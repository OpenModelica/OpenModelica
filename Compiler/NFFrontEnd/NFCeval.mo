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
import NFComponent.Component;
import NFExpression.Expression;
import NFInstNode.InstNode;
import Typing = NFTyping;
import Error;

uniontype EvalTarget
  record DIMENSION
    String name;
    Integer index;
    Expression exp;
    SourceInfo info;
  end DIMENSION;

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

    case Expression.CREF(cref = ComponentRef.CREF(node = c as InstNode.COMPONENT_NODE()))
      algorithm
        Typing.typeComponentBinding(c, InstNode.parent(c));
        binding := Component.getBinding(InstNode.component(c));
      then
        evalBinding(binding, exp, target);

    case Expression.CREF(cref = ComponentRef.CREF(node = c as InstNode.CLASS_NODE()))
      then evalTypename(c, exp, target);

    else exp;
  end match;
end evalExp;

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
  input InstNode node;
  input Expression originExp;
  input EvalTarget target;
  output Expression exp;
algorithm
  exp := match target
    case EvalTarget.DIMENSION() then originExp;

    else originExp;
  end match;
end evalTypename;

annotation(__OpenModelica_Interface="frontend");
end NFCeval;
