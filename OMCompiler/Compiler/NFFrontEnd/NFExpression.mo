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
  import AbsynUtil;
  import List;
  import System;
  import Flags;

  import Builtin = NFBuiltin;
  import BuiltinCall = NFBuiltinCall;
  import Expression = NFExpression;
  import Function = NFFunction;
  import NFPrefixes.{Variability, Purity};
  import Prefixes = NFPrefixes;
  import Ceval = NFCeval;
  import ComplexType = NFComplexType;
  import ExpandExp = NFExpandExp;
  import TypeCheck = NFTypeCheck;
  import ValuesUtil;
  import MetaModelica.Dangerous.listReverseInPlace;
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
  import Call = NFCall;
  import Binding = NFBinding;
  import NFClassTree.ClassTree;
  import Class = NFClass;
  import NFComponentRef.Origin;
  import Values;
  import Record = NFRecord;
  import ClockKind = NFClockKind;
  import ExpressionIterator = NFExpressionIterator;
  import InstContext = NFInstContext;
  import UnorderedMap;

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

  record CLKCONST "Clock constructors"
    ClockKind clk "Clock kinds";
  end CLKCONST;

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
    Boolean literal "True if the array is known to only contain literal expressions.";
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
    Type ty;
    Expression condition;
    Expression trueBranch;
    Expression falseBranch;
  end IF;

  record CAST
    Type ty;
    Expression exp;
  end CAST;

  record BOX "MetaModelica boxed value"
    Expression exp;
  end BOX;

  record UNBOX "MetaModelica value unboxing (similar to a cast)"
    Expression exp;
    Type ty;
  end UNBOX;

  record SUBSCRIPTED_EXP
    Expression exp;
    list<Subscript> subscripts;
    Type ty;
    Boolean split;
  end SUBSCRIPTED_EXP;

  record TUPLE_ELEMENT
    Expression tupleExp;
    Integer index;
    Type ty;
  end TUPLE_ELEMENT;

  record RECORD_ELEMENT
    Expression recordExp;
    Integer index;
    String fieldName;
    Type ty;
  end RECORD_ELEMENT;

  record MUTABLE
    Mutable<Expression> exp;
  end MUTABLE;

  record EMPTY
    Type ty;
  end EMPTY;

  record PARTIAL_FUNCTION_APPLICATION
    ComponentRef fn;
    list<Expression> args;
    list<String> argNames;
    Type ty;
  end PARTIAL_FUNCTION_APPLICATION;

  function isArray
    input Expression exp;
    output Boolean isArray;
  algorithm
    isArray := match exp
      case ARRAY() then true;
      else false;
    end match;
  end isArray;

  function isEmptyArray
    input Expression exp;
    output Boolean emptyArray;
  algorithm
    emptyArray := match exp
      case ARRAY(elements = {}) then true;
      else false;
    end match;
  end isEmptyArray;

  function isCref
    input Expression exp;
    output Boolean isCref;
  algorithm
    isCref := match exp
      case CREF() then true;
      else false;
    end match;
  end isCref;

  function isWildCref
    input Expression exp;
    output Boolean wild;
  algorithm
    wild := match exp
      case CREF(cref = ComponentRef.WILD()) then true;
      else false;
    end match;
  end isWildCref;

  function isCall
    input Expression exp;
    output Boolean isCall;
  algorithm
    isCall := match exp
      case CALL() then true;
      else false;
    end match;
  end isCall;

  function isImpureCall
    input Expression exp;
    output Boolean isImpure;
  algorithm
    isImpure := match exp
      case CALL() then Call.isImpure(exp.call);
      else false;
    end match;
  end isImpureCall;

  function isCallNamed
    input Expression exp;
    input String name;
    output Boolean res;
  algorithm
    res := match exp
      case CALL() then Call.isNamed(exp.call, name);
      else false;
    end match;
  end isCallNamed;

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
        list<Subscript> subs;
        ClockKind clk1, clk2;
        Mutable<Expression> me;
        list<list<Expression>> mat;

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

      case ENUM_LITERAL()
        algorithm
          ENUM_LITERAL(ty = ty, index = i) := exp2;
          comp := AbsynUtil.pathCompare(Type.enumName(exp1.ty), Type.enumName(ty));

          if comp == 0 then
            comp := Util.intCompare(exp1.index, i);
          end if;
        then
          comp;

      case CLKCONST(clk1)
        algorithm
          CLKCONST(clk2) := exp2;
        then
          ClockKind.compare(clk1, clk2);

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
          if comp == 0 then List.compare(exp1.elements, expl, compare) else comp;

      case MATRIX()
        algorithm
          MATRIX(elements = mat) := exp2;
        then
          List.compare(exp1.elements, mat, function List.compare(compareFn = compare));

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
          List.compare(exp1.elements, expl, compare);

      case RECORD()
        algorithm
          RECORD(path = p, elements = expl) := exp2;
          comp := AbsynUtil.pathCompare(exp1.path, p);
        then
          if comp == 0 then List.compare(exp1.elements, expl, compare) else comp;

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

      case CAST()
        algorithm
          e1 := match exp2
                  case CAST(exp = e1) then e1;
                  case e1 then e1;
                end match;
        then
          compare(exp1.exp, e1);

      case BOX()
        algorithm
          BOX(exp = e2) := exp2;
        then
          compare(exp1.exp, e2);

      case UNBOX()
        algorithm
          UNBOX(exp = e1) := exp2;
        then
          compare(exp1.exp, e1);

      case SUBSCRIPTED_EXP()
        algorithm
          SUBSCRIPTED_EXP(exp = e1, subscripts = subs) := exp2;
          comp := compare(exp1.exp, e1);

          if comp == 0 then
            comp := Subscript.compareList(exp1.subscripts, subs);
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

      case RECORD_ELEMENT()
        algorithm
          RECORD_ELEMENT(recordExp = e1, index = i) := exp2;
          comp := Util.intCompare(exp1.index, i);

          if comp == 0 then
            comp := compare(exp1.recordExp, e1);
          end if;
        then
          comp;

      case MUTABLE()
        algorithm
          MUTABLE(exp = me) := exp2;
        then
          compare(Mutable.access(exp1.exp), Mutable.access(me));

      case EMPTY()
        algorithm
          EMPTY(ty = ty) := exp2;
        then
          valueCompare(exp1.ty, ty);

      case PARTIAL_FUNCTION_APPLICATION()
        algorithm
          PARTIAL_FUNCTION_APPLICATION(fn = cr, args = expl) := exp2;
          comp := ComponentRef.compare(exp1.fn, cr);

          if comp == 0 then
            comp := List.compare(exp1.args, expl, compare);
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
    output Integer comp = List.compare(expl1, expl2, compare);
  end compareList;

  function typeOf
    input Expression exp;
    output Type ty;
  algorithm
    ty := match exp
      case INTEGER()         then Type.INTEGER();
      case REAL()            then Type.REAL();
      case STRING()          then Type.STRING();
      case BOOLEAN()         then Type.BOOLEAN();
      case ENUM_LITERAL()    then exp.ty;
      case CLKCONST()        then Type.CLOCK();
      case CREF()            then exp.ty;
      case TYPENAME()        then exp.ty;
      case ARRAY()           then exp.ty;
      case RANGE()           then exp.ty;
      case TUPLE()           then exp.ty;
      case RECORD()          then exp.ty;
      case CALL()            then Call.typeOf(exp.call);
      case SIZE()            then if isSome(exp.dimIndex) then
                                    Type.INTEGER() else Type.sizeType(typeOf(exp.exp));
      case END()             then Type.INTEGER();
      case BINARY()          then Operator.typeOf(exp.operator);
      case UNARY()           then Operator.typeOf(exp.operator);
      case LBINARY()         then Operator.typeOf(exp.operator);
      case LUNARY()          then Operator.typeOf(exp.operator);
      case RELATION()        then Type.copyDims(Operator.typeOf(exp.operator), Type.BOOLEAN());
      case IF()              then exp.ty;
      case CAST()            then exp.ty;
      case BOX()             then Type.METABOXED(typeOf(exp.exp));
      case UNBOX()           then exp.ty;
      case SUBSCRIPTED_EXP() then exp.ty;
      case TUPLE_ELEMENT()   then exp.ty;
      case RECORD_ELEMENT()  then exp.ty;
      case MUTABLE()         then typeOf(Mutable.access(exp.exp));
      case EMPTY()           then exp.ty;
      case PARTIAL_FUNCTION_APPLICATION() then exp.ty;
      else Type.UNKNOWN();
    end match;
  end typeOf;

  function setType
    input Type ty;
    input output Expression exp;
  algorithm
    exp := match exp
      case ENUM_LITERAL()    algorithm exp.ty := ty; then exp;
      case CREF()            algorithm exp.ty := ty; then exp;
      case TYPENAME()        algorithm exp.ty := ty; then exp;
      case ARRAY()           algorithm exp.ty := ty; then exp;
      case RANGE()           algorithm exp.ty := ty; then exp;
      case TUPLE()           algorithm exp.ty := ty; then exp;
      case RECORD()          algorithm exp.ty := ty; then exp;
      case CALL()            algorithm exp.call := Call.setType(exp.call, ty); then exp;
      case BINARY()          algorithm exp.operator := Operator.setType(ty, exp.operator); then exp;
      case UNARY()           algorithm exp.operator := Operator.setType(ty, exp.operator); then exp;
      case LBINARY()         algorithm exp.operator := Operator.setType(ty, exp.operator); then exp;
      case LUNARY()          algorithm exp.operator := Operator.setType(ty, exp.operator); then exp;
      case RELATION()        algorithm exp.operator := Operator.setType(ty, exp.operator); then exp;
      case IF()              algorithm exp.ty := ty; then exp;
      case CAST()            algorithm exp.ty := ty; then exp;
      case UNBOX()           algorithm exp.ty := ty; then exp;
      case SUBSCRIPTED_EXP() algorithm exp.ty := ty; then exp;
      case TUPLE_ELEMENT()   algorithm exp.ty := ty; then exp;
      case RECORD_ELEMENT()  algorithm exp.ty := ty; then exp;
      case PARTIAL_FUNCTION_APPLICATION() algorithm exp.ty := ty; then exp;
      else exp;
    end match;
  end setType;

  function typeCastOpt
    input Option<Expression> exp;
    input Type ty;
    output Option<Expression> outExp = Util.applyOption(exp, function typeCast(ty = ty));
  end typeCastOpt;

  function typeCast
    "Converts an expression to the given type. Dimensions of array types can be
     omitted, and are ignored by this function, since arrays can't be cast to a
     different size. Only the element type of the type is used, so for example:
       typeCast({1, 2, 3}, Type.REAL()) => {1.0, 2.0, 3.0}

     The function does not check that the cast is valid, and expressions that
     can't be converted outright will be wrapped as a CAST expression."
    input output Expression exp;
    input Type ty;
  protected
    Type t, t2, ety;
    list<Expression> el;
    Expression e1, e2;
    Integer dim_diff;
  algorithm
    ety := Type.arrayElementType(ty);

    exp := match exp
      // Integer can be cast to Real.
      case INTEGER()
        then if Type.isReal(ety) then REAL(intReal(exp.value)) else typeCastGeneric(exp, ety);

      // Boolean can be cast to Real (only if -d=nfAPI is on)
      // as there are annotations having expressions such as Boolean x > 0.5
      case BOOLEAN()
        then if Type.isReal(ety) and Flags.isSet(Flags.NF_API) then
          REAL(if exp.value then 1.0 else 0.0) else typeCastGeneric(exp, ety);

      // Real doesn't need to be cast to Real, since we convert e.g. array with
      // a mix of Integers and Reals to only Reals.
      case REAL()
        then if Type.isReal(ety) then exp else typeCastGeneric(exp, ety);

      // For arrays we typecast each element and update the type of the array.
      case ARRAY(ty = t, elements = el)
        algorithm
          el := list(typeCast(e, ety) for e in el);
          t := Type.setArrayElementType(t, ety);
        then
          ARRAY(t, el, exp.literal);

      case RANGE(ty = t)
        algorithm
          t := Type.setArrayElementType(t, ety);
        then
          RANGE(t, typeCast(exp.start, ety), typeCastOpt(exp.step, ety), typeCast(exp.stop, ety));

      // Unary operators (i.e. -) are handled by casting the operand.
      case UNARY()
        algorithm
          t := Type.setArrayElementType(Operator.typeOf(exp.operator), ety);
        then
          UNARY(Operator.setType(t, exp.operator), typeCast(exp.exp, ety));

      // If-expressions are handled by casting each of the branches.
      case IF()
        algorithm
          e1 := typeCast(exp.trueBranch, ety);
          e2 := typeCast(exp.falseBranch, ety);
          t := if Type.isConditionalArray(ty) then
            Type.setConditionalArrayTypes(ty, typeOf(e1), typeOf(e2)) else typeOf(e1);
        then
          IF(t, exp.condition, e1, e2);

      // Calls are handled by Call.typeCast, which has special rules for some functions.
      case CALL()
        then Call.typeCast(exp, ety);

      // Casting a cast expression overrides its current cast type.
      case CAST() then typeCast(exp.exp, ty);

      case SUBSCRIPTED_EXP()
        algorithm
          e1 := typeCast(exp.exp, ety);
          t := Type.setArrayElementType(exp.ty, ety);
        then
          SUBSCRIPTED_EXP(e1, exp.subscripts, t, exp.split);

      // Other expressions are handled by making a CAST expression.
      else typeCastGeneric(exp, ety);
    end match;
  end typeCast;

  function typeCastGeneric
    input output Expression exp;
    input Type ty;
  protected
    Type exp_ty = typeOf(exp);
  algorithm
    if not Type.isEqual(ty, Type.arrayElementType(exp_ty)) then
      exp := CAST(Type.setArrayElementType(exp_ty, ty), exp);
    end if;
  end typeCastGeneric;

  function realValue
    input Expression exp;
    output Real value;
  algorithm
    value := match exp
      case REAL() then exp.value;
      case INTEGER() then intReal(exp.value);
    end match;
  end realValue;

  function makeReal
    input Real value;
    output Expression exp = REAL(value);
  end makeReal;

  function integerValue
    input Expression exp;
    output Integer value;
  algorithm
    INTEGER(value=value) := exp;
  end integerValue;

  function makeInteger
    input Integer value;
    output Expression exp = INTEGER(value);
  end makeInteger;

  function stringValue
    input Expression exp;
    output String value;
  algorithm
    STRING(value=value) := exp;
  end stringValue;

  function makeArray
    input Type ty;
    input list<Expression> expl;
    input Boolean literal = false;
    output Expression outExp;
  algorithm
    outExp := ARRAY(ty, expl, literal);
    annotation(__OpenModelica_EarlyInline = true);
  end makeArray;

  function makeEmptyArray
    input Type ty;
    output Expression outExp;
  algorithm
    outExp := ARRAY(ty, {}, true);
    annotation(__OpenModelica_EarlyInline = true);
  end makeEmptyArray;

  function makeIntegerArray
    input list<Integer> values;
    output Expression exp;
  algorithm
    exp := makeArray(Type.ARRAY(Type.INTEGER(), {Dimension.fromInteger(listLength(values))}),
                     list(INTEGER(v) for v in values),
                     literal = true);
  end makeIntegerArray;

  function makeRealArray
    input list<Real> values;
    output Expression exp;
  algorithm
    exp := makeArray(Type.ARRAY(Type.REAL(), {Dimension.fromInteger(listLength(values))}),
                     list(REAL(v) for v in values),
                     literal = true);
  end makeRealArray;

  function makeRealMatrix
    input list<list<Real>> values;
    output Expression exp;
  protected
    Type ty;
    list<Expression> expl;
  algorithm
    if listEmpty(values) then
      ty := Type.ARRAY(Type.REAL(), {Dimension.fromInteger(0), Dimension.UNKNOWN()});
      exp := makeEmptyArray(ty);
    else
      ty := Type.ARRAY(Type.REAL(), {Dimension.fromInteger(listLength(listHead(values)))});
      expl := list(makeArray(ty, list(REAL(v) for v in row), literal = true) for row in values);
      ty := Type.liftArrayLeft(ty, Dimension.fromInteger(listLength(expl)));
      exp := makeArray(ty, expl, literal = true);
    end if;
  end makeRealMatrix;

  function makeExpArray
    input list<Expression> elements;
    input Type elementType;
    input Boolean isLiteral = false;
    output Expression exp;
  protected
    Type ty;
  algorithm
    ty := Type.liftArrayLeft(elementType, Dimension.fromInteger(listLength(elements)));
    exp := makeArray(ty, elements, isLiteral);
  end makeExpArray;

  function makeRecord
    input Absyn.Path recordName;
    input Type recordType;
    input list<Expression> fields;
    output Expression exp;
  algorithm
    exp := RECORD(recordName, recordType, fields);
  end makeRecord;

  function makeRange
    input Expression start;
    input Option<Expression> step;
    input Expression stop;
    output Expression rangeExp;
  algorithm
    rangeExp := RANGE(
      TypeCheck.getRangeType(start, step, stop, typeOf(start), AbsynUtil.dummyInfo),
      start, step, stop
    );
  end makeRange;

  function makeIntegerRange
    input Integer start;
    input Integer step;
    input Integer stop;
    output Expression rangeExp;
  protected
    Expression start_exp, stop_exp;
    Option<Expression> step_exp;
  algorithm
    start_exp := Expression.INTEGER(start);
    stop_exp := Expression.INTEGER(stop);

    if start == stop or
       step == 1 and start <= stop or
       step == -1 and start >= stop then
      step_exp := NONE();
    else
      step_exp := SOME(Expression.INTEGER(step));
    end if;

    rangeExp := makeRange(start_exp, step_exp, stop_exp);
  end makeIntegerRange;

  function makeTuple
    input list<Expression> expl;
    output Expression tupleExp;
  protected
    list<Type> tyl;
  algorithm
    if listLength(expl) == 1 then
      tupleExp := listHead(expl);
    else
      tyl := list(typeOf(e) for e in expl);
      tupleExp := TUPLE(Type.TUPLE(tyl, NONE()), expl);
    end if;
  end makeTuple;

  function applySubscripts
    "Subscripts an expression with the given list of subscripts."
    input list<Subscript> subscripts;
    input Expression exp;
    output Expression outExp;
  algorithm
    if listEmpty(subscripts) then
      outExp := exp;
    else
      outExp := applySubscript(listHead(subscripts), exp, listRest(subscripts));
    end if;
  end applySubscripts;

  function applySubscript
    "Subscripts an expression with the given subscript, and then applies the
     optional list of subscripts to each element of the subscripted expression."
    input Subscript subscript;
    input Expression exp;
    input list<Subscript> restSubscripts = {};
    output Expression outExp;
  algorithm
    outExp := match exp
      case CREF() then applySubscriptCref(subscript, exp.cref, restSubscripts);

      case TYPENAME() guard listEmpty(restSubscripts)
        then applySubscriptTypename(subscript, exp.ty);

      case ARRAY() then applySubscriptArray(subscript, exp, restSubscripts);

      case RANGE() guard listEmpty(restSubscripts)
        then applySubscriptRange(subscript, exp);

      case CALL()
        then applySubscriptCall(subscript, exp, restSubscripts);

      case IF() then applySubscriptIf(subscript, exp, restSubscripts);

      case UNBOX()
        algorithm
          outExp := applySubscript(subscript, exp.exp, restSubscripts);
        then
          unbox(outExp);

      case BOX() then box(applySubscript(subscript, exp.exp, restSubscripts));

      case CAST()
        algorithm
          outExp := applySubscript(subscript, exp.exp, restSubscripts);
        then
          CAST(Type.copyElementType(typeOf(outExp), exp.ty), outExp);

      else makeSubscriptedExp(subscript :: restSubscripts, exp);
    end match;
  end applySubscript;

  function applySubscriptCref
    input Subscript subscript;
    input ComponentRef cref;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  protected
    ComponentRef cr;
    Type ty;
  algorithm
    cr := ComponentRef.mergeSubscripts(subscript :: restSubscripts, cref);
    ty := ComponentRef.getSubscriptedType(cr);
    outExp := CREF(ty, cr);
  end applySubscriptCref;

  function applySubscriptTypename
    input Subscript subscript;
    input Type ty;
    output Expression outExp;
  protected
    Subscript sub;
    Integer index;
    list<Expression> expl;
  algorithm
    sub := Subscript.expandSlice(subscript);

    outExp := match sub
      case Subscript.INDEX() then applyIndexSubscriptTypename(ty, sub);

      case Subscript.SLICE()
        then SUBSCRIPTED_EXP(TYPENAME(ty), {subscript}, Type.ARRAY(ty, {Subscript.toDimension(sub)}), false);

      case Subscript.WHOLE()
        then TYPENAME(ty);

      case Subscript.EXPANDED_SLICE()
        algorithm
          expl := list(applyIndexSubscriptTypename(ty, i) for i in sub.indices);
        then
          makeArray(Type.liftArrayLeft(ty, Dimension.fromInteger(listLength(expl))), expl, literal = true);

    end match;
  end applySubscriptTypename;

  function applyIndexSubscriptTypename
    input Type ty;
    input Subscript index;
    output Expression subscriptedExp;
  protected
    Expression idx_exp;
    Integer idx;
  algorithm
    idx_exp := Subscript.toExp(index);

    if isScalarLiteral(idx_exp) then
      idx := toInteger(idx_exp);

      subscriptedExp := match ty
        case Type.BOOLEAN() guard idx <= 2
          then if idx == 1 then BOOLEAN(false) else BOOLEAN(true);

        case Type.ENUMERATION() then nthEnumLiteral(ty, idx);
      end match;
    else
      subscriptedExp := SUBSCRIPTED_EXP(TYPENAME(ty), {index}, ty, false);
    end if;
  end applyIndexSubscriptTypename;

  function applySubscriptArray
    input Subscript subscript;
    input Expression exp;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  protected
    Subscript sub, s;
    list<Subscript> rest_subs;
    list<Expression> expl;
    Type ty;
    Integer el_count;
    Boolean literal;
    Expression first_e;
  algorithm
    if isEmptyArray(exp) then
      outExp := makeSubscriptedExp(subscript :: restSubscripts, exp);
      return;
    end if;

    sub := Subscript.expandSlice(subscript);

    outExp := match sub
      case Subscript.INDEX() then applyIndexSubscriptArray(exp, sub, restSubscripts);
      case Subscript.SLICE() then makeSubscriptedExp(subscript :: restSubscripts, exp);
      case Subscript.WHOLE()
        algorithm
          if listEmpty(restSubscripts) then
            outExp := exp;
          else
            ARRAY(ty = ty, elements = expl, literal = literal) := exp;
            s :: rest_subs := restSubscripts;
            expl := list(applySubscript(s, e, rest_subs) for e in expl);
            (ty, literal) := typeSubscriptedArray(expl, restSubscripts, ty, literal);
            outExp := makeArray(ty, expl, literal);
          end if;
        then
          outExp;

      case Subscript.EXPANDED_SLICE()
        algorithm
          ARRAY(ty = ty, literal = literal) := exp;
          expl := list(applyIndexSubscriptArray(exp, i, restSubscripts) for i in sub.indices);
          (ty, literal) := typeSubscriptedArray(expl, restSubscripts, ty, literal);
        then
          makeArray(ty, expl, literal);

      case Subscript.SPLIT_INDEX() then makeSubscriptedExp(subscript :: restSubscripts, exp);

    end match;
  end applySubscriptArray;

  function typeSubscriptedArray
    input list<Expression> elements;
    input list<Subscript> subscripts;
    input output Type ty;
    input output Boolean literal;
  protected
    Integer count;
    Expression e;
  algorithm
    count := listLength(elements);

    if count > 0 then
      // If the array isn't empty, use the type of the first element.
      e := listHead(elements);
      ty := typeOf(e);
      // Non-literal subscripts might change an array from literal to non-literal.
      literal := literal and isLiteral(e);
    else
      // If the array is empty, use the slower method of subscripting the type.
      ty := Type.subscript(Type.unliftArray(ty), subscripts);
    end if;

    ty := Type.liftArrayLeft(ty, Dimension.fromInteger(count));
  end typeSubscriptedArray;

  function applyIndexSubscriptArray
    input Expression exp;
    input Subscript index;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  algorithm
    outExp := applyIndexExpArray(exp, Subscript.toExp(index), restSubscripts);
  end applyIndexSubscriptArray;

  function applyIndexExpArray
    input Expression exp;
    input Expression index;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  protected
    list<Expression> expl;
  algorithm
    if isScalarLiteral(index) then
      ARRAY(elements = expl) := exp;
      outExp := applySubscripts(restSubscripts, listGet(expl, toInteger(index)));
    else
      outExp := makeSubscriptedExp(Subscript.INDEX(index) :: restSubscripts, exp);
    end if;
  end applyIndexExpArray;

  function applySubscriptRange
    input Subscript subscript;
    input Expression exp;
    output Expression outExp;
  protected
    Subscript sub;
    Expression start_exp, stop_exp;
    Option<Expression> step_exp;
    Type ty;
    list<Expression> expl;
  algorithm
    sub := Subscript.expandSlice(subscript);

    outExp := match sub
      case Subscript.INDEX() then applyIndexSubscriptRange(exp, sub);

      case Subscript.SLICE()
        algorithm
          RANGE(ty = ty) := exp;
          ty := Type.ARRAY(Type.unliftArray(ty), {Subscript.toDimension(sub)});
        then
          SUBSCRIPTED_EXP(exp, {subscript}, ty, false);

      case Subscript.WHOLE() then exp;

      case Subscript.EXPANDED_SLICE()
        algorithm
          expl := list(applyIndexSubscriptRange(exp, i) for i in sub.indices);
          RANGE(ty = ty) := exp;
        then
          makeArray(Type.liftArrayLeft(ty, Dimension.fromInteger(listLength(expl))), expl);

      case Subscript.SPLIT_INDEX()
        algorithm
          RANGE(ty = ty) := exp;
          ty := Type.unliftArray(ty);
        then
          SUBSCRIPTED_EXP(exp, {sub}, ty, true);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown subscript '" + Subscript.toString(sub) + "'", sourceInfo());
        then
          fail();

    end match;
  end applySubscriptRange;

  function applyIndexSubscriptRange
    input Expression rangeExp;
    input Subscript index;
    output Expression outExp;
  protected
    Expression index_exp, start_exp, stop_exp;
    Option<Expression> step_exp;
    Type ty;
    list<Subscript> subs;
  algorithm
    Subscript.INDEX(index = index_exp) := index;

    if isScalarLiteral(index_exp) then
      RANGE(start = start_exp, step = step_exp, stop = stop_exp) := rangeExp;
      outExp := applyIndexSubscriptRange2(start_exp, step_exp, stop_exp, toInteger(index_exp));
    else
      RANGE(ty = ty) := rangeExp;
      subs := {index};
      ty := Type.subscript(ty, subs);
      outExp := SUBSCRIPTED_EXP(rangeExp, subs, ty, false);
    end if;
  end applyIndexSubscriptRange;

  function applyIndexSubscriptRange2
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
      case (INTEGER(), SOME(INTEGER(iidx)))
        then INTEGER(startExp.value + (index - 1) * iidx);

      case (INTEGER(), _)
        then INTEGER(startExp.value + index - 1);

      case (REAL(), SOME(REAL(ridx)))
        then REAL(startExp.value + (index - 1) * ridx);

      case (REAL(), _)
        then REAL(startExp.value + index - 1.0);

      case (BOOLEAN(), _)
        then if index == 1 then startExp else stopExp;

      case (ENUM_LITERAL(index = iidx), _)
        algorithm
          iidx := iidx + index - 1;
        then
          nthEnumLiteral(startExp.ty, iidx);

    end match;
  end applyIndexSubscriptRange2;

  function applySubscriptCall
    input Subscript subscript;
    input Expression exp;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  protected
    Call call;
  algorithm
    CALL(call = call) := exp;

    outExp := match call
      local
        Expression arg;
        Type ty;

      case Call.TYPED_CALL(arguments = {arg})
        guard Function.Function.isSubscriptableBuiltin(call.fn)
        algorithm
          arg := applySubscript(subscript, arg, restSubscripts);
          ty := Type.copyDims(typeOf(arg), call.ty);
        then
          CALL(Call.TYPED_CALL(call.fn, ty, call.var, call.purity, {arg}, call.attributes));

      case Call.TYPED_ARRAY_CONSTRUCTOR()
        then applySubscriptArrayConstructor(subscript, call, restSubscripts);

      else makeSubscriptedExp(subscript :: restSubscripts, exp);
    end match;
  end applySubscriptCall;

  function applySubscriptArrayConstructor
    input Subscript subscript;
    input Call call;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  algorithm
    if Subscript.isIndex(subscript) and listEmpty(restSubscripts) then
      outExp := applyIndexSubscriptArrayConstructor(call, subscript);
    else
      // TODO: Handle slicing and multiple subscripts better.
      outExp := makeSubscriptedExp(subscript :: restSubscripts, CALL(call));
    end if;
  end applySubscriptArrayConstructor;

  function applyIndexSubscriptArrayConstructor
    input Call call;
    input Subscript index;
    output Expression subscriptedExp;
  protected
    Type ty;
    Variability var;
    Purity pur;
    Expression exp, iter_exp;
    list<tuple<InstNode, Expression>> iters;
    InstNode iter;
  algorithm
    Call.TYPED_ARRAY_CONSTRUCTOR(ty, var, pur, exp, iters) := call;
    ((iter, iter_exp), iters) := List.splitLast(iters);
    iter_exp := applySubscript(index, iter_exp);
    subscriptedExp := replaceIterator(exp, iter, iter_exp);

    if not listEmpty(iters) then
      subscriptedExp := CALL(Call.TYPED_ARRAY_CONSTRUCTOR(Type.unliftArray(ty), var, pur, subscriptedExp, iters));
    end if;
  end applyIndexSubscriptArrayConstructor;

  function applySubscriptIf
    input Subscript subscript;
    input Expression exp;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  protected
    Expression cond, tb, fb;
    Type ty;
  algorithm
    IF(ty, cond, tb, fb) := exp;
    tb := applySubscript(subscript, tb, restSubscripts);
    fb := applySubscript(subscript, fb, restSubscripts);
    ty := if Type.isConditionalArray(ty) then
      Type.setConditionalArrayTypes(ty, typeOf(tb), typeOf(fb)) else typeOf(tb);
    outExp := IF(ty, cond, tb, fb);
  end applySubscriptIf;

  function makeSubscriptedExp
    input list<Subscript> subscripts;
    input Expression exp;
    output Expression outExp;
  protected
    Expression e;
    list<Subscript> subs, extra_subs;
    Type ty;
    Integer dim_count;
    Boolean split;
  algorithm
    // If the expression is already a SUBSCRIPTED_EXP we need to concatenate the
    // old subscripts with the new. Otherwise we just create a new SUBSCRIPTED_EXP.
    (e, subs, ty, split) := match exp
      case SUBSCRIPTED_EXP() then (exp.exp, exp.subscripts, typeOf(exp.exp), exp.split);
      else (exp, {}, typeOf(exp), false);
    end match;

    if not split then
      split := List.exist(subscripts, Subscript.isSplitIndex);
    end if;

    dim_count := Type.dimensionCount(ty);
    (subs, extra_subs) := Subscript.mergeList(subscripts, subs, dim_count);

    // Check that the expression has enough dimensions to be subscripted.
    if not listEmpty(extra_subs) then
      Error.assertion(false, getInstanceName() + ": too few dimensions in " +
        toString(exp) + " to apply subscripts " + Subscript.toStringList(subscripts), sourceInfo());
    end if;

    ty := Type.subscript(ty, subs);
    outExp := SUBSCRIPTED_EXP(e, subs, ty, split);
  end makeSubscriptedExp;

  function replaceIterator
    "Replaces the given iterator with the given value in an expression."
    input output Expression exp;
    input InstNode iterator;
    input Expression iteratorValue;
  algorithm
    exp := map(exp, function replaceIterator2(iterator = iterator, iteratorValue = iteratorValue));
  end replaceIterator;

  function replaceIterator2
    input Expression exp;
    input InstNode iterator;
    input Expression iteratorValue;
    output Expression outExp;
  algorithm
    outExp := match exp
      local
        InstNode node;
        ComponentRef cref;
        list<String> fields;

      // Cref is simple identifier, i
      case CREF(cref = ComponentRef.CREF(node = node))
        guard ComponentRef.isSimple(exp.cref)
        then if InstNode.refEqual(iterator, node) then iteratorValue else exp;

      // Cref is qualified identifier, i.x
      case CREF(cref = ComponentRef.CREF())
        algorithm
          // Only the first (last in stored order) part of a cref can be an iterator.
          node := ComponentRef.node(ComponentRef.last(exp.cref));

          if InstNode.refEqual(iterator, node) then
            // Start with the given value.
            outExp := iteratorValue;

            // Go down into the record fields using the rest of the cref.
            fields := list(InstNode.name(n) for n in listRest(ComponentRef.nodes(exp.cref)));

            for f in fields loop
              outExp := recordElement(f, outExp);
            end for;
          else
            outExp := exp;
          end if;
        then
          outExp;

      else exp;
    end match;
  end replaceIterator2;

  function containsIterator
    input Expression exp;
    input InstNode iterator;
    output Boolean res;
  protected
    function containsIterator2
      input Expression exp;
      input InstNode iterator;
      output Boolean res;
    algorithm
      res := match exp
        local
          InstNode node;

        case CREF(cref = ComponentRef.CREF(node = node))
          then InstNode.refEqual(node, iterator);
        else false;
      end match;
    end containsIterator2;
  algorithm
    res := contains(exp, function containsIterator2(iterator = iterator));
  end containsIterator;

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
      outExp := makeArray(ty,inExps);
      return;
    end if;

    partexps := List.partition(inExps, dimsize);

    newlst := {};
    for arrexp in partexps loop
      newlst := makeArray(ty,arrexp)::newlst;
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
      case BOOLEAN() then if exp.value then 2 else 1;
      case ENUM_LITERAL() then exp.index;
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
    ClockKind clk;
  algorithm
    str := match exp
      case INTEGER() then intString(exp.value);
      case REAL() then realString(exp.value);
      case STRING() then "\"" + System.escapedString(exp.value, false) + "\"";
      case BOOLEAN() then boolString(exp.value);

      case ENUM_LITERAL(ty = t as Type.ENUMERATION())
        then AbsynUtil.pathString(t.typePath) + "." + exp.name;

      case CLKCONST(clk) then ClockKind.toString(clk);
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
      case RECORD() then List.toString(exp.elements, toString, AbsynUtil.pathString(exp.path), "(", ", ", ")", true);
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

      case CAST() then if Flags.isSet(Flags.NF_API) then
                         toString(exp.exp)
                       else
                         "CAST(" + Type.toString(exp.ty) + ", " + toString(exp.exp) + ")";

      case BOX() then "BOX(" + toString(exp.exp) + ")";
      case UNBOX() then "UNBOX(" + toString(exp.exp) + ")";
      case SUBSCRIPTED_EXP() then toString(exp.exp) + Subscript.toStringList(exp.subscripts);
      case TUPLE_ELEMENT() then toString(exp.tupleExp) + "[" + intString(exp.index) + "]";
      case RECORD_ELEMENT() then toString(exp.recordExp) + "[field: " + exp.fieldName + "]";
      case MUTABLE() then toString(Mutable.access(exp.exp));
      case EMPTY() then "#EMPTY#";
      case PARTIAL_FUNCTION_APPLICATION()
        then "function " + ComponentRef.toString(exp.fn) + "(" + stringDelimitList(
          list(n + " = " + toString(a) threaded for a in exp.args, n in exp.argNames), ", ") + ")";

      else anyString(exp);
    end match;
  end toString;

  function toFlatString
    input Expression exp;
    output String str;
  protected
    Type t;
    ClockKind clk;
  algorithm
    str := match exp
      case INTEGER() then intString(exp.value);
      case REAL() then realString(exp.value);
      case STRING() then "\"" + Util.escapeModelicaStringToCString(exp.value) + "\"";
      case BOOLEAN() then boolString(exp.value);

      case ENUM_LITERAL(ty = t as Type.ENUMERATION())
        then "'" + AbsynUtil.pathString(t.typePath) + "'." + exp.name;

      case CLKCONST(clk) then ClockKind.toFlatString(clk);

      case CREF() then ComponentRef.toFlatString(exp.cref);
      case TYPENAME() then Type.typenameString(Type.arrayElementType(exp.ty));
      case ARRAY(elements={}) then "fill("+toFlatString(makeDefaultValue(Type.elementType(exp.ty)))+", " + Type.dimensionsToFlatString(exp.ty) + ")";
      case ARRAY() then "{" + stringDelimitList(list(toFlatString(e) for e in exp.elements), ", ") + "}";
      case MATRIX() then "[" + stringDelimitList(list(stringDelimitList(list(toFlatString(e) for e in el), ", ") for el in exp.elements), "; ") + "]";

      case RANGE() then operandFlatString(exp.start, exp, false) +
                        (
                        if isSome(exp.step)
                        then ":" + operandFlatString(Util.getOption(exp.step), exp, false)
                        else ""
                        ) + ":" + operandFlatString(exp.stop, exp, false);

      case TUPLE() then "(" + stringDelimitList(list(toFlatString(e) for e in exp.elements), ", ") + ")";
      case RECORD() then List.toString(exp.elements, toFlatString, "'" + AbsynUtil.pathString(exp.path), "'(", ", ", ")", true);
      case CALL() then Call.toFlatString(exp.call);
      case SIZE() then "size(" + toFlatString(exp.exp) +
                        (
                        if isSome(exp.dimIndex)
                        then ", " + toFlatString(Util.getOption(exp.dimIndex))
                        else ""
                        ) + ")";
      case END() then "end";

      case BINARY() then operandFlatString(exp.exp1, exp, true) +
                         Operator.symbol(exp.operator) +
                         operandFlatString(exp.exp2, exp, false);

      case UNARY() then Operator.symbol(exp.operator, "") +
                        operandFlatString(exp.exp, exp, false);

      case LBINARY() then operandFlatString(exp.exp1, exp, true) +
                          Operator.symbol(exp.operator) +
                          operandFlatString(exp.exp2, exp, false);

      case LUNARY() then Operator.symbol(exp.operator, "") + " " +
                         operandFlatString(exp.exp, exp, false);

      case RELATION() then operandFlatString(exp.exp1, exp, true) +
                           Operator.symbol(exp.operator) +
                           operandFlatString(exp.exp2, exp, false);

      case IF() then "if " + toFlatString(exp.condition) + " then " + toFlatString(exp.trueBranch) + " else " + toFlatString(exp.falseBranch);

      case CAST() then toFlatString(exp.exp);
      case UNBOX() then "UNBOX(" + toFlatString(exp.exp) + ")";
      case BOX() then "BOX(" + toFlatString(exp.exp) + ")";

      case SUBSCRIPTED_EXP() then toFlatSubscriptedString(exp.exp, exp.subscripts);
      case TUPLE_ELEMENT() then toFlatString(exp.tupleExp) + "[" + intString(exp.index) + "]";
      case RECORD_ELEMENT() then toFlatString(exp.recordExp) + "[field: " + exp.fieldName + "]";
      case MUTABLE() then toFlatString(Mutable.access(exp.exp));
      case EMPTY() then "#EMPTY#";
      case PARTIAL_FUNCTION_APPLICATION()
        then "function " + ComponentRef.toFlatString(exp.fn) + "(" + stringDelimitList(
          list(n + " = " + toFlatString(a) threaded for a in exp.args, n in exp.argNames), ", ") + ")";

      else anyString(exp);
    end match;
  end toFlatString;

  function toFlatSubscriptedString
    input Expression exp;
    input list<Subscript> subscripts;
    output String str;
  protected
    Type exp_ty;
    list<Type> sub_tyl;
    list<Dimension> dims;
    list<String> strl;
    String name;
    list<Subscript> subs;
  algorithm
    if Flags.getConfigBool(Flags.MODELICA_OUTPUT) then
      subs := list(s for s guard not Subscript.isSplitIndex(s) in subscripts);

      if listEmpty(subs) then
        str := toFlatString(exp);
      else
        exp_ty := typeOf(exp);
        dims := List.firstN(Type.arrayDims(exp_ty), listLength(subs));
        sub_tyl := list(Dimension.subscriptType(d) for d in dims);
        name := Type.subscriptedTypeName(exp_ty, sub_tyl);

        strl := {")"};

        for s in subs loop
          strl := Subscript.toFlatString(s) :: strl;
          strl := "," :: strl;
        end for;

        strl := toFlatString(exp) :: strl;
        strl := "'(" :: strl;
        strl := name :: strl;
        strl := "'" :: strl;
        str := stringAppendList(strl);
      end if;
    else
      str := toFlatString(exp) + Subscript.toFlatStringList(subscripts);
    end if;
  end toFlatSubscriptedString;

  function operandString
    "Helper function to toString, prints an operator and adds parentheses as needed."
    input Expression operand;
    input Expression operator;
    input Boolean lhs;
    output String str;
  protected
    Integer operand_prio, operator_prio;
    Boolean parenthesize = false;
  algorithm
    str := toString(operand);
    operand_prio := priority(operand, lhs);

    if operand_prio == 4 then
      parenthesize := true;
    else
      operator_prio := priority(operator, lhs);

      if operand_prio > operator_prio then
        parenthesize := true;
      elseif operand_prio == operator_prio then
        parenthesize := if lhs then isNonAssociativeExp(operand) else not
                                    isAssociativeExp(operand);
      end if;
    end if;

    if parenthesize then
      str := "(" + str + ")";
    end if;
  end operandString;

  function operandFlatString
    "Helper function to toString, prints an operator and adds parentheses as needed."
    input Expression operand;
    input Expression operator;
    input Boolean lhs;
    output String str;
  protected
    Integer operand_prio, operator_prio;
    Boolean parenthesize = false;
  algorithm
    str := toFlatString(operand);
    operand_prio := priority(operand, lhs);

    if operand_prio == 4 then
      parenthesize := true;
    else
      operator_prio := priority(operator, lhs);

      if operand_prio > operator_prio then
        parenthesize := true;
      elseif operand_prio == operator_prio then
        parenthesize := if lhs then isNonAssociativeExp(operand) else not
                                    isAssociativeExp(operand);
      end if;
    end if;

    if parenthesize then
      str := "(" + str + ")";
    end if;
  end operandFlatString;

  function priority
    input Expression exp;
    input Boolean lhs;
    output Integer priority;
  algorithm
    priority := match exp
      case INTEGER() then if exp.value < 0 then 4 else 0;
      case REAL() then if exp.value < 0.0 then 4 else 0;
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

  function isNonAssociativeExp
    input Expression exp;
    output Boolean isAssociative;
  algorithm
    isAssociative := match exp
      case BINARY() then Operator.isNonAssociative(exp.operator);
      case LBINARY() then true;
      else false;
    end match;
  end isNonAssociativeExp;

  function getName
    "Returns the 'name' of an Expression, for example the function name of a
     call or the record class name of a record expression."
    input Expression exp;
    output String name;
  algorithm
    name := match exp
      case RECORD() then AbsynUtil.pathString(exp.path);
      case CALL() then AbsynUtil.pathString(Call.functionName(exp.call));
      case CAST() then getName(exp.exp);
      case BOX() then getName(exp.exp);
      case UNBOX() then getName(exp.exp);
      case MUTABLE() then getName(Mutable.access(exp.exp));
      case PARTIAL_FUNCTION_APPLICATION() then ComponentRef.toString(exp.fn);
      else toString(exp);
    end match;
  end getName;

  function enumLiteralPath
    input Expression exp;
    output Absyn.Path path;
  protected
    String name;
    Absyn.Path ty_path;
  algorithm
    ENUM_LITERAL(name = name, ty = Type.ENUMERATION(typePath = ty_path)) := exp;
    path := AbsynUtil.suffixPath(ty_path, name);
  end enumLiteralPath;

  function toAbsynOpt
    input Option<Expression> exp;
    output Option<Absyn.Exp> aexp;
  algorithm
    aexp := match exp
      local
        Expression e;

      case SOME(e) then SOME(toAbsyn(e));
      else NONE();
    end match;
  end toAbsynOpt;

  function toAbsyn
    input Expression exp;
    output Absyn.Exp aexp;
  algorithm
    aexp := match exp
      local
        Type ty;

      case INTEGER() then Absyn.Exp.INTEGER(exp.value);
      case REAL() then Absyn.Exp.REAL(String(exp.value));
      case STRING() then Absyn.Exp.STRING(exp.value);
      case BOOLEAN() then Absyn.Exp.BOOL(exp.value);
      case ENUM_LITERAL(ty = ty as Type.ENUMERATION())
        then Absyn.Exp.CREF(AbsynUtil.pathToCref(enumLiteralPath(exp)));
      case CLKCONST() then ClockKind.toAbsyn(exp.clk);
      case CREF() then Absyn.Exp.CREF(ComponentRef.toAbsyn(exp.cref));
      case TYPENAME() then Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT(Type.toString(exp.ty), {}));
      case ARRAY() then Absyn.Exp.ARRAY(list(toAbsyn(e) for e in exp.elements));
      case MATRIX() then Absyn.Exp.MATRIX(list(list(toAbsyn(e) for e in l) for l in exp.elements));
      case RANGE() then Absyn.Exp.RANGE(toAbsyn(exp.start), toAbsynOpt(exp.step), toAbsyn(exp.stop));
      case TUPLE() then Absyn.Exp.TUPLE(list(toAbsyn(e) for e in exp.elements));
      case RECORD() then AbsynUtil.makeCall(AbsynUtil.pathToCref(exp.path), list(toAbsyn(e) for e in exp.elements));
      case CALL() then Call.toAbsyn(exp.call);
      case SIZE() then AbsynUtil.makeCall(Absyn.ComponentRef.CREF_IDENT("size", {}),
        if isSome(exp.dimIndex) then {toAbsyn(Util.getOption(exp.dimIndex))} else {});
      case END() then Absyn.Exp.END();
      case BINARY() then Absyn.Exp.BINARY(toAbsyn(exp.exp1), Operator.toAbsyn(exp.operator), toAbsyn(exp.exp2));
      case UNARY() then Absyn.Exp.UNARY(Operator.toAbsyn(exp.operator), toAbsyn(exp.exp));
      case LBINARY() then Absyn.Exp.LBINARY(toAbsyn(exp.exp1), Operator.toAbsyn(exp.operator), toAbsyn(exp.exp2));
      case LUNARY() then Absyn.Exp.LUNARY(Operator.toAbsyn(exp.operator), toAbsyn(exp.exp));
      case RELATION() then Absyn.Exp.RELATION(toAbsyn(exp.exp1), Operator.toAbsyn(exp.operator), toAbsyn(exp.exp2));
      case IF() then Absyn.Exp.IFEXP(toAbsyn(exp.condition), toAbsyn(exp.trueBranch), toAbsyn(exp.falseBranch), {});
      case CAST() then toAbsyn(exp.exp);
      case BOX() then toAbsyn(exp.exp);
      case UNBOX() then toAbsyn(exp.exp);
      case MUTABLE() then toAbsyn(Mutable.access(exp.exp));
      case PARTIAL_FUNCTION_APPLICATION()
        then Absyn.Exp.PARTEVALFUNCTION(ComponentRef.toAbsyn(exp.fn),
          Absyn.FunctionArgs.FUNCTIONARGS(list(toAbsyn(e) for e in exp.args), {}));

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown expression '" + toString(exp) + "'", sourceInfo());
        then
          fail();

    end match;
  end toAbsyn;

  function toDAEOpt
    input Option<Expression> exp;
    output Option<DAE.Exp> dexp;
  algorithm
    dexp := match exp
      local
        Expression e;

      case SOME(e) then SOME(toDAE(e));
      else NONE();
    end match;
  end toDAEOpt;

  function toDAE
    input Expression exp;
    output DAE.Exp dexp;
  protected
    Boolean changed = true;
  algorithm
    dexp := match exp
      local
        DAE.Operator daeOp;
        Boolean swap, negate;
        DAE.Exp dae1, dae2;
        Function.Function fn;

      case INTEGER() then DAE.ICONST(exp.value);
      case REAL() then DAE.RCONST(exp.value);
      case STRING() then DAE.SCONST(exp.value);
      case BOOLEAN() then DAE.BCONST(exp.value);
      case ENUM_LITERAL() then DAE.ENUM_LITERAL(enumLiteralPath(exp), exp.index);

      case CLKCONST()
        then DAE.CLKCONST(ClockKind.toDAE(exp.clk));

      case CREF()
        then DAE.CREF(ComponentRef.toDAE(exp.cref), Type.toDAE(exp.ty));

      case TYPENAME()
        then toDAE(ExpandExp.expandTypename(exp.ty));

      case ARRAY()
        then DAE.ARRAY(Type.toDAE(exp.ty), Type.isVector(exp.ty),
          list(toDAE(e) for e in exp.elements));

      case RECORD() then toDAERecord(exp.ty, exp.path, exp.elements);

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
        algorithm
          (daeOp, swap, negate) := Operator.toDAE(exp.operator);
          dae1 := toDAE(exp.exp1);
          dae2 := toDAE(if negate then negate(exp.exp2) else exp.exp2);
        then
          DAE.BINARY(if swap then dae2 else dae1, daeOp, if swap then dae1 else dae2);

      case UNARY() then DAE.UNARY(Operator.toDAE(exp.operator), toDAE(exp.exp));
      case LBINARY() then DAE.LBINARY(toDAE(exp.exp1), Operator.toDAE(exp.operator), toDAE(exp.exp2));
      case LUNARY() then DAE.LUNARY(Operator.toDAE(exp.operator), toDAE(exp.exp));
      case RELATION() then DAE.RELATION(toDAE(exp.exp1), Operator.toDAE(exp.operator), toDAE(exp.exp2), -1, NONE());
      case IF() then DAE.IFEXP(toDAE(exp.condition), toDAE(exp.trueBranch), toDAE(exp.falseBranch));
      case CAST() then DAE.CAST(Type.toDAE(exp.ty), toDAE(exp.exp));
      case BOX() then DAE.BOX(toDAE(exp.exp));
      case UNBOX() then DAE.UNBOX(toDAE(exp.exp), Type.toDAE(exp.ty));

      case SUBSCRIPTED_EXP()
        then DAE.ASUB(toDAE(exp.exp), list(Subscript.toDAEExp(s) for s in exp.subscripts));

      case TUPLE_ELEMENT()
        then DAE.TSUB(toDAE(exp.tupleExp), exp.index, Type.toDAE(exp.ty));

      case RECORD_ELEMENT()
        then DAE.RSUB(toDAE(exp.recordExp), exp.index, exp.fieldName, Type.toDAE(exp.ty));

      case PARTIAL_FUNCTION_APPLICATION()
        algorithm
          fn :: _ := Function.Function.typeRefCache(exp.fn);
        then
          DAE.PARTEVALFUNCTION(Function.Function.nameConsiderBuiltin(fn),
                               list(toDAE(arg) for arg in exp.args),
                               Type.toDAE(exp.ty),
                               Type.toDAE(Type.FUNCTION(fn, NFType.FunctionType.FUNCTIONAL_VARIABLE)));

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown expression '" + toString(exp) + "'", sourceInfo());
        then
          fail();

    end match;
  end toDAE;

  function toDAERecord
    input Type ty;
    input Absyn.Path path;
    input list<Expression> args;
    output DAE.Exp exp;
  protected
    list<String> field_names = {};
    Expression arg;
    list<Expression> rest_args = args;
    list<DAE.Exp> dargs = {};
  algorithm
    for field in Type.recordFields(Type.unbox(ty)) loop
      arg :: rest_args := rest_args;

      () := match field
        case Record.Field.INPUT()
          algorithm
            field_names := field.name :: field_names;
            dargs := toDAE(arg) :: dargs;
          then
            ();

        // TODO: Constants/parameters shouldn't be added to record expressions
        //       since that causes issues with the backend, but removing them
        //       currently causes even worse issues.
        case Record.Field.LOCAL()
          algorithm
            field_names := field.name :: field_names;
            dargs := toDAE(arg) :: dargs;
          then
            ();

        else ();
      end match;
    end for;

    field_names := listReverseInPlace(field_names);
    dargs := listReverseInPlace(dargs);

    exp := if Type.isBoxed(ty) then
        DAE.METARECORDCALL(path, dargs, field_names, -1, {})
      else
        DAE.RECORD(path, dargs, field_names, Type.toDAE(ty));
  end toDAERecord;

  function toDAEValueOpt
    input Option<Expression> exp;
    output Option<Values.Value> value = Util.applyOption(exp, toDAEValue);
  end toDAEValueOpt;

  function toDAEValue
    input Expression exp;
    output Values.Value value;
  algorithm
    value := match exp
      local
        Type ty;
        list<Values.Value> vals;
        list<Record.Field> fields;
        list<String> field_names;

      case INTEGER() then Values.INTEGER(exp.value);
      case REAL() then Values.REAL(exp.value);
      case STRING() then Values.STRING(exp.value);
      case BOOLEAN() then Values.BOOL(exp.value);
      case ENUM_LITERAL(ty = ty as Type.ENUMERATION())
        then Values.ENUM_LITERAL(AbsynUtil.suffixPath(ty.typePath, exp.name), exp.index);

      case ARRAY()
        algorithm
          vals := list(toDAEValue(e) for e in exp.elements);
        then
          ValuesUtil.makeArray(vals);

      case RECORD() then toDAEValueRecord(exp.ty, exp.path, exp.elements);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unhandled expression " + toString(exp), sourceInfo());
        then
          fail();
    end match;
  end toDAEValue;

  function toDAEValueRecord
    input Type ty;
    input Absyn.Path path;
    input list<Expression> args;
    output Values.Value value;
  protected
    list<String> field_names = {};
    Expression arg;
    list<Expression> rest_args = args;
    list<Values.Value> values = {};
  algorithm
    for field in Type.recordFields(ty) loop
      arg :: rest_args := rest_args;

      () := match field
        case Record.Field.INPUT()
          algorithm
            field_names := field.name :: field_names;
            values := toDAEValue(arg) :: values;
          then
            ();

        else ();
      end match;
    end for;

    field_names := listReverseInPlace(field_names);
    values := listReverseInPlace(values);
    value := Values.RECORD(path, values, field_names, -1);
  end toDAEValueRecord;

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

      case CLKCONST() then CLKCONST(ClockKind.mapExp(exp.clk, func));
      case CREF() then CREF(exp.ty, ComponentRef.mapExp(exp.cref, func));
      case ARRAY() then ARRAY(exp.ty, list(map(e, func) for e in exp.elements), exp.literal);
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

      case CALL() then CALL(Call.mapExp(exp.call, func));

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
             referenceEq(exp.falseBranch, e3) then exp else IF(exp.ty, e1, e2, e3);

      case CAST()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case BOX()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else box(e1);

      case UNBOX()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else unbox(e1);

      case SUBSCRIPTED_EXP()
        then SUBSCRIPTED_EXP(map(exp.exp, func),
          list(Subscript.mapExp(s, func) for s in exp.subscripts), exp.ty, exp.split);

      case TUPLE_ELEMENT()
        algorithm
          e1 := map(exp.tupleExp, func);
        then
          if referenceEq(exp.tupleExp, e1) then exp else TUPLE_ELEMENT(e1, exp.index, exp.ty);

      case RECORD_ELEMENT()
        algorithm
          e1 := map(exp.recordExp, func);
        then
          if referenceEq(exp.recordExp, e1) then exp else RECORD_ELEMENT(e1, exp.index, exp.fieldName, exp.ty);

      case MUTABLE()
        algorithm
          Mutable.update(exp.exp, map(Mutable.access(exp.exp), func));
        then
          exp;

      case PARTIAL_FUNCTION_APPLICATION()
        algorithm
          exp.args := list(map(e, func) for e in exp.args);
        then
          exp;

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
    outExp := match exp
      case SOME(e) then SOME(map(e, func));
      else exp;
    end match;
  end mapOpt;

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

      case CLKCONST() then CLKCONST(ClockKind.mapExpShallow(exp.clk, func));
      case CREF() then CREF(exp.ty, ComponentRef.mapExpShallow(exp.cref, func));
      case ARRAY() then ARRAY(exp.ty, list(func(e) for e in exp.elements), exp.literal);
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

      case CALL() then CALL(Call.mapExpShallow(exp.call, func));

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
             referenceEq(exp.falseBranch, e3) then exp else IF(exp.ty, e1, e2, e3);

      case CAST()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case BOX()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else box(e1);

      case UNBOX()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else unbox(e1);

      case SUBSCRIPTED_EXP()
        then SUBSCRIPTED_EXP(func(exp.exp),
          list(Subscript.mapShallowExp(e, func) for e in exp.subscripts), exp.ty, exp.split);

      case TUPLE_ELEMENT()
        algorithm
          e1 := func(exp.tupleExp);
        then
          if referenceEq(exp.tupleExp, e1) then exp else TUPLE_ELEMENT(e1, exp.index, exp.ty);

      case RECORD_ELEMENT()
        algorithm
          e1 := func(exp.recordExp);
        then
          if referenceEq(exp.recordExp, e1) then exp else RECORD_ELEMENT(e1, exp.index, exp.fieldName, exp.ty);

      case MUTABLE()
        algorithm
          Mutable.update(exp.exp, func(Mutable.access(exp.exp)));
        then
          exp;

      case PARTIAL_FUNCTION_APPLICATION()
        algorithm
          exp.args := list(func(e) for e in exp.args);
        then
          exp;

      else exp;
    end match;
  end mapShallow;

  function mapShallowOpt
    input Option<Expression> exp;
    input MapFunc func;
    output Option<Expression> outExp;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    Expression e;
  algorithm
    outExp := match exp
      case SOME(e) then SOME(func(e));
      else exp;
    end match;
  end mapShallowOpt;

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
          exp.literal := List.all(exp.elements, isLiteral);
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

  function foldOpt<ArgT>
    input Option<Expression> exp;
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

      case SOME(e) then func(e, arg);
      else arg;
    end match;
  end foldOpt;

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
        Expression e, e1, e2;

      case CLKCONST() then ClockKind.foldExp(exp.clk, func, arg);
      case CREF() then ComponentRef.foldExp(exp.cref, func, arg);
      case ARRAY() then foldList(exp.elements, func, arg);

      case MATRIX()
        algorithm
          result := arg;
          for row in exp.elements loop
            result := foldList(row, func, result);
          end for;
        then
          result;

      case RANGE()
        algorithm
          result := fold(exp.start, func, arg);
          result := foldOpt(exp.step, func, result);
        then
          fold(exp.stop, func, result);

      case TUPLE() then foldList(exp.elements, func, arg);
      case RECORD() then foldList(exp.elements, func, arg);
      case CALL() then Call.foldExp(exp.call, func, arg);

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
      case BOX() then fold(exp.exp, func, arg);
      case UNBOX() then fold(exp.exp, func, arg);

      case SUBSCRIPTED_EXP()
        algorithm
          result := fold(exp.exp, func, arg);
        then
          List.fold(exp.subscripts, function Subscript.foldExp(func = func), result);

      case TUPLE_ELEMENT() then fold(exp.tupleExp, func, arg);
      case RECORD_ELEMENT() then fold(exp.recordExp, func, arg);
      case MUTABLE() then fold(Mutable.access(exp.exp), func, arg);
      case PARTIAL_FUNCTION_APPLICATION() then foldList(exp.args, func, arg);
      else arg;
    end match;

    result := func(exp, result);
  end fold;

  function applyList
    input list<Expression> expl;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    for e in expl loop
      apply(e, func);
    end for;
  end applyList;

  function applyOpt
    input Option<Expression> exp;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  protected
    Expression e;
  algorithm
    if isSome(exp) then
      SOME(e) := exp;
      apply(e, func);
    end if;
  end applyOpt;

  function apply
    input Expression exp;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match exp
      local
        Expression e, e1, e2;

      case CLKCONST() algorithm ClockKind.applyExp(exp.clk, func); then ();
      case CREF() algorithm ComponentRef.applyExp(exp.cref, func); then ();
      case ARRAY() algorithm applyList(exp.elements, func); then ();

      case MATRIX()
        algorithm
          for row in exp.elements loop
            applyList(row, func);
          end for;
        then
          ();

      case RANGE()
        algorithm
          apply(exp.start, func);
          applyOpt(exp.step, func);
          apply(exp.stop, func);
        then
          ();

      case TUPLE() algorithm applyList(exp.elements, func); then ();
      case RECORD() algorithm applyList(exp.elements, func); then ();
      case CALL() algorithm Call.applyExp(exp.call, func); then ();

      case SIZE()
        algorithm
          apply(exp.exp, func);
          applyOpt(exp.dimIndex, func);
        then
          ();

      case BINARY()
        algorithm
          apply(exp.exp1, func);
          apply(exp.exp2, func);
        then
          ();

      case UNARY() algorithm apply(exp.exp, func); then ();

      case LBINARY()
        algorithm
          apply(exp.exp1, func);
          apply(exp.exp2, func);
        then
          ();

      case LUNARY() algorithm apply(exp.exp, func); then ();

      case RELATION()
        algorithm
          apply(exp.exp1, func);
          apply(exp.exp2, func);
        then
          ();

      case IF()
        algorithm
          apply(exp.condition, func);
          apply(exp.trueBranch, func);
          apply(exp.falseBranch, func);
        then
          ();

      case CAST() algorithm apply(exp.exp, func); then ();
      case BOX() algorithm apply(exp.exp, func); then ();
      case UNBOX() algorithm apply(exp.exp, func); then ();

      case SUBSCRIPTED_EXP()
        algorithm
          apply(exp.exp, func);

          for s in exp.subscripts loop
            Subscript.applyExp(s, func);
          end for;
        then
          ();

      case TUPLE_ELEMENT() algorithm apply(exp.tupleExp, func); then ();
      case RECORD_ELEMENT() algorithm apply(exp.recordExp, func); then ();
      case MUTABLE() algorithm apply(Mutable.access(exp.exp), func); then ();
      case PARTIAL_FUNCTION_APPLICATION() algorithm applyList(exp.args, func); then ();
      else ();
    end match;

    func(exp);
  end apply;

  function applyListShallow
    input list<Expression> expl;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    for e in expl loop
      func(e);
    end for;
  end applyListShallow;

  function applyShallow
    input Expression exp;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match exp
      local
        Expression e;

      case CLKCONST() algorithm ClockKind.applyExpShallow(exp.clk, func); then ();
      case CREF() algorithm ComponentRef.applyExpShallow(exp.cref, func); then ();
      case ARRAY() algorithm applyListShallow(exp.elements, func); then ();

      case MATRIX()
        algorithm
          for row in exp.elements loop
            applyList(row, func);
          end for;
        then
          ();

      case RANGE()
        algorithm
          func(exp.start);
          applyShallowOpt(exp.step, func);
          func(exp.stop);
        then
          ();

      case TUPLE() algorithm applyListShallow(exp.elements, func); then ();
      case RECORD() algorithm applyListShallow(exp.elements, func); then ();
      case CALL() algorithm Call.applyExpShallow(exp.call, func); then ();

      case SIZE()
        algorithm
          func(exp.exp);
          applyShallowOpt(exp.dimIndex, func);
        then
          ();

      case BINARY()
        algorithm
          func(exp.exp1);
          func(exp.exp2);
        then
          ();

      case UNARY() algorithm func(exp.exp); then ();

      case LBINARY()
        algorithm
          func(exp.exp1);
          func(exp.exp2);
        then
          ();

      case LUNARY() algorithm func(exp.exp); then ();

      case RELATION()
        algorithm
          func(exp.exp1);
          func(exp.exp2);
        then
          ();

      case IF()
        algorithm
          func(exp.condition);
          func(exp.trueBranch);
          func(exp.falseBranch);
        then
          ();

      case CAST() algorithm func(exp.exp); then ();
      case BOX() algorithm func(exp.exp); then ();
      case UNBOX() algorithm func(exp.exp); then ();

      case SUBSCRIPTED_EXP()
        algorithm
          func(exp.exp);

          for s in exp.subscripts loop
            Subscript.applyExpShallow(s, func);
          end for;
        then
          ();

      case TUPLE_ELEMENT() algorithm func(exp.tupleExp); then ();
      case RECORD_ELEMENT() algorithm func(exp.recordExp); then ();
      case MUTABLE() algorithm func(Mutable.access(exp.exp)); then ();
      case PARTIAL_FUNCTION_APPLICATION() algorithm applyListShallow(exp.args, func); then ();
      else ();
    end match;
  end applyShallow;

  function applyShallowOpt
    input Option<Expression> exp;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  protected
    Expression e;
  algorithm
    if isSome(exp) then
      SOME(e) := exp;
      func(e);
    end if;
  end applyShallowOpt;

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
        list<Subscript> subs;
        ClockKind ck;
        list<list<Expression>> mat;

      case CLKCONST()
        algorithm
          (ck, arg) := ClockKind.mapFoldExp(exp.clk, func, arg);
        then
          if referenceEq(exp.clk, ck) then exp else CLKCONST(ck);

      case CREF()
        algorithm
          (cr, arg) := ComponentRef.mapFoldExp(exp.cref, func, arg);
       then
          if referenceEq(exp.cref, cr) then exp else CREF(exp.ty, cr);

      case ARRAY()
        algorithm
          (expl, arg) := List.map1Fold(exp.elements, mapFold, func, arg);
        then
          ARRAY(exp.ty, expl, exp.literal);

      case MATRIX()
        algorithm
          (mat, arg) := List.mapFoldList(exp.elements, function mapFold(func = func), arg);
        then
          MATRIX(mat);

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
          (call, arg) := Call.mapFoldExp(exp.call, func, arg);
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
             referenceEq(exp.falseBranch, e3) then exp else IF(exp.ty, e1, e2, e3);

      case CAST()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case BOX()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else box(e1);

      case UNBOX()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
        then
          if referenceEq(exp.exp, e1) then exp else unbox(e1);

      case SUBSCRIPTED_EXP()
        algorithm
          (e1, arg) := mapFold(exp.exp, func, arg);
          (subs, arg) := List.mapFold(exp.subscripts, function Subscript.mapFoldExp(func = func), arg);
        then
          SUBSCRIPTED_EXP(e1, subs, exp.ty, exp.split);

      case TUPLE_ELEMENT()
        algorithm
          (e1, arg) := mapFold(exp.tupleExp, func, arg);
        then
          if referenceEq(exp.tupleExp, e1) then exp else TUPLE_ELEMENT(e1, exp.index, exp.ty);

      case RECORD_ELEMENT()
        algorithm
          (e1, arg) := mapFold(exp.recordExp, func, arg);
        then
          if referenceEq(exp.recordExp, e1) then exp else RECORD_ELEMENT(e1, exp.index, exp.fieldName, exp.ty);

      case MUTABLE()
        algorithm
          (e1, arg) := mapFold(Mutable.access(exp.exp), func, arg);
          Mutable.update(exp.exp, e1);
        then
          exp;

      case PARTIAL_FUNCTION_APPLICATION()
        algorithm
          (expl, arg) := List.map1Fold(exp.args, mapFold, func, arg);
          exp.args := expl;
        then
          exp;

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
    outExp := match exp
      case SOME(e)
        algorithm
          (e, arg) := mapFold(e, func, arg);
        then
          SOME(e);

      else exp;
    end match;
  end mapFoldOpt;

  function mapFoldShallow<ArgT>
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
        Option<Expression> oe;
        ComponentRef cr;
        list<Expression> expl;
        Call call;
        list<Subscript> subs;
        Boolean unchanged;
        ClockKind ck;
        list<list<Expression>> mat;

      case CLKCONST()
        algorithm
          (ck, arg) := ClockKind.mapFoldExpShallow(exp.clk, func, arg);
        then
          if referenceEq(exp.clk, ck) then exp else CLKCONST(ck);

      case CREF()
        algorithm
          (cr, arg) := ComponentRef.mapFoldExpShallow(exp.cref, func, arg);
       then
          if referenceEq(exp.cref, cr) then exp else CREF(exp.ty, cr);

      case ARRAY()
        algorithm
          (expl, arg) := List.mapFold(exp.elements, func, arg);
        then
          ARRAY(exp.ty, expl, exp.literal);

      case MATRIX()
        algorithm
          (mat, arg) := List.mapFoldList(exp.elements, func, arg);
        then
          MATRIX(mat);

      case RANGE(step = oe)
        algorithm
          (e1, arg) := func(exp.start, arg);
          (oe, arg) := mapFoldOptShallow(exp.step, func, arg);
          (e3, arg) := func(exp.stop, arg);
        then
          if referenceEq(e1, exp.start) and referenceEq(oe, exp.step) and referenceEq(e3, exp.stop) then
            exp else RANGE(exp.ty, e1, oe, e3);

      case TUPLE()
        algorithm
          (expl, arg) := List.mapFold(exp.elements, func, arg);
        then
          TUPLE(exp.ty, expl);

      case RECORD()
        algorithm
          (expl, arg) := List.mapFold(exp.elements, func, arg);
        then
          RECORD(exp.path, exp.ty, expl);

      case CALL()
        algorithm
          (call, arg) := Call.mapFoldExpShallow(exp.call, func, arg);
        then
          if referenceEq(exp.call, call) then exp else CALL(call);

      case SIZE()
        algorithm
          (e1, arg) := func(exp.exp, arg);
          (oe, arg) := mapFoldOptShallow(exp.dimIndex, func, arg);
        then
          if referenceEq(exp.exp, e1) and referenceEq(exp.dimIndex, oe) then
            exp else SIZE(e1, oe);

      case BINARY()
        algorithm
          (e1, arg) := func(exp.exp1, arg);
          (e2, arg) := func(exp.exp2, arg);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else BINARY(e1, exp.operator, e2);

      case UNARY()
        algorithm
          (e1, arg) := func(exp.exp, arg);
        then
          if referenceEq(exp.exp, e1) then exp else UNARY(exp.operator, e1);

      case LBINARY()
        algorithm
          (e1, arg) := func(exp.exp1, arg);
          (e2, arg) := func(exp.exp2, arg);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else LBINARY(e1, exp.operator, e2);

      case LUNARY()
        algorithm
          (e1, arg) := func(exp.exp, arg);
        then
          if referenceEq(exp.exp, e1) then exp else LUNARY(exp.operator, e1);

      case RELATION()
        algorithm
          (e1, arg) := func(exp.exp1, arg);
          (e2, arg) := func(exp.exp2, arg);
        then
          if referenceEq(exp.exp1, e1) and referenceEq(exp.exp2, e2)
            then exp else RELATION(e1, exp.operator, e2);

      case IF()
        algorithm
          (e1, arg) := func(exp.condition, arg);
          (e2, arg) := func(exp.trueBranch, arg);
          (e3, arg) := func(exp.falseBranch, arg);
        then
          if referenceEq(exp.condition, e1) and referenceEq(exp.trueBranch, e2) and
             referenceEq(exp.falseBranch, e3) then exp else IF(exp.ty, e1, e2, e3);

      case CAST()
        algorithm
          (e1, arg) := func(exp.exp, arg);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case BOX()
        algorithm
          (e1, arg) := func(exp.exp, arg);
        then
          if referenceEq(exp.exp, e1) then exp else box(e1);

      case UNBOX()
        algorithm
          (e1, arg) := func(exp.exp, arg);
        then
          if referenceEq(exp.exp, e1) then exp else unbox(e1);

      case SUBSCRIPTED_EXP()
        algorithm
          (e1, arg) := func(exp.exp, arg);
          (subs, arg) := List.mapFold(exp.subscripts, function Subscript.mapFoldExpShallow(func = func), arg);
        then
          SUBSCRIPTED_EXP(e1, subs, exp.ty, exp.split);

      case TUPLE_ELEMENT()
        algorithm
          (e1, arg) := func(exp.tupleExp, arg);
        then
          if referenceEq(exp.tupleExp, e1) then exp else TUPLE_ELEMENT(e1, exp.index, exp.ty);

      case RECORD_ELEMENT()
        algorithm
          (e1, arg) := func(exp.recordExp, arg);
        then
          if referenceEq(exp.recordExp, e1) then exp else RECORD_ELEMENT(e1, exp.index, exp.fieldName, exp.ty);

      case MUTABLE()
        algorithm
          (e1, arg) := func(Mutable.access(exp.exp), arg);
          Mutable.update(exp.exp, e1);
        then
          exp;

      case PARTIAL_FUNCTION_APPLICATION()
        algorithm
          (expl, arg) := List.mapFold(exp.args, func, arg);
          exp.args := expl;
        then
          exp;

      else exp;
    end match;
  end mapFoldShallow;

  function mapFoldOptShallow<ArgT>
    input Option<Expression> exp;
    input MapFunc func;
          output Option<Expression> outExp;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    Expression e1, e2;
  algorithm
    outExp := match exp
      case SOME(e1)
        algorithm
          (e2, arg) := func(e1, arg);
        then
          if referenceEq(e1, e2) then exp else SOME(e2);

      else exp;
    end match;
  end mapFoldOptShallow;

  function containsOpt
    input Option<Expression> exp;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
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

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    if func(exp) then
      res := true;
      return;
    end if;

    res := match exp
      local
        Expression e;

      case CLKCONST() then ClockKind.containsExp(exp.clk, func);
      case CREF() then ComponentRef.containsExp(exp.cref, func);
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
      case CALL() then Call.containsExp(exp.call, func);

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
      case BOX() then contains(exp.exp, func);
      case UNBOX() then contains(exp.exp, func);

      case SUBSCRIPTED_EXP()
        then contains(exp.exp, func) or Subscript.listContainsExp(exp.subscripts, func);

      case TUPLE_ELEMENT() then contains(exp.tupleExp, func);
      case RECORD_ELEMENT() then contains(exp.recordExp, func);
      case MUTABLE() then contains(Mutable.access(exp.exp), func);
      case PARTIAL_FUNCTION_APPLICATION() then listContains(exp.args, func);
      else false;
    end match;
  end contains;

  function listContains
    input list<Expression> expl;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    for e in expl loop
      if contains(e, func) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end listContains;

  function containsShallow
    input Expression exp;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    res := match exp
      case CLKCONST() then ClockKind.containsExpShallow(exp.clk, func);
      case CREF() then ComponentRef.containsExpShallow(exp.cref, func);
      case ARRAY() then listContainsShallow(exp.elements, func);

      case MATRIX()
        algorithm
          res := false;

          for row in exp.elements loop
            if listContainsShallow(row, func) then
              res := true;
              break;
            end if;
          end for;
        then
          res;

      case RANGE()
        then func(exp.start) or
             Util.applyOptionOrDefault(exp.step, func, false) or
             func(exp.stop);

      case TUPLE() then listContainsShallow(exp.elements, func);
      case RECORD() then listContainsShallow(exp.elements, func);
      case CALL() then Call.containsExpShallow(exp.call, func);

      case SIZE()
        then Util.applyOptionOrDefault(exp.dimIndex, func, false) or
             func(exp.exp);

      case BINARY() then func(exp.exp1) or func(exp.exp2);
      case UNARY() then func(exp.exp);
      case LBINARY() then func(exp.exp1) or func(exp.exp2);
      case LUNARY() then func(exp.exp);
      case RELATION() then func(exp.exp1) or func(exp.exp2);
      case IF() then func(exp.condition) or func(exp.trueBranch) or func(exp.falseBranch);
      case CAST() then func(exp.exp);
      case BOX() then func(exp.exp);
      case UNBOX() then func(exp.exp);

      case SUBSCRIPTED_EXP()
        then func(exp.exp) or Subscript.listContainsExpShallow(exp.subscripts, func);

      case TUPLE_ELEMENT() then func(exp.tupleExp);
      case RECORD_ELEMENT() then func(exp.recordExp);
      case MUTABLE() then func(Mutable.access(exp.exp));
      case PARTIAL_FUNCTION_APPLICATION() then listContains(exp.args, func);
      else false;
    end match;
  end containsShallow;

  function listContainsShallow
    input list<Expression> expl;
    input ContainsPred func;
    output Boolean res;

    partial function ContainsPred
      input Expression exp;
      output Boolean res;
    end ContainsPred;
  algorithm
    for e in expl loop
      if func(e) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end listContainsShallow;

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
    exp := CREF(ComponentRef.getSubscriptedType(cref), cref);
  end fromCref;

  function toCref
    input Expression exp;
    output ComponentRef cref;
  algorithm
    CREF(cref = cref) := exp;
  end toCref;

  function isIterator
    input Expression exp;
    output Boolean isIterator;
  algorithm
    isIterator := match exp
      case CREF() then ComponentRef.isIterator(exp.cref);
      else false;
    end match;
  end isIterator;

  function containsAnyIterator
    input Expression exp;
    input InstContext.Type context;
    output Boolean iter;
  algorithm
    if InstContext.inFor(context) then
      iter := contains(exp, isIterator);
    else
      iter := false;
    end if;
  end containsAnyIterator;

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

  function isOne
    input Expression exp;
    output Boolean isOne;
  algorithm
    isOne := match exp
      case INTEGER() then exp.value == 1;
      case REAL() then exp.value == 1.0;
      case CAST() then isOne(exp.exp);
      else false;
    end match;
  end isOne;

  function isNegative
    input Expression exp;
    output Boolean negative;
  algorithm
    negative := match exp
      case INTEGER() then exp.value < 0;
      case REAL() then exp.value < 0;
      case BOOLEAN() then false;
      case ENUM_LITERAL() then false;
      case CAST() then isNegative(exp.exp);
      case UNARY() then not isNegative(exp.exp);
      else false;
    end match;
  end isNegative;

  function isScalar
    input Expression exp;
    output Boolean scalar = Type.isScalar(typeOf(exp));
  end isScalar;

  function isScalarLiteral
    input Expression exp;
    output Boolean literal;
  algorithm
    literal := match exp
      case INTEGER() then true;
      case REAL() then true;
      case STRING() then true;
      case BOOLEAN() then true;
      case ENUM_LITERAL() then true;
      else false;
    end match;
  end isScalarLiteral;

  function isLiteral
    input Expression exp;
    output Boolean literal;
  algorithm
    literal := match exp
      case INTEGER() then true;
      case REAL() then true;
      case STRING() then true;
      case BOOLEAN() then true;
      case ENUM_LITERAL() then true;
      case ARRAY() then exp.literal or List.all(exp.elements, isLiteral);
      case RECORD() then List.all(exp.elements, isLiteral);
      case RANGE() then isLiteral(exp.start) and
                        isLiteral(exp.stop) and
                        Util.applyOptionOrDefault(exp.step, isLiteral, true);
      else false;
    end match;
  end isLiteral;

  function isInteger
    input Expression exp;
    output Boolean isInteger;
  algorithm
    isInteger := match exp
      case INTEGER() then true;
      else false;
    end match;
  end isInteger;

  function isBoolean
    input Expression exp;
    output Boolean isBool;
  algorithm
    isBool := match exp
      case BOOLEAN() then true;
      else false;
    end match;
  end isBoolean;

  function isRecord
    input Expression exp;
    output Boolean isRecord;
  algorithm
    isRecord := match exp
      case RECORD() then true;
      else false;
    end match;
  end isRecord;

  function isRecordOrRecordArray
    input Expression exp;
    output Boolean isRecord;
  algorithm
    isRecord := match exp
      case RECORD() then true;
      case ARRAY() then List.all(exp.elements, isRecordOrRecordArray);
      else false;
    end match;
  end isRecordOrRecordArray;

  function fillType
    "Creates an array with the given type, filling it with the given scalar
     expression."
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
      exp := makeArray(arr_ty, expl, literal = isLiteral(exp));
    end for;
  end fillType;

  function liftArray
    "Creates an array with the given dimension, where each element is the given
     expression. Example: liftArray([3], 1) => {1, 1, 1}"
    input Dimension dim;
    input output Expression exp;
          output Type arrayType = typeOf(exp);
  protected
    list<Expression> expl = {};
  algorithm
    for i in 1:Dimension.size(dim) loop
      expl := exp :: expl;
    end for;

    arrayType := Type.liftArrayLeft(arrayType, dim);
    exp := makeArray(arrayType, expl, literal = isLiteral(exp));
  end liftArray;

  function liftArrayList
    "Creates an array from the given list of dimensions, where each element is
     the given expression. Example:
       liftArrayList([2, 3], 1) => {{1, 1, 1}, {1, 1, 1}}"
    input list<Dimension> dims;
    input output Expression exp;
          output Type arrayType = typeOf(exp);
  protected
    list<Expression> expl;
    Boolean is_literal = isLiteral(exp);
  algorithm
    for dim in listReverse(dims) loop
      expl := {};
      for i in 1:Dimension.size(dim) loop
        expl := exp :: expl;
      end for;

      arrayType := Type.liftArrayLeft(arrayType, dim);
      exp := makeArray(arrayType, expl, literal = is_literal);
    end for;
  end liftArrayList;

  function makeZero
    input Type ty;
    output Expression zeroExp;
  algorithm
    zeroExp := match ty
      case Type.REAL() then REAL(0.0);
      case Type.INTEGER() then INTEGER(0);
      case Type.ARRAY()
        then ARRAY(ty,
                   List.fill(makeZero(Type.unliftArray(ty)),
                             Dimension.size(listHead(ty.dimensions))),
                   literal = true);
      case Type.COMPLEX() then makeOperatorRecordZero(ty.cls);
    end match;
  end makeZero;

  function makeOperatorRecordZero
    input InstNode recordNode;
    output Expression zeroExp;
  protected
    InstNode op_node;
    Function.Function fn;
  algorithm
    op_node := Class.lookupElement("'0'", InstNode.getClass(recordNode));
    Function.Function.instFunctionNode(op_node, NFInstContext.NO_CONTEXT, InstNode.info(InstNode.parent(op_node)));
    {fn} := Function.Function.typeNodeCache(op_node);
    zeroExp := CALL(Call.makeTypedCall(fn, {}, Variability.CONSTANT, Purity.PURE));
    zeroExp := Ceval.evalExp(zeroExp);
  end makeOperatorRecordZero;

  function makeOne
    input Type ty;
    output Expression zeroExp;
  algorithm
    zeroExp := match ty
      case Type.REAL() then REAL(1.0);
      case Type.INTEGER() then INTEGER(1);
      case Type.ARRAY()
        then ARRAY(ty,
                   List.fill(makeZero(Type.unliftArray(ty)),
                             Dimension.size(listHead(ty.dimensions))),
                   literal = true);
    end match;
  end makeOne;

  function makeMaxValue
    input Type ty;
    output Expression exp;
  algorithm
    exp := match ty
      case Type.REAL() then REAL(System.realMaxLit());
      case Type.INTEGER() then INTEGER(System.intMaxLit());
      case Type.BOOLEAN() then BOOLEAN(true);
      case Type.ENUMERATION() then ENUM_LITERAL(ty, List.last(ty.literals), listLength(ty.literals));
      case Type.ARRAY()
        then ARRAY(ty,
                   List.fill(makeMaxValue(Type.unliftArray(ty)),
                             Dimension.size(listHead(ty.dimensions))),
                   literal = true);
    end match;
  end makeMaxValue;

  function makeMinValue
    input Type ty;
    output Expression exp;
  algorithm
    exp := match ty
      case Type.REAL() then REAL(-System.realMaxLit());
      case Type.INTEGER() then INTEGER(-System.intMaxLit());
      case Type.BOOLEAN() then BOOLEAN(false);
      case Type.ENUMERATION() then ENUM_LITERAL(ty, listHead(ty.literals), 1);
      case Type.ARRAY()
        then makeArray(ty,
                       List.fill(makeMinValue(Type.unliftArray(ty)),
                                 Dimension.size(listHead(ty.dimensions))),
                       literal = true);
    end match;
  end makeMinValue;

  function makeDefaultValue
    input Type ty;
    output Expression exp;
  algorithm
    exp := match ty
      case Type.INTEGER() then INTEGER(0);
      case Type.REAL() then REAL(0);
      case Type.STRING() then STRING("");
      case Type.BOOLEAN() then BOOLEAN(false);
      case Type.ENUMERATION() then ENUM_LITERAL(ty, listHead(ty.literals), 1);
      case Type.ARRAY() then fillType(ty, makeDefaultValue(Type.arrayElementType(ty)));
      case Type.TUPLE() then TUPLE(ty, list(makeDefaultValue(t) for t in ty.types));
    end match;
  end makeDefaultValue;

  function box
    input Expression exp;
    output Expression boxedExp;
  algorithm
    boxedExp := match exp
      case STRING() then exp;
      case RECORD()
        then RECORD(exp.path, Type.box(exp.ty), list(box(e) for e in exp.elements));
      case BOX() then exp;
      else BOX(exp);
    end match;
  end box;

  function unbox
    input Expression boxedExp;
    output Expression exp;
  algorithm
    exp := match boxedExp
      local
        Type ty;

      case BOX() then boxedExp.exp;

      else
        algorithm
          ty := typeOf(boxedExp);
        then
          if Type.isBoxed(ty) then UNBOX(boxedExp, Type.unbox(ty)) else boxedExp;

    end match;
  end unbox;

  function isNegated
    input Expression exp;
    output Boolean negated;
  algorithm
    negated := match exp
      case INTEGER() then exp.value < 0;
      case REAL() then exp.value < 0;
      case CAST() then isNegated(exp.exp);
      case UNARY() then true;
      else false;
    end match;
  end isNegated;

  function negate
    "Returns '-exp'"
    input output Expression exp;
  algorithm
    exp := match exp
      case INTEGER() then INTEGER(-exp.value);
      case REAL() then REAL(-exp.value);
      case CAST() then CAST(exp.ty, negate(exp.exp));
      case UNARY() then exp.exp;
      else UNARY(Operator.makeUMinus(typeOf(exp)), exp);
    end match;
  end negate;

  function logicNegate
    "Returns 'not exp'"
    input Expression exp;
    output Expression outExp;
  algorithm
    outExp := match exp
      case BOOLEAN() then BOOLEAN(not exp.value);
      case LUNARY() then exp.exp;
      else LUNARY(Operator.makeNot(typeOf(exp)), exp);
    end match;
  end logicNegate;

  function arrayElements
    input Expression array;
    output list<Expression> elements;
  algorithm
    ARRAY(elements = elements) := array;
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

  function arrayScalarElement
    input Expression arrayExp;
    output Expression scalarExp;
  algorithm
    ARRAY(elements = {scalarExp}) := arrayExp;
  end arrayScalarElement;

  function hasArrayCall
    "Returns true if the given expression contains a function call that returns
     an array, otherwise false."
    input Expression exp;
    output Boolean hasArrayCall;
  algorithm
    hasArrayCall := contains(exp, hasArrayCall2);
  end hasArrayCall;

  function hasArrayCall2
    input Expression exp;
    output Boolean hasArrayCall;
  protected
    Call call;
    Type ty;
  algorithm
    hasArrayCall := match exp
      case CALL(call = call)
        algorithm
          ty := Call.typeOf(call);
        then
          Type.isArray(ty) and Call.isVectorizeable(call);

      case TUPLE_ELEMENT(tupleExp = CALL(call = call))
        algorithm
          ty := Type.nthTupleType(Call.typeOf(call), exp.index);
        then
          Type.isArray(ty) and Call.isVectorizeable(call);

      else false;
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
    Boolean literal;
  algorithm
    ARRAY(Type.ARRAY(ty, dim1 :: dim2 :: rest_dims), expl, literal) := arrayExp;

    if not listEmpty(expl) then
      row_ty := Type.ARRAY(ty, dim1 :: rest_dims);
      matrix := list(arrayElements(e) for e in expl);
      matrix := List.transposeList(matrix);
      expl := list(makeArray(row_ty, row, literal) for row in matrix);
    end if;

    outExp := makeArray(Type.ARRAY(ty, dim2 :: dim1 :: rest_dims), expl, literal);
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

      rows := makeArray(row_ty, row, literal = true) :: rows;
    end for;

    matrix := makeArray(Type.liftArrayLeft(row_ty, Dimension.fromInteger(n)), rows, literal = true);
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
        Expression arr_exp;
        Boolean expanded;

      // No types left, we're done!
      case (_, {}) then exp;

      // An array, promote each element in the array.
      case (ARRAY(), ty :: rest_ty)
        then makeArray(ty, list(promote2(e, false, dims, rest_ty) for e in exp.elements));

      // An expression with array type, but which is not an array expression.
      // Such an expression can't be promoted here, so we create a promote call instead.
      case (_, _) guard isArray
        algorithm
          (outExp, expanded) := ExpandExp.expand(exp);

          if expanded then
            outExp := promote2(outExp, true, dims, types);
          else
            outExp := CALL(Call.makeTypedCall(
              NFBuiltinFuncs.PROMOTE, {exp, INTEGER(dims)}, variability(exp), purity(exp), listHead(types)));
          end if;
        then
          outExp;

      // A scalar expression, promote it as many times as the number of types given.
      else
        algorithm
          outExp := exp;
          for ty in listReverse(types) loop
            outExp := makeArray(ty, {outExp});
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
      case CLKCONST() then Variability.DISCRETE;
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
      case BOX() then variability(exp.exp);
      case UNBOX() then variability(exp.exp);
      case SUBSCRIPTED_EXP()
        then Prefixes.variabilityMax(variability(exp.exp), Subscript.variabilityList(exp.subscripts));
      case TUPLE_ELEMENT() then variability(exp.tupleExp);
      case RECORD_ELEMENT() then variability(exp.recordExp);
      case MUTABLE() then variability(Mutable.access(exp.exp));
      case EMPTY() then Variability.CONSTANT;
      case PARTIAL_FUNCTION_APPLICATION() then Variability.CONTINUOUS;
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

  function purity
    input Expression exp;
    output Purity pur;
  algorithm
    pur := match exp
      case INTEGER() then Purity.PURE;
      case REAL() then Purity.PURE;
      case STRING() then Purity.PURE;
      case BOOLEAN() then Purity.PURE;
      case ENUM_LITERAL() then Purity.PURE;
      case CLKCONST() then Purity.PURE;
      case CREF() then ComponentRef.purity(exp.cref);
      case TYPENAME() then Purity.PURE;
      case ARRAY() then purityList(exp.elements);
      case MATRIX() then List.fold(exp.elements, purityList, Purity.PURE);

      case RANGE()
        algorithm
          pur := purity(exp.start);
          pur := Prefixes.purityMin(pur, purity(exp.stop));

          if isSome(exp.step) then
            pur := Prefixes.purityMin(pur, purity(Util.getOption(exp.step)));
          end if;
        then
          pur;

      case TUPLE() then purityList(exp.elements);
      case RECORD() then purityList(exp.elements);
      case CALL() then Call.purity(exp.call);
      case SIZE()
        then if isSome(exp.dimIndex) then purity(Util.getOption(exp.dimIndex)) else Purity.PURE;

      case END() then Purity.PURE;
      case BINARY() then Prefixes.purityMin(purity(exp.exp1), purity(exp.exp2));
      case UNARY() then purity(exp.exp);
      case LBINARY() then Prefixes.purityMin(purity(exp.exp1), purity(exp.exp2));
      case LUNARY() then purity(exp.exp);
      case RELATION() then Prefixes.purityMin(purity(exp.exp1), purity(exp.exp2));
      case IF() then Prefixes.purityMin(purity(exp.condition),
                       Prefixes.purityMin(purity(exp.trueBranch), purity(exp.falseBranch)));
      case CAST() then purity(exp.exp);
      case BOX() then purity(exp.exp);
      case UNBOX() then purity(exp.exp);
      case SUBSCRIPTED_EXP()
        then Prefixes.purityMin(purity(exp.exp), Subscript.purityList(exp.subscripts));
      case TUPLE_ELEMENT() then purity(exp.tupleExp);
      case RECORD_ELEMENT() then purity(exp.recordExp);
      case MUTABLE() then purity(Mutable.access(exp.exp));
      case EMPTY() then Purity.PURE;
      case PARTIAL_FUNCTION_APPLICATION() then Purity.PURE;
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown expression.", sourceInfo());
        then
          fail();
    end match;
  end purity;

  function purityList
    input list<Expression> expl;
    input output Purity pur = Purity.PURE;
  algorithm
    for e in expl loop
      pur := Prefixes.purityMin(pur, purity(e));
    end for;
  end purityList;

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

  function isMutable
    input Expression exp;
    output Boolean isMutable;
  algorithm
    isMutable := match exp
      case MUTABLE() then true;
      else false;
    end match;
  end isMutable;

  function updateMutable
    input Expression mutableExp;
    input Expression value;
  protected
    Mutable<Expression> exp_ptr;
  algorithm
    Expression.MUTABLE(exp = exp_ptr) := mutableExp;
    Mutable.update(exp_ptr, value);
  end updateMutable;

  function isEmpty
    input Expression exp;
    output Boolean empty;
  algorithm
    empty := match exp
      case EMPTY() then true;
      else false;
    end match;
  end isEmpty;

  function enumIndexExp
    input Expression enumExp;
    output Expression indexExp;
  algorithm
    indexExp := match enumExp
      case ENUM_LITERAL() then INTEGER(enumExp.index);
      else CALL(Call.makeTypedCall(
        NFBuiltinFuncs.INTEGER_ENUM, {enumExp}, variability(enumExp), Purity.PURE));
    end match;
  end enumIndexExp;

  function toScalar
    input Expression exp;
    output Expression outExp;
  algorithm
    outExp := match exp
      case ARRAY(elements = {outExp}) then toScalar(outExp);
      else exp;
    end match;
  end toScalar;

  function tupleElement
    input Expression exp;
    input Type ty;
    input Integer index;
    output Expression tupleElem;
  algorithm
    tupleElem := match exp
      local
        Type ety;

      case TUPLE() then listGet(exp.elements, index);

      case ARRAY()
        algorithm
          ety := Type.unliftArray(ty);
          exp.elements := list(tupleElement(e, ety, index) for e in exp.elements);
        then
          exp;

      case SUBSCRIPTED_EXP(split = true)
        then mapSplitExpressions(exp, function tupleElement(ty = ty, index = index));

      else TUPLE_ELEMENT(exp, index, ty);
    end match;
  end tupleElement;

  function recordElement
    "Returns the field with the given name in a record expression. If the
     expression is an array it will return the equivalent of calling the
     function on each element of the array."
    input String elementName;
    input Expression recordExp;
    output Expression outExp;
  algorithm
    outExp := match recordExp
      local
        InstNode node;
        Class cls;
        ClassTree cls_tree;
        Type ty;
        Integer index;
        list<Expression> expl;
        ComponentRef cref;

      case RECORD(ty = Type.COMPLEX(cls = node))
        algorithm
          cls := InstNode.getClass(node);
          index := Class.lookupComponentIndex(elementName, cls);
        then
          listGet(recordExp.elements, index);

      case CREF()
        algorithm
          Type.COMPLEX(cls = node) := Type.arrayElementType(recordExp.ty);
          cls_tree := Class.classTree(InstNode.getClass(node));
          (node, false) := ClassTree.lookupElement(elementName, cls_tree);
          ty := InstNode.getType(node);
          cref := ComponentRef.prefixCref(node, ty, {}, recordExp.cref);
          ty := Type.liftArrayLeftList(ty, Type.arrayDims(recordExp.ty));
        then
          CREF(ty, cref);

      case ARRAY(elements = {}, ty = Type.ARRAY(elementType = Type.COMPLEX(cls = node)))
        algorithm
          cls := InstNode.getClass(node);
          index := Class.lookupComponentIndex(elementName, cls);
          ty := InstNode.getType(Class.nthComponent(index, cls));
        then
          makeArray(ty, {});

      case ARRAY(ty = Type.ARRAY(elementType = Type.COMPLEX(cls = node)))
        algorithm
          index := Class.lookupComponentIndex(elementName, InstNode.getClass(node));
          expl := list(nthRecordElement(index, e) for e in recordExp.elements);
          ty := Type.liftArrayLeft(typeOf(listHead(expl)),
                                   Dimension.fromInteger(listLength(expl)));
        then
          makeArray(ty, expl, recordExp.literal);

      case SUBSCRIPTED_EXP()
        algorithm
          outExp := recordElement(elementName, recordExp.exp);
          ty := Type.subscript(typeOf(outExp), recordExp.subscripts);
        then
          SUBSCRIPTED_EXP(outExp, recordExp.subscripts, ty, recordExp.split);

      case EMPTY() then fail();

      else
        algorithm
          ty := typeOf(recordExp);
          Type.COMPLEX(cls = node) := Type.arrayElementType(ty);
          cls := InstNode.getClass(node);
          index := Class.lookupComponentIndex(elementName, cls);
          ty := Type.liftArrayLeftList(
            InstNode.getType(Class.nthComponent(index, cls)),
            Type.arrayDims(ty));
        then
          RECORD_ELEMENT(recordExp, index, elementName, ty);

    end match;
  end recordElement;

  function nthRecordElement
    "Returns the nth field of a record expression. If the expression is an array
     it will return an array with the nth field in each array element."
    input Integer index;
    input Expression recordExp;
    output Expression outExp;
  algorithm
    outExp := match recordExp
      local
        InstNode node;
        list<Expression> expl;
        Type ty;

      case RECORD() then listGet(recordExp.elements, index);

      case CREF()
        algorithm
          Type.COMPLEX(cls = node) := Type.arrayElementType(typeOf(recordExp));
          node := Class.nthComponent(index, InstNode.getClass(node));
        then
          fromCref(ComponentRef.prefixCref(node, InstNode.getType(node), {}, recordExp.cref));

      case ARRAY(elements = {}, ty = Type.ARRAY(elementType = Type.COMPLEX(cls = node)))
        then makeEmptyArray(InstNode.getType(Class.nthComponent(index, InstNode.getClass(node))));

      case ARRAY()
        algorithm
          expl := list(nthRecordElement(index, e) for e in recordExp.elements);
          ty := Type.liftArrayLeft(typeOf(listHead(expl)), listHead(Type.arrayDims(recordExp.ty)));
        then
          makeArray(ty, expl);

      case RECORD_ELEMENT(ty = Type.ARRAY(elementType = Type.COMPLEX(cls = node)))
        algorithm
          node := Class.nthComponent(index, InstNode.getClass(node));
        then
          RECORD_ELEMENT(recordExp, index, InstNode.name(node),
                         Type.liftArrayLeftList(InstNode.getType(node), Type.arrayDims(recordExp.ty)));

      case SUBSCRIPTED_EXP()
        algorithm
          outExp := nthRecordElement(index, recordExp.exp);
          ty := Type.subscript(typeOf(outExp), recordExp.subscripts);
        then
          SUBSCRIPTED_EXP(outExp, recordExp.subscripts, ty, recordExp.split);

      else
        algorithm
          Type.COMPLEX(cls = node) := typeOf(recordExp);
          node := Class.nthComponent(index, InstNode.getClass(node));
        then
          RECORD_ELEMENT(recordExp, index, InstNode.name(node), InstNode.getType(node));

    end match;
  end nthRecordElement;

  function retype
    input output Expression exp;
  algorithm
    () := match exp
      local
        list<Dimension> dims;
        Type ty;

      case RANGE()
        algorithm
          exp.ty := TypeCheck.getRangeType(exp.start, exp.step, exp.stop,
            typeOf(exp.start), AbsynUtil.dummyInfo);
        then
          ();

      case CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR())
        algorithm
          exp.call := Call.retype(exp.call);
        then
          ();

      else
        algorithm
          ty := typeOf(exp);

          if Type.isConditionalArray(ty) then
            ty := Type.simplifyConditionalArray(ty);
            exp := setType(ty, exp);
          end if;
        then
          ();

    end match;
  end retype;

  function nthEnumLiteral
    input Type ty;
    input Integer n;
    output Expression exp;
  algorithm
    exp := ENUM_LITERAL(ty, Type.nthEnumLiteral(ty, n), n);
  end nthEnumLiteral;

  function foldReduction
    input Expression exp;
    input list<tuple<InstNode, Expression>> iterators;
    input Expression foldExp;
    input MapFn mapFn;
    input FoldFn foldFn;
    output Expression result;

    partial function MapFn
      input output Expression exp;
    end MapFn;

    partial function FoldFn
      input Expression exp1;
      input Expression exp2;
      output Expression result;
    end FoldFn;
  protected
    InstNode node;
    Expression e, range;
    Mutable<Expression> iter;
    list<Expression> ranges = {};
    list<Mutable<Expression>> iters = {};
  algorithm
    e := exp;
    for i in iterators loop
      (node, range) := i;
      iter := Mutable.create(INTEGER(0));
      e := replaceIterator(e, node, MUTABLE(iter));
      iters := iter :: iters;
      ranges := range :: ranges;
    end for;

    result := foldReduction2(e, ranges, iters, foldExp, mapFn, foldFn);
  end foldReduction;

  function foldReduction2
    input Expression exp;
    input list<Expression> ranges;
    input list<Mutable<Expression>> iterators;
    input Expression foldExp;
    input MapFn mapFn;
    input FoldFn foldFn;
    output Expression result;

    partial function MapFn
      input output Expression exp;
    end MapFn;

    partial function FoldFn
      input Expression exp1;
      input Expression exp2;
      output Expression result;
    end FoldFn;
  protected
    Expression range, value;
    list<Expression> ranges_rest, el;
    Mutable<Expression> iter;
    list<Mutable<Expression>> iters_rest;
    ExpressionIterator range_iter;
  algorithm
    if listEmpty(ranges) then
      result := foldFn(foldExp, mapFn(exp));
    else
      range :: ranges_rest := ranges;
      iter :: iters_rest := iterators;
      range_iter := ExpressionIterator.fromExp(range);
      result := foldExp;

      while ExpressionIterator.hasNext(range_iter) loop
        (range_iter, value) := ExpressionIterator.next(range_iter);
        Mutable.update(iter, value);
        result := foldReduction2(exp, ranges_rest, iters_rest, result, mapFn, foldFn);
      end while;
    end if;
  end foldReduction2;

  function isPure
    input Expression exp;
    output Boolean isPure;
  algorithm
    isPure := match exp
      case Expression.CREF() then not ComponentRef.isIterator(exp.cref);
      case Expression.CALL()
        then match AbsynUtil.pathFirstIdent(Call.functionName(exp.call))
          case "Connections" then false;
          case "cardinality" then false;
          else not Call.isImpure(exp.call);
        end match;
      else true;
    end match;
  end isPure;

  function filterSplitIndices
    input output Expression exp;
    input InstNode node;
  protected
    Expression e;
    list<Subscript> subs;
  algorithm
    exp := match exp
      case Expression.SUBSCRIPTED_EXP(exp = e, subscripts = subs)
        algorithm
          subs := list(s for s guard not filterSplitIndices2(s, node) in subs);
        then
          Expression.applySubscripts(subs, exp.exp);

      else exp;
    end match;
  end filterSplitIndices;

  function filterSplitIndices2
    input Subscript sub;
    input InstNode node;
    output Boolean matching;
  algorithm
    matching := match sub
      case Subscript.SPLIT_INDEX() then InstNode.refEqual(sub.node, node);
      case Subscript.SPLIT_PROXY() then InstNode.refEqual(sub.parent, node);
      else false;
    end match;
  end filterSplitIndices2;

  function expandSplitIndices
    "Replaces split indices in a subscripted expression with : subscripts."
    input Expression exp;
    output Expression outExp;
  algorithm
    outExp := match exp
      case Expression.SUBSCRIPTED_EXP()
        then Expression.applySubscripts(Subscript.expandSplitIndices(exp.subscripts, {}), exp.exp);

      else exp;
    end match;
  end expandSplitIndices;

  function expandNonListedSplitIndices
    "Replaces split indices in a subscripted expression with : subscripts,
     except for indices that reference nodes in the given list."
    input Expression exp;
    input list<InstNode> indicesToKeep;
    output Expression outExp;
  algorithm
    outExp := match exp
      case Expression.SUBSCRIPTED_EXP(split = true)
        then Expression.applySubscripts(Subscript.expandSplitIndices(exp.subscripts, indicesToKeep), exp.exp);
      else exp;
    end match;
  end expandNonListedSplitIndices;

  function isSplitSubscriptedExp
    input Expression exp;
    output Boolean split;
  algorithm
    split := match exp
      case Expression.SUBSCRIPTED_EXP(split = split) then split;
      else false;
    end match;
  end isSplitSubscriptedExp;

  function mapSplitExpressions
    input Expression exp;
    input Func func;
    output Expression outExp;

    partial function Func
      input output Expression exp;
    end Func;
  protected
    Option<UnorderedMap<Subscript, Expression>> osub_repls;
    UnorderedMap<Subscript, Expression> sub_repls;
    list<Subscript> subs;
    list<Expression> sub_exps, dim_sizes;
  algorithm
    (outExp, osub_repls) := Expression.mapFold(exp, replaceSplitSubscripts, NONE());

    if isNone(osub_repls) then
      outExp := func(exp);
    else
      SOME(sub_repls) := osub_repls;
      subs := UnorderedMap.keyList(sub_repls);
      sub_exps := UnorderedMap.valueList(sub_repls);
      dim_sizes := list(Subscript.splitIndexDimExp(s) for s in subs);
      dim_sizes := list(replaceSplitSubscripts(d, SOME(sub_repls)) for d in dim_sizes);
      outExp := mapSplitExpressions2(outExp, dim_sizes, sub_exps, func);
      outExp := Expression.applySubscripts(subs, outExp);
    end if;
  end mapSplitExpressions;

  function replaceSplitSubscripts
    input output Expression exp;
    input output Option<UnorderedMap<Subscript, Expression>> subRepls;
  algorithm
    exp := match exp
      local
        list<Subscript> subs;

      case Expression.SUBSCRIPTED_EXP(split = true)
        algorithm
          (subs, subRepls) := List.mapFold(exp.subscripts, replaceSplitSubscripts2, subRepls);
        then
          Expression.applySubscripts(subs, exp.exp);

      else exp;
    end match;
  end replaceSplitSubscripts;

  function replaceSplitSubscripts2
    input output Subscript subscript;
    input output Option<UnorderedMap<Subscript, Expression>> subRepls;
  protected
    Expression sub_exp;
    UnorderedMap<Subscript, Expression> sub_repls;
  algorithm
    subscript := match subscript
      case Subscript.SPLIT_INDEX()
        algorithm
          if isSome(subRepls) then
            SOME(sub_repls) := subRepls;
          else
            sub_repls := UnorderedMap.new<Expression>(Subscript.hash, Subscript.isEqual);
            subRepls := SOME(sub_repls);
          end if;

          sub_exp := Expression.makeMutable(Expression.INTEGER(0));
          sub_exp := UnorderedMap.tryAdd(subscript, sub_exp, sub_repls);
        then
          Subscript.INDEX(sub_exp);

      else subscript;
    end match;
  end replaceSplitSubscripts2;

  function mapSplitExpressions2
    input Expression exp;
    input list<Expression> dimSizes;
    input list<Expression> subExps;
    input Func func;
    output Expression outExp;

    partial function Func
      input output Expression exp;
    end Func;
  protected
    Expression dim_size;
    list<Expression> rest_dims;
    Integer dim_size_int;
    Expression sub_exp;
    list<Expression> rest_subs, expl;
    Type ty;
  algorithm
    if listEmpty(dimSizes) then
      outExp := Expression.map(exp, mapSplitExpressions3);
      outExp := func(outExp);
    else
      dim_size :: rest_dims := dimSizes;
      dim_size_int := toInteger(Ceval.evalExp(dim_size));
      sub_exp :: rest_subs := subExps;
      expl := {};

      for i in dim_size_int:-1:1 loop
        Expression.updateMutable(sub_exp, Expression.INTEGER(i));
        outExp := mapSplitExpressions2(exp, rest_dims, rest_subs, func);
        expl := outExp :: expl;
      end for;

      ty := Expression.typeOf(if listEmpty(expl) then exp else listHead(expl));
      outExp := Expression.makeExpArray(expl, ty, isLiteral = true);
    end if;
  end mapSplitExpressions2;

  function mapSplitExpressions3
    input output Expression exp;
  protected
    list<Subscript> subs;
  algorithm
    exp := match exp
      case Expression.MUTABLE() then Mutable.access(exp.exp);

      case Expression.SUBSCRIPTED_EXP(subscripts = subs)
        then Expression.applySubscripts(subs, exp.exp);

      else exp;
    end match;
  end mapSplitExpressions3;

  function hasNonArrayIteratorSubscript
    "Returns true if the given iterator is only used to subscript array
     expression in the given expression, otherwise false."
    input Expression exp;
    input InstNode iterator;
    output Boolean res;
  algorithm
    res := match exp
      case CREF() then containsIterator(exp, iterator);
      case SUBSCRIPTED_EXP() then not isArray(exp.exp) and
        Subscript.listContainsExp(exp.subscripts, function containsIterator(iterator = iterator));
      else containsShallow(exp, function hasNonArrayIteratorSubscript(iterator = iterator));
    end match;
  end hasNonArrayIteratorSubscript;

  function mapCrefScalars
    "Takes a cref expression and applies a function to each scalar cref,
     creating a new expression with the same dimensions as the given cref.
       Ex: mapCrefScalars(/*Real[2, 2]*/ x, ComponentRef.toString) =>
           {{'x[1, 1]', 'x[1, 2]'}, {'x[2, 1]', 'x[2, 2]'}}"
    input Expression crefExp;
    input MapFn mapFn;
    output Expression outExp;

    partial function MapFn
      input ComponentRef cref;
      output Expression exp;
    end MapFn;
  algorithm
    outExp := ExpandExp.expand(crefExp);
    outExp := mapCrefScalars2(outExp, mapFn);
  end mapCrefScalars;

  function mapCrefScalars2
    input Expression exp;
    input MapFn mapFn;
    output Expression outExp;

    partial function MapFn
      input ComponentRef cref;
      output Expression exp;
    end MapFn;
  protected
    list<Expression> expl;
    Type ty;
    Boolean literal;
    ComponentRef cref;
  algorithm
    outExp := match exp
      case Expression.ARRAY()
        guard not listEmpty(exp.elements)
        algorithm
          expl := list(mapCrefScalars2(e, mapFn) for e in exp.elements);
          ty := typeOf(listHead(expl));
          literal := List.all(expl, isLiteral);
        then
          makeExpArray(expl, ty, literal);

      case Expression.CREF() then mapFn(exp.cref);
      else exp;
    end match;
  end mapCrefScalars2;

  function isFunctionPointer
    input Expression exp;
    output Boolean res;
  algorithm
    res := match exp
      case Expression.CREF(ty = Type.FUNCTION()) then true;
      case Expression.PARTIAL_FUNCTION_APPLICATION() then true;
      else false;
    end match;
  end isFunctionPointer;

  function isConnector
    "Returns true if the expression is a component reference that refers to a
     connector, otherwise false."
    input Expression exp;
    output Boolean res;
  protected
    InstNode node;
  algorithm
    res := match exp
      case Expression.CREF()
        algorithm
          node := ComponentRef.node(exp.cref);
        then
          InstNode.isComponent(node) and InstNode.isConnector(node);

      else false;
    end match;
  end isConnector;

  function isComponentExpression
    "Returns true if the expression is a component reference that refers to an
     actual component (and not e.g. a function), otherwise false"
    input Expression exp;
    output Boolean res;
  algorithm
    res := match exp
      case Expression.CREF()
        then ComponentRef.isCref(exp.cref) and
             InstNode.isComponent(ComponentRef.node(exp.cref));

      else false;
    end match;
  end isComponentExpression;

annotation(__OpenModelica_Interface="frontend");
end NFExpression;
