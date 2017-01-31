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
import NFEquation.Equation;
import NFClass.Class;
import NFExpression.Expression;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFPrefix.Prefix;
import NFPrefix.PrefixType;
import NFStatement.Statement;
import NFType.Type;
import Operator = NFOperator;

protected
import Inst = NFInst;
import Lookup = NFLookup;
import TypeCheck = NFTypeCheck;
import Types;
import ClassInf;
import InstUtil = NFInstUtil;
import Func = NFFunc;
import NFClass.ClassTree;

public
function typeClass
  input output InstNode classNode;
        output Type ty;
algorithm
  (classNode, ty) := typeComponents(classNode);
  classNode := typeBindings(classNode);
  classNode := typeSections(classNode);
end typeClass;

function typeComponents
  input output InstNode classNode;
  input InstNode scope = classNode;
        output Type ty;
protected
  Class cls;
  array<InstNode> components;
algorithm
  cls := InstNode.getClass(classNode);

  ty := match cls
    case Class.INSTANCED_CLASS(components = components)
      algorithm
        for i in 1:arrayLength(components) loop
          if InstNode.isComponent(components[i]) then
            components[i] := typeComponent(components[i]);
          else
            components[i] := typeComponents(components[i]);
          end if;
        end for;
      then
        Type.COMPLEX(classNode);

    case Class.INSTANCED_BUILTIN()
      then cls.ty;

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated class " +
          InstNode.name(classNode));
      then
        fail();
  end match;
end typeComponents;

function typeComponent
  input output InstNode component;
protected
  Component c = InstNode.component(component);
  InstNode parent = InstNode.parent(component);
  array<Dimension> dims;
  SourceInfo info;
  InstNode node;
  Type ty;
algorithm
  () := match c
    // An untyped component, type it.
    case Component.UNTYPED_COMPONENT(dimensions = dims)
      algorithm
        info := InstNode.info(component);

        for i in 1:arrayLength(dims) loop
          dims[i] := typeDimension(dims[i], parent, info);
        end for;

        (node, ty) := typeComponents(c.classInst, component);
        ty := Type.liftArrayLeftList(ty, arrayList(dims));
        component := InstNode.updateComponent(Component.setType(ty, c), component);
      then
        ();

    // A component that has already been typed, skip it.
    case Component.TYPED_COMPONENT() then ();

    // A component that hasn't been instantiated. This might be a package
    // constant, in which case it should be instantiated and typed.
    case Component.COMPONENT_DEF()
      algorithm
        component := Inst.instComponent(component, InstNode.EMPTY_NODE(),
            InstNode.EMPTY_NODE());
        component := typeComponent(component);
      then
        ();

    // Any other component shouldn't show up here, give an error.
    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated component " +
          InstNode.name(component));
      then
        ();
  end match;
end typeComponent;

function typeDimension
  input output Dimension dimension;
  input InstNode scope;
  input SourceInfo info;
algorithm
  dimension := match dimension
    local
      Absyn.Exp dim_exp;
      Expression typed_exp;
      Class cls;

    case Dimension.UNTYPED(dimension = dim_exp)
      algorithm
        typed_exp := typeExp(dim_exp, scope, info, true);
      then
        Dimension.fromTypedExp(typed_exp);

    else dimension;
  end match;
end typeDimension;

function typeBindings
  input output InstNode classNode;
  input InstNode scope = classNode;
protected
  Class cls;
  array<InstNode> components;
algorithm
  cls := InstNode.getClass(classNode);

  _ := match cls
    case Class.INSTANCED_CLASS(components = components)
      algorithm
        for i in 1:arrayLength(components) loop
          if InstNode.isComponent(components[i]) then
            typeComponentBinding(components[i], scope);
          else
            components[i] := typeBindings(components[i]);
          end if;
        end for;
      then
        ();

    case Class.INSTANCED_BUILTIN()
      algorithm
        cls.attributes := typeTypeAttributes(cls.attributes, cls.ty, scope);
        classNode := InstNode.updateClass(cls, classNode);
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated class " +
          InstNode.name(classNode));
      then
        fail();
  end match;
end typeBindings;

function typeComponentBinding
  input InstNode component;
  input InstNode scope;
protected
  Component c = InstNode.component(component);
algorithm
  () := match c
    local
      array<Dimension> dims;
      Dimension dim;
      Type ty;
      list<DAE.Dimension> ty_dims;
      Binding binding;
      InstNode node;

    // An untyped component, type it.
    case Component.TYPED_COMPONENT()
      algorithm
        binding := typeBinding(c.binding, scope);

        if not referenceEq(binding, c.binding) then
          c.binding := binding;
          InstNode.updateComponent(c, component);
        end if;

        typeBindings(c.classInst, component);
      then
        ();

    // Any other component shouldn't show up here, give an error.
    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated component " +
          InstNode.name(component));
      then
        fail();
  end match;
end typeComponentBinding;

function typeBinding
  input output Binding binding;
  input InstNode scope;
algorithm
  binding := match binding
    local
      Absyn.Exp aexp;
      Expression exp;
      Type ty;
      DAE.Const variability;

    case Binding.UNTYPED_BINDING(bindingExp = aexp)
      algorithm
        (exp, ty, variability) := typeExp(aexp, binding.scope, binding.info);
      then
        Binding.TYPED_BINDING(exp, ty, variability, binding.propagatedDims, binding.info);

    case Binding.TYPED_BINDING() then binding;
    case Binding.UNBOUND() then binding;

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated binding");
      then
        fail();

  end match;
end typeBinding;

function typeSections
  input output InstNode classNode;
  input InstNode scope = classNode;
protected
  Class cls, typed_cls;
  array<InstNode> components;
  list<Equation> eq, ieq;
  list<list<Statement>> alg, ialg;
algorithm
  cls := InstNode.getClass(classNode);

  _ := match cls
    case Class.INSTANCED_CLASS(components = components)
      algorithm
        eq := typeEquations(cls.equations, scope);
        ieq := typeEquations(cls.initialEquations, scope);
        alg := typeAlgorithms(cls.algorithms, scope);
        ialg := typeAlgorithms(cls.initialAlgorithms, scope);
        typed_cls := Class.setSections(eq, ieq, alg, ialg, cls);

        for i in 1:arrayLength(components) loop
          if InstNode.isComponent(components[i]) then
            typeSections(InstNode.classScope(components[i]), components[i]);
          else
            components[i] := typeSections(components[i]);
          end if;
        end for;

        classNode := InstNode.updateClass(typed_cls, classNode);
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

function typeEquations
  input output list<Equation> equations;
  input InstNode scope;
algorithm
  equations := list(typeEquation(eq, scope) for eq in equations);
end typeEquations;

function typeEquation
  input output Equation eq;
  input InstNode scope;
algorithm
  eq := match eq
    local
      Absyn.Exp cond;
      Option<Expression> ope1;
      Expression e1, e2, e3;
      Option<Type> opty1;
      Type ty1, ty2;
      list<Equation> eqs1, body;
      list<tuple<Expression, list<Equation>>> tybrs;
      InstNode fakeComponent;
      array<InstNode> components;
      Class cls;
      Integer index;
      ClassTree.Tree elements;

    case Equation.UNTYPED_EQUALITY()
      algorithm
        (e1, ty1) := typeExp(eq.lhs, scope, eq.info);
        (e2,_) := typeExp(eq.rhs, scope, eq.info);
      then
        Equation.EQUALITY(e1, e2, ty1, eq.info);

    case Equation.UNTYPED_CONNECT()
      algorithm
        (e1, ty1) := typeCref(eq.lhs, scope, eq.info);
        (e2, ty2) := typeCref(eq.rhs, scope, eq.info);
      then
        Equation.CONNECT(e1, ty1, e2, ty2, eq.info);

    case Equation.UNTYPED_FOR()
      algorithm
        ope1 := NONE();
        if (isSome(eq.range)) then
          (e1, ty1) := typeExp(Util.getOption(eq.range), scope, eq.info);
          ty1 := Type.arrayElementType(ty1);
          ope1 := SOME(e1);
        end if;
        // we need to add the iterator to the component scope!
        fakeComponent := InstNode.newComponent(
           SCode.COMPONENT(
              eq.name,
              SCode.defaultPrefixes,
              SCode.defaultVarAttr,
              Absyn.TPATH(Absyn.IDENT("Integer"), NONE()),
              SCode.NOMOD(),
              SCode.COMMENT(NONE(), NONE()),
              NONE(),
              eq.info), scope);
        fakeComponent := Inst.instComponent(fakeComponent, scope, scope);
        fakeComponent := typeComponent(fakeComponent);
        cls := InstNode.getClass(scope);
        components := Class.components(cls);
        index := arrayLength(components) + 1;
        components := listArray(listAppend(arrayList(components), {fakeComponent}));
        cls := Class.setComponents(components, cls);
        elements := Class.elements(cls);
        elements :=  ClassTree.add(elements, eq.name,
              ClassTree.Entry.COMPONENT(0, index), ClassTree.addConflictReplace);
        cls := Class.setElements(elements, cls);
        fakeComponent := InstNode.updateClass(cls, scope);
        eqs1 := list(typeEquation(beq, fakeComponent) for beq in eq.body);
      then
        Equation.FOR(eq.name, 1, ty1, ope1, eqs1, eq.info);

    case Equation.UNTYPED_IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, scope, eq.info);
              eqs1 := list(typeEquation(beq, scope) for beq in body);
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
              e1 := typeExp(cond, scope, eq.info);
              eqs1 := list(typeEquation(beq, scope) for beq in body);
            then (e1, eqs1);
          end match
        for br in eq.branches);
      then
        Equation.WHEN(tybrs, eq.info);

    case Equation.UNTYPED_ASSERT()
      algorithm
        (e1) := typeExp(eq.condition, scope, eq.info);
        (e2) := typeExp(eq.message, scope, eq.info);
        (e3) := typeExp(eq.level, scope, eq.info);
      then
        Equation.ASSERT(e1, e2, e3, eq.info);

    case Equation.UNTYPED_TERMINATE()
      algorithm
        (e1) := typeExp(eq.message, scope, eq.info);
      then
        Equation.TERMINATE(e1, eq.info);

    case Equation.UNTYPED_REINIT()
      algorithm
        (e1,_) := typeCref(eq.cref, scope, eq.info);
        (e2) := typeExp(eq.reinitExp, scope, eq.info);
      then
        Equation.REINIT(e1, e2, eq.info);

    case Equation.UNTYPED_NORETCALL()
      algorithm
        (e1) := typeExp(eq.exp, scope, eq.info);
      then
        Equation.NORETCALL(e1, eq.info);

    else eq;
  end match;
end typeEquation;

function typeAlgorithms
  input output list<list<Statement>> algorithms;
  input InstNode scope;
algorithm
  algorithms := list(typeAlgorithm(alg, scope) for alg in algorithms);
end typeAlgorithms;

function typeAlgorithm
  input output list<Statement> alg;
  input InstNode scope;
algorithm
  alg := list(typeStatement(stmt, scope) for stmt in alg);
end typeAlgorithm;

function typeStatement
  input output Statement st;
  input InstNode scope;
algorithm
  st := match st
    local
      Absyn.Exp cond;
      Option<Expression> ope1;
      Expression e1, e2, e3;
      Option<Type> opty1;
      Type ty1, ty2, ty3;
      list<Statement> sts1, body;
      list<tuple<Expression, list<Statement>>> tybrs;

    case Statement.UNTYPED_ASSIGNMENT()
      algorithm
        (e1,_) := typeExp(st.lhs, scope, st.info);
        (e2,_) := typeExp(st.rhs, scope, st.info);
      then
        Statement.ASSIGNMENT(e1, e2, st.info);

    case Statement.UNTYPED_IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, scope, st.info);
              sts1 := list(typeStatement(bst, scope) for bst in body);
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
              e1 := typeExp(cond, scope, st.info);
              sts1 := list(typeStatement(bst, scope) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.WHEN(tybrs, st.info);

    case Statement.UNTYPED_ASSERT()
      algorithm
        (e1) := typeExp(st.condition, scope, st.info);
        (e2) := typeExp(st.message, scope, st.info);
        (e3) := typeExp(st.level, scope, st.info);
      then
        Statement.ASSERT(e1, e2, e3, st.info);

    case Statement.UNTYPED_TERMINATE()
      algorithm
        (e1) := typeExp(st.message, scope, st.info);
      then
        Statement.TERMINATE(e1, st.info);

    case Statement.UNTYPED_REINIT()
      algorithm
        (e1,_) := typeCref(st.cref, scope, st.info);
        (e2) := typeExp(st.reinitExp, scope, st.info);
      then
        Statement.REINIT(e1, e2, st.info);

    case Statement.UNTYPED_NORETCALL()
      algorithm
        (e1) := typeExp(st.exp, scope, st.info);
      then
        Statement.NORETCALL(e1, st.info);

    case Statement.UNTYPED_WHILE()
      algorithm
        (e1) := typeExp(st.condition, scope, st.info);
        sts1 := list(typeStatement(bst, scope) for bst in st.body);
      then
        Statement.WHILE(e1, sts1, st.info);

    case Statement.FAILURE()
      algorithm
        sts1 := list(typeStatement(bst, scope) for bst in st.body);
      then
        Statement.FAILURE(sts1, st.info);


    else st;
  end match;
end typeStatement;

//function makeComplexType
//  input InstNode classNode;
//  input Class classInst;
//  input InstNode scope;
//  output Type ty;
//protected
//  array<InstNode> components;
//  ClassInf.State s;
//  SCode.Element el;
//  SCode.Restriction r;
//  Absyn.Path p;
//  list<DAE.Var> varLst = {};
//  InstNode cn;
//  Component c;
//  Type t;
//  DAE.Binding binding;
//algorithm
//  Class.INSTANCED_CLASS(components = components) := classInst;
//
//  for i in arrayLength(components):-1:1 loop
//    cn := components[i];
//
//    if InstNode.isComponent(cn) then
//      c := InstNode.component(cn);
//      t := Component.getType(c);
//
//      varLst := DAE.TYPES_VAR(
//                  InstNode.name(cn),
//                  Component.attr2DaeAttr(Component.getAttributes(c)),
//                  Type.toDAE(t),
//                  DAE.UNBOUND(), // TODO FIXME, do we need the binding?
//                  NONE())::varLst;
//    end if;
//  end for;
//
//  el := InstNode.definition(classNode);
//  r := SCode.getClassRestriction(el);
//  p := InstNode.path(classNode);
//  s := ClassInf.start(r, p);
//  //ty := DAE.T_COMPLEX(s, varLst, NONE(), {p});
//  ty := Type.COMPLEX();
//end makeComplexType;

function typeTypeAttributes
  input output list<Modifier> attributes;
  input Type ty;
  input InstNode scope;
algorithm
  attributes := list(typeTypeAttribute(a, scope) for a in attributes);

  _ := match ty
    case Type.REAL() then checkRealAttributes(attributes);
    case Type.INTEGER() then checkIntAttributes(attributes);
    case Type.BOOLEAN() then checkBoolAttributes(attributes);
    case Type.STRING() then checkStringAttributes(attributes);
    case Type.ENUMERATION() then checkEnumAttributes(attributes);
    else
      algorithm
        assert(false, getInstanceName() + " got unknown type");
      then
        fail();
  end match;
end typeTypeAttributes;

function typeTypeAttribute
  input output Modifier attribute;
  input InstNode scope;
protected
  String name;
  Binding binding;
algorithm
  name := Modifier.name(attribute);
  binding := Modifier.binding(attribute);
  binding := typeBinding(binding, scope);
  attribute := Modifier.setBinding(binding, attribute);
end typeTypeAttribute;

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

function typeExp
  input Absyn.Exp untypedExp;
  input InstNode scope;
  input SourceInfo info;
  input Boolean allowTypename = false;
  output Expression typedExp;
  output Type ty;
  output DAE.Const variability;

  import DAE.Const;
algorithm
  (typedExp, ty, variability) := match untypedExp
    local
      Expression e1, e2, e3;
      Type ty1, ty2, ty3;
      DAE.Const var1, var2, var3;
      Operator op;

    case Absyn.Exp.INTEGER()
      then (Expression.INTEGER(untypedExp.value), Type.INTEGER(), Const.C_CONST());
    case Absyn.Exp.REAL()
      then (Expression.REAL(stringReal(untypedExp.value)), Type.REAL(), Const.C_CONST());
    case Absyn.Exp.STRING()
      then (Expression.STRING(untypedExp.value), Type.STRING(), Const.C_CONST());
    case Absyn.Exp.BOOL()
      then (Expression.BOOLEAN(untypedExp.value), Type.BOOLEAN(), Const.C_CONST());

    case Absyn.Exp.CREF()
      then typeCref(untypedExp.componentRef, scope, info, allowTypename);

    case Absyn.Exp.ARRAY()
      algorithm
        (typedExp, ty, variability) := typeArray(untypedExp.arrayExp, scope, info);
      then
        (typedExp, ty, variability);

    case Absyn.Exp.RANGE()
      algorithm
        (typedExp, ty, variability) := typeRange(untypedExp.start, untypedExp.step, untypedExp.stop, scope, info);
      then
        (typedExp, ty, variability);

    case Absyn.Exp.BINARY()
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp1, scope, info);
        (e2, ty2, var2) := typeExp(untypedExp.exp2, scope, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkBinaryOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.UNARY()  // Unary +, -
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp, scope, info);
        op := translateOperator(untypedExp.op);
        (typedExp, ty) := TypeCheck.checkUnaryOperation(e1, ty1, op);
      then
        (typedExp, ty, var1);

    case Absyn.Exp.LBINARY()
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp1, scope, info);
        (e2, ty2, var2) := typeExp(untypedExp.exp2, scope, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkLogicalBinaryOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.LUNARY()  // Unary not
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp, scope, info);
        op := translateOperator(untypedExp.op);
        (typedExp, ty) := TypeCheck.checkLogicalUnaryOperation(e1, ty1, op);
      then
        (typedExp, ty, var1);

    case Absyn.Exp.RELATION()
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.exp1, scope, info);
        (e2, ty2, var2) := typeExp(untypedExp.exp2, scope, info);
        op := translateOperator(untypedExp.op);

        (typedExp, ty) := TypeCheck.checkRelationOperation(e1, ty1, op, e2, ty2);
      then
        (typedExp, ty, Types.constAnd(var1, var2));

    case Absyn.Exp.IFEXP()
      algorithm
        (e1, ty1, var1) := typeExp(untypedExp.ifExp, scope, info);
        (e2, ty2, var2) := typeExp(untypedExp.trueBranch, scope, info);
        (e3, ty3, var3) := typeExp(untypedExp.elseBranch, scope, info);

        (typedExp, ty, variability) := TypeCheck.checkIfExpression(e1, ty1, var1, e2, ty2, var2, e3, ty3, var3, info);
      then
        (typedExp, ty, variability);

    case Absyn.Exp.CALL()
      algorithm
        (typedExp, ty, variability) := Func.typeFunctionCall(untypedExp.function_, untypedExp.functionArgs, scope, info);
      then
        (typedExp, ty, variability);

    else
      algorithm
        assert(false, getInstanceName() + " got unknown expression");
      then
        fail();
  end match;
end typeExp;

function translateOperator
  input Absyn.Operator inOperator;
  output Operator outOperator;
algorithm
  outOperator := match(inOperator)
    case Absyn.ADD() then Operator.ADD(Type.UNKNOWN());
    case Absyn.SUB() then Operator.SUB(Type.UNKNOWN());
    case Absyn.MUL() then Operator.MUL(Type.UNKNOWN());
    case Absyn.DIV() then Operator.DIV(Type.UNKNOWN());
    case Absyn.POW() then Operator.POW(Type.UNKNOWN());
    case Absyn.UPLUS() then Operator.ADD(Type.UNKNOWN());
    case Absyn.UMINUS() then Operator.UMINUS(Type.UNKNOWN());
    case Absyn.ADD_EW() then Operator.ADD_ARR(Type.UNKNOWN());
    case Absyn.SUB_EW() then Operator.SUB_ARR(Type.UNKNOWN());
    case Absyn.MUL_EW() then Operator.MUL_ARR(Type.UNKNOWN());
    case Absyn.DIV_EW() then Operator.DIV_ARR(Type.UNKNOWN());
    case Absyn.POW_EW() then Operator.POW_ARR2(Type.UNKNOWN());
    case Absyn.UPLUS_EW() then Operator.ADD(Type.UNKNOWN());
    case Absyn.UMINUS_EW() then Operator.UMINUS(Type.UNKNOWN());
    // logical have boolean type
    case Absyn.AND() then Operator.AND(Type.BOOLEAN());
    case Absyn.OR() then Operator.OR(Type.BOOLEAN());
    case Absyn.NOT() then Operator.NOT(Type.BOOLEAN());
    // relational have boolean type too
    case Absyn.LESS() then Operator.LESS(Type.BOOLEAN());
    case Absyn.LESSEQ() then Operator.LESSEQ(Type.BOOLEAN());
    case Absyn.GREATER() then Operator.GREATER(Type.BOOLEAN());
    case Absyn.GREATEREQ() then Operator.GREATEREQ(Type.BOOLEAN());
    case Absyn.EQUAL() then Operator.EQUAL(Type.BOOLEAN());
    case Absyn.NEQUAL() then Operator.NEQUAL(Type.BOOLEAN());
  end match;
end translateOperator;

function typeArray
  input list<Absyn.Exp> expressions;
  input InstNode scope;
  input SourceInfo info;
  output Expression arrayExp;
  output Type arrayType = Type.UNKNOWN();
  output DAE.Const variability = DAE.C_CONST();
protected
  Expression exp;
  list<Expression> expl = {};
  DAE.Const var;
  Type elem_ty;
algorithm
  for e in expressions loop
    (exp, elem_ty, var) := typeExp(e, scope, info);
    variability := Types.constAnd(var, variability);
    expl := exp :: expl;
  end for;

  arrayType := Type.liftArrayLeft(elem_ty, Dimension.INTEGER(listLength(expl)));
  arrayExp := Expression.ARRAY(arrayType, listReverse(expl));
end typeArray;

function typeExps
  input list<Absyn.Exp> expressions;
  input InstNode scope;
  input SourceInfo info;
  output list<Expression> exps = {};
  output list<Type> daeTys = {};
  output list<DAE.Const> daeVrs = {};
protected
  Expression exp;
  DAE.Const var;
  Type elem_ty;
algorithm
  for e in expressions loop
    (exp, elem_ty, var) := typeExp(e, scope, info);

    exps := exp :: exps;
    daeTys := elem_ty :: daeTys;
    daeVrs := var :: daeVrs;

  end for;
  exps := listReverse(exps);
  daeTys := listReverse(daeTys);
  daeVrs := listReverse(daeVrs);
end typeExps;

function typeRange
  input Absyn.Exp inStart;
  input Option<Absyn.Exp> inStep;
  input Absyn.Exp inEnd;
  input InstNode scope;
  input SourceInfo info;
  output Expression outRange;
  output Type outType;
  output DAE.Const variability;
protected
  Absyn.Exp astep;
  Expression dstart, dend, dstep, dimexp;
  Option<Expression> dopt_step;
  Type strtype, endtype, stptype;
  Option<Type> optsteptype;
  DAE.Const var;
  Boolean numeric, isreal, enum;
algorithm
  (dstart, strtype, variability) := typeExp(inStart,scope,info);
  (dend, endtype, var) := typeExp(inEnd,scope,info);
  variability := Types.constAnd(var, variability);

  if isSome(inStep) then
    SOME(astep) := inStep;
    (dstep, stptype, var) := typeExp(astep,scope,info);
    variability := Types.constAnd(var, variability);

    dopt_step := SOME(dstep);
    outType := TypeCheck.getRangeType(dstart, strtype, dopt_step, SOME(stptype), dend, endtype, info);
  else
    dopt_step := NONE();
    outType := TypeCheck.getRangeType(dstart, strtype, dopt_step, NONE(), dend, endtype, info);
  end if;

  outRange := Expression.RANGE(outType, dstart, dopt_step, dend);
end typeRange;

function typeCref
  "Looks up a given component reference and returns a typed Expression, along
   with the type and variability of the referenced component. In some cases a
   typename, like Boolean or an enumeration, may be used to indicate a range.
   This is also handled by this function if the parameter allowTypename is true."
  input Absyn.ComponentRef untypedCref;
  input InstNode scope;
  input SourceInfo info;
  input Boolean allowTypename = false "Allow crefs referring to typenames.";
  output Expression typedCref;
  output Type ty;
  output DAE.Const variability;
protected
  InstNode node, found_scope, first_node;
  list<InstNode> nodes;
  Prefix prefix;
  Component.Attributes attr;
  DAE.VarKind vr;
  Component comp;
  Class cls;
  Type t;
algorithm
  // Look up the cref.
  (node, nodes, found_scope) := Lookup.lookupComponent(untypedCref, scope, info, allowTypename);

  // Type the first node found (which should recursively type the other nodes too).
  first_node := listHead(nodes);
  if InstNode.isComponent(first_node) then
    first_node := typeComponent(first_node);
  else
    first_node := Inst.instantiate(first_node, Modifier.NOMOD(), found_scope);
    first_node := typeComponents(first_node, found_scope);
  end if;

  // Create a prefix from the scope the cref was found in.
  prefix := InstNode.prefix(found_scope);
  // Append the cref itself to the prefix.
  prefix := makeCrefPrefix(untypedCref, nodes, prefix);

  if allowTypename and InstNode.isClass(node) then
    // Special case when a cref refers to a typename, e.g. as a dimension.
    cls := InstNode.getClass(node);
    t := Class.getType(cls);

    (typedCref, ty) := match t
      // Make sure it's a type that's allowed, and make a cref.
      case Type.ENUMERATION() then (Expression.CREF(node, prefix), t);
      case Type.BOOLEAN() then (Expression.CREF(node, prefix), t);

      // This should be caught by the lookup.
      else
        algorithm
          assert(false, getInstanceName() + " got invalid typename class");
        then
          fail();

    end match;

    // Typenames are always constant.
    variability := DAE.C_CONST();

  else
    // A normal component, create a cref from it.
    typedCref := Expression.CREF(node, prefix);

    // TODO: The subscripts needs to taken into account when getting the type of
    // the component.
    comp := InstNode.component(node);
    Component.TYPED_COMPONENT(ty = ty, attributes = attr) := comp;
    Component.ATTRIBUTES(variability = vr) := attr;
    variability := NFTyping.variabilityToConst(NFInstUtil.daeToSCodeVariability(vr));
  end if;
end typeCref;

function makeCrefPrefix
  input Absyn.ComponentRef cref;
  input list<InstNode> nodes;
  input output Prefix prefix;
algorithm
  assert(not listEmpty(nodes), getInstanceName() + " got too few instance nodes");

  prefix := match cref
    case Absyn.ComponentRef.CREF_IDENT()
      then Prefix.addCref(listHead(nodes), prefix);

    case Absyn.ComponentRef.CREF_QUAL()
      then makeCrefPrefix(cref.componentRef, listRest(nodes),
        Prefix.addCref(listHead(nodes), prefix));

    case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
      then makeCrefPrefix(cref.componentRef, nodes, prefix);

  end match;
end makeCrefPrefix;

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
