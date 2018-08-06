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
  output FunctionTree funcs;
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
        FlatModel.FLAT_MODEL(vars, eql, ieql, alg, ialg, cmt);

    else FlatModel.FLAT_MODEL(vars, {}, {}, {}, {}, cmt);
  end match;

  execStat(getInstanceName() + "(" + name + ")");
  flatModel := resolveConnections(flatModel, name);
  funcs := flattenFunctions(flatModel, name);
end flatten;

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
        if Binding.isBound(condition) and Expression.isFalse(Binding.getTypedExp(condition)) then
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
  Variability comp_var;
algorithm
  dims := Type.arrayDims(ty);
  binding := Component.getBinding(comp);

  // Create an equation if there's a binding on a complex component.
  if Binding.isExplicitlyBound(binding) then
    binding := flattenBinding(binding, prefix);
    binding_exp := Binding.getTypedExp(binding);

    comp_var := Component.variability(comp);
    if comp_var <= Variability.STRUCTURAL_PARAMETER then
      binding_exp := Ceval.evalExp(binding_exp);
    else
      binding_exp := SimplifyExp.simplify(binding_exp);
    end if;

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
algorithm
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
      then
        binding;

    // CEVAL_BINDINGs are temporary bindings generated by the constant
    // evaluation and no longer needed after flattening.
    case Binding.CEVAL_BINDING() then NFBinding.EMPTY_BINDING;

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
      then unrollForLoop(eq, prefix, equations);

    case Equation.CONNECT()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
        eql := flattenEquations(eq.broken, prefix);
      then
        Equation.CONNECT(e1, e2, eql, eq.source) :: equations;

    case Equation.IF()
      then flattenIfEquation(eq.branches, prefix, eq.source, equations);

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
  input list<Equation.Branch> branches;
  input ComponentRef prefix;
  input DAE.ElementSource source;
  input output list<Equation> equations;
protected
  list<Equation.Branch> bl = {};
  Expression cond;
  list<Equation> eql;
  Variability var;
algorithm
  for b in branches loop
    bl := match b
      case Equation.Branch.BRANCH(cond, var, eql)
        algorithm
          // flatten the condition first
          cond := flattenExp(cond, prefix);
          // flatten the equations
          eql := flattenEquations(eql, prefix);

          if Expression.isTrue(cond) and listEmpty(bl) then
            // If the condition is literal true and we haven't collected any other
            // branches yet, replace the if equation with this branch.
            equations := listAppend(eql, equations);
            return;
          elseif not Expression.isFalse(cond) then
            // Only add the branch to the list of branches if the condition is not
            // literal false, otherwise just drop it since it will never trigger.
            bl := Equation.makeBranch(cond, eql, var) :: bl;
          end if;
        then
          bl;

      else b :: bl;
    end match;
  end for;

  // Add the flattened if equation to the list of equations if we got this far,
  // and there are any branches still remaining.
  if not listEmpty(bl) then
    equations := Equation.IF(listReverseInPlace(bl), source) :: equations;
  end if;
end flattenIfEquation;

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
  range := Ceval.evalExp(range, Ceval.EvalTarget.RANGE(Equation.info(forLoop)));
  range_iter := RangeIterator.fromExp(range);

  while RangeIterator.hasNext(range_iter) loop
    (range_iter, val) := RangeIterator.next(range_iter);
    unrolled_body := list(Equation.mapExp(eq,
      function Expression.replaceIterator(iterator = iter, iteratorValue = val)) for eq in body);
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

function flattenFunctions
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
end flattenFunctions;

function collectComponentFuncs
  input Variable var;
  input output FunctionTree funcs;
protected
  Binding binding;
  ComponentRef cref;
  InstNode node;
  Type ty;
algorithm
  () := match var
    case Variable.VARIABLE(ty = ty, binding = binding)
      algorithm
        // TODO: Collect functions from the component's type attributes.

        funcs := collectTypeFuncs(ty, funcs);

        // Collect functions used in the component's binding, if it has one.
        if Binding.isExplicitlyBound(binding) then
          funcs := collectExpFuncs(Binding.getTypedExp(binding), funcs);
        end if;
      then
        ();

  end match;
end collectComponentFuncs;

function collectTypeFuncs
  input Type ty;
  input output FunctionTree funcs;
algorithm
  () := match ty
    local
      InstNode con, de;

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
    case Expression.CALL()
      algorithm
        funcs := flattenFunction(Call.typedFunction(exp.call), funcs);
      then
        ();

    else ();
  end match;
end collectExpFuncs_traverse;

function flattenFunction
  input Function fn;
  input output FunctionTree funcs;
algorithm
  if not Function.isCollected(fn) then
    Function.collect(fn);
    funcs := FunctionTree.add(funcs, Function.name(fn), fn);
    funcs := collectClassFunctions(fn.node, funcs);

    for fn_der in fn.derivatives loop
      for der_fn in Function.getCachedFuncs(fn_der.derivativeFn) loop
        funcs := flattenFunction(der_fn, funcs);
      end for;
    end for;
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
