/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ExpressionBasics
" file:        ExpressionBasics.mo
  package:     ExpressionBasics
  description: ExpressionBasics


  This file contains the module ExpressionDump, which contains the most basic functions
  to print and work with DAE.Expression."

// public imports
import DAE;
protected
import AbsynUtil;
import ExpressionDumpTpl;
import List;
import Tpl;
import Util;

public function printExpStr
"This function prints a complete expression."
  input DAE.Exp e;
  output String s;
algorithm
  s := Tpl.tplString2(ExpressionDumpTpl.dumpExp, e, "\"");
end printExpStr;

public function dimensionString
  "Returns a string representation of an array dimension."
  input DAE.Dimension dim;
  output String str;
algorithm
  str := match(dim)
    local
      String s;
      Integer x;
      Absyn.Path p;
      DAE.Exp e;
      Integer size;
    case DAE.DIM_UNKNOWN() then ":";

    case DAE.DIM_ENUM(enumTypeName = p)
      algorithm
        s := AbsynUtil.pathString(p);
      then
        s;

    case DAE.DIM_BOOLEAN() then "Boolean";

    case DAE.DIM_INTEGER(integer = x)
      algorithm
        s := intString(x);
      then
        s;

    case DAE.DIM_EXP(exp = e)
      algorithm
        s := printExpStr(e);
      then
        s;
  end match;
end dimensionString;

public function dimensionsString
  "Returns a string representation of an array dimension."
  input DAE.Dimensions dims;
  output String str;
algorithm
  str := stringDelimitList(List.map(dims,dimensionString),",");
end dimensionsString;

public function shouldParenthesize
  "Determines whether an operand in an expression needs parentheses around it."
  input DAE.Exp inOperand;
  input DAE.Exp inOperator;
  input Boolean inLhs;
  output Boolean outShouldParenthesize;
algorithm
  outShouldParenthesize := match inOperand
    local
      Integer diff;

    case DAE.UNARY() then true;

    else
      algorithm
        diff := Util.intCompare(priority(inOperand, inLhs),
                               priority(inOperator, inLhs));
      then
        shouldParenthesize2(diff, inOperand, inLhs);

  end match;
end shouldParenthesize;

protected function shouldParenthesize2
  input Integer inPrioDiff;
  input DAE.Exp inOperand;
  input Boolean inLhs;
  output Boolean outShouldParenthesize;
algorithm
  outShouldParenthesize := match inPrioDiff
    case 1 then true;
    case 0 then if inLhs then isNonAssociativeExp(inOperand) else
                              not isAssociativeExp(inOperand);
    else false;
  end match;
end shouldParenthesize2;

protected function isAssociativeExp
  "Determines whether the given expression represents an associative operation or not."
  input DAE.Exp inExp;
  output Boolean outIsAssociative;
algorithm
  outIsAssociative := match(inExp)
    local
      DAE.Operator op;

    case DAE.BINARY(operator = op) then isAssociativeOp(op);
    case DAE.LBINARY() then true;
    else false;
  end match;
end isAssociativeExp;

protected function isAssociativeOp
  "Determines whether the given operator is associative or not."
  input DAE.Operator inOperator;
  output Boolean outIsAssociative;
algorithm
  outIsAssociative := match inOperator
    case DAE.ADD() then true;
    case DAE.MUL() then true;
    case DAE.ADD_ARR() then true;
    case DAE.MUL_ARRAY_SCALAR() then true;
    case DAE.ADD_ARRAY_SCALAR() then true;
    else false;
  end match;
end isAssociativeOp;

protected function isNonAssociativeExp
  input DAE.Exp exp;
  output Boolean isNonAssociative;
algorithm
  isNonAssociative := match exp
    case DAE.BINARY() then isNonAssociativeOp(exp.operator);
    else false;
  end match;
end isNonAssociativeExp;

protected function isNonAssociativeOp
  input DAE.Operator inOperator;
  output Boolean isNonAssociative;
algorithm
  isNonAssociative := match inOperator
    case DAE.POW() then true;
    case DAE.POW_ARRAY_SCALAR() then true;
    case DAE.POW_SCALAR_ARRAY() then true;
    case DAE.POW_ARR() then true;
    case DAE.POW_ARR2() then true;
    else false;
  end match;
end isNonAssociativeOp;

public function priority
  "Returns an integer priority given an expression, which is used by
   ExpressionDumpTpl to add parentheses when dumping expressions. The inLhs
   argument should be true if the expression occurs on the left side of a binary
   operation, otherwise false. This is because we don't need to add parentheses
   to expressions such as x * y / z, but x / (y * z) needs them, so the
   priorities of some binary operations differ depending on which side they are."
  input DAE.Exp inExp;
  input Boolean inLhs;
  output Integer outPriority;
algorithm
  outPriority := match(inExp, inLhs)
    local
      DAE.Operator op;

    case (DAE.BINARY(operator = op), false) then priorityBinopRhs(op);
    case (DAE.BINARY(operator = op), true) then priorityBinopLhs(op);
    case (DAE.RCONST(), _) guard inExp.real < 0.0 then 4; // Same as unary minus of a real literal
    case (DAE.UNARY(), _) then 4;
    case (DAE.LBINARY(operator = op), _) then priorityLBinop(op);
    case (DAE.LUNARY(), _) then 7;
    case (DAE.RELATION(), _) then 6;
    case (DAE.RANGE(), _) then 10;
    case (DAE.IFEXP(), _) then 11;
    else 0;
  end match;
end priority;

protected function priorityBinopLhs
  "Returns the priority for a binary operation on the left hand side. Add and
   sub has the same priority, and mul and div too, in contrast with
   priorityBinopRhs."
  input DAE.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case DAE.ADD() then 5;
    case DAE.SUB() then 5;
    case DAE.MUL() then 2;
    case DAE.DIV() then 2;
    case DAE.POW() then 1;
    case DAE.ADD_ARR() then 5;
    case DAE.SUB_ARR() then 5;
    case DAE.MUL_ARR() then 2;
    case DAE.DIV_ARR() then 2;
    case DAE.MUL_ARRAY_SCALAR() then 2;
    case DAE.ADD_ARRAY_SCALAR() then 5;
    case DAE.SUB_SCALAR_ARRAY() then 5;
    case DAE.MUL_SCALAR_PRODUCT() then 2;
    case DAE.MUL_MATRIX_PRODUCT() then 2;
    case DAE.DIV_ARRAY_SCALAR() then 2;
    case DAE.DIV_SCALAR_ARRAY() then 2;
    case DAE.POW_ARRAY_SCALAR() then 1;
    case DAE.POW_SCALAR_ARRAY() then 1;
    case DAE.POW_ARR() then 1;
    case DAE.POW_ARR2() then 1;
  end match;
end priorityBinopLhs;

protected function priorityBinopRhs
  "Returns the priority for a binary operation on the right hand side. Add and
   sub has different priorities, and mul and div too, in contrast with
   priorityBinopLhs."
  input DAE.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case DAE.ADD() then 6;
    case DAE.SUB() then 5;
    case DAE.MUL() then 3;
    case DAE.DIV() then 2;
    case DAE.POW() then 1;
    case DAE.ADD_ARR() then 6;
    case DAE.SUB_ARR() then 5;
    case DAE.MUL_ARR() then 3;
    case DAE.DIV_ARR() then 2;
    case DAE.MUL_ARRAY_SCALAR() then 3;
    case DAE.ADD_ARRAY_SCALAR() then 6;
    case DAE.SUB_SCALAR_ARRAY() then 5;
    case DAE.MUL_SCALAR_PRODUCT() then 3;
    case DAE.MUL_MATRIX_PRODUCT() then 3;
    case DAE.DIV_ARRAY_SCALAR() then 2;
    case DAE.DIV_SCALAR_ARRAY() then 2;
    case DAE.POW_ARRAY_SCALAR() then 1;
    case DAE.POW_SCALAR_ARRAY() then 1;
    case DAE.POW_ARR() then 1;
    case DAE.POW_ARR2() then 1;
  end match;
end priorityBinopRhs;

protected function priorityLBinop
  input DAE.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case DAE.AND() then 8;
    case DAE.OR() then 9;
  end match;
end priorityLBinop;

public function evalCat<Exp>
  input Integer dim;
  input list<Exp> exps;
  input GetArrayContents getArrayContents;
  input ToString toString;
  output list<Exp> outExps;
  output list<Integer> outDims;
  partial function GetArrayContents
    input Exp e;
    output list<Exp> es;
  end GetArrayContents;
  partial function MakeArrayFromList
    input list<Exp> es;
    output Exp e;
  end MakeArrayFromList;
  partial function ToString
    input Exp e;
    output String s;
  end ToString;
protected
  list<Exp> arr;
  list<list<Exp>> arrs={};
  list<Integer> dims, firstDims={}, lastDims, reverseDims;
  list<list<Integer>> dimsLst={};
  Integer j, k, l, thisDim, lastDim;
  array<Exp> expArr;
algorithm
  true := dim >= 1;
  false := listEmpty(exps);
  if 1 == dim then
    outExps := listAppend(getArrayContents(e) for e in listReverse(exps));
    outDims := {listLength(outExps)};
    return;
  end if;
  for e in listReverse(exps) loop
    // Here we get a linear representation of all expressions in the array
    // and the dimensions necessary to build up the array again
    (arr,dims) := evalCatGetFlatArray(e, dim, getArrayContents=getArrayContents, toString=toString);
    arrs := arr::arrs;
    dimsLst := dims::dimsLst;
  end for;
  for i in 1:(dim-1) loop
    j := min(listHead(d) for d in dimsLst);

    if j <> max(listHead(d) for d in dimsLst) then
      Error.assertion(false, getInstanceName() + ": cat got uneven dimensions for dim=" + String(i) + " " + stringDelimitList(list(toString(e) for e in exps), ", "), sourceInfo());
    end if;

    firstDims := j :: firstDims;
    dimsLst := list(listRest(d) for d in dimsLst);
  end for;
  reverseDims := firstDims;
  firstDims := listReverse(firstDims);
  lastDims := list(listHead(d) for d in dimsLst);
  lastDim := sum(d for d in lastDims);
  reverseDims := lastDim::reverseDims;
  // Fill in the elements of the new array in the new order; this uses
  // an array structure for random access
  expArr := Dangerous.arrayCreateNoInit(lastDim*product(d for d in firstDims), listHead(exps));
  k := 1;
  for exps in arrs loop
    thisDim :: lastDims := lastDims;
    l := 0;
    for e in exps loop
      arrayUpdate(expArr, k+mod(l, thisDim)+(lastDim*div(l, thisDim)), e);
      l := l+1;
    end for;
    k := k + thisDim;
  end for;
  // Convert the flat array structure to a tree array structure with the
  // correct dimensions
  outExps := arrayList(expArr);
  outDims := listReverse(reverseDims);
end evalCat;

protected function evalCatGetFlatArray<Exp>
  input Exp e;
  input Integer dim;
  input GetArrayContents getArrayContents;
  input ToString toString;
  output list<Exp> outExps={};
  output list<Integer> outDims={};
  partial function GetArrayContents
    input Exp e;
    output list<Exp> es;
  end GetArrayContents;
  partial function ToString
    input Exp e;
    output String s;
  end ToString;
protected
  list<Exp> arr;
  list<Integer> dims;
  Integer i;
algorithm
  if dim == 1 then
    outExps := getArrayContents(e);
    outDims := {listLength(outExps)};
    return;
  end if;
  i := 0;
  for exp in listReverse(getArrayContents(e)) loop
    (arr, dims) := evalCatGetFlatArray(exp, dim-1, getArrayContents=getArrayContents, toString=toString);
    if listEmpty(outDims) then
      outDims := dims;
    elseif not valueEq(dims, outDims) then
      Error.assertion(false, getInstanceName() + ": Got unbalanced array from " + toString(e), sourceInfo());
    end if;
    outExps := listAppend(arr, outExps);
    i := i+1;
  end for;
  outDims := i :: outDims;
end evalCatGetFlatArray;

public function expEqual
  "Returns true if the two expressions are equal, otherwise false."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outEqual;
algorithm
  outEqual := 0==compare(inExp1, inExp2);
end expEqual;

function compare
  input DAE.Exp inExp1, inExp2;
  output Integer comp;
algorithm
  // Return true if the references are the same.
  if referenceEq(inExp1, inExp2) then
    comp := 0;
    return;
  end if;

  comp := Util.intCompare(valueConstructor(inExp1), valueConstructor(inExp2));
  // Return false if the expressions are not of the same type.
  if comp <> 0 then
    return;
  end if;

  // Otherwise, check if the expressions are equal or not.
  // Since the expressions have already been verified to be of the same type
  // above we can match on only one of them to allow the pattern matching to
  // optimize this to jump directly to the correct case.
  comp := match(inExp1)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;
      Absyn.Path p;
      DAE.Exp e, e1, e2;
      Option<DAE.Exp> oe;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mexpl;
      DAE.Operator op;
      DAE.ComponentRef cr;
      DAE.Type ty;
      list<DAE.Subscript> subs;

    case DAE.ICONST()
      algorithm
        DAE.ICONST(integer = i) := inExp2;
      then
        Util.intCompare(inExp1.integer, i);

    case DAE.RCONST()
      algorithm
        DAE.RCONST(real = r) := inExp2;
      then Util.realCompare(inExp1.real, r);

    case DAE.SCONST()
      algorithm
        DAE.SCONST(string = s) := inExp2;
      then stringCompare(inExp1.string, s);

    case DAE.BCONST()
      algorithm
        DAE.BCONST(bool = b) := inExp2;
      then Util.boolCompare(inExp1.bool, b);

    case DAE.ENUM_LITERAL()
      algorithm
        DAE.ENUM_LITERAL(name = p) := inExp2;
      then AbsynUtil.pathCompare(inExp1.name, p);

    case DAE.CREF()
      algorithm
        DAE.CREF(componentRef = cr) := inExp2;
      then ComponentReference.crefCompareGeneric(inExp1.componentRef, cr);

    case DAE.ARRAY()
      algorithm
        DAE.ARRAY(ty = ty, array = expl) := inExp2;
        comp := valueCompare(inExp1.ty, ty);
      then if 0==comp then compareList(inExp1.array, expl) else comp;

    case DAE.MATRIX()
      algorithm
        DAE.MATRIX(ty = ty, matrix = mexpl) := inExp2;
        comp := valueCompare(inExp1.ty, ty);
      then if 0==comp then compareListList(inExp1.matrix, mexpl) else comp;

    case DAE.BINARY()
      algorithm
        DAE.BINARY(exp1 = e1, operator = op, exp2 = e2) := inExp2;
        comp := operatorCompare(inExp1.operator, op);
        comp := if 0==comp then compare(inExp1.exp1, e1) else comp;
      then if 0==comp then compare(inExp1.exp2, e2) else comp;

    case DAE.LBINARY()
      algorithm
        DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2) := inExp2;
        comp := operatorCompare(inExp1.operator, op);
        comp := if 0==comp then compare(inExp1.exp1, e1) else comp;
      then if 0==comp then compare(inExp1.exp2, e2) else comp;

    case DAE.UNARY()
      algorithm
        DAE.UNARY(exp = e, operator = op) := inExp2;
        comp := operatorCompare(inExp1.operator, op);
      then if 0==comp then compare(inExp1.exp, e) else comp;

    case DAE.LUNARY()
      algorithm
        DAE.LUNARY(exp = e, operator = op) := inExp2;
        comp := operatorCompare(inExp1.operator, op);
      then if 0==comp then compare(inExp1.exp, e) else comp;

    case DAE.RELATION()
      algorithm
        DAE.RELATION(exp1 = e1, operator = op, exp2 = e2) := inExp2;
        comp := operatorCompare(inExp1.operator, op);
        comp := if 0==comp then compare(inExp1.exp1, e1) else comp;
      then if 0==comp then compare(inExp1.exp2, e2) else comp;

    case DAE.IFEXP()
      algorithm
        DAE.IFEXP(expCond = e, expThen = e1, expElse = e2) := inExp2;
        comp := compare(inExp1.expCond, e);
        comp := if 0==comp then compare(inExp1.expThen, e1) else comp;
      then if 0==comp then compare(inExp1.expElse, e2) else comp;

    case DAE.CALL()
      algorithm
        DAE.CALL(path = p, expLst = expl) := inExp2;
        comp := AbsynUtil.pathCompare(inExp1.path, p);
      then if 0==comp then compareList(inExp1.expLst, expl) else comp;

    case DAE.RECORD()
      algorithm
        DAE.RECORD(path = p, exps = expl) := inExp2;
        comp := AbsynUtil.pathCompare(inExp1.path, p);
      then if 0==comp then compareList(inExp1.exps, expl) else comp;

    case DAE.PARTEVALFUNCTION()
      algorithm
        DAE.PARTEVALFUNCTION(path = p, expList = expl) := inExp2;
        comp := AbsynUtil.pathCompare(inExp1.path, p);
      then if 0==comp then compareList(inExp1.expList, expl) else comp;

    case DAE.RANGE()
      algorithm
        DAE.RANGE(start = e1, step = oe, stop = e2) := inExp2;
        comp := compare(inExp1.start, e1);
        comp := if 0==comp then compare(inExp1.stop, e2) else comp;
      then if 0==comp then compareOpt(inExp1.step, oe) else comp;

    case DAE.TUPLE()
      algorithm
        DAE.TUPLE(PR = expl) := inExp2;
      then compareList(inExp1.PR, expl);

    case DAE.CAST()
      algorithm
        DAE.CAST(ty = ty, exp = e) := inExp2;
        comp := valueCompare(inExp1.ty, ty);
      then if 0==comp then compare(inExp1.exp, e) else comp;

    case DAE.ASUB()
      algorithm
        DAE.ASUB(exp = e, sub = subs) := inExp2;
        comp := compare(inExp1.exp, e);
      then if comp==0 then compareSubscriptList(inExp1.sub, subs) else comp;

    case DAE.RSUB()
      algorithm
        DAE.RSUB(exp = e, ix=i, fieldName=s, ty=ty) := inExp2;
        comp := Util.intCompare(inExp1.ix, i);
        comp := if comp==0 then valueCompare(inExp1.ty, ty) else comp;
        comp := if comp==0 then stringCompare(inExp1.fieldName, s) else comp;
      then if comp==0 then compare(inExp1.exp, e) else comp;

    case DAE.TSUB()
      algorithm
        DAE.TSUB(exp = e, ix=i, ty = ty) := inExp2;
        comp := Util.intCompare(inExp1.ix, i);
        comp := if 0==comp then valueCompare(inExp1.ty, ty) else comp;
      then if 0==comp then compare(inExp1.exp, e) else comp;

    case DAE.SIZE()
      algorithm
        DAE.SIZE(exp = e, sz = oe) := inExp2;
        comp := compare(inExp1.exp, e);
      then if comp==0 then compareOpt(inExp1.sz, oe) else comp;

    case DAE.REDUCTION()
      // Reductions contain too much information to compare in a sane manner.
      then valueCompare(inExp1, inExp2);

    case DAE.LIST()
      algorithm
        DAE.LIST(valList = expl) := inExp2;
      then
        compareList(inExp1.valList, expl);

    case DAE.CONS()
      algorithm
        DAE.CONS(car = e1, cdr = e2) := inExp2;
        comp := compare(inExp1.car, e1);
      then if 0==comp then compare(inExp1.cdr, e2) else comp;

    case DAE.META_TUPLE()
      algorithm
        DAE.META_TUPLE(listExp = expl) := inExp2;
      then
        compareList(inExp1.listExp, expl);

    case DAE.META_OPTION()
      algorithm
        DAE.META_OPTION(exp = oe) := inExp2;
      then
        compareOpt(inExp1.exp, oe);

    case DAE.METARECORDCALL()
      algorithm
        DAE.METARECORDCALL(path = p, args = expl) := inExp2;
        comp := AbsynUtil.pathCompare(inExp1.path, p);
      then if comp==0 then compareList(inExp1.args, expl) else comp;

    case DAE.MATCHEXPRESSION()
      then valueCompare(inExp1, inExp2);

    case DAE.BOX()
      algorithm
        DAE.BOX(exp = e) := inExp2;
      then
        compare(inExp1.exp, e);

    case DAE.UNBOX()
      algorithm
        DAE.UNBOX(exp = e) := inExp2;
      then
        compare(inExp1.exp, e);

    case DAE.SHARED_LITERAL()
      algorithm
        DAE.SHARED_LITERAL(index = i) := inExp2;
      then Util.intCompare(inExp1.index, i);

    case DAE.EMPTY()
      algorithm
        DAE.EMPTY(name=cr) := inExp2;
      then ComponentReference.crefCompareGeneric(inExp1.name, cr);

    case DAE.CODE()
      then valueCompare(inExp1, inExp2);

    else
      algorithm
        Error.addInternalError("Expression.compare failed: ctor:" + String(valueConstructor(inExp1)) + " " + printExpStr(inExp1) + " " + printExpStr(inExp2), sourceInfo());
      then fail();
  end match;
end compare;

annotation(__OpenModelica_Interface="frontend_dump");
end ExpressionBasics;
