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
  import System;

  import Builtin = NFBuiltin;
  import BuiltinCall = NFBuiltinCall;
  import Expression = NFExpression;
  import Function = NFFunction;
  import NFPrefixes.Variability;
  import Prefixes = NFPrefixes;
  import Ceval = NFCeval;
  import ComplexType = NFComplexType;
  import ExpandExp = NFExpandExp;
  import TypeCheck = NFTypeCheck;
  import ValuesUtil;
  import MetaModelica.Dangerous.listReverseInPlace;
  import Types;

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
  import NFBinding.Binding;
  import NFComponent.Component;
  import NFClassTree.ClassTree;
  import NFClass.Class;
  import NFComponentRef.Origin;
  import NFTyping.ExpOrigin;
  import ExpressionSimplify;
  import Values;

	uniontype ClockKind
	  record INFERRED_CLOCK
	  end INFERRED_CLOCK;

	  record INTEGER_CLOCK
	    Expression intervalCounter;
	    Expression resolution " integer type >= 1 ";
	  end INTEGER_CLOCK;

	  record REAL_CLOCK
	    Expression interval;
	  end REAL_CLOCK;

	  record BOOLEAN_CLOCK
	    Expression condition;
	    Expression startInterval " real type >= 0.0 ";
	  end BOOLEAN_CLOCK;

	  record SOLVER_CLOCK
	    Expression c;
	    Expression solverMethod " string type ";
	  end SOLVER_CLOCK;

    function compare
      input ClockKind ck1;
      input ClockKind ck2;
      output Integer comp;
    algorithm
      comp := match (ck1, ck2)
        local
          Expression i1, ic1, r1, c1, si1, sm1, i2, ic2, r2, c2, si2, sm2;
        case (INFERRED_CLOCK(), INFERRED_CLOCK()) then 0;
        case (INTEGER_CLOCK(i1, r1),INTEGER_CLOCK(i2, r2))
          algorithm
            comp := Expression.compare(i1, i2);
            if (comp == 0) then
              comp := Expression.compare(r1, r2);
            end if;
          then comp;
        case (REAL_CLOCK(i1), REAL_CLOCK(i2)) then Expression.compare(i1, i2);
        case (BOOLEAN_CLOCK(c1, si1), BOOLEAN_CLOCK(c2, si2))
          algorithm
            comp := Expression.compare(c1, c2);
            if (comp == 0) then
              comp := Expression.compare(si1, si2);
            end if;
          then comp;
        case (SOLVER_CLOCK(c1, sm2), SOLVER_CLOCK(c2, sm1))
          algorithm
            comp := Expression.compare(c1, c2);
            if (comp == 0) then
              comp := Expression.compare(sm1, sm2);
            end if;
          then comp;
      end match;
    end compare;

	  function toDAE
	    input ClockKind ick;
	    output DAE.ClockKind ock;
	  algorithm
	    ock := match ick
	      local
	        Expression i, ic, r, c, si, sm;
	      case INFERRED_CLOCK()     then DAE.INFERRED_CLOCK();
	      case INTEGER_CLOCK(i, r)  then DAE.INTEGER_CLOCK(Expression.toDAE(i), Expression.toDAE(r));
	      case REAL_CLOCK(i)        then DAE.REAL_CLOCK(Expression.toDAE(i));
	      case BOOLEAN_CLOCK(c, si) then DAE.BOOLEAN_CLOCK(Expression.toDAE(c), Expression.toDAE(si));
	      case SOLVER_CLOCK(c, sm)  then DAE.SOLVER_CLOCK(Expression.toDAE(c), Expression.toDAE(sm));
	    end match;
	  end toDAE;

    function toDebugString
      input ClockKind ick;
      output String ock;
    algorithm
      ock := match ick
        local
          Expression i, ic, r, c, si, sm;
        case INFERRED_CLOCK()     then "INFERRED_CLOCK()";
        case INTEGER_CLOCK(i, r)  then "INTEGER_CLOCK(" + Expression.toString(i) + ", " + Expression.toString(r) + ")";
        case REAL_CLOCK(i)        then "REAL_CLOCK(" + Expression.toString(i) + ")";
        case BOOLEAN_CLOCK(c, si) then "BOOLEAN_CLOCK(" + Expression.toString(c) + ", " + Expression.toString(si) + ")";
        case SOLVER_CLOCK(c, sm)  then "SOLVER_CLOCK(" + Expression.toString(c) + ", " + Expression.toString(sm) + ")";
      end match;
    end toDebugString;

    function toString
      input ClockKind ck;
      output String str;
    algorithm
      str := match ck
        local
          Expression e1, e2;

        case INFERRED_CLOCK()      then "";
        case INTEGER_CLOCK(e1, e2) then Expression.toString(e1) + ", " + Expression.toString(e2);
        case REAL_CLOCK(e1)        then Expression.toString(e1);
        case BOOLEAN_CLOCK(e1, e2) then Expression.toString(e1) + ", " + Expression.toString(e2);
        case SOLVER_CLOCK(e1, e2)  then Expression.toString(e1) + ", " + Expression.toString(e2);
      end match;

      str := "Clock(" + str + ")";
    end toString;
	end ClockKind;

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
    list<Subscript> subscripts;
    Type ty;
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

  record BOX "MetaModelica boxed value"
    Expression exp;
  end BOX;

  record MUTABLE
    Mutable<Expression> exp;
  end MUTABLE;

  record EMPTY
    Type ty;
  end EMPTY;

  record CLKCONST "Clock constructors"
    ClockKind clk "Clock kinds";
  end CLKCONST;

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
          comp := Absyn.pathCompare(Type.enumName(exp1.ty), Type.enumName(ty));

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
          if comp == 0 then compareList(exp1.elements, expl) else comp;

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

      case RECORD()
        algorithm
          RECORD(path = p, elements = expl) := exp2;
          comp := Absyn.pathCompare(exp1.path, p);
        then
          if comp == 0 then compareList(exp1.elements, expl) else comp;

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

      case PARTIAL_FUNCTION_APPLICATION()
        algorithm
          PARTIAL_FUNCTION_APPLICATION(fn = cr, args = expl) := exp2;
          comp := ComponentRef.compare(exp1.fn, cr);

          if comp == 0 then
            comp := compareList(exp1.args, expl);
          end if;
        then
          comp;

      case BOX()
        algorithm
          BOX(exp = e2) := exp2;
        then
          compare(exp1.exp, e2);

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
      case RELATION()        then Operator.typeOf(exp.operator);
      case IF()              then typeOf(exp.trueBranch);
      case CAST()            then exp.ty;
      case UNBOX()           then exp.ty;
      case SUBSCRIPTED_EXP() then exp.ty;
      case TUPLE_ELEMENT()   then exp.ty;
      case RECORD_ELEMENT()  then exp.ty;
      case BOX()             then Type.METABOXED(typeOf(exp.exp));
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
    () := match exp
      case ENUM_LITERAL()    algorithm exp.ty := ty; then ();
      case CREF()            algorithm exp.ty := ty; then ();
      case TYPENAME()        algorithm exp.ty := ty; then ();
      case ARRAY()           algorithm exp.ty := ty; then ();
      case RANGE()           algorithm exp.ty := ty; then ();
      case TUPLE()           algorithm exp.ty := ty; then ();
      case RECORD()          algorithm exp.ty := ty; then ();
      case CALL()            algorithm exp.call := Call.setType(exp.call, ty); then ();
      case BINARY()          algorithm exp.operator := Operator.setType(ty, exp.operator); then ();
      case UNARY()           algorithm exp.operator := Operator.setType(ty, exp.operator); then ();
      case LBINARY()         algorithm exp.operator := Operator.setType(ty, exp.operator); then ();
      case LUNARY()          algorithm exp.operator := Operator.setType(ty, exp.operator); then ();
      case RELATION()        algorithm exp.operator := Operator.setType(ty, exp.operator); then ();
      case CAST()            algorithm exp.ty := ty; then ();
      case UNBOX()           algorithm exp.ty := ty; then ();
      case SUBSCRIPTED_EXP() algorithm exp.ty := ty; then ();
      case TUPLE_ELEMENT()   algorithm exp.ty := ty; then ();
      case RECORD_ELEMENT()  algorithm exp.ty := ty; then ();
      case PARTIAL_FUNCTION_APPLICATION() algorithm exp.ty := ty; then ();
      else ();
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
    Type t, ety;
    list<Expression> el;
  algorithm
    ety := Type.arrayElementType(ty);

    exp := match (exp, ety)
      // Integer can be cast to Real.
      case (INTEGER(), Type.REAL())
        then REAL(intReal(exp.value));

      // Real doesn't need to be cast to Real, since we convert e.g. array with
      // a mix of Integers and Reals to only Reals.
      case (REAL(), Type.REAL()) then exp;

      // For arrays we typecast each element and update the type of the array.
      case (ARRAY(ty = t, elements = el), _)
        algorithm
          el := list(typeCast(e, ety) for e in el);
          t := Type.setArrayElementType(t, ety);
        then
          ARRAY(t, el, exp.literal);

      case (RANGE(ty = t), _)
        algorithm
          t := Type.setArrayElementType(t, ety);
        then
          RANGE(t, typeCast(exp.start, ety), typeCastOpt(exp.step, ety), typeCast(exp.stop, ety));

      // Unary operators (i.e. -) are handled by casting the operand.
      case (UNARY(), _)
        algorithm
          t := Type.setArrayElementType(Operator.typeOf(exp.operator), ety);
        then
          UNARY(Operator.setType(t, exp.operator), typeCast(exp.exp, ety));

      // If-expressions are handled by casting each of the branches.
      case (IF(), _)
        then IF(exp.condition, typeCast(exp.trueBranch, ety), typeCast(exp.falseBranch, ety));

      // Calls are handled by Call.typeCast, which has special rules for some functions.
      case (CALL(), _)
        then Call.typeCast(exp, ety);

      // Casting a cast expression overrides its current cast type.
      case (CAST(), _) then typeCast(exp.exp, ty);

      // Other expressions are handled by making a CAST expression.
      else
        algorithm
          t := typeOf(exp);
          t := Type.setArrayElementType(t, ety);
        then
          CAST(t, exp);

    end match;
  end typeCast;

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

      case CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR())
        then applySubscriptArrayConstructor(subscript, exp.call, restSubscripts);

      case CALL()
        then applySubscriptCall(subscript, exp, restSubscripts);

      case IF() then applySubscriptIf(subscript, exp, restSubscripts);

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
    cr := ComponentRef.applySubscripts(subscript :: restSubscripts, cref);
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
        then SUBSCRIPTED_EXP(TYPENAME(ty), {subscript}, Type.ARRAY(ty, {Subscript.toDimension(sub)}));

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
          then if idx == 1 then Expression.BOOLEAN(false) else Expression.BOOLEAN(true);

        case Type.ENUMERATION()
          then Expression.ENUM_LITERAL(ty, Type.nthEnumLiteral(ty, idx), idx);
      end match;
    else
      subscriptedExp := SUBSCRIPTED_EXP(TYPENAME(ty), {index}, ty);
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
  algorithm
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

            el_count := listLength(expl);
            ty := if el_count > 0 then typeOf(listHead(expl)) else
                                       Type.subscript(ty, restSubscripts);
            ty := Type.liftArrayLeft(ty, Dimension.fromInteger(el_count));
            outExp := makeArray(ty, expl, literal);
          end if;
        then
          outExp;

      case Subscript.EXPANDED_SLICE()
        algorithm
          ARRAY(literal = literal) := exp;
          expl := list(applyIndexSubscriptArray(exp, i, restSubscripts) for i in sub.indices);

          el_count := listLength(expl);
          ty := if el_count > 0 then typeOf(listHead(expl)) else
                                     Type.subscript(typeOf(exp), restSubscripts);
          ty := Type.liftArrayLeft(ty, Dimension.fromInteger(el_count));
        then
          makeArray(ty, expl, literal);
    end match;
  end applySubscriptArray;

  function applyIndexSubscriptArray
    input Expression exp;
    input Subscript index;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  protected
    Expression index_exp = Subscript.toExp(index);
    list<Expression> expl;
  algorithm
    if isScalarLiteral(index_exp) then
      ARRAY(elements = expl) := exp;
      outExp := applySubscripts(restSubscripts, listGet(expl, toInteger(index_exp)));
    else
      outExp := makeSubscriptedExp(index :: restSubscripts, exp);
    end if;
  end applyIndexSubscriptArray;

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
          SUBSCRIPTED_EXP(exp, {subscript}, ty);

      case Subscript.WHOLE() then exp;

      case Subscript.EXPANDED_SLICE()
        algorithm
          expl := list(applyIndexSubscriptRange(exp, i) for i in sub.indices);
          RANGE(ty = ty) := exp;
        then
          makeArray(Type.liftArrayLeft(ty, Dimension.fromInteger(listLength(expl))), expl);

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
  algorithm
    Subscript.INDEX(index = index_exp) := index;

    if isScalarLiteral(index_exp) then
      RANGE(start = start_exp, step = step_exp, stop = stop_exp) := rangeExp;
      outExp := applyIndexSubscriptRange2(start_exp, step_exp, stop_exp, toInteger(index_exp));
    else
      RANGE(ty = ty) := rangeExp;
      outExp := SUBSCRIPTED_EXP(rangeExp, {index}, ty);
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
      case (Expression.INTEGER(), SOME(Expression.INTEGER(iidx)))
        then Expression.INTEGER(startExp.value + (index - 1) * iidx);

      case (Expression.INTEGER(), _)
        then Expression.INTEGER(startExp.value + index - 1);

      case (Expression.REAL(), SOME(Expression.REAL(ridx)))
        then Expression.REAL(startExp.value + (index - 1) * ridx);

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
          CALL(Call.TYPED_CALL(call.fn, ty, call.var, {arg}, call.attributes));

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
    Expression exp, iter_exp;
    list<tuple<InstNode, Expression>> iters;
    InstNode iter;
  algorithm
    Call.TYPED_ARRAY_CONSTRUCTOR(ty, var, exp, iters) := call;
    ((iter, iter_exp), iters) := List.splitLast(iters);
    iter_exp := applySubscript(index, iter_exp);
    subscriptedExp := replaceIterator(exp, iter, iter_exp);

    if not listEmpty(iters) then
      subscriptedExp := CALL(Call.TYPED_ARRAY_CONSTRUCTOR(Type.unliftArray(ty), var, subscriptedExp, iters));
    end if;
  end applyIndexSubscriptArrayConstructor;

  function applySubscriptIf
    input Subscript subscript;
    input Expression exp;
    input list<Subscript> restSubscripts;
    output Expression outExp;
  protected
    Expression cond, tb, fb;
  algorithm
    Expression.IF(cond, tb, fb) := exp;
    tb := applySubscript(subscript, tb, restSubscripts);
    fb := applySubscript(subscript, fb, restSubscripts);
    outExp := Expression.IF(cond, tb, fb);
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
  algorithm
    // If the expression is already a SUBSCRIPTED_EXP we need to concatenate the
    // old subscripts with the new. Otherwise we just create a new SUBSCRIPTED_EXP.
    (e, subs, ty) := match exp
      case SUBSCRIPTED_EXP() then (exp.exp,exp.subscripts, Expression.typeOf(exp.exp));
      else (exp, {}, Expression.typeOf(exp));
    end match;

    dim_count := Type.dimensionCount(ty);
    (subs, extra_subs) := Subscript.mergeList(subscripts, subs, dim_count);

    // Check that the expression has enough dimensions to be subscripted.
    if not listEmpty(extra_subs) then
      Error.assertion(false, getInstanceName() + ": too few dimensions in " +
        Expression.toString(exp) + " to apply subscripts " + Subscript.toStringList(subscripts), sourceInfo());
    end if;

    ty := Type.subscript(ty, subs);
    outExp := SUBSCRIPTED_EXP(e, subs, ty);
  end makeSubscriptedExp;

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
  algorithm
    exp := match exp
      local
        InstNode node;

      case CREF(cref = ComponentRef.CREF(node = node))
        then if InstNode.refEqual(iterator, node) then iteratorValue else exp;

      else exp;
    end match;
  end replaceIterator2;

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
      case BOOLEAN() then if exp.value then 1 else 0;
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
      case STRING() then "\"" + exp.value + "\"";
      case BOOLEAN() then boolString(exp.value);

      case ENUM_LITERAL(ty = t as Type.ENUMERATION())
        then Absyn.pathString(t.typePath) + "." + exp.name;

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
      case BOX() then "BOX(" + toString(exp.exp) + ")";
      case CAST() then "CAST(" + Type.toString(exp.ty) + ", " + toString(exp.exp) + ")";
      case SUBSCRIPTED_EXP() then toString(exp.exp) + Subscript.toStringList(exp.subscripts);
      case TUPLE_ELEMENT() then toString(exp.tupleExp) + "[" + intString(exp.index) + "]";
      case RECORD_ELEMENT() then toString(exp.recordExp) + "[field: " + exp.fieldName + "]";
      case MUTABLE() then toString(Mutable.access(exp.exp));
      case EMPTY() then "#EMPTY#";
      case PARTIAL_FUNCTION_APPLICATION()
        then "function " + ComponentRef.toString(exp.fn) + "(" + stringDelimitList(
          list(n + " = " + Expression.toString(a) threaded for a in exp.args, n in exp.argNames), ", ") + ")";

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
        Type ty;
        DAE.Operator daeOp;
        Boolean swap;
        DAE.Exp dae1, dae2;
        list<String> names;
        Function.Function fn;

      case INTEGER() then DAE.ICONST(exp.value);
      case REAL() then DAE.RCONST(exp.value);
      case STRING() then DAE.SCONST(exp.value);
      case BOOLEAN() then DAE.BCONST(exp.value);
      case ENUM_LITERAL(ty = ty as Type.ENUMERATION())
        then DAE.ENUM_LITERAL(Absyn.suffixPath(ty.typePath, exp.name), exp.index);

      case CLKCONST()
        then DAE.CLKCONST(ClockKind.toDAE(exp.clk));

      case CREF()
        then DAE.CREF(ComponentRef.toDAE(exp.cref), Type.toDAE(exp.ty));

      case TYPENAME()
        then toDAE(ExpandExp.expandTypename(exp.ty));

      case ARRAY()
        then DAE.ARRAY(Type.toDAE(exp.ty), Type.isScalarArray(exp.ty),
          list(toDAE(e) for e in exp.elements));

      case RECORD(ty = Type.COMPLEX(complexTy = ComplexType.RECORD(fieldNames = names)))
        then DAE.RECORD(exp.path, list(toDAE(e) for e in exp.elements), names, Type.toDAE(exp.ty));

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

      case INTEGER() then Values.INTEGER(exp.value);
      case REAL() then Values.REAL(exp.value);
      case STRING() then Values.STRING(exp.value);
      case BOOLEAN() then Values.BOOL(exp.value);
      case ENUM_LITERAL(ty = ty as Type.ENUMERATION())
        then Values.ENUM_LITERAL(Absyn.suffixPath(ty.typePath, exp.name), exp.index);

      case ARRAY()
        algorithm
          vals := list(toDAEValue(e) for e in exp.elements);
        then
          ValuesUtil.makeArray(vals);

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unhandled expression " + toString(exp), sourceInfo());
        then
          fail();
    end match;
  end toDAEValue;

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

      case CLKCONST(ClockKind.INTEGER_CLOCK(e1, e2))
        algorithm
          e3 := map(e1, func);
          e4 := map(e2, func);
       then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.INTEGER_CLOCK(e3, e4));

      case CLKCONST(ClockKind.REAL_CLOCK(e1))
        algorithm
          e2 := map(e1, func);
       then
          if referenceEq(e1, e2)
          then exp
          else CLKCONST(ClockKind.REAL_CLOCK(e2));

      case CLKCONST(ClockKind.BOOLEAN_CLOCK(e1, e2))
        algorithm
          e3 := map(e1, func);
          e4 := map(e2, func);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.BOOLEAN_CLOCK(e3, e4));

      case CLKCONST(ClockKind.SOLVER_CLOCK(e1, e2))
        algorithm
          e3 := map(e1, func);
          e4 := map(e2, func);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.SOLVER_CLOCK(e3, e4));

      case CREF() then CREF(exp.ty, mapCref(exp.cref, func));
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
        then SUBSCRIPTED_EXP(map(exp.exp, func), list(Subscript.mapExp(s, func) for s in exp.subscripts), exp.ty);

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

      case BOX()
        algorithm
          e1 := map(exp.exp, func);
        then
          if referenceEq(exp.exp, e1) then exp else BOX(e1);

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
        list<tuple<InstNode, Expression>> iters;

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

      case Call.UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := map(call.exp, func);
          iters := mapCallIterators(call.iters, func);
        then
          Call.UNTYPED_ARRAY_CONSTRUCTOR(e, iters);

      case Call.TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := map(call.exp, func);
          iters := mapCallIterators(call.iters, func);
        then
          Call.TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, e, iters);

      case Call.UNTYPED_REDUCTION()
        algorithm
          e := map(call.exp, func);
          iters := mapCallIterators(call.iters, func);
        then
          Call.UNTYPED_REDUCTION(call.ref, e, iters);

      case Call.TYPED_REDUCTION()
        algorithm
          e := map(call.exp, func);
          iters := mapCallIterators(call.iters, func);
        then
          Call.TYPED_REDUCTION(call.fn, call.ty, call.var, e, iters);

    end match;
  end mapCall;

  function mapCallIterators
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
    output list<tuple<InstNode, Expression>> outIters = {};

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      new_exp := map(exp, func);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapCallIterators;

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

      case ComponentRef.CREF(origin = Origin.CREF)
        algorithm
          subs := list(Subscript.mapExp(s, func) for s in cref.subscripts);
          rest := mapCref(cref.restCref, func);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapCref;

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

      case CLKCONST(ClockKind.INTEGER_CLOCK(e1, e2))
        algorithm
          e3 := func(e1);
          e4 := func(e2);
       then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.INTEGER_CLOCK(e3, e4));

      case CLKCONST(ClockKind.REAL_CLOCK(e1))
        algorithm
          e2 := func(e1);
       then
          if referenceEq(e1, e2)
          then exp
          else CLKCONST(ClockKind.REAL_CLOCK(e2));

      case CLKCONST(ClockKind.BOOLEAN_CLOCK(e1, e2))
        algorithm
          e3 := func(e1);
          e4 := func(e2);
       then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.BOOLEAN_CLOCK(e3, e4));

      case CLKCONST(ClockKind.SOLVER_CLOCK(e1, e2))
        algorithm
          e3 := func(e1);
          e4 := func(e2);
       then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.SOLVER_CLOCK(e3, e4));

      case CREF() then CREF(exp.ty, mapCrefShallow(exp.cref, func));
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
        then SUBSCRIPTED_EXP(func(exp.exp), list(Subscript.mapShallowExp(e, func) for e in exp.subscripts), exp.ty);

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

      case BOX()
        algorithm
          e1 := func(exp.exp);
        then
          if referenceEq(exp.exp, e1) then exp else BOX(e1);

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

      case ComponentRef.CREF(origin = Origin.CREF)
        algorithm
          subs := list(Subscript.mapShallowExp(s, func) for s in cref.subscripts);
          rest := mapCref(cref.restCref, func);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapCrefShallow;

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

      case Call.UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := func(call.exp);
        then
          Call.UNTYPED_ARRAY_CONSTRUCTOR(e, call.iters);

      case Call.TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          e := func(call.exp);
        then
          Call.TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, e, call.iters);

      case Call.UNTYPED_REDUCTION()
        algorithm
          e := func(call.exp);
        then
          Call.UNTYPED_REDUCTION(call.ref, e, call.iters);

      case Call.TYPED_REDUCTION()
        algorithm
          e := func(call.exp);
        then
          Call.TYPED_REDUCTION(call.fn, call.ty, call.var, e, call.iters);
    end match;
  end mapCallShallow;

  function mapCallShallowIterators
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
    output list<tuple<InstNode, Expression>> outIters = {};

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      new_exp := func(exp);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapCallShallowIterators;

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
        Expression e, e1, e2;

      case CLKCONST(ClockKind.INTEGER_CLOCK(e1, e2))
        algorithm
          result := fold(e1, func, arg);
          result := fold(e2, func, result);
       then
          result;

      case CLKCONST(ClockKind.REAL_CLOCK(e1))
        algorithm
          result := fold(e1, func, arg);
       then
          result;

      case CLKCONST(ClockKind.BOOLEAN_CLOCK(e1, e2))
        algorithm
          result := fold(e1, func, arg);
          result := fold(e2, func, result);
       then
          result;

      case CLKCONST(ClockKind.SOLVER_CLOCK(e1, e2))
        algorithm
          result := fold(e1, func, arg);
          result := fold(e2, func, result);
       then
          result;

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
          List.fold(exp.subscripts, function Subscript.foldExp(func = func), result);

      case TUPLE_ELEMENT() then fold(exp.tupleExp, func, arg);
      case RECORD_ELEMENT() then fold(exp.recordExp, func, arg);
      case BOX() then fold(exp.exp, func, arg);
      case MUTABLE() then fold(Mutable.access(exp.exp), func, arg);
      case PARTIAL_FUNCTION_APPLICATION() then foldList(exp.args, func, arg);
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

      case Call.UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          foldArg := fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := fold(Util.tuple22(i), func, foldArg);
          end for;
        then
          ();

      case Call.TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          foldArg := fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := fold(Util.tuple22(i), func, foldArg);
          end for;
        then
          ();

      case Call.UNTYPED_REDUCTION()
        algorithm
          foldArg := fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := fold(Util.tuple22(i), func, foldArg);
          end for;
        then
          ();

      case Call.TYPED_REDUCTION()
        algorithm
          foldArg := fold(call.exp, func, foldArg);

          for i in call.iters loop
            foldArg := fold(Util.tuple22(i), func, foldArg);
          end for;
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
      case ComponentRef.CREF(origin = Origin.CREF)
        algorithm
          arg := List.fold(cref.subscripts, function Subscript.foldExp(func = func), arg);
          arg := foldCref(cref.restCref, func, arg);
        then
          ();

      else ();
    end match;
  end foldCref;

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

      case CLKCONST(ClockKind.INTEGER_CLOCK(e1, e2))
        algorithm
          apply(e1, func);
          apply(e2, func);
       then
          ();

      case CLKCONST(ClockKind.REAL_CLOCK(e1))
        algorithm
          apply(e1, func);
       then
         ();

      case CLKCONST(ClockKind.BOOLEAN_CLOCK(e1, e2))
        algorithm
          apply(e1, func);
          apply(e2, func);
       then
          ();

      case CLKCONST(ClockKind.SOLVER_CLOCK(e1, e2))
        algorithm
          apply(e1, func);
          apply(e2, func);
       then
          ();

      case CREF() algorithm applyCref(exp.cref, func); then ();
      case ARRAY() algorithm applyList(exp.elements, func); then ();

      case MATRIX()
        algorithm
          for row in exp.elements loop
            applyList(row, func);
          end for;
        then
          ();

      case RANGE(step = SOME(e))
        algorithm
          apply(exp.start, func);
          apply(e, func);
          apply(exp.stop, func);
        then
          ();

      case RANGE()
        algorithm
          apply(exp.start, func);
          apply(exp.stop, func);
        then
          ();

      case TUPLE() algorithm applyList(exp.elements, func); then ();
      case RECORD() algorithm applyList(exp.elements, func); then ();
      case CALL() algorithm applyCall(exp.call, func); then ();

      case SIZE(dimIndex = SOME(e))
        algorithm
          apply(exp.exp, func);
          apply(e, func);
        then
          ();

      case SIZE() algorithm apply(exp.exp, func); then ();

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
      case BOX() algorithm apply(exp.exp, func); then ();
      case MUTABLE() algorithm apply(Mutable.access(exp.exp), func); then ();
      case PARTIAL_FUNCTION_APPLICATION() algorithm applyList(exp.args, func); then ();
      else ();
    end match;

    func(exp);
  end apply;

  function applyCall
    input Call call;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match call
      local
        Expression e;

      case Call.UNTYPED_CALL()
        algorithm
          applyList(call.arguments, func);

          for arg in call.named_args loop
            (_, e) := arg;
            apply(e, func);
          end for;
        then
          ();

      case Call.ARG_TYPED_CALL()
        algorithm
          for arg in call.arguments loop
            (e, _, _) := arg;
            apply(e, func);
          end for;

          for arg in call.named_args loop
            (_, e, _, _) := arg;
            apply(e, func);
          end for;
        then
          ();

      case Call.TYPED_CALL()
        algorithm
          applyList(call.arguments, func);
        then
          ();

      case Call.UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          apply(call.exp, func);

          for i in call.iters loop
            apply(Util.tuple22(i), func);
          end for;
        then
          ();

      case Call.TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          apply(call.exp, func);

          for i in call.iters loop
            apply(Util.tuple22(i), func);
          end for;
        then
          ();

      case Call.UNTYPED_REDUCTION()
        algorithm
          apply(call.exp, func);

          for i in call.iters loop
            apply(Util.tuple22(i), func);
          end for;
        then
          ();

      case Call.TYPED_REDUCTION()
        algorithm
          apply(call.exp, func);

          for i in call.iters loop
            apply(Util.tuple22(i), func);
          end for;
        then
          ();
    end match;
  end applyCall;

  function applyCref
    input ComponentRef cref;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match cref
      case ComponentRef.CREF(origin = Origin.CREF)
        algorithm
          for s in cref.subscripts loop
            applyCrefSubscript(s, func);
          end for;

          applyCref(cref.restCref, func);
        then
          ();

      else ();
    end match;
  end applyCref;

  function applyCrefSubscript
    input Subscript subscript;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    () := match subscript
      case Subscript.UNTYPED() algorithm apply(subscript.exp, func); then ();
      case Subscript.INDEX()   algorithm apply(subscript.index, func); then ();
      case Subscript.SLICE()   algorithm apply(subscript.slice, func); then ();
      case Subscript.WHOLE()   then ();
    end match;
  end applyCrefSubscript;

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

      case CLKCONST(ClockKind.INTEGER_CLOCK(e1, e2))
        algorithm
          (e3, arg) := mapFold(e1, func, arg);
          (e4, arg) := mapFold(e2, func, arg);
       then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.INTEGER_CLOCK(e3, e4));

      case CLKCONST(ClockKind.REAL_CLOCK(e1))
        algorithm
          (e2, arg) := mapFold(e1, func, arg);
       then
          if referenceEq(e1, e2)
          then exp
          else CLKCONST(ClockKind.REAL_CLOCK(e2));

      case CLKCONST(ClockKind.BOOLEAN_CLOCK(e1, e2))
        algorithm
          (e3, arg) := mapFold(e1, func, arg);
          (e4, arg) := mapFold(e2, func, arg);
       then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.BOOLEAN_CLOCK(e3, e4));

      case CLKCONST(ClockKind.SOLVER_CLOCK(e1, e2))
        algorithm
          (e3, arg) := mapFold(e1, func, arg);
          (e4, arg) := mapFold(e2, func, arg);
       then
          if referenceEq(e1, e3) and referenceEq(e2, e4)
          then exp
          else CLKCONST(ClockKind.SOLVER_CLOCK(e3, e4));

      case CREF()
        algorithm
          (cr, arg) := mapFoldCref(exp.cref, func, arg);
       then
          if referenceEq(exp.cref, cr) then exp else CREF(exp.ty, cr);

      case ARRAY()
        algorithm
          (expl, arg) := List.map1Fold(exp.elements, mapFold, func, arg);
        then
          ARRAY(exp.ty, expl, exp.literal);

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
          (subs, arg) := List.mapFold(exp.subscripts, function Subscript.mapFoldExp(func = func), arg);
        then
          SUBSCRIPTED_EXP(e1, subs, exp.ty);

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

      case Call.UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.UNTYPED_ARRAY_CONSTRUCTOR(e, call.iters);

      case Call.TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, e, call.iters);

      case Call.UNTYPED_REDUCTION()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.UNTYPED_REDUCTION(call.ref, e, call.iters);

      case Call.TYPED_REDUCTION()
        algorithm
          (e, foldArg) := mapFold(call.exp, func, foldArg);
        then
          Call.TYPED_REDUCTION(call.fn, call.ty, call.var, e, call.iters);
    end match;
  end mapFoldCall;

  function mapFoldCallIterators<ArgT>
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
          output list<tuple<InstNode, Expression>> outIters = {};
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      (new_exp, arg) := mapFold(exp, func, arg);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapFoldCallIterators;

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

      case ComponentRef.CREF(origin = Origin.CREF)
        algorithm
          (subs, arg) := List.map1Fold(cref.subscripts, Subscript.mapFoldExp, func, arg);
          (rest, arg) := mapFoldCref(cref.restCref, func, arg);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapFoldCref;

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

      case CLKCONST()
        algorithm
          (outExp, arg) := mapFoldClockShallow(exp, func, arg);
        then
          outExp;

      case CREF()
        algorithm
          (cr, arg) := mapFoldCrefShallow(exp.cref, func, arg);
       then
          if referenceEq(exp.cref, cr) then exp else CREF(exp.ty, cr);

      case ARRAY()
        algorithm
          (expl, arg) := List.mapFold(exp.elements, func, arg);
        then
          ARRAY(exp.ty, expl, exp.literal);

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
          (call, arg) := mapFoldCallShallow(exp.call, func, arg);
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
             referenceEq(exp.falseBranch, e3) then exp else IF(e1, e2, e3);

      case CAST()
        algorithm
          (e1, arg) := func(exp.exp, arg);
        then
          if referenceEq(exp.exp, e1) then exp else CAST(exp.ty, e1);

      case UNBOX()
        algorithm
          (e1, arg) := func(exp.exp, arg);
        then
          if referenceEq(exp.exp, e1) then exp else UNBOX(e1, exp.ty);

      case SUBSCRIPTED_EXP()
        algorithm
          (e1, arg) := func(exp.exp, arg);
          (subs, arg) := List.mapFold(exp.subscripts, function Subscript.mapFoldExpShallow(func = func), arg);
        then
          SUBSCRIPTED_EXP(e1, subs, exp.ty);

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

  function mapFoldClockShallow<ArgT>
    input Expression clockExp;
    input MapFunc func;
          output Expression outExp;
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    ClockKind clk;
    Expression e1, e2, e3, e4;
  algorithm
    CLKCONST(clk = clk) := clockExp;

    outExp := match clk
      case ClockKind.INTEGER_CLOCK(e1, e2)
        algorithm
          (e3, arg) := func(e1, arg);
          (e4, arg) := func(e2, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then
            clockExp else CLKCONST(ClockKind.INTEGER_CLOCK(e3, e4));

      case ClockKind.REAL_CLOCK(e1)
        algorithm
          (e2, arg) := func(e1, arg);
        then
          if referenceEq(e1, e2) then
            clockExp else CLKCONST(ClockKind.REAL_CLOCK(e2));

      case ClockKind.BOOLEAN_CLOCK(e1, e2)
        algorithm
          (e3, arg) := func(e1, arg);
          (e4, arg) := func(e2, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then
            clockExp else CLKCONST(ClockKind.BOOLEAN_CLOCK(e3, e4));

      case ClockKind.SOLVER_CLOCK(e1, e2)
        algorithm
          (e3, arg) := func(e1, arg);
          (e4, arg) := func(e2, arg);
        then
          if referenceEq(e1, e3) and referenceEq(e2, e4) then
            clockExp else CLKCONST(ClockKind.SOLVER_CLOCK(e3, e4));

      else clockExp;
    end match;
  end mapFoldClockShallow;

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

  function mapFoldCallShallow<ArgT>
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
        list<tuple<InstNode, Expression>> iters;

      case Call.UNTYPED_CALL()
        algorithm
          (args, foldArg) := List.mapFold(call.arguments, func, foldArg);
          nargs := {};

          for arg in call.named_args loop
            (s, e) := arg;
            (e, foldArg) := func(e, foldArg);
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
            (e, foldArg) := func(e, foldArg);
            targs := (e, t, v) :: targs;
          end for;

          for arg in call.named_args loop
            (s, e, t, v) := arg;
            (e, foldArg) := func(e, foldArg);
            tnargs := (s, e, t, v) :: tnargs;
          end for;
        then
          Call.ARG_TYPED_CALL(call.ref, listReverse(targs), listReverse(tnargs), call.call_scope);

      case Call.TYPED_CALL()
        algorithm
          (args, foldArg) := List.mapFold(call.arguments, func, foldArg);
        then
          Call.TYPED_CALL(call.fn, call.ty, call.var, args, call.attributes);

      case Call.UNTYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldCallIteratorsShallow(call.iters, func, foldArg);
        then
          Call.UNTYPED_ARRAY_CONSTRUCTOR(e, iters);

      case Call.TYPED_ARRAY_CONSTRUCTOR()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldCallIteratorsShallow(call.iters, func, foldArg);
        then
          Call.TYPED_ARRAY_CONSTRUCTOR(call.ty, call.var, e, iters);

      case Call.UNTYPED_REDUCTION()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldCallIteratorsShallow(call.iters, func, foldArg);
        then
          Call.UNTYPED_REDUCTION(call.ref, e, iters);

      case Call.TYPED_REDUCTION()
        algorithm
          (e, foldArg) := func(call.exp, foldArg);
          iters := mapFoldCallIteratorsShallow(call.iters, func, foldArg);
        then
          Call.TYPED_REDUCTION(call.fn, call.ty, call.var, e, iters);

    end match;
  end mapFoldCallShallow;

  function mapFoldCallIteratorsShallow<ArgT>
    input list<tuple<InstNode, Expression>> iters;
    input MapFunc func;
          output list<tuple<InstNode, Expression>> outIters = {};
    input output ArgT arg;

    partial function MapFunc
      input output Expression e;
      input output ArgT arg;
    end MapFunc;
  protected
    InstNode node;
    Expression exp, new_exp;
  algorithm
    for i in iters loop
      (node, exp) := i;
      (new_exp, arg) := func(exp, arg);
      outIters := (if referenceEq(new_exp, exp) then i else (node, new_exp)) :: outIters;
    end for;

    outIters := listReverseInPlace(outIters);
  end mapFoldCallIteratorsShallow;

  function mapFoldCrefShallow<ArgT>
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

      case ComponentRef.CREF(origin = Origin.CREF)
        algorithm
          (subs, arg) := List.map1Fold(cref.subscripts, Subscript.mapFoldExpShallow, func, arg);
          (rest, arg) := mapFoldCrefShallow(cref.restCref, func, arg);
        then
          ComponentRef.CREF(cref.node, subs, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapFoldCrefShallow;

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
        then contains(exp.exp, func) or Subscript.listContainsExp(exp.subscripts, func);

      case TUPLE_ELEMENT() then contains(exp.tupleExp, func);
      case RECORD_ELEMENT() then contains(exp.recordExp, func);
      case PARTIAL_FUNCTION_APPLICATION() then listContains(exp.args, func);
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
        then Subscript.listContainsExp(cref.subscripts, func) or
             crefContains(cref.restCref, func);

      else false;
    end match;
  end crefContains;

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
      case Call.UNTYPED_ARRAY_CONSTRUCTOR() then contains(call.exp, func);
      case Call.TYPED_ARRAY_CONSTRUCTOR() then contains(call.exp, func);
      case Call.UNTYPED_REDUCTION() then contains(call.exp, func);
      case Call.TYPED_REDUCTION() then contains(call.exp, func);
    end match;
  end callContains;

  function containsShallow
    input Expression exp;
    input ContainsPred func;
    output Boolean res;
  algorithm
    res := match exp
      case CREF() then crefContainsShallow(exp.cref, func);
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
      case CALL() then callContainsShallow(exp.call, func);

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
      case UNBOX() then func(exp.exp);

      case SUBSCRIPTED_EXP()
        then func(exp.exp) or Subscript.listContainsExpShallow(exp.subscripts, func);

      case TUPLE_ELEMENT() then func(exp.tupleExp);
      case RECORD_ELEMENT() then func(exp.recordExp);
      case PARTIAL_FUNCTION_APPLICATION() then listContains(exp.args, func);
      case BOX() then func(exp.exp);
      else false;
    end match;
  end containsShallow;

  function crefContainsShallow
    input ComponentRef cref;
    input ContainsPred func;
    output Boolean res;
  algorithm
    res := match cref
      case ComponentRef.CREF()
        then Subscript.listContainsExpShallow(cref.subscripts, func) or
             crefContainsShallow(cref.restCref, func);

      else false;
    end match;
  end crefContainsShallow;

  function listContainsShallow
    input list<Expression> expl;
    input ContainsPred func;
    output Boolean res;
  algorithm
    for e in expl loop
      if func(e) then
        res := true;
        return;
      end if;
    end for;

    res := false;
  end listContainsShallow;

  function callContainsShallow
    input Call call;
    input ContainsPred func;
    output Boolean res;
  algorithm
    res := match call
      local
        Expression e;

      case Call.UNTYPED_CALL()
        algorithm
          res := listContainsShallow(call.arguments, func);

          if not res then
            for arg in call.named_args loop
              (_, e) := arg;

              if func(e) then
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

            if func(e) then
              res := true;
              return;
            end if;
          end for;

          for arg in call.named_args loop
            (_, e, _, _) := arg;

            if func(e) then
              res := true;
              return;
            end if;
          end for;
        then
          false;

      case Call.TYPED_CALL() then listContainsShallow(call.arguments, func);
      case Call.UNTYPED_ARRAY_CONSTRUCTOR() then func(call.exp);
      case Call.TYPED_ARRAY_CONSTRUCTOR() then func(call.exp);
      case Call.UNTYPED_REDUCTION() then func(call.exp);
      case Call.TYPED_REDUCTION() then func(call.exp);
    end match;
  end callContainsShallow;

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

  function containsIterator
    input Expression exp;
    input ExpOrigin.Type origin;
    output Boolean iter;
  algorithm
    if ExpOrigin.flagSet(origin, ExpOrigin.FOR) then
      iter := contains(exp, isIterator);
    else
      iter := false;
    end if;
  end containsIterator;

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

  function isPositive
    input Expression exp;
    output Boolean positive;
  algorithm
    positive := match exp
      case INTEGER() then exp.value > 0;
      case REAL() then exp.value > 0;
      case BOOLEAN() then true;
      case ENUM_LITERAL() then true;
      case CAST() then isPositive(exp.exp);
      case UNARY() then not isPositive(exp.exp);
    end match;
  end isPositive;

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
      case ARRAY() then List.all(exp.elements, isLiteral);
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
      exp := Expression.makeArray(arr_ty, expl, literal = isLiteral(exp));
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
        then ARRAY(ty,
                   List.fill(makeZero(Type.unliftArray(ty)),
                             Dimension.size(listHead(ty.dimensions))),
                   literal = true);
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
                       List.fill(makeMaxValue(Type.unliftArray(ty)),
                                 Dimension.size(listHead(ty.dimensions))),
                       literal = true);
    end match;
  end makeMinValue;

  function box
    input Expression exp;
    output Expression boxedExp;
  algorithm
    boxedExp := match exp
      case Expression.BOX() then exp;
      else Expression.BOX(exp);
    end match;
  end box;

  function unbox
    input Expression boxedExp;
    output Expression exp;
  algorithm
    exp := match boxedExp
      local
        Type ty;

      case Expression.BOX() then boxedExp.exp;

      else
        algorithm
          ty := Expression.typeOf(boxedExp);
        then
          if Type.isBoxed(ty) then Expression.UNBOX(boxedExp, Type.unbox(ty)) else boxedExp;

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
              NFBuiltinFuncs.PROMOTE, {exp, INTEGER(dims)}, variability(exp), listHead(types)));
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
      case CLKCONST(_) then Variability.DISCRETE;
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
        then Prefixes.variabilityMax(variability(exp.exp), Subscript.variabilityList(exp.subscripts));
      case TUPLE_ELEMENT() then variability(exp.tupleExp);
      case RECORD_ELEMENT() then variability(exp.recordExp);
      case BOX() then variability(exp.exp);
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

  function isEmpty
    input Expression exp;
    output Boolean empty;
  algorithm
    empty := match exp
      case EMPTY() then true;
      else false;
    end match;
  end isEmpty;

  function lookupRecordField
    input String name;
    input Expression exp;
    output Expression fieldExp;
  algorithm
    fieldExp := match exp
      local
        InstNode node;
        Integer index;
        ClassTree cls_tree;
        ComponentRef cref;
        Type ty;

      case RECORD(ty = Type.COMPLEX(cls = node))
        algorithm
          cls_tree := Class.classTree(InstNode.getClass(node));
          index := ClassTree.lookupComponentIndex(name, cls_tree);
        then
          listGet(exp.elements, index);

      case CREF(ty = Type.COMPLEX(cls = node))
        algorithm
          cls_tree := Class.classTree(InstNode.getClass(node));
          (node, false) := ClassTree.lookupElement(name, cls_tree);
          ty := InstNode.getType(node);
          cref := ComponentRef.prefixCref(node, ty, {}, exp.cref);
          ty := Type.liftArrayLeftList(ty, Type.arrayDims(exp.ty));
        then
          CREF(ty, cref);

    end match;
  end lookupRecordField;

  function enumIndexExp
    input Expression enumExp;
    output Expression indexExp;
  algorithm
    indexExp := match enumExp
      case ENUM_LITERAL() then INTEGER(enumExp.index);
      else CALL(Call.makeTypedCall(
        NFBuiltinFuncs.INTEGER_ENUM, {enumExp}, variability(enumExp)));
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

      case Expression.TUPLE() then listGet(exp.elements, index);

      case Expression.ARRAY()
        algorithm
          ety := Type.unliftArray(ty);
          exp.elements := list(tupleElement(e, ety, index) for e in exp.elements);
        then
          exp;

      else Expression.TUPLE_ELEMENT(exp, index, ty);
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
        Type ty;
        Integer index;
        list<Expression> expl;

      case RECORD(ty = Type.COMPLEX(cls = node))
        algorithm
          cls := InstNode.getClass(node);
          index := Class.lookupComponentIndex(elementName, cls);
        then
          listGet(recordExp.elements, index);

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
          ty := Type.liftArrayLeft(Expression.typeOf(listHead(expl)),
                                   Dimension.fromInteger(listLength(expl)));
        then
          Expression.makeArray(ty, expl, recordExp.literal);

      else
        algorithm
          ty := typeOf(recordExp);
          Type.COMPLEX(cls = node) := Type.arrayElementType(ty);
          cls := InstNode.getClass(node);
          index := Class.lookupComponentIndex(elementName, cls);
          ty := Type.liftArrayRightList(
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

      case RECORD() then listGet(recordExp.elements, index);

      case ARRAY(elements = {}, ty = Type.ARRAY(elementType = Type.COMPLEX(cls = node)))
        then makeEmptyArray(InstNode.getType(Class.nthComponent(index, InstNode.getClass(node))));

      case ARRAY()
        algorithm
          expl := list(nthRecordElement(index, e) for e in recordExp.elements);
        then
          makeArray(Type.setArrayElementType(recordExp.ty, Expression.typeOf(listHead(expl))), expl);

      else
        algorithm
          Type.COMPLEX(cls = node) := typeOf(recordExp);
          node := Class.nthComponent(index, InstNode.getClass(node));
        then
          RECORD_ELEMENT(recordExp, index, InstNode.name(node), InstNode.getType(node));

    end match;
  end nthRecordElement;


  function splitRecordCref
    input Expression exp;
    output Expression outExp;
  algorithm
    outExp := ExpandExp.expand(exp);

    outExp := match outExp
      local
        InstNode cls;
        array<InstNode> comps;
        ComponentRef cr, field_cr;
        Type ty;
        list<Expression> fields;

      case CREF(ty = Type.COMPLEX(cls = cls), cref = cr)
        algorithm
          comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(cls)));
          fields := {};

          for i in arrayLength(comps):-1:1 loop
            ty := InstNode.getType(comps[i]);
            field_cr := ComponentRef.prefixCref(comps[i], ty, {}, cr);
            fields := CREF(ty, field_cr) :: fields;
          end for;
        then
          RECORD(InstNode.scopePath(cls), outExp.ty, fields);

      case ARRAY()
        algorithm
          outExp.elements := list(splitRecordCref(e) for e in outExp.elements);
        then
          outExp;

      else exp;
    end match;
  end splitRecordCref;

  function retype
    input output Expression exp;
  algorithm
    () := match exp
      local
        list<Dimension> dims;

      case RANGE()
        algorithm
          exp.ty := TypeCheck.getRangeType(exp.start, exp.step, exp.stop,
            typeOf(exp.start), Absyn.dummyInfo);
        then
          ();

      case CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR())
        algorithm
          exp.call := Call.retype(exp.call);
        then
          ();

      else ();
    end match;
  end retype;

annotation(__OpenModelica_Interface="frontend");
end NFExpression;
