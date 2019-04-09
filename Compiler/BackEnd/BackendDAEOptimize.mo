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
               - and so on ..."

public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;
public import HashTable2;

protected
import AdjacencyMatrix;
import Algorithm;
import Array;
import BackendDAETransform;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendDAEEXT;
import BackendInline;
import BackendVarTransform;
import BackendVariable;
import BaseHashTable;
import CheckModel;
import ClassInf;
import ComponentReference;
import DAEUtil;
import DAEDump;
import Debug;
import Differentiate;
import ElementSource;
import ExpandableArray;
import Expression;
import ExpressionDump;
import ExpressionSolve;
import ExpressionSimplify;
import Error;
import Flags;
import GC;
import HashTableExpToIndex;
import HpcOmTaskGraph;
import List;
import Matching;
import MetaModelica.Dangerous;
import Mutable;
import RewriteRules;
import SCode;
import SynchronousFeatures;
import Tearing;
import Types;
import Util;
import Values;

public function simplifyAllExpressions "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  list<BackendDAE.Equation> removedEqsList = {};
  BackendDAE.Shared shared;
algorithm
  _ := BackendDAEUtil.traverseBackendDAEExpsNoCopyWithUpdate(outDAE, ExpressionSimplify.simplify1TraverseHelper, 0);

  // filter empty algorithms
  shared := outDAE.shared;
  for eq in BackendEquation.equationList(shared.removedEqs) loop
    removedEqsList := match eq
      case BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst={}))  then removedEqsList;
      else eq::removedEqsList;
    end match;
  end for;
  shared.removedEqs := BackendEquation.listEquation(MetaModelica.Dangerous.listReverseInPlace(removedEqsList));
  outDAE.shared := shared;
end simplifyAllExpressions;

// =============================================================================
// simplifyInStream
//
// OM introduces $OMC$PosetiveMax which can simplified using min or max attribute
// see Modelica spec for inStream
// author: Vitalij Ruge
// see. #3885, 4441, 5104
// =============================================================================

public function simplifyInStream
  input output BackendDAE.BackendDAE dae;
protected
  BackendDAE.Shared shared = dae.shared;
  BackendDAE.EqSystems eqs = dae.eqs;
  list<BackendDAE.Variables> vars = list(eq.orderedVars for eq in eqs);
algorithm
  // from the description inputs are part of globalKnownVars and localKnownVars :(
  vars := shared.globalKnownVars :: vars; // need inputs with min = 0 or max = 0
  vars := shared.localKnownVars :: vars;
  _ := BackendDAEUtil.traverseBackendDAEExpsNoCopyWithUpdate(dae, simplifyInStreamWork, vars);
end simplifyInStream;


protected function simplifyInStreamWork
  input DAE.Exp inExp;
  input list<BackendDAE.Variables> inVars;
  output DAE.Exp outExp;
  output list<BackendDAE.Variables> outVars = inVars;
algorithm
  outExp := Expression.traverseExpBottomUp(inExp, simplifyInStreamWork2, outVars);

  // with #5104 we remove max(x, eps)
  // so in case max(x,eps)*y/max(x,eps) => x*y/x
  // now x can be equal 0, so we need simplify x*y/x = y
  // it's seem no other models silplyfied it
  if not Expression.expEqual(outExp, inExp) then
    outExp := ExpressionSimplify.simplify(outExp);
  end if;
end simplifyInStreamWork;

protected function simplifyInStreamWork2
  input DAE.Exp inExp;
  input list<BackendDAE.Variables> inVars;
  output DAE.Exp outExp;
  output list<BackendDAE.Variables> outVars = inVars;
algorithm
  outExp := match(inExp)
    local
      DAE.Type tp;
      DAE.ComponentRef cr;
      DAE.Exp e, expr, ret;
      Option<DAE.Exp> eMin, eMax;

    // positiveMax(cref, eps) = 0 if variable(cref).max <= 0
    // positiveMax(cref, eps) = cref if variable(cref).min >= 0
    case DAE.CALL(path=Absyn.IDENT("$OMC$PositiveMax"),expLst={e as DAE.CREF(componentRef=cr), expr})
    algorithm
      (eMin, eMax) := simplifyInStreamWorkExpresion(cr, outVars);
      if simplifyInStreamWorkSimplify(eMax, true) then  // var.max <= 0.0
        tp := ComponentReference.crefTypeFull(cr);
        ret := Expression.createZeroExpression(tp);
      elseif simplifyInStreamWorkSimplify(eMin, false) then // var.min >= 0.0
        ret := e;
      else
        tp := ComponentReference.crefTypeFull(cr);
        ret := Expression.makePureBuiltinCall("max", {e, expr}, tp);
      end if;
    then
       ret;

    //positiveMax(-cref, eps) = 0 if variable(cref).min >= 0
    //positiveMax(-cref, eps) = -cref if variable(cref).max <= 0
    case DAE.CALL(path=Absyn.IDENT("$OMC$PositiveMax"),expLst={e as DAE.UNARY(DAE.UMINUS(tp), DAE.CREF(componentRef=cr)), expr})
    algorithm
      (eMin, eMax) := simplifyInStreamWorkExpresion(cr, outVars);
      if simplifyInStreamWorkSimplify(eMin, false) then // var.min >= 0.0
        ret := Expression.createZeroExpression(tp);
      elseif simplifyInStreamWorkSimplify(eMax, true) then  // var.max <= 0.0
        ret := e;
      else
        ret := Expression.makePureBuiltinCall("max", {e, expr}, tp);
      end if;
    then
       ret;

    //positiveMax(cref, eps) = cref where cref >= 0
    case DAE.CALL(path=Absyn.IDENT("$OMC$PositiveMax"),expLst={e, expr}) guard Expression.isPositiveOrZero(e)
    then e;

    // e.g. positiveMax(cref, eps) = max(cref,eps) = eps where cref < 0
    case DAE.CALL(path=Absyn.IDENT("$OMC$PositiveMax"),expLst={e, expr})
      //print("\nsimplifyInStreamWork: ");
      //print(ExpressionDump.printExpStr(inExp));
      //print(" <-> ");
      //print(ExpressionDump.printExpStr(e));
    then
      Expression.makePureBuiltinCall("max", {e, expr}, Expression.typeof(e));

    case DAE.CALL(path=Absyn.IDENT("$OMC$inStreamDiv"),expLst={e, expr})
      algorithm
          e := ExpressionSimplify.simplify(e);
          ret := match(e)
                  local
                    DAE.Exp a,b;

                  case DAE.BINARY(a, DAE.DIV(), b)
                  guard Expression.isZero(a) and Expression.isZero(b)
                  then expr;

                  else e;

                 end match;
      then
         ret;

    else inExp;
  end match;
end simplifyInStreamWork2;

protected function simplifyInStreamWorkExpresion
  input DAE.ComponentRef cr;
  input list<BackendDAE.Variables> inVars;
  output Option<DAE.Exp> outMin = NONE();
  output Option<DAE.Exp> outMax = NONE();
protected
  BackendDAE.Var v;
algorithm
  for vars in inVars loop
    try
      (v, _) := BackendVariable.getVarSingle(cr, vars);
      (outMin, outMax) := BackendVariable.getMinMaxAttribute(v);
      break;
    else
      // search
    end try;
  end for;
end simplifyInStreamWorkExpresion;

protected function simplifyInStreamWorkSimplify
  input Option<DAE.Exp> bound;
  input Boolean neg;
  output Boolean isZero;
algorithm
  isZero := match bound
    local
      Real r;
      Boolean b;
      DAE.Exp expr;

    case SOME(DAE.RCONST(r))
      then if neg then r<= 0.0 else r >= 0.0;

    case SOME(expr)
      //guard Expression.isConst(expr)
      algorithm
       expr := ExpressionSimplify.simplify(expr);
       b := match expr
            case DAE.RCONST(r)
              then if neg then r<= 0.0 else r >= 0.0;
            else
              false;
            end match;
      then
        b;

    else false;
  end match;
end simplifyInStreamWorkSimplify;

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
        ((_, (_, _, true))) := BackendDAEUtil.traverseBackendDAEExpsEqns (
            syst.orderedEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls,
            (shared.globalKnownVars, shared.aliasVars, false))
        );
        ((_, (_, _, true))) := BackendDAEUtil.traverseBackendDAEExpsEqns (
            syst.removedEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls,
            (shared.globalKnownVars, shared.aliasVars, false))
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
      BackendDAE.Variables globalKnownVars, aliasvars;
      DAE.Type tp;
      DAE.Exp e, zero;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      DAE.CallAttributes attr;
      Boolean negate;
      String idn;

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr, ty=tp)}), (globalKnownVars, aliasvars, _)) equation
      (var, _) = BackendVariable.getVarSingle(cr, globalKnownVars);
      false = BackendVariable.isVarOnTopLevelAndInput(var);
      (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
    then (zero, (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={e as DAE.CREF(componentRef=cr)}), (globalKnownVars, aliasvars, _)) guard idn=="pre" or idn=="previous" equation
      (_, _) = BackendVariable.getVarSingle(cr, globalKnownVars);
    then(e, (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}), (globalKnownVars, aliasvars, _)) guard idn=="pre" or idn=="previous"
    then (e, (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={e as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")))}), (globalKnownVars, aliasvars, _)) guard idn=="pre" or idn=="previous"
    then (e, (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={DAE.CREF(componentRef=cr, ty=tp)}, attr=attr), (globalKnownVars, aliasvars, _)) guard idn=="pre" or idn=="previous" equation
      (var, _) = BackendVariable.getVarSingle(cr, aliasvars);
      (cr, negate) = BackendVariable.getAlias(var);
      e = DAE.CREF(cr, tp);
      e = if negate then Expression.negate(e) else e;
      (e, _) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT(idn), {e}, attr));
      (e, _) = Expression.traverseExpBottomUp(e, traverserExpsimplifyTimeIndepFuncCalls, (globalKnownVars, aliasvars, false));
    then (e, (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={DAE.CREF(componentRef=cr, ty=tp)}), (globalKnownVars, aliasvars, _)) guard idn=="change" or idn=="edge" equation
      (_::_, _) = BackendVariable.getVar(cr, globalKnownVars);
      zero = Expression.arrayFill(Expression.arrayDimension(tp), DAE.BCONST(false));
    then (zero, (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={DAE.CREF(componentRef=cr, ty=tp)}), (globalKnownVars, aliasvars, _)) guard idn=="change" or idn=="edge" equation
      (_::_, _) = BackendVariable.getVar(cr, aliasvars);
      zero = Expression.arrayFill(Expression.arrayDimension(tp), DAE.BCONST(false));
    then (zero, (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))}), (globalKnownVars, aliasvars, _)) guard idn=="change" or idn=="edge"
    then (DAE.BCONST(false), (globalKnownVars, aliasvars, true));

    case (DAE.CALL(path=Absyn.IDENT(name=idn), expLst={DAE.CREF(componentRef=cr, ty=tp)}, attr=attr), (globalKnownVars, aliasvars, _)) guard idn=="change" or idn=="edge" equation
      (var, _) = BackendVariable.getVarSingle(cr, aliasvars);
      (cr, negate) = BackendVariable.getAlias(var);
      e = DAE.CREF(cr, tp);
      e = if negate then Expression.negate(e) else e;
      (e, _) = ExpressionSimplify.simplify(DAE.CALL(Absyn.IDENT(idn), {e}, attr));
      (e, _) = Expression.traverseExpBottomUp(e, traverserExpsimplifyTimeIndepFuncCalls, (globalKnownVars, aliasvars, false));
    then (e, (globalKnownVars, aliasvars, true));

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
  BackendDAEUtil.traverseBackendDAEExpsVarsWithUpdate(shared.globalKnownVars, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.globalKnownVars, shared.aliasVars, false)));
  BackendDAEUtil.traverseBackendDAEExpsEqns(shared.initialEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.globalKnownVars, shared.aliasVars, false)));
  BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.globalKnownVars, shared.aliasVars, false)));
  (shared.eventInfo, _) := traverseEventInfoExps(shared.eventInfo, Expression.traverseSubexpressionsHelper, (traverserExpsimplifyTimeIndepFuncCalls, (shared.globalKnownVars, shared.aliasVars, false)));
  outDAE := BackendDAE.DAE(inDAE.eqs, shared);
end simplifyTimeIndepFuncCallsShared;

protected function traverseEventInfoExps<T>
  input output BackendDAE.EventInfo eventInfo;
  input FuncExpType func;
  input output T arg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output T outA;
  end FuncExpType;
algorithm
  arg := DoubleEndedList.mapFoldNoCopy(eventInfo.zeroCrossings.zc, function traverseZeroCrossingExps(func=func), arg);
  arg := DoubleEndedList.mapFoldNoCopy(eventInfo.samples.zc, function traverseZeroCrossingExps(func=func), arg);
  arg := DoubleEndedList.mapFoldNoCopy(eventInfo.relations, function traverseZeroCrossingExps(func=func), arg);
end traverseEventInfoExps;

protected function traverseZeroCrossingExps<T>
  input output BackendDAE.ZeroCrossing zc;
  input FuncExpType func;
  input output T arg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output T outA;
  end FuncExpType;
algorithm
  (zc, arg) := match zc
    local
      DAE.Exp relation1, relation2;
      list<Integer> occurEquLst;

    case BackendDAE.ZERO_CROSSING(relation1, occurEquLst)
      equation
        (relation2, arg) = Expression.traverseExpBottomUp(relation1, func, arg);
      then (if referenceEq(relation1, relation2) then BackendDAE.ZERO_CROSSING(relation2, occurEquLst) else zc, arg);
  end match;
end traverseZeroCrossingExps;

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
      BackendDAE.Variables vars,globalKnownVars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<BackendDAE.Var> vlst;

    case (e as DAE.CREF(DAE.CREF_IDENT(ident = "time",subscriptLst = {}),_), (_,vars,globalKnownVars,b1,b2))
      then (e,false,(true,vars,globalKnownVars,b1,b2));
    // inputs not constant and parameter(fixed=false) are constant but evaluated after konstant variables are evaluted
    case (e as DAE.CREF(cr,_), (_,vars,globalKnownVars,b1,b2))
      equation
        (vlst,_::_)= BackendVariable.getVar(cr, globalKnownVars) "input variables stored in known variables are input on top level";
        false = List.mapAllValueBool(vlst,toplevelInputOrUnfixed,false);
      then (e,false,(true,vars,globalKnownVars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {_,_,_}), (_,vars,globalKnownVars,b1,b2)) then (e,false,(true,vars,globalKnownVars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {_}), (_,vars,globalKnownVars,b1,b2)) then (e,false,(true,vars,globalKnownVars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "previous"), expLst = {_}), (_,vars,globalKnownVars,b1,b2)) then (e,false,(true,vars,globalKnownVars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "change"), expLst = {_}), (_,vars,globalKnownVars,b1,b2)) then (e,false,(true,vars,globalKnownVars,b1,b2));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "edge"), expLst = {_}), (_,vars,globalKnownVars,b1,b2)) then (e,false,(true,vars,globalKnownVars,b1,b2));
    // case for finding simple equation in jacobians
    // there are all known variables mark as input
    // and they are all time-depending
    case (e as DAE.CREF(cr,_), (_,vars,globalKnownVars,true,b2))
      equation
        (var::_,_::_)= BackendVariable.getVar(cr, globalKnownVars);
        DAE.INPUT() = BackendVariable.getVarDirection(var);
      then (e,false,(true,vars,globalKnownVars,true,b2));
    // unkown var
    case (e as DAE.CREF(cr,_), (_,vars,globalKnownVars,b1,true))
      equation
        (_::_,_::_)= BackendVariable.getVar(cr, vars);
      then (e,false,(true,vars,globalKnownVars,b1,true));
    case (e,(b,_,_,_,_)) then (e,not b,inTpl);

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
       (_,(_,n)) = AdjacencyMatrix.traverseAdjacencyMatrix(inM,countSimpleEquationsFinder,(dlow,0));
      then n;
  end match;
end countSimpleEquations;

protected function countSimpleEquationsFinder
"author: Frenkel TUD 2011-05"
 input BackendDAE.IncidenceMatrixElement elem;
 input Integer pos;
 input tuple<BackendDAE.BackendDAE,Integer> inTpl;
 output list<Integer> outList;
 output tuple<BackendDAE.BackendDAE,Integer> outTpl;
algorithm
  (outList,outTpl) :=
  matchcontinue (elem,pos,inTpl)
    local
      Integer l,i,n,n_1;
      BackendDAE.BackendDAE dae;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;

    case (_,_,(dae as BackendDAE.DAE({syst},shared),n))
      equation
        // check number of vars in eqns
        l = listLength(elem);
        true = intLt(l,3);
        true = intGt(l,0);
        countsimpleEquation(elem,l,pos,syst,shared);
        n_1 = n+1;
      then ({},(dae,n_1));
    else ({},inTpl);
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
      BackendDAE.Variables vars,globalKnownVars;
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
        eqn = BackendEquation.get(eqns,pos);
        BackendDAE.EQUATION(exp=e1,scalar=e2) = eqn;
        // variable time not there
        globalKnownVars = BackendVariable.daeGlobalKnownVars(shared);
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,globalKnownVars,true,false));
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,globalKnownVars,true,false));
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
        eqn = BackendEquation.get(eqns,pos);
        BackendDAE.EQUATION(exp=e1,scalar=e2) = eqn;
        // variable time not there
        globalKnownVars = BackendVariable.daeGlobalKnownVars(shared);
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e1, traversingTimeEqnsFinder, (false,vars,globalKnownVars,false,false));
        (_,(false,_,_,_,_)) = Expression.traverseExpTopDown(e2, traversingTimeEqnsFinder, (false,vars,globalKnownVars,false,false));
        cr = BackendVariable.varCref(var);
        cre = Expression.crefExp(cr);
        (_,{}) = ExpressionSolve.solve(e1,e2,cre);
      then ();
    // a = der(b)
    case ({_,_},_,_,_,_)
      equation
        eqns = BackendEquation.getEqnsFromEqSystem(syst);
        eqn = BackendEquation.get(eqns,pos);
        (cr,_,_,_,_) = BackendEquation.derivativeEquation(eqn);
        // select candidate
        vars = BackendVariable.daeVars(syst);
        ((_::_),(_::_)) = BackendVariable.getVar(cr,vars);
      then ();
    // a = b
    case ({_,_},_,_,_,_)
      equation
        eqns = BackendEquation.getEqnsFromEqSystem(syst);
        (eqn as BackendDAE.EQUATION()) = BackendEquation.get(eqns,pos);
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
      BackendDAE.Variables globalKnownVars;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(systs, shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars)))
      algorithm
        repl := BackendVarTransform.emptyReplacements();
        ((repl, _)) := BackendVariable.traverseBackendDAEVars(globalKnownVars, removeParametersFinder, (repl, globalKnownVars));
        (globalKnownVars, repl) := replaceFinalVars(1, globalKnownVars, repl);
        (globalKnownVars, repl) := replaceFinalVars(1, globalKnownVars, repl);
        if Flags.isSet(Flags.DUMP_PARAM_REPL) then
          BackendVarTransform.dumpReplacements(repl);
        end if;
        systs := List.map1(systs,removeParameterswork, repl);
        shared.globalKnownVars := globalKnownVars;
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

    case (v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp)),(repl,vars))
      equation
        (exp1, _) = Expression.traverseExpBottomUp(exp, BackendDAEUtil.replaceCrefsWithValues, (vars, varName));
        repl_1 = BackendVarTransform.addReplacement(repl, varName, exp1,NONE());
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
      BackendDAE.Variables globalKnownVars,globalKnownVars1,globalKnownVars2;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;

    case(numrepl,globalKnownVars,repl)
      equation
      true = intEq(0,numrepl);
    then (globalKnownVars,repl);

    case(_,globalKnownVars,repl)
      equation
      (globalKnownVars1, (repl1,numrepl)) = BackendVariable.traverseBackendDAEVarsWithUpdate(globalKnownVars,replaceFinalVarTraverser,(repl,0));
      (globalKnownVars2, repl2) = replaceFinalVars(numrepl,globalKnownVars1,repl1);
    then (globalKnownVars2,repl2);

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
      BackendDAE.Variables globalKnownVars;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
    case BackendDAE.DAE(systs, shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars))
      algorithm
        repl := BackendVarTransform.emptyReplacements();
        repl := BackendVariable.traverseBackendDAEVars(globalKnownVars, protectedParametersFinder, repl);
        if Flags.isSet(Flags.DUMP_PP_REPL) then
          BackendVarTransform.dumpReplacements(repl);
        end if;
        systs := List.map1(systs, removeProtectedParameterswork, repl);
        shared.globalKnownVars := globalKnownVars;
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

    case syst as BackendDAE.EQSYSTEM(orderedEqs=eqns)
      algorithm
        lsteqns := BackendEquation.equationList(eqns);
        (lsteqns, b) := BackendVarTransform.replaceEquations(lsteqns, repl, NONE());
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
    case (v as BackendDAE.VAR(varName=varName,varKind=BackendDAE.PARAM(),bindExp=SOME(exp),values=values),repl)
      equation
        true = DAEUtil.getProtectedAttr(values);
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
        (m, (mT,_,_,changed)) := AdjacencyMatrix.traverseAdjacencyMatrix(m, removeEqualFunctionCallFinder, (mT,vars,eqns,{}));
        // update arrayeqns and algorithms, collect info for wrappers
        syst.m := SOME(m); syst.mT := SOME(mT); syst.matching := BackendDAE.NO_MATCHING();
        syst := BackendDAEUtil.updateIncidenceMatrix(syst, BackendDAE.NORMAL(), NONE(), changed);
      then (syst, ishared);
  end match;
end removeEqualFunctionCallsWork;

protected function removeEqualFunctionCallFinder "author: Frenkel TUD 2010-12"
  input BackendDAE.IncidenceMatrixElement elem;
  input Integer pos;
  input tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>> inTpl;
  output list<Integer> outList;
  output tuple<BackendDAE.IncidenceMatrixT,BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>> outTpl;
algorithm
  (outList,outTpl):=
  matchcontinue (elem,pos,inTpl)
    local
      BackendDAE.IncidenceMatrix mT;
      list<Integer> changed;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      DAE.Exp exp,e1,e2,ecr;
      AvlSetInt.Tree expvars;
      list<Integer> controleqns,expvars1;
      list<list<Integer>> expvarseqns;

    case (_,_,(mT,vars,eqns,changed))
      equation
        // check number of vars in eqns
        _::_ = elem;
        BackendDAE.EQUATION(exp=e1,scalar=e2) = BackendEquation.get(eqns,pos);
        // BackendDump.debugStrExpStrExpStr(("Test ",e1," = ",e2,"\n"));
        (ecr,exp) = functionCallEqn(e1,e2,vars);
        // TODO: Handle this with alias-equations instead?; at least they don't replace back to the original expression...
        // failure(DAE.CREF(componentRef=_) = exp);
        // failure(DAE.UNARY(operator=DAE.UMINUS(ty=_),exp=DAE.CREF(componentRef=_)) = exp);
        // BackendDump.debugStrExpStrExpStr(("Found ",ecr," = ",exp,"\n"));
        expvars = BackendDAEUtil.incidenceRowExp(exp,vars,AvlSetInt.EMPTY(),NONE(),BackendDAE.NORMAL());
        // print("expvars "); BackendDump.debuglst((expvars,intString," ","\n"));
        (expvars1::expvarseqns) = List.map2(AvlSetInt.listKeys(expvars),varEqns,pos,mT);
        // print("expvars1 "); BackendDump.debuglst((expvars1,intString," ","\n"));;
        controleqns = getControlEqns(expvars1,expvarseqns);
        // print("controleqns "); BackendDump.debuglst((controleqns,intString," ","\n"));
        (eqns1,changed) = removeEqualFunctionCall(controleqns,ecr,exp,eqns,changed);
        //print("changed1 "); BackendDump.debuglst((changed1,intString," ","\n"));
        //print("changed2 "); BackendDump.debuglst((changed2,intString," ","\n"));
        // print("Next\n");
      then ({},(mT,vars,eqns1,changed));
    case (_,_,_)
      then ({},inTpl);
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
  input Integer pos;
  input BackendDAE.IncidenceMatrixT mT;
  output list<Integer> outVarEqns;
protected
  list<Integer> vareqns,vareqns1;
algorithm
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
        eqn = BackendEquation.get(inEqns,pos);
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
      BackendDAE.Variables globalKnownVars, globalKnownVars1;
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;

    case BackendDAE.DAE(eqs, shared)
      algorithm
        globalKnownVars1 := BackendVariable.emptyVars();
        globalKnownVars := shared.globalKnownVars;
        globalKnownVars1 := BackendVariable.traverseBackendDAEVars(globalKnownVars, copyNonParamVariables, globalKnownVars1);
        ((_, globalKnownVars1)) := List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem, checkUnusedVariables, (globalKnownVars,globalKnownVars1));
        ((_, globalKnownVars1)) := BackendDAEUtil.traverseBackendDAEExpsVars(globalKnownVars, checkUnusedParameter, (globalKnownVars,globalKnownVars1));
        ((_, globalKnownVars1)) := BackendDAEUtil.traverseBackendDAEExpsVars(shared.aliasVars, checkUnusedParameter, (globalKnownVars,globalKnownVars1));
        ((_, globalKnownVars1)) := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, checkUnusedParameter, (globalKnownVars,globalKnownVars1));
        ((_, globalKnownVars1)) := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.initialEqs, checkUnusedParameter, (globalKnownVars,globalKnownVars1));
        shared.globalKnownVars := globalKnownVars1;
      then
        BackendDAE.DAE(eqs, shared);
  end match;
end removeUnusedParameter;

protected function copyNonParamVariables
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVars;
  output BackendDAE.Var outVar;
  output BackendDAE.Variables outVars;
algorithm
  (outVar,outVars) := match (inVar,inVars)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
    case (v as BackendDAE.VAR(varKind = BackendDAE.PARAM()),_)
      then (v,inVars);
    else
      equation
        vars1 = BackendVariable.addVar(inVar,inVars);
      then (inVar,vars1);
  end match;
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
    case (exp,(vars,_))
      equation
         (_,(_,vars1)) = Expression.traverseExpBottomUp(exp,checkUnusedParameterExp,inTpl);
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
      tuple<BackendDAE.Variables,BackendDAE.Variables> tp;

    // special case for time, it is never part of the equation system
    case (e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(_,_))
      then (e, inTuple);

    // Special Case for Records
    case (e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),tp)
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (_,tp) = Expression.traverseExpList(expl,checkUnusedParameterExp,tp);
      then (e, tp);

    // Special Case for Arrays
    case (e as DAE.CREF(ty = DAE.T_ARRAY()),tp)
      equation
        (e1,true) = Expression.extendArrExp(e,false);
        (_,tp) = Expression.traverseExpBottomUp(e1,checkUnusedParameterExp,tp);
      then (e, tp);

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
  This function removes unused variables
  from BackendDAE.BackendDAE to get speed up for compilation of
  target code"
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
algorithm
  outDlow := match inDlow
    local
      BackendDAE.Variables globalKnownVars, globalKnownVars1;
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;
      tuple<BackendDAE.Variables,BackendDAE.Variables> tpl;

    case BackendDAE.DAE(eqs, shared)
      algorithm
        globalKnownVars1 := BackendVariable.emptyVars();
        globalKnownVars := shared.globalKnownVars;
        tpl := List.fold1(eqs,BackendDAEUtil.traverseBackendDAEExpsEqSystem, checkUnusedVariables, (globalKnownVars, globalKnownVars1));
        tpl := BackendDAEUtil.traverseBackendDAEExpsVars(globalKnownVars, checkUnusedVariables, tpl);
        tpl := BackendDAEUtil.traverseBackendDAEExpsVars(shared.aliasVars, checkUnusedVariables, tpl);
        tpl := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, checkUnusedVariables, tpl);
        ((_, globalKnownVars1)) := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.initialEqs, checkUnusedVariables, tpl);
        shared.globalKnownVars := globalKnownVars1;
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
      tuple<BackendDAE.Variables,BackendDAE.Variables> tpl;
    case (exp,_)
      equation
         (_,tpl) = Expression.traverseExpBottomUp(exp,checkUnusedVariablesExp,inTpl);
       then (exp,tpl);
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
      tuple<BackendDAE.Variables,BackendDAE.Variables> tp;

    // special case for time, it is never part of the equation system
    case (e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),tp)
      then (e, tp);

    // Special Case for Records
    case (e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),tp)
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (_,tp) = Expression.traverseExpList(expl,checkUnusedVariablesExp,tp);
      then (e, tp);

    // Special Case for Arrays
    case (e as DAE.CREF(ty = DAE.T_ARRAY()),tp)
      equation
        (e1,true) = Expression.extendArrExp(e,false);
        (_,tp) = Expression.traverseExpBottomUp(e1,checkUnusedVariablesExp,tp);
      then (e, tp);

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
  input BackendDAE.EqSystems inEqs;
  input BackendDAE.Shared inShared;
  input list<BackendDAE.Equation> inEquationLst;
  input DAE.FunctionTree inFunctionTree;
  input DAE.FunctionTree inusedFunctions;
  output DAE.FunctionTree outFunctionTree;
protected
  partial function FuncType
    input DAE.Exp inExp;
    input DAE.FunctionTree inUnsedFunctions;
    output DAE.Exp outExp;
    output DAE.FunctionTree outUsedFunctions;
  end FuncType;

  FuncType func;
  DAE.FunctionTree funcs, usedfuncs;
algorithm
  funcs := inFunctionTree;
  usedfuncs := inusedFunctions;
  func := function checkUnusedFunctions(inFunctions = funcs);

  // equation system
  usedfuncs := List.fold1(inEqs, BackendDAEUtil.traverseBackendDAEExpsEqSystem, func, usedfuncs);
  usedfuncs := List.fold1(inEqs, BackendDAEUtil.traverseBackendDAEExpsEqSystemJacobians, func, usedfuncs);

  // equation list
  usedfuncs := List.fold1(inEquationLst, BackendEquation.traverseExpsOfEquationList_WithoutChange, func, usedfuncs);

  // shared object
  usedfuncs := BackendDAEUtil.traverseBackendDAEExpsVars(inShared.globalKnownVars, func, usedfuncs);
  usedfuncs := BackendDAEUtil.traverseBackendDAEExpsVars(inShared.externalObjects, func, usedfuncs);
  usedfuncs := BackendDAEUtil.traverseBackendDAEExpsVars(inShared.aliasVars, func, usedfuncs);
  usedfuncs := BackendDAEUtil.traverseBackendDAEExpsEqns(inShared.removedEqs, func, usedfuncs);
  usedfuncs := BackendDAEUtil.traverseBackendDAEExpsEqns(inShared.initialEqs, func, usedfuncs);
  usedfuncs := removeUnusedFunctionsSymJacs(inShared.symjacs, funcs, usedfuncs);

  outFunctionTree := usedfuncs;
end removeUnusedFunctions;

public function copyRecordConstructorAndExternalObjConstructorDestructor
  input DAE.FunctionTree inFunctions;
  output DAE.FunctionTree outFunctions;
protected
  list<DAE.Function> funcelems;
algorithm
  funcelems := DAEUtil.getFunctionList(inFunctions);
  outFunctions := List.fold(funcelems,copyRecordConstructorAndExternalObjConstructorDestructorFold,DAE.AvlTreePathFunction.Tree.EMPTY());
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
         funcs1 = DAE.AvlTreePathFunction.add(funcs, path, SOME(f));
       then
        funcs1;
    // copy external objects constructors/destructors
    case (f as DAE.FUNCTION(path = path),funcs)
      equation
         true = boolOr(
                  stringEq(Absyn.pathLastIdent(path), "constructor"),
                  stringEq(Absyn.pathLastIdent(path), "destructor"));
         funcs1 = DAE.AvlTreePathFunction.add(funcs, path, SOME(f));
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
        BackendDAE.Shared shared;

      case (SOME((bdae, _, _, _, _, _)), _, _)
        equation
          bdae = BackendDAEUtil.setFunctionTree(bdae, inFunctions);
          shared = bdae.shared;
          usedfuncs = removeUnusedFunctions(bdae.eqs, shared, {}, shared.functionTree, inUsedFunctions);
          outUsedFunctions = DAE.AvlTreePathFunction.join(outUsedFunctions, usedfuncs);
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
        DAE.T_FUNCTION(path=path)))
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
    _ := DAE.AvlTreePathFunction.get(inUsedFunctions, inPath);
  else // Otherwise, try to add it.
    (f, body) := getFunctionAndBody(inPath, inFunctions);

    if isSome(f) then
      outUsedFunctions := DAE.AvlTreePathFunction.add(outUsedFunctions, inPath, f);
      (_, outUsedFunctions) := DAEUtil.traverseDAEElementList(body,
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
    outFn as SOME(fn) := DAE.AvlTreePathFunction.get(fns, inPath);
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
  Integer sz;
  BackendDAE.Variables vars;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  vars := BackendVariable.emptyVarsSized(integer(sum(BackendVariable.varsSize(s.orderedVars) for s in systs)*1.4));
  // We can use listReduce as if there is no eq-system something went terribly wrong
  syst := List.fold(listReverse(systs), mergeIndependentBlocks, BackendDAEUtil.createEqSystem(vars));
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
  vars := BackendVariable.addVariables(syst1.orderedVars, syst2.orderedVars);
  eqs := BackendEquation.addList(BackendEquation.equationList(syst1.orderedEqs), syst2.orderedEqs);
  removedEqs := BackendEquation.addList(BackendEquation.equationList(syst1.removedEqs), syst2.removedEqs);
  stateSets := listAppend(syst1.stateSets, syst2.stateSets);
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
      BackendDAE.IncidenceMatrix m, mT, rm, rmT;
      array<Integer> eqPartMap, varPartMap, rixs;
      array<Boolean> vars, rvars;
      Boolean b;
      Integer i;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;
    case (syst,shared,_,_)
      equation
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst, m, mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.NORMAL(), SOME(funcs));
        (rm, rmT) = BackendDAEUtil.removedIncidenceMatrix(syst, BackendDAE.NORMAL(), SOME(funcs));
        eqPartMap = arrayCreate(arrayLength(m), 0);
        varPartMap = arrayCreate(arrayLength(mT), 0);
        rixs = arrayCreate(arrayLength(rm), 0);
        vars = arrayCreate(arrayLength(mT), false);
        rvars = arrayCreate(arrayLength(rmT), false);
        // ixsT = arrayCreate(arrayLength(mT),0);
        i = SynchronousFeatures.partitionIndependentBlocks0(m, mT, rm, rmT, eqPartMap, varPartMap, rixs, vars, rvars);
        // i2 = SynchronousFeatures.partitionIndependentBlocks0(mT,m,ixsT);
        b = i > 1;
        // bcall2(b,BackendDump.dumpBackendDAE,BackendDAE.DAE({syst},shared), "partitionIndependentBlocksHelper");
        // printPartition(b,ixs);
        systs = if b then SynchronousFeatures.partitionIndependentBlocksSplitBlocks(i, syst, eqPartMap, rixs, mT, rmT, throwNoError, funcs) else {syst};
        // print("Number of partitioned systems: " + intString(listLength(systs)) + "\n");
        // List.map1_0(systs, BackendDump.dumpEqSystem, "System");
        GC.free(eqPartMap);
        GC.free(varPartMap);
        GC.free(rixs);
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
        source = ElementSource.addSymbolicTransformation(source, DAE.OP_RESIDUAL(e1,e2,e));
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
      Integer eqIdx, numAdd,numMul,numDiv,numTrig,numRel,numOth, numFuncs, numLog, size, jacEntries;
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
      BackendDAE.InnerEquations innerEquations;
      list<Integer> vlst;
      list<list<Integer>> vLstLst;
    case ({},_,_,_) then compInfosIn;
    case (BackendDAE.SINGLEEQUATION(eqn=eqIdx)::rest,_,_,_)
      equation
        eqns = BackendEquation.getEqnsFromEqSystem(isyst);
        eqn = BackendEquation.get(eqns, eqIdx);
          //BackendDump.dumpBackendDAEEqnList({eqn},"AN EQUATION",true);
        //BackendDump.dumpEquationList({eqn},"");
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        compInfo = BackendDAE.COUNTER(listHead(inComps),numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        if Flags.isSet(Flags.COUNT_OPERATIONS) then BackendDump.dumpCompInfo(compInfo); end if;
      then countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case (BackendDAE.SINGLEWHENEQUATION(eqn=eqIdx)::rest,_,_,_)
      equation
         eqn = BackendEquation.get(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
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
        jacEntries = getNumJacEntries(jac);
        if intEq(jacEntries,-1) then jacEntries = size*size; end if;  // a non linear system that is too small and too dense (usually 2x2) to be torn
        density = realDiv(intReal(jacEntries),intReal(size*size));
        compInfo = BackendDAE.SYSTEM(comp,allOps,size,density);
      then
        countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLEARRAY(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.get(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLEIFEQUATION(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.get(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog+1,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLEALGORITHM(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.get(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog+1,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case ((comp as BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqIdx))::rest,_,_,_)
      equation
         eqn = BackendEquation.get(BackendEquation.getEqnsFromEqSystem(isyst), eqIdx);
         (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = BackendEquation.traverseExpsOfEquation(eqn,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
         compInfo = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog+1,numOth,numFuncs);
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst, residualequations=tornEqs, innerEquations= innerEquations), linear = true)::rest,_,BackendDAE.SHARED(functionTree=funcs),_)
      equation
        comp = listHead(inComps);
        eqns = BackendEquation.getEqnsFromEqSystem(isyst);
        vars = BackendVariable.daeVars(isyst);
        // the torn equations
        eqnlst = BackendEquation.getList(tornEqs,eqns);
        varlst = List.map1(vlst,BackendVariable.getVarAtIndexFirst, vars);
        (explst,_) = BackendDAEUtil.getEqnSysRhs(BackendEquation.listEquation(eqnlst),BackendVariable.listVar1(varlst),SOME(funcs));
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = Expression.traverseExpList(explst,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        torn = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        // the other eqs
        (otherEqs,vLstLst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        vlst = List.flatten(vLstLst);
        eqnlst = BackendEquation.getList(otherEqs,eqns);
        varlst = List.map1(vlst,BackendVariable.getVarAtIndexFirst, vars);
        (explst,_) = BackendDAEUtil.getEqnSysRhs(BackendEquation.listEquation(eqnlst),BackendVariable.listVar1(varlst),SOME(funcs));
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = Expression.traverseExpList(explst,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        other = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        compInfo = BackendDAE.TORN_ANALYSE(comp,torn,other,listLength(tornEqs));
      then
         countOperationstraverseComps(rest,isyst,ishared,compInfo::compInfosIn);
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=tornEqs, innerEquations = innerEquations), linear = false)::rest,_,BackendDAE.SHARED(),_)
      equation
        comp = listHead(inComps);
        eqns = BackendEquation.getEqnsFromEqSystem(isyst);
        _ = BackendVariable.daeVars(isyst);
        // the torn equations
        eqnlst = BackendEquation.getList(tornEqs,eqns);
        explst = List.map(eqnlst,BackendEquation.getEquationRHS);
        (_,(numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs)) = Expression.traverseExpList(explst,function countOperationsExp(shared=ishared),(0,0,0,0,0,0,0,0));
        torn = BackendDAE.COUNTER(comp,numAdd,numMul,numDiv,numTrig,numRel,numLog,numOth,numFuncs);
        // the other eqs
        (otherEqs,_,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        eqnlst = BackendEquation.getList(otherEqs,eqns);
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
  numEntries := match inJac
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<BackendDAE.Var> vars1, vars2;
      case BackendDAE.FULL_JACOBIAN(NONE())
        then -1;
      case BackendDAE.FULL_JACOBIAN(SOME(jac))
        then listLength(jac);
      case BackendDAE.EMPTY_JACOBIAN()
        then -1;
      /* TODO: implement/check for GENERIC_JACOBIAN */
      case BackendDAE.GENERIC_JACOBIAN(jacobian=NONE())
        then -1;
      case BackendDAE.GENERIC_JACOBIAN(jacobian=SOME((_,_,vars1,vars2,_,_)))
        guard
          listLength(vars1) == listLength(vars2)
        then listLength(vars1);
      else
        equation
          //print(BackendDump.jacobianString(inJac));
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
      (_,tpl) = traversecountOperationsExp(exp1,shared,inTuple);
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

    case (e as DAE.CALL(path=Absyn.IDENT(name=opName)),_,(i1,i2,i3,i4,i5,i6,i7,i8))
      guard stringEq(opName,"sin") or stringEq(opName,"cos") or stringEq(opName,"tan")
      then (e, (i1,i2,i3,i4+1,i5,i6,i7,i8));

    case (e as DAE.CALL(path=Absyn.IDENT(name="der")),_,(i1,i2,i3,i4,i5,i6,i7,i8))
      then (e, (i1,i2,i3,i4,i5,i6,i7,i8));

    case (e as DAE.CALL(path=Absyn.IDENT(name="exp")),_,(i1,i2,i3,i4,i5,i6,i7,i8))
      then (e, (i1,i2,i3,i4,i5,i6,i7+1,i8));

    case (e as DAE.CALL(path=Absyn.IDENT(name="pre")),_,(i1,i2,i3,i4,i5,i6,i7,i8))
      then (e, (i1,i2,i3,i4,i5,i6,i7,i8+1));

    case (e as DAE.CALL(path=Absyn.IDENT(name="previous")),_,(i1,i2,i3,i4,i5,i6,i7,i8))
      then (e, (i1,i2,i3,i4,i5,i6,i7,i8+1));

    case (e as DAE.CALL(path=path),_,_) equation
      func = DAEUtil.getNamedFunction(path,BackendDAEUtil.getFunctions(shared));
      elemLst = DAEUtil.getFunctionElements(func);
      //print(ExpressionDump.dumpExpStr(e,0)+"\n");
      //print("THE FUNCTION CALL\n "+DAEDump.dumpElementsStr(elemLst)+"\n");
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
      then (i1+i,i2,i3,i4,i5,i6,i7,i8);
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
    case (DAE.MUL_ARRAY_SCALAR(),(i1,i2,i3,i4,i5,i6,i7,i8))
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
      then (i1,i2,i3,i4,i5,i6+1,i7,i8);
    case (DAE.NOT(),(i1,i2,i3,i4,i5,i6,i7,i8))
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
      BackendDAE.Variables vars, globalKnownVars;
      BackendDAE.EquationArray eqns, initialEqs;
      list<BackendDAE.Equation> eqnslst, asserts;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Boolean systChanged;

    case ( syst as BackendDAE.EQSYSTEM(orderedEqs=eqns),
           shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars, initialEqs=initialEqs) )
      algorithm
        // traverse the equations
        eqnslst := BackendEquation.equationList(eqns);
        // traverse equations in reverse order, than branch equations of if equaitions need no reverse
        ((eqnslst,asserts,systChanged)) := List.fold31(listReverse(eqnslst), simplifyIfEquationsFinder, globalKnownVars, {},{},false);
        syst.orderedEqs := BackendEquation.listEquation(eqnslst);

        // traverse the initial equations
        eqnslst := BackendEquation.equationList(initialEqs);
        // traverse equations in reverse order, than branch equations of if equaitions need no reverse
        ((eqnslst,asserts,true)) := List.fold31(listReverse(eqnslst), simplifyIfEquationsFinder, globalKnownVars, {},{},systChanged);
        shared.initialEqs := BackendEquation.listEquation(eqnslst);

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
  input output list<BackendDAE.Equation> acc;
  input output list<BackendDAE.Equation> asserts;
  input output Boolean b;
algorithm
  (acc, asserts, b) := matchcontinue(inElem,inConstArg)
    local
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqnslst,asserts1;
      list<list<BackendDAE.Equation>> eqnslstlst;
      DAE.ElementSource source;
      BackendDAE.Variables globalKnownVars;
      BackendDAE.Equation eqn;
      BackendDAE.EquationAttributes attr;

    case (BackendDAE.IF_EQUATION(conditions=explst, eqnstrue=eqnslstlst, eqnsfalse=eqnslst, source=source, attr=attr), globalKnownVars)
      equation
        // check conditions
        (explst,_) = Expression.traverseExpList(explst, simplifyEvaluatedParamter, (globalKnownVars,false));
        explst = ExpressionSimplify.simplifyList(explst);
        // simplify if equation
        (acc,asserts1) = simplifyIfEquation(explst,eqnslstlst,eqnslst,{},{},source,globalKnownVars,acc,attr);
        asserts = listAppend(asserts,asserts1);
      then
        (acc, asserts, true);

    case (eqn,globalKnownVars)
      equation
        (eqn,(_,b)) = BackendEquation.traverseExpsOfEquation(eqn, simplifyIfExpevaluatedParamter, (globalKnownVars,b));
      then
        (eqn::acc,asserts,b);
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
      BackendDAE.Variables globalKnownVars;
      DAE.Exp e1,e2,cond,expThen,expElse;
      Boolean b,b1;
    case (e1 as DAE.IFEXP(expCond=cond, expThen=expThen, expElse=expElse),(globalKnownVars,b))
      equation
        (cond,(_,b1)) = Expression.traverseExpBottomUp(cond, simplifyEvaluatedParamter, (globalKnownVars,false));
        e2 = if b1 then DAE.IFEXP(cond,expThen,expElse) else e1;
        (e2,_) = ExpressionSimplify.condsimplify(b1,e2);
      then (e2,(globalKnownVars,b or b1));
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
      BackendDAE.Variables globalKnownVars;
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      DAE.Exp e;
    case (DAE.CREF(componentRef = cr),(globalKnownVars,_))
      equation
        (v,_) = BackendVariable.getVarSingle(cr,globalKnownVars);
        true = BackendVariable.isFinalVar(v);
        e = BackendVariable.varBindExpStartValue(v);
      then (e,(globalKnownVars,true));
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
  input BackendDAE.Variables globalKnownVars;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.EquationAttributes inEqAttr;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outAsserts;
algorithm
  (outEqns,outAsserts) := match(conditions,theneqns,elseenqs,conditions1,theneqns1,source,globalKnownVars,inEqns,inEqAttr)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns,elseenqs1,asserts;

    // no true case left with condition<>false
    case ({},{},_,{},{},_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold31(listReverse(elseenqs), simplifyIfEquationsFinder, globalKnownVars, {},{},false);
      then
        (listAppend(eqns,inEqns),asserts);
    // true case left with condition<>false
    case ({},{},_,_,_,_,_,_,_)
      equation
        explst = listReverse(conditions1);
        eqnslst = listReverse(theneqns1);
        // simplify nested if equations
        ((elseenqs1,asserts,_)) = List.fold31(listReverse(elseenqs), simplifyIfEquationsFinder, globalKnownVars, {},{},false);
        elseenqs1 = listAppend(elseenqs1,asserts);
        (eqnslst,elseenqs1,asserts) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs1,{},{},{});
        eqns = simplifyIfEquation1(explst,eqnslst,elseenqs1,source,globalKnownVars,inEqns,inEqAttr);
      then
        (eqns,asserts);
    // if true and first use it
    case(DAE.BCONST(true)::_,eqns::_,_,{},_,_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold31(listReverse(eqns), simplifyIfEquationsFinder, globalKnownVars, {},{},false);
      then
        (listAppend(eqns,inEqns),asserts);
    // if true and not first use it as new else
    case(DAE.BCONST(true)::_,eqns::_,_,_,_,_,_,_,_)
      equation
        explst = listReverse(conditions1);
        eqnslst = listReverse(theneqns1);
        // simplify nested if equations
        ((elseenqs1,asserts,_)) = List.fold31(listReverse(eqns), simplifyIfEquationsFinder, globalKnownVars, {},{},false);
        elseenqs1 = listAppend(elseenqs1,asserts);
        (eqnslst,elseenqs1,asserts) = simplifyIfEquationAsserts(explst,eqnslst,elseenqs1,{},{},{});
        eqns = simplifyIfEquation1(explst,eqnslst,elseenqs1,source,globalKnownVars,inEqns,inEqAttr);
      then
        (eqns,asserts);
    // if false skip it
    case(DAE.BCONST(false)::explst,_::eqnslst,_,_,_,_,_,_,_)
      equation
        (eqns,asserts) = simplifyIfEquation(explst,eqnslst,elseenqs,conditions1,theneqns1,source,globalKnownVars,inEqns,inEqAttr);
      then
        (eqns,asserts);
    // all other cases
    case(e::explst,eqns::eqnslst,_,_,_,_,_,_,_)
      equation
        // simplify nested if equations
        ((eqns,asserts,_)) = List.fold31(listReverse(eqns), simplifyIfEquationsFinder, globalKnownVars, {},{},false);
        eqns = listAppend(eqns,asserts);
        (eqns,asserts) = simplifyIfEquation(explst,eqnslst,elseenqs,e::conditions1,eqns::theneqns1,source,globalKnownVars,inEqns,inEqAttr);
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
  input BackendDAE.Variables globalKnownVars;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.EquationAttributes inEqAttr;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(conditions,theneqns,elseenqs,source,globalKnownVars,inEqns,inEqAttr)
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
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e)::rest,_) guard not BaseHashTable.hasKey(cr, iHt)
      equation
        false = Expression.expHasCref(e, cr);
        ht = BaseHashTable.add((cr,e), iHt);
      then
        simplifySolvedIfEqnsElse(rest,ht);
    case (BackendDAE.EQUATION(exp=DAE.UNARY(operator=DAE.UMINUS(), exp=DAE.CREF(componentRef=cr)), scalar=e)::rest,_) guard not BaseHashTable.hasKey(cr, iHt)
      equation
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
          ElementSource.getElementSourceFileInfo(source));
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
        Error.addSourceMessage(Error.IF_EQUATION_UNBALANCED_2,{str,eqstr},ElementSource.getElementSourceFileInfo(source));
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
        Error.addSourceMessage(Error.IF_EQUATION_WARNING,{str},ElementSource.getElementSourceFileInfo(source));
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
    case(BackendDAE.COMPLEX_EQUATION(left = DAE.TUPLE(expl), right = e2))
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
      DAE.Exp zeroExp;
      Integer size;

    case (_, _, {}, _, _)
      equation
        List.map_0(inExpLst2, List.assertIsEmpty);
      then {};

    case (_, _, fb::fbs, _, _)
      equation
        size = Expression.sizeOf(Expression.typeof(fb));
        tbsRest = List.map(inExpLst2, List.rest);
        rest_res = makeEquationsFromResiduals(inExp1, tbsRest, fbs, inSource, inEqAttr);
        tbsFirst = List.map(inExpLst2, listHead);
        ifexp = Expression.makeNestedIf(inExp1,tbsFirst,fb);
        if size==1 then
          eq = BackendDAE.EQUATION(DAE.RCONST(0.0), ifexp, inSource, inEqAttr);
        else
          zeroExp = Expression.createZeroExpression(Expression.typeof(fb));
          eq = BackendDAE.COMPLEX_EQUATION(size, zeroExp, ifexp, inSource, inEqAttr);
        end if;

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
  oAcc := if BaseHashTable.hasKey(key, iHt1) then iAcc else key::iAcc;
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
      BackendDAE.Variables globalKnownVars;
      BackendDAE.EquationArray inieqns, remeqns;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> lsteqns;
      Boolean b;
    case BackendDAE.DAE(systs, shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars))
      algorithm
        repl := BackendVarTransform.emptyReplacements();
        repl := BackendVariable.traverseBackendDAEVars(globalKnownVars, removeConstantsFinder, repl);
        if Flags.isSet(Flags.DUMP_CONST_REPL) then
          BackendVarTransform.dumpReplacements(repl);
        end if;

        (globalKnownVars, (repl, _)) := BackendVariable.traverseBackendDAEVarsWithUpdate(globalKnownVars, replaceFinalVarTraverser, (repl, 0));

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
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars)
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
      BackendDAEUtil.traverseBackendDAEExpsEqns(orderedEqs, traverserreplaceEdgeChange, false);
      BackendDAEUtil.traverseBackendDAEExpsEqns(removedEqs, traverserreplaceEdgeChange, false);
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
        BackendDAEUtil.traverseBackendDAEExpsEqns(remeqns, traverserreplaceEdgeChange, false);
      then BackendDAE.DAE(systs, shared);
  end match;
end replaceEdgeChangeShared;


// =============================================================================
// section for preOptModule >>removeLocalKnownVars<<
//
// =============================================================================

public function removeLocalKnownVars "Looks for equations only depending on one variable and save them in localKnownVars."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, removeLocalKnownVars2);
end removeLocalKnownVars;


public function removeLocalKnownVars2
  input output BackendDAE.EqSystem syst;
  input output BackendDAE.Shared shared;
protected
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Var potentialLocalKnownVar;
  BackendDAE.Equation potentialGlobalKnownEquation;
  BackendDAE.Variables orderedVars = syst.orderedVars;
  BackendDAE.EquationArray orderedEqs = syst.orderedEqs;
  DAE.Exp lhs;
  DAE.Exp rhs;
  DAE.Exp crefExp;
  DAE.Exp binding;
  list<Integer> localKnownVars={};
  list<Integer> localKnownEqns={};
  Integer eindex=0;
  Integer vindex;
algorithm
  (_,m,_,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(syst, BackendDAE.NORMAL(),NONE());

  // Delete negative entries from incidence matrix
  m := Array.map(m,Tearing.deleteNegativeEntries);

  for row in m loop
    eindex := eindex+1;
    if listLength(row) == 1 then
      {vindex} := row;
      //print("Variable: " + intString(vindex) + "\n");
      //print("Equation: " + intString(eindex) + "\n\n");

      potentialLocalKnownVar := BackendVariable.getVarAt(orderedVars,vindex);
      potentialGlobalKnownEquation := BackendEquation.get(orderedEqs,eindex);

      try
        BackendDAE.EQUATION(exp = lhs, scalar = rhs) := potentialGlobalKnownEquation;
        crefExp := BackendVariable.varExp(potentialLocalKnownVar);
        (binding,_) := ExpressionSolve.solve(lhs,rhs,crefExp);
        potentialLocalKnownVar := BackendVariable.setBindExp(potentialLocalKnownVar, SOME(binding));
        localKnownVars := vindex::localKnownVars;
        localKnownEqns := eindex::localKnownEqns;
        shared.localKnownVars := BackendVariable.addVar(potentialLocalKnownVar, shared.localKnownVars);
      else
      end try;
    end if;
  end for;
  localKnownVars := List.sort(localKnownVars, intLt);
  localKnownEqns := listReverse(localKnownEqns);


  for var in localKnownVars loop
    orderedVars := BackendVariable.removeVar(var, orderedVars);
  end for;

  for eqn in localKnownEqns loop
    orderedEqs := BackendEquation.delete(eqn, orderedEqs);
  end for;

  // delete adjacency matrix
  syst.m := NONE();
  syst.mT := NONE();
  syst.matching := BackendDAE.NO_MATCHING();

  // TODO: remove this
  syst.orderedVars := BackendVariable.listVar(BackendVariable.varList(orderedVars));
  syst.orderedEqs := orderedEqs;
end removeLocalKnownVars2;


// =============================================================================
// section for postOptModule >>addInitialStmtsToAlgorithms<<
//
//   Real a[3];
// algorithm       -->  algorithm
//   a[1] := 1.0;         a[1] := $START.a[1];
//                        a[2] := $START.a[2];
//                        a[3] := $START.a[3];
//                        a[1] := 1.0;
// =============================================================================

public function addInitialStmtsToAlgorithms "
  section are executed in the order of appearance. Whenever an algorithm section is invoked, all variables appearing
  on the left hand side of the assignment operator := are initialized (at least conceptually):
    - A non-discrete variable is initialized with its start value (i.e. the value of the start-attribute).
    - A discrete variable v is initialized with pre(v)."
  input BackendDAE.BackendDAE inDAE;
  input Boolean isInitialSystem;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem1(inDAE, addInitialStmtsToAlgorithms1, isInitialSystem);
end addInitialStmtsToAlgorithms;

protected function addInitialStmtsToAlgorithms1 "Helper function to addInitialStmtsToAlgorithms."
  input BackendDAE.EqSystem syst;
  input Boolean isInitialSystem;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst = syst;
  output BackendDAE.Shared oshared = shared;
protected
  BackendDAE.Variables ordvars, allVars;
  BackendDAE.EquationArray ordeqns;
  BackendDAE.EquationArray initEqns;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=ordvars, orderedEqs=ordeqns) := osyst;
  BackendEquation.traverseEquationArray_WithUpdate(ordeqns, eaddInitialStmtsToAlgorithms1Helper, (ordvars, isInitialSystem));
end addInitialStmtsToAlgorithms1;

protected function eaddInitialStmtsToAlgorithms1Helper "Helper function to addInitialStmtsToAlgorithms1."
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.Variables, Boolean> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.Variables, Boolean> outTpl = inTpl;
algorithm
  (outEq) := match (inEq, inTpl)
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
      Boolean isInitialEquations;

    case (BackendDAE.ALGORITHM(size=size, alg=alg as DAE.ALGORITHM_STMTS(statements), source=source, expand=crExpand, attr=attr), (vars, isInitialEquations))
      equation
        crlst = CheckModel.checkAndGetAlgorithmOutputs(alg, source, crExpand);
        outputs = List.map(crlst, Expression.crefExp);
        statements = expandAlgorithmStmts(statements, outputs, vars, isInitialEquations);
      then BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(statements), source, crExpand, attr);

    else inEq;
  end match;
end eaddInitialStmtsToAlgorithms1Helper;

public function expandAlgorithmStmts "Helper function to eaddInitialStmtsToAlgorithms1Helper."
  input list<DAE.Statement> inAlg;
  input list<DAE.Exp> inOutputs;
  input BackendDAE.Variables inVars;
  input Boolean isInitialEquation;
  output list<DAE.Statement> outAlg;
algorithm
  outAlg := match(inAlg, inOutputs, inVars)
    local
      DAE.Exp out, initExp;
      list<DAE.Exp> rest;
      DAE.ComponentRef cref;
      list<BackendDAE.Var> vars;
      DAE.Statement stmt;
      DAE.Type type_;
      list<DAE.Statement> statements;

    case(statements, {}, _)
    then statements;

    case(statements, out::rest, _) algorithm
      cref := Expression.expCref(out);
      (vars, _) := BackendVariable.getVar(cref, inVars);
      for v in vars loop
        type_ := v.varType;
        if BackendVariable.isVarDiscrete(v) and not isInitialEquation then
          initExp := Expression.makePureBuiltinCall("pre", {Expression.crefExp(v.varName)}, type_);
        else
          initExp := Expression.crefExp(ComponentReference.crefPrefixStart(v.varName));
        end if;
        stmt := Algorithm.makeAssignment(DAE.CREF(v.varName, type_), DAE.PROP(type_, DAE.C_VAR()), initExp, DAE.PROP(type_, DAE.C_VAR()), DAE.dummyAttrVar, SCode.NON_INITIAL(), DAE.emptyElementSource);
        statements := stmt::statements;
      end for;
    then expandAlgorithmStmts(statements, rest, inVars, isInitialEquation);
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
  input output BackendDAE.EqSystem syst;
  input output BackendDAE.Shared shared;
algorithm
  (syst, shared) := match (syst, shared)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns, remeqns, inieqns;
      Mutable<BackendDAE.Shared> shared_arr;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), BackendDAE.SHARED(initialEqs=inieqns))
      algorithm
        shared_arr := Mutable.create(shared);
        (_, vars) := BackendEquation.traverseEquationArray_WithUpdate(eqns, function traverserexpandDerEquation(shared=shared_arr), vars);
        (_, vars) := BackendEquation.traverseEquationArray_WithUpdate(inieqns, function traverserexpandDerEquation(shared=shared_arr), vars);
        syst.orderedVars := vars;
      then (syst, Mutable.access(shared_arr));
  end match;
end expandDerOperatorWork;

protected function traverserexpandDerEquation "
  Help function to e.g. traverserexpandDerEquation"
  input output BackendDAE.Equation eq;
  input output BackendDAE.Variables vars;
  input Mutable<BackendDAE.Shared> shared;
protected
   BackendDAE.Equation e, e1;
   tuple<BackendDAE.Variables, DAE.FunctionTree> ext_arg, ext_art1;
   DAE.FunctionTree funcs;
   Boolean b;
   list<DAE.SymbolicOperation> ops;
algorithm
  (eq, (vars, ops)) := BackendEquation.traverseExpsOfEquation(eq, function traverserexpandDerExp(shared=shared), (vars, {}));
  eq := List.foldr(ops, BackendEquation.addOperation, eq);
end traverserexpandDerEquation;

protected function traverserexpandDerExp "
  Help function to e.g. traverserexpandDerExp"
  input output DAE.Exp exp;
  input output tuple<BackendDAE.Variables, list<DAE.SymbolicOperation>> tpl;
  input Mutable<BackendDAE.Shared> shared;
protected
  DAE.Exp exp_1;
  tuple<BackendDAE.Variables, BackendDAE.Shared, Boolean> ext_arg;
  BackendDAE.Variables vars1, vars2;
  list<DAE.SymbolicOperation> ops;
  DAE.FunctionTree funcs;
  Boolean b;
algorithm
  (vars1, ops) := tpl;
  (exp_1, vars2) := Expression.traverseExpBottomUp(exp, function expandDerExp(inShared=shared), vars1);
  if not (referenceEq(vars1, vars2) and referenceEq(exp, exp_1)) then
    ops := DAE.OP_DIFFERENTIATE(DAE.crefTime, exp, exp_1)::ops;
    exp := exp_1;
    tpl := (vars2, ops);
  end if;
end traverserexpandDerExp;

protected function expandDerExp "
  Help function to e.g. expandDerOperatorEqn"
  input output DAE.Exp exp;
  input output BackendDAE.Variables vars;
  input Mutable<BackendDAE.Shared> inShared;
algorithm
  (exp,vars) := matchcontinue exp
    local
      DAE.Exp e1, e2;
      DAE.ComponentRef cr;
      String str;
      list<BackendDAE.Var> varlst;
      BackendDAE.Var v;
      Boolean b;
      DAE.FunctionTree funcs;
      BackendDAE.Shared shared;
    case DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=cr)})})
      equation
        str = ComponentReference.crefStr(cr);
        str = stringAppendList({"The model includes derivatives of order > 1 for: ", str, ". That is not supported. Real d", str, " = der(", str, ") *might* result in a solvable model"});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
    // case for arrays
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(ty = DAE.T_ARRAY())}))
      equation
        (e2, true) = Expression.extendArrExp(e1, false);
        (exp,vars) = Expression.traverseExpBottomUp(e2, function expandDerExp(inShared=inShared), vars);
      then (exp,vars);
    // case for records
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))}))
      equation
        (e2, true) = Expression.extendArrExp(e1, false);
        (exp,vars) = Expression.traverseExpBottomUp(e2, function expandDerExp(inShared=inShared), vars);
      then (exp,vars);
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=cr)}))
      equation
        (v, _) = BackendVariable.getVarSingle(cr, vars);
        (vars, e1) = updateStatesVar(vars, v, e1);
      then (e1, vars);
    case (e1 as DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={DAE.CREF(componentRef=cr)}))
      equation
        (varlst, _) = BackendVariable.getVar(cr, vars);
        vars = updateStatesVars(vars, varlst, false);
      then (e1, vars);
    case (DAE.CALL(path=Absyn.IDENT(name = "der"), expLst={e1}))
      equation
        (e2, shared) = Differentiate.differentiateExpTime(e1, vars, Mutable.access(inShared));
        Mutable.update(inShared, shared);
        (e2, _) = ExpressionSimplify.simplify(e2);
        (_, vars) = Expression.traverseExpBottomUp(e2, derCrefsExp, vars);
      then (e2, vars);
    else (exp,vars);
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
      (v, _) = BackendVariable.getVarSingle(cr, vars);
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

public function addedScaledVars_states
  "added var_norm = var/nominal, where var is state."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systlst;
  list<BackendDAE.EqSystem> osystlst = {};
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  list<BackendDAE.Var> lst_states;
  BackendDAE.Var tmpv;
  DAE.ComponentRef cref;
  DAE.Exp norm, y_norm, y, lhs;
  BackendDAE.Equation eqn;
  BackendDAE.Shared oshared;
  BackendDAE.EqSystem syst;
algorithm
  BackendDAE.DAE(systlst, oshared) := inDAE;

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
            eqns := BackendEquation.add(eqn, eqns);
            vars := BackendVariable.addVar(tmpv, vars);
          end for;
          syst1.orderedVars := vars;
          syst1.orderedEqs := eqns;
        then BackendDAEUtil.clearEqSyst(syst1);
    end match;
    osystlst := syst::osystlst;
  end for;

  outDAE := BackendDAE.DAE(osystlst, oshared);
end addedScaledVars_states;

public function addedScaledVars_inputs
  "added var_norm = var/nominal, where var is state."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systlst;
  list<BackendDAE.EqSystem> osystlst = {};
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  list<BackendDAE.Var> kvarlst, lst_inputs;
  BackendDAE.Var tmpv;
  DAE.ComponentRef cref;
  DAE.Exp norm, y_norm, y, lhs;
  BackendDAE.Equation eqn;
  BackendDAE.Shared oshared;
  BackendDAE.EqSystem syst;
algorithm
  BackendDAE.DAE(systlst, oshared) := inDAE;
  kvarlst := BackendVariable.varList(oshared.globalKnownVars);
  lst_inputs := List.select(kvarlst, BackendVariable.isVarOnTopLevelAndInputNoDerInput);

  //BackendDump.printVarList(lst_inputs);
  syst :: osystlst := systlst;
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
          eqns := BackendEquation.add(eqn, eqns);
          vars := BackendVariable.addVar(tmpv, vars);
        end for;
        syst1.orderedEqs := eqns;
        syst1.orderedVars := vars;
      then BackendDAEUtil.clearEqSyst(syst1);
  end match;
  osystlst := syst::osystlst;

  outDAE := BackendDAE.DAE(osystlst, oshared);
end addedScaledVars_inputs;

// =============================================================================
// section for sortEqnsVars
//
// author: Vitalij Ruge
// =============================================================================

public function sortEqnsVars
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
  list<tuple<Integer,Integer>> tplIndexWeight;
  list<Integer> indexs;
  list<BackendDAE.Var> var_lst;
  list<BackendDAE.Equation> eqn_lst;
algorithm
  //BackendDump.bltdump("Start", outDAE);
  BackendDAE.DAE(systlst, shared) := inDAE;
  BackendDAE.SHARED(functionTree=functionTree) := shared;
  for syst in systlst loop
    syst := match syst
      local
        BackendDAE.EqSystem syst1;
      case syst1 as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
        algorithm
          (_, m, mT) := BackendDAEUtil.getIncidenceMatrix(syst, BackendDAE.ABSOLUTE(), SOME(functionTree));
          //debug
          if Flags.isSet(Flags.SORT_EQNS_AND_VARS) then
            BackendDump.dumpIncidenceMatrix(m);
            BackendDump.dumpIncidenceMatrixT(mT);
          end if;

          BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(numberOfElements = nv)) := vars;
          ne := ExpandableArray.getNumberOfElements(eqns);
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
          tplIndexWeight := List.sort(tplIndexWeight, Util.compareTuple2IntLt);
          //new order vars indexs
          indexs := sortEqnsVarsWorkTpl(tplIndexWeight);
          var_lst := list(BackendVariable.getVarAt(vars, i) for i in indexs);
          // new vars
          vars := BackendVariable.listVar1(var_lst);
          //sort eqns
          tplIndexWeight := list((i, w_eqns[i]) for i in 1:ne);
          //sorted eqns
          tplIndexWeight := List.sort(tplIndexWeight, Util.compareTuple2IntGt);
          //new order eqns indexs
          indexs := sortEqnsVarsWorkTpl(tplIndexWeight);
          eqn_lst := list(BackendEquation.get(eqns, i) for i in indexs);
          //new eqns
          eqns := BackendEquation.listEquation(eqn_lst);
          syst1.orderedEqs := eqns;
          syst1.orderedVars := vars;

          //debug
          if Flags.isSet(Flags.SORT_EQNS_AND_VARS) then
            (_, m, mT) := BackendDAEUtil.getIncidenceMatrix(syst1, BackendDAE.ABSOLUTE(), SOME(functionTree));
            BackendDump.dumpIncidenceMatrix(m);
            BackendDump.dumpIncidenceMatrixT(mT);
          end if;

          GC.free(w_vars);
          GC.free(w_eqns);
        then BackendDAEUtil.clearEqSyst(syst1);
    end match;
    new_systlst := syst :: new_systlst;
  end for; //syst

  outDAE:= BackendDAE.DAE(new_systlst, shared);
  //BackendDump.bltdump("End", outDAE);
end sortEqnsVars;

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

// =============================================================================
// fix some bugs for complex function
//
// e.g. (a,-b) = f(.) -> (a,c) = f(.) with c = -b
//      (a,b) = (c,d) -> a=c and b = d
//      {a,b} = {c,d} -> a=c and b = d
//      (a,b) = f(a) fixed iterration var
// author: Vitalij Ruge
// =============================================================================


public function simplifyComplexFunction
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := simplifyComplexFunction1(inDAE, true);
end simplifyComplexFunction;

public function simplifyComplexFunction1
  input BackendDAE.BackendDAE inDAE;
  input Boolean withTmpVars = false;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  list<BackendDAE.EqSystem> systlst = {};
  BackendDAE.Shared shared;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  Integer n, size, idx = 1, m, j;
  BackendDAE.Equation eqn, eqn1;
  DAE.Exp left, right, e1, e2, e, e3, e4;
  list<DAE.Exp> left_lst, right_lst;
  list<Integer> indRemove;
  DAE.ElementSource source "origin of equation";
  BackendDAE.EquationAttributes attr;
  Boolean update, sc;
  Absyn.Path path;
  list<DAE.Exp> arrayLst, arrayLst2, expLst;
  DAE.CallAttributes cattr;
  DAE.ComponentRef cr;
  BackendDAE.Var tmpvar;
  String tmpVarPrefix;
algorithm
  shared := inDAE.shared;
  tmpVarPrefix := match shared
    case BackendDAE.SHARED(backendDAEType=BackendDAE.SIMULATION()) then "$OMC$CF$sim";
    case BackendDAE.SHARED(backendDAEType=BackendDAE.INITIALSYSTEM()) then "$OMC$CF$init";
    else "$OMC$CF$unknown";
  end match;

  for syst in inDAE.eqs loop
    BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns) := syst;
    n := ExpandableArray.getNumberOfElements(eqns);
    update := false;
    indRemove := {};

    for i in 1:n loop
      try
        eqn := BackendEquation.get(eqns, i);
      else
        continue;
      end try;
      if BackendEquation.isComplexEquation(eqn) or BackendEquation.isArrayEquation(eqn) then
        if BackendEquation.isComplexEquation(eqn) then
          BackendDAE.COMPLEX_EQUATION(size=size,left=left, right=right, attr= attr, source=source) := eqn;
        else
          BackendDAE.ARRAY_EQUATION(left=left, right=right, attr= attr, source=source) := eqn;
        end if;

        if Expression.isTuple(left) and Expression.isTuple(right) then // tuple() = tuple()
          //print(BackendDump.equationString(eqn) + "--In--\n");
          DAE.TUPLE(PR = left_lst) := left;
          DAE.TUPLE(PR = right_lst) := right;
          update := true;
          indRemove := i :: indRemove;
          for e1 in left_lst loop
            e2 :: right_lst := right_lst;
            //print("=>" +  ExpressionDump.printExpStr(e2) + " = " +  ExpressionDump.printExpStr(e1) + "\n");
            if not Expression.isWild(e1) then
              if Expression.isScalar(e2) then
                eqn1 := BackendEquation.generateEquation(e1, e2, source, attr);
                eqns := BackendEquation.add(eqn1, eqns);
                //print(BackendDump.equationString(eqn1) + "--new--\n");
              else
                expLst := simplifyComplexFunction2(e1);
                arrayLst := simplifyComplexFunction2(e2);
                for e_asub in arrayLst loop
                  e3 :: expLst := expLst;
                  eqn1 := BackendEquation.generateEquation(e_asub, e3, source, attr);
                  eqns := BackendEquation.add(eqn1, eqns);
                  //print(BackendDump.equationString(eqn1) + "--new--\n");
                end for;
              end if; //isScalar
            end if; // isWild
          end for;
      elseif Expression.isArray(left) and Expression.isArray(right)
      then // array{} = array{} // not work with arrayType
          //print(BackendDump.equationString(eqn) + "--In--\n");
        try
          left_lst := Expression.getArrayOrRangeContents(left);
          right_lst := Expression.getArrayOrRangeContents(right);
          update := true;
          indRemove := i :: indRemove;
          for e1 in left_lst loop
          e2 :: right_lst := right_lst;
          //print("=>" +  ExpressionDump.printExpStr(e2) + " = " +  ExpressionDump.printExpStr(e1) + "\n");
          if not Expression.isWild(e1) then
            if Expression.isScalar(e2) then
            eqn1 := BackendEquation.generateEquation(e1, e2, source, attr);
            eqns := BackendEquation.add(eqn1, eqns);
            //print(BackendDump.equationString(eqn1) + "--new--\n");
            else
            expLst := simplifyComplexFunction2(e1);
            arrayLst := simplifyComplexFunction2(e2);
            for e_asub in arrayLst loop
              e3 :: expLst := expLst;
              eqn1 := BackendEquation.generateEquation(e_asub, e3, source, attr);
              eqns := BackendEquation.add(eqn1, eqns);
              //print(BackendDump.equationString(eqn1) + "--new--\n");
            end for;
            end if; //isScalar
          end if; // isWild
          end for;
        else
          continue;
        end try;
      elseif withTmpVars and  Expression.isTuple(left) and Expression.isCall(right)  //tuple() = call()
      then
        DAE.TUPLE(PR = left_lst) := left;
        DAE.CALL(path=path,expLst = expLst, attr= cattr) := right;
        expLst := {};
        for e1 in left_lst loop
          if Expression.isCref(e1) then
            DAE.CREF(componentRef = cr) := e1;
            if Expression.expHasCrefNoPreOrStart(right, cr) then
              update := true;
              cr  := ComponentReference.makeCrefIdent(tmpVarPrefix + intString(idx), Expression.typeof(e1) , {});
              idx := idx + 1;
              e := Expression.crefExp(cr);
              tmpvar := BackendVariable.makeVar(cr);
              tmpvar := BackendVariable.setVarTS(tmpvar,SOME(BackendDAE.AVOID()));
              vars := BackendVariable.addVar(tmpvar, vars);

              eqn1 := BackendDAE.EQUATION(e, e1, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
              eqns := BackendEquation.add(eqn1, eqns);
            else
              e := e1;
            end if;
            elseif Expression.isUnaryCref(e1) then
              update := true;
              cr  := ComponentReference.makeCrefIdent(tmpVarPrefix + intString(idx), Expression.typeof(e1) , {});
              idx := idx + 1;
              e := Expression.crefExp(cr);
              tmpvar := BackendVariable.makeVar(cr);
              tmpvar := BackendVariable.setVarTS(tmpvar,SOME(BackendDAE.AVOID()));
              vars := BackendVariable.addVar(tmpvar, vars);
              eqn1 := BackendDAE.EQUATION(e, e1, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
              //print(BackendDump.equationString(eqn1) + "--new--\n");
              eqns := BackendEquation.add(eqn1, eqns);
             elseif Expression.isArray(e1) then
              update := true;
              DAE.ARRAY(array=arrayLst, scalar=sc) := e1;
              m := listLength(arrayLst);
              cr  := ComponentReference.makeCrefIdent(tmpVarPrefix + intString(idx), Expression.typeof(e1) , {});
              idx := idx + 1;
              e := Expression.crefExp(cr);
              tmpvar := BackendVariable.makeVar(cr);
              tmpvar := BackendVariable.setVarTS(tmpvar,SOME(BackendDAE.AVOID()));
              tmpvar.arryDim := {DAE.DIM_INTEGER(m)};
              // e[1]
              arrayLst2 := list( Expression.makeAsubAddIndex(e,k) for k in 1:m);
              j := 1;
              for e2 in arrayLst2 loop
                e3 :: arrayLst := arrayLst;
                eqn1 := BackendDAE.EQUATION(e2, e3, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
                //print(BackendDump.equationString(eqn1) + "--new--\n");
                eqns := BackendEquation.add(eqn1, eqns);
                cr  := ComponentReference.makeCrefIdent(tmpVarPrefix + intString(idx-1), Expression.typeof(e1) , {DAE.INDEX(DAE.ICONST(j))});
                j := j + 1;
                tmpvar.varName := cr;
                vars := BackendVariable.addVar(tmpvar, vars);
                //vars := BackendVariable.addVar(tmpvar, vars);
              end for;
              //BackendDump.printVariables(vars);
            else
              e := e1;
            end if;
            expLst := e :: expLst;
          end for; // lhs
          left := DAE.TUPLE(MetaModelica.Dangerous.listReverseInPlace(expLst));
          eqn := BackendEquation.generateEquation(left, right, source, attr);
          eqns := BackendEquation.setAtIndex(eqns, i, eqn);
        end if; // lhs <-> rhs
      end if; // complex
    end for; //1:n


    if update then
      for i in listReverse(indRemove) loop
      //print("\neqns:" + intString(i) + "\n");
      //BackendDump.printEquationArray(eqns);
        eqns := BackendEquation.delete(i,eqns);
      end for;
      eqns := BackendEquation.listEquation(BackendEquation.equationList(eqns));
      systlst := BackendDAEUtil.createEqSystem(vars, eqns, syst.stateSets, syst.partitionKind, syst.removedEqs) :: systlst;
    else
      systlst := syst :: systlst;
    end if;
  end for; // syst

  outDAE.eqs := systlst;
end simplifyComplexFunction1;

function simplifyComplexFunction2
  input DAE.Exp e1;
  output list<DAE.Exp> out_lst_e1 = {};
protected
  list<DAE.Exp> lst_e;
algorithm
  try
    if Expression.isArray(e1) or Expression.isArrayType(Expression.typeof(e1)) then
      lst_e := Expression.getArrayOrRangeContents(e1);
      for e in lst_e loop
        out_lst_e1 := listAppend(simplifyComplexFunction2(e),out_lst_e1);
      end for;
    elseif Expression.isRecord(e1) then
      lst_e := Expression.splitRecord(e1, Expression.typeof(e1));
      for e in lst_e loop
        out_lst_e1 := listAppend(simplifyComplexFunction2(e),out_lst_e1);
      end for;
      out_lst_e1 := {e1};
    else
     out_lst_e1 := {e1};
   end if;
  else
     out_lst_e1 := {e1};
  end try;

end simplifyComplexFunction2;

// =============================================================================
// section for hets
//
// (h)euristic (e)quation (t)erms (s)ort
// heuristic sorting of terms for better numeric in equations(res, torn,...)
//
// author: Vitalij Ruge
// =============================================================================

public function hets
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if Flags.getConfigString(Flags.HETS)<> "none" then
    outDAE := hetsWork(inDAE);
  else
    outDAE := inDAE;
  end if;
end hets;

protected function hetsWork
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
  BackendDAE.InnerEquations innerEquations;
  BackendDAE.InnerEquation innerEquation;
  Integer i,j;
  BackendDAE.Equation eqn;
  list<Integer> tvars "be careful with states, this are solved for der(x)";
  list<Integer> teqns;
  DAE.ComponentRef cr;
  BackendDAE.StrongComponents comps;
  BackendDAE.Shared shared;
algorithm
  shared := outDAE.shared;
  for syst in outDAE.eqs loop
    BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching as BackendDAE.MATCHING(comps=comps),stateSets=stateSets,partitionKind=partitionKind) := syst;

    for comp in comps loop
      if BackendEquation.isTornSystem(comp) then

        BackendDAE.TORNSYSTEM(strictTearingSet = BackendDAE.TEARINGSET(tearingvars=tvars, residualequations=teqns, innerEquations = innerEquations)) := comp;
        for innerEquation in innerEquations loop
           try
            (i,{j},_) := BackendDAEUtil.getEqnAndVarsFromInnerEquation(innerEquation);
            eqn := BackendEquation.get(eqns, i);
            BackendDAE.VAR(varName = cr) := BackendVariable.getVarAt(vars, j);
            eqn := BackendEquation.solveEquation(eqn, Expression.crefExp(cr), SOME(shared.functionTree));
            eqn := hetsSplitRhs(eqn);
            eqns := BackendEquation.setAtIndex(eqns, i, eqn);
           else
           end try;
        end for;

        for i in teqns loop
          eqn := BackendEquation.get(eqns, i);
          eqn := hetsSplitRes(eqn);
          eqns := BackendEquation.setAtIndex(eqns, i, eqn);
        end for;
      elseif BackendEquation.isEquationsSystem(comp) then
        BackendDAE.EQUATIONSYSTEM(eqns=teqns) := comp;
        for i in teqns loop
          eqn := BackendEquation.get(eqns, i);
          eqn := hetsSplitRes(eqn);
          eqns := BackendEquation.setAtIndex(eqns, i, eqn);
        end for;
      end if;
    end for;
  end for;
end hetsWork;

function hetsSplitRes
 input BackendDAE.Equation iEqn;
 output BackendDAE.Equation oEqn;

algorithm
  oEqn := match iEqn
          local DAE.Exp e1,e2, e;
          DAE.ElementSource source;
          BackendDAE.EquationAttributes attr;

          case BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=attr)
            equation
            e = Expression.createResidualExp(e1, e2);
            e = hetsSplitExp(e);
          then BackendDAE.RESIDUAL_EQUATION(e, source, attr);

          case BackendDAE.RESIDUAL_EQUATION(e, source, attr)
            equation
            e = hetsSplitExp(e);
          then BackendDAE.RESIDUAL_EQUATION(e, source, attr);

          else iEqn;
          end match;
end hetsSplitRes;

function hetsSplitRhs
 input BackendDAE.Equation iEqn;
 output BackendDAE.Equation oEqn;

algorithm
  oEqn := match iEqn
          local DAE.Exp e1,e2, e;
          DAE.ElementSource source;
          BackendDAE.EquationAttributes attr;

          case BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=attr)
            equation
            e2 = hetsSplitExp(e2);
          then BackendDAE.EQUATION(e1, e2, source, attr);

          else iEqn;
          end match;
end hetsSplitRhs;

function hetsSplitExp
  input DAE.Exp iExp;
  output DAE.Exp oExp;
algorithm
  oExp := match iExp
          local DAE.Exp e,e1,e2; DAE.Operator op;
          list<DAE.Exp> terms, termsDer;

          case DAE.BINARY(e1, op, e2)
          guard Expression.isMulOrDiv(op)
            algorithm
              e1 := hetsSplitExp(e1);
              e2 := hetsSplitExp(e2);
            then DAE.BINARY(e1, op, e2);

          case e as DAE.BINARY(_, op, _)
          guard Expression.isAddOrSub(op)
            algorithm
              terms := Expression.terms(e);
              terms := list(hetsSplitExp(t) for t in terms);
              (termsDer, terms) := List.splitOnTrue(terms, Expression.expHasDer);
            then Expression.expAdd(Expression.makeSum1(terms), Expression.makeSum1(termsDer));
          else iExp;
          end match;
end hetsSplitExp;

// =============================================================================
// section inlineFunctionInLoops
// force inlining function of loop
// author: Vitalij Ruge
// motivation see #3997 library devs introduce annotation(Inline=true) for simplify loops
// =============================================================================
public function inlineFunctionInLoops
  input output BackendDAE.BackendDAE dae;
algorithm
  dae := inlineFunctionInLoopsMain(dae);
end inlineFunctionInLoops;

protected function inlineFunctionInLoopsMain
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.Shared shared;
  DAE.FunctionTree functionTree;
  BackendDAE.EqSystems eqs;
  BackendDAE.EqSystem _syst;
algorithm
  shared := inDAE.shared;
  functionTree := shared.functionTree;
  eqs := {};
  for syst in inDAE.eqs loop
    (_syst, shared) :=  inlineFunctionInLoopsWork(syst, functionTree, shared);
     eqs := _syst :: eqs;
  end for;
  outDAE := BackendDAE.DAE(eqs, shared);
end inlineFunctionInLoopsMain;

protected function inlineFunctionInLoopsWork
  input output BackendDAE.EqSystem syst;
  input DAE.FunctionTree functionTree;
  input output BackendDAE.Shared shared;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.BaseClockPartitionKind partitionKind;
  BackendDAE.StateSets stateSets;
  BackendDAE.StrongComponents comps;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  Inline.Functiontuple fns = (SOME(functionTree),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE(), DAE.DEFAULT_INLINE()});
  Boolean inlined;
  BackendDAE.Equation eq, eqNew;
  BackendDAE.EqSystem tmpEqs, tmpEqs1;
  list<Integer> idEqns;
  Boolean inlined1;
  Integer id;
algorithm
  inlined := false;
  inlined1 := false;
  tmpEqs1 := BackendDAEUtil.createEqSystem( BackendVariable.listVar({}), BackendEquation.listEquation({}));
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching as BackendDAE.MATCHING(comps=comps),stateSets=stateSets,partitionKind=partitionKind) := syst;
  for comp in comps
  loop
      if BackendEquation.isEquationsSystem(comp) or BackendEquation.isTornSystem(comp)  or
      (match comp case BackendDAE.SINGLECOMPLEXEQUATION() then true; else false; end match)
      then
         idEqns := match comp
                   case BackendDAE.EQUATIONSYSTEM(eqns=idEqns) then idEqns;
                   case BackendDAE.SINGLECOMPLEXEQUATION(eqn = id) then {id};
                   end match;
         for id in idEqns
         loop
           eq := BackendEquation.get(eqns, id);
           //eqn := BackendInline.inlineEqOpt(SOME(eq), fns);
           //eqns := BackendEquation.setAtIndexFirst(id, eq, eqns);
           (eqNew, tmpEqs, inlined, shared) := BackendInline.inlineEqAppend_debug(eq, fns, shared);
           if inlined or not BackendEquation.equationEqual(eq, eqNew)
           then
             tmpEqs1 := BackendDAEUtil.mergeEqSystems(tmpEqs, tmpEqs1);
             eqns := BackendEquation.setAtIndexFirst(id, eqNew, eqns);
             //BackendDump.printEquation(BackendEquation.get(eqns, id));
             inlined1 := true;
           end if;
         end for;
      end if;
  end for;
  syst.orderedEqs := eqns;
  if inlined1 then
    syst := BackendDAEUtil.clearEqSyst(syst);
    syst := BackendDAEUtil.mergeEqSystems(tmpEqs1, syst);
  end if;
end inlineFunctionInLoopsWork;

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
            case BackendDAE.SHARED(backendDAEType=BackendDAE.SIMULATION()) then true;
            case BackendDAE.SHARED(backendDAEType=BackendDAE.INITIALSYSTEM()) then true;
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
    ne := ExpandableArray.getNumberOfElements(eqns);
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
  BackendDAE.InnerEquations innerEquations;
  BackendDAE.InnerEquation innerEquation;
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
    BackendDAE.TORNSYSTEM(linear=linear, strictTearingSet = BackendDAE.TEARINGSET(tearingvars=vars, residualequations=eqns, innerEquations = innerEquations)) := inComp;
    if linear then
      return;
    end if;
    if Flags.isSet(Flags.DUMP_SIMPLIFY_LOOPS) then
        print("------ Tearing ------\n");
    end if;

    for innerEquation in innerEquations loop
      (k,vv) := BackendDAEUtil.getEqnAndVarsFromInnerEquation(innerEquation);
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
      eqn := BackendEquation.get(outEqns, i);
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
    (noLoopTerm, outEqns, outVars, outShared, update, para) :=  BackendEquation.makeTmpEqnForExp(noLoopTerm, tmpVarName + "T", System.tmpTickIndex(Global.tmpVariableIndex), outEqns, outVars, outShared);
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
      ne := ExpandableArray.getNumberOfElements(inEqns);
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
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, introduceDerAliasWork);
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
        eqns := BackendEquation.addList(eqnsList, eqns);
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
      (v, _) = BackendVariable.getVarSingle(cr, vars);
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
// section for replaceDerCall
//
// =============================================================================

public function replaceDerCalls
" This module replaces all der(cref)-calls by $DER.cref crefs expression."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, replaceDerCallWork);
end replaceDerCalls;

protected function replaceDerCallWork
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
      BackendDAE.Variables localKnowns;
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      algorithm
        (eqns, vars) :=
          BackendEquation.traverseEquationArray_WithUpdate(eqns, traverserreplaceDerCall, vars);
        (localKnowns, vars) := BackendVariable.traverseBackendDAEVars(vars,
          moveStatesVariables, (oshared.localKnownVars, vars));
        oshared.localKnownVars := localKnowns;
        syst.orderedEqs := eqns; syst.orderedVars := vars;
      then syst;
  end match;
end replaceDerCallWork;

protected function traverserreplaceDerCall "
  Help function to e.g. replaceDerCall"
  input BackendDAE.Equation inEq;
  input BackendDAE.Variables inVars;
  output BackendDAE.Equation outEq;
  output BackendDAE.Variables outVars = inVars;
protected
  BackendDAE.Equation e;
  BackendDAE.Variables vars;
  list<DAE.SymbolicOperation> ops;
algorithm
  (e, ops) := BackendEquation.traverseExpsOfEquation(inEq, traverserreplaceDerCallExp, {});
  outEq := List.foldr(ops, BackendEquation.addOperation, e);
end traverserreplaceDerCall;

protected function traverserreplaceDerCallExp "
  Help function to e.g. traverserreplaceDerCall"
  input DAE.Exp inExp;
  input list<DAE.SymbolicOperation> tpl;
  output DAE.Exp outExp;
  output list<DAE.SymbolicOperation> outTpl;
protected
  DAE.Exp e, e1;
  tuple<BackendDAE.Variables, Boolean> ext_arg;
  BackendDAE.Variables vars;
  list<DAE.SymbolicOperation> ops;
  DAE.FunctionTree funcs;
  Boolean b, addVars;
  BackendDAE.Shared shared;
  list<BackendDAE.Equation> eqnLst;
algorithm
  e := inExp;
  ops := tpl;
  (e1, b) := Expression.traverseExpBottomUp(e, replaceDerCall, false);
  ops := List.consOnTrue(b, DAE.SUBSTITUTION({e1}, e), ops);
  outExp := e1;
  outTpl := ops;
end traverserreplaceDerCallExp;

protected function replaceDerCall "
  Help function to e.g. traverserreplaceDerCallExp"
  input DAE.Exp inExp;
  input Boolean itpl;
  output DAE.Exp outExp;
  output Boolean tpl;
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

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr, ty=ty)}), _) equation
      cref = ComponentReference.crefPrefixDer(cr);
      outExp = DAE.CREF(cref,ty);
    then (outExp, true);

    case (DAE.CALL(path=Absyn.IDENT(name="der")), _) equation
      str = "BackendDAEOptimize.replaceDerCall failed for: " + ExpressionDump.printExpStr(inExp) + "\n";
      Error.addMessage(Error.INTERNAL_ERROR, {str});
    then fail();

    else (inExp, itpl);
  end matchcontinue;
end replaceDerCall;

protected function moveStatesVariables
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables, BackendDAE.Variables> inTpl;
  output BackendDAE.Var outVar = inVar;
  output tuple<BackendDAE.Variables, BackendDAE.Variables> outTpl = inTpl;
algorithm
  _ := match(inVar)
  local
    DAE.ComponentRef cref;
    BackendDAE.Var newVar;
    BackendDAE.Variables localKnowns, newVars;
    case(BackendDAE.VAR(varKind = BackendDAE.STATE(), varName=cref)) algorithm
      (localKnowns, newVars) := inTpl;
      // remove the state from variables
      newVars := BackendVariable.deleteVar(cref, newVars);
      // push it to the local knows
      localKnowns := BackendVariable.addVar(inVar, localKnowns);

      cref := ComponentReference.crefPrefixDer(cref);
      newVar := BackendVariable.copyVarNewName(cref, inVar);
      newVar := BackendVariable.setVarKind(newVar, BackendDAE.STATE_DER());

      newVars := BackendVariable.addVar(newVar, newVars);
      outTpl := (localKnowns, newVars);
    then ();
    else then();
  end match;
end moveStatesVariables;


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
    BackendDAEUtil.traverseBackendDAEExpsEqns(isyst.orderedEqs, traverserapplyRewriteRulesBackend, false);
    BackendDAEUtil.traverseBackendDAEExpsEqns(isyst.removedEqs, traverserapplyRewriteRulesBackend, false);
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
  BackendDAEUtil.traverseBackendDAEExpsVarsWithUpdate(shared.globalKnownVars, traverserapplyRewriteRulesBackend, false);
  BackendDAEUtil.traverseBackendDAEExpsEqns(shared.initialEqs, traverserapplyRewriteRulesBackend, false);
  BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, traverserapplyRewriteRulesBackend, false);
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

      warning = "Iteration variables of equation system with analytic Jacobian:\n" + warnAboutVars(varlst);
      warningList = listAllIterationVariables2(rest, inVars);
    then warning::warningList;

    case (BackendDAE.EQUATIONSYSTEM(vars=vlst, jacType=BackendDAE.JAC_NO_ANALYTIC())::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      false = listEmpty(varlst);

      warning = "Iteration variables of equation system without analytic Jacobian:\n" + warnAboutVars(varlst);
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
  (BackendDAE.DAE(eqs, shared), _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, addTimeAsState1, 0);
  orderedVars := BackendVariable.emptyVars();
  var := BackendDAE.VAR(DAE.crefTimeState, BackendDAE.STATE(1, NONE()), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.BCONST(false), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
  var := BackendVariable.setVarFixed(var, true);
  var := BackendVariable.setVarStartValue(var, DAE.CREF(DAE.crefTime, DAE.T_REAL_DEFAULT));
  orderedVars := BackendVariable.addVar(var, orderedVars);
  orderedEqs := BackendEquation.emptyEqnsSized(1);
  orderedEqs := BackendEquation.add(BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"), {DAE.CREF(DAE.crefTimeState, DAE.T_REAL_DEFAULT)}, DAE.callAttrBuiltinReal), DAE.RCONST(1.0), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC), orderedEqs);
  eq := BackendDAEUtil.createEqSystem(orderedVars, orderedEqs, {}, BackendDAE.CONTINUOUS_TIME_PARTITION());
  outDAE := BackendDAE.DAE(eq::eqs, shared);
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

    case syst as BackendDAE.EQSYSTEM( orderedEqs=orderedEqs)
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

//-------------------------------------
//Evaluate Output Variables Only.
//-------------------------------------
public function evaluateOutputsOnly"Computes only the scc which are necessary in order to calculate the output vars.
author: Waurich TUD 09/2015"
  input BackendDAE.BackendDAE daeIn;
  output BackendDAE.BackendDAE daeOut;
protected
  Integer size, nVars, nEqs;
  array<Integer> ass1,ass2, varVisited;
  list<Integer> outputVarIndxs, stateIndxs, stateTasks, stateTasks1 , outputTasks, predecessors, tasks, varIdcs, eqIdcs, stateDerIdcs;
  list<BackendDAE.StrongComponent> comps, compsNew, addComps;
  BackendDAE.StrongComponent comp;
  BackendDAE.EqSystem syst;
  BackendDAE.EqSystems systs, systsNew;
  BackendDAE.Equation eq;
  BackendDAE.EquationArray eqs;
  BackendDAE.IncidenceMatrix m, mT;
  BackendDAE.Matching matching;
  BackendDAE.Shared shared;
  BackendDAE.Variables vars;
  DAE.FunctionTree funcTree;
  list<BackendDAE.Equation> eqLst, eqLstNew;
  list<BackendDAE.Var> varLst, varLstNew, states;
  list<DAE.ComponentRef> crefs;
  HpcOmTaskGraph.TaskGraph taskGraph, taskGraphT;
  HpcOmTaskGraph.TaskGraphMeta taskGraphData;
  array<tuple<Integer,Integer,Integer>> varCompMapping;
  array<tuple<Integer,Integer,Integer>> eqCompMapping;

  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  Integer systemNumber=0, numberOfSystems;
algorithm
  daeOut := daeIn;

  BackendDAE.DAE(systs,shared) := daeIn;
  BackendDAE.SHARED(functionTree = funcTree) := shared;
  systsNew := {};
  //traverse the simulation-DAE systems
  numberOfSystems := listLength(systs);
  for syst in systs loop
    systemNumber := systemNumber+1;
    BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs=eqs, matching=matching) := syst;
    BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps) := matching;

    // get taskgraph and transposed taskgraph for simulation eqsystem
    (taskGraph,taskGraphData) := HpcOmTaskGraph.getEmptyTaskGraph(0,0,0);
    (taskGraph,taskGraphData,_) := HpcOmTaskGraph.createTaskGraph0(syst,shared,false,(taskGraph,taskGraphData,1));
    HpcOmTaskGraph.TASKGRAPHMETA(varCompMapping=varCompMapping, eqCompMapping=eqCompMapping) := taskGraphData;
    size := arrayLength(taskGraph);
    taskGraphT := AdjacencyMatrix.transposeAdjacencyMatrix(taskGraph,size);

    //get output variables
    BackendDAE.EQSYSTEM(orderedVars = vars) := syst;
    varLst := BackendVariable.varList(vars);
    varLst := List.filterOnTrue(varLst,BackendVariable.isOutputVar);

    if not listEmpty(varLst) then

      //THIS SYSTEM CONTAINS OUTPUT VARIABLES
      //-------------------------------------
      outputVarIndxs := BackendVariable.getVarIndexFromVars(varLst,vars);
      outputTasks := List.map(List.map1(outputVarIndxs,Array.getIndexFirst,varCompMapping),Util.tuple31);
        //print("outputTasks "+stringDelimitList(List.map(outputTasks,intString),", ")+"\n");

      //get all necessary components to calculate the outputs
      predecessors := HpcOmTaskGraph.getAllSuccessors(outputTasks,taskGraphT);
      predecessors := List.sort(predecessors,intGt);
      compsNew := List.map1(listAppend(outputTasks,predecessors),List.getIndexFirst,comps);
         //print("predecessors of outputs "+stringDelimitList(List.map(predecessors,intString),", ")+"\n");

      //get equations from the new reduced set of comps
      eqLstNew := BackendDAEUtil.getStrongComponentEquations(compsNew,eqs,vars);

      // Get all state-variables which are needed in these equations and apply the same search for these equations.
      // The according state-derivatives have to be computed.
      stateTasks := {};
      varVisited := arrayCreate(BackendVariable.varsSize(vars),-1);
      while not listEmpty(eqLstNew) loop
        eq::eqLstNew := eqLstNew;
          //print("eq: "+BackendDump.equationString(eq)+"\n");
        crefs := BackendEquation.equationCrefs(eq);
        crefs := List.filter1OnTrue(crefs,BackendVariable.isState,vars);
        (states,stateIndxs) := BackendVariable.getVarLst(crefs,vars);
        (stateIndxs,states) := List.filter1OnTrueSync(stateIndxs,stateVarIsNotVisited,varVisited,states);//not yet visited
        if not listEmpty(stateIndxs) then
            //print("states "+stringDelimitList(List.map(states,BackendDump.varString),"\n ")+"\n");
          List.map2_0(stateIndxs,Array.updateIndexFirst,1,varVisited);
          //add the new tasks which are necessary for the states
          stateTasks1 := List.map(List.map1(stateIndxs,Array.getIndexFirst,varCompMapping),Util.tuple31);
          stateTasks := List.append_reverse(stateTasks1,stateTasks);
          //get their predecessor tasks, the corresponding comps and add their equations
          predecessors := HpcOmTaskGraph.getAllSuccessors(stateTasks1,taskGraphT);
          addComps := List.map1(listAppend(stateTasks1,predecessors),List.getIndexFirst,comps);
          eqLstNew := List.unique(listAppend(eqLstNew,BackendDAEUtil.getStrongComponentEquations(addComps,eqs,vars)));
        end if;
      end while;
      stateTasks := Dangerous.listReverseInPlace(stateTasks);

      //get all necessary components to calculate the outputs and the state derivatives
      predecessors := HpcOmTaskGraph.getAllSuccessors(listAppend(outputTasks,stateTasks),taskGraphT);
      tasks := List.sort(listAppend(predecessors,listAppend(outputTasks,stateTasks)),intGt);
        //print("predecessors of outputs and states "+stringDelimitList(List.map(tasks,intString),", ")+"\n");
      compsNew := List.map1(tasks,List.getIndexFirst,comps);
      compsNew := List.unique(compsNew);
        print("There have been "+intString(listLength(comps))+" SCCs and now there are "+intString(listLength(compsNew))+" SCCs.\n");

      //get vars and equations from the new reduced set of comps and make a equationIdxMap
      eqLstNew := {};
      varLstNew := {};
      for comp in compsNew loop
        (varLst,_,eqLst,_) := BackendDAEUtil.getStrongComponentVarsAndEquations(comp,vars,eqs);
        varLstNew := listAppend(varLst,varLstNew);
        eqLstNew := listAppend(eqLst,eqLstNew);
      end for;

      // causalize again
      syst.orderedVars := BackendVariable.listVar1(listReverse(varLstNew));
      syst.orderedEqs := BackendEquation.listEquation(listReverse(eqLstNew));

      syst.m :=NONE();
      syst.mT :=NONE();
      syst.matching := BackendDAE.NO_MATCHING();
      (m,mT) := BackendDAEUtil.incidenceMatrix(syst,BackendDAE.NORMAL(),NONE());
      syst.m := SOME(m);
      syst.mT := SOME(mT);
      nVars := listLength(varLstNew);
      nEqs := listLength(eqLstNew);
      ass1 := arrayCreate(nVars, -1);
      ass2 := arrayCreate(nEqs, -1);
      Matching.matchingExternalsetIncidenceMatrix(nVars, nEqs, m);
      BackendDAEEXT.matching(nVars, nEqs, 5, -1, 0.0, 1);
      BackendDAEEXT.getAssignment(ass2, ass1);
      matching := BackendDAE.MATCHING(ass1,ass2,compsNew);
      syst.matching := matching;

      (syst, _, _, mapEqnIncRow, mapIncRowEqn) := BackendDAEUtil.getIncidenceMatrixScalar(syst, BackendDAE.NORMAL(), SOME(funcTree));
      syst := BackendDAETransform.strongComponentsScalar(syst,shared,mapEqnIncRow,mapIncRowEqn);
      syst.removedEqs := BackendEquation.emptyEqns();
    else
      Error.addCompilerNotification("No output variables in this system ("+String(systemNumber)+"/"+String(numberOfSystems)+")");
    end if;

    systsNew := syst::systsNew;
  end for;

   //alias vars are not necessary anymore
   shared.aliasVars := BackendVariable.emptyVars();
   daeOut := BackendDAE.DAE(systsNew,shared);
end evaluateOutputsOnly;

protected function stateVarIsNotVisited"checks if the indexed entry in the array is less than 0"
  input Integer idx;
  input array<Integer> varArr;
  output Boolean b;
algorithm
  b := intLt(arrayGet(varArr,idx),0);
end stateVarIsNotVisited;


// =============================================================================
// section for initOptModule >>inlineHomotopy<<
//
// =============================================================================

public function inlineHomotopy
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.Variables orderedVars;
  Boolean foundHomotopy;
algorithm
  for syst in inDAE.eqs loop
    orderedEqs := syst.orderedEqs;
    (orderedEqs, foundHomotopy) := BackendEquation.traverseEquationArray_WithUpdate(orderedEqs, inlineHomotopy2, false);
    syst.orderedEqs := orderedEqs;
  end for;
end inlineHomotopy;

protected function inlineHomotopy2
  input BackendDAE.Equation inEq;
  input Boolean inFoundHomotopy;
  output BackendDAE.Equation outEq;
  output Boolean outFoundHomotopy = inFoundHomotopy;
algorithm
  (outEq, outFoundHomotopy) := BackendEquation.traverseExpsOfEquation(inEq, inlineHomotopy3, inFoundHomotopy);
end inlineHomotopy2;

protected function inlineHomotopy3
  input DAE.Exp inExp;
  input Boolean inFoundHomotopy;
  output DAE.Exp outExp;
  output Boolean outFoundHomotopy = inFoundHomotopy;
algorithm
  (outExp, outFoundHomotopy) := Expression.traverseExpTopDown(inExp, replaceHomotopyWithLambdaExpression, inFoundHomotopy);
end inlineHomotopy3;

protected function replaceHomotopyWithLambdaExpression
  input DAE.Exp inExp;
  input Boolean inFoundHomotopy;
  output DAE.Exp outExp = inExp;
  output Boolean cont = true;
  output Boolean outFoundHomotopy;
algorithm
  outFoundHomotopy := match(inExp)
    local
      DAE.Exp actual, simplified, lambda;

    case DAE.CALL(path=Absyn.IDENT("homotopy"), expLst={actual,simplified})
      algorithm
        lambda := Expression.crefExp(ComponentReference.makeCrefIdent(BackendDAE.homotopyLambda, DAE.T_REAL_DEFAULT, {}));
        outExp := DAE.BINARY(DAE.BINARY(simplified, DAE.MUL(DAE.T_REAL_DEFAULT), DAE.BINARY(DAE.RCONST(1.0), DAE.SUB(DAE.T_REAL_DEFAULT), lambda)), DAE.ADD(DAE.T_REAL_DEFAULT), DAE.BINARY(actual, DAE.MUL(DAE.T_REAL_DEFAULT), lambda));
     then true;

    else inFoundHomotopy;
  end match;
end replaceHomotopyWithLambdaExpression;

// =============================================================================
// section for initOptModule >>generateHomotopyComponents<<
//
// =============================================================================

public function generateHomotopyComponents " finds the smallest homotopy loop and creates a component out of it
  author: ptaeuber 2017"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  BackendDAE.StrongComponents comps;
  BackendDAE.EqSystems newEqSystems={};
  array<Integer> ass1, ass2;
algorithm
  if Config.adaptiveHomotopy() then
    for syst in outDAE.eqs loop
      BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps) := syst.matching;
      if Config.globalHomotopy() then
        (comps, syst) := traverseStrongComponentsForHomotopyLoop(comps, syst);
      else
        (comps, syst) := traverseStrongComponentsAddLambda(comps, syst);
      end if;
      syst.matching := BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps);
      newEqSystems := syst::newEqSystems;
    end for;
    outDAE.eqs := listReverse(newEqSystems);
  else
    Error.addCompilerWarning("InitOptModule generateHomotopyComponents is activated for an equidistant homotopy method and will therefore be ignored.");
  end if;
end generateHomotopyComponents;

protected function traverseStrongComponentsForHomotopyLoop " traverses all the strong components and finds the smallest homotopy loop
  author: ptaeuber 2017"
  input output BackendDAE.StrongComponents comps;
  input output BackendDAE.EqSystem system;
protected
  Integer nComps, compIndex=0, homotopyLoopBeginning=0, homotopyLoopEnd=0;
  BackendDAE.StrongComponents preHomotopyComponents, homotopyComponents, postHomotopyComponents;
  BackendDAE.StrongComponent homotopyComponent;
  BackendDAE.Var lambda;
  Integer lambdaIdx;
algorithm
  nComps := listLength(comps);
  for comp in comps loop
    compIndex := compIndex + 1;
    _ := match(comp)
      local
        Integer eqnIndex, varIndex;
        list<Integer> eqnIndexes, varIndexes, resEqnIndexes, tVarIndexes, innerEqnIndexes;
        list<list<Integer>> innerVarIndexesLst;
        BackendDAE.InnerEquations innerEquations;
        BackendDAE.Equation eqn;
        list<BackendDAE.Equation> eqnLst;
        Boolean hasHomotopy;

      case(BackendDAE.SINGLEEQUATION(eqn=eqnIndex))
        equation
          eqn = BackendEquation.get(system.orderedEqs, eqnIndex);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);
          if hasHomotopy then
            homotopyLoopEnd = compIndex;
            if (homotopyLoopBeginning == 0) then
              homotopyLoopBeginning = compIndex;
            end if;
          end if;
        then();

      case(BackendDAE.EQUATIONSYSTEM(eqns=eqnIndexes))
        equation
          if (homotopyLoopBeginning == 0) then
            eqnLst = BackendEquation.getList(eqnIndexes, system.orderedEqs);
            (_, hasHomotopy) = BackendEquation.traverseExpsOfEquationList(eqnLst, BackendDAEUtil.containsHomotopyCall, false);

            if hasHomotopy then
              homotopyLoopBeginning = compIndex;
              homotopyLoopEnd = compIndex;
            end if;
          else
            homotopyLoopEnd = compIndex;
          end if;
        then();

      case(BackendDAE.SINGLEARRAY(eqn=eqnIndex))
        equation
          eqn = BackendEquation.get(system.orderedEqs, eqnIndex);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);

          if hasHomotopy then
            homotopyLoopEnd = compIndex;
            if (homotopyLoopBeginning == 0) then
              homotopyLoopBeginning = compIndex;
            end if;
          end if;
        then();

      case(BackendDAE.SINGLEALGORITHM(eqn=eqnIndex))
        equation
          eqn = BackendEquation.get(system.orderedEqs, eqnIndex);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);

          if hasHomotopy then
            homotopyLoopEnd = compIndex;
            if (homotopyLoopBeginning == 0) then
              homotopyLoopBeginning = compIndex;
            end if;
          end if;
        then();

      case(BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqnIndex))
        equation
          eqn = BackendEquation.get(system.orderedEqs, eqnIndex);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);

          if hasHomotopy then
            homotopyLoopEnd = compIndex;
            if (homotopyLoopBeginning == 0) then
              homotopyLoopBeginning = compIndex;
            end if;
          end if;
        then();

      case(BackendDAE.SINGLEWHENEQUATION(eqn=eqnIndex))
        equation
          eqn = BackendEquation.get(system.orderedEqs, eqnIndex);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);

          if hasHomotopy then
            homotopyLoopEnd = compIndex;
            if (homotopyLoopBeginning == 0) then
              homotopyLoopBeginning = compIndex;
            end if;
          end if;
        then();

      case(BackendDAE.SINGLEIFEQUATION(eqn=eqnIndex))
        equation
          eqn = BackendEquation.get(system.orderedEqs, eqnIndex);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);

          if hasHomotopy then
            homotopyLoopEnd = compIndex;
            if (homotopyLoopBeginning == 0) then
              homotopyLoopBeginning = compIndex;
            end if;
          end if;
        then();

      case(BackendDAE.TORNSYSTEM(strictTearingSet=BackendDAE.TEARINGSET(residualequations=resEqnIndexes, innerEquations=innerEquations)))
        equation
          if (homotopyLoopBeginning == 0) then
            eqnLst = BackendEquation.getList(resEqnIndexes, system.orderedEqs);
            (_, hasHomotopy) = BackendEquation.traverseExpsOfEquationList(eqnLst, BackendDAEUtil.containsHomotopyCall, false);

            if not hasHomotopy then
              (innerEqnIndexes,_,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
              eqnLst = BackendEquation.getList(innerEqnIndexes, system.orderedEqs);
              (_, hasHomotopy) = BackendEquation.traverseExpsOfEquationList(eqnLst, BackendDAEUtil.containsHomotopyCall, false);
            end if;

            if hasHomotopy then
              homotopyLoopBeginning = compIndex;
              homotopyLoopEnd = compIndex;
            end if;
          else
            homotopyLoopEnd = compIndex;
          end if;
        then();
    end match;
  end for;

  if homotopyLoopBeginning > 0 then
    // Add homotopy lambda to system
    lambda := BackendDAE.VAR(ComponentReference.makeCrefIdent(BackendDAE.homotopyLambda, DAE.T_REAL_DEFAULT, {}), BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.BCONST(false), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
    system.orderedVars := BackendVariable.addVar(lambda, system.orderedVars);
    lambdaIdx := BackendVariable.varsSize(system.orderedVars);

    (preHomotopyComponents, homotopyComponents, postHomotopyComponents) := getHomotopyComponents(List.intRange(nComps), comps, homotopyLoopBeginning, homotopyLoopEnd);

    homotopyComponent := createOneHomotopyComponent(homotopyComponents, system, lambdaIdx);

    comps := homotopyComponent::postHomotopyComponents;
    comps := listAppend(preHomotopyComponents, comps);
  end if;
end traverseStrongComponentsForHomotopyLoop;


protected function getHomotopyComponents " divides the components into pre-homotopy, homotopy and post-homotopy parts
  author: ptaeuber 2017"
  input list<Integer> componentIndexes;
  input BackendDAE.StrongComponents components;
  input Integer homotopyLoopBeginning;
  input Integer homotopyLoopEnd;
  input output BackendDAE.StrongComponents outPreHomotopyComponents = {};
  input output BackendDAE.StrongComponents outHomotopyComponents = {};
  input output BackendDAE.StrongComponents outPostHomotopyComponents = {};
algorithm
  (outPreHomotopyComponents, outHomotopyComponents, outPostHomotopyComponents) := match(componentIndexes, components)
    local
      Integer i;
      list<Integer> indexes;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents comps;

    case(i::{}, comp::{})
      equation
        if intLt(i, homotopyLoopBeginning) then
          outPreHomotopyComponents = comp::outPreHomotopyComponents;
        elseif intGt(i, homotopyLoopEnd) then
          outPostHomotopyComponents = comp::outPostHomotopyComponents;
        else
          outHomotopyComponents = comp::outHomotopyComponents;
        end if;
      then (listReverse(outPreHomotopyComponents), listReverse(outHomotopyComponents), listReverse(outPostHomotopyComponents));

    case(i::indexes, comp::comps)
      equation
        if intLt(i, homotopyLoopBeginning) then
          outPreHomotopyComponents = comp::outPreHomotopyComponents;
        elseif intGt(i, homotopyLoopEnd) then
          outPostHomotopyComponents = comp::outPostHomotopyComponents;
        else
          outHomotopyComponents = comp::outHomotopyComponents;
        end if;
      then getHomotopyComponents(indexes, comps, homotopyLoopBeginning, homotopyLoopEnd, outPreHomotopyComponents, outHomotopyComponents, outPostHomotopyComponents);
  end match;
end getHomotopyComponents;

protected function createOneHomotopyComponent " creates one BackendDAE.TORNSYSTEM out of all homotopy components
  author: ptaeuber 2017"
  input BackendDAE.StrongComponents homotopyComponents;
  input BackendDAE.EqSystem inSystem;
  input Integer lambdaIdx;
  output BackendDAE.StrongComponent outHomotopyComponent;
protected
  BackendDAE.InnerEquations newInnerEquations = {};
  list<Integer> newResEquations = {};
  list<Integer> newIterationVars = {};
  Boolean isMixed = false;
algorithm
  for comp in homotopyComponents loop
    (newInnerEquations, newResEquations, newIterationVars) := match(comp)
      local
        Integer eqnIndex, varIndex;
        list<Integer> eqnIndexes, varIndexes, resEqnIndexes, tVarIndexes;
        BackendDAE.InnerEquations innerEquations;
        BackendDAE.InnerEquation newInnerEquation;
        Boolean mixedSystem;

      case(BackendDAE.SINGLEEQUATION(eqn=eqnIndex, var=varIndex))
        equation
          newInnerEquation = BackendDAE.INNEREQUATION(eqn=eqnIndex, vars={varIndex});
        then (newInnerEquation::newInnerEquations, newResEquations, newIterationVars);

      case(BackendDAE.EQUATIONSYSTEM(eqns=eqnIndexes, vars=varIndexes, mixedSystem=mixedSystem))
        equation
          if mixedSystem then
            isMixed = true;
          end if;
        then (newInnerEquations, listAppend(newResEquations, eqnIndexes), listAppend(newIterationVars, varIndexes));

      case(BackendDAE.SINGLEARRAY(eqn=eqnIndex, vars=varIndexes))
        equation
          newInnerEquation = BackendDAE.INNEREQUATION(eqn=eqnIndex, vars=varIndexes);
        then (newInnerEquation::newInnerEquations, newResEquations, newIterationVars);

      case(BackendDAE.SINGLEALGORITHM(eqn=eqnIndex, vars=varIndexes))
        equation
          newInnerEquation = BackendDAE.INNEREQUATION(eqn=eqnIndex, vars=varIndexes);
        then (newInnerEquation::newInnerEquations, newResEquations, newIterationVars);

      case(BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqnIndex, vars=varIndexes))
        equation
          newInnerEquation = BackendDAE.INNEREQUATION(eqn=eqnIndex, vars=varIndexes);
        then (newInnerEquation::newInnerEquations, newResEquations, newIterationVars);

      case(BackendDAE.SINGLEWHENEQUATION(eqn=eqnIndex, vars=varIndexes))
        equation
          newInnerEquation = BackendDAE.INNEREQUATION(eqn=eqnIndex, vars=varIndexes);
        then (newInnerEquation::newInnerEquations, newResEquations, newIterationVars);

      case(BackendDAE.SINGLEIFEQUATION(eqn=eqnIndex, vars=varIndexes))
        equation
          newInnerEquation = BackendDAE.INNEREQUATION(eqn=eqnIndex, vars=varIndexes);
        then (newInnerEquation::newInnerEquations, newResEquations, newIterationVars);

      case(BackendDAE.TORNSYSTEM(strictTearingSet=BackendDAE.TEARINGSET(residualequations=resEqnIndexes, tearingvars=tVarIndexes, innerEquations=innerEquations), mixedSystem=mixedSystem))
        algorithm
          if mixedSystem then
            isMixed := true;
          end if;
          for innerEquation in innerEquations loop
            newInnerEquations := innerEquation::newInnerEquations;
          end for;
        then (newInnerEquations, listAppend(newResEquations, resEqnIndexes), listAppend(newIterationVars, tVarIndexes));
    end match;
  end for;

  outHomotopyComponent := BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(listAppend(newIterationVars,{lambdaIdx}), newResEquations, listReverse(newInnerEquations), BackendDAE.EMPTY_JACOBIAN()), NONE(), false, isMixed);
end createOneHomotopyComponent;

protected function traverseStrongComponentsAddLambda " traverses all the strong components and adds lambda as the last variable if the system contains homotopy
  author: ptaeuber 2017"
  input output BackendDAE.StrongComponents comps;
  input output BackendDAE.EqSystem system;
protected
  BackendDAE.StrongComponents newComps={};
  BackendDAE.Var lambda;
  Integer lambdaIdx;
  Boolean hasAnyHomotopy = false;
algorithm
  lambdaIdx := BackendVariable.varsSize(system.orderedVars) + 1;

  for comp in comps loop
    comp := match(comp)
      local
        list<Integer> eqnIndexes, varIndexes, resEqnIndexes, tVarIndexes, innerEqnIndexes;
        Option<BackendDAE.TearingSet> casualTearingSet;
        BackendDAE.InnerEquations innerEquations;
        BackendDAE.Jacobian jac;
        BackendDAE.JacobianType jacType;
        list<BackendDAE.Equation> eqnLst;
        Boolean linear, mixedSystem, hasHomotopy;

      case(BackendDAE.EQUATIONSYSTEM(eqns=eqnIndexes, vars=varIndexes, jac=jac, jacType=jacType, mixedSystem=mixedSystem))
        equation
          eqnLst = BackendEquation.getList(eqnIndexes, system.orderedEqs);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquationList(eqnLst, BackendDAEUtil.containsHomotopyCall, false);

          if hasHomotopy then
            hasAnyHomotopy = true;
            // Add lambda in front of the list, list seems to be reversed later for EQUATIONSYSTEM
            comp = BackendDAE.EQUATIONSYSTEM(eqnIndexes, lambdaIdx::varIndexes, jac, jacType, mixedSystem);
          end if;
        then comp;

      case(BackendDAE.TORNSYSTEM(strictTearingSet=BackendDAE.TEARINGSET(residualequations=resEqnIndexes, tearingvars=tVarIndexes, innerEquations=innerEquations, jac=jac), casualTearingSet=casualTearingSet, linear=linear, mixedSystem=mixedSystem))
        equation
          eqnLst = BackendEquation.getList(resEqnIndexes, system.orderedEqs);
          (_, hasHomotopy) = BackendEquation.traverseExpsOfEquationList(eqnLst, BackendDAEUtil.containsHomotopyCall, false);

          if not hasHomotopy then
            (innerEqnIndexes,_,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
            eqnLst = BackendEquation.getList(innerEqnIndexes, system.orderedEqs);
            (_, hasHomotopy) = BackendEquation.traverseExpsOfEquationList(eqnLst, BackendDAEUtil.containsHomotopyCall, false);
          end if;

          if hasHomotopy then
            hasAnyHomotopy = true;
            comp = BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(listAppend(tVarIndexes, {lambdaIdx}), resEqnIndexes, innerEquations, jac), casualTearingSet, linear, mixedSystem);
          end if;
        then comp;
      else comp;
    end match;
    newComps := comp::newComps;
  end for;

  if hasAnyHomotopy then
    // Add homotopy lambda to system
    lambda := BackendDAE.VAR(ComponentReference.makeCrefIdent(BackendDAE.homotopyLambda, DAE.T_REAL_DEFAULT, {}), BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.BCONST(false), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
    system.orderedVars := BackendVariable.addVar(lambda, system.orderedVars);
  end if;
  comps := listReverse(newComps);
end traverseStrongComponentsAddLambda;

annotation(__OpenModelica_Interface="backend");
end BackendDAEOptimize;
