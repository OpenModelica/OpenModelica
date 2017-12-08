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

  record ADD
    Type ty;
  end ADD;

  record SUB
    Type ty;
  end SUB;

  record MUL
    Type ty;
  end MUL;

  record DIV
    Type ty;
  end DIV;

  record POW
    Type ty;
  end POW;

  record UMINUS
    Type ty;
  end UMINUS;

  record UMINUS_ARR
    Type ty;
  end UMINUS_ARR;

  record ADD_ARR
    Type ty;
  end ADD_ARR;

  record SUB_ARR
    Type ty;
  end SUB_ARR;

  record MUL_ARR "Element-wise array multiplication"
    Type ty;
  end MUL_ARR;

  record DIV_ARR
    Type ty;
  end DIV_ARR;

  record MUL_ARRAY_SCALAR " {a,b,c} * s"
    Type ty "type of the array" ;
  end MUL_ARRAY_SCALAR;

  record ADD_ARRAY_SCALAR " {a,b,c} .+ s"
    Type ty "type of the array";
  end ADD_ARRAY_SCALAR;

  record SUB_SCALAR_ARRAY "s .- {a,b,c}"
    Type ty "type of the array" ;
  end SUB_SCALAR_ARRAY;

  record MUL_SCALAR_PRODUCT " {a,b,c} * {c,d,e} => a*c+b*d+c*e"
    Type ty "type of the array" ;
  end MUL_SCALAR_PRODUCT;

  record MUL_MATRIX_PRODUCT "M1 * M2, matrix dot product"
    Type ty "{{..},..}  {{..},{..}}" ;
  end MUL_MATRIX_PRODUCT;

  record DIV_ARRAY_SCALAR "{a, b} / c"
    Type ty  "type of the array";
  end DIV_ARRAY_SCALAR;

  record DIV_SCALAR_ARRAY "c / {a,b}"
    Type ty "type of the array" ;
  end DIV_SCALAR_ARRAY;

  record POW_ARRAY_SCALAR
    Type ty "type of the array" ;
  end POW_ARRAY_SCALAR;

  record POW_SCALAR_ARRAY
    Type ty "type of the array" ;
  end POW_SCALAR_ARRAY;

  record POW_ARR "Power of a matrix: {{1,2,3},{4,5.0,6},{7,8,9}}^2"
    Type ty "type of the array";
  end POW_ARR;

  record POW_ARR2 "elementwise power of arrays: {1,2,3}.^{3,2,1}"
    Type ty "type of the array";
  end POW_ARR2;

  record AND
    Type ty;
  end AND;

  record OR
    Type ty;
  end OR;

  record NOT
    Type ty;
  end NOT;

  record LESS
    Type ty;
  end LESS;

  record LESSEQ
    Type ty;
  end LESSEQ;

  record GREATER
    Type ty;
  end GREATER;

  record GREATEREQ
    Type ty;
  end GREATEREQ;

  record EQUAL
    Type ty;
  end EQUAL;

  record NEQUAL
    Type ty;
  end NEQUAL;

  record USERDEFINED
    Absyn.Path fqName "The FQ name of the overloaded operator function" ;
  end USERDEFINED;

  function compare
    input Operator op1;
    input Operator op2;
    output Integer comp;
  algorithm
    comp := match (op1, op2)
      case (USERDEFINED(), USERDEFINED())
        then Absyn.pathCompare(op1.fqName, op2.fqName);

      else Util.intCompare(valueConstructor(op1), valueConstructor(op2));
    end match;
  end compare;

  function fromAbsyn
    input Absyn.Operator inOperator;
    output Operator outOperator;
  algorithm
    outOperator := match(inOperator)
      case Absyn.ADD() then Operator.ADD(Type.UNKNOWN());
      case Absyn.SUB() then Operator.SUB(Type.UNKNOWN());
      case Absyn.MUL() then Operator.MUL(Type.UNKNOWN());
      case Absyn.DIV() then Operator.DIV(Type.UNKNOWN());
      case Absyn.POW() then Operator.POW(Type.UNKNOWN());
      case Absyn.UPLUS() then Operator.ADD(Type.UNKNOWN());
      case Absyn.UMINUS() then Operator.UMINUS(Type.UNKNOWN());
      case Absyn.ADD_EW() then Operator.ADD_ARR(Type.UNKNOWN());
      case Absyn.SUB_EW() then Operator.SUB_ARR(Type.UNKNOWN());
      case Absyn.MUL_EW() then Operator.MUL_ARR(Type.UNKNOWN());
      case Absyn.DIV_EW() then Operator.DIV_ARR(Type.UNKNOWN());
      case Absyn.POW_EW() then Operator.POW_ARR2(Type.UNKNOWN());
      case Absyn.UPLUS_EW() then Operator.ADD(Type.UNKNOWN());
      case Absyn.UMINUS_EW() then Operator.UMINUS(Type.UNKNOWN());
      // logical have boolean type
      case Absyn.AND() then Operator.AND(Type.BOOLEAN());
      case Absyn.OR() then Operator.OR(Type.BOOLEAN());
      case Absyn.NOT() then Operator.NOT(Type.BOOLEAN());
      // relational have boolean type too
      case Absyn.LESS() then Operator.LESS(Type.BOOLEAN());
      case Absyn.LESSEQ() then Operator.LESSEQ(Type.BOOLEAN());
      case Absyn.GREATER() then Operator.GREATER(Type.BOOLEAN());
      case Absyn.GREATEREQ() then Operator.GREATEREQ(Type.BOOLEAN());
      case Absyn.EQUAL() then Operator.EQUAL(Type.BOOLEAN());
      case Absyn.NEQUAL() then Operator.NEQUAL(Type.BOOLEAN());
    end match;
  end fromAbsyn;

  function toDAE
    input Operator op;
    output DAE.Operator daeOp;
  algorithm
    daeOp := match op
      case ADD() then DAE.ADD(Type.toDAE(op.ty));
      case SUB() then DAE.SUB(Type.toDAE(op.ty));
      case MUL() then DAE.MUL(Type.toDAE(op.ty));
      case DIV() then DAE.DIV(Type.toDAE(op.ty));
      case POW() then DAE.POW(Type.toDAE(op.ty));
      case UMINUS() then DAE.UMINUS(Type.toDAE(op.ty));
      case UMINUS_ARR() then DAE.UMINUS_ARR(Type.toDAE(op.ty));
      case ADD_ARR() then DAE.ADD_ARR(Type.toDAE(op.ty));
      case SUB_ARR() then DAE.SUB_ARR(Type.toDAE(op.ty));
      case MUL_ARR() then DAE.MUL_ARR(Type.toDAE(op.ty));
      case DIV_ARR() then DAE.DIV_ARR(Type.toDAE(op.ty));
      case MUL_ARRAY_SCALAR() then DAE.MUL_ARRAY_SCALAR(Type.toDAE(op.ty));
      case ADD_ARRAY_SCALAR() then DAE.ADD_ARRAY_SCALAR(Type.toDAE(op.ty));
      case SUB_SCALAR_ARRAY() then DAE.SUB_SCALAR_ARRAY(Type.toDAE(op.ty));
      case MUL_SCALAR_PRODUCT() then DAE.MUL_SCALAR_PRODUCT(Type.toDAE(op.ty));
      case MUL_MATRIX_PRODUCT() then DAE.MUL_MATRIX_PRODUCT(Type.toDAE(op.ty));
      case DIV_ARRAY_SCALAR() then DAE.DIV_ARRAY_SCALAR(Type.toDAE(op.ty));
      case DIV_SCALAR_ARRAY() then DAE.DIV_SCALAR_ARRAY(Type.toDAE(op.ty));
      case POW_ARRAY_SCALAR() then DAE.POW_ARRAY_SCALAR(Type.toDAE(op.ty));
      case POW_SCALAR_ARRAY() then DAE.POW_SCALAR_ARRAY(Type.toDAE(op.ty));
      case POW_ARR() then DAE.POW_ARR(Type.toDAE(op.ty));
      case POW_ARR2() then DAE.POW_ARR2(Type.toDAE(op.ty));
      case AND() then DAE.AND(Type.toDAE(op.ty));
      case OR() then DAE.OR(Type.toDAE(op.ty));
      case NOT() then DAE.NOT(Type.toDAE(op.ty));
      case LESS() then DAE.LESS(Type.toDAE(op.ty));
      case LESSEQ() then DAE.LESSEQ(Type.toDAE(op.ty));
      case GREATER() then DAE.GREATER(Type.toDAE(op.ty));
      case GREATEREQ() then DAE.GREATEREQ(Type.toDAE(op.ty));
      case EQUAL() then DAE.EQUAL(Type.toDAE(op.ty));
      case NEQUAL() then DAE.NEQUAL(Type.toDAE(op.ty));
      case USERDEFINED() then DAE.USERDEFINED(op.fqName);
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type.");
        then
          fail();
    end match;
  end toDAE;

  function typeOf
    input Operator op;
    output Type ty;
  algorithm
    ty := match op
      case ADD() then op.ty;
      case SUB() then op.ty;
      case MUL() then op.ty;
      case DIV() then op.ty;
      case POW() then op.ty;
      case UMINUS() then op.ty;
      case UMINUS_ARR() then op.ty;
      case ADD_ARR() then op.ty;
      case SUB_ARR() then op.ty;
      case MUL_ARR() then op.ty;
      case DIV_ARR() then op.ty;
      case MUL_ARRAY_SCALAR() then op.ty;
      case ADD_ARRAY_SCALAR() then op.ty;
      case SUB_SCALAR_ARRAY() then op.ty;
      case MUL_SCALAR_PRODUCT() then op.ty;
      case MUL_MATRIX_PRODUCT() then op.ty;
      case DIV_ARRAY_SCALAR() then op.ty;
      case DIV_SCALAR_ARRAY() then op.ty;
      case POW_ARRAY_SCALAR() then op.ty;
      case POW_SCALAR_ARRAY() then op.ty;
      case POW_ARR() then  op.ty;
      case POW_ARR2() then op.ty;
      case AND() then op.ty;
      case OR() then op.ty;
      case NOT() then  op.ty;
      case LESS() then op.ty;
      case LESSEQ() then op.ty;
      case GREATER() then op.ty;
      case GREATEREQ() then op.ty;
      case EQUAL() then op.ty;
      case NEQUAL() then op.ty;
      case USERDEFINED() then Type.UNKNOWN();
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type.");
        then
          fail();
    end match;
  end typeOf;

  function setType
    input Type ty;
    input Operator op;
    output Operator newOp;
  algorithm
    newOp := match op
      case ADD() then ADD(ty);
      case SUB() then SUB(ty);
      case MUL() then MUL(ty);
      case DIV() then DIV(ty);
      case POW() then POW(ty);
      case UMINUS() then UMINUS(ty);
      case UMINUS_ARR() then UMINUS_ARR(ty);
      case ADD_ARR() then ADD_ARR(ty);
      case SUB_ARR() then SUB_ARR(ty);
      case MUL_ARR() then MUL_ARR(ty);
      case DIV_ARR() then DIV_ARR(ty);
      case MUL_ARRAY_SCALAR() then MUL_ARRAY_SCALAR(ty);
      case ADD_ARRAY_SCALAR() then ADD_ARRAY_SCALAR(ty);
      case SUB_SCALAR_ARRAY() then SUB_SCALAR_ARRAY(ty);
      case MUL_SCALAR_PRODUCT() then MUL_SCALAR_PRODUCT(ty);
      case MUL_MATRIX_PRODUCT() then MUL_MATRIX_PRODUCT(ty);
      case DIV_ARRAY_SCALAR() then DIV_ARRAY_SCALAR(ty);
      case DIV_SCALAR_ARRAY() then DIV_SCALAR_ARRAY(ty);
      case POW_ARRAY_SCALAR() then POW_ARRAY_SCALAR(ty);
      case POW_SCALAR_ARRAY() then POW_SCALAR_ARRAY(ty);
      case POW_ARR() then POW_ARR(ty);
      case POW_ARR2() then POW_ARR2(ty);
      case AND() then AND(ty);
      case OR() then OR(ty);
      case NOT() then NOT(ty);
      case LESS() then LESS(ty);
      case LESSEQ() then LESSEQ(ty);
      case GREATER() then GREATER(ty);
      case GREATEREQ() then GREATEREQ(ty);
      case EQUAL() then EQUAL(ty);
      case NEQUAL() then NEQUAL(ty);
      case USERDEFINED() then op;
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type.");
        then
          fail();
    end match;
  end setType;

  function isBinaryElementWise
    input Operator op;
    output Boolean isElementWise;
  algorithm
    isElementWise := match op
      case ADD_ARR() then true;
      case SUB_ARR() then true;
      case MUL_ARR() then true;
      case DIV_ARR() then true;
      case POW_ARR2() then true;
      else false;
    end match;
  end isBinaryElementWise;

  function symbol
    input Operator op;
    input String spacing = " ";
    output String symbol;
  algorithm
    symbol := match op
      case ADD()                then  "+";
      case SUB()                then  "-";
      case MUL()                then ".*";
      case DIV()                then  "/";
      case POW()                then  "^";
      case UMINUS()             then  "-";
      case UMINUS_ARR()         then  "-";
      case ADD_ARR()            then  "+";
      case SUB_ARR()            then  "-";
      case MUL_ARR()            then ".*";
      case DIV_ARR()            then "./";
      case MUL_ARRAY_SCALAR()   then  "*";
      case ADD_ARRAY_SCALAR()   then ".+";
      case SUB_SCALAR_ARRAY()   then ".-";
      case MUL_SCALAR_PRODUCT() then  "*";
      case MUL_MATRIX_PRODUCT() then  "*";
      case DIV_ARRAY_SCALAR()   then  "/";
      case DIV_SCALAR_ARRAY()   then "./";
      case POW_ARRAY_SCALAR()   then ".^";
      case POW_SCALAR_ARRAY()   then ".^";
      case POW_ARR()            then  "^";
      case POW_ARR2()           then ".^";
      case AND()                then "and";
      case OR()                 then "or";
      case NOT()                then "not";
      case LESS()               then "<";
      case LESSEQ()             then "<=";
      case GREATER()            then ">";
      case GREATEREQ()          then ">=";
      case EQUAL()              then "==";
      case NEQUAL()             then "<>";
      case USERDEFINED()        then "Userdefined:" + Absyn.pathString(op.fqName);
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type.");
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
    priority := match op
      case ADD() then if lhs then 5 else 6;
      case SUB() then 5;
      case MUL() then 2;
      case DIV() then 2;
      case POW() then 1;
      case ADD_ARR() then if lhs then 5 else 6;
      case SUB_ARR() then 5;
      case MUL_ARR() then if lhs then 2 else 3;
      case DIV_ARR() then 2;
      case MUL_ARRAY_SCALAR() then if lhs then 2 else 3;
      case ADD_ARRAY_SCALAR() then if lhs then 5 else 6;
      case SUB_SCALAR_ARRAY() then 5;
      case MUL_SCALAR_PRODUCT() then if lhs then 2 else 3;
      case MUL_MATRIX_PRODUCT() then if lhs then 2 else 3;
      case DIV_ARRAY_SCALAR() then 2;
      case DIV_SCALAR_ARRAY() then 2;
      case POW_ARRAY_SCALAR() then 1;
      case POW_SCALAR_ARRAY() then 1;
      case POW_ARR() then 1;
      case POW_ARR2() then 1;
      case AND() then 8;
      case OR() then 9;
      else 0;
    end match;
  end priority;

  function isAssociative
    input Operator op;
    output Boolean isAssociative;
  algorithm
    isAssociative := match op
      case ADD() then true;
      case ADD_ARR() then true;
      case ADD_ARRAY_SCALAR() then true;
      case MUL_ARR() then true;
      case MUL_ARRAY_SCALAR() then true;
      else false;
    end match;
  end isAssociative;

annotation(__OpenModelica_Interface="frontend");
end NFOperator;
