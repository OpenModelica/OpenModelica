/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFFlatten
" file:        NFFlatten.mo
  package:     NFFlatten
  description: Flattening


  New instantiation, enable with -d=newInst.
"

import Binding = NFBinding;
import Equation = NFEquation;
import NFFunction.Function;
import NFInstNode.InstNode;
import Statement = NFStatement;
import FlatModel = NFFlatModel;
import Algorithm = NFAlgorithm;
import CardinalityTable = NFCardinalityTable;

protected
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import ExecStat.execStat;
import ExpressionIterator = NFExpressionIterator;
import Expression = NFExpression;
import Flags;
import List;
import Call = NFCall;
import Class = NFClass;
import NFClassTree.ClassTree;
import Component = NFComponent;
import NFModifier.Modifier;
import Sections = NFSections;
import NFOCConnectionGraph;
import Prefixes = NFPrefixes;
import RangeIterator = NFRangeIterator;
import Subscript = NFSubscript;
import Type = NFType;
import Util;
import MetaModelica.Dangerous.listReverseInPlace;
import ConnectionSets = NFConnectionSets.ConnectionSets;
import Connection = NFConnection;
import Connector = NFConnector;
import ConnectEquations = NFConnectEquations;
import Connections = NFConnections;
import Face = NFConnector.Face;
import System;
import ComplexType = NFComplexType;
import NFInstNode.CachedData;
import NFPrefixes.{Direction, Variability, Visibility, Purity, Parallelism};
import Variable = NFVariable;
import ElementSource;
import Ceval = NFCeval;
import SimplifyExp = NFSimplifyExp;
import Restriction = NFRestriction;
import EvalConstants = NFEvalConstants;
import SimplifyModel = NFSimplifyModel;
import InstNodeType = NFInstNode.InstNodeType;
import ExpandableConnectors = NFExpandableConnectors;
import SCodeUtil;
import DAE;
import Structural = NFStructural;
import ArrayConnections = NFArrayConnections;
import UnorderedMap;
import UnorderedSet;
import Inline = NFInline;
import ExpandExp = NFExpandExp;
import InstUtil = NFInstUtil;

public
type FunctionTree = FunctionTreeImpl.Tree;

encapsulated package FunctionTreeImpl
  import Absyn.Path;
  import NFFunction.Function;
  import BaseAvlTree;

  extends BaseAvlTree;
  redeclare type Key = Absyn.Path;
  redeclare type Value = Function;

  redeclare function extends keyStr
  algorithm
    outString := AbsynUtil.pathString(inKey);
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := "";
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := AbsynUtil.pathCompareNoQual(inKey1, inKey2);
  end keyCompare;

  redeclare function addConflictDefault = addConflictKeep;
end FunctionTreeImpl;

uniontype FlattenSettings
  record SETTINGS
    Boolean scalarize;
    Boolean arrayConnect;
    Boolean nfAPI;
    Boolean newBackend;
  end SETTINGS;
end FlattenSettings;

constant ComponentRef EMPTY_PREFIX = ComponentRef.EMPTY();

function flatten
  input InstNode classInst;
  input String name;
  output FlatModel flatModel;
protected
  Sections sections;
  list<Variable> vars;
  list<Equation> eql, ieql;
  list<Algorithm> alg, ialg;
  DAE.ElementSource src;
  Option<SCode.Comment> cmt;
  FlattenSettings settings;
  UnorderedSet<ComponentRef> deleted_vars;
algorithm
  settings := FlattenSettings.SETTINGS(
    Flags.isSet(Flags.NF_SCALARIZE),
    Flags.isSet(Flags.ARRAY_CONNECT),
    Flags.isSet(Flags.NF_API),
    Flags.getConfigBool(Flags.NEW_BACKEND)
  );

  sections := Sections.EMPTY();
  src := ElementSource.createElementSource(InstNode.info(classInst));
  src := ElementSource.addCommentToSource(src,
    SCodeUtil.getElementComment(InstNode.definition(classInst)));

  deleted_vars := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);

  (vars, sections) := flattenClass(InstNode.getClass(classInst), EMPTY_PREFIX,
    Visibility.PUBLIC, NONE(), {}, sections, deleted_vars, settings);
  vars := listReverseInPlace(vars);

  flatModel := match sections
    case Sections.SECTIONS()
      algorithm
        eql := listReverseInPlace(sections.equations);
        ieql := listReverseInPlace(sections.initialEquations);
        alg := listReverseInPlace(sections.algorithms);
        ialg := listReverseInPlace(sections.initialAlgorithms);
      then
        FlatModel.FLAT_MODEL(name, vars, eql, ieql, alg, ialg, src);

      else FlatModel.FLAT_MODEL(name, vars, {}, {}, {}, {}, src);
  end match;

  execStat(getInstanceName());
  InstUtil.dumpFlatModelDebug("flatten", flatModel);

  if settings.arrayConnect then
    flatModel := resolveArrayConnections(flatModel);
  else
    flatModel := resolveConnections(flatModel, deleted_vars);
  end if;
  InstUtil.dumpFlatModelDebug("connections", flatModel);
end flatten;

function collectFunctions
  input FlatModel flatModel;
  output FunctionTree funcs;
algorithm
  funcs := FunctionTree.new();
  funcs := List.fold(flatModel.variables, collectComponentFuncs, funcs);
  funcs := List.fold(flatModel.equations, collectEquationFuncs, funcs);
  funcs := List.fold(flatModel.initialEquations, collectEquationFuncs, funcs);
  funcs := List.fold(flatModel.algorithms, collectAlgorithmFuncs, funcs);
  funcs := List.fold(flatModel.initialAlgorithms, collectAlgorithmFuncs, funcs);
  execStat(getInstanceName());
end collectFunctions;

function vectorizeVariableBinding
  input output Variable var;
protected
  list<tuple<String, Binding>> ty_attrs = {};
  String attr_name;
  Binding attr_binding;
algorithm
  var.binding := vectorizeBinding(var.binding, var.ty);

  for ty_attr in var.typeAttributes loop
    (attr_name, attr_binding) := ty_attr;
    attr_binding := vectorizeBinding(attr_binding,
      Type.copyDims(var.ty, Binding.getType(attr_binding)));
    ty_attrs := (attr_name, attr_binding) :: ty_attrs;
  end for;

  var.typeAttributes := listReverseInPlace(ty_attrs);
end vectorizeVariableBinding;

protected
function flattenClass
  input Class cls;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
  input output Sections sections;
  input UnorderedSet<ComponentRef> deletedVars;
  input FlattenSettings settings;
protected
  array<InstNode> comps;
  list<Binding> bindings = {};
  Binding b;
algorithm
  () := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      algorithm
        if isSome(binding) then
          SOME(b) := binding;

          if Binding.isBound(b) then
            b := flattenBinding(b, ComponentRef.rest(prefix));
            bindings := getRecordBindings(b, comps, prefix);
          end if;
        end if;

        if listEmpty(bindings) then
          for c in comps loop
            (vars, sections) := flattenComponent(c, prefix, visibility, binding, vars, sections, deletedVars, settings);
          end for;
        else
          for c in comps loop
            b :: bindings := bindings;
            (vars, sections) := flattenComponent(c, prefix, visibility, SOME(b), vars, sections, deletedVars, settings);
          end for;
        end if;

        sections := flattenSections(cls.sections, prefix, sections, settings);
      then
        ();

    case Class.TYPED_DERIVED()
      algorithm
        (vars, sections) :=
          flattenClass(InstNode.getClass(cls.baseClass), prefix, visibility, binding, vars, sections, deletedVars, settings);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-instantiated component " + ComponentRef.toString(prefix) + "\n", sourceInfo());
      then
        ();

  end match;
end flattenClass;

function flattenComponent
  input InstNode component;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input output list<Variable> vars;
  input output Sections sections;
  input UnorderedSet<ComponentRef> deletedVars;
  input FlattenSettings settings;
protected
  InstNode comp_node;
  Component c;
  Type ty;
  Binding condition;
  Class cls;
  Visibility vis;
  list<Variable> children;
algorithm
  // Remove components that are only outer.
  if InstNode.isOnlyOuter(component) then
    return;
  end if;

  comp_node := InstNode.resolveOuter(component);
  c := InstNode.component(comp_node);

  () := match c
    case Component.TYPED_COMPONENT(condition = condition, ty = ty)
      algorithm
        // Delete the component if it has a condition that's false.
        if isDeletedComponent(condition, prefix) then
          deleteComponent(component, prefix, deletedVars);
          return;
        end if;

        cls := InstNode.getClass(c.classInst);
        vis := if InstNode.isProtected(component) then Visibility.PROTECTED else visibility;

        (vars, sections) := match getComponentType(ty, settings)
          case ComponentType.COMPLEX
          then flattenComplexComponent(comp_node, c, cls, ty,
            vis, outerBinding, prefix, vars, sections, deletedVars, settings);

          case ComponentType.NORMAL
          then flattenSimpleComponent(comp_node, c, vis, outerBinding,
            Class.getTypeAttributes(cls), prefix, vars, sections, settings, {});

          case ComponentType.RECORD algorithm
            (children, sections) := flattenComplexComponent(comp_node, c, cls, ty,
              vis, outerBinding, prefix, {}, sections, deletedVars, settings);
          then flattenSimpleComponent(comp_node, c, vis, outerBinding,
            Class.getTypeAttributes(cls), prefix, vars, sections, settings, children);

          else algorithm
            Error.assertion(false, getInstanceName() + " got unknown component", sourceInfo());
          then fail();
        end match;
      then
        ();

    // A component that was already deleted during e.g. typing.
    case _ guard Component.isDeleted(c)
      algorithm
        deleteComponent(component, prefix, deletedVars);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown component", sourceInfo());
      then
        fail();

  end match;
end flattenComponent;

function isDeletedComponent
  input Binding condition;
  input ComponentRef prefix;
  output Boolean isDeleted;
protected
  Expression exp;
  Binding cond;
algorithm
  if Binding.isBound(condition) then
    cond := flattenBinding(condition, prefix);
    exp := Binding.getTypedExp(cond);
    exp := Ceval.evalExp(exp, Ceval.EvalTarget.CONDITION(Binding.getInfo(cond)));
    exp := Expression.expandSplitIndices(exp);

    // Hack to make arrays work when all elements have the same value.
    if Expression.arrayAllEqual(exp) then
      exp := Expression.arrayFirstScalar(exp);
    end if;

    isDeleted := match exp
      case Expression.BOOLEAN() then not exp.value;
      else
        algorithm
          Error.addSourceMessage(Error.CONDITIONAL_EXP_WITHOUT_VALUE,
            {Expression.toString(exp)}, Binding.getInfo(cond));
        then
          fail();
    end match;
  else
    isDeleted := false;
  end if;
end isDeletedComponent;

function deleteComponent
  input InstNode node;
  input ComponentRef prefix;
  input UnorderedSet<ComponentRef> deletedVars;
protected
  ComponentRef cref;
algorithm
  cref := ComponentRef.prefixCref(node, Type.UNKNOWN(), {}, prefix);
  UnorderedSet.add(cref, deletedVars);
end deleteComponent;

function getComponentType
  input Type ty;
  input FlattenSettings settings;
  output ComponentType compTy;
algorithm
  compTy := match ty
    case Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT())
      then ComponentType.NORMAL;
    case Type.COMPLEX(complexTy = ComplexType.RECORD()) guard(settings.newBackend)
      then ComponentType.RECORD;
    case Type.COMPLEX() then ComponentType.COMPLEX;
    case Type.ARRAY()   then getComponentType(ty.elementType, settings);
                        else ComponentType.NORMAL;
  end match;
end getComponentType;

type ComponentType = enumeration(NORMAL, COMPLEX, RECORD);

function flattenSimpleComponent
  input InstNode node;
  input Component comp;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input list<Modifier> typeAttrs;
  input ComponentRef prefix;
  input output list<Variable> vars;
  input output Sections sections;
  input FlattenSettings settings;
  input list<Variable> children;
protected
  InstNode comp_node = node;
  ComponentRef name;
  Binding binding;
  Type ty;
  Option<SCode.Comment> cmt;
  SourceInfo info;
  Component.Attributes comp_attr;
  Visibility vis;
  Equation eq;
  list<tuple<String, Binding>> ty_attrs;
  Variability var;
  Boolean unfix;
algorithm
  Component.TYPED_COMPONENT(ty = ty, binding = binding, attributes = comp_attr,
    comment = cmt, info = info) := comp;
  var := comp_attr.variability;

  if isSome(outerBinding) then
    SOME(binding) := outerBinding;
    unfix := Binding.isUnbound(binding) and var == Variability.PARAMETER;
  else
    binding := flattenBinding(binding, prefix);
    unfix := false;
  end if;

  // If the component is an array component with a binding and at least discrete variability,
  // move the binding into an equation. This avoids having to scalarize the binding.
  if not settings.nfAPI then
    if Type.isArray(ty) and Binding.isBound(binding) and var >= Variability.DISCRETE then
      name := ComponentRef.prefixCref(comp_node, ty, {}, prefix);
      eq := Equation.ARRAY_EQUALITY(Expression.CREF(ty, name), Binding.getTypedExp(binding), ty,
        ElementSource.createElementSource(info));
      sections := Sections.prependEquation(eq, sections);
      binding := NFBinding.EMPTY_BINDING;

      // Moving the binding of an input variable to an equation can change how
      // the variable is counted when counting variables and equations, but
      // since there's no way to override such a binding from outside the model
      // we can remove the input prefix to keep the balance.
      if comp_attr.direction == Direction.INPUT and ComponentRef.isEmpty(prefix) then
        comp_attr.direction := Direction.NONE;
        Error.addSourceMessage(Error.TOP_LEVEL_INPUT_WITH_BINDING,
          {ComponentRef.toString(name)}, info);
      end if;
    end if;
  end if;

  ty := flattenType(ty, prefix);
  name := ComponentRef.prefixCref(comp_node, ty, {}, prefix);
  ty_attrs := list(flattenTypeAttribute(m, name) for m in typeAttrs);

  // Set fixed = false for parameters that are part of a record instance whose
  // binding couldn't be split and was moved to an initial equation.
  if unfix then
    ty_attrs := Binding.setAttr(ty_attrs, "fixed",
      Binding.makeFlat(Expression.BOOLEAN(false), Variability.CONSTANT, NFBinding.Source.GENERATED));
  end if;

  vars := Variable.VARIABLE(name, ty, binding, visibility, comp_attr, ty_attrs, children, cmt, info) :: vars;
end flattenSimpleComponent;

function flattenTypeAttribute
  input Modifier attr;
  input ComponentRef prefix;
  output tuple<String, Binding> outAttr;
protected
  Binding binding;
algorithm
  binding := flattenBinding(Modifier.binding(attr), prefix, isTypeAttribute = true);
  outAttr := (Modifier.name(attr), binding);
end flattenTypeAttribute;

function isTypeAttributeNamed
  input String name;
  input tuple<String, Binding> attr;
  output Boolean isNamed;
protected
  String attr_name;
algorithm
  (attr_name, _) := attr;
  isNamed := name == attr_name;
end isTypeAttributeNamed;

function getRecordBindings
  input Binding binding;
  input array<InstNode> comps;
  input ComponentRef prefix;
  output list<Binding> recordBindings = {};
protected
  Expression binding_exp;
  Variability var;
  Binding.Source bind_src;
algorithm
  binding_exp := Binding.getTypedExp(binding);
  var := Binding.variability(binding);
  bind_src := Binding.source(binding);

  // Convert the expressions in the record expression into bindings.
  recordBindings := match binding_exp
    case Expression.RECORD()
      then list(if Expression.isEmpty(e) then
               // The binding for a record field might be Expression.EMPTY if it comes
               // from an evaluated function call where it wasn't assigned a value.
               NFBinding.EMPTY_BINDING
             else
               Binding.makeFlat(e, var, bind_src)
           for e in binding_exp.elements);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-record binding " +
          Expression.toString(binding_exp), sourceInfo());
      then
        fail();
  end match;

  Error.assertion(listLength(recordBindings) == arrayLength(comps),
    getInstanceName() + " got record binding with wrong number of elements for " +
      ComponentRef.toString(prefix),
    sourceInfo());
end getRecordBindings;

function flattenComplexComponent
  input InstNode node;
  input Component comp;
  input Class cls;
  input Type nodeTy;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input ComponentRef prefix;
  input output list<Variable> vars;
  input output Sections sections;
  input UnorderedSet<ComponentRef> deletedVars;
  input FlattenSettings settings;
protected
  list<Dimension> dims;
  ComponentRef name;
  Binding binding;
  Option<Binding> opt_binding;
  Expression binding_exp, binding_exp_eval;
  Equation eq;
  list<Expression> bindings;
  Variability comp_var, binding_var;
  Type ty;
algorithm
  ty := flattenType(nodeTy, prefix);
  dims := Type.arrayDims(ty);
  binding := if isSome(outerBinding) then Util.getOption(outerBinding) else Component.getBinding(comp);

  // Create an equation if there's a binding on a complex component.
  if Binding.isExplicitlyBound(binding) then
    binding := flattenBinding(binding, prefix);
    binding_exp := Binding.getTypedExp(binding);
    binding_var := Binding.variability(binding);

    comp_var := Component.variability(comp);
    if comp_var <= Variability.STRUCTURAL_PARAMETER or binding_var <= Variability.STRUCTURAL_PARAMETER then
      binding_exp := Ceval.evalExp(binding_exp);
    elseif binding_var == Variability.PARAMETER and Component.isFinal(comp) then
      // Try to use inlining first.
      try
        binding_exp := Inline.inlineRecordConstructorCall(binding_exp);
      else
      end try;

      // If inlining fails, try to evaluate the binding instead.
      if not (Expression.isRecord(binding_exp) or Expression.isCref(binding_exp)) then
        try
          binding_exp_eval := Ceval.evalExp(binding_exp);

          // Throw away the evaluated binding if the number of dimensions no
          // longer match after evaluation, in case Ceval fails to apply the
          // subscripts correctly.
          // TODO: Fix this, it shouldn't be needed.
          0 := Type.dimensionDiff(ty, Expression.typeOf(binding_exp_eval));
          binding_exp := binding_exp_eval;
        else
        end try;
      end if;
    else
      binding_exp := SimplifyExp.simplify(binding_exp);
    end if;

    binding_exp := splitRecordCref(binding_exp);

    // TODO: This will probably not work so well if the binding is an array that
    //       contains record non-literals. In that case we should probably
    //       create an equation for each non-literal in the array, and pass the
    //       rest on as usual.
    if not Expression.isRecordOrRecordArray(binding_exp) then
      name := ComponentRef.prefixCref(node, ty, {}, prefix);
      eq := Equation.EQUALITY(Expression.CREF(ty, name),  binding_exp, ty,
        ElementSource.createElementSource(InstNode.info(node)));
      sections := Sections.prependEquation(eq, sections, isInitial = comp_var <= Variability.PARAMETER);
      opt_binding := SOME(NFBinding.EMPTY_BINDING);
    else
      binding := Binding.setTypedExp(binding_exp, binding);
      opt_binding := SOME(binding);
    end if;
  else
    opt_binding := NONE();
  end if;

  name := ComponentRef.prefixCref(node, ty, {}, prefix);

  // Flatten the class directly if the component is a scalar, otherwise scalarize it.
  if listEmpty(dims) then
    (vars, sections) := flattenClass(cls, name, visibility, opt_binding, vars, sections, deletedVars, settings);
  elseif settings.scalarize then
    dims := list(flattenDimension(d, name) for d in dims);
    (vars, sections) := flattenArray(cls, dims, name, visibility, opt_binding, vars, sections, {}, deletedVars, settings);
  else
    (vars, sections) := vectorizeArray(cls, dims, name, visibility, opt_binding, vars, sections, {}, deletedVars, settings);
  end if;
end flattenComplexComponent;

function splitRecordCref
  input Expression exp;
  output Expression outExp;
algorithm
  outExp := ExpandExp.expand(exp);

  outExp := match outExp
    local
      InstNode cls;
      array<InstNode> comps;
      ComponentRef cr, field_cr;
      Type ty;
      list<Expression> fields;

    case Expression.CREF(ty = Type.COMPLEX(cls = cls), cref = cr)
      algorithm
        comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(cls)));
        fields := {};

        for i in arrayLength(comps):-1:1 loop
          ty := InstNode.getType(comps[i]);
          field_cr := ComponentRef.prefixCref(comps[i], ty, {}, cr);
          field_cr := flattenCref(field_cr, cr);
          fields := Expression.fromCref(field_cr) :: fields;
        end for;
      then
        Expression.makeRecord(InstNode.scopePath(cls), outExp.ty, fields);

    case Expression.ARRAY()
      algorithm
        outExp.elements := list(splitRecordCref(e) for e in outExp.elements);
      then
        outExp;

    else exp;
  end match;
end splitRecordCref;

function flattenArray
  input Class cls;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
  input output Sections sections;
  input list<Subscript> subscripts = {};
  input UnorderedSet<ComponentRef> deletedVars;
  input FlattenSettings settings;
protected
  Dimension dim;
  list<Dimension> rest_dims;
  ComponentRef sub_pre;
  RangeIterator range_iter;
  Expression sub_exp;
  list<Subscript> subs;
algorithm
  if listEmpty(dimensions) then
    subs := listReverse(subscripts);
    sub_pre := ComponentRef.setSubscripts(subs, prefix);

    (vars, sections) := flattenClass(cls, sub_pre, visibility,
      subscriptBindingOpt(subs, binding), vars, sections, deletedVars, settings);
  else
    dim :: rest_dims := dimensions;
    dim := flattenDimension(dim, prefix);
    range_iter := RangeIterator.fromDim(dim);

    while RangeIterator.hasNext(range_iter) loop
      (range_iter, sub_exp) := RangeIterator.next(range_iter);
      (vars, sections) := flattenArray(cls, rest_dims, prefix, visibility,
          binding, vars, sections, Subscript.INDEX(sub_exp) :: subscripts, deletedVars, settings);
    end while;
  end if;
end flattenArray;

function vectorizeArray
  input Class cls;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
  input output Sections sections;
  input list<Subscript> subscripts = {};
  input UnorderedSet<ComponentRef> deletedVars;
  input FlattenSettings settings;
protected
  list<Variable> vrs;
  Sections sects;
algorithm
  // if we don't scalarize flatten the class and vectorize it
  (vrs, sects) := flattenClass(cls, prefix, visibility, binding, {}, Sections.SECTIONS({}, {}, {}, {}), deletedVars, settings);

  // add dimensions to the types
  for v in vrs loop
    v.ty := Type.liftArrayLeftList(v.ty, dimensions);
    vars := v :: vars;
  end for;

  // vectorize equations
  () := match sects
    case Sections.SECTIONS()
      algorithm
        for eqn in listReverse(sects.equations) loop
          sections := Sections.prependEquation(vectorizeEquation(eqn, dimensions, prefix, settings), sections);
        end for;
        for eqn in listReverse(sects.initialEquations) loop
          sections := Sections.prependEquation(vectorizeEquation(eqn, dimensions, prefix, settings), sections, true);
        end for;
        for alg in listReverse(sects.algorithms) loop
          sections := Sections.prependAlgorithm(vectorizeAlgorithm(alg, dimensions, prefix), sections);
        end for;
        for alg in listReverse(sects.initialAlgorithms) loop
          sections := Sections.prependAlgorithm(vectorizeAlgorithm(alg, dimensions, prefix), sections, true);
        end for;
      then ();
  end match;
end vectorizeArray;

function vectorizeBinding
  input output Binding binding;
  input Type varType;
protected
  Expression bind_exp;
  Type bind_ty;
  Integer dim_diff;
  list<Dimension> dims;
  list<Expression> dim_expl;
algorithm
  () := match binding
    case Binding.TYPED_BINDING(bindingExp = bind_exp)
      algorithm
        bind_ty := match bind_exp
          case Expression.CREF()
            then ComponentRef.getSubscriptedType(bind_exp.cref, includeScope = true);
          else Expression.typeOf(bind_exp);
        end match;

        //bind_ty := Expression.typeOf(binding.bindingExp);
        dim_diff := Type.dimensionDiff(varType, bind_ty);

        if dim_diff > 0 then
          dim_expl := list(Dimension.sizeExp(d) for d in List.firstN(Type.arrayDims(varType), dim_diff));
          binding.bindingExp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.FILL_FUNC,
            binding.bindingExp :: dim_expl, binding.variability, Purity.PURE, varType));
          binding.bindingType := Expression.typeOf(binding.bindingExp);
        end if;
      then
        ();

    else ();
  end match;
end vectorizeBinding;

function vectorizeEquation
  input output Equation eqn;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input FlattenSettings settings;
algorithm
  // Flatten with an empty prefix to get rid of any split indices.
  {eqn} := flattenEquation(eqn, EMPTY_PREFIX, {}, settings);

  eqn := match eqn
    local
      InstNode iter;
      list<InstNode> iters;
      Expression range;
      list<Expression> ranges;
      list<Subscript> subs;
      DAE.ElementSource src;

    // convert simple equality of crefs to array equality
    case Equation.EQUALITY(lhs = Expression.CREF(), rhs = Expression.CREF())
      then Equation.ARRAY_EQUALITY(eqn.lhs, eqn.rhs, Type.liftArrayLeftList(eqn.ty, dimensions), eqn.source);

    // wrap general equation into for loop
    else
      algorithm
        (iters, ranges, subs) := makeIterators(prefix, dimensions);
        subs := listReverseInPlace(subs);
        eqn := Equation.mapExp(eqn, function addIterator(prefix = prefix, subscripts = subs));
        src := Equation.source(eqn);

        iter :: iters := iters;
        range :: ranges := ranges;
        eqn := Equation.FOR(iter, SOME(range), {eqn}, src);

        while not listEmpty(iters) loop
          iter :: iters := iters;
          range :: ranges := ranges;
          eqn := Equation.FOR(iter, SOME(range), {eqn}, src);
        end while;
      then
        eqn;

  end match;
end vectorizeEquation;

function vectorizeAlgorithm
  input output Algorithm alg;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
algorithm
  // Flatten with an empty prefix to get rid of any split indices.
  alg.statements := flattenStatements(alg.statements, EMPTY_PREFIX);

  alg := match alg
    local
      InstNode iter;
      list<InstNode> iters;
      Expression range;
      list<Expression> ranges;
      list<Subscript> subs;
      list<Statement> body;

    // let simple assignment as is
    case Algorithm.ALGORITHM(statements = {Statement.ASSIGNMENT(lhs = Expression.CREF(), rhs = Expression.CREF())})
      then alg;

    // wrap general algorithm into for loop
    else
      algorithm
        (iters, ranges, subs) := makeIterators(prefix, dimensions);
        subs := listReverseInPlace(subs);
        body := Statement.mapExpList(alg.statements, function addIterator(prefix = prefix, subscripts = subs));

        while not listEmpty(iters) loop
          iter :: iters := iters;
          range :: ranges := ranges;
          body := {Statement.FOR(iter, SOME(range), body, Statement.ForType.NORMAL(), alg.source)};
        end while;
      then
        Algorithm.ALGORITHM(body, alg.source);

  end match;
end vectorizeAlgorithm;

function makeIterators
  input ComponentRef prefix;
  input list<Dimension> dimensions;
  output list<InstNode> iterators = {};
  output list<Expression> ranges = {};
  output list<Subscript> subscripts = {};
protected
  Component iter_comp;
  InstNode prefix_node, iter;
  Expression range;
  Integer index = 1;
  Subscript sub;
algorithm
  prefix_node := ComponentRef.node(prefix);

  for dim in dimensions loop
    iter := InstNode.newIndexedIterator(index, Type.INTEGER(), InstNode.info(prefix_node));
    iterators := iter :: iterators;
    index := index + 1;

    range := Expression.makeRange(Expression.INTEGER(1), NONE(), Dimension.sizeExp(dim));
    ranges := range :: ranges;

    sub := Subscript.INDEX(Expression.CREF(Type.INTEGER(), ComponentRef.makeIterator(iter, Type.INTEGER())));
    subscripts := sub :: subscripts;
  end for;
end makeIterators;

function addIterator
  input output Expression exp;
  input ComponentRef prefix;
  input list<Subscript> subscripts;
algorithm
  exp := Expression.map(exp, function addIterator_traverse(prefix = prefix, subscripts = subscripts));
end addIterator;

function addIterator_traverse
  input output Expression exp;
  input ComponentRef prefix;
  input list<Subscript> subscripts;
protected
  String restString, prefixString = ComponentRef.toString(prefix);
  Integer prefixLength = stringLength(prefixString);
algorithm
  exp := match exp
    local
      ComponentRef restCref;
    case Expression.CREF(cref = ComponentRef.CREF(restCref = restCref))
      algorithm
        restString := ComponentRef.toString(restCref);
        if prefixLength <= stringLength(restString) and prefixString == substring(restString, 1, prefixLength) then
          exp.cref := ComponentRef.mergeSubscripts(subscripts, exp.cref, applyToScope = true);
        end if;
      then
        exp;
    else exp;
  end match;
end addIterator_traverse;

function subscriptBindingOpt
  input list<Subscript> subscripts;
  input output Option<Binding> binding;
protected
  Binding b;
  Expression exp;
  Type ty;
algorithm
  if isSome(binding) then
    SOME(b) := binding;

    binding := match b
      case Binding.TYPED_BINDING(bindingExp = exp, bindingType = ty)
        algorithm
          b.bindingExp := Expression.applySubscripts(subscripts, exp);
          b.bindingType := Type.arrayElementType(ty);
        then
          SOME(b);

      case Binding.FLAT_BINDING(bindingExp = exp)
        algorithm
          b.bindingExp := Expression.applySubscripts(subscripts, exp);
        then
          SOME(b);

      else binding;
    end match;
  end if;
end subscriptBindingOpt;

public function flattenBinding
  input output Binding binding;
  input ComponentRef prefix;
  input Boolean isTypeAttribute = false;
algorithm
  binding := match binding
    local
      list<Subscript> subs, accum_subs;
      Integer binding_level;
      Expression bind_exp;
      list<InstNode> pars;
      InstNode par;

    case Binding.UNBOUND() then binding;

    case Binding.TYPED_BINDING()
      algorithm
        if binding.isFlattened then
          return;
        end if;

        binding.bindingExp := flattenExp(binding.bindingExp, prefix);
        binding.bindingType := flattenType(binding.bindingType, prefix);
        binding.isFlattened := true;
      then
        binding;

    // CEVAL_BINDINGs are temporary bindings generated by the constant
    // evaluation and no longer needed after flattening.
    case Binding.CEVAL_BINDING() then NFBinding.EMPTY_BINDING;
    case Binding.FLAT_BINDING() then binding;

    case Binding.INVALID_BINDING()
      algorithm
        Error.addTotalMessages(binding.errors);
      then
        fail();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got untyped binding.", sourceInfo());
      then
        fail();

  end match;
end flattenBinding;

public function flattenExp
  input output Expression exp;
  input ComponentRef prefix;
algorithm
  exp := Expression.map(exp, function flattenExp_traverse(prefix = prefix));
end flattenExp;

function flattenExp_traverse
  input output Expression exp;
  input ComponentRef prefix;
algorithm
  exp := match exp
    case Expression.CREF(cref = ComponentRef.CREF())
      algorithm
        exp.cref := flattenCref(exp.cref, prefix);
        exp.ty := flattenType(exp.ty, prefix);
      then
        exp;

    case Expression.SUBSCRIPTED_EXP()
      then replaceSplitIndices(exp.exp, exp.subscripts, prefix);

    case Expression.IF(ty = Type.CONDITIONAL_ARRAY()) then flattenConditionalArrayIfExp(exp);
    else exp;
  end match;

  exp := flattenExpType(exp, prefix);
end flattenExp_traverse;

function replaceSplitIndices
  input output Expression exp;
  input list<Subscript> subscripts;
  input ComponentRef prefix;
protected
  list<Subscript> subs = subscripts, cr_subs;
  Integer index;
  InstNode cr_node;
algorithm
  for cr in ComponentRef.toListReverse(prefix) loop
    cr_subs := ComponentRef.getSubscripts(cr);

    if not listEmpty(cr_subs) then
      index := 1;
      cr_node := ComponentRef.node(cr);

      for s in cr_subs loop
        subs := List.replaceOnTrue(s, subs,
          function replaceSplitIndices2(node = cr_node, index = index));
        index := index + 1;
      end for;
    end if;
  end for;

  subs := Subscript.expandSplitIndices(subs);
  exp := Expression.applySubscripts(subs, exp);
end replaceSplitIndices;

function replaceSplitIndices2
  input Subscript sub;
  input InstNode node;
  input Integer index;
  output Boolean replace;
algorithm
  replace := match sub
    case Subscript.SPLIT_INDEX()
      then sub.dimIndex == index and InstNode.refEqual(sub.node, node);
    else false;
  end match;
end replaceSplitIndices2;

function flattenCref
  input output ComponentRef cref;
  input ComponentRef prefix;
protected
  Type ty, ty2;
algorithm
  cref := ComponentRef.transferSubscripts(prefix, cref);

  if ComponentRef.hasSplitSubscripts(cref) then
    cref := flattenCrefSplitSubscripts(cref, prefix);
  end if;

  cref := ComponentRef.mapTypes(cref, function flattenType(prefix = prefix));
end flattenCref;

function flattenCrefSplitSubscripts
  input output ComponentRef cref;
  input ComponentRef prefix;
protected
  type SubscriptList = list<Subscript>;
  UnorderedMap<InstNode, SubscriptList> sub_map;
algorithm
  sub_map := UnorderedMap.new<SubscriptList>(InstNode.hash, InstNode.refEqual);

  for cr in ComponentRef.toListReverse(prefix) loop
    if ComponentRef.hasSubscripts(cr) then
      UnorderedMap.addUnique(ComponentRef.node(cr), ComponentRef.getSubscripts(cr), sub_map);
    end if;
  end for;

  cref := ComponentRef.mapSubscripts(cref, function flattenCrefSplitSubscripts2(subMap = sub_map));
  cref := ComponentRef.simplifySubscripts(cref, true);
end flattenCrefSplitSubscripts;

function flattenCrefSplitSubscripts2
  input output Subscript sub;
  input UnorderedMap<InstNode, list<Subscript>> subMap;
algorithm
  sub := match sub
    local
      list<Subscript> subs;

    case Subscript.SPLIT_INDEX()
      algorithm
        subs := UnorderedMap.getOrDefault(sub.node, subMap, {});
      then
        if sub.dimIndex > listLength(subs) then Subscript.WHOLE() else listGet(subs, sub.dimIndex);

    else sub;
  end match;
end flattenCrefSplitSubscripts2;

function flattenConditionalArrayIfExp
  input output Expression exp;
protected
  Expression cond;
  Variability cond_var;
algorithm
  Expression.IF(condition = cond) := exp;
  cond_var := Expression.variability(cond);

  if Expression.variability(cond) == Variability.PARAMETER then
    Structural.markExp(cond);
  end if;
end flattenConditionalArrayIfExp;

function flattenExpType
  input output Expression exp;
  input ComponentRef prefix;
protected
  Type ty;
algorithm
  ty := Expression.typeOf(exp);

  if Type.isArray(ty) then
    ty := flattenType(ty, prefix);
    exp := Expression.setType(ty, exp);
  end if;
end flattenExpType;

function flattenType
  input output Type ty;
  input ComponentRef prefix;
algorithm
  ty := Type.mapDims(ty, function flattenDimension(prefix = prefix));
end flattenType;

function flattenDimension
  input output Dimension dim;
  input ComponentRef prefix;
algorithm
  dim := match dim
    case Dimension.EXP()
      then Dimension.fromExp(flattenExp(dim.exp, prefix), dim.var);

    else dim;
  end match;
end flattenDimension;

function flattenSections
  input Sections sections;
  input ComponentRef prefix;
  input output Sections accumSections;
  input FlattenSettings settings;
algorithm
  () := match sections
    local
      list<Equation> eq, ieq;
      list<Algorithm> alg, ialg;

    case Sections.SECTIONS()
      algorithm
        eq := flattenEquations(sections.equations, prefix, settings);
        ieq := flattenEquations(sections.initialEquations, prefix, settings);
        alg := flattenAlgorithms(sections.algorithms, prefix);
        ialg := flattenAlgorithms(sections.initialAlgorithms, prefix);
        accumSections := Sections.prepend(eq, ieq, alg, ialg, accumSections);
      then
        ();

    else ();
  end match;
end flattenSections;

function flattenEquations
  input list<Equation> eql;
  input ComponentRef prefix;
  input FlattenSettings settings;
  output list<Equation> equations = {};
algorithm
  for eq in eql loop
    equations := flattenEquation(eq, prefix, equations, settings);
  end for;
end flattenEquations;

function flattenEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
algorithm
  equations := match eq
    local
      Expression e1, e2, e3;
      Type ty;
      list<Equation> eql;

    case Equation.EQUALITY()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
        ty := flattenType(eq.ty, prefix);
      then
        Equation.EQUALITY(e1, e2, ty, eq.source) :: equations;

    case Equation.FOR()
      algorithm
        if settings.arrayConnect then
          eq.body := flattenEquations(eq.body, EMPTY_PREFIX, settings);
          eql := eq :: equations;
        elseif not settings.scalarize then
          eql := splitForLoop(eq, prefix, equations, settings);
        else
          eql := unrollForLoop(eq, prefix, equations, settings);
        end if;
      then eql;

    case Equation.CONNECT()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
      then
        Equation.CONNECT(e1, e2, eq.source) :: equations;

    case Equation.IF()
      then flattenIfEquation(eq, prefix, equations, settings);

    case Equation.WHEN()
      algorithm
        eq.branches := list(flattenEqBranch(b, prefix, settings) for b in eq.branches);
      then
        eq :: equations;

    case Equation.ASSERT()
      algorithm
        e1 := flattenExp(eq.condition, prefix);
        e2 := flattenExp(eq.message, prefix);
        e3 := flattenExp(eq.level, prefix);
      then
        Equation.ASSERT(e1, e2, e3, eq.source) :: equations;

    case Equation.TERMINATE()
      algorithm
        e1 := flattenExp(eq.message, prefix);
      then
        Equation.TERMINATE(e1, eq.source) :: equations;

    case Equation.REINIT()
      algorithm
        e1 := flattenExp(eq.cref, prefix);
        e2 := flattenExp(eq.reinitExp, prefix);
      then
        Equation.REINIT(e1, e2, eq.source) :: equations;

    case Equation.NORETCALL()
      algorithm
        e1 := flattenExp(eq.exp, prefix);
      then
        Equation.NORETCALL(e1, eq.source) :: equations;

    else eq :: equations;
  end match;
end flattenEquation;

function flattenIfEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
protected
  Equation.Branch branch;
  list<Equation.Branch> branches, bl = {};
  Expression cond;
  list<Equation> eql;
  Variability var;
  Boolean has_connect;
  DAE.ElementSource src;
  SourceInfo info;
  Ceval.EvalTarget target;
algorithm
  Equation.IF(branches = branches, source = src) := eq;
  has_connect := Equation.contains(eq, isConnectEq);

  // Print errors for unbound constants/parameters if the if-equation contains
  // connects, since we must select a branch in that case.
  target := if has_connect then
    Ceval.EvalTarget.GENERIC(Equation.info(eq)) else
    Ceval.EvalTarget.IGNORE_ERRORS();

  while not listEmpty(branches) loop
    branch :: branches := branches;

    bl := match branch
      case Equation.Branch.BRANCH(cond, var, eql)
        algorithm
          // Flatten the condition and body of the branch.
          cond := flattenExp(cond, prefix);

          // Evaluate structural conditions.
          if var <= Variability.STRUCTURAL_PARAMETER then
            if Expression.isPure(cond) then
              cond := Ceval.evalExp(cond, target);
            end if;

            // Conditions in an if-equation that contains connects must be possible to evaluate.
            if not Expression.isBoolean(cond) and has_connect then
              Error.addInternalError(
                "Failed to evaluate branch condition in if equation containing connect equations: `" +
                Expression.toString(cond) + "`", Equation.info(eq));
              fail();
            end if;
          end if;

          if Expression.isTrue(cond) then
            // The condition is true and the branch will thus always be selected
            // if reached, so we can discard the remaining branches.
            branches := {};
            eql := flattenEquations(eql, prefix, settings);

            if listEmpty(bl) then
              // If we haven't collected any other branches yet, replace the if-equation with this branch.
              equations := listAppend(eql, equations);
            else
              // Otherwise, append this branch.
              bl := Equation.makeBranch(cond, listReverseInPlace(eql), var) :: bl;
            end if;
          elseif not Expression.isFalse(cond) then
            // Only add the branch to the list of branches if the condition is not
            // literal false, otherwise just drop it since it will never trigger.
            eql := flattenEquations(eql, prefix, settings);
            bl := Equation.makeBranch(cond, listReverseInPlace(eql), var) :: bl;
          end if;
        then
          bl;

      // An invalid branch must have a false condition, anything else is an error.
      case Equation.Branch.INVALID_BRANCH(branch =
          Equation.Branch.BRANCH(condition = cond, conditionVar = var))
        guard has_connect
        algorithm
          if var <= Variability.STRUCTURAL_PARAMETER then
            cond := Ceval.evalExp(cond, target);
          end if;

          if not Expression.isFalse(cond) then
            Equation.Branch.triggerErrors(branch);
          end if;
        then
          bl;

      else branch :: bl;
    end match;
  end while;

  // Add the flattened if-equation to the list of equations if there are any
  // branches still remaining.
  if not listEmpty(bl) then
    equations := Equation.IF(listReverseInPlace(bl), src) :: equations;
  end if;
end flattenIfEquation;

function isConnectEq
  input Equation eq;
  output Boolean isConnect;
algorithm
  isConnect := match eq
    local
      Function fn;

    case Equation.CONNECT() then true;
    case Equation.NORETCALL(exp = Expression.CALL(call = Call.TYPED_CALL(fn = fn)))
      then AbsynUtil.pathFirstIdent(Function.name(fn)) == "Connections";
    else false;
  end match;
end isConnectEq;

function flattenEqBranch
  input output Equation.Branch branch;
  input ComponentRef prefix;
  input FlattenSettings settings;
protected
  Expression exp;
  list<Equation> eql;
  Variability var;
algorithm
  Equation.Branch.BRANCH(exp, var, eql) := branch;
  exp := flattenExp(exp, prefix);
  eql := flattenEquations(eql, prefix, settings);
  branch := Equation.makeBranch(exp, listReverseInPlace(eql), var);
end flattenEqBranch;

function unrollForLoop
  input Equation forLoop;
  input ComponentRef prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
protected
  InstNode iter;
  list<Equation> body, unrolled_body;
  Expression range;
  RangeIterator range_iter;
  Expression val;
algorithm
  Equation.FOR(iterator = iter, range = SOME(range), body = body) := forLoop;

  // Unroll the loop by replacing the iterator with each of its values in the for loop body.
  range := flattenExp(range, prefix);
  range := Ceval.evalExp(range, Ceval.EvalTarget.RANGE(Equation.info(forLoop)));
  range_iter := RangeIterator.fromExp(range);

  while RangeIterator.hasNext(range_iter) loop
    (range_iter, val) := RangeIterator.next(range_iter);
    unrolled_body := Equation.replaceIteratorList(body, iter, val);
    unrolled_body := flattenEquations(unrolled_body, prefix, settings);
    equations := listAppend(unrolled_body, equations);
  end while;
end unrollForLoop;

function splitForLoop
  input Equation forLoop;
  input ComponentRef prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
protected
  InstNode iter;
  Option<Expression> range;
  list<Equation> body, connects, non_connects;
  DAE.ElementSource src;
  Equation eq;
algorithm
  Equation.FOR(iter, range, body, src) := forLoop;
  body := flattenEquations(body, EMPTY_PREFIX, settings);
  (connects, non_connects) := splitForLoop2(body);

  if not listEmpty(connects) then
    eq := Equation.FOR(iter, range, connects, src);

    if settings.arrayConnect then
      equations := eq :: equations;
    else
      equations := unrollForLoop(eq, prefix, equations, settings);
    end if;
  end if;

  if not listEmpty(non_connects) then
    equations := Equation.FOR(iter, range, non_connects, src) :: equations;
  end if;
end splitForLoop;

function splitForLoop2
  input list<Equation> forBody;
  output list<Equation> connects = {};
  output list<Equation> nonConnects = {};
protected
  list<Equation> conns, nconns;
algorithm
  for eq in forBody loop
    () := match eq
      case Equation.CONNECT()
        algorithm
          connects := eq :: connects;
        then
          ();

      case Equation.FOR()
        algorithm
          (conns, nconns) := splitForLoop2(eq.body);

          if not listEmpty(conns) then
            connects := Equation.FOR(eq.iterator, eq.range, conns, eq.source) :: connects;
          end if;

          if not listEmpty(nconns) then
            nonConnects := Equation.FOR(eq.iterator, eq.range, nconns, eq.source) :: nonConnects;
          end if;
        then
          ();

      else
        algorithm
          nonConnects := eq :: nonConnects;
        then
          ();

    end match;
  end for;
end splitForLoop2;

function flattenAlgorithms
  input list<Algorithm> algorithms;
  input ComponentRef prefix;
  output list<Algorithm> outAlgorithms = {};
algorithm
  for alg in algorithms loop
    alg.statements := flattenStatements(alg.statements, prefix);

    // CheckModel relies on the ElementSource to know whether a certain algorithm comes from
    // an array component, otherwise is will miscount the number of equations.
    if ComponentRef.hasSubscripts(prefix) then
      alg.source := addElementSourceArrayPrefix(alg.source, prefix);
    end if;

    outAlgorithms := alg :: outAlgorithms;
  end for;
end flattenAlgorithms;

function flattenStatements
  input output list<Statement> stmts;
  input ComponentRef prefix;
algorithm
  stmts := list(flattenStatement(s, prefix) for s in stmts);
end flattenStatements;

function flattenStatement
  input output Statement stmt;
  input ComponentRef prefix;
algorithm
  stmt := match stmt
    local
      Expression e1, e2, e3;
      Type ty;
      list<Statement> body;

    case Statement.ASSIGNMENT()
      algorithm
        e1 := flattenExp(stmt.lhs, prefix);
        e2 := flattenExp(stmt.rhs, prefix);
        ty := flattenType(stmt.ty, prefix);
      then
        Statement.ASSIGNMENT(e1, e2, ty, stmt.source);

    case Statement.FOR()
      algorithm
        stmt.range := Util.applyOption(stmt.range, function flattenExp(prefix = prefix));
        stmt.body := flattenStatements(stmt.body, prefix);
        stmt.forType := updateForType(stmt.forType, stmt.body);
      then
        stmt;

    case Statement.IF()
      algorithm
        stmt.branches := list(flattenStmtBranch(b, prefix) for b in stmt.branches);
      then
        stmt;

    case Statement.WHEN()
      algorithm
        stmt.branches := list(flattenStmtBranch(b, prefix) for b in stmt.branches);
      then
        stmt;

    case Statement.ASSERT()
      algorithm
        e1 := flattenExp(stmt.condition, prefix);
        e2 := flattenExp(stmt.message, prefix);
        e3 := flattenExp(stmt.level, prefix);
      then
        Statement.ASSERT(e1, e2, e3, stmt.source);

    case Statement.TERMINATE()
      algorithm
        e1 := flattenExp(stmt.message, prefix);
      then
        Statement.TERMINATE(e1, stmt.source);

    case Statement.NORETCALL()
      algorithm
        e1 := flattenExp(stmt.exp, prefix);
      then
        Statement.NORETCALL(e1, stmt.source);

    case Statement.WHILE()
      algorithm
        e1 := flattenExp(stmt.condition, prefix);
        body := flattenStatements(stmt.body, prefix);
      then
        Statement.WHILE(e1, body, stmt.source);

    case Statement.FAILURE()
      algorithm
        body := flattenStatements(stmt.body, prefix);
      then
        Statement.FAILURE(body, stmt.source);

    else stmt;
  end match;
end flattenStatement;

function flattenStmtBranch
  input output tuple<Expression, list<Statement>> branch;
  input ComponentRef prefix;
protected
  Expression cond;
  list<Statement> body;
algorithm
  (cond, body) := branch;
  cond := flattenExp(cond, prefix);
  body := flattenStatements(body, prefix);
  branch := (cond, body);
end flattenStmtBranch;

function addElementSourceArrayPrefix
  input output DAE.ElementSource source;
  input ComponentRef prefix;
protected
  DAE.ComponentPrefix comp_pre;
algorithm
  // It seems the backend doesn't really care about the ComponentPrefix, and
  // creating a proper prefix here could be rather expensive. So we just create
  // a dummy prefix here with one subscript to keep CheckModel happy.
  comp_pre := DAE.ComponentPrefix.PRE(
    ComponentRef.firstName(prefix),
    {},
    {DAE.Subscript.INDEX(DAE.Exp.ICONST(-1))},
    DAE.ComponentPrefix.NOCOMPPRE(),
    ClassInf.State.UNKNOWN(Absyn.IDENT("?")),
    AbsynUtil.dummyInfo
  );

  source := ElementSource.addElementSourceInstanceOpt(source, comp_pre);
end addElementSourceArrayPrefix;

function isDeletedConnector
  input ComponentRef cref;
  input UnorderedSet<ComponentRef> deletedVars;
  output Boolean res;
protected
  ComponentRef cr = cref;
  InstNode node;
algorithm
  cr := ComponentRef.stripSubscripts(cref);

  while ComponentRef.isCref(cr) loop
    node := ComponentRef.node(cr);

    if InstNode.isComponent(node) and Component.hasCondition(InstNode.component(node)) then
      if UnorderedSet.contains(cr, deletedVars) then
        res := true;
        return;
      end if;
    end if;

    cr := ComponentRef.stripSubscripts(ComponentRef.rest(cr));
  end while;

  res := false;
end isDeletedConnector;

function resolveConnections
"Generates the connect equations and adds them to the equation list"
  input output FlatModel flatModel;
  input UnorderedSet<ComponentRef> deletedVars;
protected
  Connections conns;
  list<Equation> conn_eql, ec_eql;
  ConnectionSets.Sets csets;
  array<list<Connector>> csets_array;
  CardinalityTable.Table ctable;
  Connections.BrokenEdges broken = {};
  UnorderedMap<ComponentRef, Variable> vars;
algorithm
  vars := UnorderedMap.new<Variable>(ComponentRef.hash, ComponentRef.isEqual,
    listLength(flatModel.variables));

  for v in flatModel.variables loop
    UnorderedMap.addNew(v.name, v, vars);
  end for;

  // get the connections from the model
  (flatModel, conns) := Connections.collect(flatModel,
    function isDeletedConnector(deletedVars = deletedVars));

  // Elaborate expandable connectors.
  (flatModel, conns) := ExpandableConnectors.elaborate(flatModel, conns);
  // handle overconstrained connections
  // - build the graph
  // - evaluate the Connections.* operators
  // - generate the equations to replace the broken connects
  // - return the broken connects + the equations
  if  System.getHasOverconstrainedConnectors() then
    (flatModel, broken) := NFOCConnectionGraph.handleOverconstrainedConnections(flatModel, conns,
      function isDeletedConnector(deletedVars = deletedVars));
  end if;
  // add the broken connections
  conns := Connections.addBroken(broken, conns);
  // build the sets, check the broken connects
  csets := ConnectionSets.fromConnections(conns);
  csets_array := ConnectionSets.extractSets(csets);
  // generate the equations
  conn_eql := ConnectEquations.generateEquations(csets_array, vars);

  // append the equalityConstraint call equations for the broken connects
  if System.getHasOverconstrainedConnectors() then
    ec_eql := List.flatten(list(Util.tuple33(e) for e in broken));
    flatModel.equations := listAppend(ec_eql, flatModel.equations);
  end if;

  // add the equations to the flat model
  flatModel.equations := listAppend(conn_eql, flatModel.equations);
  flatModel.variables := list(v for v guard Variable.isPresent(v) in flatModel.variables);

  ctable := CardinalityTable.fromConnections(conns);

  // Evaluate any connection operators if they're used.
  if  System.getHasStreamConnectors() or System.getUsesCardinality() then
    flatModel := evaluateConnectionOperators(flatModel, csets, csets_array, vars, ctable);
  end if;

  execStat(getInstanceName());
end resolveConnections;

function evaluateConnectionOperators
  input output FlatModel flatModel;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input UnorderedMap<ComponentRef, Variable> variables;
  input CardinalityTable.Table ctable;
algorithm
  flatModel.variables := list(evaluateBindingConnOp(c, sets, setsArray, variables, ctable) for c in flatModel.variables);
  flatModel.equations := evaluateEquationsConnOp(flatModel.equations, sets, setsArray, variables, ctable);
  flatModel.initialEquations := evaluateEquationsConnOp(flatModel.initialEquations, sets, setsArray, variables, ctable);
  // TODO: Implement evaluation for algorithm sections.
end evaluateConnectionOperators;

function evaluateBindingConnOp
  input output Variable var;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input UnorderedMap<ComponentRef, Variable> variables;
  input CardinalityTable.Table ctable;
protected
  Binding binding;
  Expression exp, eval_exp;
algorithm
  () := match var
    case Variable.VARIABLE(binding = binding as Binding.TYPED_BINDING(bindingExp = exp))
      algorithm
        eval_exp := ConnectEquations.evaluateOperators(exp, sets, setsArray, variables, ctable);

        if not referenceEq(exp, eval_exp) then
          binding.bindingExp := eval_exp;
          var.binding := binding;
        end if;
      then
        ();

    else ();
  end match;
end evaluateBindingConnOp;

function evaluateEquationsConnOp
  input output list<Equation> equations;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input UnorderedMap<ComponentRef, Variable> variables;
  input CardinalityTable.Table ctable;
algorithm
  equations := list(evaluateEquationConnOp(eq, sets, setsArray, variables, ctable) for eq in equations);
end evaluateEquationsConnOp;

function evaluateEquationConnOp
  input output Equation eq;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input UnorderedMap<ComponentRef, Variable> variables;
  input CardinalityTable.Table ctable;
algorithm
  eq := Equation.mapExp(eq,
    function ConnectEquations.evaluateOperators(sets = sets, setsArray = setsArray,
      variables = variables, ctable = ctable));

  () := match eq
    case Equation.IF()
      algorithm
        for b in eq.branches loop
          () := match b
            case Equation.Branch.BRANCH()
              algorithm
                if b.conditionVar == Variability.PARAMETER and not
                   Structural.isExpressionNotFixed(b.condition, maxDepth = 100)
                then
                  Structural.markExp(b.condition);
                end if;
              then
                ();

            else ();
          end match;
        end for;
      then
        ();

    else ();
  end match;
end evaluateEquationConnOp;

function resolveArrayConnections
  "Generates the connect equations and adds them to the equation list"
  input output FlatModel flatModel;
algorithm
  flatModel := ArrayConnections.resolve(flatModel);
  execStat(getInstanceName());
end resolveArrayConnections;

function collectComponentFuncs
  input Variable var;
  input output FunctionTree funcs;
algorithm
  () := match var
    case Variable.VARIABLE()
      algorithm
        funcs := collectTypeFuncs(var.ty, funcs);
        funcs := collectBindingFuncs(var.binding, funcs);

        for attr in var.typeAttributes loop
          funcs := collectBindingFuncs(Util.tuple22(attr), funcs);
        end for;

        for c in var.children loop
          funcs := collectComponentFuncs(c, funcs);
        end for;
      then
        ();

  end match;
end collectComponentFuncs;

function collectBindingFuncs
  input Binding binding;
  input output FunctionTree funcs;
algorithm
  if Binding.isExplicitlyBound(binding) then
    funcs := collectExpFuncs(Binding.getTypedExp(binding), funcs);
  end if;
end collectBindingFuncs;

function collectTypeFuncs
  input Type ty;
  input output FunctionTree funcs;
protected
algorithm
  () := match ty
    local
      InstNode con, de;
      Function fn;

    case Type.ARRAY()
      algorithm
        funcs := Dimension.foldExpList(ty.dimensions, collectExpFuncs_traverse, funcs);
        funcs := collectTypeFuncs(ty.elementType, funcs);
      then
        ();

    case Type.FUNCTION(fn = fn)
      algorithm
        funcs := flattenFunction(fn, funcs);
      then
        ();

    // Collect external object structors.
    case Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT(constructor = con, destructor = de))
      algorithm
        funcs := collectStructor(con, funcs);
        funcs := collectStructor(de, funcs);
      then
        ();

    // Collect record constructors.
    case Type.COMPLEX(complexTy = ComplexType.RECORD(constructor = con))
      algorithm
        funcs := collectStructor(con, funcs);
      then
        ();

    else ();
  end match;
end collectTypeFuncs;

function collectStructor
  input InstNode node;
  input output FunctionTree funcs;
protected
  CachedData cache;
  list<Function> fn;
algorithm
  cache := InstNode.getFuncCache(node);

  () := match cache
    case CachedData.FUNCTION()
      algorithm
        for fn in cache.funcs loop
          funcs := flattenFunction(fn, funcs);
        end for;
      then
        ();

    else ();
  end match;
end collectStructor;

function collectEquationFuncs
  input Equation eq;
  input output FunctionTree funcs;
algorithm
  () := match eq
    case Equation.EQUALITY()
      algorithm
        funcs := collectExpFuncs(eq.lhs, funcs);
        funcs := collectExpFuncs(eq.rhs, funcs);
        funcs := collectTypeFuncs(eq.ty, funcs);
      then
        ();

    case Equation.ARRAY_EQUALITY()
      algorithm
        // Lhs is always a cref, no need to check it.
        funcs := collectExpFuncs(eq.rhs, funcs);
        funcs := collectTypeFuncs(eq.ty, funcs);
      then
        ();

    // For equations are always unrolled, so functions in the range doesn't
    // matter since they are always evaluated.
    case Equation.FOR()
      algorithm
        funcs := List.fold(eq.body, collectEquationFuncs, funcs);
      then
        ();

    case Equation.IF()
      algorithm
        funcs := List.fold(eq.branches, collectEqBranchFuncs, funcs);
      then
        ();

    case Equation.WHEN()
      algorithm
        funcs := List.fold(eq.branches, collectEqBranchFuncs, funcs);
      then
        ();

    case Equation.ASSERT()
      algorithm
        funcs := collectExpFuncs(eq.condition, funcs);
        funcs := collectExpFuncs(eq.message, funcs);
        funcs := collectExpFuncs(eq.level, funcs);
      then
        ();

    case Equation.TERMINATE()
      algorithm
        funcs := collectExpFuncs(eq.message, funcs);
      then
        ();

    case Equation.REINIT()
      algorithm
        funcs := collectExpFuncs(eq.reinitExp, funcs);
      then
        ();

    case Equation.NORETCALL()
      algorithm
        funcs := collectExpFuncs(eq.exp, funcs);
      then
        ();

    else ();
  end match;
end collectEquationFuncs;

function collectEqBranchFuncs
  input Equation.Branch branch;
  input output FunctionTree funcs;
algorithm
  () := match branch
    case Equation.Branch.BRANCH()
      algorithm
        funcs := collectExpFuncs(branch.condition, funcs);
        funcs := List.fold(branch.body, collectEquationFuncs, funcs);
      then
        ();

    else ();
  end match;
end collectEqBranchFuncs;

function collectAlgorithmFuncs
  input Algorithm alg;
  input output FunctionTree funcs;
algorithm
  funcs := List.fold(alg.statements, collectStatementFuncs, funcs);
end collectAlgorithmFuncs;

function collectStatementFuncs
  input Statement stmt;
  input output FunctionTree funcs;
algorithm
  () := match stmt
    case Statement.ASSIGNMENT()
      algorithm
        funcs := collectExpFuncs(stmt.lhs, funcs);
        funcs := collectExpFuncs(stmt.rhs, funcs);
        funcs := collectTypeFuncs(stmt.ty, funcs);
      then
        ();

    case Statement.FOR()
      algorithm
        funcs := List.fold(stmt.body, collectStatementFuncs, funcs);
        funcs := collectExpFuncs(Util.getOption(stmt.range), funcs);
      then
        ();

    case Statement.IF()
      algorithm
        funcs := List.fold(stmt.branches, collectStmtBranchFuncs, funcs);
      then
        ();

    case Statement.WHEN()
      algorithm
        funcs := List.fold(stmt.branches, collectStmtBranchFuncs, funcs);
      then
        ();

    case Statement.ASSERT()
      algorithm
        funcs := collectExpFuncs(stmt.condition, funcs);
        funcs := collectExpFuncs(stmt.message, funcs);
        funcs := collectExpFuncs(stmt.level, funcs);
      then
        ();

    case Statement.TERMINATE()
      algorithm
        funcs := collectExpFuncs(stmt.message, funcs);
      then
        ();

    case Statement.NORETCALL()
      algorithm
        funcs := collectExpFuncs(stmt.exp, funcs);
      then
        ();

    case Statement.WHILE()
      algorithm
        funcs := collectExpFuncs(stmt.condition, funcs);
        funcs := List.fold(stmt.body, collectStatementFuncs, funcs);
      then
        ();

    else ();
  end match;
end collectStatementFuncs;

function collectStmtBranchFuncs
  input tuple<Expression, list<Statement>> branch;
  input output FunctionTree funcs;
algorithm
  funcs := collectExpFuncs(Util.tuple21(branch), funcs);
  funcs := List.fold(Util.tuple22(branch), collectStatementFuncs, funcs);
end collectStmtBranchFuncs;

function collectExpFuncs
  input Expression exp;
  input output FunctionTree funcs;
algorithm
  funcs := Expression.fold(exp, collectExpFuncs_traverse, funcs);
end collectExpFuncs;

function collectExpFuncs_traverse
  input Expression exp;
  input output FunctionTree funcs;
algorithm
  () := match exp
    local
      Function fn;

    case Expression.CALL()
      algorithm
        funcs := flattenFunction(Call.typedFunction(exp.call), funcs);
      then
        ();

    case Expression.CREF()
      algorithm
        funcs := collectTypeFuncs(exp.ty, funcs);
      then
        ();

    case Expression.RECORD()
      algorithm
        funcs := collectTypeFuncs(exp.ty, funcs);
      then
        ();

    case Expression.PARTIAL_FUNCTION_APPLICATION()
      algorithm
        for f in Function.getRefCache(exp.fn) loop
          funcs := flattenFunction(f, funcs);
        end for;
      then
        ();

    else ();
  end match;
end collectExpFuncs_traverse;

function flattenFunction
  input Function func;
  input output FunctionTree funcs;
protected
  Function fn = func;
algorithm
  if not Function.isCollected(fn) then
    fn := Function.mapExp(fn, Expression.expandSplitIndices);
    fn := EvalConstants.evaluateFunction(fn);
    SimplifyModel.simplifyFunction(fn);
    Function.collect(fn);

    if not InstNode.isPartial(fn.node) then
      funcs := FunctionTree.add(funcs, Function.name(fn), fn);
      funcs := collectClassFunctions(fn.node, funcs);

      for fn_der in fn.derivatives loop
        for der_fn in Function.getCachedFuncs(fn_der.derivativeFn) loop
          funcs := flattenFunction(der_fn, funcs);
        end for;
      end for;

      for fn_inv in fn.inverses loop
        funcs := collectExpFuncs(fn_inv.inverseCall, funcs);
      end for;
    end if;
  end if;
end flattenFunction;

function collectClassFunctions
  input InstNode clsNode;
  input output FunctionTree funcs;
protected
  Class cls;
  ClassTree cls_tree;
  Sections sections;
  Component comp;
  Binding binding;
algorithm
  cls := InstNode.getClass(clsNode);

  () := match cls
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE(), sections = sections)
      algorithm
        for c in cls_tree.components loop
          comp := InstNode.component(c);
          funcs := collectTypeFuncs(Component.getType(comp), funcs);
          binding := Component.getBinding(comp);

          if Binding.isExplicitlyBound(binding) then
            funcs := collectExpFuncs(Binding.getTypedExp(binding), funcs);
          end if;
        end for;

        () := match sections
          case Sections.SECTIONS()
            algorithm
              funcs := List.fold(sections.algorithms, collectAlgorithmFuncs, funcs);
            then
              ();

          else ();
        end match;
      then
        ();

    case Class.TYPED_DERIVED()
      algorithm
        funcs := collectClassFunctions(cls.baseClass, funcs);
      then
        ();

    else ();
  end match;
end collectClassFunctions;

function updateForType
  input output Statement.ForType forType;
  input list<Statement> forBody;
protected
  UnorderedMap<ComponentRef, SourceInfo> vars;
algorithm
  () := match forType
    case Statement.ForType.NORMAL() then ();

    case Statement.ForType.PARALLEL()
      algorithm
        // ParModelica needs to know which variables are used in the loop body,
        // so collect them here and add them to the ForType.
        vars := UnorderedMap.new<SourceInfo>(ComponentRef.hash, ComponentRef.isEqual);

        for s in forBody loop
          vars := Statement.fold(s, collectParallelVariables, vars);
        end for;

        forType.vars := UnorderedMap.toList(vars);

        // Only parglobal variables are allowed to be used in a parfor loop.
        for v in forType.vars loop
          checkParGlobalCref(v);
        end for;
      then
        ();

  end match;
end updateForType;

function collectParallelVariables
  input Statement stmt;
  input output UnorderedMap<ComponentRef, SourceInfo> vars;
protected
  SourceInfo info;
algorithm
  info := Statement.info(stmt);
  vars := Statement.foldExp(stmt,
    function Expression.fold(func = function collectParallelVariablesExp(info = info)), vars);
end collectParallelVariables;

function collectParallelVariablesExp
  input Expression exp;
  input SourceInfo info;
  input output UnorderedMap<ComponentRef, SourceInfo> vars;
protected
  InstNode node;
  ComponentRef cref;
algorithm
  () := match exp
    case Expression.CREF()
      guard ComponentRef.isCref(exp.cref) and
            not ComponentRef.isIterator(exp.cref) and
            InstNode.isComponent(ComponentRef.node(exp.cref))
      algorithm
        cref := ComponentRef.stripSubscriptsAll(exp.cref);
        UnorderedMap.tryAdd(cref, info, vars);
      then
        ();

    else ();
  end match;
end collectParallelVariablesExp;

function checkParGlobalCref
  input tuple<ComponentRef, SourceInfo> crefInfo;
protected
  ComponentRef cref;
  SourceInfo info;
  InstNode node;
  String errorString;
algorithm
  (cref, info) := crefInfo;
  node := ComponentRef.node(cref);

  if Component.parallelism(InstNode.component(node)) <> Parallelism.GLOBAL then
    errorString := "\n" +
    "- Component '" + AbsynUtil.pathString(ComponentRef.toPath(cref)) +
    "' is used in a parallel for loop." + "\n" +
    "- Parallel for loops can only contain references to parglobal variables"
    ;
    Error.addSourceMessage(Error.PARMODELICA_ERROR,
      {errorString}, info);
    fail();
  end if;
end checkParGlobalCref;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
