/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package NFInstContext
  "Used by the instantation to keep track of in which context the instantiation is done."

  type Type = Integer;

  // Flag values:
  constant Type NO_CONTEXT      = 0;
  constant Type RELAXED         = intBitLShift(1,  0); // Relaxed instantiation, used by e.g. checkModel.
  constant Type CLASS           = intBitLShift(1,  1); // In class.
  constant Type FUNCTION        = intBitLShift(1,  2); // In function.
  constant Type REDECLARED      = intBitLShift(1,  3); // In an element that will be replaced with a redeclare.
  constant Type ALGORITHM       = intBitLShift(1,  4); // In algorithm section.
  constant Type EQUATION        = intBitLShift(1,  5); // In equation section.
  constant Type INITIAL         = intBitLShift(1,  6); // In initial section.
  constant Type LHS             = intBitLShift(1,  7); // On left hand side of equality/assignment.
  constant Type RHS             = intBitLShift(1,  8); // On right hand side of equality/assignment.
  constant Type WHEN            = intBitLShift(1,  9); // In when equation/statement.
  constant Type CLOCKED         = intBitLShift(1, 10); // Part of a clocked when equation.
  constant Type FOR             = intBitLShift(1, 11); // In a for loop.
  constant Type IF              = intBitLShift(1, 12); // In an if equation/statement.
  constant Type WHILE           = intBitLShift(1, 13); // In a while loop.
  constant Type NONEXPANDABLE   = intBitLShift(1, 14); // In non-parameter if/for.
  constant Type ITERATION_RANGE = intBitLShift(1, 15); // In range used for iteration.
  constant Type DIMENSION       = intBitLShift(1, 16); // In dimension.
  constant Type BINDING         = intBitLShift(1, 17); // In binding.
  constant Type CONDITION       = intBitLShift(1, 18); // In conditional expression.
  constant Type SUBSCRIPT       = intBitLShift(1, 19); // In subscript.
  constant Type SUBEXPRESSION   = intBitLShift(1, 20); // Part of a larger expression.
  constant Type CONNECT         = intBitLShift(1, 21); // Part of connect argument.
  constant Type NOEVENT         = intBitLShift(1, 22); // Part of noEvent argument.
  constant Type ASSERT          = intBitLShift(1, 23); // Part of assert argument.

  // Combined flags:
  constant Type EQ_SUBEXPRESSION = intBitOr(EQUATION, SUBEXPRESSION);
  constant Type VALID_TYPENAME_SCOPE = intBitOr(ITERATION_RANGE, DIMENSION);
  constant Type DISCRETE_SCOPE = intBitOr(WHEN, intBitOr(INITIAL, FUNCTION));

  function set
    input Type context;
    input Type flag;
    output Type newOrigin;
  algorithm
    newOrigin := intBitOr(context, flag);
    annotation(__OpenModelica_EarlyInline=true);
  end set;

  function isSet
    input Type context;
    input Type flag;
    output Boolean set;
  algorithm
    set := intBitAnd(context, flag) > 0;
    annotation(__OpenModelica_EarlyInline=true);
  end isSet;

  function isNotSet
    input Type context;
    input Type flag;
    output Boolean notSet;
  algorithm
    notSet := intBitAnd(context, flag) == 0;
    annotation(__OpenModelica_EarlyInline=true);
  end isNotSet;

  function inRelaxed
    input Type context;
    output Boolean res = intBitAnd(context, RELAXED) > 0;
  end inRelaxed;

  function inClass
    input Type context;
    output Boolean res = intBitAnd(context, CLASS) > 0;
  end inClass;

  function inFunction
    input Type context;
    output Boolean res = intBitAnd(context, FUNCTION) > 0;
  end inFunction;

  function inRedeclared
    input Type context;
    output Boolean res = intBitAnd(context, REDECLARED) > 0;
  end inRedeclared;

  function inAlgorithm
    input Type context;
    output Boolean res = intBitAnd(context, ALGORITHM) > 0;
  end inAlgorithm;

  function inEquation
    input Type context;
    output Boolean res = intBitAnd(context, EQUATION) > 0;
  end inEquation;

  function inInitial
    input Type context;
    output Boolean res = intBitAnd(context, INITIAL) > 0;
  end inInitial;

  function onLHS
    input Type context;
    output Boolean res = intBitAnd(context, LHS) > 0;
  end onLHS;

  function onRHS
    input Type context;
    output Boolean res = intBitAnd(context, RHS) > 0;
  end onRHS;

  function inWhen
    input Type context;
    output Boolean res = intBitAnd(context, WHEN) > 0;
  end inWhen;

  function inClocked
    input Type context;
    output Boolean res = intBitAnd(context, CLOCKED) > 0;
  end inClocked;

  function inFor
    input Type context;
    output Boolean res = intBitAnd(context, FOR) > 0;
  end inFor;

  function inIf
    input Type context;
    output Boolean res = intBitAnd(context, IF) > 0;
  end inIf;

  function inWhile
    input Type context;
    output Boolean res = intBitAnd(context, WHILE) > 0;
  end inWhile;

  function inNonexpandable
    input Type context;
    output Boolean res = intBitAnd(context, NONEXPANDABLE) > 0;
  end inNonexpandable;

  function inIterationRange
    input Type context;
    output Boolean res = intBitAnd(context, ITERATION_RANGE) > 0;
  end inIterationRange;

  function inDimension
    input Type context;
    output Boolean res = intBitAnd(context, DIMENSION) > 0;
  end inDimension;

  function inBinding
    input Type context;
    output Boolean res = intBitAnd(context, BINDING) > 0;
  end inBinding;

  function inCondition
    input Type context;
    output Boolean res = intBitAnd(context, CONDITION) > 0;
  end inCondition;

  function inSubscript
    input Type context;
    output Boolean res = intBitAnd(context, SUBSCRIPT) > 0;
  end inSubscript;

  function inSubexpression
    input Type context;
    output Boolean res = intBitAnd(context, SUBEXPRESSION) > 0;
  end inSubexpression;

  function inConnect
    input Type context;
    output Boolean res = intBitAnd(context, CONNECT) > 0;
  end inConnect;

  function inNoEvent
    input Type context;
    output Boolean res = intBitAnd(context, NOEVENT) > 0;
  end inNoEvent;

  function inAssert
    input Type context;
    output Boolean res = intBitAnd(context, ASSERT) > 0;
  end inAssert;

  function inValidTypenameScope
    input Type context;
    output Boolean res = intBitAnd(context, intBitOr(ITERATION_RANGE, DIMENSION)) > 0;
  end inValidTypenameScope;

  function inDiscreteScope
    input Type context;
    output Boolean res = intBitAnd(context, intBitOr(WHEN, intBitOr(INITIAL, FUNCTION))) > 0;
  end inDiscreteScope;

  function inLoop
    input Type context;
    output Boolean res = intBitAnd(context, intBitOr(FOR, WHILE)) > 0;
  end inLoop;

  function inValidWhenScope
    input Type context;
    output Boolean res =
      intBitAnd(context, intBitOr(intBitOr(FUNCTION, WHILE), intBitOr(IF, intBitOr(FOR, WHEN)))) == 0;
  end inValidWhenScope;

  function isSingleExpression
    "Returns true if the given context indicates the expression is alone on
     either side of an equality/assignment."
    input Type context;
    output Boolean isSingle = context < ITERATION_RANGE - 1;
  end isSingleExpression;

annotation(__OpenModelica_Interface="frontend");
end NFInstContext;

