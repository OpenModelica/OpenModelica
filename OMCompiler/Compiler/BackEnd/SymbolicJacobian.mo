/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2024, Open Source Modelica Consortium (OSMC),
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

encapsulated package SymbolicJacobian
" file:        SymbolicJacobian.mo
  package:     SymbolicJacobian
  description: This package contains stuff that is related to symbolic jacobian or sparsity structure."


public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;
public import FGraph;

protected
import Array;
import BackendDAEOptimize;
import BackendDAETransform;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import BackendVarTransform;
import BaseHashSet;
import Ceval;
import ClockIndexes;
import Config;
import ComponentReference;
import Debug;
import Differentiate;
import DynamicOptimization;
import ElementSource;
import ExecStat.execStat;
import ExpandableArray;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import Error;
import Flags;
import FlagsUtil;
import GCExt;
import Global;
import Graph;
import HashSet;
import IndexReduction;
import List;
import StringUtil;
import System;
import UnorderedMap;
import Util;
import Values;
import ValuesUtil;

// =============================================================================
// section for postOptModule >>symbolicJacobian<<
//
// Detects the sparse pattern of the ODE system and calculates also the symbolic
// Jacobian if flag "--generateDynamicJacobian=symbolic".
// =============================================================================

// From User Documentation for ida v5.4.0 equation (2.5) aka Alpha
// is the scalar in the system Jacobian, proportional to the inverse of the step
// size used for DAE_Mode symbolic jacobians
public constant String DAE_CJ = "$DAE_CJ";

public function symbolicJacobian "author: lochel
  Detects the sparse pattern of the ODE system and calculates also the symbolic
  Jacobian if flag '--generateDynamicJacobian=symbolic'."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN)
    case "none"     then inDAE;
    case "numeric"  then detectSparsePatternODE(inDAE);
    case "symbolic" then generateSymbolicJacobianPast(inDAE);
  end match;
end symbolicJacobian;

// =============================================================================
// section for postOptModule >>calculateStateSetsJacobians<<
//
// =============================================================================

public function calculateStateSetsJacobians "author: wbraun
  Calculates the Jacobian matrix with directional derivative method for dynamic
  state selection."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, calculateEqSystemStateSetsJacobians);
end calculateStateSetsJacobians;

// =============================================================================
// section for postOptModule >>calculateStrongComponentJacobians<<
//
// Module for to calculate strong component Jacobian matrices
// =============================================================================

public function calculateStrongComponentJacobians "author: wbraun
  Calculates Jacobian matrix with directional derivative method for each SCC."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  try
    outDAE := BackendDAEUtil.mapEqSystem(inDAE, calculateEqSystemJacobians);
  else
    outDAE := inDAE;
  end try;
end calculateStrongComponentJacobians;

// =============================================================================
// section for postOptModule >>constantLinearSystem<<
//
// constant Jacobian matrices. Linear system of equations (A x = b) where
// A and b are constant.
// =============================================================================

public function constantLinearSystem
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, constantLinearSystem0, (false,1));
end constantLinearSystem;

// =============================================================================
// section for postOptModule >>detectSparsePatternODE<<
//
// Generate sparse pattern
// =============================================================================
protected function detectSparsePatternODE
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.BackendDAE DAE;
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.SparseColoring coloredCols;
  BackendDAE.SparsePattern sparsePattern;
  list<BackendDAE.Var> states;
  BackendDAE.Var dummyVar;
  BackendDAE.Variables v;
  constant Boolean debug = false;
algorithm
  // lochel: This module fails for some models (e.g. #3543)
  try
    if debug then execStat("detectSparsePatternODE -> start "); end if;
    BackendDAE.DAE(eqs = eqs) := inBackendDAE;

    // prepare a DAE
    DAE := BackendDAEUtil.copyBackendDAE(inBackendDAE);
    if debug then execStat("detectSparsePatternODE -> copy dae "); end if;
    DAE := BackendDAEOptimize.collapseIndependentBlocks(DAE);
    if debug then execStat("detectSparsePatternODE -> collapse blocks "); end if;
    DAE := BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
    if debug then execStat("detectSparsePatternODE -> transform backend dae "); end if;

    // get states for DAE
    BackendDAE.DAE(eqs = {BackendDAE.EQSYSTEM(orderedVars = v)}, shared=shared) := DAE;
    states := BackendVariable.getAllStateVarFromVariables(v);
    if debug then execStat("detectSparsePatternODE -> get all vars "); end if;

    // generate sparse pattern
    (sparsePattern, coloredCols) := generateSparsePattern(DAE, states, states);
    if debug then execStat("detectSparsePatternODE -> generateSparsePattern "); end if;
    shared := addBackendDAESharedJacobianSparsePattern(sparsePattern, coloredCols, BackendDAE.SymbolicJacobianAIndex, shared);
    if debug then execStat("detectSparsePatternODE -> addBackendDAESharedJacobianSparsePattern "); end if;

    outBackendDAE := BackendDAE.DAE(eqs, shared);
  else
    // skip this optimization module
    Error.addCompilerWarning("The optimization module detectJacobianSparsePattern failed. This module will be skipped and the transformation process continued.");
    outBackendDAE := inBackendDAE;
  end try;
end detectSparsePatternODE;

// =============================================================================
// section for postOptModule >>symbolicJacobianDAE<<
//
// Generate symbolic jacobian for DAEMode
// =============================================================================

public function symbolicJacobianDAE
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.BackendDAE DAE;
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  BackendDAE.SparseColoring coloredCols;
  BackendDAE.SparsePattern sparsePattern;
  BackendDAE.NonlinearPattern nonlinearPattern;
  list<BackendDAE.Var> inDepVars;
  list<BackendDAE.Var> depVars;
  BackendDAE.Var dummyVar;
  BackendDAE.Variables v, resVars;
  BackendDAE.Variables emptyVars = BackendVariable.emptyVars();
  Option<BackendDAE.SymbolicJacobian> symjac;
  DAE.FunctionTree funcs;
  constant Boolean debug = false;
algorithm
  try
    if debug then execStat(getInstanceName() + "-> start "); end if;
    BackendDAE.DAE(eqs = eqs) := inBackendDAE;

    // prepare a DAE
    DAE := BackendDAEUtil.copyBackendDAE(inBackendDAE);
    if debug then execStat(getInstanceName() + "-> copy dae "); end if;
    DAE := BackendDAEOptimize.collapseIndependentBlocks(DAE);
    if debug then execStat(getInstanceName() + "-> collapse blocks "); end if;
    DAE := BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
    if debug then execStat(getInstanceName() + "-> transform backend dae "); end if;

    // get states for DAE
    BackendDAE.DAE(eqs = {BackendDAE.EQSYSTEM(orderedVars = v)}, shared=shared) := DAE;
    ((_, resVars)) := BackendVariable.traverseBackendDAEVars(v, BackendVariable.collectVarKindVarinVariables, (BackendVariable.isDAEmodeResVar, emptyVars));
    depVars := BackendVariable.varList(resVars);

    inDepVars := listAppend(shared.daeModeData.stateVars, shared.daeModeData.algStateVars);

    if debug then execStat(getInstanceName() + "-> get all vars "); end if;

    if Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN) == "symbolic" then
      // generate symbolic jacobian and sparsity pattern
      (symjac, funcs, sparsePattern, coloredCols, nonlinearPattern) := generateGenericJacobian(
        inBackendDAE          = DAE,
        inDiffVars            = inDepVars,
        inStateVars           = BackendVariable.emptyVars(),
        inInputVars           = BackendVariable.emptyVars(),
        inParameterVars       = shared.globalKnownVars,
        inDifferentiatedVars  = resVars,
        inVars                = BackendVariable.varList(v),
        inName                = "A",
        onlySparsePattern     = false,
        daeMode               = true);
      if debug then execStat(getInstanceName() + "-> generateGenericJacobian "); end if;

      shared.symjacs := List.set(shared.symjacs, BackendDAE.SymbolicJacobianAIndex, (symjac, sparsePattern, coloredCols, nonlinearPattern));
      shared.functionTree := funcs;

      if debug then BackendDump.dumpJacobianString(BackendDAE.GENERIC_JACOBIAN(symjac, sparsePattern, coloredCols, nonlinearPattern)); end if;
    else
      // only generate sparsity pattern
      (sparsePattern, coloredCols) := generateSparsePattern(DAE, inDepVars, depVars);
      if debug then execStat(getInstanceName() + "-> generateSparsePattern "); end if;
      shared := addBackendDAESharedJacobianSparsePattern(sparsePattern, coloredCols, BackendDAE.SymbolicJacobianAIndex, shared);
      if debug then execStat(getInstanceName() + "-> addBackendDAESharedJacobianSparsePattern "); end if;
    end if;

    outBackendDAE := BackendDAE.DAE(eqs, shared);
  else
    // skip this optimization module
    Error.addCompilerWarning("The optimization module " + getInstanceName() + " failed. This module will be skipped and the transformation process continued.");
    outBackendDAE := inBackendDAE;
  end try;
end symbolicJacobianDAE;

// =============================================================================
// section for postOptModule >>generateSymbolicJacobianPast<<
//
// Symbolic Jacobian subsection
// =============================================================================

protected function generateSymbolicJacobianPast
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  Option<BackendDAE.SymbolicJacobian> symJacA;
  BackendDAE.SparsePattern sparsePattern;
  BackendDAE.SparseColoring sparseColoring;
  BackendDAE.NonlinearPattern nonlinearPattern;
  DAE.FunctionTree funcs, functionTree;
algorithm
  System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
  BackendDAE.DAE(eqs=eqs,shared=shared) := inBackendDAE;
  (symJacA, funcs, sparsePattern, sparseColoring, nonlinearPattern) := createSymbolicJacobianforStates(inBackendDAE);
  shared := addBackendDAESharedJacobian(symJacA, sparsePattern, sparseColoring, nonlinearPattern, shared);
  functionTree := BackendDAEUtil.getFunctions(shared);
  functionTree := DAE.AvlTreePathFunction.join(functionTree, funcs);
  shared := BackendDAEUtil.setSharedFunctionTree(shared, functionTree);
  outBackendDAE := BackendDAE.DAE(eqs,shared);
  System.realtimeTock(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
end generateSymbolicJacobianPast;

protected function createSymbolicJacobianforStates "author: wbraun
  all functionODE equation are differentiated with respect to the states."
  input BackendDAE.BackendDAE inBackendDAE;
  output Option<BackendDAE.SymbolicJacobian> outJacobian;
  output DAE.FunctionTree outFunctionTree;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outSparseColoring;
  output BackendDAE.NonlinearPattern outNonlinearPattern;
protected
  BackendDAE.BackendDAE backendDAE2;
  list<BackendDAE.Var>  varlst, knvarlst, states, inputvars, paramvars;
  BackendDAE.Variables v, globalKnownVars;
algorithm
  if Flags.isSet(Flags.JAC_DUMP2) then
    print("analytical Jacobians -> start generate system for matrix A time : " + realString(clock()) + "\n");
  end if;
  backendDAE2 := BackendDAEUtil.copyBackendDAE(inBackendDAE);
  backendDAE2 := BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
  backendDAE2 := BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
  BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)},BackendDAE.SHARED(globalKnownVars = globalKnownVars)) := backendDAE2;

  // Prepare all needed variables
  varlst := BackendVariable.varList(v);
  knvarlst := BackendVariable.varList(globalKnownVars);
  states := BackendVariable.getAllStateVarFromVariables(v);
  inputvars := List.select(knvarlst,BackendVariable.isInput);
  paramvars := List.select(knvarlst, BackendVariable.isParam);

  if Flags.isSet(Flags.JAC_DUMP2) then
    print("analytical Jacobians -> prepared vars for symbolic matrix A time: " + realString(clock()) + "\n");
  end if;
  if Flags.isSet(Flags.JAC_DUMP2) then
    BackendDump.bltdump("System to create symbolic jacobian of: ",backendDAE2);
  end if;
  (outJacobian, outFunctionTree, outSparsePattern, outSparseColoring, outNonlinearPattern) := generateGenericJacobian(backendDAE2,states,BackendVariable.listVar1(states),BackendVariable.listVar1(inputvars),BackendVariable.listVar1(paramvars),BackendVariable.listVar1(states),varlst,"A",false);
end createSymbolicJacobianforStates;

// =============================================================================
// section for postOptModule >>generateSymbolicSensitivities<<
//
// That function generates symbolic sentivities for parameters
// by differentiatiating the states with respect to the parameters
// =============================================================================

public function generateSymbolicSensitivities
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
  Option<BackendDAE.SymbolicJacobian> symJacS;
  BackendDAE.SparsePattern sparsePattern;
  BackendDAE.SparseColoring sparseColoring;
  BackendDAE.NonlinearPattern nonlinearPattern;
  DAE.FunctionTree funcs, functionTree;
algorithm
  System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
  BackendDAE.DAE(eqs=eqs,shared=shared) := inBackendDAE;
  (symJacS, funcs, sparsePattern, sparseColoring, nonlinearPattern) := createSymbolicJacobianforParameters(inBackendDAE);
  shared := addBackendDAESharedJacobian(symJacS, sparsePattern, sparseColoring, nonlinearPattern, shared);
  functionTree := BackendDAEUtil.getFunctions(shared);
  functionTree := DAE.AvlTreePathFunction.join(functionTree, funcs);
  shared := BackendDAEUtil.setSharedFunctionTree(shared, functionTree);
  outBackendDAE := BackendDAE.DAE(eqs,shared);
  System.realtimeTock(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
end generateSymbolicSensitivities;

protected function createSymbolicJacobianforParameters
"author: wbraun
  all functionODE equation are differentiated with respect to the parameters."
  input BackendDAE.BackendDAE inBackendDAE;
  output Option<BackendDAE.SymbolicJacobian> outJacobian;
  output DAE.FunctionTree outFunctionTree;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outSparseColoring;
  output BackendDAE.NonlinearPattern outNonlinearPattern;
protected
  BackendDAE.BackendDAE backendDAE2;
  list<BackendDAE.Var>  varlst, knvarlst, states, inputvars, paramvars;
  BackendDAE.Variables v, globalKnownVars;
algorithm
  if Flags.isSet(Flags.JAC_DUMP2) then
    print("analytical Jacobians -> start generate system for matrix S time : " + realString(clock()) + "\n");
  end if;

  backendDAE2 := BackendDAEUtil.copyBackendDAE(inBackendDAE);
  backendDAE2 := BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
  backendDAE2 := BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
  BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)},BackendDAE.SHARED(globalKnownVars = globalKnownVars)) := backendDAE2;

  // Prepare all needed variables
  varlst := BackendVariable.varList(v);
  knvarlst := BackendVariable.varList(globalKnownVars);
  states := BackendVariable.getAllStateVarFromVariables(v);
  inputvars := List.select(knvarlst,BackendVariable.isInput);
  paramvars := List.select(knvarlst, BackendVariable.isParam);

  if Flags.isSet(Flags.JAC_DUMP2) then
    print("analytical Jacobians -> prepared vars for symbolic matrix S time: " + realString(clock()) + "\n");
  end if;
  if Flags.isSet(Flags.JAC_DUMP2) then
    BackendDump.bltdump("System to create symbolic jacobian of: ",backendDAE2);
  end if;
  (outJacobian, outFunctionTree, outSparsePattern, outSparseColoring, outNonlinearPattern) := generateGenericJacobian(backendDAE2,paramvars,BackendVariable.listVar1(states),BackendVariable.listVar1(inputvars),BackendVariable.listVar1(states),BackendVariable.listVar1(states),varlst,"S",false);
end createSymbolicJacobianforParameters;

// =============================================================================
// section for postOptModule >>generateSymbolicLinearizationPast<<
//
// =============================================================================

public function generateSymbolicLinearizationPast
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE := matchcontinue(inBackendDAE)
  local
    BackendDAE.EqSystems eqs;
    BackendDAE.Shared shared;
    BackendDAE.SymbolicJacobians linearModelMatrices;
    DAE.FunctionTree funcs, functionTree;
    list< .DAE.Constraint> constraints;
  case(_) equation
    true = Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION);
    BackendDAE.DAE(eqs=eqs,shared=shared) = inBackendDAE;
    (linearModelMatrices, funcs) = createLinearModelMatrices(inBackendDAE, Config.acceptOptimicaGrammar());
    shared = BackendDAEUtil.setSharedSymJacs(shared, linearModelMatrices);
    functionTree = BackendDAEUtil.getFunctions(shared);
    functionTree = DAE.AvlTreePathFunction.join(functionTree, funcs);
    shared = BackendDAEUtil.setSharedFunctionTree(shared, functionTree);
    outBackendDAE = BackendDAE.DAE(eqs,shared);
  then outBackendDAE;

  else inBackendDAE;
  end matchcontinue;
end generateSymbolicLinearizationPast;

// =============================================================================
// section for postOptModule >>inputDerivativesUsed<<
//
// check for derivatives of inputs
// =============================================================================

public function inputDerivativesUsed "author: Frenkel TUD 2012-10
  checks if der(input) is used and report a warning/error."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, inputDerivativesUsedWork, false);
end inputDerivativesUsed;

protected function inputDerivativesUsedWork "author: Frenkel TUD 2012-10"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared = inShared "unused";
  output Boolean outChanged;
protected
  Boolean hasFailed = false;
algorithm
  (osyst, outChanged) := matchcontinue(isyst)
    local
      BackendDAE.EquationArray orderedEqs;
      list<DAE.Exp> explst;
      String s;
    case BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) equation
      ((_, explst as _::_)) = BackendDAEUtil.traverseBackendDAEExpsEqns(orderedEqs, traverserinputDerivativesUsed, (BackendVariable.daeGlobalKnownVars(inShared), {}));
      s = stringDelimitList(List.map(explst, ExpressionDump.printExpStr), "\n");
      Error.addMessage(Error.DERIVATIVE_INPUT, {s});
      hasFailed = true;
    then (BackendDAEUtil.setEqSystEqs(isyst, orderedEqs), true);

    else (isyst, inChanged);
  end matchcontinue;

  // Fail after error is displayed.
  // We do it this way, because I was to lazy to rewrite all of this function.
  if hasFailed then fail(); end if;
end inputDerivativesUsedWork;

protected function traverserinputDerivativesUsed "author: Frenkel TUD 2012-10"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<DAE.Exp>> itpl;
  output DAE.Exp e;
  output tuple<BackendDAE.Variables,list<DAE.Exp>> tpl;
algorithm
  (e,tpl) := Expression.traverseExpTopDown(inExp,traverserExpinputDerivativesUsed,itpl);
end traverserinputDerivativesUsed;

protected function traverserExpinputDerivativesUsed
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<DAE.Exp>> tpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,list<DAE.Exp>> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,tpl)
    local
      BackendDAE.Variables vars;
      DAE.Type tp;
      DAE.Exp e;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<DAE.Exp> explst;
    case (e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)})}),(vars,explst))
      equation
        (var,_) = BackendVariable.getVarSingle(cr, vars);
        true = BackendVariable.isVarOnTopLevelAndInput(var);
      then (e,false,(vars,e::explst));
    case (e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),(vars,explst))
      equation
        (var,_) = BackendVariable.getVarSingle(cr, vars);
        true = BackendVariable.isVarOnTopLevelAndInput(var);
      then (e,false,(vars,e::explst));
    else (inExp,true,tpl);
  end matchcontinue;
end traverserExpinputDerivativesUsed;

// =============================================================================
// solve linear systems with constant jacobian and variable b-Vector
//
// =============================================================================

protected function jacobianIsConstant
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  output Boolean isConst;
protected
  list<BackendDAE.Equation> eqs;
  list<DAE.Exp> exps;
algorithm
  eqs := List.map(jac, Util.tuple33);
  isConst := not List.any(eqs, variableResidual);
end jacobianIsConstant;

protected function variableResidual
  input BackendDAE.Equation eq;
  output Boolean isNotConst;
algorithm
  isNotConst := match(eq)
    case BackendDAE.RESIDUAL_EQUATION(exp=DAE.RCONST(_))
    then false;

    else true;
  end match;
end variableResidual;

protected function replaceStrongComponent "replaces the indexed component with compsNew and adds compsAdd at the end. the assignments will be updated"
  input BackendDAE.EqSystem systIn;
  input Integer idx;
  input BackendDAE.StrongComponents compsNew;
  input BackendDAE.StrongComponents compsAdd;
  output BackendDAE.EqSystem systOut = systIn;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.Matching matching;
  array<Integer> ass1, ass2, assAdd;
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps)) := systIn;
  if not listEmpty(compsAdd) then
    assAdd := arrayCreate(listLength(compsAdd), 0);
    ass1 := arrayAppend(ass1, assAdd);
    ass2 := arrayAppend(ass2, assAdd);
    List.map2_0(compsAdd, updateAssignment, ass1, ass2);
  end if;
  List.map2_0(compsNew, updateAssignment, ass1, ass2);
  comps := List.replaceAtWithList(compsNew, idx-1, comps);
  systOut.matching := BackendDAE.MATCHING(ass1, ass2, listAppend(comps, compsAdd));
  systOut := BackendDAEUtil.setEqSystMatrices(systOut);
end replaceStrongComponent;

protected function updateAssignment
  input BackendDAE.StrongComponent comp;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _ := matchcontinue(comp,ass1,ass2)
  local
    Integer eq,var;
  case(BackendDAE.SINGLEEQUATION(eqn=eq,var=var),_,_)
    equation
      arrayUpdate(ass2,eq,var);
      arrayUpdate(ass1,var,eq);
    then ();
  else
    then ();
  end matchcontinue;
end updateAssignment;

protected function solveConstJacLinearSystem
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared ishared;
  input list<BackendDAE.Equation> eqn_lst;
  input list<Integer> eqn_indxs;
  input list<BackendDAE.Var> var_lst;
  input list<Integer> var_indxs;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer sysIdxIn;
  input Integer compIdxIn;
  output list<BackendDAE.Equation> sysEqsOut;
  output list<BackendDAE.Equation> bEqsOut;
  output list<BackendDAE.Var> bVarsOut;
  output array<Integer> orderOut;
  output Integer sysIdxOut;
protected
    BackendDAE.Variables vars,vars1,v;
    BackendDAE.EquationArray eqns,eqns1, eqns2;
    list<DAE.Exp> beqs;
    list<DAE.ElementSource> sources;
    BackendDAE.Matching matching;
    DAE.FunctionTree funcs;
    BackendDAE.Shared shared;
    BackendDAE.StateSets stateSets;
    BackendDAE.BaseClockPartitionKind partitionKind;

    array<array<Real>> A;
    array<Real> b;
    Real entry;
    Integer row,col,n, systIdx;
    array<Integer> order;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=matching,stateSets=stateSets,partitionKind=partitionKind) := syst;
  BackendDAE.SHARED(functionTree=funcs) := ishared;
  eqns1 := BackendEquation.listEquation(eqn_lst);
  v := BackendVariable.listVar1(var_lst);
  n := listLength(var_lst);
  (beqs,sources) := BackendDAEUtil.getEqnSysRhs(eqns1,v,SOME(funcs));
  beqs := listReverse(beqs);
    //print("bside: \n"+ExpressionDump.printExpListStr(beqs)+"\n");
  A := evaluateConstantJacobianArray(listLength(var_lst),jac);
    //print("JacVals\n"+stringDelimitList(List.map(jacVals,rListStr),"\n")+"\n\n");

  b := arrayCreate(n*n,0.0);  // i.e. a matrix for the b-vars to get their coefficients independently [(b1,0,0);(0,b2,0),(0,0,b3)]
  order := arrayCreate(n,0);
  for row in 1:n loop
    arrayUpdate(b,(row-1)*n+row,1.0);
  end for;
    //print("b\n"+stringDelimitList(List.mapArray(b,realString),", ")+"\n\n");
    //print("A\n"+stringDelimitList(List.mapArray(A,realString),", ")+"\n\n");
  gauss(A,b,1,n,List.intRange(n),order);
    //print("the order: "+stringDelimitList(List.mapArray(order,intString),",")+"\n");

  (bVarsOut,bEqsOut) := createBVecVars(sysIdxIn,compIdxIn,n,DAE.T_REAL_DEFAULT,beqs);
  sysEqsOut := createSysEquations(A,b,n,order,var_lst,bVarsOut);
  for a in A loop
    GCExt.free(a);
  end for;
  GCExt.free(A);
  GCExt.free(b);
  sysIdxOut := sysIdxIn+1;
  orderOut := order;
end solveConstJacLinearSystem;

protected function createSysEquations "creates new equations for a linear system with constant Jacobian matrix.
  author: Waurich TUD 2015-03"
  input array<array<Real>> A;
  input array<Real> b;
  input Integer n;
  input array<Integer> order;
  input list<BackendDAE.Var> xVars;
  input list<BackendDAE.Var> bVars;
  output list<BackendDAE.Equation> sysEqs = {};
protected
  Integer i;
  Integer row;
  DAE.Exp lhs, rhs;
  list<DAE.Exp> exps, coeffExps, xExps, bExps, xProds, bProds;
  list<Real> coeffs;
  BackendDAE.Equation eq;
algorithm
  xExps := List.map(xVars, BackendVariable.varExp2);
  bExps := List.map(bVars, BackendVariable.varExp2);
  for i in 1:n loop
    row := arrayGet(order,i);
    coeffs := arrayList(A[row]);
    coeffExps := List.map(coeffs,Expression.makeRealExp);
    xProds := List.threadMap1(coeffExps,xExps,makeBinaryExp,DAE.MUL(DAE.T_REAL_DEFAULT));
    lhs := List.fold1(xProds,Expression.makeBinaryExp,DAE.ADD(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0));
    (lhs,_) := ExpressionSimplify.simplify(lhs);
    coeffs := Array.getRange((row-1)*n+1,(row*n),b);
    coeffExps := List.map(coeffs,Expression.makeRealExp);
    bProds := List.threadMap1(coeffExps,bExps,makeBinaryExp,DAE.MUL(DAE.T_REAL_DEFAULT));
    rhs := List.fold1(bProds,Expression.makeBinaryExp,DAE.ADD(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0));
    (rhs,_) := ExpressionSimplify.simplify(rhs);
    eq := BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
    sysEqs := eq::sysEqs;
  end for;
end createSysEquations;

public function makeBinaryExp
  input DAE.Exp inLhs;
  input DAE.Exp inRhs;
  input DAE.Operator inOp;
  output DAE.Exp outExp;
algorithm
  outExp := DAE.BINARY(inLhs, inOp, inRhs);
end makeBinaryExp;

protected function createBVecVars "creates variables for the b-Vector of a linear system with constant Jacobian
  author:Waurich TUD 2015-03"
  input Integer sysIdx;
  input Integer compIdx;
  input Integer size;
  input DAE.Type typ;
  input list<DAE.Exp> bExps;
  output list<BackendDAE.Var> varLst = {};
  output list<BackendDAE.Equation> eqLst = {};
protected
  String ident;
  Integer i;
  DAE.ComponentRef cref;
  BackendDAE.Var var;
  BackendDAE.Equation beq;
algorithm
  for i in 1:size loop
    ident := "$sys"+intString(sysIdx)+"_"+intString(compIdx)+"_b"+intString(i);
    cref := ComponentReference.makeCrefIdent(ident,typ,{});
    var := BackendVariable.makeVar(cref);
    varLst := var::varLst;
    beq := BackendDAE.EQUATION(listGet(bExps,i),Expression.crefExp(cref),DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
    eqLst := beq::eqLst;
  end for;
end createBVecVars;

protected function gauss
  input array<array<Real>> A;
  input array<Real> b;
  input Integer indxIn;
  input Integer n;
  input list<Integer> rangeIn;
  input array<Integer> permutation;
protected
  Integer pivotIdx,pos, ir, ic, p_ir;// ir=rowIdx, ic=columnIdx, p_ir=permuted row idx
  Real pivot, entry, pr_entry, b_entry, first;
  list<Integer> range;
algorithm
  _ := matchcontinue(A,b,indxIn,n,rangeIn,permutation)
  case(_,_,_,_,_,_)
    algorithm
      true := intLe(indxIn,n);
      (pivotIdx,pivot) := getPivotElement(A,rangeIn,indxIn,n);
        //print("pivot: "+intString(pivotIdx)+" has value: "+realString(pivot)+"\n");
      arrayUpdate(permutation,indxIn,pivotIdx);
      range := List.deleteMemberOnTrue(pivotIdx,rangeIn,intEq);

      // the pivot row in the A-matrix divided by the pivot element
      for ic in indxIn:n loop
        entry := arrayGet(A[pivotIdx],ic);
        entry := realDiv(entry,pivot); //divide column entry with pivot element
          //print(" pos "+intString(pos)+" entry "+realString(arrayGet(A,pos))+"\n");
        arrayUpdate(A[pivotIdx],ic,entry);
      end for;
      // the complete pivot row of the b-vector divided by the pivot element
      for ic in 1:n loop
        pos := (pivotIdx-1)*n+ic;
        b_entry := arrayGet(b,pos);
        b_entry := realDiv(b_entry,pivot);
        arrayUpdate(b,pos,b_entry);
      end for;

       // the remaining rows
       for ir in range loop
         first := arrayGet(A[ir],indxIn); //the first row element, that is going to be zero
         //print("first "+realString(first)+"\n");
          for ic in indxIn:n loop
            pos := (ir-1)*n+ic;
            entry := arrayGet(A[ir],ic);  // the current entry
            pivot := arrayGet(A[pivotIdx],ic);  // the element from the column in the pivot row
            //print("pivot "+realString(pivot)+"\n");
            //print("ir "+intString(ir)+" pos "+intString(pos)+" entry0 "+realString(entry)+" entry1 "+realString(realSub(entry,realDiv(first,pivot)))+"\n");
            entry := realSub(entry,realMul(first,pivot));
            arrayUpdate(A[ir],ic,entry);
            b_entry := arrayGet(b,pos);
            pivot := arrayGet(b,(pivotIdx-1)*n+ic);
            b_entry := b_entry - realMul(first,pivot);
            arrayUpdate(b,pos,b_entry);
          end for;
      end for;
        //print("A\n"+stringDelimitList(List.mapArray(A, realString),", ")+"\n\n");
        //print("b\n"+stringDelimitList(List.mapArray(b, realString),", ")+"\n\n");

      //print("new permutation: "+stringDelimitList(List.mapArray(permutation, intString),",")+"\n");
      //print("JACB "+intString(indxIn)+" \n"+stringDelimitList(List.mapArray(jacB, rListStr),"\n ")+"\n\n");
      gauss(A,b,indxIn+1,n,range,permutation);
    then();
  else ();
  end matchcontinue;
end gauss;

protected function getPivotElement "gets the highest element in the startIdx'th to n'th rows and the startidx'th column"
  input array<array<Real>> A;
  input list<Integer> rangeIn;
  input Integer startIdx;
  input Integer n;
  output Integer pos = 0;
  output Real value = 0.0;
protected
  Integer i;
  Real entry;
algorithm
  for i in rangeIn loop
    entry := arrayGet(A[i],startIdx);
    //print("i "+intString(i)+" pi "+intString(p_i)+" entry "+realString(entry)+"\n");
    if realAbs(entry) > value then
      value := entry;
      pos := i;
    end if;
  end for;
end getPivotElement;

protected function rListStr
  input list<Real> l;
  output String s;
algorithm
  s := stringDelimitList(List.map(l,realString)," , ");
end rListStr;



// =============================================================================
// unsorted section
//
// =============================================================================

protected function constantLinearSystem0
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input tuple<Boolean, Integer> iTpl "<inChanged,sysIdxIn>";
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared;
  output tuple<Boolean,Integer> oTpl "<oChanged,sysIdxOut>";
protected
  Boolean changed;
  Integer sysIdx;
  BackendDAE.StrongComponents comps;
algorithm
  ((changed,sysIdx)) := iTpl;
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := isyst;
  (osyst, outShared, changed, sysIdx) := constantLinearSystem1(isyst, inShared, comps, changed, sysIdx, 1);
  osyst := constantLinearSystem2(changed, osyst);
  oTpl := (changed,sysIdx+1);
end constantLinearSystem0;

protected function constantLinearSystem2
  input Boolean b;
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match(b,isyst)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case (false,_) then isyst;
//    case (true,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=BackendDAE.NO_MATCHING()))
    case (true,BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, stateSets=stateSets, partitionKind=partitionKind))
      equation
        // remove empty entries from vars/eqns
        vars = BackendVariable.listVar1(BackendVariable.varList(vars));
        eqns = BackendEquation.listEquation(BackendEquation.equationList(eqns));
      then
        BackendDAEUtil.createEqSystem(vars, eqns, stateSets, partitionKind);
/*    case (true,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2,comps=comps)))
      then
        updateEquationSystemMatching(vars,eqns,ass1,ass2,comps);
*/  end match;
end constantLinearSystem2;

protected function constantLinearSystem1
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponents inComps;
  input Boolean inRunMatching;
  input Integer sysIdxIn;
  input Integer compIdxIn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean runMatching;
  output Integer sysIdxOut;
algorithm
  (osyst, oshared, runMatching, sysIdxOut) := match (inComps)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Integer sysIdx, compIdx;

    case {}
    then (isyst, ishared, inRunMatching, sysIdxIn);

    case comp::comps equation
      (syst, shared, b, sysIdx, compIdx) = constantLinearSystemWork(isyst, ishared, comp, sysIdxIn, compIdxIn);
      (syst, shared, runMatching, sysIdx) = constantLinearSystem1(syst, shared, comps, b or inRunMatching, sysIdx, compIdx);
    then (syst, shared, runMatching, sysIdx);
  end match;
end constantLinearSystem1;

protected function constantLinearSystemWork
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponent comp;
  input Integer sysIdxIn;
  input Integer compIdxIn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
  output Integer sysIdxOut;
  output Integer compIdxOut;
algorithm
  (osyst, oshared, outRunMatching, sysIdxOut, compIdxOut):=
  matchcontinue (isyst, ishared, comp)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp1;
      Boolean b,b1;
      list<BackendDAE.Equation> eqn_lst;
      list<BackendDAE.Var> var_lst;
      list<Integer> eindex,vindx;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;

      Integer sysIdx;
      array<Integer> order;
      list<Integer> bVarIdcs,bEqIdcs;
      list<BackendDAE.Var> bVars;
      list<BackendDAE.Equation> bEqs,sysEqs;
      BackendDAE.StrongComponents bComps,sysComps;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case (syst, shared, (BackendDAE.EQUATIONSYSTEM( eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(SOME(jac)),
                                                    jacType=BackendDAE.JAC_CONSTANT() )))
      equation
        //the A-matrix and the b-Vector are constant
        eqn_lst = BackendEquation.getList(eindex, syst.orderedEqs);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, syst.orderedVars);
        (syst,shared) = solveLinearSystem(syst, shared, eqn_lst, eindex, var_lst, vindx, jac);
      then (syst,shared,true,sysIdxIn,compIdxIn+1);

    case ( syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), shared,
           BackendDAE.EQUATIONSYSTEM( eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(SOME(jac)),
                                      jacType=BackendDAE.JAC_LINEAR() ) )
      equation
        true = BackendDAEUtil.isSimulationDAE(ishared);
        //only the A-matrix is constant, apply Gaussian Elimination
        eqn_lst = BackendEquation.getList(eindex, eqns);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        true = jacobianIsConstant(jac);
        true = Flags.isSet(Flags.CONSTJAC);
        //true = intEq(compIdxIn,37) and intEq(sysIdxIn,1);
        //print("ITS CONSTANT\n");
        //print("THE COMPIDX: "+intString(compIdxIn)+" THE SYSIDX"+intString(sysIdxIn)+"\n");
          //BackendDump.dumpEqnsSolved2({comp},eqns,vars);
        eqn_lst = BackendEquation.getList(eindex,eqns);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        (sysEqs, bEqs, bVars, order, sysIdx) =
            solveConstJacLinearSystem(syst, shared, eqn_lst, eindex, listReverse(var_lst), vindx, jac, sysIdxIn, compIdxIn);
          //print("the b-vector stuff \n");
          //BackendDump.printEquationList(bEqs);
          //BackendDump.printVarList(bVars);
          //print("the sysEqs stuff \n");
          //BackendDump.printEquationList(sysEqs);
        //build comps
          //print("size"+intString(BackendEquation.equationArraySize(eqns))+"\n");
          //print("numberOfElement"+intString(BackendEquation.getNumberOfEquations(eqns))+"\n");
          //print("arrSize"+intString(BackendDAEUtil.equationArraySize2(eqns))+"\n");
          //print("length"+intString(listLength(BackendEquation.equationList(eqns)))+"\n");
        bVarIdcs = List.intRange2(BackendVariable.varsSize(vars)+1, BackendVariable.varsSize(vars)+listLength(bVars));
        bEqIdcs = List.intRange2(BackendEquation.getNumberOfEquations(eqns)+1, BackendEquation.getNumberOfEquations(eqns)+listLength(bEqs));
        bComps = List.threadMap(bEqIdcs, bVarIdcs, BackendDAEUtil.makeSingleEquationComp);
        sysComps = List.threadMap( List.map1(arrayList(order), List.getIndexFirst, eindex), listReverse(vindx),
                                   BackendDAEUtil.makeSingleEquationComp );
          //print("bCOMPS\n");
          //BackendDump.dumpComponents(bComps);
          //print("SYSCOMPS\n");
          //BackendDump.dumpComponents(sysComps);
        //build system
        syst.orderedVars = List.fold(bVars, BackendVariable.addVar, vars);
        eqns = BackendEquation.addList(bEqs, eqns);
        syst.orderedEqs = List.threadFold(eindex, sysEqs, BackendEquation.setAtIndexFirst, eqns);
        syst = BackendDAEUtil.setEqSystMatrices(syst);
        syst = replaceStrongComponent(syst,compIdxIn,sysComps,bComps);
          //print("compIdxIn"+intString(compIdxIn)+"\n");
      then (syst, ishared, false, sysIdx, compIdxIn+listLength(sysComps));
    else (isyst, ishared, false, sysIdxIn, compIdxIn+1);
  end matchcontinue;
end constantLinearSystemWork;

protected function solveLinearSystem
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared ishared;
  input list<BackendDAE.Equation> eqn_lst;
  input list<Integer> eqn_indxs;
  input list<BackendDAE.Var> var_lst;
  input list<Integer> var_indxs;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst, oshared) := match (inSyst, ishared)
    local
      BackendDAE.Variables v;
      BackendDAE.EquationArray eqns, eqns1;
      list<DAE.Exp> beqs;
      list<DAE.ElementSource> sources;
      list<Real> rhsVals,solvedVals;
      list<list<Real>> jacVals;
      Integer linInfo;
      list<DAE.ComponentRef> names;
      DAE.FunctionTree funcs;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;

    case (syst as BackendDAE.EQSYSTEM(), BackendDAE.SHARED(functionTree=funcs))
      equation
        eqns1 = BackendEquation.listEquation(eqn_lst);
        v = BackendVariable.listVar1(var_lst);
        (beqs, sources) = BackendDAEUtil.getEqnSysRhs(eqns1, v, SOME(funcs));
        beqs = listReverse(beqs);
        rhsVals = ValuesUtil.valueReals(List.map(beqs, Ceval.cevalSimple));
        jacVals = evaluateConstantJacobian(listLength(var_lst), jac);
        (solvedVals, linInfo) = System.dgesv(jacVals, rhsVals);
        names = List.map(var_lst, BackendVariable.varCref);
        checkLinearSystem(linInfo, names, jacVals, rhsVals, eqn_lst);
        sources = List.map1( sources, ElementSource.addSymbolicTransformation,
                             DAE.LINEAR_SOLVED(names, jacVals, rhsVals, solvedVals) );
        (v, eqns, shared) = changeConstantLinearSystemVars( var_lst, solvedVals, sources, var_indxs,
                                                                           syst.orderedVars, syst.orderedEqs, ishared );
        syst.orderedVars = v;
        syst.orderedEqs = List.fold(eqn_indxs, BackendEquation.delete, eqns);
      then
        (BackendDAEUtil.setEqSystMatrices(syst), shared);
  end match;
end solveLinearSystem;

protected function changeConstantLinearSystemVars
  input list<BackendDAE.Var> inVarLst;
  input list<Real> inSolvedVals;
  input list<DAE.ElementSource> inSources;
  input list<Integer> var_indxs;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray ieqns;
  input BackendDAE.Shared ishared;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray oeqns;
  output BackendDAE.Shared oshared;
algorithm
    (outVars,oeqns,oshared) := match (inVarLst,inSolvedVals,inSources,var_indxs,inVars,ieqns,ishared)
    local
      BackendDAE.Var v,v1;
      list<BackendDAE.Var> varlst;
      DAE.ElementSource s;
      list<DAE.ElementSource> slst;
      BackendDAE.Variables vars,vars1,vars2;
      Real r;
      list<Real> rlst;
      BackendDAE.Shared shared;
      BackendDAE.EquationArray eqns;
      Integer indx;
      list<Integer> vindxs;
      DAE.ComponentRef cref;
      DAE.Type tp;
      DAE.Exp e;
    case ({},{},{},_,vars,eqns,_) then (vars,eqns,ishared);
    case ((BackendDAE.VAR(varName=cref,varKind=BackendDAE.STATE(),varType=tp))::varlst,r::rlst,_::slst,_::vindxs,vars,eqns,_)
      equation
        e = Expression.makeCrefExp(cref, tp);
        e = Expression.expDer(e);
        eqns = BackendEquation.add(BackendDAE.EQUATION(e, DAE.RCONST(r), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN), eqns);
        (vars2,eqns,shared) = changeConstantLinearSystemVars(varlst,rlst,slst,vindxs,vars,eqns,ishared);
      then (vars2,eqns,shared);
    case (v::varlst,r::rlst,_::slst,indx::vindxs,vars,eqns,_)
      equation
        v1 = BackendVariable.setBindExp(v, SOME(DAE.RCONST(r)));
        v1 = BackendVariable.setVarStartValue(v1,DAE.RCONST(r));
        // ToDo: merge source of var and equation
        (vars1,_) = BackendVariable.removeVar(indx, vars);
        shared = BackendVariable.addGlobalKnownVarDAE(v1,ishared);
        (vars2,eqns,shared) = changeConstantLinearSystemVars(varlst,rlst,slst,vindxs,vars1,eqns,shared);
      then (vars2,eqns,shared);
  end match;
end changeConstantLinearSystemVars;

public function evaluateConstantJacobian
  "Evaluate a constant Jacobian so we can solve a linear system during runtime"
  input Integer size;
  input list<tuple<Integer,Integer,BackendDAE.Equation>> jac;
  output list<list<Real>> vals;
protected
  array<array<Real>> valarr;
  list<array<Real>> tmp2;
algorithm
  valarr := evaluateConstantJacobianArray(size, jac);
  tmp2 := arrayList(valarr);
  vals := List.map(tmp2,arrayList);
end evaluateConstantJacobian;

protected function evaluateConstantJacobianArray
  "Evaluate a constant Jacobian so we can solve a linear system during runtime"
  input Integer size;
  input list<tuple<Integer,Integer,BackendDAE.Equation>> jac;
  output array<array<Real>> valarr;
protected
  array<Real> tmp;
  list<array<Real>> tmp2;
algorithm
  tmp := arrayCreate(size,0.0);
  tmp2 := List.map(List.fill(tmp,size),arrayCopy);
  valarr := listArray(tmp2);
  List.map1_0(jac,evaluateConstantJacobian2,valarr);
end evaluateConstantJacobianArray;

protected function evaluateConstantJacobian2
  input tuple<Integer,Integer,BackendDAE.Equation> jac;
  input array<array<Real>> vals;
algorithm
  _ := match (jac,vals)
    local
      DAE.Exp exp;
      Integer i1,i2;
      Real r;
    case ((i1,i2,BackendDAE.RESIDUAL_EQUATION(exp=exp)),_)
      equation
        Values.REAL(r) = Ceval.cevalSimple(exp);
        arrayUpdate(arrayGet(vals,i1),i2,r);
      then ();
  end match;
end evaluateConstantJacobian2;

protected function checkLinearSystem
  input Integer info;
  input list<DAE.ComponentRef> vars;
  input list<list<Real>> jac;
  input list<Real> rhs;
  input list<BackendDAE.Equation> eqnlst;
algorithm
  _ := matchcontinue (info,vars,jac,rhs,eqnlst)
    local
      String infoStr,syst,varnames,varname,rhsStr,jacStr,eqnstr;
    case (0,_,_,_,_) then ();
    case (_,_,_,_,_)
      equation
        true = info > 0;
        varname = ComponentReference.printComponentRefStr(listGet(vars,info));
        infoStr = intString(info);
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ;\n  ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ;\n  ");
        eqnstr = BackendDump.dumpEqnsStr(eqnlst);
        syst = stringAppendList({"\n",eqnstr,"\n[\n  ", jacStr, "\n]\n  *\n[\n  ",varnames,"\n]\n  =\n[\n  ",rhsStr,"\n]"});
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
      then fail();
    case (_,_,_,_,_)
      equation
        true = info < 0;
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ; ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ; ");
        eqnstr = BackendDump.dumpEqnsStr(eqnlst);
        syst = stringAppendList({eqnstr,"\n[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
      then fail();
  end matchcontinue;
end checkLinearSystem;

public function generateSparsePattern "author: wbraun
  Function generated for a given set of variables and
  equations the sparsity pattern and a coloring of Jacobian matrix A^(NxM).
    col: N = size(diffVars)
    rows : M = size(diffedVars)
  The sparsity pattern is represented basically as a list of lists, every list
  represents the non-zero elements of a row.

  The coloring is saved as a list of lists, every list contains the
  cols with the same color."
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inIndependentVars "vars";
  input list<BackendDAE.Var> inDependentVars "eqns";
  input Boolean nonlinearPattern = false;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outColoredCols;
protected
  constant Boolean debug = false;
  String patternName = if nonlinearPattern then "Nonlinear" else "Sparsity";
algorithm
  (outSparsePattern,outColoredCols) := matchcontinue(inBackendDAE,inIndependentVars,inDependentVars)
    local
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst, syst1;
      BackendDAE.StrongComponents comps;
      BackendDAE.AdjacencyMatrix adjMatrix, adjMatrixT;
      BackendDAE.Matching bdaeMatching;

      list<tuple<Integer, list<Integer>>>  sparseGraph, sparseGraphT;
      array<tuple<Integer, list<Integer>>> arraysparseGraph;

      Integer sizeN, sizeM, adjSize, adjSizeT;
      Integer nonZeroElements, maxColor;
      list<Integer> nodesList, nodesEqnsIndex;
      list<list<Integer>> sparsepattern,sparsepatternT, coloredlist;
      list<BackendDAE.Var> jacDiffVars, dependentVars, independentVars;
      BackendDAE.Variables varswithDiffs;
      BackendDAE.EquationArray orderedEqns;
      array<Option<list<Integer>>> forbiddenColor;
      array<Integer> colored, colored1, ass1, ass2;
      array<list<Integer>> coloredArray;

      list<DAE.ComponentRef> depCompRefsLst, inDepCompRefsLst;
      array<DAE.ComponentRef> depCompRefs, inDepCompRefs;

      array<list<Integer>> eqnSparse, varSparse, sparseArray, sparseArrayT;
      array<Integer> mark, usedvar;

      BackendDAE.SparseColoring coloring;
      list<list<DAE.ComponentRef>> translated;
      list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsetuple, sparsetupleT;

    // if there are no independent var, no pattern needed, otherwise there
    // is an empty pattern for the dependent variables
    case (_,_,{}) then (({},{},({},{}),-1),{});
    case(BackendDAE.DAE(eqs = (syst as BackendDAE.EQSYSTEM(matching=bdaeMatching as BackendDAE.MATCHING(comps=comps, ass1=ass1)))::{}),independentVars,dependentVars)
      algorithm
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print(" start getting " + patternName + " pattern for variables : " + intString(listLength(dependentVars))  + " and the independent vars: " + intString(listLength(independentVars)) +"\n");
        end if;
        if debug then execStat("generateSparsePattern -> do start "); end if;
        // prepare crefs
        depCompRefsLst := List.map(dependentVars, BackendVariable.varCref);
        depCompRefs := listArray(depCompRefsLst);
        sizeM := arrayLength(depCompRefs);

        // create jacobian vars
        (jacDiffVars,inDepCompRefsLst) := createInDepVars(independentVars);
        inDepCompRefs := listArray(inDepCompRefsLst);
        sizeN := arrayLength(inDepCompRefs);

        // generate adjacency matrix including diff vars
        (syst1 as BackendDAE.EQSYSTEM(orderedVars=varswithDiffs,orderedEqs=orderedEqns)) := BackendDAEUtil.addVarsToEqSystem(syst,jacDiffVars);
        (adjMatrix, adjMatrixT) := BackendDAEUtil.adjacencyMatrix(syst1,BackendDAE.SPARSE(),NONE(),BackendDAEUtil.isInitializationDAE(inBackendDAE.shared));
        adjSize := arrayLength(adjMatrix) "number of equations";
        adjSizeT := arrayLength(adjMatrixT) "number of variables";

        // Debug dumping
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          BackendDump.printVarList(BackendVariable.varList(varswithDiffs));
          BackendDump.printEquationList(BackendEquation.equationList(orderedEqns));
          BackendDump.dumpAdjacencyMatrix(adjMatrix);
          BackendDump.dumpAdjacencyMatrixT(adjMatrixT);
          BackendDump.dumpFullMatching(bdaeMatching);
        end if;

        // get indexes of diffed vars (rows)
        nodesEqnsIndex := BackendVariable.getVarIndexFromVars(dependentVars,varswithDiffs);
        nodesEqnsIndex := List.map1(nodesEqnsIndex, Array.getIndexFirst, ass1);

        // debug dump
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print("nodesEqnsIndexs: ");
          BackendDump.dumpAdjacencyRow(nodesEqnsIndex);
          print("\n");
          print("analytical Jacobians[" + patternName + "] -> build sparse graph: " + realString(clock()) + "\n");
        end if;

        // prepare data for getSparsePattern
        eqnSparse := arrayCreate(adjSize, {});
        varSparse := arrayCreate(adjSizeT, {});
        mark := arrayCreate(adjSizeT, 0);
        usedvar := arrayCreate(adjSizeT, 0);

        // make dependent variables as used if there are some
        // otherwise Array.setRange fails start is greater than end
        if (sizeN>0) then
          usedvar := Array.setRange(adjSizeT-(sizeN-1), adjSizeT, usedvar, 1);
        end if;

        if debug then execStat("generateSparsePattern -> start "); end if;
        eqnSparse := getSparsePattern(comps, eqnSparse, varSparse, mark, usedvar, 1, adjMatrix, adjMatrixT);
        if debug then execStat("generateSparsePattern -> end "); end if;
        // debug dump
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          BackendDump.dumpSparsePatternArray(eqnSparse);
          print("analytical Jacobians[" + patternName + "] -> prepared arrayList for transpose list: " + realString(clock()) + "\n");
        end if;

        // select nodesEqnsIndex and map index to incoming vars
        sparseArray := Array.select(eqnSparse, nodesEqnsIndex);
        sparsepattern := arrayList(sparseArray);

        sparsepattern := List.map1List(sparsepattern, intSub, adjSizeT-sizeN);
        sparseArray := listArray(sparsepattern);

        if debug then execStat("generateSparsePattern -> postProcess "); end if;

        // transpose the column-based pattern to row-based pattern
        sparseArrayT := arrayCreate(sizeN,{});
        sparseArrayT := transposeSparsePattern(sparsepattern, sparseArrayT, 1);
        sparsepatternT := arrayList(sparseArrayT);
        nonZeroElements := List.lengthListElements(sparsepattern);
        if debug then execStat("generateSparsePattern -> transpose done "); end if;

        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          // dump statistics
          dumpSparsePatternStatistics(nonZeroElements,sparsepatternT);
          BackendDump.dumpSparsePattern(sparsepattern);
          BackendDump.dumpSparsePattern(sparsepatternT);
          //execStat("generateSparsePattern -> nonZeroElements: " + intString(nonZeroElements) + " " ,ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        end if;

        // translated to DAE.ComRefs
        if listEmpty(sparsepattern) then
          sparsetuple := {};
          sparsetupleT := {};
        else
          translated := list(list(arrayGet(inDepCompRefs, i) for i in lst) for lst in sparsepattern);
          sparsetuple := list((cr,t) threaded for cr in depCompRefs, t in translated);
          translated := list(list(arrayGet(depCompRefs, i) for i in lst) for lst in sparsepatternT);
          sparsetupleT := list((cr,t) threaded for cr in inDepCompRefs, t in translated);
        end if;

        if debug then execStat("generateSparsePattern -> coloring start "); end if;
        if nonlinearPattern or Flags.isSet(Flags.DISABLE_COLORING) then
          //without coloring
          coloring := list({arrayGet(inDepCompRefs, i)} for i in 1:sizeN);
        else
          // get coloring based on sparse pattern
          coloredArray := createColoring(sparseArray, sparseArrayT, sizeN, sizeM);
          coloring := list(list(arrayGet(inDepCompRefs, i) for i in lst) for lst in coloredArray);
        end if;
        if debug then execStat("generateSparsePattern -> coloring done "); end if;

        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print("analytical Jacobians[" + patternName + "] -> ready! " + realString(clock()) + "\n");
        end if;

        outSparsePattern := (sparsetupleT, sparsetuple, (inDepCompRefsLst, depCompRefsLst), nonZeroElements);
        if Flags.isSet(Flags.DUMP_SPARSE) then
          BackendDump.dumpSparsityPattern(outSparsePattern, " --- " + patternName + " Pattern ---");
          BackendDump.dumpSparseColoring(coloring, " --- " + patternName + " Coloring ---");
        end if;
        if debug then execStat("generateSparsePattern -> final end "); end if;
      then (outSparsePattern, coloring);
    else
      algorithm
        Error.addInternalError("function generateSparsePattern failed", sourceInfo());
      then fail();
  end matchcontinue;
end generateSparsePattern;

public function createColoring
  input array<list<Integer>> sparseArray;
  input array<list<Integer>> sparseArrayT;
  input Integer sizeVars;
  input Integer sizeVarswithDep;
  output array<list<Integer>> coloredArray;
protected
  constant Boolean debug = false;
  list<Integer> nodesList;
  array<Integer> colored;
  array<Integer> forbiddenColor;
  list<tuple<Integer, list<Integer>>> sparseGraph, sparseGraphT;
  array<tuple<Integer, list<Integer>>> arraysparseGraph;
  Integer maxColor;
algorithm
  try
    // build up a bi-partied graph of pattern
    if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
      print("analytical Jacobians[SPARSE] -> build sparse graph.\n");
    end if;
    nodesList := List.intRange2(1,sizeVarswithDep);
    sparseGraph := Graph.buildGraph(nodesList,createBipartiteGraph,sparseArray);
    sparseGraphT := Graph.buildGraph(List.intRange2(1,sizeVars),createBipartiteGraph,sparseArrayT);

    // debug dump
    if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
      print("sparse graph: \n");
      Graph.printGraphInt(sparseGraph);
      print("transposed sparse graph: \n");
      Graph.printGraphInt(sparseGraphT);
      print("analytical Jacobians[SPARSE] -> builded graph for coloring.\n");
    end if;

    // color sparse bipartite graph
    forbiddenColor := arrayCreate(sizeVars,0);
    colored := arrayCreate(sizeVars,0);
    arraysparseGraph := listArray(sparseGraph);
    if debug then execStat("generateSparsePattern -> coloring start "); end if;
    if (sizeVars>0) then
      Graph.partialDistance2colorInt(sparseGraphT, forbiddenColor, nodesList, arraysparseGraph, colored);
    end if;
    if debug then execStat("generateSparsePattern -> coloring end "); end if;
    GCExt.free(forbiddenColor);
    GCExt.free(arraysparseGraph);
    // get max color used
    maxColor := Array.fold(colored, intMax, 0);

    // map index of that array into colors
    coloredArray := arrayCreate(maxColor, {});
    mapIndexColors(colored, sizeVars, coloredArray);
    GCExt.free(colored);

    if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
      print("Print Coloring Cols: \n");
      BackendDump.dumpSparsePattern(arrayList(coloredArray));
    end if;
  else
    Error.addInternalError("function createColoring failed", sourceInfo());
    fail();
  end try;
end createColoring;

protected function dumpSparsePatternStatistics
  input Integer nonZeroElements;
  input list<list<Integer>> sparsepatternT;
protected
  Integer maxDegree;
algorithm
  (_, maxDegree) := List.mapFold(sparsepatternT, findDegrees, 0);
  print("analytical Jacobians[SPARSE] -> got sparse pattern nonZeroElements: "+ String(nonZeroElements) + " maxNodeDegree: " + String(maxDegree) + " time : " + String(clock()) + "\n");
end dumpSparsePatternStatistics;

protected function findDegrees<T>
  input list<T> inList;
  input Integer inValue;
  output Integer outDegree;
  output Integer outMaxDegree;
algorithm
  outDegree := listLength(inList);
  outMaxDegree := intMax(inValue, outDegree);
end findDegrees;

protected function getSparsePattern
  input BackendDAE.StrongComponents inComponents;
  input array<list<Integer>> ineqnSparse; //
  input array<list<Integer>> invarSparse; //
  input array<Integer> inMark; //
  input array<Integer> inUsed; //
  input Integer inmarkValue;
  input BackendDAE.AdjacencyMatrix inMatrix;
  input BackendDAE.AdjacencyMatrix inMatrixT;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := match (inComponents, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue, inMatrix, inMatrixT)
  local
    list<Integer> vars, vars1, vars2, eqns, eqns1,  eqns2;
    list<Integer> inputVars;
    list<list<Integer>> inputVarsLst;
    list<Integer> solvedVars;
    array<list<Integer>> result;
    Integer var, eqn;
    BackendDAE.StrongComponents rest;
    BackendDAE.StrongComponent comp;
    BackendDAE.InnerEquations innerEquations;
    case ({}, result,_,_,_,_,_,_) then result;

    case(BackendDAE.SINGLEEQUATION(eqn=eqn,var=var)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.removeOnTrue(var, intEq, inputVars);

        getSparsePattern2(inputVars, {var}, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEARRAY(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEIFEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrixT, eqn);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEALGORITHM(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEWHENEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEIFEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.EQUATIONSYSTEM(eqns=eqns,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVarsLst = List.map1(eqns, Array.getIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=eqns,tearingvars=vars,innerEquations=innerEquations))::rest,result,_,_,_,_,_,_)
      equation
        (eqns1,inputVarsLst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        vars1 = List.flatten(inputVarsLst);
        eqns1 = listAppend(eqns, eqns1);
        solvedVars = listAppend(vars, vars1);

        inputVarsLst = List.map1(eqns1, Array.getIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = list(v for v guard not listMember(v, solvedVars) in inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns1, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    else
       equation
         (comp::_) = inComponents;
         BackendDump.dumpComponent(comp);
         Error.addInternalError("function getSparsePattern failed", sourceInfo());
       then fail();
  end match;
end getSparsePattern;

protected function getSparsePattern2
  input list<Integer> inInputVars;
  input list<Integer> inSolvedVars;
  input list<Integer> inEqns;
  input array<list<Integer>> ineqnSparse;
  input array<list<Integer>> invarSparse;
  input array<Integer> inMark;
  input array<Integer> inUsed;
  input Integer inmarkValue;
protected
  list<Integer> localList;
algorithm
  localList := getSparsePatternHelp(inInputVars, invarSparse, inMark, inUsed, inmarkValue);
  List.map2_0(inSolvedVars, Array.updateIndexFirst, localList, invarSparse);
  List.map2_0(inEqns, Array.updateIndexFirst, localList, ineqnSparse);
end getSparsePattern2;

protected function getSparsePatternHelp
  input list<Integer> inInputVars;
  input array<list<Integer>> invarSparse;
  input array<Integer> inMark;
  input array<Integer> inUsed;
  input Integer inmarkValue;
  output list<Integer> outLocalList = {};
protected
  Integer arrayElement;
  list<Integer> varSparse;
algorithm
  for var in inInputVars loop
    arrayElement := arrayGet(inUsed, var);
    if intEq(1, arrayElement) then
      arrayElement := arrayGet(inMark, var);
      if not intEq(inmarkValue, arrayElement) then
        arrayUpdate(inMark, var, inmarkValue);
        outLocalList := var::outLocalList;
      end if;
    end if;

    varSparse := arrayGet(invarSparse, var);
    for v in varSparse loop
      arrayElement := arrayGet(inMark, v);
      if not intEq(inmarkValue, arrayElement) then
        arrayUpdate(inMark, v, inmarkValue);
        outLocalList := v::outLocalList;
      end if;
    end for;
  end for;
end getSparsePatternHelp;

public function transposeSparsePattern
  input list<list<Integer>> inSparsePattern;
  input array<list<Integer>> inAccumList;
  input Integer inValue;
  output array<list<Integer>> outSparsePattern = inAccumList;
protected
  Integer value = inValue;
  list<Integer> tmplist;
algorithm
  for oneList in inSparsePattern loop
    for oneElem in oneList loop
      tmplist := arrayGet(outSparsePattern,oneElem);
      MetaModelica.Dangerous.arrayUpdateNoBoundsChecking(outSparsePattern, oneElem, value::tmplist);
    end for;
    value := value + 1;
  end for;
end transposeSparsePattern;

public function transposeSparsePatternTuple
  input list<tuple<Integer, list<Integer>>> inSparsePattern;
  input array<tuple<Integer,list<Integer>>> inAccumList;
  output array<tuple<Integer,list<Integer>>> outSparsePattern = inAccumList;
protected
  Integer value;
  list<Integer> tmplist;
  list<Integer> oneList;
  tuple<Integer,list<Integer>> tmpTuple;
  Integer i;
algorithm
  for oneListTuple in inSparsePattern loop
    (value, oneList) := oneListTuple;
    for oneElem in oneList loop
      tmpTuple := arrayGet(outSparsePattern,oneElem+1);
      (_, tmplist) := tmpTuple;
      tmplist := value::tmplist;
      tmpTuple := (oneElem, tmplist);
      MetaModelica.Dangerous.arrayUpdateNoBoundsChecking(outSparsePattern, oneElem+1, tmpTuple);
    end for;
  end for;
  // sort all transposed lists
  for i in 1:listLength(inSparsePattern) loop
    tmpTuple := arrayGet(outSparsePattern,i);
    (value, tmplist) := tmpTuple;
    tmplist := List.heapSortIntList(tmplist);
    tmpTuple := (value, tmplist);
    MetaModelica.Dangerous.arrayUpdateNoBoundsChecking(outSparsePattern, i, tmpTuple);
  end for;
end transposeSparsePatternTuple;

protected function mapIndexColors
  input array<Integer> inColors;
  input Integer inMaxIndex;
  input array<list<Integer>> inArray;
protected
  Integer index;
algorithm
  try
    for i in 1:inMaxIndex loop
      index := arrayGet(inColors, i);
      arrayUpdate(inArray, index, i::arrayGet(inArray, index));
    end for;
  else
    Error.addInternalError("function mapIndexColors failed", sourceInfo());
    fail();
  end try;
end mapIndexColors;

protected function createBipartiteGraph
  input Integer inNode;
  input array<list<Integer>> inSparsePattern;
  output list<Integer> outEdges = {};
algorithm
  if inNode >= 1 and inNode <= arrayLength(inSparsePattern)  then
    outEdges := arrayGet(inSparsePattern,inNode);
  else
    outEdges := {};
  end if;
end createBipartiteGraph;

protected function createInDepVars
"This function creates variables for the dependecy
analysis, this needs to cosider different behavoir
clock stated and continuous states.
continuous states: der(x) > dependent and x > independent
clocked states: previous(x) > independent and x > dependent
"
  input list<BackendDAE.Var> independentVars;
  input Boolean createpDerStates = true;
  output list<BackendDAE.Var> outVars = {};
  output list<DAE.ComponentRef> outCrefs = {};
protected
  BackendDAE.Var var;
algorithm
  for v in independentVars loop
    if BackendVariable.isClockedStateVar(v) then
      var :=  BackendVariable.createClockedState(v);
      outVars := var::outVars;
      outCrefs := var.varName::outCrefs;
    elseif createpDerStates then
      outVars := BackendVariable.createpDerVar(v)::outVars;
      outCrefs := v.varName::outCrefs;
    else
      outVars := v::outVars;
      outCrefs := v.varName::outCrefs;
    end if;
  end for;
  outVars := listReverse(outVars);
  outCrefs := listReverse(outCrefs);
end createInDepVars;

public function createFMIModelDerivatives
"This function genererate the stucture output and the
 partial derivatives for FMI, which are basically the jacobian matrices.
 author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.SymbolicJacobians outJacobianMatrices = {};
  output DAE.FunctionTree outFunctionTree;
protected
  BackendDAE.BackendDAE backendDAE,emptyBDAE;
  BackendDAE.EqSystem eqSyst;
  Option<BackendDAE.SymbolicJacobian> outJacobian;

  list<BackendDAE.Var> varlst, knvarlst, states, inputvars, outputvars, paramvars, indepVars, depVars;

  BackendDAE.Variables v,globalKnownVars,statesarr,inputvarsarr,paramvarsarr,outputvarsarr, depVarsArr;

  BackendDAE.SparsePattern sparsePattern;
  BackendDAE.SparseColoring sparseColoring;
  BackendDAE.NonlinearPattern nonlinearPattern;

  DAE.FunctionTree funcs, functionTree;

  BackendDAE.ExtraInfo ei;
  FCore.Cache cache;
  FCore.Graph graph;
algorithm
try
  // for now perform on collapsed system
  backendDAE := BackendDAEUtil.copyBackendDAE(inBackendDAE);
  backendDAE := BackendDAEOptimize.collapseIndependentBlocks(backendDAE);
  backendDAE := BackendDAEUtil.transformBackendDAE(backendDAE,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());

  // get all variables
  eqSyst::{} := backendDAE.eqs;
  v := eqSyst.orderedVars;
  globalKnownVars := backendDAE.shared.globalKnownVars;

  // prepare all needed variables
  varlst := BackendVariable.varList(v);
  knvarlst := BackendVariable.varList(globalKnownVars);

  states := if Config.languageStandardAtLeast(Config.LanguageStandard.'3.3') then
    BackendVariable.getAllClockedStatesFromVariables(v) else {};

  states := listAppend(BackendVariable.getAllStateVarFromVariables(v), states);

  inputvars := List.select(knvarlst,BackendVariable.isVarOnTopLevelAndInput);
  outputvars := List.select(varlst, BackendVariable.isVarOnTopLevelAndOutput);

  // independent varibales states + inputs
  indepVars := listAppend(states, inputvars);

  // dependent varibales der(states) + outputs
  depVars := listAppend(states, outputvars);

  // Generate sparse pattern for matrices states
  // prepare more needed variables
  if Flags.isSet(Flags.DIS_SYMJAC_FMI20) then
    // empty BackendDAE in case derivates should not calclulated
    cache := backendDAE.shared.cache;
    graph := backendDAE.shared.graph;
    ei := backendDAE.shared.info;
    emptyBDAE := BackendDAE.DAE({BackendDAEUtil.createEqSystem(BackendVariable.emptyVars(), BackendEquation.emptyEqns())}, BackendDAEUtil.createEmptyShared(BackendDAE.JACOBIAN(), ei, cache, graph));

    (sparsePattern, sparseColoring) := generateSparsePattern(backendDAE, indepVars, depVars);
    if Flags.isSet(Flags.JAC_DUMP2) then
      BackendDump.dumpSparsityPattern(sparsePattern, "FMI sparsity");
    end if;
    outJacobianMatrices := (SOME((emptyBDAE,"FMIDER",{},{},{}, {})), sparsePattern, sparseColoring, BackendDAE.emptyNonlinearPattern)::outJacobianMatrices;
    outFunctionTree := inBackendDAE.shared.functionTree;
  else
    // prepare more needed variables
    paramvars := List.select(knvarlst, BackendVariable.isParam);
    statesarr := BackendVariable.listVar1(states);
    inputvarsarr := BackendVariable.listVar1(inputvars);
    paramvarsarr := BackendVariable.listVar1(paramvars);
    depVarsArr := BackendVariable.listVar1(depVars);

    (outJacobian, outFunctionTree, sparsePattern, sparseColoring, nonlinearPattern) := generateGenericJacobian(backendDAE,indepVars,statesarr,inputvarsarr,paramvarsarr,depVarsArr,varlst,"FMIDER", Flags.isSet(Flags.DIS_SYMJAC_FMI20));
    if Flags.isSet(Flags.JAC_DUMP2) then
      BackendDump.dumpSparsityPattern(sparsePattern, "FMI sparsity");
    end if;
    outJacobianMatrices := (outJacobian, sparsePattern, sparseColoring, nonlinearPattern)::outJacobianMatrices;
    outFunctionTree := DAE.AvlTreePathFunction.join(inBackendDAE.shared.functionTree, outFunctionTree);
  end if;
else
  Error.addInternalError("function createFMIModelDerivatives failed", sourceInfo());
  outJacobianMatrices := {};
  outFunctionTree := inBackendDAE.shared.functionTree;
end try;
end createFMIModelDerivatives;

public function createFMIModelDerivativesForInitialization
"This function genererate the stucture output and the
 partial derivatives for FMI, which are basically the jacobian matrices."
  input BackendDAE.BackendDAE initDAE;
  input BackendDAE.BackendDAE simDAE;
  input list<BackendDAE.Var> depVars;
  input list<BackendDAE.Var> indepVars;
  input BackendDAE.Variables orderedVars;
  input BackendDAE.SparsePattern sparsePattern_;
  input BackendDAE.SparseColoring sparseColoring_;
  output BackendDAE.SymbolicJacobians outJacobianMatrices = {};
protected
  BackendDAE.BackendDAE backendDAE, backendDAE_1, emptyBDAE;
  BackendDAE.EqSystem eqSyst, currentSystem;
  Option<BackendDAE.SymbolicJacobian> outJacobian;
  list<BackendDAE.Var> varlst, knvarlst, states, inputvars, outputvars, paramvars, indepVars_1, depVars_1;
  BackendDAE.Variables v, globalKnownVars, statesarr, inputvarsarr, paramvarsarr, outputvarsarr, depVarsArr;
  BackendDAE.SparsePattern sparsePattern;
  BackendDAE.SparseColoring sparseColoring;
  DAE.FunctionTree funcs, functionTree;
  BackendDAE.ExtraInfo ei;
  FCore.Cache cache;
  FCore.Graph graph;
  BackendDAE.EquationArray newEqArray, newOrderedEquationArray;
  BackendDAE.Shared shared;
  DAE.Exp lhs, rhs;
  BackendDAE.Equation eqn;
  list<Integer> eqlistToRemove;
  DAE.ComponentRef cr;
  list<DAE.ComponentRef> crefsVarsToRemove;
  BackendDAE.Variables newVars;
algorithm
try

  backendDAE_1 := BackendDAEUtil.copyBackendDAE(initDAE);
  backendDAE_1 := BackendDAEOptimize.collapseIndependentBlocks(backendDAE_1);

  //BackendDump.printBackendDAE(backendDAE_1);
  //BackendDump.dumpVariables(simDAE.shared.globalKnownVars, "check global vars");

  /* add the calculated parameter equations here which does not have constant binding
   parameter Real x = 10;
   Real m = x; */
  BackendDAE.DAE(currentSystem::{}, shared) := backendDAE_1;
  for var in depVars loop
    if BackendVariable.isParam(var) and not BackendVariable.varHasConstantBindExp(var) then
      //print("\n PARAM_CHECK: " + ComponentReference.printComponentRefStr(var.varName));
      lhs := BackendVariable.varExp(var);
      rhs := BackendVariable.varBindExpStartValueNoFail(var) "bindings are optional";
      eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
      //BackendDump.printEquation(eqn);
      BackendEquation.add(eqn, currentSystem.orderedEqs);
      if not BackendVariable.containsCref(var.varName, currentSystem.orderedVars) then
        currentSystem := BackendVariable.addVarDAE(BackendVariable.makeVar(var.varName), currentSystem);
      end if;
    end if;
  end for;

  // remove equations and vars of the form a = $START.b from Eqsyst to simplify jacobian calculations
  newOrderedEquationArray := BackendEquation.emptyEqns();
  crefsVarsToRemove:= {};
  for eq in BackendEquation.equationList(currentSystem.orderedEqs) loop
    if not BackendEquation.isAlgorithm(eq) then
      lhs := BackendEquation.getEquationLHS(eq);
      rhs := BackendEquation.getEquationRHS(eq);
      // print("\nlhs :" + anyString(lhs));
      // print("\nrhs :" + anyString(rhs));
      // BackendDump.printEquation(eq);
      if Expression.isExpCref(lhs) and Expression.isExpCref(rhs) and (ComponentReference.isStartCref(Expression.expCref(rhs)) and ComponentReference.crefEqual(ComponentReference.popCref(Expression.expCref(rhs)), Expression.expCref(lhs))) then
        crefsVarsToRemove := Expression.expCref(lhs) :: crefsVarsToRemove;
      else
        BackendEquation.add(eq, newOrderedEquationArray);
      end if;
    else
      BackendEquation.add(eq, newOrderedEquationArray);
    end if;
  end for;

  newVars := BackendVariable.emptyVars();
  for var in BackendVariable.varList(currentSystem.orderedVars) loop
    if not listMember(var.varName, crefsVarsToRemove) then
      newVars := BackendVariable.addVar(var, newVars);
    end if;
  end for;

  currentSystem := BackendDAEUtil.setEqSystEqs(currentSystem, newOrderedEquationArray);
  currentSystem := BackendDAEUtil.setEqSystVars(currentSystem, newVars);

  // put the shared globalknown Vars
  // for var in BackendVariable.varList(simDAE.shared.globalKnownVars) loop
  //   if not BackendVariable.containsCref(var.varName, currentSystem.orderedVars) then
  //     shared := BackendVariable.addGlobalKnownVarDAE(var, shared);
  //   end if;
  // end for;


  backendDAE_1 := BackendDAE.DAE({currentSystem}, shared);
  backendDAE_1 := BackendDAEUtil.transformBackendDAE(backendDAE_1, SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());

  //BackendDump.printBackendDAE(backendDAE_1);

  //prepare simulation DAE
  backendDAE := BackendDAEUtil.copyBackendDAE(simDAE);
  backendDAE := BackendDAEOptimize.collapseIndependentBlocks(backendDAE);

  eqSyst::{} := backendDAE.eqs;
  v := eqSyst.orderedVars;
  // get state var from simulation DAE
  states := if Config.languageStandardAtLeast(Config.LanguageStandard.'3.3') then
    BackendVariable.getAllClockedStatesFromVariables(v) else {};
  states := listAppend(BackendVariable.getAllStateVarFromVariables(v), states);

  // prepare all needed variables from initialization DAE
  varlst := BackendVariable.varList(currentSystem.orderedVars);
  knvarlst := BackendVariable.varList(simDAE.shared.globalKnownVars);
  //BackendDump.dumpVarList(knvarlst, "shared simulation DAE");
  inputvars := List.select(knvarlst, BackendVariable.isVarOnTopLevelAndInput);

  // Generate empty jacobian martices
  if Flags.isSet(Flags.DIS_SYMJAC_FMI20) then
    cache := initDAE.shared.cache;
    graph := initDAE.shared.graph;
    ei := initDAE.shared.info;
    emptyBDAE := BackendDAE.DAE({BackendDAEUtil.createEqSystem(BackendVariable.emptyVars(), BackendEquation.emptyEqns())}, BackendDAEUtil.createEmptyShared(BackendDAE.JACOBIAN(), ei, cache, graph));
    outJacobianMatrices := (SOME((emptyBDAE,"FMIDERINIT",{},{},{}, {})), BackendDAE.emptySparsePattern, {}, BackendDAE.emptyNonlinearPattern)::outJacobianMatrices;
  else
    // prepare more needed variables
    paramvars := List.select(knvarlst, BackendVariable.isParam);
    statesarr := BackendVariable.listVar1(states);
    inputvarsarr := BackendVariable.listVar1(inputvars);
    paramvarsarr := BackendVariable.listVar1(paramvars);
    depVarsArr := BackendVariable.listVar1(depVars);

    //(outJacobian, outFunctionTree, _, _) := generateGenericJacobian(backendDAE_1, indepVars, BackendVariable.emptyVars(), BackendVariable.emptyVars(), BackendVariable.emptyVars(), depVarsArr, depVars, "FMIDERINIT", Flags.isSet(Flags.DIS_SYMJAC_FMI20));
    (outJacobian, _, _, _) := generateGenericJacobian(backendDAE_1, indepVars, statesarr, inputvarsarr, paramvarsarr, depVarsArr, varlst, "FMIDERINIT", Flags.isSet(Flags.DIS_SYMJAC_FMI20));

    if Flags.isSet(Flags.JAC_DUMP2) then
      BackendDump.dumpSparsityPattern(sparsePattern_, "FMI sparsity");
    end if;
    // kabdelhak: maybe also pass nonlinearity pattern to add it here
    outJacobianMatrices := (outJacobian, sparsePattern_, sparseColoring_, BackendDAE.emptyNonlinearPattern)::outJacobianMatrices;
  end if;
else
  Error.addInternalError("function createFMIModelDerivativesForInitialization failed", sourceInfo());
  outJacobianMatrices := {};
end try;
end createFMIModelDerivativesForInitialization;

protected function createLinearModelMatrices "This function creates the linear model matrices column-wise
  author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  input Boolean useOptimica;
  output BackendDAE.SymbolicJacobians outJacobianMatrices;
  output DAE.FunctionTree outFunctionTree;

algorithm
  (outJacobianMatrices, outFunctionTree) :=
  match (inBackendDAE, useOptimica)
    local
      BackendDAE.BackendDAE backendDAE,backendDAE2,emptyBDAE;

      list<BackendDAE.Var>  varlst, knvarlst,  states, inputvars, inputvars2, outputvars, paramvars, states_inputs, conVarsList, fconVarsList, object;
      list<DAE.ComponentRef> comref_states, comref_inputvars, comref_outputvars, comref_vars, comref_knvars;
      DAE.ComponentRef leftcref;

      BackendDAE.Variables v,globalKnownVars,statesarr,inputvarsarr,paramvarsarr,outputvarsarr, optimizer_vars, conVars;
      BackendDAE.EquationArray e;

      BackendDAE.SymbolicJacobians linearModelMatrices;
      Option<BackendDAE.SymbolicJacobian> linearModelMatrix;

      BackendDAE.SparsePattern sparsePattern;
      BackendDAE.SparseColoring sparseColoring;
      BackendDAE.NonlinearPattern nonlinearPattern;

      DAE.FunctionTree funcs, functionTree;
      list<DAE.Function> funcLst;

      BackendDAE.ExtraInfo ei;
      FCore.Cache cache;
      FCore.Graph graph;

    case (backendDAE, false)
      equation
        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)}, BackendDAE.SHARED(globalKnownVars = globalKnownVars)) = backendDAE2;

        // Prepare all needed variables
        varlst = BackendVariable.varList(v);
        knvarlst = BackendVariable.varList(globalKnownVars);
        states = BackendVariable.getAllStateVarFromVariables(v);
        inputvars = List.select(knvarlst,BackendVariable.isInput);
        paramvars = List.select(knvarlst, BackendVariable.isParam);
        inputvars2 = List.select(knvarlst,BackendVariable.isVarOnTopLevelAndInput);
        outputvars = List.select(varlst, BackendVariable.isVarOnTopLevelAndOutput);

        statesarr = BackendVariable.listVar1(states);
        inputvarsarr = BackendVariable.listVar1(inputvars);
        paramvarsarr = BackendVariable.listVar1(paramvars);
        outputvarsarr = BackendVariable.listVar1(outputvars);

        // Differentiate the System w.r.t states for matrices A
        (linearModelMatrix, functionTree, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"A",false);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = {(linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern)};
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix A time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t inputs for matrices B
        (linearModelMatrix, funcs, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2,inputvars2,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"B",false);
        functionTree = DAE.AvlTreePathFunction.join(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = (linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern) :: linearModelMatrices;
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix B time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t states for matrices C
        (linearModelMatrix, funcs, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,outputvarsarr,varlst,"C",false);
        functionTree = DAE.AvlTreePathFunction.join(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = (linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern) :: linearModelMatrices;
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix C time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t inputs for matrices D
        (linearModelMatrix, funcs, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2,inputvars2,statesarr,inputvarsarr,paramvarsarr,outputvarsarr,varlst,"D",false);
        functionTree = DAE.AvlTreePathFunction.join(functionTree, funcs);
        linearModelMatrices = (linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern) :: linearModelMatrices;
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix D time: " + realString(clock()) + "\n");
        end if;

      then
        (listReverse(linearModelMatrices), functionTree);

    case (backendDAE, true) //  created linear model (matrices) for optimization
      equation
        // A := der(x)
        // B := {der(x), con(x), L(x)}
        // C := {der(x), con(x), L(x), M(x)}
        // D := {}

        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)}, BackendDAE.SHARED(globalKnownVars = globalKnownVars)) = backendDAE2;

        // Prepare all needed variables
        varlst = BackendVariable.varList(v);
        knvarlst = BackendVariable.varList(globalKnownVars);
        states = BackendVariable.getAllStateVarFromVariables(v);
        inputvars = List.select(knvarlst,BackendVariable.isInput);
        paramvars = List.select(knvarlst, BackendVariable.isParam);
        inputvars2 = List.select(knvarlst,BackendVariable.isVarOnTopLevelAndInputNoDerInput); // without der(u)
        outputvars = List.select(varlst, BackendVariable.isVarOnTopLevelAndOutput);
        conVarsList = List.select(varlst, BackendVariable.isRealOptimizeConstraintsVars);
        fconVarsList = List.select(varlst, BackendVariable.isRealOptimizeFinalConstraintsVars); // ToDo: FinalCon

        states_inputs = listAppend(states, inputvars2);
        statesarr = BackendVariable.listVar1(states);
        inputvarsarr = BackendVariable.listVar1(inputvars);
        paramvarsarr = BackendVariable.listVar1(paramvars);
        outputvarsarr = BackendVariable.listVar1(outputvars);
        conVars = BackendVariable.listVar1(conVarsList);

        //BackendDump.printVariables(conVars);
        //BackendDump.printVariables(object);
        //print(intString(BackendVariable.varsSize(object)));
        //object = BackendVariable.listVar1(object);

        // Differentiate the System w.r.t states for matrices A
        (linearModelMatrix, functionTree, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"A",false);

        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = {(linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern)};
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix A time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t states&inputs for matrices B

        optimizer_vars = BackendVariable.addVariables(statesarr, BackendVariable.copyVariables(conVars));
        object = DynamicOptimization.checkObjectIsSet(outputvarsarr, BackendDAE.optimizationLagrangeTermName);
        optimizer_vars = BackendVariable.addVars(object, optimizer_vars);
        //BackendDump.printVariables(optimizer_vars);
        (linearModelMatrix, funcs, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2,states_inputs,statesarr,inputvarsarr,paramvarsarr,optimizer_vars,varlst,"B",false);
        functionTree = DAE.AvlTreePathFunction.join(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = (linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern) :: linearModelMatrices;
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix B time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t states for matrices C
        object = DynamicOptimization.checkObjectIsSet(outputvarsarr, BackendDAE.optimizationMayerTermName);
        optimizer_vars = BackendVariable.addVars(object, optimizer_vars);
        //BackendDump.printVariables(optimizer_vars);
        (linearModelMatrix, funcs, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2,states_inputs,statesarr,inputvarsarr,paramvarsarr,optimizer_vars,varlst,"C",false);
        functionTree = DAE.AvlTreePathFunction.join(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = (linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern) :: linearModelMatrices;
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix C time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t inputs for matrices D
        optimizer_vars = BackendVariable.emptyVars();
        optimizer_vars = BackendVariable.listVar1(fconVarsList);

        (linearModelMatrix, funcs, sparsePattern, sparseColoring, nonlinearPattern) = generateGenericJacobian(backendDAE2, states_inputs, statesarr, inputvarsarr, paramvarsarr, optimizer_vars, varlst, "D", false);
        functionTree = DAE.AvlTreePathFunction.join(functionTree, funcs);
        linearModelMatrices = (linearModelMatrix,sparsePattern,sparseColoring, nonlinearPattern) :: linearModelMatrices;
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix D time: " + realString(clock()) + "\n");
        end if;

      then
        (listReverse(linearModelMatrices), functionTree);
    else
      equation
        Error.addInternalError("Generation of LinearModel Matrices failed.", sourceInfo());
      then
        fail();
  end match;
end createLinearModelMatrices;

protected function generateGenericJacobian "author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inDiffVars "independent vars";
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParameterVars "globalKnownVars";
  input BackendDAE.Variables inDifferentiatedVars "resVars";
  input list<BackendDAE.Var> inVars "dependent vars = resVars + other vars";
  input String inName;
  input Boolean onlySparsePattern;
  input Boolean daeMode = false;
  output Option<BackendDAE.SymbolicJacobian> outJacobian;
  output DAE.FunctionTree outFunctionTree;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outSparseColoring;
  output BackendDAE.NonlinearPattern nonlinearPattern;
protected
  BackendDAE.SymbolicJacobian symbolicJacobian;
  BackendDAE.Shared shared = inBackendDAE.shared;
  BackendDAE.BackendDAE jacDAE;
  list<BackendDAE.Var> jacDiffedVars;
algorithm
  try
    outFunctionTree := shared.functionTree;
    if not onlySparsePattern then
      (symbolicJacobian, outFunctionTree) := createJacobian(inBackendDAE,inDiffVars, inStateVars, inInputVars, inParameterVars, inDifferentiatedVars, inVars, inName, daeMode);
      true := checkForNonLinearStrongComponents(symbolicJacobian);
      outJacobian := SOME(symbolicJacobian);
      // nonlinear pattern is the same as the sparse pattern of the jacobian
      (jacDAE, _, _, _,  _, _) := symbolicJacobian;
      jacDiffedVars := getJacobianResiduals(jacDAE);
      // copy the jacobian DAE to avoid wrong variables being added
      (nonlinearPattern, _) := generateSparsePattern(BackendDAEUtil.copyBackendDAE(jacDAE), inDiffVars, jacDiffedVars, true);
      nonlinearPattern := stripPartialDerNonlinearPattern(nonlinearPattern);
    else
      outJacobian := NONE();
      // no jacobian -> no nonlinear pattern
      nonlinearPattern := BackendDAE.emptyNonlinearPattern;
    end if;
    // generate sparse pattern
    if (not stringEq(inName, "FMIDERINIT")) then
      (outSparsePattern,outSparseColoring) := generateSparsePattern(inBackendDAE, inDiffVars, BackendVariable.varList(inDifferentiatedVars));
    end if;
  else
    fail();
  end try;
end generateGenericJacobian;

protected function createJacobian "author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inDiffVars "independent vars";
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParameterVars "globalKnownVars";
  input BackendDAE.Variables inDifferentiatedVars "resVars";
  input list<BackendDAE.Var> inVars "dependent vars = resVars + other vars";
  input String inName;
  input Boolean daeMode;
  output BackendDAE.SymbolicJacobian outJacobian;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outJacobian, outFunctionTree) :=
  matchcontinue (inBackendDAE,inDiffVars,inStateVars,inInputVars,inParameterVars,inDifferentiatedVars,inVars,inName)
    local
      BackendDAE.BackendDAE backendDAE, reducedDAE;

      list<DAE.ComponentRef> comref_vars, comref_differentiatedVars, dependencies;

      BackendDAE.Shared shared;
      BackendDAE.Variables  globalKnownVars, globalKnownVars1;
      list<BackendDAE.Var> diffedVars "resVars", seedlst, indepVars;

      DAE.FunctionTree funcs;

    case (_,_,_,_,_,_,_,_)
      equation
        diffedVars = BackendVariable.varList(inDifferentiatedVars);
        comref_differentiatedVars = List.map(diffedVars, BackendVariable.varCref);

        reducedDAE = BackendDAEUtil.reduceEqSystemsInDAE(inBackendDAE, diffedVars);

        indepVars = createInDepVars(inDiffVars, false);
        comref_vars = List.map(inDiffVars, BackendVariable.varCref);
        seedlst = List.map1(comref_vars, createSeedVars, inName);

        if Flags.isSet(Flags.JAC_DUMP) then
          print("Create symbolic Jacobians from:\n");
          print(BackendDump.varListString(indepVars, "Independent Variables"));
          print(BackendDump.varListString(diffedVars, "Dependent Variables"));
          print("Basic equation system:\n");
          print(BackendDump.equationListString(BackendEquation.equationSystemsEqnsLst(reducedDAE.eqs), "differentiated equations"));
          print(BackendDump.varListString(BackendVariable.equationSystemsVarsLst(reducedDAE.eqs), "related variables"));
          print(BackendDump.varListString(BackendVariable.varList(reducedDAE.shared.globalKnownVars), "known variables"));
        end if;

        // Differentiate the eqns system in reducedDAE w.r.t. independents
        (backendDAE as BackendDAE.DAE(), funcs) = generateSymbolicJacobian(reducedDAE, indepVars, inDifferentiatedVars, BackendVariable.listVar1(seedlst), inStateVars, inInputVars, inParameterVars, inName, daeMode);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated equations for Jacobian " + inName + " time: " + realString(clock()) + "\n");
        end if;

        // Add the function tree to the jacobian backendDAE
        backendDAE = BackendDAEUtil.setFunctionTree(backendDAE, funcs);

        backendDAE = optimizeJacobianMatrix(backendDAE,comref_differentiatedVars,comref_vars);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated Jacobian DAE time: " + realString(clock()) + "\n");
        end if;
        dependencies = calcJacobianDependencies((backendDAE, "", {}, {}, {}, {}));

     then
        ((backendDAE, inName, inDiffVars, diffedVars, inVars, dependencies), funcs);
    else
      equation
        Error.addInternalError("function createJacobian failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end createJacobian;

protected function optimizeJacobianMatrix "author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<DAE.ComponentRef> inComRef1 "eqnvars";
  input list<DAE.ComponentRef> inComRef2 "vars to differentiate";
  output BackendDAE.BackendDAE outJacobian;
protected
  array<Integer> ea = listArray({});
  BackendDAE.Matching eMatching = BackendDAE.MATCHING(ea, ea, {});
algorithm
  outJacobian :=
    matchcontinue (inBackendDAE,inComRef1,inComRef2)
    local
      BackendDAE.BackendDAE backendDAE, backendDAE2;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Boolean b;
      String addRemoveConstantEqnsModule;
      list<String> strPostOptModules;

      case (BackendDAE.DAE(syst::{}, shared), {}, _)
        equation
          syst.orderedVars = BackendVariable.listVar({});
          syst.matching = eMatching;
        then BackendDAE.DAE(syst::{}, shared);
      case (BackendDAE.DAE(syst::{}, shared), _, {})
        equation
          syst.orderedVars = BackendVariable.listVar({});
          syst.matching = eMatching;
        then BackendDAE.DAE(syst::{}, shared);
      case (backendDAE, _, _)
        equation
          if Flags.isSet(Flags.JAC_DUMP2) then
            print("analytical Jacobians -> optimize jacobians time: " + realString(clock()) + "\n");
          end if;

          if Flags.isSet(Flags.JAC_DUMP) then
            BackendDump.bltdump("Symbolic Jacobian",backendDAE);
          else
            b = FlagsUtil.disableDebug(Flags.EXEC_STAT);
          end if;

          strPostOptModules = {"wrapFunctionCalls",
                               "inlineArrayEqn",
                               "constantLinearSystem",
                               "solveSimpleEquations",
                               "tearingSystem",
                               "calculateStrongComponentJacobians",
                               "removeConstants",
                               "simplifyTimeIndepFuncCalls"};

          // Add removeSimpleEquation to remove constant(= independent of seed) equations.
          if Flags.isSet(Flags.SPLIT_CONSTANT_PARTS_SYMJAC) then
            /* ToDo: removeSimpleEquation can't handle all sorts of equations inside the
             * jacobian BackendDAE. E.g. for equations lile
             * $cse14 := $DER$$PModelica$PMedia$PWater$PIF97_Utilities$PwaterBaseProp_ph(p[10], h[10], 0, 0, 1.0, 0.0);
             * from SteamPipe from ScalableTestsuite.
             * Add a new module which finds constant (= independent of seed) equations
             * and moves them to a different system.
             */
            strPostOptModules = List.insert(strPostOptModules, 4, "removeSimpleEquations");
          end if;

          backendDAE2 = BackendDAEUtil.getSolvedSystemforJacobians(backendDAE,
                                                                   {"removeEqualRHS",
                                                                    "removeSimpleEquations",
                                                                    "evalFunc"},
                                                                    NONE(),
                                                                    NONE(),
                                                                    strPostOptModules);
          if Flags.isSet(Flags.JAC_DUMP) then
            BackendDump.bltdump("Symbolic Jacobian",backendDAE2);
          else
            _ = FlagsUtil.set(Flags.EXEC_STAT, b);
          end if;
        then backendDAE2;
     else
       equation
         Error.addInternalError("function optimizeJacobianMatrix failed", sourceInfo());
       then fail();
   end matchcontinue;
end optimizeJacobianMatrix;

protected function generateSymbolicJacobian "author: lochel"
  input BackendDAE.BackendDAE inBackendDAE "reducedDAE (variables and equations needed to calculate resVars)";
  input list<BackendDAE.Var> inVars "independent vars";
  input BackendDAE.Variables inDiffedVars "resVars";
  input BackendDAE.Variables inSeedVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars "globalKnownVars";
  input String inMatrixName;
  input Boolean daeMode;
  output BackendDAE.BackendDAE outJacobian;
  output DAE.FunctionTree outFunctions;
algorithm
  (outJacobian,outFunctions) := matchcontinue(inBackendDAE, inVars, inDiffedVars, inSeedVars, inStateVars, inInputVars, inParamVars, inMatrixName)
    local
      BackendDAE.BackendDAE bDAE;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars, comref_diffvars, comref_diffedvars;
      DAE.ComponentRef x;
      String dummyVarName;

      BackendDAE.Variables diffVarsArr;
      BackendDAE.Variables stateVars;
      BackendDAE.Variables inputVars;
      BackendDAE.Variables paramVars;
      BackendDAE.Variables diffedVars "resVars";
      BackendDAE.BackendDAE jacobian;

      // BackendDAE
      BackendDAE.Variables orderedVars, jacOrderedVars; // ordered Variables, only states and alg. vars
      BackendDAE.Variables globalKnownVars, jacKnownVars; // Known variables, i.e. constants and parameters
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs; // ordered Equations
      BackendDAE.EquationArray removedEqs, jacRemovedEqs; // Removed equations a=b
      // end BackendDAE

      list<BackendDAE.Var> diffVars "independent vars", derivedVariables, diffedVarLst;
      list<BackendDAE.Equation> eqns, derivedEquations;

      list<list<BackendDAE.Equation>> derivedEquationslst;


      FCore.Cache cache;
      FCore.Graph graph;
      BackendDAE.Shared shared;

      String matrixName;
      array<Integer> ass2;
      list<Integer> assLst;

      BackendDAE.DifferentiateInputData diffData;

      BackendDAE.ExtraInfo ei;
      Integer size;

    case(BackendDAE.DAE(shared=BackendDAE.SHARED(cache=cache, graph=graph, info=ei, functionTree=functions)), {}, _, _, _, _, _, _) equation
      jacobian = BackendDAE.DAE( {BackendDAEUtil.createEqSystem(BackendVariable.emptyVars(), BackendEquation.emptyEqns())},
                                 BackendDAEUtil.createEmptyShared(BackendDAE.JACOBIAN(), ei, cache, graph));
    then (jacobian, functions);

    case( BackendDAE.DAE( BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, matching=BackendDAE.MATCHING(ass2=ass2))::{},
                         BackendDAE.SHARED(globalKnownVars=globalKnownVars, cache=cache,graph=graph, functionTree=functions, info=ei) ),
          diffVars, diffedVars, _, _, _, _, matrixName ) equation
      // Generate tmp variables
      dummyVarName = ("dummyVar" + matrixName);
      x = DAE.CREF_IDENT(dummyVarName,DAE.T_REAL_DEFAULT,{});

      // differentiate the equation system
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("*** analytical Jacobians -> derived all algorithms time: " + realString(clock()) + "\n");
      end if;
      diffVarsArr = BackendVariable.listVar1(diffVars);
      comref_diffvars = List.map(diffVars, BackendVariable.varCref);
      diffData = BackendDAE.emptyInputData;
      diffData.independenentVars = SOME(diffVarsArr);
      diffData.dependenentVars = SOME(diffedVars);
      diffData.knownVars = SOME(globalKnownVars);
      diffData.allVars = SOME(orderedVars);
      diffData.diffCrefs = comref_diffvars;
      diffData.matrixName = SOME(matrixName);
      eqns = BackendEquation.equationList(orderedEqs);
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("*** analytical Jacobians -> before derive all equation: " + realString(clock()) + "\n");
      end if;
      (derivedEquations, functions) = deriveAll(eqns, arrayList(ass2), x, diffData, functions, daeMode);
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("*** analytical Jacobians -> after derive all equation: " + realString(clock()) + "\n");
      end if;
      // replace all der(x), since ExpressionSolve can't handle der(x) proper
      derivedEquations = BackendEquation.replaceDerOpInEquationList(derivedEquations);
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("*** analytical Jacobians -> created all derived equation time: " + realString(clock()) + "\n");
      end if;

      // create BackendDAE.DAE with differentiated vars and equations

      // all variables for new equation system
      // d(ordered vars)/d(dummyVar)
      diffVars = BackendVariable.varList(orderedVars);
      derivedVariables = createAllDiffedVars(diffVars, x, diffedVars, matrixName);

      jacOrderedVars = BackendVariable.listVar1(derivedVariables);
      // known vars: all variable from original system + seed
      size = BackendVariable.varsSize(orderedVars) +
             BackendVariable.varsSize(globalKnownVars) +
             BackendVariable.varsSize(inSeedVars);
      jacKnownVars = BackendVariable.emptyVarsSized(size);
      jacKnownVars = BackendVariable.addVariables(inSeedVars, jacKnownVars);
      (jacKnownVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(jacKnownVars, BackendVariable.setVarDirectionTpl, (DAE.INPUT()));
      jacKnownVars = BackendVariable.addVariables(orderedVars, jacKnownVars);
      jacKnownVars = BackendVariable.addVariables(globalKnownVars, jacKnownVars);
      jacOrderedEqs = BackendEquation.listEquation(derivedEquations);


      shared = BackendDAEUtil.createEmptyShared(BackendDAE.JACOBIAN(), ei, cache, graph);

      jacobian = BackendDAE.DAE( BackendDAEUtil.createEqSystem(jacOrderedVars, jacOrderedEqs)::{},
                                 BackendDAEUtil.setSharedGlobalKnownVars(shared, jacKnownVars) );
    then (jacobian, functions);

    else
     equation
      Error.addInternalError(getInstanceName() + " failed", sourceInfo());
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

public function createSeedVars "author: wbraun"
  input DAE.ComponentRef indiffVar;
  input String inMatrixName;
  output BackendDAE.Var outSeedVar;
protected
  DAE.ComponentRef derivedCref;
algorithm
  derivedCref := Differentiate.createSeedCrefName(indiffVar, inMatrixName);
  outSeedVar := BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.INPUT(), DAE.NON_PARALLEL(), ComponentReference.crefLastType(derivedCref), NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), NONE(),DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true, false, false);
end createSeedVars;

protected function createAllDiffedVars "author: wbraun"
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input String inMatrixName;
  output list<BackendDAE.Var> outVars;
algorithm
  try
    outVars := createAllDiffedVarsWork(inVars, inCref, inAllVars, 0, inMatrixName, {});
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"SymbolicJacobian.createAllDiffedVars failed"});
    fail();
  end try;
end createAllDiffedVars;

protected function createAllDiffedVarsWork "author: wbraun,hkiel"
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inIndex;
  input String inMatrixName;
  input list<BackendDAE.Var> iVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := match(inVars, inCref,inAllVars,inIndex,inMatrixName,iVars)
  local
    BackendDAE.Var v, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<BackendDAE.Var> restVar;
    Integer index;

    case({}, _, _, _, _, _)
    then listReverse(iVars);

     case((v as BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE()))::restVar, cref, _, index, _, _) algorithm
       try
        (_, _) := BackendVariable.getVarSingle(currVar, inAllVars);
        currVar := ComponentReference.crefPrefixDer(currVar);
        derivedCref := ComponentReference.createDifferentiatedCrefName(currVar, cref, inMatrixName);
        r1 := BackendVariable.copyVarNewName(derivedCref, v);
        r1 := BackendVariable.setVarKind(r1, BackendDAE.STATE_DER());
        r1.unreplaceable := true;
        index := index + 1;
      else
        currVar := ComponentReference.crefPrefixDer(currVar);
        derivedCref := ComponentReference.createDifferentiatedCrefName(currVar, cref, inMatrixName);
        r1 := BackendVariable.copyVarNewName(derivedCref, v);
        r1 := BackendVariable.setVarKind(r1, BackendDAE.STATE_DER());
      end try;
    then
      createAllDiffedVarsWork(restVar, cref, inAllVars, index, inMatrixName, r1::iVars);

    case((v as BackendDAE.VAR(varName=currVar))::restVar, cref, _, index, _, _) algorithm
      try
        (_, _) := BackendVariable.getVarSingle(currVar, inAllVars);
        derivedCref := ComponentReference.createDifferentiatedCrefName(currVar, cref, inMatrixName);
        r1 := BackendVariable.copyVarNewName(derivedCref, v);
        r1 := BackendVariable.setVarKind(r1, BackendDAE.VARIABLE());
        r1.unreplaceable := true;
        index := index + 1;
      else
        derivedCref := ComponentReference.createDifferentiatedCrefName(currVar, cref, inMatrixName);
        r1 := BackendVariable.copyVarNewName(derivedCref, v);
        r1 := BackendVariable.setVarKind(r1, BackendDAE.VARIABLE());
      end try;
    then
      createAllDiffedVarsWork(restVar, cref, inAllVars, index, inMatrixName, r1::iVars);

  end match;
end createAllDiffedVarsWork;

protected function deriveAll
  input list<BackendDAE.Equation> inEquations;
  input list<Integer> ass2;
  input DAE.ComponentRef inDiffCref;
  input BackendDAE.DifferentiateInputData inDiffData;
  input DAE.FunctionTree inFunctions;
  input Boolean daeMode;
  output list<BackendDAE.Equation> outDerivedEquations = {};
  output DAE.FunctionTree outFunctions = inFunctions;
protected
  BackendDAE.Variables allVars;
  BackendDAE.Equation currDerivedEquation;
  list<BackendDAE.Equation> tmpEquations;
  list<BackendDAE.Var> solvedvars;
  list<Integer> ass2_1 = ass2, solvedfor;
  Boolean b;
algorithm
  try
    BackendDAE.DIFFINPUTDATA(allVars=SOME(allVars)) := inDiffData;
    for currEquation in inEquations loop
      (currDerivedEquation, outFunctions) := Differentiate.differentiateEquation(currEquation, inDiffCref, inDiffData, BackendDAE.GENERIC_GRADIENT(daeMode), outFunctions);
      tmpEquations := BackendEquation.scalarComplexEquations(currDerivedEquation, outFunctions);
      outDerivedEquations := listAppend(tmpEquations, outDerivedEquations);
    end for;

    outDerivedEquations := listReverse(outDerivedEquations);

  else
    Error.addMessage(Error.INTERNAL_ERROR, {"SymbolicJacobian.deriveAll failed"});
    fail();
  end try;
end deriveAll;

public function getJacobianMatrixbyName
  input BackendDAE.SymbolicJacobians injacobianMatrices;
  input String inJacobianName;
  output Option<tuple<Option<BackendDAE.SymbolicJacobian>, BackendDAE.SparsePattern, BackendDAE.SparseColoring, BackendDAE.NonlinearPattern>> outMatrix;
algorithm
  outMatrix := match(injacobianMatrices)
    local
      tuple<Option<BackendDAE.SymbolicJacobian>, BackendDAE.SparsePattern, BackendDAE.SparseColoring, BackendDAE.NonlinearPattern> matrix;
      BackendDAE.SymbolicJacobians rest;
      String name;

    case (matrix as (SOME((_,name,_,_,_,_)), _, _, _))::_ guard
      stringEq(name, inJacobianName)
    then SOME(matrix);

    case _::rest
    then getJacobianMatrixbyName(rest, inJacobianName);

    else NONE();
  end match;
end getJacobianMatrixbyName;

public function updateJacobianDependencies
  input output BackendDAE.Jacobian jacobian;
algorithm
  jacobian := match jacobian
    local
      BackendDAE.Jacobian jac;
      BackendDAE.SymbolicJacobian symJac;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      String name;
      list<BackendDAE.Var> diffVars;
      list<BackendDAE.Var> diffedVars;
      list<BackendDAE.Var> allDiffedVars;
      list<DAE.ComponentRef> dependencies;
    case jac as BackendDAE.GENERIC_JACOBIAN()
      algorithm
        SOME(symJac as (BackendDAE.DAE({syst}, shared),name,diffVars,diffedVars,allDiffedVars,dependencies)) := jac.jacobian;
        dependencies := calcJacobianDependencies(symJac);
        jac.jacobian := SOME((BackendDAE.DAE({syst}, shared),name,diffVars,diffedVars,allDiffedVars,dependencies));
    then jac;
    else jacobian;
  end match;
end updateJacobianDependencies;

public function calcJacobianDependencies
  input BackendDAE.SymbolicJacobian jacobian;
  output list<DAE.ComponentRef> dependencies;
protected
  BackendDAE.EqSystems systems;
  BackendDAE.Shared shared;
  BackendDAE.EqSystem syst;
algorithm
  (BackendDAE.DAE(systems, shared), _, _, _, _, _) := jacobian;
  syst := listHead(systems);  // Only the first system contains directional derivative,
                                // the others contain optional constant equations
  dependencies := BackendEquation.getCrefsFromEquations(syst.orderedEqs, syst.orderedVars, shared.globalKnownVars);
end calcJacobianDependencies;

public function getJacobianDependencies
  input BackendDAE.Jacobian jacobian;
  output list<DAE.ComponentRef> dependencies;
algorithm
  dependencies := match(jacobian)
    case (BackendDAE.GENERIC_JACOBIAN(jacobian=SOME((_, _, _, _, _, dependencies))))
    then dependencies;

    case (BackendDAE.GENERIC_JACOBIAN(jacobian=NONE()))
    then {};

    else equation
      Error.addInternalError("function getJacobianDependencies failed", sourceInfo());
    then fail();

  end match;
end getJacobianDependencies;

// =============================================================================
// Module for to calculate strong component Jacobains
//
// =============================================================================

protected function calculateEqSystemJacobians
  input BackendDAE.EqSystem inSyst;
  input  BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSyst;
  output  BackendDAE.Shared outShared;
algorithm
  (outSyst, outShared) := match (inSyst, inShared)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1;
      array<Integer> ass2;
      BackendDAE.StrongComponents comps;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;

    case (syst as BackendDAE.EQSYSTEM( orderedVars=vars, orderedEqs=eqns,
                                       matching=BackendDAE.MATCHING(ass1,ass2,comps) ), shared)
      equation
        (comps, shared) = calculateJacobiansComponents(comps, vars, eqns, shared);
        syst.matching = BackendDAE.MATCHING(ass1, ass2, comps);
      then (syst, shared);
  end match;
end calculateEqSystemJacobians;

protected function calculateJacobiansComponents
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Shared inShared;
  output BackendDAE.StrongComponents outComps;
  output BackendDAE.Shared outShared = inShared;
algorithm
  outComps := list(match component
    local
      BackendDAE.StrongComponent comp;
    case comp equation
      (comp, outShared) = calculateJacobianComponent(comp, inVars, inEqns, outShared);
      then comp;
    end match for component in inComps);
end calculateJacobiansComponents;

public function prepareTornStrongComponentData
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input list<Integer> inIterationvarsInts;
  input list<Integer> inResidualequations;
  input BackendDAE.InnerEquations innerEquations;
  input DAE.FunctionTree funcTree;
  input String name;
  output BackendDAE.Variables outDiffVars;
  output BackendDAE.Variables outResidualVars;
  output BackendDAE.Variables outOtherVars;
  output BackendDAE.EquationArray outResidualEqns;
  output BackendDAE.EquationArray outOtherEqns;
protected
  list<BackendDAE.Var> iterationvars, resVarsLst, ovarsLst;
  list<BackendDAE.Equation> reqns, otherEqnsLst;
  list<list<Integer>> otherVarsIntsLst;
  list<Integer> otherEqnsInts, otherVarsInts;
algorithm
try
  // get iteration vars
  iterationvars := list(BackendVariable.transformXToXd(BackendVariable.getVarAt(inVars, e)) for e in inIterationvarsInts);
  outDiffVars := BackendVariable.listVar1(iterationvars);

  // debug
  if Flags.isSet(Flags.DEBUG_ALGLOOP_JACOBIAN) then
    print("*** got iteration variables at time: " + realString(clock()) + "\n");
    BackendDump.printVarList(iterationvars);
  end if;

  // get residual eqns
  reqns := BackendEquation.getList(inResidualequations, inEqns);
  reqns := BackendEquation.replaceDerOpInEquationList(reqns);
  outResidualEqns := BackendEquation.listEquation(reqns);

  // create  residual equations
  (_, reqns) := BackendEquation.traverseEquationArray(outResidualEqns, BackendEquation.traverseEquationToScalarResidualForm, (funcTree, {}));
  reqns := listReverse(reqns);
  (reqns, resVarsLst) := BackendEquation.convertResidualsIntoSolvedEquations(reqns, "$res_" + name + "_", 1);
  outResidualVars := BackendVariable.listVar1(resVarsLst);
  outResidualEqns := BackendEquation.listEquation(reqns);

  // debug
  if Flags.isSet(Flags.DEBUG_ALGLOOP_JACOBIAN) then
    print("*** got residual equation and created corresponding variables at time: " + realString(clock()) + "\n");
    print("Equations:\n");
    BackendDump.printEquationList(reqns);
  end if;

  // get other eqns
  (otherEqnsInts,otherVarsIntsLst,_) := List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
  otherEqnsLst := BackendEquation.getList(otherEqnsInts, inEqns);
  otherEqnsLst := BackendEquation.replaceDerOpInEquationList(otherEqnsLst);
  outOtherEqns := BackendEquation.listEquation(otherEqnsLst);

  // get other vars
  otherVarsInts := List.flatten(otherVarsIntsLst);
  ovarsLst := list(BackendVariable.transformXToXd(BackendVariable.getVarAt(inVars, e)) for e in otherVarsInts);
  outOtherVars := BackendVariable.listVar1(ovarsLst);

  // debug
  if Flags.isSet(Flags.DEBUG_ALGLOOP_JACOBIAN) then
    print("*** got residual equation and created corresponding variables at time: " + realString(clock()) + "\n");
    print("other Equations:\n");
    BackendDump.printEquationList(otherEqnsLst);
    print("other Variables:\n");
    BackendDump.printVarList(ovarsLst);
  end if;
else
  fail();
end try;
end prepareTornStrongComponentData;

protected function checkForSymbolicJacobian
  input list<BackendDAE.Equation> inResidualEqns;
  input list<BackendDAE.Equation> inOtherEqns;
  input String name;
  output Boolean out;
protected
  Boolean b1, b2;
algorithm
  if not Flags.isSet(Flags.FORCE_NLS_ANALYTIC_JACOBIAN) then
    try // this might fail because of algorithms TODO: fix it!
      (b1, _) := BackendEquation.traverseExpsOfEquationList_WithStop(inResidualEqns, traverserhasEqnNonDiffParts, ({}, true, false));
      (b2, _) := BackendEquation.traverseExpsOfEquationList_WithStop(inOtherEqns, traverserhasEqnNonDiffParts, ({}, true, false));
      if not (b1 and b2) then
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("Skip symbolic jacobian for non-linear system " + name + "\n");
        end if;
        out := false;
      else
        out := true;
      end if;
    else
      out := false;
    end try;
  else
    out := true;
  end if;
end checkForSymbolicJacobian;

protected function calculateTearingSetJacobian
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.TearingSet inTearingSet;
  input BackendDAE.Shared inShared;
  input Boolean isLinear;
  output BackendDAE.Jacobian outJacobian;
  output BackendDAE.Shared outShared;
protected
  String name, prename;
  Boolean debug = false, onlySparsePattern=false;

  BackendDAE.Variables diffVars, oVars, resVars;
  BackendDAE.EquationArray resEqns, oEqns;
algorithm
  try
    // check non-linear flag
    if not isLinear and not Flags.isSet(Flags.NLS_ANALYTIC_JACOBIAN) then
     onlySparsePattern := true;
    end if;
    // generate jacobian name
    if isLinear then
      prename := "LS";
    else
      prename := "NLS";
    end if;
    name := prename + "Jac" + intString(System.tmpTickIndex(Global.backendDAE_jacobianSeq));

    if debug then
      print("*** "+ prename + "-JAC *** start creating Jacobian for a torn system " + name + " of size " + intString(listLength(inTearingSet.tearingvars)) + " time: " + realString(clock()) + "\n");
    end if;

    (diffVars, resVars, oVars, resEqns, oEqns) := prepareTornStrongComponentData(inVars, inEqns, inTearingSet.tearingvars, inTearingSet.residualequations, inTearingSet.innerEquations, inShared.functionTree, name);

    if debug then
      print("*** "+ prename + "-JAC *** prepared all data for differentiation at time: " + realString(clock()) + "\n");
    end if;

    //check if we are able to calc symbolic jacobian
    if not (isLinear or checkForSymbolicJacobian(BackendEquation.equationList(resEqns), BackendEquation.equationList(oEqns), name)) then
      onlySparsePattern := true;
    end if;

    // generate generic jacobian backend dae
    (outJacobian, outShared) := getSymbolicJacobian(diffVars, resEqns, resVars, oEqns, oVars, inShared, inVars, name, onlySparsePattern);
  else
    fail();
  end try;
end calculateTearingSetJacobian;

protected function calculateJacobianComponent
  "Calculates jacobian matrix for strong components of torn systems and non-linear systems."
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input  BackendDAE.Shared inShared;
  output BackendDAE.StrongComponent outComp;
  output  BackendDAE.Shared outShared;
algorithm
  (outComp, outShared) := matchcontinue (inComp, inVars, inEqns, inShared)
    local
      BackendDAE.StrongComponent comp;
      BackendDAE.Shared shared;
      list<Integer> iterationvarsInts,iterationvarsInts2;
      list<Integer> residualequations,residualequations2;
      BackendDAE.InnerEquations innerEquations,innerEquations2;
      Boolean b;

      list<list<Integer>> otherVarsIntsLst;
      list<Integer> otherEqnsInts, otherVarsInts;

      list<BackendDAE.Var> iterationvars, ovarsLst, resVarsLst;
      BackendDAE.Var tmpVar;
      BackendDAE.Variables diffVars, ovars, resVars;
      list<BackendDAE.Equation> reqns, otherEqnsLst;
      BackendDAE.EquationArray eqns, oeqns;

      BackendDAE.Jacobian jacobian,jacobianCausal;

      String name;
      Boolean mixedSystem, linear;

      Boolean debug = false, onlySparsePattern = true;
      BackendDAE.TearingSet strictTearingset, casualTearingSet;
      Option<BackendDAE.TearingSet> optCasualTearingSet;

      // generate symbolic jacobian for a torn system
      case (BackendDAE.TORNSYSTEM(strictTearingset, optCasualTearingSet, linear, mixedSystem), _, _, _)
        equation
          // generate generic jacobian backend dae
          (jacobian, shared) = calculateTearingSetJacobian(inVars, inEqns, strictTearingset, inShared, linear);
          strictTearingset.jac = jacobian;

          if isSome(optCasualTearingSet) then
            casualTearingSet = Util.getOption(optCasualTearingSet);
            (jacobianCausal, shared) = calculateTearingSetJacobian(inVars, inEqns, casualTearingSet, shared, linear);
            casualTearingSet.jac = jacobianCausal;
            optCasualTearingSet = SOME(casualTearingSet);
          end if;
      then (BackendDAE.TORNSYSTEM(strictTearingset, optCasualTearingSet, linear, mixedSystem), shared);

      // do not touch constant systems for now
      case (comp as BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_CONSTANT()), _, _, _) then (comp, inShared);

      // Convert linear system to a torn system with symbolica jacobian, when flag is enabled
      case (comp as BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_LINEAR(), eqns=residualequations, vars=iterationvarsInts, mixedSystem=mixedSystem), _, _, _)
        guard(Flags.isSet(Flags.LS_ANALYTIC_JACOBIAN))
        equation
          strictTearingset = BackendDAE.TEARINGSET(iterationvarsInts, residualequations, {}, BackendDAE.EMPTY_JACOBIAN());
          (jacobian, shared) = calculateTearingSetJacobian(inVars, inEqns, strictTearingset, inShared, true);
          strictTearingset.jac = jacobian;
      then (BackendDAE.TORNSYSTEM(strictTearingset, NONE(), true, mixedSystem), shared);

      // Do not touch linear system
      case (comp as BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_LINEAR()), _, _, _) then (comp, inShared);

      case (BackendDAE.EQUATIONSYSTEM(eqns=residualequations, vars=iterationvarsInts, mixedSystem=mixedSystem), _, _, _)
        equation
          //generate jacobian name
          name = "NLSJac" + intString(System.tmpTickIndex(Global.backendDAE_jacobianSeq));

          // get iteration vars
          iterationvars = List.map1r(iterationvarsInts, BackendVariable.getVarAt, inVars);
          iterationvars = List.map(iterationvars, BackendVariable.transformXToXd);
          iterationvars = listReverse(iterationvars);
          diffVars = BackendVariable.listVar1(iterationvars);

          // get residual eqns
          reqns = BackendEquation.getList(residualequations, inEqns);
          reqns = BackendEquation.replaceDerOpInEquationList(reqns);

          //check if we are able to calc symbolic jacobian
          if checkForSymbolicJacobian(reqns, {}, name) and Flags.isSet(Flags.NLS_ANALYTIC_JACOBIAN) then
            onlySparsePattern = false;
          end if;

          eqns = BackendEquation.listEquation(reqns);
          // create  residual equations
          (_, reqns) = BackendEquation.traverseEquationArray(eqns, BackendEquation.traverseEquationToScalarResidualForm, (inShared.functionTree, {}));
          reqns = listReverse(reqns);
          (reqns, resVarsLst) = BackendEquation.convertResidualsIntoSolvedEquations(reqns, "$res_" + name + "_", 1);
          resVars = BackendVariable.listVar1(resVarsLst);
          eqns = BackendEquation.listEquation(reqns);

          // other eqns and vars are empty
          oeqns = BackendEquation.listEquation({});
          ovars =  BackendVariable.emptyVars();

          // generate generic jacobian backend dae
          (jacobian, shared) = getSymbolicJacobian(diffVars, eqns, resVars, oeqns, ovars, inShared, inVars, name, onlySparsePattern);
      then (BackendDAE.EQUATIONSYSTEM(residualequations, iterationvarsInts, jacobian, BackendDAE.JAC_GENERIC(), mixedSystem), shared);

      case (comp, _, _, _) then (comp, inShared);
  end matchcontinue;

  // Check if all nonlinear iteration variables have start values
  if BackendDAEUtil.isInitializationDAE(inShared) then
      try
        checkNonLinDependecies(outComp,inEqns);
      else
        Error.addInternalError("function calculateJacobianComponent failed to check all non-linear iteration variables for start values.", sourceInfo());
      end try;
  end if;
end calculateJacobianComponent;

protected function checkNonLinDependecies
  "Check if all non-linear iteartion variables of given non-linear equation
   system have a start value and throw warning if not. Only start values for
   those have an influence on solver iteration."
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.EquationArray inEqns;
protected
  String name, msg;
  Boolean existNonLin;
algorithm
  if Flags.isSet(Flags.INITIALIZATION) then
    // Dump full information.
    _ := match (inComp)
      local
        BackendDAE.Jacobian jac;
        list<Integer> resIndices, eqnIndices = {};
        BackendDAE.InnerEquations innerEquations;
        Boolean linear;
        String str;
      // Case non-linear torn equation system
      case (BackendDAE.TORNSYSTEM(strictTearingSet=BackendDAE.TEARINGSET(jac=jac, residualequations=resIndices, innerEquations=innerEquations), linear=false))
        algorithm
          for eq in innerEquations loop
            eqnIndices := match eq
              local
                Integer idx;
              case BackendDAE.INNEREQUATION(eqn = idx) then idx::eqnIndices;
              case BackendDAE.INNEREQUATIONCONSTRAINTS(eqn = idx) then idx::eqnIndices;
              else eqnIndices;
            end match;
          end for;
          eqnIndices := listAppend(resIndices,eqnIndices);
          printNonLinIterVarsAndEqs(jac,eqnIndices,inEqns);
        then();

      // Case non-linear non-torn equation system
      case (BackendDAE.EQUATIONSYSTEM(eqns=eqnIndices, jac=jac, jacType=BackendDAE.JAC_NONLINEAR()))
        algorithm
          printNonLinIterVarsAndEqs(jac,eqnIndices,inEqns);
        then();

      // ToDo: Check if jacType=BackendDAE.JAC_GENERIC is needed
      //case BackendDAE.EQUATIONSYSTEM(jac=jac, jacType=BackendDAE.JAC_GENERIC())
      else();
    end match;
  else
    // Only error message.
    (existNonLin, name) := match (inComp)
      local
        BackendDAE.Jacobian jac;
        Boolean linear;
        String str;
      // Case non-linear teared equation system
      case (BackendDAE.TORNSYSTEM(strictTearingSet=BackendDAE.TEARINGSET(jac=jac), linear=false))
        then existNonLinIterVars(jac);

      // Case non-linear non-teared equation system
      case (BackendDAE.EQUATIONSYSTEM(jac=jac, jacType=BackendDAE.JAC_NONLINEAR()))
        then existNonLinIterVars(jac);

      // ToDo: Check if jacType=BackendDAE.JAC_GENERIC is needed
      //case BackendDAE.EQUATIONSYSTEM(jac=jac, jacType=BackendDAE.JAC_GENERIC())
      else (false,"");
    end match;
    if existNonLin then
      msg := System.gettext("For more information set -d=initialization. In OMEdit Tools->Options->Simulation->Show additional information from the initialization process, in OMNotebook call setCommandLineOptions(\"-d=initialization\")");
      Error.addMessage(Error.INITIALIZATION_ITERATION_VARIABLES, {name, msg});
    end if;
  end if;
end checkNonLinDependecies;

protected function existNonLinIterVars
  "Helper function for checkNonLinDependecies. Returns true if any non-linear
   iteration variables without start value are contained in given jacobian."
  input BackendDAE.Jacobian jacobian_in;
  output Boolean existNonLin;
  output String jacName;
algorithm
  (existNonLin, jacName) := match (jacobian_in)
    local
      list<BackendDAE.Var> diffVars, residualVars, allDiffedVars;
      list<DAE.ComponentRef> dependentVarsCref;
      DAE.ComponentRef varCref;
      BackendDAE.Var var;
      String name;
      Boolean exist=false;
    case BackendDAE.GENERIC_JACOBIAN(SOME((_,name,diffVars,residualVars,allDiffedVars,dependentVarsCref))) algorithm
      // Search for non-linear variables without start value
      for varCref in dependentVarsCref loop
        for var in diffVars loop
          if ComponentReference.crefEqual(varCref, var.varName) then
            if (not BackendVariable.varHasStartValue(var)) then
              exist:= true;
              break;
            end if;
          end if;
        end for;
        if exist then
          break;
        end if;
      end for;
    then (exist, name);

  // ToDo
  // case BackendDAE.FULL_JACOBIAN() algorithm
    else (false, "");
  end match;
end existNonLinIterVars;

protected function printNonLinIterVarsAndEqs
  "Helper function for checkNonLinDependecies. Prints relevant information regarding
  start attributes of non linear iteration variables."
  input BackendDAE.Jacobian jacobian;
  input list<Integer> eqnIndices;
  input BackendDAE.EquationArray inEqns;
algorithm
    _ := match jacobian
      local
        BackendDAE.EqSystem syst;
        BackendDAE.Shared shared;
        Integer idx = 1;
        list<BackendDAE.Var> diffVars, residualVars, allDiffedVars, nonLin = {}, nonLinStart = {}, lin = {};
        list<DAE.ComponentRef> dependentVarsCref;
        DAE.ComponentRef varCref;
        BackendDAE.Var var;
        String name;
      case BackendDAE.GENERIC_JACOBIAN(jacobian = SOME((BackendDAE.DAE({syst}, shared),name,diffVars,residualVars,allDiffedVars,dependentVarsCref)))
        algorithm
          // Get non-linear variables without start value
          for varCref in dependentVarsCref loop
            for var in diffVars loop
              if ComponentReference.crefEqual(varCref, var.varName) then
                if (not BackendVariable.varHasStartValue(var)) then
                  nonLin := var::nonLin;
                else
                  nonLinStart := var::nonLinStart;
                end if;
              end if;
            end for;
          end for;
          if not listEmpty(nonLin) then
            BackendDump.dumpVarList(nonLin, "Nonlinear iteration variables with default zero start attribute in " + name + ".");
          end if;
          if not listEmpty(nonLinStart) then
            BackendDump.dumpVarList(nonLinStart, "Nonlinear iteration variables with predefined start attribute in " + name + ".");
          end if;

          // Get linear variables with start value, but ignore discrete vars
          // kabdelhak: i don't get this, how are these the linear ones? these are the inner variables
          for var in allDiffedVars loop
            if (BackendVariable.varHasStartValue(var) and not BackendVariable.isVarDiscrete(var) ) then
              lin := var::lin;
            end if;
          end for;
          if not listEmpty(lin) then
            BackendDump.dumpVarList(lin, "Linear iteration variables with predefined start attributes that are unrelevant in " + name + ".");
          end if;

          if not (listEmpty(nonLin) and listEmpty(nonLinStart) and listEmpty(lin)) then
            print("Info: Only non-linear iteration variables in non-linear eqation systems require start values."
                  + " All other start values have no influence on convergence and are ignored."
                  + (if Flags.isSet(Flags.DUMP_LOOPS) then "\n\n"
                     else " Use \"-d=dumpLoops\" to show all loops. In OMEdit Tools->Options->Simulation->Additional Translation Flags,"
                          + " in OMNotebook call setCommandLineOptions(\"-d=dumpLoops\")\n\n"));
          end if;
        then();

      else();
    end match;
  // ToDo
  // BackendDAE.FULL_JACOBIAN()
end printNonLinIterVarsAndEqs;

public function getNonLinearVariables
  "Returns all nonlinear variables for the jacobian."
  input BackendDAE.Jacobian jacobian;
  output list<BackendDAE.Var> nonLin = {};
algorithm
    nonLin := match jacobian
      local
        list<BackendDAE.Var> diffVars;
        list<DAE.ComponentRef> dependentVarsCref;

      case BackendDAE.GENERIC_JACOBIAN(jacobian = SOME((_, _,diffVars, _, _, dependentVarsCref)))
        algorithm
          // nonlinear variables are those appearing in the jacobian
          for varCref in dependentVarsCref loop
            for var in diffVars loop
              if ComponentReference.crefEqual(varCref, var.varName) then
                var.initNonlinear := true;
                nonLin := var::nonLin;
                break;
              end if;
            end for;
          end for;
      then nonLin;

      else {};
    end match;
  // ToDo
  // BackendDAE.FULL_JACOBIAN()
end getNonLinearVariables;

protected function traverserhasEqnNonDiffParts
"function breaks differentiation for
 currently not working parts of functions"
  input DAE.Exp inExp;
  input tuple<list<DAE.Exp>, Boolean, Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<list<DAE.Exp>, Boolean, Boolean> outTpl = inTpl;
protected
 list<DAE.Exp> expList;
algorithm
  (outExp, (expList, cont, _)) := Expression.traverseExpTopDown(inExp, hasEqnNonDiffParts, inTpl);
  if Flags.isSet(Flags.DUMP_EXCLUDED_EXP) and not cont then
    print("Traverser for catching functions, that should not be differentiated\n");
    print(stringDelimitList(List.map(expList, ExpressionDump.printExpStr), "\n"));
    print("\n\n");
  end if;
end traverserhasEqnNonDiffParts;

protected function hasEqnNonDiffParts
"function breaks differentiation for
 currently not working parts of functions"
  input DAE.Exp inExp;
  input tuple<list<DAE.Exp>, Boolean, Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<list<DAE.Exp>, Boolean, Boolean> outTpl;
algorithm
  (outExp, cont, outTpl) := matchcontinue(inExp, inTpl)
  local
    list<DAE.Exp> expLst, expLst1;
    Boolean b, insideCall;
    DAE.Type ty;

    case (DAE.CALL(path=Absyn.IDENT("delay")), (expLst, _, insideCall)) then (inExp, false, (inExp::expLst, false, insideCall));

// For now exclude all not built in calls
    case (DAE.CALL(attr=DAE.CALL_ATTR(builtin=false)), (expLst, _, insideCall)) then (inExp, false, (inExp::expLst, false, insideCall));

/*
    case (_, (expLst, _, true)) guard(Expression.isRecord(inExp)) then (inExp, false, (inExp::expLst, false, true));
    case (_, (expLst, _, true)) guard(Expression.isMatrix(inExp)) then (inExp, false, (inExp::expLst, false, true));
    case (DAE.CALL(attr=DAE.CALL_ATTR(ty = ty, builtin=false)), (expLst, b, insideCall))
      equation
        true = isRecordInvoled(ty);
    then (inExp, false, (inExp::expLst, false, insideCall));
    case (DAE.CALL(expLst=expLst1,attr=DAE.CALL_ATTR(builtin=false)), (expLst, b, insideCall))
      equation
        (_, (_, false, _)) = Expression.traverseExpListTopDown(expLst1, hasEqnNonDiffParts, (expLst, b, true));
    then (inExp, false, (inExp::expLst, false, insideCall));
*/

    case (outExp, (_, b, _)) then (outExp, b, inTpl);
  end matchcontinue;
end hasEqnNonDiffParts;

protected function isRecordInvoled
  input DAE.Type inType;
  output Boolean out;
algorithm
  out := match(inType)
  local
    DAE.Type ty;
    list<DAE.Type> types;
    list<Boolean> blst;
    case DAE.T_COMPLEX() then true;
    case DAE.T_ARRAY(ty=ty) then isRecordInvoled(ty);
    case DAE.T_FUNCTION(funcResultType=ty) then isRecordInvoled(ty);
    case DAE.T_TUPLE(types)
    then List.any(types, isRecordInvoled);
    else false;
  end match;
end isRecordInvoled;

public function getSymbolicJacobian "author: wbraun
  This function creates a symbolic Jacobian column for non-linear systems and
  tearing systems."
  input BackendDAE.Variables inDiffVars;
  input BackendDAE.EquationArray inResEquations;
  input BackendDAE.Variables inResVars;
  input BackendDAE.EquationArray inotherEquations;
  input BackendDAE.Variables inotherVars;
  input BackendDAE.Shared inShared;
  input BackendDAE.Variables inAllVars;
  input String inName;
  input Boolean inOnlySparsePattern;
  output BackendDAE.Jacobian outJacobian;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.BackendDAE backendDAE;
  BackendDAE.EquationArray eqns;
  BackendDAE.ExtraInfo einfo;
  BackendDAE.Shared shared;
  BackendDAE.SparseColoring sparseColoring;
  BackendDAE.SparsePattern sparsePattern;
  BackendDAE.NonlinearPattern nonlinearPattern;
  BackendDAE.Variables dependentVars, globalKnownVars;
  DAE.FunctionTree funcs;
  FCore.Cache cache;
  FCore.Graph graph;
  list<BackendDAE.Var> knvarLst1, knvarLst2, independentVarsLst, dependentVarsLst, otherVarsLst;
  list<DAE.ComponentRef> independentComRefs, dependentVarsComRefs, otherVarsLstComRefs;
  Option<BackendDAE.SymbolicJacobian> symJacBDAE;
algorithm
  try
    globalKnownVars := BackendDAEUtil.getGlobalKnownVarsFromShared(inShared);
    funcs := BackendDAEUtil.getFunctions(inShared);
    einfo := BackendDAEUtil.getExtraInfo(inShared);

    if Flags.isSet(Flags.JAC_DUMP2) then
      print("---+++ create analytical jacobian +++---");
      print("\n---+++ independent variables +++---\n");
      BackendDump.printVariables(inDiffVars);
      print("\n---+++ equation system +++---\n");
      BackendDump.printEquationArray(inResEquations);
    end if;

    independentVarsLst := BackendVariable.varList(inDiffVars);
    independentComRefs := List.map(independentVarsLst, BackendVariable.varCref);

    otherVarsLst := BackendVariable.varList(inotherVars);
    otherVarsLstComRefs := List.map(otherVarsLst, BackendVariable.varCref);

    if Flags.isSet(Flags.JAC_DUMP2) then
      print("\n---+++ known variables +++---\n");
      BackendDump.printVariables(globalKnownVars);
    end if;

    // dependentVarsLst = listReverse(dependentVarsLst);
    dependentVars := BackendVariable.mergeVariables(inResVars, inotherVars);
    eqns := BackendEquation.merge(inResEquations, inotherEquations);

    if Flags.isSet(Flags.JAC_DUMP2) then
      print("\n---+++ created backend system +++---\n");
      print("\n---+++ vars +++---\n");
      BackendDump.printVariables(dependentVars);
      print("\n---+++ equations +++---\n");
      BackendDump.printEquationArray(eqns);
    end if;

    // create known variables
    knvarLst1 := BackendEquation.equationsVars(eqns, globalKnownVars);
    //knvarLst2 := BackendEquation.equationsVars(eqns, inAllVars);
    knvarLst2 := {};
    // Create a list of known variables true *only* for this shared system
    globalKnownVars := BackendVariable.listVar2(knvarLst1,knvarLst2);
    // Remove inputs for the jacobian
    globalKnownVars := BackendVariable.removeCrefs(independentComRefs, globalKnownVars);
    globalKnownVars := BackendVariable.removeCrefs(otherVarsLstComRefs, globalKnownVars);

    if Flags.isSet(Flags.JAC_DUMP2) then
      print("\n---+++ known variables +++---\n");
      BackendDump.printVariables(globalKnownVars);
    end if;

    // prepare vars and equations for BackendDAE
    cache := FCore.emptyCache();
    graph := FGraph.empty();
    shared := BackendDAEUtil.createEmptyShared(BackendDAE.ALGEQSYSTEM(), einfo, cache, graph);
    shared := BackendDAEUtil.setSharedGlobalKnownVars(shared, globalKnownVars);
    shared := BackendDAEUtil.setSharedFunctionTree(shared, funcs);
    backendDAE := BackendDAE.DAE({BackendDAEUtil.createEqSystem(dependentVars, eqns)}, shared);

    if Flags.isSet(Flags.JAC_DUMP2) then
      BackendDump.bltdump("System",backendDAE);
    end if;

    backendDAE := BackendDAEUtil.transformBackendDAE(backendDAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());

    BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = dependentVars)}, BackendDAE.SHARED(globalKnownVars = globalKnownVars)) := backendDAE;

    // prepare creation of symbolic jacobian
    // create dependent variables
    dependentVarsLst := BackendVariable.varList(dependentVars);

    (symJacBDAE, funcs, sparsePattern, sparseColoring, nonlinearPattern) := generateGenericJacobian(backendDAE,
      independentVarsLst,
      BackendVariable.emptyVars(),
      BackendVariable.emptyVars(),
      globalKnownVars,
      inResVars,
      dependentVarsLst,
      inName,
      inOnlySparsePattern);

    outJacobian := BackendDAE.GENERIC_JACOBIAN(symJacBDAE, sparsePattern, sparseColoring, nonlinearPattern);
    outShared := BackendDAEUtil.setSharedFunctionTree(inShared, funcs);
  else

    if Flags.isSet(Flags.JAC_DUMP) then
      Error.addInternalError("function getSymbolicJacobian failed", sourceInfo());
    end if;
    outJacobian := BackendDAE.EMPTY_JACOBIAN();
    outShared := inShared;
  end try;
end getSymbolicJacobian;

public function hasGenericSymbolicJacobian
  input BackendDAE.Jacobian inJacobian;
  output Boolean out;
algorithm
  out := match(inJacobian)
    case (BackendDAE.GENERIC_JACOBIAN(jacobian=SOME(_))) then true;
    else false;
  end match;
end hasGenericSymbolicJacobian;

protected function calculateEqSystemStateSetsJacobians
  input BackendDAE.EqSystem inSyst;
  input  BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSyst;
  output  BackendDAE.Shared outShared;
algorithm
  (outSyst,outShared) := match (inSyst, inShared)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StrongComponents comps;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StateSets stateSets;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs = eqns, stateSets=stateSets), shared)
      equation
        comps = BackendDAEUtil.getStrongComponents(syst);
        (stateSets, shared) = calculateStateSetsJacobian(stateSets, vars, eqns, comps, shared);
        syst.stateSets = stateSets;
      then (syst, shared);
  end match;
end calculateEqSystemStateSetsJacobians;

protected function calculateStateSetsJacobian
  input BackendDAE.StateSets inStateSets;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.StrongComponents inComps;
  input  BackendDAE.Shared inShared;
  output BackendDAE.StateSets outStateSets;
  output  BackendDAE.Shared outShared = inShared;
algorithm
  outStateSets := list(match s
      local
        BackendDAE.StateSet stateSet;
      case stateSet
        equation
          (stateSet, outShared) = calculateStateSetJacobian(stateSet, inVars, inEqns, inComps, outShared);
        then stateSet;
    end match for s in inStateSets);
end calculateStateSetsJacobian;

protected function calculateStateSetJacobian
  input BackendDAE.StateSet inStateSet;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.StrongComponents inComps;
  input  BackendDAE.Shared inShared;
  output BackendDAE.StateSet outStateSet;
  output  BackendDAE.Shared outShared;
algorithm
  (outStateSet, outShared) := match (inStateSet, inVars, inEqns, inComps, inShared)
    local
      BackendDAE.StateSet stateSet;
      BackendDAE.Shared shared;

      Integer index, rang;
      list<DAE.ComponentRef> state;
      DAE.ComponentRef crA, crJ;
      list<BackendDAE.Var> varA, varJ, statescandidates, ovars;

      list<DAE.ComponentRef> crstates;
      array<Boolean> marked;
      HashSet.HashSet hs;

      list<BackendDAE.Var> statevars, compvars;
      BackendDAE.Variables diffVars, allvars, vars, oVars, resVars;
      list<BackendDAE.Equation> eqns, compeqns, ceqns, oeqns;
      BackendDAE.EquationArray cEqns, oEqns;

      BackendDAE.Jacobian jacobian;

      String name;

    case (BackendDAE.STATESET(index=index, rang=rang, state=state, crA=crA, varA=varA, statescandidates=statescandidates,
      ovars=ovars, eqns=eqns, oeqns=oeqns, crJ=crJ, varJ=varJ), _, _, _, _)
      equation
        // get state names
        crstates = List.map(statescandidates, BackendVariable.varCref);
        marked = arrayCreate(BackendVariable.varsSize(inVars), false);
        // get Equations for Jac from the strong component
        marked = List.fold1(crstates, markSetStates, inVars, marked);
        (compeqns, compvars) = getStateSetCompVarEqns(inComps, marked, inEqns, inVars);
        // remove the state set equation
        compeqns = List.select(compeqns, removeStateSetEqn);
        // remove the state candidates to geht the other vars
        hs = List.fold(crstates, BaseHashSet.add, HashSet.emptyHashSet());
        compvars = List.select1(compvars, removeStateSetStates, hs);
        // match the equations to get the residual equations
        (ceqns, oeqns) = IndexReduction.splitEqnsinConstraintAndOther(compvars, compeqns, inShared);
        // change state vars to ders
        compvars = List.map(compvars, BackendVariable.transformXToXd);
        // replace der in equations
        ceqns = BackendEquation.replaceDerOpInEquationList(ceqns);
        oeqns = BackendEquation.replaceDerOpInEquationList(oeqns);
        // convert ceqns to res[..] = lhs-rhs
        ceqns = createResidualSetEquations(ceqns, crJ, 1, intGt(listLength(ceqns), 1));

        //add states to allVars
        allvars = BackendVariable.copyVariables(inVars);
        statevars = BackendVariable.getAllStateVarFromVariables(allvars);
        statevars = List.map(statevars, BackendVariable.transformXToXd);
        allvars = BackendVariable.addVars(statevars, allvars);

        // create arrays
        resVars = BackendVariable.listVar1(varJ);
        diffVars = BackendVariable.listVar1(statescandidates);
        oVars =  BackendVariable.listVar1(compvars);
        cEqns = BackendEquation.listEquation(ceqns);
        oEqns = BackendEquation.listEquation(oeqns);

        //generate Jacobian name
        name = "StateSetJac" + intString(System.tmpTickIndex(Global.backendDAE_jacobianSeq));
        // generate generic Jacobian back end dae
        (jacobian, shared) = getSymbolicJacobian(diffVars, cEqns, resVars, oEqns, oVars, inShared, allvars, name, false);

      then (BackendDAE.STATESET(index, rang, state, crA, varA, statescandidates, ovars, eqns, oeqns, crJ, varJ, jacobian), shared);
  end match;
end calculateStateSetJacobian;

protected function markSetStates
  input DAE.ComponentRef inCr;
  input BackendDAE.Variables iVars;
  input array<Boolean> iMark;
  output array<Boolean> oMark;
protected
  Integer index;
algorithm
  (_, index) := BackendVariable.getVarSingle(inCr, iVars);
  oMark := arrayUpdate(iMark, index, true);
end markSetStates;

protected function removeStateSetStates
  input BackendDAE.Var inVar;
  input HashSet.HashSet hs;
  output Boolean b;
algorithm
  b := not BaseHashSet.has(BackendVariable.varCref(inVar), hs);
end removeStateSetStates;

protected function removeStateSetEqn
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match(inEqn)
    case BackendDAE.ARRAY_EQUATION(source=DAE.SOURCE(info=SOURCEINFO(fileName="stateselection"))) then false;
    case BackendDAE.EQUATION(source=DAE.SOURCE(info=SOURCEINFO(fileName="stateselection"))) then false;
    else true;
  end match;
end removeStateSetEqn;

protected function foundMarked
  input list<Integer> ilst;
  input array<Boolean> marked;
  output Boolean found;
algorithm
  found := match(ilst, marked)
    local
      Boolean b;
      Integer i;
      list<Integer> rest;
    case ({}, _) then false;
    case (i::rest, _)
      equation
        b = marked[i];
        b = if not b then foundMarked(rest, marked) else b;
      then
        b;
  end match;
end foundMarked;

protected function getStateSetCompVarEqns "author: Frenkel TUD 2013-01
  Retrieves the equation and the variable for a state set"
  input BackendDAE.StrongComponents inComp;
  input array<Boolean> marked;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Equation> outEquations = {};
  output list<BackendDAE.Var> outVars = {};
protected
  list<Integer> elst, vlst;
  list<BackendDAE.Equation> eqnlst;
  list<BackendDAE.Var> varlst;
algorithm
  for comp in inComp loop
    (elst, vlst) := BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
    if foundMarked(vlst, marked) then
      eqnlst := BackendEquation.getList(elst, inEquationArray);
      varlst := List.map1r(vlst, BackendVariable.getVarAt, inVariables);
      outEquations := listAppend(eqnlst, outEquations);
      outVars := listAppend(varlst, outVars);
    end if;
  end for;
end getStateSetCompVarEqns;

protected function createResidualSetEquations
  input list<BackendDAE.Equation> iEqs;
  input DAE.ComponentRef crJ;
  input Integer index;
  input Boolean applySubs;
  output list<BackendDAE.Equation> oEqs;
protected
  Integer idx = index;
algorithm
  oEqs := list(match eq
      local
        DAE.ComponentRef crj;
        DAE.Exp res, e1, e2, expJ;
        BackendDAE.Equation eqn;
        DAE.ElementSource source;
        BackendDAE.EquationAttributes eqAttr;
      case BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr)
        equation
          crj = if applySubs then ComponentReference.subscriptCrefWithInt(crJ, idx) else crJ;
          expJ = Expression.crefExp(crj);
          res = Expression.expSub(e1, e2);
          eqn = BackendDAE.EQUATION(expJ, res, source, eqAttr);
          idx = idx + 1;
        then eqn;

      case BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source, attr=eqAttr)
        equation
          expJ = Expression.crefExp(ComponentReference.subscriptCrefWithInt(crJ, idx));
          eqn = BackendDAE.EQUATION(expJ, e1, source, eqAttr);
          idx = idx + 1;
        then eqn;

      case eqn
        equation
          Error.addInternalError("function createResidualSetEquations failed for equation: " + BackendDump.equationString(eqn), sourceInfo());
        then
          fail();
    end match for eq in iEqs);
end createResidualSetEquations;

public function calculateJacobian "This function takes an array of equations and the variables of the equation
  and calculates the Jacobian of the equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.AdjacencyMatrix inAdjacencyMatrix;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input BackendDAE.Shared iShared;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output BackendDAE.Shared oShared;
algorithm
  (outTplIntegerIntegerEquationLstOption, oShared):=
  matchcontinue (inVariables,inEquationArray,inAdjacencyMatrix,differentiateIfExp,iShared)
    local
      list<BackendDAE.Equation> eqn_lst;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.AdjacencyMatrix m;
      BackendDAE.Shared shared;
    case (vars,eqns,m,_,_)
      equation
        (jac, shared) = calculateJacobianRows(eqns,vars,m,1,1,differentiateIfExp,iShared,BackendDAEUtil.varsInEqn);
      then
        (SOME(jac),shared);
    else (NONE(), iShared);  /* no analytic jacobian available */
  end matchcontinue;
end calculateJacobian;

protected function calculateJacobianRows "author: PA
  This function takes a list of Equations and a set of variables and
  calculates the Jacobian expression for each variable over each equations,
  returned in a sparse matrix representation.
  For example, the equation on index e1: 3ax+5yz+ zz  given the
  variables {x,y,z} on index x1,y1,z1 gives
  {(e1,x1,3a), (e1,y1,5z), (e1,z1,5y+2z)}"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Variables vars;
  input Type_a m;
  input Integer eqn_indx;
  input Integer scalar_eqn_indx;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input BackendDAE.Shared iShared;
  input varsInEqnFunc varsInEqn;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst = {};
  output BackendDAE.Shared oShared = iShared;
  partial function varsInEqnFunc
    input Type_a m;
    input Integer indx;
    output list<Integer> outIntegerLst;
  end varsInEqnFunc;
protected
  Integer size, i, j, n, k;
  BackendDAE.Equation eqn;
algorithm
  i := eqn_indx;
  j := scalar_eqn_indx;
  size := 0;
  n := ExpandableArray.getLastUsedIndex(inEquationArray);
  // print("CalcJac(Eqs:" + intString(n) + ")\n");
  for k in 1:n loop
    if ExpandableArray.occupied(k, inEquationArray) then
      eqn := ExpandableArray.get(k, inEquationArray);
      (outLst, size, oShared) := calculateJacobianRow(eqn, vars,  m, i, j, differentiateIfExp, oShared, varsInEqn, outLst);
      i := i+1;
      j := j+size;
    end if;
  end for;
  outLst := MetaModelica.Dangerous.listReverseInPlace(outLst);
  // print("END_CalcJac(Size:" + intString(listLength(outLst)) + ")\n");
end calculateJacobianRows;

protected function calculateJacobianRow "author: PA
  Calculates the Jacobian for one equation. See calculateJacobianRows.
  inputs:  (Equation,
              BackendDAE.Variables,
              AdjacencyMatrix,
              AdjacencyMatrixT,
              int /* eqn index */)
  outputs: ((int  int  Equation) list option)"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables vars;
  input Type_a m;
  input Integer eqn_indx;
  input Integer scalar_eqn_indx;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input BackendDAE.Shared iShared;
  input varsInEqnFunc fvarsInEqn;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> iAcc;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst;
  output Integer size;
  output BackendDAE.Shared oShared;
  partial function varsInEqnFunc
    input Type_a m;
    input Integer indx;
    output list<Integer> outIntegerLst;
  end varsInEqnFunc;
algorithm
  (outLst, size, oShared):=  match (inEquation,vars,m,eqn_indx,scalar_eqn_indx,differentiateIfExp,iShared,fvarsInEqn,iAcc)
    local
      list<Integer> var_indxs,var_indxs_1,ds;
      list<tuple<Integer, Integer, BackendDAE.Equation>> eqns;
      DAE.Exp e,e1,e2;
      list<DAE.Exp> expl;
      DAE.Type t;
      list<list<DAE.Subscript>> subslst;
      DAE.ElementSource source;
      DAE.ComponentRef cr;
      String str;
      BackendDAE.Shared shared;

    // residual equations
    case (BackendDAE.EQUATION(exp = e1,scalar=e2,source=source),_,_,_,_,_,_,_,_)
      equation
        var_indxs = fvarsInEqn(m, eqn_indx);
        // Remove duplicates and get in correct order: ascending index
        var_indxs_1 = List.sort(var_indxs,intGt);
        var_indxs_1 = List.sortedUnique(var_indxs_1, intEq);
        (eqns, shared) = calculateJacobianRow2(Expression.expSub(e1,e2), vars, scalar_eqn_indx, var_indxs_1,differentiateIfExp,iShared,source,iAcc);
      then
        (eqns, 1, shared);

    // residual equations
    case (BackendDAE.RESIDUAL_EQUATION(exp=e,source=source),_,_,_,_,_,_,_,_)
      equation
        var_indxs = fvarsInEqn(m, eqn_indx);
        // Remove duplicates and get in correct order: ascending index
        var_indxs_1 = List.sort(var_indxs,intGt);
        var_indxs_1 = List.sortedUnique(var_indxs_1, intEq);
        (eqns, shared) = calculateJacobianRow2(e, vars, scalar_eqn_indx, var_indxs_1,differentiateIfExp,iShared,source,iAcc);
      then
        (eqns, 1, shared);

    // solved equations
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e2,source=source),_,_,_,_,_,_,_,_)
      equation
        e1 = Expression.crefExp(cr);

        var_indxs = fvarsInEqn(m, eqn_indx);
        // Remove duplicates and get in correct order: ascending index
        var_indxs_1 = List.sort(var_indxs,intGt);
        var_indxs_1 = List.sortedUnique(var_indxs_1, intEq);
        (eqns, shared) = calculateJacobianRow2(Expression.expSub(e1,e2), vars, scalar_eqn_indx, var_indxs_1,differentiateIfExp,iShared,source,iAcc);
      then
        (eqns, 1, shared);

    // array equations
    case (BackendDAE.ARRAY_EQUATION(dimSize=ds,left=e1,right=e2,source=source),_,_,_,_,_,_,_,_)
      equation
        _ = Expression.typeof(e1);
        e = Expression.expSub(e1,e2);
        (e,_) = Expression.extendArrExp(e,false);
        subslst = Expression.dimensionSizesSubscripts(ds);
        subslst = Expression.rangesToSubscripts(subslst);
        expl = List.map1r(subslst,Expression.applyExpSubscripts,e);

        var_indxs = fvarsInEqn(m, eqn_indx);
        // Remove duplicates and get in correct order: ascending index
        var_indxs_1 = List.sort(var_indxs,intGt);
        var_indxs_1 = List.sortedUnique(var_indxs_1, intEq);
        (eqns, shared) = calculateJacobianRowLst(expl, vars, scalar_eqn_indx, var_indxs_1,differentiateIfExp,iShared,source,iAcc);
        size = List.fold(ds,intMul,1);
      then
        (eqns, size, shared);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = BackendDump.dumpEqnsStr({inEquation});
        Debug.traceln("- BackendDAE.calculateJacobianRow failed on " + str);
      then
        fail();
  end match;
end calculateJacobianRow;

protected function calculateJacobianRowLst "author: Frenkel TUD 2012-06
  calls calculateJacobianRow2 for a list of DAE.Exp"
  input list<DAE.Exp> inExps;
  input BackendDAE.Variables vars;
  input Integer eqn_indx;
  input list<Integer> inIntegerLst;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input BackendDAE.Shared iShared;
  input DAE.ElementSource source;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> iAcc;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst = iAcc;
  output BackendDAE.Shared oShared = iShared;
protected
  Integer eqn_indx_arr = eqn_indx;
algorithm
  for e in inExps loop
    (outLst, oShared) := calculateJacobianRow2(e,vars,eqn_indx_arr,inIntegerLst,differentiateIfExp,oShared,source,outLst);
    eqn_indx_arr := eqn_indx_arr + 1;
  end for;
end calculateJacobianRowLst;

protected function calculateJacobianRow2 "author: PA
  Differentiates expression for each variable cref.
  inputs: (DAE.Exp,
             BackendDAE.Variables,
             int, /* equation index */
             int list) /* var indexes */
  outputs: ((int int Equation) list option)"
  input DAE.Exp inExp;
  input BackendDAE.Variables vars;
  input Integer eqn_indx;
  input list<Integer> inIntegerLst;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input BackendDAE.Shared iShared;
  input DAE.ElementSource source;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> iAcc;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst = iAcc;
  output BackendDAE.Shared oShared = iShared;
protected
  DAE.Exp e, e_1, dcrexp;
  BackendDAE.Var v;
  DAE.ComponentRef cr, dcr;
  Integer vindx;
  String str;
algorithm
  try
    for vindx in inIntegerLst loop
      v := BackendVariable.getVarAt(vars, vindx);
      cr := BackendVariable.varCref(v);
      if BackendVariable.isStateVar(v) then
        dcr := ComponentReference.crefPrefixDer(cr);
        dcrexp := Expression.crefExp(cr);
        dcrexp := DAE.CALL(Absyn.IDENT("der"), {dcrexp}, DAE.callAttrBuiltinReal);
        ((e, _)) := Expression.replaceExp(inExp, dcrexp, Expression.crefExp(dcr));
      end if;
      (e_1, oShared) := Differentiate.differentiateExpCrefFullJacobian(inExp, cr, vars, oShared);
      // e_1 already simplified in Differentiate.differentiateExpCrefFullJacobian!
      if not Expression.isZero(e_1) then
        outLst := (eqn_indx,vindx,BackendDAE.RESIDUAL_EQUATION(e_1,source,BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN))::outLst;
      end if;
    end for;
  else
    if Flags.isSet(Flags.FAILTRACE) then
      str := ExpressionDump.printExpStr(inExp);
      Debug.traceln("- BackendDAE.calculateJacobianRow2 failed on " + str);
    end if;
    fail();
  end try;
end calculateJacobianRow2;

protected function addBackendDAESharedJacobian
  input Option<BackendDAE.SymbolicJacobian> inSymJac;
  input BackendDAE.SparsePattern inSparsePattern;
  input BackendDAE.SparseColoring inSparseColoring;
  input BackendDAE.NonlinearPattern inNonlinearPattern;
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Variables globalKnownVars,exobj,av;
  BackendDAE.EquationArray remeqns,inieqns;
  list<DAE.Constraint> constrs;
  list<DAE.ClassAttributes> clsAttrs;
  FCore.Cache cache;
  FCore.Graph graph;
  DAE.FunctionTree funcTree;
  BackendDAE.EventInfo einfo;
  BackendDAE.ExternalObjectClasses eoc;
  BackendDAE.BackendDAEType btp;
  BackendDAE.SymbolicJacobians symjacs;
  BackendDAE.ExtraInfo ei;
algorithm
  symjacs := { (inSymJac, inSparsePattern, inSparseColoring, inNonlinearPattern),
               (NONE(), ({}, {}, ({}, {}), -1), {}, ({}, {}, ({}, {}), -1)),
               (NONE(), ({}, {}, ({}, {}), -1), {}, ({}, {}, ({}, {}), -1)),
               (NONE(), ({}, {}, ({}, {}), -1), {}, ({}, {}, ({}, {}), -1))};
  outShared := BackendDAEUtil.setSharedSymJacs(inShared, symjacs);
end addBackendDAESharedJacobian;

protected function addBackendDAESharedJacobianSparsePattern
  input BackendDAE.SparsePattern inSparsePattern;
  input BackendDAE.SparseColoring inSparseColoring;
  input Integer inIndex;
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Variables globalKnownVars,exobj,av;
  BackendDAE.EquationArray remeqns,inieqns;
  list<DAE.Constraint> constrs;
  list<DAE.ClassAttributes> clsAttrs;
  FCore.Cache cache;
  FCore.Graph graph;
  DAE.FunctionTree funcTree;
  BackendDAE.EventInfo einfo;
  BackendDAE.ExternalObjectClasses eoc;
  BackendDAE.BackendDAEType btp;
  BackendDAE.SymbolicJacobians symjacs;
  Option<BackendDAE.SymbolicJacobian> symJac;
  BackendDAE.ExtraInfo ei;
  BackendDAE.NonlinearPattern nonlinearPattern = BackendDAE.emptyNonlinearPattern;
algorithm
  BackendDAE.SHARED(symjacs=symjacs) := inShared;
  ((symJac, _, _, _)) := listGet(symjacs, inIndex);
  symjacs := List.set(symjacs, inIndex, ((symJac, inSparsePattern, inSparseColoring, nonlinearPattern)));
  outShared := BackendDAEUtil.setSharedSymJacs(inShared, symjacs);
end addBackendDAESharedJacobianSparsePattern;

public function analyzeJacobian "author: PA
  Analyse the Jacobian to find out if the Jacobian of system of equations
  can be solved at compile time or runtime or if it is a non-linear system
  of equations."
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerEquationLstOption;
  output BackendDAE.JacobianType outJacobianType;
  output Boolean jacConstant "true if jac is constant, does not check rhs";
algorithm
  (outJacobianType,jacConstant):=
  matchcontinue (vars,eqns,inTplIntegerIntegerEquationLstOption)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      Boolean b;
      BackendDAE.JacobianType jactype;
    case (_,_,SOME(jac))
      equation
        //str = BackendDump.dumpJacobianStr(SOME(jac));
        //print("analyze Jacobian: \n" + str + "\n");
        b = jacobianNonlinear(vars, jac);
        // check also if variables occur in if expressions
        ((_,false)) = if not b then BackendDAEUtil.traverseBackendDAEExpsEqnsWithStop(eqns,varsNotInRelations,(vars,true)) else (vars,false);
        //print("jac type: JAC_NONLINEAR() \n");
      then
        (BackendDAE.JAC_NONLINEAR(),false);

    case (_,_,SOME(jac))
      equation
        true = jacobianConstant(jac);
        b = rhsConstant(vars,eqns);
        jactype = if b then BackendDAE.JAC_CONSTANT() else BackendDAE.JAC_LINEAR();
        //print("jac type: " + if_(b,"JAC_CONSTANT()","JAC_LINEAR()")  + "\n");
      then
        (jactype,true);

    case (_,_,SOME(_)) then (BackendDAE.JAC_LINEAR(),false);
    case (_,_,NONE()) then (BackendDAE.JAC_NO_ANALYTIC(),false);
  end matchcontinue;
end analyzeJacobian;

protected function jacobianNonlinear "author: PA
  Check if Jacobian indicates a non-linear system.
  TODO: Algorithms and array equations"
  input BackendDAE.Variables vars;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean isNonLinear = false;
protected
  DAE.Exp e1,e2,e;
  BackendDAE.Equation eq;
  tuple<Integer, Integer, BackendDAE.Equation> tpl;
algorithm
  for tpl in inTplIntegerIntegerEquationLst loop
    (_,_,eq) := tpl;
    isNonLinear := match(vars,eq)
      case(_,BackendDAE.EQUATION(exp = e1,scalar = e2))
        then jacobianNonlinearExp(vars, e1) or jacobianNonlinearExp(vars, e2);
      case(_,BackendDAE.RESIDUAL_EQUATION(exp = e))
        then jacobianNonlinearExp(vars, e);
      end match;
    if isNonLinear then
      return;
    end if;
  end for;
end jacobianNonlinear;

protected function jacobianNonlinearExp "author: PA
  Checks whether the Jacobian indicates a non-linear system.
  This is true if the Jacobian contains any of the variables
  that is solved for."
  input BackendDAE.Variables vars;
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  (_,(_,outBoolean)) := Expression.traverseExpTopDown(inExp,traverserjacobianNonlinearExp,(vars,false));
end jacobianNonlinearExp;

protected function traverserjacobianNonlinearExp "author: Frenkel TUD 2012-08"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean> tpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,tpl)
    local
      BackendDAE.Variables vars;
      DAE.Exp e;
      DAE.ComponentRef cr;
      Boolean b;
    case (e as DAE.CREF(componentRef=cr),(vars,_))
      equation
        (_::_,_) = BackendVariable.getVar(cr, vars);
      then (e,false,(vars,true));

    case (e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),(vars,_))
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then (e,false,(vars,true));

    case (e as DAE.CALL(path=Absyn.IDENT(name = "pre")),_)
      then (e,false,tpl);

    case (e as DAE.CALL(path=Absyn.IDENT(name = "previous")),_)
      then (e,false,tpl);

    case (e,(_,b)) then (e,not b,tpl);
  end matchcontinue;
end traverserjacobianNonlinearExp;

protected function jacobianConstant "author: PA
  Checks if Jacobian is constant, i.e. all expressions in each equation are constant."
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean=true;
protected
  DAE.Exp e1,e2, e;
  tuple<Integer, Integer, BackendDAE.Equation> tpl;
  BackendDAE.Equation eqn;
algorithm
  /* TODO: Algorithms and ArrayEquations */

  for tpl in inTplIntegerIntegerEquationLst loop
    eqn := Util.tuple33(tpl);
    outBoolean := match eqn
      case BackendDAE.EQUATION(exp = e1,scalar = e2)
        then Expression.isConst(e1) and Expression.isConst(e2);
      case BackendDAE.RESIDUAL_EQUATION(exp = e)
        then Expression.isConst(e);
      case BackendDAE.SOLVED_EQUATION(exp = e)
        then Expression.isConst(e);
      case BackendDAE.ARRAY_EQUATION(left=e1, right=e2)
        then Expression.isConst(e1) and Expression.isConst(e2);
      case BackendDAE.COMPLEX_EQUATION(left=e1, right=e2)
        then Expression.isConst(e1) and Expression.isConst(e2);
      else false;
      end match;

    if not outBoolean then
      break;
    end if;

  end for;

end jacobianConstant;

public function isJacobianGeneric
  input BackendDAE.Jacobian inJac;
  output Boolean result;
algorithm
  result := match(inJac)
  case BackendDAE.GENERIC_JACOBIAN() then true;
  else false;
  end match;
end isJacobianGeneric;

protected function varsNotInRelations
  input output DAE.Exp exp;
  output Boolean cont;
  input output tuple<BackendDAE.Variables,Boolean> tpl;
algorithm
  (exp,cont,tpl) := match (exp,tpl)
    local
      DAE.Exp cond,t,f,e1;
      BackendDAE.Variables vars;
      Boolean b;
      Absyn.Path path;
      list<DAE.Exp> expLst;
    case (DAE.IFEXP(cond,t,f),(vars,b))
      equation
        // check if vars not in condition
        (_,(_,b)) = Expression.traverseExpTopDown(cond, BackendDAEUtil.getEqnsysRhsExp2, (vars,b));
        (t,(_,b)) = Expression.traverseExpTopDown(t, varsNotInRelations, (vars,b));
        (f,(_,b)) = Expression.traverseExpTopDown(f, varsNotInRelations, (vars,b));
      then (DAE.IFEXP(cond,t,f),false,(vars,b));

    case (DAE.CALL(path=Absyn.IDENT(name = "der")),_)
      then (exp,true,tpl);
    case (DAE.CALL(path = Absyn.IDENT(name = "pre")),_)
      then (exp,false,tpl);
    case (DAE.CALL(path = Absyn.IDENT(name = "previous")),_)
      then (exp,false,tpl);
    case (DAE.CALL(expLst=expLst),_)
      equation
        // check if vars occurs not in argument list
        (_,tpl) = Expression.traverseExpListTopDown(expLst, BackendDAEUtil.getEqnsysRhsExp2, tpl);
      then (exp,false,tpl);
    case (DAE.LBINARY(),_)
      equation
        // check if vars not in condition
        (_,tpl) = Expression.traverseExpTopDown(exp, BackendDAEUtil.getEqnsysRhsExp2, tpl);
      then (exp,false,tpl);
    case (DAE.LUNARY(),tpl)
      equation
        // check if vars not in condition
        (_,tpl) = Expression.traverseExpTopDown(exp, BackendDAEUtil.getEqnsysRhsExp2, tpl);
      then (exp,false,tpl);
    case (DAE.RELATION(),tpl)
      equation
        // check if vars not in condition
        (_,tpl) = Expression.traverseExpTopDown(exp, BackendDAEUtil.getEqnsysRhsExp2, tpl);
      then (exp,false,tpl);
    case (DAE.ASUB(exp=e1,sub=expLst),_)
      equation
        // check if vars not in condition
        (_,tpl as (_,b)) = Expression.traverseExpTopDown(e1, varsNotInRelations, tpl);
        if b then
          (_,tpl) = Expression.traverseExpListTopDown(expLst, BackendDAEUtil.getEqnsysRhsExp2, tpl);
        end if;
      then (exp,false,tpl);
    case (_,(_,b)) then (exp,b,tpl);
  end match;
end varsNotInRelations;

protected function rhsConstant "author: PA
  Determines if the right hand sides of an equation system,
  represented as a BackendDAE, is constant."
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  output Boolean outBoolean;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  if BackendEquation.equationArraySize(eqns) == 0 then
    outBoolean:= true;
  else
    repl := BackendDAEUtil.makeZeroReplacements(vars);
    ((_,outBoolean,_)) := BackendEquation.traverseEquationArray_WithStop(eqns,rhsConstant2,(vars,true,repl));
  end if;
end rhsConstant;

protected function rhsConstant2 "Helper function to rhsConstant, traverses equation list."
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements> inTpl;
  output BackendDAE.Equation outEq;
  output Boolean cont;
  output tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  (outEq,cont,outTpl) := matchcontinue (inEq,inTpl)
    local
      DAE.Exp new_exp,rhs_exp,e1,e2,e;
      Boolean b,res;
      BackendDAE.Equation eqn;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
    // check rhs for for EQUATION nodes.
    case (eqn as BackendDAE.EQUATION(exp = e1,scalar = e2),(vars,b,repl))
      equation
        new_exp = Expression.expSub(e1, e2);
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(new_exp, vars,NONE(),SOME(repl));
        res = Expression.isConst(rhs_exp);
      then (eqn,res,(vars,b and res,repl));
    // check rhs for for ARRAY_EQUATION nodes. check rhs for for RESIDUAL_EQUATION nodes.
    case (eqn as BackendDAE.ARRAY_EQUATION(left=e1,right=e2),(vars,b,repl))
      equation
        new_exp = Expression.expSub(e1, e2);
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(new_exp, vars,NONE(),SOME(repl));
        res = Expression.isConst(rhs_exp);
      then (eqn,res,(vars,b and res,repl));

    case (eqn as BackendDAE.COMPLEX_EQUATION(left=e1,right=e2),(vars,b,repl))
      equation
        new_exp = Expression.expSub(e1, e2);
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(new_exp, vars,NONE(),SOME(repl));
        res = Expression.isConst(rhs_exp);
      then (eqn,res,(vars,b and res,repl));

    case (eqn as BackendDAE.RESIDUAL_EQUATION(exp = e),(vars,b,repl)) /* check rhs for for RESIDUAL_EQUATION nodes. */
      equation
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(e, vars,NONE(),SOME(repl));
        res = Expression.isConst(rhs_exp);
      then (eqn,res,(vars,b and res,repl));

    case (eqn,(vars,_,repl)) then (eqn,false,(vars,false,repl));
  end matchcontinue;
end rhsConstant2;

function getJacobianResiduals
  input BackendDAE.BackendDAE jacDAE;
  output list<BackendDAE.Var> diffedRes;
protected
  BackendDAE.EqSystem syst;
algorithm
  syst :: _ := jacDAE.eqs;
  diffedRes := list(var for var guard(BackendVariable.isRESVar(var)) in BackendVariable.varList(syst.orderedVars));
end getJacobianResiduals;

// =============================================================================
// Function detects non-linear strong component in symbolic jacobians
//  - non-linear components should never appear in symbolic jacobian and
//    indicate an singular or wrong system
//  - this modules stops compiling and outputs an error, otherwise we
//    would get error at runtime compiling
// =============================================================================

function checkForNonLinearStrongComponents
"Checks for non-linear algebraic strong compontents and break if some found."
  input BackendDAE.SymbolicJacobian symbolicJacobian;
  output Boolean result;
protected
  BackendDAE.BackendDAE jacBDAE;
  String name;
algorithm
  (jacBDAE, name, _, _, _, _) := symbolicJacobian;
  try
    _ := BackendDAEUtil.mapEqSystem(jacBDAE, checkForNonLinearStrongComponents_work);
    result := true;
  else
    Error.addMessage(Error.INVALID_NONLINEAR_JACOBIAN_COMPONENT, {name});
    result := false;
  end try;
end checkForNonLinearStrongComponents;

function checkForNonLinearStrongComponents_work
  input output BackendDAE.EqSystem syst;
  input output BackendDAE.Shared shared;
protected
  BackendDAE.StrongComponents comps;
algorithm
  try
    BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := syst;
    for comp in comps loop
      () := match (comp)
        local
          BackendDAE.JacobianType jacTp;
        case BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_NONLINEAR())
          then fail();
        case BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_NO_ANALYTIC())
          then fail();
        case BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_GENERIC())
          then fail();
        case BackendDAE.TORNSYSTEM(linear=false)
          then fail();
         else ();
      end match;
    end for;
  else
    fail();
  end try;
end checkForNonLinearStrongComponents_work;


public function getFixedStatesForSelfdependentSets
  " author: kabdelhak
  Returns states to fix for initial problem in the case of selfdependent dynamic state sets"
  input BackendDAE.StateSet stateSet;
  input list<BackendDAE.Var> unfixedStates;
  input Integer toFix;
  output list<BackendDAE.Var> statesToFix;
protected
  list<tuple<Integer,BackendDAE.Var>> nonlinearCountLst = {};
  Integer nonlinearCount;
algorithm
  _:= match(stateSet.jacobian)
  local
    BackendDAE.SymbolicJacobian sJac;
    BackendDAE.BackendDAE dae;
    list<BackendDAE.Var> diffVars;
    String matrixName;
  case (BackendDAE.GENERIC_JACOBIAN(jacobian=SOME(sJac))) algorithm
    ((dae,matrixName,diffVars, _, _,_)) := sJac;
    for var in unfixedStates loop
      nonlinearCountLst := getNonlinearStateCount(var,unfixedStates,dae,matrixName)::nonlinearCountLst;
    end for;
  then 0;
  end match;
  statesToFix := fixedVarsFromNonlinearCount(nonlinearCountLst, toFix);
end getFixedStatesForSelfdependentSets;

protected function getNonlinearStateCount
  input BackendDAE.Var state;
  input list<BackendDAE.Var> diffVars;
  input BackendDAE.BackendDAE dae;
  input String matrixName;
  output tuple<Integer,BackendDAE.Var> outTpl;
protected
algorithm
  outTpl:=match(dae)
  local
    BackendDAE.EqSystems systs;
    tuple<BackendDAE.Var,list<BackendDAE.Var>,Integer,String> tpl;
    BackendDAE.Var outState;
    Integer nonlinearCount = 0;
  case BackendDAE.DAE(eqs=systs) algorithm
    tpl := (state,diffVars,nonlinearCount,matrixName);
    for syst in systs loop
      _:= match(syst)
      local
        BackendDAE.EquationArray eqnarray;

      case BackendDAE.EQSYSTEM(_,eqnarray,_,_,_,_,_,_) algorithm
        tpl := BackendEquation.traverseEquationArray(eqnarray,getNonlinearStateCount0,tpl);
      then 0;
      end match;
    end for;
    (outState,_,nonlinearCount,_) := tpl;
  then (nonlinearCount,outState);
  end match;

end getNonlinearStateCount;

protected function getNonlinearStateCount0
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.Var,list<BackendDAE.Var>,Integer,String> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.Var,list<BackendDAE.Var>,Integer,String> outTpl;
algorithm
  outEq := inEq;
  outTpl := match inEq
  local
    DAE.Exp exp, diffExp;
    BackendDAE.Var state;
    list<BackendDAE.Var> diffVars;
    Integer nonlinearCount;
    String matrixName;
    DAE.ComponentRef seedVar;
    list<DAE.Subscript> subs;
  case BackendDAE.EQUATION(scalar=exp) algorithm
    (state,diffVars,nonlinearCount,matrixName) := inTpl;
    // Differentiate equation to look for nonlinear dependencies
    seedVar := Differentiate.createSeedCrefName(BackendVariable.varCref(state),matrixName);
    diffExp := Differentiate.differentiateExpSolve(exp,seedVar,NONE());
    for var in diffVars loop
      if not ComponentReference.crefEqual(var.varName, state.varName) and Expression.expContains(diffExp,Expression.crefExp(var.varName)) then
        // Heuristic to punish vars with a value of zero
        if Expression.isZero(BackendVariable.varStartValue(var)) then
          nonlinearCount := nonlinearCount + 2;
        else
          nonlinearCount := nonlinearCount + 1;
        end if;
      end if;
    end for;
  then (state,diffVars,nonlinearCount,matrixName);
  end match;
end getNonlinearStateCount0;

protected function fixedVarsFromNonlinearCount
  input list<tuple<Integer,BackendDAE.Var>> tplLst;
  input Integer toFix;
  output list<BackendDAE.Var> fixedVars = {};
protected
  list<tuple<Integer,BackendDAE.Var>> sortedTplLst, strippedTplLst;
  BackendDAE.Var fixVar;
  Integer fixInt;
algorithm
  for tpl in tplLst loop
     (fixInt,fixVar) := tpl;
  end for;
  // Sort by nonlinear count and take first N states to fix
  sortedTplLst := List.sort(tplLst, Util.compareTupleIntGt);
  strippedTplLst := List.firstN(sortedTplLst,toFix);
  for tpl in strippedTplLst loop
    (_,fixVar) := tpl;
    fixVar.values := DAEUtil.setFixedAttr(fixVar.values,SOME(DAE.BCONST(true)));
    fixedVars := fixVar::fixedVars;
  end for;
end fixedVarsFromNonlinearCount;

protected function stripPartialDerNonlinearPattern
  "kabdelhak: this function strips a jacobian residual down to the original
  residual variable to get the equation mapping right. Used for nonlinear
  pattern analysis."
  input output BackendDAE.NonlinearPattern pat;
protected
  BackendDAE.NonlinearPatternCrefs pat_cref, pat_crefT;
  list<DAE.ComponentRef> v1, v2;
  Integer index;
algorithm
  (pat_cref, pat_crefT, (v1, v2), index) := pat;
  pat_cref := list(stripPartialDer(cref_tpl) for cref_tpl in pat_cref);
  pat_crefT := list(stripPartialDer(cref_tpl) for cref_tpl in pat_crefT);
  v1 := list(stripPartialDerWork(v) for v in v1);
  v2 := list(stripPartialDerWork(v) for v in v2);
  pat := (pat_cref, pat_crefT, (v1, v2), index);
end stripPartialDerNonlinearPattern;

protected function stripPartialDer
  input output BackendDAE.NonlinearPatternCref cref_tpl;
protected
  DAE.ComponentRef cref;
  list<DAE.ComponentRef> dependencies;
algorithm
  (cref, dependencies) := cref_tpl;
  (cref, _) := stripPartialDerWork(cref);
  dependencies := list(stripPartialDerWork(dep) for dep in dependencies);
  cref_tpl := (cref, dependencies);
end stripPartialDer;

protected function stripPartialDerWork
  input output DAE.ComponentRef cref;
  output Boolean strip;
algorithm
  (cref, strip) := match cref
    local
      DAE.ComponentRef cr;

    case DAE.CREF_IDENT() guard(StringUtil.startsWith(cref.ident, "$pDER")) then (cref, true);

    case DAE.CREF_QUAL()  guard(StringUtil.startsWith(cref.ident, "$pDER")) then (cref, true);

    case DAE.CREF_QUAL() algorithm
      (cr, strip) := stripPartialDerWork(cref.componentRef);
      if strip then
        cr := DAE.CREF_IDENT(cref.ident, cref.identType, cref.subscriptLst);
      else
        cr := DAE.CREF_QUAL(cref.ident, cref.identType, cref.subscriptLst, cr);
      end if;
    then (cr, false);

    else (cref, false);
  end match;
end stripPartialDerWork;

// =============================================================================
// [ASSC] section for analytical to symbolical singularity transformation
//
// Generates linear jacobian
// =============================================================================
public
type LinearJacobianRow = UnorderedMap<Integer, Real>;
type LinearJacobianRhs = array<.DAE.Exp>;
type LinearJacobianInd = array<tuple<Integer, Integer>>;

uniontype LinearJacobian
  record LINEAR_REAL_JACOBIAN
    array<LinearJacobianRow> rows   "all loop variables entries";
    LinearJacobianRhs rhs           "the expression containing all non loop variable entries";
    LinearJacobianInd ind           "equation indices  <array, scalar>";
    array<Boolean> eq_marks             "changed equations";
  end LINEAR_REAL_JACOBIAN;

  public function toString
    input SymbolicJacobian.LinearJacobian linJac;
    input String heading = "";
    output String str;
  algorithm
    str := "######################################################\n" +
        " LinearJacobian sparsity pattern: " + heading + "\n" +
        "######################################################\n" +
        "(scal_idx|arr_idx|changed) [var_index, value] || RHS_EXPRESSION\n";
    for idx in 1:arrayLength(linJac.rows) loop
      str := str + rowToString(linJac.rows[idx], linJac.rhs[idx], linJac.ind[idx], linJac.eq_marks[idx]);
    end for;
    str := str + "\n";
  end toString;

  protected function rowToString
    input SymbolicJacobian.LinearJacobianRow row;
    input DAE.Exp rhs;
    input tuple<Integer, Integer> indices;
    input Boolean changed;
    output String str;
  protected
    Integer i_arr, i_scal, index;
    Real value;
    list<tuple<Integer, Real>> row_lst = UnorderedMap.toList(row);
  algorithm
    (i_arr, i_scal) := indices;
    str := "(" + intString(i_arr) + "|" + intString(i_scal) + "|" + boolString(changed) +"):    ";
    if listEmpty(row_lst) then
      str := str + "EMPTY ROW     ";
    else
      for element in row_lst loop
        (index, value) := element;
        str := str + "[" + intString(index) + "|" + realString(value) + "] ";
      end for;
    end if;
    str := str + "    || RHS: " + ExpressionDump.printExpStr(ExpressionSimplify.simplify(rhs)) + "\n";
  end rowToString;

  public function generate
    "author: kabdelhak FHB 03-2021
     Generates a jacobian from algebraic loop equations which are linear
     w.r.t. all loopVars. Fails if these criteria are not met."
    input list<tuple<BackendDAE.Equation, tuple<Integer, Integer>>> loopEqs;
    input list<tuple<BackendDAE.Var, Integer>> loopVars;
    input array<Integer> ass1;
    output LinearJacobian linJac;
  protected
    Integer eqn_index = 1, var_index;
    Real constReal;
    LinearJacobianRow row;
    list<LinearJacobianRow> tmp_mat = {};
    list<DAE.Exp> tmp_rhs = {};
    list<tuple<Integer, Integer>> tmp_idx = {};
    BackendDAE.Equation eqn;
    tuple<Integer, Integer> index;
    Integer scal_idx;
    BackendDAE.Var var;
    DAE.Exp res, pDer;
    BackendVarTransform.VariableReplacements varRep;

    // Helper functions to either have integer or real valued coefficients
    evaluateFunc eFunc = if Flags.getConfigBool(Flags.REAL_ASSC) then Expression.getEvaluatedConstReal else intWrapperFunc;

    partial function evaluateFunc
      input DAE.Exp e;
      output Real v;
    end evaluateFunc;

    function intWrapperFunc extends evaluateFunc;
    algorithm
      v := intReal(Expression.getEvaluatedConstInteger(e));
    end intWrapperFunc;

  algorithm
    /* Add a replacement rule var->0 for each loopVar, so that the RHS can be determined afterwards */
    varRep := BackendVarTransform.emptyReplacements();
    for loopVar in loopVars loop
      (var, _) := loopVar;
      varRep := BackendVarTransform.addReplacement(varRep, BackendVariable.varCref(var), DAE.ICONST(0), NONE());
    end for;

    /* Loop over all equations and create residual expression. */
    for loopEq in loopEqs loop
      row := UnorderedMap.new<Real>(Util.id, intEq);
      (eqn, index) := loopEq;
      res := BackendEquation.createResidualExp(eqn);
      /* Loop over all variables and differentiate residual expression for each. */
      try
        for loopVar in loopVars loop
          (var, var_index) := loopVar;
          pDer := Differentiate.differentiateExpSolve(res, BackendVariable.varCref(var), NONE());
          (pDer, _) := ExpressionSimplify.simplify(pDer);
          constReal := eFunc(pDer);
          if not realEq(constReal, 0.0) then
            UnorderedMap.add(var_index, constReal, row);
          end if;
        end for;
        /*
          Save the full row.
            - row entries
            - rhs
            - equation index
          Perform var replacements, multiply by -1 and simplify for rhs.
          NOTE: Multiplication with -1 is not really necessary for the
                conversion of analytical to structural singularity, but
                would be necessary if used for anything else.
        */
        res := BackendVarTransform.replaceExp(res, varRep, NONE());
        tmp_mat := row :: tmp_mat;
        tmp_rhs := ExpressionSimplify.simplify(DAE.BINARY(DAE.ICONST(-1), DAE.MUL(DAE.T_UNKNOWN_DEFAULT), res)) :: tmp_rhs;
        tmp_idx := index :: tmp_idx;

        /* set var as matched so that it can be chosen as pivot element for gaussian elimination */
        (_, scal_idx) := index;
        eqn_index := eqn_index + 1;
      else
        /*
          Differentiation not possible or not convertible to a real.
          Purposely fails.
        */
      end try;
    end for;
    /* convert and store all data */
    linJac := LINEAR_REAL_JACOBIAN(
      rows      = listArray(tmp_mat),
      rhs       = listArray(tmp_rhs),
      ind       = listArray(tmp_idx),
      eq_marks  = arrayCreate(listLength(tmp_mat), false)
    );
  end generate;

  public function emptyOrSingle
    "author: kabdelhak FHB 03-2021
     Returns true if the linear real jacobian is empty or has only one single row."
    input LinearJacobian linJac;
    output Boolean empty = (arrayLength(linJac.rows) < 2)
                       and (arrayLength(linJac.rhs) < 2)
                       and (arrayLength(linJac.ind) < 2)
                       and (arrayLength(linJac.eq_marks) < 2);
  end emptyOrSingle;

  public function solve
    "author: kabdelhak FHB 03-2021
     Performs a gaussian elimination algorithm on the jacobian without reducing the
     pivot elements to one to maintain the integer structure. This guarantees that
     no numerical errors can occur and analytical singularities will be detected.
     Also keeps track of the RHS for later equation replacement.

    Performs gaussian elimination for one pivot row and all following rows to reduce.
    new_row = old_row * pivot_element - pivot_row * row_element
    Example:
      pivot idx: 2, because the first is zero
      pivot row:     |  0 -1 -4 |
      row-to change: | -3  2  3 |
      new_row:       |  3  0  5 |"
    input output LinearJacobian linJac;
  protected
    Integer col_index;
    Real piv_value, row_value;
  algorithm
    /*
      Gaussian Algorithm without rearranging rows.
    */
    for i in 1:arrayLength(linJac.rows) loop
      try
        /*
          no pivot element can be chosen?
          jump over all manipulations, nothing to do
        */
        (col_index, piv_value) := getPivot(linJac.rows[i]);

        //updatePivotRow(linJac.rows[i], piv_value);
        // ToDo: updating the pivot row would also need an update for the rhs!

        for j in i+1:arrayLength(linJac.rows) loop
          row_value := UnorderedMap.getOrDefault(col_index, linJac.rows[j], 0.0);
          if not realEq(row_value, 0.0) then
            // set row to processed and perform pivot step
            linJac.eq_marks[j] := true;
            solveRow(linJac.rows[i], linJac.rows[j], piv_value, row_value);
            //perform multiplication inside? use simplification of multiplication afterwards?
            linJac.rhs[j] := DAE.BINARY(
                                  DAE.BINARY(linJac.rhs[j], DAE.MUL(DAE.T_REAL_DEFAULT), DAE.RCONST(piv_value)),       // row_rhs * piv_elem
                                  DAE.SUB(DAE.T_REAL_DEFAULT),                                                    // -
                                  DAE.BINARY(linJac.rhs[i], DAE.MUL(DAE.T_REAL_DEFAULT), DAE.RCONST(row_value))   // piv_rhs * row_elem
                              );
          end if;
        end for;
      else
        /* no pivot element, nothing to do */
      end try;
    end for;
  end solve;

  public function solveRow
  "author: kabdelhak FHB 03-2021
   performs one single row update : new_row = old_row * pivot_element - pivot_row * row_element"
    input LinearJacobianRow pivot_row;
    input LinearJacobianRow row;
    input Real piv_value;
    input Real row_value;
  protected
    Integer idx;
    Real val, diag_val;
  algorithm
    // update all elements that are in the pivot row
    for idx in UnorderedMap.keyList(pivot_row) loop
      _ := match (UnorderedMap.get(idx, row), UnorderedMap.get(idx, pivot_row))

        // row to be updated has and element at this position
        case (SOME(val), SOME(diag_val)) algorithm
          val := val * piv_value - diag_val * row_value;
          if realAbs(val) < 1e-12 then
            /* delete element if zero */
            UnorderedMap.remove(idx, row);
          else
            UnorderedMap.add(idx, val, row);
          end if;
        then ();

        // row to be updated does not have an element at this position
        case (NONE(), SOME(diag_val)) algorithm
          UnorderedMap.add(idx, -diag_val * row_value, row);
        then ();

        else algorithm
          Error.assertion(false, getInstanceName() + " key does not have an element in pivot row.", sourceInfo());
        then ();
       end match;
    end for;

    // update all row elements that are not in pivot row
    for idx in UnorderedMap.keyList(row) loop
      _ := match (UnorderedMap.get(idx, row), UnorderedMap.get(idx, pivot_row))
        case (SOME(val), NONE()) algorithm
          val := val * piv_value;
          UnorderedMap.add(idx, val, row);
        then ();
        else ();
      end match;
    end for;
  end solveRow;

  public function updatePivotRow
  "author: kabdelhak FHB 03-2021
   updates the pivot row by dividing everything by its pivot value"
    input LinearJacobianRow pivot_row;
    input Real piv_value;
  protected
    Real value;
  algorithm
    if not realEq(piv_value, 1.0) then
      for idx in UnorderedMap.keyList(pivot_row) loop
        value := UnorderedMap.getOrFail(idx, pivot_row);
        UnorderedMap.add(idx, value/piv_value, pivot_row);
      end for;
    end if;
  end updatePivotRow;

  protected function getPivot
  "author: kabdelhak FHB 03-2021
   Returns the first element that can be chosen as pivot, fails if none can be chosen."
    input LinearJacobianRow pivot_row;
    output Integer idx;
    output Real value;
  algorithm
    if Vector.isEmpty(pivot_row.keys) then
      /* singular row */
      fail();
    else
      idx := UnorderedMap.firstKey(pivot_row);
      value := UnorderedMap.getOrFail(idx, pivot_row);
    end if;
  end getPivot;

  public function resolveASSC
  "author: kabdelhak FHB 03-2021
   Resolves analytical singularities by replacing the equations with
   zero rows in the jacobian with new equations. Needs preceeding
   solving of the linear real jacobian."
    input LinearJacobian linJac;
    input output array<Integer> ass1;
    input output array<Integer> ass2;
    input output BackendDAE.EqSystem syst;
    input Boolean init;
  protected
    Integer i_arr, i_scal;
    DAE.Exp lhs, rhs;
    BackendDAE.Equation newEqn;
    list<Integer> updateList_arr = {};
    array<list<Integer>> mapEqnIncRow;
    array<Integer> mapIncRowEqn;
    BackendDAE.IndexType indexType;
    Boolean fullASSC = Flags.getConfigBool(Flags.FULL_ASSC);
  algorithm
    for r in 1:arrayLength(linJac.rows) loop
      /*
        check if row has been changed
        for now also only resolve singularities and not replace full loop
        otherwise it sometimes leads to mixed determined systems
      */
      if linJac.eq_marks[r] and (UnorderedMap.isEmpty(linJac.rows[r]) or fullASSC) then
        (i_arr, i_scal) := linJac.ind[r];
        /* remove assignments */
        ass2[ass1[i_scal]] := -1;
        ass1[i_scal] := -1;

        /* replace equation */
        rhs := ExpressionSimplify.simplify(linJac.rhs[r]);
        lhs := generateLHSfromList(
          row_indices     = UnorderedMap.keyArray(linJac.rows[r]),
          row_values      = UnorderedMap.valueArray(linJac.rows[r]),
          vars            = syst.orderedVars
        );
        newEqn := BackendEquation.generateEquation(lhs, rhs);

        /* dump replacements */
        if Flags.isSet(Flags.DUMP_ASSC) or (Flags.isSet(Flags.BLT_DUMP) and UnorderedMap.isEmpty(linJac.rows[r])) then
          print("[ASSC] The equation: " + BackendDump.equationString(BackendEquation.get(syst.orderedEqs, i_arr)) + "\n");
          print("[ASSC] Gets replaced by equation: " + BackendDump.equationString(newEqn) + "\n");
        end if;

        syst.orderedEqs := BackendEquation.setAtIndex(syst.orderedEqs, i_arr, newEqn);
        updateList_arr := i_arr :: updateList_arr;
      end if;
    end for;
      /*
        update adjacency matrix and transposed adjacency matrix
      */
      if not listEmpty(updateList_arr) then
        try
          /* scalar = true */
          SOME((mapEqnIncRow, mapIncRowEqn, indexType, true, _)) := syst.mapping;
          syst := BackendDAEUtil.updateAdjacencyMatrixScalar(syst, indexType, NONE(), updateList_arr, mapEqnIncRow, mapIncRowEqn, false);
        else
          /*
            scalar = false,
            should never occur, just to have a fallback option if someone wants to use this algorithm somewhere else
          */
          syst := BackendDAEUtil.updateAdjacencyMatrix(syst, BackendDAE.SOLVABLE(), NONE(), updateList_arr, false);
        end try;
      end if;

      if not listEmpty(updateList_arr) and not Flags.isSet(Flags.DUMP_ASSC) and Flags.isSet(Flags.BLT_DUMP) then
        print("--- Some equations have been changed, for more information please use -d=dumpASSC.---\n\n");
      end if;
  end resolveASSC;

  protected function generateLHSfromList
  "author: kabdelhak FHB 03-2021
   Generates the LHS expression from a flattened linear real jacobian row.
   Only used for full replacement of causalized loop."
    input array<Integer> row_indices;
    input array<Real> row_values;
    input BackendDAE.Variables vars;
    output DAE.Exp lhs;
  protected
    Integer length = arrayLength(row_indices);
  algorithm
    // add first expression
    if length == 0 then
      lhs := DAE.RCONST(0.0);
    else
      lhs := DAE.BINARY(
                DAE.RCONST(row_values[1]),
                DAE.MUL(DAE.T_REAL_DEFAULT),
                BackendVariable.varExp(BackendVariable.getVarAt(vars, row_indices[1]))
             );
    end if;

    // add subsequent expressions
    for i in 2:arrayLength(row_indices) loop
      lhs := DAE.BINARY(lhs, DAE.ADD(DAE.T_REAL_DEFAULT), DAE.BINARY(
                DAE.RCONST(row_values[i]),
                DAE.MUL(DAE.T_REAL_DEFAULT),
                BackendVariable.varExp(BackendVariable.getVarAt(vars, row_indices[i]))
             ));
    end for;
  end generateLHSfromList;

  public function anyChanges
  "author: kabdelhak FHB 03-2021
   Returns true if any row of the jacobian got changed during gaussian elimination."
    input LinearJacobian linJac;
    output Boolean changed = false;
  algorithm
    for i in 1:arrayLength(linJac.eq_marks) loop
      if linJac.eq_marks[i] then
        changed := true;
        return;
      end if;
    end for;
  end anyChanges;
end LinearJacobian;

annotation(__OpenModelica_Interface="backend");
end SymbolicJacobian;
