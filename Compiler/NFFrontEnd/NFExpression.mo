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

encapsulated package NFExpression

import DAE;
import NFInstNode.InstNode;
import NFPrefix.Prefix;
import Operator = NFOperator;
import Subscript = NFSubscript;
import Type = NFType;

protected
import Util;
import Absyn;
import List;

public
uniontype CallAttributes
  record CALL_ATTR
    Type ty "The type of the return value, if several return values this is undefined";
    Boolean tuple_ "tuple" ;
    Boolean builtin "builtin Function call" ;
    Boolean isImpure "if the function has prefix *impure* is true, else false";
    Boolean isFunctionPointerCall;
    DAE.InlineType inlineType;
    DAE.TailCall tailCall "Input variables of the function if the call is tail-recursive";
  end CALL_ATTR;
end CallAttributes;

public constant CallAttributes callAttrBuiltinBool = CALL_ATTR(Type.BOOLEAN(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinInteger = CALL_ATTR(Type.INTEGER(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinReal = CALL_ATTR(Type.REAL(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinString = CALL_ATTR(Type.STRING(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinOther = CALL_ATTR(Type.UNKNOWN(),false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureBool = CALL_ATTR(Type.BOOLEAN(),false,true,true,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureInteger = CALL_ATTR(Type.INTEGER(),false,true,true,false,DAE.NO_INLINE(),DAE.NO_TAIL());
public constant CallAttributes callAttrBuiltinImpureReal = CALL_ATTR(Type.REAL(),false,true,true,false,DAE.NO_INLINE(),DAE.NO_TAIL());

uniontype Expression
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

  record ENUM
    Absyn.Path name;
    Integer index;
  end ENUM;

  record CREF
    InstNode component;
    Prefix prefix;
  end CREF;

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

  record CALL
    Absyn.Path path;
    list<Expression> arguments;
    CallAttributes attr;
  end CALL;

  record SIZE
    Expression exp;
    Option<Expression> dimIndex;
  end SIZE;

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
        InstNode c;
        Type ty;
        list<Expression> expl;
        Expression e1, e2, e3;
        Option<Expression> oe;
        Absyn.Path p;
        Operator op;

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
          CREF(component = c) := exp2;
          b := referenceEq(InstNode.component(c), InstNode.component(exp1.component));
          // TODO: Check prefix too.
        then
          if b then 0 else 1;

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

      case CALL()
        algorithm
          CALL(path = p, arguments = expl) := exp2;
          comp := Absyn.pathCompare(exp1.path, p);
        then
          if comp == 0 then compareList(exp1.arguments, expl) else comp;

      case SIZE()
        algorithm
          SIZE(exp = e1, dimIndex = oe) := exp2;
          comp := compareOpt(exp1.dimIndex, oe);
        then
          if comp == 0 then compare(exp1.exp, e1) else comp;

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
      case CAST(ty, _)
        algorithm
          ty := if listMember(ty, {Type.INTEGER(), Type.REAL(), Type.STRING(), Type.BOOLEAN()}) then ty else Type.UNKNOWN();
        then ty;
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

      case (_, Type.REAL())
        then
          CAST(Type.REAL(), exp);

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
        Prefix pre;

      case ARRAY() then listGet(array.elements, index);

      case CREF(prefix = pre)
        algorithm
          pre := Prefix.addSubscript(Subscript.INDEX(INTEGER(index)), pre);
        then
          CREF(array.component, pre);

    end match;
  end arrayElement;

  function toInteger
    input Expression exp;
    output Integer i;
  algorithm
    i := match exp
      case INTEGER() then exp.value;
      case BOOLEAN() then if exp.value then 1 else 0;
      case ENUM() then exp.index;
    end match;
  end toInteger;

  function toString
    input Expression exp;
    output String str;
  protected
    Expression e;
    Type t;
  algorithm
    str := match exp
      case INTEGER() then String(exp.value);
      case REAL() then String(exp.value);
      case STRING() then exp.value;
      case BOOLEAN() then String(exp.value);

      case ENUM() then Absyn.pathString(exp.name);
      case CREF() then Prefix.toString(exp.prefix);
      case ARRAY() then "{" + stringDelimitList(List.map(exp.elements, toString), ", ") + "}";

      case RANGE() then toString(exp.start) +
                        (
                        if isSome(exp.step)
                        then ":" + toString(Util.getOption(exp.step))
                        else ""
                        ) + ":" + toString(exp.stop);
      case CALL() then Absyn.pathString(exp.path) + "(" + stringDelimitList(List.map(exp.arguments, toString), ", ") + ")";
      case SIZE() then "size(" + toString(exp.exp) +
                        (
                        if isSome(exp.dimIndex)
                        then ", " + toString(Util.getOption(exp.dimIndex))
                        else ""
                        ) + ")";
      case BINARY() then "(" + toString(exp.exp1) + Operator.symbol(exp.operator) + toString(exp.exp2) + ")";
      case UNARY() then "(" + Operator.symbol(exp.operator) + " " + toString(exp.exp) + ")";
      case LBINARY() then "(" + toString(exp.exp1) + Operator.symbol(exp.operator) + toString(exp.exp2) + ")";
      case LUNARY() then "(" + Operator.symbol(exp.operator) + " " + toString(exp.exp) + ")";

      case RELATION() then "(" + toString(exp.exp1) + Operator.symbol(exp.operator) + toString(exp.exp2) + ")";
      case IF() then "if" + toString(exp.condition) + " then " + toString(exp.trueBranch) + " else " + toString(exp.falseBranch);

      case UNBOX() then "UNBOX(" + toString(exp.exp) + ")";

      case CAST() then "CAST(" + Type.toString(exp.ty) + ", " + toString(exp.exp) + ")";


      else "NFExpression.toString: IMPLEMENT ME";
    end match;
  end toString;

  function toDAE
    input Expression exp;
    output DAE.Exp dexp;
  algorithm
    dexp := match exp
      case INTEGER() then DAE.ICONST(exp.value);
      case REAL() then DAE.RCONST(exp.value);
      case STRING() then DAE.SCONST(exp.value);
      case BOOLEAN() then DAE.BCONST(exp.value);
      case ENUM() then DAE.ENUM_LITERAL(exp.name, exp.index);

      case CREF()
        then DAE.CREF(Prefix.toCref(exp.prefix), DAE.T_UNKNOWN_DEFAULT);

      case ARRAY()
        then DAE.ARRAY(Type.toDAE(exp.ty), Type.isScalarArray(exp.ty),
          list(toDAE(e) for e in exp.elements));

      case RANGE()
        then DAE.RANGE(
               Type.toDAE(exp.ty),
               toDAE(exp.start),
               if isSome(exp.step)
               then SOME(toDAE(Util.getOption(exp.step)))
               else NONE(),
               toDAE(exp.stop));

      case CALL()
        then DAE.CALL(exp.path, List.map(exp.arguments, toDAE), toDAECallAtributes(exp.attr));

      case SIZE()
        then DAE.SIZE(toDAE(exp.exp),
               if isSome(exp.dimIndex)
               then SOME(toDAE(Util.getOption(exp.dimIndex)))
               else NONE());

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
          assert(false, getInstanceName() + " got unknown expression");
        then
          fail();

    end match;
  end toDAE;

  function toDAECallAtributes
    input CallAttributes attr;
    output DAE.CallAttributes fattr;
  protected
    Type ty "The type of the return value, if several return values this is undefined";
    Boolean tuple_ "tuple";
    Boolean builtin "builtin Function call";
    Boolean isImpure "if the function has prefix *impure* is true, else false";
    Boolean isFunctionPointerCall;
    DAE.InlineType inlineType;
    DAE.TailCall tailCall "Input variables of the function if the call is tail-recursive";
  algorithm
    CALL_ATTR(ty, tuple_, builtin, isImpure, isFunctionPointerCall, inlineType, tailCall) := attr;
    fattr := DAE.CALL_ATTR(Type.toDAE(ty), tuple_, builtin, isImpure, isFunctionPointerCall, inlineType, tailCall);
  end toDAECallAtributes;

  function makeBuiltinCall
    "Create a CALL with the given data for a call to a builtin function."
    input String name;
    input list<Expression> args;
    input Type result_type;
    input Boolean isImpure;
    output Expression call;
    annotation(__OpenModelica_EarlyInline = true);
  algorithm
    call := Expression.CALL(Absyn.IDENT(name), args,
      CallAttributes.CALL_ATTR(result_type, false, true, isImpure, false, DAE.NO_INLINE(), DAE.NO_TAIL()));
  end makeBuiltinCall;

  function makePureBuiltinCall
    "Create a CALL with the given data for a call to a builtin function."
    input String name;
    input list<Expression> args;
    input Type result_type;
    output Expression call;
    annotation(__OpenModelica_EarlyInline = true);
  algorithm
    call := makeBuiltinCall(name, args, result_type, false);
  end makePureBuiltinCall;
end Expression;

annotation(__OpenModelica_Interface="frontend");
end NFExpression;
