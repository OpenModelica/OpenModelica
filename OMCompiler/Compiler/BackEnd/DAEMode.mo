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

encapsulated package DAEMode
" file:        DAEMode.mo
  package:     DAEMode
  description: This module prepares BackendDAE equations to solve
               to pass them directly to a DAE solver.

               Therefor all equations are transformed to residual form:
               residualVar = eqRHS - eqLHS

"
public

import BackendDAE;

protected

import Absyn;
import Array;
import BackendDAEOptimize;
import BackendDAEUtil;
import BackendDAEFunc;
import BackendDump;
import BackendEquation;
import BackendVariable;
import CheckModel;
import CommonSubExpression;
import ComponentReference;
import Config;
import DAE;
import ErrorExt;
import ExecStat.execStat;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import ExpressionSolve;
import Flags;
import Global;
import Initialization;
import List;
import Matching;
import StackOverflow;
import Util;

public function getEqSystemDAEmode "Run the equation system pipeline."
  input BackendDAE.BackendDAE inDAE;
  input String fileNamePrefix;
  input Option<list<String>> strPreOptModules = NONE();
  input Option<String> strmatchingAlgorithm = NONE();
  input Option<String> strdaeHandler = NONE();
  input Option<list<String>> strPostOptModules = NONE();
  output BackendDAE.BackendDAE outDAEmode;
  output BackendDAE.BackendDAE outInitDAE;
  output list<BackendDAE.Equation> outRemovedInitialEquationLst;
 protected
  BackendDAE.BackendDAE dae, simDAE;
  list<tuple<BackendDAEFunc.optimizationModule, String>> preOptModules;
  list<tuple<BackendDAEFunc.optimizationModule, String>> postOptModules;
  tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEFunc.matchingAlgorithmFunc, String> matchingAlgorithm;
  BackendDAE.Variables globalKnownVars;
  Integer numCheckpoints;
  BackendDAE.EqSystem eqSyst;
algorithm
  numCheckpoints:=ErrorExt.getNumCheckpoints();
  try
    StackOverflow.clearStacktraceMessages();
    preOptModules := BackendDAEUtil.getPreOptModules(strPreOptModules);
    postOptModules := BackendDAEUtil.getPostOptModules(match strPostOptModules case (NONE()) then SOME(getPostOptModulesDAEString()); else strPostOptModules; end match);
    matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(strmatchingAlgorithm);
    Flags.setConfigString(Flags.INDEX_REDUCTION_METHOD, "dummyDerivatives");
    daeHandler := BackendDAEUtil.getIndexReductionMethod(strdaeHandler);

    if Flags.isSet(Flags.DUMP_DAE_LOW) then
      BackendDump.dumpBackendDAE(inDAE, "dumpdaelow");
      if Flags.isSet(Flags.ADDITIONAL_GRAPHVIZ_DUMP) then
        BackendDump.graphvizIncidenceMatrix(inDAE, "dumpdaelow");
      end if;
    end if;

    // pre-optimization phase
    dae := BackendDAEUtil.preOptimizeDAE(inDAE, preOptModules);

    execStat("pre-optimization done (n="+String(BackendDAEUtil.daeSize(dae))+")");
    // transformation phase (matching and sorting using index reduction method)
    dae := BackendDAEUtil.causalizeDAE(dae, NONE(), matchingAlgorithm, daeHandler, true);
    execStat("matching and sorting (n="+String(BackendDAEUtil.daeSize(dae))+")");

    if Flags.isSet(Flags.GRAPHML) then
      BackendDump.dumpBipartiteGraphDAE(dae, fileNamePrefix);
    end if;

    if Flags.isSet(Flags.BLT_DUMP) then
      BackendDump.bltdump("bltdump", dae);
    end if;

    // generate system for initialization
    (outInitDAE, _, outRemovedInitialEquationLst, globalKnownVars) := Initialization.solveInitialSystem(dae);

    // use function tree from initDAE further for simDAE
    simDAE := BackendDAEUtil.setFunctionTree(dae, BackendDAEUtil.getFunctions(outInitDAE.shared));

    // Set updated globalKnownVars
    simDAE := BackendDAEUtil.setDAEGlobalKnownVars(simDAE, globalKnownVars);
    simDAE := BackendDAEOptimize.addInitialStmtsToAlgorithms(simDAE, false);
    simDAE := Initialization.removeInitializationStuff(simDAE);

    // post-optimization phase
    // use preOpt instead
    simDAE := BackendDAEUtil.postOptimizeDAE(simDAE, postOptModules, matchingAlgorithm, daeHandler);

    // sort the globalKnownVars
    simDAE := BackendDAEUtil.sortGlobalKnownVarsInDAE(simDAE);

    // debug dump
    if Flags.isSet(Flags.DUMP_INDX_DAE) then
      BackendDump.dumpBackendDAE(simDAE, "dumpindxdae");
    end if;

    outDAEmode := simDAE;
    return;
  else
    setGlobalRoot(Global.stackoverFlowIndex, NONE());
    ErrorExt.rollbackNumCheckpoints(ErrorExt.getNumCheckpoints()-numCheckpoints);
    Error.addInternalError("Stack overflow in "+getInstanceName()+"...\n"+stringDelimitList(StackOverflow.readableStacktraceMessages(), "\n"), sourceInfo());
    /* Do not fail or we can loop too much */
    StackOverflow.clearStacktraceMessages();
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
  fail();
end getEqSystemDAEmode;

/*
get config function
*/
protected function getPostOptModulesDAEString
  output list<String> strpostOptModules;
algorithm
  strpostOptModules := Config.getPostOptModulesDAE();
end getPostOptModulesDAEString;


// =============================================================================
// public section for createDAEmodeBDAE
//
// =============================================================================
public

function createDAEmodeBDAE
" This modules creates a BDAE with residual Variables."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, createDAEmodeEqSystem);
end createDAEmodeBDAE;


// =============================================================================
// protected section for createDAEmodeBDAE
//
// =============================================================================
protected

uniontype TraverseEqnAryFold
  record TRAVERSER_CREATE_DAE
    BackendDAE.BackendDAEModeData globalDAEData;
    BackendDAE.Variables newDAEVars;
    BackendDAE.EquationArray newDAEEquations;
    BackendDAE.Variables systemVars;
    DAE.FunctionTree functionTree;
    Boolean recursiveStrongComponentRun;
    BackendDAE.Shared shared;
  end TRAVERSER_CREATE_DAE;
end TraverseEqnAryFold;

function createDAEmodeEqSystem
"The main to create equations by adding auxiliary variables
 and auxiliary equations  of the form $auxExp = rhs, $resVar = $auxExp - lhs"
  input output BackendDAE.EqSystem syst;
  input output BackendDAE.Shared shared;
protected
  TraverseEqnAryFold travArgs;
  BackendDAE.BackendDAEModeData globalDAEData;
  BackendDAE.EquationArray tmp;
  BackendDAE.Variables vars;
  BackendDAE.EqSystem retSystem;
  BackendDAE.Variables newDAEVars;
  BackendDAE.EquationArray newDAEEquations;
  list<BackendDAE.Equation> resEqns;
  Integer systemSize;
  Boolean debug = Flags.isSet(Flags.DEBUG_DAEMODE);
  constant Boolean exec = false;
algorithm
  globalDAEData := shared.daeModeData;
  systemSize := BackendDAEUtil.systemSize(syst);
  newDAEVars := BackendVariable.emptyVars();
  newDAEEquations := BackendEquation.emptyEqnsSized(systemSize);
  travArgs := TRAVERSER_CREATE_DAE(globalDAEData, newDAEVars, newDAEEquations, syst.orderedVars, shared.functionTree, false, shared);
  if debug then BackendDump.printEqSystem(syst); end if;
  // for every equation create corresponding residiual variable(s)
  travArgs := BackendDAEUtil.traverseEqSystemStrongComponents(syst, traverserStrongComponents, travArgs);
  if exec then execStat("DAEmode: created residual equations for system size :  " + intString(BackendDAEUtil.systemSize(syst)) + ": " );  end if;
  globalDAEData := travArgs.globalDAEData;

  // add systemVars to modelVars
  if isSome(globalDAEData.modelVars) then
    globalDAEData.modelVars := SOME(BackendVariable.addVariables(travArgs.systemVars, Util.getOption(globalDAEData.modelVars)));
  else
    globalDAEData.modelVars := SOME(travArgs.systemVars);
  end if;
  if exec then execStat("DAEmode: adding residual variables:  " + intString(BackendVariable.varsSize(Util.getOption(globalDAEData.modelVars))) + ": " );  end if;

  // create residual system
  retSystem := BackendDAEUtil.createEqSystem(travArgs.newDAEVars);
  retSystem := BackendDAEUtil.setEqSystEqs(retSystem, travArgs.newDAEEquations);
  retSystem := BackendDAEUtil.setEqSystRemovedEqns(retSystem, syst.removedEqs);

  if exec then execStat("DAEmode: created system:  " + intString(BackendDAEUtil.systemSize(retSystem)) + ": " );  end if;

  syst := retSystem;
  shared.daeModeData := globalDAEData;
  if debug then BackendDump.printEqSystem(syst); end if;
  if debug then BackendDump.dumpBackendDAEModeData(globalDAEData); end if;

end createDAEmodeEqSystem;

function traverserStrongComponents
"This function prepares an equation system for
 the dae mode by dividing the equations into
 aux equations and residual equations.
 "
  input list<BackendDAE.Equation> inEqns;
  input list<BackendDAE.Var> inVars;
  input list<Integer> varIdxs;
  input list<Integer> eqnIdxs;
  input output TraverseEqnAryFold traverserArgs;
protected
  list<BackendDAE.Var> vars = inVars;
  list<DAE.ComponentRef> varCrefLst;
  Boolean recursiveStrongComponentRun;
  Boolean isStateVarInvoled;
algorithm
  varCrefLst := list(v.varName for v in inVars);
  isStateVarInvoled := Util.boolOrList(list(BackendVariable.isStateVar(v) for v in inVars));
  (traverserArgs) :=
  matchcontinue(inEqns, traverserArgs.recursiveStrongComponentRun, isStateVarInvoled)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.IncidenceMatrix adjMatrix;

      list<BackendDAE.Equation> newResEqns;
      list<BackendDAE.Var> newResVars, newAuxVars, discVars, contVars;
      BackendDAE.Var var;
      BackendDAE.Variables systemVars;
      BackendDAE.Var dummyVar;
      BackendDAE.Equation eq, new_eq, aux_eq;
      Integer size, newnumResVars;
      DAE.Exp exp, exp2;
      BackendDAE.BackendDAEModeData globalDAEData;
      DAE.ComponentRef cref, newCref;
      DAE.FunctionTree funcsTree;
      list<DAE.ComponentRef> crlst;
      Boolean b1, b2;
      list<BackendDAE.Equation> discEqns;
      list<BackendDAE.Equation> contEqns;

      DAE.Algorithm alg;
      DAE.ElementSource source;
      DAE.Expand crefExpand;

      constant Boolean debug = false;

    case ({eq}, false, false)
      guard(Util.boolAndList(list(BackendVariable.isCSEVar(v) for v in vars)))
      equation
        newResVars = list(BackendVariable.setVarKind(v, BackendDAE.DAE_AUX_VAR()) for v in vars);
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(newResVars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList({new_eq}, traverserArgs.newDAEEquations);
        traverserArgs.systemVars = BackendVariable.removeCrefs(varCrefLst, traverserArgs.systemVars);
        if debug then print("[DAEmode] Added solved aux vars. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.EQUATION()}, false, false)
      equation
        {var} = vars;
        eq.exp = ExpressionSolve.solve(eq.exp, eq.scalar, Expression.crefExp(var.varName));
        new_eq = BackendDAE.SOLVED_EQUATION(var.varName, eq.exp, eq.source, eq.attr);
        new_eq = BackendEquation.setEquationAttributes(new_eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(vars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList({new_eq}, traverserArgs.newDAEEquations);
        if debug then print("[DAEmode] Create solved equation. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.COMPLEX_EQUATION()}, false, false)
      equation
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(vars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList({new_eq}, traverserArgs.newDAEEquations);
        if debug then print("[DAEmode] Create solved complex equation. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.ARRAY_EQUATION()}, false, false)
      equation
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(vars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList({new_eq}, traverserArgs.newDAEEquations);
        if debug then print("[DAEmode] Create solved array equations. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.WHEN_EQUATION()}, false, _)
      equation
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_DISCRETE);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(vars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList({new_eq}, traverserArgs.newDAEEquations);
        if debug then print("[DAEmode] Create solved when equation. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.ALGORITHM(alg=alg, source=source, expand=crefExpand)}, false, false)
      equation
        // check that all vars
        true = CheckModel.isCrefListAlgorithmOutput(varCrefLst, alg, source, crefExpand);
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(vars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList({new_eq}, traverserArgs.newDAEEquations);
        if debug then print("[DAEmode] Create solved algorithms. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    // a = f(...) and a is an array
    case ({eq as BackendDAE.ARRAY_EQUATION(left=exp)}, b1, b2)
      guard ( Expression.isCref(exp) and (b1 or b2))
      equation
        globalDAEData = traverserArgs.globalDAEData;

        cref = Expression.expCref(exp);

        // create aux variables for recordCref
        newAuxVars = BackendVariable.getVar(cref, traverserArgs.systemVars);
        crlst = ComponentReference.expandCref(cref, true);
        newAuxVars = list(BackendVariable.copyVarNewName(ComponentReference.crefPrefixAux(cr), v) threaded for cr in crlst, v in newAuxVars);
        newAuxVars = list(BackendVariable.setVarKind(v, BackendDAE.DAE_AUX_VAR()) for v in newAuxVars);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(newAuxVars, traverserArgs.newDAEVars);

        // create aux equation aux = f(...)
        newCref = ComponentReference.crefPrefixAux(cref);
        eq.left = Expression.crefExp(newCref);
        aux_eq = eq;

        aux_eq = BackendEquation.setEquationAttributes(aux_eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.newDAEEquations = BackendEquation.addList({aux_eq}, traverserArgs.newDAEEquations);

        // prepare res equation aux = recordCref
        globalDAEData = traverserArgs.globalDAEData;
        eq.right = Expression.crefToExp(cref);
        newResEqns = BackendEquation.equationToScalarResidualForm(eq, traverserArgs.functionTree);
        //if debug then print("case: new eqns:\n" + BackendDump.dumpEqnsStr(newResEqns) + "\n"); end if;
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, globalDAEData.numResVars);
        globalDAEData.numResVars = newnumResVars;
        newResEqns = list(BackendEquation.setEquationAttributes(e, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC) for e in newResEqns);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(newResVars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList(newResEqns, traverserArgs.newDAEEquations);
        globalDAEData = addVarsGlobalData(globalDAEData, vars);

        traverserArgs.globalDAEData = globalDAEData;
        if debug then print("[DAEmode] Added residual array equation\n" +
                      BackendDump.varListString(newResVars, "") + "states:\n" +
                      BackendDump.varListString(vars, "") + "eqs:\n" +
                      BackendDump.equationListString(newResEqns, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq}, b1, b2)
      guard ( b1 or b2)
      equation
        globalDAEData = traverserArgs.globalDAEData;
        newResEqns = BackendEquation.equationToScalarResidualForm(eq, traverserArgs.functionTree);
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, globalDAEData.numResVars);
        globalDAEData.numResVars = newnumResVars;
        newResEqns = list(BackendEquation.setEquationAttributes(e, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC) for e in newResEqns);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(newResVars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList(newResEqns, traverserArgs.newDAEEquations);
        globalDAEData = addVarsGlobalData(globalDAEData, vars);
        traverserArgs.globalDAEData = globalDAEData;
        if debug then print("[DAEmode] Added strong component or state eqns\n" +
                      BackendDump.varListString(newResVars, "") + "states:\n" +
                      BackendDump.varListString(vars, "") + "eqs:\n" +
                      BackendDump.equationListString(newResEqns, "") + "\n"); end if;
      then
        (traverserArgs);

    // recordCref = f(...)
    case ({eq as BackendDAE.COMPLEX_EQUATION(left=exp)}, _, _)
      guard(Expression.isCref(exp))
      //guard( Util.boolAndList(list( Expression.isRecordType(ComponentReference.crefTypeFull(v.varName)) for v in vars)) )
      equation
        if debug then print("case: Complex: " + BackendDump.equationListString(inEqns, "") + "\n"); end if;
        /*
        if debug then print("case: left:  " + ExpressionDump.dumpExpStr(exp ,0) + "\n"); end if;
        if debug then print("case: right: " + ExpressionDump.dumpExpStr(exp2,0) + "\n"); end if;
        */
        cref = Expression.expCref(exp);

        // create aux variables for recordCref
        newAuxVars = list(BackendVariable.copyVarNewName(ComponentReference.crefPrefixAux(cr), v) threaded for cr in varCrefLst, v in vars);
        newAuxVars = list(BackendVariable.setVarKind(v, BackendDAE.DAE_AUX_VAR()) for v in newAuxVars);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(newAuxVars, traverserArgs.newDAEVars);

        // create aux equation aux = f(...)
        newCref = ComponentReference.crefPrefixAux(cref);
        eq.left = Expression.crefToExp(newCref);
        aux_eq = eq;

        aux_eq = BackendEquation.setEquationAttributes(aux_eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.newDAEEquations = BackendEquation.addList({aux_eq}, traverserArgs.newDAEEquations);

        // prepare res equation aux = recordCref
        globalDAEData = traverserArgs.globalDAEData;
        eq.right = Expression.crefToExp(cref);
        newResEqns = BackendEquation.equationToScalarResidualForm(eq, traverserArgs.functionTree);
        //if debug then print("case: new eqns:\n" + BackendDump.dumpEqnsStr(newResEqns) + "\n"); end if;
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, globalDAEData.numResVars);
        globalDAEData.numResVars = newnumResVars;
        newResEqns = list(BackendEquation.setEquationAttributes(e, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC) for e in newResEqns);
        traverserArgs.newDAEVars = BackendVariable.addNewVars(newResVars, traverserArgs.newDAEVars);
        traverserArgs.newDAEEquations = BackendEquation.addList(newResEqns, traverserArgs.newDAEEquations);
        globalDAEData = addVarsGlobalData(globalDAEData, vars);
        traverserArgs.globalDAEData = globalDAEData;
        if debug then print("[DAEmode] Added complex residual equation with aux variables. Res-vars:\n" +
                      BackendDump.varListString(newResVars, "") + "eqs:\n" +
                      BackendDump.equationListString(newResEqns, "") + "aux vars:\n" +
                      BackendDump.varListString(newAuxVars, "") + "aux eq:\n" +
                      BackendDump.equationListString({aux_eq}, "") + "\n");
                      end if;
      then
        (traverserArgs);

    case(_, false, _)
      algorithm

        (discVars, contVars) := List.splitOnTrue(inVars, BackendVariable.isVarDiscrete);
        (newAuxVars, contVars) := List.splitOnTrue(contVars, BackendVariable.BackendVariable.isCSEVar);
        discVars := listAppend(newAuxVars,discVars);
        (discEqns, contEqns) := getDiscAndContEqns(inVars, inEqns, discVars, contVars, traverserArgs.shared.functionTree);

        // create discrete
        for e in discEqns loop
          size := BackendEquation.equationSize(e);
          newAuxVars := List.firstN(discVars, size);
          traverserArgs := traverserStrongComponents({e}, newAuxVars, {}, {}, traverserArgs);
          discVars := List.stripN(discVars, size);
        end for;

        // create continuous
        for e in contEqns loop
          size := BackendEquation.equationSize(e);
          newAuxVars := List.firstN(contVars, size);
          traverserArgs.recursiveStrongComponentRun := true;
          traverserArgs := traverserStrongComponents({e}, newAuxVars, {}, {}, traverserArgs);
          traverserArgs.recursiveStrongComponentRun := false;
          contVars := List.stripN(contVars, size);
        end for;
      then
        (traverserArgs);


    else equation
      Error.addInternalError("DAEMode.traverserStrongComponents failed on equation:\n" +
                              BackendDump.equationListString(inEqns, "") + "\nVariables:\n" +
                              BackendDump.varListString(inVars, "") + "\n", sourceInfo());
    then fail();

  end matchcontinue;
end traverserStrongComponents;

function getDiscAndContEqns
  input list<BackendDAE.Var> inAllVars;
  input list<BackendDAE.Equation> inAllEqns;
  input list<BackendDAE.Var> inDiscVars;
  input list<BackendDAE.Var> inContVars;
  input DAE.FunctionTree functionTree;
  output list<BackendDAE.Equation> discEqns;
  output list<BackendDAE.Equation> contEqns;
protected
  BackendDAE.EqSystem syst;
  BackendDAE.IncidenceMatrix adjMatrix;

  list<Integer> varsIndex, eqnIndex;
  array<Integer> assignVarEqn "eqn := assignVarEqn[var]";
  array<Integer> assignEqnVar "var := assignEqnVar[eqn]";

  array<Integer> mapEqnScalarArray;
  constant Boolean debug = false;
algorithm
  try
    // create syst for a matching
    syst := BackendDAEUtil.createEqSystem(BackendVariable.listVar1(inAllVars), BackendEquation.listEquation(inAllEqns) );
    if debug then BackendDump.printEqSystem(syst); end if;
    (adjMatrix, _, _, mapEqnScalarArray) := BackendDAEUtil.incidenceMatrixScalar(syst, BackendDAE.NORMAL(), SOME(functionTree));
    if debug then BackendDump.dumpIncidenceMatrix(adjMatrix); end if;
    (assignVarEqn, assignEqnVar, true) := Matching.RegularMatching(adjMatrix, BackendDAEUtil.systemSize(syst), BackendDAEUtil.systemSize(syst));
    if debug then BackendDump.dumpMatching(assignVarEqn); end if;

    // get discrete vars indexes and then the equations
    varsIndex := BackendVariable.getVarIndexFromVars(inDiscVars, syst.orderedVars);
    if debug then print("discVarsIndex: "); BackendDump.dumpIncidenceRow(varsIndex);  end if;
    eqnIndex := List.map1(varsIndex, Array.getIndexFirst, assignVarEqn);
    if debug then print("discEqnIndex: "); BackendDump.dumpIncidenceRow(eqnIndex);  end if;
    eqnIndex := List.unique(list(mapEqnScalarArray[i] for i in eqnIndex));
    discEqns := BackendEquation.getList(eqnIndex, syst.orderedEqs);
    if debug then BackendDump.equationListString(discEqns, "Discrete Equations");  end if;

    // get continuous equations
    varsIndex := BackendVariable.getVarIndexFromVars(inContVars, syst.orderedVars);
    eqnIndex := List.map1(varsIndex, Array.getIndexFirst, assignVarEqn);
    eqnIndex := List.unique(list(mapEqnScalarArray[i] for i in eqnIndex));
    if debug then print("contEqnIndex: "); BackendDump.dumpIncidenceRow(eqnIndex);  end if;
    contEqns := BackendEquation.getList(eqnIndex, syst.orderedEqs);
    if debug then BackendDump.equationListString(contEqns, "Continuous Equations");  end if;
  else
    fail();
  end try;
end getDiscAndContEqns;

function addVarsGlobalData
  input output BackendDAE.BackendDAEModeData globalDAEData;
  input list<BackendDAE.Var> inVars;
protected
  list<BackendDAE.Var> vars;
algorithm
  // prepare algebraic states
  vars := List.filterOnTrue(inVars, BackendVariable.isNonStateVar);
  vars := list(BackendVariable.setVarKind(v, BackendDAE.ALG_STATE()) for v in vars);
  //print("Alg vars: " + BackendDump.varListString(vars, "") + "\n");
  globalDAEData.algStateVars := listAppend(vars, globalDAEData.algStateVars);
  globalDAEData.stateVars := listAppend(List.filterOnTrue(inVars, BackendVariable.isStateVar), globalDAEData.stateVars);
end addVarsGlobalData;

function setNonStateVarAlgState
  input output list<BackendDAE.Var> varList;
protected
  list<BackendDAE.Var> tmpVarList = {};
algorithm
  for v in varList loop
    v := match (v)
      local
      case (BackendDAE.VAR(varKind=BackendDAE.STATE())) then v;
      case (BackendDAE.VAR(varKind=BackendDAE.VARIABLE()))
        equation
          v = BackendVariable.setVarKind(v, BackendDAE.ALG_STATE());
        then v;
      else fail();
    end match;
  end for;
  varList := listReverse(varList);
end setNonStateVarAlgState;

annotation(__OpenModelica_Interface="backend");
end DAEMode;
