/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Expression
"
  file:	       Expression.mo
  package:     Expression
  description: Expressions

  RCS: $Id: Expression.mo 6623 2010-10-26 18:26:41Z Frenkel TUD $

  This file contains the module `Expression\', which contains data types for
  describing expressions, after they have been examined by the
  static analyzer in the module `StaticExp\'.  There are of course
  great similarities with the expression types in the `Absyn\'
  module, but there are also several important differences.

  No overloading of operators occur, and subscripts have been
  checked to see if they are slices.  All expressions are also type
  consistent, and all implicit type conversions in the AST are made
  explicit here."

public import Absyn;
public import DAE;

public type ComponentRef = DAE.ComponentRef;
public type Ident = String;
public type Operator = DAE.Operator;
public type Type = DAE.ExpType;
public type Subscript = DAE.Subscript;
public type Var = DAE.ExpVar;

protected import ComponentReference;
protected import ExpressionSimplify;
protected import RTOpts;
protected import Util;
protected import ModUtil;
protected import Debug;
protected import Static;
protected import Env;
protected import ExpressionDump;
protected import System;
protected import DAEUtil;
protected import Algorithm;
protected import Prefix;

/***************************************************/
/* transform to other types */
/***************************************************/

public function intSubscripts
"function: intSubscripts
  This function describes the function between a list of integers
  and a list of DAE.Subscript where each integer is converted to
  an integer indexing expression."
  input list<Integer> inIntegerLst;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inIntegerLst)
    local
      list<Subscript> xs_1;
      Integer x;
      list<Integer> xs;
    case {} then {};
    case (x :: xs)
      equation
        xs_1 = intSubscripts(xs);
      then
        (DAE.INDEX(DAE.ICONST(x)) :: xs_1);
  end matchcontinue;
end intSubscripts;

public function subscriptsInt "
function: subscriptsInt
  author: PA
  This function creates a list of ints from
  a subscript list, see also intSubscripts."
  input list<Subscript> inSubscriptLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inSubscriptLst)
    local
      list<Integer> xs_1;
      Integer x;
      list<Subscript> xs;
    case {} then {};
    case (DAE.INDEX(exp = DAE.ICONST(integer = x)) :: xs)
      equation
        xs_1 = subscriptsInt(xs);
      then
        (x :: xs_1);
    case (DAE.INDEX(exp = DAE.ENUM_LITERAL(index = x)) :: xs)
      equation
        xs_1 = subscriptsInt(xs);
      then
        (x :: xs_1);
  end matchcontinue;
end subscriptsInt;

public function unelabExp
"function: unelabExp
  Transform an DAE.Exp into Absyn.Expression.
  Note: This function currently only works for
  constants and component references."
  input DAE.Exp inExp;
  output Absyn.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      Integer i;
      Real r;
      Ident s;
      Boolean b;
      Absyn.ComponentRef cr_1;
      ComponentRef cr;
      Type t,tp;
      list<Absyn.Exp> expl_1,aexpl;
      list<DAE.Exp> expl;
      DAE.Exp e1,e2,e3;
      Operator op;
      Absyn.Exp ae1,ae2,ae3;
      Absyn.Operator aop;
      list<list<DAE.Exp>> mexpl2;
      list<list<Absyn.Exp>> amexpl;
      list<list<tuple<DAE.Exp,Boolean>>> mexpl;
      Absyn.ComponentRef acref;
      Absyn.Path path;
      Absyn.CodeNode code;

    case (DAE.ICONST(integer = i)) then Absyn.INTEGER(i);
    case (DAE.RCONST(real = r)) then Absyn.REAL(r);
    case (DAE.SCONST(string = s)) then Absyn.STRING(s);
    case (DAE.BCONST(bool = b)) then Absyn.BOOL(b);
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

    case(DAE.RELATION(e1,op,e2)) equation
      aop = unelabOperator(op);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.RELATION(ae1,aop,ae2);

    case(DAE.IFEXP(e1,e2,e3)) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
      ae3 = unelabExp(e3);
    then Absyn.IFEXP(ae1,ae2,ae3,{});

    case(DAE.CALL(path,expl,_,_,_,_)) equation
      aexpl = Util.listMap(expl,unelabExp);
      acref = Absyn.pathToCref(path);
    then Absyn.CALL(acref,Absyn.FUNCTIONARGS(aexpl,{}));

    case(DAE.PARTEVALFUNCTION(path,expl,_))
      equation
        aexpl = Util.listMap(expl,unelabExp);
        acref = Absyn.pathToCref(path);
      then
        Absyn.PARTEVALFUNCTION(acref,Absyn.FUNCTIONARGS(aexpl,{}));

    case (DAE.ARRAY(ty = tp,scalar = b,array = expl))
      equation
        expl_1 = Util.listMap(expl, unelabExp);
      then
        Absyn.ARRAY(expl_1);
    
    case(DAE.MATRIX(_,_,mexpl)) equation
      mexpl2 = Util.listListMap(mexpl,Util.tuple21);
      amexpl = Util.listListMap(mexpl2,unelabExp);
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
        expl_1 = Util.listMap(expl, unelabExp);
      then
        Absyn.TUPLE(expl_1);
    case(DAE.CAST(_,e1)) equation
      ae1 = unelabExp(e1);
    then ae1;

     // ASUB can not be unelabed since it has no representation in Absyn.
    case(DAE.ASUB(_,_)) equation
      print("Internal Error, can not unelab ASUB\n");
    then fail();

    case(DAE.SIZE(e1,SOME(e2))) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({ae1,ae2},{}));

    case(DAE.SIZE(e1,SOME(e2))) equation
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({ae1,ae2},{}));

    case(DAE.CODE(code,_)) then Absyn.CODE(code);

    case DAE.REDUCTION(path,e1,s,e2) equation
      //print("unelab of reduction not impl. yet");
      acref = Absyn.pathToCref(path);
      ae1 = unelabExp(e1);
      ae2 = unelabExp(e2);
    then 
      Absyn.CALL(acref, Absyn.FOR_ITER_FARG(ae1, {(s,SOME(ae2))}));

    case(DAE.END()) then Absyn.END();
    case(DAE.VALUEBLOCK(_,_,_,_)) equation
      print("unelab of VALUEBLOCK not impl. yet");
    then fail();
  end matchcontinue;
end unelabExp;

protected function unelabOperator "help function to unelabExpression."
input Operator op;
output Absyn.Operator aop;
algorithm
  aop := matchcontinue(op)
    case(DAE.ADD(_)) then Absyn.ADD();
    case(DAE.SUB(_)) then Absyn.SUB();
    case(DAE.MUL(_)) then Absyn.MUL();
    case(DAE.DIV(_)) then Absyn.DIV();
    case(DAE.POW(_)) then Absyn.POW();
    case(DAE.UMINUS(_)) then Absyn.UMINUS();
    case(DAE.UPLUS(_)) then Absyn.UPLUS();
    case(DAE.UMINUS_ARR(_)) then Absyn.UMINUS();
    case(DAE.UPLUS_ARR(_)) then Absyn.UPLUS();
    case(DAE.ADD_ARR(_)) then Absyn.ADD();
    case(DAE.SUB_ARR(_)) then Absyn.SUB();
    case(DAE.MUL_ARR(_)) then Absyn.MUL();
    case(DAE.DIV_ARR(_)) then Absyn.DIV();
    case(DAE.MUL_SCALAR_ARRAY(_)) then Absyn.MUL();
    case(DAE.MUL_ARRAY_SCALAR(_)) then Absyn.MUL();
    case(DAE.ADD_SCALAR_ARRAY(_)) then Absyn.ADD();
    case(DAE.ADD_ARRAY_SCALAR(_)) then Absyn.ADD();
    case(DAE.SUB_SCALAR_ARRAY(_)) then Absyn.SUB();
    case(DAE.SUB_ARRAY_SCALAR(_)) then Absyn.SUB();
    case(DAE.MUL_SCALAR_PRODUCT(_)) then Absyn.MUL();
    case(DAE.MUL_MATRIX_PRODUCT(_)) then Absyn.MUL();
    case(DAE.DIV_SCALAR_ARRAY(_)) then Absyn.DIV();
    case(DAE.DIV_ARRAY_SCALAR(_)) then Absyn.DIV();
    case(DAE.POW_SCALAR_ARRAY(_)) then Absyn.POW();
    case(DAE.POW_ARRAY_SCALAR(_)) then Absyn.POW();
    case(DAE.POW_ARR(_)) then Absyn.POW();
    case(DAE.POW_ARR2(_)) then Absyn.POW();
    case(DAE.AND()) then Absyn.AND();
    case(DAE.OR()) then Absyn.OR();
    case(DAE.NOT()) then Absyn.NOT();
    case(DAE.LESS(_)) then Absyn.LESS();
    case(DAE.LESSEQ(_)) then Absyn.LESSEQ();
    case(DAE.GREATER(_)) then Absyn.GREATER();
    case(DAE.GREATEREQ(_)) then Absyn.GREATEREQ();
    case(DAE.EQUAL(_)) then Absyn.EQUAL();
    case(DAE.NEQUAL(_)) then Absyn.NEQUAL();
  end matchcontinue;
end unelabOperator;

public function stringifyCrefs
"function: stringifyCrefs
  This function takes an expression and transforms all component
  reference  names contained in the expression to a simpler form.
  For instance DAE.CREF_QUAL(\"a\",{}, DAE.CREF_IDENT(\"b\",{})) becomes
  DAE.CREF_IDENT(\"a.b\",{})

  NOTE: This function should not be used in OMC, since the OMC backend no longer
    uses stringified components. It is still used by MathCore though."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
  case(inExp)
    local DAE.Exp e;
    equation
      ((e,_)) = traverseExp(inExp, traversingstringifyCrefFinder, {});
      then
        e;
  end matchcontinue;
end stringifyCrefs;

public function traversingstringifyCrefFinder "
helper for stringifyCrefs
"
  input tuple<DAE.Exp, list<Integer> > inExp;
  output tuple<DAE.Exp, list<Integer> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    list<Integer> ilst "just a dummy to use traverseExp";
    ComponentRef cr,crs;
    Type ty;
    DAE.Exp e;
  case ((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_VAR()), ilst)) then ((e, ilst));
  case ((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = _)), ilst)) then ((e, ilst));    
  case( (DAE.CREF(cr,ty), ilst) )
    local list<Boolean> blist;
    equation
      crs = ComponentReference.stringifyComponentRef(cr);
    then
      ((DAE.CREF(crs,ty), ilst ));
  case(inExp) then inExp;
end matchcontinue;
end traversingstringifyCrefFinder;

public function CodeVarToCref
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=matchcontinue(inExp)
    local
      ComponentRef e_cref;
      Absyn.ComponentRef cref;
    case(DAE.CODE(Absyn.C_VARIABLENAME(cref),_))
      equation
        (_,e_cref) = Static.elabUntypedCref(Env.emptyCache(),Env.emptyEnv,cref,false,Prefix.NOPRE,Absyn.dummyInfo);
      then DAE.CREF(e_cref,DAE.ET_OTHER());
    case(DAE.CODE(Absyn.C_EXPRESSION(Absyn.CALL(Absyn.CREF_IDENT("der",{}),Absyn.FUNCTIONARGS({Absyn.CREF(cref)},{}))),_))
      equation
        (_,e_cref) = Static.elabUntypedCref(Env.emptyCache(),Env.emptyEnv,cref,false,Prefix.NOPRE,Absyn.dummyInfo);
      then DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(e_cref,DAE.ET_OTHER())},false,false,DAE.ET_OTHER(),DAE.NO_INLINE());
  end matchcontinue;
end CodeVarToCref;

public function realToIntIfPossible
"converts to ICONST if possible. If it does
 not fit, a RCONST is returned instead."
	input Real inVal;
	output DAE.Exp outVal;
algorithm
  outVal := matchcontinue(inVal)
  	local
  	  	Integer i;
    case	(inVal)
      equation
       	 i = realInt(inVal);
     	then
				DAE.ICONST(i);
    case	(inVal)
    	then
				DAE.RCONST(inVal);
	end matchcontinue;
end realToIntIfPossible;

public function liftArrayR "
function liftArrayR
Converts a type into an array type with dimension n as first dim"
  input Type tp;
  input DAE.Dimension n;
  output Type outTp;
algorithm
  outTp := matchcontinue(tp,n)
    local
      Type elt_tp;
      list<DAE.Dimension> dims;

    case(DAE.ET_ARRAY(elt_tp,dims),n)
      equation
      dims = n::dims;
      then DAE.ET_ARRAY(elt_tp,dims);

    case(tp,n)
    then DAE.ET_ARRAY(tp,{n});

  end matchcontinue;
end liftArrayR;

public function dimensionSizeExp
  "Converts a dimension to an integer expression."
  input DAE.Dimension dim;
  output DAE.Exp exp;
algorithm
  exp := matchcontinue(dim)
    local
      Integer i;
    case DAE.DIM_INTEGER(integer = i) then DAE.ICONST(i);
    case DAE.DIM_ENUM(size = i) then DAE.ICONST(i);
  end matchcontinue;
end dimensionSizeExp;

public function intDimension
  "Converts an integer to an array dimension."
  input Integer value;
  output DAE.Dimension dim;
algorithm
  dim := DAE.DIM_INTEGER(value);
end intDimension;

public function dimensionSubscript
  "Converts an array dimension to a subscript."
  input DAE.Dimension dim;
  output DAE.Subscript sub;
algorithm
  sub := matchcontinue(dim)
    local
      Integer i;
    case DAE.DIM_INTEGER(integer = i) then DAE.INDEX(DAE.ICONST(i));
    case DAE.DIM_ENUM(size = i) then DAE.INDEX(DAE.ICONST(i));
    case DAE.DIM_UNKNOWN() then DAE.WHOLEDIM();
  end matchcontinue;
end dimensionSubscript;

/***************************************************/
/* Change  */
/***************************************************/

public function negate
"function: negate
  author: PA
  Negates an expression."
  input DAE.Exp e;
  output DAE.Exp outExp;
protected
  Type t;
algorithm
  outExp := matchcontinue(e)
  local 
    Type t;
    Operator op;
    Boolean b;
    /* to avoid unnessecary --e */
    case(DAE.UNARY(DAE.UMINUS(t),e)) then e;
    case(DAE.UNARY(DAE.UMINUS_ARR(t),e)) then e;

    /* -0 = 0 */
    case(e) equation
      true = isZero(e);
    then e;

    case(e) equation
      t = typeof(e);
      b = DAEUtil.expTypeArray(t);
      op = Util.if_(b,DAE.UMINUS_ARR(t),DAE.UMINUS(t));
    then DAE.UNARY(op,e);
  end matchcontinue;
end negate;

public function expand "expands products
For example
a *(b+c) => a*b + a*c
" 
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  outE := matchcontinue(e)
  local DAE.ExpType tp;
    DAE.Operator op;
    DAE.Exp e1,e2,e21,e22;
    case(DAE.BINARY(e1,DAE.MUL(tp),e2)) equation
      DAE.BINARY(e21,op,e22) = expand(e2);
      true = isAddOrSub(op);      
    then DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e21),op,DAE.BINARY(e1,DAE.MUL(tp),e22));
    case(e) then e;     
  end matchcontinue;
end expand;

public function abs
"function: abs
  author: PA
  Makes the expression absolute. i.e. non-negative."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
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
    case (DAE.UNARY(operator = DAE.UMINUS(ty = tp),exp = e))
      equation
        e_1 = abs(e);
      then
        e_1;
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = abs(e1);
        e2_1 = abs(e2);
      then
        DAE.BINARY(e1_1,op,e2_1);
    case (e) then e;
  end matchcontinue;
end abs;

public function stripNoEvent
"Function that strips all noEvent() calls in an expression"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  ((outE,_)) := traverseExp(e,stripNoEventExp,0);
end stripNoEvent;

protected function stripNoEventExp "
traversal function for stripNoEvent"
  input tuple<DAE.Exp,Integer/*dummy*/> inTpl;
  output tuple<DAE.Exp,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local DAE.Exp e; Integer i;
    case((DAE.CALL(path=Absyn.IDENT("noEvent"),expLst={e}),i)) then ((e,i));
    case((e,i)) then ((e,i));
  end matchcontinue;
end stripNoEventExp;

public function addNoEventToRelations
"Function that adds a  noEvent() call to all relations in an expression"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  ((outE,_)) := traverseExp(e,addNoEventToRelationExp,0);
end addNoEventToRelations;

protected function addNoEventToRelationExp "
traversal function for addNoEventToRelations"
  input tuple<DAE.Exp,Integer/*dummy*/> inTpl;
  output tuple<DAE.Exp,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local DAE.Exp e; Integer i;
    case((e as DAE.RELATION(exp1=_),i)) then ((DAE.CALL(Absyn.IDENT("noEvent"),{e},false,true,DAE.ET_BOOL(),DAE.NO_INLINE()),i));
    case((e,i)) then ((e,i));
  end matchcontinue;
end addNoEventToRelationExp;

public function addNoEventToEventTriggeringFunctions
" Function that adds a  noEvent() call to all event triggering functions in an expression"
  input DAE.Exp e;
  output DAE.Exp outE;
algorithm
  ((outE,_)) := traverseExp(e,addNoEventToEventTriggeringFunctionsExp,0);
end addNoEventToEventTriggeringFunctions;

protected function addNoEventToEventTriggeringFunctionsExp "
traversal function for addNoEventToEventTriggeringFunctions"
  input tuple<DAE.Exp,Integer/*dummy*/> inTpl;
  output tuple<DAE.Exp,Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local DAE.Exp e; Integer i;
    case (((e as DAE.CALL(path=_)), i))
      equation
        true = isEventTriggeringFunctionExp(e);
      then ((DAE.CALL(Absyn.IDENT("noEvent"),{e},false,true,DAE.ET_BOOL(),DAE.NO_INLINE()),i));
    case ((e,i)) then ((e,i));
  end matchcontinue;
end addNoEventToEventTriggeringFunctionsExp;

public function expStripLastSubs
"function: expStripLastSubs
  Strips the last subscripts of a Exp"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
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
      then DAE.CREF(cr_1,ty);

    case (DAE.UNARY(operator=op,exp=e))
      equation
        e_1 = expStripLastSubs(e);
        ty = typeof(e_1);
        b = DAEUtil.expTypeArray(ty);
        op1 = Util.if_(b,DAE.UMINUS_ARR(ty),DAE.UMINUS(ty));
      then DAE.UNARY(op1,e_1);
  end matchcontinue;
end expStripLastSubs;

public function expStripLastIdent
"function: expStripLastIdent
  Strips the last subscripts of a Exp"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
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
      then DAE.CREF(cr_1,ty);
    case (DAE.UNARY(operator=op,exp=e))
      equation
        e_1 = expStripLastIdent(e);
        ty = typeof(e_1);
        b = DAEUtil.expTypeArray(ty);
        op1 = Util.if_(b,DAE.UMINUS_ARR(ty),DAE.UMINUS(ty));
      then DAE.UNARY(op1,e_1);
  end matchcontinue;
end expStripLastIdent;

public function prependSubscriptExp
"Prepends a subscript to a CREF expression
 For instance a.b[1,2] with subscript 'i' becomes a.b[i,1,2]."
  input DAE.Exp exp;
  input Subscript subscr;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(exp,subscr)
  local Type t; ComponentRef cr,cr1,cr2;
    list<Subscript> subs;
    case(DAE.CREF(cr,t),subscr) equation
      cr1 = ComponentReference.crefStripLastSubs(cr);
      subs = ComponentReference.crefLastSubs(cr);
      cr2 = ComponentReference.subscriptCref(cr1,subscr::subs);
    then DAE.CREF(cr2,t);
  end matchcontinue;
end prependSubscriptExp;

public function applyExpSubscripts "
author: PA
Takes an arbitrary expression and applies subscripts to it. This is done by creating asub
expressions given the original expression and then simplify them.
Note: The subscripts must be INDEX

alternative names: subsriptExp (but already taken), subscriptToAsub"
  input DAE.Exp e;
  input list<DAE.Subscript> subs; 
  output DAE.Exp res;
algorithm
  res := matchcontinue(e,subs)
  local list<DAE.Exp> expl;
    DAE.Exp s;
    DAE.Subscript sub;
    
    case(e,{}) then e;
      
    case(e,sub::subs) equation
      // Apply one subscript at a time, so simplify works fine on it.
     s = subscriptExp(sub);
     res = applyExpSubscripts(ExpressionSimplify.simplify(DAE.ASUB(e,{s})),subs);
    then res;
      
  end matchcontinue;
end applyExpSubscripts ;

public function unliftArray
"function: unliftArray
  Converts an array type into its element type
  See also Types.unliftArray.
  ."
  input Type inType;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType)
    local
      Type tp,t;
      DAE.Dimension d;
      list<DAE.Dimension> ds;
    case (DAE.ET_ARRAY(ty = tp,arrayDimensions = {_}))
      then tp;
    case (DAE.ET_ARRAY(ty = tp,arrayDimensions = (d :: ds)))
      then DAE.ET_ARRAY(tp,ds);
    case (t) then t;
  end matchcontinue;
end unliftArray;

public function unliftExp
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      Type ty;
    case DAE.CREF(componentRef = cr, ty = ty)
      local 
        DAE.ComponentRef cr;
      equation
        ty = unliftArray(ty);
      then
        DAE.CREF(cr, ty);
    case DAE.ARRAY(ty = ty, scalar = s, array = a)
      local
        Boolean s;
        list<DAE.Exp> a;
      equation
        ty = unliftArray(ty);
      then
        DAE.ARRAY(ty, s, a);
    case DAE.MATRIX(ty = ty, integer = i, scalar = s)
      local
        Integer i;
        list<list<tuple<DAE.Exp, Boolean>>> s;
      equation
        ty = unliftArray(ty);
      then
        DAE.MATRIX(ty, i, s);
    case (_) then inExp;
  end matchcontinue;
end unliftExp;


public function liftArrayRight "
This function adds an array dimension to a type on the right side, i.e.
liftArrayRigth(Real[2,3],SOME(4)) => Real[2,3,4].

This function has the same functionality as Types.liftArrayType but for DAE.ExpType.'
"
  input Type inType;
  input DAE.Dimension inDimension;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType,inDimension)
    local
      Type ty_1,ty;
      list<DAE.Dimension> dims;
      DAE.Dimension dim;
      Integer i;
    case (DAE.ET_ARRAY(ty,dims),dim)
      equation
        ty_1 = liftArrayRight(ty, dim);
      then
        DAE.ET_ARRAY(ty_1,dims);
    case (ty,dim)
      then
        DAE.ET_ARRAY(ty,{dim});
  end matchcontinue;
end liftArrayRight;

public function liftArrayLeft "
author: PA
This function adds an array dimension to a type on the left side, i.e.
liftArrayRigth(Real[2,3],SOME(4)) => Real[4,2,3]
"
  input Type inType;
  input DAE.Dimension inDimension;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType,inDimension)
    local
      Type ty_1,ty;
      list<DAE.Dimension> dims;
      DAE.Dimension dim;
      
    case (DAE.ET_ARRAY(ty,dims),dim) then DAE.ET_ARRAY(ty,dim::dims);
      
    case (ty,dim)then DAE.ET_ARRAY(ty,{dim});
      
  end matchcontinue;
end liftArrayLeft;

public function setOpType
  "Sets the type of an operator."
  input Operator inOp;
  input Type inType;
  output Operator outOp;
algorithm
  outOp := matchcontinue(inOp, inType)
    case (DAE.ADD(ty = _), _) then DAE.ADD(inType);
    case (DAE.SUB(ty = _), _) then DAE.SUB(inType);
    case (DAE.MUL(ty = _), _) then DAE.MUL(inType);
    case (DAE.DIV(ty = _), _) then DAE.DIV(inType);
    case (DAE.POW(ty = _), _) then DAE.POW(inType);
    case (DAE.UMINUS(ty = _), _) then DAE.UMINUS(inType);
    case (DAE.UPLUS(ty = _), _) then DAE.UPLUS(inType);
    case (DAE.UMINUS_ARR(ty = _), _) then DAE.UMINUS_ARR(inType);
    case (DAE.UPLUS_ARR(ty = _), _) then DAE.UPLUS_ARR(inType);
    case (DAE.ADD_ARR(ty = _), _) then DAE.ADD_ARR(inType);
    case (DAE.SUB_ARR(ty = _), _) then DAE.SUB_ARR(inType);
    case (DAE.MUL_ARR(ty = _), _) then DAE.MUL_ARR(inType);
    case (DAE.DIV_ARR(ty = _), _) then DAE.DIV_ARR(inType);
    case (DAE.MUL_SCALAR_ARRAY(ty = _), _) then DAE.MUL_SCALAR_ARRAY(inType);
    case (DAE.MUL_ARRAY_SCALAR(ty = _), _) then DAE.MUL_ARRAY_SCALAR(inType);
    case (DAE.ADD_SCALAR_ARRAY(ty = _), _) then DAE.ADD_SCALAR_ARRAY(inType);
    case (DAE.ADD_ARRAY_SCALAR(ty = _), _) then DAE.ADD_ARRAY_SCALAR(inType);
    case (DAE.SUB_SCALAR_ARRAY(ty = _), _) then DAE.SUB_SCALAR_ARRAY(inType);
    case (DAE.SUB_ARRAY_SCALAR(ty = _), _) then DAE.SUB_ARRAY_SCALAR(inType);
    case (DAE.MUL_SCALAR_PRODUCT(ty = _), _) then DAE.MUL_SCALAR_PRODUCT(inType);
    case (DAE.MUL_MATRIX_PRODUCT(ty = _), _) then DAE.MUL_MATRIX_PRODUCT(inType);
    case (DAE.DIV_ARRAY_SCALAR(ty = _), _) then DAE.DIV_ARRAY_SCALAR(inType);
    case (DAE.DIV_SCALAR_ARRAY(ty = _), _) then DAE.DIV_SCALAR_ARRAY(inType);
    case (DAE.POW_ARRAY_SCALAR(ty = _), _) then DAE.POW_ARRAY_SCALAR(inType);
    case (DAE.POW_SCALAR_ARRAY(ty = _), _) then DAE.POW_SCALAR_ARRAY(inType);
    case (DAE.POW_ARR(ty = _), _) then DAE.POW_ARR(inType);
    case (DAE.POW_ARR2(ty = _), _) then DAE.POW_ARR2(inType);
    case (DAE.AND(), _) then DAE.AND();
    case (DAE.OR(), _) then DAE.OR();
    case (DAE.NOT(),_ ) then DAE.NOT();
    case (DAE.LESS(ty = _), _) then inOp;
    case (DAE.LESSEQ(ty = _), _) then inOp;
    case (DAE.GREATER(ty = _), _) then inOp;
    case (DAE.GREATEREQ(ty = _), _) then inOp;
    case (DAE.EQUAL(ty = _), _) then inOp;
    case (DAE.NEQUAL(ty = _), _) then inOp;
    case (DAE.USERDEFINED(fqName = _), _) then inOp;
    case (_, _)
      equation
        Debug.fprintln("failtrace","- Expression.setOpType failed on unknown operator");
      then  
        fail();
  end matchcontinue;
end setOpType;

public function subscriptsAppend
"function: subscriptsAppend
  This function takes a subscript list and adds a new subscript.
  But there are a few special cases.  When the last existing
  subscript is a slice, it is replaced by the slice indexed by
  the new subscript."
  input list<Subscript> inSubscriptLst;
  input DAE.Exp inSubscript;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst := matchcontinue (inSubscriptLst,inSubscript)
    local
      DAE.Exp e_1,e;
      Subscript s;
      list<Subscript> ss_1,ss;
    case ({},_) then {DAE.INDEX(inSubscript)};
    case (DAE.WHOLEDIM() :: ss,_) then DAE.INDEX(inSubscript) :: ss;
    case ({DAE.SLICE(exp = e)},_)
      equation
        e_1 = ExpressionSimplify.simplify1(DAE.ASUB(e,{inSubscript}));
      then
        {DAE.INDEX(e_1)};
    case ({(s as DAE.INDEX(exp = _))},_) then {s,DAE.INDEX(inSubscript)};
    case ((s :: ss),_)
      equation
        ss_1 = subscriptsAppend(ss, inSubscript);
      then
        (s :: ss_1);
  end matchcontinue;
end subscriptsAppend;

public function unliftArrayTypeWithSubs "
helper function for renameVarsToUnderlineVar2 unlifts array type as much as we have subscripts"
  input list<Subscript> subs;
  input Type ty;
  output Type oty;
algorithm  oty := matchcontinue(subs,ty)
  local
    list<Subscript> rest;
  case({},ty) then ty;
  case(_::rest, ty)
    equation
      ty = unliftArray(ty);
      ty = unliftArrayTypeWithSubs(rest,ty);
    then
      ty;
end matchcontinue;
end unliftArrayTypeWithSubs;

public function unliftArrayX "Function: unliftArrayX
Unlifts a type with X dimensions..."
  input Type inType;
  input Integer x;
  output Type outType;
algorithm 
  outType := matchcontinue(inType,x)
    local Type ty;
    case(inType,0) then inType;
    case(inType,x)
      equation
        ty = unliftArray(inType);
      then
        unliftArrayX(ty,x-1);
  end matchcontinue;
end unliftArrayX;

public function arrayAppend
  "Appends a new element to a DAE.ARRAY."
  input DAE.Exp head;
  input DAE.Exp rest;
  output DAE.Exp array;
algorithm
  array := matchcontinue(head, rest)
    local
      DAE.ExpType ty;
      Boolean scalar;
      list<DAE.Exp> expl;
      Integer dim;
      list<DAE.Dimension> dims;
    case (_, DAE.ARRAY(
        DAE.ET_ARRAY(ty = ty, arrayDimensions = DAE.DIM_INTEGER(dim) :: dims),
        scalar = scalar, 
        array = expl))
      equation
        dim = dim + 1;
        dims = DAE.DIM_INTEGER(dim) :: dims;
      then
        DAE.ARRAY(DAE.ET_ARRAY(ty, dims), scalar, head :: expl);
    case (_, _)
      equation
        Debug.fprintln("failtrace", "- Expression.arrayAppend failed.");
      then
        fail();
  end matchcontinue;
end arrayAppend;


public function arrayDimensionSetFirst
  "Updates the first dimension of an array type."
  input DAE.ExpType inArrayType;
  input DAE.Dimension dimension;
  output DAE.ExpType outArrayType;
algorithm
  outArrayType := matchcontinue(inArrayType, dimension)
    local
      DAE.ExpType ty;
      list<DAE.Dimension> rest_dims;
    case (DAE.ET_ARRAY(ty = ty, arrayDimensions = _ :: rest_dims), _)
      then DAE.ET_ARRAY(ty, dimension :: rest_dims);
  end matchcontinue;
end arrayDimensionSetFirst;

/***************************************************/
/* Getter  */
/***************************************************/

public function expReal "returns the real value if expression is constant Real"
  input DAE.Exp exp;
  output Real r;
algorithm
  r := matchcontinue(exp) local Integer i;
    case(DAE.RCONST(r)) then r;
    case(DAE.ICONST(i)) then intReal(i);
    case(DAE.CAST(_,DAE.ICONST(i))) then intReal(i);
  end matchcontinue;
end expReal;

public function expInt "returns the int value if expression is constant Integer"
	input DAE.Exp exp;
	output Integer i;
algorithm
	i := matchcontinue(exp) local Integer i2;
    case (DAE.ICONST(integer = i2)) then i2;
    case (DAE.ENUM_LITERAL(index = i2)) then i2;
	end matchcontinue;
end expInt;

public function varName "Returns the name of a Var"
  input Var v;
  output String name;
algorithm
  name := matchcontinue(v)
    case(DAE.COMPLEX_VAR(name,_)) then name;
  end matchcontinue;
end varName;

public function varType "Returns the type of a Var"
  input Var v;
  output Type tp;
algorithm
  tp := matchcontinue(v)
    case(DAE.COMPLEX_VAR(_,tp)) then tp;
  end matchcontinue;
end varType;

public function expCref
"function: expCref
  Returns the componentref if DAE.Exp is a CREF,"
  input DAE.Exp inExp;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inExp)
    local ComponentRef cr;
    case (DAE.CREF(componentRef = cr)) then cr;
  end matchcontinue;
end expCref;

public function expCrefTuple
"function: expCrefTuple
  Returns the componentref if the expression in inTuple is a CREF."
  input tuple<DAE.Exp, Boolean> inTuple;
  output ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inTuple)
    local ComponentRef cr;
    case ((DAE.CREF(componentRef = cr),_)) then cr;
  end matchcontinue;
end expCrefTuple;

public function expCrefInclIfExpFactors
"function: expCrefInclIfExpFactors
  Returns the componentref if DAE.Exp is a CREF, or the factors of CREF if expression is an if expression.
  This is used in e.g. the tearing algorithm to detect potential division by zero in
  expressions like 1/(if b then 1.0 else x) which could lead to division by zero if b is false and x is 0; "
  input DAE.Exp inExp;
  output list<ComponentRef> outComponentRefs;
algorithm
  outComponentRefs:=
  matchcontinue (inExp)
    local ComponentRef cr; DAE.Exp c,tb,fb;
      list<DAE.Exp> f;
      list<ComponentRef> crefs;
    case (DAE.CREF(componentRef = cr)) then {cr};
    case(DAE.IFEXP(c,tb,fb)) equation
      f = Util.listSelect(listAppend(factors(tb),factors(fb)),isCref);
      crefs = Util.listMap(f,expCref);
    then crefs;
  end matchcontinue;
end expCrefInclIfExpFactors;

public function boolExp "returns the boolean constant expression of a BOOL"
input DAE.Exp e;
output Boolean b;
algorithm
  b := matchcontinue(e)
    case(DAE.BCONST(b)) then b;
  end matchcontinue;
end boolExp;

public function getBoolConst "returns the expression as a Boolean value.
"
input DAE.Exp e;
output Boolean b;
algorithm
  b := matchcontinue(e)
    case(DAE.BCONST(b)) then b;
  end matchcontinue;
end getBoolConst;

public function getRealConst "returns the expression as a Real value.
Integer constants are cast to Real"
input DAE.Exp e;
output Real v;
algorithm
  v := matchcontinue(e)
  local Integer i;
    case(DAE.RCONST(v)) then v;
    case(DAE.CAST(_,e)) then getRealConst(e);
    case(DAE.ICONST(i)) then intReal(i);
  end matchcontinue;
end getRealConst;

// stefan
public function unboxExpType
"function: unboxExpType
	takes a type, and if it is boxed, unbox it
	otherwise return the given type"
	input Type inType;
	output Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      Type ty;
    case(DAE.ET_BOXED(ty)) then ty;
    case(ty) then ty;
  end matchcontinue;
end unboxExpType;

public function subscriptExp
"function: subscriptExp
  Returns the expression in a subscript index.
  If the subscript is not an index the function fails.x"
  input Subscript inSubscript;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inSubscript)
    local DAE.Exp e;
    case (DAE.INDEX(exp = e)) then e;
  end matchcontinue;
end subscriptExp;

public function nthArrayExp
"function: nthArrayExp
  author: PA
  Returns the nth expression of an array expression."
  input DAE.Exp inExp;
  input Integer inInteger;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inInteger)
    local
      DAE.Exp e;
      list<DAE.Exp> expl;
      Integer indx;
    case (DAE.ARRAY(array = expl),indx)
      equation
        e = listNth(expl, indx);
      then
        e;
  end matchcontinue;
end nthArrayExp;

public function expLastSubs
"function: expLastSubs
  Return the last subscripts of a Exp"
  input DAE.Exp inExp;
  output list<Subscript> outSubscriptLst;
algorithm
  outSubscriptLst:=
  matchcontinue (inExp)
    local
      ComponentRef cr;
      list<Subscript> subs;
      DAE.Exp e;
    case (DAE.CREF(componentRef=cr))
      equation
        subs = ComponentReference.crefLastSubs(cr);
      then subs;
    case (DAE.UNARY(exp=e))
      equation
        subs = expLastSubs(e);
      then subs;
  end matchcontinue;
end expLastSubs;

public function arrayDimension "
Author BZ
Get dimension of array.
"
	input Type tp;
  output list<DAE.Dimension> dims;
algorithm
  dims := matchcontinue(tp)
    case(DAE.ET_ARRAY(_,dims)) then dims;
    case(_) then {};
  end matchcontinue;
end arrayDimension;

public function arrayTypeDimensions
"Return the array dimensions of a type."
	input Type tp;
  output list<DAE.Dimension> dims;
algorithm
  dims := matchcontinue(tp)
    case(DAE.ET_ARRAY(_,dims)) then dims;
  end matchcontinue;
end arrayTypeDimensions;

public function subscriptDimensions "Function: subscriptDimensions
Returns the dimensionality of the subscript expression
"
  input list<Subscript> insubs;
  output list<DAE.Dimension> oint;
algorithm oint := matchcontinue(insubs)
  local
    Subscript ss;
    list<Subscript> subs;
    list<DAE.Exp> expl;
    Integer x;
    list<DAE.Dimension> recursive;
    DAE.Exp e;

  case ({}) then {};
    
  case ((ss as DAE.INDEX(DAE.ICONST(x)))::subs) 
    equation
      recursive = subscriptDimensions(subs);
    then 
      DAE.DIM_INTEGER(x):: recursive;      
    
  case ((ss as DAE.WHOLEDIM) :: subs)
    equation
      recursive = subscriptDimensions(subs);
    then
      DAE.DIM_UNKNOWN() :: recursive;

  case ((ss as DAE.INDEX(exp = e)) :: subs)
    equation
      recursive = subscriptDimensions(subs);
    then
      DAE.DIM_EXP(e) :: recursive;
       
  case (ss :: subs)
    local String sub_str;
    equation
      true = RTOpts.debugFlag("failtrace");
      sub_str = ExpressionDump.subscriptString(ss);
      Debug.fprintln("failtrace", "- Expression.subscriptDimensions failed on " +& sub_str);
    then
      fail();
end matchcontinue;
end subscriptDimensions;

public function arrayEltType
"function: arrayEltType
   Returns the element type of an array expression."
  input Type inType;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inType)
    local Type t;
    case (DAE.ET_ARRAY(ty = t)) then arrayEltType(t);
    case (t) then t;
  end matchcontinue;
end arrayEltType;

public function sizeOf
"Returns the size of an ET_ARRAY or ET_COMPLEX"
  input DAE.ExpType inType;
  output Integer i;
algorithm
  i := matchcontinue inType
    local
      list<DAE.Dimension> ad;
      Integer nr;
      list<Integer> lstInt;
      list<Var> varLst;
    // count the variables in array
    case DAE.ET_ARRAY(arrayDimensions = ad)
      equation
        nr = dimensionSize(Util.listReduce(ad, dimensionsMult));
      then
        nr;
    // count the variables in record
    case DAE.ET_COMPLEX(varLst = varLst)
      equation
        lstInt = Util.listMap(Util.listMap(varLst, varType), sizeOf);
        nr = Util.listReduce(lstInt, intAdd);
      then
        nr;
    // for all other consider it just 1 variable
    case _ then 1;
  end matchcontinue;
end sizeOf;

public function dimensionSize
  "Extracts an integer from an array dimension"
  input DAE.Dimension dim;
  output Integer value;
algorithm
  value := matchcontinue(dim)
    local
      Integer i;
    case DAE.DIM_INTEGER(integer = i) then i;
    case DAE.DIM_ENUM(size = i) then i; 
  end matchcontinue;
end dimensionSize;

public function typeof "
function typeof
  Retrieves the Type of the Expression"
  input DAE.Exp inExp;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inExp)
    local
      Type tp;
      Operator op;
      DAE.Exp e1,e2,e3,e;
      list<DAE.Exp> explist;
      list<Type> tylist;
      Absyn.Path p;
    case (DAE.ICONST(integer = _)) then DAE.ET_INT();
    case (DAE.RCONST(real = _)) then DAE.ET_REAL();
    case (DAE.SCONST(string = _)) then DAE.ET_STRING();
    case (DAE.BCONST(bool = _)) then DAE.ET_BOOL();
    case (DAE.ENUM_LITERAL(name = p)) then DAE.ET_ENUMERATION(p, {}, {}); 
    case (DAE.CREF(ty = tp)) then tp;
    case (DAE.BINARY(operator = op)) then typeofOp(op);
    case (DAE.UNARY(operator = op)) then typeofOp(op);
    case (DAE.LBINARY(operator = op)) then typeofOp(op);
    case (DAE.LUNARY(operator = op)) then typeofOp(op);
    case (DAE.RELATION(operator = op)) then typeofOp(op);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)) then typeof(e2);
    case (DAE.CALL(path = _,ty=tp)) then tp;
    case (DAE.PARTEVALFUNCTION(path = _,ty=tp)) then tp;
    case (DAE.ARRAY(ty = tp)) then tp;
    case (DAE.MATRIX(ty = tp)) then tp;
    case (DAE.RANGE(ty = tp)) then tp;
    case (DAE.CAST(ty = tp)) then tp;
    case (DAE.ASUB(exp = e,sub=explist)) equation
      tp = unliftArrayTypeWithSubs(Util.listMap(explist,makeIndexSubscript) ,typeof(e));
    then tp;
    case (DAE.CODE(ty = tp)) then tp;
    case (DAE.REDUCTION(expr = e)) then typeof(e);
    case (DAE.END()) then DAE.ET_OTHER();  /* Can be any type. */
    case (DAE.SIZE(_,NONE())) then DAE.ET_INT();
    case (DAE.SIZE(_,SOME(_))) then DAE.ET_ARRAY(DAE.ET_INT(),{DAE.DIM_UNKNOWN()});

    //MetaModelica extension
    case (DAE.LIST(ty = tp)) then DAE.ET_LIST(tp); // was tp, but the type of a LIST is a LIST
    case (DAE.CONS(ty = tp)) then DAE.ET_LIST(tp); // CONS creates lists
    case (DAE.META_TUPLE(explist))
      equation
        tylist = Util.listMap(explist, typeof);
      then DAE.ET_METATUPLE(tylist);
    case (DAE.META_OPTION(SOME(e)))
      equation
        tp = typeof(e);
      then DAE.ET_METAOPTION(tp);
    case (DAE.META_OPTION(NONE())) then DAE.ET_METAOPTION(DAE.ET_OTHER());
    case (DAE.METARECORDCALL(path=_)) then DAE.ET_UNIONTYPE();
    case e
      equation
        Debug.fprintln("failtrace", "- Expression.typeof failed for " +& ExpressionDump.printExpStr(e));
      then fail();
  end matchcontinue;
end typeof;

public function typeofOp
"function: typeofOp
  Helper function to typeof"
  input Operator inOperator;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inOperator)
    local Type t;
    case (DAE.ADD(ty = t)) then t;
    case (DAE.SUB(ty = t)) then t;
    case (DAE.MUL(ty = t)) then t;
    case (DAE.DIV(ty = t)) then t;
    case (DAE.POW(ty = t)) then t;
    case (DAE.UMINUS(ty = t)) then t;
    case (DAE.UPLUS(ty = t)) then t;
    case (DAE.UMINUS_ARR(ty = t)) then t;
    case (DAE.UPLUS_ARR(ty = t)) then t;
    case (DAE.ADD_ARR(ty = t)) then t;
    case (DAE.SUB_ARR(ty = t)) then t;
    case (DAE.MUL_ARR(ty = t)) then t;
    case (DAE.DIV_ARR(ty = t)) then t;
    case (DAE.MUL_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.MUL_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.ADD_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.ADD_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.SUB_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.SUB_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.MUL_SCALAR_PRODUCT(ty = t)) then t;
    case (DAE.MUL_MATRIX_PRODUCT(ty = t)) then t;
    case (DAE.DIV_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.DIV_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.POW_ARRAY_SCALAR(ty = t)) then t;
    case (DAE.POW_SCALAR_ARRAY(ty = t)) then t;
    case (DAE.POW_ARR(ty = t)) then t;
    case (DAE.POW_ARR2(ty = t)) then t;
    case (DAE.AND()) then DAE.ET_BOOL();
    case (DAE.OR()) then DAE.ET_BOOL();
    case (DAE.NOT()) then DAE.ET_BOOL();
    case (DAE.LESS(ty = t)) then t;
    case (DAE.LESSEQ(ty = t)) then t;
    case (DAE.GREATER(ty = t)) then t;
    case (DAE.GREATEREQ(ty = t)) then t;
    case (DAE.EQUAL(ty = t)) then t;
    case (DAE.NEQUAL(ty = t)) then t;
    case (DAE.USERDEFINED(fqName = t))
      local Absyn.Path t;
      then
        DAE.ET_OTHER();
  end matchcontinue;
end typeofOp;

public function getRelations
"function: getRelations
  Retrieve all function sub expressions in an expression."
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      DAE.Exp e,e1,e2,cond,tb,fb;
      list<DAE.Exp> rellst1,rellst2,rellst,rellst3,rellst4,xs;
      Type t;
      Boolean sc;
    case ((e as DAE.RELATION(exp1 = _))) then {e};
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
    case (_) then {};
  end matchcontinue;
end getRelations;

public function allTerms
"simliar to terms, but also perform expansion of
 multiplications to reveal more terms, like for instance:
 allTerms((a+b)*(b+c)) => {a*b,a*c,b*b,b*c}"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      list<DAE.Exp> f1,f2,res,f2_1;
      DAE.Exp e1,e2,e;
      Type tp;
      ComponentRef cr;

   case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = _),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        res = listAppend(f1, f2);
      then
        res;
   case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = _),exp2 = e2))
     equation
       f1 = allTerms(e1);
       f2 = allTerms(e2);
       f2_1 = Util.listMap(f2, negate);
       res = listAppend(f1, f2_1);
     then
       res;

   case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = _),exp2 = e2))
      equation
        f1 = allTerms(e1);
        f2 = allTerms(e2);
        res = listAppend(f1, f2);
      then
        res;
   case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = _),exp2 = e2))
     equation
       f1 = allTerms(e1);
       f2 = allTerms(e2);
       f2_1 = Util.listMap(f2, negate);
       res = listAppend(f1, f2_1);
     then
       res;

       /* terms( a*(b+c)) => {a*b, c*b} */
   case (e as DAE.BINARY(e1,DAE.MUL(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_ARR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_SCALAR_ARRAY(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;    
   case (e as DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e2);
     f1 = Util.listMap1(f1,makeProduct,e1);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1; 
     /* terms( (b+c)*a) => {b*a, c*a} */
   case (e as DAE.BINARY(e1,DAE.MUL(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_ARR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_SCALAR_ARRAY(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,makeProduct,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;          
   /* terms( (b+c)/a) => {b/a, c/a} */
   case (e as DAE.BINARY(e1,DAE.DIV(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,expDiv,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;
   case (e as DAE.BINARY(e1,DAE.DIV_ARR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,expDiv,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;  
   case (e as DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,expDiv,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1; 
   case (e as DAE.BINARY(e1,DAE.DIV_SCALAR_ARRAY(tp),e2)) equation
     (f1 as _::_::_) = allTerms(e1);
     f1 = Util.listMap1(f1,expDiv,e2);
     f1 = Util.listFlatten(Util.listMap(f1,allTerms));
   then f1;              
   case ((e as DAE.BINARY(operator = DAE.MUL(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.MUL_ARR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.MUL_SCALAR_ARRAY(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.MUL_ARRAY_SCALAR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV_ARR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_ARR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_ARR2(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_ARRAY_SCALAR(ty = _)))) then {e};
   case ((e as DAE.BINARY(operator = DAE.POW_SCALAR_ARRAY(ty = _)))) then {e};
   case ((e as DAE.CREF(componentRef = cr))) then {e};
   case ((e as DAE.ICONST(integer = _))) then {e};
   case ((e as DAE.RCONST(real = _))) then {e};
   case ((e as DAE.SCONST(string = _))) then {e};
   case ((e as DAE.UNARY(operator = _))) then {e};
   case ((e as DAE.IFEXP(expCond = _))) then {e};
   case ((e as DAE.CALL(path = _))) then {e};
   case ((e as DAE.PARTEVALFUNCTION(path = _))) then {e};
   case ((e as DAE.ARRAY(ty = _))) then {e};
   case ((e as DAE.MATRIX(ty = _))) then {e};
   case ((e as DAE.RANGE(ty = _))) then {e};
   case ((e as DAE.CAST(ty = _))) then {e};
   case ((e as DAE.ASUB(exp = _))) then {e};
   case ((e as DAE.SIZE(exp = _))) then {e};
   case ((e as DAE.REDUCTION(path = _))) then {e};
    case (_) then {};
  end matchcontinue;
end allTerms;

public function terms "
function: terms
  author: PA
  Returns the terms of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      list<DAE.Exp> f1,f2,res,f2_1;
      DAE.Exp e1,e2,e;
      Type tp;
      ComponentRef cr;
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = _),exp2 = e2))
      equation
        f1 = terms(e1);
        f2 = terms(e2);
        res = listAppend(f1, f2);
      then
        res;
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = _),exp2 = e2))
      equation
        f1 = terms(e1);
        f2 = terms(e2);
        f2_1 = Util.listMap(f2, negate);
        res = listAppend(f1, f2_1);
      then
        res;
    case ((e as DAE.BINARY(operator = DAE.MUL(ty = _)))) then {e};
    case ((e as DAE.BINARY(operator = DAE.DIV(ty = _)))) then {e};
    case ((e as DAE.BINARY(operator = DAE.POW(ty = _)))) then {e};
    case ((e as DAE.CREF(componentRef = cr))) then {e};
    case ((e as DAE.ICONST(integer = _))) then {e};
    case ((e as DAE.RCONST(real = _))) then {e};
    case ((e as DAE.SCONST(string = _))) then {e};
    case ((e as DAE.UNARY(operator = _))) then {e};
    case ((e as DAE.IFEXP(expCond = _))) then {e};
    case ((e as DAE.CALL(path = _))) then {e};
    case ((e as DAE.PARTEVALFUNCTION(path = _))) then {e};
    case ((e as DAE.ARRAY(ty = _))) then {e};
    case ((e as DAE.MATRIX(ty = _))) then {e};
    case ((e as DAE.RANGE(ty = _))) then {e};
    case ((e as DAE.CAST(ty = _))) then {e};
    case ((e as DAE.ASUB(exp = _))) then {e};
    case ((e as DAE.SIZE(exp = _))) then {e};
    case ((e as DAE.REDUCTION(path = _))) then {e};
    case (_) then {};
  end matchcontinue;
end terms;

public function quotient
"function: quotient
  author: PA
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
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = _),exp2 = e2)) then (e1,e2);  /* (numerator,denominator) */
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2))
      equation
        (p,q) = quotient(e1);
        tp = typeof(p);
      then
        (DAE.BINARY(e2,DAE.MUL(tp),p),q);
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2))
      equation
        (p,q) = quotient(e2);
        tp = typeof(p);
      then
        (DAE.BINARY(e1,DAE.MUL(tp),p),q);
  end matchcontinue;
end quotient;

public function factors
"function: factors
  Returns the factors of the expression if any as a list of expressions"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExp)
    local
      list<DAE.Exp> f1,f2,f1_1,f2_1,res,f2_2;
      DAE.Exp e1,e2,e;
      ComponentRef cr;
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2))
      equation
        f1 = factors(e1) "Both subexpression has factors" ;
        f2 = factors(e2);
        f1_1 = noFactors(f1, e1);
        f2_1 = noFactors(f2, e2);
        res = listAppend(f1_1, f2_1);
      then
        res;
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = DAE.ET_REAL()),exp2 = e2))
      equation
        f1 = factors(e1);
        f2 = factors(e2);
        f1_1 = noFactors(f1, e1);
        f2_1 = noFactors(f2, e2);
        f2_2 = inverseFactors(f2_1);
        res = listAppend(f1_1, f2_2);
      then
        res;
    case ((e as DAE.CREF(componentRef = cr))) then {e};
    case ((e as DAE.BINARY(exp1 = _))) then {e};
    case ((e as DAE.ICONST(integer = _))) then {e};
    case ((e as DAE.RCONST(real = _))) then {e};
    case ((e as DAE.SCONST(string = _))) then {e};
    case ((e as DAE.UNARY(operator = _))) then {e};
    case ((e as DAE.IFEXP(expCond = _))) then {e};
    case ((e as DAE.CALL(path = _))) then {e};
    case ((e as DAE.PARTEVALFUNCTION(path = _))) then {e};
    case ((e as DAE.ARRAY(ty = _))) then {e};
    case ((e as DAE.MATRIX(ty = _))) then {e};
    case ((e as DAE.RANGE(ty = _))) then {e};
    case ((e as DAE.CAST(ty = _))) then {e};
    case ((e as DAE.ASUB(exp = _))) then {e};
    case ((e as DAE.SIZE(exp = _))) then {e};
    case ((e as DAE.REDUCTION(path = _))) then {e};
    case (_) then {};
  end matchcontinue;
end factors;

protected function noFactors
"function noFactors
  Helper function to factors.
  If a factor list is empty, the expression has no subfactors.
  But the complete expression is then a factor for larger
  expressions, returned by this function."
  input list<DAE.Exp> inExpLst;
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inExp)
    local
      DAE.Exp e;
      list<DAE.Exp> lst;
    case ({},e) then {e};
    case (lst,_) then lst;
  end matchcontinue;
end noFactors;

public function inverseFactors
"function inverseFactors
  Takes a list of expressions and returns
  each expression in the list inversed.
  For example: inverseFactors {a, 3+b} => {1/a, 1/3+b}"
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst)
    local
      list<DAE.Exp> es_1,es;
      Type tp2,tp;
      DAE.Exp e1,e2,e;
    case ({}) then {};
    case ((DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2) :: es))
      equation
        es_1 = inverseFactors(es);
        tp2 = typeof(e2);
      then
        (DAE.BINARY(e1,DAE.POW(tp),DAE.UNARY(DAE.UMINUS(tp2),e2)) :: es_1);
    case ((e :: es))
      equation
        DAE.ET_REAL() = typeof(e);
        es_1 = inverseFactors(es);
      then
        (DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),e) :: es_1);
    case ((e :: es))
      equation
        DAE.ET_INT() = typeof(e);
        es_1 = inverseFactors(es);
      then
        (DAE.BINARY(DAE.ICONST(1),DAE.DIV(DAE.ET_INT()),e) :: es_1);
  end matchcontinue;
end inverseFactors;

public function getTermsContainingX
"function getTermsContainingX
  Retrieves all terms of an expression containng a variable,
  given as second argument (in the form of an Exp)"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp1;
  output DAE.Exp outExp2;
algorithm
  (outExp1,outExp2) := matchcontinue (inExp1,inExp2)
    local
      DAE.Exp xt1,nonxt1,xt2,nonxt2,xt,nonxt,e1,e2,cr,e;
      Type ty;
      Boolean res;
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.ADD(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.ADD(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.SUB(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.SUB(ty),nonxt2);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UPLUS(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UPLUS(ty),xt1);
        nonxt = DAE.UNARY(DAE.UPLUS(ty),nonxt1);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UMINUS(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UMINUS(ty),xt1);
        nonxt = DAE.UNARY(DAE.UMINUS(ty),nonxt1);
      then
        (xt,nonxt);
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.ADD_ARR(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.ADD_ARR(ty),nonxt2);
      then
        (xt,nonxt);      
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = ty),exp2 = e2),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e1, cr);
        (xt2,nonxt2) = getTermsContainingX(e2, cr);
        xt = DAE.BINARY(xt1,DAE.SUB_ARR(ty),xt2);
        nonxt = DAE.BINARY(nonxt1,DAE.SUB_ARR(ty),nonxt2);
      then
        (xt,nonxt);      
    case (DAE.UNARY(operator = DAE.UPLUS_ARR(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UPLUS_ARR(ty),xt1);
        nonxt = DAE.UNARY(DAE.UPLUS_ARR(ty),nonxt1);
      then
        (xt,nonxt);
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(ty = ty),exp = e),(cr as DAE.CREF(componentRef = _)))
      equation
        (xt1,nonxt1) = getTermsContainingX(e, cr);
        xt = DAE.UNARY(DAE.UMINUS_ARR(ty),xt1);
        nonxt = DAE.UNARY(DAE.UMINUS_ARR(ty),nonxt1);
      then
        (xt,nonxt);            
    case (e,(cr as DAE.CREF(componentRef = _)))
      equation
        res = expContains(e, cr);
        xt = Util.if_(res, e, DAE.RCONST(0.0));
        nonxt = Util.if_(res, DAE.RCONST(0.0), e);
      then
        (xt,nonxt);
    case (e,cr)
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

public function countBinary "counts the number of binary operations in an expression"
  input DAE.Exp e;
  output Integer count;
algorithm
  count := matchcontinue(e)
    local DAE.Exp e1,e2,e3; list<DAE.Exp> expl; list<list<tuple<DAE.Exp,Boolean>>> mexpl;
    case(DAE.BINARY(e1,_,e2)) 
      equation
        count = 1 + countBinary(e1) + countBinary(e2);
      then count;
    case(DAE.IFEXP(e1,e2,e3)) 
      equation
        count =  countBinary(e2) + countBinary(e3);
      then count;
    case(DAE.CALL(expLst = expl)) 
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.PARTEVALFUNCTION(expList = expl))
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.ARRAY(array = expl)) 
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.MATRIX(scalar=mexpl)) 
      equation
        expl = Util.listFlatten(Util.listListMap(mexpl,Util.tuple21));
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.RANGE(_,e1,SOME(e2),e3)) 
      equation
        count = countBinary(e1) + countBinary(e2) + countBinary(e3);
      then count;
    case(DAE.RANGE(_,e1,NONE(),e3)) 
      equation
        count = countBinary(e1) + countBinary(e3);
      then count;
    case(DAE.TUPLE(expl)) 
      equation
        count = Util.listReduce(Util.listMap(expl,countBinary),intAdd);
      then count;
    case(DAE.CAST(_,e)) then countBinary(e);
    case(DAE.ASUB(e,_)) then countBinary(e);
    case(_) then 0;
  end matchcontinue;
end countBinary;

public function countMulDiv "counts the number of multiplications and divisions in an expression"
  input DAE.Exp e;
  output Integer count;
algorithm
  count := matchcontinue(e)
    local DAE.Exp e1,e2,e3; list<DAE.Exp> expl; list<list<tuple<DAE.Exp,Boolean>>> mexpl;
    case(DAE.BINARY(e1,DAE.MUL(_),e2)) equation
      count = 1 + countMulDiv(e1) + countMulDiv(e2);
    then count;
    case(DAE.BINARY(e1,DAE.DIV(_),e2)) equation
      count = 1 + countMulDiv(e1) + countMulDiv(e2);
    then count;
    case(DAE.IFEXP(e1,e2,e3)) equation
      count =  countMulDiv(e2) + countMulDiv(e3);
    then count;
    case(DAE.CALL(expLst = expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.PARTEVALFUNCTION(expList = expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.ARRAY(array = expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.MATRIX(scalar=mexpl)) equation
      expl = Util.listFlatten(Util.listListMap(mexpl,Util.tuple21));
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.RANGE(_,e1,SOME(e2),e3)) equation
      count = countMulDiv(e1) + countMulDiv(e2) + countMulDiv(e3);
    then count;
    case(DAE.RANGE(_,e1,NONE(),e3)) equation
      count = countMulDiv(e1) + countMulDiv(e3);
    then count;
    case(DAE.TUPLE(expl)) equation
      count = Util.listReduce(Util.listMap(expl,countMulDiv),intAdd);
    then count;
    case(DAE.CAST(_,e)) then countMulDiv(e);
    case(DAE.ASUB(e,_)) then countMulDiv(e);
    case(_) then 0;
  end matchcontinue;
end countMulDiv;

public function realIfRealInArray "function: realIfRealInArray
this function takes a list of numbers. If one of them is a real, type real is returned.
Otherwise Inteteger. Fails on other types."
  input list<DAE.Exp> inExps;
  output Type otype;
algorithm otype := matchcontinue(inExps)
  local
    DAE.Exp e1,e2;
    list<DAE.Exp> expl;
    Type ty,rty;
    case({}) then DAE.ET_INT();
  case( e1 :: expl)
    equation
      (ty as DAE.ET_INT()) = typeof(e1);
      rty = realIfRealInArray(expl);
      then
        rty;
  case(e1 :: expl)
    equation
    (ty as DAE.ET_REAL()) = typeof(e1);
      rty = realIfRealInArray(expl);
    then
      ty;
  case(_)
    equation
    Debug.fprint("failtrace"," realIfRealInArray got non array/real Expressions \n");
    then
      fail();
  end matchcontinue;
end realIfRealInArray;

public function flattenArrayExpToList "returns all non-array expressions of an array expression as a long list
E.g. {[1,2;3,4],[4,5;6,7]} => {1,2,3,4,4,5,6,7}"
  input DAE.Exp e;
  output list<DAE.Exp> expLst;
algorithm
  expLst := matchcontinue(e)
  local
    list<DAE.Exp> expl;
    list<list<tuple<DAE.Exp,Boolean>>> mexpl;
    case(DAE.ARRAY(array=expl)) equation
      expLst = Util.listFlatten(Util.listMap(expl,flattenArrayExpToList));
    then expLst;
    case(DAE.MATRIX(scalar=mexpl)) equation
      expLst = Util.listFlatten(Util.listMap(Util.listFlatten(Util.listListMap(mexpl,Util.tuple21)),flattenArrayExpToList));
    then expLst;
    case(e) then {e};
  end matchcontinue;
end flattenArrayExpToList;

/***************************************************/
/* generate  */
/***************************************************/

public function makeNoEvent " adds a noEvent call around an expression"
input DAE.Exp e1;
output DAE.Exp res;
algorithm
  res := DAE.CALL(Absyn.IDENT("noEvent"),{e1},false,true,DAE.ET_BOOL(),DAE.NO_INLINE());
end makeNoEvent;

public function makeNestedIf "creates a nested if expression given a list of conditions and
guared expressions and a default value (the else branch)"
  input list<DAE.Exp> conds "conditions";
  input list<DAE.Exp> tbExps " guarded expressions, for each condition";
  input DAE.Exp fExp "default value, else branch";
  output DAE.Exp ifExp;
algorithm
  ifExp := matchcontinue(conds,tbExps,fExp)
  local DAE.Exp c,tbExp;
    case({c},{tbExp},fExp)
    then DAE.IFEXP(c,tbExp,fExp);
    case(c::conds,tbExp::tbExps,fExp) equation
      ifExp = makeNestedIf(conds,tbExps,fExp);
    then DAE.IFEXP(c,tbExp,ifExp);
  end matchcontinue;
end makeNestedIf;

public function makeCrefExp
"function makeCrefExp
  Makes an expression of a component reference, given also a type"
  input ComponentRef cref;
  input Type tp;
  output DAE.Exp e;
algorithm 
  e:= DAE.CREF(cref,tp);
end makeCrefExp;

public function makeCrefExpNoType "similar to makeCrefExp but picks type from componentref"
input ComponentRef cref;
output DAE.Exp e;
algorithm
  e := makeCrefExp(cref,ComponentReference.crefTypeConsiderSubs(cref));
end makeCrefExpNoType;

public function crefExp "
Author: BZ, 2008-08
generate an DAE.CREF(ComponentRef, Type) from a ComponenRef, make array type correct from subs"
  input ComponentRef cr;
  output DAE.Exp cref;
algorithm cref := matchcontinue(cr)
  local
    Type ty1,ty2;
    list<Subscript> subs;
  case(cr)
    equation
      (ty1 as DAE.ET_ARRAY(_,_)) = ComponentReference.crefLastType(cr);
      subs = ComponentReference.crefLastSubs(cr);
      ty2 = unliftArrayTypeWithSubs(subs,ty1);
    then
      DAE.CREF(cr,ty2);
  case(cr)
    equation
      ty1 = ComponentReference.crefLastType(cr);
    then
      DAE.CREF(cr,ty1);
end matchcontinue;
end crefExp;

public function makeRealArray
"function: makeRealArray
  Construct an array node of an DAE.Exp list of type REAL."
  input list<DAE.Exp> inExpLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpLst)
    local list<DAE.Exp> expl;
    case (expl) then DAE.ARRAY(DAE.ET_REAL(),false,expl);
  end matchcontinue;
end makeRealArray;

public function makeRealAdd
"function: makeRealAdd
  Construct an add node of the two expressions of type REAL."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inExp2)
    local DAE.Exp e1,e2;
    case (e1,e2) then DAE.BINARY(e1,DAE.ADD(DAE.ET_REAL()),e2);
  end matchcontinue;
end makeRealAdd;

public function expAdd
"function: expAdd
  author: PA
  Adds two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
  Type tp;
  Boolean b;
  Operator op;
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp) "	array_elt_type(tp) => tp\'" ;
  op := Util.if_(b,DAE.ADD_ARR(tp),DAE.ADD(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expAdd;

public function expSub
"function: expMul
  author: PA
  Subtracts two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
  Type tp;
  Boolean b;
  Operator op;
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp);
  op := Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expSub;

public function makeDiff
"Takes two expressions and create
 the difference between them"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp res;
algorithm
  res := matchcontinue(e1,e2)
    local
      Type etp;
      Boolean scalar;
      Operator op;

    case(e1,e2) equation
      true = isZero(e2);
    then e1;

    case(e1,e2) equation
      true = isZero(e1);
    then negate(e2);

    case(e1,e2) then expSub(e1,e2);
  end matchcontinue;
end makeDiff;

public function makeSum
"function: makeSum
  Takes a list of expressions an makes a sum
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
      list<Ident> explst;
      Ident str;
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
        op = Util.if_(b,DAE.ADD_ARR(tp),DAE.ADD(tp));
			then DAE.BINARY(e1, op, e2);			  
				//res = DAE.BINARY(e1, DAE.ADD(tp), e2);
			//then res;
    /*case ({e1,e2})
      equation
        b1 = isZero(e1);
        tp = typeof(e1) "Take type info from e1, ok since type checking already performed." ;
        res = DAE.BINARY(e1,DAE.ADD(tp),e2);
				res = Util.if_(b1,e2,res);
      then
        res;*/
    case ((e1 :: rest))
      equation
        b1 = isZero(e1);
        e2 = makeSum(rest);
        tp = typeof(e2);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.ADD_ARR(tp),DAE.ADD(tp));        
        res = DAE.BINARY(e1,op,e2);
        res = Util.if_(b1,e2,res);
      then
        res;
    case (lst)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace","-Expression.makeSum failed, DAE.Exp lst:");
        explst = Util.listMap(lst, ExpressionDump.printExpStr);
        str = Util.stringDelimitList(explst, ", ");
        Debug.fprint("failtrace",str);
        Debug.fprint("failtrace","\n");
      then
        fail();
  end matchcontinue;
end makeSum;

public function expMul
"function: expMul
  author: PA
  Multiplies two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
  Type tp;
  Boolean b;
  Operator op;
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp) "	array_elt_type(tp) => tp\'" ;
  op := Util.if_(b,DAE.MUL_ARR(tp),DAE.MUL(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expMul;

public function makeProduct
"Makes a product of two expressions"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp product;
algorithm
  product := makeProductLst({e1,e2});
end makeProduct;

public function makeProductLst
"function: makeProductLst
  Takes a list of expressions an makes a product
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
      list<Ident> explst;
      Ident str;
      Boolean b_isZero,b1,b2;
    case ({}) then DAE.RCONST(1.0);
    case ({e1})
      equation
        b_isZero = isZero(e1);
        res = Util.if_(b_isZero,makeConstZero(typeof(e1)),e1);
      then res;
    case ((e :: es)) /* to prevent infinite recursion, disregard constant 1. */
      equation
        true = isConstOne(e);
        res = makeProductLst(es);
        b_isZero = isZero(res);
        res = Util.if_(b_isZero,makeConstZero(typeof(e)),res);
      then
        res;
     case ((e :: es)) /* to prevent infinite recursion, disregard constant 0. */
      equation
        true = isZero(e);
        res = makeConstZero(typeof(e));
      then
        res;
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
        res = Util.if_(b_isZero,makeConstZero(typeof(e)),res);
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
        res = Util.if_(b_isZero,makeConstZero(tp),res);
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
        res = Util.if_(b_isZero,makeConstZero(typeof(e1)),res);
      then
				res;
    case (lst)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace","-Expression.makeProductLst failed, DAE.Exp lst:");
        explst = Util.listMap(lst, ExpressionDump.printExpStr);
        str = Util.stringDelimitList(explst, ", ");
        Debug.fprint("failtrace",str);
        Debug.fprint("failtrace","\n");
      then
        fail();
  end matchcontinue;
end makeProductLst;

protected function checkIfOther
"Checks if a type is OTHER and in that case returns REAL instead.
 This is used to make proper transformations in case OTHER is
 retrieved from subexpression where it should instead be REAL or INT"
input Type inTp;
output Type outTp;
algorithm
  outTp := matchcontinue(inTp)
    case (DAE.ET_OTHER()) then DAE.ET_REAL();
    case (inTp) then inTp;
  end matchcontinue;
end checkIfOther;

public function expDiv "
function expDiv
  author: PA
  Divides two scalar expressions."
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outExp;
  Type tp;
  Boolean b;
  Operator op;  
algorithm
  tp := typeof(e1);
  b := DAEUtil.expTypeArray(tp);
  op := Util.if_(b,DAE.DIV_ARR(tp),DAE.DIV(tp));
  outExp := DAE.BINARY(e1,op,e2);
end expDiv;

public function makeDiv "Takes two expressions and create a division"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp res;
algorithm
  res := matchcontinue(e1,e2)
    case(e1,e2) equation
      true = isZero(e1);
    then e1;
    case(e1,e2) equation
      true = isOne(e2);
    then e1;
    case(e1,e2) then expDiv(e1,e2);
  end matchcontinue;
end makeDiv;

public function makeAsub "creates an ASUB given an expression and an index"
  input DAE.Exp e;
  input Integer indx;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(e,indx)
  local list<DAE.Exp> subs;
    case(DAE.ASUB(e,subs),indx) equation
    subs = listAppend(subs,{DAE.ICONST(indx)});
    then DAE.ASUB(e,subs);

    case(e,indx) then DAE.ASUB(e,{DAE.ICONST(indx)});
  end matchcontinue;
end makeAsub;

public function expLn
"function expLn
  author: PA
  Takes the natural logarithm of an expression."
  input DAE.Exp e1;
  output DAE.Exp outExp;
  Type tp;
algorithm
  tp := typeof(e1);
  outExp := DAE.CALL(Absyn.IDENT("log"),{e1},false,true,tp,DAE.NO_INLINE());
end expLn;

public function makeIntegerExp
"Creates an integer constant expression given the integer input."
  input Integer i;
  output DAE.Exp e;
algorithm
  e := DAE.ICONST(i);
end makeIntegerExp;

public function makeConstOne
"function makeConstOne
  author: PA
  Create the constant value one, given a type that is INT or REAL"
  input Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inType)
    case (DAE.ET_INT()) then DAE.ICONST(1);
    case (DAE.ET_REAL()) then DAE.RCONST(1.0);
  end matchcontinue;
end makeConstOne;

public function makeConstZero
"Generates a zero constant"
	input Type inType;
	output DAE.Exp const;
algorithm
  const := matchcontinue(inType)
    case (DAE.ET_REAL()) then DAE.RCONST(0.0);
    case (DAE.ET_INT()) then DAE.ICONST(0);
    case(_) then DAE.RCONST(0.0);
  end matchcontinue;
end makeConstZero;

public function makeListOfZeros
  input Integer inDimension;
  output list<DAE.Exp> outList;
algorithm
  outList := matchcontinue(inDimension)
    local Integer dimension;
      DAE.Exp head;
      list<DAE.Exp> tail;
      case(0)
        then {};
      case(dimension) equation
        head = DAE.RCONST(0.0);
        tail = makeListOfZeros(dimension-1);
        then head :: tail;
  end matchcontinue;
end makeListOfZeros;

public function makeRealArrayOfZeros
  input Integer inDimension;
  output DAE.Exp outExp;
  list<DAE.Exp> l;
algorithm
  l := makeListOfZeros(inDimension);
  outExp := makeRealArray(l);
end makeRealArrayOfZeros;

public function makeZeroExpression
" creates a Real or array<Real> zero expression with given dimensions, also returns its type"
  input list<DAE.Dimension> inDims;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp,outType) := matchcontinue(inDims)
    local
      Integer i;
      DAE.Dimension d;
      list<DAE.Dimension> dims;
      DAE.Exp e;
      list<DAE.Exp> eLst;
      DAE.Type ty;
    case {} then (DAE.RCONST(0.0), DAE.T_REAL_DEFAULT);
    case d::dims
      equation
        i = dimensionSize(d);
        (e, ty) = makeZeroExpression(dims);
        eLst = Util.listFill(e,i);
      then
        (DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_REAL(),d::dims),false,eLst), 
         (DAE.T_ARRAY(d,ty),NONE()));      
  end matchcontinue;
end makeZeroExpression;  

public function arrayFill
  input list<DAE.Dimension> dims;
  input DAE.Exp inExp;
  output DAE.Exp oExp;
algorithm 
  oExp := matchcontinue(dims,inExp)
    local
      list<DAE.Exp> expl;
    case({},inExp) then inExp;
    case(dims,inExp)
      equation
        oExp = arrayFill2(dims,inExp);
      then
        oExp;
  end matchcontinue;
end arrayFill;

protected function arrayFill2
  input list<DAE.Dimension> dims;
  input DAE.Exp inExp;
  output DAE.Exp oExp;
algorithm 
  oExp := matchcontinue(dims,inExp)
  local
    Integer i;
    DAE.Dimension d;
    Type ty;
    list<DAE.Exp> expl;
  case({d},inExp)
    equation
      ty = typeof(inExp);
      i = dimensionSize(d);
      expl = listCreateExp(i,inExp);
    then
      DAE.ARRAY(DAE.ET_ARRAY(ty,{DAE.DIM_INTEGER(i)}),true,expl);
  case(_::dims,inExp)
    equation
      print(" arrayFill2 not implemented for matrixes, only single arrays \n");
    then
      fail();
  end matchcontinue;
end arrayFill2;

protected function listCreateExp "
Author BZ
Creates a lsit of exps containing the input Expression.
"
input Integer n;
input DAE.Exp e;
output list<DAE.Exp> expl;
algorithm expl := matchcontinue(n,e)
  case(n,e)
    equation
    true = intEq(n,0);
    then
      {};
  case(n,e)
    equation
      true = n>0;
      expl = listCreateExp(n-1,e);
      then
        e::expl;
  end matchcontinue;
end listCreateExp;

public function makeIndexSubscript
"function makeIndexSubscript
  Creates a Subscript INDEX from an Expression."
  input DAE.Exp exp;
  output Subscript subscript;
algorithm
  subscript := DAE.INDEX(exp);
end makeIndexSubscript;

public function makeVar "Creates a Var given a name and Type"
  input String name;
  input Type tp;
  output Var v;
algorithm
  v:= DAE.COMPLEX_VAR(name,tp);
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
  res := matchcontinue(dim1, dim2)
    case (DAE.DIM_UNKNOWN(), _) then DAE.DIM_UNKNOWN();
    case (_, DAE.DIM_UNKNOWN()) then DAE.DIM_UNKNOWN();
    case (_, _)
      equation
        res = intDimension(dimensionSize(dim1) + dimensionSize(dim2));
      then
        res;
  end matchcontinue;
end dimensionsAdd;

public function concatArrayType
  "Concatenates two array types, so that the resulting type is correct."
  input DAE.ExpType arrayType1;
  input DAE.ExpType arrayType2;
  output DAE.ExpType concatType;
algorithm
  concatType := matchcontinue(arrayType1, arrayType2)
    local
      DAE.ExpType et;
      DAE.Dimension dim1, dim2;
      list<DAE.Dimension> dims1, dims2;
    case (DAE.ET_ARRAY(ty = et, arrayDimensions = dim1 :: dims1),
          DAE.ET_ARRAY(arrayDimensions = dim2 :: dims2))
      equation
        dim1 = dimensionsAdd(dim1, dim2);
      then
        DAE.ET_ARRAY(et, dim1 :: dims1);
  end matchcontinue;
end concatArrayType;

/***************************************************/
/* replace DAE.Exp */
/***************************************************/

public function replaceExpListOpt
"similar to replaceExpList. But with Option<DAE.Exp> instead of Expression."
  input Option<DAE.Exp> inExp1;
  input list<DAE.Exp> s;
  input list<DAE.Exp> t;
  output Option<DAE.Exp> outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,s,t)
    local DAE.Exp e;
    case (NONE(),_,_) then (NONE(),0);
    case (SOME(e),s,t) equation
      (e,outInteger) = replaceExpList(e,s,t);
     then (SOME(e),outInteger);
  end matchcontinue;
end replaceExpListOpt;

public function replaceListExp
"function: replaceListExpression.
  Replaces an list of expressions with a expression."
  input list<DAE.Exp> inExpLst;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output list<DAE.Exp> outExpLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpLst,outIntegerLst) := matchcontinue (inExpLst,inExp2,inExp3)
    local
      DAE.Exp e,e1,e2,e3;
      Integer c;
      list<DAE.Exp> rest,explst;
      list<Integer> intlst;
    case ({},_,_) then ({},{});  
    case (e::rest,e2,e3)
      equation
        (e1,c) = replaceExp(e, e2, e3);
        (explst,intlst) = replaceListExp(rest,e2,e3);
      then
        (e1::explst,c::intlst);
  end matchcontinue;
end replaceListExp;

public function replaceExpList
"function: replaceExpList.
  Replaces an expression with a list of several expressions.
  NOTE: Not repreteadly applied, so the source and target
        lists must be disjunct
  Useful for instance when replacing several
  variables at once in an expression."
  input DAE.Exp inExp1;
  input list<DAE.Exp> inExpLst2;
  input list<DAE.Exp> inExpLst3;
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,inExpLst2,inExpLst3)
    local
      DAE.Exp e,e_1,e_2,s1,t1;
      Integer c1,c2,c;
      list<DAE.Exp> sr,tr;
    case (e,{},{}) then (e,0);  /* expr, source list, target list */
    case (e,(s1 :: sr),(t1 :: tr))
      equation
        (e_1,c1) = replaceExp(e, s1, t1);
        (e_2,c2) = replaceExpList(e_1, sr, tr);
        c = c1 + c2;
      then
        (e_2,c);
  end matchcontinue;
end replaceExpList;

public function replaceExp
"function: replaceExp
  Helper function to replaceExpList."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp expr,source,target,e1_1,e2_1,e1,e2,e3_1,e3,e_1,r_1,e,r,s;
      Integer c1,c2,c,c3,cnt_1,b,i;
      Operator op;
      list<DAE.Exp> expl_1,expl;
      list<Integer> cnt;
      Absyn.Path path,p;
      Boolean t;
      Type tp,ety;
      Absyn.CodeNode a;
      Ident id;
      ComponentRef cr;
      list<Subscript> subs;

    case (expr,source,target) /* expr source expr target expr */
      equation
        true = expEqual(expr, source);
      then
        (target,1);
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.BINARY(e1_1,op,e2_1),c);
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.LBINARY(e1_1,op,e2_1),c);
    case (DAE.UNARY(operator = op,exp = e1),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.UNARY(op,e1_1),c);
    case (DAE.LUNARY(operator = op,exp = e1),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.LUNARY(op,e1_1),c);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.RELATION(e1_1,op,e2_1),c);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        (e3_1,c3) = replaceExp(e3, source, target);
        c = Util.listReduce({c1,c2,c3}, intAdd);
      then
        (DAE.IFEXP(e1_1,e2_1,e3_1),c);
    case (DAE.CALL(path = path,expLst = expl,tuple_ = t,builtin = c,ty=tp,inlineType=i),source,target)
      local Boolean c;DAE.InlineType i; Type tp;
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, intAdd);
      then
        (DAE.CALL(path,expl_1,t,c,tp,i),cnt_1);
    case(DAE.PARTEVALFUNCTION(path = path, expList = expl, ty = tp),source,target)
      local Type tp;
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, intAdd);
      then
        (DAE.PARTEVALFUNCTION(path,expl_1,tp),cnt_1);
    case (DAE.ARRAY(ty = tp,scalar = c,array = expl),source,target)
      local Boolean c;
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, intAdd);
      then
        (DAE.ARRAY(tp,c,expl_1),cnt_1);
    case (DAE.MATRIX(ty = t,integer = b,scalar = expl),source,target)
      local
        list<list<tuple<DAE.Exp, Boolean>>> expl_1,expl;
        Integer cnt;
        Type t;
      equation
        (expl_1,cnt) = replaceExpMatrix(expl, source, target);
      then
        (DAE.MATRIX(t,b,expl_1),cnt);
    case (DAE.RANGE(ty = tp,exp = e1,expOption = NONE(),range = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.RANGE(tp,e1_1,NONE(),e2_1),c);
    case (DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e3),range = e2),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        (e3_1,c3) = replaceExp(e3, source, target);
        c = Util.listReduce({c1,c2,c3}, intAdd);
      then
        (DAE.RANGE(tp,e1_1,SOME(e3_1),e2_1),c);
    case (DAE.TUPLE(PR = expl),source,target)
      equation
        (expl_1,cnt) = Util.listMap22(expl, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, intAdd);
      then
        (DAE.TUPLE(expl_1),cnt_1);
    case (DAE.CAST(ty = tp,exp = e1),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.CAST(tp,e1_1),c);

    case (DAE.ASUB(exp = e1,sub = ae1),source,target)
      local list<DAE.Exp> ae1;
      equation
        (e1_1,c) = replaceExp(e1, source, target);
        (expl_1,cnt) = Util.listMap22(ae1, replaceExp, source, target);
        cnt_1 = Util.listReduce(cnt, intAdd);
        c = c+cnt_1;
      then
        (DAE.ASUB(e1_1,expl_1),c);

    case (DAE.SIZE(exp = e1,sz = NONE()),source,target)
      equation
        (e1_1,c) = replaceExp(e1, source, target);
      then
        (DAE.SIZE(e1_1,NONE()),c);
    case (DAE.SIZE(exp = e1,sz = SOME(e2)),source,target)
      equation
        (e1_1,c1) = replaceExp(e1, source, target);
        (e2_1,c2) = replaceExp(e2, source, target);
        c = c1 + c2;
      then
        (DAE.SIZE(e1_1,SOME(e2_1)),c);
    case (DAE.CODE(code = a,ty = b),source,target)
      local Type b;
      equation
        Debug.fprint("failtrace","-Expression.replaceExp on CODE not implemented.\n");
      then
        (DAE.CODE(a,b),0);
    case (DAE.REDUCTION(path = p,expr = e,ident = id,range = r),source,target)
      equation
        (e_1,c1) = replaceExp(e, source, target);
        (r_1,c2) = replaceExp(r, source, target);
        c = c1 + c2;
      then
        (DAE.REDUCTION(p,e_1,id,r_1),c);
    // qualified componentreferences, replace subscripts
    case(DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),source,target) equation
      (subs,c1) = replaceExpSubs(subs,source,target);
      (DAE.CREF(cr,_),c2) = replaceCrefExpSubs(DAE.CREF(cr,ety),source,target);
       // (DAE.CREF(cr,_),c2) = replaceExp(DAE.CREF(cr,ety),source,target);
      c = c1+c2;
    then (DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),c1);

    // simple componentreference, replace subscripts
    case(DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),source,target) equation
      (subs,c1) = replaceExpSubs(subs,source,target);
    then (DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),c1);

    case(DAE.CREF(cr as DAE.CREF_IDENT(id,t2,ssl),ety),_,_)
      local
        Type ety,t2;
        ComponentRef cr,cr_1;
        String name,id;
        list<Subscript> ssl;
      equation
        false = ComponentReference.crefHasScalarSubscripts(cr);
        name = ComponentReference.printComponentRefStr(cr);
        false = Util.stringContainsChar(name,"$");
        id = System.stringAppendList({"$",id});
        id = Util.stringReplaceChar(id,".","$p");
        cr_1 = ComponentReference.makeCrefIdent(id,t2,ssl);
      then
        (DAE.CREF(cr_1,ety),1);
    // no replacement
    case (e,s,_) then (e,0);
  end matchcontinue;
end replaceExp;

protected function replaceCrefExpSubs
"function: replaceCrefExpSubs
help function to replaceExpression. replaces expressions in subscript list
from all Crefs.
"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue (inExp1,inExp2,inExp3)
    local
      DAE.Exp source,target;
      Integer c1,c2,c;
      Operator op;
      Type tp,ety;
      Ident id;
      ComponentRef cr;
      list<Subscript> subs;
    
    case(DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),source,target) 
      equation
        (subs,c1) = replaceExpSubs(subs,source,target);
        (DAE.CREF(cr,_),c2) = replaceCrefExpSubs(DAE.CREF(cr,ety),source,target);
        c = c1+c2;
      then 
        (DAE.CREF(DAE.CREF_QUAL(id,tp,subs,cr),ety),c);

    // simple componentreference, replace subscripts
    case(DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),source,target) 
      equation
        (subs,c1) = replaceExpSubs(subs,source,target);
      then 
        (DAE.CREF(DAE.CREF_IDENT(id,tp,subs),ety),c1);
  end matchcontinue;
end replaceCrefExpSubs;

protected function replaceExpSubs
"function: replaceExpSubs
help function to replaceExpression. replaces expressions in subscript list
"
  input list<Subscript> subs;
  input DAE.Exp source;
  input DAE.Exp target;
  output list<Subscript> outSubs;
  output Integer cnt;
algorithm
  (outSubs,cnt) := matchcontinue(subs,source,target)
    local DAE.Exp e; Integer cnt1,cnt2;
    // empty list
    case({},_,_) then ({},0);
    // WHOLEDIM == ':' 
    case(DAE.WHOLEDIM()::subs,source,target) 
      equation
        (subs,cnt) = replaceExpSubs(subs,source,target);
      then 
        (DAE.WHOLEDIM()::subs,cnt);

    // slices e.g. a[{1,5,7}]
    case(DAE.SLICE(e)::subs,source,target) 
      equation
        (e,cnt1) = replaceExp(e,source,target);
        (subs,cnt2) = replaceExpSubs(subs,source,target);
        cnt = cnt1 + cnt2;
      then 
        (DAE.SLICE(e)::subs,cnt);

    // index, e.g. a[i+1]
    case(DAE.INDEX(e)::subs,source,target) 
      equation
        (e,cnt1) = replaceExp(e,source,target);
        (subs,cnt2) = replaceExpSubs(subs,source,target);
        cnt = cnt1 + cnt2;
      then 
        (DAE.INDEX(e)::subs,cnt);
  end matchcontinue;
end replaceExpSubs;

protected function replaceExpMatrix
"function: replaceExpMatrix
  author: PA
  Helper function to replaceExp,
  traverses Matrix expression list."
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpBooleanLstLst1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpBooleanLstLst;
  output Integer outInteger;
algorithm
  (outTplExpBooleanLstLst,outInteger) := matchcontinue (inTplExpBooleanLstLst1,inExp2,inExp3)
    local
      DAE.Exp str,dst,src;
      list<tuple<DAE.Exp, Boolean>> e_1,e;
      Integer c1,c2,c;
      list<list<tuple<DAE.Exp, Boolean>>> es_1,es;
    // empty list
    case ({},str,dst) then ({},0);
    // head :: rest
    case ((e :: es),src,dst)
      equation
        (e_1,c1) = replaceExpMatrix2(e, src, dst);
        (es_1,c2) = replaceExpMatrix(es, src, dst);
        c = c1 + c2;
      then
        ((e_1 :: es_1),c);
    // failure
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "- Expression.replaceExpMatrix failed\n");
      then
        fail();
  end matchcontinue;
end replaceExpMatrix;

protected function replaceExpMatrix2
"function: replaceExpMatrix2
  author: PA
  Helper function to replaceExpMatrix"
  input list<tuple<DAE.Exp, Boolean>> inTplExpBooleanLst1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output list<tuple<DAE.Exp, Boolean>> outTplExpBooleanLst;
  output Integer outInteger;
algorithm
  (outTplExpBooleanLst,outInteger) := matchcontinue (inTplExpBooleanLst1,inExp2,inExp3)
    local
      list<tuple<DAE.Exp, Boolean>> es_1,es;
      Integer c1,c2,c;
      DAE.Exp e_1,e,src,dst;
      Boolean b;
    case ({},_,_) then ({},0);
    case (((e,b) :: es),src,dst)
      equation
        (es_1,c1) = replaceExpMatrix2(es, src, dst);
        (e_1,c2) = replaceExp(e, src, dst);
        c = c1 + c2;
      then
        (((e_1,b) :: es_1),c);
  end matchcontinue;
end replaceExpMatrix2;


/***************************************************/
/* traverse DAE.Exp */
/***************************************************/

public function traverseExp
"function traverseExp
  Traverses all subexpressions of an expression.
  Takes a function and an extra argument passed through the traversal.
  The function can potentially change the expression. In such cases,
  the changes are made bottom-up, i.e. a subexpression is traversed
  and changed before the complete expression is traversed."
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output tuple<DAE.Exp, Type_a> outTplExpTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTplExpTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
  end FuncExpType;
algorithm
  outTplExpTypeA:=
  matchcontinue (inExp,func,inTypeA)
    local
      DAE.Exp e1_1,e,e1,e2_1,e2,e3_1,e_1,e3;
      Type_a ext_arg_1,ext_arg_2,ext_arg,ext_arg_3,ext_arg_4;
      Operator op_1,op;
      FuncExpType rel;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path fn_1,fn,path_1,path;
      Boolean t_1,b_1,t,b,scalar_1,scalar;
      Type tp_1,tp;
      Integer i_1,i;
      Ident id_1,id;
    case ((e as DAE.UNARY(operator = op,exp = e1)),rel,ext_arg) /* unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.UNARY(op,e1_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.BINARY(e1_1,op,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.LUNARY(operator = op,exp = e1)),rel,ext_arg) /* logic unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.LUNARY(op,e1_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* logic binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.LBINARY(e1_1,op,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* RELATION */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.RELATION(e1_1,op,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)),rel,ext_arg) /* if expression */
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
        ((e,ext_arg_4)) = rel((DAE.IFEXP(e1_1,e2_1,e3_1),ext_arg_3));
      then
        ((e,ext_arg_4));
    case ((e as DAE.CALL(path = fn,expLst = expl,tuple_ = t,builtin = b,ty=tp,inlineType = i)),rel,ext_arg)
      local Type tp,tp_1; DAE.InlineType  i;
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, traverseExp, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.CALL(fn,expl_1,t,b,tp,i),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.PARTEVALFUNCTION(path = fn, expList = expl, ty = tp)),rel,ext_arg)
      local Type tp;
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, traverseExp, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.PARTEVALFUNCTION(fn,expl_1,tp),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.ARRAY(ty = tp,scalar = scalar,array = expl)),rel,ext_arg)
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, traverseExp, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.ARRAY(tp,scalar,expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.MATRIX(ty = tp,integer = scalar,scalar = expl)),rel,ext_arg)
      local
        list<list<tuple<DAE.Exp, Boolean>>> expl_1,expl;
        Integer scalar_1,scalar;
      equation
        (expl_1,ext_arg_1) = traverseExpMatrix(expl, traverseExp, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.MATRIX(tp,scalar,expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = NONE(),range = e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.RANGE(tp,e1_1,NONE(),e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExp(e3, rel, ext_arg_2);
        ((e,ext_arg_4)) = rel((DAE.RANGE(tp,e1_1,SOME(e2_1),e3_1),ext_arg_3));
      then
        ((e,ext_arg_4));
    case ((e as DAE.TUPLE(PR = expl)),rel,ext_arg)
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl, traverseExp, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.TUPLE(expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.CAST(ty = tp,exp = e1)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.CAST(tp,e1_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.ASUB(exp = e1,sub = expl_1)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((expl_1,ext_arg_2)) = traverseExpList(expl_1, traverseExp, rel, ext_arg_1);
        ((e,ext_arg_2)) = rel((DAE.ASUB(e1_1,expl_1),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.SIZE(exp = e1,sz = NONE())),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e,ext_arg_2)) = rel((DAE.SIZE(e1_1,NONE()),ext_arg_1));
      then
        ((e,ext_arg_2));
    case ((e as DAE.SIZE(exp = e1,sz = SOME(e2))),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.SIZE(e1_1,SOME(e2_1)),ext_arg_2));
      then
        ((e,ext_arg_3));
    case ((e as DAE.REDUCTION(path = path,expr = e1,ident = id,range = e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((e,ext_arg_3)) = rel((DAE.REDUCTION(path,e1_1,id,e2_1),ext_arg_2));
      then
        ((e,ext_arg_3));
            /* MetaModelica list */
    case ((e as DAE.CONS(tp,e1,e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExp(e2, rel, ext_arg_1);
        ((DAE.CONS(_,_,_),ext_arg_3)) = rel((e,ext_arg_2));
      then
        ((DAE.CONS(tp,e1_1,e2_1),ext_arg_3));

    case ((e as DAE.LIST(tp,expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((DAE.LIST(tp,expl_1),ext_arg_2));

    case ((e as DAE.META_TUPLE(expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((DAE.META_TUPLE(expl_1),ext_arg_2));

    case ((e as DAE.META_OPTION(NONE())),rel,ext_arg)
      equation
      then
        ((DAE.META_OPTION(NONE()),ext_arg));

    case ((e as DAE.META_OPTION(SOME(e1))),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExp(e1, rel, ext_arg);
        ((e_1,ext_arg_2)) = rel((e,ext_arg_1));
      then
        ((DAE.META_OPTION(SOME(e1_1)),ext_arg_2));
        /* --------------------- */

    case (e,rel,ext_arg)
      equation
        ((e_1,ext_arg_1)) = rel((e,ext_arg));
      then
        ((e_1,ext_arg_1));
  end matchcontinue;
end traverseExp;

public function traverseExpTopDown
"function traverseExpTopDown
  Traverses all subexpressions of an expression.
  Takes a function and an extra argument passed through the traversal.
  The function can potentially change the expression. In such cases,
  the changes are made top-down, i.e. a subexpression is traversed
  and changed after the complete expression is traversed."
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output tuple<DAE.Exp, Type_a> outTplExpTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTplExpTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
  end FuncExpType;
protected
  DAE.Exp e;
  Type_a ext_arg_1;
algorithm
  ((e,ext_arg_1)) := func((inExp,inTypeA));
  outTplExpTypeA := traverseExpTopDown1(e,func,ext_arg_1);
end traverseExpTopDown;

protected function traverseExpTopDown1
"function traverseExpTopDown1
  Helper for traverseExpTopDown."
  replaceable type Type_a subtypeof Any;
  input DAE.Exp inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output tuple<DAE.Exp, Type_a> outTplExpTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTplExpTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
  end FuncExpType;
algorithm
  outTplExpTypeA:=
  matchcontinue (inExp,func,inTypeA)
    local
      DAE.Exp e1_1,e,e1,e2_1,e2,e3_1,e_1,e3;
      Type_a ext_arg_1,ext_arg_2,ext_arg,ext_arg_3,ext_arg_4;
      Operator op_1,op;
      FuncExpType rel;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path fn_1,fn,path_1,path;
      Boolean t_1,b_1,t,b,scalar_1,scalar;
      Type tp_1,tp;
      Integer i_1,i;
      Ident id_1,id;
    case ((e as DAE.UNARY(operator = op,exp = e1)),rel,ext_arg) /* unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
      then
        ((DAE.UNARY(op,e1_1),ext_arg_1));
    case ((e as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
      then
        ((DAE.BINARY(e1_1,op,e2_1),ext_arg_2));
    case ((e as DAE.LUNARY(operator = op,exp = e1)),rel,ext_arg) /* logic unary */
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
      then
        ((DAE.LUNARY(op,e1_1),ext_arg_1));
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* logic binary */
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
      then
        ((DAE.LBINARY(e1_1,op,e2_1),ext_arg_2));
    case ((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),rel,ext_arg) /* RELATION */
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
      then
        ((DAE.RELATION(e1_1,op,e2_1),ext_arg_2));
    case ((e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3)),rel,ext_arg) /* if expression */
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExpTopDown(e3, rel, ext_arg_2);
      then
        ((DAE.IFEXP(e1_1,e2_1,e3_1),ext_arg_3));
    case ((e as DAE.CALL(path = fn,expLst = expl,tuple_ = t,builtin = b,ty=tp,inlineType = i)),rel,ext_arg)
      local Type tp,tp_1; DAE.InlineType  i;
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl,traverseExpTopDown, rel, ext_arg);
      then
        ((DAE.CALL(fn,expl_1,t,b,tp,i),ext_arg_1));
    case ((e as DAE.PARTEVALFUNCTION(path = fn, expList = expl, ty = tp)),rel,ext_arg)
      local Type tp;
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl,traverseExpTopDown, rel, ext_arg);
      then
        ((DAE.PARTEVALFUNCTION(fn,expl_1,tp),ext_arg_1));
    case ((e as DAE.ARRAY(ty = tp,scalar = scalar,array = expl)),rel,ext_arg)
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl,traverseExpTopDown, rel, ext_arg);
      then
        ((DAE.ARRAY(tp,scalar,expl_1),ext_arg_1));
    case ((e as DAE.MATRIX(ty = tp,integer = scalar,scalar = expl)),rel,ext_arg)
      local
        list<list<tuple<DAE.Exp, Boolean>>> expl_1,expl;
        Integer scalar_1,scalar;
      equation
        (expl_1,ext_arg_1) = traverseExpMatrix(expl,traverseExpTopDown, rel, ext_arg);
      then
        ((DAE.MATRIX(tp,scalar,expl_1),ext_arg_1));
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = NONE(),range = e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
      then
        ((DAE.RANGE(tp,e1_1,NONE(),e2_1),ext_arg_2));
    case ((e as DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
        ((e3_1,ext_arg_3)) = traverseExpTopDown(e3, rel, ext_arg_2);
      then
        ((DAE.RANGE(tp,e1_1,SOME(e2_1),e3_1),ext_arg_3));
    case ((e as DAE.TUPLE(PR = expl)),rel,ext_arg)
      equation
        ((expl_1,ext_arg_1)) = traverseExpList(expl,traverseExpTopDown, rel, ext_arg);
      then
        ((DAE.TUPLE(expl_1),ext_arg_1));
    case ((e as DAE.CAST(ty = tp,exp = e1)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
      then
        ((DAE.CAST(tp,e1_1),ext_arg_1));
    case ((e as DAE.ASUB(exp = e1,sub = expl_1)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((expl_1,ext_arg_2)) = traverseExpList(expl_1,traverseExpTopDown, rel, ext_arg_1);
      then
        ((DAE.ASUB(e1_1,expl_1),ext_arg_1));
    case ((e as DAE.SIZE(exp = e1,sz = NONE())),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
      then
        ((DAE.SIZE(e1_1,NONE()),ext_arg_1));
    case ((e as DAE.SIZE(exp = e1,sz = SOME(e2))),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
      then
        ((DAE.SIZE(e1_1,SOME(e2_1)),ext_arg_2));
    case ((e as DAE.REDUCTION(path = path,expr = e1,ident = id,range = e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
      then
        ((DAE.REDUCTION(path,e1_1,id,e2_1),ext_arg_2));
            /* MetaModelica list */
    case ((e as DAE.CONS(tp,e1,e2)),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
        ((e2_1,ext_arg_2)) = traverseExpTopDown(e2, rel, ext_arg_1);
      then
        ((DAE.CONS(tp,e1_1,e2_1),ext_arg_2));

    case ((e as DAE.LIST(tp,expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
      then
        ((DAE.LIST(tp,expl_1),ext_arg_1));

    case ((e as DAE.META_TUPLE(expl)),rel,ext_arg)
      equation
        (expl_1,ext_arg_1) = Util.listFoldMap(expl, rel, ext_arg);
      then
        ((DAE.META_TUPLE(expl_1),ext_arg_1));

    case ((e as DAE.META_OPTION(NONE())),rel,ext_arg)
      then
        ((DAE.META_OPTION(NONE()),ext_arg));

    case ((e as DAE.META_OPTION(SOME(e1))),rel,ext_arg)
      equation
        ((e1_1,ext_arg_1)) = traverseExpTopDown(e1, rel, ext_arg);
      then
        ((DAE.META_OPTION(SOME(e1_1)),ext_arg_1));
        /* --------------------- */

    case (e,rel,ext_arg) then ((e,ext_arg));
  end matchcontinue;
end traverseExpTopDown1;

protected function traverseExpMatrix
"function: traverseExpMatrix
  author: PA
   Helper function to traverseExp, traverses matrix expressions."
  replaceable type Type_a subtypeof Any;
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpBooleanLstLst;
  input traversefuncType tfunc "use traverseExp ore traverseExpTopDown";
  input FuncExpType func;
  input Type_a inTypeA;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpBooleanLstLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTplExpTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  partial function traversefuncType
    input DAE.Exp inExp;
    input funcType func;
    input Type_a inTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
    partial function funcType
      input tuple<DAE.Exp, Type_a> tpl1;
      output tuple<DAE.Exp, Type_a> tpl2;
    end funcType;    
  end traversefuncType;    
algorithm
  (outTplExpBooleanLstLst,outTypeA):=
  matchcontinue (inTplExpBooleanLstLst,tfunc,func,inTypeA)
    local
      FuncExpType rel;
      Type_a e_arg,e_arg_1,e_arg_2;
      list<tuple<DAE.Exp, Boolean>> row_1,row;
      list<list<tuple<DAE.Exp, Boolean>>> rows_1,rows;
    case ({},_,_,e_arg) then ({},e_arg);
    case ((row :: rows),tfunc,rel,e_arg)
      equation
        (row_1,e_arg_1) = traverseExpMatrix2(row, tfunc, rel, e_arg);
        (rows_1,e_arg_2) = traverseExpMatrix(rows, tfunc, rel, e_arg_1);
      then
        ((row_1 :: rows_1),e_arg_2);
  end matchcontinue;
end traverseExpMatrix;

protected function traverseExpMatrix2
"function: traverseExpMatrix2
  author: PA
  Helper function to traverseExpMatrix."
  replaceable type Type_a subtypeof Any;
  input list<tuple<DAE.Exp, Boolean>> inTplExpBooleanLst;
  input traversefuncType tfunc "use traverseExp ore traverseExpTopDown";
  input FuncExpType func;
  input Type_a inTypeA;
  output list<tuple<DAE.Exp, Boolean>> outTplExpBooleanLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTplExpTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  partial function traversefuncType
    input DAE.Exp inExp;
    input funcType func;
    input Type_a inTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
    partial function funcType
      input tuple<DAE.Exp, Type_a> tpl1;
      output tuple<DAE.Exp, Type_a> tpl2;
    end funcType;    
  end traversefuncType;   
algorithm
  (outTplExpBooleanLst,outTypeA):=
  matchcontinue (inTplExpBooleanLst,tfunc,func,inTypeA)
    local
      Type_a e_arg,e_arg_1,e_arg_2;
      DAE.Exp e_1,e;
      list<tuple<DAE.Exp, Boolean>> rest_1,rest;
      Boolean b;
      FuncExpType rel;
    case ({},_,_,e_arg) then ({},e_arg);
    case (((e,b) :: rest),tfunc,rel,e_arg)
      equation
        ((e_1,e_arg_1)) = tfunc(e, rel, e_arg);
        (rest_1,e_arg_2) = traverseExpMatrix2(rest, tfunc, rel, e_arg_1);
      then
        (((e_1,b) :: rest_1),e_arg_2);
  end matchcontinue;
end traverseExpMatrix2;

public function traverseExpList
"function traverseExpList
 author PA:
 Calls traverseExp for each element of list."
  replaceable type Type_a subtypeof Any;
  input list<DAE.Exp> expl;
  input traversefuncType tfunc "use traverseExp ore traverseExpTopDown";
  input funcType rel;
  input Type_a ext_arg;
  output tuple<list<DAE.Exp>, Type_a> outTpl;
  partial function funcType
    input tuple<DAE.Exp, Type_a> tpl1;
    output tuple<DAE.Exp, Type_a> tpl2;
  end funcType;
  partial function traversefuncType
    input DAE.Exp inExp;
    input funcType func;
    input Type_a inTypeA;
    output tuple<DAE.Exp, Type_a> outTplExpTypeA;
    partial function funcType
      input tuple<DAE.Exp, Type_a> tpl1;
      output tuple<DAE.Exp, Type_a> tpl2;
    end funcType;    
  end traversefuncType;    
algorithm
  outTpl := matchcontinue(expl,tfunc,rel,ext_arg)
  local DAE.Exp e,e1; list<DAE.Exp> expl1;
    case({},_,_,ext_arg) then (({},ext_arg));
    case(e::expl,tfunc,rel,ext_arg) equation
      ((e1,ext_arg)) = tfunc(e, rel, ext_arg);
      ((expl1,ext_arg)) = traverseExpList(expl,tfunc,rel,ext_arg);
    then ((e1::expl1,ext_arg)); 
  end matchcontinue;
end traverseExpList;

public function traverseExpOpt "Calls traverseExp for SOME(exp) and does nothing for NONE"
  input Option<DAE.Exp> inExp;
  input FuncExpType func;
  input Type_a inTypeA;
  output tuple<Option<DAE.Exp>, Type_a> outTpl;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
    replaceable type Type_a subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  outTpl:= matchcontinue (inExp,func,inTypeA)
  local DAE.Exp e;
    case(NONE(),_,inTypeA) then ((NONE(),inTypeA));
    case(SOME(e),func,inTypeA) equation
      ((e,inTypeA)) = traverseExp(e,func,inTypeA);
     then ((SOME(e),inTypeA));
  end matchcontinue;
end traverseExpOpt;

public function extractCrefsFromExp "
Author: BZ 2008-06, Extracts all ComponentRef from an Expression.
"
input DAE.Exp inExp;
output list<ComponentRef> ocrefs;
algorithm ocrefs := matchcontinue(inExp)
  case(inExp)
    local list<ComponentRef> crefs;
    equation
      ((_,crefs)) = traverseExp(inExp, traversingComponentRefFinder, {});
      then
        crefs;
  end matchcontinue;
end extractCrefsFromExp;

public function traversingComponentRefFinder "
Author: BZ 2008-06
Exp traverser that Union the current ComponentRef with list if it is already there.
Returns a list containing, unique, all componentRef in an Expression.
"
  input tuple<DAE.Exp, list<ComponentRef> > inExp;
  output tuple<DAE.Exp, list<ComponentRef> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    list<ComponentRef> crefs;
    ComponentRef cr;
    Type ty;
  case( (DAE.CREF(cr,ty), crefs) )
    local list<Boolean> blist;
    equation
      crefs = Util.listUnionEltOnTrue(cr,crefs,ComponentReference.crefEqual);
    then
      ((DAE.CREF(cr,ty), crefs ));
  case(inExp) then inExp;
end matchcontinue;
end traversingComponentRefFinder;

public function extractDivExpFromExp "
Author: Frenkel TUD 2010-02, Extracts all Division DAE.Exp from an Expression.
"
input DAE.Exp inExp;
output list<DAE.Exp> outExps;
algorithm outExps := matchcontinue(inExp)
  case(inExp)
    local list<DAE.Exp> exps;
    equation
      ((_,exps)) = traverseExp(inExp, traversingDivExpFinder, {});
      then
        exps;
  end matchcontinue;
end extractDivExpFromExp;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02
Returns a list containing, all division DAE.Exp in an Expression.
"
  input tuple<DAE.Exp, list<DAE.Exp> > inExp;
  output tuple<DAE.Exp, list<DAE.Exp> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    list<DAE.Exp> exps;
    DAE.Exp e,e2;
    Type ty;
  case( (e as DAE.BINARY(operator = DAE.DIV(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case( ( e as DAE.BINARY(operator = DAE.DIV_ARR(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case( ( e as DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case( ( e as DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), exps) )
    then ((e, e2::exps ));
  case(inExp) then inExp;
end matchcontinue;
end traversingDivExpFinder;

public function getMatchingExpsList
  input list<DAE.Exp> inExps;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
  list<list<DAE.Exp>> explists;
algorithm
  explists := Util.listMap1(inExps, getMatchingExps, inFn);
  outExpLst := Util.listFlatten(explists);
end getMatchingExpsList;

public function getMatchingExps
"function: getMatchingExps
  Return all exps that match the given function.
  Inner exps may be returned separately but not
  extracted from the DAE.Exp they are in, e.g.
    CALL(foo, {CALL(bar)}) will return
    {CALL(foo, {CALL(bar)}), CALL(bar,{})}"
  input DAE.Exp inExp;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
algorithm
  outExpLst:=
  matchcontinue (inExp,inFn)
    local
      list<DAE.Exp> exps,exps2,args,a,b,res,elts,elst,elist;
      DAE.Exp e,e1,e2,e3;
      Absyn.Path path;
      Boolean tuple_,builtin;
      list<tuple<DAE.Exp, Boolean>> flatexplst;
      list<list<tuple<DAE.Exp, Boolean>>> explst;
      Option<DAE.Exp> optexp;
      MatchFn fn;

    // First we check if the function matches
    case (e, fn)
      equation
        res = fn(e);
      then res;

    // Else: Traverse all Exps
    case ((e as DAE.CALL(path = path,expLst = args,tuple_ = tuple_,builtin = builtin)),fn)
      equation
        exps = getMatchingExpsList(args,fn);
      then
        exps;
    case (DAE.PARTEVALFUNCTION(expList = args),fn)
      equation
        res = getMatchingExpsList(args,fn);
      then
        res;
    case (DAE.BINARY(exp1 = e1,exp2 = e2),fn) /* Binary */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.UNARY(exp = e),fn) /* Unary */
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),fn) /* LBinary */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.LUNARY(exp = e),fn) /* LUnary */
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),fn) /* Relation */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),fn)
      equation
        res = getMatchingExpsList({e1,e2,e3},fn);
      then
        res;
    case (DAE.ARRAY(array = elts),fn) /* Array */
      equation
        res = getMatchingExpsList(elts,fn);
      then
        res;
    case (DAE.MATRIX(scalar = explst),fn) /* Matrix */
      equation
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        res = getMatchingExpsList(elst,fn);
      then
        res;
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2),fn) /* Range */
      local list<DAE.Exp> e3;
      equation
        e3 = Util.optionToList(optexp);
        elist = listAppend({e1,e2}, e3);
        res = getMatchingExpsList(elist,fn);
      then
        res;
    case (DAE.TUPLE(PR = exps),fn) /* Tuple */
      equation
        res = getMatchingExpsList(exps,fn);
      then
        res;
    case (DAE.CAST(exp = e),fn)
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = e2),fn) /* Size */
      local Option<DAE.Exp> e2;
      equation
        a = Util.optionToList(e2);
        elist = e1 :: a;
        res = getMatchingExpsList(elist,fn);
      then
        res;

        /* MetaModelica list */
    case (DAE.CONS(_,e1,e2),fn)
      equation
        elist = {e1,e2};
        res = getMatchingExpsList(elist,fn);
      then res;

    case  (DAE.LIST(_,elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;

    case (e as DAE.METARECORDCALL(args = elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;

    case (DAE.META_TUPLE(elist), fn)
      equation
        res = getMatchingExpsList(elist, fn);
      then res;

   case (DAE.META_OPTION(SOME(e1)), fn)
      equation
        res = getMatchingExps(e1, fn);
      then res;

    case(DAE.ASUB(exp = e1),fn)
      equation
        res = getMatchingExps(e1,fn);
        then
          res;

    case(DAE.CREF(_,_),_) then {};

		case (DAE.REDUCTION(expr = e1), fn)
			equation
				res = getMatchingExps(e1, fn);
			then
				res;

    case (DAE.VALUEBLOCK(localDecls = ld,body = body,result = e),fn)
      local
    		list<DAE.Element> ld;
    		list<DAE.Statement> body;
      equation
        exps = DAEUtil.getAllExps(ld);
        exps2 = Algorithm.getAllExpsStmts(body);
        exps = listAppend(exps,exps2);
        res = getMatchingExpsList(e::exps,fn);
      then res;

    case (DAE.ICONST(_),_) then {};
    case (DAE.RCONST(_),_) then {};
    case (DAE.BCONST(_),_) then {};
    case (DAE.SCONST(_),_) then {};
    case (DAE.CODE(_,_),_) then {};
    case (DAE.END(),_) then {};
    case (DAE.META_OPTION(NONE()),_) then {};

    case (e,_)
      equation
        Debug.fprintln("failtrace", "- Expression.getMatchingExps failed: " +& ExpressionDump.printExpStr(e));
      then fail();

  end matchcontinue;
end getMatchingExps;


/***************************************************/
/* Compare and Check DAE.Exp */
/***************************************************/

public function operatorDivOrMul "returns true if operator is division or multiplication"
  input  Operator op;
  output Boolean res;
algorithm
  res := matchcontinue(op)
    case(DAE.MUL(_)) then true;
    case(DAE.DIV(_)) then true;
    case (_) then false;
  end matchcontinue;
end operatorDivOrMul;

public function identEqual
"function: identEqual
  author: PA
  Compares two Ident."
  input Ident inIdent1;
  input Ident inIdent2;
  output Boolean outBoolean;
algorithm
  outBoolean := stringEqual(inIdent1, inIdent2);
end identEqual;

public function isRange
"function: isRange
  Returns true if expression is a range expression."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case DAE.RANGE(ty = _) then true;
    case _ then false;
  end matchcontinue;
end isRange;

public function isOne
"function: isOne
  Returns true if an expression is constant
  and has the value one, otherwise false"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local
      Integer ival;
      Real rzero,rval;
      Boolean res;
      Type t;
      DAE.Exp e;
    case (DAE.ICONST(integer = ival)) then intEq(ival,1);
    case (DAE.RCONST(real = rval)) then realEq(rval,1.0);
/*      
      equation
        rzero = intReal(1) "Due to bug in mmc, go trough a cast from int" ;
        (rzero ==. rval) = true;
      then
        true; */
    case (DAE.CAST(ty = t,exp = e))
      equation
        res = isOne(e) "Casting to one is still one" ;
      then
        res;
    case (_) then false;
  end matchcontinue;
end isOne;

public function isZero
"function: isZero
  Returns true if an expression is constant
  and has the value zero, otherwise false"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Integer ival;
      Real rzero,rval;
      Boolean res;
      Type t;
      DAE.Exp e;
      list<DAE.Exp> ae;
      list<Boolean> ab;
      list<list<tuple<DAE.Exp, Boolean>>> scalar;      
      list<tuple<DAE.Exp, Boolean>> aelstlst;       
    case (DAE.ICONST(integer = ival)) then intEq(ival,0);
    case (DAE.RCONST(real = rval)) then realEq(rval,0.0);
/*      
      equation
        true = realEq(rval,0.0);
        rzero = intReal(0) "Due to bug in mmc, go trough a cast from int" ;
        (rzero ==. rval) = true;
      then
        true;
        */
    case (DAE.CAST(ty = t,exp = e))
      equation
        res = isZero(e) "Casting to zero is still zero" ;
      then
        res;
    case(DAE.UNARY(DAE.UMINUS(_),e)) then isZero(e);
    case(DAE.ARRAY(array = ae))
      equation
        ab = Util.listMap(ae,isZero);  
        res = Util.boolAndList(ab);
      then   
        res;
    case (DAE.MATRIX(scalar = scalar))  
      equation
        aelstlst = Util.listFlatten(scalar);
        ae = Util.listMap(aelstlst,Util.tuple21);
        ab = Util.listMap(ae,isZero);  
        res = Util.boolAndList(ab);
      then   
        res;         
    case(DAE.UNARY(DAE.UMINUS_ARR(_),e)) then isZero(e);
    case (_) then false;
  end matchcontinue;
end isZero;

public function isConst
"function: isConst
  Returns true if an expression
  is constant otherwise false"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Integer ival;
      Real rval;
      Boolean bval,res,b1,b2;
      Ident sval;
      Operator op;
      DAE.Exp e,e1,e2;
      Type t;
      list<DAE.Exp> ae;
      list<Boolean> ab;
      list<list<tuple<DAE.Exp, Boolean>>> scalar;      
      list<tuple<DAE.Exp, Boolean>> aelstlst;      
    case (DAE.ICONST(integer = ival)) then true;
    case (DAE.RCONST(real = rval)) then true;
    case (DAE.BCONST(bool = bval)) then true;
    case (DAE.SCONST(string = sval)) then true;
    case (DAE.ENUM_LITERAL(name = _)) then true;

    case (DAE.UNARY(operator = op,exp = e))
      equation
        res = isConst(e);
      then
        res;
    case (DAE.CAST(ty = t,exp = e)) /* Casting to zero is still zero */
      equation
        res = isConst(e);
      then
        res;
    case (DAE.BINARY(e1,op,e2))
      equation
        b1 = isConst(e1);
        b2 = isConst(e2);
        res = boolAnd(b1,b2);
      then
        res;
    case (DAE.IFEXP(_,e1,e2))
      equation
        b1 = isConst(e1);
        b2 = isConst(e2);
        res = boolAnd(b1,b2);
      then
        res;        
    case (DAE.ARRAY(array = ae))  
      equation
        ab = Util.listMap(ae,isConst);  
        res = Util.boolAndList(ab);
      then   
        res;   
    case (DAE.MATRIX(scalar = scalar))  
      equation
        aelstlst = Util.listFlatten(scalar);
        ae = Util.listMap(aelstlst,Util.tuple21);
        ab = Util.listMap(ae,isConst);  
        res = Util.boolAndList(ab);
      then   
        res;            
    case (_) then false;
  end matchcontinue;
end isConst;

public function isNotConst
"function isNotConst
  author: PA
  Check if expression is not constant."
  input DAE.Exp e;
  output Boolean nb;
  Boolean b;
algorithm
  b := isConst(e);
  nb := boolNot(b);
end isNotConst;

public function isRelation
"function: isRelation
  Returns true if expression is a function expression."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Boolean b1,b2,res;
      DAE.Exp e1,e2;
    case (DAE.RELATION(exp1 = _)) then true;
    case (DAE.LUNARY(exp = DAE.RELATION(exp1 = _))) then true;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        b1 = isRelation(e1);
        b2 = isRelation(e2);
        res = boolOr(b1, b2);
      then
        res;
    case (_) then false;
  end matchcontinue;
end isRelation;

protected function isEventTriggeringFunctionExp
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := matchcontinue(inExp)
    case (DAE.CALL(path = Absyn.IDENT("div"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("mod"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("rem"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("ceil"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("floor"))) then true;
    case (DAE.CALL(path = Absyn.IDENT("integer"))) then true;
    case (_) then false;
  end matchcontinue;
end isEventTriggeringFunctionExp;

public function isAddOrSub "returns true if operator is ADD or SUB"
  input Operator op;
  output Boolean res;
algorithm
  res := isAdd(op) or isSub(op);    
end isAddOrSub;

public function isAdd "returns true if operator is ADD"
  input Operator op;
  output Boolean res;
algorithm
  res := matchcontinue(op)
    case(DAE.ADD(_)) then true;
    case(_) then false;
  end matchcontinue;
end isAdd;

public function isSub "returns true if operator is SUB"
  input Operator op;
  output Boolean res;
algorithm
  res := matchcontinue(op)
    case(DAE.SUB(_)) then true;
    case(_) then false;
  end matchcontinue;
end isSub;


public function equalTypes ""
input Type t1,t2;
output Boolean b;
algorithm b := matchcontinue(t1,t2)
  local
    list<DAE.ExpVar> vars1,vars2;
    Type ty1,ty2;
    list<DAE.Dimension> ad1,ad2;
    list<Integer> li1,li2;

  case(DAE.ET_INT(),DAE.ET_INT()) then true;
  case(DAE.ET_REAL(),DAE.ET_REAL()) then true;
  case(DAE.ET_STRING(),DAE.ET_STRING()) then true;
  case(DAE.ET_BOOL(),DAE.ET_BOOL()) then true;

  case(DAE.ET_COMPLEX(_,vars1,_), DAE.ET_COMPLEX(_,vars2,_))
       then equalTypesComplexVars(vars1,vars2);
  case(DAE.ET_ARRAY(ty1,ad1),DAE.ET_ARRAY(ty2,ad2))
    equation
      li1 = Util.listMap(ad1, dimensionSize);
      li2 = Util.listMap(ad2, dimensionSize);
      true = Util.isListEqualWithCompareFunc(li1,li2,intEq);
      true = equalTypes(ty1,ty2);
    then
      true;
  case(t1,t2) then false;
  end matchcontinue;
end equalTypes;

protected function equalTypesComplexVars ""
input list<DAE.ExpVar> vars1,vars2;
output Boolean b;
algorithm
  b := matchcontinue(vars1,vars2)
  local
    DAE.ExpType t1,t2;
    String s1,s2;
    case({},{}) then true;
    case(DAE.COMPLEX_VAR(s1,t1)::vars1,DAE.COMPLEX_VAR(s2,t2)::vars2)
      equation
        //print(" verify subvars: " +& s1 +& " and " +& s2 +& " to go: " +& intString(listLength(vars1)) +& " , " +& intString(listLength(vars2))  +& "\n");
        true = stringEqual(s1,s2);
        //print(" types: " +& ExpressionDump.typeString(t1) +& " and " +& ExpressionDump.typeString(t2) +& "\n");
        true = equalTypes(t1,t2);
        //print(s1 +& " and " +& s2 +& " EQUAL \n\n");
        then
          equalTypesComplexVars(vars1,vars2);
    case(_,_) then false;
  end matchcontinue;
end equalTypesComplexVars;

public function typeBuiltin
"function: typeBuiltin
  Returns true if type is one of the builtin types."
  input Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inType)
    case (DAE.ET_INT()) then true;
    case (DAE.ET_REAL()) then true;
    case (DAE.ET_STRING()) then true;
    case (DAE.ET_BOOL()) then true;
    case (_) then false;
  end matchcontinue;
end typeBuiltin;

public function isWholeDim ""
  input DAE.Subscript s;
  output Boolean b;
algorithm
  b := matchcontinue(s)
    case(DAE.WHOLEDIM) then true;
    case(_) then false;
  end matchcontinue;
end isWholeDim;

public function isInt ""
  input Type it;
  output Boolean re;
algorithm
  re := matchcontinue(it)
    local
      Type t1,t2;
    case(DAE.ET_ARRAY(ty=t2))
      then
        isReal(t2);
    case(DAE.ET_INT) then true;
    case(_) then false;
  end matchcontinue;
end isInt;

public function isReal ""
  input Type it;
  output Boolean re;
algorithm
  re := matchcontinue(it)
    local
      Type t1,t2;
    case(DAE.ET_ARRAY(ty=t2))
      then
        isReal(t2);
    case(DAE.ET_REAL) then true;
    case(_) then false;
  end matchcontinue;
end isReal;

public function isExpReal ""
  input DAE.Exp e;
  output Boolean re;
algorithm
  re := matchcontinue(e)
    local Type t;
    case(e)
      equation
        t = typeof(e);
        then
          isReal(t);
  end matchcontinue;
end isExpReal;

public function isConstFalse
"Return true if expression is false"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case DAE.BCONST(false) then true;
    case (_) then false;
  end matchcontinue;
end isConstFalse;

public function isConstTrue
"Return true if expression is true"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case DAE.BCONST(true) then true;
    case (_) then false;
  end matchcontinue;
end isConstTrue;

public function isConstOne
"function: isConstOne
  Return true if expression is 1"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local Real rval; Integer ival;
    
    // constant real 1.0
    case DAE.RCONST(rval)
      equation
        true = realEq(rval, 1.0);
      then
        true;
    
    // constant integer 1 
    case DAE.ICONST(ival)
      equation
        true = intEq(ival, 1);
      then 
        true;
    
    // anything else
    case (_) then false;
  end matchcontinue;
end isConstOne;

public function isConstMinusOne
"function: isConstMinusOne
  Return true if expression is -1"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local Real rval; Integer ival;
    
    // is real -1.0
    case DAE.RCONST(rval)
      equation
        true = realEq(rval, -1.0);
      then
        true;
    
    // is integer 1
    case DAE.ICONST(ival)
      equation
         true = intEq(ival, -1);
      then 
        true;
    
    // anything else
    case (_) then false;
  end matchcontinue;
end isConstMinusOne;


public function containVectorFunctioncall
"Returns true if expression or subexpression is a
 functioncall that returns an array, otherwise false.
  Note: the der operator is represented as a
        function call but still return false."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local
      DAE.Exp e1,e2,e,e3;
      Boolean res;
      list<Boolean> blst;
      list<DAE.Exp> elst;
      list<tuple<DAE.Exp, Boolean>> flatexplst;
      list<list<tuple<DAE.Exp, Boolean>>> explst;
      Option<DAE.Exp> optexp;
    
    // der is not a vector function
    case (DAE.CALL(path = Absyn.IDENT(name = "der"))) then false;
    
    // pre is not a vector function, adrpo: 2009-03-03 -> pre is also needed here!
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    
    // inStream and actualStream are not a vector function, adrpo: 2010-08-31 -> they are also needed here!
    case (DAE.CALL(path = Absyn.IDENT(name = "inStream"))) then false;
    case (DAE.CALL(path = Absyn.IDENT(name = "actualStream"))) then false;      
    
    // a call that has an return array type returns true 
    case (DAE.CALL(path = _, ty = DAE.ET_ARRAY(_,_))) then true;
    
    // any other call returns false
    case (DAE.CALL(path = _)) then false;
    
    // partial evaluation
    case (DAE.PARTEVALFUNCTION(path = _, expList = elst)) // stefan
      equation
        blst = Util.listMap(elst,containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    
    // binary operators, e1 has a vector function call
    case (DAE.BINARY(exp1 = e1,exp2 = e2)) 
      equation
        true = containVectorFunctioncall(e1);
      then
        true;    
    // binary operators, e2 has a vector function call
    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // unary operators
    case (DAE.UNARY(exp = e))
      equation
        res = containVectorFunctioncall(e);
      then
        res;
    // logical binary operators, e1 is a vector call
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // logical binary operators, e2 is a vector call
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // logical unary operators, e is a vector call
    case (DAE.LUNARY(exp = e))
      equation
        res = containVectorFunctioncall(e);
      then
        res;
    // relations e1 op e2, where e1 is a vector call
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // relations e1 op e2, where e2 is a vector call
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // if expression where the condition is a vector call
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // if expression where the then part is a vector call
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // if expression where the else part is a vector call
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containVectorFunctioncall(e3);
      then
        true;
    // arrays 
    case (DAE.ARRAY(array = elst))
      equation
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // matrixes
    case (DAE.MATRIX(scalar = explst))
      equation
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // ranges [e1:step:e2], where e1 is a vector call
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // ranges [e1:step:e2], where e2 is a vector call
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // ranges [e1:step:e2], where step is a vector call
    case (DAE.RANGE(exp = e1,expOption = SOME(e),range = e2))
      equation
        true = containVectorFunctioncall(e);
      then
        true;
    // tuples return true all the time???!! adrpo: FIXME! TODO! is this really true?
    case (DAE.TUPLE(PR = elst))
      equation 
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // cast
    case (DAE.CAST(exp = e))
      equation
        res = containVectorFunctioncall(e);
      then
        res;
    // size operator
    case (DAE.SIZE(exp = e1,sz = optexp))      
      equation
        true = containVectorFunctioncall(e1);
      then
        true;
    // size operator
    case (DAE.SIZE(exp = e1,sz = SOME(e2)))
      equation
        true = containVectorFunctioncall(e2);
      then
        true;
    // any other expressions return false
    case (_) then false;
  end matchcontinue;
end containVectorFunctioncall;

public function containFunctioncall
"function: containFunctioncall
  Returns true if expression or subexpression
  is a functioncall, otherwise false.
  Note: the der and pre operators are represented
        as function calls but still returns false."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    local
      DAE.Exp e1,e2,e,e3;
      Boolean res;
      list<Boolean> blst;
      list<DAE.Exp> elst;
      list<tuple<DAE.Exp, Boolean>> flatexplst;
      list<list<tuple<DAE.Exp, Boolean>>> explst;
      Option<DAE.Exp> optexp;
    
    // der(x) is not a function call
    case (DAE.CALL(path = Absyn.IDENT(name = "der"))) then false;
    // pre(x) is not a function call
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    // any other call is a function call
    case (DAE.CALL(path = _)) then true;
    // partial evaluation functions
    case (DAE.PARTEVALFUNCTION(path = _, expList = elst)) // stefan
      equation
        blst = Util.listMap(elst,containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // binary
    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.BINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // unary
    case (DAE.UNARY(exp = e))
      equation
        res = containFunctioncall(e);
      then
        res;
    // logical binary
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e1);
      then
        true; 
    case (DAE.LBINARY(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // logical unary
    case (DAE.LUNARY(exp = e))
      equation
        res = containFunctioncall(e);
      then
        res;
    // relations
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.RELATION(exp1 = e1,exp2 = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // if expressions
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containFunctioncall(e2);
      then
        true;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        true = containFunctioncall(e3);
      then
        true;
    // arrays 
    case (DAE.ARRAY(array = elst))
      equation
        blst = Util.listMap(elst, containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // matrix
    case (DAE.MATRIX(scalar = explst))
      equation
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        blst = Util.listMap(elst, containFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // ranges
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containFunctioncall(e1);
      then
        true; 
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2))
      equation
        true = containFunctioncall(e2);
      then
        true;
    case (DAE.RANGE(exp = e1,expOption = SOME(e),range = e2))
      equation
        true = containFunctioncall(e);
      then
        true;
    // tuples return true all the time???!! adrpo: FIXME! TODO! is this really true?
    case (DAE.TUPLE(PR = elst))
      equation 
        blst = Util.listMap(elst, containVectorFunctioncall);
        res = Util.boolOrList(blst);
      then
        res;
    // cast
    case (DAE.CAST(exp = e))
      equation
        res = containFunctioncall(e);
      then
        res;
    // size
    case (DAE.SIZE(exp = e1,sz = e2))
      local Option<DAE.Exp> e2;
      equation
        true = containFunctioncall(e1);
      then
        true;
    case (DAE.SIZE(exp = e1,sz = SOME(e2)))
      equation
        true = containFunctioncall(e2);
      then
        true;
    // anything else
    case (_) then false;
  end matchcontinue;
end containFunctioncall;

public function expIntOrder "Function: expIntOrder
This function takes a list of Exp, assumes they are all ICONST
and checks wheter the ICONST are in order."
  input Integer expectedValue;
  input list<DAE.Exp> integers;
  output Boolean ob;
algorithm 
  ob := matchcontinue(expectedValue,integers)
    local
      list<DAE.Exp> expl;
      Integer x1,x2;
      Boolean b;
    case(_,{}) then true;
    case(x1, DAE.ICONST(x2)::expl)
      equation
        true = intEq(x1, x2);
        b = expIntOrder(x1+1,expl);
      then 
        b;
    case(_,_) then false;
  end matchcontinue;
end expIntOrder;

public function isArray " function: isArray
returns true if expression is an array.
"
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := matchcontinue(inExp)
    case(DAE.ARRAY(array = _ )) then true;
    case(_) then false;
  end matchcontinue;
end isArray;

public function isMatrix " function: isArray
returns true if expression is an array.
"
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := matchcontinue(inExp)
    case(DAE.MATRIX(scalar = _ )) then true;
    case(_) then false;
  end matchcontinue;
end isMatrix;

public function isUnary " function: isArray
returns true if expression is an array.
"
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB:=
  matchcontinue(inExp)
    local
      DAE.Exp exp1;
    case(exp1 as DAE.UNARY(operator =_))
      then
        true;
    case(_)
    then
      false;
  end matchcontinue;
end isUnary;

public function isCref "
Author: BZ 2008-06, checks wheter an DAE.Exp is cref or not.

alternative name: isExpCref
"
  input DAE.Exp inExp;
  output Boolean outB;
algorithm outB:= matchcontinue(inExp)
    case(DAE.CREF(_,_)) then true;
    case(_) then false;
  end matchcontinue;
end isCref;

public function isCrefArray "Function isCrefArray
Checks wheter a cref is an array or not.
"
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB:=
  matchcontinue(inExp)
    local
      DAE.Exp exp1;
    case(exp1 as DAE.CREF(_,DAE.ET_ARRAY(_,_)))
    then
      true;
    case(_)
    then
      false;
  end matchcontinue;
end isCrefArray;

public function isCrefScalar
  "Checks whether an expression is a scalar cref or not."
  input DAE.Exp inExp;
  output Boolean isScalar;
algorithm
  isScalar := matchcontinue(inExp)
    case DAE.CREF(ty = DAE.ET_ARRAY(ty = _))
      local ComponentRef cr; Boolean b;
      equation
        cr = expCref(inExp);
        b = ComponentReference.crefHasScalarSubscripts(cr);
      then
        b;
    case DAE.CREF(ty = _) then true;
    case _ then false;
  end matchcontinue;
end isCrefScalar;

public function expCanBeZero "Returns true if it is possible that the expression can be zero.

For instance,
expCanBeZero(1) => false
expCanBeZero(a+b) => true  (for a = -b)
expCanBeZero(1+a^2) => false (all terms positive)
"
  input DAE.Exp e;
  output Boolean canBeZero;
algorithm
  canBeZero := matchcontinue(e)
    local list<DAE.Exp> terms;

    case(e) equation
      true = isConst(e) and not isZero(e);
    then false;

      /* For several terms, all must be positive or zero and at least one must be > 0 */
    case(e) equation
      (terms as _::_) = terms(e);
      true = Util.boolAndList(Util.listMap(terms,expIsPositiveOrZero));
      _::_ = Util.listSelect(terms,expIsPositive);
    then false;

    case(e) then true;
  end matchcontinue;
end expCanBeZero;

public function expIsPositive "Returns true if an expression is positive,
Returns true in the following cases:
constant >= 0

See also expIsPositiveOrZero.
"
  input DAE.Exp e;
  output Boolean res;
algorithm
  res := matchcontinue(e)
    local DAE.Exp e1,e2;

     /* constant >= 0 */
    case(e) equation
      true = isConst(e);
      false = expReal(e) <. intReal(0);
    then true;

    case(_) then false;
  end matchcontinue;
end expIsPositive;

public function expIsPositiveOrZero "Returns true if an expression is positive or equal to zero,
Returns true in the following cases:
constant >= 0
a^n, for even n.
abs(expr)
"
  input DAE.Exp e;
  output Boolean res;
algorithm
  res := matchcontinue(e)
    local DAE.Exp e1,e2;

     /* constant >= 0 */
    case(e) equation
      true = isConst(e);
      false = expReal(e) <. intReal(0);
    then true;

      /* e1 ^ n for even n */
    case(DAE.BINARY(e1,DAE.POW(_),e2)) equation
      true = isEven(e2);
    then true;

    /* expr * expr */
    case(DAE.BINARY(e1,DAE.MUL(_),e2)) equation
      true = expEqual(e1,e2);
    then true;
    case(_) then false;
  end matchcontinue;
end expIsPositiveOrZero;

public function isEven "returns true if expression is even"
  input DAE.Exp e;
  output Boolean even;
algorithm
  even := matchcontinue(e)
  local Integer i;
    case(DAE.ICONST(i)) equation
     0 = intMod(i,2);
    then true;
    case(_) then false;
  end matchcontinue;
end isEven;

public function isIntegerOrReal "Returns true if Type is Integer or Real"
input Type tp;
output Boolean res;
algorithm
  res := matchcontinue(tp)
    case(DAE.ET_REAL()) then  true;
    case(DAE.ET_INT()) then true;
    case(_) then false;
  end matchcontinue;
end isIntegerOrReal;

public function expEqual
"function: expEqual
  Returns true if the two expressions are equal."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp1,inExp2)
    local
      Integer c1,c2,i1,i2;
      Ident id1,id2;
      Boolean b1,c1_1,c2_1,b2,res,b3;
      DAE.Exp e11,e12,e21,e22,e1,e2,e13,e23,r1,r2;
      Operator op1,op2;
      list<Boolean> bs;
      Absyn.Path path1,path2;
      list<DAE.Exp> expl1,expl2;
      Type tp1,tp2;
    
    // check for pointer equality first, if they point to the same thing, they are equal
    case (inExp1,inExp2)
      equation
        true = System.refEqual(inExp1,inExp2);
      then
        true;    
    
    // integers
    case (DAE.ICONST(integer = c1),DAE.ICONST(integer = c2)) then (c1 == c2);
    // reals
    case (DAE.RCONST(real = c1),DAE.RCONST(real = c2))
      local Real c1,c2;
      then
        (c1 ==. c2);
    // strings
    case (DAE.SCONST(string = c1),DAE.SCONST(string = c2))
      local Ident c1,c2;
      equation
        true = stringEqual(c1, c2);
      then
        true;
    // booleans
    case (DAE.BCONST(bool = c1),DAE.BCONST(bool = c2))
      local Boolean c1,c2;
      equation
        res = Util.boolEqual(c1, c2);
      then
        res;
    // enumeration literals
    case (DAE.ENUM_LITERAL(name = enum1), DAE.ENUM_LITERAL(name = enum2))
      local Absyn.Path enum1, enum2;
      equation
        res = Absyn.pathEqual(enum1, enum2);
      then
        res;
    // crefs
    case (DAE.CREF(componentRef = c1),DAE.CREF(componentRef = c2))
      local ComponentRef c1,c2;
      equation
        res = ComponentReference.crefEqual(c1, c2);
      then
        res;
    // binary ops
    case (DAE.BINARY(exp1 = e11,operator = op1,exp2 = e12),DAE.BINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // logical binary ops
    case (DAE.LBINARY(exp1 = e11,operator = op1,exp2 = e12),
          DAE.LBINARY(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // unary ops
    case (DAE.UNARY(operator = op1,exp = e1),DAE.UNARY(operator = op2,exp = e2))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e1, e2);
        res = boolAnd(b1, b2);
      then
        res;
    // logical binary ops
    case (DAE.LUNARY(operator = op1,exp = e1),DAE.LUNARY(operator = op2,exp = e2))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e1, e2);
        res = boolAnd(b1, b2);
      then
        res;
    // relational ops
    case (DAE.RELATION(exp1 = e11,operator = op1,exp2 = e12),DAE.RELATION(exp1 = e21,operator = op2,exp2 = e22))
      equation
        b1 = operatorEqual(op1, op2);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // if expressions
    case (DAE.IFEXP(expCond = e11,expThen = e12,expElse = e13),DAE.IFEXP(expCond = e21,expThen = e22,expElse = e23))
      equation
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // function calls
    case (DAE.CALL(path = path1,expLst = expl1),DAE.CALL(path = path2,expLst = expl2))
      equation
        b1 = ModUtil.pathEqual(path1, path2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList((b1 :: bs));
      then
        res;
    // partially evaluated functions
    case (DAE.PARTEVALFUNCTION(path = path1,expList = expl1),DAE.PARTEVALFUNCTION(path = path2,expList = expl2))
      equation
        b1 = ModUtil.pathEqual(path1, path2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList((b1 :: bs));
      then
        res;
    // arrays
    case (DAE.ARRAY(ty = tp1,array = expl1),DAE.ARRAY(ty = tp2,array = expl2))
      equation
        equality(tp1 = tp2);
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList(bs);
      then
        res;
    // matrix
    case (e1 as DAE.MATRIX(ty = _), e2 as DAE.MATRIX(ty = _))
      equation
        equality(e1 = e2); // TODO! FIXME! should use expEqual on elements
      then
        true;
    case (e1 as DAE.MATRIX(ty = _), e2 as DAE.MATRIX(ty = _))
      equation
        failure(equality(e1 = e2)); // TODO! FIXME! should use expEqual on elements
      then
        false;
    // ranges [start:stop]
    case (DAE.RANGE(ty = tp1,exp = e11,expOption = NONE(),range = e13),DAE.RANGE(ty = tp2,exp = e21,expOption = NONE(),range = e23))
      equation
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        res = Util.boolAndList({b1,b2});
      then
        res;
    // ranges [start:step:stop]
    case (DAE.RANGE(ty = tp1,exp = e11,expOption = SOME(e12),range = e13),DAE.RANGE(ty = tp2,exp = e21,expOption = SOME(e22),range = e23))
      equation
        b1 = expEqual(e13, e23);
        b2 = expEqual(e11, e21);
        b3 = expEqual(e12, e22);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // tuples
    case (DAE.TUPLE(PR = expl1),DAE.TUPLE(PR = expl2))
      equation
        bs = Util.listThreadMap(expl1, expl2, expEqual);
        res = Util.boolAndList(bs);
      then
        res;
    // casting
    case (DAE.CAST(ty = tp1,exp = e1),DAE.CAST(ty = tp2,exp = e2))
      equation
        equality(tp1 = tp2);
        res = expEqual(e1, e2);
      then
        res;
    // array subscripts
    case (DAE.ASUB(exp = e1,sub = ae1),DAE.ASUB(exp = e2,sub = ae2))
      local
        list<DAE.Exp> ae1,ae2;
      equation
        bs = Util.listThreadMap(ae1, ae2, expEqual);
        res = Util.boolAndList(bs);
        b2 = expEqual(e1, e2);
        res = boolAnd(res, b2);
      then
        res;
    // size(a)
    case (DAE.SIZE(exp = e1,sz = NONE()),DAE.SIZE(exp = e2,sz = NONE()))
      equation
        res = expEqual(e1, e2);
      then
        res;
    // size(a, dim)
    case (DAE.SIZE(exp = e1,sz = SOME(e11)),DAE.SIZE(exp = e2,sz = SOME(e22)))
      equation
        b1 = expEqual(e1, e2);
        b2 = expEqual(e11, e22);
        res = boolAnd(b1, b2);
      then
        res;
    // metamodeling code
    case (DAE.CODE(code = _),DAE.CODE(code = _))
      equation
        Debug.fprint("failtrace","exp_equal on CODE not impl.\n");
      then
        false;
    case (DAE.REDUCTION(path = path1,expr = e1,ident = id1,range = r1),DAE.REDUCTION(path = path2,expr = e2,ident = id2,range = r2))
      equation
        true = stringEqual(id1, id2);
        b1 = ModUtil.pathEqual(path1, path2);
        b2 = expEqual(e1, e2);
        b3 = expEqual(r1, r2);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    // end id
    case (DAE.END(),DAE.END()) then true;
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
    case (_,_) then false;
  end matchcontinue;
end expEqual;

public function expContains
"function: expContains
  Returns true if first expression contains the
  second one as a sub expression. Only component
  references or der(componentReference) can be
  checked so far."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp1,inExp2)
    local
      Integer i;
      DAE.Exp cr,c1,c2,e1,e2,e,c,t,f,cref;
      Ident s,str;
      Boolean res,res1,res2,res3;
      list<Boolean> reslist;
      list<DAE.Exp> explist,expl_2,args;
      list<tuple<DAE.Exp, Boolean>> expl_1;
      list<list<tuple<DAE.Exp, Boolean>>> expl;
      ComponentRef cr1,cr2;
      Operator op;
      Absyn.Path fcn;
    
    case (DAE.ICONST(integer = _),cr) then false;
    case (DAE.RCONST(real = _),cr) then false;
    case (DAE.SCONST(string = _),cr) then false;
    case (DAE.BCONST(bool = _),cr) then false;
    case (DAE.ARRAY(array = explist),cr)
      equation
        reslist = Util.listMap1(explist, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (DAE.MATRIX(scalar = expl),cr)
      equation
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        reslist = Util.listMap1(expl_2, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case ((c1 as DAE.CREF(componentRef = cr1)),(c2 as DAE.CREF(componentRef = cr2)))
      equation
        res = ComponentReference.crefEqual(cr1, cr2);
      then
        res;
    case ((c1 as DAE.CREF(componentRef = cr1)),c2 ) then false;
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),cr )
      equation
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (DAE.UNARY(operator = op,exp = e),cr)
      equation
        res = expContains(e, cr);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),cr)
      equation
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (DAE.LUNARY(operator = op,exp = e),cr )
      equation
        res = expContains(e, cr);
      then
        res;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),cr)
      equation
        res1 = expContains(e1, cr);
        res2 = expContains(e2, cr);
        res = boolOr(res1, res2);
      then
        res;
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f),cr)
      equation
        res1 = expContains(c, cr);
        res2 = expContains(t, cr);
        res3 = expContains(f, cr);
        res = Util.boolOrList({res1,res2,res3});
      then
        res;
    case(DAE.CALL(path=Absyn.IDENT(name="der"),expLst={DAE.CREF(cr1,_)}),
         DAE.CALL(path=Absyn.IDENT(name="der"),expLst={DAE.CREF(cr2,_)})) 
      equation
        res = ComponentReference.crefEqual(cr1,cr2);
      then res;
    // pre(v) does not contain variable v
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {cref}),cr) then false;
    // special rule for no arguments
    case (DAE.CALL(expLst = {}),_) then false;
    // general case for arguments
    case (DAE.CALL(path = fcn,expLst = args),(cr as DAE.CREF(componentRef = _)))
      equation
        reslist = Util.listMap1(args, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (DAE.PARTEVALFUNCTION(path = fcn,expList = args),(cr as DAE.CREF(componentRef = _)))
      equation
        reslist = Util.listMap1(args, expContains, cr);
        res = Util.boolOrList(reslist);
      then
        res;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = DAE.ICONST(integer = i)),cr ) then false;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e),cr )
      equation
        res = expContains(e, cr);
      then
        res;
    case (DAE.ASUB(exp = e,sub = _),cr)
      equation
        res = expContains(e, cr);
      then
        res;
		case (DAE.REDUCTION(expr = e), cr)
			equation
				res = expContains(e, cr);
			then
				res;
    case (e,cr)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Expression.expContains failed\n");
        s = ExpressionDump.printExpStr(e);
        str = System.stringAppendList({"exp = ",s,"\n"});
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end expContains;

public function containsExp
"function containsExp
  Author BZ 2008-06 same as expContains, but reversed."
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
  res := matchcontinue(e)
    case(DAE.CREF(_,_)) then true;
    case(DAE.IFEXP(_,_,_)) then true;
    case(_) then false;
  end matchcontinue;
end isExpCrefOrIfExp;

protected function operatorEqual
"function: operatorEqual
  Helper function to expEqual."
  input Operator inOperator1;
  input Operator inOperator2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inOperator1,inOperator2)
    local
      Boolean res;
      Absyn.Path p1,p2;
    case (DAE.ADD(ty = _),DAE.ADD(ty = _)) then true;
    case (DAE.SUB(ty = _),DAE.SUB(ty = _)) then true;
    case (DAE.MUL(ty = _),DAE.MUL(ty = _)) then true;
    case (DAE.DIV(ty = _),DAE.DIV(ty = _)) then true;
    case (DAE.POW(ty = _),DAE.POW(ty = _)) then true;
    case (DAE.UMINUS(ty = _),DAE.UMINUS(ty = _)) then true;
    case (DAE.UMINUS_ARR(ty = _),DAE.UMINUS_ARR(ty = _)) then true;
    case (DAE.UPLUS_ARR(ty = _),DAE.UPLUS_ARR(ty = _)) then true;
    case (DAE.ADD_ARR(ty = _),DAE.ADD_ARR(ty = _)) then true;
    case (DAE.SUB_ARR(ty = _),DAE.SUB_ARR(ty = _)) then true;
    case (DAE.MUL_ARR(ty = _),DAE.MUL_ARR(ty = _)) then true;
    case (DAE.DIV_ARR(ty = _),DAE.DIV_ARR(ty = _)) then true;
    case (DAE.MUL_SCALAR_ARRAY(ty = _),DAE.MUL_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.MUL_ARRAY_SCALAR(ty = _),DAE.MUL_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.ADD_SCALAR_ARRAY(ty = _),DAE.ADD_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.ADD_ARRAY_SCALAR(ty = _),DAE.ADD_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.SUB_SCALAR_ARRAY(ty = _),DAE.SUB_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.SUB_ARRAY_SCALAR(ty = _),DAE.SUB_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.MUL_SCALAR_PRODUCT(ty = _),DAE.MUL_SCALAR_PRODUCT(ty = _)) then true;
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),DAE.MUL_MATRIX_PRODUCT(ty = _)) then true;
    case (DAE.DIV_SCALAR_ARRAY(ty = _),DAE.DIV_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.DIV_ARRAY_SCALAR(ty = _),DAE.DIV_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.POW_SCALAR_ARRAY(ty = _),DAE.POW_SCALAR_ARRAY(ty = _)) then true;
    case (DAE.POW_ARRAY_SCALAR(ty = _),DAE.POW_ARRAY_SCALAR(ty = _)) then true;
    case (DAE.POW_ARR(ty = _),DAE.POW_ARR(ty = _)) then true;
    case (DAE.POW_ARR2(ty = _),DAE.POW_ARR2(ty = _)) then true;
    case (DAE.AND(),DAE.AND()) then true;
    case (DAE.OR(),DAE.OR()) then true;
    case (DAE.NOT(),DAE.NOT()) then true;
    case (DAE.LESS(ty = _),DAE.LESS(ty = _)) then true;
    case (DAE.LESSEQ(ty = _),DAE.LESSEQ(ty = _)) then true;
    case (DAE.GREATER(ty = _),DAE.GREATER(ty = _)) then true;
    case (DAE.GREATEREQ(ty = _),DAE.GREATEREQ(ty = _)) then true;
    case (DAE.EQUAL(ty = _),DAE.EQUAL(ty = _)) then true;
    case (DAE.NEQUAL(ty = _),DAE.NEQUAL(ty = _)) then true;
    case (DAE.USERDEFINED(fqName = p1),DAE.USERDEFINED(fqName = p2))
      equation
        res = ModUtil.pathEqual(p1, p2);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end operatorEqual;

public function arrayContainZeroDimension " function containZeroDimension
Check wheter an arrayDim contains a zero dimension or not.
"
input list<DAE.Dimension> inDim;
output Boolean zero;

algorithm
  zero :=
  matchcontinue(inDim)
    local
      DAE.Dimension d;
      list<DAE.Dimension> iLst;
      Integer x;
      Boolean retVal;
    case({}) then true;

    case (DAE.DIM_UNKNOWN() :: iLst)
      equation
        retVal = arrayContainZeroDimension(iLst);
      then
        retVal;

    case (d :: iLst)
      equation
        false = (dimensionSize(d) >= 1);
        retVal = arrayContainZeroDimension(iLst);
      then
        retVal;

    case(_) then false;
end matchcontinue;
end arrayContainZeroDimension;

public function arrayContainWholeDimension
  "Checks if a list of dimensions contain a wholedim, i.e. NONE."
  input list<DAE.Dimension> inDim;
  output Boolean wholedim;
algorithm
  wholedim := matchcontinue(inDim)
    local
      input list<DAE.Dimension> rest_dims;
    case ({}) then false;
    case (DAE.DIM_UNKNOWN() :: rest_dims) then true;
    case (_ :: rest_dims) then arrayContainZeroDimension(rest_dims);
  end matchcontinue;
end arrayContainWholeDimension;

public function isArrayType
"Returns true if inType is an ET_ARRAY"
  input DAE.ExpType inType;
  output Boolean b;
algorithm
  b := matchcontinue inType
    case DAE.ET_ARRAY(_,_) then true;
    case _ then false;
  end matchcontinue;
end isArrayType;

public function dimensionsEqual
  "Returns whether two dimensions are equal or not."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := matchcontinue(dim1, dim2)
    case (DAE.DIM_UNKNOWN(), _) then true;
    case (_, DAE.DIM_UNKNOWN()) then true;
    case (DAE.DIM_EXP(exp = _), _) then true;
    case (_, DAE.DIM_EXP(exp = _)) then true;
    case (_, _)
      local Boolean b;
      equation
        b = intEq(dimensionSize(dim1), dimensionSize(dim2));
      then
        b;
  end matchcontinue;
end dimensionsEqual;

public function dimensionsKnownAndEqual
  "Checks that two dimensions are specified and equal."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := intEq(dimensionSize(dim1), dimensionSize(dim2));
end dimensionsKnownAndEqual;

public function dimensionKnown
  "Checks whether a dimensions is known or not."
  input DAE.Dimension dim;
  output Boolean known;
algorithm
  known := matchcontinue(dim)
    case DAE.DIM_UNKNOWN() then false;
    case DAE.DIM_EXP(exp = DAE.ICONST(integer = _)) then true;
    case DAE.DIM_EXP(exp = _) then false;
    case _ then true;
  end matchcontinue;
end dimensionKnown;

public function subscriptEqual
"function: subscriptEqual
  Returns true if two subscript lists are equal."
  input list<Subscript> inSubscriptLst1;
  input list<Subscript> inSubscriptLst2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inSubscriptLst1,inSubscriptLst2)
    local
      Boolean res;
      list<Subscript> xs1,xs2;
      DAE.Exp e1,e2;
      
    // both lists are empty 
    case ({},{}) then true;
    
    // wholedims as list heads, compare the rest
    case ((DAE.WHOLEDIM() :: xs1),(DAE.WHOLEDIM() :: xs2))
      equation
        res = subscriptEqual(xs1, xs2);
      then
        res;
    
    // slices as heads, compare the slice exps and then compare the rest
    case ((DAE.SLICE(exp = e1) :: xs1),(DAE.SLICE(exp = e2) :: xs2))
      equation
        res = subscriptEqual(xs1, xs2);
        true = expEqual(e1, e2);
      then
        res;
    
    // indexes as heads, compare the index exps and then compare the rest
    case ((DAE.INDEX(exp = e1) :: xs1),(DAE.INDEX(exp = e2) :: xs2))
      equation
        res = subscriptEqual(xs1, xs2);
        true = expEqual(e1, e2);
      then
        res;
    
    // subscripts are not equal, return false  
    case (_,_) then false;
  end matchcontinue;
end subscriptEqual;

public function subscriptConstants "
returns true if all subscripts are constant values (no slice or wholedim "
  input list<Subscript> subs;
  output Boolean areConstant;
algorithm
  areConstant := matchcontinue(subs)
    case({}) then true;
    case(DAE.INDEX(exp = DAE.ICONST(integer = _)):: subs) 
      equation
        areConstant = subscriptConstants(subs);
      then 
        areConstant;
    case(DAE.INDEX(exp = DAE.ENUM_LITERAL(index = _)) :: subs)
      equation
        areConstant = subscriptConstants(subs);
      then
        areConstant;
    case(_) then false;
  end matchcontinue;
end subscriptConstants;

public function isValidSubscript
  "Checks if an expression is a valid subscript, i.e. an integer or enumeration
  literal."
  input DAE.Exp inSub;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inSub)
    case DAE.ICONST(integer = _) then true;
    case DAE.ENUM_LITERAL(index = _) then true;
    case _ then false;
  end matchcontinue;
end isValidSubscript;

public function subscriptContain "function: subscriptContain
	This function checks whether sub2 contains sub1 or not(DAE.WHOLEDIM)
"
  input list<Subscript> issl1;
  input list<Subscript> issl2;
  output Boolean contained;
algorithm
  contained := matchcontinue(issl1,issl2)
    local
      Boolean b;
      Subscript ss1,ss2;
      list<Subscript> ssl1,ssl2;
    case({},_) then true;
    case(ss1 ::ssl1, (ss2 as DAE.WHOLEDIM())::ssl2)
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
    case((ss1 as DAE.INDEX(e1 as DAE.ICONST(i)))::ssl1, (ss2 as DAE.SLICE(e2 as DAE.ARRAY(_,_,expl))) ::ssl2)
      local DAE.Exp e1,e2; Integer i; list<DAE.Exp> expl;
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
    case(_,_) then false;
  end matchcontinue;
end subscriptContain;

protected function subscriptContain2 "
"
  input Integer inInt;
  input list<DAE.Exp> inExp2;
  output Boolean contained;
algorithm
  contained := matchcontinue(inInt,inExp2)
    local
      Boolean b,b2;
      DAE.Exp e1,e2;
      list<DAE.Exp> expl,expl2;
      Integer i,j;
      case(i,( (e1 as DAE.ICONST(j)) :: expl))
        equation
            true = (i == j);
          then
            true;
      case(i,(( e1 as DAE.ICONST(j)) :: expl))
        equation
            true = subscriptContain2(i,expl);
          then
            true;
      case(i,( (e1 as DAE.ARRAY(_,_,expl2)) :: expl))
        equation
          b = subscriptContain2(i,expl2);
          b2 = subscriptContain2(i,expl);
          b = Util.boolOrList({b,b2});
        then
          b;
      case(_,_) then false;
  end matchcontinue;
end subscriptContain2;

end Expression;

