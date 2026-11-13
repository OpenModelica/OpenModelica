/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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

protected import Absyn;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import DAEUtil;
protected import Debug;
protected import ElementSource;
protected import Expression;
protected import ExpressionBasics;
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
      BackendDAE.EquationArray orderedEqs;
      list<BackendDAE.Equation> eqnLst;

    case BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) algorithm
      eqnLst := BackendEquation.equationList(orderedEqs);
      (eqnLst, true) := getScalarArrayEqns(eqnLst);
      orderedEqs := BackendEquation.listEquation(eqnLst);
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
  (outEqnLst, outFound) := match inEqnLst
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns, eqns1;
      Boolean b;

    case {}
    then (listReverse(inAccEqnLst), inFound);

    case eqn::eqns algorithm
      (eqns1, b) := getScalarArrayEqns1(eqn, inAccEqnLst);
      (eqns1, b) := getScalarArrayEqns0(eqns, eqns1, b or inFound);
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
      DAE.Exp lhs, rhs;
      list<DAE.Exp> ea1, ea2;
      list<BackendDAE.Equation> eqns;
      BackendDAE.EquationAttributes attr;

    case BackendDAE.ARRAY_EQUATION(left = lhs, right = rhs, source = source, attr = attr)
      algorithm
        ea1 := scalarizeArrayExp(lhs);
        ea2 := scalarizeArrayExp(rhs);

        (_, eqns) := List.threadFold3(ea1, ea2, generateScalarArrayEqns2,
          source, attr, DAE.EQUALITY_EXPS(lhs, rhs), (1, inAccEqnLst));
      then
        (eqns, true);

    case BackendDAE.COMPLEX_EQUATION(left = lhs, right = rhs, source = source, attr = attr)
      algorithm
        ea1 := Expression.splitRecord(lhs, Expression.typeof(lhs));
        ea2 := Expression.splitRecord(rhs, Expression.typeof(rhs));
        (_, eqns) := List.threadFold3(ea1, ea2, generateScalarArrayEqns2,
          source, attr, DAE.EQUALITY_EXPS(lhs, rhs), (1, inAccEqnLst));
      then
        (eqns, true);

    else (inEqn :: inAccEqnLst, false);
  end matchcontinue;
end getScalarArrayEqns1;

protected function scalarizeArrayExp
  "Returns the scalar elements of an array expression, fails if the expression
   can't be expanded. Array valued if-expressions and smooth/noEvent calls are
   expanded element-wise, e.g. `if c then {a, b} else {d, e}` becomes
   `{if c then a else d, if c then b else e}`."
  input DAE.Exp inExp;
  output list<DAE.Exp> outExps;
algorithm
  outExps := match inExp
    local
      DAE.Exp cond, e, e1, e2, p;
      list<DAE.Exp> ea1, ea2;

    case _ guard Expression.isArray(inExp) or Expression.isMatrix(inExp)
    then Expression.flattenArrayExpToList(inExp);

    case DAE.IFEXP(expCond = cond)
      algorithm
        ea1 := scalarizeArrayExp(inExp.expThen);
        ea2 := scalarizeArrayExp(inExp.expElse);
        true := listLength(ea1) == listLength(ea2);
      then list(DAE.IFEXP(cond, e1, e2) threaded for e1 in ea1, e2 in ea2);

    case DAE.CALL(path = Absyn.IDENT("smooth"), expLst = {p, e})
    then list(Expression.makePureBuiltinCall("smooth", {p, e1}, Expression.typeof(e1)) for e1 in scalarizeArrayExp(e));

    case DAE.CALL(path = Absyn.IDENT("noEvent"), expLst = {e})
    then list(Expression.makePureBuiltinCall("noEvent", {e1}, Expression.typeof(e1)) for e1 in scalarizeArrayExp(e));

    else
      algorithm
        e := Expression.extendArrExp(inExp);
        e := ExpressionSimplify.simplify(e);
        true := Expression.isArray(e) or Expression.isMatrix(e);
      then Expression.flattenArrayExpToList(e);
  end match;
end scalarizeArrayExp;

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
    case (i, eqns) algorithm
      tp := Expression.typeof(inExp1);
      true := DAEUtil.expTypeComplex(tp);
      size := Expression.sizeOf(tp);
      source := ElementSource.addSymbolicTransformation(inSource, DAE.OP_SCALARIZE(eqExp, i, DAE.EQUALITY_EXPS(inExp1, inExp2)));
    then ((i+1, BackendDAE.COMPLEX_EQUATION(size, inExp1, inExp2, source, eqAttr)::eqns));

    // array types to array equations
    case (i, eqns) algorithm
      tp := Expression.typeof(inExp1);
      true := DAEUtil.expTypeArray(tp);
      dims := Expression.arrayDimension(tp);
      tp := DAEUtil.expTypeElementType(tp);
      if DAEUtil.expTypeComplex(tp) then
        recordSize := SOME(Expression.sizeOf(tp));
      else
        recordSize := NONE();
      end if;
      ds := Expression.dimensionsSizes(dims);
      source := ElementSource.addSymbolicTransformation(inSource, DAE.OP_SCALARIZE(eqExp, i, DAE.EQUALITY_EXPS(inExp1, inExp2)));
    then ((i+1, BackendDAE.ARRAY_EQUATION(ds, inExp1, inExp2, source, eqAttr, recordSize)::eqns));

    // other types
    case (i, eqns) algorithm
      tp := Expression.typeof(inExp1);
      b1 := DAEUtil.expTypeComplex(tp);
      b2 := DAEUtil.expTypeArray(tp);
      false := b1 or b2;
      source := ElementSource.addSymbolicTransformation(inSource, DAE.OP_SCALARIZE(eqExp, i, DAE.EQUALITY_EXPS(inExp1, inExp2)));
    then ((i+1, BackendDAE.EQUATION(inExp1, inExp2, source, eqAttr)::eqns));

    else algorithm
      // show only on failtrace!
      true := Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("- InlineArrayEquations.generateScalarArrayEqns2 failed on: " + ExpressionBasics.printExpStr(inExp1) + " = " + ExpressionBasics.printExpStr(inExp2) + "\n");
    then fail();
  end matchcontinue;
end generateScalarArrayEqns2;

annotation(__OpenModelica_Interface="backend");
end InlineArrayEquations;
