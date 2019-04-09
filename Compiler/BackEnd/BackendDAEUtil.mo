/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2017, Open Source Modelica Consortium (OSMC),
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

encapsulated package BackendDAEUtil
" file:        BackendDAEUtil.mo
  package:     BackendDAEUtil
  description: BackendDAEUtil comprised functions for BackendDAE data types.

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

import Absyn;
import AvlSetInt;
import AvlSetPath;
import BackendDAE;
import BackendDAEFunc;
import DAE;
import FCore;
import Util;

protected
import AdjacencyMatrix;
import Algorithm;
import Array;
import BackendDAEOptimize;
import BackendDAETransform;
import BackendDump;
import BackendEquation;
import BackendDAEEXT;
import BackendInline;
import BackendVarTransform;
import BackendVariable;
import BinaryTree;
import Causalize;
import CheckModel;
import ClassInf;
import ClockIndexes;
import CommonSubExpression;
import ComponentReference;
import Config;
import DAEDump;
import DAEMode;
import DAEUtil;
import Debug;
import Differentiate;
import DumpGraphML;
import DynamicOptimization;
import ElementSource;
import Error;
import ErrorExt;
import EvaluateFunctions;
import EvaluateParameter;
import ExecStat.execStat;
import ExpandableArray;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import ExpressionSolve;
import FindZeroCrossings;
import Flags;
import FMI;
import Global;
import HpcOmEqSystems;
import IndexReduction;
import Initialization;
import Inline;
import InlineArrayEquations;
import List;
import Matching;
import MetaModelica.Dangerous;
import OnRelaxation;
import RemoveSimpleEquations;
import ResolveLoops;
import SCode;
import Sorting;
import StackOverflow;
import SymbolicImplicitSolver;
import SymbolicJacobian;
import SynchronousFeatures;
import System;
import Tearing;
import Types;
import UnitCheck;
import Uncertainties;
import Values;
import XMLDump;
import ZeroCrossings;

public function isInitializationDAE
  input BackendDAE.Shared inShared;
  output Boolean res;
algorithm
  res := match(inShared)
    case (BackendDAE.SHARED(backendDAEType=BackendDAE.INITIALSYSTEM())) then true;
    else false;
  end match;
end isInitializationDAE;

public function isSimulationDAE
  input BackendDAE.Shared inShared;
  output Boolean res;
algorithm
  res := match(inShared)
    case (BackendDAE.SHARED(backendDAEType=BackendDAE.SIMULATION())) then true;
    else false;
  end match;
end isSimulationDAE;

public function isJacobianDAE
  input BackendDAE.Shared inShared;
  output Boolean res;
algorithm
  res := match(inShared)
    case (BackendDAE.SHARED(backendDAEType=BackendDAE.JACOBIAN())) then true;
    else false;
  end match;
end isJacobianDAE;

/*************************************************
 * checkBackendDAE and stuff
 ************************************************/

public function checkBackendDAEWithErrorMsg "author: Frenkel TUD
  run checkDEALow and prints all errors"
  input BackendDAE.BackendDAE inBackendDAE;
protected
  list<tuple<DAE.Exp, list<DAE.ComponentRef>>> expCrefs;
  list<BackendDAE.Equation> wrongEqns;
algorithm
  if not Flags.isSet(Flags.CHECK_BACKEND_DAE) then return; end if;
  _ := matchcontinue (inBackendDAE)
    local
      Integer nVars, nEqns;
      Boolean samesize;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree functionTree;

    case BackendDAE.DAE(eqs=(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=orderedEqs))::{}, shared=BackendDAE.SHARED(functionTree=_)) equation
      //true = Flags.isSet(Flags.CHECK_BACKEND_DAE);
      //Check for correct size
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendEquation.equationArraySize(orderedEqs);
      samesize = nVars == nEqns;
      if Flags.isSet(Flags.CHECK_BACKEND_DAE) then
        print("No. of Equations: " + intString(nVars) + " No. of BackendDAE.Variables: " + intString(nEqns) + " Samesize: " + boolString(samesize) + "\n");
      end if;
      (expCrefs, wrongEqns) = checkBackendDAE(inBackendDAE);
      printcheckBackendDAEWithErrorMsg(expCrefs, wrongEqns);
    then ();

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function checkBackendDAEWithErrorMsg failed"});
    then fail();
  end matchcontinue;
end checkBackendDAEWithErrorMsg;

public function printcheckBackendDAEWithErrorMsg"author: Frenkel TUD
  helper for checkDEALowWithErrorMsg"
  input list<tuple<DAE.Exp,list<DAE.ComponentRef>>> inExpCrefs;
  input list<BackendDAE.Equation> inWrongEqns;
algorithm
  _ := match (inExpCrefs,inWrongEqns)
    local
      DAE.Exp e;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> res;
      list<String> strcrefs;
      String crefstring, expstr,scopestr;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> wrongEqns;

    case ({},{})  then ();

    case ({},eqn::wrongEqns)
      equation
        printEqnSizeError(eqn);
        printcheckBackendDAEWithErrorMsg({},wrongEqns);
      then ();

    case (((e,crefs))::res,wrongEqns)
      equation
        strcrefs = List.map(crefs,ComponentReference.crefStr);
        crefstring = stringDelimitList(strcrefs,", ");
        expstr = ExpressionDump.printExpStr(e);
        scopestr = stringAppendList({crefstring," from Expression: ",expstr});
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {scopestr,"BackendDAE object"});
        printcheckBackendDAEWithErrorMsg(res,wrongEqns);
      then
        ();
  end match;
end printcheckBackendDAEWithErrorMsg;

protected function printEqnSizeError"author: Frenkel TUD 2010-12"
    input BackendDAE.Equation inEqn;
algorithm
  _ := matchcontinue(inEqn)
  local
    BackendDAE.Equation eqn;
    DAE.Exp e1, e2;
    DAE.ComponentRef cr;
    DAE.Type t1,t2;
    String eqnstr, t1str, t2str, tstr;
    DAE.ElementSource source;
    case (eqn as BackendDAE.EQUATION(exp=e1,scalar=e2,source=source))
      equation
        eqnstr = BackendDump.equationString(eqn);
        t1 = Expression.typeof(e1);
        t2 = Expression.typeof(e2);
        t1str = Types.unparseTypeNoAttr(t1);
        t2str = Types.unparseTypeNoAttr(t2);
        tstr = stringAppendList({t1str," != ", t2str});
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {eqnstr,tstr}, ElementSource.getElementSourceFileInfo(source));
      then ();
    case (eqn as BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e1,source=source))
      equation
        eqnstr = BackendDump.equationString(eqn);
        t1 = Expression.typeof(e1);
        t2 = ComponentReference.crefLastType(cr);
        t1str = Types.unparseTypeNoAttr(t1);
        t2str = Types.unparseTypeNoAttr(t2);
        tstr = stringAppendList({t1str," != ", t2str});
        Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR, {eqnstr,tstr}, ElementSource.getElementSourceFileInfo(source));
      then ();
      //
    else ();
  end matchcontinue;
end printEqnSizeError;

public function checkBackendDAE "author: Frenkel TUD
  This function checks the BackendDAE object if
  -  all component refercences used in the expressions are
     part of the BackendDAE object.
  -  all variables that are reinit are states
  Returns all component references which not part of the BackendDAE object."
  input BackendDAE.BackendDAE inBackendDAE;
  output list<tuple<DAE.Exp,list<DAE.ComponentRef>>> outExpCrefs;
  output list<BackendDAE.Equation> outWrongEqns;
algorithm
  (outExpCrefs,outWrongEqns) := matchcontinue inBackendDAE
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.Variables allvars;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> expcrefs;
      list<BackendDAE.Equation> wrongEqns;


    case BackendDAE.DAE(syst::{}, shared)
      equation
        allvars = BackendVariable.mergeVariables(syst.orderedVars, shared.globalKnownVars);
        ((_, expcrefs)) = traverseBackendDAEExpsVars(syst.orderedVars, checkBackendDAEExp, (allvars, {}));
        ((_, expcrefs)) = traverseBackendDAEExpsEqns(shared.removedEqs, checkBackendDAEExp, (allvars, expcrefs));
        ((_, expcrefs)) = traverseBackendDAEExpsVars(shared.globalKnownVars, checkBackendDAEExp, (allvars, expcrefs));
        ((_, expcrefs)) = traverseBackendDAEExpsEqns(syst.orderedEqs, checkBackendDAEExp, (allvars, expcrefs));
        ((_, expcrefs)) = traverseBackendDAEExpsEqns(syst.removedEqs, checkBackendDAEExp, (allvars, expcrefs));
        ((_, expcrefs)) = traverseBackendDAEExpsEqns(shared.initialEqs, checkBackendDAEExp, (allvars, expcrefs));

        wrongEqns = BackendEquation.traverseEquationArray(syst.orderedEqs, checkEquationSize, {});
        wrongEqns = BackendEquation.traverseEquationArray(shared.removedEqs, checkEquationSize, wrongEqns);
        wrongEqns = BackendEquation.traverseEquationArray(syst.removedEqs, checkEquationSize, wrongEqns);
        wrongEqns = BackendEquation.traverseEquationArray(shared.initialEqs, checkEquationSize, wrongEqns);
      then
        (expcrefs, wrongEqns);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- BackendDAEUtil.checkBackendDAE failed\n");
      then
        fail();
  end matchcontinue;
end checkBackendDAE;

protected function checkBackendDAEExp
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<tuple<DAE.Exp,list<DAE.ComponentRef>>>> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,list<tuple<DAE.Exp,list<DAE.ComponentRef>>>> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp exp;
      BackendDAE.Variables vars;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.Exp,list<DAE.ComponentRef>>> lstExpCrefs,lstExpCrefs1;
    case (exp,(vars,lstExpCrefs))
      equation
        (_,(_,crefs)) = Expression.traverseExpBottomUp(exp,traversecheckBackendDAEExp,(vars,{}));
       then (exp, if not listEmpty(crefs) then (vars,(exp,crefs)::lstExpCrefs) else inTpl);
    else (inExp,inTpl);
  end matchcontinue;
end checkBackendDAEExp;

protected function traversecheckBackendDAEExp
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<DAE.ComponentRef>> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,list<DAE.ComponentRef>> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs,crefs1;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;
      list<BackendDAE.Var> backendVars;
      DAE.ReductionIterators riters;
      tuple<BackendDAE.Variables,list<DAE.ComponentRef>> tp;

    // special case for time, it is never part of the equation system
    case (e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),_)
      then (e, inTuple);

    // Special Case for Records
    case (e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),_)
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (_,tp) = Expression.traverseExpList(expl,traversecheckBackendDAEExp,inTuple);
      then (e, tp);

    // Special Case for Arrays
    case (e as DAE.CREF(ty = DAE.T_ARRAY()),_)
      equation
        (e1,true) = Expression.extendArrExp(e,false);
        (_,tp) = Expression.traverseExpBottomUp(e1,traversecheckBackendDAEExp,inTuple);
      then (e, tp);

    // case for Reductions
    case (e as DAE.REDUCTION(iterators = riters),(vars,crefs))
      equation
        // add idents to vars
        backendVars = List.map(riters,makeIterVariable);
        vars = BackendVariable.addVars(backendVars,vars);
      then (e, (vars,crefs));

    // case for functionpointers
    case (e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC()),_)
      then (e, inTuple);

    case (e as DAE.CREF(componentRef = cr),(vars,_))
      equation
         (_,_) = BackendVariable.getVar(cr, vars);
      then (e, inTuple);

    case (e as DAE.CREF(componentRef = cr),(vars,crefs))
      //failed before, so no need to getVar() again
         //failure((_,_) = BackendVariable.getVar(cr, vars));
      then (e, (vars,cr::crefs));

    else (inExp,inTuple);
  end matchcontinue;
end traversecheckBackendDAEExp;

protected function makeIterVariable
  input DAE.ReductionIterator iter;
  output BackendDAE.Var backendVar;
protected
  String name;
  DAE.ComponentRef cr;
algorithm
  name := Expression.reductionIterName(iter);
  cr := ComponentReference.makeCrefIdent(name,DAE.T_INTEGER_DEFAULT,{});
  backendVar := BackendDAE.VAR(cr, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_INTEGER_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.BCONST(false), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
end makeIterVariable;

protected function checkEquationSize"author: Frenkel TUD 2010-12
  - check if the left hand side and the rigth hand side have equal types."
  input BackendDAE.Equation inEq;
  input list<BackendDAE.Equation> inEqs;
  output BackendDAE.Equation outEq;
  output list<BackendDAE.Equation> outEqs;
algorithm
  (outEq,outEqs) := matchcontinue (inEq,inEqs)
    local
      BackendDAE.Equation e;
      list<BackendDAE.Equation> wrongEqns,wrongEqns1;
      DAE.Exp e1, e2;
      DAE.ComponentRef cr;
      DAE.Type t1,t2;
      Boolean b;
    case (e as BackendDAE.EQUATION(exp=e1,scalar=e2),wrongEqns)
      equation
        t1 = Expression.typeof(e1);
        t2 = Expression.typeof(e2);
        b = Expression.equalTypes(t1,t2);
        wrongEqns1 = List.consOnTrue(not b,e,wrongEqns);
      then (e,wrongEqns1);

    case (e as BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e1),wrongEqns)
      equation
        t1 = Expression.typeof(e1);
        t2 = ComponentReference.crefLastType(cr);
        b = Expression.equalTypes(t1,t2);
        wrongEqns1 = List.consOnTrue(not b,e,wrongEqns);
      then (e,wrongEqns1);

      //
    else (inEq,inEqs);
  end matchcontinue;
end checkEquationSize;

public function checkAssertCondition "Succeds if condition of assert is not constant false"
  input DAE.Exp cond;
  input DAE.Exp message;
  input DAE.Exp level;
  input SourceInfo info;
algorithm
  // Don't check assertions when checking models
  if Flags.getConfigBool(Flags.CHECK_MODEL) then return; end if;
  _ := matchcontinue(cond,message,level,info)
    local
      String messageStr;
    case (_,_,_,_)
      guard
        not Expression.isConstFalse(cond)
      then ();
    case (_,_,_,_)
      equation
        failure(DAE.ENUM_LITERAL(index=1) = level);
      then ();
    case(_,_,_,_)
      equation
        true = Expression.isConstFalse(cond);
        messageStr = ExpressionDump.printExpStr(message);
        Error.addSourceMessage(Error.ASSERT_CONSTANT_FALSE_ERROR,{messageStr},info);
      then fail();
  end matchcontinue;
end checkAssertCondition;

// =============================================================================
// Util function at Backend using for lowering and other stuff
//
// =============================================================================

public function copyBackendDAE "author: Frenkel TUD, wbraun
  Copy the dae to avoid changes in vectors."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := mapEqSystem(inDAE, copyEqSystemAndShared);
end copyBackendDAE;

public function copyEqSystemAndShared
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared;
algorithm
  outSystem := copyEqSystem(inSystem);
  outShared := copyBackendDAEShared(inShared);
end copyEqSystemAndShared;

public function copyEqSystem
  input BackendDAE.EqSystem inSystem;
  output BackendDAE.EqSystem outSystem;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns, removedEqs;
  Option<BackendDAE.IncidenceMatrix> m, mt;
  BackendDAE.Matching matching;
algorithm
  vars := BackendVariable.copyVariables(inSystem.orderedVars);
  eqns := BackendEquation.copyEquationArray(inSystem.orderedEqs);
  removedEqs := BackendEquation.copyEquationArray(inSystem.removedEqs);
  m := AdjacencyMatrix.copyAdjacencyMatrix(inSystem.m);
  mt := AdjacencyMatrix.copyAdjacencyMatrixT(inSystem.mT);
  matching := copyMatching(inSystem.matching);
  outSystem := BackendDAE.EQSYSTEM(vars, eqns, m, mt, matching, inSystem.stateSets, inSystem.partitionKind, removedEqs);
end copyEqSystem;

public function copyEqSystems
  input BackendDAE.EqSystems inSystems;
  output BackendDAE.EqSystems outSystems = {};
algorithm
  for e in inSystems loop
    outSystems := copyEqSystem(e) :: outSystems;
  end for;
end copyEqSystems;

public function mergeEqSystems
  input BackendDAE.EqSystem System1;
  input output BackendDAE.EqSystem System2;
algorithm
  System2.orderedEqs := BackendEquation.merge(System1.orderedEqs,System2.orderedEqs);
  System2.orderedVars := BackendVariable.mergeVariables(System1.orderedVars,System2.orderedVars);
end mergeEqSystems;

public function copyBackendDAEShared
"  author: Frenkel TUD, wbraun
  Copy the shared part of an BackendDAE to avoid changes in
  vectors."
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
algorithm
  outShared:=
  match (inShared)
    local
      BackendDAE.Shared shared;

    case shared as BackendDAE.SHARED()
      equation
        shared.globalKnownVars = BackendVariable.copyVariables(shared.globalKnownVars);
        shared.externalObjects = BackendVariable.copyVariables(shared.externalObjects);
        shared.initialEqs = BackendEquation.copyEquationArray(shared.initialEqs);
        shared.removedEqs = BackendEquation.copyEquationArray(shared.removedEqs);
      then
        shared;
  end match;
end copyBackendDAEShared;

public function copyMatching
  input BackendDAE.Matching inMatching;
  output BackendDAE.Matching outMatching;
algorithm
  outMatching := match (inMatching)
    local
      array<Integer> ass1, cass1, ass2, cass2;
      BackendDAE.StrongComponents comps;
    case (BackendDAE.NO_MATCHING()) then BackendDAE.NO_MATCHING();
    case (BackendDAE.MATCHING(ass1=ass1,ass2=ass2,comps=comps))
      equation
        cass1 = arrayCopy(ass1);
        cass2 = arrayCopy(ass2);
      then BackendDAE.MATCHING(cass1,cass2,comps);
  end match;
end copyMatching;

public function getCompsOfMatching "author: mwalther
  Get all strong connected components of the given matching. If the matching
  has the concrete type NO_MATCHING, the returned list is empty."
  input BackendDAE.Matching inMatching;
  output BackendDAE.StrongComponents outComps;
algorithm
  outComps := match (inMatching)
    local
      BackendDAE.StrongComponents comps;
    case (BackendDAE.MATCHING(comps=comps))
      then comps;
    else
      then {};
  end match;
end getCompsOfMatching;

public function addVarsToEqSystem
  input BackendDAE.EqSystem syst;
  input list<BackendDAE.Var> varlst;
  output BackendDAE.EqSystem osyst;
protected
  BackendDAE.Variables vars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := syst;
  osyst := setEqSystVars(syst, BackendVariable.addVars(varlst, vars));
end addVarsToEqSystem;

public function numberOfZeroCrossings "author: lochel"
  input BackendDAE.BackendDAE inBackendDAE;
  output Integer outNumZeroCrossings "number of ordinary zero crossings" ;
  output Integer outNumTimeEvents    "number of zero crossings that are time events" ;
  output Integer outNumRelations;
  output Integer outNumMathEventFunctions;
protected
  BackendDAE.EventInfo eventInfo = inBackendDAE.shared.eventInfo;
algorithm
  outNumZeroCrossings := ZeroCrossings.length(eventInfo.zeroCrossings);
  outNumTimeEvents := listLength(eventInfo.timeEvents);
  outNumRelations := DoubleEndedList.length(eventInfo.relations);
  outNumMathEventFunctions := eventInfo.numberMathEvents;
end numberOfZeroCrossings;

public function numberOfDiscreteVars "author: lochel"
  input BackendDAE.BackendDAE inBackendDAE;
  output Integer outNumDiscreteReal;
algorithm
  outNumDiscreteReal := countDiscreteVars(inBackendDAE);
end numberOfDiscreteVars;

protected function countDiscreteVars "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  output Integer outNumDiscreteVars;
protected
  BackendDAE.Variables globalKnownVars, alias;
algorithm
  BackendDAE.SHARED(globalKnownVars=globalKnownVars, aliasVars=alias) := inDAE.shared;
  outNumDiscreteVars := countDiscreteVars1(inDAE.eqs);
  outNumDiscreteVars := BackendVariable.traverseBackendDAEVars(globalKnownVars, countDiscreteVars3, outNumDiscreteVars);
  outNumDiscreteVars := BackendVariable.traverseBackendDAEVars(alias, countDiscreteVars3, outNumDiscreteVars);
end countDiscreteVars;

protected function countDiscreteVars1 "author: lochel"
  input BackendDAE.EqSystems inEqSystems;
  output Integer outNumDiscreteVars;
algorithm
  outNumDiscreteVars := 0;
  outNumDiscreteVars := List.fold(inEqSystems, countDiscreteVars2, outNumDiscreteVars);
end countDiscreteVars1;

protected function countDiscreteVars2 "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  input Integer inNumDiscreteVars;
  output Integer outNumDiscreteVars;
protected
  BackendDAE.Variables vars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := inEqSystem;
  outNumDiscreteVars := BackendVariable.traverseBackendDAEVars(vars, countDiscreteVars3, inNumDiscreteVars);
end countDiscreteVars2;

protected function countDiscreteVars3 "author: lochel"
  input BackendDAE.Var var;
  input Integer nDiscreteVars;
  output BackendDAE.Var outVar;
  output Integer outCount;
algorithm
  (outVar,outCount) := match (var,nDiscreteVars)
    // discrete
    case (BackendDAE.VAR(varKind=BackendDAE.DISCRETE(), varType=DAE.T_REAL()), _)
      then (var, nDiscreteVars+1);
    else (var,nDiscreteVars);
  end match;
end countDiscreteVars3;

public function replaceCrefsWithValues
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, DAE.ComponentRef> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, DAE.ComponentRef> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr, cr_orign;
    case (DAE.CREF(cr, _), (vars, cr_orign))
      guard
        not ComponentReference.crefEqualNoStringCompare(cr, cr_orign)
      equation
        ({BackendDAE.VAR(bindExp = SOME(e))}, _) = BackendVariable.getVar(cr, vars);
        (e, _) = Expression.traverseExpBottomUp(e, replaceCrefsWithValues, (vars, cr_orign));
      then (e, (vars,cr_orign));
    else (inExp,inTuple);
  end matchcontinue;
end replaceCrefsWithValues;

public function makeExpType
"Transforms a BackendDAE.Type to DAE.Type"
  input BackendDAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := inType;
end makeExpType;

public function hasExpContinuousParts
"Returns true if expression has contiuous parts,
 and false if the expression is completely discrete.
 Used to detect if an expression is a ZeroCrossing."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnvars;
  output Boolean outBoolean;
algorithm
  (_,(_, _, outBoolean)) := Expression.traverseExpTopDown(inExp, traversingContinuousExpFinder, (inVariables, inKnvars, false));
end hasExpContinuousParts;

protected function traversingContinuousExpFinder "Helper for isDiscreteExp"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.Variables,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,BackendDAE.Variables,Boolean> outTpl;
algorithm
  (outExp, cont, outTpl) := matchcontinue (inExp, inTpl)
    local
      BackendDAE.Variables vars, globalKnownVars;
      DAE.ComponentRef cr;
      DAE.Exp e;
      Boolean blst;
      BackendDAE.Var backendVar;
      Absyn.Ident name;

    case (e as DAE.CREF(componentRef=cr), (vars, globalKnownVars, _)) equation
      ((backendVar::_), _) = BackendVariable.getVar(cr, vars);
      false = BackendVariable.isVarDiscrete(backendVar);
    then (e, false, (vars, globalKnownVars, true));

    // builtin variable time is not discrete
    case (e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")), (vars, globalKnownVars, _))
    then (e, false, (vars, globalKnownVars, true));

    // Known variables that are input are continuous
    case (e as DAE.CREF(componentRef=cr), (vars, globalKnownVars, _)) equation
      (backendVar::_, _) = BackendVariable.getVar(cr, globalKnownVars);
      true = BackendVariable.isInput(backendVar);
    then (e, false, (vars, globalKnownVars, true));

    case (e as DAE.CALL(path=Absyn.IDENT(name=name)), (vars, globalKnownVars, blst))
      guard stringEq("pre", name) or
            stringEq("change", name) or
            stringEq("ceil", name) or
            stringEq("floor", name) or
            stringEq("div", name) or
            stringEq("mod", name) or
            stringEq("rem", name)
    then (e, false, (vars, globalKnownVars, blst));

    case (e as DAE.CALL(path=Absyn.IDENT(name="noEvent")), (vars, globalKnownVars, _))
    then (e, false, (vars, globalKnownVars, false));

    case (e, (vars, globalKnownVars, blst))
    then (e, true, (vars, globalKnownVars, blst));
  end matchcontinue;
end traversingContinuousExpFinder;

public function statesAndVarsExp
"This function investigates an expression and returns as subexpressions
  that are variable names or derivatives of state names or states
  inputs:  (DAE.Exp, BackendDAE.Variables)
  outputs: DAE.Exp list"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> exps;
algorithm
  (_,(_,exps)) := Expression.traverseExpTopDown(inExp, traversingstatesAndVarsExpFinder, (inVariables,{}));
end statesAndVarsExp;

public function traversingstatesAndVarsExpFinder "
Author: Frenkel TUD 2010-10
Helper for statesAndVarsExp"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<DAE.Exp>> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,list<DAE.Exp>> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.ComponentRef cr;
      list<DAE.Exp> expl,res,creexps;
      DAE.Exp e,e1;
      list<DAE.Var> varLst;
      BackendDAE.Variables vars;
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_)))),(vars,_))
      equation
        creexps = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (_,(_,res)) = Expression.traverseExpListTopDown(creexps, traversingstatesAndVarsExpFinder, inTpl);
      then (e,true,(vars,res));
    // Special Case for unextended arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY())),(vars,_))
      equation
        (e1,true) = Expression.extendArrExp(e,false);
        (_,(_,res)) = Expression.traverseExpTopDown(e1, traversingstatesAndVarsExpFinder, inTpl);
      then (e,true,(vars,res));
    // Special Case for time variable
    //case (((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time"))),(vars,expl)))
    //  then ((e,false,(vars,e::expl)));
    case ((e as DAE.CREF(componentRef = cr)),(vars,expl))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then (e,false,(vars,e::expl));
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),(vars,expl))
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE())::_),_) = BackendVariable.getVar(cr, vars);
      then (e,false,(vars,e::expl));
    // is this case right?
    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,_))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then (e,false,inTpl);
    else (inExp,true,inTpl);
  end matchcontinue;
end traversingstatesAndVarsExpFinder;

public function isLoopDependent
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
        subscript_exprs = List.map(subscripts, Expression.subscriptIndexExp);
        true = isLoopDependentHelper(subscript_exprs, iteratorExp);
      then true;
    case (DAE.ASUB(sub = subscript_exprs), _)
      then isLoopDependentHelper(subscript_exprs, iteratorExp);
    else false;
  end matchcontinue;
end isLoopDependent;

protected function isLoopDependentHelper
  "Helper for isLoopDependent.
  Checks if a list of subscripts contains a certain iterator expression."
  input list<DAE.Exp> subscripts;
  input DAE.Exp iteratorExp;
  output Boolean isDependent = false;
algorithm
  for subscript in subscripts loop
    try
      if Expression.expContains(subscript, iteratorExp) then
        isDependent := true;
        return;
      end if;
    else
      // go on with iteration
    end try;
  end for;
end isLoopDependentHelper;

public function devectorizeArrayVar
  input DAE.Exp arrayVar;
  output DAE.Exp newArrayVar;
algorithm
  newArrayVar := matchcontinue(arrayVar)
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
      list<DAE.Exp> subs;
      DAE.Exp e;

    case (DAE.ASUB(exp = DAE.ARRAY(array = (DAE.CREF(componentRef = cr)::_)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
        e = Expression.crefExp(cr);
      then
        // adrpo: TODO! FIXME! check if this is TYPE correct!
        //        shouldn't we change the type using the subs?
        Expression.makeASUB(e, subs);

    case (DAE.ASUB(exp = DAE.MATRIX(matrix = (((DAE.CREF(componentRef = cr))::_)::_)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
        e = Expression.crefExp(cr);
      then
        // adrpo: TODO! FIXME! check if this is TYPE correct!
        //        shouldn't we change the type using the subs?
        Expression.makeASUB(e, subs);

    case (_) then arrayVar;
  end matchcontinue;
end devectorizeArrayVar;

public function explodeArrayVars
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
      list<DAE.Exp> clonedElements, newElements;
      list<DAE.Exp> indices;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> varCrefs;
      list<DAE.Exp> varExprs;
      DAE.Exp daeExp;
      list<BackendDAE.Var> bvars;

    case (DAE.CREF(), _, _, _)
      equation
        indices = rangeExprs(rangeExpr);
        clonedElements = List.fill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;

    case (DAE.ASUB(exp = DAE.CREF()), _, _, _)
      equation
        // If the range is constant, then we can use it to generate only those
        // array elements that are actually used.
        indices = rangeExprs(rangeExpr);
        clonedElements = List.fill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;

    case (DAE.CREF(componentRef = cref), _, _, _)
      equation
        (bvars, _) = BackendVariable.getVar(cref, vars);
        varExprs = List.map(bvars, BackendVariable.varExp);
        //varCrefs = List.map(bvars, BackendVariable.varCref);
        //varExprs = List.map(varCrefs, Expression.crefExp);
      then varExprs;

    case (DAE.ASUB(exp = DAE.CREF(componentRef = cref)), _, _, _)
      equation
        // If the range is not constant, then we just extract all array elements
        // of the array.
        (bvars, _) = BackendVariable.getVar(cref, vars);
        varExprs = List.map(bvars, BackendVariable.varExp);
        //varCrefs = List.map(bvars, BackendVariable.varCref);
        //varExprs = List.map(varCrefs, Expression.crefExp);
      then varExprs;

    case (DAE.ASUB(exp = daeExp), _, _, _)
      equation
        varExprs = Expression.flattenArrayExpToList(daeExp);
      then
        varExprs;
  end matchcontinue;
end explodeArrayVars;

protected function rangeExprs
  "Tries to convert a range to a list of integer expressions. Returns a list of
  integer expressions if possible, or fails. Used by explodeArrayVars."
  input DAE.Exp inRange;
  output list<DAE.Exp> outValues;
algorithm
  outValues := match inRange
    local
      list<DAE.Exp> arrayElements;
      Integer start, stop;
      list<Integer> vals;

    case DAE.ARRAY(array = arrayElements) then arrayElements;
    case DAE.RANGE() then Expression.expandRange(inRange);

  end match;
end rangeExprs;

public function daeSize
"author: Frenkel TUD
  Returns the size of the dae system, which correspondents to the number of variables."
  input BackendDAE.BackendDAE inDAE;
  output Integer sz;
algorithm
  sz := sum(systemSize(s) for s in inDAE.eqs);
end daeSize;

public function systemSize
  "Returns the size of the dae system, the size of the equations in an BackendDAE.EquationArray,
  which not corresponds to the number of equations in a system."
  input BackendDAE.EqSystem inEqSystem;
  output Integer outSize = BackendEquation.equationArraySize(inEqSystem.orderedEqs);
end systemSize;

public function maxSizeOfEqSystems
  "Returns the maximum system size of given EqSystems"
  input list<BackendDAE.EqSystem> inEqSystems;
  output Integer outSize = 0;
protected
  Integer i;
algorithm
  for eqSyst in inEqSystems loop
    i := systemSize(eqSyst);
    if intGt(i, outSize) then
      outSize := i;
    end if;
  end for;
end maxSizeOfEqSystems;

public function numOfComps "Returns the number of StrongComponents in the EqSystem
  author: waurich TUD"
  input BackendDAE.EqSystem inEqSystem;
  output Integer num;
protected
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.MATCHING(comps=comps) := inEqSystem.matching;
  num := listLength(comps);
end numOfComps;

public function equationArraySizeBDAE
"author: Frenkel TUD
  Returns the size of the dae system, which correspondents to the number of variables."
  input BackendDAE.BackendDAE inDAE;
  output Integer outSize;
algorithm
  outSize := List.applyAndFold(inDAE.eqs, intAdd, equationArraySizeDAE, 0);
end equationArraySizeBDAE;

public function equationArraySizeDAE
"author: Frenkel TUD
  Returns the number of equations in a system."
  input BackendDAE.EqSystem inEqSystem;
  output Integer n = BackendEquation.getNumberOfEquations(inEqSystem.orderedEqs);
end equationArraySizeDAE;

public function hasDAEMatching
  "Returns  true if all system have already a matching, otherwise return false."
  input BackendDAE.BackendDAE inDAE;
  output Boolean b;
algorithm
  b := List.applyAndFold(inDAE.eqs, boolAnd, hasEqSystemMatching, true);
end hasDAEMatching;

public function hasEqSystemMatching
  "Returns true if EqSystem has a matching."
  input BackendDAE.EqSystem dae;
  output Boolean b;
algorithm
  b  := match(dae)
    case BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING()) then true;
    case BackendDAE.EQSYSTEM(matching=BackendDAE.NO_MATCHING()) then false;
  end match;
end hasEqSystemMatching;

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
  newElements := match(clones, indices, iteratorExp)
    local
      DAE.Exp clone, newElement, newElement2, index;
      list<DAE.Exp> restClones, restIndices, elements;
    case ({}, {}, _) then {};
    case (clone::restClones, index::restIndices, _)
      equation
        ((newElement, _)) = Expression.replaceExp(clone, iteratorExp, index);
        newElement2 = simplifySubscripts(newElement);
        elements = generateArrayElements(restClones, restIndices, iteratorExp);
      then (newElement2::elements);
  end match;
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
      DAE.Type arrayType, varType;
      list<DAE.Exp> subExprs, subExprsSimplified;
      list<DAE.Subscript> subscripts;
      DAE.Exp newCrefExp;
      DAE.ComponentRef cref_;

    // A CREF => just simplify the subscripts.
    case (DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, subscripts), varType))
      equation
        subscripts = List.map(subscripts, simplifySubscript);
        cref_ = ComponentReference.makeCrefIdent(varIdent, arrayType, subscripts);
        newCrefExp = Expression.makeCrefExp(cref_, varType);
      then
        newCrefExp;

    // An ASUB => convert to CREF if only constant subscripts.
    case (DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, _), varType), subExprs))
      equation
        {} = List.select(subExprs, Expression.isNotConst);
        // If a subscript is not a single constant value it needs to be
        // simplified, e.g. cref[3+4] => cref[7], otherwise some subscripts
        // might be counted twice, such as cref[3+4] and cref[2+5], even though
        // they reference the same element.
        subExprsSimplified = ExpressionSimplify.simplifyList(subExprs);
        subscripts = List.map(subExprsSimplified, Expression.makeIndexSubscript);
        cref_ = ComponentReference.makeCrefIdent(varIdent, arrayType, subscripts);
        newCrefExp = Expression.makeCrefExp(cref_, varType);
      then
        newCrefExp;

    else asub;
  end matchcontinue;
end simplifySubscripts;

protected function simplifySubscript
  input DAE.Subscript sub;
  output DAE.Subscript simplifiedSub;
algorithm
  simplifiedSub := matchcontinue(sub)
    local
      DAE.Exp e, e1;

    case (DAE.INDEX(exp = e))
      equation
        (e1,_) = ExpressionSimplify.simplify(e);
      then
        if referenceEq(e1,e) then sub else DAE.INDEX(e);
    else sub;

  end matchcontinue;
end simplifySubscript;


public function setTearingSelectAttribute
  "Returns the expression of the tearingSelect annotation"
  input Option<SCode.Comment> comment;
  output Option<BackendDAE.TearingSelect> ts;
protected
  SCode.Annotation ann;
  Absyn.Exp val;
  String ts_str;
algorithm
  try
    SOME(SCode.COMMENT(annotation_=SOME(ann))) := comment;
    val := SCode.getNamedAnnotation(ann, "tearingSelect");
    ts_str := Absyn.crefIdent(Absyn.expCref(val));
    ts := match(ts_str)
      case "always" then SOME(BackendDAE.ALWAYS());
      case "prefer" then SOME(BackendDAE.PREFER());
      case "avoid"  then SOME(BackendDAE.AVOID());
      case "never"  then SOME(BackendDAE.NEVER());
      case "default" then SOME(BackendDAE.DEFAULT());
      else NONE();
    end match;
  else
    ts := NONE();
  end try;
end setTearingSelectAttribute;


public function setHideResultAttribute
  "Returns the expression of the hideResult annotation.
   Uses isProtected as default if the annotation is not specified.
   See Modelica Spec 3.3, section 18.3"
  input Option<SCode.Comment> comment;
  input Boolean isProtected;
  input DAE.ComponentRef inCref;
  output DAE.Exp hideResult;
protected
  SCode.Annotation ann;
  Absyn.Exp val;
  DAE.ComponentRef crefRoot;
algorithm
  try
    SOME(SCode.COMMENT(annotation_=SOME(ann))) := comment;
    val := SCode.getNamedAnnotation(ann, "HideResult");
    hideResult := Expression.fromAbsynExp(val);

    hideResult := match(inCref)
      case(DAE.CREF_QUAL())
        equation
          (crefRoot,_) = ComponentReference.splitCrefLast(inCref);
          hideResult = Expression.traverseExpBottomUp(hideResult, ComponentReference.joinCrefsExp, crefRoot);
       then hideResult;
      else hideResult;
    end match;

  else
    hideResult := DAE.BCONST(isProtected);
  end try;
end setHideResultAttribute;


/*******************************************
   Functions that deals with BackendDAE as input
********************************************/

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
             daeLow: BackendDAE,
             assignments1: int vector,
             assignments2: int vector,
             incidenceMatrix: IncidenceMatrix,
             incidenceMatrixT: IncidenceMatrixT)
  outputs: (dynamicBlocks: int list list, outputBlocks: int list list)
"
  input BackendDAE.EqSystem syst;
  output BackendDAE.StrongComponents outCompsStates;
  output BackendDAE.StrongComponents outCompsNoStates;
algorithm
  (outCompsStates,outCompsNoStates):=
  matchcontinue syst
    local
      Integer size;
      array<Integer> arr,arr_1;
      BackendDAE.StrongComponents comps,blt_states,blt_no_states;
      BackendDAE.Variables v;
      BackendDAE.EquationArray e,se,ie;
      array<Integer> ass1,ass2;
      array<list<Integer>> m,mt;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1,_,comps)))
      equation
        size = arrayLength(ass1) "equation_size(e) => size &";
        arr = arrayCreate(size, 0);
        arr_1 = markStateEquations(syst, arr, ass1);
        (blt_states,blt_no_states) = splitBlocks(comps, arr_1);
      then
        (blt_states,blt_no_states);
    else
      equation
        print("- BackendDAEUtil.generateStatePartition failed\n");
      then
        fail();
  end matchcontinue;
end generateStatePartition;

protected function splitBlocks "Split the blocks into two parts, one dynamic and one output, depending
  on if an equation in the block is marked or not.
  inputs:  (blocks: int list list, marks: int array)
  outputs: (dynamic: int list list, output: int list list)"
  input BackendDAE.StrongComponents inComps;
  input array<Integer> inIntegerArray;
  output BackendDAE.StrongComponents outCompsStates;
  output BackendDAE.StrongComponents outCompsNoStates;
algorithm
  (outCompsStates,outCompsNoStates) := matchcontinue (inComps,inIntegerArray)
    local
      BackendDAE.StrongComponents comps,states,output_;
      BackendDAE.StrongComponent comp;
      list<Integer> eqns;
      array<Integer> arr;

    case ({},_) then ({},{});

    case (comp::comps,arr)
      equation
        (eqns,_) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        true = blockIsDynamic(eqns, arr) "block is dynamic, belong in dynamic section";
        (states,output_) = splitBlocks(comps, arr);
      then
        ((comp::states),output_);

    case (comp::comps,arr)
      equation
        (states,output_) = splitBlocks(comps, arr) "block is not dynamic, belong in output section";
      then
        (states,(comp::output_));
    else
      equation
        print("- BackendDAEUtil.splitBlocks failed\n");
      then
        fail();
  end matchcontinue;
end splitBlocks;

public function blockIsDynamic "Return true if the block contains a variable that is marked"
  input list<Integer> lst;
  input array<Integer> arr;
  output Boolean outBoolean=true;
algorithm
  for x in lst loop
    if arr[x]<>0 then
      return;
    end if;
  end for;
  outBoolean := false;
end blockIsDynamic;

public function markStateEquations "This function goes through all equations and marks the ones that
  calculates a state, or is needed in order to calculate a state,
  with a non-zero value in the array passed as argument.
  This is done by traversing the directed graph of nodes where
  a node is an equation/solved variable and following the edges in the
  backward direction.
  inputs: (daeLow: BackendDAE,
             marks: int array,
    incidenceMatrix: IncidenceMatrix,
    incidenceMatrixT: IncidenceMatrixT,
    assignments1: int vector,
    assignments2: int vector)
  outputs: marks: int array"
  input BackendDAE.EqSystem syst;
  input array<Integer> arr;
  input array<Integer> ass1;
  output array<Integer> outIntegerArray;
protected
  list<Integer> statevarindx_lst,eqns;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Variables v;
algorithm
  BackendDAE.EQSYSTEM(orderedVars = v,m=SOME(m)) := syst;
  if (Flags.getConfigEnum(Flags.SYM_SOLVER) > 0) then
    (_,statevarindx_lst) := BackendVariable.getAllAlgStateVarIndexFromVariables(v);
  else
    (_,statevarindx_lst) := BackendVariable.getAllStateVarIndexFromVariables(v);
  end if;
  eqns := list(arrayGet(ass1,i) for i guard arrayGet(ass1,i)>0 in statevarindx_lst);
  outIntegerArray := markStateEquationsWork(eqns,m,ass1,arr);
end markStateEquations;

public function markZeroCrossingEquations "function: markStateEquations
  This function goes through all equations and marks the ones that
  calculates a state, or is needed in order to calculate a state,
  with a non-zero value in the array passed as argument.
  This is done by traversing the directed graph of nodes where
  a node is an equation/solved variable and following the edges in the
  backward direction.
  inputs: (daeLow: BackendDAE,
             marks: int array,
    incidenceMatrix: IncidenceMatrix,
    incidenceMatrixT: IncidenceMatrixT,
    assignments1: int vector,
    assignments2: int vector)
  outputs: marks: int array"
  input BackendDAE.EqSystem syst;
  input list<BackendDAE.ZeroCrossing> inZeroCross;
  input array<Integer> arr;
  input array<Integer> ass1;
  output array<Integer> outIntegerArray;
protected
  list<Integer> varindx_lst,eqns;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Variables v;
  AvlSetInt.Tree tree;
  CheckEquationsVarsExpTopDownFunc func;
  partial function CheckEquationsVarsExpTopDownFunc
    input output DAE.Exp exp;
    output Boolean cont;
    input output AvlSetInt.Tree tree;
  end CheckEquationsVarsExpTopDownFunc;
algorithm
  BackendDAE.EQSYSTEM(orderedVars = v,m=SOME(m)) := syst;
  tree := AvlSetInt.new();
  func := function BackendEquation.checkEquationsVarsExpTopDown(vars=v);
  for zc in inZeroCross loop
    tree := varsCollector(zc.relation_, tree, func);
  end for;
  varindx_lst := AvlSetInt.listKeys(tree);
  eqns := list(arrayGet(ass1,i) for i guard arrayGet(ass1,i)>0 in varindx_lst);
  outIntegerArray := markStateEquationsWork(eqns,m,ass1,arr);
end markZeroCrossingEquations;

protected function varsCollector
  input DAE.Exp exp;
  input output AvlSetInt.Tree tree;
  input CheckEquationsVarsExpTopDownFunc func;

  partial function CheckEquationsVarsExpTopDownFunc
    input output DAE.Exp exp;
    output Boolean cont;
    input output AvlSetInt.Tree tree;
  end CheckEquationsVarsExpTopDownFunc;
algorithm
  tree := BackendEquation.expressionVarsIndexes(exp, tree, func);
end varsCollector;

protected function markStateEquationsWork
"Helper function to mark_state_equation
  Does the job by looking at variable indexes and incidencematrices.
  inputs: (eqns: int list,
             marks: (int array  BackendDAE.IncidenceMatrix  int vector  int vector))
  outputs: ((marks: int array  BackendDAE.IncidenceMatrix
        int vector  int vector))"
  input list<Integer> inEqns;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1;
  input array<Integer> iMark;
  output array<Integer> oMark = iMark;
protected
  list<Integer> queue = inEqns;
  list<Integer> queue_tmp,vlst;
  Integer j, eqn, len = arrayLength(ass1);
algorithm

 while not listEmpty(queue) loop
   eqn :: queue := queue;
   if oMark[eqn] == 0 then // "Mark an unmarked node/equation"
     arrayUpdate(oMark, eqn, 1);
     for i in m[eqn] loop
       if i>0 and i<=len then
         // We already did bounds checking above
         j := Dangerous.arrayGetNoBoundsChecking(ass1, i);
         if if j>0 then arrayGet(oMark, j) == 0 else false then
           // Only add positive, unmarked variables to the queue
           queue := j::queue;
          end if;
       end if;
     end for;
   end if;
 end while;

end markStateEquationsWork;


public function removeNegative
"author: PA
  Removes all negative integers."
  input list<Integer> lst;
  output list<Integer> lst_1;
algorithm
  lst_1 := List.select(lst, Util.intPositive);
end removeNegative;

public function eqnsForVarWithStates
"author: PA
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
  outIntegerLst := matchcontinue (inIncidenceMatrixT,inInteger)
    local
      Integer n,indx;
      list<Integer> res,res_1;
      array<list<Integer>> mt;
      String s;

    case (mt,n)
      equation
        res = mt[n];
        res_1 = List.map(res, intAbs);
      then
        res_1;

    case (_,indx)
      equation
        print("- BackendDAEUtil.eqnsForVarWithStates failed, indx= ");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end eqnsForVarWithStates;

public function varsInEqn
"author: PA
  This function returns all variable indices as a list for
  a given equation, given as an equation index. (1...n)
  Negative indexes are removed.
  See also: eqnsForVar and eqnsForVarWithStates
  inputs:  (IncidenceMatrix, int /* equation */)
  outputs:  int list /* variables */"
  input BackendDAE.IncidenceMatrix m;
  input Integer indx;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (m,indx)
    local String s;
    case (_,_)
      then
        removeNegative(m[indx]);
    else
      equation
        s = "- BackendDAEUtil.varsInEqn failed, indx= " + intString(indx) + "array length: " + intString(arrayLength(m)) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR,{s});
      then
        fail();
  end matchcontinue;
end varsInEqn;

protected type TraverseIndicesTuple = tuple<list<Integer>, list<Integer>, list<Integer>>;

public function setEvaluationStage
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  //BackendDAE.SparsePattern sp;
  list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> spCrefs, spCrefsT;
  BackendDAE.Variables vars;
  list<BackendDAE.Var> varLst;
  BackendDAE.EquationArray eqns;
  BackendDAE.Matching matching;
  list<Integer> indicesDynamic, indicesDiscrete, indicesAlgebraic, indicesZC;
  list<DAE.ComponentRef> eqnCrefs;
  TraverseIndicesTuple traverseArgs;
  array<Integer> assigndEqn, assigndVar, markedEqns;
  BackendDAE.EqSystems newEqs = {};
  array<Integer> zceqnsmarks;

  BackendDAE.IncidenceMatrix adjMatrix, adjMatrixT;

  BackendDAE.ZeroCrossingSet zeroCrossingsSet;
  list<BackendDAE.ZeroCrossing> zeroCrossings;

  constant Boolean debug = false;
algorithm

  // get zeroCrossings
  zeroCrossings := ZeroCrossings.toList(inBackendDAE.shared.eventInfo.zeroCrossings);

  // walk once through all comps and get of dependends of dynamic, algebraic, zeroCrossings,
  for eqSystem in inBackendDAE.eqs loop
    if debug then
      BackendDump.printEqSystem(eqSystem);
    end if;

    vars := eqSystem.orderedVars;
    eqns := eqSystem.orderedEqs;

    try
      (matching as BackendDAE.MATCHING(ass2=assigndEqn,ass1=assigndVar)) := eqSystem.matching;
      (eqSystem, adjMatrix, adjMatrixT) := getIncidenceMatrixfromOption(eqSystem, BackendDAE.ABSOLUTE(), SOME(inBackendDAE.shared.functionTree));

      // collect all dynamic, discrete, algebraic equations
      traverseArgs := ({}, {}, {});
      traverseArgs := BackendDAEUtil.traverseEqSystemStrongComponents(eqSystem, collectEqnsIndexByKind, traverseArgs);
      ((indicesDynamic, indicesDiscrete, indicesAlgebraic)) := traverseArgs;

      if debug then
        print("Dynamic equation indicies:\n");
        print(stringDelimitList(list(intString(i) for i in indicesDynamic), ", "));
        print("\n");
      end if;

      markedEqns := arrayCreate(BackendEquation.getNumberOfEquations(eqns), 0);
      markedEqns := markStateEquationsWork(indicesDynamic, adjMatrix, assigndVar, markedEqns);
      eqns := setMarkedEqnsEvalStage(eqns, markedEqns, BackendEquation.setEvalStageDynamic);

      markedEqns := arrayCreate(BackendEquation.getNumberOfEquations(eqns), 0);
      markedEqns := markZeroCrossingEquations(eqSystem, zeroCrossings, markedEqns, assigndVar);
      eqns := setMarkedEqnsEvalStage(eqns, markedEqns, BackendEquation.setEvalStageZeroCross);

      markedEqns := arrayCreate(BackendEquation.getNumberOfEquations(eqns), 0);
      markedEqns := markStateEquationsWork(indicesAlgebraic, adjMatrix, assigndVar, markedEqns);
      eqns := setMarkedEqnsEvalStage(eqns, markedEqns, BackendEquation.setEvalStageAlgebraic);

      /* For now avoid this and evaluate all the event update breaks right now
         quite a lot models.
      */
      markedEqns := arrayCreate(BackendEquation.getNumberOfEquations(eqns), 1);
      //markedEqns := markStateEquationsWork(indicesDiscrete, adjMatrix, assigndVar, markedEqns);
      //markedEqns := markStateEquationsWork(indicesDiscrete, adjMatrixT, assigndVar, markedEqns);
      eqns := setMarkedEqnsEvalStage(eqns, markedEqns, BackendEquation.setEvalStageDiscrete);
    else
      /* in case something goes wrong above mark all equation to be evaluated always */
      markedEqns := arrayCreate(BackendEquation.getNumberOfEquations(eqns), 1);
      eqns := setMarkedEqnsEvalStage(eqns, markedEqns, BackendEquation.setEvalStageAll);
    end try;

    if debug then
      BackendDump.dumpEquationArray(eqns, "Updated equations");
    end if;

    // update EvaluationState in EquationArray
    newEqs := eqSystem::newEqs;
  end for;

  // update BackendDAE.DAE
  outBackendDAE := BackendDAE.DAE(newEqs, inBackendDAE.shared);

end setEvaluationStage;

protected function setMarkedEqnsEvalStage
  input output BackendDAE.EquationArray eqns;
  input array<Integer> markEqns;
  input setEvalStage func;
  partial function setEvalStage
    input output BackendDAE.EvaluationStages evalStage;
  end setEvalStage;
protected
  BackendDAE.Equation eqn;
  Integer eqnIndex;
algorithm
  for i in 1:arrayLength(markEqns) loop
    if markEqns[i]>0 then
      eqn := BackendEquation.get(eqns, i);
      eqn := BackendEquation.setEquationEvalStage(eqn, func);
      eqns := BackendEquation.setAtIndex(eqns, i, eqn);
    end if;
  end for;
end setMarkedEqnsEvalStage;

protected function collectEqnsIndexByKind
"This function collects equation indices by kind.
 "
  input list<BackendDAE.Equation> inEqns;
  input list<BackendDAE.Var> inVars;
  input list<Integer> varIdxs;
  input list<Integer> eqnIdxs;
  input output TraverseIndicesTuple traverserArgs;
protected
  list<Integer> indicesDynamic, indicesDiscrete, indicesAlgebraic;
algorithm
  (indicesDynamic, indicesDiscrete, indicesAlgebraic) := traverserArgs;
  for v in inVars loop
    // discrete equations are detected by the corresponding variables
    if BackendVariable.isVarDiscrete(v) then
      indicesDiscrete := listAppend(eqnIdxs, indicesDiscrete);
    end if;
  end for;

  for eq in inEqns loop
    // dynamic
    if BackendEquation.isDynamicEquation(eq) then
      indicesDynamic := listAppend(eqnIdxs, indicesDynamic);
    end if;
    // select also continuos equation
    if BackendEquation.isAuxEquation(eq) then
      indicesAlgebraic := listAppend(eqnIdxs, indicesAlgebraic);
    end if;
  end for;

  traverserArgs := (indicesDynamic, indicesDiscrete, indicesAlgebraic);
end collectEqnsIndexByKind;

public function subscript2dCombinations
"This function takes two lists of list of subscripts and combines them in
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
  outExpSubscriptLstLst := match (inExpSubscriptLstLst1,inExpSubscriptLstLst2)
    local
      list<list<DAE.Subscript>> lst1,lst2,res,ss,ss2;
      list<DAE.Subscript> s1;

    case ({},_) then {};

    case ((s1::ss),ss2)
      equation
        lst1 = subscript2dCombinations2(s1, ss2);
        lst2 = subscript2dCombinations(ss, ss2);
        res = listAppend(lst1, lst2);
      then
        res;
  end match;
end subscript2dCombinations;

protected function subscript2dCombinations2
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := match (inExpSubscriptLst,inExpSubscriptLstLst)
    local
      list<list<DAE.Subscript>> lst1,ss2;
      list<DAE.Subscript> elt1,ss,s2;

    case (_,{}) then {};

    case (ss,(s2::ss2))
      equation
        lst1 = subscript2dCombinations2(ss, ss2);
        elt1 = listAppend(ss, s2);
      then
        (elt1::lst1);
  end match;
end subscript2dCombinations2;

public function splitoutEquationAndVars
" author: wbraun"
  input BackendDAE.StrongComponents inNeededBlocks;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqnsNew;
  input BackendDAE.Variables inVarsNew;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.Variables outVars;
algorithm
  (outEqns,outVars) := match(inNeededBlocks,inEqns,inVars, inEqnsNew, inVarsNew)
  local
    BackendDAE.StrongComponent comp;
    BackendDAE.StrongComponents rest;
    BackendDAE.Equation eqn;
    BackendDAE.Var var;
    list<BackendDAE.Equation> eqn_lst;
    list<BackendDAE.Var> var_lst;
    BackendDAE.EquationArray eqnsNew;
    BackendDAE.Variables varsNew;
    case ({},_,_,eqnsNew,varsNew) then (eqnsNew,varsNew);
    case (comp::rest,_,_,eqnsNew,varsNew)
      equation
      (eqnsNew,varsNew) = splitoutEquationAndVars(rest,inEqns,inVars,eqnsNew,varsNew);
      (eqn_lst,var_lst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, inEqns, inVars);
      eqnsNew = BackendEquation.addList(eqn_lst, eqnsNew);
      varsNew = BackendVariable.addVars(var_lst, varsNew);
    then (eqnsNew,varsNew);
 end match;
end splitoutEquationAndVars;

public function getStrongComponents
"author: Frenkel TUD 2011-11
  This function returns the strongComponents of a BackendDAE."
  input BackendDAE.EqSystem syst;
  output BackendDAE.StrongComponents outComps;
algorithm
  outComps := match(syst)
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=outComps))) then outComps;
    else {};
  end match;
end getStrongComponents;

public function getFunctions
"author: Frenkel TUD 2011-11
  This function returns the Functions of a BackendDAE."
  input BackendDAE.Shared shared;
  output DAE.FunctionTree functionTree;
algorithm
  BackendDAE.SHARED(functionTree=functionTree) := shared;
end getFunctions;

public function getGlobalKnownVarsFromShared
"function: getFunctions
  author: Frenkel TUD 2011-11
  This function returns known variable of a BackendDAE."
  input BackendDAE.Shared shared;
  output BackendDAE.Variables globalKnownVars;
algorithm
  BackendDAE.SHARED(globalKnownVars=globalKnownVars) := shared;
end getGlobalKnownVarsFromShared;

public function getExtraInfo
"function: getExtraInfo
  This function returns extra info of a BackendDAE."
  input BackendDAE.Shared shared;
  output BackendDAE.ExtraInfo einfo;
algorithm
  BackendDAE.SHARED(info=einfo) := shared;
end getExtraInfo;


public function reduceEqSystemsInDAE
"Function reduces BackendDAE system by filtering
the equation and select only the one that are needed
to calculate the given varibales.
"
  input BackendDAE.BackendDAE inDAE;
  input list<BackendDAE.Var> iVarlst;
  input Boolean makeMatching = true;
  output BackendDAE.BackendDAE outDAE;

protected
  BackendDAE.Shared shared;
  list<BackendDAE.EqSystem> systs;
  BackendDAE.EqSystem tmpsyst;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  outDAE := BackendDAE.DAE(list(tryReduceEqSystem(syst, shared, iVarlst) for syst in systs), shared);
  if makeMatching then
    outDAE := BackendDAEUtil.transformBackendDAE(outDAE,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
  end if;
end reduceEqSystemsInDAE;

public function tryReduceEqSystem
" Helpfunction to reduceEqSystemsInDAE.
"
  input BackendDAE.EqSystem iSyst;
  input BackendDAE.Shared shared;
  input list<BackendDAE.Var> iVarlst;
  output BackendDAE.EqSystem oSyst;
algorithm
  try
    //BackendDump.dumpEqSystem(iSyst,"IN: tryReduceEqSystem");
    oSyst := reduceEqSystem(iSyst, shared, iVarlst);
    //BackendDump.dumpEqSystem(oSyst,"OUT: tryReduceEqSystem");
  else
    oSyst := iSyst;
  end try;
end tryReduceEqSystem;


public function reduceEqSystem
"Function reduces BackendDAE.EqSystem system by filtering
the equation and select only the one that are needed
to calculate the given varibales. Shared object is used
only to get the functionsTree.
"
  input BackendDAE.EqSystem iSyst;
  input BackendDAE.Shared shared;
  input list<BackendDAE.Var> iVarlst;
  output BackendDAE.EqSystem oSyst;

protected
   array<Integer> ass1, ass2;
   BackendDAE.Variables v;
   BackendDAE.EqSystem syst;
   BackendDAE.Variables iVars = BackendVariable.listVar(iVarlst);
   BackendDAE.EquationArray ordererdEqs, arrEqs;
   list<Integer> indx_lst_v, indx_lst_e, ind_mark, statevarindx_lst;
   array<Integer> indx_arr;
   list<BackendDAE.Equation> el;
   list<BackendDAE.Var> vl;

   DAE.FunctionTree funcs;
   BackendDAE.IncidenceMatrix m;
algorithm
  oSyst := match iSyst
    case syst as BackendDAE.EQSYSTEM( orderedEqs=ordererdEqs, orderedVars=v,
                                      matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2) )
      algorithm
        if (Flags.getConfigEnum(Flags.SYM_SOLVER) > 0) then
          (_,statevarindx_lst) := BackendVariable.getAllAlgStateVarIndexFromVariables(v);
        else
          (_,statevarindx_lst) := BackendVariable.getAllStateVarIndexFromVariables(v);
        end if;
        indx_lst_v := BackendVariable.getVarIndexFromVariables(iVars, v);

        indx_lst_v := listAppend(indx_lst_v, statevarindx_lst) "overestimate";
        indx_lst_e := List.map1r(indx_lst_v, arrayGet, ass1);

        indx_arr := arrayCreate(equationArraySizeDAE(iSyst), 0);
        funcs := getFunctions(shared);
        (_, m, _) := getIncidenceMatrix(iSyst, BackendDAE.SPARSE(), SOME(funcs));

        indx_arr := markStateEquationsWork(indx_lst_e,  m, ass1, indx_arr);

        indx_lst_e := Array.foldIndex(indx_arr, translateArrayList, {});

        el := BackendEquation.getList(indx_lst_e, ordererdEqs);
        arrEqs := BackendEquation.listEquation(el);
        vl := BackendEquation.equationsVars(arrEqs, v);

        syst.orderedVars := BackendVariable.listVar1(vl);
        syst.orderedEqs := arrEqs;
        syst.stateSets := {};
      then BackendDAEUtil.clearEqSyst(syst);
  end match;
end reduceEqSystem;

public function introduceOutputAliases
  input output BackendDAE.BackendDAE dae;
protected
  BackendDAE.EqSystems systems, returnSysts = {};
  BackendDAE.Variables vars, newVars;
  BackendDAE.EquationArray eqs;
  list<BackendDAE.Equation> newEqns;
  DAE.ComponentRef newCref, cref;
  BackendDAE.Var newVar;
  BackendDAE.Equation newEqn;
  HashSet.HashSet topLevelOutputs = HashSet.emptyHashSet();
algorithm
  systems := dae.eqs;
  for system in systems loop
    eqs := system.orderedEqs;
    vars := system.orderedVars;
    newVars := BackendVariable.emptyVarsSized(realInt(intReal(BackendVariable.varsSize(vars)) * 1.4));
    newEqns := {};

    for v in BackendVariable.varList(vars) loop
      if not BackendVariable.isVarOnTopLevelAndOutput(v) then
        newVars := BackendVariable.addVar(v, newVars);
      else
        cref := BackendVariable.varCref(v);
        topLevelOutputs := BaseHashSet.add(cref, topLevelOutputs);

        // generate new internal alias var
        newCref := ComponentReference.prependStringCref(BackendDAE.outputAliasPrefix, cref);
        newVar := BackendVariable.copyVarNewName(newCref, v);
        newVar := BackendVariable.setVarDirection(newVar, DAE.BIDIR());
        newVars := BackendVariable.addVar(newVar, newVars);

        // update output to ordinary variable
        v := BackendVariable.setVarKind(v, BackendDAE.VARIABLE());
        v := BackendVariable.removeFixedAttribute(v);
        v := BackendVariable.removeStartAttribute(v);
        newVars := BackendVariable.addVar(v, newVars);

        // generate new equation and add it
        newEqn := BackendEquation.generateEquation(Expression.crefToExp(cref), Expression.crefToExp(newCref), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
        newEqns := newEqn::newEqns;
      end if;
    end for;

    _ := traverseBackendDAEExpsEqns(eqs, introduceOutputAliases_eqs, topLevelOutputs);
    eqs := BackendEquation.addList(newEqns, eqs);
    system.orderedVars := newVars;
    system.orderedEqs := eqs;
    returnSysts := system::returnSysts;
  end for;

  returnSysts := listReverse(returnSysts);
  dae.eqs := returnSysts;
end introduceOutputAliases;

protected function introduceOutputAliases_eqs
  input DAE.Exp inExp;
  input HashSet.HashSet inStates;
  output DAE.Exp outExp;
  output HashSet.HashSet outStates;
algorithm
  (outExp, outStates) := Expression.traverseExpBottomUp(inExp, introduceOutputAliases_eqs2, inStates);
end introduceOutputAliases_eqs;

protected function introduceOutputAliases_eqs2
  input DAE.Exp inExp;
  input HashSet.HashSet inStates;
  output DAE.Exp outExp;
  output HashSet.HashSet outStates = inStates;
algorithm
  outExp := match inExp
    local
      DAE.Exp e1;
      DAE.ComponentRef cr, newCref;

    // replace der(cr) with der(<outputAliasPrefix> + cr)
    case e1 as DAE.CREF(componentRef=cr) guard BaseHashSet.has(cr, inStates) algorithm
      newCref := ComponentReference.prependStringCref(BackendDAE.outputAliasPrefix, cr);
      e1.componentRef := newCref;
    then e1;

    else inExp;
  end match;
end introduceOutputAliases_eqs2;

protected function translateArrayList
  input Integer inElement;
  input Integer inIndex;
  input list<Integer> inFoldArg;
  output list<Integer> outFoldArg;
algorithm
  outFoldArg := if intEq(inElement, 1) then inIndex::inFoldArg else inFoldArg;
end translateArrayList;

public function removeDiscreteAssignments "
Author: wbraun
Function tarverse Statements and remove discrete one"
  input list<DAE.Statement> inStmts;
  input BackendDAE.Variables inVars;
  output list<DAE.Statement> outStmts;
algorithm
  outStmts := matchcontinue(inStmts,inVars)
    local
      list<DAE.Statement> stmts,rest,xs;
      DAE.Else algElse;
      DAE.Statement stmt,ew;
      DAE.ComponentRef cref;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.Exp e;
      DAE.ElementSource source;

      DAE.Type tp;
      Boolean b1;
      String id1;
      Integer index;

      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case ({},_) then ({});

    case ((DAE.STMT_ASSIGN(exp1 = e)::rest),vars)
      equation
        cref = Expression.expCref(e);
        ({v},_) = BackendVariable.getVar(cref,vars);
        true = BackendVariable.isVarDiscrete(v);
        xs = removeDiscreteAssignments(rest,vars);
      then xs;

    /*case ((DAE.STMT_TUPLE_ASSIGN(expExpLst = expl1)::rest),vars)
      equation
        crefLst = List.map(expl1,Expression.expCref);
        (vlst,_) = List.map1_2(crefLst,BackendVariable.getVar,vars);
        //blst = List.map(vlst,BackendVariable.isVarDiscrete);
        //true = boolOrList(blst);
        xs = removeDiscreteAssignments(rest,vars);
      then xs;
      */
    case ((DAE.STMT_ASSIGN_ARR(lhs = e)::rest),vars)
      equation
        cref = Expression.expCref(e);
        ({v},_) = BackendVariable.getVar(cref,vars);
        true = BackendVariable.isVarDiscrete(v);
        xs = removeDiscreteAssignments(rest,vars);
      then xs;

    case (((DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source))::rest),vars)
      equation
        stmts = removeDiscreteAssignments(stmts,vars);
        algElse = removediscreteAssingmentsElse(algElse,vars);
        xs = removeDiscreteAssignments(rest,vars);
      then DAE.STMT_IF(e,stmts,algElse,source)::xs;

    case (((DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,index=index,range=e,statementLst=stmts, source = source))::rest),vars)
      equation
        stmts = removeDiscreteAssignments(stmts,vars);
        xs = removeDiscreteAssignments(rest,vars);
      then DAE.STMT_FOR(tp,b1,id1,index,e,stmts,source)::xs;

    case (((DAE.STMT_WHILE(exp=e,statementLst=stmts, source = source))::rest),vars)
      equation
        stmts = removeDiscreteAssignments(stmts,vars);
        xs = removeDiscreteAssignments(rest,vars);
      then DAE.STMT_WHILE(e,stmts,source)::xs;

    case (((DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=NONE(),source=source))::rest),vars)
      equation
        stmts = removeDiscreteAssignments(stmts,vars);
        xs = removeDiscreteAssignments(rest,vars);
      then DAE.STMT_WHEN(e,conditions,initialCall,stmts,NONE(),source)::xs;

    case (((DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=SOME(ew),source=source))::rest),vars)
      equation
        stmts = removeDiscreteAssignments(stmts,vars);
        {ew} = removeDiscreteAssignments({ew},vars);
        xs = removeDiscreteAssignments(rest,vars);
      then DAE.STMT_WHEN(e,conditions,initialCall,stmts,SOME(ew),source)::xs;

    case ((stmt::rest),vars)
      equation
        xs = removeDiscreteAssignments(rest,vars);
      then  stmt::xs;
  end matchcontinue;
end removeDiscreteAssignments;

protected function removediscreteAssingmentsElse "author: wbraun
  Helper function for traverseDAEEquationsELse"
  input DAE.Else inElse;
  input BackendDAE.Variables inVars;
  output DAE.Else outElse;
algorithm
  outElse := match(inElse,inVars)
  local
    DAE.Exp e;
    list<DAE.Statement> st;
    DAE.Else el;
    BackendDAE.Variables vars;
  case(DAE.NOELSE(),_) then (DAE.NOELSE());
  case(DAE.ELSEIF(e,st,el),vars)
    equation
      el = removediscreteAssingmentsElse(el,vars);
      st = removeDiscreteAssignments(st,vars);
    then DAE.ELSEIF(e,st,el);
  case(DAE.ELSE(st),vars)
    equation
      st = removeDiscreteAssignments(st,vars);
    then DAE.ELSE(st);
end match;
end removediscreteAssingmentsElse;

public function collateAlgorithm "
Author: Frenkel TUD 2010-07"
  input DAE.Algorithm inAlg;
  input Option<DAE.FunctionTree> infuncs;
  output DAE.Algorithm outAlg;
algorithm
  outAlg := matchcontinue(inAlg,infuncs)
    local list<DAE.Statement> statementLst;
    case(DAE.ALGORITHM_STMTS(statementLst=statementLst),_)
      equation
        (statementLst,_) = DAEUtil.traverseDAEStmts(statementLst, collateArrExpStmt, infuncs);
      then
        DAE.ALGORITHM_STMTS(statementLst);
    else inAlg;
  end matchcontinue;
end collateAlgorithm;

protected function collateArrExpStmt "author: Frenkel TUD 2010-07
  wbraun: added as workaround for when condition.
  As long as we don't support fully array helpVars,
  we can't collate the expression of a when condition."
  input DAE.Exp inExp;
  input DAE.Statement inStmt;
  input Option<DAE.FunctionTree> funcs;
  output DAE.Exp outExp = inExp;
  output Option<DAE.FunctionTree> oarg = funcs;
algorithm
  try
    outExp := Expression.traverseExpBottomUp(outExp, traversingcollateArrExpStmt, (inStmt, funcs));
  else
  end try;
end collateArrExpStmt;

protected function traversingcollateArrExpStmt "wbraun: added as workaround for when condition.
  As long as we don't support fully array helpVars,
  we can't collate the expression of a when condition."
  input DAE.Exp inExp;
  input tuple<DAE.Statement, Option<DAE.FunctionTree>> inTpl;
  output DAE.Exp outExp;
  output tuple<DAE.Statement, Option<DAE.FunctionTree>> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      Option<DAE.FunctionTree> funcs;
      DAE.ComponentRef cr;
      DAE.Type ty;
      Integer i;
      DAE.Exp e,e1,e1_1,e1_2;
      Boolean b;
      DAE.Statement x;
    // do nothing if try to collate when codition expression
    case (e as DAE.MATRIX(matrix=((DAE.CREF())::_)::_), (DAE.STMT_WHEN(), _))
      then (e,inTpl);
    case (e as DAE.MATRIX(matrix=(((DAE.UNARY(exp = DAE.CREF())))::_)::_), (DAE.STMT_WHEN(), _))
      then (e,inTpl);
    case (e as DAE.ARRAY(array=(DAE.CREF())::_), (DAE.STMT_WHEN(), _))
      then (e,inTpl);
    case (e as DAE.ARRAY(array=(DAE.UNARY(exp = DAE.CREF()))::_), (DAE.STMT_WHEN(), _))
      then (e,inTpl);
     // collate in other cases
    case (e as DAE.MATRIX(matrix=((e1 as DAE.CREF())::_)::_), _)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,inTpl);
    case (e as DAE.MATRIX(matrix=(((e1 as DAE.UNARY(exp = DAE.CREF())))::_)::_), _)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,inTpl);
    case (e as DAE.ARRAY(array=(e1 as DAE.CREF())::_), _)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,inTpl);
    case (e as DAE.ARRAY(array=(e1 as DAE.UNARY(exp = DAE.CREF()))::_), _)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,inTpl);
    else (inExp,inTpl);
  end matchcontinue;
end traversingcollateArrExpStmt;

public function collateArrExpList
" author Frenkel TUD:
  replace {a[1],a[2],a[3]} for Real a[3] with a"
  input list<DAE.Exp> iexpl;
  input Option<DAE.FunctionTree> optfunc;
  output list<DAE.Exp> outexpl;
algorithm
  outexpl := match(iexpl,optfunc)
    local
      DAE.Exp e,e1;
      list<DAE.Exp> expl1,expl;

    case({},_) then {};

    case(e::expl,_) equation
      (e1,_) = collateArrExp(e,optfunc);
      expl1 = collateArrExpList(expl,optfunc);
    then
      e1::expl1;
  end match;
end collateArrExpList;

public function collateArrExp "
Author: Frenkel TUD 2010-07"
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> inFuncs;
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> outFuncs;
algorithm
  (outExp,outFuncs) := Expression.traverseExpBottomUp(inExp, traversingcollateArrExp, inFuncs);
end collateArrExp;

protected function traversingcollateArrExp
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> inFuncs;
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> funcs;
algorithm
  (outExp,funcs) := matchcontinue (inExp,inFuncs)
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
      Integer i;
      DAE.Exp e,e1,e1_1,e1_2;
      Boolean b;
    case (e as DAE.MATRIX(matrix=((e1 as DAE.CREF())::_)::_),funcs)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,funcs);

    case (e as DAE.MATRIX(matrix=(((e1 as DAE.UNARY(exp = DAE.CREF())))::_)::_),funcs)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,funcs);

    case (e as DAE.ARRAY(array=(e1 as DAE.CREF())::_),funcs)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,funcs);

    case (e as DAE.ARRAY(array=(e1 as DAE.UNARY(exp = DAE.CREF()))::_),funcs)
      equation
        e1_1 = Expression.expStripLastSubs(e1);
        (e1_2,true) = Expression.extendArrExp(e1_1,false);
        true = Expression.expEqual(e,e1_2);
      then (e1_1,funcs);

    else (inExp,inFuncs);
  end matchcontinue;
end traversingcollateArrExp;

public function getEquationBlock"author: PA

  Returns the block the equation belongs to.
"
  input Integer inInteger;
  input BackendDAE.StrongComponents inComps;
  output BackendDAE.StrongComponent outComp;
algorithm
  outComp:=
  matchcontinue (inInteger,inComps)
    local
      Integer i;
      list<Integer> elst;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp;
    case (i,comp::_)
      equation
        (elst,_) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        true = listMember(i,elst);
      then
        comp;
    case (i,_::comps)
      equation
        comp = getEquationBlock(i,comps);
      then
        comp;
  end matchcontinue;
end getEquationBlock;

/******************************************************************
 stuff to calculate incidence matrix

 wbraun: It should be renames to Adjacency matrix, because
    incidence matrix descibes the relation between knots and edges.
    In the sense it is used here is the relation between knots and
    knots of a bigraph.
******************************************************************/

public function incidenceMatrix
"author: PA, adrpo
  Calculates the incidence matrix, i.e. which variables are present in each equation.
  You can ask for absolute indexes or normal (negative for der) via the IndexType.
    wbraun: beware dim(IncidenceMatrix) != dim(IncidenceMatrixT) due to array equations. "
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
algorithm
  try
    BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns) := inEqSystem;
    (outIncidenceMatrix, outIncidenceMatrixT) :=
      incidenceMatrixDispatch(vars, eqns, inIndexType, functionTree);
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEUtil.incidenceMatrix failed."});
    fail();
  end try;
end incidenceMatrix;

public function incidenceMatrixMasked
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.IndexType inIndexType;
  input array<Boolean> inMask;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
algorithm
  try
    BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns) := inEqSystem;
    (outIncidenceMatrix, outIncidenceMatrixT) :=
      incidenceMatrixDispatchMasked(vars, eqns, inIndexType, inMask, functionTree);
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEUtil.incidenceMatrix failed."});
    fail();
  end try;
end incidenceMatrixMasked;

public function incidenceMatrixScalar
"author: PA, adrpo
  Calculates the incidence matrix, i.e. which variables are present in each equation.
  You can ask for absolute indexes or normal (negative for der) via the IndexType"
  input BackendDAE.EqSystem syst;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output array<list<Integer>> outMapEqnIncRow;
  output array<Integer> outMapIncRowEqn;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
algorithm
  try
    BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns) := syst;
    ExpandableArray.compress(eqns);
    (outIncidenceMatrix, outIncidenceMatrixT, outMapEqnIncRow, outMapIncRowEqn) :=
      incidenceMatrixDispatchScalar(vars, eqns, inIndexType, functionTree);
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAEUtil.incidenceMatrixScalar failed."});
    fail();
  end try;
end incidenceMatrixScalar;

protected function applyIndexType
"@author: adrpo
  Applies absolute value to all entries in the given list."
  input AvlSetInt.Tree inLst;
  input BackendDAE.IndexType inIndexType;
  output AvlSetInt.Tree outLst;
algorithm
  outLst := match(inLst, inIndexType)
    // transform to absolute indexes
    case (_, BackendDAE.ABSOLUTE())
      algorithm
        outLst := AvlSetInt.EMPTY();
        for key in AvlSetInt.listKeys(inLst) loop
          outLst := AvlSetInt.add(outLst, intAbs(key));
        end for;
    then outLst;

    // leave as it is
    else inLst;
  end match;
end applyIndexType;

public function incidenceMatrixDispatch
"@author: adrpo
  Calculates the incidence matrix as an array of list of integers"
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree = NONE();
  output BackendDAE.IncidenceMatrix outIncidenceArray;
  output BackendDAE.IncidenceMatrixT outIncidenceArrayT;
protected
  Integer num_eqs, num_vars;
  BackendDAE.Equation eq;
  list<Integer> row;
  AvlSetInt.Tree rowTree;
algorithm
  num_eqs := BackendEquation.getNumberOfEquations(inEqns);
  num_vars := BackendVariable.varsSize(inVars);
  outIncidenceArray := arrayCreate(num_eqs, {});
  outIncidenceArrayT := arrayCreate(num_vars, {});

  for idx in 1:num_eqs loop
    // Get the equation.
    eq := BackendEquation.get(inEqns, idx);
    // Compute the row.
    rowTree := incidenceRow(eq, inVars, inIndexType, functionTree, AvlSetInt.EMPTY());
    row := AvlSetInt.listKeys(rowTree);
    // Put it in the arrays.
    arrayUpdate(outIncidenceArray, idx, row);
    outIncidenceArrayT := fillincidenceMatrixT(row, {idx}, outIncidenceArrayT);
  end for;
end incidenceMatrixDispatch;

public function incidenceMatrixDispatchMasked
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.IndexType inIndexType;
  input array<Boolean> inMask;
  input Option<DAE.FunctionTree> functionTree = NONE();
  output BackendDAE.IncidenceMatrix outIncidenceArray;
  output BackendDAE.IncidenceMatrixT outIncidenceArrayT;
protected
  Integer num_eqs, num_vars;
  BackendDAE.Equation eq;
  list<Integer> row;
  AvlSetInt.Tree rowTree;
algorithm
  num_eqs := BackendEquation.getNumberOfEquations(inEqns);
  num_vars := BackendVariable.varsSize(inVars);
  outIncidenceArray := arrayCreate(num_eqs, {});
  outIncidenceArrayT := arrayCreate(num_vars, {});

  for idx in 1:num_eqs loop
    if inMask[idx] then
      // Get the equation.
      eq := BackendEquation.get(inEqns, idx);
      // Compute the row.
      rowTree := incidenceRow(eq, inVars, inIndexType, functionTree, AvlSetInt.EMPTY());
      row := AvlSetInt.listKeys(rowTree);
      // Put it in the arrays.
      arrayUpdate(outIncidenceArray, idx, row);
      outIncidenceArrayT := fillincidenceMatrixT(row, {idx}, outIncidenceArrayT);
    end if;
  end for;
end incidenceMatrixDispatchMasked;

protected function incidenceMatrixDispatchScalar
"@author: adrpo
  Calculates the incidence matrix as an array of list of integers"
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.IncidenceMatrix outIncidenceArray;
  output BackendDAE.IncidenceMatrixT outIncidenceArrayT = outIncidenceArrayT;
  output array<list<Integer>> omapEqnIncRow;
  output array<Integer> omapIncRowEqn;
protected
  Integer num_eqs, num_vars, size, num_rows = 0;
  BackendDAE.Equation eq;
  AvlSetInt.Tree rowTree;
  list<Integer> row, row_indices, imap = {};
  list<BackendDAE.IncidenceMatrixElement> iarr = {};
algorithm
  num_eqs := BackendEquation.getNumberOfEquations(inEqns);
  num_vars := BackendVariable.varsSize(inVars);
  outIncidenceArrayT := arrayCreate(num_vars, {});
  omapEqnIncRow := arrayCreate(num_eqs, {});

  for idx in 1:num_eqs loop
    // Get the equation.
    eq := BackendEquation.get(inEqns, idx);

    // Compute the row.
    (rowTree, size) := incidenceRow(eq, inVars, inIndexType, functionTree, AvlSetInt.EMPTY());
    row := AvlSetInt.listKeys(rowTree);
    row_indices := List.intRange2(num_rows + 1, num_rows + size);
    num_rows := num_rows + size;
    arrayUpdate(omapEqnIncRow, idx, row_indices);
    imap := List.consN(size, idx, imap);

    // Put it in the arrays
    iarr := List.consN(size, row, iarr);
    outIncidenceArrayT := fillincidenceMatrixT(row, row_indices, outIncidenceArrayT);
  end for;

  outIncidenceArray := List.listArrayReverse(iarr);
  omapIncRowEqn := List.listArrayReverse(imap);
end incidenceMatrixDispatchScalar;

protected function fillincidenceMatrixT
"@author: Frenkel TUD 2011-04
  inserts the equation numbers"
  input BackendDAE.IncidenceMatrixElement eqns;
  input list<Integer> eqnsindxs;
  input BackendDAE.IncidenceMatrixT inIncidenceArrayT;
  output BackendDAE.IncidenceMatrixT outIncidenceArrayT = inIncidenceArrayT;
protected
  BackendDAE.IncidenceMatrixElement row;
  list<Integer> ei;
algorithm
  for v in eqns loop
    if v < 0 then
      v := intAbs(v);
      ei := list(intNeg(e) for e in eqnsindxs);
    else
      ei := eqnsindxs;
    end if;

    // Put it in the array.
    row := listAppend(ei, arrayGet(inIncidenceArrayT, v));
    arrayUpdate(outIncidenceArrayT, v, row);
  end for;
end fillincidenceMatrixT;

public function incidenceRow
"author: PA
  Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for one equation."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables vars;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  input AvlSetInt.Tree iRow;
  output AvlSetInt.Tree outIntegerLst;
  output Integer rowSize;
protected
  list<Integer> whenIntegerLst;
algorithm
  whenIntegerLst := matchcontinue inIndexType
    local
      BackendDAE.EquationKind kind;
      DAE.ComponentRef cr;
      Integer i;
      list<Integer> varIxs;
    case BackendDAE.BASECLOCK_IDX()
      equation
        BackendDAE.EQUATION_ATTRIBUTES(kind = kind) = BackendEquation.getEquationAttributes(inEquation);
        BackendDAE.CLOCKED_EQUATION(i) = kind;
        cr = DAE.CREF_IDENT(BackendDAE.WHENCLK_PRREFIX + intString(i), DAE.T_CLOCK_DEFAULT, {});
        (_, varIxs) = BackendVariable.getVar(cr, vars);
      then varIxs;
    case BackendDAE.SUBCLOCK_IDX()
      equation
        BackendDAE.EQUATION_ATTRIBUTES(kind = kind) = BackendEquation.getEquationAttributes(inEquation);
        BackendDAE.CLOCKED_EQUATION(i) = kind;
        cr = DAE.CREF_IDENT(BackendDAE.WHENCLK_PRREFIX + intString(i), DAE.T_CLOCK_DEFAULT, {});
        (_, varIxs) = BackendVariable.getVar(cr, vars);
      then varIxs;
    else {};
  end matchcontinue;

  (outIntegerLst,rowSize) := matchcontinue (inEquation)
    local
      AvlSetInt.Tree lst1,lst2,res;
      list<Integer> dimsize;
      DAE.Exp e1,e2,e,expCref,cond;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      Integer size;
      String eqnstr, str;
      list<DAE.Statement> statementLst;
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Equation eqn;
      list<BackendDAE.WhenOperator> whenStmtLst;

    // EQUATION
    case BackendDAE.EQUATION(exp = e1,scalar = e2)
      equation
        lst1 = incidenceRowExp(e1, vars, iRow, functionTree, inIndexType);
        res = incidenceRowExp(e2, vars, lst1, functionTree, inIndexType);
      then
        (res,1);

    // COMPLEX_EQUATION
    case BackendDAE.COMPLEX_EQUATION(size=size,left=e1,right=e2)
      equation
        lst1 = incidenceRowExp(e1, vars, iRow, functionTree, inIndexType);
        res = incidenceRowExp(e2, vars, lst1, functionTree, inIndexType);
      then
        (res,size);

    // ARRAY_EQUATION
    case BackendDAE.ARRAY_EQUATION(dimSize=dimsize,left=e1,right=e2)
      equation
        size = if Flags.isSet(Flags.NF_SCALARIZE) then List.reduce(dimsize, intMul) else 1;
        lst1 = incidenceRowExp(e1, vars, iRow, functionTree, inIndexType);
        res = incidenceRowExp(e2, vars, lst1, functionTree, inIndexType);
      then
        (res,size);

    // FOR_EQUATION
    case BackendDAE.FOR_EQUATION(body = eqn, iter = DAE.CREF(componentRef = DAE.CREF_IDENT(ident = str)))
      equation
        // assume one equation defining a whole array var (no NF_SCALARIZE)
        eqn = BackendEquation.traverseExpsOfEquation(eqn, function Expression.traverseExpTopDown(func = stripIterSub), str);
      then
        incidenceRow(eqn, vars, inIndexType, functionTree, iRow);

    // SOLVED_EQUATION
    case BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e)
      equation
        expCref = Expression.crefExp(cr);
        lst1 = incidenceRowExp(expCref, vars, iRow, functionTree, inIndexType);
        res = incidenceRowExp(e, vars, lst1, functionTree, inIndexType);
      then
        (res,1);

    // RESIDUAL_EQUATION
    case BackendDAE.RESIDUAL_EQUATION(exp = e)
      equation
        res = incidenceRowExp(e, vars, iRow, functionTree, inIndexType);
      then
        (res,1);

    // WHEN_EQUATION
    case BackendDAE.WHEN_EQUATION(size=size,whenEquation = we)
      equation
        res = incidenceRowWhen(we, vars, inIndexType, functionTree, iRow);
      then
        (res,size);

    // ALGORITHM For now assume that algorithm will be solvable for
    // correct variables. I.e. find all variables in algorithm and add to lst.
    // If algorithm later on needs to be inverted, i.e. solved for
    // different variables than calculated, a non linear solver or
    // analysis of algorithm itself needs to be implemented.
    case BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS(statementLst = statementLst))
      equation
        res = traverseStmts(statementLst, function incidenceRowAlgorithm(inVariables = vars,
          functionTree = functionTree, inIndexType = inIndexType), iRow);
      then
        (res,size);

    // if Equation
    case BackendDAE.IF_EQUATION(conditions=expl,eqnstrue=eqnslst,eqnsfalse=eqns)
      equation
        res = incidenceRow1(expl, incidenceRowExp, vars, iRow, functionTree, inIndexType);
        res = incidenceRowLstLst(eqnslst, vars, inIndexType, functionTree, res);
        (res,size) = incidenceRowLst(eqns, vars, inIndexType, functionTree, res);
      then
        (res,size);

    else
      equation
        eqnstr = BackendDump.equationString(inEquation);
        str = "- BackendDAEUtil.incidenceRow failed for equation: " + eqnstr;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
  outIntegerLst := AvlSetInt.addList(outIntegerLst, whenIntegerLst);
end incidenceRow;

protected
function stripIterSub
"Strips the last subscript if it is equal to given inIter ident.
 This enables incicence analysis for array variables defined in for loops.
 author: rfranke"
  input DAE.Exp inExp;
  input DAE.Ident inIter;
  output DAE.Exp outExp;
  output Boolean cont;
  output DAE.Ident outIter = inIter;
algorithm
  (outExp, cont) := match inExp
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
    case DAE.CREF(componentRef = cr, ty = ty)
    then (DAE.CREF(ComponentReference.crefStripIterSub(cr, inIter), ty), false);
    else (inExp, true);
  end match;
end stripIterSub;

protected function incidenceRowLst
"author: Frenkel TUD
  Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for if equation."
  input list<BackendDAE.Equation> inEquation;
  input BackendDAE.Variables inVariables;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  input AvlSetInt.Tree inIntegerLst;
  output AvlSetInt.Tree outIntegerLst = inIntegerLst;
  output Integer rowSize = 0;
protected
  Integer size;
algorithm
  for eq in inEquation loop
    (outIntegerLst, size) :=
      incidenceRow(eq, inVariables, inIndexType, functionTree, outIntegerLst);
    rowSize := rowSize + size;
  end for;
end incidenceRowLst;

protected function incidenceRowLstLst
"author: Frenkel TUD
  Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for if equation."
  input list<list<BackendDAE.Equation>> inEquation;
  input BackendDAE.Variables inVariables;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  input AvlSetInt.Tree inIntegerLst;
  output AvlSetInt.Tree outIntegerLst = inIntegerLst;
  output Integer rowSize = 0;
protected
  Integer size;
algorithm
  for eql in inEquation loop
    (outIntegerLst, size) := incidenceRowLst(eql, inVariables, inIndexType,
        functionTree, outIntegerLst);
    rowSize := rowSize + size;
  end for;
end incidenceRowLstLst;

protected function incidenceRowWhen
"Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for a when equation."
  input BackendDAE.WhenEquation inEquation;
  input BackendDAE.Variables inVariables;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  input AvlSetInt.Tree inRow;
  output AvlSetInt.Tree outRow;
algorithm
  outRow := match (inEquation)
    local
      list<Integer> res;
      DAE.Exp e1, e2, cond;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation elsewe;
      Option<BackendDAE.WhenEquation> oelsewe;
      list<BackendDAE.WhenOperator> whenStmtLst;

    case BackendDAE.WHEN_STMTS(condition = cond, whenStmtLst = whenStmtLst, elsewhenPart = oelsewe)
      algorithm
        outRow := incidenceRowExp(cond, inVariables, inRow, functionTree, inIndexType);
        outRow := incidenceRowWhenOps(whenStmtLst, inVariables, inIndexType, functionTree, outRow);

        if isSome(oelsewe) then
          SOME(elsewe) := oelsewe;
          outRow := incidenceRowWhen(elsewe, inVariables, inIndexType, functionTree, outRow);
        end if;
    then outRow;
  end match;
end incidenceRowWhen;

protected function incidenceRowWhenOps
"Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for a when equation stmts."
  input list<BackendDAE.WhenOperator>  inWhenOps;
  input BackendDAE.Variables inVariables;
  input BackendDAE.IndexType inIndexType;
  input Option<DAE.FunctionTree> functionTree;
  input AvlSetInt.Tree inRow;
  output AvlSetInt.Tree outRow;
algorithm
  outRow := match (inWhenOps)
    local
      DAE.Exp e1, e2;
      DAE.ComponentRef cr;
      list<BackendDAE.WhenOperator> rest;

    case {} then inRow;
    case (BackendDAE.ASSIGN(left = DAE.CREF(componentRef = DAE.WILD()), right = e2)::rest)
      equation
        outRow = incidenceRowExp(e2, inVariables, inRow, functionTree, inIndexType);
        outRow = incidenceRowWhenOps(rest, inVariables, inIndexType, functionTree, outRow);
    then outRow;

    case (BackendDAE.ASSIGN(left = e1, right = e2)::rest)
      equation
        //e1 = Expression.crefExp(cr);
        outRow = incidenceRowExp(e1, inVariables, inRow, functionTree, inIndexType);
        outRow = incidenceRowExp(e2, inVariables, outRow, functionTree, inIndexType);
        outRow = incidenceRowWhenOps(rest, inVariables, inIndexType, functionTree, outRow);
    then outRow;

    case (BackendDAE.REINIT(stateVar = cr, value = e2)::rest)
      equation
        e1 = Expression.crefExp(cr);
        outRow = incidenceRowExp(e1, inVariables, inRow, functionTree, inIndexType);
        outRow = incidenceRowExp(e2, inVariables, outRow, functionTree, inIndexType);
        outRow = incidenceRowWhenOps(rest, inVariables, inIndexType, functionTree, outRow);
    then outRow;
    case (BackendDAE.ASSERT(condition = e1, message = e2)::rest)
      equation
        outRow = incidenceRowExp(e1, inVariables, inRow, functionTree, inIndexType);
        outRow = incidenceRowExp(e2, inVariables, outRow, functionTree, inIndexType);
        outRow = incidenceRowWhenOps(rest, inVariables, inIndexType, functionTree, outRow);
    then outRow;
    case (BackendDAE.TERMINATE(message = e1)::rest)
      equation
        outRow = incidenceRowExp(e1, inVariables, inRow, functionTree, inIndexType);
        outRow = incidenceRowWhenOps(rest, inVariables, inIndexType, functionTree, outRow);
    then outRow;
    case (BackendDAE.NORETCALL(exp = e1)::rest)
      equation
        outRow = incidenceRowExp(e1, inVariables, inRow, functionTree, inIndexType);
        outRow = incidenceRowWhenOps(rest, inVariables, inIndexType, functionTree, outRow);
    then outRow;
  end match;
end incidenceRowWhenOps;

protected function incidenceRowAlgorithm
  input DAE.Exp exp;
  input output AvlSetInt.Tree row;
  input BackendDAE.Variables inVariables;
  input Option<DAE.FunctionTree> functionTree;
  input BackendDAE.IndexType inIndexType;
algorithm
  row := incidenceRowExp(exp, inVariables, row, functionTree, inIndexType);
end incidenceRowAlgorithm;

public function incidenceRow1
  "Tail recursive implementation."
  input list<Type_a> inList;
  input FuncType inFunc;
  input Type_b inArg;
  input Type_c inArg1;
  input Type_d inArg2;
  input Type_e inArg3;
  output Type_c outArg1;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;

  partial function FuncType
    input Type_a inElem;
    input Type_b inArg;
    input Type_c inArg1;
    input Type_d inArg2;
    input Type_e inArg3;
    output Type_c outArg1;
  end FuncType;
algorithm
  outArg1 := match(inList, inFunc, inArg, inArg1, inArg2, inArg3)
    local
      Type_a e1;
      list<Type_a> rest_e1;
      Type_c res,res1;
    case ({}, _, _, _, _, _) then inArg1;
    case (e1::rest_e1, _, _, _, _, _)
      equation
        res = inFunc(e1, inArg, inArg1, inArg2, inArg3);
        res1 = incidenceRow1(rest_e1, inFunc, inArg, res, inArg2, inArg3);
      then
        res1;
  end match;
end incidenceRow1;

public function incidenceRowExp "author: PA
  Helper function to incidenceRow, investigates expressions for variables,
  returning variable indexes."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input AvlSetInt.Tree inIntegerLst;
  input Option<DAE.FunctionTree> functionTree;
  input BackendDAE.IndexType inIndexType;
  output AvlSetInt.Tree outIntegerLst;
algorithm
  outIntegerLst := match inIndexType
    local
      AvlSetInt.Tree vallst;

    case BackendDAE.SPARSE() equation
      (_, (_, vallst)) = Expression.traverseExpTopDown(inExp, traversingincidenceRowExpFinderwithInput, (inVariables, inIntegerLst));
    then vallst;

    case BackendDAE.SOLVABLE() equation
      (_, (_, vallst, _, _)) = Expression.traverseExpTopDown(inExp, traversingincidenceRowExpSolvableFinder, (inVariables, inIntegerLst, AvlSetPath.EMPTY(), functionTree));
    then vallst;

    case BackendDAE.BASECLOCK_IDX() equation
      (_, (_, vallst)) = Expression.traverseExpTopDown(inExp, traversingIncidenceRowExpFinderBaseClock, (inVariables, inIntegerLst));
    then vallst;

    case BackendDAE.SUBCLOCK_IDX() equation
      (_, (_, vallst)) = Expression.traverseExpTopDown(inExp, traversingIncidenceRowExpFinderSubClock, (inVariables, inIntegerLst));
    then vallst;

    else equation
      (_, (_, vallst)) = Expression.traverseExpTopDown(inExp, traversingincidenceRowExpFinder, (inVariables, inIntegerLst));
      // only absolute indexes?
      vallst = applyIndexType(vallst, inIndexType);
    then vallst;
  end match;
end incidenceRowExp;

public function traversingincidenceRowExpSolvableFinder "Helper for statesAndVarsExp"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, AvlSetInt.Tree, AvlSetPath.Tree, Option<DAE.FunctionTree>> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables, AvlSetInt.Tree, AvlSetPath.Tree, Option<DAE.FunctionTree>> outTpl;
algorithm
  (outExp, cont, outTpl) := matchcontinue (inExp, inTpl)
    local
      list<Integer> p, p2, ilst;
      AvlSetInt.Tree pa;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e1, e2, startvalue, stopvalue, stepvalue;
      list<BackendDAE.Var> varslst;
      Boolean b;
      list<DAE.Exp> explst;
      Option<DAE.Exp> stepvalueopt;
      Integer i;
      list<DAE.ComponentRef> crlst;
      Option<DAE.FunctionTree> ofunctionTree;
      DAE.FunctionTree functionTree;
      tuple<BackendDAE.Variables, AvlSetInt.Tree, AvlSetPath.Tree, Option<DAE.FunctionTree>> tpl;
      Integer diffindx;
      list<DAE.Subscript> subs;
      AvlSetPath.Tree visitedPaths;
      String idn;

    case (DAE.LBINARY(), tpl)
    then (inExp, false, tpl);

    case (DAE.RELATION(), tpl)
    then (inExp, false, tpl);

    case (DAE.IFEXP(expThen=e1, expElse=e2), tpl) equation
      (_, tpl) = Expression.traverseExpTopDown(e1, traversingincidenceRowExpSolvableFinder, tpl);
      (_, tpl) = Expression.traverseExpTopDown(e2, traversingincidenceRowExpSolvableFinder, tpl);
    then (inExp, false, tpl);

    case (DAE.RANGE(), tpl)
    then (inExp, false, tpl);

    case (DAE.ASUB(exp=DAE.CREF(componentRef=cr), sub=explst), (vars, pa, visitedPaths, ofunctionTree))
      algorithm
        {e1 as DAE.RANGE()} := ExpressionSimplify.simplifyList(explst);
        subs := list(DAE.INDEX(e) for e in extendRange(e1, vars));
        crlst := list(ComponentReference.subscriptCref(cr, {s}) for s in subs);
        (varslst, p) := BackendVariable.getVarLst(crlst, vars);
        pa := incidenceRowExp1(varslst, p, pa, 0);
      then
        (inExp, false, (vars, pa, visitedPaths, ofunctionTree));

    case (DAE.ASUB(exp=e1, sub={DAE.ICONST(i)}), tpl) equation
      e1 = Expression.nthArrayExp(e1, i);
      (_, tpl) = Expression.traverseExpTopDown(e1, traversingincidenceRowExpSolvableFinder, tpl);
    then (inExp, false, tpl);

    // otherwise
    case (DAE.ASUB(), _)
    then fail();

    case (DAE.TSUB(exp=e1), tpl) equation
      (_, tpl) = Expression.traverseExpTopDown(e1, traversingincidenceRowExpSolvableFinder, tpl);
    then (inExp, false, tpl);

    // cref and $START.cref
    case (DAE.CREF(componentRef=cr), (vars, pa, visitedPaths, ofunctionTree)) equation
      (varslst, p) = BackendVariable.getVar(cr, vars);
      (_, p2) = BackendVariable.getVar(ComponentReference.crefPrefixStart(cr), vars);

      pa = incidenceRowExp1(varslst, p, pa, 0);
      pa = incidenceRowExp1(varslst, p2, pa, 0);
    then (inExp, true, (vars, pa, visitedPaths, ofunctionTree));

    // only cref
    case (DAE.CREF(componentRef=cr), (vars, pa, visitedPaths, ofunctionTree)) equation
      (varslst, p) = BackendVariable.getVar(cr, vars);
      pa = incidenceRowExp1(varslst, p, pa, 0);
    then (inExp, true, (vars, pa, visitedPaths, ofunctionTree));

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr)}), (vars, pa, visitedPaths, ofunctionTree)) equation
      (varslst, p) = BackendVariable.getVar(cr, vars);
      pa = incidenceRowExp1(varslst, p, pa, 1);
    then (inExp, false,(vars, pa, visitedPaths, ofunctionTree));

    /* higher derivative, is only present during index reduction */
    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr), DAE.ICONST(diffindx)}), (vars, pa, visitedPaths, ofunctionTree)) equation
      (varslst, p) = BackendVariable.getVar(cr, vars);
      pa = incidenceRowExp1(varslst, p, pa, diffindx);
    then (inExp, false,(vars, pa, visitedPaths, ofunctionTree));

    /* pre(v) is considered a known variable */
    /* previous(v) is considered a known variable */
    case (DAE.CALL(path=Absyn.IDENT(name=idn)), tpl) guard idn=="pre" or idn=="previous"
    then (inExp, false, tpl);

    /* delay(...) can be used to break algebraic loops given some solver options */
    case (DAE.CALL(path=Absyn.IDENT(name="delay"), expLst = {_, _, e1, e2}), tpl) equation
      b = Flags.getConfigBool(Flags.DELAY_BREAK_LOOP) and Expression.expEqual(e1, e2);
    then (inExp, not b, tpl);

    // use the inlined function to analyze the ocuring variables
    case (DAE.CALL(), (vars, pa, visitedPaths, ofunctionTree as SOME(functionTree))) guard not AvlSetPath.hasKey(visitedPaths, inExp.path)
      algorithm
        (e1,_) := Inline.forceInlineCall(inExp, {}, (SOME(functionTree), {DAE.NORM_INLINE(),DAE.DEFAULT_INLINE()}));
        false := referenceEq(inExp,e1);
        (_, tpl) := Expression.traverseExpTopDown(e1, traversingincidenceRowExpSolvableFinder, (vars, pa, AvlSetPath.add(visitedPaths, inExp.path), ofunctionTree));
      then (inExp, false, tpl);

    else (inExp, true, inTpl);
  end matchcontinue;
end traversingincidenceRowExpSolvableFinder;

public function traversingIncidenceRowExpFinderBaseClock "author: lochel
  This is used for base-clock partitioning."
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, AvlSetInt.Tree> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables, AvlSetInt.Tree> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,inTpl)
    local
      list<Integer> p, p2;
      AvlSetInt.Tree pa;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e;

    case (DAE.CREF(componentRef=cr), (vars, pa))
      equation
        (_, p) = BackendVariable.getVar(cr, vars);
        (_, p2) = BackendVariable.getVar(ComponentReference.crefPrefixStart(cr), vars);
        pa = AvlSetInt.addList(pa, p);
        pa = AvlSetInt.addList(pa, p2);
      then (inExp, true, (vars, pa));

    case (DAE.CREF(componentRef=cr), (vars, pa))
      equation
        (_, p) = BackendVariable.getVar(cr, vars);
      then (inExp, true, (vars, AvlSetInt.addList(pa, p)));

    case (DAE.CALL(path=Absyn.IDENT(name="sample"), expLst={_, e}), _)
      equation
        (_, outTpl) = Expression.traverseExpTopDown(e, traversingIncidenceRowExpFinderBaseClock, inTpl);
      then (inExp, false, outTpl);

    case (DAE.CLKCONST(DAE.SOLVER_CLOCK(e)), _)
      algorithm
        (_, outTpl) := Expression.traverseExpTopDown(e, traversingIncidenceRowExpFinderBaseClock, inTpl);
      then (inExp, true, outTpl);

    case (DAE.CLKCONST(DAE.BOOLEAN_CLOCK()), _)
      then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="hold")), _)
      then (inExp, false, inTpl);

    else (inExp, true, inTpl);
  end matchcontinue;
end traversingIncidenceRowExpFinderBaseClock;

public function traversingIncidenceRowExpFinderSubClock "author: lochel
  This is used for sub-clock partitioning.
  TODO: avoid code duplicates, cf. function traversingIncidenceRowExpFinderBaseClock"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, AvlSetInt.Tree> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables, AvlSetInt.Tree> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,inTpl)
    local
      list<Integer> p, p2;
      AvlSetInt.Tree pa, res;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;

    case (DAE.CREF(componentRef=cr), (vars, pa))
      equation
        (_, p) = BackendVariable.getVar(cr, vars);
        (_, p2) = BackendVariable.getVar(ComponentReference.crefPrefixStart(cr), vars);
        res = AvlSetInt.addList(pa, p);
        res = AvlSetInt.addList(res, p2);
      then (inExp, true, (vars, res));

    case (DAE.CREF(componentRef=cr), (vars, pa))
      equation
        (_, p) = BackendVariable.getVar(cr, vars);
        res = AvlSetInt.addList(pa, p);
      then (inExp, true, (vars, res));

    case (DAE.CALL(path=Absyn.IDENT(name="subSample")), _)
      then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="superSample")), _)
      then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="shiftSample")), _)
      then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="backSample")), _)
      then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="noClock")), _)
      then (inExp, false, inTpl);

    else (inExp, true, inTpl);
  end matchcontinue;
end traversingIncidenceRowExpFinderSubClock;

public function traversingincidenceRowExpFinder "
  author: Frenkel TUD 2010-11
  Helper for statesAndVarsExp"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,AvlSetInt.Tree> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,AvlSetInt.Tree> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue(inExp,inTpl)
    local
      list<Integer> p, p2;
      AvlSetInt.Tree pa,res;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e,e1,e2;
      list<BackendDAE.Var> varslst;
      Boolean b;
      Integer i;
      String str;

    // cref and $START.cref
    case (e as DAE.CREF(componentRef=cr), (vars, pa))
      equation
        (varslst, p) = BackendVariable.getVar(cr, vars);
        (_, p2) = BackendVariable.getVar(ComponentReference.crefPrefixStart(cr), vars);

        res = incidenceRowExp1(varslst, p, pa, 0);
        res = incidenceRowExp1(varslst, p2, res, 0);
      then (e, true, (vars, res));

    // only cref
    case (e as DAE.CREF(componentRef = cr),(vars,pa))
      equation
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1(varslst,p,pa,0);
      then (e, true, (vars,res));

    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa))
      equation
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1(varslst,p,pa,1);
        /* check also indizes of cr */
        (_,(_,res)) = Expression.traverseExpTopDownCrefHelper(cr, traversingincidenceRowExpFinder, (vars,res));
      then
        (e,false,(vars,res));

    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1(varslst,p,pa,1);
        /* check also indizes of cr */
        (_,(_,res)) = Expression.traverseExpTopDownCrefHelper(cr, traversingincidenceRowExpFinder, (vars,res));
      then (e,false,(vars,res));

    /* pre(v) is considered a known variable */
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF()}),_) then (inExp,false,inTpl);

    /* previous(v) is considered a known variable */
    case (DAE.CALL(path = Absyn.IDENT(name = "previous"),expLst = {DAE.CREF()}),_) then (inExp,false,inTpl);

    /* delay(e) can be used to break algebraic loops given some solver options */
    case (DAE.CALL(path = Absyn.IDENT(name = "delay"),expLst = {_,_,e1,e2}),_)
      equation
        b = Flags.getConfigBool(Flags.DELAY_BREAK_LOOP) and Expression.expEqual(e1,e2);
      then (inExp,not b,inTpl);

    case (DAE.ASUB(exp=DAE.CREF(componentRef=cr), sub={DAE.ICONST(i)}), (vars, pa))
      equation
        cr = ComponentReference.subscriptCrefWithInt(cr, i);
        (varslst, p) = BackendVariable.getVar(cr, vars);
        pa = incidenceRowExp1(varslst, p, pa, 0);
    then (inExp, false, (vars, pa));

    case (DAE.ASUB(exp = e1, sub={DAE.ICONST(i)}),(vars,_))
      equation
        e1 = Expression.nthArrayExp(e1, i);
        (_, (_, res)) = Expression.traverseExpTopDown(e1, traversingincidenceRowExpFinder, inTpl);
      then (inExp, false, (vars, res));

    case (DAE.ASUB(),(_,_))
      then fail();

    else (inExp,true,inTpl);
  end matchcontinue;
end traversingincidenceRowExpFinder;

protected function incidenceRowExp1
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  input AvlSetInt.Tree inVarIndxLst;
  input Integer diffindex;
  output AvlSetInt.Tree outVarIndxLst;
algorithm
  outVarIndxLst := match (inVarLst,inIntegerLst,inVarIndxLst,diffindex)
    local
       list<BackendDAE.Var> rest;
       list<Integer> irest;
       AvlSetInt.Tree vars;
       Integer i,i1,diffidx;
       Boolean b;
    case ({},{},vars,_) then vars;
    /*If variable x is a state, der(x) is a variable in incidence matrix,
         x is inserted as negative value, since it is needed by debugging and
         index reduction using dummy derivatives */
    case (BackendDAE.VAR(varKind = BackendDAE.STATE(derName=SOME(_)))::rest,i::irest,_,_)
      equation
        i1 = if intGe(diffindex,1) then i else -i;
        vars = AvlSetInt.add(inVarIndxLst, i1);
      then incidenceRowExp1(rest,irest,vars,diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.STATE(index=diffidx))::rest,i::irest,_,_)
      equation
        i1 = if intGe(diffindex,diffidx) then i else -i;
        vars = AvlSetInt.add(inVarIndxLst, i1);
      then incidenceRowExp1(rest,irest,vars,diffindex);
    case (_::rest,i::irest,_,_)
      equation
        vars = AvlSetInt.add(inVarIndxLst, i);
      then incidenceRowExp1(rest,irest,vars,diffindex);
  end match;
end incidenceRowExp1;

public function traversingincidenceRowExpFinderwithInput "Helper for statesAndVarsExp"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,AvlSetInt.Tree> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,AvlSetInt.Tree> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,inTpl)
  local
      list<Integer> p;
      AvlSetInt.Tree pa, res;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e;
      list<BackendDAE.Var> varslst;

    case (DAE.CREF(componentRef = cr),(vars,pa))
      equation
        cr = ComponentReference.makeCrefQual(BackendDAE.partialDerivativeNamePrefix, DAE.T_REAL_DEFAULT, {}, cr);
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1withInput(varslst,p,pa,0);
      then (inExp,false,(vars,res));

    case (DAE.CREF(componentRef=cr), (vars, pa))
      equation
        (varslst, p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1withInput(varslst, p, pa, 0);

        (varslst, p) = BackendVariable.getVar(ComponentReference.crefPrefixStart(cr), vars);
        res = incidenceRowExp1withInput(varslst, p, res, 0);
      then (inExp, true, (vars, res));

    case (DAE.CREF(componentRef = cr),(vars,pa))
      equation
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1withInput(varslst,p,pa,0);
      then (inExp, true, (vars, res));

    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa))
      equation
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1withInput(varslst,p,pa,1);
      then (inExp,false,(vars,res));

    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1withInput(varslst,p,pa,1);
      then (inExp,false,(vars,res));

    case (DAE.CALL(path = Absyn.IDENT(name = "previous"),expLst = {DAE.CREF(componentRef = cr)}),(vars,pa))
      equation
        cr = ComponentReference.makeCrefQual(DAE.previousNamePrefix, DAE.T_REAL_DEFAULT, {}, cr);
        (varslst,p) = BackendVariable.getVar(cr, vars);
        res = incidenceRowExp1withInput(varslst,p,pa,1);
      then (inExp,false,(vars,res));

    /* pre(v) is considered a known variable */
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF()}),_) then (inExp,false,inTpl);

    else (inExp,true,inTpl);
  end matchcontinue;
end traversingincidenceRowExpFinderwithInput;


protected function incidenceRowExp1withInput
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  input AvlSetInt.Tree vars;
  input Integer diffindex;
  output AvlSetInt.Tree outIntegerLst;
algorithm
  outIntegerLst := match (inVarLst,inIntegerLst,vars,diffindex)
    local
       list<BackendDAE.Var> rest;
       list<Integer> irest;
       Integer i;
    case ({},{},_,_) then vars;
    case (BackendDAE.VAR(varKind = BackendDAE.DAE_AUX_VAR())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.DAE_RESIDUAL_VAR())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.JAC_DIFF_VAR())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())::rest,i::irest,_,_)
      guard not (diffindex==0 or AvlSetInt.hasKey(vars, i))
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.CLOCKED_STATE())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.ALG_STATE())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.OPT_CONSTR())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (BackendDAE.VAR(varKind = BackendDAE.OPT_FCONSTR())::rest,i::irest,_,_)
      guard not AvlSetInt.hasKey(vars, i)
      then incidenceRowExp1(rest,irest,AvlSetInt.add(vars, i),diffindex);
    case (_ :: _,_::_,_,_)
      then vars;
  end match;
end incidenceRowExp1withInput;

public function updateIncidenceMatrix
"author: PA
  Takes a daelow and the incidence matrix and its transposed
  represenation and a list of  equation indexes that needs to be updated.
  First the BackendDAE.IncidenceMatrix is updated, i.e. the mapping from equations
  to variables. Then, by collecting all variables in the list of equations
  to update, a list of changed variables are retrieved. This is used to
  update the BackendDAE.IncidenceMatrixT (transpose) mapping from variables to
  equations. The function returns an updated incidence matrix.
  inputs:  (BackendDAE,
            IncidenceMatrix,
            IncidenceMatrixT,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.EqSystem syst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> functionTree;
  input list<Integer> inIntegerLst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := matchcontinue syst
    local
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray daeeqns;

    case BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=daeeqns, m=SOME(m), mT=SOME(mt))
      equation
        (m,mt) = updateIncidenceMatrix1(vars, daeeqns, inIndxType, functionTree, m, mt, inIntegerLst);
      then BackendDAEUtil.setEqSystMatrices(syst, SOME(m), SOME(mt));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"BackendDAEUtil.updateIncididenceMatrix failed"});
      then fail();

  end matchcontinue;
end updateIncidenceMatrix;

protected function updateIncidenceMatrix1
  "Helper"
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray daeeqns;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> functionTree;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input list<Integer> inIntegerLst;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT):=
  match (vars,daeeqns,inIndxType,functionTree,m,mt,inIntegerLst)
    local
      BackendDAE.IncidenceMatrix m_1,m_2;
      BackendDAE.IncidenceMatrixT mt_1,mt_2,mt_3;
      Integer e,abse;
      BackendDAE.Equation eqn;
      AvlSetInt.Tree row,invars,outvars;
      list<Integer> eqns,oldvars;

    case (_,_,_,_,_,_,{}) then (m,mt);

    case (_,_,_,_,_,_,(e::eqns))
      equation
        abse = intAbs(e);
        eqn = BackendEquation.get(daeeqns, abse);
        (row,_) = incidenceRow(eqn,vars,inIndxType,functionTree,AvlSetInt.EMPTY());
        oldvars = getOldVars(m,abse);
        m_1 = Array.replaceAtWithFill(abse,AvlSetInt.listKeys(row),{},m);
        (_,outvars,invars) = AvlSetInt.intersection(AvlSetInt.addList(AvlSetInt.EMPTY(), oldvars),row);
        mt_1 = removeValuefromMatrix(abse,AvlSetInt.listKeys(outvars),mt);
        mt_2 = addValuetoMatrix(abse,AvlSetInt.listKeys(invars),mt_1);
        (m_2,mt_3) = updateIncidenceMatrix1(vars,daeeqns,inIndxType,functionTree,m_1,mt_2,eqns);
      then (m_2,mt_3);

  end match;
end updateIncidenceMatrix1;

public function updateIncidenceMatrixScalar
"author: PA
  Takes a daelow and the incidence matrix and its transposed
  represenation and a list of  equation indexes that needs to be updated.
  First the BackendDAE.IncidenceMatrix is updated, i.e. the mapping from equations
  to variables. Then, by collecting all variables in the list of equations
  to update, a list of changed variables are retrieved. This is used to
  update the BackendDAE.IncidenceMatrixT (transpose) mapping from variables to
  equations. The function returns an updated incidence matrix.
  inputs:  (BackendDAE,
            IncidenceMatrix,
            IncidenceMatrixT,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.EqSystem syst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> functionTree;
  input list<Integer> inIntegerLst "numbers of equations in BackendDAE.EquationArray";
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  output BackendDAE.EqSystem osyst;
  output array<list<Integer>> oMapEqnIncRow;
  output array<Integer> oMapIncRowEqn;
algorithm
  (osyst, oMapEqnIncRow, oMapIncRowEqn) := matchcontinue syst
    local
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      Integer oldsize, newsize, oldsize1, newsize1, deltasize;
      list<Integer> eqns;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray daeeqns;
      BackendDAE.Matching matching;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;

    case BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=daeeqns, m=SOME(m), mT=SOME(mt))
      equation
        // extend the mapping arrays
        oldsize = arrayLength(iMapEqnIncRow);
        newsize = BackendEquation.getNumberOfEquations(daeeqns);
        mapEqnIncRow = Array.expand(newsize-oldsize, iMapEqnIncRow, {});
        oldsize1 = arrayLength(iMapIncRowEqn);
        newsize1 = BackendEquation.equationArraySize(daeeqns);
        deltasize = newsize1-oldsize1;
        mapIncRowEqn = Array.expand(deltasize, iMapIncRowEqn, 0);
        // extend the incidenceMatrix
        m = Array.expand(deltasize, m, {});
        mt = Array.expand(deltasize, mt, {});
        // fill the extended parts first
        (m, mt, mapEqnIncRow, mapIncRowEqn) =
            updateIncidenceMatrixScalar2( oldsize+1, newsize, oldsize1, vars, daeeqns, m, mt, mapEqnIncRow,
                                          mapIncRowEqn, inIndxType, functionTree );
        // update the old
        eqns = List.removeOnTrue(oldsize, intLt, inIntegerLst);
        (m,mt,mapEqnIncRow,mapIncRowEqn) =
            updateIncidenceMatrixScalar1( vars, daeeqns, m, mt, eqns, mapEqnIncRow,
                                          mapIncRowEqn, inIndxType, functionTree );
      then
        (BackendDAEUtil.setEqSystMatrices(syst, SOME(m), SOME(mt)), mapEqnIncRow, mapIncRowEqn);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"BackendDAEUtil.updateIncidenceMatrixScalar failed"});
      then
        fail();

  end matchcontinue;
end updateIncidenceMatrixScalar;

protected function updateIncidenceMatrixScalar1
  "Helper"
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray daeeqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input list<Integer> inIntegerLst;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output array<list<Integer>> oMapEqnIncRow;
  output array<Integer> oMapIncRowEqn;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT,oMapEqnIncRow,oMapIncRowEqn):=
  match (vars,daeeqns,m,mt,inIntegerLst,iMapEqnIncRow,iMapIncRowEqn,inIndxType,functionTree)
    local
      BackendDAE.IncidenceMatrix m_1,m_2;
      BackendDAE.IncidenceMatrixT mt_1,mt_2,mt_3;
      Integer e,abse,size;
      BackendDAE.Equation eqn;
      AvlSetInt.Tree row,invarsTree,outvarsTree;
      list<Integer> invars,outvars,eqns,oldvars,scalarindxs;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;

    case (_,_,_,_,{},_,_,_,_) then (m,mt,iMapEqnIncRow,iMapIncRowEqn);

    case (_,_,_,_,e::eqns,_,_,_,_)
      equation
        abse = intAbs(e);
        eqn = BackendEquation.get(daeeqns, abse);
        (row,_) = incidenceRow(eqn,vars,inIndxType,functionTree,AvlSetInt.Tree.EMPTY());
        scalarindxs = iMapEqnIncRow[abse];
        oldvars = getOldVars(m,listHead(scalarindxs));
        (_,outvarsTree,invarsTree) = AvlSetInt.intersection(AvlSetInt.addList(AvlSetInt.Tree.EMPTY(), oldvars),row);
        outvars = AvlSetInt.listKeys(outvarsTree);
        invars = AvlSetInt.listKeys(invarsTree);
        // do the same for each scalar indxs
        m_1 = List.fold1r(scalarindxs,arrayUpdate,AvlSetInt.listKeys(row),m);
        mt_1 = List.fold1(scalarindxs,removeValuefromMatrix,outvars,mt);
        mt_2 = List.fold1(scalarindxs,addValuetoMatrix,invars,mt_1);
        (m_2,mt_3,mapEqnIncRow,mapIncRowEqn) = updateIncidenceMatrixScalar1(vars,daeeqns,m_1,mt_2,eqns,iMapEqnIncRow,iMapIncRowEqn,inIndxType,functionTree);
      then (m_2,mt_3,mapEqnIncRow,mapIncRowEqn);

  end match;
end updateIncidenceMatrixScalar1;

protected function updateIncidenceMatrixScalar2
  "Helper"
  input Integer index;
  input Integer n;
  input Integer size;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray daeeqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output array<list<Integer>> oMapEqnIncRow;
  output array<Integer> oMapIncRowEqn;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT,oMapEqnIncRow,oMapIncRowEqn):=
  matchcontinue (index,n,size,vars,daeeqns,m,mt,iMapEqnIncRow,iMapIncRowEqn,inIndxType,functionTree)
    local
      BackendDAE.IncidenceMatrix m1;
      BackendDAE.IncidenceMatrixT mt1;
      Integer abse,rowsize,new_size;
      BackendDAE.Equation eqn;
      AvlSetInt.Tree row;
      list<Integer> scalarindxs, row_lst;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;

    case (_,_,_,_,_,_,_,_,_,_,_)
      guard
        not intGt(index,n)
      equation
        abse = intAbs(index);
        eqn = BackendEquation.get(daeeqns, abse);
        rowsize = BackendEquation.equationSize(eqn);
        (row,_) = incidenceRow(eqn,vars,inIndxType,functionTree,AvlSetInt.EMPTY());
        new_size = size+rowsize;
        scalarindxs = List.intRange2(size+1,new_size);
        mapEqnIncRow = arrayUpdate(iMapEqnIncRow,abse,scalarindxs);
        mapIncRowEqn = List.fold1r(scalarindxs,arrayUpdate,abse,iMapIncRowEqn);
        row_lst = AvlSetInt.listKeys(row);
        m1= List.fold1r(scalarindxs,arrayUpdate,row_lst,m);
        mt1 = fillincidenceMatrixT(row_lst,scalarindxs,mt);
        (m1,mt1,mapEqnIncRow,mapIncRowEqn) = updateIncidenceMatrixScalar2(index+1,n,new_size,vars,daeeqns,m1,mt1,mapEqnIncRow,mapIncRowEqn,inIndxType,functionTree);
      then
        (m1,mt1,mapEqnIncRow,mapIncRowEqn);
    case (_,_,_,_,_,_,_,_,_,_,_)
      then
        (m,mt,iMapEqnIncRow,iMapIncRowEqn);
  end matchcontinue;
end updateIncidenceMatrixScalar2;

protected function getOldVars
  input array<list<Integer>> m;
  input Integer pos;
  output  list<Integer> oldvars;
algorithm
  oldvars := if pos <= arrayLength(m) then m[pos] else {};
end getOldVars;

protected function removeValuefromMatrix
"author: Frenkel TUD 2011-04"
  input Integer inValue;
  input list<Integer> inIntegerLst;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  outIncidenceMatrixT:=
  matchcontinue (inValue,inIntegerLst,inIncidenceMatrixT)
    local
      BackendDAE.IncidenceMatrixT mt,mt_1,mt_2;
      BackendDAE.IncidenceMatrixElement mlst,mlst1;
      list<Integer> keys;
      Integer k,kabs;
      Integer v,v_1;
    case (_,{},mt) then mt;
    case (v,k::keys,mt)
      equation
        kabs = intAbs(k);
        mlst = mt[kabs];
        v_1 = if intGt(k,0) then v else -v;
        mlst1 = List.removeOnTrue(v_1,intEq,mlst);
        mt_1 = arrayUpdate(mt, kabs , mlst1);
        mt_2 = removeValuefromMatrix(v,keys,mt_1);
      then
        mt_2;
    case (v,_::keys,mt)
      equation
        mt_2 = removeValuefromMatrix(v,keys,mt);
      then
        mt_2;
    case (_,_,_)
      equation
        print("- BackendDAE.removeValuefromMatrix failed\n");
      then
        fail();
  end matchcontinue;
end removeValuefromMatrix;

protected function addValuetoMatrix
"author: Frenkel TUD 2011-04"
  input Integer inValue;
  input list<Integer> inIntegerLst;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  outIncidenceMatrixT:=
  matchcontinue (inValue,inIntegerLst,inIncidenceMatrixT)
    local
      BackendDAE.IncidenceMatrixT mt,mt_1,mt_2;
      BackendDAE.IncidenceMatrixElement mlst;
      list<Integer> keys;
      Integer k,kabs;
      Integer v,v_1;
    case (_,{},mt) then mt;
    case (v,k::keys,mt)
      equation
        kabs = intAbs(k);
        mlst = getOldVars(mt,kabs);
        v_1 = if intGt(k,0) then v else -v;
        false = listMember(v_1, mlst);
        mt_1 = Array.replaceAtWithFill(kabs,v_1::mlst,{},mt);
        mt_2 = addValuetoMatrix(v,keys,mt_1);
      then
        mt_2;
    case (v,_::keys,mt)
      equation
        mt_2 = addValuetoMatrix(v,keys,mt);
      then
        mt_2;
    case (_,_,_)
      equation
        print("- BackendDAE.addValuetoMatrix failed\n");
      then
        fail();
  end matchcontinue;
end addValuetoMatrix;

public function getIncidenceMatrixfromOptionForMapEqSystem "function getIncidenceMatrixfromOption"
  input BackendDAE.EqSystem syst;
  input BackendDAE.IndexType inIndxType;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
protected
  DAE.FunctionTree funcs;
algorithm
  funcs := getFunctions(shared);
  (osyst,_,_) := getIncidenceMatrixfromOption(syst,inIndxType,SOME(funcs));
  oshared := shared;
end getIncidenceMatrixfromOptionForMapEqSystem;

public function getIncidenceMatrixfromOption
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> inFunctionTree;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
algorithm
  (outSyst, outM, outMT) := match inSyst
    local
      BackendDAE.IncidenceMatrix m, mT;
      BackendDAE.Variables v;
      BackendDAE.EquationArray eq;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case BackendDAE.EQSYSTEM(m=NONE()) equation
      (m, mT) = incidenceMatrix(inSyst, inIndxType, inFunctionTree);
    then (BackendDAEUtil.setEqSystMatrices(inSyst, SOME(m), SOME(mT)), m, mT);

    case BackendDAE.EQSYSTEM(orderedVars=v, m=SOME(m), mT=NONE()) equation
      mT = AdjacencyMatrix.transposeAdjacencyMatrix(m, BackendVariable.varsSize(v));
    then (BackendDAEUtil.setEqSystMatrices(inSyst, SOME(m), SOME(mT)), m, mT);

    case BackendDAE.EQSYSTEM(m=SOME(m), mT=SOME(mT))
    then (inSyst, m, mT);
  end match;
end getIncidenceMatrixfromOption;

public function getIncidenceMatrix "this function returns the incidence matrix,
  if the system contains multidimensional equations and the scalar one is needed use getIncidenceMatrixScalar"
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.EqSystem outEqSystem;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
algorithm
  (outM, outMT) := incidenceMatrix(inEqSystem, inIndxType, functionTree);
  outEqSystem := BackendDAEUtil.setEqSystMatrices(inEqSystem, SOME(outM), SOME(outMT));
end getIncidenceMatrix;

public function getIncidenceMatrixScalar "function getIncidenceMatrixScalar"
  input BackendDAE.EqSystem syst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> functionTree;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
  output array<list<Integer>> outMapEqnIncRow;
  output array<Integer> outMapIncRowEqn;
algorithm
  (outM, outMT, outMapEqnIncRow, outMapIncRowEqn) := incidenceMatrixScalar(syst, inIndxType, functionTree);
  osyst := BackendDAEUtil.setEqSystMatrices(syst, SOME(outM), SOME(outMT));
end getIncidenceMatrixScalar;

public function removedIncidenceMatrix
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> inFunctionTree;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
algorithm
  (outM, outMT) := incidenceMatrixDispatch(inSyst.orderedVars, inSyst.removedEqs, inIndxType, inFunctionTree);
end removedIncidenceMatrix;

public function removedIncidenceMatrixMasked
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.IndexType inIndxType;
  input array<Boolean> inMask;
  input Option<DAE.FunctionTree> inFunctionTree;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
algorithm
  (outM, outMT) := incidenceMatrixDispatchMasked(inSyst.orderedVars, inSyst.removedEqs, inIndxType, inMask, inFunctionTree);
end removedIncidenceMatrixMasked;

protected function traverseStmts "Author: Frenkel TUD 2012-06
  traverese DAE.Statement without change possibility."
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a iextraArg;
  output Type_a oextraArg;
  partial function FuncExpType
     input DAE.Exp arg1;
     input output Type_a arg2;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  oextraArg := matchcontinue(inStmts,func,iextraArg)
    local
      DAE.Exp e,e2;
      list<DAE.Exp> expl1;
      DAE.ComponentRef cr;
      list<DAE.Statement> xs,stmts;
      DAE.Type tp;
      DAE.Statement x,ew;
      Boolean b1;
      String id1,str;
      DAE.Else algElse;
      Type_a extraArg;

    case ({},_,extraArg) then extraArg;

    case ((DAE.STMT_ASSIGN(exp1 = e2,exp = e)::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
        extraArg = func(e2, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case ((DAE.STMT_TUPLE_ASSIGN(expExpLst = expl1, exp = e)::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
        extraArg = List.fold(expl1,func,extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case ((DAE.STMT_ASSIGN_ARR(lhs = e2, exp = e)::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
        extraArg = func(e2, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse))::xs),_,extraArg)
      equation
        extraArg = traverseStmtsElse(algElse,func,extraArg);
        extraArg = traverseStmts(stmts,func,extraArg);
        extraArg = func(e, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_FOR(type_=tp,iter=id1,range=e,statementLst=stmts))::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
        cr = ComponentReference.makeCrefIdent(id1, tp, {});
        (stmts,_) = DAEUtil.traverseDAEEquationsStmts(stmts,Expression.traverseSubexpressionsHelper,(Expression.replaceCref,(cr,e)));
        extraArg = traverseStmts(stmts,func,extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_PARFOR(type_=tp,iter=id1,range=e,statementLst=stmts))::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
        cr = ComponentReference.makeCrefIdent(id1, tp, {});
        (stmts,_) = DAEUtil.traverseDAEEquationsStmts(stmts,Expression.traverseSubexpressionsHelper,(Expression.replaceCref,(cr,e)));
        extraArg = traverseStmts(stmts,func,extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_WHILE(exp=e,statementLst=stmts))::xs),_,extraArg)
      equation
        extraArg = traverseStmts(stmts,func,extraArg);
        extraArg = func(e, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_WHEN(exp=e,statementLst=stmts,elseWhen=NONE()))::xs),_,extraArg)
      equation
        extraArg = traverseStmts(stmts,func,extraArg);
        extraArg = func(e, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_WHEN(exp=e,statementLst=stmts,elseWhen=SOME(ew)))::xs),_,extraArg)
      equation
        extraArg = traverseStmts({ew},func,extraArg);
        extraArg = traverseStmts(stmts,func,extraArg);
        extraArg = func(e, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_ASSERT(cond = e, msg=e2))::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
        extraArg = func(e2, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_TERMINATE(msg = e))::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_REINIT(var = e,value=e2))::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
        extraArg = func(e2, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_NORETCALL(exp = e))::xs),_,extraArg)
      equation
        extraArg = func(e, extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_RETURN())::xs),_,extraArg)
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_BREAK())::xs),_,extraArg)
      then
        traverseStmts(xs, func, extraArg);

    case (((DAE.STMT_CONTINUE())::xs),_,extraArg)
      then
        traverseStmts(xs, func, extraArg);

    // MetaModelica extension. KS
    case (((DAE.STMT_FAILURE(body=stmts))::xs),_,extraArg)
      equation
        extraArg = traverseStmts(stmts,func,extraArg);
      then
        traverseStmts(xs, func, extraArg);

    case ((x::_),_,_)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "BackenddAEUtil.traverseStmts not implemented correctly: " + str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end traverseStmts;

protected function traverseStmtsElse "
Author: Frenkel TUD 2012-06
Helper function for traverseStmts
"
  input DAE.Else inElse;
  input FuncExpType func;
  input Type_a iextraArg;
  output Type_a oextraArg;
  partial function FuncExpType
    input DAE.Exp arg1;
    input output Type_a arg2;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  oextraArg := match(inElse,func,iextraArg)
    local
      DAE.Exp e;
      list<DAE.Statement> st;
      DAE.Else el;
      Type_a extraArg;
    case (DAE.NOELSE(),_,extraArg) then extraArg;
    case (DAE.ELSEIF(e,st,el),_,extraArg)
      equation
        extraArg = traverseStmtsElse(el,func,extraArg);
        extraArg = func(e, extraArg);
      then
        traverseStmts(st,func,extraArg);
    case(DAE.ELSE(st),_,extraArg)
      then
        traverseStmts(st,func,extraArg);
  end match;
end traverseStmtsElse;

public function incidenceMatrixToSparsePattern
" Applies absolute value to all entries in the incidence matrix and
  also sort and unique them."
  input BackendDAE.IncidenceMatrix m;
  output BackendDAE.IncidenceMatrix res;
protected
  list<list<Integer>> lst,lst_1;
algorithm
  lst := arrayList(m);
  lst_1 := List.mapList(lst, intAbs);
  lst_1 := List.map1(lst_1, List.sort, intGt);
  lst_1 := List.map1(lst_1, List.sortedUnique, intGe);
  res := listArray(lst_1);
end incidenceMatrixToSparsePattern;

/******************************************************************
 stuff to calculate enhanced Adjacency matrix

 The Adjacency matrix describes the relation between knots and
 knots of a bigraph. Additional information about the solvability
 of a variable are available.
******************************************************************/

public function getAdjacencyMatrixEnhancedScalar
"author: Frenkel TUD 2012-05
  Calculates the Adjacency matrix, i.e. which variables are present in each equation
  and add some information how the variable occur in the equation(see BackendDAE.BackendDAE.Solvability)."
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input Boolean trytosolve "determine the solvability by solving for the variable instead of deriving, needed for 'Casual Tearing Set'";
  output BackendDAE.AdjacencyMatrixEnhanced outIncidenceMatrix;
  output BackendDAE.AdjacencyMatrixTEnhanced outIncidenceMatrixT;
  output array<list<Integer>> outMapEqnIncRow;
  output array<Integer> outMapIncRowEqn;
protected
  list<tuple<Integer,list<Integer>>> varsSolvedInWhenEqnsTupleList;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT,outMapEqnIncRow,outMapIncRowEqn) :=
  matchcontinue (syst, shared)
    local
      BackendDAE.AdjacencyMatrixEnhanced arr;
      BackendDAE.AdjacencyMatrixTEnhanced arrT;
      BackendDAE.Variables vars,globalKnownVars;
      BackendDAE.EquationArray eqns;
      Integer numberOfEqs,numberofVars;
      array<Integer> rowmark "array to mark if a variable is allready found in the equation, and to mark if it is unsolvable(marked negative) in the equation";
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;

    case (BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns), BackendDAE.SHARED(globalKnownVars=globalKnownVars))
      equation
        // get the size
        numberOfEqs = BackendEquation.getNumberOfEquations(eqns);
        numberofVars = BackendVariable.varsSize(vars);
        // create the array to hold the Adjacency matrix
         arrT = arrayCreate(numberofVars, {});
        // create the array to mark if a variable is allready found in the equation
        rowmark = arrayCreate(numberofVars, 0);
        (arr,arrT,mapEqnIncRow,mapIncRowEqn,varsSolvedInWhenEqnsTupleList) = adjacencyMatrixDispatchEnhancedScalar(vars, eqns,arrT, numberOfEqs, rowmark,globalKnownVars ,trytosolve);
      then
        (arr,arrT,mapEqnIncRow,mapIncRowEqn);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"BackendDAEUtil.getAdjacencyMatrixEnhancedScalar failed"});
      then
        fail();
  end matchcontinue;

  makeWhenEqnVarsUnsolvable(outIncidenceMatrix,outIncidenceMatrixT,varsSolvedInWhenEqnsTupleList);
end getAdjacencyMatrixEnhancedScalar;


function makeWhenEqnVarsUnsolvable
 "Function to make variables solved in when-equations unsolvable in all other equations.
  author: ptaeuber FHB"
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input list<tuple<Integer,list<Integer>>> varsSolvedInWhenEqnsTupleList;
protected
  Integer eqn;
  list<Integer> vars,eqns;
  BackendDAE.AdjacencyMatrixElementEnhanced adjacencyRow;
  BackendDAE.AdjacencyMatrixElementEnhanced adjacencyRowT;
algorithm
  for tpl in varsSolvedInWhenEqnsTupleList loop
    (eqn,vars) := tpl;
    for var in vars loop

      // update m
      adjacencyRowT := mt[var];
      eqns := list(
        match(adjacencyElemT)
          local
            Integer i;
          case(i,_,_) then i;
        end match for adjacencyElemT in adjacencyRowT);
      eqns := List.deleteMember(eqns,eqn);
      for e in eqns loop
        adjacencyRow := m[e];
        adjacencyRow := list(
        match(adjacencyElem)
          local
            Integer i;
            BackendDAE.Constraints c;
          case((i,_,c)) guard intEq(i,var) then (i,BackendDAE.SOLVABILITY_UNSOLVABLE(),c);
          case((_,_,_)) then (adjacencyElem);
        end match for adjacencyElem in adjacencyRow);
        arrayUpdate(m,e,adjacencyRow);
      end for;

      // update mt
      adjacencyRowT := mt[var];
      adjacencyRowT := list(
        match(adjacencyElemT)
          local
            Integer i;
            BackendDAE.Constraints c;
          case((i,_,c)) guard not intEq(i,eqn) then (i,BackendDAE.SOLVABILITY_UNSOLVABLE(),c);
          case((_,_,_)) then (adjacencyElemT);
        end match for adjacencyElemT in adjacencyRowT);
    arrayUpdate(mt,var,adjacencyRowT);
    end for;
  end for;
end makeWhenEqnVarsUnsolvable;


protected function adjacencyMatrixDispatchEnhancedScalar
"@author: Frenkel TUD 2012-05
  Calculates the adjacency matrix and the transposed
  adjacency matrix."
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqArr;
  output BackendDAE.AdjacencyMatrixEnhanced outIncidenceArray;
  input output BackendDAE.AdjacencyMatrixTEnhanced incidenceArrayT;
  input Integer numberOfEqs;
  input array<Integer> rowmark;
  input BackendDAE.Variables globalKnownVars;
  input Boolean trytosolve;
  output array<list<Integer>> omapEqnIncRow;
  output array<Integer> omapIncRowEqn;
  output list<tuple<Integer,list<Integer>>> varsSolvedInWhenEqnsTupleListOut = {};
protected
  list<BackendDAE.AdjacencyMatrixElementEnhanced> inIncidenceArray = {};
  list<list<Integer>> mapEqnIncRow = {};
  list<Integer> imapIncRowEqn = {};
  BackendDAE.Equation e;
  BackendDAE.AdjacencyMatrixElementEnhanced row;
  Integer size, rowSize = 0;
  list<tuple<Integer,list<Integer>>> varsSolvedInWhenEqnsTuple;
  list<Integer> rowindxs;
algorithm
  for i1 in 1:numberOfEqs loop
    // get the equation
    e := BackendEquation.get(eqArr, i1);
    // compute the row
    (row,size,varsSolvedInWhenEqnsTuple) := adjacencyRowEnhanced(vars, e, i1, rowmark, globalKnownVars, trytosolve);
    rowindxs := List.intRange2(rowSize+1, rowSize+size);
    rowSize := rowSize + size;
    imapIncRowEqn := List.consN(size,i1,imapIncRowEqn);
    // put it in the arrays
    inIncidenceArray := List.consN(size,row,inIncidenceArray);
    incidenceArrayT := fillincAdjacencyMatrixTEnhanced(row,rowindxs,incidenceArrayT);
    varsSolvedInWhenEqnsTupleListOut := listAppend(varsSolvedInWhenEqnsTuple, varsSolvedInWhenEqnsTupleListOut);
    mapEqnIncRow := rowindxs::mapEqnIncRow;
  end for;
  outIncidenceArray := List.listArrayReverse(inIncidenceArray);
  omapEqnIncRow := List.listArrayReverse(mapEqnIncRow);
  omapIncRowEqn := List.listArrayReverse(imapIncRowEqn);
end adjacencyMatrixDispatchEnhancedScalar;


public function getAdjacencyMatrixEnhanced
"author: Frenkel TUD 2012-05
  Calculates the Adjacency matrix, i.e. which variables are present in each equation
  and add some information how the variable occure in the equation(see BackendDAE.BackendDAE.Solvability)."
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input Boolean trytosolve;
  output BackendDAE.AdjacencyMatrixEnhanced outIncidenceMatrix;
  output BackendDAE.AdjacencyMatrixTEnhanced outIncidenceMatrixT;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT) := matchcontinue (syst, shared)
    local
      BackendDAE.AdjacencyMatrixEnhanced arr;
      BackendDAE.AdjacencyMatrixTEnhanced arrT;
      BackendDAE.Variables vars,globalKnownVars;
      BackendDAE.EquationArray eqns;
      Integer numberOfEqs,numberofVars;
      array<Integer> rowmark "array to mark if a variable is allready found in the equation, and to mark if it is unsolvable(marked negative) in the equation";

    case (BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns), BackendDAE.SHARED(globalKnownVars=globalKnownVars))
      equation
        // get the size
        numberOfEqs = BackendEquation.getNumberOfEquations(eqns);
        numberofVars = BackendVariable.varsSize(vars);
        // create the array to hold the Adjacency matrix
        arr = arrayCreate(BackendEquation.equationArraySize(eqns), {});
        arrT = arrayCreate(numberofVars, {});
        // create the array to mark if a variable is allready found in the equation
        rowmark = arrayCreate(numberofVars, 0);
        (arr,arrT) = adjacencyMatrixDispatchEnhanced(vars, eqns, arr,arrT, 0, numberOfEqs, intLt(0, numberOfEqs),rowmark,globalKnownVars,trytosolve);
      then
        (arr,arrT);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"BackendDAEUtil.getAdjacencyMatrixEnhanced failed"});
      then
        fail();
  end matchcontinue;
end getAdjacencyMatrixEnhanced;

protected function adjacencyMatrixDispatchEnhanced
"@author: Frenkel TUD 2012-05
  Calculates the adjacency matrix and the transposed
  adjacency matrix."
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqArr;
  input BackendDAE.AdjacencyMatrixEnhanced inIncidenceArray;
  input BackendDAE.AdjacencyMatrixTEnhanced inIncidenceArrayT;
  input Integer index;
  input Integer numberOfEqs;
  input Boolean stop;
  input array<Integer> rowmark;
  input BackendDAE.Variables globalKnownVars;
  input Boolean trytosolve;
  output BackendDAE.AdjacencyMatrixEnhanced outIncidenceArray;
  output BackendDAE.AdjacencyMatrixTEnhanced outIncidenceArrayT;
algorithm
  (outIncidenceArray,outIncidenceArrayT) :=
    match (vars, eqArr, inIncidenceArray, inIncidenceArrayT, index, numberOfEqs, stop, rowmark, globalKnownVars)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced row;
      BackendDAE.Equation e;
      BackendDAE.AdjacencyMatrixEnhanced iArr;
      BackendDAE.AdjacencyMatrixTEnhanced iArrT;
      Integer i1;

    // index = numberOfEqs (we reach the end)
    case (_, _, _, _, _, _,  false, _, _)
    then (inIncidenceArray, inIncidenceArrayT);

    // index < numberOfEqs
    case (_, _, _, _, _, _, true, _, _)
      equation
        i1 = index+1;

        // get the equation
        e = BackendEquation.get(eqArr, i1);
        // compute the row
        (row,_,_) = adjacencyRowEnhanced(vars, e, i1, rowmark, globalKnownVars, trytosolve);
        // put it in the arrays
        iArr = arrayUpdate(inIncidenceArray, i1, row);
        iArrT = fillincAdjacencyMatrixTEnhanced(row,{i1},inIncidenceArrayT);
        (iArr,iArrT) = adjacencyMatrixDispatchEnhanced(vars, eqArr, iArr, iArrT, i1, numberOfEqs, intLt(i1, numberOfEqs), rowmark, globalKnownVars, trytosolve);
      then
        (iArr,iArrT);
  end match;
end adjacencyMatrixDispatchEnhanced;

protected function fillincAdjacencyMatrixTEnhanced
"@author: Frenkel TUD 2011-04
  helper for adjacencyMatrixDispatchEnhanced.
  Inserts the rows in the transposed adjacency matrix."
  input BackendDAE.AdjacencyMatrixElementEnhanced eqns;
  input list<Integer> eqnsindxs;
  input BackendDAE.AdjacencyMatrixTEnhanced inIncidenceArrayT;
  output BackendDAE.AdjacencyMatrixTEnhanced outIncidenceArrayT;
algorithm
  outIncidenceArrayT := matchcontinue (eqns, eqnsindxs, inIncidenceArrayT)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced row,rest,newrow;
      Integer v,vabs;
      BackendDAE.AdjacencyMatrixTEnhanced mT;
      BackendDAE.Solvability solva;
      BackendDAE.Constraints cons;
      list<Integer> eqnsindxs1;

    case ({},_,_) then inIncidenceArrayT;

    case ((v,solva,cons)::rest,_,_)
      guard
        intLt(0, v)
      equation
        row = inIncidenceArrayT[v];
        newrow = List.map2(eqnsindxs,Util.make3Tuple,solva,cons);
        row = listAppend(newrow,row);
        // put it in the array
        mT = arrayUpdate(inIncidenceArrayT, v, row);
      then
        fillincAdjacencyMatrixTEnhanced(rest, eqnsindxs, mT);

    case ((v,solva,cons)::rest,_,_)
      equation
        vabs = intAbs(v);
        row = inIncidenceArrayT[vabs];
        eqnsindxs1 = List.map(eqnsindxs,intNeg);
        newrow = List.map2(eqnsindxs1,Util.make3Tuple,solva,cons);
        // put it in the array
        row = listAppend(newrow,row);
        mT = arrayUpdate(inIncidenceArrayT, vabs, row);
      then
        fillincAdjacencyMatrixTEnhanced(rest, eqnsindxs, mT);

    case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"BackendDAEUtil.fillincAdjacencyMatrixTEnhanced failed"});
      then
        fail();
  end matchcontinue;
end fillincAdjacencyMatrixTEnhanced;

protected function adjacencyRowEnhanced
"author: Frenkel TUD 2012-05
  Helper function to adjacencyMatrixDispatchEnhanced. Calculates the adjacency row
  in the matrix for one equation."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Equation inEquation;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.Variables globalKnownVars;
  input Boolean trytosolve;
  output BackendDAE.AdjacencyMatrixElementEnhanced outRow;
  output Integer size;
  output list<tuple<Integer,list<Integer>>> varsSolvedInWhenEqnsTuple={};
algorithm
  (outRow,size) := matchcontinue (inVariables,inEquation,mark,rowmark,globalKnownVars)
    local
      list<Integer> lst,ds, lstall, varsSolvedInWhenEqns;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e,expCref,cond;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we,elsewe;
      String eqnstr;
      DAE.Algorithm alg;
      BackendDAE.AdjacencyMatrixElementEnhanced row, row1;
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns,eqnselse;
      list<DAE.ComponentRef> algoutCrefs;
      DAE.Expand crefExpand;
      DAE.ElementSource source;

    // EQUATION
    case (vars,BackendDAE.EQUATION(exp = e1,scalar = e2),_,_,_)
      equation
        lst = adjacencyRowExpEnhanced(e1, vars, mark, rowmark, {});
        lst = adjacencyRowExpEnhanced(e2, vars, mark, rowmark, lst);
        row = adjacencyRowEnhanced1(lst,e1,e2,vars,globalKnownVars,mark,rowmark,{},trytosolve);
      then
        (row,1);
    // COMPLEX_EQUATION
    case (vars,BackendDAE.COMPLEX_EQUATION(size=size,left=e1,right=e2),_,_,_)
      equation
        lst = adjacencyRowExpEnhanced(e1, vars, mark, rowmark, {});
        lst = adjacencyRowExpEnhanced(e2, vars, mark, rowmark, lst);
        row = adjacencyRowEnhanced1(lst,e1,e2,vars,globalKnownVars,mark,rowmark,{},trytosolve);
      then
        (row,size);
    // ARRAY_EQUATION
    case (vars,BackendDAE.ARRAY_EQUATION(dimSize=ds,left=e1,right=e2),_,_,_)
      equation
        lst = adjacencyRowExpEnhanced(e1, vars, mark, rowmark, {});
        lst = adjacencyRowExpEnhanced(e2, vars, mark, rowmark, lst);
        row = adjacencyRowEnhanced1(lst,e1,e2,vars,globalKnownVars,mark,rowmark,{},trytosolve);
        size = List.fold(ds,intMul,1);
      then
        (row,size);

    // SOLVED_EQUATION
    case (vars,BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e),_,_,_)
      equation
        expCref = Expression.crefExp(cr);
        lst = adjacencyRowExpEnhanced(expCref, vars, mark, rowmark, {});
        lst = adjacencyRowExpEnhanced(e, vars, mark, rowmark, lst);
        row = adjacencyRowEnhanced1(lst,expCref,e,vars,globalKnownVars,mark,rowmark,{},trytosolve);
      then
        (row,1);
    // RESIDUAL_EQUATION
    case (vars,BackendDAE.RESIDUAL_EQUATION(exp = e),_,_,_)
      equation
        lst = adjacencyRowExpEnhanced(e, vars, mark, rowmark, {});
        row = adjacencyRowEnhanced1(lst,e,DAE.RCONST(0.0),vars,globalKnownVars,mark,rowmark,{},trytosolve);
      then
        (row,1);

    // WHEN_EQUATION
    case (vars,BackendDAE.WHEN_EQUATION(size=size,whenEquation = elsewe),_,_,_)
      equation
        (row,varsSolvedInWhenEqns) = adjacencyRowWhenEnhanced(elsewe, mark, rowmark, vars, globalKnownVars, {}, {});
        varsSolvedInWhenEqnsTuple = {(mark,varsSolvedInWhenEqns)};
      then
        (row,size);

    // ALGORITHM For now assume that algorithm will be solvable for
    // output variables. Mark this as solved and input variables as unsolvable:
    case (vars,BackendDAE.ALGORITHM(size=size,alg=alg,source=source,expand=crefExpand),_,_,_)
      equation
        // get outputs
        algoutCrefs = CheckModel.checkAndGetAlgorithmOutputs(alg, source, crefExpand);
        // mark outputs as solved
        row = adjacencyRowAlgorithmOutputs(algoutCrefs,vars,mark,rowmark,{});
        // get inputs
        expl = Algorithm.getAllExps(alg);
        // mark inputs as unsolvable
        (_,(_,_,_,row)) = Expression.traverseExpList(expl, adjacencyRowAlgorithmInputs, (vars,mark,rowmark,row));
      then
        (row,size);

    // special case for it initial() then ... else ... end if; only else branch needs to be checked
    case(_,BackendDAE.IF_EQUATION(conditions={DAE.CALL(path=Absyn.IDENT("initial"))},eqnstrue={_},eqnsfalse=eqnselse),_,_,_)
      equation
        (row,size) = adjacencyRowEnhancedEqnLst(eqnselse,inVariables,mark,rowmark,globalKnownVars,trytosolve);
      then
        (row,size);

    // if Equation
    // TODO : how to handle this?
    // Proposal:
    // 1. mark all vars in conditions as unsolvable
    // 2. vars occur in all branches: check how they are occur
    // 3. vars occur not in all branches: mark as unsolvable
    case(vars, BackendDAE.IF_EQUATION(conditions=expl,eqnstrue=eqnslst,eqnsfalse=eqnselse),_,_,_)
      equation
        //print("Warning: BackendDAEUtil.adjacencyRowEnhanced does not handle if-equations propper!\n");
        // mark all negative because the when condition cannot used to solve a variable
        lst = List.fold3(expl, adjacencyRowExpEnhanced, vars, mark, rowmark, {});
        _ = List.fold1(lst,markNegativ,rowmark,mark);
        row1 = adjacencyRowEnhanced1(lst,DAE.RCONST(0.0),DAE.RCONST(0.0),vars,globalKnownVars,mark,rowmark,{},trytosolve);

        (row, size) = adjacencyRowEnhancedEqnLst(eqnselse, vars, mark, rowmark, globalKnownVars, trytosolve);
        lst = List.map(row,Util.tuple31);

        (lst, row, size) = List.fold5(eqnslst, adjacencyRowEnhancedEqnLstIfBranches, vars, mark, rowmark, globalKnownVars, trytosolve, (lst, row, size));

        lstall = List.map(row, Util.tuple31);
        (_, lst, _) = List.intersection1OnTrue(lstall, lst, intEq);
        _ = List.fold1(lst, markNegativ, rowmark, mark);
        row = listAppend(row1,row);
      then
        (row,size);

    else
      equation
        eqnstr = BackendDump.equationString(inEquation);
        eqnstr = stringAppendList({"BackendDAE.adjacencyRowEnhanced failed for eqn:\n",eqnstr,"\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{eqnstr});
      then
        fail();
  end matchcontinue;
end adjacencyRowEnhanced;

protected function adjacencyRowEnhancedEqnLstIfBranches
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Variables inVariables;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.Variables globalKnownVars;
  input Boolean trytosolve;
  input tuple<list<Integer>,BackendDAE.AdjacencyMatrixElementEnhanced,Integer> intpl;
  output tuple<list<Integer>,BackendDAE.AdjacencyMatrixElementEnhanced,Integer> outtpl;
protected
  BackendDAE.AdjacencyMatrixElementEnhanced row, iRow;
  list<Integer> lst, inLstAllBranch;
  Integer size, iSize;
algorithm
  (inLstAllBranch,iRow,iSize) := intpl;
  for eqn in iEqns loop
    (row,size,_) := adjacencyRowEnhanced(inVariables, eqn, mark, rowmark, globalKnownVars, trytosolve);
    lst := List.map(row,Util.tuple31);
    inLstAllBranch := List.intersectionOnTrue(lst, inLstAllBranch,intEq);
    iSize := iSize + size;
    iRow := listAppend(row,iRow);
  end for;
  outtpl := (inLstAllBranch,iRow,iSize);
end adjacencyRowEnhancedEqnLstIfBranches;

protected function adjacencyRowEnhancedEqnLst
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Variables inVariables;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.Variables globalKnownVars;
  input Boolean trytosolve;
  output BackendDAE.AdjacencyMatrixElementEnhanced outRow = {};
  output Integer oSize = 0;
protected
  BackendDAE.AdjacencyMatrixElementEnhanced row;
  Integer size;
algorithm
  for eqn in iEqns loop
    (row,size,_) := adjacencyRowEnhanced(inVariables,eqn,mark,rowmark,globalKnownVars,trytosolve);
    outRow := listAppend(row,outRow);
    oSize := oSize + size;
  end for;
end adjacencyRowEnhancedEqnLst;

protected function adjacencyRowAlgorithmOutputs
"author: Frenkel TUD 10-2012
  Helper function to adjacencyRowEnhanced. Mark all algorithm outputs
  as solved."
  input list<DAE.ComponentRef> algOutputs;
  input BackendDAE.Variables inVariables;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  output BackendDAE.AdjacencyMatrixElementEnhanced outRow;
algorithm
  outRow := match(algOutputs,inVariables,mark,rowmark,iRow)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest;
      list<Integer> vindx;
      BackendDAE.AdjacencyMatrixElementEnhanced row;
    case ({},_,_,_,_) then iRow;
    case (cr::rest,_,_,_,_)
      equation
        (_,vindx) = BackendVariable.getVar(cr,inVariables);
        row = adjacencyRowAlgorithmOutputs1(vindx,mark,rowmark,iRow);
      then
        adjacencyRowAlgorithmOutputs(rest,inVariables,mark,rowmark,row);
  end match;
end adjacencyRowAlgorithmOutputs;

protected function adjacencyRowAlgorithmOutputs1
"author: Frenkel TUD 10-2012
  Helper function to adjacencyRowEnhanced. Mark all algorithm outputs
  as solved."
  input list<Integer> vindx;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  output BackendDAE.AdjacencyMatrixElementEnhanced outRow;
algorithm
  outRow := match(vindx,mark,rowmark,iRow)
    local
      Integer i;
      list<Integer> rest;
    case ({},_,_,_) then iRow;
    case (i::rest,_,_,_)
      equation
        arrayUpdate(rowmark,i,mark);
      then
        adjacencyRowAlgorithmOutputs1(rest,mark,rowmark,(i,BackendDAE.SOLVABILITY_SOLVED(),{})::iRow);
  end match;
end adjacencyRowAlgorithmOutputs1;

protected function adjacencyRowAlgorithmInputs
"author: Frenkel TUD 10-2012
  Helper function to adjacencyRowEnhanced. Mark all algorithm inputs
  as unsolvable."
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Integer,array<Integer>,BackendDAE.AdjacencyMatrixElementEnhanced> iTpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,Integer,array<Integer>,BackendDAE.AdjacencyMatrixElementEnhanced> oTpl;
algorithm
  (outExp,oTpl) := matchcontinue (inExp,iTpl)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      Integer mark;
      array<Integer>rowmark;
      BackendDAE.AdjacencyMatrixElementEnhanced row;
      list<Integer> vindx;
    case (e as DAE.CREF(componentRef=cr),(vars,mark,rowmark,row))
      equation
        (_,vindx) = BackendVariable.getVar(cr,vars);
        row = adjacencyRowAlgorithmInputs1(vindx,mark,rowmark,row);
      then (e,(vars,mark,rowmark,row));
    else (inExp,iTpl);
  end matchcontinue;
end adjacencyRowAlgorithmInputs;

protected function adjacencyRowAlgorithmInputs1
"author: Frenkel TUD 10-2012
  Helper function to adjacencyRowEnhanced. Mark all algorithm inputs
  as unsolvable."
  input list<Integer> vindx;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  output BackendDAE.AdjacencyMatrixElementEnhanced outRow;
algorithm
  outRow := match(vindx,mark,rowmark,iRow)
    local
      Integer i;
      list<Integer> rest;
    case ({},_,_,_) then iRow;
    case (i::rest,_,_,_)
      guard
        // not already handled
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,-mark);
      then
        adjacencyRowAlgorithmInputs1(rest,mark,rowmark,(i,BackendDAE.SOLVABILITY_UNSOLVABLE(),{})::iRow);
    case (_::rest,_,_,_)
      then
        adjacencyRowAlgorithmInputs1(rest,mark,rowmark,iRow);
  end match;
end adjacencyRowAlgorithmInputs1;

protected function adjacencyRowWhenEnhanced
"author: Frenkel TUD
  Helper function to adjacencyMatrixDispatchEnhanced. Calculates the adjacency row
  in the matrix for one equation."
  input BackendDAE.WhenEquation inEquation;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables globalKnownVars;
  input list<Integer> iLst;
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  output BackendDAE.AdjacencyMatrixElementEnhanced outRow = iRow;
  output list<Integer> varsSolvedInWhenEqns={};
protected
  DAE.Exp condition;
  list<BackendDAE.WhenOperator> whenStmtLst;
  Option<BackendDAE.WhenEquation> oelsepart;
  list<Integer> lst;
  BackendDAE.WhenEquation elsepart;
algorithm
  BackendDAE.WHEN_STMTS(condition = condition, whenStmtLst = whenStmtLst, elsewhenPart = oelsepart) := inEquation;
  lst := adjacencyRowExpEnhanced(condition, vars, mark, rowmark, iLst);
  for rs in whenStmtLst loop
    _ := match(rs)
      local
        Integer varIndx;
        list<Integer> varIdcs;
        DAE.ComponentRef left;
        list<DAE.ComponentRef> crefs;
        DAE.Exp right, leftexp;

      case BackendDAE.ASSIGN(left = leftexp as DAE.CREF(componentRef = left), right=right)
        equation
        (_,{varIndx}) = BackendVariable.getVar(left, vars);
        varsSolvedInWhenEqns = varIndx :: varsSolvedInWhenEqns;
        lst = adjacencyRowExpEnhanced(right, vars, mark, rowmark, lst);
        // mark all negative because the when condition cannot used to solve a variable
        _ = List.fold1(lst,markNegativ,rowmark,mark);
        //leftexp = Expression.crefExp(left);
        lst = adjacencyRowExpEnhanced(leftexp, vars, mark, rowmark, lst);
        outRow = adjacencyRowEnhanced1(lst,leftexp,right,vars,globalKnownVars,mark,rowmark,outRow,false);
      then ();

      case BackendDAE.ASSIGN(leftexp, right) equation
        crefs = Expression.getAllCrefs(leftexp);
        (_,varIdcs) = BackendVariable.getVarLst(crefs, vars);
        varsSolvedInWhenEqns = listAppend(varIdcs, varsSolvedInWhenEqns);
        lst = adjacencyRowExpEnhanced(right, vars, mark, rowmark, lst);
        // mark all negative because the when condition cannot used to solve a variable
        _ = List.fold1(lst,markNegativ,rowmark,mark);
        lst = adjacencyRowExpEnhanced(leftexp, vars, mark, rowmark, lst);
        outRow = adjacencyRowEnhanced1(lst,leftexp,right,vars,globalKnownVars,mark,rowmark,outRow,false);
      then ();

      else ();
    end match;

  end for;
  if isSome(oelsepart) then
    SOME(elsepart) := oelsepart;
    outRow := adjacencyRowWhenEnhanced(elsepart, mark, rowmark, vars, globalKnownVars, lst, outRow);
  end if;
end adjacencyRowWhenEnhanced;

protected function markNegativ
"author: Frenkel TUD 2012-05
  Helper function to adjacencyRowEnhanced. Update the array
  with a negative entry in indx."
  input Integer indx;
  input array<Integer> rowmark;
  input Integer mark;
  output Integer oMark;
algorithm
  _ := arrayUpdate(rowmark,indx,-mark);
  oMark := mark;
end markNegativ;

protected function adjacencyRowEnhanced1
"author: Frenkel TUD 2012-05
  Helper function to adjacencyRowEnhanced. Calculates the
  solvability of the variables."
  input list<Integer> lst;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables globalKnownVars;
  input Integer mark;
  input array<Integer> rowmark;
  input BackendDAE.AdjacencyMatrixElementEnhanced inRow;
  input Boolean trytosolve;
  output BackendDAE.AdjacencyMatrixElementEnhanced outRow;
algorithm
  outRow := matchcontinue(lst,e1,e2,vars,globalKnownVars,mark,rowmark,inRow)
    local
      Integer r,rabs;
      list<Integer> rest;
      DAE.Exp de,detmp, e, e_derAlias;
      DAE.ComponentRef cr,cr1,crarr;
      BackendDAE.Solvability solvab;
      list<DAE.ComponentRef> crlst;
      Absyn.Path path,path1;
      list<DAE.Exp> explst,crexplst, explst2;
      Boolean b,solved,derived;
      BackendDAE.Constraints cons;
    case({},_,_,_,_,_,_,_) then inRow;
/*    case(r::rest,_,_,_,_,_,_,_)
      equation
        // if r negativ then unsolvable
        true = intLt(r,0);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_UNSOLVABLE())::inRow,trytosolve);
*/    case(r::rest,DAE.CALL(path= Absyn.IDENT("der"),expLst={DAE.CREF(componentRef = cr)}),_,_,_,_,_,_)
      guard
        intGt(r,0)
      equation
        // if not negatet rowmark then
        false = intEq(rowmark[r],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1,varKind=BackendDAE.STATE()) = BackendVariable.getVarAt(vars, r);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasDerCref(e2,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.CALL(path= Absyn.IDENT("der"),expLst={DAE.CREF(componentRef = cr)}),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1,varKind=BackendDAE.STATE()) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasDerCref(e1,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.CREF(componentRef=cr),_,_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e2,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.CREF(componentRef=cr),_,_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        crarr = ComponentReference.crefStripLastSubs(cr1);
        true = ComponentReference.crefEqualNoStringCompare(cr, crarr);
        false = Expression.expHasCrefNoPreorDer(e2,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.LUNARY(operator=DAE.NOT(_),exp=DAE.CREF(componentRef=cr)),_,_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e2,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CREF(componentRef=cr)),_,_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e2,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CREF(componentRef=cr)),_,_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        crarr = ComponentReference.crefStripLastSubs(cr1);
        true = ComponentReference.crefEqualNoStringCompare(cr, crarr);
        false = Expression.expHasCrefNoPreorDer(e2,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.CREF(componentRef=cr),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e1,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.CREF(componentRef=cr),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        crarr = ComponentReference.crefStripLastSubs(cr1);
        true = ComponentReference.crefEqualNoStringCompare(cr, crarr);
        false = Expression.expHasCrefNoPreorDer(e1,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.LUNARY(operator=DAE.NOT(_),exp=DAE.CREF(componentRef=cr)),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e1,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CREF(componentRef=cr)),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e1,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CREF(componentRef=cr)),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        crarr = ComponentReference.crefStripLastSubs(cr1);
        true = ComponentReference.crefEqualNoStringCompare(cr, crarr);
        false = Expression.expHasCrefNoPreorDer(e1,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.CREF(componentRef=cr),_,_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefPrefixOf(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e2,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.CREF(componentRef=cr),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = ComponentReference.crefPrefixOf(cr, cr1);
        false = Expression.expHasCrefNoPreorDer(e1,cr);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.CALL(path=path,expLst=explst,attr=DAE.CALL_ATTR(ty= DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path1)))),_,_,_,_,_,_)
      equation
        true = Absyn.pathEqual(path,path1);
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = expCrefLstHasCref(explst,cr1);
        false = Expression.expHasCrefNoPreorDer(e2,cr1);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,DAE.CALL(path=path,expLst=explst,attr=DAE.CALL_ATTR(ty= DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path1)))),_,_,_,_,_)
      equation
        true = Absyn.pathEqual(path,path1);
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        true = expCrefLstHasCref(explst,cr1);
        false = Expression.expHasCrefNoPreorDer(e1,cr1);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,DAE.TUPLE(PR=explst),DAE.CALL(),_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then
        false = intEq(rowmark[rabs],-mark);
        // solved?
        BackendDAE.VAR(varName=cr1) = BackendVariable.getVarAt(vars, rabs);
        explst = List.flatten(List.map1(explst, Expression.generateCrefsExpLstFromExp, NONE()));
        crlst = List.map(explst, Expression.expCref);
        crlst = List.flatten(List.map1(crlst, ComponentReference.expandCref, true));
        crexplst = List.map(crlst, Expression.crefExp);
        true = expCrefLstHasCref(crexplst,cr1);
        false = Expression.expHasCrefNoPreorDer(e2,cr1);
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_SOLVED(),{})::inRow,trytosolve);
    case(r::rest,_,_,_,_,_,_,_)
      // case: state derivative
      equation
        // if not negatet rowmark then linear or nonlinear
        true = intGt(r,0);
        false = intEq(rowmark[r],-mark);
        // de/dvar
        BackendDAE.VAR(varName=cr,varKind=BackendDAE.STATE()) = BackendVariable.getVarAt(vars, r);
        cr1 = ComponentReference.crefPrefixDer(cr);
        e = Expression.crefExp(cr);
        ((e,_)) = Expression.replaceExp(Expression.expSub(e1,e2), DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), Expression.crefExp(cr1));
        e_derAlias = Expression.traverseExpDummy(e, replaceDerCall);
        (de,solved,derived,cons) = tryToSolveOrDerive(e_derAlias, cr1, vars, NONE(),trytosolve);
        if not solved then
          (de,_) = ExpressionSimplify.simplify(de);
          (_,crlst) = Expression.traverseExpBottomUp(de, Expression.traversingComponentRefFinder, {});
          solvab = adjacencyRowEnhanced2(cr1,de,crlst,vars,globalKnownVars);
        else
          if derived then
            (de,_) = ExpressionSimplify.simplify(de);
            (_,crlst) = Expression.traverseExpBottomUp(de, Expression.traversingComponentRefFinder, {});
            solvab = adjacencyRowEnhanced2(cr1,de,crlst,vars,globalKnownVars);
            solvab = transformSolvabilityForCasualTearingSet(solvab);
          else
            solvab = BackendDAE.SOLVABILITY_SOLVABLE();
          end if;
        end if;
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,solvab,cons)::inRow,trytosolve);
    case(r::rest,_,_,_,_,_,_,_)
      equation
        rabs = intAbs(r);
        // if not negatet rowmark then linear or nonlinear
        false = intEq(rowmark[rabs],-mark);
        // de/dvar
        BackendDAE.VAR(varName=cr) = BackendVariable.getVarAt(vars, rabs);
        e = Expression.expSub(e1,e2);
        e_derAlias = Expression.traverseExpDummy(e, replaceDerCall);
        (de,solved,derived,cons) = tryToSolveOrDerive(e_derAlias, cr, vars, NONE(),trytosolve);
        if not solved then
          (de,_) = ExpressionSimplify.simplify(de);
          (_,crlst) = Expression.traverseExpTopDown(de, Expression.traversingComponentRefFinderNoPreDer, {});
          solvab = adjacencyRowEnhanced2(cr,de,crlst,vars,globalKnownVars);
        else
          if derived then
            (de,_) = ExpressionSimplify.simplify(de);
            (_,crlst) = Expression.traverseExpTopDown(de, Expression.traversingComponentRefFinderNoPreDer, {});
            solvab = adjacencyRowEnhanced2(cr,de,crlst,vars,globalKnownVars);
            solvab = transformSolvabilityForCasualTearingSet(solvab);
          else
            solvab = BackendDAE.SOLVABILITY_SOLVABLE();
          end if;
        end if;
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,solvab,cons)::inRow,trytosolve);
    case(r::rest,_,_,_,_,_,_,_)
      then
        adjacencyRowEnhanced1(rest,e1,e2,vars,globalKnownVars,mark,rowmark,(r,BackendDAE.SOLVABILITY_UNSOLVABLE(),{})::inRow,trytosolve);
  end matchcontinue;
end adjacencyRowEnhanced1;


protected function replaceDerCall "
  replaces der-calls in expression with alias-variable"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
      String str;
      BackendDAE.Var v;
      list<DAE.Exp> expLst;

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr, ty=ty)}))
      equation
        v = BackendVariable.createAliasDerVar(cr);
        cr = BackendVariable.varCref(v);
        outExp = DAE.CREF(cr,ty);
     then (outExp);

    case (DAE.CALL(path=Absyn.IDENT(name="der")))
      equation
        str = "BackendDAEUtil.replaceDerCall failed for: " + ExpressionDump.printExpStr(inExp) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
     then fail();

    else (inExp);
  end matchcontinue;
end replaceDerCall;


protected function tryToSolveOrDerive
  input DAE.Exp e;
  input DAE.ComponentRef cr "x";
  input BackendDAE.Variables vars;
  input Option<DAE.FunctionTree> functions;
  input Boolean trytosolve1 "if true, try to solve the expression for the variable, even if flag 'allowImpossibleAssignments' is not set";
  output DAE.Exp f;
  output Boolean solved=false "true if equation is solved for the variable with ExpressionSolve.solve2, false if equation is differentiated";
  output Boolean derived=false;
  output BackendDAE.Constraints outCons={};
protected
  DAE.Type tp = Expression.typeof(e);
  Boolean trytosolve2 = stringEqual(Flags.getConfigString(Flags.TEARING_STRICTNESS), "casual");
  Boolean localCon;
  DAE.Exp one, tmpEqn, solvedExp, con;
  list<BackendDAE.Equation> eqnForNewVars;
  list<DAE.ComponentRef> newVarsCrefs;
  DAE.ComponentRef tmpVar;
  DAE.Constraint constraint;
  BackendDAE.Constraints constraints;
  constant Boolean debug = false;
algorithm
  if trytosolve1 or trytosolve2 then
    try // try to solve for x (1*x = f(y))
      (solvedExp,_,eqnForNewVars,newVarsCrefs) := ExpressionSolve.solve2(e, Expression.makeConstZero(tp),Expression.crefExp(cr), functions, SOME(1));

      if debug then
        print("Solve expression:\n" + ExpressionDump.printExpStr(e) + "\n");
        print("for variable: " + ExpressionDump.printExpStr(Expression.crefExp(cr)) + "\n");
        print("Solved expression:\n" + ExpressionDump.printExpStr(solvedExp) + "\n");
        ComponentReference.printComponentRefList(newVarsCrefs);
        BackendDump.dumpEquationList(eqnForNewVars, "eqnForNewVars");
        ExpressionDump.dumpExp(solvedExp);
        print("listLength(eqnForNewVars): " + intString(listLength(eqnForNewVars)) + "\n\n");
      end if;

      if trytosolve1 then
        (_,(constraints,_)) := Expression.traverseExpTopDown(solvedExp, getConstraints, ({},vars));

        for eqn in eqnForNewVars loop
          BackendDAE.SOLVED_EQUATION(componentRef=tmpVar, exp=tmpEqn) := eqn;
          (_,(constraints,_)) := Expression.traverseExpTopDown(tmpEqn, getConstraints, (constraints,vars));
        end for;


        for i in listLength(constraints):-1:1 loop
          constraint := listGet(constraints, i);
          DAE.CONSTRAINT_DT(constraint = con, localCon=localCon) := constraint;
          for eqn in eqnForNewVars loop
            BackendDAE.SOLVED_EQUATION(componentRef=tmpVar, exp=tmpEqn) := eqn;
            con := Expression.replaceCrefBottomUp(con, tmpVar, tmpEqn);
          end for;
          outCons := DAE.CONSTRAINT_DT(con, localCon)::outCons;
        end for;

        if debug then
          print("Constraints before substitution: " + ExpressionDump.constraintDTlistToString(constraints, "\n") + "\n\n");
          print("Substituted expression:\n" + ExpressionDump.printExpStr(solvedExp) + "\n");
          print("Constraints:" + ExpressionDump.constraintDTlistToString(outCons, "\n") + "\n\n");
        end if;
      end if;

      solved := true;
    else end try;
  end if;
  try
  f := Differentiate.differentiateExpSolve(e, cr, functions);
  f := match(f)
        /* der(f(x)) = c/y => c*x = y*lhs */
        case DAE.BINARY(one,DAE.DIV(), DAE.CREF()) /*Note: 1/x => ln(x) => Expression.solve will solve it */
          guard Expression.isConst(one) and not Expression.isZero(one)
        then one;
        else f;
      end match;
   derived := true;
   else
      f := Expression.makeConstOne(tp);
   end try;
   if Expression.isZero(f) then
    // see https://trac.openmodelica.org/OpenModelica/ticket/3742#comment:12
    // ExpressionSolve will fail for f == 0 --> internal loops inside tearing
    fail();
   end if;
   true := solved or derived;
   if debug then
     print("tryToSolveOrDerive" + ExpressionDump.printExpStr(e) + " -> " +  ExpressionDump.printExpStr(f) + " == " + ExpressionDump.printExpStr(Expression.crefExp(cr)) + "\n");
   end if;
end tryToSolveOrDerive;


protected function getConstraints "
author: ptaeuber
Function to find the constraints for Dynamic Tearing."
  input DAE.Exp inExp;
  input tuple<BackendDAE.Constraints,BackendDAE.Variables> inTpl;
  output DAE.Exp outExp;
  output Boolean cont=true;
  output tuple<BackendDAE.Constraints,BackendDAE.Variables> outTpl;
protected
  BackendDAE.Constraints inCons;
  BackendDAE.Variables vars;
algorithm
  (inCons,vars) := inTpl;
  (outExp,outTpl) := match(inExp)
    local
      DAE.Exp e;
      DAE.Exp rel;
      DAE.Constraint con;
      list<DAE.ComponentRef> crlst;
      Boolean localCon;
    case DAE.BINARY(operator=DAE.DIV(), exp2=e)
      equation
        rel = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"), {e}, DAE.callAttrBuiltinOther), DAE.GREATER(DAE.T_REAL_DEFAULT), DAE.RCONST(1e-12), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    case DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {e})
      equation
        rel = DAE.RELATION(e, DAE.GREATEREQ(DAE.T_REAL_DEFAULT), DAE.RCONST(0.0), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    case DAE.BINARY(exp1=e, operator=DAE.POW(), exp2=DAE.RCONST(0.5))
      equation
        rel = DAE.RELATION(e, DAE.GREATEREQ(DAE.T_REAL_DEFAULT), DAE.RCONST(0.0), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    case DAE.CALL(path = Absyn.IDENT(name = "log"), expLst = {e})
      equation
        rel = DAE.RELATION(e, DAE.GREATER(DAE.T_REAL_DEFAULT), DAE.RCONST(1e-12), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    case DAE.CALL(path = Absyn.IDENT(name = "log10"), expLst = {e})
      equation
        rel = DAE.RELATION(e, DAE.GREATER(DAE.T_REAL_DEFAULT), DAE.RCONST(1e-12), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    case DAE.CALL(path = Absyn.IDENT(name = "asin"), expLst = {e})
      equation
        rel = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"), {e}, DAE.callAttrBuiltinOther), DAE.LESSEQ(DAE.T_REAL_DEFAULT), DAE.RCONST(1.0), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    case DAE.CALL(path = Absyn.IDENT(name = "acos"), expLst = {e})
      equation
        rel = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"), {e}, DAE.callAttrBuiltinOther), DAE.LESSEQ(DAE.T_REAL_DEFAULT), DAE.RCONST(1.0), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    case DAE.CALL(path = Absyn.IDENT(name = "tan"), expLst = {e})
      equation
        rel = DAE.RELATION(DAE.BINARY(exp1=DAE.CALL(Absyn.IDENT("abs"), {DAE.BINARY(exp1=DAE.BINARY(exp1=e, operator=DAE.DIV(ty=DAE.T_REAL_DEFAULT), exp2=DAE.RCONST(3.14159265358979)), operator=DAE.MUL(ty=DAE.T_REAL_DEFAULT), exp2=DAE.RCONST(2.0))}, DAE.callAttrBuiltinOther), operator=DAE.SUB(ty=DAE.T_REAL_DEFAULT), exp2=DAE.CALL(Absyn.IDENT("floor"), {DAE.CALL(Absyn.IDENT("abs"), {DAE.BINARY(exp1=DAE.BINARY(exp1=e, operator=DAE.DIV(ty=DAE.T_REAL_DEFAULT), exp2=DAE.RCONST(3.14159265358979)), operator=DAE.MUL(ty=DAE.T_REAL_DEFAULT), exp2=DAE.RCONST(2.0))}, DAE.callAttrBuiltinOther)}, DAE.callAttrBuiltinOther)), DAE.GREATER(DAE.T_REAL_DEFAULT), DAE.RCONST(1e-12), -1, NONE());
        (_,crlst) = Expression.traverseExpTopDown(rel, Expression.traversingComponentRefFinderNoPreDer, {});
        localCon = containAnyVarWithoutStates(crlst,vars);
        con = DAE.CONSTRAINT_DT(rel,localCon);
     then (inExp,(con::inCons,vars));

    else
     then (inExp,inTpl);
  end match;
end getConstraints;


public function getEqnAndVarsFromInnerEquation
  "author: ptaeuber
   Returns the equation and the variables from BackendDAE record INNEREQUATION
   or the equation, variables and constraints from INNEREQUATIONCONSTRAINTS."
  input BackendDAE.InnerEquation innerEquation;
  output Integer outEqn;
  output list<Integer> outVars;
  output BackendDAE.Constraints outCons;
algorithm
  (outEqn,outVars,outCons) := match(innerEquation)
    local
      Integer eqn;
      list<Integer> vars;
      BackendDAE.Constraints cons;
    case(BackendDAE.INNEREQUATION(eqn=eqn, vars=vars)) then (eqn,vars,{});
    case(BackendDAE.INNEREQUATIONCONSTRAINTS(eqn=eqn, vars=vars, cons=cons)) then (eqn,vars,cons);
  end match;
end getEqnAndVarsFromInnerEquation;


protected function transformSolvabilityForCasualTearingSet
  input BackendDAE.Solvability inSolvab;
  output BackendDAE.Solvability outSolvab;
algorithm
  outSolvab := match(inSolvab)
    case BackendDAE.SOLVABILITY_CONST(b=false) then BackendDAE.SOLVABILITY_CONST(false);
    case BackendDAE.SOLVABILITY_PARAMETER(b=false) then BackendDAE.SOLVABILITY_PARAMETER(false);
    case BackendDAE.SOLVABILITY_LINEAR(b=false) then BackendDAE.SOLVABILITY_LINEAR(false);
    else BackendDAE.SOLVABILITY_SOLVABLE();
  end match;
end transformSolvabilityForCasualTearingSet;


protected function expCrefLstHasCref
  input list<DAE.Exp> iExpLst;
  input DAE.ComponentRef inCr;
  output Boolean outB;
algorithm
  outB := matchcontinue(iExpLst,inCr)
    local
      DAE.ComponentRef cr;
      list<DAE.Exp> rest;
      Boolean b;
    case ({},_) then false;
    case (DAE.CREF(componentRef=cr)::rest,_)
      equation
        b = ComponentReference.crefEqualNoStringCompare(cr,inCr);
        b = if not b then expCrefLstHasCref(rest, inCr) else b;
      then
        b;
    else
      then
        false;
  end matchcontinue;
end expCrefLstHasCref;

protected function adjacencyRowEnhanced2
"author: Frenkel TUD 2012-05
  Helper function to adjacencyRowEnhanced. Calculates the
  solvability of the variables."
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input list<DAE.ComponentRef> crlst;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.Solvability oSolvab;
algorithm
  oSolvab := match(cr,e,crlst,vars,globalKnownVars)
    local
      Boolean b,b1,b2;
    case(_,_,{},_,_)
      equation
        b1 = Expression.isZeroOrAlmostZero(e);
        b2 = Expression.isConstOne(e) or Expression.isConstMinusOne(e);
      then
        if b2 then BackendDAE.SOLVABILITY_CONSTONE() else BackendDAE.SOLVABILITY_CONST(not b1);
    case(_,_,_,_,_) guard List.isMemberOnTrue(cr,crlst,ComponentReference.crefEqualNoStringCompare)
      then
        BackendDAE.SOLVABILITY_NONLINEAR();
    case(_,_,_,_,_)
      equation
        b1 = containAnyVar(crlst,globalKnownVars);
        b2 = containAnyVar(crlst,vars);
      then
        adjacencyRowEnhanced3(b1,b2,cr,e,crlst,vars,globalKnownVars);
  end match;
end adjacencyRowEnhanced2;

protected function adjacencyRowEnhanced3
"author: Frenkel TUD 2012-05
  Helper function to adjacencyRowEnhanced. Calculates the
  solvability of the variables."
  input Boolean b1;
  input Boolean b2;
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input list<DAE.ComponentRef> crlst;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.Solvability oSolvab;
algorithm
  oSolvab := match(b1,b2,cr,e,crlst,vars,globalKnownVars)
    local
      Boolean b,b_1;
      DAE.Exp e1, nominal;
    case(true,true,_,_,_,_,_)
      equation
        (e1,_) = Expression.traverseExpBottomUp(e, replaceVarWithValue, globalKnownVars);
        (e1,_) = ExpressionSimplify.simplify(e1);
        b = not Expression.isZeroOrAlmostZero(e1);
      then
       BackendDAE.SOLVABILITY_LINEAR(b);
    case(false,_,_,_,_,_,_)
      equation
        b = not Expression.isZeroOrAlmostZero(e);
      then
        BackendDAE.SOLVABILITY_LINEAR(b);
    case(true,_,_,_,_,_,_)
      algorithm
        (nominal,_) := Expression.traverseExpBottomUp(e, replaceVarWithNominal, globalKnownVars);
        (nominal,_) := ExpressionSimplify.simplify(nominal);
        (e1,_) := Expression.traverseExpBottomUp(e, replaceVarWithValue, globalKnownVars);
        (e1,_) := ExpressionSimplify.simplify(e1);
        b := not Expression.isZeroOrAlmostZero(e1, nominal);
        b_1 := Expression.isConst(e1);
      then
       if b_1 then BackendDAE.SOLVABILITY_PARAMETER(b) else BackendDAE.SOLVABILITY_LINEAR(b);
    case(_,_,_,_,_,_,_)
      equation
        b = not Expression.isZeroOrAlmostZero(e);
      then
        BackendDAE.SOLVABILITY_LINEAR(b);
  end match;
end adjacencyRowEnhanced3;

protected function replaceVarWithValue
"Helper function to adjacencyRowEnhanced3. Traverser to replace variables(parameters) with their bind expression."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output DAE.Exp outExp;
  output BackendDAE.Variables outVars;
algorithm
  (outExp,outVars) := matchcontinue (inExp,inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      BackendDAE.Var v;
      DAE.Exp e;

    case (DAE.CREF(componentRef=cr),vars)
      equation
        (v::_,_) = BackendVariable.getVar(cr,vars);
        e = BackendVariable.varBindExp(v);
        (e,_) = Expression.traverseExpBottomUp(e, replaceVarWithValue, vars);
      then (e, vars);

    case (DAE.CREF(componentRef=cr),vars)
      equation
        (v::_,_) = BackendVariable.getVar(cr,vars);
        true = BackendVariable.varFixed(v);
        e = BackendVariable.varBindExpStartValue(v);
        (e,_) = Expression.traverseExpBottomUp(e, replaceVarWithValue, vars);
      then (e, vars);

    else (inExp,inVars);

  end matchcontinue;
end replaceVarWithValue;

protected function replaceVarWithNominal
"Helper function to adjacencyRowEnhanced3. Traverser to replace variables(parameters) with their nominal values."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output DAE.Exp outExp;
  output BackendDAE.Variables outVars;
algorithm
  (outExp,outVars) := matchcontinue (inExp,inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      BackendDAE.Var v;
      DAE.Exp nom;

    case (DAE.CREF(componentRef=cr),vars)
      equation
        (v::_,_) = BackendVariable.getVar(cr,vars);
        nom = BackendVariable.getVarNominalValue(v);
        (nom,_) = Expression.traverseExpBottomUp(nom, replaceVarWithNominal, vars);
      then (nom, vars);

    else (inExp,inVars);

  end matchcontinue;
end replaceVarWithNominal;

protected function adjacencyRowExpEnhanced
"author: Frenkel TUD 2012-05
  Helper function to adjacencyRowEnhanced, investigates expressions for
  variables, returning variable indexes, and mark the solvability."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input Integer mark;
  input array<Integer> rowmark;
  input list<Integer> inRow;
  output list<Integer> outRow;
algorithm
  (_,(_,_,_,_,outRow)) := Expression.traverseExpTopDown(inExp, traversingAdjacencyRowExpSolvableEnhancedFinder, (inVariables,false,mark,rowmark,inRow));
end adjacencyRowExpEnhanced;

protected function traversingAdjacencyRowExpSolvableEnhancedFinder "Helper for adjacencyRowExpEnhanced"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, Boolean, Integer, array<Integer>, list<Integer>> inTpl "(exp, (variables, unsolvable, mark, rowmark, row))";
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables, Boolean, Integer, array<Integer>, list<Integer>> outTpl;
algorithm
  (outExp, cont, outTpl) := matchcontinue (inExp, inTpl)
    local
      list<Integer> p, pa, res;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e1, e2, e3;
      list<BackendDAE.Var> varslst;
      Boolean b, bs;
      Integer mark, i;
      array<Integer> rowmark;
      BinaryTree.BinTree bt;
      Integer it;
      array<Integer> at;

    case (DAE.LUNARY(exp=e1), (vars, bs, it, at, pa)) equation
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e1, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
    then (inExp, false, (vars, bs, it, at, pa));

    case (DAE.LBINARY(exp1=e1, exp2=e2), (vars, bs, it, at, pa)) equation
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e1, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e2, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
    then (inExp, false, (vars, bs, it, at, pa));

    case (DAE.RELATION(exp1=e1, exp2=e2), (vars, bs, it, at, pa)) equation
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e1, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e2, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
    then (inExp, false, (vars, bs, it, at, pa));

    case (DAE.IFEXP(expCond=e3, expThen=e1, expElse=e2), (vars, bs, it, at, pa)) equation
      mark = it;
      rowmark = at;
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e1, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, bs, it, at, pa));
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e2, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, bs, it, at, pa));
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e3, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
      // mark all vars which are not in alle branches unsolvable
      (_, bt) = Expression.traverseExpTopDown(inExp, getIfExpBranchVarOccurency, BinaryTree.emptyBinTree);
      (_, (_, _, _, _)) = Expression.traverseExpBottomUp(e1, markBranchVars, (mark, rowmark, vars, bt));
      (_, (_, _, _, _)) = Expression.traverseExpBottomUp(e2, markBranchVars, (mark, rowmark, vars, bt));
    then (inExp, false, (vars, bs, it, at, pa));

    case (DAE.RANGE(start=e1, step=NONE(), stop=e2), (vars, bs, it, at, pa)) equation
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e1, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e2, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
    then (inExp, false, (vars, bs, it, at, pa));

    case (DAE.RANGE(start=e1, step=SOME(e3), stop=e2), (vars, bs, it, at, pa)) equation
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e1, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e2, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e3, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, true, it, at, pa));
    then (inExp, false, (vars, bs, it, at, pa));

    case (DAE.ASUB(exp=e1, sub={DAE.ICONST(i)}), (vars, bs, it, at, pa)) equation
      e1 = Expression.nthArrayExp(e1, i);
      (_, (vars, _, _, _, pa)) = Expression.traverseExpTopDown(e1, traversingAdjacencyRowExpSolvableEnhancedFinder, (vars, bs, it, at, pa));
    then (inExp, false, (vars, bs, it, at, pa));

    case (DAE.ASUB(), (_, _, _, _, _))
    then fail();

    case (DAE.CREF(componentRef=cr), (vars, bs, it, at, pa)) equation
      mark = it;
      rowmark = at;
      (varslst, p) = BackendVariable.getVar(cr, vars);
      res = adjacencyRowExpEnhanced1(varslst, p, pa, true, mark, rowmark, bs);
    then (inExp, false, (vars, bs, it, at, res));

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr)}), (vars, bs, it, at, pa)) equation
      mark = it;
      rowmark = at;
      (varslst, p) = BackendVariable.getVar(cr, vars);
      res = adjacencyRowExpEnhanced1(varslst, p, pa, false, mark, rowmark, bs);
    then (inExp, false, (vars, bs, it, at, res));

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr), DAE.ICONST(_)}), (vars, bs, it, at, pa)) equation
      mark = it;
      rowmark = at;
      (varslst, p) = BackendVariable.getVar(cr, vars);
      res = adjacencyRowExpEnhanced1(varslst, p, pa, false, mark, rowmark, bs);
    then (inExp, false, (vars, bs, it, at, res));

    // pre(v) is considered a known variable
    case (DAE.CALL(path=Absyn.IDENT(name="pre"), expLst={DAE.CREF()}), (_, _, _, _, _))
    then (inExp, false, inTpl);

    // previous(v) is considered a known variable
    case (DAE.CALL(path=Absyn.IDENT(name="previous"), expLst={DAE.CREF()}), (_, _, _, _, _))
    then (inExp, false, inTpl);

    // delay(e) can be used to break algebraic loops given some solver options
    case (DAE.CALL(path=Absyn.IDENT(name="delay"), expLst={_, _, e1, e2}), (_, _, _, _, _)) equation
      b = Flags.getConfigBool(Flags.DELAY_BREAK_LOOP) and Expression.expEqual(e1, e2);
    then (inExp, not b, inTpl);

    else (inExp, true, inTpl);
  end matchcontinue;
end traversingAdjacencyRowExpSolvableEnhancedFinder;

protected function markBranchVars "mark all vars of a if expression which are not in all branches as unsolvable"
  input DAE.Exp inExp;
  input tuple<Integer,array<Integer>,BackendDAE.Variables,BinaryTree.BinTree> inTuple;
  output DAE.Exp outExp;
  output tuple<Integer,array<Integer>,BackendDAE.Variables,BinaryTree.BinTree> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      BinaryTree.BinTree bt;
      list<Integer> ilst;
      Integer mark;
      array<Integer> rowmark;
      list<BackendDAE.Var> backendVars;

    // special case for time, it is never part of the equation system
    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),_)
      then (inExp, inTuple);

    // case for functionpointers
    case (DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC()),_)
      then (inExp, inTuple);

    // mark if not in bt
    case (DAE.CREF(componentRef = cr),(mark,rowmark,vars,bt))
      equation
         (backendVars,ilst) = BackendVariable.getVar(cr, vars);
         markBranchVars1(backendVars,ilst,mark,rowmark,bt);
      then (inExp, inTuple);

    else (inExp,inTuple);
  end matchcontinue;
end markBranchVars;

protected function markBranchVars1
"Author: Frenkel TUD 2012-09
  Helper for markBranchVars"
  input list<BackendDAE.Var> varlst;
  input list<Integer> iIlst;
  input Integer mark;
  input array<Integer> rowmark;
  input BinaryTree.BinTree bt;
algorithm
  _ := matchcontinue(varlst,iIlst,mark,rowmark,bt)
    local
      DAE.ComponentRef cr;
     list<BackendDAE.Var> vlst;
     Integer i;
     list<Integer> ilst;
    case({},_,_,_,_) then ();
    case(BackendDAE.VAR(varName=cr)::vlst,_::ilst,_,_,_)
      equation
        _ = BinaryTree.treeGet(bt,cr);
        markBranchVars1(vlst,ilst,mark,rowmark,bt);
      then
        ();
    case(_::vlst,i::ilst,_,_,_)
      equation
        arrayUpdate(rowmark,i,-mark);
        markBranchVars1(vlst,ilst,mark,rowmark,bt);
      then
        ();
  end matchcontinue;
end markBranchVars1;

protected function getIfExpBranchVarOccurency "Helper for getIfExpBranchVarOccurency"
  input DAE.Exp inExp;
  input BinaryTree.BinTree inBt;
  output DAE.Exp outExp;
  output Boolean cont;
  output BinaryTree.BinTree bt;
algorithm
  (outExp,cont,bt) := match (inExp,inBt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,e1,e2;
      BinaryTree.BinTree bt_then,bt_else;
      Boolean b;
      list<DAE.Exp> elst;
    case (e as DAE.IFEXP(expThen = e1,expElse = e2),bt)
      equation
        (_,bt_then) = Expression.traverseExpTopDown(e1,getIfExpBranchVarOccurency,BinaryTree.emptyBinTree);
        (_,bt_else) = Expression.traverseExpTopDown(e2,getIfExpBranchVarOccurency,BinaryTree.emptyBinTree);
        bt = BinaryTree.binTreeintersection(bt_then,bt_else,bt);
      then (e,false,bt);
    // skip relations,ranges,asubs
    case (e as DAE.LUNARY(),bt)
      then (e,false,bt);
    case (e as DAE.LBINARY(),bt)
      then (e,false,bt);
    case (e as DAE.RELATION(),bt)
      then (e,false,bt);
    case (e as DAE.RANGE(),bt)
      then (e,false,bt);
    case (e as DAE.RANGE(),bt)
      then (e,false,bt);
    case (e as DAE.ASUB(exp = e1),bt)
      equation
        (_,bt) = Expression.traverseExpTopDown(e1, getIfExpBranchVarOccurency, bt);
      then (e,false,bt);
    // add crefs
    case (e as DAE.CREF(componentRef = cr),bt)
      equation
        bt = BinaryTree.treeAdd(bt,cr,0);
      then (e,false,bt);
    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),bt)
      equation
        bt = BinaryTree.treeAdd(bt,cr,0);
      then (e,false,bt);
    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),bt)
      equation
        bt = BinaryTree.treeAdd(bt,cr,0);
      then (e,false,bt);
    // pre(v) is considered a known variable
    case (e as DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF()}),bt)
      then (e,false,bt);
    // previous(v) is considered a known variable
    case (e as DAE.CALL(path = Absyn.IDENT(name = "previous"),expLst = {DAE.CREF()}),bt)
      then (e,false,bt);
    // delay(e) can be used to break algebraic loops given some solver options
    case (e as DAE.CALL(path = Absyn.IDENT(name = "delay"),expLst = {_,_,e1,e2}),bt)
      equation
        b = Flags.getConfigBool(Flags.DELAY_BREAK_LOOP) and Expression.expEqual(e1,e2);
      then (e,not b,bt);
    else (inExp,true,inBt);
  end match;
end getIfExpBranchVarOccurency;

protected function adjacencyRowExpEnhanced1
"author: Frenkel TUD 2012-05
  Helper function to traversingAdjacencyRowExpSolvableEnhancedFinder, fill the variable indexes
  in the list and update the array to mark the variables."
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  input list<Integer> vars;
  input Boolean notinder;
  input Integer mark;
  input array<Integer> rowmark;
  input Boolean unsolvable;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVarLst,inIntegerLst,vars,notinder,mark,rowmark,unsolvable)
    local
       list<BackendDAE.Var> rest;
       list<Integer> irest,res;
       Integer i,i1;
       Boolean b,b1;
    case ({},{},_,_,_,_,_) then vars;
    /*If variable x is a state, der(x) is a variable in incidence matrix,
         x is inserted as negative value, since it is needed by debugging and
         index reduction using dummy derivatives */
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())::rest,i::irest,_,false,_,_,_)
      guard
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = adjacencyRowExpEnhanced1(rest,irest,i::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())::rest,i::irest,_,true,_,_,_)
      equation
        i1 = -i;
        failure(_ = List.getMemberOnTrue(i1, vars, intEq));
        res = adjacencyRowExpEnhanced1(rest,irest,i1::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())::rest,i::irest,_,_,_,_,_)
      guard
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = adjacencyRowExpEnhanced1(rest,irest,i::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER())::rest,i::irest,_,_,_,_,true)
      equation
        b = intEq(rowmark[i],mark);
        b1 = intEq(rowmark[i],-mark);
        b = b or b1;
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = List.consOnTrue(not b, i, vars);
        res = adjacencyRowExpEnhanced1(rest,irest,res,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE())::rest,i::irest,_,_,_,_,_)
      guard
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = adjacencyRowExpEnhanced1(rest,irest,i::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE())::rest,i::irest,_,_,_,_,true)
      equation
        b = intEq(rowmark[i],mark);
        b1 = intEq(rowmark[i],-mark);
        b = b or b1;
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = List.consOnTrue(not b, i, vars);
        res = adjacencyRowExpEnhanced1(rest,irest,res,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.ALG_STATE())::rest,i::irest,_,_,_,_,_)
      guard
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = adjacencyRowExpEnhanced1(rest,irest,i::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.ALG_STATE())::rest,i::irest,_,_,_,_,true)
      equation
        b = intEq(rowmark[i],mark);
        b1 = intEq(rowmark[i],-mark);
        b = b or b1;
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = List.consOnTrue(not b, i, vars);
        res = adjacencyRowExpEnhanced1(rest,irest,res,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())::rest,i::irest,_,_,_,_,_)
      guard
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = adjacencyRowExpEnhanced1(rest,irest,i::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE())::rest,i::irest,_,_,_,_,true)
      equation
        b = intEq(rowmark[i],mark);
        b1 = intEq(rowmark[i],-mark);
        b = b or b1;
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = List.consOnTrue(not b, i, vars);
        res = adjacencyRowExpEnhanced1(rest,irest,res,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER())::rest,i::irest,_,_,_,_,_)
      guard
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = adjacencyRowExpEnhanced1(rest,irest,i::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER())::rest,i::irest,_,_,_,_,true)
      equation
        b = intEq(rowmark[i],mark);
        b1 = intEq(rowmark[i],-mark);
        b = b or b1;
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = List.consOnTrue(not b, i, vars);
        res = adjacencyRowExpEnhanced1(rest,irest,res,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())::rest,i::irest,_,_,_,_,_)
      guard
        not intEq(intAbs(rowmark[i]),mark)
      equation
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = adjacencyRowExpEnhanced1(rest,irest,i::vars,notinder,mark,rowmark,unsolvable);
      then res;
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())::rest,i::irest,_,_,_,_,true)
      equation
        b = intEq(rowmark[i],mark);
        b1 = intEq(rowmark[i],-mark);
        b = b or b1;
        arrayUpdate(rowmark,i,if unsolvable then -mark else mark);
        res = List.consOnTrue(not b, i, vars);
        res = adjacencyRowExpEnhanced1(rest,irest,res,notinder,mark,rowmark,unsolvable);
      then res;
    case (_::rest,_::irest,_,_,_,_,_)
      equation
        res = adjacencyRowExpEnhanced1(rest,irest,vars,notinder,mark,rowmark,unsolvable);
      then res;
  end matchcontinue;
end adjacencyRowExpEnhanced1;

public function solvabilityWights
"author: Frenkel TUD 2012-05,
  return a integer for the solvability, this function is used
  to calculade wights for variables "
  input BackendDAE.Solvability solva;
  output Integer i;
algorithm
  i := match(solva)
    case BackendDAE.SOLVABILITY_SOLVED() then 1;
    case BackendDAE.SOLVABILITY_CONSTONE() then 2;
    case BackendDAE.SOLVABILITY_CONST() then 5;
    case BackendDAE.SOLVABILITY_PARAMETER(b=false) then 0;
    case BackendDAE.SOLVABILITY_PARAMETER(b=true) then 50;
    case BackendDAE.SOLVABILITY_LINEAR(b=false) then 0;
    case BackendDAE.SOLVABILITY_LINEAR(b=true) then 100;
    case BackendDAE.SOLVABILITY_NONLINEAR() then 500;
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then 1000;
  end match;
end solvabilityWights;

public function solvabilityCMP
"author: Frenkel TUD 2012-05,
  function to compare solvabilities in the way solvabilityA < solvabilityB with
  solved < constone < const < parameter < linear < nonlinear < unsolvable."
  input BackendDAE.Solvability sa;
  input BackendDAE.Solvability sb;
  output Boolean b;
algorithm
  b := match(sa,sb)
    case (BackendDAE.SOLVABILITY_SOLVED(),BackendDAE.SOLVABILITY_SOLVED()) then false;
    case (_,BackendDAE.SOLVABILITY_SOLVED()) then true;
    case (BackendDAE.SOLVABILITY_SOLVED(),BackendDAE.SOLVABILITY_CONSTONE()) then false;
    case (BackendDAE.SOLVABILITY_CONSTONE(),BackendDAE.SOLVABILITY_CONSTONE()) then false;
    case (_,BackendDAE.SOLVABILITY_CONSTONE()) then true;
    case (BackendDAE.SOLVABILITY_SOLVED(),BackendDAE.SOLVABILITY_CONST()) then false;
    case (BackendDAE.SOLVABILITY_CONSTONE(),BackendDAE.SOLVABILITY_CONST()) then false;
    case (BackendDAE.SOLVABILITY_CONST(),BackendDAE.SOLVABILITY_CONST()) then false;
    case (_,BackendDAE.SOLVABILITY_CONST()) then true;
    case (BackendDAE.SOLVABILITY_SOLVED(),BackendDAE.SOLVABILITY_PARAMETER()) then false;
    case (BackendDAE.SOLVABILITY_CONSTONE(),BackendDAE.SOLVABILITY_PARAMETER()) then false;
    case (BackendDAE.SOLVABILITY_CONST(),BackendDAE.SOLVABILITY_PARAMETER()) then false;
    case (BackendDAE.SOLVABILITY_PARAMETER(),BackendDAE.SOLVABILITY_PARAMETER()) then false;
    case (_,BackendDAE.SOLVABILITY_PARAMETER()) then true;
    case (BackendDAE.SOLVABILITY_SOLVED(),BackendDAE.SOLVABILITY_LINEAR()) then false;
    case (BackendDAE.SOLVABILITY_CONSTONE(),BackendDAE.SOLVABILITY_LINEAR()) then false;
    case (BackendDAE.SOLVABILITY_CONST(),BackendDAE.SOLVABILITY_LINEAR()) then false;
    case (BackendDAE.SOLVABILITY_PARAMETER(),BackendDAE.SOLVABILITY_LINEAR()) then false;
    case (BackendDAE.SOLVABILITY_LINEAR(),BackendDAE.SOLVABILITY_LINEAR()) then false;
    case (_,BackendDAE.SOLVABILITY_LINEAR()) then true;
    case (BackendDAE.SOLVABILITY_SOLVED(),BackendDAE.SOLVABILITY_NONLINEAR()) then false;
    case (BackendDAE.SOLVABILITY_CONSTONE(),BackendDAE.SOLVABILITY_NONLINEAR()) then false;
    case (BackendDAE.SOLVABILITY_CONST(),BackendDAE.SOLVABILITY_NONLINEAR()) then false;
    case (BackendDAE.SOLVABILITY_PARAMETER(),BackendDAE.SOLVABILITY_NONLINEAR()) then false;
    case (BackendDAE.SOLVABILITY_LINEAR(),BackendDAE.SOLVABILITY_NONLINEAR()) then false;
    case (BackendDAE.SOLVABILITY_NONLINEAR(),BackendDAE.SOLVABILITY_NONLINEAR()) then false;
    case (_,BackendDAE.SOLVABILITY_NONLINEAR()) then true;
    case (BackendDAE.SOLVABILITY_UNSOLVABLE(),BackendDAE.SOLVABILITY_UNSOLVABLE()) then false;
    case (BackendDAE.SOLVABILITY_UNSOLVABLE(),_) then true;
  end match;
end solvabilityCMP;

public function getArrayEquationSub"author: Frenkel TUD
  helper for calculateJacobianRow"
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
        subslst = Expression.dimensionSizesSubcriptsOpt(ad);
        (subs::subslst1) = Expression.rangesToSubscripts(subslst);
      then
        (subs,{(i,subslst1)});
    // found last entry
    case (i,_,((ie,{subs}))::rest)
      guard
        intEq(i,ie)
      then
        (subs,rest);
    // found entry
    case (i,_,((ie,subs::subslst))::rest)
      guard
        intEq(i,ie)
      then
        (subs,(ie,subslst)::rest);
    // next entry
    case (i,ad,(entry as (ie,_))::rest)
      guard
        not intEq(i,ie)
      equation
        (subs1,entrylst) = getArrayEquationSub(i,ad,rest);
      then
        (subs1,entry::entrylst);
    case (_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- BackendDAE.getArrayEquationSub failed\n");
      then
        fail();
  end matchcontinue;
end getArrayEquationSub;

public function containAnyVar "author: PA
  Returns true if any of the variables given
  as ComponentRef list is among the BackendDAE.Variables."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExpComponentRefLst,inVariables)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;
      BackendDAE.Variables vars;
    case ({},_) then false;
    case ((cr::_),vars)
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        true;
    case ((_::crefs),vars)
      then
       containAnyVar(crefs, vars);
  end matchcontinue;
end containAnyVar;

protected function containAnyVarWithoutStates
"Like containAnyVar but if var is state it is not counted."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExpComponentRefLst,inVariables)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;
      BackendDAE.Variables vars;
      BackendDAE.Var v;
    case ({},_) then false;
    case ((cr::_),vars)
      equation
        (v::_,_) = BackendVariable.getVar(cr, vars);
        false = BackendVariable.isStateVar(v);
      then
        true;
    case ((_::crefs),vars)
      then
       containAnyVarWithoutStates(crefs, vars);
  end matchcontinue;
end containAnyVarWithoutStates;

public function getEqnSysRhs "author: Frenkel TUD 2013-02

  Retrieve the right hand side of an equation system, given a set of variables.
  Uses A1*x + b1= A2*x + b2 -> 0 = (A1 - A2)*x+(b1-b2) -> x=0 -> rhs= A*0+b=b.
  Does not work for nonlinear Equations.

  inputs:  (DAE.Exp, BackendDAE.Variables /* variables of the eqn sys. */)
  outputs:  DAE.Exp =
"
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVariables;
  input Option<DAE.FunctionTree> funcs;
  output list<DAE.Exp> outRhsExps;
  output list<DAE.ElementSource> outSources;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  repl := makeZeroReplacements(inVariables);
  ((_, outRhsExps, outSources, _, _)) := BackendEquation.traverseEquationArray(inEqns, equationToExp, (inVariables, {}, {}, funcs, repl));
end getEqnSysRhs;

protected function equationToExp
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.Variables,list<DAE.Exp>,list<DAE.ElementSource>,Option<DAE.FunctionTree>,BackendVarTransform.VariableReplacements> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.Variables,list<DAE.Exp>,list<DAE.ElementSource>,Option<DAE.FunctionTree>,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  (outEq,outTpl) := matchcontinue (inEq,inTpl)
    local
      DAE.Exp e;
      DAE.Exp e1,e2,new_exp,rhs_exp,rhs_exp_1,rhs_exp_2;
      list<Integer> ds;
      list<Option<Integer>> ad;
      BackendDAE.Equation eqn;
      BackendDAE.Variables v;
      list<DAE.Exp> explst,explst1;
      list<DAE.ElementSource> sources;
      DAE.ElementSource source;
      String str;
      list<list<DAE.Subscript>> subslst;
      Option<DAE.FunctionTree> funcs;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef componentRef;

    case (eqn as BackendDAE.RESIDUAL_EQUATION(exp=e,source=source),(v,explst,sources,funcs,repl))
      equation
        rhs_exp = getEqnsysRhsExp(e, v, funcs, SOME(repl));
      then (eqn,(v,rhs_exp::explst,source::sources,funcs,repl));

    case (eqn as BackendDAE.EQUATION(exp=e1, scalar=e2,source=source),(v,explst,sources,funcs,repl))
      equation
        new_exp = Expression.expSub(e1,e2);
        rhs_exp = getEqnsysRhsExp(new_exp, v, funcs, SOME(repl));
        rhs_exp_1 = Expression.negate(rhs_exp);
        (rhs_exp_2,_) = ExpressionSimplify.simplify(rhs_exp_1);
      then (eqn,(v,rhs_exp_2::explst,source::sources,funcs,repl));

    case (eqn as BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2, source=source), (v,explst,sources,funcs,repl))
      equation
        new_exp = Expression.expSub(e1,e2);
        subslst = Expression.dimensionSizesSubscripts(ds);
        subslst = Expression.rangesToSubscripts(subslst);
        explst1 = List.map1r(subslst,Expression.applyExpSubscripts,new_exp);
        explst1 = List.map3(explst1,getEqnsysRhsExp,v,funcs,SOME(repl));
        explst1 = List.map(explst1,Expression.negate);
        explst1 = ExpressionSimplify.simplifyList(explst1);
        explst = List.append_reverse(explst1,explst);
        sources = List.consN(BackendEquation.equationSize(eqn), source, sources);
      then (eqn,(v,explst,sources,funcs,repl));

    case (eqn as BackendDAE.SOLVED_EQUATION(componentRef=componentRef, exp=e2, source=source),(v,explst,sources,funcs,repl))
      equation
        e1 = Expression.crefExp(componentRef);
        new_exp = Expression.expSub(e1,e2);
        rhs_exp = getEqnsysRhsExp(new_exp, v, funcs, SOME(repl));
        rhs_exp_1 = Expression.negate(rhs_exp);
        (rhs_exp_2,_) = ExpressionSimplify.simplify(rhs_exp_1);
      then (eqn,(v,rhs_exp_2::explst,source::sources,funcs,repl));

    case (eqn as BackendDAE.COMPLEX_EQUATION(),_)
      equation
        str = BackendDump.equationString(eqn);
        str = "BackendDAEUtil.equationToExp failed for complex equation: " + str;
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},BackendEquation.equationInfo(eqn));
      then fail();

    case (eqn,_)
      equation
        str = BackendDump.equationString(eqn);
        str = "BackendDAEUtil.equationToExp failed: " + str;
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},BackendEquation.equationInfo(eqn));
      then
        fail();
  end matchcontinue;
end equationToExp;

public function getEqnsysRhsExp "author: PA

  Retrieve the right hand side expression of an equation
  in an equation system, given a set of variables.
  Uses A1*x + b1= A2*x + b2 -> 0 = (A1 - A2)*x+(b1-b2) -> x=0 -> rhs= A*0+b=b.
  Does not work for nonlinear Equations.

  inputs:  (DAE.Exp, BackendDAE.Variables /* variables of the eqn sys. */)
  outputs:  DAE.Exp =
"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input Option<DAE.FunctionTree> funcs;
  input Option<BackendVarTransform.VariableReplacements> oRepl;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp,inVariables,funcs,oRepl)
    local
      BackendVarTransform.VariableReplacements repl;
    case (_,_,_,SOME(repl))
      equation
       (outExp,(_,_,_,true)) = Expression.traverseExpTopDown(inExp, getEqnsysRhsExp1, (repl,inVariables,funcs,true));
       (outExp,_) = ExpressionSimplify.simplify(outExp);
      then
        outExp;
    else
      equation
        repl = makeZeroReplacements(inVariables);
       (outExp,(_,_,_,true)) = Expression.traverseExpTopDown(inExp, getEqnsysRhsExp1, (repl,inVariables,funcs,true));
       (outExp,_) = ExpressionSimplify.simplify(outExp);
      then
        outExp;
  end match;
end getEqnsysRhsExp;

protected function getEqnsysRhsExp1
  input DAE.Exp inExp;
  input tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,Option<DAE.FunctionTree>,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,Option<DAE.FunctionTree>,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := match (inExp,inTpl)
    local
      DAE.Exp cond,t,f,e, e1, e2, zero,exp;
      DAE.Type tp;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Variables vars;
      Boolean b,b1;
      Absyn.Path path;
      list<DAE.Exp> expLst;
      Option<DAE.FunctionTree> funcs;
      tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,Option<DAE.FunctionTree>,Boolean> tpl;
    case (e as DAE.CREF(),(repl,_,_,_))
      equation
        (e1,b1) = BackendVarTransform.replaceExp(e, repl, NONE());
        e1 = if b1 then e1 else e;
      then (e1,false,inTpl);

    case (DAE.IFEXP(cond,t,f),(repl,vars,funcs,b))
      equation
        // check if vars not in condition
        (_,(_,b)) = Expression.traverseExpTopDown(cond, getEqnsysRhsExp2, (vars,b));
        (t,tpl) = Expression.traverseExpTopDown(t, getEqnsysRhsExp1, (repl,vars,funcs,b));
        (f,tpl) = Expression.traverseExpTopDown(f, getEqnsysRhsExp1, tpl);
      then
        (DAE.IFEXP(cond,t,f),false,tpl);

    case (e as DAE.CALL(path=Absyn.IDENT(name = "der")),_)
      then (e,true,inTpl);

    case (e as DAE.CALL(path = Absyn.IDENT(name = "pre")),_)
      then (e,false,inTpl);

    case (e as DAE.CALL(path = Absyn.IDENT(name = "previous")),_)
      then (e,false,inTpl);

    case (e as DAE.CALL(path = Absyn.IDENT(name = "semiLinear"), expLst={cond,t,f}),_)
       equation
        tp = Expression.typeof(e);
        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        e1 = Expression.expMul(cond,t);
        e2 = Expression.expMul(cond,f);
        exp = DAE.IFEXP(DAE.RELATION(cond, DAE.GREATEREQ(tp), zero, -1, NONE()), e1, e2);
        (exp, tpl) = Expression.traverseExpTopDown(exp, getEqnsysRhsExp1, inTpl);
      then (exp,false,tpl);

    case (e as DAE.CALL(expLst=expLst),(repl,vars,funcs,b))
      equation
        // check if vars not in expList
        (_,(_,b)) = Expression.traverseExpListTopDown(expLst, getEqnsysRhsExp2, (vars,b));
        (e,b) = getEqnsysRhsExp3(b,e,(repl,vars,funcs,true));
      then (e,false,(repl,vars,funcs,b));

    case (e,(_,_,_,b)) then (e,b,inTpl);
  end match;
end getEqnsysRhsExp1;

protected function getEqnsysRhsExp3
  input Boolean b;
  input DAE.Exp inExp;
  input tuple<BackendVarTransform.VariableReplacements,BackendDAE.Variables,Option<DAE.FunctionTree>,Boolean> iTpl;
  output DAE.Exp oExp;
  output Boolean notfound;
algorithm
  (oExp,notfound) := matchcontinue(b,inExp,iTpl)
  local
    Option<DAE.FunctionTree> funcs;
    DAE.Exp e;
  case (false,_,(_,_,funcs,_))
    equation
      // try to inline
      (e,_,true) = Inline.forceInlineExp(inExp,(funcs,{DAE.NORM_INLINE(),DAE.DEFAULT_INLINE()}),DAE.emptyElementSource);
      (e,(_,_,_,notfound)) = Expression.traverseExpTopDown(e, getEqnsysRhsExp1, iTpl);
    then
      (e,notfound);
  else (inExp,b);
  end matchcontinue;
end getEqnsysRhsExp3;

public function getEqnsysRhsExp2
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      Boolean b;
    // special case for time, it is never part of the equation system
    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),_)
      then (inExp, false, inTpl);

    // case for functionpointers
    case (DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC()),_)
      then (inExp, false, inTpl);

    case (DAE.CALL(path = Absyn.IDENT(name = "pre")),_)
      then (inExp,false,inTpl);

    case (DAE.CALL(path = Absyn.IDENT(name = "previous")),_)
      then (inExp,false,inTpl);

    // found ?
    case (DAE.CREF(componentRef = cr),(vars,_))
      equation
         (_::_,_) = BackendVariable.getVar(cr, vars);
      then (inExp, false,(vars,false));

    case (_,(_,b)) then (inExp,b,inTpl);
  end matchcontinue;
end getEqnsysRhsExp2;

public function makeZeroReplacements "
  Help function to ifBranchesFreeFromVar, creates replacement rules
  v -> 0, for all variables"
  input BackendDAE.Variables vars;
  output BackendVarTransform.VariableReplacements repl;
algorithm
  repl := BackendVariable.traverseBackendDAEVars(vars,makeZeroReplacement,BackendVarTransform.emptyReplacements());
end makeZeroReplacements;

protected function makeZeroReplacement "helper function to makeZeroReplacements.
Creates replacement BackendDAE.Var -> 0"
  input BackendDAE.Var inVar;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Var var;
  output BackendVarTransform.VariableReplacements repl;
algorithm
  (var,repl) := matchcontinue (inVar,inRepl)
    local
      DAE.ComponentRef cr;
    case (var,repl)
      equation
        cr =  BackendVariable.varCref(var);
        repl = BackendVarTransform.addReplacement(repl,cr,Expression.makeConstZero(ComponentReference.crefLastType(cr)),NONE());
      then (var,repl);
    else (inVar,inRepl);
  end matchcontinue;
end makeZeroReplacement;

/*************************************************
 * traverseBackendDAE and stuff
 ************************************************/
public function traverseBackendDAEExps "author: Frenkel TUD

  This function goes through the BackendDAE structure and finds all the
  expressions and performs the function on them in a list
  an extra argument passed through the function.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.BackendDAE inBackendDAE;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA := matchcontinue inBackendDAE
    local
      BackendDAE.Shared shared;
      list<BackendDAE.EqSystem> systs;
      String name;

    case BackendDAE.DAE(systs, shared)
      equation
        outTypeA = List.fold1(systs, traverseBackendDAEExpsEqSystem, func, inTypeA);
        outTypeA = traverseBackendDAEExpsVars(shared.globalKnownVars, func, outTypeA);
        outTypeA = traverseBackendDAEExpsEqns(shared.initialEqs, func, outTypeA);
        outTypeA = traverseBackendDAEExpsEqns(shared.removedEqs, func, outTypeA);
      then
        outTypeA;

    else equation
      (_, _, name) = System.dladdr(func);
      Error.addInternalError("traverseBackendDAEExps failed for " + name, sourceInfo());
    then fail();
  end matchcontinue;
end traverseBackendDAEExps;

public function traverseBackendDAEExpsEqSystemJacobians "author: wbraun

  This function goes through the all jacobians and stateSets and finds all the
  expressions and performs the function on them in a list
  an extra argument passed through the function.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EqSystem syst;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA :=
  matchcontinue(syst, func, inTypeA)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.StateSets stateSets;
      Type_a arg;
    case (BackendDAE.EQSYSTEM(stateSets = stateSets), _, _)
      equation
        comps = getStrongComponents(syst);
        arg = traverseStrongComponentsJacobiansExp(comps, func, inTypeA);
        arg = traverseStateSetsJacobiansExp(stateSets, func, arg);
     then arg;
    else inTypeA;
  end matchcontinue;
end traverseBackendDAEExpsEqSystemJacobians;

public function traverseStrongComponentsJacobiansExp
 "author: wbraun"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.StrongComponents inComps;
  input FuncExpType inFunc;
  input output Type_a arg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  for comp in inComps loop
    arg := match comp
      local
        list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
        BackendDAE.BackendDAE bdae;
      case BackendDAE.EQUATIONSYSTEM(jac=BackendDAE.FULL_JACOBIAN(SOME(jac)))
        then traverseBackendDAEExpsJacobianEqn(jac, inFunc, arg);
      case BackendDAE.EQUATIONSYSTEM(jac=BackendDAE.GENERIC_JACOBIAN(jacobian = SOME((bdae,_,_,_,_,_))))
        then traverseBackendDAEExps(bdae, inFunc, arg);
      case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(jac=BackendDAE.GENERIC_JACOBIAN(jacobian = SOME((bdae,_,_,_,_,_)))))
        then traverseBackendDAEExps(bdae, inFunc, arg);
      else arg;
    end match;
  end for;
end traverseStrongComponentsJacobiansExp;

protected function traverseBackendDAEExpsJacobianEqn "Helper for traverseExpsOfEquation."
  replaceable type Type_a subtypeof Any;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inJacEntry;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA :=
    match (inJacEntry, func, inTypeA)
     local
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      Integer i,j;
      BackendDAE.Equation eqn;
      Type_a typeA;
    case ({}, _, _) then inTypeA;
    case ((_,_,eqn)::_, _, _)
      equation
       typeA = traverseBackendDAEExpsOptEqn(SOME(eqn),func,inTypeA);
     then typeA;
  end match;
end traverseBackendDAEExpsJacobianEqn;

public function traverseStateSetsJacobiansExp
  replaceable type Type_a subtypeof Any;
  input BackendDAE.StateSets inStateSets;
  input FuncExpType inFunc;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA :=
  match(inStateSets, inFunc, inTypeA)
    local
      BackendDAE.StateSets rest;
      BackendDAE.StateSet set;
      BackendDAE.BackendDAE bdae;
      Type_a arg;
    case ({}, _, _) then inTypeA;
    case (BackendDAE.STATESET(jacobian = BackendDAE.GENERIC_JACOBIAN(jacobian = SOME((bdae,_,_,_,_,_))))::rest, _, _)
      equation
        arg = traverseBackendDAEExps(bdae, inFunc, inTypeA);
      then
        traverseStateSetsJacobiansExp(rest, inFunc, arg);
  end match;
end traverseStateSetsJacobiansExp;

public function traverseBackendDAEExpsNoCopyWithUpdate<A>
 "This function goes through the BackendDAE structure and finds all the
  expressions and performs the function on them in a list
  an extra argument passed through the function."
  input BackendDAE.BackendDAE inBackendDAE;
  input FuncExpType func;
  input A inTypeA;
  output A outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end FuncExpType;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
  String name;
algorithm
  try
    BackendDAE.DAE(systs, shared) := inBackendDAE;
    outTypeA := List.fold1(systs, traverseBackendDAEExpsEqSystemWithUpdate, func, inTypeA);
    outTypeA := traverseBackendDAEExpsVarsWithUpdate(shared.globalKnownVars, func, outTypeA);
    outTypeA := traverseBackendDAEExpsEqns(shared.initialEqs, func, outTypeA);
    outTypeA := traverseBackendDAEExpsEqns(shared.removedEqs, func, outTypeA);
  else
    (_, _, name) := System.dladdr(func);
    Error.addInternalError("traverseBackendDAEExpsNoCopyWithUpdate failed for " + name, sourceInfo());
    fail();
  end try;
end traverseBackendDAEExpsNoCopyWithUpdate;

public function traverseBackendDAEExpsEqSystem "This function goes through the BackendDAE structure and finds all the
  expressions and performs the function on them in a list
  an extra argument passed through the function.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EqSystem syst;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA := traverseBackendDAEExpsVars(syst.orderedVars, func, inTypeA);
  outTypeA := traverseBackendDAEExpsEqns(syst.orderedEqs, func, outTypeA);
  outTypeA := traverseBackendDAEExpsEqns(syst.removedEqs, func, outTypeA);
end traverseBackendDAEExpsEqSystem;

public function traverseBackendDAEExpsEqSystemWithUpdate "This function goes through the BackendDAE structure and finds all the
  expressions and performs the function on them in a list
  an extra argument passed through the function."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EqSystem syst;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA := traverseBackendDAEExpsVarsWithUpdate(syst.orderedVars, func, inTypeA);
  outTypeA := traverseBackendDAEExpsEqns(syst.orderedEqs, func, outTypeA);
  outTypeA := traverseBackendDAEExpsEqns(syst.removedEqs, func, outTypeA);
end traverseBackendDAEExpsEqSystemWithUpdate;

public function traverseBackendDAEExpsVars "Helper for traverseBackendDAEExps"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Variables inVariables;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inVariables)
    local
      array<Option<BackendDAE.Var>> varOptArr;
      Type_a ext_arg_1;
      String name;
    case BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr))
      equation
        ext_arg_1 = traverseArrayNoCopy(varOptArr,func,traverseBackendDAEExpsVar,inTypeA);
      then
        ext_arg_1;

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      (_, _, name) = System.dladdr(func);
      Debug.trace("- BackendDAE.traverseBackendDAEExpsVars failed for " + name + "\n");
    then fail();
  end matchcontinue;
end traverseBackendDAEExpsVars;

public function traverseBackendDAEExpsVarsWithUpdate "Helper for traverseBackendDAEExps"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Variables inVariables;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA:=
  matchcontinue (inVariables)
    local
      array<Option<BackendDAE.Var>> varOptArr;
      Type_a ext_arg_1;
      String name;
    case BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr))
      equation
        (_,ext_arg_1) = traverseArrayNoCopyWithUpdate(varOptArr,func,traverseBackendDAEExpsVarWithUpdate,inTypeA);
      then
        ext_arg_1;

    else equation
      (_, _, name) = System.dladdr(func);
      Error.addInternalError("traverseBackendDAEExpsVarsWithUpdate failed for " + name, sourceInfo());
    then fail();
  end matchcontinue;
end traverseBackendDAEExpsVarsWithUpdate;

public function traverseArrayNoCopy<ArrT, ElemT, ArgT>
  input array<ArrT> inArray;
  input ElemFuncType inElemFunc;
  input ArrayFuncType inArrayFunc;
  input ArgT inArg;
  input Integer inLength = arrayLength(inArray);
  output ArgT outArg = inArg;

  partial function ElemFuncType
    input ElemT inElement;
    input ArgT inArg;
    output ElemT outElement;
    output ArgT outArg;
  end ElemFuncType;

  partial function ArrayFuncType
    input ArrT inElement;
    input ElemFuncType inFunc;
    input ArgT inArg;
    output ArgT outArg;
  end ArrayFuncType;
algorithm
  true := inLength <= arrayLength(inArray);

  for i in 1:inLength loop
    outArg := inArrayFunc(inArray[i], inElemFunc, outArg);
  end for;
end traverseArrayNoCopy;

public function traverseArrayNoCopyWithStop<ArrT, ElemT, ArgT>
  "Same as traverseArrayNoCopy, but with an additional parameter to
   stop the traversal."
  input array<ArrT> inArray;
  input ElemFuncType inElemFunc;
  input ArrayFuncType inArrayFunc;
  input ArgT inArg;
  input Integer inLength = arrayLength(inArray);
  output ArgT outArg = inArg;

  partial function ElemFuncType
    input ElemT inElement;
    input ArgT inArg;
    output ElemT outElement;
    output Boolean outContinue;
    output ArgT outArg;
  end ElemFuncType;

  partial function ArrayFuncType
    input ArrT inElement;
    input ElemFuncType inFunc;
    input ArgT inArg;
    output Boolean outContinue;
    output ArgT outArg;
  end ArrayFuncType;
protected
  Boolean cont;
algorithm
  true := inLength <= arrayLength(inArray);

  for i in 1:inLength loop
    (cont, outArg) := inArrayFunc(inArray[i], inElemFunc, outArg);
    if not cont then break; end if;
  end for;
end traverseArrayNoCopyWithStop;

public function traverseArrayNoCopyWithUpdate<ArrT, ElemT, ArgT>
  input array<ArrT> inArray;
  input ElemFuncType inElemFunc;
  input ArrayFuncType inArrayFunc;
  input ArgT inArg;
  input Integer inLength = arrayLength(inArray);
  output array<ArrT> outArray = inArray;
  output ArgT outArg = inArg;

  partial function ElemFuncType
    input ElemT inElement;
    input ArgT inArg;
    output ElemT outElement;
    output ArgT outArg;
  end ElemFuncType;

  partial function ArrayFuncType
    input ArrT inElement;
    input ElemFuncType inFunc;
    input ArgT inArg;
    output ArrT outElement;
    output ArgT outArg;
  end ArrayFuncType;
protected
  ArrT e, new_e;
algorithm
  true := inLength <= arrayLength(inArray);

  for i in 1:inLength loop
    e := inArray[i];
    (new_e, outArg) := inArrayFunc(e, inElemFunc, outArg);
    if not referenceEq(e, new_e) then
      arrayUpdate(outArray, i, new_e);
    end if;
  end for;
end traverseArrayNoCopyWithUpdate;

protected function traverseBackendDAEExpsVar "author: Frenkel TUD
  Helper traverseBackendDAEExpsVar. Get all exps from a BackendDAE.Var.
  DAE.T_UNKNOWN_DEFAULT is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Var> inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (_,outTypeA):=traverseBackendDAEExpsVarWithUpdate(inVar,func,inTypeA);
end traverseBackendDAEExpsVar;

protected function traverseBackendDAEExpsVarWithUpdate "author: Frenkel TUD
  Helper traverseBackendDAEExpsVar. Get all exps from a BackendDAE.Var.
  DAE.T_UNKNOWN_DEFAULT is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Var> inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output Option<BackendDAE.Var> ovar;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (ovar, outTypeA) := matchcontinue(inVar)
    local
      DAE.Exp e1, e1_;
      DAE.ComponentRef cref;
      list<DAE.Dimension> instdims;
      Option<DAE.VariableAttributes> attr, attr_;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      Type_a ext_arg_1, ext_arg_2;
      BackendDAE.VarKind varKind;
      DAE.VarDirection varDirection;
      DAE.VarParallelism varParallelism;
      BackendDAE.Type varType;
      DAE.ElementSource source;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      DAE.VarInnerOuter io;
      Boolean unreplaceable;
      String name;
      Option<BackendDAE.Var> v;
      Option<DAE.Exp> tplExp;

    case NONE()
    then (NONE(), inTypeA);

    case SOME(BackendDAE.VAR(cref, varKind, varDirection, varParallelism, varType, SOME(e1), tplExp, instdims, source, attr, ts, hideResult, comment, ct, io, unreplaceable)) equation
      (e1_, ext_arg_1) = func(e1, inTypeA);
      (attr_, ext_arg_2) = traverseBackendDAEVarAttr(attr, func, ext_arg_1);
      if referenceEq(e1,e1_) and referenceEq(attr,attr_) then
        v = inVar;
      else
        v = SOME(BackendDAE.VAR(cref, varKind, varDirection, varParallelism, varType, SOME(e1_), tplExp, instdims, source, attr_, ts, hideResult, comment, ct, io, unreplaceable));
      end if;
    then (v, ext_arg_2);

    case SOME(BackendDAE.VAR(cref, varKind, varDirection, varParallelism, varType, NONE(), tplExp, instdims, source, attr, ts, hideResult, comment, ct, io, unreplaceable)) equation
      (attr_, ext_arg_2) = traverseBackendDAEVarAttr(attr, func, inTypeA);
      if referenceEq(attr,attr_) then
        v = inVar;
      else
        v = SOME(BackendDAE.VAR(cref, varKind, varDirection, varParallelism, varType, NONE(), tplExp, instdims, source, attr_, ts, hideResult, comment, ct, io, unreplaceable));
      end if;
    then (v, ext_arg_2);

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      (_, _, name) = System.dladdr(func);
      Debug.trace("- BackendDAE.traverseBackendDAEExpsVar failed for " + name + "\n");
    then fail();
  end matchcontinue;
end traverseBackendDAEExpsVarWithUpdate;

public function traverseBackendDAEVarAttr
"help function to traverseBackendDAEExpsVarWithUpdate
author: Peter Aronsson (paronsson@wolfram.com)
"
  input Option<DAE.VariableAttributes> attr;
  input FuncExpType func;
  input ExtraArgType extraArg;
  replaceable type ExtraArgType subtypeof Any;
  partial function FuncExpType
    input DAE.Exp inExp;
    input ExtraArgType inTypeA;
    output DAE.Exp outExp;
    output ExtraArgType outA;
  end FuncExpType;
  output Option<DAE.VariableAttributes> outAttr;
  output ExtraArgType outExtraArg;
algorithm
 (outAttr,outExtraArg) := match(attr,func,extraArg)
   local
     Option<DAE.Exp> q,u,du,min,max,i,f,n,eqbound,startOrigin;
     Option<DAE.Exp> q_,u_,du_,min_,max_,i_,f_,n_,eqbound_;
     Option<DAE.StateSelect> ss;
     Option<DAE.Uncertainty> unc;
     Option<DAE.Distribution> dist, dist_;
     Option<Boolean> p,fin;
     Option<DAE.VariableAttributes> a;
   case(NONE(),_,_) then (NONE(),extraArg);
   case(SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,dist,eqbound,p,fin,startOrigin)),_,_) equation
     (q_,outExtraArg) = Expression.traverseExpOpt(q,func,extraArg);
     (u_,outExtraArg) = Expression.traverseExpOpt(u,func,outExtraArg);
     (du_,outExtraArg) = Expression.traverseExpOpt(du,func,outExtraArg);
     (min_,outExtraArg) = Expression.traverseExpOpt(min,func,outExtraArg);
     (max_,outExtraArg) = Expression.traverseExpOpt(max,func,outExtraArg);
     (i_,outExtraArg) = Expression.traverseExpOpt(i,func,outExtraArg);
     (f_,outExtraArg) = Expression.traverseExpOpt(f,func,outExtraArg);
     (n_,outExtraArg) = Expression.traverseExpOpt(n,func,outExtraArg);
     (eqbound_,outExtraArg) = Expression.traverseExpOpt(eqbound,func,outExtraArg);
     (dist_,outExtraArg) = traverseBackendDAEAttrDistribution(dist,func,outExtraArg);
     if referenceEq(q,q_) and referenceEq(u,u_) and referenceEq(du,du_) and referenceEq(min,min_) and referenceEq(max,max_) and referenceEq(i,i_) and referenceEq(f,f_) and referenceEq(n,n_)
        and referenceEq(eqbound,eqbound_) and referenceEq(dist,dist_) then
        a = attr;
      else
        a = SOME(DAE.VAR_ATTR_REAL(q_,u_,du_,min_,max_,i_,f_,n_,ss,unc,dist_,eqbound_,p,fin,startOrigin));
     end if;
   then (a,outExtraArg);

   case(SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,dist,eqbound,p,fin,startOrigin)),_,_) equation
     (q_,outExtraArg) = Expression.traverseExpOpt(q,func,extraArg);
     (min_,outExtraArg) = Expression.traverseExpOpt(min,func,outExtraArg);
     (max_,outExtraArg) = Expression.traverseExpOpt(max,func,outExtraArg);
     (i_,outExtraArg) = Expression.traverseExpOpt(i,func,outExtraArg);
     (f_,outExtraArg) = Expression.traverseExpOpt(f,func,outExtraArg);
     (eqbound_,outExtraArg) = Expression.traverseExpOpt(eqbound,func,outExtraArg);
     (dist_,outExtraArg) = traverseBackendDAEAttrDistribution(dist,func,outExtraArg);
     if referenceEq(q,q_) and referenceEq(min,min_) and referenceEq(max,max_) and referenceEq(i,i_) and referenceEq(f,f_)
        and referenceEq(eqbound,eqbound_) and referenceEq(dist,dist_) then
        a = attr;
      else
        a = SOME(DAE.VAR_ATTR_INT(q_,min_,max_,i_,f_,unc,dist_,eqbound_,p,fin,startOrigin));
     end if;
   then (a,outExtraArg);

   case(SOME(DAE.VAR_ATTR_BOOL(q,i,f,eqbound,p,fin,startOrigin)),_,_) equation
     (q_,outExtraArg) = Expression.traverseExpOpt(q,func,extraArg);
     (i_,outExtraArg) = Expression.traverseExpOpt(i,func,outExtraArg);
     (f_,outExtraArg) = Expression.traverseExpOpt(f,func,outExtraArg);
     (eqbound_,outExtraArg) = Expression.traverseExpOpt(eqbound,func,outExtraArg);
     if referenceEq(q,q_) and referenceEq(i,i_) and referenceEq(f,f_) and referenceEq(eqbound,eqbound_) then
        a = attr;
      else
        a = SOME(DAE.VAR_ATTR_BOOL(q_,i_,f_,eqbound_,p,fin,startOrigin));
     end if;
   then (a,outExtraArg);

   case(SOME(DAE.VAR_ATTR_STRING(q,i,f,eqbound,p,fin,startOrigin)),_,_) equation
     (q_,outExtraArg) = Expression.traverseExpOpt(q,func,extraArg);
     (i_,outExtraArg) = Expression.traverseExpOpt(i,func,outExtraArg);
     (f_,outExtraArg) = Expression.traverseExpOpt(f,func,outExtraArg);
     (eqbound_,outExtraArg) = Expression.traverseExpOpt(eqbound,func,outExtraArg);
     if referenceEq(q,q_) and referenceEq(i,i_) and referenceEq(f,f_) and referenceEq(eqbound,eqbound_) then
        a = attr;
      else
        a = SOME(DAE.VAR_ATTR_STRING(q_,i_,f_,eqbound_,p,fin,startOrigin));
     end if;
   then (a,outExtraArg);

   case(SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,i,f,eqbound,p,fin,startOrigin)),_,_) equation
     (q_,outExtraArg) = Expression.traverseExpOpt(q,func,extraArg);
     (min_,outExtraArg) = Expression.traverseExpOpt(min,func,outExtraArg);
     (max_,outExtraArg) = Expression.traverseExpOpt(max,func,outExtraArg);
     (i_,outExtraArg) = Expression.traverseExpOpt(i,func,outExtraArg);
     (f_,outExtraArg) = Expression.traverseExpOpt(f,func,outExtraArg);
     (eqbound_,outExtraArg) = Expression.traverseExpOpt(eqbound,func,outExtraArg);
     if referenceEq(q,q_) and referenceEq(min,min_) and referenceEq(max,max_) and referenceEq(i,i_) and referenceEq(f,f_) and referenceEq(eqbound,eqbound_) then
        a = attr;
      else
        a = SOME(DAE.VAR_ATTR_ENUMERATION(q_,min_,max_,i_,f_,eqbound_,p,fin,startOrigin));
     end if;
    then (a,outExtraArg);
  case(SOME(DAE.VAR_ATTR_CLOCK(_, _)),_,_)
    then (attr,extraArg);

 end match;
end traverseBackendDAEVarAttr;

protected function traverseBackendDAEAttrDistribution
"help function to traverseBackendDAEVarAttr
author: Peter Aronsson (paronsson@wolfram.com)
"
  input Option<DAE.Distribution> distOpt;
  input FuncExpType func;
  input Type_a extraArg;
  replaceable type Type_a subtypeof Any;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  output Option<DAE.Distribution> outDistOpt;
  output Type_a outExtraArg;
algorithm
 (outDistOpt,outExtraArg) := match(distOpt,func,extraArg)
 local
   DAE.Exp name,arr,sarr;
   DAE.Exp name_,arr_,sarr_;
   Option<DAE.Distribution> d;

   case(NONE(),_,outExtraArg) then (NONE(),outExtraArg);

   case(SOME(DAE.DISTRIBUTION(name,arr,sarr)),_,_) equation
     (arr_,_) = Expression.extendArrExp(arr,false);
     (sarr_,_) = Expression.extendArrExp(sarr,false);
     (name_,outExtraArg) = Expression.traverseExpBottomUp(name,func,extraArg);
     (arr_,outExtraArg) = Expression.traverseExpBottomUp(arr_,func,outExtraArg);
     (sarr_,outExtraArg) = Expression.traverseExpBottomUp(sarr_,func,outExtraArg);
     if referenceEq(name, name_) and referenceEq(arr, arr_) and referenceEq(sarr, sarr_) then
       d = distOpt;
     else
       d = SOME(DAE.DISTRIBUTION(name_,arr_,sarr_));
     end if;
    then (d,outExtraArg);
 end match;
end traverseBackendDAEAttrDistribution;

public function traverseBackendDAEExpsEqns<T> "author: lochel
  Traverse all expressions of an equation array and apply modifications to them."
  input BackendDAE.EquationArray equationArray;
  input FuncExpType func;
  input output T extraArg;

  partial function FuncExpType
    input output DAE.Exp exp;
    input output T extraArg;
  end FuncExpType;
protected
  String name;
  BackendDAE.Equation eqn, eqn_new;
algorithm
  try
    for i in 1:ExpandableArray.getLastUsedIndex(equationArray) loop
      if ExpandableArray.occupied(i, equationArray) then
        eqn := ExpandableArray.get(i, equationArray);
        (eqn_new, extraArg) := BackendEquation.traverseExpsOfEquation(eqn, func, extraArg);
        if not referenceEq(eqn, eqn_new) then
          ExpandableArray.update(i, eqn_new, equationArray);
        end if;
      end if;
    end for;
  else
    if Flags.isSet(Flags.FAILTRACE) then
      (_, _, name) := System.dladdr(func);
      Debug.trace("- BackendDAE.traverseBackendDAEExpsEqns failed for " + name + "\n");
    end if;
    fail();
  end try;
end traverseBackendDAEExpsEqns;

public function traverseBackendDAEExpsEqnsWithStop<T> "author: lochel"
  input BackendDAE.EquationArray equationArray;
  input FuncExpType func;
  input output T extraArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input T inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output T outA;
  end FuncExpType;
protected
  String name;
  BackendDAE.Equation e, new_e;
  Boolean continue_;
algorithm
  try
    for i in 1:ExpandableArray.getLastUsedIndex(equationArray) loop
      if ExpandableArray.occupied(i, equationArray) then
        e := ExpandableArray.get(i, equationArray);
        (continue_, extraArg) := BackendEquation.traverseExpsOfEquation_WithStop(e, func, extraArg);
        if not continue_ then
          break;
        end if;
      end if;
    end for;
  else
    if Flags.isSet(Flags.FAILTRACE) then
      (_, _, name) := System.dladdr(func);
      Error.addInternalError("BackendDAEUtil.traverseBackendDAEExpsEqnsWithStop failed for " + name, sourceInfo());
    end if;
    fail();
  end try;
end traverseBackendDAEExpsEqnsWithStop;

public function traverseBackendDAEExpsOptEqn "author: Frenkel TUD 2010-11
  Helper for traverseExpsOfEquation."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (_,outTypeA) := traverseBackendDAEExpsOptEqnWithUpdate(inEquation,func,inTypeA);
end traverseBackendDAEExpsOptEqn;

protected function traverseBackendDAEExpsOptEqnWithUpdate "author: Frenkel TUD 2010-11
  Helper for traverseExpsOfEquation."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Option<BackendDAE.Equation> outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (outEquation,outTypeA) := match (inEquation,func,inTypeA)
    local
      BackendDAE.Equation eqn1,eqn2;
     Type_a ext_arg_1;
    case (SOME(eqn1),_,_)
      equation
        (eqn2,ext_arg_1) = BackendEquation.traverseExpsOfEquation(eqn1,func,inTypeA);
      then
        (if referenceEq(eqn1,eqn2) then inEquation else SOME(eqn2),ext_arg_1);
    else (NONE(),inTypeA);
  end match;
end traverseBackendDAEExpsOptEqnWithUpdate;

public function traverseAlgorithmExpsWithUpdate "
  This function goes through the Algorithm structure and finds all the
  expressions and performs the function on them
"
  replaceable type Type_a subtypeof Any;
  input DAE.Algorithm inAlgorithm;
  input FuncExpType func;
  input Type_a inTypeA;
  output DAE.Algorithm outAlgorithm;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (outAlgorithm,outTypeA) := match (inAlgorithm,func,inTypeA)
    local
      list<DAE.Statement> stmts,stmts1;
      Type_a ext_arg_1;
      DAE.Algorithm alg;
    case (DAE.ALGORITHM_STMTS(statementLst = stmts),_,_)
      equation
        (stmts1,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts,func,inTypeA);
        alg = if referenceEq(stmts,stmts1) then inAlgorithm else DAE.ALGORITHM_STMTS(stmts1);
      then
        (alg,ext_arg_1);
  end match;
end traverseAlgorithmExpsWithUpdate;

protected function traverseZeroCrossingExps
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.ZeroCrossing> iZeroCrossing;
  input FuncExpType func;
  input Type_a inTypeA;
  input list<BackendDAE.ZeroCrossing> iAcc={};
  output list<BackendDAE.ZeroCrossing> oZeroCrossing;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (oZeroCrossing,outTypeA) := match(iZeroCrossing,func,inTypeA,iAcc)
    local
      list<BackendDAE.ZeroCrossing> zeroCrossing;
      DAE.Exp relation1, relation2;
      list<Integer> occurEquLst;
      Type_a arg;
      BackendDAE.ZeroCrossing zc;
    case({},_,_,_) then (listReverse(iAcc),inTypeA);
    case((zc as BackendDAE.ZERO_CROSSING(relation1,occurEquLst))::zeroCrossing,_,_,_)
      equation
        (relation2,arg) = Expression.traverseExpBottomUp(relation1,func,inTypeA);
        (zeroCrossing,arg) = traverseZeroCrossingExps(zeroCrossing,func,arg,(if referenceEq(relation1,relation2) then zc else BackendDAE.ZERO_CROSSING(relation2,occurEquLst))::iAcc);
      then
        (zeroCrossing,arg);
  end match;
end traverseZeroCrossingExps;

/*************************************************
 * Equation System Pipeline
 ************************************************/

public function getSolvedSystem "Run the equation system pipeline."
  input BackendDAE.BackendDAE inDAE;
  input String fileNamePrefix;
  input Option<list<String>> strPreOptModules = NONE();
  input Option<String> strmatchingAlgorithm = NONE();
  input Option<String> strdaeHandler = NONE();
  input Option<list<String>> strPostOptModules = NONE();
  output BackendDAE.BackendDAE outSimDAE;
  output BackendDAE.BackendDAE outInitDAE;
  output Option<BackendDAE.BackendDAE> outInitDAE_lambda0_option;
  output Option<BackendDAE.InlineData > outInlineData;
  output list<BackendDAE.Equation> outRemovedInitialEquationLst;
protected
  BackendDAE.BackendDAE dae, simDAE, outInitDAE_lambda0;
  list<tuple<BackendDAEFunc.optimizationModule, String>> preOptModules;
  list<tuple<BackendDAEFunc.optimizationModule, String>> postOptModules;
  tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEFunc.matchingAlgorithmFunc, String> matchingAlgorithm;
  BackendDAE.InlineData inlineData;
  BackendDAE.Variables globalKnownVars;
  Integer numCheckpoints;
  DAE.FunctionTree funcTree;
algorithm
  numCheckpoints:=ErrorExt.getNumCheckpoints();
  try
  StackOverflow.clearStacktraceMessages();
  preOptModules := getPreOptModules(strPreOptModules);
  postOptModules := getPostOptModules(strPostOptModules);
  matchingAlgorithm := getMatchingAlgorithm(strmatchingAlgorithm);
  daeHandler := getIndexReductionMethod(strdaeHandler);

  if Flags.isSet(Flags.DUMP_DAE_LOW) then
    BackendDump.dumpBackendDAE(inDAE, "dumpdaelow");
    if Flags.isSet(Flags.ADDITIONAL_GRAPHVIZ_DUMP) then
      BackendDump.graphvizIncidenceMatrix(inDAE, "dumpdaelow");
    end if;
  end if;

  // pre-optimization phase
  dae := preOptimizeDAE(inDAE, preOptModules);

  execStat("pre-optimization done (n="+String(daeSize(dae))+")");
  // transformation phase (matching and sorting using index reduction method)
  dae := causalizeDAE(dae, NONE(), matchingAlgorithm, daeHandler, true);
  execStat("matching and sorting (n="+String(daeSize(dae))+")");

  // synchronous features post-phase
  dae := SynchronousFeatures.synchronousFeatures(dae);
  if Flags.isSet(Flags.OPT_DAE_DUMP) then
    BackendDump.dumpBackendDAE(dae, "synchronousFeatures");
  end if;

  if Flags.isSet(Flags.GRAPHML) then
    BackendDump.dumpBipartiteGraphDAE(dae, fileNamePrefix);
  end if;

  if Flags.isSet(Flags.BLT_DUMP) then
    BackendDump.bltdump("bltdump", dae);
  end if;

  if Flags.isSet(Flags.EVAL_OUTPUT_ONLY) then
    // prepare the equations
    dae := BackendDAEOptimize.evaluateOutputsOnly(dae);
  end if;

  //generate Jacobian for StateSets for initial state selection
  dae := SymbolicJacobian.calculateStateSetsJacobians(dae);

  // generate system for initialization
  (outInitDAE, outInitDAE_lambda0_option, outRemovedInitialEquationLst, globalKnownVars) := Initialization.solveInitialSystem(dae);
  if Flags.isSet(Flags.WARN_NO_NOMINAL) then
    warnAboutIterationVariablesWithNoNominal(outInitDAE);
  end if;

  // use function tree from initDAE further for simDAE
  simDAE := BackendDAEUtil.setFunctionTree(dae, BackendDAEUtil.getFunctions(outInitDAE.shared));

  // Set updated globalKnownVars
  simDAE := setDAEGlobalKnownVars(simDAE, globalKnownVars);

  // add initial assignmnents to all algorithms
  simDAE := BackendDAEOptimize.addInitialStmtsToAlgorithms(simDAE, false);

  // remove homotopy and initial calls
  simDAE := Initialization.removeInitializationStuff(simDAE);

  // generate inline solver
  outInlineData := SymbolicImplicitSolver.symSolver(simDAE);

  // post-optimization phase
  simDAE := postOptimizeDAE(simDAE, postOptModules, matchingAlgorithm, daeHandler);
  if Flags.isSet(Flags.WARN_NO_NOMINAL) then
    warnAboutIterationVariablesWithNoNominal(simDAE);
  end if;

  // sort the globalKnownVars
  simDAE := sortGlobalKnownVarsInDAE(simDAE);
  execStat("sort global known variables");

  // remove unused functions
  funcTree := BackendDAEOptimize.copyRecordConstructorAndExternalObjConstructorDestructor(BackendDAEUtil.getFunctions(simDAE.shared));
  funcTree := BackendDAEOptimize.removeUnusedFunctions(outInitDAE.eqs, outInitDAE.shared, outRemovedInitialEquationLst, BackendDAEUtil.getFunctions(simDAE.shared), funcTree);
  if isSome(outInitDAE_lambda0_option) then
    SOME(outInitDAE_lambda0) := outInitDAE_lambda0_option;
    funcTree := BackendDAEOptimize.removeUnusedFunctions(outInitDAE_lambda0.eqs, simDAE.shared, {}, BackendDAEUtil.getFunctions(simDAE.shared), funcTree);
  end if;
  funcTree := BackendDAEOptimize.removeUnusedFunctions(simDAE.eqs, simDAE.shared, {}, BackendDAEUtil.getFunctions(simDAE.shared), funcTree);
  outSimDAE := BackendDAEUtil.setFunctionTree(simDAE, funcTree);
  execStat("remove unused functions");

  if Flags.isSet(Flags.DUMP_INDX_DAE) then
    BackendDump.dumpBackendDAE(outSimDAE, "dumpindxdae");
    if Flags.isSet(Flags.ADDITIONAL_GRAPHVIZ_DUMP) then
      BackendDump.graphvizBackendDAE(outSimDAE, "dumpindxdae");
    end if;
  end if;
  if Flags.isSet(Flags.DUMP_TRANSFORMED_MODELICA_MODEL) then
    BackendDump.dumpBackendDAEToModelica(outSimDAE, "dumpindxdae");
  end if;
  if Flags.isSet(Flags.DUMP_BACKENDDAE_INFO) or Flags.isSet(Flags.DUMP_STATESELECTION_INFO) or Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO) then
    BackendDump.dumpCompShort(outSimDAE);
  end if;
  if Flags.isSet(Flags.DUMP_EQNINORDER) then
    BackendDump.dumpEqnsSolved(outSimDAE, "indxdae: eqns in order");
  end if;
  if Flags.isSet(Flags.DUMP_LOOPS) then
    BackendDump.dumpLoops(outSimDAE);
  end if;
  checkBackendDAEWithErrorMsg(outSimDAE);
  return;
  else
  setGlobalRoot(Global.stackoverFlowIndex, NONE());
  ErrorExt.rollbackNumCheckpoints(ErrorExt.getNumCheckpoints()-numCheckpoints);
  Error.addInternalError("Stack overflow in "+getInstanceName()+"...\n"+stringDelimitList(StackOverflow.readableStacktraceMessages(), "\n"), sourceInfo());
  /* Do not fail or we can loop too much */
  StackOverflow.clearStacktraceMessages();
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
  fail();
end getSolvedSystem;

public function preOptimizeBackendDAE "
  This function runs the pre-optimization modules."
  input BackendDAE.BackendDAE inDAE;
  input Option<list<String>> strPreOptModules;
  output BackendDAE.BackendDAE outDAE;
protected
  list<tuple<BackendDAEFunc.optimizationModule, String>> preOptModules;
algorithm
  preOptModules := getPreOptModules(strPreOptModules);
  outDAE := preOptimizeDAE(inDAE, preOptModules);
end preOptimizeBackendDAE;

public function preOptimizeDAE "
  This function runs the pre-optimization modules."
  input BackendDAE.BackendDAE inDAE;
  input list<tuple<BackendDAEFunc.optimizationModule, String>> inPreOptModules;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  BackendDAEFunc.optimizationModule optModule;
  String moduleStr;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
algorithm
  execStat("prepare preOptimizeDAE");
  for preOptModule in inPreOptModules loop
    (optModule, moduleStr) := preOptModule;
    moduleStr := moduleStr + " (" + BackendDump.printBackendDAEType2String(inDAE.shared.backendDAEType) + ")";
    try
      BackendDAE.DAE(systs, shared) := optModule(outDAE);
      (systs, shared) := filterEmptySystems(systs, shared);
      outDAE := BackendDAE.DAE(systs, shared);
      execStat("preOpt " + moduleStr);
      if Flags.isSet(Flags.OPT_DAE_DUMP) then
        BackendDump.dumpBackendDAE(outDAE, "pre-optimization module " + moduleStr);
      end if;
    else
      execStat("preOpt " + moduleStr + " <failed>");
      Error.addCompilerError("pre-optimization module " + moduleStr + " failed.");
      fail();
    end try;
  end for;

  if Flags.isSet(Flags.OPT_DAE_DUMP) then
    print("pre-optimization done.\n");
  end if;
end preOptimizeDAE;

public function transformBackendDAE "
  Run the matching and index reduction algorithm"
  input BackendDAE.BackendDAE inDAE;
  input Option<BackendDAE.MatchingOptions> inMatchingOptions;
  input Option<String> strmatchingAlgorithm;
  input Option<String> strindexReductionMethod;
  output BackendDAE.BackendDAE outDAE;
protected
  tuple<BackendDAEFunc.matchingAlgorithmFunc,String> matchingAlgorithm;
  tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String> indexReductionMethod;
algorithm
  matchingAlgorithm := getMatchingAlgorithm(strmatchingAlgorithm);
  indexReductionMethod := getIndexReductionMethod(strindexReductionMethod);
  outDAE := causalizeDAE(inDAE,inMatchingOptions,matchingAlgorithm,indexReductionMethod,true);
end transformBackendDAE;

public function causalizeDAE "
  Run the matching Algorithm.
  In case of a DAE a DAE handler is used to reduce the index of the DAE."
  input BackendDAE.BackendDAE inDAE;
  input Option<BackendDAE.MatchingOptions> inMatchingOptions;
  input tuple<BackendDAEFunc.matchingAlgorithmFunc,String> matchingAlgorithm;
  input tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String> stateDeselection;
  input Boolean dolateinline;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
  list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> args;
  Boolean causalized;
algorithm
  BackendDAE.DAE(systs,shared) := inDAE;
  // reduce index
  (systs,shared,args,causalized) := mapCausalizeDAE(systs,shared,inMatchingOptions,matchingAlgorithm,stateDeselection,{},{},false);
  // do late inline
  outDAE := if dolateinline then BackendInline.lateInlineFunction(BackendDAE.DAE(systs,shared)) else BackendDAE.DAE(systs,shared);
    //print("The StructurallySingularSystemHandlerArgs\n");
    //List.map_0(args,BackendDump.SSSHandlerArgString);

  // do state selection
  if causalized then
    BackendDAE.DAE(systs,shared) := stateDeselectionDAE(outDAE, args, stateDeselection);
  end if;

  // sort assigned equations to blt form
  systs := mapSortEqnsDAE(systs, shared);
  outDAE := BackendDAE.DAE(systs, shared);
end causalizeDAE;

protected function mapCausalizeDAE "
  Run the matching Algorithm.
  In case of a DAE a DAE handler is used to reduce the index of the DAE."
  input list<BackendDAE.EqSystem> isysts;
  input BackendDAE.Shared ishared;
  input Option<BackendDAE.MatchingOptions> inMatchingOptions;
  input tuple<BackendDAEFunc.matchingAlgorithmFunc,String> matchingAlgorithm;
  input tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String> stateDeselection;
  input list<BackendDAE.EqSystem> acc;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> acc1;
  input Boolean iCausalized;
  output list<BackendDAE.EqSystem> osysts;
  output BackendDAE.Shared oshared;
  output list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> oargs;
  output Boolean oCausalized;
algorithm
  (osysts,oshared,oargs,oCausalized) := match (isysts,ishared,inMatchingOptions,matchingAlgorithm,stateDeselection,acc,acc1,iCausalized)
    local
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;
      Option<BackendDAE.StructurallySingularSystemHandlerArg> arg;
      list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> args;
      Boolean causalized;

    case ({},_,_,_,_,_,_,_)
    then (listReverse(acc),ishared,listReverse(acc1),iCausalized);

    case (syst::systs,_,_,_,_,_,_,_) equation
      (syst,shared,arg,causalized) = causalizeDAEWork(syst,ishared,inMatchingOptions,matchingAlgorithm,stateDeselection,iCausalized);
      (systs,shared,args,causalized) = mapCausalizeDAE(systs,shared,inMatchingOptions,matchingAlgorithm,stateDeselection,syst::acc,arg::acc1,causalized);
    then (systs,shared,args,causalized);
  end match;
end mapCausalizeDAE;

protected function causalizeDAEWork "
  Run the matching Algorithm.
  In case of an DAE an DAE-Handler is used to reduce
  the index of the dae."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Option<BackendDAE.MatchingOptions> inMatchingOptions;
  input tuple<BackendDAEFunc.matchingAlgorithmFunc,String> matchingAlgorithm;
  input tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String> stateDeselection;
  input Boolean iCausalized;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Option<BackendDAE.StructurallySingularSystemHandlerArg> oArg;
  output Boolean oCausalized;
algorithm
  (osyst,oshared,oArg,oCausalized) := matchcontinue (isyst,ishared,inMatchingOptions,matchingAlgorithm,stateDeselection,iCausalized)
    local
      String str,mAmethodstr,str1;
      BackendDAE.MatchingOptions match_opts;
      BackendDAEFunc.matchingAlgorithmFunc matchingAlgorithmfunc;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
      DAE.FunctionTree funcs;
      Integer nvars,neqns;

    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING()),_,_,_,_,_)
      then
        (isyst,ishared,NONE(),iCausalized);

    case (BackendDAE.EQSYSTEM(matching=BackendDAE.NO_MATCHING()),_,_,(matchingAlgorithmfunc,_),(sssHandler,_,_,_),_)
      equation
        //  print("SystemSize: " + intString(systemSize(isyst)) + "\n");
        funcs = getFunctions(ishared);
        (syst,_,_,mapEqnIncRow,mapIncRowEqn) = getIncidenceMatrixScalar(isyst,BackendDAE.SOLVABLE(), SOME(funcs));
        match_opts = Util.getOptionOrDefault(inMatchingOptions,(BackendDAE.INDEX_REDUCTION(), BackendDAE.EXACT()));
        arg = IndexReduction.getStructurallySingularSystemHandlerArg(syst,ishared,mapEqnIncRow,mapIncRowEqn);
        // check singular system
        nvars = BackendVariable.daenumVariables(syst);
        neqns = systemSize(syst);
        syst = Causalize.singularSystemCheck(nvars,neqns,syst,match_opts,matchingAlgorithm,arg,ishared);
        // execStat("transformDAE -> singularSystemCheck " + mAmethodstr);
        // match the system and reduce index if neccessary
        (syst,shared,arg) = matchingAlgorithmfunc(syst, ishared, false, match_opts, sssHandler, arg);
        // execStat("transformDAE -> matchingAlgorithm " + mAmethodstr + " index Reduction Method " + str1);
      then (syst,shared,SOME(arg),true);

    case (_,_,_,(_,mAmethodstr),(_,str1,_,_),_)
      equation
        str = "Transformation Module " + mAmethodstr + " index Reduction Method " + str1 + " failed!";
        if not isInitializationDAE(ishared) then
          Error.addMessage(Error.INTERNAL_ERROR, {str});
        end if;
      then
        fail();
  end matchcontinue;
end causalizeDAEWork;

protected function stateDeselectionDAE
  input BackendDAE.BackendDAE inDAE;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> args;
  input tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String> stateDeselection;
  output BackendDAE.BackendDAE outDAE;
protected
  String methodstr;
  BackendDAEFunc.stateDeselectionFunc sDfunc;
algorithm
  // do state selection
  (_, _, sDfunc, methodstr) := stateDeselection;
  outDAE := sDfunc(inDAE, args);
  //execStat("transformDAE -> state selection " + methodstr);
end stateDeselectionDAE;

protected function mapSortEqnsDAE "Run Tarjan's Algorithm."
  input list<BackendDAE.EqSystem> inSystem;
  input BackendDAE.Shared inShared;
  output list<BackendDAE.EqSystem> outSystem;
algorithm
  outSystem := list(match (syst)
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=_::_))) then syst;
    else sortEqnsDAEWork(syst, inShared);
  end match for syst in inSystem);
end mapSortEqnsDAE;

protected function sortEqnsDAEWork "Run Tarjans Algorithm."
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSystem;
protected
  BackendDAE.EqSystem syst;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  DAE.FunctionTree funcs;
algorithm
  try
    // sorting algorithm
    funcs := getFunctions(inShared);
    (syst, _, _, mapEqnIncRow, mapIncRowEqn) := getIncidenceMatrixScalar(inSystem, BackendDAE.NORMAL(), SOME(funcs));
    (outSystem, _) := BackendDAETransform.strongComponentsScalar(syst, inShared, mapEqnIncRow, mapIncRowEqn);
  else
    //BackendDump.dumpEqSystem(inSystem, "Transformation module sort components failed for following system:");
    Error.addInternalError("Transformation module sort components failed", sourceInfo());
    fail();
  end try;
end sortEqnsDAEWork;

function dumpStrongComponents
"dump the strongly connected components on a flag"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
algorithm
  if Flags.isSet(Flags.DUMP_SCC_GRAPHML) then return; end if;
  _ := match(isyst, ishared)
    local
      String fileName, fileNamePrefix;
      Integer seqNo;

    case (_, BackendDAE.SHARED(info = BackendDAE.EXTRA_INFO(fileNamePrefix=fileNamePrefix)))
      equation
        seqNo = System.tmpTickIndex(Global.backendDAE_fileSequence);
        fileName = fileNamePrefix + "_" + intString(seqNo) + "_Comps" + intString(systemSize(isyst)) + ".graphml";
        DumpGraphML.dumpSystem(isyst,ishared,NONE(),fileName,false);
      then ();

  end match;
end dumpStrongComponents;

public function postOptimizeDAE
  "Run the post-optimization modules."
  input BackendDAE.BackendDAE inDAE;
  input list<tuple<BackendDAEFunc.optimizationModule, String>> inPostOptModules;
  input tuple<BackendDAEFunc.matchingAlgorithmFunc, String> inMatchingAlgorithm;
  input tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> inDAEHandler;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  BackendDAEFunc.optimizationModule optModule;
  String moduleStr;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  constant Boolean debug = false;
algorithm
  execStat("prepare postOptimizeDAE");
  for postOptModule in inPostOptModules loop
    (optModule, moduleStr) := postOptModule;
    moduleStr := moduleStr + " (" + BackendDump.printBackendDAEType2String(inDAE.shared.backendDAEType) + ")";
    try
      BackendDAE.DAE(systs, shared) := optModule(outDAE);
      (systs, shared) := filterEmptySystems(systs, shared);
      outDAE := BackendDAE.DAE(systs, shared);
      if debug then execStat("postOpt " + moduleStr); end if;
      outDAE := causalizeDAE(outDAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), inMatchingAlgorithm, inDAEHandler, false);
      execStat("postOpt " + (if debug then "causalize " else "") + moduleStr);
      if Flags.isSet(Flags.OPT_DAE_DUMP) then
        BackendDump.dumpBackendDAE(outDAE, "post-optimization module " + moduleStr);
      end if;
    else
      execStat("<failed> postOpt " + moduleStr);
      Error.addCompilerError("post-optimization module " + moduleStr + " failed.");
      fail();
    end try;
  end for;

  if Flags.isSet(Flags.OPT_DAE_DUMP) then
    print("post-optimization done.\n");
  end if;
end postOptimizeDAE;

public function getSolvedSystemforJacobians "Run the equation system pipeline."
  input BackendDAE.BackendDAE inDAE;
  input list<String> strPreOptModules;
  input Option<String> strMatchingAlgorithm;
  input Option<String> strDAEHandler;
  input list<String> strPostOptModules;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.BackendDAE dae;
  list<tuple<BackendDAEFunc.optimizationModule, String>> preOptModules;
  list<tuple<BackendDAEFunc.optimizationModule, String>> postOptModules;
  tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEFunc.matchingAlgorithmFunc, String> matchingAlgorithm;
algorithm
  preOptModules := selectOptModules(strPreOptModules, {}, {}, allPreOptimizationModules());
  postOptModules := selectOptModules(strPostOptModules, {}, {}, allPostOptimizationModules());
  matchingAlgorithm := getMatchingAlgorithm(strMatchingAlgorithm);
  daeHandler := getIndexReductionMethod(strDAEHandler);

  //fcall2(Flags.DUMP_DAE_LOW, BackendDump.dumpBackendDAE, inDAE, "dumpdaelow");
  // pre optimisation phase
  dae := preOptimizeDAE(inDAE, preOptModules);

  // transformation phase (matching and sorting using a index reduction method
  dae := causalizeDAE(dae, NONE(), matchingAlgorithm, daeHandler, true);
  execStat("causalizeDAE (first run)");
  //fcall(Flags.DUMP_DAE_LOW, BackendDump.bltdump, ("bltdump", dae));

  // post-optimization phase
  outDAE := postOptimizeDAE(dae, postOptModules, matchingAlgorithm, daeHandler);

  //fcall2(Flags.DUMP_INDX_DAE, BackendDump.dumpBackendDAE, outDAE, "dumpindxdae");
  //bcall(Flags.isSet(Flags.DUMP_BACKENDDAE_INFO) or Flags.isSet(Flags.DUMP_STATESELECTION_INFO) or Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO), BackendDump.dumpCompShort, outDAE);
  //fcall2(Flags.DUMP_EQNINORDER, BackendDump.dumpEqnsSolved, outDAE, "system for jacobians");
end getSolvedSystemforJacobians;

public function sortGlobalKnownVarsInDAE "
author: ptaeuber
This function sorts the globalKnownVars"
  input output BackendDAE.BackendDAE backendDAE;
protected
  BackendDAE.Variables globalKnownVars, globalKnownVars_sorted;
  BackendDAE.EquationArray parameterEqns;
  BackendDAE.EqSystem paramSystem;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Var var;
  array<Integer> ass1, ass2;
  list<list<Integer>> comps;
  list<Integer> flatComps;
algorithm
  globalKnownVars := backendDAE.shared.globalKnownVars;
  parameterEqns := BackendEquation.emptyEqnsSized(BackendVariable.varsSize(globalKnownVars));
  parameterEqns := BackendVariable.traverseBackendDAEVars(globalKnownVars, createGlobalKnownVarsEquations, parameterEqns);

  paramSystem := BackendDAEUtil.createEqSystem(globalKnownVars, parameterEqns);
  (m, _) := BackendDAEUtil.incidenceMatrix(paramSystem, BackendDAE.NORMAL(), NONE());
  (ass1, ass2) := Matching.PerfectMatching(m);
  comps := Sorting.Tarjan(m, ass1);
  flatComps := list(Initialization.flattenParamComp(comp, globalKnownVars) for comp in comps);

  globalKnownVars_sorted := BackendVariable.emptyVars();
  for i in flatComps loop
      var := BackendVariable.getVarAt(globalKnownVars, i);
      globalKnownVars_sorted := BackendVariable.addVar(var, globalKnownVars_sorted);
  end for;

  backendDAE := setDAEGlobalKnownVars(backendDAE, globalKnownVars_sorted);
  ExecStat.execStat("sorting global known variables");
end sortGlobalKnownVarsInDAE;

protected function createGlobalKnownVarsEquations
  input output BackendDAE.Var var;
  input output BackendDAE.EquationArray parameterEqns;
protected
  DAE.Exp lhs, rhs;
  BackendDAE.Equation eqn;
algorithm
  lhs := BackendVariable.varExp(var);
  try
    rhs := BackendVariable.varBindExpStartValue(var);
  else
    rhs := DAE.RCONST(0.0);
  end try;
  eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
  parameterEqns := BackendEquation.add(eqn, parameterEqns);
end createGlobalKnownVarsEquations;


/*************************************************
 * index reduction method Selection
 ************************************************/

public function getIndexReductionMethodString
" function: getIndexReductionMethodString"
  output String strIndexReductionMethod;
algorithm
  strIndexReductionMethod := Config.getIndexReductionMethod();
end getIndexReductionMethodString;

public function getIndexReductionMethod
" function: getIndexReductionMethod"
  input Option<String> ostrIndexReductionMethod;
  output tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String> IndexReductionMethod;
protected
  list<tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String>> allIndexReductionMethods;
  String strIndexReductionMethod;
algorithm
 allIndexReductionMethods := {(IndexReduction.failIfIndexReduction, "none", IndexReduction.noStateDeselection, "none"),
                              (IndexReduction.pantelidesIndexReduction, "Pantelides", IndexReduction.noStateDeselection, "uode"),
                              (IndexReduction.pantelidesIndexReduction, "Pantelides", IndexReduction.dynamicStateSelection, "dynamicStateSelection"),
                              (IndexReduction.pantelidesIndexReduction, "Pantelides", IndexReduction.dynamicStateSelection, "dummyDerivatives")};
 strIndexReductionMethod := getIndexReductionMethodString();
 strIndexReductionMethod := Util.getOptionOrDefault(ostrIndexReductionMethod,strIndexReductionMethod);
 IndexReductionMethod := selectIndexReductionMethod(strIndexReductionMethod,allIndexReductionMethods);
end getIndexReductionMethod;

protected function selectIndexReductionMethod
" function: selectIndexReductionMethod"
  input String strIndexReductionMethod;
  input list<tuple<Type_a,String,Type_b,String>> inIndexReductionMethods;
  output tuple<Type_a,String,Type_b,String> outIndexReductionMethod;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outIndexReductionMethod:=
  matchcontinue (strIndexReductionMethod,inIndexReductionMethods)
    local
      String name,str;
      tuple<Type_a,String,Type_b,String> method;
      list<tuple<Type_a,String,Type_b,String>> methods;
    case (_,(method as (_,_,_,name))::_)
      guard
        stringEqual(strIndexReductionMethod,name)
      then
        method;
    case (_,_::methods)
      equation
        method = selectIndexReductionMethod(strIndexReductionMethod,methods);
      then
        method;
    else
      equation
        str = stringAppendList({"Selection of Index Reduction Method ",strIndexReductionMethod," failed."});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end selectIndexReductionMethod;

/*************************************************
 * matching Algorithm Selection
 ************************************************/

public function getMatchingAlgorithmString
" function: getMatchingAlgorithmString"
  output String strMatchingAlgorithm;
algorithm
  strMatchingAlgorithm := Config.getMatchingAlgorithm();
end getMatchingAlgorithmString;

public function getMatchingAlgorithm
" function: getIndexReductionMethod"
  input Option<String> ostrMatchingAlgorithm;
  output tuple<BackendDAEFunc.matchingAlgorithmFunc,String> matchingAlgorithm;
protected
  list<tuple<BackendDAEFunc.matchingAlgorithmFunc,String>> allMatchingAlgorithms;
  String strMatchingAlgorithm;
algorithm
 allMatchingAlgorithms := {(Matching.BFSB,"BFSB"),
                           (Matching.DFSB,"DFSB"),
                           (Matching.MC21A,"MC21A"),
                           (Matching.PF,"PF"),
                           (Matching.PFPlus,"PFPlus"),
                           (Matching.HK,"HK"),
                           (Matching.HKDW,"HKDW"),
                           (Matching.ABMP,"ABMP"),
                           (Matching.PR_FIFO_FAIR,"PR"),
                           (Matching.DFSBExternal,"DFSBExt"),
                           (Matching.BFSBExternal,"BFSBExt"),
                           (Matching.MC21AExternal,"MC21AExt"),
                           (Matching.PFExternal,"PFExt"),
                           (Matching.PFPlusExternal,"PFPlusExt"),
                           (Matching.HKExternal,"HKExt"),
                           (Matching.HKDWExternal,"HKDWExt"),
                           (Matching.ABMPExternal,"ABMPExt"),
                           (Matching.PR_FIFO_FAIRExternal,"PRExt"),
                           (Matching.BBMatching,"BB")};
 strMatchingAlgorithm := getMatchingAlgorithmString();
 strMatchingAlgorithm := Util.getOptionOrDefault(ostrMatchingAlgorithm,strMatchingAlgorithm);
 matchingAlgorithm := selectMatchingAlgorithm(strMatchingAlgorithm,allMatchingAlgorithms);
end getMatchingAlgorithm;

protected function selectMatchingAlgorithm
" function: selectMatchingAlgorithm"
  input String strMatchingAlgorithm;
  input list<tuple<Type_a,String>> inMatchingAlgorithms;
  output tuple<Type_a,String> outMatchingAlgorithm;
  replaceable type Type_a subtypeof Any;
algorithm
  outMatchingAlgorithm:=
  matchcontinue (strMatchingAlgorithm,inMatchingAlgorithms)
    local
      String name,str;
      tuple<Type_a,String> method;
      list<tuple<Type_a,String>> methods;
    case (_,(method as (_,name))::_)
      guard
        stringEqual(strMatchingAlgorithm,name)
      then
        method;
    case (_,_::methods)
      equation
        method = selectMatchingAlgorithm(strMatchingAlgorithm,methods);
      then
        method;
    else
      equation
        str = stringAppendList({"Selection of Matching Algorithm ",strMatchingAlgorithm," failed."});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end selectMatchingAlgorithm;


// =============================================================================
// Optimization module selection
//
// =============================================================================

public function allPreOptimizationModules
  "This list contains all back end pre-optimization modules."
  output list<tuple<BackendDAEFunc.optimizationModule, String>> allPreOptimizationModules = {
    (BackendDAEUtil.introduceOutputAliases, "introduceOutputAliases"),
    (Uncertainties.dataReconciliation, "dataReconciliation"),
    (UnitCheck.unitChecking, "unitChecking"),
    (DynamicOptimization.createDynamicOptimization,"createDynamicOptimization"),
    (BackendInline.normalInlineFunction, "normalInlineFunction"),
    (EvaluateParameter.evaluateParameters, "evaluateParameters"),
    (RemoveSimpleEquations.removeVerySimpleEquations, "removeVerySimpleEquations"),
    (BackendDAEOptimize.simplifyIfEquations, "simplifyIfEquations"),
    (BackendDAEOptimize.expandDerOperator, "expandDerOperator"),
    (BackendDAEOptimize.removeEqualFunctionCalls, "removeEqualFunctionCalls"),
    (BackendDAEOptimize.removeLocalKnownVars, "removeLocalKnownVars"),
    (CommonSubExpression.wrapFunctionCalls, "wrapFunctionCalls"),
    (SynchronousFeatures.clockPartitioning, "clockPartitioning"),
    (IndexReduction.findStateOrder, "findStateOrder"),
    (BackendDAEOptimize.introduceDerAlias, "introduceDerAlias"),
    (DynamicOptimization.inputDerivativesForDynOpt, "inputDerivativesForDynOpt"), // only for dyn. opt.
    (BackendDAEOptimize.replaceEdgeChange, "replaceEdgeChange"),
    (InlineArrayEquations.inlineArrayEqn, "inlineArrayEqn"),
    (BackendDAEOptimize.sortEqnsVars, "sortEqnsVars"),
    (RemoveSimpleEquations.removeSimpleEquations, "removeSimpleEquations"),
    (CommonSubExpression.commonSubExpressionReplacement, "comSubExp"),
    (ResolveLoops.resolveLoops, "resolveLoops"),
    (EvaluateFunctions.evalFunctions, "evalFunc"),
    (FindZeroCrossings.encapsulateWhenConditions, "encapsulateWhenConditions"),
    // TODO: move the following modules to the correct position
    (BackendDAEOptimize.removeProtectedParameters, "removeProtectedParameters"),
    (BackendDAEOptimize.removeUnusedParameter, "removeUnusedParameter"),
    (BackendDAEOptimize.removeUnusedVariables, "removeUnusedVariables"),
    (BackendDAEOptimize.residualForm, "residualForm"),
    (BackendDAEOptimize.simplifyAllExpressions, "simplifyAllExpressions"),
    (BackendDAEOptimize.simplifyInStream, "simplifyInStream"),
    (BackendDump.dumpDAE, "dumpDAE"),
    (XMLDump.dumpDAEXML, "dumpDAEXML"),
    // This should indeed be at the end
    (BackendDAETransform.collapseArrayExpressions, "collapseArrayExpressions")
  };
end allPreOptimizationModules;

public function allPostOptimizationModules
  "This list contains all back end sim-optimization modules."
  output list<tuple<BackendDAEFunc.optimizationModule, String>> allPostOptimizationModules = {
    (BackendInline.lateInlineFunction, "lateInlineFunction"),
    (DynamicOptimization.simplifyConstraints, "simplifyConstraints"),
    (CommonSubExpression.wrapFunctionCalls, "wrapFunctionCalls"),
    (CommonSubExpression.cseBinary, "cseBinary"),
    (BackendDAEOptimize.replaceDerCalls, "replaceDerCalls"),
    (OnRelaxation.relaxSystem, "relaxSystem"),
    (InlineArrayEquations.inlineArrayEqn, "inlineArrayEqn"),
    (SymbolicJacobian.constantLinearSystem, "constantLinearSystem"),
    (BackendDAEOptimize.simplifysemiLinear, "simplifysemiLinear"),
    (ResolveLoops.solveLinearSystem, "solveLinearSystem"),
    (BackendDAEOptimize.addedScaledVars_states, "addScaledVars_states"),
    (BackendDAEOptimize.addedScaledVars_inputs, "addScaledVars_inputs"),
    (RemoveSimpleEquations.removeSimpleEquations, "removeSimpleEquations"),
    (BackendDAEOptimize.inlineFunctionInLoops, "forceInlineFunctionInLoops"), // before simplifyComplexFunction
    (BackendDAEOptimize.simplifyComplexFunction, "simplifyComplexFunction"),
    (ExpressionSolve.solveSimpleEquations, "solveSimpleEquations"),
    (ResolveLoops.reshuffling_post, "reshufflePost"),
    (DynamicOptimization.reduceDynamicOptimization, "reduceDynamicOptimization"), // before tearing
    (Tearing.tearingSystem, "tearingSystem"),
    (BackendDAEOptimize.simplifyLoops, "simplifyLoops"),
    (Tearing.recursiveTearing, "recursiveTearing"),
    (HpcOmEqSystems.partitionLinearTornSystem, "partlintornsystem"),
    (BackendDAEOptimize.countOperations, "countOperations"),
    (SymbolicJacobian.inputDerivativesUsed, "inputDerivativesUsed"),
    (DynamicOptimization.removeLoops, "extendDynamicOptimization"),
    (BackendDAEOptimize.addTimeAsState, "addTimeAsState"),
    (SymbolicJacobian.calculateStrongComponentJacobians, "calculateStrongComponentJacobians"),
    (SymbolicJacobian.calculateStateSetsJacobians, "calculateStateSetsJacobians"),
    (SymbolicJacobian.symbolicJacobian, "symbolicJacobian"),
    (SymbolicJacobian.generateSymbolicSensitivities, "generateSymbolicSensitivities"),
    (SymbolicJacobian.generateSymbolicLinearizationPast, "generateSymbolicLinearization"),
    (BackendDAEOptimize.removeConstants, "removeConstants"),
    (BackendDAEOptimize.simplifyTimeIndepFuncCalls, "simplifyTimeIndepFuncCalls"),
    (BackendDAEOptimize.simplifyAllExpressions, "simplifyAllExpressions"),
    (BackendDAEOptimize.hets, "hets"),
    (FindZeroCrossings.findZeroCrossings, "findZeroCrossings"),
    // TODO: move the following modules to the correct position
    (BackendDump.dumpComponentsGraphStr, "dumpComponentsGraphStr"),
    (BackendDump.dumpDAE, "dumpDAE"),
    (XMLDump.dumpDAEXML, "dumpDAEXML"),
    // This should indeed be at the end
    (BackendDAETransform.collapseArrayExpressions, "collapseArrayExpressions"),
    // DAEmode modules
    (DAEMode.createDAEmodeBDAE, "createDAEmodeBDAE"),
    (SymbolicJacobian.detectSparsePatternDAE, "detectDAEmodeSparsePattern"),
    (BackendDAEUtil.setEvaluationStage, "setEvaluationStage")
  };
end allPostOptimizationModules;

protected function allInitOptimizationModules
  "This list contains all back end init-optimization modules."
  output list<tuple<BackendDAEFunc.optimizationModule, String>> allInitOptimizationModules = {
    (Initialization.replaceHomotopyWithSimplified, "replaceHomotopyWithSimplified"),
    (SymbolicJacobian.constantLinearSystem, "constantLinearSystem"),
    (BackendDAEOptimize.inlineHomotopy, "inlineHomotopy"),
    (BackendDAEOptimize.inlineFunctionInLoops, "forceInlineFunctionInLoops"), // before simplifyComplexFunction
    (BackendDAEOptimize.simplifyComplexFunction, "simplifyComplexFunction"),
    (CommonSubExpression.wrapFunctionCalls, "wrapFunctionCalls"),
    (DynamicOptimization.reduceDynamicOptimization, "reduceDynamicOptimization"), // before tearing
    (Tearing.tearingSystem, "tearingSystem"),
    (BackendDAEOptimize.simplifyLoops, "simplifyLoops"),
    (Tearing.recursiveTearing, "recursiveTearing"),
    (ExpressionSolve.solveSimpleEquations, "solveSimpleEquations"),
    (BackendDAEOptimize.generateHomotopyComponents, "generateHomotopyComponents"), // after tearing, after solveSimpleEquations, before calculateStrongComponentJacobians
    (SymbolicJacobian.calculateStrongComponentJacobians, "calculateStrongComponentJacobians"),
    (BackendDAEOptimize.simplifyAllExpressions, "simplifyAllExpressions"),
    (SymbolicJacobian.inputDerivativesUsed, "inputDerivativesUsed"),
    (DynamicOptimization.removeLoops, "extendDynamicOptimization"),
    // This should indeed be at the end
    (BackendDAETransform.collapseArrayExpressions, "collapseArrayExpressions")
  };
end allInitOptimizationModules;

public function getPreOptModulesString
  output list<String> strPreOptModules;
algorithm
  strPreOptModules := Config.getPreOptModules();
end getPreOptModulesString;

protected function deprecatedDebugFlag
  input Flags.DebugFlag inFlag;
  input list<String> inModuleList;
  input String inModule;
  input String inPhase;
  output list<String> outModuleList = inModuleList;
algorithm
  if Flags.isSet(inFlag) then
    outModuleList := inModule::inModuleList;
    Error.addCompilerWarning("Deprecated debug flag -d=" + Flags.debugFlagName(inFlag) + " detected. Use --" + inPhase + "=" + inModule + " instead.");
  end if;
end deprecatedDebugFlag;

protected function deprecatedConfigFlag
  input Flags.ConfigFlag inFlag;
  input list<String> inModuleList;
  input String inModule;
  input String inPhase;
  output list<String> outModuleList = inModuleList;
algorithm
  if Flags.getConfigBool(inFlag) then
    outModuleList := inModule::inModuleList;
    Error.addCompilerWarning("Deprecated flag --" + Flags.configFlagName(inFlag) + " detected. Use --" + inPhase + "=" + inModule + " instead.");
  end if;
end deprecatedConfigFlag;

public function getPreOptModules
  input Option<list<String>> inPreOptModules;
  output list<tuple<BackendDAEFunc.optimizationModule, String>> outPreOptModules;
protected
  list<String> preOptModules;
  list<String> enabledModules = Flags.getConfigStringList(Flags.PRE_OPT_MODULES_ADD);
  list<String> disabledModules = Flags.getConfigStringList(Flags.PRE_OPT_MODULES_SUB);
algorithm
  preOptModules := getPreOptModulesString();
  preOptModules := Util.getOptionOrDefault(inPreOptModules, preOptModules);

  if isSome(getGlobalRoot(Global.isInStream)) then
    enabledModules := "simplifyInStream"::enabledModules;
  end if;

  if Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) then
    // handle special flags, which enable modules
    enabledModules := deprecatedDebugFlag(Flags.SORT_EQNS_AND_VARS, enabledModules, "sortEqnsVars", "preOptModules+");
    enabledModules := deprecatedDebugFlag(Flags.ADD_DER_ALIASES, enabledModules, "introduceDerAlias", "preOptModules+");

    if Config.acceptOptimicaGrammar() or Flags.getConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM) then
      enabledModules := "inputDerivativesForDynOpt"::enabledModules;
      enabledModules := "createDynamicOptimization"::enabledModules;
    end if;

    // handle special flags, which disable modules
    disabledModules := deprecatedDebugFlag(Flags.NO_PARTITIONING, disabledModules, "clockPartitioning", "preOptModules-");
    disabledModules := deprecatedDebugFlag(Flags.DISABLE_COMSUBEXP, disabledModules, "comSubExp", "preOptModules-");

    if Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS) == "causal" or
       Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS) == "none" then
      disabledModules := "removeSimpleEquations"::disabledModules;
    end if;

    if not Flags.isSet(Flags.EVALUATE_CONST_FUNCTIONS) then
      disabledModules := "evalFunc"::disabledModules;
      Error.addCompilerWarning("Deprecated debug flag --d=evalConstFuncs=false detected. Use --preOptModules-=evalFunc instead.");
    end if;

    if not Flags.isSet(Flags.NF_SCALARIZE) then
      disabledModules := "inlineArrayEqn"::disabledModules;
    end if;
  end if;

  if not Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) and not listEmpty(enabledModules) then
    Error.addCompilerError("It's not possible to combine following flags: --preOptModules+=... and --" + Flags.configFlagName(Flags.DEFAULT_OPT_MODULES_ORDERING) + "=false");
    fail();
  end if;

  if not Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) and not listEmpty(disabledModules) then
    Error.addCompilerError("It's not possible to combine following flags: --postOptModules-=... and --" + Flags.configFlagName(Flags.DEFAULT_OPT_MODULES_ORDERING) + "=false");
    fail();
  end if;

  outPreOptModules := selectOptModules(preOptModules, enabledModules, disabledModules, allPreOptimizationModules());
end getPreOptModules;

public function getPostOptModulesString
  output list<String> strpostOptModules;
algorithm
  strpostOptModules := Config.getPostOptModules();
end getPostOptModulesString;

public function getPostOptModules
  input Option<list<String>> inPostOptModules;
  output list<tuple<BackendDAEFunc.optimizationModule, String>> outPostOptModules;
protected
  list<String> postOptModules;
  list<String> enabledModules = Flags.getConfigStringList(Flags.POST_OPT_MODULES_ADD);
  list<String> disabledModules = Flags.getConfigStringList(Flags.POST_OPT_MODULES_SUB);
algorithm
  postOptModules := getPostOptModulesString();
  postOptModules := Util.getOptionOrDefault(inPostOptModules, postOptModules);

  if Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) then
    // handle special flags, which enable modules
    if Flags.getConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM) then
      enabledModules := "simplifyConstraints"::enabledModules;
    end if;

    enabledModules := deprecatedDebugFlag(Flags.REDUCE_DYN_OPT, enabledModules, "reduceDynamicOptimization", "postOptModules+");

    if not Flags.getConfigString(Flags.LOOP2CON) == "none" then
      enabledModules := "extendDynamicOptimization"::enabledModules;
    end if;

    enabledModules := deprecatedConfigFlag(Flags.CSE_BINARY, enabledModules, "cseBinary", "postOptModules+");
    enabledModules := deprecatedConfigFlag(Flags.CSE_CALL, enabledModules, "wrapFunctionCalls", "postOptModules+");
    enabledModules := deprecatedConfigFlag(Flags.CSE_EACHCALL, enabledModules, "wrapFunctionCalls", "postOptModules+");
    enabledModules := deprecatedDebugFlag(Flags.ON_RELAXATION, enabledModules, "relaxSystem", "postOptModules+");

    if Flags.getConfigBool(Flags.DISABLE_LINEAR_TEARING) then
      Flags.setConfigInt(Flags.MAX_SIZE_LINEAR_TEARING, 0);
      Error.addCompilerWarning("Deprecated flag --disableLinearTearing detected. Use --maxSizeLinearTearing=0 instead.");
    end if;

    if Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION)  or  Config.acceptOptimicaGrammar() or Flags.getConfigBool(Flags.GENERATE_DYN_OPTIMIZATION_PROBLEM) then
      enabledModules := "generateSymbolicLinearization"::enabledModules;
    end if;

    enabledModules := deprecatedDebugFlag(Flags.ADD_SCALED_VARS, enabledModules, "addScaledVars_states", "postOptModules+");
    enabledModules := deprecatedDebugFlag(Flags.ADD_SCALED_VARS_INPUT, enabledModules, "addScaledVars_inputs", "postOptModules+");

    if Flags.getConfigInt(Flags.SIMPLIFY_LOOPS) > 0 then
      enabledModules := "simplifyLoops"::enabledModules;
    end if;

    if Flags.getConfigString(Flags.HETS) <> "none" then
      enabledModules := "hets"::enabledModules;
    end if;


    if Flags.isSet(Flags.COUNT_OPERATIONS) then
      enabledModules := "countOperations"::enabledModules;
    end if;

    enabledModules := deprecatedConfigFlag(Flags.ADD_TIME_AS_STATE, enabledModules, "addTimeAsState", "postOptModules+");

    if 1 < Flags.getConfigInt(Flags.MAX_SIZE_FOR_SOLVE_LINIEAR_SYSTEM) then
      enabledModules := "solveLinearSystem"::enabledModules;
    end if;

    if Flags.isSet(Flags.RESHUFFLE_POST) then
      enabledModules := "reshufflePost"::enabledModules;
    end if;

    if Flags.getConfigInt(Flags.RTEARING) > 0 then
      enabledModules := "recursiveTearing"::enabledModules;
    end if;

    if Flags.getConfigInt(Flags.PARTLINTORN) > 0 then
      enabledModules := "partlintornsystem"::enabledModules;
    end if;

    // handle special flags, which disable modules
    disabledModules := deprecatedDebugFlag(Flags.DIS_SIMP_FUN, disabledModules, "simplifyComplexFunction", "postOptModules-");

    if Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS) == "none" or
       Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS) == "fastAcausal" or
       Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS) == "allAcausal" then
      disabledModules := "removeSimpleEquations"::disabledModules;
    end if;

    if Config.getTearingMethod() == "noTearing" then
      disabledModules := "tearingSystem"::disabledModules;
    end if;

    if not Flags.isSet(Flags.NF_SCALARIZE) then
      disabledModules := "inlineArrayEqn"::disabledModules;
    end if;
  end if;

  if not Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) and not listEmpty(enabledModules) then
    Error.addCompilerError("It's not possible to combine following flags: --postOptModules+=... and --" + Flags.configFlagName(Flags.DEFAULT_OPT_MODULES_ORDERING) + "=false");
    fail();
  end if;

  if not Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) and not listEmpty(disabledModules) then
    Error.addCompilerError("It's not possible to combine following flags: --postOptModules-=... and --" + Flags.configFlagName(Flags.DEFAULT_OPT_MODULES_ORDERING) + "=false");
    fail();
  end if;

  outPostOptModules := selectOptModules(postOptModules, enabledModules, disabledModules, allPostOptimizationModules());
end getPostOptModules;

public function getInitOptModules
  input Option<list<String>> inInitOptModules;
  input list<String> inEnabledModules = {};
  input list<String> inDisabledModules = {};
  output list<tuple<BackendDAEFunc.optimizationModule, String>> outInitOptModules;
protected
  list<String> initOptModules;
  list<String> enabledModules = Flags.getConfigStringList(Flags.INIT_OPT_MODULES_ADD);
  list<String> disabledModules = Flags.getConfigStringList(Flags.INIT_OPT_MODULES_SUB);
algorithm
  initOptModules := Config.getInitOptModules();
  initOptModules := Util.getOptionOrDefault(inInitOptModules, initOptModules);

  if Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) then
    // handle special flags, which enable modules
    if Flags.getConfigInt(Flags.SIMPLIFY_LOOPS) > 0 then
      enabledModules := "simplifyLoops"::enabledModules;
    end if;

    if Flags.getConfigInt(Flags.RTEARING) > 0 then
      enabledModules := "recursiveTearing"::enabledModules;
    end if;

    // handle special flags, which disable modules
    disabledModules := deprecatedDebugFlag(Flags.DIS_SIMP_FUN, disabledModules, "simplifyComplexFunction", "initOptModules-");

    if Config.getTearingMethod() == "noTearing" then
      disabledModules := "tearingSystem"::disabledModules;
    end if;
  end if;

  if not Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) and not listEmpty(enabledModules) then
    Error.addCompilerError("It's not possible to combine following flags: --initOptModules+=... and --" + Flags.configFlagName(Flags.DEFAULT_OPT_MODULES_ORDERING) + "=false");
    fail();
  end if;

  if not Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING) and not listEmpty(disabledModules) then
    Error.addCompilerError("It's not possible to combine following flags: --initOptModules-=... and --" + Flags.configFlagName(Flags.DEFAULT_OPT_MODULES_ORDERING) + "=false");
    fail();
  end if;

  outInitOptModules := selectOptModules(initOptModules, enabledModules, disabledModules, allInitOptimizationModules());
  initOptModules := List.map(outInitOptModules, Util.tuple22);
  outInitOptModules := selectOptModules(initOptModules, inEnabledModules, inDisabledModules, allInitOptimizationModules());
end getInitOptModules;

protected function selectOptModules
  input list<String> inStrOptModules;
  input list<String> inEnabledModules = {};
  input list<String> inDisabledModules = {};
  input list<tuple<BackendDAEFunc.optimizationModule, String>> inOptModules;
  output list<tuple<BackendDAEFunc.optimizationModule, String>> outOptModules = {};
protected
  Boolean forceOrdering = Flags.getConfigBool(Flags.DEFAULT_OPT_MODULES_ORDERING);
  String name;
  Integer numModules = listLength(inOptModules);
  array<Boolean> activeModules = arrayCreate(numModules, false);
  Integer index;
  Integer maxIndex = -1;
algorithm
  if forceOrdering then
    for name in inStrOptModules loop
      for index in getModuleIndexes(name, inOptModules) loop
        if index < maxIndex then
          Error.addCompilerWarning("Specified ordering will be ignored. Use --" + Flags.configFlagName(Flags.DEFAULT_OPT_MODULES_ORDERING) + "=false to override module ordering.");
          maxIndex := numModules;
        else
          maxIndex := intMax(maxIndex, index);
        end if;

        activeModules[index] := true;
      end for;
    end for;

    for name in inEnabledModules loop
      for index in getModuleIndexes(name, inOptModules) loop
        activeModules[index] := true;
      end for;
    end for;

    for name in inDisabledModules loop
      for index in getModuleIndexes(name, inOptModules) loop
        activeModules[index] := false;
      end for;
    end for;

    for i in 1:numModules loop
      if activeModules[i] then
        outOptModules := listGet(inOptModules, i)::outOptModules;
      end if;
    end for;
  else
    for name in inStrOptModules loop
      outOptModules := selectOptModules1(name, inOptModules)::outOptModules;
    end for;
  end if;
  outOptModules := listReverse(outOptModules);
end selectOptModules;

protected function getModuleIndexes
  input String inModuleName;
  input list<tuple<BackendDAEFunc.optimizationModule, String>> inModuleList;
  output list<Integer> outIndexes = {};
protected
  String name;
  Integer index=1;
algorithm
  for module in inModuleList loop
    (_, name) := module;
    if stringEqual(inModuleName, name) then
      outIndexes := index::outIndexes;
    end if;
    index := index+1;
  end for;
  if listEmpty(outIndexes) then
    Error.addCompilerError("'" + inModuleName + "' is not a valid optimization module. Please check the flags carefully.");
    fail();
  end if;
end getModuleIndexes;

protected function selectOptModules1
  input String strOptModule;
  input list<tuple<BackendDAEFunc.optimizationModule, String>> inOptModules;
  output tuple<BackendDAEFunc.optimizationModule, String> outOptModule;
algorithm
  outOptModule := match inOptModules
    local
      String name;
      tuple<BackendDAEFunc.optimizationModule, String> module;
      list<tuple<BackendDAEFunc.optimizationModule, String>> rest;

    case (module as (_, name))::_ guard(stringEqual(name, strOptModule))
    then module;

    case (_, name)::rest guard(not stringEqual(name, strOptModule))
    then selectOptModules1(strOptModule, rest);

    else equation
      Error.addInternalError("Selection of optimization module " + strOptModule + " failed.", sourceInfo());
    then fail();
  end match;
end selectOptModules1;

public function isInitOptModuleActivated " returns true if given initOptModule is activated
  author: ptaeuber"
  input String initOptModule;
  input list<tuple<BackendDAEFunc.optimizationModule, String>> activatedInitOptModules = {};
  output Boolean isActivated = false;
protected
  list<tuple<BackendDAEFunc.optimizationModule, String>> modules = activatedInitOptModules;
  String s;
algorithm
  if listEmpty(modules) then
    modules := getInitOptModules(NONE());
  end if;
  for module in modules loop
    (_, s) := module;
    if stringEqual(s, initOptModule) then
      isActivated := true;
      return;
    end if;
  end for;
end isInitOptModuleActivated;

/*************************************************
 * traverse BackendDAE equation systems
 ************************************************/

public function mapEqSystem1<A>
  "Helper to map a preopt module over each equation system"
  input BackendDAE.BackendDAE dae;
  input Function func;
  input A a;
  output BackendDAE.BackendDAE odae;

  partial function Function
    input BackendDAE.EqSystem syst;
    input A a;
    input BackendDAE.Shared shared;
    output BackendDAE.EqSystem osyst;
    output BackendDAE.Shared oshared;
  end Function;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := dae;
  (systs, shared) := List.map1Fold(systs, func, a, shared);
  // Filter out empty systems
  (systs, shared) := filterEmptySystems(systs, shared);
  odae := BackendDAE.DAE(systs, shared);
end mapEqSystem1;

public function mapEqSystemAndFold<B>
  "Helper to map a preopt module over each equation system"
  input BackendDAE.BackendDAE inDAE;
  input Function inFunc;
  input B initialExtra;
  output BackendDAE.BackendDAE outDAE;
  output B outExtra;

  partial function Function
    input BackendDAE.EqSystem inSyst;
    input BackendDAE.Shared inShared;
    input B inExtra;
    output BackendDAE.EqSystem outSyst;
    output BackendDAE.Shared outShared;
    output B outExtra;
  end Function;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  (systs, shared, outExtra) := List.mapFold2(systs, inFunc, shared, initialExtra);
  // Filter out empty systems
  (systs, shared) := filterEmptySystems(systs, shared);
  outDAE := BackendDAE.DAE(systs, shared);
end mapEqSystemAndFold;

public function foldEqSystem
  "Helper to map a preopt module over each equation system"
  input BackendDAE.BackendDAE dae;
  input Function func;
  input B initialExtra;
  output B extra;
  partial function Function
    input BackendDAE.EqSystem syst;
    input BackendDAE.Shared shared;
    input B fold;
    output B ofold;
  end Function;
  replaceable type B subtypeof Any;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := dae;
  extra := List.fold1(systs,func,shared,initialExtra);
  // Filter out empty systems
  (_, shared) := filterEmptySystems(systs, shared);
end foldEqSystem;

public function mapEqSystem
  "Helper to map a preopt module over each equation system"
  input BackendDAE.BackendDAE inDAE;
  input Function inFunc;
  output BackendDAE.BackendDAE outDAE;
  partial function Function
    input BackendDAE.EqSystem syst;
    input BackendDAE.Shared shared;
    output BackendDAE.EqSystem osyst;
    output BackendDAE.Shared oshared;
  end Function;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  (systs, shared) := List.mapFold(systs, inFunc, shared);
  // Filter out empty systems
  (systs, shared) := filterEmptySystems(systs, shared);
  outDAE := BackendDAE.DAE(systs, shared);
end mapEqSystem;

public function nonEmptySystem
  input BackendDAE.EqSystem syst;
  output Boolean nonEmpty;
algorithm
  nonEmpty := BackendVariable.varsSize(syst.orderedVars) <> 0 or BackendEquation.getNumberOfEquations(syst.removedEqs) <> 0;
end nonEmptySystem;

protected function filterEmptySystems
  "Filter out equation systems leaving at least one behind"
  input BackendDAE.EqSystems inSysts;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystems outSysts = {};
  output BackendDAE.Shared outShared = inShared;
protected
  list<BackendDAE.Equation> reqns = {};
algorithm
  for e in inSysts loop
    (reqns, outSysts) := filterEmptySystem(e, reqns, outSysts);
  end for;

  if listEmpty(outSysts) then
    outSysts := {BackendDAEUtil.createEqSystem(BackendVariable.emptyVars(), BackendEquation.emptyEqns())};
  else
    outSysts := Dangerous.listReverseInPlace(outSysts);
  end if;

  outShared.removedEqs := BackendEquation.addList(reqns, outShared.removedEqs);
end filterEmptySystems;

protected function filterEmptySystem
  input BackendDAE.EqSystem inSyst;
  input output list<BackendDAE.Equation> reqs;
  input output BackendDAE.EqSystems systs;
algorithm
  if BackendVariable.varsSize(inSyst.orderedVars) <> 0 or
     (isClockedSyst(inSyst) and BackendEquation.getNumberOfEquations(inSyst.removedEqs) <> 0) then
    systs := inSyst::systs;
  else
     reqs := listAppend(BackendEquation.equationList(inSyst.removedEqs), reqs);
  end if;
end filterEmptySystem;

public function getAllVarLst "retrieve all variables of the dae by collecting them from each equation system and combining with known vars"
  input BackendDAE.BackendDAE dae;
  output list<BackendDAE.Var> varLst;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Variables globalKnownVars;
algorithm
  BackendDAE.DAE(eqs=eqs,shared = BackendDAE.SHARED(globalKnownVars=globalKnownVars)) := dae;
  varLst := List.flatten(List.map(globalKnownVars::List.map(eqs, BackendVariable.daeVars), BackendVariable.varList));
end getAllVarLst;

public function isClockedSyst
  input BackendDAE.EqSystem inSyst;
  output Boolean out;
algorithm
  out := match inSyst
    case BackendDAE.EQSYSTEM(partitionKind=BackendDAE.CLOCKED_PARTITION()) then true;
    else false;
  end match;
end isClockedSyst;

public function getAlgorithms
  input BackendDAE.BackendDAE dae;
  output array<DAE.Algorithm> algs;
protected
  BackendDAE.EqSystems systs;
  list<DAE.Algorithm> alglst;
algorithm
  BackendDAE.DAE(eqs=systs) := dae;
  alglst := List.fold(systs,collectAlgorithmsFromEqSystem,{});
  algs := listArray(alglst);
end getAlgorithms;

protected function collectAlgorithmsFromEqSystem
  input BackendDAE.EqSystem syst;
  input list<DAE.Algorithm> alglst;
  output list<DAE.Algorithm> oalglst;
protected
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=eqns) := syst;
  oalglst := BackendEquation.traverseEquationArray(eqns,collectAlgorithms,alglst);
end collectAlgorithmsFromEqSystem;

protected function collectAlgorithms
  input BackendDAE.Equation inEq;
  input list<DAE.Algorithm> inAlgs;
  output BackendDAE.Equation outEq;
  output list<DAE.Algorithm> algs;
algorithm
  (outEq,algs) := match (inEq,inAlgs)
    local
      DAE.Algorithm alg;
    case (BackendDAE.ALGORITHM(alg=alg),algs)
      then (inEq,alg::algs);
    else (inEq,inAlgs);
  end match;
end collectAlgorithms;

// =============================================================================
// section for getConditionList
//
// =============================================================================

public function getConditionList "author: lochel
  This function extracts all when-conditions. A when-condition can only be a
  ComponentRef or initial()-call. If one condition is equal to >initial()<, the
  second output becomes true."
  input DAE.Exp inCondition;
  output list<DAE.ComponentRef> outConditionVarList;
  output Boolean outInitialCall;
algorithm
  (outConditionVarList, outInitialCall) := match (inCondition)
    local
      list<DAE.Exp> conditionList;
      list<DAE.ComponentRef> conditionVarList;
      Boolean initialCall;

    case DAE.ARRAY(array=conditionList)
      equation
        (conditionVarList, initialCall) = getConditionList1(conditionList, {}, false);
      then (conditionVarList, initialCall);

    else
      equation
        (conditionVarList, initialCall) = getConditionList1({inCondition}, {}, false);
      then (conditionVarList, initialCall);
  end match;
end getConditionList;

protected function getConditionList1 "author: lochel"
  input list<DAE.Exp> inConditionList;
  input list<DAE.ComponentRef> inConditionVarList;
  input Boolean inInitialCall;
  output list<DAE.ComponentRef> outConditionVarList;
  output Boolean outInitialCall;
algorithm
  (outConditionVarList, outInitialCall) := match inConditionList
    local
      list<DAE.Exp> conditionList;
      list<DAE.ComponentRef> conditionVarList;
      Boolean initialCall;
      DAE.ComponentRef componentRef;
      DAE.Exp exp;

    case {}
    then (inConditionVarList, inInitialCall);

    // filter constant conditions
    case exp::conditionList guard(Expression.isConst(exp)) equation
      (conditionVarList, initialCall) = getConditionList1(conditionList, inConditionVarList, inInitialCall);
    then (conditionVarList, initialCall);

    case DAE.CALL(path=Absyn.IDENT(name="initial"))::conditionList equation
      (conditionVarList, initialCall) = getConditionList1(conditionList, inConditionVarList, true);
    then (conditionVarList, initialCall);

    case DAE.CREF(componentRef=componentRef)::conditionList equation
      (conditionVarList, initialCall) = getConditionList1(conditionList, componentRef::inConditionVarList, inInitialCall);
    then (conditionVarList, initialCall);

    case exp::_ equation
      Error.addInternalError("function getConditionList1 failed for " + ExpressionDump.printExpStr(exp), sourceInfo());
    then fail();
  end match;
end getConditionList1;

public function isArrayComp"outputs true if the strongComponent is an arrayEquation"
  input BackendDAE.StrongComponent comp;
  output Boolean isArray;
algorithm
  isArray := match(comp)
    case(BackendDAE.SINGLEARRAY())
      then true;
  else false;
  end match;
end isArrayComp;

public function isWhenComp"outputs true if the strongComponent is a whenEquation"
  input BackendDAE.StrongComponent comp;
  output Boolean isWhen;
algorithm
  isWhen := match(comp)
    case(BackendDAE.SINGLEWHENEQUATION())
      then true;
  else false;
  end match;
end isWhenComp;

public function isSingleEquationComp "outputs true if the strongComponent is a singleEquation"
  input BackendDAE.StrongComponent comp;
  output Boolean isWhen;
algorithm
  isWhen := match(comp)
    case(BackendDAE.SINGLEEQUATION())
      then true;
  else false;
  end match;
end isSingleEquationComp;

public function isLinearEqSystemComp "outputs true if the strongComponent is a linear equationsystem"
  input BackendDAE.StrongComponent comp;
  output Boolean isWhen;
algorithm
  isWhen := match(comp)
    case(BackendDAE.EQUATIONSYSTEM(jacType = BackendDAE.JAC_LINEAR()))
      then true;
  else false;
  end match;
end isLinearEqSystemComp;

public function isNonLinearEqSystemComp "outputs true if the strongComponent is a nonlinear equationsystem"
  input BackendDAE.StrongComponent comp;
  output Boolean isWhen;
algorithm
  isWhen := match(comp)
    case(BackendDAE.EQUATIONSYSTEM(jacType = BackendDAE.JAC_NONLINEAR()))
      then true;
  else false;
  end match;
end isNonLinearEqSystemComp;

public function isLinearTornSystemComp "outputs true if the strongComponent is a linear torn system"
  input BackendDAE.StrongComponent comp;
  output Boolean isWhen;
algorithm
  isWhen := match(comp)
    case(BackendDAE.TORNSYSTEM(linear=true))
      then true;
  else false;
  end match;
end isLinearTornSystemComp;

public function isNonLinearTornSystemComp "outputs true if the strongComponent is a nonlinear torn system"
  input BackendDAE.StrongComponent comp;
  output Boolean isWhen;
algorithm
  isWhen := match(comp)
    case(BackendDAE.TORNSYSTEM(linear=false))
      then true;
  else false;
  end match;
end isNonLinearTornSystemComp;

public function extendRange
  input DAE.Exp inRangeExp;
  input BackendDAE.Variables inKnVariables;
  output list<DAE.Exp> outExpLst = {};
protected
  DAE.Exp start, step, stop;
  Option<DAE.Exp> ostep;
  DAE.Type ty;
algorithm
  try
    DAE.RANGE(ty = ty, start = start, step = ostep, stop = stop) := inRangeExp;

    start := evalExp(start, inKnVariables);
    stop := evalExp(stop, inKnVariables);

    if isSome(ostep) then
      SOME(step) := ostep;
      ostep := SOME(evalExp(step, inKnVariables));
    end if;

    outExpLst := Expression.expandRange(DAE.RANGE(ty, start, ostep, stop));
  else
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.trace("BackendDAECreate.extendRange failed. Maybe some ZeroCrossing are not supported\n");
    end if;
  end try;
end extendRange;

public function evalExp
  input DAE.Exp inExp;
  input BackendDAE.Variables inKnVariables;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      DAE.Exp e, e1, e2;

    case DAE.CREF()
      algorithm
        ((BackendDAE.VAR(bindExp = SOME(e)) :: _), _) :=
          BackendVariable.getVar(inExp.componentRef, inKnVariables);
      then
        e;

    case DAE.BINARY(operator = DAE.ADD(DAE.T_INTEGER()))
      algorithm
        e1 := evalExp(inExp.exp1, inKnVariables);
        e2 := evalExp(inExp.exp2, inKnVariables);
      then
        DAE.ICONST(Expression.expInt(e1) + Expression.expInt(e2));

    case DAE.BINARY(operator = DAE.SUB(DAE.T_INTEGER()))
      algorithm
        e1 := evalExp(inExp.exp1, inKnVariables);
        e2 := evalExp(inExp.exp2, inKnVariables);
      then
        DAE.ICONST(Expression.expInt(e1) - Expression.expInt(e2));

    else inExp;
  end match;
end evalExp;

public function expInt "returns the int value of an expression"
  input DAE.Exp inExp;
  input BackendDAE.Variables inKnVariables;
  output Integer i;
algorithm
  i := match(inExp)
    local
      Integer i1, i2;
      DAE.ComponentRef cr;
      DAE.Exp e, e1, e2;

    case DAE.ICONST(integer=i2)
    then i2;

    case DAE.ENUM_LITERAL(index=i2)
    then i2;

    case DAE.CREF(componentRef=cr) equation
      ((BackendDAE.VAR(bindExp=SOME(e)):: _), _) = BackendVariable.getVar(cr, inKnVariables);
      i2 = expInt(e, inKnVariables);
    then i2;

    case DAE.BINARY(exp1=e1, operator=DAE.ADD(DAE.T_INTEGER()), exp2=e2) equation
      i1 = expInt(e1, inKnVariables);
      i2 = expInt(e2, inKnVariables);
      i = i1 + i2;
    then i;

    case DAE.BINARY(exp1=e1, operator=DAE.SUB(DAE.T_INTEGER()), exp2=e2) equation
      i1 = expInt(e1, inKnVariables);
      i2 = expInt(e2, inKnVariables);
      i = i1 - i2;
    then i;
  end match;
end expInt;

public function createEqSystem
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs = BackendEquation.emptyEqns();
  input BackendDAE.StateSets inStateSets = {};
  input BackendDAE.BaseClockPartitionKind inPartitionKind = BackendDAE.UNKNOWN_PARTITION();
  input BackendDAE.EquationArray removedEqs = BackendEquation.emptyEqns();
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := BackendDAE.EQSYSTEM( inVars, inEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(),
                                  inStateSets, inPartitionKind, removedEqs );
end createEqSystem;

public function createEmptyShared
  input BackendDAE.BackendDAEType backendDAEType;
  input BackendDAE.ExtraInfo ei;
  input FCore.Cache cache;
  input FCore.Graph graph;
  output BackendDAE.Shared shared;
algorithm
  shared := BackendDAE.SHARED(BackendVariable.emptyVars(),
                              BackendVariable.emptyVars(),
                              BackendVariable.emptyVars(),
                              BackendVariable.emptyVars(),
                              BackendEquation.emptyEqns(),
                              BackendEquation.emptyEqns(),
                              {},
                              {},
                              cache,
                              graph,
                              DAE.AvlTreePathFunction.new(),
                              emptyEventInfo(),
                              {},
                              backendDAEType,
                              {},
                              ei,
                              emptyPartitionsInfo(),
                              BackendDAE.emptyDAEModeData,
                              NONE()
                              );
end createEmptyShared;

public function emptyPartitionsInfo
  output BackendDAE.PartitionsInfo partitionsInfo;
protected
  array<BackendDAE.BasePartition> basePartitions;
  array<BackendDAE.SubPartition> subPartitions;
algorithm
  basePartitions := arrayCreate(0, BackendDAE.BASE_PARTITION(DAE.INFERRED_CLOCK(), 0));
  subPartitions := arrayCreate(0, BackendDAE.SUB_PARTITION(BackendDAE.DEFAULT_SUBCLOCK, false, {}));
  partitionsInfo := BackendDAE.PARTITIONS_INFO(basePartitions, subPartitions);
end emptyPartitionsInfo;

public function makeSingleEquationComp
  input Integer eqIdx;
  input Integer varIdx;
  output BackendDAE.StrongComponent comp;
algorithm
  comp := BackendDAE.SINGLEEQUATION(eqIdx,varIdx);
end makeSingleEquationComp;

public function getAliasVars "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.Variables outAliasVars;
algorithm
  BackendDAE.DAE(shared=BackendDAE.SHARED(aliasVars=outAliasVars)) := inDAE;
end getAliasVars;

public function getGlobalKnownVarsFromDAE "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.Variables globalKnownVars;
algorithm
  BackendDAE.DAE(shared=BackendDAE.SHARED(globalKnownVars=globalKnownVars)) := inDAE;
end getGlobalKnownVarsFromDAE;


public function setVars
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.Variables inVars;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(syst::systs, shared) := inDAE;
  syst := setEqSystVars(syst, inVars);
  outDAE := BackendDAE.DAE(syst::systs, shared);
end setVars;

public function setEqs
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.EquationArray inEqs;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(syst::systs, shared) := inDAE;
  syst := setEqSystEqs(syst, inEqs);
  outDAE := BackendDAE.DAE(syst::systs, shared);
end setEqs;

public function setAliasVars "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.Variables inAliasVars;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  shared := setSharedAliasVars(shared, inAliasVars);
  outDAE := BackendDAE.DAE(systs, shared);
end setAliasVars;

public function setDAEGlobalKnownVars "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.Variables inGlobalKnownVars;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  shared := setSharedGlobalKnownVars(shared, inGlobalKnownVars);
  outDAE := BackendDAE.DAE(systs, shared);
end setDAEGlobalKnownVars;

public function setFunctionTree "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  shared := setSharedFunctionTree(shared, inFunctionTree);
  outDAE := BackendDAE.DAE(systs, shared);
end setFunctionTree;

public function setEqSystEqs
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.EquationArray inEqs;
  output BackendDAE.EqSystem syst = inSyst;
algorithm
  syst.orderedEqs := inEqs;
end setEqSystEqs;

public function setEqSystVars
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Variables inVars;
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := match inSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM()
      algorithm syst.orderedVars := inVars;
      then syst;
  end match;
end setEqSystVars;

public function setEqSystMatrices
  input BackendDAE.EqSystem inSyst;
  input Option<BackendDAE.IncidenceMatrix> m = NONE();
  input Option<BackendDAE.IncidenceMatrix> mT = NONE();
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := match inSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM()
      algorithm
        syst.m := m; syst.mT := mT;
      then syst;
  end match;
end setEqSystMatrices;

public function clearEqSyst
  input BackendDAE.EqSystem inSyst;
  output BackendDAE.EqSystem outSyst;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs, removedEqs;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM( orderedVars=vars, orderedEqs=eqs, stateSets=stateSets, partitionKind=partitionKind,
                       removedEqs=removedEqs ) := inSyst;
  outSyst := BackendDAE.EQSYSTEM( orderedVars=vars, orderedEqs=eqs, m=NONE(), mT=NONE(), removedEqs=removedEqs,
                                  matching=BackendDAE.NO_MATCHING(), stateSets=stateSets, partitionKind=partitionKind );
end clearEqSyst;

public function setEqSystMatching
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Matching matching;
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := match inSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM()
      algorithm syst.matching := matching;
      then syst;
  end match;
end setEqSystMatching;

public function setEqSystStateSets
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.StateSets stateSets;
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := match inSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM()
      algorithm syst.stateSets := stateSets;
      then syst;
  end match;
end setEqSystStateSets;

public function setEqSystRemovedEqns
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.EquationArray removedEqs;
  output BackendDAE.EqSystem outSyst = inSyst;
algorithm
  outSyst.removedEqs := removedEqs;
end setEqSystRemovedEqns;

public function setSharedRemovedEqns
  input BackendDAE.Shared inShared;
  input BackendDAE.EquationArray inRemovedEqs;
  output BackendDAE.Shared outShared;
algorithm
  outShared := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED() algorithm
      shared.removedEqs := inRemovedEqs;
    then shared;
  end match;
end setSharedRemovedEqns;

public function setSharedInitialEqns
  input BackendDAE.Shared inShared;
  input BackendDAE.EquationArray initialEqs;
  output BackendDAE.Shared outShared;
algorithm
  outShared := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED()
      algorithm shared.initialEqs := initialEqs;
      then shared;
  end match;
end setSharedInitialEqns;

public function setSharedSymJacs
  input BackendDAE.Shared inShared;
  input BackendDAE.SymbolicJacobians symjacs;
  output BackendDAE.Shared outShared;
algorithm
  outShared := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED()
      algorithm shared.symjacs := symjacs;
      then shared;
  end match;
end setSharedSymJacs;

public function getSharedSymJacs
  input BackendDAE.Shared inShared;
  output BackendDAE.SymbolicJacobians outSymjacs;
algorithm
  outSymjacs := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED() then shared.symjacs;
  end match;
end getSharedSymJacs;

public function setSharedFunctionTree
  input BackendDAE.Shared inShared;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.Shared outShared;
algorithm
  outShared := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED()
      algorithm shared.functionTree := inFunctionTree;
      then shared;
  end match;
end setSharedFunctionTree;

public function setSharedEventInfo
  input BackendDAE.Shared inShared;
  input BackendDAE.EventInfo eventInfo;
  output BackendDAE.Shared outShared = inShared;
algorithm
  outShared.eventInfo := eventInfo;
end setSharedEventInfo;

public function setSharedGlobalKnownVars
  input BackendDAE.Shared inShared;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.Shared outShared = inShared;
algorithm
  outShared.globalKnownVars := globalKnownVars;
end setSharedGlobalKnownVars;

public function setSharedAliasVars
  input BackendDAE.Shared inShared;
  input BackendDAE.Variables aliasVars;
  output BackendDAE.Shared outShared;
algorithm
  outShared := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED()
      algorithm shared.aliasVars := aliasVars;
      then shared;
  end match;
end setSharedAliasVars;

public function setSharedOptimica
  input BackendDAE.Shared inShared;
  input list<DAE.Constraint> constraints;
  input list<DAE.ClassAttributes> classAttrs;
  output BackendDAE.Shared outShared;
algorithm
  outShared := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED()
      equation
        shared.constraints = constraints;
        shared.classAttrs = classAttrs;
      then shared;
  end match;
end setSharedOptimica;

public function collapseOrderedEqs
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.EquationArray outEqns;
protected
  list<BackendDAE.Equation> eqsLst;
algorithm
  eqsLst := List.fold(inDAE.eqs, collapseRemovedEqs1, {});
  outEqns := BackendEquation.listEquation(listAppend(eqsLst, BackendEquation.equationList(inDAE.shared.removedEqs)));
end collapseOrderedEqs;

public function collapseRemovedEqs
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.EquationArray outEqns;
protected
  list<BackendDAE.Equation> eqsLst;
algorithm
  eqsLst := List.fold(inDAE.eqs, collapseRemovedEqs1, {});
  outEqns := BackendEquation.listEquation(listAppend(eqsLst, BackendEquation.equationList(inDAE.shared.removedEqs)));
end collapseRemovedEqs;

protected function collapseRemovedEqs1
  input BackendDAE.EqSystem inSyst;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := if BackendDAEUtil.isClockedSyst(inSyst) then inEqns
             else listAppend(BackendEquation.equationList(inSyst.removedEqs), inEqns);
end collapseRemovedEqs1;

public function emptyEventInfo
  output BackendDAE.EventInfo info;
algorithm
  info := BackendDAE.EVENT_INFO({}, ZeroCrossings.new(), DoubleEndedList.fromList({}), ZeroCrossings.new(), 0);
end emptyEventInfo;

public function getSubClock
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output Option<BackendDAE.SubClock> outSubClock;
algorithm
  outSubClock := match inSyst.partitionKind
    local
      Integer idx;
    case BackendDAE.CLOCKED_PARTITION(idx)
      then SOME(inShared.partitionsInfo.subPartitions[idx].clock);
    else NONE();
  end match;
end getSubClock;

public function componentsEqual"outputs true if 1 strongly connected components are equal"
  input BackendDAE.StrongComponent comp1;
  input BackendDAE.StrongComponent comp2;
  output Boolean isEqual;
algorithm
  isEqual := match(comp1,comp2)
    local
      Integer i1,i2, j1,j2;
      list<Integer> l1,l2,k1,k2;
      BackendDAE.InnerEquations l3,k3;
  case(BackendDAE.SINGLEEQUATION(eqn=i1,var=i2),BackendDAE.SINGLEEQUATION(eqn=j1,var=j2))
  then intEq(i1,j1) and intEq(i2,j2);

  case(BackendDAE.EQUATIONSYSTEM(eqns=l1,vars=l2),BackendDAE.EQUATIONSYSTEM(eqns=k1,vars=k2))
  then List.isEqualOnTrue(l1,k1,intEq) and List.isEqualOnTrue(l2,k2,intEq);

  case(BackendDAE.SINGLEARRAY(eqn=i1,vars=l1),BackendDAE.SINGLEARRAY(eqn=j1,vars=k1))
  then intEq(i1,j1) and List.isEqualOnTrue(l1,k1,intEq);

  case(BackendDAE.SINGLEALGORITHM(eqn=i1,vars=l1),BackendDAE.SINGLEALGORITHM(eqn=j1,vars=k1))
  then intEq(i1,j1) and List.isEqualOnTrue(l1,k1,intEq);

  case(BackendDAE.SINGLECOMPLEXEQUATION(eqn=i1,vars=l1),BackendDAE.SINGLECOMPLEXEQUATION(eqn=j1,vars=k1))
  then intEq(i1,j1) and List.isEqualOnTrue(l1,k1,intEq);

  case(BackendDAE.SINGLEWHENEQUATION(eqn=i1,vars=l1),BackendDAE.SINGLEWHENEQUATION(eqn=j1,vars=k1))
  then intEq(i1,j1) and List.isEqualOnTrue(l1,k1,intEq);

  case(BackendDAE.SINGLEIFEQUATION(eqn=i1,vars=l1),BackendDAE.SINGLEIFEQUATION(eqn=j1,vars=k1))
  then intEq(i1,j1) and List.isEqualOnTrue(l1,k1,intEq);

  case(BackendDAE.TORNSYSTEM(strictTearingSet=BackendDAE.TEARINGSET(tearingvars=l1,residualequations=l2,innerEquations=l3)),BackendDAE.TORNSYSTEM(strictTearingSet=BackendDAE.TEARINGSET(tearingvars=k1,residualequations=k2,innerEquations=k3)))
  then List.isEqualOnTrue(l1,k1,intEq) and List.isEqualOnTrue(l2,k2,intEq) and List.isEqualOnTrue(l3,k3,innerEquationsEqual);
  else false;
  end match;
end componentsEqual;

protected function innerEquationsEqual"compares 2 innerEquations from innerEquations in TearingSets"
  input BackendDAE.InnerEquation innerEquation1;
  input BackendDAE.InnerEquation innerEquation2;
  output Boolean isEqual;
algorithm
  isEqual := match(innerEquation1,innerEquation2)
    local
      Integer i1,i2;
      list<Integer> l1,l2;
    case(BackendDAE.INNEREQUATION(eqn=i1,vars=l1),BackendDAE.INNEREQUATION(eqn=i2,vars=l2))
     then intEq(i1,i2) and List.isEqualOnTrue(l1,l2,intEq);
    case(BackendDAE.INNEREQUATIONCONSTRAINTS(eqn=i1,vars=l1),BackendDAE.INNEREQUATIONCONSTRAINTS(eqn=i2,vars=l2))
     then intEq(i1,i2) and List.isEqualOnTrue(l1,l2,intEq);
    else
     false;
  end match;
end innerEquationsEqual;


public function causalizeVarBindSystem"causalizes a system of variables and their binding-equations.
author: waurich TUD 08.2015"
  input list<BackendDAE.Var> varLstIn;
  output list<list<Integer>> comps;
  output array<Integer> ass1;
  output array<Integer> ass2;
protected
  Integer nVars,nEqs;
  list<Integer> order;
  BackendDAE.IncidenceMatrix m,  mT;
  list<DAE.Exp> bindExps;
  list<BackendDAE.Equation> eqs;
algorithm
  bindExps := List.map(varLstIn,BackendVariable.varBindExp);
  eqs := List.threadMap2(List.map(varLstIn,BackendVariable.varExp), bindExps, BackendEquation.generateEquation, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
  (m, mT) := BackendDAEUtil.incidenceMatrixDispatch(BackendVariable.listVar1(varLstIn), BackendEquation.listEquation(eqs), BackendDAE.ABSOLUTE(), NONE());
  nVars := listLength(varLstIn);
  nEqs := listLength(eqs);
  ass1 := arrayCreate(nVars, -1);
  ass2 := arrayCreate(nEqs, -1);
  Matching.matchingExternalsetIncidenceMatrix(nVars, nEqs, m);
  BackendDAEEXT.matching(nVars, nEqs, 5, -1, 0.0, 1);
  BackendDAEEXT.getAssignment(ass2, ass1);
  comps := Sorting.TarjanTransposed(mT, ass2);
end causalizeVarBindSystem;

public function traverseEqSystemStrongComponents
"This function goes through the strong components of a EqSystem and pass
 the variables and equation with their indexes to the traversing function.
 It fail if the EqSytem does not have the matching and strong components are
 empty. It does not change the input EqSystem."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EqSystem syst;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA = inTypeA;
  partial function FuncExpType
    input list<BackendDAE.Equation> inEqns;
    input list<BackendDAE.Var> inVars;
    input list<Integer> varIdxs;
    input list<Integer> eqnIdxs;
    input Type_a inA;
    output Type_a outA;
  end FuncExpType;
protected
  BackendDAE.StrongComponents comps;
  BackendDAE.Variables varArr;
  BackendDAE.EquationArray eqnArr;
  list<BackendDAE.Var> vars;
  list<BackendDAE.Equation> eqns;
  list<Integer> varIdxs, eqnIdxs;
  String name;
algorithm
  try
    BackendDAE.EQSYSTEM(matching    = BackendDAE.MATCHING(comps=comps),
                        orderedVars = varArr,
                        orderedEqs  = eqnArr) := syst;

    for component in comps loop
      (vars, varIdxs, eqns, eqnIdxs) := getStrongComponentVarsAndEquations(component, varArr, eqnArr);
      outTypeA := func(eqns, vars, varIdxs, eqnIdxs, outTypeA);
    end for;
  else
    (_, _, name) := System.dladdr(func);
    Error.addInternalError("BackendDAEUtil.traverseEqSystemStrongComponents failed " +
                            "with function:\n" +  name + "\n", sourceInfo());
    fail();
  end try;
end traverseEqSystemStrongComponents;

public function getStrongComponentsVarsAndEquations"gets the variables and and the equations from all sccs.
author: Waurich TUD 09-2015"
  input BackendDAE.StrongComponents comps;
  input BackendDAE.Variables varArr;
  input BackendDAE.EquationArray eqArr;
  output list<BackendDAE.Var> varsOut = {};
  output list<Integer> varIdxsOut = {};
  output list<BackendDAE.Equation> eqsOut = {};
  output list<Integer> eqIdxsOut = {};
protected
  BackendDAE.StrongComponent comp;
  list<BackendDAE.Equation> eqs;
  list<BackendDAE.Var> vars;
  list<Integer> vIdxs,eIdxs;
algorithm
  for comp in comps loop
    (vars,vIdxs,eqs,eIdxs) := BackendDAEUtil.getStrongComponentVarsAndEquations(comp, varArr, eqArr);
    varsOut := listAppend(vars,varsOut);
    varIdxsOut := listAppend(vIdxs,varIdxsOut);
    eqsOut := listAppend(eqs,eqsOut);
    eqIdxsOut := listAppend(eIdxs,eqIdxsOut);
  end for;
  varsOut := listReverse(varsOut);
  varIdxsOut := listReverse(varIdxsOut);
  eqsOut := listReverse(eqsOut);
  eqIdxsOut := listReverse(eqIdxsOut);
end getStrongComponentsVarsAndEquations;

public function getStrongComponentVarsAndEquations"gets the variables and and the equations from the scc.
author: Waurich TUD 09-2015"
  input BackendDAE.StrongComponent comp;
  input BackendDAE.Variables varArr;
  input BackendDAE.EquationArray eqArr;
  output list<BackendDAE.Var> varsOut;
  output list<Integer> varIdxs;
  output list<BackendDAE.Equation> eqsOut;
  output list<Integer> eqIdcxs;
algorithm
  (varsOut,varIdxs,eqsOut,eqIdcxs) := match(comp,varArr,eqArr)
    local
      Integer vidx,eidx;
      list<Integer> vidxs,eidxs, otherEqns, otherVars;
      list<list<Integer>> otherVarsLst;
      BackendDAE.Equation eq;
      BackendDAE.Var var;
      list<BackendDAE.Equation> eqs;
      list<BackendDAE.Var> vars;
      BackendDAE.InnerEquations innerEquations;
  case(BackendDAE.SINGLEEQUATION(eqn=eidx,var=vidx),_,_)
    equation
      var = BackendVariable.getVarAt(varArr,vidx);
      eq = BackendEquation.get(eqArr,eidx);
    then ({var},{vidx},{eq},{eidx});
  case(BackendDAE.EQUATIONSYSTEM(eqns=eidxs,vars=vidxs),_,_)
    equation
      vars = List.map1(vidxs,BackendVariable.getVarAtIndexFirst,varArr);
      eqs = BackendEquation.getList(eidxs,eqArr);
    then (vars,vidxs,eqs,eidxs);
  case(BackendDAE.SINGLEARRAY(eqn=eidx,vars=vidxs),_,_)
    equation
      vars = List.map1(vidxs,BackendVariable.getVarAtIndexFirst,varArr);
      eq = BackendEquation.get(eqArr,eidx);
    then (vars,vidxs,{eq},{eidx});
  case(BackendDAE.SINGLEALGORITHM(eqn=eidx,vars=vidxs),_,_)
    equation
      vars = List.map1(vidxs,BackendVariable.getVarAtIndexFirst,varArr);
      eq = BackendEquation.get(eqArr,eidx);
    then (vars,vidxs,{eq},{eidx});
  case(BackendDAE.SINGLECOMPLEXEQUATION(eqn=eidx,vars=vidxs),_,_)
    equation
      vars = List.map1(vidxs,BackendVariable.getVarAtIndexFirst,varArr);
      eq = BackendEquation.get(eqArr,eidx);
    then (vars,vidxs,{eq},{eidx});
  case(BackendDAE.SINGLEWHENEQUATION(eqn=eidx,vars=vidxs),_,_)
    equation
      vars = List.map1(vidxs,BackendVariable.getVarAtIndexFirst,varArr);
      eq = BackendEquation.get(eqArr,eidx);
    then (vars,vidxs,{eq},{eidx});
  case(BackendDAE.SINGLEIFEQUATION(eqn=eidx,vars=vidxs),_,_)
    equation
      vars = List.map1(vidxs,BackendVariable.getVarAtIndexFirst,varArr);
      eq = BackendEquation.get(eqArr,eidx);
    then (vars,vidxs,{eq},{eidx});
  case(BackendDAE.TORNSYSTEM(strictTearingSet = BackendDAE.TEARINGSET(residualequations=eidxs,tearingvars=vidxs, innerEquations=innerEquations)),_,_)
    equation
      (otherEqns,otherVarsLst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
      otherVars = List.flatten(otherVarsLst);
      eidxs = listAppend(otherEqns,eidxs);
      vidxs = listAppend(otherVars,vidxs);
      vars = List.map1(vidxs,BackendVariable.getVarAtIndexFirst,varArr);
      eqs = BackendEquation.getList(eidxs,eqArr);
    then (vars,vidxs,eqs,eidxs);
  end match;
end getStrongComponentVarsAndEquations;

public function getStrongComponentEquations"gets all equations from a component"
  input list<BackendDAE.StrongComponent> comps;
  input BackendDAE.EquationArray eqs;
  input BackendDAE.Variables vars;
  output list<BackendDAE.Equation> eqsOut;
protected
  BackendDAE.StrongComponent comp;
  list<BackendDAE.Equation> eqLst;
algorithm
  eqsOut := {};
  for comp in comps loop
    (_,_,eqLst,_) := BackendDAEUtil.getStrongComponentVarsAndEquations(comp,vars,eqs);
    eqsOut := listAppend(eqLst,eqsOut);
  end for;
end getStrongComponentEquations;

public function isFuncCallWithNoDerAnnotation"checks if the equation is a function call which has a noDerivative annotation.
Outputs the noDerivative binding crefs as well.
author: waurich TUD 10-2015"
  input BackendDAE.Equation eq;
  input DAE.FunctionTree functionTree;
  output Boolean isFuncCallWithNoDerAnno;
  output list<DAE.ComponentRef> noDerivativeInputs;
algorithm
  (_,(_,noDerivativeInputs)) := BackendEquation.traverseExpsOfEquation(eq,function Expression.traverseExpTopDown(func=isFuncCallWithNoDerAnnotation1),(functionTree,{}));
  isFuncCallWithNoDerAnno := not listEmpty(noDerivativeInputs);
end isFuncCallWithNoDerAnnotation;

public function isFuncCallWithNoDerAnnotation1 "checks if the exp is a function call which has a noDerivative annotation.
Collects all crefs which dont need a derivative.
author: waurich TUD 10-2015"
  input DAE.Exp expIn;
  input tuple<DAE.FunctionTree, list<DAE.ComponentRef>> tplIn; // <functionTree, foldList to collect noDer-input-vars>
  output DAE.Exp expOut;
  output Boolean cont;
  output tuple<DAE.FunctionTree, list<DAE.ComponentRef>> tplOut;
algorithm
  (expOut, cont, tplOut) := matchcontinue(expIn, tplIn)
    local
      list<Integer> inputPos;
      Absyn.Path path;
      DAE.derivativeCond cond;
      DAE.FunctionDefinition mapper;
      DAE.FunctionTree functionTree;
      list<DAE.ComponentRef> crefsIn, noDerivativeInputs;
      list<DAE.Exp> expLst;
      list<tuple<Integer,DAE.derivativeCond>> conditionRefs;
  case(DAE.CALL(path=path,expLst=expLst),(functionTree,crefsIn))
    algorithm
      (mapper, _) := Differentiate.getFunctionMapper(path, functionTree);
      DAE.FUNCTION_DER_MAPPER(conditionRefs=conditionRefs) := mapper;
      inputPos := getNoDerivativeInputPosition(conditionRefs);
      expLst := List.map1(inputPos,List.getIndexFirst,expLst);
      expLst := List.filter1OnTrue(expLst,isNotFunctionCall,functionTree);
      noDerivativeInputs := List.flatten(List.map(expLst,Expression.getAllCrefs));
        //print("crefs: "+stringDelimitList(List.map(noDerivativeInputs,ComponentReference.crefStr),", ")+"\n");
    then (expIn,true,(functionTree,listAppend(noDerivativeInputs,crefsIn)));
  else
    then (expIn,true,tplIn);
  end matchcontinue;
end isFuncCallWithNoDerAnnotation1;

public function isNotFunctionCall
"Returns true if the given expression is something different than a function call.
author: waurich TUD 10-2015"
  input DAE.Exp inExp;
  input DAE.FunctionTree funcsIn;
  output Boolean outIsNoCall;
algorithm
  outIsNoCall := matchcontinue(inExp,funcsIn)
    local
      Absyn.Path path;
      DAE.Function func;
    case (DAE.CALL(path=path),_)
      equation
        SOME(func) = DAE.AvlTreePathFunction.get(funcsIn,path);
         then listEmpty(DAEUtil.getFunctionElements(func));
    else true;
  end matchcontinue;
end isNotFunctionCall;

protected function getNoDerivativeInputPosition"get the position idx for the input-var which does not need a derivation from the NoDerivative annotations"
  input list<tuple<Integer,DAE.derivativeCond>> conds;
  output list<Integer> IdxsOut = {};
algorithm
  for c in conds loop
    IdxsOut := match(c)
      local
        Integer idx;
      case (idx,DAE.NO_DERIVATIVE(_))
        then idx::IdxsOut;
      else IdxsOut;
    end match;
  end for;
end getNoDerivativeInputPosition;

public function checkIncidenceMatrixSolvability "Performs a limited matching algorithm to sometimes figure out which equations are superflours or which variables are never solved for."
  input BackendDAE.EqSystem syst;
  input DAE.FunctionTree functionTree;
protected
  Integer varSize, eqnSize, v, eq, count;
  BackendDAE.IncidenceMatrix m, mT, mOrig, mTOrig;
  list<Integer> vars, eqs, varsInOrig, eqsInOrig;
  array<Integer> solvedVars;
  array<list<tuple<DAE.ComponentRef,Integer>>> solvedEqs;
  list<SourceInfo> infos;
  list<tuple<DAE.ComponentRef,Integer>> names;
  Integer errors = 0, numSolved = 0, eqSize, lenInfos, lenVars;
  Boolean cont = true;
  BackendDAE.Variables varsArray;
  BackendDAE.Var var;
  BackendDAE.EquationArray eqsArray;
  BackendDAE.Equation _equation;
  constant Boolean debug=false;
  constant Boolean alwaysCheck=false;
  SourceInfo info;
  String str;
algorithm
  varsArray := syst.orderedVars;
  eqsArray := syst.orderedEqs;
  varSize := BackendVariable.varsSize(varsArray);
  eqnSize := BackendEquation.equationArraySize(eqsArray);
  if varSize <> eqnSize then
    Error.addMessage(if varSize > eqnSize then Error.UNDERDET_EQN_SYSTEM else Error.OVERDET_EQN_SYSTEM, {String(eqnSize), String(varSize)});
  elseif not alwaysCheck then
    return;
  end if;
  (_, mOrig, mTOrig) := BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.ABSOLUTE(), SOME(functionTree));

  m := arrayCopy(mOrig);
  mT := arrayCopy(mTOrig);

  solvedVars := arrayCreate(arrayLength(mT), 0);
  solvedEqs := arrayCreate(arrayLength(m), {});

  for i in 1:arrayLength(m) /* Not eqnSize; that is the size including arrays */ loop
    _equation := BackendEquation.get(eqsArray, i);
    info := BackendEquation.equationInfo(_equation);
    eqSize := BackendEquation.equationSize(_equation);
    count := listLength(arrayGet(m, i));
    if eqSize > count then
      str := stringDelimitList(list(ComponentReference.printComponentRefStr(BackendVariable.varCref(BackendVariable.getVarAt(varsArray, j))) for j in arrayGet(m, i)), ", ");
      Error.addInternalError(BackendDump.equationString(_equation) + " has size size " + String(eqSize) + " but " + String(count) + " variables ("+ str +")", info);
      return;
    end if;
  end for;

  if debug then
    print("Got adjacency matrix "+String(varSize)+" "+String(arrayLength(m))+" "+String(eqnSize)+" "+String(arrayLength(mT))+"...\n");
  end if;
  count := 0;
  while cont and count < 1000 loop
    cont := false;
    count := count+1;
    for i in 1:arrayLength(m) /* Not eqnSize; that is the size including arrays */ loop
      if not listEmpty(arrayGet(solvedEqs, i)) then
        continue;
      end if;
      _equation := BackendEquation.get(eqsArray, i);
      info := BackendEquation.equationInfo(_equation);
      eqSize := BackendEquation.equationSize(_equation);
      vars := arrayGet(m, i);
      lenVars := listLength(vars);
      if eqSize == 0 then
        arrayUpdate(solvedEqs, i, {(DAE.emptyCref,0)});
        continue;
      end if;
      if lenVars <= eqSize then
        if lenVars < eqSize then
          variableDoesNotFitInEquation(i, vars, mOrig, eqsArray, varsArray, solvedVars);
          errors := errors+1;
          if lenVars == 0 then
            arrayUpdate(solvedEqs, i, (DAE.emptyCref,0)::arrayGet(solvedEqs,i));
          end if;
        end if;
        for v in vars loop
          var := BackendVariable.getVarAt(varsArray, v);
          arrayUpdate(solvedEqs, i, (var.varName,v)::arrayGet(solvedEqs,i));
          arrayUpdate(solvedVars, v, i);
          eqs := arrayGet(mT, v);
          for eq in eqs loop
            // Remove references to the variable in other equations since we can't solve it there
            arrayUpdate(m, eq, List.setDifference(arrayGet(m, eq), vars));
          end for;
          numSolved := numSolved+1;
        end for;
        cont := true;
      end if;
    end for;

    if debug then
      print("Number of equations solved: " + String(numSolved-errors) + "\n");
      print("Number of errors: " + String(errors) + "\n");
    end if;

    for i in 1:arrayLength(mT) /* = varSize */ loop
      if 0 <> arrayGet(solvedVars, i) then
        continue;
      end if;
      eqs := arrayGet(mT, i);
      var := BackendVariable.getVarAt(varsArray, i);
      info := var.source.info;
      if listEmpty(eqs) then
        Error.addSourceMessage(Error.VAR_NO_REMAINING_EQN, {
          ComponentReference.printComponentRefStr(var.varName),
          stringAppendList(list("\n  Equation " + String(eq) + ": " + BackendDump.equationString(BackendEquation.get(eqsArray, eq)) + ", which needs to solve for " + stringDelimitList(list(ComponentReference.printComponentRefStr(Util.tuple21(tpl)) for tpl in arrayGet(solvedEqs, eq)), ", ") for eq in arrayGet(mTOrig, i)))
          }, info);
        arrayUpdate(solvedVars, i, -1);
      elseif listLength(eqs) == 1 then
        {eq} := eqs;
        eqSize := BackendEquation.equationSize(BackendEquation.get(eqsArray, eq));
        names := arrayGet(solvedEqs, eq);
        lenInfos := listLength(names);
        arrayUpdate(solvedVars, i, eq);
        arrayUpdate(solvedEqs, eq, (var.varName,i)::names);
        if lenInfos >= eqSize then
          variableDoesNotFitInEquation(eq, {i}, mOrig, eqsArray, varsArray, solvedVars);
          errors := errors+1;
        end if;
        vars := arrayGet(m, eq);
        if lenInfos+1 >= eqSize then // TODO: FIXME
          for v in vars loop
            // Remove references to the equation in other variables since we can't solve it there
            arrayUpdate(mT, v, List.setDifference(arrayGet(mT, v), eqs));
          end for;
        end if;
        numSolved := numSolved+1;
        cont := true;
      end if;
    end for;

    if debug then
      print("Number of equations solved: " + String(numSolved-errors) + "\n");
      print("Number of errors: " + String(errors) + "\n");
    end if;
  end while;
  true := 0 == errors;
  if alwaysCheck and varSize == eqnSize then
    return;
  end if;
  if debug then
    for i in 1:arrayLength(mT) /* = varSize */ loop
      var := BackendVariable.getVarAt(varsArray, i);
      if 0 == arrayGet(solvedVars, i) then
        print("Remaining unsolved variable:" + ComponentReference.printComponentRefStr(var.varName) + "\n");
      end if;
    end for;
    for i in 1:arrayLength(m) /* = varSize */ loop
      _equation := BackendEquation.get(eqsArray, i);
      eqnSize := BackendEquation.equationSize(_equation);
      count := listLength(arrayGet(solvedEqs, i));
      if eqnSize <> count then
        vars := arrayGet(m, i);
        print("Remaining vars: " + stringDelimitList(list(String(j) for j in vars), ", ") + "\n");
        if count > 0 then
          str := stringDelimitList(list(ComponentReference.printComponentRefStr(Util.tuple21(e)) for e in arrayGet(solvedEqs, i)), ", ");
          print("Remaining equation (already solved "+str+"): " + BackendDump.equationString(_equation) + "\n");
        else
          print("Remaining equation: " + BackendDump.equationString(_equation) + "\n");
        end if;
      end if;
    end for;
  end if;
  fail();
end checkIncidenceMatrixSolvability;

protected function variableDoesNotFitInEquation
  input Integer eq;
  input list<Integer> vars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.EquationArray eqsArray;
  input BackendDAE.Variables varsArray;
  input array<Integer> solvedVars;
protected
  BackendDAE.Equation _equation;
  list<Integer> varsInOrig, eqsInOrig;
  String eqsString;
  SourceInfo info;
  Integer eqSize;
algorithm
  _equation := BackendEquation.get(eqsArray, eq);
  info := BackendEquation.equationInfo(_equation);
  eqSize := BackendEquation.equationSize(_equation);

  varsInOrig := List.setDifference(arrayGet(m, eq), vars);
  eqsInOrig := List.sortedUnique(List.sort(list(arrayGet(solvedVars,myVar) for myVar guard arrayGet(solvedVars,myVar)>0 in varsInOrig), intGt), intEq);
  eqsString := stringAppendList(list("\n    Equation " + String(eqNum) + " (size: "+String(BackendEquation.equationSize(BackendEquation.get(eqsArray, eqNum)))+"): " + BackendDump.equationString(BackendEquation.get(eqsArray, eqNum)) for eqNum in eqsInOrig));
  Error.addSourceMessage(Error.EQN_NO_SPACE_TO_SOLVE, {
    String(eq),
    String(eqSize),
    BackendDump.equationString(_equation),
    getVariableNamesForErrorMessage(varsArray, vars),
    getVariableNamesForErrorMessage(varsArray, varsInOrig),
    eqsString
    }, info);
end variableDoesNotFitInEquation;

protected function getVariableNamesForErrorMessage
  input BackendDAE.Variables varsArray;
  input list<Integer> vars;
  output String names;
algorithm
  names := stringDelimitList(list(ComponentReference.printComponentRefStr(BackendVariable.varCref(BackendVariable.getVarAt(varsArray, v))) for v in vars), ", ");
end getVariableNamesForErrorMessage;

// =============================================================================
// warn about iteration variables with no nominal attribute
//
// =============================================================================

protected function warnAboutIterationVariablesWithNoNominal
" author: ptaeuber"
  input BackendDAE.BackendDAE inDAE;
protected
  BackendDAE.StrongComponents comps;
  String daeTypeStr, compKind;
  list<Integer> vlst = {};
  list<BackendDAE.Var> vars;
algorithm
  daeTypeStr := BackendDump.printBackendDAEType2String(inDAE.shared.backendDAEType);
  for syst in inDAE.eqs loop
    BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := syst;

    // Go through all the strongly connected components.
    for comp in comps loop
      // Get the component's variables.
      (compKind, vlst) := match(comp)
        case BackendDAE.EQUATIONSYSTEM(vars = vlst, jacType = BackendDAE.JAC_NONLINEAR())
          then ("nonlinear equation system in the " + daeTypeStr + " DAE:", vlst);
        case BackendDAE.EQUATIONSYSTEM(vars = vlst, jacType = BackendDAE.JAC_GENERIC())
          then ("equation system with analytic Jacobian in the " + daeTypeStr + " DAE:", vlst);
        case BackendDAE.EQUATIONSYSTEM(vars = vlst, jacType = BackendDAE.JAC_NO_ANALYTIC())
          then ("equation system without analytic Jacobian in the " + daeTypeStr + " DAE:", vlst);
        case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars = vlst), linear = false)
          then ("torn nonlinear equation system in the " + daeTypeStr + " DAE:", vlst);
        // If the component is none of these types, do nothing.
        else ("", {});
      end match;

      if not listEmpty(vlst) then
        // Filter out the variables that are missing start values.
        vars := List.map1r(vlst, BackendVariable.getVarAt, syst.orderedVars);
        vars := list(v for v guard(not BackendVariable.varHasNominalValue(v)) in vars);

        // Print a warning if we found any variables with missing start values.
        if not listEmpty(vars) then
          Error.addCompilerWarning(BackendDump.varListStringIndented(vars, "Iteration variables with no nominal value in " + compKind));
        end if;
      end if;
    end for;
  end for;
end warnAboutIterationVariablesWithNoNominal;

public function getLinearfromJacType "  author: Frenkel TUD 2012-09"
  input BackendDAE.JacobianType jacType;
  output Boolean linear;
algorithm
  linear := match(jacType)
    case (BackendDAE.JAC_CONSTANT()) then true;
    case (BackendDAE.JAC_LINEAR()) then true;
    case (BackendDAE.JAC_NONLINEAR()) then false;
    case (BackendDAE.JAC_NO_ANALYTIC()) then false;
  end match;
end getLinearfromJacType;

public function containsHomotopyCall
  input DAE.Exp inExp;
  input Boolean inHomotopy;
  output DAE.Exp outExp;
  output Boolean outHomotopy;
protected
  Boolean b;
algorithm
  (outExp, outHomotopy) := Expression.traverseExpTopDown(inExp, containsHomotopyCall2, inHomotopy);
end containsHomotopyCall;

protected function containsHomotopyCall2
  input DAE.Exp inExp;
  input Boolean inHomotopy;
  output DAE.Exp outExp = inExp;
  output Boolean cont;
  output Boolean outHomotopy;
protected
  Boolean b;
algorithm
  (outExp, outHomotopy, cont) := match(inExp, inHomotopy)
    case (_, true)
     then (inExp, true, false);

    case (DAE.CALL(path=Absyn.IDENT(name="homotopy")), _)
     then (inExp, true, false);

    case (DAE.CREF(componentRef=DAE.CREF_IDENT(ident=BackendDAE.homotopyLambda)), _)
     then (inExp, true, false);

    else (inExp, inHomotopy, true);
  end match;
end containsHomotopyCall2;

annotation(__OpenModelica_Interface="backend");
end BackendDAEUtil;
