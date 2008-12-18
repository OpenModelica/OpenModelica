/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

  RCS: $Id: Derive.mo 3772 2008-12-13 16:04:48Z adrpo $

  This module is responsible for symbolic differentiation of equations and
  expressions. Is is currently (2004-09-28) only used by the solve function in
  the exp module for solving equations.

  The symbolic differentiation is used in the Newton-Raphson method and in
  index reduction."

public import Exp;
public import Absyn;

protected import Util;
protected import Error;
protected import Debug;

public function differentiateExpCont "calls differentiateExp(e,cr,false)"
  input Exp.Exp inExp;
  input Exp.ComponentRef inComponentRef;
  output Exp.Exp outExp;
algorithm
  outExp := differentiateExp(inExp,inComponentRef,false);
end differentiateExpCont;

public function differentiateExp "function: differenatiate_exp

  This function differentiates expressions with respect to a given variable,
  given as second argument.
  For example.
  differentiateExp(\'2xy+2x+y\',x) => 2x+2
"
  input Exp.Exp inExp;
  input Exp.ComponentRef inComponentRef;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Exp.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inComponentRef,differentiateIfExp)
    local
      Real rval;
      Exp.ComponentRef cr,crx,tv;
      Exp.Exp e,e1_1,e2_1,e1,e2,const_one,d_e1,d_e2,exp,e_1,exp_1,e3_1,e3,cond;
      Exp.Type tp; 
      Absyn.Path a,fname;
      Boolean b,c;
      Exp.Operator op,rel;
      String e_str,s,s2,str;
      list<Exp.Exp> expl_1,expl,sub;
      Integer i;
    case (Exp.ICONST(integer = _),_,_) then Exp.RCONST(0.0);

    case (Exp.RCONST(real = _),_,_) then Exp.RCONST(0.0);

    case (Exp.CREF(componentRef = cr),crx,_)
      equation
        true = Exp.crefEqual(cr, crx) "D(x)/dx => 1" ;
        rval = intReal(1) "Since bug in MetaModelica Compiler (MMC) makes 1.0 into 0.0" ;
      then
        Exp.RCONST(rval);

    case ((e as Exp.CREF(componentRef = cr)),crx,_)
      equation
        false = Exp.crefEqual(cr, crx) "D(c)/dx => 0" ;
      then
        Exp.RCONST(0.0);

    case (Exp.BINARY(exp1 = e1,operator = Exp.ADD(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        Exp.BINARY(e1_1,Exp.ADD(tp),e2_1);

    case (Exp.BINARY(exp1 = e1,operator = Exp.SUB(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        Exp.BINARY(e1_1,Exp.SUB(tp),e2_1);

    case (Exp.BINARY(exp1 = (e1 as Exp.CREF(componentRef = cr)),operator = Exp.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* ax^(a-1) */
      equation
        true = Exp.crefEqual(cr, tv) "x^a => ax^(a-1)" ;
        false = Exp.expContains(e2, Exp.CREF(tv,tp));
        const_one = differentiateExp(Exp.CREF(tv,tp), tv,differentiateIfExp);
      then
        Exp.BINARY(e2,Exp.MUL(tp),
          Exp.BINARY(e1,Exp.POW(tp),Exp.BINARY(e2,Exp.SUB(tp),const_one)));

    case (Exp.BINARY(exp1 = e1,operator = Exp.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* ax^(a-1) */
      equation
        d_e1 = differentiateExp(e1, tv,differentiateIfExp) "e^x => xder(e)e^x-1" ;
        false = Exp.expContains(e2, Exp.CREF(tv,tp));
        const_one = differentiateExp(Exp.CREF(tv,tp), tv,differentiateIfExp);
        exp = Exp.BINARY(
          Exp.BINARY(d_e1,Exp.MUL(tp),Exp.BINARY(e2,Exp.SUB(tp),Exp.RCONST(1.0))),Exp.MUL(tp),
          Exp.BINARY(e1,Exp.POW(tp),Exp.BINARY(e2,Exp.SUB(tp),const_one)));
      then
        exp;

      case (e as Exp.BINARY(exp1 = e1,operator = Exp.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* a^x => a^x * log(A) */
      equation
        false = Exp.expContains(e1, Exp.CREF(tv,tp));
        true  = Exp.expContains(e2,Exp.CREF(tv,tp));
        d_e2 = differentiateExp(e2, tv,differentiateIfExp);
        exp = Exp.BINARY(d_e2,Exp.MUL(tp),
	        Exp.BINARY(e,Exp.MUL(tp),Exp.CALL(Absyn.IDENT("log"),{e1},false,true,tp))
          );
      then
        exp;

        /* ax^(a-1) */
    case (Exp.BINARY(exp1 = (e1 as Exp.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = {(exp as Exp.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=ctp)),operator = Exp.POW(ty = tp),exp2 = e2),tv,differentiateIfExp)
      local Exp.Type ctp;
      equation
        true = Exp.crefEqual(cr, tv) "der(e)^x => xder(e,2)der(e)^(x-1)" ;
        false = Exp.expContains(e2, Exp.CREF(tv,tp));
        const_one = differentiateExp(Exp.CREF(tv,tp), tv,differentiateIfExp);
      then
        Exp.BINARY(
          Exp.BINARY(Exp.CALL(a,{exp,Exp.ICONST(2)},b,c,ctp),Exp.MUL(tp),e2),Exp.MUL(tp),
          Exp.BINARY(e1,Exp.POW(tp),Exp.BINARY(e2,Exp.SUB(tp),const_one)));

        /* f\'g + fg\' */
    case (Exp.BINARY(exp1 = e1,operator = Exp.MUL(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        Exp.BINARY(Exp.BINARY(e1,Exp.MUL(tp),e2_1),Exp.ADD(tp),
          Exp.BINARY(e1_1,Exp.MUL(tp),e2));

        /* (f'g - fg' ) / g^2 */
    case (Exp.BINARY(exp1 = e1,operator = Exp.DIV(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        Exp.BINARY(
          Exp.BINARY(
          	Exp.BINARY(e1_1,Exp.MUL(tp),e2),
          	Exp.SUB(tp),
          	Exp.BINARY(e1,Exp.MUL(tp),e2_1)),
          Exp.DIV(tp),
          Exp.BINARY(e2,Exp.MUL(tp),e2));

    case (Exp.UNARY(operator = op,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        Exp.UNARY(op,e_1);

        /* der(tanh(x)) = der(x) / cosh(x) */
    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
     local  Exp.Type tp;
      equation
        isTanh(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(exp_1,Exp.DIV(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp));

        /* der(cosh(x)) => der(x)sinh(x) */
    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isCosh(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sinh"),{exp},b,c,tp));

        /* der(sinh(x)) => der(x)sinh(x) */
    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isSinh(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp));

        /* sin(x) */
    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isSin(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(Exp.CALL(Absyn.IDENT("cos"),{exp},b,c,tp),Exp.MUL(Exp.REAL()),
          exp_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isCos(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(
          Exp.UNARY(Exp.UMINUS(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sin"),{exp},b,c,tp)),Exp.MUL(Exp.REAL()),exp_1);

       // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case (Exp.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isACos(fname);
        true = Exp.expContains(e, Exp.CREF(tv,Exp.REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
        Exp.UNARY(Exp.UMINUS(Exp.REAL()),Exp.BINARY(e_1,Exp.DIV(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sqrt"),{Exp.BINARY(Exp.RCONST(1.0),Exp.SUB(Exp.REAL()),Exp.BINARY(e,Exp.MUL(Exp.REAL()),e))},false,true,Exp.REAL())));

        // der(arcsin(x)) = der(x)/sqrt(1-x^2)
      case (Exp.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isASin(fname);
        true = Exp.expContains(e, Exp.CREF(tv,Exp.REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
       Exp.BINARY(e_1,Exp.DIV(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sqrt"),{Exp.BINARY(Exp.RCONST(1.0),Exp.SUB(Exp.REAL()),Exp.BINARY(e,Exp.MUL(Exp.REAL()),e))},false,true,Exp.REAL()));

        // der(arctan(x)) = der(x)/1+x^2
      case (Exp.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        isATan(fname);
        true = Exp.expContains(e, Exp.CREF(tv,Exp.REAL()));
        e_1 = differentiateExp(e, tv,differentiateIfExp)  ;
      then
       Exp.BINARY(e_1,Exp.DIV(Exp.REAL()),Exp.BINARY(Exp.RCONST(1.0),Exp.ADD(Exp.REAL()),Exp.BINARY(e,Exp.MUL(Exp.REAL()),e)));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isExp(fname) "exp(x) => x\'  exp(x)" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(Exp.CALL(fname,(exp :: {}),b,c,tp),Exp.MUL(Exp.REAL()),exp_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        isLog(fname) "log(x) => x\'  1/x" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),exp));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isLog10(fname) "log10(x) => x\'1/(xlog(10))" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),
          Exp.BINARY(exp,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("log"),{Exp.RCONST(10.0)},b,c,tp))));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),
          Exp.BINARY(Exp.RCONST(2.0),Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sqrt"),(exp :: {}),b,c,tp))),Exp.MUL(Exp.REAL()),exp_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        isTan(fname) "tan x => 1/((cos x)^2)" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),
          Exp.BINARY(Exp.CALL(Absyn.IDENT("cos"),{exp},b,c,tp),Exp.POW(Exp.REAL()),
          Exp.RCONST(2.0))),Exp.MUL(Exp.REAL()),exp_1);

       // derivative of arbitrary function, not dependent of variable, i.e. constant
		case (Exp.CALL(fname,expl,b,c,tp),tv,differentiateIfExp)
		  local list<Boolean> bLst; Exp.Type tp;
      equation
        bLst = Util.listMap1(expl,Exp.expContains, Exp.CREF(tv,Exp.REAL()));
        false = Util.listReduce(bLst,boolOr);
      then
        Exp.RCONST(0.0);

    case ((e as Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2)),tv,differentiateIfExp)
      equation
        e_str = Exp.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (Exp.LUNARY(operator = op,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        Exp.LUNARY(op,e_1);

    case (Exp.RELATION(exp1 = e1,operator = rel,exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        Exp.RELATION(e1_1,rel,e2_1);

        /* der(x) */
    case (Exp.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = {(exp as Exp.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=tp),tv,differentiateIfExp)
      local Exp.Type tp;
      equation
        true = Exp.crefEqual(cr, tv);
      then
        Exp.CALL(a,{exp,Exp.ICONST(2)},b,c,tp);

        /* der(abs(x)) = sign(x)der(x) */
    case (Exp.CALL(path = (a as Absyn.IDENT(name = "abs")),expLst = {exp},tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        exp_1 = differentiateExp(exp, tv,differentiateIfExp);
      then
        Exp.BINARY(Exp.CALL(Absyn.IDENT("sign"),{exp_1},false,true,Exp.INT()),
          Exp.MUL(Exp.REAL()),exp_1);

    case (Exp.ARRAY(ty = tp,scalar = b,array = expl),tv,differentiateIfExp)
      equation
        expl_1 = Util.listMap2(expl, differentiateExp, tv,differentiateIfExp);
      then
        Exp.ARRAY(tp,b,expl_1);

    case (Exp.TUPLE(PR = expl),tv,differentiateIfExp)
      equation
        expl_1 = Util.listMap2(expl, differentiateExp, tv,differentiateIfExp);
      then
        Exp.TUPLE(expl_1);

    case (Exp.CAST(ty = tp,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        Exp.CAST(tp,e_1);

    case (Exp.ASUB(exp = e,sub = sub),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv,differentiateIfExp);
      then
        Exp.ASUB(e,sub);

    case (Exp.REDUCTION(path = a,expr = e1,ident = b,range = e2),tv,differentiateIfExp)
      local String b;
      equation
        e1_1 = differentiateExp(e1, tv,differentiateIfExp);
        e2_1 = differentiateExp(e2, tv,differentiateIfExp);
      then
        Exp.REDUCTION(a,e1_1,b,e2_1);

    case (e,cr,differentiateIfExp)
      equation
        false = Exp.expContains(e, Exp.CREF(cr,Exp.REAL())) "If the expression does not contain the variable,
	 the derivative is zero. For efficiency reasons this rule
	 is last. Otherwise expressions is allways traversed twice
	 when differentiating." ;
      then
        Exp.RCONST(0.0);

        /* Differentiate if-expressions if last argument true */
    case (Exp.IFEXP(cond,e1,e2),tv,differentiateIfExp as true) equation
      e1_1 = differentiateExp(e1, tv,differentiateIfExp);
      e2_1 = differentiateExp(e2, tv,differentiateIfExp);
    then Exp.IFEXP(cond,e1_1,e2_1);

    case (e,cr,differentiateIfExp)
      equation
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
