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

package BackendEquation
" file:	       BackendEquation.mo
  package:     BackendEquation
  description: BackendEquation contains functions that do something with
               BackendDAEEquation datatype.


"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import Algorithm;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendVarTransform;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Util;


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
    case (BackendDAE.DAE(eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst)),when_index)
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
        crs2 = Expression.extractCrefsFromExp(e1);
        crs3 = Expression.extractCrefsFromExp(e2);
        crs = Util.listFlatten({crs1,crs2,crs3});
      then
        crs;

    case ((BackendDAE.RESIDUAL_EQUATION(exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Expression.extractCrefsFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        crs;

    case ((BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Expression.extractCrefsFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        (cr :: crs);

    case ((BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: es))
      local list<list<DAE.ComponentRef>> crs2;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl, Expression.extractCrefsFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs = listAppend(crs1, crs2_1);
      then
        crs;

    case ((BackendDAE.ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es))
      local list<list<DAE.ComponentRef>> crs2,crs3;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl1, Expression.extractCrefsFromExp);
        crs3 = Util.listMap(expl2, Expression.extractCrefsFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs3_1 = Util.listFlatten(crs3);
        crs = Util.listFlatten({crs1,crs2_1,crs3_1});
      then
        crs;

    case ((BackendDAE.WHEN_EQUATION(whenEquation =
           BackendDAE.WHEN_EQ(index = indx,left = cr,right = e,elsewhenPart=SOME(weq)),source = source) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Expression.extractCrefsFromExp(e);
        crs3 = equationsCrefs({BackendDAE.WHEN_EQUATION(weq,source)});
        crs = listAppend(crs1, listAppend(crs2, crs3));
      then
        (cr :: crs);
  end matchcontinue;
end equationsCrefs;

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
        res = boolAnd(Expression.expEqual(e11,e21),Expression.expEqual(e12,e22));
      then res;

    case(BackendDAE.ARRAY_EQUATION(index = i1),
         BackendDAE.ARRAY_EQUATION(index = i2))
      equation
        res = intEq(i1,i2);
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
         //ExpressionDump.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        tp = Expression.typeof(e2);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));
        e = ExpressionSimplify.simplify(DAE.BINARY(e1,op,e2));
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = exp,source = source))
      equation
         //ExpressionDump.dumpExpWithTitle("equationToResidualForm 2\n",exp);
        tp = Expression.typeof(exp);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));        
        e = ExpressionSimplify.simplify(DAE.BINARY(DAE.CREF(cr,tp),op,exp));
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
        Debug.fprintln("failtrace", "- BackendDAE.equationToResidualForm failed");
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

protected function equationSource "Retrieve the source from a BackendDAE.BackendDAE equation"
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

end BackendEquation;
