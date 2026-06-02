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
import ComponentReferenceBasics;
import Error;
import ExpressionDumpTpl;
import List;
import MetaModelica.Dangerous;
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
  str := match dim
    local
      String s;
      Integer x;
      Absyn.Path p;
      DAE.Exp e;
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
  outIsAssociative := match inExp
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
  outPriority := match inOp
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
  outPriority := match inOp
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
  outPriority := match inOp
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
  comp := match inExp1
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
      then ComponentReferenceBasics.crefCompareGeneric(inExp1.componentRef, cr);

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
      then ComponentReferenceBasics.crefCompareGeneric(inExp1.name, cr);

    case DAE.CODE()
      then valueCompare(inExp1, inExp2);

    else
      algorithm
        Error.addInternalError("ExpressionBasics.compare failed: ctor:" + String(valueConstructor(inExp1)) + " " + printExpStr(inExp1) + " " + printExpStr(inExp2), sourceInfo());
      then fail();
  end match;
end compare;

protected function compareList
  input list<DAE.Exp> inExpl1;
  input list<DAE.Exp> inExpl2;
  output Integer comp;
protected
  Integer len1, len2;
  DAE.Exp e2;
  list<DAE.Exp> rest_expl2 = inExpl2;
algorithm
  // Check that the lists have the same length, otherwise they can't be equal.
  len1 := listLength(inExpl1);
  len2 := listLength(inExpl2);
  comp := Util.intCompare(len1, len2);
  if comp <> 0 then
    return;
  end if;

  for e1 in inExpl1 loop
    e2 :: rest_expl2 := rest_expl2;

    // Return false if the expressions are not equal.
    comp := compare(e1, e2);
    if 0 <> comp then
      return;
    end if;
  end for;

  comp := 0;
end compareList;

protected function compareListList
  input list<list<DAE.Exp>> inExpl1;
  input list<list<DAE.Exp>> inExpl2;
  output Integer comp;
protected
  list<DAE.Exp> expl2;
  list<list<DAE.Exp>> rest_expl2 = inExpl2;
  Integer len1, len2;
algorithm
  // Check that the lists have the same length, otherwise they can't be equal.
  len1 := listLength(inExpl1);
  len2 := listLength(inExpl2);
  comp := Util.intCompare(len1, len2);
  if comp <> 0 then
    return;
  end if;

  for expl1 in inExpl1 loop
    expl2 :: rest_expl2 := rest_expl2;

    // Return false if the expression lists are not equal.
    comp := compareList(expl1, expl2);
    if 0 <> comp then
      return;
    end if;
  end for;

  comp := 0;
end compareListList;

protected function compareOpt
  input Option<DAE.Exp> inExp1;
  input Option<DAE.Exp> inExp2;
  output Integer comp;
protected
  DAE.Exp e1, e2;
algorithm
  comp := match(inExp1, inExp2)
    case (NONE(), NONE()) then 0;
    case (NONE(), _) then -1;
    case (_, NONE()) then 1;
    case (SOME(e1), SOME(e2)) then compare(e1, e2);
  end match;
end compareOpt;

public function operatorCompare
"Helper function to expEqual."
  input DAE.Operator inOperator1;
  input DAE.Operator inOperator2;
  output Integer comp;
algorithm
  comp := match (inOperator1,inOperator2)
    local
      Absyn.Path p1,p2;

    case (DAE.USERDEFINED(fqName = p1),DAE.USERDEFINED(fqName = p2))
      then AbsynUtil.pathCompare(p1, p2);
    else Util.intCompare(valueConstructor(inOperator1), valueConstructor(inOperator2));
  end match;
end operatorCompare;

function compareSubscripts
  input DAE.Subscript sub1;
  input DAE.Subscript sub2;
  output Integer res;
algorithm
  if referenceEq(sub1, sub2) then
    res := 0;
  else
    res := match (sub1, sub2)
      case (DAE.Subscript.WHOLEDIM(), DAE.Subscript.WHOLEDIM()) then 0;
      case (DAE.Subscript.SLICE(), DAE.Subscript.SLICE()) then compare(sub1.exp, sub2.exp);
      case (DAE.Subscript.INDEX(), DAE.Subscript.INDEX()) then compare(sub1.exp, sub2.exp);
      case (DAE.Subscript.WHOLE_NONEXP(), DAE.Subscript.WHOLE_NONEXP()) then compare(sub1.exp, sub2.exp);
      else Util.intCompare(valueConstructor(sub1), valueConstructor(sub2));
    end match;
  end if;
end compareSubscripts;

protected function compareSubscriptList
  input list<DAE.Subscript> subs1;
  input list<DAE.Subscript> subs2;
  output Integer comp;
protected
  Integer len1, len2;
  DAE.Subscript s2;
  list<DAE.Subscript> rest_subs2 = subs2;
algorithm
  // Check that the lists have the same length, otherwise they can't be equal.
  len1 := listLength(subs1);
  len2 := listLength(subs2);
  comp := Util.intCompare(len1, len2);
  if comp <> 0 then
    return;
  end if;

  for s1 in subs1 loop
    s2 :: rest_subs2 := rest_subs2;

    // Return false if the expressions are not equal.
    comp := compareSubscripts(s1, s2);
    if 0 <> comp then
      return;
    end if;
  end for;

  comp := 0;
end compareSubscriptList;


public function subscriptInt
  "Tries to convert a subscript to an integer index."
  input DAE.Subscript inSubscript;
  output Integer outInteger = expArrayIndex(subscriptIndexExp(inSubscript));
end subscriptInt;

public function subscriptsInt
  "Tries to convert a list of subscripts to integer indices."
  input list<DAE.Subscript> inSubscripts;
  output list<Integer> outIntegers;
algorithm
  outIntegers := List.map(inSubscripts, subscriptInt);
end subscriptsInt;

public function expArrayIndex
  "Returns the array index that an expression represents as an integer."
  input DAE.Exp inExp;
  output Integer outIndex;
algorithm
  outIndex := match inExp
    case DAE.ICONST() then inExp.integer;
    case DAE.ENUM_LITERAL() then inExp.index;
    case DAE.BCONST() then if inExp.bool then 2 else 1;
  end match;
end expArrayIndex;

public function subscriptIndexExp
  "Returns the expression in a subscript index.
  If the subscript is not an index the function fails."
  input DAE.Subscript inSubscript;
  output DAE.Exp outExp;
algorithm
  DAE.INDEX(exp = outExp) := inSubscript;
end subscriptIndexExp;

public function subscriptEqual
"Returns true if two subscript lists are equal."
  input list<DAE.Subscript> inSubscriptLst1;
  input list<DAE.Subscript> inSubscriptLst2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inSubscriptLst1,inSubscriptLst2)
    local
      list<DAE.Subscript> xs1,xs2;
      DAE.Exp e1,e2;

    // both lists are empty
    case ({},{}) then true;

    // wholedims as list heads, compare the rest
    case ((DAE.WHOLEDIM() :: xs1),(DAE.WHOLEDIM() :: xs2))
      then subscriptEqual(xs1, xs2);

    // slices as heads, compare the slice exps and then compare the rest
    case ((DAE.SLICE(exp = e1) :: xs1),(DAE.SLICE(exp = e2) :: xs2))
      then if expEqual(e1, e2) then subscriptEqual(xs1, xs2) else false;

    // indexes as heads, compare the index exps and then compare the rest
    case ((DAE.INDEX(exp = e1) :: xs1),(DAE.INDEX(exp = e2) :: xs2))
      then if expEqual(e1, e2) then subscriptEqual(xs1, xs2) else false;

    case ((DAE.WHOLE_NONEXP(exp = e1) :: xs1),(DAE.WHOLE_NONEXP(exp = e2) :: xs2))
      then if expEqual(e1, e2) then subscriptEqual(xs1, xs2) else false;

    // subscripts are not equal, return false
    else false;
  end match;
end subscriptEqual;

public function printListStr
"Same as printList, except it returns
  a string instead of printing."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input String inString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString := stringDelimitList(List.map(inTypeALst,inFuncTypeTypeAToString),inString);
end printListStr;

public function printSubscriptStr "
  Print a Subscript into a String."
  input DAE.Subscript sub;
  output String outString;
algorithm
  outString := match sub
    case DAE.WHOLEDIM() then ":";
    case DAE.INDEX() then printExpStr(sub.exp);
    case DAE.SLICE() then printExpStr(sub.exp);
    case DAE.WHOLE_NONEXP() then "1:" + printExpStr(sub.exp);
  end match;
end printSubscriptStr;

public function hashExp "help function to hashExpMod"
  input DAE.Exp e;
  output Integer hash;
algorithm
 hash := matchcontinue e
   local
    Real r;
    Integer i;
    Boolean b;
    String s;
    Absyn.Path path;
    DAE.Exp e1,e2,e3;
    DAE.Operator op;
    list<DAE.Exp> expl;
    list<list<DAE.Exp>> mexpl;
    DAE.ComponentRef cr;
    DAE.ReductionIterators iters;
    DAE.ReductionInfo info;
    list<DAE.Subscript> subs;

 case DAE.ICONST(i)                                then stringHashDjb2(intString(i));
 case DAE.RCONST(r)                                then stringHashDjb2(realString(r));
 case DAE.BCONST(b)                                then stringHashDjb2(boolString(b));
 case DAE.SCONST(s)                                then stringHashDjb2(s);
 case DAE.ENUM_LITERAL(name=path)                  then stringHashDjb2(AbsynUtil.pathString(path));
 case DAE.CREF(componentRef=cr)                    then ComponentReferenceBasics.hashComponentRef(cr);

 case DAE.BINARY(e1,op,e2)                         then 1 + hashExp(e1)+hashOp(op)+hashExp(e2);
 case DAE.UNARY(op,e1)                             then 2 + hashOp(op)+hashExp(e1);
 case DAE.LBINARY(e1,op,e2)                        then 3 + hashExp(e1)+hashOp(op)+hashExp(e2);
 case DAE.LUNARY(op,e1)                            then 4 + hashOp(op)+hashExp(e1);
 case DAE.RELATION(e1,op,e2,_,_)                   then 5 + hashExp(e1)+hashOp(op)+hashExp(e2);
 case DAE.IFEXP(e1,e2,e3)                          then 6 + hashExp(e1)+hashExp(e2)+hashExp(e3);
 case DAE.CALL(path=path,expLst=expl)              then 7 + stringHashDjb2(AbsynUtil.pathString(path))+List.reduce(List.map(expl,hashExp),intAdd);
 case DAE.RECORD(path=path,exps=expl)            then 8 + stringHashDjb2(AbsynUtil.pathString(path))+List.reduce(List.map(expl,hashExp),intAdd);
 case DAE.PARTEVALFUNCTION(path=path,expList=expl) then 9 + stringHashDjb2(AbsynUtil.pathString(path))+List.reduce(List.map(expl,hashExp),intAdd);
 case DAE.ARRAY(array=expl)                        then 10 + List.reduce(List.map(expl,hashExp),intAdd);
 case DAE.MATRIX(matrix=mexpl)                     then 11 + List.reduce(List.map(List.flatten(mexpl),hashExp),intAdd);
 case DAE.RANGE(_,e1,SOME(e2),e3)                  then 12 + hashExp(e1)+hashExp(e2)+hashExp(e3);
 case DAE.RANGE(_,e1,NONE(),e3)                    then 13 + hashExp(e1)+hashExp(e3);
 case DAE.TUPLE(expl)                              then 14 + List.reduce(List.map(expl,hashExp),intAdd);
 case DAE.CAST(_,e1)                               then 15 + hashExp(e1);
 case DAE.ASUB(e1,subs)                            then 16 + hashExp(e1)+List.reduce(list(hashExp(getSubscriptExp(sub)) for sub in subs),intAdd);
 case DAE.TSUB(e1,i,_)                             then 17 + hashExp(e1)+stringHashDjb2(intString(i));
 case DAE.SIZE(e1,SOME(e2))                        then 18 + hashExp(e1)+hashExp(e2);
 case DAE.SIZE(e1,NONE())                          then 19 + hashExp(e1);
 // case(DAE.CODE(_,_))                             then 20; // TODO: implement hashing of CODE AST
 // case(DAE.EMPTY(scope=_))                        then 21; // TODO: implement hashing of EMTPY (needed ?)
 case DAE.REDUCTION(info,e1,iters)                 then 22 + hashReductionInfo(info)+hashExp(e1)+List.reduce(List.map(iters,hashReductionIter),intAdd);
 // TODO: hashing of all MetaModelica extensions
 else stringHashDjb2(printExpStr(e));
 end matchcontinue;
end hashExp;

protected function hashReductionInfo "help function to hashExp"
  input DAE.ReductionInfo info;
  output Integer hash;
algorithm
  hash := match info
  local
    Absyn.Path path;

    // TODO: complete hasing of all subexpressions
    case DAE.REDUCTIONINFO(path=path) then 22 + stringHashDjb2(AbsynUtil.pathString(path));
  end match;
end hashReductionInfo;

protected function hashReductionIter "help function to hashExp"
  input DAE.ReductionIterator iter;
  output Integer hash;
algorithm
  hash := match iter
  local
    String id;
    DAE.Exp e1,e2;


    case DAE.REDUCTIONITER(id,e1,SOME(e2),_)       then 23 + stringHashDjb2(id)+hashExp(e1)+hashExp(e2);
    case DAE.REDUCTIONITER(id,e1,NONE(),_)         then 24 + stringHashDjb2(id)+hashExp(e1);
  end match;

end hashReductionIter;

protected function hashOp "help function to hashExp"
  input DAE.Operator op;
  output Integer hash;
algorithm
  hash := match op
    local
      Absyn.Path path;

    case DAE.ADD(_)                                    then 25;
    case DAE.SUB(_)                                    then 26;
    case DAE.MUL(_)                                    then 27;
    case DAE.DIV(_)                                    then 28;
    case DAE.POW(_)                                    then 29;
    case DAE.UMINUS(_)                                 then 30;
    case DAE.UMINUS_ARR(_)                             then 31;
    case DAE.ADD_ARR(_)                                then 32;
    case DAE.SUB_ARR(_)                                then 33;
    case DAE.MUL_ARR(_)                                then 34;
    case DAE.DIV_ARR(_)                                then 35;
    case DAE.MUL_ARRAY_SCALAR(_)                       then 36;
    case DAE.ADD_ARRAY_SCALAR(_)                       then 37;
    case DAE.SUB_SCALAR_ARRAY(_)                       then 38;
    case DAE.MUL_SCALAR_PRODUCT(_)                     then 39;
    case DAE.MUL_MATRIX_PRODUCT(_)                     then 40;
    case DAE.DIV_ARRAY_SCALAR(_)                       then 41;
    case DAE.DIV_SCALAR_ARRAY(_)                       then 42;
    case DAE.POW_ARRAY_SCALAR(_)                       then 43;
    case DAE.POW_SCALAR_ARRAY(_)                       then 44;
    case DAE.POW_ARR(_)                                then 45;
    case DAE.POW_ARR2(_)                               then 46;
    case DAE.AND(_)                                    then 47;
    case DAE.OR(_)                                     then 48;
    case DAE.NOT(_)                                    then 49;
    case DAE.LESS(_)                                   then 50;
    case DAE.LESSEQ(_)                                 then 51;
    case DAE.GREATER(_)                                then 52;
    case DAE.GREATEREQ(_)                              then 53;
    case DAE.EQUAL(_)                                  then 54;
    case DAE.NEQUAL(_)                                 then 55;
    case DAE.USERDEFINED(path)                         then 56 + stringHashDjb2(AbsynUtil.pathString(path)) ;
    end match;
end hashOp;

protected function getSubscriptExp
  "Returns the subscript expression, or fails on DAE.WHOLEDIM.
   Private copy for hashExp so the cref/exp hashing cluster can live in
   frontend_dump (ExpressionBasics/ComponentReferenceBasics) without pulling in
   the full frontend Expression module. Mirrors Expression.getSubscriptExp."
  input DAE.Subscript inSubscript;
  output DAE.Exp outExp;
algorithm
  outExp := match inSubscript
    local DAE.Exp e;

    case DAE.SLICE(exp = e) then e;
    case DAE.INDEX(exp = e) then e;
    case DAE.WHOLE_NONEXP(exp = e) then e;
  end match;
end getSubscriptExp;

annotation(__OpenModelica_Interface="frontend_dump");
end ExpressionBasics;
