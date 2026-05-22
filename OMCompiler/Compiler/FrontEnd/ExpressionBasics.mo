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

encapsulated package ExpressionBasics
" file:        ExpressionBasics.mo
  package:     ExpressionBasics
  description: ExpressionBasics


  This file contains the module ExpressionDump, which contains the most basic functions
  to print and work with DAE.Expression."

// public imports
import DAE;
protected
import AbsynUtil;
import ExpressionDumpTpl;
import List;
import Tpl;
import Util;

public function printExpStr
"This function prints a complete expression."
  input DAE.Exp e;
  output String s;
algorithm
  s := Tpl.tplString2(ExpressionDumpTpl.dumpExp, e, "\"");
end printExpStr;

public function dimensionString
  "Returns a string representation of an array dimension."
  input DAE.Dimension dim;
  output String str;
algorithm
  str := match(dim)
    local
      String s;
      Integer x;
      Absyn.Path p;
      DAE.Exp e;
      Integer size;
    case DAE.DIM_UNKNOWN() then ":";

    case DAE.DIM_ENUM(enumTypeName = p)
      algorithm
        s := AbsynUtil.pathString(p);
      then
        s;

    case DAE.DIM_BOOLEAN() then "Boolean";

    case DAE.DIM_INTEGER(integer = x)
      algorithm
        s := intString(x);
      then
        s;

    case DAE.DIM_EXP(exp = e)
      algorithm
        s := printExpStr(e);
      then
        s;
  end match;
end dimensionString;

public function dimensionsString
  "Returns a string representation of an array dimension."
  input DAE.Dimensions dims;
  output String str;
algorithm
  str := stringDelimitList(List.map(dims,dimensionString),",");
end dimensionsString;

public function shouldParenthesize
  "Determines whether an operand in an expression needs parentheses around it."
  input DAE.Exp inOperand;
  input DAE.Exp inOperator;
  input Boolean inLhs;
  output Boolean outShouldParenthesize;
algorithm
  outShouldParenthesize := match inOperand
    local
      Integer diff;

    case DAE.UNARY() then true;

    else
      algorithm
        diff := Util.intCompare(priority(inOperand, inLhs),
                               priority(inOperator, inLhs));
      then
        shouldParenthesize2(diff, inOperand, inLhs);

  end match;
end shouldParenthesize;

protected function shouldParenthesize2
  input Integer inPrioDiff;
  input DAE.Exp inOperand;
  input Boolean inLhs;
  output Boolean outShouldParenthesize;
algorithm
  outShouldParenthesize := match inPrioDiff
    case 1 then true;
    case 0 then if inLhs then isNonAssociativeExp(inOperand) else
                              not isAssociativeExp(inOperand);
    else false;
  end match;
end shouldParenthesize2;

protected function isAssociativeExp
  "Determines whether the given expression represents an associative operation or not."
  input DAE.Exp inExp;
  output Boolean outIsAssociative;
algorithm
  outIsAssociative := match(inExp)
    local
      DAE.Operator op;

    case DAE.BINARY(operator = op) then isAssociativeOp(op);
    case DAE.LBINARY() then true;
    else false;
  end match;
end isAssociativeExp;

protected function isAssociativeOp
  "Determines whether the given operator is associative or not."
  input DAE.Operator inOperator;
  output Boolean outIsAssociative;
algorithm
  outIsAssociative := match inOperator
    case DAE.ADD() then true;
    case DAE.MUL() then true;
    case DAE.ADD_ARR() then true;
    case DAE.MUL_ARRAY_SCALAR() then true;
    case DAE.ADD_ARRAY_SCALAR() then true;
    else false;
  end match;
end isAssociativeOp;

protected function isNonAssociativeExp
  input DAE.Exp exp;
  output Boolean isNonAssociative;
algorithm
  isNonAssociative := match exp
    case DAE.BINARY() then isNonAssociativeOp(exp.operator);
    else false;
  end match;
end isNonAssociativeExp;

protected function isNonAssociativeOp
  input DAE.Operator inOperator;
  output Boolean isNonAssociative;
algorithm
  isNonAssociative := match inOperator
    case DAE.POW() then true;
    case DAE.POW_ARRAY_SCALAR() then true;
    case DAE.POW_SCALAR_ARRAY() then true;
    case DAE.POW_ARR() then true;
    case DAE.POW_ARR2() then true;
    else false;
  end match;
end isNonAssociativeOp;

public function priority
  "Returns an integer priority given an expression, which is used by
   ExpressionDumpTpl to add parentheses when dumping expressions. The inLhs
   argument should be true if the expression occurs on the left side of a binary
   operation, otherwise false. This is because we don't need to add parentheses
   to expressions such as x * y / z, but x / (y * z) needs them, so the
   priorities of some binary operations differ depending on which side they are."
  input DAE.Exp inExp;
  input Boolean inLhs;
  output Integer outPriority;
algorithm
  outPriority := match(inExp, inLhs)
    local
      DAE.Operator op;

    case (DAE.BINARY(operator = op), false) then priorityBinopRhs(op);
    case (DAE.BINARY(operator = op), true) then priorityBinopLhs(op);
    case (DAE.RCONST(), _) guard inExp.real < 0.0 then 4; // Same as unary minus of a real literal
    case (DAE.UNARY(), _) then 4;
    case (DAE.LBINARY(operator = op), _) then priorityLBinop(op);
    case (DAE.LUNARY(), _) then 7;
    case (DAE.RELATION(), _) then 6;
    case (DAE.RANGE(), _) then 10;
    case (DAE.IFEXP(), _) then 11;
    else 0;
  end match;
end priority;

protected function priorityBinopLhs
  "Returns the priority for a binary operation on the left hand side. Add and
   sub has the same priority, and mul and div too, in contrast with
   priorityBinopRhs."
  input DAE.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case DAE.ADD() then 5;
    case DAE.SUB() then 5;
    case DAE.MUL() then 2;
    case DAE.DIV() then 2;
    case DAE.POW() then 1;
    case DAE.ADD_ARR() then 5;
    case DAE.SUB_ARR() then 5;
    case DAE.MUL_ARR() then 2;
    case DAE.DIV_ARR() then 2;
    case DAE.MUL_ARRAY_SCALAR() then 2;
    case DAE.ADD_ARRAY_SCALAR() then 5;
    case DAE.SUB_SCALAR_ARRAY() then 5;
    case DAE.MUL_SCALAR_PRODUCT() then 2;
    case DAE.MUL_MATRIX_PRODUCT() then 2;
    case DAE.DIV_ARRAY_SCALAR() then 2;
    case DAE.DIV_SCALAR_ARRAY() then 2;
    case DAE.POW_ARRAY_SCALAR() then 1;
    case DAE.POW_SCALAR_ARRAY() then 1;
    case DAE.POW_ARR() then 1;
    case DAE.POW_ARR2() then 1;
  end match;
end priorityBinopLhs;

protected function priorityBinopRhs
  "Returns the priority for a binary operation on the right hand side. Add and
   sub has different priorities, and mul and div too, in contrast with
   priorityBinopLhs."
  input DAE.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case DAE.ADD() then 6;
    case DAE.SUB() then 5;
    case DAE.MUL() then 3;
    case DAE.DIV() then 2;
    case DAE.POW() then 1;
    case DAE.ADD_ARR() then 6;
    case DAE.SUB_ARR() then 5;
    case DAE.MUL_ARR() then 3;
    case DAE.DIV_ARR() then 2;
    case DAE.MUL_ARRAY_SCALAR() then 3;
    case DAE.ADD_ARRAY_SCALAR() then 6;
    case DAE.SUB_SCALAR_ARRAY() then 5;
    case DAE.MUL_SCALAR_PRODUCT() then 3;
    case DAE.MUL_MATRIX_PRODUCT() then 3;
    case DAE.DIV_ARRAY_SCALAR() then 2;
    case DAE.DIV_SCALAR_ARRAY() then 2;
    case DAE.POW_ARRAY_SCALAR() then 1;
    case DAE.POW_SCALAR_ARRAY() then 1;
    case DAE.POW_ARR() then 1;
    case DAE.POW_ARR2() then 1;
  end match;
end priorityBinopRhs;

protected function priorityLBinop
  input DAE.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case DAE.AND() then 8;
    case DAE.OR() then 9;
  end match;
end priorityLBinop;

annotation(__OpenModelica_Interface="frontend_dump");
end ExpressionBasics;
