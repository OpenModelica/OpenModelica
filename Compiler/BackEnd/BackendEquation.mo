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
               BackendDAEEquation data type.

  RCS: $Id$
"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import Algorithm;
protected import Array;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendVariable;
protected import BaseHashTable;
protected import BinaryTreeInt;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import FCore;
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
  Transform the a list of equations into an expandable BackendDAE.Equation
  array."
  input list<BackendDAE.Equation> inEquationList;
  output BackendDAE.EquationArray outEquationArray;
protected
  Integer len, size, arrsize;
  Real rlen;
  array<Option<BackendDAE.Equation>> optarr;
algorithm
  len := listLength(inEquationList);
  rlen := intReal(len) * 1.4;
  arrsize := realInt(rlen);
  optarr := arrayCreate(arrsize, NONE());
  (size, optarr) := listEquation1(inEquationList, 1, 0, optarr);
  outEquationArray := BackendDAE.EQUATION_ARRAY(size, len, arrsize, optarr);
end listEquation;

protected function listEquation1
  input list<BackendDAE.Equation> inEquationList;
  input Integer inPos "initially call this with 1";
  input Integer inSize "initially call this with 0";
  input array<Option<BackendDAE.Equation>> inEquOptArr;
  output Integer outSize;
  output array<Option<BackendDAE.Equation>> outEquOptArr;
algorithm
  (outSize, outEquOptArr) := match (inEquationList, inPos, inSize, inEquOptArr)
    local
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> rest;
      Integer size;
      array<Option<BackendDAE.Equation>> equOptArr;

    case ({}, _, _, _)
    then (inSize, inEquOptArr);

    case (eq::rest, _, _, _) equation
      size = equationSize(eq);
      equOptArr = arrayUpdate(inEquOptArr, inPos, SOME(eq));
      (size, equOptArr) = listEquation1(rest, inPos+1, size+inSize, equOptArr);
    then (size, equOptArr);
  end match;
end listEquation1;

public function emptyEqns "
  Returns an empty expandable equation array."
  output BackendDAE.EquationArray eqns;
algorithm
  eqns := listEquation({});
end emptyEqns;

public function emptyEqnsSized "
  Returns an empty expandable equation array with a given size."
  input Integer size;
  output BackendDAE.EquationArray outEquationArray;
protected
  array<Option<BackendDAE.Equation>> equOptArr;
algorithm
  equOptArr := arrayCreate(size, NONE());
  outEquationArray := BackendDAE.EQUATION_ARRAY(0, 0, size, equOptArr);
end emptyEqnsSized;

public function equationList "author: PA
  Transform the expandable BackendDAE.Equation array to a list of Equations."
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inEquationArray)
    local
      array<Option<BackendDAE.Equation>> arr;
      BackendDAE.Equation elt;
      Integer n, size;
      list<BackendDAE.Equation> lst;

    case (BackendDAE.EQUATION_ARRAY(numberOfElement=0))
    then {};

    case (BackendDAE.EQUATION_ARRAY(numberOfElement=1, equOptArr=arr)) equation
      SOME(elt) = arr[1];
    then {elt};

    case (BackendDAE.EQUATION_ARRAY(numberOfElement=n, equOptArr=arr)) equation
      lst = equationList2(arr, n, {});
    then lst;

    case (_) equation
      print("- BackendDAEUtil.equationList failed\n");
    then fail();
  end matchcontinue;
end equationList;

protected function equationList2 "author: PA
  Helper function toequationList
  inputs:  (Equation option array, int /* pos */, int /* lastpos */)
  outputs: BackendDAE.Equation list"
  input array<Option<BackendDAE.Equation>> arr;
  input Integer pos;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := match (arr, pos, iAcc)
    case (_, 0, _)
    then iAcc;

    else equationList2(arr, pos-1, List.consOption(arr[pos], iAcc));
  end match;
end equationList2;

public function getWhenEquationExpr "
  Get the left and right hand parts from an equation appearing in a when clause"
  input BackendDAE.WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  BackendDAE.WHEN_EQ(left=outComponentRef, right=outExp) := inWhenEquation;
end getWhenEquationExpr;

public function copyEquationArray "author: wbraun
  Performs a deep copy of an expandable equation array."
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
protected
  Integer numberOfElement, size, arrSize;
  array<Option<BackendDAE.Equation>> equOptArr, newEquOptArr;
algorithm
  BackendDAE.EQUATION_ARRAY(size, numberOfElement, arrSize, equOptArr) := inEquationArray;
  newEquOptArr := arrayCopy(equOptArr);
  outEquationArray := BackendDAE.EQUATION_ARRAY(size, numberOfElement, arrSize, newEquOptArr);
end copyEquationArray;

public function equationsLstVars
"author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occurring variables form the array."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  (_, (_, bt)) := traverseExpsOfEquationList(inEquationLst, checkEquationsVarsExpTopDownTraverseHelper, (inVars, bt));
  (keys, _) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys, BackendVariable.getVarAt, inVars);
end equationsLstVars;

public function equationsVars
"author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occurring variables form the array."
  input BackendDAE.EquationArray inEquations;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  (_, bt) := BackendDAEUtil.traverseBackendDAEExpsEqns(inEquations, checkEquationsVarsExpTopDownTraverseHelper, (inVars, bt));
  (keys, _) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys, BackendVariable.getVarAt, inVars);
end equationsVars;

public function equationsVars2
"author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occurring variables form the array."
  input BackendDAE.EquationArray inEquations;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outVars;
protected
  BinaryTreeInt.BinTree bt;
  list<Integer> keys;
algorithm
  bt := BinaryTreeInt.emptyBinTree;
  (_, bt) := BackendDAEUtil.traverseBackendDAEExpsEqns(inEquations, checkEquationsVarsExpTopDownTraverseHelper, (inVars, bt) );
  (keys, _) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys, BackendVariable.getVarAt, inVars);
end equationsVars2;

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
  (_, (_, bt)) := traverseExpsOfEquation(inEquation, checkEquationsVarsExpTopDownTraverseHelper,  (inVars, bt));
  (keys, _) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys, BackendVariable.getVarAt, inVars);
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
  (_, (_, bt)) := Expression.traverseExpTopDown(inExp, checkEquationsVarsExpTopDown, (inVars, bt));
  (keys, _) := BinaryTreeInt.bintreeToList(bt);
  outVars := List.map1r(keys, BackendVariable.getVarAt, inVars);
end expressionVars;

public function checkEquationsVarsExpTopDownTraverseHelper
"This function traverses expssions to-down to collect all
 variables that are involed into the expression."
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, BinaryTreeInt.BinTree> itpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, BinaryTreeInt.BinTree> otpl;
algorithm
  (outExp, otpl) := Expression.traverseExpTopDown(inExp,checkEquationsVarsExpTopDown,itpl);
end checkEquationsVarsExpTopDownTraverseHelper;

protected function checkEquationsVarsExpTopDown
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, BinaryTreeInt.BinTree> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables, BinaryTreeInt.BinTree> outTuple;
algorithm
  (outExp,cont,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      BinaryTreeInt.BinTree bt;
      DAE.ComponentRef cr;
      list<Integer> ilst;

    // special case for time, it is never part of the equation system
    case (e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")), (vars, bt))
    then (e, true, (vars, bt));

    // case for function pointers
    case (e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC()), (vars, bt))
    then (e, true, (vars, bt));

    // case for pre vars
    case (e as DAE.CALL(path = Absyn.IDENT(name = "pre")), _)
    then (inExp, false, inTuple);

    // add it
    case (e as DAE.CREF(componentRef = cr), (vars, bt)) equation
      (_, ilst) = BackendVariable.getVar(cr, vars);
      bt = BinaryTreeInt.treeAddList(bt, ilst);
    then (e, true, (vars, bt));

    else (inExp, true, inTuple);
  end matchcontinue;
end checkEquationsVarsExpTopDown;

public function equationsStates "author: Frenkel TUD
  From a list of equations return all occurring state variables references."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_, (_,(outExpComponentRefLst, _))) := traverseExpsOfEquationList(inEquationLst, Expression.traverseSubexpressionsHelper, (traversingStateRefFinder, ({}, inVars)));
end equationsStates;

protected function traversingStateRefFinder "author: Frenkel TUD 2011-05"
  input DAE.Exp inExp;
  input tuple<list<DAE.ComponentRef>, BackendDAE.Variables> inTpl;
  output DAE.Exp outExp;
  output tuple<list<DAE.ComponentRef>, BackendDAE.Variables> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      BackendDAE.Variables vars;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef cr;
      DAE.Exp e;

    case (e as DAE.CREF(componentRef=cr), (crefs, vars)) equation
      true = BackendVariable.isState(cr, vars);
      crefs = List.unionEltOnTrue(cr, crefs, ComponentReference.crefEqual);
    then (e, (crefs, vars));

    else (inExp,inTpl);
  end matchcontinue;
end traversingStateRefFinder;

public function equationsParams "author: marcusw
  From a list of equations return all occurring parameter variables. Duplicates are removed."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Var> outParamVars;
  output list<Integer> outParamVarsIdc;
algorithm
  (_, (_,(outParamVars,outParamVarsIdc,_))) := traverseExpsOfEquationList(inEquationLst, Expression.traverseSubexpressionsHelper, (traversingParamRefFinder, ({}, {}, inVars)));
end equationsParams;

protected function traversingParamRefFinder "author: marcusw
  Checks if the given expression is a parameter variable and adds it to the result list on true. Duplicates are removed."
  input DAE.Exp inExp;
  input tuple<list<BackendDAE.Var>, list<Integer>, BackendDAE.Variables> inTpl; //<result list, result idc, all variables>
  output DAE.Exp outExp;
  output tuple<list<BackendDAE.Var>, list<Integer>, BackendDAE.Variables> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue(inExp,inTpl)
    local
      BackendDAE.Variables allVars;
      list<BackendDAE.Var> vars, foundVars;
      list<Integer> varIdc, foundVarsIdc;
      DAE.ComponentRef cr;
      DAE.Exp e;

    case (e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")), (vars, varIdc, allVars))
      then (e, (vars, varIdc, allVars));
    case (e as DAE.CREF(componentRef=cr), (vars, varIdc, allVars)) equation
      //print("traversingParamRefFinder: try to get Variable " + ComponentReference.crefStr(cr) + "\n");
      (foundVars, foundVarsIdc) = BackendVariable.getVar(cr, allVars);
      (vars, varIdc) = traversingParamRefFinder0(foundVars, foundVarsIdc, vars, varIdc);
      then (e, (vars, varIdc, allVars));
    else (inExp,inTpl);
  end matchcontinue;
end traversingParamRefFinder;

protected function traversingParamRefFinder0
  input list<BackendDAE.Var> iVars;
  input list<Integer> iVarIdc;
  input list<BackendDAE.Var> iParamVarsList;
  input list<Integer> iParamVarsIdc;
  output list<BackendDAE.Var> oParamVarsList;
  output list<Integer> oParamVarIdc;
protected
  BackendDAE.Var var;
  list<BackendDAE.Var> vars = iParamVarsList;
  list<Integer> varIdc = iParamVarsIdc;
  Integer varIdx;
  list<Integer> rest = iVarIdc;
algorithm
  for var in iVars loop
    varIdx::rest := rest;
    if(BackendVariable.isParam(var)) then
      vars := List.unionEltOnTrue(var, vars, BackendVariable.varEqual);
      varIdc := List.unionEltOnTrue(varIdx, varIdc, intEq);
    end if;
  end for;
  oParamVarsList := vars;
  oParamVarIdc := varIdc;
end traversingParamRefFinder0;

public function iterationVarsinRelations
 "From a list of equations return all variables, which used inside
  a relation, then this equation system is marked as mixed and also
  the indexes of the relations may be used in future."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  output Boolean mixedSystem;
  output list<Integer> indexes;
algorithm
  (_, (_,(indexes, _))) := traverseExpsOfEquationList(inEquationLst, Expression.traverseSubexpressionsHelper, (traversingRelationsforIterationVars, ({}, inVars)));
  mixedSystem := not listEmpty(indexes);
end iterationVarsinRelations;

protected function traversingRelationsforIterationVars
  input DAE.Exp inExp;
  input tuple<list<Integer>, BackendDAE.Variables> inTpl;
  output DAE.Exp outExp;
  output tuple<list<Integer>, BackendDAE.Variables> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      BackendDAE.Variables vars;
      list<Integer> indexes;
      DAE.Exp e, e1, e2;
      Integer index;
      list<BackendDAE.Var> vlst1,vlst2;

    case (e as DAE.RELATION(exp1=e1, exp2=e2, index=index), (indexes, vars))
      equation
        vlst1 = expressionVars(e1, vars);
        vlst2 = expressionVars(e2, vars);
        //if lists are not empty continue
        _::_ = listAppend(vlst1, vlst2);
    then (e, (index::indexes, vars));

    else (inExp,inTpl);
  end matchcontinue;
end traversingRelationsforIterationVars;

public function equationsCrefs "author: PA
  From a list of equations return all occurring variables/component references."
  input list<BackendDAE.Equation> inEquationLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_, (_,outExpComponentRefLst)) := traverseExpsOfEquationList(inEquationLst, Expression.traverseSubexpressionsHelper, (Expression.traversingComponentRefFinder, {}));
end equationsCrefs;

public function equationCrefs "author: PA
  From one equation return all occurring component references."
  input BackendDAE.Equation inEquation;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := equationsCrefs({inEquation});
end equationCrefs;

public function getAllCrefFromEquations
  input BackendDAE.EquationArray inEqns;
  output list<DAE.ComponentRef> cr_lst;
algorithm
  cr_lst := traverseEquationArray(inEqns, traversingEquationCrefFinder, {});
end getAllCrefFromEquations;

protected function traversingEquationCrefFinder "author: Frenkel TUD 2010-11"
  input BackendDAE.Equation inEq;
  input list<DAE.ComponentRef> inCrefs;
  output BackendDAE.Equation e;
  output list<DAE.ComponentRef> cr_lst;
algorithm
  e := inEq;
  cr_lst := inCrefs;
  (_, (_,cr_lst)) := traverseExpsOfEquation(e, Expression.traverseSubexpressionsHelper, (Expression.traversingComponentRefFinder, cr_lst));
end traversingEquationCrefFinder;

public function equationUnknownCrefs "author: Frenkel TUD 2012-05
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
  (_, (_, (_, _, ht))) := traverseExpsOfEquationList(inEquationLst, Expression.traverseSubexpressionsHelper, (checkEquationsUnknownCrefsExp, (inVars, inKnVars, ht)));
  cr_lst := BaseHashTable.hashTableKeyList(ht);
end equationUnknownCrefs;

protected function checkEquationsUnknownCrefsExp
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, HashTable.HashTable> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, HashTable.HashTable> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e, e1;
      BackendDAE.Variables vars, knvars;
      HashTable.HashTable ht;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;

    // special case for time, it is never part of the equation system
    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")), _)
      then (inExp, inTuple);

    // special case for records
    case (e as DAE.CREF(componentRef = cr, ty= DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(_))), _)
      equation
        expl = List.map1(varLst, Expression.generateCrefsExpFromExpVar, cr);
        (_, outTuple) = Expression.traverseExpList(expl, checkEquationsUnknownCrefsExp, inTuple);
      then (e, outTuple);

    // special case for arrays
    case (e as DAE.CREF(ty = DAE.T_ARRAY()), _)
      equation
        (e1, true) = Expression.extendArrExp(e, false);
        (_, outTuple) = Expression.traverseExpBottomUp(e1, checkEquationsUnknownCrefsExp, inTuple);
      then (e, outTuple);

    // case for function pointers
    case (DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC()), _)
      then (inExp, inTuple);

    // already there
    case (DAE.CREF(componentRef = cr), (_, _, ht))
      equation
        _ = BaseHashTable.get(cr, ht);
      then (inExp, inTuple);

    // known
    case (DAE.CREF(componentRef = cr), (vars, _, _))
      equation
       (_, _) = BackendVariable.getVar(cr, vars);
      then (inExp, inTuple);

    case (DAE.CREF(componentRef = cr), (_, knvars, _))
      equation
        (_, _) = BackendVariable.getVar(cr, knvars);
      then (inExp, inTuple);

    // add it
    case (DAE.CREF(componentRef = cr), (vars, knvars, ht))
      equation
        ht = BaseHashTable.add((cr, 0), ht);
      then (inExp, (vars, knvars, ht));

    else (inExp,inTuple);
  end matchcontinue;
end checkEquationsUnknownCrefsExp;

public function traverseExpsOfEquationList<ArgT> "author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the
  equations and the multidim equations and the algorithms."
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType func;
  input ArgT inArg;
  output list<BackendDAE.Equation> outEquations = {};
  output ArgT outArg = inArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncExpType;
algorithm
  for eq in inEquations loop
    (eq, outArg) := traverseExpsOfEquation(eq, func, outArg);
    outEquations := eq::outEquations;
  end for;

  outEquations := listReverse(outEquations);
end traverseExpsOfEquationList;

protected function traverseExpsOfEquationList_WithStop "author: Frenkel TUD 2012-09
  Traverses all expressions of a list of equations.
  It is possible to change the equations."
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType inFunc;
  input Type_a inTypeA;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outA;
  end FuncExpType;
algorithm
  (outBoolean, outTypeA) := match (inEquations, inFunc, inTypeA)
    local
      Type_a arg;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      Boolean b;

    case ({}, _, _)
    then (true, inTypeA);

    case (eqn::eqns, _, _) equation
      (b, arg) = traverseExpsOfEquation_WithStop(eqn, inFunc, inTypeA);
      if b then
        (b, arg) = traverseExpsOfEquationList_WithStop(eqns, inFunc, arg);
      end if;
    then (b, arg);
  end match;
end traverseExpsOfEquationList_WithStop;

protected function traverseExpsOfEquationListList_WithStop<T> "author: Frenkel TUD 2012-09
  Traverses all expressions of a list of equations.
  It is possible to change the equations."
  input list<list<BackendDAE.Equation>> inEquations;
  input FuncExpType func;
  input T inTypeA;
  output Boolean outBoolean;
  output T outTypeA;

  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output T outA;
  end FuncExpType;
algorithm
  (outBoolean, outTypeA) := match (inEquations, func, inTypeA)
    local
      T arg;
      list<BackendDAE.Equation> eqn;
      list<list<BackendDAE.Equation>> eqns;
      Boolean b;

    case ({}, _, _)
    then (true, inTypeA);

    case (eqn::eqns, _, _) equation
      (b, arg) = traverseExpsOfEquationList_WithStop(eqn, func, inTypeA);
      if b then
        (b, arg) = traverseExpsOfEquationListList_WithStop(eqns, func, arg);
      end if;
    then (b, arg);
  end match;
end traverseExpsOfEquationListList_WithStop;

public function traverseExpsOfEquation<T> "author: Frenkel TUD 2010-11
  Traverses all expressions of a equation.
  It is possible to change the equation."
  input BackendDAE.Equation inEquation;
  input FuncExpType inFunc;
  input T inTypeA;
  output BackendDAE.Equation outEquation;
  output T outTypeA;

  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output T outTypeA;
  end FuncExpType;
algorithm
  (outEquation, outTypeA) := match(inEquation)
    local
      DAE.Exp e1, e2, e_1, e_2, cond, start, stop, iter;
      list<DAE.Exp> expl;
      DAE.Type tp;
      DAE.ComponentRef cr, cr1;
      BackendDAE.WhenEquation elsePart, elsePart1;
      DAE.ElementSource source;
      Integer size;
      T extArg;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts, stmts1;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes attr;

    case BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=attr) equation
      (e_1, extArg) = inFunc(e1, inTypeA);
      (e_2, extArg) = inFunc(e2, extArg);
    then (BackendDAE.EQUATION(e_1, e_2, source, attr), extArg);

    case BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left=e1, right=e2, source=source, attr=attr) equation
      (e_1, extArg) = inFunc(e1, inTypeA);
      (e_2, extArg) = inFunc(e2, extArg);
    then (BackendDAE.ARRAY_EQUATION(dimSize, e_1, e_2, source, attr), extArg);

    case BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2, source=source, attr=attr) equation
      tp = Expression.typeof(e2);
      e1 = Expression.makeCrefExp(cr, tp);
      (DAE.CREF(cr1, _), extArg) = inFunc(e1, inTypeA);
      (e_2, extArg) = inFunc(e2, extArg);
    then (BackendDAE.SOLVED_EQUATION(cr1, e_2, source, attr), extArg);

    case BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source, attr=attr) equation
      (e_1, extArg) = inFunc(e1, inTypeA);
    then (BackendDAE.RESIDUAL_EQUATION(e_1, source, attr), extArg);

    case BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e2, elsewhenPart=NONE()), source=source, attr=attr) equation
      tp = Expression.typeof(e2);
      e1 = Expression.makeCrefExp(cr, tp);
      (e1, extArg) = inFunc(e1, inTypeA);
      if Expression.isCref(e1) then
        DAE.CREF(cr1, _) = e1;
      else
        cr1=cr;
      end if;
      (e_2, extArg) = inFunc(e2, extArg);
      (cond, extArg) = inFunc(cond, extArg);
    then (BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(cond, cr1, e_2, NONE()), source, attr), extArg);

    case BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e2, elsewhenPart=SOME(elsePart)), source=source, attr=attr) equation
      tp = Expression.typeof(e2);
      e1 = Expression.makeCrefExp(cr, tp);
      (e1, extArg) = inFunc(e1, inTypeA);
      if Expression.isCref(e1) then
        DAE.CREF(cr1, _) = e1;
      else
        cr1=cr;
      end if;
      (e_2, extArg) = inFunc(e2, extArg);
      (cond, extArg) = inFunc(cond, extArg);
      (BackendDAE.WHEN_EQUATION(whenEquation=elsePart1), extArg) = traverseExpsOfEquation(BackendDAE.WHEN_EQUATION(size, elsePart, source, attr), inFunc, extArg);
    then (BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(cond, cr1, e_2, SOME(elsePart1)), source, attr), extArg);

    case BackendDAE.ALGORITHM(size=size, alg=alg as DAE.ALGORITHM_STMTS(statementLst = stmts), source=source, expand=crefExpand, attr=attr) equation
      (stmts1, extArg) = DAEUtil.traverseDAEEquationsStmts(stmts, inFunc, inTypeA);
      alg = if referenceEq(stmts, stmts1) then alg else DAE.ALGORITHM_STMTS(stmts1);
    then (BackendDAE.ALGORITHM(size, alg, source, crefExpand, attr), extArg);

    case BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, attr=attr) equation
      (e_1, extArg) = inFunc(e1, inTypeA);
      (e_2, extArg) = inFunc(e2, extArg);
    then (BackendDAE.COMPLEX_EQUATION(size, e_1, e_2, source, attr), extArg);

    case BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns, source=source, attr=attr) equation
      (expl, extArg) = traverseExpsOfExpList(expl, inFunc, inTypeA);
      (eqnslst, extArg) = List.map1Fold(eqnslst, traverseExpsOfEquationList, inFunc, extArg);
      (eqns, extArg) = List.map1Fold(eqns, traverseExpsOfEquation, inFunc, extArg);
    then (BackendDAE.IF_EQUATION(expl, eqnslst, eqns, source, attr), extArg);

    case BackendDAE.FOR_EQUATION(iter=iter,start=start,stop=stop,left=e1, right=e2, source=source, attr=attr) equation
      (e_1, extArg) = inFunc(e1, inTypeA);
      (e_2, extArg) = inFunc(e2, extArg);
    then (BackendDAE.FOR_EQUATION(iter,start,stop,e_1,e_2,source,attr), extArg);
  end match;
end traverseExpsOfEquation;

public function traverseExpsOfEquation_WithStop<T> "author: Frenkel TUD 2010-11
  Traverses all expressions of a equation.
  It is possible to change the equation."
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input T inTypeA;
  output Boolean outBoolean;
  output T outTypeA;

  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output T outA;
  end FuncExpType;
algorithm
  (outBoolean, outTypeA) := match (inEquation, func, inTypeA)
    local
      DAE.Exp e1, e2, cond;
      list<DAE.Exp> expl;
      DAE.Type tp;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source;
      Integer size;
      T ext_arg, ext_arg_1, ext_arg_2, ext_arg_3;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      Boolean b, b1, b2, b3, b4;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2), _, _)
      equation
        (_, b, ext_arg) = func(e1, inTypeA);
        if b then
          (_, b, ext_arg) = func(e2, ext_arg);
        end if;
      then (b, ext_arg);

    case (BackendDAE.ARRAY_EQUATION(left=e1, right=e2), _, _)
      equation
        (_, b, ext_arg) = func(e1, inTypeA);
        if b then
          (_, b, ext_arg) = func(e2, ext_arg);
        end if;
      then (b, ext_arg);

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2), _, _)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr, tp);
        (_, b, ext_arg) = func(e1, inTypeA);
        if b then
          (_, b, ext_arg) = func(e2, ext_arg);
        end if;
      then (b, ext_arg);

    case (BackendDAE.RESIDUAL_EQUATION(exp=e1), _, _)
      equation
        (_, b, ext_arg) = func(e1, inTypeA);
      then (b, ext_arg);

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e2, elsewhenPart=NONE())), _, _)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr, tp);
        (_, b, ext_arg) = func(e1, inTypeA);
        if b then
          (_, b, ext_arg) = func(e2, ext_arg);
        end if;
        if b then
          (_, b, ext_arg) = func(cond, ext_arg);
        end if;
      then (b, ext_arg);

    case (BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e2, elsewhenPart=SOME(elsePart)), source=source, attr=eqAttr), _, _)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr, tp);
        (_, b, ext_arg) = func(e1, inTypeA);
        if b then
          (_, b, ext_arg) = func(e2, ext_arg);
        end if;
        if b then
          (_, b, ext_arg) = func(cond, ext_arg);
        end if;
        if b then
          (b, ext_arg) = traverseExpsOfEquation_WithStop(BackendDAE.WHEN_EQUATION(size, elsePart, source, eqAttr), func, ext_arg);
        end if;
      then (b, ext_arg);

    case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS()), _, _)
      equation
        print("not implemented error - BackendDAE.ALGORITHM - BackendEquation.traverseExpsOfEquation_WithStop\n");
       // (stmts1, ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts, func, inTypeA);
      then fail();

    //(true, inTypeA);
    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2), _, _)
      equation
        (_, b, ext_arg) = func(e1, inTypeA);
        if b then
          (_, b, ext_arg) = func(e2, ext_arg);
        end if;
      then (b, ext_arg);

    case (BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns), _, _)
      equation
        (b, ext_arg) = traverseExpsOfExpList_WithStop(expl, func, inTypeA);
        if b then
          (b, ext_arg) = traverseExpsOfEquationListList_WithStop(eqnslst, func, ext_arg);
        end if;
        if b then
          (b, ext_arg) = traverseExpsOfEquationList_WithStop(eqns, func, ext_arg);
        end if;
      then (b, ext_arg);
  end match;
end traverseExpsOfEquation_WithStop;

protected function traverseExpsOfExpList<T> "author Frenkel TUD:
  Calls user function for each element of list."
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input T inExtArg;
  output list<DAE.Exp> outExpl;
  output T outTypeA;

  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output T outA;
  end FuncExpType;
algorithm
  (outExpl, outTypeA) := match (inExpl)
    local
      DAE.Exp e, e1;
      list<DAE.Exp> expl1, res;
      T extArg;

    case {}
    then ({}, inExtArg);

    case e::res equation
      (e1, extArg) = rel(e, inExtArg);
      (expl1, extArg) = traverseExpsOfExpList(res, rel, extArg);
    then (e1::expl1, extArg);
  end match;
end traverseExpsOfExpList;

protected function traverseExpsOfExpList_WithStop<T> "author Frenkel TUD
  Calls user function for each element of list."
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input T inExtArg;
  output Boolean outBoolean;
  output T outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output T outA;
  end FuncExpType;algorithm
  (outBoolean, outTypeA) := match(inExpl)
    local
      DAE.Exp e;
      list<DAE.Exp> res;
      T extArg;
      Boolean b;

    case {}
    then (true, inExtArg);

    case e::res equation
      (_, b, extArg) = rel(e, inExtArg);
      if b then
        (b, extArg) = traverseExpsOfExpList_WithStop(res, rel, extArg);
      end if;
    then (b, extArg);
  end match;
end traverseExpsOfExpList_WithStop;

public function traverseEquationArray<T> "author: Frenkel TUD
  Traverses all equations of a BackendDAE.EquationArray."
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input T inTypeA;
  output T outTypeA;

  partial function FuncExpType
    input BackendDAE.Equation inEq;
    input T inA;
    output BackendDAE.Equation outEq;
    output T outA;
  end FuncExpType;
protected
  array<Option<BackendDAE.Equation>> equOptArr;
algorithm
  //try
    BackendDAE.EQUATION_ARRAY(equOptArr=equOptArr) := inEquationArray;
    outTypeA := BackendDAEUtil.traverseArrayNoCopy(equOptArr, func, traverseOptEquation, inTypeA);
  //else
  //  if Flags.isSet(Flags.FAILTRACE) then
  //    Debug.trace("- BackendEquation.traverseEquationArray failed\n");
  //  end if;
  //  fail();
  //end try;
end traverseEquationArray;

public function traverseEquationArray_WithStop "author: Frenkel TUD
  Traverses all equations of a BackendDAE.EquationArray."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input FuncWithStop inFuncWithStop;
  input Type_a inTypeA;
  output Type_a outTypeA;

  partial function FuncWithStop
    input BackendDAE.Equation inEq;
    input Type_a inA;
    output BackendDAE.Equation outEq;
    output Boolean cont;
    output Type_a outA;
  end FuncWithStop;
protected
  array<Option<BackendDAE.Equation>> equOptArr;
algorithm
  //try
    BackendDAE.EQUATION_ARRAY(equOptArr=equOptArr) := inEquationArray;
    outTypeA := BackendDAEUtil.traverseArrayNoCopyWithStop(equOptArr, inFuncWithStop, traverseOptEquation_WithStop, inTypeA);
  //else
  //  if Flags.isSet(Flags.FAILTRACE) then
  //    Debug.trace("- BackendEquation.traverseEquationArray_WithStop failed\n");
  //  end if;
  //  fail();
  //end try;
end traverseEquationArray_WithStop;

protected function traverseOptEquation<T>
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input T inTypeA;
  output T outTypeA;

  partial function FuncExpType
    input BackendDAE.Equation inEq;
    input T inA;
    output BackendDAE.Equation outEq;
    output T outA;
  end FuncExpType;
algorithm
  outTypeA := match(inEquation)
    local
      BackendDAE.Equation eqn;
      T ext_arg;

    case NONE()
    then inTypeA;

    case SOME(eqn) equation
      (_, ext_arg) = func(eqn, inTypeA);
    then ext_arg;
  end match;
end traverseOptEquation;

protected function traverseOptEquation_WithStop<T>
  input Option<BackendDAE.Equation> inEquation;
  input FuncWithStop inFuncWithStop;
  input T inTypeA;
  output Boolean outBoolean;
  output T outTypeA;

  partial function FuncWithStop
    input BackendDAE.Equation inEq;
    input T inA;
    output BackendDAE.Equation outEq;
    output Boolean cont;
    output T outA;
  end FuncWithStop;
algorithm
  (outBoolean, outTypeA) :=  match(inEquation)
    local
      BackendDAE.Equation eqn;
      T ext_arg;
      Boolean b;

    case NONE()
    then (true, inTypeA);

    case SOME(eqn) equation
      (_, b, ext_arg) = inFuncWithStop(eqn, inTypeA);
    then (b, ext_arg);
  end match;
end traverseOptEquation_WithStop;

public function traverseEquationArray_WithUpdate<T> "author: Frenkel TUD
  Traverses all equations of a BackendDAE.EquationArray."
  input BackendDAE.EquationArray inEquationArray;
  input FuncWithUpdate inFuncWithUpdate;
  input T inTypeA;
  output BackendDAE.EquationArray outEquationArray;
  output T outTypeA;

  partial function FuncWithUpdate
    input BackendDAE.Equation inEq;
    input T inA;
    output BackendDAE.Equation outEq;
    output T outA;
  end FuncWithUpdate;
protected
  Integer numberOfElement, arrSize, size;
  array<Option<BackendDAE.Equation>> equOptArr;
algorithm
  BackendDAE.EQUATION_ARRAY(size=size, numberOfElement=numberOfElement, arrSize=arrSize, equOptArr=equOptArr) := inEquationArray;
  (equOptArr, outTypeA) := BackendDAEUtil.traverseArrayNoCopyWithUpdate(equOptArr, inFuncWithUpdate, traverseOptEquation_WithUpdate, inTypeA);
  outEquationArray := BackendDAE.EQUATION_ARRAY(size, numberOfElement, arrSize, equOptArr);
end traverseEquationArray_WithUpdate;

protected function traverseOptEquation_WithUpdate<T> "author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqnsWithUpdate."
  input Option<BackendDAE.Equation> inEquation;
  input FuncWithUpdate inFuncWithUpdate;
  input T inTypeA;
  output Option<BackendDAE.Equation> outEquation;
  output T outTypeA;

  partial function FuncWithUpdate
    input BackendDAE.Equation inEq;
    input T inA;
    output BackendDAE.Equation outEq;
    output T outA;
  end FuncWithUpdate;
algorithm
  (outEquation, outTypeA) :=  match(inEquation)
    local
      Option<BackendDAE.Equation> oeqn;
      BackendDAE.Equation eqn, eqn1;
      T ext_arg;

    case NONE()
    then (NONE(), inTypeA);

    case SOME(eqn) equation
      (eqn1, ext_arg) = inFuncWithUpdate(eqn, inTypeA);
      oeqn = if referenceEq(eqn, eqn1) then inEquation else SOME(eqn1);
    then (oeqn, ext_arg);
  end match;
end traverseOptEquation_WithUpdate;

public function equationEqual "
  Returns true if two equations are equal"
  input BackendDAE.Equation e1;
  input BackendDAE.Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue (e1, e2)
    local
      DAE.Exp e11, e12, e21, e22, exp1, exp2;
      DAE.ComponentRef cr1, cr2;
      DAE.Algorithm alg1, alg2;
      list<DAE.Exp> explst1, explst2;

    case (_, _) equation
      true = referenceEq(e1, e2);
    then true;

    case (BackendDAE.EQUATION(exp=e11, scalar=e12), BackendDAE.EQUATION(exp=e21, scalar=e22)) equation
      res = boolAnd(Expression.expEqual(e11, e21), Expression.expEqual(e12, e22));
    then res;

    case (BackendDAE.ARRAY_EQUATION(left=e11, right=e12), BackendDAE.ARRAY_EQUATION(left=e21, right=e22)) equation
      res = boolAnd(Expression.expEqual(e11, e21), Expression.expEqual(e12, e22));
    then res;

    case (BackendDAE.COMPLEX_EQUATION(left=e11, right=e12), BackendDAE.COMPLEX_EQUATION(left=e21, right=e22)) equation
      res = boolAnd(Expression.expEqual(e11, e21), Expression.expEqual(e12, e22));
    then res;

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr1, exp=exp1), BackendDAE.SOLVED_EQUATION(componentRef=cr2, exp=exp2)) equation
      res = boolAnd(ComponentReference.crefEqualNoStringCompare(cr1, cr2), Expression.expEqual(exp1, exp2));
    then res;

    case (BackendDAE.RESIDUAL_EQUATION(exp=exp1), BackendDAE.RESIDUAL_EQUATION(exp=exp2)) equation
      res = Expression.expEqual(exp1, exp2);
    then res;

    case (BackendDAE.ALGORITHM(alg=alg1), BackendDAE.ALGORITHM(alg=alg2)) equation
      explst1 = Algorithm.getAllExps(alg1);
      explst2 = Algorithm.getAllExps(alg2);
      res = List.isEqualOnTrue(explst1, explst2, Expression.expEqual);
    then res;

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left=cr1, right=exp1)), BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(left=cr2, right=exp2))) equation
      res = boolAnd(ComponentReference.crefEqualNoStringCompare(cr1, cr2), Expression.expEqual(exp1, exp2));
    then res;

    else false;
  end matchcontinue;
end equationEqual;

public function addEquations "author: wbraun
  Adds a list of BackendDAE.Equation to BackendDAE.EquationArray."
  input list<BackendDAE.Equation> eqnlst;
  input BackendDAE.EquationArray eqns;
  output BackendDAE.EquationArray eqns_1;
algorithm
  eqns_1 := List.fold(eqnlst, addEquation, eqns);
end addEquations;

public function mergeEquationArray "
  This function returns an EquationArray containing all the equations from both
  inputs."
  input BackendDAE.EquationArray inEqns1;
  input BackendDAE.EquationArray inEqns2;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns := addEquations(equationList(inEqns1), inEqns2);
end mergeEquationArray;

protected function findFirstUnusedEquOptEntry
  input Integer inPos "initially call this with 1";
  input Integer inSize;
  input array<Option<BackendDAE.Equation>> inEquOptArr;
  output Integer outIndex;
algorithm
  outIndex := findFirstUnusedEquOptEntryWork(inPos, inSize, inEquOptArr[inPos], inEquOptArr);
end findFirstUnusedEquOptEntry;

protected function findFirstUnusedEquOptEntryWork
  input Integer inPos "initially call this with 1";
  input Integer inSize;
  input Option<BackendDAE.Equation> thisValue;
  input array<Option<BackendDAE.Equation>> inEquOptArr;
  output Integer outIndex;
algorithm
  outIndex := match (inPos, inSize, thisValue, inEquOptArr)
    case (_, _, NONE(), _)
      then inPos;

    case (_, _, _, _)
      then findFirstUnusedEquOptEntryWork(inPos+1, inSize, arrayGet(inEquOptArr,inPos+1), inEquOptArr);
  end match;
end findFirstUnusedEquOptEntryWork;

public function addEquation "author: PA
  Adds an equation to an EquationArray."
  input BackendDAE.Equation inEquation;
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue (inEquation, inEquationArray)
    local
      Integer n_1, numberOfElement, arrSize, expandsize, expandsize_1, newsize, size, index;
      array<Option<BackendDAE.Equation>> arr_1, equOptArr, arr_2;
      BackendDAE.Equation e;
      Real rsize, rexpandsize;

    case (e, BackendDAE.EQUATION_ARRAY(size=size, numberOfElement=numberOfElement, arrSize=arrSize, equOptArr=equOptArr)) equation
      (numberOfElement < arrSize) = true "Have space to add array elt.";
      n_1 = numberOfElement + 1;
      index = findFirstUnusedEquOptEntry(n_1, arrSize, equOptArr);
      arr_1 = arrayUpdate(equOptArr, index, SOME(e));
      size = equationSize(e) + size;
    then BackendDAE.EQUATION_ARRAY(size, n_1, arrSize, arr_1);

    case (e, BackendDAE.EQUATION_ARRAY(size=size, numberOfElement=numberOfElement, arrSize=arrSize, equOptArr=equOptArr)) equation /* Do NOT Have space to add array elt. Expand array 1.4 times */
      (numberOfElement < arrSize) = false;
      rsize = intReal(arrSize);
      rexpandsize = rsize * 0.4;
      expandsize = realInt(rexpandsize);
      expandsize_1 = intMax(expandsize, 1);
      newsize = expandsize_1 + arrSize;
      arr_1 = Array.expand(expandsize_1, equOptArr, NONE());
      n_1 = numberOfElement + 1;
      arr_2 = arrayUpdate(arr_1, n_1, SOME(e));
      size = equationSize(e) + size;
    then BackendDAE.EQUATION_ARRAY(size, n_1, newsize, arr_2);

    case (_, BackendDAE.EQUATION_ARRAY(size=size, numberOfElement=numberOfElement, arrSize=arrSize, equOptArr=equOptArr)) equation
      print("- BackendEquation.addEquation failed\nArraySize: " + intString(arrSize) + "\nnumberOfElement " + intString(numberOfElement) + "\nSize " + intString(size) + "\narraySize " + intString(arrayLength(equOptArr)));
    then fail();
  end matchcontinue;
end addEquation;

public function equationAddDAE "author: Frenkel TUD 2011-05"
  input BackendDAE.Equation inEquation;
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs, newOrderedEqs;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars, orderedEqs, m, mT, _, stateSets, partitionKind) := inEqSystem;
  newOrderedEqs := addEquation(inEquation, orderedEqs);
  outEqSystem := BackendDAE.EQSYSTEM(orderedVars, newOrderedEqs, m, mT, BackendDAE.NO_MATCHING(), stateSets, partitionKind);
end equationAddDAE;

public function equationsAddDAE "author: Frenkel TUD 2011-05"
  input list<BackendDAE.Equation> inEquations;
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs, newOrderedEqs;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars, orderedEqs, m, mT, _, stateSets, partitionKind) := inEqSystem;
  newOrderedEqs := List.fold(inEquations, addEquation, orderedEqs);
  outEqSystem := BackendDAE.EQSYSTEM(orderedVars, newOrderedEqs, m, mT, BackendDAE.NO_MATCHING(), stateSets, partitionKind);
end equationsAddDAE;

public function requationsAddDAE "author: Frenkel TUD 2012-10
  Add a list of equations to removed equations of a BackendDAE.
  If the variable already exists, the function updates the variable."
  input list<BackendDAE.Equation> inEquations;
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
algorithm
  outShared := match (inEquations, inShared)
    local
      BackendDAE.Variables knvars, exobj, aliasVars;
      BackendDAE.EquationArray remeqns, inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph env;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;

    case ({}, _)
    then inShared;

    case (_, BackendDAE.SHARED(knvars, exobj, aliasVars, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei)) equation
      remeqns = List.fold(inEquations, addEquation, remeqns);
    then BackendDAE.SHARED(knvars, exobj, aliasVars, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei);
  end match;
end requationsAddDAE;

public function removeRemovedEqs
"
remove removedEqs
"
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
protected
      BackendDAE.Variables knvars, exobj, aliasVars;
      BackendDAE.EquationArray remeqns, inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph env;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.ExtraInfo ei;
      Integer n;
algorithm
  (BackendDAE.SHARED(knvars, exobj, aliasVars, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei)) := inShared;
  BackendDAE.EQUATION_ARRAY(numberOfElement=n) := remeqns;
  for ind in 1:n loop
    remeqns := equationRemove(ind, remeqns);
  end for;

  outShared := BackendDAE.SHARED(knvars, exobj, aliasVars, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei);

end removeRemovedEqs;

public function setAtIndex "author: lochel
  Sets the n-th array element of an EquationArray.
  Please note: one-based indexing"
  input BackendDAE.EquationArray inEquationArray;
  input Integer inPos "one-based indexing";
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
protected
  array<Option<BackendDAE.Equation>> equOptArr, newEquOptArr;
  Integer size, numberOfElement, arrSize;
algorithm
  BackendDAE.EQUATION_ARRAY(size, numberOfElement, arrSize, equOptArr) := inEquationArray;
  size := size -equationOptSize(equOptArr[inPos]) +equationSize(inEquation);
  newEquOptArr := arrayUpdate(equOptArr, inPos, SOME(inEquation));
  outEquationArray := BackendDAE.EQUATION_ARRAY(size, numberOfElement, arrSize, newEquOptArr);
end setAtIndex;

public function setAtIndexFirst "author: waurich
  Sets the n-th array element of an EquationArray but with index at first argument.
  Please note: one-based indexing"
  input Integer inPos "one-based indexing";
  input BackendDAE.Equation inEquation;
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray = setAtIndex(inEquationArray, inPos, inEquation);
end setAtIndexFirst;

public function getEqns "author: Frenkel TUD 2011-05
  returns the equations given by the list of indexes"
  input list<Integer> inIndices "one-based indexing";
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := List.map1r(inIndices, equationNth1, inEquationArray);
end getEqns;

public function equationNth1 "author: PA
  Return the n-th equation from the expandable equation array
  indexed from 1..N."
  input BackendDAE.EquationArray inEquationArray;
  input Integer inPos "one-based indexing";
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquationArray, inPos)
    local
      BackendDAE.Equation e;
      Integer n;
      array<Option<BackendDAE.Equation>> arr;
      String str;

    case (BackendDAE.EQUATION_ARRAY(numberOfElement=n, equOptArr=arr), _) equation
      true = intLe(inPos, n);
      SOME(e) = arr[inPos];
    then e;

    case (BackendDAE.EQUATION_ARRAY(numberOfElement=n), _) equation
      str = "BackendEquation.equationNth1 failed; numberOfElement=" + intString(n) + "; pos=" + intString(inPos);
      print(str + "\n");
      Error.addInternalError(str, sourceInfo());
    then fail();
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

    case ({}, _, _) equation
      str = "BackendEquation.equationNthSize1 failed";
      print(str + "\n");
      Error.addInternalError(str, sourceInfo());
    then fail();

    case (eqn::_, _, _) equation
      size = equationSize(eqn);
      true = (pos >= acc);
      true = (pos < acc+size);
    then eqn;

    case (eqn::eqns, _, _) equation
      size = equationSize(eqn);
      true = (pos >= acc+size);
    then equationNthSize1(eqns, pos, acc+size);

    else equation
      str = "BackendEquation.equationNthSize1 failed";
      print(str + "\n");
      Error.addInternalError(str, sourceInfo());
    then fail();
  end matchcontinue;
end equationNthSize1;

public function equationDelete "author: Frenkel TUD 2010-12
  Deletes all the equations from a given list of indices."
  input BackendDAE.EquationArray inEquationArray;
  input list<Integer> inIndices;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue (inEquationArray, inIndices)
    local
      list<BackendDAE.Equation> eqnlst;
      Integer numberOfElement, arrSize;
      array<Option<BackendDAE.Equation>> equOptArr;

    case (_, {})
    then inEquationArray;

    case (BackendDAE.EQUATION_ARRAY(arrSize=arrSize, equOptArr=equOptArr), _) equation
      equOptArr = List.fold1r(inIndices, arrayUpdate, NONE(), equOptArr);
      eqnlst = equationDelete1(arrSize, equOptArr, {});
    then listEquation(eqnlst);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- BackendDAE.equationDelete failed\n");
      then fail();
  end matchcontinue;
end equationDelete;

protected function equationDelete1 "author: Frenkel TUD 2012-09
  helper for equationDelete."
  input Integer index;
  input array<Option<BackendDAE.Equation>> equOptArr;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oAcc;
algorithm
  oAcc := matchcontinue (index, equOptArr, iAcc)
    local
      BackendDAE.Equation eqn;

    case (0, _, _)
    then iAcc;

    case (_, _, _) equation
      SOME(eqn) = equOptArr[index];
    then equationDelete1(index-1, equOptArr, eqn::iAcc);

    case (_, _, _)
    then equationDelete1(index-1, equOptArr, iAcc);
  end matchcontinue;
end equationDelete1;

public function equationRemove "author: Frenkel TUD 2012-09
  Removes the equations from the array on the given position but
  does not scale down the array size"
  input Integer inPos "one-based indexing";
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue (inPos, inEquationArray)
    local
      Integer numberOfElement, arrSize, size, size1, eqnsize;
      array<Option<BackendDAE.Equation>> equOptArr;
      BackendDAE.Equation eqn;

    case (_, BackendDAE.EQUATION_ARRAY(size=size, numberOfElement=numberOfElement, arrSize=arrSize, equOptArr=equOptArr)) equation
      true = intLe(inPos, numberOfElement);
      SOME(eqn) = equOptArr[inPos];
      equOptArr = arrayUpdate(equOptArr, inPos, NONE());
      eqnsize = equationSize(eqn);
      size1 = size - eqnsize;
    then BackendDAE.EQUATION_ARRAY(size1, numberOfElement, arrSize, equOptArr);

    //case (_, BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfElement, equOptArr=equOptArr)) equation
    //  true = intLe(inPos, numberOfElement);
    //  NONE() = equOptArr[inPos];
    //then inEquationArray;

    else equation
      print("BackendDAE.equationRemove failed\n");
      Error.addInternalError("BackendDAE.equationRemove failed", sourceInfo());
    then fail();
  end matchcontinue;
end equationRemove;

public function compressEquations "author: Frenkel TUD 2012-11
  Closes the gaps of an expandable equation array.
  TODO: Not used. Should it get removed?"
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue (inEquationArray)
    local
      Integer numberOfElement, arrSize;
      array<Option<BackendDAE.Equation>> equOptArr;

    case BackendDAE.EQUATION_ARRAY(numberOfElement=numberOfElement, equOptArr=equOptArr) equation
      outEquationArray = emptyEqnsSized(numberOfElement);
    then compressEquations1(1, numberOfElement, equOptArr, outEquationArray);

    else equation
      print("BackendEquation.compressEquations failed\n");
    then fail();
  end matchcontinue;
end compressEquations;

protected function compressEquations1 "author: Frenkel TUD 2012-09"
  input Integer index;
  input Integer nEqns;
  input array<Option<BackendDAE.Equation>> equOptArr;
  input BackendDAE.EquationArray iEqns;
  output BackendDAE.EquationArray oEqns;
algorithm
  oEqns := matchcontinue (index, nEqns, equOptArr, iEqns)
    local
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns;

    // found element
    case (_, _, _, _) equation
      true = intLe(index, nEqns);
      SOME(eqn) = equOptArr[index];
      eqns = addEquation(eqn, iEqns);
    then compressEquations1(index+1, nEqns, equOptArr, eqns);

    // found non element
    case (_, _, _, _) equation
      true = intLe(index, nEqns);
      NONE() = equOptArr[index];
    then compressEquations1(index+1, nEqns, equOptArr, iEqns);

    // at the end
    case (_, _, _, _) equation
      false = intLe(index, nEqns);
    then iEqns;

    else equation
      print("BackendEquation.compressEquations1 failed for index " + intString(index) + " and Number of Equations " + intString(nEqns) + "\n");
    then fail();
  end matchcontinue;
end compressEquations1;

public function equationToScalarResidualForm "author: Frenkel TUD 2012-06
  This function transforms an equation to its scalar residual form.
  For instance, a=b is transformed to a-b=0, and the instance {a[1], a[2]}=b to a[1]=b[1] and a[2]=b[2]"
  input BackendDAE.Equation inEquation;
  output list<BackendDAE.Equation> outEquations;
algorithm

  outEquations := match (inEquation)
    local
      DAE.Exp e, e1, e2, exp;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      BackendDAE.Equation backendEq;
      list<Integer> ds;
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqns;
      list<list<DAE.Subscript>> subslst;
      Real r;
      BackendDAE.EquationAttributes attr;

    case (BackendDAE.EQUATION(exp=DAE.TUPLE(explst), scalar=e2, source=source, attr=attr)) equation
      ((_, eqns)) = List.fold3(explst,equationTupleToScalarResidualForm, e2, source, attr, (1, {}));
    then eqns;

    case (BackendDAE.EQUATION(exp= DAE.RCONST(real= 0.0), scalar=e2, source=source, attr=attr)) equation
      (e, _) = ExpressionSimplify.simplify(e2);
      eqns ={BackendDAE.RESIDUAL_EQUATION(e, source, attr)};
    then eqns;

    case (BackendDAE.EQUATION(exp=e1, scalar= DAE.RCONST(real=0.0), source=source, attr=attr)) equation
      (e, _) = ExpressionSimplify.simplify(e1);
      eqns ={BackendDAE.RESIDUAL_EQUATION(e, source, attr)};
    then eqns;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=attr)) equation
      exp = Expression.createResidualExp(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then {BackendDAE.RESIDUAL_EQUATION(e, source, attr)};

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2, source=source, attr=attr)) equation
      e1 = Expression.crefExp(cr);
      exp = Expression.createResidualExp(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then {BackendDAE.RESIDUAL_EQUATION(e, source, attr)};

    case (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2, source=source, attr=attr)) equation
      exp = Expression.createResidualExp(e1, e2);
      subslst = Expression.dimensionSizesSubscripts(ds);
      subslst = Expression.rangesToSubscripts(subslst);
      explst = List.map1r(subslst, Expression.applyExpSubscripts, exp);
      explst = ExpressionSimplify.simplifyList(explst, {});
      eqns = List.map2(explst, generateRESIDUAL_EQUATION, source, attr);
    then eqns;

    case (backendEq as BackendDAE.COMPLEX_EQUATION())
    then {backendEq};

    case (backendEq as BackendDAE.RESIDUAL_EQUATION())
    then {backendEq};

    case (backendEq as BackendDAE.ALGORITHM())
    then {backendEq};

    case (backendEq as BackendDAE.WHEN_EQUATION())
    then {backendEq};

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- BackendDAE.equationToScalarResidualForm failed\n");
      then fail();
  end match;
end equationToScalarResidualForm;

protected function equationTupleToScalarResidualForm "
  Tuple-expressions (function calls) that need to be converted to residual form
  are scalarized in a stupid, straight-forward way."
  input DAE.Exp cr;
  input DAE.Exp exp;
  input DAE.ElementSource inSource;
  input BackendDAE.EquationAttributes inEqAttr;
  input tuple<Integer, list<BackendDAE.Equation>> inTpl;
  output tuple<Integer, list<BackendDAE.Equation>> outTpl;
algorithm
  outTpl := match (cr, exp, inSource, inEqAttr, inTpl)
    local
      Integer i;
      list<BackendDAE.Equation> eqs;
      String str;
      DAE.Exp e;

    // wild-card does not produce a residual
    case (DAE.CREF(componentRef=DAE.WILD()), _, _, _, (i, eqs))
    then ((i+1, eqs));

    // 0-length arrays do not produce a residual
    case (DAE.ARRAY(array={}), _, _, _, (i, eqs))
    then ((i+1, eqs));

    // a scalar real
    case (DAE.CREF(ty=DAE.T_REAL()), _, _, _, (i, eqs)) equation
      eqs = BackendDAE.RESIDUAL_EQUATION(DAE.TSUB(exp, i, DAE.T_REAL_DEFAULT), inSource, inEqAttr)::eqs;
    then ((i+1, eqs));

    // create a sum for arrays...
    case (DAE.CREF(ty=DAE.T_ARRAY(ty=DAE.T_REAL())), _, _, _, (i, eqs)) equation
      e = Expression.makePureBuiltinCall("sum", {DAE.TSUB(exp, i, DAE.T_REAL_DEFAULT)}, DAE.T_REAL_DEFAULT);
      eqs = BackendDAE.RESIDUAL_EQUATION(e, inSource, inEqAttr)::eqs;
    then ((i+1, eqs));

    case (_, _, _, _, (i, _)) equation
      str = "BackendEquation.equationTupleToScalarResidualForm failed: " + intString(i) + ": " + ExpressionDump.printExpStr(cr);
      Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, DAEUtil.getElementSourceFileInfo(inSource));
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
      DAE.Exp e, e1, e2, exp;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      BackendDAE.Equation backendEq;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr)) equation
      //ExpressionDump.dumpExpWithTitle("equationToResidualForm 1\n", e2);
      exp = Expression.createResidualExp(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then BackendDAE.RESIDUAL_EQUATION(e, source, eqAttr);

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2, source=source, attr=eqAttr)) equation
      e1 = Expression.crefExp(cr);
      exp = Expression.createResidualExp(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then BackendDAE.RESIDUAL_EQUATION(e, source, eqAttr);

    case (BackendDAE.ARRAY_EQUATION(left=e1, right=e2, source=source, attr=eqAttr)) equation
      exp = Expression.createResidualExp(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then BackendDAE.RESIDUAL_EQUATION(e, source, eqAttr);

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, attr=eqAttr)) equation
      exp = Expression.createResidualExp(e1, e2);
      (e, _) = ExpressionSimplify.simplify(exp);
    then BackendDAE.RESIDUAL_EQUATION(e, source, eqAttr);

    case (backendEq as BackendDAE.RESIDUAL_EQUATION())
    then backendEq;

    case (backendEq as BackendDAE.ALGORITHM())
    then backendEq;

    case (backendEq as BackendDAE.WHEN_EQUATION())
    then backendEq;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- BackendDAE.equationToResidualForm failed\n");
      then fail();
  end matchcontinue;
end equationToResidualForm;

public function traverseEquationToScalarResidualForm
"author: Frenkel TUD 2010-11"
  input BackendDAE.Equation inEq;
  input list<BackendDAE.Equation> inEqs;
  output BackendDAE.Equation outEq;
  output list<BackendDAE.Equation> outEqs;
algorithm
  (outEq,outEqs) := matchcontinue(inEq,inEqs)
    local
      list<BackendDAE.Equation> eqns,reqn;
      BackendDAE.Equation eqn;

    case (eqn, eqns)
      equation
        reqn = equationToScalarResidualForm(eqn);
        eqns = listAppend(reqn,eqns);
      then (eqn, eqns);

    else (inEq,inEqs);
  end matchcontinue;
end traverseEquationToScalarResidualForm;

public function equationInfo "
  Retrieve the line number information from a BackendDAE.BackendDAEequation"
  input BackendDAE.Equation eq;
  output SourceInfo info;
algorithm
  info := DAEUtil.getElementSourceFileInfo(equationSource(eq));
end equationInfo;

public function markedEquationSource
  input BackendDAE.EqSystem syst;
  input Integer inPos "one-based indexing";
  output DAE.ElementSource outSource;
protected
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=eqns) := syst;
  outSource := equationSource(equationNth1(eqns, inPos));
end markedEquationSource;

public function equationSource "
  Retrieve the source from a BackendDAE.BackendDAEequation"
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

public function equationSize "
  Retrieve the size from a BackendDAE.BackendDAEequation"
  input BackendDAE.Equation eq;
  output Integer osize;
algorithm
  osize := match eq
    local
      list<Integer> ds;
      Integer size, start, stop;
      list<BackendDAE.Equation> eqnsfalse;

    case BackendDAE.EQUATION()
    then 1;

    case BackendDAE.ARRAY_EQUATION(dimSize=ds) equation
      size = List.fold(ds, intMul, 1);
    then size;

    case BackendDAE.SOLVED_EQUATION()
    then 1;

    case BackendDAE.RESIDUAL_EQUATION()
    then 1;

    case BackendDAE.WHEN_EQUATION(size=size)
    then size;

    case BackendDAE.ALGORITHM(size=size)
    then size;

    case BackendDAE.COMPLEX_EQUATION(size=size)
    then size;

    case BackendDAE.IF_EQUATION(eqnsfalse=eqnsfalse) equation
      size = equationLstSize(eqnsfalse);
    then size;

    case BackendDAE.FOR_EQUATION(start=DAE.ICONST(start), stop=DAE.ICONST(stop)) equation
      size = stop-start+1;
    then size;

    else equation
      Error.addInternalError("BackendEquation.equationSize failed!", sourceInfo());
    then fail();
  end match;
end equationSize;

public function isInitialEquation
  input BackendDAE.Equation inEquation;
  output Boolean outBool;
protected
  BackendDAE.EquationKind eqKind;
algorithm
  eqKind := equationKind(inEquation);
  outBool := isInitialEqKind(eqKind);
end isInitialEquation;

public function isInitialEqKind
  input BackendDAE.EquationKind inEqKind;
  output Boolean outBool;
algorithm
  outBool := match (inEqKind)
    case (BackendDAE.INITIAL_EQUATION()) then true;
    else false;
  end match;
end isInitialEqKind;

public function equationKind "Retrieve the kind from a BackendDAE.BackendDAEequation"
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationKind outEqKind;
algorithm
  outEqKind := match inEquation
    local
      BackendDAE.EquationKind kind;

    case BackendDAE.EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    case BackendDAE.ARRAY_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    case BackendDAE.SOLVED_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    case BackendDAE.RESIDUAL_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    case BackendDAE.WHEN_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    case BackendDAE.ALGORITHM(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    case BackendDAE.COMPLEX_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    case BackendDAE.IF_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(kind=kind)) then kind;
    else equation
      Error.addInternalError("BackendEquation.equationKind failed!", sourceInfo());
    then fail();
  end match;
end equationKind;

public function equationOptSize
  input Option<BackendDAE.Equation> oeqn;
  output Integer size;
algorithm
  size := match (oeqn)
    local BackendDAE.Equation eqn;
    case (NONE()) then 0;
    case (SOME(eqn)) then equationSize(eqn);
  end match;
end equationOptSize;

public function equationLstSize
  input list<BackendDAE.Equation> inEqns;
  output Integer size;
algorithm
  size := equationLstSize_impl(inEqns, 0);
end equationLstSize;

protected function equationLstSize_impl
  input list<BackendDAE.Equation> inEqns;
  input Integer isize;
  output Integer size;
algorithm
  size := match (inEqns, isize)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest;

    case ({}, _)
    then isize;

    case (eqn::rest, _)
    then equationLstSize_impl(rest, isize+equationSize(eqn));
  end match;
end equationLstSize_impl;

public function generateEquation "author Frenkel TUD 2012-12
  helper to generate an equation from lhs and rhs.
  the type of this function is determined by the lhs.
  This function is called if an equation is found which is not simple"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes inEqAttr;
  output BackendDAE.Equation outEqn;
protected
  DAE.Type ty;
algorithm
  ty := Expression.typeof(lhs);
  outEqn := matchcontinue ()
    local
      Integer size;
      DAE.Dimensions dims;
      list<Integer> ds;
      Boolean b1, b2;

    // complex types to complex equations
    case () equation
      true = DAEUtil.expTypeComplex(ty) or DAEUtil.expTypeTuple(ty);
      size = Expression.sizeOf(ty);
    then BackendDAE.COMPLEX_EQUATION(size, lhs, rhs, source, inEqAttr);

    // array types to array equations
    case () equation
      true = DAEUtil.expTypeArray(ty);
      dims = Expression.arrayDimension(ty);
      ds = Expression.dimensionsSizes(dims);
    then BackendDAE.ARRAY_EQUATION(ds, lhs, rhs, source, inEqAttr);

    // other types
    case () equation
      b1 = DAEUtil.expTypeComplex(ty);
      b2 = DAEUtil.expTypeArray(ty);
      false = b1 or b2;
    then BackendDAE.EQUATION(lhs, rhs, source, inEqAttr);

    else equation
      // show only on failtrace!
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("- BackendEquation.generateEquation failed on: " + ExpressionDump.printExpStr(lhs) + " = " + ExpressionDump.printExpStr(rhs) + "\n");
    then fail();
  end matchcontinue;
end generateEquation;

public function generateEQUATION "author: Frenkel TUD 2010-05"
  input DAE.Exp iLhs;
  input DAE.Exp iRhs;
  input DAE.ElementSource Source;
  input BackendDAE.EquationKind inEqKind;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAE.EQUATION(iLhs, iRhs, Source, BackendDAE.EQUATION_ATTRIBUTES(false, inEqKind, 0, BackendDAE.NO_LOOP()));
end generateEQUATION;

public function setSubPartition "author: lochel"
  input BackendDAE.Equation inEqn;
  input Integer inSubClockPartitionIndex;
  output BackendDAE.Equation outEqn;
protected
  BackendDAE.EquationAttributes attr;
algorithm
  attr := getEquationAttributes(inEqn);
  attr := setSubClockPartitionIndex(attr, inSubClockPartitionIndex);
  outEqn := setEquationAttributes(inEqn, attr);
end setSubPartition;

public function getEquationAttributes
  input BackendDAE.Equation inEqn;
  output BackendDAE.EquationAttributes outAttr;
algorithm
  outAttr := match inEqn
    local
      BackendDAE.EquationAttributes attr;

    case BackendDAE.EQUATION(attr=attr) then attr;
    case BackendDAE.ARRAY_EQUATION(attr=attr) then attr;
    case BackendDAE.SOLVED_EQUATION(attr=attr) then attr;
    case BackendDAE.RESIDUAL_EQUATION(attr=attr) then attr;
    case BackendDAE.ALGORITHM(attr=attr) then attr;
    case BackendDAE.WHEN_EQUATION(attr=attr) then attr;
    case BackendDAE.COMPLEX_EQUATION(attr=attr) then attr;
    case BackendDAE.IF_EQUATION(attr=attr) then attr;
    case BackendDAE.FOR_EQUATION(attr=attr) then attr;

    else equation
      Error.addInternalError("./Compiler/BackEnd/BackendEquation.mo: function getEquationAttributes failed", sourceInfo());
    then fail();
  end match;
end getEquationAttributes;

public function setSubClockPartitionIndex
  input BackendDAE.EquationAttributes inAttr;
  input Integer inSubClockPartitionIndex;
  output BackendDAE.EquationAttributes outAttr;
protected
  Boolean differentiated;
  BackendDAE.EquationKind kind;
  BackendDAE.LoopInfo loopInfo;
algorithm
  BackendDAE.EQUATION_ATTRIBUTES(differentiated=differentiated, kind=kind, loopInfo=loopInfo) := inAttr;
  outAttr := BackendDAE.EQUATION_ATTRIBUTES(differentiated, kind, inSubClockPartitionIndex, loopInfo);
end setSubClockPartitionIndex;

public function setEquationAttributes
  input BackendDAE.Equation inEqn;
  input BackendDAE.EquationAttributes inAttr;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := match (inEqn, inAttr)
    local
      DAE.ElementSource source;
      list<Integer> dimSize;
      DAE.Exp lhs;
      DAE.Exp rhs;
      DAE.ComponentRef componentRef;
      Integer size;
      DAE.Algorithm alg;
      DAE.Expand expand;
      BackendDAE.WhenEquation whenEquation;
      list< .DAE.Exp> conditions;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqnsfalse;

    case (BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), _)
    then BackendDAE.EQUATION(lhs, rhs, source, inAttr);

    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left=lhs, right=rhs, source=source), _)
    then BackendDAE.ARRAY_EQUATION(dimSize, lhs, rhs, source, inAttr);

    case (BackendDAE.SOLVED_EQUATION(componentRef=componentRef, exp=rhs, source=source), _)
    then BackendDAE.SOLVED_EQUATION(componentRef, rhs, source, inAttr);

    case (BackendDAE.RESIDUAL_EQUATION(exp=rhs, source=source), _)
    then BackendDAE.RESIDUAL_EQUATION(rhs, source, inAttr);

    case (BackendDAE.ALGORITHM(size=size, alg=alg, source=source, expand=expand), _)
    then BackendDAE.ALGORITHM(size, alg, source, expand, inAttr);

    case (BackendDAE.WHEN_EQUATION(size=size, whenEquation=whenEquation, source=source), _)
    then BackendDAE.WHEN_EQUATION(size, whenEquation, source, inAttr);

    case (BackendDAE.COMPLEX_EQUATION(size=size, left=lhs, right=rhs, source=source), _)
    then BackendDAE.COMPLEX_EQUATION(size, lhs, rhs, source, inAttr);

    case (BackendDAE.IF_EQUATION(conditions=conditions, eqnstrue=eqnstrue, eqnsfalse=eqnsfalse, source=source), _)
    then BackendDAE.IF_EQUATION(conditions, eqnstrue, eqnsfalse, source, inAttr);

    else equation
      Error.addInternalError("./Compiler/BackEnd/BackendEquation.mo: function setEquationAttributes failed", sourceInfo());
    then fail();
  end match;
end setEquationAttributes;

public function generateSolvedEqnsfromOption "author: Frenkel TUD 2010-05"
  input DAE.ComponentRef inLhs;
  input Option<DAE.Exp> inRhs;
  input DAE.ElementSource inSource;
  input BackendDAE.EquationKind inEqKind;
  output list<BackendDAE.Equation> outEqn;
algorithm
  outEqn :=  match (inLhs, inRhs, inSource, inEqKind)
  local
    DAE.Exp rhs;

    case (_, SOME(rhs), _, _)
    then {BackendDAE.SOLVED_EQUATION(inLhs, rhs, inSource, BackendDAE.EQUATION_ATTRIBUTES(false, inEqKind, 0, BackendDAE.NO_LOOP()))};

    else {};
  end match;
end generateSolvedEqnsfromOption;

public function generateResidualFromRelation "author: vitalij"
  input String conCrefName;
  input DAE.Exp iRhs;
  input DAE.ElementSource Source;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables knvars;
  input BackendDAE.VarKind conKind;

  output list<BackendDAE.Equation> outEqn;
  output BackendDAE.Var vout;
algorithm
  (outEqn, vout) :=  match (conCrefName, iRhs)
    local
      DAE.Exp rhs, e1, e2 , expNull, lowBound;
      DAE.ComponentRef lhs, cr;
      BackendDAE.Var dummyVar, v;
      BackendDAE.Equation eqn;

    case (_, DAE.RELATION(e1, DAE.LESS(_), e2, _, _)) equation
      lhs = ComponentReference.makeCrefIdent(conCrefName, DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, conKind, DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      rhs = Expression.expSub(e1,e2);
      (rhs, _) = ExpressionSimplify.simplify1(rhs);
      expNull = DAE.RCONST(0.0);
      lowBound = DAE.RCONST(-1e21);
      dummyVar = BackendVariable.setVarMinMax(dummyVar, SOME(lowBound), SOME(expNull));
    then ({BackendDAE.SOLVED_EQUATION(lhs, rhs, Source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, dummyVar);

    case (_, DAE.RELATION(e1, DAE.LESSEQ(_), e2, _, _)) equation
      lhs = ComponentReference.makeCrefIdent(conCrefName, DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, conKind, DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      rhs = Expression.expSub(e1,e2);
      (rhs, _) = ExpressionSimplify.simplify1(rhs);
      expNull = DAE.RCONST(0.0);
      lowBound = DAE.RCONST(-1e21);
      dummyVar = BackendVariable.setVarMinMax(dummyVar, SOME(lowBound), SOME(expNull));
    then ({BackendDAE.SOLVED_EQUATION(lhs, rhs, Source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, dummyVar);

    case (_, DAE.RELATION(e1, DAE.GREATER(_), e2, _, _)) equation
      lhs = ComponentReference.makeCrefIdent(conCrefName, DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, conKind, DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      rhs =  Expression.expSub(e2,e1);
      (rhs, _) = ExpressionSimplify.simplify1(rhs);
      expNull = DAE.RCONST(0.0);
      lowBound = DAE.RCONST(-1e21);
      dummyVar = BackendVariable.setVarMinMax(dummyVar, SOME(lowBound), SOME(expNull));
    then ({BackendDAE.SOLVED_EQUATION(lhs, rhs, Source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, dummyVar);

    case (_, DAE.RELATION(e1, DAE.GREATEREQ(_), e2, _, _)) equation
      lhs = ComponentReference.makeCrefIdent(conCrefName, DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, conKind, DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      rhs =  Expression.expSub(e2,e1);
      (rhs, _) = ExpressionSimplify.simplify(rhs);
      expNull = DAE.RCONST(0.0);
      lowBound = DAE.RCONST(-1e21);
      dummyVar = BackendVariable.setVarMinMax(dummyVar, SOME(lowBound), SOME(expNull));
    then ({BackendDAE.SOLVED_EQUATION(lhs, rhs, Source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, dummyVar);

    case (_, DAE.RELATION(e1, DAE.EQUAL(_), e2, _, _)) equation
      lhs = ComponentReference.makeCrefIdent(conCrefName, DAE.T_REAL_DEFAULT, {});
      dummyVar = BackendDAE.VAR(lhs, conKind, DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      rhs =  Expression.expSub(e2,e1);
      (rhs, _) = ExpressionSimplify.simplify(rhs);
      expNull = DAE.RCONST(0.0);
      dummyVar = BackendVariable.setVarMinMax(dummyVar, SOME(expNull), SOME(expNull));
    then ({BackendDAE.SOLVED_EQUATION(lhs, rhs, Source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, dummyVar);

    case(_,e1 as DAE.CREF(componentRef = cr)) algorithm
      try
        ({v}, _) := BackendVariable.getVar(cr, inVars);
      else
        ({v}, _) := BackendVariable.getVar(cr, knvars);
      end try;

      lhs := ComponentReference.makeCrefIdent(conCrefName, DAE.T_REAL_DEFAULT, {});
      dummyVar := BackendDAE.VAR(lhs, conKind, DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      dummyVar := BackendVariable.mergeAliasVars(dummyVar, v, false, knvars);
      eqn := BackendDAE.SOLVED_EQUATION(lhs, e1, Source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);

    then ({eqn}, dummyVar);
    else fail();
  end match;
end generateResidualFromRelation;

public function makeTmpEqnForExp
"
  author: Vitalij Ruge
  make and append an eqn and var for expression
"
  input DAE.Exp iExp;
  input String name "var name";
  input Integer offset;
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Variables ivars;
  input BackendDAE.Shared ishared;

  output DAE.Exp oExp;
  output BackendDAE.EquationArray oeqns = ieqns;
  output BackendDAE.Variables ovars = ivars;
  output BackendDAE.Shared oshared = ishared;

protected
  DAE.ComponentRef cr;
  DAE.ComponentRef cr_time = ComponentReference.makeCrefIdent("time", DAE.T_REAL_DEFAULT , {});
  BackendDAE.Var tmpvar;
  String name_ = "__OMC__" + intString(offset) + "$" + name;
  DAE.Exp x, y;
  BackendDAE.Equation eqn;
  list<BackendDAE.Var> eqnVars, eqnKnVars, inputsKnVars, paramKnVars;
  BackendDAE.Variables knowVars;
  Boolean b;

algorithm

  (y, _) := ExpressionSimplify.simplify(iExp);
  b := Expression.isCref(y) or Expression.isConst(y);
  if not b then
    cr  := ComponentReference.makeCrefIdent(name_, DAE.T_REAL_DEFAULT , {});
    tmpvar := BackendVariable.makeVar(cr);
    x := Expression.crefExp(cr);
    oExp := x;

    eqn := BackendDAE.EQUATION(x, y, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    //BackendDump.printEquation(eqn);
    eqnVars := equationVars(eqn, ivars);
    b := listEmpty(eqnVars) and not Expression.expHasCref(y,cr_time);
    if b then
      knowVars := BackendVariable.daeKnVars(oshared);
      eqnKnVars := equationVars(eqn, knowVars);
      (inputsKnVars,_) := List.splitOnTrue(eqnKnVars, BackendVariable.isInput);
       b := listEmpty(inputsKnVars);
    end if;
    if b then
      tmpvar := BackendVariable.setBindExp(tmpvar, SOME(y));
      (paramKnVars,_) := List.splitOnTrue(eqnKnVars, BackendVariable.isParam);
      if listEmpty(paramKnVars) then
        tmpvar := BackendVariable.setVarKind(tmpvar, BackendDAE.CONST());
      else
        tmpvar := BackendVariable.setVarKind(tmpvar, BackendDAE.PARAM());
      end if;
      oshared := BackendVariable.addKnVarDAE(tmpvar, oshared);
    else
      oeqns := BackendEquation.addEquation(eqn, oeqns);
      ovars := BackendVariable.addVar(tmpvar, ovars);
    end if;
  else
   oExp := y;
  end if;

end makeTmpEqnForExp;

public function normalizationVec
"
  author: Vitalij Ruge
  normalization of vector
"
  input array<DAE.Exp> vec;
  input String name "var name";
  input Integer offset;
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Variables ivars;
  input BackendDAE.Shared ishared;
  output array<DAE.Exp> nvec;
  output BackendDAE.EquationArray oeqns;
  output BackendDAE.Variables ovars;
  output BackendDAE.Shared oshared;
protected
  DAE.Exp len = Expression.lenVec(vec);
algorithm
  (len,oeqns,ovars,oshared) := makeTmpEqnForExp(len, name, offset, ieqns, ivars,ishared);
  if Expression.isZero(len) then
    fail();
  end if;
  nvec := Array.map1(vec, Expression.makeDiv, len);
end normalizationVec;

public function solveEquation "author: wbraun
  Solves an equation w.r.t. a component reference. All equations are transformed
  to a EQUATION(cref, exp).
  Algorithm, when and if-equation are left as they are."
  input BackendDAE.Equation eqn;
  input DAE.Exp crefExp;
  input Option<DAE.FunctionTree> functions;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue (eqn, crefExp, functions)
    local
      DAE.Exp e1, e2;
      DAE.Exp res;
      DAE.ComponentRef cref, cr;
      list<DAE.ComponentRef> crefLst;
      BackendDAE.Equation eq;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr), _, _) equation
      (res, _, {}, {}) = ExpressionSolve.solve2(e1, e2, crefExp, functions, NONE());
    then (BackendDAE.EQUATION(crefExp, res, source, eqAttr));

    case (BackendDAE.ARRAY_EQUATION(left=e1, right=e2, source=source, attr=eqAttr), _, _) equation
      (res, _, {}, {}) = ExpressionSolve.solve2(e1, e2, crefExp, functions, NONE());
    then (BackendDAE.EQUATION(crefExp, res, source, eqAttr));

    case (BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e2, source=source, attr=eqAttr), _,_) equation
      cr = Expression.expCref(crefExp);
      true = ComponentReference.crefEqual(cref, cr);
    then (BackendDAE.EQUATION(crefExp, e2, source, eqAttr));

    case (BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e2, source=source, attr=eqAttr), _, _) equation
      cr = Expression.expCref(crefExp);
      false = ComponentReference.crefEqual(cref, cr);
      e1 = Expression.crefExp(cref);
      (res, _, {}, {}) = ExpressionSolve.solve2(e1, e2, crefExp, functions, NONE());
    then (BackendDAE.EQUATION(crefExp, res, source, eqAttr));

    case (BackendDAE.RESIDUAL_EQUATION(exp=e2, source=source, attr=eqAttr), _, _) equation
      e1 = Expression.makeConstZero(Expression.typeof(e2));
      (res, _, {}, {}) = ExpressionSolve.solve2(e2, e1, crefExp, functions, NONE());
    then (BackendDAE.EQUATION(crefExp, res, source, eqAttr));

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, attr=eqAttr), _, _) equation
      (res, _, {}, {}) = ExpressionSolve.solve2(e1, e2, crefExp, functions, NONE());
    then (BackendDAE.EQUATION(crefExp, res, source, eqAttr));
/*
    case (eq as BackendDAE.ALGORITHM(alg=_), _)
    then eq;

    case (eq as BackendDAE.WHEN_EQUATION(size=_), _)
    then eq;

    case (eq as BackendDAE.IF_EQUATION(conditions=_), _)
    then eq;
*/
    else equation
      BackendDump.dumpBackendDAEEqnList({eqn}, "function BackendEquation.solveEquation failed w.r.t " + ExpressionDump.printExpStr(crefExp), true);
      Error.addInternalError("./Compiler/BackEnd/BackendEquation.mo: function solveEquation failed", sourceInfo());
    then fail();
  end matchcontinue;
end solveEquation;

protected function generateRESIDUAL_EQUATION "author: Frenkel TUD 2010-05"
  input DAE.Exp inExp;
  input DAE.ElementSource inSource;
  input BackendDAE.EquationAttributes inEqAttr;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := BackendDAE.RESIDUAL_EQUATION(inExp, inSource, inEqAttr);
end generateRESIDUAL_EQUATION;

public function getEqnsFromEqSystem "
  Extracts the orderedEqs attribute from an equation system."
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EquationArray outOrderedEqs;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=outOrderedEqs) := inEqSystem;
end getEqnsFromEqSystem;

public function getInitialEqnsFromShared "
  Extracts the initial equations from a shared object."
  input BackendDAE.Shared inShared;
  output BackendDAE.EquationArray outInitialEqs;
algorithm
  BackendDAE.SHARED(initialEqs=outInitialEqs) := inShared;
end getInitialEqnsFromShared;

public function aliasEquation "author Frenkel TUD 2011-04
  Returns the two sides of an alias equation as expressions and cref.
  If the equation is not simple, this function will fail."
  input BackendDAE.Equation inEqn;
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> outTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
algorithm
  outTpls := match (inEqn)
    local
      DAE.Exp e, e1, e2;
      DAE.ComponentRef cr;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2))
    then aliasEquation1(e1, e2, {});

    case (BackendDAE.ARRAY_EQUATION(left=e1, right=e2))
    then aliasEquation1(e1, e2, {});

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2)) equation
      e = Expression.crefExp(cr);
    then aliasEquation1(e, e2, {});

    case (BackendDAE.RESIDUAL_EQUATION(exp=e1))
    then aliasExpression(e1, {});

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2))
    then aliasEquation1(e1, e2, {});
  end match;
end aliasEquation;

protected function aliasEquation1 "author Frenkel TUD 2011-04
  helper for aliasEquation"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> inTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> outTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
algorithm
  outTpls := match (lhs, rhs, inTpls)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp e1, e2;
      DAE.Type ty;
      list<DAE.Exp> elst1, elst2;
      list<list<DAE.Exp>> elstlst1, elstlst2;
      list<DAE.Var> varLst1, varLst2;
      Absyn.Path patha, patha1, pathb, pathb1;

    // a = b;
    case (DAE.CREF(componentRef = cr1), DAE.CREF(componentRef = cr2), _)
    then (cr1, cr2, lhs, rhs, false)::inTpls;

    // a = -b;
    case (DAE.CREF(componentRef = cr1), DAE.UNARY(DAE.UMINUS(ty), DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, DAE.UNARY(DAE.UMINUS(ty), lhs), rhs, true)::inTpls;

    case (DAE.CREF(componentRef = cr1), DAE.UNARY(DAE.UMINUS_ARR(ty), DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, DAE.UNARY(DAE.UMINUS_ARR(ty), lhs), rhs, true)::inTpls;

    // -a = b;
    case (DAE.UNARY(DAE.UMINUS(ty), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _)
    then (cr1, cr2, lhs, DAE.UNARY(DAE.UMINUS(ty), rhs), true)::inTpls;

    case (DAE.UNARY(DAE.UMINUS_ARR(ty), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _)
    then (cr1, cr2, lhs, DAE.UNARY(DAE.UMINUS_ARR(ty), rhs), true)::inTpls;

    // -a = -b;
    case (DAE.UNARY(DAE.UMINUS(_), e1 as DAE.CREF(componentRef = cr1)), DAE.UNARY(DAE.UMINUS(_), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, e2, false)::inTpls;

    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, e2, false)::inTpls;

    // a = not b;
    case (DAE.CREF(componentRef = cr1), DAE.LUNARY(DAE.NOT(ty), DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, DAE.LUNARY(DAE.NOT(ty), lhs), rhs, true)::inTpls;

    // not a = b;
    case (DAE.LUNARY(DAE.NOT(ty), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _)
    then (cr1, cr2, lhs, DAE.LUNARY(DAE.NOT(ty), rhs), true)::inTpls;

    // not a = not b;
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF(componentRef = cr1)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, e2, false)::inTpls;

    // {a1, a2, a3, ..} = {b1, b2, b3, ..};
    case (DAE.ARRAY(array = elst1), DAE.ARRAY(array = elst2), _)
    then List.threadFold(elst1, elst2, aliasEquation1, inTpls);

    case (DAE.MATRIX(matrix = elstlst1), DAE.MATRIX(matrix = elstlst2), _)
    then List.threadFold(elstlst1, elstlst2, aliasEquationLst, inTpls);

    // a = {b1, b2, b3, ..}
    //case (DAE.CREF(componentRef = cr1), DAE.ARRAY(array = elst2, dims=dims), _)
    //then //    aliasArray(cr1, false, elst2, dims, inTpls);

    // -a = {b1, b2, b3, ..}
    //case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ARRAY(array = elst2, dims=dims), _)
    //then //    aliasArray(cr1, true, elst2, dims, inTpls);

    // a = -{b1, b2, b3, ..}
    //case (DAE.CREF(componentRef = cr1), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.ARRAY(array = elst2, ty=ty)), _)

    // -a = -{b1, b2, b3, ..}
    //case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.ARRAY(array = elst2, ty=ty)), _)

    // {a1, a2, a3, ..} = b
    //case (DAE.ARRAY(array = elst1), DAE.CREF(componentRef = cr2), _)

    // -{a1, a2, a3, ..} = b
    //case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.ARRAY(array = elst1, ty=ty)), DAE.CREF(componentRef = cr2), _)

    // {a1, a2, a3, ..} = -b
    //case (DAE.ARRAY(array = elst1), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF(componentRef = cr2)), _)

    // -{a1, a2, a3, ..} = -b
    //case (DAE.UNARY(DAE.UMINUS_ARR(_)DAE.ARRAY(array = elst1, ty=ty)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF(componentRef = cr2)), _)

    // not a = {b1, b2, b3, ..}
    //case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ARRAY(array = elst2, ty=ty), _)

    // a = not {b1, b2, b3, ..}
    //case (DAE.CREF(componentRef = cr1), DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(array = elst2, ty=ty)), _)

    // not a = not {b1, b2, b3, ..}
    //case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF(componentRef = cr1)), DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(array = elst2, ty=ty)), _)

    // {a1, a2, a3, ..} = not b
    //case (DAE.ARRAY(array = elst1, ty=ty), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF(componentRef = cr2)), _)

    // not {a1, a2, a3, ..} = b
    //case (DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(array = elst1, ty=ty)), DAE.CREF(componentRef = cr2), _)

    // not {a1, a2, a3, ..} = not b
    //case (DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(array = elst1, ty=ty)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF(componentRef = cr2)), _)

    // a = Record(b1, b2, b3, ..)
    case (DAE.CREF(componentRef = cr1), DAE.CALL(path=pathb, expLst=elst2, attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=varLst2, complexClassType=ClassInf.RECORD(pathb1)))), _) equation
      true = Absyn.pathEqual(pathb, pathb1);
    then aliasRecord(cr1, varLst2, elst2, inTpls);

    // Record(a1, a2, a3, ..) = b
    case (DAE.CALL(path=patha, expLst=elst1, attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=varLst1, complexClassType=ClassInf.RECORD(patha1)))), DAE.CREF(componentRef = cr2), _) equation
      true = Absyn.pathEqual(patha, patha1);
    then aliasRecord(cr2, varLst1, elst1, inTpls);

    // Record(a1, a2, a3, ..) = Record(b1, b2, b3, ..)
    case (DAE.CALL(path=patha, expLst=elst1, attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(patha1)))),
      DAE.CALL(path=pathb, expLst=elst2, attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(pathb1)))), _) equation
      true = Absyn.pathEqual(patha, patha1);
      true = Absyn.pathEqual(pathb, pathb1);
    then List.threadFold(elst1, elst2, aliasEquation1, inTpls);

    // matchcontinue part
    else aliasEquation2(lhs, rhs, inTpls);
  end match;
end aliasEquation1;

protected function aliasEquationLst "author Frenkel TUD 2011-04
  helper for aliasEquation"
  input list<DAE.Exp> elst1;
  input list<DAE.Exp> elst2;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> inTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> outTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
algorithm
  outTpls := List.threadFold(elst1, elst2, aliasEquation1, inTpls);
end aliasEquationLst;

protected function aliasEquation2 "author Frenkel TUD 2011-04
  helper for aliasEquation"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> inTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> outTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
algorithm
  outTpls := matchcontinue (lhs, rhs, inTpls)
    local
      list<DAE.Exp> elst1, elst2;

    // {a1+b1, a2+b2, a3+b3, ..} = 0;
    case (DAE.ARRAY(array = elst1), _, _) equation
      true = Expression.isZero(rhs);
    then List.fold(elst1, aliasExpression, inTpls);

    // 0 = {a1+b1, a2+b2, a3+b3, ..};
    case (_, DAE.ARRAY(array = elst2), _) equation
      true = Expression.isZero(lhs);
    then List.fold(elst2, aliasExpression, inTpls);

    // lhs = 0
    case (_, _, _) equation
      true = Expression.isZero(rhs);
    then aliasExpression(lhs, inTpls);

    // 0 = rhs
    case (_, _, _) equation
      true = Expression.isZero(lhs);
    then aliasExpression(rhs, inTpls);
  end matchcontinue;
end aliasEquation2;

protected function aliasRecord "author Frenkel TUD 2011-04
  helper for aliasEquation"
  input DAE.ComponentRef cr;
  input list<DAE.Var> varLst;
  input list<DAE.Exp> explst;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> inTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> outTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
algorithm
  outTpls := match (cr, varLst, explst, inTpls)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp e1, e2;
      DAE.Type ty, ty1;
      list<DAE.Exp> elst;
      list<DAE.Var> vlst;
      DAE.Ident ident;

    case (_, {}, {}, _)
    then inTpls;

    // a = b
    case (_, DAE.TYPES_VAR(name=ident, ty=ty)::vlst, (e2 as DAE.CREF(componentRef = cr2))::elst, _) equation
      cr1 = ComponentReference.crefPrependIdent(cr, ident, {}, ty);
      e1 = DAE.CREF(cr1, ty);
    then aliasRecord(cr, vlst, elst, (cr1, cr2, e1, e2, false)::inTpls);

    // a = -b
    case (_, DAE.TYPES_VAR(name=ident, ty=ty)::vlst, (e2 as DAE.UNARY(DAE.UMINUS(ty1), DAE.CREF(componentRef = cr2)))::elst, _) equation
      cr1 = ComponentReference.crefPrependIdent(cr, ident, {}, ty);
      e1 = DAE.UNARY(DAE.UMINUS(ty1), DAE.CREF(cr1, ty));
    then aliasRecord(cr, vlst, elst, (cr1, cr2, e1, e2, true)::inTpls);

    case (_, DAE.TYPES_VAR(name=ident, ty=ty)::vlst, (e2 as DAE.UNARY(DAE.UMINUS_ARR(ty1), DAE.CREF(componentRef = cr2)))::elst, _) equation
      cr1 = ComponentReference.crefPrependIdent(cr, ident, {}, ty);
      e1 = DAE.UNARY(DAE.UMINUS_ARR(ty1), DAE.CREF(cr1, ty));
    then aliasRecord(cr, vlst, elst, (cr1, cr2, e1, e2, true)::inTpls);

    // a = not b
    case (_, DAE.TYPES_VAR(name=ident, ty=ty)::vlst, (e2 as DAE.LUNARY(DAE.NOT(ty1), DAE.CREF(componentRef = cr2)))::elst, _) equation
      cr1 = ComponentReference.crefPrependIdent(cr, ident, {}, ty);
      e1 = DAE.LUNARY(DAE.NOT(ty1), DAE.CREF(cr1, ty));
    then aliasRecord(cr, vlst, elst, (cr1, cr2, e1, e2, true)::inTpls);

    // a = {b1, b2, b3}
  end match;
end aliasRecord;

protected function aliasExpression "author Frenkel TUD 2011-11
  Returns the two sides of an alias expression as expressions and cref.
  If the expression is not simple, this function will fail."
  input DAE.Exp exp;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> inTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef, DAE.Exp, DAE.Exp, Boolean>> outTpls "(cr1, cr2, cr1=e2, cr2=e1, true if negated alias)";
algorithm
  outTpls := match (exp, inTpls)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp e1, e2;
      DAE.Type ty;

    // a + b
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.ADD(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, DAE.UNARY(DAE.UMINUS(ty), e1), DAE.UNARY(DAE.UMINUS(ty), e2), true)::inTpls;

    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.ADD_ARR(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, DAE.UNARY(DAE.UMINUS_ARR(ty), e1), DAE.UNARY(DAE.UMINUS_ARR(ty), e2), true)::inTpls;

    // a - b
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.SUB(), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, e2, false)::inTpls;

    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.SUB_ARR(), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, e2, false)::inTpls;

    // -a + b
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ADD(), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, e2, false)::inTpls;

    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ADD_ARR(), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, e2, false)::inTpls;

    // -a - b = 0
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = cr1)), DAE.SUB(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, DAE.UNARY(DAE.UMINUS(ty), e2), true)::inTpls;

    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = cr1)), DAE.SUB_ARR(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _)
    then (cr1, cr2, e1, DAE.UNARY(DAE.UMINUS_ARR(ty), e2), true)::inTpls;
  end match;
end aliasExpression;

public function derivativeEquation "author Frenkel TUD 2011-04
  Returns the two sides of an derivative equation as expressions and cref.
  If the equation is not a derivative equation, this function will fail."
  input BackendDAE.Equation eqn;
  output DAE.ComponentRef cr;
  output DAE.ComponentRef dcr "the derivative of cr";
  output DAE.Exp e;
  output DAE.Exp de "der(cr)";
  output Boolean negate;
algorithm
  (cr, dcr, e, de, negate) := match (eqn)
    local
      DAE.Exp ne, ne2;

    // a = der(b);
    case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr), scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})))
    then (cr, dcr, e, de, false);

    // der(a) = b;
    case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}), scalar=e as DAE.CREF(componentRef = dcr)))
    then (cr, dcr, e, de, false);

    // a = -der(b);
    case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr), scalar=de as  DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})))) equation
      ne = Expression.negate(e);
    then (cr, dcr, ne, de, true);

    case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr), scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})))) equation
      ne = Expression.negate(e);
    then (cr, dcr, ne, de, true);

    // -der(a) = b;
    case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})), scalar=e as DAE.CREF(componentRef = dcr))) equation
      ne = Expression.negate(e);
    then (cr, dcr, ne, de, true);

    case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})), scalar=e as DAE.CREF(componentRef = dcr))) equation
      ne = Expression.negate(e);
    then (cr, dcr, ne, de, true);

    // -a = der(b);
    case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = dcr)), scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}))) equation
      ne = Expression.negate(de);
    then (cr, dcr, e, ne, true);

    case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = dcr)), scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}))) equation
      ne = Expression.negate(de);
    then (cr, dcr, e, ne, true);

    // der(a) = -b;
    case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}), scalar=e as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = dcr)))) equation
      ne = Expression.negate(de);
    then (cr, dcr, e, ne, true);

    case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}), scalar=e as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = dcr)))) equation
      ne = Expression.negate(de);
    then (cr, dcr, e, ne, true);

    // -a = -der(b);
    case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = dcr)), scalar=de as  DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})))) equation
      ne = Expression.negate(e);
      ne2 = Expression.negate(de);
    then (cr, dcr, ne, ne2, false);

    case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = dcr)), scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})))) equation
      ne = Expression.negate(e);
      ne2 = Expression.negate(de);
    then (cr, dcr, ne, ne2, false);

    // -der(a) = -b;
    case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})), scalar=e as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = dcr)))) equation
      ne = Expression.negate(e);
      ne2 = Expression.negate(de);
    then (cr, dcr, ne, ne2, false);

    case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)})), scalar=e as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = dcr)))) equation
      ne = Expression.negate(e);
      ne2 = Expression.negate(de);
    then (cr, dcr, ne, ne2, false);
  end match;
end derivativeEquation;

public function addOperation "
  Adds symbolic transformation information to equation's source."
  input BackendDAE.Equation inEqn;
  input DAE.SymbolicOperation inSymOp;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := match (inEqn, inSymOp)
    local
      Integer size;
      DAE.Exp e1, e2;
      list<DAE.Exp> conditions;
      DAE.ElementSource source;
      BackendDAE.WhenEquation whenEquation;
      DAE.ComponentRef cr1;
      list<BackendDAE.Equation> eqnsfalse;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<Integer> ds;
      DAE.Algorithm alg;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.EQUATION(e1, e2, source, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.EQUATION(e1, e2, source, eqAttr);

    case (BackendDAE.ARRAY_EQUATION(ds, e1, e2, source, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.ARRAY_EQUATION(ds, e1, e2, source, eqAttr);

    case (BackendDAE.SOLVED_EQUATION(cr1, e1, source, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.SOLVED_EQUATION(cr1, e1, source, eqAttr);

    case (BackendDAE.RESIDUAL_EQUATION(e1, source, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.RESIDUAL_EQUATION(e1, source, eqAttr);

    case (BackendDAE.ALGORITHM(size, alg, source, crefExpand, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.ALGORITHM(size, alg, source, crefExpand, eqAttr);

    case (BackendDAE.WHEN_EQUATION(size, whenEquation, source, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.WHEN_EQUATION(size, whenEquation, source, eqAttr);

    case (BackendDAE.COMPLEX_EQUATION(size, e1, e2, source, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.COMPLEX_EQUATION(size, e1, e2, source, eqAttr);

    case (BackendDAE.IF_EQUATION(conditions, eqnstrue, eqnsfalse, source, eqAttr), _) equation
      source = DAEUtil.addSymbolicTransformation(source, inSymOp);
    then BackendDAE.IF_EQUATION(conditions, eqnstrue, eqnsfalse, source, eqAttr);

    else equation
      Error.addInternalError("BackendEquation.addOperation failed", sourceInfo());
    then fail();
  end match;
end addOperation;

public function isWhenEquation
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match (inEqn)
    case BackendDAE.WHEN_EQUATION() then true;
    else false;
  end match;
end isWhenEquation;

public function isArrayEquation
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match (inEqn)
    case BackendDAE.ARRAY_EQUATION() then true;
    else false;
  end match;
end isArrayEquation;

public function isAlgorithm
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match (inEqn)
    case BackendDAE.ALGORITHM() then true;
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
  input BackendDAE.Equation inEqn;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := match (inEqn)
    local
      DAE.Exp e1, e2;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      Integer size;
      list<Integer> dimSize;
      list<DAE.Exp> conditions;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqnsfalse;
      BackendDAE.EquationAttributes eqAttr;

    case BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr) equation
      eqAttr = markDifferentiated2(eqAttr);
    then BackendDAE.EQUATION(e1, e2, source, eqAttr);

    case BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left=e1, right=e2, source=source, attr=eqAttr) equation
      eqAttr = markDifferentiated2(eqAttr);
    then BackendDAE.ARRAY_EQUATION(dimSize, e1, e2, source, eqAttr);

    case BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2, source=source, attr=eqAttr) equation
      eqAttr = markDifferentiated2(eqAttr);
    then BackendDAE.SOLVED_EQUATION(cr, e2, source, eqAttr);

    case BackendDAE.RESIDUAL_EQUATION(exp=e2, source=source, attr=eqAttr) equation
      eqAttr = markDifferentiated2(eqAttr);
    then BackendDAE.RESIDUAL_EQUATION(e2, source, eqAttr);

    case BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, attr=eqAttr) equation
      eqAttr = markDifferentiated2(eqAttr);
    then BackendDAE.COMPLEX_EQUATION(size, e1, e2, source, eqAttr);

    case BackendDAE.ALGORITHM()
    then inEqn;

    case BackendDAE.WHEN_EQUATION()
    then inEqn;

    case BackendDAE.IF_EQUATION(conditions=conditions, eqnstrue=eqnstrue, eqnsfalse=eqnsfalse, source=source, attr=eqAttr) equation
      eqAttr = markDifferentiated2(eqAttr);
      eqnstrue = List.mapList(eqnstrue, markDifferentiated);
      eqnsfalse = List.map(eqnsfalse, markDifferentiated);
    then BackendDAE.IF_EQUATION(conditions, eqnstrue, eqnsfalse, source, eqAttr);
  end match;
end markDifferentiated;

protected function markDifferentiated2
  input BackendDAE.EquationAttributes inAttr;
  output BackendDAE.EquationAttributes outAttr;
protected
  BackendDAE.EquationKind kind;
  Integer subPartitionIndex;
  BackendDAE.LoopInfo loopInfo;
algorithm
  BackendDAE.EQUATION_ATTRIBUTES(kind=kind, subPartitionIndex=subPartitionIndex, loopInfo=loopInfo) := inAttr;
  outAttr := BackendDAE.EQUATION_ATTRIBUTES(true, kind, subPartitionIndex, loopInfo);
end markDifferentiated2;

public function isDifferentiated
  input BackendDAE.Equation inEqn;
  output Boolean diffed;
algorithm
  diffed := match (inEqn)
    local
      Boolean b;
      BackendDAE.Equation eqn;
    case BackendDAE.EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=b)) then b;
    case BackendDAE.ARRAY_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=b)) then b;
    case BackendDAE.SOLVED_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=b)) then b;
    case BackendDAE.RESIDUAL_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=b)) then b;
    case BackendDAE.COMPLEX_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=b)) then b;
    case BackendDAE.ALGORITHM(attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=b)) then b;
    case BackendDAE.WHEN_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=b))then b;
    case BackendDAE.IF_EQUATION(eqnsfalse=eqn::_) then isDifferentiated(eqn);
  end match;
end isDifferentiated;

public function replaceDerOpInEquationList
  "Replaces all der(cref) with $DER.cref in a list of equations."
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  (outEqns, ) := traverseExpsOfEquationList(inEqns, Expression.replaceDerOpInExpCond, NONE());
end replaceDerOpInEquationList;

public function getEquationRHS"gets the right hand side expression of an equation.
author:Waurich TUD 2014-10"
  input BackendDAE.Equation eq;
  output DAE.Exp rhs;
algorithm
  rhs := match(eq)
    local
      DAE.Exp exp1;
    case(BackendDAE.EQUATION(scalar = exp1))
      then exp1;
    case(BackendDAE.ARRAY_EQUATION(right = exp1))
      then exp1;
    case(BackendDAE.SOLVED_EQUATION(exp = exp1))
      then exp1;
    case(BackendDAE.COMPLEX_EQUATION(right = exp1))
      then exp1;
    case(BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(condition=DAE.BCONST(bool=true),right=exp1)))
      then exp1;
    else
      //equation print("BackendEquation.getEquationRHS failed!\n!");
      then fail();
  end match;
end getEquationRHS;

public function getEquationLHS"gets the left hand side expression of an equation.
author:Waurich TUD 2014-10"
  input BackendDAE.Equation eq;
  output DAE.Exp lhs;
algorithm
  lhs := match(eq)
    local
      DAE.Exp exp1;
      DAE.ComponentRef cref;
    case(BackendDAE.EQUATION(exp = exp1))
      then exp1;
    case(BackendDAE.ARRAY_EQUATION(left = exp1))
      then exp1;
    case(BackendDAE.SOLVED_EQUATION(componentRef = cref))
      then Expression.crefExp(cref);
    case(BackendDAE.COMPLEX_EQUATION(left = exp1))
      then exp1;
    case(BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(condition=DAE.BCONST(bool=true),left=cref)))
      then Expression.crefExp(cref);
    else
      //equation print("BackendEquation.getEquationLHS failed!\n");
      then fail();
  end match;
end getEquationLHS;

annotation(__OpenModelica_Interface="backend");
end BackendEquation;
