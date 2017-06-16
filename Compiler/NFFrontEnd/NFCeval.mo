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

encapsulated package NFCeval

import Binding = NFBinding;
import ComponentRef = NFComponentRef;
import Error;
import NFComponent.Component;
import Expression = NFExpression;
import NFInstNode.InstNode;
import Operator = NFOperator;
import Typing = NFTyping;
import NFCall.Call;
import Dimension = NFDimension;
import Type = NFType;

uniontype EvalTarget
  record DIMENSION
    String name;
    Integer index;
    Expression exp;
    SourceInfo info;
  end DIMENSION;

  record ATTRIBUTE
    Expression exp;
    SourceInfo info;
  end ATTRIBUTE;

  record RANGE
    SourceInfo info;
  end RANGE;

  record IGNORE_ERRORS end IGNORE_ERRORS;
end EvalTarget;

function evalExp
  input output Expression exp;
  input EvalTarget target;
algorithm
  exp := match exp
    local
      InstNode c;
      Binding binding;
      Expression exp1, exp2, exp3;
      list<Expression> expl = {};
      Call call;
      Component comp;
      Option<Expression> oexp;

    case Expression.CREF(cref=ComponentRef.CREF(node = c as InstNode.COMPONENT_NODE()))
      algorithm
        Typing.typeComponentBinding(c);
        binding := Component.getBinding(InstNode.component(c));
      then
        evalBinding(binding, exp, target);

    case Expression.TYPENAME()
      then evalTypename(exp.ty, exp, target);

    case Expression.ARRAY()
      algorithm
        for e in exp.elements loop
          exp1 := evalExp(e, target);
          expl := exp1 :: expl;
        end for;
      then Expression.ARRAY(exp.ty, listReverse(expl));

    // Ranges could be evaluated into arrays, but that's less efficient in some
    // cases. So here we just evaluate the range's expressions, and let the
    // caller worry about vectorization.
    case Expression.RANGE()
      algorithm
        exp1 := evalExp(exp.start, target);
        oexp := evalExpOpt(exp.step, target);
        exp3 := evalExp(exp.stop, target);
      then
        Expression.RANGE(exp.ty, exp1, oexp, exp3);

    case Expression.RECORD()
      algorithm
        assert(false, "Unimplemented case for " + Expression.toString(exp) + " in " + getInstanceName());
      then fail();

    case Expression.CALL(call = call as Call.TYPED_CALL())
      algorithm
        call.arguments := list(evalExp(e, target) for e in call.arguments);
      then
        Expression.CALL(call);

    case Expression.SIZE()
      algorithm
        assert(false, "Unimplemented case for " + Expression.toString(exp) + " in " + getInstanceName());
      then fail();

    case Expression.BINARY()
      algorithm
        exp1 := evalExp(exp.exp1, target);
        exp2 := evalExp(exp.exp2, target);
      then Expression.BINARY(exp1, exp.operator, exp2);

    case Expression.UNARY()
      algorithm
        exp1 := evalExp(exp.exp, target);
      then Expression.UNARY(exp.operator, exp1);

    case Expression.LBINARY()
      algorithm
        exp1 := evalExp(exp.exp1, target);
        exp2 := evalExp(exp.exp2, target);
      then Expression.LBINARY(exp1, exp.operator, exp2);

    case Expression.LUNARY()
      algorithm
        exp1 := evalExp(exp.exp, target);
      then Expression.LUNARY(exp.operator, exp1);

    case Expression.RELATION()
      algorithm
        exp1 := evalExp(exp.exp1, target);
        exp2 := evalExp(exp.exp2, target);
      then Expression.RELATION(exp1, exp.operator, exp2);

    case Expression.IF()
      algorithm
        exp1 := evalExp(exp.condition, target);
        exp2 := evalExp(exp.trueBranch, target);
        exp3 := evalExp(exp.falseBranch, target);
      then Expression.IF(exp1, exp2, exp3);

    case Expression.CAST()
      algorithm
        exp1 := evalExp(exp.exp, target);
      then Expression.CAST(exp.ty, exp1);

    case Expression.UNBOX()
      algorithm
        exp1 := evalExp(exp.exp, target);
      then Expression.UNBOX(exp1, exp.ty);

    else exp;
  end match;
end evalExp;

function evalExpOpt
  input output Option<Expression> oexp;
  input EvalTarget target;
algorithm
  oexp := match oexp
    local
      Expression e;

    case SOME(e) then SOME(evalExp(e, target));
    else oexp;
  end match;
end evalExpOpt;

protected

function evalBinding
  input Binding binding;
  input Expression originExp "The expression the binding came from, e.g. a cref.";
  input EvalTarget target;
  output Expression exp;
algorithm
  exp := match binding
    case Binding.TYPED_BINDING() then evalExp(binding.bindingExp, target);
    case Binding.UNBOUND()
      algorithm
        printUnboundError(target, originExp);
      then
        originExp;
    else
      algorithm
        assert(false, getInstanceName() + " failed on untyped binding");
      then
        fail();
  end match;
end evalBinding;

function printUnboundError
  input EvalTarget target;
  input Expression exp;
algorithm
  () := match target
    case EvalTarget.DIMENSION()
      algorithm
        Error.addSourceMessage(Error.STRUCTURAL_PARAMETER_OR_CONSTANT_WITH_NO_BINDING,
          {Expression.toString(exp), target.name}, target.info);
      then
        fail();

    else ();
  end match;
end printUnboundError;

function evalTypename
  input Type ty;
  input Expression originExp;
  input EvalTarget target;
  output Expression exp;
protected
  list<Expression> lits;
algorithm
  exp := match ty
    case Type.ARRAY(elementType = Type.BOOLEAN())
      then Expression.ARRAY(ty, {Expression.BOOLEAN(false), Expression.BOOLEAN(true)});

    case Type.ARRAY(elementType = Type.ENUMERATION())
      algorithm
        lits := Expression.makeEnumLiterals(ty.elementType);
      then
        Expression.ARRAY(ty, lits);

    else
      algorithm
        assert(false, getInstanceName() + " got invalid typename");
      then
        fail();

  end match;
end evalTypename;

annotation(__OpenModelica_Interface="frontend");
end NFCeval;
