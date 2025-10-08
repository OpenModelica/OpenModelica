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
  import Dump;
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

  record RESIZABLE
    "for all symbolic purposes this is INTEGER() for codegeneration it is EXP()
    invoked by using annotation(__OpenModelica_resizable=true) on a parameter"
    Integer size              "the actual size defined by the user";
    Option<Integer> opt_size  "the optimal size determined by the backend";
    Expression exp            "the full expression (parameter)";
    Variability var;
  end RESIZABLE;

  record UNKNOWN
  end UNKNOWN;

  function fromExp
    input Expression exp;
    input Variability var;
    output Dimension dim;
  algorithm
    dim := match exp
      local
        Expression e;
        Integer value;
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

      else algorithm
        e := SimplifyExp.simplify(exp);
      then match e
        // if it can be simplified to an integer its just an integer
        case Expression.INTEGER(value) then INTEGER(value, var);
        // if it can be simplified to an integer after replacing resizables its resizable
        else algorithm
          e := Expression.map(e, Expression.replaceResizableParameter);
          e := SimplifyExp.simplify(e);
        then match e
          case Expression.INTEGER(value) then RESIZABLE(value, NONE(), exp, var);
          // otherwise it is just an expression
          else EXP(exp, var);
        end match;
      end match;
    end match;
  end fromExp;

  function fromRange
    input Expression range "needs to be RANGE()";
    output Dimension dim;
  protected
    Integer start, step, stop;
  algorithm
    (start, step, stop) := match range
      case Expression.RANGE(start = Expression.INTEGER(start),
                            step  = NONE(),
                            stop  = Expression.INTEGER(stop))
      then (start, 1, stop);
      case Expression.RANGE(start = Expression.INTEGER(start),
                            step  = SOME(Expression.INTEGER(step)),
                            stop  = Expression.INTEGER(stop))
      then (start, step, stop);
      else algorithm
        Error.assertion(false, getInstanceName() + " got non-range expression: " + Expression.toString(range), sourceInfo());
      then fail();
    end match;

    dim := INTEGER(realInt((stop-start)/step + 1), NFPrefixes.Variability.CONSTANT);
  end fromRange;

  function fromInteger
    input Integer n;
    input Variability var = Variability.CONSTANT;
    output Dimension dim = INTEGER(n, var);
  end fromInteger;

  function fromExpArray
    input array<Expression> expl;
    output Dimension dim = INTEGER(arrayLength(expl), Variability.CONSTANT);
  end fromExpArray;

  function fromExpList
    input list<Expression> expl;
    output Dimension dim = INTEGER(listLength(expl), Variability.CONSTANT);
  end fromExpList;

  function toRange
    input Dimension dim;
    output Expression range;
  algorithm
    range := Expression.RANGE(Type.liftArrayLeft(typeOf(dim), dim),
      lowerBoundExp(dim), NONE(), upperBoundExp(dim));
  end toRange;

  function toDAE
    input Dimension dim;
    output DAE.Dimension daeDim;
  algorithm
    daeDim := match dim
      local
        Type ty;

      case INTEGER()    then DAE.DIM_INTEGER(dim.size);
      case BOOLEAN()    then DAE.DIM_BOOLEAN();
      case ENUM(enumType = ty as Type.ENUMERATION())
        then DAE.DIM_ENUM(ty.typePath, ty.literals, listLength(ty.literals));
      case EXP()        then DAE.DIM_EXP(Expression.toDAE(dim.exp));
      case RESIZABLE()  then DAE.DIM_EXP(Expression.toDAE(dim.exp));
      case UNKNOWN()    then DAE.DIM_UNKNOWN();
    end match;
  end toDAE;

  function add
    input Dimension a, b;
    output Dimension c;
  protected
    function addExp
      input Expression e1;
      input Expression e2;
      output Expression res = Expression.BINARY(e1, Operator.OPERATOR(Type.INTEGER(), NFOperator.Op.ADD), e2);
    end addExp;
    function addOpt
      input Option<Integer> s1;
      input Option<Integer> s2;
      output Option<Integer> res;
    algorithm
      res := match (s1, s2)
        local
          Integer i1, i2;
        case (SOME(i1), SOME(i2)) then SOME(i1+i2);
        else NONE();
      end match;
    end addOpt;
  algorithm
    c := match (a, b)
      case (UNKNOWN(),_)              then UNKNOWN();
      case (_,UNKNOWN())              then UNKNOWN();
      case (INTEGER(),INTEGER())      then INTEGER(a.size+b.size, Prefixes.variabilityMax(a.var, b.var));
      case (INTEGER(),EXP())          then EXP(addExp(b.exp, Expression.INTEGER(a.size)), b.var);
      case (EXP(),INTEGER())          then EXP(addExp(a.exp, Expression.INTEGER(b.size)), a.var);
      case (EXP(),EXP())              then EXP(addExp(a.exp, b.exp), Prefixes.variabilityMax(a.var, b.var));
      case (INTEGER(),RESIZABLE())    then RESIZABLE(a.size+b.size, addOpt(SOME(a.size), b.opt_size), addExp(b.exp, Expression.INTEGER(a.size)), b.var);
      case (RESIZABLE(),INTEGER())    then RESIZABLE(a.size+b.size, addOpt(a.opt_size, SOME(b.size)), addExp(a.exp, Expression.INTEGER(b.size)), a.var);
      case (EXP(),RESIZABLE())        then EXP(addExp(a.exp, b.exp), Prefixes.variabilityMax(a.var, b.var));
      case (RESIZABLE(),EXP())        then EXP(addExp(a.exp, b.exp), Prefixes.variabilityMax(a.var, b.var));
      case (RESIZABLE(),RESIZABLE())  then RESIZABLE(a.size+b.size, addOpt(a.opt_size, b.opt_size), addExp(a.exp, b.exp), Prefixes.variabilityMax(a.var, b.var));
      else UNKNOWN();
    end match;
  end add;

  function size
    input Dimension dim;
    input Boolean resize = false;
    output Integer size;
  algorithm
    size := match dim
      local
        Type ty;

      case INTEGER()    then dim.size;
      case RESIZABLE()  then if resize then Util.getOptionOrDefault(dim.opt_size, dim.size) else dim.size;
      case BOOLEAN()    then 2;
      case ENUM(enumType = ty as Type.ENUMERATION()) then listLength(ty.literals);
      else algorithm
        if Flags.isSet(Flags.FAILTRACE) then
          Error.addCompilerWarning(getInstanceName() + " could not get size of: " + toString(dim));
        end if;
      then fail();
    end match;
  end size;

  function sizesProduct
    "Returns the product of the given dimension sizes."
    input list<Dimension> dims;
    input Boolean resize = false;
    output Integer outSize = 1;
  algorithm
    for dim in dims loop
      outSize := outSize * Dimension.size(dim, resize);
    end for;
  end sizesProduct;

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
      case (RESIZABLE(), RESIZABLE()) then Expression.isEqual(dim1.exp, dim2.exp);
      else Dimension.size(dim1) == Dimension.size(dim2);
    end match;
  end isEqual;

  function isEqualKnown
    input Dimension dim1;
    input Dimension dim2;
    output Boolean isEqual;
  algorithm
    isEqual := match (dim1, dim2)
      case (UNKNOWN(), _)             then false;
      case (_, UNKNOWN())             then false;
      case (EXP(), EXP())             then Expression.isEqual(dim1.exp, dim2.exp);
      case (RESIZABLE(), RESIZABLE()) then Expression.isEqual(dim1.exp, dim2.exp);
      case (EXP(), _)                 then false;
      case (_, EXP())                 then false;
      else Dimension.size(dim1) == Dimension.size(dim2);
    end match;
  end isEqualKnown;

  function isEqualKnownSize
    "Same as isEqualKnown, but also takes the nodes and dimension indices that
     the dimensions come from in order to check for equality when one dimension
     is a size-expression that refers to the other dimension."
    input Dimension dim1;
    input InstNode node1;
    input Integer index1;
    input Dimension dim2;
    input InstNode node2;
    input Integer index2;
    output Boolean isEqual;
  protected
    Expression cref_exp, index_exp;
  algorithm
    isEqual := match (dim1, dim2)
      // dim1 is equal to dim2 if dim1 = size(node2, ...)
      case (EXP(), _) guard isSizeOf(dim1, node2, index2) then true;

      // dim2 is equal to dim1 if dim2 = size(node1, ...)
      case (_, EXP()) guard isSizeOf(dim2, node1, index1) then true;

      case (EXP(), EXP()) then Expression.isEqual(dim1.exp, dim2.exp);
      case (RESIZABLE(), RESIZABLE()) then Expression.isEqual(dim1.exp, dim2.exp);
      case (UNKNOWN(), _) then false;
      case (_, UNKNOWN()) then false;
      else Dimension.size(dim1) == Dimension.size(dim2);
    end match;
  end isEqualKnownSize;

  function isSizeOf
    "Returns true if the dimension is size(node, index)."
    input Dimension dim;
    input InstNode node;
    input Integer index;
    output Boolean res;
  protected
    Expression cref_exp, index_exp;
  algorithm
    res := match dim
      case EXP(exp = Expression.SIZE(exp = cref_exp as Expression.CREF(), dimIndex = SOME(index_exp)))
        then InstNode.refEqual(ComponentRef.node(cref_exp.cref), node) and
             Expression.isEqual(index_exp, Expression.INTEGER(index));

      else false;
    end match;
  end isSizeOf;

  function isResizable
    input Dimension dim;
    output Boolean b;
  algorithm
    b := match dim
      case RESIZABLE() then true;
      else false;
    end match;
  end isResizable;

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
      case RESIZABLE() then true;
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
      case RESIZABLE() then Expression.typeOf(dim.exp);
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

      case RAW_DIM() then Dump.printSubscriptStr(dim.dim);
      case INTEGER() then String(dim.size);
      case BOOLEAN() then "Boolean";
      case ENUM(enumType = ty as Type.ENUMERATION()) then AbsynUtil.pathString(ty.typePath);
      case EXP() then Expression.toString(dim.exp);
      case RESIZABLE() then Expression.toString(dim.exp) + "(R)";
      case UNKNOWN() then ":";
      case UNTYPED() then Expression.toString(dim.dimension);
    end match;
  end toString;

  function hashList
    input list<Dimension> dims;
    output Integer i = stringHashDjb2(toStringList(dims));
  end hashList;

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
    input BaseModelica.OutputFormat format;
    output String str;
  algorithm
    str := match dim
      case INTEGER() then String(dim.size);
      case BOOLEAN() then "Boolean";
      case ENUM() then Type.toFlatString(dim.enumType, format);
      case EXP() then Expression.toFlatString(dim.exp, format);
      case RESIZABLE() then Expression.toFlatString(dim.exp, format) + "(R)";
      case UNKNOWN() then ":";
      case UNTYPED() then Expression.toFlatString(dim.dimension, format);
    end match;
  end toFlatString;

  function endExp
    "Returns an expression for the last index in a dimension."
    input Dimension dim;
    input Expression subscriptedExp;
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
      case RESIZABLE() then dim.exp;
      case UNKNOWN()
        then match subscriptedExp
          case Expression.CREF()
            then Expression.SIZE(Expression.fromCref(ComponentRef.stripSubscripts(subscriptedExp.cref)),
                                 SOME(Expression.INTEGER(index)));
          case Expression.SUBSCRIPTED_EXP()
            then Expression.SIZE(subscriptedExp.exp, SOME(Expression.INTEGER(index)));
        end match;
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
      case RESIZABLE() then dim.exp;
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
      case RESIZABLE() then dim.exp;
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
      case RESIZABLE() then dim.var;
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

      case RESIZABLE(exp = e1)
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
      case RESIZABLE() then Expression.fold(dim.exp, func, arg);
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
    input EvalTarget target = NFCeval.noTarget;
    output Dimension outDim;
  algorithm
    outDim := match dim
      case EXP() then fromExp(Ceval.evalExp(dim.exp, target), dim.var);
      case RESIZABLE() algorithm
        dim.exp := Ceval.evalExp(dim.exp, target);
      then dim;
      else dim;
    end match;
  end eval;

  function simplify
    input output Dimension dim;
  algorithm
    dim := match dim
      local
        Expression simple;
      case EXP() algorithm
        simple := SimplifyExp.simplify(dim.exp);
      then fromExp(simple, Expression.variability(simple));
      case RESIZABLE() algorithm
        dim.exp := SimplifyExp.simplify(dim.exp);
      then dim;
      else dim;
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
      case RESIZABLE() then Expression.typeOf(dim.exp);
      else Type.UNKNOWN();
    end match;
  end typeOf;

annotation(__OpenModelica_Interface="frontend");
end NFDimension;
