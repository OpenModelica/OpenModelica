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
import NFModifier.Modifier;
import Statement = NFStatement;
import NFType.Type;
import Operator = NFOperator;
import NFPrefixes.Variability;
import NFPrefixes.ConnectorType;
import Prefixes = NFPrefixes;
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
import NFModifier.ModTable;
import Package = NFPackage;
import NFFunction.Function;
import NFInstNode.CachedData;
import Direction = NFPrefixes.Direction;
import BindingOrigin = NFBindingOrigin;
import ElementSource;

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
package ExpOrigin
  // ExpOrigin is used to keep track of where an expression is coming from,
  // and is implemented as an integer bitfield.
  type Type = Integer;

  // Flag values:
  constant Type CLASS           = 0;     // In class.
  constant Type FUNCTION        = 1;     // In function.
  constant Type ALGORITHM       = 2;     // In algorithm section.
  constant Type EQUATION        = 4;     // In equation section.
  constant Type INITIAL         = 8;     // In initial section.
  constant Type LHS             = 16;    // On left hand side of equality/assignment.
  constant Type RHS             = 32;    // On right hand side of equality/assignment.
  constant Type WHEN            = 64;    // In when equation/statement.
  constant Type NONEXPANDABLE   = 128;   // In non-parameter if/for.
  constant Type ITERATION_RANGE = 256;   // In range used for iteration.
  constant Type DIMENSION       = 512;   // In dimension.
  constant Type BINDING         = 1024;  // In binding.
  constant Type CONDITION       = 2048;  // In conditional expression.
  constant Type SUBSCRIPT       = 4096;  // In subscript.
  constant Type SUBEXPRESSION   = 8192;  // Part of a larger expression.
  constant Type CONNECT         = 16384; // Part of connect argument.
  constant Type NOEVENT         = 32768; // Part of noEvent argument.

  // Combined flags:
  constant Type EQ_SUBEXPRESSION = intBitOr(EQUATION, SUBEXPRESSION);
  constant Type VALID_TYPENAME_SCOPE = intBitOr(ITERATION_RANGE, DIMENSION);
  constant Type DISCRETE_SCOPE = intBitOr(WHEN, intBitOr(INITIAL, FUNCTION));
end ExpOrigin;

public
function typeClass
  input InstNode cls;
  input String name;
algorithm
  typeComponents(cls, ExpOrigin.CLASS);
  execStat("NFTyping.typeComponents(" + name + ")");
  typeBindings(cls, cls, ExpOrigin.CLASS);
  execStat("NFTyping.typeBindings(" + name + ")");
  typeSections(cls, ExpOrigin.CLASS);
  execStat("NFTyping.typeSections(" + name + ")");
end typeClass;

function typeComponents
  input InstNode cls;
  input ExpOrigin.Type origin;
protected
  Class c = InstNode.getClass(cls), c2;
  ClassTree cls_tree;
  list<Dimension> dims;
algorithm
  () := match c
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          if not InstNode.isEmpty(c) then
            typeComponent(c, origin);
          end if;
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
        typeComponents(cls, origin);
      then
        ();

    case Class.INSTANCED_BUILTIN(restriction = Restriction.EXTERNAL_OBJECT())
      algorithm
        typeExternalObjectStructors(c.ty);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated class " + InstNode.name(cls), sourceInfo());
      then
        fail();

  end match;
end typeComponents;

function typeExternalObjectStructors
  input Type ty;
protected
  InstNode constructor, destructor;
  Function fn;
  Boolean typed, special;
algorithm
  Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT(constructor, destructor)) := ty;
  CachedData.FUNCTION({fn}, typed, special) := InstNode.getFuncCache(constructor);
  if not typed then
    fn := Function.typeFunction(fn);
    InstNode.setFuncCache(constructor, CachedData.FUNCTION({fn}, true, special));
  end if;

  CachedData.FUNCTION({fn}, typed, special) := InstNode.getFuncCache(destructor);
  if not typed then
    fn := Function.typeFunction(fn);
    InstNode.setFuncCache(destructor, CachedData.FUNCTION({fn}, true, special));
  end if;
end typeExternalObjectStructors;

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
  input ExpOrigin.Type origin;
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
        typeDimensions(c.dimensions, node, c.binding, origin, c.info);

        // Construct the type of the component and update the node with it.
        ty := Type.liftArrayLeftList(makeClassType(c.classInst), arrayList(c.dimensions));
        InstNode.updateComponent(Component.setType(ty, c), node);

        // Check that the component's attributes are valid.
        checkComponentAttributes(c.attributes, component);

        // Type the component's children.
        typeComponents(c.classInst, origin);
      then
        ty;

    // A component that has already been typed, skip it.
    case Component.TYPED_COMPONENT() then c.ty;
    case Component.ITERATOR() then c.ty;
    case Component.ENUM_LITERAL(literal = Expression.ENUM_LITERAL(ty = ty)) then ty;

    // Any other type of component shouldn't show up here.
    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated component " + InstNode.name(component), sourceInfo());
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
  if InstNode.isEmpty(node) then
    isConnector := false;
  else
    isConnector := Class.isConnectorClass(InstNode.getClass(node)) or
                   checkConnectorType(InstNode.parent(node));
  end if;
end checkConnectorType;

function typeIterator
  input InstNode iterator;
  input SourceInfo info;
  input ExpOrigin.Type origin;
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
        binding := typeBinding(c.binding, intBitOr(origin, ExpOrigin.ITERATION_RANGE));

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
        Error.assertion(false, getInstanceName() + ": Implicit iteration ranges not yet implement", sourceInfo());
      then
        fail();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-iterator " + InstNode.name(iterator), sourceInfo());
      then
        fail();

  end match;
end typeIterator;

function typeDimensions
  input output array<Dimension> dimensions;
  input InstNode component;
  input Binding binding;
  input ExpOrigin.Type origin;
  input SourceInfo info;
algorithm
  for i in 1:arrayLength(dimensions) loop
    typeDimension(dimensions, i, component, binding, origin, info);
  end for;
end typeDimensions;

function typeDimension
  input array<Dimension> dimensions;
  input Integer index;
  input InstNode component;
  input Binding binding;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Dimension dimension = dimensions[index];
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
        // Only give an error if we're not in a function.
        if intBitAnd(origin, ExpOrigin.FUNCTION) == 0 then
          // TODO: Tell the user which variables are involved in the loop (can be
          //       found with DFS on the dimension expression. Maybe have a limit
          //       on the output in case there's a lot of dimensions involved.
          Error.addSourceMessage(Error.CYCLIC_DIMENSIONS,
            {String(index), InstNode.name(component), Expression.toString(dimension.dimension)}, info);
          fail();
        end if;

        // If we are in a functions we allow e.g. size expression of unknown dimensions.
        dim := Dimension.UNKNOWN();
        arrayUpdate(dimensions, index, dim);
      then
        dim;

    // If the dimension is not typed, type it.
    case Dimension.UNTYPED()
      algorithm
        arrayUpdate(dimensions, index, Dimension.UNTYPED(dimension.dimension, true));

        (exp, ty, var) := typeExp(dimension.dimension, intBitOr(origin, ExpOrigin.DIMENSION), info);
        TypeCheck.checkDimensionType(exp, ty, info);

        if var <= Variability.PARAMETER then
          // Evaluate the dimension if it's a parameter expression.
          exp := Ceval.evalExp(exp, Ceval.EvalTarget.DIMENSION(component, index, exp, info));
          exp := SimplifyExp.simplifyExp(exp);
        else
          // Dimensions must be parameter expressions, unless we're in a function.
          if intBitAnd(origin, ExpOrigin.FUNCTION) == 0 then
            Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN,
              {Expression.toString(exp)}, info);
            fail();
          end if;
        end if;

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

    // If the dimension is unknown in a function, keep it unknown.
    case Dimension.UNKNOWN() guard intBitAnd(origin, ExpOrigin.FUNCTION) <> 0
      then dimension;

    // If the dimension is unknown in a class, try to infer it from the components binding.
    case Dimension.UNKNOWN()
      algorithm
        // If the component doesn't have a binding, try to use the start attribute instead.
        b := match binding
          case Binding.UNBOUND()
            then Modifier.binding(Class.lookupAttribute("start", InstNode.getClass(component)));
          else binding;
        end match;

        dim := match b
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
              prop_dims := InstNode.countDimensions(InstNode.parent(component),
                InstNode.level(component) - BindingOrigin.level(b.origin));
              dim := typeExpDim(b.bindingExp, index + prop_dims,
                intBitOr(origin, ExpOrigin.DIMENSION), info);
            then
              dim;

          // A typed binding, get the dimension from the binding's type.
          case Binding.TYPED_BINDING()
            algorithm
              prop_dims := InstNode.countDimensions(InstNode.parent(component),
                InstNode.level(component) - BindingOrigin.level(b.origin));
              dim := nthDimensionBoundsChecked(b.bindingType, index + prop_dims);
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
  input InstNode cls;
  input InstNode component;
  input ExpOrigin.Type origin;
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
          typeComponentBinding(c, origin);
        end for;
      then
        ();

    case Class.INSTANCED_BUILTIN()
      algorithm
        c.attributes := typeTypeAttributes(c.attributes, c.ty, component, origin);
        InstNode.updateClass(c, cls);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated class " + InstNode.name(cls), sourceInfo());
      then
        fail();

  end match;
end typeBindings;

function typeComponentBinding
  input InstNode component;
  input ExpOrigin.Type origin;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c;
algorithm
  if InstNode.isEmpty(component) then
    return;
  end if;

  c := InstNode.component(node);

  () := match c
    local
      Binding binding;
      InstNode cls;
      MatchKind matchKind;
      Boolean dirty;
      String name;
      Variability comp_var;

    // A component that's already been typed.
    case Component.TYPED_COMPONENT(binding = Binding.TYPED_BINDING()) then ();

    case Component.TYPED_COMPONENT()
      algorithm
        name := InstNode.name(component);
        binding := typeBinding(c.binding, intBitOr(origin, ExpOrigin.BINDING));
        dirty := not referenceEq(binding, c.binding);

        // If the binding changed during typing it means it was an untyped
        // binding which is now typed, and it needs to be type checked.
        if dirty then
          binding := TypeCheck.matchBinding(binding, c.ty, name, node);
          comp_var := Component.variability(c);

          if Binding.variability(binding) > comp_var then
            if comp_var == Variability.PARAMETER and intBitAnd(origin, ExpOrigin.FUNCTION) > 0 then
              Error.addSourceMessage(Error.FUNCTION_HIGHER_VARIABILITY_BINDING, {name, Prefixes.variabilityString(Component.variability(c)),
                 "'" + Binding.toString(c.binding) + "'", Prefixes.variabilityString(Binding.variability(binding))}, Binding.getInfo(binding));
            else
              Error.addSourceMessage(Error.HIGHER_VARIABILITY_BINDING,
                {name, Prefixes.variabilityString(Component.variability(c)),
                 "'" + Binding.toString(c.binding) + "'", Prefixes.variabilityString(Binding.variability(binding))},
                Binding.getInfo(binding));
              fail();
            end if;
          end if;

          // Evaluate the binding if the component is a constant.
          if comp_var == Variability.CONSTANT then
            // TODO: Allow this to fail for now. Once constant evaluation has
            // been improved we should print an error when a constant binding
            // couldn't be evaluated instead.
            try
              binding := evalBinding(binding);
            else
            end try;
          end if;

          c.binding := binding;
        end if;

        if Binding.isBound(c.condition) then
          c.condition := typeComponentCondition(c.condition, origin);
          dirty := true;
        end if;

        // Update the node if the component changed.
        if dirty then
          InstNode.updateComponent(c, node);
        end if;

        typeBindings(c.classInst, component, origin);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid node " + InstNode.name(node), sourceInfo());
      then
        fail();

  end match;
end typeComponentBinding;

function typeBinding
  input output Binding binding;
  input ExpOrigin.Type origin;
algorithm
  binding := match binding
    local
      Expression exp;
      Type ty;
      Variability var;
      SourceInfo info;

    case Binding.UNTYPED_BINDING(bindingExp = exp)
      algorithm
        info := Binding.getInfo(binding);
        (exp, ty, var) := typeExp(exp, origin, info);
      then
        Binding.TYPED_BINDING(exp, ty, var, binding.origin);

    case Binding.TYPED_BINDING() then binding;
    case Binding.UNBOUND() then binding;

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated binding", sourceInfo());
      then
        fail();

  end match;
end typeBinding;

function typeComponentCondition
  input output Binding condition;
  input ExpOrigin.Type origin;
algorithm
  condition := match condition
    local
      Expression exp;
      Type ty;
      Variability var;
      SourceInfo info;
      MatchKind mk;

    case Binding.UNTYPED_BINDING(bindingExp = exp)
      algorithm
        info := Binding.getInfo(condition);
        (exp, ty, var) := typeExp(exp, intBitOr(origin, ExpOrigin.CONDITION), info);
        (exp, _, mk) := TypeCheck.matchTypes(ty, Type.BOOLEAN(), exp);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR,
            {Expression.toString(exp), Type.toString(ty)}, info);
          fail();
        end if;

        if var > Variability.PARAMETER then
          Error.addSourceMessage(Error.COMPONENT_CONDITION_VARIABILITY,
            {Expression.toString(exp)}, info);
          fail();
        end if;

        exp := Ceval.evalExp(exp, Ceval.EvalTarget.CONDITION(info));
        exp := SimplifyExp.simplifyExp(exp);
      then
        Binding.FLAT_BINDING(exp);

  end match;
end typeComponentCondition;

function typeTypeAttributes
  input output list<Modifier> attributes;
  input Type ty;
  input InstNode component;
  input ExpOrigin.Type origin;
protected
  partial function attrTypeFn
    input String name;
    input Type ty;
    input SourceInfo info;
    output Type attrTy;
  end attrTypeFn;

  attrTypeFn ty_fn;
algorithm
  ty_fn := match ty
    case Type.REAL() then getRealAttributeType;
    case Type.INTEGER() then getIntAttributeType;
    case Type.BOOLEAN() then getBoolAttributeType;
    case Type.STRING() then getStringAttributeType;
    case Type.ENUMERATION() then getEnumAttributeType;
    else getAnyAttributeType;
  end match;

  attributes := list(typeTypeAttribute(a, ty_fn, ty, component, origin) for a in attributes);
end typeTypeAttributes;

function typeTypeAttribute
  input output Modifier attribute;
  input attrTypeFn attrTyFn;
  input Type ty;
  input InstNode component;
  input ExpOrigin.Type origin;

  partial function attrTypeFn
    input String name;
    input Type ty;
    input SourceInfo info;
    output Type attrTy;
  end attrTypeFn;
protected
  String name;
  Binding binding;
  BindingOrigin binding_origin;
  Type expected_ty, comp_ty;
algorithm
  () := match attribute
    // Normal modifier with no submodifiers.
    case Modifier.MODIFIER(name = name, binding = binding, subModifiers = ModTable.EMPTY())
      algorithm
        // Use the given function to get the expected type of the attribute.
        expected_ty := attrTyFn(name, ty, Modifier.info(attribute));
        binding_origin := Binding.getOrigin(binding);

        // Add the component's dimensions to the expected type, unless the
        // binding is declared 'each'.
        if not (BindingOrigin.isEach(binding_origin) or BindingOrigin.isFromClass(binding_origin)) then
          comp_ty := InstNode.getType(component);

          if Type.isArray(comp_ty) then
            expected_ty := Type.ARRAY(expected_ty, Type.arrayDims(comp_ty));
          end if;
        end if;

        // Type and type check the attribute.
        binding := typeBinding(binding, origin);
        binding := TypeCheck.matchBinding(binding, expected_ty, name, component);

        // Check the variability. All builtin attributes have parameter variability.
        if Binding.variability(binding) > Variability.PARAMETER then
          Error.addSourceMessage(Error.HIGHER_VARIABILITY_BINDING,
            {name, Prefixes.variabilityString(Variability.PARAMETER),
            "'" + Binding.toString(binding) + "'", Prefixes.variabilityString(Binding.variability(binding))},
            BindingOrigin.info(binding_origin));
          fail();
        end if;

        binding := match name
          case "fixed" then evalBinding(binding);
          case "stateSelect" then evalBinding(binding);
          else Package.replaceBindingConstants(binding);
        end match;

        attribute.binding := binding;
      then
        ();

    // Modifier with submodifier, e.g. Real x(start(y = 1)), is an error.
    case Modifier.MODIFIER()
      algorithm
        // Print an error for the first submodifier. The builtin attributes
        // don't have types as such, so for the error message to make sense we
        // join the attribute name and submodifier name together (e.g. start.y).
        name := attribute.name + "." + Util.tuple21(listHead(ModTable.toList(attribute.subModifiers)));
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, Type.toString(ty)}, attribute.info);
      then
        fail();

  end match;
end typeTypeAttribute;

function evalBinding
  input output Binding binding;
algorithm
  binding := match binding
    local
      Expression exp;

    case Binding.TYPED_BINDING()
      algorithm
        exp := Ceval.evalExp(binding.bindingExp, Ceval.EvalTarget.ATTRIBUTE(binding));
        exp := SimplifyExp.simplifyExp(exp);
      then
        Binding.TYPED_BINDING(exp, binding.bindingType, binding.variability, binding.origin);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed for " + Binding.toString(binding), sourceInfo());
      then
        fail();
  end match;
end evalBinding;

function getAttributeNameBinding
  input Modifier attr;
  input String typeName;
  output String name;
  output Binding binding;
algorithm
  (name, binding) := match attr
    case Modifier.MODIFIER(name = name, binding = binding, subModifiers = ModTable.EMPTY())
      then (name, binding);

    case Modifier.MODIFIER()
      algorithm
        name := attr.name + "." + Util.tuple21(listHead(ModTable.toList(attr.subModifiers)));
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, typeName}, attr.info);
      then
        fail();

  end match;
end getAttributeNameBinding;

function getRealAttributeType
  input String name;
  input Type ty;
  input SourceInfo info;
  output Type attrTy;
algorithm
  attrTy := match name
    case "quantity" then Type.STRING();
    case "unit" then Type.STRING();
    case "displayUnit" then Type.STRING();
    case "min" then ty;
    case "max" then ty;
    case "start" then ty;
    case "fixed" then Type.BOOLEAN();
    case "nominal" then ty;
    case "unbounded" then Type.BOOLEAN();
    case "stateSelect" then NFBuiltin.STATESELECT_TYPE;
    else
      algorithm
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, Type.toString(ty)}, info);
      then
        fail();
  end match;
end getRealAttributeType;

function getIntAttributeType
  input String name;
  input Type ty;
  input SourceInfo info;
  output Type attrTy;
algorithm
  attrTy := match name
    case "quantity" then Type.STRING();
    case "min" then ty;
    case "max" then ty;
    case "start" then ty;
    case "fixed" then Type.BOOLEAN();
    else
      algorithm
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, Type.toString(ty)}, info);
      then
        fail();
  end match;
end getIntAttributeType;

function getBoolAttributeType
  input String name;
  input Type ty;
  input SourceInfo info;
  output Type attrTy;
algorithm
  attrTy := match name
    case "quantity" then Type.STRING();
    case "start" then ty;
    case "fixed" then Type.BOOLEAN();
    else
      algorithm
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, Type.toString(ty)}, info);
      then
        fail();
  end match;
end getBoolAttributeType;

function getStringAttributeType
  input String name;
  input Type ty;
  input SourceInfo info;
  output Type attrTy;
algorithm
  attrTy := match name
    case "quantity" then Type.STRING();
    case "start" then ty;
    case "fixed" then Type.BOOLEAN();
    else
      algorithm
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, Type.toString(ty)}, info);
      then
        fail();
  end match;
end getStringAttributeType;

function getEnumAttributeType
  input String name;
  input Type ty;
  input SourceInfo info;
  output Type attrTy;
algorithm
  attrTy := match name
    case "quantity" then Type.STRING();
    case "min" then ty;
    case "max" then ty;
    case "start" then ty;
    case "fixed" then Type.BOOLEAN();
    else
      algorithm
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, Type.toString(ty)}, info);
      then
        fail();
  end match;
end getEnumAttributeType;

function getAnyAttributeType
  input String name;
  input Type ty;
  input SourceInfo info;
  output Type attrTy;
algorithm
  Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
    {name, Type.toString(ty)}, info);
  fail();
end getAnyAttributeType;

function typeExp
  "Types an untyped expression, returning the typed expression itself along with
   its type and variability. The default behaviour is to replace any constants
   found with their bound values (giving an error if they have none), but this
   can be turned off with the replaceConstants parameter. Note that replaceConstants
   is not propagated when typing subexpressions, because this is so far only
   used when we need the whole expression to be kept as a cref (like connectors)."
  input output Expression exp;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  input Boolean replaceConstants = true;
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
      Integer next_origin;

    case Expression.INTEGER() then (exp, Type.INTEGER(), Variability.CONSTANT);
    case Expression.REAL() then (exp, Type.REAL(), Variability.CONSTANT);
    case Expression.STRING() then (exp, Type.STRING(), Variability.CONSTANT);
    case Expression.BOOLEAN() then (exp, Type.BOOLEAN(), Variability.CONSTANT);
    case Expression.ENUM_LITERAL() then (exp, exp.ty, Variability.CONSTANT);

    case Expression.CREF()
      algorithm
        (cref, ty, variability) := typeCref(exp.cref, origin, info);
        e1 := Expression.CREF(ty, cref);

        if replaceConstants and variability == Variability.CONSTANT then
          e1 := Ceval.evalExp(e1, Ceval.EvalTarget.GENERIC(info));
        end if;
      then
        (e1, ty, variability);

    case Expression.TYPENAME()
      algorithm
        if intBitAnd(origin, ExpOrigin.VALID_TYPENAME_SCOPE) == 0 then
          Error.addSourceMessage(Error.INVALID_TYPENAME_USE,
            {Type.typenameString(Type.arrayElementType(exp.ty))}, info);
          fail();
        end if;
      then
        (exp, exp.ty, Variability.CONSTANT);

    case Expression.ARRAY() then typeArray(exp.elements, origin, info);
    case Expression.MATRIX() then typeMatrix(exp.elements, origin, info);
    case Expression.RANGE() then typeRange(exp, origin, info);
    case Expression.TUPLE() then typeTuple(exp.elements, origin, info);
    case Expression.SIZE() then typeSize(exp, origin, info);

    case Expression.END()
      algorithm
        // end is replaced in subscripts before we get here, so any end still
        // left should be outside a subscript and thus illegal.
        Error.addSourceMessage(Error.END_ILLEGAL_USE_ERROR, {}, info);
      then
        fail();

    case Expression.BINARY()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp1, next_origin, info);
        (e2, ty2, var2) := typeExp(exp.exp2, next_origin, info);
        (exp, ty) := TypeCheck.checkBinaryOperation(e1, ty1, exp.operator, e2, ty2, info);
      then
        (exp, ty, Prefixes.variabilityMax(var1, var2));

    case Expression.UNARY()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp, next_origin, info);
        (exp, ty) := TypeCheck.checkUnaryOperation(e1, ty1, exp.operator, info);
      then
        (exp, ty, var1);

    case Expression.LBINARY()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp1, next_origin, info);
        (e2, ty2, var2) := typeExp(exp.exp2, next_origin, info);
        (exp, ty) := TypeCheck.checkLogicalBinaryOperation(e1, ty1, exp.operator, e2, ty2, info);
      then
        (exp, ty, Prefixes.variabilityMax(var1, var2));

    case Expression.LUNARY()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp, next_origin, info);
        (exp, ty) := TypeCheck.checkLogicalUnaryOperation(e1, ty1, exp.operator, info);
      then
        (exp, ty, var1);

    case Expression.RELATION()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp1, next_origin, info);
        (e2, ty2, var2) := typeExp(exp.exp2, next_origin, info);
        (exp, ty) := TypeCheck.checkRelationOperation(e1, ty1, exp.operator, e2, ty2, origin, info);
        variability := Prefixes.variabilityMax(var1, var2);

        // A relation involving continuous expressions which is not inside
        // noEvent is a discrete expression.
        if intBitAnd(origin, ExpOrigin.NOEVENT) == 0 and variability == Variability.CONTINUOUS then
          variability := Variability.DISCRETE;
        end if;
      then
        (exp, ty, variability);

    case Expression.IF()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.condition, next_origin, info);
        (e2, ty2, var2) := typeExp(exp.trueBranch, next_origin, info);
        (e3, ty3, var3) := typeExp(exp.falseBranch, next_origin, info);
      then
        TypeCheck.checkIfExpression(e1, ty1, var1, e2, ty2, var2, e3, ty3, var3, info);

    case Expression.CALL()
      then Call.typeCall(exp, origin, info);

    case Expression.CAST()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.SUBEXPRESSION);
        (exp, ty, var1) := typeExp(exp.exp, next_origin, info);
      then
        (exp, ty, var1);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown expression: " + Expression.toString(exp), sourceInfo());
      then
        fail();

  end match;

  // Expressions inside when-clauses and initial sections are discrete.
  if intBitAnd(origin, ExpOrigin.DISCRETE_SCOPE) > 0 and variability == Variability.CONTINUOUS then
    variability := Variability.DISCRETE;
  end if;
end typeExp;

function typeExpl
  input list<Expression> expl;
  input ExpOrigin.Type origin;
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
    (exp, ty, var) := typeExp(e, origin, info);
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
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Dimension dim;
  output Option<Expression> typedExp = NONE();
  output TypingError error;
algorithm
  (dim, error) := match exp
    local
      Type ty;
      Expression e;

    // An untyped array, use typeArrayDim to get the dimension.
    case Expression.ARRAY(ty = Type.UNKNOWN())
      then typeArrayDim(exp, dimIndex);

    // A typed array, fetch the dimension from its type.
    case Expression.ARRAY()
      then nthDimensionBoundsChecked(exp.ty, dimIndex);

    // A cref, use typeCrefDim to get the dimension.
    case Expression.CREF()
      then typeCrefDim(exp.cref, dimIndex, origin, info);

    // Any other expression, type the whole expression and get the dimension
    // from the type.
    else
      algorithm
        (e, ty, _) := typeExp(exp, origin, info);
        typedExp := SOME(e);
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
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Dimension dim;
  output TypingError error;
algorithm
  (dim, error) := match cref
    case ComponentRef.CREF(node = InstNode.COMPONENT_NODE())
      then typeComponentDim(cref.node, dimIndex, listLength(cref.subscripts), origin, info);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid cref.", sourceInfo());
      then
        fail();

  end match;
end typeCrefDim;

function typeComponentDim
  input InstNode component;
  input Integer dimIndex;
  input Integer offset "The number of dimensions to skip due to subscripts.";
  input ExpOrigin.Type origin;
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
      Integer index;

    // An untyped component, get the requested dimension from the component and type it.
    case Component.UNTYPED_COMPONENT()
      algorithm
        index := dimIndex + offset;
        if index < 1 or index > arrayLength(c.dimensions) then
          error := TypingError.OUT_OF_BOUNDS(max(arrayLength(c.dimensions) - offset, 0));
          d := Dimension.UNKNOWN();
        else
          error := TypingError.NO_ERROR();
          d := typeDimension(c.dimensions, index, node, c.binding, origin, c.info);
        end if;
      then
        (d, error);

    // A typed component, get the requested dimension from its type.
    else nthDimensionBoundsChecked(Component.getType(c), dimIndex, offset);

  end match;
end typeComponentDim;

function nthDimensionBoundsChecked
  "Returns the requested dimension from the given type, along with a TypingError
   indicating whether the index was valid or not."
  input Type ty;
  input Integer dimIndex;
  input Integer offset = 0 "The number of dimensions to skip due to subscripts.";
  output Dimension dim;
  output TypingError error;
protected
  Integer dim_size = Type.dimensionCount(ty);
  Integer index = dimIndex + offset;
algorithm
  if index < 1 or index > dim_size then
    dim := Dimension.UNKNOWN();
    error := TypingError.OUT_OF_BOUNDS(dim_size - offset);
  else
    dim := Type.nthDimension(ty, index);
    error := TypingError.NO_ERROR();
  end if;
end nthDimensionBoundsChecked;

function typeCref
  input output ComponentRef cref;
  input ExpOrigin.Type origin;
  input SourceInfo info;
        output Type ty;
        output Variability variability;
protected
  Variability subs_var;
algorithm
  // Check that time isn't used in a function context.
  // TODO: Fix NFBuiltin.TIME_CREF so that the compiler treats it like an actual
  //       constant, then maybe we can use referenceEq here instead.
  if intBitAnd(origin, ExpOrigin.FUNCTION) > 0 and
     ComponentRef.firstName(cref) == "time" then
    Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"time"}, info);
    fail();
  end if;

  (cref, subs_var) := typeCref2(cref, origin, info);
  ty := ComponentRef.getSubscriptedType(cref);
  variability := Prefixes.variabilityMax(ComponentRef.getVariability(cref), subs_var);
end typeCref;

function typeCref2
  input output ComponentRef cref;
  input ExpOrigin.Type origin;
  input SourceInfo info;
        output Variability subsVariability;

  import NFComponentRef.Origin;
algorithm
  (cref, subsVariability) := match cref
    local
      ComponentRef rest_cr;
      Type node_ty;
      list<Subscript> subs;
      Variability subs_var, rest_var;

    case ComponentRef.CREF(origin = Origin.SCOPE)
      then (cref, Variability.CONSTANT);

    case ComponentRef.CREF(node = InstNode.COMPONENT_NODE())
      algorithm
        node_ty := typeComponent(cref.node, origin);
        (subs, subs_var) := typeSubscripts(cref.subscripts, node_ty, cref, origin, info);
        (rest_cr, rest_var) := typeCref2(cref.restCref, origin, info);
        subsVariability := Prefixes.variabilityMax(subs_var, rest_var);
      then
        (ComponentRef.CREF(cref.node, subs, node_ty, cref.origin, rest_cr), subsVariability);

    else (cref, Variability.CONSTANT);
  end match;
end typeCref2;

function typeSubscripts
  input list<Subscript> subscripts;
  input Type crefType;
  input ComponentRef cref;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output list<Subscript> typedSubs;
  output Variability variability = Variability.CONSTANT;
protected
  list<Dimension> dims;
  Dimension dim;
  Integer next_origin, i;
  Subscript sub;
  Variability var;
algorithm
  dims := Type.arrayDims(crefType);

  if listLength(subscripts) > listLength(dims) then
    Error.addSourceMessage(Error.WRONG_NUMBER_OF_SUBSCRIPTS,
      {ComponentRef.toString(cref),
       String(listLength(subscripts)), String(listLength(dims))}, info);
    fail();
  end if;

  typedSubs := {};
  next_origin := intBitOr(origin, ExpOrigin.SUBSCRIPT);
  i := 1;

  for s in subscripts loop
    dim :: dims := dims;
    (sub, var) := typeSubscript(s, dim, cref, i, origin, info);
    typedSubs := sub :: typedSubs;
    variability := Prefixes.variabilityMax(variability, var);
    i := i + 1;
  end for;

  typedSubs := listReverseInPlace(typedSubs);
end typeSubscripts;

function typeSubscript
  input Subscript subscript;
  input Dimension dimension;
  input ComponentRef cref;
  input Integer index;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Subscript outSubscript = subscript;
  output Variability variability = Variability.CONSTANT;
protected
  Expression e;
  Type ty, ety;
  MatchKind mk;
algorithm
  ty := match subscript
    // An untyped subscript, type the expression and create a typed subscript.
    case Subscript.UNTYPED()
      algorithm
        e := evaluateEnd(subscript.exp, dimension, cref, index, origin, info);
        (e, ty, variability) := typeExp(e, origin, info);

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
        Error.assertion(false, getInstanceName() + " got untyped subscript", sourceInfo());
      then
        fail();
  end match;

  // Type check the subscript's type against the expected subscript type for the dimension.
  ety := Dimension.subscriptType(dimension);
  // We can have both : subscripts and : dimensions here, so we need to allow unknowns.
  (_, _, mk) := TypeCheck.matchTypes(ty, ety, e, allowUnknown = true);

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessage(Error.SUBSCRIPT_TYPE_MISMATCH,
      {Subscript.toString(subscript), Type.toString(ty), Type.toString(ety)}, info);
    fail();
  end if;
end typeSubscript;

function typeArray
  input list<Expression> elements;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression arrayExp;
  output Type arrayType = Type.UNKNOWN();
  output Variability variability = Variability.CONSTANT;
protected
  Expression exp;
  list<Expression> expl = {}, expl2 = {};
  Variability var;
  Type ty1 = Type.UNKNOWN(), ty2, ty3;
  list<Type> tys = {};
  MatchKind mk;
  Integer n=1;
algorithm
  for e in elements loop
    (exp, ty2, var) := typeExp(e, origin, info);
    variability := Prefixes.variabilityMax(var, variability);
    (, ty3, mk) := TypeCheck.matchTypes(ty2, ty1, exp, allowUnknown = true);
    if TypeCheck.isIncompatibleMatch(mk) then
      // Try the other way around to get the super-type of the array
      (, ty3, mk) := TypeCheck.matchTypes(ty1, ty2, exp, allowUnknown = false);
      if TypeCheck.isCompatibleMatch(mk) then
        ty1 := ty3;
      end if;
    else
      ty1 := ty3;
    end if;
    expl := exp :: expl;
    tys := ty2 :: tys;
    n := n+1;
  end for;
  // Give the actual error-messages here after we got the super-type of the array
  for e in expl loop
    ty2::tys := tys;
    (exp, , mk) := TypeCheck.matchTypes(ty2, ty1, e);
    expl2 := exp::expl2;
    n := n-1;
    if TypeCheck.isIncompatibleMatch(mk) then
      Error.addSourceMessage(Error.NF_ARRAY_TYPE_MISMATCH, {String(n), Expression.toString(exp), Type.toString(ty2), Type.toString(ty1)}, info);
      fail();
    end if;
  end for;

  arrayType := Type.liftArrayLeft(ty1, Dimension.fromExpList(expl2));
  arrayExp := Expression.ARRAY(arrayType, expl2);
end typeArray;

function typeMatrix "The array concatenation operator"
  input list<list<Expression>> elements;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression arrayExp;
  output Type arrayType = Type.UNKNOWN();
  output Variability variability = Variability.CONSTANT;
protected
  Expression exp;
  list<Expression> expl = {}, res = {};
  Variability var;
  Type ty = Type.UNKNOWN();
  list<Type> tys = {}, resTys = {};
  Integer n = 2;
algorithm
  if listLength(elements) > 1 then
    for el in elements loop
      (exp, ty, var) := typeMatrixComma(el, origin, info);
      variability := Prefixes.variabilityMax(var, variability);
      expl := exp :: expl;
      tys := ty :: tys;
      n := max(n, Type.dimensionCount(ty));
    end for;
    for e in expl loop
      ty::tys := tys;
      (e,ty) := Expression.promote(e, ty, n);
      resTys := ty::resTys;
      res := e::res;
    end for;
    (arrayExp, arrayType) := Call.makeBuiltinCat(1, res, resTys, info);
  else
    (arrayExp, arrayType, variability) := typeMatrixComma(listHead(elements), origin, info);
    if Type.dimensionCount(arrayType) < 2 then
      (arrayExp, arrayType) := Expression.promote(arrayExp, arrayType, n);
    end if;
  end if;
end typeMatrix;

function typeMatrixComma
  input list<Expression> elements;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression arrayExp;
  output Type arrayType;
  output Variability variability = Variability.CONSTANT;
protected
  Expression exp;
  list<Expression> expl = {}, res = {};
  Variability var;
  Type ty = Type.UNKNOWN(), ty1, ty2, ty3;
  list<Type> tys = {}, tys2;
  Integer n = 2, pos;
  TypeCheck.MatchKind mk;
algorithm
  Error.assertion(not listEmpty(elements), getInstanceName() + " expected non-empty arguments", sourceInfo());
  if listLength(elements) > 1 then
    for e in elements loop
      (exp, ty1, ) := typeExp(e, origin, info);
      expl := exp :: expl;
      if Type.isEqual(ty, Type.UNKNOWN()) then
        ty := ty1;
      else
        (,,ty2,mk) := TypeCheck.matchExpressions(Expression.INTEGER(0), Type.arrayElementType(ty1), Expression.INTEGER(0), Type.arrayElementType(ty));
        if TypeCheck.isCompatibleMatch(mk) then
          ty := ty2;
        end if;
      end if;
      tys := ty1 :: tys;
      n := max(n, Type.dimensionCount(ty));
    end for;
    tys2 := {};
    res := {};
    pos := n+1;
    for e in expl loop
      ty1::tys := tys;
      pos := pos-1;
      if Type.dimensionCount(ty1) <> n then
        (e,ty1) := Expression.promote(e, ty1, n);
      end if;
      ty2 := Type.setArrayElementType(ty1, ty);
      (e, ty3, mk) := TypeCheck.matchTypes(ty1, ty2, e);
      if TypeCheck.isIncompatibleMatch(mk) then
        Error.addSourceMessageAndFail(Error.ARG_TYPE_MISMATCH, {String(pos), "matrix constructor ", "arg", Expression.toString(e), Type.toString(ty1), Type.toString(ty2)}, info);
      end if;
      res := e :: res;
      tys2 := ty3 :: tys2;
    end for;
    (arrayExp, arrayType) := Call.makeBuiltinCat(2, res, tys2, info);
  else
    (arrayExp, arrayType, variability) := typeExp(listHead(elements), origin, info);
  end if;
end typeMatrixComma;

function typeRange
  input output Expression rangeExp;
  input ExpOrigin.Type origin;
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
  (start_exp, start_ty, start_var) := typeExp(start_exp, origin, info);
  (stop_exp, stop_ty, stop_var) := typeExp(stop_exp, origin, info);
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
    (step_exp, step_ty, step_var) := typeExp(step_exp, origin, info);
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

  if variability <= Variability.PARAMETER then
    start_exp := SimplifyExp.simplifyExp(Ceval.evalExp(start_exp, Ceval.EvalTarget.IGNORE_ERRORS()));
    ostep_exp := SimplifyExp.simplifyExpOpt(Ceval.evalExpOpt(ostep_exp, Ceval.EvalTarget.IGNORE_ERRORS()));
    stop_exp := SimplifyExp.simplifyExp(Ceval.evalExp(stop_exp, Ceval.EvalTarget.IGNORE_ERRORS()));
  end if;

  rangeType := TypeCheck.getRangeType(start_exp, ostep_exp, stop_exp, rangeType, info);
  rangeExp := Expression.RANGE(rangeType, start_exp, ostep_exp, stop_exp);
end typeRange;

function typeTuple
  input list<Expression> elements;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression tupleExp;
  output Type tupleType;
  output Variability variability;
protected
  list<Expression> expl;
  list<Type> tyl;
  list<Variability> valr;
algorithm
  // Tuples are only allowed on the lhs side of an equality/assignment,
  // and only if they are alone and not part of a larger expression.
  if intBitAnd(origin, ExpOrigin.LHS) == 0 or
     intBitAnd(origin, ExpOrigin.SUBEXPRESSION) <> 0 then
    Error.addSourceMessage(Error.RHS_TUPLE_EXPRESSION,
      {Expression.toString(Expression.TUPLE(Type.UNKNOWN(), elements))}, info);
    fail();
  end if;

  (expl, tyl, valr) := typeExpl(elements, origin, info);
  tupleType := Type.TUPLE(tyl, NONE());
  tupleExp := Expression.TUPLE(tupleType, expl);
  variability := if listEmpty(valr) then Variability.CONSTANT else listHead(valr);
end typeTuple;

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
  "Types a size expression. If evaluate is true the size expression is also
   evaluated if the dimension is known and the index is a parameter expression,
   otherwise a typed size expression is returned."
  input output Expression sizeExp;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  input Boolean evaluate = true;
        output Type sizeType;
        output Variability variability;
protected
  Expression exp, index;
  Type exp_ty, index_ty;
  TypeCheck.MatchKind ty_match;
  Integer iindex, dim_size;
  Dimension dim;
  TypingError ty_err;
  Option<Expression> oexp;
algorithm
  (sizeExp, sizeType, variability) := match sizeExp
    case Expression.SIZE(exp = exp, dimIndex = SOME(index))
      algorithm
        (index, index_ty, variability) := typeExp(index, origin, info);

        // The second argument must be an Integer.
        (index, _, ty_match) :=
          TypeCheck.matchTypes(index_ty, Type.INTEGER(), index);

        if TypeCheck.isIncompatibleMatch(ty_match) then
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
            {"2", "size ", "dim", Expression.toString(index), Type.toString(index_ty), "Integer"}, info);
          fail();
        end if;

        if variability <= Variability.PARAMETER then
          // Evaluate the index if it's a constant.
          index := Ceval.evalExp(index, Ceval.EvalTarget.IGNORE_ERRORS());
          index := SimplifyExp.simplifyExp(index);

          // TODO: Print an error if the index couldn't be evaluated to an int.
          Expression.INTEGER(iindex) := index;

          // Get the iindex'd dimension of the expression.
          (dim, oexp, ty_err) := typeExpDim(exp, iindex, origin, info);
          checkSizeTypingError(ty_err, exp, iindex, info);

          if Dimension.isKnown(dim) and evaluate then
            // If the dimension size is known, return its size.
            exp := Expression.INTEGER(Dimension.size(dim));
          else
            // If the dimension size is unknown (e.g. in a function) or
            // evaluation is disabled, return a size expression instead.
            if isSome(oexp) then
              SOME(exp) := oexp;
            else
              exp := typeExp(exp, origin, info);
            end if;

            exp := Expression.SIZE(exp, SOME(index));
          end if;

          // Use the most variable of the index and the dimension as the variability
          // of the size expression.
          variability := Prefixes.variabilityMax(variability, Dimension.variability(dim));
        else
          // If the index is not a constant, type the whole expression.
          (exp, exp_ty) := typeExp(sizeExp.exp, origin, info);

          // Check that it's an array.
          if not Type.isArray(exp_ty) then
            Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {"size"}, info);
            fail();
          end if;

          // Since we don't know which dimension to take the size of, return a size expression.
          exp := Expression.SIZE(exp, SOME(index));
          variability := Variability.CONTINUOUS;
        end if;
      then
        (exp, Type.INTEGER(), variability);

    case Expression.SIZE()
      algorithm
        (exp, exp_ty, _) := typeExp(sizeExp.exp, origin, info);

        // The first argument must be an array of any type.
        if not Type.isArray(exp_ty) then
          Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {"size"}, info);
          fail();
        end if;

        sizeType := Type.ARRAY(Type.INTEGER(), {Dimension.fromInteger(Type.dimensionCount(exp_ty))});
      then
        (Expression.SIZE(exp, NONE()), sizeType, Variability.PARAMETER);

  end match;
end typeSize;

function checkSizeTypingError
  input TypingError typingError;
  input Expression exp;
  input Integer index;
  input SourceInfo info;
algorithm
  () := match typingError
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
          {String(index), Expression.toString(exp), String(typingError.upperBound)}, info);
      then
        fail();
  end match;
end checkSizeTypingError;

function evaluateEnd
  input Expression exp;
  input Dimension dim;
  input ComponentRef cref;
  input Integer index;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression outExp;
 algorithm
   outExp := match exp
     local
      Type ty;
      ComponentRef cr;

    case Expression.END() then Dimension.sizeExp(dim, cref, index);

    case Expression.CREF()
      algorithm
       (cr, ty) := typeCref(exp.cref, origin, info);
      then
       Expression.CREF(ty, cr);

    else Expression.mapShallow(exp,
      function evaluateEnd(dim = dim, cref = cref, index = index, info = info, origin = origin));

  end match;
end evaluateEnd;

function typeSections
  input InstNode classNode;
  input ExpOrigin.Type origin;
protected
  Class cls, typed_cls;
  array<InstNode> components;
  Sections sections;
  SourceInfo info;
  Integer initial_origin;
algorithm
  cls := InstNode.getClass(classNode);

  _ := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = components),
        sections = sections)
      algorithm
        sections := match sections
          case Sections.SECTIONS()
            algorithm
              initial_origin := intBitOr(origin, ExpOrigin.INITIAL);
            then
              Sections.map(sections,
                function typeEquation(origin = intBitOr(origin, ExpOrigin.EQUATION)),
                function typeAlgorithm(origin = intBitOr(origin, ExpOrigin.ALGORITHM)),
                function typeEquation(origin = intBitOr(initial_origin, ExpOrigin.EQUATION)),
                function typeAlgorithm(origin = intBitOr(initial_origin, ExpOrigin.ALGORITHM)));

          case Sections.EXTERNAL(explicit = true)
            algorithm
              info := InstNode.info(classNode);
              sections.args := list(typeExternalArg(arg, info, classNode) for arg in sections.args);
              sections.outputRef := typeCref(sections.outputRef, origin, info);
            then
              sections;

          case Sections.EXTERNAL()
            then makeDefaultExternalCall(sections, classNode);

          else sections;
        end match;

        typed_cls := Class.setSections(sections, cls);

        for c in components loop
          typeComponentSections(InstNode.resolveOuter(c), origin);
        end for;

        InstNode.updateClass(typed_cls, classNode);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated class " + InstNode.name(classNode), sourceInfo());
      then
        fail();
  end match;
end typeSections;

function typeExternalArg
  input Expression arg;
  input SourceInfo info;
  input InstNode node;
  output Expression outArg;
protected
  Type ty;
  Variability var;
  Expression index;
algorithm
  outArg := match arg
    case Expression.SIZE(dimIndex = SOME(_))
      algorithm
        outArg := typeSize(arg, ExpOrigin.FUNCTION, info, evaluate = false);
        Expression.SIZE(dimIndex = SOME(index)) := outArg;

        // Size expression must have a constant dimension index.
        if not Expression.isInteger(index) then
          Error.addSourceMessage(Error.EXTERNAL_ARG_NONCONSTANT_SIZE_INDEX,
            {Expression.toString(arg)}, info);
          fail();
        end if;
      then
        outArg;

    else
      algorithm
        (outArg, ty, var) := typeExp(arg, ExpOrigin.FUNCTION, info);
      then
        match arg
          // All kinds of crefs are allowed.
          case Expression.CREF() then outArg;
          else
            algorithm
              // The only other kind of expression that's allowed is scalar constants.
              if Type.isScalarBuiltin(ty) and var == Variability.CONSTANT then
                outArg := Ceval.evalExp(outArg, Ceval.EvalTarget.GENERIC(info));
                outArg := SimplifyExp.simplifyExp(arg);
              else
                Error.addSourceMessage(Error.EXTERNAL_ARG_WRONG_EXP,
                  {Expression.toString(outArg)}, info);
                fail();
              end if;
            then
              outArg;
        end match;
  end match;
end typeExternalArg;

function makeDefaultExternalCall
  "Constructs a default external call for an external function. If only one
   output exists a call 'output = func(input1, input2, ...)' is generated,
   otherwise a call 'func(param1, param2, ...)' is generated from the function's
   formal parameters and local variables."
  input output Sections extDecl;
  input InstNode fnNode;
algorithm
  extDecl := match extDecl
    local
      list<Expression> args;
      ComponentRef output_ref;
      Function fn;
      Boolean single_output;
      array<InstNode> comps;
      Component comp;
      Type ty;
      InstNode node;
      Expression exp;

    case Sections.EXTERNAL()
      algorithm
        // An explicit function call isn't needed for builtin calls.
        if extDecl.language == "builtin" then
          return;
        end if;

        // Fetch the cached function.
        CachedData.FUNCTION(funcs = {fn}) := InstNode.getFuncCache(fnNode);
        // Check whether we have a single output or not.
        single_output := listLength(fn.outputs) == 1;

        // When there's a single array output we can't generate a call on the
        // 'output = func(inputs)' form, so print a warning and treat is as
        // though it's not a single output.
        if single_output and Type.isArray(Function.returnType(fn)) then
          single_output := false;
          Error.addSourceMessage(Error.EXT_FN_SINGLE_RETURN_ARRAY,
            {extDecl.language}, InstNode.info(fnNode));
        end if;

        // If we have a single output, set the external declaration's output to
        // be a reference to the function's output. Otherwise leave it as empty.
        if single_output then
          {node} := fn.outputs;
          ty := InstNode.getType(node);
          extDecl.outputRef := ComponentRef.fromNode(node, ty);
        end if;

        // Generate function arguments from the function's components.
        comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(fn.node)));
        if arrayLength(comps) > 0 then
          args := {};
          for c in comps loop
            comp := InstNode.component(c);

            // Skip outputs if there's only a single output.
            if not single_output or Component.direction(comp) <> Direction.OUTPUT then
              // Generate a cref for the component and add it to the list of arguments.
              ty := Component.getType(comp);
              exp := Expression.CREF(ty, ComponentRef.fromNode(c, ty));
              args := exp :: args;

              // If the component is an array, generate a size expression for
              // each dimension too.
              for i in 1:Type.dimensionCount(ty) loop
                args := Expression.SIZE(exp, SOME(Expression.INTEGER(i))) :: args;
              end for;
            end if;
          end for;

          extDecl.args := listReverse(args);
        end if;
      then
        extDecl;

  end match;
end makeDefaultExternalCall;

function typeComponentSections
  input InstNode component;
  input ExpOrigin.Type origin;
protected
  Component comp;
algorithm
  if InstNode.isEmpty(component) then
    return;
  end if;

  comp := InstNode.component(component);

  () := match comp
    case Component.TYPED_COMPONENT()
      algorithm
        typeSections(comp.classInst, origin);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated component " + InstNode.name(component), sourceInfo());
      then
        fail();

  end match;
end typeComponentSections;

function typeEquation
  input output Equation eq;
  input ExpOrigin.Type origin;
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
      Integer next_origin;
      Equation tyeq;
      SourceInfo info;

    case Equation.EQUALITY()
      algorithm
        info := ElementSource.getInfo(eq.source);
        (e1, ty1) := typeExp(eq.lhs, intBitOr(origin, ExpOrigin.LHS), info);
        (e2, ty2) := typeExp(eq.rhs, intBitOr(origin, ExpOrigin.RHS), info);
        (e1, e2, ty, mk) := TypeCheck.matchExpressions(e1, ty1, e2, ty2);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR,
            {Expression.toString(e1) + " = " + Expression.toString(e2),
             Type.toString(ty1) + " = " + Type.toString(ty2)}, info);
          fail();
        end if;

        // Array equations containing function calls should not be scalarized.
        if Type.isArray(ty) and (Expression.hasArrayCall(e1) or Expression.hasArrayCall(e2)) then
          tyeq := Equation.ARRAY_EQUALITY(e1, e2, ty, eq.source);
        else
          tyeq := Equation.EQUALITY(e1, e2, ty, eq.source);
        end if;
      then
        tyeq;

    case Equation.CONNECT()
      then typeConnect(eq.lhs, eq.rhs, origin, eq.source);

    case Equation.FOR()
      algorithm
        info := ElementSource.getInfo(eq.source);
        typeIterator(eq.iterator, info, origin, structural = true);
        body := list(typeEquation(e, origin) for e in eq.body);
      then
        Equation.FOR(eq.iterator, body, eq.source);

    case Equation.IF() then typeIfEquation(eq.branches, origin, eq.source);

    case Equation.WHEN()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.WHEN);

        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, next_origin, eq.source, Error.WHEN_CONDITION_TYPE_ERROR, allowVector = true);
              eqs1 := list(typeEquation(beq, next_origin) for beq in body);
            then (e1, eqs1);
          end match
        for br in eq.branches);
      then
        Equation.WHEN(tybrs, eq.source);

    case Equation.ASSERT()
      algorithm
        info := ElementSource.getInfo(eq.source);
        e1 := typeOperatorArg(eq.condition, Type.BOOLEAN(), origin, "assert", "condition", 1, info);
        e2 := typeOperatorArg(eq.message, Type.STRING(), origin, "assert", "message", 2, info);
        e3 := typeOperatorArg(eq.level, NFBuiltin.ASSERTIONLEVEL_TYPE, origin, "assert", "level", 3, info);
      then
        Equation.ASSERT(e1, e2, e3, eq.source);

    case Equation.TERMINATE()
      algorithm
        info := ElementSource.getInfo(eq.source);
        e1 := typeOperatorArg(eq.message, Type.STRING(), origin, "terminate", "message", 1, info);
      then
        Equation.TERMINATE(e1, eq.source);

    case Equation.REINIT()
      algorithm
        (e1, e2) := typeReinit(eq.cref, eq.reinitExp, origin, eq.source);
      then
        Equation.REINIT(e1, e2, eq.source);

    case Equation.NORETCALL()
      algorithm
        e1 := typeExp(eq.exp, origin, ElementSource.getInfo(eq.source));
      then
        Equation.NORETCALL(e1, eq.source);

    else eq;
  end match;
end typeEquation;

function typeConnect
  input Expression lhsConn;
  input Expression rhsConn;
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
  output Equation connEq;
protected
  Expression lhs, rhs;
  Type lhs_ty, rhs_ty;
  Variability lhs_var, rhs_var;
  MatchKind mk;
  Integer next_origin;
  SourceInfo info;
algorithm
  info := ElementSource.getInfo(source);

  // Connections may not be used in if-equations unless the conditions are
  // parameter expressions.
  // TODO: Also check for cardinality etc. as per 8.3.3.
  if intBitAnd(origin, ExpOrigin.NONEXPANDABLE) <> 0 then
    Error.addSourceMessage(Error.CONNECT_IN_IF,
      {Expression.toString(lhsConn), Expression.toString(rhsConn)}, info);
    fail();
  end if;

  next_origin := intBitOr(origin, ExpOrigin.CONNECT);
  (lhs, lhs_ty, lhs_var) := typeExp(lhsConn, next_origin, info, replaceConstants = false);
  (rhs, rhs_ty, rhs_var) := typeExp(rhsConn, next_origin, info, replaceConstants = false);

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

  connEq := Equation.CONNECT(lhs, rhs, source);
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
  input ExpOrigin.Type origin;
algorithm
  alg := list(typeStatement(stmt, origin) for stmt in alg);
end typeAlgorithm;

function typeStatement
  input output Statement st;
  input ExpOrigin.Type origin;
algorithm
  st := match st
    local
      Expression cond, e1, e2, e3;
      Type ty1, ty2, ty3;
      list<Statement> sts1, body;
      list<tuple<Expression, list<Statement>>> tybrs;
      InstNode iterator;
      MatchKind mk;
      Integer next_origin;
      SourceInfo info;

    case Statement.ASSIGNMENT()
      algorithm
        info := ElementSource.getInfo(st.source);
        (e1, ty1) := typeExp(st.lhs, intBitOr(origin, ExpOrigin.LHS), info);
        (e2, ty2) := typeExp(st.rhs, intBitOr(origin, ExpOrigin.RHS), info);

        // TODO: Should probably only be allowUnknown = true if in a function.
        (e2,_, mk) := TypeCheck.matchTypes(ty2, ty1, e2, allowUnknown = true);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR,
            {Expression.toString(e1), Expression.toString(e2),
             Type.toString(ty1), Type.toString(ty2)}, info);
          fail();
        end if;
      then
        Statement.ASSIGNMENT(e1, e2, st.source);

    case Statement.FOR()
      algorithm
        info := ElementSource.getInfo(st.source);
        typeIterator(st.iterator, info, origin, structural = false);
        body := typeAlgorithm(st.body, origin);
      then
        Statement.FOR(st.iterator, body, st.source);

    case Statement.IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, origin, st.source, Error.IF_CONDITION_TYPE_ERROR);
              sts1 := list(typeStatement(bst, origin) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.IF(tybrs, st.source);

    case Statement.WHEN()
      algorithm
        next_origin := intBitOr(origin, ExpOrigin.WHEN);

        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, next_origin, st.source, Error.WHEN_CONDITION_TYPE_ERROR, allowVector = true);
              sts1 := list(typeStatement(bst, next_origin) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.WHEN(tybrs, st.source);

    case Statement.ASSERT()
      algorithm
        info := ElementSource.getInfo(st.source);
        e1 := typeOperatorArg(st.condition, Type.BOOLEAN(), origin, "assert", "condition", 1, info);
        e2 := typeOperatorArg(st.message, Type.STRING(), origin, "assert", "message", 2, info);
        e3 := typeOperatorArg(st.level, NFBuiltin.ASSERTIONLEVEL_TYPE, origin, "assert", "level", 3, info);
      then
        Statement.ASSERT(e1, e2, e3, st.source);

    case Statement.TERMINATE()
      algorithm
        info := ElementSource.getInfo(st.source);
        e1 := typeOperatorArg(st.message, Type.STRING(), origin, "terminate", "message", 1, info);
      then
        Statement.TERMINATE(e1, st.source);

    case Statement.NORETCALL()
      algorithm
        e1 := typeExp(st.exp, origin, ElementSource.getInfo(st.source));
      then
        Statement.NORETCALL(e1, st.source);

    case Statement.WHILE()
      algorithm
        e1 := typeCondition(st.condition, origin, st.source, Error.WHILE_CONDITION_TYPE_ERROR);
        sts1 := list(typeStatement(bst, origin) for bst in st.body);
      then
        Statement.WHILE(e1, sts1, st.source);

    case Statement.FAILURE()
      algorithm
        sts1 := list(typeStatement(bst, origin) for bst in st.body);
      then
        Statement.FAILURE(sts1, st.source);

    else st;
  end match;
end typeStatement;

function typeCondition
  input output Expression condition;
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
  input Error.Message errorMsg;
  input Boolean allowVector = false;
        output Variability variability;
protected
  Type ty;
  MatchKind mk;
  SourceInfo info;
algorithm
  info := ElementSource.getInfo(source);
  (condition, ty, variability) := typeExp(condition, origin, info);

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
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
  output Equation ifEq;
protected
  Expression cond;
  list<Equation> eql;
  Variability accum_var = Variability.CONSTANT, var;
  list<tuple<Expression, list<Equation>>> bl = {};
  Integer next_origin = origin;
algorithm
  for b in branches loop
    (cond, eql) := b;
    (cond, var) := typeCondition(cond, next_origin, source, Error.IF_CONDITION_TYPE_ERROR);
    accum_var := Prefixes.variabilityMax(accum_var, var);

    if var <= Variability.PARAMETER then
      // If the condition is a parameter expression, evaluate it so we can do
      // branch selection later on.
      cond := Ceval.evalExp(cond, Ceval.EvalTarget.IGNORE_ERRORS());
      cond := SimplifyExp.simplifyExp(cond);
    else
      // Otherwise, set the non-expandable bit in the origin, so we can check
      // that e.g. connect isn't used in any branches from here on.
      next_origin := intBitOr(origin, ExpOrigin.NONEXPANDABLE);
    end if;

    if not Expression.isFalse(cond) then
      eql := list(typeEquation(e, next_origin) for e in eql);
      bl := (cond, eql) :: bl;
    end if;
  end for;

  // TODO: If accum_var <= PARAMETER, then each branch must have the same number
  //       of equations.
  ifEq := Equation.IF(listReverseInPlace(bl), source);
end typeIfEquation;

function typeOperatorArg
  input output Expression arg;
  input Type expectedType;
  input ExpOrigin.Type origin;
  input String operatorName;
  input String argName;
  input Integer argIndex;
  input SourceInfo info;
protected
  Type ty;
  MatchKind mk;
algorithm
  (arg, ty, _) := typeExp(arg, origin, info);
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
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
protected
  Variability var;
  MatchKind mk;
  Type ty1, ty2;
  ComponentRef cref;
  SourceInfo info;
algorithm
  info := ElementSource.getInfo(source);
  (crefExp, ty1, _) := typeExp(crefExp, origin, info, replaceConstants = false);
  (exp, ty2, _) := typeExp(exp, origin, info);

  // The first argument must be a cref.
  cref := match crefExp
    case Expression.CREF() then crefExp.cref;
    else
      algorithm
        Error.addSourceMessage(Error.REINIT_MUST_BE_VAR_OR_ARRAY, {}, info);
      then
        fail();
  end match;

  // The first argument must be a continuous time variable.
  // Check the variability of the cref instead of the variability returned by
  // typeExp, since expressions in when-equation count as discrete.
  if ComponentRef.getVariability(cref) <> Variability.CONTINUOUS then
    Error.addSourceMessage(Error.REINIT_MUST_BE_VAR,
      {Expression.toString(crefExp),
       Prefixes.variabilityString(ComponentRef.getVariability(cref))}, info);
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
