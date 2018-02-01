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
import CommonSubExpression;
import ComponentReference;
import Config;
import DAE;
import ErrorExt;
import ExecStat.execStat;
import Expression;
import Global;
import Initialization;
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
    simDAE := BackendDAEOptimize.addInitialStmtsToAlgorithms(simDAE);
    simDAE := Initialization.removeInitializationStuff(simDAE);

    // post-optimization phase
    // use preOpt instead
    simDAE := BackendDAEUtil.postOptimizeDAE(simDAE, postOptModules, matchingAlgorithm, daeHandler);

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


// =============================================================================
// section for postOptModule >>calculateStateSetsJacobians<<
//
// =============================================================================

protected
type TraverseEqnAryFold = tuple <BackendDAE.BackendDAEModeData, BackendDAE.Variables>;

public function createDAEmodeBDAE
" This modules creates a BDAE with residual Variables."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, createDAEmodeEqSystem);
end createDAEmodeBDAE;


protected function createDAEmodeEqSystem
"The main to create equations by adding auxiliary variables
 and auxiliary equations  of the form $auxExp = rhs, $resVar = $auxExp - lhs"
  input output BackendDAE.EqSystem syst;
  input output BackendDAE.Shared shared;
protected
  TraverseEqnAryFold travArgs;
  BackendDAE.BackendDAEModeData extraArgs;
  BackendDAE.EquationArray tmp;
  BackendDAE.Variables vars;
  BackendDAE.EqSystem retSystem;
  constant Boolean debug = false;
algorithm
  extraArgs := BackendDAE.BDAE_MODE_DATA(shared.daeModeData.numAuxVars,{},shared.daeModeData.numResVars,{},shared.daeModeData.numAuxEqns,{},shared.daeModeData.numResEqns,{});
  travArgs := (extraArgs, syst.orderedVars);
  if debug then BackendDump.printEqSystem(syst); end if;
  // for every equation create corresponding residiual variable(s)
  travArgs := BackendEquation.traverseEquationArray(syst.orderedEqs,
    traverserEqnAryAuxRes, travArgs);
  (extraArgs, vars) := travArgs;
  syst.orderedVars := vars;

  // push ordered variables to known vars
  shared.localKnownVars := BackendVariable.addVariables(syst.orderedVars, shared.localKnownVars);

  // create residual system
  extraArgs.resVars := listAppend(extraArgs.resVars, extraArgs.auxVars);
  retSystem := BackendDAEUtil.createEqSystem(BackendVariable.listVar(extraArgs.resVars));

  extraArgs.resEqns := listReverse(extraArgs.resEqns);
  extraArgs.resEqns := listAppend(listReverse(extraArgs.auxEqns),extraArgs.resEqns);
  retSystem := BackendDAEUtil.setEqSystEqs(retSystem, BackendEquation.listEquation(extraArgs.resEqns));

  retSystem := BackendDAEUtil.setEqSystStateSets(retSystem, syst.stateSets);
  syst := retSystem;
  shared.daeModeData := extraArgs;
  if debug then BackendDump.printEqSystem(syst); end if;

end createDAEmodeEqSystem;

protected function traverserEqnAryAuxRes
"This function prepares an equation system for
 the dae mode by dividing the equations into
 aux equations and residual equations.

 "
  input output BackendDAE.Equation orgEquation;
  input output TraverseEqnAryFold extraArgs;
algorithm
  (extraArgs) :=
  matchcontinue (orgEquation)
    local
      list<BackendDAE.Equation> newResEqns;
      list<BackendDAE.Var> newResVars;
      BackendDAE.Variables orderedVars;
      BackendDAE.Var dummyVar;
      BackendDAE.Equation eq;
      Integer newnumResVars;
      DAE.Exp exp;
      BackendDAE.BackendDAEModeData travArgs;
      DAE.ComponentRef cref;
      String str;

    case (eq as BackendDAE.EQUATION(exp=exp)) guard( CommonSubExpression.isCSEExp(exp))
      equation
        (travArgs, orderedVars) = extraArgs;
        cref = Expression.expCref(exp);
        (newResVars,_) = BackendVariable.getVar(cref, orderedVars);
        newResVars = list(BackendVariable.setVarKind(v, BackendDAE.DAE_AUX_VAR()) for v in newResVars);
        travArgs.auxVars = listAppend(newResVars, travArgs.auxVars);
        travArgs.auxEqns = listAppend({eq}, travArgs.auxEqns);
        orderedVars = BackendVariable.removeCref(cref, orderedVars);
        extraArgs = (travArgs, orderedVars);
      then
        (extraArgs);

    case (eq as BackendDAE.EQUATION())
      equation
        (travArgs, orderedVars) = extraArgs;
        newResEqns = BackendEquation.equationToScalarResidualForm(eq);
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, travArgs.numResVars);
        travArgs.numResVars = newnumResVars;
        travArgs.resVars = listAppend(newResVars, travArgs.resVars);
        travArgs.resEqns = listAppend(newResEqns, travArgs.resEqns);
        extraArgs = (travArgs, orderedVars);
      then
        (extraArgs);

    case (eq as BackendDAE.SOLVED_EQUATION())
      equation
        (travArgs, orderedVars) = extraArgs;
        newResEqns = BackendEquation.equationToScalarResidualForm(eq);
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, travArgs.numResVars);
        travArgs.numResVars = newnumResVars;
        travArgs.resVars = listAppend(newResVars, travArgs.resVars);
        travArgs.resEqns = listAppend(newResEqns, travArgs.resEqns);
        extraArgs = (travArgs, orderedVars);
      then
        (extraArgs);

    case (eq as BackendDAE.ARRAY_EQUATION())
      equation
        (travArgs, orderedVars) = extraArgs;
        newResEqns = BackendEquation.equationToScalarResidualForm(eq);
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, travArgs.numResVars);
        travArgs.numResVars = newnumResVars;
        travArgs.resVars = listAppend(listReverse(newResVars), travArgs.resVars);
        travArgs.resEqns = listAppend(newResEqns, travArgs.resEqns);
        extraArgs = (travArgs, orderedVars);
      then
        (extraArgs);

    case (eq as BackendDAE.COMPLEX_EQUATION())
      equation
        (travArgs, orderedVars) = extraArgs;
        newResEqns = BackendEquation.equationToScalarResidualForm(eq);
        dummyVar = BackendVariable.makeVar(DAE.emptyCref);
        dummyVar = BackendVariable.setVarKind(dummyVar, BackendDAE.DAE_RESIDUAL_VAR());
        (newResEqns, newResVars, newnumResVars) = BackendEquation.convertResidualsIntoSolvedEquations(newResEqns,
            "$DAEres", dummyVar, travArgs.numResVars);
        travArgs.numResVars = newnumResVars;
        travArgs.resVars = listAppend(newResVars, travArgs.resVars);
        travArgs.resEqns = listAppend(newResEqns, travArgs.resEqns);
        extraArgs = (travArgs, orderedVars);
      then
        (extraArgs);

    else equation
      str = BackendDump.equationString(orgEquation);
      Error.addInternalError("DAEMode.traverserEqnAryAuxRes failed on equation:\n" + str + "\n", sourceInfo());
    then fail();
  end matchcontinue;
end traverserEqnAryAuxRes;

/*
get config function
*/
protected function getPostOptModulesDAEString
  output list<String> strpostOptModules;
algorithm
  strpostOptModules := Config.getPostOptModulesDAE();
end getPostOptModulesDAEString;

annotation(__OpenModelica_Interface="backend");
end DAEMode;
