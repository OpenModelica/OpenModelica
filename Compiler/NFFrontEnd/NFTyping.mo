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

encapsulated package NFTyping
" file:        NFTyping.mo
  package:     NFTyping
  description: NFInst typing.


  Functions used by NFInst for typing.
"

import Binding = NFBinding;
import NFComponent.Component;
import Dimension = NFDimension;
import Equation = NFEquation;
import NFClass.Class;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFMod.Modifier;
import Statement = NFStatement;
import NFType.Type;
import Operator = NFOperator;
import NFPrefixes.Variability;
import NFPrefixes.ConnectorType;
import Prefixes = NFPrefixes;
import ExpOrigin = NFExpOrigin;
import Connector = NFConnector;
import Connection = NFConnection;

protected
import Builtin = NFBuiltin;
import Ceval = NFCeval;
import ClassInf;
import ComponentRef = NFComponentRef;
import Origin = NFComponentRef.Origin;
import ExecStat.execStat;
import Inst = NFInst;
import InstUtil = NFInstUtil;
import Lookup = NFLookup;
import MatchKind = NFTypeCheck.MatchKind;
import NFCall.Call;
import NFClass.ClassTree;
import SimplifyExp = NFSimplifyExp;
import Subscript = NFSubscript;
import TypeCheck = NFTypeCheck;
import Types;
import NFSections.Sections;
import List;
import DAEUtil;
import MetaModelica.Dangerous.listReverseInPlace;
import ComplexType = NFComplexType;
import Restriction = NFRestriction;

uniontype TypingError
  record NO_ERROR end NO_ERROR;

  record OUT_OF_BOUNDS
    Integer upperBound;
  end OUT_OF_BOUNDS;

  function isError
    input TypingError error;
    output Boolean isError;
  algorithm
    isError := match error
      case NO_ERROR() then false;
      else true;
    end match;
  end isError;
end TypingError;

public
function typeClass
  input InstNode cls;
  input String name;
algorithm
  typeComponents(cls);
  execStat("NFTyping.typeComponents(" + name + ")");
  typeBindings(cls);
  execStat("NFTyping.typeBindings(" + name + ")");
  typeSections(cls);
  execStat("NFTyping.typeSections(" + name + ")");
end typeClass;

function typeFunction
  input InstNode cls;
algorithm
  typeComponents(cls);
  typeBindings(cls);
  typeSections(cls);
end typeFunction;

function typeComponents
  input InstNode cls;
protected
  Class c = InstNode.getClass(cls), c2;
  ClassTree cls_tree;
  list<Dimension> dims;
algorithm
  () := match c
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          typeComponent(c);
        end for;
      then
        ();

    case Class.DERIVED_CLASS()
      algorithm
        // At this stage most of the information in the derived class has been
        // transferred to the component instance it belongs to, so we can
        // collapse the extends hierarchy by replacing it with the base class.
        c2 := InstNode.getClass(c.baseClass);
        // But keep the restriction.
        c2 := Class.setRestriction(c.restriction, c2);
        InstNode.updateClass(c2, cls);
        typeComponents(cls);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated class " +
          InstNode.name(cls));
      then
        fail();

  end match;
end typeComponents;

function makeClassType
  input InstNode clsNode;
  output Type ty;
protected
  Class cls;
  Restriction res;
algorithm
  cls := InstNode.getClass(clsNode);

  ty := match cls
    case Class.INSTANCED_CLASS(restriction = Restriction.CONNECTOR())
      then Type.COMPLEX(clsNode, makeConnectorType(cls.elements));

    else Class.getType(cls, clsNode);
  end match;
end makeClassType;

function makeConnectorType
  input ClassTree ctree;
  output ComplexType connectorTy;
protected
  list<InstNode> pots = {}, flows = {}, streams = {};
  ConnectorType cty;
algorithm
  for c in ClassTree.enumerateComponents(ctree) loop
    cty := Component.connectorType(InstNode.component(c));

    if cty == ConnectorType.FLOW then
      flows := c :: flows;
    elseif cty == ConnectorType.STREAM then
      streams := c :: streams;
    else
      pots := c :: pots;
    end if;
  end for;

  connectorTy := ComplexType.CONNECTOR(pots, flows, streams, false);
end makeConnectorType;

function typeComponent
  input InstNode component;
  output Type ty;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
algorithm
  ty := match c
    // An untyped component, type it.
    case Component.UNTYPED_COMPONENT()
      algorithm
        // Type the component's dimensions.
        typeDimensions(c.dimensions, node, c.binding, c.info);

        // Construct the type of the component and update the node with it.
        ty := Type.liftArrayLeftList(makeClassType(c.classInst), arrayList(c.dimensions));
        InstNode.updateComponent(Component.setType(ty, c), node);

        // Check that the component's attributes are valid.
        checkComponentAttributes(c.attributes, component);

        // Type the component's children.
        typeComponents(c.classInst);
      then
        ty;

    // A component that has already been typed, skip it.
    case Component.TYPED_COMPONENT() then c.ty;
    case Component.ITERATOR() then c.ty;
    case Component.ENUM_LITERAL(literal = Expression.ENUM_LITERAL(ty = ty)) then ty;

    // Any other type of component shouldn't show up here.
    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated component " +
          InstNode.name(component));
      then
        fail();

  end match;
end typeComponent;

// TODO: Make this check part of the check that a class adheres to its
//       restriction.
function checkComponentAttributes
  input Component.Attributes attributes;
  input InstNode component;
protected
  Component.Attributes attr = attributes;
  ConnectorType cty;
algorithm
  () := match attr
    case Component.ATTRIBUTES(connectorType = cty)
      algorithm
        // The Modelica specification forbids using stream outside connector
        // declarations, but has no such restriction for flow. To compromise we
        // print a warning for both flow and stream.
        if cty <> ConnectorType.POTENTIAL and not checkConnectorType(component) then
          Error.addSourceMessage(Error.CONNECTOR_PREFIX_OUTSIDE_CONNECTOR,
            {Prefixes.connectorTypeString(cty)}, InstNode.info(component));
          // Remove the prefix from the component, to avoid issues like a flow
          // equation being generated for it.
          attr.connectorType := ConnectorType.POTENTIAL;
          InstNode.componentApply(component, Component.setAttributes, attr);
        end if;
      then
        ();

    else ();
  end match;
end checkComponentAttributes;

function checkConnectorType
  input InstNode node;
  output Boolean isConnector;
algorithm
  isConnector := match node
    case InstNode.COMPONENT_NODE()
      then Class.isConnectorClass(InstNode.getClass(node)) or
           checkConnectorType(node.parent);

    else false;
  end match;
end checkConnectorType;

function typeIterator
  input InstNode iterator;
  input SourceInfo info;
  input Boolean structural "If the iteration range must be a parameter expression or not.";
protected
  Component c = InstNode.component(iterator);
  Binding binding;
  Type ty;
  Expression exp;
algorithm
  () := match c
    case Component.ITERATOR(binding = Binding.UNTYPED_BINDING())
      algorithm
        binding := typeBinding(c.binding, ExpOrigin.ITERATION_RANGE());

        // If the iteration range is structural, it must be a parameter expression.
        if structural then
          if Binding.variability(binding) > Variability.PARAMETER then
            Error.addSourceMessageAndFail(Error.NON_PARAMETER_ITERATOR_RANGE,
              {Binding.toString(binding)}, info);
          else
            SOME(exp) := Binding.typedExp(binding);
            exp := Ceval.evalExp(exp, Ceval.EvalTarget.RANGE(info));
            exp := SimplifyExp.simplifyExp(exp);
            binding := Binding.setTypedExp(exp, binding);
          end if;
        end if;

        ty := Binding.getType(binding);

        // The iteration range must be a vector expression.
        if not Type.isVector(ty) then
          Error.addSourceMessageAndFail(Error.FOR_EXPRESSION_TYPE_ERROR,
            {Binding.toString(binding), Type.toString(ty)}, info);
        end if;

        // The type of the iterator is the element type of the range expression.
        ty := Type.arrayElementType(ty);
        c := Component.ITERATOR(ty, binding);
        InstNode.updateComponent(c, iterator);
      then
        ();

    case Component.ITERATOR(binding = Binding.UNBOUND())
      algorithm
        assert(false, getInstanceName() + ": Implicit iteration ranges not yet implement");
      then
        fail();

    else
      algorithm
        assert(false, getInstanceName() + " got non-iterator " + InstNode.name(iterator));
      then
        fail();

  end match;
end typeIterator;

function typeDimensions
  input output array<Dimension> dimensions;
  input InstNode component;
  input Binding binding;
  input SourceInfo info;
algorithm
  for i in 1:arrayLength(dimensions) loop
    typeDimension(dimensions[i], component, binding, i, dimensions, info);
  end for;
end typeDimensions;

function typeDimension
  input output Dimension dimension;
  input InstNode component;
  input Binding binding;
  input Integer index;
  input array<Dimension> dimensions;
  input SourceInfo info;
algorithm
  dimension := match dimension
    local
      Expression exp;
      Variability var;
      Dimension dim;
      Binding b;
      TypingError ty_err;
      Type ty;
      Integer prop_dims;

    // Print an error when a dimension that's currently being processed is
    // found, which indicates a dependency loop. Another way of handling this
    // would be to instead view the dimension as unknown and infer it from the
    // binding, which means that things like x[size(x, 1)] = {...} could be
    // handled. But that is not specified and doesn't seem needed, and can also
    // give different results depending on the declaration order of components.
    case Dimension.UNTYPED(isProcessing = true)
      algorithm
        // TODO: Tell the user which variables are involved in the loop (can be
        //       found with DFS on the dimension expression. Maybe have a limit
        //       on the output in case there's a lot of dimensions involved.
        Error.addSourceMessage(Error.CYCLIC_DIMENSIONS,
          {String(index), InstNode.name(component), Expression.toString(dimension.dimension)}, info);
      then
        fail();

    // If the dimension is not typed, type it.
    case Dimension.UNTYPED()
      algorithm
        arrayUpdate(dimensions, index, Dimension.UNTYPED(dimension.dimension, true));

        (exp, ty, var) := typeExp(dimension.dimension, info, ExpOrigin.DIMENSION());
        TypeCheck.checkDimension(exp, ty, var, info);

        exp := Ceval.evalExp(exp, Ceval.EvalTarget.DIMENSION(component, index, exp, info));
        exp := SimplifyExp.simplifyExp(exp);

        // It's possible to get an array expression here, for example if the
        // dimension expression is a parameter whose binding comes from a
        // modifier on an array component. If all the elements are equal we can
        // just take one of them and use that, but we don't yet support the case
        // where they are different. Creating a dimension from an array leads to
        // weird things happening, so for now we print an error instead.
        if not Expression.arrayAllEqual(exp) then
          Error.addSourceMessage(Error.RAGGED_DIMENSION, {Expression.toString(exp)}, info);
          fail();
        end if;

        dim := Dimension.fromExp(Expression.arrayFirstScalar(exp), var);
        arrayUpdate(dimensions, index, dim);
      then
        dim;

    // If the dimension is unknown, try to infer it from the components binding.
    case Dimension.UNKNOWN()
      algorithm
        dim := match binding
          // Print an error if there's no binding.
          case Binding.UNBOUND()
            algorithm
              Error.addSourceMessage(Error.FAILURE_TO_DEDUCE_DIMS_NO_MOD,
                {String(index), InstNode.name(component)}, info);
            then
              fail();

          // An untyped binding, type the expression only as much as is needed
          // to get the dimension we're looking for.
          case Binding.UNTYPED_BINDING()
            algorithm
              prop_dims := InstNode.countDimensions(InstNode.parent(component), binding.propagatedLevels);
              dim := typeExpDim(binding.bindingExp, index + prop_dims, ExpOrigin.DIMENSION(), info);
            then
              dim;

          // A typed binding, get the dimension from the binding's type.
          case Binding.TYPED_BINDING()
            algorithm
              prop_dims := InstNode.countDimensions(InstNode.parent(component), binding.propagatedLevels);
              dim := nthDimensionBoundsChecked(binding.bindingType, index + prop_dims);
            then
              dim;

          else Dimension.UNKNOWN();
        end match;

        arrayUpdate(dimensions, index, dim);
      then
        dim;

    // Other kinds of dimensions are already typed.
    else dimension;
  end match;
end typeDimension;

function typeBindings
  input output InstNode cls;
protected
  Class c;
  ClassTree cls_tree;
  InstNode node;
algorithm
  c := InstNode.getClass(cls);

  () := match c
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          typeComponentBinding(c);
        end for;
      then
        ();

    case Class.INSTANCED_BUILTIN()
      algorithm
        c.attributes := typeTypeAttributes(c.attributes, c.ty);
        InstNode.updateClass(c, cls);
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated class " +
          InstNode.name(cls));
      then
        fail();

  end match;
end typeBindings;

function typeComponentBinding
  input InstNode component;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
algorithm
  () := match c
    local
      Binding binding;
      InstNode cls;
      MatchKind matchKind;
      Boolean dirty;

    case Component.TYPED_COMPONENT()
      algorithm
        binding := typeBinding(c.binding);
        dirty := not referenceEq(binding, c.binding);

        // If the binding changed during typing it means it was an untyped
        // binding which is now typed, and it needs to be type checked.
        if dirty then
          binding := TypeCheck.matchBinding(binding, c.ty, node);

          if Binding.variability(binding) > Component.variability(c) then
            Error.addSourceMessage(Error.HIGHER_VARIABILITY_BINDING,
              {InstNode.name(node), Prefixes.variabilityString(Component.variability(c)),
               "'" + Binding.toString(binding) + "'", Prefixes.variabilityString(Binding.variability(binding))},
              Binding.getInfo(binding));
            fail();
          end if;

          c.binding := binding;
        end if;

        cls := typeBindings(c.classInst);

        // The component's type can change, e.g. if it was a derived class that
        // was resolved to its base class.
        if not referenceEq(cls, c.classInst) then
          c.classInst := cls;
          dirty := true;
        end if;

        // Update the node if the component changed.
        if dirty then
          InstNode.updateComponent(c, node);
        end if;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got invalid node " + InstNode.name(node));
      then
        fail();

  end match;
end typeComponentBinding;

function typeBinding
  input output Binding binding;
  input ExpOrigin origin = ExpOrigin.BINDING();
algorithm
  binding := match binding
    local
      Expression exp;
      Type ty;
      Variability var;

    case Binding.UNTYPED_BINDING(bindingExp = exp)
      algorithm
        (exp, ty, var) := typeExp(exp, binding.info, origin);
      then
        Binding.TYPED_BINDING(exp, ty, var, binding.propagatedLevels, binding.info);

    case Binding.TYPED_BINDING() then binding;
    case Binding.UNBOUND() then binding;

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated binding");
      then
        fail();

  end match;
end typeBinding;

function typeTypeAttributes
  input output list<Modifier> attributes;
  input Type ty;
algorithm
  attributes := list(typeTypeAttribute(a) for a in attributes);

  _ := match ty
    case Type.REAL() then checkRealAttributes(attributes);
    case Type.INTEGER() then checkIntAttributes(attributes);
    case Type.BOOLEAN() then checkBoolAttributes(attributes);
    case Type.STRING() then checkStringAttributes(attributes);
    case Type.ENUMERATION() then checkEnumAttributes(attributes);
    case Type.ANY_TYPE() then checkAnyTypeAttributes(attributes);
    else
      algorithm
        assert(false, getInstanceName() + " got unknown type");
      then
        fail();
  end match;
end typeTypeAttributes;

function typeTypeAttribute
  input output Modifier attribute;
protected
  String name;
  Binding binding;
algorithm
  name := Modifier.name(attribute);
  binding := Modifier.binding(attribute);

  binding := typeBinding(binding);

  binding := match name
    case "fixed" then evalBinding(binding);
    else binding;
  end match;

  attribute := Modifier.setBinding(binding, attribute);
end typeTypeAttribute;

function evalBinding
  input output Binding binding;
algorithm
  binding := match binding
    local
      Expression exp;

    case Binding.TYPED_BINDING()
      algorithm
        exp := Ceval.evalExp(binding.bindingExp, Ceval.EvalTarget.ATTRIBUTE(binding.bindingExp, binding.info));
        exp := SimplifyExp.simplifyExp(exp);
      then
        Binding.TYPED_BINDING(exp, binding.bindingType, binding.variability, binding.propagatedLevels, binding.info);

    else
      algorithm
        assert(false, getInstanceName() + " failed for " + Binding.toString(binding));
      then
        fail();
  end match;
end evalBinding;

function checkRealAttributes
  input list<Modifier> attributes;
algorithm
  // TODO: Check that the attributes are valid Real attributes and that their
  // bindings have the correct types.
end checkRealAttributes;

function checkIntAttributes
  input list<Modifier> attributes;
algorithm
  // TODO: Check that the attributes are valid Integer attributes and that their
  // bindings have the correct types.
end checkIntAttributes;

function checkBoolAttributes
  input list<Modifier> attributes;
algorithm
  // TODO: Check that the attributes are valid Bool attributes and that their
  // bindings have the correct types.
end checkBoolAttributes;

function checkStringAttributes
  input list<Modifier> attributes;
algorithm
  // TODO: Check that the attributes are valid String attributes and that their
  // bindings have the correct types.
end checkStringAttributes;

function checkEnumAttributes
  input list<Modifier> attributes;
algorithm
  // TODO: Check that the attributes are valid enumeration attributes and that their
  // bindings have the correct types.
end checkEnumAttributes;

function checkAnyTypeAttributes
  input list<Modifier> attributes;
algorithm
  // TODO:
end checkAnyTypeAttributes;

function typeExp
  input output Expression exp;
  input SourceInfo info;
  input ExpOrigin origin = ExpOrigin.NO_ORIGIN();
        output Type ty;
        output Variability variability;
algorithm
  (exp, ty, variability) := match exp
    local
      Expression e1, e2, e3;
      Variability var1, var2, var3;
      Type ty1, ty2, ty3;
      Operator op;
      ComponentRef cref;
      ExpOrigin next_origin;

    case Expression.INTEGER() then (exp, Type.INTEGER(), Variability.CONSTANT);
    case Expression.REAL() then (exp, Type.REAL(), Variability.CONSTANT);
    case Expression.STRING() then (exp, Type.STRING(), Variability.CONSTANT);
    case Expression.BOOLEAN() then (exp, Type.BOOLEAN(), Variability.CONSTANT);
    case Expression.ENUM_LITERAL() then (exp, exp.ty, Variability.CONSTANT);

    case Expression.CREF()
      algorithm
        (cref, ty, variability) := typeCref(exp.cref, info);
      then
        (Expression.CREF(ty, cref), ty, variability);

    case Expression.TYPENAME()
      algorithm
        () := match origin
          case ExpOrigin.ITERATION_RANGE() then ();
          case ExpOrigin.DIMENSION() then ();
          else
            algorithm
              Error.addSourceMessage(Error.INVALID_TYPENAME_USE,
                {Type.typenameString(Type.arrayElementType(exp.ty))}, info);
            then
              fail();
        end match;
      then
        (exp, exp.ty, Variability.CONSTANT);

    case Expression.ARRAY() then typeArray(exp.elements, info);
    case Expression.RANGE() then typeRange(exp, info);
    case Expression.TUPLE() then typeTuple(exp.elements, info, origin);
    case Expression.SIZE() then typeSize(exp, info);
    case Expression.END() then typeEnd(origin, info);

    case Expression.BINARY()
      algorithm
        next_origin := ExpOrigin.next(origin);
        (e1, ty1, var1) := typeExp(exp.exp1, info, next_origin);
        (e2, ty2, var2) := typeExp(exp.exp2, info, next_origin);
        (exp, ty) := TypeCheck.checkBinaryOperation(e1, ty1, exp.operator, e2, ty2);
      then
        (exp, ty, Prefixes.variabilityMax(var1, var2));

    case Expression.UNARY()
      algorithm
        (e1, ty1, var1) := typeExp(exp.exp, info, ExpOrigin.next(origin));
        (exp, ty) := TypeCheck.checkUnaryOperation(e1, ty1, exp.operator);
      then
        (exp, ty, var1);

    case Expression.LBINARY()
      algorithm
        next_origin := ExpOrigin.next(origin);
        (e1, ty1, var1) := typeExp(exp.exp1, info, next_origin);
        (e2, ty2, var2) := typeExp(exp.exp2, info, next_origin);
        (exp, ty) := TypeCheck.checkLogicalBinaryOperation(e1, ty1, exp.operator, e2, ty2);
      then
        (exp, ty, Prefixes.variabilityMax(var1, var2));

    case Expression.LUNARY()
      algorithm
        (e1, ty1, var1) := typeExp(exp.exp, info, ExpOrigin.next(origin));
        (exp, ty) := TypeCheck.checkLogicalUnaryOperation(e1, ty1, exp.operator);
      then
        (exp, ty, var1);

    case Expression.RELATION()
      algorithm
        next_origin := ExpOrigin.next(origin);
        (e1, ty1, var1) := typeExp(exp.exp1, info, next_origin);
        (e2, ty2, var2) := typeExp(exp.exp2, info, next_origin);
        (exp, ty) := TypeCheck.checkRelationOperation(e1, ty1, exp.operator, e2, ty2);
      then
        (exp, ty, Prefixes.variabilityMax(var1, var2));

    case Expression.IF()
      algorithm
        next_origin := ExpOrigin.next(origin);
        (e1, ty1, var1) := typeExp(exp.condition, info, next_origin);
        (e2, ty2, var2) := typeExp(exp.trueBranch, info, next_origin);
        (e3, ty3, var3) := typeExp(exp.falseBranch, info, next_origin);
      then
        TypeCheck.checkIfExpression(e1, ty1, var1, e2, ty2, var2, e3, ty3, var3, info);

    case Expression.CALL()
      then Call.typeCall(exp, info);

    else
      algorithm
        assert(false, getInstanceName() + " got unknown expression");
      then
        fail();

  end match;
end typeExp;

function typeExpl
  input list<Expression> expl;
  input SourceInfo info;
  output list<Expression> explTyped = {};
  output list<Type> tyl = {};
  output list<Variability> varl = {};
protected
  Expression exp;
  Variability var;
  Type ty;
algorithm
  for e in listReverse(expl) loop
    (exp, ty, var) := typeExp(e, info);
    explTyped := exp :: explTyped;
    tyl := ty :: tyl;
    varl := var :: varl;
  end for;
end typeExpl;

function typeExpDim
  "Returns the requested dimension of the given expression, while doing as
   little typing as possible. This function returns TypingError.OUT_OF_BOUNDS if
   the given index doesn't refer to a valid dimension, in which case the
   returned dimension is undefined."
  input Expression exp;
  input Integer dimIndex;
  input ExpOrigin origin;
  input SourceInfo info;
        output Dimension dim;
        output TypingError error;
algorithm
  (dim, error) := match exp
    local
      Type ty;

    // An untyped array, use typeArrayDim to get the dimension.
    case Expression.ARRAY(ty = Type.UNKNOWN())
      then typeArrayDim(exp, dimIndex);

    // A typed array, fetch the dimension from its type.
    case Expression.ARRAY()
      then nthDimensionBoundsChecked(exp.ty, dimIndex);

    // A cref, use typeCrefDim to get the dimension.
    case Expression.CREF()
      then typeCrefDim(exp.cref, dimIndex, info);

    // Any other expression, type the whole expression and get the dimension
    // from the type.
    else
      algorithm
        (_, ty, _) := typeExp(exp, info, origin);
      then
        nthDimensionBoundsChecked(ty, dimIndex);

  end match;
end typeExpDim;

function typeArrayDim
  "Returns the requested dimension of an array dimension. This function is meant
   to be used on an untyped array, for a typed array it's better to just use
   e.g.  nthDimensionBoundsChecked on its type."
  input Expression arrayExp;
  input Integer dimIndex;
  output Dimension dim;
  output TypingError error;
algorithm
  // We don't yet know the number of dimensions, but the index must at least be 1.
  if dimIndex < 1 then
    dim := Dimension.UNKNOWN();
    error := TypingError.OUT_OF_BOUNDS(Expression.dimensionCount(arrayExp));
  else
    (dim, error) := typeArrayDim2(arrayExp, dimIndex);
  end if;
end typeArrayDim;

function typeArrayDim2
  input Expression arrayExp;
  input Integer dimIndex;
  input Integer dimCount = 0;
        output Dimension dim;
        output TypingError error;
algorithm
  (dim, error) := match (arrayExp, dimIndex)
    case (Expression.ARRAY(), 1)
      then (Dimension.fromExpList(arrayExp.elements), TypingError.NO_ERROR());

    // Modelica arrays are non-ragged and only the last dimension of an array
    // expression can be empty, so just traverse into the first element.
    case (Expression.ARRAY(), _)
      then typeArrayDim2(listHead(arrayExp.elements), dimIndex - 1, dimCount + 1);

    else
      algorithm
        dim := Dimension.UNKNOWN();
        error := TypingError.OUT_OF_BOUNDS(dimCount);
      then
        (dim, error);

  end match;
end typeArrayDim2;

function typeCrefDim
  input ComponentRef cref;
  input Integer dimIndex;
  input SourceInfo info;
  output Dimension dim;
  output TypingError error;
algorithm
  (dim, error) := match cref
    case ComponentRef.CREF(node = InstNode.COMPONENT_NODE())
      then typeComponentDim(cref.node, dimIndex, info);

    else
      algorithm
        assert(false, getInstanceName() + " got invalid cref.");
      then
        fail();

  end match;
end typeCrefDim;

function typeComponentDim
  input InstNode component;
  input Integer dimIndex;
  input SourceInfo info;
  output Dimension dim;
  output TypingError error;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
algorithm
  (dim, error) := match c
    local
      Dimension d;
      Type ty;

    // An untyped component, get the requested dimension from the component and type it.
    case Component.UNTYPED_COMPONENT()
      algorithm
        if dimIndex < 1 or dimIndex > arrayLength(c.dimensions) then
          error := TypingError.OUT_OF_BOUNDS(arrayLength(c.dimensions));
          d := Dimension.UNKNOWN();
        else
          error := TypingError.NO_ERROR();
          d := arrayGet(c.dimensions, dimIndex);
          d := typeDimension(d, node, c.binding, dimIndex, c.dimensions, c.info);
        end if;
      then
        (d, error);

    // A typed component, get the requested dimension from its type.
    else nthDimensionBoundsChecked(Component.getType(c), dimIndex);

  end match;
end typeComponentDim;

function nthDimensionBoundsChecked
  "Returns the requested dimension from the given type, along with a TypingError
   indicating whether the index was valid or not."
  input Type ty;
  input Integer dimIndex;
  output Dimension dim;
  output TypingError error;
protected
  Integer dim_size = Type.dimensionCount(ty);
algorithm
  if dimIndex < 1 or dimIndex > dim_size then
    dim := Dimension.UNKNOWN();
    error := TypingError.OUT_OF_BOUNDS(dim_size);
  else
    dim := Type.nthDimension(ty, dimIndex);
    error := TypingError.NO_ERROR();
  end if;
end nthDimensionBoundsChecked;

function typeCref
  input output ComponentRef cref;
  input SourceInfo info;
        output Type ty;
        output Variability variability;

  import NFComponentRef.Origin;
algorithm
  (cref, ty, variability) := match cref
    local
      ComponentRef rest_cr;
      Type node_ty, cref_ty;
      list<Subscript> subs;

    case ComponentRef.CREF(origin = Origin.SCOPE)
      then (cref, Type.UNKNOWN(), Variability.CONTINUOUS);

    case ComponentRef.CREF(node = InstNode.COMPONENT_NODE())
      algorithm
        node_ty := typeComponent(cref.node);
        variability := ComponentRef.getVariability(cref);
        subs := typeSubscripts(cref.subscripts, node_ty, cref.node, info);
        cref_ty := Type.subscript(node_ty, subs);
        (rest_cr, ty, _) := typeCref(cref.restCref, info);
        ty := Type.liftArrayLeftList(cref_ty, Type.arrayDims(ty));
      then
        (ComponentRef.CREF(cref.node, subs, cref_ty, cref.origin, rest_cr), ty, variability);

    case ComponentRef.CREF(node = InstNode.CLASS_NODE())
      then (cref, Type.UNKNOWN(), Variability.CONTINUOUS);

    case ComponentRef.EMPTY()
      then (cref, Type.UNKNOWN(), Variability.CONTINUOUS);

    case ComponentRef.WILD()
      then (cref, Type.UNKNOWN(), Variability.CONTINUOUS);

    else
      algorithm
        assert(false, getInstanceName() + " got unknown cref");
      then
        fail();

  end match;
end typeCref;

function typeSubscripts
  input list<Subscript> subscripts;
  input Type crefType;
  input InstNode node;
  input SourceInfo info;
  output list<Subscript> typedSubs;
protected
  list<Dimension> dims;
algorithm
  dims := Type.arrayDims(crefType);

  if listLength(subscripts) > listLength(dims) then
    Error.addSourceMessage(Error.WRONG_NUMBER_OF_SUBSCRIPTS,
      {InstNode.name(node) + Subscript.toStringList(subscripts),
       String(listLength(subscripts)), String(listLength(dims))}, info);
    fail();
  end if;

  typedSubs := {};
  for s in listReverse(subscripts) loop
    typedSubs := typeSubscript(s, listHead(dims), info) :: typedSubs;
    dims := listRest(dims);
  end for;
end typeSubscripts;

function typeSubscript
  input Subscript subscript;
  input Dimension dimension;
  input SourceInfo info;
  output Subscript outSubscript = subscript;
protected
  Expression e;
  Type ty, ety;
  MatchKind mk;
algorithm
  ty := match subscript
    // An untyped subscript, type the expression and create a typed subscript.
    case Subscript.UNTYPED()
      algorithm
        (e, ty, _) := typeExp(subscript.exp, info, ExpOrigin.SUBSCRIPT(dimension));

        if Type.isArray(ty) then
          outSubscript := Subscript.SLICE(e);
          ty := Type.unliftArray(ty);
        else
          outSubscript := Subscript.INDEX(e);
        end if;
      then
        ty;

    // Other subscripts have already been typed, but still need to be type checked.
    case Subscript.INDEX() then Expression.typeOf(subscript.index);
    case Subscript.SLICE() then Type.unliftArray(Expression.typeOf(subscript.slice));
    case Subscript.WHOLE() then Type.UNKNOWN();
    else
      algorithm
        assert(false, getInstanceName() + " got untyped subscript");
      then
        fail();
  end match;

  // Type check the subscript's type against the expected subscript type for the dimension.
  ety := Dimension.subscriptType(dimension);
  // We can have both : subscripts and : dimensions here, so we need to allow unknowns.
  (_, _, mk) := TypeCheck.matchTypes(ty, ety, e, allowUnknown = true);

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessage(Error.EXP_TYPE_MISMATCH,
      {Subscript.toString(subscript), Type.toString(ety), Type.toString(ty)}, info);
    fail();
  end if;
end typeSubscript;

function typeArray
  input list<Expression> elements;
  input SourceInfo info;
  output Expression arrayExp;
  output Type arrayType = Type.UNKNOWN();
  output Variability variability = Variability.CONSTANT;
protected
  Expression exp;
  list<Expression> expl = {};
  Variability var;
  Type ty;
algorithm
  for e in elements loop
    // TODO: Type checking.
    (exp, ty, var) := typeExp(e, info);
    variability := Prefixes.variabilityMax(var, variability);
    expl := exp :: expl;
  end for;

  arrayType := Type.liftArrayLeft(ty, Dimension.fromExpList(expl));
  arrayExp := Expression.ARRAY(arrayType, listReverse(expl));
end typeArray;

function typeRange
  input output Expression rangeExp;
  input SourceInfo info;
        output Type rangeType;
        output Variability variability;
protected
  Expression start_exp, step_exp, stop_exp;
  Type start_ty, step_ty, stop_ty;
  Option<Expression> ostep_exp;
  Option<Type> ostep_ty;
  Variability start_var, step_var, stop_var;
  TypeCheck.MatchKind ty_match;
algorithm
  Expression.RANGE(start = start_exp, step = ostep_exp, stop = stop_exp) := rangeExp;

  // Type start and stop.
  (start_exp, start_ty, start_var) := typeExp(start_exp, info);
  (stop_exp, stop_ty, stop_var) := typeExp(stop_exp, info);
  variability := Prefixes.variabilityMax(start_var, stop_var);

  // Type check start and stop.
  (start_exp, stop_exp, rangeType, ty_match) :=
    TypeCheck.matchExpressions(start_exp, start_ty, stop_exp, stop_ty);

  if TypeCheck.isIncompatibleMatch(ty_match) then
    printRangeTypeError(start_exp, start_ty, stop_exp, stop_ty, info);
  end if;

  if isSome(ostep_exp) then
    // Type step.
    SOME(step_exp) := ostep_exp;
    (step_exp, step_ty, step_var) := typeExp(step_exp, info);
    variability := Prefixes.variabilityMax(step_var, variability);

    // Type check start and step.
    (start_exp, step_exp, rangeType, ty_match) :=
      TypeCheck.matchExpressions(start_exp, start_ty, step_exp, step_ty);

    if TypeCheck.isIncompatibleMatch(ty_match) then
      printRangeTypeError(start_exp, start_ty, step_exp, step_ty, info);
    end if;

    // We've checked start-stop and start-step now, so step-stop must also be
    // type compatible. Stop might need to be type cast here though.
    stop_exp := TypeCheck.matchTypes_cast(stop_ty, rangeType, stop_exp);

    ostep_exp := SOME(step_exp);
    ostep_ty := SOME(step_ty);
  else
    ostep_exp := NONE();
    ostep_ty := NONE();
  end if;

  rangeType := TypeCheck.getRangeType(start_exp, ostep_exp, stop_exp, rangeType, info);
  rangeExp := Expression.RANGE(rangeType, start_exp, ostep_exp, stop_exp);
end typeRange;

function typeTuple
  input list<Expression> elements;
  input SourceInfo info;
  input ExpOrigin origin;
  output Expression tupleExp;
  output Type tupleType;
  output Variability variability;
protected
  list<Expression> expl;
  list<Type> tyl;
  list<Variability> valr;
algorithm
  () := match origin
    case ExpOrigin.LHS() then ();
    else
      algorithm
        Error.addSourceMessage(Error.RHS_TUPLE_EXPRESSION,
          {Expression.toString(Expression.TUPLE(Type.UNKNOWN(), elements))}, info);
      then
        fail();
  end match;

  (expl, tyl, valr) := typeExpl(elements, info);
  tupleType := Type.TUPLE(tyl, NONE());
  tupleExp := Expression.TUPLE(tupleType, expl);
  variability := if listEmpty(valr) then Variability.CONSTANT else listHead(valr);
end typeTuple;

protected
function printRangeTypeError
  input Expression exp1;
  input Type ty1;
  input Expression exp2;
  input Type ty2;
  input SourceInfo info;
algorithm
  Error.addSourceMessage(Error.RANGE_TYPE_MISMATCH,
    {Expression.toString(exp1), Type.toString(ty1),
     Expression.toString(exp2), Type.toString(ty2)}, info);
  fail();
end printRangeTypeError;

function typeSize
  input output Expression sizeExp;
  input SourceInfo info;
        output Type sizeType;
        output Variability variability;
protected
  Expression exp, index;
  Type exp_ty, index_ty;
  TypeCheck.MatchKind ty_match;
  Integer iindex, dim_size;
  Dimension dim;
  TypingError ty_err;
algorithm
  (sizeExp, sizeType, variability) := match sizeExp
    case Expression.SIZE(dimIndex = SOME(index))
      algorithm
        (index, index_ty, variability) := typeExp(index, info);

        // The second argument must be an Integer.
        (index, _, ty_match) :=
          TypeCheck.matchTypes(index_ty, Type.INTEGER(), index);

        if TypeCheck.isIncompatibleMatch(ty_match) then
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
            {"2", "size ", "dim", Expression.toString(index), Type.toString(index_ty), "Integer"}, info);
          fail();
        end if;

        // TODO: Only evaluate the index if it's a constant (parameter?),
        //       otherwise just return a size expression.
        index := Ceval.evalExp(index, Ceval.EvalTarget.IGNORE_ERRORS());
        index := SimplifyExp.simplifyExp(index);

        // TODO: Print an error if the index couldn't be evaluated to an int.
        Expression.INTEGER(iindex) := index;

        (dim, ty_err) := typeExpDim(sizeExp.exp, iindex, ExpOrigin.NO_ORIGIN(), info);

        () := match ty_err
          case NO_ERROR() then ();

          // The first argument wasn't an array.
          case OUT_OF_BOUNDS(0)
            algorithm
              Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {"size"}, info);
            then
              fail();

          // The index referred to an invalid dimension.
          case OUT_OF_BOUNDS()
            algorithm
              Error.addSourceMessage(Error.INVALID_SIZE_INDEX,
                {String(iindex), Expression.toString(sizeExp.exp), String(ty_err.upperBound)}, info);
            then
              fail();
        end match;

        dim_size := Dimension.size(dim);
      then
        (Expression.INTEGER(dim_size), Type.INTEGER(), Variability.CONSTANT);

    case Expression.SIZE()
      algorithm
        (exp, exp_ty, _) := typeExp(sizeExp.exp, info);

        // The first argument must be an array of any type.
        if not Type.isArray(exp_ty) then
          Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {"size"}, info);
          fail();
        end if;

        sizeType := Type.ARRAY(Type.INTEGER(), {Dimension.INTEGER(Type.dimensionCount(exp_ty))});
      then
        (Expression.SIZE(exp, NONE()), sizeType, Variability.PARAMETER);

  end match;
end typeSize;

function typeEnd
  input ExpOrigin origin;
  input SourceInfo info;
  output Expression exp;
  output Type ty;
  output Variability variability;
protected
  Dimension dim;
algorithm
  dim := match origin
    case ExpOrigin.SUBSCRIPT() then origin.dimension;
    else
      algorithm
        Error.addSourceMessageAndFail(Error.END_ILLEGAL_USE_ERROR, {}, info);
      then
        fail();
  end match;

  (exp, ty, variability) := match dim
    local
      Integer sz;

    case Dimension.INTEGER() then (Expression.INTEGER(dim.size), Type.INTEGER(), Variability.CONSTANT);
    case Dimension.BOOLEAN() then (Expression.BOOLEAN(true), Type.BOOLEAN(), Variability.CONSTANT);
    case Dimension.ENUM(enumType = ty as Type.ENUMERATION())
      algorithm
        sz := listLength(ty.literals);
      then
        (Expression.makeEnumLiteral(ty, sz), ty, Variability.CONSTANT);
    case Dimension.EXP() then (dim.exp, Expression.typeOf(dim.exp), dim.var);
    else
      algorithm
        assert(false, getInstanceName() + " got unknown dimension");
      then
        fail();
  end match;
end typeEnd;

function typeSections
  input InstNode classNode;
protected
  Class cls, typed_cls;
  array<InstNode> components;
  Sections sections;
algorithm
  cls := InstNode.getClass(classNode);

  _ := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = components),
        sections = sections)
      algorithm
        sections := Sections.map(sections, typeEquation, typeAlgorithm);
        typed_cls := Class.setSections(sections, cls);

        for i in 1:arrayLength(components) loop
          typeSections(InstNode.classScope(InstNode.resolveOuter(components[i])));
        end for;

        InstNode.updateClass(typed_cls, classNode);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated class " +
          InstNode.name(classNode));
      then
        fail();
  end match;
end typeSections;

function typeEquation
  input output Equation eq;
algorithm
  eq := match eq
    local
      Expression cond, e1, e2, e3;
      Type ty, ty1, ty2;
      list<Equation> eqs1, body;
      list<tuple<Expression, list<Equation>>> tybrs;
      InstNode iterator;
      MatchKind mk;
      Variability var, bvar;

    case Equation.EQUALITY()
      algorithm
        (e1, ty1) := typeExp(eq.lhs, eq.info, ExpOrigin.LHS());
        (e2, ty2) := typeExp(eq.rhs, eq.info, ExpOrigin.RHS());
        (e1, e2, ty, mk) := TypeCheck.matchExpressions(e1, ty1, e2, ty2);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR,
            {Expression.toString(e1) + " = " + Expression.toString(e2),
             Type.toString(ty1) + " = " + Type.toString(ty2)}, eq.info);
          fail();
        end if;
      then
        Equation.EQUALITY(e1, e2, ty, eq.info);

    case Equation.CONNECT()
      then typeConnect(eq.lhs, eq.rhs, eq.info);

    case Equation.FOR()
      algorithm
        typeIterator(eq.iterator, eq.info, structural = true);
        body := list(typeEquation(e) for e in eq.body);
      then
        Equation.FOR(eq.iterator, body, eq.info);

    case Equation.IF() then typeIfEquation(eq.branches, eq.info);

    case Equation.WHEN()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, eq.info, Error.WHEN_CONDITION_TYPE_ERROR, allowVector = true);
              eqs1 := list(typeEquation(beq) for beq in body);
            then (e1, eqs1);
          end match
        for br in eq.branches);
      then
        Equation.WHEN(tybrs, eq.info);

    case Equation.ASSERT()
      algorithm
        e1 := typeOperatorArg(eq.condition, Type.BOOLEAN(), "assert", "condition", 1, eq.info);
        e2 := typeOperatorArg(eq.message, Type.STRING(), "assert", "message", 2, eq.info);
        e3 := typeOperatorArg(eq.level, NFBuiltin.ASSERTIONLEVEL_TYPE, "assert", "level", 3, eq.info);
      then
        Equation.ASSERT(e1, e2, e3, eq.info);

    case Equation.TERMINATE()
      algorithm
        e1 := typeOperatorArg(eq.message, Type.STRING(), "terminate", "message", 1, eq.info);
      then
        Equation.TERMINATE(e1, eq.info);

    case Equation.REINIT()
      algorithm
        (e1, e2) := typeReinit(eq.cref, eq.reinitExp, eq.info);
      then
        Equation.REINIT(e1, e2, eq.info);

    case Equation.NORETCALL()
      algorithm
        e1 := typeExp(eq.exp, eq.info);
      then
        Equation.NORETCALL(e1, eq.info);

    else eq;
  end match;
end typeEquation;

function typeConnect
  input Expression lhsConn;
  input Expression rhsConn;
  input SourceInfo info;
  output Equation connEq;
protected
  Expression lhs, rhs;
  Type lhs_ty, rhs_ty;
  Variability lhs_var, rhs_var;
  MatchKind mk;
algorithm
  (lhs, lhs_ty, lhs_var) := typeExp(lhsConn, info);
  (rhs, rhs_ty, rhs_var) := typeExp(rhsConn, info);

  checkConnector(lhs, info);
  checkConnector(rhs, info);

  (lhs, rhs, _, mk) := TypeCheck.matchExpressions(lhs, lhs_ty, rhs, rhs_ty);

  if TypeCheck.isIncompatibleMatch(mk) then
    // TODO: Better error message.
    Error.addSourceMessage(Error.INVALID_CONNECTOR_VARIABLE,
      {Expression.toString(lhsConn), Expression.toString(rhsConn)}, info);
    fail();
  end if;

  // TODO: No point in doing this here since connectors aren't allowed to have
  //       variability prefixes. We should check each individual connection once
  //       the connections have been expanded during flattening instead.
  // It's an error if either connector is constant/parameter while the other isn't.
  //if (lhs_var <= Variability.PARAMETER) <> (rhs_var <= Varibility.PARAMETER then
  //  if lhs_var > Variability.PARAMETER then
  //    (lhs, rhs, lhs_var) := (rhs, lhs, rhs_var);
  //  end if;

  //  Error.addSourceMessage(Error.INCOMPATIBLE_CONNECTOR_VARIABILITY,
  //    {Expression.toString(lhs), Prefixes.variabilityString(lhs_var),
  //     Expression.toString(rhs)}, info);
  //  fail();
  //end if;

  connEq := Equation.CONNECT(lhs, rhs, info);
end typeConnect;

function checkConnector
  input Expression connExp;
  input SourceInfo info;
protected
  ComponentRef cr, rest_cr;
algorithm
  () := match connExp
    case Expression.CREF(cref = cr as ComponentRef.CREF(origin = Origin.CREF))
      algorithm
        if not InstNode.isConnector(cr.node) then
          Error.addSourceMessage(Error.INVALID_CONNECTOR_TYPE,
            {ComponentRef.toString(cr)}, info);
          fail();
        end if;

        checkConnectorForm(cr, info);
      then
        ();

    else
      algorithm
        Error.addSourceMessage(Error.INVALID_CONNECTOR_TYPE,
          {Expression.toString(connExp)}, info);
      then
        fail();
  end match;
end checkConnector;

function checkConnectorForm
  "Helper function for checkConnector. Checks that a connector cref uses the
   correct form, i.e. either c1.c2...cn or m.c."
  input ComponentRef cref;
  input SourceInfo info;
  input Boolean foundConnector = true;
algorithm
  () := match cref
    case ComponentRef.CREF(origin = Origin.CREF)
      algorithm
        // The only part of the connector reference allowed to not be a
        // non-connector is the very last part.
        if not foundConnector then
          Error.addSourceMessage(Error.INVALID_CONNECTOR_FORM,
            {ComponentRef.toString(cref)}, info);
          fail();
        end if;

        checkConnectorForm(cref.restCref, info, InstNode.isConnector(cref.node));
      then
        ();

    else ();
  end match;
end checkConnectorForm;

function typeAlgorithm
  input output list<Statement> alg;
algorithm
  alg := list(typeStatement(stmt) for stmt in alg);
end typeAlgorithm;

function typeStatement
  input output Statement st;
algorithm
  st := match st
    local
      Expression cond, e1, e2, e3;
      Type ty1, ty2, ty3;
      list<Statement> sts1, body;
      list<tuple<Expression, list<Statement>>> tybrs;
      InstNode iterator;
      MatchKind mk;

    case Statement.ASSIGNMENT()
      algorithm
        (e1, ty1) := typeExp(st.lhs, st.info, ExpOrigin.LHS());
        (e2, ty2) := typeExp(st.rhs, st.info, ExpOrigin.RHS());

        (e2,_, mk) := TypeCheck.matchTypes(ty2, ty1, e2);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR,
            {Expression.toString(e1), Expression.toString(e2),
             Type.toString(ty1), Type.toString(ty2)}, st.info);
          fail();
        end if;
      then
        Statement.ASSIGNMENT(e1, e2, st.info);

    case Statement.FOR()
      algorithm
        typeIterator(st.iterator, st.info, structural = false);
        body := typeAlgorithm(st.body);
      then
        Statement.FOR(st.iterator, body, st.info);

    case Statement.IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, st.info, Error.IF_CONDITION_TYPE_ERROR);
              sts1 := list(typeStatement(bst) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.IF(tybrs, st.info);

    case Statement.WHEN()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, st.info, Error.WHEN_CONDITION_TYPE_ERROR, allowVector = true);
              sts1 := list(typeStatement(bst) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.WHEN(tybrs, st.info);

    case Statement.ASSERT()
      algorithm
        e1 := typeOperatorArg(st.condition, Type.BOOLEAN(), "assert", "condition", 1, st.info);
        e2 := typeOperatorArg(st.message, Type.STRING(), "assert", "message", 2, st.info);
        e3 := typeOperatorArg(st.level, NFBuiltin.ASSERTIONLEVEL_TYPE, "assert", "level", 3, st.info);
      then
        Statement.ASSERT(e1, e2, e3, st.info);

    case Statement.TERMINATE()
      algorithm
        e1 := typeOperatorArg(st.message, Type.STRING(), "terminate", "message", 1, st.info);
      then
        Statement.TERMINATE(e1, st.info);

    case Statement.NORETCALL()
      algorithm
        e1 := typeExp(st.exp, st.info);
      then
        Statement.NORETCALL(e1, st.info);

    case Statement.WHILE()
      algorithm
        e1 := typeCondition(st.condition, st.info, Error.WHILE_CONDITION_TYPE_ERROR);
        sts1 := list(typeStatement(bst) for bst in st.body);
      then
        Statement.WHILE(e1, sts1, st.info);

    case Statement.FAILURE()
      algorithm
        sts1 := list(typeStatement(bst) for bst in st.body);
      then
        Statement.FAILURE(sts1, st.info);

    else st;
  end match;
end typeStatement;

function typeCondition
  input output Expression condition;
  input SourceInfo info;
  input Error.Message errorMsg;
  input Boolean allowVector = false;
        output Variability variability;
protected
  Type ty;
  MatchKind mk;
algorithm
  (condition, ty, variability) := typeExp(condition, info);

  if allowVector and Type.isVector(ty) then
    (_, _, mk) := TypeCheck.matchTypes(Type.arrayElementType(ty), Type.BOOLEAN(), condition);
  else
    (_, _, mk) := TypeCheck.matchTypes(ty, Type.BOOLEAN(), condition);
  end if;

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessage(errorMsg,
      {Expression.toString(condition), Type.toString(ty)}, info);
    fail();
  end if;
end typeCondition;

function typeIfEquation
  input list<tuple<Expression, list<Equation>>> branches;
  input SourceInfo info;
  output Equation ifEq;
protected
  Expression cond;
  list<Equation> eql;
  Variability accum_var = Variability.CONSTANT, var;
  list<tuple<Expression, list<Equation>>> bl = {};
algorithm
  for b in branches loop
    (cond, eql) := b;
    (cond, var) := typeCondition(cond, info, Error.IF_CONDITION_TYPE_ERROR);
    accum_var := Prefixes.variabilityMax(accum_var, var);

    if var <= Variability.PARAMETER then
      cond := Ceval.evalExp(cond, Ceval.EvalTarget.IGNORE_ERRORS());
      cond := SimplifyExp.simplifyExp(cond);
    end if;

    eql := list(typeEquation(e) for e in eql);
    bl := (cond, eql) :: bl;
  end for;

  // TODO: If accum_var <= PARAMETER, then each branch must have the same number
  //       of equations.
  ifEq := Equation.IF(listReverseInPlace(bl), info);
end typeIfEquation;

function typeOperatorArg
  input output Expression arg;
  input Type expectedType;
  input String operatorName;
  input String argName;
  input Integer argIndex;
  input SourceInfo info;
protected
  Type ty;
  MatchKind mk;
algorithm
  (arg, ty, _) := typeExp(arg, info);
  (arg, _, mk) := TypeCheck.matchTypes(ty, expectedType, arg);

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
      {intString(argIndex), operatorName, argName, Expression.toString(arg),
       Type.toString(ty), Type.toString(expectedType)}, info);
    fail();
  end if;
end typeOperatorArg;

function typeReinit
  input output Expression crefExp;
  input output Expression exp;
  input SourceInfo info;
protected
  Variability var;
  MatchKind mk;
  Type ty1, ty2;
algorithm
  (crefExp, ty1, var) := typeExp(crefExp, info);
  (exp, ty2, _) := typeExp(exp, info);

  // The first argument must be a cref.
  () := match crefExp
    case Expression.CREF() then ();
    else
      algorithm
        Error.addSourceMessage(Error.REINIT_MUST_BE_VAR_OR_ARRAY, {}, info);
      then
        fail();
  end match;

  // The first argument must be a continuous time variable.
  if var <> Variability.CONTINUOUS then
    Error.addSourceMessage(Error.REINIT_MUST_BE_VAR,
      {Expression.toString(crefExp), Prefixes.variabilityString(var)}, info);
    fail();
  end if;

  // The first argument must be a subtype of Real.
  (_, _, mk) := TypeCheck.matchTypes(Type.arrayElementType(ty1), Type.REAL(), crefExp);

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessage(Error.REINIT_MUST_BE_REAL,
      {Expression.toString(crefExp), Type.toString(Type.arrayElementType(ty1))}, info);
    fail();
  end if;

  // The second argument must be type compatible with the first.
  (exp, _, mk) := TypeCheck.matchTypes(ty2, ty1, exp);

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
      {"2", "reinit", "", Expression.toString(exp), Type.toString(ty2), Type.toString(ty1)}, info);
    fail();
  end if;
end typeReinit;

annotation(__OpenModelica_Interface="frontend");
end NFTyping;
