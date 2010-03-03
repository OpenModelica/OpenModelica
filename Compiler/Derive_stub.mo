/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
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

protected import Exp;
protected import Util;
protected import Error;
protected import Debug;

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
	        DAE.BINARY(e,DAE.MUL(tp),DAE.CALL(Absyn.IDENT("log"),{e1},false,true,tp))
          );
      then
        exp;

        /* ax^(a-1) */
    case (DAE.BINARY(exp1 = (e1 as DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = {(exp as DAE.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=ctp)),operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp)
      local DAE.ExpType ctp;
      equation
        true = Exp.crefEqual(cr, tv) "der(e)^x => xder(e,2)der(e)^(x-1)" ;
        false = Exp.expContains(e2, DAE.CREF(tv,tp));
        const_one = differentiateExp(DAE.CREF(tv,tp), tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.CALL(a,{exp,DAE.ICONST(2)},b,c,ctp),DAE.MUL(tp),e2),DAE.MUL(tp),
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
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
     local  DAE.ExpType tp;
      equation
        isTanh(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp));

        /* der(cosh(x)) => der(x)sinh(x) */
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isCosh(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sinh"),{exp},b,c,tp));

        /* der(sinh(x)) => der(x)sinh(x) */
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isSinh(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp));

        /* sin(x) */
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isSin(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(Absyn.IDENT("cos"),{exp},b,c,tp),DAE.MUL(DAE.ET_REAL()),
          exp_1);

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isCos(fname);
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{exp},b,c,tp)),DAE.MUL(DAE.ET_REAL()),exp_1);

       // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isACos(fname);
        true = Exp.expContains(e, DAE.CREF(tv,DAE.ET_REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
        DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},false,true,DAE.ET_REAL())));

        // der(arcsin(x)) = der(x)/sqrt(1-x^2)
      case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isASin(fname);
        true = Exp.expContains(e, DAE.CREF(tv,DAE.ET_REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},false,true,DAE.ET_REAL()));

        // der(arctan(x)) = der(x)/1+x^2
      case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isATan(fname);
        true = Exp.expContains(e, DAE.CREF(tv,DAE.ET_REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e)));

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isExp(fname) "exp(x) => x\'  exp(x)" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(fname,(exp :: {}),b,c,tp),DAE.MUL(DAE.ET_REAL()),exp_1);

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        isLog(fname) "log(x) => x\'  1/x" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),exp));

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isLog10(fname) "log10(x) => x\'1/(xlog(10))" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(exp,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},b,c,tp))));

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),(exp :: {}),b,c,tp))),DAE.MUL(DAE.ET_REAL()),exp_1);

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        isTan(fname) "tan x => 1/((cos x)^2)" ;
        true = Exp.expContains(exp, DAE.CREF(tv,DAE.ET_REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.CALL(Absyn.IDENT("cos"),{exp},b,c,tp),DAE.POW(DAE.ET_REAL()),
          DAE.RCONST(2.0))),DAE.MUL(DAE.ET_REAL()),exp_1);

       // derivative of arbitrary function, not dependent of variable, i.e. constant
		case (DAE.CALL(fname,expl,b,c,tp),tv,differentiateIfExp)
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
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = {(exp as DAE.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local DAE.ExpType tp;
      equation
        true = Exp.crefEqual(cr, tv);
      then
        DAE.CALL(a,{exp,DAE.ICONST(2)},b,c,tp);

        /* der(abs(x)) = sign(x)der(x) */
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "abs")),expLst = {exp},tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(Absyn.IDENT("sign"),{exp_1},false,true,DAE.ET_INT()),
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
