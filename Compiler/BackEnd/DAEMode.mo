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
    list<BackendDAE.Var> auxVars;
    list<BackendDAE.Equation> auxEqns;
    list<BackendDAE.Var> resVars;
    list<BackendDAE.Equation> resEqns;
    BackendDAE.Variables systemVars;
    DAE.FunctionTree functionTree;
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
  list<BackendDAE.Equation> resEqns;
  Boolean debug = Flags.isSet(Flags.DEBUG_DAEMODE);
algorithm
  globalDAEData := shared.daeModeData;
  travArgs := TRAVERSER_CREATE_DAE(globalDAEData, {}, {}, {}, {}, syst.orderedVars, shared.functionTree);
  if debug then BackendDump.printEqSystem(syst); end if;
  // for every equation create corresponding residiual variable(s)
  travArgs := BackendDAEUtil.traverseEqSystemStrongComponents(syst,
      traverserStrongComponents, travArgs);

  globalDAEData := travArgs.globalDAEData;

  // add systemVars to modelVars
  if isSome(globalDAEData.modelVars) then
    globalDAEData.modelVars := SOME(BackendVariable.addVariables(Util.getOption(globalDAEData.modelVars), travArgs.systemVars));
  else
    globalDAEData.modelVars := SOME(travArgs.systemVars);
  end if;

  // create residual system
  retSystem := BackendDAEUtil.createEqSystem(BackendVariable.listVar(listAppend(travArgs.auxVars, travArgs.resVars)));

  resEqns := listReverse(travArgs.resEqns);
  resEqns := listAppend(listReverse(travArgs.auxEqns), resEqns);
  retSystem := BackendDAEUtil.setEqSystEqs(retSystem, BackendEquation.listEquation(resEqns));

  retSystem := BackendDAEUtil.setEqSystStateSets(retSystem, syst.stateSets);
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
algorithm
  (traverserArgs) :=
  matchcontinue(inEqns, inVars)
    local
      list<BackendDAE.Equation> newResEqns;
      list<BackendDAE.Var> newResVars, newAuxVars, vars;
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

      DAE.Algorithm alg;
      DAE.ElementSource source;
      DAE.Expand crefExpand;

      constant Boolean debug = false;

    case ({eq}, vars)
      guard(Util.boolAndList(list(CommonSubExpression.isCSECref(v.varName) for v in vars)) and not listEmpty(varIdxs))
      equation
        newResVars = list(BackendVariable.setVarKind(v, BackendDAE.DAE_AUX_VAR()) for v in vars);
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.auxVars = listAppend(newResVars, traverserArgs.auxVars);
        traverserArgs.auxEqns = listAppend({new_eq}, traverserArgs.auxEqns);
        crlst = list(v.varName for v in vars);
        traverserArgs.systemVars = BackendVariable.removeCrefs(crlst, traverserArgs.systemVars);
        if debug then print("[DAEmode] Added solved aux vars. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.EQUATION()}, {var})
      guard (not listEmpty(varIdxs) and // not inside of EQNS_SYSTEM possible solveable
             not BackendVariable.isStateVar(var))
      equation
        eq.exp = ExpressionSolve.solve(eq.exp, eq.scalar, Expression.crefExp(var.varName));
        new_eq = BackendDAE.SOLVED_EQUATION(var.varName, eq.exp, eq.source, eq.attr);
        new_eq = BackendEquation.setEquationAttributes(new_eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.auxVars = listAppend({var}, traverserArgs.auxVars);
        traverserArgs.auxEqns = listAppend({new_eq}, traverserArgs.auxEqns);
        if debug then print("[DAEmode] Create solved equation. vars:\n" +
                      BackendDump.varListString({var}, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.COMPLEX_EQUATION()}, vars)
      guard (not listEmpty(varIdxs) and // not inside of EQNS_SYSTEM possible solveable
             not Util.boolOrList(list(BackendVariable.isStateVar(v) for v in vars)))
      equation
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.auxVars = listAppend(vars, traverserArgs.auxVars);
        traverserArgs.auxEqns = listAppend({new_eq}, traverserArgs.auxEqns);
        if debug then print("[DAEmode] Create solved complex equation. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.ARRAY_EQUATION()}, vars)
      guard (not listEmpty(varIdxs) and // not inside of EQNS_SYSTEM possible solveable
             not Util.boolOrList(list(BackendVariable.isStateVar(v) for v in vars)))
      equation
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.auxVars = listAppend(vars, traverserArgs.auxVars);
        traverserArgs.auxEqns = listAppend({new_eq}, traverserArgs.auxEqns);
        if debug then print("[DAEmode] Create solved array equations. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.WHEN_EQUATION()}, {var})
      guard (not listEmpty(varIdxs)) // not inside of EQNS_SYSTEM possible solveable
      equation
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_DISCRETE);
        traverserArgs.auxVars = listAppend({var}, traverserArgs.auxVars);
        traverserArgs.auxEqns = listAppend({new_eq}, traverserArgs.auxEqns);
        if debug then print("[DAEmode] Create solved when equation. vars:\n" +
                      BackendDump.varListString({var}, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq as BackendDAE.ALGORITHM(alg=alg, source=source, expand=crefExpand)}, vars)
      guard (not listEmpty(varIdxs) // not inside of EQNS_SYSTEM possible solveable
             and not Util.boolOrList(list(BackendVariable.isStateVar(v) for v in vars)))
      equation
        // check that all vars
        true = CheckModel.isCrefListAlgorithmOutput(list(v.varName for v in vars), alg, source, crefExpand);
        new_eq = BackendEquation.setEquationAttributes(eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.auxVars = listAppend(vars, traverserArgs.auxVars);
        traverserArgs.auxEqns = listAppend({new_eq}, traverserArgs.auxEqns);
        if debug then print("[DAEmode] Create solved algorithms. vars:\n" +
                      BackendDump.varListString(vars, "") + "eq:\n" +
                      BackendDump.equationListString({new_eq}, "") + "\n"); end if;
      then
        (traverserArgs);

    // a = f(...) and a is an array
    case ({eq as BackendDAE.ARRAY_EQUATION(left=exp)}, vars)
      guard (Util.boolOrList(list(BackendVariable.isStateVar(v) for v in vars))
             or listEmpty(varIdxs) // inside of EQNS_SYSTEM
             and Expression.isCref(exp) )
      equation
        globalDAEData = traverserArgs.globalDAEData;

        cref = Expression.expCref(exp);

        // create aux variables for recordCref
        newAuxVars = BackendVariable.getVar(cref, traverserArgs.systemVars);
        crlst = ComponentReference.expandCref(cref, true);
        newAuxVars = list(BackendVariable.copyVarNewName(ComponentReference.crefPrefixAux(cr), v) threaded for cr in crlst, v in newAuxVars);
        newAuxVars = list(BackendVariable.setVarKind(v, BackendDAE.DAE_AUX_VAR()) for v in newAuxVars);
        traverserArgs.auxVars = listAppend(newAuxVars, traverserArgs.auxVars);

        // create aux equation aux = f(...)
        newCref = ComponentReference.crefPrefixAux(cref);
        eq.left = Expression.crefExp(newCref);
        aux_eq = eq;

        aux_eq = BackendEquation.setEquationAttributes(aux_eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.auxEqns = listAppend({aux_eq}, traverserArgs.auxEqns);

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
        traverserArgs.resVars = listAppend(newResVars, traverserArgs.resVars);
        traverserArgs.resEqns = listAppend(listReverse(newResEqns), traverserArgs.resEqns);
        globalDAEData = addVarsGlobalData(globalDAEData, vars);

        traverserArgs.globalDAEData = globalDAEData;
        if debug then print("[DAEmode] Added residual array equation\n" +
                      BackendDump.varListString(newResVars, "") + "states:\n" +
                      BackendDump.varListString(vars, "") + "eqs:\n" +
                      BackendDump.equationListString(newResEqns, "") + "\n"); end if;
      then
        (traverserArgs);

    case ({eq}, vars)
      guard (Util.boolOrList(list(BackendVariable.isStateVar(v) for v in vars))
             or listEmpty(varIdxs)) // inside of EQNS_SYSTEM
      equation
        globalDAEData = traverserArgs.globalDAEData;
        newResEqns = BackendEquation.equationToScalarResidualForm(eq, traverserArgs.functionTree);
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, globalDAEData.numResVars);
        globalDAEData.numResVars = newnumResVars;
        newResEqns = list(BackendEquation.setEquationAttributes(e, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC) for e in newResEqns);
        traverserArgs.resVars = listAppend(newResVars, traverserArgs.resVars);
        traverserArgs.resEqns = listAppend(listReverse(newResEqns), traverserArgs.resEqns);
        globalDAEData = addVarsGlobalData(globalDAEData, vars);
        traverserArgs.globalDAEData = globalDAEData;
        if debug then print("[DAEmode] Added strong component or state eqns\n" +
                      BackendDump.varListString(newResVars, "") + "states:\n" +
                      BackendDump.varListString(vars, "") + "eqs:\n" +
                      BackendDump.equationListString(newResEqns, "") + "\n"); end if;
      then
        (traverserArgs);

    // recordCref = f(...)
    case ({eq as BackendDAE.COMPLEX_EQUATION(left=exp)}, vars)
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
        crlst = list(BackendVariable.varCref(v) for v in vars);
        newAuxVars = list(BackendVariable.copyVarNewName(ComponentReference.crefPrefixAux(cr), v) threaded for cr in crlst, v in vars);
        newAuxVars = list(BackendVariable.setVarKind(v, BackendDAE.DAE_AUX_VAR()) for v in newAuxVars);
        traverserArgs.auxVars = listAppend(newAuxVars, traverserArgs.auxVars);

        // create aux equation aux = f(...)
        newCref = ComponentReference.crefPrefixAux(cref);
        eq.left = Expression.crefToExp(newCref);
        aux_eq = eq;

        aux_eq = BackendEquation.setEquationAttributes(aux_eq, BackendDAE.EQ_ATTR_DEFAULT_AUX);
        traverserArgs.auxEqns = listAppend({aux_eq}, traverserArgs.auxEqns);

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
        traverserArgs.resVars = listAppend(listReverse(newResVars), traverserArgs.resVars);
        traverserArgs.resEqns = listAppend(listReverse(newResEqns), traverserArgs.resEqns);
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

    case(_, _)
      guard(not listEmpty(varIdxs))
      algorithm
        vars := inVars;
        for e in inEqns loop
          size := BackendEquation.equationSize(e);
          newAuxVars := List.firstN(vars, size);
          traverserArgs := traverserStrongComponents({e}, newAuxVars, {}, {}, traverserArgs);
          vars := List.stripN(vars, size);
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


function addVarsGlobalData
  input output BackendDAE.BackendDAEModeData globalDAEData;
  input list<BackendDAE.Var> inVars;
protected
  list<BackendDAE.Var> vars;
algorithm
  // prepare algebraic states
  vars := List.filterOnTrue(inVars, BackendVariable.isNonStateVar);
  // check for discrete vars
  {} := List.filterOnTrue(vars, BackendVariable.isVarDiscrete);
  vars := list(BackendVariable.setVarKind(v, BackendDAE.ALG_STATE()) for v in vars);
  //print("Alg vars: " + BackendDump.varListString(vars, "") + "\n");
  globalDAEData.algStateVars := listAppend(globalDAEData.algStateVars, vars);
  globalDAEData.stateVars := listAppend(globalDAEData.stateVars, List.filterOnTrue(inVars, BackendVariable.isStateVar));
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
