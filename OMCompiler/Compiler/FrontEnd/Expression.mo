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

encapsulated package Expression
" file:        Expression.mo
  package:     Expression
  description: Expressions


  This file contains the module `Expression\', which contains data types for
  describing expressions, after they have been examined by the
  static analyzer in the module `StaticExp\'.  There are of course
  great similarities with the expression types in the `Absyn\'
  module, but there are also several important differences.

  No overloading of operators occur, and subscripts have been
  checked to see if they are slices.  All expressions are also type
  consistent, and all implicit type conversions in the AST are made
  explicit here."

// public imports
public import Absyn;
public import AbsynUtil;
public import DAE;

protected
type ComponentRef = DAE.ComponentRef;
type Exp = DAE.Exp;
type Operator = DAE.Operator;
type Type = DAE.Type;
type Subscript = DAE.Subscript;
type Var = DAE.Var;

// protected imports
protected import Array;
protected import ClassInf;
protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import DoubleEnded;
protected import FCore;
protected import FGraph;
protected import Error;
protected import ExpressionDump;
protected import ExpressionDump.printExpStr;
protected import ExpressionSimplify;
protected import Dump;
protected import Flags;
protected import List;
protected import Patternm;
protected import Static;
protected import System; // stringReal
protected import Types;
protected import Util;

/***************************************************/
/* transform to other types */
/***************************************************/

public function intSubscript
  "Converts an integer into an index subscript."
  input Integer inInteger;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := DAE.INDEX(DAE.ICONST(inInteger));
end intSubscript;

public function intSubscripts
  "Converts a list of integers into index subscripts."
  input list<Integer> inIntegers;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := List.map(inIntegers, intSubscript);
end intSubscripts;

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

public function dimensionIsZero
  input DAE.Dimension inDimension;
  output Boolean outIsZero;
algorithm
  outIsZero := 0 == dimensionSize(inDimension);
end dimensionIsZero;

public function unelabExp
"Transform an DAE.Exp into Absyn.Expression.
  Note: This function currently only works for
  constants and component references."
  input DAE.Exp inExp;
  output Absyn.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;
      Absyn.ComponentRef cr_1;
      ComponentRef cr;
      list<Absyn.Exp> expl_1,aexpl;
      list<DAE.Exp> expl;
      DAE.Exp e1,e2,e3;
      Operator op;
      Absyn.Exp ae1,ae2,ae3;
      Absyn.Operator aop;
      list<list<DAE.Exp>> mexpl2;
      list<list<Absyn.Exp>> amexpl;
      Absyn.ComponentRef acref;
      Absyn.Path path;
      Absyn.CodeNode code;
      DAE.ReductionIterators riters;
      Absyn.ForIterators aiters;
      DAE.Type ty;
      DAE.Dimensions dims;
      Absyn.ReductionIterType iterType;

    case (DAE.ICONST(integer = i)) then Absyn.INTEGER(i);
    case (DAE.RCONST(real = r))
      equation
        s = realString(r);
      then Absyn.REAL(s);
    case (DAE.SCONST(string = s)) then Absyn.STRING(s);
    case (DAE.BCONST(bool = b)) then Absyn.BOOL(b);
    case (DAE.ENUM_LITERAL(name = path))
      equation
        cr_1 = AbsynUtil.pathToCref(path);
      then Absyn.CREF(cr_1);

    case (DAE.CREF(componentRef = cr))
      equation
        cr_1 = ComponentReference.unelabCref(cr);
      then
        Absyn.CREF(cr_1);

    case(DAE.BINARY(e1,op,e2)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.BINARY(ae1,aop,ae2);

    case(DAE.UNARY(op,e1)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
    then Absyn.UNARY(aop,ae1);

    case(DAE.LBINARY(e1,op,e2)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.LBINARY(ae1,aop,ae2);

    case(DAE.LUNARY(op,e1)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
    then Absyn.LUNARY(aop,ae1);

    case(DAE.RELATION(exp1=e1,operator=op,exp2=e2)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.RELATION(ae1,aop,ae2);

    case(DAE.IFEXP(e1,e2,e3)) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
      ae3 = unelabExp(e3);
    then Absyn.IFEXP(ae1,ae2,ae3,{});

    case (DAE.CALL(path,expl,_))
      equation
        aexpl = List.map(expl,unelabExp);
        acref = AbsynUtil.pathToCref(path);
      then Absyn.CALL(acref,Absyn.FUNCTIONARGS(aexpl,{}));

    case (DAE.RECORD(path = path,exps = expl))
      equation
        aexpl = List.map(expl,unelabExp);
        acref = AbsynUtil.pathToCref(path);
      then Absyn.CALL(acref,Absyn.FUNCTIONARGS(aexpl,{}));

    case(DAE.PARTEVALFUNCTION(path,expl,_,_))
      equation
        aexpl = List.map(expl,unelabExp);
        acref = AbsynUtil.pathToCref(path);
      then
        Absyn.PARTEVALFUNCTION(acref,Absyn.FUNCTIONARGS(aexpl,{}));

    case (DAE.ARRAY(array = {}, ty = ty))
      equation
        (ty, dims) = Types.flattenArrayType(ty);
        ae1 = unleabZeroExpFromType(ty);
        expl_1 = List.map(dims, unelabDimensionToFillExp);
      then
        Absyn.CALL(Absyn.CREF_IDENT("fill",{}),Absyn.FUNCTIONARGS(ae1::expl_1,{}));

    case (DAE.ARRAY(array = expl))
      equation
        expl_1 = List.map(expl, unelabExp);
      then
        Absyn.ARRAY(expl_1);

    case(DAE.MATRIX(matrix = mexpl2))
      equation
        amexpl = List.mapList(mexpl2,unelabExp);
      then (Absyn.MATRIX(amexpl));

    case(DAE.RANGE(_,e1,SOME(e2),e3)) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
      ae3 = unelabExp(e3);
    then Absyn.RANGE(ae1,SOME(ae2),ae3);

    case(DAE.RANGE(_,e1,NONE(),e3)) equation
      ae1 = unelabExp(e1);
      ae3 = unelabExp(e3);
    then Absyn.RANGE(ae1,NONE(),ae3);

    case(DAE.TUPLE(expl))
      equation
        expl_1 = List.map(expl, unelabExp);
      then
        Absyn.TUPLE(expl_1);

    case(DAE.CAST(_,e1)) equation
      ae1 = unelabExp(e1);
    then ae1;

     // ASUB can not be unelabed since it has no representation in Absyn.
    case(DAE.ASUB(_,_)) equation
      print("Internal Error, can not unelab ASUB\n");
    then fail();

    // TSUB(expression) => expression
    case(DAE.TSUB(e1,_,_)) equation
      ae1 = unelabExp(e1);
    then ae1;

    case(DAE.SIZE(e1,SOME(e2))) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({ae1,ae2},{}));

    /* WHAT? exactly the same case as above???!!!
    case(DAE.SIZE(e1,SOME(e2))) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({ae1,ae2},{}));
    */

    case(DAE.CODE(code,_)) then Absyn.CODE(code);

    case DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(iterType=iterType,path=path),expr=e1,iterators=riters)
      equation
      //print("unelab of reduction not impl. yet");
      acref = AbsynUtil.pathToCref(path);
      ae1 = unelabExp(e1);
      aiters = List.map(riters, unelabReductionIterator);
      then Absyn.CALL(acref, Absyn.FOR_ITER_FARG(ae1, iterType, aiters));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        print("Expression.unelabExp failed on: " + ExpressionDump.printExpStr(inExp) + "\n");
      then
        fail();
  end matchcontinue;
end unelabExp;

public function unelabDimension
"Transform an DAE.Dimension into Absyn.Subscript, if possible"
  input DAE.Dimension inDim;
  output Absyn.Subscript outDim;
algorithm
  outDim := match (inDim)
    local
      Integer i;
      Absyn.Path p;
      Absyn.ComponentRef c;
      DAE.Exp e;
      Absyn.Exp ae;

    case (DAE.DIM_INTEGER(i)) then Absyn.SUBSCRIPT(Absyn.INTEGER(i));

    case (DAE.DIM_BOOLEAN()) then Absyn.SUBSCRIPT(Absyn.CREF(Absyn.CREF_IDENT("Boolean", {})));

    case (DAE.DIM_ENUM(enumTypeName = p))
      equation
        c = AbsynUtil.pathToCref(p);
      then
        Absyn.SUBSCRIPT(Absyn.CREF(c));

    case (DAE.DIM_EXP(e))
      equation
        ae = unelabExp(e);
      then
        Absyn.SUBSCRIPT(ae);

    case (DAE.DIM_UNKNOWN()) then Absyn.NOSUB();

  end match;
end unelabDimension;

protected function unleabZeroExpFromType
  input DAE.Type ty;
  output Absyn.Exp outExp;
algorithm
  outExp := match ty
    case DAE.T_BOOL() then Absyn.BOOL(false);
    case DAE.T_STRING() then Absyn.STRING("");
    case DAE.T_INTEGER() then Absyn.INTEGER(0);
    case DAE.T_REAL() then Absyn.REAL("0.0");
    case DAE.T_UNKNOWN() then Absyn.REAL("0.0"); /* Look at the crap unelabMod needs... */
  end match;
end unleabZeroExpFromType;

protected function unelabDimensionToFillExp
"Transform an DAE.Dimension into Absyn.Exp, if possible"
  input DAE.Dimension inDim;
  output Absyn.Exp outExp;
algorithm
  outExp := match (inDim)
    local
      Integer i;
      DAE.Exp e;

    case (DAE.DIM_INTEGER(i)) then Absyn.INTEGER(i);

    case (DAE.DIM_EXP(e)) then unelabExp(e);

    else Absyn.INTEGER(1); /* Probably bad, but only used with zero-length arrays */

  end match;
end unelabDimensionToFillExp;

protected function unelabReductionIterator
  input DAE.ReductionIterator riter;
  output Absyn.ForIterator aiter;
algorithm
  aiter := match riter
    local
      String id;
      DAE.Exp exp;
      Option<DAE.Exp> gexp;
      Absyn.Exp aexp;
      Option<Absyn.Exp> agexp;
    case DAE.REDUCTIONITER(id=id,exp=exp,guardExp=gexp)
      equation
        aexp = unelabExp(exp);
        agexp = Util.applyOption(gexp, unelabExp);
      then Absyn.ITERATOR(id,agexp,SOME(aexp));
  end match;
end unelabReductionIterator;

protected function unelabOperator "help function to unelabExpression."
input DAE.Operator op;
output Absyn.Operator aop;
algorithm
  aop := match(op)
    case(DAE.ADD(_)) then Absyn.ADD();
    case(DAE.SUB(_)) then Absyn.SUB();
    case(DAE.MUL(_)) then Absyn.MUL();
    case(DAE.DIV(_)) then Absyn.DIV();
    case(DAE.POW(_)) then Absyn.POW();
    case(DAE.UMINUS(_)) then Absyn.UMINUS();
    case(DAE.UMINUS_ARR(_)) then Absyn.UMINUS();
    case(DAE.ADD_ARR(_)) then Absyn.ADD();
    case(DAE.SUB_ARR(_)) then Absyn.SUB();
    case(DAE.MUL_ARR(_)) then Absyn.MUL();
    case(DAE.DIV_ARR(_)) then Absyn.DIV();
    case(DAE.MUL_ARRAY_SCALAR(_)) then Absyn.MUL();
    case(DAE.ADD_ARRAY_SCALAR(_)) then Absyn.ADD();
    case(DAE.SUB_SCALAR_ARRAY(_)) then Absyn.SUB();
    case(DAE.MUL_SCALAR_PRODUCT(_)) then Absyn.MUL();
    case(DAE.MUL_MATRIX_PRODUCT(_)) then Absyn.MUL();
    case(DAE.DIV_SCALAR_ARRAY(_)) then Absyn.DIV();
    case(DAE.DIV_ARRAY_SCALAR(_)) then Absyn.DIV();
    case(DAE.POW_SCALAR_ARRAY(_)) then Absyn.POW();
    case(DAE.POW_ARRAY_SCALAR(_)) then Absyn.POW();
    case(DAE.POW_ARR(_)) then Absyn.POW();
    case(DAE.POW_ARR2(_)) then Absyn.POW();
    case(DAE.AND(_)) then Absyn.AND();
    case(DAE.OR(_)) then Absyn.OR();
    case(DAE.NOT(_)) then Absyn.NOT();
    case(DAE.LESS(_)) then Absyn.LESS();
    case(DAE.LESSEQ(_)) then Absyn.LESSEQ();
    case(DAE.GREATER(_)) then Absyn.GREATER();
    case(DAE.GREATEREQ(_)) then Absyn.GREATEREQ();
    case(DAE.EQUAL(_)) then Absyn.EQUAL();
    case(DAE.NEQUAL(_)) then Absyn.NEQUAL();
  end match;
end unelabOperator;

public function stringifyCrefs
"This function takes an expression and transforms all component
  reference  names contained in the expression to a simpler form.
  For instance DAE.CREF_QUAL(a,{}, DAE.CREF_IDENT(b,{})) becomes
  DAE.CREF_IDENT(a.b,{})

  NOTE: This function should not be used in OMC, since the OMC backend no longer
        uses stringified components. It is still used by MathCore though."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := traverseExpDummy(inExp, traversingstringifyCrefFinder);
end stringifyCrefs;

public function traversingstringifyCrefFinder "
helper for stringifyCrefs"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      ComponentRef cr,crs;
      Type ty;
      DAE.Exp e;
      list<Boolean> blist;

    case DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_VAR())
      then inExp;

    case DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_FUNC())
      then inExp;

    case DAE.CREF(cr,ty)
      equation
        crs = ComponentReference.stringifyComponentRef(cr);
      then makeCrefExp(crs,ty);

    else inExp;

  end match;
end traversingstringifyCrefFinder;

public function CodeVarToCref
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp)
    local
      ComponentRef e_cref;
      Absyn.ComponentRef cref;
      DAE.Exp e;

    case(DAE.CODE(Absyn.C_VARIABLENAME(cref),_))
      equation
        (_,e_cref) = Static.elabUntypedCref(FCore.emptyCache(),FGraph.empty(),cref,false,DAE.NOPRE(),AbsynUtil.dummyInfo);
        e = crefExp(e_cref);
      then
        e;

    case(DAE.CODE(Absyn.C_EXPRESSION(Absyn.CALL(Absyn.CREF_IDENT("der",{}),Absyn.FUNCTIONARGS({Absyn.CREF(cref)},{}))),_))
      equation
        (_,e_cref) = Static.elabUntypedCref(FCore.emptyCache(),FGraph.empty(),cref,false,DAE.NOPRE(),AbsynUtil.dummyInfo);
        e = crefExp(e_cref);
      then
        DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal);
  end match;
end CodeVarToCref;

public function realToIntIfPossible
"converts to ICONST if possible. If it does
 not fit, a RCONST is returned instead."
  input Real inVal;
  output DAE.Exp outVal;
algorithm
  try
    outVal := DAE.ICONST(realInt(inVal));
  else
    outVal := DAE.RCONST(inVal);
  end try;
end realToIntIfPossible;

public function liftArrayR "
  function liftArrayR
  Converts a type into an array type with dimension n as first dim"
  input DAE.Type tp;
  input DAE.Dimension n;
  output DAE.Type outTp;
algorithm
  outTp := match(tp,n)
    local
      Type elt_tp;
      list<DAE.Dimension> dims;

    case(DAE.T_ARRAY(elt_tp,dims),_)
      equation
        dims = n::dims;
      then
        DAE.T_ARRAY(elt_tp,dims);

    else DAE.T_ARRAY(tp,{n});

  end match;
end liftArrayR;

public function dimensionSizeConstantExp
  "Converts (extracts) a dimension to an expression.
  This function will fail if dimension is unknown or an expression (in case the dimension is from a different scope).
  If you want to(kind of) handle unknown dims use dimensionSizeExpHandleUnkown."
  input DAE.Dimension dim;
  output DAE.Exp exp;
algorithm
  exp := match(dim)
    local
      Integer i;

    case DAE.DIM_INTEGER(integer = i) then DAE.ICONST(i);
    case DAE.DIM_ENUM(size = i) then DAE.ICONST(i);
    case DAE.DIM_BOOLEAN() then DAE.ICONST(2);
  end match;
end dimensionSizeConstantExp;

public function dimensionSizeExp
  "Converts (extracts) a dimension to an expression.
  This function will fail if dimension is unknown. i.e. DIM_UNKNOWN.
  If you want to(kind of) handle unknown dims use dimensionSizeExpHandleUnkown."
  input DAE.Dimension dim;
  output DAE.Exp exp;
algorithm
  exp := match(dim)
    local
      Integer i;
      DAE.Exp e;

    case DAE.DIM_INTEGER(integer = i) then DAE.ICONST(i);
    case DAE.DIM_ENUM(size = i) then DAE.ICONST(i);
    case DAE.DIM_BOOLEAN() then DAE.ICONST(2);
    case DAE.DIM_EXP(exp = e) then e;
  end match;
end dimensionSizeExp;

public function dimensionSizeExpHandleUnkown
  "Converts (extracts) a dimension to an expression.
  This function will change unknown dims to DAE.ICONST(-1).
  we use it to handle unknown dims in code generation. unknown dims
  are okay if the variable is a function input (it's just holds the slot
  and will not be generated). Otherwise it's an error
  since it shouldn't have reached there."
  input DAE.Dimension dim;
  output DAE.Exp exp;
algorithm
  exp := match(dim)
    case DAE.DIM_UNKNOWN() then DAE.ICONST(-1);
    else dimensionSizeExp(dim);
  end match;
end dimensionSizeExpHandleUnkown;

public function intDimension
  "Converts an integer to an array dimension."
  input Integer value;
  output DAE.Dimension dim;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  dim := DAE.DIM_INTEGER(value);
end intDimension;

public function dimensionSubscript
  "Converts an array dimension to a subscript."
  input DAE.Dimension dim;
  output DAE.Subscript sub;
algorithm
  sub := match(dim)
    local
      Integer i;

    case DAE.DIM_INTEGER(integer = i) then DAE.INDEX(DAE.ICONST(i));
    case DAE.DIM_ENUM(size = i) then DAE.INDEX(DAE.ICONST(i));
    case DAE.DIM_BOOLEAN() then DAE.INDEX(DAE.ICONST(2));
    case DAE.DIM_UNKNOWN() then DAE.WHOLEDIM();
  end match;
end dimensionSubscript;

/***************************************************/
/* Change  */
/***************************************************/

public function negate
"author: PA
  Negates an expression."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp)
    local
      Type t;
      Operator op;
      Boolean b,b_1;
      Real r,r_1;
      Integer i,i_1;
      DAE.Exp e,e1,e2;

    // to avoid un-necessary --e
    case(DAE.UNARY(DAE.UMINUS(_),e)) then e;
    case(DAE.UNARY(DAE.UMINUS_ARR(_),e)) then e;
    case(DAE.LUNARY(DAE.NOT(_),e)) then e;

    // -(a*b) = (-a)*b
    // -(a/b) = (-a)/b
    case(DAE.BINARY(e1,op,e2)) guard(isMulOrDiv(op))
    then DAE.BINARY(negate(e1),op,e2);

    // -(a-b) = b-a
    case(DAE.BINARY(e1,op,e2)) guard(isSub(op))
    then DAE.BINARY(e2,op,e1);

    case e // -0 = 0
    guard isZero(e)
    then e;

    case (DAE.ICONST(i))
      equation
        i_1 = 0 - i;
      then DAE.ICONST(i_1);
    case (DAE.RCONST(r))
      equation
        r_1 = 0.0 - r;
      then DAE.RCONST(r_1);
    case (DAE.BCONST(b))
      equation
        b_1 = not b;
      then DAE.BCONST(b_1);

    case(e)
      equation
        t = typeof(e);
        outExp = match (t)
        case (DAE.T_BOOL()) // not e
          then DAE.LUNARY(DAE.NOT(t),e);
        else
          equation
            b = DAEUtil.expTypeArray(t);
            op = if b then DAE.UMINUS_ARR(t) else DAE.UMINUS(t);
          then DAE.UNARY(op,e);
        end match;
      then
        outExp;

  end match;
end negate;

public function negateReal
  input DAE.Exp inReal;
  output DAE.Exp outNegatedReal;
algorithm
  outNegatedReal := DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT), inReal);
end negateReal;

public function expand "expands products
For example
a *(b+c) => a*b + a*c"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  outE := match(e)
    local
      DAE.Type tp;
      DAE.Operator op;
      DAE.Exp e1,e2,e21,e22;

    case(DAE.BINARY(e1,DAE.MUL(tp),e2 as DAE.BINARY(e21,op,e22))) guard isAddOrSub(op)
      equation
        DAE.BINARY(e21,op,e22) = expand(e2);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e21),op,DAE.BINARY(e1,DAE.MUL(tp),e22));

    else e;
  end match;
end expand;

public function expDer
"author: Frenkel TUD 2012-11
  exp -> der(exp)"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := DAE.CALL(Absyn.IDENT("der"),{inExp},DAE.callAttrBuiltinReal);
end expDer;

public function expAbs
"author: PA
  Makes the expression absolute. i.e. non-negative."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp)
    local
      Integer i2,i;
      Real r2,r;
      DAE.Exp e_1,e,e1_1,e2_1,e1,e2;
      Type tp;
      Operator op;

    case (DAE.ICONST(integer = i))
      equation
        i2 = intAbs(i);
      then
        DAE.ICONST(i2);

    case (DAE.RCONST(real = r))
      equation
        r2 = realAbs(r);
      then
        DAE.RCONST(r2);

    case (DAE.UNARY(operator = DAE.UMINUS(),exp = e))
      equation
        e_1 = expAbs(e);
      then
        e_1;

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = expAbs(e1);
        e2_1 = expAbs(e2);
      then
        DAE.BINARY(e1_1,op,e2_1);

    else inExp;
  end match;
end expAbs;

public function stripNoEvent
"Function that strips all noEvent() calls in an expression"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  outE := traverseExpDummy(e,stripNoEventExp);
end stripNoEvent;

protected function stripNoEventExp "
traversal function for stripNoEvent"
  input DAE.Exp e;
  output DAE.Exp outExp;
algorithm
  outExp := match e
    case DAE.CALL(path=Absyn.IDENT("noEvent"),expLst={outExp}) then outExp;
    else e;
  end match;
end stripNoEventExp;

public function addNoEventToRelations
"Function that adds a noEvent() call to all relations in an expression"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  outE := traverseExpDummy(e,addNoEventToRelationExp);
end addNoEventToRelations;

protected function addNoEventToRelationExp "
traversal function for addNoEventToRelations"
  input DAE.Exp e;
  output DAE.Exp outExp;
algorithm
  outExp := match e
    case DAE.RELATION() then makeNoEvent(e);
    else e;
  end match;
end addNoEventToRelationExp;

public function addNoEventToRelationsAndConds
"Function that adds a noEvent() call to all relations in an expression"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  outE := traverseExpDummy(e,addNoEventToRelationandCondExp);
end addNoEventToRelationsAndConds;

protected function addNoEventToRelationandCondExp "
traversal function for addNoEventToRelationsAndConds"
  input DAE.Exp e;
  output DAE.Exp outExp;
algorithm
  outExp := match e
    local
      DAE.Exp e1,e2,e3;
    case DAE.RELATION() then makeNoEvent(e);
    case DAE.IFEXP(e1,e2,e3) then DAE.IFEXP(makeNoEvent(e1),e2,e3);
    else e;
  end match;
end addNoEventToRelationandCondExp;

public function addNoEventToEventTriggeringFunctions
" Function that adds a noEvent() call to all event triggering functions in an expression"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  outE := traverseExpDummy(e,addNoEventToEventTriggeringFunctionsExp);
end addNoEventToEventTriggeringFunctions;

protected function addNoEventToEventTriggeringFunctionsExp "
traversal function for addNoEventToEventTriggeringFunctions"
  input DAE.Exp e;
  output DAE.Exp outExp;
algorithm
  outExp := match e
    case DAE.CALL()
      guard
        isEventTriggeringFunctionExp(e)
      then makeNoEvent(e);
    else e;
  end match;
end addNoEventToEventTriggeringFunctionsExp;

public function expStripLastSubs
"Strips the last subscripts of a Exp"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match (inExp)
    local
      ComponentRef cr,cr_1;
      Type ty;
      Operator op,op1;
      DAE.Exp e,e_1;
      Boolean b;

    case (DAE.CREF(componentRef=cr))
      equation
        ty = ComponentReference.crefLastType(cr);
        cr_1 = ComponentReference.crefStripLastSubs(cr);
        e = makeCrefExp(cr_1, ty);
      then
        e;

    case (DAE.UNARY(exp=e))
      equation
        e_1 = expStripLastSubs(e);
        ty = typeof(e_1);
        b = DAEUtil.expTypeArray(ty);
        op1 = if b then DAE.UMINUS_ARR(ty) else DAE.UMINUS(ty);
      then
        DAE.UNARY(op1,e_1);
  end match;
end expStripLastSubs;

public function expStripLastIdent
"Strips the last identifier of a cref Exp"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  match (inExp)
    local
      ComponentRef cr,cr_1;
      Type ty;
      Operator op,op1;
      DAE.Exp e,e_1;
      Boolean b;

    case (DAE.CREF(componentRef=cr))
      equation
        cr_1 = ComponentReference.crefStripLastIdent(cr);
        ty = ComponentReference.crefLastType(cr_1);
        e = makeCrefExp(cr_1, ty);
      then
        e;

    case (DAE.UNARY(exp=e))
      equation
        e_1 = expStripLastIdent(e);
        ty = typeof(e_1);
        b = DAEUtil.expTypeArray(ty);
        op1 = if b then DAE.UMINUS_ARR(ty) else DAE.UMINUS(ty);
      then
        DAE.UNARY(op1,e_1);
  end match;
end expStripLastIdent;

public function prependSubscriptExp
"Prepends a subscript to a CREF expression
 For instance a.b[1,2] with subscript 'i' becomes a.b[i,1,2]."
  input DAE.Exp exp;
  input DAE.Subscript subscr;
  output DAE.Exp outExp;
algorithm
  outExp := match(exp,subscr)
    local
      Type t; ComponentRef cr,cr1,cr2;
      list<DAE.Subscript> subs;
      DAE.Exp e;

    case (DAE.CREF(cr,t),_)
      equation
        cr1 = ComponentReference.crefStripLastSubs(cr);
        subs = ComponentReference.crefLastSubs(cr);
        cr2 = ComponentReference.subscriptCref(cr1,subscr::subs);
        e = makeCrefExp(cr2, t);
    then
      e;
  end match;
end prependSubscriptExp;

public function applyExpSubscripts "
author: PA
Takes an arbitrary expression and applies subscripts to it. This is done by creating asub
expressions given the original expression and then simplify them.
Note: The subscripts must be INDEX

alternative names: subsriptExp (but already taken), subscriptToAsub"
  input output DAE.Exp exp;
  input list<DAE.Subscript> inSubs;
protected
  DAE.Exp s;
algorithm
  exp := applyExpSubscriptsFoldCheckSimplify(exp, inSubs);
end applyExpSubscripts;


public function applyExpSubscriptsFoldCheckSimplify "
author: PA
Takes an arbitrary expression and applies subscripts to it. This is done by creating asub
expressions given the original expression and then simplify them.
Note: The subscripts must be INDEX

alternative names: subsriptExp (but already taken), subscriptToAsub

This version of the function also returns a boolean stating if simplify
improved anything (can be used as a heuristic if you want to apply
the subscript when scalarizing)"
  input output DAE.Exp exp;
  input list<DAE.Subscript> inSubs;
  input output Boolean checkSimplify = false;
protected
  Boolean b;
  DAE.Exp s;
algorithm
  for sub in inSubs loop
    // Apply one subscript at a time, so simplify works fine on it.
    //s := subscriptIndexExp(sub);
    try
      s := getSubscriptExp(sub);
      (exp,b) := ExpressionSimplify.simplify(makeASUB(exp,{s}));
      checkSimplify := b or checkSimplify;
    else
      // skipped DAE.WHOLEDIM
    end try;
  end for;
end applyExpSubscriptsFoldCheckSimplify;

public function subscriptExp
"@mahge
  This function does the same job as 'applyExpSubscripts' function.
  However this one doesn't use ExpressionSimplify.simplify.


  Takes an expression and a list of subscripts and subscripts
  the given expression.
  If a component reference is given the subs are applied to it.
  If an array(DAE.ARRAY) is given the element at the specified
  subscripts is returned.
  e.g. subscriptExp on ({{1,2},{3,4}}) with sub [2,1] gives 3
       subscriptExp on (a) with sub [2,1] gives a[2,1]

"
  input DAE.Exp inExp;
  input list<DAE.Subscript> inSubs;
  output DAE.Exp outArg;
algorithm
  outArg := match(inExp, inSubs)
    local
      DAE.ComponentRef cref;
      DAE.Type ty;
      DAE.Exp exp,exp1,exp2;
      list<DAE.Exp> explst;
      DAE.Subscript sub;
      list<DAE.Subscript> restsubs;
      DAE.Operator op;
      String str;

    case(_, {}) then inExp;

    case(DAE.CREF(cref, ty), _)
      equation
        cref = ComponentReference.subscriptCref(cref, inSubs);
      then
        DAE.CREF(cref, ty);

    case(DAE.ARRAY(_, _, explst), sub::restsubs)
      equation
        exp = listGet(explst, subscriptInt(sub));
      then
        subscriptExp(exp, restsubs);

    case (DAE.BINARY(exp1, op, exp2), _)
      equation
        exp1 = subscriptExp(exp1, inSubs);
        exp2 = subscriptExp(exp2, inSubs);
      then
        DAE.BINARY(exp1, op, exp2);

    case (DAE.CAST(ty,exp1), _)
      equation
        exp1 = subscriptExp(exp1, inSubs);
        ty = Types.arrayElementType(ty);
        exp1 = DAE.CAST(ty,exp1);
      then
        exp1;

    else
      equation
        str = "Expression.subscriptExp failed on " + ExpressionDump.printExpStr(inExp) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();

  end match;
end subscriptExp;


public function unliftArray
"Converts an array type into its element type
  See also Types.unliftArray.
  ."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    local
      Type tp,t;
      DAE.Dimension d;
      DAE.Dimensions ds;

    case (DAE.T_ARRAY(ty = tp,dims = {_}))
      then tp;
    case (DAE.T_ARRAY(ty = tp,dims = (_ :: ds)))
      then DAE.T_ARRAY(tp,ds);
    case (DAE.T_METATYPE(ty = tp))
      then Types.simplifyType(unliftArray(tp));
    case (DAE.T_METAARRAY(ty = tp))
      then tp;
    else inType;
  end match;
end unliftArray;

public function unliftArrayIgnoreFirst
  input A a;
  input DAE.Type inType;
  output DAE.Type outType;
  replaceable type A subtypeof Any;
algorithm
  outType := unliftArray(inType);
end unliftArrayIgnoreFirst;

public function unliftExp
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp)
    local
      Type ty;
      DAE.ComponentRef cr;
      Boolean s;
      list<DAE.Exp> a;
      Integer i;
      list<list<DAE.Exp>> mat;
      DAE.Exp expCref;

    case DAE.CREF(componentRef = cr, ty = ty)
      equation
        ty = unliftArray(ty);
        expCref = makeCrefExp(cr, ty);
      then
        expCref;

    case DAE.ARRAY(ty = ty, scalar = s, array = a)
      equation
        ty = unliftArray(ty);
      then
        DAE.ARRAY(ty, s, a);

    case DAE.MATRIX(ty = ty, integer = i, matrix = mat)
      equation
        ty = unliftArray(ty);
      then
        DAE.MATRIX(ty, i, mat);

    else inExp;

  end match;
end unliftExp;

public function liftExp
  input DAE.Exp inExp;
  input DAE.Dimension inDimension;
  output DAE.Exp outExp;
algorithm
  outExp := DAE.ARRAY(Types.liftArray(typeof(inExp), inDimension),
    false, List.fill(inExp, dimensionSize(inDimension)));
end liftExp;

public function liftExpList
  input DAE.Exp inExp;
  input list<DAE.Dimension> inDimensions;
  output DAE.Exp outExp = inExp;
algorithm
  for dim in listReverse(inDimensions) loop
    outExp := liftExp(outExp, dim);
  end for;
end liftExpList;

public function liftArrayRight "
This function adds an array dimension to a type on the right side, i.e.
liftArrayRigth(Real[2,3],SOME(4)) => Real[2,3,4].
This function has the same functionality as Types.liftArrayType but for DAE.Type.'"
  input DAE.Type inType;
  input DAE.Dimension inDimension;
  output DAE.Type outType;
algorithm
  outType := match(inType,inDimension)
    local
      Type ty_1,ty;
      DAE.Dimensions dims;
      DAE.Dimension dim;

    case (DAE.T_ARRAY(ty,dims),dim)
      equation
        ty_1 = liftArrayRight(ty, dim);
      then
        DAE.T_ARRAY(ty_1,dims);

    else DAE.T_ARRAY(inType,{inDimension});

  end match;
end liftArrayRight;

public function liftArrayLeft "
author: PA
This function adds an array dimension to a type on the left side, i.e.
liftArrayRigth(Real[2,3],SOME(4)) => Real[4,2,3]"
  input DAE.Type inType;
  input DAE.Dimension inDimension;
  output DAE.Type outType;
algorithm
  outType := match(inType,inDimension)
    local
      Type ty;
      DAE.Dimensions dims;
      DAE.Dimension dim;

    case (DAE.T_ARRAY(ty,dims),dim) then DAE.T_ARRAY(ty,dim::dims);

    else DAE.T_ARRAY(inType,{inDimension});

  end match;
end liftArrayLeft;

public function liftArrayLeftList
  input DAE.Type inType;
  input list<DAE.Dimension> inDimensions;
  output DAE.Type outType;
algorithm
  outType := match(inType, inDimensions)
    local
      Type ty;
      DAE.Dimensions dims;

    case (_, {}) then inType;

    case (DAE.T_ARRAY(ty, dims), _)
      equation
        dims = listAppend(inDimensions, dims);
      then
        DAE.T_ARRAY(ty, dims);

    else DAE.T_ARRAY(inType, inDimensions);

  end match;
end liftArrayLeftList;

public function setOpType
  "Sets the type of an operator."
  input DAE.Operator inOp;
  input DAE.Type inType;
  output DAE.Operator outOp;
algorithm
  outOp := match(inOp, inType)
    case (DAE.ADD(), _) then DAE.ADD(inType);
    case (DAE.SUB(), _) then DAE.SUB(inType);
    case (DAE.MUL(), _) then DAE.MUL(inType);
    case (DAE.DIV(), _) then DAE.DIV(inType);
    case (DAE.POW(), _) then DAE.POW(inType);
    case (DAE.UMINUS(), _) then DAE.UMINUS(inType);
    case (DAE.UMINUS_ARR(), _) then DAE.UMINUS_ARR(inType);
    case (DAE.ADD_ARR(), _) then DAE.ADD_ARR(inType);
    case (DAE.SUB_ARR(), _) then DAE.SUB_ARR(inType);
    case (DAE.MUL_ARR(), _) then DAE.MUL_ARR(inType);
    case (DAE.DIV_ARR(), _) then DAE.DIV_ARR(inType);
    case (DAE.MUL_ARRAY_SCALAR(), _) then DAE.MUL_ARRAY_SCALAR(inType);
    case (DAE.ADD_ARRAY_SCALAR(), _) then DAE.ADD_ARRAY_SCALAR(inType);
    case (DAE.SUB_SCALAR_ARRAY(), _) then DAE.SUB_SCALAR_ARRAY(inType);
    case (DAE.MUL_SCALAR_PRODUCT(), _) then DAE.MUL_SCALAR_PRODUCT(inType);
    case (DAE.MUL_MATRIX_PRODUCT(), _) then DAE.MUL_MATRIX_PRODUCT(inType);
    case (DAE.DIV_ARRAY_SCALAR(), _) then DAE.DIV_ARRAY_SCALAR(inType);
    case (DAE.DIV_SCALAR_ARRAY(), _) then DAE.DIV_SCALAR_ARRAY(inType);
    case (DAE.POW_ARRAY_SCALAR(), _) then DAE.POW_ARRAY_SCALAR(inType);
    case (DAE.POW_SCALAR_ARRAY(), _) then DAE.POW_SCALAR_ARRAY(inType);
    case (DAE.POW_ARR(), _) then DAE.POW_ARR(inType);
    case (DAE.POW_ARR2(), _) then DAE.POW_ARR2(inType);
    case (DAE.AND(), _) then DAE.AND(inType);
    case (DAE.OR(), _) then DAE.OR(inType);
    case (DAE.NOT(),_ ) then DAE.NOT(inType);
    case (DAE.LESS(), _) then inOp;
    case (DAE.LESSEQ(), _) then inOp;
    case (DAE.GREATER(), _) then inOp;
    case (DAE.GREATEREQ(), _) then inOp;
    case (DAE.EQUAL(), _) then inOp;
    case (DAE.NEQUAL(), _) then inOp;
    case (DAE.USERDEFINED(), _) then inOp;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Expression.setOpType failed on unknown operator");
      then
        fail();
  end match;
end setOpType;

public function unliftOperator
  "Unlifts the type of an operator by removing one dimension from the operator
   type. The operator is changed to the scalar version if the type becomes a
   scalar type."
  input DAE.Operator inOperator;
  output DAE.Operator outOperator;
protected
  Type ty;
algorithm
  ty := typeofOp(inOperator);
  ty := unliftArray(ty);
  outOperator := unliftOperator2(inOperator, ty);
end unliftOperator;

public function unliftOperatorX
  "Unlifts the type of an operator by removing X dimensions from the operator
   type. The operator is changed to the scalar version if the type becomes a
   scalar type."
  input DAE.Operator inOperator;
  input Integer inX;
  output DAE.Operator outOperator;
protected
  Type ty;
algorithm
  ty := typeofOp(inOperator);
  ty := unliftArrayX(ty, inX);
  outOperator := unliftOperator2(inOperator, ty);
end unliftOperatorX;

protected function unliftOperator2
  "Helper function to unliftOperator. Sets the type of the given operator, and
   changes the operator to the scalar version if the type is scalar."
  input DAE.Operator inOperator;
  input DAE.Type inType;
  output DAE.Operator outOperator;
algorithm
  outOperator := match(inOperator, inType)
    case (_, DAE.T_ARRAY()) then setOpType(inOperator, inType);
    else makeScalarOpFromArrayOp(inOperator, inType);
  end match;
end unliftOperator2;

protected function makeScalarOpFromArrayOp
  "Helper function to makeScalarOpFromArrayOp. Returns the scalar version of a
   given array operator."
  input DAE.Operator inOperator;
  input DAE.Type inType;
  output DAE.Operator outOperator;
algorithm
  outOperator := match(inOperator, inType)
    case (DAE.MUL_ARRAY_SCALAR(), _) then DAE.MUL(inType);
    case (DAE.ADD_ARRAY_SCALAR(), _) then DAE.ADD(inType);
    case (DAE.SUB_SCALAR_ARRAY(), _) then DAE.SUB(inType);
    case (DAE.DIV_ARRAY_SCALAR(), _) then DAE.DIV(inType);
    case (DAE.DIV_SCALAR_ARRAY(), _) then DAE.DIV(inType);
    case (DAE.POW_ARRAY_SCALAR(), _) then DAE.POW(inType);
    case (DAE.POW_SCALAR_ARRAY(), _) then DAE.POW(inType);
    case (DAE.UMINUS_ARR(), _)       then DAE.UMINUS(inType);
    case (DAE.ADD_ARR(), _)          then DAE.ADD(inType);
    case (DAE.SUB_ARR(), _)          then DAE.SUB(inType);
    case (DAE.MUL_ARR(), _)          then DAE.MUL(inType);
    case (DAE.DIV_ARR(), _)          then DAE.DIV(inType);
    else inOperator;
  end match;
end makeScalarOpFromArrayOp;

public function isScalarArrayOp
  "Returns true if the operator takes a scalar and an array as arguments."
  input DAE.Operator inOperator;
  output Boolean outIsScalarArrayOp;
algorithm
  outIsScalarArrayOp := match(inOperator)
    case DAE.SUB_SCALAR_ARRAY() then true;
    case DAE.DIV_SCALAR_ARRAY() then true;
    case DAE.POW_SCALAR_ARRAY() then true;
  else false;
  end match;
end isScalarArrayOp;

public function isArrayScalarOp
  "Returns true if the operator takes an array and a scalar as arguments."
  input DAE.Operator inOperator;
  output Boolean outIsArrayScalarOp;
algorithm
  outIsArrayScalarOp := match(inOperator)
    case DAE.MUL_ARRAY_SCALAR() then true;
    case DAE.ADD_ARRAY_SCALAR() then true;
    case DAE.DIV_ARRAY_SCALAR() then true;
    case DAE.POW_ARRAY_SCALAR() then true;
    else false;
  end match;
end isArrayScalarOp;

public function subscriptsAppend
"This function takes a subscript list and adds a new subscript.
  But there are a few special cases.  When the last existing
  subscript is a slice, it is replaced by the slice indexed by
  the new subscript."
  input list<DAE.Subscript> inSubscriptLst;
  input DAE.Exp inSubscript;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := match(inSubscriptLst,inSubscript)
    local
      DAE.Exp e_1,e;
      Subscript s;
      list<DAE.Subscript> ss_1,ss;

    case ({},_) then {DAE.INDEX(inSubscript)};
    case (DAE.WHOLEDIM() :: ss,_) then DAE.INDEX(inSubscript) :: ss;

    case ({DAE.SLICE(exp = e)},_)
      equation
        (e_1,_) = ExpressionSimplify.simplify1(makeASUB(e,{inSubscript}));
      then
        {DAE.INDEX(e_1)};

    case ({(s as DAE.INDEX())},_) then {s,DAE.INDEX(inSubscript)};

    case ((s :: ss),_)
      equation
        ss_1 = subscriptsAppend(ss, inSubscript);
      then
        (s :: ss_1);
  end match;
end subscriptsAppend;

public function subscriptsReplaceSlice
  "Replaces the first slice subscript in the given list with the given subscript."
  input list<DAE.Subscript> inSubscripts;
  input DAE.Subscript inSubscript;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := match(inSubscripts, inSubscript)
    local
      list<DAE.Subscript> rest_subs;
      DAE.Subscript sub;

    case (DAE.WHOLEDIM() :: rest_subs, _) then inSubscript :: rest_subs;
    case (DAE.SLICE() :: rest_subs, _) then inSubscript :: rest_subs;
    case (sub :: rest_subs, _)
      equation
        rest_subs = subscriptsReplaceSlice(rest_subs, inSubscript);
      then
        sub :: rest_subs;

  end match;
end subscriptsReplaceSlice;

public function unliftArrayTypeWithSubs "
helper function for renameVarsToUnderlineVar2 unlifts array type as much as we have subscripts"
  input list<DAE.Subscript> subs;
  input DAE.Type ity;
  output DAE.Type oty;
algorithm
  oty := match(subs,ity)
    local
      list<DAE.Subscript> rest;
      Type ty;

    case({},ty) then ty;

    case(_::rest, ty)
      equation
        ty = unliftArray(ty);
        ty = unliftArrayTypeWithSubs(rest,ty);
      then
        ty;
  end match;
end unliftArrayTypeWithSubs;

public function unliftArrayX "Function: unliftArrayX
Unlifts a type with X dimensions..."
  input DAE.Type inType;
  input Integer x;
  output DAE.Type outType;
algorithm
  outType := match(inType,x)
    local Type ty;

    case (_,0) then inType;
    else
      equation
        ty = unliftArray(inType);
      then
        unliftArrayX(ty,x-1);
  end match;
end unliftArrayX;

public function arrayAppend
  "Appends a new element to a DAE.ARRAY."
  input DAE.Exp head;
  input DAE.Exp rest;
  output DAE.Exp array;
algorithm
  array := match(head, rest)
    local
      DAE.Type ty;
      Boolean scalar;
      list<DAE.Exp> expl;
      Integer dim;
      DAE.Dimensions dims;

    case (_, DAE.ARRAY(
        DAE.T_ARRAY(ty = ty, dims = DAE.DIM_INTEGER(dim) :: dims),
        scalar,
        expl))
      equation
        dim = dim + 1;
        dims = DAE.DIM_INTEGER(dim) :: dims;
      then
        DAE.ARRAY(DAE.T_ARRAY(ty, dims), scalar, head :: expl);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Expression.arrayAppend failed.");
      then
        fail();
  end match;
end arrayAppend;


public function arrayDimensionSetFirst
  "Updates the first dimension of an array type."
  input DAE.Type inArrayType;
  input DAE.Dimension dimension;
  output DAE.Type outArrayType;
algorithm
  outArrayType := match(inArrayType, dimension)
    local
      DAE.Type ty;
      DAE.Dimensions rest_dims;

    case (DAE.T_ARRAY(ty = ty, dims = _ :: rest_dims), _)
      then DAE.T_ARRAY(ty, dimension :: rest_dims);
  end match;
end arrayDimensionSetFirst;

/***************************************************/
/* Getter  */
/***************************************************/

public function toReal
  "Returns the value of a constant Real expression."
  input DAE.Exp inExp;
  output Real outReal;
algorithm
  outReal := match inExp
    case DAE.RCONST() then inExp.real;
    case DAE.ICONST() then intReal(inExp.integer);
    case DAE.CAST() then toReal(inExp.exp);
    case DAE.ENUM_LITERAL() then intReal(inExp.index);
  end match;
end toReal;

public function toBool
  "Returns the value of a constant Boolean expression."
  input DAE.Exp inExp;
  output Boolean outBool;
algorithm
  DAE.BCONST(outBool) := inExp;
end toBool;

public function realExpIntLit "returns the int value if expression is constant Real that can be represented by an Integer"
  input DAE.Exp exp;
  output Option<Integer> oi;
algorithm
  oi := match exp
    local
      Real r;
      Integer i;
      Option<Integer> op;
    case (DAE.RCONST(real = r))
      equation
        i = realInt(r);
        op = if realEq(r,intReal(i)) then SOME(i) else NONE();
      then op;
    else NONE();
  end match;
end realExpIntLit;

public function expInt "returns the int value if expression is constant Integer"
  input DAE.Exp exp;
  output Integer i;
algorithm
  i := match exp
    case DAE.ICONST() then exp.integer;
    case DAE.ENUM_LITERAL() then exp.index;
    case DAE.BCONST() then if exp.bool then 1 else 0;
  end match;
end expInt;

public function getClockInterval
  "Returns a real interval expression for any clock kind; 0.0 if unknown."
  input DAE.ClockKind inClk;
  output DAE.Exp outIntvl;
protected
  DAE.Exp e, e2;
  Integer res;
algorithm
  outIntvl := match inClk
    case DAE.REAL_CLOCK(e)
      then e;
    case DAE.INTEGER_CLOCK(e, e2)
      then DAE.BINARY(
             DAE.CAST(DAE.T_REAL_DEFAULT, e),
             DAE.DIV(DAE.T_REAL_DEFAULT),
             DAE.CAST(DAE.T_REAL_DEFAULT, e2));
    case DAE.BOOLEAN_CLOCK(e, e2)
      then e2; // startInterval
    else
      then DAE.RCONST(0.0);
  end match;
end getClockInterval;

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

public function sconstEnumNameString
  input DAE.Exp exp;
  output String str;
algorithm
  str := match exp
    local
      String s;
      Absyn.Path name;
    case DAE.SCONST(s) then s;
    case DAE.ENUM_LITERAL(name) then AbsynUtil.pathString(name);
  end match;
end sconstEnumNameString;

public function varName "Returns the name of a Var"
  input DAE.Var v;
  output String name;
algorithm
  name := match(v)
    case(DAE.TYPES_VAR(name = name)) then name;
  end match;
end varName;

public function varType "Returns the type of a Var"
  input DAE.Var v;
  output DAE.Type tp;
algorithm
  tp := match(v)
    case(DAE.TYPES_VAR(ty = tp)) then tp;
  end match;
end varType;

public function expOrDerCref
"Returns the componentref if DAE.Exp is a CREF or DER(CREF)"
  input DAE.Exp inExp;
  output DAE.ComponentRef outComponentRef;
  output Boolean isDer;
algorithm
  (outComponentRef, isDer) :=
  match (inExp)
    local ComponentRef cr;
    case DAE.CREF(componentRef = cr) then (cr, false);
    case DAE.CALL(path = Absyn.IDENT(name = "der"),expLst={DAE.CREF(cr,_)}) then (cr, true);
  end match;
end expOrDerCref;

public function expCref
"Returns the componentref if DAE.Exp is a CREF,"
  input DAE.Exp inExp;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inExp)
    local ComponentRef cr;
    case (DAE.CREF(componentRef = cr)) then cr;
  end match;
end expCref;

public function expCrefNegCref
"Returns the componentref if DAE.Exp is a CREF or -CREF"
  input DAE.Exp inExp;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inExp)
    local ComponentRef cr;
    case (DAE.CREF(componentRef = cr)) then cr;
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr))) then cr;
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr))) then cr;
  end match;
end expCrefNegCref;

public function expCrefTuple
"Returns the componentref if the expression in inTuple is a CREF."
  input tuple<DAE.Exp, Boolean> inTuple;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inTuple)
    local ComponentRef cr;
    case ((DAE.CREF(componentRef = cr),_)) then cr;
  end match;
end expCrefTuple;

public function expCrefInclIfExpFactors
"Returns the componentref if DAE.Exp is a CREF, or the factors of CREF if expression is an if expression.
  This is used in e.g. the tearing algorithm to detect potential division by zero in
  expressions like 1/(if b then 1.0 else x) which could lead to division by zero if b is false and x is 0; "
  input DAE.Exp inExp;
  output list<DAE.ComponentRef> outComponentRefs;
algorithm
  outComponentRefs:=
  match (inExp)
    local ComponentRef cr; DAE.Exp c,tb,fb;
      list<DAE.Exp> f;
      list<DAE.ComponentRef> crefs;
    case (DAE.CREF(componentRef = cr)) then {cr};
    case(DAE.IFEXP(_,tb,fb)) equation
      f = List.select(listAppend(factors(tb),factors(fb)),isCref);
      crefs = List.map(f,expCref);
    then crefs;
  end match;
end expCrefInclIfExpFactors;

public function getArrayContents "returns the list of expressions in the array"
  input DAE.Exp e;
  output list<DAE.Exp> es;
algorithm
  DAE.ARRAY(array=es) := e;
end getArrayContents;

public function getArrayOrMatrixContents
  "Returns the contents of an array or matrix as a list of expressions."
  input DAE.Exp inExp;
  output list<DAE.Exp> outContents;
algorithm
  outContents := match(inExp)
    local
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mat;
      DAE.Type ty, el_ty;
      DAE.Dimensions dims;
      Boolean sc;

    case DAE.ARRAY(array = expl) then expl;
    case DAE.MATRIX(ty = DAE.T_ARRAY(el_ty, _ :: dims), matrix = mat)
      equation
        ty = DAE.T_ARRAY(el_ty, dims);
        sc = Types.basicType(el_ty);
      then
        List.map2(mat, makeArray, ty, sc);

  end match;
end getArrayOrMatrixContents;

protected function makeASUBsForDimension"makes all asubs for the complete dimension of the exp."
  input DAE.Exp eIn;
  output list<DAE.Exp> eLstOut={};
protected
  Integer size;
  DAE.Dimensions dims;
algorithm
  dims := expDimensions(eIn);
  try
    {DAE.DIM_INTEGER(integer=size)} := dims;
    for i in size:-1:1 loop
      eLstOut := makeASUBSingleSub(eIn,DAE.ICONST(i))::eLstOut;
    end for;
  else
    eLstOut := {};
  end try;
end makeASUBsForDimension;

public function getComplexContents "returns the list of expressions from a complex structure like array,record,call,tuple...
author:Waurich TUD 2014-04"
  input DAE.Exp e;
  output list<DAE.Exp> es;
algorithm
  es := matchcontinue(e)
    local
      Boolean noArr;
      DAE.ComponentRef cref;
      DAE.Exp exp, exp1, exp2;
      DAE.Type ty;
      list<DAE.Exp> expLst, expLst1, expLst2;
      list<list<DAE.Exp>> expLstLst;
      list<DAE.ComponentRef> crefs;
    case(DAE.CREF())
      equation
        expLst = arrayElements(e);
        noArr = listLength(expLst)==1;
        exp = listHead(expLst);
        noArr = noArr  and expEqual(exp,e);
        expLst = if noArr then {} else expLst;
      then
        expLst;

    case(DAE.BINARY(exp1=exp1,operator=DAE.ADD_ARR(),exp2=exp2))
      equation
        if isArray(exp1) then
          expLst1 = getComplexContents(exp1);
        else
          expLst1 = makeASUBsForDimension(exp1);
        end if;
        if isArray(exp2) then
          expLst2 = getComplexContents(exp2);
        else
          expLst2 = makeASUBsForDimension(exp2);
        end if;
          //print("complexed expLst1:\n"+ExpressionDump.printExpListStr(expLst1)+"\n");
          //print("complexed expLst2:\n"+ExpressionDump.printExpListStr(expLst2)+"\n");
        ty = typeof(listHead(expLst1));
        expLst = List.threadMap(expLst1,expLst2,function makeBinaryExp(inOp=DAE.ADD(ty)));
      then
        expLst;

    case(DAE.CALL(expLst=expLst))
      equation
         expLstLst = List.map(expLst,getComplexContentsInCall);
         expLst = List.flatten(expLstLst);
      then
        expLst;
    case(DAE.RECORD(exps=expLst))
      then
        expLst;
    case(DAE.ARRAY())
      equation
      expLst = arrayElements(e);
      then
        expLst;
    case(DAE.MATRIX(matrix=expLstLst))
      equation
        expLst = List.flatten(expLstLst);
      then
        expLst;
    case(DAE.TUPLE(PR=expLst))
      then
        expLst;
    case(DAE.CAST(exp=exp))
      equation
        expLst = getComplexContents(exp);
      then
        expLst;
    case(DAE.ASUB(exp=exp))
      equation
        expLst = getComplexContents(exp);
      then
        expLst;
    else {};
  end matchcontinue;
end getComplexContents;

protected function getComplexContentsInCall"gets the scalars for the complex expressions inside a function call"
  input DAE.Exp expIn;
  output list<DAE.Exp> expsOut;
protected
  list<DAE.Exp> expLst;
algorithm
  expLst := getComplexContents(expIn);
  expsOut := if listEmpty(expLst) then {expIn} else expLst;
end getComplexContentsInCall;

public function getArrayOrRangeContents "returns the list of expressions in the array"
  input DAE.Exp e;
  output list<DAE.Exp> es;
algorithm
  es := match e
    local
      Boolean bstart,bstop;
      Integer istart,istep,istop;
      Real rstart,rstep,rstop;
      list<list<DAE.Exp>> matrix;
      DAE.Type ty;
    case DAE.ARRAY(array=es) then es;
    case DAE.MATRIX(matrix=matrix,ty=ty)
      equation
        ty = Types.unliftArray(ty);
        es = List.map2(matrix,makeArray,ty,not Types.arrayType(ty));
      then es;
    case DAE.CREF(ty=DAE.T_ARRAY(dims=DAE.DIM_INTEGER(istop)::_))
      equation
        es = List.map(ExpressionSimplify.simplifyRange(1,1,istop), makeIntegerExp);
        es = List.map1r(es, makeASUBSingleSub, e);
      then es;
    case DAE.RANGE(start = DAE.BCONST(bstart), step = NONE(), stop = DAE.BCONST(bstop))
      then List.map(ExpressionSimplify.simplifyRangeBool(bstart, bstop), makeBoolExp);

    case DAE.RANGE(start = DAE.ICONST(istart), step = NONE(), stop = DAE.ICONST(istop))
      then List.map(ExpressionSimplify.simplifyRange(istart,1,istop), makeIntegerExp);

    case DAE.RANGE(start = DAE.ICONST(istart), step = SOME(DAE.ICONST(istep)), stop = DAE.ICONST(istop))
      then List.map(ExpressionSimplify.simplifyRange(istart,istep,istop), makeIntegerExp);

    case DAE.RANGE(start = DAE.RCONST(rstart), step = NONE(), stop = DAE.RCONST(rstop))
      then List.map(ExpressionSimplify.simplifyRangeReal(rstart,1.0,rstop), makeRealExp);

    case DAE.RANGE(start = DAE.RCONST(rstart), step = SOME(DAE.RCONST(rstep)), stop = DAE.RCONST(rstop))
      then List.map(ExpressionSimplify.simplifyRangeReal(rstart,rstep,rstop), makeRealExp);
  end match;
end getArrayOrRangeContents;

public function get2dArrayOrMatrixContent "returns the list of expressions in the array"
  input DAE.Exp e;
  output list<list<DAE.Exp>> outExps;
algorithm
  outExps := match e
    local
      list<DAE.Exp> es;
      list<list<DAE.Exp>> ess;
    case DAE.ARRAY(array=es) then List.map(es,getArrayContents);
    case DAE.MATRIX(matrix=ess) then ess;
  end match;
end get2dArrayOrMatrixContent;

// stefan
public function unboxExpType
"takes a type, and if it is boxed, unbox it
  otherwise return the given type"
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    local
      Type ty;
    case(DAE.T_METABOXED(ty = ty)) then ty;
    else inType;
  end match;
end unboxExpType;

public function unboxExp
"takes an expression and unboxes it if it is boxed"
  input DAE.Exp ie;
  output DAE.Exp outExp;
algorithm
  outExp := match (ie)
    local
      DAE.Exp e;
    case (DAE.BOX(e)) then unboxExp(e);
    else ie;
  end match;
end unboxExp;

public function boxExp
"takes an expression and boxes it"
  input DAE.Exp e;
  output DAE.Exp outExp;
algorithm
  outExp := match (e)
    case (DAE.BOX(_)) then e;
    else DAE.BOX(e);
  end match;
end boxExp;

public function subscriptIndexExp
  "Returns the expression in a subscript index.
  If the subscript is not an index the function fails."
  input DAE.Subscript inSubscript;
  output DAE.Exp outExp;
algorithm
  DAE.INDEX(exp = outExp) := inSubscript;
end subscriptIndexExp;

public function getSubscriptExp
  "Returns the subscript expression, or fails on DAE.WHOLEDIM."
  input DAE.Subscript inSubscript;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSubscript)
    local DAE.Exp e;

    case DAE.SLICE(exp = e) then e;
    case DAE.INDEX(exp = e) then e;
    case DAE.WHOLE_NONEXP(exp = e) then e;
  end match;
end getSubscriptExp;

public function subscriptNonExpandedExp
"Returns the expression in a subscript representing non-expanded array.
  If the subscript is not WHOLE_NONEXP the function fails."
  input DAE.Subscript inSubscript;
  output DAE.Exp outExp;
algorithm
  outExp:=
  match (inSubscript)
    local DAE.Exp e;
    case (DAE.WHOLE_NONEXP(exp = e)) then e;
  end match;
end subscriptNonExpandedExp;

public function subscriptIsFirst
  "Returns true if the given subscript is the first index for a dimension, i.e.
   1, false or the first enumeration literal in an enumeration."
  input DAE.Subscript inSubscript;
  output Boolean outIsFirst;
algorithm
  outIsFirst := match (inSubscript)
    case DAE.INDEX(exp=DAE.ICONST(1)) then true;
    case DAE.INDEX(exp=DAE.BCONST(false)) then true;
    case DAE.INDEX(exp=DAE.ENUM_LITERAL(index=1)) then true;
  end match;
end subscriptIsFirst;

public function nthArrayExp "author: PA
  Returns the nth expression of an array expression."
  input DAE.Exp inExp;
  input Integer inInteger;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      DAE.Exp e1, e2, e_1, e_2;
      list<DAE.Exp> expl;
      Operator op;
      Type ty;

    case DAE.BINARY(operator=op, exp1=e1, exp2=e2) equation
      ty = typeofOp(op);
      true = Types.isArray(ty);
      e_1 = nthArrayExp(e1, inInteger);
      e_2 = nthArrayExp(e2, inInteger);
    then DAE.BINARY(e_1, op, e_2);

    case DAE.ARRAY(array=expl) equation
      e1 = listGet(expl, inInteger);
    then e1;

    else inExp;
  end matchcontinue;
end nthArrayExp;

public function expLastSubs
"Return the last subscripts of a Exp"
  input DAE.Exp inExp;
  output list<DAE.Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  match (inExp)
    local
      ComponentRef cr;
      list<DAE.Subscript> subs;
      DAE.Exp e;

    case (DAE.CREF(componentRef=cr))
      equation
        subs = ComponentReference.crefLastSubs(cr);
      then subs;

    case (DAE.UNARY(exp=e))
      equation
        subs = expLastSubs(e);
      then subs;
  end match;
end expLastSubs;

public function expDimensions
  "Tries to return the dimensions from an expression, typically an array."
  input DAE.Exp inExp;
  output DAE.Dimensions outDims;
algorithm
  outDims := match(inExp)
    local
      DAE.Type tp;
      Exp e;

    case DAE.ARRAY(ty = tp) then arrayDimension(tp);
    case DAE.MATRIX(ty = tp) then arrayDimension(tp);
    case DAE.LUNARY(exp = e) then expDimensions(e);
    case DAE.LBINARY(exp1 = e) then expDimensions(e);
    case DAE.CALL(attr=DAE.CALL_ATTR(ty = tp)) then arrayDimension(tp);

  end match;
end expDimensions;

public function arrayDimension "
Author BZ
Get dimension of array.
"
  input DAE.Type tp;
  output DAE.Dimensions dims;
algorithm
  dims := match(tp)
    case(DAE.T_ARRAY(dims = dims)) then dims;
    else {};
  end match;
end arrayDimension;

public function arrayTypeDimensions
"Return the array dimensions of a type."
  input DAE.Type tp;
  output DAE.Dimensions dims;
algorithm
  dims := match(tp)
    case(DAE.T_ARRAY(dims = dims)) then dims;
  end match;
end arrayTypeDimensions;

public function subscriptDimensions
  "Converts a list of subscript to a list of dimensions."
  input list<DAE.Subscript> inSubscripts;
  output DAE.Dimensions outDimensions;
algorithm
  outDimensions := List.map(inSubscripts, subscriptDimension);
end subscriptDimensions;

public function subscriptDimension
  "Converts a subscript to a dimension by interpreting the subscript as a
   dimension."
  input DAE.Subscript inSubscript;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inSubscript)
    local
      Integer x;
      DAE.Exp e;
      String sub_str;

    case DAE.INDEX(exp = DAE.ICONST(x)) then DAE.DIM_INTEGER(x);
    case DAE.INDEX(exp = e) then DAE.DIM_EXP(e);
    case DAE.WHOLEDIM() then DAE.DIM_UNKNOWN();

    // Special cases for non-expanded arrays
    case DAE.WHOLE_NONEXP(exp = DAE.ICONST(x))
      guard not Config.splitArrays()
      then
        DAE.DIM_INTEGER(x);

    case DAE.WHOLE_NONEXP(exp=e)
      guard not Config.splitArrays()
      then
        DAE.DIM_EXP(e);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        sub_str = ExpressionDump.subscriptString(inSubscript);
        Debug.traceln("- Expression.subscriptDimension failed on " + sub_str);
      then
        fail();

  end match;
end subscriptDimension;

public function arrayEltType
" Returns the element type of an array expression."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    local Type t;
    case (DAE.T_ARRAY(ty = t)) then arrayEltType(t);
    else inType;
  end match;
end arrayEltType;

public function sizeOf
"Returns the size of an ET_ARRAY or ET_COMPLEX"
  input DAE.Type inType;
  output Integer i;
algorithm
  i := matchcontinue inType
    local
      DAE.Dimensions ad;
      Integer nr;
      list<Integer> lstInt;
      list<Var> varLst;
      list<DAE.Type> typs;
      Type ty;

    // count the variables in array
    case DAE.T_ARRAY(dims = ad)
      equation
        nr = dimensionSize(List.reduce(ad, dimensionsMult));
        nr = nr * sizeOf(inType.ty);
      then
        nr;

    // count the variables in record
    case DAE.T_COMPLEX(varLst = varLst)
      equation
        lstInt = List.mapMap(varLst, varType, sizeOf);
        nr = List.reduce(lstInt, intAdd);
      then
        nr;

    case DAE.T_TUPLE(types=typs)
      equation
        nr = List.applyAndFold(typs, intAdd, sizeOf, 0);
      then
        nr;
/* Size of Enumeration is 1 like a Integer
    case DAE.T_ENUMERATION(index=NONE(),names=strlst)
      then
        listLength(strlst);
*/
    case DAE.T_FUNCTION(funcResultType=ty)
      then
        sizeOf(ty);

    case DAE.T_METATYPE(ty=ty)
      then sizeOf(ty);

    // 0 for T_UNKNOWN as it can only appear in tuples for WILD()??!!
    case DAE.T_UNKNOWN() then 0;

    // for all other consider it just 1 variable
    else 1;
  end matchcontinue;
end sizeOf;

public function dimensionSize
  "Extracts an integer from an array dimension"
  input DAE.Dimension dim;
  output Integer value;
algorithm
  value := match(dim)
    local
      Integer i;
    case DAE.DIM_INTEGER(integer = i) then i;
    case DAE.DIM_ENUM(size = i) then i;
    case DAE.DIM_BOOLEAN() then 2;
    case DAE.DIM_EXP(exp = DAE.ICONST(integer = i)) then i;
    case DAE.DIM_EXP(exp = DAE.ENUM_LITERAL(index = i)) then i;
    // else algorithm
      // Error.addInternalError("Function dimensionSize failed to extract size from dimension. Make sure
         // you have dimension that is evaluated if you want to use this function.", sourceInfo());
      // then fail();
  end match;
end dimensionSize;

public function addDimensions
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output DAE.Dimension dim;
algorithm
  dim := matchcontinue (dim1,dim2)
    local
      Integer i1,i2,i;
    case (_,_)
      equation
        i = dimensionSize(dim1)+dimensionSize(dim2);
      then DAE.DIM_INTEGER(i);
    else DAE.DIM_UNKNOWN();
  end matchcontinue;
end addDimensions;

public function dimensionSizeAll
  "Extracts an integer from an array dimension. Also handles DIM_EXP and
  DIM_UNKNOWN if checkModel is used."
  input DAE.Dimension dim;
  output Integer value;
algorithm
  value := matchcontinue(dim)
    local
      Integer i;
      DAE.Exp e;
    case DAE.DIM_INTEGER(integer = i) then i;
    case DAE.DIM_ENUM(size = i) then i;
    case DAE.DIM_BOOLEAN() then 2;
    case DAE.DIM_EXP(exp = e) then expInt(e);
    case DAE.DIM_EXP()
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
      then
        0;
    case DAE.DIM_UNKNOWN()
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
      then
        0;
  end matchcontinue;
end dimensionSizeAll;

public function dimensionsSizes
  "Extracts a list of integers from a list of array dimensions"
  input DAE.Dimensions inDims;
  output list<Integer> outValues;
algorithm
  outValues := List.map(inDims, dimensionSizeAll);
end dimensionsSizes;

public function typeof "Retrieves the Type of the Expression"
  input DAE.Exp inExp;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inExp)
    local
      Type tp;
      Operator op;
      DAE.Exp e1,e2,e3,e,iterExp,operExp;
      list<DAE.Exp> explist,exps;
      Absyn.Path p;
      String msg;
      DAE.Type ty, iterTp, operTp;
      list<DAE.Type> tys, typeVars;
      Integer i,i1,i2;
      DAE.Dimension dim;
      DAE.Dimensions iterdims;

    case DAE.ICONST() then DAE.T_INTEGER_DEFAULT;
    case DAE.RCONST() then DAE.T_REAL_DEFAULT;
    case DAE.SCONST() then DAE.T_STRING_DEFAULT;
    case DAE.BCONST() then DAE.T_BOOL_DEFAULT;
    case DAE.CLKCONST() then DAE.T_CLOCK_DEFAULT;
    case DAE.ENUM_LITERAL(name = p, index=i) then DAE.T_ENUMERATION(SOME(i), p, {}, {}, {});
    case DAE.CREF(ty = tp) then tp;
    case DAE.BINARY(operator = op) then typeofOp(op);
    case DAE.UNARY(operator = op) then typeofOp(op);
    case DAE.LBINARY(operator = op) then typeofOp(op);
    case DAE.LUNARY(operator = op) then typeofOp(op);
    case DAE.RELATION(operator = op) then typeofRelation(typeofOp(op));
    case DAE.IFEXP(expThen = e2) then typeof(e2);
    case DAE.CALL(attr = DAE.CALL_ATTR(ty=tp)) then tp;
    case DAE.RECORD(ty=tp) then tp;
    case DAE.PARTEVALFUNCTION(ty=tp) then tp;
    case DAE.ARRAY(ty = tp) then tp;
    case DAE.MATRIX(ty = tp) then tp;
    case DAE.RANGE(ty = tp) then tp;
    case DAE.CAST(ty = tp) then tp;
    case DAE.ASUB(exp = e,sub=explist)
      equation
        // Count the number of scalar subscripts, and remove as many dimensions.
        i = sum(1 for e guard(isScalar(e)) in explist);
        tp = unliftArrayX(typeof(e), i);
      then
        tp;
    case DAE.TSUB(ty = tp) then tp;
    case DAE.RSUB() then inExp.ty;
    case DAE.CODE(ty = tp) then tp;
      /* array reduction with known size */
    case DAE.REDUCTION(iterators={DAE.REDUCTIONITER(exp=iterExp,guardExp=NONE())},expr = operExp, reductionInfo=DAE.REDUCTIONINFO(exprType=DAE.T_ARRAY(dims=dim::_),path = Absyn.IDENT("array")))
      equation
        false = dimensionKnown(dim);
        iterTp = typeof(iterExp);
        operTp = typeof(operExp);
        DAE.T_ARRAY(dims=iterdims) = iterTp;
        tp = Types.liftTypeWithDims(operTp, iterdims);
      then tp;
    case DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(exprType=ty))
      then Types.simplifyType(ty);
    case DAE.SIZE(_,NONE()) then DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()});
    case DAE.SIZE(_,SOME(_)) then DAE.T_INTEGER_DEFAULT;

    // MetaModelica extension
    case DAE.LIST() then DAE.T_METATYPE(DAE.T_METALIST_DEFAULT);
    case DAE.CONS() then DAE.T_METATYPE(DAE.T_METALIST_DEFAULT);
    case DAE.META_TUPLE(exps)
      equation
         tys = List.map(exps, typeof);
      then
        DAE.T_METATYPE(DAE.T_METATUPLE(tys));
    case DAE.TUPLE(exps)
      equation
         tys = List.map(exps, typeof);
      then DAE.T_TUPLE(tys, NONE());
    case DAE.META_OPTION() then DAE.T_METATYPE(DAE.T_NONE_DEFAULT);
    case DAE.METARECORDCALL(path=p, index = i, typeVars=typeVars)
      then DAE.T_METATYPE(DAE.T_METARECORD(p, AbsynUtil.stripLast(p), typeVars, i, {}, false));
    case DAE.BOX(e)
      then DAE.T_METATYPE(DAE.T_METABOXED(typeof(e)));
    case DAE.MATCHEXPRESSION(et=tp)
      then tp;
    case DAE.UNBOX(ty = tp) then tp;
    case DAE.SHARED_LITERAL(exp = e) then typeof(e);
    // A little crazy, but sometimes we call typeof on things that will not be used in the end...
    case DAE.EMPTY(ty = tp) then tp;

    case e
      equation
        msg = "- Expression.typeof failed for " + ExpressionDump.printExpStr(e);
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then fail();
  end matchcontinue;
end typeof;

protected function typeofRelation
"Boolean or array of boolean"
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    local
      Type ty,ty1;
      DAE.Dimensions dims;
    case DAE.T_ARRAY(ty=ty,dims=dims)
      equation
        _ = typeofRelation(ty);
      then
        DAE.T_ARRAY(ty,dims);
    else DAE.T_BOOL_DEFAULT;
  end match;
end typeofRelation;

public function typeofOp
"Helper function to typeof"
  input DAE.Operator inOperator;
  output DAE.Type outType;
algorithm
  outType := match (inOperator)
    local Type t;

    case (DAE.ADD(ty = t)) then t;
    case (DAE.SUB(ty = t)) then t;
    case (DAE.MUL(ty = t)) then t;
    case (DAE.DIV(ty = t)) then t;
    case (DAE.POW(ty = t)) then t;
    case (DAE.UMINUS(ty = t)) then t;
    case (DAE.UMINUS_ARR(ty = t)) then t;
    case (DAE.ADD_ARR(ty = t)) then t;
    case (DAE.SUB_ARR(ty = t)) then t;
    case (DAE.MUL_ARR(ty = t)) then t;
    case (DAE.DIV_ARR(ty = t)) then t;
    case (DAE.MUL_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.ADD_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.SUB_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.MUL_SCALAR_PRODUCT(ty = t)) then t;
    case (DAE.MUL_MATRIX_PRODUCT(ty = t)) then t;
    case (DAE.DIV_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.DIV_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.POW_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.POW_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.POW_ARR(ty = t)) then t;
    case (DAE.POW_ARR2(ty = t)) then t;
    case (DAE.AND(ty = t)) then t;
    case (DAE.OR(ty = t)) then t;
    case (DAE.NOT(ty = t)) then t;
    case (DAE.LESS(ty = t)) then t;
    case (DAE.LESSEQ(ty = t)) then t;
    case (DAE.GREATER(ty = t)) then t;
    case (DAE.GREATEREQ(ty = t)) then t;
    case (DAE.EQUAL(ty = t)) then t;
    case (DAE.NEQUAL(ty = t)) then t;
    case (DAE.USERDEFINED()) then DAE.T_UNKNOWN_DEFAULT;
  end match;
end typeofOp;

public function getRelations
"Retrieve all function sub expressions in an expression."
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match (inExp)
    local
      DAE.Exp e,e1,e2,cond,tb,fb;
      list<DAE.Exp> rellst1,rellst2,rellst,rellst3,rellst4,xs;
      Type t;
      Boolean sc;

    case ((e as DAE.RELATION())) then {e};

    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        rellst1 = getRelations(e1);
        rellst2 = getRelations(e2);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;

    case (DAE.LUNARY(exp = e))
      equation
        rellst = getRelations(e);
      then
        rellst;

    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        rellst1 = getRelations(e1);
        rellst2 = getRelations(e2);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;

    case (DAE.IFEXP(expCond = cond,expThen = tb,expElse = fb))
      equation
        rellst1 = getRelations(cond);
        rellst2 = getRelations(tb);
        rellst3 = getRelations(fb);
        rellst4 = listAppend(rellst1, rellst2);
        rellst = listAppend(rellst3, rellst4);
      then
        rellst;

    case (DAE.ARRAY(array = {e}))
      equation
        rellst = getRelations(e);
      then
        rellst;

    case (DAE.ARRAY(ty = t,scalar = sc,array = (e :: xs)))
      equation
        rellst1 = getRelations(DAE.ARRAY(t,sc,xs));
        rellst2 = getRelations(e);
        rellst = listAppend(rellst1, rellst2);
      then
        rellst;

    case (DAE.UNARY(exp = e))
      equation
        rellst = getRelations(e);
      then
        rellst;

    else {};
  end match;
end getRelations;

public function getAllCrefs "author: lochel
  This function extracts all crefs from the input expression, except 'time'."
  input DAE.Exp inExp;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  (_, outCrefs) := traverseExpBottomUp(inExp, getAllCrefs2, {});
end getAllCrefs;

protected function getAllCrefs2
   input DAE.Exp inExp;
   input list<DAE.ComponentRef> inCrefList;
   output DAE.Exp outExp = inExp;
   output list<DAE.ComponentRef> outCrefList = inCrefList;
protected
  DAE.ComponentRef cr;
algorithm
  if isCref(inExp) then
    DAE.CREF(componentRef=cr) := inExp;
    if not ComponentReference.crefEqual(cr, DAE.crefTime) and not listMember(cr, inCrefList) then
      outCrefList := cr::outCrefList;
    end if;
  end if;
end getAllCrefs2;

public function getAllCrefsExpanded "author: ptaeuber
  This function extracts all crefs from the input expression (except 'time') and expands arrays and records."
  input DAE.Exp inExp;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  (_, outCrefs) := traverseExpBottomUp(inExp, getAllCrefsExpanded2, {});
end getAllCrefsExpanded;

protected function getAllCrefsExpanded2
   input DAE.Exp inExp;
   input list<DAE.ComponentRef> inCrefList;
   output DAE.Exp outExp = inExp;
   output list<DAE.ComponentRef> outCrefList = inCrefList;
protected
  DAE.ComponentRef cr;
  list<DAE.ComponentRef> crlst;
algorithm
  if isCref(inExp) then
    DAE.CREF(componentRef=cr) := inExp;
    crlst := ComponentReference.expandCref(cr, true);
    for c in crlst loop
      if not ComponentReference.crefEqual(c, DAE.crefTime) and not listMember(c, inCrefList) then
        outCrefList := c::outCrefList;
      end if;
    end for;
  end if;
end getAllCrefsExpanded2;

public function allTerms
"similar to terms, but also performs expansion of
 multiplications to reveal more terms, like for instance:
 allTerms((a+b)*(b+c)) => {a*b,a*c,b*b,b*c}"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue(inExp)
    local
      list<DAE.Exp> f1,f2,res,f2_1;
      DAE.Exp e1,e2,e;
      Type tp;
      ComponentRef cr;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        res = listAppend(f1, f2);
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        f2_1 = List.map(f2, negate);
        res = listAppend(f1, f2_1);
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        res = listAppend(f1, f2);
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        f2_1 = List.map(f2, negate);
        res = listAppend(f1, f2_1);
      then
        res;

    // terms( a*(b+c)) => {a*b, c*b}
    case (DAE.BINARY(e1,DAE.MUL(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e2);
        f1 = List.map1(f1,makeProduct,e1);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.BINARY(e1,DAE.MUL_ARR(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e2);
        f1 = List.map1(f1,makeProduct,e1);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e2);
        f1 = List.map1(f1,makeProduct,e1);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    // terms( (b+c)*a) => {b*a, c*a}
    case (DAE.BINARY(e1,DAE.MUL(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e1);
        f1 = List.map1(f1,makeProduct,e2);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.BINARY(e1,DAE.MUL_ARR(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e1);
        f1 = List.map1(f1,makeProduct,e2);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e1);
        f1 = List.map1(f1,makeProduct,e2);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    // terms( (b+c)/a) => {b/a, c/a}
    case (DAE.BINARY(e1,DAE.DIV(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e1);
        f1 = List.map1(f1,expDiv,e2);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.BINARY(e1,DAE.DIV_ARR(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e1);
        f1 = List.map1(f1,expDiv,e2);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e1);
        f1 = List.map1(f1,expDiv,e2);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.BINARY(e1,DAE.DIV_SCALAR_ARRAY(_),e2))
      equation
        (f1 as _::_::_) = allTerms(e1);
        f1 = List.map1(f1,expDiv,e2);
        f1 = List.flatten(List.map(f1,allTerms));
      then
        f1;

    case (DAE.UNARY(operator = DAE.UMINUS(),exp=e1))
      equation
        f1 = allTerms(e1);
        f1 = List.map(f1,negate);
      then
        f1;

    case (DAE.UNARY(operator = DAE.UMINUS_ARR(),exp=e1))
      equation
        f1 = allTerms(e1);
        f1 = List.map(f1,negate);
      then
        f1;

    case (DAE.LUNARY(operator = DAE.NOT(), exp = e1))
      equation
        f1 = allTerms(e1);
        f1 = List.map(f1,negate);
      then
        f1;

    case (DAE.ASUB(exp = e1,sub=f2))
      equation
        f1 = allTerms(e1);
        f1 = List.map1(f1,makeASUB,f2);
      then
        f1;
/*
    case (e as DAE.BINARY(operator = DAE.MUL())) then {e};
    case (e as DAE.BINARY(operator = DAE.MUL_ARR())) then {e};
    case (e as DAE.BINARY(operator = DAE.MUL_ARRAY_SCALAR())) then {e};
    case (e as DAE.BINARY(operator = DAE.DIV())) then {e};
    case (e as DAE.BINARY(operator = DAE.DIV_ARR())) then {e};
    case (e as DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR())) then {e};
    case (e as DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY())) then {e};
    case (e as DAE.BINARY(operator = DAE.POW())) then {e};
    case (e as DAE.BINARY(operator = DAE.POW_ARR())) then {e};
    case (e as DAE.BINARY(operator = DAE.POW_ARR2())) then {e};
    case (e as DAE.BINARY(operator = DAE.POW_ARRAY_SCALAR())) then {e};
    case (e as DAE.BINARY(operator = DAE.POW_SCALAR_ARRAY())) then {e};
    case (e as DAE.CREF()) then {e};
    case (e as DAE.ICONST()) then {e};
    case (e as DAE.RCONST()) then {e};
    case (e as DAE.SCONST()) then {e};
    case ((e as DAE.ENUM_LITERAL())) then {e};
    case (e as DAE.UNARY()) then {e};
    case (e as DAE.IFEXP()) then {e};
    case (e as DAE.CALL()) then {e};
    case (e as DAE.RECORD()) then {e};
    case (e as DAE.PARTEVALFUNCTION()) then {e};
    case (e as DAE.ARRAY()) then {e};
    case (e as DAE.MATRIX()) then {e};
    case (e as DAE.RANGE()) then {e};
    case (e as DAE.CAST()) then {e};
    case (e as DAE.ASUB()) then {e};
    case (e as DAE.SIZE()) then {e};
    case (e as DAE.REDUCTION()) then {e};
*/
    else {inExp};
  end matchcontinue;
end allTerms;

public function allTermsForCref
"simliar to terms, but also perform expansion of
 multiplications to reveal more terms, like for instance:
 allTerms((a(x)+b(x))*(c+d)) => {a(x)*(c+d),b(x)*(c+d)}"
  input DAE.Exp inExp;
  input DAE.ComponentRef cr "x";
  input MapFunc inFunc;
  output list<DAE.Exp> outExpLstWithX;
  output list<DAE.Exp> outExpLstWithoutX;

  partial function MapFunc
    input DAE.Exp inElement;
    input DAE.ComponentRef inCr;
    output Boolean outElement;
  end MapFunc;

algorithm
  (outExpLstWithX,outExpLstWithoutX) := matchcontinue (inExp)
    local
      list<DAE.Exp> f1,f2,fx1,fx2,res,resx;
      DAE.Exp e1,e2,e;
      Type tp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(),exp2 = e2))
      equation
        (fx1,f1) = allTermsForCref(e1, cr, inFunc);
        (fx2,f2) = allTermsForCref(e2, cr, inFunc);
        res = listAppend(f1, f2);
        resx = listAppend(fx1, fx2);
      then
        (resx, res);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(),exp2 = e2))
      equation
        (fx1,f1) = allTermsForCref(e1, cr, inFunc);
        (fx2,f2) = allTermsForCref(e2, cr, inFunc);
        f2 = List.map(f2, negate);
        fx2 = List.map(fx2, negate);
        res = listAppend(f1, f2);
        resx = listAppend(fx1, fx2);
      then
        (resx,res);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(),exp2 = e2))
      equation
        (fx1,f1) = allTermsForCref(e1, cr, inFunc);
        (fx2,f2) = allTermsForCref(e2, cr, inFunc);
        res = listAppend(f1, f2);
        resx = listAppend(fx1, fx2);
      then
        (resx, res);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(),exp2 = e2))
      equation
        (fx1,f1) = allTermsForCref(e1, cr, inFunc);
        (fx2,f2) = allTermsForCref(e2, cr, inFunc);
        f2 = List.map(f2, negate);
        fx2 = List.map(fx2, negate);
        res = listAppend(f1, f2);
        resx = listAppend(fx1, fx2);
      then
        (resx,res);

    // terms( a*(b+c)) => {a*b, c*b}
    case (DAE.BINARY(e1,DAE.MUL(_),e2))
      guard inFunc(e2,cr)
      equation
        (fx1, f1) = allTermsForCref(e2, cr, inFunc);
        (fx1, f2) = List.split1OnTrue(fx1, inFunc, cr);
        res = listAppend(f1, f2);
        e = makeSum1(res);
        e = expMul(e, e1);
        fx1 = List.map1(fx1,expMul,e1);
        if not isZero(e) then
          if expHasCrefNoPreOrStart(e1,cr) then
            fx1 = e :: fx1;
            f1 = {};
          else
            f1 = {e};
          end if;
        end if;
        //f1 = List.flatten(List.map1(fx1,allTermsForCref, cr));
      then
        (fx1, f1);

    // terms( (b+c)*a) => {b*a, c*a}
    case (DAE.BINARY(e1,DAE.MUL(_),e2))
      guard inFunc(e1,cr)
      equation
        (fx1, f1) = allTermsForCref(e1, cr, inFunc);
        (fx1, f2) = List.split1OnTrue(fx1, inFunc, cr);
        res = listAppend(f1, f2);
        e = makeSum1(res);
        e = expMul(e, e2);
        fx1 = List.map1(fx1,expMul,e2);
        if not isZero(e) then
          if expHasCrefNoPreOrStart(e1,cr) then
            fx1 = e :: fx1;
            f1 = {};
          else
            f1 = {e};
          end if;
        end if;
        //fx1 = List.flatten(List.map1(fx1,allTermsForCref, cr));
      then
        (fx1, f1);

    // terms( (b+c)/a) => {b/a, c/a}
    case (DAE.BINARY(e1,DAE.DIV(_),e2))
      guard inFunc(e1,cr)
      equation
        (fx1, f1) = allTermsForCref(e1, cr, inFunc);
        (fx1, f2) = List.split1OnTrue(fx1, inFunc, cr);
        res = listAppend(f1, f2);
        e = makeSum1(res);
        e = makeDiv(e, e2);
        fx1 = List.map1(fx1,makeDiv,e2);
        if not isZero(e) then
          if expHasCrefNoPreOrStart(e1,cr) then
            fx1 = e :: fx1;
            f1 = {};
          else
            f1 = {e};
          end if;
        end if;
        //fx1 = List.flatten(List.map1(fx1,allTermsForCref, cr));
      then
        (fx1, f1);

    // -()
    case (DAE.UNARY(operator = DAE.UMINUS(),exp=e1))
      equation
        (fx1,f1) = allTermsForCref(e1, cr, inFunc);
        f1 = List.map(f1,negate);
        fx1 = List.map(fx1,negate);
      then
        (fx1, f1);

    else
      equation
        if inFunc(inExp,cr) then
          res = {};
          resx = {inExp};
        else
          resx = {};
          res = {inExp};
        end if;
        then (resx, res);
  end matchcontinue;
end allTermsForCref;


public function termsExpandUnary
  "Returns the terms of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match inExp
                local DAE.Exp e;
                case (DAE.UNARY(operator = DAE.UMINUS(),exp=e)) then List.map(terms(e), negate);
                else terms(inExp);
               end match;
end termsExpandUnary;

public function terms
  "Returns the terms of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := terms2(inExp,{},false);
end terms;

protected function terms2
  "Returns the terms of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  input list<DAE.Exp> inAcc;
  input Boolean neg;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match (inExp,inAcc,neg)
    local
      DAE.Exp e1,e2,e;
      list<DAE.Exp> acc;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(),exp2 = e2),acc,_)
      equation
        acc = terms2(e2,acc,neg);
        acc = terms2(e1,acc,neg);
      then acc;

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(),exp2 = e2),acc,_)
      equation
        acc = terms2(e2,acc,not neg);
        acc = terms2(e1,acc,neg);
      then acc;

    case (e,acc,true)
      equation
        e = negate(e);
      then e::acc;
    case (e,acc,_) then e::acc;
  end match;
end terms2;

public function quotient
"author: PA
  Returns the quotient of an expression.
  For instance e = p/q returns (p,q) for numerator p and denominator q."
  input DAE.Exp inExp;
  output DAE.Exp num;
  output DAE.Exp denom;
algorithm
  (num,denom):=
  matchcontinue (inExp)
    local
      DAE.Exp e1,e2,p,q;
      Type tp;
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(),exp2 = e2)) then (e1,e2);  /* (numerator,denominator) */
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2))
      equation
        (p,q) = quotient(e1);
        tp = typeof(p);
      then
        (DAE.BINARY(e2,DAE.MUL(tp),p),q);
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2))
      equation
        (p,q) = quotient(e2);
        tp = typeof(p);
      then
        (DAE.BINARY(e1,DAE.MUL(tp),p),q);
  end matchcontinue;
end quotient;

public function factors
"Returns the factors of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  // TODO: Remove this listReverse as it is pointless.
  // It transforms a*b to b*a, but the testsuite expects this :(
  outExpLst := listReverse(factorsWork(inExp,{},false));
end factors;

protected function factorsWork
"Returns the factors of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  input output list<DAE.Exp> acc;
  input Boolean doInverseFactors "Decides if a factor e should be 1/e instead";
algorithm
  acc := match inExp
    local
      DAE.Exp e1,e2,e;

    case DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2)
      algorithm
        acc := factorsWork(e1,acc,doInverseFactors);
        acc := factorsWork(e2,acc,doInverseFactors);
      then acc;
    case DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = DAE.T_REAL()),exp2 = e2)
      algorithm
        acc := factorsWork(e1,acc,doInverseFactors);
        acc := factorsWork(e2,acc,not doInverseFactors);
      then acc;
    case DAE.ICONST(integer = 1)
      then acc;
    case DAE.RCONST(real = 1.0)
      then acc;
    // case DAE.UNARY() // factor(-(x*y)) is -(x*y) ??
    else (if doInverseFactors then inverseFactors(inExp) else inExp) :: acc;
  end match;
end factorsWork;

public function inverseFactors
"each expression in the list inversed.
  For example: inverseFactors {a, 3+b} => {1/a, 1/3+b}"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      Type tp2,tp;
      DAE.Exp e1,e2,e;
      DAE.Operator op;

    // e1^e2 =>e1^(-e2)
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2))
      equation
        tp2 = typeof(e2);
      then
        DAE.BINARY(e1,DAE.POW(tp),DAE.UNARY(DAE.UMINUS(tp2),e2));

    // e1 / e2 = e2 / e1
    case (DAE.BINARY(exp1 = e1,operator = op as DAE.DIV(),exp2 = e2))
      equation
       false = isZero(e1);
      then
        DAE.BINARY(e2,op,e1);

    case e
      equation
        false = isZero(e);
        tp = typeof(e);
        e = match(tp)
          case DAE.T_REAL() then DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.T_REAL_DEFAULT),e);
          case DAE.T_INTEGER() then DAE.BINARY(DAE.ICONST(1),DAE.DIV(DAE.T_INTEGER_DEFAULT),e);
        end match;
      then
        e;
  end matchcontinue;
end inverseFactors;

public function expandFactors
"
 Returns the factors of the expression if any as a list of expressions.
 e.g.
 -(x*(x*y)^n) -> {-1,x,x^n,x^n}
"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  // TODO: Remove this listReverse as it is pointless.
  // It transforms a*b to b*a, but the testsuite expects this :(
  // issue with expEqual(a*b,b*a) return false
  outExpLst := listReverse(expandFactorsWork(inExp,{},false));
end expandFactors;

protected function expandFactorsWork
"Returns the factors of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  input output list<DAE.Exp> acc;
  input Boolean doInverseFactors "Decides if a factor e should be 1/e instead";
algorithm

  acc := match inExp
    local
      DAE.Exp e1,e2,e3,e;
      Type tp;
      list<DAE.Exp> pow_acc, pow_acc2;
       Operator op;

    // (x*y)^n = x^n*y^n
    case DAE.BINARY(DAE.BINARY(e1,DAE.MUL(),e2), DAE.POW(), e3)
      equation
        pow_acc = expandFactorsWork(e1,{},doInverseFactors);
        pow_acc = expPowLst(pow_acc, e3);

        pow_acc2 = expandFactorsWork(e2,{},doInverseFactors);
        pow_acc2 = expPowLst(pow_acc2, e3);

        acc = listAppend(pow_acc, acc);
        acc = listAppend(pow_acc2, acc);
      then acc;
    // (x/y)^n = x^n*y^(-n)
    case DAE.BINARY(DAE.BINARY(e1,DAE.DIV(),e2), DAE.POW(), e3)
      equation
        pow_acc = expandFactorsWork(e1,{},doInverseFactors);
        pow_acc = expPowLst(pow_acc, e3);

        pow_acc2 = expandFactorsWork(e2,{},doInverseFactors);
        pow_acc2 = expPowLst(pow_acc2, negate(e3));

        acc = listAppend(pow_acc, acc);
        acc = listAppend(pow_acc2, acc);
      then acc;
    // (x^n)^m = x^(n*m)
    case DAE.BINARY(DAE.BINARY(e1,DAE.POW(),e2), DAE.POW(), e3)
      equation
        e = expMul(e2,e3);
        pow_acc = expandFactorsWork(e1,{},doInverseFactors);
        pow_acc = expPowLst(pow_acc, e);

        acc = listAppend(pow_acc, acc);
      then acc;
    // ToDo
    // exp(x + y) = exp(x)*exp(y)
    // exp(x - y) = exp(x)/exp(y)
    // abs(x*y) = abs(x)*abs(y)
    // abs(x/y) = abs(x)/abs(y);

    // x/0 = x * 1/0
    case DAE.BINARY(e1, op as DAE.DIV(tp), e2)
      guard isZero(e2)
      algorithm
        if doInverseFactors then
          e := e2;
        else
          e := DAE.BINARY(makeConstOne(tp), op, e2);
        end if;
        acc := expandFactorsWork(e1,acc,doInverseFactors);
      then e::acc;

    // -(x) = -1*x
    case DAE.UNARY(DAE.UMINUS(tp),e1)
      equation
        e = makeConstOne(tp);
        acc = expandFactorsWork(e1,acc,doInverseFactors);
        e = negate(e);
      then e::acc;
    case DAE.UNARY(DAE.UMINUS_ARR(tp),e1)
      equation
        e = makeConstOne(tp);
        acc = expandFactorsWork(e1,acc,doInverseFactors);
        e = negate(e);
      then e::acc;

   else
     equation
       acc = expandFactorsWork3(inExp,acc,doInverseFactors);
     then expandFactorsWork2(acc,doInverseFactors);

   end match;

end expandFactorsWork;

protected function expandFactorsWork3
  input DAE.Exp inExp;
  input output list<DAE.Exp> acc;
  input Boolean doInverseFactors "Decides if a factor e should be 1/e instead";
protected
  DAE.Exp e1,e2, e;
  Operator op;
algorithm
   acc := matchcontinue(inExp)
            case _
                then factorsWork(inExp,acc,doInverseFactors);
            case DAE.BINARY(e1, DAE.MUL(), e2)
              equation
                 acc = expandFactorsWork(e1, acc, doInverseFactors);
                 acc = expandFactorsWork(e2, acc, doInverseFactors);
              then
                 acc;
            case DAE.BINARY(DAE.BINARY(e, op  as DAE.DIV(), e1),  DAE.DIV(), e2)
               equation
                  e = DAE.BINARY(e, op , expMul(e1, e2));
                  acc = expandFactorsWork(e, acc, doInverseFactors);
                then
                  acc;
            case DAE.BINARY(DAE.BINARY(e, DAE.MUL(), e1),  op as DAE.DIV(), e2)
               equation
                  acc = expandFactorsWork(e, acc, doInverseFactors);
                  acc = expandFactorsWork(DAE.BINARY(e1, op, e2), acc, doInverseFactors);
                then
                  acc;
            case _
              //equation
              //  print("\ninExp*: ");print(ExpressionDump.printExpStr(inExp));
              then inExp :: acc;
         end matchcontinue;


end expandFactorsWork3;


protected function expandFactorsWork2
  input list<DAE.Exp> inAcc;
  input Boolean doInverseFactors "Decides if a factor e should be 1/e instead";
  output list<DAE.Exp> outExpLst = {};
protected
  list<DAE.Exp> tmpExpLst;
algorithm

for elem in inAcc loop
  tmpExpLst := match(elem)
                 case(DAE.BINARY(DAE.BINARY(_,DAE.DIV(),_), DAE.POW(), _)) then expandFactorsWork(elem,{},doInverseFactors);
                 case(DAE.BINARY(DAE.BINARY(_,DAE.MUL(),_), DAE.POW(), _)) then expandFactorsWork(elem,{},doInverseFactors);
                 case(DAE.BINARY(DAE.BINARY(_,DAE.POW(),_), DAE.POW(), _)) then expandFactorsWork(elem,{},doInverseFactors);
                 case(DAE.UNARY(DAE.UMINUS(),_))  then expandFactorsWork(elem,{},doInverseFactors);
                 case(DAE.UNARY(DAE.UMINUS_ARR(),_))  then expandFactorsWork(elem,{},doInverseFactors);
                 else {elem};
               end match;
  outExpLst := listAppend(tmpExpLst, outExpLst);
end for;

end expandFactorsWork2;


public function getTermsContainingX
"Retrieves all terms of an expression containing a variable,
  given as second argument (in the form of an Exp)"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp1;
  output DAE.Exp outExp2;
algorithm
  (outExp1,outExp2) := matchcontinue (inExp1,inExp2)
    local
      DAE.Exp xt1,nonxt1,xt2,nonxt2,xt,nonxt,e1,e2,cr,e,zero;
      Type ty;
      Boolean res;
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty),exp2 = e2),(cr as DAE.CREF()))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.ADD(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.ADD(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty),exp2 = e2),(cr as DAE.CREF()))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.SUB(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.SUB(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UMINUS(ty = ty),exp = e),(cr as DAE.CREF()))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UMINUS(ty),xt1);
        nonxt = DAE.UNARY(DAE.UMINUS(ty),nonxt1);
      then
        (xt,nonxt);
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = ty),exp2 = e2),(cr as DAE.CREF()))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.ADD_ARR(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.ADD_ARR(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = ty),exp2 = e2),(cr as DAE.CREF()))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.SUB_ARR(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.SUB_ARR(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(ty = ty),exp = e),(cr as DAE.CREF()))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UMINUS_ARR(ty),xt1);
        nonxt = DAE.UNARY(DAE.UMINUS_ARR(ty),nonxt1);
      then
        (xt,nonxt);
    case (e,(cr as DAE.CREF(ty = ty)))
      equation
        res = expContains(e, cr);
        (zero,_) = makeZeroExpression(arrayDimension(ty));
        xt = if res then e else zero;
        nonxt = if res then zero else e;
      then
        (xt,nonxt);
    else
      equation
        /*Print.printBuf("Expression.getTerms_containingX failed: ");
        ExpressionDump.printExp(e);
        Print.printBuf("\nsolving for: ");
        ExpressionDump.printExp(cr);
        Print.printBuf("\n");*/
      then
        fail();
  end matchcontinue;
end getTermsContainingX;

public function flattenArrayExpToList "returns all non-array expressions of an array expression as a long list
E.g. {[1,2;3,4],[4,5;6,7]} => {1,2,3,4,4,5,6,7}"
  input DAE.Exp e;
  output list<DAE.Exp> expLst;
algorithm
  expLst := matchcontinue(e)
    local
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mexpl;
    case(DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=DAE.ARRAY(array=expl)))
      equation
        expl = List.flatten(List.map(expl,flattenArrayExpToList));
        expLst = List.map(expl,negate);
      then expLst;
    case(DAE.ARRAY(array=expl))
      equation
        expLst = List.flatten(List.map(expl,flattenArrayExpToList));
      then expLst;
    case(DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=DAE.MATRIX(matrix=mexpl)))
      equation
        expl = List.flatten(List.map(List.flatten(mexpl),flattenArrayExpToList));
        expLst = List.map(expl,negate);
      then expLst;
    case(DAE.MATRIX(matrix=mexpl))
      equation
        expLst = List.flatten(List.map(List.flatten(mexpl),flattenArrayExpToList));
      then expLst;
    else {e};
  end matchcontinue;
end flattenArrayExpToList;

/***************************************************/
/* generate  */
/***************************************************/

public function makeNoEvent " adds a noEvent call around an expression"
input DAE.Exp e1;
output DAE.Exp res;
algorithm
  res := Expression.makePureBuiltinCall("noEvent", {e1}, DAE.T_BOOL_DEFAULT);
end makeNoEvent;

public function makeAbs ""
input DAE.Exp e1;
output DAE.Exp res;
algorithm
  res := Expression.makePureBuiltinCall("abs", {e1}, DAE.T_REAL_DEFAULT);
end makeAbs;

public function makeSign ""
input DAE.Exp e1;
output DAE.Exp res;
algorithm
  res := Expression.makePureBuiltinCall("sign", {e1}, DAE.T_REAL_DEFAULT);
end makeSign;


public function makeNestedIf "creates a nested if expression given a list of conditions and
guarded expressions and a default value (the else branch)"
  input list<DAE.Exp> inConds "conditions";
  input list<DAE.Exp> inTbExps " guarded expressions, for each condition";
  input DAE.Exp fExp "default value, else branch";
  output DAE.Exp ifExp;
algorithm
  ifExp := match(inConds,inTbExps,fExp)
    local DAE.Exp c,tbExp; list<DAE.Exp> conds, tbExps;
    case({c},{tbExp},_)
    then DAE.IFEXP(c,tbExp,fExp);
    case(c::conds,tbExp::tbExps,_)
      equation
        ifExp = makeNestedIf(conds,tbExps,fExp);
      then DAE.IFEXP(c,tbExp,ifExp);
  end match;
end makeNestedIf;

public function makeCrefExp
"Makes an expression of a component reference, given also a type"
  input DAE.ComponentRef inCref;
  input DAE.Type inExpType;
  output DAE.Exp outExp;
algorithm
  outExp := match(inCref, inExpType)
    local
      ComponentRef cref;
      Type tGiven, tExisting;

    case (cref, tGiven)
      equation
        if Flags.isSet(Flags.CHECK_DAE_CREF_TYPE)
        then // check type
          tExisting = ComponentReference.crefLastType(cref);
          if not valueEq(tGiven, tExisting)
          then // type not the same
            Debug.traceln("Warning: Expression.makeCrefExp: cref " + ComponentReference.printComponentRefStr(cref) + " was given type DAE.CREF.ty: " +
                      Types.unparseType(tGiven) +
                      " is different from existing DAE.CREF.componentRef.ty: " +
                      Types.unparseType(tExisting));
          end if;
        end if;
      then
        DAE.CREF(cref, tGiven);

  end match;
end makeCrefExp;


public function crefToExp
" mahge:
  creates a DAE.Exp from a cref by exrtacting the type from the types of the cref (if qualified) and
  considering the dimensions and subscripts that exist in the cref.
"
  input DAE.ComponentRef cr;
  output DAE.Exp cref;
algorithm
  cref := DAE.CREF(cr,ComponentReference.crefTypeFull(cr));
end crefToExp;




public function crefExp
" ***deprecated.
  mahge: use crefToExp(). This is not correct. We need to consider more than just the last subs.

Author: BZ, 2008-08
generate an DAE.CREF(ComponentRef, Type) from a ComponenRef, make array type correct from subs"
  input DAE.ComponentRef cr;
  output DAE.Exp cref;
algorithm
  cref := match(cr)
    local
      Type ty1,ty2;
      list<DAE.Subscript> subs;

    case _
      equation
        ty1 = ComponentReference.crefLastType(cr);
        cref = match(ty1)
          case DAE.T_ARRAY()
            equation
              subs = ComponentReference.crefLastSubs(cr);
              ty2 = unliftArrayTypeWithSubs(subs,ty1);
            then DAE.CREF(cr,ty2);
          else DAE.CREF(cr,ty1);
        end match;
      then
        cref;

  end match;
end crefExp;

public function makeASUB
"@author: adrpo
  Creates an ASUB given an expression and a list of expression indexes.
  If flag -d=checkASUB is ON we give a warning that the given exp is
  not a component reference."
  input DAE.Exp inExp;
  input list<DAE.Exp> inSubs;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp,inSubs)
    local
      DAE.Exp exp;
      list<DAE.Exp> subs,subs1,subs2;

    // We need to be careful when constructing ASUB's. All subscripts should be in a list.
    case (DAE.ASUB(exp,subs1),subs2)
      equation
        subs = listAppend(subs1,subs2);
        exp = DAE.ASUB(exp,subs);
      then
        exp;

    case(_, _)
      equation
        if Flags.isSet(Flags.CHECK_ASUB) // check the DAE.ASUB
        then
          _ = match(inExp) // check the DAE.ASUB so that the given expression is NOT a cref
            case (DAE.CREF())
              equation
                Debug.traceln("Warning: makeASUB: given expression: " +
                        ExpressionDump.printExpStr(inExp) +
                        " contains a component reference!\n" +
                        " Subscripts exps: [" + stringDelimitList(List.map(inSubs, ExpressionDump.printExpStr), ",")+ "]\n" +
                        "DAE.ASUB should not be used for component references, instead the subscripts should be added directly to the component reference!");
              then ();
            else (); // check the DAE.ASUB -> was not a cref
          end match;
        end if;
        exp = DAE.ASUB(inExp,inSubs);
      then
        exp;

  end match;
end makeASUB;

public function makeASUBSingleSub
  input DAE.Exp exp;
  input DAE.Exp sub;
  output DAE.Exp outExp;
algorithm
  outExp := makeASUB(exp,{sub});
end makeASUBSingleSub;

public function makeTuple
  input list<DAE.Exp> inExps;
  output DAE.Exp outExp;
algorithm
  outExp := if listLength(inExps) > 1 then DAE.TUPLE(inExps) else List.first(inExps);
end makeTuple;


public function generateCrefsExpFromExpVar "
Author: Frenkel TUD 2010-05"
  input DAE.Var inVar;
  input DAE.ComponentRef inCrefPrefix;
  output DAE.Exp outCrefExp;
algorithm outCrefExp := match(inVar,inCrefPrefix)
  local
    String name;
    DAE.Type ty;
    DAE.ComponentRef cr;
    DAE.Exp e;

  case (DAE.TYPES_VAR(name=name,ty=ty),_)
    equation
      cr = ComponentReference.crefPrependIdent(inCrefPrefix,name,{},ty);
      e = makeCrefExp(cr, ty);
    then
      e;

 end match;
end generateCrefsExpFromExpVar;

public function generateCrefsFromExpVar "
Author: Frenkel TUD 2010-05"
  input DAE.Var inVar;
  input DAE.ComponentRef inCrefPrefix;
  output DAE.ComponentRef outCref;
algorithm outCref := match(inVar,inCrefPrefix)
  local
    String name;
    DAE.Type ty;
    DAE.ComponentRef cr;
    DAE.Exp e;

  case (DAE.TYPES_VAR(name=name,ty=ty),_)
  equation
    cr = ComponentReference.crefPrependIdent(inCrefPrefix,name,{},ty);
  then
    cr;
 end match;
end generateCrefsFromExpVar;

public function generateCrefsExpFromExp
  input DAE.Exp inExp;
  input DAE.ComponentRef inCrefPrefix;
  output DAE.Exp outCrefExp;
algorithm
  outCrefExp := match inExp
    local
      String name;
      DAE.Type ty;
      DAE.ComponentRef cr;
      DAE.Exp e;
      Absyn.Path p1,p2;
      list<DAE.Exp> explst;
      Boolean b;
      DAE.CallAttributes attr;

    case DAE.CREF(componentRef=DAE.WILD()) then inExp;

    case DAE.ARRAY(ty=ty, scalar=b, array=explst)
      equation
        explst = List.map1(explst, generateCrefsExpFromExp, inCrefPrefix);
      then DAE.ARRAY(ty, b, explst);

    case DAE.CALL(path=p1,expLst=explst,attr=attr as DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(p2))))
      equation
        true = AbsynUtil.pathEqual(p1,p2) "is record constructor";
        explst = List.map1(explst, generateCrefsExpFromExp, inCrefPrefix);
      then
        DAE.CALL(p1,explst,attr);

    case DAE.CREF(componentRef=cr,ty=ty)
      equation
        name = ComponentReference.crefModelicaStr(cr);
        cr = ComponentReference.crefPrependIdent(inCrefPrefix,name,{},ty);
        e = makeCrefExp(cr, ty);
      then
        e;
    case DAE.UNARY(exp=e)
      then negate(generateCrefsExpFromExp(e, inCrefPrefix)); /*ToDo: check*/
    else
      equation
        print("Expression.generateCrefsExpFromExp: fail for" + ExpressionDump.printExpStr(inExp) + "\n");
      then fail();
  end match;
end generateCrefsExpFromExp;

public function generateCrefsExpLstFromExp
  input DAE.Exp inExp;
  input Option<DAE.ComponentRef> inCrefPrefix;
  output list<DAE.Exp> outCrefExpList;
algorithm
  outCrefExpList := match(inExp,inCrefPrefix)
    local
      String name;
      DAE.Type ty;
      DAE.ComponentRef cr, incref;
      DAE.Exp e;
      Absyn.Path p1,p2;
      list<DAE.Exp> explst;
      Boolean b;

    case (DAE.TUPLE(PR=explst), _)
      equation
        explst = List.flatten(List.map1(explst, generateCrefsExpLstFromExp, inCrefPrefix));
      then explst;

    case (DAE.ARRAY( array=explst), _)
      equation
        explst = List.flatten(List.map1(explst, generateCrefsExpLstFromExp, inCrefPrefix));
      then explst;

    case (DAE.CALL(path=p1,expLst=explst,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(p2)))),_)
      guard AbsynUtil.pathEqual(p1,p2) "is record constructor"
      then List.flatten(List.map1(explst, generateCrefsExpLstFromExp, inCrefPrefix));

    case(DAE.CALL(path = Absyn.IDENT("der"),expLst = {DAE.CREF(componentRef = incref)}), _)
      equation
        cr = ComponentReference.crefPrefixDer(incref);
        e = Expression.crefExp(cr);
      then generateCrefsExpLstFromExp(e, inCrefPrefix);

    case (DAE.CREF(componentRef=cr,ty=ty),SOME(incref))
      equation
        name = ComponentReference.crefModelicaStr(cr);
        cr = ComponentReference.crefPrependIdent(incref,name,{},ty);
        e = makeCrefExp(cr, ty);
      then
        {e};

    case (DAE.CREF(),NONE()) then {inExp};

    case (DAE.UNARY(exp=e),_)
      then generateCrefsExpLstFromExp(e, inCrefPrefix);/*ToDo: check*/

    else
      equation
        print("Expression.generateCrefsExpLstFromExp: fail for " + ExpressionDump.printExpStr(inExp) + "\n");
      then fail();

  end match;
end generateCrefsExpLstFromExp;

public function makeArray
  input list<DAE.Exp> inElements;
  input DAE.Type inType;
  input Boolean inScalar;
  output DAE.Exp outArray;
algorithm
  outArray := DAE.ARRAY(inType, inScalar, inElements);
end makeArray;

public function makeArrayFromList
  input list<DAE.Exp> inElements;
  output DAE.Exp outArray;
protected
  DAE.Type ty;
algorithm
  ty := typeof(listHead(inElements));
  outArray := DAE.ARRAY(DAE.T_ARRAY(ty,{DAE.DIM_INTEGER(listLength(inElements))}), not Types.isArray(ty), inElements);
end makeArrayFromList;

public function makeScalarArray
  "Constructs an array of the given scalar type."
  input list<DAE.Exp> inExpLst;
  input DAE.Type et;
  output DAE.Exp outExp;
protected
  Integer i;
algorithm
  i := listLength(inExpLst);
  outExp := DAE.ARRAY(DAE.T_ARRAY(et, {DAE.DIM_INTEGER(i)}), true, inExpLst);
end makeScalarArray;

public function makeRealArray
"Construct an array node of an DAE.Exp list of type REAL."
  input list<DAE.Exp> expl;
  output DAE.Exp outExp;
algorithm
  outExp := makeScalarArray(expl,DAE.T_REAL_DEFAULT);
end makeRealArray;

public function makeRealAdd
"Construct an add node of the two expressions of type REAL."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
algorithm
  outExp := DAE.BINARY(inExp1, DAE.ADD(DAE.T_REAL_DEFAULT), inExp2);
end makeRealAdd;

public function expAdd
"author: PA
  Adds two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(e1,e2)
    local
      Type tp;
      Boolean b;
      Operator op;
      Real r1,r2;
      Integer i1,i2;
      DAE.Exp e, x, y, z;
    case(_,_)
      equation
        true = isZero(e1);
      then e2;
    case(_,_)
      equation
        true = isZero(e2);
      then e1;
    case(DAE.RCONST(r1),DAE.RCONST(r2))
      equation
        r1 = realAdd(r1,r2);
      then
        DAE.RCONST(r1);
    case(DAE.ICONST(i1),DAE.ICONST(i2))
      equation
        i1 = intAdd(i1,i2);
      then
        DAE.ICONST(i1);
    /* a + (-b) = a - b */
    case (_,DAE.UNARY(operator=DAE.UMINUS(),exp=e))
      then
        expSub(e1,e);
    case (_,DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=e))
      then
        expSub(e1,e);
    // x +(-y)*z
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS(),x),op as DAE.MUL(),y))
      then
        expSub(e1,DAE.BINARY(x,op,y));
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(),x), op as DAE.MUL_ARR(),y))
      then
        expSub(e1,DAE.BINARY(x,op,y));
    // x +(-y)/z
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS(),x),op as DAE.DIV(),y))
      then
        expSub(e1,DAE.BINARY(x,op,y));
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(),x), op as DAE.DIV_ARR(),y))
      then
        expSub(e1,DAE.BINARY(x,op,y));
    /* -b + a = a - b */
    case (DAE.UNARY(operator=DAE.UMINUS(),exp=e),_)
      then
        expSub(e2,e);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=e),_)
      then
        expSub(e2,e);
    // (-y)*z+x
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(),x),op as DAE.MUL(),y),_)
      then
        expSub(e2,DAE.BINARY(x,op,y));
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(),x), op as DAE.MUL_ARR(),y),_)
      then
        expSub(e2,DAE.BINARY(x,op,y));
    // (-y)/z + x
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(),x),op as DAE.DIV(),y),_)
      then
        expSub(e2,DAE.BINARY(x,op,y));
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(),x), op as DAE.DIV_ARR(),y),_)
      then
        expSub(e2,DAE.BINARY(x,op,y));

    case (_,_)
      equation
        tp = typeof(e1);
        true = Types.isIntegerOrRealOrSubTypeOfEither(tp);
        b = DAEUtil.expTypeArray(tp) "  array_elt_type(tp) => tp\'" ;
        op = if b then DAE.ADD_ARR(tp) else DAE.ADD(tp);
      then
        DAE.BINARY(e1,op,e2);
    else
      equation
        tp = typeof(e1);
        true = Types.isEnumeration(tp);
      then
        DAE.BINARY(e1,DAE.ADD(tp),e2);
  end matchcontinue;
end expAdd;

public function expSub
"author: PA
  Subtracts two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(e1,e2)
    local
      Type tp;
      Boolean b;
      Operator op;
      Real r1,r2;
      Integer i1,i2;
      DAE.Exp e, x,y;
    case(_,_)
      equation
        true = isZero(e1);
      then
        negate(e2);
    case(_,_)
      equation
        true = isZero(e2);
      then
        e1;
    case(DAE.RCONST(r1),DAE.RCONST(r2))
      equation
        r1 = realSub(r1,r2);
      then
        DAE.RCONST(r1);
    case(DAE.ICONST(i1),DAE.ICONST(i2))
      equation
        i1 = intSub(i1,i2);
      then
        DAE.ICONST(i1);
    /* a - (-b) = a + b */
    case (_,DAE.UNARY(operator=DAE.UMINUS(),exp=e))
      then
        expAdd(e1,e);
    case (_,DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=e))
      then
        expAdd(e1,e);
    // x -(-y)*z
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS(),x),op as DAE.MUL(),y))
      then
        expAdd(e1,DAE.BINARY(x,op,y));
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(),x), op as DAE.MUL_ARR(),y))
      then
        expAdd(e1,DAE.BINARY(x,op,y));
    // x -(-y)/z
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS(),x),op as DAE.DIV(),y))
      then
        expAdd(e1,DAE.BINARY(x,op,y));
    case (_,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(),x), op as DAE.DIV_ARR(),y))
      then
        expAdd(e1,DAE.BINARY(x,op,y));
    /* - a - b = -(a + b) */
    case (DAE.UNARY(operator=DAE.UMINUS(),exp=e),_)
      equation
        e = expAdd(e,e2);
      then
        negate(e);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=e),_)
      equation
        e = expAdd(e,e2);
      then
        negate(e);
    case (_,_)
      equation
        tp = typeof(e1);
        if Types.isIntegerOrRealOrSubTypeOfEither(tp)
        then
          b = DAEUtil.expTypeArray(tp);
          op = if b then DAE.SUB_ARR(tp) else DAE.SUB(tp);
          outExp = DAE.BINARY(e1,op,e2);
        else if Types.isEnumeration(tp)
             then
               outExp = DAE.BINARY(e1,DAE.SUB(tp),e2);
             else
               fail();
             end if;
        end if;
      then
        outExp;

  end matchcontinue;
end expSub;

public function makeDiff
"Takes two expressions and create
 the difference between them"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp res;
algorithm
  res := if isZero(e2)
         then e1
         elseif isZero(e1)
             then negate(e2)
             else expSub(e1,e2);
end makeDiff;

public function makeDifference
"Takes two expressions and create
 the difference between them --> a-(b+c) = a-b-c"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp res;
algorithm
  res := makeDiff(e1, e2);
end makeDifference;

public function makeLBinary
"Makes a binary logical expression of all elements in the list."
  input list<DAE.Exp> inExpLst;
  input DAE.Operator op;
  output DAE.Exp outExp;
algorithm
  outExp := match (inExpLst,op)
    local
      DAE.Exp e1,e2,res;
      list<DAE.Exp> rest;
      String str;
    case ({},DAE.AND(_)) then DAE.BCONST(true);
    case ({},DAE.OR(_)) then DAE.BCONST(false);
    case ({e1},_) then e1;
    case ({e1, e2},_) then DAE.LBINARY(e1,op,e2);
    case ((e1 :: rest),_)
      equation
        res = makeLBinary(rest,op);
        res = DAE.LBINARY(e1,op,res);
      then res;
    else
      equation
        str = "Expression.makeLBinary failed for operator " + ExpressionDump.lbinopSymbol(op);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end makeLBinary;

public function makeSum1
"Takes a list of expressions an makes a sum
  expression sorting adding all elements in the list.

Note:
makeSum1 => (a + b) + c
makeSum => a + (b + c)
"


  input list<DAE.Exp> inExpLst;
  input Boolean simplify = false;
  output DAE.Exp outExp;
protected
  DAE.Exp e1,e2;
algorithm
  outExp := matchcontinue(inExpLst)
            case({}) then DAE.RCONST(0.0);
            case({e1}) then e1;
            case({e1,e2}) then expAdd(e1,e2);
            case(_)then makeSumWork(inExpLst, simplify);
            else
              equation
               if Flags.isSet(Flags.FAILTRACE) then
                 Debug.trace("-Expression.makeSum1 failed, DAE.Exp lst:");
                 Debug.trace(ExpressionDump.printExpListStr(inExpLst));
               end if;
              then fail();
            end matchcontinue;

end makeSum1;

protected function makeSumWork
"Takes a list of expressions an makes a sum
  expression adding all elements in the list."
  input list<DAE.Exp> inExpLst;
  input Boolean simplify = false;
  output DAE.Exp outExp;

protected
  Type tp;
  list<DAE.Exp> rest;
  DAE.Exp eLst;
  DAE.Operator op;

algorithm
  eLst :: rest := inExpLst;
  tp := typeof(eLst);
  op := if DAEUtil.expTypeArray(tp) then DAE.ADD_ARR(tp) else DAE.ADD(tp);

  outExp := eLst;
  for elem in rest loop
    outExp := if isZero(elem) then outExp elseif isZero(outExp) then elem elseif simplify then ExpressionSimplify.simplify1(DAE.BINARY(outExp, op, elem)) else DAE.BINARY(outExp, op, elem);
  end for;

end makeSumWork;

public function makeSum
"Takes a list of expressions an makes a sum
  expression adding all elements in the list."
  input list<DAE.Exp> inExpLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpLst)
    local
      DAE.Exp e1,e2,res;
      Boolean b1;
      Type tp;
      list<DAE.Exp> rest,lst;
      list<String> explst;
      String str;
      Operator op;
      Boolean b;
    case ({}) then DAE.RCONST(0.0);
    case ({e1}) then e1;
    case ({e1, e2})
      equation
        true = isZero(e1);
      then e2;
    case ({e1, e2})
      equation
        true = isZero(e2);
      then e1;
    case ({e1, e2})
      equation
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
        b = DAEUtil.expTypeArray(tp);
        op = if b then DAE.ADD_ARR(tp) else DAE.ADD(tp);
      then DAE.BINARY(e1, op, e2);
        //res = DAE.BINARY(e1, DAE.ADD(tp), e2);
      //then res;
    /*case ({e1,e2})
      equation
        b1 = isZero(e1);
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
        res = DAE.BINARY(e1,DAE.ADD(tp),e2);
        res = if_(b1,e2,res);
      then
        res;*/
    case ((e1 :: rest))
      equation
        b1 = isZero(e1);
        e2 = makeSum(rest);
        tp = typeof(e2);
        b = DAEUtil.expTypeArray(tp);
        op = if b then DAE.ADD_ARR(tp) else DAE.ADD(tp);
        res = DAE.BINARY(e1,op,e2);
        res = if b1 then e2 else res;
      then
        res;
    case (lst)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-Expression.makeSum failed, DAE.Exp lst:");
        explst = List.map(lst, ExpressionDump.printExpStr);
        str = stringDelimitList(explst, ", ");
        Debug.traceln(str);
      then
        fail();
  end matchcontinue;
end makeSum;

public function expMul
"author: PA
  Multiplies two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(e1,e2)
    local
      Type tp;
      Boolean b1,b2;
      Operator op;
      Real r1,r2;
      Integer i1,i2;
      DAE.Exp e1_1,e2_1;
    case(_,_)
      equation
        true = isZero(e1);
      then e1;
    case(_,_)
      equation
        true = isZero(e2);
      then e2;
    case(DAE.RCONST(real = 1.0),_)
      then e2;
    case(_,DAE.RCONST(real = 1.0))
      then e1;
    case(DAE.ICONST(1),_)
      then e2;
    case(_,DAE.ICONST(1))
      then e1;
    case(DAE.RCONST(r1),DAE.RCONST(r2))
      equation
        r1 = realMul(r1,r2);
      then
        DAE.RCONST(r1);
    case(DAE.ICONST(i1),DAE.ICONST(i2))
      equation
        i1 = intMul(i1,i2);
      then
        DAE.ICONST(i1);
    else
      equation
        tp = typeof(e1);
        true = Types.isIntegerOrRealOrSubTypeOfEither(tp);
        b1 = DAEUtil.expTypeArray(tp);
        tp = typeof(e2);
        true = Types.isIntegerOrRealOrSubTypeOfEither(tp);
        b2 = DAEUtil.expTypeArray(tp);
        /* swap e1 and e2 if we have scalar mul array */
        (e1_1,e2_1) = Util.swap((not b1) and b2, e1, e2);
        /* Create all kinds of multiplication with scalars or arrays */
        op = if b1 and b2 then DAE.MUL_ARR(tp) else (if b1==b2 then DAE.MUL(tp) else DAE.MUL_ARRAY_SCALAR(tp));
      then
        DAE.BINARY(e1_1,op,e2_1);
  end matchcontinue;
end expMul;

public function expPow "author: vitalij"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;

algorithm
  outExp := match(e1,e2)
    local
      Type tp;
      DAE.Exp e,e3,e4,e5;
      Real r1,r2;
      Boolean b;
      Operator op;

    // e1^1 = e1
    case(_,_) guard(isOne(e2))
    then e1;

    // e1^0 = 1
    case(_,_) guard(isZero(e2))
    then makeConstOne(typeof(e1));

    // 1^e2 = 1
    case (_,_) guard(isConstOne(e1))
    then e1;

    // 0^e2 = 0
    case (_,_) guard(isZero(e1) and expIsPositive(e2))
    then makeConstZero(typeof(e1));

    // (-e)^r = e^r if r is even
    case (DAE.UNARY(DAE.UMINUS(),e), _) guard(isEven(e2))
    then expPow(e, e2);

    // (x/y)^(-z) = (y/x)^z
    case (DAE.BINARY(e3, DAE.DIV(), e4), DAE.UNARY(DAE.UMINUS(),e5))
    equation
      e = makeDiv(e4,e3);
      e = expPow(e,e5);
    then e;

    // (e1/e2)^(-r) = (e2/e1)^r
    case (DAE.BINARY(e3, DAE.DIV(), e4) , _) guard(isNegativeOrZero(e2))
    then expPow(makeDiv(e4,e3), negate(e2));

    // x^0.5 => sqrt(x)
    case (_, _) guard(isHalf(e2))
    then Expression.makePureBuiltinCall("sqrt",{e1},DAE.T_REAL_DEFAULT);

    else equation
      tp = typeof(e1);
      b = DAEUtil.expTypeArray(tp);
      op = if b then DAE.POW_ARR(tp) else DAE.POW(tp);
    then DAE.BINARY(e1,op,e2);

  end match;
end expPow;

public function expPowLst
"
{a,b}^n -> {a^n, b^n}
author: vitalij"
  input list<DAE.Exp> expLst;
  input DAE.Exp n;
  output list<DAE.Exp> outExp = List.map1(expLst, expPow, n);
end expPowLst;

public function expMaxScalar "author: Frenkel TUD 2011-04
  returns max(e1,e2)."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
protected
  Type tp;
algorithm
  tp := typeof(e1);
  outExp := DAE.CALL(Absyn.IDENT("max"),{e1,e2},DAE.CALL_ATTR(tp,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
end expMaxScalar;

public function expOptMaxScalar
  input Option<DAE.Exp> e1;
  input Option<DAE.Exp> e2;
  output Option<DAE.Exp> outExp;
protected
algorithm
  outExp := match(e1,e2)
            local DAE.Exp e11, e22;
            case(_, NONE()) then e1;
            case(NONE(), ) then e2;
            case(SOME(e11), SOME(e22)) then SOME(expMaxScalar(e11, e22));
            end match;
end expOptMaxScalar;


public function expMinScalar "author: Frenkel TUD 2011-04
  returns min(e1,e2)."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
protected
  Type tp;
  Boolean b;
algorithm
  tp := typeof(e1);
  outExp := DAE.CALL(Absyn.IDENT("min"),{e1,e2},DAE.CALL_ATTR(tp, false, true, false, false, DAE.NO_INLINE(), DAE.NO_TAIL()));
end expMinScalar;

public function expOptMinScalar
  input Option<DAE.Exp> e1;
  input Option<DAE.Exp> e2;
  output Option<DAE.Exp> outExp;
protected
algorithm
  outExp := match(e1,e2)
            local DAE.Exp e11, e22;
            case(_, NONE()) then e1;
            case(NONE(), ) then e2;
            case(SOME(e11), SOME(e22)) then SOME(expMinScalar(e11, e22));
            end match;
end expOptMinScalar;


public function makeProductVector "takes and expression e1 and a list of expressisions {v1,v2,...,vn} and returns
{e1*v1,e1*v2,...,e1*vn}"
  input DAE.Exp e1;
  input list<DAE.Exp> v;
  output list<DAE.Exp> res;
algorithm
  res := List.map1(v,makeProduct,e1);
end makeProductVector;

public function makeScalarProduct
"calculate a scalr product <v,w>"
  input array<DAE.Exp> v;
  input array<DAE.Exp> w;
  output DAE.Exp s = DAE.RCONST(0.0);
protected
  Integer size1=arrayLength(v), size2= arrayLength(w);
algorithm
  if size1 <> size2 then
    print("makeScalarProduct faili.\n");
    return ;
  end if;

  s := makeSum1(list( expMul(arrayGet(v,i), arrayGet(w,i))  for i in 1:size1 ));
  (s,_) := ExpressionSimplify.simplify(s);

end makeScalarProduct;

public function lenVec
  input array<DAE.Exp> v;
  output DAE.Exp len = makeScalarProduct(v,v);
  algorithm
  len := Expression.makePureBuiltinCall("sqrt",{len},DAE.T_REAL_DEFAULT);
end lenVec;

public function addVec
  input array<DAE.Exp> v;
  input array<DAE.Exp> w;
  output array<DAE.Exp> y;

protected
  Integer size1=arrayLength(v), size2= arrayLength(w);
algorithm
  if size1 <> size2 then
    print("addVec fail.\n");
    return ;
  end if;
  y := arrayCreate(size1, DAE.RCONST(0.0));
  for i in 1:size1 loop
    arrayUpdate(y,i,expAdd(arrayGet(v,i), arrayGet(w,i)));
  end for;
end addVec;

public function subVec
  input array<DAE.Exp> v;
  input array<DAE.Exp> w;
  output array<DAE.Exp> y;

protected
  Integer size1=arrayLength(v), size2= arrayLength(w);
algorithm
  if size1 <> size2 then
    print("addVec fail.\n");
    return ;
  end if;
  y := arrayCreate(size1, DAE.RCONST(0.0));
  for i in 1:size1 loop
    arrayUpdate(y,i,expSub(arrayGet(v,i), arrayGet(w,i)));
  end for;
end subVec;


public function makeProduct
"Makes a product of two expressions"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp product;
algorithm
  product := makeProductLst({e1,e2});
end makeProduct;

public function makeProductLst
"Takes a list of expressions an makes a product
  expression multiplying all elements in the list."
  input list<DAE.Exp> inExpLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpLst)
    local
      DAE.Exp e1,res,e,e2,p1;
      list<DAE.Exp> es,rest,lst;
      Type tp;
      list<String> explst;
      String str;
      Boolean b_isZero,b1,b2;
    case ({}) then DAE.RCONST(1.0);
    case ({e1}) then e1;
    case ((e :: es)) /* to prevent infinite recursion, disregard constant 1. */
      equation
        true = isConstOne(e);
        res = makeProductLst(es);
      then
        res;
    // e1/e*e2 for e = 0 => fail
    case (DAE.BINARY(operator = DAE.DIV(),exp2 = e)::_)
      equation
        true = isZero(e);
      then
        fail();

    // e2*e1/e for e = 0 => fail
    case ({_,DAE.BINARY(operator = DAE.DIV(),exp2 = e)})
      equation
        true = isZero(e);
      then
        fail();
     case ((e :: _)) /* to prevent infinite recursion, disregard constant 0. */
      equation
        true = isZero(e);
      then e;
    case ({DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e),e2})
      equation
        true = isConstOne(e1);
      then
        DAE.BINARY(e2,DAE.DIV(tp),e);
    case ({e2,DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e)})
      equation
        true = isConstOne(e1);
      then
        DAE.BINARY(e2,DAE.DIV(tp),e);
    case ((DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e) :: es))
      equation
        true = isConstOne(e1);
        p1 = makeProductLst(es);
        res = DAE.BINARY(p1,DAE.DIV(tp),e);
        b_isZero = isZero(p1);
        res = if b_isZero then makeConstZero(typeof(e)) else res;
      then
        res;
    case ({e1,e2})
      equation
        true = isConstOne(e2);
      then
        e1;
    case ({e1,e2})
      equation
        b1 = isZero(e1);
        b2 = isZero(e2);
        b_isZero = boolOr(b1,b2);
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
        tp = checkIfOther(tp);
        res = DAE.BINARY(e1,DAE.MUL(tp),e2);
        res = if b_isZero then makeConstZero(tp) else res;
      then
        res;
    case ((e1 :: rest))
      equation
        e2 = makeProductLst(rest);
        tp = typeof(e1);
        tp = checkIfOther(tp);
        res = DAE.BINARY(e1,DAE.MUL(tp),e2);
        b1 = isZero(e1);
        b2 = isZero(e2);
        b_isZero = boolOr(b1,b2);
        res = if b_isZero then makeConstZero(typeof(e1)) else res;
      then
        res;
    case (lst)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("-Expression.makeProductLst failed, DAE.Exp lst:");
        explst = List.map(lst, ExpressionDump.printExpStr);
        str = stringDelimitList(explst, ", ");
        Debug.traceln(str);
      then
        fail();
  end matchcontinue;
end makeProductLst;

protected function checkIfOther
"Checks if a type is OTHER and in that case returns REAL instead.
 This is used to make proper transformations in case OTHER is
 retrieved from subexpression where it should instead be REAL or INT"
input DAE.Type inTp;
output DAE.Type outTp;
algorithm
  outTp := match(inTp)
    case DAE.T_UNKNOWN() then DAE.T_REAL_DEFAULT;
    else inTp;
  end match;
end checkIfOther;

public function expDiv "
function expDiv
  author: PA
  Divides two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
protected
  Type tp;
  Boolean b;
  Operator op;
algorithm
  tp := typeof(e1);
  true := Types.isIntegerOrRealOrSubTypeOfEither(tp);
  b := DAEUtil.expTypeArray(tp);
  op := if b then DAE.DIV_ARR(tp) else DAE.DIV(tp);
  outExp := DAE.BINARY(e1,op,e2);
end expDiv;

public function makeDiv "Takes two expressions and create a division"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp res;
algorithm
  res := match(e1,e2)
    case(_,_) guard(isZero(e1) and not isZero(e2))
    then e1;
    case(_,_) guard(isOne(e2))
    then e1;
    else expDiv(e1,e2);
  end match;
end makeDiv;

public function makeDivVector "takes and expression e1 and a list of expressisions {v1,v2,...,vn} and returns
{v1/e1,v2/e1,...,vn/e1}"
  input list<DAE.Exp> v;
  input DAE.Exp e1;
  output list<DAE.Exp> res;
algorithm
  res := List.map1(v,makeDiv,e1);
end makeDivVector;

public function makeAsubAddIndex "creates an ASUB given an expression and an index"
  input DAE.Exp e;
  input Integer indx;
  output DAE.Exp outExp = e;
algorithm
  outExp := match outExp
    case DAE.ASUB()
      algorithm
        outExp.sub := listAppend(outExp.sub, {DAE.ICONST(indx)});
      then
        outExp;

    else makeASUB(e, {DAE.ICONST(indx)});
  end match;
end makeAsubAddIndex;

public function makeIntegerExp
"Creates an integer constant expression given the integer input."
  input Integer i;
  output DAE.Exp e;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  e := DAE.ICONST(i);
end makeIntegerExp;

public function makeRealExp
"Creates an integer constant expression given the integer input."
  input Real r;
  output DAE.Exp e;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  e := DAE.RCONST(r);
end makeRealExp;

public function makeBoolExp
"Creates an integer constant expression given the integer input."
  input Boolean b;
  output DAE.Exp e;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  e := DAE.BCONST(b);
end makeBoolExp;

public function makeConstOne
"author: PA
  Create the constant value one, given a type that is INT or REAL"
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match (inType)
    case (DAE.T_INTEGER()) then DAE.ICONST(1);
    case (DAE.T_REAL()) then DAE.RCONST(1.0);
    else DAE.RCONST(1.0);
  end match;
end makeConstOne;

public function makeConstZero
"Generates a zero constant"
  input DAE.Type inType;
  output DAE.Exp const;
algorithm
  const := match(inType)
    case (DAE.T_REAL()) then DAE.RCONST(0.0);
    case (DAE.T_INTEGER()) then DAE.ICONST(0);
    else DAE.RCONST(0.0);
  end match;
end makeConstZero;

function makeConstNumber
  input DAE.Type ty;
  input Integer n;
  output DAE.Exp exp;
algorithm
  exp := match ty
    case DAE.T_INTEGER() then DAE.ICONST(n);
    else DAE.RCONST(n);
  end match;
end makeConstNumber;

public function makeConstZeroE
"Generates a zero constant, using type from inExp"
  input DAE.Exp iExp;
  output DAE.Exp const;
protected
  DAE.Type tp = typeof(iExp);
algorithm
  const := makeConstZero(tp);
end makeConstZeroE;


public function makeListOfZeros
  input Integer inDimension;
  output list<DAE.Exp> outList = {};
algorithm
  if (inDimension > 0) then
    for i in 1:inDimension loop
      outList := DAE.RCONST(0.0) :: outList;
    end for;
  end if;
end makeListOfZeros;

public function makeRealArrayOfZeros
  input Integer inDimension;
  output DAE.Exp outExp;
protected
  list<DAE.Exp> l;
algorithm
  l := makeListOfZeros(inDimension);
  outExp := makeRealArray(l);
end makeRealArrayOfZeros;

public function createZeroExpression
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  (outExp) := match (inType)
    local
      DAE.Exp e;
      list<DAE.Type> typeLst;
      list<DAE.Exp> expLst;
      DAE.Dimensions dims;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;
      Absyn.Path path;
      list<DAE.Var> varLst;
      list<String> varNames;

    // real and integer
    case (_) guard(isIntegerOrReal(inType)) then makeConstZero(inType);

    case DAE.T_TUPLE(types=typeLst) equation
      expLst = List.map(typeLst, createZeroExpression);
      e = DAE.TUPLE(expLst);
    then e;

    case DAE.T_ARRAY(dims=dims) equation
      (e, _) = makeZeroExpression(dims);
    then e;

    // record type
    case DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(path)) equation
      cr = DAE.CREF_IDENT("$TMP", inType, {});
      typeLst = list(v.ty for v in varLst);
      expLst = List.map(typeLst, createZeroExpression);
      varNames = List.map(varLst, varName);
      true = listLength(varNames) == listLength(expLst);
      e = DAE.RECORD(path, expLst, varNames, inType);
    then e;

    // all other are failing cases
    else fail();
  end match;
end createZeroExpression;


public function makeZeroExpression
" creates a Real or array<Real> zero expression with given dimensions, also returns its type"
  input DAE.Dimensions inDims;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := match(inDims)
    local
      Integer i;
      DAE.Dimension d;
      DAE.Dimensions dims;
      DAE.Exp e;
      list<DAE.Exp> eLst;
      DAE.Type ty;
      Boolean scalar;

    case {} then (DAE.RCONST(0.0), DAE.T_REAL_DEFAULT);

    case d::dims
      equation
        i = dimensionSize(d);
        (e, ty) = makeZeroExpression(dims);
        eLst = List.fill(e,i);
        scalar = listEmpty(dims);
      then
        (DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,d::dims),scalar,eLst),
         DAE.T_ARRAY(ty,{d}));
  end match;
end makeZeroExpression;

public function makeOneExpression
" creates a Real or array<Real> one expression with given dimensions, also returns its type"
  input DAE.Dimensions inDims;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := match(inDims)
    local
      Integer i;
      DAE.Dimension d;
      DAE.Dimensions dims;
      DAE.Exp e;
      list<DAE.Exp> eLst;
      DAE.Type ty;
      Boolean scalar;

    case {} then (DAE.RCONST(1.0), DAE.T_REAL_DEFAULT);

    case d::dims
      equation
        i = dimensionSize(d);
        (e, ty) = makeOneExpression(dims);
        eLst = List.fill(e,i);
        scalar = listEmpty(dims);
      then
        (DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,d::dims),scalar,eLst),
         DAE.T_ARRAY(ty,{d}));
  end match;
end makeOneExpression;

public function listToArray
" @mahge:
  creates an array from a list of expressions and
  dimensions. e.g.
   listToArray({1,2,3,4,5,6}, {3,2}) -> {{1,2}, {3,4}, {5,6}}
"
  input list<DAE.Exp> inList;
  input DAE.Dimensions dims;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(inList, dims)
    local
      DAE.Type ty;
      DAE.Exp exp;

    case(_, {})
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Expression.listToArray called with empty dimension list."});
      then fail();

    case({}, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Expression.listToArray called with empty list."});
      then fail();

    // Here we assume that all the elements of the list
    // have the same type.
    case(exp::_, _)
      equation
        ty = typeof(exp);
        oExp = listToArray2(inList,dims,ty);
      then
        oExp;
  end matchcontinue;

end listToArray;


protected function listToArray2
  input list<DAE.Exp> inList;
  input DAE.Dimensions iDims;
  input DAE.Type inType;
  output DAE.Exp oExp;
algorithm
  () := match(inList, iDims, inType)
  local
    Integer i;
    DAE.Dimension d;
    list<DAE.Exp> explst;
    DAE.Dimensions dims;
    Boolean is_scalar;
    DAE.Type ty;

  case(_, {d}, _)
    algorithm
      is_scalar := not Types.isArray(inType);
      if dimensionKnown(d) then
        i := dimensionSize(d);
        if i <> listLength(inList) then
          Error.addMessage(Error.INTERNAL_ERROR, {"Expression.listToArray2: Number of elements in the list does not match the dimension size."});
          fail();
        else
          ty := liftArrayR(inType, DAE.DIM_INTEGER(listLength(inList)));
          oExp := DAE.ARRAY(ty, is_scalar, inList);
        end if;
      // We do not know the dimension size but we have only one dimension.
      // WE just create a one dimensional array and hope for the best. This is needed for
      // codegen when we have to expand an array crefexp to an array expression. Sometimes
      // we get an unevaluated dimension for a model variable all the way down in codegen :(
      else
        ty := liftArrayR(inType, d);
        oExp := DAE.ARRAY(ty, is_scalar, inList);
      end if;
    then ();

  case(_, _ :: _ , _)
    algorithm
      (d, dims) := List.splitLast(iDims);
      explst := listToArray3(inList,d);
      ty := liftArrayR(inType, DAE.DIM_INTEGER(listLength(explst)));
      oExp := listToArray2(explst,dims,ty);
    then
      ();

  end match;
end listToArray2;


protected function listToArray3
  input list<DAE.Exp> inList;
  input DAE.Dimension iDim;
  output list<DAE.Exp> oExps;
algorithm
  oExps := match(inList, iDim)
  local
    Integer i;
    DAE.Dimension d;
    list<DAE.Exp> explst, restexps, restarr;
    DAE.Exp arrexp;

    case({}, _) then {};

    case(_, d)
      equation
        i = dimensionSize(d);
        if (i > listLength(inList)) then
          Error.addMessage(Error.INTERNAL_ERROR, {"Expression.listToArray3: Not enough elements left in list to fit dimension."});
          fail();
        else
          (explst, restexps) = List.split(inList,i);
          arrexp = makeArrayFromList(explst);
          restarr = listToArray3(restexps,d);
        end if;
      then
        arrexp::restarr;

  end match;
end listToArray3;


public function arrayFill
  input DAE.Dimensions dims;
  input DAE.Exp inExp;
  output DAE.Exp oExp;
algorithm
  oExp := match(dims,inExp)

    case({},_) then inExp;

    else
      equation
        oExp = arrayFill2(dims,inExp);
      then
        oExp;

  end match;
end arrayFill;

protected function arrayFill2
  input DAE.Dimensions iDims;
  input DAE.Exp inExp;
  output DAE.Exp oExp;
algorithm
  oExp := match(iDims,inExp)
    local
      Integer i;
      DAE.Dimension d;
      Type ty;
      list<DAE.Exp> expl;
      DAE.Exp arrexp;
      DAE.Dimensions dims;

    case({d},_)
      equation
        ty = typeof(inExp);
        i = dimensionSize(d);
        expl = List.fill(inExp, i);
      then
        DAE.ARRAY(DAE.T_ARRAY(ty,{DAE.DIM_INTEGER(i)}),true,expl);

    case(d::dims,_)
      equation
        arrexp = arrayFill2({d},inExp);
        arrexp = arrayFill2(dims,arrexp);
      then
        arrexp;

  end match;
end arrayFill2;

public function makeIndexSubscript
"Creates a Subscript INDEX from an Expression."
  input DAE.Exp exp;
  output DAE.Subscript subscript;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  subscript := DAE.INDEX(exp);
end makeIndexSubscript;

public function makeVar "Creates a Var given a name and Type"
  input String name;
  input DAE.Type tp;
  output DAE.Var v;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  v := DAE.TYPES_VAR(name, DAE.dummyAttrVar, tp, DAE.UNBOUND(), false, NONE());
end makeVar;

public function dimensionsMult
  "Multiplies two dimensions."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output DAE.Dimension res;
algorithm
  res := intDimension(dimensionSize(dim1) * dimensionSize(dim2));
end dimensionsMult;

public function dimensionsAdd
  "Adds two dimensions."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output DAE.Dimension res;
algorithm
  try
    res := intDimension(dimensionSize(dim1) + dimensionSize(dim2));
  else
    res := DAE.DIM_UNKNOWN();
  end try;
end dimensionsAdd;

public function concatArrayType
  "Concatenates two array types, so that the resulting type is correct."
  input DAE.Type arrayType1;
  input DAE.Type arrayType2;
  output DAE.Type concatType;
algorithm
  concatType := match(arrayType1, arrayType2)
    local
      DAE.Type et;
      DAE.Dimension dim1, dim2;
      DAE.Dimensions dims1, dims2;

    case (DAE.T_ARRAY(ty = et, dims = dim1 :: dims1), DAE.T_ARRAY(dims = dim2 :: _))
      equation
        dim1 = dimensionsAdd(dim1, dim2);
      then
        DAE.T_ARRAY(et, dim1 :: dims1);
  end match;
end concatArrayType;

public function replaceExpTpl
  "Help function to e.g. detectImplicitDiscreteAlgsStatemensFor"
  input DAE.Exp inExp;
  input tuple<DAE.Exp, DAE.Exp> tpl;
  output DAE.Exp outExp;
  output tuple<DAE.Exp, DAE.Exp> outTpl;
algorithm
  (outExp,outTpl) := match(inExp,tpl)
    local
      DAE.Exp e, e1, s, t;

    case (e, (s, t))
      equation
      ((e1, _)) = replaceExp(e, s, t);
      then (e1, tpl);

  end match;
end replaceExpTpl;

public function replaceExp
"Helper function to replaceExpList."
  input DAE.Exp inExp;
  input DAE.Exp inSourceExp;
  input DAE.Exp inTargetExp;
  output tuple<DAE.Exp,Integer> out;
protected
  DAE.Exp exp;
  Integer i;
algorithm
  (exp,(_,_,i)) := traverseExpTopDown(inExp,replaceExpWork,(inSourceExp,inTargetExp,0));
  out := (exp,i);
end replaceExp;

protected function replaceExpWork
  input DAE.Exp inExp;
  input tuple<DAE.Exp,DAE.Exp,Integer> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.Exp,DAE.Exp,Integer> otpl;
algorithm
  (outExp,cont,otpl) := match(inExp,inTpl)
    local
      tuple<DAE.Exp,DAE.Exp,Integer> tpl;
      DAE.Exp expr,source,target;
      Integer c;
      DAE.ComponentRef cr;
      DAE.Type ty;
    case (_,(source,target,c))
      guard expEqual(inExp, source)
      then (target,false,(source,target,c+1));

    else (inExp,true,inTpl);
  end match;
end replaceExpWork;

public function expressionCollector
   input DAE.Exp exp;
   input list<DAE.Exp> acc;
   output DAE.Exp outExp;
   output list<DAE.Exp> outExps;
algorithm
  outExp := exp;
  outExps := exp::acc;
end expressionCollector;


public function replaceCrefBottomUp
  input DAE.Exp inExp;
  input DAE.ComponentRef inSourceExp;
  input DAE.Exp inTargetExp;
  output DAE.Exp exp;
algorithm
  (exp,_) := traverseExpBottomUp(inExp,replaceCref,(inSourceExp,inTargetExp));
end replaceCrefBottomUp;

public function replaceCref
"Replace a componentref with a expression"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,DAE.Exp> inTpl;
  output DAE.Exp outExp;
  output tuple<DAE.ComponentRef,DAE.Exp> otpl;
algorithm
  (outExp,otpl) := match (inExp,inTpl)
    local
      DAE.Exp target;
      DAE.ComponentRef cr,cr1;
    case (DAE.CREF(componentRef=cr),(cr1,target))
      guard ComponentReference.crefEqualNoStringCompare(cr, cr1)
      then
        (target,inTpl);
    else (inExp,inTpl);
  end match;
end replaceCref;

public function containsInitialCall "public function containsInitialCall
  author: lochel
  Spec33 p. 90:
  [...] The equations of a when-clause are active during initialization, if
  and only if they are explicitly enabled with the initial() operator; and
  only in one of the two forms when initial() then or when {…,initial(),…}
  then. [...]"
  input DAE.Exp condition;    // expression of a when-clause
  output Boolean res;
algorithm
  res := match(condition)
    local
      list<Exp> array;

    case (DAE.CALL(path = Absyn.IDENT(name = "initial")))
    then true;

    case (DAE.ARRAY(array=array))
    then List.mapBoolOr(array, containsInitialCall);

    else false;
  end match;
end containsInitialCall;

/***************************************************/
/* traverse DAE.Exp */
/***************************************************/

public function traverseExpBottomUp<T>
"Traverses all subexpressions of an expression.
  Takes a function and an extra argument passed through the traversal.
  The function can potentially change the expression. In such cases,
  the changes are made bottom-up, i.e. a subexpression is traversed
  and changed before the complete expression is traversed.

  NOTE: The user-provided function is not allowed to fail! If you want to
  detect a failure, return NONE() in your user-provided datatype."
  input DAE.Exp inExp;
  input FuncExpType inFunc;
  input T inExtArg;
  output DAE.Exp outExp;
  output T outExtArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input T inExtArg;
    output DAE.Exp outExp;
    output T outExtArg;
  end FuncExpType;
algorithm
  (outExp, outExtArg) := match (inExp)
    local
      DAE.Exp e1_1, e, e1, e2_1, e2, e3_1, e3, e4, e4_1;
      T ext_arg;
      Operator op;
      FuncExpType rel;
      list<DAE.Exp> expl_1, expl;
      Absyn.Path fn;
      Boolean scalar;
      Type tp, t;
      Integer i;
      list<list<DAE.Exp>> lstexpl_1, lstexpl;
      Integer dim;
      String str;
      list<DAE.Element> localDecls;
      list<String> fieldNames;
      DAE.CallAttributes attr;
      list<DAE.MatchCase> cases, cases_1;
      DAE.MatchType matchTy;
      Integer index_;
      Option<tuple<DAE.Exp, Integer, Integer>> isExpisASUB;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters, riters_1;
      DAE.ComponentRef cr, cr_1;
      list<list<String>> aliases;
      DAE.ClockKind clk, clk1;
      list<DAE.Type> typeVars;

    case DAE.EMPTY() equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.ICONST() equation
        (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.RCONST() equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.SCONST() equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.BCONST() equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.CLKCONST(clk) equation
      (clk1, ext_arg) = traverseExpClk(clk, inFunc, inExtArg);
      e = if referenceEq(clk1, clk) then inExp else DAE.CLKCONST(clk1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.ENUM_LITERAL() equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.CREF(cr, tp) equation
      (cr_1, ext_arg) = traverseExpCref(cr, inFunc, inExtArg);
      e = if referenceEq(cr, cr_1) then inExp else DAE.CREF(cr_1, tp);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    // unary
    case DAE.UNARY(operator=op, exp=e1) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.UNARY(op, e1_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    // binary
    case DAE.BINARY(exp1=e1, operator=op, exp2=e2) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.BINARY(e1_1, op, e2_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    // logical unary
    case DAE.LUNARY(operator=op, exp=e1) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.LUNARY(op, e1_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    // logical binary
    case DAE.LBINARY(exp1=e1, operator=op, exp2=e2) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.LBINARY(e1_1, op, e2_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    // relation
    case DAE.RELATION(exp1=e1, operator=op, exp2=e2, index=index_, optionExpisASUB=isExpisASUB) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.RELATION(e1_1, op, e2_1, index_, isExpisASUB);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    // if expressions
    case DAE.IFEXP(expCond=e1, expThen=e2, expElse=e3) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      (e3_1, ext_arg) = traverseExpBottomUp(e3, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) and referenceEq(e3, e3_1) then inExp else DAE.IFEXP(e1_1, e2_1, e3_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.CALL(path=fn, expLst=expl, attr=attr) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.CALL(fn, expl_1, attr);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.RECORD(path=fn, exps=expl, comp=fieldNames, ty=tp) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.RECORD(fn, expl_1, fieldNames, tp);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.PARTEVALFUNCTION(fn, expl, tp, t) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.PARTEVALFUNCTION(fn, expl_1, tp, t);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.ARRAY(ty=tp, scalar=scalar, array=expl) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.ARRAY(tp, scalar, expl_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.MATRIX(ty=tp, integer=dim, matrix=lstexpl) equation
      (lstexpl_1, ext_arg) = traverseExpMatrix(lstexpl, inFunc, inExtArg);
      e = if referenceEq(lstexpl, lstexpl_1) then inExp else DAE.MATRIX(tp, dim, lstexpl_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.RANGE(ty=tp, start=e1, step=NONE(), stop=e2) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.RANGE(tp, e1_1, NONE(), e2_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.RANGE(ty=tp, start=e1, step=SOME(e2), stop=e3) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      (e3_1, ext_arg) = traverseExpBottomUp(e3, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) and referenceEq(e3, e3_1) then inExp else DAE.RANGE(tp, e1_1, SOME(e2_1), e3_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.TUPLE(PR=expl) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.TUPLE(expl_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.CAST(ty=tp, exp=e1) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.CAST(tp, e1_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.ASUB(exp=e1, sub=expl) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(expl, expl_1) then inExp else makeASUB(e1_1, expl_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.TSUB(e1, i, tp) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.TSUB(e1_1, i, tp);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case e1 as DAE.RSUB()
      algorithm
        (e1_1, ext_arg) := traverseExpBottomUp(e1.exp, inFunc, inExtArg);
        if not referenceEq(e1.exp, e1_1) then
          e1.exp := e1_1;
        end if;
        (e1, ext_arg) := inFunc(e1, ext_arg);
      then (e1, ext_arg);

    case DAE.SIZE(exp=e1, sz=NONE()) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.SIZE(e1_1, NONE());
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.SIZE(exp=e1, sz=SOME(e2)) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.SIZE(e1_1, SOME(e2_1));
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.REDUCTION(reductionInfo=reductionInfo, expr=e1, iterators=riters) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (riters_1, ext_arg) = traverseReductionIterators(riters, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(riters, riters_1) then inExp else DAE.REDUCTION(reductionInfo, e1_1, riters_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    // MetaModelica list
    case DAE.CONS(e1, e2) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      (e2_1, ext_arg) = traverseExpBottomUp(e2, inFunc, ext_arg);
      e = if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.CONS(e1_1, e2_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.LIST(expl) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.LIST(expl_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.META_TUPLE(expl) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.META_TUPLE(expl_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.META_OPTION(NONE()) equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.META_OPTION(SOME(e1)) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.META_OPTION(SOME(e1_1));
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.BOX(e1) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.BOX(e1_1);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.UNBOX(e1, tp) equation
      (e1_1, ext_arg) = traverseExpBottomUp(e1, inFunc, inExtArg);
      e = if referenceEq(e1, e1_1) then inExp else DAE.UNBOX(e1_1, tp);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.METARECORDCALL(fn, expl, fieldNames, i, typeVars) equation
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      e = if referenceEq(expl, expl_1) then inExp else DAE.METARECORDCALL(fn, expl_1, fieldNames, i, typeVars);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);
    // ---------------------

    case DAE.MATCHEXPRESSION(matchTy, expl, aliases, localDecls, cases, tp) equation
      // Don't traverse the local declarations; we don't store bindings there (yet)
      (expl_1, ext_arg) = traverseExpList(expl, inFunc, inExtArg);
      (cases_1, ext_arg) = Patternm.traverseCases(cases, inFunc, ext_arg);
      e = if referenceEq(expl, expl_1) and referenceEq(cases, cases_1) then inExp else DAE.MATCHEXPRESSION(matchTy, expl_1, aliases, localDecls, cases_1, tp);
      (e, ext_arg) = inFunc(e, ext_arg);
    then (e, ext_arg);

    case DAE.SHARED_LITERAL() equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    case DAE.PATTERN() equation
      (e, ext_arg) = inFunc(inExp, inExtArg);
    then (e, ext_arg);

    // Why don't we call inFunc() for these expressions?
    case DAE.CODE() then (inExp, inExtArg);

    else equation
      str = ExpressionDump.printExpStr(inExp);
      str = "Expression.traverseExpBottomUp or one of the user-defined functions using it is not implemented correctly: " + str;
      Error.addInternalError(str, sourceInfo());
    then fail();
  end match;
end traverseExpBottomUp;

public function traverseExpDummy "Like traverseExpBottomUp but passes a default 0 argument"
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType func;
  output DAE.Exp outExp;
  partial function FuncExpType
    input DAE.Exp inExp;
    output DAE.Exp outExp;
  end FuncExpType;
algorithm
  (outExp,_) := traverseExpBottomUp(inExp,traverseExpDummyHelper,func);
end traverseExpDummy;

public function traverseExpDummyHelper "Like traverseExpBottomUp but does not use an extra argument"
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType func;
  output DAE.Exp outExp;
  output FuncExpType outFunc;
  partial function FuncExpType
    input DAE.Exp inExp;
    output DAE.Exp outExp;
  end FuncExpType;
algorithm
  outExp := func(inExp);
  outFunc := func;
end traverseExpDummyHelper;

public function traverseSubexpressionsHelper
"This function is used as input to a traverse function that does not traverse all subexpressions.
The extra argument is a tuple of the actul function to call on each subexpression and the extra argument."
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input tuple<FuncExpType,Type_a> itpl;
  output DAE.Exp outExp;
  output tuple<FuncExpType,Type_a> otpl;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
protected
  FuncExpType rel;
  Type_a ext_arg, ext_arg2;
algorithm
  (rel,ext_arg) := itpl;
  (outExp,ext_arg2) := traverseExpBottomUp(inExp,rel,ext_arg);
  otpl := if referenceEq(ext_arg, ext_arg2) then itpl else (rel,ext_arg2);
end traverseSubexpressionsHelper;

public function traverseSubexpressions
"This function is used as input to a traverse function that does not traverse all subexpressions.
The extra argument is a tuple of the actul function to call on each subexpression and the extra argument."
  replaceable type Type_a subtypeof Any;
  input output DAE.Exp e;
  input output Type_a arg;
  input FuncExpType func;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (e, arg) := traverseExpBottomUp(e, func, arg);
end traverseSubexpressions;

public function traverseSubexpressionsDummyHelper
"This function is used as input to a traverse function that does not traverse all subexpressions.
The extra argument is a tuple of the actul function to call on each subexpression and the extra argument.
"
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType inFunc;
  output DAE.Exp outExp;
  output FuncExpType outFunc;
  partial function FuncExpType
    input DAE.Exp inExp;
    output DAE.Exp outExp;
  end FuncExpType;
algorithm
  (outExp,outFunc) := traverseExpBottomUp(inExp,traverseExpDummyHelper,inFunc);
end traverseSubexpressionsDummyHelper;

public function traverseSubexpressionsTopDownHelper
"This function is used as input to a traverse function that does not traverse all subexpressions.
The extra argument is a tuple of the actual function to call on each subexpression and the extra argument."
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input tuple<FuncExpType2,Type_a> itpl;
  output DAE.Exp outExp;
  output tuple<FuncExpType2,Type_a> otpl;
  partial function FuncExpType2
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outA;
  end FuncExpType2;
protected
  FuncExpType2 rel;
  Type_a ext_arg, ext_arg2;
algorithm
  (rel,ext_arg) := itpl;
  (outExp,ext_arg2) := traverseExpTopDown(inExp,rel,ext_arg);
  otpl := if referenceEq(ext_arg, ext_arg2) then itpl else (rel,ext_arg2);
end traverseSubexpressionsTopDownHelper;

protected function traverseExpMatrix
"author: PA
   Helper function to traverseExpBottomUp, traverses matrix expressions."
  replaceable type Type_a subtypeof Any;
  input list<list<DAE.Exp>> inMatrix;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<list<DAE.Exp>> outMatrix = {};
  output Type_a outTypeA = inTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
protected
  list<DAE.Exp> row_1;
  Boolean same = true;
algorithm
  for row in inMatrix loop
    (row_1,outTypeA) := traverseExpList(row, func, outTypeA);
    same := if referenceEq(row,row_1) then same else false;
    outMatrix := row_1::outMatrix;
  end for;
  if same then
    outMatrix := inMatrix;
  else
    outMatrix := MetaModelica.Dangerous.listReverseInPlace(outMatrix);
  end if;
end traverseExpMatrix;

public function traverseExpList<ArgT> "Calls traverseExpBottomUp for each element of list."
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input ArgT iext_arg;
  output list<DAE.Exp> expl;
  output ArgT ext_arg = iext_arg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input ArgT inTypeA;
    output DAE.Exp outExp;
    output ArgT outA;
  end FuncExpType;
protected
  DAE.Exp e1;
  Boolean allEq=true;
  DoubleEnded.MutableList<DAE.Exp> delst;
  Integer nEq=0;
algorithm
  for e in inExpl loop
    (e1, ext_arg) := traverseExpBottomUp(e, rel, ext_arg);
    // Preserve reference equality without any allocation if nothing changed
    if (if allEq then not referenceEq(e, e1) else false) then
      allEq:=false;
      delst := DoubleEnded.empty(e1);
      for elt in inExpl loop
        if nEq < 1 then
          break;
        end if;
        DoubleEnded.push_back(delst, elt);
        nEq := nEq-1;
      end for;
    end if;
    if allEq then
      nEq := nEq + 1;
    else
      DoubleEnded.push_back(delst, e1);
    end if;
  end for;
  expl := if allEq then inExpl else DoubleEnded.toListAndClear(delst);
end traverseExpList;

public function traverseExpTopDown
"Traverses all subexpressions of an expression.
  Takes a function and an extra argument passed through the traversal.
  The function can potentially change the expression. In such cases,
  the changes are made top-down, i.e. a subexpression is traversed
  and changed after the complete expression is traversed."
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType func;
  input Type_a ext_arg;
  output DAE.Exp outExp;
  output Type_a outArg;
  partial function FuncExpType
    input DAE.Exp exp;
    input Type_a arg;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outArg;
  end FuncExpType;
protected
  Boolean cont;
algorithm
  (outExp,cont,outArg) := func(inExp,ext_arg);
  (outExp,outArg) := traverseExpTopDown1(cont,outExp,func,outArg);
end traverseExpTopDown;

protected function traverseExpClk
  replaceable type Type_a subtypeof Any;
  input DAE.ClockKind inClk;
  input FuncExpType func;
  input Type_a inArg;
  output DAE.ClockKind outClk;
  output Type_a outArg;
  partial function FuncExpType
    input DAE.Exp exp;
    input Type_a arg;
    output DAE.Exp outExp;
    output Type_a outArg;
  end FuncExpType;
algorithm
  (outClk, outArg) := match inClk
    local
      DAE.Exp e, e1, e2, ea, eb;
      Real intvl;
      Integer i1, i2;
      Type_a arg;
      String str;
      DAE.ClockKind clk;
    case DAE.INTEGER_CLOCK(e1, e2)
      equation
        (ea, arg) = traverseExpBottomUp(e1, func, inArg);
        (eb, arg) = traverseExpBottomUp(e2, func, inArg);
        clk = if referenceEq(ea, e1) and referenceEq(eb, e2)
              then inClk else DAE.INTEGER_CLOCK(ea, eb);
      then (clk, arg);
    case DAE.REAL_CLOCK(e)
      equation
        (e1, arg) = traverseExpBottomUp(e, func, inArg);
        clk = if referenceEq(e1, e) then inClk else DAE.REAL_CLOCK(e1);
      then (clk, arg);
    case DAE.BOOLEAN_CLOCK(e1, e2)
      equation
        (ea, arg) = traverseExpBottomUp(e1, func, inArg);
        (eb, arg) = traverseExpBottomUp(e2, func, inArg);
        clk = if referenceEq(ea, e1) and referenceEq(eb, e2)
              then inClk else DAE.BOOLEAN_CLOCK(ea, eb);
      then (clk, arg);
    case DAE.SOLVER_CLOCK(e1, e2)
      equation
        (ea, arg) = traverseExpBottomUp(e1, func, inArg);
        (eb, arg) = traverseExpBottomUp(e2, func, inArg);
        clk = if referenceEq(ea, e1) and referenceEq(eb, e2)
              then inClk else DAE.SOLVER_CLOCK(ea, eb);
      then (clk, arg);
    else (inClk, inArg);
  end match;
end traverseExpClk;

protected function traverseExpTopDownClockHelper
  replaceable type Type_a subtypeof Any;
  input DAE.ClockKind inClk;
  input FuncExpType func;
  input Type_a inArg;
  output DAE.ClockKind outClk;
  output Type_a outArg;
  partial function FuncExpType
    input DAE.Exp exp;
    input Type_a arg;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outArg;
  end FuncExpType;
algorithm
  (outClk, outArg) := match inClk
    local
      DAE.Exp e, e1, e2, ea, eb;
      Real intvl;
      Integer i1, i2;
      Type_a arg;
      String str;
      DAE.ClockKind clk;

    case DAE.INTEGER_CLOCK(e1, e2)
      equation
        (ea, arg) = traverseExpTopDown(e1, func, inArg);
        (eb, arg) = traverseExpTopDown(e2, func, inArg);
        clk = if referenceEq(ea, e1) and referenceEq(eb, e2)
              then inClk else DAE.INTEGER_CLOCK(ea, eb);
      then (clk, arg);
    case DAE.REAL_CLOCK(e)
      equation
        (e1, arg) = traverseExpTopDown(e, func, inArg);
        clk = if referenceEq(e1, e) then inClk else DAE.REAL_CLOCK(e1);
      then (clk, arg);
    case DAE.BOOLEAN_CLOCK(e1, e2)
      equation
        (ea, arg) = traverseExpTopDown(e1, func, inArg);
        (eb, arg) = traverseExpTopDown(e2, func, inArg);
        clk = if referenceEq(ea, e1) and referenceEq(eb, e2)
              then inClk else DAE.BOOLEAN_CLOCK(ea, eb);
      then (clk, arg);
    case DAE.SOLVER_CLOCK(e1, e2)
      equation
        (ea, arg) = traverseExpTopDown(e1, func, inArg);
        (eb, arg) = traverseExpTopDown(e2, func, inArg);
        clk = if referenceEq(ea, e1) and referenceEq(eb, e2)
              then inClk else DAE.SOLVER_CLOCK(ea, eb);
      then (clk, arg);
    else (inClk, inArg);
  end match;
end traverseExpTopDownClockHelper;

protected function traverseExpTopDown1
"Helper for traverseExpTopDown."
  replaceable type Type_a subtypeof Any;
  input Boolean cont;
  input DAE.Exp inExp;
  input FuncExpType func;
  input Type_a inArg;
  output DAE.Exp outExp;
  output Type_a outArg;
  partial function FuncExpType
    input DAE.Exp exp;
    input Type_a arg;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outArg;
  end FuncExpType;
algorithm
  (outExp,outArg) := match (cont,inExp,func,inArg)
    local
      DAE.Exp e1_1,e,e1,e2_1,e2,e3_1,e3,e4,e4_1;
      Type_a ext_arg_1,ext_arg_2,ext_arg,ext_arg_3,ext_arg_4;
      Operator op;
      FuncExpType rel;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path fn;
      Boolean scalar;
      Type tp,et,t;
      Integer i;
      String str;
      list<String> fieldNames;
      list<list<DAE.Exp>> lstexpl_1,lstexpl;
      Integer dim;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      Option<DAE.Exp> oe1;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters;
      DAE.CallAttributes attr;
      list<DAE.Element> localDecls;
      DAE.MatchType matchType;
      list<DAE.MatchCase> cases;
      ComponentRef cr,cr_1;
      list<list<String>> aliases;
      DAE.ClockKind clk, clk1;
      list<DAE.Type> typeVars;

    case (false,_,_,_) then (inExp,inArg);
    case (_,DAE.ICONST(_),_,ext_arg) then (inExp,ext_arg);
    case (_,DAE.RCONST(_),_,ext_arg) then (inExp,ext_arg);
    case (_,DAE.SCONST(_),_,ext_arg) then (inExp,ext_arg);
    case (_,DAE.BCONST(_),_,ext_arg) then (inExp,ext_arg);
    case (_,DAE.CLKCONST(clk),_,ext_arg)
      equation
        (clk1, ext_arg) = traverseExpTopDownClockHelper(clk,func,ext_arg);
        e = if referenceEq(clk1,clk) then inExp else DAE.CLKCONST(clk1);
      then (e, ext_arg);
    case (_,DAE.ENUM_LITERAL(),_,ext_arg) then (inExp,ext_arg);
    case (_,DAE.CREF(cr,tp),rel,ext_arg)
      equation
        (cr_1,ext_arg_1) = traverseExpTopDownCrefHelper(cr,rel,ext_arg);
      then (if referenceEq(cr,cr_1) then inExp else DAE.CREF(cr_1,tp),ext_arg_1);
    // unary
    case (_,DAE.UNARY(operator = op,exp = e1),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
      then
        (if referenceEq(e1, e1_1) then inExp else DAE.UNARY(op,e1_1),ext_arg_1);

    // binary
    case (_,DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.BINARY(e1_1,op,e2_1),ext_arg_2);

    // logical unary
    case (_,DAE.LUNARY(operator = op,exp = e1),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
      then (if referenceEq(e1, e1_1) then inExp else DAE.LUNARY(op,e1_1),ext_arg_1);

    // logical binary
    case (_,DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.LBINARY(e1_1,op,e2_1),ext_arg_2);

    // relation
    case (_,DAE.RELATION(exp1 = e1,operator = op,exp2 = e2, index=index_, optionExpisASUB= isExpisASUB),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.RELATION(e1_1,op,e2_1,index_,isExpisASUB),ext_arg_2);

    // if expressions
    case (_,(DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
        (e3_1,ext_arg_3) = traverseExpTopDown(e3, rel, ext_arg_2);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) and referenceEq(e3, e3_1) then inExp else DAE.IFEXP(e1_1,e2_1,e3_1),ext_arg_3);

    // call
    case (_,(DAE.CALL(path = fn,expLst = expl,attr = attr)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.CALL(fn,expl_1,attr),ext_arg_1);

    case (_,(DAE.RECORD(path = fn,exps = expl,comp = fieldNames,ty = tp)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.RECORD(fn,expl_1,fieldNames,tp),ext_arg_1);

    case (_,(DAE.PARTEVALFUNCTION(fn, expl, tp, t)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.PARTEVALFUNCTION(fn,expl_1,tp,t),ext_arg_1);

    case (_,(DAE.ARRAY(ty = tp,scalar = scalar,array = expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.ARRAY(tp,scalar,expl_1),ext_arg_1);

    case (_,(DAE.MATRIX(ty = tp,integer = dim,matrix = lstexpl)),rel,ext_arg)
      equation
        (lstexpl_1,ext_arg_1) = traverseExpMatrixTopDown(lstexpl, rel, ext_arg);
      then (DAE.MATRIX(tp,dim,lstexpl_1),ext_arg_1);

    case (_,(DAE.RANGE(ty = tp,start = e1,step = NONE(),stop = e2)),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.RANGE(tp,e1_1,NONE(),e2_1),ext_arg_2);

    case (_,(DAE.RANGE(ty = tp,start = e1,step = SOME(e2),stop = e3)),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
        (e3_1,ext_arg_3) = traverseExpTopDown(e3, rel, ext_arg_2);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) and referenceEq(e3, e3_1) then inExp else DAE.RANGE(tp,e1_1,SOME(e2_1),e3_1),ext_arg_3);

    case (_,(DAE.TUPLE(PR = expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.TUPLE(expl_1),ext_arg_1);

    case (_,(DAE.CAST(ty = tp,exp = e1)),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
      then (DAE.CAST(tp,e1_1),ext_arg_1);

    case (_,(DAE.ASUB(exp = e1,sub = expl_1)),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (expl_1,ext_arg_2) = traverseExpListTopDown(expl_1, rel, ext_arg_1);
      then (makeASUB(e1_1,expl_1),ext_arg_2);

    case (_,(DAE.TSUB(e1,i,tp)),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
      then (DAE.TSUB(e1_1,i,tp),ext_arg_1);

    case (_,e1 as DAE.RSUB(),rel,ext_arg)
      algorithm
        (e1_1,ext_arg_1) := traverseExpTopDown(e1.exp, rel, ext_arg);
        if not referenceEq(e1.exp, e1_1) then
          e1.exp := e1_1;
        end if;
      then (e1,ext_arg_1);

    case (_,(DAE.SIZE(exp = e1,sz = NONE())),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
      then (DAE.SIZE(e1_1,NONE()),ext_arg_1);

    case (_,(DAE.SIZE(exp = e1,sz = SOME(e2))),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.SIZE(e1_1,SOME(e2_1)),ext_arg_2);

    case (_,DAE.CODE(),_,ext_arg) then (inExp,ext_arg);

    case (_,DAE.REDUCTION(reductionInfo = reductionInfo, expr = e1, iterators = riters),rel,ext_arg)
      equation
        (e1,ext_arg) = traverseExpTopDown(e1, rel, ext_arg);
        (riters,ext_arg) = traverseReductionIteratorsTopDown(riters, rel, ext_arg);
      then (DAE.REDUCTION(reductionInfo,e1,riters),ext_arg);

    case (_, DAE.EMPTY(), _, _)
      then (inExp, inArg);

    // MetaModelica list
    case (_,DAE.CONS(e1,e2),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
        (e2_1,ext_arg_2) = traverseExpTopDown(e2, rel, ext_arg_1);
      then (if referenceEq(e1, e1_1) and referenceEq(e2, e2_1) then inExp else DAE.CONS(e1_1,e2_1),ext_arg_2);

    case (_,DAE.LIST(expl),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.LIST(expl_1),ext_arg_1);

    case (_,DAE.META_TUPLE(expl),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.META_TUPLE(expl_1),ext_arg_1);

    case (_,DAE.META_OPTION(oe1),rel,ext_arg)
      equation
        (oe1,ext_arg) = traverseExpOptTopDown(oe1, rel, ext_arg);
      then (DAE.META_OPTION(oe1),ext_arg);

    case (_,DAE.MATCHEXPRESSION(matchType,expl,aliases,localDecls,cases,et),rel,ext_arg)
      equation
        (expl,ext_arg) = traverseExpListTopDown(expl,rel,ext_arg);
        (cases, ext_arg) = Patternm.traverseCasesTopDown(cases, rel, ext_arg);
      then (DAE.MATCHEXPRESSION(matchType,expl,aliases,localDecls,cases,et),ext_arg);

    case (_,DAE.METARECORDCALL(fn,expl,fieldNames,i,typeVars),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = traverseExpListTopDown(expl, rel, ext_arg);
      then (DAE.METARECORDCALL(fn,expl_1,fieldNames,i,typeVars),ext_arg_1);

    case (_,DAE.UNBOX(e1,tp),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
      then (DAE.UNBOX(e1_1,tp),ext_arg_1);

    case (_,DAE.BOX(e1),rel,ext_arg)
      equation
        (e1_1,ext_arg_1) = traverseExpTopDown(e1, rel, ext_arg);
      then (DAE.BOX(e1_1),ext_arg_1);

    case (_,DAE.PATTERN(),_,ext_arg)
      then (inExp,ext_arg);

    case (_,DAE.SHARED_LITERAL(),_,ext_arg)
      then (inExp,ext_arg);

    else
      equation
        str = ExpressionDump.printExpStr(inExp);
        str = getInstanceName() + " or " + System.dladdr(func) + "not implemented correctly: " + str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end traverseExpTopDown1;

protected function traverseExpMatrixTopDown
"author: PA
   Helper function to traverseExpTopDown, traverses matrix expressions."
  replaceable type Type_a subtypeof Any;
  input list<list<DAE.Exp>> inMatrix;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<list<DAE.Exp>> outMatrix = {};
  output Type_a outTypeA = inTypeA;
  partial function FuncExpType
    input DAE.Exp exp;
    input Type_a arg;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outArg;
  end FuncExpType;
protected
  list<DAE.Exp> row_1;
  Boolean same = true;
algorithm
  for row in inMatrix loop
    (row_1,outTypeA) := traverseExpListTopDown(row, func, outTypeA);
    same := if referenceEq(row,row_1) then same else false;
    outMatrix := row_1::outMatrix;
  end for;
  if same then
    outMatrix := inMatrix;
  else
    outMatrix := MetaModelica.Dangerous.listReverseInPlace(outMatrix);
  end if;
end traverseExpMatrixTopDown;

public function traverseExpListTopDown
" author PA:
 Calls traverseExpListTopDown for each element of list."
  replaceable type Type_a subtypeof Any;
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input Type_a inExt_arg;
  output list<DAE.Exp> outExpl = {};
  output Type_a outA = inExt_arg;
  partial function FuncExpType
    input DAE.Exp exp;
    input Type_a arg;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outArg;
  end FuncExpType;
protected
  DAE.Exp e_1;
  Boolean same = true;
algorithm
  for e in inExpl loop
    (e_1,outA) := traverseExpTopDown(e, rel, outA);
    same := if referenceEq(e,e_1) then same else false;
    outExpl := e_1::outExpl;
  end for;
  if same then
    outExpl := inExpl;
  else
    outExpl := MetaModelica.Dangerous.listReverseInPlace(outExpl);
  end if;
end traverseExpListTopDown;

public function traverseExpOpt "Calls traverseExpBottomUp for SOME(exp) and does nothing for NONE"
  input Option<DAE.Exp> inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output Option<DAE.Exp> outExp;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outTypeA) := match (inExp,func,inTypeA)
    local
      DAE.Exp e,e1;
      Type_a a;
      Option<DAE.Exp> oe;
    case (NONE(),_,a) then (inExp/*In case external functions create a copy of NONE()*/,a);
    case(oe as SOME(e),_,a) equation
      (e1,a) = traverseExpBottomUp(e,func,a);
      oe = if referenceEq(e,e1) then oe else SOME(e1);
     then (oe,a);
  end match;
end traverseExpOpt;

public function traverseExpOptTopDown "Calls traverseExpTopDown for SOME(exp) and does nothing for NONE"
  input Option<DAE.Exp> inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output Option<DAE.Exp> outExp;
  output Type_a outA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outA) := match (inExp,func,inTypeA)
    local DAE.Exp e,e1; Type_a a;
    case(NONE(),_,a) then (NONE(),a);
    case(SOME(e),_,a)
      equation
        (e1,a) = traverseExpTopDown(e,func,a);
      then (if referenceEq(e,e1) then inExp else SOME(e1),a);
  end match;
end traverseExpOptTopDown;

public function traverseExpCrefDims<ArgT>
  input DAE.ComponentRef inCref;
  input FuncType inFunc;
  input ArgT inArg;
  output DAE.ComponentRef outCref;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outCref, outArg) := match(inCref)
    local
      DAE.Ident id;
      DAE.Type ty, new_ty;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr, new_cr;
      ArgT arg;
      Integer idx;

    case DAE.CREF_QUAL(id, ty, subs, cr)
      equation
        (new_cr, arg) = traverseExpCrefDims(cr, inFunc, inArg);
        (new_ty, arg) = traverseExpTypeDims(ty, inFunc, inArg);
        cr = if referenceEq(new_cr, cr) and referenceEq(new_ty, ty)
          then inCref else DAE.CREF_QUAL(id, new_ty, subs, new_cr);
      then
        (cr, arg);

    case DAE.CREF_IDENT(id, ty, subs)
      equation
        (new_ty, arg) = traverseExpTypeDims(ty, inFunc, inArg);
        cr = if referenceEq(new_ty, ty)
          then inCref else DAE.CREF_IDENT(id, new_ty, subs);
      then
        (cr, arg);

    case DAE.CREF_ITER(id, idx, ty, subs)
      equation
        (new_ty, arg) = traverseExpTypeDims(ty, inFunc, inArg);
        cr = if referenceEq(new_ty, ty)
          then inCref else DAE.CREF_ITER(id, idx, new_ty, subs);
      then
        (cr, arg);

    else (inCref, inArg);
  end match;
end traverseExpCrefDims;

public function traverseExpTypeDims<ArgT>
  input DAE.Type inType;
  input FuncType inFunc;
  input ArgT inArg;
  output DAE.Type outType;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outType, outArg) := match(inType)
    local
      DAE.Type ty, new_ty;
      list<DAE.Dimension> dims, new_dims;
      ArgT arg;
      Boolean changed;
      ClassInf.State state;
      list<DAE.Var> vars;
      DAE.EqualityConstraint ec;

    case DAE.T_ARRAY(ty, dims)
      equation
        (_, arg, changed) = traverseExpTypeDims2(dims, inFunc, inArg);
        ty = if changed then DAE.T_ARRAY(ty, dims) else inType;
      then
        (ty, arg);

    case DAE.T_SUBTYPE_BASIC(state, vars, ty, ec)
      equation
        (new_ty, arg) = traverseExpTypeDims(ty, inFunc, inArg);
        ty = if referenceEq(new_ty, ty) then inType else DAE.T_SUBTYPE_BASIC(state, vars, ty, ec);
      then
        (ty, arg);

    else (inType, inArg);
  end match;
end traverseExpTypeDims;

protected function traverseExpTypeDims2<ArgT>
  input list<DAE.Dimension> inDims;
  input FuncType inFunc;
  input ArgT inArg;
  output list<DAE.Dimension> outDims = {};
  output ArgT outArg = inArg;
  output Boolean outChanged = false;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
protected
  Boolean changed;
  DAE.Exp exp, new_exp;
algorithm
  for dim in inDims loop
    dim := match(dim)
      case DAE.DIM_EXP(exp)
        equation
          (new_exp, outArg) = inFunc(exp, outArg);
          changed = not referenceEq(new_exp, exp);
          outChanged = outChanged or changed;
        then
          if changed then DAE.DIM_EXP(exp) else dim;

      else dim;
    end match;

    outDims := dim :: outDims;
  end for;

  outDims := if outChanged then listReverse(outDims) else inDims;
end traverseExpTypeDims2;

public function extractUniqueCrefsFromExp
  "Extracts all unique ComponentRef from an Expression."
  input DAE.Exp inExp;
  output list<DAE.ComponentRef> ocrefs;
algorithm
  // ocrefs := List.unique(List.flatten(List.map1(extractCrefsFromExp(inExp), ComponentReference.expandCref, true)));
  ocrefs := List.unique(extractCrefsFromExp(inExp));
end extractUniqueCrefsFromExp;

public function extractCrefsFromExp "
Author: BZ 2008-06, Extracts all ComponentRef from an Expression."
  input DAE.Exp inExp;
  output list<DAE.ComponentRef> ocrefs;
algorithm
  (_,ocrefs) := traverseExpBottomUp(inExp, traversingComponentRefFinder, {});
end extractCrefsFromExp;

public function traversingComponentRefFinder "
Author: BZ 2008-06
Exp traverser that Union the current ComponentRef with list if it is already there.
Returns a list containing, unique, all componentRef in an Expression."
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inCrefs;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> crefs;
algorithm
  (outExp,crefs) := match (inExp,inCrefs)
    local
      ComponentRef cr;
    case (DAE.CREF(componentRef=cr), crefs)
      equation
        crefs = List.unionEltOnTrue(cr,crefs,ComponentReference.crefEqual);
      then (inExp,crefs);
    else (inExp,inCrefs);
  end match;
end traversingComponentRefFinder;

public function extractUniqueCrefsFromExpDerPreStart
  "author mahge: Same as extractUniqueCrefsFromExp except:
  This function will not treat der(), pre() and start() as calls
  but as unique ids. i.e. x is different from der(x) and given der(x) x will not
  be extreacted as a unique id. Instead you get $DER.x. Same oes for pre and start.."
  input DAE.Exp inExp;
  output list<DAE.ComponentRef> ocrefs;
algorithm
  // ocrefs := List.unique(List.flatten(List.map1(extractCrefsFromExp(inExp), ComponentReference.expandCref, true)));
  ocrefs := List.unique(extractCrefsFromExpDerPreStart(inExp));
end extractUniqueCrefsFromExpDerPreStart;

public function extractCrefsFromExpDerPreStart
" author mahge: Same as extractCrefsFromExp except:
  This function will not treat der(), pre() and start() as calls
  but as unique ids. i.e. x is different from der(x) and given der(x) x will not
  be extreacted as a unique id. Instead you get $DER.x. Same oes for pre and start."
  input DAE.Exp inExp;
  output list<DAE.ComponentRef> ocrefs;
algorithm
  (_,ocrefs) := traverseExpTopDown(inExp, traversingComponentRefFinderDerPreStart, {});
end extractCrefsFromExpDerPreStart;

public function traversingComponentRefFinderDerPreStart "
"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inCrefs;
  output DAE.Exp e;
  output Boolean cont;
  output list<DAE.ComponentRef> crefs;
algorithm
  (e,cont,crefs) := match (inExp,inCrefs)
    local
      ComponentRef cr;
    case (DAE.CREF(componentRef=cr), crefs)
      algorithm
        crefs := List.unionEltOnTrue(cr,inCrefs,ComponentReference.crefEqual);
      then (inExp, false, crefs);

    case (DAE.CALL(path = Absyn.IDENT(name="der"), expLst={DAE.CREF(componentRef=cr)}),_) algorithm
      cr := ComponentReference.crefPrefixDer(cr);
      crefs := List.unionEltOnTrue(cr,inCrefs,ComponentReference.crefEqual);
    then (inExp, false, crefs);
      
    case (DAE.CALL(path = Absyn.IDENT(name="pre"), expLst={DAE.CREF(componentRef=cr)}),_) algorithm
      cr := ComponentReference.crefPrefixPre(cr);
      crefs := List.unionEltOnTrue(cr,inCrefs,ComponentReference.crefEqual);
    then (inExp, false, crefs);
      
    case (DAE.CALL(path = Absyn.IDENT(name="previous"), expLst={DAE.CREF(componentRef=cr)}),_) algorithm
      cr := ComponentReference.crefPrefixPrevious(cr);
      crefs := List.unionEltOnTrue(cr,inCrefs,ComponentReference.crefEqual);
    then (inExp, false, crefs);
      
    case (DAE.CALL(path = Absyn.IDENT(name="start"), expLst={DAE.CREF(componentRef=cr)}),_) algorithm
      Error.addInternalError(getInstanceName() + " - Found a start call expression " + ExpressionDump.printExpStr(inExp), sourceInfo());
      cr := ComponentReference.crefPrefixStart(cr);
      crefs := List.unionEltOnTrue(cr,inCrefs,ComponentReference.crefEqual);
    then (inExp, false, crefs);

    else (inExp,true,inCrefs);
  end match;
end traversingComponentRefFinderDerPreStart;

public function extractUniqueCrefsFromStatmentS
  "authot mahge: Extracts all unique ComponentRef from Statments."
  input list<DAE.Statement> inStmts;
  output tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>> ocrefs;
protected
  list<list<DAE.ComponentRef>> lhscreflstlst;
  list<list<DAE.ComponentRef>> rhscreflstlst;
  list<DAE.ComponentRef> orhscrefs;
  list<DAE.ComponentRef> olhscrefs;
algorithm
  (lhscreflstlst,rhscreflstlst) := List.map_2(inStmts,extractCrefsStatment);
  orhscrefs := List.unique(List.flatten(rhscreflstlst));
  olhscrefs := List.unique(List.flatten(lhscreflstlst));
  ocrefs := (olhscrefs,orhscrefs);
end extractUniqueCrefsFromStatmentS;


public function extractCrefsStatment
  "Extracts all ComponentRef from a Statment."
  input DAE.Statement inStmt;
  output list<DAE.ComponentRef> olcrefs;
  output list<DAE.ComponentRef> orcrefs;
algorithm
  (olcrefs,orcrefs) := match(inStmt)
    local
      Exp exp1,exp2;
      list<DAE.Exp> expLst;
      list<DAE.Statement> stmtLst;

    case DAE.STMT_ASSIGN(exp1 = exp1, exp = exp2)
      equation
        olcrefs = extractCrefsFromExpDerPreStart(exp1);
        orcrefs = extractCrefsFromExpDerPreStart(exp2);
      then
        (olcrefs,orcrefs);

    case DAE.STMT_TUPLE_ASSIGN(expExpLst = expLst, exp = exp2)
      equation
        olcrefs = List.flatten(List.map(expLst, extractCrefsFromExpDerPreStart));
        orcrefs = extractCrefsFromExpDerPreStart(exp2);
      then
        (olcrefs,orcrefs);

    case DAE.STMT_ASSIGN_ARR(lhs = exp1, exp = exp2)
      equation
        olcrefs = extractCrefsFromExpDerPreStart(exp1);
        orcrefs = extractCrefsFromExpDerPreStart(exp2);
      then
        (olcrefs,orcrefs);

    case DAE.STMT_IF(statementLst = stmtLst)
      equation
        (olcrefs,orcrefs) = extractUniqueCrefsFromStatmentS(stmtLst);
      then
        (olcrefs,orcrefs);

    case DAE.STMT_FOR(statementLst = stmtLst)
      equation
        (olcrefs,orcrefs) = extractUniqueCrefsFromStatmentS(stmtLst);
      then
        (olcrefs,orcrefs);

    case DAE.STMT_WHILE(statementLst = stmtLst)
      equation
        (olcrefs,orcrefs) = extractUniqueCrefsFromStatmentS(stmtLst);
      then
        (olcrefs,orcrefs);

    case DAE.STMT_WHEN(statementLst = stmtLst)
      equation
        (olcrefs,orcrefs) = extractUniqueCrefsFromStatmentS(stmtLst);
      then
        (olcrefs,orcrefs);

    case DAE.STMT_ASSERT(cond = exp1)
      equation
        orcrefs = extractCrefsFromExpDerPreStart(exp1);
      then
        ({},orcrefs);

    else ({},{});

  end match;
end extractCrefsStatment;

public function getLhsCrefsFromStatements "Extracts all lhs crefs from Statements.
  author: ptaeuber"
  input list<DAE.Statement> inStmts;
  output list<DAE.ComponentRef> lhsCrefs;
protected
  list<list<DAE.ComponentRef>> lhsCrefsLst;
algorithm
  lhsCrefsLst := List.map(inStmts,getLhsCrefsFromStatement);
  lhsCrefs := List.flatten(lhsCrefsLst);
end getLhsCrefsFromStatements;

protected function getLhsCrefsFromStatement "Extracts all lhs crefs from a statement.
  author: ptaeuber"
  input DAE.Statement inStmt;
  output list<DAE.ComponentRef> lhsCrefs;
algorithm
  lhsCrefs := match(inStmt)
    local
      Exp exp1,exp2;
      list<DAE.Exp> expLst;
      list<DAE.Statement> stmtLst;

    case DAE.STMT_ASSIGN(exp1 = exp1)
      equation
        lhsCrefs = extractCrefsFromExpDerPreStart(exp1);
      then lhsCrefs;

    case DAE.STMT_TUPLE_ASSIGN(expExpLst = expLst)
      equation
        lhsCrefs = List.flatten(List.map(expLst, extractCrefsFromExpDerPreStart));
      then lhsCrefs;

    case DAE.STMT_ASSIGN_ARR(lhs = exp1)
      equation
        lhsCrefs = extractCrefsFromExpDerPreStart(exp1);
      then lhsCrefs;

    case DAE.STMT_IF(statementLst = stmtLst)
      equation
        lhsCrefs = getLhsCrefsFromStatements(stmtLst);
      then lhsCrefs;

    case DAE.STMT_FOR(statementLst = stmtLst)
      equation
        lhsCrefs = getLhsCrefsFromStatements(stmtLst);
      then lhsCrefs;

    case DAE.STMT_WHILE(statementLst = stmtLst)
      equation
        lhsCrefs = getLhsCrefsFromStatements(stmtLst);
      then lhsCrefs;

    case DAE.STMT_WHEN(statementLst = stmtLst)
      equation
        lhsCrefs = getLhsCrefsFromStatements(stmtLst);
      then lhsCrefs;

    else {};

  end match;
end getLhsCrefsFromStatement;

public function expHasInitial "
 returns true if the expression contains any initial() call"
  input DAE.Exp exp;
  output Boolean found;
algorithm
  (_,found) := traverseExpTopDown(exp, traversingexpHasInitial, false);
end expHasInitial;

public function traversingexpHasInitial
  input output DAE.Exp exp;
  output Boolean cont;
  input output Boolean found;
algorithm
  if found then
    cont := false;
    return;
  end if;
  (cont,found) := match exp
    case DAE.CALL(path= Absyn.IDENT("initial"))
      then (false,true);
    else (true,found);
  end match;
end traversingexpHasInitial;

public function expHasCrefs "
@author: adrpo 2011-04-29
 returns true if the expression contains crefs"
  input DAE.Exp inExp;
  output Boolean hasCrefs;
algorithm
  hasCrefs := match(inExp)
    local
      Boolean b;

    case _
      equation
        (_,b) = traverseExpTopDown(inExp, traversingComponentRefPresent, false);
      then
        b;
  end match;
end expHasCrefs;

public function traversingComponentRefPresent "Returns a true if the exp is a componentRef"
  input DAE.Exp inExp;
  input Boolean found;
  output DAE.Exp outExp;
  output Boolean cont;
  output Boolean outFound;
algorithm
  (outExp,cont,outFound) := match (inExp,found)
    case (_,true) then (inExp,false,true);
    case (DAE.CREF(), _) then (inExp, false, true);
    else (inExp,true,false);
  end match;
end traversingComponentRefPresent;

public function traversingComponentRefFinderNoPreDer "
Author: BZ 2008-06
Exp traverser that Union the current ComponentRef with list if it is already there.
Returns a list containing, unique, all componentRef in an Expression."
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inCrefs;
  output DAE.Exp e;
  output Boolean cont;
  output list<DAE.ComponentRef> crefs;
algorithm
  (e,cont,crefs) := match (inExp,inCrefs)
    local
      ComponentRef cr;
    case (DAE.CREF(componentRef=cr), crefs)
      equation
        crefs = List.unionEltOnTrue(cr,crefs,ComponentReference.crefEqual);
      then (inExp, false, crefs);
    case (DAE.CALL(path = Absyn.IDENT(name = "der")), _) then (inExp, false, inCrefs);
    case (DAE.CALL(path = Absyn.IDENT(name = "pre")), _) then (inExp, false, inCrefs);
    case (DAE.CALL(path = Absyn.IDENT(name = "previous")), _) then (inExp, false, inCrefs);
    else (inExp,true,inCrefs);
  end match;
end traversingComponentRefFinderNoPreDer;

public function expHasCref "author: Frenkel TUD 2011-04
  returns true if the expression contains the cref"
  input DAE.Exp inExp;
  input DAE.ComponentRef inCr;
  output Boolean hasCref;
algorithm
  (_,(_,hasCref)) := traverseExpTopDown(inExp, traversingexpHasCref, (inCr,false));
end expHasCref;

public function traversingexpHasCref "
@author: Frenkel TUD 2011-04
Returns a true if the exp the componentRef"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.ComponentRef,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue(inExp,inTpl)
    local
      Boolean b;
      ComponentRef cr,cr1;

    case (DAE.CREF(componentRef = cr1), (cr,false))
      equation
        b = ComponentReference.crefEqualNoStringCompare(cr,cr1);
      then
        (inExp,not b,if b then (cr,b) else inTpl);

    case (_,(_,b)) then (inExp,not b,inTpl);

  end matchcontinue;
end traversingexpHasCref;

public function expHasCrefName "Returns a true if the exp contains a cref that starts with the given name"
  input DAE.Exp inExp;
  input String name;
  output Boolean hasCref;
algorithm
  (_,(_,hasCref)) := traverseExpTopDown(inExp, traversingexpHasName, (name,false));
end expHasCrefName;

public function anyExpHasCrefName "Returns a true if any exp contains a cref that starts with the given name"
  input list<DAE.Exp> inExps;
  input String name;
  output Boolean hasCref;
algorithm
  hasCref := List.applyAndFold1(inExps, boolOr, expHasCrefName, name, false);
end anyExpHasCrefName;

public function traversingexpHasName "Returns a true if the exp contains a cref that starts with the given name"
  input DAE.Exp inExp;
  input tuple<String,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<String,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := match (inExp,inTpl)
    local
      Boolean b;
      String name;
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef = cr), (name,false))
      equation
        b = name == ComponentReference.crefFirstIdent(cr);
      then (inExp,not b,if b then (name,b) else inTpl);
    case (_,(_,b)) then (inExp,not b,inTpl);
  end match;
end traversingexpHasName;

public function expHasDerCref "
@author: Frenkel TUD 2012-06
 returns true if the expression contains the cref in function der"
  input DAE.Exp inExp;
  input DAE.ComponentRef inCr;
  output Boolean hasCref;
algorithm
  (_,(_,hasCref)) := traverseExpTopDown(inExp, traversingexpHasDerCref, (inCr,false));
end expHasDerCref;

public function traversingexpHasDerCref "
@author: Frenkel TUD 2012-06
Returns a true if the exp contains the componentRef in der"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.ComponentRef,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue(inExp,inTpl)
    local
      Boolean b;
      ComponentRef cr,cr1;

    case (DAE.CALL(path= Absyn.IDENT("der"),expLst={DAE.CREF(componentRef = cr1)}), (cr,false))
      equation
        b = ComponentReference.crefEqualNoStringCompare(cr,cr1);
      then (inExp,not b,if b then (cr,b) else inTpl);

    case (DAE.CALL(path= Absyn.IDENT("der"),expLst={DAE.CREF(componentRef = cr1)}), (cr,false))
      equation
        b = ComponentReference.crefPrefixOf(cr,cr1);
      then (inExp,not b,if b then (cr,b) else inTpl);

    case (_,(_,b)) then (inExp,not b,inTpl);

  end matchcontinue;
end traversingexpHasDerCref;

public function expHasDer "
 returns true if the expression contains the  function der"
  input DAE.Exp inExp;
  output Boolean hasCref;
algorithm
  (_, hasCref) := traverseExpTopDown(inExp, traversingexpHasDer, false);
end expHasDer;

public function traversingexpHasDer "
Returns a true if the exp contains in der"
  input DAE.Exp inExp;
  input Boolean inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output Boolean outTpl;
algorithm
  (outExp,cont,outTpl) := match(inExp,inTpl)
    local
      Boolean b;
      ComponentRef cr;

    case (DAE.CALL(path= Absyn.IDENT("der")), false)
      then (inExp,false,true);

    //isAlias
    case(DAE.CREF(componentRef = cr), false)
    guard intEq(System.strncmp(ComponentReference.crefFirstIdent(cr),"$DERAlias",9),0)  //BackendDAE.derivativeNamePrefix
     equation
      then (inExp,false,true);

    case (_,b) then (inExp, not b, inTpl);

  end match;
end traversingexpHasDer;

public function expHasPre "
 Returns true if the expression contains the operator pre"
  input DAE.Exp inExp;
  output Boolean hasPre;
algorithm
  (_, hasPre) := traverseExpTopDown(inExp, traversingexpHasPre, false);
end expHasPre;

protected function traversingexpHasPre "
Returns true if the exp is pre(..)"
  input DAE.Exp inExp;
  input Boolean inHasIt;
  output DAE.Exp outExp;
  output Boolean cont;
  output Boolean outHasIt;
algorithm
  (outExp,cont,outHasIt) := match(inExp,inHasIt)
    local
      Boolean b;
      ComponentRef cr;
    case (DAE.CALL(path= Absyn.IDENT("pre")), false)
      then (inExp,false,true);
    case (_,b) then (inExp, not b, inHasIt);
  end match;
end traversingexpHasPre;

public function expHasPrevious "
Returns true if the expression contains the operator previous"
  input DAE.Exp inExp;
  output Boolean hasPre;
algorithm
  (_, hasPre) := traverseExpTopDown(inExp, traversingexpHasPrevious, false);
end expHasPrevious;

protected function traversingexpHasPrevious "
Returns true if the exp is pre(..)"
  input DAE.Exp inExp;
  input Boolean inHasIt;
  output DAE.Exp outExp;
  output Boolean cont;
  output Boolean outHasIt;
algorithm
  (outExp,cont,outHasIt) := match(inExp,inHasIt)
    local
      Boolean b;
      ComponentRef cr;
    case (DAE.CALL(path= Absyn.IDENT("previous")), false)
      then (inExp,false,true);
    case (_,b) then (inExp, not b, inHasIt);
  end match;
end traversingexpHasPrevious;


public function expHasCrefNoPreorDer "
@author: Frenkel TUD 2011-04
 returns true if the expression contains the cref, but not in pre,change,edge"
  input DAE.Exp inExp;
  input DAE.ComponentRef inCr;
  output Boolean hasCref;
algorithm
  (_,(_,hasCref)) := traverseExpTopDown(inExp, traversingexpHasCrefNoPreorDer, (inCr,false));
end expHasCrefNoPreorDer;

public function traversingexpHasCrefNoPreorDer "
@author: Frenkel TUD 2011-04
Returns a true if the exp the componentRef"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.ComponentRef,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := match (inExp,inTpl)
    local
      Boolean b;
      DAE.ComponentRef cr,cr1;

    case (DAE.CALL(path = Absyn.IDENT(name = "pre")), _)
      then (inExp,false,inTpl);

    case (DAE.CALL(path = Absyn.IDENT(name = "previous")), _)
      then (inExp,false,inTpl);

    case (DAE.CREF(componentRef = cr1), (cr,false))
      equation
        b = ComponentReference.crefEqualNoStringCompare(cr,cr1);
      then (inExp,not b,if b then (cr,b) else inTpl);

/* Not reachable...
    case (DAE.CREF(componentRef = cr1), (cr,false))
      equation
        b = ComponentReference.crefPrefixOf(cr1,cr);
      then (inExp,not b,(cr,b));
*/
    case (_,(_,b)) then (inExp,not b,inTpl);

  end match;
end traversingexpHasCrefNoPreorDer;

public function expHasCrefsNoPreOrStart "
 returns true if the expression contains one cref from the list, but not in pre(),change(),edge(),start(), delay()"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inCr;
  output Boolean hasCref = false;
algorithm
  for cr in inCr loop
    (_,(_,hasCref)) := traverseExpTopDown(inExp, traversingexpHasCrefNoPreOrStart, (cr,false));
    if hasCref then
      break;
    end if;
  end for;
end expHasCrefsNoPreOrStart;


public function expHasCrefNoPreOrStart "
 returns true if the expression contains the cref, but not in pre(),change(),edge(),start(), delay()"
  input DAE.Exp inExp;
  input DAE.ComponentRef inCr;
  output Boolean hasCref;
algorithm
  (_,(_,hasCref)) := traverseExpTopDown(inExp, traversingexpHasCrefNoPreOrStart, (inCr,false));
end expHasCrefNoPreOrStart;

protected function traversingexpHasCrefNoPreOrStart "
return true if the exp the componentRef"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.ComponentRef,Boolean> outTpl;

algorithm
  (outExp,cont,outTpl) := match (inExp,inTpl)
    local
      Boolean b;
      DAE.ComponentRef cr,cr1;

    case (DAE.CALL(path = Absyn.IDENT(name = "pre")), _)
      then (inExp,false,inTpl);
    case (DAE.CALL(path = Absyn.IDENT(name = "previous")), _)
      then (inExp,false,inTpl);
    case (DAE.CALL(path = Absyn.IDENT(name = "change")), _)
      then (inExp,false,inTpl);
    case (DAE.CALL(path = Absyn.IDENT(name = "delay")), _)
      then (inExp,false,inTpl);
    case (DAE.CALL(path = Absyn.IDENT(name = "edge")), _)
      then (inExp,false,inTpl);
    case (DAE.CALL(path = Absyn.IDENT(name = "$_round")), _)
      then (inExp,false,inTpl);

    case (DAE.CREF(componentRef = cr1), (cr,false))
      equation
        b = ComponentReference.crefEqualNoStringCompare(cr,cr1);
      then (inExp,not b,if b then (cr,b) else inTpl);

    case (_,(_,b)) then (inExp,not b,inTpl);

  end match;
end traversingexpHasCrefNoPreOrStart;

public function expHasCrefInIf "
Returns a true if the exp contains the componentRef in if,sign,semiLinear"

  input DAE.Exp inExp;
  input DAE.ComponentRef inCr;
  output Boolean hasCref;
algorithm
  (_,(_,hasCref)) := traverseExpTopDown(inExp,expHasCrefInIfWork, (inCr,false));
end expHasCrefInIf;

public function expHasCrefInIfWork "
Returns a true if the exp contains the componentRef in if,sign,semiLinear"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.ComponentRef,Boolean> outTpl;
algorithm
  (outExp,cont,outTpl) := match(inExp,inTpl)
    local
      Boolean b;
      Integer i;
      ComponentRef cr;
      DAE.Exp e1;

    case(DAE.IFEXP(e1,_,_),(cr,false))
    guard(not isFunCall(e1,"noEvent"))
     equation
       b = expHasCref(e1,cr);
     then (e1, true,if b then (cr,b) else inTpl);

    case(DAE.CALL(path = Absyn.IDENT(name = "smooth"),expLst = {DAE.ICONST(i),e1}),(cr,false))
    guard(i>1)
     then (e1,true, (cr, expHasCref(e1,cr)));

    case(DAE.CALL(), (cr,false))
    guard(isEventTriggeringFunctionExp(inExp))
     equation
     b = expHasCref(inExp, cr);
     then(inExp, true,if b then (cr,b) else inTpl);

    case(DAE.CALL(path = Absyn.IDENT(name = "semiLinear"),expLst = {e1,_,_}),(cr,false))
     equation
       b = expHasCref(e1,cr);
     then (e1, true,if b then (cr,b) else inTpl);

    case(DAE.CALL(path = Absyn.IDENT(name = "sign"),expLst = {e1}),(cr,false))
     equation
       b = expHasCref(e1,cr);
     then (e1, not b,if b then (cr,b) else inTpl);

    case (_, (_,true)) then (inExp,false,inTpl);
    else (inExp, true, inTpl);

  end match;
end expHasCrefInIfWork;

public function expHasCrefInSmoothZero
  "author: kabdelhak FHB 2019-09
  Returns true if the expression contains a function call of the form
  smooth(0, cr). Used to determine if an artificial state should
  not be differentiated and reverted to be an algebraic variable
  instead. "
  input DAE.Exp exp;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  (_, (_, b)) := traverseExpBottomUp(exp, expHasCrefInSmoothZeroWork, (cr, false));
end expHasCrefInSmoothZero;

protected function expHasCrefInSmoothZeroWork
  "author: kabdelhak FHB 2019-09
  Work function to detect smooth(0, cr).
  Q: Should it also return true if the smooth call expression
  contains the cref in any way not only for direct identity?"
  input output DAE.Exp exp;
  input output tuple<DAE.ComponentRef, Boolean> tpl;
algorithm
  tpl := match (exp, tpl)
    local
      DAE.ComponentRef cr, sCr;
      Boolean b;
    case (DAE.CALL(path = Absyn.IDENT(name = "smooth"), expLst = {DAE.ICONST(0), DAE.CREF(componentRef = sCr)}), (cr, false))
      algorithm
        b := ComponentReference.crefEqual(sCr, cr);
        //expHasCref(e, cr); use this instead for full check?
      then (cr, b);
    else tpl;
  end match;
end expHasCrefInSmoothZeroWork;

public function traverseCrefsFromExp "
Author: Frenkel TUD 2011-05, traverses all ComponentRef from an Expression."
  input DAE.Exp inExp;
  input FuncCrefTypeA inFunc;
  input Type_a inArg;
  output Type_a outArg;
  partial function FuncCrefTypeA
    input DAE.ComponentRef inCref;
    input Type_a inArg;
    output Type_a outArg;
  end FuncCrefTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outArg := match(inExp,inFunc,inArg)
   local Type_a arg;
    case(_,_,_)
      equation
        (_,(_,arg)) = traverseExpBottomUp(inExp, traversingCrefFinder, (inFunc,inArg));
      then
        arg;
  end match;
end traverseCrefsFromExp;

protected function traversingCrefFinder "
Author: Frenkel TUD 2011-05"
  input DAE.Exp inExp;
  input tuple<FuncCrefTypeA,Type_a> inTpl;
  output DAE.Exp outExp;
  output tuple<FuncCrefTypeA,Type_a> outTpl;
  partial function FuncCrefTypeA
    input DAE.ComponentRef inCref;
    input Type_a inArg;
    output Type_a outArg;
  end FuncCrefTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outTpl) := match (inExp,inTpl)
    local
      Type_a arg,arg1;
      FuncCrefTypeA func;
      ComponentRef cr;

    case (DAE.CREF(cr,_),(func,arg))
      equation
        arg1 = func(cr,arg);
      then (inExp, if referenceEq(arg, arg1) then inTpl else (func,arg1));

    else (inExp,inTpl);

  end match;
end traversingCrefFinder;

public function extractDivExpFromExp "
Author: Frenkel TUD 2010-02, Extracts all Division DAE.Exp from an Expression."
  input DAE.Exp inExp;
  output list<DAE.Exp> outExps;
algorithm
  (_,outExps) := traverseExpBottomUp(inExp, traversingDivExpFinder, {});
end extractDivExpFromExp;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02
Returns a list containing, all division DAE.Exp in an Expression."
  input DAE.Exp e;
  input list<DAE.Exp> exps;
  output DAE.Exp outExp;
  output list<DAE.Exp> acc;
algorithm
  (outExp,acc) := match (e,exps)
  local
      DAE.Exp e2;
    case (DAE.BINARY(operator = DAE.DIV(_),exp2 = e2), _)
      then (e, e2::exps);

    case (DAE.BINARY(operator = DAE.DIV_ARR(_),exp2 = e2), _)
      then (e, e2::exps);

    case (DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR(_),exp2 = e2), _)
      then (e, e2::exps);

    case (DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY(_),exp2 = e2), _)
      then (e, e2::exps);

    else (e,exps);
  end match;
end traversingDivExpFinder;

public function traverseExpListBidir<ArgT>
  "Traverses a list of expressions, calling traverseExpBidir on each
  expression."
  input list<DAE.Exp> inExpl;
  input FuncType inEnterFunc;
  input FuncType inExitFunc;
  input ArgT inArg;
  output list<DAE.Exp> outExpl;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outExpl, outArg) :=
    List.map2Fold(inExpl, traverseExpBidir, inEnterFunc, inExitFunc, inArg);
end traverseExpListBidir;

public function traverseExpBidir<ArgT>
  "This function takes an expression and a tuple with an enter function, an exit
  function, and an extra argument. For each expression it encounters it calls
  the enter function with the expression and the extra argument. It then
  traverses all subexpressions in the expression and calls traverseExpBidir on
  them with the updated argument. Finally it calls the exit function, again with
  the updated argument. This means that this function is bidirectional, and can
  be used to emulate both top-down and bottom-up traversal."
  input DAE.Exp inExp;
  input FuncType inEnterFunc;
  input FuncType inExitFunc;
  input ArgT inArg;
  output DAE.Exp outExp;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outExp, outArg) := inEnterFunc(inExp, inArg);
  (outExp, outArg) := traverseExpBidirSubExps(outExp, inEnterFunc, inExitFunc, outArg);
  (outExp, outArg) := inExitFunc(outExp, outArg);
end traverseExpBidir;

public function traverseExpOptBidir<ArgT>
  "Same as traverseExpBidir, but with an optional expression. Calls
  traverseExpBidir if the option is SOME(), or just returns the input if it's
  NONE()"
  input Option<DAE.Exp> inExp;
  input FuncType inEnterFunc;
  input FuncType inExitFunc;
  input ArgT inArg;
  output Option<DAE.Exp> outExp;
  output ArgT outArg;

  partial function FuncType
    input Exp inExp;
    input ArgT inArg;
    output Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outExp, outArg) := match(inExp)
    local
      DAE.Exp e,e1;
      ArgT arg;

    case SOME(e)
      equation
        (e1, arg) = traverseExpBidir(e, inEnterFunc, inExitFunc, inArg);
      then
        (if referenceEq(e,e1) then inExp else SOME(e1), arg);

    else (inExp, inArg);
  end match;
end traverseExpOptBidir;

protected function traverseExpBidirSubExps<ArgT>
  "Helper function to traverseExpBidir. Traverses the subexpressions of an
  expression and calls traverseExpBidir on them."
  input DAE.Exp inExp;
  input FuncType inEnterFunc;
  input FuncType inExitFunc;
  input ArgT inArg;
  output DAE.Exp outExp;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outExp, outArg) := match(inExp)
    local
      Integer i;
      DAE.Exp e1, e2, e3;
      Option<DAE.Exp> oe1;
      DAE.Operator op;
      ComponentRef cref;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mat_expl;
      String error_msg;
      DAE.MatchType match_ty;
      list<DAE.Element> match_decls;
      list<DAE.MatchCase> match_cases;
      Integer index, dim;
      Option<tuple<DAE.Exp, Integer, Integer>> opt_exp_asub;
      Absyn.Path path;
      Boolean b1;
      Type ty,t;
      list<String> strl;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters;
      DAE.CallAttributes attr;
      list<list<String>> aliases;
      ArgT arg;
      list<DAE.Type> typeVars;

    case DAE.ICONST() then (inExp, inArg);
    case DAE.RCONST() then (inExp, inArg);
    case DAE.SCONST() then (inExp, inArg);
    case DAE.BCONST() then (inExp, inArg);
    case DAE.ENUM_LITERAL() then (inExp, inArg);

    case DAE.CREF(componentRef = cref, ty = ty)
      equation
        (cref, arg) = traverseExpBidirCref(cref, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.CREF(cref, ty), arg);

    case DAE.BINARY(exp1 = e1, operator = op, exp2 = e2)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (e2, arg) = traverseExpBidir(e2, inEnterFunc, inExitFunc, arg);
      then
        (DAE.BINARY(e1, op, e2), arg);

    case DAE.UNARY(operator = op, exp = e1)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.UNARY(op, e1), arg);

    case DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (e2, arg) = traverseExpBidir(e2, inEnterFunc, inExitFunc, arg);
      then
        (DAE.LBINARY(e1, op, e2), arg);

    case DAE.LUNARY(operator = op, exp = e1)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.LUNARY(op, e1), arg);

    case DAE.RELATION(exp1 = e1, operator = op, exp2 = e2, index = index,
         optionExpisASUB = opt_exp_asub)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (e2, arg) = traverseExpBidir(e2, inEnterFunc, inExitFunc, arg);
      then
        (DAE.RELATION(e1, op, e2, index, opt_exp_asub), arg);

    case DAE.IFEXP(expCond = e1, expThen = e2, expElse = e3)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (e2, arg) = traverseExpBidir(e2, inEnterFunc, inExitFunc, arg);
        (e3, arg) = traverseExpBidir(e3, inEnterFunc, inExitFunc, arg);
      then
        (DAE.IFEXP(e1, e2, e3), arg);

    case DAE.CALL(path = path, expLst = expl, attr = attr)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.CALL(path, expl, attr), arg);

    case DAE.RECORD(path = path, exps = expl, comp = strl, ty = ty)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.RECORD(path, expl, strl, ty), arg);

    case DAE.PARTEVALFUNCTION(path, expl, ty, t)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.PARTEVALFUNCTION(path, expl, ty, t), arg);

    case DAE.ARRAY(ty = ty, scalar = b1, array = expl)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.ARRAY(ty, b1, expl), arg);

    case DAE.MATRIX(ty = ty, integer = dim, matrix = mat_expl)
      equation
        (mat_expl, arg) = List.map2Fold(mat_expl, traverseExpListBidir,
          inEnterFunc, inExitFunc, inArg);
      then
        (DAE.MATRIX(ty, dim, mat_expl), arg);

    case DAE.RANGE(ty = ty, start = e1, step = oe1, stop = e2)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (oe1, arg) = traverseExpOptBidir(oe1, inEnterFunc, inExitFunc, arg);
        (e2, arg) = traverseExpBidir(e2, inEnterFunc, inExitFunc, arg);
      then
        (DAE.RANGE(ty, e1, oe1, e2), arg);

    case DAE.TUPLE(PR = expl)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.TUPLE(expl), arg);

    case DAE.CAST(ty = ty, exp = e1)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.CAST(ty, e1), arg);

    case DAE.ASUB(exp = e1, sub = expl)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, arg);
      then
        (DAE.ASUB(e1, expl), arg);

    case e1 as DAE.RSUB()
      equation
        (e2, arg) = traverseExpBidir(e1.exp, inEnterFunc, inExitFunc, inArg);
        e1.exp = e2;
      then
        (e1, arg);

    case DAE.TSUB(e1, i, ty)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.TSUB(e1, i, ty), arg);

    case DAE.SIZE(exp = e1, sz = oe1)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (oe1, arg) = traverseExpOptBidir(oe1, inEnterFunc, inExitFunc, arg);
      then
        (DAE.SIZE(e1, oe1), arg);

    case DAE.CODE()
      then (inExp, inArg);

    case DAE.REDUCTION(reductionInfo = reductionInfo, expr = e1, iterators = riters)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (riters, arg) = List.map2Fold(riters, traverseReductionIteratorBidir,
          inEnterFunc, inExitFunc, arg);
      then
        (DAE.REDUCTION(reductionInfo, e1, riters), arg);

    case DAE.LIST(valList = expl)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.LIST(expl), arg);

    case DAE.CONS(car = e1, cdr = e2)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
        (e2, arg) = traverseExpBidir(e2, inEnterFunc, inExitFunc, arg);
      then
        (DAE.CONS(e1, e2), arg);

    case DAE.META_TUPLE(listExp = expl)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.TUPLE(expl), arg);

    case DAE.META_OPTION(exp = oe1)
      equation
        (oe1, arg) = traverseExpOptBidir(oe1, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.META_OPTION(oe1), arg);

    case DAE.METARECORDCALL(path = path, args = expl, fieldNames = strl, index = index, typeVars = typeVars)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.METARECORDCALL(path, expl, strl, index, typeVars), arg);

    case DAE.MATCHEXPRESSION(matchType = match_ty, inputs = expl, aliases=aliases,
        localDecls = match_decls, cases = match_cases, et = ty)
      equation
        (expl, arg) = traverseExpListBidir(expl, inEnterFunc, inExitFunc, inArg);
        Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {getInstanceName() + " not yet implemented for match expressions. Called using: " + System.dladdr(inEnterFunc) + " " + System.dladdr(inExitFunc)}, sourceInfo());
        //(cases, tup) = List.mapFold(cases, traverseMatchCase, tup);
      then
        (DAE.MATCHEXPRESSION(match_ty, expl, aliases, match_decls, match_cases, ty), arg);

    case DAE.BOX(exp = e1)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.BOX(e1), arg);

    case DAE.UNBOX(exp = e1, ty = ty)
      equation
        (e1, arg) = traverseExpBidir(e1, inEnterFunc, inExitFunc, inArg);
      then
      (DAE.UNBOX(e1, ty), arg);

    case DAE.SHARED_LITERAL() then (inExp, inArg);
    case DAE.PATTERN() then (inExp, inArg);

    else
      equation
        Error.addInternalError(getInstanceName() + " - Unknown expression " + ExpressionDump.printExpStr(inExp) + ". Called using: " + System.dladdr(inEnterFunc) + " " + System.dladdr(inExitFunc), sourceInfo());
      then
        fail();

  end match;
end traverseExpBidirSubExps;

public function traverseExpBidirCref<ArgT>
  "Helper function to traverseExpBidirSubExps. Traverses any expressions in a
  component reference (i.e. in it's subscripts)."
  input DAE.ComponentRef inCref;
  input FuncType inEnterFunc;
  input FuncType inExitFunc;
  input ArgT inArg;
  output DAE.ComponentRef outCref;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outCref, outArg) := match(inCref)
    local
      String name;
      ComponentRef cr;
      Type ty;
      list<DAE.Subscript> subs;
      ArgT arg;

    case DAE.CREF_QUAL(name, ty, subs, cr)
      equation
        (subs, arg) = List.map2Fold(subs, traverseExpBidirSubs, inEnterFunc,
          inExitFunc, inArg);
        (cr, arg) = traverseExpBidirCref(cr, inEnterFunc, inExitFunc, arg);
      then
        (DAE.CREF_QUAL(name, ty, subs, cr), arg);

    case DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs)
      equation
        (subs, arg) = List.map2Fold(subs, traverseExpBidirSubs, inEnterFunc,
          inExitFunc, inArg);
      then
        (DAE.CREF_IDENT(name, ty, subs), arg);

    else (inCref, inArg);
  end match;
end traverseExpBidirCref;

public function traverseExpCref
  "Helper function to traverseExpBottomUp. Traverses any expressions in a
  component reference (i.e. in it's subscripts)."
  input DAE.ComponentRef inCref;
  input FuncType rel;
  input Type_a iarg;
  output DAE.ComponentRef outCref;
  output Type_a outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input Type_a inArg;
    output DAE.Exp outExp;
    output Type_a outArg;
  end FuncType;

  replaceable type Type_a subtypeof Any;
algorithm
  (outCref, outArg) := match(inCref, rel, iarg)
    local
      String name;
      ComponentRef cr,cr_1;
      Type ty;
      list<DAE.Subscript> subs,subs_1;
      Type_a arg;
      Integer ix;
      String instant;

    case (DAE.CREF_QUAL(ident = name, identType = ty, subscriptLst = subs, componentRef = cr), _, arg)
      equation
        (subs_1, arg) = traverseExpSubs(subs, rel, arg);
        (cr_1, arg) = traverseExpCref(cr, rel, arg);
        cr = if referenceEq(cr,cr_1) and referenceEq(subs,subs_1) then inCref else DAE.CREF_QUAL(name, ty, subs_1, cr_1);
      then
        (cr, arg);

    case (DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs), _, arg)
      equation
        (subs_1, arg) = traverseExpSubs(subs, rel, arg);
        cr = if referenceEq(subs,subs_1) then inCref else DAE.CREF_IDENT(name, ty, subs_1);
      then
        (cr, arg);

    case (DAE.CREF_ITER(ident = name, index = ix, identType = ty, subscriptLst = subs), _, arg)
      equation
        (subs_1, arg) = traverseExpSubs(subs, rel, arg);
        cr = if referenceEq(subs,subs_1) then inCref else DAE.CREF_ITER(name, ix, ty, subs_1);
      then
        (cr, arg);

    case (DAE.OPTIMICA_ATTR_INST_CREF(componentRef = cr, instant = instant), _, arg)
      equation
        (cr_1, arg) = traverseExpCref(cr, rel, arg);
        cr = if referenceEq(cr,cr_1) then inCref else DAE.OPTIMICA_ATTR_INST_CREF(cr_1, instant);
      then
        (cr, arg);

    case (DAE.WILD(), _, arg) then (inCref, arg);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Expression.traverseExpCref: Unknown cref"});
      then fail();
  end match;
end traverseExpCref;

protected function traverseExpSubs
  input list<DAE.Subscript> inSubscript;
  input FuncType rel;
  input Type_a iarg;
  output list<DAE.Subscript> outSubscript;
  output Type_a outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input Type_a inArg;
    output DAE.Exp outExp;
    output Type_a outArg;
  end FuncType;

  replaceable type Type_a subtypeof Any;
algorithm
  (outSubscript, outArg) := match(inSubscript, rel, iarg)
    local
      DAE.Exp sub_exp,sub_exp_1;
      list<DAE.Subscript> rest,res;
      Type_a arg;

    case ({}, _, arg) then (inSubscript,arg);
    case (DAE.WHOLEDIM()::rest, _, arg)
      equation
        (res,arg) = traverseExpSubs(rest,rel,arg);
        res = if referenceEq(rest,res) then inSubscript else (DAE.WHOLEDIM()::res);
      then (res, arg);

    case (DAE.SLICE(exp = sub_exp)::rest, _, arg)
      equation
        (sub_exp_1,arg) = traverseExpBottomUp(sub_exp, rel, arg);
        (res,arg) = traverseExpSubs(rest,rel,arg);
        res = if referenceEq(sub_exp,sub_exp_1) and referenceEq(rest,res) then inSubscript else (DAE.SLICE(sub_exp_1)::res);
      then
        (res, arg);

    case (DAE.INDEX(exp = sub_exp)::rest, _, arg)
      equation
        (sub_exp_1,arg) = traverseExpBottomUp(sub_exp, rel, arg);
        (res,arg) = traverseExpSubs(rest,rel,arg);
        res = if referenceEq(sub_exp,sub_exp_1) and referenceEq(rest,res) then inSubscript else (DAE.INDEX(sub_exp_1)::res);
      then
        (res, arg);

    case (DAE.WHOLE_NONEXP(exp = sub_exp)::rest, _, arg)
      equation
        (sub_exp_1,arg) = traverseExpBottomUp(sub_exp, rel, arg);
        (res,arg) = traverseExpSubs(rest,rel,arg);
        res = if referenceEq(sub_exp,sub_exp_1) and referenceEq(rest,res) then inSubscript else (DAE.WHOLE_NONEXP(sub_exp_1)::res);
      then
        (res, arg);

  end match;
end traverseExpSubs;

public function traverseExpTopDownCrefHelper
  input DAE.ComponentRef inCref;
  input FuncType rel;
  input Argument iarg;
  output DAE.ComponentRef outCref;
  output Argument outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input Argument inArg;
    output DAE.Exp outExp;
    output Boolean cont;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
algorithm
  (outCref, outArg) := match(inCref, rel, iarg)
    local
      String name;
      ComponentRef cr, cr_1;
      Type ty;
      list<DAE.Subscript> subs, subs_1;
      Argument arg;

    case (DAE.CREF_QUAL(ident = name, identType = ty, subscriptLst = subs, componentRef = cr), _, arg)
      equation
        (subs_1,arg) = traverseExpTopDownSubs(subs, rel, arg);
        (cr_1, arg) = traverseExpTopDownCrefHelper(cr, rel, arg);
      then
        (if referenceEq(subs,subs_1) and referenceEq(cr,cr_1) then inCref else DAE.CREF_QUAL(name, ty, subs_1, cr_1), arg);

    case (DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs), _, arg)
      equation
        (subs_1,arg) = traverseExpTopDownSubs(subs, rel, arg);
      then
        (if referenceEq(subs,subs_1) then inCref else DAE.CREF_IDENT(name, ty, subs_1), arg);

    case (DAE.WILD(), _, arg) then (inCref, arg);
  end match;
end traverseExpTopDownCrefHelper;

protected function traverseExpBidirSubs<ArgT>
  "Helper function to traverseExpBidirCref. Traverses expressions in a
  subscript."
  input DAE.Subscript inSubscript;
  input FuncType inEnterFunc;
  input FuncType inExitFunc;
  input ArgT inArg;
  output DAE.Subscript outSubscript;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outSubscript, outArg) := match(inSubscript)
    local
      DAE.Exp sub_exp;
      ArgT arg;

    case DAE.WHOLEDIM() then (inSubscript, inArg);

    case DAE.SLICE(exp = sub_exp)
      equation
        (sub_exp, arg) = traverseExpBidir(sub_exp, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.SLICE(sub_exp), arg);

    case DAE.INDEX(exp = sub_exp)
      equation
        (sub_exp, arg) = traverseExpBidir(sub_exp, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.INDEX(sub_exp), arg);

    case DAE.WHOLE_NONEXP(exp = sub_exp)
      equation
        (sub_exp, arg) = traverseExpBidir(sub_exp, inEnterFunc, inExitFunc, inArg);
      then
        (DAE.WHOLE_NONEXP(sub_exp), arg);

  end match;
end traverseExpBidirSubs;

protected function traverseExpTopDownSubs
  input list<DAE.Subscript> inSubscript;
  input FuncType rel;
  input Argument iarg;
  output list<DAE.Subscript> outSubscript;
  output Argument arg=iarg;

  partial function FuncType
    input DAE.Exp inExp;
    input Argument inArg;
    output DAE.Exp outExp;
    output Boolean cont;
    output Argument outArg;
  end FuncType;

  replaceable type Argument subtypeof Any;
protected
  DAE.Exp exp;
  DAE.Subscript nsub;
  Boolean allEq=true;
  DoubleEnded.MutableList<DAE.Subscript> delst;
  Integer nEq=0;
algorithm
  for sub in inSubscript loop
    nsub := match sub
      case DAE.WHOLEDIM() then sub;
      case DAE.SLICE()
        algorithm
          (exp,arg) := traverseExpTopDown(sub.exp, rel, arg);
        then if referenceEq(sub.exp, exp) then sub else DAE.SLICE(exp);
      case DAE.INDEX()
        algorithm
          (exp,arg) := traverseExpTopDown(sub.exp, rel, arg);
        then if referenceEq(sub.exp, exp) then sub else DAE.INDEX(exp);
      case DAE.WHOLE_NONEXP()
        algorithm
          (exp,arg) := traverseExpTopDown(sub.exp, rel, arg);
        then if referenceEq(sub.exp, exp) then sub else DAE.WHOLE_NONEXP(exp);
    end match;
    // Preserve reference equality without any allocation if nothing changed
    if (if allEq then not referenceEq(nsub, sub) else false) then
      allEq:=false;
      delst := DoubleEnded.empty(nsub);
      for elt in inSubscript loop
        if nEq < 1 then
          break;
        end if;
        DoubleEnded.push_back(delst, elt);
        nEq := nEq-1;
      end for;
    end if;
    if allEq then
      nEq := nEq + 1;
    else
      DoubleEnded.push_back(delst, nsub);
    end if;
  end for;
  outSubscript := if allEq then inSubscript else DoubleEnded.toListAndClear(delst);
end traverseExpTopDownSubs;

/***************************************************/
/* Compare and Check DAE.Exp */
/***************************************************/

public function operatorDivOrMul "returns true if operator is division or multiplication"
  input DAE.Operator op;
  output Boolean res;
algorithm
  res := match(op)
    case(DAE.MUL(_)) then true;
    case(DAE.DIV(_)) then true;
    else false;
  end match;
end operatorDivOrMul;

public function isRange
"Returns true if expression is a range expression."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    case DAE.RANGE() then true;
    else false;
  end match;
end isRange;

public function isReduction
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    case DAE.REDUCTION() then true;
    else false;
  end match;
end isReduction;

public function isOne
"Returns true if an expression is constant
  and has the value one, otherwise false"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      Integer ival;
      Real rval;
      Boolean res;
      Type t;
      DAE.Exp e;

    case (DAE.ICONST(integer = ival)) then intEq(ival,1);
    case (DAE.RCONST(real = rval)) then realEq(rval,1.0);
    case (DAE.CAST(exp = e))
      equation
        res = isOne(e) "Casting to one is still one" ;
      then
        res;
    else false;
  end match;
end isOne;

public function isZero
"Returns true if an expression is constant
  and has the value zero, otherwise false"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      Integer ival;
      Real rval;
      Type t;
      DAE.Exp e;
      list<DAE.Exp> ae;
      list<list<DAE.Exp>> matrix;

    case (DAE.ICONST(integer = ival))
     then intEq(ival,0);

    case (DAE.RCONST(real = rval))
     then realEq(rval,0.0);

    case (DAE.CAST(exp = e))
     then isZero(e);

    case (DAE.UNARY(DAE.UMINUS(_),e))
     then isZero(e);

    case (DAE.ARRAY(array = ae))
     then List.mapAllValueBool(ae,isZero,true);

    case (DAE.MATRIX(matrix = matrix))
     then List.mapListAllValueBool(matrix,isZero,true);

    case (DAE.UNARY(DAE.UMINUS_ARR(_),e))
     then isZero(e);

    else false;

  end match;
end isZero;


public function isZeroOrAlmostZero
"Returns true if an expression is constant
  and zero or near to zero, otherwise false"
  input DAE.Exp inExp;
  input DAE.Exp nominal = DAE.RCONST(1.0);
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp, nominal)
    local
      Integer ival;
      Real rval;
      Type t;
      DAE.Exp e,e1;
      list<DAE.Exp> ae;
      list<list<DAE.Exp>> matrix;
      Real rNom;

    case (DAE.ICONST(integer = ival),_)
     then intEq(ival,0);

    case (DAE.RCONST(real = rval), DAE.RCONST(real=rNom))
     then realLt(abs(rval),1e-6*abs(rNom));

    case (DAE.RCONST(real = rval),_)
     then realLt(abs(rval),1e-6);

    case (DAE.CAST(exp = e),_)
     then isZeroOrAlmostZero(e, nominal);

    case (DAE.UNARY(DAE.UMINUS(_),e),_)
     then isZeroOrAlmostZero(e, nominal);

    case (DAE.ARRAY(array = ae),_)
     then List.map1AllValueBool(ae,isZeroOrAlmostZero,true,nominal);

    case (DAE.MATRIX(matrix = matrix),_)
      then List.map1ListAllValueBool(matrix,isZeroOrAlmostZero,true,nominal);

    case (DAE.UNARY(DAE.UMINUS_ARR(_),e),_)
     then isZeroOrAlmostZero(e, nominal);

    case (DAE.IFEXP(_,e,e1),_)
     then (isZeroOrAlmostZero(e, nominal) or isZeroOrAlmostZero(e1, nominal));

    else false;

  end match;
end isZeroOrAlmostZero;


public function isPositiveOrZero
  "Returns true if an expression is known to be >= 0"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm


  outBoolean := match (inExp)
    local
      Boolean b,b1,b2,b3;
      DAE.Exp e1,e2;
      Integer i;
      Real r;
      /* abs(e) */
    case DAE.CALL(path = Absyn.IDENT("abs")) then true;
    // exp(x)
    case DAE.CALL(path = Absyn.IDENT("exp")) then true;
    // cosh(x)
    case DAE.CALL(path = Absyn.IDENT("cosh")) then true;
      /* literals */
    case DAE.ICONST(i) then i>=0;
    case DAE.RCONST(r) then realGe(r,0.0);
      /* e1 + e2 */
    case DAE.BINARY(e1,DAE.ADD(),e2)
      then isPositiveOrZero(e1) and isPositiveOrZero(e2);
      /* e1 - e2 */
    case DAE.BINARY(e1,DAE.SUB(),e2)
      then isPositiveOrZero(e1) and isNegativeOrZero(e2);
      /* e1 * e2 , -e1 * -e2, e ^ 2.0 */
    case DAE.BINARY(e1,DAE.MUL(),e2)
      equation
        b1 = (isPositiveOrZero(e1) and isPositiveOrZero(e2));
        b2 = (isNegativeOrZero(e1) and isNegativeOrZero(e2));
        b3 = expEqual(e1,e2);
      then b1 or b2 or b3;
      /* e1 / e2, -e1 / -e2 */
    case DAE.BINARY(e1,DAE.DIV(),e2)
      equation
        b1 = (isPositiveOrZero(e1) and isPositiveOrZero(e2));
        b2 = (isNegativeOrZero(e1) and isNegativeOrZero(e2));
      then b1 or b2;
      /* Integer power we can say something good about */
    case DAE.BINARY(e1,DAE.POW(),DAE.RCONST(r))
      equation
        i = realInt(r);
        b1 = realEq(r,intReal(i));
        b2 = 0 == intMod(i,2);
        b3 = isPositiveOrZero(e1);
        b = b2 or b3;
      then b1 and b;
    case DAE.BINARY(_,DAE.POW(),e2) then isEven(e2);
    // -(x)
    case DAE.UNARY(DAE.UMINUS(), e1) then isNegativeOrZero(e1);
    else isZero(inExp);

  end match;
end isPositiveOrZero;

public function isNegativeOrZero
"Returns true if an expression is known to be <= 0"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local Integer i; Real r; DAE.Exp e1,e2;
    /* literals */
    case DAE.ICONST(i) then i <= 0;
    case DAE.RCONST(r) then r <= 0.0;
    // -(x)
    case DAE.UNARY(DAE.UMINUS(), e1) then isPositiveOrZero(e1);
    /* Integer power we can say something good about */
    case DAE.BINARY(_,DAE.POW(),e2) guard(isOdd(e2)) then isNegativeOrZero(e2);

    else isZero(inExp);

  end match;
end isNegativeOrZero;

public function isHalf
"Returns true if an expression is 0.5"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      Real rval;

    case (DAE.RCONST(real = rval)) then realEq(rval,0.5);
    else false;

  end match;
end isHalf;

public function isAtomic
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    case DAE.CREF() then true;
    case DAE.CALL() then true;
    case DAE.ICONST() then inExp.integer >= 0;
    case DAE.RCONST() then inExp.real > 0.0;
    else false;
  end match;
end isAtomic;

public function isImpure "author: lochel
  Returns true if an expression contains an impure function call."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := isConstWork(inExp);
  (_, outBoolean) := traverseExpTopDown(inExp, isImpureWork, false);
end isImpure;

protected function isImpureWork "author: lochel"
  input DAE.Exp inExp;
  input Boolean isImpure;
  output DAE.Exp outExp;
  output Boolean cont;
  output Boolean outImpure;
algorithm
  (outExp,cont,outImpure) := match (inExp,isImpure)
    case (_, true) then (inExp,true,true);

    case (DAE.CALL(attr=DAE.CALL_ATTR(isImpure=true)), _)
      then (inExp,false,true);

    // workaround for builtin functions that are impure, but not marked as impure
    case (DAE.CALL(path = Absyn.IDENT(name="alarm"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="compareFilesAndMove"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="delay"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="initial"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="print"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="readFile"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="sample"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="system"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="system_parallel"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="terminal"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    case (DAE.CALL(path = Absyn.IDENT(name="writeFile"), attr=DAE.CALL_ATTR(builtin=true)), _)
      then (inExp,false,true);

    else (inExp,true,false);
  end match;
end isImpureWork;


public function containsRecordType
  " Returns true if an expression contains a record type."
  input DAE.Exp inExp;
  output Boolean isRec;
algorithm
  (_, isRec) := traverseExpTopDown(inExp, containsRecordTypeWork, false);
end containsRecordType;

protected function containsRecordTypeWork
  input DAE.Exp inExp;
  input Boolean inRec;
  output DAE.Exp outExp = inExp;
  output Boolean cont = false;
  output Boolean outRec = inRec;
algorithm
  if not inRec then
    (outExp,cont,outRec) := matchcontinue inExp
      local
        DAE.Type ty;
        list<DAE.Exp> expLst;
        Boolean subRec;
        DAE.ComponentRef cr;
      case DAE.RECORD()
        algorithm
        then (inExp,false,true);
      case DAE.CALL(expLst=expLst, attr=DAE.CALL_ATTR(ty=ty))
        algorithm
          subRec := isRecordType(ty);
          if not subRec then
            for exp in expLst loop
              subRec := containsRecordType(exp);
              if subRec then
                break;
              end if;
            end for;
          end if;
        then (inExp,not subRec,subRec);
      else (inExp,true,false);
    end matchcontinue;
  end if;
end containsRecordTypeWork;

public function isConst
"Returns true if an expression is constant"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := isConstWork(inExp);
end isConst;

public function isEvaluatedConst
"Returns true if an expression is really a constant scalar value. no calls, casts, or something"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match inExp
    case DAE.ICONST() then true;
    case DAE.RCONST() then true;
    case DAE.BCONST() then true;
    case DAE.SCONST() then true;
    case DAE.ENUM_LITERAL() then true;
    else false;
  end match;
end isEvaluatedConst;

public function getEvaluatedConstInteger
"Returns the constant integer value, fails for incorrect types."
  input DAE.Exp inExp;
  output Integer val;
algorithm
  val := match inExp
    local
      Integer integer;
    case DAE.ICONST(integer = integer)
      then integer;
    case DAE.RCONST()
      algorithm
        SOME(integer) := realExpIntLit(inExp);
      then integer;
    else fail();
  end match;
end getEvaluatedConstInteger;

protected function isConstWork
"Returns true if an expression is constant"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      Boolean res;
      Operator op;
      DAE.Exp e,e1,e2;
      Type t;
      list<DAE.Exp> ae;
      list<list<DAE.Exp>> matrix;
      Absyn.Path path;

    case (DAE.ICONST()) then true;
    case (DAE.RCONST()) then true;
    case (DAE.BCONST()) then true;
    case (DAE.SCONST()) then true;
    case (DAE.ENUM_LITERAL()) then true;

    case (DAE.UNARY(exp = e)) then isConstWork(e);

    case (DAE.CAST(exp = e)) then isConstWork(e);

    case (DAE.BINARY(e1,_,e2))
      equation
        res = isConstWork(e2);
      then
        if res then isConstWork(e1) else false;

    case (DAE.IFEXP(e,e1,e2))
      equation
        res = isConstWork(e2);
        if res then
          res = isConstWork(e1);
        end if;
      then
        if res then isConstWork(e) else false;

    case (DAE.LBINARY(exp1=e1,exp2=e2))
      equation
        res = isConstWork(e2);
      then
        if res then isConstWork(e1) else false;

    case (DAE.LUNARY(exp=e)) then isConstWork(e);

    case (DAE.RELATION(exp1=e1,exp2=e2))
      equation
        res = isConstWork(e2);
      then
        if res then isConstWork(e1) else false;

    case (DAE.ARRAY(array = ae)) then isConstWorkList(ae);

    case (DAE.MATRIX(matrix = matrix)) then isConstWorkListList(matrix);

    case (DAE.RANGE(start=e1,step=NONE(),stop=e2))
      equation
        res = isConstWork(e2);
      then
        if res then isConstWork(e1) else false;

    case (DAE.RANGE(start=e,step=SOME(e1),stop=e2))
      equation
        res = isConstWork(e2);
        if res then
          res = isConstWork(e1);
        end if;
      then
        if res then isConstWork(e) else false;

    case (DAE.PARTEVALFUNCTION(expList = ae)) then isConstWorkList(ae);

    case (DAE.TUPLE(PR = ae)) then isConstWorkList(ae);

    case (DAE.ASUB(exp=e,sub=ae))
      equation
        res = isConstWork(e);
      then
        if res then isConstWorkList(ae) else false;

    case (DAE.TSUB(exp=e)) then isConstWork(e);

    case (DAE.SIZE(exp=e,sz=NONE())) then isConstWork(e);

    case (DAE.SIZE(exp=e1,sz=SOME(e2)))
      equation
        res = isConstWork(e2);
      then
        if res then isConstWork(e1) else false;

    case (DAE.CALL(expLst=ae, attr=DAE.CALL_ATTR(builtin=false, isImpure=false))) then isConstWorkList(ae);
    case (DAE.CALL(path=path, expLst=ae, attr=DAE.CALL_ATTR(builtin=true))) then
      if listMember(AbsynUtil.pathFirstIdent(path),
        {"initial","terminal","sample" /* der/edge/change/pre belongs to this list usually, but if we optimize the expression, we might end up with pre of a constant expression... */}
        ) then false else isConstWorkList(ae);

    case (DAE.RECORD(exps=ae)) then isConstWorkList(ae);

      /*TODO:Make this work for multiple iters, guard exps*/
    case (DAE.REDUCTION(expr=e1,iterators={DAE.REDUCTIONITER(exp=e2)}))
      equation
        res = isConstWork(e2);
      then
        if res then isConstWork(e1) else false;

    case(DAE.BOX(exp=e)) then isConstWork(e);

    else false;
  end match;
end isConstWork;

protected function isConstValueWork
"Returns true if an expression is a constant value"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      Boolean res;
      DAE.Exp e,e1,e2;
      list<DAE.Exp> ae;
      list<list<DAE.Exp>> matrix;

    case DAE.ICONST() then true;
    case DAE.RCONST() then true;
    case DAE.BCONST() then true;
    case DAE.SCONST() then true;
    case DAE.ENUM_LITERAL() then true;
    case DAE.ARRAY(array = ae) then isConstValueWorkList(ae);
    case DAE.MATRIX(matrix = matrix) then isConstValueWorkListList(matrix);
    case DAE.RECORD() then true;
    case DAE.METARECORDCALL() then true;
    else false;

  end match;
end isConstValueWork;

public function isConstValue
"Returns true if an expression is a constant value (not a composite operation)"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := isConstValueWork(inExp);
end isConstValue;

public function isConstWorkList
"Returns true if a list of expressions is constant"
  input list<DAE.Exp> inExps;
  output Boolean outBoolean;
protected
  DAE.Exp e;
  list<DAE.Exp> exps;
  Boolean b = true;
algorithm
  exps := inExps;
  while b and not listEmpty(exps) loop
    e::exps := exps;
    b := isConstWork(e);
  end while;
  outBoolean := b;
end isConstWorkList;

protected function isConstWorkListList
  input list<list<DAE.Exp>> inExps;
  output Boolean outIsConst;
protected
  list<DAE.Exp> e;
  list<list<DAE.Exp>> exps;
  Boolean b = true;
algorithm
  exps := inExps;
  while b and not listEmpty(exps) loop
    e::exps := exps;
    b := isConstWorkList(e);
  end while;
  outIsConst := b;
end isConstWorkListList;

protected function isConstValueWorkList
"Returns true if a list of expressions is a constant value"
  input list<DAE.Exp> inExps;
  output Boolean outBoolean;
protected
  DAE.Exp e;
  list<DAE.Exp> exps;
  Boolean b = true;
algorithm
  exps := inExps;
  while b and not listEmpty(exps) loop
    e::exps := exps;
    b := isConstValueWork(e);
  end while;
  outBoolean := b;
end isConstValueWorkList;

protected function isConstValueWorkListList
  input list<list<DAE.Exp>> inExps;
  output Boolean outIsConst;
protected
  list<DAE.Exp> e;
  list<list<DAE.Exp>> exps;
  Boolean b = true;
algorithm
  exps := inExps;
  while b and not listEmpty(exps) loop
    e::exps := exps;
    b := isConstValueWorkList(e);
  end while;
  outIsConst := b;
end isConstValueWorkListList;

public function isNotConst
"author: PA
  Check if expression is not constant."
  input DAE.Exp e;
  output Boolean nb;
protected
  Boolean b;
algorithm
  b := isConst(e);
  nb := boolNot(b);
end isNotConst;

public function isRelation "Returns true if expression is a relation"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    case (DAE.RELATION()) then true;
    else false;
  end match;
end isRelation;

public function isEventTriggeringFunctionExp
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := match(inExp)
    case (DAE.CALL(path = Absyn.IDENT("div"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("mod"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("rem"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("ceil"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("floor"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("integer"))) then true;
    else false;
  end match;
end isEventTriggeringFunctionExp;

public function isAddOrSub "returns true if operator is ADD or SUB"
  input DAE.Operator op;
  output Boolean res;
algorithm
  res := isAdd(op) or isSub(op);
end isAddOrSub;

public function isAdd "returns true if operator is ADD"
  input DAE.Operator op;
  output Boolean res;
algorithm
  res := match(op)
    case(DAE.ADD()) then true;
    case(DAE.ADD_ARR()) then true;
    else false;
  end match;
end isAdd;

public function isSub "returns true if operator is SUB"
  input DAE.Operator op;
  output Boolean res;
algorithm
  res := match(op)
    case(DAE.SUB()) then true;
    case(DAE.SUB_ARR()) then true;
    else false;
  end match;
end isSub;

public function isAddOrSubBinary "returns true if BINARY is a+b or a-b"
  input DAE.Exp iExp;
  output Boolean res;
protected
  DAE.Operator op;
algorithm
  res := match(iExp)
         case(DAE.BINARY(_,op,_)) then isAddOrSub(op);
         else false;
         end match;
end isAddOrSubBinary;

public function isMulOrDiv "returns true if operator is MUL or DIV"
  input DAE.Operator op;
  output Boolean res = isMul(op) or isDiv(op);
end isMulOrDiv;

public function isMul "returns true if operator is MUL"
  input DAE.Operator op;
  output Boolean res;
algorithm
  res := match(op)
    case(DAE.MUL()) then true;
    case(DAE.MUL_ARR()) then true;
    else false;
  end match;
end isMul;

public function isDiv "returns true if operator is DIV"
  input DAE.Operator op;
  output Boolean res;
algorithm
  res := match(op)
    case(DAE.DIV()) then true;
    case(DAE.DIV_ARR()) then true;
    else false;
  end match;
end isDiv;

public function isDivBinary "returns true if BINARY is a/b"
  input DAE.Exp iExp;
  output Boolean res;
protected
  DAE.Operator op;
algorithm
  res := match(iExp)
         case(DAE.BINARY(_,op,_)) then isDiv(op);
         else false;
         end match;
end isDivBinary;


public function isMulorDivBinary "returns true if BINARY is a/b or a*b"
  input DAE.Exp iExp;
  output Boolean res;
protected
  DAE.Operator op;
algorithm
  res := match(iExp)
         case(DAE.BINARY(_,op,_)) then isMulOrDiv(op);
         else false;
         end match;
end isMulorDivBinary;

public function isPow "returns true if operator is POW"
  input DAE.Operator op;
  output Boolean res;
algorithm
  res := match(op)
    case(DAE.POW()) then true;
    else false;
  end match;
end isPow;


public function isFunCall "return true if expression is DAE.CALL(path=Absyn.IDENT(name))"
  input DAE.Exp iExp;
  input String name;
  output Boolean res;
algorithm
  res := match(iExp, name)
         local String name_;
          case(DAE.CALL(path=Absyn.IDENT(name_)),_) then name_ == name;
          else false;
         end match;
end isFunCall;

public function equalTypes ""
input DAE.Type t1,t2;
output Boolean b;
algorithm b := matchcontinue(t1,t2)
  local
    list<DAE.Var> vars1,vars2;
    Type ty1,ty2;
    DAE.Dimensions ad1,ad2;
    list<Integer> li1,li2;

  case(DAE.T_INTEGER(),DAE.T_INTEGER()) then true;
  case(DAE.T_REAL(),DAE.T_REAL()) then true;
  case(DAE.T_STRING(),DAE.T_STRING()) then true;
  case(DAE.T_BOOL(),DAE.T_BOOL()) then true;
  // BTH
  case(DAE.T_CLOCK(),DAE.T_CLOCK()) then true;

  case(DAE.T_COMPLEX(varLst = vars1), DAE.T_COMPLEX(varLst = vars2))
       then equalTypesComplexVars(vars1,vars2);

  case(DAE.T_ARRAY(ty1,ad1),DAE.T_ARRAY(ty2,ad2))
    equation
      li1 = List.map(ad1, dimensionSize);
      li2 = List.map(ad2, dimensionSize);
      true = List.isEqualOnTrue(li1,li2,intEq);
      true = equalTypes(ty1,ty2);
    then
      true;
  else false;
  end matchcontinue;
end equalTypes;

protected function equalTypesComplexVars ""
  input list<DAE.Var> inVars1,inVars2;
  output Boolean b;
algorithm
  b := matchcontinue(inVars1,inVars2)
    local
      DAE.Type t1,t2;
      String s1,s2;
      list<DAE.Var> vars1,vars2;

    case({},{}) then true;

    case(DAE.TYPES_VAR(name = s1, ty = t1)::vars1,DAE.TYPES_VAR(name = s2, ty = t2)::vars2)
      equation
        //print(" verify subvars: " + s1 + " and " + s2 + " to go: " + intString(listLength(vars1)) + " , " + intString(listLength(vars2))  + "\n");
        true = stringEq(s1,s2);
        //print(" types: " + Types.unparseType(t1) + " and " + Types.unparseType(t2) + "\n");
        true = equalTypes(t1,t2);
        //print(s1 + " and " + s2 + " EQUAL \n\n");
      then
        equalTypesComplexVars(vars1,vars2);

    else false;
  end matchcontinue;
end equalTypesComplexVars;

public function typeBuiltin
"Returns true if type is one of the builtin types."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inType)
    case (DAE.T_INTEGER()) then true;
    case (DAE.T_REAL()) then true;
    case (DAE.T_STRING()) then true;
    case (DAE.T_BOOL()) then true;
    // BTH
    case (DAE.T_CLOCK()) then true;
    else false;
  end match;
end typeBuiltin;

public function isWholeDim ""
  input DAE.Subscript s;
  output Boolean b;
algorithm
  b := match(s)
    case(DAE.WHOLEDIM()) then true;
    else false;
  end match;
end isWholeDim;

public function isInt ""
  input DAE.Type it;
  output Boolean re;
algorithm
  re := match(it)
    local
      Type t1;
    case(DAE.T_INTEGER()) then true;
    case(DAE.T_ARRAY(ty=t1)) then isInt(t1);
    else false;
  end match;
end isInt;

public function isReal ""
  input DAE.Type it;
  output Boolean re;
algorithm
  re := match(it)
    local
      Type t1;
    case(DAE.T_REAL()) then true;
    case(DAE.T_ARRAY(ty=t1)) then isReal(t1);
  else false;
  end match;
end isReal;

public function isExpReal ""
  input DAE.Exp e;
  output Boolean re;
algorithm
  re := isReal(typeof(e));
end isExpReal;

public function isConstZeroLength
  "Return true if expression has zero-dimension"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    case DAE.ARRAY(array={}) then true;
    case DAE.MATRIX(matrix={}) then true;
    else false;
  end match;
end isConstZeroLength;

public function isConstFalse
"Return true if expression is false"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp)
    case DAE.BCONST(false) then true;
    else false;
  end match;
end isConstFalse;

public function isConstTrue
"Return true if expression is true"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp)
    case DAE.BCONST(true) then true;
    else false;
  end match;
end isConstTrue;

public function isConstOne
"Return true if expression is 1"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp)
    local Real rval; Integer ival;

    // constant real 1.0
    case DAE.RCONST(rval) then realEq(rval, 1.0);
    // constant integer 1
    case DAE.ICONST(ival) then intEq(ival, 1);
    // anything else
    else false;
  end match;
end isConstOne;

public function isConstMinusOne
"Return true if expression is -1"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp)
    local Real rval; Integer ival;

    // is real -1.0
    case DAE.RCONST(rval) then realEq(rval, -1.0);
    // is integer -1
    case DAE.ICONST(ival) then intEq(ival, -1);
    // anything else
    else false;
  end match;
end isConstMinusOne;


public function isGreatereqOrLesseq
  input DAE.Operator op;
  output Boolean b;
algorithm
  b := match(op)
       case(DAE.GREATEREQ()) then true;
       case(DAE.LESSEQ()) then true;
       else false;
       end match;
end isGreatereqOrLesseq;

public function isLesseqOrLess
  input DAE.Operator op;
  output Boolean b;
algorithm
  b := match(op)
       case(DAE.LESS()) then true;
       case(DAE.LESSEQ()) then true;
       else false;
       end match;
end isLesseqOrLess;


public function containVectorFunctioncall
"Returns true if expression or subexpression is a
 functioncall that returns an array, otherwise false.
  Note: the der operator is represented as a
        function call but still return false."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      DAE.Exp e1,e2,e,e3;
      Boolean res;
      list<Boolean> blst;
      list<DAE.Exp> elst,flatexplst;
      list<list<DAE.Exp>> explst;
      Option<DAE.Exp> optexp;

    // der is not a vector function
    case (DAE.CALL(path = Absyn.IDENT(name = "der"))) then false;

    // pre is not a vector function, adrpo: 2009-03-03 -> pre is also needed here!
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    case (DAE.CALL(path = Absyn.IDENT(name = "previous"))) then false;
    // inStream and actualStream are not a vector function, adrpo: 2010-08-31 -> they are also needed here!
    case (DAE.CALL(path = Absyn.IDENT(name = "inStream"))) then false;
    case (DAE.CALL(path = Absyn.IDENT(name = "actualStream"))) then false;

    // a call that has an return array type returns true
    case (DAE.CALL(attr = DAE.CALL_ATTR(ty = DAE.T_ARRAY()))) then true;

    // any other call returns false
    case (DAE.CALL()) then false;

    // partial evaluation
    case (DAE.PARTEVALFUNCTION(expList = elst)) // stefan
      then
        List.mapBoolOr(elst,containVectorFunctioncall);

    // binary operators, e1 has a vector function call
    case (DAE.BINARY(exp1 = e1)) guard containVectorFunctioncall(e1)
      then
        true;
    // binary operators, e2 has a vector function call
    case (DAE.BINARY(exp2 = e2)) guard containVectorFunctioncall(e2)
      then
        true;
    // unary operators
    case (DAE.UNARY(exp = e))
      then
        containVectorFunctioncall(e);
    // logical binary operators, e1 is a vector call
    case (DAE.LBINARY(exp1 = e1)) guard containVectorFunctioncall(e1)
      then
        true;
    // logical binary operators, e2 is a vector call
    case (DAE.LBINARY(exp2 = e2)) guard containVectorFunctioncall(e2)
      then
        true;
    // logical unary operators, e is a vector call
    case (DAE.LUNARY(exp = e))
      then
        containVectorFunctioncall(e);
    // relations e1 op e2, where e1 is a vector call
    case (DAE.RELATION(exp1 = e1)) guard containVectorFunctioncall(e1)
      then
        true;
    // relations e1 op e2, where e2 is a vector call
    case (DAE.RELATION(exp2 = e2)) guard containVectorFunctioncall(e2)
      then
        true;
    // if expression where the condition is a vector call
    case (DAE.IFEXP(expCond = e1)) guard containVectorFunctioncall(e1)
      then
        true;
    // if expression where the then part is a vector call
    case (DAE.IFEXP(expThen = e2)) guard containVectorFunctioncall(e2)
      then
        true;
    // if expression where the else part is a vector call
    case (DAE.IFEXP(expElse = e3)) guard containVectorFunctioncall(e3)
      then
        true;
    // arrays
    case (DAE.ARRAY(array = elst))
      then
        List.mapBoolOr(elst, containVectorFunctioncall);
    // matrixes
    case (DAE.MATRIX(matrix = explst))
      equation
        flatexplst = List.flatten(explst);
        res = List.mapBoolOr(flatexplst, containVectorFunctioncall);
      then
        res;
    // ranges [e1:step:e2], where e1 is a vector call
    case (DAE.RANGE(start = e1)) guard containVectorFunctioncall(e1)
      then
        true;
    // ranges [e1:step:e2], where e2 is a vector call
    case (DAE.RANGE(stop = e2)) guard containVectorFunctioncall(e2)
      then
        true;
    // ranges [e1:step:e2], where step is a vector call
    case (DAE.RANGE(step = SOME(e))) guard containVectorFunctioncall(e)
      then
        true;
    // tuples return true all the time???!! adrpo: FIXME! TODO! is this really true?
    case (DAE.TUPLE(PR = elst))
      then
        List.mapBoolOr(elst, containVectorFunctioncall);
    // cast
    case (DAE.CAST(exp = e))
      then
        containVectorFunctioncall(e);
    // size operator
    case (DAE.SIZE(exp = e1)) guard containVectorFunctioncall(e1)
      then
        true;
    // size operator
    case (DAE.SIZE(sz = SOME(e2))) guard containVectorFunctioncall(e2)
      then
        true;
    // any other expressions return false
    else false;
  end match;
end containVectorFunctioncall;

public function containFunctioncall
"Returns true if expression or subexpression
  is a functioncall, otherwise false.
  Note: the der and pre operators are represented
        as function calls but still returns false."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      DAE.Exp e1,e2,e,e3;
      Boolean res;
      list<Boolean> blst;
      list<DAE.Exp> elst,flatexplst;
      list<list<DAE.Exp>> explst;
      Option<DAE.Exp> optexp;

    // der(x) is not a function call
    case (DAE.CALL(path = Absyn.IDENT(name = "der"))) then false;

    // pre(x) is not a function call
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;

    case (DAE.CALL(path = Absyn.IDENT(name = "previous"))) then false;

    // any other call is a function call
    case (DAE.CALL()) then true;

    // partial evaluation functions
    case (DAE.PARTEVALFUNCTION(expList = elst)) // stefan
      equation
        res = List.mapBoolOr(elst,containFunctioncall);
      then
        res;

    // binary
    case (DAE.BINARY(exp1 = e1)) guard containFunctioncall(e1)
      then
        true;

    case (DAE.BINARY(exp2 = e2)) guard containFunctioncall(e2)
      then
        true;

    // unary
    case (DAE.UNARY(exp = e))
      then
        containFunctioncall(e);

    // logical binary
    case (DAE.LBINARY(exp1 = e1)) guard containFunctioncall(e1)
      then
        true;

    case (DAE.LBINARY(exp2 = e2)) guard containFunctioncall(e2)
      then
        true;

    // logical unary
    case (DAE.LUNARY(exp = e))
      then
        containFunctioncall(e);

    // relations
    case (DAE.RELATION(exp1 = e1)) guard containFunctioncall(e1)
      then
        true;

    case (DAE.RELATION(exp2 = e2)) guard containFunctioncall(e2)
      then
        true;

    // if expressions
    case (DAE.IFEXP(expCond = e1)) guard containFunctioncall(e1)
      then
        true;

    case (DAE.IFEXP(expThen = e2)) guard containFunctioncall(e2)
      then
        true;

    case (DAE.IFEXP(expElse = e3)) guard containFunctioncall(e3)
      then
        true;

    // arrays
    case (DAE.ARRAY(array = elst))
      then
        List.mapBoolOr(elst, containFunctioncall);

    // matrix
    case (DAE.MATRIX(matrix = explst))
      equation
        flatexplst = List.flatten(explst);
        res = List.mapBoolOr(flatexplst, containFunctioncall);
      then
        res;

    // ranges
    case (DAE.RANGE(start = e1)) guard containFunctioncall(e1)
      then
        true;

    case (DAE.RANGE(stop = e2)) guard containFunctioncall(e2)
      then
        true;

    case (DAE.RANGE(step = SOME(e))) guard containFunctioncall(e)
      then
        true;

    // tuples return true all the time???!! adrpo: FIXME! TODO! is this really true?
    case (DAE.TUPLE(PR = elst))
      then
        List.mapBoolOr(elst, containVectorFunctioncall);

    // cast
    case (DAE.CAST(exp = e))
      then
        containFunctioncall(e);

    // asub
    case (DAE.ASUB(exp = e))
      then
        containFunctioncall(e);

    // size
    case (DAE.SIZE(exp = e1)) guard containFunctioncall(e1)
      then
        true;

    case (DAE.SIZE(sz = SOME(e2))) guard containFunctioncall(e2)
      then
        true;

    // anything else
    else false;

  end match;
end containFunctioncall;

public function expIntOrder "Function: expIntOrder
This function takes a list of Exp, assumes they are all ICONST
and checks wheter the ICONST are in order."
  input Integer expectedValue;
  input list<DAE.Exp> integers;
  output Boolean ob;
algorithm
  ob := match(expectedValue,integers)
    local
      list<DAE.Exp> expl;
      Integer x1,x2;
      Boolean b;
    case(_,{}) then true;
    case(x1, DAE.ICONST(x2)::expl) guard intEq(x1, x2)
      then
        expIntOrder(x1+1,expl);
    else false;
  end match;
end expIntOrder;

public function isArray "returns true if expression is an array.
"
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := match(inExp)
    case(DAE.ARRAY()) then true;
    case(DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=DAE.ARRAY())) then true;
    else false;
  end match;
end isArray;

public function isMetaArray "returns true if expression is a MM array."
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := Types.isMetaArray(typeof(inExp));
end isMetaArray;

public function isMatrix "returns true if expression is an matrix.
"
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := match(inExp)
    case(DAE.MATRIX()) then true;
    case(DAE.UNARY(operator=DAE.UMINUS_ARR(),exp=DAE.MATRIX())) then true;
    else false;
  end match;
end isMatrix;

public function isVector
  "Returns true if the expression is a vector, i.e. an array with one dimension,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsVector;
algorithm
  outIsVector := match(inExp)
    // Nested arrays are not vectors.
    case DAE.ARRAY(ty = DAE.T_ARRAY(ty = DAE.T_ARRAY())) then false;
    // Non-nested array with one dimension is a vector.
    case DAE.ARRAY(ty = DAE.T_ARRAY(dims = {_})) then true;
    else false;
  end match;
end isVector;

public function isUnary
  "Returns true if expression is an unary."
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB:= match(inExp)
    case(DAE.UNARY()) then true;
    else false;
  end match;
end isUnary;

public function isBinary
  "Returns true if expression is an binary."
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB:= match(inExp)
    case(DAE.BINARY()) then true;
    else false;
  end match;
end isBinary;

public function isNegativeUnary
  "Returns true if expression is a negative unary."
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB:= match(inExp)
    case(DAE.UNARY(operator=DAE.UMINUS())) then true;
    else false;
  end match;
end isNegativeUnary;

public function isCref
  "Returns true if the given expression is a component reference,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsCref;
algorithm
  outIsCref := match(inExp)
    case DAE.CREF() then true;
    else false;
  end match;
end isCref;

public function isUnaryCref
  input DAE.Exp inExp;
  output Boolean outIsCref;
algorithm
  outIsCref := match inExp
    case DAE.UNARY(DAE.UMINUS(), DAE.CREF()) then true;
    else false;
  end match;

end isUnaryCref;

public function isCall
  "Returns true if the given expression is a function call,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsCall;
algorithm
  outIsCall := match(inExp)
    case DAE.CALL() then true;
    else false;
  end match;
end isCall;

public function isTSUB
  "Returns true if the given expression is TSUB,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsCall;
algorithm
  outIsCall := match(inExp)
    case DAE.TSUB() then true;
    else false;
  end match;
end isTSUB;

public function isPureCall
  "Returns true if the given expression is a pure function call,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsPureCall;
algorithm
  outIsPureCall := isCall(inExp) and not isImpure(inExp);
end isPureCall;

public function isImpureCall
  "Returns true if the given expression is a pure function call,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsPureCall;
algorithm
  outIsPureCall := isCall(inExp) and isImpure(inExp);
end isImpureCall;

public function isRecordCall
  "Returns true if the given expression is a record call,i.e. a function call without elements
   otherwise false."
  input DAE.Exp inExp;
  input DAE.FunctionTree funcsIn;
  output Boolean outIsCall;
algorithm
  outIsCall := match(inExp,funcsIn)
    local
      Absyn.Path path;
      DAE.Function func;
    case (DAE.CALL(path=path),_)
      equation
        SOME(func) = DAE.AvlTreePathFunction.get(funcsIn,path);
         then listEmpty(DAEUtil.getFunctionElements(func));
    else false;
  end match;
end isRecordCall;

public function isNotCref
  "Returns true if the given expression is a not component reference,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsCref;
algorithm
  outIsCref := match(inExp)
    case DAE.CREF() then false;
    else true;
  end match;
end isNotCref;

public function isCrefArray
  "Checks whether a cref is an array or not.
"
  input DAE.Exp inExp;
  output Boolean outIsArray;
algorithm
  outIsArray := match(inExp)
    case(DAE.CREF(ty = DAE.T_ARRAY())) then true;
    else false;
  end match;
end isCrefArray;

public function isCrefScalar
  "Checks whether an expression is a scalar cref or not."
  input DAE.Exp inExp;
  output Boolean isScalar;
algorithm
  isScalar := matchcontinue(inExp)
    local
      ComponentRef cr;
      Boolean b;

    case DAE.CREF(ty = DAE.T_ARRAY())
      equation
        cr = expCref(inExp);
        b = ComponentReference.crefHasScalarSubscripts(cr);
      then
        b;

    case DAE.CREF() then true;

    else false;
  end matchcontinue;
end isCrefScalar;

public function isTuple
  "Returns true if the given expression is a tuple,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsTuple;
algorithm
  outIsTuple := match(inExp)
    case DAE.TUPLE() then true;
    else false;
  end match;
end isTuple;

public function isRecord
  "Returns true if the given expression is a record,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsRecord;
algorithm
  outIsRecord := match(inExp)
    case DAE.RECORD() then true;
    else false;
  end match;
end isRecord;

public function isScalarConst
  "Returns true if the given expression is a scalar constant, otherwise false."
  input DAE.Exp inExp;
  output Boolean outIsScalar;
algorithm
  outIsScalar := match(inExp)
    case DAE.ICONST() then true;
    case DAE.RCONST() then true;
    case DAE.SCONST() then true;
    case DAE.BCONST() then true;
    case DAE.ENUM_LITERAL() then true;
    else false;
  end match;
end isScalarConst;

public function expIsPositive "Returns true if an expression is positive,
Returns true in the following cases:
constant >= 0

See also isPositiveOrZero.
"
  input DAE.Exp e;
  output Boolean res;
algorithm
  res :=isPositiveOrZero(e) and not isZero(e);
end expIsPositive;

public function isEven "returns true if const expression is even"
  input DAE.Exp e;
  output Boolean even;
algorithm
  even := match(e)
    local
      Integer i;
      Real r;
      DAE.Exp exp;

    case(DAE.ICONST(i)) then intMod(i,2) == 0;
    case(DAE.RCONST(r)) then realMod(r, 2.0) == 0.0;
    case(DAE.CAST(exp = exp)) then isEven(exp);
    else false;
  end match;
end isEven;

public function isOdd "returns true if const expression is odd"
  input DAE.Exp e;
  output Boolean even;
algorithm
  even := match(e)
    local
      Integer i;
      Real r;
      DAE.Exp exp;

    case(DAE.ICONST(i)) then intMod(i,2) == 1;
    case(DAE.RCONST(r)) then realMod(r, 2.0) == 1.0;
    case(DAE.CAST(exp = exp)) then isOdd(exp);
    else false;
  end match;
end isOdd;

public function isIntegerOrReal "Returns true if Type is Integer or Real"
input DAE.Type tp;
output Boolean res;
algorithm
  res := match(tp)
    case DAE.T_REAL() then  true;
    case DAE.T_INTEGER() then true;
    else false;
  end match;
end isIntegerOrReal;

public function expEqual
  "Returns true if the two expressions are equal, otherwise false."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outEqual;
algorithm
  outEqual := 0==compare(inExp1, inExp2);
end expEqual;

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

public function expStructuralEqual
"Returns true if the two expressions are structural equal. This means
  only the componentreference can be different"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp1,inExp2)
    local
      Integer i1,i2;
      String s1,s2;
      Boolean b,b1,b2,res;
      DAE.Exp e11,e12,e21,e22,e1,e2,e13,e23;
      Operator op1,op2;
      Absyn.Path path1,path2;
      list<DAE.Exp> expl1,expl2;
      list<list<Exp>> explstlst1,explstlst2;
      Type tp1,tp2;
      Real r1,r2;
      Absyn.Path enum1, enum2;
      ComponentRef cr1,cr2;
      list<DAE.Exp> ae1,ae2;
    case (DAE.ICONST(integer = i1),DAE.ICONST(integer = i2)) then (i1 == i2);
    case (DAE.UNARY(DAE.UMINUS(_),DAE.ICONST(integer = i1)),DAE.ICONST(integer = i2))
      equation
        i1 = - i1;
      then (i1 == i2);
    case (DAE.ICONST(integer = i1),DAE.UNARY(DAE.UMINUS(_),DAE.ICONST(integer = i2)))
      equation
        i2 = - i2;
      then (i1 == i2);
    case (DAE.RCONST(real = r1),DAE.RCONST(real = r2)) then (r1 == r2);
    case (DAE.UNARY(DAE.UMINUS(_),DAE.RCONST(real = r1)),DAE.RCONST(real = r2))
      equation
        r1 = - r1;
      then (r1 == r2);
    case (DAE.RCONST(real = r1),DAE.UNARY(DAE.UMINUS(_),DAE.RCONST(real = r2)))
      equation
        r2 = - r2;
      then (r1 == r2);
    case (DAE.SCONST(string = s1),DAE.SCONST(string = s2)) then stringEq(s1, s2);
    case (DAE.BCONST(bool = b1),DAE.BCONST(bool = b2)) then boolEq(b1, b2);
    case (DAE.ENUM_LITERAL(name = enum1), DAE.ENUM_LITERAL(name = enum2)) then AbsynUtil.pathEqual(enum1, enum2);
    case (DAE.CREF(),DAE.CREF()) then true;

    // binary ops
    case (DAE.BINARY(exp1 = e11,operator = op1,exp2 = e12),DAE.BINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b = operatorEqual(op1, op2);
        b = if b then expStructuralEqual(e11, e21) else b;
        b = if b then expStructuralEqual(e12, e22) else b;
      then
        b;

    // logical binary ops
    case (DAE.LBINARY(exp1 = e11,operator = op1,exp2 = e12),
          DAE.LBINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b = operatorEqual(op1, op2);
        b = if b then expStructuralEqual(e11, e21) else b;
        b = if b then expStructuralEqual(e12, e22) else b;
      then
        b;

    // unary ops
    case (DAE.UNARY(operator = op1,exp = e1),DAE.UNARY(operator = op2,exp = e2))
      equation
        b = operatorEqual(op1, op2);
        b = if b then expStructuralEqual(e1, e2) else b;
      then
        b;

    // logical unary ops
    case (DAE.LUNARY(operator = op1,exp = e1),DAE.LUNARY(operator = op2,exp = e2))
      equation
        b = operatorEqual(op1, op2);
        b = if b then expStructuralEqual(e1, e2) else b;
      then
        b;

    // relational ops
    case (DAE.RELATION(exp1 = e11,operator = op1,exp2 = e12),DAE.RELATION(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b = operatorEqual(op1, op2);
        b = if b then expStructuralEqual(e11, e21) else b;
        b = if b then expStructuralEqual(e12, e22) else b;
      then
        b;

    // if expressions
    case (DAE.IFEXP(expCond = e11,expThen = e12,expElse = e13),DAE.IFEXP(expCond = e21,expThen = e22,expElse = e23))
      equation
        b = expStructuralEqual(e11, e21);
        b = if b then expStructuralEqual(e12, e22) else b;
        b = if b then expStructuralEqual(e13, e23) else b;
      then
        b;

    // function calls
    case (DAE.CALL(path = path1,expLst = expl1),DAE.CALL(path = path2,expLst = expl2))
      equation
        b = AbsynUtil.pathEqual(path1, path2);
        b = if b then expStructuralEqualList(expl1, expl2) else b;
      then
        b;
    case (DAE.RECORD(path = path1,exps = expl1),DAE.RECORD(path = path2,exps = expl2))
      equation
        b = AbsynUtil.pathEqual(path1, path2);
        b = if b then expStructuralEqualList(expl1, expl2) else b;
      then
        b;
    // partially evaluated functions
    case (DAE.PARTEVALFUNCTION(path = path1,expList = expl1),DAE.PARTEVALFUNCTION(path = path2,expList = expl2))
      equation
        b = AbsynUtil.pathEqual(path1, path2);
        b = if b then expStructuralEqualList(expl1, expl2) else b;
      then
        b;

    // arrays
    case (DAE.ARRAY(ty = tp1,array = expl1),DAE.ARRAY(ty = tp2,array = expl2))
      equation
        b = valueEq(tp1, tp2);
        b = if b then expStructuralEqualList(expl1, expl2) else b;
      then
        b;

    // matrix
    case (DAE.MATRIX(matrix = explstlst1), DAE.MATRIX(matrix = explstlst2))
      then
        expStructuralEqualListLst(explstlst1,explstlst2);

    // ranges [start:stop]
    case (DAE.RANGE(start = e11,step = NONE(),stop = e13),
          DAE.RANGE(start = e21,step = NONE(),stop = e23))
      equation
        b = expStructuralEqual(e11, e21);
        b = if b then expStructuralEqual(e13, e23) else b;
      then
        b;

    // ranges [start:step:stop]
    case (DAE.RANGE(start = e11,step = SOME(e12),stop = e13),
          DAE.RANGE(start = e21,step = SOME(e22),stop = e23))
      equation
        b = expStructuralEqual(e11, e21);
        b = if b then expStructuralEqual(e12, e22) else b;
        b = if b then expStructuralEqual(e13, e23) else b;
      then
        b;

    // tuples
    case (DAE.TUPLE(PR = expl1),DAE.TUPLE(PR = expl2))
      then expStructuralEqualList(expl1, expl2);

    // casting
    case (DAE.CAST(ty = tp1,exp = e1),DAE.CAST(ty = tp2,exp = e2))
      equation
        b = valueEq(tp1, tp2);
        b = if b then expStructuralEqual(e1, e2) else b;
      then
        b;

    // array subscripts
    case (DAE.ASUB(exp = e1,sub = ae1),DAE.ASUB(sub = ae2))
      equation
        b = expStructuralEqual(e1, e1);
        b = if b then expStructuralEqualList(ae1, ae2) else b;
      then
        b;

    // size(a)
    case (DAE.SIZE(exp = e1,sz = NONE()),DAE.SIZE(exp = e2,sz = NONE()))
      then expStructuralEqual(e1, e2);

    // size(a, dim)
    case (DAE.SIZE(exp = e1,sz = SOME(e11)),DAE.SIZE(exp = e2,sz = SOME(e22)))
      equation
        b = expStructuralEqual(e1, e2);
        b = if b then expStructuralEqual(e11, e22) else b;
      then
        b;

    // metamodeling code
    case (DAE.CODE(),DAE.CODE())
      equation
        Debug.trace("exp_equal on CODE not impl.\n");
      then
        false;

    case (DAE.REDUCTION(),DAE.REDUCTION())
      equation
        // Reductions contain too much information to compare equality in a sane manner
        res = valueEq(inExp1,inExp2);
      then
        res;

    // end id
    /*// everything else failed, try structural equality
    case (e1,e2)
      equation
        equality(e1 = e2);
      then true;
    case (e1,e2)
      equation
        failure(equality(e1 = e2));
      then false;
    */
    // not equal
    case (DAE.LIST(valList = expl1),DAE.LIST(valList = expl2))
      then expStructuralEqualList(expl1, expl2);

    case (DAE.CONS(car = e11,cdr = e12),
          DAE.CONS(car = e21,cdr = e22))
      equation
        b = expStructuralEqual(e11, e21);
        b = if b then expStructuralEqual(e12, e22) else b;
      then
        b;

    case (DAE.META_TUPLE(listExp = expl1),DAE.META_TUPLE(listExp = expl2))
      then expStructuralEqualList(expl1, expl2);

    case (DAE.META_OPTION(exp = NONE()),
          DAE.META_OPTION(exp = NONE()))
      then true;

    case (DAE.META_OPTION(exp = SOME(e1)),
          DAE.META_OPTION(exp = SOME(e2)))
      then expStructuralEqual(e1, e2);

    case (DAE.METARECORDCALL(path = path1,args = expl1),DAE.METARECORDCALL(path = path2,args = expl2))
      equation
        b = AbsynUtil.pathEqual(path1, path2);
        b = if b then expStructuralEqualList(expl1, expl2) else b;
      then
        b;

    case (e1 as DAE.MATCHEXPRESSION(),
          e2 as DAE.MATCHEXPRESSION())
      then valueEq(e1,e2);

    case (DAE.BOX(e1),DAE.BOX(e2))
      then expStructuralEqual(e1, e2);

    case (DAE.UNBOX(exp=e1),DAE.UNBOX(exp=e2))
      then expStructuralEqual(e1, e2);

    case (DAE.SHARED_LITERAL(index=i1),DAE.SHARED_LITERAL(index=i2)) then intEq(i1,i2);

    else false;
  end match;
end expStructuralEqual;

public function expStructuralEqualList
"Returns true if the two lists of expressions are structural equal."
  input list<DAE.Exp> inExp1;
  input list<DAE.Exp> inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp1,inExp2)
    local
      DAE.Exp e1,e2;
      list<DAE.Exp> es1,es2;
      Boolean b;
    case ({},{}) then true;
    case (e1::es1,e2::es2) guard expStructuralEqual(e1,e2)
      then
        expStructuralEqualList(es1, es2);
    else false;
  end match;
end expStructuralEqualList;

protected function expStructuralEqualListLst
"Returns true if the two lists of lists of expressions are structural equal."
  input list<list<DAE.Exp>> inExp1;
  input list<list<DAE.Exp>> inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp1,inExp2)
    local
      list<DAE.Exp> e1,e2;
      list<list<DAE.Exp>> es1,es2;
      Boolean b;
    case ({},{}) then true;
    case (e1::es1,e2::es2) guard expStructuralEqualList(e1,e2)
      then
        expStructuralEqualListLst(es1, es2);
    else false;
  end match;
end expStructuralEqualListLst;

public function expContains
"Returns true if first expression contains the second one as a sub expression.
Only constants, component references or der(componentReference) can be checked
so far."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp1, inExp2)
    local
      Boolean b1, b2;
      Boolean res;
      ComponentRef cr1, cr2;
      DAE.Exp e1, e2, e, c, t, f;
      Integer i1, i2;
      list<DAE.Exp> expLst;
      list<list<DAE.Exp>> expl;
      Real r1, r2;
      String str, s1, s2;

    case (DAE.ICONST(i1), DAE.ICONST(i2)) then i1 == i2;
    case (DAE.ICONST(), _) then false;

    case (DAE.RCONST(r1), DAE.RCONST(r2)) then r1 == r2;
    case (DAE.RCONST(), _) then false;

    case (DAE.SCONST(s1), DAE.SCONST(s2)) then s1 == s2;
    case (DAE.SCONST(), _) then false;

    case (DAE.BCONST(b1), DAE.BCONST(b2)) then b1 == b2;
    case (DAE.BCONST(), _) then true;

    case (DAE.ENUM_LITERAL(), _) then false;

    case (DAE.ARRAY(array=expLst), _) equation
      res = List.map1BoolOr(expLst, expContains, inExp2);
    then res;

    case (DAE.MATRIX(matrix=expl), _) equation
      res = List.map1ListBoolOr(expl, expContains, inExp2);
    then res;

    case (DAE.CREF(componentRef=cr1), DAE.CREF(componentRef=cr2)) equation
      res = ComponentReference.crefEqual(cr1, cr2);
      if not res then
        expLst = List.map(ComponentReference.crefSubs(cr1), getSubscriptExp);
        res = List.map1BoolOr(expLst, expContains, inExp2);
      end if;
    then res;

    case ((DAE.CREF()), _) then false;

    case (DAE.BINARY(exp1=e1, exp2=e2), _) equation
      res = expContains(e1, inExp2);
      res = if res then true else expContains(e2, inExp2);
    then res;

    case (DAE.UNARY(exp=e), _) equation
      res = expContains(e, inExp2);
    then res;

    case (DAE.LBINARY(exp1=e1, exp2=e2), _) equation
      res = expContains(e1, inExp2);
      res = if res then true else expContains(e2, inExp2);
    then res;

    case (DAE.LUNARY(exp=e), _) equation
      res = expContains(e, inExp2);
    then res;

    case (DAE.RELATION(exp1=e1, exp2=e2), _) equation
      res = expContains(e1, inExp2);
      res = if res then true else expContains(e2, inExp2);
    then res;

    case (DAE.IFEXP(expCond=c, expThen=t, expElse=f), _) equation
      res = expContains(c, inExp2);
      res = if res then true else expContains(t, inExp2);
      res = if res then true else expContains(f, inExp2);
    then res;

    case (DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(cr1)}),
          DAE.CALL(path=Absyn.IDENT(name="der"), expLst={DAE.CREF(cr2)})) equation
      res = ComponentReference.crefEqual(cr1, cr2);
    then res;

    // pre(v) does not contain variable v
    case (DAE.CALL(path=Absyn.IDENT(name="pre")), _) then false;
    case (DAE.CALL(path=Absyn.IDENT(name="previous")), _) then false;

    // special rule for no arguments
    case (DAE.CALL(expLst={}), _)
     then false;

    // general case for arguments
    case (DAE.CALL(expLst=expLst), _) equation
      res = List.map1BoolOr(expLst, expContains, inExp2);
    then res;

    case (DAE.PARTEVALFUNCTION(expList=expLst), DAE.CREF()) equation
      res = List.map1BoolOr(expLst, expContains, inExp2);
    then res;

    /* record constructors
    case (DAE.RECORD(exps=expLst), DAE.CREF()) equation
      res = List.map1BoolOr(expLst, expContains, inExp2);
    then res; */

    case (DAE.CAST(ty=DAE.T_REAL(), exp=DAE.ICONST()), _)
    then false;

    case (DAE.CAST(ty=DAE.T_REAL(), exp=e), _) equation
      res = expContains(e, inExp2);
    then res;

    case (DAE.ASUB(exp=e, sub=expLst), _) equation
      res = List.map1BoolOr(expLst, expContains, inExp2);
      res = if res then true else expContains(e, inExp2);
    then res;

    case (DAE.REDUCTION(expr=e), _) equation
      res = expContains(e, inExp2);
    then res;

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.trace("- Expression.expContains failed\n");
      s1 = ExpressionDump.printExpStr(inExp1);
      s2 = ExpressionDump.printExpStr(inExp2);
      str = stringAppendList({"exp = ", s1," subexp = ", s2});
      Debug.traceln(str);
    then fail();
  end matchcontinue;
end expContains;

public function containsExp
"Author BZ 2008-06 same as expContains, but reversed."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean:= expContains(inExp2,inExp1);
end containsExp;

public function isExpCrefOrIfExp
"Returns true if expression is a componentRef or an if expression"
  input DAE.Exp e;
  output Boolean res;
algorithm
  res := match(e)
    case(DAE.CREF(_,_)) then true;
    case(DAE.IFEXP(_,_,_)) then true;
    else false;
  end match;
end isExpCrefOrIfExp;

public function isExpIfExp
"Returns true if expression is an if expression"
  input DAE.Exp e;
  output Boolean res;
algorithm
  res := match(e)
    case DAE.IFEXP() then true;
    else false;
  end match;
end isExpIfExp;

public function operatorEqual
"Helper function to expEqual."
  input DAE.Operator inOperator1;
  input DAE.Operator inOperator2;
  output Boolean outBoolean;
algorithm
  outBoolean := 0==operatorCompare(inOperator1,inOperator2);
end operatorEqual;

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

public function arrayContainZeroDimension
  "Checks if one of the dimensions in a list is zero."
  input list<DAE.Dimension> inDimensions;
  output Boolean outContainZeroDim;
algorithm
  outContainZeroDim := match(inDimensions)
    local
      list<DAE.Dimension> rest_dims;

    case (DAE.DIM_INTEGER(0) :: _) then true;
    case (_ :: rest_dims) then arrayContainZeroDimension(rest_dims);
    else false;

  end match;
end arrayContainZeroDimension;

public function arrayContainWholeDimension
  "Checks if a list of dimensions contain a wholedim, i.e. NONE."
  input DAE.Dimensions inDim;
  output Boolean wholedim;
algorithm
  wholedim := match(inDim)
    local
      DAE.Dimensions rest_dims;
    case (DAE.DIM_UNKNOWN() :: _) then true;
    case (_ :: rest_dims) then arrayContainWholeDimension(rest_dims);
    else false;
  end match;
end arrayContainWholeDimension;

public function isArrayType
"Returns true if inType is an T_ARRAY"
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match inType
    case DAE.T_ARRAY() then true;
    else false;
  end match;
end isArrayType;

public function isRecordType
  "Return true if the type is a record type."
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match(inType)
    case DAE.T_COMPLEX(complexClassType = ClassInf.RECORD()) then true;
    else false;
  end match;
end isRecordType;

public function isNotComplex "returns true if the exp is 1-dimensional"
  input DAE.Exp e;
  output Boolean b;
algorithm
  b := match(e)
    local
      Boolean b2;
      DAE.Exp e2;
    case(DAE.CALL())
      then
        false;
    case(DAE.RECORD())
      then
        false;
    case(DAE.ARRAY())
      then
        false;
    case(DAE.CAST(exp=e2))
      equation
        b2 = isNotComplex(e2);
      then b2;
    else
      true;
  end match;
end isNotComplex;

public function isRealType
 "Return true if the type is Real."
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match(inType)
    case (DAE.T_REAL()) then true;
    else false;
  end match;
end isRealType;

public function dimensionsEqual
  "Returns whether two dimensions are equal or not."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := match(dim1, dim2)
    local Boolean b;
    case (DAE.DIM_UNKNOWN(), _) then true;
    case (_, DAE.DIM_UNKNOWN()) then true;
    case (DAE.DIM_EXP(), _) then true;
    case (_, DAE.DIM_EXP()) then true;

    else
      equation
        b = intEq(dimensionSize(dim1), dimensionSize(dim2));
      then
        b;
  end match;
end dimensionsEqual;

public function dimsEqual
  "Returns whether two dimensions are equal or not."
  input DAE.Dimensions dims1;
  input DAE.Dimensions dims2;
  output Boolean res;
algorithm
  res := match(dims1, dims2)
    local
      DAE.Dimension d1, d2;
      DAE.Dimensions dl1, dl2;

    case ({}, {}) then true;
    case (d1::dl1, d2::dl2) guard dimensionsEqual(d1, d2)
      then
        dimsEqual(dl1, dl2);
    else false;
  end match;
end dimsEqual;

public function dimsEqualAllowZero
"Returns whether two dimensions are equal or not.
 0 == anydim is allowed"
  input DAE.Dimensions dims1;
  input DAE.Dimensions dims2;
  output Boolean res;
algorithm
  res := match(dims1, dims2)
    local
      DAE.Dimension d1, d2;
      DAE.Dimensions dl1, dl2;

    case ({}, {}) then true;
    case (d1::dl1, d2::dl2) guard dimensionsEqualAllowZero(d1, d2)
      then
        dimsEqualAllowZero(dl1, dl2);
    else false;
  end match;
end dimsEqualAllowZero;

public function dimensionsEqualAllowZero
"Returns whether two dimensions are equal or not.
 0 == anyDim is allowed"
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := match(dim1, dim2)
    local
      Boolean b;
      Integer d1, d2;

    case (DAE.DIM_UNKNOWN(), _) then true;
    case (_, DAE.DIM_UNKNOWN()) then true;
    case (DAE.DIM_EXP(), _) then true;
    case (_, DAE.DIM_EXP()) then true;

    else
      equation
        d1 = dimensionSize(dim1);
        d2 = dimensionSize(dim2);
        b = boolOr(
              intEq(d1, d2),
              boolOr(
                boolAnd(intEq(d1,0), intNe(d2,0)),
                boolAnd(intEq(d2,0), intNe(d1,0))));
      then
        b;
  end match;
end dimensionsEqualAllowZero;

public function dimensionsKnownAndEqual
  "Checks that two dimensions are specified and equal."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := match (dim1,dim2)
    case (DAE.DIM_UNKNOWN(),_) then false; // dimensionSizeExp fails on DIM_UNKNOWN...
    case (_,DAE.DIM_UNKNOWN()) then false;
    else expEqual(dimensionSizeExp(dim1), dimensionSizeExp(dim2));
  end match;
end dimensionsKnownAndEqual;

public function dimensionKnown
  "Checks whether a dimension is known or not."
  input DAE.Dimension dim;
  output Boolean known;
algorithm
  known := match(dim)
    case DAE.DIM_UNKNOWN() then false;
    case DAE.DIM_EXP(exp = DAE.ICONST()) then true;
    case DAE.DIM_EXP(exp = DAE.BCONST()) then true;
    case DAE.DIM_EXP(exp = DAE.ENUM_LITERAL()) then true;
    case DAE.DIM_EXP() then false;
    else true;
  end match;
end dimensionKnown;

public function dimensionKnownAndNonZero
  "Checks whether a dimensions is known or not."
  input DAE.Dimension dim;
  output Boolean known;
algorithm
  known := match(dim)
    case DAE.DIM_EXP(exp = DAE.ICONST(0)) then false;
    case DAE.DIM_INTEGER(0) then false;
    else dimensionKnown(dim);
  end match;
end dimensionKnownAndNonZero;

public function dimensionsKnownAndNonZero
  "Checks whether all dimensions are known or not."
  input list<DAE.Dimension> dims;
  output Boolean allKnown;
algorithm
  allKnown := List.mapBoolAnd(dims, dimensionKnownAndNonZero);
end dimensionsKnownAndNonZero;

public function dimensionUnknownOrExp
  "Checks whether a dimensions is known or not."
  input DAE.Dimension dim;
  output Boolean known;
algorithm
  known := match(dim)
    case DAE.DIM_UNKNOWN() then true;
    case DAE.DIM_EXP() then true;
    else false;
  end match;
end dimensionUnknownOrExp;

public function dimensionUnknown
  input DAE.Dimension inDimension;
  output Boolean outUnknown;
algorithm
  outUnknown := match(inDimension)
    case DAE.DIM_UNKNOWN() then true;
    else false;
  end match;
end dimensionUnknown;

public function hasUnknownDims
  input list<DAE.Dimension> dims;
  output Boolean hasUnkown;
algorithm
  hasUnkown := List.mapBoolOr(dims, dimensionUnknown);
end hasUnknownDims;

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

public function subscriptConstants "
returns true if all subscripts are known (i.e no cref) constant values (no slice or wholedim)"
  input list<DAE.Subscript> inSubs;
  output Boolean areConstant = true;
algorithm
  for sub in inSubs loop
    areConstant := match(sub)
      case DAE.INDEX(exp = DAE.ICONST()) then true;
      case DAE.INDEX(exp = DAE.ENUM_LITERAL()) then true;
      case DAE.INDEX(exp = DAE.BCONST()) then true;
      else false;
    end match;

    if not areConstant then return; end if;
  end for;
end subscriptConstants;

public function isValidSubscript
  "Checks if an expression is a valid subscript, i.e. an integer or enumeration
  literal."
  input DAE.Exp inSub;
  output Boolean isValid;
algorithm
  isValid := match(inSub)
    case DAE.ICONST() then true;
    case DAE.ENUM_LITERAL() then true;
    case DAE.BCONST() then true;
    else false;
  end match;
end isValidSubscript;

public function subscriptContain "This function checks whether sub2 contains sub1 or not(DAE.WHOLEDIM())"
  input list<DAE.Subscript> issl1;
  input list<DAE.Subscript> issl2;
  output Boolean contained;
algorithm
  contained := match(issl1,issl2)
    local
      Boolean b;
      Subscript ss1,ss2;
      list<DAE.Subscript> ssl1,ssl2;
      DAE.Exp e1,e2;
      Integer i;
      list<DAE.Exp> expl;

    case({},_) then true;

    case(_ ::ssl1, (DAE.WHOLEDIM())::ssl2)
      equation
        b = subscriptContain(ssl1,ssl2);
      then b;

    // Should there be additional checking in this case?
    case(_ ::ssl1, (DAE.WHOLE_NONEXP(_))::ssl2)
      equation
        b = subscriptContain(ssl1,ssl2);
      then b;
/*    case(ss1::ssl1, (ss2 as DAE.SLICE(exp)) ::ssl2)
      local DAE.Exp exp;
        equation
         b = subscriptContain(ssl1,ssl2);
        then
          b;
          */
    case((DAE.INDEX(DAE.ICONST(i)))::ssl1, (DAE.SLICE(DAE.ARRAY(_,_,expl))) ::ssl2)
      equation
        true = subscriptContain2(i,expl);
        b = subscriptContain(ssl1,ssl2);
      then
        b;

    case(ss1::ssl1,ss2::ssl2)
      equation
        true = subscriptEqual({ss1},{ss2});
        b = subscriptContain(ssl1,ssl2);
      then
        b;
    else false;
  end match;
end subscriptContain;

protected function subscriptContain2 "
"
  input Integer inInt;
  input list<DAE.Exp> inExp2;
  output Boolean contained;
algorithm
  contained := match(inInt,inExp2)
    local
      Boolean b,b2;
      DAE.Exp e1,e2;
      list<DAE.Exp> expl,expl2;
      Integer i,j;
      case(i,( (DAE.ICONST(j)) :: _)) guard (i == j)
          then
            true;
      case(i,(( DAE.ICONST(_)) :: expl)) guard subscriptContain2(i,expl)
          then
            true;
      case(i,( (DAE.ARRAY(_,_,expl2)) :: expl))
        equation
          b = subscriptContain2(i,expl2);
          b2 = if b then true else subscriptContain2(i,expl);
        then
          b2;
      else false;
  end match;
end subscriptContain2;

public function hasNoSideEffects
  "Returns true if the expression is free from side-effects. Use with traverseExpBottomUp."
  input DAE.Exp inExp;
  input Boolean ib;
  output DAE.Exp outExp;
  output Boolean ob;
algorithm
  (outExp,ob) := match (inExp,ib)
    local
      DAE.Exp e;
    case (DAE.CALL(),_) then (inExp,false);
    case (DAE.MATCHEXPRESSION(),_) then (inExp,false);
    else (inExp,ib);
  end match;
end hasNoSideEffects;

public function isBuiltinFunctionReference
  "Returns true if the expression is a reference to a builtin function"
  input DAE.Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=true)) then true;
    else false;
  end match;
end isBuiltinFunctionReference;

public function makeCons "DAE.CONS"
  input DAE.Exp car;
  input DAE.Exp cdr;
  output DAE.Exp exp;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  exp := DAE.CONS(car,cdr);
end makeCons;

public function makeBuiltinCall
  "Create a DAE.CALL with the given data for a call to a builtin function."
  input String name;
  input list<DAE.Exp> args;
  input DAE.Type result_type;
  input Boolean isImpure;
  output DAE.Exp call;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  call := DAE.CALL(Absyn.IDENT(name),args,DAE.CALL_ATTR(result_type,false,true,isImpure,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
end makeBuiltinCall;

public function makePureBuiltinCall
  "Create a DAE.CALL with the given data for a call to a builtin function."
  input String name;
  input list<DAE.Exp> args;
  input DAE.Type result_type;
  output DAE.Exp call;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  call := makeBuiltinCall(name, args, result_type, false);
end makePureBuiltinCall;

public function makeImpureBuiltinCall
  "Create a DAE.CALL with the given data for a call to a builtin function."
  input String name;
  input list<DAE.Exp> args;
  input DAE.Type result_type;
  output DAE.Exp call;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  call := makeBuiltinCall(name, args, result_type, true);
end makeImpureBuiltinCall;

public function reductionIterName
  input DAE.ReductionIterator iter;
  output String name;
algorithm
  DAE.REDUCTIONITER(id=name) := iter;
end reductionIterName;

protected function traverseReductionIteratorBidir<ArgT>
  input DAE.ReductionIterator inIter;
  input FuncType inEnterFunc;
  input FuncType inExitFunc;
  input ArgT inArg;
  output DAE.ReductionIterator outIter;
  output ArgT outArg;

  partial function FuncType
    input DAE.Exp inExp;
    input ArgT inArg;
    output DAE.Exp outExp;
    output ArgT outArg;
  end FuncType;
algorithm
  (outIter, outArg) := match(inIter)
    local
      String id;
      DAE.Exp exp;
      Option<DAE.Exp> gexp;
      DAE.Type ty;
      ArgT arg;

    case DAE.REDUCTIONITER(id, exp, gexp, ty)
      equation
        (exp, arg) = traverseExpBidir(exp, inEnterFunc, inExitFunc, inArg);
        (gexp, arg) = traverseExpOptBidir(gexp, inEnterFunc, inExitFunc, arg);
      then
        (DAE.REDUCTIONITER(id, exp, gexp, ty), arg);

  end match;
end traverseReductionIteratorBidir;

protected function traverseReductionIteratorTopDown
  input DAE.ReductionIterator iter;
  input FuncExpType func;
  input Type_a inArg;
  output DAE.ReductionIterator outIter;
  output Type_a outArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outA;
  end FuncExpType;

  replaceable type Type_a subtypeof Any;
algorithm
  (outIter,outArg) := match (iter,func,inArg)
    local
      String id;
      DAE.Exp exp;
      Option<DAE.Exp> gexp;
      DAE.Type ty;
      Type_a arg;
    case (DAE.REDUCTIONITER(id,exp,gexp,ty),_,arg)
      equation
        (exp, arg) = traverseExpTopDown(exp, func, arg);
        (gexp, arg) = traverseExpOptTopDown(gexp, func, arg);
      then (DAE.REDUCTIONITER(id,exp,gexp,ty),arg);
  end match;
end traverseReductionIteratorTopDown;

protected function traverseReductionIteratorsTopDown
  input DAE.ReductionIterators inIters;
  input FuncExpType func;
  input Type_a inArg;
  output DAE.ReductionIterators outIters;
  output Type_a outArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Boolean cont;
    output Type_a outA;
  end FuncExpType;

  replaceable type Type_a subtypeof Any;
algorithm
  (outIters,outArg) := match (inIters,func,inArg)
    local
      Type_a arg;
      DAE.ReductionIterator iter;
      DAE.ReductionIterators iters;

    case ({},_,arg) then (inIters,arg);
    case (iter::iters,_,arg)
      equation
        (iter, arg) = traverseReductionIteratorTopDown(iter, func, arg);
        (iters, arg) = traverseReductionIteratorsTopDown(iters, func, arg);
      then (iter::iters,arg);
  end match;
end traverseReductionIteratorsTopDown;

protected function traverseReductionIterator
  input DAE.ReductionIterator iter;
  input FuncExpType func;
  input Type_a iarg;
  output DAE.ReductionIterator outIter;
  output Type_a outArg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outIter,outArg) := match (iter,func,iarg)
    local
      String id;
      DAE.Exp exp,exp1;
      Option<DAE.Exp> gexp,gexp1;
      DAE.Type ty;
      Type_a arg;

    case (DAE.REDUCTIONITER(id,exp,gexp,ty),_,arg)
      equation
        (exp1, arg) = traverseExpBottomUp(exp, func, arg);
        (gexp1, arg) = traverseExpOpt(gexp, func, arg);
        outIter = if referenceEq(exp,exp1) and referenceEq(gexp,gexp1) then iter else DAE.REDUCTIONITER(id,exp1,gexp1,ty);
      then (outIter, arg);
  end match;
end traverseReductionIterator;

protected function traverseReductionIterators
  input output DAE.ReductionIterators iters;
  input FuncExpType func;
  input output Type_a arg;

  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (iters,arg) := match iters
    local
      DAE.ReductionIterator iter,iter1;
      DAE.ReductionIterators rest,iters1;

    case {} then (iters,arg);
    case iter::rest
      equation
        (iter1, arg) = traverseReductionIterator(iter, func, arg);
        (iters1, arg) = traverseReductionIterators(rest, func, arg);
        iters = if referenceEq(iter,iter1) and referenceEq(rest,iters1) then iters else (iter1::iters1);
      then (iters, arg);
  end match;
end traverseReductionIterators;

public function simpleCrefName
  input DAE.Exp exp;
  output String name;
algorithm
  DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name,subscriptLst={})) := exp;
end simpleCrefName;

public function isTailCall
  input DAE.Exp exp;
  output Boolean isTail;
algorithm
  isTail := match exp
    case DAE.CALL(attr=DAE.CALL_ATTR(tailCall=DAE.TAIL())) then true;
    else false;
  end match;
end isTailCall;

public function complexityTraverse
  input DAE.Exp exp;
  input Integer complexity;
  output DAE.Exp outExp;
  output Integer outComplexity;
algorithm
  (outExp,outComplexity) := traverseExpBottomUp(exp,complexityTraverse2,complexity);
end complexityTraverse;

protected function complexityTraverse2
  input DAE.Exp exp;
  input Integer complexity_;
  output DAE.Exp outExp;
  output Integer outComplexity;
algorithm
  outComplexity := complexity_ + complexity(exp);
  outExp := exp;
end complexityTraverse2;

protected constant Integer complexityAlloc = 5;
protected constant Integer complexityVeryBig = 500000 "Things that are too hard to calculate :(";
protected constant Integer complexityDimLarge = 1000 "Unknown dimensions usually aren't big, but might be";

public function complexity
  input DAE.Exp exp;
  output Integer i;
algorithm
  i := match exp
    local
      DAE.Operator op;
      DAE.Exp e,e1,e2,e3;
      Integer c1,c2,c3;
      list<DAE.Exp> exps;
      list<list<DAE.Exp>> matrix;
      String str,name;
      DAE.Type tp;
    case DAE.ICONST() then 0;
    case DAE.RCONST() then 0;
    case DAE.SCONST() then 0;
    case DAE.BCONST() then 0;
    case DAE.SHARED_LITERAL() then 0;
    case DAE.ENUM_LITERAL() then 0;
    case DAE.CREF(ty=tp) then tpComplexity(tp);
    case DAE.BINARY(exp1=e1,operator=op,exp2=e2)
      equation
        c1 = complexity(e1);
        c2 = complexity(e2);
        c3 = opComplexity(op);
      then c1+c2+c3;
    case DAE.UNARY(exp=e,operator=op)
      equation
        c1 = complexity(e);
        c2 = opComplexity(op);
      then c1+c2;
    case DAE.LBINARY(exp1=e1,exp2=e2,operator=op)
      equation
        c1 = complexity(e1);
        c2 = complexity(e2);
        c3 = opComplexity(op);
      then c1+c2+c3;
    case DAE.LUNARY(exp=e,operator=op)
      equation
        c1 = complexity(e);
        c2 = opComplexity(op);
      then c1+c2;
    case DAE.RELATION(exp1=e1,exp2=e2,operator=op)
      equation
        c1 = complexity(e1);
        c2 = complexity(e2);
        c3 = opComplexity(op);
      then c1+c2+c3;
    case DAE.IFEXP(expCond=e1,expThen=e2,expElse=e3)
      equation
        c1 = complexity(e1);
        c2 = complexity(e2);
        c3 = complexity(e3);
      then c1+intMax(c2,c3);
    case DAE.CALL(path=Absyn.IDENT(name),expLst=exps,attr=DAE.CALL_ATTR(ty=tp,builtin=true))
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,0);
        c2 = complexityBuiltin(name,tp);
        /* TODO: Cost is based on type and size of inputs. Maybe even name for builtins :) */
      then c1+c2;
    case DAE.CALL(expLst=exps)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,0);
        c2 = listLength(exps);
        /* TODO: Cost is based on type and size of inputs. Maybe even name for builtins :) */
      then c1+c2+25;
    case DAE.RECORD(exps=exps)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,1);
      then c1;
    case DAE.PARTEVALFUNCTION()
      then complexityVeryBig; /* This should not be here anyway :) */
    case DAE.ARRAY(array=exps,ty=tp)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,if isArrayType(tp) then 0 else complexityAlloc);
        c2 = listLength(exps);
      then c1+c2;
    case DAE.MATRIX(matrix=matrix as (exps::_))
      equation
        c1 = List.applyAndFold(List.flatten(matrix),intAdd,complexity,complexityAlloc);
        c2 = listLength(exps)*listLength(matrix);
      then c1 + c2;
    case DAE.RANGE(start=e1,stop=e2,step=NONE())
      then complexityDimLarge+complexity(e1)+complexity(e2); /* TODO: Check type maybe? */
    case DAE.RANGE(start=e1,stop=e2,step=SOME(e3))
      then complexityDimLarge+complexity(e1)+complexity(e2)+complexity(e3); /* TODO: Check type maybe? */
    case DAE.TUPLE(PR=exps)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,complexityAlloc);
        c2 = listLength(exps);
      then c1+c2;
    case DAE.CAST(exp=e,ty=tp) then tpComplexity(tp)+complexity(e);
    case DAE.ASUB(exp=e,sub=exps)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,complexityAlloc);
        c2 = listLength(exps);
        c3 = complexity(e);
      then c1+c2+c3;
    case DAE.TSUB(exp=e) then complexity(e)+1;
    case DAE.SIZE(exp=e,sz=NONE()) then complexity(e)+complexityAlloc+10; /* TODO: Cost is based on type (creating the array) */
    case DAE.SIZE(exp=e1,sz=SOME(e2)) then complexity(e1)+complexity(e2)+1;
    case DAE.CODE() then complexityVeryBig;
    case DAE.EMPTY() then complexityVeryBig;
    case DAE.REDUCTION() then complexityVeryBig; /* TODO: We need a real traversal... */
    case DAE.LIST(valList=exps)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,complexityAlloc);
        c2 = listLength(exps);
      then c1+c2+complexityAlloc;
    case DAE.CONS(car=e1,cdr=e2)
      then complexityAlloc+complexity(e1)+complexity(e2);
    case DAE.META_TUPLE(listExp=exps)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,complexityAlloc);
        c2 = listLength(exps);
      then complexityAlloc+c1+c2;
    case DAE.META_OPTION(exp=NONE()) then 0;
    case DAE.META_OPTION(exp=SOME(e)) then complexity(e)+complexityAlloc;
    case DAE.METARECORDCALL(args=exps)
      equation
        c1 = List.applyAndFold(exps,intAdd,complexity,complexityAlloc);
        c2 = listLength(exps);
      then c1+c2+complexityAlloc;
    case DAE.MATCHEXPRESSION() then complexityVeryBig;
    case DAE.BOX(exp=e) then complexityAlloc+complexity(e);
    case DAE.UNBOX(exp=e) then 1+complexity(e);
    case DAE.PATTERN() then 0;
    else
      equation
        str = "Expression.complexityWork failed: " + ExpressionDump.printExpStr(exp);
        Error.addMessage(Error.INTERNAL_ERROR,{str});
      then fail();
  end match;
end complexity;

protected function complexityBuiltin
  input String name;
  input DAE.Type tp;
  output Integer complexity;
algorithm
  complexity := match (name,tp)
    case ("identity",_) then complexityAlloc+tpComplexity(tp);
    case ("cross",_) then 3*3;
    else 25;
  end match;
end complexityBuiltin;

protected function tpComplexity
  input DAE.Type tp;
  output Integer i;
algorithm
  i := match tp
    local
      list<DAE.Dimension> dims;
    case DAE.T_ARRAY(dims=dims)
      equation
        i = List.applyAndFold(dims,intMul,dimComplexity,1);
      then i;
    else 0;
  end match;
end tpComplexity;

public function dimComplexity
  input DAE.Dimension dim;
  output Integer i;
algorithm
  i := match dim
    case DAE.DIM_INTEGER(integer=i) then i;
    case DAE.DIM_ENUM(size=i) then i;
    case DAE.DIM_BOOLEAN() then 2;
    else complexityDimLarge;
  end match;
end dimComplexity;

protected function opComplexity
  input DAE.Operator op;
  output Integer i;
algorithm
  i := match op
    local
      DAE.Type tp;
    case DAE.ADD(ty=DAE.T_STRING()) then 100;
    case DAE.ADD() then 1;
    case DAE.SUB() then 1;
    case DAE.MUL() then 1;
    case DAE.DIV() then 1;
    case DAE.POW() then 30;
    case DAE.UMINUS() then 1;
      /* TODO: Array dims? */
    case DAE.UMINUS_ARR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.ADD_ARR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.SUB_ARR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.MUL_ARR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.DIV_ARR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.MUL_ARRAY_SCALAR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.ADD_ARRAY_SCALAR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.SUB_SCALAR_ARRAY(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.MUL_SCALAR_PRODUCT(ty=tp) then complexityAlloc+3*tpComplexity(tp);
    case DAE.MUL_MATRIX_PRODUCT(ty=tp) then complexityAlloc+3*tpComplexity(tp);
    case DAE.DIV_ARRAY_SCALAR(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.DIV_SCALAR_ARRAY(ty=tp) then complexityAlloc+tpComplexity(tp);
    case DAE.POW_ARRAY_SCALAR(ty=tp) then complexityAlloc+30*tpComplexity(tp);
    case DAE.POW_SCALAR_ARRAY(ty=tp) then complexityAlloc+30*tpComplexity(tp);
    case DAE.POW_ARR(ty=tp) then complexityAlloc+30*tpComplexity(tp);
    case DAE.POW_ARR2(ty=tp) then complexityAlloc+30*tpComplexity(tp);
    /* TODO: Array ops? */
    case DAE.AND() then 1;
    case DAE.OR() then 1;
    case DAE.NOT() then 1;
    case DAE.LESS() then 1;
    case DAE.LESSEQ() then 1;
    case DAE.GREATER() then 1;
    case DAE.GREATEREQ() then 1;
    case DAE.EQUAL() then 1;
    case DAE.NEQUAL() then 1;
    case DAE.USERDEFINED() then 100;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Expression.opWCET failed"});
      then fail();
  end match;
end opComplexity;

public function makeEnumLiterals
  "Construct a list of enumeration literal expression given the type name of an
   enumeration an a list of literal names."
  input Absyn.Path inTypeName;
  input list<String> inLiterals;
  output list<DAE.Exp> outLiterals;
protected
  list<Absyn.Path> enum_lit_names;
  list<DAE.Exp> enum_lit_expl;
algorithm
  enum_lit_names := List.map1r(inLiterals, AbsynUtil.suffixPath, inTypeName);
  (outLiterals, _) := List.mapFold(enum_lit_names, makeEnumLiteral, 1);
end makeEnumLiterals;

protected function makeEnumLiteral
  "Creates a new enumeration literal. For use with listMapAndFold."
  input Absyn.Path name;
  input Integer index;
  output DAE.Exp enumExp;
  output Integer newIndex;
algorithm
  enumExp := DAE.ENUM_LITERAL(name, index);
  newIndex := index + 1;
end makeEnumLiteral;

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
      equation
        diff = Util.intCompare(priority(inOperand, inLhs),
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

public function isWild
  input DAE.Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case DAE.CREF(componentRef=DAE.WILD()) then true;
    else false;
  end match;
end isWild;

public function isNotWild
  input DAE.Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case DAE.CREF(componentRef=DAE.WILD()) then false;
    else true;
  end match;
end isNotWild;

public function dimensionsToExps "Takes a list of dimensions and select the expressions dimensions, returning a list of expressions"
  input list<DAE.Dimension> dims;
  output list<DAE.Exp> exps = {};
algorithm
  for d in dims loop
    exps := match (d)
      local
        DAE.Exp exp;
      case DAE.DIM_EXP(exp) then exp::exps;
      else exps;
    end match;
  end for;
  exps := listReverse(exps);
end dimensionsToExps;

public function splitRecord
  "Splits a record into its elements. Works for crefs, records constructor calls, and casts of the same"
  input DAE.Exp inExp;
  input DAE.Type ty;
  output list<DAE.Exp> outExps;
algorithm
  outExps := match (inExp,ty)
    local
      DAE.Exp exp;
      list<DAE.Var> vs;
      DAE.ComponentRef cr;
      Absyn.Path p1,p2;
      list<DAE.Exp> exps;
    case (DAE.CAST(exp=exp),_) then splitRecord(exp,ty);
     case (DAE.CREF(),DAE.T_COMPLEX(complexClassType=ClassInf.EXTERNAL_OBJ(), varLst = {}))
       //Don't split External objects
      then fail();
    case (DAE.CREF(componentRef=cr),DAE.T_COMPLEX(varLst = vs))
      then List.map1(vs,splitRecord2,cr);
    case (DAE.CALL(path=p1,expLst=exps,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(p2)))),_)
      equation
        true = AbsynUtil.pathEqual(p1,p2) "is record constructor";
      then exps;
    case (DAE.RECORD(exps=exps),_)
      then exps;
  end match;
end splitRecord;

protected function splitRecord2
  input DAE.Var var;
  input DAE.ComponentRef cr;
  output DAE.Exp exp;
protected
  String n;
  DAE.Type tt,ty;
algorithm
  DAE.TYPES_VAR(name = n,ty = tt) := var;
  ty := Types.simplifyType(tt);
  exp := makeCrefExp(ComponentReference.crefPrependIdent(cr, n, {}, ty), ty);
end splitRecord2;

public function splitArray
  "Splits an array into a list of elements."
  input DAE.Exp inExp;
  output list<DAE.Exp> outExp;
  output Boolean didSplit;
algorithm
  (outExp,didSplit) := match(inExp)
    local
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mat;
      Integer istart, istop, istep;
      Option<DAE.Exp> step;

    case DAE.ARRAY(array = expl) then (expl,true);
    case DAE.MATRIX(matrix = mat) then (List.flatten(mat),true);
    case DAE.RANGE(start = DAE.ICONST(istart), step = step, stop = DAE.ICONST(istop))
      then (list(DAE.ICONST(i) for i in ExpressionSimplify.simplifyRange(istart,match step case NONE() then 1; case SOME(DAE.ICONST(istep)) then istep; end match,istop)),true);
    else ({inExp},false);
  end match;
end splitArray;

public function equationExpEqual
  input DAE.EquationExp exp1;
  input DAE.EquationExp exp2;
  output Boolean b;
algorithm
  b := match (exp1,exp2)
    local
      DAE.Exp e1,e2,e3,e4;
    case (DAE.PARTIAL_EQUATION(e1),DAE.PARTIAL_EQUATION(e2)) then expEqual(e1,e2);
    case (DAE.RESIDUAL_EXP(e1),DAE.RESIDUAL_EXP(e2)) then expEqual(e1,e2);
    case (DAE.EQUALITY_EXPS(e1,e2),DAE.EQUALITY_EXPS(e3,e4)) then expEqual(e1,e3) and expEqual(e2,e4);
    else false;
  end match;
end equationExpEqual;

public function promoteExp
  "This function corresponds to the promote function described in the Modelica
   spec. It takes an expression, the type of the expression and a number of
   dimensions, and adds dimensions of size 1 to the right of the expression
   until the expression has as many dimensions as given. It also returns the
   type of the promoted expression. E.g.:

     promoteExp({1, 2, 3}, Integer[3], 3) =>
        ({{{1}}, {{2}}, {{3}}}, Integer[3,1,1])

   The reason why this function takes a type instead of using the type of the
   expression is because it's used by Static.promoteExp, which already knows the
   type."
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Integer inDims;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp, outType) := matchcontinue(inExp, inType, inDims)
    local
      Integer dims_to_add;
      DAE.Type ty, res_ty;
      DAE.Exp exp;
      list<DAE.Type> tys;
      list<DAE.Dimension> dims, added_dims;
      Boolean is_array_ty;

    case (_, _, _)
      equation
        // Figure out how many dimensions we need to add.
        dims_to_add = inDims - Types.numberOfDimensions(inType);
        // If the expression already has at least as many dimensions as we want,
        // fail and return the unchanged expression.
        true = dims_to_add > 0;

        // Construct all the types we will need here, to avoid having to
        // construct new types for all the subexpressions created.

        // Add as many dimensions of size 1 as needed.
        added_dims = List.fill(DAE.DIM_INTEGER(1), dims_to_add);
        // Append the dimensions from the type and the added dimensions.
        dims = listAppend(Types.getDimensions(inType), added_dims);
        // Construct the result type.
        ty = Types.arrayElementType(inType);
        res_ty = Types.liftArrayListDims(ty, dims);
        // Construct the expression types.
        ty = Types.simplifyType(ty);
        tys = makePromotedTypes(dims, ty, {});

        // Use the constructed types to promote the expression.
        is_array_ty = Types.isArray(inType);
        exp = promoteExp2(inExp, is_array_ty, inDims, tys);
      then
        (exp, res_ty);

    else (inExp, inType);

  end matchcontinue;
end promoteExp;

protected function makePromotedTypes
  "Creates a lift of types given a list of dimensions and an element type. The
   types are created by removing the head of the dimension list one by one and
   creating types from the remaining dimensions. E.g.:

     makePromotedTypes({[2], [3], [1]}, Real) =>
        {Real[2,3,1], Real[3,1], Real[1]}
   "
  input list<DAE.Dimension> inDimensions;
  input DAE.Type inElementType;
  input list<DAE.Type> inAccumTypes;
  output list<DAE.Type> outAccumTypes;
algorithm
  outAccumTypes := match(inDimensions, inElementType, inAccumTypes)
    local
      list<DAE.Dimension> rest_dims;
      DAE.Type ty;

    case (_ :: rest_dims, _, _)
      equation
        ty = DAE.T_ARRAY(inElementType, inDimensions);
      then
        makePromotedTypes(rest_dims, inElementType, ty :: inAccumTypes);

    case ({}, _, _) then listReverse(inAccumTypes);

  end match;
end makePromotedTypes;

protected function promoteExp2
  "Helper function to promoteExp."
  input DAE.Exp inExp;
  input Boolean inIsArray;
  input Integer inDims;
  input list<DAE.Type> inTypes;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inIsArray, inDims, inTypes)
    local
      DAE.Type ty;
      list<DAE.Exp> expl;
      list<DAE.Type> rest_ty;

    // No types left, we're done!
    case (_, _, _, {}) then inExp;

    // An array, promote each element in the array.
    case (DAE.ARRAY(_, _, expl), _, _, ty :: rest_ty)
      equation
        expl = List.map3(expl, promoteExp2, false, inDims, rest_ty);
      then
        DAE.ARRAY(ty, false, expl);

    // An expression with array type, but which is not an array expression. Such
    // an expression can't be promoted here, so we create a promote call instead.
    case (_, true, _, ty :: _)
      then makePureBuiltinCall("promote", {inExp, DAE.ICONST(inDims)}, ty);

    // Any other expression, call promoteExp3.
    else promoteExp3(inExp, inTypes);

  end match;
end promoteExp2;

protected function promoteExp3
  "Helper function to promoteExp2. Promotes a scalar expression as many times as
   the number of types given."
  input DAE.Exp inExp;
  input list<DAE.Type> inTypes;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inTypes)
    local
      DAE.Type ty;
      list<DAE.Type> rest_ty;
      DAE.Exp exp;

    // No types left, were' done!
    case (_, {}) then inExp;

    // Only one type left, create a scalar array with it.
    case (_, {ty}) then makeArray({inExp}, ty, true);

    // Several types left. Promote the expression using the rest of the types,
    // and then create an non-scalar array of the expression with the first type.
    case (_, ty :: rest_ty)
      equation
        exp = promoteExp3(inExp, rest_ty);
      then
        makeArray({exp}, ty, false);

  end match;
end promoteExp3;

public function hashExpMod "
author: PA
hash expression to value in range [0,mod-1]"
  input DAE.Exp e;
  input Integer mod;
  output Integer hash;
algorithm
  hash := intMod(intAbs(hashExp(e)),mod);
end hashExpMod;

public function hashExp "help function to hashExpMod"
  input DAE.Exp e;
  output Integer hash;
algorithm
 hash := matchcontinue(e)
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

 case(DAE.ICONST(i))                                then stringHashDjb2(intString(i));
 case(DAE.RCONST(r))                                then stringHashDjb2(realString(r));
 case(DAE.BCONST(b))                                then stringHashDjb2(boolString(b));
 case(DAE.SCONST(s))                                then stringHashDjb2(s);
 case(DAE.ENUM_LITERAL(name=path))                  then stringHashDjb2(AbsynUtil.pathString(path));
 case(DAE.CREF(componentRef=cr))                    then ComponentReference.hashComponentRef(cr);

 case(DAE.BINARY(e1,op,e2))                         then 1 + hashExp(e1)+hashOp(op)+hashExp(e2);
 case(DAE.UNARY(op,e1))                             then 2 + hashOp(op)+hashExp(e1);
 case(DAE.LBINARY(e1,op,e2))                        then 3 + hashExp(e1)+hashOp(op)+hashExp(e2);
 case(DAE.LUNARY(op,e1))                            then 4 + hashOp(op)+hashExp(e1);
 case(DAE.RELATION(e1,op,e2,_,_))                   then 5 + hashExp(e1)+hashOp(op)+hashExp(e2);
 case(DAE.IFEXP(e1,e2,e3))                          then 6 + hashExp(e1)+hashExp(e2)+hashExp(e3);
 case(DAE.CALL(path=path,expLst=expl))              then 7 + stringHashDjb2(AbsynUtil.pathString(path))+List.reduce(List.map(expl,hashExp),intAdd);
 case(DAE.RECORD(path=path,exps=expl))            then 8 + stringHashDjb2(AbsynUtil.pathString(path))+List.reduce(List.map(expl,hashExp),intAdd);
 case(DAE.PARTEVALFUNCTION(path=path,expList=expl)) then 9 + stringHashDjb2(AbsynUtil.pathString(path))+List.reduce(List.map(expl,hashExp),intAdd);
 case(DAE.ARRAY(array=expl))                        then 10 + List.reduce(List.map(expl,hashExp),intAdd);
 case(DAE.MATRIX(matrix=mexpl))                     then 11 + List.reduce(List.map(List.flatten(mexpl),hashExp),intAdd);
 case(DAE.RANGE(_,e1,SOME(e2),e3))                  then 12 + hashExp(e1)+hashExp(e2)+hashExp(e3);
 case(DAE.RANGE(_,e1,NONE(),e3))                    then 13 + hashExp(e1)+hashExp(e3);
 case(DAE.TUPLE(expl))                              then 14 + List.reduce(List.map(expl,hashExp),intAdd);
 case(DAE.CAST(_,e1))                               then 15 + hashExp(e1);
 case(DAE.ASUB(e1,expl))                            then 16 + hashExp(e1)+List.reduce(List.map(expl,hashExp),intAdd);
 case(DAE.TSUB(e1,i,_))                             then 17 + hashExp(e1)+stringHashDjb2(intString(i));
 case(DAE.SIZE(e1,SOME(e2)))                        then 18 + hashExp(e1)+hashExp(e2);
 case(DAE.SIZE(e1,NONE()))                          then 19 + hashExp(e1);
 // case(DAE.CODE(_,_))                             then 20; // TODO: implement hashing of CODE AST
 // case(DAE.EMPTY(scope=_))                        then 21; // TODO: implement hashing of EMTPY (needed ?)
 case(DAE.REDUCTION(info,e1,iters))                 then 22 + hashReductionInfo(info)+hashExp(e1)+List.reduce(List.map(iters,hashReductionIter),intAdd);
 // TODO: hashing of all MetaModelica extensions
 else stringHashDjb2(ExpressionDump.printExpStr(e));
 end matchcontinue;
end hashExp;


protected function hashReductionInfo "help function to hashExp"
  input DAE.ReductionInfo info;
  output Integer hash;
algorithm
  hash := match(info)
  local
    Absyn.Path path;

    // TODO: complete hasing of all subexpressions
    case (DAE.REDUCTIONINFO(path=path)) then 22 + stringHashDjb2(AbsynUtil.pathString(path));
  end match;
end hashReductionInfo;

protected protected function hashReductionIter "help function to hashExp"
  input DAE.ReductionIterator iter;
  output Integer hash;
algorithm
  hash := match(iter)
  local
    String id;
    DAE.Exp e1,e2;


    case(DAE.REDUCTIONITER(id,e1,SOME(e2),_))       then 23 + stringHashDjb2(id)+hashExp(e1)+hashExp(e2);
    case(DAE.REDUCTIONITER(id,e1,NONE(),_))         then 24 + stringHashDjb2(id)+hashExp(e1);
  end match;

end hashReductionIter;
protected protected function hashOp "help function to hashExp"
  input DAE.Operator op;
  output Integer hash;
algorithm
  hash := match(op)
    local
      Absyn.Path path;

    case(DAE.ADD(_))                                    then 25;
    case(DAE.SUB(_))                                    then 26;
    case(DAE.MUL(_))                                    then 27;
    case(DAE.DIV(_))                                    then 28;
    case(DAE.POW(_))                                    then 29;
    case(DAE.UMINUS(_))                                 then 30;
    case(DAE.UMINUS_ARR(_))                             then 31;
    case(DAE.ADD_ARR(_))                                then 32;
    case(DAE.SUB_ARR(_))                                then 33;
    case(DAE.MUL_ARR(_))                                then 34;
    case(DAE.DIV_ARR(_))                                then 35;
    case(DAE.MUL_ARRAY_SCALAR(_))                       then 36;
    case(DAE.ADD_ARRAY_SCALAR(_))                       then 37;
    case(DAE.SUB_SCALAR_ARRAY(_))                       then 38;
    case(DAE.MUL_SCALAR_PRODUCT(_))                     then 39;
    case(DAE.MUL_MATRIX_PRODUCT(_))                     then 40;
    case(DAE.DIV_ARRAY_SCALAR(_))                       then 41;
    case(DAE.DIV_SCALAR_ARRAY(_))                       then 42;
    case(DAE.POW_ARRAY_SCALAR(_))                       then 43;
    case(DAE.POW_SCALAR_ARRAY(_))                       then 44;
    case(DAE.POW_ARR(_))                                then 45;
    case(DAE.POW_ARR2(_))                               then 46;
    case(DAE.AND(_))                                    then 47;
    case(DAE.OR(_))                                     then 48;
    case(DAE.NOT(_))                                    then 49;
    case(DAE.LESS(_))                                   then 50;
    case(DAE.LESSEQ(_))                                 then 51;
    case(DAE.GREATER(_))                                then 52;
    case(DAE.GREATEREQ(_))                              then 53;
    case(DAE.EQUAL(_))                                  then 54;
    case(DAE.NEQUAL(_))                                 then 55;
    case(DAE.USERDEFINED(path))                         then 56 + stringHashDjb2(AbsynUtil.pathString(path)) ;
    end match;
end hashOp;

public function matrixToArray
  input DAE.Exp inMatrix;
  output DAE.Exp outArray;
algorithm
  outArray := match(inMatrix)
    local
      DAE.Type ty, row_ty;
      list<list<Exp>> matrix;
      list<DAE.Exp> rows;

    case DAE.MATRIX(ty = ty, matrix = matrix)
      equation
        row_ty = unliftArray(ty);
        rows = List.map2(matrix, makeArray, row_ty, true);
      then
        DAE.ARRAY(ty, false, rows);

    else inMatrix;

  end match;
end matrixToArray;

public function transposeArray
  input DAE.Exp inArray;
  output DAE.Exp outArray;
  output Boolean outWasTransposed;
algorithm
  (outArray, outWasTransposed) := match(inArray)
    local
      DAE.Type ty, row_ty;
      DAE.Dimension dim1, dim2;
      DAE.Dimensions rest_dims;
      list<Exp> expl;
      list<list<Exp>> matrix;
      Integer i;

    // Empty array, just transpose the type.
    case DAE.ARRAY(DAE.T_ARRAY(ty, dim1 :: dim2 :: rest_dims), _, {})
      then (DAE.ARRAY(DAE.T_ARRAY(ty, dim2 :: dim1 :: rest_dims), false, {}), true);

    case DAE.ARRAY(DAE.T_ARRAY(ty, dim1 :: dim2 :: rest_dims), _, expl)
      equation
        row_ty = DAE.T_ARRAY(ty, dim1 :: rest_dims);
        matrix = List.map(expl, getArrayOrMatrixContents);
        matrix = List.transposeList(matrix);
        expl = List.map2(matrix, makeArray, row_ty, true);
      then
        (DAE.ARRAY(DAE.T_ARRAY(ty, dim2 :: dim1 :: rest_dims), false, expl), true);

    case DAE.MATRIX (matrix=matrix,ty=DAE.T_ARRAY(ty, {dim1, dim2}))
      equation
        matrix = List.transposeList(matrix);
        ty = DAE.T_ARRAY(ty, {dim2, dim1});
        i = listLength(matrix);
      then
        (DAE.MATRIX(ty,i,matrix), true);

    else (inArray, false);

  end match;
end transposeArray;

public function getCrefFromCrefOrAsub
  "Get the cref from an expression that might be ASUB. If so, return the base CREF (this function does *not* always return a CREF with the same type as the full expression)."
  input DAE.Exp exp;
  output DAE.ComponentRef cr;
algorithm
  cr := match exp
    case DAE.CREF(componentRef=cr) then cr;
    case DAE.ASUB(exp=DAE.CREF(componentRef=cr)) then cr;
  end match;
end getCrefFromCrefOrAsub;

public function arrayElements
  "Returns the array elements of an expression."
  input DAE.Exp inExp;
  output list<DAE.Exp> outExp;
algorithm
  outExp := match(inExp)
    local
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crl;
      list<list<DAE.Exp>> mat;

    case DAE.CREF(componentRef = cr)
      equation
        crl = ComponentReference.expandCref(cr, false);
        expl = List.map(crl, crefExp);
      then
        expl;

    case DAE.ARRAY(array = expl, ty = DAE.T_ARRAY())
      then List.mapFlat(expl, arrayElements);

    case DAE.ARRAY(array = expl) then expl;

    case DAE.MATRIX(matrix = mat) then List.flatten(mat);

    else {inExp};

  end match;
end arrayElements;

public function arrayContent
  "Returns the contents of an array expression, i.e. a list of expressions."
  input DAE.Exp inExp;
  output list<DAE.Exp> outContent;
algorithm
  DAE.ARRAY(array = outContent) := inExp;
end arrayContent;

public function fromAbsynExp
"@author: adrpo
 transform Absyn.Exp into DAE.Exp, unknown types are used"
  input Absyn.Exp inAExp;
  output DAE.Exp outDExp;
algorithm
  outDExp := match(inAExp)
    local
      Integer i;
      Real r;
      Boolean b;
      String s;
      Absyn.Exp ae, ae1, ae2, cond;
      Absyn.Operator aop;
      Absyn.ComponentRef acr;
      list<Absyn.Exp> aexps;
      list<list<Absyn.Exp>> aexpslst;
      Absyn.FunctionArgs fargs;
      Absyn.Path p;
      Option<Absyn.Exp> aoe;
      DAE.ComponentRef cr;
      DAE.Exp e, e1, e2;
      DAE.Operator op;
      list<DAE.Exp> exps;
      list<list<DAE.Exp>> expslst;
      Option<DAE.Exp> oe;

    case (Absyn.INTEGER(i)) then DAE.ICONST(i);
    case (Absyn.REAL(s))
      equation
        r = System.stringReal(s);
      then DAE.RCONST(r);
    case (Absyn.BOOL(b)) then DAE.BCONST(b);
    case (Absyn.STRING(s)) then DAE.SCONST(s);

    case (Absyn.CREF(acr))
      equation
        cr = ComponentReference.toExpCref(acr);
        e = makeCrefExp(cr, DAE.T_UNKNOWN_DEFAULT);
      then
        e;

    case (Absyn.BINARY(ae1, aop, ae2))
      equation
        op = fromAbsynOperator(aop, DAE.T_UNKNOWN_DEFAULT);
        e1 = fromAbsynExp(ae1);
        e2 = fromAbsynExp(ae2);
        e = DAE.BINARY(e1, op, e2);
      then
        e;

    case (Absyn.UNARY(aop, ae))
      equation
        op = fromAbsynOperator(aop, DAE.T_UNKNOWN_DEFAULT);
        e = fromAbsynExp(ae);
        e = DAE.UNARY(op, e);
      then
        e;

    case (Absyn.LBINARY(ae1, aop, ae2))
      equation
        op = fromAbsynOperator(aop, DAE.T_UNKNOWN_DEFAULT);
        e1 = fromAbsynExp(ae1);
        e2 = fromAbsynExp(ae2);
        e = DAE.LBINARY(e1, op, e2);
      then
        e;

    case (Absyn.LUNARY(aop, ae))
      equation
        op = fromAbsynOperator(aop, DAE.T_UNKNOWN_DEFAULT);
        e = fromAbsynExp(ae);
        e = DAE.LUNARY(op, e);
      then
        e;

    case (Absyn.RELATION(ae1, aop, ae2))
      equation
        op = fromAbsynOperator(aop, DAE.T_UNKNOWN_DEFAULT);
        e1 = fromAbsynExp(ae1);
        e2 = fromAbsynExp(ae2);
        e = DAE.RELATION(e1, op, e2, 0, NONE());
      then
        e;

    case (ae as Absyn.IFEXP())
      equation
        Absyn.IFEXP(ifExp = cond, trueBranch = ae1, elseBranch = ae2) = AbsynUtil.canonIfExp(ae);
        e = fromAbsynExp(cond);
        e1 = fromAbsynExp(ae1);
        e2 = fromAbsynExp(ae2);
        e = DAE.IFEXP(e, e1, e2);
      then
        e;

    case (Absyn.CALL(acr, fargs))
      equation
        exps = fargsToExps(fargs);
        p = AbsynUtil.crefToPath(acr);
        e = DAE.CALL(p, exps, DAE.callAttrBuiltinOther);
      then
        e;

    case (Absyn.PARTEVALFUNCTION(acr, fargs))
      equation
        exps = fargsToExps(fargs);
        p = AbsynUtil.crefToPath(acr);
        e = DAE.PARTEVALFUNCTION(p, exps, DAE.T_UNKNOWN_DEFAULT, DAE.T_UNKNOWN_DEFAULT);
      then
        e;

    case (Absyn.ARRAY(aexps))
      equation
        exps = List.map(aexps, fromAbsynExp);
        e = DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT, false, exps);
      then
        e;

    case (Absyn.MATRIX(aexpslst))
      equation
        expslst = List.mapList(aexpslst, fromAbsynExp);
        i = listLength(listHead(expslst));
        e = DAE.MATRIX(DAE.T_UNKNOWN_DEFAULT, i, expslst);
      then
        e;

    case (Absyn.RANGE(ae1, aoe, ae2))
      equation
        e1 = fromAbsynExp(ae1);
        e2 = fromAbsynExp(ae2);
        oe = fromAbsynExpOpt(aoe);
        e = DAE.RANGE(DAE.T_UNKNOWN_DEFAULT, e1, oe, e2);
      then
        e;

    case (Absyn.TUPLE(aexps))
      equation
        exps = List.map(aexps, fromAbsynExp);
        e = DAE.TUPLE(exps);
      then
        e;

    else
    equation
      print("Expression.fromAbsynExp: Unhandled expression: " + Dump.printExpStr(inAExp) + "\n");
    then
      fail();

  end match;
end fromAbsynExp;

public function fargsToExps
  input Absyn.FunctionArgs inFargs;
  output list<DAE.Exp> outExps;
algorithm
  outExps := matchcontinue(inFargs)
    local
      list<DAE.Exp> exps;
      list<Absyn.NamedArg> nargs;
      list<Absyn.Exp> aexps;

    case (Absyn.FUNCTIONARGS(aexps, {}))
      equation
        exps = List.map(aexps, fromAbsynExp);
      then
        exps;

    case (Absyn.FUNCTIONARGS(_, _))
      equation
        print("Expression.fargsToExps: Named arguments are not handled!\n");
      then
        {};

  end matchcontinue;
end fargsToExps;

protected function fromAbsynExpOpt
  input Option<Absyn.Exp> aoe;
  output Option<DAE.Exp> oe;
algorithm
  oe := match(aoe)
    local
      Absyn.Exp ae;
      DAE.Exp e;

    case (NONE()) then NONE();

    case (SOME(ae))
      equation
        e = fromAbsynExp(ae);
      then
        SOME(e);

  end match;
end fromAbsynExpOpt;

protected function fromAbsynOperator
"@author: adrpo"
 input Absyn.Operator aop;
 input DAE.Type ty;
 output DAE.Operator op;
algorithm
  op := match(aop, ty)
    case(Absyn.ADD(), _) then DAE.ADD(ty);
    case(Absyn.SUB(), _) then DAE.SUB(ty);
    case(Absyn.MUL(), _) then DAE.MUL(ty);
    case(Absyn.DIV(), _) then DAE.DIV(ty);
    case(Absyn.POW(), _) then DAE.POW(ty);
    case(Absyn.UMINUS(), _) then DAE.UMINUS(ty);
    case(Absyn.AND(), _) then DAE.AND(ty);
    case(Absyn.OR(), _) then DAE.OR(ty);
    case(Absyn.NOT(), _) then DAE.NOT(ty);
    case(Absyn.LESS(), _) then DAE.LESS(ty);
    case(Absyn.LESSEQ(), _) then DAE.LESSEQ(ty);
    case(Absyn.GREATER(), _) then DAE.GREATER(ty);
    case(Absyn.GREATEREQ(), _) then DAE.GREATEREQ(ty);
    case(Absyn.EQUAL(), _) then DAE.EQUAL(ty);
    case(Absyn.NEQUAL(), _) then DAE.NEQUAL(ty);
    else
    equation
      print("Expression.fromAbsynOperator: Unhandled operator: " + Dump.opSymbol(aop) + "\n");
    then
      fail();
  end match;
end fromAbsynOperator;

public function replaceDerOpInExp
  "Replaces all der(cref) with $DER.cref in an expression."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  (outExp, _) := traverseExpBottomUp(inExp, replaceDerOpInExpTraverser, NONE());
end replaceDerOpInExp;

public function replaceDerOpInExpCond
  "Replaces der(cref) with $DER.cref in an expression, where the cref to replace
  is explicitly given."
  input DAE.Exp e;
  input Option<DAE.ComponentRef> cr;
  output DAE.Exp outExp;
  output Option<DAE.ComponentRef> outCr;
algorithm
  (outExp, outCr) := traverseExpBottomUp(e, replaceDerOpInExpTraverser, cr);
end replaceDerOpInExpCond;

public function replaceDerOpInExpTraverser
  "Used with Expression.traverseExpBottomUp to traverse an expression an replace calls to
  der(cref) with a component reference $DER.cref. If an optional component
  reference is supplied, then only that component reference is replaced.
  Otherwise all calls to der are replaced.

  This is done since some parts of the compiler can't handle der-calls, such as
  Derive.differentiateExpression. Ideally these parts should be fixed so that they can
  handle der-calls, but until that happens we just replace the der-calls with
  crefs."
  input DAE.Exp e;
  input Option<DAE.ComponentRef> optCr;
  output DAE.Exp outExp;
  output Option<DAE.ComponentRef> outCr;
algorithm
  (outExp,outCr) := matchcontinue (e,optCr)
    local
      DAE.ComponentRef cr, derCr;
      DAE.Exp cref_exp;
      DAE.ComponentRef cref;

    case (DAE.CALL(path = Absyn.IDENT("der"), expLst = {DAE.CREF(componentRef = cr)}), SOME(cref))
      equation
        derCr = ComponentReference.crefPrefixDer(cr);
        true = ComponentReference.crefEqualNoStringCompare(derCr, cref);
        cref_exp = crefExp(derCr);
      then (cref_exp, optCr);

    case (DAE.CALL(path = Absyn.IDENT("der"), expLst = {DAE.CREF(componentRef = cr)}), NONE())
      equation
        cr = ComponentReference.crefPrefixDer(cr);
        cref_exp = crefExp(cr);
      then (cref_exp, NONE());
    else (e,optCr);
  end matchcontinue;
end replaceDerOpInExpTraverser;

public function makeBinaryExp
  input DAE.Exp inLhs;
  input DAE.Operator inOp;
  input DAE.Exp inRhs;
  output DAE.Exp outExp;
algorithm
  outExp := DAE.BINARY(inLhs, inOp, inRhs);
end makeBinaryExp;

public function checkExpDimensionSizes
  "Extracts an integer from an exp"
  input DAE.Exp dim;
  output Boolean value;
algorithm
  value := match(dim)
    case DAE.ICONST() then dim.integer > 0;
    else
     false;
  end match;
end checkExpDimensionSizes;

public function checkDimensionSizes
 "Extracts an integer from an array dimension. Also handles DIM_EXP and
  DIM_UNKNOWN if checkModel is used."
  input DAE.Dimension  dim;
  output Boolean value;
algorithm
  value := match(dim)
    case DAE.DIM_INTEGER() then true;
    case DAE.DIM_ENUM() then true;
    case DAE.DIM_BOOLEAN() then true;
    case DAE.DIM_EXP() then true;
    case DAE.DIM_UNKNOWN() then false;
  end match;
end checkDimensionSizes;

public function dimensionsList
  "Extracts a list of integers from a list of array dimensions"
  input DAE.Dimensions inDims;
  output list<Integer> outValues;
protected
  list<Integer> dims;
algorithm
  outValues := matchcontinue(inDims)
    case (_)
      equation
        true = List.mapBoolAnd(inDims, checkDimensionSizes);
        dims = List.map(inDims, dimensionSizeAll);
      then dims;
    else {};
  end matchcontinue;
end dimensionsList;


public function expDimensionsList
  "Extracts a list of integers from a list of expressions"
  input list<DAE.Exp> inDims;
  output list<Integer> outValues;
protected
  list<Integer> dims;
algorithm
  outValues := matchcontinue(inDims)
    case (_)
      equation
        true = List.mapBoolAnd(inDims, checkExpDimensionSizes);
        dims = List.map(inDims, expInt);
        then dims;
    else {};
  end matchcontinue;
end expDimensionsList;

public function isCrefListWithEqualIdents
  "Checks if all expressions in the given list are crefs with the same identifiers.
    e.g.  {A[1],A[2],…,A[n]} -> true
          {A[1],B[1]} -> false"
  input list<DAE.Exp> iExpressions;
  output Boolean oCrefWithEqualIdents;
protected
  Boolean tmpCrefWithEqualIdents;
  list<Boolean> boolHelperList;
  list<DAE.ComponentRef> crefs;
  DAE.Exp head;
  DAE.ComponentRef headCref;
algorithm
  oCrefWithEqualIdents := matchcontinue(iExpressions)
    case(head::_)
      equation
        //print("isCrefListWithEqualIdents: \n" + stringDelimitList(List.map1(iExpressions, ExpressionDump.dumpExpStr, 1), ""));
        true = List.mapBoolAnd(iExpressions, isCref);
        //print("isCrefListWithEqualIdents: all crefs!\n");
        crefs = List.map(iExpressions, expCref);
        headCref = expCref(head);
        tmpCrefWithEqualIdents = List.map1BoolAnd(crefs, ComponentReference.crefEqualWithoutLastSubs, headCref);
        //print("isCrefListWithEqualIdents: returns " + boolString(tmpCrefWithEqualIdents) + "\n\n");
      then tmpCrefWithEqualIdents;
    case({})
      then true;
    else
      equation
        //print("isCrefListWithEqualIdents: returns false\n\n");
      then false;
  end matchcontinue;
end isCrefListWithEqualIdents;

/*
protected function traverseExpDerPreStart
" TODO: REPLACE THIS ABOMINATION WITH A BETTER traverseExpBottomUp

  Traverses all subexpressions of an expression.
  Takes a function and an extra argument passed through the traversal.
  The function can potentially change the expression. In such cases,
  the changes are made bottom-up, i.e. a subexpression is traversed
  and changed before the complete expression is traversed.

  NOTE: The user-provided function is not allowed to fail! If you want to
  detect a failure, return NONE() in your user-provided datatype.

  mahge : This function will not treat der(), pre() and start() as calls
  but as unique ids. i.e. x is different from der(x) and given der(x) x will not
  be extreacted as a unique id. Instead you get $DER.x. Same oes for pre and start.
"
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output DAE.Exp outExp;
  output Type_a outA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (outExp,outA) := match (inExp,func,inTypeA)
    local
      DAE.Exp e1_1,e,e1,e2_1,e2,e3_1,e3;
      Type_a ext_arg_1,ext_arg_2,ext_arg,ext_arg_3,ext_arg_4;
      Operator op;
      FuncExpType rel;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path fn;
      Boolean scalar;
      Type tp, t;
      Integer i;
      list<list<DAE.Exp>> lstexpl_1,lstexpl;
      Integer dim;
      String str;
      list<DAE.Element> localDecls;
      tuple<DAE.Exp,Type_a> res;
      list<String> fieldNames;
      DAE.CallAttributes attr;
      list<DAE.MatchCase> cases,cases_1;
      DAE.MatchType matchTy;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters,riters_1;
      DAE.ComponentRef cr,cr_1;
      list<list<String>> aliases;
      list<DAE.Type> typeVars;

    case ((e as DAE.EMPTY()),rel,ext_arg)
      equation
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case ((e as DAE.ICONST(_)),rel,ext_arg)
      equation
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case ((e as DAE.RCONST(_)),rel,ext_arg)
      equation
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case ((e as DAE.SCONST(_)),rel,ext_arg)
      equation
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case ((e as DAE.BCONST(_)),rel,ext_arg)
      equation
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case ((e as DAE.ENUM_LITERAL()),rel,ext_arg)
      equation
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.CREF(cr,tp),rel,ext_arg)
      equation
        (cr_1,ext_arg) = traverseExpCref(cr, rel, ext_arg);
        e = if referenceEq(cr,cr_1) then inExp else DAE.CREF(cr_1,tp);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    // unary
    case (DAE.UNARY(operator = op,exp = e1),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.UNARY(op,e1_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    // binary
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) then inExp else DAE.BINARY(e1_1,op,e2_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    // logical unary
    case (DAE.LUNARY(operator = op,exp = e1),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.LUNARY(op,e1_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    // logical binary
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) then inExp else DAE.LBINARY(e1_1,op,e2_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    // relation
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2, index=index_, optionExpisASUB= isExpisASUB),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) then inExp else DAE.RELATION(e1_1,op,e2_1,index_,isExpisASUB);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    // if expressions
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        (e3_1,ext_arg) = traverseExpDerPreStart(e3, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) and referenceEq(e3,e3_1) then inExp else DAE.IFEXP(e1_1,e2_1,e3_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.CALL(path = fn,expLst = expl,attr = attr),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.CALL(fn,expl_1,attr);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.RECORD(path = fn,exps = expl,comp = fieldNames, ty = tp),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.RECORD(fn,expl_1,fieldNames,tp);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.PARTEVALFUNCTION(fn, expl, tp, t),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.PARTEVALFUNCTION(fn,expl_1,tp,t);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.ARRAY(ty = tp,scalar = scalar,array = expl),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.ARRAY(tp,scalar,expl_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.MATRIX(ty = tp,integer = dim, matrix=lstexpl),rel,ext_arg)
      equation
        (lstexpl_1,ext_arg) = traverseExpMatrix(lstexpl, rel, ext_arg);
        e = if referenceEq(lstexpl,lstexpl_1) then inExp else DAE.MATRIX(tp,dim,lstexpl_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.RANGE(ty = tp,start = e1,step = NONE(),stop = e2),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) then inExp else DAE.RANGE(tp,e1_1,NONE(),e2_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.RANGE(ty = tp,start = e1,step = SOME(e2),stop = e3),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        (e3_1,ext_arg) = traverseExpDerPreStart(e3, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) and referenceEq(e3,e3_1) then inExp else DAE.RANGE(tp,e1_1,SOME(e2_1),e3_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.TUPLE(PR = expl),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.TUPLE(expl_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.CAST(ty = tp,exp = e1),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.CAST(tp,e1_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.ASUB(exp = e1,sub = expl),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(expl,expl_1) then inExp else makeASUB(e1_1,expl_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.TSUB(e1,i,tp),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.TSUB(e1_1,i,tp);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.SIZE(exp = e1,sz = NONE()),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.SIZE(e1_1,NONE());
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.SIZE(exp = e1,sz = SOME(e2)),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) then inExp else DAE.SIZE(e1_1,SOME(e2_1));
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.REDUCTION(reductionInfo=reductionInfo,expr = e1,iterators = riters),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (riters_1,ext_arg) = traverseReductionIterators(riters, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(riters,riters_1) then inExp else DAE.REDUCTION(reductionInfo,e1_1,riters_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    // MetaModelica list
    case (DAE.CONS(e1,e2),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        (e2_1,ext_arg) = traverseExpDerPreStart(e2, rel, ext_arg);
        e = if referenceEq(e1,e1_1) and referenceEq(e2,e2_1) then inExp else DAE.CONS(e1_1,e2_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.LIST(expl),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.LIST(expl_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.META_TUPLE(expl),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.META_TUPLE(expl_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.META_OPTION(NONE()),rel,ext_arg)
      equation
        (e,ext_arg) = rel(inExp,ext_arg);
      then (e,ext_arg);

    case (DAE.META_OPTION(SOME(e1)),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.META_OPTION(SOME(e1_1));
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.BOX(e1),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.BOX(e1_1);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.UNBOX(e1,tp),rel,ext_arg)
      equation
        (e1_1,ext_arg) = traverseExpDerPreStart(e1, rel, ext_arg);
        e = if referenceEq(e1,e1_1) then inExp else DAE.UNBOX(e1_1,tp);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.METARECORDCALL(fn,expl,fieldNames,i,typeVars),rel,ext_arg)
      equation
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        e = if referenceEq(expl,expl_1) then inExp else DAE.METARECORDCALL(fn,expl_1,fieldNames,i,typeVars);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);
    // ---------------------

    case (DAE.MATCHEXPRESSION(matchTy,expl,aliases,localDecls,cases,tp),rel,ext_arg)
      equation
        // Don't traverse the local declarations; we don't store bindings there (yet)
        (expl_1,ext_arg) = traverseExpDerPreStartList(expl, rel, ext_arg);
        (cases_1,ext_arg) = Patternm.traverseCases(cases,rel,ext_arg);
        e = if referenceEq(expl,expl_1) and referenceEq(cases,cases_1) then inExp else DAE.MATCHEXPRESSION(matchTy,expl_1,aliases,localDecls,cases_1,tp);
        (e,ext_arg) = rel(e,ext_arg);
      then (e,ext_arg);

    case (DAE.SHARED_LITERAL(),rel,ext_arg)
      equation
        (e,ext_arg) = rel(inExp,ext_arg);
      then (e,ext_arg);

    case (DAE.PATTERN(),rel,ext_arg)
      equation
        (e,ext_arg) = rel(inExp,ext_arg);
      then (e,ext_arg);

    // Why don't we call rel() for these expressions?
    case (DAE.CODE(),_,ext_arg) then (inExp,ext_arg);

    else
      equation
        str = ExpressionDump.printExpStr(inExp);
        str = "Expression.traverseExpDerPreStart or one of the user-defined functions using it is not implemented correctly: " + str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end traverseExpDerPreStart;

protected function traverseExpDerPreStartList
" TODO: REPLACE THIS ABOMINATION WITH A BETTER traverseExpBottomUp

  author mahge: Same as traverseExpList except:
  This function will not treat der(), pre() and start() as calls
  but as unique ids. i.e. x is different from der(x) and given der(x) x will not
  be extreacted as a unique id. Instead you get $DER.x. Same oes for pre and start.."

  replaceable type Type_a subtypeof Any;
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input Type_a iext_arg;
  output list<DAE.Exp> outExpl;
  output Type_a outA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  (outExpl,outA) := match(inExpl,rel,iext_arg)
    local
      DAE.Exp e,e1;
      list<DAE.Exp> expl,expl1;
      Type_a ext_arg;

    case ({},_,ext_arg) then (inExpl,ext_arg);

    case (e::expl,_,ext_arg)
      equation
        (e1,ext_arg) = traverseExpDerPreStart(e, rel, ext_arg);
        (expl1,ext_arg) = traverseExpDerPreStartList(expl,rel,ext_arg);
        expl = if referenceEq(e,e1) and referenceEq(expl,expl1) then inExpl else (e1::expl1);
      then (expl,ext_arg);
  end match;
end traverseExpDerPreStartList;
*/

public function renameExpCrefIdent
  input DAE.Exp inExp;
  input tuple<String,String> inTpl;
  output DAE.Exp outExp;
  output tuple<String,String> outTpl;
algorithm
  (outExp,outTpl) := match (inExp,inTpl)
    local
      DAE.Type ty1,ty2;
      String name,from,to;
      DAE.Exp exp;
    case (DAE.CREF(DAE.CREF_IDENT(name,ty1,{}),ty2),(from,to))
      equation
        exp = if stringEq(name,from) then DAE.CREF(DAE.CREF_IDENT(to,ty1,{}),ty2) else inExp;
      then (exp,inTpl);
    else (inExp,inTpl);
  end match;
end renameExpCrefIdent;

public function emptyToWild
  input DAE.Exp exp;
  output DAE.Exp outExp;
protected
  DAE.Type ty;
algorithm
  ty := typeof(exp);
  outExp := if Types.isZeroLengthArray(ty) then DAE.CREF(DAE.WILD(),ty) else exp;
end emptyToWild;

public function makeVectorCall
  input DAE.Exp exp;
  input DAE.Type tp;
  output DAE.Exp outExp;
algorithm
  outExp := makePureBuiltinCall("vector",{exp},tp);
end makeVectorCall;


public function expandCrefs
  input DAE.Exp inExp;
  input Boolean expandRecord;
  output DAE.Exp outExp;
  input output Integer dummy=0 "For traversal";
algorithm
  outExp := match inExp
    local
      DAE.Type elem_ty, arr_ty;
      list<DAE.Exp> exp_lst;
      DAE.Exp exp;
    case DAE.CREF(ty=arr_ty as DAE.T_ARRAY()) algorithm
        exp_lst := list(makeCrefExp(cr, arr_ty.ty) for cr in ComponentReference.expandCref(inExp.componentRef, expandRecord));
        exp := listToArray(exp_lst, arr_ty.dims);
      then exp;
    else inExp;
  end match;
end expandCrefs;

public function expandExpression
 " mahge:
   Expands a given expression to a list of expression. this means flattening any records in the
   expression and  vectorizing arrays.

   Currently can only handle crefs and array expressions. Maybe we need to handle binary operations at least.

   Right now this is used in generating simple residual equations from complex ones in SimCode.
 "

  input DAE.Exp inExp;
  input Boolean expandRecord;
  output list<DAE.Exp> outExps;
algorithm
  (outExps) := match (inExp)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<DAE.Exp> expl = {}, expl1, expl2;
      String msg;
      DAE.Exp e1, e2;
      DAE.Operator op;

    case (DAE.CREF(cr,_))
      algorithm
        crlst := ComponentReference.expandCref(cr, expandRecord);
        outExps := List.map(crlst, crefToExp);
      then outExps;

    case (DAE.UNARY(operator=DAE.UMINUS()))
      algorithm
        expl := list(DAE.UNARY(inExp.operator, exp) for exp in expandExpression(inExp.exp, expandRecord));
      then expl;

    case (DAE.BINARY())
      algorithm
        // TODO! FIXME! we should change the type in the operator,
        // i.e. use Types.unliftArray on the type inside the operator
        op := inExp.operator;
        expl1 := expandExpression(inExp.exp1, expandRecord);
        expl2 := expandExpression(inExp.exp2, expandRecord);
        // TODO! FIXME! maybe we should also support (array op scalar)
        // make sure the lists have the same length
        if listLength(expl1) <> listLength(expl2) then
          fail();
        end if;
        e1 := listGet(expl1, 1);
        e2 := listGet(expl1, 2);
        for i in 1:listLength(expl1) loop
          e1 := listGet(expl1, i);
          e2 := listGet(expl2, i);
          expl := DAE.BINARY(e1, op, e2)::expl;
        end for;
        expl := listReverse(expl);
      then expl;

    case DAE.ARRAY(_,_,expl)
      algorithm
        expl := List.mapFlat(expl, function expandExpression(expandRecord = expandRecord));
      then expl;

    else
     algorithm
        msg := "- Expression.expandExpression failed for " + ExpressionDump.printExpStr(inExp);
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end match;

end expandExpression;

public function extendArrExp "author: Frenkel TUD 2010-07
  alternative name: vectorizeExp"
  input DAE.Exp inExp;
  input Boolean inExpanded = false "True if something was expanded, otherwise false.";
  output DAE.Exp outExp;
  output Boolean outExpanded;
algorithm
  (outExp, outExpanded) := matchcontinue (inExp, inExpanded)
    local
      DAE.Exp exp;
      Boolean b;

    case (outExp, _)
      equation
        (exp, b) = traverseExpBottomUp(inExp, traversingextendArrExp, false);
      then
        (exp, b);

    else (inExp, inExpanded);

  end matchcontinue;
end extendArrExp;

protected function traversingextendArrExp "author: Frenkel TUD 2010-07.
  This function extend all array and record componentrefs to their
  elements. This is necessary for BLT and substitution of simple
  equations."
  input DAE.Exp inExp;
  input Boolean inExpanded;
  output DAE.Exp outExp;
  output Boolean outExpanded;
algorithm
  (outExp, outExpanded) := match(inExp)
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
      DAE.Dimension id, jd;
      Integer i, j;
      list<DAE.Exp> expl;
      DAE.Exp e;
      list<DAE.Var> varLst;
      Absyn.Path name;
      list<list<DAE.Exp>> mat;

    // CASE for Matrix
    case DAE.CREF(ty=ty as DAE.T_ARRAY(dims={id, jd}))
      equation
        i = dimensionSize(id);
        j = dimensionSize(jd);
        expl = expandExpression(inExp, expandRecord = false);
        mat = makeMatrix(expl, j);
        e = DAE.MATRIX(ty, i, mat);
      then
        (e, true);

    // CASE for Array
    case DAE.CREF(ty=ty as DAE.T_ARRAY())
      equation
        expl = expandExpression(inExp, expandRecord = false);
        e = DAE.ARRAY(ty, true, expl);
      then
        (e, true);

    // CASE for Records
    case DAE.CREF(componentRef=cr, ty=ty as DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(name)))
      equation
        expl = List.map1(varLst, generateCrefsExpFromExpVar, cr);
        i = listLength(expl);
        true = intGt(i, 0);
        e = DAE.CALL(name, expl, DAE.CALL_ATTR(ty, false, false, false, false, DAE.NO_INLINE(), DAE.NO_TAIL()));
        (e, _) = traverseExpBottomUp(e, traversingextendArrExp, true);
      then
        (e, true);

    else (inExp, inExpanded);

  end match;
end traversingextendArrExp;

protected function insertSubScripts"traverses the subscripts of the templSubScript and searches for wholedim. the value replaces the wholedim.
If there are multiple values, the templSubScript will be used for each of them and multiple new subScriptLsts are created.
author:Waurich TUD 2014-04"
  input list<DAE.Subscript> templSubScript;
  input list<list<DAE.Subscript>> value;
  input list<DAE.Subscript> lstIn;
  output list<list<DAE.Subscript>> outSubScript;
algorithm
  outSubScript := matchcontinue(templSubScript,value,lstIn)
    local
      Integer i;
      DAE.Subscript sub;
      list<DAE.Subscript> rest,lst,val;
      list<list<DAE.Subscript>> lsts;
    case(DAE.WHOLEDIM()::rest,_,_)
      equation
        // found a wholedim, replace with value, insert in lst
        lsts = List.map1(value,listAppend,lstIn);
        lsts = List.map1(lsts,List.append_reverser,rest);
      then
        lsts;
    case(DAE.INDEX()::rest,_,_)
      equation
        sub = listHead(templSubScript);
        lsts = insertSubScripts(rest,value,sub::lstIn);
      then
        lsts;
    else value;
  end matchcontinue;
end insertSubScripts;

protected function makeMatrix
  input list<DAE.Exp> expl;
  input Integer n;
  output list<list<DAE.Exp>> res;
protected
  list<DAE.Exp> col;
  Integer r;
  import listReverse = MetaModelica.Dangerous.listReverseInPlace;
algorithm
  res := {};
  col := {};
  r := n;
  for e in expl loop
    r := r-1;
    col := e::col;
    if r==0 then
      res := listReverse(col)::res;
      col := {};
      r := n;
    end if;
  end for;
  Error.assertionOrAddSourceMessage(listEmpty(col), Error.INTERNAL_ERROR, {"Expression.makeMatrix failed"}, sourceInfo());
  res := listReverse(res);
end makeMatrix;

public function rangesToSubscripts
  "This function takes a list of subscript ranges representing dimensions, e.g.
    {{1, 2, 3}, {1, 2}} which corresponds to dimensions [3, 2], and generates
    all subscript combinations, e.g. {{1, 1}, {1, 2}, {2, 1}, {2, 2}, {3, 1},
    {3, 2}}."
  input list<list<DAE.Subscript>> inRangelist;
  output list<list<DAE.Subscript>> outSubslst;
algorithm
  outSubslst := List.allCombinations(inRangelist, NONE(), AbsynUtil.dummyInfo);
end rangesToSubscripts;

public function expandSubscript
  "Expands a subscript into a list of subscripts. Also takes a dimension to be
   able to evaluate : subscripts."
  input DAE.Subscript inSubscript;
  input DAE.Dimension inDimension;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := match inSubscript
    local
      DAE.Exp exp;

    // An index subscript from range.
    case DAE.INDEX(exp = DAE.RANGE())
      then list(DAE.INDEX(e) for e in expandRange(inSubscript.exp));

    // An index subscript from array.
    // This really shouldn't be happening. But the backend creats things like this.
    // e.g. When finding Adjacency Matrix entry for for-loops in Algorithm sections.
    // That whole creating IM should be done the way checkModel works. but it's not. :( so
    // we have this.
    case DAE.INDEX(exp = DAE.ARRAY())
      then expandSliceExp(inSubscript.exp);

    // An index subscript, return it as an array.
    case DAE.INDEX() then {inSubscript};

    // A : subscript, use the dimension to generate all subscripts.
    case DAE.WHOLEDIM()
      then expandDimension(inDimension);

    // A slice subscript.
    case DAE.SLICE()
      then expandSliceExp(inSubscript.exp);

  end match;
end expandSubscript;

public function expandDimension
  "Generates a list of subscripts given an array dimension."
  input DAE.Dimension inDimension;
  output list<DAE.Subscript> outSubscript;
algorithm
  outSubscript := match(inDimension)
    local
      Integer dim_int;
      Absyn.Path enum_ty;
      list<String> enum_lits;
      list<DAE.Exp> enum_expl;

    // An integer dimension, generate a list of integer subscripts.
    case DAE.DIM_INTEGER(integer = dim_int)
      then dimensionSizeSubscripts(dim_int);

    // An enumeration dimension, construct all enumeration literals and make
    // subscript out of them.
    case DAE.DIM_ENUM(enumTypeName = enum_ty, literals = enum_lits)
      equation
        enum_expl = makeEnumLiterals(enum_ty, enum_lits);
      then
        List.map(enum_expl, makeIndexSubscript);

    case DAE.DIM_BOOLEAN()
      then DAE.INDEX(DAE.BCONST(false))::DAE.INDEX(DAE.BCONST(true))::{};

    else {};
  end match;
end expandDimension;

public function expandSliceExp
  "Expands a slice subscript expression."
  input DAE.Exp inSliceExp;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := match(inSliceExp)
    local
      list<DAE.Exp> expl;
      String exp_str, err_str;

    case DAE.ARRAY(array = expl)
      then List.map(expl, makeIndexSubscript);

    case DAE.RANGE()
      then List.map(Expression.expandRange(inSliceExp), makeIndexSubscript);

  end match;
end expandSliceExp;

public function dimensionSizesSubscripts
  input list<Integer> inDimSizes;
  output list<list<DAE.Subscript>> outSubscripts;
algorithm
  outSubscripts := List.map(inDimSizes, dimensionSizeSubscripts);
end dimensionSizesSubscripts;

public function dimensionSizesSubcriptsOpt
  input list<Option<Integer>> inDimSizes;
  output list<list<DAE.Subscript>> outSubscripts;
algorithm
  outSubscripts := List.mapOption(inDimSizes, dimensionSizeSubscripts);
end dimensionSizesSubcriptsOpt;

public function dimensionSizeSubscripts
  "Converts a dimension size in the form of an integer into a list of
   subscripts, e.g.: [3] => {1, 2, 3}."
  input Integer inDimSize;
  output list<DAE.Subscript> outSubscripts;
algorithm
  outSubscripts := list(DAE.INDEX(DAE.ICONST(i)) for i in 1:inDimSize);
end dimensionSizeSubscripts;

public function createResidualExp
"author: Frenkel TUD 2012-10
  do some numerical helpfull thinks like
  a = b/c - > a*c-b"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp resExp;
protected
  DAE.Exp iExp1, iExp2;
algorithm
  (iExp1,iExp2) := createResidualExp2(inExp1,inExp2);

  resExp := matchcontinue(iExp1, iExp2)
    local
      DAE.Exp e, e1, e2, res, res1, res2, N1, D1, N2, D2, N ,D;
      list<DAE.Exp> explst, explst1;
      DAE.Type ty;

    case(_, DAE.RCONST(real = 0.0)) then iExp1;
    case(_, DAE.ICONST(0)) then iExp1;
    case(DAE.RCONST(real = 0.0), _) then iExp2;
    case(DAE.ICONST(0), _) then iExp2;
    case(_, _)
      equation
        ty = typeof(iExp1);
        true = Types.isIntegerOrRealOrSubTypeOfEither(ty);
        // N1/D1 = N2/D2
        (N1,D1) = makeFraction(iExp1);
        (N2,D2) = makeFraction(iExp2);
        // N1*D2 = N2*D1 // simplify N1*D2 e.g. N1*D2 = (a/b + c)*b -> a+c/b
        res1 = ExpressionSimplify.simplifySumOperatorExpression(N1, DAE.MUL(ty), D2);
        res2 = ExpressionSimplify.simplifySumOperatorExpression(N2, DAE.MUL(ty), D1);

        //heuristic
        explst = terms(iExp1);
        explst1 = terms(iExp2);
        if isConst(res1) or (listLength(explst1) + 1) > listLength(explst) then
          res = expSub(res2,res1);
        else
          res = expSub(res1,res2);
        end if;

        (res, _) = ExpressionSimplify.simplify(res);
        //print("\n\niExp1:\n");print(ExpressionDump.printExpStr(iExp1));
        //print("\niExp2:\n");print(ExpressionDump.printExpStr(iExp2));
        //print("\nres:\n");print(ExpressionDump.printExpStr(res));
      then
        res;
    case(_, _)
      equation
        ty = typeof(iExp1);
        true = Types.isEnumeration(ty);
        res = expSub(iExp1, iExp2);
      then
        res;
    case(_, _)
      equation
        ty = typeof(iExp1);
        true = Types.isBooleanOrSubTypeBoolean(ty);
        res = DAE.LUNARY(DAE.NOT(ty), DAE.RELATION(iExp1, DAE.EQUAL(ty), iExp2, -1, NONE()));
      then
        res;
    case(_, _)
      equation
        ty = typeof(iExp1);
        true = Types.isStringOrSubTypeString(ty);
        res = DAE.LUNARY(DAE.NOT(ty), DAE.RELATION(iExp1, DAE.EQUAL(ty), iExp2, -1, NONE()));
      then
        res;
    else
      equation
        res = expSub(iExp1, iExp2);
       (res, _) = ExpressionSimplify.simplify(res);
      then
        res;
  end matchcontinue;
end createResidualExp;

public function makeFraction
"
In: f(x) {+,-} g(x)
Out: {N,D}

where f(x) {+,-} g(x) = N/D

author: Vitalij Ruge

"
  input DAE.Exp iExp;
  output DAE.Exp n "numerator";
  output DAE.Exp d "denominator";
protected
  list<DAE.Exp> N, D, T;
  DAE.Type tp = typeof(iExp);
algorithm
  T := terms(iExp);
  T := ExpressionSimplify.simplifyList(T);
  (N,D) := moveDivToMul(T, {}, {});
  N := ExpressionSimplify.simplifyList(N);
  D := ExpressionSimplify.simplifyList(D);
  n := makeSum1(N);
  d := makeProductLst(D);
  (n,_) := ExpressionSimplify.simplify1(n);
  (d,_) := ExpressionSimplify.simplify1(d);
end makeFraction;

protected function moveDivToMul
  input list<DAE.Exp> iExpLst;
  input list<DAE.Exp> iExpLstAcc;
  input list<DAE.Exp> iExpMuls;
  output list<DAE.Exp> oExpLst;
  output list<DAE.Exp> oExpMuls;
algorithm
  (oExpLst, oExpMuls) := match(iExpLst, iExpLstAcc, iExpMuls)
    local
      DAE.Exp e, e1, e2;
      list<DAE.Exp> rest, acc, elst, elst1;
    case ({}, _, _) then (iExpLstAcc, iExpMuls);
    //-(a/b)
    case (DAE.UNARY(_,DAE.BINARY(exp1=e1, operator=DAE.DIV(), exp2=e2))::rest, _, _)
      equation
         acc = List.map1(iExpLstAcc, Expression.expMul, e2);
         rest = List.map1(rest, Expression.expMul, e2);
         rest = ExpressionSimplify.simplifyList(rest);
        (elst, elst1) = moveDivToMul(rest, negate(e1)::acc, e2::iExpMuls);
      then
        (elst, elst1);
    case (DAE.UNARY(_,DAE.BINARY(exp1=e1, operator=DAE.DIV_ARRAY_SCALAR(), exp2=e2))::rest, _, _)
      equation
         acc = List.map1(iExpLstAcc, Expression.expMul, e2);
         rest = List.map1(rest, Expression.expMul, e2);
         rest = ExpressionSimplify.simplifyList(rest);
        (elst, elst1) = moveDivToMul(rest, negate(e1)::acc, e2::iExpMuls);
      then
        (elst, elst1);
    // a/b
    case (DAE.BINARY(exp1=e1, operator=DAE.DIV(), exp2=e2)::rest, _, _)
      equation
         acc = List.map1(iExpLstAcc, Expression.expMul, e2);
         rest = List.map1(rest, Expression.expMul, e2);
         rest = ExpressionSimplify.simplifyList(rest);
        (elst, elst1) = moveDivToMul(rest, e1::acc, e2::iExpMuls);
      then
        (elst, elst1);
    case (DAE.BINARY(exp1=e1, operator=DAE.DIV_ARRAY_SCALAR(), exp2=e2)::rest, _, _)
      equation
         acc = List.map1(iExpLstAcc, Expression.expMul, e2);
         rest = List.map1(rest, Expression.expMul, e2);
         rest = ExpressionSimplify.simplifyList(rest);
        (elst, elst1) = moveDivToMul(rest, e1::acc, e2::iExpMuls);
      then
        (elst, elst1);
    case (e::rest, _, _)
      equation
        (elst, elst1) = moveDivToMul(rest, e::iExpLstAcc, iExpMuls);
      then
        (elst, elst1);
  end match;
end moveDivToMul;

protected function createResidualExp2
"author: Vitalij
  do some numerical helpfull thinks on like
  sqrt(f()) - sqrt(g(.)) = 0 -> f(.) - g(.)"
  input DAE.Exp iExp1;
  input DAE.Exp iExp2;
  output DAE.Exp oExp1 = iExp1;
  output DAE.Exp oExp2 = iExp2;
protected
  Boolean con = true, con1;
  Integer ii = 1;
algorithm

while con and ii < 15 loop
  (oExp1, oExp2, con) := matchcontinue(oExp1, oExp2)
    local DAE.Exp e, e1, e2;

    case(_,_)
     equation
      (e1,e2,true) = createResidualExp3(oExp1, oExp2);
      (e1,_) = ExpressionSimplify.simplify1(e1);
      (e2,_) = ExpressionSimplify.simplify1(e2);
    then (e1 ,e2, true);

    case(_,_)
     equation
      (e2,e1,true) = createResidualExp3(oExp2, oExp1);
      (e1,_) = ExpressionSimplify.simplify1(e1);
      (e2,_) = ExpressionSimplify.simplify1(e2);
    then (e1 ,e2, true);
    else (oExp1, oExp2, false);
    end matchcontinue;

  (oExp1, oExp2, con1) := matchcontinue(oExp1, oExp2)
    local DAE.Exp e, e1, e2;
    case(_,_)
    equation
      true = isZero(oExp1);
      (e1,e2) = makeFraction(oExp2);
    then (e1 ,oExp1, not isOne(e2));

    case(_,_)
    equation
      true = isZero(oExp2);
      (e1,e2) = makeFraction(oExp1);
    then (e1 ,oExp2, not isOne(e2));

    case(_,_)
    equation
      true = isOne(oExp1);
      (e1,e2) = makeFraction(oExp2);
    then (e1 ,e2, not isOne(e2));

    case(_,_)
    equation
      true = isOne(oExp2);
      (e1,e2) = makeFraction(oExp1);
    then (e1 ,e2, not isOne(e2));

    else (oExp1, oExp2, false);
    end matchcontinue;
   con := con or con1;

   ii := ii + 1;
   if not con then
     (oExp1,con) := ExpressionSimplify.simplify1(oExp1);
     (oExp2,con1) := ExpressionSimplify.simplify1(oExp2);
     con := con or con1;
     ii := ii + 3;
  // else
  //   print("\niExp1");print(ExpressionDump.printExpStr(iExp1));
  //    print("\te1");print(ExpressionDump.printExpStr(oExp2));
  //   print("\niExp2");print(ExpressionDump.printExpStr(iExp2));
  //    print("\te2");print(ExpressionDump.printExpStr(oExp2));
   end if;

end while;

 (oExp1,_) := ExpressionSimplify.simplify1(oExp1);
 (oExp2,_) := ExpressionSimplify.simplify1(oExp2);

end createResidualExp2;

public function createResidualExp3
"author: Vitalij
  helper function of createResidualExp3
  swaps args"
  input DAE.Exp iExp1;
  input DAE.Exp iExp2;
  output DAE.Exp oExp1;
  output DAE.Exp oExp2;
  output Boolean con;
algorithm
  (oExp1, oExp2, con) := matchcontinue(iExp1, iExp2)
      local
        DAE.Exp e,e1,e2,e3,e4,e5,res;
        String s1, s2;
        DAE.Type tp;
        Real r;

    // f(x) = f(y) -> x = y
    case(DAE.CALL(path = Absyn.IDENT(s1), expLst={e1}),DAE.CALL(path = Absyn.IDENT(s2) ,expLst={e2}))
      guard s1 == s2 and createResidualExp4(s1)
     then (e1,e2, true);
    // sqrt(f(x)) = 0.0 -> f(x) = 0
    case(DAE.CALL(path = Absyn.IDENT("sqrt"), expLst={e1}), DAE.RCONST(0.0))
      then (e1,iExp2,true);
    // sqrt(f(x)) = c -> f(x) = c^2
    case(DAE.CALL(path = Absyn.IDENT("sqrt"), expLst={e1}), e2)
      guard(Expression.isConst(e2))
      equation
       e = Expression.expPow(iExp2, DAE.RCONST(2.0));
      then (e1,e,true);
    // log(f(x)) = c -> f(x) = exp(c)
    case(DAE.CALL(path = Absyn.IDENT("log"), expLst={e1}), e2)
      guard(Expression.isConst(e2))
      equation
       tp = Expression.typeof(iExp2);
       e = Expression.makePureBuiltinCall("exp", {iExp2}, tp);
      then (e1,e,true);
    // log10(f(x)) = c -> f(x) = 10^(c)
    case(DAE.CALL(path = Absyn.IDENT("log10"), expLst={e1}), e2)
      guard(Expression.isConst(e2))
      equation
       e = Expression.expPow(DAE.RCONST(10.0),iExp2);
      then (e1,e,true);
/*
    // f(x)^y = 0 -> x = 0
    case(DAE.BINARY(e1,DAE.POW(_),e2),DAE.RCONST(0.0))
      then (e1, iExp2, true);
    // abs(f(x)) = 0.0 -> f(x) = 0
    case(DAE.CALL(path = Absyn.IDENT("abs"), expLst={e1}), DAE.RCONST(0.0))
      then (e1,iExp2,true);
*/
   // semiLinear(0,e1,e2) = 0 -> e1 - e2 = 0
   case(DAE.CALL(path = Absyn.IDENT("semiLinear"), expLst={DAE.RCONST(0.0), e1, e2}), DAE.RCONST(0.0))
      then (e1,e2,true);
   // -f(.) = 0 -> f(.) = 0
   case(DAE.UNARY(operator = DAE.UMINUS(),exp = e1), e2 as DAE.RCONST(0.0))
    then (e1,e2,true);
  // f(x) - f(y) = 0 -> x = y
    case(DAE.BINARY(DAE.CALL(path = Absyn.IDENT(s1), expLst={e1}),DAE.SUB(),DAE.CALL(path = Absyn.IDENT(s2) ,expLst={e2})), DAE.RCONST(0.0))
    guard s1 == s2 and createResidualExp4(s1)
     then (e1,e2,true);
   else (iExp1, iExp2, false);
  end matchcontinue;
end createResidualExp3;

protected function createResidualExp4"
 author: Vitalij
 helper function of createResidualExp3
 return true if f(x) = f(y), then it can be transformed into x = y.

 Beware: function is not complete, yet!
"
  input String f;
  output Boolean resB;
algorithm
  resB := match(f)
    case("sqrt") then true;
    case("exp") then true;
    case("log") then true;
    case("log10") then true;
    case("tanh") then true;
    case("sinh") then true;
    else false;
  end match;
end createResidualExp4;

public function isAsubExp
  input DAE.Exp expIn;
  output Boolean isAsub;
algorithm
  isAsub := match(expIn)
    case(DAE.ASUB(_,_)) equation
      then true;
    else false;
  end match;
end isAsubExp;

public function typeCast
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := DAE.CAST(inType, inExp);
  outExp := ExpressionSimplify.simplify1(outExp);
end typeCast;

public function typeCastElements
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Exp outExp;
protected
  DAE.Type ty;
algorithm
  ty := typeof(inExp);
  ty := Types.setArrayElementType(ty, inType);
  outExp := typeCast(inExp, ty);
end typeCastElements;

public function expandRange
  "Expands a range expression into its elements:
    expandRange(1:4) => {1, 2, 3, 4}"
  input DAE.Exp inRange;
  output list<DAE.Exp> outValues;
protected
  DAE.Exp start_exp, stop_exp;
  Option<DAE.Exp> ostep_exp;
  Integer istep;
  Real rstep;
  list<DAE.Exp> vals;
  list<String> enum_names;
  Absyn.Path enum_type;
  DAE.Type range_ty;
algorithm
  DAE.RANGE(start = start_exp, step = ostep_exp, stop = stop_exp) := inRange;

  outValues := match (start_exp, stop_exp)
    // An integer range, with or without a step value.
    case (DAE.ICONST(), DAE.ICONST())
      algorithm
        DAE.ICONST(istep) := Util.getOptionOrDefault(ostep_exp, DAE.ICONST(1));
      then
        list(DAE.ICONST(i) for i in
          List.intRange3(start_exp.integer, istep, stop_exp.integer));

    // A real range, with or without a step value.
    case (DAE.RCONST(), DAE.RCONST())
      algorithm
        DAE.RCONST(rstep) := Util.getOptionOrDefault(ostep_exp, DAE.RCONST(1.0));
      then
        list(DAE.RCONST(r) for r in
          ExpressionSimplify.simplifyRangeReal(start_exp.real, rstep, stop_exp.real));

    // false:true => {false, true}
    case (DAE.BCONST(false), DAE.BCONST(true))
      then {start_exp, stop_exp};

    // true:false => {}
    case (DAE.BCONST(true), DAE.BCONST(false))
      then {};

    // true:true => true, false:false => false
    case (DAE.BCONST(), DAE.BCONST())
      then {start_exp};

    // An enumeration range, no step value allowed.
    case (DAE.ENUM_LITERAL(), DAE.ENUM_LITERAL())
      algorithm
        if start_exp.index > stop_exp.index then
          vals := {};
        elseif start_exp.index == stop_exp.index then
          vals := {start_exp};
        else
          DAE.RANGE(ty = range_ty) := inRange;
          DAE.T_ENUMERATION(path = enum_type, names = enum_names) := Types.arrayElementType(range_ty);
          enum_names := List.sublist(enum_names, start_exp.index,
            (stop_exp.index - start_exp.index) + 1);
          vals := makeEnumLiterals(enum_type, enum_names);
        end if;
      then
        vals;

  end match;
end expandRange;

public function isScalar
  input DAE.Exp inExp;
  output Boolean outIsScalar;
algorithm
  outIsScalar := match inExp
    case DAE.ICONST() then true;
    case DAE.RCONST() then true;
    case DAE.SCONST() then true;
    case DAE.BCONST() then true;
    case DAE.CLKCONST() then true;
    case DAE.ENUM_LITERAL() then true;
    case DAE.UNARY() then isScalar(inExp.exp);
    case DAE.LUNARY() then isScalar(inExp.exp);
    case DAE.RELATION() then true;
    case DAE.ARRAY() then false;
    case DAE.MATRIX() then false;
    case DAE.RANGE() then false;
    case DAE.CAST() then isScalar(inExp.exp);
    case DAE.SIZE() then isSome(inExp.sz);
    else Types.isSimpleType(typeof(inExp));
  end match;
end isScalar;

public function containsAnyCall
  "Returns true if the given expression contains any function calls,
   otherwise false."
  input DAE.Exp inExp;
  output Boolean outContainsCall;
algorithm
  (_, outContainsCall) := traverseExpTopDown(inExp, containsAnyCall_traverser, false);
end containsAnyCall;

protected function containsAnyCall_traverser
  input DAE.Exp inExp;
  input Boolean inContainsCall;
  output DAE.Exp outExp = inExp;
  output Boolean outContinue;
  output Boolean outContainsCall;
algorithm
  outContainsCall := match inExp
    case DAE.CALL() then true;
    else inContainsCall;
  end match;

  outContinue := not outContainsCall;
end containsAnyCall_traverser;

public function containsCallTo
  "Returns true if the given expression contains any function calls,
   otherwise false."
  input DAE.Exp inExp;
  input Absyn.Path path;
  output Boolean outContainsCall;
algorithm
  (_, (_,outContainsCall)) := traverseExpTopDown(inExp, containsCallTo_traverser, (path,false));
end containsCallTo;

protected function containsCallTo_traverser
  input DAE.Exp inExp;
  input tuple<Absyn.Path,Boolean> inTpl;
  output DAE.Exp outExp = inExp;
  output Boolean outContinue = false;
  output tuple<Absyn.Path,Boolean> outTpl = inTpl;
protected
  Boolean containsCall;
  Absyn.Path path;
algorithm
  (path,containsCall) := outTpl;
  if containsCall then
    return;
  end if;
  outContinue := match inExp
    case DAE.CALL() then AbsynUtil.pathEqual(path,inExp.path);
    else true;
  end match;
  if not outContinue then
    outTpl := (path,false);
  end if;
end containsCallTo_traverser;

public function rangeSize
  "Tries to figure out the size of a range expression. Either return the size or
   fails."
  input DAE.Exp inRange;
  output Integer outSize;
algorithm
  outSize := match inRange
    local
      Integer start, step, stop;

    case DAE.RANGE(ty = DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(outSize)})) then outSize;

    case DAE.RANGE(start = DAE.ICONST(start),
                   step = NONE(),
                   stop = DAE.ICONST(stop))
      then max(stop - start, 0);

    case DAE.RANGE(start = DAE.ICONST(start),
                   step = SOME(DAE.ICONST(step)),
                   stop = DAE.ICONST(stop))
      algorithm
        if step <> 0 then
          outSize := max(realInt(floor(realDiv(stop - start, step))) + 1, 0);
        else
          fail();
        end if;
      then
        outSize;

  end match;
end rangeSize;

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
        DAE.ASUB(exp = e, sub = expl) := inExp2;
        comp := compare(inExp1.exp, e);
      then if comp==0 then compareList(inExp1.sub, expl) else comp;

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

public function isInvariantExpNoTraverse "For use with traverseExp"
  input output DAE.Exp e;
  input output Boolean b;
algorithm
  if not b then
    return;
  end if;
  b := match e
    case DAE.ICONST() then true;
    case DAE.RCONST() then true;
    case DAE.SCONST() then true;
    case DAE.BCONST() then true;
    case DAE.BINARY() then true;
    case DAE.UNARY() then true;
    case DAE.LBINARY() then true;
    case DAE.LUNARY() then true;
    case DAE.RELATION() then true;
    case DAE.IFEXP() then true;
    case DAE.CALL(path=Absyn.FULLYQUALIFIED()) then true;
    case DAE.PARTEVALFUNCTION(path=Absyn.FULLYQUALIFIED()) then true;
    case DAE.ARRAY() then true;
    case DAE.MATRIX() then true;
    case DAE.RANGE() then true;
    case DAE.CONS() then true;
    case DAE.LIST() then true;
    else false;
  end match;
end isInvariantExpNoTraverse;

public function findCallIsInlineAfterIndexReduction
  input output DAE.Exp e;
  output Boolean cont;
  input output Boolean res;
algorithm
  if not res then
    res := match e
      case DAE.CALL(attr=DAE.CALL_ATTR(inlineType=DAE.AFTER_INDEX_RED_INLINE())) then true;
      else false;
    end match;
  end if;
  cont := not res;
end findCallIsInlineAfterIndexReduction;

public function tupleHead
  input DAE.Exp exp;
  input DAE.Properties prop;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outExp, outProp) := match (exp, prop)
    local
      DAE.Type ty;

    case (DAE.Exp.TUPLE(_ :: _), DAE.Properties.PROP_TUPLE())
      then (listHead(exp.PR), Types.propTupleFirstProp(prop));
    case (_, DAE.Properties.PROP_TUPLE(type_ = DAE.T_TUPLE(types = ty :: _)))
      then (DAE.Exp.TSUB(exp, 1, ty), Types.propTupleFirstProp(prop));
    else (exp, prop);
  end match;
end tupleHead;

public function isSimpleLiteralValue "A value that requires nothing special during code generation. String literals are special and not included."
  input DAE.Exp exp;
  output Boolean b;
algorithm
  b := match exp
    case DAE.ICONST() then true;
    case DAE.RCONST() then true;
    case DAE.BCONST() then true;
    case DAE.ENUM_LITERAL() then true;
    else false;
  end match;
end isSimpleLiteralValue;

public function consToListIgnoreSharedLiteral
  input output DAE.Exp e;
protected
  DAE.Exp exp;
algorithm
  if match e
    case DAE.SHARED_LITERAL() then true;
    case DAE.LIST() then true;
    case DAE.CONS() then true;
    else false; end match then
    try
      e := consToListIgnoreSharedLiteralWork(e);
    else
    end try;
  end if;
end consToListIgnoreSharedLiteral;

protected function consToListIgnoreSharedLiteralWork
  input output DAE.Exp e;
  input list<DAE.Exp> acc={};
algorithm
  e := match (e,acc)
    case (DAE.SHARED_LITERAL(),_) then consToListIgnoreSharedLiteralWork(e.exp, acc);
    case (DAE.LIST(),{}) then e;
    case (DAE.LIST(),_) then DAE.LIST(List.append_reverse(acc, e.valList));
    case (DAE.CONS(),_) then consToListIgnoreSharedLiteralWork(e.cdr, e.car::acc);
  end match;
end consToListIgnoreSharedLiteralWork;

annotation(__OpenModelica_Interface="frontend");
end Expression;
