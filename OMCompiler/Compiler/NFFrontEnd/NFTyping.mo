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
import Component = NFComponent;
import Dimension = NFDimension;
import Equation = NFEquation;
import Class = NFClass;
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
import Algorithm = NFAlgorithm;
import Record = NFRecord;

protected
import Builtin = NFBuiltin;
import BuiltinCall = NFBuiltinCall;
import Ceval = NFCeval;
import ComponentRef = NFComponentRef;
import Config;
import Origin = NFComponentRef.Origin;
import ExecStat.execStat;
import InstUtil = NFInstUtil;
import Lookup = NFLookup;
import MatchKind = NFTypeCheck.MatchKind;
import Call = NFCall;
import NFClassTree.ClassTree;
import Subscript = NFSubscript;
import TypeCheck = NFTypeCheck;
import Types;
import NFSections.Sections;
import List;
import MetaModelica.Dangerous.listReverseInPlace;
import ComplexType = NFComplexType;
import Restriction = NFRestriction;
import NFModifier.ModTable;
import Package = NFPackage;
import NFFunction.Function;
import NFInstNode.CachedData;
import Direction = NFPrefixes.Direction;
import ElementSource;
import System;
import ErrorExt;
import ErrorTypes;
import OperatorOverloading = NFOperatorOverloading;
import Structural = NFStructural;

public
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

package ExpOrigin
  // ExpOrigin is used to keep track of where an expression is coming from,
  // and is implemented as an integer bitfield.
  type Type = Integer;

  // Flag values:
  constant Type CLASS           = 0;                   // In class.
  constant Type FUNCTION        = intBitLShift(1,  0); // In function.
  constant Type ALGORITHM       = intBitLShift(1,  1); // In algorithm section.
  constant Type EQUATION        = intBitLShift(1,  2); // In equation section.
  constant Type INITIAL         = intBitLShift(1,  3); // In initial section.
  constant Type LHS             = intBitLShift(1,  4); // On left hand side of equality/assignment.
  constant Type RHS             = intBitLShift(1,  5); // On right hand side of equality/assignment.
  constant Type WHEN            = intBitLShift(1,  6); // In when equation/statement.
  constant Type CLOCKED         = intBitLShift(1,  7); // Part of a clocked when equation.
  constant Type FOR             = intBitLShift(1,  8); // In a for loop.
  constant Type IF              = intBitLShift(1,  9); // In an if equation/statement.
  constant Type WHILE           = intBitLShift(1, 10); // In a while loop.
  constant Type NONEXPANDABLE   = intBitLShift(1, 11); // In non-parameter if/for.
  constant Type ITERATION_RANGE = intBitLShift(1, 12); // In range used for iteration.
  constant Type DIMENSION       = intBitLShift(1, 13); // In dimension.
  constant Type BINDING         = intBitLShift(1, 14); // In binding.
  constant Type CONDITION       = intBitLShift(1, 15); // In conditional expression.
  constant Type SUBSCRIPT       = intBitLShift(1, 16); // In subscript.
  constant Type SUBEXPRESSION   = intBitLShift(1, 17); // Part of a larger expression.
  constant Type CONNECT         = intBitLShift(1, 18); // Part of connect argument.
  constant Type NOEVENT         = intBitLShift(1, 19); // Part of noEvent argument.
  constant Type ASSERT          = intBitLShift(1, 20); // Part of assert argument.

  // Combined flags:
  constant Type EQ_SUBEXPRESSION = intBitOr(EQUATION, SUBEXPRESSION);
  constant Type VALID_TYPENAME_SCOPE = intBitOr(ITERATION_RANGE, DIMENSION);
  constant Type DISCRETE_SCOPE = intBitOr(WHEN, intBitOr(INITIAL, FUNCTION));

  function isSingleExpression
    "Returns true if the given origin indicates the expression is alone on
     either side of an equality/assignment."
    input Type origin;
    output Boolean isSingle = origin < ITERATION_RANGE - 1;
  end isSingleExpression;

  function setFlag
    input Type origin;
    input Type flag;
    output Type newOrigin;
  algorithm
    newOrigin := intBitOr(origin, flag);
    annotation(__OpenModelica_EarlyInline=true);
  end setFlag;

  function flagSet
    input Type origin;
    input Type flag;
    output Boolean set;
  algorithm
    set := intBitAnd(origin, flag) > 0;
    annotation(__OpenModelica_EarlyInline=true);
  end flagSet;

  function flagNotSet
    input Type origin;
    input Type flag;
    output Boolean notSet;
  algorithm
    notSet := intBitAnd(origin, flag) == 0;
    annotation(__OpenModelica_EarlyInline=true);
  end flagNotSet;
end ExpOrigin;

public
function typeClass
  input InstNode cls;
algorithm
  typeClassType(cls, NFBinding.EMPTY_BINDING, ExpOrigin.CLASS, cls);
  typeComponents(cls, ExpOrigin.CLASS);
  execStat("NFTyping.typeComponents");
  typeBindings(cls, cls, ExpOrigin.CLASS);
  execStat("NFTyping.typeBindings");
  typeClassSections(cls, ExpOrigin.CLASS);
  execStat("NFTyping.typeClassSections");
end typeClass;

function typeComponents
  input InstNode cls;
  input ExpOrigin.Type origin;
protected
  Class c = InstNode.getClass(cls), c2;
  ClassTree cls_tree;
  InstNode ext_node, con, de;
algorithm
  () := match c
    case Class.INSTANCED_CLASS(restriction = Restriction.TYPE()) then ();

    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          typeComponent(c, origin);
        end for;

        () := match c.ty
          case Type.COMPLEX(complexTy = ComplexType.RECORD(constructor = con))
            algorithm
              typeStructor(con);
            then
              ();

          else ();
        end match;
      then
        ();

    // For derived types with dimensions we keep them as they are, because we
    // need to preserve the dimensions.
    case Class.TYPED_DERIVED(ty = Type.ARRAY())
      algorithm
        typeComponents(c.baseClass, origin);
      then
        ();

    // Derived types without dimensions can be collapsed.
    case Class.TYPED_DERIVED()
      algorithm
        typeComponents(c.baseClass, origin);
        c2 := InstNode.getClass(c.baseClass);
        c2 := Class.setRestriction(c.restriction, c2);
        InstNode.updateClass(c2, cls);
      then
        ();

    case Class.INSTANCED_BUILTIN(ty = Type.COMPLEX(complexTy =
        ComplexType.EXTERNAL_OBJECT(constructor = con, destructor = de)))
      algorithm
        typeStructor(con);
        typeStructor(de);
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

function typeStructor
  input InstNode node;
protected
  CachedData cache;
  list<Function> fnl;
algorithm
  cache := InstNode.getFuncCache(node);

  () := match cache
    case CachedData.FUNCTION(funcs = fnl, typed = false)
      algorithm
        fnl := list(Function.typeFunction(fn) for fn in fnl);
        fnl := list(OperatorOverloading.patchOperatorRecordConstructorBinding(fn) for fn in fnl);
        InstNode.setFuncCache(node, CachedData.FUNCTION(fnl, true, cache.specialBuiltin));
      then
        ();

    else ();
  end match;
end typeStructor;

function typeClassType
  input InstNode clsNode;
  input Binding componentBinding;
  input ExpOrigin.Type origin;
  input InstNode instanceNode;
  output Type ty;
protected
  Class cls, ty_cls;
  InstNode node, ty_node;
  Function fn;
  Boolean is_expandable;
algorithm
  cls := InstNode.getClass(clsNode);

  ty := match cls
    case Class.INSTANCED_CLASS(restriction = Restriction.CONNECTOR(isExpandable = is_expandable))
      algorithm
        ty := Type.COMPLEX(clsNode, makeConnectorType(cls.elements, is_expandable));
        cls.ty := ty;
        InstNode.updateClass(cls, clsNode);
      then
        ty;

    case Class.INSTANCED_CLASS(ty = Type.COMPLEX(cls = ty_node, complexTy = ComplexType.RECORD(constructor = node)))
      algorithm
        ty := Type.COMPLEX(ty_node, makeRecordType(node));
        cls.ty := ty;
        InstNode.updateClass(cls, clsNode);
      then
        ty;

    // A long class declaration of a type extending from a type has the type of the base class.
    case Class.INSTANCED_CLASS(ty = Type.COMPLEX(complexTy = ComplexType.EXTENDS_TYPE(node)))
      algorithm
        ty := typeClassType(node, componentBinding, origin, instanceNode);
        cls.ty := ty;
        InstNode.updateClass(cls, clsNode);
      then
        ty;

    // A component of function type, i.e. a functional input parameter.
    case Class.INSTANCED_CLASS(restriction = Restriction.FUNCTION())
        guard InstNode.isComponent(instanceNode)
      algorithm
        fn :: _ := Function.typeNodeCache(clsNode);
        ty := Type.FUNCTION(fn, NFType.FunctionType.FUNCTIONAL_PARAMETER);
        cls.ty := ty;
        InstNode.updateClass(cls, clsNode);
      then
        ty;

    case Class.INSTANCED_CLASS() then cls.ty;

    case Class.EXPANDED_DERIVED()
      algorithm
        typeDimensions(cls.dims, clsNode, componentBinding, origin, InstNode.info(clsNode));
        ty := typeClassType(cls.baseClass, componentBinding, origin, instanceNode);
        ty := Type.liftArrayLeftList(ty, arrayList(cls.dims));
        ty_cls := Class.TYPED_DERIVED(ty, cls.baseClass, cls.restriction);
        InstNode.updateClass(ty_cls, clsNode);
      then
        ty;

    case Class.INSTANCED_BUILTIN() then cls.ty;
    case Class.TYPED_DERIVED() then cls.ty;

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got noninstantiated class " +
          InstNode.name(clsNode), sourceInfo());
      then
        fail();

  end match;
end typeClassType;

function makeConnectorType
  input ClassTree ctree;
  input Boolean isExpandable;
  output ComplexType connectorTy;
protected
  list<InstNode> pots = {}, flows = {}, streams = {}, exps = {};
  ConnectorType.Type cty;
algorithm
  if isExpandable then
    for c in ClassTree.enumerateComponents(ctree) loop
      cty := Component.connectorType(InstNode.component(c));

      if intBitAnd(cty, ConnectorType.EXPANDABLE) > 0 then
        exps := c :: exps;
      else
        pots := c :: pots;
      end if;
    end for;

    connectorTy := ComplexType.EXPANDABLE_CONNECTOR(pots, exps);
  else
    for c in ClassTree.enumerateComponents(ctree) loop
      cty := Component.connectorType(InstNode.component(c));

      if intBitAnd(cty, ConnectorType.FLOW) > 0 then
        flows := c :: flows;
      elseif intBitAnd(cty, ConnectorType.STREAM) > 0 then
        streams := c :: streams;
      elseif intBitAnd(cty, ConnectorType.POTENTIAL) > 0 then
        pots := c :: pots;
      else
        Error.addInternalError("Invalid connector type on component " + InstNode.name(c), InstNode.info(c));
        fail();
      end if;
    end for;

    connectorTy := ComplexType.CONNECTOR(pots, flows, streams);

    if not listEmpty(streams) then
      System.setHasStreamConnectors(true);
    end if;
  end if;
end makeConnectorType;

function makeRecordType
  input InstNode constructor;
  output ComplexType recordTy;
protected
  CachedData cache;
  Function fn;
  list<Record.Field> fields;
algorithm
  cache := InstNode.getFuncCache(constructor);

  recordTy := match cache
    case CachedData.FUNCTION(funcs = fn :: _)
      algorithm
        fields := Record.collectRecordFields(fn.node);
      then
        ComplexType.RECORD(constructor, fields);

    else
      algorithm
        Error.assertion(false, getInstanceName() +
          " got record type without constructor", sourceInfo());
      then
        fail();
  end match;
end makeRecordType;

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
        ty := typeClassType(c.classInst, c.binding, origin, component);
        ty := Type.liftArrayLeftList(ty, arrayList(c.dimensions));
        InstNode.updateComponent(Component.setType(ty, c), node);

        // Check that flow/stream variables are Real.
        checkComponentStreamAttribute(c.attributes.connectorType, ty, component);

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
        Error.assertion(false, getInstanceName() + " got noninstantiated component " + InstNode.name(component), sourceInfo());
      then
        fail();

  end match;
end typeComponent;

function checkComponentStreamAttribute
  input ConnectorType.Type cty;
  input Type ty;
  input InstNode component;
protected
  Type ety;
algorithm
  if ConnectorType.isFlowOrStream(cty) then
    ety := Type.arrayElementType(ty);

    if not (Type.isReal(ety) or Type.isComplex(ety)) then
      Error.addSourceMessageAndFail(Error.NON_REAL_FLOW_OR_STREAM,
        {ConnectorType.toString(cty), InstNode.name(component)}, InstNode.info(component));
    end if;
  end if;
end checkComponentStreamAttribute;

function checkConnectorType
  input InstNode node;
  output Boolean isConnector;
protected
  InstNode dnode = InstNode.getDerivedNode(node);
algorithm
  if InstNode.isEmpty(dnode) or InstNode.isInnerOuterNode(dnode) then
    isConnector := false;
  else
    isConnector := Class.isConnectorClass(InstNode.getClass(dnode)) or
                   checkConnectorType(InstNode.parent(dnode));
  end if;
end checkConnectorType;

function typeIterator
  input InstNode iterator;
  input Expression range;
  input ExpOrigin.Type origin;
  input Boolean structural "If the iteration range must be a parameter expression or not.";
  output Expression outRange;
  output Type ty;
  output Variability var;
protected
  Component c = InstNode.component(iterator);
  Expression exp;
  SourceInfo info;
algorithm
  (outRange, ty, var) := match c
    case Component.ITERATOR(info = info)
      algorithm
        (exp, ty, var) := typeExp(range, ExpOrigin.setFlag(origin, ExpOrigin.ITERATION_RANGE), info);

        // If the iteration range is structural, it must be a parameter expression.
        if structural and var > Variability.PARAMETER then
          Error.addSourceMessageAndFail(Error.NON_PARAMETER_ITERATOR_RANGE,
            {Expression.toString(exp)}, info);
        end if;

        // The iteration range must be a vector expression.
        if not Type.isVector(ty) then
          Error.addSourceMessageAndFail(Error.FOR_EXPRESSION_TYPE_ERROR,
            {Expression.toString(exp), Type.toString(ty)}, info);
        end if;

        // The type of the iterator is the element type of the range expression.
        c := Component.ITERATOR(Type.arrayElementType(ty), var, info);
        InstNode.updateComponent(c, iterator);
      then
        (exp, ty, var);

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
      Expression exp, dim_exp;
      Option<Expression> oexp;
      Variability var;
      Dimension dim;
      Binding b;
      Type ty;
      TypingError ty_err;
      Integer parent_dims, dim_index;

    // Print an error when a dimension that's currently being processed is
    // found, which indicates a dependency loop. Another way of handling this
    // would be to instead view the dimension as unknown and infer it from the
    // binding, which means that things like x[size(x, 1)] = {...} could be
    // handled. But that is not specified and doesn't seem needed, and can also
    // give different results depending on the declaration order of components.
    case Dimension.UNTYPED(isProcessing = true)
      algorithm
        // Only give an error if we're not in a function.
        if ExpOrigin.flagNotSet(origin, ExpOrigin.FUNCTION) then
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

        (exp, ty, var) := typeExp(dimension.dimension, ExpOrigin.setFlag(origin, ExpOrigin.DIMENSION), info);
        TypeCheck.checkDimensionType(exp, ty, info);

        if ExpOrigin.flagNotSet(origin, ExpOrigin.FUNCTION) then
          // Dimensions must be parameter expressions in a non-function class.
          if var <= Variability.PARAMETER then
            dim_exp := Ceval.evalExpBinding(exp, Ceval.EvalTarget.DIMENSION(component, index, exp, info));
          else
            Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {Expression.toString(exp)}, info);
            fail();
          end if;
        else
          // For functions, only evaluate constant and structural parameter expressions.
          if var <= Variability.STRUCTURAL_PARAMETER then
            dim_exp := Ceval.evalExpBinding(exp, Ceval.EvalTarget.DIMENSION(component, index, exp, info));
          else
            dim_exp := exp;
          end if;
        end if;

        // It's possible to get an array expression here, for example if the
        // dimension expression is a parameter whose binding comes from a
        // modifier on an array component. If all the elements are equal we can
        // just take on of them and use that, otherwise we use the binding
        // expression but replace the expression in it with the evaluated one.
        exp := Expression.getBindingExp(dim_exp);
        if Expression.isArray(exp) then
          if Expression.arrayAllEqual(exp) then
            exp := Expression.arrayFirstScalar(exp);
          else
            exp := Expression.setBindingExp(exp, dim_exp);
          end if;
        end if;

        dim := Dimension.fromExp(exp, var);
        arrayUpdate(dimensions, index, dim);
      then
        dim;

    // If the dimension is unknown in a function, keep it unknown.
    case Dimension.UNKNOWN() guard ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION)
      then dimension;

    // If the dimension is unknown in a class, try to infer it from the components binding.
    case Dimension.UNKNOWN()
      algorithm
        b := binding;
        parent_dims := 0;

        if Binding.isUnbound(binding) then
          // If the component has no binding, try to use its parent's binding
          // (i.e. for record fields where the record instance has a binding).
          (b, parent_dims) := getRecordElementBinding(component);

          if Binding.isUnbound(b) then
            // If the component still doesn't have a binding, try to use the start attribute instead.
            // TODO: Any attribute should actually be fine to use here.
            parent_dims := 0;
            b := Class.lookupAttributeBinding("start", InstNode.getClass(component));
          end if;
        end if;

        (dim, ty_err) := match b
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
              dim_index := index + Binding.propagatedDimCount(b) + parent_dims;
              (dim, oexp, ty_err) := typeExpDim(b.bindingExp, dim_index, ExpOrigin.setFlag(origin, ExpOrigin.DIMENSION), info);

              // If the deduced dimension is unknown, evaluate the binding and try again.
              if Dimension.isUnknown(dim) and not TypingError.isError(ty_err) then
                exp := if isSome(oexp) then Util.getOption(oexp) else b.bindingExp;
                exp := Ceval.evalExp(exp, Ceval.EvalTarget.DIMENSION(component, index, exp, info));
                (dim, ty_err) := nthDimensionBoundsChecked(Expression.typeOf(exp), dim_index);
              end if;
            then
              (dim, ty_err);

          // A typed binding, get the dimension from the binding's type.
          case Binding.TYPED_BINDING()
            algorithm
              dim_index := index + parent_dims;
              (dim, ty_err) := nthDimensionBoundsChecked(b.bindingType, dim_index);

              // If the deduced dimension is unknown, evaluate the binding and try again.
              if Dimension.isUnknown(dim) and not TypingError.isError(ty_err) then
                exp := Ceval.evalExp(b.bindingExp, Ceval.EvalTarget.DIMENSION(component, index, b.bindingExp, info));
                (dim, ty_err) := nthDimensionBoundsChecked(Expression.typeOf(exp), dim_index);
              end if;
            then
              (dim, ty_err);

        end match;

        () := match ty_err
          case TypingError.OUT_OF_BOUNDS()
            algorithm
              Error.addSourceMessage(Error.DIMENSION_DEDUCTION_FROM_BINDING_FAILURE,
                {String(index), InstNode.name(component), Binding.toString(b)}, info);
            then
              fail();

          else ();
        end match;

        // Make sure the dimension is constant evaluted, and also mark it as structural.
        dim := match dim
          case Dimension.EXP(exp = exp)
            algorithm
              Structural.markExp(exp);
              exp := Ceval.evalExp(exp, Ceval.EvalTarget.DIMENSION(component, index, exp, info));
            then
              Dimension.fromExp(exp, dim.var);

          case Dimension.UNKNOWN()
            algorithm
              Error.addInternalError(getInstanceName() + " returned unknown dimension in a non-function context", info);
            then
              fail();

          else dim;
        end match;

        arrayUpdate(dimensions, index, dim);
      then
        dim;

    // Other kinds of dimensions are already typed.
    else dimension;
  end match;

  verifyDimension(dimension, component, info);
end typeDimension;

function verifyDimension
  input Dimension dimension;
  input InstNode component;
  input SourceInfo info;
algorithm
  () := match dimension
    case Dimension.INTEGER()
      algorithm
        // Check that integer dimensions are not negative.
        if dimension.size < 0 then
          Error.addSourceMessage(Error.NEGATIVE_DIMENSION_INDEX,
            {String(dimension.size), InstNode.name(component)}, info);
          fail();
        end if;
      then
        ();

    else ();
  end match;
end verifyDimension;

function makeDimension
  input Expression dimExp;
  input Expression unevaledExp;
  input Variability variability;
  output Dimension outDimension;
protected
  Expression exp = dimExp;
algorithm
  if Expression.isArray(exp) then
    if Expression.arrayAllEqual(exp) then
      exp := Expression.arrayFirstScalar(exp);
    else

    end if;
  end if;

  outDimension := Dimension.fromExp(exp, variability);
end makeDimension;

function getRecordElementBinding
  "Tries to fetch the binding for a given record field by using the binding of
   the record instance."
  input InstNode component;
  output Binding binding;
  output Integer parentDims = 0;
protected
  InstNode parent;
  Component comp;
  Expression exp;
  Binding parent_binding;
algorithm
  parent := InstNode.derivedParent(component);

  if InstNode.isComponent(parent) then
    // Get the binding of the component's parent.
    comp := InstNode.component(parent);
    parent_binding := Component.getBinding(comp);

    if Binding.isUnbound(parent_binding) then
      // If the parent has no binding, try the parent's parent.
      (binding, parentDims) := getRecordElementBinding(parent);
    else
      // Otherwise type the binding, so we can safely look up the field name.
      binding := typeBinding(parent_binding, ExpOrigin.CLASS);

      // If the binding wasn't typed before, update the parent component with it
      // so we don't have to type it again.
      if not referenceEq(parent_binding, binding) then
        InstNode.componentApply(parent, Component.setBinding, binding);
      end if;
    end if;

    parentDims := parentDims + Component.dimensionCount(comp);

    // If we found a binding, get the binding for the field from it.
    if Binding.isBound(binding) then
      binding := Binding.recordFieldBinding(component, binding);
    end if;
  else
    binding := NFBinding.EMPTY_BINDING;
  end if;
end getRecordElementBinding;

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

    case Class.INSTANCED_BUILTIN(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          typeComponentBinding(c, origin);
        end for;
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    case Class.TYPED_DERIVED()
      algorithm
        typeBindings(c.baseClass, component, origin);
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
  input Boolean typeChildren = true;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c;
  Binding binding;
  InstNode cls;
  MatchKind matchKind;
  String name;
  Variability comp_var, comp_eff_var, bind_var, bind_eff_var;
  Component.Attributes attrs;
algorithm
  c := InstNode.component(node);

  () := match c
    case Component.TYPED_COMPONENT(binding = Binding.UNTYPED_BINDING(), attributes = attrs)
      algorithm
        name := InstNode.name(component);
        binding := c.binding;

        ErrorExt.setCheckpoint(getInstanceName());
        try
          checkBindingEach(c.binding);
          binding := typeBinding(binding, ExpOrigin.setFlag(origin, ExpOrigin.BINDING));

          if not (Config.getGraphicsExpMode() and stringEq(name, "graphics")) then
            binding := TypeCheck.matchBinding(binding, c.ty, name, node);
          end if;

          comp_var := checkComponentBindingVariability(name, c, binding, origin);

          if comp_var <> attrs.variability then
            attrs.variability := comp_var;
            c.attributes := attrs;
          end if;
        else
          if Binding.isBound(c.condition) then
            binding := Binding.INVALID_BINDING(binding, ErrorExt.getCheckpointMessages());
          else
            ErrorExt.delCheckpoint(getInstanceName());
            fail();
          end if;
        end try;
        ErrorExt.delCheckpoint(getInstanceName());

        c.binding := binding;

        if Binding.isBound(c.condition) then
          c.condition := typeComponentCondition(c.condition, origin);
        end if;

        InstNode.updateComponent(c, node);

        if typeChildren then
          typeBindings(c.classInst, component, origin);
        end if;
      then
        ();

    // A component without a binding, or with a binding that's already been typed.
    case Component.TYPED_COMPONENT()
      algorithm
        checkBindingEach(c.binding);

        if Binding.isTyped(c.binding) then
          c.binding := TypeCheck.matchBinding(c.binding, c.ty, InstNode.name(component), node);
        end if;

        if Binding.isBound(c.condition) then
          c.condition := typeComponentCondition(c.condition, origin);
          InstNode.updateComponent(c, node);
        end if;

        if typeChildren then
          typeBindings(c.classInst, component, origin);
        end if;
      then
        ();

    // An untyped component with a binding. This might happen when typing a
    // dimension and having to evaluate the binding of a not yet typed
    // component. Type only the binding and let the case above handle the rest.
    case Component.UNTYPED_COMPONENT(binding = Binding.UNTYPED_BINDING(), attributes = attrs)
      algorithm
        name := InstNode.name(component);
        checkBindingEach(c.binding);
        binding := typeBinding(c.binding, ExpOrigin.setFlag(origin, ExpOrigin.BINDING));
        comp_var := checkComponentBindingVariability(name, c, binding, origin);

        if comp_var <> attrs.variability then
          attrs.variability := comp_var;
          c.attributes := attrs;
        end if;

        c.binding := binding;
        InstNode.updateComponent(c, node);
      then
        ();

    case Component.ENUM_LITERAL() then ();
    case Component.TYPE_ATTRIBUTE(modifier = Modifier.NOMOD()) then ();

    case Component.TYPE_ATTRIBUTE()
      algorithm
        c.modifier := typeTypeAttribute(c.modifier, c.ty, InstNode.parent(component), origin);
        InstNode.updateComponent(c, node);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid node " + InstNode.name(node), sourceInfo());
      then
        fail();

  end match;
end typeComponentBinding;

function checkComponentBindingVariability
  input String name;
  input Component component;
  input Binding binding;
  input ExpOrigin.Type origin;
  output Variability var;
protected
  Variability comp_var, comp_eff_var, bind_var, bind_eff_var;
algorithm
  comp_var := Component.variability(component);
  comp_eff_var := Prefixes.effectiveVariability(comp_var);
  bind_var := Binding.variability(binding);
  bind_eff_var := Prefixes.effectiveVariability(bind_var);

  if bind_eff_var > comp_eff_var and ExpOrigin.flagNotSet(origin, ExpOrigin.FUNCTION) then
    Error.addSourceMessage(Error.HIGHER_VARIABILITY_BINDING, {
        name,
        Prefixes.variabilityString(comp_eff_var),
        "'" + Binding.toString(Component.getBinding(component)) + "'",
        Prefixes.variabilityString(bind_eff_var)
      },
      Binding.getInfo(binding));
    fail();
  end if;

  // Mark parameters that have a structural cref as binding as also
  // structural. This is perhaps not optimal, but is required right now
  // to avoid structural singularity and other issues.
  if comp_var == Variability.PARAMETER and
     ((bind_var == Variability.STRUCTURAL_PARAMETER and Binding.isCrefExp(binding)) or
      bind_var == Variability.NON_STRUCTURAL_PARAMETER) then
    var := bind_var;
  else
    var := comp_var;
  end if;
end checkComponentBindingVariability;

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
      NFBinding.EachType each_ty;

    case Binding.UNTYPED_BINDING(bindingExp = exp)
      algorithm
        info := Binding.getInfo(binding);
        (exp, ty, var) := typeExp(exp, origin, info);

        if binding.isEach then
          each_ty := NFBinding.EachType.EACH;
        elseif Binding.isClassBinding(binding) then
          each_ty := NFBinding.EachType.REPEAT;
        else
          each_ty := NFBinding.EachType.NOT_EACH;
        end if;
      then
        Binding.TYPED_BINDING(exp, ty, var, each_ty,
          Mutable.create(NFBinding.EvalState.NOT_EVALUATED), false, binding.info);

    case Binding.TYPED_BINDING() then binding;
    case Binding.UNBOUND() then binding;

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated binding", sourceInfo());
      then
        fail();

  end match;
end typeBinding;

function checkBindingEach
  input Binding binding;
protected
  list<InstNode> parents;
algorithm
  if Binding.isEach(binding) then
    parents := listRest(Binding.parents(binding));

    for parent in parents loop
      if Type.isArray(InstNode.getType(parent)) then
        return;
      end if;
    end for;

    Error.addStrictMessage(Error.EACH_ON_NON_ARRAY,
      {InstNode.name(listHead(parents))}, Binding.getInfo(binding));
  end if;
end checkBindingEach;

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
        (exp, ty, var) := typeExp(exp, ExpOrigin.setFlag(origin, ExpOrigin.CONDITION), info);
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
      then
        Binding.TYPED_BINDING(exp, ty, var, NFBinding.EachType.NOT_EACH,
          Mutable.create(NFBinding.EvalState.NOT_EVALUATED), false, info);

  end match;
end typeComponentCondition;

function typeTypeAttribute
  input output Modifier attribute;
  input Type ty;
  input InstNode component;
  input ExpOrigin.Type origin;
protected
  String name;
  Binding binding;
  InstNode mod_parent;
algorithm
  attribute := match attribute
    // Modifier with submodifier, e.g. Real x(start(y = 1)), is an error.
    case Modifier.MODIFIER()
      guard not ModTable.isEmpty(attribute.subModifiers)
      algorithm
        // Print an error for the first submodifier. The builtin attributes
        // don't have types as such, so for the error message to make sense we
        // join the attribute name and submodifier name together (e.g. start.y).
        name := attribute.name + "." + Util.tuple21(listHead(ModTable.toList(attribute.subModifiers)));
        Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
          {name, Type.toString(ty)}, attribute.info);
      then
        fail();

    // Modifier with no binding, e.g. Real x(final start).
    case Modifier.MODIFIER()
      guard Binding.isUnbound(attribute.binding)
      algorithm
        checkBindingEach(attribute.binding);
      then
        NFModifier.NOMOD();

    // Normal modifier with no submodifiers.
    case Modifier.MODIFIER(name = name, binding = binding)
      algorithm
        // Type and type check the attribute.
        checkBindingEach(binding);

        if Binding.isBound(binding) then
          binding := typeBinding(binding, origin);
          binding := TypeCheck.matchBinding(binding, ty, name, component);

          // Check the variability. All builtin attributes have parameter variability.
          if Binding.variability(binding) > Variability.PARAMETER then
            Error.addSourceMessage(Error.HIGHER_VARIABILITY_BINDING,
              {name, Prefixes.variabilityString(Variability.PARAMETER),
               "'" + Binding.toString(binding) + "'", Prefixes.variabilityString(Binding.variability(binding))},
              Binding.getInfo(binding));
            fail();
          end if;

          attribute.binding := binding;
        end if;
      then
        attribute;

  end match;
end typeTypeAttribute;

function typeExp
  "Types an untyped expression, returning the typed expression itself along with
   its type and variability."
  input output Expression exp;
  input ExpOrigin.Type origin;
  input SourceInfo info;
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
      ExpOrigin.Type next_origin;

    case Expression.INTEGER()      then (exp, Type.INTEGER(), Variability.CONSTANT);
    case Expression.REAL()         then (exp, Type.REAL(),    Variability.CONSTANT);
    case Expression.STRING()       then (exp, Type.STRING(),  Variability.CONSTANT);
    case Expression.BOOLEAN()      then (exp, Type.BOOLEAN(), Variability.CONSTANT);
    case Expression.ENUM_LITERAL() then (exp, exp.ty,         Variability.CONSTANT);
    case Expression.CREF()         then typeCrefExp(exp.cref, origin, info);

    case Expression.TYPENAME()
      algorithm
        if ExpOrigin.flagNotSet(origin, ExpOrigin.VALID_TYPENAME_SCOPE) then
          Error.addSourceMessage(Error.INVALID_TYPENAME_USE,
            {Type.typenameString(Type.arrayElementType(exp.ty))}, info);
          fail();
        end if;
      then
        (exp, exp.ty, Variability.CONSTANT);

    case Expression.ARRAY()  then typeArray(exp.elements, origin, info);
    case Expression.MATRIX() then typeMatrix(exp.elements, origin, info);
    case Expression.RANGE()  then typeRange(exp, origin, info);
    case Expression.TUPLE()  then typeTuple(exp.elements, origin, info);
    case Expression.SIZE()   then typeSize(exp, origin, info);

    case Expression.END()
      algorithm
        // end is replaced in subscripts before we get here, so any end still
        // left should be outside a subscript and thus illegal.
        Error.addSourceMessage(Error.END_ILLEGAL_USE_ERROR, {}, info);
      then
        fail();

    case Expression.BINARY()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp1, next_origin, info);
        (e2, ty2, var2) := typeExp(exp.exp2, next_origin, info);
        (exp, ty) := TypeCheck.checkBinaryOperation(e1, ty1, var1, exp.operator, e2, ty2, var2, info);
      then
        (exp, ty, Prefixes.variabilityMax(var1, var2));

    case Expression.UNARY()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp, next_origin, info);
        (exp, ty) := TypeCheck.checkUnaryOperation(e1, ty1, var1, exp.operator, info);
      then
        (exp, ty, var1);

    case Expression.LBINARY()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp1, next_origin, info);
        (e2, ty2, var2) := typeExp(exp.exp2, next_origin, info);
        (exp, ty) := TypeCheck.checkLogicalBinaryOperation(e1, ty1, var1, exp.operator, e2, ty2, var2, info);
      then
        (exp, ty, Prefixes.variabilityMax(var1, var2));

    case Expression.LUNARY()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp, next_origin, info);
        (exp, ty) := TypeCheck.checkLogicalUnaryOperation(e1, ty1, var1, exp.operator, info);
      then
        (exp, ty, var1);

    case Expression.RELATION()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
        (e1, ty1, var1) := typeExp(exp.exp1, next_origin, info);
        (e2, ty2, var2) := typeExp(exp.exp2, next_origin, info);
        (exp, ty) := TypeCheck.checkRelationOperation(e1, ty1, var1, exp.operator, e2, ty2, var2, origin, info);
        variability := Prefixes.variabilityMax(var1, var2);

        // A relation involving continuous expressions which is not inside
        // noEvent is a discrete expression.
        if ExpOrigin.flagNotSet(origin, ExpOrigin.NOEVENT) and variability == Variability.CONTINUOUS then
          variability := Variability.DISCRETE;
        end if;
      then
        (exp, ty, variability);

    case Expression.IF() then typeIfExpression(exp, origin, info);

    case Expression.CALL()
      algorithm
        (e1, ty, var1) := Call.typeCall(exp, origin, info);

        // If the call has multiple outputs and isn't alone on either side of an
        // equation/algorithm, select the first output.
        if Type.isTuple(ty) and not ExpOrigin.isSingleExpression(origin) then
          ty := Type.firstTupleType(ty);
          e1 := Expression.tupleElement(e1, ty, 1);
        end if;
      then
        (e1, ty, var1);

    case Expression.CAST()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
      then
        typeExp(exp.exp, next_origin, info);

    // Subscripted expressions are assumed to already be typed.
    case Expression.SUBSCRIPTED_EXP()
      then (exp, exp.ty, Expression.variability(exp));

    case Expression.MUTABLE()
      algorithm
        e1 := Mutable.access(exp.exp);
        (e1, ty, variability) := typeExp(e1, origin, info);
        exp.exp := Mutable.create(e1);
      then
        (exp, ty, variability);

    case Expression.PARTIAL_FUNCTION_APPLICATION()
      then Function.typePartialApplication(exp, origin, info);

    case Expression.BINDING_EXP()
      then typeBindingExp(exp, origin, info);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown expression: " + Expression.toString(exp), sourceInfo());
      then
        fail();

  end match;

  // Expressions inside when-clauses and initial sections are discrete.
  if ExpOrigin.flagSet(origin, ExpOrigin.DISCRETE_SCOPE) and variability == Variability.CONTINUOUS then
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

function typeBindingExp
  input Expression exp;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression outExp;
  output Type ty;
  output Variability variability;
protected
  Expression e;
  list<InstNode> parents;
  Boolean is_each;
  Type exp_ty;
  Integer parent_dims;
algorithm
  Expression.BINDING_EXP(e, _, _, parents, is_each) := exp;
  (e, exp_ty, variability) := typeExp(e, origin, info);

  parent_dims := 0;

  if not is_each then
    for p in listRest(parents) loop
      parent_dims := parent_dims + Type.dimensionCount(InstNode.getType(p));
    end for;
  end if;

  if parent_dims == 0 then
    ty := exp_ty;
  else
    // If the binding has too few dimensions we can't unlift it, but TypeCheck.matchBinding
    // can report the error better so we silently ignore it here.
    if Type.dimensionCount(exp_ty) >= parent_dims then
      ty := Type.unliftArrayN(parent_dims, exp_ty);
    end if;
  end if;

  outExp := Expression.BINDING_EXP(e, exp_ty, ty, parents, is_each);
end typeBindingExp;

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
protected
  Type ty;
  Expression e;
algorithm
  ty := Expression.typeOf(exp);

  if Type.isKnown(ty) then
    // If the expression has already been typed, just get the dimension from the type.
    (dim, error) := nthDimensionBoundsChecked(ty, dimIndex);
    typedExp := SOME(exp);
  else
    // Otherwise we try to type as little as possible of the expression to get
    // the dimension we need, to avoid introducing unnecessary cycles.
    e := Expression.getBindingExp(exp);
    (dim, error) := match e
      // An untyped array, use typeArrayDim to get the dimension.
      case Expression.ARRAY(ty = Type.UNKNOWN())
        then typeArrayDim(e, dimIndex);

      // A cref, use typeCrefDim to get the dimension.
      case Expression.CREF()
        then typeCrefDim(e.cref, dimIndex, origin, info);

      // Any other expression, type the whole expression and get the dimension
      // from the type.
      else
        algorithm
          (e, ty, _) := typeExp(e, origin, info);

          if Type.isConditionalArray(ty) then
            e := Ceval.evalExp(e, Ceval.EvalTarget.GENERIC(info));
            Structural.markExp(e);
            ty := Expression.typeOf(e);
          end if;

          typedExp := SOME(e);
        then
          nthDimensionBoundsChecked(ty, dimIndex);

    end match;
  end if;
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
  output TypingError error = TypingError.NO_ERROR();
protected
  list<ComponentRef> crl;
  list<Subscript> subs;
  Integer index, dim_count, dim_total = 0;
  InstNode node;
  Component c;
  Type ty;
algorithm
  // TODO: If the cref has subscripts it becomes trickier to correctly calculate
  //       the dimension. For now we take the easy way out and just type the
  //       whole cref, but doing so might introduce unnecessary cycles.
  if ComponentRef.hasSubscripts(cref) then
    (_, ty) := typeCref(cref, origin, info);
    (dim, error) := nthDimensionBoundsChecked(ty, dimIndex);
    return;
  end if;

  // Loop through the cref in reverse, reducing the index by the number of
  // dimensions each component has until we find a component that the index is
  // valid for. This is done even if the index is 0 or negative, since the loop
  // also sums up the total number of dimensions which is needed to give a good
  // error message.
  crl := ComponentRef.toListReverse(cref);
  index := dimIndex;

  for cr in crl loop
    () := match cr
      case ComponentRef.CREF(node = InstNode.COMPONENT_NODE(), subscripts = subs)
        algorithm
          node := InstNode.resolveOuter(cr.node);
          c := InstNode.component(node);

          // If the component is untyped it might have an array type whose dimensions
          // we need to take into consideration. To avoid making this more complicated
          // than it already is we make sure that the component is typed in that case.
          if Class.hasDimensions(InstNode.getClass(Component.classInstance(c))) then
            typeComponent(node, origin);
            c := InstNode.component(node);
          end if;

          dim_count := match c
            case Component.UNTYPED_COMPONENT()
              algorithm
                dim_count := arrayLength(c.dimensions);

                if index <= dim_count and index > 0 then
                  dim := typeDimension(c.dimensions, index, node, c.binding, origin, c.info);
                  return;
                end if;
              then
                dim_count;

            case Component.TYPED_COMPONENT()
              algorithm
                dim_count := Type.dimensionCount(c.ty);

                if index <= dim_count and index > 0 then
                  dim := Type.nthDimension(c.ty, index);
                  return;
                end if;
              then
                dim_count;

            else 0;
          end match;

          index := index - dim_count;
          dim_total := dim_total + dim_count;
        then
          ();

      else ();
    end match;
  end for;

  dim := Dimension.UNKNOWN();
  error := TypingError.OUT_OF_BOUNDS(dim_total);
end typeCrefDim;

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

function typeCrefExp
  input ComponentRef cref;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression exp;
  output Type ty;
  output Variability variability;
protected
  ComponentRef cr;
  Variability node_var, subs_var;
  Boolean eval;
algorithm
  (cr, ty, node_var, subs_var) := typeCref(cref, origin, info);
  exp := Expression.CREF(ty, cr);
  variability := Prefixes.variabilityMax(node_var, subs_var);
end typeCrefExp;

function typeCref
  input output ComponentRef cref;
  input ExpOrigin.Type origin;
  input SourceInfo info;
        output Type ty;
        output Variability nodeVariability;
        output Variability subsVariability;
protected
  Variability subs_var;
algorithm
  // Check that time isn't used in a function context.
  // TODO: Fix NFBuiltin.TIME_CREF so that the compiler treats it like an actual
  //       constant, then maybe we can use referenceEq here instead.
  if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) and
     ComponentRef.firstName(cref) == "time" then
    Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"time"}, info);
    fail();
  end if;

  (cref, subsVariability) := typeCref2(cref, origin, info);
  ty := ComponentRef.getSubscriptedType(cref);
  nodeVariability := ComponentRef.nodeVariability(cref);
end typeCref;

function typeCref2
  input output ComponentRef cref;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  input Boolean firstPart = true;
        output Variability subsVariability;

  import NFComponentRef.Origin;
algorithm
  (cref, subsVariability) := match cref
    local
      ComponentRef rest_cr;
      Type node_ty;
      list<Subscript> subs;
      Variability subs_var, rest_var;
      ExpOrigin.Type node_origin;
      Function fn;

    case ComponentRef.CREF(origin = Origin.SCOPE)
      algorithm
        cref.ty := InstNode.getType(cref.node);
      then
        (cref, Variability.CONSTANT);

    case ComponentRef.CREF(node = InstNode.COMPONENT_NODE())
      algorithm
        if Component.hasCondition(InstNode.component(cref.node)) and
           (ExpOrigin.flagNotSet(origin, ExpOrigin.CONNECT) or
            ExpOrigin.flagSet(origin, ExpOrigin.SUBSCRIPT)) then
          Error.addStrictMessage(Error.CONDITIONAL_COMPONENT_INVALID_CONTEXT,
            {InstNode.name(cref.node)}, info);
        end if;

        // The origin used when typing a component node depends on where the
        // component was declared, not where it's used. This can be different to
        // the given origin, e.g. for package constants used in a function.
        node_origin := if InstNode.isFunction(InstNode.explicitParent(cref.node)) then
          ExpOrigin.FUNCTION else ExpOrigin.CLASS;
        node_ty := typeComponent(cref.node, node_origin);

        (subs, subs_var) := typeSubscripts(cref.subscripts, node_ty, cref, origin, info);
        (rest_cr, rest_var) := typeCref2(cref.restCref, origin, info, false);
        subsVariability := Prefixes.variabilityMax(subs_var, rest_var);
      then
        (ComponentRef.CREF(cref.node, subs, node_ty, cref.origin, rest_cr), subsVariability);

    case ComponentRef.CREF(node = InstNode.CLASS_NODE())
      guard firstPart and InstNode.isFunction(cref.node)
      algorithm
        fn :: _ := Function.typeNodeCache(cref.node);
        cref.ty := Type.FUNCTION(fn, NFType.FunctionType.FUNCTION_REFERENCE);
        cref.restCref := typeCref2(cref.restCref, origin, info, false);
      then
        (cref, Variability.CONTINUOUS);

    case ComponentRef.CREF(node = InstNode.CLASS_NODE())
      algorithm
        cref.ty := InstNode.getType(cref.node);
      then
        (cref, Variability.CONSTANT);

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
  if listEmpty(subscripts) then
    typedSubs := subscripts;
    return;
  end if;

  dims := Type.arrayDims(crefType);
  typedSubs := {};
  next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBSCRIPT);
  i := 1;

  if listLength(subscripts) > listLength(dims) then
    Error.addSourceMessage(Error.WRONG_NUMBER_OF_SUBSCRIPTS,
      {ComponentRef.toString(cref), String(listLength(subscripts)), String(listLength(dims))}, info);
    fail();
  end if;

  for s in subscripts loop
    dim :: dims := dims;
    (sub, var) := typeSubscript(s, dim, cref, i, next_origin, info);
    typedSubs := sub :: typedSubs;
    variability := Prefixes.variabilityMax(variability, var);
    i := i + 1;

    // Mark parameter subscripts as structural so that they're evaluated.
    // TODO: Ideally this shouldn't be needed, but the old frontend does it and
    //       the backend relies on it.
    if var == Variability.PARAMETER then
      Structural.markSubscript(sub);
    end if;
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
  (ty, variability) := match subscript
    // An untyped subscript, type the expression and create a typed subscript.
    case Subscript.UNTYPED()
      algorithm
        e := evaluateEnd(subscript.exp, dimension, cref, index, origin, info);
        (e, ty, variability) := typeExp(e, origin, info);

        if Type.isArray(ty) then
          outSubscript := Subscript.SLICE(e);
          ty := Type.unliftArray(ty);

          if ExpOrigin.flagSet(origin, ExpOrigin.EQUATION) then
            Structural.markExp(e);
          end if;
        else
          outSubscript := Subscript.INDEX(e);
        end if;
      then
        (ty, variability);

    // Other subscripts have already been typed, but still need to be type checked.
    case Subscript.INDEX(index = e) then (Expression.typeOf(e), Expression.variability(e));
    case Subscript.SLICE(slice = e) then (Type.unliftArray(Expression.typeOf(e)), Expression.variability(e));
    case Subscript.WHOLE() then (Type.UNKNOWN(), Dimension.variability(dimension));
    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown subscript", sourceInfo());
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
  ExpOrigin.Type next_origin;
algorithm
  next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);

  for e in elements loop
    (exp, ty2, var) := typeExp(e, next_origin, info);
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
    if not Config.getGraphicsExpMode() then // forget errors when handling annotations
      if TypeCheck.isIncompatibleMatch(mk) then
        Error.addSourceMessage(Error.NF_ARRAY_TYPE_MISMATCH, {String(n), Expression.toString(exp), Type.toString(ty2), Type.toString(ty1)}, info);
        fail();
      end if;
    end if;
  end for;

  arrayType := Type.liftArrayLeft(ty1, Dimension.fromExpList(expl2));
  arrayExp := Expression.makeArray(arrayType, expl2);
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
  ExpOrigin.Type next_origin = ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
algorithm
  if listLength(elements) > 1 then
    for el in elements loop
      (exp, ty, var) := typeMatrixComma(el, next_origin, info);
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
    (arrayExp, arrayType) := BuiltinCall.makeCatExp(1, res, resTys, variability, info);
  else
    (arrayExp, arrayType, variability) := typeMatrixComma(listHead(elements), next_origin, info);
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
      (exp, ty1, var) := typeExp(e, origin, info);
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
      variability := Prefixes.variabilityMax(variability, var);
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
    (arrayExp, arrayType) := BuiltinCall.makeCatExp(2, res, tys2, variability, info);
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
  ExpOrigin.Type next_origin = ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
algorithm
  Expression.RANGE(start = start_exp, step = ostep_exp, stop = stop_exp) := rangeExp;

  // Type start and stop.
  (start_exp, start_ty, start_var) := typeExp(start_exp, next_origin, info);
  (stop_exp, stop_ty, stop_var) := typeExp(stop_exp, next_origin, info);
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
    (step_exp, step_ty, step_var) := typeExp(step_exp, next_origin, info);
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

  if variability <= Variability.PARAMETER and not ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
    Structural.markExp(rangeExp);
  end if;
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
  ExpOrigin.Type next_origin;
algorithm
  // Tuples are only allowed on the lhs side of an equality/assignment,
  // and only if they are alone and not part of a larger expression.
  if ExpOrigin.flagNotSet(origin, ExpOrigin.LHS) or
     ExpOrigin.flagSet(origin, ExpOrigin.SUBEXPRESSION) then
    Error.addSourceMessage(Error.RHS_TUPLE_EXPRESSION,
      {Expression.toString(Expression.TUPLE(Type.UNKNOWN(), elements))}, info);
    fail();
  end if;

  next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
  (expl, tyl, valr) := typeExpl(elements, next_origin, info);
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
  ExpOrigin.Type next_origin = ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);
algorithm
  (sizeExp, sizeType, variability) := match sizeExp
    case Expression.SIZE(exp = exp, dimIndex = SOME(index))
      algorithm
        (index, index_ty, variability) := typeExp(index, next_origin, info);

        // The second argument must be an Integer.
        (index, _, ty_match) :=
          TypeCheck.matchTypes(index_ty, Type.INTEGER(), index);

        if TypeCheck.isIncompatibleMatch(ty_match) then
          Error.addSourceMessage(Error.ARG_TYPE_MISMATCH,
            {"2", "size ", "dim", Expression.toString(index), Type.toString(index_ty), "Integer"}, info);
          fail();
        end if;

        if variability <= Variability.STRUCTURAL_PARAMETER and
           not Expression.containsIterator(index, origin) then
          // Evaluate the index if it's a constant.
          index := Ceval.evalExp(index, Ceval.EvalTarget.IGNORE_ERRORS());

          // TODO: Print an error if the index couldn't be evaluated to an int.
          Expression.INTEGER(iindex) := index;

          // Get the iindex'd dimension of the expression.
          (dim, oexp, ty_err) := typeExpDim(exp, iindex, next_origin, info);
          checkSizeTypingError(ty_err, exp, iindex, info);

          if Dimension.isKnown(dim) and evaluate then
            // If the dimension size is known, return its size.
            exp := Dimension.sizeExp(dim);
          else
            // If the dimension size is unknown (e.g. in a function) or
            // evaluation is disabled, return a size expression instead.
            if isSome(oexp) then
              SOME(exp) := oexp;
            else
              exp := typeExp(exp, next_origin, info);
            end if;

            exp := Expression.SIZE(exp, SOME(index));
          end if;

          if ExpOrigin.flagNotSet(origin, ExpOrigin.FUNCTION) or Dimension.isKnown(dim) then
            // size is constant outside functions, or for known dimensions inside functions.
            variability := Variability.CONSTANT;
          else
            // size is discrete for : in functions.
            variability := Variability.DISCRETE;
          end if;
        else
          // If the index is not a constant, type the whole expression.
          (exp, exp_ty) := typeExp(sizeExp.exp, next_origin, info);

          // Check that it's an array.
          if not Type.isArray(exp_ty) then
            Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {"size"}, info);
            fail();
          end if;

          // Since we don't know which dimension to take the size of, return a size expression.
          exp := Expression.SIZE(exp, SOME(index));
        end if;
      then
        (exp, Type.INTEGER(), variability);

    case Expression.SIZE()
      algorithm
        (exp, exp_ty, _) := typeExp(sizeExp.exp, next_origin, info);
        sizeType := Type.sizeType(exp_ty);
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

    case Expression.END() then Dimension.endExp(dim, cref, index);

    // Stop when encountering a cref, any 'end' in a cref expression refers to
    // the cref's dimensions and will be evaluated when the cref is typed.
    case Expression.CREF() then exp;

    else Expression.mapShallow(exp,
      function evaluateEnd(dim = dim, cref = cref, index = index, info = info, origin = origin));

  end match;
end evaluateEnd;

function typeIfExpression
  input output Expression ifExp;
  input ExpOrigin.Type origin;
  input SourceInfo info;
        output Type ty;
        output Variability var;
protected
  Expression cond, tb, fb, tb2, fb2;
  ExpOrigin.Type next_origin;
  Type cond_ty, tb_ty, fb_ty;
  Variability cond_var, tb_var, fb_var;
  MatchKind ty_match;
algorithm
  Expression.IF(condition = cond, trueBranch = tb, falseBranch = fb) := ifExp;
  next_origin := ExpOrigin.setFlag(origin, ExpOrigin.SUBEXPRESSION);

  (cond, cond_ty, cond_var) := typeExp(cond, next_origin, info);

  // The condition must be a scalar boolean.
  (cond, _, ty_match) := TypeCheck.matchTypes(cond_ty, Type.BOOLEAN(), cond);

  if TypeCheck.isIncompatibleMatch(ty_match) then
    Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR,
      {Expression.toString(cond), Type.toString(cond_ty)}, info);
    fail();
  end if;

  (tb, tb_ty, tb_var) := typeExp(tb, next_origin, info);
  (fb, fb_ty, fb_var) := typeExp(fb, next_origin, info);
  (tb2, fb2, ty, ty_match) := TypeCheck.matchIfBranches(tb, tb_ty, fb, fb_ty);

  if TypeCheck.isIncompatibleMatch(ty_match) then
    Error.addSourceMessage(Error.TYPE_MISMATCH_IF_EXP,
      {"", Expression.toString(tb), Type.toString(tb_ty),
           Expression.toString(fb), Type.toString(fb_ty)}, info);
    fail();
  end if;

  ifExp := Expression.IF(ty, cond, tb2, fb2);
  var := Prefixes.variabilityMax(cond_var, Prefixes.variabilityMax(tb_var, fb_var));
end typeIfExpression;

function evaluateCondition
  input Expression condExp;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Boolean condBool;
protected
  Expression cond_exp;
algorithm
  cond_exp := Ceval.evalExp(condExp, Ceval.EvalTarget.GENERIC(info));

  if Expression.arrayAllEqual(cond_exp) then
    cond_exp := Expression.arrayFirstScalar(cond_exp);
  end if;

  condBool := match cond_exp
    case Expression.BOOLEAN() then cond_exp.value;
    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed to evaluate condition `" +
          Expression.toString(condExp) + "`", info);
      then
        fail();
  end match;
end evaluateCondition;

function typeClassSections
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
    case Class.INSTANCED_CLASS(restriction = Restriction.TYPE()) then ();

    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = components),
        sections = sections)
      algorithm
        sections := match sections
          case Sections.SECTIONS()
            algorithm
              initial_origin := ExpOrigin.setFlag(origin, ExpOrigin.INITIAL);
            then
              Sections.map(sections,
                function typeEquation(origin = ExpOrigin.setFlag(origin, ExpOrigin.EQUATION)),
                function typeAlgorithm(origin = ExpOrigin.setFlag(origin, ExpOrigin.ALGORITHM)),
                function typeEquation(origin = ExpOrigin.setFlag(initial_origin, ExpOrigin.EQUATION)),
                function typeAlgorithm(origin = ExpOrigin.setFlag(initial_origin, ExpOrigin.ALGORITHM)));

          case Sections.EXTERNAL()
            algorithm
              Error.addSourceMessage(Error.TRANS_VIOLATION,
                {InstNode.name(classNode), Restriction.toString(cls.restriction), "external declaration"},
                InstNode.info(classNode));
            then
              fail();

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

    case Class.TYPED_DERIVED()
      algorithm
        typeClassSections(cls.baseClass, origin);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated class " + InstNode.name(classNode), sourceInfo());
      then
        fail();
  end match;
end typeClassSections;

function typeFunctionSections
  input InstNode classNode;
  input ExpOrigin.Type origin;
protected
  Class cls, typed_cls;
  Sections sections;
  SourceInfo info;
  Algorithm alg;
algorithm
  cls := InstNode.getClass(classNode);

  _ := match cls
    case Class.INSTANCED_CLASS(sections = sections)
      algorithm
        sections := match sections
          case Sections.SECTIONS({}, {}, {alg}, {})
            algorithm
              sections.algorithms := {typeAlgorithm(alg, ExpOrigin.setFlag(origin, ExpOrigin.ALGORITHM))};
            then
              sections;

          case Sections.SECTIONS()
            algorithm
              if listLength(sections.equations) > 0 or listLength(sections.initialEquations) > 0 then
                Error.addSourceMessage(Error.EQUATION_TRANSITION_FAILURE,
                  {"function"}, InstNode.info(classNode));
              else
                Error.addSourceMessage(Error.MULTIPLE_SECTIONS_IN_FUNCTION,
                  {InstNode.name(classNode)}, InstNode.info(classNode));
              end if;
            then
              fail();

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
        InstNode.updateClass(typed_cls, classNode);
      then
        ();

    case Class.TYPED_DERIVED()
      algorithm
        typeFunctionSections(cls.baseClass, origin);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got uninstantiated class " + InstNode.name(classNode), sourceInfo());
      then
        fail();
  end match;
end typeFunctionSections;

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
  comp := InstNode.component(component);

  () := match comp
    case Component.TYPED_COMPONENT()
      algorithm
        typeClassSections(comp.classInst, origin);
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
      list<Equation.Branch> tybrs;
      InstNode iterator;
      MatchKind mk;
      Variability var, bvar;
      Integer next_origin;
      SourceInfo info;

    case Equation.EQUALITY() then typeEqualityEquation(eq.lhs, eq.rhs, origin, eq.source);
    case Equation.CONNECT()  then typeConnect(eq.lhs, eq.rhs, origin, eq.source);

    case Equation.FOR()
      algorithm
        info := ElementSource.getInfo(eq.source);

        if isSome(eq.range) then
          SOME(e1) := eq.range;
          e1 := typeIterator(eq.iterator, e1, origin, structural = true);
        else
          Error.assertion(false, getInstanceName() + ": missing support for implicit iteration range", sourceInfo());
          fail();
        end if;

        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.FOR);
        body := list(typeEquation(e, next_origin) for e in eq.body);
      then
        Equation.FOR(eq.iterator, SOME(e1), body, eq.source);

    case Equation.IF() then typeIfEquation(eq.branches, origin, eq.source);
    case Equation.WHEN() then typeWhenEquation(eq.branches, origin, eq.source);

    case Equation.ASSERT()
      algorithm
        info := ElementSource.getInfo(eq.source);
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.ASSERT);
        e1 := typeOperatorArg(eq.condition, Type.BOOLEAN(),
          ExpOrigin.setFlag(next_origin, ExpOrigin.CONDITION), "assert", "condition", 1, info);
        e2 := typeOperatorArg(eq.message, Type.STRING(), next_origin, "assert", "message", 2, info);
        e3 := typeOperatorArg(eq.level, NFBuiltin.ASSERTIONLEVEL_TYPE, next_origin, "assert", "level", 3, info);
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
  list<Equation> eql;
algorithm
  info := ElementSource.getInfo(source);

  // Connections may not be used in if-equations unless the conditions are
  // parameter expressions.
  // TODO: Also check for cardinality etc. as per 8.3.3.
  if ExpOrigin.flagSet(origin, ExpOrigin.NONEXPANDABLE) then
    Error.addSourceMessage(Error.CONNECT_IN_IF,
      {Expression.toString(lhsConn), Expression.toString(rhsConn)}, info);
    fail();
  end if;

  next_origin := ExpOrigin.setFlag(origin, ExpOrigin.CONNECT);
  (lhs, lhs_ty) := typeConnector(lhsConn, next_origin, info);
  (rhs, rhs_ty) := typeConnector(rhsConn, next_origin, info);

  // Check that the connectors have matching types, but only if they're not expandable.
  // Expandable connectors can only be type checked after they've been augmented during
  // the connection handling.
  if not (Type.isExpandableConnector(lhs_ty) or Type.isExpandableConnector(rhs_ty)) then
    (lhs, rhs, _, mk) := TypeCheck.matchExpressions(lhs, lhs_ty, rhs, rhs_ty, allowUnknown = true);

    if TypeCheck.isIncompatibleMatch(mk) then
      // TODO: Better error message.
      Error.addSourceMessage(Error.INVALID_CONNECTOR_VARIABLE,
        {Expression.toString(lhsConn), Expression.toString(rhsConn)}, info);
      fail();
    end if;
  end if;

  connEq := Equation.CONNECT(lhs, rhs, source);
end typeConnect;

function typeConnector
  input output Expression connExp;
  input ExpOrigin.Type origin;
  input SourceInfo info;
        output Type ty;
algorithm
  (connExp, ty, _) := typeExp(connExp, origin, info);
  checkConnector(connExp, info);
end typeConnector;

function checkConnector
  input Expression connExp;
  input SourceInfo info;
protected
  ComponentRef cr;
  list<Subscript> subs;
algorithm
  () := match connExp
    case Expression.CREF(cref = cr as ComponentRef.CREF(origin = Origin.CREF))
      algorithm
        if not InstNode.isConnector(cr.node) then
          Error.addSourceMessageAndFail(Error.INVALID_CONNECTOR_TYPE,
            {ComponentRef.toString(cr)}, info);
        end if;

        if not checkConnectorForm(cr) then
          Error.addSourceMessageAndFail(Error.INVALID_CONNECTOR_FORM,
            {ComponentRef.toString(cr)}, info);
        end if;

        if ComponentRef.subscriptsVariability(cr) > Variability.PARAMETER then
          subs := ComponentRef.subscriptsAllFlat(cr);
          for sub in subs loop
            if Subscript.variability(sub) > Variability.PARAMETER then
              Error.addSourceMessage(Error.CONNECTOR_NON_PARAMETER_SUBSCRIPT,
                {Expression.toString(connExp), Subscript.toString(sub)}, info);
              fail();
            end if;
          end for;
        end if;
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
  input Boolean isConnector = true;
  output Boolean valid;
algorithm
  valid := match cref
    // The only part of the connector reference allowed to not be a
    // non-connector is the very last part.
    case ComponentRef.CREF(origin = Origin.CREF)
      then if isConnector then
        checkConnectorForm(cref.restCref, InstNode.isConnector(cref.node)) else false;

    else true;
  end match;
end checkConnectorForm;

function checkLhsInWhen
  input Expression exp;
  output Boolean isValid;
algorithm
  isValid := match exp
    case Expression.CREF() then true;
    case Expression.TUPLE()
      algorithm
        for e in exp.elements loop
          checkLhsInWhen(e);
        end for;
      then
        true;
    else false;
  end match;
end checkLhsInWhen;

function typeAlgorithm
  input output Algorithm alg;
  input ExpOrigin.Type origin;
algorithm
  alg.statements := list(typeStatement(s, origin) for s in alg.statements);
end typeAlgorithm;

function typeStatements
  input output list<Statement> alg;
  input ExpOrigin.Type origin;
algorithm
  alg := list(typeStatement(stmt, origin) for stmt in alg);
end typeStatements;

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
      ExpOrigin.Type next_origin, cond_origin;
      SourceInfo info;

    case Statement.ASSIGNMENT()
      algorithm
        info := ElementSource.getInfo(st.source);
        (e1, ty1) := typeExp(st.lhs, ExpOrigin.setFlag(origin, ExpOrigin.LHS), info);
        (e2, ty2) := typeExp(st.rhs, ExpOrigin.setFlag(origin, ExpOrigin.RHS), info);

        // TODO: Should probably only be allowUnknown = true if in a function.
        (e2, ty3, mk) := TypeCheck.matchTypes(ty2, ty1, e2, allowUnknown = true);

        if TypeCheck.isIncompatibleMatch(mk) then
          Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR,
            {Expression.toString(e1), Expression.toString(e2),
             Type.toString(ty1), Type.toString(ty2)}, info);
          fail();
        end if;
      then
        Statement.ASSIGNMENT(e1, e2, ty3, st.source);

    case Statement.FOR()
      algorithm
        info := ElementSource.getInfo(st.source);

        if isSome(st.range) then
          SOME(e1) := st.range;
          e1 := typeIterator(st.iterator, e1, origin, structural = false);
        else
          Error.assertion(false, getInstanceName() + ": missing support for implicit iteration range", sourceInfo());
          fail();
        end if;

        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.FOR);
        body := typeStatements(st.body, next_origin);
      then
        Statement.FOR(st.iterator, SOME(e1), body, st.source);

    case Statement.IF()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.IF);
        cond_origin := ExpOrigin.setFlag(next_origin, ExpOrigin.CONDITION);

        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, cond_origin, st.source, Error.IF_CONDITION_TYPE_ERROR);
              sts1 := list(typeStatement(bst, next_origin) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.IF(tybrs, st.source);

    case Statement.WHEN()
      algorithm
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.WHEN);

        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeCondition(cond, origin, st.source, Error.WHEN_CONDITION_TYPE_ERROR, allowVector = true);
              sts1 := list(typeStatement(bst, next_origin) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.WHEN(tybrs, st.source);

    case Statement.ASSERT()
      algorithm
        info := ElementSource.getInfo(st.source);
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.ASSERT);
        e1 := typeOperatorArg(st.condition, Type.BOOLEAN(),
          ExpOrigin.setFlag(next_origin, ExpOrigin.CONDITION), "assert", "condition", 1, info);
        e2 := typeOperatorArg(st.message, Type.STRING(), next_origin, "assert", "message", 2, info);
        e3 := typeOperatorArg(st.level, NFBuiltin.ASSERTIONLEVEL_TYPE, next_origin, "assert", "level", 3, info);
      then
        Statement.ASSERT(e1, e2, e3, st.source);

    case Statement.TERMINATE()
      algorithm
        info := ElementSource.getInfo(st.source);

        // terminate is not allowed in a function context.
        if ExpOrigin.flagSet(origin, ExpOrigin.FUNCTION) then
          Error.addSourceMessage(Error.EXP_INVALID_IN_FUNCTION, {"terminate"}, info);
          fail();
        end if;

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

function typeEqualityEquation
  input Expression lhsExp;
  input Expression rhsExp;
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
  output Equation eq;
protected
  SourceInfo info = ElementSource.getInfo(source);
  Expression e1, e2;
  Type ty1, ty2, ty;
  MatchKind mk;
algorithm
  if ExpOrigin.flagSet(origin, ExpOrigin.WHEN) and
     ExpOrigin.flagNotSet(origin, ExpOrigin.CLOCKED) then
    if checkLhsInWhen(lhsExp) then
      Structural.markSubscriptsInExp(lhsExp);
    else
      Error.addSourceMessage(Error.WHEN_EQ_LHS, {Expression.toString(lhsExp)}, info);
      fail();
    end if;
  end if;

  (e1, ty1) := typeExp(lhsExp, ExpOrigin.setFlag(origin, ExpOrigin.LHS), info);
  (e2, ty2) := typeExp(rhsExp, ExpOrigin.setFlag(origin, ExpOrigin.RHS), info);
  (e1, e2, ty, mk) := TypeCheck.matchExpressions(e1, ty1, e2, ty2);

  if TypeCheck.isIncompatibleMatch(mk) then
    Error.addSourceMessage(Error.EQUATION_TYPE_MISMATCH_ERROR,
      {Expression.toString(e1) + " = " + Expression.toString(e2),
       Type.toString(ty1) + " = " + Type.toString(ty2)}, info);
    fail();
  end if;

  eq := Equation.EQUALITY(e1, e2, ty, source);
end typeEqualityEquation;

function typeCondition
  input output Expression condition;
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
  input ErrorTypes.Message errorMsg;
  input Boolean allowVector = false;
  input Boolean allowClock = false;
        output Type ty;
        output Variability variability;
protected
  SourceInfo info;
  Type ety;
algorithm
  info := ElementSource.getInfo(source);
  (condition, ty, variability) := typeExp(condition, origin, info);

  ety := if allowVector then Type.arrayElementType(ty) else ty;

  if not (Type.isBoolean(ety) or (allowClock and Type.isClock(ety))) then
    Error.addSourceMessage(errorMsg,
      {Expression.toString(condition), Type.toString(ty)}, info);
    fail();
  end if;
end typeCondition;

function typeIfEquation
  input list<Equation.Branch> branches;
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
  output Equation ifEq;
protected
  Expression cond;
  list<Equation> eql;
  Variability accum_var = Variability.CONSTANT, var;
  list<Equation.Branch> bl = {}, bl2 = {};
  ExpOrigin.Type next_origin = ExpOrigin.setFlag(origin, ExpOrigin.IF);
  ExpOrigin.Type cond_origin = ExpOrigin.setFlag(next_origin, ExpOrigin.CONDITION);
algorithm
  // Type the conditions of all the branches.
  for b in branches loop
    Equation.Branch.BRANCH(cond, _, eql) := b;
    (cond, _, var) := typeCondition(cond, cond_origin, source, Error.IF_CONDITION_TYPE_ERROR);

    if var > Variability.PARAMETER or Structural.isExpressionNotFixed(cond, maxDepth = 100) then
      // If the condition doesn't fulfill the requirements for allowing
      // connections in the branch, mark the origin so we can check that when
      // typing the body of the branch.
      next_origin := ExpOrigin.setFlag(next_origin, ExpOrigin.NONEXPANDABLE);
    elseif var == Variability.PARAMETER and accum_var <= Variability.PARAMETER then
      // If all conditions up to and including this one are parameter
      // expressions, consider the condition to be structural.
      var := Variability.STRUCTURAL_PARAMETER;
      Structural.markExp(cond);
    end if;

    accum_var := Prefixes.variabilityMax(accum_var, var);
    bl := Equation.Branch.BRANCH(cond, var, eql) :: bl;
  end for;

  // Type the bodies of all the branches.
  for b in bl loop
    Equation.Branch.BRANCH(cond, var, eql) := b;

    ErrorExt.setCheckpoint(getInstanceName());
    try
      eql := list(typeEquation(e, next_origin) for e in eql);
      bl2 := Equation.makeBranch(cond, eql, var) :: bl2;
    else
      bl2 := Equation.INVALID_BRANCH(Equation.makeBranch(cond, eql, var),
                                     ErrorExt.getCheckpointMessages()) :: bl2;
    end try;
    ErrorExt.delCheckpoint(getInstanceName());
  end for;

  // Do branch selection anyway if -d=-nfScalarize is set, otherwise turning of
  // scalarization breaks currently.
  if not Flags.isSet(Flags.NF_SCALARIZE) then
    bl := bl2;
    bl2 := {};

    for b in bl loop
      bl2 := match b
        case Equation.Branch.BRANCH()
          guard b.conditionVar <= Variability.STRUCTURAL_PARAMETER
          algorithm
            b.condition := Ceval.evalExp(b.condition);
          then
            if Expression.isFalse(b.condition) then bl2 else b :: bl2;

        else b :: bl2;
      end match;
    end for;

    bl2 := listReverseInPlace(bl2);
  end if;

  ifEq := Equation.IF(bl2, source);
end typeIfEquation;

function isNonConstantIfCondition
  input Expression exp;
  output Boolean isConstant;
algorithm
  isConstant := match exp
    local
      Function fn;

    case Expression.CREF() then ComponentRef.isIterator(exp.cref);
    case Expression.CALL(call = Call.TYPED_CALL(fn = fn))
      then match AbsynUtil.pathFirstIdent(fn.path)
        case "Connections" then true;
        case "cardinality" then true;
        else Call.isImpure(exp.call);
      end match;
    else false;
  end match;
end isNonConstantIfCondition;

function typeWhenEquation
  input list<Equation.Branch> branches;
  input ExpOrigin.Type origin;
  input DAE.ElementSource source;
  output Equation whenEq;
protected
  ExpOrigin.Type next_origin = ExpOrigin.setFlag(origin, ExpOrigin.WHEN);
  list<Equation.Branch> accum_branches = {};
  Expression cond;
  list<Equation> body;
  Type ty;
  Variability var;
algorithm
  for branch in branches loop
    Equation.Branch.BRANCH(cond, _, body) := branch;
    (cond, ty, var) := typeCondition(cond, origin, source,
      Error.WHEN_CONDITION_TYPE_ERROR, allowVector = true, allowClock = true);

    if Type.isClock(ty) then
      if listLength(branches) <> 1 then
        if referenceEq(branch, listHead(branches)) then
          Error.addSourceMessage(Error.ELSE_WHEN_CLOCK, {}, ElementSource.getInfo(source));
        else
          Error.addSourceMessage(Error.CLOCKED_WHEN_BRANCH, {}, ElementSource.getInfo(source));
        end if;

        fail();
      else
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.CLOCKED);
      end if;
    end if;

    body := list(typeEquation(eq, next_origin) for eq in body);
    accum_branches := Equation.makeBranch(cond, body, var) :: accum_branches;
  end for;

  whenEq := Equation.WHEN(listReverseInPlace(accum_branches), source);
end typeWhenEquation;

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
  (crefExp, ty1, _) := typeExp(crefExp, origin, info);
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
  // typeExp, since expressions in when-equations count as discrete.
  if ComponentRef.nodeVariability(cref) < Variability.IMPLICITLY_DISCRETE then
    Error.addSourceMessage(Error.REINIT_MUST_BE_VAR,
      {Expression.toString(crefExp),
       Prefixes.variabilityString(ComponentRef.nodeVariability(cref))}, info);
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
