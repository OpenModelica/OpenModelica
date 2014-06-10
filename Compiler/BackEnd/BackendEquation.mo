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
protected import BinaryTreeInt;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Env;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import Flags;
protected import HashTable;
protected import List;
protected import Util;

public function listEquation "author: PA
  Transform the a list of Equations into an expandable BackendDAE.Equation array."
  input list<BackendDAE.Equation> inEquationList;
  output BackendDAE.EquationArray outEquationArray;
protected
  Integer len, size, arrsize;
  Real rlen, rlen_1;
  array<Option<BackendDAE.Equation>> optarr;
algorithm
  len := listLength(inEquationList);
  rlen := intReal(len);
  rlen_1 := rlen *. 1.4;
  arrsize := realInt(rlen_1);
  optarr := arrayCreate(arrsize, NONE());
  (size,optarr) := listEquation1(inEquationList,1,0,optarr);
  outEquationArray := BackendDAE.EQUATION_ARRAY(size,len,arrsize,optarr);
end listEquation;

protected function listEquation1
  input list<BackendDAE.Equation> inEquationList;
  input Integer pos;
  input Integer iSize;
  input array<Option<BackendDAE.Equation>> iOptArr;
  output Integer oSize;
  output array<Option<BackendDAE.Equation>> oOptArr;
algorithm
  (oSize,oOptArr) := match(inEquationList,pos,iSize,iOptArr)
    local
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> rest;
      Integer size;
      array<Option<BackendDAE.Equation>> optArr;
    case ({},_,_,_) then (iSize,iOptArr);
    case (eq::rest,_,_,_)
      equation
        size = equationSize(eq);
        optArr = arrayUpdate(iOptArr,pos,SOME(eq));
        (size,optArr) = listEquation1(rest,pos+1,size+iSize,optArr);
      then
        (size,optArr);
end match;
end listEquation1;

public function emptyEqns
  output BackendDAE.EquationArray eqns;
algorithm
  eqns := listEquation({});
end emptyEqns;

public function emptyEqnsSized
  input Integer size;
  output BackendDAE.EquationArray outEquationArray;
protected
  array<Option<BackendDAE.Equation>> optarr;
algorithm
  optarr := arrayCreate(size, NONE());
  outEquationArray := BackendDAE.EQUATION_ARRAY(0,0,size,optarr);
end emptyEqnsSized;

public function equationList "author: PA
  Transform the expandable BackendDAE.Equation array to a list of Equations."
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue(inEquationArray)
    local
      array<Option<BackendDAE.Equation>> arr;
      BackendDAE.Equation elt;
      Integer n,size;
      list<BackendDAE.Equation> lst;

    case (BackendDAE.EQUATION_ARRAY(numberOfElement = 0,equOptArr = _)) then {};

    case (BackendDAE.EQUATION_ARRAY(numberOfElement = 1,equOptArr = arr)) equation
      SOME(elt) = arr[1];
    then {elt};

    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = _,equOptArr = arr)) equation
      lst = equationList2(arr, n, {});
    then lst;

    case (_) equation
      print("- BackendDAEUtil.equationList failed\n");
    then fail();
  end matchcontinue;
end equationList;

protected function equationList2 "author: PA
  Helper function to equationList
  inputs:  (Equation option array, int /* pos */, int /* lastpos */)
  outputs: BackendDAE.Equation list"
  input array<Option<BackendDAE.Equation>> arr;
  input Integer pos;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := match (arr, pos, iAcc)
    case (_,0,_) then iAcc;
    else equationList2(arr,pos-1,List.consOption(arr[pos],iAcc));
  end match;
end equationList2;

public function getWhenEquationExpr
"Get the left and right hand parts from an equation appearing in a when clause"
  input BackendDAE.WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  (outComponentRef,outExp) := match (inWhenEquation)
    local DAE.ComponentRef cr; DAE.Exp e;
    case (BackendDAE.WHEN_EQ(left = cr,right = e)) then (cr,e);
  end match;
end getWhenEquationExpr;

public function getZeroCrossingIndicesFromWhenClause "Returns a list of indices of zerocrossings that a given when clause is dependent on.
"
  input BackendDAE.BackendDAE inBackendDAE;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  match (inBackendDAE,inInteger)
    local
      list<Integer> res;
      list<BackendDAE.ZeroCrossing> zcLst;
      Integer when_index;
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst))),when_index)
      equation
        res = getZeroCrossingIndicesFromWhenClause2(zcLst, 0, when_index);
      then
        res;
  end match;
end getZeroCrossingIndicesFromWhenClause;

protected function getZeroCrossingIndicesFromWhenClause2 "helper function to get_zero_crossing_indices_from_when_clause
"
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inZeroCrossingLst1,inInteger2,inInteger3)
    local
      Integer count_1,count,when_index;
      list<Integer> resx,whenClauseList;
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
"author: wbraun"
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
"author: Frenkel TUD 2012-03
  From the equations and a variable array return all
  occuring variables form the array."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  (_,(_,bt)) := traverseBackendDAEExpsEqnList(inEquationLst,checkEquationsVarsWithoutRelations,(inVars,bt));
  (keys,_) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys,BackendVariable.getVarAt,inVars);
end equationsLstVarsWithoutRelations;

public function equationsVarsWithoutRelations
"author: Frenkel TUD 2012-03
  From the equations and a variable array return all
  occuring variables form the array without relations."
  input BackendDAE.EquationArray inEquations;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  ((_,bt)) := BackendDAEUtil.traverseBackendDAEExpsEqns(inEquations,checkEquationsVarsWithoutRelations,(inVars,bt));
  (keys,_) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys,BackendVariable.getVarAt,inVars);
end equationsVarsWithoutRelations;

protected function checkEquationsVarsWithoutRelations
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BinaryTreeInt.BinTree>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BinaryTreeInt.BinTree>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local
      DAE.Exp exp;
      BackendDAE.Variables vars;
      BinaryTreeInt.BinTree bt;
    case ((exp,(vars,bt)))
      equation
         ((_,(_,bt))) = Expression.traverseExpWithoutRelations(exp,checkEquationsVarsExp,(vars,bt));
       then
        ((exp,(vars,bt)));
    case _ then inTpl;
  end matchcontinue;
end checkEquationsVarsWithoutRelations;

public function equationsLstVars
"author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occuring variables form the array."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  (_,(_,bt)) := traverseBackendDAEExpsEqnList(inEquationLst,checkEquationsVars,(inVars,bt));
  (keys,_) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys,BackendVariable.getVarAt,inVars);
end equationsLstVars;

public function equationsVars
"author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occuring variables form the array."
  input BackendDAE.EquationArray inEquations;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  ((_,bt)) := BackendDAEUtil.traverseBackendDAEExpsEqns(inEquations,checkEquationsVars,(inVars,bt));
  (keys,_) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys,BackendVariable.getVarAt,inVars);
end equationsVars;

public function equationVars
"author: Frenkel TUD 2012-03
  From the equation and a variable array return all
  variables in the equation."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  (_,(_,bt)) := traverseBackendDAEExpsEqn(inEquation,checkEquationsVars,(inVars,bt));
  (keys,_) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys,BackendVariable.getVarAt,inVars);
end equationVars;

public function expressionVars
"author: Frenkel TUD 2012-03
  From the expression and a variable array return all
  variables in the expression."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  ((_,(_,bt))) := Expression.traverseExp(inExp,checkEquationsVarsExp,(inVars,bt));
  (keys,_) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys,BackendVariable.getVarAt,inVars);
end expressionVars;

protected function checkEquationsVars
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BinaryTreeInt.BinTree>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BinaryTreeInt.BinTree>> outTpl;
protected
  DAE.Exp exp;
  tuple<BackendDAE.Variables,BinaryTreeInt.BinTree> tpl;
algorithm
  (exp,tpl) := inTpl;
  outTpl := Expression.traverseExp(exp,checkEquationsVarsExp,tpl);
end checkEquationsVars;

protected function checkEquationsVarsExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BinaryTreeInt.BinTree>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BinaryTreeInt.BinTree>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      BinaryTreeInt.BinTree bt;
      DAE.ComponentRef cr;
      list<Integer> ilst;

    // special case for time, it is never part of the equation system
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,bt)))
      then ((e, (vars,bt)));

    // case for functionpointers
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,bt)))
      then
        ((e, (vars,bt)));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,bt)))
      equation
         (_,ilst) = BackendVariable.getVar(cr, vars);
         bt = BinaryTreeInt.treeAddList(bt,ilst);
      then
        ((e, (vars,bt)));

    case _ then inTuple;
  end matchcontinue;
end checkEquationsVarsExp;

public function equationsStates
"author: Frenkel TUD
  From a list of equations return all
  occuring state variables references."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_,(outExpComponentRefLst,_)) := traverseBackendDAEExpsEqnList(inEquationLst,extractStatesFromExp,({},inVars));
end equationsStates;

protected function extractStatesFromExp "author: Frenkel TUD 2011-05
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

    else inExp;

  end matchcontinue;
end traversingStateRefFinder;

public function equationsCrefs
"author: PA
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
"author: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Equation, list<DAE.ComponentRef>> inTpl;
 output tuple<BackendDAE.Equation, list<DAE.ComponentRef>> outTpl;
protected
  BackendDAE.Equation e;
  list<DAE.ComponentRef> cr_lst;
algorithm
  (e,cr_lst) := inTpl;
  (_,cr_lst) := traverseBackendDAEExpsEqn(e,extractCrefsFromExp,cr_lst);
  outTpl := (e,cr_lst);
end traversingEquationCrefFinder;

protected function extractCrefsFromExp "author: Frenkel TUD 2010-11
  helper for equationsCrefs"
 input tuple<DAE.Exp, list<DAE.ComponentRef>> inTpl;
 output tuple<DAE.Exp, list<DAE.ComponentRef>> outTpl;
protected
 list<DAE.ComponentRef> crefs;
 DAE.Exp e,e1;
algorithm
  (e,crefs) := inTpl;
  outTpl := Expression.traverseExp(e, Expression.traversingComponentRefFinder, crefs);
end extractCrefsFromExp;

public function equationUnknownCrefs
"author: Frenkel TUD 2012-05
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
    else inTpl;
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

    else inTuple;
  end matchcontinue;
end checkEquationsUnknownCrefsExp;

public function traverseBackendDAEExpsEqnList"author: Frenkel TUD 2010-11
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

public function traverseBackendDAEExpsEqnListWithStop
"author: Frenkel TUD 2012-09
  traverse all expressions of a list of Equations. It is possible to change the equations"
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outBoolean,outTypeA) := match(inEquations,func,inTypeA)
    local
      Type_a arg;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      Boolean b;
    case ({},_,_) then (true,inTypeA);
    case (eqn::eqns,_,_)
      equation
        (b,arg) = traverseBackendDAEExpsEqnWithStop(eqn,func,inTypeA);
        (b,arg) = Debug.bcallret3_2(b,traverseBackendDAEExpsEqnListWithStop,eqns,func,arg,b,arg);
      then
        (b,arg);
  end match;
end traverseBackendDAEExpsEqnListWithStop;

public function traverseBackendDAEExpsEqnListListWithStop
"author: Frenkel TUD 2012-09
  traverse all expressions of a list of Equations. It is possible to change the equations"
  replaceable type Type_a subtypeof Any;
  input list<list<BackendDAE.Equation>> inEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outBoolean,outTypeA) := match(inEquations,func,inTypeA)
    local
      Type_a arg;
      list<BackendDAE.Equation> eqn;
      list<list<BackendDAE.Equation>> eqns;
      Boolean b;
    case ({},_,_) then (true,inTypeA);
    case (eqn::eqns,_,_)
      equation
        (b,arg) = traverseBackendDAEExpsEqnListWithStop(eqn,func,inTypeA);
        (b,arg) = Debug.bcallret3_2(b,traverseBackendDAEExpsEqnListListWithStop,eqns,func,arg,b,arg);
      then
        (b,arg);
  end match;
end traverseBackendDAEExpsEqnListListWithStop;

public function traverseBackendDAEExpsEqn "author: Frenkel TUD 2010-11
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
      DAE.Exp e1,e2,e_1,e_2,cond;
      list<DAE.Exp> expl;
      DAE.Type tp;
      DAE.ComponentRef cr,cr1;
      BackendDAE.WhenEquation elsePart,elsePart1;
      DAE.ElementSource source;
      Integer size;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts,stmts1;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      Boolean diffed;
      DAE.Expand crefExpand;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.EQUATION(e_1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_2);

    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1,right = e2,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e_1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_2);

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source,differentiated=diffed),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_2);

    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_1);

    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation = BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e2,elsewhenPart=NONE()),source = source),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
        ((cond,ext_arg_2)) = func((cond,ext_arg_2));
      then
       (BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr1,e_2,NONE()),source,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_2);

    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation = BackendDAE.WHEN_EQ(condition=cond,left=cr,right=e2,elsewhenPart=SOME(elsePart)),source = source),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
        ((cond,ext_arg_2)) = func((cond,ext_arg_2));
        (BackendDAE.WHEN_EQUATION(whenEquation=elsePart1),ext_arg_3) = traverseBackendDAEExpsEqn(BackendDAE.WHEN_EQUATION(size,elsePart,source,BackendDAE.UNKNOWN_EQUATION_KIND()),func,ext_arg_2);
      then
        (BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr1,e_2,SOME(elsePart1)),source,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_3);

    case (BackendDAE.ALGORITHM(size=size,alg=alg as DAE.ALGORITHM_STMTS(statementLst = stmts),source=source,expand=crefExpand),_,_)
      equation
        (stmts1,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts,func,inTypeA);
        alg = Util.if_(referenceEq(stmts,stmts1),alg,DAE.ALGORITHM_STMTS(stmts1));
      then
        (BackendDAE.ALGORITHM(size,alg,source,crefExpand,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_1);

    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1,right = e2,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.COMPLEX_EQUATION(size,e_1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_2);

    case (BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns, source=source),_,_)
      equation
        (expl,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
        (eqnslst,ext_arg_2) = List.map1Fold(eqnslst,traverseBackendDAEExpsEqnList,func,ext_arg_1);
        (eqns,ext_arg_2) = List.map1Fold(eqns,traverseBackendDAEExpsEqn,func,ext_arg_2);
      then
        (BackendDAE.IF_EQUATION(expl,eqnslst,eqns,source,BackendDAE.UNKNOWN_EQUATION_KIND()),ext_arg_2);

  end match;
end traverseBackendDAEExpsEqn;

public function traverseBackendDAEExpsEqnWithStop "author: Frenkel TUD 2010-11
  traverse all expressions of a Equation. It is possible to change the equation"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outBoolean,outTypeA):= match (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,cond;
      list<DAE.Exp> expl;
      DAE.Type tp;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source;
      Integer size;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      Boolean b1,b2,b3,b4;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2),_,_)
      equation
        ((_,b1,ext_arg_1)) = func((e1,inTypeA));
        ((_,b2,ext_arg_2)) = Debug.bcallret1(b1,func,(e2,ext_arg_1),(e2,b1,ext_arg_1));
      then
        (b2,ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(left = e1,right = e2),_,_)
      equation
        ((_,b1,ext_arg_1)) = func((e1,inTypeA));
        ((_,b2,ext_arg_2)) = Debug.bcallret1(b1,func,(e2,ext_arg_1),(e2,b1,ext_arg_1));
      then
        (b2,ext_arg_2);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((_,b1,ext_arg_1)) = func((e1,inTypeA));
        ((_,b2,ext_arg_2)) = Debug.bcallret1(b1,func,(e2,ext_arg_1),(e2,b1,ext_arg_1));
      then
        (b2,ext_arg_2);
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1),_,_)
      equation
        ((_,b1,ext_arg_1)) = func((e1,inTypeA));
      then
        (b1,ext_arg_1);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e2,elsewhenPart=NONE())),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((_,b1,ext_arg_1)) = func((e1,inTypeA));
        ((_,b2,ext_arg_2)) = Debug.bcallret1(b1,func,(e2,ext_arg_1),(e2,b1,ext_arg_1));
        ((_,b3,ext_arg_3)) = Debug.bcallret1(b2,func,(cond,ext_arg_2),(e2,b2,ext_arg_2));
      then
       (b3,ext_arg_3);
    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation = BackendDAE.WHEN_EQ(condition=cond,left=cr,right=e2,elsewhenPart=SOME(elsePart)),source = source),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((_,b1,ext_arg_1)) = func((e1,inTypeA));
        ((_,b2,ext_arg_2)) = Debug.bcallret1(b1,func,(e2,ext_arg_1),(e2,b1,ext_arg_1));
        ((_,b3,ext_arg_3)) = Debug.bcallret1(b2,func,(cond,ext_arg_2),(e2,b2,ext_arg_2));
        (b4,ext_arg_3) = Debug.bcallret3_2(b2,traverseBackendDAEExpsEqnWithStop,BackendDAE.WHEN_EQUATION(size,elsePart,source,BackendDAE.UNKNOWN_EQUATION_KIND()),func,ext_arg_2,b3,ext_arg_3);
      then
        (b4,ext_arg_3);
    case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst = _)),_,_)
      equation
        print("not implemented error - BackendDAE.ALGORITHM - BackendEquation.traverseBackendDAEExpsEqnWithStop\n");
       // (stmts1,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts,func,inTypeA);
      then
        fail();
        //(true,inTypeA);
    case (BackendDAE.COMPLEX_EQUATION(left = e1,right = e2),_,_)
      equation
        ((_,b1,ext_arg_1)) = func((e1,inTypeA));
        ((_,b2,ext_arg_2)) = Debug.bcallret1(b1,func,(e2,ext_arg_1),(e2,b1,ext_arg_1));
      then
        (b2,ext_arg_2);

    case (BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns),_,_)
      equation
        (b1,ext_arg_1) = traverseBackendDAEExpListWithStop(expl,func,inTypeA);
        (b2,ext_arg_2) = Debug.bcallret3_2(b1,traverseBackendDAEExpsEqnListListWithStop,eqnslst,func,ext_arg_1,b1,ext_arg_1);
        (b3,ext_arg_3) = Debug.bcallret3_2(b2,traverseBackendDAEExpsEqnListWithStop,eqns,func,ext_arg_2,b2,ext_arg_2);
      then
        (b3,ext_arg_3);
  end match;
end traverseBackendDAEExpsEqnWithStop;

public function traverseBackendDAEExpsEqnListOutEqn
"author: Frenkel TUD 2010-11
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
  (outEquations,outchangedEquations,outTypeA) :=
     traverseBackendDAEExpsEqnListOutEqnwork(inEquations,inlistchangedEquations,func,inTypeA,{});
end traverseBackendDAEExpsEqnListOutEqn;

protected function traverseBackendDAEExpsEqnListOutEqnwork
"author: Frenkel TUD 2010-11
  traverse all expressions of a list of Equations. It is possible to change the equations"
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Equation> inlistchangedEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<BackendDAE.Equation> inEquationsAcc;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outchangedEquations;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquations,outchangedEquations,outTypeA) := match(inEquations,inlistchangedEquations,func,inTypeA,inEquationsAcc)
  local
       BackendDAE.Equation e,e1;
       list<BackendDAE.Equation> res,eqns, changedeqns;
       Type_a ext_arg_1,ext_arg_2;
       Boolean b;
    case({},_,_,_,_) then (listReverse(inEquationsAcc),inlistchangedEquations,inTypeA);
    case(e::res,_,_,_,_)
     equation
      (e1,b,ext_arg_1) = traverseBackendDAEExpsEqnOutEqn(e,func,inTypeA);
      changedeqns = List.consOnTrue(b, e1, inlistchangedEquations);
      (eqns,changedeqns,ext_arg_2)  = traverseBackendDAEExpsEqnListOutEqnwork(res,changedeqns,func,ext_arg_1,e1::inEquationsAcc);
    then
      (eqns,changedeqns,ext_arg_2);
    end match;
end traverseBackendDAEExpsEqnListOutEqnwork;

public function traverseBackendDAEExpsEqnOutEqn
 "copy of traverseBackendDAEExpsEqn
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
      DAE.Exp e1,e2,e_1,e_2,cond;
      list<DAE.Exp> expl;
      DAE.Type tp;
      DAE.ComponentRef cr,cr1;
      BackendDAE.WhenEquation elsePart,elsePart1;
      DAE.ElementSource source;
      Integer size;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      BackendDAE.Equation eq;
      Boolean b1,b2,b3,b4,bres;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqns,eqnsfalse,eqnsfalse1;
      Boolean diffed;
      DAE.Expand crefExpand;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.EQUATION(e_1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),bres,ext_arg_2);

    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1,right = e2,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e_1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),bres,ext_arg_2);

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source,differentiated=diffed),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),bres,ext_arg_2);

    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),b1,ext_arg_1);

    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation = BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e2,elsewhenPart=NONE()),source = source),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        ((cond,b3,ext_arg_2)) = func((cond,ext_arg_2));
        bres = Util.boolOrList({b1,b2,b3});
      then
       (BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr1,e_2,NONE()),source,BackendDAE.UNKNOWN_EQUATION_KIND()),bres,ext_arg_2);

    case (BackendDAE.WHEN_EQUATION(size=size,whenEquation = BackendDAE.WHEN_EQ(condition=cond,left=cr,right=e2,elsewhenPart=SOME(elsePart)),source = source),_,_)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        ((cond,b3,ext_arg_2)) = func((cond,ext_arg_2));
        (BackendDAE.WHEN_EQUATION(whenEquation=elsePart1),b4,ext_arg_3) = traverseBackendDAEExpsEqnOutEqn(BackendDAE.WHEN_EQUATION(size,elsePart,source,BackendDAE.UNKNOWN_EQUATION_KIND()),func,ext_arg_2);
        bres = Util.boolOrList({b1,b2,b3,b4});
      then
        (BackendDAE.WHEN_EQUATION(size,BackendDAE.WHEN_EQ(cond,cr1,e_2,SOME(elsePart1)),source,BackendDAE.UNKNOWN_EQUATION_KIND()),bres,ext_arg_3);

    case (BackendDAE.ALGORITHM(size=size,alg=alg,source=source,expand=crefExpand),_,_)
      then
        (BackendDAE.ALGORITHM(size,alg,source,crefExpand,BackendDAE.UNKNOWN_EQUATION_KIND()),false,inTypeA);

    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1,right = e2,source=source,differentiated=diffed),_,_)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.COMPLEX_EQUATION(size,e_1,e_2,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND()),bres,ext_arg_2);

    // special case for it initial() then ... else ... end if; only else branch needs to be checked
    /*
    case (BackendDAE.IF_EQUATION(conditions={e1 as DAE.CALL(path=Absyn.IDENT("initial"))},eqnstrue={eqns},eqnsfalse=eqnsfalse,source=source),_,_)
      equation
        (eqnsfalse,eqnsfalse1,ext_arg_2) = traverseBackendDAEExpsEqnListOutEqn(eqnsfalse,{},func,inTypeA);
        bres = List.isNotEmpty(eqnsfalse1);
        eqnsfalse1 = Util.if_(bres,eqnsfalse1,eqnsfalse);
      then
        (BackendDAE.IF_EQUATION({e1},{eqns},eqnsfalse1,source),bres,ext_arg_2);
    */
    case (eq as BackendDAE.IF_EQUATION(conditions=_),_,_)
      equation
        (eq,bres,ext_arg_1) = traverseBackendDAEExpsEqnOutEqnIfEqns( eq, func, inTypeA);
      then
        (eq,bres,ext_arg_1);

  end match;
end traverseBackendDAEExpsEqnOutEqn;

protected function traverseBackendDAEExpsEqnOutEqnIfEqns
"Helper function to traverseBackendDAEExpsEqnOutEqn."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inIfEqn;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outIfEqn;
  output Boolean outflag;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outIfEqn,outflag,outTypeA):= match (inIfEqn,func,inTypeA)
    local
      Type_a ext_arg_1;
      Boolean bres,bres1,bres2;
      DAE.Exp condition;
      list<DAE.Exp> conditions, restconditions;
      BackendDAE.Equation ifeqn;
      list<BackendDAE.Equation> eqnstrue, eqnstrue1, elseeqns, elseeqns1;
      list<list<BackendDAE.Equation>> eqnsTrueLst, resteqns;
      DAE.ElementSource source_;
    case (BackendDAE.IF_EQUATION(conditions={}, eqnstrue={}, eqnsfalse=elseeqns, source=source_),_,_)
      equation
        (elseeqns,elseeqns1,ext_arg_1) = traverseBackendDAEExpsEqnListOutEqn(elseeqns,{},func,inTypeA);
        bres = List.isNotEmpty(elseeqns1);
        elseeqns = Util.if_(bres,elseeqns1,elseeqns);
      then
        (BackendDAE.IF_EQUATION({},{},elseeqns,source_,BackendDAE.UNKNOWN_EQUATION_KIND()),bres,ext_arg_1);
    case (BackendDAE.IF_EQUATION(conditions=condition::restconditions, eqnstrue=eqnstrue::resteqns, eqnsfalse=elseeqns, source=source_),_,_)
      equation
        ((condition,bres,ext_arg_1)) = func((condition,inTypeA));
        (eqnstrue,eqnstrue1,ext_arg_1) = traverseBackendDAEExpsEqnListOutEqn(eqnstrue,{},func,ext_arg_1);
        bres1 = List.isNotEmpty(eqnstrue1);
        eqnstrue = Util.if_(bres,eqnstrue1,eqnstrue);
        ifeqn = BackendDAE.IF_EQUATION(restconditions, resteqns, elseeqns, source_, BackendDAE.UNKNOWN_EQUATION_KIND());
        (BackendDAE.IF_EQUATION(conditions=conditions, eqnstrue=eqnsTrueLst, eqnsfalse=elseeqns, source=source_), bres2, ext_arg_1)
                                                                    = traverseBackendDAEExpsEqnOutEqnIfEqns(ifeqn, func, ext_arg_1);
        conditions = listAppend({condition},conditions);
        eqnsTrueLst = listAppend({eqnstrue},eqnsTrueLst);
        bres = Util.boolOrList({bres,bres1,bres2});
      then
        (BackendDAE.IF_EQUATION(conditions, eqnsTrueLst, elseeqns, source_, BackendDAE.UNKNOWN_EQUATION_KIND()), bres, ext_arg_1);
  end match;
end traverseBackendDAEExpsEqnOutEqnIfEqns;

public function traverseBackendDAEExpList
" author Frenkel TUD:
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
    case(e::res,_,ext_arg_1) equation
      ((e1,ext_arg_2)) = rel((e, ext_arg_1));
      (expl1,ext_arg_3) = traverseBackendDAEExpList(res,rel,ext_arg_2);
    then (e1::expl1,ext_arg_3);
  end match;
end traverseBackendDAEExpList;

public function traverseBackendDAEExpListWithStop
" author Frenkel TUD:
 Calls user function for each element of list."
  replaceable type Type_a subtypeof Any;
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input Type_a ext_arg;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outBoolean,outTypeA) := match(inExpl,rel,ext_arg)
  local
      DAE.Exp e;
      list<DAE.Exp> res;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      Boolean b;
    case({},_,ext_arg_1) then (true,ext_arg_1);
    case(e::res,_,ext_arg_1) equation
      ((_,b,ext_arg_2)) = rel((e, ext_arg_1));
      (b,ext_arg_3) = Debug.bcallret3_2(b,traverseBackendDAEExpListWithStop,res,rel,ext_arg_2,b,ext_arg_2);
    then (b,ext_arg_3);
  end match;
end traverseBackendDAEExpListWithStop;

public function traverseBackendDAEEqnsList
" author Frenkel TUD:
 Calls user function for each element of list."
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEqns;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<BackendDAE.Equation> inAccEqns;
  output list<BackendDAE.Equation> outEqns;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEqns,outTypeA) := match(inEqns,func,inTypeA,inAccEqns)
  local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest;
      Type_a ext_arg;
    case({},_,_,_) then (listReverse(inAccEqns),inTypeA);
    case(eqn::rest,_,_,_)
      equation
        ((eqn,ext_arg)) = func((eqn, inTypeA));
        (rest,ext_arg) = traverseBackendDAEEqnsList(rest,func,ext_arg,eqn::inAccEqns);
      then
        (rest,ext_arg);
  end match;
end traverseBackendDAEEqnsList;

public function traverseBackendDAEEqns "author: Frenkel TUD

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
    case ((BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr)),_,_)
      then BackendDAEUtil.traverseBackendDAEArrayNoCopy(equOptArr,func,traverseBackendDAEOptEqn,1,arrayLength(equOptArr),inTypeA);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEEqns failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqns;

protected function traverseBackendDAEOptEqn "author: Frenkel TUD 2010-11
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
    case (NONE(),_,_) then inTypeA;
    case (SOME(eqn),_,_)
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

public function traverseBackendDAEEqnsWithStop "author: Frenkel TUD

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
    case ((BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr)),_,_)
      then BackendDAEUtil.traverseBackendDAEArrayNoCopyWithStop(equOptArr,func,traverseBackendDAEOptEqnWithStop,1,arrayLength(equOptArr),inTypeA);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEEqnsWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqnsWithStop;

protected function traverseBackendDAEOptEqnWithStop "author: Frenkel TUD 2010-11
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
    case (NONE(),_,_) then (true,inTypeA);
    case (SOME(eqn),_,_)
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

public function traverseBackendDAEEqnsWithUpdate "author: Frenkel TUD

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
    case ((BackendDAE.EQUATION_ARRAY(size=size,numberOfElement=numberOfElement,arrSize=arrSize,equOptArr = equOptArr)),_,_)
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

protected function traverseBackendDAEOptEqnWithUpdate "author: Frenkel TUD 2010-11
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
    case (oeqn as NONE(),_,_) then (oeqn,inTypeA);
    case (oeqn as SOME(eqn),_,_)
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

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr1,right=exp1)),
          BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr2,right=exp2)))
      equation
        res = boolAnd(ComponentReference.crefEqualNoStringCompare(cr1, cr2),Expression.expEqual(exp1,exp2));
      then res;

    case(_,_) then false;

  end matchcontinue;
end equationEqual;

public function addEquations "author: wbraun
  Adds a list of BackendDAE.Equation to BackendDAE.EquationArray"
  input list<BackendDAE.Equation> eqnlst;
  input BackendDAE.EquationArray eqns;
  output BackendDAE.EquationArray eqns_1;
algorithm
  eqns_1 := List.fold(eqnlst, equationAdd, eqns);
end addEquations;

public function mergeEquationArray "author: vitalij
  This function returns an EquationArray containing all the equations from both
  inputs."
  input BackendDAE.EquationArray inEqns1;
  input BackendDAE.EquationArray inEqns2;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns := addEquations(equationList(inEqns1), inEqns2);
end mergeEquationArray;

public function equationAdd "author: PA

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
            "\nnumberOfElement " +& intString(n) +& "\nSize " +& intString(size) +& "\narraySize " +& intString(arrayLength(arr)));
      then
        fail();
  end matchcontinue;
end equationAdd;

public function equationAddDAE
"author: Frenkel TUD 2011-05"
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
      BackendDAE.StateSets stateSets;
    case (_,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=mT,stateSets=stateSets))
      equation
        eqns1 = equationAdd(inEquation,eqns);
      then BackendDAE.EQSYSTEM(ordvars,eqns1,m,mT,BackendDAE.NO_MATCHING(),stateSets);
  end match;
end equationAddDAE;

public function equationsAddDAE
"author: Frenkel TUD 2011-05"
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
      BackendDAE.StateSets stateSets;
    case (_,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=mT,stateSets=stateSets))
      equation
        eqns1 = List.fold(inEquations,equationAdd,eqns);
      then BackendDAE.EQSYSTEM(ordvars,eqns1,m,mT,BackendDAE.NO_MATCHING(),stateSets);
  end match;
end equationsAddDAE;

public function requationsAddDAE
"author: Frenkel TUD 2012-10
  Add a list of equations to removed equations of a BackendDAE.
  If the variable already exists, the function updates the variable."
  input list<BackendDAE.Equation> inEquations;
  input BackendDAE.Shared shared;
  output BackendDAE.Shared oshared;
algorithm
  oshared := match (inEquations,shared)
    local
      BackendDAE.Variables knvars,exobj,aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;

    case ({},_) then shared;

    case (_,BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs,ei))
      equation
        remeqns = List.fold(inEquations,equationAdd,remeqns);
      then BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcs,einfo,eoc,btp,symjacs,ei);

  end match;
end requationsAddDAE;

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
      BackendDAE.Variables ordvars;
      BackendDAE.EquationArray eqns,eqns1;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
    case (_,_,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching,stateSets))
      equation
        eqns1 = equationSetnth(eqns,inInteger,inEquation);
      then BackendDAE.EQSYSTEM(ordvars,eqns1,m,mT,matching,stateSets);
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

public function getEqns "author: Frenkel TUD 2011-05
  returns the equations given by the list of indexes"
  input list<Integer> inIndxes;
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := List.map1r(inIndxes, equationNth1, inEquationArray);
end getEqns;

public function equationNth0 "author: PA
  Return the n-th equation from the expandable equation array
  indexed from 0..N-1.

  inputs:  (EquationArray, int /* n */)
  outputs:  Equation"
  input BackendDAE.EquationArray inEquationArray;
  input Integer pos;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := equationNth1(inEquationArray, pos+1);
end equationNth0;

public function equationNth1 "author: PA
  Return the n-th equation from the expandable equation array
  indexed from 1..N.

  inputs:  (EquationArray, int /* n */)
  outputs:  Equation"
  input BackendDAE.EquationArray inEquationArray;
  input Integer pos;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation:=
  matchcontinue (inEquationArray,pos)
    local
      BackendDAE.Equation e;
      Integer n;
      array<Option<BackendDAE.Equation>> arr;
      String str;

    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,equOptArr = arr),_)
      equation
        true = intLe(pos,n);
        SOME(e) = arr[pos];
      then
        e;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n),_)
      equation
        str = "BackendEquation.equationNth1 failed; numberOfElement=" +& intString(n) +& "; pos=" +& intString(pos);
        print(str +& "\n");
        Error.addMessage(Error.INTERNAL_ERROR,{str});
      then
        fail();
  end matchcontinue;
end equationNth1;

public function equationNthSize
  input BackendDAE.EquationArray inEquationArray;
  input Integer pos;
  output BackendDAE.Equation outEquation;
protected
  list<BackendDAE.Equation> eqns;
algorithm
  eqns := equationList(inEquationArray);
  outEquation := equationNthSize1(eqns, pos, 1);
end equationNthSize;

public function equationNthSize1
  input list<BackendDAE.Equation> inEqns;
  input Integer pos;
  input Integer acc;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEqns, pos, acc)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      Integer size;
      array<Option<BackendDAE.Equation>> arr;
      String str;

    case ({}, _, _)
      equation
        str = "BackendEquation.equationNthSize1 failed";
        print(str +& "\n");
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();

    case (eqn::_, _, _)
      equation
        size = equationSize(eqn);
        true = (pos >= acc);
        true = (pos < acc+size);
      then eqn;

    case (eqn::eqns, _, _)
      equation
        size = equationSize(eqn);
        true = (pos >= acc+size);
      then equationNthSize1(eqns, pos, acc+size);

    else
      equation
        str = "BackendEquation.equationNthSize1 failed";
        print(str +& "\n");
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end equationNthSize1;

public function equationDelete "author: Frenkel TUD 2010-12
  Delets the equations from the list of Integers."
  input BackendDAE.EquationArray inEquationArray;
  input list<Integer> inIntLst;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue (inEquationArray,inIntLst)
    local
      list<BackendDAE.Equation> eqnlst;
      Integer numberOfElement,arrSize;
      array<Option<BackendDAE.Equation>> equOptArr;
    case (_,{})
      then
        inEquationArray;
    case (BackendDAE.EQUATION_ARRAY(arrSize=arrSize,equOptArr=equOptArr),_)
      equation
        equOptArr = List.fold1r(inIntLst,arrayUpdate,NONE(),equOptArr);
        eqnlst = equationDelete1(arrSize,equOptArr,{});
      then
        listEquation(eqnlst);
    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAE.equationDelete failed");
      then
        fail();
  end matchcontinue;
end equationDelete;

protected function equationDelete1
 "author: Frenkel TUD 2012-09
  helper for equationDelete."
  input Integer index;
  input array<Option<BackendDAE.Equation>> equOptArr;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oAcc;
algorithm
  oAcc := matchcontinue(index,equOptArr,iAcc)
    local
      BackendDAE.Equation eqn;
    case(0,_,_) then iAcc;
    case(_,_,_)
      equation
        SOME(eqn) = equOptArr[index];
      then
        equationDelete1(index-1,equOptArr,eqn::iAcc);
    case(_,_,_)
      then
        equationDelete1(index-1,equOptArr,iAcc);
  end matchcontinue;
end equationDelete1;

public function equationRemove "author: Frenkel TUD 2012-09
  Removes the equations from the array on the given possitoin but
  does not scale down the array size"
  input Integer inPos "1 based index";
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue (inPos,inEquationArray)
    local
      Integer numberOfElement,arrSize,size,size1,eqnsize;
      array<Option<BackendDAE.Equation>> equOptArr;
      BackendDAE.Equation eqn;
    case (_,BackendDAE.EQUATION_ARRAY(size=size,numberOfElement=numberOfElement,arrSize=arrSize,equOptArr=equOptArr))
      equation
        true = intLe(inPos,numberOfElement);
        SOME(eqn) = equOptArr[inPos];
        equOptArr = arrayUpdate(equOptArr,inPos,NONE());
        eqnsize = equationSize(eqn);
        size1 = size - eqnsize;
      then
        BackendDAE.EQUATION_ARRAY(size1,numberOfElement,arrSize,equOptArr);
    case (_,BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfElement,equOptArr=equOptArr))
      equation
        true = intLe(inPos,numberOfElement);
        NONE() = equOptArr[inPos];
      then
        inEquationArray;
    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAE.equationRemove failed");
      then
        fail();
  end matchcontinue;
end equationRemove;

public function compressEquations "author: Frenkel TUD 2012-11
  Closes the gabs"
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue(inEquationArray)
    local
      Integer numberOfElement,arrSize;
      array<Option<BackendDAE.Equation>> equOptArr;
    case BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfElement,equOptArr=equOptArr)
      equation
        outEquationArray = emptyEqnsSized(numberOfElement);
      then
        compressEquations1(1,numberOfElement,equOptArr,outEquationArray);
    else
      equation
        print("BackendEquation.compressEquations failed\n");
      then
        fail();
  end matchcontinue;
end compressEquations;

protected function compressEquations1 "author: Frenkel TUD 2012-09"
  input Integer index;
  input Integer nEqns;
  input array<Option<BackendDAE.Equation>> equOptArr;
  input BackendDAE.EquationArray iEqns;
  output BackendDAE.EquationArray oEqns;
algorithm
  oEqns := matchcontinue(index,nEqns,equOptArr,iEqns)
    local
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns;
    // found element
    case(_,_,_,_)
      equation
        true = intLe(index,nEqns);
        SOME(eqn) = equOptArr[index];
        eqns = equationAdd(eqn,iEqns);
      then
        compressEquations1(index+1,nEqns,equOptArr,eqns);
    // found non element
    case(_,_,_,_)
      equation
        true = intLe(index,nEqns);
        NONE() = equOptArr[index];
      then
        compressEquations1(index+1,nEqns,equOptArr,iEqns);
    // at the end
    case(_,_,_,_)
      equation
        false = intLe(index,nEqns);
      then
        iEqns;
    else
      equation
        print("BackendEquation.compressEquations1 failed for index " +& intString(index) +& " and Number of Equations " +& intString(nEqns) +& "\n");
      then
        fail();
  end matchcontinue;
end compressEquations1;

public function equationToScalarResidualForm "author: Frenkel TUD 2012-06
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
      Boolean diffed;
      Real r;

    case (BackendDAE.EQUATION(exp=DAE.TUPLE(explst), scalar=e2, source=source)) equation
      ((_, eqns)) = List.fold2(explst, equationTupleToScalarResidualForm, e2, source, (1, {}));
    then eqns;

    // workaround, should changed to DAE.RCONST(0.0)
    // when new rml is availiable
    case (BackendDAE.EQUATION(exp=DAE.RCONST(r), scalar=e2, source=source, differentiated=diffed)) equation
      true = realEq(r, 0.0);
      eqns ={BackendDAE.RESIDUAL_EQUATION(e2, source, diffed, BackendDAE.UNKNOWN_EQUATION_KIND())};
    then eqns;

    // workaround, should changed to DAE.RCONST(0.0)
    // when new rml is availiable
    case (BackendDAE.EQUATION(exp=e1, scalar=DAE.RCONST(r), source=source, differentiated=diffed)) equation
      true = realEq(r, 0.0);
      eqns ={BackendDAE.RESIDUAL_EQUATION(e1, source, diffed, BackendDAE.UNKNOWN_EQUATION_KIND())};
    then eqns;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, differentiated=diffed)) equation
      exp = Expression.expSub(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then {BackendDAE.RESIDUAL_EQUATION(e, source, diffed, BackendDAE.UNKNOWN_EQUATION_KIND())};

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2, source=source, differentiated=diffed)) equation
      e1 = Expression.crefExp(cr);
      exp = Expression.expSub(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then {BackendDAE.RESIDUAL_EQUATION(e, source, diffed, BackendDAE.UNKNOWN_EQUATION_KIND())};

    case (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2, source=source)) equation
      exp = Expression.expSub(e1, e2);
      ad = List.map(ds, Util.makeOption);
      subslst = BackendDAEUtil.arrayDimensionsToRange(ad);
      subslst = BackendDAEUtil.rangesToSubscripts(subslst);
      explst = List.map1r(subslst, Expression.applyExpSubscripts, exp);
      explst = ExpressionSimplify.simplifyList(explst, {});
      eqns = List.map1(explst, generateRESIDUAL_EQUATION, source);
    then eqns;

    case (backendEq as BackendDAE.COMPLEX_EQUATION(source=_))  then {backendEq};
    case (backendEq as BackendDAE.RESIDUAL_EQUATION(source=_)) then {backendEq};
    case (backendEq as BackendDAE.ALGORITHM(alg=_))                 then {backendEq};
    case (backendEq as BackendDAE.WHEN_EQUATION(whenEquation=_))    then {backendEq};

    case (_) equation
      Debug.fprintln(Flags.FAILTRACE, "- BackendDAE.equationToScalarResidualForm failed");
    then fail();
  end matchcontinue;
end equationToScalarResidualForm;

protected function equationTupleToScalarResidualForm "Tuple-expressions (function calls) that need to be converted to residual form are scalarized in a stupid, straight-forward way"
  input DAE.Exp cr;
  input DAE.Exp exp;
  input DAE.ElementSource inSource;
  input tuple<Integer,list<BackendDAE.Equation>> inTpl;
  output tuple<Integer,list<BackendDAE.Equation>> outTpl;
algorithm
  outTpl := match (cr,exp,inSource,inTpl)
    local
      Integer i;
      list<BackendDAE.Equation> eqs;
      String str;
      DAE.Exp e;
      // Wild-card does not produce a residual
    case (DAE.CREF(componentRef=DAE.WILD()),_,_,(i,eqs)) then ((i+1,eqs));
      // 0-length arrays do not produce a residual
    case (DAE.ARRAY(array={}),_,_,(i,eqs)) then ((i+1,eqs));
      // A scalar real
    case (DAE.CREF(ty=DAE.T_REAL(source=_)),_,_,(i,eqs))
      equation
        eqs = BackendDAE.RESIDUAL_EQUATION(DAE.TSUB(exp,i,DAE.T_REAL_DEFAULT),inSource,false,BackendDAE.UNKNOWN_EQUATION_KIND())::eqs;
      then ((i+1,eqs));
      // Create a sum for arrays...
    case (DAE.CREF(ty=DAE.T_ARRAY(ty=DAE.T_REAL(source=_))),_,_,(i,eqs))
      equation
        e = Expression.makePureBuiltinCall("sum",{DAE.TSUB(exp,i,DAE.T_REAL_DEFAULT)},DAE.T_REAL_DEFAULT);
        eqs = BackendDAE.RESIDUAL_EQUATION(e,inSource,false,BackendDAE.UNKNOWN_EQUATION_KIND())::eqs;
      then ((i+1,eqs));
    case (_,_,_,(i,_))
      equation
        str = "BackendEquation.equationTupleToScalarResidualForm failed: " +& intString(i) +& ": " +& ExpressionDump.printExpStr(cr);
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},DAEUtil.getElementSourceFileInfo(inSource));
      then fail();
  end match;
end equationTupleToScalarResidualForm;

public function equationToResidualForm "author: PA
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
      Boolean diffed;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source, differentiated=diffed))
      equation
        //ExpressionDump.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND());

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source = source, differentiated=diffed))
      equation
        e1 = Expression.crefExp(cr);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND());

    case (BackendDAE.ARRAY_EQUATION(left = e1,right = e2,source = source, differentiated=diffed))
      equation
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND());

    case (BackendDAE.COMPLEX_EQUATION(left = e1,right = e2,source = source, differentiated=diffed))
      equation
         exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source,diffed,BackendDAE.UNKNOWN_EQUATION_KIND());

    case (backendEq as BackendDAE.RESIDUAL_EQUATION(exp = _)) then backendEq;

    case (backendEq as BackendDAE.ALGORITHM(alg = _)) then backendEq;

    case (backendEq as BackendDAE.WHEN_EQUATION(whenEquation = _)) then backendEq;

    case (_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAE.equationToResidualForm failed");
      then
        fail();
  end matchcontinue;
end equationToResidualForm;

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
  source := equationSource(equationNth0(eqns,i-1));
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
    case BackendDAE.WHEN_EQUATION(size=size) then size;
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

public function equationKind "Retrieve the kind from a BackendDAE.BackendDAE equation"
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationKind outEqKind;
algorithm
  outEqKind := match inEquation
    local
      BackendDAE.EquationKind kind;

    case BackendDAE.EQUATION(kind=kind) then kind;
    case BackendDAE.ARRAY_EQUATION(kind=kind) then kind;
    case BackendDAE.SOLVED_EQUATION(kind=kind) then kind;
    case BackendDAE.RESIDUAL_EQUATION(kind=kind) then kind;
    case BackendDAE.WHEN_EQUATION(kind=kind) then kind;
    case BackendDAE.ALGORITHM(kind=kind) then kind;
    case BackendDAE.COMPLEX_EQUATION(kind=kind) then kind;
    case BackendDAE.IF_EQUATION(kind=kind) then kind;
    case (_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendEquation.equationKind failed!"});
    then fail();
  end match;
end equationKind;

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

public function generateEquation
"author Frenkel TUD 2012-12
  helper to generate an equation from lhs and rhs.
  This function is called if an equation is found which is not simple"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type ty;
  input DAE.ElementSource source;
  input Boolean differentiated;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue (lhs,rhs,ty,source,differentiated)
    local
      Integer size;
      DAE.Dimensions dims;
      list<Integer> ds;
      Boolean b1,b2;
    // complex types to complex equations
    case (_,_,_,_,_)
      equation
        true = DAEUtil.expTypeComplex(ty);
        size = Expression.sizeOf(ty);
       then
        BackendDAE.COMPLEX_EQUATION(size,lhs,rhs,source,differentiated,BackendDAE.UNKNOWN_EQUATION_KIND());
    // array types to array equations
    case (_,_,_,_,_)
      equation
        true = DAEUtil.expTypeArray(ty);
        dims = Expression.arrayDimension(ty);
        ds = Expression.dimensionsSizes(dims);
      then
        BackendDAE.ARRAY_EQUATION(ds,lhs,rhs,source,differentiated,BackendDAE.UNKNOWN_EQUATION_KIND());
    // other types
    case (_,_,_,_,_)
      equation
        b1 = DAEUtil.expTypeComplex(ty);
        b2 = DAEUtil.expTypeArray(ty);
        false = b1 or b2;
      then
        BackendDAE.EQUATION(lhs,rhs,source,differentiated,BackendDAE.UNKNOWN_EQUATION_KIND());
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendEquation.generateEquation failed on: " +& ExpressionDump.printExpStr(lhs) +& " = " +& ExpressionDump.printExpStr(rhs) +& "\n");
      then
        fail();
  end matchcontinue;
end generateEquation;

public function generateEQUATION "
Author: Frenkel TUD 2010-05"
  input DAE.Exp iLhs;
  input DAE.Exp iRhs;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAE.EQUATION(iLhs,iRhs,Source,false,BackendDAE.UNKNOWN_EQUATION_KIND());
end generateEQUATION;

public function generateSolvedEqnsfromOption "
Author: Frenkel TUD 2010-05"
  input DAE.ComponentRef iLhs;
  input Option<DAE.Exp> iRhs;
  input DAE.ElementSource Source;
  output list<BackendDAE.Equation> outEqn;
algorithm
  outEqn :=  match (iLhs, iRhs, Source)
  local
    DAE.Exp rhs;
    DAE.ComponentRef lhs;
    case (lhs, SOME(rhs), _)
      then {BackendDAE.SOLVED_EQUATION(lhs,rhs,Source,false,BackendDAE.UNKNOWN_EQUATION_KIND())};
    else {};
  end match;
end generateSolvedEqnsfromOption;

public function generateResidualfromRealtion "author: vitalij"
  input Integer inI;
  input DAE.Exp iRhs;
  input DAE.ElementSource Source;
  output list<BackendDAE.Equation> outEqn;
  output BackendDAE.Var vout;
algorithm
  (outEqn,vout) :=  match (inI, iRhs, Source)
  local
    DAE.Exp rhs,e1,e2;
    DAE.ComponentRef lhs;
    BackendDAE.Var dummyVar;
    case (_,DAE.RELATION(e1,DAE.LESS(_),e2,_,_), _) equation
      lhs = ComponentReference.makeCrefIdent("$TMP_ineq_con" +& intString(inI), DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, BackendDAE.OPT_CONSTR(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      (rhs,_) = ExpressionSimplify.simplify(DAE.BINARY(e1,DAE.SUB(DAE.T_REAL_DEFAULT),e2));
    then ({BackendDAE.SOLVED_EQUATION(lhs,rhs,Source,false,BackendDAE.UNKNOWN_EQUATION_KIND())},dummyVar);
    case (_,DAE.RELATION(e1,DAE.LESSEQ(_),e2,_,_), _) equation
      lhs = ComponentReference.makeCrefIdent("$TMP_ineq_con" +& intString(inI), DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, BackendDAE.OPT_CONSTR(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      (rhs,_) = ExpressionSimplify.simplify(DAE.BINARY(e1,DAE.SUB(DAE.T_REAL_DEFAULT),e2));
      then ({BackendDAE.SOLVED_EQUATION(lhs,rhs,Source,false,BackendDAE.UNKNOWN_EQUATION_KIND())},dummyVar);
    case (_,DAE.RELATION(e1,DAE.GREATER(_),e2,_,_), _) equation
      lhs = ComponentReference.makeCrefIdent("$TMP_ineq_con" +& intString(inI), DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, BackendDAE.OPT_CONSTR(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      (rhs,_) = ExpressionSimplify.simplify(DAE.BINARY(e2,DAE.SUB(DAE.T_REAL_DEFAULT),e1));
      then ({BackendDAE.SOLVED_EQUATION(lhs,rhs,Source,false,BackendDAE.UNKNOWN_EQUATION_KIND())},dummyVar);
    case (_,DAE.RELATION(e1,DAE.GREATEREQ(_),e2,_,_), _) equation
      lhs = ComponentReference.makeCrefIdent("$TMP_ineq_con" +& intString(inI), DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, BackendDAE.OPT_CONSTR(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      (rhs,_) = ExpressionSimplify.simplify(DAE.BINARY(e2,DAE.SUB(DAE.T_REAL_DEFAULT),e1));
      then ({BackendDAE.SOLVED_EQUATION(lhs, rhs,Source,false,BackendDAE.UNKNOWN_EQUATION_KIND())},dummyVar);
    case (_,DAE.RELATION(e1,DAE.EQUAL(_),e2,_,_), _) equation
      lhs = ComponentReference.makeCrefIdent("$TMP_eq_con" +& intString(inI), DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, BackendDAE.OPT_CONSTR(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      (rhs,_) = ExpressionSimplify.simplify(DAE.BINARY(e2,DAE.SUB(DAE.T_REAL_DEFAULT),e1));
      then ({BackendDAE.SOLVED_EQUATION(lhs, rhs,Source,false,BackendDAE.UNKNOWN_EQUATION_KIND())},dummyVar);
    else equation
      lhs = ComponentReference.makeCrefIdent("$TMP_eq_con" +& intString(inI), DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, BackendDAE.OPT_CONSTR(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
    then ({},dummyVar);
  end match;
end generateResidualfromRealtion;

public function solveEquation "author: wbraun
  Solves an equation w.r.t. a component reference. All equations are transformed
  to a EQUATION(cref, exp).
  Algorithm, when and if equation are left as they are."
  input BackendDAE.Equation eqn;
  input DAE.Exp crefExp;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue (eqn, crefExp)
    local
      DAE.Exp e1,e2;
      DAE.Exp res;
      DAE.ComponentRef cref, cr;
      list<DAE.ComponentRef> crefLst;
      BackendDAE.Equation eq;
      Boolean differentiated;
      DAE.ElementSource source;
      BackendDAE.EquationKind eqKind;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, differentiated=differentiated, kind=eqKind), _)
      equation
        (res, _) = ExpressionSolve.solve(e1, e2, crefExp);
      then (BackendDAE.EQUATION(crefExp, res ,source, differentiated, eqKind));

    case (BackendDAE.ARRAY_EQUATION(left=e1, right=e2, source=source, differentiated=differentiated, kind=eqKind), _)
      equation
        (res, _) = ExpressionSolve.solve(e1, e2, crefExp);
      then (BackendDAE.EQUATION(crefExp, res, source, differentiated, eqKind));

    case (BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e2, source=source, differentiated=differentiated, kind=eqKind), _)
      equation
        cr = Expression.expCref(crefExp);
        true = ComponentReference.crefEqual(cref, cr);
      then (BackendDAE.EQUATION(crefExp, e2, source, differentiated, eqKind));

    case (BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e2, source=source, differentiated=differentiated, kind=eqKind), _)
      equation
        cr = Expression.expCref(crefExp);
        false = ComponentReference.crefEqual(cref, cr);
        e1 = Expression.crefExp(cref);
        (res,_) = ExpressionSolve.solve(e1, e2, crefExp);
      then (BackendDAE.EQUATION(crefExp, res, source, differentiated, eqKind));

    case (BackendDAE.RESIDUAL_EQUATION(exp=e2, source=source, differentiated=differentiated, kind=eqKind), _)
      equation
        e1 = Expression.makeConstOne(Expression.typeof(e2));
        (res, _) = ExpressionSolve.solve(e1, e2, crefExp);
      then (BackendDAE.EQUATION(crefExp, res, source, differentiated, eqKind));

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, differentiated=differentiated, kind=eqKind), _)
      equation
        (res, _) = ExpressionSolve.solve(e1, e2, crefExp);
      then (BackendDAE.EQUATION(crefExp, res, source, differentiated, eqKind));
/*
    case (eq as BackendDAE.ALGORITHM(alg=_), _)
      then eq;

    case (eq as BackendDAE.WHEN_EQUATION(size=_), _)
      then eq;

    case (eq as BackendDAE.IF_EQUATION(conditions=_), _)
      then eq;
*/
    else equation
      BackendDump.dumpBackendDAEEqnList({eqn}, "function BackendEquation.solveEquation failed w.r.t " +& ExpressionDump.printExpStr(crefExp), true);
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendEquation.mo: function solveEquation failed"});
    then fail();
  end matchcontinue;
end solveEquation;

public function generateRESIDUAL_EQUATION "
  author: Frenkel TUD 2010-05"
  input DAE.Exp inExp;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAE.RESIDUAL_EQUATION(inExp, Source, false, BackendDAE.UNKNOWN_EQUATION_KIND());
end generateRESIDUAL_EQUATION;

public function daeEqns
  input BackendDAE.EqSystem syst;
  output BackendDAE.EquationArray eqnarr;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs = eqnarr) := syst;
end daeEqns;

public function daeInitialEqns
  input BackendDAE.Shared shared;
  output BackendDAE.EquationArray eqnarr;
algorithm
  BackendDAE.SHARED(initialEqs = eqnarr) := shared;
end daeInitialEqns;

public function aliasEquation
"author Frenkel TUD 2011-04
  Returns the two sides of an alias equation as expressions and cref.
  If the equation is not simple, this function will fail."
  input BackendDAE.Equation eqn;
  output list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> outTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
algorithm
  outTpls := match (eqn)
    local
      DAE.Exp e,e1,e2;
      DAE.ComponentRef cr;
    case (BackendDAE.EQUATION(exp=e1,scalar=e2))
      then aliasEquation1(e1,e2,{});
    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2))
      then aliasEquation1(e1,e2,{});
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e2))
      equation
        e = Expression.crefExp(cr);
      then aliasEquation1(e,e2,{});
    case (BackendDAE.RESIDUAL_EQUATION(exp=e1))
      then aliasExpression(e1,{});
    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2))
      then aliasEquation1(e1,e2,{});
  end match;
end aliasEquation;

protected function aliasEquation1
"author Frenkel TUD 2011-04
  helper for aliasEquation"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> inTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
  output list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> outTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
algorithm
  outTpls := match (lhs,rhs,inTpls)
      local
        DAE.ComponentRef cr1,cr2;
        DAE.Exp e1,e2;
        DAE.Type ty;
        list<DAE.Exp> elst1,elst2;
        list<list<DAE.Exp>> elstlst1,elstlst2;
        list<DAE.Var> varLst1,varLst2;
        Absyn.Path patha,patha1,pathb,pathb1;
      // a = b;
      case (DAE.CREF(componentRef = cr1),DAE.CREF(componentRef = cr2),_)
        then (cr1,cr2,lhs,rhs,false)::inTpls;
      // a = -b;
      case (DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS(ty),DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,DAE.UNARY(DAE.UMINUS(ty),lhs),rhs,true)::inTpls;
      case (DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS_ARR(ty),DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,DAE.UNARY(DAE.UMINUS_ARR(ty),lhs),rhs,true)::inTpls;
      // -a = b;
      case (DAE.UNARY(DAE.UMINUS(ty),DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr2),_)
        then (cr1,cr2,lhs,DAE.UNARY(DAE.UMINUS(ty),rhs),true)::inTpls;
      case (DAE.UNARY(DAE.UMINUS_ARR(ty),DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr2),_)
        then (cr1,cr2,lhs,DAE.UNARY(DAE.UMINUS_ARR(ty),rhs),true)::inTpls;
      // -a = -b;
      case (DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(componentRef = cr1)),DAE.UNARY(DAE.UMINUS(_),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,e2,false)::inTpls;
      case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,e2,false)::inTpls;
      // a = not b;
      case (DAE.CREF(componentRef = cr1),DAE.LUNARY(DAE.NOT(ty),DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,DAE.LUNARY(DAE.NOT(ty),lhs),rhs,true)::inTpls;
      // not a = b;
      case (DAE.LUNARY(DAE.NOT(ty),DAE.CREF(componentRef = cr1)),DAE.CREF(componentRef = cr2),_)
        then (cr1,cr2,lhs,DAE.LUNARY(DAE.NOT(ty),rhs),true)::inTpls;
      // not a = not b;
      case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,e2,false)::inTpls;
      // {a1,a2,a3,..} = {b1,b2,b3,..};
      case (DAE.ARRAY(array = elst1),DAE.ARRAY(array = elst2),_)
        then List.threadFold(elst1,elst2,aliasEquation1,inTpls);
      case (DAE.MATRIX(matrix = elstlst1),DAE.MATRIX(matrix = elstlst2),_)
        then List.threadFold(elstlst1,elstlst2,aliasEquationLst,inTpls);
      // a = {b1,b2,b3,..}
      //case (DAE.CREF(componentRef = cr1),DAE.ARRAY(array = elst2,dims=dims),_)
      //  then
      //    aliasArray(cr1,false,elst2,dims,inTpls);
      // -a = {b1,b2,b3,..}
      //case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ARRAY(array = elst2,dims=dims),_)
      //  then
      //    aliasArray(cr1,true,elst2,dims,inTpls);
      // a = -{b1,b2,b3,..}
      //case (DAE.CREF(componentRef = cr1),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.ARRAY(array = elst2,ty=ty)),_)
      // -a = -{b1,b2,b3,..}
      //case (DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.ARRAY(array = elst2,ty=ty)),_)
      // {a1,a2,a3,..} = b
      //case (DAE.ARRAY(array = elst1),DAE.CREF(componentRef = cr2),_)
      // -{a1,a2,a3,..} = b
      //case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.ARRAY(array = elst1,ty=ty)),DAE.CREF(componentRef = cr2),_)
      // {a1,a2,a3,..} = -b
      //case (DAE.ARRAY(array = elst1),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_)
      // -{a1,a2,a3,..} = -b
      //case (DAE.UNARY(DAE.UMINUS_ARR(_)DAE.ARRAY(array = elst1,ty=ty)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(componentRef = cr2)),_)
      // not a = {b1,b2,b3,..}
      //case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ARRAY(array = elst2,ty=ty),_)
      // a = not {b1,b2,b3,..}
      //case (DAE.CREF(componentRef = cr1),DAE.LUNARY(DAE.NOT(_),DAE.ARRAY(array = elst2,ty=ty)),_)
      // not a = not {b1,b2,b3,..}
      //case (DAE.LUNARY(DAE.NOT(_),e1 as DAE.CREF(componentRef = cr1)),DAE.LUNARY(DAE.NOT(_),DAE.ARRAY(array = elst2,ty=ty)),_)
      // {a1,a2,a3,..} = not b
      //case (DAE.ARRAY(array = elst1,ty=ty),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_)
      // not {a1,a2,a3,..} = b
      //case (DAE.LUNARY(DAE.NOT(_),DAE.ARRAY(array = elst1,ty=ty)),DAE.CREF(componentRef = cr2),_)
      // not {a1,a2,a3,..} = not b
      //case (DAE.LUNARY(DAE.NOT(_),DAE.ARRAY(array = elst1,ty=ty)),DAE.LUNARY(DAE.NOT(_),e2 as DAE.CREF(componentRef = cr2)),_)
      // a = Record(b1,b2,b3,..)
      case (DAE.CREF(componentRef = cr1),DAE.CALL(path=pathb,expLst=elst2,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=varLst2,complexClassType=ClassInf.RECORD(pathb1)))),_)
        equation
          true = Absyn.pathEqual(pathb,pathb1);
        then
          aliasRecord(cr1,varLst2,elst2,inTpls);
      // Record(a1,a2,a3,..) = b
      case (DAE.CALL(path=patha,expLst=elst1,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=varLst1,complexClassType=ClassInf.RECORD(patha1)))),DAE.CREF(componentRef = cr2),_)
        equation
          true = Absyn.pathEqual(patha,patha1);
        then
          aliasRecord(cr2,varLst1,elst1,inTpls);
      // Record(a1,a2,a3,..) = Record(b1,b2,b3,..)
      case (DAE.CALL(path=patha,expLst=elst1,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(patha1)))),
            DAE.CALL(path=pathb,expLst=elst2,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(pathb1)))),_)
        equation
          true = Absyn.pathEqual(patha,patha1);
          true = Absyn.pathEqual(pathb,pathb1);
        then List.threadFold(elst1,elst2,aliasEquation1,inTpls);
      // matchcontinue part
      else
        then aliasEquation2(lhs,rhs,inTpls);
  end match;
end aliasEquation1;

protected function aliasEquationLst
"author Frenkel TUD 2011-04
  helper for aliasEquation"
  input list<DAE.Exp> elst1;
  input list<DAE.Exp> elst2;
  input list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> inTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
  output list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> outTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
algorithm
  outTpls := List.threadFold(elst1,elst2,aliasEquation1,inTpls);
end aliasEquationLst;

protected function aliasEquation2
"author Frenkel TUD 2011-04
  helper for aliasEquation"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> inTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
  output list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> outTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
algorithm
  outTpls := matchcontinue (lhs,rhs,inTpls)
    local
      list<DAE.Exp> elst1,elst2;
    // {a1+b1,a2+b2,a3+b3,..} = 0;
    case (DAE.ARRAY(array = elst1),_,_)
      equation
        true = Expression.isZero(rhs);
      then List.fold(elst1,aliasExpression,inTpls);
    // 0 = {a1+b1,a2+b2,a3+b3,..};
    case (_,DAE.ARRAY(array = elst2),_)
      equation
        true = Expression.isZero(lhs);
      then List.fold(elst2,aliasExpression,inTpls);
    // lhs = 0
    case (_,_,_)
      equation
        true = Expression.isZero(rhs);
       then aliasExpression(lhs,inTpls);
    // 0 = rhs
    case (_,_,_)
      equation
        true = Expression.isZero(lhs);
      then aliasExpression(rhs,inTpls);
  end matchcontinue;
end aliasEquation2;

// protected function aliasArray
// "//   author Frenkel TUD 2011-04
//   helper for aliasEquation"
//   input DAE.ComponentRef cr;
//   input Boolean negate;
//   input list<DAE.Exp> explst;
//   input DAE.Type iTy;
//   input list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> inTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
//   output list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> outTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
// algorithm
//   outTpls := match (cr,negate,explst,iTy,inTpls)
//     local
//       DAE.ComponentRef cr1,cr2;
//       DAE.Exp e1,e2;
//       DAE.Type ty,ty1;
//       list<DAE.Exp> elst;
//     case (_,_,{},_,_) then inTpls;
//     // a = b
//     case (_,_,(e2 as DAE.CREF(componentRef = cr2))::elst,_,_)
//       equation
//       then
//         aliasArray(cr,negate,elst,iTy,inTpls);
//     // a = -b
//     // a = not b
//   end match;
// end aliasArray;

protected function aliasRecord
"author Frenkel TUD 2011-04
  helper for aliasEquation"
  input DAE.ComponentRef cr;
  input list<DAE.Var> varLst;
  input list<DAE.Exp> explst;
  input list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> inTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
  output list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> outTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
algorithm
  outTpls := match (cr,varLst,explst,inTpls)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e1,e2;
      DAE.Type ty,ty1;
      list<DAE.Exp> elst;
      list<DAE.Var> vlst;
      DAE.Ident ident;
    case (_,{},{},_) then inTpls;
    // a = b
    case (_,DAE.TYPES_VAR(name=ident,ty=ty)::vlst,(e2 as DAE.CREF(componentRef = cr2))::elst,_)
      equation
        cr1 = ComponentReference.crefPrependIdent(cr,ident,{},ty);
        e1 = DAE.CREF(cr1,ty);
      then
        aliasRecord(cr,vlst,elst,(cr1,cr2,e1,e2,false)::inTpls);
    // a = -b
    case (_,DAE.TYPES_VAR(name=ident,ty=ty)::vlst,(e2 as DAE.UNARY(DAE.UMINUS(ty1),DAE.CREF(componentRef = cr2)))::elst,_)
      equation
        cr1 = ComponentReference.crefPrependIdent(cr,ident,{},ty);
        e1 = DAE.UNARY(DAE.UMINUS(ty1),DAE.CREF(cr1,ty));
      then
        aliasRecord(cr,vlst,elst,(cr1,cr2,e1,e2,true)::inTpls);
    case (_,DAE.TYPES_VAR(name=ident,ty=ty)::vlst,(e2 as DAE.UNARY(DAE.UMINUS_ARR(ty1),DAE.CREF(componentRef = cr2)))::elst,_)
      equation
        cr1 = ComponentReference.crefPrependIdent(cr,ident,{},ty);
        e1 = DAE.UNARY(DAE.UMINUS_ARR(ty1),DAE.CREF(cr1,ty));
      then
        aliasRecord(cr,vlst,elst,(cr1,cr2,e1,e2,true)::inTpls);
    // a = not b
    case (_,DAE.TYPES_VAR(name=ident,ty=ty)::vlst,(e2 as DAE.LUNARY(DAE.NOT(ty1),DAE.CREF(componentRef = cr2)))::elst,_)
      equation
        cr1 = ComponentReference.crefPrependIdent(cr,ident,{},ty);
        e1 = DAE.LUNARY(DAE.NOT(ty1),DAE.CREF(cr1,ty));
      then
        aliasRecord(cr,vlst,elst,(cr1,cr2,e1,e2,true)::inTpls);
    // a = {b1,b2,b3}
  end match;
end aliasRecord;

protected function aliasExpression
"author Frenkel TUD 2011-11
  Returns the two sides of an alias expression as expressions and cref.
  If the expression is not simple, this function will fail."
  input DAE.Exp exp;
  input list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> inTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
  output list<tuple<DAE.ComponentRef,DAE.ComponentRef,DAE.Exp,DAE.Exp,Boolean>> outTpls "(cr1,cr2,cr1=e2,cr2=e1,true if negated alias)";
algorithm
  outTpls := match (exp,inTpls)
      local
        DAE.ComponentRef cr1,cr2;
        DAE.Exp e1,e2;
        DAE.Type ty;
      // a + b
      case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,DAE.UNARY(DAE.UMINUS(ty),e1),DAE.UNARY(DAE.UMINUS(ty),e2),true)::inTpls;
      case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.UNARY(DAE.UMINUS_ARR(ty),e2),true)::inTpls;
      // a - b
      case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,e2,false)::inTpls;
      case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,e2,false)::inTpls;
      // -a + b
      case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,e2,false)::inTpls;
      case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,e2,false)::inTpls;
      // -a - b = 0
      case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,DAE.UNARY(DAE.UMINUS(ty),e2),true)::inTpls;
      case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=ty),e2 as DAE.CREF(componentRef = cr2)),_)
        then (cr1,cr2,e1,DAE.UNARY(DAE.UMINUS_ARR(ty),e2),true)::inTpls;
  end match;
end aliasExpression;

public function derivativeEquation
"author Frenkel TUD 2011-04
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
        DAE.Exp ne,ne2;
      // a = der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr),scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})))
        then (cr,dcr,e,de,false);
      // der(a) = b;
      case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),scalar=e as DAE.CREF(componentRef = dcr)))
        then (cr,dcr,e,de,false);
      // a = -der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr),scalar=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr),scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))))
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
        equation
          ne = Expression.negate(e);
          ne2 = Expression.negate(de);
        then (cr,dcr,ne,ne2,false);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))))
        equation
          ne = Expression.negate(e);
          ne2 = Expression.negate(de);
        then (cr,dcr,ne,ne2,false);
      // -der(a) = -b;
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr))))
        equation
          ne = Expression.negate(e);
          ne2 = Expression.negate(de);
        then (cr,dcr,ne,ne2,false);
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr))))
        equation
          ne = Expression.negate(e);
          ne2 = Expression.negate(de);
        then (cr,dcr,ne,ne2,false);
  end match;
end derivativeEquation;

public function addOperation
  input BackendDAE.Equation eq;
  input DAE.SymbolicOperation op;
  output BackendDAE.Equation oeq;
algorithm
  oeq := match (eq,op)
    local
      Integer size;
      DAE.Exp e1,e2;
      list<DAE.Exp> conditions;
      DAE.ElementSource source;
      BackendDAE.WhenEquation whenEquation;
      DAE.ComponentRef cr1;
      list<BackendDAE.Equation> eqnsfalse;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<Integer> ds;
      DAE.Algorithm alg;
      Boolean diffed;
      DAE.Expand crefExpand;
      BackendDAE.EquationKind eqKind;

    case (BackendDAE.EQUATION(e1,e2,source,diffed,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.EQUATION(e1,e2,source,diffed,eqKind);

    case (BackendDAE.ARRAY_EQUATION(ds,e1,e2,source,diffed,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.ARRAY_EQUATION(ds,e1,e2,source,diffed,eqKind);

    case (BackendDAE.SOLVED_EQUATION(cr1,e1,source,diffed,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.SOLVED_EQUATION(cr1,e1,source,diffed,eqKind);

    case (BackendDAE.RESIDUAL_EQUATION(e1,source,diffed,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.RESIDUAL_EQUATION(e1,source,diffed,eqKind);

    case (BackendDAE.ALGORITHM(size,alg,source,crefExpand,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.ALGORITHM(size,alg,source,crefExpand,eqKind);

    case (BackendDAE.WHEN_EQUATION(size,whenEquation,source,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.WHEN_EQUATION(size,whenEquation,source,eqKind);

    case (BackendDAE.COMPLEX_EQUATION(size,e1,e2,source,diffed,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.COMPLEX_EQUATION(size,e1,e2,source,diffed,eqKind);

    case (BackendDAE.IF_EQUATION(conditions,eqnstrue,eqnsfalse,source,eqKind),_)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.IF_EQUATION(conditions,eqnstrue,eqnsfalse,source,eqKind);

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
    else false;
  end match;
end isWhenEquation;

public function isArrayEquation
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match(inEqn)
    case BackendDAE.ARRAY_EQUATION(source=_) then true;
    else false;
  end match;
end isArrayEquation;

public function isAlgorithm
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match(inEqn)
    case BackendDAE.ALGORITHM(source=_) then true;
    else false;
  end match;
end isAlgorithm;

public function isNotAlgorithm
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := not isAlgorithm(inEqn);
end isNotAlgorithm;

public function markDifferentiated
  input BackendDAE.Equation iEqn;
  output BackendDAE.Equation oEqn;
algorithm
  oEqn := match(iEqn)
    local
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      Integer size;
      list<Integer> dimSize;
      list<DAE.Exp> conditions;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqnsfalse;
      BackendDAE.EquationKind eqKind;

    case BackendDAE.EQUATION(exp=e1,scalar=e2,source=source,kind=eqKind)
      then BackendDAE.EQUATION(e1,e2,source,true,eqKind);
    case BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left=e1,right=e2,source=source,kind=eqKind)
      then BackendDAE.ARRAY_EQUATION(dimSize,e1,e2,source,true,eqKind);
    case BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e2,source=source,kind=eqKind)
      then BackendDAE.SOLVED_EQUATION(cr,e2,source,true,eqKind);
    case BackendDAE.RESIDUAL_EQUATION(exp=e2,source=source,kind=eqKind)
      then BackendDAE.RESIDUAL_EQUATION(e2,source,true,eqKind);
    case BackendDAE.COMPLEX_EQUATION(size=size,left=e1,right=e2,source=source,kind=eqKind)
      then BackendDAE.COMPLEX_EQUATION(size,e1,e2,source,true,eqKind);
    case BackendDAE.ALGORITHM(source=_)
      then iEqn;
    case BackendDAE.WHEN_EQUATION(source=_)
      then iEqn;
    case BackendDAE.IF_EQUATION(conditions=conditions,eqnstrue=eqnstrue,eqnsfalse=eqnsfalse,source=source,kind=eqKind)
      equation
        eqnstrue = List.mapList(eqnstrue,markDifferentiated);
        eqnsfalse = List.map(eqnsfalse,markDifferentiated);
      then BackendDAE.IF_EQUATION(conditions,eqnstrue,eqnsfalse,source,eqKind);
  end match;
end markDifferentiated;

public function isDifferentiated
  input BackendDAE.Equation iEqn;
  output Boolean diffed;
algorithm
  diffed := match(iEqn)
    local
      Boolean b;
      BackendDAE.Equation eqn;
    case BackendDAE.EQUATION(differentiated=b) then b;
    case BackendDAE.ARRAY_EQUATION(differentiated=b) then b;
    case BackendDAE.SOLVED_EQUATION(differentiated=b) then b;
    case BackendDAE.RESIDUAL_EQUATION(differentiated=b) then b;
    case BackendDAE.COMPLEX_EQUATION(differentiated=b) then b;
    case BackendDAE.ALGORITHM(source=_) then false;
    case BackendDAE.WHEN_EQUATION(source=_) then false;
    case BackendDAE.IF_EQUATION(eqnsfalse=eqn::_) then isDifferentiated(eqn);
  end match;
end isDifferentiated;

public function replaceDerOpInEquationList
  "Replaces all der(cref) with $DER.cref in a list of equations."
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := List.map(inEqns, replaceDerOpInEquation);
end replaceDerOpInEquationList;

protected function replaceDerOpInEquation
  "Replaces all der(cref) with $DER.cref in an equation."
  input BackendDAE.Equation inEqn;
  output BackendDAE.Equation outEqn;
algorithm

  outEqn := matchcontinue(inEqn)
    local
      DAE.Exp e1, e2;
      DAE.ElementSource src;
      DAE.ComponentRef cr;
      list<Integer> dimSize;
      Integer size;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts, stmts1;
      Boolean diffed;
      DAE.Expand crefExpand;
      BackendDAE.EquationKind eqKind;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=src, differentiated=diffed, kind=eqKind))
      equation
        e1 = Expression.replaceDerOpInExp(e1);
        e2 = Expression.replaceDerOpInExp(e2);
      then
        BackendDAE.EQUATION(e1, e2, src, diffed, eqKind);

    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left=e1, right=e2, source=src, differentiated=diffed, kind=eqKind))
      equation
        e1 = Expression.replaceDerOpInExp(e1);
        e2 = Expression.replaceDerOpInExp(e2);
      then
        BackendDAE.ARRAY_EQUATION(dimSize, e1, e2, src, diffed, eqKind);

    case (BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=src, differentiated=diffed, kind=eqKind))
      equation
        e1 = Expression.replaceDerOpInExp(e1);
        e2 = Expression.replaceDerOpInExp(e2);
      then
        BackendDAE.COMPLEX_EQUATION(size, e1, e2, src, diffed, eqKind);

    case (BackendDAE.RESIDUAL_EQUATION(exp=e1, source=src, differentiated=diffed, kind=eqKind))
      equation
        e1 = Expression.replaceDerOpInExp(e1);
      then
        BackendDAE.RESIDUAL_EQUATION(e1, src, diffed, eqKind);

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e1, source=src, differentiated=diffed, kind=eqKind))
      equation
        e1 = Expression.replaceDerOpInExp(e1);
      then
        BackendDAE.SOLVED_EQUATION(cr, e1, src, diffed, eqKind);

    case (BackendDAE.ALGORITHM(size=size, alg=alg as DAE.ALGORITHM_STMTS(statementLst=stmts), source=src, expand=crefExpand, kind=eqKind))
      equation
        (stmts1, _) = DAEUtil.traverseDAEEquationsStmts(stmts, Expression.replaceDerOpInExpTraverser, NONE());
        alg = Util.if_(referenceEq(stmts, stmts1), alg, DAE.ALGORITHM_STMTS(stmts1));
      then
        BackendDAE.ALGORITHM(size, alg, src, crefExpand, eqKind);

    case (_) then inEqn;

  end matchcontinue;
end replaceDerOpInEquation;

end BackendEquation;
