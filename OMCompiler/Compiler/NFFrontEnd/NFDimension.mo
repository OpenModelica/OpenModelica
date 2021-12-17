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

encapsulated uniontype NFDimension
protected
  import Dimension = NFDimension;
  import Operator = NFOperator;
  import Prefixes = NFPrefixes;
  import List;
  import SimplifyExp = NFSimplifyExp;
  import Ceval = NFCeval;

public
  import Absyn.{Exp, Path, Subscript};
  import Class = NFClass;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import Type = NFType;
  import ComponentRef = NFComponentRef;
  import NFPrefixes.Variability;
  import Inst = NFInst;
  import NFCeval.EvalTarget;

  record RAW_DIM
    Absyn.Subscript dim;
    InstNode scope;
  end RAW_DIM;

  record UNTYPED
    Expression dimension;
    Boolean isProcessing;
  end UNTYPED;

  record INTEGER
    Integer size;
    Variability var;
  end INTEGER;

  record BOOLEAN
  end BOOLEAN;

  record ENUM
    Type enumType;
  end ENUM;

  record EXP
    Expression exp;
    Variability var;
  end EXP;

  record UNKNOWN
  end UNKNOWN;

  function fromExp
    input Expression exp;
    input Variability var;
    output Dimension dim;
  algorithm
    dim := match exp
      local
        Class cls;
        ComponentRef cref;
        Type ty;

      case Expression.INTEGER() then INTEGER(exp.value, var);

      case Expression.TYPENAME(ty = Type.ARRAY(elementType = ty))
        then
          match ty
            case Type.BOOLEAN() then BOOLEAN();
            case Type.ENUMERATION() then ENUM(ty);
            else
              algorithm
                Error.assertion(false, getInstanceName() + " got invalid typename", sourceInfo());
              then
                fail();
          end match;

      case Expression.ARRAY()
        guard Expression.arrayAllEqual(exp)
        then fromExp(Expression.arrayFirstScalar(exp), var);

      case Expression.SUBSCRIPTED_EXP(split = true)
        guard Expression.isArray(exp.exp) and Expression.arrayAllEqual(exp.exp)
        then fromExp(Expression.arrayFirstScalar(exp.exp), var);

      else EXP(exp, var);
    end match;
  end fromExp;

  function fromInteger
    input Integer n;
    input Variability var = Variability.CONSTANT;
    output Dimension dim = INTEGER(n, var);
  end fromInteger;

  function fromExpList
    input list<Expression> expl;
    output Dimension dim = INTEGER(listLength(expl), Variability.CONSTANT);
  end fromExpList;

  function toDAE
    input Dimension dim;
    output DAE.Dimension daeDim;
  algorithm
    daeDim := match dim
      local
        Type ty;

      case INTEGER() then DAE.DIM_INTEGER(dim.size);
      case BOOLEAN() then DAE.DIM_BOOLEAN();
      case ENUM(enumType = ty as Type.ENUMERATION())
        then DAE.DIM_ENUM(ty.typePath, ty.literals, listLength(ty.literals));
      case EXP() then DAE.DIM_EXP(Expression.toDAE(dim.exp));
      case UNKNOWN() then DAE.DIM_UNKNOWN();
    end match;
  end toDAE;

  function add
    input Dimension a, b;
    output Dimension c;
  algorithm
    c := match (a, b)
      case (UNKNOWN(),_) then UNKNOWN();
      case (_,UNKNOWN()) then UNKNOWN();
      case (INTEGER(),INTEGER()) then INTEGER(a.size+b.size, Prefixes.variabilityMax(a.var, b.var));
      case (INTEGER(),EXP()) then EXP(Expression.BINARY(b.exp, Operator.OPERATOR(Type.INTEGER(), NFOperator.Op.ADD), Expression.INTEGER(a.size)), b.var);
      case (EXP(),INTEGER()) then EXP(Expression.BINARY(a.exp, Operator.OPERATOR(Type.INTEGER(), NFOperator.Op.ADD), Expression.INTEGER(b.size)), a.var);
      case (EXP(),EXP()) then EXP(Expression.BINARY(a.exp, Operator.OPERATOR(Type.INTEGER(), NFOperator.Op.ADD), b.exp), Prefixes.variabilityMax(a.var, b.var));
      else UNKNOWN();
    end match;
  end add;

  function size
    input Dimension dim;
    output Integer size;
  algorithm
    size := match dim
      local
        Type ty;

      case INTEGER() then dim.size;
      case BOOLEAN() then 2;
      case ENUM(enumType = ty as Type.ENUMERATION()) then listLength(ty.literals);
    end match;
  end size;

  function isEqual
    input Dimension dim1;
    input Dimension dim2;
    output Boolean isEqual;
  algorithm
    isEqual := match (dim1, dim2)
      case (UNKNOWN(), _) then true;
      case (_, UNKNOWN()) then true;
      case (EXP(), _) then true;
      case (_, EXP()) then true;
      else Dimension.size(dim1) == Dimension.size(dim2);
    end match;
  end isEqual;

  function isEqualKnown
    input Dimension dim1;
    input Dimension dim2;
    output Boolean isEqual;
  algorithm
    isEqual := match (dim1, dim2)
      case (UNKNOWN(), _) then false;
      case (_, UNKNOWN()) then false;
      case (EXP(), EXP()) then Expression.isEqual(dim1.exp, dim2.exp);
      case (EXP(), _) then false;
      case (_, EXP()) then false;
      else Dimension.size(dim1) == Dimension.size(dim2);
    end match;
  end isEqualKnown;

  function allEqualKnown
    input list<Dimension> dims1;
    input list<Dimension> dims2;
    output Boolean allEqual = List.isEqualOnTrue(dims1, dims2, isEqualKnown);
  end allEqualKnown;

  function isKnown
    input Dimension dim;
    input Boolean allowExp = false;
    output Boolean known;
  algorithm
    known := match dim
      case INTEGER() then true;
      case BOOLEAN() then true;
      case ENUM() then true;
      case EXP() then allowExp;
      else false;
    end match;
  end isKnown;

  function isUnknown
    input Dimension dim;
    output Boolean isUnknown;
  algorithm
    isUnknown := match dim
      case UNKNOWN() then true;
      else false;
    end match;
  end isUnknown;

  function isZero
    input Dimension dim;
    output Boolean isZero;
  algorithm
    isZero := match dim
      case INTEGER() then dim.size == 0;
      case ENUM() then Type.enumSize(dim.enumType) == 0;
      else false;
    end match;
  end isZero;

  function isOne
    input Dimension dim;
    output Boolean isOne;
  algorithm
    isOne := match dim
      case INTEGER() then dim.size == 1;
      case ENUM() then Type.enumSize(dim.enumType) == 1;
      else false;
    end match;
  end isOne;

  function subscriptType
    "Returns the expected type of a subscript for the given dimension."
    input Dimension dim;
    output Type ty;
  algorithm
    ty := match dim
      case INTEGER() then Type.INTEGER();
      case BOOLEAN() then Type.BOOLEAN();
      case ENUM() then dim.enumType;
      case EXP() then Expression.typeOf(dim.exp);
      else Type.UNKNOWN();
    end match;
  end subscriptType;

  function toString
    input Dimension dim;
    output String str;
  algorithm
    str := match dim
      local
        Type ty;

      case INTEGER() then String(dim.size);
      case BOOLEAN() then "Boolean";
      case ENUM(enumType = ty as Type.ENUMERATION()) then AbsynUtil.pathString(ty.typePath);
      case EXP() then Expression.toString(dim.exp);
      case UNKNOWN() then ":";
      case UNTYPED() then Expression.toString(dim.dimension);
    end match;
  end toString;

  function toStringList
    input list<Dimension> dims;
    input Boolean brackets = true;
    output String str;
  algorithm
    str := stringDelimitList(list(toString(d) for d in dims), ", ");

    if brackets then
      str := "[" + str + "]";
    end if;
  end toStringList;

  function toFlatString
    input Dimension dim;
    output String str;
  algorithm
    str := match dim
      case INTEGER() then String(dim.size);
      case BOOLEAN() then "Boolean";
      case ENUM() then Type.toFlatString(dim.enumType);
      case EXP() then Expression.toFlatString(dim.exp);
      case UNKNOWN() then ":";
      case UNTYPED() then Expression.toFlatString(dim.dimension);
    end match;
  end toFlatString;

  function endExp
    "Returns an expression for the last index in a dimension."
    input Dimension dim;
    input ComponentRef cref;
    input Integer index;
    output Expression sizeExp;
  algorithm
    sizeExp := match dim
      local
        Type ty;

      case INTEGER() then Expression.INTEGER(dim.size);
      case BOOLEAN() then Expression.BOOLEAN(true);
      case ENUM(enumType = ty as Type.ENUMERATION())
        then Expression.makeEnumLiteral(ty, listLength(ty.literals));
      case EXP() then dim.exp;
      case UNKNOWN()
        then Expression.SIZE(Expression.fromCref(ComponentRef.stripSubscripts(cref)),
                             SOME(Expression.INTEGER(index)));
    end match;
  end endExp;

  function sizeExp
    "Returns the size of a dimension as an Expression."
    input Dimension dim;
    output Expression sizeExp;
  algorithm
    sizeExp := match dim
      local
        Type ty;

      case INTEGER() then Expression.INTEGER(dim.size);
      case BOOLEAN() then Expression.INTEGER(2);
      case ENUM(enumType = ty as Type.ENUMERATION())
        then Expression.INTEGER(listLength(ty.literals));
      case EXP() then dim.exp;
    end match;
  end sizeExp;

  function lowerBoundExp
    input Dimension dim;
    output Expression exp;
  algorithm
    exp := match dim
      case BOOLEAN() then Expression.BOOLEAN(false);
      case ENUM() then Expression.makeEnumLiteral(dim.enumType, 1);
      else Expression.INTEGER(1);
    end match;
  end lowerBoundExp;

  function expIsLowerBound
    "Returns true if the expression represents the lower bound of a dimension."
    input Expression exp;
    output Boolean isStart;
  algorithm
    isStart := match exp
      case Expression.INTEGER() then exp.value == 1;
      case Expression.BOOLEAN() then exp.value == false;
      case Expression.ENUM_LITERAL() then exp.index == 1;
      else false;
    end match;
  end expIsLowerBound;

  function upperBoundExp
    input Dimension dim;
    output Expression exp;
  algorithm
    exp := match dim
      local
        Type ty;

      case INTEGER() then Expression.INTEGER(dim.size);
      case BOOLEAN() then Expression.BOOLEAN(true);
      case ENUM(enumType = ty as Type.ENUMERATION())
        then Expression.makeEnumLiteral(ty, listLength(ty.literals));
      case EXP() then dim.exp;
    end match;
  end upperBoundExp;

  function expIsUpperBound
    "Returns true if the expression represents the upper bound of the given dimension."
    input Expression exp;
    input Dimension dim;
    output Boolean isEnd;
  algorithm
    isEnd := match (exp, dim)
      local
        Type ty;

      case (Expression.INTEGER(), INTEGER()) then exp.value == dim.size;
      case (Expression.BOOLEAN(), _) then exp.value == true;
      case (Expression.ENUM_LITERAL(), ENUM(enumType = ty as Type.ENUMERATION()))
        then exp.index == listLength(ty.literals);
      else false;
    end match;
  end expIsUpperBound;

  function variability
    input Dimension dim;
    output Variability var;
  algorithm
    var := match dim
      case INTEGER() then dim.var;
      case BOOLEAN() then Variability.CONSTANT;
      case ENUM() then Variability.CONSTANT;
      case EXP() then dim.var;
      case UNKNOWN() then Variability.CONTINUOUS;
    end match;
  end variability;

  function mapExp
    input Dimension dim;
    input MapFunc func;
    output Dimension outDim;

    partial function MapFunc
      input output Expression e;
    end MapFunc;
  algorithm
    outDim := match dim
      local
        Expression e1, e2;

      case UNTYPED(dimension = e1)
        algorithm
          e2 := Expression.map(e1, func);
        then
          if referenceEq(e1, e2) then dim else UNTYPED(e2, dim.isProcessing);

      case EXP(exp = e1)
        algorithm
          e2 := Expression.map(e1, func);
        then
          if referenceEq(e1, e2) then dim else fromExp(e2, dim.var);

      else dim;
    end match;
  end mapExp;

  function foldExp<ArgT>
    input Dimension dim;
    input FoldFunc func;
    input ArgT arg;
    output ArgT outArg;

    partial function FoldFunc
      input Expression dim;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    outArg := match dim
      case UNTYPED() then Expression.fold(dim.dimension, func, arg);
      case EXP() then Expression.fold(dim.exp, func, arg);
      else arg;
    end match;
  end foldExp;

  function foldExpList<ArgT>
    input list<Dimension> dims;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression dim;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for dim in dims loop
      arg := foldExp(dim, func, arg);
    end for;
  end foldExpList;

  function eval
    input Dimension dim;
    input EvalTarget target = EvalTarget.IGNORE_ERRORS();
    output Dimension outDim;
  algorithm
    outDim := match dim
      case EXP() then fromExp(Ceval.evalExp(dim.exp, target), dim.var);
      else dim;
    end match;
  end eval;

  function simplify
    input output Dimension dim;
  algorithm
    () := match dim
      case EXP()
        algorithm
          dim.exp := SimplifyExp.simplify(dim.exp);
        then
          ();

      else ();
    end match;
  end simplify;

  function typeOf
    input Dimension dim;
    output Type ty;
  algorithm
    ty := match dim
      case INTEGER() then Type.INTEGER();
      case BOOLEAN() then Type.BOOLEAN();
      case ENUM() then dim.enumType;
      case EXP() then Expression.typeOf(dim.exp);
      else Type.UNKNOWN();
    end match;
  end typeOf;

annotation(__OpenModelica_Interface="frontend");
end NFDimension;
