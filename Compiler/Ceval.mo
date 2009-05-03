/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköpings, Sweden.
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

package Ceval
" file:	 Ceval.mo
  package:      Ceval
  description: Constant propagation of expressions

  RCS: $Id$

  This module handles constant propagation (or evaluation)
  When elaborating expressions, in the Static module, expressions are checked to 
  find out its type. It also checks whether the expressions are constant and the function 
  ceval in this module will then evaluate the expression to a constant value, defined
  in the Values module.
 
  Input: 
 	Env: Environment with bindings
 	Exp: Expression to check for constant evaluation
 	Bool flag determines whether the current instantiation is implicit
 	InteractiveSymbolTable is optional, and used in interactive mode,
 	e.g. from OMShell
 	
  Output:
 	Value: The evaluated value
      InteractiveSymbolTable: Modified symbol table
      Subscript list : Evaluates subscripts and generates constant expressions."

public import Env;
public import Exp;
public import Interactive;
public import Values;
public import Absyn;
public import Types;
public import ConnectionGraph;

public 
uniontype Msg
  record MSG "Give error message" end MSG;
  record NO_MSG "Do not give error message" end NO_MSG;
end Msg;

protected import Static;
protected import Print;
protected import ModUtil;
protected import System;
protected import SCode;
protected import Inst;
protected import Lookup;
protected import DAE;
protected import Debug;
protected import Util;
protected import RTOpts;
protected import Prefix;
protected import Derive;
protected import Connect;
protected import Error;
protected import Cevalfunc;
protected import CevalScript;

public function ceval 
"function: ceval
  This function is used when the value of a constant expression is
  needed.  It takes an environment and an expression and calculates
  its value.
 
  The third argument indicates whether the evaluation is performed in the
  interactive environment (implicit instantiation), in which case function
  calls are evaluated.
  
  The last argument is an optional dimension."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Option<Integer> inIntegerOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inIntegerOption,inMsg)
    local
      Integer x,dim,l,lhv,rhv,res,start_1,stop_1,step_1,i,indx_1,indx;
      Option<Interactive.InteractiveSymbolTable> st,st_1,st_2,st_3;
      Real lhvr,rhvr,resr,sum,div,diff,r;
      String funcstr,str,lh_str,rh_str,iter;
      Boolean impl,builtin,b,b_1;
      Absyn.Exp exp_1,exp;
      list<Env.Frame> env;
      Msg msg;
      Absyn.Element elt_1,elt;
      Absyn.CodeNode c;
      list<Values.Value> es_1,elts,vallst,vlst1,vlst2,reslst,aval,rhvals,lhvals,arr,arr_1,ivals,rvals,vallst_1,vals;
      list<Exp.Exp> es,expl;
      list<list<tuple<Exp.Exp, Boolean>>> expll;
      Values.Value v,newval,value,sval,elt1,elt2,v_1,lhs_1,rhs_1;
      Exp.Exp lh,rh,e,lhs,rhs,start,stop,step,e1,e2,iterexp;
      Absyn.Path funcpath,func;
      Absyn.Program p,ptot;
      list<Interactive.CompiledCFunction> cflist;
      Exp.Operator relop;
      Env.Cache cache;
    case (cache,_,Exp.ICONST(integer = x),_,st,_,_) then (cache,Values.INTEGER(x),st); 

    case (cache,_,Exp.RCONST(real = x),_,st,_,_)
      local Real x;
      then
        (cache,Values.REAL(x),st);

    case (cache,_,Exp.SCONST(string = x),_,st,_,_)
      local String x;
      then
        (cache,Values.STRING(x),st);

    case (cache,_,Exp.BCONST(bool = x),_,st,_,_)
      local Boolean x;
      then
        (cache,Values.BOOL(x),st);

    case (cache,_,Exp.END(),_,st,SOME(dim),_) then (cache,Values.INTEGER(dim),st); 

    case (cache,_,Exp.END(),_,st,NONE, MSG())
      equation 
        Error.addMessage(Error.END_ILLEGAL_USE_ERROR, {});
      then
        fail();

    case (cache,_,Exp.END(),_,st,NONE, NO_MSG()) then fail(); 

    case (cache,env,Exp.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation 
        (cache,exp_1) = CevalScript.cevalAstExp(cache,env, exp, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (cache,env,Exp.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation 
        (cache,exp_1) = CevalScript.cevalAstExp(cache,env, exp, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (cache,env,Exp.CODE(code = Absyn.C_ELEMENT(element = elt)),impl,st,_,msg)
      equation 
        (cache,elt_1) = CevalScript.cevalAstElt(cache,env, elt, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_ELEMENT(elt_1)),st);

    case (cache,env,Exp.CODE(code = c),_,st,_,_) then (cache,Values.CODE(c),st); 

    case (cache,env,Exp.ARRAY(array = es),impl,st,_,msg)
      equation 
        (cache,es_1) = cevalList(cache,env, es, impl, st, msg);
        l = listLength(es_1);
      then
        (cache,Values.ARRAY(es_1),st);

    case (cache,env,Exp.MATRIX(scalar = expll),impl,st,_,msg)
      equation 
        (cache,elts) = cevalMatrixElt(cache,env, expll, impl, msg);
      then
        (cache,Values.ARRAY(elts),st);

    case (cache,env,Exp.CREF(componentRef = c),(impl as false),SOME(st),_,msg)
      local
        Exp.ComponentRef c;
        Interactive.InteractiveSymbolTable st;
      equation 
        (cache,v) = cevalCref(cache,env, c, false, msg) "When in interactive mode, always evalutate crefs, i.e non-implicit
	    mode.." ;
      then
        (cache,v,SOME(st));

    case (cache,env,Exp.CREF(componentRef = c),impl,st,_,msg)
      local Exp.ComponentRef c;
      equation 
        (cache,v) = cevalCref(cache,env, c, impl, msg);
      then
        (cache,v,st);

    //Evaluates for build in types. ADD, SUB, MUL, DIV for Reals and Integers.
    case (cache,env,exp,impl,st,dim,msg)
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (cache,v,st_1) = cevalBuiltin(cache,env, exp, impl, st, dim, msg);
      then
        (cache,v,st_1);

    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),impl,st,_,msg) 
      /* Call functions FIXME: functions are always generated. Put back the check
	  and write another rule for the false case that generates the function */ 
      equation
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
        (cache,newval)= cevalCallFunction(cache,env, e, vallst, msg);
      then
        (cache,newval,st);

    case (cache,env,(e as Exp.CALL(path = _)),(impl as false),NONE,_, NO_MSG()) then fail(); 

    case (cache,env,(e as Exp.CALL(path = _)),(impl as true),SOME(st),_,msg)
      local Interactive.InteractiveSymbolTable st;
      equation 
        (cache,value,st) = CevalScript.cevalInteractiveFunctions(cache,env, e, st, msg);
      then
        (cache,value,SOME(st));

    case (cache,env,(e as Exp.CALL(path = func,expLst = expl)),(impl as true),(st as SOME(_)),_,msg)
      equation 
				(cache,false) = Static.isExternalObjectFunction(cache,env,func);
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg) "Call of record constructors, etc., i.e. functions that can be constant propagated." ;
        (cache,newval) = cevalFunction(cache,env, func, vallst, impl, msg);
      then
        (cache,newval,st);

    case (cache,env,(e as Exp.CALL(path = func,expLst = expl)),(impl as true),
      (st as SOME(Interactive.SYMBOLTABLE(p,_,_,_,_,cflist,_))),_,msg)
      local Integer funcHandle;
      equation 
        (true, funcHandle) = Static.isFunctionInCflist(cflist, func) "Call externally implemented functions." ;
        (cache,false) = Static.isExternalObjectFunction(cache,env,func);
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
        funcstr = ModUtil.pathString2(func, "_");
        Debug.fprintln("dynload", "CALL: about to execute: " +& funcstr);
        newval = System.executeFunction(funcHandle, vallst);
      then
        (cache,newval,st);
        
    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),impl,st,_,msg)
      /* Is this case really necessary? */
      local String s; list<String> ss;
      equation
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
        (cache,newval)= cevalCallFunction(cache,env, e, vallst, msg);
      then
        (cache,newval,st);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.ADD(ty = Exp.STRING()),exp2 = rh),impl,st,_,msg) /* Strings */ 
      local String lhv,rhv;
      equation 
        (cache,Values.STRING(lhv),_) = ceval(cache,env, lh, impl, st, NONE, msg);
        (cache,Values.STRING(rhv),_) = ceval(cache,env, rh, impl, st, NONE, msg);
        str = stringAppend(lhv, rhv);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.ADD(ty = Exp.REAL()),exp2 = rh),impl,st,dim,msg) /* Numerical */ 
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation 
        (cache,Values.REAL(lhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.REAL(rhv),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        sum = lhv +. rhv;
      then
        (cache,Values.REAL(sum),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.ADD_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vlst1),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.addElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.SUB_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vlst1),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.subElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vlst1),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.mulElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.DIV_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vlst1),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.divElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.POW_ARR2(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vlst1),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.powElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = Values.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.ADD_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.ADD_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = Values.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.SUB_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.subScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.SUB_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = Values.subArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.POW_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.powScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.POW_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = Values.powArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.DIV_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = Values.divScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.DIV_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = Values.divArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst),st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL_SCALAR_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(rhvals),st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(lhvals),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        res = Values.multScalarProduct(rhvals, lhvals);
      then
        (cache,res,st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation 
        (cache,Values.ARRAY((lhvals as (elt1 :: _))),st_1) = ceval(cache,env, lh, impl, st, dim, msg) "{{..}..{..}}  {...}" ;
        (cache,Values.ARRAY((rhvals as (elt2 :: _))),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        true = Values.isArray(elt1);
        false = Values.isArray(elt2);
        res = Values.multScalarProduct(lhvals, rhvals);
      then
        (cache,res,st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation 
        (cache,Values.ARRAY((rhvals as (elt1 :: _))),st_1) = ceval(cache,env, rh, impl, st, dim, msg) "{...}  {{..}..{..}}" ;
        (cache,Values.ARRAY((lhvals as (elt2 :: _))),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        true = Values.isArray(elt1);
        false = Values.isArray(elt2);
        res = Values.multScalarProduct(lhvals, rhvals);
      then
        (cache,res,st_2);

    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        list<Values.Value> res;
        Option<Integer> dim;
      equation 
        (cache,Values.ARRAY((rhvals as (elt1 :: _))),st_1) = ceval(cache,env, rh, impl, st, dim, msg) "{{..}..{..}}  {{..}..{..}}" ;
        (cache,Values.ARRAY((lhvals as (elt2 :: _))),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        true = Values.isArray(elt1);
        true = Values.isArray(elt2);
        res = Values.multMatrix(lhvals, rhvals);
      then
        (cache,Values.ARRAY(res),st_2);

		//POW (integer or real)
    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.POW(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);        
				res3 = Values.safeIntRealOp(res1, res2, Values.POWOP);
      then 
        (cache,res3,st_2);

		//MUL (integer or real)
    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.MUL(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);        
				res3 = Values.safeIntRealOp(res1, res2, Values.MULOP);
      then
        (cache,res3,st_2);

		//DIV (integer or real)
    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.DIV(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);        
				res3 = Values.safeIntRealOp(res1, res2, Values.DIVOP);
      then
        (cache,res3,st_2);

		//DIV (handle div by zero)
    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.DIV(ty =_),exp2 = rh),impl,st,dim,msg)
      local
        Real lhv,rhv;
        Option<Integer> dim;
        Values.Value res1;
      equation 
         (cache,res1,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
         true = Values.isZero(res1);
        lh_str = Exp.printExpStr(lh);
        rh_str = Exp.printExpStr(rh);
        Error.addMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str});
      then
        fail();

		//ADD (integer or real)
    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.ADD(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);        
				res3 = Values.safeIntRealOp(res1, res2, Values.ADDOP);
      then
        (cache,res3,st_2);

		//SUB (integer or real)
    case (cache,env,Exp.BINARY(exp1 = lh,operator = Exp.SUB(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);        
				res3 = Values.safeIntRealOp(res1, res2, Values.SUBOP);
      then
        (cache,res3,st_2);

        /*  unary minus of array */  
    case (cache,env,Exp.UNARY(operator = Exp.UMINUS_ARR(ty = _),exp = exp),impl,st,dim,msg) 
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(arr),st_1) = ceval(cache,env, exp, impl, st, dim, msg);
        arr_1 = Util.listMap(arr, Values.valueNeg);
      then
        (cache,Values.ARRAY(arr_1),st_1);

    case (cache,env,Exp.UNARY(operator = Exp.UMINUS(ty = _),exp = exp),impl,st,dim,msg)
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (cache,v,st_1) = ceval(cache,env, exp, impl, st, dim, msg);
        v_1 = Values.valueNeg(v);
      then
        (cache,v_1,st_1);

    case (cache,env,Exp.UNARY(operator = Exp.UPLUS(ty = _),exp = exp),impl,st,dim,msg)
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (cache,v,st_1) = ceval(cache,env, exp, impl, st, dim, msg);
      then
        (cache,v,st_1);

        /* Logical */         
        // special case when leftside is false... 
        // We allow errors on right hand side. and even if there is no errors, the performance 
        // will be better.
    case (cache,env,Exp.LBINARY(exp1 = lh,operator = Exp.AND(),exp2 = rh),impl,st,dim,msg) 
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation 
        (cache,Values.BOOL(lhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        false = lhv;        
      then
        (cache,Values.BOOL(false),st_1);
        
        /* Logical */ 
    case (cache,env,Exp.LBINARY(exp1 = lh,operator = Exp.AND(),exp2 = rh),impl,st,dim,msg) 
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation 
        (cache,Values.BOOL(lhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);        
        (cache,Values.BOOL(rhv),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        x = boolAnd(lhv, rhv);
      then
        (cache,Values.BOOL(x),st_2);

    case (cache,env,Exp.LBINARY(exp1 = lh,operator = Exp.OR(),exp2 = rh),impl,st,dim,msg)
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation 
        (cache,Values.BOOL(lhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.BOOL(rhv),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        x = boolOr(lhv, rhv);
      then
        (cache,Values.BOOL(x),st_2);
// Special case for a boolean expression like if( expression or ARRAY_IDEX_OUT_OF_BOUNDS_ERROR) 
// "expression" in this case we return the lh expression to be equall to 
// the previous c-code generation.
    case (cache,env,Exp.LBINARY(exp1 = lh,operator = Exp.OR(),exp2 = rh),impl,st,dim,msg)
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation 
        (cache,v as Values.BOOL(rhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        failure((_,_,_) = ceval(cache,env, rh, impl, st_1, dim, msg));
      then
        (cache,v,st_1);
        
    case (cache,env,Exp.LUNARY(operator = Exp.NOT(),exp = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.BOOL(b),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        b_1 = boolNot(b);
      then
        (cache,Values.BOOL(b_1),st_1);

        /* Relations */ 
    case (cache,env,Exp.RELATION(exp1 = lhs,operator = relop,exp2 = rhs),impl,st,dim,msg) 
      local Option<Integer> dim;
      equation 
        (cache,lhs_1,st_1) = ceval(cache,env, lhs, impl, st, dim, msg);
        (cache,rhs_1,st_2) = ceval(cache,env, rhs, impl, st_1, dim, msg);
        v = cevalRelation(lhs_1, relop, rhs_1);
      then
        (cache,v,st_2);

    case (cache,env,Exp.RANGE(ty = Exp.INT(),exp = start,expOption = NONE,range = stop),impl,st,dim,msg) /*  */ 
      local Option<Integer> dim;
      equation 
        (cache,Values.INTEGER(start_1),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.INTEGER(stop_1),st_2) = ceval(cache,env, stop, impl, st_1, dim, msg);
        arr = cevalRange(start_1, 1, stop_1);
      then
        (cache,Values.ARRAY(arr),st_1);

    case (cache,env,Exp.RANGE(ty = Exp.INT(),exp = start,expOption = SOME(step),range = stop),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.INTEGER(start_1),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.INTEGER(step_1),st_2) = ceval(cache,env, step, impl, st_1, dim, msg);
        (cache,Values.INTEGER(stop_1),st_3) = ceval(cache,env, stop, impl, st_2, dim, msg);
        arr = cevalRange(start_1, step_1, stop_1);
      then
        (cache,Values.ARRAY(arr),st_3);

    case (cache,env,Exp.RANGE(ty = Exp.REAL(),exp = start,expOption = NONE,range = stop),impl,st,dim,msg)
      local
        Real start_1,stop_1,step;
        Option<Integer> dim;
      equation 
        (cache,Values.REAL(start_1),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.REAL(stop_1),st_2) = ceval(cache,env, stop, impl, st_1, dim, msg);
        diff = stop_1 -. start_1;
        step = intReal(1);
        arr = cevalRangeReal(start_1, step, stop_1) "bug in MetaModelica Compiler (MMC), 1.0 => 0.0 in cygwin" ;
      then
        (cache,Values.ARRAY(arr),st_2);

    case (cache,env,Exp.RANGE(ty = Exp.REAL(),exp = start,expOption = SOME(step),range = stop),impl,st,dim,msg)
      local
        Real start_1,step_1,stop_1;
        Option<Integer> dim;
      equation 
        (cache,Values.REAL(start_1),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.REAL(step_1),st_2) = ceval(cache,env, step, impl, st_1, dim, msg);
        (cache,Values.REAL(stop_1),st_3) = ceval(cache,env, stop, impl, st_2, dim, msg);
        arr = cevalRangeReal(start_1, step_1, stop_1);
      then
        (cache,Values.ARRAY(arr),st_3);

    case (cache,env,Exp.CAST(ty = Exp.REAL(),exp = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.INTEGER(i),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        r = intReal(i);
      then
        (cache,Values.REAL(r),st_1);

    case (cache,env,Exp.CAST(ty = Exp.T_ARRAY(Exp.REAL(),_),exp = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(ivals),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        rvals = Values.typeConvert(Exp.INT(), Exp.REAL(), ivals);
      then
        (cache,Values.ARRAY(rvals),st_1);

    case (cache,env,Exp.CAST(ty = Exp.REAL(),exp = (e as Exp.ARRAY(ty = Exp.INT(),array = expl))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vallst),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        vallst_1 = Values.typeConvert(Exp.INT(), Exp.REAL(), vallst);
      then
        (cache,Values.ARRAY(vallst_1),st_1);

    case (cache,env,Exp.CAST(ty = Exp.REAL(),exp = (e as Exp.RANGE(ty = Exp.INT()))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vallst),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        vallst_1 = Values.typeConvert(Exp.INT(), Exp.REAL(), vallst);
      then
        (cache,Values.ARRAY(vallst_1),st_1);

    case (cache,env,Exp.CAST(ty = Exp.REAL(),exp = (e as Exp.MATRIX(ty = Exp.INT()))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vallst),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        vallst_1 = Values.typeConvert(Exp.INT(), Exp.REAL(), vallst);
      then
        (cache,Values.ARRAY(vallst_1),st_1);

    case (cache,env,Exp.IFEXP(expCond = b,expThen = e1,expElse = e2),impl,st,dim,msg)
      local
        Exp.Exp b;
        Option<Integer> dim;
      equation 
        (cache,Values.BOOL(true),st_1) = ceval(cache,env, b, impl, st, dim, msg) "Ifexp, true branch" ;
        (cache,v,st_2) = ceval(cache,env, e1, impl, st_1, dim, msg);
      then
        (cache,v,st_2);

    case (cache,env,Exp.IFEXP(expCond = b,expThen = e1,expElse = e2),impl,st,dim,msg)
      local
        Exp.Exp b;
        Option<Integer> dim;
      equation 
        (cache,Values.BOOL(false),st_1) = ceval(cache,env, b, impl, st, dim, msg) "Ifexp, false branch" ;
        (cache,v,st_2) = ceval(cache,env, e2, impl, st_1, dim, msg);
      then
        (cache,v,st_2);

    case (cache,env,Exp.ASUB(exp = e,sub = ((e1 as Exp.ICONST(indx))::{})),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vals),st_1) = ceval(cache,env, e, impl, st, dim, msg) "asub" ;
        indx_1 = indx - 1;
        v = listNth(vals, indx_1);
      then
        (cache,v,st_1);
    case (cache, env, Exp.ASUB(exp = e,sub = expl ), impl, st, dim, msg)
      local Option<Integer> dim; String s;
      equation 
        (cache,Values.ARRAY(vals),st_1) = ceval(cache,env, e, impl, st, dim, msg) "asub" ;
        (cache,es_1) = cevalList(cache,env, expl, impl, st_1, msg) "asub exp" ;
        v = Util.listFirst(es_1);
        v = Values.nthnthArrayelt(es_1,Values.ARRAY(vals),v);
      then
        (cache,v,st_1);
    case (cache,env,Exp.REDUCTION(path = p,expr = exp,ident = iter,range = iterexp),impl,st,dim, MSG()) /* (v,st) */ 
      local
        Absyn.Path p;
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        print("#-- Ceval.ceval reduction not impl yet.\n");
      then
        fail();

    case (cache,env,Exp.REDUCTION(path = p,expr = exp,ident = iter,range = iterexp),impl,st,dim, NO_MSG()) /* (v,st) */ 
      local
        Absyn.Path p;
        Exp.Exp exp;
        Option<Integer> dim;
      then
        fail();

    /* ceval can fail and that is ok, catched by other rules... */ 
    case (cache,env,e,_,_,_, MSG()) 
      equation
        /*
        Debug.fprint("failtrace", "- Ceval.ceval failed: ");
        str = Exp.printExpStr(e);
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", "\n");        
        Debug.fprint("failtrace", " Env:" );
        Debug.fcall("failtrace", Env.printEnv, env);
        */
      then
        fail();
  end matchcontinue;
end ceval;

protected function cevalBuiltin 
"function: cevalBuiltin 
  Helper for ceval. Parts for builtin calls are moved here, for readability.
  See ceval for documentation.
  NOTE:    It\'s ok if cevalBuiltin fails. Just means the call was not a builtin function"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Option<Integer> inIntegerOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inIntegerOption,inMsg)
    local
      partial function HandlerFunc
				input Env.Cache inCache;
        input list<Env.Frame> inEnvFrameLst;
        input list<Exp.Exp> inExpExpLst;
        input Boolean inBoolean;
        input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
        input Msg inMsg;
        output Env.Cache outCache;
        output Values.Value outValue;
        output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
      end HandlerFunc;
      Values.Value v,newval;
      Option<Interactive.InteractiveSymbolTable> st;
      list<Env.Frame> env;
      Exp.Exp exp,dim,e;
      Boolean impl,builtin;
      Msg msg;
      HandlerFunc handler;
      String id;
      list<Exp.Exp> args,expl;
      list<Values.Value> vallst;
      Absyn.Path funcpath,path;
      Env.Cache cache;
    case (cache,env,Exp.SIZE(exp = exp,sz = SOME(dim)),impl,st,_,msg)
      equation 
        (cache,v,st) = cevalBuiltinSize(cache,env, exp, dim, impl, st, msg) "Handle size separately" ;
      then
        (cache,v,st);
    case (cache,env,Exp.SIZE(exp = exp,sz = NONE),impl,st,_,msg)
      equation 
        (cache,v,st) = cevalBuiltinSizeMatrix(cache,env, exp, impl, st, msg);
      then
        (cache,v,st);
    case (cache,env,Exp.CALL(path = path,expLst = args,builtin = builtin),impl,st,_,msg) /* buildin: as true */ 
      equation 
        id = Absyn.pathString(path);
        handler = cevalBuiltinHandler(id);
        (cache,v,st) = handler(cache,env, args, impl, st, msg);
      then
        (cache,v,st);
    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = (builtin as true))),impl,(st as NONE),_,msg)
      equation  
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
        (cache,newval) = cevalCallFunction(cache,env, e, vallst, msg);
      then
        (cache,newval,st);
  end matchcontinue;
end cevalBuiltin;

protected function cevalBuiltinHandler 
"function: cevalBuiltinHandler
  This function dispatches builtin functions and operators to a dedicated
  function that evaluates that particular function.
  It takes an identifier as input and returns a function that evaluates that
  function or operator.  
  NOTE: size handled specially. see cevalBuiltin:
        removed: case (\"size\") => cevalBuiltinSize"
  input Absyn.Ident inIdent;
  output HandlerFunc handler;
  partial function HandlerFunc
  	input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Exp.Exp> inExpExpLst;
    input Boolean inBoolean;
    input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
    input Msg inMsg;
    output Env.Cache outCache;
    output Values.Value outValue;
    output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
  end HandlerFunc;
algorithm 
  handler :=
  matchcontinue (inIdent)
    local String id;
    case "floor" then cevalBuiltinFloor; 
    case "ceil" then cevalBuiltinCeil; 
    case "abs" then cevalBuiltinAbs; 
    case "sqrt" then cevalBuiltinSqrt; 
    case "div" then cevalBuiltinDiv; 
    case "sin" then cevalBuiltinSin; 
    case "cos" then cevalBuiltinCos;
    case "tan" then cevalBuiltinTan;
    case "sinh" then cevalBuiltinSinh; 
    case "cosh" then cevalBuiltinCosh;
    case "tanh" then cevalBuiltinTanh;                    
    case "log" then cevalBuiltinLog;   
    case "arcsin" then cevalBuiltinAsin; 
    case "arccos" then cevalBuiltinAcos; 
    case "arctan" then cevalBuiltinAtan; 
    case "integer" then cevalBuiltinInteger; 
    case "mod" then cevalBuiltinMod; 
    case "max" then cevalBuiltinMax; 
    case "min" then cevalBuiltinMin; 
    case "rem" then cevalBuiltinRem; 
    case "diagonal" then cevalBuiltinDiagonal; 
    case "transpose" then cevalBuiltinTranspose; 
    case "differentiate" then cevalBuiltinDifferentiate; 
    case "simplify" then cevalBuiltinSimplify; 
    case "sign" then cevalBuiltinSign; 
    case "exp" then cevalBuiltinExp; 
    case "noEvent" then cevalBuiltinNoevent; 
    case "cardinality" then cevalBuiltinCardinality; 
    case "cat" then cevalBuiltinCat; 
    case "identity" then cevalBuiltinIdentity; 
    case "promote" then cevalBuiltinPromote; 
    case "String" then cevalBuiltinString;
    case "isRoot" then cevalBuiltinIsRoot;
    //case "semiLinear" then cevalBuiltinSemiLinear;
    //case "delay" then cevalBuiltinDelay;
    case id
      equation 
        Debug.fprint("ceval", "No Ceval.cevalBuiltinHandler found for: ");
        Debug.fprintln("ceval", id);
      then
        fail();
  end matchcontinue;
end cevalBuiltinHandler;

protected function cevalCallFunction "function: cevalCallFunction
  This function evaluates CALL expressions, i.e. function calls.
  They are currently evaluated by generating code for the function and
  then dynamicly load the function and call it."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input list<Values.Value> inValuesValueLst;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inExp,inValuesValueLst,inMsg)
    local
      Values.Value newval;
      list<Env.Frame> env;
      Exp.Exp e;
      Absyn.Path funcpath;
      list<Exp.Exp> expl;
      Boolean builtin;
      list<Values.Value> vallst;
      Msg msg;
      String funcstr,str;
      Env.Cache cache;
   /* 
   External functions that are "known" should be evaluated without
	 compilation, e.g. all math functions 
	 */ 
    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,msg) 
      equation 
        (cache,newval) = cevalKnownExternalFuncs(cache,env, funcpath, vallst, msg);
      then
        (cache,newval);
        
        // This case prevents the constructor call of external objects of being evaluated
    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl, builtin = builtin)),vallst,msg)
      local Types.Type tp;
        Absyn.Path funcpath2;
        String s;
      equation
        cevalIsExternalObjectConstructor(cache,funcpath,env);
        then fail();

        /* Record constructors */
    case(cache,env,(e as Exp.CALL(path = funcpath,ty = Exp.COMPLEX(varLst=varLst))),vallst,msg)
      local list<Exp.Var> varLst; list<String> varNames;
       equation
      varNames = Util.listMap(varLst,Exp.varName);      
    then (cache,Values.RECORD(funcpath,vallst,varNames));

    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,msg)
      local
        Absyn.Path p2;
        String s;
        Env.Env env1;
        SCode.Class sc;
        list<SCode.Element> elementList;
        SCode.ClassDef cdef;
        list<DAE.Element> daeList;
      equation 
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        (cache,sc as SCode.CLASS(_,false,_,SCode.R_FUNCTION(),cdef ),env1) = 
        Lookup.lookupClass(cache,env,funcpath,true);
        (cache,env1,daeList) = Inst.implicitFunctionInstantiation(cache, env1,Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, sc, {}) ;
        newval = Cevalfunc.cevalUserFunc(env1,e,vallst,sc,daeList);
        //print("ret value(/s): "); print(Values.printValStr(newval));print("\n"); 
      then
        (cache,newval);

/*     This match-rule is commented out due to a new constant evaluation algorithm in 
     Cevalfunc.mo.
     We still keep this incase we need to have a generate backup in the future.
     2007-10-26 BZ
     2007-11-01 readded, external c-function needs this... 
     TODO: implement a check for external functionrecurisvly.
*/
    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,msg) 
      /**//* Call functions in non-interactive mode. FIXME: functions are always generated. 
      Put back the check and write another rule for the false case that generates the function 
      2007-10-20 partially fixed BZ*//**/
      local Integer libHandle, funcHandle;
      equation
 				failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        cache = CevalScript.cevalGenerateFunction(cache,env, funcpath);
        funcstr = ModUtil.pathString2(funcpath, "_");
        Debug.fprintln("dynload", "cevalCallFunction: about to execute " +& funcstr);
        libHandle = System.loadLibrary(funcstr);
        funcHandle = System.lookupFunction(libHandle, stringAppend("in_", funcstr));
        newval = System.executeFunction(funcHandle, vallst);
        System.freeFunction(funcHandle);
        System.freeLibrary(libHandle);
      then
        (cache,newval);

    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,msg) 
      local String error_Str;
      equation
        error_Str = Absyn.pathString(funcpath);
        //TODO: readd this when testsuite is okay.
        //Error.addMessage(Error.FAILED_TO_EVALUATE_FUNCTION, {error_Str});
        true = RTOpts.debugFlag("nogen");
        Debug.fprint("failtrace", "- codegeneration is turned off. switch \"nogen\" flag off\n");
      then
        fail();

    case (cache,env,e,_,_)
      equation
        Debug.fprint("failtrace", "- Ceval.cevalCallFunction failed: ");
        str = Exp.printExpStr(e);
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end cevalCallFunction;

protected function cevalIsExternalObjectConstructor
	input Env.Cache cache;
  input Absyn.Path funcpath;
  input Env.Env env;
protected
  Absyn.Path funcpath2;
  Types.Type tp;
algorithm
  "constructor" := Absyn.pathLastIdent(funcpath);
  funcpath2:=Absyn.stripLast(funcpath);
  (_,tp,_) := Lookup.lookupType(cache,env,funcpath2,true);
  Types.externalObjectConstructorType(tp);
end cevalIsExternalObjectConstructor;

protected function cevalKnownExternalFuncs "function: cevalKnownExternalFuncs
  Evaluates external functions that are known, e.g. all math functions."
	input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path funcpath;
  input list<Values.Value> vals;
  input Msg msg;
  output Env.Cache outCache;
  output Values.Value res;
  SCode.Class cdef;
  list<Env.Frame> env_1;
  String fid;
  Option<Absyn.ExternalDecl> extdecl;
  Option<String> id,lan;
  Option<Absyn.ComponentRef> out;
  list<Absyn.Exp> args;
algorithm 
  (outCache,cdef,env_1) := Lookup.lookupClass(inCache,env, funcpath, false);
  SCode.CLASS(fid,_,_,SCode.R_EXT_FUNCTION(),SCode.PARTS(_,_,_,_,_,extdecl)) := cdef;
  SOME(Absyn.EXTERNALDECL(id,lan,out,args,_)) := extdecl;
  isKnownExternalFunc(fid, id);
  res := cevalKnownExternalFuncs2(fid, id, vals, msg);
end cevalKnownExternalFuncs;

public function isKnownExternalFunc "function isKnownExternalFunc
  Succeds if external function name is 
  \"known\", i.e. no compilation required."
  input String inString;
  input Option<String> inStringOption;
algorithm 
  _:=
  matchcontinue (inString,inStringOption)
    case ("acos",SOME("acos")) then (); 
    case ("asin",SOME("asin")) then (); 
    case ("atan",SOME("atan")) then (); 
    case ("atan2",SOME("atan2")) then (); 
    case ("cos",SOME("cos")) then (); 
    case ("cosh",SOME("cosh")) then (); 
    case ("exp",SOME("exp")) then (); 
    case ("log",SOME("log")) then (); 
    case ("log10",SOME("log10")) then (); 
    case ("sin",SOME("sin")) then (); 
    case ("sinh",SOME("sinh")) then (); 
    case ("tan",SOME("tan")) then (); 
    case ("tanh",SOME("tanh")) then (); 
  end matchcontinue;
end isKnownExternalFunc;

protected function cevalKnownExternalFuncs2 "function: cevalKnownExternalFuncs2
  author: PA
  Helper function to cevalKnownExternalFuncs, does the evaluation."
  input SCode.Ident inIdent;
  input Option<Absyn.Ident> inAbsynIdentOption;
  input list<Values.Value> inValuesValueLst;
  input Msg inMsg;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inIdent,inAbsynIdentOption,inValuesValueLst,inMsg)
    local Real rv_1,rv,rv1,rv2,sv,cv;
    case ("acos",SOME("acos"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.acos(rv);
      then
        Values.REAL(rv_1);
    case ("asin",SOME("asin"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.asin(rv);
      then
        Values.REAL(rv_1);
    case ("atan",SOME("atan"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.atan(rv);
      then
        Values.REAL(rv_1);
    case ("atan2",SOME("atan2"),{Values.REAL(real = rv1),Values.REAL(real = rv2)},_)
      equation 
        rv_1 = System.atan2(rv1, rv2);
      then
        Values.REAL(rv_1);
    case ("cos",SOME("cos"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = realCos(rv);
      then
        Values.REAL(rv_1);
    case ("cosh",SOME("cosh"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.cosh(rv);
      then
        Values.REAL(rv_1);
    case ("exp",SOME("exp"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = realExp(rv);
      then
        Values.REAL(rv_1);
    case ("log",SOME("log"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.log(rv);
      then
        Values.REAL(rv_1);
    case ("log10",SOME("log10"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.log10(rv);
      then
        Values.REAL(rv_1);
    case ("sin",SOME("sin"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = realSin(rv);
      then
        Values.REAL(rv_1);
    case ("sinh",SOME("sinh"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.sinh(rv);
      then
        Values.REAL(rv_1);
    case ("tan",SOME("tan"),{Values.REAL(real = rv)},_)
      equation 
        sv = realSin(rv);
        cv = realCos(rv);
        rv_1 = sv/.cv;
      then
        Values.REAL(rv_1);
    case ("tanh",SOME("tanh"),{Values.REAL(real = rv)},_)
      equation 
        rv_1 = System.tanh(rv);
      then
        Values.REAL(rv_1);
  end matchcontinue;
end cevalKnownExternalFuncs2;

protected function cevalFunction "function: cevalFunction 
  For constant evaluation of functions returning a single value. 
  For now only record constructors."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Values.Value> inValuesValueLst;
  input Boolean inBoolean;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inPath,inValuesValueLst,inBoolean,inMsg)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env;
      list<String> compnames;
      Types.Mod mod;
      list<DAE.Element> dae;
      Values.Value value;
      Absyn.Path funcname;
      list<Values.Value> vallst;
      Boolean impl;
      Msg msg;
      String s;
      Env.Cache cache;
    case (cache,env,funcname,vallst,impl,msg) /* For record constructors */ 
      equation 
        (_,_) = Lookup.lookupRecordConstructorClass(env, funcname);
        (cache,c,env_1) = Lookup.lookupClass(cache,env, funcname, false);
        compnames = SCode.componentNames(c);
        mod = Types.valuesToMods(vallst, compnames);
        (cache,dae,_,_,_,_,_,_) = Inst.instClass(cache,env_1, mod, Prefix.NOPRE(), Connect.emptySet, c, {}, impl, 
          Inst.TOP_CALL(),ConnectionGraph.EMPTY);
        value = DAE.daeToRecordValue(funcname, dae, impl);
      then
        (cache,value);
    case (cache,env,funcname,vallst,(impl as true),msg)
      equation 
        Debug.fprint("failtrace", "- Ceval.cevalFunction: Don't know what to do. impl was always false before:");
        s = Absyn.pathString(funcname);
        Debug.fprintln("failtrace", s);
      then
        fail();
  end matchcontinue;
end cevalFunction;

protected function cevalMatrixElt "function: cevalMatrixElt
  Evaluates the expression of a matrix constructor, e.g. {1,2;3,4}"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst "matrix constr. elts";
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
algorithm 
  (outCache,outValuesValueLst) :=
  matchcontinue (inCache,inEnv,inTplExpExpBooleanLstLst,inBoolean,inMsg)
    local
      Values.Value v;
      list<Values.Value> vl;
      list<Env.Frame> env;
      list<tuple<Exp.Exp, Boolean>> expl;
      list<list<tuple<Exp.Exp, Boolean>>> expll;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
    case (cache,env,(expl :: expll),impl,msg)
      equation 
        (cache,v) = cevalMatrixEltRow(cache,env, expl, impl, msg);
        (cache,vl)= cevalMatrixElt(cache,env, expll, impl, msg);
      then
        (cache,v :: vl);
    case (cache,_,{},_,msg) then (cache,{}); 
  end matchcontinue;
end cevalMatrixElt;

protected function cevalMatrixEltRow "function: cevalMatrixEltRow
  Helper function to cevalMatrixElt"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<Exp.Exp, Boolean>> inTplExpExpBooleanLst;
  input Boolean inBoolean;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inTplExpExpBooleanLst,inBoolean,inMsg)
    local
      Values.Value res;
      list<Values.Value> resl;
      list<Env.Frame> env;
      Exp.Exp e;
      list<tuple<Exp.Exp, Boolean>> rest;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
    case (cache,env,((e,_) :: rest),impl,msg)
      equation 
        (cache,res,_) = ceval(cache,env, e, impl, NONE, NONE, msg);
        (cache,Values.ARRAY(resl)) = cevalMatrixEltRow(cache,env, rest, impl, msg);
      then
        (cache,Values.ARRAY((res :: resl)));
    case (cache,env,{},_,msg) then (cache,Values.ARRAY({})); 
  end matchcontinue;
end cevalMatrixEltRow;

protected function cevalBuiltinSize "function: cevalBuiltinSize
  Evaluates the size operator."
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input Exp.Exp inExp2;
  input Exp.Exp inExp3;
  input Boolean inBoolean4;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption5;
  input Msg inMsg6;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv1,inExp2,inExp3,inBoolean4,inInteractiveInteractiveSymbolTableOption5,inMsg6)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Binding bind,binding;
      list<Integer> sizelst;
      Integer dim,dim_1,v,dimv,len;
      Option<Interactive.InteractiveSymbolTable> st_1,st;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Boolean impl,bl;
      Msg msg;
      list<Inst.DimExp> dims;
      Values.Value v2;
      Exp.Type crtp;
      Exp.Exp exp,e;
      String cr_str,dim_str,size_str,expstr;
      list<Exp.Exp> es;
      Env.Cache cache;
      list<list<tuple<Exp.Exp, Boolean>>> mat;
    case (cache,_,Exp.MATRIX(scalar=mat),Exp.ICONST(1),_,st,_)
      equation
        v=listLength(mat);
      then 
        (cache,Values.INTEGER(v),st);   
    case (cache,_,Exp.MATRIX(scalar=mat),Exp.ICONST(2),_,st,_)
      equation
        v=listLength(Util.listFirst(mat));
      then 
        (cache,Values.INTEGER(v),st);   
    case (cache,env,Exp.MATRIX(scalar=mat),Exp.ICONST(dim),impl,st,msg)
      equation
        bl=(dim>2);
        true=bl;
        dim_1=dim-2;
        e=Util.tuple21(Util.listFirst(Util.listFirst(mat)));
        (cache,Values.INTEGER(v),st_1)=cevalBuiltinSize(cache,env,e,Exp.ICONST(dim_1),impl,st,msg);
      then 
        (cache,Values.INTEGER(v),st);   
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),dim,impl,st,msg)
      equation 
        (cache,attr,tp,bind,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions known, always ceval" ;
        true = Types.dimensionsKnown(tp);
        sizelst = Types.getDimensionSizes(tp);
        (cache,Values.INTEGER(dim),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        dim_1 = dim - 1;
        v = listNth(sizelst, dim_1);
      then
        (cache,Values.INTEGER(v),st_1);
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),dim,(impl as false),st,msg)
      local
        Exp.Type tp;
        Exp.Exp dim;
      equation 
        (cache,dims) = Inst.elabComponentArraydimFromEnv(cache,env, cr) "If component not instantiated yet, recursive definition.
	 For example,
	 Real x{:}(min=fill(1.0,size(x,1))) = {1.0} 
	 
	  When size(x,1) should be determined, x must be instantiated, but
	  that is not done yet. Solution: Examine Element to find modifier 
	  which will determine dimension size.
	" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        v2 = cevalBuiltinSize3(dims, dimv);
      then
        (cache,v2,st_1);
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),dim,(impl as true),st,msg)
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,bind,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions not known and impl=true, just silently fail" ;
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),dim,(impl as false),st,MSG())
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,bind,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions not known and impl=false, error message" ;

        false = Types.dimensionsKnown(tp);
        cr_str = Exp.printComponentRefStr(cr);
        dim_str = Exp.printExpStr(dim);
        size_str = Util.stringAppendList({"size(",cr_str,", ",dim_str,")"});
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {size_str});
      then
        fail();
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),dim,(impl as false),st,NO_MSG())
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,bind,_,_) = Lookup.lookupVar(cache,env, cr);
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,(impl as false),st,MSG())
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,Types.UNBOUND(),_,_) = Lookup.lookupVar(cache,env, cr) "For crefs without value binding" ;
        expstr = Exp.printExpStr(exp);
        Error.addMessage(Error.UNBOUND_VALUE, {expstr});
      then
        fail();
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,(impl as false),st,NO_MSG())
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,Types.UNBOUND(),_,_) = Lookup.lookupVar(cache,env, cr);
      then
        fail();
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,(impl as true),st,msg)
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,Types.UNBOUND(),_,_) = Lookup.lookupVar(cache,env, cr) "For crefs without value binding. If impl=true just silently fail" ;
      then
        fail();
               
		/* For crefs with value binding
		e.g. size(x,1) when Real x[:]=fill(0,1); */
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,impl,st,msg)
      local
        Values.Value v;
        Exp.Exp dim;
      equation 
        (cache,attr,tp,binding,_,_) = Lookup.lookupVar(cache,env, cr)  ;     
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        (cache,v) = cevalCrefBinding(cache,env, cr, binding, impl, msg);
        v2 = cevalBuiltinSize2(v, dimv);
      then
        (cache,v2,st_1);
    case (cache,env,Exp.ARRAY(array = (e :: es)),dim,impl,st,msg)
      local
        Exp.Type tp;
        Exp.Exp dim;
      equation 
        tp = Exp.typeof(e) "Special case for array expressions with nonconstant values For now: only arrays of scalar elements: TODO generalize to arbitrary
	   dimensions" ;
        true = Exp.typeBuiltin(tp);
        (cache,Values.INTEGER(1),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        len = listLength((e :: es));
      then
        (cache,Values.INTEGER(len),st_1);
        
       /* For expressions with value binding that can not determine type
		e.g. size(x,2) when Real x[:,:]=fill(0.0,0,2); empty array with second dimension == 2, no way of 
		knowing that from the value. Must investigate the expression itself.*/
    case (cache,env,exp,dim,impl,st,msg)
      local
        Values.Value v;
        Exp.Exp dim;
        list<Option<Integer>> adims;
        Integer i;
      equation 
        (cache,Values.ARRAY({}),st_1) = ceval(cache,env, exp, impl, st, NONE, msg) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        adims = Exp.arrayTypeDimensions(Exp.typeof(exp));
				SOME(i) = listNth(adims,dimv-1);
      then
        (cache,Values.INTEGER(i),st_1);
        
    case (cache,env,exp,dim,impl,st,msg)
      local
        Values.Value v;
        Exp.Exp dim;
      equation 
        (cache,v,st_1) = ceval(cache,env, exp, impl, st, NONE, msg) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        v2 = cevalBuiltinSize2(v, dimv);
      then
        (cache,v2,st_1);
    case (cache,env,exp,dim,impl,st,MSG())
      local Exp.Exp dim;
      equation 
        Print.printErrorBuf("#-- Ceval.cevalBuiltinSize failed: ");
        expstr = Exp.printExpStr(exp);
        Print.printErrorBuf(expstr);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize;

protected function cevalBuiltinSize2 "function: cevalBultinSize2
  Helper function to cevalBuiltinSize"
  input Values.Value inValue;
  input Integer inInteger;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inValue,inInteger)
    local
      Integer dim,ind_1,ind;
      list<Values.Value> lst;
      Values.Value l;
    case (Values.ARRAY(valueLst = lst),1)
      equation 
        dim = listLength(lst);
      then
        Values.INTEGER(dim);
    case (Values.ARRAY(valueLst = (l :: lst)),ind)
      local Values.Value dim;
      equation 
        ind_1 = ind - 1;
        dim = cevalBuiltinSize2(l, ind_1);
      then
        dim;
    case (_,_)
      equation 
        Debug.fprint("failtrace", "- Ceval.cevalBuiltinSize2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize2;

protected function cevalBuiltinSize3 "function: cevalBuiltinSize3
  author: PA
  Helper function to cevalBuiltinSize. 
  Used when recursive definition (attribute modifiers using size) is used."
  input list<Inst.DimExp> inInstDimExpLst;
  input Integer inInteger;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inInstDimExpLst,inInteger)
    local
      Integer n_1,v,n;
      list<Inst.DimExp> dims;
      Exp.Subscript sub;
      Option<Exp.Exp> eopt;
    case (dims,n)
      equation 
        n_1 = n - 1;
        Inst.DIMINT(v) = listNth(dims, n_1);
      then
        Values.INTEGER(v);
    case (dims,n)
      equation 
        n_1 = n - 1;
        Inst.DIMEXP(sub,eopt) = listNth(dims, n_1);
        print("- Ceval.cevalBuiltinSize_3 failed DIMEXP in dimesion\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize3;

protected function cevalBuiltinAbs "function: cevalBuiltinAbs
  author: LP
  Evaluates the abs operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer iv;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realAbs(rv);
      then
        (cache,Values.REAL(rv_1),st);
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.INTEGER(iv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        iv = intAbs(iv);
      then
        (cache,Values.INTEGER(iv),st);
  end matchcontinue;
end cevalBuiltinAbs;

protected function cevalBuiltinSign "function: cevalBuiltinSign
  author: PA
  Evaluates the sign operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      Boolean b1,b2,b3,impl;
      list<Env.Frame> env;
      Exp.Exp exp;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer iv,iv_1;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        b1 = (rv >. 0.0);
        b2 = (rv <. 0.0);
        b3 = (rv ==. 0.0);
        {(_,rv_1)} = Util.listSelect({(b1,1.0),(b2,-1.0),(b3,0.0)}, Util.tuple21);
      then
        (cache,Values.REAL(rv_1),st);
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.INTEGER(iv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        b1 = (iv > 0);
        b2 = (iv < 0);
        b3 = (iv == 0);
        {(_,iv_1)} = Util.listSelect({(b1,1),(b2,-1),(b3,0)}, Util.tuple21);
      then
        (cache,Values.INTEGER(iv_1),st);
  end matchcontinue;
end cevalBuiltinSign;

protected function cevalBuiltinExp "function: cevalBuiltinExp
  author: PA
  Evaluates the exp function"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realExp(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinExp;

protected function cevalBuiltinNoevent "function: cevalBuiltinNoevent
  author: PA
  Evaluates the noEvent operator. During constant evaluation events are not
  considered, so evaluation will simply remove the operator and evaluate the
  operand."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,v,_) = ceval(cache,env, exp, impl, st, NONE, msg);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinNoevent;

protected function cevalBuiltinCardinality "function: cevalBuiltinCardinality
  author: PA
  Evaluates the cardinality operator. The cardinality of a connector 
  instance is its number of (inside and outside) connections, i.e. 
  number of occurences in connect equations."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer cnt;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{Exp.CREF(componentRef = cr)},impl,st,msg)
      equation 
        (cache,cnt) = cevalCardinality(cache,env, cr);
      then
        (cache,Values.INTEGER(cnt),st);
  end matchcontinue;
end cevalBuiltinCardinality;

protected function cevalCardinality "function: cevalCardinality 
  author: PA
  counts the number of connect occurences of the 
  component ref in equations in current scope."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Integer outInteger;
algorithm 
  (outCache,outInteger) :=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      Env.Env env;
      list<Exp.ComponentRef> cr_lst,cr_lst2,cr_totlst,crs;
      Integer res;
      Exp.ComponentRef cr;
      Env.Cache cache;
      Absyn.Path path;
      Exp.ComponentRef prefix,currentPrefix;
      Absyn.Ident currentPrefixIdent;
    case (cache,env ,cr)
      equation 
        (env as (Env.FRAME(connectionSet = (crs,prefix))::_)) = Env.stripForLoopScope(env);
        cr_lst = Util.listSelect1(crs, cr, Exp.crefContainedIn);
        currentPrefixIdent= Exp.crefLastIdent(prefix);
        currentPrefix = Exp.CREF_IDENT(currentPrefixIdent,Exp.OTHER(),{});
 		    //	Select connect references that has cr as suffix and correct Prefix.
        cr_lst = Util.listSelect1R(cr_lst, currentPrefix, Exp.crefPrefixOf);
        
        // Select connect references that are identifiers (inside connectors)
        cr_lst2 = Util.listSelect(crs,Exp.crefIsIdent);
        cr_lst2 = Util.listSelect1(cr_lst2,cr,Exp.crefEqual);
        
        cr_totlst = Util.listUnionOnTrue(listAppend(cr_lst,cr_lst2),{},Exp.crefEqual);
        res = listLength(cr_totlst);
        
        /*print("inFrame :");print(Env.printEnvPathStr(env));print("\n");  
        print("cardinality(");print(Exp.printComponentRefStr(cr));print(")=");print(intString(res));
        print("\nicrefs =");print(Util.stringDelimitList(Util.listMap(crs,Exp.printComponentRefStr),","));
        print("\ncrefs =");print(Util.stringDelimitList(Util.listMap(cr_totlst,Exp.printComponentRefStr),","));
        print("\n");
       	print("prefix =");print(Exp.printComponentRefStr(prefix));print("\n");*/       	
       //	print("env:");print(Env.printEnvStr(env));
       	
      then
        (cache,res);
  end matchcontinue;
end cevalCardinality;

protected function cevalBuiltinCat "function: cevalBuiltinCat
  author: PA
  Evaluates the cat operator, for matrix concatenation."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer dim_int;
      list<Values.Value> mat_lst;
      Values.Value v;
      list<Env.Frame> env;
      Exp.Exp dim;
      list<Exp.Exp> matrices;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,(dim :: matrices),impl,st,msg)
      equation 
        (cache,Values.INTEGER(dim_int),_) = ceval(cache,env, dim, impl, st, NONE, msg);
        (cache,mat_lst) = cevalList(cache,env, matrices, impl, st, msg);
        v = cevalCat(mat_lst, dim_int);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinCat;

protected function cevalBuiltinIdentity "function: cevalBuiltinIdentity
  author: PA
  Evaluates the identity operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer dim_int,dim_int_1;
      list<Exp.Exp> expl;
      list<Values.Value> retExp;
      list<Env.Frame> env;
      Exp.Exp dim;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
     	Env.Cache cache;
    case (cache,env,{dim},impl,st,msg)
      equation 
        (cache,Values.INTEGER(dim_int),_) = ceval(cache,env, dim, impl, st, NONE, msg);
        dim_int_1 = dim_int + 1;
        expl = Util.listFill(Exp.ICONST(1), dim_int);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, Exp.ARRAY(Exp.INT(),true,expl), impl, st, dim_int_1, 
          1, {}, msg);
      then
        (cache,Values.ARRAY(retExp),st);
  end matchcontinue;
end cevalBuiltinIdentity;

protected function cevalBuiltinPromote "function: cevalBuiltinPromote
  author: PA
  Evaluates the internal promote operator, for promotion of arrays"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value arr_val,res;
      Integer dim_val;
      list<Env.Frame> env;
      Exp.Exp arr,dim;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{arr,dim},impl,st,msg)
      equation 
        (cache,arr_val,_) = ceval(cache,env, arr, impl, st, NONE, msg);
        (cache,Values.INTEGER(dim_val),_) = ceval(cache,env, dim, impl, st, NONE, msg);
        res = cevalBuiltinPromote2(arr_val, dim_val);
      then
        (cache,res,st);
  end matchcontinue;
end cevalBuiltinPromote;

protected function cevalBuiltinPromote2 "function: cevalBuiltinPromote2
  Helper function to cevalBuiltinPromote"
  input Values.Value inValue;
  input Integer inInteger;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inValue,inInteger)
    local
      Values.Value v;
      Integer n_1,n;
      list<Values.Value> vs_1,vs;
    case (v,0) then Values.ARRAY({v}); 
    case (Values.ARRAY(valueLst = vs),n)
      equation 
        n_1 = n - 1;
        vs_1 = Util.listMap1(vs, cevalBuiltinPromote2, n_1);
      then
        Values.ARRAY(vs_1);
  end matchcontinue;
end cevalBuiltinPromote2;


protected function cevalBuiltinString "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e)"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value arr_val,res;
      Integer dim_val;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i; Real r; Boolean b;
    case (cache,env,{exp,_,_,_},impl,st,msg)
      equation 
        (cache,Values.INTEGER(i),_) = ceval(cache,env, exp, impl, st, NONE, msg);
				str = intString(i);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,{exp,_,_,_},impl,st,msg)
      equation 
        (cache,Values.REAL(r),_) = ceval(cache,env, exp, impl, st, NONE, msg);
				str = realString(r);
      then
        (cache,Values.STRING(str),st); 
        
    case (cache,env,{exp,_,_,_},impl,st,msg)
      equation 
        (cache,Values.BOOL(b),_) = ceval(cache,env, exp, impl, st, NONE, msg);
				str = Util.boolString(b);
      then
        (cache,Values.STRING(str),st);                 
        
  end matchcontinue;
end cevalBuiltinString;

protected function cevalCat "function: cevalCat
  evaluates the cat operator given a list of 
  array values and a concatenation dimension."
  input list<Values.Value> v_lst;
  input Integer dim;
  output Values.Value outValue;
  list<Values.Value> v_lst_1;
algorithm 
  v_lst_1 := catDimension(v_lst, dim);
  outValue := Values.ARRAY(v_lst_1);
end cevalCat;

protected function catDimension "function: catDimension
  Helper function to cevalCat, concatenates a list 
  arrays as Values, given a dimension as integer."
  input list<Values.Value> inValuesValueLst;
  input Integer inInteger;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inValuesValueLst,inInteger)
    local
      list<list<Values.Value>> vlst_lst,v_lst_lst,v_lst_lst_1;
      list<Values.Value> v_lst_1,vlst,vlst2;
      Integer dim_1,len,dim;
    case (vlst,1) /* base case for first dimension */ 
      equation 
        vlst_lst = Util.listMap(vlst, Values.arrayValues);
        v_lst_1 = Util.listFlatten(vlst_lst);
      then
        v_lst_1;
    case (vlst,dim) /* higher dimensions */ 
      equation 
        v_lst_lst = Util.listMap(vlst, Values.arrayValues);
        dim_1 = dim - 1;
        v_lst_lst_1 = catDimension2(v_lst_lst, dim_1);
        v_lst_1 = Util.listMap(v_lst_lst_1, Values.makeArray);
        (Values.ARRAY(valueLst = vlst2) :: _) = v_lst_1;
        len = listLength(vlst2);
        v_lst_1 = cevalBuiltinTranspose2(v_lst_1, 1, len);
      then
        v_lst_1;
  end matchcontinue;
end catDimension;

protected function catDimension2 "function: catDimension2
  author: PA
  Helper function to catDimension."
  input list<list<Values.Value>> inValuesValueLstLst;
  input Integer inInteger;
  output list<list<Values.Value>> outValuesValueLstLst;
algorithm 
  outValuesValueLstLst:=
  matchcontinue (inValuesValueLstLst,inInteger)
    local
      list<Values.Value> l_lst,first_lst,first_lst_1;
      list<list<Values.Value>> first_lst_2,lst,rest,rest_1,res;
      Integer dim;
    case (lst,dim)
      equation 
        l_lst = Util.listFirst(lst);
        1 = listLength(l_lst);
        first_lst = Util.listMap(lst, Util.listFirst);
        first_lst_1 = catDimension(first_lst, dim);
        first_lst_2 = Util.listMap(first_lst_1, Util.listCreate);
      then
        first_lst_2;
    case (lst,dim)
      equation 
        first_lst = Util.listMap(lst, Util.listFirst);
        rest = Util.listMap(lst, Util.listRest);
        first_lst_1 = catDimension(first_lst, dim);
        rest_1 = catDimension2(rest, dim);
        res = Util.listThreadMap(rest_1, first_lst_1, Util.listCons);
      then
        res;
  end matchcontinue;
end catDimension2;

protected function cevalBuiltinFloor "function: cevalBuiltinFloor
  author: LP
  evaluates the floor operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      Integer iv;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
        iv=realInt(rv_1);
      then
        (cache,Values.INTEGER(iv),st);
  end matchcontinue;
end cevalBuiltinFloor;

protected function cevalBuiltinCeil "function cevalBuiltinCeil
  author: LP
  evaluates the ceil operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1,rvt,rv_2,realRet;
      Integer ri,ri_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        rvt = intReal(ri);
        (rvt ==. rv) = true;        
      then
        (cache,Values.REAL(rvt),st);
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        ri_1 = ri + 1;
        realRet = intReal(ri_1); 
      then
        (cache,Values.REAL(realRet),st);
  end matchcontinue;
end cevalBuiltinCeil;

protected function cevalBuiltinSqrt "function: cevalBuiltinSqrt
  author: LP
  Evaluates the builtin sqrt operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        (rv <. 0.0) = true;
        Error.addMessage(Error.NEGATIVE_SQRT, {});
      then
        fail();
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realSqrt(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinSqrt;

protected function cevalBuiltinSin "function cevalBuiltinSin
  author: LP
  Evaluates the builtin sin function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realSin(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinSin;

protected function cevalBuiltinSinh "function cevalBuiltinSinh
  author: PA
  Evaluates the builtin sinh function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = System.sinh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinSinh;

protected function cevalBuiltinCos "function cevalBuiltinCos
  author: LP
  Evaluates the builtin cos function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realCos(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinCos;

protected function cevalBuiltinCosh "function cevalBuiltinCosh
  author: PA
  Evaluates the builtin cosh function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = System.cosh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinCosh;

protected function cevalBuiltinLog "function cevalBuiltinLog
  author: LP
  Evaluates the builtin Log function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = System.log(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinLog;

protected function cevalBuiltinTan "function cevalBuiltinTan
  author: LP
  Evaluates the builtin tan function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,sv,cv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg) /* tan is not implemented in MetaModelica Compiler (MMC) for some strange reason. */ 
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        sv = realSin(rv);
        cv = realCos(rv);
        rv_1 = sv/.cv;
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinTan;

protected function cevalBuiltinTanh "function cevalBuiltinTanh
  author: PA
  Evaluates the builtin tanh function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,sv,cv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg) /* tanh is not implemented in MetaModelica Compiler (MMC) for some strange reason. */ 
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
         rv_1 = System.tanh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinTanh;

protected function cevalBuiltinAsin "function cevalBuiltinAsin
  author: PA
  Evaluates the builtin asin function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = System.asin(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinAsin;

protected function cevalBuiltinAcos "function cevalBuiltinAcos
  author: PA
  Evaluates the builtin acos function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = System.acos(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinAcos;

protected function cevalBuiltinAtan "function cevalBuiltinAtan
  author: PA
  Evaluates the builtin atan function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg) /* atan is not implemented in MetaModelica Compiler (MMC) for some strange reason. */ 
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = System.atan(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinAtan;

protected function cevalBuiltinDiv "function cevalBuiltinDiv
  author: LP
  Evaluates the builtin div operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rv_1,rv_2;
      Integer ri,ri_1,ri1,ri2;
      list<Env.Frame> env;
      Exp.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str,lh_str,rh_str;
      Env.Cache cache;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv_1 = rv1/.rv2;
        ri = realInt(rv_1);
        rv_2 = intReal(ri);
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv_1 = rv1/.rv2;
        ri_1 = realInt(rv_1);
        rv_2 = intReal(ri_1);
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
        rv_1 = rv1/.rv2;
        ri_1 = realInt(rv_1);
        rv_2 = intReal(ri_1);
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        ri_1 = ri1/ri2;
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,MSG())
      equation 
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, MSG());
        (rv2 ==. 0.0) = true;
        exp1_str = Exp.printExpStr(exp1);
        exp2_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.DIVISION_BY_ZERO, {exp1_str,exp2_str});
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,MSG())
      equation 
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, MSG());
        (ri2 == 0) = true;
        lh_str = Exp.printExpStr(exp1);
        rh_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str});
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiv;

protected function cevalBuiltinMod "function cevalBuiltinMod
  author: LP
  Evaluates the builtin mod operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rva,rvb,rvc,rvd;
      list<Env.Frame> env;
      Exp.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer ri,ri1,ri2,ri_1;
      String lhs_str,rhs_str;
      Env.Cache cache;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv1 = intReal(ri1);
        rv2 = intReal(ri2);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
        ri_1 = realInt(rvd);
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,MSG())
      equation 
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, MSG());
        (rv2 ==. 0.0) = true;
        lhs_str = Exp.printExpStr(exp1);
        rhs_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str});
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,MSG())
      equation 
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, MSG());
        (ri2 == 0) = true;
        lhs_str = Exp.printExpStr(exp1);
        rhs_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str});
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinMod;

protected function cevalBuiltinMax "function cevalBuiltinMax
  author: LP
  Evaluates the builtin max function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v,v_1;
      list<Env.Frame> env;
      Exp.Exp arr,s1,s2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer i1,i2,i;
      Real r1,r2,r;
      Env.Cache cache;
    case (cache,env,{arr},impl,st,msg)
      equation 
        (cache,v,_) = ceval(cache,env, arr, impl, st, NONE, msg);
        (v_1) = cevalBuiltinMax2(v);
      then
        (cache,v_1,st);
    case (cache,env,{s1,s2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(i1),_) = ceval(cache,env, s1, impl, st, NONE, msg);
        (cache,Values.INTEGER(i2),_) = ceval(cache,env, s2, impl, st, NONE, msg);
        i = intMax(i1, i2);
      then
        (cache,Values.INTEGER(i),st);
    case (cache,env,{s1,s2},impl,st,msg)
      equation 
        (cache,Values.REAL(r1),_) = ceval(cache,env, s1, impl, st, NONE, msg);
        (cache,Values.REAL(r2),_) = ceval(cache,env, s2, impl, st, NONE, msg);
        r = realMax(r1, r2);
      then
        (cache,Values.REAL(r),st);
  end matchcontinue;
end cevalBuiltinMax;

protected function cevalBuiltinMax2 "function: cevalBuiltinMax2
  Helper function to cevalBuiltinMax."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inValue)
    local
      Integer i1,i2,res,i;
      Values.Value v1,v,vl;
      list<Values.Value> vls;
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation 
        (Values.INTEGER(i1)) = cevalBuiltinMax2(v1);
        (Values.INTEGER(i2)) = cevalBuiltinMax2(Values.ARRAY(vls));
        res = intMax(i1, i2);
      then
        Values.INTEGER(res);
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      local Real i1,i2,res;
      equation 
        (Values.REAL(i1)) = cevalBuiltinMax2(v1);
        (Values.REAL(i2)) = cevalBuiltinMax2(Values.ARRAY(vls));
        res = realMax(i1, i2);
      then
        Values.REAL(res);
    case (Values.ARRAY(valueLst = {vl}))
      equation 
        (v) = cevalBuiltinMax2(vl);
      then
        v;
    case (Values.INTEGER(integer = i)) then Values.INTEGER(i); 
    case (Values.REAL(real = i))
      local Real i;
      then
        Values.REAL(i);
    case (_)
      equation 
        //print("- Ceval.cevalBuiltinMax2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinMax2;

protected function cevalBuiltinMin "function: cevalBuiltinMin
  author: PA
  Constant evaluation of builtin min function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v,v_1;
      list<Env.Frame> env;
      Exp.Exp arr,s1,s2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer i1,i2,i;
      Real r1,r2,r;
      Env.Cache cache;
    case (cache,env,{arr},impl,st,msg)
      equation 
        (cache,v,_) = ceval(cache,env, arr, impl, st, NONE, msg);
        (v_1) = cevalBuiltinMin2(v);
      then
        (cache,v_1,st);
    case (cache,env,{s1,s2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(i1),_) = ceval(cache,env, s1, impl, st, NONE, msg);
        (cache,Values.INTEGER(i2),_) = ceval(cache,env, s2, impl, st, NONE, msg);
        i = intMin(i1, i2);
      then
        (cache,Values.INTEGER(i),st);
    case (cache,env,{s1,s2},impl,st,msg)
      equation 
        (cache,Values.REAL(r1),_) = ceval(cache,env, s1, impl, st, NONE, msg);
        (cache,Values.REAL(r2),_) = ceval(cache,env, s2, impl, st, NONE, msg);
        r = realMin(r1, r2);
      then
        (cache,Values.REAL(r),st);
  end matchcontinue;
end cevalBuiltinMin;

protected function cevalBuiltinMin2 "function: cevalBuiltinMin2
  Helper function to cevalBuiltinMin."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inValue)
    local
      Integer i1,i2,res,i;
      Values.Value v1,v,vl;
      list<Values.Value> vls;
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation 
        (Values.INTEGER(i1)) = cevalBuiltinMin2(v1);
        (Values.INTEGER(i2)) = cevalBuiltinMin2(Values.ARRAY(vls));
        res = intMin(i1, i2);
      then
        Values.INTEGER(res);
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      local Real i1,i2,res;
      equation 
        (Values.REAL(i1)) = cevalBuiltinMin2(v1);
        (Values.REAL(i2)) = cevalBuiltinMin2(Values.ARRAY(vls));
        res = realMin(i1, i2);
      then
        Values.REAL(res);
    case (Values.ARRAY(valueLst = {vl}))
      equation 
        (v) = cevalBuiltinMin2(vl);
      then
        v;
    case (Values.INTEGER(integer = i)) then Values.INTEGER(i); 
    case (Values.REAL(real = i))
      local Real i;
      then
        Values.REAL(i);
  end matchcontinue;
end cevalBuiltinMin2;

protected function cevalBuiltinIsRoot "function cevalBuiltinCos
  author: HN
  Evaluates the builtin Connections.isRoot function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        // TODO We have to get the list of roots here somehow from Inst.instProgram 
      then
        (cache,Values.BOOL(false),st);
  end matchcontinue;
end cevalBuiltinIsRoot;

protected function cevalBuiltinDifferentiate "function cevalBuiltinDifferentiate
  author: LP
  This function differentiates an equation: x^2 + x => 2x + 1"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Exp.Exp differentiated_exp,differentiated_exp_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp1,Exp.CREF(componentRef = cr)},impl,st,msg)
      equation 
        differentiated_exp = Derive.differentiateExpCont(exp1, cr);
        differentiated_exp_1 = Exp.simplify(differentiated_exp);
        /*
         this is wrong... this should be used instead but unelabExp must be able to unelaborate a complete exp 
         now it doesn't so the expression is returned as string Exp.unelabExp(differentiated_exp') => absyn_exp
        */        
        ret_val = Exp.printExpStr(differentiated_exp_1);
      then
        (cache,Values.STRING(ret_val),st);
    case (_,_,_,_,st,msg) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */ 
      equation 
        print("#- Differentiation failed. Celab.cevalBuiltinDifferentiate failed.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDifferentiate;

protected function cevalBuiltinSimplify "function cevalBuiltinSimplify
  author: LP
  this function simplifies an equation: x^2 + x => 2x + 1"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Exp.Exp exp1_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp1},impl,st,msg)
      equation 
        exp1_1 = Exp.simplify(exp1);
        ret_val = Exp.printExpStr(exp1_1) "this should be used instead but unelab_exp must be able to unelaborate a complete exp Exp.unelab_exp(simplifyd_exp\') => absyn_exp" ;
      then
        (cache,Values.STRING(ret_val),st);
    case (_,_,_,_,st,MSG()) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */ 
      equation 
        print("#- Simplification failed. Ceval.cevalBuildinSimplify failed.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSimplify;

protected function cevalBuiltinRem "function cevalBuiltinRem
  author: LP
  Evaluates the builtin rem operator"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rva,rva_1,rvb,rvd;
      Integer rvai,ri,ri1,ri2,ri_1;
      list<Env.Frame> env;
      Exp.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str;
      Env.Cache cache;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation 
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv1 = intReal(ri1);
        rv2 = intReal(ri2);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
        ri_1 = realInt(rvd);
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,MSG())
      equation 
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, MSG());
        (rv2 ==. 0.0) = true;
        exp1_str = Exp.printExpStr(exp1);
        exp2_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str});
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,MSG())
      equation 
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, MSG());
        (ri2 == 0) = true;
        exp1_str = Exp.printExpStr(exp1);
        exp2_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str});
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinRem;

protected function cevalBuiltinInteger "function cevalBuiltinInteger
  author: LP
  Evaluates the builtin integer operator"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv;
      Integer ri;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        ri = realInt(rv);
      then
        (cache,Values.INTEGER(ri),st);
  end matchcontinue;
end cevalBuiltinInteger;

protected function cevalBuiltinDiagonal "function cevalBuiltinDiagonal
  This function generates a matrix{n,n} (A) of the vector {a,b,...,n}
  where the diagonal of A is the vector {a,b,...,n}
  ie A{1,1} == a, A{2,2} == b ..."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Values.Value> rv2,retExp;
      Integer dimension,correctDimension;
      String dimensionString;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.ARRAY(rv2),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        dimension = listLength(rv2);
        correctDimension = dimension + 1;
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, exp, impl, st, correctDimension, 1, {}, msg);
        dimensionString = intString(dimension);
        Debug.fcall("ceval", Print.printBuf, "== dimensionString ");
        Debug.fcall("ceval", Print.printBuf, dimensionString);
        Debug.fcall("ceval", Print.printBuf, "\n");
      then
        (cache,Values.ARRAY(retExp),st);
    case (_,_,_,_,_,MSG())
      equation 
        Print.printErrorBuf("#- Error, could not evaulate diagonal. Ceval.cevalBuiltinDiagonal failed.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal;

protected function cevalBuiltinDiagonal2 "function: cevalBuiltinDiagonal2
   This is a help function that is calling itself recursively to 
   generate the a nxn matrix with some special diagonal elements. 
   See cevalBuiltinDiagonal."
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input Exp.Exp inExp2;
  input Boolean inBoolean3;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Integer inInteger5 "matrix dimension";
  input Integer inInteger6 "row";
  input list<Values.Value> inValuesValueLst7;
  input Msg inMsg8;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
algorithm 
  (outCache,outValuesValueLst) :=
  matchcontinue (inCache,inEnv1,inExp2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inInteger5,inInteger6,inValuesValueLst7,inMsg8)
    local
      Real rv2;
      Integer correctDim,correctPlace,newRow,matrixDimension,row;
      list<Values.Value> zeroList,listWithElement,retExp,appendedList,listIN,list_;
      list<Env.Frame> env;
      Exp.Exp s1,s2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String RowString,matrixDimensionString;
      Env.Cache cache;
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg)
      equation 
        s2 = Exp.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Exp.ASUB(s1,{s2}), impl, st, NONE, msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, 
          {Values.ARRAY(listWithElement)}, msg);
      then
        (cache,retExp);
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation 
        s2 = Exp.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Exp.ASUB(s1,{s2}), impl, st, NONE, msg);

        failure(equality(matrixDimension = row));
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        appendedList = listAppend(listIN, {Values.ARRAY(listWithElement)});
        (cache,retExp)= cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, appendedList, 
          msg);
      then
        (cache,retExp);
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg)
      local Integer rv2;
      equation 
        s2 = Exp.ICONST(row);
        (cache,Values.INTEGER(rv2),_) = ceval(cache,env, Exp.ASUB(s1,{s2}), impl, st, NONE, msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.INTEGER(rv2), correctPlace, zeroList);
        newRow = row + 1;
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, 
          {Values.ARRAY(listWithElement)}, msg);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      local Integer rv2;
      equation 
        s2 = Exp.ICONST(row);
        (cache,Values.INTEGER(rv2),_) = ceval(cache,env, Exp.ASUB(s1,{s2}), impl, st, NONE, msg);
        failure(equality(matrixDimension = row));
        
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.INTEGER(rv2), correctPlace, zeroList);
        newRow = row + 1;
        appendedList = listAppend(listIN, {Values.ARRAY(listWithElement)});
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, appendedList, 
          msg);
      then
        (cache,retExp);
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation 
        equality(matrixDimension = row);
      then
        (cache,listIN);
    case (_,_,_,_,_,matrixDimension,row,list_,MSG())
      equation 
        print("#- Ceval.cevalBuiltinDiagonal2: Couldn't elaborate Ceval.cevalBuiltinDiagonal2()\n");
        RowString = intString(row);
        matrixDimensionString = intString(matrixDimension);
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal2;

protected function cevalBuiltinTranspose "function cevalBuiltinTranspose
  This function transposes the two first dimension of an array A."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Values.Value> vlst,vlst2,vlst_1;
      Integer dim1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.ARRAY(vlst),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        (Values.ARRAY(valueLst = vlst2) :: _) = vlst;
        dim1 = listLength(vlst2);
        vlst_1 = cevalBuiltinTranspose2(vlst, 1, dim1);
      then
        (cache,Values.ARRAY(vlst_1),st);
    case (_,_,_,_,_,MSG())
      equation 
        Print.printErrorBuf("#- Error, could not evaluate transpose. Celab.cevalBuildinTranspose failed.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinTranspose;

protected function cevalBuiltinTranspose2 "function: cevalBuiltinTranspose2
  author: PA
  Helper function to cevalBuiltinTranspose"
  input list<Values.Value> inValuesValueLst1;
  input Integer inInteger2 "index";
  input Integer inInteger3 "dimension";
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inValuesValueLst1,inInteger2,inInteger3)
    local
      list<Values.Value> transposed_row,rest,vlst;
      Integer indx_1,indx,dim1;
    case (vlst,indx,dim1)
      equation 
        (indx <= dim1) = true;
        transposed_row = Util.listMap1(vlst, Values.nthArrayelt, indx);
        indx_1 = indx + 1;
        rest = cevalBuiltinTranspose2(vlst, indx_1, dim1);
      then
        (Values.ARRAY(transposed_row) :: rest);
    case (_,_,_) then {}; 
  end matchcontinue;
end cevalBuiltinTranspose2;

protected function cevalBuiltinSizeMatrix "function: cevalBuiltinSizeMatrix
  Helper function for cevalBuiltinSize, for size(A) where A is a matrix."
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Exp.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      Types.Binding bind;
      list<Integer> sizelst;
      Values.Value v;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st,st_1;
      Msg msg;
      Exp.Exp exp;
      Env.Cache cache;
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),impl,st,msg)
      equation 
        (cache,attr,tp,bind,_,_) = Lookup.lookupVar(cache,env, cr);
        sizelst = Types.getDimensionSizes(tp);
        v = Values.intlistToValue(sizelst);
      then
        (cache,v,st);
    case (cache,env,exp,impl,st,msg)
      equation 
        (cache,v,st_1) = ceval(cache,env, exp, impl, st, NONE, msg);
        tp = Types.typeOfValue(v);
        sizelst = Types.getDimensionSizes(tp);
        v = Values.intlistToValue(sizelst);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinSizeMatrix;

protected function cevalRelation "function: cevalRelation
  Performs the arithmetic relation check and gives a boolean result."
  input Values.Value inValue1;
  input Exp.Operator inOperator2;
  input Values.Value inValue3;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inValue1,inOperator2,inValue3)
    local
      Values.Value v,v1,v2;
      Exp.Type t;
      Boolean b,nb1,nb2,ba,bb,b1,b2;
      Integer i1,i2;
      String s1,s2;
    case (v1,Exp.GREATER(ty = t),v2)
      equation 
        v = cevalRelation(v2, Exp.LESS(t), v1);
      then
        v;
        
                
    case (Values.STRING(string = s1),Exp.LESS(ty = Exp.STRING()),Values.STRING(string = s2))  /* Strings */
      equation 
        i1 = System.strcmp(s1,s2);
        b = (i1 < 0); 
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),Exp.LESSEQ(ty = Exp.STRING()),Values.STRING(string = s2))
      equation 
        i1 = System.strcmp(s1,s2);
        b = (i1 <= 0); 
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),Exp.GREATEREQ(ty = Exp.STRING()),Values.STRING(string = s2))
      equation 
        i1 = System.strcmp(s1,s2);
        b = (i1 >= 0); 
      then
        Values.BOOL(b);

    case (Values.STRING(string = s1),Exp.EQUAL(ty = Exp.STRING()),Values.STRING(string = s2))
      equation 
        i1 = System.strcmp(s1,s2);
        b = (i1 == 0); 
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),Exp.NEQUAL(ty = Exp.STRING()),Values.STRING(string = s2))
      equation 
        i1 = System.strcmp(s1,s2);
        b = (i1 <> 0); 
      then
        Values.BOOL(b);
        
        
    case (Values.INTEGER(integer = i1),Exp.LESS(ty = Exp.INT()),Values.INTEGER(integer = i2)) /* Integers */ 
      equation 
        b = (i1 < i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.LESSEQ(ty = Exp.INT()),Values.INTEGER(integer = i2))
      equation 
        b = (i1 <= i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.GREATEREQ(ty = Exp.INT()),Values.INTEGER(integer = i2))
      equation 
        b = (i1 >= i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.EQUAL(ty = Exp.INT()),Values.INTEGER(integer = i2))
      equation 
        b = (i1 == i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.NEQUAL(ty = Exp.INT()),Values.INTEGER(integer = i2))
      equation 
        b = (i1 <> i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.LESS(ty = Exp.REAL()),Values.REAL(real = i2)) /* Reals */ 
      local Real i1,i2;
      equation 
        b = (i1 <. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.LESSEQ(ty = Exp.REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation 
        b = (i1 <=. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.GREATEREQ(ty = Exp.REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation 
        b = (i1 >=. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.EQUAL(ty = Exp.REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation 
        b = (i1 ==. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.NEQUAL(ty = Exp.REAL()),Values.REAL(real = i2)) /* Booleans */ 
      local Real i1,i2;
      equation 
        b = (i1 <>. i2);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = b1),Exp.NEQUAL(ty = Exp.BOOL()),Values.BOOL(boolean = b2)) /* Booleans */ 
      equation 
        nb1 = boolNot(b1) "b1 != b2  == (b1 and not b2) or (not b1 and b2)" ;
        nb2 = boolNot(b2);
        ba = boolAnd(b1, nb2);
        bb = boolAnd(nb1, b2);
        b = boolOr(ba, bb);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = b1),Exp.EQUAL(ty = Exp.BOOL()),Values.BOOL(boolean = b2))
      equation 
        nb1 = boolNot(b1) "b1 == b2  ==> b1 and b2 or (not b1 and not b2)" ;
        nb2 = boolNot(b2);
        ba = boolAnd(b1, b2);
        bb = boolAnd(nb1, nb2);
        b = boolOr(ba, bb);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = false),Exp.LESS(ty = Exp.BOOL()),Values.BOOL(boolean = true)) then Values.BOOL(true); 
    case (Values.BOOL(boolean = _),Exp.LESS(ty = Exp.BOOL()),Values.BOOL(boolean = _)) then Values.BOOL(false); 
    case (Values.STRING(string = s1),Exp.EQUAL(ty = Exp.STRING()),Values.STRING(string = s2))
      local
        String s1,s2;
      equation
        b = (s1 ==& s2);
      then
        Values.BOOL(b);

    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "- Ceval.cevalRelation failed\n");
        //print("- Ceval.cevalRelation failed\n");
      then
        fail();
  end matchcontinue;
end cevalRelation;

protected function cevalRange "function: cevalRange
  This function evaluates a range expression. 
  It only handles integers."
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inInteger1,inInteger2,inInteger3)
    local
      Integer start,stop,j,d,k,step;
      Boolean b1,b2,c1,b3,b4,c2;
      list<Values.Value> res;
    case (start,_,stop)
      equation 
        (start == stop) = true "e.g. 1:1 => {1}" ;
      then
        {Values.INTEGER(start)};
    case (j,d,k)
      equation 
        b1 = (j > k) "if d > 0 and j>k or if d < 0 and j<k" ;
        b2 = (d > 0);
        c1 = boolAnd(b1, b2);
        b3 = (j < k);
        b4 = (d < 0);
        c2 = boolAnd(b3, b4);
        true = boolOr(c1, c1);
      then
        {};
    case (start,step,stop)
      equation 
        res = cevalRange2(start, step, stop);
      then
        res;
  end matchcontinue;
end cevalRange;

protected function cevalRange2 "function: cevalRange2
  Helper function to cevalRange."
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inInteger1,inInteger2,inInteger3)
    local
      Integer start,stop,next,step;
      list<Values.Value> l;
    case (start,_,stop)
      equation 
        (start > stop) = true;
      then
        {};
    case (start,step,stop)
      equation 
        (start > stop) = false;
        next = start + step "redundant" ;
        l = cevalRange2(next, step, stop);
      then
        (Values.INTEGER(start) :: l);
  end matchcontinue;
end cevalRange2;

protected function cevalRangeReal "function: cevalRangeReal
  This function evaluates a range expression.  
  It only handles reals."
  input Real inReal1;
  input Real inReal2;
  input Real inReal3;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inReal1,inReal2,inReal3)
    local
      Real start,stop,j,d,k;
      Boolean b1,b2,c1,b3,b4,c2;
      list<Values.Value> res;
    case (start,_,stop)
      equation 
        (start ==. stop) = true "e.g. 1:1 => {1}" ;
      then
        {Values.REAL(start)};
    case (j,d,k)
      equation 
        b1 = (j >. k) "if d > 0 and j>k or if d < 0 and j<k" ;
        b2 = (d >. 0.0);
        c1 = boolAnd(b1, b2);
        b3 = (j <. k);
        b4 = (d <. 0.0);
        c2 = boolAnd(b3, b4);
        true = boolOr(c1, c1);
      then
        {};
    case (j,d,k)
      equation 
        res = cevalRangeReal2(j, d, k);
      then
        res;
  end matchcontinue;
end cevalRangeReal;

protected function cevalRangeReal2 "function: cevalRangeReal2
  Helper function to cevalRangeReal."
  input Real inReal1;
  input Real inReal2;
  input Real inReal3;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inReal1,inReal2,inReal3)
    local
      Real start,stop,next,step;
      list<Values.Value> l;
    case (start,_,stop)
      equation 
        (start >. stop) = true;
      then
        {};
    case (start,step,stop)
      equation 
        (start >. stop) = false;
        next = start +. step "redundant" ;
        l = cevalRangeReal2(next, step, stop);
      then
        (Values.REAL(start) :: l);
  end matchcontinue;
end cevalRangeReal2;

public function cevalList "function: cevalList
  This function does constant 
  evaluation on a list of expressions."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
algorithm 
  (outCache,outValuesValueLst):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      Values.Value v;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      list<Values.Value> vs;
      list<Exp.Exp> exps;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,v,_) = ceval(cache,env, exp, impl, st, NONE, msg);
      then
        (cache,{v});
    case (cache,env,(exp :: exps),impl,st,msg)
      equation 
        (cache,v,_) = ceval(cache,env, exp, impl, st, NONE, msg);
        (cache,vs) = cevalList(cache,env, exps, impl, st, msg);
      then
        (cache,v :: vs);
  end matchcontinue;
end cevalList;

protected function cevalCref "function: cevalCref
  Evaluates ComponentRef, i.e. variables, by 
  looking up variables in the environment."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,inMsg)
    local
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Binding binding;
      Values.Value v;
      list<Env.Frame> env;
      Exp.ComponentRef c;
      Boolean impl;
      Msg msg;
      String scope_str,str;
      Env.Cache cache;
    
    /* Search in env for binding, special rule for enumerations, the cr does not have a value since it -is- a value. */
    case (cache,env,c,impl,msg)  
      equation 
        (cache,attr,ty as (Types.T_ENUM(),_),binding,_,_) = Lookup.lookupVar(cache,env, c);
      then
        (cache,Values.ENUM(c));  
    
    /* Search in env for binding. */
    case (cache,env,c,impl,msg)  
      equation 
        (cache,attr,ty,binding,_,_) = Lookup.lookupVar(cache,env, c);
        false = crefEqualValue(c,binding);        
        (cache,v) = cevalCrefBinding(cache,env, c, binding, impl, msg);
      then
        (cache,v);
        
    case (cache,env,c,(impl as false),MSG())
      equation 
        failure((_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
        scope_str = Env.printEnvPathStr(env);
        str = Exp.printComponentRefStr(c);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {str,scope_str});
      then
        fail();
    case (cache,env,c,(impl as false),NO_MSG())
      equation 
        failure((_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
      then
        fail();
    case (cache,env,c,(impl as false),MSG()) /* No binding found. */ 
      equation 
        str = Exp.printComponentRefStr(c);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.NO_CONSTANT_BINDING, {str,scope_str});
      then
        fail();
  end matchcontinue;
end cevalCref;

public function cevalCrefBinding "function: cevalCrefBinding
  Helper function to cevalCref. 
  Evaluates variables by evaluating their bindings."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input Types.Binding inBinding;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBinding,inBoolean,inMsg)
    local
      Exp.ComponentRef cr_1,cr,e1;
      list<Exp.Subscript> subsc;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      list<Integer> sizelst;
      Values.Value res,v,e_val;
      list<Env.Frame> env;
      Boolean impl;
      Msg msg;
      String rfn,iter,id,expstr,s1,s2,str;
      Exp.Exp elexp,iterexp,exp;
      Env.Cache cache;
    case (cache,env,cr,Types.VALBOUND(valBound = v),impl,msg) /* Exp.CREF_IDENT(id,subsc) */ 
      equation 
        Debug.fprint("tcvt", "+++++++ Ceval.cevalCrefBinding Types.VALBOUND\n");
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);
    case (cache,env,cr,Types.UNBOUND(),(impl as false),MSG())
      local 
        Exp.ComponentRef cr;
      equation 
        /*Print.printBuf("- Ceval.cevalCrefBinding failed (UNBOUND)\n");*/
       //Debug.fprint("ceval", "#- Ceval.cevalCrefBinding failed (UNBOUND)");
/*       print("Ceval.cevalCrefBinding failed (UNBOUND) *********\n");
       print(Exp.printComponentRefStr(cr));
       print("\n");
*/      then
        fail();
    case (cache,env,_,Types.UNBOUND(),(impl as true),MSG())
      equation 
        Debug.fprint("ceval", "#- Ceval.cevalCrefBinding: Ignoring unbound when implicit");
      then
        fail();

        /* REDUCTION bindings */ 
    case (cache,env,Exp.CREF_IDENT(ident = id,subscriptLst = subsc),Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,MSG()) 
      equation 
        Exp.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        equality(rfn = "array");
        Debug.fprintln("ceval", "#- Ceval.cevalCrefBinding: Array evaluation");
      then
        fail();

        /* REDUCTION bindings Exp.CREF_IDENT(id,subsc) */ 
    case (cache,env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,msg) 
      equation 
        Exp.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        failure(equality(rfn = "array"));
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache,env, exp, impl, NONE, NONE, msg);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);
        
        /* arbitrary expressions, C_VAR, value exists. Exp.CREF_IDENT(id,subsc) */ 
    case (cache,env,cr,Types.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = Types.C_VAR()),impl,msg) 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, e_val, sizelst, impl, msg);
      then
        (cache,res);

        /* arbitrary expressions, C_PARAM, value exists. Exp.CREF_IDENT(id,subsc) */ 
    case (cache,env,cr,Types.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = Types.C_PARAM()),impl,msg) 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res)= cevalSubscriptValue(cache,env, subsc, e_val, sizelst, impl, msg);
      then
        (cache,res);

        /* arbitrary expressions. When binding has optional value. Exp.CREF_IDENT(id,subsc) */
    case (cache,env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,msg)  
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache,env, exp, impl, NONE, NONE, msg);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);

        /* arbitrary expressions. When binding has optional value. Exp.CREF_IDENT(id,subsc) */ 
    case (cache,env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_PARAM()),impl,msg) 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache,env, exp, impl, NONE, NONE, msg);
        (cache,res)= cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);
    case (cache,env,_,Types.EQBOUND(exp = exp,constant_ = Types.C_VAR()),impl,MSG())
      equation 
        Debug.fprint("ceval", "#- Ceval.cevalCrefBinding failed (nonconstant EQBOUND(");
        expstr = Exp.printExpStr(exp);
        Debug.fprint("ceval", expstr);
        Debug.fprintln("ceval", "))");
      then
        fail();
    case (cache,_,e1,Types.EQBOUND(exp = exp),_,_)
      equation 
        /* FAILTRACE REMOVE
        s1 = Exp.printComponentRefStr(e1);
        s2 = Exp.printExpStr(exp);
        str = Util.stringAppendList({"- Ceval.cevalCrefBinding: ",s1," = ",s2," failed\n"});
        Debug.fprint("failtrace", str);
        */
      then
        fail();
  end matchcontinue;
end cevalCrefBinding;

protected function cevalSubscriptValue "function: cevalSubscriptValue
  Helper function to cevalCrefBinding. It applies 
  subscripts to array values to extract array elements."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Subscript> inExpSubscriptLst "subscripts to extract";
  input Values.Value inValue;
  input list<Integer> inIntegerLst "dimension sizes";
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inExpSubscriptLst,inValue,inIntegerLst,inBoolean,inMsg)
    local
      Integer n,n_1,dim;
      Values.Value subval,res,v;
      list<Env.Frame> env;
      Exp.Exp exp;
      list<Exp.Subscript> subs;
      list<Values.Value> lst;
      list<Integer> dims;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
    case (cache,env,(Exp.INDEX(exp = exp) :: subs),Values.ARRAY(valueLst = lst),(dim :: dims),impl,msg)
      equation 
        (cache,Values.INTEGER(n),_) = ceval(cache,env, exp, impl, NONE, SOME(dim), msg);
        n_1 = n - 1;
        subval = listNth(lst, n_1);
        (cache,res) = cevalSubscriptValue(cache,env, subs, subval, dims, impl, msg);
      then
        (cache,res);
    case (cache,env,{},v,_,_,_) then (cache,v); 
    case (_,_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "- Ceval.cevalSubscriptValue failed\n");
      then
        fail();
  end matchcontinue;
end cevalSubscriptValue;

public function cevalSubscripts "function: cevalSubscripts
  This function relates a list of subscripts to their canonical
  forms, which is when all expressions are evaluated to constant
  values. For instance
  the subscript list {1,p,q} (as in x[1,p,q]) where p and q have constant values 2,3 respectively will become
  {1,2,3} (resulting in x[1,2,3]).
  "
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Exp.Subscript> inExpSubscriptLst;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Exp.Subscript> outExpSubscriptLst;
algorithm 
  (outCache,outExpSubscriptLst) :=
  matchcontinue (inCache,inEnv,inExpSubscriptLst,inIntegerLst,inBoolean,inMsg)
    local
      Exp.Subscript sub_1,sub;
      list<Exp.Subscript> subs_1,subs;
      list<Env.Frame> env;
      Integer dim;
      list<Integer> dims;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
    case (cache,_,{},_,_,_) then (cache,{}); 
    case (cache,env,(sub :: subs),(dim :: dims),impl,msg)
      equation 
        (cache,sub_1) = cevalSubscript(cache,env, sub, dim, impl, msg);
        (cache,subs_1) = cevalSubscripts(cache,env, subs, dims, impl, msg);
      then
        (cache,sub_1 :: subs_1);
  end matchcontinue;
end cevalSubscripts;

public function cevalSubscript "function: cevalSubscript
  This function relates a subscript to its canonical forms, which 
  is when all expressions are evaluated to constant values."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Subscript inSubscript;
  input Integer inInteger;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Exp.Subscript outSubscript;
algorithm 
  (outCache,outSubscript) :=
  matchcontinue (inCache,inEnv,inSubscript,inInteger,inBoolean,inMsg)
    local
      list<Env.Frame> env;
      Values.Value v1;
      Exp.Exp e1_1,e1;
      Integer dim;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
      Integer indx;
    case (cache,env,Exp.WHOLEDIM(),_,_,_) then (cache,Exp.WHOLEDIM());  
    case (cache,env,Exp.INDEX(exp = e1),dim,impl,msg)
      equation 
        (cache,v1 as Values.INTEGER(indx),_) = ceval(cache,env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
        true = indx <= dim;
      then
        (cache,Exp.INDEX(e1_1));
    case (cache,env,Exp.SLICE(exp = e1),dim,impl,msg)
      equation 
        (cache,v1,_) = ceval(cache,env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
       true = dimensionSliceInRange(v1,dim);
      then
        (cache,Exp.SLICE(e1_1));
  end matchcontinue;
end cevalSubscript;

public function getValueString "
Constant evaluates Expression and returns a string representing value. 
"
  input Exp.Exp e1;
  output String ostring;
algorithm ostring := matchcontinue( e1)
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val as Values.STRING(ret),_) = ceval(Env.emptyCache,Env.emptyEnv, e1,true,NONE,NONE,MSG());
    then
      ret;
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val,_) = ceval(Env.emptyCache,Env.emptyEnv, e1,true,NONE,NONE,MSG());
      ret = Values.printValStr(val);
    then
      ret;
      
end matchcontinue;
end getValueString;


protected function cevalTuple 
  input list<Exp.Exp> inexps;
  output list<Values.Value> oval;
algorithm oval := matchcontinue(inexps)
  case({}) then {};
case(e ::expl)
  local
    Exp.Exp e;
    list<Exp.Exp> expl;
    Values.Value v;
    list<Values.Value> vs;
  equation
    (_,v,_) = ceval(Env.emptyCache, Env.emptyEnv, e,true,NONE,NONE,MSG);
    vs = cevalTuple(expl);
  then
    v::vs;
end matchcontinue;
end cevalTuple;

protected function crefEqualValue ""
  input Exp.ComponentRef c;
  input Types.Binding v;
  output Boolean outBoolean;
algorithm outBoolean := matchcontinue(c,v)
  case(c,(v as Types.EQBOUND(Exp.CREF(c2,_),NONE,_)))
    local Exp.ComponentRef c2;
    equation
      true = Exp.crefEqual(c,c2);
    then
      true;
  case(_,_) then false;
end matchcontinue;
end crefEqualValue;

protected function dimensionSliceInRange "Checks that the values of a dimension slice is all in the range 1 to dim size
if so returns true, else returns false"
input Values.Value arr;
input Integer dimSize;
output Boolean inRange;
algorithm
  inRange := matchcontinue(arr,dimSize)
  local Integer indx;
    list<Values.Value> vlst;
    case(Values.ARRAY({}),_) then true;
    case(Values.ARRAY(Values.INTEGER(indx)::vlst),dimSize) equation
      true = indx <= dimSize;
      true = dimensionSliceInRange(Values.ARRAY(vlst),dimSize);
    then true;
    case(_,_) then false;
  end matchcontinue;
end dimensionSliceInRange;

end Ceval;

