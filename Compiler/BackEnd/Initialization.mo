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
protected import BackendDAETransform;
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
protected import SimCodeUtil;

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
  output list<BackendDAE.Equation> outRemovedInitialEquations;
algorithm
  (outInitDAE, outUseHomotopy, outRemovedInitialEquations) := matchcontinue(inDAE)
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
      Boolean b, b1, b2;
      HashSet.HashSet hs "contains all pre variables";
      list<tuple<BackendDAEFunc.postOptimizationDAEModule, String, Boolean>> pastOptModules;
      tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> daeHandler;
      tuple<BackendDAEFunc.matchingAlgorithmFunc, String> matchingAlgorithm;
      Boolean useHomotopy;
      list<BackendDAE.Var> dumpVars, dumpVars2;
      BackendDAE.ExtraInfo ei;
      list<BackendDAE.Equation> removedEqns;

    case (_) equation
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
      initsyst = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
      (initsyst, dumpVars) = preBalanceInitialSystem(initsyst);

      SimCodeUtil.execStat("created initial system");
      // split the initial system into independend subsystems
      initdae = BackendDAE.DAE({initsyst}, shared);
      Debug.fcall(Flags.OPT_DAE_DUMP, print, stringAppendList({"\ncreated initial system:\n\n"}));
      Debug.fcall(Flags.OPT_DAE_DUMP, BackendDump.printBackendDAE, initdae);
      (systs, shared) = BackendDAEOptimize.partitionIndependentBlocksHelper(initsyst, shared, Error.getNumErrorMessages(), true);
      initdae = BackendDAE.DAE(systs, shared);
      SimCodeUtil.execStat("partitioned initial system");
      Debug.fcall(Flags.OPT_DAE_DUMP, print, stringAppendList({"\npartitioned initial system:\n\n"}));
      Debug.fcall(Flags.OPT_DAE_DUMP, BackendDump.printBackendDAE, initdae);
      // initdae = BackendDAE.DAE({initsyst}, shared);

      // fix over- and under-constrained subsystems
      (initdae, dumpVars2, removedEqns) = analyzeInitialSystem(initdae, dae, initVars);
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
      b1 = List.isNotEmpty(dumpVars);
      b2 = List.isNotEmpty(removedEqns);
      Debug.bcall(b1 and (not Flags.isSet(Flags.INITIALIZATION)), Error.addCompilerWarning, "The initial conditions are not fully specified. Use +d=initialization for more information.");
      Debug.bcall(b1 and Flags.isSet(Flags.INITIALIZATION), Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(listLength(dumpVars)) +& " variables:\n" +& warnAboutVars2(dumpVars));
      Debug.bcall(b2 and (not Flags.isSet(Flags.INITIALIZATION)), Error.addCompilerWarning, "The initial conditions are over specified. Use +d=initialization for more information.");
      Debug.bcall(b2 and Flags.isSet(Flags.INITIALIZATION), Error.addCompilerWarning, "Assuming redundant initial conditions for the following " +& intString(listLength(removedEqns)) +& " initial equations:\n" +& warnAboutEqns2(removedEqns));

      // warn about iteration variables with default zero start attribute
      b = warnAboutIterationVariablesWithDefaultZeroStartAttribute(initdae);
      Debug.bcall(b and (not Flags.isSet(Flags.INITIALIZATION)), Error.addCompilerWarning, "There are iteration variables with default zero start attribute. Use +d=initialization for more information.");

      b = Flags.isSet(Flags.DUMP_EQNINORDER) and Flags.isSet(Flags.DUMP_INITIAL_SYSTEM);
      Debug.bcall2(b, BackendDump.dumpEqnsSolved, initdae, "initial system: eqns in order");

      Debug.fcall(Flags.ITERATION_VARS, BackendDAEOptimize.listAllIterationVariables, initdae);
    then (SOME(initdae), useHomotopy, removedEqns);

    else (NONE(), false, {});
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
    case (_, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intGt(nEqns, nVars);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "It was not possible to solve the over-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)");
    then fail();

    // determined system: nEqns = nVars
    case ( _, _) equation
      nVars = BackendVariable.varsSize(BackendVariable.daeVars(isyst));
      nEqns = BackendDAEUtil.systemSize(isyst);
      true = intEq(nEqns, nVars);
    then (isyst, sharedOptimized);

    // under-determined system: nEqns < nVars
    case ( _, _) equation
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
  BackendDAE.BaseClockPartitionKind partitionKind;
  list<BackendDAE.Equation> eqnlst;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets, partitionKind=partitionKind) := inEqSystem;

  ((orderedVars, eqnlst)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, inlineWhenForInitializationEquation, (orderedVars, {}));
  eqns := BackendEquation.listEquation(eqnlst);

  outEqSystem := BackendDAE.EQSYSTEM(orderedVars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind);
end inlineWhenForInitializationSystem;

protected function inlineWhenForInitializationEquation "author: lochel
  This is a helper function for inlineWhenForInitialization1."
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.Variables, list<BackendDAE.Equation>> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.Variables, list<BackendDAE.Equation>> outTpl;
algorithm
  (outEq,outTpl) := match (inEq,inTpl)
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
      BackendDAE.EquationAttributes eqAttr;

    // when equation during initialization
    case (eqn as BackendDAE.WHEN_EQUATION(whenEquation=weqn, source=source, attr=eqAttr), (vars, eqns)) equation
      (eqns, vars) = inlineWhenForInitializationWhenEquation(weqn, source, eqAttr, eqns, vars);
    then (eqn, (vars, eqns));

    // algorithm
    case (eqn as BackendDAE.ALGORITHM(alg=alg, source=source,expand=crefExpand), (vars, eqns)) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg;
      (stmts, leftCrs) = generateInitialWhenAlg(stmts, true, {}, HashTable.emptyHashTableSized(50));
      alg = DAE.ALGORITHM_STMTS(stmts);
      size = listLength(CheckModel.algorithmOutputs(alg, crefExpand));
      crintLst = BaseHashTable.hashTableList(leftCrs);
      crefLst = List.fold(crintLst, selectSecondZero, {});
      (eqns, vars) = generateInactiveWhenEquationForInitialization(crefLst, source, eqns, vars);
      eqns = List.consOnTrue(List.isNotEmpty(stmts), BackendDAE.ALGORITHM(size, alg, source, crefExpand, BackendDAE.EQ_ATTR_DEFAULT_INITIAL), eqns);
    then (eqn, (vars, eqns));

    case (eqn, (vars, eqns))
    then (eqn, (vars, eqn::eqns));
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
  input DAE.ElementSource inSource;
  input BackendDAE.EquationAttributes inEqAttr;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.Variables inVars;
  output list<BackendDAE.Equation> outEqns;
  output BackendDAE.Variables outVars;
algorithm
  (outEqns, outVars) := matchcontinue(inWEqn, inSource, inEqAttr, inEqns, inVars)
    local
      DAE.ComponentRef left;
      DAE.Exp condition, right, crexp;
      BackendDAE.Equation eqn;
      DAE.Type identType;
      list<BackendDAE.Equation> eqns;
      BackendDAE.WhenEquation weqn;
      BackendDAE.Variables vars;

    // active when equation during initialization
    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right), _, _, _, _) equation
      true = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExp
      crexp = Expression.crefExp(left);
      identType = Expression.typeof(crexp);
      eqn = BackendEquation.generateEquation(crexp, right, identType, inSource, inEqAttr);
    then (eqn::inEqns, inVars);

    // inactive when equation during initialization
    case (BackendDAE.WHEN_EQ(condition=condition, left=left,  elsewhenPart=NONE()), _, _, _, _) equation
      false = Expression.containsInitialCall(condition, false);
      (eqns,_) = generateInactiveWhenEquationForInitialization({left}, inSource, inEqns, inVars);
    then (eqns, inVars);

    // inactive when equation during initialization with else when part (no strict Modelica)
    case (BackendDAE.WHEN_EQ(condition=condition, elsewhenPart=SOME(weqn)), _, _, _, _) equation
      false = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExp
      (eqns, vars) = inlineWhenForInitializationWhenEquation(weqn, inSource, inEqAttr, inEqns, inVars);
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
      eqn = BackendDAE.EQUATION(crefExp, crefPreExp, inSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
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
  ((_,outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns(removedEqs, Expression.traverseSubexpressionsHelper, (collectPreVariablesTraverseExp, outHS)); // ???
  ((_,outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns(ieqns, Expression.traverseSubexpressionsHelper, (collectPreVariablesTraverseExp, outHS));

  // print("collectPreVariables:\n");
  // crefs := BaseHashSet.hashSetList(outHS);
  // BackendDump.debuglst((crefs,ComponentReference.printComponentRefStr,"\n","\n"));
end collectPreVariables;

public function collectPreVariablesEqSystem
  input BackendDAE.EqSystem inEqSystem;
  input HashSet.HashSet inHS;
  output HashSet.HashSet outHS;
protected
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := inEqSystem;
  ((_,outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns(orderedEqs, Expression.traverseSubexpressionsHelper, (collectPreVariablesTraverseExp, inHS));
end collectPreVariablesEqSystem;

public function collectPreVariablesTraverseExp
  input DAE.Exp e;
  input HashSet.HashSet hs;
  output DAE.Exp outExp;
  output HashSet.HashSet ohs;
algorithm
  (outExp,ohs) := match (e,hs)
    local
      list<DAE.Exp> explst;
    case (DAE.CALL(path=Absyn.IDENT(name="pre")), _)
      equation
        (_, ohs) = Expression.traverseExp(e, collectPreVariablesTraverseExp2, hs);
      then (e, ohs);

    case (DAE.CALL(path=Absyn.IDENT(name="change")), _)
      equation
        (_, ohs) = Expression.traverseExp(e, collectPreVariablesTraverseExp2, hs);
      then (e, ohs);

    case (DAE.CALL(path=Absyn.IDENT(name="edge")), _)
      equation
        (_, ohs) = Expression.traverseExp(e, collectPreVariablesTraverseExp2, hs);
      then (e, ohs);

    else (e,hs);
  end match;
end collectPreVariablesTraverseExp;

protected function collectPreVariablesTraverseExp2 "author: lochel"
  input DAE.Exp e;
  input HashSet.HashSet hs;
  output DAE.Exp outExp;
  output HashSet.HashSet ohs;
algorithm
  (outExp,ohs) := match (e,hs)
    local
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef cr;

    case (DAE.CREF(componentRef=cr), _)
      equation
        crefs = ComponentReference.expandCref(cr, true);
        ohs = List.fold(crefs, BaseHashSet.add, hs);
      then (e, ohs);

    else (e,hs);
  end match;
end collectPreVariablesTraverseExp2;

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
      Boolean b;

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

    case (BackendDAE.TORNSYSTEM(tearingvars=vlst, linear=false)::rest, _) equation
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
      varlst = filterVarsWithoutStartValue(varlst);
      false = List.isEmpty(varlst);

      Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "Iteration variables with default zero start attribute in torn nonlinear equation system:\n" +& warnAboutVars2(varlst));
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

protected function warnAboutVars2 "author: lochel
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

protected function warnAboutEqns2 "author: lochel
  TODO: Replace this with an general BackendDump implementation."
  input list<BackendDAE.Equation> inEqns;
  output String outString;
algorithm
  outString := match(inEqns)
    local
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqns;
      String crStr;
      String str;

    case ({}) then "";

    case (eq::{}) equation
      crStr = "         " +& BackendDump.equationString(eq);
    then crStr;

    case (eq::eqns) equation
      crStr = BackendDump.equationString(eq);
      str = "         " +& crStr +& "\n" +& warnAboutEqns2(eqns);
    then str;
  end match;
end warnAboutEqns2;

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
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVars;
  output BackendDAE.Var outVar;
  output BackendDAE.Variables outVars;
algorithm
  (outVar,outVars) := matchcontinue (inVar,inVars)
    local
      BackendDAE.Var var, preVar;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr, preCR;
      DAE.Type ty;
      DAE.InstDims arryDim;

    // unfixed state
    case (var as BackendDAE.VAR(varName=_, varKind=BackendDAE.STATE(index=_)), vars) equation
      false = BackendVariable.varFixed(var);
      // ignore stateset variables
      // false = isStateSetVar(cr);
      vars = BackendVariable.addVar(var, vars);
    then (var, vars);

    // unfixed parameter
    case (var as BackendDAE.VAR(varKind=BackendDAE.PARAM()), vars) equation
      false = BackendVariable.varFixed(var);
      vars = BackendVariable.addVar(var, vars);
    then (var, vars);

    // unfixed discrete -> pre(vd)
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), vars) equation
      false = BackendVariable.varFixed(var);
      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      vars = BackendVariable.addVar(preVar, vars);
    then (var, vars);

    else (inVar,inVars);
  end matchcontinue;
end selectInitializationVariables2;

// =============================================================================
// section for simplifying initial functions
//
// =============================================================================

protected function simplifyInitialFunctions "author: Frenkel TUD 2012-12
  simplify initial() with true and sample with false"
  input DAE.Exp inExp;
  input Boolean inUseHomotopy;
  output DAE.Exp exp;
  output Boolean useHomotopy;
algorithm
  (exp, useHomotopy) := Expression.traverseExp(inExp, simplifyInitialFunctionsExp, inUseHomotopy);
end simplifyInitialFunctions;

protected function simplifyInitialFunctionsExp "author: Frenkel TUD 2012-12
  helper for simplifyInitialFunctions"
  input DAE.Exp inExp;
  input Boolean useHomotopy;
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp,outUseHomotopy) := match (inExp,useHomotopy)
    local
      DAE.Exp e1, e2, e3, actual, simplified;
    case (DAE.CALL(path = Absyn.IDENT(name="initial")), _) then (DAE.BCONST(true), useHomotopy);
    case (DAE.CALL(path = Absyn.IDENT(name="sample")), _) then (DAE.BCONST(false), useHomotopy);
    case (DAE.CALL(path = Absyn.IDENT(name="delay"), expLst = _::e1::_ ), _) then (e1, useHomotopy);
    case (DAE.CALL(path = Absyn.IDENT(name="homotopy"), expLst = actual::simplified::_ ), _)
      equation
        e1 = Expression.makePureBuiltinCall("homotopyParameter", {}, DAE.T_REAL_DEFAULT);
        e2 = DAE.BINARY(e1, DAE.MUL(DAE.T_REAL_DEFAULT), actual);
        e3 = DAE.BINARY(DAE.RCONST(1.0), DAE.SUB(DAE.T_REAL_DEFAULT), e1);
        e1 = DAE.BINARY(e3, DAE.MUL(DAE.T_REAL_DEFAULT), simplified);
        e3 = DAE.BINARY(e2, DAE.ADD(DAE.T_REAL_DEFAULT), e1);
      then (e3, true);
    else (inExp,useHomotopy);
  end match;
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
  BackendDAE.BaseClockPartitionKind partitionKind;
  Boolean b;
  BackendDAE.IncidenceMatrix mt;
algorithm
  (_, _, mt) := BackendDAEUtil.getIncidenceMatrix(inSystem, BackendDAE.NORMAL(), NONE());
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets, partitionKind=partitionKind) := inSystem;
  (orderedVars, orderedEqs, b, outDumpVars) := preBalanceInitialSystem1(arrayLength(mt), mt, orderedVars, orderedEqs, false, {});
  outSystem := Util.if_(b, BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind), inSystem);
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

    case (0, _, _, _, false, _)
    then (inVars, inEqs, false, inDumpVars);

    case (0, _, _, _, true, _) equation
      vars = BackendVariable.listVar1(BackendVariable.varList(inVars));
    then (vars, inEqs, true, inDumpVars);

    case (_, _, _, _, _, _) equation
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

    case (_, _, _, _, _, _) equation
      row = mt[n];
      true = List.isEmpty(row);

      var = BackendVariable.getVarAt(inVars, n);
      cref = BackendVariable.varCref(var);
      true = ComponentReference.isPreCref(cref);

      (vars, _) = BackendVariable.removeVars({n}, inVars, {});
    then (vars, inEqs, true, inDumpVars);

    case (_, _, _, _, _, _) equation
      row = mt[n];
      true = List.isEmpty(row);

      var = BackendVariable.getVarAt(inVars, n);
      cref = BackendVariable.varCref(var);
      false = ComponentReference.isPreCref(cref);

      (eqs, dumpVars) = addStartValueEquations({var}, inEqs, inDumpVars);
    then (inVars, eqs, true, dumpVars);

    case (_, _, _, _, _, _) equation
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
  output list<BackendDAE.Equation> outRemovedEqns;
algorithm
  (outDAE, (_, _, outDumpVars, outRemovedEqns)) := BackendDAEUtil.mapEqSystemAndFold(initDAE, analyzeInitialSystem2, (inDAE, inInitVars, {}, {}));
end analyzeInitialSystem;

protected function getInitEqIndex
  input BackendDAE.Equation inEquation;
  input tuple<Integer, list<Integer>> inTpl;
  output tuple<Integer, list<Integer>> outTpl;
protected
  Integer pos;
  list<Integer> lst;
algorithm
  (pos, lst) := inTpl;
  lst := listAppend(lst, Util.if_(BackendEquation.isInitialEquation(inEquation), {pos}, {}));
  outTpl := (pos+1, lst);
end getInitEqIndex;

protected function analyzeInitialSystem2 "author: lochel"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, tuple<BackendDAE.BackendDAE, BackendDAE.Variables, list<BackendDAE.Var>, list<BackendDAE.Equation>>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, tuple<BackendDAE.BackendDAE, BackendDAE.Variables, list<BackendDAE.Var>, list<BackendDAE.Equation>>> osharedOptimized;
algorithm
  (osyst, osharedOptimized) := matchcontinue(isyst, sharedOptimized)
    local
      BackendDAE.BackendDAE inDAE;
      BackendDAE.EqSystem system, sys;
      BackendDAE.EquationArray eqns, eqns2;
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
      list<BackendDAE.Equation> removedEqns, removedEqns2;
      list<Integer> unassigned;
      BackendDAE.EqSystem syst;
      array<Integer> vec1, vec2;

    // (regular) determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars, dumpVars, removedEqns))) equation
// print("index-0 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, shared, 0);
// print("index-0 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAE.EQSYSTEM(vars, eqns2, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());

    then (system, (shared, (inDAE, initVars, dumpVars, removedEqns)));

    // (index-1) mixed-determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars, dumpVars, removedEqns))) equation
// print("index-1 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, shared, 1);
// print("index-1 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAE.EQSYSTEM(vars, eqns2, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
    then (system, (shared, (inDAE, initVars, dumpVars, removedEqns)));

    // (index-2) mixed-determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars, dumpVars, removedEqns))) equation
// print("index-2 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, shared, 2);
// print("index-2 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAE.EQSYSTEM(vars, eqns2, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
    then (system, (shared, (inDAE, initVars, dumpVars, removedEqns)));

    // (index-3) mixed-determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (shared, (inDAE, initVars, dumpVars, removedEqns))) equation
// print("index-3 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, shared, 3);
// print("index-3 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAE.EQSYSTEM(vars, eqns2, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
    then (system, (shared, (inDAE, initVars, dumpVars, removedEqns)));

    else //equation
      //Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function analyzeInitialSystem2 failed");
    then fail();
  end matchcontinue;
end analyzeInitialSystem2;

protected function fixInitialSystem "author: lochel
  This function handles under-, over-, and mixed-determined systems with a given index."
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inInitVars;
  input BackendDAE.Shared inShared;
  input Integer inIndex "index of the system (0 is regular)" ;
  output BackendDAE.EquationArray outEqns;
  output list<BackendDAE.Var> outDumpVars;
  output list<BackendDAE.Equation> outRemovedEqns;
protected
  Integer nVars, nEqns, nInitEqs, nInitVars, nAddEqs, nAddVars;
  list<Integer> stateIndices, range, unassigned, initEqsIndices, redundantEqns;
  list<BackendDAE.Var> initVarList;
  array<Integer> vec1, vec2;
  BackendDAE.IncidenceMatrix m "incidence matrix of modified system" ;
  BackendDAE.IncidenceMatrix m_ "incidence matrix of original system (TODO: fix this one)" ;
  BackendDAE.EqSystem syst;
  DAE.FunctionTree funcs;
  BackendDAE.AdjacencyMatrixEnhanced me;
  array<Integer> mapIncRowEqn;
algorithm
  // nVars = nEqns
  nVars := BackendVariable.varsSize(inVars);
  nEqns := BackendDAEUtil.equationSize(inEqns);
  syst := BackendDAE.EQSYSTEM(inVars, inEqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
  funcs := BackendDAEUtil.getFunctions(inShared);
  (syst, m_, _, _, mapIncRowEqn) := BackendDAEUtil.getIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs));
//BackendDump.dumpEqSystem(syst, "fixInitialSystem");
//BackendDump.dumpVariables(inInitVars, "selected initialization variables");
//BackendDump.dumpIncidenceMatrix(m_);

  // get state-index list
  stateIndices := BackendVariable.getVarIndexFromVar(inInitVars, inVars);
  nInitVars := listLength(stateIndices);
//print("{" +& stringDelimitList(List.map(stateIndices, intString),",") +& "}\n");

  // get initial equation-index list
  //(initEqs, _) := List.extractOnTrue(BackendEquation.equationList(inEqns), BackendEquation.isInitialEquation);
  //nInitEqs := BackendDAEUtil.equationSize(BackendEquation.listEquation(initEqs));
  ((_, initEqsIndices)) := List.fold(BackendEquation.equationList(inEqns), getInitEqIndex, (1, {}));
  nInitEqs := listLength(initEqsIndices);
//print("{" +& stringDelimitList(List.map(initEqsIndices, intString),",") +& "}\n");

  // modify incidence matrix for under-determined systems
  nAddEqs := intMax(nVars-nEqns + inIndex, inIndex);
//print("nAddEqs: " +& intString(nAddEqs) +& "\n");
  m_ := fixUnderDeterminedSystem(m_, stateIndices, nEqns, nAddEqs);
  SOME(m) := BackendDAEUtil.copyIncidenceMatrix(SOME(m_)) "deep copy" ;

  // modify incidence matrix for over-determined systems
  nAddVars := intMax(nEqns-nVars + inIndex, inIndex);
//print("nAddVars: " +& intString(nAddVars) +& "\n");
  m := fixOverDeterminedSystem(m, initEqsIndices, nVars, nAddVars);

  // match the system (nVars+nAddVars == nEqns+nAddEqs)
  vec1 := arrayCreate(nVars+nAddVars, -1);
  vec2 := arrayCreate(nEqns+nAddEqs, -1);
  Matching.matchingExternalsetIncidenceMatrix(nVars+nAddVars, nEqns+nAddEqs, m);
  BackendDAEEXT.matching(nVars+nAddVars, nEqns+nAddEqs, 5, 0, 0.0, 1);
  BackendDAEEXT.getAssignment(vec2, vec1);
//BackendDump.dumpMatchingVars(vec1);
//BackendDump.dumpMatchingEqns(vec2);

  // check whether or not a complete matching was found
  unassigned := Matching.getUnassigned(nVars+nAddVars, vec1, {});
  Debug.bcall(0 < listLength(unassigned), Error.addCompilerNotification, "The given system is mixed-determined.   [index > " +& intString(inIndex) +& "]");
  0 := listLength(unassigned); // if this fails, the system is singular (mixed-determined)

  // map to equations
  range := List.intRange2(nVars+1, nVars+nAddVars);
  range := Util.if_(nAddVars > 0, range, {});
  redundantEqns := mapIndices(range, vec1);
//print("{" +& stringDelimitList(List.map(redundantEqns, intString),",") +& "}\n");

  // symbolic consistency check
  (me, _, _, _) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst, inShared);
  (_, _, _) := consistencyCheck(redundantEqns, inEqns, inVars, inShared, nAddVars, m_, me, vec1, vec2, mapIncRowEqn);

  // remove all unassigned equations
  outRemovedEqns := BackendEquation.getEqns(redundantEqns, inEqns);
//BackendDump.dumpEquationList(outRemovedEqns, "removed equations");
  outEqns := BackendEquation.equationDelete(inEqns, redundantEqns);
//BackendDump.dumpEquationArray(outEqns, "remaining equations");

  // map to variables
  range := List.intRange2(nEqns+1, nEqns+nAddEqs);
  range := Util.if_(nAddEqs > 0, range, {});
  range := mapIndices(range, vec2);
//print("{" +& stringDelimitList(List.map(range, intString),",") +& "}\n");

  // introduce additional initial equations
  initVarList := List.map1r(range, BackendVariable.getVarAt, inVars);
  (outEqns, outDumpVars) := addStartValueEquations(initVarList, outEqns, {});
//BackendDump.dumpEquationArray(outEqns, "remaining equations");
end fixInitialSystem;

protected function fixUnderDeterminedSystem "author: lochel"
  input BackendDAE.IncidenceMatrix inM;
  input list<Integer> inInitVarIndices;
  input Integer inNEqns;
  input Integer inNAddEqns;
  output BackendDAE.IncidenceMatrix outM;
algorithm
  outM := match(inM, inInitVarIndices, inNEqns, inNAddEqns)
    local
      BackendDAE.IncidenceMatrix m;
      list<Integer> newEqIndices;

    case (_, _, _, 0)
    then inM;

    //case (_, {}, _,  _) equation
    //  print("Error!!!!\n");
    //then fail();

    case (_, _, _, _) equation
      true = (inNAddEqns > 0) "just to be careful" ;
      m = arrayCreate(inNEqns+inNAddEqns, {});
      m = Util.arrayCopy(inM, m);
      newEqIndices = List.intRange2(inNEqns+1, inNEqns+inNAddEqns);
      m = List.fold1(newEqIndices, squareIncidenceMatrix1, inInitVarIndices, m);
    then m;
  end match;
end fixUnderDeterminedSystem;

protected function squareIncidenceMatrix1 "author: lochel"
  input Integer inPos;
  input list<Integer> inDependency;
  input BackendDAE.IncidenceMatrix inM;
  output BackendDAE.IncidenceMatrix outM;
algorithm
  outM := arrayUpdate(inM, inPos, inDependency);
end squareIncidenceMatrix1;

protected function fixOverDeterminedSystem "author: lochel"
  input BackendDAE.IncidenceMatrix inM;
  input list<Integer> inInitEqnIndices;
  input Integer inNVars;
  input Integer inNAddVars;
  output BackendDAE.IncidenceMatrix outM;
algorithm
  outM := match(inM, inInitEqnIndices, inNVars, inNAddVars)
    local
      BackendDAE.IncidenceMatrix m;
      list<Integer> newVarIndices;

    case (_, _, _, 0)
    then inM;

    //case (_, {}, _, _) equation
    //  print("Error!!!!\n");
    //then fail();

    case (_, _, _, _) equation
      true = (inNAddVars > 0) "just to be careful" ;
      newVarIndices = List.intRange2(inNVars+1, inNVars+inNAddVars);
      m = List.fold1(inInitEqnIndices, squareIncidenceMatrix2, newVarIndices, inM);
    then m;
  end match;
end fixOverDeterminedSystem;

protected function squareIncidenceMatrix2 "author: lochel"
  input Integer inPos;
  input list<Integer> inRange;
  input BackendDAE.IncidenceMatrix inM;
  output BackendDAE.IncidenceMatrix outM;
algorithm
  outM := arrayUpdate(inM, inPos, listAppend(arrayGet(inM, inPos), inRange));
end squareIncidenceMatrix2;

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

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.addEquation(eqn, inEqns);

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

      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.addEquation(eqn, inEqns);

      // crStr = BackendDump.varString(var);
      // Debug.fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "  " +& crStr);

      (eqns, dumpVars) = addStartValueEquations(vars, eqns, inDumpVars);
    then (eqns, var::dumpVars);

    else equation
      Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function addStartValueEquations failed");
    then fail();
  end matchcontinue;
end addStartValueEquations;

// =============================================================================
// section for symbolic consistency check
//
// =============================================================================

protected function consistencyCheck "
  This function performs a symbolic consistency check of all detected redundant
  initial equations and returns three lists:
    - The first list contains all consistent initial conditions.
    - The second list contains all inconsistent initial conditions.
    - The third list contains all initial conditions that couldn't be checked."
  input list<Integer> inRedundantEqns "these are the indices of the redundant equations" ;
  input BackendDAE.EquationArray inEqns "this are all equations of the given system" ;
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared inShared;
  input Integer nAddVars;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<Integer> vecVarToEqs;
  input array<Integer> vecEqsToVar;
  input array<Integer> mapIncRowEqn;
  output list<Integer> outConsistentEquations "These equations are consistent and can be removed from the initialization problem without any issue." ;
  output list<Integer> outInconsistentEquations "If this list is not empty then the initialization problem is inconsistent and has no solution." ;
  output list<Integer> outUncheckedEquations "These equations need to be checked numerically." ;
algorithm
  (outConsistentEquations, outInconsistentEquations, outUncheckedEquations) := matchcontinue(inRedundantEqns, inEqns, inVars, inShared, nAddVars, inM, me, vecVarToEqs, vecEqsToVar, mapIncRowEqn)
    local
      list<Integer> outRange, resiRange, flatComps, markedComps;
      list<Integer> outListComps, outLoopListComps, restRedundantEqns;
      list<Integer> consistentEquations, inconsistentEquations, uncheckedEquations, uncheckedEquations2;
      BackendDAE.IncidenceMatrix m;
      Integer nVars, nEqns, currRedundantEqn, redundantEqn;
      list<list<Integer>> comps;
      BackendDAE.IncidenceMatrixT mT;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EquationArray substEqns;

    case ({}, _, _, _, _, _, _, _, _, _)
    then ({}, {}, {});

    case (currRedundantEqn::restRedundantEqns, _, _, _, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendDAEUtil.equationSize(inEqns);
    //BackendDump.dumpMatchingVars(vecVarToEqs);
    //BackendDump.dumpMatchingEqns(vecEqsToVar);
    //BackendDump.dumpVariables(inVars, "inVars");
    //BackendDump.dumpEquationArray(inEqns, "inEqns");
    //BackendDump.dumpList(inRedundantEqns, "inRedundantEqns: ");
    //BackendDump.dumpIncidenceMatrix(inM);

      mT = BackendDAEUtil.transposeMatrix(inM, nVars+nAddVars);
    //BackendDump.dumpIncidenceMatrix(inM);

      // get the sorting and algebraic loops
      comps = BackendDAETransform.tarjanAlgorithm(mT, vecEqsToVar);
      flatComps = List.flatten(comps);
    //BackendDump.dumpComponentsOLD(comps);

      // split comps in a list with all equations that are part of a algebraic
      // loop and in one list with all other equations
      (outListComps, outLoopListComps) = splitStrongComponents(comps);
    //BackendDump.dumpList(outListComps, "outListComps: ");
    //BackendDump.dumpList(outLoopListComps, "outLoopListComps: ");

      // map indices to take care of array equations
      redundantEqn = mapIndex(currRedundantEqn, mapIncRowEqn);
      flatComps = mapIndices(flatComps, mapIncRowEqn);
      outLoopListComps = mapIndices(outLoopListComps, mapIncRowEqn);
    //BackendDump.dumpList(flatComps, "flatComps: ");
    //BackendDump.dumpList(arrayList(mapIncRowEqn), "mapIncRowEqn: ");

      markedComps = compsMarker(currRedundantEqn, vecVarToEqs, inM, flatComps, outLoopListComps);
    //BackendDump.dumpList(markedComps, "markedComps: ");

      repl = BackendVarTransform.emptyReplacements();
      repl = setupVarReplacements(markedComps, inEqns, inVars, vecEqsToVar, repl, mapIncRowEqn, me);
    //BackendVarTransform.dumpReplacements(repl);
      substEqns = applyVarReplacements(redundantEqn, inEqns, repl);

      (outRange, true, uncheckedEquations) = getConsistentEquation(redundantEqn, substEqns, inEqns, inM, vecVarToEqs, inVars, inShared, 1);
      (consistentEquations, inconsistentEquations, uncheckedEquations2) = consistencyCheck(restRedundantEqns, inEqns, inVars, inShared, nAddVars, inM, me, vecVarToEqs, vecEqsToVar, mapIncRowEqn);

      consistentEquations = listAppend(consistentEquations, outRange);
      uncheckedEquations = listAppend(uncheckedEquations, uncheckedEquations2);
    //BackendDump.dumpList(outRange, "outRange: ");
    //BackendDump.dumpEquationArray(inEqns, "inEqns");
    //BackendDump.dumpEquationArray(substEqns, "substEqns");
    then (consistentEquations, inconsistentEquations, uncheckedEquations);

    case (currRedundantEqn::restRedundantEqns, _, _, _, _, _, _, _, _, _) equation
      (consistentEquations, inconsistentEquations, uncheckedEquations) = consistencyCheck(restRedundantEqns, inEqns, inVars, inShared, nAddVars, inM, me, vecVarToEqs, vecEqsToVar, mapIncRowEqn);
    then (consistentEquations, currRedundantEqn::inconsistentEquations, uncheckedEquations);
  end matchcontinue;
end consistencyCheck;

protected function isVarExplicitSolvable
  input BackendDAE.AdjacencyMatrixElementEnhanced inElem;
  input Integer inVarID;
  output Boolean outSolvable;
algorithm
  outSolvable := matchcontinue(inElem, inVarID)
    local
      Integer id;
      BackendDAE.AdjacencyMatrixElementEnhanced elem;
      Boolean b;

    case ({}, _)
    then true;

    //case ((id, BackendDAE.SOLVABILITY_SOLVED())::elem, _) equation
    //  true = intEq(id, inVarID);
    //then false;

    case ((id, BackendDAE.SOLVABILITY_UNSOLVABLE())::elem, _) equation
      true = intEq(id, inVarID);
    then false;

    case ((id, BackendDAE.SOLVABILITY_NONLINEAR())::elem, _) equation
      true = intEq(id, inVarID);
    then false;

    case ((_, _)::elem, _) equation
      b = isVarExplicitSolvable(elem, inVarID);
    then b;
  end matchcontinue;
end isVarExplicitSolvable;

protected function splitStrongComponents "author: mwenzler"
  input list<list<Integer>> inComps "list of strong components" ;
  output list<Integer> outListComps "all components of size 1" ;
  output list<Integer> outLoopListComps "all components of size > 1" ;
algorithm
  (outListComps, outLoopListComps) := match(inComps)
    local
      Integer currIndex;
      list<Integer> currComp, listComps, loopListComps;
      list<list<Integer>> restComps;

    case ({})
    then ({}, {});

    case ({currIndex}::restComps) equation
      (listComps, loopListComps) = splitStrongComponents(restComps);
    then (currIndex::listComps, loopListComps);

    case (currComp::restComps) equation
      (listComps, loopListComps) = splitStrongComponents(restComps);
      loopListComps = listAppend(currComp, loopListComps);
    then (listComps, loopListComps);
  end match;
end splitStrongComponents;

protected function mapIndex "author: lochel
  This function applies 'inMapping' to the input index."
  input Integer inIndex;
  input array<Integer> inMapping;
  output Integer outIndex;
algorithm
  outIndex := inMapping[inIndex];
end mapIndex;

protected function mapIndices "author: lochel
  This function applies 'inMapping' to the input index list."
  input list<Integer> inIndices;
  input array<Integer> inMapping;
  output list<Integer> outIndices;
algorithm
  outIndices := List.map1(inIndices, mapIndex, inMapping);
end mapIndices;

protected function compsMarker "author: mwenzler"
  input Integer inUnassignedEqn;
  input array<Integer> inVecVarToEq;
  input BackendDAE.IncidenceMatrix inM;
  input list<Integer> inFlatComps;
  input list<Integer> inLoopListComps "not used yet" ;
  output list<Integer> outMarkedEqns "contains all the indices of the equations that need to be considered" ;
protected
  list<Integer> varList;
  list<Integer> markedEqns;
algorithm
  outMarkedEqns := matchcontinue (inUnassignedEqn, inVecVarToEq, inM, inFlatComps, inLoopListComps)
    case (_, _, _, _, _) equation
      false = listMember(inUnassignedEqn, inLoopListComps);
      varList = inM[inUnassignedEqn];
      markedEqns = compsMarker2(varList, inVecVarToEq, inM, inFlatComps, {}, inLoopListComps);

      outMarkedEqns = downCompsMarker(listReverse(inFlatComps), inVecVarToEq, inM, inFlatComps, markedEqns, inLoopListComps);
    then outMarkedEqns;

    else equation
      // TODO: change the message
      Error.addCompilerNotification("It was not possible to analyze the given system symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    then fail();
  end matchcontinue;
end compsMarker;

protected function compsMarker2
  input list<Integer> inVarList;
  input array<Integer> inVecVarToEq;
  input BackendDAE.IncidenceMatrix inM;
  input list<Integer> inFlatComps;
  input list<Integer> inMarkedEqns;
  input list<Integer> inLoopListComps;
  output list<Integer> outMarkedEqns;
algorithm
  outMarkedEqns := matchcontinue (inVarList, inVecVarToEq, inM, inFlatComps, inMarkedEqns, inLoopListComps)
    local
      Integer indexVar, indexEq;
      list<Integer> var_list2, var_list3;
      list<Integer> markedEqns;

    case ({}, _, _, _, _, _) equation
    then inMarkedEqns;

    case (indexVar::var_list2, _, _, _, _, _) equation
      indexEq = inVecVarToEq[indexVar];
      false = listMember(indexEq, inLoopListComps);
      false = listMember(indexEq, inMarkedEqns);
      markedEqns = compsMarker2(var_list2, inVecVarToEq, inM, inFlatComps, inMarkedEqns, inLoopListComps);
    then indexEq::markedEqns;

    case (indexVar::var_list2, _, _, _, _, _) equation
      indexEq = inVecVarToEq[indexVar];
      false = listMember(indexEq, inLoopListComps);
      true = listMember(indexEq, inMarkedEqns);
      markedEqns = compsMarker2(var_list2, inVecVarToEq, inM, inFlatComps, inMarkedEqns, inLoopListComps);
    then markedEqns;

    else equation
      Error.addCompilerNotification("It was not possible to analyze the given system symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    then fail();
  end matchcontinue;
end compsMarker2;

protected function downCompsMarker
  input list<Integer> unassignedEqns;
  input array<Integer> vecVarToEq;
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> flatComps;
  input list<Integer> inMarkedEqns;
  input list<Integer> inLoopListComps;
  output list<Integer> outMarkedEqns;
algorithm
  outMarkedEqns := matchcontinue (unassignedEqns, vecVarToEq, m, flatComps, inMarkedEqns, inLoopListComps)
    local
      list<Integer> unassignedEqns2, var_list;
      Integer indexUnassigned, marker;
      list<Integer> markedEqns;

    case ({}, _, _, _, _, _)
    then inMarkedEqns;

    case (indexUnassigned::unassignedEqns2, _, _, _, _, _) equation
      true = listMember(indexUnassigned, inMarkedEqns);
      var_list = m[indexUnassigned];
      markedEqns = compsMarker2(var_list, vecVarToEq, m, flatComps, inMarkedEqns, inLoopListComps);
      markedEqns = downCompsMarker(unassignedEqns2, vecVarToEq, m, flatComps, markedEqns, inLoopListComps);
    then markedEqns;

    case (indexUnassigned::unassignedEqns2, _, _, _, _, _) equation
      markedEqns = downCompsMarker(unassignedEqns2, vecVarToEq, m, flatComps, inMarkedEqns, inLoopListComps);
    then markedEqns;
  end matchcontinue;
end downCompsMarker;

protected function setupVarReplacements
  input list<Integer> inMarkedEqns;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVars;
  input array<Integer> inVecEqToVar "matching" ;
  input BackendVarTransform.VariableReplacements inRepls "initially call this with empty replacements" ;
  input array<Integer> inMapIncRowEqn;
  input BackendDAE.AdjacencyMatrixEnhanced inME;
  output BackendVarTransform.VariableReplacements outRepls;
algorithm
  outRepls := matchcontinue (inMarkedEqns, inEqns, inVars, inVecEqToVar, inRepls, inMapIncRowEqn, inME)
    local
      Integer markedEqn;
      list<Integer> markedEqns;
      Integer indexVar, indexEq;
      BackendVarTransform.VariableReplacements repls;
      BackendDAE.Var var;
      DAE.ComponentRef varName;
      BackendDAE.Equation eqn;
      DAE.ComponentRef cref;
      BackendDAE.Type type_;
      DAE.Exp exp, exp1, x;

    case ({}, _, _, _, _, _, _)
    then inRepls;

    case (markedEqn::markedEqns, _, _, _, _,  _, _) equation
      indexVar = inVecEqToVar[markedEqn];
      true = isVarExplicitSolvable(inME[markedEqn], indexVar);
      var = BackendVariable.getVarAt(inVars, indexVar);

      indexEq = inMapIncRowEqn[markedEqn];
      eqn = BackendEquation.equationNth1(inEqns, indexEq);

      cref = BackendVariable.varCref(var);
      type_ = BackendVariable.varType(var);
      x = DAE.CREF(cref, type_);
      (eqn as BackendDAE.EQUATION(scalar=exp)) = BackendEquation.solveEquation(eqn, x);

      varName = BackendVariable.varCref(var);
      (exp1, _) = Expression.traverseExp(exp, BackendDAEUtil.replaceCrefsWithValues, (inVars, varName));
      repls = BackendVarTransform.addReplacement(inRepls, varName, exp1, NONE());
      repls = setupVarReplacements(markedEqns, inEqns, inVars, inVecEqToVar, repls, inMapIncRowEqn, inME);
    then repls;

    case (_::markedEqns, _, _, _, _, _, _) equation
      repls = setupVarReplacements(markedEqns, inEqns, inVars, inVecEqToVar, inRepls, inMapIncRowEqn, inME);
    then repls;
  end matchcontinue;
end setupVarReplacements;

protected function applyVarReplacements "author: lochel
  This function applies variable replacements to one equation out of an equation
  array.
  Side-effects are omitted by doing a deep copy."
  input Integer inEqnIndex;
  input BackendDAE.EquationArray inEqnList;
  input BackendVarTransform.VariableReplacements inVarRepls;
  output BackendDAE.EquationArray outEqnList;
protected
  BackendDAE.Equation eqn;
algorithm
  outEqnList := BackendEquation.copyEquationArray(inEqnList) "avoid side-effects" ;
  eqn := BackendEquation.equationNth1(outEqnList, inEqnIndex);
  ({eqn}, _) := BackendVarTransform.replaceEquations({eqn}, inVarRepls, NONE());
  outEqnList := BackendEquation.setAtIndex(outEqnList, inEqnIndex, eqn);
end applyVarReplacements;

protected function getConsistentEquation "author: mwenzler"
  input Integer inUnassignedEqn;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.EquationArray inEqnsOrig;
  input BackendDAE.IncidenceMatrix inM;
  input array<Integer> vecVarToEqs;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared shared;
  input Integer counter;
  output list<Integer> outUnassignedEqns;   // consistent equation
  output Boolean outConsistent;
  output list<Integer> outRemovedEqns;    // problem with parameter in the equation
algorithm
  (outUnassignedEqns, outConsistent, outRemovedEqns) := matchcontinue(inUnassignedEqn, inEqns, inEqnsOrig, inM, vecVarToEqs, vars, shared, counter)
    local
      Integer currEqID, currVarID, currID, nVars, nEqns;
      list<Integer> unassignedEqns, unassignedEqns2, listVar, removedEqns;
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

    case (currID, _, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      true = Expression.isZero(exp);
      //((_, listParameter))=parameterCheck((exp, {}));
      //false=intGt(listLength(listParameter), 0);
      eqn = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerNotification("The following equation is consistent and got removed from the initialization problem: " +& BackendDump.equationString(eqn));
    then ({currID}, true, {});

    case (currID, _, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intGt(counter, nEqns-nVars);

      Error.addCompilerError("Initialization problem is structural singular. Please, check the initial conditions." );
    then ({}, true, {});

    case (currID, _, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);

      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_, listParameter))=parameterCheck((exp, {}));
      false=intGt(listLength(listParameter), 0);

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerError("The initialization problem is inconsistent due to the following equation: " +& BackendDump.equationString(eqn2) +& " (" +& BackendDump.equationString(eqn) +& ")");
    then ({}, false, {});

    case (currID, _, _, _, _, _, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_, listParameter))=parameterCheck((exp, {}));
      true=intGt(listLength(listParameter), 0);

      list_inEqns=BackendEquation.equationList(inEqns);
      list_inEqns = List.set(list_inEqns, currID, eqn);
      eqns = BackendEquation.listEquation(list_inEqns);
      funcs = BackendDAEUtil.getFunctions(shared);
      system = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
      (_, m, _, _, _) = BackendDAEUtil.getIncidenceMatrixScalar(system, BackendDAE.NORMAL(), SOME(funcs));
      listVar=m[currID];
      false=intEq(0, listLength(listVar));

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerNotification("It was not possible to analyze the given system symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    then ({}, false, {});

    case (currID, _, _, _, _, _, _, _) equation
      //true = intEq(listLength(inM[currID]), 0);
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.equationNth1(inEqns, currID);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_, listParameter))=parameterCheck((exp, {}));
      true=intGt(listLength(listParameter), 0);

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, currID);
      Error.addCompilerWarning("It was not possible to determine if the initialization problem is consistent, because of not evaluable parameters during compile time: " +& BackendDump.equationString(eqn2) +& " (" +& BackendDump.equationString(eqn) +& ")");
    then ({}, true, {currID});
  end matchcontinue;
end getConsistentEquation;

protected function parameterCheck "author: mwenzler"
   input tuple<DAE.Exp, list<String>> inExp;
  output tuple<DAE.Exp, list<String>> outExp;
protected
  DAE.Exp e;
  list<String> listParameter;
algorithm
  (e, listParameter) := inExp;
  (e, listParameter) := Expression.traverseExp(e, parameterCheck2, listParameter); // TODO: Was {}; why?
  outExp := (e, listParameter);
end parameterCheck;

protected function parameterCheck2
  input DAE.Exp exp;
  input list<String> inParams;
  output DAE.Exp outExp;
  output list<String> listParameter;
algorithm
  (outExp,listParameter) := match (exp,inParams)
    local
      DAE.Type ty;
      String Para;

    case (DAE.CREF(componentRef=DAE.CREF_QUAL(ident=Para), ty=ty), listParameter)
      equation
        listParameter=listAppend({Para}, listParameter);
      then (exp, listParameter);

    case (DAE.CREF(componentRef=DAE.CREF_IDENT(ident=Para), ty=ty), listParameter)
      equation
        listParameter=listAppend({Para}, listParameter);
      then (exp, listParameter);

    case (DAE.CREF(componentRef=DAE.CREF_ITER(ident=Para), ty=ty), listParameter)
      equation
        listParameter=listAppend({Para}, listParameter);
      then (exp, listParameter);

    else (exp, inParams);
  end match;
end parameterCheck2;


// =============================================================================
// section for introducing pre-variables for alias variables
//
// =============================================================================

protected function introducePreVarsForAliasVariables "author: lochel
  This function introduces all the pre-vars for the initial system that belong to alias vars."
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
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
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs)) equation
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

      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startValue, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);
      eqns = Debug.bcallret2(preUsed and isFixed, BackendEquation.addEquation, eqn, eqns, eqns);
    then (var, (vars, fixvars, eqns, hs));

    // discrete-time
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs)) equation
      isFixed = BackendVariable.varFixed(var);
      startValueOpt = BackendVariable.varStartValueOption(var);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValueOpt);

      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, preVar, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then (var, (vars, fixvars, eqns, hs));

    // continuous-time
    case (var as BackendDAE.VAR(varName=cr, varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs)) equation
      preUsed = BaseHashSet.has(cr, hs);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      fixvars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then (var, (vars, fixvars, eqns, hs));

    else (inVar,inTpl);
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
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, HashSet.HashSet> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
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
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(index=_), varType=ty), (vars, fixvars, eqns, hs)) equation
      isFixed = BackendVariable.varFixed(var);
      _ = BackendVariable.varStartValueOption(var);
      preUsed = BaseHashSet.has(cr, hs);

      startExp = BackendVariable.varStartValue(var);
      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = Debug.bcallret2(isFixed, BackendEquation.addEquation, eqn, eqns, eqns);

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

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), DAE.CREF(preCR, ty), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = BackendVariable.addVar(derVar, vars);
      vars = BackendVariable.addVar(var, vars);
      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);
      eqns = Debug.bcallret2(preUsed, BackendEquation.addEquation, eqn, eqns, eqns);
    then (var, (vars, fixvars, eqns, hs));

    // discrete (preUsed=true)
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty), (vars, fixvars, eqns, hs)) equation
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

      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startValue_, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = BackendVariable.addVar(var, vars);
      vars = BackendVariable.addVar(preVar, vars);
      eqns = BackendEquation.addEquation(eqn, eqns);
    then (var, (vars, fixvars, eqns, hs));

    // discrete
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE()), (vars, fixvars, eqns, hs)) equation
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
    then (var, (vars, fixvars, eqns, hs));

    // parameter without binding and fixed=true
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=NONE()), (vars, fixvars, eqns, hs)) equation
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
    then (var, (vars, fixvars, eqns, hs));

    // parameter with binding and fixed=false
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=ty), (vars, fixvars, eqns, hs)) equation
      true = intGt(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 31);
      false = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, NONE());

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(bindExp);
      info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNFIXED_PARAMETER_WITH_BINDING, {s, s, str}, info);

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), bindExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.addEquation(eqn, eqns);

      vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, hs));

    // *** MODELICA 3.1 COMPATIBLE ***
    // parameter with binding and fixed=false and no start value
    // use the binding as start value
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=_), (vars, fixvars, eqns, hs)) equation
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
    then (var, (vars, fixvars, eqns, hs));

    // *** MODELICA 3.1 COMPATIBLE ***
    // parameter with binding and fixed=false and a start value
    // ignore the binding and use the start value
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=_), (vars, fixvars, eqns, hs)) equation
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
    then (var, (vars, fixvars, eqns, hs));

    // parameter with constant binding
    case (var as BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars, eqns, hs)) equation
      true = Expression.isConst(bindExp);
      fixvars = BackendVariable.addVar(var, fixvars);
    then (var, (vars, fixvars, eqns, hs));

    // parameter
    case (var as BackendDAE.VAR(varKind=BackendDAE.PARAM()), (vars, fixvars, eqns, hs)) equation
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, hs));

    // skip constant
    case (var as BackendDAE.VAR(varKind=BackendDAE.CONST()), _) // equation
      // fixvars = BackendVariable.addVar(var, fixvars);
    then (var, inTpl);

    // VARIABLE (fixed=true)
    // DUMMY_STATE
    case (var as BackendDAE.VAR(varName=cr, varType=ty), (vars, fixvars, eqns, hs)) equation
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

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), startValue_, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = Debug.bcallret2(not isInput, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(isInput, BackendVariable.addVar, var, fixvars, fixvars);
      vars = Debug.bcallret2(preUsed, BackendVariable.addVar, preVar, vars, vars);
      eqns = BackendEquation.addEquation(eqn, eqns);

      // Error.addCompilerNotification("VARIABLE (fixed=true): " +& BackendDump.varString(var));
    then (var, (vars, fixvars, eqns, hs));

    // VARIABLE (fixed=false)
    // DUMMY_STATE
    case (var as BackendDAE.VAR(varName=cr, varType=ty), (vars, fixvars, eqns, hs)) equation
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
    then (var, (vars, fixvars, eqns, hs));

    else
      equation
        Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function collectInitialVars failed for: " +& BackendDump.varString(inVar));
      then fail();

  end matchcontinue;
end collectInitialVars;

protected function collectInitialEqns "author: lochel"
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.EquationArray, BackendDAE.EquationArray> inTpl;
  output BackendDAE.Equation eqn;
  output tuple<BackendDAE.EquationArray, BackendDAE.EquationArray> outTpl;
protected
  BackendDAE.Equation eqn1;
  BackendDAE.EquationArray eqns, reeqns;
  Integer size;
  Boolean b;
algorithm
  eqn := inEq;
  (eqns, reeqns) := inTpl;

  // replace der(x) with $DER.x and replace pre(x) with $PRE.x
  (eqn1, _) := BackendEquation.traverseBackendDAEExpsEqn(eqn, Expression.traverseSubexpressionsDummyHelper, replaceDerPreCref);

  // add it, if size is zero (terminate, assert, noretcall) move to removed equations
  size := BackendEquation.equationSize(eqn1);
  b := intGt(size, 0);

  eqns := Debug.bcallret2(b, BackendEquation.addEquation, eqn1, eqns, eqns);
  reeqns := Debug.bcallret2(not b, BackendEquation.addEquation, eqn1, reeqns, reeqns);
  outTpl := (eqns, reeqns);
end collectInitialEqns;

protected function replaceDerPreCref "author: Frenkel TUD 2011-05
  helper for replaceDerCref"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      DAE.ComponentRef dummyder, cr;
      DAE.Type ty;
      Integer i;

    case DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty))
      equation
        dummyder = ComponentReference.crefPrefixDer(cr);
      then DAE.CREF(dummyder, ty);

    case DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty))
      equation
        dummyder = ComponentReference.crefPrefixPre(cr);
      then DAE.CREF(dummyder, ty);

    else inExp;
  end match;
end replaceDerPreCref;

// =============================================================================
// section for bindings
//
// =============================================================================

protected function collectInitialBindings "author: lochel
  This function collects all the vars for the initial system."
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.EquationArray, BackendDAE.EquationArray> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.EquationArray, BackendDAE.EquationArray> outTpl;
algorithm
  (outVar,outTpl) := match (inVar,inTpl)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cr;
      DAE.Type ty;
      BackendDAE.EquationArray eqns, reeqns;
      DAE.Exp bindExp, crefExp;
      DAE.ElementSource source;
      BackendDAE.Equation eqn;

    // no binding
    case (var as BackendDAE.VAR(bindExp=NONE()), _) equation
    then (var, inTpl);

    // binding
    case (var as BackendDAE.VAR(varName=cr, bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns)) equation
      crefExp = DAE.CREF(cr, ty);
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.addEquation(eqn, eqns);
    then (var, (eqns, reeqns));

    else
      equation
        Error.addInternalError("./Compiler/BackEnd/Initialization.mo: function collectInitialBindings failed for: " +& BackendDump.varString(inVar));
      then fail();

  end match;
end collectInitialBindings;

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

    case (false, _, _, _)
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

    case (_, _, _, _, _, _, _) equation
      (_::_, _) = BackendVariable.getVar(cr2, knvars);
      e = Debug.bcallret1(negate, Expression.negate, e2, e2);
      initalAliases = BaseHashTable.add((cr1, e), iInitalAliases);
      Debug.fcall(Flags.DUMPOPTINIT, BackendDump.debugStrCrefStrExpStr, ("Found initial Alias ", cr1, " = ", e, "\n"));
    then initalAliases;

    case (_, _, _, _, _, _, _) equation
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
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(vars, eqns, m, mT, matching, stateSets, partitionKind) := inSyst;
  (vars, (_, b)) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars, optimizeInitialAliasesFinder, (initalAliases, false));
  outSyst := Util.if_(b, BackendDAE.EQSYSTEM(vars, eqns, m, mT, matching, stateSets, partitionKind), inSyst);
end optimizeInitialAliases;

protected function optimizeInitialAliasesFinder "author: Frenkel TUD 2011-03"
  input BackendDAE.Var inVar;
  input tuple<HashTable2.HashTable, Boolean> inTpl;
  output BackendDAE.Var outVar;
  output tuple<HashTable2.HashTable, Boolean> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      HashTable2.HashTable initalAliases;
      DAE.ComponentRef varName;
      DAE.Exp exp;

    case (v as BackendDAE.VAR(varName=varName), (initalAliases, _)) equation
      exp = BaseHashTable.get(varName, initalAliases);
      v = BackendVariable.setVarStartValue(v, exp);
      v = BackendVariable.setVarFixed(v, true);
      Debug.fcall(Flags.DUMPOPTINIT, BackendDump.debugStrCrefStrExpStr, ("Set Var ", varName, " (start= ", exp, ", fixed=true)\n"));
    then (v, (initalAliases, true));

    else (inVar,inTpl);
  end matchcontinue;
end optimizeInitialAliasesFinder;

end Initialization;
