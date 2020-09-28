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

encapsulated package Differentiate
" file:        Differentiate.mo
  package:     Differentiate
  description: Differentiation of equations from BackendDAE.BackendDAE


  This module is responsible for symbolic differentiation of equations and
  expressions.

  The symbolic differentiation is used in the Newton-Raphson method and in
  index reduction."

// public imports
public import Absyn;
public import BackendDAE;
public import DAE;
public import DAEUtil;
public import Types;

// protected imports
protected import AbsynUtil;
protected import Algorithm;
protected import Array;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendUtil;
protected import BackendVariable;
protected import ClassInf;
protected import ComponentReference;
protected import DAEDump;
protected import DAEDumpTpl;
protected import Debug;
protected import ElementSource;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionDump;
protected import Flags;
protected import Inline;
protected import List;
protected import SCode;
protected import Util;

constant Integer defaultMaxIter = 20;

// =============================================================================
// differentiation interfaces:
//  - createDifferentiatedCrefName
//  - createSeedCrefName
//  - differentiateEquation
//  - differentiateEquationTime
//  - differentiateExpCrefFullJacobian
//  - differentiateExpSolve
//  - differentiateExpTime
// =============================================================================

public function differentiateEquationTime
  "Differentiates an equation with respect to time.
  Returns NONE() if it was not possible to calculate a derivative."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Shared inShared;
  output Option<BackendDAE.Equation> outEquation;
  output BackendDAE.Shared outShared = inShared;
protected
  BackendDAE.DifferentiateInputData diffData;
  BackendDAE.Equation eqn;
  BackendDAE.Variables knvars;
  DAE.ElementSource source;
  DAE.FunctionTree funcs;
algorithm
  try
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      BackendDump.debugStrEqnStr("### differentiateEquationTime\n", inEquation, " w.r.t. time\n");
    end if;
    funcs := BackendDAEUtil.getFunctions(inShared);
    knvars := BackendDAEUtil.getGlobalKnownVarsFromShared(inShared);
    diffData := BackendDAE.emptyInputData;
    diffData.dependenentVars := SOME(inVariables);
    diffData.knownVars := SOME(knvars);
    diffData.allVars := SOME(inVariables);
    (eqn, funcs) := differentiateEquation(inEquation, DAE.crefTime, diffData, BackendDAE.DIFFERENTIATION_TIME(), funcs);
    outEquation := SOME(eqn);
    outShared := BackendDAEUtil.setSharedFunctionTree(inShared, funcs);
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      BackendDump.debugStrEqnStr("### Result of differentiateEquationTime\n --> ", eqn, "\n");
    end if;
  else
    source := BackendEquation.equationSource(inEquation);
    Error.addSourceMessage(Error.INTERNAL_ERROR, {"\nDifferentiate.differentiateEquationTime failed for " + BackendDump.equationString(inEquation) + "\n\n"}, ElementSource.getElementSourceFileInfo(source));
    outEquation := NONE();
  end try;
end differentiateEquationTime;

public function differentiateExpTime
  "Differentiates an expression with respect to time."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Shared inShared;
  output DAE.Exp outExp;
  output BackendDAE.Shared outShared;
protected
  DAE.Exp dexp;
  DAE.FunctionTree funcs;
  BackendDAE.DifferentiateInputData diffData;
  BackendDAE.Variables knvars;
algorithm
  try
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      BackendDump.debugStrExpStr("### differentiateExpTime\n ", inExp, " w.r.t. time\n");
    end if;
    funcs := BackendDAEUtil.getFunctions(inShared);
    knvars := BackendDAEUtil.getGlobalKnownVarsFromShared(inShared);
    diffData := BackendDAE.emptyInputData;
    diffData.dependenentVars := SOME(inVariables);
    diffData.knownVars := SOME(knvars);
    (dexp, funcs) := differentiateExp(inExp, DAE.crefTime, diffData, BackendDAE.DIFFERENTIATION_TIME(), funcs, defaultMaxIter);
    (outExp, _) := ExpressionSimplify.simplify(dexp);
    outShared := BackendDAEUtil.setSharedFunctionTree(inShared, funcs);
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      BackendDump.debugStrExpStr("### Result of differentiateExpTime\n --> ", outExp, "n");
    end if;
  else
    // expandDerOperator expects sometime that differentiate fails,
    // so the calling function need to take care of the error messages.
    // TODO: change that in expandDerOperator
    //Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, ElementSource.getElementSourceFileInfo(DAE.emptyElementSource));

    if Flags.isSet(Flags.FAILTRACE) then
      Error.addSourceMessage(Error.NON_EXISTING_DERIVATIVE, {ExpressionDump.printExpStr(inExp), "time"}, sourceInfo());
    end if;
    fail();
  end try;
end differentiateExpTime;

public function differentiateExpSolve
  "Differentiates an expression with respect to inCref."
  input DAE.Exp inExp;
  input DAE.ComponentRef inCref;
  input Option<DAE.FunctionTree> functions;
  output DAE.Exp outExp;
protected
  list<DAE.Exp> fac = Expression.factors(inExp);
  DAE.Exp dexp;
  DAE.FunctionTree fun;
algorithm
  ({}, _) := List.split1OnTrue(fac, Expression.expHasCrefInIf, inCref); // check if differentiateExpSolve is allowed

  try
    fun := match(functions)
      local
        DAE.FunctionTree fun_;
      case SOME(fun_) then fun_;
      else DAE.AvlTreePathFunction.Tree.EMPTY();
    end match;

    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      BackendDump.debugStrExpStrCrefStr("### differentiateExpSolve\n ", inExp, " w.r.t. ", inCref, "\n");
    end if;
    (dexp, _) := differentiateExp(inExp, inCref, BackendDAE.emptyInputData, BackendDAE.SIMPLE_DIFFERENTIATION(), fun, defaultMaxIter);
    (outExp, _) := ExpressionSimplify.simplify(dexp);
    if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
      BackendDump.debugStrExpStr("### Result of differentiateExpSolve\n --> ", outExp, "\n");
    end if;
  else
    if Flags.isSet(Flags.FAILTRACE) then
      Error.addSourceMessage(Error.NON_EXISTING_DERIVATIVE, {ExpressionDump.printExpStr(inExp), ComponentReference.crefStr(inCref)}, sourceInfo());
    end if;
    fail();
  end try;
end differentiateExpSolve;


public function differentiateExpCrefFullJacobian
  "Differentiates an expression inExp with respect to inCref."
  input DAE.Exp inExp;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Shared inShared;
  output DAE.Exp outExp;
  output BackendDAE.Shared outShared;
protected
  DAE.Exp dexp;
  DAE.FunctionTree funcs;
  BackendDAE.DifferentiateInputData diffData;
  BackendDAE.Variables knvars;
algorithm
  try
    funcs := BackendDAEUtil.getFunctions(inShared);
    knvars := BackendDAEUtil.getGlobalKnownVarsFromShared(inShared);
    diffData := BackendDAE.emptyInputData;
    diffData.dependenentVars := SOME(inVariables);
    diffData.knownVars := SOME(knvars);
    (dexp, funcs) := differentiateExp(inExp, inCref, diffData, BackendDAE.DIFF_FULL_JACOBIAN(), funcs, defaultMaxIter);
    (outExp,_) := ExpressionSimplify.simplify(dexp);
    outShared := BackendDAEUtil.setSharedFunctionTree(inShared, funcs);
  else
    // expandDerOperator expects sometimes that differentiate fails,
    // so the calling function need to take care of the error messages.
    // TODO: change that in expandDerOperator
    //Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, ElementSource.getElementSourceFileInfo(DAE.emptyElementSource));

    if Flags.isSet(Flags.FAILTRACE) then
      Error.addSourceMessage(Error.NON_EXISTING_DERIVATIVE, {ExpressionDump.printExpStr(inExp), ComponentReference.crefStr(inCref)}, sourceInfo());
    end if;
    fail();
  end try;
end differentiateExpCrefFullJacobian;


// =============================================================================
// further interface functions to differentiation
//  - differentiateEquation
//  - differentiateBackendDAE
//
// =============================================================================


public function differentiateEquation
  "Differentiates an equation with respect to a cref."
  input BackendDAE.Equation inEquation;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.Equation outEquation;
  output DAE.FunctionTree outFunctionTree;
algorithm
  try
    (outEquation, outFunctionTree) := differentiateEquationFragile(inEquation, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
  else
    Error.addSourceMessage(Error.NON_EXISTING_DERIVATIVE, {BackendDump.equationString(inEquation), ComponentReference.crefStr(inDiffwrtCref)}, sourceInfo());
    fail();
  end try;
end differentiateEquation;

public function differentiateEquationFragile
  "author: kabdelhak 2019-09
  Differentiates an equation with respect to a cref, fails if it can't be differentiated."
  input BackendDAE.Equation inEquation;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.Equation outEquation;
  output DAE.FunctionTree outFunctionTree;
algorithm
  // Debug dump
  if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
    BackendDump.debugStrEqnStr("### differentiateEquation\n ", inEquation, " w.r.t. " + ComponentReference.crefStr(inDiffwrtCref) + "\n");
  end if;
  (outEquation, outFunctionTree) := match inEquation
    local
      DAE.Exp e1_1, e2_1, e1_2, e2_2, e1, e2;
      DAE.ComponentRef cref;
      DAE.ElementSource source;
      Integer size;
      Option<Integer> recordSize;
      list<DAE.Exp> out1, expExpLst, expExpLst1;
      DAE.Type exptyp;
      list<Integer> dimSize;
      String se1, dse1, se2, dse2;
      DAE.SymbolicOperation op1, op2;
      DAE.FunctionTree funcs;
      DAE.Algorithm alg;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      list<DAE.Statement> statementLst;
      DAE.Expand expand;
      BackendDAE.WhenEquation whenEqn;
      BackendDAE.EquationAttributes eqAttr;

    // equations
    case BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr)
      equation
        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, defaultMaxIter);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, defaultMaxIter);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, ElementSource.addSymbolicTransformation, source);

      then
        (BackendDAE.EQUATION(e1_1, e2_1, source, eqAttr), funcs);

    // solved equations
    case BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e2, source=source, attr=eqAttr)
      equation
        e1 = Expression.crefExp(cref);

        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, defaultMaxIter);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, defaultMaxIter);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, ElementSource.addSymbolicTransformation, source);

      then
        (BackendDAE.EQUATION(e1_1, e2_1, source, eqAttr), funcs);

    // RESIDUAL_EQUATION
    case BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source, attr=eqAttr)
      equation

        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, defaultMaxIter);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        source = List.foldr({op1}, ElementSource.addSymbolicTransformation, source);

      then
        (BackendDAE.RESIDUAL_EQUATION(e1_1, source, eqAttr), funcs);

    // complex equations
    case BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, attr=eqAttr)
      equation
        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, defaultMaxIter);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, defaultMaxIter);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, ElementSource.addSymbolicTransformation, source);

      then
        (BackendDAE.COMPLEX_EQUATION(size, e1_1, e2_1, source, eqAttr), funcs);

    // Array Equations
    case BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left=e1, right=e2, source=source, attr=eqAttr, recordSize=recordSize)
      equation
        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, defaultMaxIter);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, defaultMaxIter);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, ElementSource.addSymbolicTransformation, source);

      then
        (BackendDAE.ARRAY_EQUATION(dimSize, e1_1, e2_1, source, eqAttr, recordSize), funcs);

    // differentiate algorithm
    case BackendDAE.ALGORITHM(size=size, alg=DAE.ALGORITHM_STMTS(statementLst=statementLst), source=source, expand=expand, attr=eqAttr)
      equation
        // get Allgorithm
        (statementLst, funcs) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree, defaultMaxIter);
        alg = DAE.ALGORITHM_STMTS(statementLst);

        //op1 = DAE.OP_DIFFERENTIATE(cr, before, after)
        //op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e2);
        //source = ElementSource.addSymbolicTransformation(source, op1);

       then
        (BackendDAE.ALGORITHM(size, alg, source, expand, eqAttr), funcs);

    // if-equations
    case BackendDAE.IF_EQUATION(conditions=expExpLst, eqnstrue=eqnslst, eqnsfalse=eqns, source=source, attr=eqAttr)
      equation
        (eqnslst, funcs) = differentiateEquationsLst(eqnslst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
        (eqns, funcs) = differentiateEquations(eqns, inDiffwrtCref, inInputData, inDiffType, {}, funcs);

      then
        (BackendDAE.IF_EQUATION(expExpLst, eqnslst, eqns, source, eqAttr), funcs);

    case BackendDAE.WHEN_EQUATION(size=size, whenEquation=whenEqn, source=source, attr=eqAttr)
      equation
        (whenEqn, funcs) = differentiateWhenEquations(whenEqn, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

      then
        (BackendDAE.WHEN_EQUATION(size, whenEqn, source, eqAttr), funcs);
    else equation
      Error.addSourceMessage(Error.NON_EXISTING_DERIVATIVE, {BackendDump.equationString(inEquation), ComponentReference.crefStr(inDiffwrtCref)}, sourceInfo());
     then fail();
  end match;
  // Debug dump
  if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
    BackendDump.debugStrEqnStr("### Result of differentiateEquation\n --> ", outEquation,"\n");
  end if;
end differentiateEquationFragile;


protected function differentiateEquations
  "Differentiates an equation with respect to a cref."
  input list<BackendDAE.Equation> inEquations;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input list<BackendDAE.Equation> inEquationsAccum;
  input DAE.FunctionTree inFunctionTree;
  output list<BackendDAE.Equation> outEquations;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outEquations,outFunctionTree) := matchcontinue (inEquations)
    local
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> rest, eqns;
      BackendDAE.Equation eqn;

    case {} then (listReverse(inEquationsAccum), inFunctionTree);

    // equations
    case eqn::rest
      equation
        (eqn, funcs) = differentiateEquation(eqn,  inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        eqns = eqn::inEquationsAccum;
        (eqns, funcs) = differentiateEquations(rest, inDiffwrtCref, inInputData, inDiffType, eqns, funcs);
      then (eqns, funcs);

    case eqn::_
      equation
        Error.addSourceMessage(Error.NON_EXISTING_DERIVATIVE, {BackendDump.equationString(eqn), ComponentReference.crefStr(inDiffwrtCref)}, sourceInfo());
      then
        fail();
  end matchcontinue;
end differentiateEquations;

protected function differentiateEquationsLst
  "Differentiates a list of an equation list with respect to a cref.
  Helper function to differentiate a IF-EQUATION."
  input list<list<BackendDAE.Equation>> inEquationsLst;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input list<list<BackendDAE.Equation>> inEquationsLstAccum;
  input DAE.FunctionTree inFunctionTree;
  output list<list<BackendDAE.Equation>> outEquationsLst;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outEquationsLst, outFunctionTree) := matchcontinue inEquationsLst
    local
      DAE.FunctionTree funcs;
      list<list<BackendDAE.Equation>> rest, eqnsLst;
      list<BackendDAE.Equation> eqns;
      String msg;
      DAE.ElementSource source;

    case {} then (listReverse(inEquationsLstAccum), inFunctionTree);

    // equations
    case eqns::rest
      equation
        (eqns, funcs) = differentiateEquations(eqns,  inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
        eqnsLst = eqns::inEquationsLstAccum;
        (eqnsLst, funcs) = differentiateEquationsLst(rest, inDiffwrtCref, inInputData, inDiffType, eqnsLst, funcs);
      then (eqnsLst, funcs);

    case eqns::_
      equation
        Error.addSourceMessage(Error.NON_EXISTING_DERIVATIVE, {BackendDump.equationListString(eqns, "equation list"), ComponentReference.crefStr(inDiffwrtCref)}, sourceInfo());
      then
        fail();
  end matchcontinue;
end differentiateEquationsLst;

protected function differentiateWhenEquations
  "Differentiates a when equation with respect to a cref."
  input BackendDAE.WhenEquation inWhenEquations;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.WhenEquation outWhenEquations;
  output DAE.FunctionTree outFunctionTree;
protected
  BackendDAE.WhenEquation elsewhenPart, delsewhenPart;
  Option<BackendDAE.WhenEquation> oelsepart;
  list<BackendDAE.WhenOperator> whenStmtLst, stmtLst;
  DAE.FunctionTree funcs;
  DAE.Exp condition;
algorithm
  BackendDAE.WHEN_STMTS(condition = condition, whenStmtLst = whenStmtLst, elsewhenPart = oelsepart) := inWhenEquations;
  funcs := inFunctionTree;
  stmtLst := {};
  for rs in whenStmtLst loop
    rs := match(rs)
      local
        DAE.ElementSource src;
        DAE.Exp right, dright, eleft, dleft;

      case BackendDAE.ASSIGN(eleft, right, src) equation
        (dleft, funcs) = differentiateExp(eleft, inDiffwrtCref, inInputData, inDiffType, funcs, defaultMaxIter);
        (dright, funcs) = differentiateExp(right, inDiffwrtCref, inInputData, inDiffType, funcs, defaultMaxIter);
      then BackendDAE.ASSIGN(dleft, dright, src);

      else rs;
    end match;

    stmtLst := rs::stmtLst;
  end for;
  if isSome(oelsepart) then
    SOME(elsewhenPart) := oelsepart;
    (delsewhenPart, funcs) := differentiateWhenEquations(elsewhenPart, inDiffwrtCref, inInputData, inDiffType, funcs);
    oelsepart := SOME(delsewhenPart);
  else
    oelsepart := NONE();
  end if;

  outWhenEquations := BackendDAE.WHEN_STMTS(condition, stmtLst, oelsepart);
  outFunctionTree := funcs;
end differentiateWhenEquations;

// =============================================================================
// main differentiation functions
//  - differentiateExp
//  - differentiateStatements
//
// =============================================================================

protected function differentiateExp
  input DAE.Exp inExp;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
protected
  constant Boolean debug = false;
algorithm
  if debug then print("\nDifferentiate Exp: "+ExpressionDump.printExpStr(inExp)+
                      " w.r.t. "+ComponentReference.printComponentRefStr(inDiffwrtCref)+"\n"); end if;

/*
  // This check does not seem to be necessary since looking through the stack of expression seems to stop iteration in most cases, and you get a spam of messages from this check.
  if maxIter < 1 then
    Error.addInternalError("Differentiation reached maximum number of iterations ("+String(defaultMaxIter)+"). Current expression is: " + ExpressionDump.printExpStr(inExp) + " w.r.t. " + ComponentReference.printComponentRefStr(inDiffwrtCref), sourceInfo());
    fail();
  end if;
*/
  (outDiffedExp, outFunctionTree) := match inExp
    local
      Absyn.Path p, p1, p2;
      Boolean b;
      DAE.CallAttributes attr;
      DAE.Exp e1, e2, e3, actual, simplified;
      DAE.Exp res, res1, res2;
      DAE.FunctionTree functionTree;
      DAE.Operator op;
      DAE.Type tp;
      Integer i;
      String s1, s2, stp;
      list<String> strLst;
      list<DAE.Var> varLst;
      //String se1;
      list<DAE.Exp> sub, expl;
      list<list<DAE.Exp>> matrix, dmatrix;
      DAE.ComponentRef cref;

    // constants => results in zero
    case DAE.BCONST(bool=b) then (DAE.BCONST(b), inFunctionTree);
    case DAE.ICONST() then (DAE.ICONST(0), inFunctionTree);
    case DAE.RCONST() then (DAE.RCONST(0.0), inFunctionTree);
    case DAE.SCONST() then (inExp, inFunctionTree);


    case DAE.RECORD(path = p, exps = expl, comp = strLst, ty=tp)
      algorithm
       sub := {};
       functionTree := inFunctionTree;
       for e in expl loop
         (e1, functionTree) := differentiateExp(e,inDiffwrtCref, inInputData, inDiffType, functionTree, maxIter);
          sub := e1 :: sub;
       end for;
    then  (DAE.RECORD(p, listReverse(sub), strLst, tp), functionTree);

    // differentiate cref
    case DAE.CREF(componentRef=cref, ty=tp) equation

      if ComponentReference.isStartCref(cref) then
        // differentiate start value
        res = Expression.makeConstZero(tp);
        functionTree = inFunctionTree;
      else
        (res, functionTree) = differentiateCrefs(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);
      end if;

    then (res, functionTree);

    // differentiate homotopy
    case DAE.CALL(path=p as Absyn.IDENT(name="homotopy"), expLst={actual, simplified}, attr=attr) algorithm
      (e1, functionTree) := differentiateExp(actual, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
    then (e1, functionTree);

    /*
      do not differentiate semiLinear, if the second or third expression contains the diff cref
      ticket: #5595
    */
    case DAE.CALL(path=p as Absyn.IDENT(name="semiLinear"), expLst={e1, e2, e3}, attr=attr)
      guard(Expression.expHasCref(e2, inDiffwrtCref) or  Expression.expHasCref(e3, inDiffwrtCref))
    then fail();

    // differentiate call
    case DAE.CALL() equation

      (res, functionTree) = differentiateCalls(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);
      (res,_) = ExpressionSimplify.simplify1(res);

    then (res, functionTree);

    // differentiate binary
    case DAE.BINARY() equation

      (res, functionTree) = differentiateBinary(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);
      (res) = ExpressionSimplify.simplifyBinaryExp(res);

    then (res, functionTree);

    // differentiate operator
    case DAE.UNARY(operator=op, exp=e1) equation

      (res, functionTree) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);

      res = DAE.UNARY(op,res);
      (res) = ExpressionSimplify.simplifyUnaryExp(res);

    then (res, functionTree);

    // differentiate cast
    case DAE.CAST(ty=tp, exp=e1) equation

      (res, functionTree) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);
      (res,_) = ExpressionSimplify.simplify1(res);

    then (DAE.CAST(tp, res), functionTree);

    // differentiate asub
    case DAE.ASUB(exp=e1, sub=sub) equation

      (res1, functionTree) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);

      res = Expression.makeASUB(res1,sub);
      (res,_) = ExpressionSimplify.simplify1(res);

    then (res, functionTree);

    case DAE.ARRAY(ty=tp, scalar=b, array=expl) equation

      (expl, functionTree) = List.map3Fold(expl, function differentiateExp(maxIter=maxIter-1), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

      res = DAE.ARRAY(tp, b, expl);
      (res,_) = ExpressionSimplify.simplify1(res);

    then (res, functionTree);

    case DAE.MATRIX(ty=tp, integer=i, matrix=matrix) equation

      (dmatrix, functionTree) = List.map3FoldList(matrix, function differentiateExp(maxIter=maxIter-1), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

      res = DAE.MATRIX(tp, i, dmatrix);
      (res,_) = ExpressionSimplify.simplify1(res);

    then (res, functionTree);

     // differentiate tsub
    case DAE.TSUB(exp=e1, ix=i, ty=tp)
      algorithm
        (res1, functionTree) := differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);

        if not referenceEq(e1, res1) then
          res := DAE.TSUB(res1, i, tp);
          (res,_) := ExpressionSimplify.simplify1(res);
        else
          res := inExp;
        end if;
      then (res, functionTree);


    // differentiate rsub
    case e1 as DAE.RSUB()
      algorithm
        // Try simplifying first.
        (res, b) := ExpressionSimplify.simplify(e1);
        if b then
          (res, functionTree) := differentiateExp(res, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);
        else
	        (res1, functionTree) := differentiateExp(e1.exp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);
	        // This might not be needed anymore. If it is simplifiable
	        // Then it would have been simplified above.
	        if not referenceEq(e1.exp, res1) then
	          try
	            (expl, strLst) := match res1
	              case DAE.RECORD(exps=expl,comp=strLst) then (expl, strLst);
	              case DAE.CALL(path=p1,expLst=expl,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path=p2), varLst=varLst)))
	              guard AbsynUtil.pathEqual(p1,p2)
	              then (expl, list(v.name for v in varLst));
	            end match;
	            res := listGet(expl, List.position1OnTrue(strLst, stringEq, e1.fieldName));
	          else
	            e1.exp := res1;
	            (res,_) := ExpressionSimplify.simplify1(e1);
	          end try;
	        end if;
	      end if;
      then (res, functionTree);

    // differentiate tuple
    case DAE.TUPLE(PR=expl) equation

      (expl, functionTree) = List.map3Fold(expl, function differentiateExp(maxIter=maxIter-1), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

      res = DAE.TUPLE(expl);
      (res,_) = ExpressionSimplify.simplify1(res);

    then (res, functionTree);

    case DAE.IFEXP(expCond=e1, expThen=e2, expElse=e3) equation

      (res1, functionTree) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);
      (res2, functionTree) = differentiateExp(e3, inDiffwrtCref, inInputData, inDiffType, functionTree, maxIter-1);

      res = DAE.IFEXP(e1, res1, res2);
      (res,_) = ExpressionSimplify.simplify1(res);

    then (res, functionTree);

    // boolean expression, e.g. relation, are left as they are
    case DAE.RELATION()
    then (inExp, inFunctionTree);

    case DAE.LBINARY()
    then (inExp, inFunctionTree);

    case DAE.LUNARY()
    then (inExp, inFunctionTree);

    case DAE.SIZE()
    then (inExp, inFunctionTree);

    case DAE.RANGE()
    then (inExp, inFunctionTree);

    case DAE.REDUCTION()
      algorithm
        (res1, functionTree) := differentiateExp(inExp.expr, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter-1);

        if not referenceEq(inExp.expr, res1) then
          res := DAE.REDUCTION(inExp.reductionInfo, res1, inExp.iterators);
          res := ExpressionSimplify.simplify1(res);
        else
          res := inExp;
        end if;
      then
        (res, functionTree);

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      s1 = ExpressionDump.printExpStr(inExp);
      s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
      stp = Types.printTypeStr(Expression.typeof(inExp));
      Debug.trace("- differentiateExp " + s1 + " type: " + stp + " w.r.t " + s2 + " failed\n");
    then fail();
  end match;
  if debug then print("Differentiate-Exp-result: " + ExpressionDump.printExpStr(outDiffedExp) + "\n"); end if;
end differentiateExp;

protected function differentiateStatements
  input list<DAE.Statement> inStmts;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input list<DAE.Statement> inStmtsAccum;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output list<DAE.Statement> outDiffedStmts;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedStmts, outFunctionTree) := matchcontinue inStmts
    local
      DAE.ComponentRef cref;
      DAE.ElementSource source;
      DAE.Exp lhs, rhs, derivedLHS, derivedRHS;
      DAE.FunctionTree functions;
      DAE.Statement currStatement, stmt, dstmt;
      DAE.Type type_;
      BackendDAE.DifferentiateInputData inputData;
      BackendDAE.Var controlVar;
      Boolean iterIsArray,initialCall;
      DAE.Ident ident;
      DAE.Exp exp;
      DAE.Exp elseif_exp;
      DAE.Else elseif_else_;
      list<DAE.Exp> expLst, dexpLst, expLstRHS;
      Integer index;
      list<tuple<DAE.Exp, DAE.Exp>> exptl;
      list<DAE.Statement> statementLst, restStatements, derivedStatements1, derivedStatements2, else_statementLst, elseif_statementLst;
      String s1,s2;
      list<Option<DAE.Statement>> optDerivedStatements1;

    case {} then (listReverse(inStmtsAccum), inFunctionTree);

    case (currStatement as DAE.STMT_ASSIGN(type_=type_, exp1=lhs, exp=rhs, source=source))::restStatements
      equation
        (derivedLHS, functions) = differentiateExp(lhs, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (derivedRHS, functions) = differentiateExp(rhs, inDiffwrtCref, inInputData, inDiffType, functions, maxIter);
        (derivedRHS,_) = ExpressionSimplify.simplify(derivedRHS);
        /* if assigment is empty remove derived assignment */
        if (Expression.isZero(derivedLHS)) then
          derivedStatements1 = {currStatement};
        else
          derivedStatements1 = {DAE.STMT_ASSIGN(type_, derivedLHS, derivedRHS, source), currStatement};
        end if;
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case (currStatement as DAE.STMT_TUPLE_ASSIGN(expExpLst= expLst, exp=rhs, source=source))::restStatements
      equation
        (dexpLst,functions) = List.map3Fold(expLst, function differentiateExp(maxIter=maxIter), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (derivedRHS as DAE.TUPLE(expLstRHS), functions) = differentiateExp(rhs, inDiffwrtCref, inInputData, inDiffType, functions, maxIter);
        (DAE.TUPLE(expLstRHS),_) = ExpressionSimplify.simplify(derivedRHS);
        exptl = List.threadTuple(dexpLst, expLstRHS);
        optDerivedStatements1 = List.map2(exptl, makeAssignmentfromTuple, source, inFunctionTree);
        derivedStatements1 = List.flatten(List.map(optDerivedStatements1, List.fromOption));
        derivedStatements1 = listAppend(derivedStatements1, {currStatement});
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case (currStatement as DAE.STMT_TUPLE_ASSIGN(expExpLst=expLst, exp=rhs as DAE.CALL(), type_= type_, source=source))::restStatements
      equation
        (dexpLst,functions) = List.map3Fold(expLst, function differentiateExp(maxIter=maxIter), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (derivedRHS as DAE.CALL(attr=DAE.CALL_ATTR(ty=type_)), functions) = differentiateExp(rhs, inDiffwrtCref, inInputData, inDiffType, functions, maxIter);
        optDerivedStatements1 = {SOME(DAE.STMT_TUPLE_ASSIGN(type_, dexpLst, derivedRHS, source))};
        derivedStatements1 = List.flatten(List.map(optDerivedStatements1, List.fromOption));
        derivedStatements1 = listAppend(derivedStatements1, {currStatement});
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case (currStatement as DAE.STMT_ASSIGN_ARR(lhs=lhs, exp=rhs, type_=type_, source=source))::restStatements
      equation
        (derivedLHS, functions) = differentiateExp(lhs, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (derivedRHS, functions) = differentiateExp(rhs, inDiffwrtCref, inInputData, inDiffType, functions, maxIter);
        (derivedRHS,_) = ExpressionSimplify.simplify(derivedRHS);
        derivedStatements1 = {DAE.STMT_ASSIGN_ARR(type_, derivedLHS, derivedRHS, source), currStatement};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, iter=ident, index=index, range=exp, statementLst=statementLst, source=source)::restStatements
      equation
        cref = ComponentReference.makeCrefIdent(ident, DAE.T_INTEGER_DEFAULT, {});
        controlVar = BackendDAE.VAR(cref, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.BCONST(false), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
        inputData = addGlobalVars({controlVar}, inInputData);
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inputData, inDiffType, {}, inFunctionTree, maxIter);

        derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, index, exp, derivedStatements1, source)};

        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements
      equation
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree, maxIter);
        derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE(), source)};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements
      equation
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree, maxIter);
        (derivedStatements2, functions) = differentiateStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, inDiffwrtCref, inInputData, inDiffType, {}, functions, maxIter);
        derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements
      equation
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree, maxIter);
        (derivedStatements2, functions) = differentiateStatements(else_statementLst, inDiffwrtCref, inInputData, inDiffType, {}, functions, maxIter);
        derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case DAE.STMT_WHILE(exp=exp, statementLst=statementLst, source=source)::restStatements
      equation
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree, maxIter);
        derivedStatements1 = {DAE.STMT_WHILE(exp, derivedStatements1, source)};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case DAE.STMT_WHEN(exp=exp, initialCall=initialCall, statementLst=statementLst, elseWhen= NONE(), source=source)::restStatements
      equation
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree, maxIter);
        derivedStatements1 = {DAE.STMT_WHEN(exp, {}, initialCall, derivedStatements1, NONE(), source)};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case DAE.STMT_WHEN(exp=exp, initialCall=initialCall, statementLst=statementLst, elseWhen= SOME(stmt), source=source)::restStatements
      equation
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree, maxIter);
        ({dstmt}, functions) = differentiateStatements({stmt}, inDiffwrtCref, inInputData, inDiffType, {}, functions, maxIter);
        derivedStatements1 = {DAE.STMT_WHEN(exp, {}, initialCall, derivedStatements1, SOME(dstmt), source)};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions, maxIter);
      then (derivedStatements2, functions);

    case (DAE.STMT_ASSERT())::restStatements
      equation
        (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, inStmtsAccum, inFunctionTree, maxIter);
      then (derivedStatements1, functions);

    case (currStatement as DAE.STMT_TERMINATE())::restStatements
      equation
        derivedStatements1 = currStatement::inStmtsAccum;
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree, maxIter);
      then (derivedStatements2, functions);

    case (currStatement as DAE.STMT_REINIT())::restStatements
      equation
        derivedStatements1 = currStatement::inStmtsAccum;
        (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree, maxIter);
      then (derivedStatements1, functions);

    case (currStatement as DAE.STMT_NORETCALL())::restStatements
      equation
        derivedStatements1 = currStatement::inStmtsAccum;
        (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree, maxIter);
      then (derivedStatements1, functions);

    case (currStatement as DAE.STMT_RETURN())::restStatements
      equation
        derivedStatements1 = currStatement::inStmtsAccum;
        (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree, maxIter);
      then (derivedStatements1, functions);

    case (currStatement as DAE.STMT_BREAK())::restStatements
      equation
        derivedStatements1 = currStatement::inStmtsAccum;
        (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree, maxIter);
      then (derivedStatements1, functions);

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          (currStatement::_) = inStmts;
          s1 = DAEDump.ppStatementStr(currStatement);
          s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
          Debug.trace("- differentiateStatements " + s1 + " w.r.t: " + s2 + " failed\n");
        end if;
      then fail();
  end matchcontinue;
end differentiateStatements;

protected function isDiscreteAssignStatment
  input DAE.Statement inStmt;
  output Boolean out;
algorithm
  out := match (inStmt)
   local
     DAE.Type tp;
    case DAE.STMT_ASSIGN(type_= tp)
    then Types.isDiscreteType(tp);
    case DAE.STMT_ASSIGN_ARR(type_= tp)
    then Types.isDiscreteType(tp);
    case DAE.STMT_TUPLE_ASSIGN(type_= tp)
    then Types.isDiscreteType(tp);
    else false;
  end match;
end isDiscreteAssignStatment;


protected function makeAssignmentfromTuple
"Help function for differentiateStatements"
  input tuple<DAE.Exp, DAE.Exp> inTpl;
  input DAE.ElementSource source;
  input DAE.FunctionTree inFunctionTree;
  output Option<DAE.Statement> outStmt;
algorithm
  outStmt := match(inTpl)
    local
      DAE.Exp e1, e2;
      DAE.Type tp;

      case ((e1 as DAE.CREF(ty=tp), e2))
        then SOME(DAE.STMT_ASSIGN(tp, e1, e2, source));

      case ((e1 as DAE.CALL(), e2)) guard( Expression.isRecordCall(e1, inFunctionTree))
        equation
          tp = Expression.typeof(e1);
        then SOME(DAE.STMT_ASSIGN(tp, e1, e2, source));

      case ((e1, e2)) guard(Expression.isZero(e1))
        equation
          _ = Expression.typeof(e2);
        then NONE();

  end match;
end makeAssignmentfromTuple;

// =============================================================================
// help functions for differentiation
//  - differentiateCrefs
//  - differentiateCalls
//  - differentiateBinary (e.g.: ADD, SUB, MUL, DIV, POW, ...
//
// =============================================================================

protected function differentiateCrefs
  input DAE.Exp inExp;   // in as DAE.CREF(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
protected
  constant Boolean debug = false;
algorithm
  if debug then print("\nDifferentiate Exp-Cref: "+ExpressionDump.printExpStr(inExp)+
                      " w.r.t. "+ComponentReference.printComponentRefStr(inDiffwrtCref)+"\n"); end if;
  (outDiffedExp, outFunctionTree) :=
    matchcontinue(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local

      BackendDAE.DifferentiationType diffType;
      Absyn.Path path;

      BackendDAE.Variables timevars;
      BackendDAE.Variables knvars;
      BackendDAE.Var var;
      BackendDAE.VarKind kind;

      list<BackendDAE.Var> vars;
      DAE.Type tp, arrayType;
      DAE.Exp e, e1, zero, one;
      DAE.Exp res, res1;
      DAE.ComponentRef cr, cr1;
      list<DAE.Exp> expl, expl_1;

      list<DAE.Var> varLst;
      list<Boolean> b_lst;
      list<DAE.ComponentRef> crefs, diffCref;

      String s1, s2, serr, se1, matrixName;

    //
    // This part contains general rules for differentation crefs
    //

    // case for records without expanding the record
    case ((DAE.CREF(componentRef = cr,ty = tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(path)))), _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        cr = ComponentReference.prependStringCref(BackendDAE.functionDerivativeNamePrefix, cr);
        cr = ComponentReference.prependStringCref(matrixName, cr);

        res = Expression.makeCrefExp(cr, tp);
      then
        (res, inFunctionTree);

    // case for Records
    case ((DAE.CREF(componentRef = cr,ty = tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(path)))), _, _, _, _)
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (expl_1, outFunctionTree) = List.map3Fold(expl, function differentiateExp(maxIter=maxIter), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        res = DAE.CALL(path,expl_1,DAE.CALL_ATTR(tp,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
      then
        (res, outFunctionTree);


   // case for array without expanding the array
   case (DAE.CREF(componentRef = cr,ty=tp as DAE.T_ARRAY()), _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        cr = ComponentReference.prependStringCref(BackendDAE.functionDerivativeNamePrefix, cr);
        cr = ComponentReference.prependStringCref(matrixName, cr);

        res = Expression.makeCrefExp(cr, tp);
      then
        (res, inFunctionTree);

    // case for arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY())), _, _, diffType, _) guard ( match diffType case BackendDAE.GENERIC_GRADIENT() then false; else true; end match )
      equation
        true = Flags.isSet(Flags.NF_SCALARIZE); // only expand if scalarize
        (e1,true) = Expression.extendArrExp(e,false);
        (res, outFunctionTree) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      then
        (res, outFunctionTree);

    // let WILD() => WILD()
    case ((e as DAE.CREF(componentRef = DAE.WILD())), _, _, _, _)
      then
        (e, inFunctionTree);

    // D(x)/dx => 1
    case (DAE.CREF(componentRef = cr, ty = tp), _, _, _, _)
      equation
        true = ComponentReference.crefEqual(cr, inDiffwrtCref);
        (one,_) = Expression.makeOneExpression(Expression.arrayDimension(tp));
      then
        (one, inFunctionTree);

    // D(y)/dx => 0
    case (DAE.CREF(ty = tp), _, _, BackendDAE.SIMPLE_DIFFERENTIATION(), _)
      equation
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

      then
        (zero, inFunctionTree);

    // D(y)/dx => 0
    case (DAE.CREF(ty = tp), _, _, BackendDAE.DIFF_FULL_JACOBIAN(), _)
      equation
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

    // Constants, known variables, parameters and discrete variables have a 0-derivative, not the inputs
    case ((DAE.CREF(componentRef = cr, ty = tp)), _, BackendDAE.DIFFINPUTDATA(knownVars=SOME(knvars)), _, _)
      equation
        //print("\nExp-Cref\n known vars: " + ExpressionDump.printExpStr(e));
        (var,_) = BackendVariable.getVarSingle(cr, knvars);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

    // d(discrete)/d(x) = 0
    case ((DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(allVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        (BackendDAE.VAR(varKind = kind),_) = BackendVariable.getVarSingle(cr, timevars);
        //print("\nExp-Cref\n known vars: " + ComponentReference.printComponentRefStr(cr));
        true = listMember(kind,{BackendDAE.DISCRETE()}) or not Types.isReal(tp);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);
    //
    // This part contains special rules for DIFFERENTIATION_TIME()
    //

    // special rule for DUMMY_STATES, they become DUMMY_DER
    case ((DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        (var,_) = BackendVariable.getVarSingle(cr, timevars);
        true = BackendVariable.isDummyStateVar(var);
        cr = ComponentReference.crefPrefixDer(cr);
        res = Expression.makeCrefExp(cr, tp);
      then
        (res, inFunctionTree);

    // Continuous-time variables (and for shared eq-systems, also unknown variables: keep them as-they-are)
    case ((e as DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        //({BackendDAE.VAR(varKind = BackendDAE.STATE(index=_))},_) = BackendVariable.getVar(cr, timevars);
        (_,_) = BackendVariable.getVarSingle(cr, timevars);
        res = DAE.CALL(Absyn.IDENT("der"),{e},DAE.CALL_ATTR(tp,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
      then
        (res, inFunctionTree);

    //
    // This part contains special rules for DIFFERENTIATION_FUNCTION()
    //
    // dependenent variable cref without subscript
    case ((DAE.CREF(componentRef = cr,ty=tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        cr1 = ComponentReference.crefStripLastSubs(cr);
        (_,_) = BackendVariable.getVar(cr1, timevars);
        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

    // dependenent variable cref
    case ((DAE.CREF(componentRef = cr,ty=tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        (_,_) = BackendVariable.getVar(cr, timevars);
        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

    // all other variable crefs are needed to differentiate
    case ((DAE.CREF(componentRef = cr,ty=tp)), _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        cr = ComponentReference.prependStringCref(BackendDAE.functionDerivativeNamePrefix, cr);
        cr = ComponentReference.prependStringCref(matrixName, cr);
        res = Expression.makeCrefExp(cr, tp);
      then
        (res, inFunctionTree);

    //
    // This part contains special rules for GENERIC_GRADIENT()
    //
    case (DAE.CREF(componentRef = cr,ty=tp), DAE.CREF_IDENT(ident="$"), _, BackendDAE.GENERIC_GRADIENT(), _)
      equation
          (res,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (res, inFunctionTree);

    // d(x)/d(x) => generate seed variables
    case ((DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(independenentVars=SOME(timevars),matrixName=SOME(matrixName)), BackendDAE.GENERIC_GRADIENT(), _)
      equation
        //true = List.isMemberOnTrue(cr, diffCref, ComponentReference.crefEqual);
        (_::_, _) = BackendVariable.getVar(cr, timevars);
        cr = createSeedCrefName(cr, matrixName);

        res = DAE.CREF(cr, tp);
      then
        (res, inFunctionTree);


    // d(x)/d(z) = CREF(d(x)/d(dummy))
    case (DAE.CREF(componentRef=cr, ty=tp), _, BackendDAE.DIFFINPUTDATA(allVars=SOME(timevars),matrixName=SOME(matrixName)), BackendDAE.GENERIC_GRADIENT(), _)
      equation
        (var::_, _) = BackendVariable.getVar(cr, timevars);
        //Take care! state means => der(state)
        false = BackendVariable.isStateVar(var);

        cr = ComponentReference.createDifferentiatedCrefName(cr, inDiffwrtCref, matrixName);
        res = DAE.CREF(cr, tp);
      then
        (res, inFunctionTree);

    // d(x)/d(z) = CREF(d(x)/d(dummy))
    case (DAE.CREF(componentRef=cr, ty=tp), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars),matrixName=SOME(matrixName)), BackendDAE.GENERIC_GRADIENT(), _)
      equation
        (var::_, _) = BackendVariable.getVar(cr, timevars);
        //Take care! state means => der(state)
        false = BackendVariable.isStateVar(var);

        cr = ComponentReference.createDifferentiatedCrefName(cr, inDiffwrtCref, matrixName);
        res = DAE.CREF(cr, tp);
      then
        (res, inFunctionTree);

    // d(state)/d(x) = 0
    // d(input)/d(x) = 0
    // d(all other)/d(x) = 0
    case (DAE.CREF(ty=tp), _, _, BackendDAE.GENERIC_GRADIENT(), _)
      equation
        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s1 = ExpressionDump.printExpStr(inExp);
        se1 = Types.printTypeStr(Expression.typeof(inExp));
        s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
        serr = stringAppendList({"\n- differentiateCrefs ",s1," type:", se1 ," w.r.t: ",s2," failed\n"});
        Debug.trace(serr);
      then
        fail();
  end matchcontinue;
  if debug then print("Differentiate-ExpCref-result: " + ExpressionDump.printExpStr(outDiffedExp) + "\n"); end if;
end differentiateCrefs;

public function createDiffedCrefName
  input DAE.ComponentRef inCref;
  input String inMatrixName;
  output DAE.ComponentRef outCref;
protected
 list<DAE.Subscript> subs;
algorithm
  subs := ComponentReference.crefLastSubs(inCref);

  outCref := ComponentReference.crefStripLastSubs(inCref);

  outCref := ComponentReference.prependStringCref(BackendDAE.functionDerivativeNamePrefix, outCref);
  outCref := ComponentReference.prependStringCref(inMatrixName, outCref);
  outCref := ComponentReference.crefSetLastSubs(outCref, subs);
  outCref := ComponentReference.crefSetLastType(outCref, ComponentReference.crefLastType(inCref));
end createDiffedCrefName;

public function createSeedCrefName
  input DAE.ComponentRef inCref;
  input String inMatrixName;
  output DAE.ComponentRef outCref;
protected
  list<DAE.Subscript> subs;
  constant Boolean debug = false;
algorithm
  if debug then print("inCref: " + ComponentReference.printComponentRefStr(inCref) +"\n"); end if;
  if debug then print("after full type  " + Types.printTypeStr(ComponentReference.crefTypeConsiderSubs(inCref)) + "\n"); end if;
  subs := ComponentReference.crefLastSubs(inCref);
  outCref := ComponentReference.crefStripLastSubs(inCref);
  outCref := ComponentReference.crefSetLastType(outCref, DAE.T_UNKNOWN_DEFAULT);
  outCref := ComponentReference.joinCrefs(outCref, ComponentReference.makeCrefIdent("Seed" + inMatrixName, DAE.T_UNKNOWN_DEFAULT, {}));
  if debug then print("after join: " + ComponentReference.printComponentRefListStr(ComponentReference.expandCref(outCref, true)) + "\n"); end if;
  outCref := ComponentReference.crefSetLastSubs(outCref, subs);
  outCref := ComponentReference.crefSetLastType(outCref, ComponentReference.crefLastType(inCref));
  if debug then print("outCref: " + ComponentReference.printComponentRefStr(outCref) +"\n"); end if;
end createSeedCrefName;

protected function differentiateCalls
"
function: differentiateCalls
"
  input DAE.Exp inExp;   // in as DAE.CALL(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
protected
  constant Boolean debug = false;
algorithm
  if debug then print("\nDifferentiate Exp-Call: "+ExpressionDump.printExpStr(inExp)+
                      " w.r.t. "+ComponentReference.printComponentRefStr(inDiffwrtCref)+"\n"); end if;

  (outDiffedExp, outFunctionTree) :=
    match(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local

      Absyn.Path path;

      BackendDAE.Var var;
      BackendDAE.Variables timevars;
      BackendDAE.Variables knvars;

      DAE.CallAttributes attr;
      DAE.ComponentRef cr;
      DAE.Exp e, e1, e2, zero;
      DAE.Exp res, res1, actual, simplified;
      DAE.Type tp;
      DAE.FunctionTree funcs;

      Integer i;

      list<Boolean> blst;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expl, expl_1;

      list<list<DAE.ComponentRef>> crefslstls;
      Option<BackendDAE.Shared> optShared;

      String s1, s2, serr, matrixName, name;

    // differentiate homotopy
    case (DAE.CALL(path=path as Absyn.IDENT(name="homotopy"), expLst={actual, simplified}, attr=attr), _, _, _, _) equation
      (e1, funcs) = differentiateExp(actual, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      (e2, funcs) = differentiateExp(simplified, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      res = DAE.CALL(path, {e1, e2}, attr);
    then (e1, funcs);

    /* with previous are the actaully states marked in synchronous */
    case (e as DAE.CALL(path=Absyn.IDENT(name = "previous"), expLst = {DAE.CREF(componentRef=cr, ty=tp)}),
           _, BackendDAE.DIFFINPUTDATA(independenentVars=SOME(timevars),matrixName=SOME(matrixName)),
          BackendDAE.GENERIC_GRADIENT(), _) equation

      cr = ComponentReference.makeCrefQual(DAE.previousNamePrefix, tp, {}, cr);
      (_::_, _) = BackendVariable.getVar(cr, timevars);
      cr = createSeedCrefName(cr, matrixName);

      res = DAE.CREF(cr, tp);
    then (res, inFunctionTree);

    case (DAE.CALL(path = path as Absyn.IDENT(name = "der"),expLst = {e},attr=attr), _, _, BackendDAE.DIFFERENTIATION_TIME(), _)
      then
        (DAE.CALL(path,{e,DAE.ICONST(2)},attr),  inFunctionTree);

    case (DAE.CALL(path = (path as Absyn.IDENT(name = "der")),expLst = {e,DAE.ICONST(i)},attr=attr), _, _, BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        i = i + 1;
      then
        (DAE.CALL(path,{e,DAE.ICONST(i)},attr), inFunctionTree);

    case (DAE.CALL(path=Absyn.IDENT(name = "der"),expLst = {e}), _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), _, _)
      equation
        cr = Expression.expCref(e);
        tp = Expression.typeof(e);
        cr = ComponentReference.crefPrefixDer(cr);
        cr = ComponentReference.createDifferentiatedCrefName(cr, inDiffwrtCref, matrixName);
        res = Expression.makeCrefExp(cr, tp);

        if ComponentReference.crefEqual(DAE.CREF_IDENT("$",DAE.T_REAL_DEFAULT,{}), inDiffwrtCref) then
          (res,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        end if;
      then
        (res, inFunctionTree);

    /* Differentiate with respect to DAE.CREF_IDENT(ident="$") demands zero expressions */
    case (DAE.CALL(path=Absyn.IDENT(name = "der"),expLst = {e}), DAE.CREF_IDENT(ident="$"), _, _, _)
      equation
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(Expression.typeof(e)));
      then
        (zero,  inFunctionTree);

    /* Exclude records here, they are handled component-wise in differentiateFunctionCall
       and builtin function are handled in differentiateCall* */
    case (e as DAE.CALL(attr=DAE.CALL_ATTR(ty=tp,builtin=false)), DAE.CREF_IDENT(ident="$"), _, _, _)
      guard ( not Expression.isRecordCall(e, inFunctionTree) )
      equation
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

    // differentiate builtin calls with 1 argument
    case (DAE.CALL(path=Absyn.IDENT(name),attr=DAE.CALL_ATTR(builtin=true),expLst={e}), _, _, _, _)
      equation
        (res,  funcs) = differentiateCallExp1Arg(name, e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      then (res,  funcs);

    // differentiate builtin calls with N arguments with match
    // der(arctan2(y,0)) = der(sign(y)*pi/2) = 0
    case (DAE.CALL(path=Absyn.IDENT("atan2"),attr=DAE.CALL_ATTR(builtin=true),expLst={_,e1 as  DAE.RCONST(real=0.0)}), _, _, _, _)
      then
        (e1,  inFunctionTree);

    // differentiate builtin calls with N arguments as match
    case (DAE.CALL(path=Absyn.IDENT(name),attr=(attr as DAE.CALL_ATTR(builtin=true)),expLst= (expl as (_::_::_))), _, _, _, _)
      equation
        (res,  funcs) = differentiateCallExpNArg(name, expl, attr, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      then (res,  funcs);

    case (e as DAE.CALL(), _, _, _, _)
      equation
        (e1, funcs) = differentiateFunctionCall(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (e1,_,_,_) = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}),DAE.emptyElementSource/*TODO:Can we propagate source?*/);
      then
        (e1, funcs);
/*
    case (e as DAE.CALL(expLst = _), _, _, _, _)
      equation
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {ExpressionDump.printExpStr(e), ComponentReference.printComponentRefStr(inDiffwrtCref)});
      then
        fail();
*/
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s1 = ExpressionDump.printExpStr(inExp);
        s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
        serr = stringAppendList({"\n- Function differentiateCalls failed. differentiateExp ",s1," w.r.t: ",s2," failed\n"});
        Debug.trace(serr);
      then
        fail();
  end match;
  if debug then print("Differentiate-ExpCall-result: " + ExpressionDump.printExpStr(outDiffedExp) + "\n"); end if;
end differentiateCalls;

protected function differentiateCallExp1Arg
  "This function differentiates built-in call expressions with 1 argument
  with respect to a given variable,given as third argument."
  input String name;
  input DAE.Exp exp;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFuncs;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp,outFunctionTree) := match (name, exp)
    local
      DAE.Exp exp_1,exp_2;
      DAE.FunctionTree funcs;
      DAE.Type tp;
      list<DAE.Exp> expl;

    case ("pre",_) equation
      tp = Expression.typeof(exp);
      exp_1 = Expression.makeZeroExpression(Expression.arrayDimension(tp));
    then (exp_1, inFuncs);

    case ("previous",_) equation
      tp = Expression.typeof(exp);
      exp_1 = Expression.makeZeroExpression(Expression.arrayDimension(tp));
    then (exp_1, inFuncs);

    case ("$getPart",_) equation
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
    then (exp_1, funcs);

    case ("firstTick",_) then (exp, inFuncs);
    case ("interval",_) then (exp, inFuncs);

    // diff(sin(x)) = cos(x)*der(x)
    case ("sin",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("cos", {exp}, tp);
      then (DAE.BINARY(exp_2, DAE.MUL(tp), exp_1), funcs);

    // diff(cos(x)) = -sin(x)*der(x)
    case ("cos",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("sin", {exp}, tp);
      then (DAE.BINARY(DAE.UNARY(DAE.UMINUS(tp),exp_2), DAE.MUL(tp), exp_1), funcs);

    // diff(tan(x)) = (2*der(x)/(cos(2*x)+1))
    case ("tan",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("cos", {DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(tp),exp)}, tp);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.RCONST(2.0), DAE.MUL(tp), exp_1), DAE.DIV(tp),
          DAE.BINARY(exp_2, DAE.ADD(tp), DAE.RCONST(1.0))), funcs);

    // der(arcsin(x)) = der(x)/sqrt(1-x^2)
    case ("asin",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("sqrt", {DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(tp),DAE.BINARY(exp,DAE.MUL(tp),exp))}, tp);
      then (DAE.BINARY(exp_1,DAE.DIV(tp),exp_2), funcs);

    // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case ("acos",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("sqrt", {DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(tp),DAE.BINARY(exp,DAE.MUL(tp),exp))}, tp);
      then (DAE.UNARY(DAE.UMINUS(tp),DAE.BINARY(exp_1,DAE.DIV(tp),exp_2)), funcs);

    // der(arctan(x)) = der(x)/(1+x^2)
    case ("atan",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
      then (DAE.BINARY(exp_1,DAE.DIV(tp),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(tp),DAE.BINARY(exp,DAE.MUL(tp),exp))), funcs);

    // der(sinh(x)) => der(x)sinh(x)
    case ("sinh",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("cosh",{exp},tp);
      then (DAE.BINARY(exp_1,DAE.MUL(tp),exp_2), funcs);

    // der(cosh(x)) => der(x)sinh(x)
    case ("cosh",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("sinh",{exp},tp);
      then (DAE.BINARY(exp_1,DAE.MUL(tp),exp_2), funcs);

    // der(tanh(x)) = der(x) / cosh(x)^2
    case ("tanh",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType, inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("cosh", {exp}, tp);
      then (DAE.BINARY(exp_1, DAE.DIV(tp),
                      DAE.BINARY(exp_2, DAE.POW(tp), DAE.RCONST(2.0))), funcs);

    // diff(exp(x)) = der(x)*exp(x)
    case ("exp",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("exp",{exp},tp);
      then (DAE.BINARY(exp_2, DAE.MUL(tp), exp_1), funcs);

    // diff(log(x)) = der(x)/x
    case ("log",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
      then
        (DAE.BINARY(exp_1, DAE.DIV(tp), exp), funcs);

    // diff(log10(x)) = der(x)/(x*log(10))
    case ("log10",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("log",{DAE.RCONST(10.0)},tp);
      then
        (DAE.BINARY(exp_1, DAE.DIV(tp),
          DAE.BINARY(exp, DAE.MUL(tp), exp_2)), funcs);

    // diff(sqrt(x)) = der(x)/(2*sqrt(x))
    case ("sqrt",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("sqrt",{exp},tp);
      then
        (DAE.BINARY(exp_1, DAE.DIV(tp),
          DAE.BINARY(DAE.RCONST(2.0), DAE.MUL(tp), exp_2)), funcs);

    // der(abs(x)) = sign(x)der(x)
    case ("abs",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("sign",{exp}, tp);
      then (DAE.BINARY(exp_2, DAE.MUL(tp), exp_1), funcs);

    case ("sign",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then (exp_1, inFuncs);

    case ("transpose",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("transpose",{exp_1},tp);
      then
       (exp_2, funcs);

    case ("sum",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs, maxIter);
        exp_2 = Expression.makePureBuiltinCall("sum",{exp_1},tp);
      then
       (exp_2, funcs);

    case ("max",DAE.ARRAY(array=expl,ty=tp))
      equation
        tp = Types.arrayElementType(tp);
        exp_1 = createFromNCall2ArgsCall("max", expl, tp);
        (exp_2, funcs) = differentiateExp(exp_1, inDiffwrtCref, inInputData, inDiffType, inFuncs, maxIter);
      then
       (exp_2, funcs);

    case ("min",DAE.ARRAY(array=expl,ty=tp))
      equation
        tp = Types.arrayElementType(tp);
        exp_1 = createFromNCall2ArgsCall("min", expl, tp);
        (exp_2, funcs) = differentiateExp(exp_1, inDiffwrtCref, inInputData, inDiffType, inFuncs, maxIter);
      then
       (exp_2, funcs);

    case ("floor",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (exp_1, inFuncs);

    case ("ceil",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (exp_1, inFuncs);

    case ("integer",_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (exp_1, inFuncs);

  end match;
end differentiateCallExp1Arg;

protected function createFromNCall2ArgsCall
  input String funcName;
  input list<DAE.Exp> expl;
  input DAE.Type tp;
  output DAE.Exp result;
protected
  DAE.Exp e1,e2;
  list<DAE.Exp> rest;
algorithm
 e1::e2::rest := expl;
 result := Expression.makePureBuiltinCall(funcName,{e1,e2},tp);
 for elem in rest loop
   result := Expression.makePureBuiltinCall(funcName,{result,elem},tp);
 end for;
end createFromNCall2ArgsCall;

protected function differentiateCallExpNArg "
  This function differentiates built-in call expressions with N argument
  with respect to a given variable,given as third argument."
  input String name;
  input list<DAE.Exp> inExpl;
  input DAE.CallAttributes inAttr;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp,outFunctionTree) := match(name,inExpl,inAttr)
    local
      DAE.Exp e, e1, e2, cond, etmp;
      DAE.Exp res, res1, res2;
      list<DAE.Exp> expl, dexpl;
      DAE.Type tp;
      DAE.FunctionTree funcs;
      String e_str;
      Integer i;

    case ("smooth",{DAE.ICONST(i),e2}, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, funcs) = differentiateExp(e2,inDiffwrtCref,inInputData,inDiffType,inFunctionTree, maxIter);
        e1 = Expression.expSub(DAE.ICONST(i), DAE.ICONST(1));
        res2 = if intGe(i,1) then Expression.makePureBuiltinCall("smooth", {e1, res1}, tp) else res1;
      then
        (res2, funcs);

    case ("noEvent",{e1}, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, funcs) = differentiateExp(e1,inDiffwrtCref,inInputData,inDiffType,inFunctionTree, maxIter);
        res1 = Expression.makePureBuiltinCall("noEvent", {res1}, tp);
      then
        (res1, funcs);

    // der(arctan2(x,y)) = der(x/y)/(1+(x/y)^2)
    case ("atan2",{e,e1}, DAE.CALL_ATTR(ty=tp))
      equation
        e2 = Expression.makeDiv(e,e1);
        (res1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        res2 = Expression.addNoEventToRelations(DAE.IFEXP(DAE.RELATION(e1,DAE.EQUAL(tp),DAE.RCONST(0.0),-1,NONE()),
                e1,
                DAE.BINARY(res1, DAE.DIV(tp), DAE.BINARY(DAE.RCONST(1.0), DAE.ADD(tp), DAE.BINARY(e2, DAE.MUL(tp),e2)))
               ));

      then
        (res2,  funcs);

    // der(semiLinear(x,a,b)) = if (x>=0) then a*x else b*x -> if (x>=0) then da*x+a*dx else db*x+b*dx
    case ("semiLinear", {e,e1,e2}, DAE.CALL_ATTR(ty=tp))
      equation
        (res, funcs) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
        res1 = Expression.expAdd(Expression.expMul(res1, e),Expression.expMul(e1, res));
        res2 = Expression.expAdd(Expression.expMul(res2, e),Expression.expMul(e2, res));
        (res, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        res = DAE.RELATION(e, DAE.GREATEREQ(tp), res, -1, NONE());
      then
        (DAE.IFEXP(res, res1, res2), funcs);

    case ("cross", {e1,e2}, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
        res2 = Expression.makePureBuiltinCall("cross",{e1,res2},tp);
        res1 = Expression.makePureBuiltinCall("cross",{res1,e2},tp);
      then
        (DAE.BINARY(res2, DAE.ADD_ARR(tp), res1), funcs);

    case ("max", {e1,e2}, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(e1,DAE.GREATER(tp),e2,-1,NONE())},DAE.callAttrBuiltinBool), res1, res2), funcs);

    case ("min", {e1,e2}, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(e1,DAE.LESS(tp),e2,-1,NONE())},DAE.callAttrBuiltinBool), res1, res2), funcs);

    // diff(div(e1,e2)) =  diff(if noEvent(e1 > 0) then floor(e1/e2) else ceil(e1/e2)) = 0.0;
    case ("div", {_,_}, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (res1, inFunctionTree);

    // diff(mod(e1,e2)) =  diff(e1 - e2*floor(e1/e2))
    case ("mod", {e1,e2}, DAE.CALL_ATTR(ty=tp))
      equation
        etmp = Expression.makePureBuiltinCall("floor", {DAE.BINARY(e1, DAE.DIV(tp), e2)}, tp);
        e = DAE.BINARY(e1, DAE.SUB(tp), DAE.BINARY(e2, DAE.MUL(tp),  etmp));
        (res1, funcs) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      then
        (res1, funcs);

    // diff(rem(e1,e2)) = diff(e1 -div(e1,e2)*e2)
    case ("rem", {e1,e2}, DAE.CALL_ATTR(ty=tp))
      equation
        _ = Expression.makePureBuiltinCall("div", {e1, e2}, tp);
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      then
        (res1, funcs);

    case ("sample", _, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (res1, inFunctionTree);
    /* floor ceil and interger are expanded by the zeroCrossing index, thus they
       have 2 arguments */
    case ("floor", _, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (res1, inFunctionTree);

    case ("ceil", _, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (res1, inFunctionTree);

    case ("integer", _, DAE.CALL_ATTR(ty=tp))
      equation
        (res1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (res1, inFunctionTree);

  end match;
end differentiateCallExpNArg;

protected function differentiateBinary
  input DAE.Exp inExp;   // in as DAE.BINARY(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp, outFunctionTree) := match inExp
    local

      Absyn.Path path;

      BackendDAE.Var var;
      BackendDAE.Variables timevars;
      BackendDAE.Variables knvars;

      DAE.CallAttributes attr;
      DAE.ComponentRef cr;
      DAE.Exp e, e0, e1, e2, zero, etmp;
      DAE.Exp de1, de2;
      DAE.FunctionTree funcs;
      DAE.Operator op;
      DAE.Type tp, tp1;

      Integer i;

      list<Boolean> blst;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expl, expl_1;

      list<list<DAE.ComponentRef>> crefslstls;
      Option<BackendDAE.Shared> optShared;

      Real r;

      String s1, s2, serr;

    case DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(de1,DAE.ADD(tp),de2), funcs);

    case DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(de1,DAE.ADD_ARR(tp),de2), funcs);

    case DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARRAY_SCALAR(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(de1,DAE.ADD_ARRAY_SCALAR(tp),de2), funcs);

    case DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(de1,DAE.SUB(tp),de2), funcs);

    case DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(de1,DAE.SUB_ARR(tp),de2), funcs);

    case DAE.BINARY(exp1 = e1,operator = DAE.SUB_SCALAR_ARRAY(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(de1,DAE.SUB_SCALAR_ARRAY(tp),de2), funcs);

    // fg\' + f\'g
    case DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),de2),DAE.ADD(tp),
          DAE.BINARY(de1,DAE.MUL(tp),e2)), funcs);

    // fg\' + f\'g
    case DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARR(tp),de2),DAE.ADD(tp),
          DAE.BINARY(de1,DAE.MUL_ARR(tp),e2)), funcs);

    // fg\' + f\'g
    case DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARRAY_SCALAR(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),de2),DAE.ADD_ARR(tp),
          DAE.BINARY(de1,DAE.MUL_ARRAY_SCALAR(tp),e2)), funcs);

    // fg\' + f\'g
    case DAE.BINARY(exp1 = e1,operator = DAE.MUL_SCALAR_PRODUCT(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_SCALAR_PRODUCT(tp),de2),DAE.ADD(tp),
          DAE.BINARY(de1,DAE.MUL_SCALAR_PRODUCT(tp),e2)), funcs);

    // fg\' + f\'g
    case DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_MATRIX_PRODUCT(tp),de2),DAE.ADD_ARR(tp),
          DAE.BINARY(de1,DAE.MUL_MATRIX_PRODUCT(tp),e2)), funcs);

    // (f\'g - fg\') / g^2
    case DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(
             DAE.BINARY(DAE.BINARY(de1,DAE.MUL(tp),e2), DAE.SUB(tp),
             DAE.BINARY(e1,DAE.MUL(tp),de2)), DAE.DIV(tp), DAE.BINARY(e2,DAE.MUL(tp),e2)), funcs);

    // (f\'g - fg\') / g^2
    case DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.BINARY(de1,DAE.MUL_ARR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARR(tp),de2)), DAE.DIV_ARR(tp), DAE.BINARY(e2,DAE.MUL_ARR(tp),e2)), funcs);


    // (f\'g - fg\') / g^2
    case DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARRAY_SCALAR(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
        tp1 = Expression.typeof(e2);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.BINARY(de1,DAE.MUL_ARRAY_SCALAR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),de2)),DAE.DIV_ARRAY_SCALAR(tp),DAE.BINARY(e2,DAE.MUL(tp1),e2)), funcs);

    // (f\'g - fg\') / g^2
    case DAE.BINARY(exp1 = e1,operator = DAE.DIV_SCALAR_ARRAY(ty = tp),exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs, maxIter);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.BINARY(de1,DAE.MUL_ARRAY_SCALAR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),de2)),DAE.DIV_ARR(tp),DAE.BINARY(e2,DAE.MUL_ARR(tp),e2)), funcs);

    // x^r
    case DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.RCONST(real=r)))
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        r = r - 1.0;
        e = DAE.BINARY(DAE.BINARY(e2,DAE.MUL(tp),
                       DAE.BINARY(e1,DAE.POW(tp),DAE.RCONST(r))),
                       DAE.MUL(tp),de1);
      then
        (e, funcs);
    // x^i
  case DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.ICONST(integer = i)))
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        i = i - 1;
        e = DAE.BINARY(DAE.BINARY(e2,DAE.MUL(tp),
                       DAE.BINARY(e1,DAE.POW(tp),DAE.ICONST(i))),
                       DAE.MUL(tp),de1);
      then
        (e, funcs);
    // der(0^x) = 0
    case DAE.BINARY(exp1 = (DAE.RCONST(real=0.0)),operator = DAE.POW(tp))
      equation
        zero = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

    // der(r^x)  = r^x*ln(r)*der(x)
    case e0 as DAE.BINARY(exp1 = DAE.RCONST(real=r),operator = DAE.POW(tp),exp2 = e1)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        r = log(r);
        e = DAE.BINARY(DAE.BINARY(e0,DAE.MUL(tp),DAE.RCONST(r)),DAE.MUL(tp),de1);
      then
        (e, funcs);

    // added for ticket #6068
    // (p is a parameter)
    // x^p
    case DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.CREF(componentRef = cr)))
      guard(isParamOrConstant(cr, inInputData))
      equation
        etmp = match tp
          case DAE.T_INTEGER()  then DAE.BINARY(e2, DAE.SUB(tp), DAE.ICONST(1));
          else DAE.BINARY(e2, DAE.SUB(tp), DAE.RCONST(1.0));
        end match;
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        e = DAE.BINARY(DAE.BINARY(e2,DAE.MUL(tp),
                       DAE.BINARY(e1,DAE.POW(tp),etmp)),
                       DAE.MUL(tp),de1);
      then
        (e, funcs);

    // added for ticket #6068
    // (p is a parameter)
    // der(p^x)  = p^x*ln(p)*der(x)
    // if p == 0 then 0;
    case e0 as DAE.BINARY(exp1 = e1 as DAE.CREF(componentRef = cr), operator = DAE.POW(tp), exp2 = e2)
      guard(isParamOrConstant(cr, inInputData))
      equation
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        etmp = Expression.makePureBuiltinCall("log", {e1}, tp);
        // if p is equal to zero, then return zero (do not search for event)
        e = Expression.addNoEventToRelations(
          DAE.IFEXP(DAE.RELATION(e1, DAE.EQUAL(tp), DAE.RCONST(0.0), -1, NONE()), DAE.RCONST(0.0),
          DAE.BINARY(DAE.BINARY(e0,DAE.MUL(tp),etmp),DAE.MUL(tp),de2)));
      then
        (e, funcs);


    // der(x^y) = x^(y-1) * ( x*ln(x)*der(y)+(y*der(x)))
    // if x == 0 then 0;
    case DAE.BINARY(exp1 = e1,operator = DAE.POW(tp), exp2 = e2)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        etmp = Expression.makePureBuiltinCall("log", {e1}, tp);
        // if x is equal to zero, then return zero (do not search for event)
        e = Expression.addNoEventToRelations(DAE.IFEXP(DAE.RELATION(e1, DAE.EQUAL(tp), DAE.RCONST(0.0), -1, NONE()),
                       DAE.RCONST(0.0), DAE.BINARY(DAE.BINARY(e1, DAE.POW(tp), DAE.BINARY(e2, DAE.SUB(tp), DAE.RCONST(1.0))),
                       DAE.MUL(tp), DAE.BINARY(DAE.BINARY(DAE.BINARY(e1, DAE.MUL(tp), etmp), DAE.MUL(tp), de2),
                                    DAE.ADD(tp), DAE.BINARY(e2, DAE.MUL(tp), de1)))));
      then
        (e, funcs);

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s1 = ExpressionDump.printExpStr(inExp);
        s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
        serr = stringAppendList({"\n- Function differentiateBinary failed. differentiateExp ",s1," w.r.t: ",s2," failed\n"});
        Debug.trace(serr);
      then
        fail();

    end match;
end differentiateBinary;

// =============================================================================
// functions to generate derivative of a function
// =============================================================================

protected function differentiateFunctionCall"
Author: Frenkel TUD, wbraun

"
  input DAE.Exp inExp;   // in as DAE.CALL(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp, outFunctionTree) :=
    matchcontinue(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local

      BackendDAE.DifferentiateInputData inputData, diffFuncData;

      DAE.Exp e, de, zero;
      list<DAE.Exp> expl,expl1,dexpl;
      BackendDAE.Variables timevars;
      Absyn.Path path,dpath;
      Boolean b,c,isImpure;
      DAE.InlineType dinl;
      DAE.Type ty;
      DAE.FunctionTree functions;
      DAE.FunctionDefinition mapper;
      DAE.Type tp, dtp;
      list<Boolean> blst;
      list<DAE.Type> tlst;
      list<tuple<DAE.Exp,Boolean>> expBoolLst;
      String typstring, dastring, funstring, str;
      list<String> typlststring;
      DAE.TailCall tc;
      DAE.CallAttributes attr;

      DAE.FunctionDefinition derfuncdef;
      DAE.Function func,dfunc;
      list<DAE.Function> fns;
      String funcname, s1;
      list<DAE.FuncArg> falst;

    /* ticket5459
    if the function call does not contain the cref, the derivative is zero
    prevents failing of this function
    - Maybe not only for SIMPLE_DIFFERENTIATION ?
    */
    case (_, _, _, BackendDAE.SIMPLE_DIFFERENTIATION(), _)
      guard(not Expression.expHasCref(inExp, inDiffwrtCref))
      algorithm
        (e, _) := Expression.makeZeroExpression(Expression.arrayDimension(ComponentReference.crefTypeFull(inDiffwrtCref)));
    then (e, inFunctionTree);

    case (DAE.CALL(path=path,expLst=expl,attr=DAE.CALL_ATTR(tuple_=b,builtin=c,isImpure=isImpure,ty=ty,tailCall=tc)), _, _, BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        // get function mapper
        //print("Search for function mapper\n");
        (mapper, tp) = getFunctionMapper(path, inFunctionTree);
        (dpath, blst) = differentiateFunction1(path,mapper, tp, expl, (inDiffwrtCref, inInputData, inDiffType, inFunctionTree));
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAE.AvlTreePathFunction.get(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (true,_) = checkDerivativeFunctionInputs(blst, tp, dtp);
        (expl1,_) = List.splitOnBoolList(expl, blst);
        (dexpl, outFunctionTree) = List.map3Fold(expl1, function differentiateExp(maxIter=maxIter), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        expl1 = listAppend(expl,dexpl);
      then
        (DAE.CALL(dpath,expl1,DAE.CALL_ATTR(ty,b,c,isImpure,false,dinl,tc)),outFunctionTree);

    case (DAE.CALL(path=path,expLst=expl), _, _, BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        // get function mapper
        //print("Search for function mapper2\n");
        (mapper, tp) = getFunctionMapper(path, inFunctionTree);
        (dpath, blst) = differentiateFunction1(path, mapper, tp, expl, (inDiffwrtCref, inInputData, inDiffType, inFunctionTree));
        SOME(DAE.FUNCTION(type_ = dtp)) = DAE.AvlTreePathFunction.get(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (false, tlst) = checkDerivativeFunctionInputs(blst, tp, dtp);
        // add Warning
        typlststring = List.map(tlst, Types.unparseType);
        typstring = "\n" + stringDelimitList(typlststring,";\n");
        dastring = AbsynUtil.pathString(dpath);
        print("Input warnings for function mapper2\n");
        Error.addMessage(Error.UNEXPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});
      then
        fail();

    // try to inline
    case (DAE.CALL(attr=DAE.CALL_ATTR(builtin=false)), _, _, _, _)
      equation
        failure(BackendDAE.DIFF_FULL_JACOBIAN() = inDiffType);
        (e,_,true) = Inline.forceInlineExp(inExp,(SOME(inFunctionTree),{DAE.NORM_INLINE(),DAE.DEFAULT_INLINE()}),DAE.emptyElementSource);
        (e, functions) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      then
        (e, functions);

    // differentiate record call
    case (e as DAE.CALL(path=path, expLst=expl, attr=attr), _, _, _, _) guard( Expression.isRecordCall(e, inFunctionTree))
      equation
        (dexpl, functions) = List.map3Fold(expl, function differentiateExp(maxIter=maxIter), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      then (DAE.CALL(path, dexpl, attr), functions);

    //differentiate function partial
    case (e, _, _, _, _)
      equation
        // Debug dump
        if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
          BackendDump.debugStrExpStr("### Differentiate call\n ", e, " w.r.t. " + ComponentReference.crefStr(inDiffwrtCref) + "\n");
        end if;
        (de, functions) = differentiateFunctionCallPartial(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
        (e,_,b) = Inline.forceInlineExp(de,(SOME(functions),{DAE.NORM_INLINE(),DAE.DEFAULT_INLINE()}),DAE.emptyElementSource);
        if b then
          de = e;
        end if;
        // Debug dump
        if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
          BackendDump.debugStrExpStr("### result output :\n", de, " w.r.t. " + ComponentReference.crefStr(inDiffwrtCref) + "\n");
        end if;
      then
        (de, functions);

    case (_, _, _, _, _)
      equation
        /* TODO: Check replace this rule by other, since it's not correct
                 in case of
                 - failure(BackendDAE.DIFFERENTIATION_FUNCTION() = inDiffType);
                 - failure(BackendDAE.GENERIC_GRADIENT() = inDiffType);
                 but anyway fornow it catches some testsuite cases.
        */
        false = Expression.expContains(inExp, Expression.crefExp(inDiffwrtCref))
        "If the expression does not contain the variable,
         the derivative is zero. For efficiency reasons this rule
         is last. Otherwise expressions is always traversed twice
         when differentiating.";
        tp = Expression.typeof(inExp);
        zero = Expression.createZeroExpression(tp);
      then (zero, inFunctionTree);

      else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = "Differentiate.differentiateFunctionCall failed for " + ExpressionDump.printExpStr(inExp) + "\n";
        Debug.trace(str);
      then fail();
  end matchcontinue;
end differentiateFunctionCall;

protected function differentiateFunctionCallPartial"
Author: Frenkel TUD, wbraun

"
  input DAE.Exp inExp;   // in as DAE.CALL(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp, outFunctionTree) :=
    matchcontinue(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local

      BackendDAE.DifferentiateInputData inputData, diffFuncData;

      DAE.Exp e, exp, zero, ezero;
      list<DAE.Exp> expl,expl1,dexpl,dexplZero;
      BackendDAE.Variables timevars;
      Absyn.Path path,dpath;
      Boolean b,c,isImpure;
      DAE.InlineType dinl;
      DAE.Type ty, dtp;
      DAE.FunctionTree functions;
      DAE.FunctionDefinition mapper;
      DAE.Type tp, dtp;
      list<Boolean> blst;
      list<DAE.Type> tlst;
      list<tuple<DAE.Exp,Boolean>> expBoolLst;
      String typstring, dastring, funstring, str;
      list<String> typlststring;
      DAE.TailCall tc;

      list<DAE.Element> funcbody, funcbodyDer;
      list<DAE.Element> inputVars, inputVarsNoDer, inputVarsDer;
      list<DAE.Element> outputVars, outputVarsNoDer, outputVarsDer;
      list<DAE.Element> protectedVars, protectedVarsNoDer, protectedVarsDer, newProtectedVars;
      list<DAE.Statement> bodyStmts, derbodyStmts;

      DAE.FunctionDefinition derfuncdef;
      DAE.Function func,dfunc;
      list<DAE.Function> fns;
      String funcname;
      list<DAE.FuncArg> falst;
      Integer n;
      Boolean success;

    case (DAE.CALL(path=path,expLst=expl,attr=DAE.CALL_ATTR(tuple_=b,builtin=c,isImpure=isImpure,ty=ty,tailCall=tc)), _, _, _, _)
      equation
        // get function mapper
        //print("Search for function mapper\n");
        (mapper, tp) = getFunctionMapper(path, inFunctionTree);
        (dpath, blst) = differentiateFunction1(path,mapper, tp, expl, (inDiffwrtCref, inInputData, inDiffType, inFunctionTree));
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAE.AvlTreePathFunction.get(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (true,_) = checkDerivativeFunctionInputs(blst, tp, dtp);
        (expl1,_) = List.splitOnBoolList(expl, blst);
        (dexpl, functions) = List.map3Fold(expl1, function differentiateExp(maxIter=maxIter), inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        funcname = BackendUtil.modelicaStringToCStr(AbsynUtil.pathString(path), false);
        diffFuncData = BackendDAE.emptyInputData;
         diffFuncData.matrixName = SOME(funcname);
        (dexplZero, functions) = List.map3Fold(expl1, function differentiateExp(maxIter=maxIter), DAE.CREF_IDENT("$",DAE.T_REAL_DEFAULT,{}), diffFuncData, BackendDAE.GENERIC_GRADIENT(), functions);
        // debug dump
        if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
          print("### differentiated argument list:\n");
          print("Diffed ExpList: \n");
          print(stringDelimitList(List.map(dexpl, ExpressionDump.printExpStr), ", ") + "\n");
        end if;
        e = DAE.CALL(dpath,expl1,DAE.CALL_ATTR(ty,b,c,isImpure,false,dinl,tc));
        e = createPartialArguments(ty, dexpl, dexplZero, expl, e);
      then
        (e,functions);

    case (DAE.CALL(path=path,expLst=expl), _, _, _, _)
      equation
        // get function mapper
        //print("Search for function mapper2\n");
        (mapper, tp) = getFunctionMapper(path, inFunctionTree);
        (dpath, blst) = differentiateFunction1(path, mapper, tp, expl, (inDiffwrtCref, inInputData, inDiffType, inFunctionTree));
        SOME(DAE.FUNCTION(type_=dtp)) = DAE.AvlTreePathFunction.get(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (false, tlst) = checkDerivativeFunctionInputs(blst, tp, dtp);
        // add Warning
        typlststring = List.map(tlst, Types.unparseType);
        typstring = "\n" + stringDelimitList(typlststring,";\n");
        dastring = AbsynUtil.pathString(dpath);
        print("Input warnings for function mapper2\n");
        Error.addMessage(Error.UNEXPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});
      then
        fail();

    // differentiate function
    case (e as DAE.CALL(path=path,expLst=expl,attr=DAE.CALL_ATTR(tuple_=b,builtin=false,isImpure=isImpure,ty=ty,tailCall=tc)), _, _, _, _)
      equation
        // TODO: FIXIT! expressionSolve and analyticJacobian don't
        // return  new functionTree, so we can't differentiate functions then.
        failure(BackendDAE.SIMPLE_DIFFERENTIATION() = inDiffType);
        failure(BackendDAE.DIFF_FULL_JACOBIAN() = inDiffType);

        // get algorithm of the function
        SOME(func) = DAE.AvlTreePathFunction.get(inFunctionTree,path);

        //catch recursive functions call
        if not AvlSetPath.hasKey(inInputData.diffedFunctions, path) then

          // add function to diffed functions set
          inInputData.diffedFunctions = AvlSetPath.add(inInputData.diffedFunctions, path);
          // differentiate function
          (dfunc, functions, blst) = differentiatePartialFunction(func, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);

          dpath = DAEUtil.functionName(dfunc);
          DAE.T_FUNCTION(funcResultType = dtp) = DAEUtil.getFunctionType(dfunc);

          // debug
          if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
            funstring = Tpl.tplString(DAEDumpTpl.dumpFunction, dfunc);
            print("### Differentiate function: \n" + funstring + "\n\n");
          end if;

          functions = DAEUtil.addDaeFunction({dfunc}, functions);
          // add differentiated function as function mapper
          func = DAEUtil.addFunctionDefinition(func, DAE.FUNCTION_DER_MAPPER(path, dpath, 1, {}, NONE(), {}));
          functions = DAE.AvlTreePathFunction.add(functions, path, SOME(func));
        else
          (functions, inputVarsDer, _, outputVarsDer, _, blst) = getFunctionInOutVars(func, inFunctionTree, inDiffwrtCref, maxIter);
          (dpath, dtp) = getDiffedTypeandName(func, inputVarsDer, outputVarsDer, blst);
          DAE.T_FUNCTION(funcResultType = dtp) = dtp;
        end if;

        // debug
        // differentiate expl
        if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
          print("### Detailed arguments list: \n");
          print(stringDelimitList(List.map(expl, ExpressionDump.printExpStr), ", ") + "\n");
          print("### and argument types: \n");
          print(stringDelimitList(List.mapMap(expl, Expression.typeof, Types.printTypeStr), " | ") + "\n");
          print("### and output type: \n"  + Types.printTypeStr(dtp) + "\n");
        end if;

        // create differentiated call arguments
        expBoolLst = List.threadTuple(expl, blst);
        expBoolLst = List.filterOnTrue(expBoolLst, Util.tuple22);
        expl1 = List.map(expBoolLst, Util.tuple21);
        if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
          print("### Selected Arguments: \n");
          print(stringDelimitList(List.map(expl1, ExpressionDump.printExpStr), ", ") + "\n");
        end if;

        (dexpl, functions) = List.map3Fold(expl1, function differentiateExp(maxIter=maxIter), inDiffwrtCref, inInputData, inDiffType, functions);
        if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
          print("### Diffed ExpList: \n");
          print(stringDelimitList(List.map(dexpl, ExpressionDump.printExpStr), ", ") + "\n");
        end if;

        // try to create zero expression to fill up the arguments, if it fails use the total differentiation
        (dexplZero, functions, success) = tryZeroDiff(expl1, functions, maxIter);
        if success then
          e = DAE.CALL(dpath,dexpl,DAE.CALL_ATTR(dtp,b,false,isImpure,false,DAE.NO_INLINE(),tc));
          exp = createPartialArguments(ty, dexpl, dexplZero, expl, e);
        else
          exp = DAE.CALL(dpath,listAppend(expl,dexpl),DAE.CALL_ATTR(dtp,b,false,isImpure,false,DAE.NO_INLINE(),tc));
        end if;

        if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
          print("### differentiated result CALL :\n");
          print(ExpressionDump.printExpStr(exp) + "\n");
        end if;
      then
        (exp, functions);

      else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = "Differentiate.differentiateFunctionCallPartial failed for " + ExpressionDump.printExpStr(inExp) + "\n";
        Debug.trace(str);
      then fail();
  end matchcontinue;
end differentiateFunctionCallPartial;

function addFunctionConstantsAndParameters
  input output Option<BackendDAE.Variables> knownVars_opt;
  input DAE.Function func;
algorithm
  knownVars_opt := match func
    local
      list<DAE.Element> body;
      Option<BackendDAE.Var> var_opt;
      list<BackendDAE.Var> body_knowns = {};

    case DAE.FUNCTION(functions = DAE.FUNCTION_DEF(body = body)::_)
      algorithm
        for element in body loop
          var_opt := BackendDAECreate.lowerKnownVarSingle(element);
          if isSome(var_opt) then
            body_knowns := Util.getOption(var_opt) :: body_knowns;
          end if;
        end for;
        if listEmpty(body_knowns) then
          // basically do nothing, just for visualization
          knownVars_opt := knownVars_opt;
        elseif isSome(knownVars_opt) then
          // add to current variable vector
          knownVars_opt := SOME(BackendVariable.addVars(body_knowns, Util.getOption(knownVars_opt)));
        else
          // create new variable vector
          knownVars_opt := SOME(BackendVariable.listVar(body_knowns));
        end if;
    then knownVars_opt;

    else knownVars_opt;
  end match;
end addFunctionConstantsAndParameters;

function tryZeroDiff
  input output list<DAE.Exp> explist;
  input output DAE.FunctionTree functions;
  input Integer maxIter;
  output Boolean success;
algorithm
  try
   (explist, functions) := List.map3Fold(explist, function differentiateExp(maxIter=maxIter), DAE.CREF_IDENT("$",DAE.T_REAL_DEFAULT,{}), BackendDAE.emptyInputData, BackendDAE.GENERIC_GRADIENT(), functions);
   success := true;
  else
   explist := {};
   success := false;
  end try;
end tryZeroDiff;

protected function createPartialArguments
  input DAE.Type outputType;
  input list<DAE.Exp> inArgs;
  input list<DAE.Exp> inDiffedArgs;
  input list<DAE.Exp> inOrginalExpl;
  input DAE.Exp inCall;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(outputType, inCall)
    local
      Absyn.Path path, rPath;
      DAE.CallAttributes attr;
      list<DAE.Exp> expLst;
      DAE.Exp ezero, e;
      DAE.Dimensions dims;
      list<DAE.Type> tys;
      list<DAE.Var> varLst;
      list<String> varNames;

    case (DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path=rPath),varLst=varLst), DAE.CALL(path=path, attr=attr))
    equation
      tys = list(DAEUtil.varType(v) for v in varLst);
      varNames = list(DAEUtil.typeVarIdent(v) for v in varLst);
      expLst = createPartialArgumentsRecord(tys, varNames, inArgs, inDiffedArgs, inOrginalExpl, inCall);
    then DAE.RECORD(rPath, expLst, varNames, outputType);

    case (DAE.T_COMPLEX(complexClassType=ClassInf.RECORD()), DAE.TSUB(exp=DAE.CALL(path=path, attr=attr)))
    then DAE.CALL(path, listAppend(inOrginalExpl,inArgs), attr);

    case (DAE.T_TUPLE(types = tys), _) equation
      expLst = createPartialArgumentsTuple(tys, inArgs, inDiffedArgs, inOrginalExpl, inCall);
    then DAE.TUPLE(expLst);

    case (_, _)
    equation
      dims = Expression.arrayDimension(outputType);
      (ezero,_) = Expression.makeZeroExpression(dims);
      e = createPartialDifferentiatedExp(inArgs, inDiffedArgs, inOrginalExpl, inCall, 1, ezero);
    then e;

    //else case as fallback create total differentiation call
    case (_, DAE.CALL(path=path, attr=attr))
    then DAE.CALL(path, listAppend(inOrginalExpl,inArgs), attr);

  end matchcontinue;
end createPartialArguments;

protected function createPartialArgumentsTuple
  input list<DAE.Type> inTypesLst;
  input list<DAE.Exp> inArgs;
  input list<DAE.Exp> inDiffedArgs;
  input list<DAE.Exp> inOrginalExpl;
  input DAE.Exp inCall;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := list( createPartialArguments(
                                             tp, inArgs, inDiffedArgs, inOrginalExpl, (DAE.TSUB(inCall, number, tp))
                                           )
                     threaded  for tp in inTypesLst, number  in 1:listLength(inTypesLst));
end createPartialArgumentsTuple;

protected function createPartialArgumentsRecord
  input list<DAE.Type> inTypesLst;
  input list<DAE.String> inVarNames;
  input list<DAE.Exp> inArgs;
  input list<DAE.Exp> inDiffedArgs;
  input list<DAE.Exp> inOrginalExpl;
  input DAE.Exp inCall;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := list( createPartialArguments(tp, inArgs, inDiffedArgs, inOrginalExpl, (DAE.RSUB(inCall, -1, name, tp)) )
                     threaded  for tp in inTypesLst, name in inVarNames);
end createPartialArgumentsRecord;

protected function createPartialDifferentiatedExp
  "Generates an expression with a sum partial derivatives."
  input list<DAE.Exp> inDiffExpl;
  input list<DAE.Exp> inDiffExplZero;
  input list<DAE.Exp> inOrginalExpl;
  input DAE.Exp inCall;
  input Integer currentLstElement;
  input DAE.Exp inAccum;
  output DAE.Exp outExp = inAccum;
protected
  Integer i = currentLstElement;
algorithm
for de in inDiffExpl loop
  outExp := match(de, inCall)
    local
      DAE.Exp e,  eone, eArray;
      list<DAE.Exp> rest;
      list<list<DAE.Exp>> arrayArgs;
      list<DAE.Exp> expl, expLst, dexpLst;
      DAE.Type tp;
      DAE.Dimensions dims;
      Boolean b;
      Absyn.Path path;
      DAE.CallAttributes attr;

    case (_, DAE.CALL(path=path, attr=attr))
    guard(Types.isRecord(Expression.typeof(de)))
      equation
      dexpLst = List.set(inDiffExplZero, i, de);
      expLst = listAppend(inOrginalExpl,dexpLst);
      e = DAE.CALL(path, expLst, attr);
    then e;

    case (DAE.ARRAY(ty = tp,scalar = b,array = expl), _) equation
      //print("createPartialDifferentiatedExp : i = " + intString(i) + "\n");
      eArray = listGet(inDiffExplZero, i);
      dexpLst = Expression.arrayElements(eArray);
      arrayArgs = prepareArgumentsExplArray(expl, dexpLst, 1, {});
      expLst = List.map2(arrayArgs, Expression.makeArray, tp, b);
      arrayArgs = List.map2r(expLst, List.set, inDiffExplZero, i);
      arrayArgs = List.map1r(arrayArgs, listAppend, inOrginalExpl);
      e = createPartialSum(arrayArgs, expl, inCall, outExp);
    then e;

    else
     equation
      tp = Expression.typeof(de);
      dims = Expression.arrayDimension(tp);
      (eone,_) = Expression.makeOneExpression(dims);
      dexpLst = List.set(inDiffExplZero, i, eone);
      expLst = listAppend(inOrginalExpl,dexpLst);
      e = createPartialSum({expLst}, {de}, inCall, outExp);
    then e;
  end match;
  i := i + 1;
end for;
end createPartialDifferentiatedExp;

protected function createPartialSum
  "Generates an expression with a sum partial derivatives"
  input list<list<DAE.Exp>> inArgsLst;
  input list<DAE.Exp> inDiff;
  input DAE.Exp inCall;
  input DAE.Exp inAccum;
  output DAE.Exp outExp = inAccum;
protected
   list<DAE.Exp> restDiff = inDiff;
   DAE.Exp de, res;
algorithm
  for expLst in inArgsLst loop
    de::restDiff := restDiff;

    // skip for zero differentiation
    if not Expression.isZero(de) then
      res := match(inCall)
       local
         Absyn.Path path;
         DAE.CallAttributes attr;
         DAE.Type ty;
         Integer ix;
         String name;

      case DAE.RSUB(exp=DAE.CALL(path=path, attr=attr), ix=ix, fieldName=name, ty=ty)
        then DAE.RSUB(DAE.CALL(path, expLst, attr), ix, name, ty);

      case DAE.TSUB(exp=DAE.CALL(path=path, attr=attr), ix=ix, ty=ty)
        then DAE.TSUB(DAE.CALL(path, expLst, attr), ix, ty);

      case DAE.CALL(path=path, attr=attr) equation
        then DAE.CALL(path, expLst, attr);
      end match;

      res := Expression.expMul(de, res);
      outExp := Expression.expAdd(outExp, res);

    end if;
  end for;

end createPartialSum;

protected function prepareArgumentsExplArray
  "Generate an expression with a sum partial derivatives"
  input list<DAE.Exp> inWorkLst;
  input list<DAE.Exp> inArgs;
  input Integer inCurrentArg;
  input list<list<DAE.Exp>> inAccum;
  output list<list<DAE.Exp>> outExpLstLst;
algorithm
  outExpLstLst := match(inWorkLst, inArgs, inCurrentArg, inAccum)
    local
      list<DAE.Exp> rest, args;
      DAE.Exp e, eone;
      DAE.Type tp;
      DAE.Dimensions dims;

    case ({}, _, _, _)
    then listReverse(inAccum);

    case (e::rest, _, _, _) equation
      tp = Expression.typeof(e);
      dims = Expression.arrayDimension(tp);
      (eone,_) = Expression.makeOneExpression(dims);
      args = List.set(inArgs, inCurrentArg, eone);
    then prepareArgumentsExplArray(rest, inArgs, inCurrentArg+1, args::inAccum);
  end match;
end prepareArgumentsExplArray;

protected function differentiatePartialFunction "Author: wbraun"
  input DAE.Function inFunction;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input Integer maxIter;
  output DAE.Function outDerFunction;
  output DAE.FunctionTree outFunctionTree;
  output list<Boolean> outBooleanlst;
algorithm
  (outDerFunction, outFunctionTree, outBooleanlst) := matchcontinue(inFunction, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local
      BackendDAE.DifferentiateInputData inputData, diffFuncData;

      Absyn.Path path, dpath;
      Option<Absyn.Path> dpathOption;
      Boolean isImpure;
      DAE.InlineType dinl;
      DAE.FunctionTree functions;
      DAE.Type dtp, outdtp;
      String  str;

      list<DAE.Element> funcbody, funcbodyDer;
      list<DAE.Element> inputVars, inputVarsNoDer, inputVarsDer;
      list<DAE.Element> outputVars, outputVarsNoDer, outputVarsDer;
      list<DAE.Element> protectedVars, protectedVarsNoDer, protectedVarsDer, newProtectedVars;
      list<DAE.Statement> bodyStmts, derbodyStmts;

      DAE.Function func,dfunc;

      String funcname, funstring;
      DAE.ComponentRef diffwrtCref;
      list<DAE.ComponentRef> diffwrtCrefs;
      list<Boolean> blst;
      SCode.Visibility visibility;

    // differentiate function
    case (func, _, _, _, _) equation
      // debug
      if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
        funstring = Tpl.tplString(DAEDumpTpl.dumpFunction, func);
        print("### Differentiate differentiateFunctionCallPartial: \n" + funstring + "\n\n");
      end if;

      inputVars = DAEUtil.getFunctionInputVars(func);
      outputVars =  DAEUtil.getFunctionOutputVars(func);
      protectedVars  = DAEUtil.getFunctionProtectedVars(func);
      bodyStmts = DAEUtil.getFunctionAlgorithmStmts(func);
      visibility = DAEUtil.getFunctionVisibility(func);

      (functions, inputVarsDer, inputVarsNoDer, outputVarsDer, outputVarsNoDer, blst) = getFunctionInOutVars(func, inFunctionTree, inDiffwrtCref, maxIter);

      // prepare diffData
      path = DAEUtil.functionName(func);
      funcname = BackendUtil.modelicaStringToCStr(AbsynUtil.pathString(path), false);
      diffFuncData = BackendDAE.emptyInputData;
      diffFuncData.matrixName = SOME(funcname);
      diffFuncData.diffedFunctions = inInputData.diffedFunctions;

      //add protected variables to dependent Vars
      (inputData,_) = addElementVars2Dep(inputVarsNoDer, functions, diffFuncData);
      (inputData,_) = addElementVars2Dep(outputVarsNoDer, functions, inputData);

      (protectedVarsDer, functions, protectedVarsNoDer, _) = differentiateElementVars(protectedVars, inDiffwrtCref, inputData, BackendDAE.DIFFERENTIATION_FUNCTION(), functions, {}, {}, {}, maxIter, false);

      //add protected variables to dependent Vars
      (inputData,_) = addElementVars2Dep(protectedVarsNoDer, functions, inputData);

      if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
        dumpInputData(inputData);
      end if;

      inputData.knownVars = addFunctionConstantsAndParameters(inputData.knownVars, func);

      // differentiate algorithm statemeants
      //print("Function diff: statemeants");
      (derbodyStmts, functions) = differentiateStatements(listReverse(bodyStmts), inDiffwrtCref, inputData, BackendDAE.DIFFERENTIATION_FUNCTION(), {}, functions, maxIter);

      if Flags.isSet(Flags.DEBUG_DIFFERENTIATION_VERBOSE) then
        funstring = DAEDump.ppStmtListStr(derbodyStmts, 0);
        print("### Differentiate differentiateFunctionCallPartial stmts: \n" + funstring + "\n\n");
      end if;

      // create function and add it to function tree
      (dpath, dtp) = getDiffedTypeandName(func, inputVarsDer, outputVarsDer, blst);

      //change output vars to protected vars and direction bidir
      newProtectedVars = List.map1(outputVars, DAEUtil.setElementVarVisibility, DAE.PROTECTED());
      newProtectedVars = List.map1(newProtectedVars, DAEUtil.setElementVarDirection, DAE.BIDIR());

      funcbodyDer = listAppend(newProtectedVars, {DAE.ALGORITHM(DAE.ALGORITHM_STMTS(derbodyStmts), DAE.emptyElementSource)});
      funcbodyDer = listAppend(protectedVarsDer, funcbodyDer);
      funcbodyDer = listAppend(protectedVars, funcbodyDer);
      funcbodyDer = listAppend(outputVarsDer, funcbodyDer);
      funcbodyDer = listAppend(inputVarsDer, funcbodyDer);
      funcbodyDer = listAppend(inputVars, funcbodyDer);

      isImpure = DAEUtil.getFunctionImpureAttribute(func);
      dinl = DAEUtil.getFunctionInlineType(func);
      dfunc = DAE.FUNCTION(dpath, {DAE.FUNCTION_DEF(funcbodyDer)}, dtp, visibility, false, isImpure, dinl, {}, DAE.emptyElementSource, NONE());
    then (dfunc, functions, blst);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        path = DAEUtil.functionName(inFunction);
        str = "\nDifferentiate.differentiatePartialFunction failed for function: " + AbsynUtil.pathString(path) + "\n";
        Debug.trace(str);
      then fail();
  end matchcontinue;
end differentiatePartialFunction;

protected function getDiffedTypeandName
  input DAE.Function inFunction;
  input list<DAE.Element> inputVarsDer;
  input list<DAE.Element> outputVarsDer;
  input list<Boolean> blst;
  output Absyn.Path diffedName;
  output DAE.Type diffedType;
algorithm
  diffedType := Types.extendsFunctionTypeArgs(DAEUtil.getFunctionType(inFunction), inputVarsDer, outputVarsDer, blst);
  diffedName := AbsynUtil.stringPath("$DER" + BackendUtil.modelicaStringToCStr(AbsynUtil.pathString(DAEUtil.functionName(inFunction)), false));
end getDiffedTypeandName;

protected function getFunctionInOutVars
  input DAE.Function inFunction;
  input DAE.FunctionTree inFunctionTree;
  input DAE.ComponentRef inDiffwrtCref;
  input Integer maxIter;
  output DAE.FunctionTree functions = inFunctionTree;
  output list<DAE.Element> inputVarsDer;
  output list<DAE.Element> inputVarsNoDer;
  output list<DAE.Element> outputVarsDer;
  output list<DAE.Element> outputVarsNoDer;
  output list<Boolean> blst;
protected
  list<DAE.Element> inputVars, outputVars;
  BackendDAE.DifferentiateInputData diffData;
algorithm
  inputVars := DAEUtil.getFunctionInputVars(inFunction);
  outputVars := DAEUtil.getFunctionOutputVars(inFunction);
  diffData := BackendDAE.emptyInputData;
  diffData.matrixName := SOME(BackendUtil.modelicaStringToCStr(AbsynUtil.pathString(DAEUtil.functionName(inFunction)), false));

  (inputVarsDer, functions, inputVarsNoDer, blst) := differentiateElementVars(inputVars, inDiffwrtCref, diffData, BackendDAE.DIFFERENTIATION_FUNCTION(), functions, {}, {}, {}, maxIter, true);
  (outputVarsDer, functions, outputVarsNoDer, _) := differentiateElementVars(outputVars, inDiffwrtCref, diffData, BackendDAE.DIFFERENTIATION_FUNCTION(), functions, {}, {}, {}, maxIter, false);
end getFunctionInOutVars;

protected function differentiateElementVars
  input list<DAE.Element> inElements;   // in as DAE.VAR(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input list<DAE.Element>  inElementsDer;
  input list<DAE.Element>  inElementsNoDer;
  input list<Boolean>  inBooleanLst;
  input Integer maxIter;
  input Boolean elementListInputs; // filter discrete variables out for inputs
  output list<DAE.Element>  outElements;
  output DAE.FunctionTree outFunctionTree;
  output list<DAE.Element>  outElementsNoDer;
  output list<Boolean>  outBooleanLst;
algorithm
  (outElements, outFunctionTree, outElementsNoDer, outBooleanLst) := matchcontinue(inElements, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, inElementsDer, inElementsNoDer, inBooleanLst)
  local
    BackendDAE.Variables timevars;
    list<DAE.Element> rest, vars, newVars, elementsNoDer;
    DAE.Element var, var1;
    DAE.ComponentRef cref, dcref;
    list<DAE.ComponentRef> crefLst;
    DAE.Exp e;
    DAE.FunctionTree functions;
    DAE.Type tp;
    list<DAE.Type> tpLst;
    DAE.Exp binding, dbinding;
    list<DAE.Var> varLst;
    list<Boolean> blst;
    String matrixName;

    case ({}, _, _, _, _, _, _, _)
    then (MetaModelica.Dangerous.listReverseInPlace(inElementsDer), inFunctionTree, MetaModelica.Dangerous.listReverseInPlace(inElementsNoDer), MetaModelica.Dangerous.listReverseInPlace(inBooleanLst));

    case ((var1 as DAE.VAR(componentRef = cref, ty= (DAE.T_COMPLEX(complexClassType=ClassInf.RECORD())),  binding=SOME(binding)))::rest, _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), _, _, _, _, _) equation
      dcref = createDiffedCrefName(cref, matrixName);
      var = DAEUtil.replaceCrefInVar(dcref, var1);
      (dbinding,_) = differentiateExp(binding, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      var = DAEUtil.replaceBindungInVar(dbinding, var);
      vars = var::inElementsDer;
      blst = true::inBooleanLst;
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, vars, inElementsNoDer, blst, maxIter, elementListInputs);
    then (vars, functions, elementsNoDer, blst);

    case ((var1 as DAE.VAR(componentRef = cref, ty= (DAE.T_COMPLEX(complexClassType=ClassInf.RECORD()))))::rest, _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), _, _, _, _, _) equation
      dcref = createDiffedCrefName(cref, matrixName);
      var = DAEUtil.replaceCrefInVar(dcref, var1);

      //crefLst = List.map1(varLst,Expression.generateCrefsFromExpVar,dcref);
      //tpLst = List.map(varLst,Types.getVarType);
      //newVars = List.threadMap1(crefLst, tpLst, DAEUtil.replaceCrefandTypeInVar, var);
      //elementsNoDer = List.append_reverse(newVars,inElementsNoDer);

      vars = var::inElementsDer;
      blst = true::inBooleanLst;
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, vars, inElementsNoDer, blst, maxIter, elementListInputs);
    then (vars, functions, elementsNoDer, blst);

    case((var as DAE.VAR(binding=SOME(binding)))::rest, _, BackendDAE.DIFFINPUTDATA(independenentVars=SOME(timevars)), _, _, _, _, _) equation
      // check if bindung depends on independentVars
      crefLst = Expression.extractCrefsFromExp(binding);
      ({},{}) = BackendVariable.getVarLst(crefLst, timevars);

      vars = var::inElementsNoDer;
      blst = false::inBooleanLst;
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, inElementsDer, vars, blst, maxIter, elementListInputs);
    then (vars, functions, elementsNoDer, blst);

    case((var1 as DAE.VAR(componentRef = cref, ty=tp, binding=SOME(binding)))::rest, _, _, _, _, _, _, _) equation
      if elementListInputs then
        true = Types.isRealOrSubTypeReal(tp);
      end if;
      e = Expression.crefExp(cref);
      (e, functions) = differentiateCrefs(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      dcref = Expression.expCref(e);
      var = DAEUtil.replaceCrefInVar(dcref, var1);
      (dbinding, functions) = differentiateExp(binding, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      var = DAEUtil.replaceBindungInVar(dbinding, var);
      vars = var::inElementsDer;
      blst = true::inBooleanLst;
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, functions, vars, inElementsNoDer, blst, maxIter, elementListInputs);
    then (vars, functions, elementsNoDer, blst);

    case((var1 as DAE.VAR(componentRef = cref, ty=tp))::rest, _, _, _, _, _, _, _) equation
      if elementListInputs then
        true = Types.isRealOrSubTypeReal(tp);
      end if;
      e = Expression.crefExp(cref);
      (e, functions) = differentiateCrefs(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, maxIter);
      dcref = Expression.expCref(e);
      var = DAEUtil.replaceCrefInVar(dcref, var1);
      vars = var::inElementsDer;
      blst = true::inBooleanLst;
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, functions, vars, inElementsNoDer, blst, maxIter, elementListInputs);
    then (vars, functions, elementsNoDer, blst);

    case((var as DAE.VAR())::rest, _, _, _, _, _, _, _) equation
      elementsNoDer = var::inElementsNoDer;
      blst = false::inBooleanLst;
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, inElementsDer, elementsNoDer, blst, maxIter, elementListInputs);
    then (vars, functions, elementsNoDer, blst);
  end matchcontinue;
end differentiateElementVars;

protected function differentiateFunction1 "Author: Frenkel TUD"
  input Absyn.Path inFuncName;
  input DAE.FunctionDefinition inMapper;
  input DAE.Type inTp;
  input list<DAE.Exp> expl;
  input BackendDAE.DifferentiateInputArguments inDiffArgs;
  output Absyn.Path outFuncName;
  output list<Boolean> blst;
algorithm
  (outFuncName,blst) := matchcontinue (inFuncName,inMapper,inTp,expl,inDiffArgs)
    local
      BackendDAE.Variables timevars;
      DAE.FunctionTree functions;
      Absyn.Path default,fname,da,inDFuncName;
      list<tuple<Integer,DAE.derivativeCond>> cr;
      Integer derivativeOrder;
      list<DAE.FuncArg> funcArg;
      list<DAE.Type> tplst;
      list<Boolean> bl;
      list<Absyn.Path> lowerOrderDerivatives;
      DAE.FunctionDefinition mapper;
      DAE.Type tp;
      array<Boolean> ba;

    // check conditions, order=1
    case (_,DAE.FUNCTION_DER_MAPPER(derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr),DAE.T_FUNCTION(funcArg=funcArg),_,_)
      guard intEq(1,derivativeOrder)
      equation
         tplst = List.map(funcArg,Types.funcArgType);
         ba = Array.mapList(tplst, diffableTypes);
         bl = checkDerFunctionConds(ba,cr,expl,inDiffArgs);
      then
        (inDFuncName,bl);
    // check conditions, order>1
    case (_,DAE.FUNCTION_DER_MAPPER(derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr),tp,_,(_,_,_,functions))
      guard not intEq(1,derivativeOrder)
      equation
         // get n-1 func name
         fname = getlowerOrderDerivative(inFuncName,functions);
         // get mapper
         (mapper,tp) = getFunctionMapper(fname,functions);
         // get bool list
         (_,blst) = differentiateFunction1(fname,mapper,tp,expl,inDiffArgs);
         // count true
         (bl,_) = List.split1OnTrue(blst, valueEq, true);
         ba = arrayAppend(arrayCreate(listLength(blst), false), listArray(bl));
         bl = checkDerFunctionConds(ba,cr,expl,inDiffArgs);
      then
        (inDFuncName,bl);
    // conditions failed use default
    case (_,DAE.FUNCTION_DER_MAPPER(derivedFunction=fname,derivativeOrder=derivativeOrder,defaultDerivative=SOME(default),lowerOrderDerivatives=lowerOrderDerivatives),tp,_,_)
      equation
          (da,bl) = differentiateFunction1(inFuncName,DAE.FUNCTION_DER_MAPPER(fname,default,derivativeOrder,{},SOME(default),lowerOrderDerivatives),tp,expl,inDiffArgs);
      then
        (da,bl);
  end matchcontinue;
end differentiateFunction1;

protected function checkDerivativeFunctionInputs "Author: Frenkel TUD"
  input list<Boolean> blst;
  input DAE.Type tp;
  input DAE.Type dtp;
  output Boolean outBoolean;
  output list<DAE.Type> outExpectedTypeLst;
algorithm
  (outBoolean,outExpectedTypeLst) := matchcontinue(blst,tp,dtp)
    local
      list<DAE.FuncArg> falst,falst1,falst2,dfalst;
      list<DAE.Type> tlst,dtlst;
      Boolean ret;
      list<String> typlststring;

    case (_,DAE.T_FUNCTION(funcArg=falst),DAE.T_FUNCTION(funcArg=dfalst)) equation
      // generate expected function inputs
      (falst1,_) = List.splitOnBoolList(falst,blst);
      falst2 = listAppend(falst,falst1);
      // compare with derivative function inputs
      tlst = List.map(falst2,Types.funcArgType);
      dtlst = List.map(dfalst,Types.funcArgType);
      ret = List.isEqualOnTrue(tlst,dtlst,Types.equivtypes);
    then (ret,tlst);

    case (_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-Differentiate.checkDerivativeFunctionInputs failed\n");
      then fail();
  end matchcontinue;
end checkDerivativeFunctionInputs;

protected function checkDerFunctionConds "Author: Frenkel TUD"
  input array<Boolean> inbarr;
  input list<tuple<Integer,DAE.derivativeCond>> icrlst;
  input list<DAE.Exp> expl;
  input BackendDAE.DifferentiateInputArguments inDiffArgs;
  output list<Boolean> outblst;
protected
  Integer i;
  DAE.derivativeCond dc;
  DAE.Exp e;
  Absyn.Path p1, p2;
  array<Boolean> ba = inbarr;
  DAE.ComponentRef diffwrtCref;
  BackendDAE.DifferentiateInputData inputData;
  BackendDAE.DifferentiationType diffType;
  DAE.FunctionTree functionTree;
algorithm
  (diffwrtCref, inputData, diffType, functionTree) := inDiffArgs;

  for tpl in icrlst loop
    (i, dc) := tpl;

    _ := matchcontinue(dc)
      // Zero derivative, check that it's actually zero.
      case DAE.ZERO_DERIVATIVE()
        algorithm
          // Get expression.
          e := listGet(expl, i);
          // Differentiate exp.
          (e, functionTree) := differentiateExp(e, diffwrtCref, inputData, diffType, functionTree, defaultMaxIter);
          true := Expression.isZero(e);
        then
          ();

      case DAE.NO_DERIVATIVE(binding = DAE.CALL(path = p1))
        algorithm
          // Get expression.
          DAE.CALL(path = p2) := listGet(expl, i);
          true := AbsynUtil.pathEqual(p1, p2);
        then
          ();

      case DAE.NO_DERIVATIVE(binding = DAE.ICONST()) then ();

      else
        algorithm
          true := Flags.isSet(Flags.FAILTRACE);
          Debug.traceln("-Differentiate.checkDerFunctionConds failed");
        then
          fail();

    end matchcontinue;

    // Remove input from array.
    arrayUpdate(ba, i, false);
  end for;

  outblst := arrayList(ba);
end checkDerFunctionConds;

protected function getlowerOrderDerivative "Author: Frenkel TUD"
  input Absyn.Path fname;
  input DAE.FunctionTree functions;
  output Absyn.Path outFName;
algorithm
  outFName := match(fname,functions)
    local
      list<DAE.FunctionDefinition> flst;
      list<Absyn.Path> lowerOrderDerivatives;
      Absyn.Path name;
    case(_,_)
      equation
          SOME(DAE.FUNCTION(functions=flst)) = DAE.AvlTreePathFunction.get(functions,fname);
          DAE.FUNCTION_DER_MAPPER(lowerOrderDerivatives=lowerOrderDerivatives) = getFunctionMapper1(flst);
          name = List.last(lowerOrderDerivatives);
      then name;
  end match;
end getlowerOrderDerivative;

public function getFunctionMapper "Author: Frenkel TUD"
  input Absyn.Path fname;
  input DAE.FunctionTree functions;
  output DAE.FunctionDefinition mapper;
  output DAE.Type tp;
algorithm
  (mapper,tp) := matchcontinue(fname,functions)
    local
      list<DAE.FunctionDefinition> flst;
      DAE.Type t;
      DAE.FunctionDefinition m;
      String s;
    case(_,_)
      equation
        SOME(DAE.FUNCTION(functions=flst,type_=t)) = DAE.AvlTreePathFunction.get(functions,fname);
        m = getFunctionMapper1(flst);
      then (m,t);
    case (_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s = AbsynUtil.pathString(fname);
        s = stringAppend("-Differentiate.getFunctionMapper failed for function ",s);
        Debug.traceln(s);
      then
        fail();
  end matchcontinue;
end getFunctionMapper;

protected function getFunctionMapper1 "Author: Frenkel TUD"
  input list<DAE.FunctionDefinition> inFuncDefs;
  output DAE.FunctionDefinition mapper;
algorithm
  mapper := matchcontinue(inFuncDefs)
    local
      DAE.FunctionDefinition m;
      Absyn.Path p1;
      list<DAE.FunctionDefinition> funcDefs;

    case((m as DAE.FUNCTION_DER_MAPPER())::_) then m;
    case(_::funcDefs)
    equation
      m = getFunctionMapper1(funcDefs);
    then m;
    case (_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-Differentiate.getFunctionMapper1 failed\n");
      then
        fail();
  end matchcontinue;
end getFunctionMapper1;

protected function diffableTypes
    input DAE.Type inType;
  output Boolean out;
protected
  Boolean b[2];
algorithm
  b[1] := Types.isRealOrSubTypeReal(inType);
  b[2] := Types.isRecord(inType);
  out := boolOr(b[1],b[2]);
end diffableTypes;


//
// util functions for Types: DifferentiateInputData, DifferentiateInputArguments, DifferentiationType
//

protected function addDependentVars
  input list<BackendDAE.Var> inVarsLst;
  input BackendDAE.DifferentiateInputData inDiffData;
  output BackendDAE.DifferentiateInputData outDiffData = inDiffData;
protected
  BackendDAE.Variables depVars;
algorithm
  if isSome(outDiffData.dependenentVars) then
    depVars := BackendVariable.addVars(inVarsLst, Util.getOption(outDiffData.dependenentVars));
  else
    depVars := BackendVariable.listVar(inVarsLst);
  end if;
  outDiffData.dependenentVars := SOME(depVars);
end addDependentVars;

protected function addAllVars
  input list<BackendDAE.Var> inVarsLst;
  input BackendDAE.DifferentiateInputData inDiffData;
  output BackendDAE.DifferentiateInputData outDiffData = inDiffData;
protected
  BackendDAE.Variables allVars;
algorithm
  if isSome(outDiffData.allVars) then
    allVars := BackendVariable.addVars(inVarsLst, Util.getOption(outDiffData.allVars));
  else
    allVars := BackendVariable.listVar(inVarsLst);
  end if;
  outDiffData.allVars := SOME(allVars);
end addAllVars;

protected function addGlobalVars
  input list<BackendDAE.Var> inVarsLst;
  input BackendDAE.DifferentiateInputData inDiffData;
  output BackendDAE.DifferentiateInputData outDiffData = inDiffData;
protected
  BackendDAE.Variables glVars;
algorithm
  if isSome(outDiffData.knownVars) then
    glVars := BackendVariable.addVars(inVarsLst, Util.getOption(outDiffData.knownVars));
  else
    glVars := BackendVariable.listVar(inVarsLst);
  end if;
  outDiffData.knownVars := SOME(glVars);
end addGlobalVars;

protected function lowerVarsElementVars
  input list<DAE.Element> inElementLstVars;
  input DAE.FunctionTree functions;
  output list< BackendDAE.Var> varsLst;
  output list< BackendDAE.Equation> eqnsLst;
  output list< BackendDAE.Equation> reqnsLst;
protected
  list<BackendDAE.Var> vars, knvars, exvars;
algorithm
  try
    (vars, knvars, exvars, eqnsLst, reqnsLst) :=
      BackendDAECreate.lowerVars(inElementLstVars, functions);
    varsLst := listAppend(exvars, listAppend(vars, knvars));
  else
    true := Flags.isSet(Flags.FAILTRACE);
    Debug.traceln("- Differentiate.lowerVarsElementVars failed.");
  end try;
end lowerVarsElementVars;

protected function addElementVars2Dep
  input list<DAE.Element> inElementLstVars;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.DifferentiateInputData inDiffData;
  output BackendDAE.DifferentiateInputData outDiffData;
  output list< BackendDAE.Equation> outEqnsLst;
protected
  list<BackendDAE.Var> varsLst;
algorithm
  try
    (varsLst, outEqnsLst) := lowerVarsElementVars(inElementLstVars, inFunctions);
    outDiffData := addDependentVars(varsLst, inDiffData);
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"Differentiate.addElementVars2Dep failed"});
    fail();
  end try;
end addElementVars2Dep;

protected function dumpInputData
  input BackendDAE.DifferentiateInputData inDiffData;
protected
  Option<BackendDAE.Variables> independenentVars;
  Option<BackendDAE.Variables> dependenentVars;
  Option<BackendDAE.Variables> knownVars;
  Option<BackendDAE.Variables> allVars;
  list<BackendDAE.Var> controlVars;
  list<.DAE.ComponentRef> diffCrefs;
  Option<String> matrixName;
algorithm
   print("### dumpInputData ###\n");
   if isSome(inDiffData.matrixName) then
     print("### for " + Util.getOption(inDiffData.matrixName) +" ###\n");
   end if;
   if isSome(inDiffData.independenentVars) then
     print("independentVars:\n");
     BackendDump.printVariables(Util.getOption(inDiffData.independenentVars));
   end if;
   if isSome(inDiffData.dependenentVars) then
     print("dependenentVars:\n");
     BackendDump.printVariables(Util.getOption(inDiffData.dependenentVars));
   end if;
   if isSome(inDiffData.knownVars) then
     print("knownVars:\n");
     BackendDump.printVariables(Util.getOption(inDiffData.knownVars));
   end if;
   if isSome(inDiffData.allVars) then
     print("allVars:\n");
     BackendDump.printVariables(Util.getOption(inDiffData.allVars));
   end if;
   if not listEmpty(inDiffData.controlVars) then
     print("controlVars:\n");
     BackendDump.printVarList(inDiffData.controlVars);
   end if;
   if not listEmpty(inDiffData.diffCrefs) then
     print("diffCrefs:\n" + ComponentReference.printComponentRefListStr(inDiffData.diffCrefs) + "\n");
   end if;
end dumpInputData;

protected function isParamOrConstant
  input DAE.ComponentRef cref;
  input BackendDAE.DifferentiateInputData diffData;
  output Boolean b;
algorithm
  b := match diffData
    local
      BackendDAE.Variables knownVars;
      Option<list<BackendDAE.Var>> var_lst;
      BackendDAE.Var var;
    case BackendDAE.DIFFINPUTDATA(knownVars = SOME(knownVars)) algorithm
      var_lst := BackendVariable.getVarTryHard(cref, knownVars);
      if isSome(var_lst) then
        var :: _ := Util.getOption(var_lst);
        b := BackendVariable.isParamOrConstant(var);
      else
        b := false;
      end if;
    then b;
    else false;
  end match;
end isParamOrConstant;

annotation(__OpenModelica_Interface="backend");
end Differentiate;
