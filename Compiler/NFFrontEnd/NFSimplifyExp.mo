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

encapsulated package NFSimplifyExp

import Expression = NFExpression;
import Operator = NFOperator;
import Type = NFType;
import NFCall.Call;

function simplifyExp
  input output Expression exp;
algorithm
  exp := preSimplify(exp);
  exp := postSimplify(exp);
end simplifyExp;

function simplifyExpOpt
  input output Option<Expression> oexp;
algorithm
  oexp := match oexp
    local
      Expression exp;

    case SOME(exp)
      algorithm
        exp := preSimplify(exp);
        exp := postSimplify(exp);
      then
        SOME(exp);

    else oexp;
  end match;
end simplifyExpOpt;

protected

function preSimplify
  input output Expression exp;
protected
  Expression exp1, exp2, exp3;
  Option<Expression> oexp;
  list<Expression> expl = {};
  Call call;
algorithm
  exp := match exp
    case Expression.ARRAY()
      algorithm
        for e in exp.elements loop
          exp1 := simplifyExp(e);
          expl := exp1 :: expl;
        end for;
      then Expression.ARRAY(exp.ty, listReverse(expl));

    case Expression.RANGE()
      algorithm
        exp1 := simplifyExp(exp.start);
        oexp := simplifyExpOpt(exp.step);
        exp2 := simplifyExp(exp.stop);
      then
        Expression.RANGE(exp.ty, exp1, oexp, exp2);

    case Expression.RECORD()
      algorithm
        Error.assertion(false, "Unimplemented case for " + Expression.toString(exp) + " in " + getInstanceName(), sourceInfo());
      then fail();

    case Expression.CALL(call = call as Call.TYPED_CALL())
      algorithm
        call.arguments := list(simplifyExp(e) for e in call.arguments);
      then
        Expression.CALL(call);

    case Expression.BINARY()
      algorithm
        exp1 := simplifyExp(exp.exp1);
        exp2 := simplifyExp(exp.exp2);
      then Expression.BINARY(exp1, exp.operator, exp2);

    case Expression.UNARY()
      algorithm
        exp1 := simplifyExp(exp.exp);
      then Expression.UNARY(exp.operator, exp1);

    case Expression.LBINARY()
      algorithm
        exp1 := simplifyExp(exp.exp1);
        exp2 := simplifyExp(exp.exp2);
      then Expression.LBINARY(exp1, exp.operator, exp2);

    case Expression.LUNARY()
      algorithm
        exp1 := simplifyExp(exp.exp);
      then Expression.LUNARY(exp.operator, exp1);

    case Expression.RELATION()
      algorithm
        exp1 := simplifyExp(exp.exp1);
        exp2 := simplifyExp(exp.exp2);
      then Expression.RELATION(exp1, exp.operator, exp2);

    case Expression.IF()
      algorithm
        exp1 := simplifyExp(exp.condition);
        exp2 := simplifyExp(exp.trueBranch);
        exp3 := simplifyExp(exp.falseBranch);
      then Expression.IF(exp1, exp2, exp3);

    case Expression.CAST()
      algorithm
        exp1 := simplifyExp(exp.exp);
      then Expression.CAST(exp.ty, exp1);

    case Expression.UNBOX()
      algorithm
        exp1 := simplifyExp(exp.exp);
      then Expression.UNBOX(exp1, exp.ty);

    else exp;
  end match;
end preSimplify;

function postSimplify
  input output Expression exp;
protected
  Expression exp1, exp2;
  Integer i1, i2;
  Real r1, r2;
  Boolean b1, b2;
  list<Expression> expl = {};
algorithm
  exp := match exp
    case Expression.ARRAY()
      algorithm
        for e in exp.elements loop
          exp1 := postSimplify(e);
          expl := exp1 :: expl;
        end for;
      then Expression.ARRAY(exp.ty, listReverse(expl));

    case Expression.RECORD()
      algorithm
        Error.assertion(false, "Unimplemented case for " + Expression.toString(exp) + " in " + getInstanceName(), sourceInfo());
      then fail();

    case Expression.CALL()
      algorithm
        Error.assertion(false, "Unimplemented case for " + Expression.toString(exp) + " in " + getInstanceName(), sourceInfo());
      then fail();

    case Expression.BINARY(exp1=Expression.INTEGER(value=i1), exp2=Expression.INTEGER(value=i2))
      then match exp.operator
        case Operator.ADD() then Expression.INTEGER(i1 + i2);
        case Operator.SUB() then Expression.INTEGER(i1 - i2);
        case Operator.MUL() then Expression.INTEGER(i1 * i2);
        case Operator.DIV() then Expression.REAL(i1 / i2);
      end match;

    case Expression.BINARY(exp1=Expression.REAL(value=r1), exp2=Expression.REAL(value=r2))
      then match exp.operator
        case Operator.ADD() then Expression.REAL(r1 + r2);
        case Operator.SUB() then Expression.REAL(r1 - r2);
        case Operator.MUL() then Expression.REAL(r1 * r2);
        case Operator.DIV() then Expression.REAL(r1 / r2);
      end match;

    case Expression.UNARY(operator=Operator.UMINUS(), exp=Expression.INTEGER(value=i1))
      then Expression.INTEGER(-i1);

    case Expression.UNARY(operator=Operator.UMINUS(), exp=Expression.REAL(value=r1))
      then Expression.REAL(-r1);

    case Expression.LBINARY(exp1=Expression.BOOLEAN(value=b1), exp2=Expression.BOOLEAN(value=b2))
      then match exp.operator
        case Operator.AND() then Expression.BOOLEAN(b1 and b2);
        case Operator.OR() then Expression.BOOLEAN(b1 or b2);
      end match;

    case Expression.LUNARY(operator=Operator.NOT(), exp=Expression.BOOLEAN(value=b1))
      then Expression.BOOLEAN(not b1);

    case Expression.RELATION(exp1=Expression.BOOLEAN(value=b1), exp2=Expression.BOOLEAN(value=b2))
      then match exp.operator
        case Operator.EQUAL() then Expression.BOOLEAN(b1 == b2);
        case Operator.NEQUAL() then Expression.BOOLEAN(b1 <> b2);
      end match;

    case Expression.RELATION(exp1=Expression.INTEGER(value=i1), exp2=Expression.INTEGER(value=i2))
      then match exp.operator
        case Operator.LESS() then Expression.BOOLEAN(i1 < i2);
        case Operator.LESSEQ() then Expression.BOOLEAN(i1 <= i2);
        case Operator.GREATER() then Expression.BOOLEAN(i1 > i2);
        case Operator.GREATEREQ() then Expression.BOOLEAN(i1 >= i2);
        case Operator.EQUAL() then Expression.BOOLEAN(i1 == i2);
        case Operator.NEQUAL() then Expression.BOOLEAN(i1 <> i2);
      end match;

    case Expression.RELATION(exp1=Expression.REAL(value=r1), exp2=Expression.REAL(value=r2))
      then match exp.operator
        case Operator.LESS() then Expression.BOOLEAN(r1 < r2);
        case Operator.LESSEQ() then Expression.BOOLEAN(r1 <= r2);
        case Operator.GREATER() then Expression.BOOLEAN(r1 > r2);
        case Operator.GREATEREQ() then Expression.BOOLEAN(r1 >= r2);
      end match;

    case Expression.RELATION(exp1 = Expression.ENUM_LITERAL(index = i1),
                             exp2 = Expression.ENUM_LITERAL(index = i2))
      then Expression.BOOLEAN(match exp.operator
        case Operator.LESS()      then i1 < i2;
        case Operator.LESSEQ()    then i1 <= i2;
        case Operator.GREATER()   then i1 > i2;
        case Operator.GREATEREQ() then i1 >= i2;
        case Operator.EQUAL()     then i1 == i2;
        case Operator.NEQUAL()    then i1 <> i2;
      end match);

    case Expression.IF(condition=Expression.BOOLEAN(value=b1))
      then if b1 then exp.trueBranch else exp.falseBranch;

    case Expression.CAST()
      algorithm
        Error.assertion(false, "Unimplemented case for " + Expression.toString(exp) + " in " + getInstanceName(), sourceInfo());
      then fail();

    case Expression.UNBOX()
      algorithm
        Error.assertion(false, "Unimplemented case for " + Expression.toString(exp) + " in " + getInstanceName(), sourceInfo());
      then fail();

    else exp;
  end match;
end postSimplify;

annotation(__OpenModelica_Interface="frontend");
end NFSimplifyExp;
