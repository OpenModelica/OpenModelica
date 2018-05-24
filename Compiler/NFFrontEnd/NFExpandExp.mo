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

encapsulated uniontype NFExpandExp
  import Expression = NFExpression;

protected
  import RangeIterator = NFRangeIterator;
  import Subscript = NFSubscript;
  import Type = NFType;
  import NFCall.Call;
  import Dimension = NFDimension;
  import ComponentRef = NFComponentRef;
  import NFFunction.Function;
  import Operator = NFOperator;
  import Ceval = NFCeval;

public
  function expand
    input output Expression exp;
  algorithm
    exp := match exp
      local
        RangeIterator range_iter;
        list<Expression> expl;

      case Expression.CREF(ty = Type.ARRAY()) then expandCref(exp);

      case Expression.ARRAY(ty = Type.ARRAY(dimensions = _ :: _ :: {}))
        algorithm
          exp.elements := list(expand(e) for e in exp.elements);
        then
          exp;

      case Expression.ARRAY() then exp;

      case Expression.RANGE()
        algorithm
          range_iter := RangeIterator.fromExp(exp);
        then
          Expression.ARRAY(exp.ty, RangeIterator.toList(range_iter));

      case Expression.CALL() then expandCall(exp.call, exp);
      case Expression.BINARY() then expandBinary(exp.exp1, exp.operator, exp.exp2);
      case Expression.UNARY() then expandUnary(exp.exp, exp.operator);
      case Expression.LBINARY() then expandLogicalBinary(exp.exp1, exp.operator, exp.exp2);
      case Expression.LUNARY() then expandLogicalUnary(exp.exp, exp.operator);

      case Expression.CAST() then expandCast(exp.exp, exp.ty);

      else if Type.isArray(Expression.typeOf(exp)) then expandGeneric(exp) else exp;
    end match;
  end expand;

  function expandCref
    input Expression crefExp;
    output Expression arrayExp;
  protected
    list<list<list<Subscript>>> subs;
  algorithm
    arrayExp := match crefExp
      case Expression.CREF(cref = ComponentRef.CREF())
        algorithm
          subs := expandCref2(crefExp.cref);

          if listEmpty(subs) then
            arrayExp := Expression.ARRAY(Type.ARRAY(Type.arrayElementType(crefExp.ty), {Dimension.fromInteger(0)}), {});
          else
            arrayExp := expandCref3(subs, crefExp.cref, Type.arrayElementType(crefExp.ty));
          end if;
        then
          arrayExp;

      else crefExp;
    end match;
  end expandCref;

protected
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
      case {} then Expression.CREF(crefType, ComponentRef.setSubscriptsList(accum, cref));
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
          Expression.ARRAY(arr_ty, expl);
    end match;
  end expandCref4;

  function expandCall
    input Call call;
    input Expression exp;
    output Expression outExp;
  algorithm
    outExp := matchcontinue call
      case Call.TYPED_CALL()
        guard Function.isBuiltin(call.fn) and not Function.isImpure(call.fn)
        then expandBuiltinCall(call.fn, call.arguments);

      else expandGeneric(exp);
    end matchcontinue;
  end expandCall;

  function expandBuiltinCall
    input Function fn;
    input list<Expression> args;
    output Expression outExp;
  protected
    Absyn.Path fn_path = Function.nameConsiderBuiltin(fn);
  algorithm
    outExp := match Absyn.pathFirstIdent(fn_path)
      case "cat" then expandBuiltinCat(args);
      case "promote" then expandBuiltinPromote(args);
    end match;
  end expandBuiltinCall;

  function expandBuiltinCat
    input list<Expression> args;
    output Expression exp;
  algorithm
    // This relies on the fact that Ceval.evalBuiltinCat doesn't actually do any
    // actual constant evaluation, and works on non-constant arrays too as long
    // as they're expanded.
    exp := Ceval.evalBuiltinCat(listHead(args),
      list(expand(arg) for arg in listRest(args)), Ceval.EvalTarget.IGNORE_ERRORS());
  end expandBuiltinCat;

  function expandBuiltinPromote
    input list<Expression> args;
    output Expression exp;
  protected
    Integer n;
    Expression eexp, nexp;
  algorithm
    eexp :: nexp :: {} := args;
    Expression.INTEGER(value = n) := nexp;
    eexp := expand(eexp);
    exp := Expression.promote(eexp, Expression.typeOf(eexp), n);
  end expandBuiltinPromote;

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
    expl1 := Expression.arrayElements(expand(exp1));
    expl2 := Expression.arrayElements(expand(exp2));
    ty := Operator.typeOf(op);
    eop := Operator.setType(Type.unliftArray(ty), op);
    if Type.dimensionCount(ty) > 1 then
      expl := list(expandBinaryElementWise(e1, eop, e2) threaded for e1 in expl1, e2 in expl2);
    else
      expl := list(makeBinaryOp(e1, eop, e2) threaded for e1 in expl1, e2 in expl2);
    end if;

    exp := Expression.ARRAY(Operator.typeOf(op), expl);
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
    exp := Expression.mapArrayElements(exp, function makeBinaryOp(op = eop, exp1 = exp1));
  end expandBinaryScalarArray;

  function makeScalarArrayBinary_traverser
    input Expression exp1;
    input Operator op;
    input Expression exp2;
    output Expression exp;
  algorithm
    exp := match exp2
      case Expression.ARRAY() then exp2;
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
    exp := Expression.mapArrayElements(exp, function makeBinaryOp(op = eop, exp2 = exp2));
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
    Expression.ARRAY(Type.ARRAY(ty, {m, _}), expl) := Expression.transposeArray(expand(exp2));
    ty := Type.ARRAY(ty, {m});

    if listEmpty(expl) then
      exp := Expression.makeZero(ty);
    else
      e1 := expand(exp1);
      // c[i] = a * b[:, i] for i in 1:m
      expl := list(makeScalarProduct(e1, e2) for e2 in expl);
      exp := Expression.ARRAY(ty, expl);
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
    Expression.ARRAY(Type.ARRAY(ty, {n, _}), expl) := expand(exp1);
    ty := Type.ARRAY(ty, {n});

    if listEmpty(expl) then
      exp := Expression.makeZero(ty);
    else
      e2 := expand(exp2);
      // c[i] = a[i, :] * b for i in 1:n
      expl := list(makeScalarProduct(e1, e2) for e1 in expl);
      exp := Expression.ARRAY(ty, expl);
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
    Expression.ARRAY(ty, expl1) := exp1;
    Expression.ARRAY( _, expl2) := exp2;
    tyUnlift := Type.unliftArray(ty);

    if listEmpty(expl1) then
      // Scalar product of two empty arrays. The result is defined in the spec
      // by sum, so we return 0 since that's the default value of sum.
      exp := Expression.makeZero(tyUnlift);
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
    Expression.ARRAY(Type.ARRAY(ty, {n, _}), expl1) := exp1;
    // Transpose the second matrix. This makes it easier to do the multiplication,
    // since we can do row-row multiplications instead of row-column.
    Expression.ARRAY(Type.ARRAY(dimensions = {p, _}), expl2) := Expression.transposeArray(exp2);
    mat_ty := Type.ARRAY(ty, {n, p});

    if listEmpty(expl2) then
      // If any of the matrices' dimensions are zero, the result will be a matrix
      // of zeroes (the default value of sum). Only expl2 needs to be checked here,
      // the normal case can handle expl1 being empty.
      exp := Expression.makeZero(mat_ty);
    else
      // c[i, j] = a[i, :] * b[:, j] for i in 1:n, j in 1:p.
      row_ty := Type.ARRAY(ty, {p});
      expl1 := list(Expression.ARRAY(row_ty, makeBinaryMatrixProduct2(e, expl2)) for e in expl1);
      exp := Expression.ARRAY(mat_ty, expl1);
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
      case Expression.INTEGER(0)
        algorithm
          n := Dimension.size(listHead(Type.arrayDims(Operator.typeOf(op))));
        then
          Expression.makeIdentityMatrix(n, Type.REAL());

      // a ^ n where n is a literal value.
      case Expression.INTEGER(n) then expandBinaryPowMatrix2(expand(exp1), n);

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
    if Expression.isScalarLiteral(exp1) and Expression.isScalarLiteral(exp2) then
      exp := Ceval.evalBinaryOp(exp1, op, exp2);
    else
      exp := Expression.BINARY(exp1, op, exp2);
    end if;
  end makeBinaryOp;

  function expandUnary
    input Expression exp;
    input Operator op;
    output Expression outExp;
  algorithm
    outExp := expand(exp);
    outExp := Expression.mapArrayElements(outExp, function makeUnaryOp(op = op));
  end expandUnary;

  function makeUnaryOp
    input Expression exp1;
    input Operator op;
    output Expression exp = Expression.UNARY(op, exp1);
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
    expl1 := Expression.arrayElements(expand(exp1));
    expl2 := Expression.arrayElements(expand(exp2));
    ty := Operator.typeOf(op);

    if Type.dimensionCount(ty) > 1 then
      eop := Operator.setType(Type.unliftArray(ty), op);
      expl := list(expandLogicalBinary(e1, eop, e2) threaded for e1 in expl1, e2 in expl2);
    else
      expl := list(Expression.LBINARY(e1, op, e2) threaded for e1 in expl1, e2 in expl2);
    end if;

    exp := Expression.ARRAY(Operator.typeOf(op), expl);
  end expandLogicalBinary;

  function expandLogicalUnary
    input Expression exp;
    input Operator op;
    output Expression outExp;
  algorithm
    outExp := expand(exp);
    outExp := Expression.mapArrayElements(outExp, function makeLogicalUnaryOp(op = op));
  end expandLogicalUnary;

  function makeLogicalUnaryOp
    input Expression exp1;
    input Operator op;
    output Expression exp = Expression.LUNARY(op, exp1);
  end makeLogicalUnaryOp;

  function expandCast
    input Expression exp;
    input Type ty;
    output Expression outExp;
  protected
    Type ety = Type.arrayElementType(ty);
  algorithm
    outExp := expand(exp);
    outExp := Expression.mapArrayElements(outExp, function Expression.typeCast(castTy = ety));
  end expandCast;

  function expandGeneric
    input Expression exp;
    output Expression outExp;
  protected
    Type ty;
    list<Dimension> dims;
    list<list<Expression>> subs;
  algorithm
    ty := Expression.typeOf(exp);
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
          Expression.ARRAY(ty, expl);

      case {}
        algorithm
          outExp := exp;
          for s in listReverse(accum) loop
            outExp := Expression.applyIndexSubscript(s, outExp);
          end for;
        then
          outExp;

    end match;
  end expandGeneric2;

annotation(__OpenModelica_Interface="frontend");
end NFExpandExp;
