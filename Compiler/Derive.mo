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

package Derive
" file:	 Derive.mo
  package:      Derive
  description: Differentiation of equations from DAELow

  RCS: $Id$

  This module is responsible for symbolic differentiation of equations and
  expressions. Is is currently (2004-09-28) only used by the solve function in
  the exp module for solving equations.

  The symbolic differentiation is used in the Newton-Raphson method and in
  index reduction."

public import Absyn;
public import DAE;
public import DAELow;
public import RTOpts;
public import DAEUtil;

protected import Exp;
protected import Util;
protected import Error;
protected import Debug;
protected import SimCodegen;

public function differentiateEquationTime "function: differentiateEquationTime
  Differentiates an equation with respect to the time variable."
  input DAELow.Equation inEquation;
  input DAELow.Variables inVariables;
  input DAE.FunctionTree inFunctions;
  output DAELow.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation,inVariables,inFunctions)
    local
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e1,e2;
      DAELow.Variables timevars;
      DAELow.Equation dae_equation;
      DAE.ElementSource source "the origin of the element";

    case (DAELow.EQUATION(exp = e1,scalar = e2,source=source),timevars,inFunctions) /* time varying variables */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,inFunctions));
        e2_1 = differentiateExpTime(e2, (timevars,inFunctions));
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
      then
        DAELow.EQUATION(e1_2,e2_2,source);

    case (DAELow.ALGORITHM(index = _),_,_)
      equation
        print("-differentiate_equation_time on algorithm not impl yet.\n");
      then
        fail();
    case (dae_equation,_,_)
      equation
        print("-differentiate_equation_time failed\n");
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
  input tuple<DAELow.Variables,DAE.FunctionTree> inVarsandFuncs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inVarsandFuncs)
    local
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      String cr_str,cr_str_1,e_str,str,s1;
      DAE.Exp e,e_1,e1_1,e2_1,e1,e2,e3_1,e3,d_e1,exp,e0;
      DAELow.Variables timevars;
      DAE.Operator op,rel;
      list<DAE.Exp> expl_1,expl,sub;
      Absyn.Path a;
      Boolean b,c;
      DAE.InlineType inl;
      Integer i;
      Absyn.Path fname;
      DAE.ExpType ty;
      DAE.FunctionTree functions;

    case (DAE.ICONST(integer = _),_) then DAE.RCONST(0.0);
    case (DAE.RCONST(real = _),_) then DAE.RCONST(0.0);
    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident = "time",subscriptLst = {}),ty = tp),_) then DAE.RCONST(1.0);
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,functions)) /* special rule for DUMMY_STATES, they become DUMMY_DER */
      equation
        ({DAELow.VAR(varKind=DAELow.DUMMY_STATE())},_) = DAELow.getVar(cr, timevars);
        cr_str = Exp.printComponentRefStr(cr);
        ty = Exp.crefType(cr);
        cr_str_1 = SimCodegen.changeNameForDerivative(cr_str);
      then
        DAE.CREF(DAE.CREF_IDENT(cr_str_1,ty,{}),DAE.ET_REAL());

    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,functions))
      equation
        (_,_) = DAELow.getVar(cr, timevars);
      then
        DAE.CALL(Absyn.IDENT("der"),{e},false,true,DAE.ET_REAL(),DAE.NO_INLINE());

    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        isSin(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(sin(x)) = der(x)cos(x)" ;
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cos"),{e},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        isCos(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(cos(x)) = -der(x)sin(x)" ;
      then
        DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(e_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{e},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

        // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        isACos(fname);
        e_1 = differentiateExpTime(e, (timevars,functions))  ;
      then
        DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

        // der(arcsin(x)) = der(x)/sqrt(1-x^2)
      case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        isASin(fname);
        e_1 = differentiateExpTime(e, (timevars,functions))  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

        // der(arctan(x)) = der(x)/1+x^2
      case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        isATan(fname);
        e_1 = differentiateExpTime(e, (timevars,functions))  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e)));

    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        isExp(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(exp(x)) = der(x)exp(x)" ;
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(fname,{e},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

        case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        isLog(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(log(x)) = der(x)/x";
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),e);

    case (DAE.CALL(path = fname,expLst = {e},tuple_ = false,builtin = true),(timevars,functions))
      equation
        isLog(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(log(x)) = der(x)/x" ;
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),e);

    case (e0 as DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.RCONST(_))),(timevars,functions)) /* ax^(a-1) */
      equation
        d_e1 = differentiateExpTime(e1, (timevars,functions)) "e^x => xder(e)e^x-1" ;
        //false = Exp.expContains(e2, DAE.CREF(tv,tp));
        //const_one = differentiateExp(DAE.CREF(tv,tp), tv);
        exp = DAE.BINARY(
          DAE.BINARY(d_e1,DAE.MUL(tp),e2),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),DAE.RCONST(1.0))));
      then
        exp;

    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,functions)) /* list_member(cr,timevars) => false */  then DAE.RCONST(0.0);
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.ADD(tp),e2_1);
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.SUB(tp),e2_1);
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2),(timevars,functions)) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2_1),DAE.ADD(tp),
          DAE.BINARY(e1_1,DAE.MUL(tp),e2));
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2),(timevars,functions)) /* (f\'g - fg\' ) / g^2 */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(
          DAE.BINARY(DAE.BINARY(e1_1,DAE.MUL(tp),e2),DAE.SUB(tp),
          DAE.BINARY(e1,DAE.MUL(tp),e2_1)),DAE.DIV(tp),DAE.BINARY(e2,DAE.MUL(tp),e2));
    case (DAE.UNARY(operator = op,exp = e),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        DAE.UNARY(op,e_1);
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),(timevars,functions))
      equation
        e_str = Exp.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();
    case (DAE.LUNARY(operator = op,exp = e),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        DAE.LUNARY(op,e_1);
    case (DAE.RELATION(exp1 = e1,operator = rel,exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.RELATION(e1_1,rel,e2_1);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),(timevars,functions))
      equation
        e2_1 = differentiateExpTime(e2, (timevars,functions));
        e3_1 = differentiateExpTime(e3, (timevars,functions));
      then
        DAE.IFEXP(e1,e2_1,e3_1);
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = expl,tuple_ = b,builtin = c,ty=tp,inlineType=inl),(timevars,functions))
      local DAE.ExpType tp;
      equation
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.CALL(a,expl_1,b,c,tp,inl);
    case (DAE.CALL(path = a,expLst = expl,tuple_ = b,builtin = c),(timevars,functions))
      equation
        // get Derivative function
        // 
        str = Absyn.pathString(a);
        s1 = stringAppend("differentiation of function ", str);
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {s1,"no suggestion"});
      then
        fail();        
    case (e as DAE.CALL(path = a,expLst = expl,tuple_ = b,builtin = c),(timevars,functions))
      equation
        e_str = Exp.printExpStr(e);
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();
    case (DAE.ARRAY(ty = tp,scalar = b,array = expl),(timevars,functions))
      equation
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.ARRAY(tp,b,expl_1);
    case ((e as DAE.MATRIX(ty = _)),_)
      equation
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,
          {"differentiation of matrix expressions",
          "use nested vectors instead"});
      then
        e;
    case (DAE.TUPLE(PR = expl),(timevars,functions))
      equation
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.TUPLE(expl_1);
    case (DAE.CAST(ty = tp,exp = e),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        DAE.CAST(tp,e_1);
    case (DAE.ASUB(exp = e,sub = sub),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        DAE.ASUB(e,sub);
    case (DAE.REDUCTION(path = a,expr = e1,ident = b,range = e2),(timevars,functions))
      local String b;
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.REDUCTION(a,e1_1,b,e2_1);
    case (e,(timevars,functions))
      equation
        str = Exp.printExpStr(e);
        print("-differentiate_exp_time on ");
        print(str);
        print(" failed\n");
      then
        fail();
  end matchcontinue;
end differentiateExpTime;

public function differentiateExpCont "calls differentiateExp(e,cr,false)"
  input DAE.Exp inExp;
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp := differentiateExp(inExp,inComponentRef,false);
end differentiateExpCont;

public function differentiateExp "function: differenatiate_exp

  This function differentiates expressions with respect to a given variable,
  given as second argument.
  For example.
  differentiateExp(\'2xy+2x+y\',x) => 2x+2
"
  input DAE.Exp inExp;
  input DAE.ComponentRef inComponentRef;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inComponentRef,differentiateIfExp)
    local
      Real rval;
      DAE.ComponentRef cr,crx,tv;
      DAE.Exp e,e1_1,e2_1,e1,e2,const_one,d_e1,d_e2,exp,e_1,exp_1,e3_1,e3,cond;
      DAE.ExpType tp;
      Absyn.Path a,fname;
      Boolean b,c;
      DAE.InlineType inl;
      DAE.Operator op,rel;
      String e_str,s,s2,str;
      list<DAE.Exp> expl_1,expl,sub;
      Integer i;
    case (DAE.ICONST(integer = _),_,_) then DAE.RCONST(0.0);

    case (DAE.RCONST(real = _),_,_) then DAE.RCONST(0.0);

    case (DAE.CREF(componentRef = cr),crx,_)
      equation
        true = Exp.crefEqual(cr, crx) "D(x)/dx => 1" ;
        rval = intReal(1) "Since bug in MetaModelica Compiler (MMC) makes 1.0 into 0.0" ;
      then
        DAE.RCONST(rval);

    case ((e as DAE.CREF(componentRef = cr)),crx,_)
      equation
        false = Exp.crefEqual(cr, crx) "D(c)/dx => 0" ;
      then
        DAE.RCONST(0.0);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        DAE.BINARY(e1_1,DAE.ADD(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        DAE.BINARY(e1_1,DAE.SUB(tp),e2_1);

    case (DAE.BINARY(exp1 = (e1 as DAE.CREF(componentRef = cr)),operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* ax^(a-1) */
      equation
        true = Exp.crefEqual(cr, tv) "x^a => ax^(a-1)" ;
        false = Exp.expContains(e2, DAE.CREF(tv,tp));
        const_one = differentiateExp(DAE.CREF(tv,tp), tv,differentiateIfExp);
      then
        DAE.BINARY(e2,DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* ax^(a-1) */
      equation
        d_e1 = differentiateExp(e1, tv,differentiateIfExp) "e^x => xder(e)e^x-1" ;
        false = Exp.expContains(e2, DAE.CREF(tv,tp));
        const_one = differentiateExp(DAE.CREF(tv,tp), tv,differentiateIfExp);
        exp = DAE.BINARY(
          DAE.BINARY(d_e1,DAE.MUL(tp),DAE.BINARY(e2,DAE.SUB(tp),DAE.RCONST(1.0))),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));
      then
        exp;

      case (e as DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* a^x => a^x * log(A) */
      equation
        false = Exp.expContains(e1, DAE.CREF(tv,tp));
        true  = Exp.expContains(e2,DAE.CREF(tv,tp));
        d_e2 = differentiateExp(e2, tv,differentiateIfExp);
        exp = DAE.BINARY(d_e2,DAE.MUL(tp),
	        DAE.BINARY(e,DAE.MUL(tp),DAE.CALL(Absyn.IDENT("log"),{e1},false,true,tp,DAE.NO_INLINE()))
          );
      then
        exp;

        /* ax^(a-1) */
    case (DAE.BINARY(exp1 = (e1 as DAE.CALL(path = (a as Absyn.IDENT(name = "der")),
          expLst = {(exp as DAE.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=ctp,inlineType=inl)),
          operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp)
      local DAE.ExpType ctp;
      equation
        true = Exp.crefEqual(cr, tv) "der(e)^x => xder(e,2)der(e)^(x-1)" ;
        false = Exp.expContains(e2, DAE.CREF(tv,tp));
        const_one = differentiateExp(DAE.CREF(tv,tp), tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.CALL(a,{exp,DAE.ICONST(2)},b,c,ctp,inl),DAE.MUL(tp),e2),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));

        /* f\'g + fg\' */
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2_1),DAE.ADD(tp),
          DAE.BINARY(e1_1,DAE.MUL(tp),e2));

        /* (f'g - fg' ) / g^2 */
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(
          	DAE.BINARY(e1_1,DAE.MUL(tp),e2),
          	DAE.SUB(tp),
          	DAE.BINARY(e1,DAE.MUL(tp),e2_1)),
          DAE.DIV(tp),
          DAE.BINARY(e2,DAE.MUL(tp),e2));

    case (DAE.UNARY(operator = op,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        DAE.UNARY(op,e_1);

        /* der(tanh(x)) = der(x) / cosh(x) */
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
     local  DAE.ExpType tp;
      equation
        isTanh(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp,inl));

        /* der(cosh(x)) => der(x)sinh(x) */
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isCosh(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sinh"),{exp},b,c,tp,inl));

        /* der(sinh(x)) => der(x)sinh(x) */
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isSinh(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp,inl));

        /* sin(x) */
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isSin(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(Absyn.IDENT("cos"),{exp},b,c,tp,inl),DAE.MUL(DAE.ET_REAL()),
          exp_1);

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isCos(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{exp},b,c,tp,inl)),DAE.MUL(DAE.ET_REAL()),exp_1);

       // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isACos(fname);
        true = Exp.expContains(e, DAE.CREF(tv,DAE.ET_REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
        DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

        // der(arcsin(x)) = der(x)/sqrt(1-x^2)
      case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isASin(fname);
        true = Exp.expContains(e, DAE.CREF(tv,DAE.ET_REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

        // der(arctan(x)) = der(x)/1+x^2
      case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isATan(fname);
        true = Exp.expContains(e, DAE.CREF(tv,DAE.ET_REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e)));

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isExp(fname) "exp(x) => x\'  exp(x)" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(fname,(exp :: {}),b,c,tp,inl),DAE.MUL(DAE.ET_REAL()),exp_1);

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        isLog(fname) "log(x) => x\'  1/x" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),exp));

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isLog10(fname) "log10(x) => x\'1/(xlog(10))" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(exp,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},b,c,tp,inl))));

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),(exp :: {}),b,c,tp,inl))),DAE.MUL(DAE.ET_REAL()),exp_1);

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isTan(fname) "tan x => 1/((cos x)^2)" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.CALL(Absyn.IDENT("cos"),{exp},b,c,tp,inl),DAE.POW(DAE.ET_REAL()),
          DAE.RCONST(2.0))),DAE.MUL(DAE.ET_REAL()),exp_1);

       // derivative of arbitrary function, not dependent of variable, i.e. constant
		case (DAE.CALL(fname,expl,b,c,tp,inl),tv,differentiateIfExp)
		  local list<Boolean> bLst; DAE.ExpType tp;
      equation
        bLst = Util.listMap1(expl,Exp.expContains, DAE.CREF(tv,DAE.ET_REAL()));
        false = Util.listReduce(bLst,boolOr);
      then
        DAE.RCONST(0.0);

    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),tv,differentiateIfExp)
      equation
        e_str = Exp.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (DAE.LUNARY(operator = op,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        DAE.LUNARY(op,e_1);

    case (DAE.RELATION(exp1 = e1,operator = rel,exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        DAE.RELATION(e1_1,rel,e2_1);

        /* der(x) */
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst =
          {(exp as DAE.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        true = Exp.crefEqual(cr, tv);
      then
        DAE.CALL(a,{exp,DAE.ICONST(2)},b,c,tp,inl);

        /* der(abs(x)) = sign(x)der(x) */
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "abs")),expLst = {exp},tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(Absyn.IDENT("sign"),{exp_1},false,true,DAE.ET_INT(),DAE.NO_INLINE()),
          DAE.MUL(DAE.ET_REAL()),exp_1);

    case (DAE.ARRAY(ty = tp,scalar = b,array = expl),tv,differentiateIfExp)
      equation
        expl_1 = Util.listMap2(expl, differentiateExp, tv,differentiateIfExp);
      then
        DAE.ARRAY(tp,b,expl_1);

    case (DAE.TUPLE(PR = expl),tv,differentiateIfExp)
      equation
        expl_1 = Util.listMap2(expl, differentiateExp, tv,differentiateIfExp);
      then
        DAE.TUPLE(expl_1);

    case (DAE.CAST(ty = tp,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        DAE.CAST(tp,e_1);

    case (DAE.ASUB(exp = e,sub = sub),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        DAE.ASUB(e,sub);

    case (DAE.REDUCTION(path = a,expr = e1,ident = b,range = e2),tv,differentiateIfExp)
      local String b;
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        DAE.REDUCTION(a,e1_1,b,e2_1);

    case (e,cr,differentiateIfExp)
      equation
        false = Exp.expContains(e, DAE.CREF(cr,DAE.ET_REAL())) "If the expression does not contain the variable,
	 the derivative is zero. For efficiency reasons this rule
	 is last. Otherwise expressions is allways traversed twice
	 when differentiating." ;
      then
        DAE.RCONST(0.0);

        /* Differentiate if-expressions if last argument true */
    case (DAE.IFEXP(cond,e1,e2),tv,differentiateIfExp as true) equation
      e1_1 = differentiateExp(e1, tv,differentiateIfExp);
      e2_1 = differentiateExp(e2, tv,differentiateIfExp);
    then DAE.IFEXP(cond,e1_1,e2_1);

    case (e,cr,differentiateIfExp)
      equation
				true = RTOpts.debugFlag("failtrace");
        s = Exp.printExpStr(e);
        s2 = Exp.printComponentRefStr(cr);
        str = Util.stringAppendList({"differentiate_exp ",s," w.r.t:",s2," failed\n"});
        //print(str);
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end differentiateExp;

public function isTanh
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "tanh")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "tanh")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isTanh(inPath); then ();
  end matchcontinue;
end isTanh;

public function isCosh
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "cosh")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cosh")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isCosh(inPath); then ();
  end matchcontinue;
end isCosh;

public function isACos
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arccos")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "acos")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isACos(inPath); then ();
  end matchcontinue;
end isACos;

public function isASin
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arcsin")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "asin")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isASin(inPath); then ();
  end matchcontinue;
end isASin;

public function isATan
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arctan")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isATan(inPath); then ();
  end matchcontinue;
end isATan;

public function isATan2
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "arctan2")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan2")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isATan2(inPath); then ();
  end matchcontinue;
end isATan2;

public function isSinh
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sinh")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sinh")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSinh(inPath); then ();
  end matchcontinue;
end isSinh;

public function isSin
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sin")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sin")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSin(inPath); then ();
  end matchcontinue;
end isSin;

public function isCos
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "cos")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cos")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isCos(inPath); then ();
  end matchcontinue;
end isCos;

public function isExp
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "exp")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "exp")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isExp(inPath);  then ();
  end matchcontinue;
end isExp;

public function isLog
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "log")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isLog(inPath); then ();
  end matchcontinue;
end isLog;

public function isLog10
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "log10")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log10")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isLog10(inPath); then ();
  end matchcontinue;
end isLog10;

public function isSqrt
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sqrt")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sqrt")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSqrt(inPath); then ();
  end matchcontinue;
end isSqrt;

public function isTan
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "tan")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "tan")))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isTan(inPath); then ();
  end matchcontinue;
end isTan;
end Derive;

