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

  RCS: $Id$

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
protected import Algorithm;
protected import Array;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import ClassInf;
protected import ComponentReference;
protected import DAEDump;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionDump;
protected import Flags;
protected import Inline;
protected import List;
protected import SCode;
protected import Util;


// =============================================================================
// differentiation interfaces
//  - differentiateEquationTime
//  - differentiateExpTime
//  - differentiateExpSolve
//
// =============================================================================

public function differentiateEquationTime "function: differentiateEquationTime
  Differentiates an equation with respect to the time variable."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Shared ishared;
  output BackendDAE.Equation outEquation;
  output BackendDAE.Shared oshared;
algorithm
  (outEquation, oshared) := matchcontinue(inEquation, inVariables, ishared)
  local
    String msg;
    DAE.ElementSource source;
    BackendDAE.Shared shared;
    BackendDAE.Equation deqn;
    DAE.FunctionTree funcs;
    BackendDAE.DifferentiateInputData diffData;
    BackendDAE.Variables knvars;
    case (_, _, _)
    equation
      funcs = BackendDAEUtil.getFunctions(ishared);
      knvars = BackendDAEUtil.getknvars(ishared);
      diffData = BackendDAE.DIFFINPUTDATA(NONE(), SOME(inVariables), SOME(knvars), SOME(inVariables), SOME({}), NONE(), NONE());
      (deqn, funcs) = differentiateEquation(inEquation, DAE.crefTime, diffData, BackendDAE.DIFFERENTIATION_TIME(), funcs);
      oshared = BackendDAEUtil.addFunctionTree(funcs, ishared);
      then (deqn, oshared);
    else
    equation
        msg = "\nDifferentiate.differentiateEquationTime failed for " + BackendDump.equationString(inEquation) + "\n\n";
        source = BackendEquation.equationSource(inEquation);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, DAEUtil.getElementSourceFileInfo(source));
      then fail();

  end matchcontinue;
end differentiateEquationTime;

public function differentiateExpTime "function: differentiateEquationTime
  Differentiates an equation with respect to the time variable."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Shared ishared;
  output DAE.Exp outExp;
  output BackendDAE.Shared oshared;
algorithm
  (outExp, oshared) := matchcontinue(inExp, inVariables, ishared)
  local
    String msg;
    BackendDAE.Shared shared;
    DAE.Exp dexp;
    DAE.FunctionTree funcs;
    BackendDAE.DifferentiateInputData diffData;
    BackendDAE.Variables knvars;
    case (_, _, _)
    equation
      funcs = BackendDAEUtil.getFunctions(ishared);
      knvars = BackendDAEUtil.getknvars(ishared);
      diffData = BackendDAE.DIFFINPUTDATA(NONE(), SOME(inVariables), SOME(knvars), SOME(inVariables), SOME({}), NONE(), NONE());
      (dexp, funcs) = differentiateExp(inExp, DAE.crefTime, diffData, BackendDAE.DIFFERENTIATION_TIME(), funcs);
      (dexp,_) = ExpressionSimplify.simplify(dexp);
      oshared = BackendDAEUtil.addFunctionTree(funcs, ishared);
      then (dexp, oshared);
    else
    equation
        // expandDerOperator expectes sometime that differentiate fails,
        // so the calling function need to take care of the error messages.
        // TODO: change that in expandDerOperator
        //Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, DAEUtil.getElementSourceFileInfo(DAE.emptyElementSource));

        true = Flags.isSet(Flags.FAILTRACE);
        msg = "\nDifferentiate.differentiateExpTime failed for " + ExpressionDump.printExpStr(inExp) + "\n\n";
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {msg});
      then fail();

  end matchcontinue;
end differentiateExpTime;

public function differentiateExpSolve
"function: differentiateEquationSolve
  Differentiates an equation with respect to the cref variable."
  input DAE.Exp inExp;
  input DAE.ComponentRef inCref;
  input Option<DAE.FunctionTree> functions;
  output DAE.Exp outExp;
protected
  list<DAE.Exp> fac = Expression.factors(inExp);
algorithm
  ({},_) := List.split1OnTrue(fac,Expression.expHasCrefInIf,inCref); // check: differentiateExpSolve is allowed
  outExp := matchcontinue(inExp, inCref)
    local
      String msg;
      DAE.Exp dexp;
      BackendDAE.DifferentiateInputData diffData;
      DAE.FunctionTree fun;

    case (_,_)
      equation
        fun = match(functions)
              local DAE.FunctionTree fun_;
              case(SOME(fun_)) then fun_;
              else DAE.emptyFuncTree;
              end match;
        diffData = BackendDAE.DIFFINPUTDATA(NONE(), NONE(), NONE(), NONE(), SOME({}), NONE(), NONE());
        (dexp, _) = differentiateExp(inExp, inCref, diffData, BackendDAE.SIMPLE_DIFFERENTIATION(), fun);
        (dexp,_) = ExpressionSimplify.simplify(dexp);
      then dexp;

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          msg = "\nDifferentiate.differentiateExpSolve failed for " + ExpressionDump.printExpStr(inExp) + "\n\n";
          Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {msg});
        end if;
      then fail();

  end matchcontinue;
end differentiateExpSolve;


public function differentiateExpCrefFullJacobian "function: differentiateEquationTime
  Differentiates an equation with respect to the time variable."
  input DAE.Exp inExp;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Shared ishared;
  output DAE.Exp outExp;
  output BackendDAE.Shared oshared;
algorithm
  (outExp, oshared) := matchcontinue(inExp, inCref, inVariables, ishared)
  local
    String msg;
    BackendDAE.Shared shared;
    DAE.Exp dexp;
    DAE.FunctionTree funcs;
    BackendDAE.DifferentiateInputData diffData;
    BackendDAE.Variables knvars;
    case (_, _, _, _)
    equation
      funcs = BackendDAEUtil.getFunctions(ishared);
      knvars = BackendDAEUtil.getknvars(ishared);
      diffData = BackendDAE.DIFFINPUTDATA(NONE(), SOME(inVariables), SOME(knvars), NONE(), SOME({}), NONE(), NONE());
      (dexp, funcs) = differentiateExp(inExp, inCref, diffData, BackendDAE.DIFF_FULL_JACOBIAN(), funcs);
      (dexp,_) = ExpressionSimplify.simplify(dexp);
      oshared = BackendDAEUtil.addFunctionTree(funcs, ishared);
      then (dexp, oshared);
    else
    equation
        // expandDerOperator expectes sometime that differentiate fails,
        // so the calling function need to take care of the error messages.
        // TODO: change that in expandDerOperator
        //Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, DAEUtil.getElementSourceFileInfo(DAE.emptyElementSource));

        true = Flags.isSet(Flags.FAILTRACE);
        msg = "\nDifferentiate.differentiateCrefFullJacobian failed for " + ExpressionDump.printExpStr(inExp) + "\n\n";
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {msg});
      then fail();

  end matchcontinue;
end differentiateExpCrefFullJacobian;


// =============================================================================
// further interface functions to differentiation
//  - differentiateEquation
//  - differentiateBackendDAE
//
// =============================================================================


protected function differentiateEquations "
  Differentiates an equation with respect to a cref."
  input list<BackendDAE.Equation> inEquations;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input list<BackendDAE.Equation> inEquationsAccum;
  input DAE.FunctionTree inFunctionTree;
  output list<BackendDAE.Equation> outEquations;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outEquations,outFunctionTree) := matchcontinue (inEquations, inDiffwrtCref, inInputData, inDiffType, inEquationsAccum, inFunctionTree)
    local
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> rest, eqns;
      BackendDAE.Equation eqn;
      String msg;
      DAE.ElementSource source;
      list<Integer> ass, ass2;

    case ({},_,_,_,_,_) then (listReverse(inEquationsAccum), inFunctionTree);

    // equations
    case (eqn::rest,_,_,_,_,_)
      equation
        (eqn, funcs) = differentiateEquation(eqn,  inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        eqns = listAppend({eqn}, inEquationsAccum);
        (eqns, funcs) = differentiateEquations(rest, inDiffwrtCref, inInputData, inDiffType, eqns, funcs);
      then (eqns, funcs);

    case (eqn::_,_,_,_,_,_)
      equation
        msg = "\nDifferentiate.differentiateEquations failed for " + BackendDump.equationString(eqn) + "\n\n";
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {msg});
      then
        fail();
  end matchcontinue;
end differentiateEquations;

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
  (outEquation, outFunctionTree) := match(inEquation, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local
      DAE.Exp e1_1, e2_1, e1_2, e2_2, e1, e2;
      DAE.ComponentRef cref;
      BackendDAE.Variables timevars;
      DAE.ElementSource source, sourceStmt;
      Integer size;
      list<DAE.Exp> out1, expExpLst, expExpLst1;
      DAE.Type exptyp;
      list<Integer> dimSize;
      String msg, se1, dse1, se2, dse2;
      DAE.SymbolicOperation op1, op2;
      DAE.FunctionTree funcs;
      DAE.Algorithm alg;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      list<DAE.Statement> statementLst;
      DAE.Expand expand;
      BackendDAE.WhenEquation whenEqn;
      BackendDAE.EquationKind eqKind;

    // equations
    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
      equation
        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.EQUATION(e1_1, e2_1, source, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    // solved equations
    case (BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e2, source=source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
      equation
        e1 = Expression.crefExp(cref);

        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.EQUATION(e1_1, e2_1, source, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    // RESIDUAL_EQUATION
    case (BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
      equation

        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        source = List.foldr({op1}, DAEUtil.addSymbolicTransformation, source);

      then
        (BackendDAE.RESIDUAL_EQUATION(e1_1, source, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    // complex equations
    case (BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
      equation
        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.COMPLEX_EQUATION(size, e1_1, e2_1, source, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    // Array Equations
    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize, left=e1, right=e2, source=source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
      equation
        (e1_1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e1_1, _) = ExpressionSimplify.simplify(e1_1);

        (e2_1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
        (e2_1, _) = ExpressionSimplify.simplify(e2_1);

        op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e1_1);
        op2 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e2, e2_1);
        source = List.foldr({op1, op2}, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.ARRAY_EQUATION(dimSize, e1_1, e2_1, source, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    // differentiate algorithm
    case (BackendDAE.ALGORITHM(size=size, alg=DAE.ALGORITHM_STMTS(statementLst=statementLst), source=source, expand=expand, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
      equation
        // get Allgorithm
        (statementLst, funcs) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
        alg = DAE.ALGORITHM_STMTS(statementLst);

        //op1 = DAE.OP_DIFFERENTIATE(cr, before, after)
        //op1 = DAE.OP_DIFFERENTIATE(inDiffwrtCref, e1, e2);
        //source = DAEUtil.addSymbolicTransformation(source, op1);
       then
        (BackendDAE.ALGORITHM(size, alg, source, expand, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    // if-equations
    case (BackendDAE.IF_EQUATION(conditions=expExpLst, eqnstrue=eqnslst, eqnsfalse=eqns, source=source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
      equation
        (eqnslst, funcs) = differentiateEquationsLst(eqnslst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
        (eqns, funcs) = differentiateEquations(eqns, inDiffwrtCref, inInputData, inDiffType, {}, funcs);
      then
        (BackendDAE.IF_EQUATION(expExpLst, eqnslst, eqns, source, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    case (BackendDAE.WHEN_EQUATION(size=size, whenEquation=whenEqn, source=source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind)), _, _, _, _)
       equation
        (whenEqn, funcs) = differentiateWhenEquations(whenEqn, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      then
        (BackendDAE.WHEN_EQUATION(size, whenEqn, source, BackendDAE.EQUATION_ATTRIBUTES(false, eqKind, BackendDAE.NO_LOOP())), funcs);

    else
      equation
        msg = "\nDifferentiate.differentiateEquation failed for " + BackendDump.equationString(inEquation) + "\n\n";
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {msg});
      then
        fail();
  end match;
end differentiateEquation;

protected function differentiateEquationsLst
" Differentiates a list of an equation list with respect to a cref.
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
  (outEquationsLst, outFunctionTree) := matchcontinue (inEquationsLst, inDiffwrtCref, inInputData, inDiffType, inEquationsLstAccum, inFunctionTree)
    local
      DAE.FunctionTree funcs;
      list<list<BackendDAE.Equation>> rest, eqnsLst;
      list<BackendDAE.Equation> eqns;
      String msg;
      DAE.ElementSource source;

    case ({},_,_,_,_,_) then (listReverse(inEquationsLstAccum), inFunctionTree);

    // equations
    case (eqns::rest,_,_,_,_,_)
      equation
        (eqns, funcs) = differentiateEquations(eqns,  inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
        eqnsLst = listAppend({eqns}, inEquationsLstAccum);
        (eqnsLst, funcs) = differentiateEquationsLst(rest, inDiffwrtCref, inInputData, inDiffType, eqnsLst, funcs);
      then (eqnsLst, funcs);

    case (_::_,_,_,_,_,_)
      equation
        msg = "\nDifferentiate.differentiateEquationsLst failed.\n\n";
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {msg});
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
algorithm
  (outWhenEquations, outFunctionTree) := matchcontinue (inWhenEquations, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local
      DAE.FunctionTree funcs;
      String msg;
      DAE.ElementSource source;
      DAE.Exp condition;
      DAE.ComponentRef left, dleft;
      DAE.Exp right, dright, eleft;
      BackendDAE.WhenEquation elsewhenPart, delsewhenPart;

    // equations
    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=NONE()) ,_,_,_,_)
      equation
        eleft = Expression.crefExp(left);
        (eleft,funcs) = differentiateExp(eleft, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (dright,funcs) = differentiateExp(right, inDiffwrtCref, inInputData, inDiffType, funcs);
        dleft = Expression.expCref(eleft);
      then (BackendDAE.WHEN_EQ(condition, dleft, dright, NONE()), funcs);

    case (BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=SOME(elsewhenPart)) ,_,_,_,_)
      equation
        eleft = Expression.crefExp(left);
        (eleft,funcs) = differentiateExp(eleft, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (dright,funcs) = differentiateExp(right, inDiffwrtCref, inInputData, inDiffType, funcs);
        dleft = Expression.expCref(eleft);
        (delsewhenPart, funcs) = differentiateWhenEquations(elsewhenPart, inDiffwrtCref, inInputData, inDiffType, funcs);
      then (BackendDAE.WHEN_EQ(condition, dleft, dright, SOME(delsewhenPart)), funcs);

    case (_,_,_,_,_)
      equation
        msg = "\nDifferentiate.differentiateWhenEquations failed.\n\n";
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {msg});
      then
        fail();
  end matchcontinue;
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
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp, outFunctionTree) :=
    match(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local
      DAE.Exp e, e1, e2, e3, actual, simplified;
      DAE.Exp res, res1, res2;
      DAE.Type tp;
      DAE.Operator op;

      String s1,s2,serr;
      String se1;
      Integer i;
      Boolean b;

      list<DAE.Exp> sub, expl;
      list<list<DAE.Exp>> matrix, dmatrix;

      DAE.FunctionTree functionTree;

      DAE.CallAttributes attr;
      Absyn.Path p;


    // constants => results in zero
    case (DAE.BCONST(bool = b), _, _, _, _) then (DAE.BCONST(b), inFunctionTree);
    case (DAE.ICONST(), _, _, _, _) then (DAE.ICONST(0), inFunctionTree);
    case (DAE.RCONST(), _, _, _, _) then (DAE.RCONST(0.0), inFunctionTree);

    // differentiate cref
    case (e as DAE.CREF(), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\nDifferentiate exp: " + se1);

        (res, functionTree) = differentiateCrefs(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then (res, functionTree);

    /*/ differentiate homotopy
    case( e as DAE.CALL(
                path = p as Absyn.IDENT(name="homotopy"),
                expLst = {actual,simplified},
                attr = attr), _, _, _, _)
      equation
        (e1, functionTree) = differentiateExp(actual, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e2, functionTree) = differentiateExp(simplified, inDiffwrtCref, inInputData, inDiffType, functionTree);
        res = DAE.CALL(p, {e1, e2}, attr);
      then
        (res, functionTree);*/

    // differentiate call
    case( e as DAE.CALL(), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Call\nDifferentiate exp: " + se1);

        (res, functionTree) = differentiateCalls(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then (res, functionTree);

    // differentiate binary
    case( e as DAE.BINARY(), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-BINARY\nDifferentiate exp: " + se1);

        (res, functionTree) = differentiateBinary(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then (res, functionTree);

    // differentiate operator
    case( DAE.UNARY(operator = op,exp = e1), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-UNARY\nDifferentiate exp: " + se1);

        (res, functionTree) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

        res = DAE.UNARY(op,res);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then (res, functionTree);

    // differentiate cast
    case( DAE.CAST(ty = tp, exp = e), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-CAST\nDifferentiate exp: " + se1);

        (res, functionTree) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then (DAE.CAST(tp, res), functionTree);

    // differentiate asub
    case (DAE.ASUB(exp = e,sub = sub), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-ASUB\nDifferentiate exp: " + se1);

        (res1, functionTree) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

        res = Expression.makeASUB(res1,sub);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, functionTree);

    case (DAE.ARRAY(ty = tp,scalar = b,array = expl), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-ARRAY\nDifferentiate exp: " + se1);

        (expl, functionTree) = List.map3Fold(expl, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

        res = DAE.ARRAY(tp, b, expl);
        (res,_) = ExpressionSimplify.simplify1(res);
        //(res,_) = ExpressionSimplify.simplify(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, functionTree);


    case ((DAE.MATRIX(ty = tp, integer=i, matrix=matrix)), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-MARTIX\nDifferentiate exp: " + se1);

        (dmatrix, functionTree) = List.map3FoldList(matrix, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

        res = DAE.MATRIX(tp, i, dmatrix);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(e);
        //print("\nresults to exp: " + se1);
      then
        (res, functionTree);

     // differentiate tsub
    case (DAE.TSUB(exp = e,ix = i, ty = tp), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-TSUB\nDifferentiate exp: " + se1);

        (res1, functionTree) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

        res =  DAE.TSUB(res1, i, tp);
        (res,_) = ExpressionSimplify.simplify1(res);
        //(res,_) = ExpressionSimplify.simplify(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, functionTree);

    // differentiate tuple
    case (DAE.TUPLE(PR = expl), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-TUPLE\nDifferentiate exp: " + se1);

        (expl, functionTree) = List.map3Fold(expl, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

        res = DAE.TUPLE(expl);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, functionTree);

    case (DAE.IFEXP(expCond = e1, expThen = e2, expElse = e3), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-IF-EXP\nDifferentiate exp: " + se1);

        (res1, functionTree) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res2, functionTree) = differentiateExp(e3, inDiffwrtCref, inInputData, inDiffType, functionTree);

        res = DAE.IFEXP(e1, res1, res2);
        (res,_) = ExpressionSimplify.simplify1(res);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, functionTree);

    // boolean expression e.g. relation are left as thes are
    case (e as DAE.RELATION(), _, _, _, _)
      then
        (e, inFunctionTree);

    case (e as DAE.LBINARY(), _, _, _, _)
      then
        (e, inFunctionTree);

    case (e as DAE.LUNARY(), _, _, _, _)
      then
        (e, inFunctionTree);

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s1 = ExpressionDump.printExpStr(inExp);
        s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
        serr = stringAppendList({"- differentiateExp ",s1," w.r.t: ",s2," failed\n"});
        Debug.trace(serr);
      then
        fail();

  end match;

end differentiateExp;

protected function differentiateStatements
  input list<DAE.Statement> inStmts;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input list<DAE.Statement> inStmtsAccum;
  input DAE.FunctionTree inFunctionTree;
  output list<DAE.Statement> outDiffedStmts;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedStmts, outFunctionTree) :=
    match(inStmts, inDiffwrtCref, inInputData, inDiffType, inStmtsAccum, inFunctionTree)
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

    String s1,s2,serr;

    case({}, _, _, _, _, _) then (listReverse(inStmtsAccum), inFunctionTree);

    case ((currStatement as DAE.STMT_ASSIGN(type_=type_, exp1=lhs, exp=rhs, source=source))::restStatements, _, _, _, _, _)
      equation
        (derivedLHS, functions) = differentiateExp(lhs, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (derivedRHS, functions) = differentiateExp(rhs, inDiffwrtCref, inInputData, inDiffType, functions);
        (derivedRHS,_) = ExpressionSimplify.simplify(derivedRHS);
        derivedStatements1 = {DAE.STMT_ASSIGN(type_, derivedLHS, derivedRHS, source), currStatement};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case ((currStatement as DAE.STMT_TUPLE_ASSIGN(expExpLst= expLst, exp=rhs,  source=source))::restStatements, _, _, _, _, _)
      equation
        (dexpLst,functions) = List.map3Fold(expLst, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (derivedRHS as DAE.TUPLE(expLstRHS), functions) = differentiateExp(rhs, inDiffwrtCref, inInputData, inDiffType, functions);
        (DAE.TUPLE(expLstRHS),_) = ExpressionSimplify.simplify(derivedRHS);
        exptl = List.threadTuple(dexpLst, expLstRHS);
        derivedStatements1 = List.map1(exptl, Algorithm.makeSimpleAssignment, source);
        derivedStatements1 = listAppend(derivedStatements1, {currStatement});
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case ((currStatement as DAE.STMT_ASSIGN_ARR(lhs=lhs, exp=rhs, type_=type_, source=source))::restStatements, _, _, _, _, _)
      equation
        (derivedLHS, functions) = differentiateExp(lhs, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (derivedRHS, functions) = differentiateExp(rhs, inDiffwrtCref, inInputData, inDiffType, functions);
        (derivedRHS,_) = ExpressionSimplify.simplify(derivedRHS);
        derivedStatements1 = {DAE.STMT_ASSIGN_ARR(type_, derivedLHS, derivedRHS, source), currStatement};
        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case (DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, iter=ident, index=index, range=exp, statementLst=statementLst, source=source)::restStatements, _, _, _, _, _)
      equation
        cref = ComponentReference.makeCrefIdent(ident, DAE.T_INTEGER_DEFAULT, {});
        controlVar = BackendDAE.VAR(cref, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
        inputData = addAllVars({controlVar}, inInputData);
        (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inputData, inDiffType, {}, inFunctionTree);

        derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, index, exp, derivedStatements1, source)};

        derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
        (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, _, _, _, _, _)
    equation
      (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE(), source)};
      derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
      (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, _, _, _, _, _)
    equation
      (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
      (derivedStatements2, functions) = differentiateStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, inDiffwrtCref, inInputData, inDiffType, {}, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
      (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, _, _, _, _, _)
    equation
      (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
      (derivedStatements2, functions) = differentiateStatements(else_statementLst, inDiffwrtCref, inInputData, inDiffType, {}, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
      (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case(DAE.STMT_WHILE(exp=exp, statementLst=statementLst, source=source)::restStatements, _, _, _, _, _)
    equation
      (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
      derivedStatements1 = {DAE.STMT_WHILE(exp, derivedStatements1, source)};
      derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
      (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case(DAE.STMT_WHEN(exp=exp, initialCall=initialCall, statementLst=statementLst, elseWhen= NONE(), source=source)::restStatements, _, _, _, _, _)
    equation
      (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
      derivedStatements1 = {DAE.STMT_WHEN(exp, {}, initialCall, derivedStatements1, NONE(), source)};
      derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
      (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case(DAE.STMT_WHEN(exp=exp, initialCall=initialCall, statementLst=statementLst, elseWhen= SOME(stmt), source=source)::restStatements, _, _, _, _, _)
    equation
      (derivedStatements1, functions) = differentiateStatements(statementLst, inDiffwrtCref, inInputData, inDiffType, {}, inFunctionTree);
      ({dstmt}, functions) = differentiateStatements({stmt}, inDiffwrtCref, inInputData, inDiffType, {}, functions);
      derivedStatements1 = {DAE.STMT_WHEN(exp, {}, initialCall, derivedStatements1, SOME(dstmt), source)};
      derivedStatements1 = listAppend(derivedStatements1, inStmtsAccum);
      (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, functions);
    then (derivedStatements2, functions);

    case((DAE.STMT_ASSERT())::restStatements, _, _, _, _, _)
    equation
      (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, inStmtsAccum, inFunctionTree);
    then (derivedStatements1, functions);

    case((currStatement as DAE.STMT_TERMINATE())::restStatements, _, _, _, _, _)
    equation
      derivedStatements1 = listAppend({currStatement}, inStmtsAccum);
      (derivedStatements2, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree);
    then (derivedStatements2, functions);

    case((currStatement as DAE.STMT_REINIT())::restStatements, _, _, _, _, _)
    equation
      derivedStatements1 = listAppend({currStatement}, inStmtsAccum);
      (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree);
    then (derivedStatements1, functions);

    case((currStatement as DAE.STMT_NORETCALL())::restStatements, _, _, _, _, _)
    equation
      derivedStatements1 = listAppend({currStatement}, inStmtsAccum);
      (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree);
    then (derivedStatements1, functions);

    case((currStatement as DAE.STMT_RETURN())::restStatements, _, _, _, _, _)
    equation
      derivedStatements1 = listAppend({currStatement}, inStmtsAccum);
      (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree);
    then (derivedStatements1, functions);

    case((currStatement as DAE.STMT_BREAK())::restStatements, _, _, _, _, _)
    equation
      derivedStatements1 = listAppend({currStatement}, inStmtsAccum);
      (derivedStatements1, functions) = differentiateStatements(restStatements, inDiffwrtCref, inInputData, inDiffType, derivedStatements1, inFunctionTree);
    then (derivedStatements1, functions);

   else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        (currStatement::_) = inStmts;
        s1 = DAEDump.ppStatementStr(currStatement);
        s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
        serr = stringAppendList({"- differentiateStatements ",s1," w.r.t: ",s2," failed\n"});
        Debug.trace(serr);
      then
        fail();

  end match;
end differentiateStatements;


// =============================================================================
// help functions for differentation
//  - differentiateCrefs
//  - differentiateCalls
//  - differentiateBinary (e.g.: ADD, SUB, MUL, DIV, POW, ...
//
// =============================================================================

protected function differentiateCrefs
"
function: differentiateCrefs


"
  input DAE.Exp inExp;   // in as DAE.CREF(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp, outFunctionTree) :=
    matchcontinue(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local

      Absyn.Path path;

      BackendDAE.Variables timevars;
      BackendDAE.Variables knvars;
      BackendDAE.Var var;
      BackendDAE.VarKind kind;

      list<BackendDAE.Var> vars;
      DAE.Type tp;
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

    // case for Records
    case ((DAE.CREF(componentRef = cr,ty = tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(path)))), _, _, _, _)
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        (expl_1, outFunctionTree) = List.map3Fold(expl, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        res = DAE.CALL(path,expl_1,DAE.CALL_ATTR(tp,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nExp-Cref\n records " + se1);
      then
        (res, outFunctionTree);

   // case for array without expanding the array
   case (DAE.CREF(componentRef = cr,ty=tp as DAE.T_ARRAY()), _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n simple cref: " + se1);
        cr = ComponentReference.prependStringCref(BackendDAE.functionDerivativeNamePrefix, cr);
        cr = ComponentReference.prependStringCref(matrixName, cr);

        e = Expression.makeCrefExp(cr, tp);
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nresults to exp: " + se1);
      then
        (e, inFunctionTree);

    // case for arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY())), _, _, _, _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n Array " + se1);

        (e1,true) = Expression.extendArrExp(e,false);
        (res, outFunctionTree) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nExp-Cref\n Array " + se1);
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
        one = Expression.makeConstOne(tp);

        //print("\nExp-Cref\n d(x)/d(x) = 1");
      then
        (one, inFunctionTree);

    // D(y)/dx => 0
    case (DAE.CREF(ty = tp), _, _, BackendDAE.SIMPLE_DIFFERENTIATION(), _)
      equation
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        //print("\nExp-Cref\n d(x)/d(x) = 1");
      then
        (zero, inFunctionTree);

    // D(y)/dx => 0
    case (DAE.CREF(ty = tp), _, _, BackendDAE.DIFF_FULL_JACOBIAN(), _)
      equation
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        //print("\nExp-Cref\n d(x)/d(x) = 1");
      then
        (zero, inFunctionTree);

    // Constants, known variables, parameters and discrete variables have a 0-derivative, not the inputs
    case ((DAE.CREF(componentRef = cr, ty = tp)), _, BackendDAE.DIFFINPUTDATA(knownVars=SOME(knvars)), _, _)
      equation
        //print("\nExp-Cref\n known vars: " + ExpressionDump.printExpStr(e));
        (var::{},_) = BackendVariable.getVar(cr, knvars);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        //print("\nExp-Cref\n known variables = 0");
      then
        (zero, inFunctionTree);

    // d(discrete)/d(x) = 0
    case ((DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(allVars=SOME(timevars)), _, _)
      equation
        ({BackendDAE.VAR(varKind = kind)},_) = BackendVariable.getVar(cr, timevars);
        //print("\nExp-Cref\n known vars: " + ComponentReference.printComponentRefStr(cr));
        true = listMember(kind,{BackendDAE.DISCRETE()}) or not Types.isReal(tp);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        //print("\nExp-Cref\n discrete variables = 0");
      then
        (zero, inFunctionTree);

    //
    // This part contains special rules for DIFFERENTIATION_TIME()
    //

    // special rule for DUMMY_STATES, they become DUMMY_DER
    case ((DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\nDUMMY_STATE: " + se1);

        ({var},_) = BackendVariable.getVar(cr, timevars);
        true = BackendVariable.isDummyStateVar(var);
        cr = ComponentReference.crefPrefixDer(cr);
        res = Expression.makeCrefExp(cr, tp);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, inFunctionTree);

    // Continuous-time variables (and for shared eq-systems, also unknown variables: keep them as-they-are)
    case ((e as DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n all other vars: " + se1);

        //({BackendDAE.VAR(varKind = BackendDAE.STATE(index=_))},_) = BackendVariable.getVar(cr, timevars);
        ({_},_) = BackendVariable.getVar(cr, timevars);
        res = DAE.CALL(Absyn.IDENT("der"),{e},DAE.CALL_ATTR(tp,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, inFunctionTree);

    //
    // This part contains special rules for DIFFERENTIATION_FUNCTION()
    //
    // dependenent variable cref without subscript
    case ((DAE.CREF(componentRef = cr,ty=tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n independent cref: " + se1);

        cr1 = ComponentReference.crefStripLastSubs(cr);
        (_,_) = BackendVariable.getVar(cr1, timevars);
        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        //se1 = ExpressionDump.printExpStr(zero);
        //print("\nresults to exp: " + se1);
      then
        (zero, inFunctionTree);

    // dependenent variable cref
    case ((DAE.CREF(componentRef = cr,ty=tp)), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n independent cref: " + se1);

        (_,_) = BackendVariable.getVar(cr, timevars);
        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        //se1 = ExpressionDump.printExpStr(zero);
        //print("\nresults to exp: " + se1);
      then
        (zero, inFunctionTree);

    // all other variable crefs are needed to differentiate
    case ((DAE.CREF(componentRef = cr,ty=tp)), _, BackendDAE.DIFFINPUTDATA(matrixName=SOME(matrixName)), BackendDAE.DIFFERENTIATION_FUNCTION(), _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n dependent cref: " + se1);

        cr = ComponentReference.prependStringCref(BackendDAE.functionDerivativeNamePrefix, cr);
        cr = ComponentReference.prependStringCref(matrixName, cr);
        res = Expression.makeCrefExp(cr, tp);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, inFunctionTree);

    //
    // This part contains special rules for GENERIC_GRADIENT()
    //

    // d(x)/d(x) => generate seed variables
    case ((DAE.CREF(componentRef = cr,ty = tp)), _, BackendDAE.DIFFINPUTDATA(independenentVars=SOME(timevars),matrixName=SOME(matrixName)), BackendDAE.GENERIC_GRADIENT(), _)
      equation
        //true = List.isMemberOnTrue(cr, diffCref, ComponentReference.crefEqual);
        (_::_, _) = BackendVariable.getVar(cr, timevars);
        cr = createSeedCrefName(cr, matrixName);

        res = DAE.CREF(cr, tp);

        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n GG seed: " + se1);
        //print(" *** diffCref : " + ComponentReference.printComponentRefStr(cr) + " w.r.t " + ComponentReference.printComponentRefStr(inDiffwrtCref) + "\n");
      then
        (res, inFunctionTree);


    // d(x)/d(z) = CREF(d(x)/d(dummy))
    case (DAE.CREF(componentRef=cr, ty=tp), _, BackendDAE.DIFFINPUTDATA(allVars=SOME(timevars),matrixName=SOME(matrixName)), BackendDAE.GENERIC_GRADIENT(), _)
      equation
        (var::_, _) = BackendVariable.getVar(cr, timevars);
        //Take care! state means => der(state)
        false = BackendVariable.isStateVar(var);

        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n GG dummy: " + se1);

        cr = createDifferentiatedCrefName(cr, inDiffwrtCref, matrixName);
        res = DAE.CREF(cr, tp);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, inFunctionTree);

    // d(x)/d(z) = CREF(d(x)/d(dummy))
    case (DAE.CREF(componentRef=cr, ty=tp), _, BackendDAE.DIFFINPUTDATA(dependenentVars=SOME(timevars),matrixName=SOME(matrixName)), BackendDAE.GENERIC_GRADIENT(), _)
      equation
        (var::_, _) = BackendVariable.getVar(cr, timevars);
        //Take care! state means => der(state)
        false = BackendVariable.isStateVar(var);

        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n GG dummy: " + se1);

        cr = createDifferentiatedCrefName(cr, inDiffwrtCref, matrixName);
        res = DAE.CREF(cr, tp);

        //se1 = ExpressionDump.printExpStr(res);
        //print("\nresults to exp: " + se1);
      then
        (res, inFunctionTree);

    // d(state)/d(x) = 0
    // d(input)/d(x) = 0
    // d(all other)/d(x) = 0
    case (DAE.CREF(ty=tp), _, _, BackendDAE.GENERIC_GRADIENT(), _)
      equation
        //se1 = ExpressionDump.printExpStr(e);
        //print("\nExp-Cref\n GG zero: " + se1);

        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        //se1 = ExpressionDump.printExpStr(zero);
        //print("\nresults to exp: " + se1);
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
end differentiateCrefs;

public function createDifferentiatedCrefName
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  input String inMatrixName;
  output DAE.ComponentRef outCref;
protected
 String str;
algorithm
  outCref := ComponentReference.replaceSubsWithString(inCref);
  outCref := ComponentReference.joinCrefs(outCref, ComponentReference.makeCrefIdent(BackendDAE.partialDerivativeNamePrefix + inMatrixName, ComponentReference.crefTypeConsiderSubs(inCref), {}));
  outCref := ComponentReference.joinCrefs(outCref, inX);
end createDifferentiatedCrefName;

public function createSeedCrefName
  input DAE.ComponentRef inCref;
  input String inMatrixName;
  output DAE.ComponentRef outCref;
algorithm
  outCref := ComponentReference.replaceSubsWithString(inCref);
  outCref := ComponentReference.makeCrefIdent(ComponentReference.crefModelicaStr(outCref) + "Seed" + inMatrixName, ComponentReference.crefTypeConsiderSubs(inCref), {});
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
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
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
      DAE.Exp res, res1;
      DAE.Type tp;
      DAE.FunctionTree funcs;

      Integer i;
      Boolean b;

      list<Boolean> blst;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expl, expl_1;

      list<list<DAE.ComponentRef>> crefslstls;
      Option<BackendDAE.Shared> optShared;

      String s1, s2, serr, matrixName, name;

    case (e as DAE.CALL(path=Absyn.IDENT(name = "pre")), _, _, _, _)
      then
        (e,  inFunctionTree);

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
        cr = createDifferentiatedCrefName(cr, inDiffwrtCref, matrixName);
        res = Expression.makeCrefExp(cr, tp);

        b = ComponentReference.crefEqual(DAE.CREF_IDENT("$",DAE.T_REAL_DEFAULT,{}), inDiffwrtCref);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));

        res = if b then zero else res;
      then
        (res,  inFunctionTree);

    // differentiate builtin calls with 1 argument
    case (DAE.CALL(path=Absyn.IDENT(name),attr=DAE.CALL_ATTR(builtin=true),expLst={e}), _, _, _, _)
      equation
        //s1 = ExpressionDump.printExpStr(e);
        //print("\nExp-CALL\n build-funcs "+ name + "(" + s1 + ")\n");
        (res,  funcs) = differentiateCallExp1Arg(name, e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        //s1 = ExpressionDump.printExpStr(e);
        //print("\nresults to exp: " + s1);
      then (res,  funcs);


    // differentiate builtin calls with N arguments with match
    // der(arctan2(y,0)) = der(sign(y)*pi/2) = 0
    case (DAE.CALL(path=Absyn.IDENT("atan2"),attr=DAE.CALL_ATTR(builtin=true),expLst={_,e1 as  DAE.RCONST(real=0.0)}), _, _, _, _)
      then
        (e1,  inFunctionTree);

    // differentiate builtin calls with N arguments as match
    case (DAE.CALL(path=Absyn.IDENT(name),attr=(attr as DAE.CALL_ATTR(builtin=true)),expLst= (expl as (_::_::_))), _, _, _, _)
      equation
        //s1 = ExpressionDump.printExpStr(e);
        //print("\nExp-CALL\n build-funcs "+ name + "(" + s1 + ")\n");
        (res,  funcs) = differentiateCallExpNArg(name, expl, attr, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        //s1 = ExpressionDump.printExpStr(e);
        //print("\nresults to exp: " + s1);
      then (res,  funcs);

    case (e as DAE.CALL(), _, _, _, _)
      equation
        (e1, funcs) = differentiateFunctionCall(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e,_,_,_) = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE(),DAE.NO_INLINE()}),DAE.emptyElementSource/*TODO:Can we propagate source?*/);
      then
        (e, funcs);
/*
    case (e as DAE.CALL(expLst = _), _, _, _, _)
      equation
        s1 = ExpressionDump.printExpStr(e);
        s2 = ComponentReference.printComponentRefStr(inDiffwrtCref);
        serr = stringAppendList({"\n- Function differentiateCalls failed. differentiateExp ",s1," w.r.t: ",s2," failed\n"});
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {serr});
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
end differentiateCalls;

protected function differentiateCallExp1Arg "
  This function differentiates builtin call expressions with 1 argument
  with respect to a given variable,given as third argument."
  input String name;
  input DAE.Exp exp;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFuncs;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp,outFunctionTree) := match (name, exp, inDiffwrtCref, inInputData, inDiffType, inFuncs)
    local
      DAE.Exp exp_1,exp_2;
      DAE.FunctionTree funcs;
      DAE.Type tp;
      list<DAE.Exp> expl;

    case ("previous",_,_,_,_,_) then (exp, inFuncs);
    case ("$getPart",_,_,_,_,_) then (exp, inFuncs);
    case ("interval",_,_,_,_,_) then (exp, inFuncs);

    // diff(sin(x)) = cos(x)*der(x)
    case ("sin",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("cos", {exp}, tp);
      then (DAE.BINARY(exp_2, DAE.MUL(tp), exp_1), funcs);

    // diff(cos(x)) = -sin(x)*der(x)
    case ("cos",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("sin", {exp}, tp);
      then (DAE.BINARY(DAE.UNARY(DAE.UMINUS(tp),exp_2), DAE.MUL(tp), exp_1), funcs);

    // diff(tan(x)) = (2*der(x)/(cos(2*x)+1))
    case ("tan",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("cos", {DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(tp),exp)}, tp);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.RCONST(2.0), DAE.MUL(tp), exp_1), DAE.DIV(tp),
          DAE.BINARY(exp_2, DAE.ADD(tp), DAE.RCONST(1.0))), funcs);

    // der(arcsin(x)) = der(x)/sqrt(1-x^2)
    case ("asin",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("sqrt", {DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(tp),DAE.BINARY(exp,DAE.MUL(tp),exp))}, tp);
      then (DAE.BINARY(exp_1,DAE.DIV(tp),exp_2), funcs);

    // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case ("acos",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("sqrt", {DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(tp),DAE.BINARY(exp,DAE.MUL(tp),exp))}, tp);
      then (DAE.UNARY(DAE.UMINUS(tp),DAE.BINARY(exp_1,DAE.DIV(tp),exp_2)), funcs);

    // der(arctan(x)) = der(x)/(1+x^2)
    case ("atan",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
      then (DAE.BINARY(exp_1,DAE.DIV(tp),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(tp),DAE.BINARY(exp,DAE.MUL(tp),exp))), funcs);

    // der(sinh(x)) => der(x)sinh(x)
    case ("sinh",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("cosh",{exp},tp);
      then (DAE.BINARY(exp_1,DAE.MUL(tp),exp_2), funcs);

    // der(cosh(x)) => der(x)sinh(x)
    case ("cosh",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("sinh",{exp},tp);
      then (DAE.BINARY(exp_1,DAE.MUL(tp),exp_2), funcs);

    // der(tanh(x)) = der(x) / cosh(x)^2
    case ("tanh",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType, inFuncs);
        exp_2 = Expression.makePureBuiltinCall("cosh", {exp}, tp);
      then (DAE.BINARY(exp_1, DAE.DIV(tp),
                      DAE.BINARY(exp_2, DAE.POW(tp), DAE.RCONST(2.0))), funcs);

    // diff(exp(x)) = der(x)*exp(x)
    case ("exp",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("exp",{exp},tp);
      then (DAE.BINARY(exp_2, DAE.MUL(tp), exp_1), funcs);

    // diff(log(x)) = der(x)/x
    case ("log",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
      then
        (DAE.BINARY(exp_1, DAE.DIV(tp), exp), funcs);

    // diff(log10(x)) = der(x)/(x*log(10))
    case ("log10",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("log",{DAE.RCONST(10.0)},tp);
      then
        (DAE.BINARY(exp_1, DAE.DIV(tp),
          DAE.BINARY(exp, DAE.MUL(tp), exp_2)), funcs);

    // diff(sqrt(x)) = der(x)/(2*sqrt(x))
    case ("sqrt",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("sqrt",{exp},tp);
      then
        (DAE.BINARY(exp_1, DAE.DIV(tp),
          DAE.BINARY(DAE.RCONST(2.0), DAE.MUL(tp), exp_2)), funcs);

    // der(abs(x)) = sign(x)der(x)
    case ("abs",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 = Expression.makePureBuiltinCall("sign",{exp}, tp);
      then (DAE.BINARY(exp_2, DAE.MUL(tp), exp_1), funcs);

    case ("sign",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then (exp_1, inFuncs);

    case ("max",DAE.ARRAY(array=expl,ty=tp),_,_,_,_)
      equation
        tp = Types.arrayElementType(tp);
        exp_1 = createFromNCall2ArgsCall("max", expl, tp);
        (exp_2, funcs) = differentiateExp(exp_1, inDiffwrtCref, inInputData, inDiffType, inFuncs);
      then
       (exp_2, funcs);

    case ("min",DAE.ARRAY(array=expl,ty=tp),_,_,_,_)
      equation
        tp = Types.arrayElementType(tp);
        exp_1 = createFromNCall2ArgsCall("min", expl, tp);
        (exp_2, funcs) = differentiateExp(exp_1, inDiffwrtCref, inInputData, inDiffType, inFuncs);
      then
       (exp_2, funcs);

    case ("floor",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (exp_1, inFuncs);

    case ("ceil",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (exp_1, inFuncs);

    case ("integer",_,_,_,_,_)
      equation
        tp = Expression.typeof(exp);
        (exp_1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
       (exp_1, inFuncs);

    /*der(x)/dt*/
    case ("$_DF$DER",_,_,_,_,_)
      equation
        (exp_1, funcs) = differentiateExp(exp, inDiffwrtCref, inInputData,inDiffType,inFuncs);
        exp_2 =  Expression.crefExp(ComponentReference.makeCrefIdent(BackendDAE.symEulerDT, DAE.T_REAL_DEFAULT, {}));
      then
       (Expression.expDiv(exp_1,exp_2), inFuncs);

  end match;
end differentiateCallExp1Arg;

function createFromNCall2ArgsCall
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
  This function differentiates builtin call expressions with N argument
  with respect to a given variable,given as third argument."
  input String name;
  input list<DAE.Exp> inExpl;
  input DAE.CallAttributes inAttr;
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp,outFunctionTree) := match(name,inExpl,inAttr,inDiffwrtCref,inInputData,inDiffType,inFunctionTree)
    local
      DAE.Exp e, e1, e2, cond, etmp;
      DAE.Exp res, res1, res2;
      list<DAE.Exp> expl, dexpl;
      DAE.Type tp;
      DAE.FunctionTree funcs;
      String e_str;
      Integer i;

    case ("smooth",{DAE.ICONST(i),e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (res1, funcs) = differentiateExp(e2,inDiffwrtCref,inInputData,inDiffType,inFunctionTree);
        e1 = Expression.expSub(DAE.ICONST(i), DAE.ICONST(1));
        res2 = if intGe(i,1) then Expression.makePureBuiltinCall("smooth", {e1, res1}, tp) else res1;
      then
        (res2, funcs);

    case ("noEvent",{e1}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (res1, funcs) = differentiateExp(e1,inDiffwrtCref,inInputData,inDiffType,inFunctionTree);
        res1 = Expression.makePureBuiltinCall("noEvent", {res1}, tp);
      then
        (res1, funcs);

    // der(arctan2(x,y)) = der(x/y)/(1+(x/y)^2)
    case ("atan2",{e,e1}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        e2 = Expression.makeDiv(e,e1);
        (res1, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        res2 = Expression.addNoEventToRelations(DAE.IFEXP(DAE.RELATION(e1,DAE.EQUAL(tp),DAE.RCONST(0.0),-1,NONE()),
                e1,
                DAE.BINARY(res1, DAE.DIV(tp), DAE.BINARY(DAE.RCONST(1.0), DAE.ADD(tp), DAE.BINARY(e2, DAE.MUL(tp),e2)))
               ));

      then
        (res2,  funcs);

    // der(semiLinear(x,a,b)) = if (x>=0) then a*x else b*x -> if (x>=0) then da*x+a*dx else db*x+b*dx
    case ("semiLinear", {e,e1,e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (res, funcs) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, funcs);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
        res1 = Expression.expAdd(Expression.expMul(res1, e),Expression.expMul(e1, res));
        res2 = Expression.expAdd(Expression.expMul(res2, e),Expression.expMul(e2, res));
        (res, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        res = DAE.RELATION(e, DAE.GREATEREQ(tp), res, -1, NONE());
      then
        (DAE.IFEXP(res, res1, res2), funcs);

    case ("transpose", expl, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (dexpl, funcs) = List.map3Fold(expl, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      then
        (Expression.makePureBuiltinCall("transpose", dexpl, tp), funcs);

    case ("cross", {e1,e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
        res2 = Expression.makePureBuiltinCall("cross",{e1,res2},tp);
        res1 = Expression.makePureBuiltinCall("cross",{res1,e2},tp);
      then
        (DAE.BINARY(res2, DAE.ADD_ARR(tp), res1), funcs);

    case ("max", {e1,e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(e1,DAE.GREATER(tp),e2,-1,NONE())},DAE.callAttrBuiltinBool), res1, res2), funcs);

    case ("min", {e1,e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (res2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(e1,DAE.LESS(tp),e2,-1,NONE())},DAE.callAttrBuiltinBool), res1, res2), funcs);

    // diff(div(e1,e2)) =  diff(if noEvent(e1 > 0) then floor(e1/e2) else ceil(e1/e2)) = 0.0;
    case ("div", {e1,e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        (res1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (res1, inFunctionTree);

    // diff(mod(e1,e2)) =  diff(e1 - e2*floor(e1/e2))
    case ("mod", {e1,e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        etmp = Expression.makePureBuiltinCall("floor", {DAE.BINARY(e1, DAE.DIV(tp), e2)}, tp);
        e = DAE.BINARY(e1, DAE.SUB(tp), DAE.BINARY(e2, DAE.MUL(tp),  etmp));
        (res1, funcs) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      then
        (res1, funcs);

    // diff(rem(e1,e2)) = diff(e1 -div(e1,e2)*e2)
    case ("rem", {e1,e2}, DAE.CALL_ATTR(ty=tp), _, _, _, _)
      equation
        etmp = Expression.makePureBuiltinCall("div", {e1, e2}, tp);
        e = DAE.BINARY(e1, DAE.SUB(tp), DAE.BINARY(e2, DAE.MUL(tp),  etmp));
        (res1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      then
        (res1, funcs);

  end match;
end differentiateCallExpNArg;

protected function differentiateBinary
"
function: differentiateBinary
"
  input DAE.Exp inExp;   // in as DAE.BINARY(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp, outFunctionTree) :=
    match(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
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

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(de1,DAE.ADD(tp),de2), funcs);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(de1,DAE.ADD_ARR(tp),de2), funcs);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARRAY_SCALAR(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(de1,DAE.ADD_ARRAY_SCALAR(tp),de2), funcs);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(de1,DAE.SUB(tp),de2), funcs);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(de1,DAE.SUB_ARR(tp),de2), funcs);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_SCALAR_ARRAY(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(de1,DAE.SUB_SCALAR_ARRAY(tp),de2), funcs);

    // fg\' + f\'g
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),de2),DAE.ADD(tp),
          DAE.BINARY(de1,DAE.MUL(tp),e2)), funcs);

    // fg\' + f\'g
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARR(tp),de2),DAE.ADD(tp),
          DAE.BINARY(de1,DAE.MUL_ARR(tp),e2)), funcs);

    // fg\' + f\'g
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARRAY_SCALAR(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),de2),DAE.ADD_ARR(tp),
          DAE.BINARY(de1,DAE.MUL_ARRAY_SCALAR(tp),e2)), funcs);

    // fg\' + f\'g
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_SCALAR_PRODUCT(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_SCALAR_PRODUCT(tp),de2),DAE.ADD(tp),
          DAE.BINARY(de1,DAE.MUL_SCALAR_PRODUCT(tp),e2)), funcs);

    // fg\' + f\'g
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(DAE.BINARY(e1,DAE.MUL_MATRIX_PRODUCT(tp),de2),DAE.ADD_ARR(tp),
          DAE.BINARY(de1,DAE.MUL_MATRIX_PRODUCT(tp),e2)), funcs);

    // (f\'g - fg\') / g^2
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(
             DAE.BINARY(DAE.BINARY(de1,DAE.MUL(tp),e2), DAE.SUB(tp),
             DAE.BINARY(e1,DAE.MUL(tp),de2)), DAE.DIV(tp), DAE.BINARY(e2,DAE.MUL(tp),e2)), funcs);

    // (f\'g - fg\') / g^2
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.BINARY(de1,DAE.MUL_ARR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARR(tp),de2)), DAE.DIV_ARR(tp), DAE.BINARY(e2,DAE.MUL_ARR(tp),e2)), funcs);


    // (f\'g - fg\') / g^2
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARRAY_SCALAR(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
        tp1 = Expression.typeof(e2);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.BINARY(de1,DAE.MUL_ARRAY_SCALAR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),de2)),DAE.DIV_ARRAY_SCALAR(tp),DAE.BINARY(e2,DAE.MUL(tp1),e2)), funcs);

    // (f\'g - fg\') / g^2
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_SCALAR_ARRAY(ty = tp),exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, funcs);
      then
        (DAE.BINARY(
          DAE.BINARY(DAE.BINARY(de1,DAE.MUL_ARRAY_SCALAR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),de2)),DAE.DIV_ARR(tp),DAE.BINARY(e2,DAE.MUL_ARR(tp),e2)), funcs);

    // x^r
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.RCONST(real=r))), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        r = r - 1.0;
        e = DAE.BINARY(DAE.BINARY(e2,DAE.MUL(tp),
                       DAE.BINARY(e1,DAE.POW(tp),DAE.RCONST(r))),
                       DAE.MUL(tp),de1);
      then
        (e, funcs);
    // x^i
  case (DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.ICONST(integer = i))), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        i = i - 1;
        e = DAE.BINARY(DAE.BINARY(e2,DAE.MUL(tp),
                       DAE.BINARY(e1,DAE.POW(tp),DAE.ICONST(i))),
                       DAE.MUL(tp),de1);
      then
        (e, funcs);
    // der(0^x) = 0
    case (DAE.BINARY(exp1 = (DAE.RCONST(real=0.0)),operator = DAE.POW(tp)), _, _, _, _)
      equation
        (zero, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        (zero, inFunctionTree);

    // der(r^x)  = r^x*ln(r)*der(x)
    case (e0 as DAE.BINARY(exp1 = DAE.RCONST(real=r),operator = DAE.POW(tp),exp2 = e1), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        r = log(r);
        e = DAE.BINARY(DAE.BINARY(e0,DAE.MUL(tp),DAE.RCONST(r)),DAE.MUL(tp),de1);
      then
        (e, funcs);

    // der(x^y) = x^(y-1) * ( x*ln(x)*der(y)+(y*der(x)))
    // if x == 0 then 0;
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(tp), exp2 = e2), _, _, _, _)
      equation
        (de1, funcs) = differentiateExp(e1, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (de2, funcs) = differentiateExp(e2, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        etmp = Expression.makePureBuiltinCall("log", {e1}, tp);
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
  output DAE.Exp outDiffedExp;
  output DAE.FunctionTree outFunctionTree;
algorithm
  (outDiffedExp, outFunctionTree) :=
    matchcontinue(inExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree)
    local

      BackendDAE.DifferentiateInputData inputData, diffFuncData;

      DAE.Exp e, zero;
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

      list<DAE.Element> funcbody, funcbodyDer;
      list<DAE.Element> inputVars, inputVarsNoDer, inputVarsDer;
      list<DAE.Element> outputVars, outputVarsNoDer, outputVarsDer;
      list<DAE.Element> protectedVars, protectedVarsNoDer, protectedVarsDer, newProtectedVars;
      list<DAE.Statement> bodyStmts, derbodyStmts;

      DAE.FunctionDefinition derfuncdef;
      DAE.Function func,dfunc;
      list<DAE.Function> fns;
      String funcname, s1;
      list<DAE.FuncArg> falst;

    case (DAE.CALL(path=path,expLst=expl,attr=DAE.CALL_ATTR(tuple_=b,builtin=c,isImpure=isImpure,ty=ty,tailCall=tc)), _, _, BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        // get function mapper
        //print("Search for function mapper\n");
        (mapper, tp) = getFunctionMapper(path, inFunctionTree);
        (dpath, blst) = differentiateFunction1(path,mapper, tp, expl, (inDiffwrtCref, inInputData, inDiffType, inFunctionTree));
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAEUtil.avlTreeGet(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (true,_) = checkDerivativeFunctionInputs(blst, tp, dtp);
        (expl1,_) = List.splitOnBoolList(expl, blst);
        (dexpl, outFunctionTree) = List.map3Fold(expl1, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        expl1 = listAppend(expl,dexpl);
      then
        (DAE.CALL(dpath,expl1,DAE.CALL_ATTR(ty,b,c,isImpure,false,dinl,tc)),outFunctionTree);

    case (DAE.CALL(path=path,expLst=expl), _, _, BackendDAE.DIFFERENTIATION_TIME(), _)
      equation
        // get function mapper
        //print("Search for function mapper2\n");
        (mapper, tp) = getFunctionMapper(path, inFunctionTree);
        (dpath, blst) = differentiateFunction1(path, mapper, tp, expl, (inDiffwrtCref, inInputData, inDiffType, inFunctionTree));
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (false, tlst) = checkDerivativeFunctionInputs(blst, tp, dtp);
        // add Warning
        typlststring = List.map(tlst, Types.unparseType);
        typstring = "\n" + stringDelimitList(typlststring,";\n");
        dastring = Absyn.pathString(dpath);
        print("Input warnings for function mapper2\n");
        Error.addMessage(Error.UNEXPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});
      then
        fail();

    // try to inline
    case (DAE.CALL(attr=DAE.CALL_ATTR(builtin=false)), _, _, _, _)
      equation
        failure(BackendDAE.DIFF_FULL_JACOBIAN() = inDiffType);
        (e,_,true) = Inline.forceInlineExp(inExp,(SOME(inFunctionTree),{DAE.NORM_INLINE(),DAE.NO_INLINE()}),DAE.emptyElementSource);
        e = Expression.addNoEventToRelations(e);
        (e, functions) = differentiateExp(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      then
        (e, functions);

    //differentiate function partial
    case (e as DAE.CALL(), _, _, _, _)
      equation
        (e, functions) = differentiateFunctionCallPartial(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        (e,_,_,_) = Inline.inlineExp(e,(SOME(functions),{DAE.NORM_INLINE(),DAE.NO_INLINE()}),DAE.emptyElementSource);
      then
        (e, functions);

    case (_, _, _, _, _)
      equation
        false = Expression.expContains(inExp, Expression.crefExp(inDiffwrtCref))
        "If the expression does not contain the variable,
         the derivative is zero. For efficiency reasons this rule
         is last. Otherwise expressions is always traversed twice
         when differentiating.";
        tp = Expression.typeof(inExp);
        zero = Expression.createZeroExpression(tp);
      then
        (zero, inFunctionTree);

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
      DAE.Dimensions dims;

    case (DAE.CALL(path=path,expLst=expl,attr=DAE.CALL_ATTR(tuple_=b,builtin=c,isImpure=isImpure,ty=ty,tailCall=tc)), _, _, _, _)
      equation
        // get function mapper
        //print("Search for function mapper\n");
        (mapper, tp) = getFunctionMapper(path, inFunctionTree);
        (dpath, blst) = differentiateFunction1(path,mapper, tp, expl, (inDiffwrtCref, inInputData, inDiffType, inFunctionTree));
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAEUtil.avlTreeGet(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (true,_) = checkDerivativeFunctionInputs(blst, tp, dtp);
        (expl1,_) = List.splitOnBoolList(expl, blst);
        (dexpl, functions) = List.map3Fold(expl1, differentiateExp, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
        funcname = Util.modelicaStringToCStr(Absyn.pathString(path), false);
        diffFuncData = BackendDAE.DIFFINPUTDATA(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(funcname));
        (dexplZero, functions) = List.map3Fold(expl1, differentiateExp, DAE.CREF_IDENT("$",DAE.T_REAL_DEFAULT,{}), diffFuncData, BackendDAE.GENERIC_GRADIENT(), functions);
        //dexpl = listAppend(expl, dexpl);
        //print("Start creation of partial Der\n");
        //print("Diffed ExpList: \n");
        //print(stringDelimitList(List.map(dexpl, ExpressionDump.printExpStr), ", ") + "\n");
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
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(inFunctionTree, dpath);
        // check if derivativ function has all expected inputs
        (false, tlst) = checkDerivativeFunctionInputs(blst, tp, dtp);
        // add Warning
        typlststring = List.map(tlst, Types.unparseType);
        typstring = "\n" + stringDelimitList(typlststring,";\n");
        dastring = Absyn.pathString(dpath);
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
        SOME(func) = DAEUtil.avlTreeGet(inFunctionTree,path);

        // differentiate function
        (dfunc, functions, blst) = differentiatePartialFunction(func, inDiffwrtCref, NONE(), inInputData, inDiffType, inFunctionTree);

        dpath = DAEUtil.functionName(dfunc);
        // debug
        //funstring = Tpl.tplString(DAEDumpTpl.dumpFunction, dfunc);
        //print("\n\nDER.Function: \n" + funstring + "\n\n");

        functions = DAEUtil.addDaeFunction({dfunc}, functions);
        // add differentiated function as function mapper
        func = DAEUtil.addFunctionDefinition(func, DAE.FUNCTION_DER_MAPPER(path, dpath, 1, {}, NONE(), {}));
        functions = DAEUtil.avlTreeAdd(functions, path, SOME(func));

        // debug
        // differentiate expl
        //print("Finished differentiate Expression in Call.\n");
        //print("DER.Function call : \n" + ExpressionDump.printExpStr(e) + "\n");
        //print("Diff ExpList: \n");
        //print(stringDelimitList(List.map(expl, ExpressionDump.printExpStr), ", ") + "\n");
        //print("Diff ExpList Types: \n");
        //print(stringDelimitList(List.map(List.map(expl, Expression.typeof), Types.printTypeStr), " | ") + "\n");


        // create differentiated call arguments
        expBoolLst = List.threadTuple(expl, blst);
        expBoolLst = List.filterOnTrue(expBoolLst, Util.tuple22);
        expl1 = List.map(expBoolLst, Util.tuple21);
        (dexpl, functions) = List.map3Fold(expl1, differentiateExp, inDiffwrtCref, inInputData, inDiffType, functions);
        (dexplZero, functions) = List.map3Fold(expl1, differentiateExp, DAE.CREF_IDENT("$",DAE.T_REAL_DEFAULT,{}), inInputData, BackendDAE.GENERIC_GRADIENT(), functions);
        //dexpl = listAppend(expl, dexpl);
        //print("Start creation of partial Der\n");
        //print("Diffed ExpList: \n");
        //print(stringDelimitList(List.map(dexpl, ExpressionDump.printExpStr), ", ") + "\n");
        //print(" output Type: "  + Types.printTypeStr(ty) + "\n");
        e = DAE.CALL(dpath,dexpl,DAE.CALL_ATTR(ty,b,false,isImpure,false,DAE.NO_INLINE(),tc));
        exp = createPartialArguments(ty, dexpl, dexplZero, expl, e);

        // debug
        //print("Finished differentiate Expression in Call.\n");
        //print("DER.Function call : \n" + ExpressionDump.printExpStr(e) + "\n");

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

protected function createPartialArguments
  input DAE.Type outputType;
  input list<DAE.Exp> inArgs;
  input list<DAE.Exp> inDiffedArgs;
  input list<DAE.Exp> inOrginalExpl;
  input DAE.Exp inCall;
  output DAE.Exp outExp;
algorithm
  outExp := match(outputType, inArgs, inDiffedArgs, inOrginalExpl, inCall)
    local
      Absyn.Path path;
      DAE.CallAttributes attr;
      list<list<DAE.Exp>> rest;
      list<DAE.Exp> expLst, restDiff;
      DAE.Exp ezero, e;
      DAE.Dimensions dims;
      list<DAE.Type> tys;

    case (DAE.T_TUPLE(types = tys), _, _, _, _) equation
      expLst = createPartialArgumentsTuple(tys, inArgs, inDiffedArgs, inOrginalExpl, 1, inCall, {});
    then DAE.TUPLE(expLst);

    case (_, _, _, _, _) equation
      dims = Expression.arrayDimension(outputType);
      (ezero,_) = Expression.makeZeroExpression(dims);
      e = createPartialDifferentiatedExp(inArgs, inDiffedArgs, inOrginalExpl, inCall, 1, ezero);
    then e;
  end match;
end createPartialArguments;

protected function createPartialArgumentsTuple
  input list<DAE.Type> inTypesLst;
  input list<DAE.Exp> inArgs;
  input list<DAE.Exp> inDiffedArgs;
  input list<DAE.Exp> inOrginalExpl;
  input Integer number;
  input DAE.Exp inCall;
  input list<DAE.Exp> inAccum;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match(inTypesLst, inArgs, inDiffedArgs, inOrginalExpl, number, inCall, inAccum)
    local
      list<DAE.Type> expTypes;
      DAE.Type tp;
      DAE.Exp e, res;

    case ({}, _, _, _, _, _, _)
    then listReverse(inAccum);

    case (tp::expTypes, _, _, _, _, _, _) equation
      res = DAE.TSUB(inCall, number, tp);
      e = createPartialArguments(tp, inArgs, inDiffedArgs, inOrginalExpl, res);
    then createPartialArgumentsTuple(expTypes, inArgs, inDiffedArgs, inOrginalExpl, number+1, inCall, e::inAccum);
  end match;
end createPartialArgumentsTuple;

protected function createPartialDifferentiatedExp "
  generate an expresion with a sum partial derivatives."
  input list<DAE.Exp> inDiffExpl;
  input list<DAE.Exp> inDiffExplZero;
  input list<DAE.Exp> inOrginalExpl;
  input DAE.Exp inCall;
  input Integer currentLstElement;
  input DAE.Exp inAccum;
  output DAE.Exp outExp;
algorithm
  outExp := match(inDiffExpl, inDiffExplZero, inOrginalExpl, inCall, currentLstElement, inAccum)
    local
      DAE.Exp e, de, eone, eArray;
      list<DAE.Exp> rest;
      list<list<DAE.Exp>> arrayArgs;
      list<DAE.Exp> expl, expLst, dexpLst;
      DAE.Type tp;
      DAE.Dimensions dims;
      Integer i;
      Boolean b;

    case ({}, _, _, _, _, _)
    then inAccum;

    case ((DAE.ARRAY(ty = tp,scalar = b,array = expl))::rest, _, _, _, i, _) equation
      //print("createPartialDifferentiatedExp : i = " + intString(i) + "\n");
      eArray = listGet(inDiffExplZero, i);
      dexpLst = Expression.arrayElements(eArray);
      arrayArgs = prepareArgumentsExplArray(expl, dexpLst, 1, {});
      expLst = List.map2(arrayArgs, Expression.makeArray, tp, b);
      arrayArgs = List.map2r(expLst, List.set, inDiffExplZero, i);
      arrayArgs = List.map1r(arrayArgs, listAppend, inOrginalExpl);
      e = createPartialSum(arrayArgs, expl, inCall, inAccum);

      e = createPartialDifferentiatedExp(rest, inDiffExplZero, inOrginalExpl, inCall, i+1, e);
    then e;

    case (de::rest, _, _, _, i, _) equation
      tp = Expression.typeof(de);
      dims = Expression.arrayDimension(tp);
      (eone,_) = Expression.makeOneExpression(dims);
      //print("createPartialDifferentiatedExp : i = " + intString(currentLstElement) + "\n");
      dexpLst = List.set(inDiffExplZero, i, eone);
      expLst = listAppend(inOrginalExpl,dexpLst);
      e = createPartialSum({expLst}, {de}, inCall, inAccum);
      e = createPartialDifferentiatedExp(rest, inDiffExplZero, inOrginalExpl, inCall, i+1, e);
    then e;
  end match;
end createPartialDifferentiatedExp;

protected function createPartialSum "
  generate an expresion with a sum partial derivatives"
  input list<list<DAE.Exp>> inArgsLst;
  input list<DAE.Exp> inDiff;
  input DAE.Exp inCall;
  input DAE.Exp inAccum;
  output DAE.Exp outExp;
algorithm
  outExp := match(inArgsLst, inDiff, inCall, inAccum)
    local
      Absyn.Path path;
      DAE.CallAttributes attr;
      list<list<DAE.Exp>> rest;
      list<DAE.Exp> expLst, restDiff;
      DAE.Exp de, res;
      DAE.Type ty;
      Integer ix;

    case ({}, _, _, _)
    then inAccum;

    case (expLst::rest, de::restDiff, DAE.TSUB(exp=DAE.CALL(path=path, attr=attr), ix =ix, ty=ty), _) equation
      res = DAE.TSUB(DAE.CALL(path, expLst, attr), ix, ty);
      res = Expression.expMul(de, res);
      res = Expression.expAdd(inAccum, res);
    then createPartialSum(rest, restDiff, inCall, res);

    case (expLst::rest, de::restDiff, DAE.CALL(path=path, attr=attr), _) equation
      res = DAE.CALL(path, expLst, attr);
      res = Expression.expMul(de, res);
      res = Expression.expAdd(inAccum, res);
    then createPartialSum(rest, restDiff, inCall, res);
  end match;
end createPartialSum;

protected function prepareArgumentsExplArray "
  generate an expresion with a sum partial derivatives"
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
  input Option<Absyn.Path> inDerFunctionName;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  output DAE.Function outDerFunction;
  output DAE.FunctionTree outFunctionTree;
  output list<Boolean> outBooleanlst;
algorithm
  (outDerFunction, outFunctionTree, outBooleanlst) := matchcontinue(inFunction, inDiffwrtCref, inDerFunctionName, inInputData, inDiffType, inFunctionTree)
    local
      BackendDAE.DifferentiateInputData inputData, diffFuncData;

      Absyn.Path path, dpath;
      Option<Absyn.Path> dpathOption;
      Boolean isImpure;
      DAE.InlineType dinl;
      DAE.FunctionTree functions;
      DAE.Type tp, dtp;
      String  str;

      list<DAE.Element> funcbody, funcbodyDer;
      list<DAE.Element> inputVars, inputVarsNoDer, inputVarsDer;
      list<DAE.Element> outputVars, outputVarsNoDer, outputVarsDer;
      list<DAE.Element> protectedVars, protectedVarsNoDer, protectedVarsDer, newProtectedVars;
      list<DAE.Statement> bodyStmts, derbodyStmts;

      DAE.Function func,dfunc;

      String funcname;
      DAE.ComponentRef diffwrtCref;
      list<DAE.ComponentRef> diffwrtCrefs;
      list<Boolean> blst;
      SCode.Visibility visibility;

    // differentiate function
    case (func, _, dpathOption, _, _, _) equation
      // debug
      //funstring = Tpl.tplString(DAEDumpTpl.dumpFunction, func);
      //print("\n\ndifferentiate differentiateFunctionCallPartial: \n" + funstring + "\n");

      inputVars = DAEUtil.getFunctionInputVars(func);
      outputVars =  DAEUtil.getFunctionOutputVars(func);
      protectedVars  = DAEUtil.getFunctionProtectedVars(func);
      bodyStmts = DAEUtil.getFunctionAlgorithmStmts(func);
      visibility = DAEUtil.getFunctionVisibility(func);

      path = DAEUtil.functionName(func);
      funcname = Util.modelicaStringToCStr(Absyn.pathString(path), false);
      diffFuncData = BackendDAE.DIFFINPUTDATA(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(funcname));

      (inputVarsDer, functions, inputVarsNoDer, blst) = differentiateElementVars(inputVars, inDiffwrtCref, diffFuncData, BackendDAE.DIFFERENTIATION_FUNCTION(), inFunctionTree, {}, {}, {});
      (outputVarsDer, functions, outputVarsNoDer, _) = differentiateElementVars(outputVars, inDiffwrtCref, diffFuncData, BackendDAE.DIFFERENTIATION_FUNCTION(), functions, {}, {}, {});

      //add protected variables to dependent Vars
      (inputData,_) = addElementVars2Dep(inputVarsNoDer, functions, diffFuncData);
      (inputData,_) = addElementVars2Dep(outputVarsNoDer, functions, inputData);

      (protectedVarsDer, functions, protectedVarsNoDer, _) = differentiateElementVars(protectedVars, inDiffwrtCref, inputData, BackendDAE.DIFFERENTIATION_FUNCTION(), functions, {}, {}, {});

      //add protected variables to dependent Vars
      (inputData,_) = addElementVars2Dep(protectedVarsNoDer, functions, inputData);

      // differentiate algorithm statemeants
      //print("Function diff: statemeants");
      (derbodyStmts, functions) = differentiateStatements(listReverse(bodyStmts), inDiffwrtCref, inputData, BackendDAE.DIFFERENTIATION_FUNCTION(), {}, functions);

      // create function and add it to function tree
      dpath = Util.getOptionOrDefault(dpathOption, Absyn.stringPath("$DER" + funcname));

      tp = DAEUtil.getFunctionType(func);
      dtp = Types.extendsFunctionTypeArgs(tp, inputVarsDer, blst);

      inputVars = listAppend(inputVars, inputVarsDer);
      protectedVars = listAppend(protectedVars, protectedVarsDer);
      funcbodyDer = listAppend(inputVars, outputVarsDer);
      funcbodyDer = listAppend(funcbodyDer, protectedVars);

      //change output vars to protected vars and direction bidir
      newProtectedVars = List.map1(outputVars, DAEUtil.setElementVarVisibility, DAE.PROTECTED());
      newProtectedVars = List.map1(newProtectedVars, DAEUtil.setElementVarDirection, DAE.BIDIR());
      funcbodyDer = listAppend(funcbodyDer, newProtectedVars);

      funcbodyDer = listAppend(funcbodyDer, {DAE.ALGORITHM(DAE.ALGORITHM_STMTS(derbodyStmts), DAE.emptyElementSource)});

      isImpure = DAEUtil.getFunctionImpureAttribute(func);
      dinl = DAEUtil.getFunctionInlineType(func);
      dfunc = DAE.FUNCTION(dpath, {DAE.FUNCTION_DEF(funcbodyDer)}, dtp, visibility, false, isImpure, dinl, DAE.emptyElementSource, NONE());
    then (dfunc, functions, blst);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        path = DAEUtil.functionName(inFunction);
        str = "\nDifferentiate.differentiatePartialFunction failed for function: " + Absyn.pathString(path) + "\n";
        Debug.trace(str);
      then fail();
  end matchcontinue;
end differentiatePartialFunction;

protected function differentiateElementVars
  input list<DAE.Element> inElements;   // in as DAE.VAR(_)
  input DAE.ComponentRef inDiffwrtCref;
  input BackendDAE.DifferentiateInputData inInputData;
  input BackendDAE.DifferentiationType inDiffType;
  input DAE.FunctionTree inFunctionTree;
  input list<DAE.Element>  inElementsDer;
  input list<DAE.Element>  inElementsNoDer;
  input list<Boolean>  inBooleanLst;
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

    case ({}, _, _, _, _, _, _, _)
    then (inElementsDer, inFunctionTree, inElementsNoDer, inBooleanLst);

    case ((var as DAE.VAR(componentRef = cref, ty= (DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD()))))::rest, _, _, _, _, _, _, _) equation
      _ = Expression.crefExp(cref);
      //ExpressionDump.printExp(e);
      crefLst = List.map1(varLst,Expression.generateCrefsFromExpVar,cref);
      tpLst = List.map(varLst,Types.getVarType);
      // ComponentReference.printComponentRefList(crefLst);

      newVars = List.threadMap1(crefLst, tpLst, DAEUtil.replaceCrefandTypeInVar, var);

      elementsNoDer = listAppend(inElementsNoDer, newVars);
      blst = listAppend(inBooleanLst, {false});
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, inElementsDer, elementsNoDer, blst);
    then (vars, functions, elementsNoDer, blst);

    case((var as DAE.VAR(binding=SOME(binding)))::rest, _, BackendDAE.DIFFINPUTDATA(independenentVars=SOME(timevars)), _, _, _, _, _) equation
      // check if bindung depends on independentVars
      crefLst = Expression.extractCrefsFromExp(binding);
      ({},{}) = BackendVariable.getVarLst(crefLst, timevars, {}, {});

      vars = listAppend(inElementsNoDer, {var});
      blst = listAppend(inBooleanLst, {false});
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, inElementsDer, vars, blst);
    then (vars, functions, elementsNoDer, blst);

    case((var1 as DAE.VAR(componentRef = cref, ty=tp, binding=SOME(binding)))::rest, _, _, _, _, _, _, _) equation
      true = Types.isRealOrSubTypeReal(tp);
      e = Expression.crefExp(cref);
      (e, functions) = differentiateCrefs(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      dcref = Expression.expCref(e);
      var = DAEUtil.replaceCrefInVar(dcref, var1);
      (dbinding, functions) = differentiateExp(binding, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      var = DAEUtil.replaceBindungInVar(dbinding, var);
      vars = listAppend(inElementsDer, {var});
      blst = listAppend(inBooleanLst, {true});
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, functions, vars, inElementsNoDer, blst);
    then (vars, functions, elementsNoDer, blst);

    case((var1 as DAE.VAR(componentRef = cref, ty=tp))::rest, _, _, _, _, _, _, _) equation
      true = Types.isRealOrSubTypeReal(tp);
      e = Expression.crefExp(cref);
      (e, functions) = differentiateCrefs(e, inDiffwrtCref, inInputData, inDiffType, inFunctionTree);
      dcref = Expression.expCref(e);
      var = DAEUtil.replaceCrefInVar(dcref, var1);
      vars = listAppend(inElementsDer, {var});
      blst = listAppend(inBooleanLst, {true});
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, functions, vars, inElementsNoDer, blst);
    then (vars, functions, elementsNoDer, blst);

    case((var as DAE.VAR())::rest, _, _, _, _, _, _, _) equation
      elementsNoDer = listAppend(inElementsNoDer, {var});
      blst = listAppend(inBooleanLst, {false});
      (vars, functions, elementsNoDer, blst) = differentiateElementVars(rest, inDiffwrtCref, inInputData, inDiffType, inFunctionTree, inElementsDer, elementsNoDer, blst);
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
      equation
         true = intEq(1,derivativeOrder);
         tplst = List.map(funcArg,Types.funcArgType);
         ba = Array.mapList(tplst, Types.isRealOrSubTypeReal);
         bl = checkDerFunctionConds(ba,cr,expl,inDiffArgs);
      then
        (inDFuncName,bl);
    // check conditions, order>1
    case (_,DAE.FUNCTION_DER_MAPPER(derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr),tp,_,(_,_,_,functions))
      equation
         failure(true = intEq(1,derivativeOrder));
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
          (e, functionTree) := differentiateExp(e, diffwrtCref, inputData, diffType, functionTree);
          true := Expression.isZero(e);
        then
          ();

      case DAE.NO_DERIVATIVE(binding = DAE.CALL(path = p1))
        algorithm
          // Get expression.
          DAE.CALL(path = p2) := listGet(expl, i);
          true := Absyn.pathEqual(p1, p2);
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
          SOME(DAE.FUNCTION(functions=flst)) = DAEUtil.avlTreeGet(functions,fname);
          DAE.FUNCTION_DER_MAPPER(lowerOrderDerivatives=lowerOrderDerivatives) = getFunctionMapper1(flst);
          name = List.last(lowerOrderDerivatives);
      then name;
  end match;
end getlowerOrderDerivative;

protected function getFunctionMapper "Author: Frenkel TUD"
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
        SOME(DAE.FUNCTION(functions=flst,type_=t)) = DAEUtil.avlTreeGet(functions,fname);
        m = getFunctionMapper1(flst);
      then (m,t);
    case (_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s = Absyn.pathString(fname);
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

//
// util functions for Types: DifferentiateInputData, DifferentiateInputArguments, DifferentiationType
//

protected function addDependentVars
  input list<BackendDAE.Var> inVarsLst;
  input BackendDAE.DifferentiateInputData inDiffData;
  output BackendDAE.DifferentiateInputData outDiffData;
algorithm
  outDiffData := match(inVarsLst, inDiffData)
  local
    Option<BackendDAE.Variables> indepVars, knownVars, allVars;
    BackendDAE.Variables depVars;
    Option<list< BackendDAE.Var>> algVars;
    Option<list< .DAE.ComponentRef>> diffCrefs;
    Option<String> diffname;

    case ({}, _)
    then inDiffData;

    case (_, BackendDAE.DIFFINPUTDATA(indepVars, SOME(depVars), knownVars, allVars, algVars, diffCrefs, diffname)) equation
      depVars = BackendVariable.addVars(inVarsLst, depVars);
      //BackendDump.dumpVariables(depVars, "dep Vars: ");
    then BackendDAE.DIFFINPUTDATA(indepVars, SOME(depVars), knownVars, allVars, algVars, diffCrefs, diffname);

    case (_, BackendDAE.DIFFINPUTDATA(indepVars, NONE(), knownVars, allVars, algVars, diffCrefs, diffname)) equation
      depVars = BackendVariable.listVar(inVarsLst);
      //BackendDump.dumpVariables(depVars, "dep Vars: ");
    then BackendDAE.DIFFINPUTDATA(indepVars, SOME(depVars), knownVars, allVars, algVars, diffCrefs, diffname);
  end match;
end addDependentVars;

protected function addAllVars
  input list<BackendDAE.Var> inVarsLst;
  input BackendDAE.DifferentiateInputData inDiffData;
  output BackendDAE.DifferentiateInputData outDiffData;
algorithm
  outDiffData := match(inVarsLst, inDiffData)
    local
      Option<BackendDAE.Variables> depVars, knownVars, indepVars;
      BackendDAE.Variables allVars;
      Option<list< BackendDAE.Var>> algVars;
      Option<list< .DAE.ComponentRef>> diffCrefs;
      Option<String> diffname;

    case ({}, _)
    then inDiffData;

    case (_, BackendDAE.DIFFINPUTDATA(indepVars, depVars, knownVars, SOME(allVars), algVars, diffCrefs, diffname)) equation
      allVars = BackendVariable.addVars(inVarsLst, allVars);
      //BackendDump.dumpVariables(allVars, "indep Vars: ");
    then BackendDAE.DIFFINPUTDATA(indepVars, depVars, knownVars, SOME(allVars), algVars, diffCrefs, diffname);

    case (_, BackendDAE.DIFFINPUTDATA(indepVars, depVars, knownVars, NONE(), algVars, diffCrefs, diffname)) equation
      allVars = BackendVariable.listVar(inVarsLst);
      //BackendDump.dumpVariables(allVars, "indep Vars: ");
    then BackendDAE.DIFFINPUTDATA(indepVars, depVars, knownVars, SOME(allVars), algVars, diffCrefs, diffname);
  end match;
end addAllVars;

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
  input DAE.FunctionTree functions;
  input BackendDAE.DifferentiateInputData inDiffData;
  output BackendDAE.DifferentiateInputData outDiffData;
  output list< BackendDAE.Equation> eqnsLst;
algorithm
  (outDiffData, eqnsLst) := matchcontinue(inElementLstVars, functions, inDiffData)
  local
    BackendDAE.Variables indepVars, vars, knvars, exvars;
    list<BackendDAE.Equation> eqns;
    list< BackendDAE.Var> varsLst;
    String str;
    case (_, _, _)
      equation
        (varsLst, eqns) = lowerVarsElementVars(inElementLstVars, functions);
      then (addDependentVars(varsLst, inDiffData), eqns);
    else
       equation
        str = "Differentiate.addElementVars2Dep failed";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end addElementVars2Dep;

annotation(__OpenModelica_Interface="backend");
end Differentiate;
