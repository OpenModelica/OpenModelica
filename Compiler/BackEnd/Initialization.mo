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

encapsulated package Initialization
" file:  Initialization.mo
  package:     Initialization
  description: Initialization.mo contains everything needed to set up the
         BackendDAE for the initial system.

  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;
public import Util;

protected import BackendDAEEXT;
protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BaseHashTable;
protected import CheckModel;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import HashTable3;
protected import HashTable;
protected import HashTableCG;
protected import List;
protected import Matching;

// =============================================================================
// section for all public functions
//
// These are functions that can be used to access the initialization.
// =============================================================================

public function solveInitialSystem "function solveInitialSystem
  author: lochel
  This function generates a algebraic system of equations for the initialization and solves it."
  input BackendDAE.BackendDAE inDAE;
  input list<BackendDAE.Var> inTempVar;
  output Option<BackendDAE.BackendDAE> outInitDAE;
  output list<BackendDAE.Var> outTempVar;
protected
  BackendDAE.BackendDAE dae;
  BackendDAE.Variables initVars;
algorithm
  // inline all when equations, if active with body if inactive with var=pre(var)
  dae := inlineWhenForInitialization(inDAE);
  // Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, dae, "inlineWhenForInitialization");

  initVars := selectInitializationVariablesDAE(dae);
  Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpVariables, initVars, "selected initialization variables");

  (outInitDAE, outTempVar) := solveInitialSystem1(dae, initVars, inTempVar);
end solveInitialSystem;

// =============================================================================
// section for inlining when-clauses
//
// This section contains all the helper functions to replace all when-clauses
// from a given BackenDAE to get the initial equation system.
// =============================================================================

protected function inlineWhenForInitialization "function inlineWhenForInitialization
  author: lochel
  This function inlines when-clauses for the initialization."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  systs := List.map(systs, inlineWhenForInitializationSystem);
  outDAE := BackendDAE.DAE(systs, shared);
end inlineWhenForInitialization;

protected function inlineWhenForInitializationSystem "function inlineWhenForInitializationSystem
  author: lochel
  This is a helper function for inlineWhenForInitialization."
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.EquationArray eqns;
  BackendDAE.StateSets stateSets;
  list<BackendDAE.Equation> eqnlst;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets) := inEqSystem;

  ((orderedVars, eqnlst)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, inlineWhenForInitializationEquation, (orderedVars, {}));
  eqns := BackendEquation.listEquation(eqnlst);

  outEqSystem := BackendDAE.EQSYSTEM(orderedVars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets);
end inlineWhenForInitializationSystem;

protected function inlineWhenForInitializationEquation "function inlineWhenForInitializationEquation
  author: lochel
  This is a helper function for inlineWhenForInitialization1."
  input tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, list<BackendDAE.Equation>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, list<BackendDAE.Equation>>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      DAE.ElementSource source;
      BackendDAE.Equation eqn;
      DAE.Algorithm alg;
      Integer size;
      list< DAE.Statement> stmts;
      list< BackendDAE.Equation> eqns;
      BackendDAE.WhenEquation weqn;
      BackendDAE.Variables vars;
      list< DAE.ComponentRef> crefLst;
      HashTable.HashTable leftCrs;
      list<tuple<DAE.ComponentRef, Integer>> crintLst;

    // when equation during initialization
    case ((eqn as BackendDAE.WHEN_EQUATION(whenEquation=weqn, source=source), (vars, eqns))) equation
      (eqns, vars) = inlineWhenForInitializationWhenEquation(weqn, source, eqns, vars);
    then ((eqn, (vars, eqns)));

    // algorithm
    case ((eqn as BackendDAE.ALGORITHM(alg=alg, source=source), (vars, eqns))) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg;
      (stmts, leftCrs) = generateInitialWhenAlg(stmts, true, {}, HashTable.emptyHashTableSized(50));
      alg = DAE.ALGORITHM_STMTS(stmts);
      size = listLength(CheckModel.algorithmOutputs(alg));
      crintLst = BaseHashTable.hashTableList(leftCrs);
      crefLst = List.fold(crintLst, selectSecondZero, {});
      (eqns, vars) = generateInactiveWhenEquationForInitialization(crefLst, source, eqns, vars);
      eqns = List.consOnTrue(List.isNotEmpty(stmts), BackendDAE.ALGORITHM(size, alg, source), eqns);
    then ((eqn, (vars, eqns)));

    case ((eqn, (vars, eqns)))
    then ((eqn, (vars, eqn::eqns)));
  end match;
end inlineWhenForInitializationEquation;

protected function selectSecondZero
  input tuple<DAE.ComponentRef, Integer> inTpl;
  input list<DAE.ComponentRef> iAcc;
  output list<DAE.ComponentRef> oAcc;
protected
  DAE.ComponentRef cr;
  Integer i;
algorithm
  (cr, i) := inTpl;
  oAcc := List.consOnTrue(intEq(i, 0), cr, iAcc);
end selectSecondZero;

protected function inlineWhenForInitializationWhenEquation "function inlineWhenForInitializationWhenEquation
  author: lochel
  This is a helper function for inlineWhenForInitializationEquation."
  input BackendDAE.WhenEquation inWEqn;
  input DAE.ElementSource source;
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Variables iVars;
  output list<BackendDAE.Equation> oEqns;
  output BackendDAE.Variables oVars;
algorithm
  (oEqns, oVars) := matchcontinue(inWEqn, source, iEqns, iVars)
    local
      DAE.ComponentRef left;
      DAE.Exp condition, right, crexp;
      BackendDAE.Equation eqn;
      DAE.Type identType;
      list< BackendDAE.Equation> eqns;
      BackendDAE.WhenEquation weqn;
      BackendDAE.Variables vars;

    // active when equation during initialization
    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right), _, _, _) equation
      true = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExp
      crexp = Expression.crefExp(left);
      identType = Expression.typeof(crexp);
      eqn = BackendEquation.generateEquation(crexp, right, identType, source, false);
    then (eqn::iEqns, iVars);

    // inactive when equation during initialization
    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=NONE()), _, _, _) equation
      false = Expression.containsInitialCall(condition, false);
      (eqns, vars) = generateInactiveWhenEquationForInitialization({left}, source, iEqns, iVars);
    then (eqns, iVars);

    // inactive when equation during initialization with else when part (no strict Modelica)
    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=SOME(weqn)), _, _, _) equation
      false = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExp
      (eqns, vars) = inlineWhenForInitializationWhenEquation(weqn, source, iEqns, iVars);
    then (eqns, vars);
  end matchcontinue;
end inlineWhenForInitializationWhenEquation;

protected function generateInitialWhenAlg "function generateInitialWhenAlg
  author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem.
  This is a helper function for inlineWhenForInitialization3."
  input list< DAE.Statement> inStmts;
  input Boolean first;
  input list< DAE.Statement> inAcc;
  input HashTable.HashTable iLeftCrs;
  output list< DAE.Statement> outStmts;
  output HashTable.HashTable oLeftCrs;
algorithm
  (outStmts, oLeftCrs) := matchcontinue(inStmts, first, inAcc, iLeftCrs)
    local
      DAE.Exp condition;
      list< DAE.ComponentRef> crefLst;
      DAE.Statement stmt;
      list< DAE.Statement> stmts, rest;
      HashTable.HashTable leftCrs;
      list<tuple<DAE.ComponentRef, Integer>> crintLst;

    case ({}, _, _, _)
    then (listReverse(inAcc), iLeftCrs);

    // single inactive when equation during initialization
    case ((stmt as DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=NONE()))::{}, true, _, _) equation
      false = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts);
      crintLst = List.map1(crefLst, Util.makeTuple, 1);
      leftCrs = List.fold(crefLst, addWhenLeftCr, iLeftCrs);
    then ({}, leftCrs);

    // when equation during initialization
    case ((stmt as DAE.STMT_WHEN(source=_))::rest, _, _, _) equation
      // for when statements it is not necessary that all branches have the same left hand side variables
      // -> take care that for each left hand site an assigment is generated
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, false, iLeftCrs, inAcc);
      (stmts, leftCrs) = generateInitialWhenAlg(rest, false, stmts, leftCrs);
    then  (stmts, leftCrs);

    // no when equation
    case (stmt::rest, _, _, _) equation
      (stmts, leftCrs) = generateInitialWhenAlg(rest, false, stmt::inAcc, iLeftCrs);
    then (stmts, leftCrs);
  end matchcontinue;
end generateInitialWhenAlg;

protected function inlineWhenForInitializationWhenStmt "function inlineWhenForInitializationWhenStmt
  author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem.
  This is a helper function for inlineWhenForInitialization3."
  input DAE.Statement inWhen;
  input Boolean foundAktiv;
  input HashTable.HashTable iLeftCrs;
  input list< DAE.Statement> inAcc;
  output list< DAE.Statement> outStmts;
  output HashTable.HashTable oLeftCrs;
algorithm
  (outStmts, oLeftCrs) := matchcontinue(inWhen, foundAktiv, iLeftCrs, inAcc)
    local
      DAE.Exp condition;
      list< DAE.ComponentRef> crefLst;
      DAE.Statement stmt;
      list< DAE.Statement> stmts;
      HashTable.HashTable leftCrs;
      list<tuple<DAE.ComponentRef, Integer>> crintLst;

    // active when equation during initialization
    case (DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=NONE()), _, _, _) equation
      true = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts);
      crintLst = List.map1(crefLst, Util.makeTuple, 1);
      leftCrs = List.fold(crintLst, BaseHashTable.add, iLeftCrs);
      stmts = List.foldr(stmts, List.consr, inAcc);
    then (stmts, leftCrs);

    case (DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=SOME(stmt)), false, _, _) equation
      true = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts);
      crintLst = List.map1(crefLst, Util.makeTuple, 1);
      leftCrs = List.fold(crintLst, BaseHashTable.add, iLeftCrs);
      stmts = List.foldr(stmts, List.consr, inAcc);
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, true, leftCrs, stmts);
    then (stmts, leftCrs);

    // inactive when equation during initialization
    case (DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=NONE()), _, _, _) equation
      false = Expression.containsInitialCall(condition, false) and not foundAktiv;
      crefLst = CheckModel.algorithmStatementListOutputs(stmts);
      leftCrs = List.fold(crefLst, addWhenLeftCr, iLeftCrs);
    then (inAcc, leftCrs);

    // inactive when equation during initialization with elsewhen part
    case (DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=SOME(stmt)), _, _, _) equation
      false = Expression.containsInitialCall(condition, false) and not foundAktiv;
      crefLst = CheckModel.algorithmStatementListOutputs(stmts);
      leftCrs = List.fold(crefLst, addWhenLeftCr, iLeftCrs);
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, foundAktiv, leftCrs, inAcc);
    then (stmts, leftCrs);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/Initialization.mo: function inlineWhenForInitializationWhenStmt failed"});
    then fail();
  end matchcontinue;
end inlineWhenForInitializationWhenStmt;

protected function addWhenLeftCr
  input DAE.ComponentRef cr;
  input HashTable.HashTable iLeftCrs;
  output HashTable.HashTable oLeftCrs;
algorithm
  oLeftCrs := matchcontinue(cr, iLeftCrs)
    local
      HashTable.HashTable leftCrs;

    case (_, _) equation
      leftCrs = BaseHashTable.addUnique((cr, 0), iLeftCrs);
    then leftCrs;

    else then iLeftCrs;
  end matchcontinue;
end addWhenLeftCr;

protected function generateInactiveWhenEquationForInitialization "function generateInactiveWhenEquationForInitialization
  author: lochel
  This is a helper function for inlineWhenForInitialization3."
  input list<DAE.ComponentRef> inCrLst;
  input DAE.ElementSource inSource;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.Variables iVars;
  output list<BackendDAE.Equation> outEqns;
  output BackendDAE.Variables oVars;
algorithm
  (outEqns, oVars) := match(inCrLst, inSource, inEqns, iVars)
    local
      DAE.Type identType;
      DAE.ComponentRef preCR;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Variables vars;

    case ({}, _, _, _)
    then (inEqns, iVars);

    case (cr::rest, _, _, _) equation
      identType = ComponentReference.crefType(cr);
      preCR = ComponentReference.crefPrefixPre(cr);
      eqn = BackendDAE.EQUATION(DAE.CREF(cr, identType), DAE.CREF(preCR, identType), inSource, false);
      (eqns, vars) = generateInactiveWhenEquationForInitialization(rest, inSource, eqn::inEqns, iVars);
    then (eqns, vars);
 end match;
end generateInactiveWhenEquationForInitialization;

// =============================================================================
// section for selecting initialization variables
//
//   - unfixed state
//   - unfixed parameter
//   - unfixed discrete -> pre(vd)
// =============================================================================

protected function selectInitializationVariablesDAE "function selectInitializationVariablesDAE
  author: lochel
  This function wraps selectInitializationVariables."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.Variables outVars;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Variables knownVars, alias;
algorithm
  BackendDAE.DAE(systs, BackendDAE.SHARED(knownVars=knownVars, aliasVars=alias)) := inDAE;
  outVars := selectInitializationVariables(systs);
  outVars := BackendVariable.traverseBackendDAEVars(knownVars, selectInitializationVariables2, outVars);
  outVars := BackendVariable.traverseBackendDAEVars(alias, selectInitializationVariables2, outVars);
end selectInitializationVariablesDAE;

protected function selectInitializationVariables "function selectInitializationVariables
  author: lochel"
  input BackendDAE.EqSystems inEqSystems;
  output BackendDAE.Variables outVars;
algorithm
  outVars := BackendVariable.emptyVars();
  outVars := List.fold(inEqSystems, selectInitializationVariables1, outVars);
end selectInitializationVariables;

protected function selectInitializationVariables1 "function selectInitializationVariables1
  author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
protected
  BackendDAE.Variables vars;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, stateSets=stateSets) := inEqSystem;
  outVars := BackendVariable.traverseBackendDAEVars(vars, selectInitializationVariables2, inVars);
  // ignore not the states of the statesets
  // outVars := List.fold(stateSets, selectInitialStateSetVars, outVars);
end selectInitializationVariables1;

// protected function selectInitialStateSetVars
//   input BackendDAE.StateSet inSet;
//   input BackendDAE.Variables inVars;
//   output BackendDAE.Variables outVars;
// protected
//   list< BackendDAE.Var> statescandidates;
// algorithm
//   BackendDAE.STATESET(statescandidates=statescandidates) := inSet;
//   outVars := List.fold(statescandidates, selectInitialStateSetVar, inVars);
// end selectInitialStateSetVars;
//
// protected function selectInitialStateSetVar
//   input BackendDAE.Var inVar;
//   input BackendDAE.Variables inVars;
//   output BackendDAE.Variables outVars;
// protected
//   Boolean b;
// algorithm
//   b := BackendVariable.varFixed(inVar);
//   outVars := Debug.bcallret2(not b, BackendVariable.addVar, inVar, inVars, inVars);
// end selectInitialStateSetVar;

protected function selectInitializationVariables2 "function selectInitializationVariables2
  author: lochel"
  input tuple<BackendDAE.Var, BackendDAE.Variables> inTpl;
  output tuple<BackendDAE.Var, BackendDAE.Variables> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var, preVar;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr, preCR;
      DAE.Type ty;
      DAE.InstDims arryDim;

    // unfixed state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(index=_)), vars)) equation
      false = BackendVariable.varFixed(var);
      // ignore stateset variables
      // false = isStateSetVar(cr);
      vars = BackendVariable.addVar(var, vars);
    then ((var, vars));

    // unfixed parameter
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM()), vars)) equation
      false = BackendVariable.varFixed(var);
      vars = BackendVariable.addVar(var, vars);
    then ((var, vars));

    // unfixed discrete -> pre(vd)
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), vars)) equation
      false = BackendVariable.varFixed(var);
      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      vars = BackendVariable.addVar(preVar, vars);
    then ((var, vars));

    else
    then inTpl;
  end matchcontinue;
end selectInitializationVariables2;

// protected function isStateSetVar
//   input DAE.ComponentRef cr;
//   output Boolean isStateSet;
// algorithm
//   isStateSet := match(cr)
//     local
//       DAE.Ident ident;
//       Integer i;
//
//     case DAE.CREF_QUAL(ident=ident) equation
//       i = System.strncmp("$STATESET", ident, 9);
//     then intEq(i, 0);
//
//     else then false;
//   end match;
// end isStateSetVar;

// =============================================================================
// section for collecting discrete states
//
// collect all pre(var) in time equations to get the discrete states
// =============================================================================

// protected function discreteStates "function discreteStates
//   author: Frenkel TUD 2012-12
//   This function collect the discrete states and all initialized
//   pre(var)s for the initialization."
//   input BackendDAE.BackendDAE inDAE;
//   output HashSet.HashSet hs;
// protected
//   BackendDAE.EqSystems systs;
//   BackendDAE.EquationArray initialEqs;
// algorithm
//   BackendDAE.DAE(systs, BackendDAE.SHARED(initialEqs=initialEqs)) := inDAE;
//   hs := HashSet.emptyHashSet();
//   hs := List.fold(systs, discreteStatesSystems, hs);
//   Debug.fcall(Flags.DUMP_INITIAL_SYSTEM, dumpDiscreteStates, hs);
//
//   // and check the initial equations to get all initialized pre variables
//   hs := BackendDAEUtil.traverseBackendDAEExpsEqns(initialEqs, discreteStatesIEquations, hs);
// end discreteStates;
//
// protected function discreteStatesSystems "function discreteStatesSystems
//   author: Frenkel TUD
//   This is a helper function for discreteStates.
//   The function collects all discrete states in the time equations."
//   input BackendDAE.EqSystem inEqSystem;
//   input HashSet.HashSet inHs;
//   output HashSet.HashSet outHs;
// protected
//   BackendDAE.EquationArray orderedEqs;
//   BackendDAE.EquationArray eqns;
// algorithm
//   BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := inEqSystem;
//   outHs := BackendDAEUtil.traverseBackendDAEExpsEqns(orderedEqs, discreteStatesEquations, inHs);
// end discreteStatesSystems;
//
// protected function discreteStatesEquations
//   input tuple<DAE.Exp, HashSet.HashSet> inTpl;
//   output tuple<DAE.Exp, HashSet.HashSet> outTpl;
// protected
//   DAE.Exp exp;
//   HashSet.HashSet hs;
// algorithm
//   (exp, hs) := inTpl;
//   ((_, hs)) := Expression.traverseExp(exp, discreteStatesExp, hs);
//   outTpl := (exp, hs);
// end discreteStatesEquations;
//
// protected function discreteStatesExp "function discreteStatesExp
//   author: Frenkel TUD 2012"
//   input tuple<DAE.Exp, HashSet.HashSet> inTpl;
//   output tuple<DAE.Exp, HashSet.HashSet> outTpl;
// algorithm
//   outTpl := match(inTpl)
//     local
//       DAE.Exp exp;
//       list<DAE.Exp> explst;
//       HashSet.HashSet hs;
//
//     case ((exp as DAE.CALL(path=Absyn.IDENT(name="pre")), hs)) equation
//       ((_, hs)) = Expression.traverseExp(exp, discreteStatesCref, hs);
//     then ((exp, hs));
//
//     case ((exp as DAE.CALL(path=Absyn.IDENT(name="change")), hs)) equation
//       ((_, hs)) = Expression.traverseExp(exp, discreteStatesCref, hs);
//     then ((exp, hs));
//
//     case ((exp as DAE.CALL(path=Absyn.IDENT(name="edge")), hs)) equation
//       ((_, hs)) = Expression.traverseExp(exp, discreteStatesCref, hs);
//     then ((exp, hs));
//
//     else then inTpl;
//   end match;
// end discreteStatesExp;
//
// protected function discreteStatesIEquations
//   input tuple<DAE.Exp, HashSet.HashSet> inTpl;
//   output tuple<DAE.Exp, HashSet.HashSet> outTpl;
// protected
//   DAE.Exp exp;
//   HashSet.HashSet hs;
// algorithm
//   (exp, hs) := inTpl;
//   ((_, hs)) := Expression.traverseExp(exp, discreteStatesCref, hs);
//   outTpl := (exp, hs);
// end discreteStatesIEquations;
//
// protected function discreteStatesCref "function discreteStatesCref
//   author: Frenkel TUD 2012-12
//   helper for discreteStatesExp"
//   input tuple<DAE.Exp, HashSet.HashSet> inTpl;
//   output tuple<DAE.Exp, HashSet.HashSet> outTpl;
// algorithm
//   outTpl := match(inTpl)
//     local
//       list<DAE.ComponentRef> crefs;
//       DAE.ComponentRef cr;
//       HashSet.HashSet hs;
//       DAE.Exp e;
//
//     case((e as DAE.CREF(componentRef=cr), hs)) equation
//       crefs = ComponentReference.expandCref(cr, true);
//       hs = List.fold(crefs, BaseHashSet.add, hs);
//     then ((e, hs));
//
//     else then inTpl;
//   end match;
// end discreteStatesCref;
//
// protected function dumpDiscreteStates "function discreteStates
//   author: Frenkel TUD 2012-12"
//   input HashSet.HashSet hs;
// protected
//   list<DAE.ComponentRef> crefs;
// algorithm
//   crefs := BaseHashSet.hashSetList(hs);
//   print("Discrete States for Initialization:\n========================================\n");
//   BackendDump.debuglst((crefs, ComponentReference.printComponentRefStr, "\n", "\n"));
// end dumpDiscreteStates;

// =============================================================================
//
//
//
// =============================================================================

protected function solveInitialSystem1 "function solveInitialSystem1
  author: jfrenkel, lochel
  This function generates a algebraic system of equations for the initialization and solves it."
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.Variables inInitVars;
  input list<BackendDAE.Var> inTempVar;
  output Option<BackendDAE.BackendDAE> outInitDAE;
  output list<BackendDAE.Var> outTempVar;
algorithm
  (outInitDAE, outTempVar) := matchcontinue(inDAE, inInitVars, inTempVar)
    local
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.Variables knvars, vars, fixvars, evars, eavars, avars;
      BackendDAE.EquationArray inieqns, eqns, emptyeqns, reeqns;
      BackendDAE.EqSystem initsyst;
      BackendDAE.BackendDAE initdae;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree functionTree;
      array<DAE.Constraint> constraints;
      array<DAE.ClassAttributes> classAttrs;
      list<BackendDAE.Var> tempVar;
      Boolean b;

    case(BackendDAE.DAE(systs, shared as BackendDAE.SHARED(knownVars=knvars,
                                                     aliasVars=avars,
                                                     initialEqs=inieqns,
                                                     constraints=constraints,
                                                     classAttrs=classAttrs,
                                                     cache=cache,
                                                     env=env,
                                                     functionTree=functionTree)), _, _) equation
      // collect all pre(var) in time equations to get the discrete states (-> report them)
      // and collect all pre(var) in initial equations to get all initilized pre variables
      // hs = discreteStates(inDAE);

      // collect vars and eqns for initial system
      vars = BackendVariable.emptyVars();
      fixvars = BackendVariable.emptyVars();
      eqns = BackendEquation.emptyEqns();
      reeqns = BackendEquation.emptyEqns();

      ((vars, fixvars, tempVar)) = BackendVariable.traverseBackendDAEVars(avars, collectInitialAliasVars, (vars, fixvars, inTempVar));
      ((vars, fixvars)) = BackendVariable.traverseBackendDAEVars(knvars, collectInitialVars, (vars, fixvars));
      ((eqns, reeqns)) = BackendEquation.traverseBackendDAEEqns(inieqns, collectInitialEqns, (eqns, reeqns));

      Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpEquationArray, eqns, "initial equations");

      ((vars, fixvars, eqns, reeqns)) = List.fold(systs, collectInitialVarsEqnsSystem, ((vars, fixvars, eqns, reeqns)));
      ((eqns, reeqns)) = BackendVariable.traverseBackendDAEVars(vars, collectInitialBindings, (eqns, reeqns));

      // replace initial() with true and sample(..) with false
      _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns, simplifyInitialFunktions, false);

      // generate initial system
      initsyst = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
      // remove unused variables
      initsyst = removeUnusedInitialVars(initsyst);

      evars = BackendVariable.emptyVars();
      eavars = BackendVariable.emptyVars();
      emptyeqns = BackendEquation.emptyEqns();
      shared = BackendDAE.SHARED(fixvars,
                           evars,
                           eavars,
                           emptyeqns,
                           reeqns,
                           constraints,
                           classAttrs,
                           cache,
                           env,
                           functionTree,
                           BackendDAE.EVENT_INFO(BackendDAE.SAMPLE_LOOKUP(0, {}), {}, {}, {}, {}, 0, 0),
                           {},
                           BackendDAE.INITIALSYSTEM(),
                           {});

      // split it in independend subsystems
      (systs, shared) = BackendDAEOptimize.partitionIndependentBlocksHelper(initsyst, shared, Error.getNumErrorMessages(), true);
      initdae = BackendDAE.DAE(systs, shared);
      // analzye initial system
      initdae = analyzeInitialSystem(initdae, inDAE, inInitVars);

      // some debug prints
      Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, initdae, "initial system");

      // now let's solve the system!
      (initdae, _) = BackendDAEUtil.mapEqSystemAndFold(initdae, solveInitialSystem3, inDAE);
      initdae = solveInitialSystem2(initdae);
      b = Flags.isSet(Flags.DUMP_EQNINORDER) and Flags.isSet(Flags.DUMP_INITIAL_SYSTEM);
      Debug.bcall(b, BackendDump.dumpEqnsSolved, initdae);
    then (SOME(initdae), tempVar);

    else then (NONE(), inTempVar);
  end matchcontinue;
end solveInitialSystem1;

protected function simplifyInitialFunktions "function simplifyInitialFunktions
  author: Frenkel TUD 2012-12
  simplify initial() with true and sample with false"
  input tuple<DAE.Exp, Boolean> inTpl;
  output tuple<DAE.Exp, Boolean> outTpl;
protected
  DAE.Exp exp;
  Boolean b;
algorithm
  (exp, b) := inTpl;
  outTpl := Expression.traverseExp(exp, simplifyInitialFunktionsExp, b);
end simplifyInitialFunktions;

protected function simplifyInitialFunktionsExp "function simplifyInitialFunktionsExp
  author: Frenkel TUD 2012-12
  helper for simplifyInitialFunktions"
  input tuple<DAE.Exp, Boolean> inExp;
  output tuple<DAE.Exp, Boolean> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e1;
    case ((DAE.CALL(path = Absyn.IDENT(name="initial")), _)) then ((DAE.BCONST(true), true));
    case ((DAE.CALL(path = Absyn.IDENT(name="sample")), _)) then ((DAE.BCONST(false), true));
    case ((DAE.CALL(path = Absyn.IDENT(name="delay"), expLst = _::e1::_ ),_)) then ((e1, true));
    else then inExp;
  end matchcontinue;
end simplifyInitialFunktionsExp;

protected function solveInitialSystem3 "function solveInitialSystem3
  author: jfrenkel, lochel
  This is a helper function of solveInitialSystem and solves the generated system."
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, BackendDAE.BackendDAE> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, BackendDAE.BackendDAE> osharedOptimized;
algorithm
  (osyst, osharedOptimized):=
  matchcontinue (isyst, sharedOptimized)
    local
      Integer nVars, nEqns;

    // over-determined system
    case(_, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intGt(nEqns, nVars);

      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "It was not possible to solve the over-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)");
    then fail();

    // equal
    case( _, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intEq(nEqns, nVars);
    then (isyst, sharedOptimized);

    // under-determined system
    case( _, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intLt(nEqns, nVars);

      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "It was not possible to solve the under-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)");
    then fail();
  end matchcontinue;
end solveInitialSystem3;

protected function solveInitialSystem2 "function solveInitialSystem2
  author: jfrenkel, lochel
  This is a helper function of solveInitialSystem and solves the generated system."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<tuple<BackendDAEUtil.pastoptimiseDAEModule, String, Boolean>> pastOptModules;
  tuple<BackendDAEUtil.StructurallySingularSystemHandlerFunc, String, BackendDAEUtil.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEUtil.matchingAlgorithmFunc, String> matchingAlgorithm;
  Boolean execstat;
algorithm
  pastOptModules := BackendDAEUtil.getPastOptModules(SOME({"constantLinearSystem", /* here we need a special case and remove only alias and constant (no variables of the system) variables "removeSimpleEquations", */ "tearingSystem"}));
  matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(NONE());
  daeHandler := BackendDAEUtil.getIndexReductionMethod(NONE());

  // suppress execstat
  execstat := Flags.disableDebug(Flags.EXEC_STAT);

  // solve system
  outDAE := BackendDAEUtil.transformBackendDAE(inDAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());

  // reset execstat again
  _ := Flags.set(Flags.EXEC_STAT, execstat);

  // simplify system
 (outDAE, Util.SUCCESS()) := BackendDAEUtil.pastoptimiseDAE(outDAE, pastOptModules, matchingAlgorithm, daeHandler);

  Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, outDAE, "solved initial system");
end solveInitialSystem2;

protected function removeUnusedInitialVars
  input BackendDAE.EqSystem inSystem;
  output BackendDAE.EqSystem outSystem;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  Boolean b;
  BackendDAE.IncidenceMatrix mt;
algorithm
  (_, _, mt) := BackendDAEUtil.getIncidenceMatrix(inSystem, BackendDAE.NORMAL(), NONE());
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets) := inSystem;
  (orderedVars, b) := removeUnusedInitialVarsWork(arrayLength(mt), mt, orderedVars, false);
  outSystem := Util.if_(b, BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets), inSystem);
end removeUnusedInitialVars;

protected function removeUnusedInitialVarsWork
  input Integer n;
  input BackendDAE.IncidenceMatrix mt;
  input BackendDAE.Variables iVars;
  input Boolean iB;
  output BackendDAE.Variables oVars;
  output Boolean oB;
algorithm
  (oVars, oB) := match(n, mt, iVars, iB)
    local
      list<Integer> row;
      Boolean b;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> rvarlst;

    case(0, _, _, false)
    then (iVars, false);

    case(0, _, _, true) equation
      vars = BackendVariable.listVar1(BackendVariable.varList(iVars));
    then (vars, true);

    case(_, _, _, _) equation
      row = mt[n];
      b = List.isEmpty(row);
      row = Util.if_(b, {n}, {});
      (vars, rvarlst) = BackendVariable.removeVars(row, iVars, {});
      Debug.fcall(Flags.PEDANTIC, dumpRemoveUnusedInitialVar, rvarlst);
      (vars, b) = removeUnusedInitialVarsWork(n-1, mt, vars, b or iB);
    then (vars, b);
  end match;
end removeUnusedInitialVarsWork;

protected function dumpRemoveUnusedInitialVar
  input list<BackendDAE.Var> rvarlst;
algorithm
  _ := match(rvarlst)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> rest;

    case {} then ();
    case (v::rest) equation
      print("Ignore unused variable " +& BackendDump.varString(v) +& "\n");
      dumpRemoveUnusedInitialVar(rest);
    then ();
  end match;
end dumpRemoveUnusedInitialVar;

protected function analyzeInitialSystem "function analyzeInitialSystem
  author: lochel
  This function fixes discrete and state variables to balance the initial equation system."
  input BackendDAE.BackendDAE initDAE;
  input BackendDAE.BackendDAE inDAE;      // original DAE
  input BackendDAE.Variables inInitVars;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(initDAE, analyzeInitialSystem2, (inDAE, inInitVars));
end analyzeInitialSystem;

protected function analyzeInitialSystem2 "function analyzeInitialSystem2
  author lochel"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, tuple<BackendDAE.BackendDAE, BackendDAE.Variables>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, tuple<BackendDAE.BackendDAE, BackendDAE.Variables>> osharedOptimized;
algorithm
  (osyst, osharedOptimized):= matchcontinue(isyst, sharedOptimized)
    local
      BackendDAE.EqSystem system;
      Integer nVars, nEqns;
      BackendDAE.Variables vars, initVars;
      BackendDAE.EquationArray eqns;
      BackendDAE.BackendDAE inDAE;
      BackendDAE.Shared shared;
      String msg, eqn_str;
      array<Integer> vec1, vec2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
      DAE.FunctionTree funcs;
      list<Integer> unassignedeqns;
      list<list<Integer>> ilstlst;
      HashTableCG.HashTable ht;
      HashTable3.HashTable dht;

    // over-determined system
    case(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars))) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intGt(nEqns, nVars);
      Debug.fcall2(Flags.PEDANTIC, BackendDump.dumpEqSystem, isyst, "Trying to fix over-determined initial system");
      msg = "Trying to fix over-determined initial system Variables " +& intString(nVars) +& " Equations " +& intString(nEqns) +& "... [not implemented yet!]";
      Error.addCompilerWarning(msg);

      // analyze system
      funcs = BackendDAEUtil.getFunctions(shared);
      (system, m, mt, mapEqnIncRow, mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst, BackendDAE.NORMAL(), SOME(funcs));
      // BackendDump.printEqSystem(system);
      vec1 = arrayCreate(nVars, -1);
      vec2 = arrayCreate(nEqns, -1);
      Matching.matchingExternalsetIncidenceMatrix(nVars, nEqns, m);
      BackendDAEEXT.matching(nVars, nEqns, 5, -1, 0.0, 1);
      BackendDAEEXT.getAssignment(vec2, vec1);
      // BackendDump.dumpMatching(mapIncRowEqn);
      // BackendDump.dumpMatching(vec1);
      // BackendDump.dumpMatching(vec2);
      // system = BackendDAEUtil.setEqSystemMatching(system, BackendDAE.MATCHING(vec1, vec2, {}));
      // BackendDump.printEqSystem(system);
      unassignedeqns = Matching.getUnassigned(nEqns, vec2, {});
      ht = HashTableCG.emptyHashTable();
      dht = HashTable3.emptyHashTable();
      ilstlst = Matching.getEqnsforIndexReduction(unassignedeqns, nEqns, m, mt, vec1, vec2, (BackendDAE.STATEORDER(ht, dht), {}, mapEqnIncRow, mapIncRowEqn, nEqns));
      unassignedeqns = List.flatten(ilstlst);
      unassignedeqns = List.map1r(unassignedeqns, arrayGet, mapIncRowEqn);
      unassignedeqns = List.uniqueIntN(unassignedeqns, arrayLength(mapIncRowEqn));
      eqn_str = BackendDump.dumpMarkedEqns(isyst, unassignedeqns);
      //vars = getUnassigned(nVars, vec1, {});
      //vars = List.fold1(unmatched, getAssignedVars, inAssignments1, vars);
      //vars = List.select1(vars, intLe, n);
      //var_str = BackendDump.dumpMarkedVars(isyst, vars);
      msg = "System is over-determined in Equations " +& eqn_str;
      Error.addCompilerWarning(msg);
    then fail();

    // under-determined system
    case(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars))) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intLt(nEqns, nVars);

      (true, vars, eqns, shared) = fixUnderDeterminedInitialSystem(inDAE, vars, eqns, initVars, shared);
      system = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
    then (system, (shared, (inDAE, initVars)));

    else then (isyst, sharedOptimized);
  end matchcontinue;
end analyzeInitialSystem2;

protected function fixUnderDeterminedInitialSystem "function fixUnderDeterminedInitialSystem
  author: lochel"
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inInitVars;
  input BackendDAE.Shared iShared;
  output Boolean outSucceed;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.Shared oShared;
algorithm
  (outSucceed, outVars, outEqns, oShared) := matchcontinue(inDAE, inVars, inEqns, inInitVars, iShared)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      Integer nVars, nInitVars, nEqns;
      list<BackendDAE.Var> initVarList;
      BackendDAE.BackendDAE dae;
      BackendDAE.SparsePattern sparsityPattern;
      list<BackendDAE.Var> outputs;   // $res1 ... $resN (initial equations)
      list<tuple< DAE.ComponentRef, list< DAE.ComponentRef>>> dep;
      list< DAE.ComponentRef> selectedVars;
      array<Integer> vec1, vec2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EqSystem syst;
      list<Integer> unassigned;
      BackendDAE.Shared shared;
      DAE.FunctionTree funcs;
    // fix undetermined system
    case (_, _, _, _, _) equation
      // match the system
      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendDAEUtil.equationSize(inEqns);
      syst = BackendDAE.EQSYSTEM(inVars, inEqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
      funcs = BackendDAEUtil.getFunctions(iShared);
      (syst, m, mt, _, _) = BackendDAEUtil.getIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs));
      //  BackendDump.printEqSystem(syst);
      vec1 = arrayCreate(nVars, -1);
      vec2 = arrayCreate(nEqns, -1);
      Matching.matchingExternalsetIncidenceMatrix(nVars, nEqns, m);
      BackendDAEEXT.matching(nVars, nEqns, 5, -1, 0.0, 1);
      BackendDAEEXT.getAssignment(vec2, vec1);
      // try to find for unmatched variables without startvalue an equation by unassign a variable with start value
      //unassigned1 = Matching.getUnassigned(nEqns, vec2, {});
      //  print("Unassigned Eqns " +& stringDelimitList(List.map(unassigned1, intString), ", ") +& "\n");
      unassigned = Matching.getUnassigned(nVars, vec1, {});
      //  print("Unassigned Vars " +& stringDelimitList(List.map(unassigned, intString), ", ") +& "\n");
      Debug.bcall(intGt(listLength(unassigned), nVars-nEqns), print, "Error could not match all equations\n");
      unassigned = Util.if_(intGt(listLength(unassigned), nVars-nEqns), {}, unassigned);
      //unassigned = List.firstN(listReverse(unassigned), nVars-nEqns);
      unassigned = replaceFixedCandidates(unassigned, nVars, nEqns, m, mt, vec1, vec2, inVars, inInitVars, 1, arrayCreate(nEqns, -1), {});
      // add for all free variables an equation
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(nVars-nEqns) +& " variables:");
      initVarList = List.map1r(unassigned, BackendVariable.getVarAt, inVars);
      (vars, eqns, shared) = addStartValueEquations(initVarList, inVars, inEqns, iShared);
    then (true, vars, eqns, shared);

    // fix all free variables
    case(_, _, eqns, _, _) equation
      nInitVars = BackendVariable.varsSize(inInitVars);
      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendDAEUtil.equationSize(inEqns);
      true = intEq(nVars, nEqns+nInitVars);

      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(nVars-nEqns) +& " variables:");
      initVarList = BackendVariable.varList(inInitVars);
      (vars, eqns, shared) = addStartValueEquations(initVarList, inVars, eqns, iShared);
    then (true, vars, eqns, shared);

    // fix a subset of unfixed variables
    case(_, _, eqns, _, _) equation
      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intLt(nEqns, nVars);

      initVarList = BackendVariable.varList(inInitVars);
      (dae, outputs) = BackendDAEOptimize.generateInitialMatricesDAE(inDAE);
      (sparsityPattern, _) = BackendDAEOptimize.generateSparsePattern(dae, initVarList, outputs);

      (dep, _) = sparsityPattern;
      selectedVars = collectIndependentVars(dep, {});

      Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpSparsityPattern, sparsityPattern, "Sparsity Pattern");
      true = intEq(nVars-nEqns, listLength(selectedVars));  // fix only if it is definite

      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(nVars-nEqns) +& " variables:");
      (eqns) = addStartValueEquations1(selectedVars, eqns);
    then (true, inVars, eqns, iShared);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"It is not possible to determine unique which additional initial conditions should be added by auto-fixed variables."});
    then (false, inVars, inEqns, iShared);
  end matchcontinue;
end fixUnderDeterminedInitialSystem;

protected function replaceFixedCandidates "function replaceFixedCandidates
  author Frenkel TUD 2012-12
  try to switch to more appropriate candidates for fixed variables"
  input list<Integer> iUnassigned;
  input Integer nVars;
  input Integer nEqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> vec1;
  input array<Integer> vec2;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inInitVars;
  input Integer mark;
  input array<Integer> markarr;
  input list<Integer> iAcc;
  output list<Integer> oUnassigned;
algorithm
  oUnassigned := matchcontinue(iUnassigned, nVars, nEqns, m, mT, vec1, vec2, inVars, inInitVars, mark, markarr, iAcc)
    local
      Integer i, i1, i2, e;
      list<Integer> unassigned, acc;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      Boolean b;

    case ({}, _, _, _, _, _, _, _, _, _, _, _) then iAcc;

    // member of inInitVars is ok to be free
    case (i::unassigned, _, _, _, _, _, _, _, _, _, _, _) equation
      v = BackendVariable.getVarAt(inVars, i);
      cr = BackendVariable.varCref(v);
      true = BackendVariable.existsVar(cr, inInitVars, false);
      //  print("Unasigned Var from InitVars " +& ComponentReference.printComponentRefStr(cr) +& "\n");
    then replaceFixedCandidates(unassigned, nVars, nEqns, m, mT, vec1, vec2, inVars, inInitVars, mark, markarr, i::iAcc);

    // not member of inInitVars try to change it
    case (i::unassigned, _, _, _, _, _, _, _, _, _, _, _) equation
      v = BackendVariable.getVarAt(inVars, i);
      cr = BackendVariable.varCref(v);
      false = BackendVariable.existsVar(cr, inInitVars, false);
      (i1, i2) = getAssignedVarFromInitVars(1, BackendVariable.varsSize(inInitVars), vec1, inVars, inInitVars);
      //  print("try to switch " +& ComponentReference.printComponentRefStr(cr) +& " with " +& intString(i1) +& "\n");
      // unassign var
      e = vec1[i1];
      _ = arrayUpdate(vec2, e, -1);
      _ = arrayUpdate(vec1, i1, -1);
      // try to assign i1
      b = pathFound({i}, i, m, mT, vec1, vec2, mark, markarr);
      acc = replaceFixedCandidates1(b, i, i1, e, i2, nVars, nEqns, m, mT, vec1, vec2, inVars, inInitVars, mark+1, markarr, iAcc);
    then replaceFixedCandidates(unassigned, nVars, nEqns, m, mT, vec1, vec2, inVars, inInitVars, mark+1, markarr, acc);

    // if not assignable use it
    case (i::unassigned, _, _, _, _, _, _, _, _, _, _, _) //equation
      //  print("cannot switch var " +& intString(i) +& "\n");
    then replaceFixedCandidates(unassigned, nVars, nEqns, m, mT, vec1, vec2, inVars, inInitVars, mark, markarr, i::iAcc);
  end matchcontinue;
end replaceFixedCandidates;

protected function replaceFixedCandidates1
  input Boolean iFound;
  input Integer iI;
  input Integer iI1;
  input Integer iE;
  input Integer iI2;
  input Integer nVars;
  input Integer nEqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> vec1;
  input array<Integer> vec2;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inInitVars;
  input Integer mark;
  input array<Integer> markarr;
  input list<Integer> iAcc;
  output list<Integer> oUnassigned;
algorithm
  oUnassigned := match(iFound, iI, iI1, iE, iI2, nVars, nEqns, m, mT, vec1, vec2, inVars, inInitVars, mark, markarr, iAcc)
    local
      Integer  i1, i2, e;
      Boolean b;

    case (true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) then iI1::iAcc;
    case (false, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) equation
      // revert assignment
      _ = arrayUpdate(vec2, iE, iI1);
      _ = arrayUpdate(vec1, iI1, iE);
      // get next
      (i1, i2) = getAssignedVarFromInitVars(iI2+1, BackendVariable.varsSize(inInitVars), vec1, inVars, inInitVars);
      //  print("try to switch " +& intString(iI) +& " with " +& intString(i1) +& "\n");
      // unassign var
      e = vec1[i1];
      _ = arrayUpdate(vec2, e, -1);
      _ = arrayUpdate(vec1, i1, -1);
      // try to assign i1
      b = pathFound({iI}, iI, m, mT, vec1, vec2, mark, markarr);
    then replaceFixedCandidates1(b, iI, i1, e, i2, nVars, nEqns, m, mT, vec1, vec2, inVars, inInitVars, mark+1, markarr, iAcc);
  end match;
end replaceFixedCandidates1;

protected function getAssignedVarFromInitVars
  input Integer iIndex;
  input Integer nVars;
  input array<Integer> vec1;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inInitVars;
  output Integer oVar;
  output Integer oIndex;
algorithm
  (oVar, oIndex) := matchcontinue(iIndex, nVars, vec1, inVars, inInitVars)
    local
      Integer i;
      BackendDAE.Var v;
      DAE.ComponentRef cr;

    case(_, _, _, _, _) equation
      true = intLe(iIndex, nVars);
      v = BackendVariable.getVarAt(inInitVars, iIndex);
      cr = BackendVariable.varCref(v);
      (_, {i}) = BackendVariable.getVar(cr, inVars);
      // var is free?
      true = intGt(vec1[i], 0);
      //  print("found free InitVars " +& ComponentReference.printComponentRefStr(cr) +& "\n");
    then (i, iIndex);

    case(_, _, _, _, _) equation
      true = intLe(iIndex, nVars);
      (oVar, oIndex) = getAssignedVarFromInitVars(iIndex+1, nVars, vec1, inVars, inInitVars);
    then (oVar, oIndex);
  end matchcontinue;
end getAssignedVarFromInitVars;

protected function pathFound "function pathFound
  author: Frenkel TUD 2012-12
  function helper for getAssignedVarFromInitVars, traverses all colums and perform a DFSB phase on each"
  input list<Integer> stack;
  input Integer i;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Integer mark;
  input array<Integer> markarr;
  output Boolean found;
algorithm
  found :=
  match (stack, i, m, mT, ass1, ass2, mark, markarr)
    local
      list<Integer> eqns;

    case ({}, _, _, _, _, _, _, _) then false;
    case (_, _, _, _, _, _, _, _) equation
      // traverse all adiacent eqns
      eqns = List.select(mT[i], Util.intPositive);
    then pathFoundtraverseEqns(eqns, stack, m, mT, ass1, ass2, mark, markarr);
  end match;
end pathFound;

protected function pathFoundtraverseEqns "function pathFoundtraverseEqns
  author: Frenkel TUD 2012-12
  function helper for pathFound, traverses all vars of a equations and search a augmenting path"
  input list<Integer> rows;
  input list<Integer> stack;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Integer mark;
  input array<Integer> markarr;
  output Boolean found;
algorithm
  found := matchcontinue (rows, stack, m, mT, ass1, ass2, mark, markarr)
    local
      list<Integer> rest;
      Integer rc, e;
      Boolean b;

    case ({}, _, _, _, _, _, _, _) then false;
    case (e::rest, _, _, _, _, _, _, _) equation
      // row is unmatched -> augmenting path found
      true = intLt(ass2[e], 0);
      reasign(stack, e, ass1, ass2);
    then true;

    case (e::rest, _, _, _, _, _, _, _) equation
      // row is matched
      rc = ass2[e];
      false = intLt(rc, 0);
      false = intEq(markarr[e], mark);
      _ = arrayUpdate(markarr, e, mark);
      b = pathFound(rc::stack, rc, m, mT, ass1, ass2, mark, markarr);
    then pathFoundtraverseEqns1(b, rest, stack, m, mT, ass1, ass2, mark, markarr);

    case (_::rest, _, _, _, _, _, _, _)
    then pathFoundtraverseEqns(rest, stack, m, mT, ass1, ass2, mark, markarr);
  end matchcontinue;
end pathFoundtraverseEqns;

protected function pathFoundtraverseEqns1 "function pathFoundtraverseEqns1
  author: Frenkel TUD 2012-12
  function helper for pathFoundtraverseEqns"
  input Boolean b;
  input list<Integer> rows;
  input list<Integer> stack;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input Integer mark;
  input array<Integer> markarr;
  output Boolean found;
algorithm
  found := match (b, rows, stack, m, mT, ass1, ass2, mark, markarr)
    case (true, _, _, _, _, _, _, _, _) then true;
    else pathFoundtraverseEqns(rows, stack, m, mT, ass1, ass2, mark, markarr);
  end match;
end pathFoundtraverseEqns1;

protected function reasign "function reasign
  author: Frenkel TUD 2012-03
  function helper for pathfound, reasignment(rematching) allong the augmenting path
  remove all edges from the assignments that are in the path
  add all other edges to the assignment"
  input list<Integer> stack;
  input Integer e;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _ := match (stack, e, ass1, ass2)
    local
      Integer i, e1;
      list<Integer> rest;

    case ({}, _, _, _) then ();
    case (i::rest, _, _, _) equation
      e1 = ass1[i];
      _ = arrayUpdate(ass1, i, e);
      _ = arrayUpdate(ass2, e, i);
      reasign(rest, e1, ass1, ass2);
    then ();
  end match;
end reasign;

protected function collectIndependentVars "function collectIndependentVars
  author lochel"
  input list<tuple< DAE.ComponentRef, list< DAE.ComponentRef>>> inPattern;
  input list< DAE.ComponentRef> inVars;
  output list< DAE.ComponentRef> outVars;
algorithm
  outVars := matchcontinue(inPattern, inVars)
    local
      tuple< DAE.ComponentRef, list< DAE.ComponentRef>> curr;
      list<tuple< DAE.ComponentRef, list< DAE.ComponentRef>>> rest;
      DAE.ComponentRef cr;
      list< DAE.ComponentRef> crList, vars;

    case ({}, _)
    then inVars;

    case (curr::rest, _) equation
      (cr, crList) = curr;
      true = List.isEmpty(crList);

      vars = collectIndependentVars(rest, inVars);
      vars = cr::vars;
    then vars;

    case (curr::rest, _) equation
      vars = collectIndependentVars(rest, inVars);
    then vars;

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/Initialization.mo: function collectIndependentVars failed"});
    then fail();
  end matchcontinue;
end collectIndependentVars;

protected function addStartValueEquations "function addStartValueEquations
  author lochel"
  input list<BackendDAE.Var> inVarLst;
  input BackendDAE.Variables iVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Shared iShared;
  output BackendDAE.Variables oVars;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.Shared oShared;
algorithm
  (oVars, outEqns, oShared) := matchcontinue(inVarLst, iVars, inEqns, iShared)
    local
      BackendDAE.Variables vars;
      BackendDAE.Var var, preVar;
      list<BackendDAE.Var> varlst;
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns;
      DAE.Exp e,  crefExp, startExp;
      DAE.ComponentRef cref, preCref;
      DAE.Type tp;
      String crStr;
      DAE.InstDims arryDim;
      BackendDAE.Shared shared;

    case ({}, _, _, _) then (iVars, inEqns, iShared);

    case (var::varlst, _, _, _) equation
      preCref = BackendVariable.varCref(var);
      true = ComponentReference.isPreCref(preCref);
      cref = ComponentReference.popPreCref(preCref);
      tp = BackendVariable.varType(var);

      crefExp = DAE.CREF(preCref, tp);

      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, false);

      crStr = ComponentReference.crefStr(cref);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "  [discrete] " +& crStr);

      eqns = BackendEquation.equationAdd(eqn, inEqns);
      (vars, eqns, shared) = addStartValueEquations(varlst, iVars, eqns, iShared);
    then (vars, eqns, shared);

    case ((var as BackendDAE.VAR(varName=cref, varType=tp, arryDim=arryDim))::varlst, _, _, _) equation
      true = BackendVariable.isVarDiscrete(var);
      crefExp = DAE.CREF(cref, tp);

      //optexp = BackendVariable.varStartValueOption(var);
      preCref = ComponentReference.crefPrefixPre(cref);  // cr => $PRE.cr
      //preVar = BackendDAE.VAR(preCref, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), tp, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      //preVar = BackendVariable.setVarFixed(preVar, true);
      //preVar = BackendVariable.setVarStartValueOption(preVar, optexp);

      // e = Expression.crefExp(cref);
      //startExp = Expression.crefExp(preCref);

      //eqn = BackendEquation.generateEquation(crefExp, startExp, tp, DAE.emptyElementSource, false);

      crStr = ComponentReference.crefStr(cref);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "  [discrete] " +& crStr);

      ({preVar}, _) = BackendVariable.getVar(preCref, iVars);
      preVar = BackendVariable.setVarFixed(preVar, true);
      vars = BackendVariable.deleteVar(preCref, iVars);
      shared = BackendVariable.addKnVarDAE(preVar, iShared);
      //eqns = BackendEquation.equationAdd(eqn, inEqns);
      (vars, eqns, shared) = addStartValueEquations(varlst, vars, inEqns, shared);
    then (vars, eqns, shared);

    case (var::varlst, _, _, _) equation
      cref = BackendVariable.varCref(var);
      tp = BackendVariable.varType(var);

      crefExp = DAE.CREF(cref, tp);

      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, false);

      crStr = ComponentReference.crefStr(cref);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "  [continuous] " +& crStr);

      eqns = BackendEquation.equationAdd(eqn, inEqns);
      (vars, eqns, shared) = addStartValueEquations(varlst, iVars, eqns, iShared);
    then (vars, eqns, shared);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/Initialization.mo: function addStartValueEquations failed"});
    then fail();
  end matchcontinue;
end addStartValueEquations;

protected function addStartValueEquations1 "function addStartValueEquations1
  author lochel
  Same as addStartValueEquations - just with list<DAE.ComponentRef> instead of list<BackendDAE.Var>"
  input list<DAE.ComponentRef> inVars;
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns := matchcontinue(inVars, inEqns)
    local
      DAE.ComponentRef var, cref;
      list<DAE.ComponentRef> vars;
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns;
      DAE.Exp e,  crefExp, startExp;
      DAE.Type tp;
      String crStr;

    case ({}, _)
    then inEqns;

    case (var::vars, eqns) equation
      true = ComponentReference.isPreCref(var);
      cref = ComponentReference.popPreCref(var);
      crefExp = DAE.CREF(var, DAE.T_REAL_DEFAULT);

      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, false);

      crStr = ComponentReference.crefStr(cref);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "  [discrete] " +& crStr);

      eqns = BackendEquation.equationAdd(eqn, eqns);
      eqns = addStartValueEquations1(vars, eqns);
    then eqns;

    case (var::vars, eqns) equation
      crefExp = DAE.CREF(var, DAE.T_REAL_DEFAULT);

      e = Expression.crefExp(var);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, false);

      crStr = ComponentReference.crefStr(var);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "  [continuous] " +& crStr);

      eqns = BackendEquation.equationAdd(eqn, eqns);
      eqns = addStartValueEquations1(vars, eqns);
    then eqns;

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/Initialization.mo: function addStartValueEquations1 failed"});
    then fail();
  end matchcontinue;
end addStartValueEquations1;

protected function collectInitialVarsEqnsSystem "function collectInitialVarsEqnsSystem
  author: lochel, Frenkel TUD 2012-10
  This function collects variables and equations for the initial system out of an given EqSystem."
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.EquationArray> iTpl;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.EquationArray> oTpl;
protected
  BackendDAE.Variables orderedVars, vars, fixvars;
  BackendDAE.EquationArray orderedEqs, eqns, reqns;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets) := isyst;
  (vars, fixvars, eqns, reqns) := iTpl;

  ((vars, fixvars)) := BackendVariable.traverseBackendDAEVars(orderedVars, collectInitialVars, (vars, fixvars));
  ((eqns, reqns)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, collectInitialEqns, (eqns, reqns));
  //((fixvars, eqns)) := List.fold(stateSets, collectInitialStateSetVars, (fixvars, eqns));

  oTpl := (vars, fixvars, eqns, reqns);
end collectInitialVarsEqnsSystem;

// protected function collectInitialStateSetVars "function collectInitialStateSetVars
//    author Frenkel TUD
//    add the vars for state set to the initial system
//    Because the statevars are calculated by
//    set.x = set.A*dummystates we add set.A to the
//    initial system with set.A = {{1, 0, 0}, {0, 1, 0}}"
//    input BackendDAE.StateSet inSet;
//    input tuple<BackendDAE.Variables, BackendDAE.EquationArray> iTpl;
//    output tuple<BackendDAE.Variables, BackendDAE.EquationArray> oTpl;
// protected
//   BackendDAE.Variables vars;
//   BackendDAE.EquationArray eqns;
//   DAE.ComponentRef crA;
//   list<BackendDAE.Var> varA, statevars;
//   Integer setsize, rang;
// algorithm
//   (vars, eqns) := iTpl;
//   BackendDAE.STATESET(rang=rang, crA=crA, statescandidates=statevars, varA=varA) := inSet;
//   vars := BackendVariable.addVars(varA, vars);
// //  setsize := listLength(statevars) - rang;
// //  eqns := addInitalSetEqns(setsize, intGt(rang, 1), crA, eqns);
//   oTpl := (vars, eqns);
// end collectInitialStateSetVars;
//
// protected function addInitalSetEqns
//   input Integer n;
//   input Boolean twoDims;
//   input DAE.ComponentRef crA;
//   input BackendDAE.EquationArray iEqns;
//   output BackendDAE.EquationArray oEqns;
// algorithm
//   oEqns := match(n, twoDims, crA, iEqns)
//     local
//       DAE.ComponentRef crA1;
//       DAE.Exp expcrA;
//       BackendDAE.EquationArray eqns;
//     case(0, _, _, _) then iEqns;
//     case(_, _, _, _) equation
//       crA1 = ComponentReference.subscriptCrefWithInt(crA, n);
//       crA1 = Debug.bcallret2(twoDims, ComponentReference.subscriptCrefWithInt, crA1, n, crA1);
//       expcrA = Expression.crefExp(crA1);
//       eqns = BackendEquation.equationAdd(BackendDAE.EQUATION(expcrA, DAE.ICONST(1), DAE.emptyElementSource, false), iEqns);
//     then addInitalSetEqns(n-1, twoDims, crA, eqns);
//   end match;
// end addInitalSetEqns;

protected function collectInitialVars "function collectInitialVars
  author: lochel
  This function collects all the vars for the initial system."
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var, preVar, derVar;
      BackendDAE.Variables vars, fixvars;
      DAE.ComponentRef cr, preCR, derCR;
      Boolean isFixed, isInput, b;
      DAE.Type ty;
      DAE.InstDims arryDim;
      Option<DAE.Exp> startValue;
      DAE.Exp startExp, bindExp;
      String errorMessage;
      BackendDAE.VarKind varKind;

    // state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(index=_), varType=ty, arryDim=arryDim), (vars, fixvars))) equation
      isFixed = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      //preused = BaseHashSet.has(cr, hs);

      derCR = ComponentReference.crefPrefixDer(cr);  // cr => $DER.cr
      derVar = BackendDAE.VAR(derCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());

      startValue = BackendVariable.varStartValueOption(var);
      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);

      vars = BackendVariable.addVar(derVar, vars);
      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, var, fixvars, fixvars);
      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, preVar, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then ((var, (vars, fixvars)));

    // discrete
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), (vars, fixvars))) equation
      isFixed = BackendVariable.varFixed(var);
      startValue = BackendVariable.varStartValueOption(var);

      var = BackendVariable.setVarFixed(var, false);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);

      vars = BackendVariable.addVar(var, vars);
      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, preVar, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then ((var, (vars, fixvars)));

    // parameter without binding
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=NONE()), (vars, fixvars))) equation
      true = BackendVariable.varFixed(var);
      startExp = BackendVariable.varStartValueType(var);
      var = BackendVariable.setBindExp(var, startExp);

      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars)));

    // parameter with constant binding
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars))) equation
      true = Expression.isConst(bindExp);
      fixvars = BackendVariable.addVar(var, fixvars);
    then ((var, (vars, fixvars)));

    // parameter
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM()), (vars, fixvars))) equation
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars)));

    // skip constant
    case((var as BackendDAE.VAR(varKind=BackendDAE.CONST()), (vars, fixvars))) // equation
      // fixvars = BackendVariable.addVar(var, fixvars);
    then ((var, (vars, fixvars)));

    case((var as BackendDAE.VAR(varName=cr, varKind=varKind, bindExp=NONE(), varType=ty, arryDim=arryDim), (vars, fixvars))) equation
      isFixed = BackendVariable.varFixed(var);
      isInput = BackendVariable.isVarOnTopLevelAndInput(var);
      //preused = BaseHashSet.has(cr, hs);
      b = isFixed or isInput;

      startValue = BackendVariable.varStartValueOption(var);
      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, varKind, DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);

      vars = Debug.bcallret2(not b, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(b, BackendVariable.addVar, var, fixvars, fixvars);
      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, preVar, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then ((var, (vars, fixvars)));

    case((var as BackendDAE.VAR(varName=cr, varKind=varKind, bindExp=SOME(bindExp), varType=ty, arryDim=arryDim), (vars, fixvars))) equation
      isInput = BackendVariable.isVarOnTopLevelAndInput(var);
      isFixed = Expression.isConst(bindExp);
      //preused = BaseHashSet.has(cr, hs);
      b = isInput or isFixed;

      startValue = BackendVariable.varStartValueOption(var);
      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, varKind, DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);

      vars = Debug.bcallret2(not b, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(b, BackendVariable.addVar, var, fixvars, fixvars);
      vars = BackendVariable.addVar(preVar, vars);
    then ((var, (vars, fixvars)));

    case ((var, _)) equation
      errorMessage = "./Compiler/BackEnd/Initialization.mo: function collectInitialVars failed for: " +& BackendDump.varString(var);
      Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
    then fail();

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/Initialization.mo: function collectInitialVars failed"});
    then fail();
  end matchcontinue;
end collectInitialVars;

protected function collectInitialAliasVars "function collectInitialAliasVars
  author: lochel
  This function collects all the vars for the initial system."
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables, list<BackendDAE.Var>>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables, list<BackendDAE.Var>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var, preVar;
      BackendDAE.Variables vars, fixvars;
      DAE.ComponentRef cr, preCR;
      Boolean isFixed;
      DAE.Type ty;
      DAE.InstDims arryDim;
      Option<DAE.Exp> startValue;
      list<BackendDAE.Var> tempVar;

    // discrete
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), (vars, fixvars, tempVar))) equation
      isFixed = BackendVariable.varFixed(var);
      startValue = BackendVariable.varStartValueOption(var);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);

      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, preVar, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then ((var, (vars, fixvars, preVar::tempVar)));

//  // pre used
//  case((var as BackendDAE.VAR(varName=cr, varKind=varKind, varType=ty, arryDim=arryDim), (vars, fixvars, hs, tempVar))) equation
//    true = BaseHashSet.has(cr, hs);
//
//    preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
//    preVar = BackendDAE.VAR(preCR, varKind, DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
//  then ((var, (vars, fixvars, hs, preVar::tempVar)));

    else then inTpl;
  end matchcontinue;
end collectInitialAliasVars;

protected function collectInitialBindings "function collectInitialBindings
  author: lochel
  This function collects all the vars for the initial system."
  input tuple<BackendDAE.Var, tuple<BackendDAE.EquationArray, BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.EquationArray, BackendDAE.EquationArray>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Type ty;
      String errorMessage;
      BackendDAE.EquationArray eqns, reeqns;
      DAE.Exp bindExp, crefExp;
      DAE.ElementSource source;
      BackendDAE.Equation eqn;

    // no binding
    case((var as BackendDAE.VAR(bindExp=NONE()), (eqns, reeqns))) equation
    then ((var, (eqns, reeqns)));

    // binding
    case((var as BackendDAE.VAR(varName=cr, bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns))) equation
      crefExp = DAE.CREF(cr, ty);
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source, false);
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (eqns, reeqns)));

    case ((var, _)) equation
      errorMessage = "./Compiler/BackEnd/Initialization.mo: function collectInitialBindings failed for: " +& BackendDump.varString(var);
      Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
    then fail();

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/Initialization.mo: function collectInitialBindings failed"});
    then fail();
  end match;
end collectInitialBindings;

protected function collectInitialEqns "function collectInitialEqns
  author: lochel"
  input tuple<BackendDAE.Equation, tuple<BackendDAE.EquationArray, BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.EquationArray, BackendDAE.EquationArray>> outTpl;
protected
  BackendDAE.Equation eqn, eqn1;
  BackendDAE.EquationArray eqns, reeqns;
  Integer size;
  Boolean b;
algorithm
  (eqn, (eqns, reeqns)) := inTpl;

  // replace der(x) with $DER.x and replace pre(x) with $PRE.x
  (eqn1, _) := BackendEquation.traverseBackendDAEExpsEqn(eqn, replaceDerPreCref, 0);

  // add it, if size is zero (terminate, assert, noretcall) move to removed equations
  size := BackendEquation.equationSize(eqn1);
  b := intGt(size, 0);

  eqns := Debug.bcallret2(b, BackendEquation.equationAdd, eqn1, eqns, eqns);
  reeqns := Debug.bcallret2(not b, BackendEquation.equationAdd, eqn1, reeqns, reeqns);
  outTpl := (eqn, (eqns, reeqns));
end collectInitialEqns;

protected function replaceDerPreCref "function replaceDerPreCref
  author: Frenkel TUD 2011-05
  helper for collectInitialEqns"
  input tuple<DAE.Exp, Integer> inExp;
  output tuple<DAE.Exp, Integer> outExp;
protected
   DAE.Exp e;
   Integer i;
algorithm
  (e, i) := inExp;
  outExp := Expression.traverseExp(e, replaceDerPreCrefExp, i);
end replaceDerPreCref;

protected function replaceDerPreCrefExp "function replaceDerPreCrefExp
  author: Frenkel TUD 2011-05
  helper for replaceDerCref"
  input tuple<DAE.Exp, Integer> inExp;
  output tuple<DAE.Exp, Integer> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.ComponentRef dummyder, cr;
      DAE.Type ty;
      Integer i;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty)), i)) equation
      dummyder = ComponentReference.crefPrefixDer(cr);
    then ((DAE.CREF(dummyder, ty), i+1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty)), i)) equation
      dummyder = ComponentReference.crefPrefixPre(cr);
    then ((DAE.CREF(dummyder, ty), i+1));

    else
    then inExp;
  end matchcontinue;
end replaceDerPreCrefExp;

end Initialization;
