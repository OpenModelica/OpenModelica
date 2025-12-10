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

encapsulated uniontype NFOperator
protected
  import Operator = NFOperator;
  import Util;

public
  import Type = NFType;
  import Absyn;
  import AbsynUtil;
  import DAE;

  type Op = enumeration(
    // Basic arithmetic operators.
    ADD,               //  1: +
    SUB,               //  2: -
    MUL,               //  3: *
    DIV,               //  4: /
    POW,               //  5: ^
    // Element-wise arithmetic operators. These are only used until the type
    // checking, then replaced with a more specific operator.
    ADD_EW,            //  6: .+
    SUB_EW,            //  7: .-
    MUL_EW,            //  8: .*
    DIV_EW,            //  9: ./
    POW_EW,            // 10: .^
    // Scalar-Array and Array-Scalar arithmetic operators.
    ADD_SCALAR_ARRAY,  // 11: scalar + array
    ADD_ARRAY_SCALAR,  // 12: array + scalar
    SUB_SCALAR_ARRAY,  // 13: scalar - array
    SUB_ARRAY_SCALAR,  // 14: array - scalar
    MUL_SCALAR_ARRAY,  // 15: scalar * array
    MUL_ARRAY_SCALAR,  // 16: array * scalar
    MUL_VECTOR_MATRIX, // 17: vector * matrix
    MUL_MATRIX_VECTOR, // 18: matrix * vector
    SCALAR_PRODUCT,    // 19: vector * vector
    MATRIX_PRODUCT,    // 20: matrix * matrix
    DIV_SCALAR_ARRAY,  // 21: scalar / array
    DIV_ARRAY_SCALAR,  // 22: array / scalar
    POW_SCALAR_ARRAY,  // 23: scalar ^ array
    POW_ARRAY_SCALAR,  // 24: array ^ scalar
    POW_MATRIX,        // 25: matrix ^ Integer
    // Unary arithmetic operators.
    UMINUS,            // 26: -
    // Logic operators.
    AND,               // 27: and
    OR,                // 28: or
    NOT,               // 29: not
    // Relational operators.
    LESS,              // 30: <
    LESSEQ,            // 31: <=
    GREATER,           // 32: >
    GREATEREQ,         // 33: >=
    EQUAL,             // 34: ==
    NEQUAL,            // 35: <>
    USERDEFINED        // 36: Overloaded operator.
  );

  record OPERATOR
    Type ty;
    Op op;
  end OPERATOR;

  function compare
    input Operator op1;
    input Operator op2;
    output Integer comp;
  protected
    Op o1 = op1.op, o2 = op2.op;
  algorithm
    // TODO: Compare the types instead if both operators are USERDEFINED.
    comp := Util.intCompare(Integer(o1), Integer(o2));
  end compare;

  function invert
    input output Operator operator;
  algorithm
    operator.op := match operator.op
      case Op.ADD then Op.SUB;
      case Op.SUB then Op.ADD;
      case Op.MUL then Op.DIV;
      case Op.DIV then Op.MUL;
      case Op.ADD_EW then Op.SUB_EW;
      case Op.SUB_EW then Op.ADD_EW;
      case Op.MUL_EW then Op.DIV_EW;
      case Op.DIV_EW then Op.MUL_EW;
      case Op.ADD_SCALAR_ARRAY then Op.SUB_SCALAR_ARRAY;
      case Op.ADD_ARRAY_SCALAR then Op.SUB_ARRAY_SCALAR;
      case Op.SUB_SCALAR_ARRAY then Op.ADD_SCALAR_ARRAY;
      case Op.SUB_ARRAY_SCALAR then Op.ADD_ARRAY_SCALAR;
      case Op.MUL_SCALAR_ARRAY then Op.DIV_SCALAR_ARRAY;
      case Op.MUL_ARRAY_SCALAR then Op.DIV_ARRAY_SCALAR;
      case Op.DIV_SCALAR_ARRAY then Op.MUL_SCALAR_ARRAY;
      case Op.DIV_ARRAY_SCALAR then Op.MUL_ARRAY_SCALAR;
      case Op.LESS             then Op.GREATEREQ;
      case Op.LESSEQ           then Op.GREATER;
      case Op.GREATER          then Op.LESSEQ;
      case Op.GREATEREQ        then Op.LESS;
      case Op.EQUAL            then Op.EQUAL;
      case Op.NEQUAL           then Op.NEQUAL;
      // ToDo: should POW return POW? exponent should be negated
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "Failed! Don't know how to invert: " + symbol(operator)});
      then fail();
    end match;
  end invert;

  function typeRestriction
    input Type ty;
    output Integer i;
  algorithm
    if Type.isScalar(ty) then
      i := 0;
    elseif Type.isVector(ty) then
      i := 1;
    elseif Type.isMatrix(ty) then
      i := 2;
    elseif Type.isArray(ty) then
      i := 3;
    else
      i := 4;
    end if;
  end typeRestriction;

  function repairMultary
    input output Operator operator;
    input list<Type> types;
  protected
    MathClassification mc = getMathClassification(operator);
    SizeClassification sc;
    list<tuple<Integer, Type>> lst;
    tuple<Integer, Type> min_, max_;
    Type ty;
    function tplLt
      input tuple<Integer, Type> tpl1;
      input tuple<Integer, Type> tpl2;
      output Boolean b = Util.tuple21(tpl1) < Util.tuple21(tpl2);
    end tplLt;
  algorithm
    lst := list((typeRestriction(t), t) for t in types);
    min_ := List.minElement(lst, tplLt);
    max_ := List.maxElement(lst, tplLt);
    (sc, ty) := match (min_, max_)
      case ((0, _), (0, ty))  then (SizeClassification.SCALAR, ty);
      case ((0, _), (_ ,ty))  then (SizeClassification.SCALAR_ARRAY, ty);
      case ((1, _), (1, ty))  then (SizeClassification.ELEMENT_WISE, ty);
      case ((1, _), (2, ty))  then (SizeClassification.VECTOR_MATRIX, ty);
      case ((2, _), (2, ty))  then (SizeClassification.ELEMENT_WISE, ty);
      case ((3, _), (3, ty))  then (SizeClassification.ELEMENT_WISE, ty);
      else algorithm
        Error.assertion(false, getInstanceName() + " failed because the multary arguments have incompatible sizes: "
        + List.toString(types, Type.toString), sourceInfo());
      then fail();
    end match;
    operator := fromClassification((mc, sc), ty);
  end repairMultary;

  function repairBinary
    input output Operator operator;
    input Type ty1;
    input Type ty2;
  protected
    MathClassification mc = getMathClassification(operator);
    SizeClassification sc;
    Type ty;
  algorithm
    (sc, ty) := match (typeRestriction(ty1), typeRestriction(ty2))
      local
        Integer i1, i2;
      case (0, 0)                 then (SizeClassification.SCALAR, ty1);
      case (0, i2) guard(i2>0)    then (SizeClassification.SCALAR_ARRAY, ty2);
      case (i1, 0) guard(i1>0)    then (SizeClassification.ARRAY_SCALAR, ty1);
      case (1, 2)                 then (SizeClassification.VECTOR_MATRIX, ty1);
      case (2, 1)                 then (SizeClassification.MATRIX_VECTOR, ty2);
      case (i1, i2) guard(i1==i2) then (getSizeClassification(operator), ty1);
      else algorithm
        Error.assertion(false, getInstanceName() + " failed because the binary arguments have incompatible sizes: "
          + Type.toString(ty1) + ", " + Type.toString(ty2), sourceInfo());
      then fail();
    end match;
    operator := fromClassification((mc, sc), ty);
  end repairBinary;

  function isLogical
    input Operator operator;
    output Boolean b;
  algorithm
    b := match operator.op
      case Op.AND   then true;
      case Op.OR    then true;
      case Op.NOT   then true;
                    else false;
    end match;
  end isLogical;

  function isRelational
    input Operator operator;
    output Boolean b;
  algorithm
    b := match operator.op
      case Op.LESS      then true;
      case Op.LESSEQ    then true;
      case Op.GREATER   then true;
      case Op.GREATEREQ then true;
      case Op.EQUAL     then true;
      case Op.NEQUAL    then true;
                        else false;
    end match;
  end isRelational;

  function isAdd
    input Operator operator;
    output Boolean b;
  algorithm
    b := match operator.op
      case Op.ADD   then true;
      case Op.ADD_EW then true;
                    else false;
    end match;
  end isAdd;

  function isScalarProduct
    input Operator operator;
    output Boolean b;
  algorithm
    b := match operator.op
      case Op.SCALAR_PRODUCT then true;
      else false;
    end match;
  end isScalarProduct;

  function fromAbsyn
    input Absyn.Operator inOperator;
    output Operator outOperator;
  protected
    Op op;
  algorithm
    op := match inOperator
      case Absyn.ADD()       then Op.ADD;
      case Absyn.SUB()       then Op.SUB;
      case Absyn.MUL()       then Op.MUL;
      case Absyn.DIV()       then Op.DIV;
      case Absyn.POW()       then Op.POW;
      case Absyn.ADD_EW()    then Op.ADD_EW;
      case Absyn.SUB_EW()    then Op.SUB_EW;
      case Absyn.MUL_EW()    then Op.MUL_EW;
      case Absyn.DIV_EW()    then Op.DIV_EW;
      case Absyn.POW_EW()    then Op.POW_EW;
      case Absyn.UPLUS()     then Op.ADD;
      case Absyn.UPLUS_EW()  then Op.ADD;
      case Absyn.UMINUS()    then Op.UMINUS;
      case Absyn.UMINUS_EW() then Op.UMINUS;
      case Absyn.AND()       then Op.AND;
      case Absyn.OR()        then Op.OR;
      case Absyn.NOT()       then Op.NOT;
      case Absyn.LESS()      then Op.LESS;
      case Absyn.LESSEQ()    then Op.LESSEQ;
      case Absyn.GREATER()   then Op.GREATER;
      case Absyn.GREATEREQ() then Op.GREATEREQ;
      case Absyn.EQUAL()     then Op.EQUAL;
      case Absyn.NEQUAL()    then Op.NEQUAL;
    end match;

    outOperator := OPERATOR(Type.UNKNOWN(), op);
  end fromAbsyn;

  function toAbsyn
    input Operator op;
    output Absyn.Operator aop;
  algorithm
    aop := match op.op
      case Op.ADD               then if Type.isArray(op.ty) then Absyn.Operator.ADD_EW() else Absyn.Operator.ADD();
      case Op.SUB               then if Type.isArray(op.ty) then Absyn.Operator.SUB_EW() else Absyn.Operator.SUB();
      case Op.MUL               then if Type.isArray(op.ty) then Absyn.Operator.MUL_EW() else Absyn.Operator.MUL();
      case Op.DIV               then if Type.isArray(op.ty) then Absyn.Operator.DIV_EW() else Absyn.Operator.DIV();
      case Op.POW               then if Type.isArray(op.ty) then Absyn.Operator.POW_EW() else Absyn.Operator.POW();
      case Op.ADD_EW            then Absyn.Operator.ADD_EW();
      case Op.SUB_EW            then Absyn.Operator.SUB_EW();
      case Op.MUL_EW            then Absyn.Operator.MUL_EW();
      case Op.DIV_EW            then Absyn.Operator.DIV_EW();
      case Op.POW_EW            then Absyn.Operator.POW_EW();
      case Op.ADD_SCALAR_ARRAY  then Absyn.Operator.ADD();
      case Op.ADD_ARRAY_SCALAR  then Absyn.Operator.ADD();
      case Op.SUB_SCALAR_ARRAY  then Absyn.Operator.SUB();
      case Op.SUB_ARRAY_SCALAR  then Absyn.Operator.SUB();
      case Op.MUL_SCALAR_ARRAY  then Absyn.Operator.MUL();
      case Op.MUL_ARRAY_SCALAR  then Absyn.Operator.MUL();
      case Op.MUL_VECTOR_MATRIX then Absyn.Operator.MUL();
      case Op.MUL_MATRIX_VECTOR then Absyn.Operator.MUL();
      case Op.SCALAR_PRODUCT    then Absyn.Operator.MUL();
      case Op.MATRIX_PRODUCT    then Absyn.Operator.MUL();
      case Op.DIV_SCALAR_ARRAY  then Absyn.Operator.DIV();
      case Op.DIV_ARRAY_SCALAR  then Absyn.Operator.DIV();
      case Op.POW_SCALAR_ARRAY  then Absyn.Operator.POW();
      case Op.POW_ARRAY_SCALAR  then Absyn.Operator.POW();
      case Op.POW_MATRIX        then Absyn.Operator.POW();
      case Op.UMINUS            then if Type.isArray(op.ty) then Absyn.Operator.UMINUS_EW() else Absyn.Operator.UMINUS();
      case Op.AND               then Absyn.Operator.AND();
      case Op.OR                then Absyn.Operator.OR();
      case Op.NOT               then Absyn.Operator.NOT();
      case Op.LESS              then Absyn.Operator.LESS();
      case Op.LESSEQ            then Absyn.Operator.LESSEQ();
      case Op.GREATER           then Absyn.Operator.GREATER();
      case Op.EQUAL             then Absyn.Operator.EQUAL();
      case Op.NEQUAL            then Absyn.Operator.NEQUAL();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type.", sourceInfo());
        then
          fail();
    end match;
  end toAbsyn;

  function toDAE
    input Operator op;
    output DAE.Operator daeOp;
    output Boolean swapArguments = false "The DAE structure only has array*scalar, not scalar*array, etc";
    output Boolean negate = false "The second argument should be negated.";
  protected
    DAE.Type ty;
  algorithm
    ty := Type.toDAE(op.ty);
    daeOp := match op.op
      case Op.ADD               then if Type.isArray(op.ty) then DAE.ADD_ARR(ty) else DAE.ADD(ty);
      case Op.SUB               then if Type.isArray(op.ty) then DAE.SUB_ARR(ty) else DAE.SUB(ty);
      case Op.MUL               then if Type.isArray(op.ty) then DAE.MUL_ARR(ty) else DAE.MUL(ty);
      case Op.DIV               then if Type.isArray(op.ty) then DAE.DIV_ARR(ty) else DAE.DIV(ty);
      case Op.POW               then if Type.isArray(op.ty) then DAE.POW_ARR2(ty) else DAE.POW(ty);
      case Op.ADD_SCALAR_ARRAY  algorithm swapArguments := true; then DAE.ADD_ARRAY_SCALAR(ty);
      case Op.ADD_ARRAY_SCALAR  then DAE.ADD_ARRAY_SCALAR(ty);
      case Op.SUB_SCALAR_ARRAY  then DAE.SUB_SCALAR_ARRAY(ty);
      // array .- scalar is handled as array .+ (-scalar)
      case Op.SUB_ARRAY_SCALAR  algorithm negate := true; then DAE.ADD_ARRAY_SCALAR(ty);
      case Op.MUL_SCALAR_ARRAY  algorithm swapArguments := true; then DAE.MUL_ARRAY_SCALAR(ty);
      case Op.MUL_ARRAY_SCALAR  then DAE.MUL_ARRAY_SCALAR(ty);
      case Op.MUL_VECTOR_MATRIX then DAE.MUL_MATRIX_PRODUCT(ty);
      case Op.MUL_MATRIX_VECTOR then DAE.MUL_MATRIX_PRODUCT(ty);
      case Op.SCALAR_PRODUCT    then DAE.MUL_SCALAR_PRODUCT(ty);
      case Op.ADD_EW            then DAE.ADD_ARR(ty);
      case Op.SUB_EW            then DAE.SUB_ARR(ty);
      case Op.MUL_EW            then DAE.MUL_ARR(ty);
      case Op.MATRIX_PRODUCT    then DAE.MUL_MATRIX_PRODUCT(ty);
      case Op.DIV_SCALAR_ARRAY  then DAE.DIV_SCALAR_ARRAY(ty);
      case Op.DIV_ARRAY_SCALAR  then DAE.DIV_ARRAY_SCALAR(ty);
      case Op.POW_SCALAR_ARRAY  then DAE.POW_SCALAR_ARRAY(ty);
      case Op.POW_ARRAY_SCALAR  then DAE.POW_ARRAY_SCALAR(ty);
      case Op.POW_MATRIX        then DAE.POW_ARR(ty);
      case Op.UMINUS            then if Type.isArray(op.ty) then DAE.UMINUS_ARR(ty) else DAE.UMINUS(ty);
      case Op.AND               then DAE.AND(ty);
      case Op.OR                then DAE.OR(ty);
      case Op.NOT               then DAE.NOT(ty);
      case Op.LESS              then DAE.LESS(ty);
      case Op.LESSEQ            then DAE.LESSEQ(ty);
      case Op.GREATER           then DAE.GREATER(ty);
      case Op.GREATEREQ         then DAE.GREATEREQ(ty);
      case Op.EQUAL             then DAE.EQUAL(ty);
      case Op.NEQUAL            then DAE.NEQUAL(ty);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type: " + opToString(op.op), sourceInfo());
        then
          fail();
    end match;
  end toDAE;

  function typeOf
    input Operator op;
    output Type ty = op.ty;
  end typeOf;

  function setType
    input Type ty;
    input output Operator op;
  algorithm
    op.ty := ty;
  end setType;

  function scalarize
    input output Operator op;
  algorithm
    op.ty := Type.arrayElementType(op.ty);
  end scalarize;

  function unlift
    input output Operator op;
  algorithm
    op.ty := Type.unliftArray(op.ty);
  end unlift;

  function symbol
    input Operator op;
    input String spacing = " ";
    output String symbol;
  algorithm
    symbol := match op.op
      case Op.ADD               then "+";
      case Op.SUB               then "-";
      case Op.MUL               then "*";
      case Op.DIV               then "/";
      case Op.POW               then "^";
      case Op.ADD_EW            then ".+";
      case Op.SUB_EW            then ".-";
      case Op.MUL_EW            then ".*";
      case Op.DIV_EW            then "./";
      case Op.POW_EW            then ".^";
      case Op.ADD_SCALAR_ARRAY  then ".+";
      case Op.ADD_ARRAY_SCALAR  then ".+";
      case Op.SUB_SCALAR_ARRAY  then ".-";
      case Op.SUB_ARRAY_SCALAR  then ".-";
      case Op.MUL_SCALAR_ARRAY  then "*";
      case Op.MUL_ARRAY_SCALAR  then ".*";
      case Op.MUL_VECTOR_MATRIX then "*";
      case Op.MUL_MATRIX_VECTOR then "*";
      case Op.SCALAR_PRODUCT    then "*";
      case Op.MATRIX_PRODUCT    then "*";
      case Op.DIV_SCALAR_ARRAY  then "./";
      case Op.DIV_ARRAY_SCALAR  then "/";
      case Op.POW_SCALAR_ARRAY  then ".^";
      case Op.POW_ARRAY_SCALAR  then ".^";
      case Op.POW_MATRIX        then "^";
      case Op.UMINUS            then "-";
      case Op.AND               then "and";
      case Op.OR                then "or";
      case Op.NOT               then "not";
      case Op.LESS              then "<";
      case Op.LESSEQ            then "<=";
      case Op.GREATER           then ">";
      case Op.GREATEREQ         then ">=";
      case Op.EQUAL             then "==";
      case Op.NEQUAL            then "<>";
      //case Op.USERDEFINED      then "Userdefined:" + AbsynUtil.pathString(op.fqName);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type.", sourceInfo());
        then
          fail();
    end match;

    symbol := spacing + symbol + spacing;
  end symbol;

  function priority
    input Operator op;
    input Boolean lhs;
    output Integer priority;
  algorithm
    priority := match op.op
      case Op.ADD               then if lhs then 5 else 6;
      case Op.SUB               then 5;
      case Op.MUL               then 2;
      case Op.DIV               then 2;
      case Op.POW               then 1;
      case Op.ADD_EW            then if lhs then 5 else 6;
      case Op.SUB_EW            then 5;
      case Op.MUL_EW            then if lhs then 2 else 3;
      case Op.DIV_EW            then 2;
      case Op.POW_EW            then 1;
      case Op.ADD_SCALAR_ARRAY  then if lhs then 5 else 6;
      case Op.ADD_ARRAY_SCALAR  then if lhs then 5 else 6;
      case Op.SUB_SCALAR_ARRAY  then 5;
      case Op.SUB_ARRAY_SCALAR  then 5;
      case Op.MUL_SCALAR_ARRAY  then if lhs then 2 else 3;
      case Op.MUL_ARRAY_SCALAR  then if lhs then 2 else 3;
      case Op.MUL_VECTOR_MATRIX then if lhs then 2 else 3;
      case Op.MUL_MATRIX_VECTOR then if lhs then 2 else 3;
      case Op.SCALAR_PRODUCT    then if lhs then 2 else 3;
      case Op.MATRIX_PRODUCT    then if lhs then 2 else 3;
      case Op.DIV_SCALAR_ARRAY  then 2;
      case Op.DIV_ARRAY_SCALAR  then 2;
      case Op.POW_SCALAR_ARRAY  then 1;
      case Op.POW_ARRAY_SCALAR  then 1;
      case Op.POW_MATRIX        then 1;
      case Op.AND               then 8;
      case Op.OR                then 9;
      else 0;
    end match;
  end priority;

  function isAssociative
    input Operator op;
    output Boolean isAssociative;
  algorithm
    isAssociative := match op.op
      case Op.ADD then true;
      case Op.ADD_EW then true;
      //case ADD_ARRAY_SCALAR() then true;
      case Op.MUL_EW then true;
      //case MUL_ARRAY_SCALAR() then true;
      else false;
    end match;
  end isAssociative;

  function isNonAssociative
    input Operator op;
    output Boolean isNonAssociative;
  algorithm
    isNonAssociative := match op.op
      case Op.POW then true;
      case Op.POW_EW then true;
      case Op.POW_SCALAR_ARRAY then true;
      case Op.POW_ARRAY_SCALAR then true;
      case Op.POW_MATRIX then true;
      else false;
    end match;
  end isNonAssociative;

  function makeAdd
    input Type ty;
    output Operator op = OPERATOR(ty, Op.ADD);
  end makeAdd;

  function makeSub
    input Type ty;
    output Operator op = OPERATOR(ty, Op.SUB);
  end makeSub;

  function makeMul
    input Type ty;
    output Operator op = OPERATOR(ty, Op.MUL);
  end makeMul;

  function makeScalarProduct
    input Type ty;
    output Operator op = OPERATOR(ty, Op.SCALAR_PRODUCT);
  end makeScalarProduct;

  function makeDiv
    input Type ty;
    output Operator op = OPERATOR(ty, Op.DIV);
  end makeDiv;

  function makePow
    input Type ty;
    output Operator op = OPERATOR(ty, Op.POW);
  end makePow;

  function makeAddEW
    input Type ty;
    output Operator op = OPERATOR(ty, Op.ADD_EW);
  end makeAddEW;

  function makeSubEW
    input Type ty;
    output Operator op = OPERATOR(ty, Op.SUB_EW);
  end makeSubEW;

  function makeMulEW
    input Type ty;
    output Operator op = OPERATOR(ty, Op.MUL_EW);
  end makeMulEW;

  function makeDivEW
    input Type ty;
    output Operator op = OPERATOR(ty, Op.DIV_EW);
  end makeDivEW;

  function makeUMinus
    input Type ty;
    output Operator op = OPERATOR(ty, Op.UMINUS);
  end makeUMinus;

  function makeAnd
    input Type ty;
    output Operator op = OPERATOR(ty, Op.AND);
  end makeAnd;

  function makeOr
    input Type ty;
    output Operator op = OPERATOR(ty, Op.OR);
  end makeOr;

  function makeNot
    input Type ty;
    output Operator op = OPERATOR(ty, Op.NOT);
  end makeNot;

  function makeLess
    input Type ty;
    output Operator op = OPERATOR(ty, Op.LESS);
  end makeLess;

  function makeLessEq
    input Type ty;
    output Operator op = OPERATOR(ty, Op.LESSEQ);
  end makeLessEq;

  function makeGreater
    input Type ty;
    output Operator op = OPERATOR(ty, Op.GREATER);
  end makeGreater;

  function makeGreaterEq
    input Type ty;
    output Operator op = OPERATOR(ty, Op.GREATEREQ);
  end makeGreaterEq;

  function makeEqual
    input Type ty;
    output Operator op = OPERATOR(ty, Op.EQUAL);
  end makeEqual;

  function makeNotEqual
    input Type ty;
    output Operator op = OPERATOR(ty, Op.NEQUAL);
  end makeNotEqual;

  function makeScalarArray
    input Type ty;
    input Op op;
    output Operator outOp;
  protected
    Op o;
  algorithm
    o := match op
      case Op.ADD then Op.ADD_SCALAR_ARRAY;
      case Op.SUB then Op.SUB_SCALAR_ARRAY;
      case Op.MUL then Op.MUL_SCALAR_ARRAY;
      case Op.DIV then Op.DIV_SCALAR_ARRAY;
      case Op.POW then Op.POW_SCALAR_ARRAY;
    end match;

    outOp := OPERATOR(ty, o);
  end makeScalarArray;

  function makeArrayScalar
    input Type ty;
    input Op op;
    output Operator outOp;
  protected
    Op o;
  algorithm
    o := match op
      case Op.ADD then Op.ADD_ARRAY_SCALAR;
      case Op.SUB then Op.SUB_ARRAY_SCALAR;
      case Op.MUL then Op.MUL_ARRAY_SCALAR;
      case Op.DIV then Op.DIV_ARRAY_SCALAR;
      case Op.POW then Op.POW_ARRAY_SCALAR;
    end match;

    outOp := OPERATOR(ty, o);
  end makeArrayScalar;

  function stripEW
    input output Operator op;
  algorithm
    () := match op.op
      case Op.ADD_EW algorithm op.op := Op.ADD; then ();
      case Op.SUB_EW algorithm op.op := Op.SUB; then ();
      case Op.MUL_EW algorithm op.op := Op.MUL; then ();
      case Op.DIV_EW algorithm op.op := Op.DIV; then ();
      case Op.POW_EW algorithm op.op := Op.POW; then ();
      else ();
    end match;
  end stripEW;

  function isElementWise
    input Operator op;
    output Boolean ew;
  algorithm
    ew := match op.op
      case Op.ADD_EW then true;
      case Op.SUB_EW then true;
      case Op.MUL_EW then true;
      case Op.DIV_EW then true;
      case Op.POW_EW then true;
      else false;
    end match;
  end isElementWise;

  type MathClassification = enumeration(ADDITION, SUBTRACTION, MULTIPLICATION, DIVISION, POWER, LOGICAL, RELATION);
  type SizeClassification = enumeration(SCALAR, ELEMENT_WISE, ARRAY_SCALAR, SCALAR_ARRAY, MATRIX, VECTOR_MATRIX, MATRIX_VECTOR, LOGICAL, RELATION);
  type Classification = tuple<MathClassification, SizeClassification>;

  function mathSymbol
    input MathClassification mcl;
    output String str;
  algorithm
    str := match mcl
      case MathClassification.ADDITION        then "+";
      case MathClassification.SUBTRACTION     then "-";
      case MathClassification.MULTIPLICATION  then "*";
      case MathClassification.DIVISION        then "/";
      case MathClassification.POWER           then "^";
      case MathClassification.LOGICAL         then "L";
      case MathClassification.RELATION        then "R";
                                              else fail();
    end match;
  end mathSymbol;

  function classificationString
    input Classification cla;
    output String str;
  protected
    MathClassification mcl;
    SizeClassification scl;
  algorithm
    (mcl, scl) := cla;
    str := mathClassificationString(mcl) + sizeClassificationString(scl);
  end classificationString;

  function mathClassificationString
    input MathClassification mcl;
    output String str;
  algorithm
    str := match mcl
      case MathClassification.ADDITION        then "[ADD]";
      case MathClassification.SUBTRACTION     then "[SUB]";
      case MathClassification.MULTIPLICATION  then "[MUL]";
      case MathClassification.DIVISION        then "[DIV]";
      case MathClassification.POWER           then "[POW]";
      case MathClassification.LOGICAL         then "[LOG]";
      case MathClassification.RELATION        then "[REL]";
                                              else fail();
    end match;
  end mathClassificationString;

  function sizeClassificationString
    input SizeClassification scl;
    output String str;
  algorithm
    str := match scl
      case SizeClassification.SCALAR          then "[SCALAR]";
      case SizeClassification.ELEMENT_WISE    then "[ELMWIS]";
      case SizeClassification.ARRAY_SCALAR    then "[ARR-SC]";
      case SizeClassification.SCALAR_ARRAY    then "[SC-ARR]";
      case SizeClassification.MATRIX          then "[MATRIX]";
      case SizeClassification.VECTOR_MATRIX   then "[VEC-MA]";
      case SizeClassification.MATRIX_VECTOR   then "[MA-VEC]";
      case SizeClassification.LOGICAL         then "[LOGICL]";
      case SizeClassification.RELATION        then "[RELATN]";
                                              else fail();
    end match;
  end sizeClassificationString;

  function classify
    input Operator op;
    output Classification cl;
  algorithm
    cl := match op.op
      case Op.ADD                 then (MathClassification.ADDITION,        SizeClassification.SCALAR);
      case Op.SUB                 then (MathClassification.SUBTRACTION,     SizeClassification.SCALAR);
      case Op.MUL                 then (MathClassification.MULTIPLICATION,  SizeClassification.SCALAR);
      case Op.DIV                 then (MathClassification.DIVISION,        SizeClassification.SCALAR);
      case Op.POW                 then (MathClassification.POWER,           SizeClassification.SCALAR);
      case Op.ADD_EW              then (MathClassification.ADDITION,        SizeClassification.ELEMENT_WISE);
      case Op.SUB_EW              then (MathClassification.SUBTRACTION,     SizeClassification.ELEMENT_WISE);
      case Op.MUL_EW              then (MathClassification.MULTIPLICATION,  SizeClassification.ELEMENT_WISE);
      case Op.DIV_EW              then (MathClassification.DIVISION,        SizeClassification.ELEMENT_WISE);
      case Op.POW_EW              then (MathClassification.POWER,           SizeClassification.ELEMENT_WISE);
      case Op.MUL_ARRAY_SCALAR    then (MathClassification.MULTIPLICATION,  SizeClassification.ARRAY_SCALAR);
      case Op.MUL_SCALAR_ARRAY    then (MathClassification.MULTIPLICATION,  SizeClassification.SCALAR_ARRAY);
      case Op.ADD_ARRAY_SCALAR    then (MathClassification.ADDITION,        SizeClassification.ARRAY_SCALAR);
      case Op.ADD_SCALAR_ARRAY    then (MathClassification.ADDITION,        SizeClassification.SCALAR_ARRAY);
      case Op.SUB_ARRAY_SCALAR    then (MathClassification.SUBTRACTION,     SizeClassification.ARRAY_SCALAR);
      case Op.SUB_SCALAR_ARRAY    then (MathClassification.SUBTRACTION,     SizeClassification.SCALAR_ARRAY);
      case Op.SCALAR_PRODUCT      then (MathClassification.MULTIPLICATION,  SizeClassification.SCALAR);
      case Op.MATRIX_PRODUCT      then (MathClassification.MULTIPLICATION,  SizeClassification.MATRIX);
      case Op.MUL_VECTOR_MATRIX   then (MathClassification.MULTIPLICATION,  SizeClassification.VECTOR_MATRIX);
      case Op.MUL_MATRIX_VECTOR   then (MathClassification.MULTIPLICATION,  SizeClassification.MATRIX_VECTOR);
      case Op.DIV_ARRAY_SCALAR    then (MathClassification.DIVISION,        SizeClassification.ARRAY_SCALAR);
      case Op.DIV_SCALAR_ARRAY    then (MathClassification.DIVISION,        SizeClassification.SCALAR_ARRAY);
      case Op.POW_ARRAY_SCALAR    then (MathClassification.POWER,           SizeClassification.ARRAY_SCALAR);
      case Op.POW_SCALAR_ARRAY    then (MathClassification.POWER,           SizeClassification.SCALAR_ARRAY);
      case Op.POW_MATRIX          then (MathClassification.POWER,           SizeClassification.MATRIX);
      case Op.AND                 then (MathClassification.LOGICAL,         SizeClassification.LOGICAL);
      case Op.OR                  then (MathClassification.LOGICAL,         SizeClassification.LOGICAL);
      case Op.NOT                 then (MathClassification.LOGICAL,         SizeClassification.LOGICAL);
      case Op.LESS                then (MathClassification.RELATION,        SizeClassification.RELATION);
      case Op.LESSEQ              then (MathClassification.RELATION,        SizeClassification.RELATION);
      case Op.GREATER             then (MathClassification.RELATION,        SizeClassification.RELATION);
      case Op.GREATEREQ           then (MathClassification.RELATION,        SizeClassification.RELATION);
      case Op.EQUAL               then (MathClassification.RELATION,        SizeClassification.RELATION);
      case Op.NEQUAL              then (MathClassification.RELATION,        SizeClassification.RELATION);
      else algorithm
        Error.addInternalError(getInstanceName() + ": Don't know how to handle " + String(op.op), sourceInfo());
      then fail();
    end match;
  end classify;

  function classifyAddition
    "used to create an addition of the resulting type.
    Note: not to be used for logical or relations"
    input Operator op;
    output SizeClassification sz = if Type.isScalar(op.ty) then SizeClassification.SCALAR else SizeClassification.ELEMENT_WISE;
  end classifyAddition;

  function fromClassification
    "Only works for non-logical operators!"
    input Classification cl "mathematical and size classification";
    input Type ty           "Type information";
    output Operator result        "Resulting operator";
  protected
    Op op;
  algorithm
    op := match cl
      case (MathClassification.ADDITION,        SizeClassification.SCALAR)                  then Op.ADD;
      case (MathClassification.SUBTRACTION,     SizeClassification.SCALAR)                  then Op.SUB;
      case (MathClassification.MULTIPLICATION,  SizeClassification.SCALAR)                  then Op.MUL;
      // this has to be done correctly. use type of the expressions?
      //case (MathClassification.MULTIPLICATION,  SizeClassification.SCALAR)                  then Op.SCALAR_PRODUCT;
      case (MathClassification.DIVISION,        SizeClassification.SCALAR)                  then Op.DIV;
      case (MathClassification.POWER,           SizeClassification.SCALAR)                  then Op.POW;

      case (MathClassification.ADDITION,        SizeClassification.ELEMENT_WISE)            then Op.ADD_EW;
      case (MathClassification.SUBTRACTION,     SizeClassification.ELEMENT_WISE)            then Op.SUB_EW;
      case (MathClassification.MULTIPLICATION,  SizeClassification.ELEMENT_WISE)            then Op.MUL_EW;
      case (MathClassification.DIVISION,        SizeClassification.ELEMENT_WISE)            then Op.DIV_EW;
      case (MathClassification.POWER,           SizeClassification.ELEMENT_WISE)            then Op.POW_EW;

      case (MathClassification.ADDITION,        SizeClassification.ARRAY_SCALAR)            then Op.ADD_ARRAY_SCALAR;
      case (MathClassification.SUBTRACTION,     SizeClassification.ARRAY_SCALAR)            then Op.SUB_ARRAY_SCALAR;
      case (MathClassification.MULTIPLICATION,  SizeClassification.ARRAY_SCALAR)            then Op.MUL_ARRAY_SCALAR;
      case (MathClassification.DIVISION,        SizeClassification.ARRAY_SCALAR)            then Op.DIV_ARRAY_SCALAR;
      case (MathClassification.POWER,           SizeClassification.ARRAY_SCALAR)            then Op.POW_ARRAY_SCALAR;

      case (MathClassification.ADDITION,        SizeClassification.SCALAR_ARRAY)            then Op.ADD_SCALAR_ARRAY;
      case (MathClassification.SUBTRACTION,     SizeClassification.SCALAR_ARRAY)            then Op.SUB_SCALAR_ARRAY;
      case (MathClassification.MULTIPLICATION,  SizeClassification.SCALAR_ARRAY)            then Op.MUL_SCALAR_ARRAY;
      case (MathClassification.DIVISION,        SizeClassification.SCALAR_ARRAY)            then Op.DIV_SCALAR_ARRAY;
      case (MathClassification.POWER,           SizeClassification.SCALAR_ARRAY)            then Op.POW_SCALAR_ARRAY;

      case (MathClassification.ADDITION,        SizeClassification.MATRIX)                  then Op.ADD_EW;
      case (MathClassification.SUBTRACTION,     SizeClassification.MATRIX)                  then Op.SUB_EW;
      case (MathClassification.POWER,           SizeClassification.MATRIX)                  then Op.POW_MATRIX;
      case (MathClassification.MULTIPLICATION,  SizeClassification.MATRIX)                  then Op.MATRIX_PRODUCT;
      case (MathClassification.MULTIPLICATION,  SizeClassification.VECTOR_MATRIX)           then Op.MUL_VECTOR_MATRIX;
      case (MathClassification.MULTIPLICATION,  SizeClassification.MATRIX_VECTOR)           then Op.MUL_MATRIX_VECTOR;
      else algorithm
        Error.addInternalError(getInstanceName() + ": Don't know how to handle math class and size class combination: " + classificationString(cl), sourceInfo());
      then fail();
    end match;
    result := OPERATOR(ty, op);
  end fromClassification;

  function getMathClassification
    input Operator op;
    output MathClassification mcl;
  algorithm
    (mcl, _) := classify(op);
  end getMathClassification;

  function getSizeClassification
    input Operator op;
    output SizeClassification scl;
  algorithm
    (_, scl) := classify(op);
  end getSizeClassification;

  function combineSizeClassification
    input SizeClassification scl1;
    input SizeClassification scl2;
    output SizeClassification scl;
  algorithm
    scl := match (scl1, scl2)
      // Todo: more cases?
      case (SizeClassification.ELEMENT_WISE, SizeClassification.SCALAR) then SizeClassification.ARRAY_SCALAR;
      case (SizeClassification.SCALAR, SizeClassification.ELEMENT_WISE) then SizeClassification.SCALAR_ARRAY;
      else scl1;
    end match;
  end combineSizeClassification;

  function isDashClassification
    input MathClassification mcl;
    output Boolean b;
  algorithm
    b := match mcl
      case MathClassification.ADDITION    then true;
      case MathClassification.SUBTRACTION then true;
      else false;
    end match;
  end isDashClassification;

  function isCommutative
    "returns true for operators that are commutative"
    input Operator operator;
    output Boolean b;
  algorithm
    b := match Type.arrayElementType(operator.ty)
      case Type.INTEGER() then true;
      case Type.REAL()    then true;
      case Type.BOOLEAN() then true;
                          else false;
    end match;
    if not b then return; end if;

    b := match operator.op
      case Op.ADD               then true;
      case Op.MUL               then true;
      case Op.ADD_EW            then true;
      case Op.MUL_EW            then true;
      // the following might need adaption since they depend on argument ordering
      // furthermore weird regarding more than two arguments in Expression.MULTARY()
      case Op.ADD_SCALAR_ARRAY  then true;
      case Op.ADD_ARRAY_SCALAR  then true;
      case Op.MUL_SCALAR_ARRAY  then true;
      case Op.MUL_ARRAY_SCALAR  then true;
      else false;
    end match;
  end isCommutative;

  function isSoftCommutative
    "returns true for operators that are not commutative but have an easy rule for swapping arguments"
    input Operator operator;
    output Boolean b;
  algorithm
    b := match operator.op
      case Op.SUB               then true;
      case Op.DIV               then true;
      case Op.SUB_EW            then true;
      case Op.DIV_EW            then true;
      // the following might need adaption since they depend on argument ordering
      // furthermore weird regarding more than two arguments in Expression.MULTARY()
      case Op.SUB_SCALAR_ARRAY  then true;
      case Op.SUB_ARRAY_SCALAR  then true;
      case Op.DIV_SCALAR_ARRAY  then true;
      case Op.DIV_ARRAY_SCALAR  then true;
                                else false;
    end match;
  end isSoftCommutative;

  function repetition
    input Operator operator;
    output tuple<Boolean, Boolean> b;
  algorithm
    b := match operator.op
      case Op.ADD_SCALAR_ARRAY  then (true, false);
      case Op.ADD_ARRAY_SCALAR  then (false, true);
      case Op.MUL_SCALAR_ARRAY  then (true, false);
      case Op.MUL_ARRAY_SCALAR  then (false, true);
      case Op.MUL_VECTOR_MATRIX then (true, true);
      case Op.MUL_MATRIX_VECTOR then (true, true);
      case Op.MATRIX_PRODUCT    then (true, true);
                                else (false, false);
    end match;
  end repetition;

  function reduction
    input Operator operator;
    output Boolean b;
  algorithm
    b := match operator.op
      case Op.MUL_MATRIX_VECTOR then true;
      case Op.MUL_VECTOR_MATRIX then true;
      case Op.MATRIX_PRODUCT    then true;
      case Op.SCALAR_PRODUCT    then true;
                                else false;
    end match;
  end reduction;

  function isCombineable
    input Operator op1;
    input Operator op2;
    output Boolean b;
  protected
    MathClassification mcl1, mcl2;
    SizeClassification scl1, scl2;
  algorithm
    (mcl1, scl1) := classify(op1);
    (mcl2, scl2) := classify(op2);
    b := isCombineableMath(mcl1, mcl2) and isCombineableSize(scl1, scl2);
    if b then
      b := not (isScalarProduct(op1) or isScalarProduct(op2));
    end if;
  end isCombineable;

  function isCombineableMath
    input MathClassification mcl1;
    input MathClassification mcl2;
    output Boolean b;
  algorithm
    b :=  (Util.intCompare(Integer(mcl1), Integer(mcl2)) == 0)
          or (isDashClassification(mcl1) and isDashClassification(mcl2));
  end isCombineableMath;

  function isCombineableSize
    input SizeClassification scl1;
    input SizeClassification scl2;
    output Boolean b;
  algorithm
    b := (Util.intCompare(Integer(scl1), Integer(scl2)) == 0);
  end isCombineableSize;

  function toDebugString
    input Operator op;
    output String str;
  algorithm
    str := "OPERATOR(" + Type.toString(op.ty) + ", " + opToString(op.op) + ")";
  end toDebugString;

  function opToString
    input Op op;
    output String str;
  algorithm
    str := match op
      case Op.ADD then "ADD";
      case Op.SUB then "SUB";
      case Op.MUL then "MUL";
      case Op.DIV then "DIV";
      case Op.POW then "POW";
      case Op.ADD_EW then "ADD_EW";
      case Op.SUB_EW then "SUB_EW";
      case Op.MUL_EW then "MUL_EW";
      case Op.DIV_EW then "DIV_EW";
      case Op.POW_EW then "POW_EW";
      case Op.ADD_SCALAR_ARRAY then "ADD_SCALAR_ARRAY";
      case Op.ADD_ARRAY_SCALAR then "ADD_ARRAY_SCALAR";
      case Op.SUB_SCALAR_ARRAY then "SUB_SCALAR_ARRAY";
      case Op.SUB_ARRAY_SCALAR then "SUB_ARRAY_SCALAR";
      case Op.MUL_SCALAR_ARRAY then "MUL_SCALAR_ARRAY";
      case Op.MUL_ARRAY_SCALAR then "MUL_ARRAY_SCALAR";
      case Op.MUL_VECTOR_MATRIX then "MUL_VECTOR_MATRIX";
      case Op.MUL_MATRIX_VECTOR then "MUL_MATRIX_VECTOR";
      case Op.SCALAR_PRODUCT then "SCALAR_PRODUCT";
      case Op.MATRIX_PRODUCT then "MATRIX_PRODUCT";
      case Op.DIV_SCALAR_ARRAY then "DIV_SCALAR_ARRAY";
      case Op.DIV_ARRAY_SCALAR then "DIV_ARRAY_SCALAR";
      case Op.POW_SCALAR_ARRAY then "POW_SCALAR_ARRAY";
      case Op.POW_ARRAY_SCALAR then "POW_ARRAY_SCALAR";
      case Op.POW_MATRIX then "POW_MATRIX";
      case Op.UMINUS then "UMINUS";
      case Op.AND then "AND";
      case Op.OR then "OR";
      case Op.NOT then "NOT";
      case Op.LESS then "LESS";
      case Op.LESSEQ then "LESSEQ";
      case Op.GREATER then "GREATER";
      case Op.GREATEREQ then "GREATEREQ";
      case Op.EQUAL then "EQUAL";
      case Op.NEQUAL then "NEQUAL";
      case Op.USERDEFINED then "USERDEFINED";
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + "failed. Unhanded enumeration."});
        then fail();
    end match;
  end opToString;

annotation(__OpenModelica_Interface="frontend");
end NFOperator;
