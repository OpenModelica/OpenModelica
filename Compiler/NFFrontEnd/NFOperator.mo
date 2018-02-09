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
  import DAE;

  type Op = enumeration(
    // Basic arithmetic operators.
    ADD,               // +
    SUB,               // -
    MUL,               // *
    DIV,               // /
    POW,               // ^
    // Element-wise arithmetic operators. These are only used until the type
    // checking, then replaced with a more specific operator.
    ADD_EW,            // .+
    SUB_EW,            // .-
    MUL_EW,            // .*
    DIV_EW,            // ./
    POW_EW,            // .^
    // Scalar-Array and Array-Scalar arithmetic operators.
    ADD_SCALAR_ARRAY,  // scalar + array
    ADD_ARRAY_SCALAR,  // array + scalar
    SUB_SCALAR_ARRAY,  // scalar - array
    SUB_ARRAY_SCALAR,  // array - scalar
    MUL_SCALAR_ARRAY,  // scalar * array
    MUL_ARRAY_SCALAR,  // array * scalar
    MUL_VECTOR_MATRIX, // vector * matrix
    MUL_MATRIX_VECTOR, // matrix * vector
    SCALAR_PRODUCT,    // vector * vector
    MATRIX_PRODUCT,    // matrix * matrix
    DIV_SCALAR_ARRAY,  // scalar / array
    DIV_ARRAY_SCALAR,  // array / scalar
    POW_SCALAR_ARRAY,  // scalar ^ array
    POW_ARRAY_SCALAR,  // array ^ scalar
    POW_MATRIX,        // matrix ^ Integer
    // Unary arithmetic operators.
    UMINUS,            // -
    // Logic operators.
    AND,               // and
    OR,                // or
    NOT,               // not
    // Relational operators.
    LESS,              // <
    LESSEQ,            // <=
    GREATER,           // >
    GREATEREQ,         // >=
    EQUAL,             // ==
    NEQUAL,            // <>
    USERDEFINED        // Overloaded operator.
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

  function toDAE
    input Operator op;
    output DAE.Operator daeOp;
  protected
    DAE.Type ty;
  algorithm
    ty := Type.toDAE(op.ty);

    daeOp := match op.op
      case Op.ADD               then DAE.ADD(ty);
      case Op.SUB               then DAE.SUB(ty);
      case Op.MUL               then DAE.MUL(ty);
      case Op.DIV               then DAE.DIV(ty);
      case Op.POW               then DAE.POW(ty);
      case Op.ADD_SCALAR_ARRAY  then DAE.ADD(ty);
      case Op.ADD_ARRAY_SCALAR  then DAE.ADD(ty);
      case Op.SUB_SCALAR_ARRAY  then DAE.SUB(ty);
      case Op.SUB_ARRAY_SCALAR  then DAE.SUB(ty);
      case Op.MUL_SCALAR_ARRAY  then DAE.MUL(ty);
      case Op.MUL_ARRAY_SCALAR  then DAE.MUL(ty);
      case Op.MUL_VECTOR_MATRIX then DAE.MUL(ty);
      case Op.MUL_MATRIX_VECTOR then DAE.MUL(ty);
      case Op.SCALAR_PRODUCT    then DAE.MUL_SCALAR_PRODUCT(ty);
      case Op.MATRIX_PRODUCT    then DAE.MUL_MATRIX_PRODUCT(ty);
      case Op.DIV_SCALAR_ARRAY  then DAE.DIV(ty);
      case Op.DIV_ARRAY_SCALAR  then DAE.DIV(ty);
      case Op.POW_SCALAR_ARRAY  then DAE.POW_SCALAR_ARRAY(ty);
      case Op.POW_ARRAY_SCALAR  then DAE.POW_ARRAY_SCALAR(ty);
      case Op.POW_MATRIX        then DAE.POW_ARR(ty);
      case Op.UMINUS            then DAE.UMINUS(ty);
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
          Error.assertion(false, getInstanceName() + " got unknown type.", sourceInfo());
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

  function symbol
    input Operator op;
    input String spacing = " ";
    output String symbol;
  algorithm
    symbol := match op.op
      case Op.ADD               then "+";
      case Op.SUB               then "-";
      case Op.MUL               then ".*";
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
      //case Op.USERDEFINED      then "Userdefined:" + Absyn.pathString(op.fqName);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type.", sourceInfo());
        then
          fail();
    end match;

    symbol := spacing + symbol + spacing;
  end symbol;

  function toString
    input Operator op;
  algorithm
    symbol(op);
  end toString;

  function priority
    input Operator op;
    input Boolean lhs;
    output Integer priority;
  algorithm
    priority := match op.op
      case Op.ADD              then if lhs then 5 else 6;
      case Op.SUB              then 5;
      case Op.MUL              then 2;
      case Op.DIV              then 2;
      case Op.POW              then 1;
      case Op.ADD_EW           then if lhs then 5 else 6;
      case Op.SUB_EW           then 5;
      case Op.MUL_EW           then if lhs then 2 else 3;
      case Op.DIV_EW           then 2;
      case Op.POW_EW           then 1;
      //case MUL_ARRAY_SCALAR() then if lhs then 2 else 3;
      //case ADD_ARRAY_SCALAR() then if lhs then 5 else 6;
      //case SUB_SCALAR_ARRAY() then 5;
      //case SCALAR_PRODUCT()   then if lhs then 2 else 3;
      //case MATRIX_PRODUCT()   then if lhs then 2 else 3;
      //case DIV_ARRAY_SCALAR() then 2;
      //case DIV_SCALAR_ARRAY() then 2;
      //case POW_ARRAY_SCALAR() then 1;
      //case POW_SCALAR_ARRAY() then 1;
      //case POW_ARR()          then 1;
      case Op.AND              then 8;
      case Op.OR               then 9;
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

  function makeLessEq
    input Type ty;
    output Operator op = OPERATOR(ty, Op.LESSEQ);
  end makeLessEq;

  function makeEqual
    input Type ty;
    output Operator op = OPERATOR(ty, Op.EQUAL);
  end makeEqual;

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

annotation(__OpenModelica_Interface="frontend");
end NFOperator;
