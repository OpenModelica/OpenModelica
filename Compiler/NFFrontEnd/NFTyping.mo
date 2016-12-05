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
import NFComponentNode.ComponentNode;
import NFDimension.Dimension;
import NFEquation.Equation;
import NFInstance.Instance;
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
import ClassInf;
import NFInstUtil;
import Static;
import NFFunc;

public
function typeClass
  input output InstNode classNode;
  input ComponentNode component;
        output DAE.Type ty;
protected
  Component top_inst;
algorithm
  (classNode, ty) := typeClassNode(classNode, component);
end typeClass;

function typeClassNode
  input output InstNode classNode;
  input ComponentNode component;
        output DAE.Type ty;
algorithm
  (classNode, ty) := typeComponents(classNode, component);
  (classNode) := typeComponentBindings(classNode);
  (classNode) := typeSections(classNode, component);
end typeClassNode;

function typeComponents
  input output InstNode classNode;
  input ComponentNode component;
        output DAE.Type ty;
protected
  Instance cls;
  array<ComponentNode> components;
algorithm
  cls := InstNode.instance(classNode);

  ty := match cls
    case Instance.INSTANCED_CLASS(components = components)
      algorithm
        for i in 1:arrayLength(components) loop
          components[i] := typeComponent(components[i]);
        end for;
      then
        makeComplexType(classNode, cls, component);

    case Instance.INSTANCED_BUILTIN()
      then makeBuiltinType(cls, component);

    else
      algorithm
        Error.addInternalError("Typing.typeComponents got uninstantiated class " +
          InstNode.name(classNode) + "\n", Absyn.dummyInfo);
      then
        fail();
  end match;
end typeComponents;

function typeComponent
  input output ComponentNode component;
protected
  Component c = ComponentNode.component(component);
  ComponentNode parent = ComponentNode.parent(component);
  array<Dimension> dims;
  list<DAE.Dimension> ty_dims;
  SourceInfo info;
  InstNode node;
  DAE.Type ty;
algorithm
  () := match c
    // An untyped component, type it.
    case Component.UNTYPED_COMPONENT(dimensions = dims, info = info)
      algorithm
        ty_dims := {};

        for i in 1:arrayLength(dims) loop
          dims[i] := typeDimension(dims[i], parent, info);
          ty_dims := Dimension.dimension(dims[i]) :: ty_dims;
        end for;

        (node, ty) := typeClassNode(c.classInst, component);
        ty := Expression.liftArrayLeftList(ty, ty_dims);
        component := ComponentNode.updateComponent(Component.setType(ty, c), component);
      then
        ();

    // A component that has already been typed, skip it.
    case Component.TYPED_COMPONENT() then ();

    case Component.EXTENDS_NODE()
      algorithm
        c.node := typeComponents(c.node, component);
        component := ComponentNode.updateComponent(c, component);
      then
        ();

    // A component that hasn't been instantiated. This might be a package
    // constant, in which case it should be instantiated and typed.
    case Component.COMPONENT_DEF()
      algorithm
        component := Inst.instComponent(component, ComponentNode.EMPTY_NODE(),
            InstNode.EMPTY_NODE());
        component := typeComponent(component);
      then
        ();

    // Any other component shouldn't show up here, give an error.
    else
      algorithm
        Error.addInternalError("Typing.typeComponent got uninstantiated component " +
          ComponentNode.name(component), Absyn.dummyInfo);
      then
        ();
  end match;
end typeComponent;

function typeDimension
  input output Dimension dimension;
  input ComponentNode component;
  input SourceInfo info;
algorithm
  dimension := match dimension
    local
      Absyn.Exp dim_exp;
      DAE.Exp typed_exp;
      DAE.Dimension dim;

    case Dimension.UNTYPED_DIM(dimension = dim_exp)
      algorithm
        typed_exp := typeExp(dim_exp, Component.Scope.RELATIVE_COMP(0),
          component, info);

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
protected
  Instance cls;
  array<ComponentNode> components;
  InstNode scope;
algorithm
  cls := InstNode.instance(classNode);

  _ := match cls
    case Instance.INSTANCED_CLASS(components = components)
      algorithm
        for i in 1:arrayLength(components) loop
          components[i] := typeComponentBinding(components[i]);
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
  input output ComponentNode component;
protected
  Component c = ComponentNode.component(component);
algorithm
  () := match c
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
        binding := typeBinding(c.binding, component);

        if not referenceEq(binding, c.binding) then
          c.binding := binding;
          component := ComponentNode.updateComponent(c, component);
        end if;
      then
        ();

    case Component.EXTENDS_NODE()
      algorithm
        c.node := typeComponentBindings(c.node);
        component := ComponentNode.updateComponent(c, component);
      then
        ();

    // Any other component shouldn't show up here, give an error.
    else
      algorithm
        Error.addInternalError("Typing.typeBindings got uninstantiated component " +
          ComponentNode.name(component), Absyn.dummyInfo);
      then
        fail();
  end match;
end typeComponentBinding;

function typeBinding
  input output Binding binding;
  input ComponentNode component;
algorithm
  binding := match binding
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      DAE.Type ty;
      DAE.Const variability;

    case Binding.UNTYPED_BINDING(bindingExp = aexp)
      algorithm
        (dexp, ty, variability) := typeExp(aexp, binding.scope, ComponentNode.parent(component), binding.info);
      then
        Binding.TYPED_BINDING(dexp, ty, variability, binding.propagatedDims, binding.info);

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
  input ComponentNode component;
protected
  Instance cls, typed_cls;
  array<Component> components;
  list<Equation> eq, ieq;
  list<list<Statement>> alg, ialg;
  InstNode scope;
algorithm
  cls := InstNode.instance(classNode);

  _ := match cls
    case Instance.INSTANCED_CLASS()
      algorithm
        eq := typeEquations(cls.equations, component);
        ieq := typeEquations(cls.initialEquations, component);
        alg := typeAlgorithms(cls.algorithms, component);
        ialg := typeAlgorithms(cls.initialAlgorithms, component);
        typed_cls := Instance.setSections(eq, ieq, alg, ialg, cls);
        classNode := InstNode.setInstance(typed_cls, classNode);
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
  input ComponentNode component;
algorithm
  equations := list(typeEquation(eq, component) for eq in equations);
end typeEquations;

function typeEquation
  input output Equation eq;
  input ComponentNode component;
algorithm
  eq := match eq
    local
      Absyn.Exp cond;
      DAE.ComponentRef cr1, cr2;
      Option<DAE.Exp> ope1;
      DAE.Exp e1, e2, e3;
      Option<DAE.Type> opty1;
      DAE.Type ty1, ty2;
      list<Equation> eqs1, body;
      list<tuple<DAE.Exp, list<Equation>>> tybrs;

    case Equation.UNTYPED_EQUALITY()
      algorithm
        (e1, ty1) := typeExp(eq.lhs, NFComponent.DEFAULT_SCOPE, component, eq.info);
        (e2, ty2) := typeExp(eq.rhs, NFComponent.DEFAULT_SCOPE, component, eq.info);
      then
        Equation.EQUALITY(e1, e2, ty1, eq.info);

    case Equation.UNTYPED_CONNECT()
      algorithm
        (cr1, ty1) := typeCref(eq.lhs, NFComponent.DEFAULT_SCOPE, component, eq.info);
        (cr2, ty2) := typeCref(eq.rhs, NFComponent.DEFAULT_SCOPE, component, eq.info);
      then
        Equation.CONNECT(cr1, ty1, cr2, ty2, eq.info);

    /*
    case Equation.UNTYPED_FOR()
      algorithm
        (Ope1, opty1) := typeExpOption(eq.range, NFComponent.DEFAULT_SCOPE, component, eq.info);
        eqs1 := list(typeEquation(eq, component) for eq in eq.body);

        if isSome(Ope1) then
        end if;
      then
        Equation.FOR(eq.name, 1, ty1, ty2, eq.info);
        */

    case Equation.UNTYPED_IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, NFComponent.DEFAULT_SCOPE, component, eq.info);
              eqs1 := list(typeEquation(beq, component) for beq in body);
            then (e1, eqs1);
          end match
        for br in eq.branches);
      then
        Equation.IF(tybrs, eq.info);

    case Equation.UNTYPED_WHEN()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, NFComponent.DEFAULT_SCOPE, component, eq.info);
              eqs1 := list(typeEquation(beq, component) for beq in body);
            then (e1, eqs1);
          end match
        for br in eq.branches);
      then
        Equation.WHEN(tybrs, eq.info);

    case Equation.UNTYPED_ASSERT()
      algorithm
        (e1) := typeExp(eq.condition, NFComponent.DEFAULT_SCOPE, component, eq.info);
        (e2) := typeExp(eq.message, NFComponent.DEFAULT_SCOPE, component, eq.info);
        (e3) := typeExp(eq.level, NFComponent.DEFAULT_SCOPE, component, eq.info);
      then
        Equation.ASSERT(e1, e2, e3, eq.info);

    case Equation.UNTYPED_TERMINATE()
      algorithm
        (e1) := typeExp(eq.message, NFComponent.DEFAULT_SCOPE, component, eq.info);
      then
        Equation.TERMINATE(e1, eq.info);

    case Equation.UNTYPED_REINIT()
      algorithm
        (cr1, ty1) := typeCref(eq.cref, NFComponent.DEFAULT_SCOPE, component, eq.info);
        (e1) := typeExp(eq.reinitExp, NFComponent.DEFAULT_SCOPE, component, eq.info);
      then
        Equation.REINIT(cr1, e1, eq.info);

    case Equation.UNTYPED_NORETCALL()
      algorithm
        (e1) := typeExp(eq.exp, NFComponent.DEFAULT_SCOPE, component, eq.info);
      then
        Equation.NORETCALL(e1, eq.info);

    else eq;
  end match;
end typeEquation;

function typeAlgorithms
  input output list<list<Statement>> algorithms;
  input ComponentNode component;
algorithm
  algorithms := list(typeAlgorithm(alg, component) for alg in algorithms);
end typeAlgorithms;

function typeAlgorithm
  input output list<Statement> alg;
  input ComponentNode component;
algorithm
  alg := list(typeStatement(stmt, component) for stmt in alg);
end typeAlgorithm;

function typeStatement
  input output Statement st;
  input ComponentNode component;
algorithm
  st := match st
    local
      Absyn.Exp cond;
      DAE.ComponentRef cr1, cr2;
      Option<DAE.Exp> ope1;
      DAE.Exp e1, e2, e3;
      Option<DAE.Type> opty1;
      DAE.Type ty1, ty2, ty3;
      list<Statement> sts1, body;
      list<tuple<DAE.Exp, list<Statement>>> tybrs;

    case Statement.UNTYPED_ASSIGNMENT()
      algorithm
        (e1, ty1) := typeExp(st.lhs, NFComponent.DEFAULT_SCOPE, component, st.info);
        (e2, ty2) := typeExp(st.rhs, NFComponent.DEFAULT_SCOPE, component, st.info);
      then
        Statement.ASSIGNMENT(e1, e2, st.info);

    case Statement.UNTYPED_IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, NFComponent.DEFAULT_SCOPE, component, st.info);
              sts1 := list(typeStatement(bst, component) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.IF(tybrs, st.info);

    case Statement.UNTYPED_WHEN()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, NFComponent.DEFAULT_SCOPE, component, st.info);
              sts1 := list(typeStatement(bst, component) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.WHEN(tybrs, st.info);

    case Statement.UNTYPED_ASSERT()
      algorithm
        (e1) := typeExp(st.condition, NFComponent.DEFAULT_SCOPE, component, st.info);
        (e2) := typeExp(st.message, NFComponent.DEFAULT_SCOPE, component, st.info);
        (e3) := typeExp(st.level, NFComponent.DEFAULT_SCOPE, component, st.info);
      then
        Statement.ASSERT(e1, e2, e3, st.info);

    case Statement.UNTYPED_TERMINATE()
      algorithm
        (e1) := typeExp(st.message, NFComponent.DEFAULT_SCOPE, component, st.info);
      then
        Statement.TERMINATE(e1, st.info);

    case Statement.UNTYPED_REINIT()
      algorithm
        (cr1, ty1) := typeCref(st.cref, NFComponent.DEFAULT_SCOPE, component, st.info);
        (e1) := typeExp(st.reinitExp, NFComponent.DEFAULT_SCOPE, component, st.info);
      then
        Statement.REINIT(cr1, e1, st.info);

    case Statement.UNTYPED_NORETCALL()
      algorithm
        (e1) := typeExp(st.exp, NFComponent.DEFAULT_SCOPE, component, st.info);
      then
        Statement.NORETCALL(e1, st.info);

    case Statement.UNTYPED_WHILE()
      algorithm
        (e1) := typeExp(st.condition, NFComponent.DEFAULT_SCOPE, component, st.info);
        sts1 := list(typeStatement(bst, component) for bst in st.body);
      then
        Statement.WHILE(e1, sts1, st.info);

    case Statement.FAILURE()
      algorithm
        sts1 := list(typeStatement(bst, component) for bst in st.body);
      then
        Statement.FAILURE(sts1, st.info);


    else st;
  end match;
end typeStatement;

function makeComplexType
  input InstNode classNode;
  input Instance classInst;
  input ComponentNode component;
  output DAE.Type ty;
protected
  array<ComponentNode> components;
  ClassInf.State s;
  SCode.Element el;
  SCode.Restriction r;
  Absyn.Path p;
  list<DAE.Var> varLst = {};
  ComponentNode cn;
  Component c;
  DAE.Type t;
  DAE.Binding binding;
algorithm
  Instance.INSTANCED_CLASS(components = components) := classInst;

  for i in arrayLength(components):-1:1 loop
     cn := components[i];
     c := ComponentNode.component(cn);
     t := Component.getType(c);

     varLst := DAE.TYPES_VAR(
                 ComponentNode.name(cn),
                 Component.attr2DaeAttr(Component.getAttributes(c)),
                 t,
                 DAE.UNBOUND(), // TODO FIXME, do we need the binding?
                 NONE())::varLst;
  end for;

  el := InstNode.definition(classNode);
  r := SCode.getClassRestriction(el);
  p := InstNode.path(classNode);
  s := ClassInf.start(r, p);
  ty := DAE.T_COMPLEX(s, varLst, NONE(), {p});
end makeComplexType;

function makeBuiltinType
  input Instance classInst;
  input ComponentNode component;
  output DAE.Type ty;
algorithm
  ty := match classInst
    local
      String name;
      list<Modifier> type_mods;
      list<DAE.Var> type_attr;

    case Instance.INSTANCED_BUILTIN(name = name, attributes = type_mods)
      algorithm
        type_attr := list(makeTypeAttribute(tm, component) for tm in type_mods);
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
  input ComponentNode component;
  output DAE.Var attribute;
algorithm
  attribute := match modifier
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      DAE.Binding binding;
      DAE.Const c;
      DAE.Type ty;
      Binding mod_binding;

    case Modifier.MODIFIER(binding = mod_binding as Binding.UNTYPED_BINDING(bindingExp = aexp))
      algorithm
        (dexp, ty, c) := typeExp(aexp, mod_binding.scope, component, modifier.info);
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
  input Component.Scope scope;
  input ComponentNode component;
  input SourceInfo info;
  output DAE.Exp typedExp;
  output DAE.Type ty;
  output DAE.Const variability;

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
        (cref, ty, variability) := typeCref(untypedExp.componentRef, scope, component, info);
      then
        (DAE.Exp.CREF(cref, ty), ty, variability);

    case Absyn.Exp.ARRAY()
      algorithm
        (typedExp, ty, variability) := typeArray(untypedExp.arrayExp, scope, component, info);
      then
        (typedExp, ty, variability);

    case Absyn.Exp.RANGE()
      algorithm
        (typedExp, ty, variability) := typeRange(untypedExp.start, untypedExp.step, untypedExp.stop, scope, component, info);
      then
        (typedExp, ty, variability);

    case Absyn.Exp.BINARY()
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp1, scope, component, info);
        (e2, ty2, var2) := typeExp(untypedExp.exp2, scope, component, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkBinaryOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.UNARY()  // Unary +, -
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp, scope, component, info);
        op := translateOperator(untypedExp.op);
        (typedExp, ty) := TypeCheck.checkUnaryOperation(e1, ty1, op);
      then
        (typedExp, ty, var1);

    case Absyn.Exp.LBINARY()
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp1, scope, component, info);
        (e2, ty2, var2) := typeExp(untypedExp.exp2, scope, component, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkLogicalBinaryOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.LUNARY()  // Unary not
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp, scope, component, info);
        op := translateOperator(untypedExp.op);
        (typedExp, ty) := TypeCheck.checkLogicalUnaryOperation(e1, ty1, op);
      then
        (typedExp, ty, var1);

    case Absyn.Exp.RELATION()
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp1, scope, component, info);
        (e2, ty2, var2) := typeExp(untypedExp.exp2, scope, component, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkRelationOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.CALL()
      algorithm
        (typedExp, ty, variability) := NFFunc.typeFunctionCall(untypedExp.function_, untypedExp.functionArgs, scope, component, info);
      then
        (typedExp, ty, variability);

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
  input Component.Scope scope;
  input ComponentNode component;
  input SourceInfo info;
  output DAE.Exp arrayExp;
  output DAE.Type arrayType = DAE.T_UNKNOWN_DEFAULT;
  output DAE.Const variability = DAE.C_CONST();
protected
  DAE.Exp dexp;
  list<DAE.Exp> expl = {};
  DAE.Const var;
  DAE.Type elem_ty;
algorithm
  for e in expressions loop
    (dexp, elem_ty, var) := typeExp(e, scope, component, info);
    variability := Types.constAnd(var, variability);
    expl := dexp :: expl;
  end for;

  arrayType := Expression.liftArrayLeft(elem_ty, DAE.DIM_INTEGER(listLength(expl)));
  arrayExp := DAE.ARRAY(arrayType, not Types.isArray(elem_ty), listReverse(expl));
end typeArray;

function typeExps
  input list<Absyn.Exp> expressions;
  input Component.Scope scope;
  input ComponentNode component;
  input SourceInfo info;
  output list<DAE.Exp> daeExps = {};
  output list<DAE.Type> daeTys = {};
  output list<DAE.Const> daeVrs = {};
protected
  DAE.Exp dexp;
  DAE.Const var;
  DAE.Type elem_ty;
algorithm
  for e in expressions loop
    (dexp, elem_ty, var) := typeExp(e, scope, component, info);

    daeExps := dexp :: daeExps;
    daeTys := elem_ty :: daeTys;
    daeVrs := var :: daeVrs;

  end for;
  daeExps := listReverse(daeExps);
  daeTys := listReverse(daeTys);
  daeVrs := listReverse(daeVrs);
end typeExps;

function typeRange
  input Absyn.Exp inStart;
  input Option<Absyn.Exp> inStep;
  input Absyn.Exp inEnd;
  input Component.Scope scope;
  input ComponentNode component;
  input SourceInfo info;
  output DAE.Exp outRange;
  output DAE.Type outType;
  output DAE.Const variability;
protected
  Absyn.Exp astep;
  DAE.Exp dstart, dend, dstep, dimexp;
  Option<DAE.Exp> dopt_step;
  DAE.Type strtype, endtype, stptype;
  Option<DAE.Type> optsteptype;
  DAE.Const var;
  Boolean numeric, isreal, enum;
algorithm

  (dstart, strtype, variability) := typeExp(inStart,scope,component,info);
  (dend, endtype, var) := typeExp(inEnd,scope,component,info);
  variability := Types.constAnd(var, variability);

  if isSome(inStep) then
    SOME(astep) := inStep;
    (dstep, stptype, var) := typeExp(astep,scope,component,info);
    variability := Types.constAnd(var, variability);

    dopt_step := SOME(dstep);
    outType := NFTypeCheck.getRangeType(dstart, strtype, dopt_step, SOME(stptype), dend, endtype, info);
  else
    dopt_step := NONE();
    outType := NFTypeCheck.getRangeType(dstart, strtype, dopt_step, NONE(), dend, endtype, info);
  end if;

  outRange := DAE.RANGE(outType, dstart, dopt_step, dend);
end typeRange;

function typeCref
  input Absyn.ComponentRef untypedCref;
  input Component.Scope scope;
  input ComponentNode component;
  input SourceInfo info;
  output DAE.ComponentRef typedCref;
  output DAE.Type ty;
  output DAE.Const variability;
protected
  ComponentNode node;
  Prefix prefix;
  Component.Attributes attr;
  DAE.VarKind vr;
algorithm

  // Look up the whole cref, and type the found component.
  (node, prefix) := Lookup.lookupComponent(untypedCref, scope, component, info);
  node := typeComponent(node);

  typedCref := translateCref(untypedCref, node, scope, component, info);
  typedCref := Prefix.prefixCref(typedCref, prefix);
  ty := NFTypeCheck.getCrefType(typedCref);

  Component.TYPED_COMPONENT(attributes = attr) := ComponentNode.component(node);
  Component.ATTRIBUTES(variability = vr) := attr;
  variability := NFTyping.variabilityToConst(NFInstUtil.daeToSCodeVariability(vr));

end typeCref;

function translateCref
  input Absyn.ComponentRef absynCref;
  input ComponentNode crefComp;
  input Component.Scope scope;
  input ComponentNode topComp;
  input SourceInfo info;
  output DAE.ComponentRef daeCref;
  output ComponentNode preCrefComp;
algorithm
  () := match absynCref
    local
      DAE.ComponentRef cref;
      DAE.Type ty;
      list<DAE.Subscript> subs;

    case Absyn.CREF_IDENT()
      algorithm
        ty := Component.getType(ComponentNode.component(crefComp));
        subs := list(typeSubscript(sub,scope,topComp,info) for sub in absynCref.subscripts);
        daeCref := DAE.CREF_IDENT(absynCref.name, ty, subs);
        preCrefComp := ComponentNode.parent(crefComp);
      then ();

    case Absyn.CREF_QUAL()
      algorithm
        (cref, preCrefComp):= translateCref(absynCref.componentRef,crefComp,scope,topComp,info);
        ty := Component.getType(ComponentNode.component(preCrefComp));
        subs := list(typeSubscript(sub,scope,topComp,info) for sub in absynCref.subscripts);
        daeCref := DAE.CREF_QUAL(absynCref.name, ty, subs, cref);
        preCrefComp := ComponentNode.parent(preCrefComp);
      then ();

    case Absyn.CREF_FULLYQUALIFIED()
      algorithm
        (daeCref,preCrefComp) := translateCref(absynCref.componentRef,crefComp,scope,topComp,info);
      then
        ();

    /*
    case Absyn.WILD() then DAE.WILD();
    case Absyn.ALLWILD() then DAE.WILD();
    */
    else
      algorithm
        Error.addInternalError("Typing.translateCref failed. \n", Absyn.dummyInfo);
      then
        fail();

  end match;
end translateCref;

function typeSubscript
  input Absyn.Subscript inSub;
  input Component.Scope scope;
  input ComponentNode component;
  input SourceInfo info;
  output DAE.Subscript outSub;
algorithm
  outSub := match inSub
    local
      DAE.Exp exp;
      DAE.Type ty;
      Boolean valid;
    case Absyn.SUBSCRIPT()
      algorithm
        exp := typeExp(inSub.subscript,scope,component,info);
        ty := Expression.typeof(exp);
        ty := NFTypeCheck.underlyingType(ty);
        valid := NFTypeCheck.isInteger(ty) or NFTypeCheck.isBoolean(ty) or NFTypeCheck.isEnum(ty);
        if not valid then
          Error.addInternalError("Subscript is not a valid type. \n", info);
          fail();
        end if;
      then DAE.INDEX(exp);

    case Absyn.NOSUB() then DAE.WHOLEDIM();
  end match;
end typeSubscript;

public function variabilityToConst "translates SCode.Variability to DAE.Const"
  input SCode.Variability variability;
  output DAE.Const const;
algorithm
  const := match variability
    case SCode.VAR() then DAE.C_VAR();
    case SCode.DISCRETE() then DAE.C_VAR();
    case SCode.PARAM() then DAE.C_PARAM();
    case SCode.CONST() then DAE.C_CONST();
    else then DAE.C_UNKNOWN();
  end match;
end variabilityToConst;

annotation(__OpenModelica_Interface="frontend");
end NFTyping;
