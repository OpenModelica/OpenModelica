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

encapsulated package Initialization
" file:        Initialization.mo
  package:     Initialization
  description: Initialization.mo contains everything needed to set up the
               BackendDAE for the initial system.

  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import BackendDAEFunc;
public import DAE;
public import Env;
public import HashSet;
public import Util;

protected import BackendDAEEXT;
protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashSet;
protected import BaseHashTable;
protected import CheckModel;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashTable;
protected import HashTable2;
protected import List;
protected import Matching;
protected import Tearing;

// =============================================================================
// section for all public functions
//
// These are functions that can be used to access the initialization.
// =============================================================================

public function solveInitialSystem "author: lochel
  This function generates a algebraic system of equations for the initialization and solves it."
  input BackendDAE.BackendDAE inDAE;
  output Option<BackendDAE.BackendDAE> outInitDAE;
  output Boolean outUseHomotopy;
algorithm
  (outInitDAE, outUseHomotopy) := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables initVars;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.Variables knvars, vars, fixvars, evars, eavars, avars;
      BackendDAE.EquationArray inieqns, eqns, emptyeqns, reeqns;
      BackendDAE.EqSystem initsyst;
      BackendDAE.BackendDAE initdae;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree functionTree;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttrs;
      list<BackendDAE.Var> tempVar;
      Boolean b;
      HashSet.HashSet hs "contains all pre variables";
      list<tuple<BackendDAEFunc.postOptimizationDAEModule, String, Boolean>> pastOptModules;
      tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> daeHandler;
      tuple<BackendDAEFunc.matchingAlgorithmFunc, String> matchingAlgorithm;
      Boolean useHomotopy;
      list<BackendDAE.Var> dumpVars, dumpVars2;
      BackendDAE.ExtraInfo ei;

    case(_) equation
      // inline all when equations, if active with body else with lhs=pre(lhs)
      dae = inlineWhenForInitialization(inDAE);
      // Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, dae, "inlineWhenForInitialization");

      initVars = selectInitializationVariablesDAE(dae);
      // Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpVariables, initVars, "selected initialization variables");
      hs = collectPreVariables(dae);
      BackendDAE.DAE(systs, shared as BackendDAE.SHARED(knownVars=knvars,
                                                        aliasVars=avars,
                                                        initialEqs=inieqns,
                                                        constraints=constraints,
                                                        classAttrs=classAttrs,
                                                        cache=cache,
                                                        env=env,
                                                        functionTree=functionTree,
                                                        info = ei)) = dae;

      // collect vars and eqns for initial system
      vars = BackendVariable.emptyVars();
      fixvars = BackendVariable.emptyVars();
      eqns = BackendEquation.emptyEqns();
      reeqns = BackendEquation.emptyEqns();

      ((vars, fixvars, eqns, _)) = BackendVariable.traverseBackendDAEVars(avars, introducePreVarsForAliasVariables, (vars, fixvars, eqns, hs));
      ((vars, fixvars, eqns, _)) = BackendVariable.traverseBackendDAEVars(knvars, collectInitialVars, (vars, fixvars, eqns, hs));
      ((eqns, reeqns)) = BackendEquation.traverseBackendDAEEqns(inieqns, collectInitialEqns, (eqns, reeqns));

      // Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpEquationArray, eqns, "initial equations");

      ((vars, fixvars, eqns, reeqns, _)) = List.fold(systs, collectInitialVarsEqnsSystem, ((vars, fixvars, eqns, reeqns, hs)));
      ((eqns, reeqns)) = BackendVariable.traverseBackendDAEVars(vars, collectInitialBindings, (eqns, reeqns));

      // replace initial(), sample(...), delay(...) and homotopy(...)
      useHomotopy = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns, simplifyInitialFunctions, false);

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
                                 BackendDAE.EVENT_INFO({}, {}, {}, {}, {}, 0, 0),
                                 {},
                                 BackendDAE.INITIALSYSTEM(),
                                 {},
                                 ei);

      // generate initial system and pre-balance it
      initsyst = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
      (initsyst, dumpVars) = preBalanceInitialSystem(initsyst);

      // split the initial system into independend subsystems
      (systs, shared) = BackendDAEOptimize.partitionIndependentBlocksHelper(initsyst, shared, Error.getNumErrorMessages(), true);
      initdae = BackendDAE.DAE(systs, shared);
      // initdae = BackendDAE.DAE({initsyst}, shared);

      // fix over- and under-constrained subsystems
      (initdae, dumpVars2) = analyzeInitialSystem(initdae, dae, initVars);
      dumpVars = listAppend(dumpVars, dumpVars2);

      // some debug prints
      Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, initdae, "initial system");

      // now let's solve the system!
      (initdae, _) = BackendDAEUtil.mapEqSystemAndFold(initdae, solveInitialSystemEqSystem, dae);

      // transform and optimize DAE
      pastOptModules = BackendDAEUtil.getPostOptModules(SOME({"constantLinearSystem", /* here we need a special case and remove only alias and constant (no variables of the system) variables "removeSimpleEquations", */ "tearingSystem","calculateStrongComponentJacobians"}));
      matchingAlgorithm = BackendDAEUtil.getMatchingAlgorithm(NONE());
      daeHandler = BackendDAEUtil.getIndexReductionMethod(NONE());

      // solve system
      initdae = BackendDAEUtil.transformBackendDAE(initdae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());

      // simplify system
      (initdae, Util.SUCCESS()) = BackendDAEUtil.postOptimizeDAE(initdae, pastOptModules, matchingAlgorithm, daeHandler);
      Debug.fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, initdae, "solved initial system");
      Debug.bcall2(Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) and Flags.isSet(Flags.ADDITIONAL_GRAPHVIZ_DUMP), BackendDump.graphvizBackendDAE, initdae, "dumpinitialsystem");

      // warn about selected default initial conditions
      b = List.isNotEmpty(dumpVars);
      Debug.bcall(b and (not Flags.isSet(Flags.INITIALIZATION)), Error.addCompilerWarning, "The initial conditions are not fully specified. Use +d=initialization for more information.");
      Debug.bcall(b and Flags.isSet(Flags.INITIALIZATION), Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(listLength(dumpVars)) +& " variables:\n" +& warnAboutVars2(dumpVars));

      // warn about iteration variables with default zero start attribute
      b = warnAboutIterationVariablesWithDefaultZeroStartAttribute(initdae);
      Debug.bcall(b and (not Flags.isSet(Flags.INITIALIZATION)), Error.addCompilerWarning, "There are iteration variables with default zero start attribute. Use +d=initialization for more information.");

      b = Flags.isSet(Flags.DUMP_EQNINORDER) and Flags.isSet(Flags.DUMP_INITIAL_SYSTEM);
      Debug.bcall2(b, BackendDump.dumpEqnsSolved, initdae, "initial system: eqns in order");

      Debug.fcall(Flags.ITERATION_VARS, BackendDAEOptimize.listAllIterationVariables, initdae);
    then (SOME(initdae), useHomotopy);

    else (NONE(), false);
  end matchcontinue;
end solveInitialSystem;

// =============================================================================
// section for helper functions of solveInitialSystem
//
// =============================================================================

protected function solveInitialSystemEqSystem "author: lochel
  This is a helper function of solveInitialSystem and solves the generated system."
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, BackendDAE.BackendDAE> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, BackendDAE.BackendDAE> osharedOptimized;
algorithm
  (osyst, osharedOptimized) := matchcontinue(isyst, sharedOptimized)
    local
      Integer nVars, nEqns;

    // over-determined system: nEqns > nVars
    case(_, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intGt(nEqns, nVars);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "It was not possible to solve the over-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)");
    then fail();

    // determined system: nEqns = nVars
    case( _, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intEq(nEqns, nVars);
    then (isyst, sharedOptimized);

    // under-determined system: nEqns < nVars
    case( _, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intLt(nEqns, nVars);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "It was not possible to solve the under-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)");
    then fail();
  end matchcontinue;
end solveInitialSystemEqSystem;

// =============================================================================
// section for inlining when-clauses
//
// This section contains all the helper functions to replace all when-clauses
// from a given BackenDAE to get the initial equation system.
// =============================================================================

protected function inlineWhenForInitialization "author: lochel
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

protected function inlineWhenForInitializationSystem "author: lochel
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

protected function inlineWhenForInitializationEquation "author: lochel
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
      DAE.Expand crefExpand;
      BackendDAE.EquationKind eqKind;

    // when equation during initialization
    case ((eqn as BackendDAE.WHEN_EQUATION(whenEquation=weqn, source=source, kind=eqKind), (vars, eqns))) equation
      (eqns, vars) = inlineWhenForInitializationWhenEquation(weqn, source, eqKind, eqns, vars);
    then ((eqn, (vars, eqns)));

    // algorithm
    case ((eqn as BackendDAE.ALGORITHM(alg=alg, source=source,expand=crefExpand), (vars, eqns))) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg;
      (stmts, leftCrs) = generateInitialWhenAlg(stmts, true, {}, HashTable.emptyHashTableSized(50));
      alg = DAE.ALGORITHM_STMTS(stmts);
      size = listLength(CheckModel.algorithmOutputs(alg, crefExpand));
      crintLst = BaseHashTable.hashTableList(leftCrs);
      crefLst = List.fold(crintLst, selectSecondZero, {});
      (eqns, vars) = generateInactiveWhenEquationForInitialization(crefLst, source, eqns, vars);
      eqns = List.consOnTrue(List.isNotEmpty(stmts), BackendDAE.ALGORITHM(size, alg, source, crefExpand, BackendDAE.INITIAL_EQUATION()), eqns);
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

protected function inlineWhenForInitializationWhenEquation "author: lochel
  This is a helper function for inlineWhenForInitializationEquation."
  input BackendDAE.WhenEquation inWEqn;
  input DAE.ElementSource source;
  input BackendDAE.EquationKind inEqKind;
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Variables iVars;
  output list<BackendDAE.Equation> oEqns;
  output BackendDAE.Variables oVars;
algorithm
  (oEqns, oVars) := matchcontinue(inWEqn, source, inEqKind, iEqns, iVars)
    local
      DAE.ComponentRef left;
      DAE.Exp condition, right, crexp;
      BackendDAE.Equation eqn;
      DAE.Type identType;
      list< BackendDAE.Equation> eqns;
      BackendDAE.WhenEquation weqn;
      BackendDAE.Variables vars;

    // active when equation during initialization
    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right), _, _, _, _) equation
      true = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExp
      crexp = Expression.crefExp(left);
      identType = Expression.typeof(crexp);
      eqn = BackendEquation.generateEquation(crexp, right, identType, source, false, inEqKind);
    then (eqn::iEqns, iVars);

    // inactive when equation during initialization
    case (BackendDAE.WHEN_EQ(condition=condition, left=left,  elsewhenPart=NONE()), _, _, _, _) equation
      false = Expression.containsInitialCall(condition, false);
      (eqns,_) = generateInactiveWhenEquationForInitialization({left}, source, iEqns, iVars);
    then (eqns, iVars);

    // inactive when equation during initialization with else when part (no strict Modelica)
    case (BackendDAE.WHEN_EQ(condition=condition,   elsewhenPart=SOME(weqn)), _, _, _, _) equation
      false = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExp
      (eqns, vars) = inlineWhenForInitializationWhenEquation(weqn, source, inEqKind, iEqns, iVars);
    then (eqns, vars);
  end matchcontinue;
end inlineWhenForInitializationWhenEquation;

protected function generateInitialWhenAlg "author: lochel
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
    case ((DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=NONE()))::{}, true, _, _) equation
      false = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      _ = List.map1(crefLst, Util.makeTuple, 1);
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

protected function inlineWhenForInitializationWhenStmt "author: lochel
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
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      crintLst = List.map1(crefLst, Util.makeTuple, 1);
      leftCrs = List.fold(crintLst, BaseHashTable.add, iLeftCrs);
      stmts = List.foldr(stmts, List.consr, inAcc);
    then (stmts, leftCrs);

    case (DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=SOME(stmt)), false, _, _) equation
      true = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      crintLst = List.map1(crefLst, Util.makeTuple, 1);
      leftCrs = List.fold(crintLst, BaseHashTable.add, iLeftCrs);
      stmts = List.foldr(stmts, List.consr, inAcc);
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, true, leftCrs, stmts);
    then (stmts, leftCrs);

    // inactive when equation during initialization
    case (DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=NONE()), _, _, _) equation
      false = Expression.containsInitialCall(condition, false) and not foundAktiv;
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      leftCrs = List.fold(crefLst, addWhenLeftCr, iLeftCrs);
    then (inAcc, leftCrs);

    // inactive when equation during initialization with elsewhen part
    case (DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=SOME(stmt)), _, _, _) equation
      false = Expression.containsInitialCall(condition, false) and not foundAktiv;
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      leftCrs = List.fold(crefLst, addWhenLeftCr, iLeftCrs);
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, foundAktiv, leftCrs, inAcc);
    then (stmts, leftCrs);

    else equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function inlineWhenForInitializationWhenStmt failed");
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

    else iLeftCrs;
  end matchcontinue;
end addWhenLeftCr;

protected function generateInactiveWhenEquationForInitialization "author: lochel
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
      DAE.Exp crefExp, crefPreExp;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Variables vars;

    case ({}, _, _, _)
    then (inEqns, iVars);

    case (cr::rest, _, _, _) equation
      identType = ComponentReference.crefTypeConsiderSubs(cr);
      crefExp = DAE.CREF(cr, identType);
      crefPreExp = Expression.makePureBuiltinCall("pre", {crefExp}, DAE.T_BOOL_DEFAULT);
      eqn = BackendDAE.EQUATION(crefExp, crefPreExp, inSource, false, BackendDAE.INITIAL_EQUATION());
      (eqns, vars) = generateInactiveWhenEquationForInitialization(rest, inSource, eqn::inEqns, iVars);
    then (eqns, vars);
 end match;
end generateInactiveWhenEquationForInitialization;

// =============================================================================
// section for collecting all variables, of which the left limit is also used.
//
// collect all pre variables in time equations
// =============================================================================

protected function collectPreVariables "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  output HashSet.HashSet outHS;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.EquationArray ieqns, removedEqs;
  // list<DAE.ComponentRef> crefs;
algorithm
  // BackendDump.dumpBackendDAE(inDAE, "inDAE");
  BackendDAE.DAE(systs, BackendDAE.SHARED(removedEqs=removedEqs, initialEqs=ieqns)) := inDAE;

  outHS := HashSet.emptyHashSet();
  outHS := List.fold(systs, collectPreVariablesEqSystem, outHS);
  outHS := BackendDAEUtil.traverseBackendDAEExpsEqns(removedEqs, collectPreVariablesEquation, outHS); // ???
  outHS := BackendDAEUtil.traverseBackendDAEExpsEqns(ieqns, collectPreVariablesEquation, outHS);

  // print("collectPreVariables:\n");
  // crefs := BaseHashSet.hashSetList(outHS);
  // BackendDump.debuglst((crefs,ComponentReference.printComponentRefStr,"\n","\n"));
end collectPreVariables;

public function collectPreVariablesEquation "author: lochel"
  input tuple<DAE.Exp, HashSet.HashSet> inTpl;
  output tuple<DAE.Exp, HashSet.HashSet> outTpl;
protected
  DAE.Exp e;
  HashSet.HashSet hs;
algorithm
  (e, hs) := inTpl;
  ((_, hs)) := Expression.traverseExp(e, collectPreVariablesTrverseExp, hs);
  outTpl := (e, hs);
end collectPreVariablesEquation;

public function collectPreVariablesEqSystem "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  input HashSet.HashSet inHS;
  output HashSet.HashSet outHS;
protected
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := inEqSystem;
  outHS := BackendDAEUtil.traverseBackendDAEExpsEqns(orderedEqs, collectPreVariablesTrverseExpsEqns, inHS);
end collectPreVariablesEqSystem;

protected function collectPreVariablesTrverseExpsEqns "author: lochel"
  input tuple<DAE.Exp, HashSet.HashSet> inTpl;
  output tuple<DAE.Exp, HashSet.HashSet> outTpl;
protected
  DAE.Exp e;
  HashSet.HashSet hs;
algorithm
  (e, hs) := inTpl;
  ((_, hs)) := Expression.traverseExp(e, collectPreVariablesTrverseExp, hs);
  outTpl := (e, hs);
end collectPreVariablesTrverseExpsEqns;

protected function collectPreVariablesTrverseExp "author: lochel"
  input tuple<DAE.Exp, HashSet.HashSet> inTpl;
  output tuple<DAE.Exp, HashSet.HashSet> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      HashSet.HashSet hs;
    case ((e as DAE.CALL(path=Absyn.IDENT(name="pre")), hs)) equation
      ((_, hs)) = Expression.traverseExp(e, collectPreVariablesTrverseExp2, hs);
    then ((e, hs));

    case ((e as DAE.CALL(path=Absyn.IDENT(name="change")), hs)) equation
      ((_, hs)) = Expression.traverseExp(e, collectPreVariablesTrverseExp2, hs);
    then ((e, hs));

    case ((e as DAE.CALL(path=Absyn.IDENT(name="edge")), hs)) equation
      ((_, hs)) = Expression.traverseExp(e, collectPreVariablesTrverseExp2, hs);
    then ((e, hs));

    else inTpl;
  end match;
end collectPreVariablesTrverseExp;

protected function collectPreVariablesTrverseExp2 "author: lochel"
  input tuple<DAE.Exp, HashSet.HashSet> inTpl;
  output tuple<DAE.Exp, HashSet.HashSet> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef cr;
      HashSet.HashSet hs;
      DAE.Exp e;

    case((e as DAE.CREF(componentRef=cr), hs)) equation
      crefs = ComponentReference.expandCref(cr, true);
      hs = List.fold(crefs, BaseHashSet.add, hs);
    then ((e, hs));

    else inTpl;
  end match;
end collectPreVariablesTrverseExp2;

// =============================================================================
// warn about iteration variables with default zero start attribute
//
// =============================================================================

protected function warnAboutIterationVariablesWithDefaultZeroStartAttribute "author: lochel
  This function ... read the function name."
  input BackendDAE.BackendDAE inBackendDAE;
  output Boolean outWarning;
protected
  list<BackendDAE.EqSystem> eqs;
algorithm
  BackendDAE.DAE(eqs=eqs) := inBackendDAE;
  outWarning := warnAboutIterationVariablesWithDefaultZeroStartAttribute0(eqs);
end warnAboutIterationVariablesWithDefaultZeroStartAttribute;

protected function warnAboutIterationVariablesWithDefaultZeroStartAttribute0 "author: lochel"
  input list<BackendDAE.EqSystem> inEqs;
  output Boolean outWarning;
algorithm
  outWarning := match(inEqs)
    local
      Boolean b1, b2;
      BackendDAE.EqSystem eq;
      list<BackendDAE.EqSystem> eqs;
    case ({}) then false;
    case (eq::eqs) equation
      b1 = warnAboutIterationVariablesWithDefaultZeroStartAttribute0(eqs);
      b2 = warnAboutIterationVariablesWithDefaultZeroStartAttribute1(eq);
    then (b1 or b2);
  end match;
end warnAboutIterationVariablesWithDefaultZeroStartAttribute0;

protected function warnAboutIterationVariablesWithDefaultZeroStartAttribute1 "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  output Boolean outWarning;
protected
  BackendDAE.Variables vars;
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,
                      matching=BackendDAE.MATCHING(comps=comps)) := inEqSystem;
  outWarning := warnAboutIterationVariablesWithDefaultZeroStartAttribute2(comps, vars);
end warnAboutIterationVariablesWithDefaultZeroStartAttribute1;

protected function warnAboutIterationVariablesWithDefaultZeroStartAttribute2 "author: lochel"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.Variables inVars;
  output Boolean outWarning;
algorithm
  outWarning := matchcontinue(inComps, inVars)
    local
      BackendDAE.StrongComponents rest;
      list<BackendDAE.Var> varlst;
      list<Integer> vlst;
      Boolean linear, b;
      String str;

    case ({}, _) then false;

    case (BackendDAE.MIXEDEQUATIONSYSTEM(disc_vars=vlst)::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      varlst = filterVarsWithoutStartValue(varlst);
      false = List.isEmpty(varlst);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "Iteration variables with default zero start attribute in mixed equation system:\n" +& warnAboutVars2(varlst));
      _ = warnAboutIterationVariablesWithDefaultZeroStartAttribute2(rest, inVars);
    then true;

    case (BackendDAE.EQUATIONSYSTEM(vars=vlst, jacType=BackendDAE.JAC_NONLINEAR())::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      varlst = filterVarsWithoutStartValue(varlst);
      false = List.isEmpty(varlst);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "Iteration variables with default zero start attribute in nonlinear equation system:\n" +& warnAboutVars2(varlst));
      _ = warnAboutIterationVariablesWithDefaultZeroStartAttribute2(rest, inVars);
    then true;

     case (BackendDAE.EQUATIONSYSTEM(vars=vlst, jacType=BackendDAE.JAC_GENERIC())::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      varlst = filterVarsWithoutStartValue(varlst);
      false = List.isEmpty(varlst);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "Iteration variables with default zero start attribute in equation system w/o analytic Jacobian:\n" +& warnAboutVars2(varlst));
      _ = warnAboutIterationVariablesWithDefaultZeroStartAttribute2(rest, inVars);
    then true;

    case (BackendDAE.EQUATIONSYSTEM(vars=vlst, jacType=BackendDAE.JAC_NO_ANALYTIC())::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      varlst = filterVarsWithoutStartValue(varlst);
      false = List.isEmpty(varlst);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "Iteration variables with default zero start attribute in equation system w/o analytic Jacobian:\n" +& warnAboutVars2(varlst));
      _ = warnAboutIterationVariablesWithDefaultZeroStartAttribute2(rest, inVars);
    then true;

    case (BackendDAE.TORNSYSTEM(tearingvars=vlst, linear=linear)::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      varlst = filterVarsWithoutStartValue(varlst);
      false = List.isEmpty(varlst);

      str = Util.if_(linear, "linear", "nonlinear");
      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "Iteration variables with default zero start attribute in torn " +& str +& " equation system:\n" +& warnAboutVars2(varlst));
      _ = warnAboutIterationVariablesWithDefaultZeroStartAttribute2(rest, inVars);
    then true;

    case (_::rest, _) equation
      b = warnAboutIterationVariablesWithDefaultZeroStartAttribute2(rest, inVars);
    then b;
  end matchcontinue;
end warnAboutIterationVariablesWithDefaultZeroStartAttribute2;

function filterVarsWithoutStartValue "author: lochel"
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vars;

    case ({}) then {};

    case (v::vars) equation
      _ = BackendVariable.varStartValueFail(v);
      vars = filterVarsWithoutStartValue(vars);
    then vars;

    case (v::vars) equation
      vars = filterVarsWithoutStartValue(vars);
    then v::vars;

    else fail();
  end matchcontinue;
end filterVarsWithoutStartValue;

function warnAboutVars2 "author: lochel
  TODO: Replace this with an general BackendDump implementation."
  input list<BackendDAE.Var> inVars;
  output String outString;
algorithm
  outString := match(inVars)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vars;
      String crStr;
      String str;

    case ({}) then "";

    case (v::{}) equation
      crStr = "         " +& BackendDump.varString(v);
    then crStr;

    case (v::vars) equation
      crStr = BackendDump.varString(v);
      str = "         " +& crStr +& "\n" +& warnAboutVars2(vars);
    then str;
  end match;
end warnAboutVars2;

// =============================================================================
// section for selecting initialization variables
//
//   - unfixed state
//   - unfixed parameter
//   - unfixed discrete -> pre(vd)
// =============================================================================

protected function selectInitializationVariablesDAE "author: lochel
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

protected function selectInitializationVariables "author: lochel"
  input BackendDAE.EqSystems inEqSystems;
  output BackendDAE.Variables outVars;
algorithm
  outVars := BackendVariable.emptyVars();
  outVars := List.fold(inEqSystems, selectInitializationVariables1, outVars);
end selectInitializationVariables;

protected function selectInitializationVariables1 "author: lochel"
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

protected function selectInitializationVariables2 "author: lochel"
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
    case((var as BackendDAE.VAR(varName=_, varKind=BackendDAE.STATE(index=_)), vars)) equation
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

// =============================================================================
// section for simplifying initial functions
//
// =============================================================================

protected function simplifyInitialFunctions "author: Frenkel TUD 2012-12
  simplify initial() with true and sample with false"
  input tuple<DAE.Exp, Boolean /* homotopy used? */> inTpl;
  output tuple<DAE.Exp, Boolean /* homotopy used? */> outTpl;
protected
  DAE.Exp exp;
  Boolean useHomotopy;
algorithm
  (exp, useHomotopy) := inTpl;
  outTpl := Expression.traverseExp(exp, simplifyInitialFunctionsExp, useHomotopy);
end simplifyInitialFunctions;

protected function simplifyInitialFunctionsExp "author: Frenkel TUD 2012-12
  helper for simplifyInitialFunctions"
  input tuple<DAE.Exp, Boolean /* homotopy used? */> inExp;
  output tuple<DAE.Exp, Boolean /* homotopy used? */> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e1, e2, e3, actual, simplified;
      Boolean useHomotopy;
    case ((DAE.CALL(path = Absyn.IDENT(name="initial")), useHomotopy)) then ((DAE.BCONST(true), useHomotopy));
    case ((DAE.CALL(path = Absyn.IDENT(name="sample")), useHomotopy)) then ((DAE.BCONST(false), useHomotopy));
    case ((DAE.CALL(path = Absyn.IDENT(name="delay"), expLst = _::e1::_ ), useHomotopy)) then ((e1, useHomotopy));
    case ((DAE.CALL(path = Absyn.IDENT(name="homotopy"), expLst = actual::simplified::_ ), _)) equation
      e1 = Expression.makePureBuiltinCall("homotopyParameter", {}, DAE.T_REAL_DEFAULT);
      e2 = DAE.BINARY(e1, DAE.MUL(DAE.T_REAL_DEFAULT), actual);
      e3 = DAE.BINARY(DAE.RCONST(1.0), DAE.SUB(DAE.T_REAL_DEFAULT), e1);
      e1 = DAE.BINARY(e3, DAE.MUL(DAE.T_REAL_DEFAULT), simplified);
      e3 = DAE.BINARY(e2, DAE.ADD(DAE.T_REAL_DEFAULT), e1);
    then ((e3, true));
    else inExp;
  end matchcontinue;
end simplifyInitialFunctionsExp;

// =============================================================================
// section for pre-balancing the initial system
//
// This section removes unused pre variables and auto-fixes non-pre variables,
// which occure in no equation.
// =============================================================================

protected function preBalanceInitialSystem "author: lochel"
  input BackendDAE.EqSystem inSystem;
  output BackendDAE.EqSystem outSystem;
  output list<BackendDAE.Var> outDumpVars;
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
  (orderedVars, orderedEqs, b, outDumpVars) := preBalanceInitialSystem1(arrayLength(mt), mt, orderedVars, orderedEqs, false, {});
  outSystem := Util.if_(b, BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets), inSystem);
end preBalanceInitialSystem;

protected function preBalanceInitialSystem1 "author: lochel"
  input Integer n;
  input BackendDAE.IncidenceMatrix mt;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs;
  input Boolean iB;
  input list<BackendDAE.Var> inDumpVars;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqs;
  output Boolean oB;
  output list<BackendDAE.Var> outDumpVars;
algorithm
  (outVars, outEqs, oB, outDumpVars) := match (n, mt, inVars, inEqs, iB, inDumpVars)
    local
      list<Integer> row;
      Boolean b, useHomotopy;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqs;
      list<BackendDAE.Var> rvarlst;
      BackendDAE.Var var;
      DAE.ComponentRef cref;
      list<BackendDAE.Var> dumpVars;

    case(0, _, _, _, false, _)
    then (inVars, inEqs, false, inDumpVars);

    case(0, _, _, _, true, _) equation
      vars = BackendVariable.listVar1(BackendVariable.varList(inVars));
    then (vars, inEqs, true, inDumpVars);

    case(_, _, _, _, _, _) equation
      true = n > 0;
      (vars, eqs, b, dumpVars) = preBalanceInitialSystem2(n, mt, inVars, inEqs, iB, inDumpVars);
      (vars, eqs, b, dumpVars) = preBalanceInitialSystem1(n-1, mt, vars, eqs, b, dumpVars);
    then (vars, eqs, b, dumpVars);

  end match;
end preBalanceInitialSystem1;

protected function preBalanceInitialSystem2 "author: lochel"
  input Integer n;
  input BackendDAE.IncidenceMatrix mt;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs;
  input Boolean iB;
  input list<BackendDAE.Var> inDumpVars;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqs;
  output Boolean oB;
  output list<BackendDAE.Var> outDumpVars;
algorithm
  (outVars, outEqs, oB, outDumpVars) := matchcontinue(n, mt, inVars, inEqs, iB, inDumpVars)
    local
      list<Integer> row;
      Boolean b, useHomotopy;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqs;
      list<BackendDAE.Var> rvarlst;
      BackendDAE.Var var;
      DAE.ComponentRef cref;
      list<BackendDAE.Var> dumpVars;

    case(_, _, _, _, _, _) equation
      row = mt[n];
      true = List.isEmpty(row);

      var = BackendVariable.getVarAt(inVars, n);
      cref = BackendVariable.varCref(var);
      true = ComponentReference.isPreCref(cref);

      (vars, _) = BackendVariable.removeVars({n}, inVars, {});
    then (vars, inEqs, true, inDumpVars);

    case(_, _, _, _, _, _) equation
      row = mt[n];
      true = List.isEmpty(row);

      var = BackendVariable.getVarAt(inVars, n);
      cref = BackendVariable.varCref(var);
      false = ComponentReference.isPreCref(cref);

      (eqs, dumpVars) = addStartValueEquations({var}, inEqs, inDumpVars);
    then (inVars, eqs, true, dumpVars);

    case(_, _, _, _, _, _) equation
      row = mt[n];
      false = List.isEmpty(row);
    then (inVars, inEqs, iB, inDumpVars);

    else equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function preBalanceInitialSystem1 failed");
    then fail();
  end matchcontinue;
end preBalanceInitialSystem2;

protected function analyzeInitialSystem "author: lochel
  This function fixes discrete and state variables to balance the initial equation system."
  input BackendDAE.BackendDAE initDAE;
  input BackendDAE.BackendDAE inDAE;      // original DAE
  input BackendDAE.Variables inInitVars;
  output BackendDAE.BackendDAE outDAE;
  output list<BackendDAE.Var> outDumpVars;
algorithm
  (outDAE, (_, _, outDumpVars)) := BackendDAEUtil.mapEqSystemAndFold(initDAE, analyzeInitialSystem2, (inDAE, inInitVars, {}));
end analyzeInitialSystem;

protected function getConsistentEquations "author: mwenzler"
  input list<Integer> inUnassignedEqns;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.EquationArray inEqnsOrig;
  input BackendDAE.IncidenceMatrix inM;
  input array<Integer> vecVarToEqs;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared shared;
  output list<Integer> outUnassignedEqns;
  output Boolean outConsistent;
algorithm
  (outUnassignedEqns, outConsistent) := matchcontinue(inUnassignedEqns, inEqns, inEqnsOrig, inM,vecVarToEqs, vars, shared)
    local
      Integer currEqID, currVarID, currID;
      list<Integer> unassignedEqns, unassignedEqns2, listVar;
      list<BackendDAE.Equation> eqns_list;
      list<BackendDAE.Equation> eqns_list_new;
      list<BackendDAE.Equation> eqns_list2;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn, eqn2;
      DAE.Exp lhs, rhs, exp, x;
      String eqStr;
      BackendDAE.Var var;
      DAE.ComponentRef cref;
      BackendDAE.Type type_;
      Boolean consistent;
      list<String> listParameter;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.EqSystem system;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> list_inEqns;

    case ({}, _, _, _, _, _, _)
    then ({}, true);

    case (currID::unassignedEqns, _, _, _, _, _, _) equation
      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      true = Expression.isZero(exp);

      //((_,listParameter))=parameterCheck((exp,{}));
      //false=intGt(listLength(listParameter),0);
      eqn = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerNotification("The following equation is consistent and got removed from the initialization problem: " +& BackendDump.equationString(eqn));

      (unassignedEqns2, consistent) = getConsistentEquations(unassignedEqns, inEqns, inEqnsOrig, inM, vecVarToEqs, vars, shared);
    then (currID::unassignedEqns2, consistent);

    case (currID::unassignedEqns, _, _, _, _, _, _) equation
      true=emptyListOfIncidenceMatrix({currID},inM,vecVarToEqs, false);
      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_,listParameter))=parameterCheck((exp,{}));
      false=intGt(listLength(listParameter),0);

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerError("The initialization problem is inconsistent due to the following equation: " +& BackendDump.equationString(eqn2) +& " (" +& BackendDump.equationString(eqn) +& ")");

      (unassignedEqns2, consistent) = getConsistentEquations(unassignedEqns, inEqns, inEqnsOrig, inM, vecVarToEqs, vars, shared);
    then ({}, false);

    case (currID::unassignedEqns, _, _, _, _, _, _) equation
      true=emptyListOfIncidenceMatrix({currID},inM,vecVarToEqs, false);
      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_,listParameter))=parameterCheck((exp,{}));
      true=intGt(listLength(listParameter),0);

      list_inEqns=BackendEquation.equationList(inEqns);
      list_inEqns = List.set(list_inEqns, currID, eqn);
      eqns = BackendEquation.listEquation(list_inEqns);
      funcs = BackendDAEUtil.getFunctions(shared);
      system = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
      (_, m, _, _, _) = BackendDAEUtil.getIncidenceMatrixScalar(system, BackendDAE.NORMAL(), SOME(funcs));
      listVar=m[currID];
      false=intEq(0,listLength(listVar));

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerNotification("It was not possible to analyze the given system symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");

      (unassignedEqns2, consistent) = getConsistentEquations(unassignedEqns, inEqns, inEqnsOrig, inM, vecVarToEqs, vars, shared);
    then ({}, false);

    case (currID::unassignedEqns, _, _, _, _, _, _) equation
      //true = intEq(listLength(inM[currID]), 0);
      true=emptyListOfIncidenceMatrix({currID},inM,vecVarToEqs, false);
      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_,listParameter))=parameterCheck((exp,{}));
      true=intGt(listLength(listParameter),0);

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerError("It was not possible to determine if the initialization problem is consistent, because of not evaluable parameters during compile time: " +& BackendDump.equationString(eqn2) +& " (" +& BackendDump.equationString(eqn) +& ")");

     then ({}, false);

    case (currID::unassignedEqns, _, _, _, _ , _, _) equation
      false=emptyListOfIncidenceMatrix({currID},inM,vecVarToEqs, true);
      (unassignedEqns2, consistent) = getConsistentEquations(unassignedEqns, inEqns, inEqnsOrig, inM, vecVarToEqs,vars, shared);
    then (unassignedEqns2, consistent);
  end matchcontinue;
end getConsistentEquations;

protected function parameterCheck "author: mwenzler"
   input tuple<DAE.Exp,list<String>> inExp;
  output tuple<DAE.Exp,list<String>> outExp;
protected
  DAE.Exp e;
  list<String> listParameter;
algorithm
  (e, listParameter) := inExp;
  outExp := Expression.traverseExp(e, parameterCheck2,{});
end parameterCheck;

protected function parameterCheck2
  input tuple<DAE.Exp,list<String>> inExp;
  output tuple<DAE.Exp,list<String>> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Type ty;
      String Para;
      list<String> listParameter;
      DAE.Exp exp;

    case((exp as DAE.CREF(componentRef=DAE.CREF_QUAL(ident=Para), ty=ty ),listParameter)) equation
      listParameter=listAppend({Para},listParameter);
    then ((exp,listParameter));

    case((exp as DAE.CREF(componentRef=DAE.CREF_IDENT(ident=Para), ty=ty ),listParameter)) equation
      listParameter=listAppend({Para},listParameter);
    then ((exp,listParameter));

    case((exp as DAE.CREF(componentRef=DAE.CREF_ITER(ident=Para), ty=ty ),listParameter)) equation
      listParameter=listAppend({Para},listParameter);
    then ((exp,listParameter));

    else equation
      (exp,listParameter)=inExp;
    then ((exp,listParameter));
  end matchcontinue;
end parameterCheck2;

protected function manipulatedAdjacencyMatrixEnhanced "author: mwenzler"
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input Integer counter;
  output BackendDAE.AdjacencyMatrixEnhanced meOut;
algorithm
  meOut:= matchcontinue(meIn,counter)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced elem;

    case(_,_) equation
      true = counter <= arrayLength(meIn);
      elem=manipulatedAdjacencyMatrixEnhanced2(meIn[counter],{});
       meOut = Util.arrayReplaceAtWithFill(counter,elem,elem,meIn);
    then manipulatedAdjacencyMatrixEnhanced(meOut,counter+1);

    case(_,_) equation
      false = counter <= arrayLength(meIn);
    then meIn;
  end matchcontinue;
end manipulatedAdjacencyMatrixEnhanced;

protected function manipulatedAdjacencyMatrixEnhanced2
  input BackendDAE.AdjacencyMatrixElementEnhanced Inelem;
  input BackendDAE.AdjacencyMatrixElementEnhanced Newelem;
  output BackendDAE.AdjacencyMatrixElementEnhanced Outelem;
algorithm
  Outelem := matchcontinue (Inelem,Newelem)
    local
      Integer int;
      BackendDAE.AdjacencyMatrixElementEnhanced elem;
      BackendDAE.AdjacencyMatrixElementEnhancedEntry index;

    case ({},_)
    then listReverse(Newelem);

    case ((index as (int,BackendDAE.SOLVABILITY_SOLVED()))::elem,_)
    then manipulatedAdjacencyMatrixEnhanced2(elem,index::Newelem);

    case ((index as (int,BackendDAE.SOLVABILITY_UNSOLVABLE()))::elem,_)
    then manipulatedAdjacencyMatrixEnhanced2(elem,index::Newelem);

    case ((int,_)::elem,_)
    then manipulatedAdjacencyMatrixEnhanced2(elem,(int,BackendDAE.SOLVABILITY_CONSTONE())::Newelem);
  end matchcontinue;
end manipulatedAdjacencyMatrixEnhanced2;

protected function compsMarker "author: mwenzler"
  input list<Integer> unassignedEqns;
  input array<Integer> vecVarToEq;
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> flatComps;
  input list<Integer> markerComps;
  input list<Integer> markerEq;
  output list<Integer> outMarkerComps; // Marker list Comps
  output list<Integer> outMarkerEq;  // Marker 1...n

algorithm
  (outMarkerComps,outMarkerEq) := matchcontinue (unassignedEqns, vecVarToEq, m,flatComps, markerComps,markerEq)
    local
      list<Integer> unassignedEqns2, var_list;
      Integer indexUnassigned;

    case({},_,_,_,_,_) equation
      (outMarkerComps,outMarkerEq)=downCompsMarker(listReverse(flatComps), vecVarToEq, m, flatComps, markerComps, markerEq);
    then (outMarkerComps,outMarkerEq);

    case(indexUnassigned :: unassignedEqns2, _, _,_,_, _) equation
      var_list=m[indexUnassigned];
      (outMarkerComps,outMarkerEq)=compsMarker2(var_list, vecVarToEq, m,flatComps, markerComps, markerEq);
      (outMarkerComps,outMarkerEq)=compsMarker(unassignedEqns2, vecVarToEq, m, flatComps, outMarkerComps, outMarkerEq);
    then (outMarkerComps,outMarkerEq);
  end matchcontinue;
end compsMarker;

protected function downCompsMarker
  input list<Integer> unassignedEqns;
  input array<Integer> vecVarToEq;
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> flatComps;
  input list<Integer> markerComps;
  input list<Integer> markerEq;
  output list<Integer> outMarkerComps;
  output list<Integer> outMarkerEq;
algorithm
  (outMarkerComps,outMarkerEq) := matchcontinue (unassignedEqns, vecVarToEq, m,flatComps, markerComps,markerEq)
    local
      list<Integer> unassignedEqns2, var_list;
      Integer indexUnassigned, marker;

    case({},_,_,_,_,_)
    then (markerComps,markerEq);

    case(indexUnassigned :: unassignedEqns2, _, _,_,_, _) equation
      marker=listGet(markerEq,indexUnassigned);
      true = intEq(marker,1);
      var_list=m[indexUnassigned];
      (outMarkerComps,outMarkerEq)=compsMarker2(var_list, vecVarToEq, m,flatComps, markerComps, markerEq);
      (outMarkerComps,outMarkerEq)=downCompsMarker(unassignedEqns2, vecVarToEq, m, flatComps, outMarkerComps, outMarkerEq);
    then (outMarkerComps,outMarkerEq);

    case(indexUnassigned :: unassignedEqns2, _, _,_,_, _) equation
      (outMarkerComps,outMarkerEq)=downCompsMarker(unassignedEqns2, vecVarToEq, m, flatComps, markerComps, markerEq);
    then (outMarkerComps,outMarkerEq);
  end matchcontinue;
end downCompsMarker;

protected function compsMarker2
  input list<Integer> var_list;
  input array<Integer> vecVarToEq;
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> flatComps;
  input list<Integer> markerComps;
  input list<Integer> markerEq;
  output list<Integer> outMarkerComps;
  output list<Integer> outMarkerEq;
algorithm
  (outMarkerComps,outMarkerEq) := matchcontinue (var_list, vecVarToEq, m, flatComps, markerComps, markerEq)
    local
      Integer indexVar, indexEq;
      list<Integer> var_list2, var_list3;

    case({}, _, _, _, _, _) equation
    then (markerComps,markerEq);

    case(indexVar :: var_list2, _, _, _, _, _) equation
      indexEq=vecVarToEq[indexVar];
      (outMarkerComps,outMarkerEq)=compsMarker3(flatComps, markerComps, indexEq,1 , markerEq);
      (outMarkerComps,outMarkerEq)=compsMarker2(var_list2, vecVarToEq, m,flatComps, outMarkerComps, outMarkerEq);
    then (outMarkerComps,outMarkerEq);
  end matchcontinue;
end compsMarker2;

protected function compsMarker3
  input list<Integer> flatComps;
  input list<Integer> markerComps;
  input Integer indexEq;
  input Integer counter;
  input list<Integer> markerEq;
  output list<Integer> outMarkerComps;
  output list<Integer> outMarkerEq;
algorithm
  (outMarkerComps,outMarkerEq) := matchcontinue (flatComps, markerComps, indexEq, counter, markerEq)
    local
      Integer indexComp, marker;
      list<Integer> flatComps2;
      array<Integer> marker_array;

    case({},_,_,_,_)equation
    then(markerComps,markerEq);

    case(indexComp::flatComps2, _, _, _,_) equation
      true = intLe(counter,listLength(markerComps));
      true = intEq(indexComp,indexEq);
      marker=listGet(markerComps,counter);
      true = intEq(marker,0);
      marker_array = listArray(markerComps);
      marker_array = arrayUpdate(marker_array,counter,1);
      outMarkerComps = arrayList(marker_array);
      marker=listGet(markerEq,indexEq);
      marker_array = listArray(markerEq);
      marker_array = arrayUpdate(marker_array,indexEq,1);
      outMarkerEq = arrayList(marker_array);
      (outMarkerComps,outMarkerEq) = compsMarker3(flatComps2, outMarkerComps, indexEq, counter+1, outMarkerEq);
    then (outMarkerComps,outMarkerEq);

    case(indexComp::flatComps2,_,_,_,_) equation
      true = intLe(counter,listLength(markerComps));
      (outMarkerComps,outMarkerEq) = compsMarker3(flatComps2, markerComps, indexEq, counter+1, markerEq);
    then (outMarkerComps,outMarkerEq);
  end matchcontinue;
end compsMarker3;

protected function equationsReplaceEquations "author: mwenzler"
  input list<Integer> flatComps;
  input list<BackendDAE.Equation> eqns_list;
  input BackendDAE.Variables vars;
  input array<Integer> vecEqToVar;
  input BackendVarTransform.VariableReplacements repl;
  input list<Integer> markerComps;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  outRepl := matchcontinue(flatComps, eqns_list, vars, vecEqToVar, repl, markerComps)
    local
      list<Integer> flatComps2, markerComps2;
      Integer indexEq, indexVar, indexMarker;
      BackendVarTransform.VariableReplacements repl_1, repl1, repl2;
      BackendDAE.Variables knvars;
      BackendDAE.Var var;
      BackendDAE.VarKind varKind;
      DAE.ComponentRef varName;
      DAE.VarDirection varDirection;
      DAE.VarParallelism varParallelism;
      DAE.Type varType;
      BackendDAE.Equation eqn;
      DAE.ComponentRef cref;
      BackendDAE.Type type_;
      DAE.Exp exp, exp1, x;

    case ({},_,_,_,_,_) then repl;

    case(indexEq :: flatComps2,_,_,_,_,indexMarker :: markerComps2) equation
      true = intEq(indexMarker,1);
      indexVar = vecEqToVar[indexEq];
      var = BackendVariable.getVarAt(vars, indexVar);
      eqn = listGet(eqns_list, indexEq);
      cref = BackendVariable.varCref(var);
      type_ = BackendVariable.varType(var);
      x = DAE.CREF(cref, type_);
      BackendDAE.VAR(varName=varName)=var;
      (eqn as BackendDAE.EQUATION(scalar=exp)) = BackendEquation.solveEquation(eqn, x);
      ((exp1, _)) = Expression.traverseExp(exp, BackendDAEUtil.replaceCrefsWithValues, (vars, varName));
      repl_1 = BackendVarTransform.addReplacement(repl, varName, exp1,NONE());
      outRepl=equationsReplaceEquations(flatComps2, eqns_list, vars, vecEqToVar, repl_1, markerComps2);
    then outRepl;

    case(indexEq :: flatComps2,_,_,_,_,indexMarker :: markerComps2) equation
      outRepl=equationsReplaceEquations(flatComps2, eqns_list, vars, vecEqToVar, repl, markerComps2);
    then outRepl;

    end matchcontinue;
end equationsReplaceEquations;

protected function removeEqswork "author: mwenzler"
  input list<Integer> unassignedEqns;
  input list<BackendDAE.Equation> eqns_list;
  input BackendDAE.Variables vars;
  input BackendVarTransform.VariableReplacements repl;
  output list<BackendDAE.Equation> eqns_1;

algorithm
  eqns_1 := matchcontinue (unassignedEqns, eqns_list, vars, repl)
    local
      list<Integer> unassignedEqns2;
      Integer indexEq;
      BackendDAE.Equation eqn;

  case({},_,_,_) then eqns_list;
    case (indexEq :: unassignedEqns2, _, _,_ ) equation
    eqn = listGet(eqns_list, indexEq);
    (eqns_1,_) = BackendVarTransform.replaceEquations({eqn}, repl,NONE());
    eqn = listGet(eqns_1, 1);
    eqns_list = List.set(eqns_list, indexEq, eqn);
    eqns_1=removeEqswork(unassignedEqns2,eqns_list,vars,repl);
    then eqns_1;

  end matchcontinue;
end removeEqswork;

protected function minimizationUnassignedEqns "author: mwenzler"
  input list<Integer> inUnassignedEqns;
  input list<Integer> origUnassignedEqns;
  input list<Integer> residualUnassignedEqns;
  input BackendDAE.IncidenceMatrix inM;
  input  array<Integer> vecVarToEqs;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  output list<Integer> outUnassignedEqns;
  output list<Integer> outResidualUnassignedEqns;
algorithm
  (outUnassignedEqns,outResidualUnassignedEqns) := matchcontinue (inUnassignedEqns,origUnassignedEqns,residualUnassignedEqns,inM,vecVarToEqs,me)
    local
      list<Integer> unassignedEqns2, listIncidenceMatrix;
      Integer indexEq;

    case({},_,_,_,_,_) then (origUnassignedEqns,residualUnassignedEqns);

    case (indexEq :: unassignedEqns2, _, _,_,_,_) equation
        listIncidenceMatrix = inM[indexEq];
        true = minimizationUnassignedEqns2(listIncidenceMatrix,vecVarToEqs,me);
        origUnassignedEqns=listAppend(origUnassignedEqns,{indexEq});
       (outUnassignedEqns,outResidualUnassignedEqns)= minimizationUnassignedEqns(unassignedEqns2,origUnassignedEqns,residualUnassignedEqns,inM,vecVarToEqs,me);
    then (outUnassignedEqns,outResidualUnassignedEqns);

    case (indexEq :: unassignedEqns2, _, _,_,_,_) equation
        residualUnassignedEqns=listAppend(residualUnassignedEqns,{indexEq});
       (outUnassignedEqns,outResidualUnassignedEqns)= minimizationUnassignedEqns(unassignedEqns2,origUnassignedEqns,residualUnassignedEqns,inM,vecVarToEqs,me);
    then (outUnassignedEqns,outResidualUnassignedEqns);
  end matchcontinue;
end  minimizationUnassignedEqns;

protected function  minimizationUnassignedEqns2
  input list<Integer> listIncidenceMatrix;
  input  array<Integer> vecVarToEqs;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  output Boolean outHit;
algorithm
  outHit := matchcontinue (listIncidenceMatrix,vecVarToEqs,me)
    local
      list<Integer> listIncidenceMatrix2;
      Integer indexVar, indexEq;

    case({},_,_) then true;

    case (indexVar :: listIncidenceMatrix2, _, _) equation
      indexEq=vecVarToEqs[indexVar];
      false=intEq(indexEq,-1);
      outHit = minimizationUnassignedEqns2(listIncidenceMatrix2,vecVarToEqs,me);
    then outHit;

    case (indexVar :: listIncidenceMatrix2, _,_)
    then false;
  end matchcontinue;
end  minimizationUnassignedEqns2;

protected function emptyListOfIncidenceMatrix "author: mwenzler"
  input list<Integer> inUnassignedEqns;
  input BackendDAE.IncidenceMatrix inM;
  input  array<Integer> vecVarToEqs;
  input  Boolean inBool;
  output Boolean outBool;
algorithm
  outBool := matchcontinue (inUnassignedEqns,inM,vecVarToEqs, inBool)
    local
      list<Integer> unassignedEqns, listIncidenceMatrix;
      Integer indexEq;
      Boolean bool;

    case({}, _, _, _) then inBool;

    case(indexEq :: unassignedEqns, _, _, _) equation
      listIncidenceMatrix = inM[indexEq];
      bool = emptyListOfIncidenceMatrix2(listIncidenceMatrix,vecVarToEqs);
      outBool=emptyListOfIncidenceMatrix(unassignedEqns,inM,vecVarToEqs, bool);
    then outBool;
  end matchcontinue;
end emptyListOfIncidenceMatrix;

protected function  emptyListOfIncidenceMatrix2
  input list<Integer> listIncidenceMatrix;
  input  array<Integer> vecVarToEqs;
  output Boolean outHit;
algorithm
  outHit := matchcontinue (listIncidenceMatrix,vecVarToEqs)
    local
      list<Integer> listIncidenceMatrix2;
      Integer indexVar, indexEq;

    case({},_) then true;

    case (indexVar :: listIncidenceMatrix2, _) equation
      indexEq=vecVarToEqs[indexVar];
      false=intEq(indexEq,-1);
      outHit = emptyListOfIncidenceMatrix2(listIncidenceMatrix2,vecVarToEqs);
    then outHit;

    case (indexVar :: listIncidenceMatrix2, _)
    then false;

  end matchcontinue;
end  emptyListOfIncidenceMatrix2;

protected function adaptUnassignedEqns "author: mwenzler"
  input list<Integer> inUnassignedEqns;
  input list<Integer> unassignedEqns;
  input array<Integer> mapIncRowEqn;
  output  list<Integer> outUnassignedEqns;
algorithm
  outUnassignedEqns := matchcontinue(inUnassignedEqns, unassignedEqns, mapIncRowEqn)
    local
      list<Integer> inUnassignedEqns2;
      Integer indexEq, index;

      case({},_,_) then unassignedEqns;

      case(indexEq :: inUnassignedEqns2, _, _) equation
        index=mapIncRowEqn[indexEq];
        unassignedEqns=listAppend(unassignedEqns,{index});
        outUnassignedEqns=adaptUnassignedEqns(inUnassignedEqns2, unassignedEqns, mapIncRowEqn);
      then outUnassignedEqns;
  end matchcontinue;
end adaptUnassignedEqns;

protected function loopControl "author: mwenzler"
  input list<Integer> unassignedEqns;
  input Integer nEqns;
  input Integer nVars;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(unassignedEqns,nEqns,nVars)

    case(_,_,_) equation
      true = intGe(listLength(unassignedEqns),nEqns-nVars);
    then true;

    else equation
      Error.addCompilerNotification("It was not possible to analyze the given system symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    then false;

  end matchcontinue;
end loopControl;

protected function fixOverDeterminedInitialSystem "author: mwenzler"
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.EquationArray inOrigEqns;
  input Integer inNUnassignedEqns;
  input BackendDAE.IncidenceMatrix inMOrig;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced meT;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.Shared shared;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns := matchcontinue(vars, eqns, inOrigEqns, inNUnassignedEqns, inMOrig, inM, inMt, me, meT, mapEqnIncRow, mapIncRowEqn, shared)
    local
    Integer nVars, nEqns, nUnassignedEqns;
    array<Integer> vec1, vec2, marker;
    list<Integer> vec1Lst, vec2Lst, flatComps, outMarkerComps, outMarkerEq, markerEq;
    list<Integer> unassignedEqns, outUnassignedEqns, resiUnassignedEqns, marker_list;
    list<list<Integer>> comps;
    BackendDAE.EquationArray substEqns, origEqns;
    BackendVarTransform.VariableReplacements repl, outRepl;
    list<BackendDAE.Equation> eqns_list, eqns_1;
    Boolean boolUnassignedEqns, divideByZero;
    Integer pos;
    DAE.Ident ident;
    BackendDAE.IncidenceMatrix mCopy;
    BackendDAE.IncidenceMatrixT mtCopy;

    case (_, _, _, _, _, _, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intEq(nVars, nEqns);
    then eqns;

    case (_, _, _, _, _, _, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intLt(nVars, nEqns);

      vec1 = arrayCreate(nVars, -1);
      vec2 = arrayCreate(nEqns, -1);
      vec1Lst = arrayList(vec1);
      vec2Lst = arrayList(vec2);

      SOME(mCopy)=BackendDAEUtil.copyIncidenceMatrix(SOME(inM));
      SOME(mtCopy)=BackendDAEUtil.copyIncidenceMatrix(SOME(inMt));
      (vec1Lst, vec2Lst, _, _, comps, _) = Tearing.Tarjan(mCopy, mtCopy, me, meT, vec1Lst, vec2Lst, {{}, {}}, mapEqnIncRow, mapIncRowEqn, true);
      flatComps = List.flatten(comps);
      vec1 = listArray(vec1Lst);
      vec2 = listArray(vec2Lst);

      unassignedEqns = Matching.getUnassigned(nEqns, vec2, {});
      nUnassignedEqns = listLength(unassignedEqns);

      (unassignedEqns,resiUnassignedEqns)= minimizationUnassignedEqns(unassignedEqns,{},{},inM,vec1,me);
      true=loopControl(unassignedEqns,nEqns,nVars);

      marker=arrayCreate(listLength(flatComps),0);
      marker_list=arrayList(marker);
      marker=arrayCreate(nEqns,0);
      markerEq=arrayList(marker);

      unassignedEqns=adaptUnassignedEqns(unassignedEqns, {}, mapIncRowEqn); // Test
      flatComps=adaptUnassignedEqns(flatComps, {}, mapIncRowEqn); // Test
      (outMarkerComps,outMarkerEq)=compsMarker(unassignedEqns, vec1, inMOrig, flatComps, marker_list, markerEq);
      eqns_list=BackendEquation.equationList(eqns);
      repl = BackendVarTransform.emptyReplacements();
      outRepl = equationsReplaceEquations(flatComps, eqns_list, vars, vec2, repl, outMarkerComps);

      (divideByZero,pos,ident)=BackendVarTransform.divideByZeroReplacements(outRepl);
      (inM,inMt)=manipulatedAdjacencyMatrix(divideByZero, ident, vars, 1, vec1,inM,inMt);
      //unassignedEqns=adaptUnassignedEqns(unassignedEqns, {}, mapIncRowEqn);
      eqns_1=removeEqswork(unassignedEqns,eqns_list,vars,outRepl);
      substEqns = BackendEquation.listEquation(eqns_1);
      (outUnassignedEqns, true) = getConsistentEquations(unassignedEqns, substEqns, eqns, inM, vec1,vars, shared);

      // remove all unassigned equations
      substEqns = BackendEquation.equationDelete(substEqns, outUnassignedEqns);
      origEqns = BackendEquation.equationDelete(inOrigEqns, outUnassignedEqns);

    then fixOverDeterminedInitialSystem(vars, substEqns, inOrigEqns, nUnassignedEqns, inMOrig, inM, inMt, me, meT, mapEqnIncRow, mapIncRowEqn, shared);

    else // equation
      // Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function fixOverDeterminedInitialSystem failed");
    then fail();
  end matchcontinue;
end fixOverDeterminedInitialSystem;

protected function manipulatedAdjacencyMatrix
  input Boolean divideByZero;
  input DAE.Ident ident;
  input BackendDAE.Variables vars;
  input Integer counter;
  input array<Integer> vecVartoEq;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output BackendDAE.IncidenceMatrix mOut;
  output BackendDAE.IncidenceMatrixT mtOut;
algorithm
  (mOut,mtOut) := matchcontinue(divideByZero, ident, vars, counter,vecVartoEq,m,mt)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cref;
      DAE.Ident identVar;
      Integer nVars,intEg;
      list<Integer> IncidenceVec;
    case(false, _, _, _, _, _, _) then (m,mt);

    case(true, _, _, _, _, _,_) equation
      nVars = BackendVariable.varsSize(vars);
      true = intLe(counter,nVars);
      var = BackendVariable.getVarAt(vars, counter);
      cref = BackendVariable.varCref(var);
      DAE.CREF_IDENT(ident = identVar,subscriptLst = {})=cref;
      false = ident ==& identVar;
      (mOut,mtOut)=manipulatedAdjacencyMatrix(divideByZero, ident, vars, counter+1, vecVartoEq, m, mt );
    then (mOut,mtOut);

    case(true, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      true = intLe(counter,nVars);
      intEg=vecVartoEq[counter];
      IncidenceVec=m[intEg];
      m=manipulatedAdjacencyMatrix2(IncidenceVec,IncidenceVec,m,counter,intEg,1);
      IncidenceVec=mt[counter];
      mt=manipulatedAdjacencyMatrixT2(IncidenceVec,IncidenceVec,mt,counter,intEg,1);
    then(m,mt);
  end matchcontinue;
end manipulatedAdjacencyMatrix;

protected function manipulatedAdjacencyMatrixT2
  input list<Integer> IncidenceVec;
  input list<Integer> OrigIncidenceVec;
  input BackendDAE.IncidenceMatrixT mtIn;
  input Integer intVar;
  input Integer EgInt;
  input Integer counter;
  output BackendDAE.IncidenceMatrixT mtOut;
algorithm
  mtOut := matchcontinue(IncidenceVec,OrigIncidenceVec,mtIn,intVar,EgInt,counter)
  local
    Integer indexEq;
    list<Integer> IncidenceVec2, newIncidenceVec2;
  case({},_,_,_,_,_) then mtIn;
  case(indexEq :: IncidenceVec2,_,_,_,_,_)equation
    true = intLe(counter,listLength(OrigIncidenceVec));
    true = intEq(indexEq,EgInt);
    newIncidenceVec2=listDelete(OrigIncidenceVec,counter-1);
    mtIn = Util.arrayReplaceAtWithFill(intVar,newIncidenceVec2,newIncidenceVec2,mtIn);
    mtOut=manipulatedAdjacencyMatrixT2(IncidenceVec2,OrigIncidenceVec,mtIn,intVar,EgInt,counter+1);
  then mtOut;

  case(indexEq :: IncidenceVec2,_,_,_,_,_)equation
    true = intLe(counter,listLength(OrigIncidenceVec));
    mtOut=manipulatedAdjacencyMatrixT2(IncidenceVec2,OrigIncidenceVec,mtIn,intVar,EgInt,counter+1);
  then mtIn;
 end matchcontinue;
end manipulatedAdjacencyMatrixT2;

protected function manipulatedAdjacencyMatrix2
  input list<Integer> IncidenceVec;
  input list<Integer> OrigIncidenceVec;
  input BackendDAE.IncidenceMatrix mIn;
  input Integer intVar;
  input Integer EgInt;
  input Integer counter;
  output BackendDAE.IncidenceMatrix mOut;
algorithm
  mOut := matchcontinue(IncidenceVec,OrigIncidenceVec,mIn,intVar,EgInt,counter)
  local
    Integer indexVar;
    list<Integer> IncidenceVec2, newIncidenceVec2;
  case({},_,_,_,_,_) then mIn;
  case(indexVar :: IncidenceVec2,_,_,_,_,_)equation
    true = intLe(counter,listLength(OrigIncidenceVec));
    true = intEq(indexVar,intVar);
    newIncidenceVec2=listDelete(OrigIncidenceVec,counter-1);
    mIn = Util.arrayReplaceAtWithFill(EgInt,newIncidenceVec2,newIncidenceVec2,mIn);
    mOut=manipulatedAdjacencyMatrix2(IncidenceVec2,OrigIncidenceVec,mIn,intVar,EgInt,counter+1);
  then mOut;

  case(indexVar :: IncidenceVec2,_,_,_,_,_)equation
    true = intLe(counter,listLength(OrigIncidenceVec));
    mOut=manipulatedAdjacencyMatrix2(IncidenceVec2,OrigIncidenceVec,mIn,intVar,EgInt,counter+1);
  then mIn;
 end matchcontinue;
end manipulatedAdjacencyMatrix2;

protected function analyzeInitialSystem2 "author: lochel"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, tuple<BackendDAE.BackendDAE, BackendDAE.Variables, list<BackendDAE.Var>>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, tuple<BackendDAE.BackendDAE, BackendDAE.Variables, list<BackendDAE.Var>>> osharedOptimized;
algorithm
  (osyst, osharedOptimized) := matchcontinue(isyst, sharedOptimized)
    local
      BackendDAE.BackendDAE inDAE;
      BackendDAE.EqSystem system, sys;
      BackendDAE.EquationArray eqns, origEqns;
      BackendDAE.Shared shared;
      BackendDAE.Variables vars, initVars;
      Integer nVars, nEqns;
      list<BackendDAE.Var> dumpVars, dumpVars2;
      DAE.FunctionTree funcs;
      BackendDAE.IncidenceMatrix m, m1, mOrig;
      BackendDAE.IncidenceMatrixT mt, mt1;
      BackendDAE.AdjacencyMatrixEnhanced me;
      BackendDAE.AdjacencyMatrixTEnhanced meT;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;

    // over-determined system [experimental support]
    case(sys as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars, dumpVars))) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intGt(nEqns, nVars);

      Error.addCompilerNotification("Trying to fix over-determined initial system with " +& intString(nVars) +& " variables and " +& intString(nEqns) +& " equations... [experimental support]");

      funcs = BackendDAEUtil.getFunctions(shared);
      system = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
      (system, m, mt, mapEqnIncRow, mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(system, BackendDAE.NORMAL(), SOME(funcs));
      (me, meT, _, _)= BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(system, shared);

      meT=manipulatedAdjacencyMatrixEnhanced(meT,1);
      me=manipulatedAdjacencyMatrixEnhanced(me,1);

      SOME(mOrig)=BackendDAEUtil.copyIncidenceMatrix(SOME(m));
      SOME(m1)=BackendDAEUtil.copyIncidenceMatrix(SOME(m));
      SOME(mt1)=BackendDAEUtil.copyIncidenceMatrix(SOME(mt));

      origEqns=fixOverDeterminedInitialSystem(vars, eqns, eqns, nEqns, mOrig, m1, mt1, me, meT, mapEqnIncRow, mapIncRowEqn, shared);
      system = BackendDAE.EQSYSTEM(vars, origEqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
    then (system, (shared, (inDAE, initVars, dumpVars)));

    // under-determined system
    case(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars, dumpVars))) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intLt(nEqns, nVars);

      (eqns, dumpVars2) = fixUnderDeterminedInitialSystem(inDAE, vars, eqns, initVars, shared);
      dumpVars = listAppend(dumpVars, dumpVars2);
      system = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
    then (system, (shared, (inDAE, initVars, dumpVars)));

    else (isyst, sharedOptimized);
  end matchcontinue;
end analyzeInitialSystem2;

protected function fixUnderDeterminedInitialSystem "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inInitVars;
  input BackendDAE.Shared inShared;
  output BackendDAE.EquationArray outEqns;
  output list<BackendDAE.Var> outDumpVars;
protected
  Integer nVars, nEqns;
  list<BackendDAE.Var> initVarList;
  array<Integer> vec1, vec2;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mt;
  BackendDAE.EqSystem syst;
  list<Integer> unassigned;
  DAE.FunctionTree funcs;
algorithm
  // match the system
  nVars := BackendVariable.varsSize(inVars);
  nEqns := BackendDAEUtil.equationSize(inEqns);
  syst := BackendDAE.EQSYSTEM(inVars, inEqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {});
  funcs := BackendDAEUtil.getFunctions(inShared);
  (syst, m, mt, _, _) := BackendDAEUtil.getIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs));
  // BackendDump.printEqSystem(syst);

  vec1 := arrayCreate(nVars, -1);
  vec2 := arrayCreate(nEqns, -1);
  Matching.matchingExternalsetIncidenceMatrix(nVars, nEqns, m);
  BackendDAEEXT.matching(nVars, nEqns, 5, 0, 0.0, 1);
  BackendDAEEXT.getAssignment(vec2, vec1);

  // try to find for unmatched variables without startvalue an equation by unassign a variable with start value
  //unassigned1 = Matching.getUnassigned(nEqns, vec2, {});
  //  print("Unassigned Eqns " +& stringDelimitList(List.map(unassigned1, intString), ", ") +& "\n");
  unassigned := Matching.getUnassigned(nVars, vec1, {});
  //  print("Unassigned Vars " +& stringDelimitList(List.map(unassigned, intString), ", ") +& "\n");
  // Debug.bcall(intGt(listLength(unassigned), nVars-nEqns), print, "Error could not match all equations\n");

  // b := Flags.isSet(Flags.INITIALIZATION) and intLt(listLength(unassigned), nVars-nEqns);
  // Debug.bcall(b, Error.addCompilerWarning, "It is not possible to determine unique which additional initial conditions should be added by auto-fixed variables.");

  unassigned := Util.if_(intGt(listLength(unassigned), nVars-nEqns), {}, unassigned);
  // unassigned = List.firstN(listReverse(unassigned), nVars-nEqns);
  unassigned := replaceFixedCandidates(unassigned, nVars, nEqns, m, mt, vec1, vec2, inVars, inInitVars, 1, arrayCreate(nEqns, -1), {});
  // add for all free variables an equation
  // Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(nVars-nEqns) +& " variables:");
  initVarList := List.map1r(unassigned, BackendVariable.getVarAt, inVars);
  (outEqns, outDumpVars) := addStartValueEquations(initVarList, inEqns, {});
end fixUnderDeterminedInitialSystem;

protected function addStartValueEquations "author: lochel"
  input list<BackendDAE.Var> inVarLst;
  input BackendDAE.EquationArray inEqns;
  input list<BackendDAE.Var> inDumpVars;
  output BackendDAE.EquationArray outEqns;
  output list<BackendDAE.Var> outDumpVars "this are the variables that get fixed (not the same as inVarLst!)" ;
algorithm
  (outEqns, outDumpVars) := matchcontinue(inVarLst, inEqns, inDumpVars)
    local
      BackendDAE.Var var, dumpVar;
      list<BackendDAE.Var> vars, dumpVars;
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns;
      DAE.Exp e, crefExp, startExp;
      DAE.ComponentRef cref, preCref;
      DAE.Type tp;

    case ({}, _, _) then (inEqns, inDumpVars);

    case (var::vars, _, _) equation
      preCref = BackendVariable.varCref(var);
      true = ComponentReference.isPreCref(preCref);
      cref = ComponentReference.popPreCref(preCref);
      tp = BackendVariable.varType(var);

      crefExp = DAE.CREF(preCref, tp);

      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makePureBuiltinCall("$_start", {e}, tp);

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());
      eqns = BackendEquation.equationAdd(eqn, inEqns);

      dumpVar = BackendVariable.copyVarNewName(cref, var);
      // crStr = BackendDump.varString(dumpVar);
      // Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "  " +& crStr);

      (eqns, dumpVars) = addStartValueEquations(vars, eqns, inDumpVars);
    then (eqns, dumpVar::dumpVars);

    case (var::vars, _, _) equation
      cref = BackendVariable.varCref(var);
      tp = BackendVariable.varType(var);

      crefExp = DAE.CREF(cref, tp);

      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makePureBuiltinCall("$_start", {e}, tp);

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());
      eqns = BackendEquation.equationAdd(eqn, inEqns);

      // crStr = BackendDump.varString(var);
      // Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "  " +& crStr);

      (eqns, dumpVars) = addStartValueEquations(vars, eqns, inDumpVars);
    then (eqns, var::dumpVars);

    else equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function addStartValueEquations failed");
    then fail();
  end matchcontinue;
end addStartValueEquations;

protected function replaceFixedCandidates "author: Frenkel TUD 2012-12
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

protected function pathFound "author: Frenkel TUD 2012-12
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
  match(stack, i, m, mT, ass1, ass2, mark, markarr)
    local
      list<Integer> eqns;

    case ({}, _, _, _, _, _, _, _) then false;
    case (_, _, _, _, _, _, _, _) equation
      // traverse all adiacent eqns
      eqns = List.select(mT[i], Util.intPositive);
    then pathFoundtraverseEqns(eqns, stack, m, mT, ass1, ass2, mark, markarr);
  end match;
end pathFound;

protected function pathFoundtraverseEqns "author: Frenkel TUD 2012-12
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
  found := matchcontinue(rows, stack, m, mT, ass1, ass2, mark, markarr)
    local
      list<Integer> rest;
      Integer rc, e;
      Boolean b;

    case ({}, _, _, _, _, _, _, _) then false;
    case (e::_, _, _, _, _, _, _, _) equation
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

protected function pathFoundtraverseEqns1 "author: Frenkel TUD 2012-12
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
  found := match(b, rows, stack, m, mT, ass1, ass2, mark, markarr)
    case (true, _, _, _, _, _, _, _, _) then true;
    else pathFoundtraverseEqns(rows, stack, m, mT, ass1, ass2, mark, markarr);
  end match;
end pathFoundtraverseEqns1;

protected function reasign "author: Frenkel TUD 2012-03
  function helper for pathfound, reasignment(rematching) allong the augmenting path
  remove all edges from the assignments that are in the path
  add all other edges to the assignment"
  input list<Integer> stack;
  input Integer e;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _ := match(stack, e, ass1, ass2)
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

// =============================================================================
// section for introducing pre-variables for alias variables
//
// =============================================================================

protected function introducePreVarsForAliasVariables "author: lochel
  This function introduces all the pre-vars for the initial system that belong to alias vars."
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Type ty;
      DAE.InstDims arryDim;
      BackendDAE.Variables vars, fixvars;
      BackendDAE.EquationArray eqns;
      HashSet.HashSet hs;

      Boolean preUsed, isFixed;
      DAE.Exp startValue;
      Option<DAE.Exp> startValueOpt;
      DAE.ComponentRef preCR;
      BackendDAE.Var preVar;
      BackendDAE.Equation eqn;

    // discrete-time
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs))) equation
      preUsed = BaseHashSet.has(cr, hs);
      isFixed = BackendVariable.varFixed(var);
      startValue = BackendVariable.varStartValue(var);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(startValue));

      // preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      // preVar = BackendVariable.copyVarNewName(preCR, var);
      // preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      // preVar = BackendVariable.setBindExp(preVar, NONE());
      // preVar = BackendVariable.setBindValue(preVar, NONE());
      // preVar = BackendVariable.setVarFixed(preVar, true);
      // preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startValue, DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());

      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);
      eqns = Debug.bcallret2(preUsed and isFixed, BackendEquation.equationAdd, eqn, eqns, eqns);
    then ((var, (vars, fixvars, eqns, hs)));

    // discrete-time
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs))) equation
      isFixed = BackendVariable.varFixed(var);
      startValueOpt = BackendVariable.varStartValueOption(var);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValueOpt);

      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, preVar, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then ((var, (vars, fixvars, eqns, hs)));

    // continuous-time
    case((var as BackendDAE.VAR(varName=cr, varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs))) equation
      preUsed = BaseHashSet.has(cr, hs);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      fixvars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then ((var, (vars, fixvars, eqns, hs)));

    else inTpl;
  end matchcontinue;
end introducePreVarsForAliasVariables;

// =============================================================================
// section for collecting initial vars/eqns
//
// =============================================================================

protected function collectInitialVarsEqnsSystem "author: lochel
  This function collects variables and equations for the initial system out of an given EqSystem."
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.EquationArray, HashSet.HashSet> iTpl;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.EquationArray, HashSet.HashSet> oTpl;
protected
  BackendDAE.Variables orderedVars, vars, fixvars;
  BackendDAE.EquationArray orderedEqs, eqns, reqns;
  BackendDAE.StateSets stateSets;
  HashSet.HashSet hs;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets) := isyst;
  (vars, fixvars, eqns, reqns, hs) := iTpl;

  ((vars, fixvars, eqns, hs)) := BackendVariable.traverseBackendDAEVars(orderedVars, collectInitialVars, (vars, fixvars, eqns, hs));
  ((eqns, reqns)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, collectInitialEqns, (eqns, reqns));
  //((fixvars, eqns)) := List.fold(stateSets, collectInitialStateSetVars, (fixvars, eqns));

  oTpl := (vars, fixvars, eqns, reqns, hs);
end collectInitialVarsEqnsSystem;

protected function collectInitialVars "author: lochel
  This function collects all the vars for the initial system.
  TODO: return additional equations for pre-variables"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var, preVar, derVar;
      BackendDAE.Variables vars, fixvars;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      DAE.ComponentRef cr, preCR, derCR;
      Boolean isFixed, isInput, b, preUsed;
      DAE.Type ty;
      DAE.InstDims arryDim;
      Option<DAE.Exp> startValue;
      DAE.Exp startValue_;
      DAE.Exp startExp, bindExp;
      BackendDAE.VarKind varKind;
      HashSet.HashSet hs;
      String s, str, sv;
      Absyn.Info info;

    // state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(index=_), varType=ty), (vars, fixvars, eqns, hs))) equation
      isFixed = BackendVariable.varFixed(var);
      _ = BackendVariable.varStartValueOption(var);
      preUsed = BaseHashSet.has(cr, hs);

      startExp = BackendVariable.varStartValue(var);
      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), startExp, DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());
      eqns = Debug.bcallret2(isFixed, BackendEquation.equationAdd, eqn, eqns, eqns);

      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());

      derCR = ComponentReference.crefPrefixDer(cr);  // cr => $DER.cr
      derVar = BackendVariable.copyVarNewName(derCR, var);
      derVar = BackendVariable.setVarDirection(derVar, DAE.BIDIR());
      derVar = BackendVariable.setBindExp(derVar, NONE());
      derVar = BackendVariable.setBindValue(derVar, NONE());

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setBindValue(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), DAE.CREF(preCR, ty), DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());

      vars = BackendVariable.addVar(derVar, vars);
      vars = BackendVariable.addVar(var, vars);
      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);
      eqns = Debug.bcallret2(preUsed, BackendEquation.equationAdd, eqn, eqns, eqns);
    then ((var, (vars, fixvars, eqns, hs)));

    // discrete (preUsed=true)
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty), (vars, fixvars, eqns, hs))) equation
      true = BaseHashSet.has(cr, hs);
      true = BackendVariable.varFixed(var);
      startValue_ = BackendVariable.varStartValue(var);

      var = BackendVariable.setVarFixed(var, false);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setBindValue(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(startValue_));

      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startValue_, DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());

      vars = BackendVariable.addVar(var, vars);
      vars = BackendVariable.addVar(preVar, vars);
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (vars, fixvars, eqns, hs)));

    // discrete
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE()), (vars, fixvars, eqns, hs))) equation
      preUsed = BaseHashSet.has(cr, hs);
      startValue = BackendVariable.varStartValueOption(var);

      var = BackendVariable.setVarFixed(var, false);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setBindValue(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);

      vars = BackendVariable.addVar(var, vars);
      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);
    then ((var, (vars, fixvars, eqns, hs)));

    // parameter without binding and fixed=true
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=NONE()), (vars, fixvars, eqns, hs))) equation
      true = BackendVariable.varFixed(var);
      startExp = BackendVariable.varStartValueType(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, SOME(startExp));
      var = BackendVariable.setVarFixed(var, true);

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(startExp);
      info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s, str}, info);

      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars, eqns, hs)));

    // parameter with binding and fixed=false
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=ty), (vars, fixvars, eqns, hs))) equation
      true = intGt(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 31);
      false = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, NONE());

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(bindExp);
      info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNFIXED_PARAMETER_WITH_BINDING, {s, s, str}, info);

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), bindExp, DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());
      eqns = BackendEquation.equationAdd(eqn, eqns);

      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars, eqns, hs)));

    // *** MODELICA 3.1 COMPATIBLE ***
    // parameter with binding and fixed=false and no start value
    // use the binding as start value
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=_), (vars, fixvars, eqns, hs))) equation
      true = intLe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 31);
      false = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, NONE());
      NONE() = BackendVariable.varStartValueOption(var);
      var = BackendVariable.setVarStartValue(var, bindExp);

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(bindExp);
      info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNFIXED_PARAMETER_WITH_BINDING_31, {s, s, str}, info);

      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars, eqns, hs)));

    // *** MODELICA 3.1 COMPATIBLE ***
    // parameter with binding and fixed=false and a start value
    // ignore the binding and use the start value
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=_), (vars, fixvars, eqns, hs))) equation
      true = intLe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 31);
      false = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, NONE());
      SOME(startExp) = BackendVariable.varStartValueOption(var);

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(bindExp);
      sv = ExpressionDump.printExpStr(startExp);
      info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNFIXED_PARAMETER_WITH_BINDING_AND_START_VALUE_31, {s, sv, s, str}, info);

      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars, eqns, hs)));

    // parameter with constant binding
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars, eqns, hs))) equation
      true = Expression.isConst(bindExp);
      fixvars = BackendVariable.addVar(var, fixvars);
    then ((var, (vars, fixvars, eqns, hs)));

    // parameter
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM()), (vars, fixvars, eqns, hs))) equation
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars, eqns, hs)));

    // skip constant
    case((var as BackendDAE.VAR(varKind=BackendDAE.CONST()), (vars, fixvars, eqns, hs))) // equation
      // fixvars = BackendVariable.addVar(var, fixvars);
    then ((var, (vars, fixvars, eqns, hs)));

    // VARIABLE (fixed=true)
    // DUMMY_STATE
    case((var as BackendDAE.VAR(varName=cr, varType=ty), (vars, fixvars, eqns, hs))) equation
      true = BackendVariable.varFixed(var);
      isInput = BackendVariable.isVarOnTopLevelAndInput(var);
      startValue_ = BackendVariable.varStartValue(var);
      preUsed = BaseHashSet.has(cr, hs);

      var = BackendVariable.setVarFixed(var, false);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setBindValue(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), startValue_, DAE.emptyElementSource, false, BackendDAE.INITIAL_EQUATION());

      vars = Debug.bcallret2(not isInput, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(isInput, BackendVariable.addVar, var, fixvars, fixvars);
      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);
      eqns = BackendEquation.equationAdd(eqn, eqns);

      // Error.addCompilerNotification("VARIABLE (fixed=true): " +& BackendDump.varString(var));
    then ((var, (vars, fixvars, eqns, hs)));

    // VARIABLE (fixed=false)
    // DUMMY_STATE
    case((var as BackendDAE.VAR(varName=cr, varType=ty), (vars, fixvars, eqns, hs))) equation
      false = BackendVariable.varFixed(var);
      isInput = BackendVariable.isVarOnTopLevelAndInput(var);
      preUsed = BaseHashSet.has(cr, hs);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setBindValue(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      vars = Debug.bcallret2(not isInput, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(isInput, BackendVariable.addVar, var, fixvars, fixvars);
      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);

      // Error.addCompilerNotification("VARIABLE (fixed=false); " +& BackendDump.varString(var));
    then ((var, (vars, fixvars, eqns, hs)));

    case ((var, _)) equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function collectInitialVars failed for: " +& BackendDump.varString(var));
    then fail();

    else equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function collectInitialVars failed");
    then fail();
  end matchcontinue;
end collectInitialVars;

protected function collectInitialEqns "author: lochel"
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

protected function replaceDerPreCref "author: Frenkel TUD 2011-05
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

protected function replaceDerPreCrefExp "author: Frenkel TUD 2011-05
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

// =============================================================================
// section for bindings
//
// =============================================================================

protected function collectInitialBindings "author: lochel
  This function collects all the vars for the initial system."
  input tuple<BackendDAE.Var, tuple<BackendDAE.EquationArray, BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.EquationArray, BackendDAE.EquationArray>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Type ty;
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
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source, false, BackendDAE.INITIAL_EQUATION());
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (eqns, reeqns)));

    case ((var, _)) equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function collectInitialBindings failed for: " +& BackendDump.varString(var));
    then fail();

    else equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function collectInitialBindings failed");
    then fail();
  end match;
end collectInitialBindings;

// protected function collectInitialStateSetVars "author: Frenkel TUD
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
//     else false;
//   end match;
// end isStateSetVar;

// =============================================================================
// section for collecting discrete states
//
// collect all pre(var) in time equations to get the discrete states
// =============================================================================

// protected function discreteStates "author: Frenkel TUD 2012-12
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
// protected function discreteStatesSystems "author: Frenkel TUD
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
// protected function discreteStatesExp "author: Frenkel TUD 2012"
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
//     else inTpl;
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
// protected function discreteStatesCref "author: Frenkel TUD 2012-12
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
//     else inTpl;
//   end match;
// end discreteStatesCref;
//
// protected function dumpDiscreteStates "author: Frenkel TUD 2012-12"
//   input HashSet.HashSet hs;
// protected
//   list<DAE.ComponentRef> crefs;
// algorithm
//   crefs := BaseHashSet.hashSetList(hs);
//   print("Discrete States for Initialization:\n========================================\n");
//   BackendDump.debuglst((crefs, ComponentReference.printComponentRefStr, "\n", "\n"));
// end dumpDiscreteStates;

// =============================================================================
// optimize inital system
//
// =============================================================================
public function optimizeInitialSystem "author Frenkel TUD 2012-08"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      BackendDAE.EqSystems systs;
      BackendDAE.Variables knvars;
      BackendDAE.EquationArray inieqns;
      HashTable2.HashTable initalAliases;
      list<BackendDAE.Equation> eqnlst;
      Boolean optimizationfound;

    case (BackendDAE.DAE(_, BackendDAE.SHARED(knownVars=knvars, initialEqs=inieqns))) equation
      // search
      initalAliases = HashTable2.emptyHashTable();
      eqnlst = BackendEquation.equationList(inieqns);
      (eqnlst, initalAliases, optimizationfound) = optimizeInitialSystem1(eqnlst, knvars, initalAliases, {}, false);
      // do optimization
    then optimizeInitialSystemWork(optimizationfound, inDAE, eqnlst, initalAliases);

    else inDAE;
  end matchcontinue;
end optimizeInitialSystem;

protected function optimizeInitialSystemWork "author: Frenkel TUD 2012-08"
  input Boolean optimizationfound;
  input BackendDAE.BackendDAE inDAE;
  input list<BackendDAE.Equation> eqnlst;
  input HashTable2.HashTable initalAliases;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match(optimizationfound, inDAE, eqnlst, initalAliases)
    local
      BackendDAE.EqSystems systs;
      BackendDAE.Variables knvars, knvars1, exobj, av;
      BackendDAE.EquationArray remeqns, inieqns;
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

    case (true, BackendDAE.DAE(systs, BackendDAE.SHARED(knvars, exobj, av, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei)), _, _) equation
      (knvars1, (_, _)) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars, optimizeInitialAliasesFinder, (initalAliases, false));
      inieqns = BackendEquation.listEquation(eqnlst);
      systs= List.map1(systs, optimizeInitialAliases, initalAliases);
    then BackendDAE.DAE(systs, BackendDAE.SHARED(knvars1, exobj, av, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo, eoc, btp, symjacs, ei));

    case(false, _, _, _)
    then inDAE;
  end match;
end optimizeInitialSystemWork;

protected function optimizeInitialSystem1 "author: Frenkel TUD 2012-06"
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Variables knvars;
  input HashTable2.HashTable iInitalAliases;
  input list<BackendDAE.Equation> iAcc;
  input Boolean iOptimizationfound;
  output list<BackendDAE.Equation> outEqsLst;
  output HashTable2.HashTable oInitalAliases;
  output Boolean oOptimizationfound;
algorithm
  (outEqsLst, oInitalAliases, oOptimizationfound) := matchcontinue(iEqns, knvars, iInitalAliases, iAcc, iOptimizationfound)
    local
      list<BackendDAE.Equation> eqnslst, eqnslst1;
      BackendDAE.Equation eqn;
      HashTable2.HashTable initalAliases;
      Boolean optimizationfound, negate;
      DAE.ComponentRef cr1, cr2;
      DAE.Exp e1, e2;

    case ({}, _, _, _, _)
    then (listReverse(iAcc), iInitalAliases, iOptimizationfound);

    case ((eqn as BackendDAE.EQUATION(exp=e1, scalar=e2))::eqnslst, _, _, _, _) equation
      ((cr1, cr2, e1, e2, negate)::{}) = BackendEquation.aliasEquation(eqn);
      initalAliases = addInitialAlias(cr1, cr2, e1, e2, negate, knvars, iInitalAliases);
      (eqnslst1, initalAliases, optimizationfound) = optimizeInitialSystem1(eqnslst, knvars, initalAliases, iAcc, true);
    then (eqnslst1, initalAliases, optimizationfound);

    case (eqn::eqnslst, _, _, _, _) equation
      (eqnslst1, initalAliases, optimizationfound) = optimizeInitialSystem1(eqnslst, knvars, iInitalAliases, eqn::iAcc, iOptimizationfound);
    then (eqnslst1, initalAliases, optimizationfound);
  end matchcontinue;
end optimizeInitialSystem1;

protected function addInitialAlias
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input Boolean negate;
  input BackendDAE.Variables knvars;
  input HashTable2.HashTable iInitalAliases;
  output HashTable2.HashTable oInitalAliases;
algorithm
  oInitalAliases := matchcontinue(cr1, cr2, e1, e2, negate, knvars, iInitalAliases)
    local
      HashTable2.HashTable initalAliases;
      DAE.Exp e;

    case(_, _, _, _, _, _, _) equation
      (_::_, _) = BackendVariable.getVar(cr2, knvars);
      e = Debug.bcallret1(negate, Expression.negate, e2, e2);
      initalAliases = BaseHashTable.add((cr1, e), iInitalAliases);
      Debug.fcall(Flags.DUMPOPTINIT, BackendDump.debugStrCrefStrExpStr, ("Found initial Alias ", cr1, " = ", e, "\n"));
    then initalAliases;

    case(_, _, _, _, _, _, _) equation
      (_::_, _) = BackendVariable.getVar(cr1, knvars);
      e = Debug.bcallret1(negate, Expression.negate, e1, e1);
      initalAliases = BaseHashTable.add((cr2, e), iInitalAliases);
      Debug.fcall(Flags.DUMPOPTINIT, BackendDump.debugStrCrefStrExpStr, ("Found initial Alias ", cr2, " = ", e, "\n"));
    then initalAliases;
  end matchcontinue;
end addInitialAlias;

protected function optimizeInitialAliases "author: Frenkel TUD 2012-08"
  input BackendDAE.EqSystem inSyst;
  input HashTable2.HashTable initalAliases;
  output BackendDAE.EqSystem outSyst;
protected
  Option<BackendDAE.IncidenceMatrix> m, mT;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.Matching matching;
  Boolean b;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(vars, eqns, m, mT, matching, stateSets) := inSyst;
  (vars, (_, b)) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars, optimizeInitialAliasesFinder, (initalAliases, false));
  outSyst := Util.if_(b, BackendDAE.EQSYSTEM(vars, eqns, m, mT, matching, stateSets), inSyst);
end optimizeInitialAliases;

protected function optimizeInitialAliasesFinder "author: Frenkel TUD 2011-03"
  input tuple<BackendDAE.Var, tuple<HashTable2.HashTable, Boolean>> inTpl;
  output tuple<BackendDAE.Var, tuple<HashTable2.HashTable, Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var v;
      HashTable2.HashTable initalAliases;
      DAE.ComponentRef varName;
      DAE.Exp exp;

    case ((v as BackendDAE.VAR(varName=varName), (initalAliases, _))) equation
      exp = BaseHashTable.get(varName, initalAliases);
      v = BackendVariable.setVarStartValue(v, exp);
      v = BackendVariable.setVarFixed(v, true);
      Debug.fcall(Flags.DUMPOPTINIT, BackendDump.debugStrCrefStrExpStr, ("Set Var ", varName, " (start= ", exp, ", fixed=true)\n"));
    then ((v, (initalAliases, true)));

    case _ then inTpl;
  end matchcontinue;
end optimizeInitialAliasesFinder;

end Initialization;
