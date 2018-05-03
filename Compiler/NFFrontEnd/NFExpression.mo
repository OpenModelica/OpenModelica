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

  import Builtin = NFBuiltin;
  import Expression = NFExpression;
  import Function = NFFunction;
  import RangeIterator = NFRangeIterator;
  import NFPrefixes.Variability;
  import Prefixes = NFPrefixes;
  import Ceval = NFCeval;
  import MetaModelica.Dangerous.listReverseInPlace;

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
  import Binding = NFBinding;
  import NFComponent.Component;

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

  record MATRIX "The array concatentation operator [a,b; c,d]; this should be removed during type-checking"
    // Does not have a type since we only keep this operator before type-checking
    list<list<Expression>> elements;
  end MATRIX;

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

  record MUTABLE
    Mutable<Expression> exp;
  end MUTABLE;

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

  function isAllTrue
    input Expression exp;
    output Boolean isTrue;
  algorithm
    isTrue := match exp
      case BOOLEAN(true) then true;
      case ARRAY()
        algorithm
          for e in exp.elements loop
            if not isAllTrue(e) then
              isTrue := false;
              return;
            end if;
          end for;
        then
          true;

      else false;
    end match;
  end isAllTrue;

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
          Error.assertion(false, getInstanceName() + " got unknown expression.", sourceInfo());
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
      case BOX() then Type.METABOXED(typeOf(exp.exp));
      else Type.UNKNOWN();
    end match;
  end typeOf;

  function typeCast
    input Expression exp;
    input Type castTy;
    output Expression castExp = CAST(castTy, exp);
  end typeCast;

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

  function integerValue
    input Expression exp;
    output Integer value;
  algorithm
    INTEGER(value=value) := exp;
  end integerValue;

  function applySubscripts
    input list<Subscript> subscripts;
    input output Expression exp;
  algorithm
    for sub in subscripts loop
      exp := applySubscript(sub, exp);
    end for;
  end applySubscripts;

  function applySubscript
    input Subscript sub;
    input Expression exp;
    output Expression subscriptedExp;
  algorithm
    subscriptedExp := match sub
      case Subscript.INDEX() then applyIndexSubscript(sub.index, exp);
      case Subscript.SLICE() then applySliceSubscript(sub.slice, exp);
      case Subscript.WHOLE() then exp;
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped subscript " +
            Subscript.toString(sub), sourceInfo());
        then
          fail();
    end match;
  end applySubscript;

  function applyIndexSubscript
    input Expression indexExp;
    input output Expression exp;
  protected
    Boolean is_scalar_const;
    Expression texp;
    Type exp_ty;
    ComponentRef cref;
  algorithm
    is_scalar_const := isScalarConst(indexExp);

    // check exp has array type. Don't apply subs to scalar exp.
    exp_ty := typeOf(exp);
    if not Type.isArray(exp_ty) then
      Error.assertion(false, getInstanceName() + ": Application of subs on non-array expression not allowed. " +
        "Exp: " + toString(exp) + ", Exp type: " + Type.toString(exp_ty) + ", Sub: " + toString(indexExp), sourceInfo());
      fail();
    end if;

    exp := match exp
      case CREF()
        algorithm
          cref := ComponentRef.addSubscript(Subscript.INDEX(indexExp), exp.cref);
        then
          CREF(Type.unliftArray(exp.ty), cref);

      case TYPENAME() guard is_scalar_const
        then applyIndexSubscriptTypename(exp.ty, toInteger(indexExp));

      case ARRAY()
        algorithm
          if is_scalar_const then
            texp := listGet(exp.elements, toInteger(indexExp));
          else
            texp := SUBSCRIPTED_EXP(exp, {indexExp}, Type.unliftArray(exp.ty));
          end if;
        then
          texp;

      case RANGE() guard is_scalar_const
        then applyIndexSubscriptRange(exp.start, exp.step, exp.stop, toInteger(indexExp));

      case CALL(call = Call.TYPED_MAP_CALL())
        then applyIndexSubscriptReduction(exp.call, indexExp);

      case SUBSCRIPTED_EXP()
        then SUBSCRIPTED_EXP(exp.exp, listAppend(exp.subscripts,{indexExp}), Type.unliftArray(exp.ty));

      else SUBSCRIPTED_EXP(exp, {indexExp}, Type.unliftArray(exp_ty));
    end match;
  end applyIndexSubscript;

  function applyIndexSubscriptTypename
    input Type ty;
    input Integer index;
    output Expression subscriptedExp;
  algorithm
    subscriptedExp := match ty
      case Type.BOOLEAN() guard index <= 2
        then if index == 1 then Expression.BOOLEAN(false) else Expression.BOOLEAN(true);

      case Type.ENUMERATION()
        then Expression.ENUM_LITERAL(ty, Type.nthEnumLiteral(ty, index), index);
    end match;
  end applyIndexSubscriptTypename;

  function applyIndexSubscriptRange
    input Expression startExp;
    input Option<Expression> stepExp;
    input Expression stopExp;
    input Integer index;
    output Expression subscriptedExp;
  protected
    Integer iidx;
    Real ridx;
  algorithm
    subscriptedExp := match (startExp, stepExp)
      case (Expression.INTEGER(), SOME(Expression.INTEGER(iidx)))
        then Expression.INTEGER(startExp.value + index * iidx - 1);

      case (Expression.INTEGER(), _)
        then Expression.INTEGER(startExp.value + index - 1);

      case (Expression.REAL(), SOME(Expression.REAL(ridx)))
        then Expression.REAL(startExp.value + index * ridx - 1);

      case (Expression.REAL(), _)
        then Expression.REAL(startExp.value + index - 1.0);

      case (Expression.BOOLEAN(), _)
        then if index == 1 then startExp else stopExp;

      case (Expression.ENUM_LITERAL(index = iidx), _)
        algorithm
          iidx := iidx + index - 1;
        then
          ENUM_LITERAL(startExp.ty, Type.nthEnumLiteral(startExp.ty, iidx), iidx);

    end match;
  end applyIndexSubscriptRange;

  function applyIndexSubscriptReduction
    input Call call;
    input Expression indexExp;
    output Expression subscriptedExp;
  protected
    Type ty;
    Variability var;
    Expression exp, iter_exp;
    list<tuple<InstNode, Expression>> iters;
    InstNode iter;
  algorithm
    Call.TYPED_MAP_CALL(ty, var, exp, iters) := call;
    ((iter, iter_exp), iters) := List.splitLast(iters);
    iter_exp := applyIndexSubscript(indexExp, iter_exp);
    subscriptedExp := replaceIterator(exp, iter, iter_exp);

    if not listEmpty(iters) then
      subscriptedExp := CALL(Call.TYPED_MAP_CALL(Type.unliftArray(ty), var, subscriptedExp, iters));
    end if;
  end applyIndexSubscriptReduction;

  function replaceIterator
    input output Expression exp;
    input InstNode iterator;
    input Expression iteratorValue;
  algorithm
    exp := map(exp, function replaceIterator2(iterator = iterator, iteratorValue = iteratorValue));
  end replaceIterator;

  function replaceIterator2
    input output Expression exp;
    input InstNode iterator;
    input Expression iteratorValue;

    import Origin = NFComponentRef.Origin;
  algorithm
    exp := match exp
      local
        InstNode node;

      case CREF(cref = ComponentRef.CREF(node = node))
        then if InstNode.refEqual(iterator, node) then iteratorValue else exp;

      else exp;
    end match;
  end replaceIterator2;

  function applySliceSubscript
    input Expression slice;
    input Expression exp;
    output Expression subscriptedExp;
  protected
    list<Expression> expl;
    RangeIterator iter;
    Expression e;
    Type ty;
    ComponentRef cref;
  algorithm
    // Replace the last dimension of the expression type with the dimension of the slice type.
    ty := Type.liftArrayLeft(Type.unliftArray(typeOf(exp)), Type.nthDimension(typeOf(slice), 1));
    iter := RangeIterator.fromExp(slice);

    if RangeIterator.isValid(iter) then
      // If the slice is a range of known size, apply each subscript in the slice
      // to the expression and create a new array from the resulting elements.
      expl := {};

      while RangeIterator.hasNext(iter) loop
        (iter, e) := RangeIterator.next(iter);
        e := applyIndexSubscript(e, exp);
        expl := e :: expl;
      end while;

      ty := Type.liftArrayLeft(Type.unliftArray(typeOf(exp)), Dimension.fromInteger(listLength(expl)));
      subscriptedExp := ARRAY(ty, listReverseInPlace(expl));
    else
      // If the slice can't be expanded, just add it to the expression as a slice subscript.
      subscriptedExp := match exp
        case CREF()
          algorithm
            cref := ComponentRef.addSubscript(Subscript.SLICE(slice), exp.cref);
          then
            CREF(ty, cref);

        case SUBSCRIPTED_EXP()
          then SUBSCRIPTED_EXP(exp.exp, listAppend(exp.subscripts, {slice}), ty);

        else SUBSCRIPTED_EXP(exp, {slice}, ty);
      end match;
    end if;
  end applySliceSubscript;

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
    Error.assertion(not listEmpty(inDims), "Empty dimension list given in arrayFromList.", sourceInfo());

    ldim::restdims := inDims;
    dimsize := Dimension.size(ldim);
    ty := Type.liftArrayLeft(elemTy, ldim);

    if List.hasOneElement(inDims) then
      Error.assertion(dimsize == listLength(inExps), "Length mismatch in arrayFromList.", sourceInfo());
      outExp := ARRAY(ty,inExps);
      return;
    end if;

    partexps := List.partition(inExps, dimsize);

    newlst := {};
    for arrexp in partexps loop
      newlst := ARRAY(ty,arrexp)::newlst;
    end for;

    newlst := listReverse(newlst);
    outExp := arrayFromList_impl(newlst, ty, restdims);
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
      else fail();
    end match;
  end toInteger;

  function toStringTyped
    input Expression exp;
    output String str;
  algorithm
    str := "/*" + Type.toString(typeOf(exp)) + "*/ " + toString(exp);
  end toStringTyped;

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
      case MATRIX() then "[" + stringDelimitList(list(stringDelimitList(list(toString(e) for e in el), ", ") for el in exp.elements), "; ") + "]";

      case RANGE() then operandString(exp.start, exp, false) +
                        (
                        if isSome(exp.step)
                        then ":" + operandString(Util.getOption(exp.step), exp, false)
                        else ""
                        ) + ":" + operandString(exp.stop, exp, false);

      case TUPLE() then "(" + stringDelimitList(list(toString(e) for e in exp.elements), ", ") + ")";
      case RECORD() then List.toString(exp.elements, toString, Absyn.pathString(exp.path), "(", ", ", ")", true);
      case CALL() then Call.toString(exp.call);
      case SIZE() then "size(" + toString(exp.exp) +
                        (
                        if isSome(exp.dimIndex)
                        then ", " + toString(Util.getOption(exp.dimIndex))
                        else ""
                        ) + ")";
      case END() then "end";

      case BINARY() then operandString(exp.exp1, exp, true) +
                         Operator.symbol(exp.operator) +
                         operandString(exp.exp2, exp, false);

      case UNARY() then Operator.symbol(exp.operator, "") +
                        operandString(exp.exp, exp, false);

      case LBINARY() then operandString(exp.exp1, exp, true) +
                          Operator.symbol(exp.operator) +
                          operandString(exp.exp2, exp, false);

      case LUNARY() then Operator.symbol(exp.operator, "") + " " +
                         operandString(exp.exp, exp, false);

      case RELATION() then operandString(exp.exp1, exp, true) +
                           Operator.symbol(exp.operator) +
                           operandString(exp.exp2, exp, false);

      case IF() then "if " + toString(exp.condition) + " then " + toString(exp.trueBranch) + " else " + toString(exp.falseBranch);

      case UNBOX() then "UNBOX(" + toString(exp.exp) + ")";
      case CAST() then "CAST(" + Type.toString(exp.ty) + ", " + toString(exp.exp) + ")";
      case SUBSCRIPTED_EXP() then toString(exp.exp) + "[" + stringDelimitList(list(toString(e) for e in exp.subscripts), ", ") + "]";
      case TUPLE_ELEMENT() then toString(exp.tupleExp) + "[" + intString(exp.index) + "]";
      case MUTABLE() then toString(Mutable.access(exp.exp));

      else anyString(exp);
    end match;
  end toString;

  function operandString
    "Helper function to toString, prints an operator and adds parentheses as needed."
    input Expression operand;
    input Expression operator;
    input Boolean lhs;
    output String str;
  protected
    Integer operand_prio, operator_prio;
  algorithm
    str := toString(operand);

    operand_prio := priority(operand, lhs);
    if operand_prio <> 4 then
      operator_prio := priority(operator, lhs);

      if operand_prio > operator_prio or
         not lhs and operand_prio == operator_prio and not isAssociativeExp(operand) then
        str := "(" + str + ")";
      end if;
    end if;
  end operandString;

  function priority
    input Expression exp;
    input Boolean lhs;
    output Integer priority;
  algorithm
    priority := match exp
      case BINARY() then Operator.priority(exp.operator, lhs);
      case UNARY() then 4;
      case LBINARY() then Operator.priority(exp.operator, lhs);
      case LUNARY() then 7;
      case RELATION() then 6;
      case RANGE() then 10;
      case IF() then 11;
      else 0;
    end match;
  end priority;

  function isAssociativeExp
    input Expression exp;
    output Boolean isAssociative;
  algorithm
    isAssociative := match exp
      case BINARY() then Operator.isAssociative(exp.operator);
      case LBINARY() then true;
      else false;
    end match;
  end isAssociativeExp;

  function toDAE
    input Expression exp;
    output DAE.Exp dexp;
  algorithm
    dexp := match exp
      local
        Type ty;
        DAE.Operator daeOp;
        Boolean swap;
        DAE.Exp dae1, dae2;

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
               Type.toDAE(Type.arrayElementType(exp.ty)),
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
        algorithm
          (daeOp, swap) := Operator.toDAE(exp.operator);
          dae1 := toDAE(exp.exp1);
          dae2 := toDAE(exp.exp2);
        then DAE.BINARY(if swap then dae2 else dae1, daeOp, if swap then dae1 else dae2);

      case UNARY()
        then DAE.UNARY(Operator.toDAE(exp.operator), toDAE(exp.exp));

      case LBINARY()
        then DAE.LBINARY(toDAE(exp.exp1), Operator.toDAE(exp.operator), toDAE(exp.exp2));

      case LUNARY()
        then DAE.LUNARY(Operator.toDAE(exp.operator), toDAE(exp.exp));

      case RELATION()
        then DAE.RELATION(toDAE(exp.exp1), Operator.toDAE(exp.operator), toDAE(exp.exp2), -1, NONE());

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
          Error.assertion(false, getInstanceName() + " got unknown expression '" + toString(exp) + "'", sourceInfo());
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
      case MATRIX() then MATRIX(list(list(map(e, func) for e in row) for row in exp.elements));

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

      case BOX()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else BOX(e1);

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
          Call.UNTYPED_CALL(call.ref, args, listReverse(nargs), call.call_scope);

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
          Call.ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case Call.TYPED_CALL()
        algorithm
          args := list(map(arg, func) for arg in call.arguments);
        then
          Call.TYPED_CALL(call.fn, call.ty, call.var, args, call.attributes);

      case Call.UNTYPED_MAP_CALL()
        algorithm
          e := map(call.exp, func);
        then
          Call.UNTYPED_MAP_CALL(e, call.iters);

      case Call.TYPED_MAP_CALL()
        algorithm
          e := map(call.exp, func);
        then
          Call.TYPED_MAP_CALL(call.ty, call.var, e, call.iters);

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

  function mapShallow
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

      case CREF() then CREF(exp.ty, mapCrefShallow(exp.cref, func));
      case ARRAY() then ARRAY(exp.ty, list(func(e) for e in exp.elements));
      case MATRIX() then MATRIX(list(list(func(e) for e in row) for row in exp.elements));

      case RANGE(step = SOME(e2))
        algorithm
          e1 := func(exp.start);
          e4 := func(e2);
          e3 := func(exp.stop);
        then
          if referenceEq(exp.start, e1) and referenceEq(e2, e4) and
            referenceEq(exp.stop, e3) then exp else RANGE(exp.ty, e1, SOME(e4), e3);

      case RANGE()
        algorithm
          e1 := func(exp.start);
          e3 := func(exp.stop);
        then
          if referenceEq(exp.start, e1) and referenceEq(exp.stop, e3)
            then exp else RANGE(exp.ty, e1, NONE(), e3);

      case TUPLE() then TUPLE(exp.ty, list(func(e) for e in exp.elements));

      case RECORD()
        then RECORD(exp.path, exp.ty, list(func(e) for e in exp.elements));

      case CALL() then CALL(mapCallShallow(exp.call, func));

      case SIZE(dimIndex = SOME(e2))
        algorithm
          e1 := func(exp.exp);
          e3 := func(e2);
        then
          if referenceEq(exp.exp, e1) and referenceEq(e2, e3) then exp else SIZE(e1, SOME(e3));

      case SIZE()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else SIZE(e1, NONE());

      case BINARY()
        algorithm
          e1 := func(exp.exp1);
          e2 := func(exp.exp2);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else BINARY(e1, exp.operator, e2);

      case UNARY()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else UNARY(exp.operator, e1);

      case LBINARY()
        algorithm
          e1 := func(exp.exp1);
          e2 := func(exp.exp2);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else LBINARY(e1, exp.operator, e2);

      case LUNARY()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else LUNARY(exp.operator, e1);

      case RELATION()
        algorithm
          e1 := func(exp.exp1);
          e2 := func(exp.exp2);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else RELATION(e1, exp.operator, e2);

      case IF()
        algorithm
          e1 := func(exp.condition);
          e2 := func(exp.trueBranch);
          e3 := func(exp.falseBranch);
        then
          if referenceEq(exp.condition, e1) and referenceEq(exp.trueBranch, e2) and
             referenceEq(exp.falseBranch, e3) then exp else IF(e1, e2, e3);

      case CAST()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case UNBOX()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else UNBOX(e1, exp.ty);

      case SUBSCRIPTED_EXP()
        then SUBSCRIPTED_EXP(func(exp.exp), list(func(e) for e in exp.subscripts), exp.ty);

      case TUPLE_ELEMENT()
        algorithm
          e1 := func(exp.tupleExp);
        then
          if referenceEq(exp.tupleExp, e1) then exp else TUPLE_ELEMENT(e1, exp.index, exp.ty);

      case BOX()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else BOX(e1);

      else exp;
    end match;
  end mapShallow;

  function mapCrefShallow
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
          subs := list(mapSubscriptShallow(s, func) for s in cref.subscripts);
          rest := mapCref(cref.restCref, func);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapCrefShallow;

  function mapSubscriptShallow
    input Subscript subscript;
    input MapFunc func;
    output Subscript outSubscript;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outSubscript := match subscript
      case Subscript.UNTYPED() then Subscript.UNTYPED(func(subscript.exp));
      case Subscript.INDEX() then Subscript.INDEX(func(subscript.index));
      case Subscript.SLICE() then Subscript.SLICE(func(subscript.slice));
      else subscript;
    end match;
  end mapSubscriptShallow;

  function mapCallShallow
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
          args := list(func(arg) for arg in call.arguments);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            e := func(e);
            nargs := (s, e) :: nargs;
          end for;
        then
          Call.UNTYPED_CALL(call.ref, args, listReverse(nargs), call.call_scope);

      case Call.ARG_TYPED_CALL()
        algorithm
          targs := {};
          tnargs := {};

          for arg in call.arguments loop
            (e, t, v) := arg;
            e := func(e);
            targs := (e, t, v) :: targs;
          end for;

          for arg in call.named_args loop
            (s, e, t, v) := arg;
            e := func(e);
            tnargs := (s, e, t, v) :: tnargs;
          end for;
        then
          Call.ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case Call.TYPED_CALL()
        algorithm
          args := list(func(arg) for arg in call.arguments);
        then
          Call.TYPED_CALL(call.fn, call.ty, call.var, args, call.attributes);

      case Call.UNTYPED_MAP_CALL()
        algorithm
          e := func(call.exp);
        then
          Call.UNTYPED_MAP_CALL(e, call.iters);

      case Call.TYPED_MAP_CALL()
        algorithm
          e := func(call.exp);
        then
          Call.TYPED_MAP_CALL(call.ty, call.var, e, call.iters);

    end match;
  end mapCallShallow;

  function mapArrayElements
    "Applies the given function to each scalar elements of an array."
    input Expression exp;
    input MapFunc func;
    output Expression outExp;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outExp := match exp
      case ARRAY()
        algorithm
          exp.elements := list(mapArrayElements(e, func) for e in exp.elements);
        then
          exp;

      else func(exp);
    end match;
  end mapArrayElements;

  function foldList<ArgT>
    input list<Expression> expl;
    input FoldFunc func;
    input ArgT arg;
    output ArgT result = arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for e in expl loop
      result := fold(e, func, result);
    end for;
  end foldList;

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
      case ARRAY() then foldList(exp.elements, func, arg);

      case MATRIX()
        algorithm
          result := arg;
          for row in exp.elements loop
            result := foldList(row, func, result);
          end for;
        then
          result;

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

      case TUPLE() then foldList(exp.elements, func, arg);
      case RECORD() then foldList(exp.elements, func, arg);
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
          foldList(exp.subscripts, func, result);

      case TUPLE_ELEMENT() then fold(exp.tupleExp, func, arg);
      case BOX() then fold(exp.exp, func, arg);
      else arg;
    end match;

    result := func(exp, result);
  end fold;

  function foldCall<ArgT>
    input Call call;
    input FoldFunc func;
    input output ArgT foldArg;

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
          foldArg := foldList(call.arguments, func, foldArg);

          for arg in call.named_args loop
            (_, e) := arg;
            foldArg := fold(e, func, foldArg);
          end for;
        then
          ();

      case Call.ARG_TYPED_CALL()
        algorithm
          for arg in call.arguments loop
            (e, _, _) := arg;
            foldArg := fold(e, func, foldArg);
          end for;

          for arg in call.named_args loop
            (_, e, _, _) := arg;
            foldArg := fold(e, func, foldArg);
          end for;
        then
          ();

      case Call.TYPED_CALL()
        algorithm
          foldArg := foldList(call.arguments, func, foldArg);
        then
          ();

      case Call.UNTYPED_MAP_CALL()
        algorithm
          foldArg := fold(call.exp, func, foldArg);
        then
          ();

      case Call.TYPED_MAP_CALL()
        algorithm
          foldArg := fold(call.exp, func, foldArg);
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
      case Subscript.WHOLE() then arg;
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
          Call.UNTYPED_CALL(call.ref, args, listReverse(nargs), call.call_scope);

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
          Call.ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case Call.TYPED_CALL()
        algorithm
          (args, foldArg) := List.map1Fold(call.arguments, mapFold, func, foldArg);
        then
          Call.TYPED_CALL(call.fn, call.ty, call.var, args, call.attributes);

      case Call.UNTYPED_MAP_CALL()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.UNTYPED_MAP_CALL(e, call.iters);

      case Call.TYPED_MAP_CALL()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.TYPED_MAP_CALL(call.ty, call.var, e, call.iters);

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

  partial function ContainsPred
    input Expression exp;
    output Boolean res;
  end ContainsPred;

  function containsOpt
    input Option<Expression> exp;
    input ContainsPred func;
    output Boolean res;
  protected
    Expression e;
  algorithm
    res := match exp
      case SOME(e) then contains(e, func);
      else false;
    end match;
  end containsOpt;

  function contains
    input Expression exp;
    input ContainsPred func;
    output Boolean res;
  algorithm
    if func(exp) then
      res := true;
      return;
    end if;

    res := match exp
      local
        Expression e;

      case CREF() then crefContains(exp.cref, func);
      case ARRAY() then listContains(exp.elements, func);

      case MATRIX()
        algorithm
          res := false;

          for row in exp.elements loop
            if listContains(row, func) then
              res := true;
              break;
            end if;
          end for;
        then
          res;

      case RANGE()
        then contains(exp.start, func) or
             containsOpt(exp.step, func) or
             contains(exp.stop, func);

      case TUPLE() then listContains(exp.elements, func);
      case RECORD() then listContains(exp.elements, func);
      case CALL() then callContains(exp.call, func);

      case SIZE()
        then containsOpt(exp.dimIndex, func) or
             contains(exp.exp, func);

      case BINARY() then contains(exp.exp1, func) or contains(exp.exp2, func);
      case UNARY() then contains(exp.exp, func);
      case LBINARY() then contains(exp.exp1, func) or contains(exp.exp2, func);
      case LUNARY() then contains(exp.exp, func);
      case RELATION() then contains(exp.exp1, func) or contains(exp.exp2, func);

      case IF()
        then contains(exp.condition, func) or
             contains(exp.trueBranch, func) or
             contains(exp.falseBranch, func);

      case CAST() then contains(exp.exp, func);
      case UNBOX() then contains(exp.exp, func);

      case SUBSCRIPTED_EXP()
        then contains(exp.exp, func) or listContains(exp.subscripts, func);

      case TUPLE_ELEMENT()
        then contains(exp.tupleExp, func);

      case BOX() then contains(exp.exp, func);
      else false;
    end match;
  end contains;

  function crefContains
    input ComponentRef cref;
    input ContainsPred func;
    output Boolean res;
  algorithm
    res := match cref
      case ComponentRef.CREF()
        then subscriptsContains(cref.subscripts, func) or
             crefContains(cref.restCref, func);

      else false;
    end match;
  end crefContains;

  function subscriptsContains
    input list<Subscript> subs;
    input ContainsPred func;
    output Boolean res;
  algorithm
    for s in subs loop
      res := match s
        case Subscript.UNTYPED() then contains(s.exp, func);
        case Subscript.INDEX() then contains(s.index, func);
        case Subscript.SLICE() then contains(s.slice, func);
        else false;
      end match;

      if res then
        return;
      end if;
    end for;

    res := false;
  end subscriptsContains;

  function listContains
    input list<Expression> expl;
    input ContainsPred func;
    output Boolean res;
  algorithm
    for e in expl loop
      if contains(e, func) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end listContains;

  function callContains
    input Call call;
    input ContainsPred func;
    output Boolean res;
  algorithm
    res := match call
      local
        Expression e;

      case Call.UNTYPED_CALL()
        algorithm
          res := listContains(call.arguments, func);

          if not res then
            for arg in call.named_args loop
              (_, e) := arg;

              if contains(e, func) then
                res := true;
                break;
              end if;
            end for;
          end if;
        then
          res;

      case Call.ARG_TYPED_CALL()
        algorithm
          for arg in call.arguments loop
            (e, _, _) := arg;
            if contains(e, func) then
              res := true;
              return;
            end if;
          end for;

          for arg in call.named_args loop
            (_, e, _, _) := arg;
            if contains(e, func) then
              res := true;
              return;
            end if;
          end for;
        then
          false;

      case Call.TYPED_CALL() then listContains(call.arguments, func);
      case Call.UNTYPED_MAP_CALL() then contains(call.exp, func);
      case Call.TYPED_MAP_CALL() then contains(call.exp, func);
    end match;
  end callContains;

  function expand
    input output Expression exp;
  algorithm
    exp := match exp
      local
        RangeIterator range_iter;
        list<Expression> expl;

      case CREF(ty = Type.ARRAY()) then expandCref(exp);

      case ARRAY(ty = Type.ARRAY(dimensions = _ :: _ :: {}))
        algorithm
          exp.elements := list(expand(e) for e in exp.elements);
        then
          exp;

      case ARRAY() then exp;

      case RANGE()
        algorithm
          range_iter := RangeIterator.fromExp(exp);
        then
          ARRAY(exp.ty, RangeIterator.toList(range_iter));

      case BINARY() then expandBinary(exp.exp1, exp.operator, exp.exp2);
      case UNARY() then expandUnary(exp.exp, exp.operator);
      case LBINARY() then expandLogicalBinary(exp.exp1, exp.operator, exp.exp2);
      case LUNARY() then expandLogicalUnary(exp.exp, exp.operator);

      case CAST() then expandCast(exp.exp, exp.ty);

      else if Type.isArray(typeOf(exp)) then expandGeneric(exp) else exp;
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

          if listEmpty(subs) then
            arrayExp := ARRAY(Type.ARRAY(Type.arrayElementType(crefExp.ty), {Dimension.fromInteger(0)}), {});
          else
            arrayExp := expandCref3(subs, crefExp.cref, Type.arrayElementType(crefExp.ty));
          end if;
        then
          arrayExp;

      else crefExp;
    end match;
  end expandCref;

  function expandCref2
    input ComponentRef cref;
    input output list<list<list<Subscript>>> subs = {};
  protected
    list<list<Subscript>> cr_subs = {};
    list<Dimension> dims;

    import NFComponentRef.Origin;
  algorithm
    subs := match cref
      case ComponentRef.CREF(origin = Origin.CREF)
        algorithm
          dims := Type.arrayDims(cref.ty);
          cr_subs := Subscript.expandList(cref.subscripts, dims);
        then
          if listEmpty(cr_subs) and not listEmpty(dims) then
            {} else expandCref2(cref.restCref, cr_subs :: subs);

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
      case {} then CREF(crefType, ComponentRef.setSubscriptsList(accum, cref));
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

  function expandBinary
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    output Expression exp;

    import NFOperator.Op;
  algorithm
    exp := match op.op
      case Op.ADD_SCALAR_ARRAY then expandBinaryScalarArray(exp1, op, exp2, Op.ADD);
      case Op.ADD_ARRAY_SCALAR then expandBinaryArrayScalar(exp1, op, exp2, Op.ADD);
      case Op.SUB_SCALAR_ARRAY then expandBinaryScalarArray(exp1, op, exp2, Op.SUB);
      case Op.SUB_ARRAY_SCALAR then expandBinaryArrayScalar(exp1, op, exp2, Op.SUB);
      case Op.MUL_SCALAR_ARRAY then expandBinaryScalarArray(exp1, op, exp2, Op.MUL);
      case Op.MUL_ARRAY_SCALAR then expandBinaryArrayScalar(exp1, op, exp2, Op.MUL);
      case Op.MUL_VECTOR_MATRIX then expandBinaryVectorMatrix(exp1, exp2);
      case Op.MUL_MATRIX_VECTOR then expandBinaryMatrixVector(exp1, exp2);
      case Op.SCALAR_PRODUCT then expandBinaryDotProduct(exp1, exp2);
      case Op.MATRIX_PRODUCT then expandBinaryMatrixProduct(exp1, exp2);
      case Op.DIV_SCALAR_ARRAY then expandBinaryScalarArray(exp1, op, exp2, Op.DIV);
      case Op.DIV_ARRAY_SCALAR then expandBinaryArrayScalar(exp1, op, exp2, Op.DIV);
      case Op.POW_SCALAR_ARRAY then expandBinaryScalarArray(exp1, op, exp2, Op.POW);
      case Op.POW_ARRAY_SCALAR then expandBinaryArrayScalar(exp1, op, exp2, Op.POW);
      case Op.POW_MATRIX then expandBinaryPowMatrix(exp1, op, exp2);
      else expandBinaryElementWise(exp1, op, exp2);
    end match;
  end expandBinary;

  function expandBinaryElementWise
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    output Expression exp;
  protected
    list<Expression> expl1, expl2, expl;
    Type ty;
    Operator eop;
  algorithm
    expl1 := arrayElements(expand(exp1));
    expl2 := arrayElements(expand(exp2));
    ty := Operator.typeOf(op);
    eop := Operator.setType(Type.unliftArray(ty), op);
    if Type.dimensionCount(ty) > 1 then
      expl := list(expandBinaryElementWise(e1, eop, e2) threaded for e1 in expl1, e2 in expl2);
    else
      expl := list(makeBinaryOp(e1, eop, e2) threaded for e1 in expl1, e2 in expl2);
    end if;

    exp := ARRAY(Operator.typeOf(op), expl);
  end expandBinaryElementWise;

  function expandBinaryScalarArray
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    input NFOperator.Op scalarOp;
    output Expression exp;
  protected
    list<Expression> expl;
    Operator eop;
  algorithm
    exp := expand(exp2);
    eop := Operator.OPERATOR(Type.arrayElementType(Operator.typeOf(op)), scalarOp);
    exp := mapArrayElements(exp, function makeBinaryOp(op = eop, exp1 = exp1));
  end expandBinaryScalarArray;

  function makeScalarArrayBinary_traverser
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    output Expression exp;
  algorithm
    exp := match exp2
      case ARRAY() then exp2;
      else makeBinaryOp(exp1, op, exp2);
    end match;
  end makeScalarArrayBinary_traverser;

  function expandBinaryArrayScalar
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    input NFOperator.Op scalarOp;
    output Expression exp;
  protected
    list<Expression> expl;
    Operator eop;
  algorithm
    exp := expand(exp1);
    eop := Operator.OPERATOR(Type.arrayElementType(Operator.typeOf(op)), scalarOp);
    exp := mapArrayElements(exp, function makeBinaryOp(op = eop, exp2 = exp2));
  end expandBinaryArrayScalar;

  function expandBinaryVectorMatrix
    "Expands a vector*matrix expression, c[m] = a[n] * b[n, m]."
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  protected
    list<Expression> expl;
    Expression e1;
    Type ty;
    Dimension m;
  algorithm
    ARRAY(Type.ARRAY(ty, {m, _}), expl) := transposeArray(expand(exp2));
    ty := Type.ARRAY(ty, {m});

    if listEmpty(expl) then
      exp := makeZero(ty);
    else
      e1 := expand(exp1);
      // c[i] = a * b[:, i] for i in 1:m
      expl := list(makeScalarProduct(e1, e2) for e2 in expl);
      exp := ARRAY(ty, expl);
    end if;
  end expandBinaryVectorMatrix;

  function expandBinaryMatrixVector
    "Expands a matrix*vector expression, c[n] = a[n, m] * b[m]."
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  protected
    list<Expression> expl;
    Expression e2;
    Type ty;
    Dimension n;
  algorithm
    ARRAY(Type.ARRAY(ty, {n, _}), expl) := expand(exp1);
    ty := Type.ARRAY(ty, {n});

    if listEmpty(expl) then
      exp := makeZero(ty);
    else
      e2 := expand(exp2);
      // c[i] = a[i, :] * b for i in 1:n
      expl := list(makeScalarProduct(e1, e2) for e1 in expl);
      exp := ARRAY(ty, expl);
    end if;
  end expandBinaryMatrixVector;

  function expandBinaryDotProduct
    "Expands a vector*vector expression, c = a[n] * b[n]."
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  algorithm
    exp := makeScalarProduct(expand(exp1), expand(exp2));
  end expandBinaryDotProduct;

  function makeScalarProduct
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  protected
    list<Expression> expl1, expl2;
    Type ty, tyUnlift;
    Operator mul_op, add_op;
  algorithm
    ARRAY(ty, expl1) := exp1;
    ARRAY( _, expl2) := exp2;
    tyUnlift := Type.unliftArray(ty);

    if listEmpty(expl1) then
      // Scalar product of two empty arrays. The result is defined in the spec
      // by sum, so we return 0 since that's the default value of sum.
      exp := makeZero(tyUnlift);
    end if;
    mul_op := Operator.makeMul(tyUnlift);
    add_op := Operator.makeAdd(tyUnlift);
    expl1 := list(makeBinaryOp(e1, mul_op, e2) threaded for e1 in expl1, e2 in expl2);
    exp := List.reduce(expl1, function makeBinaryOp(op = add_op));
  end makeScalarProduct;

  function expandBinaryMatrixProduct
    "Expands a matrix*matrix expression, c[n, p] = a[n, m] * b[m, p]."
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  algorithm
    exp := makeBinaryMatrixProduct(expand(exp1), expand(exp2));
  end expandBinaryMatrixProduct;

  function makeBinaryMatrixProduct
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  protected
    list<Expression> expl1, expl2;
    Type ty, row_ty, mat_ty;
    Dimension n, p;
  algorithm
    ARRAY(Type.ARRAY(ty, {n, _}), expl1) := exp1;
    // Transpose the second matrix. This makes it easier to do the multiplication,
    // since we can do row-row multiplications instead of row-column.
    ARRAY(Type.ARRAY(dimensions = {p, _}), expl2) := transposeArray(exp2);
    mat_ty := Type.ARRAY(ty, {n, p});

    if listEmpty(expl2) then
      // If any of the matrices' dimensions are zero, the result will be a matrix
      // of zeroes (the default value of sum). Only expl2 needs to be checked here,
      // the normal case can handle expl1 being empty.
      exp := makeZero(mat_ty);
    else
      // c[i, j] = a[i, :] * b[:, j] for i in 1:n, j in 1:p.
      row_ty := Type.ARRAY(ty, {p});
      expl1 := list(ARRAY(row_ty, makeBinaryMatrixProduct2(e, expl2)) for e in expl1);
      exp := ARRAY(mat_ty, expl1);
    end if;
  end makeBinaryMatrixProduct;

  function makeBinaryMatrixProduct2
    input Expression row;
    input list<Expression> matrix;
    output list<Expression> outRow;
  algorithm
    outRow := list(makeScalarProduct(row, e) for e in matrix);
  end makeBinaryMatrixProduct2;

  function expandBinaryPowMatrix
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    output Expression exp;
  algorithm
    exp := match exp2
      local
        Integer n;

      // a ^ 0 = identity(size(a, 1))
      case INTEGER(0)
        algorithm
          n := Dimension.size(listHead(Type.arrayDims(Operator.typeOf(op))));
        then
          makeIdentityMatrix(n, Type.REAL());

      // a ^ n where n is a literal value.
      case INTEGER(n) then expandBinaryPowMatrix2(expand(exp1), n);

      // a ^ n where n is unknown, subscript the whole expression.
      else expandGeneric(makeBinaryOp(exp1, op, exp2));
    end match;
  end expandBinaryPowMatrix;

  function expandBinaryPowMatrix2
    input Expression matrix;
    input Integer n;
    output Expression exp;
  algorithm
    exp := match n
      // A^1 = A
      case 1 then matrix;
      // A^2 = A * A
      case 2 then makeBinaryMatrixProduct(matrix, matrix);

      // A^n = A^m * A^m where n = 2*m
      case _ guard intMod(n, 2) == 0
        algorithm
          exp := expandBinaryPowMatrix2(matrix, intDiv(n, 2));
        then
          makeBinaryMatrixProduct(exp, exp);

      // A^n = A * A^(n-1)
      else
        algorithm
          exp := expandBinaryPowMatrix2(matrix, n - 1);
        then
          makeBinaryMatrixProduct(matrix, exp);

    end match;
  end expandBinaryPowMatrix2;

  function makeBinaryOp
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    output Expression exp;
  algorithm
    if isScalarConst(exp1) and isScalarConst(exp2) then
      exp := Ceval.evalBinaryOp(exp1, op, exp2);
    else
      exp := BINARY(exp1, op, exp2);
    end if;
  end makeBinaryOp;

  function expandUnary
    input Expression exp;
    input Operator op;
    output Expression outExp;
  algorithm
    outExp := expand(exp);
    outExp := mapArrayElements(outExp, function makeUnaryOp(op = op));
  end expandUnary;

  function makeUnaryOp
    input Expression exp1;
    input Operator op;
    output Expression exp = UNARY(op, exp1);
  end makeUnaryOp;

  function expandLogicalBinary
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    output Expression exp;
  protected
    list<Expression> expl1, expl2, expl;
    Type ty;
    Operator eop;
  algorithm
    expl1 := arrayElements(expand(exp1));
    expl2 := arrayElements(expand(exp2));
    ty := Operator.typeOf(op);

    if Type.dimensionCount(ty) > 1 then
      eop := Operator.setType(Type.unliftArray(ty), op);
      expl := list(expandLogicalBinary(e1, eop, e2) threaded for e1 in expl1, e2 in expl2);
    else
      expl := list(LBINARY(e1, op, e2) threaded for e1 in expl1, e2 in expl2);
    end if;

    exp := ARRAY(Operator.typeOf(op), expl);
  end expandLogicalBinary;

  function expandLogicalUnary
    input Expression exp;
    input Operator op;
    output Expression outExp;
  algorithm
    outExp := expand(exp);
    outExp := mapArrayElements(outExp, function makeLogicalUnaryOp(op = op));
  end expandLogicalUnary;

  function makeLogicalUnaryOp
    input Expression exp1;
    input Operator op;
    output Expression exp = LUNARY(op, exp1);
  end makeLogicalUnaryOp;

  function expandCast
    input Expression exp;
    input Type ty;
    output Expression outExp;
  protected
    Type ety = Type.arrayElementType(ty);
  algorithm
    outExp := expand(exp);
    outExp := mapArrayElements(outExp, function typeCast(castTy = ety));
  end expandCast;

  function expandGeneric
    input Expression exp;
    output Expression outExp;
  protected
    Type ty;
    list<Dimension> dims;
    list<list<Expression>> subs;
  algorithm
    ty := typeOf(exp);
    dims := Type.arrayDims(ty);
    subs := list(RangeIterator.toList(RangeIterator.fromDim(d)) for d in dims);
    outExp := expandGeneric2(subs, exp, ty);
  end expandGeneric;

  function expandGeneric2
    input list<list<Expression>> subs;
    input Expression exp;
    input Type ty;
    input list<Expression> accum = {};
    output Expression outExp;
  protected
    Type t;
    list<Expression> sub, expl;
    list<list<Expression>> rest_subs;
  algorithm
    outExp := match subs
      case sub :: rest_subs
        algorithm
          t := Type.unliftArray(ty);
          expl := list(expandGeneric2(rest_subs, exp, t, s :: accum) for s in sub);
        then
          ARRAY(ty, expl);

      case {}
        algorithm
          outExp := exp;
          for s in listReverse(accum) loop
            outExp := applyIndexSubscript(s, outExp);
          end for;
        then
          outExp;

    end match;
  end expandGeneric2;

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
    exp := Expression.CREF(ComponentRef.getSubscriptedType(cref), cref);
  end fromCref;

  function toCref
    input Expression exp;
    output ComponentRef cref;
  algorithm
    Expression.CREF(cref = cref) := exp;
  end toCref;

  function isIterator
    input Expression exp;
    output Boolean isIterator;
  algorithm
    isIterator := match exp
      case Expression.CREF() then ComponentRef.isIterator(exp.cref);
      else false;
    end match;
  end isIterator;

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

  function isInteger
    input Expression exp;
    output Boolean isInteger;
  algorithm
    isInteger := match exp
      case INTEGER() then true;
      else false;
    end match;
  end isInteger;

  function isRecord
    input Expression exp;
    output Boolean isRecord;
  algorithm
    isRecord := match exp
      case RECORD() then true;
      else false;
    end match;
  end isRecord;

  function fillType
    input Type ty;
    input Expression fillExp;
    output Expression exp = fillExp;
  protected
    list<Dimension> dims = Type.arrayDims(ty);
    list<Expression> expl;
    Type arr_ty = Type.arrayElementType(ty);
  algorithm
    for dim in listReverse(dims) loop
      expl := {};
      for i in 1:Dimension.size(dim) loop
        expl := exp :: expl;
      end for;

      arr_ty := Type.liftArrayLeft(arr_ty, dim);
      exp := Expression.ARRAY(arr_ty, expl);
    end for;
  end fillType;

  function makeZero
    input Type ty;
    output Expression zeroExp;
  algorithm
    zeroExp := match ty
      case Type.REAL() then REAL(0.0);
      case Type.INTEGER() then INTEGER(0);
      case Type.ARRAY()
        then ARRAY(ty, List.fill(makeZero(Type.unliftArray(ty)),
                                 Dimension.size(listHead(ty.dimensions))));
    end match;
  end makeZero;

  function makeOne
    input Type ty;
    output Expression zeroExp;
  algorithm
    zeroExp := match ty
      case Type.REAL() then REAL(1.0);
      case Type.INTEGER() then INTEGER(1);
      case Type.ARRAY()
        then ARRAY(ty, List.fill(makeZero(Type.unliftArray(ty)),
                                 Dimension.size(listHead(ty.dimensions))));
    end match;
  end makeOne;

  function unbox
    input Expression boxedExp;
    output Expression exp;
  algorithm
    exp := match boxedExp
      case Expression.BOX() then boxedExp.exp;
      else boxedExp;
    end match;
  end unbox;

  function negate
    input output Expression exp;
  algorithm
    exp := match exp
      case INTEGER() then INTEGER(-exp.value);
      case REAL() then REAL(-exp.value);
      case CAST() then CAST(exp.ty, negate(exp.exp));
      else UNARY(Operator.OPERATOR(typeOf(exp), NFOperator.Op.UMINUS), exp);
    end match;
  end negate;

  function arrayElements
    input Expression array;
    output list<Expression> elements;
  algorithm
    Expression.ARRAY(elements = elements) := array;
  end arrayElements;

  function arrayScalarElements
    input Expression exp;
    output list<Expression> elements;
  algorithm
    elements := listReverseInPlace(arrayScalarElements_impl(exp, {}));
  end arrayScalarElements;

  function arrayScalarElements_impl
    input Expression exp;
    input output list<Expression> elements;
  algorithm
    elements := match exp
      case ARRAY()
        algorithm
          for e in exp.elements loop
            elements := arrayScalarElements_impl(e, elements);
          end for;
        then
          elements;

      else exp :: elements;
    end match;
  end arrayScalarElements_impl;

  function hasArrayCall
    "Returns true if the given expression contains a function call that returns
     an array, otherwise false."
    input Expression exp;
    output Boolean hasArrayCall;
  algorithm
    hasArrayCall := fold(exp, hasArrayCall2, false);
  end hasArrayCall;

  function hasArrayCall2
    input Expression exp;
    input output Boolean hasArrayCall;
  algorithm
    hasArrayCall := match exp
      case CALL() then Type.isArray(Call.typeOf(exp.call));
      else hasArrayCall;
    end match;
  end hasArrayCall2;

  function transposeArray
    input Expression arrayExp;
    output Expression outExp;
  protected
    Dimension dim1, dim2;
    list<Dimension> rest_dims;
    Type ty, row_ty;
    list<Expression> expl;
    list<list<Expression>> matrix;
  algorithm
    ARRAY(Type.ARRAY(ty, dim1 :: dim2 :: rest_dims), expl) := arrayExp;

    if not listEmpty(expl) then
      row_ty := Type.ARRAY(ty, dim1 :: rest_dims);
      matrix := list(arrayElements(e) for e in expl);
      matrix := List.transposeList(matrix);
      expl := list(ARRAY(row_ty, row) for row in matrix);
    end if;

    outExp := ARRAY(Type.ARRAY(ty, dim2 :: dim1 :: rest_dims), expl);
  end transposeArray;

  function makeIdentityMatrix
    input Integer n;
    input Type elementType;
    output Expression matrix;
  protected
    Expression zero, one;
    list<Expression> row, rows = {};
    Type row_ty;
  algorithm
    zero := makeZero(elementType);
    one := makeOne(elementType);
    row_ty := Type.ARRAY(elementType, {Dimension.fromInteger(n)});

    for i in 1:n loop
      row := {};

      for j in 2:i loop
        row := zero :: row;
      end for;

      row := one :: row;

      for j in i:n-1 loop
        row := zero :: row;
      end for;

      rows := Expression.ARRAY(row_ty, row) :: rows;
    end for;

    matrix := ARRAY(Type.liftArrayLeft(row_ty, Dimension.fromInteger(n)), rows);
  end makeIdentityMatrix;

  function promote
    input output Expression e;
    input output Type ty;
    input Integer n;
  protected
    list<Dimension> dims;
    Type ety;
    list<Type> tys = {};
    Boolean is_array;
  algorithm
    // Construct the dimensions that needs to be added.
    dims := list(Dimension.fromInteger(1) for i in Type.dimensionCount(ty):n-1);

    if not listEmpty(dims) then
      // Concatenate the existing dimensions and the added ones.
      dims := listAppend(Type.arrayDims(ty), dims);

      // Construct the result type.
      is_array := Type.isArray(ty);
      ety := Type.arrayElementType(ty);
      ty := Type.liftArrayLeftList(ety, dims);

      // Construct the expression types, to avoid having to create a new type
      // for each subexpression that will be created.
      while not listEmpty(dims) loop
        tys := Type.liftArrayLeftList(ety, dims) :: tys;
        dims := listRest(dims);
      end while;

      e := promote2(e, is_array, n, listReverse(tys));
    end if;
  end promote;

  function promote2
    input Expression exp;
    input Boolean isArray;
    input Integer dims;
    input list<Type> types;
    output Expression outExp;
  algorithm
    outExp := match (exp, types)
      local
        Type ty;
        list<Type> rest_ty;

      // No types left, we're done!
      case (_, {}) then exp;

      // An array, promote each element in the array.
      case (ARRAY(), ty :: rest_ty)
        then ARRAY(ty, list(promote2(e, false, dims, rest_ty) for e in exp.elements));

      // An expression with array type, but which is not an array expression.
      // Such an expression can't be promoted here, so we create a promote call instead.
      case (_, _) guard isArray
        then CALL(Call.makeBuiltinCall2(NFBuiltinFuncs.PROMOTE, {exp, INTEGER(dims)}, listHead(types)));

      // A scalar expression, promote it as many times as the number of types given.
      else
        algorithm
          outExp := exp;
          for ty in listReverse(types) loop
            outExp := ARRAY(ty, {outExp});
          end for;
        then
          outExp;

    end match;
  end promote2;

  function variability
    input Expression exp;
    output Variability var;
  algorithm
    var := match exp
      case INTEGER() then Variability.CONSTANT;
      case REAL() then Variability.CONSTANT;
      case STRING() then Variability.CONSTANT;
      case BOOLEAN() then Variability.CONSTANT;
      case ENUM_LITERAL() then Variability.CONSTANT;
      case CREF() then ComponentRef.variability(exp.cref);
      case TYPENAME() then Variability.CONSTANT;
      case ARRAY() then variabilityList(exp.elements);
      case MATRIX() then List.fold(exp.elements, variabilityList, Variability.CONSTANT);

      case RANGE()
        algorithm
          var := variability(exp.start);
          var := Prefixes.variabilityMax(var, variability(exp.stop));

          if isSome(exp.step) then
            var := Prefixes.variabilityMax(var, variability(Util.getOption(exp.step)));
          end if;
        then
          var;

      case TUPLE() then variabilityList(exp.elements);
      case RECORD() then variabilityList(exp.elements);
      case CALL() then Call.variability(exp.call);
      case SIZE()
        algorithm
          if isSome(exp.dimIndex) then
            var := Prefixes.variabilityMax(Variability.PARAMETER,
                                           variability(Util.getOption(exp.dimIndex)));
          else
            var := Variability.PARAMETER;
          end if;
        then
          var;

      case END() then Variability.PARAMETER;
      case BINARY() then Prefixes.variabilityMax(variability(exp.exp1), variability(exp.exp2));
      case UNARY() then variability(exp.exp);
      case LBINARY() then Prefixes.variabilityMax(variability(exp.exp1), variability(exp.exp2));
      case LUNARY() then variability(exp.exp);
      case RELATION()
        then Prefixes.variabilityMin(
          Prefixes.variabilityMax(variability(exp.exp1), variability(exp.exp2)),
          Variability.DISCRETE);

      case IF()
        then Prefixes.variabilityMax(variability(exp.condition),
          Prefixes.variabilityMax(variability(exp.trueBranch), variability(exp.falseBranch)));

      case CAST() then variability(exp.exp);
      case UNBOX() then variability(exp.exp);
      case SUBSCRIPTED_EXP()
        then Prefixes.variabilityMax(variability(exp.exp), variabilityList(exp.subscripts));
      case TUPLE_ELEMENT() then variability(exp.tupleExp);
      case BOX() then variability(exp.exp);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown expression.", sourceInfo());
        then
          fail();
    end match;
  end variability;

  function variabilityList
    input list<Expression> expl;
    input output Variability var = Variability.CONSTANT;
  algorithm
    for e in expl loop
      var := Prefixes.variabilityMax(var, variability(e));
    end for;
  end variabilityList;

  function makeMutable
    input Expression exp;
    output Expression outExp;
  algorithm
    outExp := MUTABLE(Mutable.create(exp));
  end makeMutable;

  function makeImmutable
    input Expression exp;
    output Expression outExp;
  algorithm
    outExp := match exp
      case MUTABLE() then Mutable.access(exp.exp);
      else exp;
    end match;
  end makeImmutable;

annotation(__OpenModelica_Interface="frontend");
end NFExpression;
