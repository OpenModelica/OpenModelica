package Derive "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Derive.rml
  module:      Derive
  description: Differentiation of equations from DAELow
 
  RCS: $Id$
  
  This module is responsible for symbolic differentiation of equations and 
  expressions. Is is currently (2004-09-28) only used by the solve function in 
  the exp module for solving equations.
  
  The symbolic differentiation is used in the Newton-Raphson method and in
  index reduction.
  
  
"

public import OpenModelica.Compiler.DAELow;

public import OpenModelica.Compiler.Exp;

public import OpenModelica.Compiler.Absyn;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Error;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.SimCodegen;

public function differentiateEquationTime "adrpo -- not used
with \"Print.rml\" 
with \"Graphviz.rml\" 

  function: differentiateEquationTime
 
  Differentiates an equation with respect to the time variable.
"
  input DAELow.Equation inEquation;
  input DAELow.Variables inVariables;
  output DAELow.Equation outEquation;
algorithm 
  outEquation:=
  matchcontinue (inEquation,inVariables)
    local
      Exp.Exp e1_1,e2_1,e1_2,e2_2,e1,e2;
      DAELow.Variables timevars;
      DAELow.Equation dae_equation;
    case (DAELow.EQUATION(exp = e1,scalar = e2),timevars) /* time varying variables */ 
      equation 
        e1_1 = differentiateExpTime(e1, timevars);
        e2_1 = differentiateExpTime(e2, timevars);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1) "& Exp.simplify(e1\'\') => e1\'\' &
	Exp.simplify(e2\'\') => e2\'\'" ;
      then
        DAELow.EQUATION(e1_2,e2_2);
    case (DAELow.ALGORITHM(index = _),_)
      equation 
        print("-differentiate_equation_time on algorithm not impl yet.\n");
      then
        fail();
    case (dae_equation,_)
      equation 
        DAELow.dumpDAELowEqnList({dae_equation},"differentiate_equation_time\n",false);
        print("-differentiate_equation_time faile\n");
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
  differentiate_exp_time(\'x+y=5PI\', {x,y}) => der(x)+der(y)=0
"
  input Exp.Exp inExp;
  input DAELow.Variables inVariables;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inVariables)
    local
      Exp.Type tp;
      Exp.ComponentRef cr;
      String cr_str,cr_str_1,e_str,str,s1;
      Exp.Exp e,e_1,e1_1,e2_1,e1,e2,e3_1,e3,d_e1,exp,e0;
      DAELow.Variables timevars,tv;
      Exp.Operator op,rel;
      list<Exp.Exp> expl_1,expl;
      Absyn.Path a;
      Boolean b,c;
      Integer i;
      Absyn.Path fname;
    case (Exp.ICONST(integer = _),_) then Exp.RCONST(0.0); 
    case (Exp.RCONST(real = _),_) then Exp.RCONST(0.0); 
    case (Exp.CREF(componentRef = Exp.CREF_IDENT(ident = "time",subscriptLst = {}),ty = tp),_) then Exp.RCONST(1.0); 
    case ((e as Exp.CREF(componentRef = cr,ty = tp)),timevars) /* special rule for DUMMY_STATES, they become DUMMY_DER */ 
      equation 
        ({DAELow.VAR(cr,DAELow.DUMMY_STATE(),_,_,_,_,_,_,_,_,_,_,_,_)},_) = DAELow.getVar(cr, timevars);
        cr_str = Exp.printComponentRefStr(cr);
        cr_str_1 = SimCodegen.changeNameForDerivative(cr_str);
      then
        Exp.CREF(Exp.CREF_IDENT(cr_str_1,{}),Exp.REAL());
    case ((e as Exp.CREF(componentRef = cr,ty = tp)),timevars)
      equation 
        (_,_) = DAELow.getVar(cr, timevars);
      then
        Exp.CALL(Absyn.IDENT("der"),{e},false,true,Exp.REAL());
    case (Exp.CALL(path = fname,expLst = {e}),timevars)
      equation 
        isSin(fname);
        e_1 = differentiateExpTime(e, timevars) "der(sin(x)) = der(x)cos(x)" ;
      then
        Exp.BINARY(e_1,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("cos"),{e},false,true,Exp.REAL()));
          
    case (Exp.CALL(path = fname,expLst = {e}),timevars)
      equation 
        isCos(fname);
        e_1 = differentiateExpTime(e, timevars) "der(cos(x)) = -der(x)sin(x)" ;
      then
        Exp.UNARY(Exp.UMINUS(Exp.REAL()),Exp.BINARY(e_1,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sin"),{e},false,true,Exp.REAL())));
          
    case (Exp.CALL(path = fname,expLst = {e}),timevars)
      equation 
        isExp(fname);
        e_1 = differentiateExpTime(e, timevars) "der(exp(x)) = der(x)exp(x)" ;
      then
        Exp.BINARY(e_1,Exp.MUL(Exp.REAL()),
          Exp.CALL(fname,{e},false,true,Exp.REAL()));
          
        case (Exp.CALL(path = fname,expLst = {e}),timevars)
      equation 
        isLog(fname);
        e_1 = differentiateExpTime(e, timevars) "der(log(x)) = der(x)/x";
      then
        Exp.BINARY(e_1,Exp.DIV(Exp.REAL()),e);    
              
    // *** Addition by JA 20060621      
    case (Exp.CALL(path = fname,expLst = {e},tuple_ = false,builtin = true),timevars)
      equation 
        isLog(fname);
        e_1 = differentiateExpTime(e, timevars) "der(log(x)) = der(x)/x" ;
      then
        Exp.BINARY(e_1,Exp.DIV(Exp.REAL()),e);
       
    case (e0 as Exp.BINARY(exp1 = e1,operator = Exp.POW(tp),exp2 = (e2 as Exp.RCONST(_))),timevars) /* ax^(a-1) */ 
      equation 
        d_e1 = differentiateExpTime(e1, timevars) "e^x => xder(e)e^x-1" ;
        //false = Exp.expContains(e2, Exp.CREF(tv,tp));
        //const_one = differentiateExp(Exp.CREF(tv,tp), tv);
        exp = Exp.BINARY(
          Exp.BINARY(d_e1,Exp.MUL(tp),e2),Exp.MUL(tp),
          Exp.BINARY(e1,Exp.POW(tp),Exp.BINARY(e2,Exp.SUB(tp),Exp.RCONST(1.0))));  
      then
        exp;  
          
    // *** End of addition by JA 20060621      
    case ((e as Exp.CREF(componentRef = cr,ty = tp)),timevars) /* list_member(cr,timevars) => false */  then Exp.RCONST(0.0); 
    case (Exp.BINARY(exp1 = e1,operator = Exp.ADD(ty = tp),exp2 = e2),tv)
      equation 
        e1_1 = differentiateExpTime(e1, tv);
        e2_1 = differentiateExpTime(e2, tv);
      then
        Exp.BINARY(e1_1,Exp.ADD(tp),e2_1);
    case (Exp.BINARY(exp1 = e1,operator = Exp.SUB(ty = tp),exp2 = e2),tv)
      equation 
        e1_1 = differentiateExpTime(e1, tv);
        e2_1 = differentiateExpTime(e2, tv);
      then
        Exp.BINARY(e1_1,Exp.SUB(tp),e2_1);
    case (Exp.BINARY(exp1 = e1,operator = Exp.MUL(ty = tp),exp2 = e2),tv) /* f\'g + fg\' */ 
      equation 
        e1_1 = differentiateExpTime(e1, tv);
        e2_1 = differentiateExpTime(e2, tv);
      then
        Exp.BINARY(Exp.BINARY(e1,Exp.MUL(tp),e2_1),Exp.ADD(tp),
          Exp.BINARY(e1_1,Exp.MUL(tp),e2));
    case (Exp.BINARY(exp1 = e1,operator = Exp.DIV(ty = tp),exp2 = e2),tv) /* (f\'g - fg\' ) / g^2 */ 
      equation 
        e1_1 = differentiateExpTime(e1, tv);
        e2_1 = differentiateExpTime(e2, tv);
      then
        Exp.BINARY(
          Exp.BINARY(Exp.BINARY(e1_1,Exp.MUL(tp),e2),Exp.SUB(tp),
          Exp.BINARY(e1,Exp.MUL(tp),e2_1)),Exp.DIV(tp),Exp.BINARY(e2,Exp.MUL(tp),e2));
    case (Exp.UNARY(operator = op,exp = e),tv)
      equation 
        e_1 = differentiateExpTime(e, tv);
      then
        Exp.UNARY(op,e_1);
    case ((e as Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2)),tv)
      equation 
        e_str = Exp.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();
    case (Exp.LUNARY(operator = op,exp = e),tv)
      equation 
        e_1 = differentiateExpTime(e, tv);
      then
        Exp.LUNARY(op,e_1);
    case (Exp.RELATION(exp1 = e1,operator = rel,exp2 = e2),tv)
      equation 
        e1_1 = differentiateExpTime(e1, tv);
        e2_1 = differentiateExpTime(e2, tv);
      then
        Exp.RELATION(e1_1,rel,e2_1);
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),tv)
      equation 
        e2_1 = differentiateExpTime(e2, tv);
        e3_1 = differentiateExpTime(e3, tv);
      then
        Exp.IFEXP(e1,e2_1,e3_1);
    case (Exp.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = expl,tuple_ = b,builtin = c,ty=tp),tv)
      local Exp.Type tp;
      equation 
        expl_1 = Util.listMap1(expl, differentiateExpTime, tv);
      then
        Exp.CALL(a,expl_1,b,c,tp);
    case (Exp.CALL(path = a,expLst = expl,tuple_ = b,builtin = c),tv)
      equation 
        str = Absyn.pathString(a);
        s1 = stringAppend("differentiation of function ", str);
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {s1,"no suggestion"});
      then
        fail();
    case (Exp.ARRAY(ty = tp,scalar = b,array = expl),tv)
      equation 
        expl_1 = Util.listMap1(expl, differentiateExpTime, tv);
      then
        Exp.ARRAY(tp,b,expl_1);
    case ((e as Exp.MATRIX(ty = _)),_)
      equation 
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, 
          {"differentiation of matrix expressions",
          "use nested vectors instead"});
      then
        e;
    case (Exp.TUPLE(PR = expl),tv)
      equation 
        expl_1 = Util.listMap1(expl, differentiateExpTime, tv);
      then
        Exp.TUPLE(expl_1);
    case (Exp.CAST(ty = tp,exp = e),tv)
      equation 
        e_1 = differentiateExpTime(e, tv);
      then
        Exp.CAST(tp,e_1);
    case (Exp.ASUB(exp = e,sub = i),tv)
      equation 
        e_1 = differentiateExpTime(e, tv);
      then
        Exp.ASUB(e,i);
    case (Exp.REDUCTION(path = a,expr = e1,ident = b,range = e2),tv)
      local String b;
      equation 
        e1_1 = differentiateExpTime(e1, tv);
        e2_1 = differentiateExpTime(e2, tv);
      then
        Exp.REDUCTION(a,e1_1,b,e2_1);
    case (e,tv)
      equation 
        str = Exp.printExpStr(e);
        print("-differentiate_exp_time on ");
        print(str);
        print(" failed\n");
      then
        fail();
  end matchcontinue;
end differentiateExpTime;

public function differentiateExp "function: differenatiate_exp
 
  This function differentiates expressions with respect to a given variable, 
  given as second argument.
  For example.
  differentiateExp(\'2xy+2x+y\',x) => 2x+2
"
  input Exp.Exp inExp;
  input Exp.ComponentRef inComponentRef;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inComponentRef)
    local
      Real rval;
      Exp.ComponentRef cr,crx,tv;
      Exp.Exp e,e1_1,e2_1,e1,e2,const_one,d_e1,exp,e_1,exp_1,e3_1,e3;
      Exp.Type tp;
      Absyn.Path a,fname;
      Boolean b,c;
      Exp.Operator op,rel;
      String e_str,s,s2,str;
      list<Exp.Exp> expl_1,expl;
      Integer i;
    case (Exp.ICONST(integer = _),_) then Exp.RCONST(0.0); 

    case (Exp.RCONST(real = _),_) then Exp.RCONST(0.0); 

    case (Exp.CREF(componentRef = cr),crx)
      equation 
        true = Exp.crefEqual(cr, crx) "D(x)/dx => 1" ;
        rval = intReal(1) "Since bug in RML makes 1.0 into 0.0" ;
      then
        Exp.RCONST(rval);

    case ((e as Exp.CREF(componentRef = cr)),crx)
      equation 
        false = Exp.crefEqual(cr, crx) "D(c)/dx => 0" ;
      then
        Exp.RCONST(0.0);

    case (Exp.BINARY(exp1 = e1,operator = Exp.ADD(ty = tp),exp2 = e2),tv)
      equation 
        e1_1 = differentiateExp(e1, tv);
        e2_1 = differentiateExp(e2, tv);
      then
        Exp.BINARY(e1_1,Exp.ADD(tp),e2_1);

    case (Exp.BINARY(exp1 = e1,operator = Exp.SUB(ty = tp),exp2 = e2),tv)
      equation 
        e1_1 = differentiateExp(e1, tv);
        e2_1 = differentiateExp(e2, tv);
      then
        Exp.BINARY(e1_1,Exp.SUB(tp),e2_1);

    case (Exp.BINARY(exp1 = (e1 as Exp.CREF(componentRef = cr)),operator = Exp.POW(ty = tp),exp2 = e2),tv) /* ax^(a-1) */ 
      equation 
        true = Exp.crefEqual(cr, tv) "a^x => ax^(a-1)" ;
        false = Exp.expContains(e2, Exp.CREF(tv,tp));
        const_one = differentiateExp(Exp.CREF(tv,tp), tv);
      then
        Exp.BINARY(e2,Exp.MUL(tp),
          Exp.BINARY(e1,Exp.POW(tp),Exp.BINARY(e2,Exp.SUB(tp),const_one)));

    case (Exp.BINARY(exp1 = e1,operator = Exp.POW(ty = tp),exp2 = e2),tv) /* ax^(a-1) */ 
      equation 
        d_e1 = differentiateExp(e1, tv) "e^x => xder(e)e^x-1" ;
        false = Exp.expContains(e2, Exp.CREF(tv,tp));
        const_one = differentiateExp(Exp.CREF(tv,tp), tv);
        exp = Exp.BINARY(
          Exp.BINARY(d_e1,Exp.MUL(tp),Exp.BINARY(e2,Exp.SUB(tp),Exp.RCONST(1.0))),Exp.MUL(tp),
          Exp.BINARY(e1,Exp.POW(tp),Exp.BINARY(e2,Exp.SUB(tp),const_one)));
      then
        exp;

    case (Exp.BINARY(exp1 = (e1 as Exp.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = {(exp as Exp.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=ctp)),operator = Exp.POW(ty = tp),exp2 = e2),tv) /* ax^(a-1) */ 
      local Exp.Type ctp;
      equation 
        true = Exp.crefEqual(cr, tv) "der(e)^x => xder(e,2)der(e)^(x-1)" ;
        false = Exp.expContains(e2, Exp.CREF(tv,tp));
        const_one = differentiateExp(Exp.CREF(tv,tp), tv);
      then
        Exp.BINARY(
          Exp.BINARY(Exp.CALL(a,{exp,Exp.ICONST(2)},b,c,ctp),Exp.MUL(tp),e2),Exp.MUL(tp),
          Exp.BINARY(e1,Exp.POW(tp),Exp.BINARY(e2,Exp.SUB(tp),const_one)));

    case (Exp.BINARY(exp1 = e1,operator = Exp.MUL(ty = tp),exp2 = e2),tv) /* f\'g + fg\' */ 
      equation 
        e1_1 = differentiateExp(e1, tv);
        e2_1 = differentiateExp(e2, tv);
      then
        Exp.BINARY(Exp.BINARY(e1,Exp.MUL(tp),e2_1),Exp.ADD(tp),
          Exp.BINARY(e1_1,Exp.MUL(tp),e2));

    case (Exp.BINARY(exp1 = e1,operator = Exp.DIV(ty = tp),exp2 = e2),tv) /* (f'g - fg' ) / g^2 */ 
      equation 
        e1_1 = differentiateExp(e1, tv);
        e2_1 = differentiateExp(e2, tv);
      then
        Exp.BINARY(
          Exp.BINARY(
          	Exp.BINARY(e1_1,Exp.MUL(tp),e2),
          	Exp.SUB(tp),
          	Exp.BINARY(e1,Exp.MUL(tp),e2_1)),
          Exp.DIV(tp),
          Exp.BINARY(e2,Exp.MUL(tp),e2));

    case (Exp.UNARY(operator = op,exp = e),tv)
      equation 
        e_1 = differentiateExp(e, tv);
      then
        Exp.UNARY(op,e_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv) /* der(tanh(x)) = der(x) / cosh(x) */ 
     local  Exp.Type tp;
      equation 
        isTanh(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(exp_1,Exp.DIV(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv) /* der(cosh(x)) => der(x)sinh(x) */ 
      local Exp.Type tp;
      equation 
        isCosh(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sinh"),{exp},b,c,tp));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv) /* der(sinh(x)) => der(x)sinh(x) */ 
      local Exp.Type tp;
      equation 
        isSinh(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv) /* sin(x) */ 
      local Exp.Type tp;
      equation 
        isSin(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(Exp.CALL(Absyn.IDENT("cos"),{exp},b,c,tp),Exp.MUL(Exp.REAL()),
          exp_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv)
      local Exp.Type tp;
      equation 
        isCos(fname);
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(
          Exp.UNARY(Exp.UMINUS(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sin"),{exp},b,c,tp)),Exp.MUL(Exp.REAL()),exp_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv)
      local Exp.Type tp;
      equation 
        isExp(fname) "exp(x) => x\'  exp(x)" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(Exp.CALL(fname,(exp :: {}),b,c,tp),Exp.MUL(Exp.REAL()),exp_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c),tv)
      equation 
        isLog(fname) "log(x) => x\'  1/x" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),exp));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv)
      local Exp.Type tp;
      equation 
        isLog10(fname) "log10(x) => x\'1/(xlog(10))" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(exp_1,Exp.MUL(Exp.REAL()),
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),
          Exp.BINARY(exp,Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("log"),{Exp.RCONST(10.0)},b,c,tp))));

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv)
      local Exp.Type tp;
      equation 
        isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),
          Exp.BINARY(Exp.RCONST(2.0),Exp.MUL(Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sqrt"),(exp :: {}),b,c,tp))),Exp.MUL(Exp.REAL()),exp_1);

    case (Exp.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp),tv)
      local Exp.Type tp;
      equation 
        isTan(fname) "tan x => 1/((cos x)^2)" ;
        true = Exp.expContains(exp, Exp.CREF(tv,Exp.REAL()));
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(
          Exp.BINARY(Exp.RCONST(1.0),Exp.DIV(Exp.REAL()),
          Exp.BINARY(Exp.CALL(Absyn.IDENT("cos"),{exp},b,c,tp),Exp.POW(Exp.REAL()),
          Exp.RCONST(2.0))),Exp.MUL(Exp.REAL()),exp_1);
          
       // derivative of arbitrary function, not dependent of variable, i.e. constant
		case (Exp.CALL(fname,expl,b,c,tp),tv)
		  local list<Boolean> bLst; Exp.Type tp;
      equation 
        bLst = Util.listMap1(expl,Exp.expContains, Exp.CREF(tv,Exp.REAL()));
        false = Util.listReduce(bLst,boolOr); 
      then
        Exp.RCONST(0.0); 

    case ((e as Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2)),tv)
      equation 
        e_str = Exp.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();

    case (Exp.LUNARY(operator = op,exp = e),tv)
      equation 
        e_1 = differentiateExp(e, tv);
      then
        Exp.LUNARY(op,e_1);

    case (Exp.RELATION(exp1 = e1,operator = rel,exp2 = e2),tv)
      equation 
        e1_1 = differentiateExp(e1, tv);
        e2_1 = differentiateExp(e2, tv);
      then
        Exp.RELATION(e1_1,rel,e2_1);

    case (Exp.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = {(exp as Exp.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=tp),tv) /* der(x) */ 
      local Exp.Type tp;
      equation 
        true = Exp.crefEqual(cr, tv);
      then
        Exp.CALL(a,{exp,Exp.ICONST(2)},b,c,tp);

    case (Exp.CALL(path = (a as Absyn.IDENT(name = "abs")),expLst = {exp},tuple_ = b,builtin = c),tv) /* der(abs(x)) = sign(x)der(x) */ 
      equation 
        exp_1 = differentiateExp(exp, tv);
      then
        Exp.BINARY(Exp.CALL(Absyn.IDENT("sign"),{exp_1},false,true,Exp.INT()),
          Exp.MUL(Exp.REAL()),exp_1);

    case (Exp.ARRAY(ty = tp,scalar = b,array = expl),tv)
      equation 
        expl_1 = Util.listMap1(expl, differentiateExp, tv);
      then
        Exp.ARRAY(tp,b,expl_1);

    case (Exp.TUPLE(PR = expl),tv)
      equation 
        expl_1 = Util.listMap1(expl, differentiateExp, tv);
      then
        Exp.TUPLE(expl_1);

    case (Exp.CAST(ty = tp,exp = e),tv)
      equation 
        e_1 = differentiateExp(e, tv);
      then
        Exp.CAST(tp,e_1);

    case (Exp.ASUB(exp = e,sub = i),tv)
      equation 
        e_1 = differentiateExp(e, tv);
      then
        Exp.ASUB(e,i);

    case (Exp.REDUCTION(path = a,expr = e1,ident = b,range = e2),tv)
      local String b;
      equation 
        e1_1 = differentiateExp(e1, tv);
        e2_1 = differentiateExp(e2, tv);
      then
        Exp.REDUCTION(a,e1_1,b,e2_1);

    case (e,cr)
      equation 
        false = Exp.expContains(e, Exp.CREF(cr,Exp.REAL())) "If the expression does not contain the variable,
	 the derivative is zero. For efficiency reasons this rule
	 is last. Otherwise expressions is allways traversed twice 
	 when differentiating." ;
      then
        Exp.RCONST(0.0);

    case (e,cr)
      equation 
        s = Exp.printExpStr(e);
        s2 = Exp.printComponentRefStr(cr);
        str = Util.stringAppendList({"differentiate_exp ",s," w.r.t:",s2," failed\n"});
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
  end matchcontinue;
end isTanh;

public function isCosh
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "cosh")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cosh")))) then (); 
  end matchcontinue;
end isCosh;

public function isACos
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "acos")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "acos")))) then (); 
  end matchcontinue;
end isACos;

public function isASin
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "asin")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "asin")))) then (); 
  end matchcontinue;
end isASin;

public function isATan
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "atan")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan")))) then (); 
  end matchcontinue;
end isATan;

public function isATan2
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "atan2")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "atan2")))) then (); 
  end matchcontinue;
end isATan2;

public function isSinh
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sinh")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sinh")))) then (); 
  end matchcontinue;
end isSinh;

public function isSin
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sin")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sin")))) then (); 
  end matchcontinue;
end isSin;

public function isCos
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "cos")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "cos")))) then (); 
  end matchcontinue;
end isCos;

public function isExp
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "exp")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "exp")))) then (); 
  end matchcontinue;
end isExp;

public function isLog
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "log")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log")))) then (); 
  end matchcontinue;
end isLog;

public function isLog10
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "log10")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "log10")))) then (); 
  end matchcontinue;
end isLog10;

public function isSqrt
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "sqrt")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "sqrt")))) then (); 
  end matchcontinue;
end isSqrt;

public function isTan
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inPath)
    case (Absyn.IDENT(name = "tan")) then (); 
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Math",path = Absyn.IDENT(name = "tan")))) then (); 
  end matchcontinue;
end isTan;
end Derive;

