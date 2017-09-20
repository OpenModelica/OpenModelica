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

encapsulated uniontype NFExpression
protected
  import Util;
  import Absyn;
  import List;

  import Expression = NFExpression;
  import Function = NFFunction;
  import RangeIterator = NFRangeIterator;

public
  import Absyn.Path;
  import DAE;
  import NFInstNode.InstNode;
  import Operator = NFOperator;
  import Subscript = NFSubscript;
  import Dimension = NFDimension;
  import Type = NFType;
  import ComponentRef = NFComponentRef;
  import NFCall.Call;

  record INTEGER
    Integer value;
  end INTEGER;

  record REAL
    Real value;
  end REAL;

  record STRING
    String value;
  end STRING;

  record BOOLEAN
    Boolean value;
  end BOOLEAN;

  record ENUM_LITERAL
    Type ty;
    String name;
    Integer index;
  end ENUM_LITERAL;

  record CREF
    Type ty;
    ComponentRef cref;
  end CREF;

  record TYPENAME "Represents a type used as a range, e.g. Boolean."
    Type ty;
  end TYPENAME;

  record ARRAY
    Type ty;
    list<Expression> elements;
  end ARRAY;

  record RANGE
    Type ty;
    Expression start;
    Option<Expression> step;
    Expression stop;
  end RANGE;

  record TUPLE
    Type ty;
    list<Expression> elements;
  end TUPLE;

  record RECORD
    Path path; // Maybe not needed since the type contains the name. Prefix?
    Type ty;
    list<Expression> elements;
  end RECORD;

  record CALL
    Call call;
  end CALL;

  record SIZE
    Expression exp;
    Option<Expression> dimIndex;
  end SIZE;

  record END
  end END;

  record BINARY "Binary operations, e.g. a+4"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end BINARY;

  record UNARY "Unary operations, -(4x)"
    Operator operator;
    Expression exp;
  end UNARY;

  record LBINARY "Logical binary operations: and, or"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end LBINARY;

  record LUNARY "Logical unary operations: not"
    Operator operator;
    Expression exp;
  end LUNARY;

  record RELATION "Relation, e.g. a <= 0"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end RELATION;

  record IF
    Expression condition;
    Expression trueBranch;
    Expression falseBranch;
  end IF;

  record CAST
    Type ty;
    Expression exp;
  end CAST;

  record UNBOX "MetaModelica value unboxing (similar to a cast)"
    Expression exp;
    Type ty;
  end UNBOX;

  function isTrue
    input Expression exp;
    output Boolean isTrue;
  algorithm
    isTrue := match exp
      case BOOLEAN(true) then true;
      else false;
    end match;
  end isTrue;

  function isEqual
    "Returns true if the two expressions are equal, otherwise false."
    input Expression exp1;
    input Expression exp2;
    output Boolean isEqual;
  algorithm
    isEqual := 0 == compare(exp1, exp2);
  end isEqual;

  function compare
    "Checks whether two expressions are equal, and returns 0 if they are.
     If the first expression is 'less' than the second it returns an integer
     less than 0, otherwise an integer greater than 0."
    input Expression exp1;
    input Expression exp2;
    output Integer comp;
  algorithm
    // Check if the expressions are the same object.
    if referenceEq(exp1, exp2) then
      comp := 0;
      return;
    end if;

    // Return false if the expressions are of different kinds.
    comp := Util.intCompare(valueConstructor(exp1), valueConstructor(exp2));
    if comp <> 0 then
      return;
    end if;

    comp := match (exp1)
      local
        Integer i;
        Real r;
        String s;
        Boolean b;
        ComponentRef cr;
        Type ty;
        list<Expression> expl;
        Expression e1, e2, e3;
        Option<Expression> oe;
        Path p;
        Operator op;
        Call c;

      case INTEGER()
        algorithm
          INTEGER(value = i) := exp2;
        then
          Util.intCompare(exp1.value, i);

      case REAL()
        algorithm
          REAL(value = r) := exp2;
        then
          Util.realCompare(exp1.value, r);

      case STRING()
        algorithm
          STRING(value = s) := exp2;
        then
          Util.stringCompare(exp1.value, s);

      case BOOLEAN()
        algorithm
          BOOLEAN(value = b) := exp2;
        then
          Util.boolCompare(exp1.value, b);

      case CREF()
        algorithm
          CREF(cref = cr) := exp2;
        then
          ComponentRef.compare(exp1.cref, cr);

      case TYPENAME()
        algorithm
          TYPENAME(ty = ty) := exp2;
        then
          valueCompare(exp1.ty, ty);

      case ARRAY()
        algorithm
          ARRAY(ty = ty, elements = expl) := exp2;
          comp := valueCompare(ty, exp1.ty);
        then
          if comp then compareList(exp1.elements, expl) else comp;

      case RANGE()
        algorithm
          RANGE(start = e1, step = oe, stop = e2) := exp2;
          comp := compare(exp1.start, e1);
          if comp == 0 then
            comp := compare(exp1.stop, e2);
            if comp == 0 then
              comp := compareOpt(exp1.step, oe);
            end if;
          end if;
        then
          comp;

      case TUPLE()
        algorithm
          TUPLE(elements = expl) := exp2;
        then
          compareList(exp1.elements, expl);

      case CALL()
        algorithm
          CALL(call = c) := exp2;
        then
          Call.compare(exp1.call, c);

      case SIZE()
        algorithm
          SIZE(exp = e1, dimIndex = oe) := exp2;
          comp := compareOpt(exp1.dimIndex, oe);
        then
          if comp == 0 then compare(exp1.exp, e1) else comp;

      case END() then 0;

      case BINARY()
        algorithm
          BINARY(exp1 = e1, operator = op, exp2 = e2) := exp2;
          comp := Operator.compare(exp1.operator, op);
          if comp == 0 then
            comp := compare(exp1.exp1, e1);
            if comp == 0 then
              comp := compare(exp1.exp2, e2);
            end if;
          end if;
        then
          comp;

      case UNARY()
        algorithm
          UNARY(operator = op, exp = e1) := exp2;
          comp := Operator.compare(exp1.operator, op);
        then
          if comp == 0 then compare(exp1.exp, e1) else comp;

      case LBINARY()
        algorithm
          LBINARY(exp1 = e1, operator = op, exp2 = e2) := exp2;
          comp := Operator.compare(exp1.operator, op);
          if comp == 0 then
            comp := compare(exp1.exp1, e1);
            if comp == 0 then
              comp := compare(exp1.exp2, e2);
            end if;
          end if;
        then
          comp;

      case LUNARY()
        algorithm
          LUNARY(operator = op, exp = e1) := exp2;
          comp := Operator.compare(exp1.operator, op);
        then
          if comp == 0 then compare(exp1.exp, e1) else comp;

      case RELATION()
        algorithm
          RELATION(exp1 = e1, operator = op, exp2 = e2) := exp2;
          comp := Operator.compare(exp1.operator, op);
          if comp == 0 then
            comp := compare(exp1.exp1, e1);
            if comp == 0 then
              comp := compare(exp1.exp2, e2);
            end if;
          end if;
        then
          comp;

      case IF()
        algorithm
          IF(condition = e1, trueBranch = e2, falseBranch = e3) := exp2;
          comp := compare(exp1.condition, e1);
          if comp == 0 then
            comp := compare(exp1.trueBranch, e2);
            if comp == 0 then
              comp := compare(exp1.falseBranch, e3);
            end if;
          end if;
        then
          comp;

      case UNBOX()
        algorithm
          UNBOX(exp = e1) := exp2;
        then
          compare(exp1.exp, e1);

      case CAST()
        algorithm
          e1 := match exp2
                  case CAST(exp = e1) then e1;
                  case e1 then e1;
                end match;
        then
          compare(exp1.exp, e1);

      else
        algorithm
          assert(false, getInstanceName() + " got unknown expression.");
        then
          fail();

    end match;
  end compare;

  function compareOpt
    input Option<Expression> expl1;
    input Option<Expression> expl2;
    output Integer comp;
  protected
    Expression e1, e2;
  algorithm
    comp := match(expl1, expl2)
      case (NONE(), NONE()) then 0;
      case (NONE(), _) then -1;
      case (_, NONE()) then 1;
      case (SOME(e1), SOME(e2)) then compare(e1, e2);
    end match;
  end compareOpt;

  function compareList
    input list<Expression> expl1;
    input list<Expression> expl2;
    output Integer comp;
  protected
    Integer len1, len2;
    Expression e2;
    list<Expression> rest_expl2 = expl2;
    Integer len1, len2;
  algorithm
    // Check that the lists have the same length, otherwise they can't be equal.
    len1 := listLength(expl1);
    len2 := listLength(expl2);
    comp := Util.intCompare(len1, len2);
    if comp <> 0 then
      return;
    end if;

    for e1 in expl1 loop
      e2 :: rest_expl2 := rest_expl2;

      // Return false if the expressions are not equal.
      comp := compare(e1, e2);
      if 0 <> comp then
        return;
      end if;
    end for;

    comp := 0;
  end compareList;

  function typeOf
    input Expression exp;
    output Type ty;
  algorithm
    ty := match exp
      case INTEGER() then Type.INTEGER();
      case REAL() then Type.REAL();
      case STRING() then Type.STRING();
      case BOOLEAN() then Type.BOOLEAN();
      case ENUM_LITERAL() then exp.ty;
      case CREF() then exp.ty;
      case ARRAY() then exp.ty;
      case RANGE() then exp.ty;
      case TUPLE() then exp.ty;
      case RECORD() then exp.ty;
      case CALL() then Call.typeOf(exp.call);
      case SIZE(dimIndex = SOME(_)) then Type.INTEGER();
      case SIZE() then typeOf(exp.exp);
      case END() then Type.INTEGER();
      case BINARY() then Operator.typeOf(exp.operator);
      case UNARY() then Operator.typeOf(exp.operator);
      case LBINARY() then Operator.typeOf(exp.operator);
      case LUNARY() then Operator.typeOf(exp.operator);
      case RELATION() then Operator.typeOf(exp.operator);
      case IF() then typeOf(exp.trueBranch);
      case CAST() then exp.ty;
      case UNBOX() then exp.ty;
      else Type.UNKNOWN();
    end match;
  end typeOf;

  function typeCastElements
    input output Expression exp;
    input Type ty;
  algorithm
    exp := match (exp, ty)
      local
        Type t;
        list<Expression> el;

      case (INTEGER(), Type.REAL())
        then REAL(intReal(exp.value));

      case (REAL(), Type.REAL()) then exp;

      case (ARRAY(ty = t, elements = el), _)
        algorithm
          el := list(typeCastElements(e, ty) for e in el);
          t := Type.setArrayElementType(t, ty);
        then
          ARRAY(t, el);

      case (UNARY(), _)
        then UNARY(exp.operator, typeCastElements(exp.exp, ty));

      else
        then
          CAST(ty, exp);

    end match;
  end typeCastElements;

  function realValue
    input Expression exp;
    output Real value;
  algorithm
    value := match exp
      case REAL() then exp.value;
      case INTEGER() then intReal(exp.value);
    end match;
  end realValue;

  function subscript
    input output Expression exp;
    input list<Subscript> subscripts;
  algorithm
    for sub in subscripts loop
      _ := match sub
        case Subscript.INDEX()
          algorithm
            exp := arrayElement(exp, toInteger(sub.index));
          then
            ();

        else
          algorithm
            assert(false, getInstanceName() + " got unknown subscript " + anyString(sub));
          then
            fail();

      end match;
    end for;
  end subscript;

  function arrayElement
    input Expression array;
    input Integer index;
    output Expression element;
  algorithm
    element := match array
      local
        ComponentRef cref;

      case ARRAY() then listGet(array.elements, index);

      case CREF()
        algorithm
          cref := ComponentRef.addSubscript(Subscript.INDEX(INTEGER(index)), array.cref);
        then
          CREF(Type.unliftArray(array.ty), cref);

    end match;
  end arrayElement;

  function arrayFromList
    input list<Expression> inExps;
    input Type elemTy;
    input list<Dimension> inDims;
    output Expression outExp;
  algorithm
    outExp := arrayFromList_impl(inExps, elemTy, listReverse(inDims));
  end arrayFromList;

  function arrayFromList_impl
    input list<Expression> inExps;
    input Type elemTy;
    input list<Dimension> inDims;
    output Expression outExp;
  protected
    Dimension ldim;
    list<Dimension> restdims;
    Type ty;
    list<Expression> newlst;
    list<list<Expression>> partexps;
    Integer dimsize;
  algorithm
    assert(not listEmpty(inDims), "Empty dimension list given in arrayFromList.");

    ldim::restdims := inDims;
    dimsize := Dimension.size(ldim);
    ty := Type.liftArrayLeft(elemTy, ldim);

    if List.hasOneElement(inDims) then
      assert(dimsize == listLength(inExps), "Length mismatch in arrayFromList.");
      outExp := ARRAY(ty,inExps);
      return;
    end if;

    partexps := List.partition(inExps, dimsize);

    newlst := {};
    for arrexp in partexps loop
      newlst := ARRAY(ty,arrexp)::newlst;
    end for;

    newlst := listReverse(newlst);
    outExp := arrayFromList(newlst, ty, restdims);
  end arrayFromList_impl;

  function makeEnumLiterals
    input Type enumType;
    output list<Expression> literals;
  protected
    list<String> lits;
  algorithm
    Type.ENUMERATION(literals = lits) := enumType;
    literals := list(ENUM_LITERAL(enumType, l, i)
      threaded for l in lits, i in 1:listLength(lits));
  end makeEnumLiterals;

  function toInteger
    input Expression exp;
    output Integer i;
  algorithm
    i := match exp
      case INTEGER() then exp.value;
      case BOOLEAN() then if exp.value then 1 else 0;
      case ENUM_LITERAL() then exp.index;
    end match;
  end toInteger;

  function toString
    input Expression exp;
    output String str;
  protected
    Type t;
  algorithm
    str := match exp
      case INTEGER() then String(exp.value);
      case REAL() then String(exp.value);
      case STRING() then "\"" + exp.value + "\"";
      case BOOLEAN() then String(exp.value);

      case ENUM_LITERAL(ty = t as Type.ENUMERATION())
        then Absyn.pathString(t.typePath) + "." + exp.name;

      case CREF() then ComponentRef.toString(exp.cref);
      case TYPENAME() then Type.toString(exp.ty);
      case ARRAY() then "{" + stringDelimitList(list(toString(e) for e in exp.elements), ", ") + "}";

      case RANGE() then toString(exp.start) +
                        (
                        if isSome(exp.step)
                        then ":" + toString(Util.getOption(exp.step))
                        else ""
                        ) + ":" + toString(exp.stop);
      case TUPLE() then "(" + stringDelimitList(list(toString(e) for e in exp.elements), ", ") + ")";
      case CALL() then Call.toString(exp.call);
      case SIZE() then "size(" + toString(exp.exp) +
                        (
                        if isSome(exp.dimIndex)
                        then ", " + toString(Util.getOption(exp.dimIndex))
                        else ""
                        ) + ")";
      case END() then "end";
      case BINARY() then "(" + toString(exp.exp1) + Operator.symbol(exp.operator) + toString(exp.exp2) + ")";
      case UNARY() then "(" + Operator.symbol(exp.operator) + " " + toString(exp.exp) + ")";
      case LBINARY() then "(" + toString(exp.exp1) + Operator.symbol(exp.operator) + toString(exp.exp2) + ")";
      case LUNARY() then "(" + Operator.symbol(exp.operator) + " " + toString(exp.exp) + ")";

      case RELATION() then "(" + toString(exp.exp1) + Operator.symbol(exp.operator) + toString(exp.exp2) + ")";
      case IF() then "if" + toString(exp.condition) + " then " + toString(exp.trueBranch) + " else " + toString(exp.falseBranch);

      case UNBOX() then "UNBOX(" + toString(exp.exp) + ")";

      case CAST() then "CAST(" + Type.toString(exp.ty) + ", " + toString(exp.exp) + ")";

      else anyString(exp);
    end match;
  end toString;

  function toDAE
    input Expression exp;
    output DAE.Exp dexp;
  algorithm
    dexp := match exp
      local
        Type ty;

      case INTEGER() then DAE.ICONST(exp.value);
      case REAL() then DAE.RCONST(exp.value);
      case STRING() then DAE.SCONST(exp.value);
      case BOOLEAN() then DAE.BCONST(exp.value);
      case ENUM_LITERAL(ty = ty as Type.ENUMERATION())
        then DAE.ENUM_LITERAL(Absyn.suffixPath(ty.typePath, exp.name), exp.index);

      case CREF()
        then DAE.CREF(ComponentRef.toDAE(exp.cref), DAE.T_UNKNOWN_DEFAULT);

      // TYPENAME() doesn't have a DAE representation, and shouldn't need to be
      // converted anyway.

      case ARRAY()
        then DAE.ARRAY(Type.toDAE(exp.ty), Type.isScalarArray(exp.ty),
          list(toDAE(e) for e in exp.elements));

      case RECORD()
        then DAE.RECORD(exp.path, list(toDAE(e) for e in exp.elements), {}, Type.toDAE(exp.ty));

      case RANGE()
        then DAE.RANGE(
               Type.toDAE(exp.ty),
               toDAE(exp.start),
               if isSome(exp.step)
               then SOME(toDAE(Util.getOption(exp.step)))
               else NONE(),
               toDAE(exp.stop));

      case TUPLE() then DAE.TUPLE(list(toDAE(e) for e in exp.elements));
      case CALL() then Call.toDAE(exp.call);

      case SIZE()
        then DAE.SIZE(toDAE(exp.exp),
               if isSome(exp.dimIndex)
               then SOME(toDAE(Util.getOption(exp.dimIndex)))
               else NONE());

      // END() doesn't have a DAE representation.

      case BINARY()
        then DAE.BINARY(toDAE(exp.exp1), Operator.toDAE(exp.operator), toDAE(exp.exp2));

      case UNARY()
        then DAE.UNARY(Operator.toDAE(exp.operator), toDAE(exp.exp));

      case LBINARY()
        then DAE.LBINARY(toDAE(exp.exp1), Operator.toDAE(exp.operator), toDAE(exp.exp2));

      case LUNARY()
        then DAE.LUNARY(Operator.toDAE(exp.operator), toDAE(exp.exp));

      case RELATION()
        then DAE.RELATION(toDAE(exp.exp1), Operator.toDAE(exp.operator), toDAE(exp.exp2), 0, NONE());

      case IF()
        then DAE.IFEXP(toDAE(exp.condition), toDAE(exp.trueBranch), toDAE(exp.falseBranch));

      case CAST() then DAE.CAST(Type.toDAE(exp.ty), toDAE(exp.exp));

      case UNBOX()
        then DAE.UNBOX(toDAE(exp.exp), Type.toDAE(exp.ty));

      else
        algorithm
          assert(false, getInstanceName() + " got unknown expression '" + toString(exp) + "'");
        then
          fail();

    end match;
  end toDAE;

  function dimensionCount
    input Expression exp;
    output Integer dimCount;
  algorithm
    dimCount := match exp
      case ARRAY(ty = Type.UNKNOWN())
        then 1 + dimensionCount(listHead(exp.elements));
      case ARRAY() then Type.dimensionCount(exp.ty);
      case RANGE() then Type.dimensionCount(exp.ty);
      case SIZE(dimIndex = NONE()) then dimensionCount(exp.exp);
      case CAST() then dimensionCount(exp.exp);
      // TODO: Add more expressions.
      else 0;
    end match;
  end dimensionCount;

  function traverse
    input Expression exp;
    input TraverseFunc func;
    output Expression outExp;

    partial function TraverseFunc
      input output Expression e;
    end TraverseFunc;
  algorithm
    outExp := match exp
      local
        Expression e1, e2, e3, e4;

      case CREF() then CREF(exp.ty, traverseCref(exp.cref, func));
      case ARRAY() then ARRAY(exp.ty, list(traverse(e, func) for e in exp.elements));

      case RANGE(step = SOME(e2))
        algorithm
          e1 := traverse(exp.start, func);
          e4 := traverse(e2, func);
          e3 := traverse(exp.stop, func);
        then
          if referenceEq(exp.start, e1) and referenceEq(e2, e4) and
            referenceEq(exp.stop, e3) then exp else RANGE(exp.ty, e1, SOME(e4), e3);

      case RANGE()
        algorithm
          e1 := traverse(exp.start, func);
          e3 := traverse(exp.stop, func);
        then
          if referenceEq(exp.start, e1) and referenceEq(exp.stop, e3)
            then exp else RANGE(exp.ty, e1, NONE(), e3);

      case TUPLE() then TUPLE(exp.ty, list(traverse(e, func) for e in exp.elements));

      case RECORD()
        then RECORD(exp.path, exp.ty, list(traverse(e, func) for e in exp.elements));

      case CALL() then CALL(traverseCall(exp.call, func));

      case SIZE(dimIndex = SOME(e2))
        algorithm
          e1 := traverse(exp.exp, func);
          e3 := traverse(e2, func);
        then
          if referenceEq(exp.exp, e1) and referenceEq(e2, e3) then exp else SIZE(e1, SOME(e3));

      case SIZE()
        algorithm
          e1 := traverse(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else SIZE(e1, NONE());

      case BINARY()
        algorithm
          e1 := traverse(exp.exp1, func);
          e2 := traverse(exp.exp2, func);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else BINARY(e1, exp.operator, e2);

      case UNARY()
        algorithm
          e1 := traverse(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else UNARY(exp.operator, e1);

      case LBINARY()
        algorithm
          e1 := traverse(exp.exp1, func);
          e2 := traverse(exp.exp2, func);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else LBINARY(e1, exp.operator, e2);

      case LUNARY()
        algorithm
          e1 := traverse(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else LUNARY(exp.operator, e1);

      case RELATION()
        algorithm
          e1 := traverse(exp.exp1, func);
          e2 := traverse(exp.exp2, func);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else RELATION(e1, exp.operator, e2);

      case IF()
        algorithm
          e1 := traverse(exp.condition, func);
          e2 := traverse(exp.trueBranch, func);
          e3 := traverse(exp.falseBranch, func);
        then
          if referenceEq(exp.condition, e1) and referenceEq(exp.trueBranch, e2) and
             referenceEq(exp.falseBranch, e3) then exp else IF(e1, e2, e3);

      case CAST()
        algorithm
          e1 := traverse(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case UNBOX()
        algorithm
          e1 := traverse(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else UNBOX(e1, exp.ty);

      else exp;
    end match;

    outExp := func(outExp);
  end traverse;

  function traverseOpt
    input Option<Expression> exp;
    input TraverseFunc func;
    output Option<Expression> outExp;

    partial function TraverseFunc
      input output Expression e;
    end TraverseFunc;
  protected
    Expression e;
  algorithm
    if isSome(exp) then
      SOME(e) := exp;
      outExp := SOME(traverse(e, func));
    end if;
  end traverseOpt;

  function traverseCall
    input Call call;
    input TraverseFunc func;
    output Call outCall;

    partial function TraverseFunc
      input output Expression e;
    end TraverseFunc;
  algorithm
    outCall := match call
      local
        list<Expression> args;
        list<Function.NamedArg> nargs;
        list<Function.TypedArg> targs;
        list<Function.TypedNamedArg> tnargs;
        String s;
        Expression e;
        Type t;
        DAE.Const c;

      case Call.UNTYPED_CALL()
        algorithm
          args := list(traverse(arg, func) for arg in call.arguments);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            e := traverse(e, func);
            nargs := (s, e) :: nargs;
          end for;
        then
          Call.UNTYPED_CALL(call.ref, call.matchingFuncs, args, listReverse(nargs));

      case Call.ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.arguments loop
            (e, t, c) := arg;
            e := traverse(e, func);
            targs := (e, t, c) :: targs;
          end for;

          for arg in call.named_args loop
            (s, e, t, c) := arg;
            e := traverse(e, func);
            tnargs := (s, e, t, c) :: tnargs;
          end for;
        then
          Call.ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs));

      case Call.TYPED_CALL()
        algorithm
          args := list(traverse(arg, func) for arg in call.arguments);
        then
          Call.TYPED_CALL(call.fn, args, call.attributes);

    end match;
  end traverseCall;

  function traverseCref
    input ComponentRef cref;
    input TraverseFunc func;
    output ComponentRef outCref;

    partial function TraverseFunc
      input output Expression e;
    end TraverseFunc;
  algorithm
    outCref := match cref
      local
        list<Subscript> subs;
        ComponentRef rest;

      case ComponentRef.CREF()
        algorithm
          subs := list(traverseSubscript(s, func) for s in cref.subscripts);
          rest := traverseCref(cref.restCref, func);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end traverseCref;

  function traverseSubscript
    input Subscript subscript;
    input TraverseFunc func;
    output Subscript outSubscript;

    partial function TraverseFunc
      input output Expression e;
    end TraverseFunc;
  algorithm
    outSubscript := match subscript
      case Subscript.UNTYPED() then Subscript.UNTYPED(traverse(subscript.exp, func));
      case Subscript.INDEX() then Subscript.INDEX(traverse(subscript.index, func));
      case Subscript.SLICE() then Subscript.SLICE(traverse(subscript.slice, func));
      else subscript;
    end match;
  end traverseSubscript;

  function expand
    input output Expression exp;
  algorithm
    exp := match exp
      local
        RangeIterator range_iter;
        list<Expression> expl;

      case CREF(ty = Type.ARRAY()) then expandCref(exp);

      case ARRAY(ty = Type.ARRAY(elementType = Type.ARRAY()))
        algorithm
          exp.elements := list(expand(e) for e in exp.elements);
        then
          exp;

      case RANGE()
        algorithm
          range_iter := RangeIterator.fromExp(exp);
        then
          ARRAY(exp.ty, RangeIterator.toList(range_iter));

      else exp;
    end match;
  end expand;

  function expandCref
    input Expression crefExp;
    output Expression arrayExp;
  protected
    list<list<list<Subscript>>> subs;
  algorithm
    arrayExp := match crefExp
      case CREF(cref = ComponentRef.CREF())
        algorithm
          subs := expandCref2(crefExp.cref);
        then
          expandCref3(subs, crefExp.cref, Type.arrayElementType(crefExp.ty));

      else crefExp;
    end match;
  end expandCref;

  function expandCref2
    input ComponentRef cref;
    input output list<list<list<Subscript>>> subs = {};
  protected
    list<list<Subscript>> cr_subs = {};
  algorithm
    subs := match cref
      case ComponentRef.CREF()
        algorithm
          for dim in listReverse(Type.arrayDims(cref.ty)) loop
            cr_subs := RangeIterator.map(RangeIterator.fromDim(dim), Subscript.makeIndex) :: cr_subs;
          end for;
        then
          expandCref2(cref.restCref, cr_subs :: subs);

      else subs;
    end match;
  end expandCref2;

  function expandCref3
    input list<list<list<Subscript>>> subs;
    input ComponentRef cref;
    input Type crefType;
    input list<list<Subscript>> accum = {};
    output Expression arrayExp;
  algorithm
    arrayExp := match subs
      case {} then CREF(crefType, ComponentRef.fillSubscripts(accum, cref));
      else expandCref4(listHead(subs), {}, accum, listRest(subs), cref, crefType);
    end match;
  end expandCref3;

  function expandCref4
    input list<list<Subscript>> subs;
    input list<Subscript> comb = {};
    input list<list<Subscript>> accum = {};
    input list<list<list<Subscript>>> restSubs;
    input ComponentRef cref;
    input Type crefType;
    output Expression arrayExp;
  protected
    list<Expression> expl = {};
    Type arr_ty;
  algorithm
    arrayExp := match subs
      case {} then expandCref3(restSubs, cref, crefType, listReverse(comb) :: accum);
      else
        algorithm
          expl := list(expandCref4(listRest(subs), sub :: comb, accum, restSubs, cref, crefType)
            for sub in listHead(subs));
          arr_ty := Type.liftArrayLeft(Expression.typeOf(listHead(expl)), Dimension.fromExpList(expl));
        then
          ARRAY(arr_ty, expl);
    end match;
  end expandCref4;

annotation(__OpenModelica_Interface="frontend");
end NFExpression;
