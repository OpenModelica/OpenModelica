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
import Attributes = NFAttributes;
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
import StringUtil;
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
import NFPrefixes.{ConnectorType, Direction, Variability, Visibility, Purity, Parallelism};
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

  function mapExp
    "maps the expressions of all functions in the tree"
    input output Tree tree;
    input MapFunc func;
    partial function MapFunc
      input output NFExpression exp;
    end MapFunc;
    function mapBody
      input Key key;
      input output Value val;
      input MapFunc func;
    algorithm
      val := Function.mapExp(val, func);
    end mapBody;
  algorithm
    tree := map(tree, function mapBody(func = func));
  end mapExp;

  redeclare function addConflictDefault = addConflictKeep;
end FunctionTreeImpl;

uniontype FlattenSettings
  record SETTINGS
    Boolean scalarize;
    Boolean arrayConnect;
    Boolean nfAPI;
    Boolean relaxedErrorChecking;
    Boolean newBackend;
    Boolean vectorizeBindings;
    Boolean implicitStartAttribute;
    Boolean minimalEval;
  end SETTINGS;
end FlattenSettings;

uniontype Prefix
  record PREFIX
    InstNode root;
    ComponentRef prefix;
  end PREFIX;

  record INDEXED_PREFIX
    InstNode root;
    ComponentRef prefix;
    ComponentRef indexedPrefix;
  end INDEXED_PREFIX;

  function new
    input InstNode root;
    input Boolean indexed = false;
    output Prefix prefix;
  algorithm
    prefix := if indexed then
      INDEXED_PREFIX(root, ComponentRef.EMPTY(), ComponentRef.EMPTY()) else
      PREFIX(root, ComponentRef.EMPTY());
  end new;

  function isEmpty
    input Prefix prefix;
    output Boolean empty;
  algorithm
    empty := match prefix
      case PREFIX() then ComponentRef.isEmpty(prefix.prefix);
      case INDEXED_PREFIX() then ComponentRef.isEmpty(prefix.indexedPrefix);
    end match;
  end isEmpty;

  function isIndexed
    input Prefix prefix;
    output Boolean indexed;
  algorithm
    indexed := match prefix
      case INDEXED_PREFIX() then true;
      else false;
    end match;
  end isIndexed;

  function push
    input InstNode node;
    input Type ty;
    input list<Dimension> dims;
    input output Prefix prefix;
  algorithm
    () := match prefix
      case PREFIX()
        algorithm
          prefix.prefix := ComponentRef.prefixCref(node, ty, {}, prefix.prefix);
        then
          ();

      case INDEXED_PREFIX()
        algorithm
          prefix.prefix := ComponentRef.prefixCref(node, ty, {}, prefix.prefix);
          prefix.indexedPrefix := ComponentRef.prefixCref(node, ty, {}, prefix.indexedPrefix);
          prefix.indexedPrefix := ComponentRef.setSubscripts(makeBindingIterators(prefix.indexedPrefix, dims),
            prefix.indexedPrefix);
        then
          ();
    end match;
  end push;

  function pop
    input output Prefix prefix;
  algorithm
    () := match prefix
      case PREFIX()
        algorithm
          prefix.prefix := ComponentRef.rest(prefix.prefix);
        then
          ();

      case INDEXED_PREFIX()
        algorithm
          prefix.prefix := ComponentRef.rest(prefix.prefix);
          prefix.indexedPrefix := ComponentRef.rest(prefix.indexedPrefix);
        then
          ();
    end match;
  end pop;

  function prefix
    input Prefix prefix;
    output ComponentRef cref;
  algorithm
    cref := match prefix
      case PREFIX() then prefix.prefix;
      case INDEXED_PREFIX() then prefix.prefix;
    end match;
  end prefix;

  function indexedPrefix
    input Prefix prefix;
    output ComponentRef cref;
  algorithm
    cref := match prefix
      case PREFIX() then prefix.prefix;
      case INDEXED_PREFIX() then prefix.indexedPrefix;
    end match;
  end indexedPrefix;

  function toNonIndexedPrefix
    input output Prefix prefix;
  algorithm
    prefix := match prefix
      case PREFIX() then prefix;
      case INDEXED_PREFIX() then PREFIX(prefix.root, prefix.prefix);
    end match;
  end toNonIndexedPrefix;

  function apply
    input Prefix prefix;
    input output ComponentRef cref;
  algorithm
    cref := ComponentRef.transferSubscripts(indexedPrefix(prefix), cref);
  end apply;

  function subscript
    input list<Subscript> subs;
    input output Prefix prefix;
  algorithm
    () := match prefix
      case PREFIX()
        algorithm
          prefix.prefix := ComponentRef.setSubscripts(subs, prefix.prefix);
        then
          ();

      case INDEXED_PREFIX()
        algorithm
          prefix.prefix := ComponentRef.setSubscripts(subs, prefix.prefix);
        then
          ();
    end match;
  end subscript;

  function toString
    input Prefix pre;
    output String str = ComponentRef.toString(prefix(pre));
  end toString;

  function rootNode
    input Prefix pre;
    output InstNode node;
  algorithm
    node := match pre
      case PREFIX() then pre.root;
      case INDEXED_PREFIX() then pre.root;
    end match;
  end rootNode;

  function instanceName
    input Prefix pre;
    output String str;
  algorithm
    str := InstNode.name(rootNode(pre));

    if not ComponentRef.isEmpty(indexedPrefix(pre)) then
      str := str + "." + toString(pre);
    end if;
  end instanceName;
end Prefix;

constant Prefix EMPTY_PREFIX = Prefix.PREFIX(InstNode.EMPTY_NODE(), ComponentRef.EMPTY());
constant Prefix EMPTY_INDEXED_PREFIX = Prefix.INDEXED_PREFIX(InstNode.EMPTY_NODE(), ComponentRef.EMPTY(), ComponentRef.EMPTY());

function flatten
  input InstNode classInst;
  input Absyn.Path classPath;
  input Boolean getConnectionResolved = true;
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
  Prefix prefix;
algorithm
  settings := FlattenSettings.SETTINGS(
    Flags.isSet(Flags.NF_SCALARIZE),
    Flags.isSet(Flags.ARRAY_CONNECT),
    Flags.isSet(Flags.NF_API),
    Flags.isSet(Flags.NF_API) or Flags.getConfigBool(Flags.CHECK_MODEL),
    Flags.getConfigBool(Flags.NEW_BACKEND),
    Flags.isSet(Flags.VECTORIZE_BINDINGS),
    Flags.isConfigFlagSet(Flags.ALLOW_NON_STANDARD_MODELICA, "implicitParameterStartAttribute"),
    Flags.getConfigString(Flags.EVALUATE_STRUCTURAL_PARAMETERS) <> "all"
  );

  prefix := Prefix.new(classInst, indexed = settings.vectorizeBindings);

  sections := Sections.EMPTY();
  src := ElementSource.createElementSource(InstNode.info(classInst));
  src := ElementSource.addCommentToSource(src,
    SCodeUtil.getElementComment(InstNode.definition(classInst)));

  deleted_vars := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);

  (vars, sections) := flattenClass(InstNode.getClass(classInst), prefix,
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
        FlatModel.FLAT_MODEL(classPath, vars, eql, ieql, alg, ialg, src);

      else FlatModel.FLAT_MODEL(classPath, vars, {}, {}, {}, {}, src);
  end match;

  // get inputs and outputs for algorithms now that types are computed
  flatModel.algorithms := list(Algorithm.setInputsOutputs(al) for al in flatModel.algorithms);
  flatModel.initialAlgorithms := list(Algorithm.setInputsOutputs(al) for al in flatModel.initialAlgorithms);

  execStat(getInstanceName());
  InstUtil.dumpFlatModelDebug("flatten", flatModel);

  if getConnectionResolved then
    if settings.arrayConnect then
      flatModel := resolveArrayConnections(flatModel);
    else
      flatModel := resolveConnections(flatModel, deleted_vars, settings);
    end if;
    InstUtil.dumpFlatModelDebug("connections", flatModel);
  end if;

  flatModel.variables := list(updateVariability(var) for var in flatModel.variables);
end flatten;

function flattenConnection
  input InstNode classInst;
  input Absyn.Path classPath;
  output Connections conns;
protected
  FlatModel flatModel;
  UnorderedSet<ComponentRef> deleted_vars;
algorithm
  flatModel := flatten(classInst, classPath, false);
  deleted_vars := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);

  // get the connections from the model
  (flatModel, conns) := Connections.collectConnections(flatModel, function isDeletedConnector(deletedVars = deleted_vars));
  // Elaborate expandable connectors.
  (_, conns) := ExpandableConnectors.elaborate(flatModel, conns);
  conns := Connections.collectFlows(flatModel, conns);
end flattenConnection;

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

function fillVectorizedVariableBinding
  input output Variable var;
protected
  list<tuple<String, Binding>> ty_attrs = {};
  String attr_name;
  Binding attr_binding;
algorithm
  var.binding := fillVectorizedBinding(var.binding, var.ty);

  for ty_attr in var.typeAttributes loop
    (attr_name, attr_binding) := ty_attr;
    attr_binding := fillVectorizedBinding(attr_binding,
      Type.copyDims(var.ty, Binding.getType(attr_binding)));
    ty_attrs := (attr_name, attr_binding) :: ty_attrs;
  end for;

  var.typeAttributes := listReverseInPlace(ty_attrs);
end fillVectorizedVariableBinding;

protected
function flattenClass
  input Class cls;
  input Prefix prefix;
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
    case Class.INSTANCED_CLASS(restriction = Restriction.TYPE()) then ();

    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      algorithm
        if isSome(binding) then
          SOME(b) := binding;

          if Binding.isBound(b) then
            b := flattenBinding(b, Prefix.pop(prefix));
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

        sections := flattenSections(cls.sections, Prefix.toNonIndexedPrefix(prefix), sections, settings);
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
        Error.assertion(false, getInstanceName() + " got non-instantiated component " + Prefix.toString(prefix) + "\n", sourceInfo());
      then
        ();

  end match;
end flattenClass;

function flattenComponent
  input InstNode component;
  input Prefix prefix;
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
    case Component.COMPONENT(condition = condition, ty = ty)
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

          case ComponentType.RECORD
            algorithm
              (children, sections) := flattenComplexComponent(comp_node, c, cls, ty,
                vis, outerBinding, prefix, {}, sections, deletedVars, settings);
            then flattenSimpleComponent(comp_node, c, vis, outerBinding,
              Class.getTypeAttributes(cls), prefix, vars, sections, settings, listReverse(children));

          else
            algorithm
              Error.assertion(false, getInstanceName() + " got unknown component", sourceInfo());
            then
              fail();
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
  input Prefix prefix;
  output Boolean isDeleted;
protected
  Expression exp;
  Binding cond;
algorithm
  if Binding.isBound(condition) then
    cond := flattenBinding(condition, prefix);
    exp := Binding.getTypedExp(cond);
    exp := Ceval.evalExp(exp, Ceval.EvalTarget.new(Binding.getInfo(cond), NFInstContext.CONDITION));
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
  input Prefix prefix;
  input UnorderedSet<ComponentRef> deletedVars;
protected
  ComponentRef cref;
algorithm
  cref := ComponentRef.prefixCref(node, Type.UNKNOWN(), {}, Prefix.prefix(prefix));
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
  input Prefix prefix;
  input output list<Variable> vars;
  input output Sections sections;
  input FlattenSettings settings;
  input list<Variable> children;
protected
  InstNode comp_node = node;
  ComponentRef name;
  Binding binding;
  Type ty;
  SCode.Comment cmt;
  SourceInfo info;
  Attributes comp_attr;
  Visibility vis;
  Equation eq;
  list<tuple<String, Binding>> ty_attrs;
  Variability var;
  Boolean unfix;
  Prefix pre;
  Variable v;
  Boolean fillVectorizedBindingFails = false;
algorithm
  Component.COMPONENT(ty = ty, binding = binding, attributes = comp_attr, comment = cmt, info = info) := comp;
  checkUnspecifiedEnumType(ty, node, info);
  var := comp_attr.variability;

  if isSome(outerBinding) then
    SOME(binding) := outerBinding;
    unfix := Binding.isUnbound(binding) and var == Variability.PARAMETER;
  else
    binding := flattenBinding(binding, prefix);
    unfix := false;
  end if;

  // If the component is vectorized and the binding uses variables of the component,
  // move the binding into an equation as fillVectorizedBinding is insufficient.
  if not settings.scalarize and not settings.vectorizeBindings and Binding.isBound(binding)
     and not Prefix.isEmpty(prefix) and Type.isArray(ComponentRef.nodeType(Prefix.prefix(prefix)))  then
    fillVectorizedBindingFails := containsPrefix(Binding.getExp(binding), prefix);
  end if;

  // If the component is an array component with a binding and at least discrete
  // variability, and scalarization is enabled, move the binding into an equation.
  // This avoids having to scalarize the binding.
  if not settings.nfAPI and settings.scalarize or fillVectorizedBindingFails then
    if var >= Variability.DISCRETE and Type.isArray(ty) and
       not Type.isExternalObject(Type.arrayElementType(ty)) and Binding.isBound(binding)
       or fillVectorizedBindingFails then
      name := ComponentRef.prefixCref(comp_node, ty, {}, Prefix.prefix(prefix));
      eq := Equation.ARRAY_EQUALITY(Expression.CREF(ty, name), Binding.getTypedExp(binding), ty,
        InstNode.EMPTY_NODE(), ElementSource.createElementSource(info));
      sections := Sections.prependEquation(eq, sections);
      binding := NFBinding.EMPTY_BINDING;

      // Moving the binding of an input variable to an equation can change how
      // the variable is counted when counting variables and equations, but
      // since there's no way to override such a binding from outside the model
      // we can remove the input prefix to keep the balance.
      if comp_attr.direction == Direction.INPUT and Prefix.isEmpty(prefix) then
        comp_attr.direction := Direction.NONE;
        Error.addSourceMessage(Error.TOP_LEVEL_INPUT_WITH_BINDING,
          {ComponentRef.toString(name)}, info);
      end if;
    end if;
  end if;

  ty := flattenType(ty, prefix, info);
  verifyDimensions(Type.arrayDims(ty), comp_node);
  pre := Prefix.push(comp_node, ty, Type.arrayDims(ty), prefix);
  ty_attrs := list(flattenTypeAttribute(m, prefix) for m in typeAttrs);

  // Set fixed = false for parameters that are part of a record instance whose
  // binding couldn't be split and was moved to an initial equation.
  if unfix then
    ty_attrs := Binding.setAttr(ty_attrs, "fixed",
      Binding.makeFlat(Expression.BOOLEAN(false), Variability.CONSTANT, NFBinding.Source.GENERATED));
  end if;

  // kabdelhak: add dummy backend info, will be changed to actual value in
  // conversion to backend process. NBackendDAE.lower
  name := Prefix.prefix(pre);
  v := Variable.VARIABLE(name, ty, binding, visibility, comp_attr, ty_attrs, children, cmt, info, NFBackendExtension.DUMMY_BACKEND_INFO);

  if not settings.relaxedErrorChecking and var < Variability.DISCRETE and
     not unfix and not Type.isComplex(Type.arrayElementType(ty)) then
    // Check that the component has a binding if it's required to have one.
    v := verifyBinding(v, var, binding, settings);
  end if;

  vars := v :: vars;
end flattenSimpleComponent;

function checkUnspecifiedEnumType
  input Type ty;
  input InstNode node;
  input SourceInfo info;
algorithm
  () := match ty
    case Type.ENUMERATION(literals = {})
      algorithm
        Error.addSourceMessage(Error.UNSPECIFIED_ENUM_COMPONENT, {InstNode.name(node)}, info);
      then
        fail();

    else ();
  end match;
end checkUnspecifiedEnumType;

function flattenTypeAttribute
  input Modifier attr;
  input Prefix prefix;
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

function verifyBinding
  input output Variable var;
  input Variability variability;
  input Binding binding;
  input FlattenSettings settings;
protected
  Binding fixed_binding, start_binding;
  Option<Expression> fixed_exp_opt;
  Expression fixed_exp, start_exp;
  Boolean fixed;
  Option<Expression> min_exp_opt, max_exp_opt;

  function eval_binding
    input Binding binding;
    output Option<Expression> result;
  algorithm
    if Binding.isBound(binding) then
      result := SOME(Ceval.tryEvalExp(Binding.getExp(binding)));
    else
      result := NONE();
    end if;
  end eval_binding;
algorithm
  if variability > Variability.CONSTANT and Binding.isBound(binding) then
    // Parameter with a binding is ok.
    return;
  end if;

  // Check if the variable is fixed or not.
  fixed_binding := Variable.lookupTypeAttribute("fixed", var);
  fixed_exp_opt := eval_binding(fixed_binding);

  if isSome(fixed_exp_opt) then
    SOME(fixed_exp) := fixed_exp_opt;

    if not Expression.isBoolean(fixed_exp) then
      return;
    end if;

    fixed := Expression.isTrue(fixed_exp);
  else
    fixed := true;
  end if;

  if variability == Variability.CONSTANT then
    if not fixed then
      // Constants are not allowed to be non-fixed.
      Error.addSourceMessage(Error.NON_FIXED_CONSTANT,
        {ComponentRef.toString(var.name)}, var.info);

      if not settings.relaxedErrorChecking then
        fail();
      end if;
    end if;

    // Constants must have binding equations.
    if Binding.isUnbound(binding) then
      Error.addSourceMessage(Error.NO_CONSTANT_BINDING, {ComponentRef.toString(var.name)}, var.info);
      fail();
    end if;
  else
    if fixed and Binding.isUnbound(binding) then
      start_binding := Variable.lookupTypeAttribute("start", var);

      if Binding.isUnbound(start_binding) then
        // Fixed parameters must have a binding equation or a start attribute.
        Error.addSourceMessage(Error.UNBOUND_PARAMETER_ERROR,
          {ComponentRef.toString(var.name)}, var.info);

        if settings.implicitStartAttribute then
          // Create a start attribute if it's missing and
          // --allowNonStandardModelica=implicitParameterStartAttribute is used
          min_exp_opt := eval_binding(Variable.lookupTypeAttribute("min", var));
          max_exp_opt := eval_binding(Variable.lookupTypeAttribute("max", var));
          start_exp := Expression.makeDefaultValue(var.ty, min_exp_opt, max_exp_opt);
          var.binding := Binding.makeFlat(start_exp, Expression.variability(start_exp),
            NFBinding.Source.GENERATED);
        elseif not settings.relaxedErrorChecking then
          fail();
        end if;
      else
        Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING,
          {ComponentRef.toString(var.name), Binding.toString(start_binding)}, var.info);
      end if;
    end if;
  end if;
end verifyBinding;

function getRecordBindings
  input Binding binding;
  input array<InstNode> comps;
  input Prefix prefix;
  output list<Binding> recordBindings = {};
protected
  Expression binding_exp;
  Variability var;
  Binding.Source bind_src;
algorithm
  binding_exp := Binding.getTypedExp(binding);
  var := Binding.variability(binding);
  bind_src := NFBinding.Source.GENERATED;

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

    case Expression.ARRAY()
      guard Type.isRecord(Type.arrayElementType(Expression.typeOf(binding_exp)))
      then list(Binding.makeFlat(Expression.nthRecordElement(i, binding_exp), var, bind_src)
                  for i in 1:arrayLength(comps));

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-record binding " +
          Expression.toString(binding_exp), sourceInfo());
      then
        fail();
  end match;

  Error.assertion(listLength(recordBindings) == arrayLength(comps),
    getInstanceName() + " got record binding with wrong number of elements for " + Prefix.toString(prefix),
    sourceInfo());
end getRecordBindings;

function flattenComplexComponent
  input InstNode node;
  input Component comp;
  input Class cls;
  input Type nodeTy;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input Prefix prefix;
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
  Variability comp_var, binding_var;
  Type ty;
  Prefix pre;
  SourceInfo info;
algorithm
  info := InstNode.info(node);
  ty := flattenType(nodeTy, prefix, info);
  dims := Type.arrayDims(ty);
  binding := if isSome(outerBinding) then Util.getOption(outerBinding) else Component.getBinding(comp);

  // For a complex component with a binding the binding needs to be split into
  // a binding for each record field, or moved to an initial equation if
  // splitting the binding fails.
  if Binding.isExplicitlyBound(binding) then
    binding := flattenBinding(binding, prefix);
    binding_exp := Binding.getTypedExp(binding);
    binding_var := Binding.variability(binding);

    comp_var := Component.variability(comp);
    if comp_var <= Variability.STRUCTURAL_PARAMETER or binding_var <= Variability.STRUCTURAL_PARAMETER then
      // Constant evaluate parameters that are structural/constant.
      binding_exp := Ceval.evalExp(binding_exp);
      binding_exp := flattenExp(binding_exp, prefix, Binding.getInfo(binding));
    elseif binding_var == Variability.PARAMETER and Component.isFinal(comp) then
      // Try to use inlining first.
      try
        binding_exp := Inline.inlineCallExp(binding_exp, forceInline = true);
      else
      end try;

      // If inlining fails, try to evaluate the binding instead.
      if not (Expression.isRecord(binding_exp) or Expression.isCref(binding_exp)) then
        try
          binding_exp_eval := Ceval.tryEvalExp(binding_exp);
          binding_exp_eval := flattenExp(binding_exp_eval, prefix, Binding.getInfo(binding));

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
      // Skip adding the equation when using the new backend, since this only
      // occurs when flattening the children of a record instance and will
      // conflict with the binding on the actual record instance.
      if not settings.newBackend then
        name := ComponentRef.prefixCref(node, ty, {}, Prefix.prefix(prefix));
        eq := Equation.EQUALITY(Expression.CREF(ty, name),  binding_exp, ty,
          InstNode.EMPTY_NODE(), ElementSource.createElementSource(info));
        sections := Sections.prependEquation(eq, sections, isInitial = comp_var <= Variability.PARAMETER);
      end if;
      opt_binding := SOME(NFBinding.EMPTY_BINDING);
    else
      binding := Binding.setTypedExp(binding_exp, binding);
      opt_binding := SOME(binding);
    end if;
  else
    opt_binding := NONE();
  end if;

  pre := Prefix.push(node, ty, dims, prefix);

  // Flatten the class directly if the component is a scalar, otherwise scalarize it.
  if listEmpty(dims) then
    (vars, sections) := flattenClass(cls, pre, visibility, opt_binding, vars, sections, deletedVars, settings);
  elseif settings.scalarize then
    dims := list(flattenDimension(d, pre, info) for d in dims);
    verifyDimensions(dims, node);
    (vars, sections) := flattenArray(cls, dims, pre, visibility, opt_binding, vars, sections, {}, deletedVars, info, settings);
  else
    (vars, sections) := vectorizeArray(cls, ty, dims, pre, visibility, opt_binding, vars, sections, {}, deletedVars, settings);
  end if;
end flattenComplexComponent;

function splitRecordCref
  input Expression exp;
  output Expression outExp;
protected
  InstNode cls;
  array<InstNode> comps;
  ComponentRef cr, field_cr;
  Type ty;
  list<Expression> fields;
  Expression cond;
algorithm
  outExp := ExpandExp.expand(exp);

  outExp := match outExp
    case Expression.CREF(ty = Type.COMPLEX(cls = cls), cref = cr)
      algorithm
        comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(cls)));
        fields := {};

        for i in arrayLength(comps):-1:1 loop
          ty := InstNode.getType(comps[i]);
          field_cr := ComponentRef.prefixCref(comps[i], ty, {}, cr);
          field_cr := flattenCref(field_cr, Prefix.PREFIX(InstNode.EMPTY_NODE(), cr), AbsynUtil.dummyInfo);
          fields := Expression.fromCref(field_cr) :: fields;
        end for;
      then
        Expression.makeRecord(InstNode.scopePath(cls), outExp.ty, fields);

    case Expression.ARRAY()
      algorithm
        outExp.elements := Array.map(outExp.elements, splitRecordCref);
      then
        outExp;

    case Expression.IF()
      guard Expression.variability(outExp.condition) <= Variability.PARAMETER
      algorithm
        cond := Ceval.tryEvalExp(outExp.condition);

        // Only mark the condition as structural if it could be evaluated.
        if not referenceEq(cond, outExp.condition) then
          Structural.markExp(outExp.condition);
        end if;
      then
        match cond
          case Expression.BOOLEAN() then splitRecordCref(if cond.value then outExp.trueBranch else outExp.falseBranch);
          else outExp;
        end match;

    else exp;
  end match;
end splitRecordCref;

function flattenArray
  input Class cls;
  input list<Dimension> dimensions;
  input Prefix prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
  input output Sections sections;
  input list<Subscript> subscripts = {};
  input UnorderedSet<ComponentRef> deletedVars;
  input SourceInfo info;
  input FlattenSettings settings;
protected
  Dimension dim;
  list<Dimension> rest_dims;
  Prefix sub_pre;
  RangeIterator range_iter;
  Expression sub_exp;
  list<Subscript> subs;
algorithm
  if listEmpty(dimensions) then
    subs := listReverse(subscripts);
    sub_pre := Prefix.subscript(subs, prefix);

    (vars, sections) := flattenClass(cls, sub_pre, visibility,
      subscriptBindingOpt(subs, binding), vars, sections, deletedVars, settings);
  else
    dim :: rest_dims := dimensions;
    dim := flattenDimension(dim, prefix, info);
    range_iter := RangeIterator.fromDim(dim, false);

    while RangeIterator.hasNext(range_iter) loop
      (range_iter, sub_exp) := RangeIterator.next(range_iter);
      (vars, sections) := flattenArray(cls, rest_dims, prefix, visibility,
          binding, vars, sections, Subscript.INDEX(sub_exp) :: subscripts, deletedVars, info, settings);
    end while;
  end if;
end flattenArray;

function vectorizeArray
  input Class cls;
  input Type cls_ty;
  input list<Dimension> dimensions;
  input Prefix prefix;
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
  list<Equation> eq, ieq;
  list<Algorithm> alg, ialg;
  ComponentRef indexed_prefix;
algorithm
  // Skip the array if any dimension is zero.
  if List.any(dimensions, Dimension.isZero) then
    return;
  end if;

  // if we don't scalarize flatten the class and vectorize it
  (vrs, sects) := flattenClass(cls, prefix, visibility, binding, {}, Sections.SECTIONS({}, {}, {}, {}), deletedVars, settings);

  for v in listReverse(vrs) loop
    // kabdelhak: this would only add 1 layer of dimensions. for nested records it needs to go deeper
    // handling it in Variable.expandChildren instead for the new backend
    if not (settings.newBackend and Type.isRecord(Type.arrayElementType(cls_ty))) then
      v.ty := Type.liftArrayLeftList(v.ty, dimensions);
    end if;
    vars := v :: vars;
  end for;

  // vectorize equations
  () := match sects
    case Sections.SECTIONS()
      algorithm
        eq := vectorizeEquations(sects.equations, dimensions, prefix, settings);
        ieq := vectorizeEquations(sects.initialEquations, dimensions, prefix, settings);
        alg := vectorizeAlgorithms(sects.algorithms, dimensions, prefix);
        ialg := vectorizeAlgorithms(sects.initialAlgorithms, dimensions, prefix);
        sections := Sections.prepend(eq, ieq, alg, ialg, sections);
      then ();
  end match;
end vectorizeArray;

function makeBindingIterators
  input ComponentRef prefix;
  input list<Dimension> dimensions;
  output list<Subscript> subs = {};
protected
  Integer index = 0;
  ComponentRef iter;
  String name;
algorithm
  name := "$" + InstNode.name(ComponentRef.node(prefix));

  for d in dimensions loop
    index := index + 1;
    iter := ComponentRef.makeIterator(InstNode.newIterator(name + String(index),
      Type.INTEGER(), AbsynUtil.dummyInfo));
    subs := Subscript.makeIndex(Expression.fromCref(iter)) :: subs;
  end for;

  subs := listReverseInPlace(subs);
end makeBindingIterators;

function vectorizeBinding
  input output Binding binding;
  input Prefix prefix;
protected
  list<Subscript> subs;
  list<InstNode> nodes;
  list<Dimension> dims;
  Expression exp;
  Call array_call;
  Type binding_ty;
  list<tuple<InstNode, Expression>> iters;
  ComponentRef prefix_cr;
algorithm
  if not Binding.isBound(binding) then
    return;
  end if;

  prefix_cr := Prefix.indexedPrefix(prefix);
  subs := list(s for s guard Subscript.isIterator(s) in ComponentRef.subscriptsAllFlat(prefix_cr));

  if listEmpty(subs) then
    return;
  end if;

  exp := Binding.getExp(binding);
  binding_ty := Binding.getType(binding);

  // When replacing split indices we often get expressions such as
  // {"m" for $i1 in 1:3}[$x1]. If the subscripts are the same as the subscripts
  // in the prefix we can just remove all the subscripts and be done.
  () := match exp
    case Expression.SUBSCRIPTED_EXP()
      guard Subscript.isEqualList(exp.subscripts, subs)
      algorithm
        binding := Binding.makeFlat(exp.exp, Binding.variability(binding), Binding.source(binding));
        return;
      then
        ();

    else ();
  end match;

  nodes := ComponentRef.nodes(prefix_cr);
  dims := List.flatten(list(Type.arrayDims(InstNode.getType(n)) for n in nodes));
  dims := List.lastN(dims, listLength(subs));
  binding_ty := Type.liftArrayLeftList(binding_ty, dims);

  if not listEmpty(dims) then
    if Expression.isLiteral(exp) or not Expression.contains(exp, Expression.isIterator) then
      array_call := Call.makeTypedCall(NFBuiltinFuncs.FILL_FUNC,
        exp :: list(Dimension.sizeExp(d) for d in dims),
        Binding.variability(binding), Purity.PURE, binding_ty);
    else
      iters := listReverse((Subscript.toIterator(s), Dimension.toRange(d)) threaded for s in subs, d in dims);

      array_call := Call.TYPED_ARRAY_CONSTRUCTOR(binding_ty,
        Expression.variability(exp), Expression.purity(exp), exp, iters);
    end if;

    exp := Expression.CALL(array_call);
  end if;

  binding := Binding.makeFlat(exp, Binding.variability(binding), Binding.source(binding));
end vectorizeBinding;

function fillVectorizedBinding
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
end fillVectorizedBinding;

function vectorizeEquations
  input list<Equation> eql;
  input list<Dimension> dimensions;
  input Prefix prefix;
  input FlattenSettings settings;
  output list<Equation> equations = {};
algorithm
  for eq in eql loop
    equations := vectorizeEquation(eq, dimensions, prefix, settings, equations);
  end for;

  equations := listReverseInPlace(equations);
end vectorizeEquations;

function vectorizeEquation
  input Equation eqn;
  input list<Dimension> dimensions;
  input Prefix prefix;
  input FlattenSettings settings;
  input output list<Equation> equations;
protected
  list<Equation> eql;
algorithm
  // Flatten with an empty prefix to get rid of any split indices.
  eql := flattenEquation(eqn, EMPTY_PREFIX, {}, settings);

  for eq in eql loop
    equations := match eq
      local
        Type ty;
        InstNode iter, scope;
        list<InstNode> iters;
        Expression lhs, rhs, range;
        list<Expression> ranges;
        list<Subscript> subs;
        DAE.ElementSource src;

      // convert simple equality of crefs to array equality
      // kabdelhak: only do it if all subscripts are simple enough
      //            will lead to complicated code if not index or whole dim
      //            and we are better off just using for loops for these
      case Equation.EQUALITY(lhs = lhs as Expression.CREF(), rhs = rhs as Expression.CREF())
        guard(not Flags.getConfigBool(Flags.NEW_BACKEND)
          or (List.all(ComponentRef.subscriptsAllWithWholeFlat(lhs.cref), Subscript.isSimple)
          and List.all(ComponentRef.subscriptsAllWithWholeFlat(rhs.cref), Subscript.isSimple)))
        algorithm
          ty := Type.liftArrayLeftList(eq.ty, dimensions);
          lhs := Expression.CREF(ty, lhs.cref);
          rhs := Expression.CREF(ty, rhs.cref);
        then Equation.ARRAY_EQUALITY(lhs, rhs, ty, eq.scope, eq.source) :: equations;

      // Pass Connections.* operators as they are and let the connection
      // handling deal with them.
      case Equation.NORETCALL(exp = lhs as Expression.CALL())
        guard Call.isConnectionsOperator(lhs.call)
        then eq :: equations;

      // wrap general equation into for loop
      else
        algorithm
          (iters, ranges, subs) := makeIterators(Prefix.prefix(prefix), dimensions);
          subs := listReverseInPlace(subs);
          eq := Equation.mapExp(eq, function addIterator(prefix = prefix, subscripts = subs));
          scope := Equation.scope(eqn);
          src := Equation.source(eqn);

          iter :: iters := iters;
          range :: ranges := ranges;
          eq := Equation.FOR(iter, SOME(range), {eq}, scope, src);

          while not listEmpty(iters) loop
            iter :: iters := iters;
            range :: ranges := ranges;
            eq := Equation.FOR(iter, SOME(range), {eq}, scope, src);
          end while;
        then
          splitForLoop(eq, EMPTY_PREFIX, equations, settings);

    end match;
  end for;
end vectorizeEquation;

function vectorizeAlgorithms
  input list<Algorithm> algs;
  input list<Dimension> dimensions;
  input Prefix prefix;
  output list<Algorithm> algorithms = {};
algorithm
  for alg in algs loop
    algorithms := vectorizeAlgorithm(alg, dimensions, prefix) :: algorithms;
  end for;

  algorithms := listReverseInPlace(algorithms);
end vectorizeAlgorithms;

function vectorizeAlgorithm
  input output Algorithm alg;
  input list<Dimension> dimensions;
  input Prefix prefix;
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
        (iters, ranges, subs) := makeIterators(Prefix.prefix(prefix), dimensions);
        subs := listReverseInPlace(subs);
        body := Statement.mapExpList(alg.statements, function addIterator(prefix = prefix, subscripts = subs));

        while not listEmpty(iters) loop
          iter :: iters := iters;
          range :: ranges := ranges;
          body := {Statement.FOR(iter, SOME(range), body, Statement.ForType.NORMAL(), alg.source)};
        end while;
      then
        Algorithm.ALGORITHM(body, alg.inputs, alg.outputs, alg.scope, alg.source); // ToDo: update inputs, outputs?
  end match;
end vectorizeAlgorithm;

public function makeIterators
  input ComponentRef prefix;
  input list<Dimension> dimensions;
  output list<InstNode> iterators = {};
  output list<Expression> ranges = {};
  output list<Subscript> subscripts = {};
protected
  Component iter_comp;
  InstNode prefix_node, iter;
  Expression range;
  Subscript sub;
algorithm
  prefix_node := ComponentRef.node(prefix);

  for dim in dimensions loop
    iter := InstNode.newUniqueIterator(InstNode.info(prefix_node));
    iterators := iter :: iterators;

    range := Expression.makeRange(Expression.INTEGER(1), NONE(), Dimension.sizeExp(dim));
    ranges := range :: ranges;

    sub := Subscript.INDEX(Expression.CREF(Type.INTEGER(), ComponentRef.makeIterator(iter, Type.INTEGER())));
    subscripts := sub :: subscripts;
  end for;
end makeIterators;

protected
function addIterator
  input output Expression exp;
  input Prefix prefix;
  input list<Subscript> subscripts;
algorithm
  exp := Expression.map(exp, function addIterator_traverse(prefix = prefix, subscripts = subscripts));
end addIterator;

function addIterator_traverse
  input output Expression exp;
  input Prefix prefix;
  input list<Subscript> subscripts;
protected
  ComponentRef ref = Prefix.prefix(prefix);
  String restString, prefixString = ComponentRef.toString(ref);
algorithm
  exp := match exp
    local
      ComponentRef restCref;
    case Expression.CREF(cref = ComponentRef.CREF(restCref = restCref))
      algorithm
        restString := ComponentRef.toString(restCref);
        if StringUtil.startsWith(restString, prefixString) then
          exp.cref := mergeIterator(exp.cref, ref, subscripts);
        end if;
      then
        exp;
    else exp;
  end match;
end addIterator_traverse;

function mergeIterator
  input output ComponentRef cref;
  input ComponentRef ref;
  input list<Subscript> subscripts;
algorithm
  cref := match cref
    case ComponentRef.CREF() algorithm
      if ComponentRef.isEqual(cref, ref) then
        cref.subscripts := listAppend(cref.subscripts, subscripts);
      else
        cref.restCref := mergeIterator(cref.restCref, ref, subscripts);
      end if;
    then cref;
    else cref;
  end match;
end mergeIterator;

function containsPrefix
  input Expression exp;
  input Prefix prefix;
  output Boolean contains;
algorithm
  contains := Expression.fold(exp, function containsPrefix_traverse(prefix = prefix), false);
end containsPrefix;

function containsPrefix_traverse
  input Expression exp;
  input output Boolean contains;
  input Prefix prefix;
protected
  String restString, prefixString = ComponentRef.toString(Prefix.prefix(prefix));
algorithm
  () := match exp
    local
      ComponentRef restCref;
    case Expression.CREF(cref = ComponentRef.CREF(restCref = restCref))
      algorithm
        restString := ComponentRef.toString(restCref);
        if StringUtil.startsWith(restString, prefixString) then
          contains := true;
        end if;
      then
        ();
    else ();
  end match;
end containsPrefix_traverse;

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
  input Prefix prefix;
  input Boolean isTypeAttribute = false;
protected
  list<Subscript> subs, accum_subs;
  Integer binding_level;
  Expression bind_exp;
  list<InstNode> pars;
  InstNode par;
  SourceInfo info;
algorithm
  binding := match binding
    case Binding.UNBOUND() then binding;

    case Binding.TYPED_BINDING()
      algorithm
        if binding.isFlattened then
          return;
        end if;

        info := Binding.getInfo(binding);
        binding.bindingExp := flattenExp(binding.bindingExp, prefix, info);
        binding.bindingType := flattenType(binding.bindingType, prefix, info);
        binding.isFlattened := true;
      then
        if Prefix.isIndexed(prefix) then vectorizeBinding(binding, prefix) else binding;

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
  input Prefix prefix;
  input SourceInfo info;
algorithm
  exp := match exp
    case Expression.CREF(cref = ComponentRef.CREF())
      algorithm
        exp.cref := ComponentRef.mapExpShallow(exp.cref, function flattenExp(prefix = prefix, info = info));
        exp.cref := flattenCref(exp.cref, prefix, info);
        exp.ty := flattenType(exp.ty, prefix, info);
      then
        exp;

    case Expression.SUBSCRIPTED_EXP(split = true)
      then Expression.mapShallow(
        replaceSplitIndices(exp.exp, exp.subscripts, prefix, info),
        function flattenExp(prefix = prefix, info = info));

    case Expression.IF(ty = Type.CONDITIONAL_ARRAY())
      then flattenConditionalArrayIfExp(exp, prefix, info);

    case Expression.INSTANCE_NAME()
      then Expression.STRING(Prefix.instanceName(prefix));

    else Expression.mapShallow(exp, function flattenExp(prefix = prefix, info = info));
  end match;

  exp := flattenExpType(exp, prefix, info);
end flattenExp;

function replaceSplitIndices
  input output Expression exp;
  input list<Subscript> subscripts;
  input Prefix prefix;
  input SourceInfo info;
protected
  list<Subscript> subs = subscripts, cr_subs;
  Integer index;
  InstNode cr_node;
algorithm
  for cr in ComponentRef.toListReverse(Prefix.indexedPrefix(prefix)) loop
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
  exp := flattenExp(exp, prefix, info);
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
  input Prefix prefix;
  input SourceInfo info;
protected
  Type ty, ty2;
algorithm
  cref := Prefix.apply(prefix, cref);

  if ComponentRef.hasSplitSubscripts(cref) then
    cref := flattenCrefSplitSubscripts(cref, prefix);
  end if;

  cref := ComponentRef.mapTypes(cref, function flattenType(prefix = prefix, info = info));
end flattenCref;

function flattenCrefSplitSubscripts
  input output ComponentRef cref;
  input Prefix prefix;
protected
  type SubscriptList = list<Subscript>;
  UnorderedMap<InstNode, SubscriptList> sub_map;
algorithm
  sub_map := UnorderedMap.new<SubscriptList>(InstNode.hash, InstNode.refEqual);

  for cr in ComponentRef.toListReverse(Prefix.indexedPrefix(prefix)) loop
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
  input Prefix prefix;
  input SourceInfo info;
protected
  Type ty;
  Expression cond, tb, fb;
  Variability cond_var;
algorithm
  Expression.IF(ty = ty, condition = cond, trueBranch = tb, falseBranch = fb) := exp;
  cond := flattenExp(cond, prefix, info);
  cond_var := Expression.variability(cond);

  if Type.isConditionalArray(ty) then
    // An if-expression where the branches are array expression with different
    // dimensions, evaluate the condition and try to select one of the branches.
    Structural.markExp(cond);
    cond := Ceval.tryEvalExp(cond);

    exp := match cond
      case Expression.BOOLEAN()
        algorithm
          if not Type.isMatchedBranch(cond.value, ty) then
            // The branch with the incompatible dimensions was chosen, print an
            // error and fail.
            (tb, fb) := Util.swap(cond.value, fb, tb);
            Error.addSourceMessage(Error.ARRAY_DIMENSION_MISMATCH,
              {Expression.toString(tb), Type.toString(Expression.typeOf(tb)),
               Dimension.toStringList(Type.arrayDims(Expression.typeOf(fb)), brackets = false)}, info);
            fail();
          end if;
        then
          flattenExp(if cond.value then tb else fb, prefix, info);

      else
        algorithm
          // The condition couldn't be evaluated, print an error and fail.
          Error.addSourceMessage(Error.TYPE_MISMATCH_IF_EXP,
            {"", Expression.toString(tb), Type.toString(Expression.typeOf(tb)),
                 Expression.toString(fb), Type.toString(Expression.typeOf(fb))}, info);
        then
          fail();
    end match;
  elseif Expression.variability(cond) == Variability.PARAMETER then
    Structural.markExp(cond);
    tb := flattenExp(tb, prefix, info);
    fb := flattenExp(fb, prefix, info);
    ty := flattenType(ty, prefix, info);
    exp := Expression.IF(ty, cond, tb, fb);
  end if;
end flattenConditionalArrayIfExp;

function flattenExpType
  input output Expression exp;
  input Prefix prefix;
  input SourceInfo info;
protected
  Type ty;
algorithm
  ty := Expression.typeOf(exp);

  if Type.isArray(ty) then
    ty := flattenType(ty, prefix, info);
    exp := Expression.setType(ty, exp);
  end if;
end flattenExpType;

function flattenType
  input output Type ty;
  input Prefix prefix;
  input SourceInfo info;
algorithm
  ty := Type.mapDims(ty, function flattenDimension(prefix = prefix, info = info));
end flattenType;

function flattenDimension
  input output Dimension dim;
  input Prefix prefix;
  input SourceInfo info;
algorithm
  dim := match dim
    case Dimension.EXP()
      then Dimension.fromExp(flattenExp(dim.exp, prefix, info), dim.var);

    else dim;
  end match;
end flattenDimension;

function flattenSections
  input Sections sections;
  input Prefix prefix;
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
  input Prefix prefix;
  input FlattenSettings settings;
  output list<Equation> equations = {};
algorithm
  for eq in eql loop
    equations := flattenEquation(eq, prefix, equations, settings);
  end for;
end flattenEquations;

function flattenEquation
  input Equation eq;
  input Prefix prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
protected
  SourceInfo info = Equation.info(eq);
algorithm
  equations := match eq
    local
      Expression e1, e2, e3;
      Type ty;
      list<Equation> eql;

    case Equation.EQUALITY()
      algorithm
        e1 := flattenExp(eq.lhs, prefix, info);
        e2 := flattenExp(eq.rhs, prefix, info);
        ty := flattenType(eq.ty, prefix, info);
      then
        Equation.EQUALITY(e1, e2, ty, eq.scope, eq.source) :: equations;

    case Equation.FOR()
      algorithm
        if settings.scalarize then
          eql := unrollForLoop(eq, prefix, equations, settings);
        else
          eql := splitForLoop(eq, prefix, equations, settings);
        end if;
      then eql;

    case Equation.CONNECT()
      algorithm
        e1 := flattenExp(eq.lhs, prefix, info);
        e2 := flattenExp(eq.rhs, prefix, info);
      then
        Equation.CONNECT(e1, e2, eq.scope, eq.source) :: equations;

    case Equation.IF()
      then flattenIfEquation(eq, prefix, equations, settings);

    case Equation.WHEN()
      algorithm
        eq.branches := list(flattenEqBranch(b, prefix, info, settings) for b in eq.branches);
      then
        eq :: equations;

    case Equation.ASSERT()
      algorithm
        e1 := flattenExp(eq.condition, prefix, info);
        e2 := flattenExp(eq.message, prefix, info);
        e3 := flattenExp(eq.level, prefix, info);
      then
        Equation.ASSERT(e1, e2, e3, eq.scope, eq.source) :: equations;

    case Equation.TERMINATE()
      algorithm
        e1 := flattenExp(eq.message, prefix, info);
      then
        Equation.TERMINATE(e1, eq.scope, eq.source) :: equations;

    case Equation.REINIT()
      algorithm
        e1 := flattenExp(eq.cref, prefix, info);
        e2 := flattenExp(eq.reinitExp, prefix, info);
      then
        Equation.REINIT(e1, e2, eq.scope, eq.source) :: equations;

    case Equation.NORETCALL()
      algorithm
        e1 := flattenExp(eq.exp, prefix, info);
      then
        Equation.NORETCALL(e1, eq.scope, eq.source) :: equations;

    else eq :: equations;
  end match;
end flattenEquation;

function flattenIfEquation
  input Equation eq;
  input Prefix prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
protected
  Equation.Branch branch;
  list<Equation.Branch> branches, bl = {};
  Expression cond;
  list<Equation> eql;
  Variability var;
  Boolean has_connect, should_eval = false, structural = true;
  DAE.ElementSource src;
  SourceInfo info;
  Ceval.EvalTarget target;
  InstNode scope;
algorithm
  Equation.IF(branches = branches, scope = scope, source = src) := eq;
  has_connect := Equation.contains(eq, Equation.isConnection);
  info := Equation.info(eq);

  // Print errors for unbound constants/parameters if the if-equation contains
  // connects, since we must select a branch in that case.
  target := if has_connect then Ceval.EvalTarget.new(info) else NFCeval.noTarget;

  while not listEmpty(branches) loop
    branch :: branches := branches;

    bl := match branch
      case Equation.Branch.BRANCH(cond, var, eql)
        algorithm
          // Flatten the condition and body of the branch.
          cond := flattenExp(cond, prefix, info);

          // Evaluate structural conditions.
          if var <= Variability.STRUCTURAL_PARAMETER then
            if Expression.isPure(cond) then
              if has_connect then
                // If-equations containing connects must be evaluated.
                should_eval := true;
              elseif settings.minimalEval then
                // Don't evaluate if --evaluateStructuralParameters=strictlyNecessary
                should_eval := false;
                structural := false;
              elseif settings.scalarize then
                // Evaluate if scalarization is turned on.
                should_eval := true;
              elseif settings.newBackend or Expression.contains(cond, Expression.isIterator) then
                // Don't evaluate if the new backend is used or the expression contains iterators.
                should_eval := false;
                // The condition needs to be vectorized before we evaluate it for the new backend,
                // so mark it as structural so it gets evaluated later instead.
                structural := settings.newBackend;
              else
                // TODO: The condition shouldn't be evaluated if scalarization is
                //       turned off since that breaks vectorizeEquation, but
                //       turning it off completely doesn't work yet either.
                should_eval := true;
              end if;

              // Mark the expression if it's structural. If we evaluate it it's always structural.
              if structural or should_eval then
                Structural.markExp(cond);
              end if;

              if should_eval then
                cond := Ceval.evalExp(cond, target);
                cond := flattenExp(cond, prefix, info);
              end if;
            end if;

            // Conditions in an if-equation that contains connects must be possible to evaluate.
            if not Expression.isBoolean(cond) and has_connect then
              Error.addInternalError(
                "Failed to evaluate branch condition in if equation containing connect equations: `" +
                Expression.toString(cond) + "`", info);
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
            Structural.markExp(cond);
            cond := Ceval.evalExp(cond, target);
            cond := flattenExp(cond, prefix, info);
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
    equations := Equation.IF(listReverseInPlace(bl), scope, src) :: equations;
  end if;
end flattenIfEquation;

function flattenEqBranch
  input output Equation.Branch branch;
  input Prefix prefix;
  input SourceInfo info;
  input FlattenSettings settings;
protected
  Expression exp;
  list<Equation> eql;
  Variability var;
algorithm
  Equation.Branch.BRANCH(exp, var, eql) := branch;
  exp := flattenExp(exp, prefix, info);
  eql := flattenEquations(eql, prefix, settings);
  branch := Equation.makeBranch(exp, listReverseInPlace(eql), var);
end flattenEqBranch;

function unrollForLoop
  input Equation forLoop;
  input Prefix prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
protected
  InstNode iter;
  list<Equation> body, unrolled_body;
  Expression range;
  RangeIterator range_iter;
  Expression val;
  SourceInfo info;
algorithm
  Equation.FOR(iterator = iter, range = SOME(range), body = body) := forLoop;
  info := Equation.info(forLoop);

  // Unroll the loop by replacing the iterator with each of its values in the for loop body.
  range := flattenExp(range, prefix, info);
  Structural.markExp(range);
  range := Ceval.evalExp(range, Ceval.EvalTarget.new(info, NFInstContext.ITERATION_RANGE));
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
  input Prefix prefix;
  input output list<Equation> equations;
  input FlattenSettings settings;
protected
  InstNode iter;
  Option<Expression> opt_range;
  Expression range;
  list<Equation> body, connects, non_connects;
  DAE.ElementSource src;
  Equation eq;
  InstNode scope;
algorithm
  Equation.FOR(iter, opt_range, body, scope, src) := forLoop;
  body := flattenEquations(body, EMPTY_PREFIX, settings);
  (connects, non_connects) := splitForLoop2(body);

  if not listEmpty(connects) then
    if isSome(opt_range) then
      SOME(range) := opt_range;
      range := Ceval.evalExp(range, Ceval.EvalTarget.new(Equation.info(forLoop), NFInstContext.ITERATION_RANGE));
      Structural.markExp(range);
      opt_range := SOME(range);
    end if;

    eq := Equation.FOR(iter, opt_range, connects, scope, src);

    if settings.arrayConnect then
      equations := eq :: equations;
    else
      equations := unrollForLoop(eq, prefix, equations, settings);
    end if;
  end if;

  if not listEmpty(non_connects) then
    equations := Equation.FOR(iter, opt_range, non_connects, scope, src) :: equations;
  end if;
end splitForLoop;

function splitForLoop2
  input list<Equation> forBody;
  output list<Equation> connects = {};
  output list<Equation> nonConnects = {};
protected
  function is_conn_operator
    input Expression exp;
    output Boolean res;
  algorithm
    res := match exp
      case Expression.CALL()
        then Call.isConnectionsOperator(exp.call) or
             Call.isStreamOperator(exp.call) or
             Call.isCardinality(exp.call);
      else false;
    end match;
  end is_conn_operator;
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
            connects := Equation.FOR(eq.iterator, eq.range, conns, eq.scope, eq.source) :: connects;
          end if;

          if not listEmpty(nconns) then
            nonConnects := Equation.FOR(eq.iterator, eq.range, nconns, eq.scope, eq.source) :: nonConnects;
          end if;
        then
          ();

      else
        algorithm
          if Equation.containsExp(eq, function Expression.contains(func = is_conn_operator)) then
            connects := eq :: connects;
          else
            nonConnects := eq :: nonConnects;
          end if;
        then
          ();

    end match;
  end for;
end splitForLoop2;

function flattenAlgorithms
  input list<Algorithm> algorithms;
  input Prefix prefix;
  output list<Algorithm> outAlgorithms = {};
algorithm
  for alg in algorithms loop
    alg.statements := flattenStatements(alg.statements, prefix);

    // CheckModel relies on the ElementSource to know whether a certain algorithm comes from
    // an array component, otherwise is will miscount the number of equations.
    if ComponentRef.hasSubscripts(Prefix.prefix(prefix)) then
      alg.source := addElementSourceArrayPrefix(alg.source, prefix);
    end if;

    outAlgorithms := alg :: outAlgorithms;
  end for;
end flattenAlgorithms;

function flattenStatements
  input output list<Statement> stmts;
  input Prefix prefix;
algorithm
  stmts := list(flattenStatement(s, prefix) for s in stmts);
end flattenStatements;

function flattenStatement
  input output Statement stmt;
  input Prefix prefix;
protected
  SourceInfo info = Statement.info(stmt);
algorithm
  stmt := match stmt
    local
      Expression e1, e2, e3;
      Type ty;
      list<Statement> body;

    case Statement.ASSIGNMENT()
      algorithm
        e1 := flattenExp(stmt.lhs, prefix, info);
        e2 := flattenExp(stmt.rhs, prefix, info);
        ty := flattenType(stmt.ty, prefix, info);
      then
        Statement.ASSIGNMENT(e1, e2, ty, stmt.source);

    case Statement.FOR()
      algorithm
        stmt.range := Util.applyOption(stmt.range, function flattenExp(prefix = prefix, info = info));
        stmt.body := flattenStatements(stmt.body, prefix);
        stmt.forType := updateForType(stmt.forType, stmt.body);
      then
        stmt;

    case Statement.IF()
      algorithm
        stmt.branches := list(flattenStmtBranch(b, prefix, info) for b in stmt.branches);
      then
        stmt;

    case Statement.WHEN()
      algorithm
        stmt.branches := list(flattenStmtBranch(b, prefix, info) for b in stmt.branches);
      then
        stmt;

    case Statement.ASSERT()
      algorithm
        e1 := flattenExp(stmt.condition, prefix, info);
        e2 := flattenExp(stmt.message, prefix, info);
        e3 := flattenExp(stmt.level, prefix, info);
      then
        Statement.ASSERT(e1, e2, e3, stmt.source);

    case Statement.TERMINATE()
      algorithm
        e1 := flattenExp(stmt.message, prefix, info);
      then
        Statement.TERMINATE(e1, stmt.source);

    case Statement.REINIT()
      algorithm
        e1 := flattenExp(stmt.cref, prefix, info);
        e2 := flattenExp(stmt.reinitExp, prefix, info);
      then
        Statement.REINIT(e1, e2, stmt.source);

    case Statement.NORETCALL()
      algorithm
        e1 := flattenExp(stmt.exp, prefix, info);
      then
        Statement.NORETCALL(e1, stmt.source);

    case Statement.WHILE()
      algorithm
        e1 := flattenExp(stmt.condition, prefix, info);
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
  input Prefix prefix;
  input SourceInfo info;
protected
  Expression cond;
  list<Statement> body;
algorithm
  (cond, body) := branch;
  cond := flattenExp(cond, prefix, info);
  body := flattenStatements(body, prefix);
  branch := (cond, body);
end flattenStmtBranch;

function addElementSourceArrayPrefix
  input output DAE.ElementSource source;
  input Prefix prefix;
protected
  DAE.ComponentPrefix comp_pre;
algorithm
  // It seems the backend doesn't really care about the ComponentPrefix, and
  // creating a proper prefix here could be rather expensive. So we just create
  // a dummy prefix here with one subscript to keep CheckModel happy.
  comp_pre := DAE.ComponentPrefix.PRE(
    ComponentRef.firstName(Prefix.prefix(prefix)),
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
  input FlattenSettings settings;
protected
  Connections conns;
  list<Equation> conn_eql, ec_eql, tlio_eql;
  list<Variable> tlio_vars;
  ConnectionSets.Sets csets;
  array<list<Connector>> csets_array;
  CardinalityTable.Table ctable;
  Connections.BrokenEdges broken = {};
  UnorderedMap<ComponentRef, Variable> vars;
  UnorderedSet<ComponentRef> connectedLocalIOs;
  Integer exposeLocalIOs;
algorithm
  vars := UnorderedMap.new<Variable>(ComponentRef.hash, ComponentRef.isEqual,
    listLength(flatModel.variables));

  for v in flatModel.variables loop
    UnorderedMap.addNew(v.name, v, vars);
  end for;

  // Collect connections from the model.
  (flatModel, conns) := Connections.collectConnections(flatModel,
    function isDeletedConnector(deletedVars = deletedVars));
  ctable := CardinalityTable.fromConnections(conns);

  // Elaborate expandable connectors.
  (flatModel, conns) := ExpandableConnectors.elaborate(flatModel, conns);
  flatModel.variables := list(v for v guard Variable.isPresent(v) in flatModel.variables);

  // Collect flow variables from the model, which needs to be done after
  // elaborating expandable connectors to get all of them.
  conns := Connections.collectFlows(flatModel, conns);

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
  conns := Connections.split(conns);
  conns := Connections.scalarize(conns, keepSingleConnectedArrays = not settings.scalarize);

  csets := ConnectionSets.fromConnections(conns);
  csets_array := ConnectionSets.extractSets(csets);
  // generate the equations
  (conn_eql, connectedLocalIOs) := ConnectEquations.generateEquations(csets_array, vars);

  // append the equalityConstraint call equations for the broken connects
  if System.getHasOverconstrainedConnectors() then
    ec_eql := List.flatten(list(e.brokenEquations for e in broken));
    flatModel.equations := listAppend(ec_eql, flatModel.equations);
  end if;

  // add the equations to the flat model
  flatModel.equations := listAppend(conn_eql, flatModel.equations);

  // add top-level IOs for unconnected local IOs
  exposeLocalIOs := Flags.getConfigInt(Flags.EXPOSE_LOCAL_IOS);
  if exposeLocalIOs > 0 then
    (tlio_vars, tlio_eql) := generateTopLevelIOs(vars, connectedLocalIOs, exposeLocalIOs);
    flatModel.variables := List.append_reverse(flatModel.variables, tlio_vars);
    flatModel.equations := List.append_reverse(flatModel.equations, tlio_eql);
  end if;

  // Evaluate any connection operators if they're used.
  if  System.getHasStreamConnectors() or System.getUsesCardinality() then
    flatModel := evaluateConnectionOperators(flatModel, csets, csets_array, vars, ctable);
  end if;

  execStat(getInstanceName());
end resolveConnections;

function generateTopLevelIOs
  "generate top-level inputs and outputs for public unconnected local input and output connectors"
  input UnorderedMap<ComponentRef, Variable> variables;
  input UnorderedSet<ComponentRef> connectedLocalIOs;
  input Integer exposeLocalIOs;
  output list<Variable> tlio_vars;
  output list<Equation> tlio_eql;
protected
  Attributes attributes;
  Variable tlio_var;
  ComponentRef cref;
  String name;
  InstNode tlio_node;
  Integer level;
algorithm
  tlio_vars := {};
  tlio_eql := {};
  for variable in UnorderedMap.valueList(variables) loop
    level := ComponentRef.depth(variable.name) - 1;
    attributes := variable.attributes;
    if 0 < level and level <= exposeLocalIOs and
      variable.visibility == Visibility.PUBLIC and
      attributes.connectorType <> ConnectorType.NON_CONNECTOR and
      (attributes.direction == Direction.INPUT or attributes.direction == Direction.OUTPUT) and
      not UnorderedSet.contains(variable.name, connectedLocalIOs)
    then
      // add a new variable and equation if removeNonTopLevelDirection removes the direction
      tlio_var := Variable.removeNonTopLevelDirection(variable);
      attributes := tlio_var.attributes;
      if attributes.direction == Direction.NONE then
        tlio_var := variable; // same attributes like start, unit
        tlio_var.binding := UNBOUND(); // value is defined with tlio_eql
        // find new name in global scope, starting with quoted identifier
        cref := tlio_var.name;
        name := stringDelimitList(ComponentRef.toString_impl(cref, {}), ".");
        while UnorderedMap.contains(tlio_var.name, variables) loop
          tlio_node := InstNode.NAME_NODE(Util.makeQuotedIdentifier(name));
          tlio_var.name := match cref case ComponentRef.CREF() then
            ComponentRef.CREF(tlio_node, cref.subscripts, cref.ty, cref.origin, ComponentRef.EMPTY());
          end match;
          name := name + "_" "append underscore until name is unique";
        end while;
        tlio_vars := tlio_var :: tlio_vars;
        tlio_eql := Equation.makeCrefEquality(variable.name, tlio_var.name,
          InstNode.EMPTY_NODE(), ElementSource.createElementSource(variable.info)) :: tlio_eql;
      end if;
    end if;
  end for;
end generateTopLevelIOs;

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
  Expression exp, eval_exp;
algorithm
  () := match var
    case Variable.VARIABLE()
      guard Binding.hasExp(var.binding)
      algorithm
        exp := Binding.getExp(var.binding);
        eval_exp := ConnectEquations.evaluateOperators(exp, sets, setsArray, variables, ctable);

        if not referenceEq(exp, eval_exp) then
          var.binding := Binding.setExp(eval_exp, var.binding);
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

    case Statement.REINIT()
      algorithm
        funcs := collectExpFuncs(stmt.cref, funcs);
        funcs := collectExpFuncs(stmt.reinitExp, funcs);
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

      if Function.isPartialDerivative(fn) then
        for f in Function.getCachedFuncs(Class.lastBaseClass(fn.node)) loop
          flattenFunction(f, funcs);
        end for;
      end if;
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

function verifyDimensions
  input list<Dimension> dimensions;
  input InstNode component;
algorithm
  for d in dimensions loop
    verifyDimension(d, component);
  end for;
end verifyDimensions;

function verifyDimension
  input Dimension dimension;
  input InstNode component;
algorithm
  () := match dimension
    case Dimension.INTEGER()
      algorithm
        // Check that integer dimensions are not negative.
        if dimension.size < 0 then
          Error.addSourceMessage(Error.NEGATIVE_DIMENSION_INDEX,
            {String(dimension.size), InstNode.name(component)}, InstNode.info(component));
          fail();
        end if;
      then
        ();

    else ();
  end match;
end verifyDimension;

function updateVariability
  input output Variable var;
protected
  Variability v;
algorithm
  if var.attributes.variability == Variability.PARAMETER then
    v := Component.variability(InstNode.component(ComponentRef.node(var.name)));

    if v < Variability.PARAMETER then
      var := Variable.setVariability(var, v);
    end if;
  end if;
end updateVariability;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
