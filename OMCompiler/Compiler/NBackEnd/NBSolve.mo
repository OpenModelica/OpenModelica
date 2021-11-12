/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBSolve
" file:         NBSolve.mo
  package:      NBSolve
  description:  This file contains all functions for the solving process.
"
public
  // OF imports
  import AvlSetPath;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTree;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;

  // backend imports
  import Differentiate = NBDifferentiate;
  import NBEquation.Equation;
  import Replacements = NBReplacements;

  type Status = enumeration(UNPROCESSED, EXPLICIT, IMPLICIT, UNSOLVABLE);

  function solve
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
    output Status status;
    output Boolean invertRelation     "If the equation represents a relation, this tells if the sign should be inverted";
  protected
    Expression residual, derivative;
    Differentiate.DifferentiationArguments diffArgs;
    Operator divOp, uminOp;
    Type ty;
  algorithm
    (eqn, status, invertRelation) := solveSimple(eqn, cref);
    // if the equation does not have a simple structure try to solve with other strategies
    if status == Status.UNPROCESSED then
      residual := Equation.getResidualExp(eqn);
      diffArgs := Differentiate.DIFFERENTIATION_ARGUMENTS(
        diffCref        = cref,
        new_vars        = {},
        jacobianHT      = NONE(),
        diffType        = NBDifferentiate.DifferentiationType.SIMPLE,
        funcTree        = funcTree,
        diffedFunctions = AvlSetPath.new()
      );
      (derivative, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
      derivative := SimplifyExp.simplify(derivative);

      if Expression.isZero(derivative) then
        invertRelation := false;
        status := Status.UNSOLVABLE;
      elseif not Expression.containsCref(derivative, cref) then
        // If eqn is linear in cref:
        (eqn, funcTree) := solveLinear(eqn, residual, derivative, diffArgs, cref, funcTree);
        // If the derivative is negative, invert possible inequality sign
        invertRelation := Expression.isNegative(derivative);
        status := Status.EXPLICIT;
      else
        // If eqn is non-linear in cref
        if Flags.isSet(Flags.FAILTRACE) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to solve Cref: "
            + ComponentRef.toString(cref) + " in equation:\n" + Equation.toString(eqn)});
        end if;
        invertRelation := false;
        status := Status.IMPLICIT;
      end if;
    end if;
    eqn := Equation.simplify(eqn, getInstanceName());
  end solve;

protected
  function solveSimple
    input output Equation eqn;
    input ComponentRef cref;
    output Status status;
    output Boolean invertRelation;
  algorithm
    (eqn, status, invertRelation) := match eqn
      local
        ComponentRef lhs, rhs;

      case Equation.SCALAR_EQUATION(lhs = Expression.CREF(cref = lhs))
        guard(ComponentRef.isEqual(cref, lhs) and not Expression.containsCref(eqn.rhs, cref))
      then (eqn, Status.EXPLICIT, false);

      case Equation.SCALAR_EQUATION(rhs = Expression.CREF(cref = rhs))
        guard(ComponentRef.isEqual(cref, rhs) and not Expression.containsCref(eqn.lhs, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      case Equation.ARRAY_EQUATION(lhs = Expression.CREF(cref = lhs))
        guard(ComponentRef.isEqual(cref, lhs) and not Expression.containsCref(eqn.rhs, cref))
      then (eqn, Status.EXPLICIT, false);

      case Equation.ARRAY_EQUATION(rhs = Expression.CREF(cref = rhs))
        guard(ComponentRef.isEqual(cref, rhs) and not Expression.containsCref(eqn.lhs, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      // we do not check for x = x because that is nonsensical
      case Equation.SIMPLE_EQUATION()
        guard(ComponentRef.isEqual(cref, eqn.lhs))
      then (eqn, Status.EXPLICIT, false);

      case Equation.SIMPLE_EQUATION()
        guard(ComponentRef.isEqual(cref, eqn.rhs))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      case Equation.RECORD_EQUATION(lhs = Expression.CREF(cref = lhs))
        guard(ComponentRef.isEqual(cref, lhs) and not Expression.containsCref(eqn.rhs, cref))
      then (eqn, Status.EXPLICIT, false);

      case Equation.RECORD_EQUATION(rhs = Expression.CREF(cref = rhs))
        guard(ComponentRef.isEqual(cref, rhs) and not Expression.containsCref(eqn.lhs, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      case Equation.WHEN_EQUATION() then (eqn, Status.EXPLICIT, false); // ToDo: need to check if implicit

      // ToDo: more cases

      else (eqn, Status.UNPROCESSED, false);
    end match;
  end solveSimple;

  function solveLinear
    "author: kabdelhak, phannebohm
    solves a linear equation with one newton step
    0 = f(x)  ---> x = -f(0)/f`(0)"
    input output Equation eqn;
    input Expression residual;
    input Expression derivative;
    input Differentiate.DifferentiationArguments diffArgs;
    input ComponentRef cref;
    input output FunctionTree funcTree;
  protected
    Expression crefExp, numerator;
    Operator mulOp, uminOp;
    Type ty;
  algorithm
    funcTree := diffArgs.funcTree;
    crefExp := Expression.fromCref(cref);
    ty := ComponentRef.getSubscriptedType(cref);
    numerator := Replacements.single(residual, crefExp, Expression.makeZero(ty));
    mulOp := Operator.OPERATOR(ty, NFOperator.Op.MUL);
    uminOp := Operator.OPERATOR(ty, NFOperator.Op.UMINUS);
    // Set eqn: cref = - f/f'
    eqn := Equation.setLHS(eqn, crefExp);
    eqn := Equation.setRHS(eqn, Expression.UNARY(uminOp, Expression.MULTARY({numerator},{derivative}, mulOp)));
  end solveLinear;

  annotation(__OpenModelica_Interface="backend");
end NBSolve;
