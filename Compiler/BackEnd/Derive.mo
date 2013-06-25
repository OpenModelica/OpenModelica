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

encapsulated package Derive
" file:        Derive.mo
  package:     Derive
  description: Differentiation of equations from BackendDAE.BackendDAE

  RCS: $Id$

  This module is responsible for symbolic differentiation of equations and
  expressions. Is is currently (2004-09-28) only used by the solve function in
  the exp module for solving equations.

  The symbolic differentiation is used in the Newton-Raphson method and in
  index reduction."

// public imports
public import Absyn;
public import BackendDAE;
public import DAE;
public import DAEUtil;
public import Types;

// protected imports
protected import BackendDump;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import ClassInf;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionDump;
protected import Flags;
protected import Inline;
protected import List;
protected import Util;

public function differentiateEquationTime "function: differentiateEquationTime
  Differentiates an equation with respect to the time variable."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Shared shared;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation,inVariables,shared)
    local
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e1,e2;
      BackendDAE.Variables timevars;
      DAE.ElementSource source,sourceStmt;
      Integer size;
      list<DAE.Exp> out1,expExpLst,expExpLst1;
      DAE.Type exptyp;
      list<Integer> dimSize;
      String msg;
      DAE.SymbolicOperation op1,op2;
      DAE.FunctionTree funcs;
      DAE.Algorithm alg;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;

    // equations
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source),timevars,_) /* time varying variables */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,shared));
        e2_1 = differentiateExpTime(e2, (timevars,shared));
        (e1_2,_) = ExpressionSimplify.simplify(e1_1);
        (e2_2,_) = ExpressionSimplify.simplify(e2_1);
        op1 = DAE.OP_DIFFERENTIATE(DAE.crefTime,e1,e1_2);
        op2 = DAE.OP_DIFFERENTIATE(DAE.crefTime,e2,e2_2);
        source = List.foldr({op1,op2},DAEUtil.addSymbolicTransformation,source);
      then
        BackendDAE.EQUATION(e1_2,e2_2,source,false);

    // complex equations
    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1,right = e2,source=source),timevars,_) /* time varying variables */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,shared));
        e2_1 = differentiateExpTime(e2, (timevars,shared));
       (e1_2,_) = ExpressionSimplify.simplify(e1_1);
       (e2_2,_) = ExpressionSimplify.simplify(e2_1);
        op1 = DAE.OP_DIFFERENTIATE(DAE.crefTime,e1,e1_2);
        op2 = DAE.OP_DIFFERENTIATE(DAE.crefTime,e2,e2_2);
        source = List.foldr({op1,op2},DAEUtil.addSymbolicTransformation,source);
      then
        BackendDAE.COMPLEX_EQUATION(size,e1_2,e2_2,source,false);

    // Array Equations
    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1,right = e2,source=source),timevars,_) /* time varying variables */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,shared));
        e2_1 = differentiateExpTime(e2, (timevars,shared));
        (e1_2,_) = ExpressionSimplify.simplify(e1_1);
        (e2_2,_) = ExpressionSimplify.simplify(e2_1);
        op1 = DAE.OP_DIFFERENTIATE(DAE.crefTime,e1,e1_2);
        op2 = DAE.OP_DIFFERENTIATE(DAE.crefTime,e2,e2_2);
        source = List.foldr({op1,op2},DAEUtil.addSymbolicTransformation,source);
      then
        BackendDAE.ARRAY_EQUATION(dimSize,e1_2,e2_2,source,false);
    // diverivative of function with multiple outputs
    case (BackendDAE.ALGORITHM(size = size,alg=alg,source=source),timevars,BackendDAE.SHARED(functionTree=funcs))
      equation
        // get Allgorithm
        DAE.ALGORITHM_STMTS(statementLst= {DAE.STMT_TUPLE_ASSIGN(type_=exptyp,expExpLst=expExpLst,exp = e1,source=sourceStmt)}) = alg;
        e1_1 = differentiateFunctionTime(e1,(timevars,shared));
        (e2,source,_) = Inline.inlineExp(e1_1,(SOME(funcs),{DAE.NORM_INLINE()}),source);
        (expExpLst1,out1) = differentiateFunctionTimeOutputs(e1,e2,expExpLst,expExpLst,(timevars,shared));
        op1 = DAE.OP_DIFFERENTIATE(DAE.crefTime,e1,e2);
        source = DAEUtil.addSymbolicTransformation(source,op1);
        alg = DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(exptyp,expExpLst1,e2,sourceStmt)});
       then
        BackendDAE.ALGORITHM(size,alg,source);

    // if-equations
    case (BackendDAE.IF_EQUATION(conditions=expExpLst, eqnstrue=eqnslst, eqnsfalse=eqns, source=source),timevars,_) /* time varying variables */
      equation
        eqnslst = List.map2List(eqnslst,differentiateEquationTime,timevars,shared);
        eqns = List.map2(eqns,differentiateEquationTime,timevars,shared);
      then
        BackendDAE.IF_EQUATION(expExpLst,eqnslst,eqns,source);

     case (_,_,_)
      equation
        msg = "- Derive.differentiateEquationTime failed for " +& BackendDump.equationString(inEquation) +& "\n";
        source = BackendEquation.equationSource(inEquation);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
  end matchcontinue;
end differentiateEquationTime;

public function differentiateExpTime "function: differentiateExpTime
  This function differentiates expressions with respect to the \'time\' variable.
  All other variables that are varying over time are given as the second variable.
  For instance, given the model:
  model test
    Real x,y;
    parameter Real PI=3.14;
  equation
    x+y=5PI;
  end test;
  gives
  differentiate_exp_time(\'x+y=5PI\', {x,y}) => der(x)+der(y)=0"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.Shared> inVariables;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inVariables)
    local
      DAE.Type tp,tp1;
      DAE.ComponentRef cr;
      list<list<DAE.ComponentRef>> crefslstls;
      list<DAE.ComponentRef> crefs;
      list<Boolean> blst;
      String e_str;
      DAE.Exp e,e_1,e1_1,e2_1,e1,e2,e3_1,e3,d_e1,exp,e0,zero,call1,call2;
      BackendDAE.Variables timevars,knvars;
      DAE.Operator op;
      list<DAE.Exp> expl_1,expl,sub;
      Absyn.Path a,fname;
      Boolean b;
      Integer i;
      DAE.FunctionTree functions;
      list<list<DAE.Exp>> explstlst,explstlst1;
      list<DAE.Var> varLst;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators iters;
      DAE.CallAttributes attr;
      BackendDAE.VarKind kind;
      Real r;
      BackendDAE.Var var;

    case (DAE.ICONST(integer = _),_) then DAE.RCONST(0.0);
    case (DAE.RCONST(real = _),_) then DAE.RCONST(0.0);

    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident = "time",subscriptLst = {}),ty = tp),_)
      then DAE.RCONST(1.0);

  // case for Records
    case ((e as DAE.CREF(componentRef = cr,ty = tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(a)))),(timevars,_))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        expl_1 = List.map1(expl, differentiateExpTime, inVariables);
      then
        DAE.CALL(a,expl_1,DAE.CALL_ATTR(tp,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
    // case for arrays
    case ((e as DAE.CREF(componentRef = cr,ty = tp as DAE.T_ARRAY(dims=_))),(_,BackendDAE.SHARED(functionTree=functions)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(SOME(functions),false)));
      then
        differentiateExpTime(e1,inVariables);

    // Constants, known variables, parameters and discrete variables have a 0-derivative, not the inputs
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(_,BackendDAE.SHARED(knownVars=knvars)))
      equation
        (var::{},_) = BackendVariable.getVar(cr, knvars);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then zero;

    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,_)) /* special rule for DUMMY_STATES, they become DUMMY_DER */
      equation
        ({BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())},_) = BackendVariable.getVar(cr, timevars);
        cr = ComponentReference.crefPrefixDer(cr);
        e = Expression.makeCrefExp(cr, tp);
      then
        e;
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,_))
      equation
        ({BackendDAE.VAR(varKind = kind)},_) = BackendVariable.getVar(cr, timevars);
        true = listMember(kind,{BackendDAE.DISCRETE(),BackendDAE.PARAM(),BackendDAE.CONST()});
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then zero;

    // Continuous-time variables (and for shared eq-systems, also unknown variables: keep them as-is)
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,_))
      equation
        // ({BackendDAE.VAR(varKind = BackendDAE.STATE(index=_))},_) = BackendVariable.getVar(cr, timevars);
      then DAE.CALL(Absyn.IDENT("der"),{e},DAE.CALL_ATTR(tp,false,true,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    // der(sign(x)) -> 0
    case (DAE.CALL(path = Absyn.IDENT("sign"),expLst = {e}),_)
      then
        DAE.RCONST(0.0);

    // der(sin(x)) = der(x)cos(x)
    case (DAE.CALL(path = Absyn.IDENT("sin"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.T_REAL_DEFAULT),
          DAE.CALL(Absyn.IDENT("cos"),{e},DAE.callAttrBuiltinReal));

    // der(cos(x)) = -der(x)sin(x)
    case (DAE.CALL(path = Absyn.IDENT("cos"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),DAE.BINARY(e_1,DAE.MUL(DAE.T_REAL_DEFAULT),
          DAE.CALL(Absyn.IDENT("sin"),{e},DAE.callAttrBuiltinReal)));

    // der(tan(x)) = der(x) / cos(x)^2
    case (DAE.CALL(path = Absyn.IDENT("tan"),expLst = {e}),_)
      equation
        e1 = differentiateExpTime(e, inVariables);
        e2 = Expression.makeBuiltinCall("cos",{e},DAE.T_REAL_DEFAULT);
      then
        DAE.BINARY(e1,DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(e2,DAE.POW(DAE.T_REAL_DEFAULT),DAE.RCONST(2.0)));

    // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = Absyn.IDENT("acos"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e))},
                   DAE.callAttrBuiltinReal)));

    // der(arcsin(x)) = der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = Absyn.IDENT("asin"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables)  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),
         DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e))},
                  DAE.callAttrBuiltinReal));

    // der(arctan(x)) = der(x)/(1+x^2)
    case (DAE.CALL(path = Absyn.IDENT("atan"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables)  ;
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e)));

    // der(arctan2(y,0)) = der(sign(y)*pi/2) = 0
    case (DAE.CALL(path = Absyn.IDENT("atan2"),expLst = {e,e1}),_)
      equation
        true = Expression.isZero(e1);
        (exp,_) = Expression.makeZeroExpression({});
      then
        exp;

    // der(arctan2(y,x)) = der(y/x)/1+(y/x)^2
    case (DAE.CALL(path = Absyn.IDENT("atan2"),expLst = {e,e1}),_)
      equation
        false = Expression.isZero(e1);
        exp = Expression.makeDiv(e,e1);
        e_1 = differentiateExpTime(exp, inVariables);
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e)));

    // der(exp(x)) = der(x)exp(x)
    case (DAE.CALL(path = fname as Absyn.IDENT("exp"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.T_REAL_DEFAULT),
          DAE.CALL(fname,{e},DAE.callAttrBuiltinReal));

    // der(sinh(x)) = der(x)cosh(x)
    case (DAE.CALL(path = Absyn.IDENT("sinh"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.T_REAL_DEFAULT),
          DAE.CALL(Absyn.IDENT("cosh"),{e},DAE.callAttrBuiltinReal));

    // der(cosh(x)) = der(x)sinh(x)
    case (DAE.CALL(path = Absyn.IDENT("cosh"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.T_REAL_DEFAULT),
          DAE.CALL(Absyn.IDENT("sinh"),{e},DAE.callAttrBuiltinReal));

    // der(tanh(x)) = der(x) / cosh(x)^2
    case (DAE.CALL(path = Absyn.IDENT("tanh"),expLst = {e}),_)
      equation
        e1 = differentiateExpTime(e, inVariables);
        e2 = Expression.makeBuiltinCall("cosh",{e},DAE.T_REAL_DEFAULT);
      then
        DAE.BINARY(e1,DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(e2,DAE.POW(DAE.T_REAL_DEFAULT),DAE.RCONST(2.0)));

    // der(log(x)) = der(x)/x
    case (DAE.CALL(path = Absyn.IDENT("log"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),e);

    // der(log10(x)) = der(x)/(ln(10)*x)
    case (DAE.CALL(path = Absyn.IDENT("log10"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
        r = realLn(10.0);
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),DAE.BINARY(DAE.RCONST(r),DAE.MUL(DAE.T_REAL_DEFAULT),e));


    case (DAE.CALL(path = fname as Absyn.IDENT("max"),expLst = {e1,e2},attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(e1,DAE.GREATER(tp),e2,-1,NONE())},DAE.callAttrBuiltinBool), e1_1, e2_1);

    case (e as DAE.CALL(path = fname as Absyn.IDENT("max"),expLst = expl,attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        /* TODO: Implement Derivative of max(a,b,...,n)  */
        e_str = ExpressionDump.printExpStr(e);
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (DAE.CALL(path = fname as Absyn.IDENT("min"),expLst = {e1,e2},attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.IFEXP(DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(e1,DAE.LESS(tp),e2,-1,NONE())},DAE.callAttrBuiltinBool), e1_1, e2_1);

    case (e as DAE.CALL(path = fname as Absyn.IDENT("min"),expLst = expl,attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        /* TODO: Implement Derivative of min(a,b,...,n)  */
        e_str = ExpressionDump.printExpStr(e);
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (e0 as DAE.CALL(path = Absyn.IDENT("sqrt"),expLst = {e}),_)
      equation
        e_1 = differentiateExpTime(e, inVariables) "sqrt(x) = der(x)/(2*sqrt(x))" ;
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.T_REAL_DEFAULT),e0));

    case (DAE.CALL(path = fname as Absyn.IDENT("cross"),expLst = {e1,e2},attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
        call1 = Expression.makeBuiltinCall("cross",{e1,e2_1},tp);
        call2 = Expression.makeBuiltinCall("cross",{e1_1,e2},tp);
      then
        DAE.BINARY(call1,DAE.ADD_ARR(tp),call2);

    case (DAE.CALL(path = fname as Absyn.IDENT("smooth"),expLst = {DAE.ICONST(i),e2},attr=attr),_)
      equation
        true = intGe(i,1);
        e1_1 = Expression.expSub(DAE.ICONST(i), DAE.ICONST(1));
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.CALL(Absyn.IDENT("smooth"), {e1_1,e2_1}, attr);

    case (DAE.CALL(path = fname as Absyn.IDENT("smooth"),expLst = {e1,e2},attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        e2_1;

    case (DAE.CALL(path = fname as Absyn.IDENT("transpose"),expLst=expl,attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        expl_1 = List.map1(expl, differentiateExpTime, inVariables);
      then
        Expression.makeBuiltinCall("transpose",expl_1,tp);

    // abs(x)
    case (DAE.CALL(path=Absyn.IDENT("abs"), expLst={exp},attr=DAE.CALL_ATTR(ty=tp)),_)
      equation
        e1_1 = differentiateExpTime(exp, inVariables);
      then
        DAE.IFEXP(DAE.RELATION(exp,DAE.GREATER(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE()), e1_1, DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),e1_1));

    // x^r
    case (e0 as DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.RCONST(real=r))),_) /* ax^(a-1) */
      equation
        d_e1 = differentiateExpTime(e1, inVariables) "e^x => xder(e)e^x-1" ;
        // false = Expression.expContains(e2, Expression.makeCrefExp(tv,tp));
        // const_one = differentiateExp(Expression.makeCrefExp(tv,tp), tv);
        r = r -. 1.0;
        exp = DAE.BINARY(
          DAE.BINARY(d_e1,DAE.MUL(tp),e2),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.RCONST(r)));
      then
        exp;

    // r^x
    case (e0 as DAE.BINARY(exp1 = (e1 as DAE.RCONST(real=r)),operator = DAE.POW(tp),exp2 = e2),_) /* r^x*ln(r)*der(x) */
      equation
        d_e1 = differentiateExpTime(e2, inVariables);
        r = realLn(r);
        exp = DAE.BINARY(DAE.BINARY(e0,DAE.MUL(tp),DAE.RCONST(r)),DAE.MUL(tp),d_e1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(e1_1,DAE.ADD(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(e1_1,DAE.SUB(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2),_) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2_1),DAE.ADD(tp),
          DAE.BINARY(e1_1,DAE.MUL(tp),e2));

    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2),_) /* (f\'g - fg\' ) / g^2 */
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.BINARY(e1_1,DAE.MUL(tp),e2),DAE.SUB(tp),
          DAE.BINARY(e1,DAE.MUL(tp),e2_1)),DAE.DIV(tp),DAE.BINARY(e2,DAE.MUL(tp),e2));

    case (DAE.UNARY(operator = op,exp = e),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.UNARY(op,e_1);

    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),_)
      equation
        e_str = ExpressionDump.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (DAE.LUNARY(operator = op,exp = e),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.LUNARY(op,e_1);
    /*
      this is wrong. The derivative of c > d is not dc > dd. It is the derivative of
      (c>d) and this is perhaps NAN for c equal d and 0 otherwise

    case (DAE.RELATION(exp1 = e1,operator = rel,exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.RELATION(e1_1,rel,e2_1);
    */

    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),_)
      equation
        e2_1 = differentiateExpTime(e2, inVariables);
        e3_1 = differentiateExpTime(e3, inVariables);
      then
        DAE.IFEXP(e1,e2_1,e3_1);

    case (DAE.CALL(path = a as Absyn.IDENT(name = "der"),expLst = {e},attr=attr),_)
      then
        DAE.CALL(a,{e,DAE.ICONST(2)},attr);

    case (DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = {e,DAE.ICONST(i)},attr=attr),_)
      equation
        i = i + 1;
      then
        DAE.CALL(a,{e,DAE.ICONST(i)},attr);

    case (e as DAE.CALL(path = a,expLst = expl,attr=DAE.CALL_ATTR(ty=tp)),(timevars,_))
      equation
        // if only parameters or discrete no derivative needed
        crefslstls = List.map(expl,Expression.extractCrefsFromExp);
        crefs = List.flatten(crefslstls);
        blst = List.map2(crefs,BackendVariable.existsVar,timevars,true);
        false = Util.boolOrList(blst);
        (e1,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        e1;

    // record constructors
    case (e as DAE.CALL(path=fname,expLst=expl,attr=attr as DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(a)))),(timevars,_))
      equation
        true = Absyn.pathEqual(a,fname);
        expl_1 = List.map1(expl, differentiateExpTime, inVariables);
      then
        DAE.CALL(fname,expl_1,attr);

    case (e as DAE.CALL(path = a,expLst = expl),(_,BackendDAE.SHARED(functionTree=functions)))
      equation
        // get Derivative function
        e1 = differentiateFunctionTime(e,inVariables);
        (e2,_,_) = Inline.inlineExp(e1,(SOME(functions),{DAE.NORM_INLINE()}),DAE.emptyElementSource/*TODO:Can we propagate source?*/);
      then
        e2;

    case (e as DAE.CALL(path = a,expLst = expl),(_,BackendDAE.SHARED(functionTree=functions)))
      equation
        // try to inline
        (e1,_,true) = Inline.forceInlineExp(e,(SOME(functions),{DAE.NORM_INLINE(),DAE.NO_INLINE()}),DAE.emptyElementSource/*TODO:Can we propagate source?*/);
        e1 = Expression.addNoEventToRelations(e1);
        // get Derivative function
      then
        differentiateExpTime(e1,inVariables);

    case (e as DAE.CALL(path = a,expLst = expl),_)
      equation
        e_str = ExpressionDump.printExpStr(e);
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (DAE.ARRAY(ty = tp,scalar = b,array = expl),_)
      equation
        expl_1 = List.map1(expl, differentiateExpTime, inVariables);
      then
        DAE.ARRAY(tp,b,expl_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = tp),exp2 = e2),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(e1_1,DAE.ADD_ARR(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = tp),exp2 = e2),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(e1_1,DAE.SUB_ARR(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = tp),exp2 = e2),_) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARR(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_ARR(tp),e2));

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARRAY_SCALAR(ty = tp),exp2 = e2),_) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_ARRAY_SCALAR(tp),e2));

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_SCALAR_PRODUCT(ty = tp),exp2 = e2),_) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_SCALAR_PRODUCT(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_SCALAR_PRODUCT(tp),e2));

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = tp),exp2 = e2),_) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_MATRIX_PRODUCT(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_MATRIX_PRODUCT(tp),e2));

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARRAY_SCALAR(ty = tp),exp2 = e2),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(e1_1,DAE.ADD_ARRAY_SCALAR(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_SCALAR_ARRAY(ty = tp),exp2 = e2),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
      then
        DAE.BINARY(e1_1,DAE.SUB_SCALAR_ARRAY(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARRAY_SCALAR(ty = tp),exp2 = e2),_) /* (f\'g - fg\' ) / g^2 */
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
        e2_1 = differentiateExpTime(e2, inVariables);
        tp1 = Expression.typeof(e2);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.BINARY(e1_1,DAE.MUL_ARRAY_SCALAR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2_1)),DAE.DIV_ARRAY_SCALAR(tp),DAE.BINARY(e2,DAE.MUL(tp1),e2));

    case ((e as DAE.MATRIX(ty = tp,integer=i,matrix=explstlst)),_)
      equation
        explstlst1 = differentiateMatrixTime(explstlst,inVariables);
      then
        DAE.MATRIX(tp,i,explstlst1);

    case (DAE.TUPLE(PR = expl),_)
      equation
        expl_1 = List.map1(expl, differentiateExpTime, inVariables);
      then
        DAE.TUPLE(expl_1);

    case (DAE.CAST(ty = tp,exp = e),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.CAST(tp,e_1);

    case (DAE.ASUB(exp = e,sub = sub),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        Expression.makeASUB(e_1,sub);

    case (DAE.TSUB(e,i,tp),_)
      equation
        e_1 = differentiateExpTime(e, inVariables);
      then
        DAE.TSUB(e_1,i,tp);

    case (DAE.REDUCTION(reductionInfo = reductionInfo,expr = e1,iterators = iters),_)
      equation
        e1_1 = differentiateExpTime(e1, inVariables);
      then
        DAE.REDUCTION(reductionInfo,e1_1,iters);

    /* We need to expect failures for example for shared array-equations
    case (e,_)
      equation
        print("- Derive.differentiateExpTime on ");
        ExpressionDump.dumpExp(e);
        print("\n failed\n");
      then
        fail(); */
  end matchcontinue;
end differentiateExpTime;

protected function differentiateMatrixTime
"function: differentiateMatrixTime
  author: Frenkel TUD
   Helper function to differentiateExpTime, differentiate matrix expressions."
  input list<list<DAE.Exp>> inTplExpBooleanLstLst;
  input tuple<BackendDAE.Variables,BackendDAE.Shared> inVariables;
  output list<list<DAE.Exp>> outTplExpBooleanLstLst;
algorithm
  outTplExpBooleanLstLst := match (inTplExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> row_1,row;
      list<list<DAE.Exp>> rows_1,rows;

    case ({},_) then ({});

    case ((row :: rows),_)
      equation
        row_1 = List.map1(row, differentiateExpTime, inVariables);
        rows_1 = differentiateMatrixTime(rows, inVariables);
      then
        (row_1 :: rows_1);
  end match;
end differentiateMatrixTime;

protected function differentiateFunctionTimeOutputs"
Author: Frenkel TUD"
  input DAE.Exp inExp;
  input DAE.Exp inDExp;
  input list<DAE.Exp> inExpLst;
  input list<DAE.Exp> inExpLst1;
  input tuple<BackendDAE.Variables,BackendDAE.Shared> inVarsandFuncs;
  output list<DAE.Exp> outExpLst;
  output list<DAE.Exp> outExpLst1;
algorithm
  (outExpLst,outExpLst1) := matchcontinue (inExp,inDExp,inExpLst,inExpLst1,inVarsandFuncs)
    local
      BackendDAE.Variables timevars;
      DAE.FunctionTree functions;
      Absyn.Path a,da;
      Integer derivativeOrder;
      DAE.Type tp,dtp;
      list<DAE.Type> tlst,tlst1,tlst2;
      list<DAE.Exp> dexplst,dexplst1,dexplst_1,dexplst1_1;
      list<Boolean> blst,blst1;
      list<String> typlststring;
      String typstring,dastring;

    // order=1
    case (DAE.CALL(path=a),DAE.CALL(path=da),_,_,(timevars,BackendDAE.SHARED(functionTree=functions)))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=1),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);
        // remove all outputs not subtyp of real
        blst = List.map(tlst,Types.isRealOrSubTypeReal);
        blst1 = listReverse(blst);
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        (tlst1,_) = List.splitOnBoolList(tlst,blst);
        true =  List.isEqualOnTrue(tlst1,tlst2,Types.equivtypes);
        // diff explst
        (dexplst,_) = List.splitOnBoolList(inExpLst,blst);
        (dexplst1,_) = List.splitOnBoolList(inExpLst1,blst1);
        dexplst_1 = List.map1(dexplst,differentiateExpTime,inVarsandFuncs);
        dexplst1_1 = List.map1(dexplst1,differentiateExpTime,inVarsandFuncs);
      then
        (dexplst_1,dexplst1_1);

    case (DAE.CALL(path=a),DAE.CALL(path=da),_,_,(timevars,BackendDAE.SHARED(functionTree=functions)))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=1),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);
        // remove all outputs not subtyp of real
        blst = List.map(tlst,Types.isRealOrSubTypeReal);
        blst1 = listReverse(blst);
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        (tlst1,_) = List.splitOnBoolList(tlst,blst);
        false = List.isEqualOnTrue(tlst1,tlst2,Types.equivtypes);
        // add Warning
        typlststring = List.map(tlst1,Types.unparseType);
        typstring = "\n" +& stringDelimitList(typlststring,";\n");
        dastring = Absyn.pathString(da);
        Error.addMessage(Error.UNEXPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});
      then
        fail();

    // order>1
    case (DAE.CALL(path=a),DAE.CALL(path=da),_,_,(timevars,BackendDAE.SHARED(functionTree=functions)))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=derivativeOrder),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);
        true = (derivativeOrder > 1);
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        true = List.isEqualOnTrue(tlst,tlst2,Types.equivtypes);
        // diff explst
        dexplst_1 = List.map1(inExpLst,differentiateExpTime,inVarsandFuncs);
        dexplst1_1 = List.map1(inExpLst1,differentiateExpTime,inVarsandFuncs);
      then
        (dexplst_1,dexplst1_1);

    case (DAE.CALL(path=a),DAE.CALL(path=da),_,_,(timevars,BackendDAE.SHARED(functionTree=functions)))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=derivativeOrder),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);
        true = (derivativeOrder > 1);
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        false = List.isEqualOnTrue(tlst,tlst2,Types.equivtypes);
        // add Warning
        typlststring = List.map(tlst,Types.unparseType);
        typstring = "\n" +& stringDelimitList(typlststring,";\n");
        dastring = Absyn.pathString(da);
        Error.addMessage(Error.UNEXPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});
      then
        fail();
  end matchcontinue;
end differentiateFunctionTimeOutputs;

protected function getFunctionResultTypes"
Author: Frenkel TUD"
  input DAE.Type inType;
  output list<DAE.Type> outTypLst;
algorithm
  outTypLst := matchcontinue (inType)
     local
       list<DAE.Type> tlst;
       DAE.Type t;
    case (DAE.T_FUNCTION(funcResultType=DAE.T_TUPLE(tupleType=tlst))) then tlst;
    case (DAE.T_FUNCTION(funcResultType=t)) then {t};
    case _ then {inType};
  end matchcontinue;
end getFunctionResultTypes;

protected function differentiateFunctionTime"
Author: Frenkel TUD"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.Shared> inVarsandFuncs;
  output DAE.Exp outExp;
algorithm
  (outExp) := matchcontinue (inExp,inVarsandFuncs)
    local
      list<DAE.Exp> expl,expl1,dexpl;
      BackendDAE.Variables timevars;
      Absyn.Path a,da;
      Boolean b,c,isImpure;
      DAE.InlineType dinl;
      DAE.Type ty;
      DAE.FunctionTree functions;
      DAE.FunctionDefinition mapper;
      DAE.Type tp,dtp;
      list<Boolean> blst;
      list<DAE.Type> tlst;
      list<String> typlststring;
      String typstring,dastring;
      DAE.TailCall tc;

    case (DAE.CALL(path=a,expLst=expl,attr=DAE.CALL_ATTR(tuple_=b,builtin=c,isImpure=isImpure,ty=ty,tailCall=tc)),(timevars,BackendDAE.SHARED(functionTree=functions)))
      equation
        // get function mapper
        (mapper,tp) = getFunctionMapper(a,functions);
        (da,blst) = differentiateFunctionTime1(a,mapper,tp,expl,inVarsandFuncs);
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected inputs
        (true,_) = checkDerivativeFunctionInputs(blst,tp,dtp);
        (expl1,_) = List.splitOnBoolList(expl,blst);
        dexpl = List.map1(expl1,differentiateExpTime,inVarsandFuncs);
        expl1 = listAppend(expl,dexpl);
      then
        DAE.CALL(da,expl1,DAE.CALL_ATTR(ty,b,c,isImpure,dinl,tc));

    case (DAE.CALL(path=a,expLst=expl),(timevars,BackendDAE.SHARED(functionTree=functions)))
      equation
        // get function mapper
        (mapper,tp) = getFunctionMapper(a,functions);
        (da,blst) = differentiateFunctionTime1(a,mapper,tp,expl,inVarsandFuncs);
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected inputs
        (false,tlst) = checkDerivativeFunctionInputs(blst,tp,dtp);
        // add Warning
        typlststring = List.map(tlst,Types.unparseType);
        typstring = "\n" +& stringDelimitList(typlststring,";\n");
        dastring = Absyn.pathString(da);
        Error.addMessage(Error.UNEXPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});
      then
        fail();
  end matchcontinue;
end differentiateFunctionTime;

protected function checkDerivativeFunctionInputs"
Author: Frenkel TUD"
  input list<Boolean> blst;
  input DAE.Type tp;
  input DAE.Type dtp;
  output Boolean outBoolean;
  output list<DAE.Type> outExpectedTypeLst;
algorithm
  (outBoolean,outExpectedTypeLst) := matchcontinue(blst,tp,dtp)
    local
      list<DAE.FuncArg> falst,falst1,falst2,dfalst;
      list<DAE.Type> tlst,dtlst;
      Boolean ret;
      case (_,DAE.T_FUNCTION(funcArg=falst),DAE.T_FUNCTION(funcArg=dfalst))
      equation
        // generate expected function inputs
        (falst1,_) = List.splitOnBoolList(falst,blst);
        falst2 = listAppend(falst,falst1);
        // compare with derivative function inputs
        tlst = List.map(falst2,Util.tuple42);
        dtlst = List.map(dfalst,Util.tuple42);
        ret = List.isEqualOnTrue(tlst,dtlst,Types.equivtypes);
      then
        (ret,tlst);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "-Derive.checkDerivativeFunctionInputs failed\n");
      then
        fail();
    end matchcontinue;
end checkDerivativeFunctionInputs;

protected function differentiateFunctionTime1"
Author: Frenkel TUD"
  input Absyn.Path inFuncName;
  input DAE.FunctionDefinition inMapper;
  input DAE.Type inTp;
  input list<DAE.Exp> expl;
  input tuple<BackendDAE.Variables,BackendDAE.Shared> inVarsandFuncs;
  output Absyn.Path outFuncName;
  output list<Boolean> blst;
algorithm
  (outFuncName,blst) := matchcontinue (inFuncName,inMapper,inTp,expl,inVarsandFuncs)
    local
      BackendDAE.Variables timevars;
      DAE.FunctionTree functions;
      Absyn.Path default,fname,da,inDFuncName;
      list<tuple<Integer,DAE.derivativeCond>> cr;
      Integer derivativeOrder;
      list<DAE.FuncArg> funcArg;
      list<DAE.Type> tplst;
      list<Boolean> bl,bl1,bl2,bl3;
      list<Absyn.Path> lowerOrderDerivatives;
      DAE.FunctionDefinition mapper;
      DAE.Type tp;

    // check conditions, order=1
    case (_,DAE.FUNCTION_DER_MAPPER(derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr),DAE.T_FUNCTION(funcArg=funcArg),_,_)
      equation
         true = intEq(1,derivativeOrder);
         tplst = List.map(funcArg,Util.tuple42);
         bl = List.map(tplst,Types.isRealOrSubTypeReal);
         bl1 = checkDerFunctionConds(bl,cr,expl,inVarsandFuncs);
      then
        (inDFuncName,bl1);
    // check conditions, order>1
    case (_,DAE.FUNCTION_DER_MAPPER(derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr),tp,_,(timevars,BackendDAE.SHARED(functionTree=functions)))
      equation
         failure(true = intEq(1,derivativeOrder));
         // get n-1 func name
         fname = getlowerOrderDerivative(inFuncName,functions);
         // get mapper
         (mapper,tp) = getFunctionMapper(fname,functions);
         // get bool list
         (da,blst) = differentiateFunctionTime1(fname,mapper,tp,expl,inVarsandFuncs);
         // count true
         (bl1,_) = List.split1OnTrue(blst,Util.isEqual,true);
         bl2 = List.fill(false,listLength(blst));
         bl = listAppend(bl2,bl1);
         bl3 = checkDerFunctionConds(bl,cr,expl,inVarsandFuncs);
      then
        (inDFuncName,bl3);
    // conditions failed use default
    case (_,DAE.FUNCTION_DER_MAPPER(derivedFunction=fname,derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr,defaultDerivative=SOME(default),lowerOrderDerivatives=lowerOrderDerivatives),tp,_,_)
      equation
          (da,bl) = differentiateFunctionTime1(inFuncName,DAE.FUNCTION_DER_MAPPER(fname,default,derivativeOrder,{},SOME(default),lowerOrderDerivatives),tp,expl,inVarsandFuncs);
      then
        (da,bl);
  end matchcontinue;
end differentiateFunctionTime1;

protected function checkDerFunctionConds "
Author: Frenkel TUD"
  input list<Boolean> inblst;
  input list<tuple<Integer,DAE.derivativeCond>> icrlst;
  input list<DAE.Exp> expl;
  input tuple<BackendDAE.Variables,BackendDAE.Shared> inVarsandFuncs;
  output list<Boolean> outblst;
algorithm
  outblst := matchcontinue(inblst,icrlst,expl,inVarsandFuncs)
    local
      Integer i;
      DAE.Exp e,de;
      list<Boolean> bl,bl1;
      array<Boolean> ba;
      Absyn.Path p1,p2;
      list<tuple<Integer,DAE.derivativeCond>> crlst;

    // no conditions
    case (_,{},_,_) then inblst;

    // zeroDerivative
    case(_,(i,DAE.ZERO_DERIVATIVE())::crlst,_,_)
      equation
        // get expression
        e = listGet(expl,i);
        // diverentiate exp
        de = differentiateExpTime(e,inVarsandFuncs);
        // is diverentiated exp zero
        true = Expression.isZero(de);
        // remove input from list
        ba = listArray(inblst);
        ba = arrayUpdate(ba,i,false);
        bl1 = arrayList(ba);
        bl = checkDerFunctionConds(bl1,crlst,expl,inVarsandFuncs);
      then
        bl;

    // noDerivative
    case(_,(i,DAE.NO_DERIVATIVE(binding=DAE.CALL(path=p1)))::crlst,_,_)
      equation
        // get expression
        DAE.CALL(path=p2) = listGet(expl,i);
        true = Absyn.pathEqual(p1, p2);
        // path equal
        // remove input from list
        ba = listArray(inblst);
        ba = arrayUpdate(ba,i,false);
        bl1 = arrayList(ba);
        bl = checkDerFunctionConds(bl1,crlst,expl,inVarsandFuncs);
      then
        bl;

    // noDerivative
    case(_,(i,DAE.NO_DERIVATIVE(binding=DAE.ICONST(_)))::crlst,_,_)
      equation
        // remove input from list
        ba = listArray(inblst);
        ba = arrayUpdate(ba,i,false);
        bl1 = arrayList(ba);
        bl = checkDerFunctionConds(bl1,crlst,expl,inVarsandFuncs);
      then
        bl;

    // failure
    case (_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "-Derive.checkDerFunctionConds failed\n");
      then
        fail();
  end matchcontinue;
end checkDerFunctionConds;

public function getlowerOrderDerivative"
Author: Frenkel TUD"
  input Absyn.Path fname;
  input DAE.FunctionTree functions;
  output Absyn.Path outFName;
algorithm
  outFName := match(fname,functions)
    local
      list<DAE.FunctionDefinition> flst;
      list<Absyn.Path> lowerOrderDerivatives;
      Absyn.Path name;
    case(_,_)
      equation
          SOME(DAE.FUNCTION(functions=flst)) = DAEUtil.avlTreeGet(functions,fname);
          DAE.FUNCTION_DER_MAPPER(lowerOrderDerivatives=lowerOrderDerivatives) = getFunctionMapper1(flst);
          name = List.last(lowerOrderDerivatives);
      then name;
  end match;
end getlowerOrderDerivative;

public function getFunctionMapper"
Author: Frenkel TUD"
  input Absyn.Path fname;
  input DAE.FunctionTree functions;
  output DAE.FunctionDefinition mapper;
  output DAE.Type tp;
algorithm
  (mapper,tp) := matchcontinue(fname,functions)
    local
      list<DAE.FunctionDefinition> flst;
      DAE.Type t;
      DAE.FunctionDefinition m;
      String s;
    case(_,_)
      equation
        SOME(DAE.FUNCTION(functions=flst,type_=t)) = DAEUtil.avlTreeGet(functions,fname);
        m = getFunctionMapper1(flst);
      then (m,t);
    case (_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s = Absyn.pathString(fname);
        s = stringAppend("-Derive.getFunctionMapper failed for function ",s);
        Debug.traceln(s);
      then
        fail();
  end matchcontinue;
end getFunctionMapper;

public function getFunctionMapper1"
Author: Frenkel TUD"
  input list<DAE.FunctionDefinition> inFuncDefs;
  output DAE.FunctionDefinition mapper;
algorithm
  mapper := matchcontinue(inFuncDefs)
    local
      DAE.FunctionDefinition m;
      Absyn.Path p1;
      list<DAE.FunctionDefinition> funcDefs;

    case((m as DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1))::funcDefs) then m;
    case(_::funcDefs)
    equation
      m = getFunctionMapper1(funcDefs);
    then m;
    case (_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "-Derive.getFunctionMapper1 failed\n");
      then
        fail();
  end matchcontinue;
end getFunctionMapper1;

public function differentiateExpCont "calls differentiateExp(e,cr,false)"
  input DAE.Exp inExp;
  input DAE.ComponentRef inComponentRef;
  input Option<DAE.FunctionTree> inFuncs;
  output DAE.Exp outExp;
algorithm
  outExp := differentiateExp(inExp,inComponentRef,false,inFuncs);
end differentiateExpCont;

public function differentiateExp "function: differentiateExp
  This function differentiates expressions with respect
  to a given variable,given as second argument.
  For example: differentiateExp(2xy+2x+y,x) => 2x+2"
  input DAE.Exp inExp;
  input DAE.ComponentRef inComponentRef;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input Option<DAE.FunctionTree> inFuncs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inComponentRef,differentiateIfExp,inFuncs)
    local
      Real rval;
      DAE.ComponentRef cr;
      DAE.Exp e,e1_1,e2_1,e1,e2,const_one,d_e1,d_e2,exp,e_1,cond,zero,call;
      DAE.Type tp;
      Absyn.Path a,path;
      Boolean b;
      DAE.Operator op;
      String e_str,s,s2,str,name;
      list<DAE.Exp> expl_1,expl,sub;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters;
      DAE.CallAttributes attr;

    case (DAE.ICONST(integer = _),_,_,_) then DAE.RCONST(0.0);

    case (DAE.RCONST(real = _),_,_,_) then DAE.RCONST(0.0);

    case (DAE.CREF(componentRef = cr),_,_,_)
      equation
        true = ComponentReference.crefEqual(cr, inComponentRef) "D(x)/dx => 1" ;
        rval = intReal(1) "Since bug in MetaModelica Compiler (MMC) makes 1.0 into 0.0" ;
      then
        DAE.RCONST(rval);

    case ((e as DAE.CREF(componentRef = cr,ty=tp)),_,_,_)
      equation
        false = ComponentReference.crefEqual(cr, inComponentRef) "D(c)/dx => 0" ;
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        zero;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(e1_1,DAE.ADD(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(e1_1,DAE.ADD_ARR(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(e1_1,DAE.SUB(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(e1_1,DAE.SUB_ARR(tp),e2_1);

    case (DAE.BINARY(exp1 = (e1 as DAE.CREF(componentRef = cr)),operator = DAE.POW(ty = tp),exp2 = e2),_,_,_) /* ax^(a-1) */
      equation
        true = ComponentReference.crefEqual(cr, inComponentRef) "x^a => ax^(a-1)" ;
        false = Expression.expContains(e2, Expression.makeCrefExp(inComponentRef,tp));
        const_one = differentiateExp(Expression.makeCrefExp(inComponentRef,tp), inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(e2,DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),_,_,_) /* ax^(a-1) */
      equation
        d_e1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs) "e^x => xder(e)e^x-1" ;
        false = Expression.expContains(e2, Expression.makeCrefExp(inComponentRef,tp));
        const_one = differentiateExp(Expression.makeCrefExp(inComponentRef,tp), inComponentRef, differentiateIfExp,inFuncs);
        exp = DAE.BINARY(
          DAE.BINARY(d_e1,DAE.MUL(tp),DAE.BINARY(e2,DAE.SUB(tp),DAE.RCONST(1.0))),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));
      then
        exp;

      case (e as DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),_,_,_) /* a^x => a^x * log(A) */
      equation
        false = Expression.expContains(e1, Expression.makeCrefExp(inComponentRef,tp));
        true  = Expression.expContains(e2,Expression.makeCrefExp(inComponentRef,tp));
        d_e2 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
        call = Expression.makeBuiltinCall("log",{e1},tp);
        exp = DAE.BINARY(d_e2,DAE.MUL(tp),DAE.BINARY(e,DAE.MUL(tp),call));
      then
        exp;

    // ax^(a-1)
    case (DAE.BINARY(exp1 = (e1 as DAE.CALL(path = (a as Absyn.IDENT(name = "der")),
          expLst = {(exp as DAE.CREF(componentRef = cr))},attr=attr)),
          operator = DAE.POW(ty = tp),exp2 = e2),_,_,_)
      equation
        true = ComponentReference.crefEqual(cr, inComponentRef) "der(e)^x => xder(e,2)der(e)^(x-1)" ;
        false = Expression.expContains(e2, Expression.makeCrefExp(inComponentRef,tp));
        const_one = differentiateExp(Expression.makeCrefExp(inComponentRef,tp), inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.CALL(a,{exp,DAE.ICONST(2)},attr),DAE.MUL(tp),e2),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));

    // f\'g + fg\'
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2_1),DAE.ADD(tp),
          DAE.BINARY(e1_1,DAE.MUL(tp),e2));

    /* f\'g + fg\' */
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_SCALAR_PRODUCT(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_SCALAR_PRODUCT(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_SCALAR_PRODUCT(tp),e2));

    /* f\'g + fg\' */
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_MATRIX_PRODUCT(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_MATRIX_PRODUCT(tp),e2));

    // (f'g - fg' ) / g^2
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(
          DAE.BINARY(
            DAE.BINARY(e1_1,DAE.MUL(tp),e2),
            DAE.SUB(tp),
            DAE.BINARY(e1,DAE.MUL(tp),e2_1)),
          DAE.DIV(tp),
          DAE.BINARY(e2,DAE.MUL(tp),e2));

    case (DAE.UNARY(operator = op,exp = e),_,_,_)
      equation
        e_1 = differentiateExp(e, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.UNARY(op,e_1);

    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),_,_,_)
      equation
        e_str = ExpressionDump.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (DAE.LUNARY(operator = op,exp = e),_,_,_)
      equation
        e_1 = differentiateExp(e, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.LUNARY(op,e_1);

    case (DAE.CALL(path=Absyn.IDENT(name),attr=DAE.CALL_ATTR(builtin=true),expLst={exp}),_,_,_)
      equation
        true = Expression.expContains(exp,Expression.crefExp(inComponentRef));
      then differentiateCallExp1Arg(name,exp,inComponentRef,differentiateIfExp,inFuncs);

    case (DAE.CALL(path = Absyn.IDENT("der"), expLst = {DAE.CREF(componentRef = cr)}), _, _,_)
      equation
        cr = ComponentReference.crefPrefixDer(cr);
        true = ComponentReference.crefEqual(cr, inComponentRef);
        rval = intReal(1);
      then
        DAE.RCONST(rval);

    // der(x)
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst =
          {(exp as DAE.CREF(componentRef = cr))},attr=attr),_,_,_)
      equation
        true = ComponentReference.crefEqual(cr, inComponentRef);
      then
        DAE.CALL(a,{exp,DAE.ICONST(2)},attr);

    // der(arctan2(y,0)) = der(sign(y)*pi/2) = 0
    case (DAE.CALL(path = Absyn.IDENT("atan2"),expLst = {e,e1}),_,_,_)
      equation
        true = Expression.expContains(e, Expression.crefExp(inComponentRef));
        true = Expression.isZero(e1);
        (exp,_) = Expression.makeZeroExpression({});
      then exp;

    // der(arctan2(y,x)) = der(y/x)/1+(y/x)^2
    case (DAE.CALL(path = Absyn.IDENT("atan2"),expLst = {e,e1}),_,_,_)
      equation
        true = Expression.expContains(e, Expression.crefExp(inComponentRef));
        false = Expression.isZero(e1);
        exp = Expression.makeDiv(e,e1);
        e_1 = differentiateExp(exp, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.T_REAL_DEFAULT),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e)));

    // der(record constructur(..)) =  record constructur(der(.),der(.))
    case (DAE.CALL(path=a,expLst=expl,attr=attr as DAE.CALL_ATTR(ty= DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path)))),_,_,_)
      equation
        true = Absyn.pathEqual(a, path);
        expl_1 = List.map3(expl, differentiateExp, inComponentRef, differentiateIfExp,inFuncs);
      then DAE.CALL(a,expl_1,attr);

    /*
      this is wrong. The derivative of c > d is not dc > dd. It is the derivative of
      (c>d) and this is perhaps NAN for c equal d and 0 otherwise

    case (DAE.RELATION(exp1 = e1,operator = rel,exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.RELATION(e1_1,rel,e2_1);
    */

    case (DAE.ARRAY(ty = tp,scalar = b,array = expl),_,_,_)
      equation
        expl_1 = List.map3(expl, differentiateExp, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.ARRAY(tp,b,expl_1);

    case (DAE.TUPLE(PR = expl),_,_,_)
      equation
        expl_1 = List.map3(expl, differentiateExp, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.TUPLE(expl_1);

    case (DAE.CAST(ty = tp,exp = e),_,_,_)
      equation
        e_1 = differentiateExp(e, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.CAST(tp,e_1);

    case (DAE.ASUB(exp = e,sub = sub),_,_,_)
      equation
        e_1 = differentiateExp(e, inComponentRef, differentiateIfExp,inFuncs);
      then
        Expression.makeASUB(e_1,sub);

      // TODO: Check if we are differentiating a local iterator?
    case (DAE.REDUCTION(reductionInfo=reductionInfo,expr = e1,iterators = riters),_,_,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.REDUCTION(reductionInfo,e1_1,riters);

    // derivative of arbitrary function, not dependent of variable, i.e. constant
    /* Caught by rule below...
    case (DAE.CALL(fname,expl,b,c,tp,inl),tv,differentiateIfExp)
      equation
        bLst = List.map1(expl,Expression.expContains, Expression.crefExp(tv));
        false = List.reduce(bLst,boolOr);
        (e1,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        e1;*/
    /* semiLinear(x,a,b) -> if (x>=0) then a*x else b*x -> if (x>=0) then da*x+a*dx else db*x+b*dx
    case (DAE.CALL(path = Absyn.IDENT("semiLinear"), expLst = {cond,e1,e2}), tv, differentiateIfExp as true,_)
      equation
        exp = differentiateExp(cond, tv, differentiateIfExp,inFuncs);
        e1_1 = differentiateExp(e1, tv, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp,inFuncs);
        e1_1 = Expression.expAdd(Expression.expMul(e1_1,cond),Expression.expMul(e1,exp));
        e2_1 = Expression.expAdd(Expression.expMul(e2_1,cond),Expression.expMul(e2,exp));
      then
        DAE.IFEXP(cond,e1_1,e2_1);
    */
    case (e as DAE.CALL(path=_),_,_,_)
      equation
        // try to inline
        (e1,_,true) = Inline.forceInlineExp(e,(inFuncs,{DAE.NORM_INLINE(),DAE.NO_INLINE()}),DAE.emptyElementSource/*TODO:Can we propagate source?*/);
        e1 = Expression.addNoEventToRelations(e1);
      then
        differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);

    case (_,_,_,_)
      equation
        false = Expression.expContains(inExp, Expression.crefExp(inComponentRef))
        "If the expression does not contain the variable,
         the derivative is zero. For efficiency reasons this rule
         is last. Otherwise expressions is always traversed twice
         when differentiating.";
        tp = Expression.typeof(inExp);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        zero;

    // Differentiate if-expressions if last argument true
    case (DAE.IFEXP(cond,e1,e2),_,true,_)
      equation
        e1_1 = differentiateExp(e1, inComponentRef, differentiateIfExp,inFuncs);
        e2_1 = differentiateExp(e2, inComponentRef, differentiateIfExp,inFuncs);
      then
        DAE.IFEXP(cond,e1_1,e2_1);

    case (_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s = ExpressionDump.printExpStr(inExp);
        s2 = ComponentReference.printComponentRefStr(inComponentRef);
        str = stringAppendList({"- Derive.differentiateExp ",s," w.r.t: ",s2," failed\n"});
        //print(str);
        Debug.fprint(Flags.FAILTRACE, str);
      then
        fail();
  end matchcontinue;
end differentiateExp;

protected function differentiateCallExp1Arg "function: differentiateCallExp1Arg
  This function differentiates builtin call expressions with 1 argument
  with respect to a given variable,given as second argument.
  The argument must contain the variable to differentiate w.r.t."
  input String name;
  input DAE.Exp exp;
  input DAE.ComponentRef tv;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input Option<DAE.FunctionTree> inFuncs;
  output DAE.Exp outExp;
algorithm
  outExp := match (name,exp,tv,differentiateIfExp,inFuncs)
    local
      DAE.Exp exp_1,exp_2;
    // der(tanh(x)) => der(x) / cosh(x)^2
    case ("tanh",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("cosh",{exp},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),
             DAE.BINARY(exp_2,DAE.POW(DAE.T_REAL_DEFAULT),DAE.RCONST(2.0)));

    // der(cosh(x)) => der(x)sinh(x)
    case ("cosh",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("sinh",{exp},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(exp_1,DAE.MUL(DAE.T_REAL_DEFAULT),exp_2);

    // der(sinh(x)) => der(x)sinh(x)
    case ("sinh",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("cosh",{exp},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(exp_1,DAE.MUL(DAE.T_REAL_DEFAULT),exp_2);

    // der(sin(x)) => der(x)cos(x)
    case ("sin",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("cos",{exp},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(exp_2,DAE.MUL(DAE.T_REAL_DEFAULT),exp_1);

    // der(cos(x)) => -der(x)sin(x)
    case ("cos",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("sin",{exp},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),exp_2),DAE.MUL(DAE.T_REAL_DEFAULT),exp_1);

    // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case ("acos",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("sqrt",{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.BINARY(exp,DAE.MUL(DAE.T_REAL_DEFAULT),exp))},DAE.T_REAL_DEFAULT);
      then DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),exp_2));

    // der(arcsin(x)) = der(x)/sqrt(1-x^2)
    case ("asin",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("sqrt",{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.BINARY(exp,DAE.MUL(DAE.T_REAL_DEFAULT),exp))},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),exp_2);

    // der(arctan(x)) = der(x)/(1+x^2)
    case ("atan",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
      then DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.T_REAL_DEFAULT),DAE.BINARY(exp,DAE.MUL(DAE.T_REAL_DEFAULT),exp)));

    // der(exp(x)) = der(x)exp(x)
    case ("exp",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("exp",{exp},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(exp_2,DAE.MUL(DAE.T_REAL_DEFAULT),exp_1);

    // der(log(x)) = der(x) / x
    case ("log",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
      then
        DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),exp);

    case ("log10",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("log",{DAE.RCONST(10.0)},DAE.T_REAL_DEFAULT);
      then
        DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(exp,DAE.MUL(DAE.T_REAL_DEFAULT),exp_2));

    case ("sqrt",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("sqrt",{exp},DAE.T_REAL_DEFAULT);
      then
        DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.T_REAL_DEFAULT),
          exp_2));

    // der(tan(x)) => der(x) / cos(x)^2
    case ("tan",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("cos",{exp},DAE.T_REAL_DEFAULT);
      then
        DAE.BINARY(exp_1,DAE.DIV(DAE.T_REAL_DEFAULT),
          DAE.BINARY(exp_2,DAE.POW(DAE.T_REAL_DEFAULT),DAE.RCONST(2.0)));

    // abs(x)
    /* Why do we have two rules for abs(x)?
    case (DAE.CALL(path=fname, expLst={exp},tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isAbs(fname);
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.IFEXP(DAE.RELATION(exp_1,DAE.GREATER(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE()), exp_1, DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),exp_1));
    */

    // der(abs(x)) = sign(x)der(x)
    case ("abs",_,_,_,_)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp,inFuncs);
        exp_2 = Expression.makeBuiltinCall("sign",{exp_1},DAE.T_INTEGER_DEFAULT);
      then DAE.BINARY(exp_2,DAE.MUL(DAE.T_REAL_DEFAULT),exp_1);
  end match;
end differentiateCallExp1Arg;

end Derive;

