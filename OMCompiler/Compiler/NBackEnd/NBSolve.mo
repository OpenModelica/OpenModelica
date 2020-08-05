/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
  import FunctionTree = NFFlatten.FunctionTree;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;

  // backend imports
  import Differentiate = NBDifferentiate;
  import NBEquation.Equation;
  import Replacements = NBReplacements;

  function solve
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
  algorithm
    try
      (eqn, funcTree) := solveLinear(eqn, cref, funcTree);
    else
    end try;
  end solve;

protected
  function solveLinear
    "author: kabdelhak, phannebohm
    solves a linear equation with one newton step"
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
  protected
    Expression residual, derivative, crefExp, zeroExp, numerator;
    Differentiate.DifferentiationArguments diffArgs;
    Operator divOp, uminOp;
  algorithm
    residual := Equation.getResidualExp(eqn);
    diffArgs := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = cref,
      jacobianHT      = NONE(),
      diffType        = NBDifferentiate.DifferentiationType.SIMPLE,
      funcTree        = funcTree,
      diffedFunctions = AvlSetPath.new()
    );
    (derivative, diffArgs) := Differentiate.differentiateExpression(residual, diffArgs);
    derivative := SimplifyExp.simplify(derivative);
    if not Expression.containsCref(derivative, cref) then
      funcTree := diffArgs.funcTree;
      crefExp := Expression.fromCref(cref);
      zeroExp := Expression.makeZero(ComponentRef.getComponentType(cref));
      numerator := Replacements.single(residual, crefExp, zeroExp);
      divOp := Operator.OPERATOR(ComponentRef.getComponentType(cref), NFOperator.Op.DIV);
      uminOp := Operator.OPERATOR(ComponentRef.getComponentType(cref), NFOperator.Op.UMINUS);
      eqn := Equation.setLHS(eqn, crefExp);
      eqn := Equation.setRHS(eqn, Expression.UNARY(uminOp, Expression.BINARY(numerator, divOp, derivative)));
      eqn := Equation.simplify(eqn);
    else
      fail();
    end if;
  end solveLinear;

  annotation(__OpenModelica_Interface="backend");
end NBSolve;
