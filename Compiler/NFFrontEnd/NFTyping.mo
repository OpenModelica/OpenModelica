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

import NFBinding.Binding;
import NFComponent.Component;
import NFDimension.Dimension;
import NFEquation.Equation;
import NFInstance.Instance;
import NFInstanceTree.InstanceTree;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFPrefix.Prefix;
import NFStatement.Statement;

protected
import ComponentReference;
import Error;
import Expression;
import Inst = NFInst;
import Lookup = NFLookup;
import TypeCheck = NFTypeCheck;
import Types;

public
function typeClass
  input output InstNode classNode;
  input output InstanceTree tree;
        output DAE.Type ty;
protected
  Component top_inst;
algorithm
  tree := InstanceTree.pushHierarchy(Component.makeTopComponent(classNode), tree);
  (classNode, tree, ty) := typeClassNode(classNode, tree);
  tree := InstanceTree.popHierarchy(tree);
end typeClass;

function typeClassNode
  input output InstNode classNode;
  input output InstanceTree tree;
        output DAE.Type ty;
algorithm
  (classNode, tree, ty) := typeComponents(classNode, tree);
  (classNode, tree) := typeComponentBindings(classNode, tree);
  (classNode, tree) := typeSections(classNode, tree);
end typeClassNode;

function typeComponents
  input output InstNode classNode;
  input output InstanceTree tree;
        output DAE.Type ty;
protected
  Instance cls;
  array<Component> components;
  Component comp;
algorithm
  cls := InstNode.instance(classNode);

  ty := match cls
    case Instance.INSTANCED_CLASS(components = components)
      algorithm
        for i in 1:arrayLength(components) loop
          comp := components[i];
          (comp, tree) := typeComponent(comp, tree);
          components[i] := comp;
        end for;
      then
        makeComplexType(cls);

    case Instance.INSTANCED_BUILTIN()
      algorithm
        (ty, tree) := makeBuiltinType(cls, InstNode.name(classNode), tree);
      then
        ty;

    else
      algorithm
        Error.addInternalError("Typing.typeComponents got uninstantiated class " +
          InstNode.name(classNode) + "\n", Absyn.dummyInfo);
      then
        fail();
  end match;
end typeComponents;

protected
function typeComponent
  input output Component component;
  input output InstanceTree tree;
algorithm
  component := match component
    local
      array<Dimension> dims;
      Dimension dim;
      DAE.Type ty;
      list<DAE.Dimension> ty_dims;
      Binding binding;
      InstNode node;
      SourceInfo info;

    // An untyped component, type it.
    case Component.UNTYPED_COMPONENT(dimensions = dims, info = info)
      algorithm
        tree := InstanceTree.pushHierarchy(component, tree);
        ty_dims := {};
        for i in 1:arrayLength(dims) loop
          dim := dims[i];
          (dim, tree) := typeDimension(dim, tree, info);
          dims[i] := dim;
          ty_dims := Dimension.dimension(dim) :: ty_dims;
        end for;

        (node, tree, ty) := typeClassNode(component.classInst, tree);
        ty := Expression.liftArrayLeftList(ty, ty_dims);
        tree := InstanceTree.popHierarchy(tree);
      then
        Component.TYPED_COMPONENT(component.name, node, ty, component.binding, component.attributes);

    // A component that has already been typed, skip it.
    case Component.TYPED_COMPONENT() then component;

    case Component.EXTENDS_NODE()
      algorithm
        (node, tree) := typeComponents(component.node, tree);
        component.node := node;
      then
        component;

    case Component.COMPONENT_REF() then component;

    // Any other component shouldn't show up here, give an error.
    else
      algorithm
        Error.addInternalError("Typing.typeComponent got uninstantiated component " +
          Component.name(component), Absyn.dummyInfo);
      then
        fail();
  end match;
end typeComponent;

function typeDimension
  input output Dimension dimension;
  input output InstanceTree tree;
  input SourceInfo info;
algorithm
  dimension := match dimension
    local
      Absyn.Exp dim_exp;
      DAE.Exp typed_exp;
      DAE.Dimension dim;

    case Dimension.UNTYPED_DIM(dimension = dim_exp)
      algorithm
        (typed_exp, tree, _, _) := typeExp(dim_exp, tree, info);

        dim := match typed_exp
          case DAE.ICONST() then DAE.DIM_INTEGER(typed_exp.integer);
          else DAE.DIM_EXP(typed_exp);
        end match;
      then
        Dimension.TYPED_DIM(dim);

    else dimension;
  end match;
end typeDimension;

function typeComponentBindings
  input output InstNode classNode;
  input output InstanceTree tree;
protected
  Instance cls;
  array<Component> components;
  Component comp;
algorithm
  cls := InstNode.instance(classNode);

  _ := match cls
    case Instance.INSTANCED_CLASS(components = components)
      algorithm
        for i in 1:arrayLength(components) loop
          comp := components[i];
          (comp, tree) := typeComponentBinding(comp, tree);
          components[i] := comp;
        end for;
      then
        ();

    case Instance.INSTANCED_BUILTIN() then ();

    else
      algorithm
        Error.addInternalError("Typing.typeBindings got uninstantiated class " +
          InstNode.name(classNode) + "\n", Absyn.dummyInfo);
      then
        fail();
  end match;
end typeComponentBindings;

function typeComponentBinding
  input output Component component;
  input output InstanceTree tree;
algorithm
  component := match component
    local
      array<Dimension> dims;
      Dimension dim;
      DAE.Type ty;
      list<DAE.Dimension> ty_dims;
      Binding binding;
      InstNode node;

    // An untyped component, type it.
    case Component.TYPED_COMPONENT()
      algorithm
        //tree := InstanceTree.pushHierarchy(component, tree);
        (binding, tree) := typeBinding(component.binding, tree);

        if not referenceEq(binding, component.binding) then
          component.binding := binding;
        end if;
        //tree := InstanceTree.popHierarchy(tree);
      then
        component;

    case Component.EXTENDS_NODE()
      algorithm
        (node, tree) := typeComponentBindings(component.node, tree);
        component.node := node;
      then
        component;

    case Component.COMPONENT_REF() then component;

    // Any other component shouldn't show up here, give an error.
    else
      algorithm
        Error.addInternalError("Typing.typeBindings got uninstantiated component " +
          Component.name(component), Absyn.dummyInfo);
      then
        fail();
  end match;
end typeComponentBinding;

function typeBinding
  input output Binding binding;
  input output InstanceTree tree;
algorithm
  binding := match binding
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      DAE.Type ty;
      InstanceTree it;

    case Binding.UNTYPED_BINDING(bindingExp = aexp)
      algorithm
        it := InstanceTree.setCurrentScope(tree, binding.scope);
        (dexp, _, ty) := typeExp(aexp, it, binding.info);
      then
        Binding.TYPED_BINDING(dexp, ty, binding.propagatedDims, binding.info);

    case Binding.TYPED_BINDING() then binding;
    case Binding.UNBOUND() then binding;

    else
      algorithm
        Error.addInternalError("Typing.typeBinding got uninstantiated binding.",
          Absyn.dummyInfo);
      then
        fail();

  end match;
end typeBinding;

function typeSections
  input output InstNode classNode;
  input output InstanceTree tree;
protected
  Instance cls, typed_cls;
  array<Component> components;
  Component comp;
  list<Equation> eq, ieq;
  list<list<Statement>> alg, ialg;
algorithm
  cls := InstNode.instance(classNode);

  _ := match cls
    case Instance.INSTANCED_CLASS()
      algorithm
        tree := InstanceTree.setCurrentScope(tree, InstNode.index(classNode));
        //tree := InstanceTree.pushHierarchy(classNode, tree);
        (eq, tree) := typeEquations(cls.equations, tree);
        (ieq, tree) := typeEquations(cls.initialEquations, tree);
        (alg, tree) := typeAlgorithms(cls.algorithms, tree);
        (ialg, tree) := typeAlgorithms(cls.initialAlgorithms, tree);
        //tree := InstanceTree.popHierarchy(tree);
        typed_cls := Instance.setSections(eq, ieq, alg, ialg, cls);
        classNode := InstNode.setInstance(classNode, typed_cls);
      then
        ();

    case Instance.INSTANCED_BUILTIN() then ();

    else
      algorithm
        Error.addInternalError("Typing.typeSections got uninstantiated class " +
          InstNode.name(classNode) + "\n", Absyn.dummyInfo);
      then
        fail();
  end match;
end typeSections;

function typeEquations
  input output list<Equation> equations;
  input output InstanceTree tree;
algorithm
  (equations, tree) := List.mapFold(equations, typeEquation, tree);
end typeEquations;

function typeEquation
  input output Equation eq;
  input output InstanceTree tree;
algorithm
  eq := match eq
    local
      DAE.Exp e1, e2;
      DAE.Type ty1, ty2;

    case Equation.UNTYPED_EQUALITY()
      algorithm
        (e1, tree, ty1) := typeExp(eq.lhs, tree, eq.info);
        (e2, tree, ty2) := typeExp(eq.rhs, tree, eq.info);
      then
        Equation.EQUALITY(e1, e2, ty1, eq.info);

    else eq;
  end match;
end typeEquation;

function typeAlgorithms
  input output list<list<Statement>> algorithms;
  input output InstanceTree tree;
algorithm
  (algorithms, tree) := List.mapFold(algorithms, typeAlgorithm, tree);
end typeAlgorithms;

function typeAlgorithm
  input output list<Statement> alg;
  input output InstanceTree tree;
algorithm
  (alg, tree) := List.mapFold(alg, typeStatement, tree);
end typeAlgorithm;

function typeStatement
  input output Statement statement;
  input output InstanceTree tree;
algorithm

end typeStatement;

function makeComplexType
  input Instance classInst;
  output DAE.Type ty;
algorithm
  ty := DAE.T_COMPLEX_DEFAULT;
end makeComplexType;

function makeBuiltinType
  input Instance classInst;
  input String name;
        output DAE.Type ty;
  input output InstanceTree tree;
algorithm
  ty := match classInst
    local
      list<Modifier> type_mods;
      list<DAE.Var> type_attr;

    case Instance.INSTANCED_BUILTIN(attributes = type_mods)
      algorithm
        (type_attr, tree) := List.mapFold(type_mods, makeTypeAttribute, tree);
      then
        match name
          case "Real" then DAE.T_REAL(type_attr, DAE.emptyTypeSource);
          case "Integer" then DAE.T_INTEGER(type_attr, DAE.emptyTypeSource);
          case "Boolean" then DAE.T_BOOL(type_attr, DAE.emptyTypeSource);
          case "String" then DAE.T_STRING(type_attr, DAE.emptyTypeSource);
          else DAE.T_UNKNOWN_DEFAULT;
        end match;

    else DAE.T_UNKNOWN_DEFAULT;
  end match;
end makeBuiltinType;

function makeTypeAttribute
  input Modifier modifier;
        output DAE.Var attribute;
  input output InstanceTree tree;
algorithm
  attribute := match modifier
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      DAE.Binding binding;
      DAE.Const c;
      DAE.Type ty;

    case Modifier.MODIFIER(binding = Binding.UNTYPED_BINDING(bindingExp = aexp))
      algorithm
        (dexp, tree, ty, c) := typeExp(aexp, tree, modifier.info);
        binding := DAE.EQBOUND(dexp, NONE(), c, DAE.BindingSource.BINDING_FROM_START_VALUE());
      then
        DAE.TYPES_VAR(modifier.name, DAE.dummyAttrVar, ty, binding, NONE());

    else
      algorithm
        Error.addInternalError("Typing.makeTypeAttribute: Bad modifier",
            Absyn.dummyInfo);
      then
        fail();

  end match;
end makeTypeAttribute;

function typeExp
  input Absyn.Exp untypedExp;
        output DAE.Exp typedExp;
  input output InstanceTree tree;
        output DAE.Type ty;
        output DAE.Const variability;
  input SourceInfo info;

  import DAE.Const;
algorithm
  (typedExp, ty, variability) := match untypedExp
    local
      DAE.ComponentRef cref;
      DAE.Exp e1, e2;
      DAE.Type ty1, ty2;
      DAE.Const var1, var2;
      DAE.Operator op;

    case Absyn.Exp.INTEGER()
      then (DAE.Exp.ICONST(untypedExp.value), DAE.T_INTEGER_DEFAULT, Const.C_CONST());
    case Absyn.Exp.REAL()
      then (DAE.Exp.RCONST(stringReal(untypedExp.value)), DAE.T_REAL_DEFAULT, Const.C_CONST());
    case Absyn.Exp.STRING()
      then (DAE.Exp.SCONST(untypedExp.value), DAE.T_STRING_DEFAULT, Const.C_CONST());
    case Absyn.Exp.BOOL()
      then (DAE.Exp.BCONST(untypedExp.value), DAE.T_BOOL_DEFAULT, Const.C_CONST());

    case Absyn.Exp.CREF()
      algorithm
        (cref, tree, ty, variability) := typeCref(untypedExp.componentRef, tree, info);
      then
        (DAE.Exp.CREF(cref, ty), ty, variability);

    case Absyn.Exp.ARRAY()
      algorithm
        (typedExp, tree, ty, variability) := typeArray(untypedExp.arrayExp, tree, info);
      then
        (typedExp, ty, variability);

    case Absyn.Exp.BINARY()
      algorithm
        (e1, tree, ty1, var1) := typeExp(untypedExp.exp1, tree, info);
        (e2, tree, ty2, var2) := typeExp(untypedExp.exp2, tree, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkBinaryOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.LBINARY()
      algorithm
        (e1, tree, ty1, var1) := typeExp(untypedExp.exp1, tree, info);
        (e2, tree, ty2, var2) := typeExp(untypedExp.exp2, tree, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkLogicalBinaryOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.RELATION()
      algorithm
        (e1, tree, ty1, var1) := typeExp(untypedExp.exp1, tree, info);
        (e2, tree, ty2, var2) := typeExp(untypedExp.exp2, tree, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkRelationOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.CALL()
      algorithm
        _ := typeFunctionCall(untypedExp.function_, untypedExp.functionArgs, info);
      then
        fail();

    else
      algorithm
        Error.addInternalError("Typing.typeExp got unknown expression.",
            Absyn.dummyInfo);
      then
        fail();
  end match;
end typeExp;

function translateOperator
  input Absyn.Operator inOperator;
  output DAE.Operator outOperator;
algorithm
  outOperator := match(inOperator)
    case Absyn.ADD() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.SUB() then DAE.SUB(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.MUL() then DAE.MUL(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.DIV() then DAE.DIV(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.POW() then DAE.POW(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UPLUS() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UMINUS() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.ADD_EW() then DAE.ADD_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.SUB_EW() then DAE.SUB_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.MUL_EW() then DAE.MUL_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.DIV_EW() then DAE.DIV_ARR(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.POW_EW() then DAE.POW_ARR2(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UPLUS_EW() then DAE.ADD(DAE.T_UNKNOWN_DEFAULT);
    case Absyn.UMINUS_EW() then DAE.UMINUS(DAE.T_UNKNOWN_DEFAULT);
    // logical have boolean type
    case Absyn.AND() then DAE.AND(DAE.T_BOOL_DEFAULT);
    case Absyn.OR() then DAE.OR(DAE.T_BOOL_DEFAULT);
    case Absyn.NOT() then DAE.NOT(DAE.T_BOOL_DEFAULT);
    // relational have boolean type too
    case Absyn.LESS() then DAE.LESS(DAE.T_BOOL_DEFAULT);
    case Absyn.LESSEQ() then DAE.LESSEQ(DAE.T_BOOL_DEFAULT);
    case Absyn.GREATER() then DAE.GREATER(DAE.T_BOOL_DEFAULT);
    case Absyn.GREATEREQ() then DAE.GREATEREQ(DAE.T_BOOL_DEFAULT);
    case Absyn.EQUAL() then DAE.EQUAL(DAE.T_BOOL_DEFAULT);
    case Absyn.NEQUAL() then DAE.NEQUAL(DAE.T_BOOL_DEFAULT);
  end match;
end translateOperator;

function typeArray
  input list<Absyn.Exp> expressions;
        output DAE.Exp arrayExp;
  input output InstanceTree tree;
        output DAE.Type arrayType = DAE.T_UNKNOWN_DEFAULT;
        output DAE.Const variability = DAE.C_CONST();
  input SourceInfo info;
protected
  DAE.Exp dexp;
  list<DAE.Exp> expl = {};
  DAE.Const var;
  DAE.Type elem_ty;
algorithm
  for e in expressions loop
    (dexp, tree, elem_ty, var) := typeExp(e, tree, info);
    variability := Types.constAnd(var, variability);
    expl := dexp :: expl;
  end for;

  arrayType := Expression.liftArrayLeft(elem_ty, DAE.DIM_INTEGER(listLength(expl)));
  arrayExp := DAE.ARRAY(arrayType, not Types.isArray(elem_ty), listReverse(expl));
end typeArray;

function typeCref
  input Absyn.ComponentRef untypedCref;
        output DAE.ComponentRef typedCref;
  input output InstanceTree tree;
        output DAE.Type ty;
        output DAE.Const variability;
  input SourceInfo info;
protected
  Instance instance;
  Component component;
  Prefix prefix;
  InstanceTree it;
algorithm
  typedCref := translateCref(untypedCref);

  // Look up the first part of the cref in the scope the cref was declared in.
  // This checks that inherited crefs can be found in the scope they're
  // inherited from, as well as checking if the cref refers to a name in the
  // local scope or in an enclosing scope (i.e. an enclosing package).
  (_, _, it) := Lookup.lookupElementId(ComponentReference.crefFirstIdent(typedCref), tree);

  if InstanceTree.currentScopeIndex(it) <> InstanceTree.currentScopeIndex(tree) then
    // The name was found in an enclosing scope, prefix it with the scope.
    typedCref := Prefix.prefixCref(typedCref, InstanceTree.scopePrefix(it));
  else
    // The name was found in the local scope, prefix it with the instance hierarchy.
    typedCref := Prefix.prefixCref(typedCref, InstanceTree.hierarchyPrefix(tree));
  end if;

  // Look up the whole cref, and type the found component.
  (component, instance, _, tree) := Lookup.lookupCref(untypedCref, tree);
  //(component, tree) := Inst.instComponent(component, tree);
  (component, tree) := typeComponent(component, tree);
  Component.TYPED_COMPONENT(ty = ty) := component;

  variability := DAE.C_VAR();
end typeCref;

function translateCref
  input Absyn.ComponentRef absynCref;
  output DAE.ComponentRef daeCref;
algorithm
  daeCref := match absynCref
    local
      DAE.ComponentRef cref;

    case Absyn.CREF_IDENT()
      then DAE.CREF_IDENT(absynCref.name, DAE.T_UNKNOWN_DEFAULT, {});

    case Absyn.CREF_QUAL()
      algorithm
        cref := translateCref(absynCref.componentRef);
      then
        DAE.CREF_QUAL(absynCref.name, DAE.T_UNKNOWN_DEFAULT, {}, cref);

    case Absyn.CREF_FULLYQUALIFIED()
      algorithm
        cref := translateCref(absynCref.componentRef);
      then
        cref;

    case Absyn.WILD() then DAE.WILD();
    case Absyn.ALLWILD() then DAE.WILD();

  end match;
end translateCref;

function typeFunctionCall
  input Absyn.ComponentRef functionName;
  input Absyn.FunctionArgs functionArgs;
  input SourceInfo info;
protected
  String fn_name;
algorithm
  try
    _ := Absyn.crefToPath(functionName);
  else
    fn_name := Dump.printComponentRefStr(functionName);
    Error.addSourceMessageAndFail(Error.SUBSCRIPTED_FUNCTION_CALL, {fn_name}, info);
  end try;
end typeFunctionCall;

annotation(__OpenModelica_Interface="frontend");
end NFTyping;
