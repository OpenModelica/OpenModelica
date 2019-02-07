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

import NFBinding.Binding;
import Equation = NFEquation;
import NFFunction.Function;
import NFInstNode.InstNode;
import Statement = NFStatement;
import FlatModel = NFFlatModel;
import Prefix;
import Algorithm = NFAlgorithm;
import CardinalityTable = NFCardinalityTable;

protected
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import ExecStat.execStat;
import ExpressionIterator = NFExpressionIterator;
import Expression = NFExpression;
import Inst = NFInst;
import List;
import NFCall.Call;
import NFClass.Class;
import NFClassTree.ClassTree;
import NFComponent.Component;
import NFModifier.Modifier;
import Sections = NFSections;
import NFOCConnectionGraph;
import Prefixes = NFPrefixes;
import NFPrefixes.Visibility;
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
import NFPrefixes.Variability;
import Variable = NFVariable;
import ElementSource;
import Ceval = NFCeval;
import NFTyping.ExpOrigin;
import SimplifyExp = NFSimplifyExp;
import Restriction = NFRestriction;
import EvalConstants = NFEvalConstants;
import SimplifyModel = NFSimplifyModel;
import InstNodeType = NFInstNode.InstNodeType;

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
    outString := Absyn.pathString(inKey);
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := "";
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := Absyn.pathCompareNoQual(inKey1, inKey2);
  end keyCompare;

  redeclare function addConflictDefault = addConflictKeep;
end FunctionTreeImpl;

function flatten
  input InstNode classInst;
  input String name;
  output FlatModel flatModel;
protected
  Sections sections;
  list<Variable> vars;
  list<Equation> eql, ieql;
  list<Algorithm> alg, ialg;
  Option<SCode.Comment> cmt;
algorithm
  sections := Sections.EMPTY();
  cmt := SCode.getElementComment(InstNode.definition(classInst));

  (vars, sections) := flattenClass(InstNode.getClass(classInst), ComponentRef.EMPTY(),
    Visibility.PUBLIC, NONE(), {}, sections);
  vars := listReverseInPlace(vars);

  flatModel := match sections
    case Sections.SECTIONS()
      algorithm
        eql := listReverseInPlace(sections.equations);
        ieql := listReverseInPlace(sections.initialEquations);
        alg := listReverseInPlace(sections.algorithms);
        ialg := listReverseInPlace(sections.initialAlgorithms);
      then
        FlatModel.FLAT_MODEL(name, vars, eql, ieql, alg, ialg, cmt);

      else FlatModel.FLAT_MODEL(name, vars, {}, {}, {}, {}, cmt);
  end match;

  execStat(getInstanceName() + "(" + name + ")");
  flatModel := resolveConnections(flatModel, name);
end flatten;

function collectFunctions
  input FlatModel flatModel;
  input String name;
  output FunctionTree funcs;
algorithm
  funcs := FunctionTree.new();
  funcs := List.fold(flatModel.variables, collectComponentFuncs, funcs);
  funcs := List.fold(flatModel.equations, collectEquationFuncs, funcs);
  funcs := List.fold(flatModel.initialEquations, collectEquationFuncs, funcs);
  funcs := List.fold(flatModel.algorithms, collectAlgorithmFuncs, funcs);
  funcs := List.fold(flatModel.initialAlgorithms, collectAlgorithmFuncs, funcs);
  execStat(getInstanceName() + "(" + name + ")");
end collectFunctions;

protected
function flattenClass
  input Class cls;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
  input output Sections sections;
protected
  array<InstNode> comps;
  list<Binding> bindings;
  Binding b;
algorithm
  // print(">" + stringAppendList(List.fill("  ", ComponentRef.depth(prefix)-1)) + ComponentRef.toString(prefix) + "\n");
  () := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      algorithm
        if isSome(binding) then
          SOME(b) := binding;

          if Binding.isBound(b) then
            b := flattenBinding(b, ComponentRef.rest(prefix));
            bindings := getRecordBindings(b);

            Error.assertion(listLength(bindings) == arrayLength(comps),
              getInstanceName() + " got record binding with wrong number of elements for " +
                ComponentRef.toString(prefix),
              sourceInfo());

            for c in comps loop
              (vars, sections) := flattenComponent(c, prefix, visibility, SOME(listHead(bindings)), vars, sections);
              bindings := listRest(bindings);
            end for;
          else
            for c in comps loop
              (vars, sections) := flattenComponent(c, prefix, visibility, binding, vars, sections);
            end for;
          end if;
        else
          for c in comps loop
            (vars, sections) := flattenComponent(c, prefix, visibility, NONE(), vars, sections);
          end for;
        end if;

        sections := flattenSections(cls.sections, prefix, sections);
      then
        ();

    case Class.TYPED_DERIVED()
      algorithm
        (vars, sections) :=
          flattenClass(InstNode.getClass(cls.baseClass), prefix, visibility, binding, vars, sections);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-instantiated component " + ComponentRef.toString(prefix) + "\n", sourceInfo());
      then
        ();

  end match;
  // print("<" + stringAppendList(List.fill("  ", ComponentRef.depth(prefix)-1)) + ComponentRef.toString(prefix) + "\n");
end flattenClass;

function flattenComponent
  input InstNode component;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input output list<Variable> vars;
  input output Sections sections;
protected
  InstNode comp_node;
  Component c;
  Type ty;
  Binding condition;
  Class cls;
  Visibility vis;
algorithm
  // Remove components that are only outer.
  if InstNode.isOnlyOuter(component) or InstNode.isEmpty(component) then
    return;
  end if;

  comp_node := InstNode.resolveOuter(component);
  c := InstNode.component(comp_node);

  // print("->" + stringAppendList(List.fill("  ", ComponentRef.depth(prefix))) + ComponentRef.toString(prefix) + "." + InstNode.name(component) + "\n");

  () := match c
    case Component.TYPED_COMPONENT(condition = condition, ty = ty)
      algorithm
        // Delete the component if it has a condition that's false.
        if isDeletedComponent(condition, prefix) then
          deleteComponent(component);
          return;
        end if;

        cls := InstNode.getClass(c.classInst);
        vis := if InstNode.isProtected(component) then Visibility.PROTECTED else visibility;

        if isComplexComponent(ty) then
          (vars, sections) := flattenComplexComponent(comp_node, c, cls, ty, vis, prefix, vars, sections);
        else
          (vars, sections) := flattenSimpleComponent(comp_node, c, vis, outerBinding,
            Class.getTypeAttributes(cls), prefix, vars, sections);
        end if;
      then
        ();

    case Component.DELETED_COMPONENT() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown component", sourceInfo());
      then
        fail();

  end match;

  // print("<-" + stringAppendList(List.fill("  ", ComponentRef.depth(prefix))) + ComponentRef.toString(prefix) + "." + InstNode.name(component) + "\n");
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
    // TODO: Flattening the condition works as intended here, but we can't yet
    //       delete components inside array instances in a reliable way since
    //       the components share the same node. I.e. we can't delete a[1].x
    //       while keeping a[2].x. So for now we skip flattening the condition,
    //       so that we get an error message in that case instead (because then
    //       the expression will be an array instead of a scalar boolean).
    cond := condition;
    //cond := flattenBinding(condition, prefix);
    exp := Binding.getTypedExp(cond);
    exp := Ceval.evalExp(exp, Ceval.EvalTarget.CONDITION(Binding.getInfo(cond)));

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
  "Recursively marks components as deleted."
  input InstNode compNode;
protected
  Component comp;
algorithm
  // @adrpo: don't delete the inner/outer node, it doesn't work!
  if InstNode.isInnerOuterNode(compNode) then
    return;
  end if;

  if not InstNode.isEmpty(compNode) then
    comp := InstNode.component(compNode);
    InstNode.updateComponent(Component.DELETED_COMPONENT(comp), compNode);
    deleteClassComponents(Component.classInstance(comp));
  end if;
end deleteComponent;

function deleteClassComponents
  input InstNode clsNode;
protected
  Class cls = InstNode.getClass(clsNode);
  array<InstNode> comps;
algorithm
  () := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      guard not Restriction.isType(cls.restriction)
      algorithm
        for c in comps loop
          deleteComponent(c);
        end for;
      then
        ();

    case Class.TYPED_DERIVED()
      algorithm
        deleteClassComponents(cls.baseClass);
      then
        ();

    else ();
  end match;
end deleteClassComponents;

function isComplexComponent
  input Type ty;
  output Boolean isComplex;
algorithm
  isComplex := match ty
    case Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT()) then false;
    case Type.COMPLEX() then true;
    case Type.ARRAY() then isComplexComponent(ty.elementType);
    else false;
  end match;
end isComplexComponent;

function flattenSimpleComponent
  input InstNode node;
  input Component comp;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input list<Modifier> typeAttrs;
  input ComponentRef prefix;
  input output list<Variable> vars;
  input output Sections sections;
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
  if Type.isArray(ty) and Binding.isBound(binding) and var >= Variability.DISCRETE then
    name := ComponentRef.prefixCref(comp_node, ty, {}, prefix);
    eq := Equation.ARRAY_EQUALITY(Expression.CREF(ty, name), Binding.getTypedExp(binding), ty,
      ElementSource.createElementSource(info));
    sections := Sections.prependEquation(eq, sections);
    binding := NFBinding.EMPTY_BINDING;
  end if;

  name := ComponentRef.prefixScope(comp_node, ty, {}, prefix);
  ty_attrs := list(flattenTypeAttribute(m, name) for m in typeAttrs);

  // Set fixed = true for parameters that are part of a record instance whose
  // binding couldn't be split and was moved to an initial equation.
  if unfix then
    ty_attrs := List.removeOnTrue("fixed", isTypeAttributeNamed, ty_attrs);
    ty_attrs := ("fixed", Binding.FLAT_BINDING(Expression.BOOLEAN(false), Variability.CONSTANT)) :: ty_attrs;
  end if;

  vars := Variable.VARIABLE(name, ty, binding, visibility, comp_attr, ty_attrs, cmt, info) :: vars;
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
  output list<Binding> recordBindings;
protected
  Expression binding_exp;
  list<Expression> expl;
  Variability var;
algorithm
  binding_exp := Binding.getTypedExp(binding);
  var := Binding.variability(binding);

  recordBindings := match binding_exp
    case Expression.RECORD() then
      list(if Expression.isEmpty(e) then
               // The binding for a record field might be Expression.EMPTY if it comes
               // from an evaluated function call where it wasn't assigned a value.
               NFBinding.EMPTY_BINDING
             else
               Binding.FLAT_BINDING(e, var)
           for e in binding_exp.elements);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-record binding " +
          Expression.toString(binding_exp), sourceInfo());
      then
        fail();
  end match;
end getRecordBindings;

function flattenComplexComponent
  input InstNode node;
  input Component comp;
  input Class cls;
  input Type ty;
  input Visibility visibility;
  input ComponentRef prefix;
  input output list<Variable> vars;
  input output Sections sections;
protected
  list<Dimension> dims;
  ComponentRef name;
  Binding binding;
  Option<Binding> opt_binding;
  Expression binding_exp;
  Equation eq;
  list<Expression> bindings;
  Variability comp_var, binding_var;
algorithm
  dims := Type.arrayDims(ty);
  binding := Component.getBinding(comp);

  // Create an equation if there's a binding on a complex component.
  if Binding.isExplicitlyBound(binding) then
    binding := flattenBinding(binding, prefix);
    binding_exp := Binding.getTypedExp(binding);
    binding_var := Binding.variability(binding);

    comp_var := Component.variability(comp);
    if comp_var <= Variability.STRUCTURAL_PARAMETER or binding_var <= Variability.STRUCTURAL_PARAMETER then
      binding_exp := Ceval.evalExp(binding_exp);
    elseif binding_var == Variability.PARAMETER and Component.isFinal(comp) then
      try
        binding_exp := Ceval.evalExp(binding_exp);
      else
      end try;
    else
      binding_exp := SimplifyExp.simplify(binding_exp);
    end if;

    binding_exp := Expression.splitRecordCref(binding_exp);

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

  name := ComponentRef.prefixScope(node, ty, {}, prefix);

  // Flatten the class directly if the component is a scalar, otherwise scalarize it.
  if listEmpty(dims) then
    (vars, sections) := flattenClass(cls, name, visibility, opt_binding, vars, sections);
  else
    (vars, sections) := flattenArray(cls, dims, name, visibility, opt_binding, vars, sections);
  end if;
end flattenComplexComponent;

function flattenArray
  input Class cls;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
  input output Sections sections;
  input list<Subscript> subscripts = {};
protected
  Dimension dim;
  list<Dimension> rest_dims;
  ComponentRef sub_pre;
  RangeIterator range_iter;
  Expression sub_exp;
  list<Subscript> subs;
  list<Variable> vrs;
  Sections sects;
algorithm
  // if we don't scalarize flatten the class and vectorize it
  if not Flags.isSet(Flags.NF_SCALARIZE) then
    (vrs, sects) := flattenClass(cls, prefix, visibility, binding, {}, Sections.SECTIONS({}, {}, {}, {}));
    // add dimensions to the types
    for v in vrs loop
      v.ty := Type.liftArrayLeftList(v.ty, dimensions);
      vars := v::vars;
    end for;
    // vectorize equations
    () := match sects
      case Sections.SECTIONS()
        algorithm
          for eqn in listReverse(sects.equations) loop
            sections := Sections.prependEquation(vectorizeEquation(eqn, dimensions, prefix), sections);
          end for;
          for eqn in listReverse(sects.initialEquations) loop
            sections := Sections.prependEquation(vectorizeEquation(eqn, dimensions, prefix), sections, true);
          end for;
          for alg in listReverse(sects.algorithms) loop
            sections := Sections.prependAlgorithm(vectorizeAlgorithm(alg, dimensions, prefix), sections);
          end for;
          for alg in listReverse(sects.initialAlgorithms) loop
            sections := Sections.prependAlgorithm(vectorizeAlgorithm(alg, dimensions, prefix), sections, true);
          end for;
        then ();
    end match;
    return;
  end if;

  if listEmpty(dimensions) then
    subs := listReverse(subscripts);
    sub_pre := ComponentRef.setSubscripts(subs, prefix);

    (vars, sections) := flattenClass(cls, sub_pre, visibility,
      subscriptBindingOpt(subs, binding), vars, sections);
  else
    dim :: rest_dims := dimensions;
    range_iter := RangeIterator.fromDim(dim);

    while RangeIterator.hasNext(range_iter) loop
      (range_iter, sub_exp) := RangeIterator.next(range_iter);
      (vars, sections) := flattenArray(cls, rest_dims, prefix, visibility,
          binding, vars, sections, Subscript.INDEX(sub_exp) :: subscripts);
    end while;
  end if;
end flattenArray;

function vectorizeEquation
  input Equation eqn;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  output Equation veqn;
algorithm
  veqn := match eqn
    local
      InstNode prefix_node, iter;
      Integer stop;
      Expression range;
    case Equation.EQUALITY(lhs = Expression.CREF(), rhs = Expression.CREF())
      // convert simple equality of crefs to array equality
      then Equation.ARRAY_EQUALITY(eqn.lhs, eqn.rhs, Type.liftArrayLeftList(eqn.ty, dimensions), eqn.source);
    else
      // wrap general equation into for loop
      algorithm
        iter := match ComponentRef.node(prefix)
          case prefix_node as InstNode.COMPONENT_NODE()
            then InstNode.COMPONENT_NODE(
              "$i", prefix_node.visibility,
              Pointer.create(Component.ITERATOR(Type.INTEGER(), Variability.IMPLICITLY_DISCRETE,
                             Component.info(Pointer.access(prefix_node.component)))),
              prefix_node.parent, InstNodeType.NORMAL_COMP());
        end match;
        {Dimension.INTEGER(size = stop)} := dimensions;
        range := Expression.RANGE(Type.INTEGER(), Expression.INTEGER(1), NONE(), Expression.INTEGER(stop));
        veqn := Equation.mapExp(eqn, function addIterator(prefix = prefix, subscript = Subscript.INDEX(Expression.CREF(Type.INTEGER(), ComponentRef.makeIterator(iter, Type.INTEGER())))));
      then
        Equation.FOR(iter, SOME(range), {veqn}, Equation.source(eqn));
  end match;
end vectorizeEquation;

function vectorizeAlgorithm
  input Algorithm alg;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  output Algorithm valg;
algorithm
  valg := match alg
    local
      InstNode prefix_node, iter;
      Integer stop;
      Expression range;
      list<Statement> body;
    case Algorithm.ALGORITHM(statements = {Statement.ASSIGNMENT(lhs = Expression.CREF(), rhs = Expression.CREF())})
      // let simple assignment as is
      then alg;
    else
      // wrap general algorithm into for loop
      algorithm
        iter := match ComponentRef.node(prefix)
          case prefix_node as InstNode.COMPONENT_NODE()
            then InstNode.COMPONENT_NODE(
              "$i", prefix_node.visibility,
              Pointer.create(Component.ITERATOR(Type.INTEGER(), Variability.IMPLICITLY_DISCRETE,
                             Component.info(Pointer.access(prefix_node.component)))),
              prefix_node.parent, InstNodeType.NORMAL_COMP());
        end match;
        {Dimension.INTEGER(size = stop)} := dimensions;
        range := Expression.RANGE(Type.INTEGER(), Expression.INTEGER(1), NONE(), Expression.INTEGER(stop));
        body := Statement.mapExpList(alg.statements, function addIterator(prefix = prefix, subscript = Subscript.INDEX(Expression.CREF(Type.INTEGER(), ComponentRef.makeIterator(iter, Type.INTEGER())))));
      then
        Algorithm.ALGORITHM({Statement.FOR(iter, SOME(range), body, alg.source)}, alg.source);
  end match;
end vectorizeAlgorithm;

function addIterator
  input output Expression exp;
  input ComponentRef prefix;
  input Subscript subscript;
algorithm
  exp := Expression.map(exp, function addIterator_traverse(prefix = prefix, subscript = subscript));
end addIterator;

function addIterator_traverse
  input output Expression exp;
  input ComponentRef prefix;
  input Subscript subscript;
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
          exp.cref := ComponentRef.applySubscripts({subscript}, exp.cref);
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

function flattenBinding
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
        bind_exp := binding.bindingExp;
        pars := listRest(binding.parents);

        // TODO: Optimize this, making a list of all subscripts in the prefix
        //       when only a few are needed is unnecessary.
        if not (binding.isEach or listEmpty(pars)) then
          if isTypeAttribute then
            pars := listRest(pars);
          end if;

          binding_level := 0;
          for parent in pars loop
            binding_level := binding_level + Type.dimensionCount(InstNode.getType(parent));
          end for;

          if binding_level > 0 then
            subs := listAppend(listReverse(s) for s in ComponentRef.subscriptsAll(prefix));
            accum_subs := {};

            for i in 1:binding_level loop
              if listEmpty(subs) then
                break;
              end if;

              accum_subs := listHead(subs) :: accum_subs;
              subs := listRest(subs);
            end for;

            bind_exp := Expression.applySubscripts(accum_subs, bind_exp);
          end if;
        end if;

        binding.bindingExp := flattenExp(bind_exp, prefix);
        binding.isFlattened := true;
      then
        binding;

    // CEVAL_BINDINGs are temporary bindings generated by the constant
    // evaluation and no longer needed after flattening.
    case Binding.CEVAL_BINDING() then NFBinding.EMPTY_BINDING;

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

function flattenExp
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
    case Expression.CREF()
      algorithm
        exp.cref := ComponentRef.transferSubscripts(prefix, exp.cref);
      then
        exp;

    else exp;
  end match;
end flattenExp_traverse;

function flattenSections
  input Sections sections;
  input ComponentRef prefix;
  input output Sections accumSections;
algorithm
  () := match sections
    local
      list<Equation> eq, ieq;
      list<Algorithm> alg, ialg;

    case Sections.SECTIONS()
      algorithm
        eq := flattenEquations(sections.equations, prefix);
        ieq := flattenEquations(sections.initialEquations, prefix);
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
  output list<Equation> equations = {};
algorithm
  for eq in eql loop
    equations := flattenEquation(eq, prefix, equations);
  end for;
end flattenEquations;

function flattenEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<Equation> equations;
algorithm
  equations := match eq
    local
      Expression e1, e2, e3;
      list<Equation> eql;

    case Equation.EQUALITY()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
      then
        Equation.EQUALITY(e1, e2, eq.ty, eq.source) :: equations;

    case Equation.FOR()
      algorithm
        if Flags.isSet(Flags.NF_SCALARIZE) then
          eql := unrollForLoop(eq, prefix, equations);
        else
          eql := eq :: equations;
        end if;
      then eql;

    case Equation.CONNECT()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
        eql := flattenEquations(eq.broken, prefix);
      then
        Equation.CONNECT(e1, e2, eql, eq.source) :: equations;

    case Equation.IF()
      then flattenIfEquation(eq, prefix, equations);

    case Equation.WHEN()
      algorithm
        eq.branches := list(flattenEqBranch(b, prefix) for b in eq.branches);
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
          eql := flattenEquations(eql, prefix);

          // Evaluate structural conditions.
          if var <= Variability.STRUCTURAL_PARAMETER then
            cond := Ceval.evalExp(cond, target);

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
      then Absyn.pathFirstIdent(Function.name(fn)) == "Connections";
    else false;
  end match;
end isConnectEq;

function flattenEqBranch
  input output Equation.Branch branch;
  input ComponentRef prefix;
protected
  Expression exp;
  list<Equation> eql;
  Variability var;
algorithm
  Equation.Branch.BRANCH(exp, var, eql) := branch;
  exp := flattenExp(exp, prefix);
  eql := flattenEquations(eql, prefix);
  branch := Equation.makeBranch(exp, listReverseInPlace(eql), var);
end flattenEqBranch;

function unrollForLoop
  input Equation forLoop;
  input ComponentRef prefix;
  input output list<Equation> equations;
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
    unrolled_body := Equation.mapExpList(body,
      function Expression.replaceIterator(iterator = iter, iteratorValue = val));
    unrolled_body := flattenEquations(unrolled_body, prefix);
    equations := listAppend(unrolled_body, equations);
  end while;
end unrollForLoop;

function flattenAlgorithms
  input list<Algorithm> algorithms;
  input ComponentRef prefix;
  output list<Algorithm> outAlgorithms = {};
algorithm
  for alg in algorithms loop
    alg.statements := Statement.mapExpList(alg.statements, function flattenExp(prefix = prefix));

    // CheckModel relies on the ElementSource to know whether a certain algorithm comes from
    // an array component, otherwise is will miscount the number of equations.
    if ComponentRef.hasSubscripts(prefix) then
      alg.source := addElementSourceArrayPrefix(alg.source, prefix);
    end if;

    outAlgorithms := alg :: outAlgorithms;
  end for;
end flattenAlgorithms;

function addElementSourceArrayPrefix
  input output DAE.ElementSource source;
  input ComponentRef prefix;
protected
  Prefix.ComponentPrefix comp_pre;
algorithm
  // It seems the backend doesn't really care about the ComponentPrefix, and
  // creating a proper prefix here could be rather expensive. So we just create
  // a dummy prefix here with one subscript to keep CheckModel happy.
  comp_pre := Prefix.ComponentPrefix.PRE(
    ComponentRef.firstName(prefix),
    {},
    {DAE.Subscript.INDEX(DAE.Exp.ICONST(-1))},
    Prefix.ComponentPrefix.NOCOMPPRE(),
    ClassInf.State.UNKNOWN(Absyn.IDENT("?")),
    Absyn.dummyInfo
  );

  source := ElementSource.addElementSourceInstanceOpt(source, comp_pre);
end addElementSourceArrayPrefix;

function resolveConnections
"Generates the connect equations and adds them to the equation list"
  input output FlatModel flatModel;
  input String name;
protected
  Connections conns;
  list<Equation> conn_eql;
  ConnectionSets.Sets csets;
  array<list<Connector>> csets_array;
  CardinalityTable.Table ctable;
  Connections.BrokenEdges broken = {};
algorithm
  // handle overconstrained connections
  // - build the graph
  // - evaluate the Connections.* operators
  // - generate the equations to replace the broken connects
  // - return the broken connects + the equations
  if  System.getHasOverconstrainedConnectors() then
    (flatModel, broken) := NFOCConnectionGraph.handleOverconstrainedConnections(flatModel, name);
  end if;
  // get the connections from the model
  (flatModel, conns) := Connections.collect(flatModel);
  // add the broken connections
  conns := Connections.addBroken(broken, conns);
  // build the sets, check the broken connects
  csets := ConnectionSets.fromConnections(conns);
  csets_array := ConnectionSets.extractSets(csets);
  // generate the equations
  conn_eql := ConnectEquations.generateEquations(csets_array);

  // append the equalityConstraint call equations for the broken connects
  if  System.getHasOverconstrainedConnectors() then
    conn_eql := listAppend(conn_eql, List.flatten(List.map(broken, Util.tuple33)));
  end if;

  // add the equations to the flat model
  flatModel.equations := listAppend(conn_eql, flatModel.equations);

  ctable := CardinalityTable.fromConnections(conns);

  // Evaluate any connection operators if they're used.
  if  System.getHasStreamConnectors() or System.getUsesCardinality() then
    flatModel := evaluateConnectionOperators(flatModel, csets, csets_array, ctable);
  end if;

  execStat(getInstanceName() + "(" + name + ")");
end resolveConnections;

function evaluateConnectionOperators
  input output FlatModel flatModel;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input CardinalityTable.Table ctable;
algorithm
  flatModel.variables := list(evaluateBindingConnOp(c, sets, setsArray, ctable) for c in flatModel.variables);
  flatModel.equations := evaluateEquationsConnOp(flatModel.equations, sets, setsArray, ctable);
  flatModel.initialEquations := evaluateEquationsConnOp(flatModel.initialEquations, sets, setsArray, ctable);
  // TODO: Implement evaluation for algorithm sections.
end evaluateConnectionOperators;

function evaluateBindingConnOp
  input output Variable var;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
  input CardinalityTable.Table ctable;
protected
  Binding binding;
  Expression exp, eval_exp;
algorithm
  () := match var
    case Variable.VARIABLE(binding = binding as Binding.TYPED_BINDING(bindingExp = exp))
      algorithm
        eval_exp := ConnectEquations.evaluateOperators(exp, sets, setsArray, ctable);

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
  input CardinalityTable.Table ctable;
algorithm
  equations := list(
      Equation.mapExp(eq,
        function ConnectEquations.evaluateOperators(sets = sets, setsArray = setsArray, ctable = ctable))
    for eq in equations);
end evaluateEquationsConnOp;

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
algorithm
  () := match Type.arrayElementType(ty)
    local
      InstNode con, de;
      Function fn;

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
          if InstNode.isEmpty(c) then
            continue;
          end if;

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

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
