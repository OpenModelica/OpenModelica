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
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFStatement.Statement;
import NFType.Type;
import Operator = NFOperator;

protected
import Ceval = NFCeval;
import ClassInf;
import ComponentRef = NFComponentRef;
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

public
function typeClass
  input InstNode cls;
  input String name;
algorithm
  typeComponents(cls);
  execStat("NFInst.typeComponents(" + name + ")");
  typeBindings(cls);
  execStat("NFInst.typeBindings(" + name + ")");
  typeSections(cls);
  execStat("NFInst.typeSections(" + name + ")");
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
  output Type ty;
protected
  Class c = InstNode.getClass(cls);
  ClassTree cls_tree;
algorithm
  ty := match c
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          typeComponent(c);
        end for;
      then
        Type.COMPLEX(cls);

    case Class.INSTANCED_BUILTIN() then c.ty;

    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated class " +
          InstNode.name(cls));
      then
        fail();

  end match;
end typeComponents;

function typeComponent
  input InstNode component;
protected
  Component c = InstNode.component(component);
  SourceInfo info;
  Type ty;
algorithm
  () := match c
    // An untyped component, type it.
    case Component.UNTYPED_COMPONENT()
      algorithm
        info := InstNode.info(component);

        // Type the component's dimensions.
        typeDimensions(c.dimensions, InstNode.name(component), info);

        // Type the component's children.
        ty := typeComponents(c.classInst);

        // Add the dimensions from the component to it's type.
        ty := Type.liftArrayLeftList(ty, arrayList(c.dimensions));

        // Finally, update the component in the instance tree.
        InstNode.updateComponent(Component.setType(ty, c), component);
      then
        ();

    // A component that has already been typed, skip it.
    case Component.TYPED_COMPONENT() then ();
    case Component.ITERATOR() then ();
    case Component.ENUM_LITERAL() then ();

    // Any other type of component shouldn't show up here.
    else
      algorithm
        assert(false, getInstanceName() + " got uninstantiated component " +
          InstNode.name(component));
      then
        ();

  end match;
end typeComponent;

function typeIterator
  input InstNode iterator;
  input SourceInfo info;
  input Boolean structural = false "If the iteration range must be a parameter expression or not.";
protected
  Component c = InstNode.component(iterator);
  Binding binding;
  Type ty;
  Expression exp;
algorithm
  () := match c
    case Component.ITERATOR(binding = Binding.UNTYPED_BINDING())
      algorithm
        binding := typeBinding(c.binding);

        // If the iteration range is structural, it must be a parameter expression.
        if structural then
          if not Types.isParameterOrConstant(Binding.variability(binding)) then
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
  input String elementName;
  input SourceInfo info;
algorithm
  for i in 1:arrayLength(dimensions) loop
    dimensions[i] := typeDimension(dimensions[i], elementName, i, info);
  end for;
end typeDimensions;

function typeDimension
  input output Dimension dimension;
  input String elementName;
  input Integer index;
  input SourceInfo info;
algorithm
  dimension := match dimension
    local
      Expression exp;
      DAE.Const var;

    // If the dimension is not typed, type it.
    case Dimension.UNTYPED()
      algorithm
        (exp, _, var) := typeExp(dimension.dimension, info);

        // TODO: Improve this error message:
        // "Dimension %s of %s is not a parameter expression."
        if not Types.isParameterOrConstant(var) then
          Error.addSourceMessageAndFail(Error.DIMENSION_NOT_KNOWN, {Expression.toString(exp)}, info);
        end if;

        exp := Ceval.evalExp(exp, Ceval.EvalTarget.DIMENSION(elementName, index, exp, info));
        exp := SimplifyExp.simplifyExp(exp);
      then
        Dimension.fromExp(exp);

    // Other kinds of dimensions are already typed.
    else dimension;
  end match;
end typeDimension;

function typeBindings
  input output InstNode cls;
protected
  Class c;
  ClassTree cls_tree;
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
  Component c = InstNode.component(component);
algorithm
  () := match c
    local
      Binding binding;
      MatchKind matchKind;

    case Component.TYPED_COMPONENT()
      algorithm
        binding := typeBinding(c.binding);
        if not referenceEq(binding, c.binding) then
          c.binding := binding;
          InstNode.updateComponent(c, component);
        end if;

        if Binding.isTyped(binding) then
          (_, _, matchKind) := TypeCheck.matchTypes(Binding.getType(binding), c.ty, Binding.getTypedExp(binding));
          if not TypeCheck.isCompatibleMatch(matchKind) then
            Error.addSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH, {InstNode.name(component), Binding.toString(binding), Type.toString(c.ty), Type.toString(Binding.getType(binding))}, Binding.getInfo(binding));
            fail();
          end if;
        end if;

        typeBindings(c.classInst);
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got invalid node " + InstNode.name(component));
      then
        fail();

  end match;
end typeComponentBinding;

function typeBinding
  input output Binding binding;
algorithm
  binding := match binding
    local
      Expression exp;
      Type ty;
      DAE.Const var;

    case Binding.UNTYPED_BINDING(bindingExp = exp)
      algorithm
        (exp, ty, var) := typeExp(exp, binding.info);
      then
        Binding.TYPED_BINDING(exp, ty, var, binding.propagatedDims, binding.info);

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
        Binding.TYPED_BINDING(exp, binding.bindingType, binding.variability, binding.propagatedDims, binding.info);

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

function typeExp
  input output Expression exp;
  input SourceInfo info;
        output Type ty;
        output DAE.Const variability;

  import DAE.Const;
algorithm
  (exp, ty, variability) := match exp
    local
      Expression e1, e2, e3;
      DAE.Const var1, var2, var3;
      Type ty1, ty2, ty3;
      Operator op;

    case Expression.INTEGER() then (exp, Type.INTEGER(), Const.C_CONST());
    case Expression.REAL() then (exp, Type.REAL(), Const.C_CONST());
    case Expression.STRING() then (exp, Type.STRING(), Const.C_CONST());
    case Expression.BOOLEAN() then (exp, Type.BOOLEAN(), Const.C_CONST());
    case Expression.ENUM_LITERAL() then (exp, exp.ty, Const.C_CONST());
    case Expression.CREF() then typeCref(exp.cref, info);
    case Expression.TYPENAME() then (exp, exp.ty, Const.C_CONST());
    case Expression.ARRAY() then typeArray(exp.elements, info);
    case Expression.RANGE() then typeRange(exp, info);

    case Expression.BINARY()
      algorithm
        (e1, ty1, var1) := typeExp(exp.exp1, info);
        (e2, ty2, var2) := typeExp(exp.exp2, info);
        (exp, ty) := TypeCheck.checkBinaryOperation(e1, ty1, exp.operator, e2, ty2);
      then
        (exp, ty, Types.constAnd(var1, var2));

    case Expression.UNARY()
      algorithm
        (e1, ty1, var1) := typeExp(exp.exp, info);
        (exp, ty) := TypeCheck.checkUnaryOperation(e1, ty1, exp.operator);
      then
        (exp, ty, var1);

    case Expression.LBINARY()
      algorithm
        (e1, ty1, var1) := typeExp(exp.exp1, info);
        (e2, ty2, var2) := typeExp(exp.exp2, info);
        (exp, ty) := TypeCheck.checkLogicalBinaryOperation(e1, ty1, exp.operator, e2, ty2);
      then
        (exp, ty, Types.constAnd(var1, var2));

    case Expression.LUNARY()
      algorithm
        (e1, ty1, var1) := typeExp(exp.exp, info);
        (exp, ty) := TypeCheck.checkLogicalUnaryOperation(e1, ty1, exp.operator);
      then
        (exp, ty, var1);

    case Expression.RELATION()
      algorithm
        (e1, ty1, var1) := typeExp(exp.exp1, info);
        (e2, ty2, var2) := typeExp(exp.exp2, info);
        (exp, ty) := TypeCheck.checkRelationOperation(e1, ty1, exp.operator, e2, ty2);
      then
        (exp, ty, Types.constAnd(var1, var2));

    case Expression.IF()
      algorithm
        (e1, ty1, var1) := typeExp(exp.condition, info);
        (e2, ty2, var2) := typeExp(exp.trueBranch, info);
        (e3, ty3, var3) := typeExp(exp.falseBranch, info);
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
  output list<DAE.Const> varl = {};
protected
  Expression exp;
  DAE.Const var;
  Type ty;
algorithm
  for e in listReverse(expl) loop
    (exp, ty, var) := typeExp(e, info);
    explTyped := exp :: explTyped;
    tyl := ty :: tyl;
    varl := var :: varl;
  end for;
end typeExpl;

function typeCref
  input ComponentRef cref;
  input SourceInfo info;
  output Expression exp;
  output Type ty;
  output DAE.Const variability;
algorithm
  (exp, ty, variability) := match cref
    local
      Component comp;
      Class cls;
      ComponentRef cr;

    case ComponentRef.CREF(node = InstNode.COMPONENT_NODE())
      algorithm
        typeComponent(cref.node);
        comp := InstNode.component(cref.node);
        ty := Component.getType(comp);
        variability := ComponentRef.getVariability(cref);
        cref.subscripts := typeSubscripts(cref.subscripts, info);
        cref.ty := Type.subscript(ty, cref.subscripts);
      then
        (Expression.CREF(cref), cref.ty, variability);

    case ComponentRef.WILD()
      then (Expression.CREF(ComponentRef.WILD()), Type.UNKNOWN(), DAE.Const.C_VAR());

    else
      algorithm
        assert(false, getInstanceName() + " got unknown cref");
      then
        fail();

  end match;
end typeCref;

function typeSubscripts
  input list<Subscript> subscripts;
  input SourceInfo info;
  output list<Subscript> typedSubs;
algorithm
  typedSubs := list(typeSubscript(s, info) for s in subscripts);
end typeSubscripts;

function typeSubscript
  input output Subscript subscript;
  input SourceInfo info;
algorithm
  subscript := match subscript
    local
      Expression e;
      Type ty;

    case Subscript.UNTYPED()
      algorithm
        (e, ty, _) := typeExp(subscript.exp, info);
      then
        if Type.isArray(ty) then Subscript.SLICE(e) else Subscript.INDEX(e);

    else subscript;
  end match;
end typeSubscript;

function typeArray
  input list<Expression> elements;
  input SourceInfo info;
  output Expression arrayExp;
  output Type arrayType = Type.UNKNOWN();
  output DAE.Const variability = DAE.C_CONST();
protected
  Expression exp;
  list<Expression> expl = {};
  DAE.Const var;
  Type ty;
algorithm
  for e in elements loop
    (exp, ty, var) := typeExp(e, info);
    variability := Types.constAnd(var, variability);
    expl := exp :: expl;
  end for;

  arrayType := Type.liftArrayLeft(ty, Dimension.INTEGER(listLength(expl)));
  arrayExp := Expression.ARRAY(arrayType, listReverse(expl));
end typeArray;

function typeRange
  input output Expression rangeExp;
  input SourceInfo info;
        output Type rangeType;
        output DAE.Const variability;
protected
  Expression start_exp, step_exp, stop_exp;
  Type start_ty, step_ty, stop_ty;
  Option<Expression> ostep_exp;
  Option<Type> ostep_ty;
  DAE.Const start_var, step_var, stop_var;
  TypeCheck.MatchKind ty_match;
algorithm
  Expression.RANGE(start = start_exp, step = ostep_exp, stop = stop_exp) := rangeExp;

  // Type start and stop.
  (start_exp, start_ty, start_var) := typeExp(start_exp, info);
  (stop_exp, stop_ty, stop_var) := typeExp(stop_exp, info);
  variability := Types.constAnd(start_var, stop_var);

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
    variability := Types.constAnd(step_var, variability);

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
          typeSections(InstNode.classScope(components[i]));
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
      Type ty1, ty2;
      list<Equation> eqs1, body;
      list<tuple<Expression, list<Equation>>> tybrs;
      InstNode iterator;

    case Equation.EQUALITY()
      algorithm
        (e1, ty1) := typeExp(eq.lhs, eq.info);
        (e2, _) := typeExp(eq.rhs, eq.info);
      then
        Equation.EQUALITY(e1, e2, ty1, eq.info);

    case Equation.CONNECT()
      algorithm
        (e1, ty1) := typeExp(eq.lhs, eq.info);
        (e2, ty2) := typeExp(eq.rhs, eq.info);
      then
        Equation.CONNECT(e1, ty1, e2, ty2, eq.info);

    case Equation.FOR()
      algorithm
        typeIterator(eq.iterator, eq.info, structural = true);
        body := list(typeEquation(e) for e in eq.body);
      then
        Equation.FOR(eq.iterator, body, eq.info);

    case Equation.IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, eq.info);
              eqs1 := list(typeEquation(beq) for beq in body);
            then (e1, eqs1);
          end match
        for br in eq.branches);
      then
        Equation.IF(tybrs, eq.info);

    case Equation.WHEN()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, eq.info);
              eqs1 := list(typeEquation(beq) for beq in body);
            then (e1, eqs1);
          end match
        for br in eq.branches);
      then
        Equation.WHEN(tybrs, eq.info);

    case Equation.ASSERT()
      algorithm
        e1 := typeExp(eq.condition, eq.info);
        e2 := typeExp(eq.message, eq.info);
        e3 := typeExp(eq.level, eq.info);
      then
        Equation.ASSERT(e1, e2, e3, eq.info);

    case Equation.TERMINATE()
      algorithm
        e1 := typeExp(eq.message, eq.info);
      then
        Equation.TERMINATE(e1, eq.info);

    case Equation.REINIT()
      algorithm
        e1 := typeExp(eq.cref, eq.info);
        e2 := typeExp(eq.reinitExp, eq.info);
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

    case Statement.ASSIGNMENT()
      algorithm
        (e1, _) := typeExp(st.lhs, st.info);
        (e2, _) := typeExp(st.rhs, st.info);
      then
        Statement.ASSIGNMENT(e1, e2, st.info);

    case Statement.FOR()
      algorithm
        typeIterator(st.iterator, st.info);
        body := typeAlgorithm(st.body);
      then
        Statement.FOR(st.iterator, body, st.info);

    case Statement.IF()
      algorithm
        tybrs := list(
          match br case(cond, body)
            algorithm
              e1 := typeExp(cond, st.info);
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
              e1 := typeExp(cond, st.info);
              sts1 := list(typeStatement(bst) for bst in body);
            then (e1, sts1);
          end match
        for br in st.branches);
      then
        Statement.WHEN(tybrs, st.info);

    case Statement.ASSERT()
      algorithm
        e1 := typeExp(st.condition, st.info);
        e2 := typeExp(st.message, st.info);
        e3 := typeExp(st.level, st.info);
      then
        Statement.ASSERT(e1, e2, e3, st.info);

    case Statement.TERMINATE()
      algorithm
        e1 := typeExp(st.message, st.info);
      then
        Statement.TERMINATE(e1, st.info);

    case Statement.REINIT()
      algorithm
        e1 := typeExp(st.cref, st.info);
        e2 := typeExp(st.reinitExp, st.info);
      then
        Statement.REINIT(e1, e2, st.info);

    case Statement.NORETCALL()
      algorithm
        e1 := typeExp(st.exp, st.info);
      then
        Statement.NORETCALL(e1, st.info);

    case Statement.WHILE()
      algorithm
        e1 := typeExp(st.condition, st.info);
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

annotation(__OpenModelica_Interface="frontend");
end NFTyping;
