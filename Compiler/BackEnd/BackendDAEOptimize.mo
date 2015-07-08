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

encapsulated package BackendDAEOptimize
" file:        BackendDAEOptimize.mo
  package:     BackendDAEOptimize
  description: BackendDAEOptimize contains functions that do some kind of
               optimization on the BackendDAE datatype:
               - removing simpleEquations
               - Tearing/Relaxation
               - Linearization
               - Inline Integration
               - and so on ...

  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;
public import HashTable2;

protected import Algorithm;
protected import Array;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import BaseHashTable;
protected import CheckModel;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import DAEDump;
protected import Debug;
protected import Differentiate;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Error;
protected import Flags;
protected import HashTableExpToIndex;
protected import List;
protected import RewriteRules;
protected import SCode;
protected import SynchronousFeatures;
protected import Types;
protected import Util;
protected import Values;
protected import ValuesUtil;

// =============================================================================
// simplify time independent function calls
//
// public functions:
//   - simplifyTimeIndepFuncCalls
// =============================================================================

public function simplifyTimeIndepFuncCalls "author: Frenkel TUD 2012-06
  pre(param) -> param
  der(param) -> 0.0
  change(param) -> false
  edge(param) -> false"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, simplifyTimeIndepFuncCalls0, false);
  outDAE := simplifyTimeIndepFuncCallsShared(outDAE);
end simplifyTimeIndepFuncCalls;

protected function simplifyTimeIndepFuncCalls0 "author: Frenkel TUD 2012-06"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared;
  output Boolean outChanged;
algorithm
  (osyst, outShared, outChanged) := matchcontinue (isyst, inShared)
    local
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;

    case (syst, shared)
      algorithm
        ((_, (_, _, true))) := BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate (
            syst.orderedEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls,
            (shared.knownVars, shared.aliasVars, false))
        );
        ((_, (_, _, true))) := BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate (
            syst.removedEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls,
            (shared.knownVars, shared.aliasVars, false))
        );
    then (isyst, inShared, true);

    else (isyst, inShared, inChanged);
  end matchcontinue;
end simplifyTimeIndepFuncCalls0;

protected function traverserExpsimplifyTimeIndepFuncCalls
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, Boolean> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, Boolean> outTpl;
algorithm
  (outExp, outTpl) := matchcontinue (inExp, inTpl)
    local
      BackendDAE.Variables knvars, aliasvars;
      DAE.Type tp;
      DAE.Exp e, zero;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      DAE.CallAttributes attr;
      Boolean negate;

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr, ty=tp)}), (knvars, aliasvars, _)) equation
      (var::{}, _) = BackendVariable.getVar(cr, knvars);
      false = BackendVariable.isVarOnTopLevelAndInput(var);
      (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
    then (zero, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={e as DAE.CREF(componentRef=cr)}), (knvars, aliasvars, _)) equation
      (_::{}, _) = BackendVariable.getVar(cr, knvars);
    then(e, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}), (knvars, aliasvars, _))
    then (e, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={e as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")))}), (knvars, aliasvars, _))
    then (e, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={DAE.CREF(componentRef=cr, ty=tp)}, attr=attr), (knvars, aliasvars, _)) equation
      (var::{}, _) = BackendVariable.getVar(cr, aliasvars);
      (cr, negate) = BackendVariable.getAlias(var);
      e = DAE.CREF(cr, tp);
      e = if negate then Expression.negate(e) else e;
      (e, _) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT("pre"), {e}, attr));
      (e, _) = Expression.traverseExpBottomUp(e, traverserExpsimplifyTimeIndepFuncCalls, (knvars, aliasvars, false));
    then (e, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="change"), expLst={DAE.CREF(componentRef=cr, ty=tp)}), (knvars, aliasvars, _)) equation
      (_::_, _) = BackendVariable.getVar(cr, knvars);
      zero = Expression.arrayFill(Expression.arrayDimension(tp), DAE.BCONST(false));
    then (zero, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="change"), expLst={DAE.CREF(componentRef=cr, ty=tp)}), (knvars, aliasvars, _)) equation
      (_::_, _) = BackendVariable.getVar(cr, aliasvars);
      zero = Expression.arrayFill(Expression.arrayDimension(tp), DAE.BCONST(false));
    then (zero, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="change"), expLst={DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}), (knvars, aliasvars, _))
    then (DAE.BCONST(false), (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="change"), expLst={DAE.CREF(componentRef=cr, ty=tp)}, attr=attr), (knvars, aliasvars, _)) equation
      (var::{}, _) = BackendVariable.getVar(cr, aliasvars);
      (cr, negate) = BackendVariable.getAlias(var);
      e = DAE.CREF(cr, tp);
      e = if negate then Expression.negate(e) else e;
      (e, _) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT("change"), {e}, attr));
      (e, _) = Expression.traverseExpBottomUp(e, traverserExpsimplifyTimeIndepFuncCalls, (knvars, aliasvars, false));
    then (e, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="edge"), expLst={DAE.CREF(componentRef=cr, ty=tp)}), (knvars, aliasvars, _)) equation
      (_::{}, _) = BackendVariable.getVar(cr, knvars);
      zero = Expression.arrayFill(Expression.arrayDimension(tp), DAE.BCONST(false));
    then (zero, (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="edge"), expLst={DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}), (knvars, aliasvars, _))
    then (DAE.BCONST(false), (knvars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name="edge"), expLst={DAE.CREF(componentRef=cr, ty=tp)}, attr=attr), (knvars, aliasvars, _)) equation
      (var::{}, _) = BackendVariable.getVar(cr, aliasvars);
      (cr, negate) = BackendVariable.getAlias(var);
      e = DAE.CREF(cr, tp);
      e = if negate then Expression.negate(e) else e;
      (e, _) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT("edge"), {e}, attr));
      (e, _) = Expression.traverseExpBottomUp(e, traverserExpsimplifyTimeIndepFuncCalls, (knvars, aliasvars, false));
    then (e, (knvars, aliasvars, true));

    else (inExp, inTpl);
  end matchcontinue;
end traverserExpsimplifyTimeIndepFuncCalls;

protected function simplifyTimeIndepFuncCallsShared "pre(param) -> param
  der(param) -> 0.0
  change(param) -> false
  edge(param) -> false
  author: Frenkel TUD 2012-06"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.Shared shared;
algorithm
  shared := inDAE.shared;
  BackendDAEUtil.traverseBackendDAEExpsVarsWithUpdate(shared.knownVars, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.knownVars, shared.aliasVars, false)));
  BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(shared.initialEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.knownVars, shared.aliasVars, false)));
  BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(shared.removedEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.knownVars, shared.aliasVars, false)));
  (shared.eventInfo, _) := traverseEventInfoExps(shared.eventInfo, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.knownVars, shared.aliasVars, false)));
  outDAE := BackendDAE.DAE(inDAE.eqs, shared);
end simplifyTimeIndepFuncCallsShared;

protected function traverseEventInfoExps<T>
  input BackendDAE.EventInfo iEventInfo;
  input FuncExpType func;
  input T inTypeA;
  output BackendDAE.EventInfo oEventInfo;
  output T outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output T outA;
  end FuncExpType;
protected
  list<BackendDAE.TimeEvent> timeEvents;
  list<BackendDAE.WhenClause> whenClauseLst;
  list<BackendDAE.ZeroCrossing> zeroCrossingLst, sampleLst, relationsLst;
  Integer numberMathEvents;
algorithm
  BackendDAE.EVENT_INFO(timeEvents, whenClauseLst, zeroCrossingLst, sampleLst, relationsLst, numberMathEvents) := iEventInfo;
  (whenClauseLst, outTypeA) := traverseWhenClauseExps(whenClauseLst, func, inTypeA, {});
  (zeroCrossingLst, outTypeA) := traverseZeroCrossingExps(zeroCrossingLst, func, outTypeA, {});
  (sampleLst, outTypeA) := traverseZeroCrossingExps(sampleLst, func, outTypeA, {});
  (relationsLst, outTypeA) := traverseZeroCrossingExps(relationsLst, func, outTypeA, {});
  oEventInfo := BackendDAE.EVENT_INFO(timeEvents, whenClauseLst, zeroCrossingLst, sampleLst, relationsLst, numberMathEvents);
end traverseEventInfoExps;

protected function traverseWhenClauseExps<T>
  input list<BackendDAE.WhenClause> iWhenClauses;
  input FuncExpType func;
  input T inTypeA;
  input list<BackendDAE.WhenClause> iAcc;
  output list<BackendDAE.WhenClause> oWhenClauses;
  output T outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output T outA;
  end FuncExpType;
algorithm
  (oWhenClauses, outTypeA) := match (iWhenClauses)
    local
      list<BackendDAE.WhenClause> whenClause;
      DAE.Exp condition;
      list<BackendDAE.WhenOperator> reinitStmtLst;
      Option<Integer> elseClause;
      T arg;

    case {}
    then (listReverse(iAcc), inTypeA);

    case BackendDAE.WHEN_CLAUSE(condition, reinitStmtLst, elseClause)::whenClause equation
      (condition, arg) = Expression.traverseExpBottomUp(condition, func, inTypeA);
      (whenClause, arg) = traverseWhenClauseExps(whenClause, func, arg, BackendDAE.WHEN_CLAUSE(condition, reinitStmtLst, elseClause)::iAcc);
    then (whenClause, arg);
  end match;
end traverseWhenClauseExps;

protected function traverseZeroCrossingExps<T>
  input list<BackendDAE.ZeroCrossing> iZeroCrossing;
  input FuncExpType func;
  input T inTypeA;
  input list<BackendDAE.ZeroCrossing> iAcc;
  output list<BackendDAE.ZeroCrossing> oZeroCrossing;
  output T outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output T outA;
  end FuncExpType;
algorithm
  (oZeroCrossing, outTypeA) := match (iZeroCrossing)
    local
      list<BackendDAE.ZeroCrossing> zeroCrossing;
      DAE.Exp relation_;
      list<Integer> occurEquLst,occurWhenLst;
      T arg;

    case {}
    then (listReverse(iAcc), inTypeA);

    case BackendDAE.ZERO_CROSSING(relation_, occurEquLst, occurWhenLst)::zeroCrossing equation
      (relation_, arg) = Expression.traverseExpBottomUp(relation_, func, inTypeA);
      (zeroCrossing, arg) = traverseZeroCrossingExps(zeroCrossing, func, arg, BackendDAE.ZERO_CROSSING(relation_, occurEquLst, occurWhenLst)::iAcc);
    then (zeroCrossing, arg);
  end match;
end traverseZeroCrossingExps;

// =============================================================================
// =============================================================================

protected function traverseIncidenceMatrix "author: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := traverseIncidenceMatrix1(inM,func,1,arrayLength(inM),inTypeA);
end traverseIncidenceMatrix;

protected function traverseIncidenceMatrix1 "author: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := traverseIncidenceMatrix2(inM,func,pos,len,intGt(pos,len),inTypeA);
  annotation(__OpenModelica_EarlyInline = true);
end traverseIncidenceMatrix1;

protected function traverseIncidenceMatrix2
"  author: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer pos "iterated 1..len";
  input Integer len "length of array";
  input Boolean stop;
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := match (inM,func,pos,len,stop,inTypeA)
    local
      BackendDAE.IncidenceMatrix m,m1,m2;
      Type_a extArg,extArg1,extArg2;
      list<Integer> eqns,eqns1;

    case(_,_,_,_,true,_)
    then (inM,inTypeA);

    case(_,_,_,_,false,_)
      equation
        ((eqns,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
        eqns1 = List.removeOnTrue(pos,intLt,eqns);
        (m1,extArg1) = traverseIncidenceMatrixList(eqns1,m,func,arrayLength(m),pos,extArg);
        (m2,extArg2) = traverseIncidenceMatrix2(m1,func,pos+1,len,intGt(pos+1,len),extArg1);
      then (m2,extArg2);

  end match;
end traverseIncidenceMatrix2;

protected function traverseIncidenceMatrixList
"  author: Frenkel TUD 2011-04"
  replaceable type Type_a subtypeof Any;
  input list<Integer> inLst "elements to traverse";
  input BackendDAE.IncidenceMatrix inM;
  input FuncType func;
  input Integer len "length of array";
  input Integer maxpos "do not go further than this position";
  input Type_a inTypeA;
  output BackendDAE.IncidenceMatrix outM;
  output Type_a outTypeA;
  partial function FuncType
    input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix,Type_a> inTpl;
    output tuple<list<Integer>,BackendDAE.IncidenceMatrix,Type_a> outTpl;
  end FuncType;
algorithm
  (outM,outTypeA) := matchcontinue(inLst,inM,func,len,maxpos,inTypeA)
    local
      BackendDAE.IncidenceMatrix m,m1;
      Type_a extArg,extArg1;
      list<Integer> rest,eqns,eqns1,alleqns;
      Integer pos;

    case({},_,_,_,_,_) then (inM,inTypeA);

    case(pos::rest,_,_,_,_,_) equation
      // do not leave the list
      true = intLt(pos,len+1);
      // do not more than necesary
      true = intLt(pos,maxpos);
      ((eqns,m,extArg)) = func((inM[pos],pos,inM,inTypeA));
      eqns1 = List.removeOnTrue(maxpos,intLt,eqns);
      alleqns = List.unionOnTrueList({rest, eqns1},intEq);
      (m1,extArg1) = traverseIncidenceMatrixList(alleqns,m,func,len,maxpos,extArg);
    then (m1,extArg1);

    case(pos::rest,_,_,_,_,_) equation
      // do not leave the list
      true = intLt(pos,len+1);
      (m,extArg) = traverseIncidenceMatrixList(rest,inM,func,len,maxpos,inTypeA);
    then (m,extArg);

    case (_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- BackendDAEOptimize.traverseIncidenceMatrixList failed\n");
      then
        fail();
  end matchcontinue;
end traverseIncidenceMatrixList;

protected function toplevelInputOrUnfixed
  input BackendDAE.Var inVar;
  output Boolean b;
algorithm
  b := BackendVariable.isVarOnTopLevelAndInput(inVar) or
       BackendVariable.isParam(inVar) and not BackendVariable.varFixed(inVar);
end toplevelInputOrUnfixed;

protected function traversingTimeEqnsFinder "author: Frenkel 2010-12"
  input DAE.Exp inExp;
  input tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<Boolean,BackendDAE.Variables,BackendDAE.Variables,Boolean,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp e;
      Boolean b,b1,b2;
      BackendDAE.Variables vars,knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<BackendDAE.Var> vlst;

    case (e as DAE.CREF(DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_), (_,vars,knvars,b1,b2))
      then (e,false,(true,vars,knvars,b1,b2));
    // inputs not constant and parameter(fixed=false) are constant but evaluated after konstant variables are evaluted
    case (e as DAE.CREF(cr,_), (_,vars,knvars,b1,b2))
      equation
        (vlst,_::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level";
        false = List.mapAllValueBool(vlst,toplevelInputOrUnfixed,false);
      then (e,false,(true,vars,knvars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {_,_,_}), (_,vars,knvars,b1,b2)) then (e,false,(true,vars,knvars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {_}), (_,vars,knvars,b1,b2)) then (e,false,(true,vars,knvars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "change"), expLst = {_}), (_,vars,knvars,b1,b2)) then (e,false,(true,vars,knvars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "edge"), expLst = {_}), (_,vars,knvars,b1,b2)) then (e,false,(true,vars,knvars,b1,b2));
    // case for finding simple equation in jacobians
    // there are all known variables mark as input
    // and they are all time-depending
    case (e as DAE.CREF(cr,_), (_,vars,knvars,true,b2))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, knvars);
        DAE.INPUT() = BackendVariable.getVarDirection(var);
      then (e,false,(true,vars,knvars,true,b2));
    // unkown var
    case (e as DAE.CREF(cr,_), (_,vars,knvars,b1,true))
      equation
        (_::_,_::_)= BackendVariable.getVar(cr, vars);
      then (e,false,(true,vars,knvars,b1,true));
    case (e,(b,vars,knvars,b1,b2)) then (e,not b,(b,vars,knvars,b1,b2));

  end matchcontinue;
end traversingTimeEqnsFinder;

public function countSimpleEquations
"author: Frenkel TUD 2011-05
  This function count the simple equations on the form a=b and a=const and a=f(not time)
  in BackendDAE.BackendDAE. Note this functions does not use variable replacements, because
  of this the number of simple equations is maybe smaller than using variable replacements."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.IncidenceMatrix inM;
  output Integer outSimpleEqns;
algorithm
  outSimpleEqns:=
  match (inDlow,inM)
    local
      BackendDAE.BackendDAE dlow;
      BackendDAE.EquationArray eqns;
      Integer n;
    case (dlow,_)
      equation
        // check equations
       (_,(_,n)) = traverseIncidenceMatrix(inM,countSimpleEquationsFinder,(dlow,0));
      then n;
  end match;
end countSimpleEquations;

protected function countSimpleEquationsFinder
"author: Frenkel TUD 2011-05"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,Integer>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.BackendDAE,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos,l,i,n,n_1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.BackendDAE dae;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;

    case ((elem,pos,m,(dae as BackendDAE.DAE({syst},shared),n)))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intLt(l,3);
        true = intGt(l,0);
        countsimpleEquation(elem,l,pos,syst,shared);
        n_1 = n+1;
      then (({},m,(dae,n_1)));
    case ((_,_,m,(dae,n)))
      then (({},m,(dae,n)));
  end matchcontinue;
end countSimpleEquationsFinder;

protected function countsimpleEquation
"  author: Frenkel TUD 2011-05"
  input BackendDAE.IncidenceMatrixElement elem;
  input Integer length;
  input Integer pos;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
algorithm
  _ := matchcontinue(elem,length,pos,syst,shared)
    local
      DAE.ComponentRef cr;
      Integer i,j;
      DAE.Exp es,cre,e1,e2;
      BackendDAE.Variables vars,knvars;
      BackendDAE.Var var;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      Boolean negate;
      DAE.ElementSource source;
    // a = const
    // wbraun:
    // speacial case for Jacobains, since there are all known variablen
    // time depending input variables
    case ({i},_,_,_,BackendDAE.SHARED(backendDAEType = BackendDAE.JACOBIAN()))
      equation
        vars = BackendVariable.daeVars(syst);
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        eqns = BackendEquation.getEqnsFromEqSystem(syst);
        eqn = BackendEquation.equationNth1(eqns,pos);
        BackendDAE.EQUATION(exp=e1,scalar=e2) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,true,false));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (_,{}) = ExpressionSolve.solve(e1,e2,cre);
      then ();
    // a = const
    case ({i},_,_,_,_)
      equation
        vars = BackendVariable.daeVars(syst);
        var = BackendVariable.getVarAt(vars,intAbs(i));
        // no State
        false = BackendVariable.isStateorStateDerVar(var);
        // try to solve the equation
        eqns = BackendEquation.getEqnsFromEqSystem(syst);
        eqn = BackendEquation.equationNth1(eqns,pos);
        BackendDAE.EQUATION(exp=e1,scalar=e2) = eqn;
        // variable time not there
        knvars = BackendVariable.daeKnVars(shared);
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,knvars,false,false));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (_,{}) = ExpressionSolve.solve(e1,e2,cre);
      then ();
    // a = der(b)
    case ({_,_},_,_,_,_)
      equation
        eqns = BackendEquation.getEqnsFromEqSystem(syst);
        eqn = BackendEquation.equationNth1(eqns,pos);
        (cr,_,_,_,_) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        vars = BackendVariable.daeVars(syst);
        ((_::_),(_::_)) = BackendVariable.getVar(cr,vars);
      then ();
    // a = b
    case ({_,_},_,_,_,_)
      equation
        eqns = BackendEquation.getEqnsFromEqSystem(syst);
        (eqn as BackendDAE.EQUATION()) = BackendEquation.equationNth1(eqns,pos);
        _ = BackendEquation.aliasEquation(eqn);
      then ();
  end matchcontinue;
end countsimpleEquation;

// =============================================================================
// remove parameters stuff
//
// =============================================================================
public function removeParameters
"author wbraun"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match inDAE
    local
      BackendDAE.Variables knvars;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(systs, shared as BackendDAE.SHARED(knownVars=knvars)))
      algorithm
        repl := BackendVarTransform.emptyReplacements();
        ((repl, _)) := BackendVariable.traverseBackendDAEVars(knvars, removeParametersFinder, (repl, knvars));
        (knvars, repl) := replaceFinalVars(1, knvars, repl);
        (knvars, repl) := replaceFinalVars(1, knvars, repl);
        if Flags.isSet(Flags.DUMP_PARAM_REPL) then
          BackendVarTransform.dumpReplacements(repl);
        end if;
        systs := List.map1(systs,removeParameterswork, repl);
        shared.knownVars := knvars;
      then
        BackendDAE.DAE(systs, shared);
  end match;
end removeParameters;

protected function removeParameterswork
"author wbraun"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match isyst
    local
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      list<BackendDAE.Equation> lsteqns;
      BackendDAE.Matching matching;
      BackendDAE.EqSystem syst;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      algorithm
        (vars, _) := replaceFinalVars(1, vars, repl); // replacing variable attributes (e.g start) in unknown vars
        (lsteqns, _) := BackendVarTransform.replaceEquations(BackendEquation.equationList(eqns), repl, NONE());
        syst.orderedVars := vars;
        syst.orderedEqs := BackendEquation.listEquation(lsteqns);
        syst.m := NONE(); syst.mT := NONE();
      then
        syst;
  end match;
end removeParameterswork;

protected function removeParametersFinder
  input BackendDAE.Var inVar;
  input tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp,exp1;
      Values.Value bindValue;

    case (v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp)),(repl,vars))
      equation
        (exp1, _) = Expression.traverseExpBottomUp(exp, BackendDAEUtil.replaceCrefsWithValues, (vars, varName));
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp1,NONE());
      then (v,(repl_1,vars));

    case (v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue)),(repl,vars))
      equation
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp,NONE());
      then (v,(repl_1,vars));

    else (inVar,inTpl);
  end matchcontinue;
end removeParametersFinder;

protected function replaceFinalVars
"  author: Frenkel TUD 2011-04"
  input Integer inNumRepl;
  input BackendDAE.Variables inVars;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Variables outVars;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  (outVars,outRepl) := matchcontinue(inNumRepl,inVars,inRepl)
    local
      Integer numrepl;
      BackendDAE.Variables knvars,knvars1,knvars2;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;

    case(numrepl,knvars,repl)
      equation
      true = intEq(0,numrepl);
    then (knvars,repl);

    case(numrepl,knvars,repl)
      equation
      (knvars1, (repl1,numrepl)) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceFinalVarTraverser,(repl,0));
      (knvars2, repl2) = replaceFinalVars(numrepl,knvars1,repl1);
    then (knvars2,repl2);

  end matchcontinue;
end replaceFinalVars;


protected function replaceFinalVarTraverser
  input BackendDAE.Var inVar;
  input tuple<BackendVarTransform.VariableReplacements,Integer> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendVarTransform.VariableReplacements,Integer> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v,v1;
      BackendVarTransform.VariableReplacements repl,repl_1;
      Integer numrepl;
      DAE.Exp e,e1;
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> attr,new_attr;

    case (v as BackendDAE.VAR(varName=cr,bindExp=SOME(e),values=attr),(repl,numrepl))
      equation
        (e1,true) = BackendVarTransform.replaceExp(e, repl, NONE());
        (e1,_) = ExpressionSimplify.simplify(e1);
        v1 = BackendVariable.setBindExp(v, SOME(e1));
        repl_1 = addConstExpReplacement(e1,cr,repl);
        (attr,repl_1) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,repl_1);
        v1 = BackendVariable.setVarAttributes(v1,attr);
      then (v1,(repl_1,numrepl+1));

    case (v as BackendDAE.VAR(values=attr),(repl,numrepl))
      equation
        (new_attr,repl) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,traverseExpVisitorWrapper,repl);
        v1 = BackendVariable.setVarAttributes(v,new_attr);
      then (v1,(repl,numrepl));
  end matchcontinue;
end replaceFinalVarTraverser;

protected function addConstExpReplacement
  input DAE.Exp inExp;
  input DAE.ComponentRef cr;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  outRepl := matchcontinue(inExp,cr,inRepl)
    case (_,_,_)
      equation
        true = Expression.isConst(inExp);
      then
        BackendVarTransform.addReplacement(inRepl, cr, inExp,NONE());
    else
      inRepl;
  end matchcontinue;
end addConstExpReplacement;

protected function traverseExpVisitorWrapper "help function to replaceFinalVarTraverser"
  input DAE.Exp inExp;
  input BackendVarTransform.VariableReplacements inRepl;
  output DAE.Exp exp;
  output BackendVarTransform.VariableReplacements repl;
algorithm
  (exp,repl) := matchcontinue(inExp,inRepl)
    local
      DAE.ComponentRef cr;

    case (exp as DAE.CREF(_,_),repl) equation
      (exp,_) = BackendVarTransform.replaceExp(exp,repl,NONE());
    then (exp,repl);

    else (inExp,inRepl);
  end matchcontinue;
end traverseExpVisitorWrapper;


// =============================================================================
// remove protected parameters stuff
//
// =============================================================================
public function removeProtectedParameters
"author Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match inDAE
    local
      BackendDAE.Variables knvars;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
    case BackendDAE.DAE(systs, shared as BackendDAE.SHARED(knownVars=knvars))
      algorithm
        repl := BackendVarTransform.emptyReplacements();
        repl := BackendVariable.traverseBackendDAEVars(knvars, protectedParametersFinder, repl);
        if Flags.isSet(Flags.DUMP_PP_REPL) then
          BackendVarTransform.dumpReplacements(repl);
        end if;
        systs := List.map1(systs, removeProtectedParameterswork, repl);
        shared.knownVars := knvars;
      then
        (BackendDAE.DAE(systs, shared));
  end match;
end removeProtectedParameters;

protected function removeProtectedParameterswork
"author Frenkel TUD"
  input BackendDAE.EqSystem isyst;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match isyst
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> lsteqns;
      Boolean b;

    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      algorithm
        lsteqns := BackendEquation.equationList(eqns);
        (lsteqns, b) := BackendVarTransform.replaceEquations(BackendEquation.equationList(eqns), repl, NONE());
        if b then
          syst.orderedEqs := BackendEquation.listEquation(lsteqns);
          syst := BackendDAEUtil.clearEqSyst(syst);
        end if;
      then
        syst;
  end match;
end removeProtectedParameterswork;

protected function protectedParametersFinder
  input BackendDAE.Var inVar;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Var outVar;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  (outVar,outRepl) := matchcontinue (inVar,inRepl)
    local
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl,repl_1;
      DAE.ComponentRef varName;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp;
      Values.Value bindValue;
    case (v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),repl)
      equation
        true = DAEUtil.getProtectedAttr(values);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp,NONE());
      then (v,repl_1);
    case (v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindValue=SOME(bindValue),values=values),repl)
      equation
        true = DAEUtil.getProtectedAttr(values);
        true = BackendVariable.varFixed(v);
        exp = ValuesUtil.valueExp(bindValue);
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp,NONE());
      then (v,repl_1);
    else (inVar,inRepl);
  end matchcontinue;
end protectedParametersFinder;


// =============================================================================
// remove equal function calls equations stuff
//
// =============================================================================
public function removeEqualFunctionCalls "author: Frenkel TUD 2011-04
  This function detects equal function calls of the form a=f(b) and c=f(b) in
  BackendDAE.BackendDAE to get speed up."
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  if Flags.getConfigBool(Flags.CSE_CALL) or Flags.getConfigBool(Flags.CSE_EACHCALL) then
    // skip this module if cse module is activated
    odae := dae;
  else
    odae := BackendDAEUtil.mapEqSystem(dae,removeEqualFunctionCallsWork);
  end if;
end removeEqualFunctionCalls;

protected function removeEqualFunctionCallsWork "author: Frenkel TUD 2011-04
  This function detects equal function calls of the form a=f(b) and c=f(b) in
  BackendDAE.BackendDAE to get speed up."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := match isyst
    local
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<Integer> changed;
      Boolean b;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;

    case syst as BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)
      algorithm
        funcs := BackendDAEUtil.getFunctions(ishared);
        (syst, m, mT) := BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.NORMAL(), SOME(funcs));
        // check equations
        (m, (mT,_,_,changed)) := traverseIncidenceMatrix(m, removeEqualFunctionCallFinder, (mT,vars,eqns,{}));
        // update arrayeqns and algorithms, collect info for wrappers
        syst.m := SOME(m); syst.mT := SOME(mT); syst.matching := BackendDAE.NO_MATCHING();
        syst := BackendDAEUtil.updateIncidenceMatrix(syst, BackendDAE.NORMAL(), NONE(), changed);
      then (syst, ishared);
  end match;
end removeEqualFunctionCallsWork;

protected function removeEqualFunctionCallFinder "author: Frenkel TUD 2010-12"
 input tuple<BackendDAE.IncidenceMatrixElement,Integer,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>>> inTpl;
 output tuple<list<Integer>,BackendDAE.IncidenceMatrix, tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.IncidenceMatrixElement elem;
      Integer pos;
      BackendDAE.IncidenceMatrix m,mT;
      list<Integer> changed;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      DAE.Exp exp,e1,e2,ecr;
      list<Integer> expvars,controleqns,expvars1;
      list<list<Integer>> expvarseqns;

    case ((elem,pos,m,(mT,vars,eqns,changed)))
      equation
        // check number of vars in eqns
        _::_ = elem;
        BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendEquation.equationNth1(eqns,pos);
        // BackendDump.debugStrExpStrExpStr(("Test ",e1," = ",e2,"\n"));
        (ecr,exp) = functionCallEqn(e1,e2,vars);
        // TODO: Handle this with alias-equations instead?; at least they don't replace back to the original expression...
        // failure(DAE.CREF(componentRef=_) = exp);
        // failure(DAE.UNARY(operator=DAE.UMINUS(ty=_),exp=DAE.CREF(componentRef=_)) = exp);
        // BackendDump.debugStrExpStrExpStr(("Found ",ecr," = ",exp,"\n"));
        expvars = BackendDAEUtil.incidenceRowExp(exp,vars,{},NONE(),BackendDAE.NORMAL());
        // print("expvars "); BackendDump.debuglst((expvars,intString," ","\n"));
        (expvars1::expvarseqns) = List.map1(expvars,varEqns,(pos,mT));
        // print("expvars1 "); BackendDump.debuglst((expvars1,intString," ","\n"));;
        controleqns = getControlEqns(expvars1,expvarseqns);
        // print("controleqns "); BackendDump.debuglst((controleqns,intString," ","\n"));
        (eqns1,changed) = removeEqualFunctionCall(controleqns,ecr,exp,eqns,changed);
        //print("changed1 "); BackendDump.debuglst((changed1,intString," ","\n"));
        //print("changed2 "); BackendDump.debuglst((changed2,intString," ","\n"));
        // print("Next\n");
      then (({},m,(mT,vars,eqns1,changed)));
    case ((_,_,m,(mT,vars,eqns,changed)))
      then (({},m,(mT,vars,eqns,changed)));
  end matchcontinue;
end removeEqualFunctionCallFinder;

protected function functionCallEqn
"author Frenkel TUD 2011-04"
  input DAE.Exp ie1;
  input DAE.Exp ie2;
  input BackendDAE.Variables inVars;
  output DAE.Exp outECr;
  output DAE.Exp outExp;
algorithm
  (outECr,outExp) := match (ie1,ie2,inVars)
      local
        DAE.ComponentRef cr;
        DAE.Exp e1,e2;
        DAE.Operator op;

      case (DAE.CREF(),DAE.UNARY(operator=DAE.UMINUS(),exp=DAE.CREF()),_)
        then fail();
      case (DAE.CREF(),DAE.CREF(),_)
        then fail();
      case (DAE.UNARY(operator=DAE.UMINUS(),exp=DAE.CREF()),DAE.CREF(),_)
        then fail();
      // a = -f(...);
      case (e1 as DAE.CREF(componentRef = cr),DAE.UNARY(operator=op as DAE.UMINUS(),exp=e2),_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (DAE.UNARY(op,e1),e2);
      // a = f(...);
      case (e1 as DAE.CREF(componentRef = cr),e2,_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (e1,e2);
      // a = -f(...);
      case (DAE.UNARY(operator=op as DAE.UMINUS(),exp=e1),e2 as DAE.CREF(componentRef = cr),_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (DAE.UNARY(op,e2),e1);
      // f(...)=a;
      case (e1,e2 as DAE.CREF(componentRef = cr),_)
        equation
          ((_::_),(_::_)) = BackendVariable.getVar(cr,inVars);
        then (e2,e1);
  end match;
end functionCallEqn;

protected function varEqns
"author Frenkel TUD 2011-04"
  input Integer v;
  input tuple<Integer,BackendDAE.IncidenceMatrixT> inTpl;
  output list<Integer> outVarEqns;
protected
  Integer pos;
  list<Integer> vareqns,vareqns1;
  BackendDAE.IncidenceMatrix mT;
algorithm
  pos := Util.tuple21(inTpl);
  mT := Util.tuple22(inTpl);
  vareqns := mT[intAbs(v)];
  vareqns1 := List.map(vareqns, intAbs);
  outVarEqns := List.removeOnTrue(intAbs(pos),intEq,vareqns1);
end varEqns;

protected function getControlEqns
"author Frenkel TUD 2011-04"
  input list<Integer> inVarsEqn;
  input list<list<Integer>> inVarsEqns;
  output list<Integer> outEqns;
algorithm
  outEqns := match(inVarsEqn,inVarsEqns)
    local
      list<Integer> a,b,c,d;
      list<list<Integer>> rest;
    case (a,{}) then a;
    case (a,b::rest)
      equation
       c = List.intersectionOnTrue(a,b,intEq);
       d = getControlEqns(c,rest);
      then d;
  end match;
end getControlEqns;

protected function removeEqualFunctionCall
"author: Frenkel TUD 2011-04"
  input list<Integer> inEqsLst;
  input DAE.Exp inExp;
  input DAE.Exp inECr;
  input BackendDAE.EquationArray inEqns;
  input list<Integer> ichanged;
  output BackendDAE.EquationArray outEqns;
  output list<Integer> outEqsLst;
algorithm
  (outEqns,outEqsLst):=
  matchcontinue (inEqsLst,inExp,inECr,inEqns,ichanged)
    local
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,i;
      list<Integer> rest,changed;
    case ({},_,_,_,_) then (inEqns,ichanged);
    case (pos::rest,_,_,_,_)
      equation
        eqn = BackendEquation.equationNth1(inEqns,pos);
        //BackendDump.printEquationList({eqn});
        //BackendDump.debugStrExpStrExpStr(("Repalce ",inExp," with ",inECr,"\n"));
        (eqn1,(_,_,i)) = BackendDAETransform.traverseBackendDAEExpsEqnWithSymbolicOperation(eqn, replaceExp, (inECr,inExp,0));
        //BackendDump.printEquationList({eqn1});
        //print("i="); print(intString(i)); print("\n");
        true = intGt(i,0);
        eqns =  BackendEquation.setAtIndex(inEqns,pos,eqn1);
        changed = List.consOnTrue(not listMember(pos,ichanged),pos,ichanged);
        (eqns,changed) = removeEqualFunctionCall(rest,inExp,inECr,eqns,changed);
      then (eqns,changed);
    case (_::rest,_,_,_,_)
      equation
        (eqns,changed) = removeEqualFunctionCall(rest,inExp,inECr,inEqns,ichanged);
      then (eqns,changed);
  end matchcontinue;
end removeEqualFunctionCall;

protected function replaceExp
  input DAE.Exp inExp;
  input tuple<list<DAE.SymbolicOperation>, tuple<DAE.Exp, DAE.Exp, Integer>> inTpl;
  output DAE.Exp e1;
  output tuple<list<DAE.SymbolicOperation>, tuple<DAE.Exp, DAE.Exp, Integer>> outTpl;
protected
  DAE.Exp e, se, te;
  Integer i, j;
  list<DAE.SymbolicOperation> ops;
algorithm
  e := inExp;
  (ops, (se, te, i)) := inTpl;
  // BackendDump.debugStrExpStrExpStr(("Repalce ", se, " with ", te, "\n"));
  ((e1, j)) := Expression.replaceExp(e, se, te);
  ops := if j>0 then DAE.SUBSTITUTION({e1}, e)::ops else ops;
  // BackendDump.debugStrExpStrExpStr(("Old ", e, " new ", e1, "\n"));
  outTpl := (ops, (se, te, i+j));
end replaceExp;

// =============================================================================
// remove unused parameter
//
// =============================================================================
public function removeUnusedParameter
"author: Frenkel TUD 2011-04
  This function remove unused parameters
  in BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match inDlow
    local
      BackendDAE.Variables knvars, knvars1;
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;

    case BackendDAE.DAE(eqs, shared)
      algorithm
        knvars1 := BackendVariable.emptyVars();
        knvars := shared.knownVars;
        ((knvars, knvars1)) := BackendVariable.traverseBackendDAEVars(knvars, copyNonParamVariables, (knvars,knvars1));
        ((_, knvars1)) := List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem, checkUnusedVariables, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsVars(knvars, checkUnusedParameter, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsVars(shared.aliasVars, checkUnusedParameter, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, checkUnusedParameter, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.initialEqs, checkUnusedParameter, (knvars,knvars1));
        (_, (_,knvars1)) := BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(shared.eventInfo.whenClauseLst, checkUnusedParameter, (knvars,knvars1));
        shared.knownVars := knvars1;
      then
        BackendDAE.DAE(eqs, shared);
  end match;
end removeUnusedParameter;

protected function copyNonParamVariables
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables,BackendDAE.Variables> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables,BackendDAE.Variables> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
    case (v as BackendDAE.VAR(varKind = BackendDAE.PARAM()),(vars,vars1))
      then (v,(vars,vars1));
    case (v as BackendDAE.VAR(),(vars,vars1))
      equation
        vars1 = BackendVariable.addVar(v,vars1);
      then (v,(vars,vars1));
  end matchcontinue;
end copyNonParamVariables;

protected function checkUnusedParameter
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.Variables> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,BackendDAE.Variables> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case (exp,(vars,vars1))
      equation
         (_,(_,vars1)) = Expression.traverseExpBottomUp(exp,checkUnusedParameterExp,(vars,vars1));
       then (exp,(vars,vars1));
    else (inExp,inTpl);
  end matchcontinue;
end checkUnusedParameter;

protected function checkUnusedParameterExp
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.Variables> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,BackendDAE.Variables> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;
      BackendDAE.Var var;

    // special case for time, it is never part of the equation system
    case (e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1))
      then (e, (vars,vars1));

    // Special Case for Records
    case (e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (_,(vars,vars1)) = Expression.traverseExpList(expl,checkUnusedParameterExp,(vars,vars1));
      then (e, (vars,vars1));

    // Special Case for Arrays
    case (e as DAE.CREF(ty = DAE.T_ARRAY()),(vars,vars1))
      equation
        (e1,true) = Expression.extendArrExp(e,false);
        (_,(vars,vars1)) = Expression.traverseExpBottomUp(e1,checkUnusedParameterExp,(vars,vars1));
      then (e, (vars,vars1));

    // case for functionpointers
    case (e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC()),_)
      then (e, inTuple);

    // already there
    case (e as DAE.CREF(componentRef = cr),(_,vars1))
      equation
        (_,_) = BackendVariable.getVar(cr, vars1);
      then (e, inTuple);

    // add it
    case (e as DAE.CREF(componentRef = cr),(vars,vars1))
      equation
         (var::_,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVar(var,vars1);
      then (e, (vars,vars1));

    else (inExp,inTuple);
  end matchcontinue;
end checkUnusedParameterExp;

// =============================================================================
// remove unused variables
//
// =============================================================================
public function removeUnusedVariables
"author: Frenkel TUD 2011-04
  This function remove unused variables
  from BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match inDlow
    local
      BackendDAE.Variables knvars, knvars1;
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;

    case BackendDAE.DAE(eqs, shared)
      algorithm
        knvars1 := BackendVariable.emptyVars();
        knvars := shared.knownVars;
        ((_, knvars1)) := List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem, checkUnusedVariables, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsVars(knvars, checkUnusedVariables, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsVars(shared.aliasVars, checkUnusedVariables, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, checkUnusedVariables, (knvars,knvars1));
        ((_, knvars1)) := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.initialEqs, checkUnusedVariables, (knvars,knvars1));
        (_, (_,knvars1)) := BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(shared.eventInfo.whenClauseLst, checkUnusedVariables, (knvars,knvars1));
        shared.knownVars := knvars1;
      then
        BackendDAE.DAE(eqs, shared);
  end match;
end removeUnusedVariables;

protected function checkUnusedVariables
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.Variables> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,BackendDAE.Variables> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case (exp,(vars,vars1))
      equation
         (_,(_,vars1)) = Expression.traverseExpBottomUp(exp,checkUnusedVariablesExp,(vars,vars1));
       then (exp,(vars,vars1));
    else (inExp,inTpl);
  end matchcontinue;
end checkUnusedVariables;

protected function checkUnusedVariablesExp
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.Variables> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,BackendDAE.Variables> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;
      BackendDAE.Var var;

    // special case for time, it is never part of the equation system
    case (e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1))
      then (e, (vars,vars1));

    // Special Case for Records
    case (e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,vars1))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (_,(vars,vars1)) = Expression.traverseExpList(expl,checkUnusedVariablesExp,(vars,vars1));
      then (e, (vars,vars1));

    // Special Case for Arrays
    case (e as DAE.CREF(ty = DAE.T_ARRAY()),(vars,vars1))
      equation
        (e1,true) = Expression.extendArrExp(e,false);
        (_,(vars,vars1)) = Expression.traverseExpBottomUp(e1,checkUnusedVariablesExp,(vars,vars1));
      then (e, (vars,vars1));

    // case for functionpointers
    case (DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC()),_)
      then (inExp, inTuple);

    // already there
    case (DAE.CREF(componentRef = cr),(_,vars1))
      equation
         (_,_) = BackendVariable.getVar(cr, vars1);
      then (inExp, inTuple);

    // add it
    case (DAE.CREF(componentRef = cr),(vars,vars1))
      equation
         (var::_,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVar(var,vars1);
      then (inExp, (vars,vars1));

    else (inExp,inTuple);
  end matchcontinue;
end checkUnusedVariablesExp;

// =============================================================================
// remove unused functions
//
// =============================================================================
public function removeUnusedFunctions "author: Frenkel TUD 2012-03
  This function remove unused functions from DAE.FunctionTree to get speed up
  for compilation of target code."
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
protected

  partial function FuncType
    input DAE.Exp inExp;
    input DAE.FunctionTree inUnsedFunctions;
    output DAE.Exp outExp;
    output DAE.FunctionTree outUsedFunctions;
  end FuncType;

  FuncType func;
algorithm
  outDlow := match inDlow
    local
      BackendDAE.Shared shared;
      BackendDAE.EqSystems eqs;
      DAE.FunctionTree funcs, usedfuncs;
    case BackendDAE.DAE(eqs, shared)
      algorithm
        funcs := shared.functionTree;
        usedfuncs := copyRecordConstructorAndExternalObjConstructorDestructor(funcs);
        func := function checkUnusedFunctions(inFunctions = funcs);
        usedfuncs := List.fold1(eqs, BackendDAEUtil.traverseBackendDAEExpsEqSystem, func, usedfuncs);
        usedfuncs := List.fold1(eqs, BackendDAEUtil.traverseBackendDAEExpsEqSystemJacobians, func, usedfuncs);
        usedfuncs := BackendDAEUtil.traverseBackendDAEExpsVars(shared.knownVars, func, usedfuncs);
        usedfuncs := BackendDAEUtil.traverseBackendDAEExpsVars(shared.externalObjects, func, usedfuncs);
        usedfuncs := BackendDAEUtil.traverseBackendDAEExpsVars(shared.aliasVars, func, usedfuncs);
        usedfuncs := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, func, usedfuncs);
        usedfuncs := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.initialEqs, func, usedfuncs);
        (_, usedfuncs) := BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(shared.eventInfo.whenClauseLst, func, usedfuncs);
        usedfuncs := removeUnusedFunctionsSymJacs(shared.symjacs, funcs, usedfuncs);
        shared.functionTree := usedfuncs;
      then
        BackendDAE.DAE(eqs, shared);
  end match;
end removeUnusedFunctions;

protected function copyRecordConstructorAndExternalObjConstructorDestructor
  input DAE.FunctionTree inFunctions;
  output DAE.FunctionTree outFunctions;
protected
  list<DAE.Function> funcelems;
algorithm
  funcelems := DAEUtil.getFunctionList(inFunctions);
  outFunctions := List.fold(funcelems,copyRecordConstructorAndExternalObjConstructorDestructorFold,DAE.emptyFuncTree);
end copyRecordConstructorAndExternalObjConstructorDestructor;

protected function copyRecordConstructorAndExternalObjConstructorDestructorFold
  input DAE.Function inFunction;
  input DAE.FunctionTree inFunctions;
  output DAE.FunctionTree outFunctions;
algorithm
  outFunctions :=
  matchcontinue (inFunction,inFunctions)
    local
      DAE.Function f;
      DAE.FunctionTree funcs,funcs1;
      Absyn.Path path;
    // copy record constructors
    case (f as DAE.RECORD_CONSTRUCTOR(path=path),funcs)
      equation
         funcs1 = DAEUtil.avlTreeAdd(funcs, path, SOME(f));
       then
        funcs1;
    // copy external objects constructors/destructors
    case (f as DAE.FUNCTION(path = path),funcs)
      equation
         true = boolOr(
                  stringEq(Absyn.pathLastIdent(path), "constructor"),
                  stringEq(Absyn.pathLastIdent(path), "destructor"));
         funcs1 = DAEUtil.avlTreeAdd(funcs, path, SOME(f));
       then
        funcs1;
    case (_,funcs) then funcs;
  end matchcontinue;
end copyRecordConstructorAndExternalObjConstructorDestructorFold;

protected function removeUnusedFunctionsSymJacs
  input BackendDAE.SymbolicJacobians inSymJacs;
  input DAE.FunctionTree inFunctions;
  input DAE.FunctionTree inUsedFunctions;
  output DAE.FunctionTree outUsedFunctions = inUsedFunctions;
algorithm
  for sjac in inSymJacs loop
    _ := match(sjac)
      local
        BackendDAE.BackendDAE bdae;
        DAE.FunctionTree usedfuncs;

      case (SOME((bdae, _, _, _, _)), _, _)
        equation
          bdae = BackendDAEUtil.setFunctionTree(bdae, inFunctions);
          BackendDAE.DAE(shared = BackendDAE.SHARED(functionTree = usedfuncs)) =
            removeUnusedFunctions(bdae);
          outUsedFunctions = DAEUtil.joinAvlTrees(outUsedFunctions, usedfuncs);
        then
          ();

      else ();
    end match;
  end for;
end removeUnusedFunctionsSymJacs;

protected function checkUnusedFunctions
  input DAE.Exp inExp;
  input DAE.FunctionTree inFunctions;
  input DAE.FunctionTree inUsedFunctions;
  output DAE.Exp outExp;
  output DAE.FunctionTree outUsedFunctions;
algorithm
  (outExp, outUsedFunctions) := Expression.traverseExpBottomUp(inExp,
    function checkUnusedFunctionsExp(inFunctions = inFunctions), inUsedFunctions);
end checkUnusedFunctions;

protected function checkUnusedFunctionsExp
  input DAE.Exp inExp;
  input DAE.FunctionTree inFunctions;
  input DAE.FunctionTree inUsedFunctions;
  output DAE.Exp outExp = inExp;
  output DAE.FunctionTree outUsedFunctions;
algorithm
  outUsedFunctions := match(inExp)
    local
      Absyn.Path path;
      DAE.ComponentRef cr;
      DAE.FunctionTree usedfuncs;

    // If the expression is some kind of function call, add it to the used functions.
    case DAE.CALL(path = path)
      then addUnusedFunction(path, inFunctions, inUsedFunctions);

    case DAE.PARTEVALFUNCTION(path = path)
      then addUnusedFunction(path, inFunctions, inUsedFunctions);

    case DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_FUNC(functionType =
        DAE.T_FUNCTION(source = {path})))
      then addUnusedFunction(path, inFunctions, inUsedFunctions);

    // If it's a cref, check the cref's dimensions for function calls.
    case DAE.CREF(componentRef = cr)
      algorithm
        (_, usedfuncs) := Expression.traverseExpCrefDims(cr,
          function checkUnusedFunctions(inFunctions = inFunctions), inUsedFunctions);
      then
        usedfuncs;

    // Otherwise, do nothing.
    else inUsedFunctions;
  end match;
end checkUnusedFunctionsExp;

protected function addUnusedFunction
  input Absyn.Path inPath;
  input DAE.FunctionTree inFunctions;
  input DAE.FunctionTree inUsedFunctions;
  output DAE.FunctionTree outUsedFunctions = inUsedFunctions;
protected
  Option<DAE.Function> f;
  list<DAE.Element> body;
algorithm
  try // Check if the function has already been added.
    _ := DAEUtil.avlTreeGet(inUsedFunctions, inPath);
  else // Otherwise, try to add it.
    (f, body) := getFunctionAndBody(inPath, inFunctions);

    if isSome(f) then
      outUsedFunctions := DAEUtil.avlTreeAdd(outUsedFunctions, inPath, f);
      (_, outUsedFunctions) := DAEUtil.traverseDAE2(body,
        function checkUnusedFunctions(inFunctions = inFunctions), outUsedFunctions);
    end if;
  end try;
end addUnusedFunction;

protected function getFunctionAndBody
"returns the body of a function"
  input Absyn.Path inPath;
  input DAE.FunctionTree fns;
  output Option<DAE.Function> outFn;
  output list<DAE.Element> outFnBody;
protected
  DAE.Function fn;
algorithm
  try
    outFn as SOME(fn) := DAEUtil.avlTreeGet(fns, inPath);
    outFnBody := DAEUtil.getFunctionElements(fn);
  else
    outFn := NONE();
    outFnBody := {};
  end try;
end getFunctionAndBody;


// =============================================================================
// parallel back end stuff (TLM)
//
// =============================================================================

public function collapseIndependentBlocks
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem syst;
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  // We can use listReduce as if there is no eq-system something went terribly wrong
  syst := List.reduce(systs, mergeIndependentBlocks);
  outDAE := BackendDAE.DAE({syst}, shared);
end collapseIndependentBlocks;

protected function mergeIndependentBlocks
  input BackendDAE.EqSystem syst1;
  input BackendDAE.EqSystem syst2;
  output BackendDAE.EqSystem syst;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs, removedEqs;
  BackendDAE.StateSets stateSets;
algorithm
  vars := BackendVariable.mergeVariables(syst2.orderedVars, syst1.orderedVars);
  eqs := BackendEquation.addEquations(BackendEquation.equationList(syst2.orderedEqs), syst1.orderedEqs);
  removedEqs := BackendEquation.addEquations(BackendEquation.equationList(syst2.removedEqs), syst1.removedEqs);
  stateSets := listAppend(syst2.stateSets, syst1.stateSets);
  syst := BackendDAEUtil.createEqSystem(vars, eqs, stateSets, BackendDAE.UNKNOWN_PARTITION(), removedEqs);
end mergeIndependentBlocks;

public function partitionIndependentBlocks
  "Finds independent partitions of the equation system by "
  input BackendDAE.BackendDAE dlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match (dlow)
    local
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;

    case (BackendDAE.DAE({syst},shared))
      equation
        (systs,shared) = partitionIndependentBlocksHelper(syst,shared,Error.getNumErrorMessages(),false);
      then BackendDAE.DAE(systs,shared);
    else // TODO: Improve support for partitioned systems of equations
      equation
        BackendDAE.DAE({syst},shared) = collapseIndependentBlocks(dlow);
        (systs,shared) = partitionIndependentBlocksHelper(syst,shared,Error.getNumErrorMessages(),false);
      then BackendDAE.DAE(systs,shared);
  end match;
end partitionIndependentBlocks;

public function partitionIndependentBlocksHelper
  "Finds independent partitions of the equation system by "
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer numErrorMessages;
  input Boolean throwNoError;
  output list<BackendDAE.EqSystem> systs;
  output BackendDAE.Shared oshared;
algorithm
  (systs,oshared) := matchcontinue (isyst,ishared,numErrorMessages,throwNoError)
    local
      BackendDAE.IncidenceMatrix m,mT;
      array<Integer> ixs;
      Boolean b;
      Integer i;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;
    case (syst,shared,_,_)
      equation
        // print("partitionIndependentBlocks: TODO: Implement me\n");
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL(),SOME(funcs));
        ixs = arrayCreate(arrayLength(m),0);
        // ixsT = arrayCreate(arrayLength(mT),0);
        i = SynchronousFeatures.partitionIndependentBlocks0(m,mT,ixs);
        // i2 = SynchronousFeatures.partitionIndependentBlocks0(mT,m,ixsT);
        b = i > 1;
        // bcall2(b,BackendDump.dumpBackendDAE,BackendDAE.DAE({syst},shared), "partitionIndependentBlocksHelper");
        // printPartition(b,ixs);
        systs = if b then SynchronousFeatures.partitionIndependentBlocksSplitBlocks(i,syst,ixs,mT,throwNoError) else {syst};
        // print("Number of partitioned systems: " + intString(listLength(systs)) + "\n");
        // List.map1_0(systs, BackendDump.dumpEqSystem, "System");
      then (systs,shared);
    else
      equation
        Error.assertion(not (numErrorMessages==Error.getNumErrorMessages()),"BackendDAEOptimize.partitionIndependentBlocks failed without good error message",Absyn.dummyInfo);
      then fail();
  end matchcontinue;
end partitionIndependentBlocksHelper;


// =============================================================================
// residual stuff ... for whatever reason
//
// =============================================================================

public function residualForm
  "Puts equations like x=y in the form of 0=x-y"
  input BackendDAE.BackendDAE dlow;
  output BackendDAE.BackendDAE odlow;
algorithm
  odlow := BackendDAEUtil.mapEqSystem1(dlow,residualForm1,1);
end residualForm;

protected function residualForm1
  "Puts equations like x=y in the form of 0=x-y"
  input BackendDAE.EqSystem syst;
  input Integer i;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst = syst;
  output BackendDAE.Shared oshared = shared;
protected
  BackendDAE.EquationArray eqs;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=eqs) := syst;
  BackendEquation.traverseEquationArray_WithUpdate(eqs, residualForm2, 1);
end residualForm1;

protected function residualForm2
  input BackendDAE.Equation inEq;
  input Integer ii;
  output BackendDAE.Equation outEq;
  output Integer oi;
algorithm
  (outEq,oi) := matchcontinue (inEq,ii)
    local
      tuple<BackendDAE.Equation,Integer> ntpl;
      DAE.Exp e1,e2,e;
      DAE.ElementSource source;
      Integer i;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.EQUATION(e1,e2,source,eqAttr),i)
      equation
        // This is ok, because EQUATION is not an array equation :D
        DAE.T_REAL() = Expression.typeof(e1);
        false = Expression.isZero(e1) or Expression.isZero(e2);
        e = DAE.BINARY(e1,DAE.SUB(DAE.T_REAL_DEFAULT),e2);
        (e,_) = ExpressionSimplify.simplify(e);
        source = DAEUtil.addSymbolicTransformation(source, DAE.OP_RESIDUAL(e1,e2,e));
      then (BackendDAE.EQUATION(DAE.RCONST(0.0),e,source,eqAttr),i);
    else (inEq,ii);
  end matchcontinue;
end residualForm2;

// =============================================================================
// countOperations
//
// =============================================================================

public function countOperations "author: Frenkel TUD 2011-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if Flags.isSet(Flags.COUNT_OPERATIONS) then
    (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, countOperations0, false);
  else
    outDAE := inDAE;
  end if;
end countOperations;

protected function countOperations0 "author: Frenkel TUD 2011-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst = isyst;
  output BackendDAE.Shared outShared = inShared;
  output Boolean outChanged = inChanged;
protected
  list<BackendDAE.CompInfo> compInfos;
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := isyst;
  (compInfos) := countOperationstraverseComps(comps, isyst, inShared,{});
end countOperations0;

public function countOperationstraverseComps "author: Frenkel TUD 2012-05"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<BackendDAE.CompInfo> compInfosIn;
  output list<BackendDAE.CompInfo> compInfosOut;
algorithm
  compInfosOut :=  matchcontinue (inComps,isyst,ishared,compInfosIn)
    local
      Integer eqIdx, numAdd,numMul,numDiv,numTrig,numRel,numOth, numFuncs, numLog, size;
      Real density;
      list<Integer> eqs, tornEqs,otherEqs;
      BackendDAE.StrongComponent comp,comp1;
      BackendDAE.StrongComponents rest;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      BackendDAE.Equation eqn;
      BackendDAE.CompInfo compInfo, allOps, torn,other;
      list<BackendDAE.Equation> eqnlst;
      BackendDAE.Jacobian jac;
      DAE.FunctionTree funcs;
      list<BackendDAE.Var> varlst;
      list<DAE.Exp> explst;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
      list<Integer> vlst;
    case ({},_,_,_) then compInfosIn;
    case (BackendDAE.SINGLEEQUATION(eqn=eqIdx)::rest,_,_,_)
      equation
        eqns = BackendEquation.getEqnsFromEqSystem(isyst);
        eqn = BackendEquation.equationNth1(eqns, eqIdx);
          //BackendDump.dumpBackendDAEEqnList({eqn},"AN EQUATION",true);
        //BackendDump.dumpEquationList({eqn},"");
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        compInfo = BackendDAE.COUNTER(listHead(inComps),numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        if Flags.isSet(Flags.COUNT_OPERATIONS) then BackendDump.dumpCompInfo(compInfo); end if;
      then countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case (BackendDAE.SINGLEWHENEQUATION(eqn=eqIdx)::rest,_,_,_)
      equation
         eqn = BackendEquation.equationNth1(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         //BackendDump.printEquation(eqn);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(listHead(inComps),numAdd,numMul,numDiv,numTrig,numRel,numLog+1,numOth,numFuncs);
        if Flags.isSet(Flags.COUNT_OPERATIONS) then BackendDump.dumpCompInfo(compInfo); end if;
      then countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.EQUATIONSYSTEM(eqns=eqs,jac=jac,jacType=BackendDAE.JAC_LINEAR()))::rest,_,_,_)
      equation
        (_,_,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.getEqnsFromEqSystem(isyst), BackendVariable.daeVars(isyst));
        size = listLength(eqs);
        density = realDiv(intReal(getNumJacEntries(jac)),intReal(size*size ));
        allOps = BackendDAE.COUNTER(comp,0,0,0,0,0,0,0,0);
        allOps = countOperationsJac(jac,ishared,allOps);
        compInfo = BackendDAE.SYSTEM(comp,allOps,size,density);
      then countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.EQUATIONSYSTEM(jac=jac))::rest,_,_,_)
      equation
        (eqnlst,_,_) = BackendDAETransform.getEquationAndSolvedVar(comp, BackendEquation.getEqnsFromEqSystem(isyst), BackendVariable.daeVars(isyst));
        size = listLength(eqnlst);
        (numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs) = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendEquation.listEquation(eqnlst),function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        allOps = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        density = realDiv(intReal(getNumJacEntries(jac)),intReal(size*size ));
        compInfo = BackendDAE.SYSTEM(comp,allOps,size,density);
      then
        countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLEARRAY(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.equationNth1(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLEIFEQUATION(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.equationNth1(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog+1,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLEALGORITHM(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.equationNth1(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog+1,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.equationNth1(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog+1,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst, residualequations=tornEqs, otherEqnVarTpl= eqnvartpllst), linear = true)::rest,_,BackendDAE.SHARED(functionTree=funcs),_)
      equation
        comp = listHead(inComps);
        eqns = BackendEquation.getEqnsFromEqSystem(isyst);
        vars = BackendVariable.daeVars(isyst);
        // the torn equations
        eqnlst = BackendEquation.getEqns(tornEqs,eqns);
        varlst = List.map1(vlst,BackendVariable.getVarAtIndexFirst, vars);
        (explst,_) = BackendDAEUtil.getEqnSysRhs(BackendEquation.listEquation(eqnlst),BackendVariable.listVar1(varlst),SOME(funcs));
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = Expression.traverseExpList(explst,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        torn = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        // the other eqs
        otherEqs = List.map(eqnvartpllst,Util.tuple21);
        vlst = List.flatten(List.map(eqnvartpllst,Util.tuple22));
        eqnlst = BackendEquation.getEqns(otherEqs,eqns);
        varlst = List.map1(vlst,BackendVariable.getVarAtIndexFirst, vars);
        (explst,_) = BackendDAEUtil.getEqnSysRhs(BackendEquation.listEquation(eqnlst),BackendVariable.listVar1(varlst),SOME(funcs));
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = Expression.traverseExpList(explst,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        other = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        compInfo = BackendDAE.TORN_ANALYSE(comp,torn,other,listLength(tornEqs));
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=tornEqs, otherEqnVarTpl= eqnvartpllst), linear = false)::rest,_,BackendDAE.SHARED(),_)
      equation
        comp = listHead(inComps);
        eqns = BackendEquation.getEqnsFromEqSystem(isyst);
        _ = BackendVariable.daeVars(isyst);
        // the torn equations
        eqnlst = BackendEquation.getEqns(tornEqs,eqns);
        explst = List.map(eqnlst,BackendEquation.getEquationRHS);
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = Expression.traverseExpList(explst,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        torn = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        // the other eqs
        otherEqs = List.map(eqnvartpllst,Util.tuple21);
        eqnlst = BackendEquation.getEqns(otherEqs,eqns);
        explst = List.map(eqnlst,BackendEquation.getEquationRHS);
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = Expression.traverseExpList(explst,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        other = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        compInfo = BackendDAE.TORN_ANALYSE(comp,torn,other,listLength(tornEqs));
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);
    case (comp::rest,_,_,_)
      equation
        print("not supported component: "+BackendDump.strongComponentString(comp)+"\n");
      then
        countOperationstraverseComps(rest,isyst,ishared,compInfosIn);
  end matchcontinue;
end countOperationstraverseComps;

protected function getNumJacEntries
  input BackendDAE.Jacobian inJac;
  output Integer numEntries;
algorithm
  numEntries := match(inJac)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      case (BackendDAE.FULL_JACOBIAN(NONE()))
        equation
           then -1;
      case (BackendDAE.FULL_JACOBIAN(SOME(jac)))
        equation
        then listLength(jac);
      /* TODO: implement for GENERIC_JACOBIAN */
      case (_)
        equation
          print("another JAC\n");
        then -1;
  end match;
end getNumJacEntries;


protected function countOperationsJac
  input BackendDAE.Jacobian inJac;
  input BackendDAE.Shared shared;
  input BackendDAE.CompInfo compInfoIn;
  output BackendDAE.CompInfo compInfoOut;
algorithm
  compInfoOut := match(inJac,shared,compInfoIn)
    local
      Integer numAdd,numMul,numDiv,numOth,numTrig,numRel,numLog, numFuncs;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.StrongComponent comp;
      case (BackendDAE.FULL_JACOBIAN(NONE()),_,_) then compInfoIn;
      case (BackendDAE.FULL_JACOBIAN(SOME(jac)),_,BackendDAE.COUNTER(comp=comp,numAdds=numAdd,numMul=numMul,numDiv=numDiv,numTrig=numTrig,numRelations=numRel,numLog=numLog,numOth=numOth,funcCalls=numFuncs))
        equation
          (numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs) = List.fold(jac,function countOperationsJac1(shared=shared),((numAdd,numMul,numDiv,numOth,numTrig,numRel,numLog,numFuncs)));
        then BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
      /* TODO: implement for GENERIC_JACOBIAN */
      case (_,_,_) then compInfoIn;
  end match;
end countOperationsJac;

protected function countOperationsJac1
  input tuple<Integer, Integer, BackendDAE.Equation> inJac;
  input BackendDAE.Shared shared;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> outTpl;
algorithm
  (_,outTpl) := BackendEquation.traverseExpsOfEquation(Util.tuple33(inJac),function countOperationsExp(shared=shared),inTpl);
end countOperationsJac1;

public function countOperationsExp
  input DAE.Exp inExp;
  input BackendDAE.Shared shared;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> inTpl;
  output DAE.Exp outExp;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> outTpl;
algorithm
  (outExp,outTpl) := Expression.traverseExpBottomUp(inExp,function traversecountOperationsExp(shared=shared),inTpl);
end countOperationsExp;

protected function traversecountOperationsExp
  input DAE.Exp inExp;
  input BackendDAE.Shared shared;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> inTuple;
  output DAE.Exp outExp;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,shared,inTuple)
    local
      Absyn.Path path;
      DAE.Exp e,cond,exp1,exp2;
      DAE.Function func;
      Integer i1,i2,i3,i4,i5,i6,i7,i8;
      tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> tpl;
      Integer iexp2;
      Real rexp2;
      DAE.Operator op;
      String opName;
      Absyn.Path path;
      list<DAE.Exp> expLst;
      list<DAE.Element> elemLst;
    //case (e as DAE.BINARY(operator=DAE.POW(),exp2=DAE.RCONST(rexp2)),_,(i1,i2,i3,i4,i5,i6)) equation
    //  iexp2 = realInt(rexp2);
    //  true = realEq(rexp2, intReal(iexp2));
    //  i2_1 = i2+intAbs(iexp2)-1;
    //  then (e, (i1,i2_1,i3,i4,i5,i6));

    case (e as DAE.BINARY(operator=op),_,_) equation
      tpl = countOperator(op,inTuple);
      then (e, tpl);

    case (e as DAE.UNARY(operator=op),_,_) equation
      tpl = countOperator(op,inTuple);
      then (e, tpl);

    case (e as DAE.LBINARY(operator=op),_,_) equation
      tpl = countOperator(op,inTuple);
      then (e, tpl);

    case (e as DAE.LUNARY(operator=op),_,_) equation
      tpl = countOperator(op,inTuple);
      then (e, tpl);

    case (e as DAE.RELATION(operator=op),_,_) equation
      tpl = countOperator(op,inTuple);
      then (e, tpl);

    case (e as DAE.IFEXP(expCond=cond,expThen=exp1,expElse=exp2),_,_) equation
      //count all branches, use the complete count for the condition and one additional logical count
      (_,tpl) = traversecountOperationsExp(cond,shared,inTuple);
      (_,tpl) = traversecountOperationsExp(exp1,shared,tpl);
      (_,tpl) = traversecountOperationsExp(exp2,shared,tpl);
      (_,(i1,i2,i3,i4,i5,i6,i7,i8)) = traversecountOperationsExp(cond,shared,tpl);
      then (e, (i1,i2,i3,i4,i5,i6+1,i7,i8));

    case (e as DAE.RECORD(exps=expLst),_,_) equation
      (_,tpl) = Expression.traverseExpList(expLst,function countOperationsExp(shared=shared),inTuple);
      then (e, tpl);

     case (e as DAE.ARRAY(array=expLst),_,_) equation
      (_,tpl) = Expression.traverseExpList(expLst,function countOperationsExp(shared=shared),inTuple);
      then (e, tpl);

     case (e as DAE.TUPLE(PR=expLst),_,_) equation
      (_,tpl) = Expression.traverseExpList(expLst,function countOperationsExp(shared=shared),inTuple);
      then (e, tpl);

    case (e as DAE.CALL(path=Absyn.IDENT(name=opName)),_,(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      true = stringEq(opName,"sin") or stringEq(opName,"cos") or stringEq(opName,"tan");
      then (e, (i1,i2,i3,i4+1,i5,i6,i7,i8));

    case (e as DAE.CALL(path=Absyn.IDENT(name=opName)),_,(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      true = stringEq(opName,"der");
      then (e, (i1,i2,i3,i4,i5,i6,i7,i8));

    case (e as DAE.CALL(path=Absyn.IDENT(name=opName)),_,(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      true = stringEq(opName,"exp");
      then (e, (i1,i2,i3,i4,i5,i6,i7+1,i8));

    case (e as DAE.CALL(path=Absyn.IDENT(name=opName)),_,(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      true = stringEq(opName,"pre");
      then (e, (i1,i2,i3,i4,i5,i6,i7,i8+1));

    case (e as DAE.CALL(path=path),_,_) equation
      func = DAEUtil.getNamedFunction(path,BackendDAEUtil.getFunctions(shared));
      elemLst = DAEUtil.getFunctionElements(func);
      //print(ExpressionDump.dumpExpStr(e,0)+"\n");
      //print("THE FUCNTION CALL\n "+DAEDump.dumpElementsStr(elemLst)+"\n");
      (i1,i2,i3,i4,i5,i6,i7,i8) = countOperationsInFunction(elemLst,shared,inTuple);
      then (e, (i1,i2,i3,i4,i5,i6,i7,i8+1));
    else
      equation
        //print(ExpressionDump.dumpExpStr(inExp,0)+"\n");
        then (inExp,inTuple);
  end matchcontinue;
end traversecountOperationsExp;

protected function countOperationsInFunction
  input list<DAE.Element> elemLst;
  input BackendDAE.Shared shared;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> outTpl;
algorithm
  outTpl := matchcontinue(elemLst,shared,inTpl)
    local
      tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> tpl;
      DAE.Element elem;
      DAE.Exp exp1, exp2;
      list<DAE.Statement> stmts;
      list<DAE.Element> rest;
     case({},_,_)
      equation
    then inTpl;
    case(DAE.ALGORITHM(algorithm_=DAE.ALGORITHM_STMTS(statementLst=stmts))::rest,_,_)
      equation
        (_,tpl) = DAEUtil.traverseDAEEquationsStmts(stmts,function traversecountOperationsExp(shared=shared),inTpl);
    then countOperationsInFunction(rest,shared,tpl);
    case(DAE.EQUATION(exp=exp1, scalar=exp2)::rest,_,_)
      equation
        (_,tpl) = traversecountOperationsExp(exp1,shared,inTpl);
        (_,tpl) = traversecountOperationsExp(exp2,shared,tpl);
    then countOperationsInFunction(rest,shared,tpl);
    case(DAE.COMPLEX_EQUATION(lhs=exp1, rhs=exp2)::rest,_,_)
      equation
        (_,tpl) = traversecountOperationsExp(exp1,shared,inTpl);
        (_,tpl) = traversecountOperationsExp(exp2,shared,tpl);
    then countOperationsInFunction(rest,shared,tpl);
    case(_::rest,_,_)
      equation
    then countOperationsInFunction(rest,shared,inTpl);
  end matchcontinue;
end countOperationsInFunction;

protected function countOperator
  input DAE.Operator op;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> inTpl; // add,mul,div,trig,relations,logical,other,funcCalls
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,Integer,Integer> outTpl;
algorithm
  outTpl := match(op, inTpl)
    local
      DAE.Type tp;
      Integer i,i1,i2,i3,i4,i5,i6,i7,i8;
    case (DAE.ADD(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1+1,i2,i3,i4,i5,i6,i7,i8);
    case (DAE.SUB(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1+1,i2,i3,i4,i5,i6,i7,i8);
    case (DAE.MUL(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2+1,i3,i4,i5,i6,i7,i8);
    case (DAE.DIV(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3+1,i4,i5,i6,i7,i8);
    case (DAE.POW(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5,i6,i7+1,i8);
    case (DAE.UMINUS(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1+1,i2,i3,i4,i5,i6,i7,i8);
    case (DAE.UMINUS_ARR(ty=tp),(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      i = Expression.sizeOf(tp);
      then (i1+i,i2,i3+i,i4,i5,i6,i7,i8);
    case (DAE.ADD_ARR(ty=tp),(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      i = Expression.sizeOf(tp);
      then (i1+i,i2,i3,i4,i5,i6,i7,i8);
    case (DAE.SUB_ARR(ty=tp),(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      i = Expression.sizeOf(tp);
      then (i1+i,i2,i3,i4,i5,i6,i7,i8);
    case (DAE.MUL_ARR(ty=tp),(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      i = Expression.sizeOf(tp);
      then (i1,i2+i,i3,i4,i5,i6,i7,i8);
    case (DAE.DIV_ARR(ty=tp),(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      i = Expression.sizeOf(tp);
      then (i1,i2,i3+i,i4,i5,i6,i7,i8);
    case (DAE.MUL_ARRAY_SCALAR(),(i1,i2,i3,i4,i5,i6,i7,i8)) equation
      then (i1,i2+1,i3,i4,i5,i6,i7,i8);
    case (DAE.ADD_ARRAY_SCALAR(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1+1,i2,i3,i4,i5,i6,i7,i8);
    case (DAE.SUB_SCALAR_ARRAY(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1+1,i2,i3,i4,i5,i6,i7,i8);
    case (DAE.MUL_SCALAR_PRODUCT(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2+1,i3,i4,i5,i6,i7,i8);
    case (DAE.MUL_MATRIX_PRODUCT(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2+1,i3,i4,i5,i6,i7,i8);
    case (DAE.DIV_ARRAY_SCALAR(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3+1,i4,i5,i6,i7,i8);
    case (DAE.DIV_SCALAR_ARRAY(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3+1,i4,i5,i6,i7,i8);
    case (DAE.POW_ARRAY_SCALAR(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5,i6,i7+1,i8);
    case (DAE.POW_SCALAR_ARRAY(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5,i6,i7+1,i8);
    case (DAE.POW_ARR(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5,i6,i7+1,i8);
    case (DAE.POW_ARR2(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5,i6,i7+1,i8);
    case (DAE.AND(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5,i6+1,i7,i8);
    case (DAE.OR(),(i1,i2,i3,i4,i5,i6,i7,i8))
      equation
      then (i1,i2,i3,i4,i5,i6+1,i7,i8);
    case (DAE.NOT(),(i1,i2,i3,i4,i5,i6,i7,i8))
      equation
      then (i1,i2,i3,i4,i5,i6+1,i7,i8);
    case (DAE.LESS(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5+1,i6,i7,i8);
    case (DAE.LESSEQ(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5+1,i6,i7,i8);
    case (DAE.GREATER(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5+1,i6,i7,i8);
    case (DAE.GREATEREQ(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5+1,i6,i7,i8);
    case (DAE.EQUAL(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5+1,i6,i7,i8);
    case (DAE.NEQUAL(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5+1,i6,i7,i8);
    case (DAE.USERDEFINED(),(i1,i2,i3,i4,i5,i6,i7,i8))
      then (i1,i2,i3,i4,i5,i6+1,i7,i8);
    else
    equation
      print("not supported operator\n");
      then inTpl;
  end match;
end countOperator;


// =============================================================================
// simplify if equations
//
// =============================================================================

public function simplifyIfEquations "author: Frenkel TUD 2012-07
  This function traveres all if equations and if expressions and tries to
  simplify it by using the information from evaluated parameters."
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem(dae, simplifyIfEquationsWork);
end simplifyIfEquations;

protected function simplifyIfEquationsWork "author: Frenkel TUD 2012-07
  This function traveres all if equations and if expressions and tries to
  simplify it by using the information from evaluated parameters."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := matchcontinue (isyst, ishared)
    local
      BackendDAE.Variables vars, knvars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> eqnslst, asserts;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;

    case ( syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),
           shared as BackendDAE.SHARED(knownVars=knvars) )
      algorithm
        // traverse the equations
        eqnslst := BackendEquation.equationList(eqns);
        // traverse equations in reverse order, than branch equations of if equaitions need no reverse
        ((eqnslst,asserts,true)) := List.fold1(listReverse(eqnslst), simplifyIfEquationsFinder, knvars, ({},{},false));
        syst.orderedEqs := BackendEquation.listEquation(eqnslst);
        syst := BackendDAEUtil.clearEqSyst(syst);
        syst := BackendEquation.requationsAddDAE(asserts, syst);
      then (syst, shared);

    else
      then (isyst, ishared);
  end matchcontinue;
end simplifyIfEquationsWork;

protected function simplifyIfEquationsFinder
"author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input BackendDAE.Equation inElem;
  input BackendDAE.Variables inConstArg;
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,Boolean> inArg;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,Boolean> outArg;
algorithm
  outArg := matchcontinue(inElem,inConstArg,inArg)
    local
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqnslst,acc,asserts,asserts1;
      list<list<BackendDAE.Equation>> eqnslstlst;
      DAE.ElementSource source;
      BackendDAE.Variables knvars;
      Boolean b;
      BackendDAE.Equation eqn;
      BackendDAE.EquationAttributes attr;

    case (BackendDAE.IF_EQUATION(conditions=explst, eqnstrue=eqnslstlst, eqnsfalse=eqnslst, source=source, attr=attr), knvars, (acc, asserts, _))
      equation
        // check conditions
        (explst,_) = Expression.traverseExpList(explst, simplifyEvaluatedParamter, (knvars,false));
        explst = ExpressionSimplify.simplifyList(explst, {});
        // simplify if equation
        (acc,asserts1) = simplifyIfEquation(explst,eqnslstlst,eqnslst,{},{},source,knvars,acc,attr);
        asserts = listAppend(asserts,asserts1);
      then
        ((acc, asserts, true));

    case (eqn,knvars,(acc,asserts,b))
      equation
        (eqn,(_,b)) = BackendEquation.traverseExpsOfEquation(eqn, simplifyIfExpevaluatedParamter, (knvars,b));
      then
        ((eqn::acc,asserts,b));
  end matchcontinue;
end simplifyIfEquationsFinder;

protected function simplifyIfExpevaluatedParamter
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean> tpl1;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,Boolean> tpl2;
algorithm
  (outExp,tpl2) := matchcontinue (inExp,tpl1)
    local
      BackendDAE.Variables knvars;
      DAE.Exp e1,e2,cond,expThen,expElse;
      Boolean b,b1;
    case (e1 as DAE.IFEXP(expCond=cond, expThen=expThen, expElse=expElse),(knvars,b))
      equation
        (cond,(_,b1)) = Expression.traverseExpBottomUp(cond, simplifyEvaluatedParamter, (knvars,false));
        e2 = if b1 then DAE.IFEXP(cond,expThen,expElse) else e1;
        (e2,_) = ExpressionSimplify.condsimplify(b1,e2);
      then (e2,(knvars,b or b1));
    else (inExp,tpl1);
  end matchcontinue;
end simplifyIfExpevaluatedParamter;

protected function simplifyEvaluatedParamter
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean> tpl1;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,Boolean> tpl2;
algorithm
  (outExp,tpl2) := matchcontinue (inExp,tpl1)
    local
      BackendDAE.Variables knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      DAE.Exp e;
    case (DAE.CREF(componentRef = cr),(knvars,_))
      equation
        (v::{},_::{}) = BackendVariable.getVar(cr,knvars);
        true = BackendVariable.isFinalVar(v);
        e = BackendVariable.varBindExpStartValue(v);
      then (e,(knvars,true));
    else (inExp,tpl1);
  end matchcontinue;
end simplifyEvaluatedParamter;

protected function simplifyIfEquation
"author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input list<BackendDAE.Equation> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<BackendDAE.Equation>> theneqns1;
  input DAE.ElementSource source;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.EquationAttributes inEqAttr;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outAsserts;
algorithm
  (outEqns,outAsserts) := match(conditions,theneqns,elseenqs,conditions1,theneqns1,source,knvars,inEqns,inEqAttr)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns,elseenqs1,asserts;

    // no true case left with condition<>false
    case ({},{},_,{},{},_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold1(listReverse(elseenqs), simplifyIfEquationsFinder, knvars, ({},{},false));
      then
        (listAppend(eqns,inEqns),asserts);
    // true case left with condition<>false
    case ({},{},_,_,_,_,_,_,_)
      equation
        explst = listReverse(conditions1);
        eqnslst = listReverse(theneqns1);
        // simplify nested if equations
        ((elseenqs1,asserts,_)) = List.fold1(listReverse(elseenqs), simplifyIfEquationsFinder, knvars, ({},{},false));
        elseenqs1 = listAppend(elseenqs1,asserts);
        (eqnslst,elseenqs1,asserts) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs1,{},{},{});
        eqns = simplifyIfEquation1(explst,eqnslst,elseenqs1,source,knvars,inEqns,inEqAttr);
      then
        (eqns,asserts);
    // if true and first use it
    case(DAE.BCONST(true)::_,eqns::_,_,{},_,_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold1(listReverse(eqns), simplifyIfEquationsFinder, knvars, ({},{},false));
      then
        (listAppend(eqns,inEqns),asserts);
    // if true and not first use it as new else
    case(DAE.BCONST(true)::_,eqns::_,_,_,_,_,_,_,_)
      equation
        explst = listReverse(conditions1);
        eqnslst = listReverse(theneqns1);
        // simplify nested if equations
        ((elseenqs1,asserts,_)) = List.fold1(listReverse(eqns), simplifyIfEquationsFinder, knvars, ({},{},false));
        elseenqs1 = listAppend(elseenqs1,asserts);
        (eqnslst,elseenqs1,asserts) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs1,{},{},{});
        eqns = simplifyIfEquation1(explst,eqnslst,elseenqs1,source,knvars,inEqns,inEqAttr);
      then
        (eqns,asserts);
    // if false skip it
    case(DAE.BCONST(false)::explst,_::eqnslst,_,_,_,_,_,_,_)
      equation
        (eqns,asserts) = simplifyIfEquation(explst,eqnslst,elseenqs,conditions1,theneqns1,source,knvars,inEqns,inEqAttr);
      then
        (eqns,asserts);
    // all other cases
    case(e::explst,eqns::eqnslst,_,_,_,_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold1(listReverse(eqns), simplifyIfEquationsFinder, knvars, ({},{},false));
        eqns = listAppend(eqns,asserts);
        (eqns,asserts) = simplifyIfEquation(explst,eqnslst,elseenqs,e::conditions1,eqns::theneqns1,source,knvars,inEqns,inEqAttr);
      then
        (eqns,asserts);
  end match;
end simplifyIfEquation;

protected function simplifyIfEquation1
"author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input list<BackendDAE.Equation> elseenqs;
  input DAE.ElementSource source;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.EquationAttributes inEqAttr;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(conditions,theneqns,elseenqs,source,knvars,inEqns,inEqAttr)
    local
      list<DAE.Exp> fbsExp;
      list<list<DAE.Exp>> tbsExp;
      list<BackendDAE.Equation> eqns;
      HashTable2.HashTable ht;
      list<tuple<DAE.ComponentRef,DAE.Exp>> crexplst;

    // true case left with condition<>false
    case (_,_,_,_,_,_,_)
      equation
        _ = countEquationsInBranches(theneqns,elseenqs,source);
        // simplify if eqution
        // if .. then a=.. elseif .. then a=... else a=.. end if;
        // to
        // a=if .. then .. else if .. then else ..;
        ht = HashTable2.emptyHashTable();
        ht = simplifySolvedIfEqnsElse(elseenqs,ht);
        ht = simplifySolvedIfEqns(listReverse(conditions),listReverse(theneqns),ht);
        crexplst = BaseHashTable.hashTableList(ht);
        eqns = simplifySolvedIfEqns2(crexplst, inEqns, inEqAttr);
        // ToDo: check if the same cref is not used more than once on the lhs, merge sources
      then
        eqns;
    case (_,_,_,_,_,_,_)
      equation
        _ = countEquationsInBranches(theneqns,elseenqs,source);
        fbsExp = makeEquationLstToResidualExpLst(elseenqs);
        tbsExp = List.map(theneqns, makeEquationLstToResidualExpLst);
        eqns = makeEquationsFromResiduals(conditions, tbsExp, fbsExp, source, inEqAttr);
      then
        listAppend(eqns,inEqns);

    else BackendDAE.IF_EQUATION(conditions,theneqns,elseenqs,source,inEqAttr)::inEqns;
  end matchcontinue;
end simplifyIfEquation1;

protected function simplifySolvedIfEqns2
  input list<tuple<DAE.ComponentRef,DAE.Exp>> crexplst;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.EquationAttributes inEqAttr;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := match(crexplst, inEqns, inEqAttr)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,crexp;
      list<tuple<DAE.ComponentRef,DAE.Exp>> rest;

    case ({}, _, _)
    then inEqns;

    case ((cr,e)::rest,_, _)
      equation
        crexp = Expression.crefExp(cr);
      then
       simplifySolvedIfEqns2(rest, BackendDAE.EQUATION(crexp, e, DAE.emptyElementSource, inEqAttr)::inEqns, inEqAttr);
  end match;
end simplifySolvedIfEqns2;

protected function simplifySolvedIfEqns
"author: Frenkel TUD 2012-10
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input HashTable2.HashTable iHt;
  output HashTable2.HashTable oHt;
algorithm
  oHt := match(conditions,theneqns,iHt)
    local
      HashTable2.HashTable ht;
      DAE.Exp c;
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> rest;
    case ({},{},_)
      then
        iHt;
    case (c::explst,eqns::rest,_)
      equation
        ht = simplifySolvedIfEqns1(c,eqns,iHt);
      then
        simplifySolvedIfEqns(explst,rest,ht);
  end match;
end simplifySolvedIfEqns;

protected function simplifySolvedIfEqns1
"author: Frenkel TUD 2012-10
  helper for simplifyIfEquations"
  input DAE.Exp condition;
  input list<BackendDAE.Equation> brancheqns;
  input HashTable2.HashTable iHt;
  output HashTable2.HashTable oHt;
algorithm
  oHt := match(condition,brancheqns,iHt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,exp;
      DAE.ElementSource source;
      HashTable2.HashTable ht;
      list<BackendDAE.Equation> rest;
    case (_,{},_)
      then
        iHt;
    case (_,BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e)::rest,_)
      equation
        false = Expression.expHasCref(e, cr);
        exp = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        ht = BaseHashTable.add((cr,exp), iHt);
      then
        simplifySolvedIfEqns1(condition,rest,ht);
    case (_,BackendDAE.EQUATION(exp=DAE.UNARY(operator=DAE.UMINUS(), exp=DAE.CREF(componentRef=cr)), scalar=e)::rest,_)
      equation
        false = Expression.expHasCref(e, cr);
        exp = BaseHashTable.get(cr, iHt);
        e = Expression.negate(e);
        exp = DAE.IFEXP(condition, e, exp);
        ht = BaseHashTable.add((cr,exp), iHt);
      then
        simplifySolvedIfEqns1(condition,rest,ht);
  end match;
end simplifySolvedIfEqns1;

protected function simplifySolvedIfEqnsElse
"author: Frenkel TUD 2012-10
  helper for simplifyIfEquations"
  input list<BackendDAE.Equation> elseenqs;
  input HashTable2.HashTable iHt;
  output HashTable2.HashTable oHt;
algorithm
  oHt := match(elseenqs,iHt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      DAE.ElementSource source;
      HashTable2.HashTable ht;
      list<BackendDAE.Equation> rest;
    case ({},_)
      then
        iHt;
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e)::rest,_)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCref(e, cr);
        ht = BaseHashTable.add((cr,e), iHt);
      then
        simplifySolvedIfEqnsElse(rest,ht);
    case (BackendDAE.EQUATION(exp=DAE.UNARY(operator=DAE.UMINUS(), exp=DAE.CREF(componentRef=cr)), scalar=e)::rest,_)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCref(e, cr);
        e = Expression.negate(e);
        ht = BaseHashTable.add((cr,e), iHt);
      then
        simplifySolvedIfEqnsElse(rest,ht);
  end match;
end simplifySolvedIfEqnsElse;

protected function simplifyIfEquationAsserts
"author: Frenkel TUD 2012-07
  helper for simplifyIfEquations"
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> theneqns;
  input list<BackendDAE.Equation> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<BackendDAE.Equation>> theneqns1;
  input list<BackendDAE.Equation> inEqns;
  output list<list<BackendDAE.Equation>> otheneqns;
  output list<BackendDAE.Equation> oelseenqs;
  output list<BackendDAE.Equation> outEqns;
algorithm
  (otheneqns,oelseenqs,outEqns) := match(conditions,theneqns,elseenqs,conditions1,theneqns1,inEqns)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqns,eqns1,beqns;
      list<list<BackendDAE.Equation>> eqnslst,eqnslst1;

    case (_,{},_,_,_,_)
      equation
        (beqns,eqns) = simplifyIfEquationAsserts1(elseenqs,NONE(),conditions1,{},inEqns);
      then
        (listReverse(theneqns1),beqns,eqns);
    case (e::explst,eqns::eqnslst,_,_,_,_)
      equation
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,SOME(e),conditions1,{},inEqns);
        (eqnslst1,eqns1,eqns) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs,e::conditions1,beqns::theneqns1,eqns);
      then
        (eqnslst1,eqns1,eqns);
  end match;
end simplifyIfEquationAsserts;

protected function simplifyIfEquationAsserts1
"author: Frenkel TUD 2012-07
  helper for simplifyIfEquationAsserts"
  input list<BackendDAE.Equation> brancheqns;
  input Option<DAE.Exp> condition;
  input list<DAE.Exp> conditions "reversed";
  input list<BackendDAE.Equation> brancheqns1;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> obrancheqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  (obrancheqns,outEqns) := match(brancheqns,condition,conditions,brancheqns1,inEqns)
    local
      DAE.Exp e,cond,msg,level;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns,beqns;
      Integer size;
      DAE.ElementSource source,source1;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes eqAttr;

    case ({},_,_,_,_)
      then
        (listReverse(brancheqns1),inEqns);

    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond=cond,msg=msg,level=level,source=source1)}),source=source,expand=crefExpand,attr=eqAttr)::eqns,NONE(),_,_,_)
      equation
        e = List.fold(conditions,makeIfExp,cond);
        (beqns,eqns) =  simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(e,msg,level,source1)}),source,crefExpand,eqAttr)::inEqns);
      then
        (beqns,eqns);

    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond=cond,msg=msg,level=level,source=source1)}),source=source,expand=crefExpand,attr=eqAttr)::eqns,SOME(e),_,_,_)
      equation
        e = DAE.IFEXP(e,cond,DAE.BCONST(true));
        e = List.fold(conditions,makeIfExp,e);
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(e,msg,level,source1)}),source,crefExpand,eqAttr)::inEqns);
      then
        (beqns,eqns);

    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg=msg,source=source1)}),source=source,expand=crefExpand,attr=eqAttr)::eqns,NONE(),_,_,_)
      equation
        e = List.fold(conditions,makeIfExp,DAE.BCONST(true));
        (beqns,eqns) =  simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_IF(e,{DAE.STMT_TERMINATE(msg,source1)},DAE.NOELSE(),source1)}),source,crefExpand,eqAttr)::inEqns);
      then
        (beqns,eqns);

    case (BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg=msg,source=source1)}),source=source,expand=crefExpand,attr=eqAttr)::eqns,SOME(e),_,_,_)
      equation
        e = List.fold(conditions,makeIfExp,e);
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,condition,conditions,brancheqns1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS({DAE.STMT_IF(e,{DAE.STMT_TERMINATE(msg,source1)},DAE.NOELSE(),source1)}),source,crefExpand,eqAttr)::inEqns);
      then
        (beqns,eqns);

    case (eqn::eqns,_,_,_,_)
      equation
        (beqns,eqns) = simplifyIfEquationAsserts1(eqns,condition,conditions,eqn::brancheqns1,inEqns);
      then
        (beqns,eqns);
  end match;
end simplifyIfEquationAsserts1;

protected function makeIfExp
  input DAE.Exp cond;
  input DAE.Exp else_;
  output DAE.Exp oExp;
algorithm
  oExp := DAE.IFEXP(cond,DAE.BCONST(true),else_);
end makeIfExp;

protected function countEquationsInBranches "
Checks that the number of equations is the same in all branches
of an if-equation"
  input list<list<BackendDAE.Equation>> trueBranches;
  input list<BackendDAE.Equation> falseBranch;
  input DAE.ElementSource source;
  output Integer nrOfEquations;
algorithm
  nrOfEquations := matchcontinue(trueBranches,falseBranch,source)
    local
      list<Boolean> b;
      list<String> strs;
      String str,eqstr;
      list<Integer> nrOfEquationsBranches;

    case (_, _, _)
      equation
        nrOfEquations = BackendEquation.equationLstSize(falseBranch);
        nrOfEquationsBranches = List.map(trueBranches, BackendEquation.equationLstSize);
        b = List.map1(nrOfEquationsBranches, intEq, nrOfEquations);
        true = List.reduce(b,boolAnd);
      then
        nrOfEquations;

    // An if-equation with non-parameter conditions must have an else-clause.
    case (_, {}, _)
      equation
        Error.addSourceMessage(Error.IF_EQUATION_MISSING_ELSE, {},
          DAEUtil.getElementSourceFileInfo(source));
      then
        fail();

    // If if-equation with non-parameter conditions must have the same number of
    // equations in each branch.
    case (_, _ :: _, _)
      equation
        nrOfEquations = BackendEquation.equationLstSize(falseBranch);
        nrOfEquationsBranches = List.map(trueBranches, BackendEquation.equationLstSize);
        eqstr = stringDelimitList(List.map(listAppend(trueBranches,{falseBranch}),BackendDump.dumpEqnsStr),"\n");
        strs = List.map(nrOfEquationsBranches, intString);
        str = stringDelimitList(strs,",");
        str = "{" + str + "," + intString(nrOfEquations) + "}";
        Error.addSourceMessage(Error.IF_EQUATION_UNBALANCED_2,{str,eqstr},DAEUtil.getElementSourceFileInfo(source));
      then
        fail();

  end matchcontinue;
end countEquationsInBranches;

protected function makeEquationLstToResidualExpLst
  input list<BackendDAE.Equation> eqLst;
  output list<DAE.Exp> oExpLst;
algorithm
  oExpLst := matchcontinue(eqLst)
    local
      list<BackendDAE.Equation> rest;
      list<DAE.Exp> exps1,exps2,exps;
      BackendDAE.Equation eq;
      DAE.ElementSource source;
      String str;
    case ({}) then {};
    case ((eq as BackendDAE.ALGORITHM(source = source))::rest)
      equation
        str = BackendDump.equationString(eq);
        str = Util.stringReplaceChar(str,"\n","");
        Error.addSourceMessage(Error.IF_EQUATION_WARNING,{str},DAEUtil.getElementSourceFileInfo(source));
        exps = makeEquationLstToResidualExpLst(rest);
      then exps;
    case (eq::rest)
      equation
        exps1 = makeEquationToResidualExpLst(eq);
        exps2 = makeEquationLstToResidualExpLst(rest);
        exps = listAppend(exps1,exps2);
      then
        exps;
  end matchcontinue;
end makeEquationLstToResidualExpLst;

protected function makeEquationToResidualExpLst "
If-equations with more than 1 equation in each branch cannot be transformed
to a single equation with residual if-expression. This function translates such
equations to a list of residual if-expressions. Normal equations are translated
to a list with a single residual expression."
  input BackendDAE.Equation eq;
  output list<DAE.Exp> oExpLst;
algorithm
  oExpLst := matchcontinue(eq)
    local
      list<list<BackendDAE.Equation>> tbs;
      list<BackendDAE.Equation> fbs;
      list<DAE.Exp> conds, fbsExp,exps;
      list<list<DAE.Exp>> tbsExp;
      BackendDAE.Equation elt;
      DAE.Exp exp;

    case (BackendDAE.IF_EQUATION(conditions=conds,eqnstrue=tbs,eqnsfalse=fbs))
      equation
        fbsExp = makeEquationLstToResidualExpLst(fbs);
        tbsExp = List.map(tbs, makeEquationLstToResidualExpLst);
        exps = makeResidualIfExpLst(conds,tbsExp,fbsExp);
      then
        exps;
    case (elt)
      equation
        exp=makeEquationToResidualExp(elt);
      then
        {exp};
  end matchcontinue;
end makeEquationToResidualExpLst;

protected function makeResidualIfExpLst
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Exp>> inExpLst2;
  input list<DAE.Exp> inExpLst3;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match (inExp1,inExpLst2,inExpLst3)
    local
      list<list<DAE.Exp>> tbs,tbsRest;
      list<DAE.Exp> tbsFirst,fbs,rest_res;
      list<DAE.Exp> conds;
      DAE.Exp ifexp,fb;

    case (_,tbs,{})
      equation
        List.map_0(tbs, List.assertIsEmpty);
      then {};

    case (conds,tbs,fb::fbs)
      equation
        tbsRest = List.map(tbs,List.rest);
        rest_res = makeResidualIfExpLst(conds, tbsRest, fbs);

        tbsFirst = List.map(tbs,listHead);

        ifexp = Expression.makeNestedIf(conds,tbsFirst,fb);
      then
        (ifexp :: rest_res);
  end match;
end makeResidualIfExpLst;

public function makeEquationToResidualExp ""
  input BackendDAE.Equation eq;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(eq)
    local
      DAE.Exp e1,e2, e;
      list<DAE.Exp> expl, expl1;
      DAE.ComponentRef cr1;
      String str;
      DAE.Type ty;
      Integer idx;
      list<Integer> idxs;
    // normal equation
    case(BackendDAE.EQUATION(exp=e1,scalar=e2))
      equation
        ty = Expression.typeof(e1);
        true = Types.isIntegerOrRealOrSubTypeOfEither(ty);
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // equation from array TODO! check if this works!
    case(BackendDAE.ARRAY_EQUATION(left=e1,right=e2))
      equation
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // solved equation
    case(BackendDAE.SOLVED_EQUATION(componentRef=cr1, exp=e2))
      equation
        e1 = Expression.crefExp(cr1);
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // residual equation
    case(BackendDAE.RESIDUAL_EQUATION(exp = oExp))
      then
        oExp;
    // complex equation
    // (x,_) = f(.)
    case(BackendDAE.COMPLEX_EQUATION(left = e1 as DAE.TUPLE(expl), right = e2))
      algorithm
        expl1 := {};
        idxs := {};
        idx := 1;
        for elem in expl loop
          if Expression.isNotWild(elem) then
            idxs := idx :: idxs;
            expl1 := elem :: expl1;
          end if;
          idx := idx + 1;
        end for;
        {e} :=  expl1;
        {idx} := idxs;
        oExp := Expression.expSub(e, DAE.TSUB(e2,idx,Expression.typeof(e)));
        //print("\n" + ExpressionDump.dumpExpStr(oExp,0));
      then oExp;
    case(BackendDAE.COMPLEX_EQUATION(left = e1, right = e2))
      equation
        oExp = Expression.expSub(e1,e2);
      then
        oExp;
    // failure
    case _
      equation
        str = "- BackendDAEOptimize.makeEquationToResidualExp failed to transform equation: " + BackendDump.equationString(eq) + " to residual form!";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end makeEquationToResidualExp;

protected function makeEquationsFromResiduals
  input list<DAE.Exp> inExp1 "conds";
  input list<list<DAE.Exp>> inExpLst2 "tbs";
  input list<DAE.Exp> inExpLst3;
  input DAE.ElementSource inSource "the origin of the element";
  input BackendDAE.EquationAttributes inEqAttr;
  output list<BackendDAE.Equation> outExpLst;
algorithm
  outExpLst := match (inExp1, inExpLst2, inExpLst3, inSource, inEqAttr)
    local
      list<list<DAE.Exp>> tbsRest;
      list<DAE.Exp> tbsFirst, fbs;
      DAE.Exp ifexp, fb;
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> rest_res;

    case (_, _, {}, _, _)
      equation
        List.map_0(inExpLst2, List.assertIsEmpty);
      then {};

    case (_, _, fb::fbs, _, _)
      equation
        tbsRest = List.map(inExpLst2, List.rest);
        rest_res = makeEquationsFromResiduals(inExp1, tbsRest, fbs, inSource, inEqAttr);

        tbsFirst = List.map(inExpLst2, listHead);

        ifexp = Expression.makeNestedIf(inExp1,tbsFirst,fb);
        eq = BackendDAE.EQUATION(DAE.RCONST(0.0), ifexp, inSource, inEqAttr);
      then (eq::rest_res);
  end match;
end makeEquationsFromResiduals;


// =============================================================================
// simplify semiLinear calls
//
// =============================================================================

public function simplifysemiLinear "author: Frenkel TUD 2012-08
  This function traveres all equations and tries to simplify calls to semiLinear"
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem(dae,simplifysemiLinearWork);
end simplifysemiLinear;

protected function simplifysemiLinearWork "author: Frenkel TUD 2012-08
  This function traveres all equations and tries to simplify calls to semiLinear"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := matchcontinue isyst
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<tuple<BackendDAE.Equation,Integer>> eqnslst;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
      BackendDAE.EqSystem syst;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case syst as BackendDAE.EQSYSTEM(orderedEqs=eqns)
      algorithm
        // traverse the equations and collect all semiLinear calls  y=semiLinear(x,sa,sb)
        (eqns, (eqnslst,_,true)) := BackendEquation.traverseEquationArray_WithUpdate(eqns,simplifysemiLinearFinder,({},0,false));
        // sort for (y,x) pairs
        eqnsarray := semiLinearSort(eqnslst, HashTableExpToIndex.emptyHashTable(), 1, arrayCreate(5, {}));
        eqnsarray := semiLinearSort1(arrayList(eqnsarray), 1, arrayCreate(5, {}));
        // optimize
        // y = semiLinear(x,sa,s1)
        // y = semiLinear(x,s1,s2)
        // y = semiLinear(x,s2,s3)
        // ...
        // y = semiLinear(x,sn,sb)
        // ->
        // s1 = if (x>=0) then sa else sb
        // s2 = s1
        // s3 = s2
        // ..
        // sn = sn-1
        // y = semiLinear(x,sa,sb)
        eqnslst := List.fold(arrayList(eqnsarray), semiLinearOptimize, {});
        // replace the equations in the system
        syst.orderedEqs := List.fold(eqnslst, semiLinearReplaceEqns, eqns);
      then (BackendDAEUtil.clearEqSyst(syst), ishared);

    else
      then (isyst,ishared);
  end matchcontinue;
end simplifysemiLinearWork;

protected function semiLinearReplaceEqns "author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input tuple<BackendDAE.Equation, Integer /*zero-based*/> iTpl;
  input BackendDAE.EquationArray iEqns;
  output BackendDAE.EquationArray oEqns;
protected
  BackendDAE.Equation eqn;
  Integer index;
algorithm
  (eqn, index) := iTpl;
  if Flags.isSet(Flags.SEMILINEAR) then
    BackendDump.debugStrEqnStr("Replace with ", eqn, "\n");
  end if;
  oEqns := BackendEquation.setAtIndex(iEqns, index+1, eqn);
end semiLinearReplaceEqns;

protected function semiLinearOptimize
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input list<tuple<BackendDAE.Equation,Integer>> iAcc;
  output list<tuple<BackendDAE.Equation,Integer>> oAcc;
algorithm
  oAcc := matchcontinue(eqnslst,iAcc)
    local
      HashTableExpToIndex.HashTable ht,ht1;
      array<tuple<BackendDAE.Equation,Integer>> eqnsarray;
      list<DAE.Exp> explst;
    case (_::{},_) then iAcc;
    case (_,_)
      equation
        // get HashMab sa-> index
        ht = HashTableExpToIndex.emptyHashTable();
        ht1 = HashTableExpToIndex.emptyHashTable();
        (ht,ht1) = semiLinearOptimize1(eqnslst,1,ht,ht1);
        // get sa
        explst = List.fold1(BaseHashTable.hashTableKeyList(ht),semiLinearGetSA,ht1,{});
        eqnsarray = listArray(eqnslst);
        // optimize
      then
        semiLinearOptimize2(explst,ht,eqnsarray,iAcc);
    case(_,_) then iAcc;
  end matchcontinue;
end semiLinearOptimize;

protected function semiLinearOptimize2
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<DAE.Exp> saLst;
  input HashTableExpToIndex.HashTable iHt;
  input array<tuple<BackendDAE.Equation,Integer>> IEqnsarray;
  input list<tuple<BackendDAE.Equation,Integer>> iAcc;
  output list<tuple<BackendDAE.Equation,Integer>> oAcc;
algorithm
  oAcc := matchcontinue(saLst,iHt,IEqnsarray,iAcc)
    local
      DAE.Exp sa,sb,s1,y,x;
      list<DAE.Exp> rest;
      list<tuple<DAE.Exp,Integer,DAE.ElementSource>> explst;
      list<tuple<BackendDAE.Equation,Integer>> acc;
      BackendDAE.Equation eqn,eqn1;
      Integer i1,index,index1;
      Absyn.Path path;
      DAE.CallAttributes attr;
      DAE.ElementSource source,source1;
      BackendDAE.EquationAttributes eqAttr;
    case ({},_,_,_) then iAcc;
    case (sa::rest,_,_,_)
      equation
        i1 = BaseHashTable.get(sa,iHt);
        ((BackendDAE.EQUATION(exp=y,scalar=DAE.CALL(path=path,expLst = {x,_,s1},attr=attr),source=source,attr=eqAttr),index)) = IEqnsarray[i1];
        // get Order of s1,s2,s3,..,sn,sb
        (sb,source1,index1,explst) = semiLinearOptimize3(s1,source,index,iHt,IEqnsarray,{});
        // generate optimized equations
        // s1 = if (x>=0) then sa else sb
        // s2 = s1
        // ..
        // sn = sn-1
        // y = semiLinear(x,sa,sb)
        eqn = BackendDAE.EQUATION(s1,DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(x,DAE.GREATEREQ(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE())},DAE.callAttrBuiltinBool),sa,sb),source,eqAttr);
        eqn1 = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source1,eqAttr);
        acc = semiLinearOptimize4(explst,(eqn1,index1)::iAcc, eqAttr);
      then
        semiLinearOptimize2(rest,iHt,IEqnsarray,(eqn,index)::acc);
    case (_::rest,_,_,_)
      then
        semiLinearOptimize2(rest,iHt,IEqnsarray,iAcc);
  end matchcontinue;
end semiLinearOptimize2;

protected function semiLinearOptimize4
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<tuple<DAE.Exp,Integer,DAE.ElementSource>> explst;
  input list<tuple<BackendDAE.Equation,Integer>> iAcc;
  input BackendDAE.EquationAttributes inEqAttr;
  output list<tuple<BackendDAE.Equation,Integer>> oAcc;
algorithm
  oAcc := match(explst, iAcc, inEqAttr)
    local
      DAE.Exp s1,s2;
      list<tuple<DAE.Exp,Integer,DAE.ElementSource>> rest;
      Integer index;
      BackendDAE.Equation eqn;
      DAE.ElementSource source;
    case ({}, _, _) then iAcc;
    case (_::{}, _, _) then iAcc;
    case((s2,index,source)::(rest as ((s1,_,_)::_)), _, _)
      equation
        eqn = BackendDAE.EQUATION(s2, s1, source, inEqAttr);
      then
        semiLinearOptimize4(rest, (eqn, index)::iAcc, inEqAttr);
  end match;
end semiLinearOptimize4;

protected function semiLinearOptimize3
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input DAE.Exp exp;
  input DAE.ElementSource isource;
  input Integer iIndex;
  input HashTableExpToIndex.HashTable iHt;
  input array<tuple<BackendDAE.Equation,Integer>> IEqnsarray;
  input list<tuple<DAE.Exp,Integer,DAE.ElementSource>> iAcc;
  output DAE.Exp slast;
  output DAE.ElementSource osource;
  output Integer oIndex;
  output list<tuple<DAE.Exp,Integer,DAE.ElementSource>> oAcc;
algorithm
  (slast,osource,oIndex,oAcc) := matchcontinue(exp,isource,iIndex,iHt,IEqnsarray,iAcc)
    local
      DAE.Exp sb;
      Integer i,index;
      DAE.ElementSource source;
    case(_,_,_,_,_,_)
      equation
        i = BaseHashTable.get(exp,iHt);
        ((BackendDAE.EQUATION(scalar=DAE.CALL(expLst = {_,_,sb}),source=source),index)) = IEqnsarray[i];
        (sb,source,index,oAcc) = semiLinearOptimize3(sb,source,index,iHt,IEqnsarray,(exp,iIndex,source)::iAcc);
      then
        (sb,source,index,oAcc);
    case(_,_,_,_,_,_)
      then
        (exp,isource,iIndex,iAcc);
  end matchcontinue;
end semiLinearOptimize3;

protected function semiLinearGetSA
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input DAE.Exp key;
  input HashTableExpToIndex.HashTable iHt1;
  input list<DAE.Exp> iAcc;
  output list<DAE.Exp> oAcc;
algorithm
  oAcc := matchcontinue(key,iHt1,iAcc)
    case (_,_,_)
      equation
        _ = BaseHashTable.get(key,iHt1);
      then
        iAcc;
    case(_,_,_)
      then
        key::iAcc;
  end matchcontinue;
end semiLinearGetSA;

protected function semiLinearOptimize1
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input Integer i;
  input HashTableExpToIndex.HashTable iHt;
  input HashTableExpToIndex.HashTable iHt1;
  output HashTableExpToIndex.HashTable oHt;
  output HashTableExpToIndex.HashTable oHt1;
algorithm
  (oHt,oHt1) := match(eqnslst,i,iHt,iHt1)
    local
     BackendDAE.Equation eqn;
      list<tuple<BackendDAE.Equation,Integer>> rest;
      HashTableExpToIndex.HashTable ht,ht1;
      DAE.Exp sa,sb;
    case ({},_,_,_) then (iHt,iHt1);
    case ((BackendDAE.EQUATION(scalar=DAE.CALL(expLst = {_,sa,sb})),_)::rest,_,_,_)
      equation
        ht = BaseHashTable.add((sa,i), iHt);
        ht1 = BaseHashTable.add((sb,i), iHt1);
        (ht,ht1) = semiLinearOptimize1(rest,i+1,ht,ht1);
      then
        (ht,ht1);
  end match;
end semiLinearOptimize1;

protected function semiLinearSort "author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input  list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input  HashTableExpToIndex.HashTable iHt;
  input  Integer size;
  input  array<list<tuple<BackendDAE.Equation,Integer>>> iEqnsarray;
  output  array<list<tuple<BackendDAE.Equation,Integer>>> oEqnsarray;
algorithm
  oEqnsarray := matchcontinue(eqnslst,iHt,size,iEqnsarray)
    local
     BackendDAE.Equation eqn;
     Integer index,i;
     list<tuple<BackendDAE.Equation,Integer>> rest,eqns;
     HashTableExpToIndex.HashTable ht;
     DAE.Exp y;
     array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
    case ({},_,_,_) then iEqnsarray;
    case ((eqn as BackendDAE.EQUATION(exp=y),index)::rest,_,_,_)
      equation
        i = BaseHashTable.get(y,iHt);
        eqns = iEqnsarray[i];
        eqnsarray = arrayUpdate(iEqnsarray,i,(eqn,index)::eqns);
      then
        semiLinearSort(rest,iHt,size,eqnsarray);
    case ((eqn as BackendDAE.EQUATION(exp=y),index)::rest,_,_,_)
      equation
        ht = BaseHashTable.add((y,size), iHt);
        // expand if necesarray
        eqnsarray = if intGt(size,arrayLength(iEqnsarray)) then Array.expand(5, iEqnsarray, {}) else iEqnsarray;
        eqnsarray = arrayUpdate(eqnsarray,size,{(eqn,index)});
      then
        semiLinearSort(rest,ht,size+1,eqnsarray);
  end matchcontinue;
end semiLinearSort;

protected function semiLinearSort1
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input  list<list<tuple<BackendDAE.Equation,Integer>>> eqnslstlst;
  input  Integer size;
  input  array<list<tuple<BackendDAE.Equation,Integer>>> iEqnsarray;
  output  array<list<tuple<BackendDAE.Equation,Integer>>> oEqnsarray;
algorithm
  oEqnsarray := match(eqnslstlst,size,iEqnsarray)
    local
     Integer size1;
     tuple<BackendDAE.Equation,Integer> tpl;
     list<tuple<BackendDAE.Equation,Integer>> eqns;
     list<list<tuple<BackendDAE.Equation,Integer>>> rest;
     HashTableExpToIndex.HashTable ht;
     array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
    case ({},_,_) then iEqnsarray;
    case ((tpl::{})::rest,_,_)
      equation
        // expand if necesarray
        eqnsarray = if intGt(size,arrayLength(iEqnsarray)) then Array.expand(5, iEqnsarray, {}) else iEqnsarray;
        eqnsarray = arrayUpdate(eqnsarray,size,{tpl});
      then
        semiLinearSort1(rest,size+1,eqnsarray);
    case (eqns::rest,_,_)
      equation
        ht = HashTableExpToIndex.emptyHashTable();
        (size1,eqnsarray) = semiLinearSort2(eqns,ht,size,iEqnsarray);
      then
        semiLinearSort1(rest,size1,eqnsarray);
  end match;
end semiLinearSort1;

protected function semiLinearSort2
"author: Frenkel TUD 2012-08
  helper for simplifysemiLinear"
  input  list<tuple<BackendDAE.Equation,Integer>> eqnslst;
  input  HashTableExpToIndex.HashTable iHt;
  input  Integer size;
  input  array<list<tuple<BackendDAE.Equation,Integer>>> iEqnsarray;
  output  Integer osize;
  output  array<list<tuple<BackendDAE.Equation,Integer>>> oEqnsarray;
algorithm
  (osize,oEqnsarray) := matchcontinue(eqnslst,iHt,size,iEqnsarray)
    local
     BackendDAE.Equation eqn;
     Integer index,i;
     list<tuple<BackendDAE.Equation,Integer>> rest,eqns;
     HashTableExpToIndex.HashTable ht;
     DAE.Exp x;
     array<list<tuple<BackendDAE.Equation,Integer>>> eqnsarray;
    case ({},_,_,_) then (size,iEqnsarray);
    case ((eqn as BackendDAE.EQUATION(scalar=DAE.CALL(expLst = x::_)),index)::rest,_,_,_)
      equation
        i = BaseHashTable.get(x,iHt);
        eqns = iEqnsarray[i];
        eqnsarray = arrayUpdate(iEqnsarray,i,(eqn,index)::eqns);
        (i,eqnsarray) = semiLinearSort2(rest,iHt,size,eqnsarray);
      then
        (i,eqnsarray);
    case ((eqn as BackendDAE.EQUATION(scalar=DAE.CALL(expLst = x::_)),index)::rest,_,_,_)
      equation
        ht = BaseHashTable.add((x,size), iHt);
        // expand if necesarray
        eqnsarray = if intGt(size,arrayLength(iEqnsarray)) then Array.expand(5, iEqnsarray, {}) else iEqnsarray;
        eqnsarray = arrayUpdate(eqnsarray,size,{(eqn,index)});
        (i,eqnsarray) = semiLinearSort2(rest,ht,size+1,eqnsarray);
      then
        (i,eqnsarray);
  end matchcontinue;
end semiLinearSort2;

protected function simplifysemiLinearFinder
"helper for simplifysemiLinear"
  input BackendDAE.Equation inEq;
  input tuple<list<tuple<BackendDAE.Equation,Integer>>,Integer,Boolean> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<list<tuple<BackendDAE.Equation,Integer>>,Integer,Boolean> outTpl;
algorithm
  (outEq,outTpl) := matchcontinue (inEq,inTpl)
    local
      BackendDAE.Equation eqn;
      list<tuple<BackendDAE.Equation,Integer>> eqnslst;
      Integer index;
      Boolean b;
      DAE.Exp x,y,sa,sb;
      DAE.ElementSource source;
      Absyn.Path path;
      DAE.CallAttributes attr;
      BackendDAE.EquationAttributes eqAttr;

    // 0 = semiLinear(0,sa,sb) -> sa=sb
    case (BackendDAE.EQUATION(exp=y,scalar=DAE.CALL(path=Absyn.IDENT("semiLinear"),expLst={x,sa,sb}),source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then (BackendDAE.EQUATION(sa,sb,source,eqAttr),(eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=DAE.CALL(path=Absyn.IDENT("semiLinear"),expLst={x,sa,sb}),scalar=y,source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then (BackendDAE.EQUATION(sa,sb,source,eqAttr),(eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=y,scalar=DAE.UNARY(exp=DAE.CALL(path=Absyn.IDENT("semiLinear"),expLst={x,sa,sb})),source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then (BackendDAE.EQUATION(sa,sb,source,eqAttr),(eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=DAE.UNARY(exp=DAE.CALL(path=Absyn.IDENT("semiLinear"),expLst={x,sa,sb})),scalar=y,source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        true = Expression.isZero(y);
        true = Expression.isZero(x);
      then (BackendDAE.EQUATION(sa,sb,source,eqAttr),(eqnslst,index+1,true));
    // y = -semiLinear(-x,sb,sa) -> y = semiLinear(x,sa,sb)
    case (BackendDAE.EQUATION(exp=y,scalar=DAE.UNARY(exp=DAE.CALL(path=path as Absyn.IDENT("semiLinear"),expLst={DAE.UNARY(exp=x),sb,sa},attr=attr)),source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=DAE.UNARY(exp=DAE.CALL(path=path as Absyn.IDENT("semiLinear"),expLst={DAE.UNARY(exp=x),sb,sa},attr=attr)),scalar=y,source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    // -y = semiLinear(-x,sb,sa) -> y = semiLinear(x,sa,sb)
    case (BackendDAE.EQUATION(exp=DAE.UNARY(exp=y),scalar=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),scalar=DAE.UNARY(exp=y),source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    // y = semiLinear(-x,sb,sa) -> -y = semiLinear(x,sa,sb)
    case (BackendDAE.EQUATION(exp=y,scalar=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=DAE.CALL(path = path as Absyn.IDENT("semiLinear"), expLst = {DAE.UNARY(exp=x),sb,sa},attr=attr),scalar=y,source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,DAE.CALL(path,{x,sa,sb},attr),source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    // y = semiLinear(x,sa,sb)
    case (eqn as BackendDAE.EQUATION(scalar=DAE.CALL(path =Absyn.IDENT("semiLinear"))),(eqnslst,index,_))
      equation
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    case (eqn as BackendDAE.EQUATION(exp=DAE.CALL(path =Absyn.IDENT("semiLinear"))),(eqnslst,index,_))
      equation
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=y,scalar=DAE.UNARY(exp= x as DAE.CALL(path = Absyn.IDENT("semiLinear"))),source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,x,source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));
    case (BackendDAE.EQUATION(exp=DAE.UNARY(exp= x as DAE.CALL(path = Absyn.IDENT("semiLinear"))),scalar=y,source=source,attr=eqAttr),(eqnslst,index,_))
      equation
        y = Expression.negate(y);
        eqn = BackendDAE.EQUATION(y,x,source,eqAttr);
        if Flags.isSet(Flags.SEMILINEAR) then
          BackendDump.debugStrEqnStr("Found semiLinear ",eqn,"\n");
        end if;
      then (eqn,((eqn,index)::eqnslst,index+1,true));

    case (eqn,(eqnslst,index,b)) then (eqn,(eqnslst,index+1,b));
  end matchcontinue;
end simplifysemiLinearFinder;

// =============================================================================
// remove constants stuff
//
// =============================================================================

public function removeConstants "author: Frenkel TUD"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match inDAE
    local
      BackendDAE.Variables knvars;
      BackendDAE.EquationArray inieqns, remeqns;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> lsteqns;
      Boolean b;
    case BackendDAE.DAE(systs, shared as BackendDAE.SHARED(knownVars=knvars, initialEqs=inieqns))
      algorithm
        repl := BackendVarTransform.emptyReplacements();
        repl := BackendVariable.traverseBackendDAEVars(knvars, removeConstantsFinder, repl);
        if Flags.isSet(Flags.DUMP_CONST_REPL) then
          BackendVarTransform.dumpReplacements(repl);
        end if;

        (knvars, (repl, _)) := BackendVariable.traverseBackendDAEVarsWithUpdate(knvars, replaceFinalVarTraverser, (repl, 0));

        lsteqns := BackendEquation.equationList(shared.initialEqs);
        (lsteqns, b) := BackendVarTransform.replaceEquations(lsteqns, repl, NONE());
        shared.initialEqs := if b then BackendEquation.listEquation(lsteqns) else shared.initialEqs;

        lsteqns := BackendEquation.equationList(shared.removedEqs);
        (lsteqns, b) := BackendVarTransform.replaceEquations(lsteqns, repl, NONE());
        shared.removedEqs := if b then BackendEquation.listEquation(lsteqns) else shared.removedEqs;


        systs := List.map1(systs, removeConstantsWork, repl);

      then BackendDAE.DAE(systs, shared);
  end match;
end removeConstants;

protected function removeConstantsWork "author: Frenkel TUD"
  input BackendDAE.EqSystem inEqSystem;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.EqSystem outEqSystem;
algorithm
  outEqSystem := match inEqSystem
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> lsteqns;
      Boolean b;
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      algorithm
        BackendVariable.traverseBackendDAEVarsWithUpdate(vars, replaceFinalVarTraverser, (repl, 0));

        (lsteqns, b) := BackendVarTransform.replaceEquations(BackendEquation.equationList(syst.orderedEqs), repl, NONE());
        if b then
          syst.orderedEqs := BackendEquation.listEquation(lsteqns);
          syst := BackendDAEUtil.clearEqSyst(syst);
        end if;

        (lsteqns, b) := BackendVarTransform.replaceEquations(BackendEquation.equationList(syst.removedEqs), repl, NONE());
        if b then
          syst.removedEqs := BackendEquation.listEquation(lsteqns);
        end if;

      then syst;
  end match;
end removeConstantsWork;

protected function removeConstantsFinder
  input BackendDAE.Var inVar;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Var outVar;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  (outVar,outRepl) := matchcontinue (inVar,inRepl)
    local
      BackendDAE.Var v;
      BackendVarTransform.VariableReplacements repl, repl_1;
      DAE.ComponentRef varName;
      DAE.Exp exp;

    case (v as BackendDAE.VAR(varName=varName, varKind=BackendDAE.CONST(), bindExp=SOME(exp)), repl)
      equation
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp, NONE());
      then (v, repl_1);

    else (inVar,inRepl);
  end matchcontinue;
end removeConstantsFinder;


// =============================================================================
// reaplace edge and change with (b and not pre(b)) and (v <> pre(v)
//
// =============================================================================

public function replaceEdgeChange "author: Frenkel TUD 2012-11
  edge(b) = b and not pre(b)
  change(b) = v <> pre(v)"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE, replaceEdgeChange0, false);
  outDAE := replaceEdgeChangeShared(outDAE);
end replaceEdgeChange;

protected function replaceEdgeChange0 "author: Frenkel TUD 2012-11"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared = inShared;
  output Boolean outChanged;
algorithm
  (osyst, outChanged) := matchcontinue isyst
    local
      BackendDAE.EquationArray orderedEqs, removedEqs;

    case BackendDAE.EQSYSTEM(orderedEqs=orderedEqs, removedEqs=removedEqs)
    algorithm
      BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(orderedEqs, traverserreplaceEdgeChange, false);
      BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(removedEqs, traverserreplaceEdgeChange, false);
    then (isyst, true);

    else (isyst, inChanged);
  end matchcontinue;
end replaceEdgeChange0;

protected function traverserreplaceEdgeChange "author: Frenkel TUD 2012-11"
  input DAE.Exp e;
  input Boolean b;
  output DAE.Exp oe;
  output Boolean ob;
algorithm
  (oe,ob) := Expression.traverseExpBottomUp(e,traverserExpreplaceEdgeChange,b);
end traverserreplaceEdgeChange;

protected function traverserExpreplaceEdgeChange "author: Frenkel TUD 2012-11"
  input DAE.Exp inExp;
  input Boolean inB;
  output DAE.Exp outExp;
  output Boolean outB;
algorithm
  (outExp,outB) := matchcontinue (inExp,inB)
    local
      DAE.Exp e;
      DAE.Type ty;

    // change(v) -> v <> pre(v)
    case (DAE.CALL(path=Absyn.IDENT(name = "change"), expLst={e}), _)
      equation
        ty = Expression.typeof(e);
      then (DAE.RELATION(e, DAE.NEQUAL(ty), DAE.CALL(Absyn.IDENT("pre"), {e}, DAE.CALL_ATTR(ty, false, true, false, false, DAE.NO_INLINE(), DAE.NO_TAIL())), -1, NONE()), true);

    // edge(b) = b and not pre(b)
    case (DAE.CALL(path=Absyn.IDENT(name = "edge"), expLst={e}), _)
      equation
        ty = Expression.typeof(e);
      then (DAE.LBINARY(e, DAE.AND(ty), DAE.LUNARY(DAE.NOT(ty), DAE.CALL(Absyn.IDENT("pre"), {e}, DAE.CALL_ATTR(ty, false, true, false, false, DAE.NO_INLINE(), DAE.NO_TAIL())))), true);

    else (inExp,inB);
  end matchcontinue;
end traverserExpreplaceEdgeChange;

protected function replaceEdgeChangeShared "author: Frenkel TUD 2012-11"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match inDAE
    local
      BackendDAE.EquationArray remeqns;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
    case BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=remeqns))
      algorithm
        BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(remeqns, traverserreplaceEdgeChange, false);
      then BackendDAE.DAE(systs, shared);
  end match;
end replaceEdgeChangeShared;

// =============================================================================
// section for postOptModule >>addInitialStmtsToAlgorithms<<
//
//   Real a[3];
// algorithm       -->  algorithm
//   a[1] := 1.0;         a[1] := $_start(a[1]);
//                        a[2] := $_start(a[2]);
//                        a[3] := $_start(a[3]);
//                        a[1] := 1.0;
// =============================================================================

public function addInitialStmtsToAlgorithms "
  section are executed in the order of appearance. Whenever an algorithm section is invoked, all variables appearing
  on the left hand side of the assignment operator := are initialized (at least conceptually):
    - A non-discrete variable is initialized with its start value (i.e. the value of the start-attribute).
    - A discrete variable v is initialized with pre(v)."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, addInitialStmtsToAlgorithms1);
end addInitialStmtsToAlgorithms;

protected function addInitialStmtsToAlgorithms1 "Helper function to addInitialStmtsToAlgorithms."
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst = syst;
  output BackendDAE.Shared oshared = shared;
protected
  BackendDAE.Variables ordvars;
  BackendDAE.EquationArray ordeqns;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=ordvars, orderedEqs=ordeqns) := osyst;
  BackendEquation.traverseEquationArray_WithUpdate(ordeqns, eaddInitialStmtsToAlgorithms1Helper, ordvars);
end addInitialStmtsToAlgorithms1;

protected function eaddInitialStmtsToAlgorithms1Helper "Helper function to addInitialStmtsToAlgorithms1."
  input BackendDAE.Equation inEq;
  input BackendDAE.Variables inVars;
  output BackendDAE.Equation outEq;
  output BackendDAE.Variables outVars;
algorithm
  (outEq,outVars) := match (inEq,inVars)
    local
      DAE.Algorithm alg;
      list<DAE.Statement> statements;
      BackendDAE.Equation eqn;
      BackendDAE.Variables vars;
      Integer size;
      list<DAE.Exp> outputs;
      DAE.ElementSource source;
      list<DAE.ComponentRef> crlst;
      DAE.Expand crExpand;
      BackendDAE.EquationAttributes attr;

    case (BackendDAE.ALGORITHM(size=size, alg=alg as DAE.ALGORITHM_STMTS(statements), source=source, expand=crExpand, attr=attr), vars)
      equation
        crlst = CheckModel.checkAndGetAlgorithmOutputs(alg, source, crExpand);
        outputs = List.map(crlst, Expression.crefExp);
        statements = expandAlgorithmStmts(statements, outputs, vars);
      then (BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(statements), source, crExpand, attr), vars);

    else (inEq,inVars);
  end match;
end eaddInitialStmtsToAlgorithms1Helper;

protected function expandAlgorithmStmts "Helper function to eaddInitialStmtsToAlgorithms1Helper."
  input list<DAE.Statement> inAlg;
  input list<DAE.Exp> inOutputs;
  input BackendDAE.Variables inVars;
  output list<DAE.Statement> outAlg;
algorithm
  outAlg := match(inAlg, inOutputs, inVars)
    local
      DAE.Exp out, initExp;
      list<DAE.Exp> rest;
      DAE.ComponentRef cref;
      BackendDAE.Var var;
      DAE.Statement stmt;
      DAE.Type type_;
      list<DAE.Statement> statements;
      Boolean b;

    case(statements, {}, _)
    then statements;

    case(statements, out::rest, _) equation
      cref = Expression.expCref(out);
      type_ = Expression.typeof(out);
      type_ = Expression.arrayEltType(type_);
      (var::_, _) = BackendVariable.getVar(cref, inVars);
      b = BackendVariable.isVarDiscrete(var);
      initExp = Expression.makePureBuiltinCall(if b then "pre" else "$_start", {out}, type_);
      stmt = Algorithm.makeAssignment(DAE.CREF(cref, type_), DAE.PROP(type_, DAE.C_VAR()), initExp, DAE.PROP(type_, DAE.C_VAR()), DAE.dummyAttrVar, SCode.NON_INITIAL(), DAE.emptyElementSource);
    then expandAlgorithmStmts(stmt::statements, rest, inVars);
  end match;
end expandAlgorithmStmts;


// =============================================================================
// section for expandDerOperator
//
// =============================================================================

public function expandDerOperator "
  Expands der(expr) using Derive.differentiteExpTime.
  This can not be done in Static, since we need all time-
  dependent variables, which is only available in BackendDAE."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, expandDerOperatorWork);
end expandDerOperator;

protected function expandDerOperatorWork "
  expands der(expr) using Derive.differentiteExpTime.
  This can not be done in Static, since we need all time-
  dependent variables, which is only available in BackendDAE."
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst, oshared) := match (inSyst, inShared)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns, remeqns, inieqns;
      BackendDAE.EqSystem syst;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), BackendDAE.SHARED(initialEqs=inieqns))
      algorithm
        (_, (vars, _)) :=
            BackendEquation.traverseEquationArray_WithUpdate(eqns, traverserexpandDerEquation, (vars, inShared));
        (_, (vars, _)) :=
            BackendEquation.traverseEquationArray_WithUpdate(inieqns, traverserexpandDerEquation, (vars, inShared));
        syst.orderedVars := vars;
      then (syst, inShared);
  end match;
end expandDerOperatorWork;

protected function traverserexpandDerEquation "
  Help function to e.g. traverserexpandDerEquation"
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.Variables, BackendDAE.Shared> tpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.Variables, BackendDAE.Shared> outTpl;
protected
   BackendDAE.Equation e, e1;
   tuple<BackendDAE.Variables, DAE.FunctionTree> ext_arg, ext_art1;
   BackendDAE.Variables vars;
   DAE.FunctionTree funcs;
   Boolean b;
   list<DAE.SymbolicOperation> ops;
   BackendDAE.Shared shared;
algorithm
  e := inEq;
  (vars, shared) := tpl;
  (e1, (vars, shared, ops)) := BackendEquation.traverseExpsOfEquation(e, traverserexpandDerExp, (vars, shared, {}));
  e1 := List.foldr(ops, BackendEquation.addOperation, e1);
  outEq := e1;
  outTpl := (vars, shared);
end traverserexpandDerEquation;

protected function traverserexpandDerExp "
  Help function to e.g. traverserexpandDerExp"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, BackendDAE.Shared, list<DAE.SymbolicOperation>> tpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, BackendDAE.Shared, list<DAE.SymbolicOperation>> outTpl;
protected
  DAE.Exp e, e1;
  tuple<BackendDAE.Variables, BackendDAE.Shared, Boolean> ext_arg;
  BackendDAE.Variables vars;
  list<DAE.SymbolicOperation> ops;
  DAE.FunctionTree funcs;
  Boolean b;
  BackendDAE.Shared shared;
algorithm
  e := inExp;
  (vars, shared, ops) := tpl;
  ext_arg := (vars, shared, false);
  (e1, ext_arg) := Expression.traverseExpBottomUp(e, expandDerExp, ext_arg);
  (vars, shared, b) := ext_arg;
  ops := List.consOnTrue(b, DAE.OP_DIFFERENTIATE(DAE.crefTime, e, e1), ops);
  outExp := e1;
  outTpl := (vars, shared, ops);
end traverserexpandDerExp;

protected function expandDerExp "
  Help function to e.g. expandDerOperatorEqn"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, BackendDAE.Shared, Boolean> itpl;
  output DAE.Exp e;
  output tuple<BackendDAE.Variables, BackendDAE.Shared, Boolean> tpl;
algorithm
  (e,tpl) := matchcontinue (inExp,itpl)
    local
      BackendDAE.Variables vars;
      DAE.Exp e1, e2;
      DAE.ComponentRef cr;
      String str;
      BackendDAE.Shared shared;
      list<BackendDAE.Var> varlst;
      BackendDAE.Var v;
      Boolean b;
      DAE.FunctionTree funcs;
    case (DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=cr)})}), (_, _, _))
      equation
        str = ComponentReference.crefStr(cr);
        str = stringAppendList({"The model includes derivatives of order > 1 for: ", str, ". That is not supported. Real d", str, " = der(", str, ") *might* result in a solvable model"});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
    // case for arrays
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(ty = DAE.T_ARRAY())}), (vars, shared as BackendDAE.SHARED(), b))
      equation
        (e2, true) = Expression.extendArrExp(e1, false);
        (e,tpl) = Expression.traverseExpBottomUp(e2, expandDerExp, (vars, shared, b));
      then (e,tpl);
    // case for records
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))}), (vars, shared as BackendDAE.SHARED(), b))
      equation
        (e2, true) = Expression.extendArrExp(e1, false);
        (e,tpl) = Expression.traverseExpBottomUp(e2, expandDerExp, (vars, shared, b));
      then (e,tpl);
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=cr)}), (vars, shared, _))
      equation
        ({v}, _) = BackendVariable.getVar(cr, vars);
        (vars, e1) = updateStatesVar(vars, v, e1);
      then (e1, (vars, shared, true));
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=cr)}), (vars, shared, _))
      equation
        (varlst, _) = BackendVariable.getVar(cr, vars);
        vars = updateStatesVars(vars, varlst, false);
      then (e1, (vars, shared, true));
    case (DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={e1}), (vars, shared, _))
      equation
        (e2, shared) = Differentiate.differentiateExpTime(e1, vars, shared);
        (e2, _) = ExpressionSimplify.simplify(e2);
        (_, vars) = Expression.traverseExpBottomUp(e2, derCrefsExp, vars);
      then (e2, (vars, shared, true));
    else (inExp,itpl);
  end matchcontinue;
end expandDerExp;

protected function derCrefsExp "helper for statesExp"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output DAE.Exp outExp;
  output BackendDAE.Variables outVars;
algorithm
  (outExp,outVars) := matchcontinue (inExp,inVars)
  local
    DAE.ComponentRef cr;
    BackendDAE.Variables vars;
    list<BackendDAE.Var> varlst;
    BackendDAE.Var v;
    DAE.Exp e;
    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}), vars)
    equation
      ({v}, _) = BackendVariable.getVar(cr, vars);
      (vars, e) = updateStatesVar(vars, v, e);
      then (e, vars);
    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}), vars)
    equation
      (varlst, _) = BackendVariable.getVar(cr, vars);
      vars = updateStatesVars(vars, varlst, false);
      then (e, vars);
    else (inExp,inVars);
end matchcontinue;
end derCrefsExp;

protected function updateStatesVar "
  Help function to expandDerExp"
  input BackendDAE.Variables inVars;
  input BackendDAE.Var var;
  input DAE.Exp iExp;
  output BackendDAE.Variables outVars;
  output DAE.Exp oExp;
algorithm
  (outVars, oExp) := matchcontinue(inVars, var, iExp)
    local
      BackendDAE.Variables vars;
      BackendDAE.Var var1;
    case(_, _, _)
      equation
        true = BackendVariable.isVarDiscrete(var) "do not change discrete vars to states, because they have no derivative" ;
      then (inVars, DAE.RCONST(0.0));
    case(_, _, _)
      equation
        false = BackendVariable.isVarDiscrete(var) "do not change discrete vars to states, because they have no derivative" ;
        false = BackendVariable.isStateVar(var);
        var1 = BackendVariable.setVarKind(var, BackendDAE.STATE(1,NONE()));
        vars = BackendVariable.addVar(var1, inVars);
      then (vars, iExp);
    case(_, _, _)
      equation
        /* Might be part of a different equation-system...
        str = "BackendDAECreate.updateStatesVars failed for: " + ComponentReference.printComponentRefStr(cr);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
        */
      then (inVars, iExp);
  end matchcontinue;
end updateStatesVar;

protected function updateStatesVars "
  Help function to expandDerExp"
  input BackendDAE.Variables inVars;
  input list<BackendDAE.Var> inNewStates;
  input Boolean noStateFound;
  output BackendDAE.Variables outVars;
algorithm
  outVars := matchcontinue(inVars, inNewStates, noStateFound)
    local
      BackendDAE.Var var;
      list<BackendDAE.Var> newStates;
      BackendDAE.Variables vars;
      //DAE.ComponentRef cr;
      //String str;

    case(_, {}, true) then inVars;
    case(_, var::newStates, _)
      equation
        false = BackendVariable.isVarDiscrete(var) "do not change discrete vars to states, because they have no derivative" ;
        false = BackendVariable.isStateVar(var);
        var = BackendVariable.setVarKind(var, BackendDAE.STATE(1,NONE()));
        vars = BackendVariable.addVar(var, inVars);
        vars = updateStatesVars(vars, newStates, true);
      then vars;
    case(_, _::newStates, _)
      equation
        /* Might be part of a different equation-system...
        str = "BackendDAECreate.updateStatesVars failed for: " + ComponentReference.printComponentRefStr(cr);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
        */
        vars = updateStatesVars(inVars, newStates, noStateFound);
      then vars;
  end matchcontinue;
end updateStatesVars;

// =============================================================================
// section for addedScaledVars
//
// =============================================================================

public function addedScaledVars
  "added var_norm = var/nominal, where var is state."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if Flags.isSet(Flags.ADD_SCALED_VARS) or Flags.isSet(Flags.ADD_SCALED_VARS_INPUT) then
    outDAE := addedScaledVarsWork(inDAE);
  else
    outDAE := inDAE;
  end if;
end addedScaledVars;

protected function addedScaledVarsWork
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systlst;
  list<BackendDAE.EqSystem> osystlst = {};
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  list<BackendDAE.Var> kvarlst, lst_states, lst_inputs;
  BackendDAE.Var tmpv;
  DAE.ComponentRef cref;
  DAE.Exp norm, y_norm, y, lhs;
  BackendDAE.Equation eqn;
  BackendDAE.Shared oshared;
  BackendDAE.EqSystem syst;
algorithm
  BackendDAE.DAE(systlst, oshared) := inDAE;
  kvarlst := BackendVariable.varList(oshared.knownVars);
  lst_inputs := List.select(kvarlst, BackendVariable.isVarOnTopLevelAndInputNoDerInput);
  // states
  if Flags.isSet(Flags.ADD_SCALED_VARS) then
    for syst in systlst loop
      syst := match syst
        local
          BackendDAE.EqSystem syst1;
        case syst1 as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
          algorithm
            // get vars
            lst_states := List.select(BackendVariable.varList(vars), BackendVariable.isStateVar);
            //BackendDump.printVarList(lst_states);
            for v in lst_states loop
              cref := BackendVariable.varCref(v);
              tmpv := BackendVariable.createVar(cref, "__OMC$scaled_state");
              y := Expression.crefExp(cref);
              norm := BackendVariable.getVarNominalValue(v);
              y_norm := Expression.expDiv(y,norm);
              (y_norm,_) := ExpressionSimplify.simplify(y_norm);
              // lhs
              cref := BackendVariable.varCref(tmpv);
              lhs := Expression.crefExp(cref);
              eqn := BackendDAE.EQUATION(lhs, y_norm, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
              //print("\n" + BackendDump.equationString(eqn));
              eqns := BackendEquation.addEquation(eqn, eqns);
              vars := BackendVariable.addVar(tmpv, vars);
            end for;
            syst1.orderedVars := vars;
            syst1.orderedEqs := eqns;
          then BackendDAEUtil.clearEqSyst(syst1);
      end match;
      osystlst := syst::osystlst;
    end for;
  else
    osystlst := systlst;
  end if;
  // inputs
  if Flags.isSet(Flags.ADD_SCALED_VARS_INPUT) then
    //BackendDump.printVarList(lst_inputs);
    syst :: osystlst := osystlst;
    syst := match syst
      local
        BackendDAE.EqSystem syst1;
      case syst1 as BackendDAE.EQSYSTEM(orderedEqs=eqns, orderedVars=vars)
        algorithm
          for v in lst_inputs loop
            cref := BackendVariable.varCref(v);
            tmpv := BackendVariable.createVar(cref, "__OMC$scaled_input");
            y := Expression.crefExp(cref);
            norm := BackendVariable.getVarNominalValue(v);
            y_norm := Expression.expDiv(y,norm);
            (y_norm,_) := ExpressionSimplify.simplify(y_norm);
            // lhs
            cref := BackendVariable.varCref(tmpv);
            lhs := Expression.crefExp(cref);
            eqn := BackendDAE.EQUATION(lhs, y_norm, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
            //print("\n" + BackendDump.equationString(eqn));
            eqns := BackendEquation.addEquation(eqn, eqns);
            vars := BackendVariable.addVar(tmpv, vars);
          end for;
          syst1.orderedEqs := eqns;
          syst1.orderedVars := vars;
        then BackendDAEUtil.clearEqSyst(syst1);
    end match;
    osystlst := syst::osystlst;
  end if;
  outDAE := BackendDAE.DAE(osystlst, oshared);
end addedScaledVarsWork;

// =============================================================================
// section for sortEqnsVars
//
// author: Vitalij Ruge
// =============================================================================

public function sortEqnsVars
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := if Flags.isSet(Flags.SORT_EQNS_AND_VARS) then sortEqnsVarsWork(inDAE) else inDAE;
end sortEqnsVars;

protected function sortEqnsVarsWork
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  list<BackendDAE.EqSystem> systlst, new_systlst = {};
  BackendDAE.Shared shared;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mT;
  Integer ne,nv;
  array<Integer> w_vars, w_eqns;
  DAE.FunctionTree functionTree;
  array<Option<BackendDAE.Var>> varOptArr;
  array<Option<BackendDAE.Equation>> equOptArr;
  list<tuple<Integer,Integer>> tplIndexWeight;
  list<Integer> indexs;
  list<BackendDAE.Var> var_lst;
  list<BackendDAE.Equation> eqn_lst;
algorithm
  //BackendDump.bltdump("START:", outDAE);
  BackendDAE.DAE(systlst, shared) := inDAE;
  BackendDAE.SHARED(functionTree=functionTree) := shared;
  for syst in systlst loop
    syst := match syst
      local
        BackendDAE.EqSystem syst1;
      case syst1 as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
        algorithm
          (_, m, mT) := BackendDAEUtil.getIncidenceMatrix(syst, BackendDAE.SPARSE(), SOME(functionTree));
          BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(varOptArr = varOptArr, numberOfElements = nv)) := vars;
          BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr, numberOfElement = ne) := eqns;
          //init weights
          w_vars := arrayCreate(nv, -1);
          w_eqns := arrayCreate(ne, -1);
          //weights vars, TODO: improve me!
          sortEqnsVarsWeights(w_vars, nv, mT);
          //weights eqns, TODO: improve me!
          sortEqnsVarsWeights(w_eqns, ne, m);
          //sort vars
          tplIndexWeight := list((i, w_vars[i]) for i in 1:nv);
          //sorted vars
          tplIndexWeight := List.sort(tplIndexWeight, compWeightsVars);
          //new order vars indexs
          indexs := sortEqnsVarsWorkTpl(tplIndexWeight);
          var_lst := list(BackendVariable.getVarAt(vars, i) for i in indexs);
          // new vars
          vars := BackendVariable.listVar1(var_lst);
          //sort eqns
          tplIndexWeight := list((i, w_eqns[i]) for i in 1:ne);
          //sorted eqns
          tplIndexWeight := List.sort(tplIndexWeight, compWeightsEqns);
          //new order eqns indexs
          indexs := sortEqnsVarsWorkTpl(tplIndexWeight);
          eqn_lst := list(BackendEquation.equationNth1(eqns, i) for i in indexs);
          //new eqns
          eqns := BackendEquation.listEquation(eqn_lst);
          syst1.orderedEqs := eqns;
          syst1.orderedVars := vars;
        then BackendDAEUtil.clearEqSyst(syst1);
    end match;
    new_systlst := syst :: new_systlst;
  end for; //syst

  outDAE:= BackendDAE.DAE(new_systlst, shared);
  //BackendDump.bltdump("ENDE:", outDAE);
end sortEqnsVarsWork;

protected function sortEqnsVarsWorkTpl
  input list<tuple<Integer,Integer>> tplIndexWeight;
  output list<Integer> outIndexs;
algorithm
  outIndexs := list(Util.tuple21(elem) for elem in tplIndexWeight);
end sortEqnsVarsWorkTpl;

protected function sortEqnsVarsWeights
  input array<Integer> inW;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  output array<Integer> outW = inW;
protected
  Integer i;
algorithm
  for i in 1:n loop
    outW[i] := listLength(m[i]);
  end for;
end sortEqnsVarsWeights;

// sort({2, 1, 3}, intGt) => {1, 2, 3}
// sort({2, 1, 3}, intLt) => {3, 2, 1}
protected function compWeightsVars
  input tuple<Integer,Integer> inTpl1;
  input tuple<Integer,Integer> inTpl2;
  output Boolean b;
protected
  Integer i1,i2;
algorithm
  (_,i1) := inTpl1;
  (_,i2) := inTpl2;
  b := intGt(i1 ,i2);
end compWeightsVars;

protected function compWeightsEqns
  input tuple<Integer,Integer> inTpl1;
  input tuple<Integer,Integer> inTpl2;
  output Boolean b;
protected
  Integer i1,i2;
algorithm
  (_,i1) := inTpl1;
  (_,i2) := inTpl2;
  //b := intLt(i1 ,i2);
  b := intGt(i1 ,i2);
end compWeightsEqns;

// =============================================================================
// section for simplifyLoops
//
// simplify(hopful) loops for simulation/optimization
// author: Vitalij Ruge
// =============================================================================

public function simplifyLoops
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := if Flags.getConfigInt(Flags.SIMPLIFY_LOOPS) > 0 then simplifyLoopsMain(inDAE) else inDAE;
end simplifyLoops;

protected function simplifyLoopsMain
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  list<BackendDAE.EqSystem> systlst, new_systlst = {};
  BackendDAE.Shared shared;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.BaseClockPartitionKind partitionKind;
  BackendDAE.StateSets stateSets;
  BackendDAE.StrongComponents comps;
  BackendDAE.Matching matching;
  DAE.FunctionTree functionTree;
  Boolean update;
  Integer index = 1, ii;
  BackendDAE.EqSystem nSyst;
  list<Integer> ass1;
  list<Integer> ass2;
  list<Integer> compOrders;
  Integer ne, nv;
  Boolean simDAE;
algorithm
  //BackendDump.bltdump("START:", outDAE);
  shared := inDAE.shared;
  functionTree := shared.functionTree;

  simDAE := match shared
            case BackendDAE.SHARED(backendDAEType = BackendDAE.SIMULATION()) then true;
            else false;
            end match;

  if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
    print("START: simplifyLoops\n");
    if not simDAE then
      print("\n***noSIM***\n");
    end if;
  end if;
  for syst in inDAE.eqs loop
    update := false;
    ass1 := {};
    ass2 := {};
    compOrders := {};
    ii := 1;
    BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching as BackendDAE.MATCHING(comps=comps),stateSets=stateSets,partitionKind=partitionKind) := syst;
    BackendDAE.EQUATION_ARRAY(numberOfElement=ne) := eqns;
    BackendDAE.VARIABLES(numberOfVars= nv) := vars;

    for comp in comps loop
      if BackendEquation.isEquationsSystem(comp) or BackendEquation.isTornSystem(comp) then
        (index,vars,eqns,shared,update, ass1, ass2,compOrders) := simplifyLoopsWork(comp, index, vars, eqns, shared, update, ass1, ass2, simDAE, ii, compOrders);
      end if;
      ii := ii + 1;
    end for; // comp
    nSyst := if update then simplifyLoopsUpdateMatching(vars, eqns, syst, listReverse(ass1), listReverse(ass2), ne, nv, functionTree, listReverse(compOrders)) else syst;
    new_systlst := nSyst :: new_systlst;
  end for; //syst
  outDAE:= BackendDAE.DAE(new_systlst, shared);
  //outDAE:= BackendDAE.DAE(listReverse(new_systlst), shared);
  //BackendDump.bltdump("ENDE:", outDAE);

  if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
    print("END: simplifyLoops\n");
  end if;

end simplifyLoopsMain;

protected function simplifyLoopsUpdateMatching
"
TODO: check me!
"
  input BackendDAE.Variables inVars "vars array";
  input BackendDAE.EquationArray inEqns "eqns array";
  input BackendDAE.EqSystem inSyst;
  input list<Integer> ass1_;
  input list<Integer> ass2_;
  input Integer nEqns;
  input Integer nVars;
  input DAE.FunctionTree functionTree;
  input list<Integer> compOrders;
  output BackendDAE.EqSystem outSyst = inSyst;

protected
  array<Integer> ass1 "eqn := ass1[var]";
  array<Integer> ass2 "var := ass2[eqn]";
  Integer n1, n2;
  BackendDAE.Matching matching;
  BackendDAE.StrongComponents comps;
algorithm
  //print("\nStart simplifyLoopsUpdateMatching");
  matching := inSyst.matching;
  BackendDAE.MATCHING(comps=comps, ass1=ass1, ass2=ass2) := matching;

  n1 := listLength(ass1_);
  n2 := listLength(ass2_);

  ass1 := Array.expand(n1, ass1, -1);
  ass2 := Array.expand(n2, ass2, -1);

  //print("ass1 :" + intString(arrayLength(ass1)) + "/" + intString(n1) + "/" + intString(nEqns));
  //print("\nass2 :" + intString(arrayLength(ass2)) + "/" + intString(n2) + "/" + intString(nVars) + "\n");
  //alg fix

  ass1 := simplifyLoopsUpdateAss(ass1, ass1_, nVars);
  ass2 := simplifyLoopsUpdateAss(ass2, ass2_, nEqns);

  comps := simplifyLoopsUpdateComps(comps, ass1_, ass2_, compOrders);

  outSyst.matching := BackendDAE.MATCHING(ass1, ass2, comps);
  outSyst.orderedEqs := inEqns;
  outSyst.orderedVars := inVars;
  outSyst := BackendDAEUtil.setEqSystMatrices(outSyst);

  //print("\nEnde simplifyLoopsUpdateMatching");
end simplifyLoopsUpdateMatching;

protected function simplifyLoopsUpdateAss
  input array<Integer> inAss;
  input list<Integer> new_ass;
  input Integer n;
  output array<Integer> outAss = inAss;
protected
  Integer i = 1;
algorithm
  for a in new_ass loop
    outAss[i+n] := a;
    i := i + 1;
  end for;
end simplifyLoopsUpdateAss;

protected function simplifyLoopsUpdateComps
  input BackendDAE.StrongComponents inComps;
  input list<Integer> inAss1;
  input list<Integer> inAss2;
  input list<Integer> inCompOrders;
  output BackendDAE.StrongComponents outComps = inComps;
protected
  Integer a1, a2, shift = 0, o;
  BackendDAE.StrongComponent comp;
  list<Integer> ass1 = inAss1, ass2 = inAss2, compOrders = inCompOrders;
algorithm
  for a1 in ass1 loop
    o :: compOrders := compOrders;
    a2 :: ass2 := ass2;
    comp := BackendDAE.SINGLEEQUATION(a1, a2);
    //print("comp: " + intString(a1) + " <->" + intString(a2) + "\n");
    outComps := List.insert(outComps, o + shift, comp);
    shift := shift + 1;
    //outComps := comp :: outComps;
  end for;
end simplifyLoopsUpdateComps;

protected function simplifyLoopsWork
  input BackendDAE.StrongComponent inComp;
  input Integer inIndx;
  input BackendDAE.Variables inVars "vars array";
  input BackendDAE.EquationArray inEqns "eqns array";
  input BackendDAE.Shared inShared;
  input Boolean inUpdate;
  input list<Integer> ass1_;
  input list<Integer> ass2_;
  input Boolean simDAE;
  input Integer ii;
  input list<Integer> inCompOrders;
  output Integer outIndx = inIndx;
  output BackendDAE.Variables outVars = inVars "vars array";
  output BackendDAE.EquationArray outEqns  = inEqns "eqns array";
  output BackendDAE.Shared outShared = inShared;
  output Boolean outUpdate = inUpdate;
  output list<Integer> ass1 = ass1_;
  output list<Integer> ass2 = ass2_;
  output list<Integer> outCompOrders = inCompOrders;
protected
  list<Integer> eqns;
  list<Integer> vv;
  list<Integer> vars "be careful with states, this are solved for der(x)";
  list<DAE.ComponentRef> var_lst = {} "varName";
  DAE.ComponentRef cr;
  BackendDAE.Equation eqn;
  Boolean update, linear;
  Integer i, k;
  list<tuple<Integer,list<Integer>>> otherEqnVarTpl;
  tuple<Integer,list<Integer>> tpl;
algorithm

  if BackendEquation.isEquationsSystem(inComp) then
    BackendDAE.EQUATIONSYSTEM(eqns=eqns,vars=vars) := inComp;

    //linear system need simplifications?
    if BackendDAEUtil.isLinearEqSystemComp(inComp) then
      return;
    end if;
    if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
        print("------ EquationsSystem ------\n");
    end if;

  else
    BackendDAE.TORNSYSTEM(linear=linear, strictTearingSet = BackendDAE.TEARINGSET(tearingvars=vars, residualequations=eqns, otherEqnVarTpl= otherEqnVarTpl)) := inComp;
    if linear then
      return;
    end if;
    if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
        print("------ Tearing ------\n");
    end if;

    for tpl in otherEqnVarTpl loop
      (k,vv) := tpl;
      eqns := k :: eqns;
      vars := listAppend(vv,vars);
    end for;
  end if; //comp

  if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
    print("------ loop-vars ------\n");
  end if;

  for i in vars loop
    BackendDAE.VAR(varName = cr) := BackendVariable.getVarAt(outVars, i);
    var_lst := cr :: var_lst;
    if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
        print(ComponentReference.printComponentRefStr(cr) +"\n");
    end if;
  end for;

  if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
    print("------------\n");
  end if;

  for i in eqns loop
    try
      eqn := BackendEquation.equationNth1(outEqns, i);
      if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
        print("update eqn[" + intString(i) + "]\n");
        print(BackendDump.equationString(eqn) + "--old--\n");
      end if;
      (outIndx, outVars, outEqns, outShared, update, eqn, ass1, ass2, outCompOrders) := simplifyLoopEqn(outIndx, outVars, outEqns, outShared, var_lst, eqn, ass1, ass2, simDAE, ii, outCompOrders);
      outUpdate := outUpdate or update;
      //if update then
        outEqns := BackendEquation.setAtIndex(outEqns, i, eqn);
      //end if;
      if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
        print("=> ");
        print(BackendDump.equationString(eqn) + "--new--\n");
      end if;
    else
    end try;
  end for;

end simplifyLoopsWork;

protected function simplifyLoopEqn
  input Integer inIndx;
  input BackendDAE.Variables inVars "vars array";
  input BackendDAE.EquationArray inEqns "eqns array";
  input BackendDAE.Shared inShared;
  input list<DAE.ComponentRef> var_lst "filter vars";
  input BackendDAE.Equation inEqn "filter eqn";
  input list<Integer> ass1_;
  input list<Integer> ass2_;
  input Boolean simDAE;
  input Integer ii;
  input list<Integer> inCompOrders;
  output Integer outIndx = inIndx;
  output BackendDAE.Variables outVars = inVars "vars array";
  output BackendDAE.EquationArray outEqns  = inEqns "eqns array";
  output BackendDAE.Shared outShared = inShared;
  output Boolean outUpdate = false;
  output BackendDAE.Equation outEqn = inEqn;
  output list<Integer> ass1 = ass1_;
  output list<Integer> ass2 = ass2_;
  output list<Integer> outCompOrder = inCompOrders;
protected
  DAE.Exp rhs, lhs, e;
  Boolean update_lhs, update_rhs;
  list<DAE.Exp> loopTerms_lhs, noLoopTerms_lhs, loopTerms_rhs, noLoopTerms_rhs;
  Boolean useTmpVars = Flags.getConfigInt(Flags.SIMPLIFY_LOOPS) > 1;
algorithm

  if BackendEquation.isAlgorithm(outEqn) then
    return;
  end if;

  //get
  lhs := BackendEquation.getEquationLHS(outEqn);
  //check
  if not Types.isIntegerOrRealOrSubTypeOfEither(Expression.typeof(lhs)) then
    return ;
  end if;
  rhs := BackendEquation.getEquationRHS(outEqn);

  (loopTerms_lhs, noLoopTerms_lhs) := simplifyLoops_SplitTerms(var_lst, lhs);
  (loopTerms_rhs, noLoopTerms_rhs) := simplifyLoops_SplitTerms(var_lst, rhs);

  if listLength(loopTerms_lhs) > listLength(loopTerms_rhs) then
    lhs := Expression.expSub(Expression.makeSum1(loopTerms_lhs), Expression.makeSum1(loopTerms_rhs));
    rhs := Expression.expSub(Expression.makeSum1(noLoopTerms_rhs), Expression.makeSum1(noLoopTerms_lhs));
  else
    lhs := Expression.expSub(Expression.makeSum1(loopTerms_rhs), Expression.makeSum1(loopTerms_lhs));
    rhs := Expression.expSub(Expression.makeSum1(noLoopTerms_lhs), Expression.makeSum1(noLoopTerms_rhs));
  end if;

  //
  (lhs,rhs,_) := Expression.createResidualExp3(lhs,rhs);
  (lhs,e) := Expression.makeFraction(lhs);
  (lhs, _) := ExpressionSimplify.simplify(lhs);
  (e, _) := ExpressionSimplify.simplify(e);

  //rhs := Expression.expMul(rhs,e);
  rhs := ExpressionSimplify.simplifySumOperatorExpression(rhs, DAE.MUL(Expression.typeof(rhs)), e);

  //update
  (outIndx, outVars, outEqns, outShared, update_rhs, rhs, ass1, ass2, outCompOrder) := simplifyLoopExp(outIndx, outVars, outEqns, outShared, var_lst, rhs, ass1, ass2, simDAE, useTmpVars,ii,outCompOrder);
  (outIndx, outVars, outEqns, outShared, update_lhs, lhs, ass1, ass2, outCompOrder) := simplifyLoopExp(outIndx, outVars, outEqns, outShared, var_lst, lhs, ass1, ass2, simDAE, useTmpVars,ii,outCompOrder);

  //
  outEqn := BackendEquation.setEquationLHS(outEqn, lhs);
  outEqn := BackendEquation.setEquationRHS(outEqn, rhs);

  outUpdate := outUpdate or update_rhs or update_lhs;
end simplifyLoopEqn;


public function simplifyLoopExp
  input Integer inIndx;
  input BackendDAE.Variables inVars "vars array";
  input BackendDAE.EquationArray inEqns "eqns array";
  input BackendDAE.Shared inShared;
  input list<DAE.ComponentRef> var_lst "filter vars";
  input DAE.Exp inExp;
  input list<Integer> ass1_;
  input list<Integer> ass2_;
  input Boolean simDAE;
  input Boolean useTmpVars = true;
  input Integer ii;
  input list<Integer> inCompOrders;
  input String tmpVarName = "LOOP";
  input Boolean noPara = false;
  output Integer outIndx = inIndx;
  output BackendDAE.Variables outVars = inVars "vars array";
  output BackendDAE.EquationArray outEqns  = inEqns "eqns array";
  output BackendDAE.Shared outShared = inShared;
  output Boolean outUpdate = false;
  output DAE.Exp outExp = inExp;
  output list<Integer> ass1 = ass1_;
  output list<Integer> ass2 = ass2_;
  output list<Integer> outCompOrder = inCompOrders;
protected
  list<DAE.Exp> loopTerms, noLoopTerms, loopFactors, noLoopFactors, loopTermsUpdatedFactors, loopTerms2, noLoopTerms2, loopFacotrsUpdatedTerms;
  DAE.Exp res, noLoopTerm, loopTerm, noLoopFactor, noLoopTerm2, loopTerm2, e1, e2, con;
  Boolean update;
  DAE.Operator op;
  Boolean para;
  Integer ne,nv;
algorithm

  (loopTerms, noLoopTerms) := simplifyLoops_SplitTerms(var_lst, outExp);

  //terms
  (noLoopTerm,_) := ExpressionSimplify.simplify1(Expression.makeSum1(noLoopTerms));
  if useTmpVars and simDAE then
    (noLoopTerm, outEqns, outVars, outShared, update, para) :=  BackendEquation.makeTmpEqnForExp(noLoopTerm, tmpVarName + "T", if simDAE then outIndx else -outIndx, outEqns, outVars, outShared);
    (outUpdate, ass1, ass2, outIndx, outCompOrder) := simplifyLoopExpHelper(update, outUpdate, para, ass1, ass2, outVars, outEqns, outIndx, ii, outCompOrder);
  end if;

   //factors
   loopTermsUpdatedFactors := {};
   for factor in loopTerms loop
     (loopFactors, noLoopFactors) := simplifyLoops_SplitFactors(var_lst, factor);
     (noLoopFactor,_) :=  ExpressionSimplify.simplify1(Expression.makeProductLst(noLoopFactors));

     if useTmpVars and simDAE then
      if (match noLoopFactor case DAE.BINARY(operator = DAE.DIV()) then true; case DAE.BINARY(operator = DAE.POW()) then true; else false; end match) then
         DAE.BINARY(e1,op,e2) := noLoopFactor;
        (e1, outEqns, outVars, outShared, update, para) :=  BackendEquation.makeTmpEqnForExp(e1, "LOOPF", if simDAE then outIndx else -outIndx, outEqns, outVars, outShared,noPara);
        (outUpdate, ass1, ass2, outIndx, outCompOrder) := simplifyLoopExpHelper(update, outUpdate, para, ass1, ass2, outVars, outEqns, outIndx, ii, outCompOrder);
        (e2, outEqns, outVars, outShared, update, para) :=  BackendEquation.makeTmpEqnForExp(e2, "LOOPF", if simDAE then outIndx else -outIndx, outEqns, outVars, outShared,noPara);
        (outUpdate, ass1, ass2, outIndx, outCompOrder) := simplifyLoopExpHelper(update, outUpdate, para, ass1, ass2, outVars, outEqns, outIndx, ii, outCompOrder);
        noLoopFactor := DAE.BINARY(e1,op,e2);
      else
        (noLoopFactor, outEqns, outVars, outShared, update, para) :=  BackendEquation.makeTmpEqnForExp(noLoopFactor, tmpVarName + "F", if simDAE then outIndx else -outIndx, outEqns, outVars, outShared);
        (outUpdate, ass1, ass2, outIndx, outCompOrder) := simplifyLoopExpHelper(update, outUpdate, para, ass1, ass2, outVars, outEqns, outIndx, ii, outCompOrder);
      end if;
     end if;

     //recursive
     loopFacotrsUpdatedTerms := {};
     for term in loopFactors loop
        res := term;
        if Expression.isBinary(res) then
          DAE.BINARY(operator=op) := res;
          if Expression.isAddOrSub(op) or Expression.isMulOrDiv(op) or Expression.isPow(op) then
            if not Expression.expEqual(res, inExp) then
              if Expression.isDiv(op) or Expression.isPow(op) then
                DAE.BINARY(e1,op,e2) := res;
                (outIndx, outVars, outEqns, outShared, update, e1, ass1, ass2, outCompOrder) := simplifyLoopExp(outIndx, outVars, outEqns, outShared, var_lst, e1, ass1, ass2, simDAE, useTmpVars, ii, outCompOrder);
                outUpdate := update or outUpdate;
                (outIndx, outVars, outEqns, outShared, update, e2, ass1, ass2, outCompOrder) := simplifyLoopExp(outIndx, outVars, outEqns, outShared, var_lst, e2, ass1, ass2, simDAE, useTmpVars, ii, outCompOrder);
                outUpdate := update or outUpdate;
                (e2,_) := ExpressionSimplify.simplify1(e2);
                res := DAE.BINARY(e1,op,e2);
              else
                (outIndx, outVars, outEqns, outShared, update, res, ass1, ass2, outCompOrder) := simplifyLoopExp(outIndx, outVars, outEqns, outShared, var_lst, res, ass1, ass2, simDAE, useTmpVars, ii, outCompOrder);
                outUpdate := update or outUpdate;
              end if; // DIV, POW
            end if; // equal
          end if; // *, /, +, -, ^
        end if; // BINARY
        loopFacotrsUpdatedTerms := res :: loopFacotrsUpdatedTerms;
     end for; //term2
     loopTermsUpdatedFactors := Expression.makeProductLst(noLoopFactor :: loopFacotrsUpdatedTerms) :: loopTermsUpdatedFactors;
   end for; //factor

   outExp := ExpressionSimplify.simplify(Expression.makeSum1(noLoopTerm::loopTermsUpdatedFactors,true));

end simplifyLoopExp;

protected function simplifyLoopExpHelper
  input Boolean update;
  input Boolean update_;
  input Boolean para;
  input list<Integer> ass1_;
  input list<Integer> ass2_;
  input BackendDAE.Variables inVars "vars array";
  input BackendDAE.EquationArray inEqns "eqns array";
  input Integer inIndex;
  input Integer ii;
  input list<Integer> inCompOrders;
  output Boolean outUpdate = update_;
  output list<Integer> ass1 = ass1_;
  output list<Integer> ass2 = ass2_;
  output Integer outIndx = inIndex;
  output list<Integer> outCompOrder = inCompOrders;
protected
  Integer ne, nv;
algorithm
   if update then
    outIndx := outIndx + 1;
    outUpdate := update;
    if not para then
      BackendDAE.EQUATION_ARRAY(numberOfElement=ne) := inEqns;
      BackendDAE.VARIABLES(numberOfVars= nv) := inVars;
      ass1 := ne :: ass1;
      ass2 := nv :: ass2;
      outCompOrder := ii :: outCompOrder;
    end if;
   end if;
end simplifyLoopExpHelper;

public function simplifyLoops_SplitTerms
  input list<DAE.ComponentRef> var_lst;
  input DAE.Exp inExp;
  output list<DAE.Exp> loopTerms = {};
  output list<DAE.Exp> noLoopTerms;
protected
  list<DAE.Exp> tmp_loopTerms;
algorithm
  noLoopTerms := Expression.terms(inExp);
  for cr in var_lst loop
    if listEmpty(noLoopTerms) then
      break;
    else
      (tmp_loopTerms, noLoopTerms) := List.split1OnTrue(noLoopTerms, Expression.expHasCrefNoPreOrStart, cr);
      loopTerms := listAppend(tmp_loopTerms, loopTerms);
    end if;
  end for;
end simplifyLoops_SplitTerms;

protected function simplifyLoops_SplitFactors
  input list<DAE.ComponentRef> var_lst;
  input DAE.Exp inExp;
  output list<DAE.Exp> loopTerms = {};
  output list<DAE.Exp> noLoopTerms;
protected
  list<DAE.Exp> tmp_loopTerms;
algorithm
  noLoopTerms := Expression.factors(inExp);
  for cr in var_lst loop
    if listEmpty(noLoopTerms) then
      break;
    else
      (tmp_loopTerms, noLoopTerms) := List.split1OnTrue(noLoopTerms, Expression.expHasCrefNoPreOrStart, cr);
      loopTerms := listAppend(tmp_loopTerms, loopTerms);
    end if;
  end for;

end simplifyLoops_SplitFactors;


// =============================================================================
// section for symEuler
//
// replace der(x) with difference quotient
// -->  implicit euler
//
// after removeSimpliEquation
// before tearing
// ToDo: not add to initial equation
// author: Vitalij Ruge
// =============================================================================

public function symEuler
 input BackendDAE.BackendDAE inDAE;
 output BackendDAE.BackendDAE outDAE;
algorithm
 outDAE := if Flags.getConfigBool(Flags.SYM_EULER) then symEulerWork(inDAE, true) else inDAE;
end symEuler;
public function symEulerInit
"
fix the difference quotient for initial equations[0/0]
ToDo: remove me
"
 input BackendDAE.BackendDAE inDAE;
 output BackendDAE.BackendDAE outDAE;
algorithm
 outDAE := if Flags.getConfigBool(Flags.SYM_EULER) then symEulerWork(BackendDAEUtil.copyBackendDAE(inDAE), false) else inDAE;

end symEulerInit;

protected function symEulerWork
  input BackendDAE.BackendDAE inDAE;
  input Boolean b " true => add, false => remove euler equation";
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> osystlst = {};
  BackendDAE.EqSystem syst_;
  BackendDAE.Shared shared;
  BackendDAE.Var tmpv;
  DAE.ComponentRef cref;
algorithm
  // make dt
  cref := ComponentReference.makeCrefIdent(BackendDAE.symEulerDT, DAE.T_REAL_DEFAULT, {});
  tmpv := BackendVariable.makeVar(cref);
  //tmpv := BackendVariable.setVarKind(tmpv, BackendDAE.PARAM());
  tmpv := BackendVariable.setBindExp(tmpv, SOME(DAE.RCONST(0.0)));
  shared := BackendVariable.addKnVarDAE(tmpv, inDAE.shared);

  for syst in inDAE.eqs loop
   (syst_, shared) := symEulerUpdateSyst(syst, b, shared);
   osystlst := syst_ :: osystlst;
  end for;

  outDAE := BackendDAE.DAE(osystlst, shared);
  //BackendDump.bltdump("BackendDAEOptimize.removeSymEulerEquation", outDAE);
end symEulerWork;

protected function symEulerUpdateSyst
  input BackendDAE.EqSystem iSyst;
  input Boolean b;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem oSyst;
  output BackendDAE.Shared oShared = shared;
protected
  array<Option<BackendDAE.Equation>> equOptArr;
  Option<BackendDAE.Equation> oeqn;
  BackendDAE.Equation eqn;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  Integer n;
  list<DAE.ComponentRef> crlst;

algorithm
  oSyst := match iSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      algorithm
        BackendDAE.EQUATION_ARRAY(equOptArr=equOptArr) := eqns;
        n := arrayLength(equOptArr);
        crlst := {};
        for i in 1:n loop
          oeqn := arrayGet(equOptArr, i);
          if isSome(oeqn) then
            SOME(eqn) := oeqn;
            (eqn, (_,crlst)) := BackendEquation.traverseExpsOfEquation(eqn, symEulerUpdateEqn, (b,crlst));
            arrayUpdate(equOptArr, i, SOME(eqn));
          end if;
        end for;
        // states -> vars
        vars := symEulerState(vars, crlst, b);
        syst.orderedVars := vars;
        syst.orderedEqs := eqns;
      then BackendDAEUtil.clearEqSyst(syst);
  end match;
end symEulerUpdateSyst;

protected function symEulerState
  input BackendDAE.Variables vars;
  input list<DAE.ComponentRef> crlst;
  input Boolean b;
  output BackendDAE.Variables ovars = vars;

protected
  Integer idx;
  BackendDAE.VarKind kind, oldKind;
algorithm
  for cref in crlst loop
    (_, idx) := BackendVariable.getVar2(cref, ovars);
    oldKind := BackendVariable.getVarKindForVar(idx,ovars);
    if b then
      kind := BackendDAE.ALG_STATE(oldKind);
    else
     BackendDAE.ALG_STATE(kind) := oldKind;
    end if;
    ovars :=  BackendVariable.setVarKindForVar(idx, kind, ovars);
  end for;
end symEulerState;

protected function symEulerUpdateEqn
  input DAE.Exp inExp;
  input tuple<Boolean, list<DAE.ComponentRef>> inTpl;
  output DAE.Exp outExp;
  output tuple<Boolean, list<DAE.ComponentRef>> outTpl;
algorithm
  (outExp, outTpl) := Expression.traverseExpBottomUp(inExp, symEulerUpdateDer, inTpl);
end symEulerUpdateEqn;

protected function symEulerUpdateDer
  input DAE.Exp inExp;
  input tuple<Boolean, list<DAE.ComponentRef>> inTpl;
  output DAE.Exp outExp;
  output tuple<Boolean, list<DAE.ComponentRef>> outTpl;
algorithm
  (outExp, outTpl) := match (inTpl, inExp)
            local DAE.Exp exp; DAE.Type tp; list<DAE.ComponentRef> cr_lst; DAE.ComponentRef cr;

            case ((true,cr_lst), DAE.CALL(path=Absyn.IDENT(name="der"), expLst={exp as DAE.CREF(ty=tp, componentRef = cr)}))
            then (Expression.makePureBuiltinCall("$_DF$DER", {exp}, tp), (true,List.unionElt(cr,cr_lst)));

            case ((false,cr_lst), DAE.CALL(path=Absyn.IDENT(name="$_DF$DER"), expLst={exp as DAE.CREF(ty=tp, componentRef = cr)}))
            then (Expression.makePureBuiltinCall("der", {exp}, tp),(false, List.unionElt(cr,cr_lst)));

            else (inExp, inTpl);
            end match;
end symEulerUpdateDer;


// =============================================================================
// section for introduceDerAlias
//
// =============================================================================

public function introduceDerAlias
" This module introduces alias for derivatove call in the form
  dx = der(x);
  This helps tearing and non-linear solvers to handle them more efficent."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if Flags.isSet(Flags.ADD_DER_ALIASES) then
    outDAE := BackendDAEUtil.mapEqSystem(inDAE, introduceDerAliasWork);
  else
    outDAE := inDAE;
  end if;
end introduceDerAlias;

protected function introduceDerAliasWork
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared = shared;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  list<BackendDAE.Equation> eqnsList;
algorithm
  osyst := match inSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      algorithm
        (eqns, (vars, eqnsList, _, _)) :=
              BackendEquation.traverseEquationArray_WithUpdate( eqns, traverserintroduceDerAliasEquation,
                                                                (vars, {}, shared, true) );
        eqns := BackendEquation.addEquations(eqnsList, eqns);
        syst.orderedEqs := eqns; syst.orderedVars := vars;
      then syst;
  end match;
end introduceDerAliasWork;

protected function traverserintroduceDerAliasEquation "
  Help function to e.g. introduceDerAliasWork"
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.Variables, list<BackendDAE.Equation>, BackendDAE.Shared, Boolean> tpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.Variables, list<BackendDAE.Equation>, BackendDAE.Shared, Boolean> outTpl;
protected
  BackendDAE.Equation e;
  BackendDAE.Variables vars;
  Boolean b;
  list<DAE.SymbolicOperation> ops;
  BackendDAE.Shared shared;
  list<BackendDAE.Equation> eqnLst;
algorithm
  (vars, eqnLst, shared, b) := tpl;
  (e, (vars, eqnLst, shared, ops, _)) := BackendEquation.traverseExpsOfEquation(inEq, traverserintroduceDerAliasExp, (vars, eqnLst, shared, {}, b));
  outEq := List.foldr(ops, BackendEquation.addOperation, e);
  outTpl := (vars, eqnLst, shared, b);
end traverserintroduceDerAliasEquation;

protected function traverserintroduceDerAliasExp "
  Help function to e.g. traverserintroduceDerAliasEquation"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, list<BackendDAE.Equation>, BackendDAE.Shared, list<DAE.SymbolicOperation>, Boolean> tpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, list<BackendDAE.Equation>, BackendDAE.Shared, list<DAE.SymbolicOperation>, Boolean> outTpl;
protected
  DAE.Exp e, e1;
  tuple<BackendDAE.Variables, list<BackendDAE.Equation>, BackendDAE.Shared, Boolean, Boolean> ext_arg;
  BackendDAE.Variables vars;
  list<DAE.SymbolicOperation> ops;
  DAE.FunctionTree funcs;
  Boolean b, addVars;
  BackendDAE.Shared shared;
  list<BackendDAE.Equation> eqnLst;
algorithm
  e := inExp;
  (vars, eqnLst, shared, ops, addVars) := tpl;
  ext_arg := (vars, eqnLst, shared, addVars, false);
  (e1, (vars, eqnLst, shared, _, b)) := Expression.traverseExpBottomUp(e, introDerAlias, ext_arg);
  ops := List.consOnTrue(b, DAE.SUBSTITUTION({e1}, e), ops);
  outExp := e1;
  outTpl := (vars, eqnLst, shared, ops, addVars);
end traverserintroduceDerAliasExp;

protected function introDerAlias "
  Help function to e.g. traverserintroduceDerAliasExp"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, list<BackendDAE.Equation>, BackendDAE.Shared, Boolean, Boolean> itpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, list<BackendDAE.Equation>, BackendDAE.Shared, Boolean, Boolean> tpl;
algorithm
  (outExp,tpl) := matchcontinue (inExp, itpl)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr,cref;
      DAE.Type ty;
      String str;
      BackendDAE.Shared shared;
      list<BackendDAE.Var> varlst;
      BackendDAE.Var v, v1;
      Boolean b, addVar;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> eqnLst;
      Integer numVars;
      list<DAE.Exp> expLst;
      String str;

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr, ty=ty)}), (vars, eqnLst, shared, addVar, _)) equation
      ({v}, _) = BackendVariable.getVar(cr, vars);
      cref = BackendVariable.varCref(v);
      v1 = BackendVariable.createAliasDerVar(cref);
      v1 = BackendVariable.mergeNominalAttribute(v, v1, false);
      cref = BackendVariable.varCref(v1);
      outExp = DAE.CREF(cref,ty);
      if addVar then
        numVars = BackendVariable.varsSize(vars);
        vars = BackendVariable.addVar(v1, vars);
        eqnLst = if numVars < BackendVariable.varsSize(vars) then BackendDAE.EQUATION(inExp, outExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::eqnLst else eqnLst;
      end if;
    then (outExp, (vars, eqnLst, shared, addVar, true));

    case (DAE.CALL(path=Absyn.IDENT(name="der")), (_, _, _, _, _)) equation
      str = "BackendDAEOptimize.introduceDerAlias failed for: " + ExpressionDump.printExpStr(inExp) + "\n";
      Error.addMessage(Error.INTERNAL_ERROR, {str});
    then fail();

    else (inExp, itpl);
  end matchcontinue;
end introDerAlias;

// =============================================================================
// replace expression with rewritten expression
//
// =============================================================================

public function applyRewriteRulesBackend
"@author: adrpo"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, applyRewriteRulesBackend0, false);
  outDAE := applyRewriteRulesBackendShared(outDAE);
end applyRewriteRulesBackend;

protected function applyRewriteRulesBackend0
"@author: adrpo"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst = isyst;
  output BackendDAE.Shared outShared = inShared;
  output Boolean outChanged;
algorithm
  try
    BackendDAEUtil.traverseBackendDAEExpsVarsWithUpdate(isyst.orderedVars, traverserapplyRewriteRulesBackend, false);
    BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(isyst.orderedEqs, traverserapplyRewriteRulesBackend, false);
    BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(isyst.removedEqs, traverserapplyRewriteRulesBackend, false);
    outChanged := true;
  else
    outChanged := false;
  end try;
end applyRewriteRulesBackend0;

protected function traverserapplyRewriteRulesBackend
"@author: adrpo"
  input DAE.Exp inExp;
  input Boolean inB;
  output DAE.Exp outExp;
  output Boolean outB;
algorithm
  (outExp,outB) := Expression.traverseExpBottomUp(inExp,traverserExpapplyRewriteRulesBackend,inB);
end traverserapplyRewriteRulesBackend;

protected function traverserExpapplyRewriteRulesBackend
"@author: adrpo"
  input DAE.Exp inExp;
  input Boolean inB;
  output DAE.Exp outExp;
  output Boolean outB;
algorithm
  (outExp,outB) := matchcontinue(inExp,inB)
    local
      DAE.Exp e;
      FCore.Cache cache;
      FCore.Graph graph;

    // apply rewrite rule
    case (e, _) equation
      (e, true) = RewriteRules.rewriteBackEnd(e);
    then (e, true);

    else (inExp,inB);
  end matchcontinue;
end traverserExpapplyRewriteRulesBackend;

protected function applyRewriteRulesBackendShared "@author: adrpo"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.Shared shared;
algorithm
  shared := inDAE.shared;
  BackendDAEUtil.traverseBackendDAEExpsVarsWithUpdate(shared.knownVars, traverserapplyRewriteRulesBackend, false);
  BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(shared.initialEqs, traverserapplyRewriteRulesBackend, false);
  BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(shared.removedEqs, traverserapplyRewriteRulesBackend, false);
  // not sure if we should apply the rules on the event info!
  // (ei, _) := traverseEventInfoExps(eventInfo, traverserapplyRewriteRulesBackend, false);
  outDAE := BackendDAE.DAE(inDAE.eqs, shared);
end applyRewriteRulesBackendShared;

// =============================================================================
// generates a list with all iteration variables
//
// =============================================================================

public function listAllIterationVariables "author: lochel"
  input BackendDAE.BackendDAE inBackendDAE;
protected
  BackendDAE.BackendDAEType backendDAEType;
  list<String> warnings;
algorithm
  BackendDAE.DAE(shared=BackendDAE.SHARED(backendDAEType=backendDAEType)) := inBackendDAE;
  warnings := listAllIterationVariables0(inBackendDAE.eqs);

  Error.addCompilerNotification("List of all iteration variables (DAE kind: " + BackendDump.printBackendDAEType2String(backendDAEType) + ")\n" + stringDelimitList(warnings, "\n"));
end listAllIterationVariables;

protected function listAllIterationVariables0 "author: lochel"
  input list<BackendDAE.EqSystem> inEqs;
  output list<String> outWarnings;
algorithm
  outWarnings := match(inEqs)
    local
      BackendDAE.EqSystem eq;
      list<BackendDAE.EqSystem> eqs;
      list<String> warning;
      list<String> warningList;

    case ({})
    then {};

    case (eq::eqs) equation
      warning = listAllIterationVariables1(eq);
      warningList = listAllIterationVariables0(eqs);
    then listAppend(warning, warningList);
  end match;
end listAllIterationVariables0;

protected function listAllIterationVariables1 "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  output list<String> outWarning;
protected
  BackendDAE.Variables vars;
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,
                      matching=BackendDAE.MATCHING(comps=comps)) := inEqSystem;
  outWarning := listAllIterationVariables2(comps, vars);
end listAllIterationVariables1;

protected function listAllIterationVariables2 "author: lochel"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.Variables inVars;
  output list<String> outWarning;
algorithm
  outWarning := matchcontinue(inComps, inVars)
    local
      BackendDAE.StrongComponents rest;
      list<BackendDAE.Var> varlst;
      list<Integer> vlst,vlst2;
      Boolean linear;
      String str;
      String warning;
      list<String> warningList;

    case ({}, _)
    then {};

    case (BackendDAE.EQUATIONSYSTEM(vars=vlst, jacType=BackendDAE.JAC_NONLINEAR())::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      false = listEmpty(varlst);

      warning = "Iteration variables of nonlinear equation system:\n" + warnAboutVars(varlst);
      warningList = listAllIterationVariables2(rest, inVars);
    then warning::warningList;

     case (BackendDAE.EQUATIONSYSTEM(vars=vlst, jacType=BackendDAE.JAC_GENERIC())::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      false = listEmpty(varlst);

      warning = "Iteration variables of equation system w/o analytic Jacobian:\n" + warnAboutVars(varlst);
      warningList = listAllIterationVariables2(rest, inVars);
    then warning::warningList;

    case (BackendDAE.EQUATIONSYSTEM(vars=vlst, jacType=BackendDAE.JAC_NO_ANALYTIC())::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      false = listEmpty(varlst);

      warning = "Iteration variables of equation system w/o analytic Jacobian:\n" + warnAboutVars(varlst);
      warningList = listAllIterationVariables2(rest, inVars);
    then warning::warningList;

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst), NONE(), linear=linear)::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      false = listEmpty(varlst);

      str = if linear then "linear" else "nonlinear";
      warning = "Iteration variables of torn " + str + " equation system:\n" + warnAboutVars(varlst);
      warningList = listAllIterationVariables2(rest, inVars);
    then warning::warningList;

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst), SOME(BackendDAE.TEARINGSET(tearingvars=vlst2)), linear=linear)::rest, _) equation
      vlst = List.unique(listAppend(vlst,vlst2));
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      false = listEmpty(varlst);

      str = if linear then "linear" else "nonlinear";
      warning = "Iteration variables of torn " + str + " equation system:\n" + warnAboutVars(varlst);
      warningList = listAllIterationVariables2(rest, inVars);
    then warning::warningList;

    case (_::rest, _) equation
      warningList = listAllIterationVariables2(rest, inVars);
    then warningList;
  end matchcontinue;
end listAllIterationVariables2;

protected function warnAboutVars "author: lochel"
  input list<BackendDAE.Var> inVars;
  output String outString;
algorithm
  outString := match(inVars)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vars;
      String crStr;
      String str;

    case ({})
    then "";

    case (v::{}) equation
      crStr = "  " + BackendDump.varString(v);
    then crStr;

    case (v::vars) equation
      crStr = BackendDump.varString(v);
      str = "  " + crStr + "\n" + warnAboutVars(vars);
    then str;
  end match;
end warnAboutVars;

public function addTimeAsState
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.EqSystem eq;
  BackendDAE.Shared shared;
  BackendDAE.Variables orderedVars "ordered Variables, only states and alg. vars";
  BackendDAE.EquationArray orderedEqs "ordered Equations";
  BackendDAE.Var var;
algorithm
  if Flags.getConfigBool(Flags.ADD_TIME_AS_STATE) then
    (BackendDAE.DAE(eqs, shared), _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, addTimeAsState1, 0);
    orderedVars := BackendVariable.emptyVars();
    var := BackendDAE.VAR(DAE.crefTimeState, BackendDAE.STATE(1, NONE()), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
    var := BackendVariable.setVarFixed(var, true);
    var := BackendVariable.setVarStartValue(var, DAE.CREF(DAE.crefTime, DAE.T_REAL_DEFAULT));
    orderedVars := BackendVariable.addVar(var, orderedVars);
    orderedEqs := BackendEquation.emptyEqns();
    orderedEqs := BackendEquation.addEquation(BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"), {DAE.CREF(DAE.crefTimeState, DAE.T_REAL_DEFAULT)}, DAE.callAttrBuiltinReal), DAE.RCONST(1.0), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC), orderedEqs);
    eq := BackendDAEUtil.createEqSystem(orderedVars, orderedEqs, {}, BackendDAE.CONTINUOUS_TIME_PARTITION());
    outDAE := BackendDAE.DAE(eq::eqs, shared);
  end if;
end addTimeAsState;

protected function addTimeAsState1
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input Integer inFoo;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared = inShared;
  output Integer outFoo = inFoo;
algorithm
  outSystem := matchcontinue inSystem
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EqSystem syst;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)
      algorithm
        BackendEquation.traverseEquationArray_WithUpdate(orderedEqs, addTimeAsState2, inFoo);
      then syst;

    else inSystem;
  end matchcontinue;
end addTimeAsState1;

protected function addTimeAsState2
  input BackendDAE.Equation inEq;
  input Integer inFoo;
  output BackendDAE.Equation outEq;
  output Integer outFoo = inFoo;
algorithm
  (outEq, _) := BackendEquation.traverseExpsOfEquation(inEq, addTimeAsState3, inFoo);
end addTimeAsState2;

protected function addTimeAsState3
  input DAE.Exp inExp;
  input Integer inTuple;
  output DAE.Exp outExp;
  output Integer outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpTopDown(inExp, addTimeAsState4, inTuple);
end addTimeAsState3;

protected function addTimeAsState4
  input DAE.Exp inExp;
  input Integer inTuple;
  output DAE.Exp outExp;
  output Boolean cont = true;
  output Integer outTuple = inTuple;
algorithm
  outExp := match inExp
    local
      DAE.Type ty;

    case DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"), ty=ty) equation
    then DAE.CREF(DAE.crefTimeState, ty);

    else inExp;
  end match;
end addTimeAsState4;

annotation(__OpenModelica_Interface="backend");
end BackendDAEOptimize;
