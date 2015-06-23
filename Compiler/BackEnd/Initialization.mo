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
public import FCore;
public import HashSet;
public import Util;

protected import Array;
protected import BackendDAEEXT;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashSet;
protected import CheckModel;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;
protected import Matching;
protected import Sorting;
protected import SimCodeUtil;

// =============================================================================
// section for all public functions
//
// These are functions that can be used to access the initialization.
// =============================================================================

public function solveInitialSystem "author: lochel
  This function generates a algebraic system of equations for the initialization and solves it."
  input BackendDAE.BackendDAE inDAE "simulation system";
  output Option<BackendDAE.BackendDAE> outInitDAE "initialization system";
  output Boolean outUseHomotopy;
  output list<BackendDAE.Equation> outRemovedInitialEquations;
  output list<BackendDAE.Var> outPrimaryParameters "already sorted";
  output list<BackendDAE.Var> outAllPrimaryParameters "already sorted";
protected
  BackendDAE.BackendDAE dae;
  BackendDAE.Variables initVars;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  BackendDAE.Variables knvars, vars, fixvars, evars, eavars, avars;
  BackendDAE.EquationArray inieqns, eqns, emptyeqns, reeqns;
  BackendDAE.EqSystem initsyst;
  BackendDAE.BackendDAE initdae;
  FCore.Cache cache;
  FCore.Graph graph;
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
algorithm
  try
    // TODO: remove this once the initialization is moved before post-optimization
    dae := BackendDAEOptimize.symEulerInit(inDAE);

    // inline all when equations, if active with body else with lhs=pre(lhs)
    dae := inlineWhenForInitialization(dae);
    // fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, dae, "inlineWhenForInitialization");

    (initVars, outPrimaryParameters, outAllPrimaryParameters) := selectInitializationVariablesDAE(dae);
    // fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpVariables, initVars, "selected initialization variables");
    hs := collectPreVariables(dae);
    BackendDAE.DAE(systs, shared as BackendDAE.SHARED(knownVars=knvars,
                                                      aliasVars=avars,
                                                      initialEqs=inieqns,
                                                      constraints=constraints,
                                                      classAttrs=classAttrs,
                                                      cache=cache,
                                                      graph=graph,
                                                      functionTree=functionTree,
                                                      info=ei)) := dae;

    // collect vars and eqns for initial system
    vars := BackendVariable.emptyVars();
    fixvars := BackendVariable.emptyVars();
    eqns := BackendEquation.emptyEqns();
    reeqns := BackendEquation.emptyEqns();

    ((vars, fixvars, eqns, _)) := BackendVariable.traverseBackendDAEVars(avars, introducePreVarsForAliasVariables, (vars, fixvars, eqns, hs));
    ((vars, fixvars, eqns, _)) := BackendVariable.traverseBackendDAEVars(knvars, collectInitialVars, (vars, fixvars, eqns, hs));
    ((eqns, reeqns)) := BackendEquation.traverseEquationArray(inieqns, collectInitialEqns, (eqns, reeqns));

    // fcall2(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpEquationArray, eqns, "initial equations");

    ((vars, fixvars, eqns, reeqns, _)) := List.fold(systs, collectInitialVarsEqnsSystem, ((vars, fixvars, eqns, reeqns, hs)));

    ((eqns, reeqns)) := BackendVariable.traverseBackendDAEVars(vars, collectInitialBindings, (eqns, reeqns));

    // replace initial(), sample(...), delay(...) and homotopy(...)
    useHomotopy := BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns, simplifyInitialFunctions, false);

    vars := BackendVariable.rehashVariables(vars);
    fixvars := BackendVariable.rehashVariables(fixvars);
    evars := BackendVariable.emptyVars();
    eavars := BackendVariable.emptyVars();
    emptyeqns := BackendEquation.emptyEqns();
    shared := BackendDAE.SHARED(fixvars,
                                evars,
                                eavars,
                                emptyeqns,
                                reeqns,
                                constraints,
                                classAttrs,
                                cache,
                                graph,
                                functionTree,
                                BackendDAEUtil.emptyEventInfo(),
                                {},
                                BackendDAE.INITIALSYSTEM(),
                                {},
                                ei);

    // generate initial system and pre-balance it
    initsyst := BackendDAEUtil.createEqSystem(vars, eqns);
    (initsyst, dumpVars) := preBalanceInitialSystem(initsyst);
    SimCodeUtil.execStat("created initial system");

    // split the initial system into independend subsystems
    initdae := BackendDAE.DAE({initsyst}, shared);
    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      print(stringAppendList({"\ncreated initial system:\n\n"}));
      BackendDump.printBackendDAE(initdae);
    end if;

    (systs, shared) := BackendDAEOptimize.partitionIndependentBlocksHelper(initsyst, shared, Error.getNumErrorMessages(), true);
    initdae := BackendDAE.DAE(systs, shared);
    SimCodeUtil.execStat("partitioned initial system");

    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      print(stringAppendList({"\npartitioned initial system:\n\n"}));
      BackendDump.printBackendDAE(initdae);
    end if;
    // initdae := BackendDAE.DAE({initsyst}, shared);

    // fix over- and under-constrained subsystems
    (initdae, dumpVars2, removedEqns) := analyzeInitialSystem(initdae, dae, initVars);
    dumpVars := listAppend(dumpVars, dumpVars2);

    // some debug prints
    if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
      BackendDump.dumpBackendDAE(initdae, "initial system");
    end if;

    // now let's solve the system!
    initdae := BackendDAEUtil.mapEqSystem(initdae, solveInitialSystemEqSystem);

    // transform and optimize DAE
    pastOptModules := BackendDAEUtil.getPostOptModules(SOME({"constantLinearSystem", "tearingSystem", "calculateStrongComponentJacobians", "solveSimpleEquations"}));
    matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(NONE());
    daeHandler := BackendDAEUtil.getIndexReductionMethod(NONE());

    // solve system
    initdae := BackendDAEUtil.transformBackendDAE(initdae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());

    // simplify system
    (initdae, Util.SUCCESS()) := BackendDAEUtil.postOptimizeDAE(initdae, pastOptModules, matchingAlgorithm, daeHandler);
    if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
      BackendDump.dumpBackendDAE(initdae, "solved initial system");
      if Flags.isSet(Flags.ADDITIONAL_GRAPHVIZ_DUMP) then
        BackendDump.graphvizBackendDAE(initdae, "dumpinitialsystem");
      end if;
    end if;

    // warn about selected default initial conditions
    b1 := not listEmpty(dumpVars);
    b2 := not listEmpty(removedEqns);
    if Flags.isSet(Flags.INITIALIZATION) then
      if b1 then
        Error.addCompilerWarning("Assuming fixed start value for the following " + intString(listLength(dumpVars)) + " variables:\n" + warnAboutVars2(dumpVars));
      end if;
      if b2 then
        Error.addCompilerWarning("Assuming redundant initial conditions for the following " + intString(listLength(removedEqns)) + " initial equations:\n" + warnAboutEqns2(removedEqns));
      end if;
    else
      if b1 then
        Error.addCompilerWarning("The initial conditions are not fully specified. Use +d=initialization for more information.");
      end if;
      if b2 then
        Error.addCompilerWarning("The initial conditions are over specified. Use +d=initialization for more information.");
      end if;
    end if;

    // warn about iteration variables with default zero start attribute
    b := warnAboutIterationVariablesWithDefaultZeroStartAttribute(initdae);
    if b and (not Flags.isSet(Flags.INITIALIZATION)) then
      Error.addCompilerWarning("There are iteration variables with default zero start attribute. Use +d=initialization for more information.");
    end if;

    if Flags.isSet(Flags.DUMP_EQNINORDER) and Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
      BackendDump.dumpEqnsSolved(initdae, "initial system: eqns in order");
    end if;

    if Flags.isSet(Flags.ITERATION_VARS) then
      BackendDAEOptimize.listAllIterationVariables(initdae);
    end if;
    if Flags.isSet(Flags.DUMP_BACKENDDAE_INFO) or Flags.isSet(Flags.DUMP_STATESELECTION_INFO) or Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO) then
      BackendDump.dumpCompShort(initdae);
    end if;

    outInitDAE := SOME(initdae);
    outUseHomotopy := useHomotopy;
    outRemovedInitialEquations := removedEqns;
  else
    outInitDAE := NONE();
    outUseHomotopy := false;
    outRemovedInitialEquations := {};
    outPrimaryParameters := {};
    outAllPrimaryParameters := {};
  end try;
end solveInitialSystem;

// =============================================================================
// section for helper functions of solveInitialSystem
//
// =============================================================================

protected function solveInitialSystemEqSystem "author: lochel
  This solves the generated system."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem osyst = isyst;
  output BackendDAE.Shared outShared = inShared "unused";
protected
  Integer nVars, nEqns;
algorithm
  nEqns := BackendDAEUtil.systemSize(isyst);
  nVars := BackendVariable.varsSize(BackendVariable.daeVars(isyst));

  // over-determined system: nEqns > nVars
  if intGt(nEqns, nVars) then
    if Flags.isSet(Flags.INITIALIZATION) then
      Error.addCompilerWarning("It was not possible to solve the over-determined initial system (" + intString(nEqns) + " equations and " + intString(nVars) + " variables)");
      BackendDump.dumpEqSystem(isyst, "It was not possible to solve the over-determined initial system (" + intString(nEqns) + " equations and " + intString(nVars) + " variables)");
    end if;

    fail();
  end if;

  // under-determined system: nEqns < nVars
  if intLt(nEqns, nVars) then
    if Flags.isSet(Flags.INITIALIZATION) then
      Error.addCompilerWarning("It was not possible to solve the under-determined initial system (" + intString(nEqns) + " equations and " + intString(nVars) + " variables)");
      BackendDump.dumpEqSystem(isyst, "It was not possible to solve the under-determined initial system (" + intString(nEqns) + " equations and " + intString(nVars) + " variables)");
    end if;

    fail();
  end if;
end solveInitialSystemEqSystem;

// =============================================================================
// section for inlining when-clauses
//
// This section contains all the helper functions to replace all when-clauses
// from a given BackendDAE to get the initial equation system.
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

protected function inlineWhenForInitializationSystem "author: lochel"
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

  eqnlst := BackendEquation.traverseEquationArray(orderedEqs, inlineWhenForInitializationEquation, {});
  //print("Before: " + intString(listLength(eqnlst)) + "\n");
  eqnlst := List.uniqueOnTrue(eqnlst, BackendEquation.equationEqual) "hack for #3209";
  //print("After: " + intString(listLength(eqnlst)) + "\n");
  eqns := BackendEquation.listEquation(eqnlst);

  outEqSystem := BackendDAEUtil.createEqSystem(orderedVars, eqns, stateSets, partitionKind);
end inlineWhenForInitializationSystem;

protected function inlineWhenForInitializationEquation "author: lochel"
  input BackendDAE.Equation inEq;
  input list<BackendDAE.Equation> inAccEq;
  output BackendDAE.Equation outEq = inEq;
  output list<BackendDAE.Equation> outAccEq;
algorithm
  outAccEq := match (inEq)
    local
      DAE.ElementSource source;
      DAE.Algorithm alg;
      Integer size;
      list< DAE.Statement> stmts;
      list< BackendDAE.Equation> eqns;
      BackendDAE.WhenEquation weqn;
      list< DAE.ComponentRef> crefLst;
      HashSet.HashSet leftCrs;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes eqAttr;

    // when equation
    case BackendDAE.WHEN_EQUATION(whenEquation=weqn, source=source, attr=eqAttr) equation
      eqns = inlineWhenForInitializationWhenEquation(weqn, source, eqAttr, inAccEq);
    then eqns;

    // algorithm
    case BackendDAE.ALGORITHM(alg=alg, source=source,expand=crefExpand) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg;
      (stmts, leftCrs) = inlineWhenForInitializationWhenAlgorithm(stmts, {}, HashSet.emptyHashSetSized(50));
      alg = DAE.ALGORITHM_STMTS(stmts);
      size = listLength(CheckModel.checkAndGetAlgorithmOutputs(alg, source, crefExpand));
      crefLst = BaseHashSet.hashSetList(leftCrs);
      eqns = generateInactiveWhenEquationForInitialization(crefLst, source, inAccEq);
      eqns = List.consOnTrue(not listEmpty(stmts), BackendDAE.ALGORITHM(size, alg, source, crefExpand, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC), eqns);
    then eqns;

    else inEq::inAccEq;
  end match;
end inlineWhenForInitializationEquation;

protected function inlineWhenForInitializationWhenEquation "author: lochel"
  input BackendDAE.WhenEquation inWEqn;
  input DAE.ElementSource inSource;
  input BackendDAE.EquationAttributes inEqAttr;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(inWEqn)
    local
      DAE.ComponentRef left;
      DAE.Exp condition, right, crexp;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.WhenEquation weqn;
      BackendDAE.Variables vars;

    // active when equation during initialization
    case BackendDAE.WHEN_EQ(condition=condition, left=left, right=right) equation
      true = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExpBottomUp
      crexp = Expression.crefExp(left);
      eqn = BackendEquation.generateEquation(crexp, right, inSource, inEqAttr);
    then eqn::inEqns;

    // inactive when equation during initialization
    case BackendDAE.WHEN_EQ(condition=condition, left=left) equation
      false = Expression.containsInitialCall(condition, false);
      eqns = generateInactiveWhenEquationForInitialization(ComponentReference.expandCref(left, true), inSource, inEqns);
    then eqns;
  end matchcontinue;
end inlineWhenForInitializationWhenEquation;

protected function inlineWhenForInitializationWhenAlgorithm "author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem."
  input list< DAE.Statement> inStmts;
  input list< DAE.Statement> inAcc "={}";
  input HashSet.HashSet inLeftCrs;
  output list< DAE.Statement> outStmts;
  output HashSet.HashSet outLeftCrs;
algorithm
  (outStmts, outLeftCrs) := matchcontinue(inStmts)
    local
      DAE.Exp condition;
      list< DAE.ComponentRef> crefLst;
      DAE.Statement stmt;
      list< DAE.Statement> stmts, rest;
      HashSet.HashSet leftCrs;
      list<tuple<DAE.ComponentRef, Integer>> crintLst;

    case {}
    then (listReverse(inAcc), inLeftCrs);

    // when statement
    case (stmt as DAE.STMT_WHEN())::rest equation
      // for when statements it is not necessary that all branches have the same left hand side variables
      // -> take care that for each left hand side an assigment is generated
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, inLeftCrs, inAcc);
      (stmts, leftCrs) = inlineWhenForInitializationWhenAlgorithm(rest, stmts, leftCrs);
    then  (stmts, leftCrs);

    // no when statement
    case stmt::rest equation
      (stmts, leftCrs) = inlineWhenForInitializationWhenAlgorithm(rest, stmt::inAcc, inLeftCrs);
    then (stmts, leftCrs);
  end matchcontinue;
end inlineWhenForInitializationWhenAlgorithm;

protected function inlineWhenForInitializationWhenStmt "author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem."
  input DAE.Statement inWhenStatement;
  input HashSet.HashSet inLeftCrs;
  input list< DAE.Statement> inAcc;
  output list< DAE.Statement> outStmts;
  output HashSet.HashSet outLeftCrs;
algorithm
  (outStmts, outLeftCrs) := matchcontinue(inWhenStatement)
    local
      DAE.Exp condition;
      list< DAE.ComponentRef> crefLst;
      DAE.Statement stmt;
      list< DAE.Statement> stmts;
      HashSet.HashSet leftCrs;
      list<tuple<DAE.ComponentRef, Integer>> crintLst;

    // active when equation during initialization
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts) equation
      true = Expression.containsInitialCall(condition, false);
      stmts = List.foldr(stmts, List.consr, inAcc);
    then (stmts, inLeftCrs);

    // inactive when equation during initialization
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=NONE()) equation
      false = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      leftCrs = List.fold(crefLst, BaseHashSet.add, inLeftCrs);
    then (inAcc, leftCrs);

    // inactive when equation during initialization with elsewhen part
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts, elseWhen=SOME(stmt)) equation
      false = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      leftCrs = List.fold(crefLst, BaseHashSet.add, inLeftCrs);
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, leftCrs, inAcc);
    then (stmts, leftCrs);

    else equation
      Error.addInternalError("function inlineWhenForInitializationWhenStmt failed", sourceInfo());
    then fail();

  end matchcontinue;
end inlineWhenForInitializationWhenStmt;

protected function generateInactiveWhenEquationForInitialization "author: lochel"
  input list<DAE.ComponentRef> inCrLst;
  input DAE.ElementSource inSource;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns = inEqns;
protected
  DAE.Type identType;
  DAE.Exp crefExp, crefPreExp;
  BackendDAE.Equation eqn;
algorithm
  for cr in inCrLst loop
    identType := ComponentReference.crefTypeConsiderSubs(cr);
    crefExp := DAE.CREF(cr, identType);
    crefPreExp := Expression.makePureBuiltinCall("pre", {crefExp}, DAE.T_BOOL_DEFAULT);
    eqn := BackendDAE.EQUATION(crefExp, crefPreExp, inSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
    outEqns := eqn::outEqns;
  end for;
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
  //list<DAE.ComponentRef> crefs;
algorithm
  //BackendDump.dumpBackendDAE(inDAE, "inDAE");
  BackendDAE.DAE(systs, BackendDAE.SHARED(removedEqs=removedEqs, initialEqs=ieqns)) := inDAE;

  outHS := HashSet.emptyHashSet();
  outHS := List.fold(systs, collectPreVariablesEqSystem, outHS);
  ((_,outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns(removedEqs, Expression.traverseSubexpressionsHelper, (collectPreVariablesTraverseExp, outHS)); // ???
  ((_,outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns(ieqns, Expression.traverseSubexpressionsHelper, (collectPreVariablesTraverseExp, outHS));

  //print("collectPreVariables:\n");
  //crefs := BaseHashSet.hashSetList(outHS);
  //BackendDump.debuglst(crefs, ComponentReference.printComponentRefStr, "\n", "\n");
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
        (_, ohs) = Expression.traverseExpBottomUp(e, collectPreVariablesTraverseExp2, hs);
      then (e, ohs);

    case (DAE.CALL(path=Absyn.IDENT(name="change")), _)
      equation
        (_, ohs) = Expression.traverseExpBottomUp(e, collectPreVariablesTraverseExp2, hs);
      then (e, ohs);

    case (DAE.CALL(path=Absyn.IDENT(name="edge")), _)
      equation
        (_, ohs) = Expression.traverseExpBottomUp(e, collectPreVariablesTraverseExp2, hs);
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
  outWarning := warnAboutIterationVariablesWithDefaultZeroStartAttribute0(eqs,
    Flags.isSet(Flags.INITIALIZATION));
end warnAboutIterationVariablesWithDefaultZeroStartAttribute;

protected function warnAboutIterationVariablesWithDefaultZeroStartAttribute0 "author: lochel"
  input list<BackendDAE.EqSystem> inEqs;
  input Boolean inShowWarnings;
  output Boolean outWarning = false;
protected
  Boolean warn;
algorithm
  for eqs in inEqs loop
    warn := warnAboutIterationVariablesWithDefaultZeroStartAttribute1(eqs, inShowWarnings);
    outWarning := outWarning or warn;

    // If we found an iteration variable with default zero start attribute but
    // +initialization wasn't given, we don't need to continue searching.
    if warn and not inShowWarnings then
      return;
    end if;
  end for;
end warnAboutIterationVariablesWithDefaultZeroStartAttribute0;

protected function warnAboutIterationVariablesWithDefaultZeroStartAttribute1 "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  input Boolean inShowWarnings;
  output Boolean outWarning = false "True if any warnings were printed.";
protected
  BackendDAE.StrongComponents comps;
  BackendDAE.Variables ordered_vars;
  list<Integer> vlst = {};
  list<BackendDAE.Var> vars;
  String err;
algorithm
  BackendDAE.EQSYSTEM(orderedVars = ordered_vars,
                      matching = BackendDAE.MATCHING(comps = comps)) := inEqSystem;

  // Go through all the strongly connected components.
  for comp in comps loop
    // Get the component's variables and select the correct error message.
    (err, vlst) := matchcontinue(comp)
      case BackendDAE.EQUATIONSYSTEM(vars = vlst, jacType = BackendDAE.JAC_NONLINEAR())
        then ("nonlinear equation system:\n", vlst);
      case BackendDAE.EQUATIONSYSTEM(vars = vlst, jacType = BackendDAE.JAC_GENERIC())
        then ("equation system w/o analytic Jacobian:\n", vlst);
      case BackendDAE.EQUATIONSYSTEM(vars = vlst, jacType = BackendDAE.JAC_NO_ANALYTIC())
        then ("equation system w/o analytic Jacobian:\n", vlst);
      case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars = vlst), linear = false)
        then ("torn nonlinear equation system:\n", vlst);
      else ("", {});
      // If the component is none of these types, do nothing.
    end matchcontinue;

    if not listEmpty(vlst) then
      // Filter out the variables that are missing start values.
      vars := List.map1r(vlst, BackendVariable.getVarAt, ordered_vars);
      //vars := list(BackendVariable.getVarAt(ordered_vars, idx) for idx in vlst);
      vars := list(v for v guard(not BackendVariable.varHasStartValue(v)) in vars);
      //vars := List.filterOnTrue(vars, BackendVariable.varHasStartValue);

      // Print a warning if we found any variables with missing start values.
      if not listEmpty(vars) then
        outWarning := true;

        if inShowWarnings then
          Error.addCompilerWarning("Iteration variables with default zero start attribute in "
            + err + warnAboutVars2(vars));
        else
          // If +initialization wasn't given we don't need to continue searching
          // once we've found one.
          return;
        end if;
      end if;
    end if;
  end for;
end warnAboutIterationVariablesWithDefaultZeroStartAttribute1;

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
      crStr = "         " + BackendDump.varString(v);
    then crStr;

    case (v::vars) equation
      crStr = BackendDump.varString(v);
      str = "         " + crStr + "\n" + warnAboutVars2(vars);
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
      crStr = "         " + BackendDump.equationString(eq);
    then crStr;

    case (eq::eqns) equation
      crStr = BackendDump.equationString(eq);
      str = "         " + crStr + "\n" + warnAboutEqns2(eqns);
    then str;
  end match;
end warnAboutEqns2;

// =============================================================================
// section for selecting initialization variables
//
//   - unfixed state
//   - secondary parameter
//   - unfixed discrete -> pre(vd)
// =============================================================================

protected function selectInitializationVariablesDAE "author: lochel
  This function wraps selectInitializationVariables."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.Variables outVars;
  output list<BackendDAE.Var> outPrimaryParameters = {};
  output list<BackendDAE.Var> outAllPrimaryParameters = {};
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Variables knownVars, alias, allParameters;
  BackendDAE.EquationArray allParameterEqns;
  BackendDAE.EqSystem paramSystem;
  BackendDAE.IncidenceMatrix m, mT;
  array<Integer> ass1 "eqn := ass1[var]";
  array<Integer> ass2 "var := ass2[eqn]";
  list<list<Integer>> comps;
  list<Integer> flatComps;
  Integer nParam;
  array<Integer> secondary;
  BackendDAE.Var p;
  DAE.Exp bindExp;
algorithm
  BackendDAE.DAE(systs, BackendDAE.SHARED(knownVars=knownVars, aliasVars=alias)) := inDAE;
  outVars := selectInitializationVariables(systs);
  outVars := BackendVariable.traverseBackendDAEVars(knownVars, selectInitializationVariables2, outVars);
  outVars := BackendVariable.traverseBackendDAEVars(alias, selectInitializationVariables2, outVars);

  // select all parameters
  allParameters := BackendVariable.emptyVars();
  allParameterEqns := BackendEquation.emptyEqns();
  (allParameters, allParameterEqns) := BackendVariable.traverseBackendDAEVars(knownVars, selectParameter2, (allParameters, allParameterEqns));
  nParam := BackendVariable.varsSize(allParameters);

  if nParam > 0 then
    //BackendDump.dumpVariables(allParameters, "all parameters");
    //BackendDump.dumpEquationArray(allParameterEqns, "all parameter equations");

    paramSystem := BackendDAEUtil.createEqSystem(allParameters, allParameterEqns);
    (m, mT) := BackendDAEUtil.incidenceMatrix(paramSystem, BackendDAE.NORMAL(), NONE());
    //BackendDump.dumpIncidenceMatrix(m);
    //BackendDump.dumpIncidenceMatrixT(mT);

    // match the system
    // ass1 and ass2 should be {1, 2, ..., nParam}
    (ass1, ass2) := Matching.PerfectMatching(m);
    //BackendDump.dumpMatchingVars(ass1);
    //BackendDump.dumpMatchingEqns(ass2);

    comps := Sorting.Tarjan(m, ass1);
    //BackendDump.dumpComponentsOLD(comps);
    comps := mapListIndices(comps, ass2) "map to var indices (not really needed, since ass2 should be {1, 2, ..., nParam})" ;
    //BackendDump.dumpComponentsOLD(comps);

    // flattern list and look for cyclic dependencies
    flatComps := list(flattenParamComp(comp, allParameters) for comp in comps);
    //BackendDump.dumpIncidenceRow(flatComps);

    // select secondary parameters
    secondary := arrayCreate(nParam, 0);
    secondary := selectSecondaryParameters(flatComps, allParameters, mT, secondary);
    //BackendDump.dumpMatchingVars(secondary);

    // get primary and secondary parameters
    for i in flatComps loop
      p := BackendVariable.getVarAt(allParameters, i);
      if 1 == secondary[i] then
        outVars := BackendVariable.addVar(p, outVars);
      else
        outAllPrimaryParameters := p::outAllPrimaryParameters;
        try
          bindExp := BackendVariable.varBindExpStartValue(p);
          if not Expression.isConst(bindExp) then
            outPrimaryParameters := p::outPrimaryParameters;
          end if;
        else
        end try;
      end if;
    end for;

    outPrimaryParameters := listReverse(outPrimaryParameters);
    outAllPrimaryParameters := listReverse(outAllPrimaryParameters);
  end if;
end selectInitializationVariablesDAE;

protected function markIndex
  input Integer inIndex;
  input array<Integer> inArray;
  output array<Integer> outArray = inArray;
algorithm
  outArray[inIndex] := 1;
end markIndex;

protected function selectSecondaryParameters
  input list<Integer> inOrdering;
  input BackendDAE.Variables inParameters;
  input BackendDAE.IncidenceMatrix inM;
  input array<Integer> inSecondaryParams;
  output array<Integer> outSecondaryParams;
algorithm
  outSecondaryParams := match inOrdering
    local
      Integer i;
      array<Integer> secondaryParams;
      list<Integer> rest;
      BackendDAE.Var param;

    case {}
    then inSecondaryParams;

    // fixed=false
    case i::rest equation
      param = BackendVariable.getVarAt(inParameters, i);
      secondaryParams = if (not BackendVariable.varFixed(param)) or 1 == inSecondaryParams[i]
        then List.fold(inM[i], markIndex, inSecondaryParams)
        else inSecondaryParams;
      secondaryParams = selectSecondaryParameters(rest, inParameters, inM, secondaryParams);
    then secondaryParams;

  end match;
end selectSecondaryParameters;

protected function flattenParamComp
  input list<Integer> paramIndices;
  input BackendDAE.Variables inAllParameters;
  output Integer outFlatComp;
algorithm
  outFlatComp := match paramIndices
    local
      Integer i;
      list<BackendDAE.Var> paramLst;
      BackendDAE.Var param;

    case {i} then i;

    else algorithm
      paramLst := {};
      for i in paramIndices loop
        param := BackendVariable.getVarAt(inAllParameters, i);
        paramLst := param::paramLst;
      end for;
      Error.addCompilerError("Cyclically dependent parameters found:\n" + warnAboutVars2(paramLst));
    then fail();
  end match;
end flattenParamComp;

protected function selectInitializationVariables "author: lochel"
  input list<BackendDAE.EqSystem> inEqSystems;
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
  BackendDAE.Variables orderedVars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars) := inEqSystem;
  outVars := BackendVariable.traverseBackendDAEVars(orderedVars, selectInitializationVariables2, inVars);
end selectInitializationVariables1;

protected function selectParameter2 "author: lochel"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables, BackendDAE.EquationArray> inTpl;
  output BackendDAE.Var outVar = inVar;
  output tuple<BackendDAE.Variables, BackendDAE.EquationArray> outTpl;
algorithm
  outTpl := match (inVar, inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      DAE.Exp bindExp, crefExp, startValue;
      BackendDAE.Equation eqn;
      DAE.ComponentRef cref;

    // parameter without binding
    case (BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=NONE()), (vars, eqns)) equation
      vars = BackendVariable.addVar(inVar, vars);

      cref = BackendVariable.varCref(inVar);
      crefExp = Expression.crefExp(cref);
      startValue = BackendVariable.varStartValue(inVar);
      eqn = BackendDAE.EQUATION(crefExp, startValue, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.addEquation(eqn, eqns);
    then ((vars, eqns));

    // parameter with binding
    case (BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, eqns)) equation
      vars = BackendVariable.addVar(inVar, vars);

      cref = BackendVariable.varCref(inVar);
      crefExp = Expression.crefExp(cref);
      eqn = BackendDAE.EQUATION(crefExp, bindExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.addEquation(eqn, eqns);
    then ((vars, eqns));

    else inTpl;
  end match;
end selectParameter2;

protected function selectInitializationVariables2 "author: lochel"
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVars;
  output BackendDAE.Var outVar;
  output BackendDAE.Variables outVars;
algorithm
  (outVar, outVars) := matchcontinue (inVar, inVars)
    local
      BackendDAE.Var preVar;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr, preCR;
      DAE.Type ty;
      DAE.InstDims arryDim;

    // unfixed state
    case (BackendDAE.VAR(varKind=BackendDAE.STATE()), vars) equation
      false = BackendVariable.varFixed(inVar);
      vars = BackendVariable.addVar(inVar, vars);
    then (inVar, vars);

    // unfixed discrete -> pre(vd)
    case (BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), vars) equation
      false = BackendVariable.varFixed(inVar);
      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      vars = BackendVariable.addVar(preVar, vars);
    then (inVar, vars);

    else (inVar, inVars);
  end matchcontinue;
end selectInitializationVariables2;

// =============================================================================
// section for simplifying initial functions
//
// =============================================================================

protected function simplifyInitialFunctions
  input DAE.Exp inExp;
  input Boolean inUseHomotopy;
  output DAE.Exp exp;
  output Boolean useHomotopy;
algorithm
  (exp, useHomotopy) := Expression.traverseExpBottomUp(inExp, simplifyInitialFunctionsExp, inUseHomotopy);
end simplifyInitialFunctions;

protected function simplifyInitialFunctionsExp
  input DAE.Exp inExp;
  input Boolean useHomotopy;
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp,outUseHomotopy) := match (inExp,useHomotopy)
    local
      DAE.Exp e1, e2, e3, actual, simplified;

    case (DAE.CALL(path = Absyn.IDENT(name="initial")), _)
    then (DAE.BCONST(true), useHomotopy);

    case (DAE.CALL(path = Absyn.IDENT(name="sample")), _)
    then (DAE.BCONST(false), useHomotopy);

    case (DAE.CALL(path = Absyn.IDENT(name="delay"), expLst = _::e1::_ ), _)
    then (e1, useHomotopy);

    case (DAE.CALL(path = Absyn.IDENT(name="homotopy"), expLst = actual::simplified::_ ), _) //equation
    //  e1 = Expression.makePureBuiltinCall("homotopyParameter", {}, DAE.T_REAL_DEFAULT);
    //  e2 = DAE.BINARY(e1, DAE.MUL(DAE.T_REAL_DEFAULT), actual);
    //  e3 = DAE.BINARY(DAE.RCONST(1.0), DAE.SUB(DAE.T_REAL_DEFAULT), e1);
    //  e1 = DAE.BINARY(e3, DAE.MUL(DAE.T_REAL_DEFAULT), simplified);
    //  e3 = DAE.BINARY(e2, DAE.ADD(DAE.T_REAL_DEFAULT), e1);
    //then (e3, true);
    then (inExp, true);

    else (inExp, useHomotopy);
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
  (_, mt) := BackendDAEUtil.incidenceMatrix(inSystem, BackendDAE.NORMAL(), NONE());
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets, partitionKind=partitionKind) := inSystem;
  (orderedVars, orderedEqs, b, outDumpVars) := preBalanceInitialSystem1(arrayLength(mt), mt, orderedVars, orderedEqs, false, {});
  outSystem := if b then BackendDAEUtil.createEqSystem(orderedVars, orderedEqs, stateSets, partitionKind) else inSystem;
end preBalanceInitialSystem;

protected function preBalanceInitialSystem1 "author: lochel"
  input Integer n;
  input BackendDAE.IncidenceMatrix mt;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs;
  input Boolean inB;
  input list<BackendDAE.Var> inDumpVars;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqs;
  output Boolean outB;
  output list<BackendDAE.Var> outDumpVars;
algorithm
  (outVars, outEqs, outB, outDumpVars) := match (n, inB)
    local
      list<Integer> row;
      Boolean b, useHomotopy;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqs;
      list<BackendDAE.Var> rvarlst;
      BackendDAE.Var var;
      DAE.ComponentRef cref;
      list<BackendDAE.Var> dumpVars;

    case (0, false)
    then (inVars, inEqs, false, inDumpVars);

    case (0, true) equation
      vars = BackendVariable.listVar1(BackendVariable.varList(inVars));
    then (vars, inEqs, true, inDumpVars);

    else equation
      true = n > 0;
      (vars, eqs, b, dumpVars) = preBalanceInitialSystem2(n, mt, inVars, inEqs, inB, inDumpVars);
      (vars, eqs, b, dumpVars) = preBalanceInitialSystem1(n-1, mt, vars, eqs, b, dumpVars);
    then (vars, eqs, b, dumpVars);

  end match;
end preBalanceInitialSystem1;

protected function preBalanceInitialSystem2 "author: lochel"
  input Integer n;
  input BackendDAE.IncidenceMatrix mt;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs;
  input Boolean inB;
  input list<BackendDAE.Var> inDumpVars;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqs;
  output Boolean outB;
  output list<BackendDAE.Var> outDumpVars;
algorithm
  (outVars, outEqs, outB, outDumpVars) := matchcontinue(n, mt, inVars, inEqs, inB, inDumpVars)
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
      true = listEmpty(row);

      var = BackendVariable.getVarAt(inVars, n);
      cref = BackendVariable.varCref(var);
      true = ComponentReference.isPreCref(cref);

      (vars, _) = BackendVariable.removeVars({n}, inVars, {});
    then (vars, inEqs, true, inDumpVars);

    case (_, _, _, _, _, _) equation
      row = mt[n];
      true = listEmpty(row);

      var = BackendVariable.getVarAt(inVars, n);
      cref = BackendVariable.varCref(var);
      false = ComponentReference.isPreCref(cref);

      (eqs, dumpVars) = addStartValueEquations({var}, inEqs, inDumpVars);
    then (inVars, eqs, true, dumpVars);

    case (_, _, _, _, _, _) equation
      row = mt[n];
      false = listEmpty(row);
    then (inVars, inEqs, inB, inDumpVars);

    else equation
      Error.addInternalError("function preBalanceInitialSystem1 failed", sourceInfo());
    then fail();
  end matchcontinue;
end preBalanceInitialSystem2;

protected function analyzeInitialSystem "author: lochel
  This function fixes discrete and state variables to balance the initial equation system."
  input BackendDAE.BackendDAE initDAE;
  input BackendDAE.BackendDAE inDAE "original DAE";
  input BackendDAE.Variables inInitVars;
  output BackendDAE.BackendDAE outDAE;
  output list<BackendDAE.Var> outDumpVars;
  output list<BackendDAE.Equation> outRemovedEqns;
protected
  BackendDAE.BackendDAE dae;
  BackendDAE.EqSystem syst;
  list<BackendDAE.EqSystem> systs, systs2;
  BackendDAE.Shared shared;
  BackendDAE.EquationArray orderedEqs;
algorithm
  // filter empty systems
  BackendDAE.DAE(systs, shared) := initDAE;
  systs2 := {};
  outRemovedEqns := {};
  for syst in systs loop
    if BackendDAEUtil.nonEmptySystem(syst) then
      systs2 := syst::systs2;
    else
      BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := syst;
      outRemovedEqns := listAppend(outRemovedEqns, BackendEquation.equationList(orderedEqs));
    end if;
  end for;
  dae := BackendDAE.DAE(systs2, shared);

  (outDAE, (_, _, outDumpVars, outRemovedEqns)) := BackendDAEUtil.mapEqSystemAndFold(dae, analyzeInitialSystem2, (inDAE, inInitVars, {}, outRemovedEqns));
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
  lst := listAppend(lst, if BackendEquation.isInitialEquation(inEquation) then {pos} else {});
  outTpl := (pos+1, lst);
end getInitEqIndex;

protected function analyzeInitialSystem2 "author: lochel"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input tuple<BackendDAE.BackendDAE, BackendDAE.Variables, list<BackendDAE.Var>, list<BackendDAE.Equation>> inTpl;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared = inShared;
  output tuple<BackendDAE.BackendDAE, BackendDAE.Variables, list<BackendDAE.Var>, list<BackendDAE.Equation>> outTpl;
algorithm
  (osyst, outTpl) := matchcontinue(isyst, inTpl)
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

    // (regular) determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (inDAE, initVars, dumpVars, removedEqns)) equation
// print("index-0 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, inShared, 0);
// print("index-0 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAEUtil.createEqSystem(vars, eqns2);
    then (system, (inDAE, initVars, dumpVars, removedEqns));

    // (index-1) mixed-determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (inDAE, initVars, dumpVars, removedEqns)) equation
// print("index-1 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, inShared, 1);
// print("index-1 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAEUtil.createEqSystem(vars, eqns2);
    then (system, (inDAE, initVars, dumpVars, removedEqns));

    // (index-2) mixed-determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (inDAE, initVars, dumpVars, removedEqns)) equation
// print("index-2 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, inShared, 2);
// print("index-2 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAEUtil.createEqSystem(vars, eqns2);
    then (system, (inDAE, initVars, dumpVars, removedEqns));

    // (index-3) mixed-determined system
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), (inDAE, initVars, dumpVars, removedEqns)) equation
// print("index-3 start\n");
      (eqns2, dumpVars2, removedEqns2) = fixInitialSystem(vars, eqns, initVars, inShared, 3);
// print("index-3 ende\n");

      // add dummy var + dummy eqn
      dumpVars = listAppend(dumpVars, dumpVars2);
      removedEqns = listAppend(removedEqns, removedEqns2);
      system = BackendDAEUtil.createEqSystem(vars, eqns2);
    then (system, (inDAE, initVars, dumpVars, removedEqns));

    else fail();
  end matchcontinue;
end analyzeInitialSystem2;

protected function fixInitialSystem "author: lochel
  This function handles under-, over-, and mixed-determined systems with a given index."
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inInitVars;
  input BackendDAE.Shared inShared;
  input Integer inIndex "index of the system (0 is regular)";
  output BackendDAE.EquationArray outEqns;
  output list<BackendDAE.Var> outDumpVars;
  output list<BackendDAE.Equation> outRemovedEqns;
protected
  Integer nVars, nEqns, nInitEqs, nAddEqs, nAddVars;
  list<Integer> stateIndices, range, initEqsIndices, redundantEqns;
  list<BackendDAE.Var> initVarList;
  array<Integer> ass1, ass2;
  BackendDAE.IncidenceMatrix m "incidence matrix of modified system";
  BackendDAE.IncidenceMatrix m_ "incidence matrix of original system (TODO: fix this one)";
  BackendDAE.EqSystem syst;
  DAE.FunctionTree funcs;
  BackendDAE.AdjacencyMatrixEnhanced me;
  array<Integer> mapIncRowEqn;
  Boolean perfectMatching;
algorithm
  // nVars = nEqns
  nVars := BackendVariable.varsSize(inVars);
  nEqns := BackendDAEUtil.equationSize(inEqns);
  syst := BackendDAEUtil.createEqSystem(inVars, inEqns);
  funcs := BackendDAEUtil.getFunctions(inShared);
  (m_, _, _, mapIncRowEqn) := BackendDAEUtil.incidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs));
//BackendDump.dumpEqSystem(syst, "fixInitialSystem");
//BackendDump.dumpVariables(inInitVars, "selected initialization variables");
//BackendDump.dumpIncidenceMatrix(m_);

  // get state-index list
  stateIndices := BackendVariable.getVarIndexFromVariables(inInitVars, inVars);
//print("{" + stringDelimitList(List.map(stateIndices, intString),",") + "}\n");

  // get initial equation-index list
  //(initEqs, _) := List.extractOnTrue(BackendEquation.equationList(inEqns), BackendEquation.isInitialEquation);
  //nInitEqs := BackendDAEUtil.equationSize(BackendEquation.listEquation(initEqs));
  ((_, initEqsIndices)) := List.fold(BackendEquation.equationList(inEqns), getInitEqIndex, (1, {}));
  nInitEqs := listLength(initEqsIndices);
//print("{" + stringDelimitList(List.map(initEqsIndices, intString),",") + "}\n");

  // modify incidence matrix for under-determined systems
  nAddEqs := intMax(nVars-nEqns + inIndex, inIndex);
//print("nAddEqs: " + intString(nAddEqs) + "\n");
  m_ := fixUnderDeterminedSystem(m_, stateIndices, nEqns, nAddEqs);
  m := arrayCopy(m_) "deep copy";

  // modify incidence matrix for over-determined systems
  nAddVars := intMax(nEqns-nVars + inIndex, inIndex);
//print("nAddVars: " + intString(nAddVars) + "\n");
  m := fixOverDeterminedSystem(m, initEqsIndices, nVars, nAddVars);

  // match the system (nVars+nAddVars == nEqns+nAddEqs)
  ass1 := arrayCreate(nVars+nAddVars, -1);
  ass2 := arrayCreate(nEqns+nAddEqs, -1);
  Matching.matchingExternalsetIncidenceMatrix(nVars+nAddVars, nEqns+nAddEqs, m);
  BackendDAEEXT.matching(nVars+nAddVars, nEqns+nAddEqs, 5, 0, 0.0, 1);
  BackendDAEEXT.getAssignment(ass2, ass1);
  perfectMatching := listEmpty(Matching.getUnassigned(nVars+nAddVars, ass1, {}));
  // (ass1, ass2, perfectMatching) := Matching.RegularMatching(m, nVars+nAddVars, nEqns+nAddEqs);
  //BackendDump.dumpMatchingVars(ass1);
  //BackendDump.dumpMatchingEqns(ass2);

  // check whether or not a complete matching was found
  if not perfectMatching then
    Error.addCompilerNotification("The given system is mixed-determined.   [index > " + intString(inIndex) + "]");
    //BackendDump.dumpEqSystem(syst, "The given system is mixed-determined.   [index > " + intString(inIndex) + "]");
    fail();
  end if;

  // map artificial variables to redundant equations
  range := if nAddVars > 0 then List.intRange2(nVars+1, nVars+nAddVars) else {};
  redundantEqns := mapIndices(range, ass1);
//print("{" + stringDelimitList(List.map(redundantEqns, intString),",") + "}\n");

  // symbolic consistency check
  (me, _, _, _) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst, inShared,false);
  (_, _, _) := consistencyCheck(redundantEqns, inEqns, inVars, inShared, nAddVars, m_, me, ass1, ass2, mapIncRowEqn);

  // remove redundant equations
  outRemovedEqns := BackendEquation.getEqns(redundantEqns, inEqns);
//BackendDump.dumpEquationList(outRemovedEqns, "removed equations");
  outEqns := BackendEquation.equationDelete(inEqns, redundantEqns);
//BackendDump.dumpEquationArray(outEqns, "remaining equations");

  // map artificial equations to unfixed states
  range := if nAddEqs > 0 then List.intRange2(nEqns+1, nEqns+nAddEqs) else {};
  range := mapIndices(range, ass2);
//print("{" + stringDelimitList(List.map(range, intString),",") + "}\n");

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
      true = (inNAddEqns > 0) "just to be careful";
      m = arrayCreate(inNEqns+inNAddEqns, {});
      m = Array.copy(inM, m);
      newEqIndices = List.intRange2(inNEqns+1, inNEqns+inNAddEqns);
      m = List.fold1(newEqIndices, squareIncidenceMatrix1, inInitVarIndices, m);
    then m;
  end match;
end fixUnderDeterminedSystem;

protected function squareIncidenceMatrix1 "author: lochel"
  input Integer inPos;
  input list<Integer> inDependency;
  input BackendDAE.IncidenceMatrix inM;
  output BackendDAE.IncidenceMatrix outM = inM;
algorithm
  outM[inPos] := inDependency;
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
      true = (inNAddVars > 0) "just to be careful";
      newVarIndices = List.intRange2(inNVars+1, inNVars+inNAddVars);
      m = List.fold1(inInitEqnIndices, squareIncidenceMatrix2, newVarIndices, inM);
    then m;
  end match;
end fixOverDeterminedSystem;

protected function squareIncidenceMatrix2 "author: lochel"
  input Integer inPos;
  input list<Integer> inRange;
  input BackendDAE.IncidenceMatrix inM;
  output BackendDAE.IncidenceMatrix outM = inM;
algorithm
  outM[inPos] := listAppend(inM[inPos], inRange);
end squareIncidenceMatrix2;

protected function addStartValueEquations "author: lochel"
  input list<BackendDAE.Var> inVarLst;
  input BackendDAE.EquationArray inEqns;
  input list<BackendDAE.Var> inDumpVars;
  output BackendDAE.EquationArray outEqns = inEqns;
  output list<BackendDAE.Var> outDumpVars = inDumpVars "this are the variables that get fixed (not the same as inVarLst!)";
protected
  BackendDAE.Var dumpVar;
  BackendDAE.Equation eqn;
  DAE.Exp e, crefExp, startExp;
  DAE.ComponentRef cref;
  DAE.Type tp;
  Boolean isPreCref;
algorithm
  for var in inVarLst loop
    cref := BackendVariable.varCref(var);
    tp := BackendVariable.varType(var);
    crefExp := DAE.CREF(cref, tp);
    isPreCref := ComponentReference.isPreCref(cref);

    if isPreCref then
      cref := ComponentReference.popPreCref(cref);
    end if;

    e := Expression.crefExp(cref);
    tp := Expression.typeof(e);
    startExp := Expression.makePureBuiltinCall("$_start", {e}, tp);

    eqn := BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
    outEqns := BackendEquation.addEquation(eqn, outEqns);

    if isPreCref then
      dumpVar := BackendVariable.copyVarNewName(cref, var);
      // crStr = BackendDump.varString(dumpVar);
      // fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "  " + crStr);

      outDumpVars := dumpVar::outDumpVars;
    else
      // crStr = BackendDump.varString(var);
      // fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "  " + crStr);

      outDumpVars := var::outDumpVars;
    end if;
  end for;
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
  input list<Integer> inRedundantEqns "these are the indices of the redundant equations";
  input BackendDAE.EquationArray inEqns "this are all equations of the given system";
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared inShared;
  input Integer nAddVars;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<Integer> vecVarToEqs;
  input array<Integer> vecEqsToVar;
  input array<Integer> mapIncRowEqn;
  output list<Integer> outConsistentEquations "These equations are consistent and can be removed from the initialization problem without any issue.";
  output list<Integer> outInconsistentEquations "If this list is not empty then the initialization problem is inconsistent and has no solution.";
  output list<Integer> outUncheckedEquations "These equations need to be checked numerically.";
algorithm
  (outConsistentEquations, outInconsistentEquations, outUncheckedEquations) := matchcontinue(inRedundantEqns)
    local
      list<Integer> outRange, resiRange, flatComps, markedComps;
      list<Integer> outListComps, outLoopListComps, restRedundantEqns;
      list<Integer> consistentEquations, inconsistentEquations, uncheckedEquations, uncheckedEquations2;
      BackendDAE.IncidenceMatrix m;
      Integer nVars, nEqns, currRedundantEqn, redundantEqn;
      list<list<Integer>> comps;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EquationArray substEqns;

    case {}
    then ({}, {}, {});

    case currRedundantEqn::restRedundantEqns equation
      nVars = BackendVariable.varsSize(inVars);
      _ = BackendDAEUtil.equationSize(inEqns);
    //BackendDump.dumpMatchingVars(vecVarToEqs);
    //BackendDump.dumpMatchingEqns(vecEqsToVar);
    //BackendDump.dumpVariables(inVars, "inVars");
    //BackendDump.dumpEquationArray(inEqns, "inEqns");
    //BackendDump.dumpList(inRedundantEqns, "inRedundantEqns: ");
    //BackendDump.dumpIncidenceMatrix(inM);

      // get the sorting and algebraic loops
      comps = Sorting.Tarjan(inM, vecVarToEqs);
      flatComps = List.flatten(comps);
    //BackendDump.dumpComponentsOLD(comps);

      // split comps in a list with all equations that are part of a algebraic
      // loop and in one list with all other equations
      (_, outLoopListComps) = splitStrongComponents(comps);
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
      repl = setupVarReplacements(markedComps, inEqns, inVars, vecEqsToVar, repl, mapIncRowEqn, me, inShared);
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

    // add current equation to list of inconsistent equations
    case currRedundantEqn::restRedundantEqns equation
      (consistentEquations, inconsistentEquations, uncheckedEquations) = consistencyCheck(restRedundantEqns, inEqns, inVars, inShared, nAddVars, inM, me, vecVarToEqs, vecEqsToVar, mapIncRowEqn);
    then (consistentEquations, currRedundantEqn::inconsistentEquations, uncheckedEquations);
  end matchcontinue;
end consistencyCheck;

protected function isVarExplicitSolvable
  input BackendDAE.AdjacencyMatrixElementEnhanced inElem;
  input Integer inVarID;
  output Boolean outSolvable;
algorithm
  outSolvable := matchcontinue(inElem)
    local
      Integer id;
      BackendDAE.AdjacencyMatrixElementEnhanced elem;
      Boolean b;

    case {}
    then true;

    //case (id, BackendDAE.SOLVABILITY_SOLVED())::elem equation
    //  true = intEq(id, inVarID);
    //then false;

    case (id, BackendDAE.SOLVABILITY_UNSOLVABLE())::_ equation
      true = intEq(id, inVarID);
    then false;

    case (id, BackendDAE.SOLVABILITY_NONLINEAR())::_ equation
      true = intEq(id, inVarID);
    then false;

    case (_, _)::elem equation
      b = isVarExplicitSolvable(elem, inVarID);
    then b;
  end matchcontinue;
end isVarExplicitSolvable;

protected function splitStrongComponents "author: mwenzler"
  input list<list<Integer>> inComps "list of strong components";
  output list<Integer> outListComps "all components of size 1";
  output list<Integer> outLoopListComps "all components of size > 1";
algorithm
  (outListComps, outLoopListComps) := match(inComps)
    local
      Integer currIndex;
      list<Integer> currComp, listComps, loopListComps;
      list<list<Integer>> restComps;

    case {}
    then ({}, {});

    case {currIndex}::restComps equation
      (listComps, loopListComps) = splitStrongComponents(restComps);
    then (currIndex::listComps, loopListComps);

    case currComp::restComps equation
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

protected function mapListIndices "author: lochel
  This function applies 'inMapping' to the input index list list."
  input list<list<Integer>> inListIndices;
  input array<Integer> inMapping;
  output list<list<Integer>> outListIndices;
algorithm
  outListIndices := List.map1(inListIndices, mapIndices, inMapping);
end mapListIndices;

protected function compsMarker "author: mwenzler"
  input Integer inUnassignedEqn;
  input array<Integer> inVecVarToEq;
  input BackendDAE.IncidenceMatrix inM;
  input list<Integer> inFlatComps;
  input list<Integer> inLoopListComps "not used yet";
  output list<Integer> outMarkedEqns "contains all the indices of the equations that need to be considered";
protected
  list<Integer> varList;
  list<Integer> markedEqns;
algorithm
  try
    false := listMember(inUnassignedEqn, inLoopListComps);
    varList := inM[inUnassignedEqn];
    markedEqns := compsMarker2(varList, inVecVarToEq, inM, inFlatComps, {}, inLoopListComps);

    outMarkedEqns := downCompsMarker(listReverse(inFlatComps), inVecVarToEq, inM, inFlatComps, markedEqns, inLoopListComps);
  else
    // TODO: change the message
    Error.addCompilerNotification("It was not possible to analyze the given system symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    fail();
  end try;
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
  outMarkedEqns := matchcontinue (inVarList)
    local
      Integer indexVar, indexEq;
      list<Integer> var_list2, var_list3;
      list<Integer> markedEqns;

    case {} equation
    then inMarkedEqns;

    case indexVar::var_list2 equation
      indexEq = inVecVarToEq[indexVar];
      false = listMember(indexEq, inLoopListComps);
      false = listMember(indexEq, inMarkedEqns);
      markedEqns = compsMarker2(var_list2, inVecVarToEq, inM, inFlatComps, inMarkedEqns, inLoopListComps);
    then indexEq::markedEqns;

    case indexVar::var_list2 equation
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
  outMarkedEqns := matchcontinue (unassignedEqns)
    local
      list<Integer> unassignedEqns2, var_list;
      Integer indexUnassigned, marker;
      list<Integer> markedEqns;

    case {}
    then inMarkedEqns;

    case indexUnassigned::unassignedEqns2 equation
      true = listMember(indexUnassigned, inMarkedEqns);
      var_list = m[indexUnassigned];
      markedEqns = compsMarker2(var_list, vecVarToEq, m, flatComps, inMarkedEqns, inLoopListComps);
      markedEqns = downCompsMarker(unassignedEqns2, vecVarToEq, m, flatComps, markedEqns, inLoopListComps);
    then markedEqns;

    case _::unassignedEqns2 equation
      markedEqns = downCompsMarker(unassignedEqns2, vecVarToEq, m, flatComps, inMarkedEqns, inLoopListComps);
    then markedEqns;
  end matchcontinue;
end downCompsMarker;

protected function setupVarReplacements
  input list<Integer> inMarkedEqns;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVars;
  input array<Integer> inVecEqToVar "matching";
  input BackendVarTransform.VariableReplacements inRepls "initially call this with empty replacements";
  input array<Integer> inMapIncRowEqn;
  input BackendDAE.AdjacencyMatrixEnhanced inME;
  input BackendDAE.Shared inShared;
  output BackendVarTransform.VariableReplacements outRepls;
algorithm
  outRepls := matchcontinue (inMarkedEqns)
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
      DAE.FunctionTree funcs;

    case {}
    then inRepls;

    case markedEqn::markedEqns equation
      indexVar = inVecEqToVar[markedEqn];
      true = isVarExplicitSolvable(inME[markedEqn], indexVar);
      var = BackendVariable.getVarAt(inVars, indexVar);

      indexEq = inMapIncRowEqn[markedEqn];
      eqn = BackendEquation.equationNth1(inEqns, indexEq);

      cref = BackendVariable.varCref(var);
      type_ = BackendVariable.varType(var);
      x = DAE.CREF(cref, type_);
      BackendDAE.SHARED(functionTree = funcs) = inShared;
      (eqn as BackendDAE.EQUATION(scalar=exp)) = BackendEquation.solveEquation(eqn, x, SOME(funcs));

      varName = BackendVariable.varCref(var);
      (exp1, _) = Expression.traverseExpBottomUp(exp, BackendDAEUtil.replaceCrefsWithValues, (inVars, varName));
      repls = BackendVarTransform.addReplacement(inRepls, varName, exp1, NONE());
      repls = setupVarReplacements(markedEqns, inEqns, inVars, inVecEqToVar, repls, inMapIncRowEqn, inME, inShared);
    then repls;

    case _::markedEqns equation
      repls = setupVarReplacements(markedEqns, inEqns, inVars, inVecEqToVar, inRepls, inMapIncRowEqn, inME, inShared);
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
  outEqnList := BackendEquation.copyEquationArray(inEqnList) "avoid side-effects";
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
  (outUnassignedEqns, outConsistent, outRemovedEqns) := matchcontinue(inUnassignedEqn)
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

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.equationNth1(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      true = Expression.isZero(exp);
      //((_, listParameter))=parameterCheck((exp, {}));
      //true = listEmpty(listParameter);
      eqn = BackendEquation.equationNth1(inEqnsOrig, inUnassignedEqn);
      Error.addCompilerNotification("The following equation is consistent and got removed from the initialization problem: " + BackendDump.equationString(eqn));
    then ({inUnassignedEqn}, true, {});

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intGt(counter, nEqns-nVars);

      Error.addCompilerError("Initialization problem is structural singular. Please, check the initial conditions.");
    then ({}, true, {});

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);

      eqn = BackendEquation.equationNth1(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_, listParameter))=parameterCheck((exp, {}));
      true = listEmpty(listParameter);

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, inUnassignedEqn);
      Error.addCompilerError("The initialization problem is inconsistent due to the following equation: " + BackendDump.equationString(eqn2) + " (" + BackendDump.equationString(eqn) + ")");
    then ({}, false, {});

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.equationNth1(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_, listParameter))=parameterCheck((exp, {}));
      false = listEmpty(listParameter);

      list_inEqns=BackendEquation.equationList(inEqns);
      list_inEqns = List.set(list_inEqns, inUnassignedEqn, eqn);
      eqns = BackendEquation.listEquation(list_inEqns);
      funcs = BackendDAEUtil.getFunctions(shared);
      system = BackendDAEUtil.createEqSystem(vars, eqns);
      (m, _) = BackendDAEUtil.incidenceMatrix(system, BackendDAE.NORMAL(), SOME(funcs));
      listVar=m[inUnassignedEqn];
      false = listEmpty(listVar);

      _ = BackendEquation.equationNth1(inEqnsOrig, inUnassignedEqn);
      Error.addCompilerNotification("It was not possible to analyze the given system symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    then ({}, false, {});

    case _ equation
      //true = listEmpty(inM[inUnassignedEqn]);
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.equationNth1(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      ((_, listParameter))=parameterCheck((exp, {}));
      false = listEmpty(listParameter);

      eqn2 = BackendEquation.equationNth1(inEqnsOrig, inUnassignedEqn);
      Error.addCompilerWarning("It was not possible to determine if the initialization problem is consistent, because of not evaluable parameters during compile time: " + BackendDump.equationString(eqn2) + " (" + BackendDump.equationString(eqn) + ")");
    then ({}, true, {inUnassignedEqn});
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
  (e, listParameter) := Expression.traverseExpBottomUp(e, parameterCheck2, listParameter); // TODO: Was {}; why?
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

    case (DAE.CREF(componentRef=DAE.CREF_QUAL(ident=Para)), listParameter)
      equation
        listParameter=listAppend({Para}, listParameter);
      then (exp, listParameter);

    case (DAE.CREF(componentRef=DAE.CREF_IDENT(ident=Para)), listParameter)
      equation
        listParameter=listAppend({Para}, listParameter);
      then (exp, listParameter);

    case (DAE.CREF(componentRef=DAE.CREF_ITER(ident=Para)), listParameter)
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
  (outVar,outTpl) := matchcontinue(inVar, inTpl)
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
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(startValue));

      // pre(v) = v.start
      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startValue, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed and isFixed then BackendEquation.addEquation(eqn, eqns) else eqns;
    then (var, (vars, fixvars, eqns, hs));

    // continuous-time
    case (var as BackendDAE.VAR(varName=cr, varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs)) equation
      preUsed = BaseHashSet.has(cr, hs);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      // pre(v) = v
      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), DAE.CREF(cr, ty), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed then BackendEquation.addEquation(eqn, eqns) else eqns;
    then (var, (vars, fixvars, eqns, hs));

    else (inVar, inTpl);
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
  ((eqns, reqns)) := BackendEquation.traverseEquationArray(orderedEqs, collectInitialEqns, (eqns, reqns));
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
      DAE.Exp startExp, bindExp, crefExp, e;
      BackendDAE.VarKind varKind;
      HashSet.HashSet hs;
      String s, str, sv;
      SourceInfo info;

    // state
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(), varType=ty), (vars, fixvars, eqns, hs)) equation
      isFixed = BackendVariable.varFixed(var);
      _ = BackendVariable.varStartValueOption(var);
      preUsed = BaseHashSet.has(cr, hs);

      crefExp = Expression.crefExp(cr);
      //startExp = Expression.makePureBuiltinCall("$_start", {crefExp}, ty);
      startExp = BackendVariable.varStartValue(var);
      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      if isFixed then
        eqns = BackendEquation.addEquation(eqn, eqns);
      end if;

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
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed then BackendEquation.addEquation(eqn, eqns) else eqns;
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
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
    then (var, (vars, fixvars, eqns, hs));

    // parameter without binding and fixed=true
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=NONE()), (vars, fixvars, eqns, hs)) equation
      true = BackendVariable.varFixed(var);
      startExp = BackendVariable.varStartValueType(var);

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(startExp);

      // e = Expression.crefExp(cr);
      // ty = Expression.typeof(e);
      // startExp = Expression.makePureBuiltinCall("$_start", {e}, ty);

      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, SOME(startExp));
      var = BackendVariable.setVarFixed(var, true);

      info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s, str}, info);

      //vars = BackendVariable.addVar(var, vars);
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
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars, eqns, hs)) equation
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
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars, eqns, hs)) equation
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
    // skip these parameters (#3050)
    case (var as BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars, eqns, hs)) equation
      true = Expression.isConst(bindExp);
      //fixvars = BackendVariable.addVar(var, fixvars);
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

      vars = if not isInput then BackendVariable.addVar(var, vars) else vars;
      fixvars = if isInput then BackendVariable.addVar(var, fixvars) else fixvars;
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = BackendEquation.addEquation(eqn, eqns);

      // Error.addCompilerNotification("VARIABLE (fixed=true): " + BackendDump.varString(var));
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

      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), DAE.CREF(cr, ty), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = if not isInput then BackendVariable.addVar(var, vars) else vars;
      fixvars = if isInput then BackendVariable.addVar(var, fixvars) else fixvars;
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed then BackendEquation.addEquation(eqn, eqns) else eqns;

      // Error.addCompilerNotification("VARIABLE (fixed=false); " + BackendDump.varString(var));
    then (var, (vars, fixvars, eqns, hs));

    else equation
      Error.addInternalError("function collectInitialVars failed for: " + BackendDump.varString(inVar), sourceInfo());
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
  (eqn1, _) := BackendEquation.traverseExpsOfEquation(eqn, Expression.traverseSubexpressionsDummyHelper, replaceDerPreCref);

  // add it, if size is zero (terminate, assert, noretcall) move to removed equations
  size := BackendEquation.equationSize(eqn1);
  b := intGt(size, 0);

  eqns := if b then BackendEquation.addEquation(eqn1, eqns) else eqns;
  reeqns := if not b then BackendEquation.addEquation(eqn1, reeqns) else reeqns;
  outTpl := (eqns, reeqns);
end collectInitialEqns;

protected function replaceDerPreCref
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
        Error.addInternalError("function collectInitialBindings failed for: " + BackendDump.varString(inVar), sourceInfo());
      then fail();

  end match;
end collectInitialBindings;

annotation(__OpenModelica_Interface="backend");
end Initialization;
