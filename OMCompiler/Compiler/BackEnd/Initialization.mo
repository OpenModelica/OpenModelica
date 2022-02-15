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
"

public
import Absyn;
import BackendDAE;
import BackendDAEFunc;
import DAE;
import HashSet;
import Util;

protected
import Array;
import BackendDAEEXT;
import BackendDAEOptimize;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVarTransform;
import BackendVariable;
import BaseHashSet;
import CheckModel;
import ComponentReference;
import DoubleEnded;
import ElementSource;
import Error;
import ExecStat.execStat;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import Flags;
import GCExt;
import IndexReduction;
import List;
import Matching;
import MetaModelica.Dangerous.listReverseInPlace;
import Sorting;
import SymbolicJacobian;
import SynchronousFeatures;

// =============================================================================
// section for all public functions
//
// These are functions that can be used to access the initialization.
// =============================================================================

public function solveInitialSystem "author: lochel
  This function generates a algebraic system of equations for the initialization and solves it."
  input BackendDAE.BackendDAE inDAE "simulation system";
  output BackendDAE.BackendDAE outInitDAE "initialization system";
  output Option<BackendDAE.BackendDAE> outInitDAE_lambda0 "initialization system for lambda=0";
  output list<BackendDAE.Equation> outRemovedInitialEquations;
  output BackendDAE.Variables outGlobalKnownVars;
  output BackendDAE.BackendDAE outSimDAE = inDAE "updated with fixed attribute";
protected
  BackendDAE.BackendDAE dae;
  BackendDAE.BackendDAE initdae;
  BackendDAE.BackendDAE initdae0;
  BackendDAE.EqSystem initsyst;
  BackendDAE.EqSystems systs;
  BackendDAE.EquationArray eqns, reeqns;
  BackendDAE.Shared shared;
  BackendDAE.Variables initVars;
  BackendDAE.Variables vars, fixvars;
  Boolean b, b1, b2, useHomotopy, datarecon=false;
  String msg;
  list<String> enabledModules, disabledModules;
  HashSet.HashSet hs "contains all pre variables";
  list<BackendDAE.Equation> removedEqns;
  list<BackendDAE.Var> dumpVars, dumpVars2, outAllPrimaryParameters;
  AvlSetCR.Tree allPrimaryParameters;
  list<tuple<BackendDAEFunc.optimizationModule, String>> initOptModules, initOptModulesLambda0;
  tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEFunc.matchingAlgorithmFunc, String> matchingAlgorithm;
algorithm
  try
    //if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
    //  BackendDump.dumpBackendDAE(inDAE, "inDAE for initialization");
    //end if;

    // inline all when equations, if active with body else with lhs=pre(lhs)
    dae := inlineWhenForInitialization(inDAE);
    //if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
    //  BackendDump.dumpBackendDAE(dae, "inlineWhenForInitialization");
    //end if;
    execStat("inlineWhenForInitialization (initialization)");

    (dae, initVars, outAllPrimaryParameters, outGlobalKnownVars) := selectInitializationVariablesDAE(dae);

    if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
      BackendDump.dumpVarList(outAllPrimaryParameters, "selected all primary parameters");
    end if;
    execStat("selectInitializationVariablesDAE (initialization)");

    hs := collectPreVariables(dae);
    execStat("collectPreVariables (initialization)");

    // collect vars and eqns for initial system
    vars := BackendVariable.emptyVars();

    fixvars := BackendVariable.listVar(outAllPrimaryParameters);

    eqns := BackendEquation.emptyEqnsSized(BackendVariable.varsSize(dae.shared.aliasVars)
                                         + BackendVariable.varsSize(dae.shared.globalKnownVars)
                                         + BackendVariable.varsSize(dae.shared.localKnownVars)
                                         + BackendEquation.getNumberOfEquations(dae.shared.initialEqs)
                                         + 2*BackendDAEUtil.daeSize(dae));
    reeqns := BackendEquation.emptyEqnsSized(BackendEquation.getNumberOfEquations(dae.shared.removedEqs));

    allPrimaryParameters := AvlSetCR.EMPTY();
    for v in outAllPrimaryParameters loop
      allPrimaryParameters := AvlSetCR.add(allPrimaryParameters, BackendVariable.varCref(v));
    end for;
    // check for datareconciliation and set the Flag, to set the Qualified Component names as TopLevel Input
    if Util.isSome(inDAE.shared.dataReconciliationData) then
       datarecon := true;
    end if;
    ((vars, fixvars, eqns, _)) := BackendVariable.traverseBackendDAEVars(dae.shared.aliasVars, introducePreVarsForAliasVariables, (vars, fixvars, eqns, hs));
    ((vars, fixvars, eqns, _, _, _, _)) := BackendVariable.traverseBackendDAEVars(dae.shared.globalKnownVars, collectInitialVars, (vars, fixvars, eqns, arrayCreate(0,0), hs, allPrimaryParameters,datarecon));
    ((vars, fixvars, eqns, _, _, _, _)) := BackendVariable.traverseBackendDAEVars(dae.shared.localKnownVars, collectInitialVars, (vars, fixvars, eqns, arrayCreate(0,0), hs, allPrimaryParameters,datarecon));
    ((eqns, reeqns)) := BackendEquation.traverseEquationArray(dae.shared.initialEqs, collectInitialEqns, (eqns, reeqns));
    ((eqns, reeqns)) := BackendEquation.traverseEquationArray(dae.shared.removedEqs, collectInitialEqns, (eqns, reeqns));
    //if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
    //  BackendDump.dumpEquationArray(eqns, "initial equations");
    //end if;
    execStat("collectInitialEqns (initialization)");

    //((vars, fixvars, eqns, reeqns, _, _)) := List.fold(dae.eqs, collectInitialVarsEqnsSystem, ((vars, fixvars, eqns, reeqns, hs, allPrimaryParameters)));
    (vars, fixvars, eqns, reeqns) := collectInitialVarsEqnsSystem(dae.eqs, vars, fixvars, eqns, reeqns, hs, allPrimaryParameters, datarecon);
    ((eqns, reeqns)) := BackendVariable.traverseBackendDAEVars(vars, collectInitialBindings, (eqns, reeqns));
    execStat("collectInitialBindings (initialization)");

    // replace initial(), sample(...), delay(...) and homotopy(...)
    useHomotopy := BackendDAEUtil.traverseBackendDAEExpsEqns(eqns, simplifyInitialFunctions, false);
    execStat("simplifyInitialFunctions (initialization)");

    vars := BackendVariable.rehashVariables(vars);
    fixvars := BackendVariable.rehashVariables(fixvars);
    shared := BackendDAEUtil.createEmptyShared(BackendDAE.INITIALSYSTEM(), dae.shared.info, dae.shared.cache, dae.shared.graph);
    shared := BackendDAEUtil.setSharedRemovedEqns(shared, BackendEquation.emptyEqns());
    shared := BackendDAEUtil.setSharedGlobalKnownVars(shared, fixvars);
    shared := BackendDAEUtil.setSharedOptimica(shared, dae.shared.constraints, dae.shared.classAttrs);
    shared := BackendDAEUtil.setSharedFunctionTree(shared, dae.shared.functionTree);
    execStat("setup shared object (initialization)");

    // generate initial system and pre-balance it
    initsyst := BackendDAEUtil.createEqSystem(vars, eqns);
    initsyst := BackendDAEUtil.setEqSystRemovedEqns(initsyst, reeqns);
    (initsyst, dumpVars) := preBalanceInitialSystem(initsyst);
    execStat("preBalanceInitialSystem (initialization)");

    // split the initial system into independend subsystems
    initdae := BackendDAE.DAE({initsyst}, shared);
    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      BackendDump.dumpBackendDAE(initdae, "created initial system");
    end if;

    if Flags.isSet(Flags.PARTITION_INITIALIZATION) then
      (systs, shared) := BackendDAEOptimize.partitionIndependentBlocksHelper(initsyst, shared, Error.getNumErrorMessages(), true);
      initdae := BackendDAE.DAE(systs, shared);
      execStat("partitionIndependentBlocks (initialization)");
    end if;

    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      BackendDump.dumpBackendDAE(initdae, "partitioned initial system");
    end if;
    // initdae := BackendDAE.DAE({initsyst}, shared);

    // fix over- and under-constrained subsystems
    (initdae, dumpVars2, removedEqns) := analyzeInitialSystem(initdae, initVars);
    dumpVars := listAppend(dumpVars, dumpVars2) annotation(__OpenModelica_DisableListAppendWarning=true);
    execStat("analyzeInitialSystem (initialization)");

    // some debug prints
    if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
      BackendDump.dumpBackendDAE(initdae, "initial system");
    end if;

    // now let's solve the system!
    initdae := BackendDAEUtil.mapEqSystem(initdae, solveInitialSystemEqSystem);
    execStat("solveInitialSystemEqSystem (initialization)");

    // solve system
    initdae := BackendDAEUtil.transformBackendDAE(initdae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
    execStat("matching and sorting (n="+String(BackendDAEUtil.daeSize(initdae))+") (initialization)");

    // add initial assignmnents to all algorithms
    initdae := BackendDAEOptimize.addInitialStmtsToAlgorithms(initdae, true);

    if useHomotopy and Config.globalHomotopy() then
      initdae0 := BackendDAEUtil.copyBackendDAE(initdae);
    end if;

    // simplify system
    initdae := BackendDAEUtil.setDAEGlobalKnownVars(initdae, outGlobalKnownVars);

    if useHomotopy then
      enabledModules := if Config.adaptiveHomotopy() then {"inlineHomotopy", "generateHomotopyComponents"} else {};
      disabledModules := {};
    else
      enabledModules := {};
      disabledModules := {"inlineHomotopy", "generateHomotopyComponents"};
    end if;

    initOptModules := BackendDAEUtil.getInitOptModules(NONE(), enabledModules, disabledModules);
    matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(NONE());
    daeHandler := BackendDAEUtil.getIndexReductionMethod(SOME("none"));
    initdae := BackendDAEUtil.postOptimizeDAE(initdae, initOptModules, matchingAlgorithm, daeHandler);

    if Flags.isSet(Flags.DUMP_INITIAL_SYSTEM) then
      BackendDump.dumpBackendDAE(initdae, "solved initial system");
      if Flags.isSet(Flags.ADDITIONAL_GRAPHVIZ_DUMP) then
        BackendDump.graphvizBackendDAE(initdae, "dumpinitialsystem");
      end if;
    end if;

    // compute system for lambda=0
    if useHomotopy and Config.globalHomotopy() then
      initOptModulesLambda0 := BackendDAEUtil.getInitOptModules(NONE(),{"replaceHomotopyWithSimplified"},{"inlineHomotopy", "generateHomotopyComponents"});
      initdae0 := BackendDAEUtil.setFunctionTree(initdae0, BackendDAEUtil.getFunctions(initdae.shared));
      initdae0 := BackendDAEUtil.postOptimizeDAE(initdae0, initOptModulesLambda0, matchingAlgorithm, daeHandler);
      initdae0.shared := BackendDAEUtil.setSharedGlobalKnownVars(initdae0.shared, BackendVariable.emptyVars());
      outInitDAE_lambda0 := SOME(initdae0);
      initdae := BackendDAEUtil.setFunctionTree(initdae, BackendDAEUtil.getFunctions(initdae0.shared));
    else
      outInitDAE_lambda0 := NONE();
    end if;

    // Remove the globalKnownVars for the initialization set again
    initdae.shared := BackendDAEUtil.setSharedGlobalKnownVars(initdae.shared, BackendVariable.emptyVars());

    // update the fixed attribute in the simulation DAE
    outSimDAE := BackendVariable.traverseBackendDAE(outSimDAE, updateFixedAttribute, BackendVariable.listVar(dumpVars));

    // warn about selected default initial conditions
    b1 := not listEmpty(dumpVars);
    b2 := not listEmpty(removedEqns);
    msg := System.gettext("For more information set -d=initialization. In OMEdit Tools->Options->Simulation->Show additional information from the initialization process, in OMNotebook call setCommandLineOptions(\"-d=initialization\")");
    if Flags.isSet(Flags.INITIALIZATION) then
      if b1 then
        Error.addCompilerWarning("Assuming fixed start value for the following " + intString(listLength(dumpVars)) + " variables:\n" + warnAboutVars2(dumpVars));
      end if;
      if b2 then
        Error.addMessage(Error.INITIALIZATION_OVER_SPECIFIED, {"The following " + intString(listLength(removedEqns)) + " initial equations are redundant, so they are removed from the initialization sytem:\n" + warnAboutEqns2(removedEqns)});
      end if;
    else
      if b1 then
        Error.addMessage(Error.INITIALIZATION_NOT_FULLY_SPECIFIED, {msg});
      end if;
      if b2 then
        Error.addMessage(Error.INITIALIZATION_OVER_SPECIFIED, {msg});
      end if;
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

    outInitDAE := initdae;
    outRemovedInitialEquations := removedEqns;
  else
    Error.addCompilerError("No system for the symbolic initialization was generated");
    fail();
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
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  list<BackendDAE.Equation> eqnlst;
  list<BackendDAE.Equation> clockEqnsLst;
  HashSet.HashSet leftCrs = HashSet.emptyHashSet() "dummy hash set - should always be empty";
algorithm
  outDAE.eqs := List.map(inDAE.eqs, inlineWhenForInitializationSystem);
  (eqnlst, _) := BackendEquation.traverseEquationArray(inDAE.shared.removedEqs, inlineWhenForInitializationEquation, ({}, leftCrs));
  // TODO AHEU: Add simCodeTarget C around this?
  clockEqnsLst := BackendEquation.traverseEquationArray(inDAE.shared.removedEqs, SynchronousFeatures.getBoolClockWhenClauses, {});
  eqnlst := listAppend(clockEqnsLst, eqnlst);
  outDAE.shared := BackendDAEUtil.setSharedRemovedEqns(outDAE.shared, BackendEquation.listEquation(eqnlst));
end inlineWhenForInitialization;

protected function inlineWhenForInitializationSystem "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem;
protected
  list<BackendDAE.Equation> eqnlst;
  HashSet.HashSet leftCrs = HashSet.emptyHashSet() "hack for #3209";
  list<DAE.ComponentRef> crefLst;
algorithm
  (eqnlst, leftCrs) := BackendEquation.traverseEquationArray(inEqSystem.orderedEqs, inlineWhenForInitializationEquation, ({}, leftCrs));
  crefLst := BaseHashSet.hashSetList(leftCrs);
  eqnlst := generateInactiveWhenEquationForInitialization(crefLst, DAE.emptyElementSource, eqnlst);
  outEqSystem := BackendDAEUtil.setEqSystEqs(inEqSystem, BackendEquation.listEquation(eqnlst));
  outEqSystem := BackendDAEUtil.clearEqSyst(outEqSystem);
end inlineWhenForInitializationSystem;

protected function inlineWhenForInitializationEquation "author: lochel"
  input BackendDAE.Equation inEq;
  input tuple<list<BackendDAE.Equation>, HashSet.HashSet> inTpl;
  output BackendDAE.Equation outEq = inEq;
  output tuple<list<BackendDAE.Equation>, HashSet.HashSet> outTpl;
protected
  BackendDAE.EquationAttributes eqAttr;
  BackendDAE.WhenEquation weqn;
  DAE.Algorithm alg;
  DAE.ElementSource source;
  DAE.Expand crefExpand;
  HashSet.HashSet leftCrs;
  Integer size;
  list<BackendDAE.Equation> eqns;
  list<BackendDAE.Equation> accEq;
  list<DAE.Statement> stmts;
algorithm
  (accEq, leftCrs) := inTpl;
  outTpl := match (inEq)
    // when equation
    case BackendDAE.WHEN_EQUATION(whenEquation=weqn, source=source, attr=eqAttr) equation
      (leftCrs, eqns) = inlineWhenForInitializationWhenEquation(weqn, source, eqAttr, accEq, leftCrs);
    then (eqns, leftCrs);

    // algorithm
    case BackendDAE.ALGORITHM(alg=alg, source=source, expand=crefExpand) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg;
      (stmts, leftCrs) = inlineWhenForInitializationWhenAlgorithm(stmts, {}, leftCrs);
      alg = DAE.ALGORITHM_STMTS(stmts);
      size = listLength(CheckModel.checkAndGetAlgorithmOutputs(alg, source, crefExpand));
      eqns = List.consOnTrue(not listEmpty(stmts), BackendDAE.ALGORITHM(size, alg, source, crefExpand, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC), accEq);
    then (eqns, leftCrs);

    else (inEq::accEq, leftCrs);
  end match;
end inlineWhenForInitializationEquation;

protected function inlineWhenForInitializationWhenEquation "author: lochel"
  input BackendDAE.WhenEquation inWEqn;
  input DAE.ElementSource inSource;
  input BackendDAE.EquationAttributes inEqAttr;
  input list<BackendDAE.Equation> inEqns;
  input HashSet.HashSet inLeftCrs;
  output HashSet.HashSet outLeftCrs = inLeftCrs;
  output list<BackendDAE.Equation> outEqns = inEqns;
protected
  DAE.Exp lhs, condition, e;
  list<DAE.Exp> eLst;
  BackendDAE.Equation eqn;
  list<BackendDAE.WhenOperator> whenStmtLst;
  DAE.ComponentRef cr;
  list<DAE.ComponentRef > crefLst;
  Boolean active;
  DAE.ElementSource source;
algorithm
  outEqns := match(inWEqn)
    case BackendDAE.WHEN_STMTS(condition=condition,whenStmtLst=whenStmtLst) algorithm
      active := Expression.containsInitialCall(condition);
      for stmt in whenStmtLst loop
        _ := match stmt
          case BackendDAE.ASSIGN(left = DAE.CREF(componentRef = cr), right = e) equation
            if active then
              lhs = Expression.crefExp(cr);
              eqn = BackendEquation.generateEquation(lhs, e, inSource, inEqAttr);
              outEqns = eqn::outEqns;
            else
              outLeftCrs = List.fold(ComponentReference.expandCref(cr, true), BaseHashSet.add, outLeftCrs);
            end if;
          then ();

          case BackendDAE.ASSIGN(left = lhs as DAE.TUPLE(PR = eLst), right = e) algorithm
            if active then
              eqn := BackendEquation.generateEquation(lhs, e, inSource, inEqAttr);
              outEqns := eqn::outEqns;
            else
              crefLst := List.flatten(List.map(eLst,Expression.getAllCrefs));
              for cr in crefLst loop
                outLeftCrs := List.fold(ComponentReference.expandCref(cr, true), BaseHashSet.add, outLeftCrs);
              end for;
            end if;
          then ();

          case BackendDAE.NORETCALL(exp=e, source=source) algorithm
            if active then
              //eqn := BackendEquation.generateEquation(DAE.CREF(DAE.emptyCref, DAE.T_UNKNOWN_DEFAULT), e, inSource, inEqAttr);
              eqn := BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_NORETCALL(e, source)}), inSource, DAE.EXPAND(), BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
              outEqns := eqn::outEqns;
            end if;
          then ();

          // Everything else doesn't have to be handled
          else ();
        end match;
      end for;
    then outEqns;
    else outEqns;
  end match;
end inlineWhenForInitializationWhenEquation;

protected function inlineWhenForInitializationWhenAlgorithm "author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem."
  input list< DAE.Statement> inStmts;
  input list< DAE.Statement> inAcc "={}";
  input HashSet.HashSet inLeftCrs;
  output list< DAE.Statement> outStmts;
  output HashSet.HashSet outLeftCrs;
algorithm
  (outStmts, outLeftCrs) := match(inStmts)
    local
      DAE.Statement stmt;
      list<DAE.Statement> stmts, rest;
      HashSet.HashSet leftCrs;

    case {}
    then (listReverse(inAcc), inLeftCrs);

    // when statement
    case (stmt as DAE.STMT_WHEN())::rest equation
      // for when statements it is not necessary that all branches have the same left hand side variables
      // -> take care that for each left hand side an assigment is generated
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, inLeftCrs, inAcc);
      (stmts, leftCrs) = inlineWhenForInitializationWhenAlgorithm(rest, stmts, leftCrs);
    then (stmts, leftCrs);

    // no when statement
    case stmt::rest equation
      (stmts, leftCrs) = inlineWhenForInitializationWhenAlgorithm(rest, stmt::inAcc, inLeftCrs);
    then (stmts, leftCrs);
  end match;
end inlineWhenForInitializationWhenAlgorithm;

protected function inlineWhenForInitializationWhenStmt "author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem."
  input DAE.Statement inWhenStatement;
  input HashSet.HashSet inLeftCrs;
  input list< DAE.Statement> inAcc;
  output list< DAE.Statement> outStmts;
  output HashSet.HashSet outLeftCrs;
algorithm
  (outStmts, outLeftCrs) := match(inWhenStatement)
    local
      DAE.Exp condition;
      list<DAE.ComponentRef> crefLst;
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      HashSet.HashSet leftCrs;

    // active when equation during initialization
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts) guard
      Expression.containsInitialCall(condition)
    equation
      stmts = List.foldr(stmts, List.consr, inAcc);
    then (stmts, inLeftCrs);

    // inactive when equation during initialization
    case DAE.STMT_WHEN(exp=_, statementLst=stmts, elseWhen=NONE()) equation
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      leftCrs = List.fold(crefLst, BaseHashSet.add, inLeftCrs);
    then (inAcc, leftCrs);

    // inactive when equation during initialization with elsewhen part
    case DAE.STMT_WHEN(exp=_, statementLst=stmts, elseWhen=SOME(stmt)) equation
      crefLst = CheckModel.algorithmStatementListOutputs(stmts, DAE.EXPAND()); // expand as we're in an algorithm
      leftCrs = List.fold(crefLst, BaseHashSet.add, inLeftCrs);
      (stmts, leftCrs) = inlineWhenForInitializationWhenStmt(stmt, leftCrs, inAcc);
    then (stmts, leftCrs);

    else equation
      Error.addInternalError("function inlineWhenForInitializationWhenStmt failed", sourceInfo());
    then fail();
  end match;
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
  //list<DAE.ComponentRef> crefs;
algorithm
  //BackendDump.dumpBackendDAE(inDAE, "inDAE");
  outHS := List.fold(inDAE.eqs, collectPreVariablesEqSystem, HashSet.emptyHashSet());
  ((_, outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns( inDAE.shared.initialEqs, Expression.traverseSubexpressionsHelper,
                                                             (collectPreVariablesTraverseExp, outHS) );
  ((_, outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns( inDAE.shared.removedEqs, Expression.traverseSubexpressionsHelper,
                                                             (collectPreVariablesTraverseExp, outHS) );
  //print("collectPreVariables:\n");
  //crefs := BaseHashSet.hashSetList(outHS);
  //BackendDump.debuglst(crefs, ComponentReference.printComponentRefStr, "\n", "\n");
end collectPreVariables;

public function collectPreVariablesEqSystem
  input BackendDAE.EqSystem inSyst;
  input HashSet.HashSet inHS;
  output HashSet.HashSet outHS;
algorithm
  ((_, outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns( inSyst.orderedEqs, Expression.traverseSubexpressionsHelper,
                                                             (collectPreVariablesTraverseExp, inHS) );
  ((_, outHS)) := BackendDAEUtil.traverseBackendDAEExpsEqns( inSyst.removedEqs, Expression.traverseSubexpressionsHelper,
                                                             (collectPreVariablesTraverseExp, outHS) );
end collectPreVariablesEqSystem;

public function collectPreVariablesTraverseExp
  input DAE.Exp inExp;
  input HashSet.HashSet inHS;
  output DAE.Exp outExp = inExp;
  output HashSet.HashSet outHS;
algorithm
  outHS := match (inExp)
    case DAE.CALL(path=Absyn.IDENT(name="pre")) equation
      (_, outHS) = Expression.traverseExpBottomUp(inExp, collectPreVariablesTraverseExp2, inHS);
    then outHS;

    case DAE.CALL(path=Absyn.IDENT(name="change")) equation
      (_, outHS) = Expression.traverseExpBottomUp(inExp, collectPreVariablesTraverseExp2, inHS);
    then outHS;

    case DAE.CALL(path=Absyn.IDENT(name="edge")) equation
      (_, outHS) = Expression.traverseExpBottomUp(inExp, collectPreVariablesTraverseExp2, inHS);
    then outHS;

    else inHS;
  end match;
end collectPreVariablesTraverseExp;

protected function collectPreVariablesTraverseExp2 "author: lochel"
  input DAE.Exp inExp;
  input HashSet.HashSet inHS;
  output DAE.Exp outExp = inExp;
  output HashSet.HashSet outHS;
algorithm
  outHS := match inExp
    local
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef cr;

    case DAE.CREF(componentRef=cr) equation
      crefs = ComponentReference.expandCref(cr, true);
      outHS = List.fold(crefs, BaseHashSet.add, inHS);
    then outHS;

    else inHS;
  end match;
end collectPreVariablesTraverseExp2;

protected function warnAboutVars2 "author: lochel
  TODO: Replace this with an general BackendDump implementation."
  input list<BackendDAE.Var> vars;
  output String outString;
protected
  list<String> strs;
  Integer len;
  Integer size;
algorithm
  if listEmpty(vars) then
    outString := "";
    return;
  end if;
  strs := list(BackendDump.varString(v) for v in vars);
  len := listLength(strs);
  size := sum(stringLength(s) for s in strs) + len*10;
  outString := warnAboutVars2Work(strs, "         ", "\n", size);
end warnAboutVars2;

function warnAboutVars2Work
  input list<String> strs;
  input String prefix;
  input String suffix;
  input Integer size;
  output String s="";
protected
  // Allocate a string of the exact required length
  System.StringAllocator sb=System.StringAllocator(size);
  Integer i=0;
algorithm
  for str in strs loop
    System.stringAllocatorStringCopy(sb, prefix, i);
    i := i+stringLength(prefix);
    System.stringAllocatorStringCopy(sb, str, i);
    i := i+stringLength(str);
    System.stringAllocatorStringCopy(sb, suffix, i);
    i := i+stringLength(suffix);
  end for;
  // Return the string
  s := System.stringAllocatorResult(sb,s);
end warnAboutVars2Work;

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
  This function wraps selectInitializationVariables.
  All primary parameters get removed from the dae."
  input output BackendDAE.BackendDAE dae;
  output BackendDAE.Variables outInitVars;
  output list<BackendDAE.Var> outAllPrimaryParameters = {};
  output BackendDAE.Variables outGlobalKnownVars = dae.shared.globalKnownVars;
protected
  BackendDAE.Variables otherVariables, globalKnownVars;
  BackendDAE.EquationArray globalKnownVarsEqns;
  BackendDAE.EqSystem globalKnownVarsSystem;
  BackendDAE.AdjacencyMatrix m, mT;
  array<Integer> ass1 "eqn := ass1[var]";
  array<Integer> ass2 "var := ass2[eqn]";
  list<list<Integer>> comps;
  list<Integer> flatComps;
  Integer nGlobalKnownVars;
  array<Integer> secondary;
  BackendDAE.Var v;
  DAE.Exp bindExp;
  HashSet.HashSet hs;
  list<DAE.ComponentRef> crefs;
  list<BackendDAE.Var> globalKnownVarList = {};
algorithm

  /* #6262, fix start values for input, when start exp has non constant bindings associated with a parameter (e.g)
     input Real x(start = x_start);
     parameter Real x_start = 6.0;
  */
  for var in BackendVariable.varList(dae.shared.globalKnownVars) loop
    if BackendVariable.isInput(var) and not Expression.isConstValue(BackendVariable.varStartValue(var)) and not Types.isArray(BackendVariable.varType(var)) then
      bindExp := BackendVariable.varStartValue(var);
      (v, _) := BackendVariable.getVarSingle(Expression.expCref(bindExp), dae.shared.globalKnownVars);
      var := BackendVariable.setVarStartValueOption(var, v.bindExp);
    end if;
    globalKnownVarList := var :: globalKnownVarList;
  end for;
  dae := BackendDAEUtil.setDAEGlobalKnownVars(dae, BackendVariable.listVar(globalKnownVarList));

  // lochel: workaround to align all elements
  globalKnownVars := BackendVariable.listVar(BackendVariable.varList(dae.shared.globalKnownVars));

  outInitVars := selectInitializationVariables(dae.eqs);
  outInitVars := BackendVariable.traverseBackendDAEVars(dae.shared.globalKnownVars, selectInitializationVariables2, outInitVars);
  outInitVars := BackendVariable.traverseBackendDAEVars(dae.shared.aliasVars, selectInitializationVariables2, outInitVars);

  globalKnownVars := BackendVariable.traverseBackendDAEVars(dae.shared.externalObjects, addExtObjToGlobalKnownVars, globalKnownVars);
  nGlobalKnownVars := BackendVariable.varsSize(globalKnownVars);
  otherVariables := BackendVariable.emptyVarsSized(nGlobalKnownVars);
  globalKnownVarsEqns := BackendEquation.emptyEqnsSized(nGlobalKnownVars);
  globalKnownVarsEqns := BackendVariable.traverseBackendDAEVars(globalKnownVars, createGlobalKnownVarsEquations, globalKnownVarsEqns);

  if nGlobalKnownVars > 0 then
    globalKnownVarsSystem := BackendDAEUtil.createEqSystem(globalKnownVars, globalKnownVarsEqns);
    (m, mT) := BackendDAEUtil.adjacencyMatrix(globalKnownVarsSystem, BackendDAE.NORMAL(), NONE(), BackendDAEUtil.isInitializationDAE(dae.shared));
    //BackendDump.dumpAdjacencyMatrix(m);
    //BackendDump.dumpAdjacencyMatrixT(mT);

    // match the system
    // ass1 and ass2 should be {1, 2, ..., nGlobalKnownVars}
    (ass1, ass2) := Matching.PerfectMatching(m);
    //BackendDump.dumpMatchingVars(ass1);
    //BackendDump.dumpMatchingEqns(ass2);

    comps := Sorting.Tarjan(m, ass1);
    //BackendDump.dumpComponentsOLD(comps);
    comps := mapListIndices(comps, ass2) "map to var indices (not really needed, since ass2 should be {1, 2, ..., nParam})" ;
    //BackendDump.dumpComponentsOLD(comps);

    // flattern list and look for cyclic dependencies
    flatComps := list(flattenParamComp(comp, globalKnownVars) for comp in comps);
    //BackendDump.dumpAdjacencyRow(flatComps);
    //BackendDump.dumpVariables(globalKnownVars, "globalKnownVars");

    // select secondary parameters
    secondary := arrayCreate(nGlobalKnownVars, 0);
    secondary := selectSecondaryParameters(flatComps, globalKnownVars, mT, secondary);

    // get primary and secondary parameters and variables
    hs := HashSet.emptyHashSetSized(2*nGlobalKnownVars+1);
    for i in flatComps loop
      v := BackendVariable.getVarAt(globalKnownVars, i);
      bindExp := BackendVariable.varBindExpStartValueNoFail(v);
      crefs := Expression.getAllCrefsExpanded(bindExp);
      //BackendDump.dumpVarList({v}, intString(i));

      _ := match(v)
        // primary parameter
        case (BackendDAE.VAR(varKind=BackendDAE.PARAM())) guard 0 == secondary[i] and BaseHashSet.hasAll(crefs, hs)
          equation
            outAllPrimaryParameters = v::outAllPrimaryParameters;
            hs = BaseHashSet.add(BackendVariable.varCref(v), hs);
        then ();

        // primary external object
        case (BackendDAE.VAR(varKind=BackendDAE.EXTOBJ(), bindExp=SOME(bindExp))) guard 0 == secondary[i] and BaseHashSet.hasAll(crefs, hs)
          equation
            outAllPrimaryParameters = v::outAllPrimaryParameters;
            v = BackendVariable.setVarFixed(v, true);
            outGlobalKnownVars = BackendVariable.addVar(v, outGlobalKnownVars);
            hs = BaseHashSet.add(BackendVariable.varCref(v), hs);
        then ();

        // secondary parameter
        case (BackendDAE.VAR(varKind=BackendDAE.PARAM()))
          equation
            otherVariables = BackendVariable.addVar(v, otherVariables);
            v = BackendVariable.setVarFixed(v, false);
            outInitVars = BackendVariable.addVar(v, outInitVars);
            outGlobalKnownVars = BackendVariable.addVar(v, outGlobalKnownVars);
          then ();

        // primary variable
        case (_) guard BackendVariable.isVarAlg(v) and 0 == secondary[i] and BaseHashSet.hasAll(crefs, hs)
          equation
            otherVariables = BackendVariable.addVar(v, otherVariables);
            v = BackendVariable.setVarFixed(v, true);
            outGlobalKnownVars = BackendVariable.addVar(v, outGlobalKnownVars);
            hs = BaseHashSet.add(BackendVariable.varCref(v), hs);
          then ();

        // secondary variable
        case (_) guard BackendVariable.isVarAlg(v)
          equation
            otherVariables = BackendVariable.addVar(v, otherVariables);
            v = BackendVariable.setVarFixed(v, false);
            outGlobalKnownVars = BackendVariable.addVar(v, outGlobalKnownVars);
          then ();

        else
          equation
            otherVariables = BackendVariable.addVar(v, otherVariables);
          then ();
      end match;
    end for;

    GCExt.free(secondary);
    outAllPrimaryParameters := listReverse(outAllPrimaryParameters);
    dae := BackendDAEUtil.setDAEGlobalKnownVars(dae, otherVariables);

    //BackendDump.dumpVarList(outAllPrimaryParameters, "outAllPrimaryParameters");
    //BackendDump.dumpVariables(otherVariables, "otherVariables");
  end if;
end selectInitializationVariablesDAE;

function addExtObjToGlobalKnownVars "
  Sets fixed=true for external objects with binding and adds them to globalKnownVars
  author: ptaeuber"
  input output BackendDAE.Var extObj;
  input output BackendDAE.Variables globalKnownVars;
algorithm
  globalKnownVars := match(extObj)
    local
      BackendDAE.Var var;
    // external object with binding
    case (BackendDAE.VAR(varKind=BackendDAE.EXTOBJ(), bindExp=SOME(_))) equation
      var = BackendVariable.setVarFixed(extObj, true);
      globalKnownVars = BackendVariable.addVar(var, globalKnownVars);
    then (globalKnownVars);
    else
      then (globalKnownVars);
  end match;
end addExtObjToGlobalKnownVars;

protected function createGlobalKnownVarsEquations
  "Creates BackendDAE.EQUATION()s from the globalKnownVars
  author: ptaeuber"
  input output BackendDAE.Var var;
  input output BackendDAE.EquationArray parameterEqns;
protected
  DAE.Exp lhs, rhs, startValue;
  BackendDAE.Equation eqn;
  BackendDAE.Var v;
  String s, str;
  SourceInfo info;
algorithm
  lhs := BackendVariable.varExp(var);

  if BackendVariable.isParam(var) and not BackendVariable.varHasBindExp(var) and BackendVariable.varFixed(var) then
    s := ExpressionDump.printExpStr(lhs);
    startValue := BackendVariable.varStartValue(var);
    str := ExpressionDump.printExpStr(startValue);
    v := BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
    v := BackendVariable.setBindExp(v, SOME(startValue));
    v := BackendVariable.setVarFixed(v, true);
    info := ElementSource.getElementSourceFileInfo(BackendVariable.getVarSource(v));
    Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s, str}, info);
  end if;

  try
    rhs := BackendVariable.varBindExpStartValue(var);
  else
    rhs := DAE.RCONST(0.0);
  end try;
  eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
  parameterEqns := BackendEquation.add(eqn, parameterEqns);
end createGlobalKnownVarsEquations;

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
  input BackendDAE.AdjacencyMatrix inM;
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
      secondaryParams = if (if BackendVariable.isVarAlg(param) then false else not BackendVariable.varFixed(param)) or 1 == inSecondaryParams[i]
                        then List.fold(inM[i], markIndex, inSecondaryParams) else inSecondaryParams;
      secondaryParams = selectSecondaryParameters(rest, inParameters, inM, secondaryParams);
    then secondaryParams;

  end match;
end selectSecondaryParameters;

public function flattenParamComp
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
algorithm
  outVars := BackendVariable.traverseBackendDAEVars(inEqSystem.orderedVars, selectInitializationVariables2, inVars);
end selectInitializationVariables1;

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
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
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
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp, outUseHomotopy) := Expression.traverseExpBottomUp(inExp, simplifyInitialFunctionsExp, inUseHomotopy);
end simplifyInitialFunctions;

protected function simplifyInitialFunctionsExp
  input DAE.Exp inExp;
  input Boolean inUseHomotopy;
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp, outUseHomotopy) := match inExp
    local
      DAE.Exp expr;

    case DAE.CALL(path=Absyn.IDENT(name="initial"))
    then (DAE.BCONST(true), inUseHomotopy);

    case DAE.CALL(path=Absyn.IDENT(name="sample"))
    then (DAE.BCONST(false), inUseHomotopy);

    case DAE.CALL(path=Absyn.IDENT(name="delay"), expLst=_::expr::_)
    then (expr, inUseHomotopy);

    case DAE.CALL(path=Absyn.IDENT(name="homotopy"))
    then (inExp, true);

    else (inExp, inUseHomotopy);
  end match;
end simplifyInitialFunctionsExp;

// =============================================================================
// section for pre-balancing the initial system
//
// This section removes unused pre variables and auto-fixes non-pre variables,
// which occur in no equation.
// =============================================================================

protected function preBalanceInitialSystem "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem = inEqSystem;
  output list<BackendDAE.Var> outDumpVars;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  Boolean b;
  BackendDAE.AdjacencyMatrix mt;
algorithm
  (_, mt) := BackendDAEUtil.adjacencyMatrix(inEqSystem, BackendDAE.NORMAL(), NONE(), true);
  (orderedVars, orderedEqs, b, outDumpVars) := preBalanceInitialSystem1(arrayLength(mt), mt, inEqSystem.orderedVars, inEqSystem.orderedEqs, false, {});
  if b then
    outEqSystem.orderedEqs := orderedEqs;
    outEqSystem.orderedVars := orderedVars;
    outEqSystem := BackendDAEUtil.clearEqSyst(outEqSystem);
  end if;
end preBalanceInitialSystem;

protected function preBalanceInitialSystem1 "author: lochel"
  input Integer n;
  input BackendDAE.AdjacencyMatrix mt;
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
      Boolean b;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqs;
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
  input BackendDAE.AdjacencyMatrix mt;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs;
  input Boolean inB;
  input list<BackendDAE.Var> inDumpVars;
  output BackendDAE.Variables outVars = inVars;
  output BackendDAE.EquationArray outEqs = inEqs;
  output Boolean outB = inB;
  output list<BackendDAE.Var> outDumpVars = inDumpVars;
protected
  list<Integer> row;
  BackendDAE.Var var;
  DAE.ComponentRef cref;
algorithm
  try
    row := mt[n];
    if listEmpty(row) then
      outB := true;
      var := BackendVariable.getVarAt(inVars, n);
      cref := BackendVariable.varCref(var);

      if ComponentReference.isPreCref(cref) then
        (outVars, _) := BackendVariable.removeVars({n}, inVars, {});
      else
        (outEqs, outDumpVars) := addStartValueEquations({var}, inEqs, inDumpVars);
      end if;
    end if;
  else
    Error.addInternalError("function preBalanceInitialSystem2 failed", sourceInfo());
    fail();
  end try;
end preBalanceInitialSystem2;

protected function analyzeInitialSystem "author: lochel
  This function fixes discrete and state variables to balance the initial equation system."
  input BackendDAE.BackendDAE inInitDAE;
  input BackendDAE.Variables inInitVars;
  input constraintHandlerFunc func = balanceInitialSystem;
  output BackendDAE.BackendDAE outDAE;
  output list<BackendDAE.Var> outDumpVars;
  output list<BackendDAE.Equation> outRemovedEqns;
protected
  BackendDAE.BackendDAE dae;
  BackendDAE.EqSystem syst;
  list<BackendDAE.EqSystem> eqs;
  DoubleEnded.MutableList<BackendDAE.Var> dumpVars;
  DoubleEnded.MutableList<BackendDAE.Equation> removedEqns;
  list<BackendDAE.Equation> filtered_initial_eqs;
algorithm
  // filter empty systems
  eqs := {};
  dumpVars := DoubleEnded.fromList({});
  removedEqns := DoubleEnded.fromList({});
  for syst in inInitDAE.eqs loop
    if BackendDAEUtil.nonEmptySystem(syst) then
      eqs := syst::eqs;
    else
      filtered_initial_eqs := list(eqn for eqn guard(BackendEquation.hasAnyUnknown(eqn, inInitVars)) in BackendEquation.equationList(syst.orderedEqs));
      DoubleEnded.push_list_back(removedEqns, filtered_initial_eqs);
      DoubleEnded.push_list_back(removedEqns, BackendEquation.equationList(syst.removedEqs));
    end if;
  end for;
  dae := BackendDAE.DAE(eqs, inInitDAE.shared);

  //execStat("reset analyzeInitialSystem (initialization)");
  outDAE := BackendDAEUtil.mapEqSystemAndFold(dae, function func(initVars=inInitVars, dumpVars=dumpVars, removedEqns=removedEqns), 0);
  outRemovedEqns := DoubleEnded.toListAndClear(removedEqns);
  outDumpVars := DoubleEnded.toListAndClear(dumpVars);
end analyzeInitialSystem;

protected function getInitEqIndices
  input list<BackendDAE.Equation> equations;
  output list<Integer> indices = {};
protected
  Integer i = 1;
algorithm
  for eq in equations loop
    if BackendEquation.isInitialEquation(eq) then
      indices := i :: indices;
    end if;

    i := i + 1;
  end for;

  indices := listReverseInPlace(indices);
end getInitEqIndices;

protected partial function constraintHandlerFunc
  input BackendDAE.EqSystem inEqSystem                              "initial system to be balanced";
  input BackendDAE.Shared inShared                                  "shared information along all systems";
  output BackendDAE.EqSystem outEqSystem                            "balanced initial system";
  output BackendDAE.Shared outShared = inShared                     "possibly adapted shared information";
  input output Integer dummy                                        "traverser dummy";
  input BackendDAE.Variables initVars                               "all variables that are allowed to be fixed";
  input DoubleEnded.MutableList<BackendDAE.Var> dumpVars            "new fixed variables";
  input DoubleEnded.MutableList<BackendDAE.Equation> removedEqns    "redundant equations";
end constraintHandlerFunc;

protected function balanceInitialSystem "author: kabdelhak
  New algorithm to handle under-, over-, and mixed-determined systems.
  1. split off initial equations and match the system without them
     (ensures that the correct equations are left unmatched)
  2. sort fixables to be matched last
     (ensures that the correct variables are left unmatched)
  3. compute adjacency matrix
  4. inverse match (var->eq)
  5. add initial equations and continue matching
  6. use subroutine resolveOverAndUnderconstraints for unmatched variables and equations
  7. use ASSC algorithm to resolve analytical singularities
     If ASSC changed anything:
     7.1 inverse match (var->eq)
     7.2 use subroutine resolveOverAndUnderconstraints for unmatched variables and equations
  8. success"
  extends constraintHandlerFunc;
protected
  Boolean debug = false;
  list<BackendDAE.Equation> eqn_lst, init_eqns, sim_eqns;
  DAE.FunctionTree funcs;
  BackendDAE.AdjacencyMatrix m, mT;
  BackendDAE.AdjacencyMatrixEnhanced me;
  Integer nVars, nEqns;
  array<Integer> scal_to_arr, var_to_eqn, eqn_to_var;
  Boolean changed = false;
  list<list<Integer>> comps;
  list<Integer> redundantEqns, unfixedVars;
  Boolean initASSC = Flags.getConfigBool(Flags.INIT_ASSC);
algorithm
  if BackendVariable.varsSize(inEqSystem.orderedVars) > 0 then
    // 1. split off initial equations and match the system without them
    (init_eqns, sim_eqns) := List.splitOnTrue(BackendEquation.equationList(inEqSystem.orderedEqs), BackendEquation.isInitialEquation);

    // 2. sort fixables to be matched last
    outEqSystem := BackendDAEUtil.createEqSystem(BackendVariable.sortInitialVars(inEqSystem.orderedVars, initVars), BackendEquation.listEquation(sim_eqns));
    outEqSystem.removedEqs := inEqSystem.removedEqs;
    funcs := BackendDAEUtil.getFunctions(inShared);

    // 3. compute adjacency matrix
    (outEqSystem, m, mT, _, scal_to_arr) := BackendDAEUtil.getAdjacencyMatrixScalar(outEqSystem, BackendDAE.SOLVABLE(), SOME(funcs), true);

    // 4. inverse match (var->eq)
    nVars := BackendVariable.varsSize(outEqSystem.orderedVars);
    // take original size here so that we can freely add the initial equations later
    nEqns := BackendEquation.equationArraySize(inEqSystem.orderedEqs);
    (eqn_to_var, var_to_eqn, _, _, _) := Matching.RegularMatching(mT, nEqns, nVars);

    // 5. add initial equations and continue matching
    outEqSystem.orderedEqs := BackendEquation.addList(init_eqns, outEqSystem.orderedEqs);
    (outEqSystem, m, mT, _, scal_to_arr) := BackendDAEUtil.getAdjacencyMatrixScalar(outEqSystem, BackendDAE.SOLVABLE(), SOME(funcs), true);
    (eqn_to_var, var_to_eqn, _, _, _) := Matching.ContinueMatching(mT, nEqns, nVars, eqn_to_var, var_to_eqn);

    unfixedVars   := list(i for i guard(var_to_eqn[i] < 0) in 1:arrayLength(var_to_eqn));
    redundantEqns := list(i for i guard(eqn_to_var[i] < 0) in 1:arrayLength(eqn_to_var));

    if not (listEmpty(redundantEqns) and listEmpty(unfixedVars)) then
      // 6. use subroutine resolveOverAndUnderconstraints for unmatched variables and equations
      (me, _, _, _) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(outEqSystem, inShared, false);
      (_, _, _) := consistencyCheck(redundantEqns, outEqSystem.orderedEqs, outEqSystem.orderedVars, inShared, 0, m, me, var_to_eqn, eqn_to_var, scal_to_arr);
      redundantEqns := List.unique(list(scal_to_arr[i] for i in redundantEqns));
      outEqSystem := resolveOverAndUnderconstraints(outEqSystem, initVars, unfixedVars, redundantEqns, dumpVars, removedEqns);
      (outEqSystem, m, mT, _, scal_to_arr) := BackendDAEUtil.getAdjacencyMatrixScalar(outEqSystem, BackendDAE.SOLVABLE(), SOME(funcs), true);
      nVars := BackendVariable.varsSize(outEqSystem.orderedVars);
      nEqns := BackendEquation.equationArraySize(outEqSystem.orderedEqs);
      (eqn_to_var, var_to_eqn, _, _, _) := Matching.RegularMatching(mT, nEqns, nVars);
    elseif not initASSC then
      outEqSystem := inEqSystem;
    end if;

    if debug then
      BackendDump.dumpEqSystem(outEqSystem, "fixInitialSystem");
      BackendDump.dumpAdjacencyMatrixT(mT);
      BackendDump.dumpMatchingVars(var_to_eqn);
      BackendDump.dumpMatchingEqns(eqn_to_var);
    end if;

    // 7. use ASSC algorithm to resolve analytical singularities
    if initASSC then
      comps := Sorting.Tarjan(m, var_to_eqn, nEqns);

      for comp in comps loop
        (eqn_to_var, var_to_eqn, outEqSystem, changed) := BackendDAEUtil.analyticalToStructuralSingularity(comp, eqn_to_var, var_to_eqn, outEqSystem, changed, true);
      end for;

      if changed then
        // 7.1 inverse match (var->eq)
        BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT)) := outEqSystem;
        (outEqSystem, m, mT, _, scal_to_arr) := BackendDAEUtil.getAdjacencyMatrixScalar(outEqSystem, BackendDAE.NORMAL(), SOME(funcs), true);
        (eqn_to_var, var_to_eqn, _, _, _) := Matching.ContinueMatching(mT, nEqns, nVars, eqn_to_var, var_to_eqn);

        unfixedVars   := list(i for i guard(var_to_eqn[i] < 0) in 1:arrayLength(var_to_eqn));
        redundantEqns := list(i for i guard(eqn_to_var[i] < 0) in 1:arrayLength(eqn_to_var));
        redundantEqns := List.unique(list(scal_to_arr[i] for i in redundantEqns));

        if not (listEmpty(redundantEqns) and listEmpty(unfixedVars)) then
          // 7.2 use subroutine resolveOverAndUnderconstraints for unmatched variables and equations
          (me, _, _, _) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(outEqSystem, inShared, false);
          (_, _, _) := consistencyCheck(redundantEqns, outEqSystem.orderedEqs, outEqSystem.orderedVars, inShared, 0, m, me, var_to_eqn, eqn_to_var, scal_to_arr);
          outEqSystem := resolveOverAndUnderconstraints(outEqSystem, initVars, unfixedVars, redundantEqns, dumpVars, removedEqns);
          (outEqSystem, m, mT, _, scal_to_arr) := BackendDAEUtil.getAdjacencyMatrixScalar(outEqSystem, BackendDAE.SOLVABLE(), SOME(funcs), true);
        end if;
      end if;
    end if;
  else
    outEqSystem := inEqSystem;
  end if;
end balanceInitialSystem;

protected function resolveOverAndUnderconstraints "author: kabdelhak
  Subroutine for balanceInitialSystem
  New algorithm to handle under-, over-, and mixed-determined systems.
  1. remove unmatched equations
  2. fix unmatched initialVars"
  input output BackendDAE.EqSystem syst                             "possibly mixed determined system to be resolved";
  input BackendDAE.Variables initVars                               "variables that are allowed to be fixed";
  input list<Integer> unfixedVars                                   "indices of variables that have to be fixed";
  input list<Integer> redundantEqns                                 "indices of equations that have to be removed";
  input DoubleEnded.MutableList<BackendDAE.Var> dumpVars            "variables that have been fixed (debug report)";
  input DoubleEnded.MutableList<BackendDAE.Equation> removedEqns    "equations that have been removed (debug report)";
protected
  Boolean debug = false;
  list<BackendDAE.Equation> redundant_lst = {};
  list<BackendDAE.Var> failed_var_lst, var_lst = {};
  BackendDAE.EquationArray new_eqns;
algorithm
  // 6. remove unmatched equations
  redundant_lst := BackendEquation.getList(redundantEqns, syst.orderedEqs);

  DoubleEnded.push_list_back(removedEqns, redundant_lst);
  new_eqns := BackendEquation.deleteList(syst.orderedEqs, redundantEqns);
  if debug then
    BackendDump.dumpEquationList(redundant_lst, "removed eqns");
  end if;

  // 7. fix unmatched states and discrete states
  var_lst := list(BackendVariable.getVarAt(syst.orderedVars, i) for i in unfixedVars);
  (new_eqns, var_lst) := addStartValueEquations(var_lst, new_eqns, {});
  DoubleEnded.push_list_back(dumpVars, var_lst);
  if debug then
    failed_var_lst := list(var for var guard(not BackendVariable.containsVar(var, initVars)) in var_lst);
    BackendDump.dumpVarList(var_lst, "fixed vars");
    // report these in general?
    BackendDump.dumpVarList(failed_var_lst, "failed vars");
  end if;

  // 8. success
  syst := BackendDAEUtil.setEqSystEqs(syst, BackendEquation.sortInitialEqns(new_eqns));
end resolveOverAndUnderconstraints;

protected function fixInitialSystem "author: lochel
  This function handles under-, over-, and mixed-determined systems with a given index."
  extends constraintHandlerFunc;
protected
  BackendDAE.EquationArray eqns2;
  list<BackendDAE.Var> dumpVars2 = {};
  list<BackendDAE.Equation> removedEqns2;
  Integer nVars, nEqns, nInitEqs, nAddEqs, nAddVars;
  list<Integer> stateIndices, range, initEqsIndices, redundantEqns;
  list<BackendDAE.Var> initVarList;
  array<Integer> ass1, ass2;
  BackendDAE.AdjacencyMatrix m "adjacency matrix of modified system";
  BackendDAE.AdjacencyMatrix m_ "adjacency matrix of original system (TODO: fix this one)";
  BackendDAE.EqSystem syst;
  DAE.FunctionTree funcs;
  BackendDAE.AdjacencyMatrixEnhanced me;
  array<Integer> mapIncRowEqn;
  Boolean perfectMatching;
  Integer maxMixedDeterminedIndex = intMax(0, Flags.getConfigInt(Flags.MAX_MIXED_DETERMINED_INDEX));

  array<Boolean> eMarks, vMarks;
  list<Integer> singular_eqns_idx, singular_vars_idx;
  Integer overDetIndex, underDetIndex, scalarEqnSize;
  BackendDAE.Equation eq;
  constant Boolean debug = false;
algorithm
  for index in 0:maxMixedDeterminedIndex loop
    //print("index-" + intString(index) + " start\n");

    // nVars = nEqns
    nVars := BackendVariable.varsSize(inEqSystem.orderedVars);
    nEqns := BackendEquation.equationArraySize(inEqSystem.orderedEqs);
    syst := BackendDAEUtil.createEqSystem(inEqSystem.orderedVars, inEqSystem.orderedEqs);
    funcs := BackendDAEUtil.getFunctions(inShared);
    (m_, _, _, mapIncRowEqn) := BackendDAEUtil.adjacencyMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), BackendDAEUtil.isInitializationDAE(inShared)); // Should always be true, just to be sure
    if debug then
      BackendDump.dumpEqSystem(syst, "fixInitialSystem");
      BackendDump.dumpVariables(initVars, "selected initialization variables");
      BackendDump.dumpVariables(inEqSystem.orderedVars, "vars in the system");
      BackendDump.dumpAdjacencyMatrix(m_);
    end if;

    // get state-index list
    stateIndices := BackendVariable.getVarIndexFromVariablesIndexInFirstSet(inEqSystem.orderedVars, initVars);

    // modify adjacency matrix for under-determined systems
    nAddEqs := intMax(nVars-nEqns + index, index);
    if debug then print("nAddEqs: " + intString(nAddEqs) + "\n"); end if;
    m := fixUnderDeterminedSystem(m_, stateIndices, nEqns, nAddEqs);

    // modify adjacency matrix for over-determined systems
    nAddVars := intMax(nEqns-nVars + index, index);
    if debug then print("nAddVars: " + intString(nAddVars) + "\n"); end if;
    m := fixOverDeterminedSystem(m, inEqSystem.orderedEqs, nVars, nAddVars);

    // match the system (nVars+nAddVars == nEqns+nAddEqs)
    //ass1 := arrayCreate(nVars+nAddVars, -1);
    //ass2 := arrayCreate(nEqns+nAddEqs, -1);
    //Matching.matchingExternalsetAdjacencyMatrix(nVars+nAddVars, nEqns+nAddEqs, m);
    //BackendDAEEXT.matching(nVars+nAddVars, nEqns+nAddEqs, 5, 0, 0.0, 1);
    //BackendDAEEXT.getAssignment(ass2, ass1);
    //perfectMatching := listEmpty(Matching.getUnassigned(nVars+nAddVars, ass1, {}));
    (ass1, ass2, perfectMatching, eMarks, vMarks) := Matching.RegularMatching(m, nVars+nAddVars, nEqns+nAddEqs);
    if debug then
      BackendDump.dumpMatchingVars(ass1);
      BackendDump.dumpMatchingEqns(ass2);
    end if;

    // check whether or not a complete matching was found
    if perfectMatching then
      if index > 0 then
        Error.addCompilerNotification("The given system is mixed-determined.   [index = " + intString(index) + "]");
      end if;

      if nAddVars > 0 then
        // map artificial variables to redundant equations
        range := List.intRange2(nVars+1, nVars+nAddVars);
        redundantEqns := mapIndices(range, ass1);
        //print("{" + stringDelimitList(List.map(redundantEqns, intString), ",") + "}\n");

        // symbolic consistency check
        (me, _, _, _) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst, inShared, false);
        (_, _, _) := consistencyCheck(redundantEqns, inEqSystem.orderedEqs, inEqSystem.orderedVars, inShared, nAddVars, m_, me, ass1, ass2, mapIncRowEqn);

        // remove redundant equations
        removedEqns2 := BackendEquation.getList(redundantEqns, inEqSystem.orderedEqs);
        //BackendDump.dumpEquationList(removedEqns2, "removed equations");
        eqns2 := BackendEquation.deleteList(inEqSystem.orderedEqs, redundantEqns);
        //BackendDump.dumpEquationArray(eqns2, "remaining equations");
        DoubleEnded.push_list_back(removedEqns, removedEqns2);
      else
        eqns2 := inEqSystem.orderedEqs;
      end if;

      if nAddEqs > 0 then
        // map artificial equations to unfixed states
        range := List.intRange2(nEqns+1, nEqns+nAddEqs);
        range := mapIndices(range, ass2);
        //print("{" + stringDelimitList(List.map(range, intString), ",") + "}\n");

        // introduce additional initial equations
        initVarList := List.map1r(range, BackendVariable.getVarAt, inEqSystem.orderedVars);
        (eqns2, dumpVars2) := addStartValueEquations(initVarList, eqns2, {});
        //BackendDump.dumpEquationArray(eqns2, "remaining equations");
        //BackendDump.dumpVarList(dumpVars2,"Check fixed attribute in vars");
        DoubleEnded.push_list_back(dumpVars, dumpVars2);
      end if;
      outEqSystem := BackendDAEUtil.setEqSystEqs(inEqSystem, eqns2);

      //print("index-" + intString(index) + " ende\n");
      //execStat("fixInitialSystem (initialization) [nEqns: " + intString(nEqns) + ", nAddEqs: " + intString(nAddEqs) + ", nAddVars: " + intString(nAddVars) + "]");
      return;
    end if;
    if debug then
      print("index-" + intString(index) + " ende\n");
    end if;
  end for;

  if Flags.isSet(Flags.INITIALIZATION) then
    overDetIndex := listLength(list(i for i guard(ass1[i] < 0) in 1:arrayLength(ass1)));
    underDetIndex := listLength(list(i for i guard(ass2[i] < 0) in 1:arrayLength(ass2)));

    // get singular indices from markings after pantelides matching
    // take care to crop the end such that the artificial variables are not taken into account
    singular_eqns_idx := list(i for i guard(eMarks[i]) in 1:arrayLength(mapIncRowEqn));
    singular_vars_idx := list(i for i guard(vMarks[i]) in 1:BackendVariable.varsSize(syst.orderedVars));

    // get array indices from scalar indices
    scalarEqnSize := listLength(singular_eqns_idx);
    singular_eqns_idx := List.uniqueOnTrue(list(mapIncRowEqn[i] for i in singular_eqns_idx), intEq);

    print("\n------------ UNBALANCED INITIAL SYSTEM ------------\n");
    print("The initial system is over- as well as underdetermined and it could not be resolved after " + intString(maxMixedDeterminedIndex) + " iterations.\n\n");
    print("==== OVERDETERMINATION BY " + intString(overDetIndex) + " EQUATION(S)\n");
    print("==== UNDERDETERMINATION OF " + intString(underDetIndex) + " VARIABLE(S)\n");
    print("\n---- involved set eqns (" + intString(scalarEqnSize) + "/" + intString(listLength(singular_eqns_idx)) + "):\n");
    for eqn in singular_eqns_idx loop
      eq := BackendEquation.get(syst.orderedEqs, mapIncRowEqn[eqn]);
      print("  " + intString(eqn) + "(" + intString(BackendEquation.equationSize(eq)) + "):\t" + BackendDump.equationString(eq) + "\n");
    end for;
    print("\n---- involved set vars (" + intString(listLength(singular_vars_idx)) + "):\n");
    for var in singular_vars_idx loop
      print("  " + intString(var) + ":\t" + BackendDump.varString(BackendVariable.getVarAt(syst.orderedVars, var)) + "\n");
    end for;
    print("--------------------------------------------------\n");
  end if;

  Error.addMessage(Error.MIXED_DETERMINED, {intString(maxMixedDeterminedIndex)});
  fail();
end fixInitialSystem;

protected function updateFixedAttribute
  "function which updates the fixed attribute of a variable"
  input output BackendDAE.Var var;
  input output BackendDAE.Variables vars;
protected
  DAE.ComponentRef cr;
algorithm
  cr := BackendVariable.varCref(var);
  if BackendVariable.containsCref(cr, vars) then
    var := BackendVariable.setVarFixed(var, true);
  end if;
end updateFixedAttribute;

protected function fixUnderDeterminedSystem "author: lochel"
  input BackendDAE.AdjacencyMatrix inM;
  input list<Integer> inInitVarIndices;
  input Integer inNEqns;
  input Integer inNAddEqns;
  output BackendDAE.AdjacencyMatrix outM;
protected
  list<Integer> newEqIndices;
algorithm
  if inNAddEqns < 0 then
    Error.addInternalError("function fixUnderDeterminedSystem failed due to invalid input", sourceInfo());
    fail();
  end if;

  if inNAddEqns > 0 then
    outM := arrayCreate(inNEqns+inNAddEqns, {});
    outM := Array.copy(inM, outM);
    newEqIndices := List.intRange2(inNEqns+1, inNEqns+inNAddEqns);
    outM := List.fold1(newEqIndices, squareAdjacencyMatrix1, inInitVarIndices, outM);
  else
    outM := arrayCopy(inM) "deep copy";
  end if;
end fixUnderDeterminedSystem;

protected function squareAdjacencyMatrix1 "author: lochel"
  input Integer inPos;
  input list<Integer> inDependency;
  input BackendDAE.AdjacencyMatrix inM;
  output BackendDAE.AdjacencyMatrix outM = inM;
algorithm
  outM[inPos] := inDependency;
end squareAdjacencyMatrix1;

protected function fixOverDeterminedSystem "author: lochel"
  input BackendDAE.AdjacencyMatrix inM;
  input BackendDAE.EquationArray orderedEqs;
  input Integer inNVars;
  input Integer inNAddVars;
  output BackendDAE.AdjacencyMatrix outM;
protected
  list<Integer> newVarIndices, initEqsIndices;
algorithm
  if inNAddVars < 0 then
    Error.addInternalError("function fixOverDeterminedSystem failed due to invalid input", sourceInfo());
    fail();
  end if;

  if inNAddVars > 0 then
    initEqsIndices := getInitEqIndices(BackendEquation.equationList(orderedEqs));
    newVarIndices := List.intRange2(inNVars+1, inNVars+inNAddVars);
    outM := List.fold1(initEqsIndices, squareAdjacencyMatrix2, newVarIndices, inM);
  else
    outM := inM;
  end if;
end fixOverDeterminedSystem;

protected function squareAdjacencyMatrix2 "author: lochel"
  input Integer inPos;
  input list<Integer> inRange;
  input BackendDAE.AdjacencyMatrix inM;
  output BackendDAE.AdjacencyMatrix outM = inM;
algorithm
  outM[inPos] := listAppend(inM[inPos], inRange);
end squareAdjacencyMatrix2;

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
    startExp := Expression.crefExp(ComponentReference.crefPrefixStart(cref));

    eqn := BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
    outEqns := BackendEquation.add(eqn, outEqns);

    if isPreCref then
      dumpVar := BackendVariable.copyVarNewName(cref, var);
      // crStr = BackendDump.varString(dumpVar);
      // fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "  " + crStr);
      dumpVar := BackendVariable.setVarFixed(dumpVar, true);
      outDumpVars := dumpVar::outDumpVars;
    else
      // crStr = BackendDump.varString(var);
      // fcall(Flags.INITIALIZATION, Error.addCompilerWarning, "  " + crStr);
      dumpVar := BackendVariable.setVarFixed(var, true);
      outDumpVars := dumpVar::outDumpVars;
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
  input BackendDAE.AdjacencyMatrix inM;
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
      list<Integer> consistentEquations, consistentEquations2, inconsistentEquations, uncheckedEquations, uncheckedEquations2;
      BackendDAE.AdjacencyMatrix m;
      Integer nVars, nEqns, currRedundantEqn, redundantEqn;
      list<list<Integer>> comps;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.EquationArray substEqns;

    case {}
    then ({}, {}, {});

    case currRedundantEqn::restRedundantEqns equation
      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendEquation.equationArraySize(inEqns);
    //BackendDump.dumpMatchingVars(vecVarToEqs);
    //BackendDump.dumpMatchingEqns(vecEqsToVar);
    //BackendDump.dumpVariables(inVars, "inVars");
    //BackendDump.dumpEquationArray(inEqns, "inEqns");
    //BackendDump.dumpList(inRedundantEqns, "inRedundantEqns: ");
    //BackendDump.dumpAdjacencyMatrix(inM);

      // get the sorting and algebraic loops
      comps = Sorting.Tarjan(inM, vecVarToEqs, nEqns);
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

      consistentEquations2 = listAppend(consistentEquations, outRange);
      uncheckedEquations2 = listAppend(uncheckedEquations, uncheckedEquations2);
    //BackendDump.dumpList(outRange, "outRange: ");
    //BackendDump.dumpEquationArray(inEqns, "inEqns");
    //BackendDump.dumpEquationArray(substEqns, "substEqns");
    then (consistentEquations2, inconsistentEquations, uncheckedEquations2);

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
  outSolvable := match(inElem)
    local
      Integer id;
      BackendDAE.AdjacencyMatrixElementEnhanced elem;
      Boolean b;

    case {}
    then true;

    //case (id, BackendDAE.SOLVABILITY_SOLVED())::elem guard intEq(id, inVarID)
    //then false;

    case (id, BackendDAE.SOLVABILITY_UNSOLVABLE(),_)::_ guard intEq(id, inVarID)
    then false;

    case (id, BackendDAE.SOLVABILITY_NONLINEAR(),_)::_ guard intEq(id, inVarID)
    then false;

    case (_, _, _)::elem equation
      b = isVarExplicitSolvable(elem, inVarID);
    then b;
  end match;
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
  input BackendDAE.AdjacencyMatrix inM;
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
    Error.addCompilerNotification("It was not possible to check the given initialization system for consistency symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    fail();
  end try;
end compsMarker;

protected function compsMarker2
  input list<Integer> inVarList;
  input array<Integer> inVecVarToEq;
  input BackendDAE.AdjacencyMatrix inM;
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
      Error.addCompilerNotification("It was not possible to check the given initialization system for consistency symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    then fail();
  end matchcontinue;
end compsMarker2;

protected function downCompsMarker
  input list<Integer> unassignedEqns;
  input array<Integer> vecVarToEq;
  input BackendDAE.AdjacencyMatrix m;
  input list<Integer> flatComps;
  input output list<Integer> inMarkedEqns;
  input list<Integer> inLoopListComps;
algorithm
  for indexUnassigned in unassignedEqns loop
    if listMember(indexUnassigned, inMarkedEqns) then
      inMarkedEqns := compsMarker2(m[indexUnassigned], vecVarToEq, m, flatComps, inMarkedEqns, inLoopListComps);
    end if;
  end for;
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

    case {}
    then inRepls;

    case markedEqn::markedEqns equation
      indexVar = inVecEqToVar[markedEqn];
      true = isVarExplicitSolvable(inME[markedEqn], indexVar);
      var = BackendVariable.getVarAt(inVars, indexVar);

      indexEq = inMapIncRowEqn[markedEqn];
      eqn = BackendEquation.get(inEqns, indexEq);

      cref = BackendVariable.varCref(var);
      type_ = BackendVariable.varType(var);
      x = DAE.CREF(cref, type_);
      (eqn as BackendDAE.EQUATION(scalar=exp)) = BackendEquation.solveEquation(eqn, x, SOME(inShared.functionTree));

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
  eqn := BackendEquation.get(outEqnList, inEqnIndex);
  ({eqn}, _) := BackendVarTransform.replaceEquations({eqn}, inVarRepls, NONE());
  outEqnList := BackendEquation.setAtIndex(outEqnList, inEqnIndex, eqn);
end applyVarReplacements;

protected function getConsistentEquation "author: mwenzler"
  input Integer inUnassignedEqn;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.EquationArray inEqnsOrig;
  input BackendDAE.AdjacencyMatrix inM;
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
      Integer nVars, nEqns;
      list<Integer> listVar;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn, eqn2;
      DAE.Exp lhs, rhs, exp;
      list<String> listParameter;
      BackendDAE.AdjacencyMatrix m;
      BackendDAE.EqSystem system;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> list_inEqns;
      Boolean anyStartValue;

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendEquation.equationArraySize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.get(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      true = Expression.isZero(exp);
      //listParameter = parameterCheck(exp);
      //true = listEmpty(listParameter);
      _ = BackendEquation.get(inEqnsOrig, inUnassignedEqn);
      // Error.addCompilerNotification("The following equation is consistent and got removed from the initialization problem: " + BackendDump.equationString(eqn));
    then ({inUnassignedEqn}, true, {});

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendEquation.equationArraySize(inEqnsOrig);
      true = intGt(counter, nEqns-nVars);

      Error.addCompilerError("Initialization problem is structural singular. Please, check the initial conditions.");
    then ({}, true, {});

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendEquation.equationArraySize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);

      eqn = BackendEquation.get(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      (listParameter, false) = parameterCheck(exp);
      true = listEmpty(listParameter);

      eqn2 = BackendEquation.get(inEqnsOrig, inUnassignedEqn);
      Error.addCompilerError("The initialization problem is inconsistent due to the following equation: " + BackendDump.equationString(eqn2) + " (" + BackendDump.equationString(eqn) + ")");
    then ({}, false, {});

    case _ equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendEquation.equationArraySize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.get(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      listParameter = parameterCheck(exp);
      false = listEmpty(listParameter);

      list_inEqns = BackendEquation.equationList(inEqns);
      list_inEqns = List.set(list_inEqns, inUnassignedEqn, eqn);
      eqns = BackendEquation.listEquation(list_inEqns);
      funcs = BackendDAEUtil.getFunctions(shared);
      system = BackendDAEUtil.createEqSystem(vars, eqns);
      (m, _) = BackendDAEUtil.adjacencyMatrix(system, BackendDAE.NORMAL(), SOME(funcs), BackendDAEUtil.isInitializationDAE(shared));
      listVar = m[inUnassignedEqn];
      false = listEmpty(listVar);

      _ = BackendEquation.get(inEqnsOrig, inUnassignedEqn);
      Error.addCompilerNotification("It was not possible to check the given initialization system for consistency symbolically, because the relevant equations are part of an algebraic loop. This is not supported yet.");
    then ({}, false, {});

    case _ equation
      //true = listEmpty(inM[inUnassignedEqn]);
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendEquation.equationArraySize(inEqnsOrig);
      true = intLe(counter, nEqns-nVars);
      eqn = BackendEquation.get(inEqns, inUnassignedEqn);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs) = eqn;
      exp = DAE.BINARY(lhs, DAE.SUB(DAE.T_REAL_DEFAULT), rhs);
      (exp, _) = ExpressionSimplify.simplify(exp);
      false = Expression.isZero(exp);

      (listParameter, anyStartValue) = parameterCheck(exp);
      true = not listEmpty(listParameter) or anyStartValue;

      eqn2 = BackendEquation.get(inEqnsOrig, inUnassignedEqn);
      Error.addCompilerWarning("It was not possible to determine if the initialization problem is consistent, because of not evaluable parameters/start values during compile time: " + BackendDump.equationString(eqn2) + " (" + BackendDump.equationString(eqn) + ")");
    then ({}, true, {inUnassignedEqn});
  end matchcontinue;
end getConsistentEquation;

protected function parameterCheck "author: mwenzler"
  input DAE.Exp inExp;
  output list<String> outParameters;
  output Boolean outAnyStartValue;
algorithm
  (_, (outParameters, outAnyStartValue)) := Expression.traverseExpTopDown(inExp, parameterCheck2, ({}, false));
end parameterCheck;

protected function parameterCheck2
  input DAE.Exp inExp;
  input tuple<list<String> /*parameters*/, Boolean /*anyStartValue*/> inParams;
  output DAE.Exp outExp = inExp;
  output Boolean outContinue;
  output tuple<list<String> /*parameters*/, Boolean /*anyStartValue*/> outParams;
protected
  DAE.ComponentRef componentRef;
  list<String> parameters;
  Boolean anyStartValue;
algorithm
  (parameters, anyStartValue) := inParams;
  (outParams, outContinue) := match inExp
    case DAE.CREF(componentRef=componentRef) algorithm
      if ComponentReference.isStartCref(componentRef) then
        anyStartValue := true;
      else
        parameters := ComponentReference.crefStr(componentRef)::parameters;
      end if;
    then ((parameters, anyStartValue), not anyStartValue);

    else (inParams, true);
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
  (outVar, outTpl) := matchcontinue(inVar, inTpl)
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
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(startValue));

      // pre(v) = v.start
      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startValue, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed and isFixed then BackendEquation.add(eqn, eqns) else eqns;
    then (var, (vars, fixvars, eqns, hs));

    // continuous-time
    case (var as BackendDAE.VAR(varName=cr, varType=ty, arryDim=arryDim), (vars, fixvars, eqns, hs)) equation
      preUsed = BaseHashSet.has(cr, hs);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      // pre(v) = v
      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), DAE.CREF(cr, ty), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed then BackendEquation.add(eqn, eqns) else eqns;
    then (var, (vars, fixvars, eqns, hs));

    else (inVar, inTpl);
  end matchcontinue;
end introducePreVarsForAliasVariables;

// =============================================================================
// section for collecting initial vars/eqns
//
// =============================================================================

protected function collectInitialVarsEqnsSystem
  "This function collects variables and equations for the initial system out of an given EqSystem."
  input list<BackendDAE.EqSystem> eqSystems;
  input output BackendDAE.Variables vars;
  input output BackendDAE.Variables fixVars;
  input output BackendDAE.EquationArray eqns;
  input output BackendDAE.EquationArray reEqns;
  input HashSet.HashSet hs;
  input AvlSetCR.Tree allPrimaryParams;
  input Boolean datareconFlag;
protected
  array<Integer> stateSetFixCounts;
algorithm
  for eq in eqSystems loop
    () := match eq
      case BackendDAE.EQSYSTEM(partitionKind = BackendDAE.CLOCKED_PARTITION())
        algorithm
          (vars, eqns) := BackendVariable.traverseBackendDAEVars(eq.orderedVars,
            collectInitialClockedVarsEqns, (vars, eqns));
        then
          ();

      else
        algorithm
          stateSetFixCounts := arrayCreate(listLength(eq.stateSets), 0);
          (vars, fixVars, eqns, stateSetFixCounts, _, _, _) := BackendVariable.traverseBackendDAEVars(eq.orderedVars,
            collectInitialVars, (vars, fixVars, eqns, stateSetFixCounts, hs, allPrimaryParams, datareconFlag));
          (eqns, reEqns) := BackendEquation.traverseEquationArray(eq.orderedEqs, collectInitialEqns, (eqns, reEqns));
          if Flags.getConfigBool(Flags.INITIAL_STATE_SELECTION) then
            (vars, eqns) := collectInitialStateSets(eq.stateSets, stateSetFixCounts, vars, eqns);
          end if;
          GCExt.free(stateSetFixCounts);
        then
          ();
    end match;
  end for;
end collectInitialVarsEqnsSystem;

protected function collectInitialStateSets "author: kabdelhak
  This function collects all information from stateSets for the initial system.
  TODO: Implement better algorithm for stateSets which are not selfdependent."
  input BackendDAE.StateSets stateSets;
  input array<Integer> stateSetFixCounts;
  input BackendDAE.Variables iVars;
  input BackendDAE.EquationArray iEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.EquationArray oEqns;

  protected
  BackendDAE.StateSet stateSet;
  BackendDAE.Equation eqn, Feqn, initEqn;
  DAE.Exp lhs, rhs, exp, expcrF, expInitset, mulFstates;
  list<DAE.Exp> expLst = {}, expcrstates, expcrInitset;
  list<DAE.ComponentRef> crLst, crInitSet;
  DAE.ComponentRef set, crF, crInitStates;
  BackendDAE.Var var, fixState;
  list<BackendDAE.Var> statesToFix = {}, unfixedStates = {}, VarsF, oInitSetVars;
  DAE.Type tp, tyExpCrStates;
  Integer toFix, setsize, nCandidates;
  Option<Integer> recordSize;
  Boolean b;
  DAE.Operator op;
  DAE.ElementSource source;
algorithm
  (oVars, oEqns) := (iVars, iEqns);
  for stateSet in stateSets loop
    oVars := BackendVariable.addVars(stateSet.varA, oVars);
    lhs := Expression.crefToExp(stateSet.crA);
    tp := ComponentReference.crefTypeFull(stateSet.crA);
    tp := DAEUtil.expTypeElementType(tp);
    if DAEUtil.expTypeComplex(tp) then
      recordSize := SOME(Expression.sizeOf(tp));
    else
      recordSize := NONE();
    end if;

    expLst:={};

    crLst := SymbolicJacobian.getJacobianDependencies(stateSet.jacobian);
    expLst := list(Expression.crefToExp(cr) for cr in crLst);
    expLst := DAE.ICONST(integer=stateSet.index-1)::expLst;

    rhs := DAE.CALL(path=Absyn.IDENT(name="$stateSelectionSet"),expLst=expLst,attr=DAE.callAttrBuiltinOther);
    eqn := BackendDAE.ARRAY_EQUATION(dimSize={listLength(stateSet.varA)}, left=lhs, right=rhs,source=DAE.emptyElementSource,attr=BackendDAE.EQ_ATTR_DEFAULT_INITIAL, recordSize=recordSize);
    oEqns := ExpandableArray.add(eqn,oEqns);

    if Flags.isSet(Flags.BLT_DUMP) or Flags.isSet(Flags.INITIALIZATION) then
      BackendDump.dumpEquationList({eqn}, "initial state selection equation generated:");
    end if;

    if arrayLength(stateSetFixCounts) >= stateSet.index and arrayGet(stateSetFixCounts,stateSet.index) > 0 then
      unfixedStates := {};
      for state in stateSet.statescandidates loop
         if not BackendVariable.varFixed(state) then
           unfixedStates := state::unfixedStates;
        end if;
      end for;
      toFix := arrayGet(stateSetFixCounts,stateSet.index);
      statesToFix := {};

      // ToDo: If selfdependent -> heuristic, if not -> add new vars and write new pivot algorithm c
      //if IndexReduction.isSelfDependent(stateSet) then
      statesToFix := SymbolicJacobian.getFixedStatesForSelfdependentSets(stateSet,unfixedStates,toFix);

      //oVars := BackendVariable.addVars(statesToFix, oVars);
           //oFixVars := BackendVariable.addVars(statesToFix, oFixVars);
      for state in statesToFix loop
        lhs := Expression.crefToExp(state.varName);
        rhs := IndexReduction.makeStartExp(state.varName);
        initEqn := BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=DAE.emptyElementSource,attr=BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
        oEqns := ExpandableArray.add(initEqn,oEqns);
      end for;

      if Flags.isSet(Flags.BLT_DUMP) or Flags.isSet(Flags.INITIALIZATION) then
        print("StateSet " + intString(stateSet.index) + " is underconstraint for the initial system.\n");
        print("======================================\n");
        print("# States left to fix: " + intString(toFix) + ".\n");
        print("# Unfixed candidates: " + intString(listLength(stateSet.statescandidates)-toFix) + ".\n");
        BackendDump.dumpVarList(statesToFix, "Chosen states to fix:");
      end if;
    end if;
  end for;
end collectInitialStateSets;

protected function collectInitialVars "author: lochel
  This function collects all the vars for the initial system.
  TODO: return additional equations for pre-variables"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, array<Integer>, HashSet.HashSet, AvlSetCR.Tree, Boolean> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, array<Integer>, HashSet.HashSet, AvlSetCR.Tree, Boolean> outTpl;
algorithm
  (outVar, outTpl) := matchcontinue (inVar, inTpl)
    local
      BackendDAE.Var var, preVar, derVar, startVar;
      BackendDAE.Variables vars, fixvars;
      BackendDAE.EquationArray eqns;
      array<Integer> stateSetFixCounts;
      BackendDAE.Equation eqn;
      DAE.ComponentRef cr, preCR, derCR, startCR;
      Boolean isFixed, isInput, b, preUsed, datarecon;
      DAE.Type ty;
      DAE.InstDims arryDim;
      Option<DAE.Exp> startValue;
      DAE.Exp startValue_;
      DAE.Exp startExp, bindExp, crefExp, e;
      BackendDAE.VarKind varKind;
      HashSet.HashSet hs;
      String s, str, sv, stateSetIdxString;
      list<String> stateSetSplit;
      Integer stateSetIdx;
      SourceInfo info;
      AvlSetCR.Tree allPrimaryParameters;
      list<DAE.ComponentRef> parameters;

    // state
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(), varType=ty), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters,datarecon)) equation
      isFixed = BackendVariable.varFixed(var);
      //_ = BackendVariable.varStartValueOption(var);
      preUsed = BaseHashSet.has(cr, hs);

      crefExp = Expression.crefExp(cr);

      startCR = ComponentReference.crefPrefixStart(cr);
      startVar = BackendVariable.copyVarNewName(startCR, var);
      startVar = BackendVariable.setBindExp(startVar, NONE());
      startVar = BackendVariable.setVarDirection(startVar, DAE.BIDIR());
      startVar = BackendVariable.setVarFixed(startVar, false);
      startVar = BackendVariable.setVarKind(startVar, BackendDAE.VARIABLE());
      startVar = BackendVariable.setVarStartValueOption(startVar, NONE());

      startExp = BackendVariable.varStartValue(var);
      parameters = Expression.getAllCrefs(startExp);

      if not min(AvlSetCR.hasKey(allPrimaryParameters, p) for p in parameters) then
        eqn = BackendDAE.EQUATION(Expression.crefExp(startCR), startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
        eqns = BackendEquation.add(eqn, eqns);

        vars = BackendVariable.addVar(startVar, vars);
      end if;

      if isFixed then
        // Special case for initial state selection
        if Util.stringStartsWith("$STATESET",ComponentReference.crefFirstIdent(cr)) and Flags.getConfigBool(Flags.INITIAL_STATE_SELECTION) then
          stateSetSplit = Util.stringSplitAtChar(ComponentReference.crefFirstIdent(cr),".");
          stateSetIdxString::stateSetSplit = stateSetSplit;
          stateSetIdxString = substring(stateSetIdxString,10,stringLength(stateSetIdxString));
          stateSetIdx = stringInt(stateSetIdxString);
          arrayUpdate(stateSetFixCounts, stateSetIdx, arrayGet(stateSetFixCounts, stateSetIdx) + 1);
        else
          // if startExp is constant, generate "cref = $START.cref" otherwise "cref = startExp"
          if Expression.isConstValue(startExp) then
            eqn = BackendDAE.EQUATION(crefExp, Expression.crefExp(startCR), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
          else
            eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
          end if;
          eqns = BackendEquation.add(eqn, eqns);
        end if;
      end if;

      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());

      derCR = ComponentReference.crefPrefixDer(cr);  // cr => $DER.cr
      derVar = BackendVariable.copyVarNewName(derCR, var);
      derVar = BackendVariable.setVarDirection(derVar, DAE.BIDIR());
      derVar = BackendVariable.setBindExp(derVar, NONE());

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), DAE.CREF(preCR, ty), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = BackendVariable.addVar(derVar, vars);
      vars = BackendVariable.addVar(var, vars);
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed then BackendEquation.add(eqn, eqns) else eqns;
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // discrete (preUsed=true)
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      true = BaseHashSet.has(cr, hs);
      true = BackendVariable.varFixed(var);
      startValue_ = BackendVariable.varStartValue(var);

      var = BackendVariable.setVarFixed(var, false);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(startValue_));

      eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startValue_, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);

      vars = BackendVariable.addVar(var, vars);
      vars = BackendVariable.addVar(preVar, vars);
      eqns = BackendEquation.add(eqn, eqns);
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // discrete
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE()), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      preUsed = BaseHashSet.has(cr, hs);
      startValue = BackendVariable.varStartValueOption(var);

      var = BackendVariable.setVarFixed(var, false);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, false);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);

      vars = BackendVariable.addVar(var, vars);
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // parameter without binding and fixed=true
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=NONE()), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      true = BackendVariable.varFixed(var);
      startExp = BackendVariable.varStartValueType(var);

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(startExp);

      // e = Expression.crefExp(cr);
      // ty = Expression.typeof(e);
      // startExp = Expression.crefExp(ComponentReference.crefPrefixStart(cr));

      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, SOME(startExp));
      var = BackendVariable.setVarFixed(var, true);

      info = ElementSource.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s, str}, info);

      //vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // parameter with binding and fixed=false
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=ty), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      true = intGt(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 31);
      false = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, NONE());

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(bindExp);
      info = ElementSource.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNFIXED_PARAMETER_WITH_BINDING, {s, s, str}, info);

      eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), bindExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.add(eqn, eqns);

      vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // *** MODELICA 3.1 COMPATIBLE ***
    // parameter with binding and fixed=false and no start value
    // use the binding as start value
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      true = intLe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 31);
      false = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, NONE());
      NONE() = BackendVariable.varStartValueOption(var);
      var = BackendVariable.setVarStartValue(var, bindExp);

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(bindExp);
      info = ElementSource.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNFIXED_PARAMETER_WITH_BINDING_31, {s, s, str}, info);

      vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // *** MODELICA 3.1 COMPATIBLE ***
    // parameter with binding and fixed=false and a start value
    // ignore the binding and use the start value
    case (var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp)), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      true = intLe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 31);
      false = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var = BackendVariable.setBindExp(var, NONE());
      SOME(startExp) = BackendVariable.varStartValueOption(var);

      s = ComponentReference.printComponentRefStr(cr);
      str = ExpressionDump.printExpStr(bindExp);
      sv = ExpressionDump.printExpStr(startExp);
      info = ElementSource.getElementSourceFileInfo(BackendVariable.getVarSource(var));
      Error.addSourceMessage(Error.UNFIXED_PARAMETER_WITH_BINDING_AND_START_VALUE_31, {s, sv, s, str}, info);

      vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // secondary parameter
    case (var as BackendDAE.VAR(varKind=BackendDAE.PARAM()), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      //true = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // external objects
    case (var as BackendDAE.VAR(varKind=BackendDAE.EXTOBJ()), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      //var = BackendVariable.setVarFixed(var, false);
      //var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // skip constant
    case (var as BackendDAE.VAR(varKind=BackendDAE.CONST()), _) // equation
      // fixvars = BackendVariable.addVar(var, fixvars);
    then (var, inTpl);

    // VARIABLE (fixed=true)
    // DUMMY_STATE
    case (var as BackendDAE.VAR(varName=cr, varType=ty), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      true = BackendVariable.varFixed(var);
      // check if dataReconciliation is present and set the Input variables to true, as Qualified components are not handled as toplevel inputs
      if datarecon then
        isInput = checkComponentNames(var.varDirection, cr);
      else
        isInput = BackendVariable.isVarOnTopLevelAndInput(var);
      end if;
      preUsed = BaseHashSet.has(cr, hs);
      _ = Expression.crefExp(cr);

      startCR = ComponentReference.crefPrefixStart(cr);
      startVar = BackendVariable.copyVarNewName(startCR, var);
      startVar = BackendVariable.setBindExp(startVar, NONE());
      startVar = BackendVariable.setVarDirection(startVar, DAE.BIDIR());
      startVar = BackendVariable.setVarFixed(startVar, false);
      startVar = BackendVariable.setVarKind(startVar, BackendDAE.VARIABLE());
      startVar = BackendVariable.setVarStartValueOption(startVar, NONE());

      startExp = BackendVariable.varStartValue(var);
      parameters = Expression.getAllCrefs(startExp);

      if not min(AvlSetCR.hasKey(allPrimaryParameters, p) for p in parameters) then
        eqn = BackendDAE.EQUATION(Expression.crefExp(startCR), startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
        eqns = BackendEquation.add(eqn, eqns);

        vars = BackendVariable.addVar(startVar, vars);
      end if;

      var = BackendVariable.setVarFixed(var, false);

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      // if startExp is constant, generate "cref = $START.cref" otherwise "cref = startExp"
      if Expression.isConstValue(startExp) then
        eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), Expression.crefExp(startCR), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      else
        eqn = BackendDAE.EQUATION(DAE.CREF(cr, ty), startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      end if;

      vars = if not isInput then BackendVariable.addVar(var, vars) else vars;
      fixvars = if isInput then BackendVariable.addVar(var, fixvars) else fixvars;
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = BackendEquation.add(eqn, eqns);

      // Error.addCompilerNotification("VARIABLE (fixed=true): " + BackendDump.varString(var));
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    // VARIABLE (fixed=false)
    // DUMMY_STATE
    case (var as BackendDAE.VAR(varName=cr, varType=ty), (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon)) equation
      false = BackendVariable.varFixed(var);
      // check if dataReconciliation is present and set the Input variables to true, as Qualified components are not handled as toplevel inputs
      if datarecon then
        isInput = checkComponentNames(var.varDirection, cr);
      else
        isInput = BackendVariable.isVarOnTopLevelAndInput(var);
      end if;
      preUsed = BaseHashSet.has(cr, hs);
      _ = Expression.crefExp(cr);

      startCR = ComponentReference.crefPrefixStart(cr);
      startVar = BackendVariable.copyVarNewName(startCR, var);
      startVar = BackendVariable.setBindExp(startVar, NONE());
      startVar = BackendVariable.setVarDirection(startVar, DAE.BIDIR());
      startVar = BackendVariable.setVarFixed(startVar, false);
      startVar = BackendVariable.setVarKind(startVar, BackendDAE.VARIABLE());
      startVar = BackendVariable.setVarStartValueOption(startVar, NONE());

      startExp = BackendVariable.varStartValue(var);
      parameters = Expression.getAllCrefs(startExp);

      if not min(AvlSetCR.hasKey(allPrimaryParameters, p) for p in parameters) then
        eqn = BackendDAE.EQUATION(Expression.crefExp(startCR), startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
        eqns = BackendEquation.add(eqn, eqns);

        vars = BackendVariable.addVar(startVar, vars);
      end if;

      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendVariable.copyVarNewName(preCR, var);
      preVar = BackendVariable.setVarDirection(preVar, DAE.BIDIR());
      preVar = BackendVariable.setBindExp(preVar, NONE());
      preVar = BackendVariable.setVarFixed(preVar, true);
      preVar = BackendVariable.setVarStartValueOption(preVar, SOME(DAE.CREF(cr, ty)));

      // if startExp is constant, generate "cref = $START.cref" otherwise "cref = startExp"
      if Expression.isConstValue(startExp) then
        eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), DAE.CREF(cr, ty), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      else
        eqn = BackendDAE.EQUATION(DAE.CREF(preCR, ty), startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      end if;

      vars = if not isInput then BackendVariable.addVar(var, vars) else vars;
      fixvars = if isInput then BackendVariable.addVar(var, fixvars) else fixvars;
      vars = if preUsed then BackendVariable.addVar(preVar, vars) else vars;
      eqns = if preUsed then BackendEquation.add(eqn, eqns) else eqns;

      // Error.addCompilerNotification("VARIABLE (fixed=false); " + BackendDump.varString(var));
    then (var, (vars, fixvars, eqns, stateSetFixCounts, hs, allPrimaryParameters, datarecon));

    else equation
      Error.addInternalError("function collectInitialVars failed for: " + BackendDump.varString(inVar), sourceInfo());
    then fail();
  end matchcontinue;
end collectInitialVars;

protected function checkComponentNames "author: arun
  This is a special function which sets the inputs for dataReconciliation
  Inorder to handle Qualified component names as inputs."
  input DAE.VarDirection inVarDirection;
  input DAE.ComponentRef inComponentRef;
  output Boolean isTopLevel;
algorithm
  isTopLevel := match (inVarDirection, inComponentRef)
    case (DAE.INPUT(), DAE.CREF_IDENT()) then true;
    case (DAE.INPUT(), DAE.CREF_QUAL()) then true;
    case (_ , _) then false;
  end match;
end checkComponentNames;

protected function collectInitialClockedVarsEqns "author: rfranke
  This function creates initial equations for a clocked partition.
  Previous states are initialized with the states. All other variables are initialized with start values."
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables, BackendDAE.EquationArray> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables, BackendDAE.EquationArray> outTpl;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
algorithm
  (vars, eqns) := inTpl;
  (outVar, outTpl) := match inVar
    local
      BackendDAE.Var var;
      BackendDAE.VarKind kind;
      DAE.ComponentRef cr;
      DAE.Type ty;
      DAE.Exp crExp, startExp;
    case (var as BackendDAE.VAR(varName=cr, varType=ty, varKind=kind)) equation
      crExp = Expression.crefExp(cr);
      // create previous variable and initial equation for discrete states
      (vars, eqns) = match kind
        local
          BackendDAE.Var previousVar;
          DAE.ComponentRef previousCR;
          DAE.Exp previousExp;
        case BackendDAE.CLOCKED_STATE(previousName=previousCR) equation
          previousVar = BackendVariable.copyVarNewName(previousCR, var);
          previousVar = BackendVariable.setVarKind(previousVar, BackendDAE.VARIABLE());
          previousVar = BackendVariable.setVarDirection(previousVar, DAE.BIDIR());
          previousVar = BackendVariable.setBindExp(previousVar, NONE());
          previousVar = BackendVariable.setVarFixed(previousVar, true);
          previousVar = BackendVariable.setVarStartValueOption(previousVar, SOME(DAE.CREF(cr, ty)));

          // HACK hide previous(v) in results because it's not calculated right
          previousVar = BackendVariable.setHideResult(previousVar, SOME(DAE.BCONST(true)));

          previousExp = Expression.crefExp(previousCR);
          vars = BackendVariable.addVar(previousVar, vars);
          eqns = BackendEquation.add(BackendDAE.EQUATION(previousExp, crExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL), eqns);
          then (vars, eqns);
        else (vars, eqns);
      end match;
      // add clocked variable and initial equation
      startExp = BackendVariable.varStartValue(var);
      vars = BackendVariable.addVar(var, vars);
      eqns = BackendEquation.add(BackendDAE.EQUATION(crExp, startExp, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL), eqns);
    then (var, (vars, eqns));
  end match;
end collectInitialClockedVarsEqns;

protected function collectInitialEqns "author: lochel"
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.EquationArray, BackendDAE.EquationArray> inTpl;
  output BackendDAE.Equation outEq = inEq;
  output tuple<BackendDAE.EquationArray, BackendDAE.EquationArray> outTpl;
protected
  HashSet.HashSet previousHS;
  BackendDAE.Equation eqn1;
  BackendDAE.EquationArray eqns, reeqns;
  Integer size;
  Boolean b;
algorithm
  (eqns, reeqns) := inTpl;

  // replace der(x) with $DER.x and replace pre(x) with $PRE.x
  (eqn1, _) := BackendEquation.traverseExpsOfEquation(inEq, Expression.traverseSubexpressionsDummyHelper, replaceDerPreCref);

  // add it, if size is zero (terminate, assert, noretcall) move to removed equations
  size := BackendEquation.equationSize(eqn1);
  b := intGt(size, 0);

  eqns := if b then BackendEquation.add(eqn1, eqns) else eqns;
  reeqns := if not b then BackendEquation.add(eqn1, reeqns) else reeqns;
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

    case DAE.CALL(path = Absyn.IDENT(name="der"), expLst = {DAE.CREF(componentRef=cr)}, attr=DAE.CALL_ATTR(ty=ty)) equation
      dummyder = ComponentReference.crefPrefixDer(cr);
    then DAE.CREF(dummyder, ty);

    case DAE.CALL(path = Absyn.IDENT(name="pre"), expLst = {DAE.CREF(componentRef=cr)}, attr=DAE.CALL_ATTR(ty=ty)) equation
      dummyder = ComponentReference.crefPrefixPre(cr);
    then DAE.CREF(dummyder, ty);

    case DAE.CALL(path = Absyn.IDENT(name="previous"), expLst = {DAE.CREF(componentRef=cr)}, attr=DAE.CALL_ATTR(ty=ty)) equation
      dummyder = ComponentReference.crefPrefixPrevious(cr);
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
  (outVar, outTpl) := match (inVar, inTpl)
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

    // external object with binding
    case (var as BackendDAE.VAR(varName=cr, bindExp=SOME(bindExp), varKind=BackendDAE.EXTOBJ(), source=source), (eqns, reeqns)) equation
      eqn = BackendDAE.SOLVED_EQUATION(cr, bindExp, source, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.add(eqn, eqns);
    then (var, (eqns, reeqns));

    // binding
    case (var as BackendDAE.VAR(varName=cr, bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns)) equation
      crefExp = DAE.CREF(cr, ty);
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqns = BackendEquation.add(eqn, eqns);
    then (var, (eqns, reeqns));

    else equation
      Error.addInternalError("function collectInitialBindings failed for: " + BackendDump.varString(inVar), sourceInfo());
    then fail();
  end match;
end collectInitialBindings;


// =============================================================================
// section for post-optimization module "removeInitializationStuff"
//
// =============================================================================

public function removeInitializationStuff
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  list<BackendDAE.Equation> removedEqsList = {};
  BackendDAE.Shared shared = inDAE.shared;
algorithm
  for eqs in outDAE.eqs loop
    _ := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs.orderedEqs, removeInitializationStuff1, false);
    _ := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs.removedEqs, removeInitializationStuff1, false);
  end for;

  _ := BackendDAEUtil.traverseBackendDAEExpsEqns(shared.removedEqs, removeInitializationStuff1, false);
  for eq in BackendEquation.equationList(shared.removedEqs) loop
    removedEqsList := match BackendEquation.equationKind(eq)
      case BackendDAE.INITIAL_EQUATION() then removedEqsList;
      else filterWhenEquation(eq, removedEqsList);
    end match;
  end for;
  shared.removedEqs := BackendEquation.listEquation(listReverse(removedEqsList));
  shared.initialEqs := BackendEquation.emptyEqns();
  outDAE.shared := shared;
end removeInitializationStuff;

protected function filterWhenEquation
  input BackendDAE.Equation inEqn;
  input list<BackendDAE.Equation> inEqnLst;
  output list<BackendDAE.Equation> outEqnLst;
protected
  DAE.Exp condition;
algorithm
  outEqnLst := match (inEqn)
    case BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_STMTS(condition=condition, elsewhenPart=NONE())) guard listEmpty(BackendDAEUtil.getConditionList(condition)) then inEqnLst;
    else inEqn::inEqnLst;
  end match;
end filterWhenEquation;

protected function removeInitializationStuff1
  input DAE.Exp inExp;
  input Boolean inUseHomotopy;
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp, outUseHomotopy) := Expression.traverseExpBottomUp(inExp, removeInitializationStuff2, inUseHomotopy);
end removeInitializationStuff1;

protected function removeInitializationStuff2
  input DAE.Exp inExp;
  input Boolean inUseHomotopy;
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp, outUseHomotopy) := match (inExp, inUseHomotopy)
    local
      DAE.Exp e1, e2, e3, actual, simplified;

    // replace initial() with false
    case (DAE.CALL(path=Absyn.IDENT(name="initial")), _)
    then (DAE.BCONST(false), inUseHomotopy);

    // replace homotopy(actual, simplified) with actual
    case (DAE.CALL(path=Absyn.IDENT(name="homotopy"), expLst=actual::_::_), _)
    then (actual, true);

    else (inExp, inUseHomotopy);
  end match;
end removeInitializationStuff2;


// =============================================================================
// section for post-optimization module "replaceHomotopyWithSimplified"
//
// =============================================================================

public function replaceHomotopyWithSimplified
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
algorithm
  for eqs in outDAE.eqs loop
    _ := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs.orderedEqs, replaceHomotopyWithSimplified1, false);
    _ := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs.removedEqs, replaceHomotopyWithSimplified1, false);
  end for;
  outDAE.eqs := list(BackendDAEUtil.clearEqSyst(eqs) for eqs in outDAE.eqs);
end replaceHomotopyWithSimplified;

protected function replaceHomotopyWithSimplified1
  input DAE.Exp inExp;
  input Boolean inUseHomotopy;
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp, outUseHomotopy) := Expression.traverseExpBottomUp(inExp, replaceHomotopyWithSimplified2, inUseHomotopy);
end replaceHomotopyWithSimplified1;

protected function replaceHomotopyWithSimplified2
  input DAE.Exp inExp;
  input Boolean inUseHomotopy;
  output DAE.Exp outExp;
  output Boolean outUseHomotopy;
algorithm
  (outExp, outUseHomotopy) := match inExp
    local
      DAE.Exp simplified;

    // replace homotopy(actual, simplified) with simplified
    case DAE.CALL(path=Absyn.IDENT(name="homotopy"), expLst=_::simplified::_)
    then (simplified, true);

    else (inExp, inUseHomotopy);
  end match;
end replaceHomotopyWithSimplified2;

annotation(__OpenModelica_Interface="backend");
end Initialization;
