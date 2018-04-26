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

encapsulated uniontype NFBinding
public
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import SCode;
  import Type = NFType;
  import NFPrefixes.Variability;
  import BindingOrigin = NFBindingOrigin;

protected
  import Dump;
  import Binding = NFBinding;

public
  record UNBOUND
    Option<NFBindingOrigin> origin;
  end UNBOUND;

  record RAW_BINDING
    Absyn.Exp bindingExp;
    InstNode scope;
    BindingOrigin origin;
    Boolean isEach;
  end RAW_BINDING;

  record UNTYPED_BINDING
    Expression bindingExp;
    Boolean isProcessing;
    InstNode scope;
    BindingOrigin origin;
    Boolean isEach;
  end UNTYPED_BINDING;

  record TYPED_BINDING
    Expression bindingExp;
    Type bindingType;
    Variability variability;
    BindingOrigin origin;
    Boolean isEach;
  end TYPED_BINDING;

  record FLAT_BINDING
    Expression bindingExp;
  end FLAT_BINDING;

public
  function fromAbsyn
    input Option<Absyn.Exp> bindingExp;
    input Boolean eachPrefix;
    input Integer level;
    input InstNode scope;
    input SourceInfo info;
    input BindingOrigin.ElementType ty = NFBindingOrigin.ElementType.COMPONENT;
    output Binding binding;
  algorithm
    binding := match bindingExp
      local
        Absyn.Exp exp;

      case SOME(exp)
        then RAW_BINDING(exp, scope, BindingOrigin.create(level, ty, info), eachPrefix);

      else UNBOUND(if eachPrefix then SOME(BindingOrigin.create(level, ty, info)) else NONE());
    end match;
  end fromAbsyn;

  function isBound
    input Binding binding;
    output Boolean isBound;
  algorithm
    isBound := match binding
      case UNBOUND() then false;
      else true;
    end match;
  end isBound;

  function isUnbound
    input Binding binding;
    output Boolean isUnbound;
  algorithm
    isUnbound := match binding
      case UNBOUND() then true;
      else false;
    end match;
  end isUnbound;

  function untypedExp
    input Binding binding;
    output Option<Expression> exp;
  algorithm
    exp := match binding
      case UNTYPED_BINDING() then SOME(binding.bindingExp);
      else NONE();
    end match;
  end untypedExp;

  function typedExp
    input Binding binding;
    output Option<Expression> exp;
  algorithm
    exp := match binding
      case TYPED_BINDING() then SOME(binding.bindingExp);
      case FLAT_BINDING() then SOME(binding.bindingExp);
      else NONE();
    end match;
  end typedExp;

  function getTypedExp
    input Binding binding;
    output Expression exp;
  algorithm
    exp := match binding
      case TYPED_BINDING() then binding.bindingExp;
      case FLAT_BINDING() then binding.bindingExp;
    end match;
  end getTypedExp;

  function setTypedExp
    input Expression exp;
    input output Binding binding;
  algorithm
    () := match binding
      case TYPED_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();
    end match;
  end setTypedExp;

  function getExp
    input Binding binding;
    output Expression exp;
  algorithm
    exp := match binding
      case UNTYPED_BINDING() then binding.bindingExp;
      case TYPED_BINDING() then binding.bindingExp;
      case FLAT_BINDING() then binding.bindingExp;
    end match;
  end getExp;

  function setExp
    input Expression exp;
    input output Binding binding;
  algorithm
    () := match binding
      case UNTYPED_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();

      case TYPED_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();

      case FLAT_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();

    end match;
  end setExp;

  function isRecordExp
    input Binding binding;
    output Boolean isRecordExp;
  algorithm
    isRecordExp := match binding
      case TYPED_BINDING(bindingExp = Expression.RECORD()) then true;
      else false;
    end match;
  end isRecordExp;

  function variability
    input Binding binding;
    output Variability var;
  algorithm
    TYPED_BINDING(variability = var) := binding;
  end variability;

  function getInfo
    input Binding binding;
    output SourceInfo info;
  algorithm
    info := match binding
      case UNBOUND(origin = SOME(BindingOrigin.ORIGIN(info = info))) then info;
      case RAW_BINDING() then binding.origin.info;
      case UNTYPED_BINDING() then binding.origin.info;
      case TYPED_BINDING() then binding.origin.info;
      else Absyn.dummyInfo;
    end match;
  end getInfo;

  function getOrigin
    input Binding binding;
    output BindingOrigin origin;
  algorithm
    origin := match binding
      case UNBOUND(origin = SOME(origin)) then origin;
      case RAW_BINDING() then binding.origin;
      case UNTYPED_BINDING() then binding.origin;
      case TYPED_BINDING() then binding.origin;
    end match;
  end getOrigin;

  function setOrigin
    input BindingOrigin origin;
    input output Binding binding;
  algorithm
    () := match binding
      case RAW_BINDING()     algorithm binding.origin := origin; then ();
      case UNTYPED_BINDING() algorithm binding.origin := origin; then ();
      case TYPED_BINDING()   algorithm binding.origin := origin; then ();
      else ();
    end match;
  end setOrigin;

  function setOriginNode
    input InstNode node;
    input output Binding binding;
  algorithm
    binding := setOrigin(BindingOrigin.setNode(node, getOrigin(binding)), binding);
  end setOriginNode;

  function getType
    input Binding binding;
    output Type ty;
  algorithm
    TYPED_BINDING(bindingType = ty) := binding;
  end getType;

  function isEach
    input Binding binding;
    output Boolean isEach;
  algorithm
    isEach := match binding
      case UNBOUND(origin = SOME(_)) then true;
      case RAW_BINDING() then binding.isEach;
      case UNTYPED_BINDING() then binding.isEach;
      case TYPED_BINDING() then binding.isEach;
      else false;
    end match;
  end isEach;

  function isTyped
    input Binding binding;
    output Boolean isTyped;
  algorithm
    isTyped := match binding
      case TYPED_BINDING() then true;
      else false;
    end match;
  end isTyped;

  function toString
    input Binding binding;
    input String prefix = "";
    output String string;
  algorithm
    string := match binding
      case UNBOUND() then "";
      case RAW_BINDING() then prefix + Dump.printExpStr(binding.bindingExp);
      case UNTYPED_BINDING() then prefix + Expression.toString(binding.bindingExp);
      case TYPED_BINDING() then prefix + Expression.toString(binding.bindingExp);
    end match;
  end toString;

  function isEqual
    input Binding binding1;
    input Binding binding2;
    output Boolean equal;
  algorithm
    equal := match (binding1, binding2)
      case (UNBOUND(), UNBOUND()) then true;

      // TODO: Handle propagated dims.
      case (RAW_BINDING(), RAW_BINDING())
        then Absyn.expEqual(binding1.bindingExp, binding2.bindingExp);

      case (UNTYPED_BINDING(), UNTYPED_BINDING())
        then Expression.isEqual(binding1.bindingExp, binding2.bindingExp);

      case (TYPED_BINDING(), TYPED_BINDING())
        then Expression.isEqual(binding1.bindingExp, binding2.bindingExp);

      else false;
    end match;
  end isEqual;

  function toDAE
    input Binding b;
    output DAE.Binding outb;
  algorithm
    outb := match b
      case UNBOUND() then DAE.UNBOUND();
      case TYPED_BINDING()
        then DAE.EQBOUND(Expression.toDAE(b.bindingExp)
                         , NONE()
                         , Variability.variabilityToDAEConst(b.variability)
                         , DAE.BINDING_FROM_DEFAULT_VALUE() // TODO: revise this.
                        );

      else algorithm
        Error.assertion(false, getInstanceName() + " got untyped binding.", sourceInfo());
        then fail();

    end match;
  end toDAE;

annotation(__OpenModelica_Interface="frontend");
end NFBinding;
