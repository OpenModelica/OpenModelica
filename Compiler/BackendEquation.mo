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

  RCS: $Id$  
"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionSimplify;
protected import Util;

public function getWhenEquationExpr
"function: getWhenEquationExpr
  Get the left and right hand parts from an equation appearing in a when clause"
  input BackendDAE.WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  (outComponentRef,outExp) := matchcontinue (inWhenEquation)
    local DAE.ComponentRef cr; DAE.Exp e;
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
        print("- BackendEquation.getZeroCrossingIndicesFromWhenClause2 failed\n");
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
  (_,outExpComponentRefLst) := traverseBackendDAEExpsEqnList(inEquationLst,extractCrefsFromExp,{});
end equationsCrefs;

protected function extractCrefsFromExp "function: extractCrefsFromExp
  author: Frenkel TUD 2010-11
  helper for equationsCrefs"
 input tuple<DAE.Exp, list<DAE.ComponentRef>> inTpl;
 output tuple<DAE.Exp, list<DAE.ComponentRef>> outTpl;  
algorithm 
  outTpl := matchcontinue(inTpl)
    local 
      list<DAE.ComponentRef> crefs,crefs1; 
      DAE.Exp e,e1; 
    case((e,crefs))
      equation
        ((e1,crefs1)) = Expression.traverseExp(e, Expression.traversingComponentRefFinder, crefs);
      then
        ((e1,crefs1));
  end matchcontinue;
end extractCrefsFromExp;

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
  (outEquations,outTypeA) := matchcontinue(inEquations,func,inTypeA)
  local 
       BackendDAE.Equation e,e1;
       list<BackendDAE.Equation> res,eqns;
       Type_a ext_arg_1,ext_arg_2;
    case({},func,inTypeA) then ({},inTypeA);
    case(e::res,func,inTypeA)
     equation
      (e1,ext_arg_1) = traverseBackendDAEExpsEqn(e,func,inTypeA);
      (eqns,ext_arg_2)  = traverseBackendDAEExpsEqnList(res,func,ext_arg_1);
    then 
      (e1::eqns,ext_arg_2);
    end matchcontinue;
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
  (outEquation,outTypeA):=  matchcontinue (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,e,e_1,e_2;
      list<DAE.Exp> expl,expl1,exps,exps1;
      DAE.ExpType tp;
      DAE.ComponentRef cr,cr1;
      BackendDAE.WhenEquation elsePart,elsePart1;
      DAE.ElementSource source;
      Integer index;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.EQUATION(e_1,e_2,source),ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(index=index,crefOrDerCref = expl,source=source),func,inTypeA)
      equation
        (exps,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
      then
        (BackendDAE.ARRAY_EQUATION(index,exps,source),ext_arg_1);
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
    case (BackendDAE.ALGORITHM(index = index,in_ = expl,out = exps,source=source),func,inTypeA)
      equation
        (expl1,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
        (exps1,ext_arg_2) = traverseBackendDAEExpList(exps,func,ext_arg_1);
      then
        (BackendDAE.ALGORITHM(index,expl1,exps1,source),ext_arg_2);
    case (BackendDAE.COMPLEX_EQUATION(index = index, lhs = e1, rhs = e2,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA)); 
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1)); 
      then
        (BackendDAE.COMPLEX_EQUATION(index,e_1,e_2,source),ext_arg_2);
  end matchcontinue;
end traverseBackendDAEExpsEqn;

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
  (outExpl,outTypeA) := matchcontinue(inExpl,rel,ext_arg)
  local 
      DAE.Exp e,e1; 
      list<DAE.Exp> expl1,res;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    case({},_,ext_arg_1) then ({},ext_arg_1);
    case(e::res,rel,ext_arg_1) equation
      ((e1,ext_arg_2)) = rel((e, ext_arg_1));
      (expl1,ext_arg_3) = traverseBackendDAEExpList(res,rel,ext_arg_2);
    then (e1::expl1,ext_arg_3); 
  end matchcontinue;
end traverseBackendDAEExpList;

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
        print("- BackendEquation.equationAdd failed\n");
      then
        fail();
  end matchcontinue;
end equationAdd;

public function equationSetnth "function: equationSetnth
  author: PA
  Sets the nth array element of an EquationArray."
  input BackendDAE.EquationArray inEquationArray;
  input Integer inInteger;
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue (inEquationArray,inInteger,inEquation)
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
      BackendDAE.Equation backendEq;
    
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
    
    case (backendEq as BackendDAE.RESIDUAL_EQUATION(exp = _,source = source)) then backendEq;
    
    case (backendEq as BackendDAE.ALGORITHM(index = _)) then backendEq;
    
    case (backendEq as BackendDAE.ARRAY_EQUATION(index = _)) then backendEq;
    
    case (backendEq as BackendDAE.WHEN_EQUATION(whenEquation = _)) then backendEq;
    
    case (backendEq)
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
