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

encapsulated package SymbolicJacobian
" file:        SymbolicJacobian.mo
  package:     SymbolicJacobian
  description: This package contains stuff that is related to symbolic jacobian or sparsity structure.

  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;
public import FGraph;

protected import Array;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashSet;
protected import Ceval;
protected import ClockIndexes;
protected import Config;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Differentiate;
protected import DynamicOptimization;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Error;
protected import Flags;
protected import Global;
protected import Graph;
protected import HashSet;
protected import IndexReduction;
protected import List;
protected import SimCodeFunctionUtil;
protected import System;
protected import Util;
protected import Values;
protected import ValuesUtil;

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
public function detectSparsePatternODE
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
algorithm
  // lochel: This module fails for some models (e.g. #3543)
  try
    BackendDAE.DAE(eqs = eqs) := inBackendDAE;

    // prepare a DAE
    DAE := BackendDAEUtil.copyBackendDAE(inBackendDAE);
    DAE := BackendDAEOptimize.collapseIndependentBlocks(DAE);
    DAE := BackendDAEUtil.transformBackendDAE(DAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());

    // get states for DAE
    BackendDAE.DAE(eqs = {BackendDAE.EQSYSTEM(orderedVars = v)}, shared=shared) := DAE;
    states := BackendVariable.getAllStateVarFromVariables(v);

    // generate sparse pattern
    (sparsePattern, coloredCols) := generateSparsePattern(DAE, states, states);
    shared := addBackendDAESharedJacobianSparsePattern(sparsePattern, coloredCols, BackendDAE.SymbolicJacobianAIndex, shared);

    outBackendDAE := BackendDAE.DAE(eqs, shared);
  else
    // skip this optimization module
    Error.addCompilerWarning("The optimization module detectJacobianSparsePattern failed. This module will be skipped and the transformation process continued.");
    outBackendDAE := inBackendDAE;
  end try;
end detectSparsePatternODE;

// =============================================================================
// section for postOptModule >>generateSymbolicJacobianPast<<
//
// Symbolic Jacobian subsection
// =============================================================================

public function generateSymbolicJacobianPast
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE := matchcontinue(inBackendDAE)
  local
    BackendDAE.EqSystems eqs;
    BackendDAE.Shared shared;
    BackendDAE.SymbolicJacobian symJacA;
    BackendDAE.SparsePattern sparsePattern;
    BackendDAE.SparseColoring sparseColoring;
    DAE.FunctionTree funcs, functionTree;

  case(_) equation
    true = Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_JACOBIAN);
    System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
    BackendDAE.DAE(eqs=eqs,shared=shared) = inBackendDAE;
    (symJacA , sparsePattern, sparseColoring, funcs) = createSymbolicJacobianforStates(inBackendDAE);
    shared = addBackendDAESharedJacobian(symJacA, sparsePattern, sparseColoring, shared);
    functionTree = BackendDAEUtil.getFunctions(shared);
    functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
    shared = BackendDAEUtil.setSharedFunctionTree(shared, functionTree);
    outBackendDAE = BackendDAE.DAE(eqs,shared);
    _ = System.realtimeTock(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
  then outBackendDAE;

  else inBackendDAE;
  end matchcontinue;
end generateSymbolicJacobianPast;

protected function createSymbolicJacobianforStates "author: wbraun
  all functionODE equation are differentiated with respect to the states."
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.SymbolicJacobian outJacobian;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outSparseColoring;
  output DAE.FunctionTree outFunctionTree;
protected
  BackendDAE.BackendDAE backendDAE2;
  list<BackendDAE.Var>  varlst, knvarlst, states, inputvars, paramvars;
  BackendDAE.Variables v, kv;
algorithm
  if Flags.isSet(Flags.JAC_DUMP2) then
    print("analytical Jacobians -> start generate system for matrix A time : " + realString(clock()) + "\n");
  end if;

  backendDAE2 := BackendDAEUtil.copyBackendDAE(inBackendDAE);
  backendDAE2 := BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
  backendDAE2 := BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
  BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)},BackendDAE.SHARED(knownVars = kv)) := backendDAE2;

  // Prepare all needed variables
  varlst := BackendVariable.varList(v);
  _ := List.map(varlst,BackendVariable.varCref);
  knvarlst := BackendVariable.varList(kv);
  _ := List.map(knvarlst,BackendVariable.varCref);
  states := BackendVariable.getAllStateVarFromVariables(v);
  inputvars := List.select(knvarlst,BackendVariable.isInput);
  paramvars := List.select(knvarlst, BackendVariable.isParam);

  if Flags.isSet(Flags.JAC_DUMP2) then
    print("analytical Jacobians -> prepared vars for symbolic matrix A time: " + realString(clock()) + "\n");
  end if;
  if Flags.isSet(Flags.JAC_DUMP2) then
    BackendDump.bltdump("System to create symbolic jacobian of: ",backendDAE2);
  end if;
  (outJacobian, outSparsePattern, outSparseColoring, outFunctionTree) := createJacobian(backendDAE2,states,BackendVariable.listVar1(states),BackendVariable.listVar1(inputvars),BackendVariable.listVar1(paramvars),BackendVariable.listVar1(states),varlst,"A");
end createSymbolicJacobianforStates;

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
    BackendDAE.SymbolicJacobians linearModelMatrixes;
    DAE.FunctionTree funcs, functionTree;
    list< .DAE.Constraint> constraints;
  case(_) equation
    true = Flags.getConfigBool(Flags.GENERATE_SYMBOLIC_LINEARIZATION);
    System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
    BackendDAE.DAE(eqs=eqs,shared=shared) = inBackendDAE;
    (linearModelMatrixes, funcs) = createLinearModelMatrixes(inBackendDAE, Config.acceptOptimicaGrammar(), Flags.isSet(Flags.DIS_SYMJAC_FMI20));
    shared = BackendDAEUtil.setSharedSymJacs(shared, linearModelMatrixes);
    functionTree = BackendDAEUtil.getFunctions(shared);
    functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
    shared = BackendDAEUtil.setSharedFunctionTree(shared, functionTree);
    outBackendDAE = BackendDAE.DAE(eqs,shared);
    _  = System.realtimeTock(ClockIndexes.RT_CLOCK_EXECSTAT_JACOBIANS);
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
algorithm
  (osyst, outChanged) := matchcontinue(isyst)
    local
      BackendDAE.EquationArray orderedEqs;
      list<DAE.Exp> explst;
      String s;
    case BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) equation
      ((_, explst as _::_)) = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(orderedEqs, traverserinputDerivativesUsed, (BackendVariable.daeKnVars(inShared), {}));
      s = stringDelimitList(List.map(explst, ExpressionDump.printExpStr), "\n");
      Error.addMessage(Error.DERIVATIVE_INPUT, {s});
    then (BackendDAEUtil.setEqSystEqs(isyst, orderedEqs), true);

    else (isyst, inChanged);
  end matchcontinue;
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
        (var::{},_) = BackendVariable.getVar(cr, vars);
        true = BackendVariable.isVarOnTopLevelAndInput(var);
      then (e,false,(vars,e::explst));
    case (e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),(vars,explst))
      equation
        (var::{},_) = BackendVariable.getVar(cr, vars);
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
  isConst := not List.exist(eqs, variableResidual);
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
  array<Integer> ass1, ass2, ass1add, ass2add;
  BackendDAE.StrongComponents comps;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps)) := systIn;
  if not listEmpty(compsAdd) then
    ass1add := arrayCreate(listLength(compsAdd), 0);
    ass2add := arrayCreate(listLength(compsAdd), 0);
    ass1 := arrayAppend(ass1, ass1add);
    ass2 := arrayAppend(ass2, ass1add);
    List.map2_0(compsAdd, updateAssignment, ass1, ass2);
  end if;
  List.map2_0(compsNew, updateAssignment, ass1, ass2);
  comps := List.replaceAtWithList(compsNew, idx-1, comps);
  comps := listAppend(comps, compsAdd);
  systOut.matching := BackendDAE.MATCHING(ass1, ass2, comps);
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
    list<list<Real>> jacVals;
    BackendDAE.Matching matching;
    DAE.FunctionTree funcs;
    BackendDAE.Shared shared;
    BackendDAE.StateSets stateSets;
    BackendDAE.BaseClockPartitionKind partitionKind;

    array<Real> A,b;
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
  jacVals := evaluateConstantJacobian(listLength(var_lst),jac);
    //print("JacVals\n"+stringDelimitList(List.map(jacVals,rListStr),"\n")+"\n\n");

  A := arrayCreate(n*n,0.0);
  b :=  arrayCreate(n*n,0.0);  // i.e. a matrix for the b-vars to get their coefficients independently [(b1,0,0);(0,b2,0),(0,0,b3)]
  order := listArray(List.fill(0,n));
  for row in 1:n loop
    for col in 1:n loop
      entry := listGet(listGet(jacVals,row),col);
      arrayUpdate(A,((row-1)*n+col),entry);
    end for;
    arrayUpdate(b,(row-1)*n+row,1.0);
  end for;
    //print("b\n"+stringDelimitList(List.map(arrayList(b),realString),", ")+"\n\n");
    //print("A\n"+stringDelimitList(List.map(arrayList(A),realString),", ")+"\n\n");
  gauss(A,b,1,n,List.intRange(n),order);
    //print("the order: "+stringDelimitList(List.map(arrayList(order),intString),",")+"\n");

  (bVarsOut,bEqsOut) := createBVecVars(sysIdxIn,compIdxIn,n,DAE.T_REAL_DEFAULT,beqs);
  sysEqsOut := createSysEquations(A,b,n,order,var_lst,bVarsOut);
  sysIdxOut := sysIdxIn+1;
  orderOut := order;
end solveConstJacLinearSystem;

protected function createSysEquations "creates new equations for a linear system with constant Jacobian matrix.
  author: Waurich TUD 2015-03"
  input array<Real> A;
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
    coeffs := Array.getRange((row-1)*n+1,(row*n),A);
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
  input array<Real> A;
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
      range := List.deleteMember(rangeIn,pivotIdx);

      // the pivot row in the A-matrix divided by the pivot element
      for ic in indxIn:n loop
        pos := (pivotIdx-1)*n+ic;
        entry := arrayGet(A,pos);
        entry := realDiv(entry,pivot); //divide column entry with pivot element
          //print(" pos "+intString(pos)+" entry "+realString(arrayGet(A,pos))+"\n");
        arrayUpdate(A,pos,entry);
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
       first := arrayGet(A,(ir-1)*n+indxIn); //the first row element, that is going to be zero
         //print("first "+realString(first)+"\n");
          for ic in indxIn:n loop
          pos := (ir-1)*n+ic;
          entry := arrayGet(A,pos);  // the current entry
          pivot := arrayGet(A,(pivotIdx-1)*n+ic);  // the element from the column in the pivot row
            //print("pivot "+realString(pivot)+"\n");
            //print("ir "+intString(ir)+" pos "+intString(pos)+" entry0 "+realString(entry)+" entry1 "+realString(realSub(entry,realDiv(first,pivot)))+"\n");
          entry := realSub(entry,realMul(first,pivot));
          arrayUpdate(A,pos,entry);
          b_entry := arrayGet(b,pos);
          pivot := arrayGet(b,(pivotIdx-1)*n+ic);
          b_entry := b_entry - realMul(first,pivot);
          arrayUpdate(b,pos,b_entry);
          end for;
      end for;
        //print("A\n"+stringDelimitList(List.map(arrayList(A),realString),", ")+"\n\n");
        //print("b\n"+stringDelimitList(List.map(arrayList(b),realString),", ")+"\n\n");

      //print("new permutation: "+stringDelimitList(List.map(arrayList(permutation),intString),",")+"\n");
      //print("JACB "+intString(indxIn)+" \n"+stringDelimitList(List.map(arrayList(jacB),rListStr),"\n ")+"\n\n");
      gauss(A,b,indxIn+1,n,range,permutation);
    then();
  else ();
  end matchcontinue;
end gauss;

protected function getPivotElement "gets the highest element in the startIdx'th to n'th rows and the startidx'th column"
  input array<Real> A;
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
    entry := arrayGet(A,(i-1)*n+startIdx);
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
        eqn_lst = BackendEquation.getEqns(eindex, syst.orderedEqs);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, syst.orderedVars);
        (syst,shared) = solveLinearSystem(syst, shared, eqn_lst, eindex, var_lst, vindx, jac);
      then (syst,shared,true,sysIdxIn,compIdxIn+1);

    case ( syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), shared,
           BackendDAE.EQUATIONSYSTEM( eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(SOME(jac)),
                                      jacType=BackendDAE.JAC_LINEAR() ) )
      equation
        true = BackendDAEUtil.isSimulationDAE(ishared);
        //only the A-matrix is constant, apply Gaussian Elimination
        eqn_lst = BackendEquation.getEqns(eindex, eqns);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        true = jacobianIsConstant(jac);
        true = Flags.isSet(Flags.CONSTJAC);
        //true = intEq(compIdxIn,37) and intEq(sysIdxIn,1);
        //print("ITS CONSTANT\n");
        //print("THE COMPIDX: "+intString(compIdxIn)+" THE SYSIDX"+intString(sysIdxIn)+"\n");
          //BackendDump.dumpEqnsSolved2({comp},eqns,vars);
        eqn_lst = BackendEquation.getEqns(eindex,eqns);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, vars);
        (sysEqs, bEqs, bVars, order, sysIdx) =
            solveConstJacLinearSystem(syst, shared, eqn_lst, eindex, listReverse(var_lst), vindx, jac, sysIdxIn, compIdxIn);
          //print("the b-vector stuff \n");
          //BackendDump.printEquationList(bEqs);
          //BackendDump.printVarList(bVars);
          //print("the sysEqs stuff \n");
          //BackendDump.printEquationList(sysEqs);
        //build comps
          //print("size"+intString(BackendDAEUtil.equationSize(eqns))+"\n");
          //print("numberOfElement"+intString(BackendDAEUtil.equationArraySize(eqns))+"\n");
          //print("arrSize"+intString(BackendDAEUtil.equationArraySize2(eqns))+"\n");
          //print("length"+intString(listLength(BackendEquation.equationList(eqns)))+"\n");
        bVarIdcs = List.intRange2(BackendVariable.varsSize(vars)+1, BackendVariable.varsSize(vars)+listLength(bVars));
        bEqIdcs = List.intRange2(BackendDAEUtil.equationArraySize(eqns)+1, BackendDAEUtil.equationArraySize(eqns)+listLength(bEqs));
        bComps = List.threadMap(bEqIdcs, bVarIdcs, BackendDAEUtil.makeSingleEquationComp);
        sysComps = List.threadMap( List.map1(arrayList(order), List.getIndexFirst, eindex), listReverse(vindx),
                                   BackendDAEUtil.makeSingleEquationComp );
          //print("bCOMPS\n");
          //BackendDump.dumpComponents(bComps);
          //print("SYSCOMPS\n");
          //BackendDump.dumpComponents(sysComps);
        //build system
        syst.orderedVars = List.fold(bVars, BackendVariable.addVar, vars);
        eqns = List.fold(bEqs, BackendEquation.addEquation, eqns);
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
        sources = List.map1( sources, DAEUtil.addSymbolicTransformation,
                             DAE.LINEAR_SOLVED(names, jacVals, rhsVals, solvedVals) );
        (v, eqns, shared) = changeConstantLinearSystemVars( var_lst, solvedVals, sources, var_indxs,
                                                                           syst.orderedVars, syst.orderedEqs, ishared );
        syst.orderedVars = v;
        syst.orderedEqs = List.fold(eqn_indxs, BackendEquation.equationRemove, eqns);
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
        eqns = BackendEquation.addEquation(BackendDAE.EQUATION(e, DAE.RCONST(r), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN), eqns);
        (vars2,eqns,shared) = changeConstantLinearSystemVars(varlst,rlst,slst,vindxs,vars,eqns,ishared);
      then (vars2,eqns,shared);
    case (v::varlst,r::rlst,_::slst,indx::vindxs,vars,eqns,_)
      equation
        v1 = BackendVariable.setBindExp(v, SOME(DAE.RCONST(r)));
        v1 = BackendVariable.setVarStartValue(v1,DAE.RCONST(r));
        // ToDo: merge source of var and equation
        (vars1,_) = BackendVariable.removeVar(indx, vars);
        shared = BackendVariable.addKnVarDAE(v1,ishared);
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
  array<Real> tmp;
  list<array<Real>> tmp2;
  list<Real> rs;
algorithm
  rs := List.fill(0.0,size);
  tmp := listArray(rs);
  tmp2 := List.map(List.fill(tmp,size),arrayCopy);
  valarr := listArray(tmp2);
  List.map1_0(jac,evaluateConstantJacobian2,valarr);
  tmp2 := arrayList(valarr);
  vals := List.map(tmp2,arrayList);
end evaluateConstantJacobian;

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

protected function generateSparsePattern "author: wbraun
  Function generated for a given set of variables and
  equations the sparsity pattern and a coloring of Jacobian matrix A^(NxM).
    col: N = size(diffVars)
    rows : M = size(diffedVars)
  The sparsity pattern is represented basically as a list of lists, every list
  represents the non-zero elements of a row.

  The coloring is saved as a list of lists, every list contains the
  cols with the same color."
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inDiffVars "vars";
  input list<BackendDAE.Var> inDiffedVars "eqns";
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outColoredCols;
algorithm
  (outSparsePattern,outColoredCols) := matchcontinue(inBackendDAE,inDiffVars,inDiffedVars)
    local
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst, syst1;
      BackendDAE.StrongComponents comps;
      BackendDAE.IncidenceMatrix adjMatrix, adjMatrixT;
      BackendDAE.Matching bdaeMatching;

      list<tuple<Integer, list<Integer>>>  sparseGraph, sparseGraphT;
      array<tuple<Integer, list<Integer>>> arraysparseGraph;

      Integer sizeN, adjSize, adjSizeT;
      Integer nonZeroElements, maxColor;
      list<Integer> nodesList, nodesEqnsIndex;
      list<list<Integer>> sparsepattern,sparsepatternT, coloredlist;
      list<BackendDAE.Var> jacDiffVars, indiffVars, indiffedVars;
      BackendDAE.Variables varswithDiffs;
      BackendDAE.EquationArray orderedEqns;
      array<Option<list<Integer>>> forbiddenColor;
      array<Integer> colored, colored1, ass1, ass2;
      array<list<Integer>> coloredArray;

      list<DAE.ComponentRef> diffCompRefsLst, diffedCompRefsLst;
      array<DAE.ComponentRef> diffCompRefs, diffedCompRefs;

      array<list<Integer>> eqnSparse, varSparse, sparseArray, sparseArrayT;
      array<Integer> mark, usedvar;

      BackendDAE.SparseColoring coloring;
      list<list<DAE.ComponentRef>> translated;
      list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsetuple, sparsetupleT;

    case (_,{},_) then (({},{},({},{}), -1),{});
    case (_,_,{}) then (({},{},({},{}), -1),{});
    case(BackendDAE.DAE(eqs = (syst as BackendDAE.EQSYSTEM(matching=bdaeMatching as BackendDAE.MATCHING(comps=comps, ass1=ass1)))::{}),indiffVars,indiffedVars)
      equation
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print(" start getting sparsity pattern diff Vars : " + intString(listLength(indiffedVars))  + " diffed vars: " + intString(listLength(indiffVars)) +"\n");
        end if;
        // prepare crefs
        diffCompRefsLst = List.map(indiffVars, BackendVariable.varCref);
        diffedCompRefsLst = List.map(indiffedVars, BackendVariable.varCref);
        diffCompRefs = listArray(diffCompRefsLst);
        diffedCompRefs = listArray(diffedCompRefsLst);
        // create jacobian vars
        jacDiffVars =  list(BackendVariable.createpDerVar(v) for v in indiffVars);
        sizeN = arrayLength(diffCompRefs);

        // generate adjacency matrix including diff vars
        (syst1 as BackendDAE.EQSYSTEM(orderedVars=varswithDiffs,orderedEqs=orderedEqns)) = BackendDAEUtil.addVarsToEqSystem(syst,jacDiffVars);
        (adjMatrix, adjMatrixT) = BackendDAEUtil.incidenceMatrix(syst1,BackendDAE.SPARSE(),NONE());
        adjSize = arrayLength(adjMatrix) "number of equations";
        adjSizeT = arrayLength(adjMatrixT) "number of variables";

        // Debug dumping
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          BackendDump.printVarList(BackendVariable.varList(varswithDiffs));
          BackendDump.printEquationList(BackendEquation.equationList(orderedEqns));
          BackendDump.dumpIncidenceMatrix(adjMatrix);
          BackendDump.dumpIncidenceMatrixT(adjMatrixT);
          BackendDump.dumpFullMatching(bdaeMatching);
        end if;

        // get indexes of diffed vars (rows)
        nodesEqnsIndex = BackendVariable.getVarIndexFromVars(indiffedVars,varswithDiffs);
        nodesEqnsIndex = List.map1(nodesEqnsIndex, Array.getIndexFirst, ass1);

        // debug dump
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print("nodesEqnsIndexs: ");
          BackendDump.dumpIncidenceRow(nodesEqnsIndex);
          print("\n");
          print("analytical Jacobians[SPARSE] -> build sparse graph: " + realString(clock()) + "\n");
        end if;

        // prepare data for getSparsePattern
        eqnSparse = arrayCreate(adjSize, {});
        varSparse = arrayCreate(adjSizeT, {});
        mark = arrayCreate(adjSizeT, 0);
        usedvar = arrayCreate(adjSizeT, 0);
        usedvar = Array.setRange(adjSizeT-(sizeN-1), adjSizeT, usedvar, 1);

        //execStat("generateSparsePattern -> start ",ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        eqnSparse = getSparsePattern(comps, eqnSparse, varSparse, mark, usedvar, 1, adjMatrix, adjMatrixT);
        //execStat("generateSparsePattern -> end ",ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        // debug dump
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          BackendDump.dumpSparsePatternArray(eqnSparse);
          print("analytical Jacobians[SPARSE] -> prepared arrayList for transpose list: " + realString(clock()) + "\n");
        end if;

        // select nodesEqnsIndex and map index to incoming vars
        sparseArray = Array.select(eqnSparse, nodesEqnsIndex);
        sparsepattern = arrayList(sparseArray);
        sparsepattern = List.map1List(sparsepattern, intSub, adjSizeT-sizeN);

        //execStat("generateSparsePattern -> postProcess ",ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);

        // transpose the column-based pattern to row-based pattern
        sparseArrayT = arrayCreate(sizeN,{});
        sparseArrayT = transposeSparsePattern(sparsepattern, sparseArrayT, 1);
        sparsepatternT = arrayList(sparseArrayT);
        //execStat("generateSparsePattern -> postProcess2 " ,ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);

        nonZeroElements = List.lengthListElements(sparsepattern);
        if Flags.isSet(Flags.DUMP_SPARSE) then
          // dump statistics
          dumpSparsePatternStatistics(nonZeroElements,sparsepatternT);
          BackendDump.dumpSparsePattern(sparsepattern);
          BackendDump.dumpSparsePattern(sparsepatternT);
          //execStat("generateSparsePattern -> nonZeroElements: " + intString(nonZeroElements) + " " ,ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        end if;

        // translated to DAE.ComRefs
        translated = list(list(arrayGet(diffCompRefs, i) for i in lst) for lst in sparsepattern);
        sparsetuple = list((cr,t) threaded for cr in diffedCompRefs, t in translated);
        translated = list(list(arrayGet(diffedCompRefs, i) for i in lst) for lst in sparsepatternT);
        sparsetupleT = list((cr,t) threaded for cr in diffCompRefs, t in translated);

        // build up a bi-partied graph of pattern
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print("analytical Jacobians[SPARSE] -> build sparse graph.\n");
        end if;
        sparseArray = listArray(sparsepattern);
        nodesList = List.intRange2(1,adjSize);
        sparseGraph = Graph.buildGraph(nodesList,createBipartiteGraph,sparseArray);
        sparseGraphT = Graph.buildGraph(List.intRange2(1,sizeN),createBipartiteGraph,sparseArrayT);

        // debug dump
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print("sparse graph: \n");
          Graph.printGraphInt(sparseGraph);
          print("transposed sparse graph: \n");
          Graph.printGraphInt(sparseGraphT);
          print("analytical Jacobians[SPARSE] -> builded graph for coloring.\n");
        end if;

        // color sparse bipartite graph
        forbiddenColor = arrayCreate(sizeN,NONE());
        colored = arrayCreate(sizeN,0);
        arraysparseGraph = listArray(sparseGraph);
        //execStat("generateSparsePattern -> coloring start " ,ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        colored1 = Graph.partialDistance2colorInt(sparseGraphT, forbiddenColor, nodesList, arraysparseGraph, colored);
        //execStat("generateSparsePattern -> coloring end " ,ClockIndexes.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
        // get max color used
        maxColor = Array.fold(colored1, intMax, 0);

        // map index of that array into colors
        coloredArray = mapIndexColors(colored1, arrayLength(diffCompRefs), arrayCreate(maxColor, {}));

        if Flags.isSet(Flags.DUMP_SPARSE) then
          print("Print Coloring Cols: \n");
          BackendDump.dumpSparsePattern(arrayList(coloredArray));
        end if;

        coloring = list(list(arrayGet(diffCompRefs, i) for i in lst) for lst in coloredArray);

        //without coloring
        //coloring = List.transposeList({diffCompRefs});
        if Flags.isSet(Flags.DUMP_SPARSE_VERBOSE) then
          print("analytical Jacobians[SPARSE] -> ready! " + realString(clock()) + "\n");
        end if;
      then ((sparsetupleT, sparsetuple, (diffCompRefsLst, diffedCompRefsLst), nonZeroElements), coloring);
    else
      algorithm
        Error.addInternalError("function generateSparsePattern failed", sourceInfo());
      then fail();
  end matchcontinue;
end generateSparsePattern;

protected function dumpSparsePatternStatistics
  input Integer nonZeroElements;
  input list<list<Integer>> sparsepatternT;
protected
  Integer maxDegree;
algorithm
  (_, maxDegree) := List.mapFold(sparsepatternT, findDegrees, 1);
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
  input BackendDAE.IncidenceMatrix inMatrix;
  input BackendDAE.IncidenceMatrix inMatrixT;
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
    list<tuple<Integer,list<Integer>>> otherEqnVarTpl;
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
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEIFEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrixT, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEALGORITHM(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLECOMPLEXEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEWHENEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.SINGLEIFEQUATION(eqn=eqn,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVars = arrayGet(inMatrix, eqn);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, {eqn}, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.EQUATIONSYSTEM(eqns=eqns,vars=solvedVars)::rest,result,_,_,_,_,_,_)
      equation
        inputVarsLst = List.map1(eqns, Array.getIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

        result = getSparsePattern(rest, result,  invarSparse, inMark, inUsed, inmarkValue+1, inMatrix, inMatrixT);
      then result;
    case(BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=eqns,tearingvars=vars,otherEqnVarTpl=otherEqnVarTpl))::rest,result,_,_,_,_,_,_)
      equation
        inputVarsLst = List.map(otherEqnVarTpl,Util.tuple22);
        vars1 = List.flatten(inputVarsLst);
        eqns1 = List.map(otherEqnVarTpl,Util.tuple21);
        eqns = listAppend(eqns, eqns1);
        solvedVars = listAppend(vars, vars1);

        inputVarsLst = List.map1(eqns, Array.getIndexFirst, inMatrix);
        inputVars = List.flatten(inputVarsLst);
        inputVars = List.fold1(solvedVars, List.removeOnTrue, intEq, inputVars);

        getSparsePattern2(inputVars, solvedVars, eqns, ineqnSparse, invarSparse, inMark, inUsed, inmarkValue);

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
  localList := getSparsePatternHelp(inInputVars, invarSparse, inMark, inUsed, inmarkValue, {});
  List.map2_0(inSolvedVars, Array.updateIndexFirst, localList, invarSparse);
  List.map2_0(inEqns, Array.updateIndexFirst, localList, ineqnSparse);
end getSparsePattern2;

protected function getSparsePatternHelp
  input list<Integer> inInputVars;
  input array<list<Integer>> invarSparse;
  input array<Integer> inMark;
  input array<Integer> inUsed;
  input Integer inmarkValue;
  input list<Integer> inLocalList;
  output list<Integer> outLocalList;
algorithm
  outLocalList := match (inInputVars, invarSparse, inMark, inUsed, inmarkValue, inLocalList)
  local
    list<Integer> localList, varSparse, rest;
    Integer arrayElement, var;
    case ({},_,_,_,_,_) then inLocalList;
    case (var::rest,_,_,_,_,_)
      equation
        arrayElement = arrayGet(inUsed, var);
        localList = if intEq(1, arrayElement) then getSparsePatternHelp2(var, inMark, inmarkValue, inLocalList) else inLocalList;

        varSparse = arrayGet(invarSparse, var);
        localList = List.fold2(varSparse, getSparsePatternHelp2, inMark, inmarkValue, localList);
        localList =  getSparsePatternHelp(rest, invarSparse, inMark, inUsed, inmarkValue, localList);
      then localList;
  end match;
end getSparsePatternHelp;

protected function getSparsePatternHelp2
  input Integer inInputVar;
  input array<Integer> inMark;
  input Integer inmarkValue;
  input list<Integer> inLocalList;
  output list<Integer> outLocalList;
algorithm
  outLocalList := matchcontinue(inInputVar, inMark, inmarkValue, inLocalList)
    local
      Integer arrayElement;
    case (_,_,_,_)
      equation
        arrayElement = arrayGet(inMark, inInputVar);
        false  = intEq(inmarkValue, arrayElement);
        arrayUpdate(inMark, inInputVar, inmarkValue);
      then inInputVar::inLocalList;
   else
      then inLocalList;
  end matchcontinue;
end getSparsePatternHelp2;

protected function transposeSparsePattern
  input list<list<Integer>> inSparsePattern;
  input array<list<Integer>> inAccumList;
  input Integer inValue;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := match(inSparsePattern, inAccumList, inValue)
  local
    list<Integer> oneElem;
    list<list<Integer>> rest;
    array<list<Integer>>  accumList;
    case ({},_,_) then inAccumList;
    case (oneElem::rest, _, _)
      equation
        accumList = transposeSparsePattern2(oneElem, inAccumList, inValue);
       then transposeSparsePattern(rest, accumList, inValue+1);
  end match;
end transposeSparsePattern;

protected function transposeSparsePattern2
  input list<Integer> inSparsePatternElem;
  input array<list<Integer>> inAccumList;
  input Integer inValue;
  output array<list<Integer>> outSparsePattern;
algorithm
  outSparsePattern := match(inSparsePatternElem, inAccumList, inValue)
  local
    Integer oneElem;
    list<Integer> rest, tmplist;
    array<list<Integer>>  accumList;
    case ({},_,_) then inAccumList;
    case (oneElem::rest,_, _)
      equation
        tmplist = arrayGet(inAccumList,oneElem);
        accumList = arrayUpdate(inAccumList, oneElem, inValue::tmplist);
       then transposeSparsePattern2(rest, accumList, inValue);
  end match;
end transposeSparsePattern2;

protected function mapIndexColors
  input array<Integer> inColors;
  input Integer inMaxIndex;
  input array<list<Integer>> inArray;
  output array<list<Integer>> outColors;
algorithm
  outColors := matchcontinue(inColors, inMaxIndex, inArray)
    local
      Integer i, index;
      list<Integer> lst;
    case (_, 0, _) then inArray;
    case (_, i, _)
      equation
        index = arrayGet(inColors, i);
        lst = arrayGet(inArray, index);
        lst = listAppend({i},lst);
        arrayUpdate(inArray, index, lst);
      then
        mapIndexColors(inColors, i-1, inArray);
   else
      equation
        Error.addInternalError("function mapIndexColors failed", sourceInfo());
      then
         fail();
 end matchcontinue;
end mapIndexColors;

protected function createBipartiteGraph
  input Integer inNode;
  input array<list<Integer>> inSparsePattern;
  output list<Integer> outEdges;
algorithm
  outEdges := matchcontinue(inNode,inSparsePattern)
    case(_, _)
      equation
        outEdges = arrayGet(inSparsePattern,inNode);
    then outEdges;
    case(_, _)
      then {};
  end matchcontinue;
end createBipartiteGraph;

protected function createLinearModelMatrixes "This function creates the linear model matrices column-wise
  author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  input Boolean useOptimica;
  input Boolean noGenSymbolicJac;
  output BackendDAE.SymbolicJacobians outJacobianMatrixes;
  output DAE.FunctionTree outFunctionTree;

algorithm
  (outJacobianMatrixes, outFunctionTree) :=
  match (inBackendDAE, useOptimica, noGenSymbolicJac)
    local
      BackendDAE.BackendDAE backendDAE,backendDAE2,emptyBDAE;

      list<BackendDAE.Var>  varlst, knvarlst,  states, inputvars, inputvars2, outputvars, paramvars, states_inputs, conVarsList, fconVarsList, object;
      list<DAE.ComponentRef> comref_states, comref_inputvars, comref_outputvars, comref_vars, comref_knvars;
      DAE.ComponentRef leftcref;

      BackendDAE.Variables v,kv,statesarr,inputvarsarr,paramvarsarr,outputvarsarr, optimizer_vars, conVars;
      BackendDAE.EquationArray e;

      BackendDAE.SymbolicJacobians linearModelMatrices;
      BackendDAE.SymbolicJacobian linearModelMatrix;

      BackendDAE.SparsePattern sparsePattern;
      BackendDAE.SparseColoring sparseColoring;

      DAE.FunctionTree funcs, functionTree;
      list<DAE.Function> funcLst;

      BackendDAE.ExtraInfo ei;
      FCore.Cache cache;
      FCore.Graph graph;

    case (backendDAE, false, true)
      equation
        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)}, BackendDAE.SHARED(knownVars = kv, functionTree = functionTree, cache=cache, graph=graph, info=ei)) = backendDAE2;


        emptyBDAE = BackendDAE.DAE({BackendDAEUtil.createEqSystem(BackendVariable.emptyVars(), BackendEquation.emptyEqns())}, BackendDAEUtil.createEmptyShared(BackendDAE.JACOBIAN(), ei, cache, graph));
        // Prepare all needed variables
        varlst = BackendVariable.varList(v);
        knvarlst = BackendVariable.varList(kv);
        states = BackendVariable.getAllStateVarFromVariables(v);
        inputvars = List.select(knvarlst,BackendVariable.isInput);
        paramvars = List.select(knvarlst, BackendVariable.isParam);
        inputvars2 = List.select(knvarlst,BackendVariable.isVarOnTopLevelAndInput);
        outputvars = List.select(varlst, BackendVariable.isVarOnTopLevelAndOutput);

        statesarr = BackendVariable.listVar1(states);
        inputvarsarr = BackendVariable.listVar1(inputvars);
        paramvarsarr = BackendVariable.listVar1(paramvars);
        outputvarsarr = BackendVariable.listVar1(outputvars);

        // Generate sparse pattern for matrices A
        (sparsePattern, sparseColoring) = generateSparsePattern(backendDAE2, states, states);
        linearModelMatrices = {(SOME((emptyBDAE,"A",{},{},{})), sparsePattern, sparseColoring)};

        // Generate sparse pattern for matrices B
        (sparsePattern, sparseColoring) = generateSparsePattern(backendDAE2, inputvars2, states);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME((emptyBDAE,"B",{},{},{})), sparsePattern, sparseColoring)});

        // Generate sparse pattern for matrices C
        (sparsePattern, sparseColoring) = generateSparsePattern(backendDAE2, states, outputvars);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME((emptyBDAE,"C",{},{},{})), sparsePattern, sparseColoring)});

        // Generate sparse pattern for matrices D
        (sparsePattern, sparseColoring) = generateSparsePattern(backendDAE2, inputvars2, outputvars);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME((emptyBDAE,"D",{},{},{})), sparsePattern, sparseColoring)});
      then
        (linearModelMatrices, functionTree);

    case (backendDAE, false, _)
      equation
        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)}, BackendDAE.SHARED(knownVars = kv)) = backendDAE2;

        // Prepare all needed variables
        varlst = BackendVariable.varList(v);
        knvarlst = BackendVariable.varList(kv);
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
        (linearModelMatrix, sparsePattern, sparseColoring, functionTree) = createJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"A");
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = {(SOME(linearModelMatrix),sparsePattern,sparseColoring)};
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix A time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t inputs for matrices B
        (linearModelMatrix, sparsePattern, sparseColoring, funcs) = createJacobian(backendDAE2,inputvars2,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"B");
        functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix B time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t states for matrices C
        (linearModelMatrix, sparsePattern, sparseColoring, funcs) = createJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,outputvarsarr,varlst,"C");
        functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix C time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t inputs for matrices D
        (linearModelMatrix, sparsePattern, sparseColoring, funcs) = createJacobian(backendDAE2,inputvars2,statesarr,inputvarsarr,paramvarsarr,outputvarsarr,varlst,"D");
        functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix D time: " + realString(clock()) + "\n");
        end if;

      then
        (linearModelMatrices, functionTree);

    case (backendDAE, true, _) //  created linear model (matrixes) for optimization
      equation
        // A := der(x)
        // B := {der(x), con(x), L(x)}
        // C := {der(x), con(x), L(x), M(x)}
        // D := {}

        backendDAE2 = BackendDAEUtil.copyBackendDAE(backendDAE);
        backendDAE2 = BackendDAEOptimize.collapseIndependentBlocks(backendDAE2);
        backendDAE2 = BackendDAEUtil.transformBackendDAE(backendDAE2,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = v)}, BackendDAE.SHARED(knownVars = kv)) = backendDAE2;

        // Prepare all needed variables
        varlst = BackendVariable.varList(v);
        knvarlst = BackendVariable.varList(kv);
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
        (linearModelMatrix, sparsePattern, sparseColoring, functionTree) = createJacobian(backendDAE2,states,statesarr,inputvarsarr,paramvarsarr,statesarr,varlst,"A");

        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = {(SOME(linearModelMatrix),sparsePattern,sparseColoring)};
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix A time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t states&inputs for matrices B

        optimizer_vars = BackendVariable.addVariables(statesarr, BackendVariable.copyVariables(conVars));
        object = DynamicOptimization.checkObjectIsSet(outputvarsarr, BackendDAE.optimizationLagrangeTermName);
        optimizer_vars = BackendVariable.addVars(object, optimizer_vars);
        //BackendDump.printVariables(optimizer_vars);
        (linearModelMatrix, sparsePattern, sparseColoring, funcs) = createJacobian(backendDAE2,states_inputs,statesarr,inputvarsarr,paramvarsarr,optimizer_vars,varlst,"B");
        functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix B time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t states for matrices C
        object = DynamicOptimization.checkObjectIsSet(outputvarsarr, BackendDAE.optimizationMayerTermName);
        optimizer_vars = BackendVariable.addVars(object, optimizer_vars);
        //BackendDump.printVariables(optimizer_vars);
        (linearModelMatrix, sparsePattern, sparseColoring, funcs) = createJacobian(backendDAE2,states_inputs,statesarr,inputvarsarr,paramvarsarr,optimizer_vars,varlst,"C");
        functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
        backendDAE2 = BackendDAEUtil.setFunctionTree(backendDAE2, functionTree);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix C time: " + realString(clock()) + "\n");
        end if;

        // Differentiate the System w.r.t inputs for matrices D
        optimizer_vars = BackendVariable.emptyVars();
        optimizer_vars = BackendVariable.listVar1(fconVarsList);

        (linearModelMatrix, sparsePattern, sparseColoring, funcs) = createJacobian(backendDAE2, states_inputs, statesarr, inputvarsarr, paramvarsarr, optimizer_vars, varlst, "D");
        functionTree = DAEUtil.joinAvlTrees(functionTree, funcs);
        linearModelMatrices = listAppend(linearModelMatrices,{(SOME(linearModelMatrix),sparsePattern,sparseColoring)});
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated system for matrix D time: " + realString(clock()) + "\n");
        end if;

      then
        (linearModelMatrices, functionTree);
    else
      equation
        Error.addInternalError("Generation of LinearModel Matrices failed.", sourceInfo());
      then
        fail();
  end match;
end createLinearModelMatrixes;

protected function createJacobian "author: wbraun"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inDiffVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParameterVars;
  input BackendDAE.Variables inDifferentiatedVars;
  input list<BackendDAE.Var> inVars;
  input String inName;
  output BackendDAE.SymbolicJacobian outJacobian;
  output BackendDAE.SparsePattern outSparsePattern;
  output BackendDAE.SparseColoring outSparseColoring;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outJacobian, outSparsePattern, outSparseColoring, outFunctionTree) :=
  matchcontinue (inBackendDAE,inDiffVars,inStateVars,inInputVars,inParameterVars,inDifferentiatedVars,inVars,inName)
    local
      BackendDAE.BackendDAE backendDAE, reduceDAE;

      list<DAE.ComponentRef> comref_vars, comref_seedVars, comref_differentiatedVars;

      BackendDAE.Shared shared;
      BackendDAE.Variables  knvars, knvars1;
      list<BackendDAE.Var> diffedVars, diffVarsTmp, seedlst, knvarsTmp;
      String s,s1;

      BackendDAE.SparsePattern sparsepattern;
      BackendDAE.SparseColoring colsColors;

      DAE.FunctionTree funcs;

    case (_,_,_,_,_,_,_,_)
      equation

        diffedVars = BackendVariable.varList(inDifferentiatedVars);
        s =  intString(listLength(diffedVars));
        comref_differentiatedVars = List.map(diffedVars, BackendVariable.varCref);

        reduceDAE = BackendDAEUtil.reduceEqSystemsInDAE(inBackendDAE, diffedVars);

        comref_vars = List.map(inDiffVars, BackendVariable.varCref);
        seedlst = List.map1(comref_vars, createSeedVars, inName);
        s1 =  intString(listLength(inVars));

        //SimCodeFunctionUtil.execStat("analytical Jacobians -> starting to generate the jacobian. DiffVars:" + s + " diffed equations: " +  s1);

        // Differentiate the ODE system w.r.t states for jacobian
        (backendDAE as BackendDAE.DAE(shared=shared), funcs) = generateSymbolicJacobian(reduceDAE, inDiffVars, inDifferentiatedVars, BackendVariable.listVar1(seedlst), inStateVars, inInputVars, inParameterVars, inName);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated equations for Jacobian " + inName + " time: " + realString(clock()) + "\n");
        end if;
        //SimCodeFunctionUtil.execStat("analytical Jacobians -> generated jacobian equations");

        knvars1 = BackendVariable.daeKnVars(shared);
        knvarsTmp = BackendVariable.varList(knvars1);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> sorted know temp vars(" + intString(listLength(knvarsTmp)) + ") for Jacobian DAE time: " + realString(clock()) + "\n");
        end if;

        (backendDAE as BackendDAE.DAE(shared=shared)) = optimizeJacobianMatrix(backendDAE,comref_differentiatedVars,comref_vars);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> generated Jacobian DAE time: " + realString(clock()) + "\n");
        end if;

        knvars = BackendVariable.daeKnVars(shared);
        diffVarsTmp = BackendVariable.varList(knvars);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> sorted know diff vars(" + intString(listLength(diffVarsTmp)) + ") for Jacobian DAE time: " + realString(clock()) + "\n");
        end if;
        (_,knvarsTmp,_) = List.intersection1OnTrue(diffVarsTmp, knvarsTmp, BackendVariable.varEqual);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> sorted know vars(" + intString(listLength(knvarsTmp)) + ") for Jacobian DAE time: " + realString(clock()) + "\n");
        end if;
        knvars = BackendVariable.listVar1(knvarsTmp);
        backendDAE = BackendDAEUtil.setKnownVars(backendDAE, knvars);
        SimCodeFunctionUtil.execStat("analytical Jacobians -> generated optimized jacobians");

        // generate sparse pattern
        (sparsepattern,colsColors) = generateSparsePattern(reduceDAE, inDiffVars, diffedVars);
        //SimCodeFunctionUtil.execStat("analytical Jacobians -> generated generateSparsePattern");
     then
        ((backendDAE, inName, inDiffVars, diffedVars, inVars), sparsepattern, colsColors, funcs);
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

          b = Flags.disableDebug(Flags.EXEC_STAT);
          if Flags.isSet(Flags.JAC_DUMP) then
            BackendDump.bltdump("Symbolic Jacobian",backendDAE);
          end if;

          backendDAE2 = BackendDAEUtil.getSolvedSystemforJacobians(backendDAE,
                                                                   {"removeEqualFunctionCalls",
                                                                    "removeSimpleEquations",
                                                                    "evalFunc",
                                                                    "simplifyAllExpressions"},
                                                                   NONE(),
                                                                   NONE(),
                                                                   {"inlineArrayEqn",
                                                                    "constantLinearSystem",
                                                                    "removeSimpleEquations",
                                                                    "tearingSystem",
                                                                    "calculateStrongComponentJacobians",
                                                                    "removeConstants",
                                                                    "solveSimpleEquations",
                                                                    "simplifyTimeIndepFuncCalls",
                                                                    "simplifyAllExpressions"});
          _ = Flags.set(Flags.EXEC_STAT, b);
          if Flags.isSet(Flags.JAC_DUMP) then
            BackendDump.bltdump("Symbolic Jacobian",backendDAE2);
          end if;
        then backendDAE2;
     else
       equation
         Error.addInternalError("function optimizeJacobianMatrix failed", sourceInfo());
       then fail();
   end matchcontinue;
end optimizeJacobianMatrix;

protected function generateSymbolicJacobian "author: lochel"
  input BackendDAE.BackendDAE inBackendDAE;
  input list<BackendDAE.Var> inVars "wrt";
  input BackendDAE.Variables indiffedVars "unknowns?";
  input BackendDAE.Variables inseedVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParamVars;
  input String inMatrixName;
  output BackendDAE.BackendDAE outJacobian;
  output DAE.FunctionTree outFunctions;
algorithm
  (outJacobian,outFunctions) := matchcontinue(inBackendDAE, inVars, indiffedVars, inseedVars, inStateVars, inInputVars, inParamVars, inMatrixName)
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
      BackendDAE.Variables diffedVars;
      BackendDAE.BackendDAE jacobian;

      // BackendDAE
      BackendDAE.Variables orderedVars, jacOrderedVars; // ordered Variables, only states and alg. vars
      BackendDAE.Variables knownVars, jacKnownVars; // Known variables, i.e. constants and parameters
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs; // ordered Equations
      BackendDAE.EquationArray removedEqs, jacRemovedEqs; // Removed equations a=b
      // end BackendDAE

      list<BackendDAE.Var> diffVars, derivedVariables, diffvars, diffedVarLst;
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

    case(BackendDAE.DAE(shared=BackendDAE.SHARED(cache=cache, graph=graph, info=ei)), {}, _, _, _, _, _, _) equation
      jacobian = BackendDAE.DAE( {BackendDAEUtil.createEqSystem(BackendVariable.emptyVars(), BackendEquation.emptyEqns())},
                                 BackendDAEUtil.createEmptyShared(BackendDAE.JACOBIAN(), ei, cache, graph));
    then (jacobian, DAE.emptyFuncTree);

    case( BackendDAE.DAE( BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, matching=BackendDAE.MATCHING(ass2=ass2))::{},
                         BackendDAE.SHARED(knownVars=knownVars, cache=cache,graph=graph, functionTree=functions, info=ei) ),
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
      diffData = BackendDAE.DIFFINPUTDATA(SOME(diffVarsArr), SOME(diffedVars), SOME(knownVars), SOME(orderedVars), {}, comref_diffvars, SOME(matrixName));
      eqns = BackendEquation.equationList(orderedEqs);
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("*** analytical Jacobians -> before derive all equation." + realString(clock()) + "\n");
      end if;
      (derivedEquations, functions) = deriveAll(eqns, arrayList(ass2), x, diffData, {}, functions);
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("*** analytical Jacobians -> after derive all equation." + realString(clock()) + "\n");
      end if;
      // replace all der(x), since ExpressionSolve can't handle der(x) proper
      derivedEquations = BackendEquation.replaceDerOpInEquationList(derivedEquations);
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("*** analytical Jacobians -> created all derived equation time: " + realString(clock()) + "\n");
      end if;

      // create BackendDAE.DAE with differentiated vars and equations

      // all variables for new equation system
      // d(ordered vars)/d(dummyVar)
      diffvars = BackendVariable.varList(orderedVars);
      derivedVariables = createAllDiffedVars(diffvars, x, diffedVars, 0, matrixName, {});

      jacOrderedVars = BackendVariable.listVar1(derivedVariables);
      // known vars: all variable from original system + seed
      size = BackendVariable.varsSize(orderedVars) +
             BackendVariable.varsSize(knownVars) +
             BackendVariable.varsSize(inseedVars);
      jacKnownVars = BackendVariable.emptyVarsSized(size);
      jacKnownVars = BackendVariable.addVariables(orderedVars, jacKnownVars);
      jacKnownVars = BackendVariable.addVariables(knownVars, jacKnownVars);
      jacKnownVars = BackendVariable.addVariables(inseedVars, jacKnownVars);
      (jacKnownVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(jacKnownVars, BackendVariable.setVarDirectionTpl, (DAE.INPUT()));
      jacOrderedEqs = BackendEquation.listEquation(derivedEquations);


      shared = BackendDAEUtil.createEmptyShared(BackendDAE.JACOBIAN(), ei, cache, graph);

      jacobian = BackendDAE.DAE( BackendDAEUtil.createEqSystem(jacOrderedVars, jacOrderedEqs)::{},
                                 BackendDAEUtil.setSharedKnVars(shared, jacKnownVars) );
    then (jacobian, functions);

    else
     equation
      Error.addInternalError("function generateSymbolicJacobian failed", sourceInfo());
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
  outSeedVar := BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(),DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
end createSeedVars;

protected function createAllDiffedVars "author: wbraun"
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inIndex;
  input String inMatrixName;
  input list<BackendDAE.Var> iVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars, inCref,inAllVars,inIndex,inMatrixName,iVars)
  local
    BackendDAE.Var  r1,v1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<BackendDAE.Var> restVar;

    case({}, _, _, _, _, _)
    then listReverse(iVars);

    // skip for dicrete variable
    case(BackendDAE.VAR(varKind=BackendDAE.DISCRETE())::restVar,cref,_,_, _, _) equation
     then
       createAllDiffedVars(restVar,cref,inAllVars,inIndex, inMatrixName,iVars);

     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,_,_, _, _) equation
      ({_}, _) = BackendVariable.getVar(currVar, inAllVars);
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = Differentiate.createDifferentiatedCrefName(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
    then
      createAllDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName,r1::iVars);

    case(BackendDAE.VAR(varName=currVar)::restVar,cref,_,_, _, _) equation
      ({_}, _) = BackendVariable.getVar(currVar, inAllVars);
      derivedCref = Differentiate.createDifferentiatedCrefName(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.STATE_DER(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
    then
      createAllDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName,r1::iVars);

     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,_,_, _, _) equation
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = Differentiate.createDifferentiatedCrefName(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
    then
      createAllDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName,r1::iVars);

    case(BackendDAE.VAR(varName=currVar)::restVar,cref,_,_, _, _) equation
      derivedCref = Differentiate.createDifferentiatedCrefName(currVar, cref, inMatrixName);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
    then
      createAllDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName,r1::iVars);

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"SymbolicJacobian.createAllDiffedVars failed"});
    then fail();
  end matchcontinue;
end createAllDiffedVars;

protected function deriveAll "author: lochel"
  input list<BackendDAE.Equation> inEquations;
  input list<Integer> ass2;
  input DAE.ComponentRef inDiffCref;
  input BackendDAE.DifferentiateInputData inDiffData;
  input list<BackendDAE.Equation> inDerivedEquations;
  input DAE.FunctionTree inFunctions;
  output list<BackendDAE.Equation> outDerivedEquations;
  output DAE.FunctionTree outFunctions;
algorithm
  (outDerivedEquations, outFunctions) :=
  matchcontinue(inEquations, ass2, inDiffCref, inDiffData, inDerivedEquations, inFunctions)
    local
      BackendDAE.Equation currEquation;
      DAE.FunctionTree functions;
      list<BackendDAE.Equation> restEquations, derivedEquations, currDerivedEquations;
      BackendDAE.Variables allVars;
      list<BackendDAE.Var> solvedvars;
      list<Integer> ass2_1,solvedfor;
      Boolean b;

    case({}, _, _, _, _, _) then (listReverse(inDerivedEquations), inFunctions);

    case(currEquation::restEquations, _, _, BackendDAE.DIFFINPUTDATA(allVars=SOME(allVars)), _, _)
      equation
      if Flags.isSet(Flags.JAC_DUMP_EQN) then
        print("Derive Equation! Left on Stack: " + intString(listLength(restEquations)) + "\n");
        BackendDump.printEquationList({currEquation});
        print("\n");
      end if;

      // filter discrete equataions
      (solvedfor,ass2_1) = List.split(ass2, BackendEquation.equationSize(currEquation));
      solvedvars = List.map1r(solvedfor,BackendVariable.getVarAt, allVars);
      b = List.mapAllValueBool(solvedvars, BackendVariable.isVarDiscrete, true);
      b = b or BackendEquation.isWhenEquation(currEquation);

      (currDerivedEquations, functions) = deriveAllHelper(b, currEquation, inDiffCref, inDiffData, inFunctions);
      derivedEquations = listAppend(currDerivedEquations, inDerivedEquations);

      if Flags.isSet(Flags.JAC_DUMP_EQN) then
        BackendDump.printEquationList(currDerivedEquations);
        print("\n");
      end if;
      (derivedEquations, functions) = deriveAll(restEquations, ass2_1, inDiffCref, inDiffData, derivedEquations, functions);
     then
       (derivedEquations, functions);

    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"SymbolicJacobian.deriveAll failed"});
    then fail();

  end matchcontinue;
end deriveAll;

protected function deriveAllHelper "author: wbraun"
  input Boolean isDiscrete;
  input BackendDAE.Equation inEquation;
  input DAE.ComponentRef inDiffCref;
  input BackendDAE.DifferentiateInputData inDiffData;
  input DAE.FunctionTree inFunctions;
  output list<BackendDAE.Equation> outDerivedEquations;
  output DAE.FunctionTree outFunctions;
algorithm
  (outDerivedEquations, outFunctions) :=
  match (isDiscrete)
    local
      BackendDAE.Equation derEquation;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      BackendDAE.Variables allVars, paramVars, stateVars, knownVars;
      list<Integer> ass2_1, solvedfor;

    case (true) equation
      if Flags.isSet(Flags.JAC_WARNINGS) then
        print("BackendDAEOptimize.derive: discrete equation has been removed.\n");
      end if;
    then ({}, inFunctions);

    case (false) equation
      (derEquation, functions) = Differentiate.differentiateEquation(inEquation, inDiffCref, inDiffData, BackendDAE.GENERIC_GRADIENT(), inFunctions);
    then ({derEquation}, functions);
  end match;
end deriveAllHelper;

public function getJacobianMatrixbyName
  input BackendDAE.SymbolicJacobians injacobianMatrixes;
  input String inJacobianName;
  output Option<tuple<Option<BackendDAE.SymbolicJacobian>, BackendDAE.SparsePattern, BackendDAE.SparseColoring>> outMatrix;
algorithm
  outMatrix := matchcontinue(injacobianMatrixes)
    local
      tuple<Option<BackendDAE.SymbolicJacobian>, BackendDAE.SparsePattern, BackendDAE.SparseColoring> matrix;
      BackendDAE.SymbolicJacobians rest;
      String name;

    case (matrix as (SOME((_,name,_,_,_)), _, _))::_ equation
      true = stringEq(name, inJacobianName);
    then SOME(matrix);

    case _::rest
    then getJacobianMatrixbyName(rest, inJacobianName);

    else NONE();
  end matchcontinue;
end getJacobianMatrixbyName;

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
        (comps, shared) = calculateJacobiansComponents(comps, vars, eqns, shared, {});
        syst.matching = BackendDAE.MATCHING(ass1, ass2, comps);
      then (syst, shared);
  end match;
end calculateEqSystemJacobians;

protected function calculateJacobiansComponents
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input  BackendDAE.Shared inShared;
  input BackendDAE.StrongComponents inAccum;
  output BackendDAE.StrongComponents outComps;
  output  BackendDAE.Shared outShared;
algorithm
  (outComps, outShared) := match (inComps, inVars, inEqns, inShared, inAccum)
    local
      BackendDAE.StrongComponents rest, result;
      BackendDAE.StrongComponent comp;
      BackendDAE.Shared shared;
      case ({}, _, _, _, _) then (listReverse(inAccum), inShared);
      case (comp::rest, _, _, _, _)
        equation
          (comp, shared) = calculateJacobianComponent(comp, inVars, inEqns, inShared);
          (result, shared) = calculateJacobiansComponents(rest, inVars, inEqns, shared, comp::inAccum);
      then (result, shared);
  end match;
end calculateJacobiansComponents;


protected function convertResidualsIntoSolvedEquations "author: lochel
  This function converts residuals into solved equations of the following form:
    e.g.: 0 = a+b -> $res1 = a+b"
  input list<BackendDAE.Equation> inResidualList;
  output list<BackendDAE.Equation> outEquationList;
  output list<BackendDAE.Var> outVariableList;
algorithm
  (outEquationList, outVariableList) := convertResidualsIntoSolvedEquations2(inResidualList, 1, {}, {});
end convertResidualsIntoSolvedEquations;

protected function convertResidualsIntoSolvedEquations2 "author: lochel"
  input list<BackendDAE.Equation> inEquationList;
  input Integer inIndex;
  input list<BackendDAE.Equation> iEquationList;
  input list<BackendDAE.Var> iVariableList;
  output list<BackendDAE.Equation> outEquationList;
  output list<BackendDAE.Var> outVariableList;
algorithm
  (outEquationList, outVariableList) := matchcontinue(inEquationList, inIndex)
    local
      Integer index;
      list<BackendDAE.Equation> restEquationList;
      list<BackendDAE.Equation> equationList;
      list<BackendDAE.Var> variableList;

      DAE.Exp expVarName;
      DAE.Exp exp;
      DAE.ElementSource source "origin of equation";

      String varName;
      DAE.ComponentRef componentRef;
      BackendDAE.Equation currEquation;
      BackendDAE.Var currVariable;
      BackendDAE.EquationAttributes eqAttr;

    case ({}, _)
    then (listReverse(iEquationList), listReverse(iVariableList));

    case ((BackendDAE.RESIDUAL_EQUATION(exp=exp,source=source,attr=eqAttr))::restEquationList, index) equation
      varName = "$res" + intString(index);
      componentRef = DAE.CREF_IDENT(varName, DAE.T_REAL_DEFAULT, {});
      expVarName = DAE.CREF(componentRef, DAE.T_REAL_DEFAULT);
      currEquation = BackendDAE.EQUATION(expVarName, exp, source, eqAttr);

      currVariable = BackendDAE.VAR(componentRef, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);

      (equationList, variableList) = convertResidualsIntoSolvedEquations2(restEquationList, index+1,currEquation::iEquationList,currVariable::iVariableList);
    then (equationList, variableList);

    case (currEquation::_, _) equation
      Error.addInternalError("function convertResidualsIntoSolvedEquations2 failed", sourceInfo());
    then fail();

    else equation
      Error.addInternalError("function convertResidualsIntoSolvedEquations2 failed", sourceInfo());
    then fail();
  end matchcontinue;
end convertResidualsIntoSolvedEquations2;

protected function calculateJacobianComponent
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
      list<tuple<Integer,list<Integer>>> otherEqnVarTpl,otherEqnVarTpl2;
      Boolean b;

      list<list<Integer>> otherVarsIntsLst;
      list<Integer> otherEqnsInts, otherVarsInts;

      list<BackendDAE.Var> iterationvars, ovarsLst, resVarsLst;
      BackendDAE.Variables diffVars, ovars, resVars;
      list<BackendDAE.Equation> reqns, otherEqnsLst;
      BackendDAE.EquationArray eqns, oeqns;

      BackendDAE.Jacobian jacobian,jacobian2;

      String name;
      Boolean mixedSystem;

      case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=iterationvarsInts, residualequations=residualequations, otherEqnVarTpl=otherEqnVarTpl), NONE(), linear=b, mixedSystem=mixedSystem), _, _, _)
        equation
          true = (Flags.isSet(Flags.NLS_ANALYTIC_JACOBIAN) and not b) or b;
          // get iteration vars
          iterationvars = List.map1r(iterationvarsInts, BackendVariable.getVarAt, inVars);
          iterationvars = List.map(iterationvars, BackendVariable.transformXToXd);
          diffVars = BackendVariable.listVar1(iterationvars);

          // get residual eqns
          reqns = BackendEquation.getEqns(residualequations, inEqns);
          reqns = BackendEquation.replaceDerOpInEquationList(reqns);
          eqns = BackendEquation.listEquation(reqns);
          // create  residual equations
          reqns = BackendEquation.traverseEquationArray(eqns, BackendEquation.traverseEquationToScalarResidualForm, {});
          reqns = listReverse(reqns);
          (reqns, resVarsLst) = convertResidualsIntoSolvedEquations(reqns);
          resVars = BackendVariable.listVar1(resVarsLst);
          eqns = BackendEquation.listEquation(reqns);

          // get other eqns
          otherEqnsInts = List.map(otherEqnVarTpl, Util.tuple21);
          otherEqnsLst = BackendEquation.getEqns(otherEqnsInts, inEqns);
          otherEqnsLst = BackendEquation.replaceDerOpInEquationList(otherEqnsLst);
          oeqns = BackendEquation.listEquation(otherEqnsLst);

          // get other vars
          otherVarsIntsLst = List.map(otherEqnVarTpl, Util.tuple22);
          otherVarsInts = List.flatten(otherVarsIntsLst);
          ovarsLst = List.map1r(otherVarsInts, BackendVariable.getVarAt, inVars);
          ovarsLst = List.map(ovarsLst, BackendVariable.transformXToXd);
          ovars = BackendVariable.listVar1(ovarsLst);

          //generate jacobian name
          name = "NLSJac" + intString(System.tmpTickIndex(Global.backendDAE_jacobianSeq));

          // generate generic jacobian backend dae
          (jacobian, shared) = getSymbolicJacobian(diffVars, eqns, resVars, oeqns, ovars, inShared, inVars, name);

      then (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(iterationvarsInts, residualequations, otherEqnVarTpl, jacobian), NONE(), b, mixedSystem), shared);

      case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=iterationvarsInts, residualequations=residualequations, otherEqnVarTpl=otherEqnVarTpl), SOME(BackendDAE.TEARINGSET(tearingvars=iterationvarsInts2, residualequations=residualequations2, otherEqnVarTpl=otherEqnVarTpl2)), linear=b, mixedSystem=mixedSystem), _, _, _)
        equation
          true = (Flags.isSet(Flags.NLS_ANALYTIC_JACOBIAN) and not b) or b;

          // Get Jacobian for strict tearing set
          // get iteration vars
          iterationvars = List.map1r(iterationvarsInts, BackendVariable.getVarAt, inVars);
          iterationvars = List.map(iterationvars, BackendVariable.transformXToXd);
          diffVars = BackendVariable.listVar1(iterationvars);

          // get residual eqns
          reqns = BackendEquation.getEqns(residualequations, inEqns);
          reqns = BackendEquation.replaceDerOpInEquationList(reqns);
          eqns = BackendEquation.listEquation(reqns);
          // create  residual equations
          reqns = BackendEquation.traverseEquationArray(eqns, BackendEquation.traverseEquationToScalarResidualForm, {});
          reqns = listReverse(reqns);
          (reqns, resVarsLst) = convertResidualsIntoSolvedEquations(reqns);
          resVars = BackendVariable.listVar1(resVarsLst);
          eqns = BackendEquation.listEquation(reqns);

          // get other eqns
          otherEqnsInts = List.map(otherEqnVarTpl, Util.tuple21);
          otherEqnsLst = BackendEquation.getEqns(otherEqnsInts, inEqns);
          otherEqnsLst = BackendEquation.replaceDerOpInEquationList(otherEqnsLst);
          oeqns = BackendEquation.listEquation(otherEqnsLst);

          // get other vars
          otherVarsIntsLst = List.map(otherEqnVarTpl, Util.tuple22);
          otherVarsInts = List.flatten(otherVarsIntsLst);
          ovarsLst = List.map1r(otherVarsInts, BackendVariable.getVarAt, inVars);
          ovarsLst = List.map(ovarsLst, BackendVariable.transformXToXd);
          ovars = BackendVariable.listVar1(ovarsLst);

          //generate jacobian name
          name = "NLSJac" + intString(System.tmpTickIndex(Global.backendDAE_jacobianSeq));

          // generate generic jacobian backend dae
          (jacobian, shared) = getSymbolicJacobian(diffVars, eqns, resVars, oeqns, ovars, inShared, inVars, name);


          // Get Jacobian for casual tearing set
          // get iteration vars
          iterationvars = List.map1r(iterationvarsInts2, BackendVariable.getVarAt, inVars);
          iterationvars = List.map(iterationvars, BackendVariable.transformXToXd);
          diffVars = BackendVariable.listVar1(iterationvars);

          // get residual eqns
          reqns = BackendEquation.getEqns(residualequations2, inEqns);
          reqns = BackendEquation.replaceDerOpInEquationList(reqns);
          eqns = BackendEquation.listEquation(reqns);
          // create  residual equations
          reqns = BackendEquation.traverseEquationArray(eqns, BackendEquation.traverseEquationToScalarResidualForm, {});
          reqns = listReverse(reqns);
          (reqns, resVarsLst) = convertResidualsIntoSolvedEquations(reqns);
          resVars = BackendVariable.listVar1(resVarsLst);
          eqns = BackendEquation.listEquation(reqns);

          // get other eqns
          otherEqnsInts = List.map(otherEqnVarTpl2, Util.tuple21);
          otherEqnsLst = BackendEquation.getEqns(otherEqnsInts, inEqns);
          otherEqnsLst = BackendEquation.replaceDerOpInEquationList(otherEqnsLst);
          oeqns = BackendEquation.listEquation(otherEqnsLst);

          // get other vars
          otherVarsIntsLst = List.map(otherEqnVarTpl2, Util.tuple22);
          otherVarsInts = List.flatten(otherVarsIntsLst);
          ovarsLst = List.map1r(otherVarsInts, BackendVariable.getVarAt, inVars);
          ovarsLst = List.map(ovarsLst, BackendVariable.transformXToXd);
          ovars = BackendVariable.listVar1(ovarsLst);

          //generate jacobian name
          name = "NLSJac" + intString(System.tmpTickIndex(Global.backendDAE_jacobianSeq));

          // generate generic jacobian backend dae
          (jacobian2, shared) = getSymbolicJacobian(diffVars, eqns, resVars, oeqns, ovars, inShared, inVars, name);

      then (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(iterationvarsInts, residualequations, otherEqnVarTpl, jacobian), SOME(BackendDAE.TEARINGSET(iterationvarsInts2, residualequations2, otherEqnVarTpl2, jacobian2)), b, mixedSystem), shared);

      // do not touch linear and constant systems for now
      case (comp as BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_CONSTANT()), _, _, _) then (comp, inShared);
      case (comp as BackendDAE.EQUATIONSYSTEM(jacType=BackendDAE.JAC_LINEAR()), _, _, _) then (comp, inShared);

      case (BackendDAE.EQUATIONSYSTEM(eqns=residualequations, vars=iterationvarsInts, mixedSystem=mixedSystem), _, _, _)
        equation
          true = Flags.isSet(Flags.NLS_ANALYTIC_JACOBIAN);
          // get iteration vars
          iterationvars = List.map1r(iterationvarsInts, BackendVariable.getVarAt, inVars);
          iterationvars = List.map(iterationvars, BackendVariable.transformXToXd);
          iterationvars = listReverse(iterationvars);
          diffVars = BackendVariable.listVar1(iterationvars);

          // get residual eqns
          reqns = BackendEquation.getEqns(residualequations, inEqns);
          reqns = BackendEquation.replaceDerOpInEquationList(reqns);
          eqns = BackendEquation.listEquation(reqns);
          // create  residual equations
          reqns = BackendEquation.traverseEquationArray(eqns, BackendEquation.traverseEquationToScalarResidualForm, {});
          reqns = listReverse(reqns);
          (reqns, resVarsLst) = convertResidualsIntoSolvedEquations(reqns);
          resVars = BackendVariable.listVar1(resVarsLst);
          eqns = BackendEquation.listEquation(reqns);

          // other eqns and vars are empty
          oeqns = BackendEquation.listEquation({});
          ovars =  BackendVariable.emptyVars();

          //generate jacobian name
          name = "NLSJac" + intString(System.tmpTickIndex(Global.backendDAE_jacobianSeq));

          // generate generic jacobian backend dae
          (jacobian, shared) = getSymbolicJacobian(diffVars, eqns, resVars, oeqns, ovars, inShared, inVars, name);

      then (BackendDAE.EQUATIONSYSTEM(residualequations, iterationvarsInts, jacobian, BackendDAE.JAC_GENERIC(), mixedSystem), shared);

      case (comp, _, _, _) then (comp, inShared);
  end matchcontinue;
end calculateJacobianComponent;

protected function getSymbolicJacobian "author: wbraun
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
  output BackendDAE.Jacobian outJacobian;
  output BackendDAE.Shared outShared;
algorithm
  (outJacobian, outShared) := matchcontinue(inDiffVars, inResEquations, inResVars, inotherEquations, inotherVars, inShared, inAllVars, inName)
    local
      FCore.Cache cache;
      FCore.Graph graph;
      BackendDAE.BackendDAE backendDAE, jacBackendDAE;

      BackendDAE.Variables emptyVars, dependentVars, independentVars, knvars, allvars;
      BackendDAE.EquationArray emptyEqns, eqns;
      list<BackendDAE.Var> knvarLst, independentVarsLst, dependentVarsLst,  otherVarsLst;
      list<BackendDAE.Equation> residual_eqnlst;
      list<DAE.ComponentRef> independentComRefs, dependentVarsComRefs,  otherVarsLstComRefs;

      DAE.ComponentRef x;
      BackendDAE.SymbolicJacobian symJacBDAE;
      BackendDAE.SparsePattern sparsePattern;
      BackendDAE.SparseColoring sparseColoring;

      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StrongComponents comps;
      BackendDAE.ExtraInfo einfo;

      DAE.FunctionTree funcs;

    case(_, _, _, _, _, _, _, _)
      equation
        knvars = BackendDAEUtil.getknvars(inShared);
        funcs = BackendDAEUtil.getFunctions(inShared);
        einfo = BackendDAEUtil.getExtraInfo(inShared);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("---+++ create analytical jacobian +++---");
          print("\n---+++ independent variables +++---\n");
          BackendDump.printVariables(inDiffVars);
          print("\n---+++ equation system +++---\n");
          BackendDump.printEquationArray(inResEquations);
        end if;

        independentVarsLst = BackendVariable.varList(inDiffVars);
        independentComRefs = List.map(independentVarsLst, BackendVariable.varCref);

        otherVarsLst = BackendVariable.varList(inotherVars);
        otherVarsLstComRefs = List.map(otherVarsLst, BackendVariable.varCref);

        // all vars since the inVars are inputs for the jacobian
        allvars = BackendVariable.copyVariables(inAllVars);
        allvars = BackendVariable.removeCrefs(independentComRefs, allvars);
        allvars = BackendVariable.removeCrefs(otherVarsLstComRefs, allvars);
        knvars = BackendVariable.mergeVariables(knvars, allvars);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("\n---+++ known variables +++---\n");
          BackendDump.printVariables(knvars);
        end if;

        // dependentVarsLst = listReverse(dependentVarsLst);
        dependentVars = BackendVariable.mergeVariables(inResVars, inotherVars);
        eqns = BackendEquation.mergeEquationArray(inResEquations, inotherEquations);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("\n---+++ created backend system +++---\n");
          print("\n---+++ vars +++---\n");
          BackendDump.printVariables(dependentVars);
          print("\n---+++ equations +++---\n");
          BackendDump.printEquationArray(eqns);
        end if;

        // create known variables
        knvarLst = BackendEquation.equationsVars(eqns, knvars);
        knvars = BackendVariable.listVar1(knvarLst);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("\n---+++ known variables +++---\n");
          BackendDump.printVariables(knvars);
        end if;

        // prepare vars and equations for BackendDAE
        emptyVars =  BackendVariable.emptyVars();
        emptyEqns = BackendEquation.listEquation({});
        cache = FCore.emptyCache();
        graph = FGraph.empty();
        shared = BackendDAEUtil.createEmptyShared(BackendDAE.ALGEQSYSTEM(), einfo, cache, graph);
        shared = BackendDAEUtil.setSharedKnVars(shared, knvars);
        shared = BackendDAEUtil.setSharedFunctionTree(shared, funcs);
        backendDAE = BackendDAE.DAE({BackendDAEUtil.createEqSystem(dependentVars, eqns)}, shared);

        backendDAE = BackendDAEUtil.transformBackendDAE(backendDAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
        BackendDAE.DAE({BackendDAE.EQSYSTEM(orderedVars = dependentVars)}, BackendDAE.SHARED(knownVars = knvars)) = backendDAE;

        // prepare creation of symbolic jacobian
        // create dependent variables
        dependentVarsLst = BackendVariable.varList(dependentVars);

        (symJacBDAE, sparsePattern, sparseColoring, funcs) = createJacobian(backendDAE,
          independentVarsLst,
          emptyVars,
          emptyVars,
          knvars,
          inResVars,
          dependentVarsLst,
          inName);
        shared = BackendDAEUtil.setSharedFunctionTree(inShared, funcs);

      then (BackendDAE.GENERIC_JACOBIAN(symJacBDAE, sparsePattern, sparseColoring), shared);

    case(_, _, _, _, _, _, _, _)
      equation
        true = Flags.isSet(Flags.JAC_DUMP);
        Error.addInternalError("function getSymbolicJacobian failed", sourceInfo());
      then (BackendDAE.EMPTY_JACOBIAN(), inShared);

        else (BackendDAE.EMPTY_JACOBIAN(), inShared);
  end matchcontinue;
end getSymbolicJacobian;

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
        (stateSets, shared) = calculateStateSetsJacobian(stateSets, vars, eqns, comps, shared, {});
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
  input BackendDAE.StateSets inAccum;
  output BackendDAE.StateSets outStateSets;
  output  BackendDAE.Shared outShared;
algorithm
  (outStateSets, outShared) := match (inStateSets, inVars, inEqns, inComps, inShared, inAccum)
    local
      BackendDAE.StateSets rest, result;
      BackendDAE.StateSet stateSet;
      BackendDAE.Shared shared;

    case ({}, _, _, _, _, _) then (listReverse(inAccum), inShared);
    case (stateSet::rest, _, _, _, _, _)
      equation
        (stateSet, shared) = calculateStateSetJacobian(stateSet, inVars, inEqns, inComps, inShared);
        (result, shared) = calculateStateSetsJacobian(rest, inVars, inEqns, inComps, shared, stateSet::inAccum);
      then (result, shared);
  end match;
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

      Integer rang;
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

    case (BackendDAE.STATESET(rang=rang, state=state, crA=crA, varA=varA, statescandidates=statescandidates,
      ovars=ovars, eqns=eqns, oeqns=oeqns, crJ=crJ, varJ=varJ), _, _, _, _)
      equation
        // get state names
        crstates = List.map(statescandidates, BackendVariable.varCref);
        marked = arrayCreate(BackendVariable.varsSize(inVars), false);
        // get Equations for Jac from the strong component
        marked = List.fold1(crstates, markSetStates, inVars, marked);
        (compeqns, compvars) = getStateSetCompVarEqns(inComps, marked, inEqns, inVars, {}, {});
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
        ceqns = createResidualSetEquations(ceqns, crJ, 1, intGt(listLength(ceqns), 1), {});

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
        (jacobian, shared) = getSymbolicJacobian(diffVars, cEqns, resVars, oEqns, oVars, inShared, allvars, name);

      then (BackendDAE.STATESET(rang, state, crA, varA, statescandidates, ovars, eqns, oeqns, crJ, varJ, jacobian), shared);
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
  (_, {index}) := BackendVariable.getVar(inCr, iVars);
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
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Var> outVars;
algorithm
  (outEquations, outVars):= matchcontinue (inComp)
    local
      list<Integer> elst, vlst;
      list<BackendDAE.Equation> eqnlst;
      list<BackendDAE.Var> varlst;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents rest;

    case {} then (inEquations, inVars);

    case comp::rest equation
      (elst, vlst) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
      true = foundMarked(vlst, marked);
      eqnlst = BackendEquation.getEqns(elst, inEquationArray);
      varlst = List.map1r(vlst, BackendVariable.getVarAt, inVariables);
      eqnlst = listAppend(eqnlst, inEquations);
      varlst = listAppend(varlst, inVars);
      (eqnlst, varlst) = getStateSetCompVarEqns(rest, marked, inEquationArray, inVariables, eqnlst, varlst);
    then (eqnlst, varlst);

    case (_::rest) equation
      (eqnlst, varlst) = getStateSetCompVarEqns(rest, marked, inEquationArray, inVariables, inEquations, inVars);
    then (eqnlst, varlst);
  end matchcontinue;
end getStateSetCompVarEqns;

protected function createResidualSetEquations
  input list<BackendDAE.Equation> iEqs;
  input DAE.ComponentRef crJ;
  input Integer index;
  input Boolean applySubs;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oEqs;
algorithm
  oEqs := match (iEqs, crJ, index, applySubs, iAcc)
    local
      DAE.ComponentRef crj;
      DAE.Exp res, e1, e2, expJ;
      list<BackendDAE.Equation> rest;
      BackendDAE.Equation eqn;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;

    case ({}, _, _, _, _) then listReverse(iAcc);
    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr)::rest, _, _, _, _)
      equation
        crj = if applySubs then ComponentReference.subscriptCrefWithInt(crJ, index) else crJ;
        expJ = Expression.crefExp(crj);
        res = Expression.expSub(e1, e2);
        eqn = BackendDAE.EQUATION(expJ, res, source, eqAttr);
      then
        createResidualSetEquations(rest, crJ, index+1, applySubs, eqn::iAcc);
    case (BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source, attr=eqAttr)::rest, _, _, _, _)
      equation
        expJ = Expression.crefExp(ComponentReference.subscriptCrefWithInt(crJ, index));
        eqn = BackendDAE.EQUATION(expJ, e1, source, eqAttr);
    then
        createResidualSetEquations(rest, crJ, index+1, applySubs, eqn::iAcc);
    case (eqn::_, _, _, _, _)
      equation
        Error.addInternalError("function createResidualSetEquations failed for equation: " + BackendDump.equationString(eqn), sourceInfo());
    then
       fail();
  end match;
end createResidualSetEquations;

public function calculateJacobian "This function takes an array of equations and the variables of the equation
  and calculates the Jacobian of the equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input BackendDAE.Shared iShared;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output BackendDAE.Shared oShared;
algorithm
  (outTplIntegerIntegerEquationLstOption, oShared):=
  matchcontinue (inVariables,inEquationArray,inIncidenceMatrix,differentiateIfExp,iShared)
    local
      list<BackendDAE.Equation> eqn_lst;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.Shared shared;
    case (vars,eqns,m,_,_)
      equation
        eqn_lst = BackendEquation.equationList(eqns);
        (jac, shared) = calculateJacobianRows(eqn_lst,vars,m,1,1,differentiateIfExp,iShared,BackendDAEUtil.varsInEqn,{});
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
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables vars;
  input Type_a m;
  input Integer eqn_indx;
  input Integer scalar_eqn_indx;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input BackendDAE.Shared iShared;
  input varsInEqnFunc varsInEqn;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> iAcc;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst;
  output BackendDAE.Shared oShared;
  partial function varsInEqnFunc
    input Type_a m;
    input Integer indx;
    output list<Integer> outIntegerLst;
  end varsInEqnFunc;
algorithm
  (outLst, oShared) := match (inEquationLst,vars,m,eqn_indx,scalar_eqn_indx,differentiateIfExp,iShared,varsInEqn,iAcc)
    local
      list<tuple<Integer, Integer, BackendDAE.Equation>> res;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      Integer size;
      BackendDAE.Shared shared;
    case ({},_,_,_,_,_,_,_,_) then (listReverse(iAcc), iShared);
    case (eqn::eqns,_,_,_,_,_,_,_,_)
      equation
        (res, size, shared) = calculateJacobianRow(eqn, vars,  m, eqn_indx, scalar_eqn_indx,differentiateIfExp,iShared,varsInEqn,iAcc);
        (res, shared) = calculateJacobianRows(eqns, vars, m, eqn_indx + 1, scalar_eqn_indx + size,differentiateIfExp,shared,varsInEqn,res);
      then
        (res, shared);
  end match;
end calculateJacobianRows;

protected function calculateJacobianRow "author: PA
  Calculates the Jacobian for one equation. See calculateJacobianRows.
  inputs:  (Equation,
              BackendDAE.Variables,
              IncidenceMatrix,
              IncidenceMatrixT,
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
        var_indxs_1 = List.unionOnTrue(var_indxs, {}, intEq) "Remove duplicates and get in correct order: ascending index";
        var_indxs_1 = List.sort(var_indxs_1,intGt);
        (eqns, shared) = calculateJacobianRow2(Expression.expSub(e1,e2), vars, scalar_eqn_indx, var_indxs_1,differentiateIfExp,iShared,source,iAcc);
      then
        (eqns, 1, shared);

    // residual equations
    case (BackendDAE.RESIDUAL_EQUATION(exp=e,source=source),_,_,_,_,_,_,_,_)
      equation
        var_indxs = fvarsInEqn(m, eqn_indx);
        var_indxs_1 = List.unionOnTrue(var_indxs, {}, intEq) "Remove duplicates and get in correct order: ascending index";
        var_indxs_1 = List.sort(var_indxs_1,intGt);
        (eqns, shared) = calculateJacobianRow2(e, vars, scalar_eqn_indx, var_indxs_1,differentiateIfExp,iShared,source,iAcc);
      then
        (eqns, 1, shared);

    // solved equations
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e2,source=source),_,_,_,_,_,_,_,_)
      equation
        e1 = Expression.crefExp(cr);
        var_indxs = fvarsInEqn(m, eqn_indx);
        var_indxs_1 = List.unionOnTrue(var_indxs, {}, intEq) "Remove duplicates and get in correct order: ascending index";
        var_indxs_1 = List.sort(var_indxs_1,intGt);
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
        var_indxs_1 = List.unionOnTrue(var_indxs, {}, intEq) "Remove duplicates and get in correct order: ascending index";
        var_indxs_1 = List.sort(var_indxs_1,intGt);
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
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst;
  output BackendDAE.Shared oShared;
algorithm
  (outLst, oShared) := match inExps
    local
      DAE.Exp e;
      list<DAE.Exp> elst;
      list<tuple<Integer, Integer, BackendDAE.Equation>> eqns;
      BackendDAE.Shared shared;

    case {} then (iAcc, iShared);

    case e::elst equation
      (eqns, shared) = calculateJacobianRow2(e,vars,eqn_indx,inIntegerLst,differentiateIfExp,iShared,source,iAcc);
      (eqns, shared) = calculateJacobianRowLst(elst,vars,eqn_indx+1,inIntegerLst,differentiateIfExp,shared,source,eqns);
    then (eqns, shared);
  end match;
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
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst;
  output BackendDAE.Shared oShared;
algorithm
  (outLst, oShared) := matchcontinue (inIntegerLst)
    local
      DAE.Exp e, e_1, e_2, dcrexp;
      BackendDAE.Var v;
      DAE.ComponentRef cr, dcr;
      list<tuple<Integer, Integer, BackendDAE.Equation>> es;
      Integer vindx;
      list<Integer> vindxs;
      String str;
      BackendDAE.Shared shared;

    case {}
    then (iAcc, iShared);

    case vindx::vindxs equation
      v = BackendVariable.getVarAt(vars, vindx);
      cr = BackendVariable.varCref(v);
      true = BackendVariable.isStateVar(v);
      dcr = ComponentReference.crefPrefixDer(cr);
      dcrexp = Expression.crefExp(cr);
      dcrexp = DAE.CALL(Absyn.IDENT("der"), {dcrexp}, DAE.callAttrBuiltinReal);
      ((e, _)) = Expression.replaceExp(inExp, dcrexp, Expression.crefExp(dcr));
      (e_1, shared) = Differentiate.differentiateExpCrefFullJacobian(e, dcr, vars, iShared);
      (e_2, _) = ExpressionSimplify.simplify(e_1);
      es = calculateJacobianRow3(eqn_indx, vindx, e_2, source, iAcc);
      (es, shared) = calculateJacobianRow2(inExp, vars, eqn_indx, vindxs, differentiateIfExp, shared, source, es);
    then (es, shared);

    case vindx::vindxs equation
      v = BackendVariable.getVarAt(vars, vindx);
      cr = BackendVariable.varCref(v);
      (e_1, shared) = Differentiate.differentiateExpCrefFullJacobian(inExp, cr, vars, iShared);
      (e_2, _) = ExpressionSimplify.simplify(e_1);
      es = calculateJacobianRow3(eqn_indx, vindx, e_2, source, iAcc);
      (es, shared) = calculateJacobianRow2(inExp, vars, eqn_indx, vindxs, differentiateIfExp, shared, source, es);
    then (es, shared);

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      str = ExpressionDump.printExpStr(inExp);
      Debug.traceln("- BackendDAE.calculateJacobianRow2 failed on " + str);
    then fail();
  end matchcontinue;
end calculateJacobianRow2;

protected function calculateJacobianRow3
  input Integer eqn_indx;
  input Integer vindx;
  input DAE.Exp inExp;
  input DAE.ElementSource source;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> iAcc;
  output list<tuple<Integer, Integer, BackendDAE.Equation>> outLst;
algorithm
  outLst := matchcontinue(eqn_indx,vindx,inExp,source,iAcc)
    case (_,_,_,_,_)
      equation
        true = Expression.isZero(inExp);
      then
        iAcc;
    else
      (eqn_indx,vindx,BackendDAE.RESIDUAL_EQUATION(inExp,source,BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN))::iAcc;
  end matchcontinue;
end calculateJacobianRow3;

protected function addBackendDAESharedJacobian
  input BackendDAE.SymbolicJacobian inSymJac;
  input BackendDAE.SparsePattern inSparsePattern;
  input BackendDAE.SparseColoring inSparseColoring;
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Variables knvars,exobj,av;
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
  symjacs := { (SOME(inSymJac), inSparsePattern, inSparseColoring), (NONE(), ({}, {}, ({}, {}), -1), {}),
               (NONE(), ({}, {}, ({}, {}), -1), {}), (NONE(), ({}, {}, ({}, {}), -1), {}) };
  outShared := BackendDAEUtil.setSharedSymJacs(inShared, symjacs);
end addBackendDAESharedJacobian;


protected function addBackendDAESharedJacobianSparsePattern
  input BackendDAE.SparsePattern inSparsePattern;
  input BackendDAE.SparseColoring inSparseColoring;
  input Integer inIndex;
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Variables knvars,exobj,av;
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
algorithm
  BackendDAE.SHARED(symjacs=symjacs) := inShared;
  ((symJac, _, _)) := listGet(symjacs, inIndex);
  symjacs := List.set(symjacs, inIndex, ((symJac, inSparsePattern, inSparseColoring)));
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
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (vars,inTplIntegerIntegerEquationLst)
    local
      DAE.Exp e1,e2,e;
      list<tuple<Integer, Integer, BackendDAE.Equation>> xs;

    case (_,((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2))::xs))
      equation
        false = jacobianNonlinearExp(vars, e1);
        false = jacobianNonlinearExp(vars, e2);
      then
        jacobianNonlinear(vars, xs);
    case (_,((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e))::xs))
      equation
        false = jacobianNonlinearExp(vars, e);
      then
        jacobianNonlinear(vars, xs);
    case (_,{}) then false;
    else true;
  end matchcontinue;
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

    case (e as DAE.CALL(path=Absyn.IDENT(name = "pre")),(vars,b))
      then (e,false,(vars,b));

    case (e as DAE.CALL(path=Absyn.IDENT(name = "previous")),(vars,b))
      then (e,false,(vars,b));

    case (e,(_,b)) then (e,not b,tpl);
  end matchcontinue;
end traverserjacobianNonlinearExp;

protected function jacobianConstant "author: PA
  Checks if Jacobian is constant, i.e. all expressions in each equation are constant."
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTplIntegerIntegerEquationLst)
    local
      DAE.Exp e1,e2,e;
      list<tuple<Integer, Integer, BackendDAE.Equation>> eqns;
    case ({}) then true;
    case (((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2))::eqns)) /* TODO: Algorithms and ArrayEquations */
      equation
        true = Expression.isConst(e1);
        true = Expression.isConst(e2);
      then
        jacobianConstant(eqns);
    case (((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e))::eqns))
      equation
        true = Expression.isConst(e);
      then
        jacobianConstant(eqns);
    case (((_,_,BackendDAE.SOLVED_EQUATION(exp = e))::eqns))
      equation
        true = Expression.isConst(e);
      then
        jacobianConstant(eqns);
    else false;
  end matchcontinue;
end jacobianConstant;

protected function varsNotInRelations
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<BackendDAE.Variables,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := match (inExp,inTpl)
    local
      DAE.Exp cond,t,f,e,e1;
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

    case (e as DAE.CALL(path=Absyn.IDENT(name = "der")),(vars,b))
      then (e,true,(vars,b));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "pre")),(vars,b))
      then (e,false,(vars,b));
    case (e as DAE.CALL(path = Absyn.IDENT(name = "previous")),(vars,b))
      then (e,false,(vars,b));
    case (e as DAE.CALL(expLst=expLst),(vars,b))
      equation
        // check if vars occurs not in argument list
        (_,(_,b)) = Expression.traverseExpListTopDown(expLst, BackendDAEUtil.getEqnsysRhsExp2, (vars,b));
      then (e,false,(vars,b));
    case (e as DAE.LBINARY(),(vars,b))
      equation
        // check if vars not in condition
        (_,(_,b)) = Expression.traverseExpTopDown(e, BackendDAEUtil.getEqnsysRhsExp2, (vars,b));
      then (e,false,(vars,b));
    case (e as DAE.LUNARY(),(vars,b))
      equation
        // check if vars not in condition
        (_,(_,b)) = Expression.traverseExpTopDown(e, BackendDAEUtil.getEqnsysRhsExp2, (vars,b));
      then (e,false,(vars,b));
    case (e as DAE.RELATION(),(vars,b))
      equation
        // check if vars not in condition
        (_,(_,b)) = Expression.traverseExpTopDown(e, BackendDAEUtil.getEqnsysRhsExp2, (vars,b));
      then (e,false,(vars,b));
    case (e as DAE.ASUB(exp=e1,sub=expLst),(vars,b))
      equation
        // check if vars not in condition
        (_,(_,b)) = Expression.traverseExpTopDown(e1, varsNotInRelations, (vars,b));
        if b then
          (_,(_,b)) = Expression.traverseExpListTopDown(expLst, BackendDAEUtil.getEqnsysRhsExp2, (vars,b));
        end if;
      then (e,false,(vars,b));
    case (e,(_,b)) then (e,b,inTpl);
  end match;
end varsNotInRelations;

protected function rhsConstant "author: PA
  Determines if the right hand sides of an equation system,
  represented as a BackendDAE, is constant."
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (vars,eqns)
    local
      Boolean res;
      BackendVarTransform.VariableReplacements repl;
    case (_,_)
      equation
        0 = BackendDAEUtil.equationSize(eqns);
      then
        true;
    case (_,_)
      equation
        repl = BackendDAEUtil.makeZeroReplacements(vars);
        ((_,res,_)) = BackendEquation.traverseEquationArray_WithStop(eqns,rhsConstant2,(vars,true,repl));
      then
        res;
  end matchcontinue;
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

annotation(__OpenModelica_Interface="backend");
end SymbolicJacobian;
