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

public import Absyn;
public import AbsynDep;
public import DAE;
public import Env;
public import Interactive;
public import Values;


public
uniontype Msg
  record MSG "Give error message" end MSG;
  record NO_MSG "Do not give error message" end NO_MSG;
end Msg;

protected import CevalScript;
protected import ClassInf;
protected import Debug;
protected import Derive;
protected import Dump;
protected import DynLoad;
protected import Error;
protected import Exp;
protected import Inst;
protected import Lookup;
protected import ModUtil;
protected import RTOpts;
protected import Print;
protected import SCode;
protected import Static;
protected import System;
protected import Types;
protected import Util;
protected import ValuesUtil;
protected import Cevalfunc;
protected import InnerOuter;
protected import Prefix;
protected import Connect;
protected import ErrorExt;

public function ceval "
  This function is used when the value of a constant expression is
  needed.  It takes an environment and an expression and calculates
  its value.

  The third argument indicates whether the evaluation is performed in the
  interactive environment (implicit instantiation), in which case function
  calls are evaluated.

  The last argument is an optional dimension."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Option<Integer> inIntegerOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;

	partial function ReductionOperator
		input Values.Value v1;
		input Values.Value v2;
		output Values.Value res;
	end ReductionOperator;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inIntegerOption,inMsg)
    local
      Integer x,dim,l,lhv,rhv,res,start_1,stop_1,step_1,i,indx_1,indx;
      Option<Integer> dimOpt;
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
      list<DAE.Exp> es,expl;
      list<list<tuple<DAE.Exp, Boolean>>> expll;
      Values.Value v,newval,value,sval,elt1,elt2,v_1,lhs_1,rhs_1;
      DAE.Exp lh,rh,e,lhs,rhs,start,stop,step,e1,e2,iterexp;
      Absyn.Path funcpath,func;
      DAE.Operator relop;
      Env.Cache cache;
      Exp.Exp expExp;
      list<Integer> dims;
      list<Option<Integer>> optDims;

    case (cache,_,DAE.ICONST(integer = x),_,st,_,_) then (cache,Values.INTEGER(x),st);

    case (cache,_,DAE.RCONST(real = x),_,st,_,_)
      local Real x;
      then
        (cache,Values.REAL(x),st);

    case (cache,_,DAE.SCONST(string = x),_,st,_,_)
      local String x;
      then
        (cache,Values.STRING(x),st);

    case (cache,_,DAE.BCONST(bool = x),_,st,_,_)
      local Boolean x;
      then
        (cache,Values.BOOL(x),st);

    case (cache,_,DAE.END(),_,st,SOME(dim),_) then (cache,Values.INTEGER(dim),st);

    case (cache,_,DAE.END(),_,st,NONE, MSG())
      equation
        Error.addMessage(Error.END_ILLEGAL_USE_ERROR, {});
      then
        fail();

    case (cache,_,DAE.END(),_,st,NONE, NO_MSG()) then fail();

    case (cache,env,DAE.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation
        (cache,exp_1) = CevalScript.cevalAstExp(cache,env, exp, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (cache,env,DAE.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation
        (cache,exp_1) = CevalScript.cevalAstExp(cache,env, exp, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (cache,env,DAE.CODE(code = Absyn.C_ELEMENT(element = elt)),impl,st,_,msg)
      equation
        (cache,elt_1) = CevalScript.cevalAstElt(cache,env, elt, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_ELEMENT(elt_1)),st);

    case (cache,env,DAE.CODE(code = c),_,st,_,_) then (cache,Values.CODE(c),st);

    case (cache,env,DAE.ARRAY(array = es, ty = DAE.ET_ARRAY(arrayDimensions = optDims)),impl,st,_,msg)
      equation
        dims = Util.listMap(optDims, Util.getOption);
        (cache,es_1) = cevalList(cache,env, es, impl, st, msg);
      then
        (cache,Values.ARRAY(es_1,dims),st);

    case (cache,env,DAE.MATRIX(scalar = expll, ty = DAE.ET_ARRAY(arrayDimensions = optDims)),impl,st,_,msg)
      equation
        dims = Util.listMap(optDims, Util.getOption);
        (cache,elts) = cevalMatrixElt(cache,env, expll, impl, msg);
      then
        (cache,Values.ARRAY(elts,dims),st);

    // MetaModelica List. sjoelund 
    case (cache,env,DAE.LIST(valList = expl),impl,st,_,msg)
      equation
        (cache,es_1) = cevalList(cache,env, expl, impl, st, msg);
      then
        (cache,Values.LIST(es_1),st);

    // MetaModelica Partial Function. sjoelund 
    case (cache,env,DAE.CREF(componentRef = c, ty = DAE.ET_FUNCTION_REFERENCE_VAR()),impl,st,_,msg)
      local
        DAE.ComponentRef c;
      equation
        print(" metamodelica non implemented\n");
        Debug.fprintln("failtrace", "Ceval.ceval not working for function references");
      then
        fail();

    case (cache,env,DAE.CREF(componentRef = c, ty = DAE.ET_FUNCTION_REFERENCE_FUNC()),impl,st,_,msg)
      local
        DAE.ComponentRef c;
      equation
        print(" metamodelica non implemented\n");
        Debug.fprintln("failtrace", "Ceval.ceval not working for function references");
      then
        fail();

    // MetaModelica Uniontype Constructor. sjoelund 2009-05-18
    case (cache,env,inExp as DAE.METARECORDCALL(path=funcpath,args=expl,fieldNames=fieldNames,index=index),impl,st,_,msg)
      local
        list<String> fieldNames; Integer index;
      equation
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
      then (cache,Values.RECORD(funcpath,vallst,fieldNames,index),st);

    // MetaModelica Option type. sjoelund 2009-07-01 
    case (cache,env,DAE.META_OPTION(NONE),impl,st,_,msg)
      then (cache,Values.OPTION(NONE),st);
    case (cache,env,DAE.META_OPTION(SOME(inExp)),impl,st,_,msg)
      equation
        (cache,value,st) = ceval(cache,env,inExp,impl,st,NONE,msg);
      then (cache,Values.OPTION(SOME(value)),st);

    // MetaModelica Tuple. sjoelund 2009-07-02 
    case (cache,env,DAE.META_TUPLE(expl),impl,st,_,msg)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,vallst) = cevalList(cache, env, expl, impl, st, msg);
      then (cache,Values.META_TUPLE(vallst),st);

    case (cache,env,DAE.TUPLE(expl),impl,st,_,msg)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cache,vallst) = cevalList(cache, env, expl, impl, st, msg);
      then (cache,Values.META_TUPLE(vallst),st);

    case (cache,env,DAE.CREF(componentRef = c),(impl as false),SOME(st),_,msg)
      local
        DAE.ComponentRef c;
        Interactive.InteractiveSymbolTable st;
      equation
        (cache,v) = cevalCref(cache,env, c, false, msg) "When in interactive mode, always evalutate crefs, i.e non-implicit mode.." ;
        //Debug.traceln("cevalCref cr: " +& Exp.printComponentRefStr(c) +& " in s: " +& Env.printEnvPathStr(env) +& " v:" +& ValuesUtil.valString(v));
      then
        (cache,v,SOME(st));

    case (cache,env,DAE.CREF(componentRef = c),impl,st,_,msg)
      local DAE.ComponentRef c;
      equation
        (cache,v) = cevalCref(cache,env, c, impl, msg);
        //Debug.traceln("cevalCref cr: " +& Exp.printComponentRefStr(c) +& " in s: " +& Env.printEnvPathStr(env) +& " v:" +& ValuesUtil.valString(v));
      then
        (cache,v,st);
        
    // Evaluates for build in types. ADD, SUB, MUL, DIV for Reals and Integers.
    case (cache,env,expExp,impl,st,dimOpt,msg)
      equation
        (cache,v,st_1) = cevalBuiltin(cache,env, expExp, impl, st, dimOpt, msg);
      then
        (cache,v,st_1);

    // adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem 
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = builtin)),impl,st,dimOpt,msg)
      // Call functions FIXME: functions are always generated. Put back the check
      // and write another rule for the false case that generates the function 
      equation
        ErrorExt.setCheckpoint("cevalCall");
        // do not handle Connection.isRoot here!
        false = stringEqual("Connection.isRoot", Absyn.pathString(funcpath));
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
        (cache,newval,st)= cevalCallFunction(cache, env, e, vallst, impl, st, dimOpt, msg);
        ErrorExt.rollBack("cevalCall");
      then
        (cache,newval,st);

    // make rollback for case above
    case(_,_,DAE.CALL(path = funcpath,expLst = expl,builtin = builtin),_,_,_,_) equation
        ErrorExt.rollBack("cevalCall");
    then fail();
    
    // Try Interactive functions last
    case (cache,env,(e as DAE.CALL(path = _)),(impl as true),SOME(st),_,msg)
      local
        Interactive.InteractiveSymbolTable st;
      equation
        (cache,value,st) = CevalScript.cevalInteractiveFunctions(cache,env, e, st, msg);
      then
        (cache,value,SOME(st));

    case (_,_,e as DAE.CALL(path = _),_,_,_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "- Ceval.ceval DAE.CALL failed: ");
        str = Exp.printExpStr(e);
        Debug.fprintln("failtrace", str);
      then
        fail();


    // Strings 
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.ET_STRING()),exp2 = rh),impl,st,_,msg) 
      local String lhv,rhv;
      equation
        (cache,Values.STRING(lhv),_) = ceval(cache,env, lh, impl, st, NONE, msg);
        (cache,Values.STRING(rhv),_) = ceval(cache,env, rh, impl, st, NONE, msg);
        str = stringAppend(lhv, rhv);
      then
        (cache,Values.STRING(str),st);

    // Numerical
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.ET_REAL()),exp2 = rh),impl,st,dim,msg)
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation
        (cache,Values.REAL(lhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.REAL(rhv),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        sum = lhv +. rhv;
      then
        (cache,Values.REAL(sum),st_2);

    // Array addition
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vlst1,dims),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2,_),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.addElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array subtraction
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vlst1,dims),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2,_),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.subElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array multiplication
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vlst1,dims),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2,_),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.mulElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array division
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vlst1,dims),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2,_),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.divElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array power
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARR2(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vlst1,dims),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(vlst2,_),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.powElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array multipled scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = ValuesUtil.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array add scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = ValuesUtil.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array subtract scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.subScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = ValuesUtil.subArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.powScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = ValuesUtil.powArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // scalar div array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_SCALAR_ARRAY(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        reslst = ValuesUtil.divScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // array div scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARRAY_SCALAR(ty = _),exp2 = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,sval,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(aval,dims),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        reslst = ValuesUtil.divArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),st_2);

    // scalar multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_SCALAR_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation
        (cache,Values.ARRAY(valueLst = rhvals),st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        (cache,Values.ARRAY(valueLst = lhvals),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        res = ValuesUtil.multScalarProduct(rhvals, lhvals);
      then
        (cache,res,st_2);

    // array multipled array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation
        (cache,Values.ARRAY(valueLst = (lhvals as (elt1 :: _))),st_1) = ceval(cache,env, lh, impl, st, dim, msg) "{{..}..{..}}  {...}" ;
        (cache,Values.ARRAY(valueLst = (rhvals as (elt2 :: _))),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        res = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,res,st_2);

    // array multiplied array 
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation
        (cache,Values.ARRAY(valueLst = (rhvals as (elt1 :: _))),st_1) = ceval(cache,env, rh, impl, st, dim, msg) "{...}  {{..}..{..}}" ;
        (cache,Values.ARRAY(valueLst = (lhvals as (elt2 :: _))),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        res = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,res,st_2);

    // array multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,st,dim,msg)
      local
        list<Values.Value> res;
        Option<Integer> dim;
      equation
        (cache,Values.ARRAY((rhvals as (elt1 :: _)),dims),st_1) = ceval(cache,env, rh, impl, st, dim, msg) "{{..}..{..}}  {{..}..{..}}" ;
        (cache,Values.ARRAY((lhvals as (elt2 :: _)),_),st_2) = ceval(cache,env, lh, impl, st_1, dim, msg);
        true = ValuesUtil.isArray(elt1);
        true = ValuesUtil.isArray(elt2);
        res = ValuesUtil.multMatrix(lhvals, rhvals);
      then
        (cache,ValuesUtil.makeArray(res),st_2);

		//POW (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
				res3 = ValuesUtil.safeIntRealOp(res1, res2, Values.POWOP);
      then
        (cache,res3,st_2);

		//MUL (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
				res3 = ValuesUtil.safeIntRealOp(res1, res2, Values.MULOP);
      then
        (cache,res3,st_2);

		//DIV (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
				res3 = ValuesUtil.safeIntRealOp(res1, res2, Values.DIVOP);
      then
        (cache,res3,st_2);

		//DIV (handle div by zero)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(ty =_),exp2 = rh),impl,st,dim,msg)
      local
        Real lhv,rhv;
        Option<Integer> dim;
        Values.Value res1;
      equation
        (cache,res1,st_1) = ceval(cache,env, rh, impl, st, dim, msg);
        true = ValuesUtil.isZero(res1);
        lh_str = Exp.printExpStr(lh);
        rh_str = Exp.printExpStr(rh);
        Error.addMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str});
      then
        fail();

		//ADD (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
				res3 = ValuesUtil.safeIntRealOp(res1, res2, Values.ADDOP);
      then
        (cache,res3,st_2);

		//SUB (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB(ty=_),exp2 = rh),impl,st,dim,msg)
      local
        Values.Value res1, res2, res3;
        Option<Integer> dim;
      equation
        (cache,res1,st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,res2,st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
				res3 = ValuesUtil.safeIntRealOp(res1, res2, Values.SUBOP);
      then
        (cache,res3,st_2);

    //  unary minus of array 
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS_ARR(ty = _),exp = exp),impl,st,dim,msg)
      local
        DAE.Exp exp;
        Option<Integer> dim;
      equation
        (cache,Values.ARRAY(arr,dims),st_1) = ceval(cache,env, exp, impl, st, dim, msg);
        arr_1 = Util.listMap(arr, ValuesUtil.valueNeg);
      then
        (cache,Values.ARRAY(arr_1,dims),st_1);

    // unary minus of expression
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = exp),impl,st,dim,msg)
      local
        DAE.Exp exp;
        Option<Integer> dim;
      equation
        (cache,v,st_1) = ceval(cache,env, exp, impl, st, dim, msg);
        v_1 = ValuesUtil.valueNeg(v);
      then
        (cache,v_1,st_1);

    // unary plus of expression
    case (cache,env,DAE.UNARY(operator = DAE.UPLUS(ty = _),exp = exp),impl,st,dim,msg)
      local
        DAE.Exp exp;
        Option<Integer> dim;
      equation
        (cache,v,st_1) = ceval(cache,env, exp, impl, st, dim, msg);
      then
        (cache,v,st_1);

    // Logical operations false AND rhs
    // special case when leftside is false...
    // We allow errors on right hand side. and even if there is no errors, the performance
    // will be better.
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.AND(),exp2 = rh),impl,st,dim,msg)
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation
        (cache,Values.BOOL(false),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
      then
        (cache,Values.BOOL(false),st_1);

    // Logical lhs AND rhs
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.AND(),exp2 = rh),impl,st,dim,msg)
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation
        (cache,Values.BOOL(lhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        (cache,Values.BOOL(rhv),st_2) = ceval(cache,env, rh, impl, st_1, dim, msg);
        x = boolAnd(lhv, rhv);
      then
        (cache,Values.BOOL(x),st_2);

    // true OR rhs 
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(),exp2 = rh),impl,st,dim,msg)
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation
        (cache,Values.BOOL(true),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
      then
        (cache,Values.BOOL(true),st_1);

    // lhs OR rhs 
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(),exp2 = rh),impl,st,dim,msg)
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
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(),exp2 = rh),impl,st,dim,msg)
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation
        (cache,v as Values.BOOL(rhv),st_1) = ceval(cache,env, lh, impl, st, dim, msg);
        failure((_,_,_) = ceval(cache,env, rh, impl, st_1, dim, msg));
      then
        (cache,v,st_1);

    // NOT
    case (cache,env,DAE.LUNARY(operator = DAE.NOT(),exp = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.BOOL(b),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        b_1 = boolNot(b);
      then
        (cache,Values.BOOL(b_1),st_1);

    // relations <, >, <=, >=, <> 
    case (cache,env,DAE.RELATION(exp1 = lhs,operator = relop,exp2 = rhs),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,lhs_1,st_1) = ceval(cache,env, lhs, impl, st, dim, msg);
        (cache,rhs_1,st_2) = ceval(cache,env, rhs, impl, st_1, dim, msg);
        v = cevalRelation(lhs_1, relop, rhs_1);
      then
        (cache,v,st_2);

    // range first:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.ET_INT(),exp = start,expOption = NONE,range = stop),impl,st,dim,msg) 
      local Option<Integer> dim;
      equation
        (cache,Values.INTEGER(start_1),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.INTEGER(stop_1),st_2) = ceval(cache,env, stop, impl, st_1, dim, msg);
        arr = cevalRange(start_1, 1, stop_1);
      then
        (cache,ValuesUtil.makeArray(arr),st_1);

    // range first:step:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.ET_INT(),exp = start,expOption = SOME(step),range = stop),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.INTEGER(start_1),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.INTEGER(step_1),st_2) = ceval(cache,env, step, impl, st_1, dim, msg);
        (cache,Values.INTEGER(stop_1),st_3) = ceval(cache,env, stop, impl, st_2, dim, msg);
        arr = cevalRange(start_1, step_1, stop_1);
      then
        (cache,ValuesUtil.makeArray(arr),st_3);

    // range first:step:last for enumearations
    case (cache,env,DAE.RANGE(ty = DAE.ET_ENUMERATION(_,_,_,_),exp = start,expOption = NONE,range = stop),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ENUM(start_1,_,_),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.ENUM(stop_1,_,_),st_2) = ceval(cache,env, stop, impl, st_1, dim, msg);
        arr = cevalRange(start_1, 1, stop_1);
      then
        (cache,ValuesUtil.makeArray(arr),st_1);

    // range first:last for reals
    case (cache,env,DAE.RANGE(ty = DAE.ET_REAL(),exp = start,expOption = NONE,range = stop),impl,st,dim,msg)
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
        (cache,ValuesUtil.makeArray(arr),st_2);

    // range first:step:last for reals    
    case (cache,env,DAE.RANGE(ty = DAE.ET_REAL(),exp = start,expOption = SOME(step),range = stop),impl,st,dim,msg)
      local
        Real start_1,step_1,stop_1;
        Option<Integer> dim;
      equation
        (cache,Values.REAL(start_1),st_1) = ceval(cache,env, start, impl, st, dim, msg);
        (cache,Values.REAL(step_1),st_2) = ceval(cache,env, step, impl, st_1, dim, msg);
        (cache,Values.REAL(stop_1),st_3) = ceval(cache,env, stop, impl, st_2, dim, msg);
        arr = cevalRangeReal(start_1, step_1, stop_1);
      then
        (cache,ValuesUtil.makeArray(arr),st_3);

    // cast integer to real
    case (cache,env,DAE.CAST(ty = DAE.ET_REAL(),exp = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.INTEGER(i),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        r = intReal(i);
      then
        (cache,Values.REAL(r),st_1);

    // cast integer array to real array
    case (cache,env,DAE.CAST(ty = DAE.ET_ARRAY(DAE.ET_REAL(),optDims),exp = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(ivals,dims),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        rvals = ValuesUtil.typeConvert(DAE.ET_INT(), DAE.ET_REAL(), ivals);
      then
        (cache,Values.ARRAY(rvals,dims),st_1);

    // cast integer array to real array
    case (cache,env,DAE.CAST(ty = DAE.ET_REAL(),exp = (e as DAE.ARRAY(ty = DAE.ET_INT(),array = expl))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vallst,dims),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        vallst_1 = ValuesUtil.typeConvert(DAE.ET_INT(), DAE.ET_REAL(), vallst);
      then
        (cache,Values.ARRAY(vallst_1,dims),st_1);

    // cast integer range to real range
    case (cache,env,DAE.CAST(ty = DAE.ET_REAL(),exp = (e as DAE.RANGE(ty = DAE.ET_INT()))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vallst,dims),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        vallst_1 = ValuesUtil.typeConvert(DAE.ET_INT(), DAE.ET_REAL(), vallst);
      then
        (cache,Values.ARRAY(vallst_1,dims),st_1);

    // cast integer matrix to real matrix
    case (cache,env,DAE.CAST(ty = DAE.ET_REAL(),exp = (e as DAE.MATRIX(ty = DAE.ET_INT()))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vallst,dims),st_1) = ceval(cache,env, e, impl, st, dim, msg);
        vallst_1 = ValuesUtil.typeConvert(DAE.ET_INT(), DAE.ET_REAL(), vallst);
      then
        (cache,Values.ARRAY(vallst_1,dims),st_1);

    // if expressions, select then branch if condition is true
    case (cache,env,DAE.IFEXP(expCond = b,expThen = e1,expElse = e2),impl,st,dim,msg)
      local
        DAE.Exp b;
        Option<Integer> dim;
      equation
        (cache,Values.BOOL(true),st_1) = ceval(cache,env, b, impl, st, dim, msg) "Ifexp, true branch" ;
        (cache,v,st_2) = ceval(cache,env, e1, impl, st_1, dim, msg);
      then
        (cache,v,st_2);

    // if expressions, select else branch if condition is false
    case (cache,env,DAE.IFEXP(expCond = b,expThen = e1,expElse = e2),impl,st,dim,msg)
      local
        DAE.Exp b;
        Option<Integer> dim;
      equation
        (cache,Values.BOOL(false),st_1) = ceval(cache,env, b, impl, st, dim, msg) "Ifexp, false branch" ;
        (cache,v,st_2) = ceval(cache,env, e2, impl, st_1, dim, msg);
      then
        (cache,v,st_2);

    // indexing for array[integer index] 
    case (cache,env,DAE.ASUB(exp = e,sub = ((e1 as DAE.ICONST(indx))::{})),impl,st,dim,msg)
      local Option<Integer> dim;
      equation
        (cache,Values.ARRAY(vals,_),st_1) = ceval(cache,env, e, impl, st, dim, msg) "asub" ;
        indx_1 = indx - 1;
        v = listNth(vals, indx_1);
      then
        (cache,v,st_1);
    
    // indexing for array[subscripts]
    case (cache, env, DAE.ASUB(exp = e,sub = expl ), impl, st, dim, msg)
      local Option<Integer> dim; String s;
      equation
        (cache,Values.ARRAY(vals,dims),st_1) = ceval(cache,env, e, impl, st, dim, msg) "asub" ;
        (cache,es_1) = cevalList(cache,env, expl, impl, st_1, msg) "asub exp" ;
        v = Util.listFirst(es_1);
        v = ValuesUtil.nthnthArrayelt(es_1,Values.ARRAY(vals,dims),v);
      then
        (cache,v,st_1);

    // reductions
    case (cache, env, DAE.REDUCTION(Absyn.IDENT(reductionName), expr = exp, ident = iter, range = iterexp), impl, st, dimOpt, msg)
      local
        DAE.Ident reductionName;
        DAE.Exp exp;
        ReductionOperator op;
      equation
        (cache, Values.ARRAY(vals,_), st_1) = ceval(cache, env, iterexp, impl, st, dimOpt, msg);
        env = Env.openScope(env, false, SOME(Env.forScopeName));
        op = lookupReductionOp(reductionName);
        (cache, value, st_1) = cevalReduction(cache, env, op, exp, iter, vals, impl, st, dimOpt, msg);
      then (cache, value, st_1);

    // ceval can fail and that is ok, caught by other rules... 
    case (cache,env,e,_,_,_,_) // MSG())
      equation
        true = RTOpts.debugFlag("ceval");
        Debug.traceln("- Ceval.ceval failed: " +& Exp.printExpStr(e));
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
        // Debug.traceln("  Env:" +& Env.printEnvStr(env));
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
  input DAE.Exp inExp;
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
        input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp,dim,e;
      Boolean impl,builtin;
      Msg msg;
      HandlerFunc handler;
      String id;
      list<DAE.Exp> args,expl;
      list<Values.Value> vallst;
      Absyn.Path funcpath,path;
      Env.Cache cache;
      Option<Integer> dimOpt;

    case (cache,env,DAE.SIZE(exp = exp,sz = SOME(dim)),impl,st,_,msg)
      equation
        (cache,v,st) = cevalBuiltinSize(cache,env, exp, dim, impl, st, msg) "Handle size separately" ;
      then
        (cache,v,st);
    case (cache,env,DAE.SIZE(exp = exp,sz = NONE),impl,st,_,msg)
      equation
        (cache,v,st) = cevalBuiltinSizeMatrix(cache,env, exp, impl, st, msg);
      then
        (cache,v,st);
    case (cache,env,DAE.CALL(path = path,expLst = args,builtin = builtin),impl,st,_,msg) /* buildin: as true */
      equation
        id = Absyn.pathString(path);
        handler = cevalBuiltinHandler(id);
        (cache,v,st) = handler(cache,env, args, impl, st, msg);
      then
        (cache,v,st);
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = (builtin as true))),impl,(st as NONE),dimOpt,msg)
      equation
        (cache,vallst) = cevalList(cache, env, expl, impl, st, msg);
        (cache,newval,st) = cevalCallFunction(cache, env, e, vallst, impl, st, dimOpt, msg);
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
    input list<DAE.Exp> inExpExpLst;
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
    case "asin" then cevalBuiltinAsin;
    case "acos" then cevalBuiltinAcos;
    case "atan" then cevalBuiltinAtan;
    case "atan2" then cevalBuiltinAtan2;
    case "log" then cevalBuiltinLog;
    case "log10" then cevalBuiltinLog10;
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
    case "linspace" then cevalBuiltinLinspace;
    case "Integer" then cevalBuiltinIntegerEnumeration;
    case "rooted" then cevalBuiltinRooted; //
    case "cross" then cevalBuiltinCross;
    case "print" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalBuiltinPrint;
    // MetaModelica type conversions
    case "intReal" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalIntReal;
    case "intString" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalIntString;
    case "realInt" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalRealInt;
    case "realString" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalRealString;
    case "stringCharInt" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringCharInt;
    case "intStringChar" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalIntStringChar;
    case "stringInt" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringInt;
    case "stringListStringChar" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalStringListStringChar;
    case "listStringCharString" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalListStringCharString;
    // Box/Unbox
    case "mmc_mk_icon" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalNoBoxUnbox;
    case "mmc_mk_rcon" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalNoBoxUnbox;
    case "mmc_mk_scon" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalNoBoxUnbox;
    case "mmc_unbox_integer" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalNoBoxUnbox;
    case "mmc_unbox_real" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalNoBoxUnbox;
    case "mmc_unbox_string" equation true = RTOpts.acceptMetaModelicaGrammar(); then cevalNoBoxUnbox;

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
  input DAE.Exp inExp;
  input list<Values.Value> inValuesValueLst;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> inSymTab;
  input Option<Integer> dim;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outSymTab;
algorithm
  (outCache,outValue,outSymTab) := matchcontinue (inCache,inEnv,inExp,inValuesValueLst,impl,inSymTab,dim,inMsg)
    local
      Values.Value newval;
      list<Env.Frame> env;
      DAE.Exp e;
      Absyn.Path funcpath;
      list<DAE.Exp> expl;
      Boolean builtin;
      list<Values.Value> vallst;
      Msg msg;
      String funcstr,str;
      Env.Cache cache;
      list<Interactive.CompiledCFunction> cflist;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.Program p,ptot;
      Integer libHandle, funcHandle;
      String fNew,fOld;
      Real buildTime, edit, build;
      Absyn.Program p;
      AbsynDep.Depends aDep;
      list<SCode.Class> a;
      list<Interactive.InstantiatedClass> b;
      list<Interactive.InteractiveVariable> c;
      list<Interactive.CompiledCFunction> cf;
      list<Interactive.LoadedFile> lf;
      Absyn.TimeStamp ts;
      String funcstr,f,funcFileNameStr;
      Boolean ifFuncInList;
      list<Interactive.CompiledCFunction> newCF;
      String name;
      Boolean ppref, fpref, epref;
      Absyn.Restriction restriction  "Restriction" ;
      Absyn.ClassDef    body;
      Absyn.Info        info;
      Absyn.Within      w;
      String funcFileNameStr;
      Types.Type tp;
      Absyn.Path funcpath2;
      String s;
      list<Exp.Var> varLst;
      list<String> varNames;
      String complexName, lastIdent;
      Absyn.Path p2;
      Env.Env env1;
      SCode.Class sc;
      list<SCode.Element> elementList;
      SCode.ClassDef cdef;
      DAE.DAElist daeList;
      String error_Str;
      CevalHashTable cevalHashTable;

      /* Try cevalFunction first */
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,impl,st,_,msg)
      equation
        (cache,false) = Static.isExternalObjectFunction(cache,env,funcpath);
        // Call of record constructors, etc., i.e. functions that can be constant propagated.
        (cache,newval) = cevalFunction(cache, env, funcpath, vallst, impl, msg);
      then
        (cache,newval,st);

        /* External functions that are "known" should be evaluated without compilation, e.g. all math functions */
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,impl,st,dim,msg)
      equation
        (cache,newval) = cevalKnownExternalFuncs(cache,env, funcpath, vallst, msg);
      then
        (cache,newval,st);

        // This case prevents the constructor call of external objects of being evaluated
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl, builtin = builtin)),vallst,impl,st,dim,msg)
      equation
        cevalIsExternalObjectConstructor(cache,funcpath,env);
      then
        fail();

    // adrpo: 2009-11-17 re-enable the Cevalfunc after dealing with record constructors!
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,impl,st,dim,msg)
      local Env.Cache garbageCache;
      equation
        false = RTOpts.debugFlag("noevalfunc");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        // make sure is NOT used for records !
        (cache,sc as SCode.CLASS(_,false,_,SCode.R_FUNCTION(),cdef,_),env1) =
        Lookup.lookupClass(cache,env,funcpath,true);
        (garbageCache,env1,_,daeList) =
        Inst.implicitFunctionInstantiation(
          cache,
          env1,
          InnerOuter.emptyInstHierarchy,
          DAE.NOMOD(),
          Prefix.NOPRE(),
          Connect.emptySet,
          sc,
          {}) ;
        newval = Cevalfunc.cevalUserFunc(env1,e,vallst,sc,daeList);
        //print("ret value(/s): "); print(ValuesUtil.printValStr(newval));print("\n");
      then
        (cache,newval,st);

        /* Record constructors */
    case(cache,env,(e as DAE.CALL(path = funcpath,ty = DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(complexName), varLst=varLst))),vallst,
         impl,st,dim,msg)
         local Absyn.Path complexName;
      equation
        true = ModUtil.pathEqual(funcpath,complexName);
        varNames = Util.listMap(varLst,Exp.varName);
      then (cache,Values.RECORD(funcpath,vallst,varNames,-1),st);

/*     This match-rule is commented out due to a new constant evaluation algorithm in
     Cevalfunc.mo.
     We still keep this incase we need to have a generate backup in the future.
     2007-10-26 BZ
     2007-11-01 readded, external c-function needs this...
     TODO: implement a check for external functionrecurisvly.
*/

    /* adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem */
    // see if function is in CF list and the build time is less than the edit time
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,impl,// (impl as true)
      (st as SOME(Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),_,_,_,_,cflist,_))),dim,msg)
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        (true, funcHandle, buildTime, fOld) = Static.isFunctionInCflist(cflist, funcpath);
        // Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,Absyn.INFO(fileName = fNew)) = Interactive.getPathedClassInProgram(funcpath, p);
        // adrpo: 2010-01-22
        // see if we don't have it in env!
        (_,SCode.CLASS(restriction=SCode.R_FUNCTION(),info=Absyn.INFO(fileName = fNew)),_) =
          Lookup.lookupClass(cache, env, funcpath, true);
        // see if the build time from the class is the same as the build time from the compiled functions list
        false = stringEqual(fNew,""); // see if the WE have a file or not!
        false = Static.needToRebuild(fNew,fOld,buildTime); // we don't need to rebuild!
        funcstr = ModUtil.pathStringReplaceDot(funcpath, "_");
        Debug.fprintln("dynload", "CALL: About to execute function present in CF list: " +& funcstr);
        newval = DynLoad.executeFunction(funcHandle, vallst);
      then
        (cache,newval,st);
    /* adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem */
    // see if function is in CF list and the build time is less than the edit time
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl)),vallst,impl,// impl as true
      (st as SOME(Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),_,_,_,_,cflist,_))),dim,msg)
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        (true, funcHandle, buildTime, fOld) = Static.isFunctionInCflist(cflist, funcpath);
        // Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,Absyn.INFO(fileName = fNew, buildTimes= Absyn.TIMESTAMP(build,_))) = Interactive.getPathedClassInProgram(funcpath, p);
        // adrpo: 2010-01-22
        // see if we don't have it in env!
        (_,SCode.CLASS(restriction=SCode.R_FUNCTION(),info=Absyn.INFO(fileName = fNew, buildTimes= Absyn.TIMESTAMP(build,_))),_) =
           Lookup.lookupClass(cache, env, funcpath, true);
        // note, this should only work for classes that have no file name!
        true = stringEqual(fNew,""); // see that we don't have a file!

        // see if the build time from the class is the same as the build time from the compiled functions list
        //debug_print("edit",edit);
        true = (buildTime >=. build);
        true = (buildTime >. edit);
        funcstr = ModUtil.pathStringReplaceDot(funcpath, "_");
        Debug.fprintln("dynload", "CALL: About to execute function present in CF list: " +& funcstr);
        newval = DynLoad.executeFunction(funcHandle, vallst);
      then
        (cache,newval,st);

      /**//* Call functions in non-interactive mode. FIXME: functions are always generated.
      Put back the check and write another rule for the false case that generates the function
      2007-10-20 partially fixed BZ*//**/
    /* adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem */
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,impl,
          SOME(Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=ts),aDep,a,b,c,cf,lf)),dim,msg) // yeha! we have a symboltable!
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        newCF = Interactive.removeCf(funcpath, cf); // remove it as it might be there with an older build time.
        (cache, funcstr) = CevalScript.cevalGenerateFunction(cache, env, funcpath);
        Debug.fprintln("dynload", "cevalCallFunction: about to execute " +& funcstr);
        libHandle = System.loadLibrary(funcstr);
        funcHandle = System.lookupFunction(libHandle, stringAppend("in_", funcstr));
        newval = DynLoad.executeFunction(funcHandle, vallst);
        System.freeLibrary(libHandle);
        buildTime = System.getCurrentTime();
        // adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem
        // update the build time in the class!
        Absyn.CLASS(name,ppref,fpref,epref,Absyn.R_FUNCTION(),body,info) = Interactive.getPathedClassInProgram(funcpath, p);

        info = Absyn.setBuildTimeInInfo(buildTime,info);
        ts = Absyn.setTimeStampBuild(ts, buildTime);
        w = Interactive.buildWithin(funcpath);
        Debug.fprintln("dynload", "Updating build time for function path: " +& Absyn.pathString(funcpath) +& " within: " +& Dump.unparseWithin(0, w) +& "\n");
        p = Interactive.updateProgram(Absyn.PROGRAM({Absyn.CLASS(name,ppref,fpref,epref,Absyn.R_FUNCTION(),body,info)},w,ts), p);
        f = Absyn.getFileNameFromInfo(info);
      then
        (cache,newval,SOME(Interactive.SYMBOLTABLE(p, aDep, a, b, c,
          Interactive.CFunction(funcpath,(DAE.T_NOTYPE(),SOME(funcpath)),funcHandle,buildTime,f)::newCF, lf)));

    /*/ crap! we have no symboltable!, see in ceval cache
      // adrpo: TODO! FIXME! this is disabled for now as we need to remove the deletion of .dll/.so from the mos files in the testsuite.
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,impl,NONE(),dim,msg)
      equation
        false = RTOpts.debugFlag("nogen");
        failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        // we might actually have a function loaded here already!
        cevalHashTable = System.getFromRoots(1);
        // see if we have it in the ceval cache
        Interactive.CFunction(funcHandle=funcHandle, buildTime=buildTime, loadedFromFile=fOld) = get(funcpath, cevalHashTable);
        funcstr = ModUtil.pathStringReplaceDot(funcpath, "_");
        Debug.fprintln("dynload", "CALL: About to execute function present in CevalCache list: " +& funcstr);
        newval = DynLoad.executeFunction(funcHandle, vallst);
      then
        (cache,newval,NONE());*/

    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,impl,NONE(),dim,msg) // crap! we have no symboltable!
      equation
        false = RTOpts.debugFlag("nogen");
 				failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        // we might actually have a function loaded here already!
        // we need to unload all functions to not get conflicts!
        (cache,funcstr) = CevalScript.cevalGenerateFunction(cache, env, funcpath);
        // generate a uniquely named dll!
        Debug.fprintln("dynload", "cevalCallFunction: about to execute " +& funcstr);
        libHandle = System.loadLibrary(funcstr);
        funcHandle = System.lookupFunction(libHandle, stringAppend("in_", funcstr));
        newval = DynLoad.executeFunction(funcHandle, vallst);
        System.freeFunction(funcHandle);
        System.freeLibrary(libHandle);
        // add to cache!
        //cevalHashTable = System.getFromRoots(1);
        //buildTime = System.getCurrentTime();
        //cevalHashTable = add((funcpath,Interactive.CFunction(funcpath,(DAE.T_NOTYPE(),SOME(funcpath)),funcHandle,buildTime,"")), cevalHashTable);
        //System.addToRoots(1, cevalHashTable);
      then
        (cache,newval,NONE());

    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,impl,st,dim,msg)
      equation
        error_Str = Absyn.pathString(funcpath);
        //TODO: readd this when testsuite is okay.
        //Error.addMessage(Error.FAILED_TO_EVALUATE_FUNCTION, {error_Str});
        true = RTOpts.debugFlag("nogen");
        Debug.fprint("failtrace", "- codegeneration is turned off. switch \"nogen\" flag off\n");
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
  DAE.Type tp;
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
  SCode.CLASS(name=fid,restriction = SCode.R_EXT_FUNCTION(), classDef=SCode.PARTS(externalDecl=extdecl)) := cdef;
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
      DAE.Mod mod;
      list<DAE.Element> dae;
      Values.Value value;
      Absyn.Path funcname;
      list<Values.Value> vallst;
      Boolean impl;
      Msg msg;
      String s;
      Env.Cache cache;
      Env.Env env_2;
      // Not working properly (only non-nested records)! /sjoelund
      /*
    case (cache,env,funcname,vallst,impl,msg) "For record constructors"
      equation
        (_,_) = Lookup.lookupRecordConstructorClass(env, funcname);
        (cache,c,env_1) = Lookup.lookupClass(cache,env, funcname, false);
        compnames = SCode.componentNames(c);
        mod = Types.valuesToMods(vallst, compnames);
        (cache,env_2,_,_,dae,_,_,_,_,_) = Inst.instClass(cache,env_1,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore, mod, Prefix.NOPRE(), Connect.emptySet, c, {}, impl,
          Inst.TOP_CALL(),ConnectionGraph.EMPTY);
        (cache, value) = DAE.daeToRecordValue(cache, env_2, funcname, dae, impl) "adrpo: We need the env here as we need to do variable Lookup!";
      then
        (cache,value);
      */

    case (cache,env,funcname,vallst,(impl as true),msg)
      equation
        /*Debug.fprint("failtrace", "- Ceval.cevalFunction: Don't know what to do. impl was always false before:");
        s = Absyn.pathString(funcname);
        Debug.fprintln("failtrace", s);*/
      then
        fail();
  end matchcontinue;
end cevalFunction;

protected function cevalMatrixElt "function: cevalMatrixElt
  Evaluates the expression of a matrix constructor, e.g. {1,2;3,4}"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst "matrix constr. elts";
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
      list<tuple<DAE.Exp, Boolean>> expl;
      list<list<tuple<DAE.Exp, Boolean>>> expll;
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
  input list<tuple<DAE.Exp, Boolean>> inTplExpExpBooleanLst;
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
      DAE.Exp e;
      list<tuple<DAE.Exp, Boolean>> rest;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
      Integer i;
      list<Integer> dims;
    case (cache,env,((e,_) :: rest),impl,msg)
      equation
        (cache,res,_) = ceval(cache,env, e, impl, NONE, NONE, msg);
        (cache,Values.ARRAY(resl,i::dims)) = cevalMatrixEltRow(cache,env, rest, impl, msg);
        i = i+1;
      then
        (cache,Values.ARRAY(res :: resl,i::dims));
    case (cache,env,{},_,msg) then (cache,Values.ARRAY({},{0}));
  end matchcontinue;
end cevalMatrixEltRow;

protected function cevalBuiltinSize "function: cevalBuiltinSize
  Evaluates the size operator."
	input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
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
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      DAE.Binding bind,binding;
      list<Integer> sizelst;
      Integer dim,dim_1,v,dimv,len;
      Option<Interactive.InteractiveSymbolTable> st_1,st;
      list<Env.Frame> env;
      DAE.ComponentRef cr;
      Boolean impl,bl;
      Msg msg;
      list<Inst.DimExp> dims;
      Values.Value v2;
      DAE.ExpType crtp;
      DAE.Exp exp,e;
      String cr_str,dim_str,size_str,expstr;
      list<DAE.Exp> es;
      Env.Cache cache;
      list<list<tuple<DAE.Exp, Boolean>>> mat;
    case (cache,_,DAE.MATRIX(scalar=mat),DAE.ICONST(1),_,st,_)
      equation
        v=listLength(mat);
      then
        (cache,Values.INTEGER(v),st);
    case (cache,_,DAE.MATRIX(scalar=mat),DAE.ICONST(2),_,st,_)
      equation
        v=listLength(Util.listFirst(mat));
      then
        (cache,Values.INTEGER(v),st);
    case (cache,env,DAE.MATRIX(scalar=mat),DAE.ICONST(dim),impl,st,msg)
      equation
        bl=(dim>2);
        true=bl;
        dim_1=dim-2;
        e=Util.tuple21(Util.listFirst(Util.listFirst(mat)));
        (cache,Values.INTEGER(v),st_1)=cevalBuiltinSize(cache,env,e,DAE.ICONST(dim_1),impl,st,msg);
      then
        (cache,Values.INTEGER(v),st);
    case (cache,env,DAE.CREF(componentRef = cr,ty = tp),dim,impl,st,msg)
      equation
        (cache,attr,tp,bind,_,_,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions known, always ceval" ;
        true = Types.dimensionsKnown(tp);
        sizelst = Types.getDimensionSizes(tp);
        (cache,Values.INTEGER(dim),st_1) = ceval(cache, env, dim, impl, st, NONE, msg);
        dim_1 = dim - 1;
        v = listNth(sizelst, dim_1);
      then
        (cache,Values.INTEGER(v),st_1);
    case (cache,env,DAE.CREF(componentRef = cr,ty = tp),dim,(impl as false),st,msg)
      local
        DAE.ExpType tp;
        DAE.Exp dim;
      equation
        (cache,dims,_) = Inst.elabComponentArraydimFromEnv(cache,env, cr) "If component not instantiated yet, recursive definition.
	 For example,
	 Real x[:](min=fill(1.0,size(x,1))) = {1.0}

	  When size(x,1) should be determined, x must be instantiated, but
	  that is not done yet. Solution: Examine Element to find modifier
	  which will determine dimension size.
	" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        v2 = cevalBuiltinSize3(dims, dimv);
      then
        (cache,v2,st_1);
    case (cache,env,DAE.CREF(componentRef = cr,ty = tp),dim,(impl as true),st,msg)
      local DAE.Exp dim;
      equation
        (cache,attr,tp,bind,_,_,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions not known and impl=true, just silently fail" ;
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (cache,env,DAE.CREF(componentRef = cr,ty = tp),dim,(impl as false),st,MSG())
      local DAE.Exp dim;
      equation
        (cache,attr,tp,bind,_,_,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions not known and impl=false, error message" ;

        false = Types.dimensionsKnown(tp);
        cr_str = Exp.printComponentRefStr(cr);
        dim_str = Exp.printExpStr(dim);
        size_str = Util.stringAppendList({"size(",cr_str,", ",dim_str,")"});
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {size_str});
      then
        fail();
    case (cache,env,DAE.CREF(componentRef = cr,ty = tp),dim,(impl as false),st,NO_MSG())
      local DAE.Exp dim;
      equation
        (cache,attr,tp,bind,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dim,(impl as false),st,MSG())
      local DAE.Exp dim;
      equation
        (cache,attr,tp,DAE.UNBOUND(),_,_,_,_) = Lookup.lookupVar(cache,env, cr) "For crefs without value binding" ;
        expstr = Exp.printExpStr(exp);
        Error.addMessage(Error.UNBOUND_VALUE, {expstr});
      then
        fail();
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dim,(impl as false),st,NO_MSG())
      local DAE.Exp dim;
      equation
        (cache,attr,tp,DAE.UNBOUND(),_,_,_,_) = Lookup.lookupVar(cache,env, cr);
      then
        fail();
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dim,(impl as true),st,msg)
      local DAE.Exp dim;
      equation
        (cache,attr,tp,DAE.UNBOUND(),_,_,_,_) = Lookup.lookupVar(cache,env, cr) "For crefs without value binding. If impl=true just silently fail" ;
      then
        fail();

		// For crefs with value binding e.g. size(x,1) when Real x[:]=fill(0,1);
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dim,impl,st,msg)
      local
        Values.Value v;
        DAE.Exp dim;
      equation 
        (cache,attr,tp,binding,_,_,_,_) = Lookup.lookupVar(cache,env, cr)  ;     
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        (cache,v) = cevalCrefBinding(cache,env, cr, binding, impl, msg);
        v2 = cevalBuiltinSize2(v, dimv);
      then
        (cache,v2,st_1);
    case (cache,env,DAE.ARRAY(array = (e :: es)),dim,impl,st,msg)
      local
        DAE.ExpType tp;
        DAE.Exp dim;
      equation
        tp = Exp.typeof(e) "Special case for array expressions with nonconstant
                            values For now: only arrays of scalar elements:
                            TODO generalize to arbitrary dimensions" ;
        true = Exp.typeBuiltin(tp);
        (cache,Values.INTEGER(1),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        len = listLength((e :: es));
      then
        (cache,Values.INTEGER(len),st_1);

    // adrpo 2009-06-08: it doen't need to be a builtin type as long as the dimension is an integer!
    case (cache,env,DAE.ARRAY(array = (e :: es)),dim,impl,st,msg)
      local
        DAE.ExpType tp;
        DAE.Exp dim;
      equation
        tp = Exp.typeof(e) "Special case for array expressions with nonconstant values
                            For now: only arrays of scalar elements:
                            TODO generalize to arbitrary dimensions" ;
        false = Exp.typeBuiltin(tp);
        (cache,Values.INTEGER(1),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        len = listLength((e :: es));
      then
        (cache,Values.INTEGER(len),st_1);

    // For expressions with value binding that can not determine type
		// e.g. size(x,2) when Real x[:,:]=fill(0.0,0,2); empty array with second dimension == 2, no way of 
		// knowing that from the value. Must investigate the expression itself.
    case (cache,env,exp,dim,impl,st,msg)
      local
        Values.Value v;
        DAE.Exp dim;
        list<Integer> adims;
        Integer i;
      equation
        (cache,Values.ARRAY({},adims),st_1) = ceval(cache,env, exp, impl, st, NONE, msg) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
				i = listNth(adims,dimv-1);
      then
        (cache,Values.INTEGER(i),st_1);

    case (cache,env,exp,dim,impl,st,msg)
      local
        Values.Value v;
        DAE.Exp dim;
      equation
        (cache,v,st_1) = ceval(cache,env, exp, impl, st, NONE, msg) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env, dim, impl, st, NONE, msg);
        v2 = cevalBuiltinSize2(v, dimv);
      then
        (cache,v2,st_1);
    case (cache,env,exp,dim,impl,st,MSG())
      local DAE.Exp dim;
      equation
        true = RTOpts.debugFlag("failtrace");
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
  outValue := matchcontinue (inValue,inInteger)
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
      DAE.Subscript sub;
      Option<DAE.Exp> eopt;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{DAE.CREF(componentRef = cr)},impl,st,msg)
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
  input DAE.ComponentRef inComponentRef;
  output Env.Cache outCache;
  output Integer outInteger;
algorithm
  (outCache,outInteger) :=
  matchcontinue (inCache,inEnv,inComponentRef)
    local
      Env.Env env;
      list<DAE.ComponentRef> cr_lst,cr_lst2,cr_totlst,crs;
      Integer res;
      DAE.ComponentRef cr;
      Env.Cache cache;
      Absyn.Path path;
      DAE.ComponentRef prefix,currentPrefix;
      Absyn.Ident currentPrefixIdent;
    case (cache,env ,cr)
      equation
        (env as (Env.FRAME(connectionSet = (crs,prefix))::_)) = Env.stripForLoopScope(env);
        cr_lst = Util.listSelect1(crs, cr, Exp.crefContainedIn);
        currentPrefixIdent= Exp.crefLastIdent(prefix);
        currentPrefix = DAE.CREF_IDENT(currentPrefixIdent,DAE.ET_OTHER(),{});
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp dim;
      list<DAE.Exp> matrices;
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
  input list<DAE.Exp> inExpExpLst;
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
      list<DAE.Exp> expl;
      list<Values.Value> retExp;
      list<Env.Frame> env;
      DAE.Exp dim;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
     	Env.Cache cache;
    case (cache,env,{dim},impl,st,msg)
      equation
        (cache,Values.INTEGER(dim_int),_) = ceval(cache,env, dim, impl, st, NONE, msg);
        dim_int_1 = dim_int + 1;
        expl = Util.listFill(DAE.ICONST(1), dim_int);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, DAE.ARRAY(DAE.ET_INT(),true,expl), impl, st, dim_int_1,
          1, {}, msg);
      then
        (cache,ValuesUtil.makeArray(retExp),st);
  end matchcontinue;
end cevalBuiltinIdentity;

protected function cevalBuiltinPromote "function: cevalBuiltinPromote
  author: PA
  Evaluates the internal promote operator, for promotion of arrays"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp arr,dim;
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
      Integer n_1,n,i;
      list<Values.Value> vs_1,vs;
      list<Integer> il;
    case (v,0) then Values.ARRAY({v},{1});
    case (Values.ARRAY(valueLst = vs, dimLst = i::_),n)
      equation
        n_1 = n - 1;
        (vs_1 as (Values.ARRAY(dimLst = il)::_)) = Util.listMap1(vs, cevalBuiltinPromote2, n_1);
      then
        Values.ARRAY(vs_1,i::il);
    case (_,_)
      equation
        Debug.fprintln("failtrace", "- Ceval.cevalBuiltinPromote2 failed");
      then fail();
  end matchcontinue;
end cevalBuiltinPromote2;


protected function cevalBuiltinString "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e)"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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

protected function cevalBuiltinLinspace "
  author: PA
  Evaluates the linpace function"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> st;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,st,inMsg)
      local
        DAE.Exp x,y,n; Integer size;
        Real rx,ry; list<Values.Value> valLst; Env.Cache cache; Boolean impl; Env.Env env; Msg msg;
    case (cache,env,{x,y,n},impl,st,msg) equation
      (cache,Values.INTEGER(size),_) = ceval(cache,env, n, impl, st, NONE, msg);
      verifyLinspaceN(size,{x,y,n});
      (cache,Values.REAL(rx),_) = ceval(cache,env, x, impl, st, NONE, msg);
      (cache,Values.REAL(ry),_) = ceval(cache,env, y, impl, st, NONE, msg);
      valLst = cevalBuiltinLinspace2(rx,ry,size,1);
    then (cache,ValuesUtil.makeArray(valLst),st);

  end matchcontinue;
end cevalBuiltinLinspace;

protected function verifyLinspaceN "checks that n>=2 for linspace(x,y,n) "
  input Integer n;
  input list<DAE.Exp> expl;
algorithm
  _ := matchcontinue(n,expl)
  local String s; DAE.Exp x,y,nx;
    case(n,_) equation
      true = n >= 2;
    then ();
    case(_,{x,y,nx}) equation
      s = "linspace("+&Exp.printExpStr(x)+&", "+&Exp.printExpStr(y)+&", "+&Exp.printExpStr(nx)+&")";
      Error.addMessage(Error.LINSPACE_ILLEGAL_SIZE_ARG,{s});
    then fail();
  end matchcontinue;
end verifyLinspaceN;

protected function cevalBuiltinLinspace2 "Helper function to cevalBuiltinLinspace"
  input Real rx;
  input Real ry;
  input Integer size;
  input Integer i "iterator 1 <= i <= size";
  output list<Values.Value> valLst;
algorithm
  valLst := matchcontinue(rx,ry,size,i)
  local Real r;
    case(rx,ry,size,i) equation
      true = i > size;
    then {};
    case(rx,ry,size,i) equation
      r = rx +. (ry -. rx)*. intReal(i-1) /. intReal(size - 1);
      valLst = cevalBuiltinLinspace2(rx,ry,size,i+1);
    then Values.REAL(r)::valLst;
  end matchcontinue;
end cevalBuiltinLinspace2;

protected function cevalBuiltinPrint "
  author: sjoelund
  Prints a String"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st, NONE, msg);
				print(str);
      then
        (cache,Values.NORETCALL,st);
  end matchcontinue;
end cevalBuiltinPrint;

protected function cevalIntReal
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(i),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        r = intReal(i);
      then
        (cache,Values.REAL(r),st);
  end matchcontinue;
end cevalIntReal;

protected function cevalIntString
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(i),st) = ceval(cache,env, exp, impl, st, NONE, msg);
        str = intString(i);
      then
        (cache,Values.STRING(str),st);
  end matchcontinue;
end cevalIntString;

protected function cevalRealInt
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(r),st) = ceval(cache,env, exp, impl, st, NONE, msg);
        i = realInt(r);
      then
        (cache,Values.INTEGER(i),st);
  end matchcontinue;
end cevalRealInt;

protected function cevalRealString
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(r),st) = ceval(cache,env, exp, impl, st, NONE, msg);
        str = realString(r);
      then
        (cache,Values.STRING(str),st);
  end matchcontinue;
end cevalRealString;

protected function cevalStringCharInt
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        i = stringCharInt(str);
      then
        (cache,Values.INTEGER(i),st);
  end matchcontinue;
end cevalStringCharInt;

protected function cevalIntStringChar
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.INTEGER(i),st) = ceval(cache,env, exp, impl, st, NONE, msg);
        str = intStringChar(i);
      then
        (cache,Values.STRING(str),st);
  end matchcontinue;
end cevalIntStringChar;

protected function cevalStringInt
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st, NONE, msg);
        i = stringInt(str);
      then
        (cache,Values.INTEGER(i),st);
  end matchcontinue;
end cevalStringInt;

protected function cevalStringListStringChar
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st, NONE, msg);
        chList = stringListStringChar(str);
        valList = Util.listMap(chList, generateValueString);
      then
        (cache,Values.LIST(valList),st);
  end matchcontinue;
end cevalStringListStringChar;

protected function generateValueString
  input String str;
  output Values.Value val;
algorithm
  val := Values.STRING(str);
end generateValueString;

protected function cevalListStringCharString
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
      Real r;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp, impl, st, NONE, msg);
        // Note that the RML version of the function has a weird name, but is also not implemented yet!
        // The work-around is to check that each String has length 1 and append all the Strings together
        // WARNING: This can be very, very slow for long lists - it grows as O(n^2)
        // TODO: When implemented, use listStringCharString (OMC name) or stringCharListString (RML name) directly
        chList = Util.listMap(valList, extractValueStringChar);
        str = Util.stringAppendList(chList);
      then
        (cache,Values.STRING(str),st);
  end matchcontinue;
end cevalListStringCharString;

protected function extractValueStringChar
  input Values.Value val;
  output String str;
algorithm
  str := matchcontinue (val)
    local String str;
    case Values.STRING(str) equation 1 = stringLength(str); then str;
  end matchcontinue;
end extractValueStringChar;

protected function cevalNoBoxUnbox
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Values.Value val;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,val,st) = ceval(cache,env, exp, impl, st, NONE, msg);
      then
        (cache,val,st);
  end matchcontinue;
end cevalNoBoxUnbox;

protected function cevalCat "function: cevalCat
  evaluates the cat operator given a list of
  array values and a concatenation dimension."
  input list<Values.Value> v_lst;
  input Integer dim;
  output Values.Value outValue;
  list<Values.Value> v_lst_1;
algorithm
  v_lst_1 := catDimension(v_lst, dim);
  outValue := ValuesUtil.makeArray(v_lst_1);
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
      Integer dim_1,len,dim,i1,i2;
      list<Integer> il;
    case (vlst,1) /* base case for first dimension */
      equation
        vlst_lst = Util.listMap(vlst, ValuesUtil.arrayValues);
        v_lst_1 = Util.listFlatten(vlst_lst);
      then
        v_lst_1;
    case (vlst,dim)
      equation
        v_lst_lst = Util.listMap(vlst, ValuesUtil.arrayValues);
        dim_1 = dim - 1;
        v_lst_lst_1 = catDimension2(v_lst_lst, dim_1);
        v_lst_1 = Util.listMap(v_lst_lst_1, ValuesUtil.makeArray);
        (Values.ARRAY(valueLst = vlst2, dimLst = i2::il) :: _) = v_lst_1;
        i1 = listLength(v_lst_1);
        v_lst_1 = cevalBuiltinTranspose2(v_lst_1, 1, i2::i1::il);
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinFloor;

protected function cevalBuiltinCeil "function cevalBuiltinCeil
  author: LP
  evaluates the ceil operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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

protected function cevalBuiltinLog10
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = System.log10(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinLog10;

protected function cevalBuiltinTan "function cevalBuiltinTan
  author: LP
  Evaluates the builtin tan function."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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

protected function cevalBuiltinAtan2
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      Real rv,rv_1,rv_2;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv_1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.REAL(rv_2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv = System.atan2(rv_1,rv_2);
      then
        (cache,Values.REAL(rv),st);
  end matchcontinue;
end cevalBuiltinAtan2;

protected function cevalBuiltinDiv "function cevalBuiltinDiv
  author: LP
  Evaluates the builtin div operator."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str,lh_str,rh_str;
      Env.Cache cache; Boolean b;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv_1 = rv1/.rv2;
        b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,System.realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv_1 = rv1/.rv2;
         b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,System.realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
        rv_1 = rv1/.rv2;
        b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,System.realCeil(rv_1),realFloor(rv_1));
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp1,exp2;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp arr,s1,s2;
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
        (Values.INTEGER(i2)) = cevalBuiltinMax2(ValuesUtil.makeArray(vls));
        res = intMax(i1, i2);
      then
        Values.INTEGER(res);
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      local Real i1,i2,res;
      equation
        (Values.REAL(i1)) = cevalBuiltinMax2(v1);
        (Values.REAL(i2)) = cevalBuiltinMax2(ValuesUtil.makeArray(vls));
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp arr,s1,s2;
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
        (Values.INTEGER(i2)) = cevalBuiltinMin2(ValuesUtil.makeArray(vls));
        res = intMin(i1, i2);
      then
        Values.INTEGER(res);
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      local Real i1,i2,res;
      equation
        (Values.REAL(i1)) = cevalBuiltinMin2(v1);
        (Values.REAL(i2)) = cevalBuiltinMin2(ValuesUtil.makeArray(vls));
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

protected function cevalBuiltinDifferentiate "function cevalBuiltinDifferentiate
  author: LP
  This function differentiates an equation: x^2 + x => 2x + 1"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp differentiated_exp,differentiated_exp_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      DAE.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp1,DAE.CREF(componentRef = cr)},impl,st,msg)
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp1_1,exp1;
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
  input list<DAE.Exp> inExpExpLst;
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
      Real rv1,rv2,rva,rva_1,rvb,rvd,dr;
      Integer rvai,ri,ri1,ri2,ri_1,di;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str;
      Env.Cache cache;
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
       (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg)
      equation
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st, NONE, msg);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
         (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st, NONE, msg);
       (cache,Values.INTEGER(di),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg);
       ri_1 = ri1 - ri2 * di;
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
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

protected function cevalBuiltinRooted
"function cevalBuiltinRooted
  author: adrpo
  Evaluates the builtin rooted operator from MultiBody"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,_,_) = ceval(cache, env, exp, impl, st, NONE, msg);
      then
        (cache,Values.BOOL(true),st);
  end matchcontinue;
end cevalBuiltinRooted;

protected function cevalBuiltinIntegerEnumeration "function cevalBuiltinIntegerEnumeration
  author: LP
  Evaluates the builtin Integer operator"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.ENUM(ri,_,_),_) = ceval(cache,env, exp, impl, st, NONE, msg);
      then
        (cache,Values.INTEGER(ri),st);
  end matchcontinue;
end cevalBuiltinIntegerEnumeration;

protected function cevalBuiltinDiagonal "function cevalBuiltinDiagonal
  This function generates a matrix{n,n} (A) of the vector {a,b,...,n}
  where the diagonal of A is the vector {a,b,...,n}
  ie A{1,1} == a, A{2,2} == b ..."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Values.Value res;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.ARRAY(rv2,{dimension}),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        correctDimension = dimension + 1;
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, exp, impl, st, correctDimension, 1, {}, msg);
        res = Values.ARRAY(retExp,{dimension,dimension});
      then
        (cache,res,st);
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
  input DAE.Exp inExp2;
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
      DAE.Exp s1,s2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String RowString,matrixDimensionString;
      Env.Cache cache;
      Values.Value v;
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, DAE.ASUB(s1,{s2}), impl, st, NONE, msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, {v}, msg);
      then
        (cache,retExp);
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, DAE.ASUB(s1,{s2}), impl, st, NONE, msg);

        failure(equality(matrixDimension = row));
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        appendedList = listAppend(listIN, {v});
        (cache,retExp)= cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, appendedList, msg);
      then
        (cache,retExp);
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg)
      local Integer rv2;
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.INTEGER(rv2),_) = ceval(cache,env, DAE.ASUB(s1,{s2}), impl, st, NONE, msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.INTEGER(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, {v}, msg);
      then
        (cache,retExp);

    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg)
      local Integer rv2;
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.INTEGER(rv2),_) = ceval(cache,env, DAE.ASUB(s1,{s2}), impl, st, NONE, msg);
        failure(equality(matrixDimension = row));

        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceAt(Values.INTEGER(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        appendedList = listAppend(listIN, {v});
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
        true = RTOpts.debugFlag("ceval");
        Debug.traceln("- Ceval.cevalBuiltinDiagonal2 failed");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal2;

protected function cevalBuiltinCross "
  x,y => {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      list<Values.Value> xv,yv;
      Values.Value res;
      list<Env.Frame> env;
      DAE.Exp xe,ye;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{xe,ye},impl,st,msg)
      equation
        (cache,Values.ARRAY(xv,{3}),_) = ceval(cache,env, xe, impl, st, NONE, msg);
        (cache,Values.ARRAY(yv,{3}),_) = ceval(cache,env, ye, impl, st, NONE, msg);
        res = ValuesUtil.crossProduct(xv,yv);
      then
        (cache,res,st);
    case (_,_,_,_,_,MSG())
      equation
        Print.printErrorBuf("#- Error, could not evaulate cross. Ceval.cevalBuiltinCross failed.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinCross;

protected function cevalBuiltinTranspose "function cevalBuiltinTranspose
  This function transposes the two first dimension of an array A."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
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
      Integer dim1,i1,i2;
      list<Integer> il;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg)
      equation
        (cache,Values.ARRAY(vlst,i1::_),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        (Values.ARRAY(valueLst = vlst2, dimLst = i2::il) :: _) = vlst;
        vlst_1 = cevalBuiltinTranspose2(vlst, 1, i2::i1::il);
      then
        (cache,Values.ARRAY(vlst_1,i2::i1::il),st);
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
  input list<Integer> inDims "dimension";
  output list<Values.Value> outValuesValueLst;
algorithm
  outValuesValueLst:=
  matchcontinue (inValuesValueLst1,inInteger2,inDims)
    local
      list<Values.Value> transposed_row,rest,vlst;
      Integer indx_1,indx,dim1;
    case (vlst,indx,inDims as (dim1::_))
      equation
        (indx <= dim1) = true;
        transposed_row = Util.listMap1(vlst, ValuesUtil.nthArrayelt, indx);
        indx_1 = indx + 1;
        rest = cevalBuiltinTranspose2(vlst, indx_1, inDims);
      then
        (Values.ARRAY(transposed_row,inDims) :: rest);
    case (_,_,_) then {};
  end matchcontinue;
end cevalBuiltinTranspose2;

protected function cevalBuiltinSizeMatrix "function: cevalBuiltinSizeMatrix
  Helper function for cevalBuiltinSize, for size(A) where A is a matrix."
	input Env.Cache inCache;
	input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      list<Integer> sizelst;
      Values.Value v;
      Env.Env env;
      DAE.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
      Exp.Exp exp;

    // size(cr)
    case (cache,env,DAE.CREF(componentRef = cr,ty = tp),impl,st,msg)
      equation
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        sizelst = Types.getDimensionSizes(tp);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v,st);
        
    // For matrix expressions: [1,2;3,4]
		case (cache, env, DAE.MATRIX(ty = DAE.ET_ARRAY(arrayDimensions = dims)), impl, st, msg)
			local
				list<Option<Integer>> dims;
			equation
				sizelst = Util.listMap(dims, Util.getOption);
				v = ValuesUtil.intlistToValue(sizelst);
			then
				(cache, v, st);
	  // For other matrix expressions e.g. on array form: {{1,2},{3,4}}
		case (cache,env,exp,impl,st,msg)
      equation
        (cache,v,st) = ceval(cache,env, exp, impl, st, NONE, msg);
        tp = Types.typeOfValue(v);
        sizelst = Types.getDimensionSizes(tp);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinSizeMatrix;

protected function cevalRelation "function: cevalRelation
  Performs the arithmetic relation check and gives a boolean result."
  input Values.Value inValue1;
  input DAE.Operator inOperator2;
  input Values.Value inValue3;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue1,inOperator2,inValue3)
    local
      Values.Value v,v1,v2;
      DAE.ExpType t;
      Boolean b,nb1,nb2,ba,bb,b1,b2;
      Integer i1,i2;
      String s1,s2;
      DAE.ComponentRef cr1, cr2;
      DAE.Operator op;

    case (v1,DAE.GREATER(ty = t),v2)
      equation
        v = cevalRelation(v2, DAE.LESS(t), v1);
      then
        v;

    /* Strings */
    case (Values.STRING(string = s1),DAE.LESS(ty = DAE.ET_STRING()),Values.STRING(string = s2))
      equation
        i1 = System.strcmp(s1,s2);
        b = (i1 < 0);
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),DAE.LESSEQ(ty = DAE.ET_STRING()),Values.STRING(string = s2))
      equation
        i1 = System.strcmp(s1,s2);
        b = (i1 <= 0);
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),DAE.GREATEREQ(ty = DAE.ET_STRING()),Values.STRING(string = s2))
      equation
        i1 = System.strcmp(s1,s2);
        b = (i1 >= 0);
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),DAE.EQUAL(ty = DAE.ET_STRING()),Values.STRING(string = s2))
      equation
        i1 = System.strcmp(s1,s2);
        b = (i1 == 0);
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),DAE.NEQUAL(ty = DAE.ET_STRING()),Values.STRING(string = s2))
      equation
        i1 = System.strcmp(s1,s2);
        b = (i1 <> 0);
      then
        Values.BOOL(b);
    case (Values.STRING(string = s1),DAE.EQUAL(ty = DAE.ET_STRING()),Values.STRING(string = s2))
      local
        String s1,s2;
      equation
        b = (s1 ==& s2);
      then
        Values.BOOL(b);

    /* Integers */
    case (Values.INTEGER(integer = i1),DAE.LESS(ty = DAE.ET_INT()),Values.INTEGER(integer = i2))
      equation
        b = (i1 < i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),DAE.LESSEQ(ty = DAE.ET_INT()),Values.INTEGER(integer = i2))
      equation
        b = (i1 <= i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),DAE.GREATEREQ(ty = DAE.ET_INT()),Values.INTEGER(integer = i2))
      equation
        b = (i1 >= i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),DAE.EQUAL(ty = DAE.ET_INT()),Values.INTEGER(integer = i2))
      equation
        b = (i1 == i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),DAE.NEQUAL(ty = DAE.ET_INT()),Values.INTEGER(integer = i2))
      equation
        b = (i1 <> i2);
      then
        Values.BOOL(b);

    /* Reals */
    case (Values.REAL(real = i1),DAE.LESS(ty = DAE.ET_REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation
        b = (i1 <. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),DAE.LESSEQ(ty = DAE.ET_REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation
        b = (i1 <=. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),DAE.GREATEREQ(ty = DAE.ET_REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation
        b = (i1 >=. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),DAE.EQUAL(ty = DAE.ET_REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation
        b = (i1 ==. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),DAE.NEQUAL(ty = DAE.ET_REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation
        b = (i1 <>. i2);
      then
        Values.BOOL(b);

    /* Booleans */
    case (Values.BOOL(boolean = b1),DAE.NEQUAL(ty = DAE.ET_BOOL()),Values.BOOL(boolean = b2))
      equation
        nb1 = boolNot(b1) "b1 != b2  == (b1 and not b2) or (not b1 and b2)" ;
        nb2 = boolNot(b2);
        ba = boolAnd(b1, nb2);
        bb = boolAnd(nb1, b2);
        b = boolOr(ba, bb);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = b1),DAE.EQUAL(ty = DAE.ET_BOOL()),Values.BOOL(boolean = b2))
      equation
        nb1 = boolNot(b1) "b1 == b2  ==> b1 and b2 or (not b1 and not b2)" ;
        nb2 = boolNot(b2);
        ba = boolAnd(b1, b2);
        bb = boolAnd(nb1, nb2);
        b = boolOr(ba, bb);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = false),DAE.LESS(ty = DAE.ET_BOOL()),Values.BOOL(boolean = true)) then Values.BOOL(true);
    case (Values.BOOL(boolean = _),DAE.LESS(ty = DAE.ET_BOOL()),Values.BOOL(boolean = _)) then Values.BOOL(false);

    /* Enumerations */
    case (Values.ENUM(index = i1),DAE.LESS(ty = DAE.ET_ENUMERATION(index = SOME(_))),Values.ENUM(index = i2))
//    case (Values.ENUM(cr1,i1),DAE.LESS(ty = Exp.ENUM()),Values.ENUM(cr2,i2))
      equation
        b = (i1 < i2);
      then
        Values.BOOL(b);
    case (Values.ENUM(index = i1),DAE.LESSEQ(ty = DAE.ET_ENUMERATION(index = SOME(_))),Values.ENUM(index = i2))
//    case (Values.ENUM(cr1,i1),DAE.LESSEQ(ty = Exp.ENUM()),Values.ENUM(cr2,i2))
      equation
        b = (i1 <= i2);
      then
        Values.BOOL(b);
    case (Values.ENUM(index = i1),DAE.GREATEREQ(ty = DAE.ET_ENUMERATION(index = SOME(_))),Values.ENUM(index = i2))
//    case (Values.ENUM(cr1,i1),DAE.GREATEREQ(ty = Exp.ENUM()),Values.ENUM(cr2,i2))
      equation
        b = (i1 >= i2);
      then
        Values.BOOL(b);
    case (Values.ENUM(index = i1),DAE.EQUAL(ty = DAE.ET_ENUMERATION(index = SOME(_))),Values.INTEGER(i2))
      equation
        bb = (i1 == i2);
      then
        Values.BOOL(bb);
    case (Values.ENUM(index = i1),DAE.EQUAL(ty = DAE.ET_ENUMERATION(index = SOME(_))),Values.ENUM(index = i2))
//    case (Values.ENUM(cr1,i1),DAE.EQUAL(ty = Exp.ENUM()),Values.ENUM(cr2,i2))
      equation
        // Why is this not performed for less or grater?
        // ba = Exp.crefEqual(cr1, cr2);
        bb = (i1 == i2);
        // b = boolAnd(ba, bb);
      then
        Values.BOOL(bb);
    case (Values.ENUM(index = i1),DAE.NEQUAL(ty = DAE.ET_ENUMERATION(index = SOME(_))),Values.ENUM(index = i2))
//    case (Values.ENUM(cr1,i1),DAE.NEQUAL(ty = Exp.ENUM()),Values.ENUM(cr2,i2))
      equation
        // ba = boolNot(Exp.crefEqual(cr1, cr2));
        bb = (i1 <> i2);
        // b = boolAnd(ba, bb);
      then
        Values.BOOL(bb);

    case (v1,op,v2)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Ceval.cevalRelation failed on: " +&
               ValuesUtil.printValStr(v1) +&
               Exp.binopSymbol(op) +&
               ValuesUtil.printValStr(v2));
      then
        fail();
  end matchcontinue;
end cevalRelation;

public function cevalRange "function: cevalRange
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
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      list<Values.Value> vs;
      list<DAE.Exp> exps;
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
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,inMsg)
    local
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Binding binding;
      Values.Value v;
      list<Env.Frame> env;
      DAE.ComponentRef c;
      Boolean impl;
      Msg msg;
      String scope_str,str;
      Env.Cache cache;
      DAE.ExpType expTy;
			Option<DAE.Const> const_for_range;

		// Enumeration -> no lookup necessary
		case (cache, env, c, impl, msg)
			local
				Absyn.Path path;
				Integer idx;
				list<String> names;
			equation
				DAE.ET_ENUMERATION(SOME(idx), _, names, {}) = Exp.getEnumTypefromCref(c);
				path = Exp.crefToPath(c);
			then
				(cache, Values.ENUM(idx, path, names));

		// Try to lookup the variables binding and constant evaluate it.
		case (cache, env, c, impl, msg)
			equation
				(cache, _, _, binding, const_for_range, _, _, _) = Lookup.lookupVar(cache, env, c);
				(cache, v) = cevalCref2(cache, env, c, binding, const_for_range, impl, msg);
			then
				(cache, v);

    // failure in lookup and we have the MSG go-ahead to print the error
    case (cache,env,c,(impl as false),MSG())
      equation
        failure((_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
        scope_str = Env.printEnvPathStr(env);
        str = Exp.printComponentRefStr(c);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {str,scope_str});
      then
        fail();
    
    // failure in lookup but NO_MSG, silently fail and move along
    case (cache,env,c,(impl as false),NO_MSG())
      equation
        failure((_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
      then
        fail();
  end matchcontinue;
end cevalCref;

public function cevalCref2
	"Helper function to cevalCref2"
	input Env.Cache inCache;
	input Env.Env inEnv;
	input DAE.ComponentRef inCref;
	input DAE.Binding inBinding;
	input Option<DAE.Const> constForRange;
	input Boolean inImpl;
	input Msg inMsg;
	output Env.Cache outCache;
	output Values.Value outValue;
algorithm
	(outCache, outValue) := matchcontinue(inCache, inEnv, inCref, inBinding, constForRange, inImpl, inMsg)
		local
			Env.Cache cache;
			Values.Value v;

		// A variable with no binding and SOME for range constness -> a for iterator
		case (_, _, _, DAE.UNBOUND(), SOME(_), _, _) then fail();

		// A variable without a binding -> error
		case (_, _, _, DAE.UNBOUND(), NONE(), false, MSG())
			local
				String str, scope_str;
			equation
				str = Exp.printComponentRefStr(inCref);
				scope_str = Env.printEnvPathStr(inEnv);
				Error.addMessage(Error.NO_CONSTANT_BINDING, {str, scope_str});
				Debug.fprintln("ceval", "- Ceval.cevalCref on: " +& str +& 
					" failed with no constant binding in scope: " +& scope_str);
			then
				fail();

		// A variable with a binding -> constant evaluate the binding
		case (_, _, _, _, _, _, _)
			equation
				failure(equality(inBinding = DAE.UNBOUND()));
				false = crefEqualValue(inCref, inBinding);
				(cache, v) = cevalCrefBinding(inCache, inEnv, inCref, inBinding, inImpl, inMsg);
			then
				(cache, v);
	end matchcontinue;	
end cevalCref2;

public function cevalCrefBinding "function: cevalCrefBinding
  Helper function to cevalCref.
  Evaluates variables by evaluating their bindings."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.Binding inBinding;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inComponentRef,inBinding,inBoolean,inMsg)
    local
      DAE.ComponentRef cr_1,cr,e1;
      list<DAE.Subscript> subsc;
      tuple<DAE.TType, Option<Absyn.Path>> tp;
      list<Integer> sizelst;
      Values.Value res,v,e_val;
      list<Env.Frame> env;
      Boolean impl;
      Msg msg;
      String rfn,iter,id,expstr,s1,s2,str;
      DAE.Exp elexp,iterexp,exp;
      Env.Cache cache;

    case (cache,env,cr,DAE.VALBOUND(valBound = v),impl,msg) /* DAE.CREF_IDENT(id,subsc) */ 
      equation 
        Debug.fprint("tcvt", "+++++++ Ceval.cevalCrefBinding DAE.VALBOUND\n");
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr_1) "DAE.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);

    case (cache,env,_,DAE.UNBOUND(),(impl as false),MSG()) then fail();

    case (cache,env,_,DAE.UNBOUND(),(impl as true),MSG())
      equation
        Debug.fprint("ceval", "#- Ceval.cevalCrefBinding: Ignoring unbound when implicit");
      then
        fail();

    // REDUCTION bindings  
    case (cache,env,DAE.CREF_IDENT(ident = id,subscriptLst = subsc),DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,MSG()) 
      equation 
        DAE.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        equality(rfn = "array");
        Debug.fprintln("ceval", "#- Ceval.cevalCrefBinding: Array evaluation");
      then
        fail();

    // REDUCTION bindings DAE.CREF_IDENT(id,subsc) 
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg) 
      equation 
        DAE.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        failure(equality(rfn = "array"));
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "DAE.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache, env, exp, impl, NONE, NONE, msg);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);
        
    // arbitrary expressions, C_VAR, value exists. DAE.CREF_IDENT(id,subsc)
    case (cache,env,cr,DAE.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = DAE.C_VAR()),impl,msg) 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "DAE.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, e_val, sizelst, impl, msg);
      then
        (cache,res);

    // arbitrary expressions, C_PARAM, value exists. DAE.CREF_IDENT(id,subsc) 
    case (cache,env,cr,DAE.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = DAE.C_PARAM()),impl,msg) 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "DAE.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res)= cevalSubscriptValue(cache,env, subsc, e_val, sizelst, impl, msg);
      then
        (cache,res);

    // arbitrary expressions. When binding has optional value. DAE.CREF_IDENT(id,subsc)
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg)
      equation
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "DAE.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache,env, exp, impl, NONE, NONE, msg);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);

    // arbitrary expressions. When binding has optional value. DAE.CREF_IDENT(id,subsc) 
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_PARAM()),impl,msg) 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1) "DAE.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache, env, exp, impl, NONE, NONE, msg);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);

    // if the binding has constant-ness DAE.C_VAR we cannot constant evaluate.
    case (cache,env,_,DAE.EQBOUND(exp = exp,constant_ = DAE.C_VAR()),impl,MSG())
      equation
				true = RTOpts.debugFlag("ceval");
        Debug.fprint("ceval", "#- Ceval.cevalCrefBinding failed (nonconstant EQBOUND(");
        expstr = Exp.printExpStr(exp);
        Debug.fprint("ceval", expstr);
        Debug.fprintln("ceval", "))");
      then
        fail();

    case (cache,env,e1,inBinding,_,_)
      equation
        true = RTOpts.debugFlag("ceval");
        s1 = Exp.printComponentRefStr(e1);
        s2 = Types.printBindingStr(inBinding);
        str = Env.printEnvPathStr(env);
        str = Util.stringAppendList({"- Ceval.cevalCrefBinding: ", 
                s1, " = [", s2, "] in env:", str, " failed\n"});
        Debug.fprint("ceval", str);
      then
        fail();
  end matchcontinue;
end cevalCrefBinding;

protected function cevalSubscriptValue "function: cevalSubscriptValue
  Helper function to cevalCrefBinding. It applies
  subscripts to array values to extract array elements."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
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
      DAE.Exp exp;
      list<DAE.Subscript> subs;
      list<Values.Value> lst,sliceLst,subvals;
      list<Integer> dims,slice;
      Boolean impl;
      Msg msg;
      Env.Cache cache;

    // we have a subscript which is an index, try to constant evaluate it
    case (cache,env,(DAE.INDEX(exp = exp) :: subs),Values.ARRAY(valueLst = lst),(dim :: dims),impl,msg)
      equation
        (cache,Values.INTEGER(n),_) = ceval(cache, env, exp, impl, NONE, SOME(dim), msg);
        n_1 = n - 1;
        subval = listNth(lst, n_1);
        (cache,res) = cevalSubscriptValue(cache, env, subs, subval, dims, impl, msg);
      then
        (cache,res);
    case (cache,env,(DAE.SLICE(exp = exp) :: subs),Values.ARRAY(valueLst = lst),(dim :: dims),impl,msg)
      equation
        (cache,subval as Values.ARRAY(valueLst = sliceLst),_) = ceval(cache, env, exp, impl, NONE, SOME(dim), msg);
        slice = Util.listMap(sliceLst, ValuesUtil.valueIntegerMinusOne);
        subvals = Util.listMap1r(slice, listNth, lst);
        (cache,lst) = cevalSubscriptValueList(cache,env, subs, subvals, dims, impl, msg);
        res = ValuesUtil.makeArray(lst);
      then
        (cache,res);

    // we have no subscripts but we have a value, return it
    case (cache,env,{},v,_,_,_) then (cache,v); 

    // failtrace
    case (_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- Ceval.cevalSubscriptValue failed\n");
      then
        fail();
  end matchcontinue;
end cevalSubscriptValue;

protected function cevalSubscriptValueList "Applies subscripts to array values to extract array elements."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
  input list<Values.Value> inValue;
  input list<Integer> inIntegerLst "dimension sizes";
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Values.Value> outValue;
algorithm
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inExpSubscriptLst,inValue,inIntegerLst,inBoolean,inMsg)
    local
      Values.Value subval,res;
      list<Env.Frame> env;
      list<Values.Value> lst,subvals;
      Boolean impl;
      Msg msg;
      list<Integer> dims;
      list<DAE.Subscript> subs;
      Env.Cache cache;
    case (cache,env,subs,{},dims,impl,msg) then (cache,{});
    case (cache,env,subs,subval::subvals,dims,impl,msg)
      equation
        (cache,res) = cevalSubscriptValue(cache,env, subs, subval, dims, impl, msg);
        (cache,lst) = cevalSubscriptValueList(cache,env, subs, subvals, dims, impl, msg);
      then
        (cache,res::lst);
  end matchcontinue;
end cevalSubscriptValueList;

public function cevalSubscripts "function: cevalSubscripts
  This function relates a list of subscripts to their canonical
  forms, which is when all expressions are evaluated to constant
  values. For instance
  the subscript list {1,p,q} (as in x[1,p,q]) where p and q have constant values 2,3 respectively will become
  {1,2,3} (resulting in x[1,2,3])."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  (outCache,outExpSubscriptLst) :=
  matchcontinue (inCache,inEnv,inExpSubscriptLst,inIntegerLst,inBoolean,inMsg)
    local
      DAE.Subscript sub_1,sub;
      list<DAE.Subscript> subs_1,subs;
      list<Env.Frame> env;
      Integer dim;
      list<Integer> dims;
      Boolean impl;
      Msg msg;
      Env.Cache cache;

    // empty case
    case (cache,_,{},_,_,_) then (cache,{}); 

    // we have subscripts
    case (cache,env,(sub :: subs),(dim :: dims),impl,msg)
      equation
        (cache,sub_1) = cevalSubscript(cache, env, sub, dim, impl, msg);
        (cache,subs_1) = cevalSubscripts(cache, env, subs, dims, impl, msg);
      then
        (cache,sub_1 :: subs_1);
  end matchcontinue;
end cevalSubscripts;

public function cevalSubscript "function: cevalSubscript
  This function relates a subscript to its canonical forms, which
  is when all expressions are evaluated to constant values."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Subscript inSubscript;
  input Integer inInteger;
  input Boolean inBoolean "impl";
  input Msg inMsg;
  output Env.Cache outCache;
  output DAE.Subscript outSubscript;
algorithm
  (outCache,outSubscript) :=
  matchcontinue (inCache,inEnv,inSubscript,inInteger,inBoolean,inMsg)
    local
      list<Env.Frame> env;
      Values.Value v1;
      DAE.Exp e1_1,e1;
      Integer dim;
      Boolean impl;
      Msg msg;
      Env.Cache cache;
      Integer indx;

    // the entire dimension, nothing to do
    case (cache,env,DAE.WHOLEDIM(),_,_,_) then (cache,DAE.WHOLEDIM());
      
    // an expression index that can be constant evaluated
    case (cache,env,DAE.INDEX(exp = e1),dim,impl,msg)
      equation
        (cache,v1 as Values.INTEGER(indx),_) = ceval(cache,env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
        true = indx <= dim;
      then
        (cache,DAE.INDEX(e1_1));

    // indexing using enum! 
    case (cache,env,DAE.INDEX(exp = e1),dim,impl,msg)
      equation
        (cache,v1 as Values.ENUM(index = indx),_) = ceval(cache,env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
        true = indx <= dim;
      then
        (cache,DAE.INDEX(e1_1));

    // an expression slice that can be constant evaluated
    case (cache,env,DAE.SLICE(exp = e1),dim,impl,msg)
      equation
        (cache,v1,_) = ceval(cache,env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
        true = dimensionSliceInRange(v1,dim);
      then
        (cache,DAE.SLICE(e1_1));
  end matchcontinue;
end cevalSubscript;

public function getValueString "
Constant evaluates Expression and returns a string representing value.
"
  input DAE.Exp e1;
  output String ostring;
algorithm ostring := matchcontinue( e1)
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val as Values.STRING(ret),_) = ceval(Env.emptyCache(),Env.emptyEnv, e1,true,NONE,NONE,MSG());
    then
      ret;
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val,_) = ceval(Env.emptyCache(),Env.emptyEnv, e1,true,NONE,NONE,MSG());
      ret = ValuesUtil.printValStr(val);
    then
      ret;

end matchcontinue;
end getValueString;


protected function cevalTuple
  input list<DAE.Exp> inexps;
  output list<Values.Value> oval;
algorithm oval := matchcontinue(inexps)
  case({}) then {};
case(e ::expl)
  local
    DAE.Exp e;
    list<DAE.Exp> expl;
    Values.Value v;
    list<Values.Value> vs;
  equation
    (_,v,_) = ceval(Env.emptyCache(), Env.emptyEnv, e,true,NONE,NONE,MSG);
    vs = cevalTuple(expl);
  then
    v::vs;
end matchcontinue;
end cevalTuple;

protected function crefEqualValue ""
  input DAE.ComponentRef c;
  input DAE.Binding v;
  output Boolean outBoolean;
algorithm outBoolean := matchcontinue(c,v)
  case(c,(v as DAE.EQBOUND(DAE.CREF(c2,_),NONE,_)))
    local DAE.ComponentRef c2;
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
    local
      Integer indx,dim;
      list<Values.Value> vlst;
      list<Integer> dims;
    case(Values.ARRAY(valueLst = {}),_) then true;
    case(Values.ARRAY(valueLst = Values.INTEGER(indx)::vlst, dimLst = dim::dims),dimSize) equation
      dim = dim-1;
      dims = dim::dims;
      true = indx <= dimSize;
      true = dimensionSliceInRange(Values.ARRAY(vlst,dims),dimSize);
    then true;
    case(_,_) then false;
  end matchcontinue;
end dimensionSliceInRange;

protected function cevalReduction
	"Help function to ceval. Evaluates reductions calls, such as
		'sum(i for i in 1:5)'"
	input Env.Cache cache;
	input Env.Env env;
	input ReductionOperator op;
	input DAE.Exp exp;
	input DAE.Ident iteratorName;
	input list<Values.Value> values;
	input Boolean implicitInstantiation;
	input Option<Interactive.InteractiveSymbolTable> symbolTable;
	input Option<Integer> dim;
	input Msg msg;
	output Env.Cache newCache;
	output Values.Value result;
	output Option<Interactive.InteractiveSymbolTable> newSymbolTable;

	partial function ReductionOperator
		input Values.Value v1;
		input Values.Value v2;
		output Values.Value res;
	end ReductionOperator;
algorithm
	(newCache, result, newSymbolTable) := matchcontinue(cache, env, op,
		exp, iteratorName, values, implicitInstantiation, symbolTable, dim, msg)
		local
			Values.Value value, value2, reduced_value;
			list<Values.Value> rest_values;
			Env.Env new_env;
			Env.Cache new_cache;
			Option<Interactive.InteractiveSymbolTable> new_st;
		case (new_cache, new_env, _, _, _, value :: {}, _, new_st, _, _)
			equation
			  // range is constant!
				new_env = Env.extendFrameForIterator(env, iteratorName, DAE.T_INTEGER_DEFAULT, DAE.VALBOUND(value), SCode.VAR(), SOME(DAE.C_CONST()));
				(new_cache, value, new_st) = ceval(new_cache, new_env, exp,
					implicitInstantiation, new_st, dim, msg);
				then (new_cache, value, new_st);
		case (new_cache, new_env, _, _, _, value :: rest_values, _, new_st, _, _)
			equation
			  // range is constant!
				(new_cache, value2, new_st) = cevalReduction(new_cache, new_env, op, exp, 
					iteratorName, rest_values, implicitInstantiation, new_st, dim, msg);
				new_env = Env.extendFrameForIterator(new_env, iteratorName, DAE.T_INTEGER_DEFAULT, DAE.VALBOUND(value), SCode.VAR(), SOME(DAE.C_CONST()));
				(new_cache, value, new_st) = ceval(new_cache, new_env, exp,
					implicitInstantiation, new_st, dim, msg);
				reduced_value = op(value, value2);
			then (cache, reduced_value, new_st);
	end matchcontinue;
end cevalReduction;

protected function valueAdd
	"Adds two Values. Used (indirectly) by cevalReduction."
	input Values.Value v1;
	input Values.Value v2;
	output Values.Value res;
algorithm
	res := matchcontinue(v1, v2)
		case (Values.INTEGER(i1), Values.INTEGER(i2))
			local Integer i1, i2, res;
			equation res = i1 + i2; then Values.INTEGER(res);
		case (Values.REAL(r1), Values.REAL(r2))
			local Real r1, r2, res;
			equation res = r1 +. r2; then Values.REAL(res);
	end matchcontinue;
end valueAdd;

protected function valueMul
	"Multiplies two Values. Used (indirectly) by cevalReduction."
	input Values.Value v1;
	input Values.Value v2;
	output Values.Value res;
algorithm
	res := matchcontinue(v1, v2)
		case (Values.INTEGER(i1), Values.INTEGER(i2))
			local Integer i1, i2, res;
			equation res = i1 * i2; then Values.INTEGER(res);
		case (Values.REAL(r1), Values.REAL(r2))
			local Real r1, r2, res;
			equation res = r1 *. r2; then Values.REAL(res);
	end matchcontinue;
end valueMul;

protected function valueMax
	"Returns the maximum of two Values. Used (indirectly) by cevalReduction."
	input Values.Value v1;
	input Values.Value v2;
	output Values.Value res;
algorithm
	res := matchcontinue(v1, v2)
		case (Values.INTEGER(i1), Values.INTEGER(i2))
			local Integer i1, i2, res;
			equation res = intMax(i1, i2); then Values.INTEGER(res);
		case (Values.REAL(r1), Values.REAL(r2))
			local Real r1, r2, res;
			equation res = realMax(r1, r2); then Values.REAL(res);
	end matchcontinue;
end valueMax;

protected function valueMin
	"Returns the minimum of two Values. Used (indirectly) by cevalReduction."
	input Values.Value v1;
	input Values.Value v2;
	output Values.Value res;
algorithm
	res := matchcontinue(v1, v2)
		case (Values.INTEGER(i1), Values.INTEGER(i2))
			local Integer i1, i2, res;
			equation res = intMin(i1, i2); then Values.INTEGER(res);
		case (Values.REAL(r1), Values.REAL(r2))
			local Real r1, r2, res;
			equation res = realMin(r1, r2); then Values.REAL(res);
	end matchcontinue;
end valueMin;

protected function lookupReductionOp
	"Looks up a reduction function based on it's name."
	input DAE.Ident reductionName;
	output ReductionOperator op;

	partial function ReductionOperator
		input Values.Value v1;
		input Values.Value v2;
		output Values.Value res;
	end ReductionOperator;
algorithm
	op := matchcontinue(reductionName)
		case "max" then valueMax;
		case "min" then valueMin;
		case "product" then valueMul;
		case "sum" then valueAdd;
	end matchcontinue;
end lookupReductionOp;


// ************************************************************************
//    hash table implementation for storing function pointes for DLLs/SOs
// ************************************************************************
constant Option<CevalHashTable> cevalHashTable = NONE();

public
type Key = Absyn.Path "the function path";
type Value = Interactive.CompiledCFunction "the compiled function";

public function hashFunc
"author: PA
  Calculates a hash value for Absyn.Path"
  input Absyn.Path p;
  output Integer res;
algorithm
  res := System.hash(Absyn.pathString(p));
end hashFunc;

public function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := stringEqual(Absyn.pathString(key1),Absyn.pathString(key2));
end keyEqual;

public function dumpCevalHashTable ""
  input CevalHashTable t;
algorithm
  print("CevalHashTable:\n");
  print(Util.stringDelimitList(Util.listMap(hashTableList(t),dumpTuple),"\n"));
  print("\n");
end dumpCevalHashTable;

public function dumpTuple
  input tuple<Key,Value> tpl;
  output String str;
algorithm
  str := matchcontinue(tpl)
    local
      Absyn.Path p; Interactive.CompiledCFunction i;
    case((p,i)) equation
      str = "{" +& Absyn.pathString(p) +& ", OPAQUE_VALUE}";
    then str;
  end matchcontinue;
end dumpTuple;

/* end of CevalHashTable instance specific code */

/* Generic hashtable code below!! */
public
uniontype CevalHashTable
  record HASHTABLE
    list<tuple<Key,Integer>>[:] hashTable " hashtable to translate Key to array indx" ;
    ValueArray valueArr "Array of values" ;
    Integer bucketSize "bucket size" ;
    Integer numberOfEntries "number of entries in hashtable" ;
  end HASHTABLE;
end CevalHashTable;

uniontype ValueArray
"array of values are expandable, to amortize the
 cost of adding elements in a more efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable" ;
    Integer arrSize "size of crefArray" ;
    Option<tuple<Key,Value>>[:] valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

public function cloneCevalHashTable
"Author BZ 2008-06
 Make a stand-alone-copy of hashtable."
input CevalHashTable inHash;
output CevalHashTable outHash;
algorithm outHash := matchcontinue(inHash)
  local
    list<tuple<Key,Integer>>[:] arg1,arg1_2;
    Integer arg3,arg4,arg3_2,arg4_2,arg21,arg21_2,arg22,arg22_2;
    Option<tuple<Key,Value>>[:] arg23,arg23_2;
  case(HASHTABLE(arg1,VALUE_ARRAY(arg21,arg22,arg23),arg3,arg4))
    equation
      arg1_2 = arrayCopy(arg1);
      arg21_2 = arg21;
      arg22_2 = arg22;
      arg23_2 = arrayCopy(arg23);
      arg3_2 = arg3;
      arg4_2 = arg4;
      then
        HASHTABLE(arg1_2,VALUE_ARRAY(arg21_2,arg22_2,arg23_2),arg3_2,arg4_2);
end matchcontinue;
end cloneCevalHashTable;

public function emptyCevalHashTable
"author: PA
  Returns an empty CevalHashTable.
  Using the bucketsize 100 and array size 10."
  output CevalHashTable hashTable;
  list<tuple<Key,Integer>>[:] arr;
  list<Option<tuple<Key,Value>>> lst;
  Option<tuple<Key,Value>>[:] emptyarr;
algorithm
  arr := fill({}, 1000);
  emptyarr := fill(NONE(), 100);
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,100,emptyarr),1000,0);
end emptyCevalHashTable;

public function isEmpty "Returns true if hashtable is empty"
  input CevalHashTable hashTable;
  output Boolean res;
algorithm
  res := matchcontinue(hashTable)
    case(HASHTABLE(_,_,_,0)) then true;
    case(_) then false;
  end matchcontinue;
end isEmpty;

public function add
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input CevalHashTable hashTable;
  output CevalHashTable outHahsTable;
algorithm
  outVariables:=
  matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);

      /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation
        print("-CevalHashTable.add failed\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input CevalHashTable hashTable;
  output CevalHashTable outHahsTable;
algorithm
  outVariables := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
    // Adding when not existing previously
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
    case (_,_)
      equation
        print("-CevalHashTable.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function delete
"author: PA
  delete the Value associatied with Key from the CevalHashTable.
  Note: This function does not delete from the index table, only from the ValueArray.
  This means that a lot of deletions will not make the CevalHashTable more compact, it
  will still contain a lot of incices information."
  input Key key;
  input CevalHashTable hashTable;
  output CevalHashTable outHahsTable;
algorithm
  outVariables := matchcontinue (key,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
    // adding when already present => Updating value
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        indx_1 = indx - 1;
        varr_1 = valueArrayClearnth(varr, indx);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,hashTable)
      equation
        print("-CevalHashTable.delete failed\n");
        print("content:"); dumpCevalHashTable(hashTable);
      then
        fail();
  end matchcontinue;
end delete;

public function get
"author: PA
  Returns a Value given a Key and a CevalHashTable."
  input Key key;
  input CevalHashTable hashTable;
  output Value value;
algorithm
  (value,_):= get1(key,hashTable);
end get;

public function get1 "help function to get"
  input Key key;
  input CevalHashTable hashTable;
  output Value value;
  output Integer indx;
algorithm
  (value,indx):= matchcontinue (key,hashTable)
    local
      Integer hval,hashindx,indx,indx_1,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;
      list<tuple<Key,Integer>>[:] hashvec;
      ValueArray varr;
      Key key2;
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        v = valueArrayNth(varr, indx);
      then
        (v,indx);
  end matchcontinue;
end get1;

public function get2
"author: PA
  Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm
  index := matchcontinue (key,keyIndices)
    local
      Key key2;
      Value res;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _))
      equation
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs))
      equation
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;

public function hashTableValueList "return the Value entries as a list of Values"
  input CevalHashTable hashTable;
  output list<Value> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple22);
end hashTableValueList;

public function hashTableKeyList "return the Key entries as a list of Keys"
  input CevalHashTable hashTable;
  output list<Key> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple21);
end hashTableKeyList;

public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input CevalHashTable hashTable;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue(hashTable)
  local ValueArray varr;
    case(HASHTABLE(valueArr = varr)) equation
      tplLst = valueArrayList(varr);
    then tplLst;
  end matchcontinue;
end hashTableList;

public function valueArrayList
"author: PA
  Transforms a ValueArray to a tuple<Key,Value> list"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue (valueArray)
    local
      Option<tuple<Key,Value>>[:] arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    case (VALUE_ARRAY(numberOfElements = 0,valueArray = arr)) then {};
    case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr))
      equation
        lastpos = n - 1;
        lst = valueArrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end valueArrayList;

public function valueArrayList2 "Helper function to valueArrayList"
  input Option<tuple<Key,Value>>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<tuple<Key,Value>> outVarLst;
algorithm
  outVarLst := matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      tuple<Key,Value> v;
      Option<tuple<Key,Value>>[:] arr;
      Integer pos,lastpos,pos_1;
      list<tuple<Key,Value>> res;
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        NONE = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (res);
  end matchcontinue;
end valueArrayList2;

public function valueArrayLength
"author: PA
  Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer size;
algorithm
  size := matchcontinue (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size;
  end matchcontinue;
end valueArrayLength;

public function valueArrayAdd
"function: valueArrayAdd
  author: PA
  Adds an entry last to the ValueArray, increasing
  array size if no space left by factor 1.4"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      Option<tuple<Key,Value>>[:] arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,size,arr_1);

    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*.0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE);
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation
        print("-CevalHashTable.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth
"function: valueArraySetnth
  author: PA
  Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,pos,entry)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;
    case (VALUE_ARRAY(n,size,arr),pos,entry)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_,_)
      equation
        print("-CevalHashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth
"author: PA
  Clears the n:th variable in the ValueArray (set to NONE)."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,pos)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;
    case (VALUE_ARRAY(n,size,arr),pos)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, NONE);
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_)
      equation
        print("-CevalHashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth
"function: valueArrayNth
  author: PA
  Retrieve the n:th Vale from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Value value;
algorithm
  value := matchcontinue (valueArray,pos)
    local
      Value v;
      Integer n,pos,len;
      Option<tuple<Key,Value>>[:] arr;
      String ps,lens,ns;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        SOME((_,v)) = arr[pos + 1];
      then
        v;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        NONE = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;

end Ceval;

