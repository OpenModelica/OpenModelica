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

encapsulated package NFComponent

import DAE;
import NFBinding.Binding;
import NFClass.Class;
import Dimension = NFDimension;
import NFInstNode.InstNode;
import NFModifier.Modifier;
import SCode.Element;
import SCode;
import Type = NFType;
import Expression = NFExpression;
import NFPrefixes.*;

protected
import NFInstUtil;
import List;
import Prefixes = NFPrefixes;

public
constant Component.Attributes DEFAULT_ATTR =
  Component.Attributes.ATTRIBUTES(
    ConnectorType.POTENTIAL,
    Parallelism.NON_PARALLEL,
    Variability.CONTINUOUS,
    Direction.NONE,
    InnerOuter.NOT_INNER_OUTER,
    false,
    false,
    Replaceable.NOT_REPLACEABLE()
  );
constant Component.Attributes INPUT_ATTR =
  Component.Attributes.ATTRIBUTES(
    ConnectorType.NON_CONNECTOR,
    Parallelism.NON_PARALLEL,
    Variability.CONTINUOUS,
    Direction.INPUT,
    InnerOuter.NOT_INNER_OUTER,
    false,
    false,
    Replaceable.NOT_REPLACEABLE()
  );

constant Component.Attributes OUTPUT_ATTR =
  Component.Attributes.ATTRIBUTES(
    ConnectorType.NON_CONNECTOR,
    Parallelism.NON_PARALLEL,
    Variability.CONTINUOUS,
    Direction.OUTPUT,
    InnerOuter.NOT_INNER_OUTER,
    false,
    false,
    Replaceable.NOT_REPLACEABLE()
  );

constant Component.Attributes CONSTANT_ATTR =
  Component.Attributes.ATTRIBUTES(
    ConnectorType.NON_CONNECTOR,
    Parallelism.NON_PARALLEL,
    Variability.CONSTANT,
    Direction.NONE,
    InnerOuter.NOT_INNER_OUTER,
    false,
    false,
    Replaceable.NOT_REPLACEABLE()
  );

constant Component.Attributes IMPL_DISCRETE_ATTR =
  Component.Attributes.ATTRIBUTES(
    ConnectorType.POTENTIAL,
    Parallelism.NON_PARALLEL,
    Variability.IMPLICITLY_DISCRETE,
    Direction.NONE,
    InnerOuter.NOT_INNER_OUTER,
    false,
    false,
    Replaceable.NOT_REPLACEABLE()
  );

uniontype Component
  uniontype Attributes
    import SCode;

    record ATTRIBUTES
      // adrpo: keep the order in DAE.ATTR
      ConnectorType connectorType;
      Parallelism parallelism;
      Variability variability;
      Direction direction;
      InnerOuter innerOuter;
      Boolean isFinal;
      Boolean isRedeclare;
      Replaceable isReplaceable;
    end ATTRIBUTES;

    function toDAE
      input Attributes ina;
      input Visibility vis;
      output DAE.Attributes outa;
    algorithm
      outa := DAE.ATTR(
        connectorTypeToDAE(ina.connectorType),
        parallelismToSCode(ina.parallelism),
        variabilityToSCode(ina.variability),
        directionToAbsyn(ina.direction),
        innerOuterToAbsyn(ina.innerOuter),
        visibilityToSCode(vis)
      );
    end toDAE;

    function toString
      input Attributes attr;
      input Type ty;
      output String str;
    algorithm
      str := (if attr.isRedeclare then "redeclare " else "") +
             (if attr.isFinal then "final " else "") +
             Prefixes.unparseInnerOuter(attr.innerOuter) +
             Prefixes.unparseConnectorType(attr.connectorType) +
             Prefixes.unparseReplaceable(attr.isReplaceable) +
             Prefixes.unparseParallelism(attr.parallelism) +
             Prefixes.unparseVariability(attr.variability, ty) +
             Prefixes.unparseDirection(attr.direction) +
             Prefixes.unparseConnectorType(attr.connectorType);
    end toString;
  end Attributes;

  record COMPONENT_DEF
    SCode.Element definition;
    Modifier modifier;
  end COMPONENT_DEF;

  record UNTYPED_COMPONENT
    InstNode classInst;
    array<Dimension> dimensions;
    Binding binding;
    Binding condition;
    Component.Attributes attributes;
    Option<SCode.Comment> comment;
    Boolean instantiated;
    SourceInfo info;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    InstNode classInst;
    Type ty;
    Binding binding;
    Binding condition;
    Component.Attributes attributes;
    Option<SCode.Comment> comment;
    SourceInfo info;
  end TYPED_COMPONENT;

  record ITERATOR
    Type ty;
    Variability variability;
    SourceInfo info;
  end ITERATOR;

  record ENUM_LITERAL
    Expression literal;
  end ENUM_LITERAL;

  record TYPE_ATTRIBUTE
    Type ty;
    Modifier modifier;
  end TYPE_ATTRIBUTE;

  record DELETED_COMPONENT
    Component component;
  end DELETED_COMPONENT;

  function new
    input SCode.Element definition;
    output Component component;
  algorithm
    component := COMPONENT_DEF(definition, Modifier.NOMOD());
  end new;

  function newEnum
    input Type enumType;
    input String literalName;
    input Integer literalIndex;
    output Component component;
  algorithm
    component := ENUM_LITERAL(Expression.ENUM_LITERAL(enumType, literalName, literalIndex));
  end newEnum;

  function definition
    input Component component;
    output SCode.Element definition;
  algorithm
    COMPONENT_DEF(definition = definition) := component;
  end definition;

  function isDefinition
    input Component component;
    output Boolean isDefinition;
  algorithm
    isDefinition := match component
      case COMPONENT_DEF() then true;
      else false;
    end match;
  end isDefinition;

  function info
    "This function shouldn't be used! Use InstNode.info instead, so that e.g.
     enumeration literals can be handled correctly."
    input Component component;
    output SourceInfo info;
  algorithm
    info := match component
      case COMPONENT_DEF() then SCode.elementInfo(component.definition);
      case UNTYPED_COMPONENT() then component.info;
      case TYPED_COMPONENT() then component.info;
    end match;
  end info;

  function classInstance
    input Component component;
    output InstNode classInst;
  algorithm
    classInst := match component
      case UNTYPED_COMPONENT() then component.classInst;
      case TYPED_COMPONENT() then component.classInst;
    end match;
  end classInstance;

  function setClassInstance
    input InstNode classInst;
    input output Component component;
  algorithm
    () := match component
      case UNTYPED_COMPONENT()
        algorithm
          component.classInst := classInst;
        then
          ();

      case TYPED_COMPONENT()
        algorithm
          component.classInst := classInst;
        then
          ();

    end match;
  end setClassInstance;

  function getModifier
    input Component component;
    output Modifier modifier;
  algorithm
    modifier := match component
      case COMPONENT_DEF() then component.modifier;
      case TYPE_ATTRIBUTE() then component.modifier;
      else Modifier.NOMOD();
    end match;
  end getModifier;

  function setModifier
    input Modifier modifier;
    input output Component component;
  algorithm
    () := match component
      case COMPONENT_DEF()
        algorithm
          component.modifier := modifier;
        then
          ();
      case TYPE_ATTRIBUTE()
        algorithm
          component.modifier := modifier;
        then
          ();
    end match;
  end setModifier;

  function mergeModifier
    input Modifier modifier;
    input output Component component;
  algorithm
    component := match component
      case COMPONENT_DEF()
        algorithm
          component.modifier := Modifier.merge(modifier, component.modifier);
        then
          component;

      case TYPE_ATTRIBUTE()
        then TYPE_ATTRIBUTE(component.ty, Modifier.merge(modifier, component.modifier));
    end match;
  end mergeModifier;

  function getType
    input Component component;
    output Type ty;
  algorithm
    ty := match component
      case TYPED_COMPONENT() then component.ty;
      case UNTYPED_COMPONENT() then InstNode.getType(component.classInst);
      case ITERATOR() then component.ty;
      case TYPE_ATTRIBUTE() then component.ty;
      case DELETED_COMPONENT() then getType(component.component);
      else Type.UNKNOWN();
    end match;
  end getType;

  function setType
    input Type ty;
    input output Component component;
  algorithm
    component := match component
      case UNTYPED_COMPONENT()
        then TYPED_COMPONENT(component.classInst, ty, component.binding,
          component.condition, component.attributes, component.comment, component.info);

      case TYPED_COMPONENT()
        algorithm
          component.ty := ty;
        then
          component;

      case ITERATOR()
        algorithm
          component.ty := ty;
        then
          component;

    end match;
  end setType;

  function isTyped
    input Component component;
    output Boolean isTyped;
  algorithm
    isTyped := match component
      case TYPED_COMPONENT() then true;
      case ITERATOR(ty = Type.UNKNOWN()) then false;
      case ITERATOR() then true;
      case TYPE_ATTRIBUTE() then true;
      else false;
    end match;
  end isTyped;

  function unliftType
    input output Component component;
  algorithm
    () := match component
      local
        Type ty;

      case TYPED_COMPONENT(ty = Type.ARRAY(elementType = ty))
        algorithm
          component.ty := ty;
        then
          ();

      case ITERATOR(ty = Type.ARRAY(elementType = ty))
        algorithm
          component.ty := ty;
        then
          ();

      else ();
    end match;
  end unliftType;

  function getAttributes
    input Component component;
    output Component.Attributes attr;
  algorithm
    attr := match component
      case UNTYPED_COMPONENT() then component.attributes;
      case TYPED_COMPONENT() then component.attributes;
    end match;
  end getAttributes;

  function setAttributes
    input Component.Attributes attr;
    input output Component component;
  algorithm
    () := match component
      case UNTYPED_COMPONENT()
        algorithm
          component.attributes := attr;
        then
          ();

      case TYPED_COMPONENT()
        algorithm
          component.attributes := attr;
        then
          ();

    end match;
  end setAttributes;

  function getBinding
    input Component component;
    output Binding b;
  algorithm
    b := match component
      case UNTYPED_COMPONENT() then component.binding;
      case TYPED_COMPONENT() then component.binding;
      case TYPE_ATTRIBUTE() then Modifier.binding(component.modifier);
      else NFBinding.EMPTY_BINDING;
    end match;
  end getBinding;

  function setBinding
    input Binding binding;
    input output Component component;
  algorithm
    () := match component
      case UNTYPED_COMPONENT()
        algorithm
          component.binding := binding;
        then
          ();

      case TYPED_COMPONENT()
        algorithm
          component.binding := binding;
        then
          ();

      case TYPE_ATTRIBUTE()
        algorithm
          component.modifier := Modifier.setBinding(binding, component.modifier);
        then
          ();
    end match;
  end setBinding;

  function hasBinding
    input Component component;
    output Boolean b;
  algorithm
    b := Binding.isBound(getBinding(component));
  end hasBinding;

  function direction
    input Component component;
    output Direction direction;
  algorithm
    direction := match component
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(direction = direction)) then direction;
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(direction = direction)) then direction;
      else Direction.NONE;
    end match;
  end direction;

  function isInput
    input Component component;
    output Boolean isInput = direction(component) == Direction.INPUT;
  end isInput;

  function makeInput
    input output Component component;
  protected
    Attributes attr;
  algorithm
    () := match component
      case UNTYPED_COMPONENT(attributes = attr)
        algorithm
          attr.direction := Direction.INPUT;
          component.attributes := attr;
        then
          ();

      case TYPED_COMPONENT(attributes = attr)
        algorithm
          attr.direction := Direction.INPUT;
          component.attributes := attr;
        then
          ();

      else ();
    end match;
  end makeInput;

  function isOutput
    input Component component;
    output Boolean isOutput = direction(component) == Direction.OUTPUT;
  end isOutput;

  function parallelism
    input Component component;
    output Parallelism parallelism;
  algorithm
    parallelism := match component
      case TYPED_COMPONENT(attributes = ATTRIBUTES(parallelism = parallelism)) then parallelism;
      case UNTYPED_COMPONENT(attributes = ATTRIBUTES(parallelism = parallelism)) then parallelism;
      else Parallelism.NON_PARALLEL;
    end match;
  end parallelism;

  function variability
    input Component component;
    output Variability variability;
  algorithm
    variability := match component
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(variability = variability)) then variability;
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(variability = variability)) then variability;
      case ITERATOR() then component.variability;
      case ENUM_LITERAL() then Variability.CONSTANT;
      else Variability.CONTINUOUS;
    end match;
  end variability;

  function setVariability
    input Variability variability;
    input output Component component;
  algorithm
    () := match component
      local
        Attributes attr;

      case UNTYPED_COMPONENT(attributes = attr)
        algorithm
          attr.variability := variability;
          component.attributes := attr;
        then
          ();

      case TYPED_COMPONENT(attributes = attr)
        algorithm
          attr.variability := variability;
          component.attributes := attr;
        then
          ();

      else ();
    end match;
  end setVariability;

  function isConst
    input Component component;
    output Boolean isConst = variability(component) == Variability.CONSTANT;
  end isConst;

  function isParameter
    input Component component;
    output Boolean b = variability(component) == Variability.PARAMETER;
  end isParameter;

  function isStructuralParameter
    input Component component;
    output Boolean b = variability(component) == Variability.STRUCTURAL_PARAMETER;
  end isStructuralParameter;

  function isVar
    input Component component;
    output Boolean isVar = variability(component) == Variability.CONTINUOUS;
  end isVar;

  function isRedeclare
    input Component component;
    output Boolean isRedeclare;
  algorithm
    isRedeclare := match component
      case COMPONENT_DEF() then SCode.isElementRedeclare(component.definition);
      else false;
    end match;
  end isRedeclare;

  function isFinal
    input Component component;
    output Boolean isFinal;
  algorithm
    isFinal := match component
      case COMPONENT_DEF()
        then SCode.finalBool(SCode.prefixesFinal(SCode.elementPrefixes(component.definition)));
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(isFinal = isFinal)) then isFinal;
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(isFinal = isFinal)) then isFinal;
      else false;
    end match;
  end isFinal;

  function innerOuter
    input Component component;
    output InnerOuter io;
  algorithm
    io := match component
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(innerOuter = io)) then io;
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(innerOuter = io)) then io;
      case COMPONENT_DEF()
        then Prefixes.innerOuterFromSCode(SCode.prefixesInnerOuter(
          SCode.elementPrefixes(component.definition)));
      else InnerOuter.NOT_INNER_OUTER;
    end match;
  end innerOuter;

  function isInner
    input Component component;
    output Boolean isInner;
  protected
    InnerOuter io = innerOuter(component);
  algorithm
    isInner := io == InnerOuter.INNER or io == InnerOuter.INNER_OUTER;
  end isInner;

  function isOuter
    input Component component;
    output Boolean isOuter;
  protected
    InnerOuter io = innerOuter(component);
  algorithm
    isOuter := io == InnerOuter.OUTER or io == InnerOuter.INNER_OUTER;
  end isOuter;

  function isOnlyOuter
    input Component component;
    output Boolean isOuter = innerOuter(component) == InnerOuter.OUTER;
  end isOnlyOuter;

  function connectorType
    input Component component;
    output ConnectorType cty;
  algorithm
    cty := match component
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(connectorType = cty)) then cty;
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(connectorType = cty)) then cty;
      case DELETED_COMPONENT() then connectorType(component.component);
      else ConnectorType.NON_CONNECTOR;
    end match;
  end connectorType;

  function isFlow
    input Component component;
    output Boolean isFlow = connectorType(component) == ConnectorType.FLOW;
  end isFlow;

  function isConnector
    input Component component;
    output Boolean isConnector =
      Class.isConnectorClass(InstNode.getDerivedClass(classInstance(component)));
  end isConnector;

  function isExpandableConnector
    input Component component;
    output Boolean isExpandableConnector =
      Class.isExpandableConnectorClass(InstNode.getDerivedClass(classInstance(component)));
  end isExpandableConnector;

  function isIdentical
    input Component comp1;
    input Component comp2;
    output Boolean identical = false;
  algorithm
    if referenceEq(comp1, comp2) then
      identical := true;
    else
      identical := match (comp1, comp2)
        case (UNTYPED_COMPONENT(), UNTYPED_COMPONENT())
          algorithm
            if not Class.isIdentical(InstNode.getClass(comp1.classInst),
                                     InstNode.getClass(comp2.classInst)) then
              return;
            end if;

            if not Binding.isEqual(comp1.binding, comp2.binding) then
              return;
            end if;
          then
            true;

        else true;
      end match;
    end if;
  end isIdentical;

  function toString
    input String name;
    input Component component;
    output String str;
  algorithm
    str := match component
      local
        SCode.Element def;

      case COMPONENT_DEF(definition = def as SCode.Element.COMPONENT())
        then SCodeDump.unparseElementStr(def);

      case UNTYPED_COMPONENT()
        then Attributes.toString(component.attributes, Type.UNKNOWN()) +
             InstNode.name(component.classInst) + " " + name +
             List.toString(arrayList(component.dimensions), Dimension.toString, "", "[", ", ", "]", false) +
             Binding.toString(component.binding, " = ");

      case TYPED_COMPONENT()
        then Attributes.toString(component.attributes, component.ty) +
             Type.toString(component.ty) + " " + name +
             Binding.toString(component.binding, " = ");

      case TYPE_ATTRIBUTE()
        then name + Modifier.toString(component.modifier, printName = false);
    end match;
  end toString;

  function setDimensions
    input list<Dimension> dims;
    input output Component component;
  algorithm
    () := match component
      case UNTYPED_COMPONENT()
        algorithm
          component.dimensions := listArray(dims);
        then
          ();

      case TYPED_COMPONENT()
        algorithm
          component.ty := Type.liftArrayLeftList(Type.arrayElementType(component.ty), dims);
        then
          ();

      else ();
    end match;
  end setDimensions;

  function dimensionCount
    input Component component;
    output Integer count;
  algorithm
    count := match component
      case UNTYPED_COMPONENT() then arrayLength(component.dimensions);
      case TYPED_COMPONENT() then listLength(Type.arrayDims(component.ty));
      else 0;
    end match;
  end dimensionCount;

  function comment
    input Component component;
    output Option<SCode.Comment> comment;
  algorithm
    comment := match component
      case COMPONENT_DEF() then SCode.getElementComment(component.definition);
      case UNTYPED_COMPONENT() then component.comment;
      case TYPED_COMPONENT() then component.comment;
      else NONE();
    end match;
  end comment;

  function getEvaluateAnnotation
    input Component component;
    output Boolean evaluate;
  protected
    SCode.Comment cmt;
  algorithm
    evaluate := SCode.getEvaluateAnnotation(comment(component));
  end getEvaluateAnnotation;

  function getFixedAttribute
    input Component component;
    output Boolean fixed = false;
  protected
    list<Modifier> typeAttrs = {};
    Binding binding;
  algorithm
    // for parameters the default is fixed = true
    if isParameter(component) or isStructuralParameter(component) then
      fixed := true;
    else
      fixed := false;
    end if;

    binding := Class.lookupAttributeBinding("fixed", InstNode.getClass(classInstance(component)));

    // no fixed attribute present
    if Binding.isUnbound(binding) then
      return;
    end if;

    fixed := fixed and Expression.isTrue(Binding.getTypedExp(binding));

  end getFixedAttribute;

  function isDeleted
    input Component component;
    output Boolean isDeleted;
  algorithm
    isDeleted := match component
      local
        Binding condition;

      case TYPED_COMPONENT(condition = condition)
        then Binding.isBound(condition) and Expression.isFalse(Binding.getTypedExp(condition));

      case DELETED_COMPONENT() then true;
      else false;
    end match;
  end isDeleted;

  function isTypeAttribute
    input Component component;
    output Boolean isAttribute;
  algorithm
    isAttribute := match component
      case TYPE_ATTRIBUTE() then true;
      else false;
    end match;
  end isTypeAttribute;
end Component;

annotation(__OpenModelica_Interface="frontend");
end NFComponent;
