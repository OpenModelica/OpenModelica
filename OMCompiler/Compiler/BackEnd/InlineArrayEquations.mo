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

encapsulated package InlineArrayEquations
" file:        InlineArrayEquations.mo
  package:     InlineArrayEquations
  description: This package contains functions for the optimization module
               inlineArrayEqn."


public import BackendDAE;
public import DAE;

protected import BackendDAEUtil;
protected import BackendEquation;
protected import DAEUtil;
protected import Debug;
protected import ElementSource;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;

// =============================================================================
// inline arrayeqns stuff
//
// public functions:
//   - inlineArrayEqn
//   - getScalarArrayEqns
// =============================================================================

public function inlineArrayEqn "
  Optimization module: inlineArrayEqn
  This module expands all array equations to scalar equations."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, inlineArrayEqn1, false);
end inlineArrayEqn;

protected function inlineArrayEqn1
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.Shared inShared;
  input Boolean inOptimized;
  output BackendDAE.EqSystem outEqSystem;
  output BackendDAE.Shared outShared = inShared "unused";
  output Boolean outOptimized;
algorithm
  (outEqSystem, outOptimized) := matchcontinue inEqSystem
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> eqnLst;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) equation
      eqnLst = BackendEquation.equationList(orderedEqs);
      (eqnLst, true) = getScalarArrayEqns(eqnLst);
      orderedEqs = BackendEquation.listEquation(eqnLst);
    then (BackendDAEUtil.clearEqSyst(BackendDAEUtil.setEqSystEqs(inEqSystem, orderedEqs)), true);

    else (inEqSystem, inOptimized);
  end matchcontinue;
end inlineArrayEqn1;

public function getScalarArrayEqns "
  Public wrapper function of getScalarArrayEqns0."
  input list<BackendDAE.Equation> inEqnLst;
  output list<BackendDAE.Equation> outEqnLst;
  output Boolean outFound;
algorithm
  (outEqnLst, outFound) := getScalarArrayEqns0(inEqnLst, {}, false);
end getScalarArrayEqns;

protected function getScalarArrayEqns0 "
  This functions does the actual work for the optimization module 'inlineArrayEqn'.
  This function is also called from the index reduction."
  input list<BackendDAE.Equation> inEqnLst;
  input list<BackendDAE.Equation> inAccEqnLst "initial call with '{}'";
  input Boolean inFound "initial call with 'false'";
  output list<BackendDAE.Equation> outEqnLst;
  output Boolean outFound;
algorithm
  (outEqnLst, outFound) := match(inEqnLst, inAccEqnLst, inFound)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns, eqns1;
      Boolean b;

    case ({}, _, _)
    then (listReverse(inAccEqnLst), inFound);

    case (eqn::eqns, _, _) equation
      (eqns1, b) = getScalarArrayEqns1(eqn, inAccEqnLst);
      (eqns1, b) = getScalarArrayEqns0(eqns, eqns1, b or inFound);
    then (eqns1, b);
  end match;
end getScalarArrayEqns0;

protected function getScalarArrayEqns1
  input BackendDAE.Equation inEqn;
  input list<BackendDAE.Equation> inAccEqnLst;
  output list<BackendDAE.Equation> outEqnLst;
  output Boolean outFound;
algorithm
  (outEqnLst, outFound) := matchcontinue inEqn
    local
      DAE.ElementSource source;
      DAE.Exp lhs, rhs, e1, e2;
      list<DAE.Exp> ea1, ea2;
      list<BackendDAE.Equation> eqns;
      BackendDAE.EquationAttributes attr;
      DAE.Exp e1_1, e2_1;

    case BackendDAE.ARRAY_EQUATION(left = lhs, right = rhs, source = source, attr = attr)
      algorithm
        if Expression.isArray(lhs) or Expression.isMatrix(lhs) then
          ea1 := Expression.flattenArrayExpToList(lhs);
        else
          e1 := Expression.extendArrExp(lhs);
          e1 := ExpressionSimplify.simplify(e1);
          true := Expression.isArray(e1) or Expression.isMatrix(e1);
          ea1 := Expression.flattenArrayExpToList(e1);
        end if;

        if Expression.isArray(rhs) or Expression.isMatrix(rhs) then
          ea2 := Expression.flattenArrayExpToList(rhs);
        else
          e2 := Expression.extendArrExp(rhs);
          e2 := ExpressionSimplify.simplify(e2);
          true := Expression.isArray(e2) or Expression.isMatrix(e2);
          ea2 := Expression.flattenArrayExpToList(e2);
        end if;

        ((_, eqns)) := List.threadFold3(ea1, ea2, generateScalarArrayEqns2,
          source, attr, DAE.EQUALITY_EXPS(lhs, rhs), (1, inAccEqnLst));
      then
        (eqns, true);

    case BackendDAE.COMPLEX_EQUATION(left = lhs, right = rhs, source = source, attr = attr)
      algorithm
        ea1 := Expression.splitRecord(lhs, Expression.typeof(lhs));
        ea2 := Expression.splitRecord(rhs, Expression.typeof(rhs));
        ((_, eqns)) := List.threadFold3(ea1, ea2, generateScalarArrayEqns2,
          source, attr, DAE.EQUALITY_EXPS(lhs, rhs), (1, inAccEqnLst));
      then
        (eqns, true);

    else (inEqn :: inAccEqnLst, false);
  end matchcontinue;
end getScalarArrayEqns1;

protected function generateScalarArrayEqns2
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource inSource;
  input BackendDAE.EquationAttributes eqAttr;
  input DAE.EquationExp eqExp "original expressions; for the symbolic trace";
  input tuple<Integer /* current index; for the symbolic trace */, list<BackendDAE.Equation>> iEqns;
  output tuple<Integer, list<BackendDAE.Equation>> oEqns;
algorithm
  oEqns := matchcontinue iEqns
    local
      DAE.Type tp;
      Integer size, i;
      Option<Integer> recordSize;
      DAE.Dimensions dims;
      list<Integer> ds;
      Boolean b1, b2;
      list<BackendDAE.Equation> eqns;
      DAE.ElementSource source;

    // complex types to complex equations
    case (i, eqns) equation
      tp = Expression.typeof(inExp1);
      true = DAEUtil.expTypeComplex(tp);
      size = Expression.sizeOf(tp);
      source = ElementSource.addSymbolicTransformation(inSource, DAE.OP_SCALARIZE(eqExp, i, DAE.EQUALITY_EXPS(inExp1, inExp2)));
    then ((i+1, BackendDAE.COMPLEX_EQUATION(size, inExp1, inExp2, source, eqAttr)::eqns));

    // array types to array equations
    case (i, eqns) equation
      tp = Expression.typeof(inExp1);
      true = DAEUtil.expTypeArray(tp);
      dims = Expression.arrayDimension(tp);
      tp = DAEUtil.expTypeElementType(tp);
      if DAEUtil.expTypeComplex(tp) then
        recordSize = SOME(Expression.sizeOf(tp));
      else
        recordSize = NONE();
      end if;
      ds = Expression.dimensionsSizes(dims);
      source = ElementSource.addSymbolicTransformation(inSource, DAE.OP_SCALARIZE(eqExp, i, DAE.EQUALITY_EXPS(inExp1, inExp2)));
    then ((i+1, BackendDAE.ARRAY_EQUATION(ds, inExp1, inExp2, source, eqAttr, recordSize)::eqns));

    // other types
    case (i, eqns) equation
      tp = Expression.typeof(inExp1);
      b1 = DAEUtil.expTypeComplex(tp);
      b2 = DAEUtil.expTypeArray(tp);
      false = b1 or b2;
      source = ElementSource.addSymbolicTransformation(inSource, DAE.OP_SCALARIZE(eqExp, i, DAE.EQUALITY_EXPS(inExp1, inExp2)));
    then ((i+1, BackendDAE.EQUATION(inExp1, inExp2, source, eqAttr)::eqns));

    else equation
      // show only on failtrace!
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("- InlineArrayEquations.generateScalarArrayEqns2 failed on: " + ExpressionDump.printExpStr(inExp1) + " = " + ExpressionDump.printExpStr(inExp2) + "\n");
    then fail();
  end matchcontinue;
end generateScalarArrayEqns2;

annotation(__OpenModelica_Interface="backend");
end InlineArrayEquations;
