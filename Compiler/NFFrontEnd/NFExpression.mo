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
  import NFPrefixes.Variability;

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

  record SUBSCRIPTED_EXP
    Expression exp;
    list<Expression> subscripts;
    Type ty;
  end SUBSCRIPTED_EXP;

  record TUPLE_ELEMENT
    Expression tupleExp;
    Integer index;
    Type ty;
  end TUPLE_ELEMENT;

  record BOX "MetaModelica boxed value"
    Expression exp;
  end BOX;

  function isCref
    input Expression exp;
    output Boolean isTrue;
  algorithm
    isTrue := match exp
      case CREF() then true;
      else false;
    end match;
  end isCref;

  function isTrue
    input Expression exp;
    output Boolean isTrue;
  algorithm
    isTrue := match exp
      case BOOLEAN(true) then true;
      else false;
    end match;
  end isTrue;

  function isFalse
    input Expression exp;
    output Boolean isTrue;
  algorithm
    isTrue := match exp
      case BOOLEAN(false) then true;
      else false;
    end match;
  end isFalse;

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

      case SUBSCRIPTED_EXP()
        algorithm
          SUBSCRIPTED_EXP(exp = e1, subscripts = expl) := exp2;
          comp := compare(exp1.exp, e1);

          if comp == 0 then
            comp := compareList(exp1.subscripts, expl);
          end if;
        then
          comp;

      case TUPLE_ELEMENT()
        algorithm
          TUPLE_ELEMENT(tupleExp = e1, index = i) := exp2;
          comp := Util.intCompare(exp1.index, i);

          if comp == 0 then
            comp := compare(exp1.tupleExp, e1);
          end if;
        then
          comp;

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
    Expression e2;
    list<Expression> rest_expl2 = expl2;
  algorithm
    // Check that the lists have the same length, otherwise they can't be equal.
    comp := Util.intCompare(listLength(expl1), listLength(expl2));
    if comp <> 0 then
      return;
    end if;

    for e1 in expl1 loop
      e2 :: rest_expl2 := rest_expl2;
      comp := compare(e1, e2);

      // Return if the expressions are not equal.
      if comp <> 0 then
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
      case SUBSCRIPTED_EXP() then exp.ty;
      case TUPLE_ELEMENT() then exp.ty;
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
        algorithm
          t := typeOf(exp);
          t := Type.setArrayElementType(t, ty);
        then
          CAST(t, exp);

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

      case SUBSCRIPTED_EXP()
        then SUBSCRIPTED_EXP(array.exp, listAppend(array.subscripts, {INTEGER(index)}), Type.unliftArray(array.ty));

      else SUBSCRIPTED_EXP(array, {INTEGER(index)}, Type.unliftArray(typeOf(array)));
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

  function makeEnumLiteral
    input Type enumType;
    input Integer index;
    output Expression literal;
  protected
    list<String> literals;
  algorithm
    Type.ENUMERATION(literals = literals) := enumType;
    literal := ENUM_LITERAL(enumType, listGet(literals, index), index);
  end makeEnumLiteral;

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
      case INTEGER() then intString(exp.value);
      case REAL() then realString(exp.value);
      case STRING() then "\"" + exp.value + "\"";
      case BOOLEAN() then boolString(exp.value);

      case ENUM_LITERAL(ty = t as Type.ENUMERATION())
        then Absyn.pathString(t.typePath) + "." + exp.name;

      case CREF() then ComponentRef.toString(exp.cref);
      case TYPENAME() then Type.typenameString(Type.arrayElementType(exp.ty));
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
      case SUBSCRIPTED_EXP() then toString(exp.exp) + "[" + stringDelimitList(list(toString(e) for e in exp.subscripts), ", ") + "]";
      case TUPLE_ELEMENT() then toString(exp.tupleExp) + "[" + intString(exp.index) + "]";

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
        then DAE.CREF(ComponentRef.toDAE(exp.cref), Type.toDAE(exp.ty));

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

      case BOX()
        then DAE.BOX(toDAE(exp.exp));

      case UNBOX()
        then DAE.UNBOX(toDAE(exp.exp), Type.toDAE(exp.ty));

      case SUBSCRIPTED_EXP()
        then DAE.ASUB(toDAE(exp.exp), list(toDAE(s) for s in exp.subscripts));

      case TUPLE_ELEMENT()
        then DAE.TSUB(toDAE(exp.tupleExp), exp.index, Type.toDAE(exp.ty));

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
      case SUBSCRIPTED_EXP() then Type.dimensionCount(exp.ty);
      case TUPLE_ELEMENT() then Type.dimensionCount(exp.ty);
      // TODO: Add more expressions.
      else 0;
    end match;
  end dimensionCount;

  function map
    input Expression exp;
    input MapFunc func;
    output Expression outExp;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outExp := match exp
      local
        Expression e1, e2, e3, e4;

      case CREF() then CREF(exp.ty, mapCref(exp.cref, func));
      case ARRAY() then ARRAY(exp.ty, list(map(e, func) for e in exp.elements));

      case RANGE(step = SOME(e2))
        algorithm
          e1 := map(exp.start, func);
          e4 := map(e2, func);
          e3 := map(exp.stop, func);
        then
          if referenceEq(exp.start, e1) and referenceEq(e2, e4) and
            referenceEq(exp.stop, e3) then exp else RANGE(exp.ty, e1, SOME(e4), e3);

      case RANGE()
        algorithm
          e1 := map(exp.start, func);
          e3 := map(exp.stop, func);
        then
          if referenceEq(exp.start, e1) and referenceEq(exp.stop, e3)
            then exp else RANGE(exp.ty, e1, NONE(), e3);

      case TUPLE() then TUPLE(exp.ty, list(map(e, func) for e in exp.elements));

      case RECORD()
        then RECORD(exp.path, exp.ty, list(map(e, func) for e in exp.elements));

      case CALL() then CALL(mapCall(exp.call, func));

      case SIZE(dimIndex = SOME(e2))
        algorithm
          e1 := map(exp.exp, func);
          e3 := map(e2, func);
        then
          if referenceEq(exp.exp, e1) and referenceEq(e2, e3) then exp else SIZE(e1, SOME(e3));

      case SIZE()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else SIZE(e1, NONE());

      case BINARY()
        algorithm
          e1 := map(exp.exp1, func);
          e2 := map(exp.exp2, func);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else BINARY(e1, exp.operator, e2);

      case UNARY()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else UNARY(exp.operator, e1);

      case LBINARY()
        algorithm
          e1 := map(exp.exp1, func);
          e2 := map(exp.exp2, func);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else LBINARY(e1, exp.operator, e2);

      case LUNARY()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else LUNARY(exp.operator, e1);

      case RELATION()
        algorithm
          e1 := map(exp.exp1, func);
          e2 := map(exp.exp2, func);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else RELATION(e1, exp.operator, e2);

      case IF()
        algorithm
          e1 := map(exp.condition, func);
          e2 := map(exp.trueBranch, func);
          e3 := map(exp.falseBranch, func);
        then
          if referenceEq(exp.condition, e1) and referenceEq(exp.trueBranch, e2) and
             referenceEq(exp.falseBranch, e3) then exp else IF(e1, e2, e3);

      case CAST()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case UNBOX()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else UNBOX(e1, exp.ty);

      case SUBSCRIPTED_EXP()
        then SUBSCRIPTED_EXP(map(exp.exp, func), list(map(e, func) for e in exp.subscripts), exp.ty);

      case TUPLE_ELEMENT()
        algorithm
          e1 := map(exp.tupleExp, func);
        then
          if referenceEq(exp.tupleExp, e1) then exp else TUPLE_ELEMENT(e1, exp.index, exp.ty);

      else exp;
    end match;

    outExp := func(outExp);
  end map;

  function mapOpt
    input Option<Expression> exp;
    input MapFunc func;
    output Option<Expression> outExp;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    Expression e;
  algorithm
    if isSome(exp) then
      SOME(e) := exp;
      outExp := SOME(map(e, func));
    end if;
  end mapOpt;

  function mapCall
    input Call call;
    input MapFunc func;
    output Call outCall;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
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
        Variability v;

      case Call.UNTYPED_CALL()
        algorithm
          args := list(map(arg, func) for arg in call.arguments);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            e := map(e, func);
            nargs := (s, e) :: nargs;
          end for;
        then
          Call.UNTYPED_CALL(call.ref, call.matchingFuncs, args, listReverse(nargs));

      case Call.ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.arguments loop
            (e, t, v) := arg;
            e := map(e, func);
            targs := (e, t, v) :: targs;
          end for;

          for arg in call.named_args loop
            (s, e, t, v) := arg;
            e := map(e, func);
            tnargs := (s, e, t, v) :: tnargs;
          end for;
        then
          Call.ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs));

      case Call.TYPED_CALL()
        algorithm
          args := list(map(arg, func) for arg in call.arguments);
        then
          Call.TYPED_CALL(call.fn, call.ty, args, call.attributes);

      case Call.UNTYPED_MAP_CALL()
        algorithm
          e := map(call.exp, func);
        then
          Call.UNTYPED_MAP_CALL(call.ref, e, call.iters);

      case Call.TYPED_MAP_CALL()
        algorithm
          e := map(call.exp, func);
        then
          Call.TYPED_MAP_CALL(call.fn, call.ty, e, call.iters);

    end match;
  end mapCall;

  function mapCref
    input ComponentRef cref;
    input MapFunc func;
    output ComponentRef outCref;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        list<Subscript> subs;
        ComponentRef rest;

      case ComponentRef.CREF()
        algorithm
          subs := list(mapSubscript(s, func) for s in cref.subscripts);
          rest := mapCref(cref.restCref, func);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapCref;

  function mapSubscript
    input Subscript subscript;
    input MapFunc func;
    output Subscript outSubscript;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outSubscript := match subscript
      case Subscript.UNTYPED() then Subscript.UNTYPED(map(subscript.exp, func));
      case Subscript.INDEX() then Subscript.INDEX(map(subscript.index, func));
      case Subscript.SLICE() then Subscript.SLICE(map(subscript.slice, func));
      else subscript;
    end match;
  end mapSubscript;

  function fold<ArgT>
    input Expression exp;
    input FoldFunc func;
    input ArgT arg;
    output ArgT result;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    result := match exp
      local
        Expression e;

      case CREF() then foldCref(exp.cref, func, arg);
      case ARRAY() then List.fold(exp.elements, func, arg);

      case RANGE(step = SOME(e))
        algorithm
          result := fold(exp.start, func, arg);
          result := fold(e, func, result);
        then
          fold(exp.stop, func, result);

      case RANGE()
        algorithm
          result := fold(exp.start, func, arg);
        then
          fold(exp.stop, func, result);

      case TUPLE() then List.fold(exp.elements, func, arg);
      case RECORD() then List.fold(exp.elements, func, arg);
      case CALL() then foldCall(exp.call, func, arg);

      case SIZE(dimIndex = SOME(e))
        algorithm
          result := fold(exp.exp, func, arg);
        then
          fold(e, func, result);

      case SIZE() then fold(exp.exp, func, arg);

      case BINARY()
        algorithm
          result := fold(exp.exp1, func, arg);
        then
          fold(exp.exp2, func, result);

      case UNARY() then fold(exp.exp, func, arg);

      case LBINARY()
        algorithm
          result := fold(exp.exp1, func, arg);
        then
          fold(exp.exp2, func, result);

      case LUNARY() then fold(exp.exp, func, arg);

      case RELATION()
        algorithm
          result := fold(exp.exp1, func, arg);
        then
          fold(exp.exp2, func, result);

      case IF()
        algorithm
          result := fold(exp.condition, func, arg);
          result := fold(exp.trueBranch, func, result);
        then
          fold(exp.falseBranch, func, result);

      case CAST() then fold(exp.exp, func, arg);
      case UNBOX() then fold(exp.exp, func, arg);

      case SUBSCRIPTED_EXP()
        algorithm
          result := fold(exp.exp, func, arg);
        then
          List.fold(exp.subscripts, func, result);

      case TUPLE_ELEMENT() then fold(exp.tupleExp, func, arg);

      else arg;
    end match;

    result := func(exp, result);
  end fold;

  function foldCall<ArgT>
    input Call call;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    () := match call
      local
        Expression e;

      case Call.UNTYPED_CALL()
        algorithm
          arg := List.fold(call.arguments, func, arg);

          for arg in call.named_args loop
            (_, e) := arg;
            arg := fold(e, func, arg);
          end for;
        then
          ();

      case Call.ARG_TYPED_CALL()
        algorithm
          for arg in call.arguments loop
            (e, _, _) := arg;
            arg := fold(e, func, arg);
          end for;

          for arg in call.named_args loop
            (_, e, _, _) := arg;
            arg := fold(e, func, arg);
          end for;
        then
          ();

      case Call.TYPED_CALL()
        algorithm
          arg := List.fold(call.arguments, func, arg);
        then
          ();

      case Call.UNTYPED_MAP_CALL()
        algorithm
          arg := fold(call.exp, func, arg);
        then
          ();

      case Call.TYPED_MAP_CALL()
        algorithm
          arg := fold(call.exp, func, arg);
        then
          ();

    end match;
  end foldCall;

  function foldCref<ArgT>
    input ComponentRef cref;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    () := match cref
      case ComponentRef.CREF()
        algorithm
          arg := List.fold(cref.subscripts, function foldSubscript(func = func), arg);
          arg := foldCref(cref.restCref, func, arg);
        then
          ();

      else ();
    end match;
  end foldCref;

  function foldSubscript<ArgT>
    input Subscript subscript;
    input FoldFunc func;
    input ArgT arg;
    output ArgT result;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    result := match subscript
      case Subscript.UNTYPED() then fold(subscript.exp, func, arg);
      case Subscript.INDEX() then fold(subscript.index, func, arg);
      case Subscript.SLICE() then fold(subscript.slice, func, arg);
    end match;
  end foldSubscript;

  function mapFold<ArgT>
    input Expression exp;
    input MapFunc func;
          output Expression outExp;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outExp := match exp
      local
        Expression e1, e2, e3, e4;
        ComponentRef cr;
        list<Expression> expl;
        Call call;

      case CREF()
        algorithm
          (cr, arg) := mapFoldCref(exp.cref, func, arg);
       then
          if referenceEq(exp.cref, cr) then exp else CREF(exp.ty, cr);

      case ARRAY()
        algorithm
          (expl, arg) := List.map1Fold(exp.elements, mapFold, func, arg);
        then
          ARRAY(exp.ty, expl);

      case RANGE(step = SOME(e2))
        algorithm
          (e1, arg) := mapFold(exp.start, func, arg);
          (e4, arg) := mapFold(e2, func, arg);
          (e3, arg) := mapFold(exp.stop, func, arg);
        then
          if referenceEq(exp.start, e1) and referenceEq(e2, e4) and
            referenceEq(exp.stop, e3) then exp else RANGE(exp.ty, e1, SOME(e4), e3);

      case RANGE()
        algorithm
          (e1, arg) := mapFold(exp.start, func, arg);
          (e3, arg) := mapFold(exp.stop, func, arg);
        then
          if referenceEq(exp.start, e1) and referenceEq(exp.stop, e3)
            then exp else RANGE(exp.ty, e1, NONE(), e3);

      case TUPLE()
        algorithm
          (expl, arg) := List.map1Fold(exp.elements, mapFold, func, arg);
        then
          TUPLE(exp.ty, expl);

      case RECORD()
        algorithm
          (expl, arg) := List.map1Fold(exp.elements, mapFold, func, arg);
        then
          RECORD(exp.path, exp.ty, expl);

      case CALL()
        algorithm
          (call, arg) := mapFoldCall(exp.call, func, arg);
        then
          if referenceEq(exp.call, call) then exp else CALL(call);

      case SIZE(dimIndex = SOME(e2))
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
          (e3, arg) := mapFold(e2, func, arg);
        then
          if referenceEq(exp.exp, e1) and referenceEq(e2, e3) then exp else SIZE(e1, SOME(e3));

      case SIZE()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else SIZE(e1, NONE());

      case BINARY()
        algorithm
          (e1, arg) := mapFold(exp.exp1, func, arg);
          (e2, arg) := mapFold(exp.exp2, func, arg);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else BINARY(e1, exp.operator, e2);

      case UNARY()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else UNARY(exp.operator, e1);

      case LBINARY()
        algorithm
          (e1, arg) := mapFold(exp.exp1, func, arg);
          (e2, arg) := mapFold(exp.exp2, func, arg);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else LBINARY(e1, exp.operator, e2);

      case LUNARY()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else LUNARY(exp.operator, e1);

      case RELATION()
        algorithm
          (e1, arg) := mapFold(exp.exp1, func, arg);
          (e2, arg) := mapFold(exp.exp2, func, arg);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else RELATION(e1, exp.operator, e2);

      case IF()
        algorithm
          (e1, arg) := mapFold(exp.condition, func, arg);
          (e2, arg) := mapFold(exp.trueBranch, func, arg);
          (e3, arg) := mapFold(exp.falseBranch, func, arg);
        then
          if referenceEq(exp.condition, e1) and referenceEq(exp.trueBranch, e2) and
             referenceEq(exp.falseBranch, e3) then exp else IF(e1, e2, e3);

      case CAST()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case UNBOX()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else UNBOX(e1, exp.ty);

      case SUBSCRIPTED_EXP()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
          (expl, arg) := List.map1Fold(exp.subscripts, mapFold, func, arg);
        then
          SUBSCRIPTED_EXP(e1, expl, exp.ty);

      case TUPLE_ELEMENT()
        algorithm
          (e1, arg) := mapFold(exp.tupleExp, func, arg);
        then
          if referenceEq(exp.tupleExp, e1) then exp else TUPLE_ELEMENT(e1, exp.index, exp.ty);

      else exp;
    end match;

    (outExp, arg) := func(outExp, arg);
  end mapFold;

  function mapFoldOpt<ArgT>
    input Option<Expression> exp;
    input MapFunc func;
          output Option<Expression> outExp;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    Expression e;
  algorithm
    if isSome(exp) then
      SOME(e) := exp;
      (e, arg) := mapFold(e, func, arg);
      outExp := SOME(e);
    end if;
  end mapFoldOpt;

  function mapFoldCall<ArgT>
    input Call call;
    input MapFunc func;
          output Call outCall;
    input output ArgT foldArg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
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
        Variability v;

      case Call.UNTYPED_CALL()
        algorithm
          (args, foldArg) := List.map1Fold(call.arguments, mapFold, func, foldArg);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            (e, foldArg) := mapFold(e, func, foldArg);
            nargs := (s, e) :: nargs;
          end for;
        then
          Call.UNTYPED_CALL(call.ref, call.matchingFuncs, args, listReverse(nargs));

      case Call.ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.arguments loop
            (e, t, v) := arg;
            (e, foldArg) := mapFold(e, func, foldArg);
            targs := (e, t, v) :: targs;
          end for;

          for arg in call.named_args loop
            (s, e, t, v) := arg;
            (e, foldArg) := mapFold(e, func, foldArg);
            tnargs := (s, e, t, v) :: tnargs;
          end for;
        then
          Call.ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs));

      case Call.TYPED_CALL()
        algorithm
          (args, foldArg) := List.map1Fold(call.arguments, mapFold, func, foldArg);
        then
          Call.TYPED_CALL(call.fn, call.ty, args, call.attributes);

      case Call.UNTYPED_MAP_CALL()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.UNTYPED_MAP_CALL(call.ref, e, call.iters);

      case Call.TYPED_MAP_CALL()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.TYPED_MAP_CALL(call.fn, call.ty, e, call.iters);

    end match;
  end mapFoldCall;

  function mapFoldCref<ArgT>
    input ComponentRef cref;
    input MapFunc func;
          output ComponentRef outCref;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        list<Subscript> subs;
        ComponentRef rest;

      case ComponentRef.CREF()
        algorithm
          (subs, arg) := List.map1Fold(cref.subscripts, mapFoldSubscript, func, arg);
          (rest, arg) := mapFoldCref(cref.restCref, func, arg);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapFoldCref;

  function mapFoldSubscript<ArgT>
    input Subscript subscript;
    input MapFunc func;
          output Subscript outSubscript;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  algorithm
    outSubscript := match subscript
      local
        Expression exp;

      case Subscript.UNTYPED()
        algorithm
          (exp, arg) := mapFold(subscript.exp, func, arg);
        then
          if referenceEq(subscript.exp, exp) then subscript else Subscript.UNTYPED(exp);

      case Subscript.INDEX()
        algorithm
          (exp, arg) := mapFold(subscript.index, func, arg);
        then
          if referenceEq(subscript.index, exp) then subscript else Subscript.INDEX(exp);

      case Subscript.SLICE()
        algorithm
          (exp, arg) := mapFold(subscript.slice, func, arg);
        then
          if referenceEq(subscript.slice, exp) then subscript else Subscript.SLICE(exp);

      else subscript;
    end match;
  end mapFoldSubscript;

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

  function arrayFirstScalar
    "Returns the first scalar element of an array. Fails if the array is empty."
    input Expression arrayExp;
    output Expression exp;
  algorithm
    exp := match arrayExp
      case ARRAY() then arrayFirstScalar(listHead(arrayExp.elements));
      else arrayExp;
    end match;
  end arrayFirstScalar;

  function arrayAllEqual
    "Checks if all scalar elements in an array are equal to each other."
    input Expression arrayExp;
    output Boolean allEqual;
  algorithm
    allEqual := matchcontinue arrayExp
      case ARRAY()
        then arrayAllEqual2(arrayExp, arrayFirstScalar(arrayExp));
      else true;
    end matchcontinue;
  end arrayAllEqual;

  function arrayAllEqual2
    input Expression arrayExp;
    input Expression element;
    output Boolean allEqual;
  algorithm
    allEqual := match arrayExp
      case ARRAY(elements = ARRAY() :: _)
        then List.map1BoolAnd(arrayExp.elements, arrayAllEqual2, element);
      case ARRAY()
        then List.map1BoolAnd(arrayExp.elements, isEqual, element);
      else true;
    end match;
  end arrayAllEqual2;

  function fromCref
    input ComponentRef cref;
    output Expression exp;
  algorithm
    exp := Expression.CREF(ComponentRef.getType(cref), cref);
  end fromCref;

  function toCref
    input Expression exp;
    output ComponentRef cref;
  algorithm
    Expression.CREF(cref = cref) := exp;
  end toCref;

  function isZero
    input Expression exp;
    output Boolean isZero;
  algorithm
    isZero := match exp
      case INTEGER() then exp.value == 0;
      case REAL() then exp.value == 0.0;
      case CAST() then isZero(exp.exp);
      case UNARY() then isZero(exp.exp);
      else false;
    end match;
  end isZero;

  function isScalarConst
    input Expression exp;
    output Boolean isScalar;
  algorithm
    isScalar := match exp
      case INTEGER() then true;
      case REAL() then true;
      case STRING() then true;
      case BOOLEAN() then true;
      case ENUM_LITERAL() then true;
      else false;
    end match;
  end isScalarConst;

annotation(__OpenModelica_Interface="frontend");
end NFExpression;
