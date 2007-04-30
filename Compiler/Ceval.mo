package Ceval "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
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

  
  file:	 Ceval.mo
  module:      Ceval
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
 	e.g. from mosh
 	
  Output:
 	Value: The evaluated value
      InteractiveSymbolTable: Modified symbol table
      Subscript list : Evaluates subscripts and generates constant expressions. 
"

public import Env;
public import Exp;
public import Interactive;
public import Values;
public import DAELow;
public import Absyn;
public import Types;

public 
uniontype Msg
  record MSG "Give error message" end MSG;

  record NO_MSG "Do not give error message" end NO_MSG;

end Msg;

protected import SimCodegen;
protected import Static;
protected import Print;
protected import ModUtil;
protected import System;
protected import SCode;
protected import Inst;
protected import Lookup;
protected import Dump;
protected import DAE;
protected import Debug;
protected import Util;
protected import ClassInf;
protected import RTOpts;
protected import Parser;
protected import Prefix;
protected import Codegen;
protected import ClassLoader;
protected import Derive;
protected import Connect;
protected import Error;
protected import Settings;
protected import Refactor;


protected function cevalBuiltin "function: cevalBuiltin
 
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
      Absyn.Path funcpath;
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
    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = id),expLst = args,builtin = builtin),impl,st,_,msg) /* buildin: as true */ 
      equation 
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

protected function cevalBuiltinHandler "function: cevalBuiltinHandler
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
    case id
      equation 
        Debug.fprint("ceval", "No Ceval.cevalBuiltinHandler found for: ");
        Debug.fprintln("ceval", id);
      then
        fail();
  end matchcontinue;
end cevalBuiltinHandler;

public function ceval "function: ceval
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
      String funcstr,infilename,outfilename,str,lh_str,rh_str,iter;
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
      Absyn.Program p;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cflist;
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

    case (cache,_,Exp.END(),_,st,NONE,MSG())
      equation 
        Error.addMessage(Error.END_ILLEGAL_USE_ERROR, {});
      then
        fail();

    case (cache,_,Exp.END(),_,st,NONE,NO_MSG()) then fail(); 

    case (cache,env,Exp.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation 
        (cache,exp_1) = cevalAstExp(cache,env, exp, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (cache,env,Exp.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation 
        (cache,exp_1) = cevalAstExp(cache,env, exp, impl, st, msg);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (cache,env,Exp.CODE(code = Absyn.C_ELEMENT(element = elt)),impl,st,_,msg)
      equation 
        (cache,elt_1) = cevalAstElt(cache,env, elt, impl, st, msg);
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
	  local String s; list<String> ss;
      equation
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
        (cache,newval)= cevalCallFunction(cache,env, e, vallst, msg);
      then
        (cache,newval,st);

    case (cache,env,(e as Exp.CALL(path = _)),(impl as false),NONE,_,NO_MSG()) then fail(); 

    case (cache,env,(e as Exp.CALL(path = _)),(impl as true),SOME(st),_,msg)
      local Interactive.InteractiveSymbolTable st;
      equation 
        (cache,value,st) = cevalInteractiveFunctions(cache,env, e, st, msg);
      then
        (cache,value,SOME(st));

    case (cache,env,(e as Exp.CALL(path = func,expLst = expl)),(impl as true),(st as SOME(_)),_,msg)
      equation 
				(cache,false) = Static.isExternalObjectFunction(cache,env,func);
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg) "Call of record constructors, etc., i.e. functions that can be 
	 constant propagated." ;
        (cache,newval) = cevalFunction(cache,env, func, vallst, impl, msg);
      then
        (cache,newval,st);

    case (cache,env,(e as Exp.CALL(path = func,expLst = expl)),(impl as true),
      (st as SOME(Interactive.SYMBOLTABLE(p,_,_,_,cflist,_))),_,msg)
      equation 
        true = Static.isFunctionInCflist(cflist, func) "Call externally implemented functions." ;
        (cache,false) = Static.isExternalObjectFunction(cache,env,func);
        (cache,vallst) = cevalList(cache,env, expl, impl, st, msg);
        funcstr = ModUtil.pathString2(func, "_");
        infilename = stringAppend(funcstr, "_in.txt");
        outfilename = stringAppend(funcstr, "_out.txt");
        Values.writeToFileAsArgs(vallst, infilename);
        System.executeFunction(funcstr);
        newval = System.readValuesFromFile(outfilename);
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

    case (cache,env,Exp.ASUB(exp = e,sub = indx),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (cache,Values.ARRAY(vals),st_1) = ceval(cache,env, e, impl, st, dim, msg) "asub" ;
        indx_1 = indx - 1;
        v = listNth(vals, indx_1);
      then
        (cache,v,st_1);

    case (cache,env,Exp.REDUCTION(path = p,expr = exp,ident = iter,range = iterexp),impl,st,dim,MSG()) /* (v,st) */ 
      local
        Absyn.Path p;
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        Print.printBuf("#-- Ceval.ceval reduction\n");
      then
        fail();

    case (cache,env,Exp.REDUCTION(path = p,expr = exp,ident = iter,range = iterexp),impl,st,dim,NO_MSG()) /* (v,st) */ 
      local
        Absyn.Path p;
        Exp.Exp exp;
        Option<Integer> dim;
      then
        fail();

        /* ceval can fail and that is ok, catched by other rules... */ 
    case (cache,env,e,_,_,_,MSG()) 
      equation 
        Debug.fprint("failtrace", "- Ceval.ceval failed: ");
        str = Exp.printExpStr(e);
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", "\n");
        /*
        Debug.fprint("failtrace", " Env:" );
        Debug.fcall("failtrace", Env.printEnv, env);
        */
      then
        fail();
  end matchcontinue;
end ceval;

protected function cevalCallFunction "function: cevalCallFunction
  This function evaluates CALL expressions, i.e. function calls.
  They are currently evaluated by generating code for the function and
  then write the function input to a file and execute the generated code. 
  Finally, the result is read back from the ressult file and returned."
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
      String funcstr,infilename,outfilename,str;
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
    case (cache,env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,msg) /* Call functions in non-interactive mode. FIXME: functions are always generated. Put back the check
	 and write another rule for the false case that generates the function */ 
      equation
 				failure(cevalIsExternalObjectConstructor(cache,funcpath,env));
        cache = cevalGenerateFunction(cache,env, funcpath);
        funcstr = ModUtil.pathString2(funcpath, "_");
        infilename = stringAppend(funcstr, "_in.txt");
        outfilename = stringAppend(funcstr, "_out.txt");
        Values.writeToFileAsArgs(vallst, infilename);
        System.executeFunction(funcstr);
        newval = System.readValuesFromFile(outfilename);
      then
        (cache,newval);
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
        (cache,dae,_,_,_,_) = Inst.instClass(cache,env_1, mod, Prefix.NOPRE(), Connect.emptySet, c, {}, impl, 
          Inst.TOP_CALL());
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

protected function cevalAstExp "relaton: cevalAstExp
  Part of meta-programming using CODE.
  This function evaluates a piece of Expression AST, replacing Eval(variable)
  with the value of the variable, given that it is of type \"Expression\".
  
  Example: y = Code(1 + x)
           2 + 5  ( x + Eval(y) )  =>   2 + 5  ( x + 1 + x )"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm 
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Exp e,e1_1,e2_1,e1,e2,e_1,cond_1,then_1,else_1,cond,then_,else_,exp,e3_1,e3;
      list<Env.Frame> env;
      Absyn.Operator op;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      list<tuple<Absyn.Exp, Absyn.Exp>> nest_1,nest;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fa;
      list<Absyn.Exp> expl_1,expl;
      Env.Cache cache;
    case (cache,_,(e as Absyn.INTEGER(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.REAL(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.CREF(componentReg = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.STRING(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.BOOL(value = _)),_,_,_) then (cache,e); 
    case (cache,env,Absyn.BINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.BINARY(e1_1,op,e2_1));
    case (cache,env,Absyn.UNARY(op = op,exp = e),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.UNARY(op,e_1));
    case (cache,env,Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.LBINARY(e1_1,op,e2_1));
    case (cache,env,Absyn.LUNARY(op = op,exp = e),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.LUNARY(op,e_1));
    case (cache,env,Absyn.RELATION(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.RELATION(e1_1,op,e2_1));
    case (cache,env,Absyn.IFEXP(ifExp = cond,trueBranch = then_,elseBranch = else_,elseIfBranch = nest),impl,st,msg)
      equation 
        (cache,cond_1) = cevalAstExp(cache,env, cond, impl, st, msg);
        (cache,then_1) = cevalAstExp(cache,env, then_, impl, st, msg);
        (cache,else_1) = cevalAstExp(cache,env, else_, impl, st, msg);
        (cache,nest_1) = cevalAstExpexpList(cache,env, nest, impl, st, msg);
      then
        (cache,Absyn.IFEXP(cond_1,then_1,else_1,nest_1));
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "Eval",subscripts = {}),functionArgs = Absyn.FUNCTIONARGS(args = {e},argNames = {})),impl,st,msg)
      local Exp.Exp e_1;
      equation 
        (cache,e_1,_,_) = Static.elabExp(cache,env, e, impl, st,true);
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp)),_) = ceval(cache,env, e_1, impl, st, NONE, msg);
      then
        (cache,exp);
    case (cache,env,(e as Absyn.CALL(function_ = cr,functionArgs = fa)),_,_,msg) then (cache,e); 
    case (cache,env,Absyn.ARRAY(arrayExp = expl),impl,st,msg)
      equation 
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.ARRAY(expl_1));
    case (cache,env,Absyn.MATRIX(matrix = expl),impl,st,msg)
      local list<list<Absyn.Exp>> expl_1,expl;
      equation 
        (cache,expl_1) = cevalAstExpListList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.MATRIX(expl_1));
    case (cache,env,Absyn.RANGE(start = e1,step = SOME(e2),stop = e3),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg);
      then
        (cache,Absyn.RANGE(e1_1,SOME(e2_1),e3_1));
    case (cache,env,Absyn.RANGE(start = e1,step = NONE,stop = e3),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg);
      then
        (cache,Absyn.RANGE(e1_1,NONE,e3_1));
    case (cache,env,Absyn.TUPLE(expressions = expl),impl,st,msg)
      equation 
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.TUPLE(expl_1));
    case (cache,env,Absyn.END(),_,_,msg) then (cache,Absyn.END()); 
    case (cache,env,(e as Absyn.CODE(code = _)),_,_,msg) then (cache,e); 
  end matchcontinue;
end cevalAstExp;

protected function cevalAstExpList "function: cevalAstExpList
  List version of cevalAstExp"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  (outCache,outAbsynExpLst) :=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      Absyn.Exp e_1,e;
      list<Absyn.Exp> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(e :: es),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
        (cache,res) = cevalAstExpList(cache,env, es, impl, st, msg);
      then
        (cache,e :: res);
  end matchcontinue;
end cevalAstExpList;

protected function cevalAstExpListList "function: cevalAstExpListList"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm 
  (outCache,outAbsynExpLstLst) :=
  matchcontinue (inCache,inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      list<Absyn.Exp> e_1,e;
      list<list<Absyn.Exp>> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(e :: es),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExpList(cache,env, e, impl, st, msg);
        (cache,res) = cevalAstExpListList(cache,env, es, impl, st, msg);
      then
        (cache,e :: res);
  end matchcontinue;
end cevalAstExpListList;

protected function cevalAstExpexpList "function: cevalAstExpexpList
  For IFEXP"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm 
  (outCache,outTplAbsynExpAbsynExpLst) :=
  matchcontinue (inCache,inEnv,inTplAbsynExpAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Msg msg;
      Absyn.Exp e1_1,e2_1,e1,e2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res,xs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,_,{},_,_,msg) then (cache,{}); 
    case (cache,env,((e1,e2) :: xs),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
        (cache,res) = cevalAstExpexpList(cache,env, xs, impl, st, msg);
      then
        (cache,(e1_1,e2_1) :: res);
  end matchcontinue;
end cevalAstExpexpList;

protected function cevalAstElt "function: cevalAstElt
  Evaluates an ast constructor for Element nodes, e.g. 
  Code(parameter Real x=1;)"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Element outElement;
algorithm 
  (outCache,outElement) :=
  matchcontinue (inCache,inEnv,inElement,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      list<Env.Frame> env;
      Boolean f,isReadOnly,impl;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String id,file;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.Info info;
      Integer sline,scolumn,eline,ecolumn;
      Option<Absyn.ConstrainClass> c;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = io,name = id,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = citems),info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scolumn,lineNumberEnd = eline,columnNumberEnd = ecolumn)),constrainClass = c),impl,st,msg)
      equation 
        (cache,citems_1) = cevalAstCitems(cache,env, citems, impl, st, msg);
      then
        (cache,Absyn.ELEMENT(f,r,io,id,Absyn.COMPONENTS(attr,tp,citems_1),info,c));
  end matchcontinue;
end cevalAstElt;

protected function cevalAstCitems "function: cevalAstCitems
  Helper function to cevalAstElt."
 	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  (outCache,outAbsynComponentItemLst) :=
  matchcontinue (inCache,inEnv,inAbsynComponentItemLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Msg msg;
      list<Absyn.ComponentItem> res,xs;
      Option<Absyn.Modification> modopt_1,modopt;
      list<Absyn.Subscript> ad_1,ad;
      list<Env.Frame> env;
      String id;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.ComponentItem x;
      Env.Cache cache;
    case (cache,_,{},_,_,msg) then (cache,{}); 
    case (cache,env,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = modopt),condition = cond,comment = cmt) :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg);
        (cache,modopt_1) = cevalAstModopt(cache,env, modopt, impl, st, msg);
        (cache,ad_1) = cevalAstArraydim(cache,env, ad, impl, st, msg);
      then
        (cache,Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad_1,modopt_1),cond,cmt) :: res);
    case (cache,env,(x :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg);
      then
        (cache,x :: res);
  end matchcontinue;
end cevalAstCitems;

protected function cevalAstModopt "function: cevalAstModopt"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm 
  (outCache,outAbsynModificationOption) :=
  matchcontinue (inCache,inEnv,inAbsynModificationOption,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Modification res,mod;
      list<Env.Frame> env;
      Boolean st;
      Option<Interactive.InteractiveSymbolTable> impl;
      Msg msg;
      Env.Cache cache;
    case (cache,env,SOME(mod),st,impl,msg)
      equation 
        (cache,res) = cevalAstModification(cache,env, mod, st, impl, msg);
      then
        (cache,SOME(res));
    case (cache,env,NONE,_,_,msg) then (cache,NONE); 
  end matchcontinue;
end cevalAstModopt;

protected function cevalAstModification "function: cevalAstModification
  This function evaluates Eval(variable) inside an AST Modification  and replaces 
  the Eval operator with the value of the variable if it has a type \"Expression\""
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Modification inModification;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Modification outModification;
algorithm 
  (outCache,outModification) :=
  matchcontinue (inCache,inEnv,inModification,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Exp e_1,e;
      list<Absyn.ElementArg> eltargs_1,eltargs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = SOME(e)),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,SOME(e_1)));
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = NONE),impl,st,msg)
      equation 
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,NONE));
  end matchcontinue;
end cevalAstModification;

protected function cevalAstEltargs "function: cevalAstEltargs
  Helper function to cevalAstModification."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  (outCache,outAbsynElementArgLst):=
  matchcontinue (inCache,inEnv,inAbsynElementArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      Absyn.Modification mod_1,mod;
      list<Absyn.ElementArg> res,args;
      Boolean b,impl;
      Absyn.Each e;
      Absyn.ComponentRef cr;
      Option<String> stropt;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.ElementArg m;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    /* TODO: look through redeclarations for Eval(var) as well */   
    case (cache,env,(Absyn.MODIFICATION(finalItem = b,each_ = e,componentReg = cr,modification = SOME(mod),comment = stropt) :: args),impl,st,msg) 
      equation 
        (cache,mod_1) = cevalAstModification(cache,env, mod, impl, st, msg);
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg);
      then
        (cache,Absyn.MODIFICATION(b,e,cr,SOME(mod_1),stropt) :: res);
    case (cache,env,(m :: args),impl,st,msg) /* TODO: look through redeclarations for Eval(var) as well */ 
      equation 
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg);
      then
        (cache,m :: res);
  end matchcontinue;
end cevalAstEltargs;

protected function cevalAstArraydim "function: cevalAstArraydim
  Helper function to cevaAstCitems"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Env.Cache outCache;
  output Absyn.ArrayDim outArrayDim;
algorithm 
  (outCache,outArrayDim) :=
  matchcontinue (inCache,inEnv,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      list<Absyn.Subscript> res,xs;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.Exp e_1,e;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(Absyn.NOSUB() :: xs),impl,st,msg)
      equation 
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg);
      then
        (cache,Absyn.NOSUB() :: res);
    case (cache,env,(Absyn.SUBSCRIPT(subScript = e) :: xs),impl,st,msg)
      equation 
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg);
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.SUBSCRIPT(e) :: res);
  end matchcontinue;
end cevalAstArraydim;

protected function cevalInteractiveFunctions "function cevalInteractiveFunctions
  This function evaluates the functions 
  defined in the interactive environment."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp "expression to evaluate";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      Absyn.Path path,p1,classpath;
      list<SCode.Class> p_1,sp,fp;
      list<Env.Frame> env;
      SCode.Class c;
      String s1,str,varid,res,cmd,executable,method_str,initfilename,cit,pd,executableSuffixedExe,sim_call,result_file,omhome,pwd,filename_1,filename,omhome_1,plotCmd,tmpPlotFile,call,str_1,scriptstr,res_1,mp,pathstr,name,cname;
      Exp.ComponentRef cr,fcr,cref,classname;
      Interactive.InteractiveSymbolTable st,newst,st_1,st_2;
      Absyn.Program p,pnew,newp;
      list<Interactive.InstantiatedClass> ic,ic_1;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      tuple<Types.TType, Option<Absyn.Path>> tp,simType;
      Absyn.Class class_;
      DAE.DAElist dae_1,dae;
      list<DAE.Element> dael;
      DAELow.DAELow daelow;
      DAELow.Variables vars;
      DAELow.EquationArray eqnarr;
      DAELow.MultiDimEquation[:] ae;
      list<Integer>[:] m,mt;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      Values.Value ret_val,simValue,size_value,value,v;
      Exp.Exp filenameprefix,exp,starttime,stoptime,interval,method,size_expression,funcref,bool_exp,storeInTemp;
      Absyn.ComponentRef cr_1;
      Integer size,length,rest;
      list<String> vars_1,vars_2,args;
      Real t1,t2,time;
      Interactive.InteractiveStmts istmts;
      Boolean bval;
      Env.Cache cache;
      Absyn.Path className;
      list<Interactive.LoadedFile> lf;
    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "lookupClass"),expLst = {Exp.CREF(componentRef = cr)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        p_1 = SCode.elaborate(p);
        (cache,env) = Inst.makeEnvFromProgram(cache,p_1, Absyn.IDENT(""));
        (cache,c,env) = Lookup.lookupClass(cache,env, path, true);
        SOME(p1) = Env.getEnvPath(env);
        s1 = ModUtil.pathString(p1);
        Print.printBuf("Found class ");
        Print.printBuf(s1);
        Print.printBuf("\n\n");
        str = Print.getString();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "typeOf"),
        expLst = {Exp.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(name = varid)),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        tp = Interactive.getTypeOfVariable(varid, iv);
        str = Types.unparseType(tp);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "clear"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg) 
    then (cache,Values.BOOL(true),Interactive.emptySymboltable); 

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "clearVariables"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = fp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        newst = Interactive.SYMBOLTABLE(p,fp,ic,{},cf,lf);
      then
        (cache,Values.BOOL(true),newst);

		// Note: This is not the environment caches, passed here as cache, but instead the cached instantiated classes.
    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "clearCache"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = fp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        newst = Interactive.SYMBOLTABLE(p,fp,{},iv,cf,lf);
      then
        (cache,Values.BOOL(true),newst);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "list"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Dump.unparseStr(p) ",false" ;
      then
        (cache,Values.STRING(str),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "list"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        class_ = Interactive.getPathedClassInProgram(path, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP())) ",false" ;
      then
        (cache,Values.STRING(str),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "jacobian"),
        expLst = {Exp.CREF(componentRef = cr)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        p_1 = SCode.elaborate(p);
        (cache,dae_1,env) = Inst.instantiateClass(cache,p_1, path);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(path,dael,env));
        ((daelow as DAELow.DAELOW(vars,_,_,eqnarr,_,_,ae,_,_,_))) = DAELow.lower(dae, false) "no dummy state" ;
        m = DAELow.incidenceMatrix(daelow);
        mt = DAELow.transposeMatrix(m);
        jac = DAELow.calculateJacobian(vars, eqnarr, ae, m, mt,false);
        res = DAELow.dumpJacobianStr(jac);
      then
        (cache,Values.STRING(res),Interactive.SYMBOLTABLE(p,sp,ic_1,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "translateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER()),filenameprefix}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        (cache,ret_val,st_1,_,_,_) = translateModel(cache,env, className, st, msg, filenameprefix);
      then
        (cache,ret_val,st_1);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "getIncidenceMatrix"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER()),filenameprefix}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        (cache,ret_val,st_1,_) = getIncidenceMatrix(cache,env, className, st, msg, filenameprefix);
      then
        (cache,ret_val,st_1);
        
      case (cache,env,
        Exp.CALL(
          path = Absyn.IDENT(name = "checkModel"),
          expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())}),
        (st as Interactive.SYMBOLTABLE(
          ast = p,
          explodedAst = sp,
          instClsLst = ic,
          lstVarVal = iv,
          compiledFunctions = cf)),msg)
           equation 
        (cache,ret_val,st_1) = checkModel(cache,env, className, st, msg);
      then
        (cache,ret_val,st_1);
        
         case (cache,env,
        Exp.CALL(
          path = Absyn.IDENT(name = "translateGraphics"),
          expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())}),
        (st as Interactive.SYMBOLTABLE(
          ast = p,
          explodedAst = sp,
          instClsLst = ic,
          lstVarVal = iv,
          compiledFunctions = cf)),msg)
           equation 
        (cache,ret_val,st_1) = translateGraphics(cache,env, className, st, msg);
      then
        (cache,ret_val,st_1);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "setCompileCommand"),
        expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg) /* (Values.STRING(\"The model have been translated\"),st\') */ 
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setCompileCommand(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "setPlotCommand"),
        expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setPlotCommand(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "getSettings"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String str1,res;
      equation 
        res = "";
        str1 = Settings.getCompileCommand();
        res = Util.stringAppendList({res,"Compile command: ", str1,"\n"});
        str1 = Settings.getTempDirectoryPath();
        res = Util.stringAppendList({res,"Temp folder path: ", str1,"\n"});
        str1 = Settings.getInstallationDirectoryPath();
        res = Util.stringAppendList({res,"Installation folder: ", str1,"\n"});
        str1 = Settings.getPlotCommand();
        res = Util.stringAppendList({res,"Plot command: ", str1,"\n"});
        str1 = Settings.getModelicaPath();
        res = Util.stringAppendList({res,"Modelica path: ", str1,"\n"});
      then
        (cache,Values.STRING(res),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "setTempDirectoryPath"),expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setTempDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "setInstallationDirectoryPath"),
        expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setInstallationDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "getTempDirectoryPath"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String res;
      equation 
        res = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(res),st);
        
    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "getInstallationDirectoryPath"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String res;
      equation 
        res = Settings.getInstallationDirectoryPath();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "setModelicaPath"),expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setModelicaPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,(exp as 
      Exp.CALL(
        path = Absyn.IDENT(name = "buildModel"),
        expLst = 
        {Exp.CODE(Absyn.C_TYPENAME(className),_),
         starttime,
         stoptime,
         interval,
         method,
         filenameprefix,
         storeInTemp})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        (cache,executable,method_str,st,initfilename) = buildModel(cache,env, exp, st_1, msg);
      then
        (cache,Values.ARRAY({Values.STRING(executable),Values.STRING(initfilename)}),st);

    case (cache,env,(exp as 
      Exp.CALL(
        path = Absyn.IDENT(name = "buildModel"),
        expLst = 
        {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        starttime,
        stoptime,
        interval,
        method,
        filenameprefix,
        storeInTemp})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg) /* failing build_model */  
    then (cache,Values.ARRAY({Values.STRING(""),Values.STRING("")}),st_1); 

    case (cache,env,(exp as 
      Exp.CALL(
        path = Absyn.IDENT(name = "simulate"),
        expLst = 
        {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        starttime,
        stoptime,
        interval,
        method,
        filenameprefix,
        storeInTemp})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        (cache,executable,method_str,st,_) = buildModel(cache,env, exp, st_1, msg) "Build and simulate model" ;
        cit = winCitation();
        pd = System.pathDelimiter();
        executableSuffixedExe = stringAppend(executable, ".exe");
        sim_call = Util.stringAppendList(
          {cit,executableSuffixedExe,cit," > output.log 2>&1"});
        //print(sim_call);
        0 = System.systemCall(sim_call);
        result_file = Util.stringAppendList({executable,"_res.plt"});
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),
          {Values.STRING(result_file)},{"resultFile"});
        simType = (
          Types.T_COMPLEX(ClassInf.RECORD("SimulationResult"),
          {
          Types.VAR("resultFile",
          Types.ATTR(false,SCode.RO(),SCode.VAR(),Absyn.BIDIR()),false,(Types.T_STRING({}),NONE),Types.UNBOUND())},NONE),NONE);
        newst = Interactive.addVarToSymboltable("currentSimulationResult", simValue, simType, st);
      then
        (cache,simValue,newst);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "simulate"),
        expLst = 
        {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        starttime,
        stoptime,
        interval,
        method,
        filenameprefix,
        storeInTemp}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String errorStr;
      equation 
        omhome = Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        errorStr = Error.printMessagesStr();
        res = Util.stringAppendList({"Simulation failed.\n",errorStr});
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),{Values.STRING(res)},
          {"resultFile"});
      then
        (cache,simValue,st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "simulate"),expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_),starttime,stoptime,interval,method,filenameprefix}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),
          {
          Values.STRING(
          "Simulation Failed. Environment variable OPENMODELICAHOME not set.")},{"resultFile"});
      then
        (cache,simValue,st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "instantiateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local Absyn.Path className;
        Absyn.ComponentRef crefCName;
      equation 
        crefCName = Absyn.pathToCref(className);
        true = Interactive.existClass(crefCName, p);
        p_1 = SCode.elaborate(p);
        (cache,(dae as DAE.DAE(dael)),env) = Inst.instantiateClass(cache,p_1, className);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        str = DAE.dumpStr(dae);
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,sp,ic_1,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "instantiateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg) /* model does not exist */ 
      equation 
				cr_1 = Absyn.pathToCref(className);
        false = Interactive.existClass(cr_1, p);
      then
        (cache,Values.STRING("Unknown model.\n"),Interactive.SYMBOLTABLE(p,sp,ic,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "instantiateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        p_1 = SCode.elaborate(p);
        str = Print.getErrorString() "we do not want error msg twice.." ;
        failure((_,_,_) = Inst.instantiateClass(cache,p_1, path));
        Print.clearErrorBuf();
        Print.printErrorBuf(str);
        str = Print.getErrorString();
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,sp,ic,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResult"),
        expLst = {Exp.SCONST(string = filename),Exp.ARRAY(array = vars),size_expression}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg) /* function ceval : (Env.Env, Exp.Exp, bool (implicit) ,
		    Interactive.InteractiveSymbolTable option, 
		    int option, ( dimensions )
		    Msg)
	  => (Values.Value, Interactive.InteractiveSymbolTable option)
 */ 
      local list<Exp.Exp> vars;
      equation 
        (cache,(size_value as Values.INTEGER(size)),SOME(st)) = ceval(cache,env, size_expression, true, SOME(st), NONE, msg);
				vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.stringAppendList({pwd,pd,filename});
        value = System.readPtolemyplotDataset(filename_1, vars_1, size);
      then
        (cache,value,st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResult"),
        expLst = {Exp.SCONST(string = filename),Exp.ARRAY(ty = _),_}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then
        fail();

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResultSize"),
        expLst = {Exp.SCONST(string = filename)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.stringAppendList({pwd,pd,filename});
        value = System.readPtolemyplotDatasetSize(filename_1);
      then
        (cache,value,st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResultSize"),
        expLst = {Exp.SCONST(string = filename)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_SIZE_ERROR, {});
      then
        fail();

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "plot" ;
        vars_2 = Util.listUnionElt("time", vars_1);
        
    
        (cache,Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        value = System.readPtolemyplotDataset(filename, vars_2, 0);
        pwd = System.pwd();
        cit = winCitation();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = Util.stringAppendList({cit,omhome_1,pd,"bin",pd,"doPlot",cit});
        tmpPlotFile = Util.stringAppendList({pwd,pd,"tmpPlot.plt"});
        res = Values.writePtolemyplotDataset(tmpPlotFile, value, vars_2, "Plot by OpenModelica");
        call = Util.stringAppendList({cit,plotCmd," \"",tmpPlotFile,"\"",cit});
        _ = System.systemCall(call);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        (cache,Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        failure(_ = System.readPtolemyplotDataset(filename, vars_2, 0));
      then
        (cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        failure((_,_,_) = ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, NO_MSG()));
      then
        (cache,Values.STRING("No simulation result to plot."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      then
        (cache,Values.STRING("Unknown error while plotting"),st);
   
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {Exp.ARRAY(array = {varName, varTimeStamp})}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local 
        Exp.Exp varName, varTimeStamp;
        String var;
        Integer res;
        Real timeStamp;
        list<Values.Value> varValues, timeValues;
        list<Real> tV, vV; 
        Real val;
      equation 
        
        {varName} = Util.listMap({varName},Exp.CodeVarToCref);
        vars_1 = Util.listMap({varName}, Exp.printExpStr);
        // Util.listMap0(vars_1,print);
        
        (cache,Values.REAL(timeStamp),SOME(st)) = ceval(cache,env, varTimeStamp, true, SOME(st), NONE, msg);
        
        (cache,Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(cache,env, 
        Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, msg);

        Values.ARRAY({Values.ARRAY(varValues)}) = System.readPtolemyplotDataset(filename, vars_1, 0);
        Values.ARRAY({Values.ARRAY(timeValues)}) = System.readPtolemyplotDataset(filename, {"time"}, 0); 

				
        tV = Values.valueReals(timeValues);
        vV = Values.valueReals(varValues);  
        val = System.getVariableValue(timeStamp, tV, vV);
        
      then
        (cache,Values.REAL(val),st);
        
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)      
      local 
        list<Exp.Exp> vars;
      then
        (cache,Values.STRING("Error, check variable name and time variables"),st);
        
        
    /* plotparametric This rule represents the normal case when an array of at least two elements 
     *  is given as an argument  
     */
    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)  
      local
        Integer res;
        list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        length = listLength(vars_1);
        (length > 1) = true;
        (cache,Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        value = System.readPtolemyplotDataset(filename, vars_1, 0);
        pwd = System.pwd();
        cit = winCitation();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = Util.stringAppendList({cit,omhome_1,pd,"bin",pd,"doPlot",cit});
        tmpPlotFile = Util.stringAppendList({pwd,pd,"tmpPlot.plt"});
        res = Values.writePtolemyplotDataset(tmpPlotFile, value, vars_1, "Plot by OpenModelica");
        call = Util.stringAppendList({cit,plotCmd," \"",tmpPlotFile,"\"",cit});
        _ = System.systemCall(call);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error with less than two elements (=variables) in the array.
           This means we cannot plot var2 as a function of var1 as var2 is missing" ;
        length = listLength(vars_1);
        (length < 2) = true;
      then
        (cache,Values.STRING("Error: Less than two variables given to plotParametric."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        (cache,Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, msg) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
        failure(_ = System.readPtolemyplotDataset(filename, vars_1, 0));
      then
        (cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        failure((_,_,_) = ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, NO_MSG())) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
      then
        (cache,Values.STRING("No simulation result to plot."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      then
        (cache,Values.STRING("Unknown error while plotting"),st);
    /* end plotparametric */        

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "timing"),expLst = {exp}),st,msg)  
      equation 
        t1 = System.time();
        (cache,value,SOME(st_1)) = ceval(cache,env, exp, true, SOME(st), NONE, msg);
        t2 = System.time();
        time = t2 -. t1;
      then
        (cache,Values.REAL(time),st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setCompiler"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        System.setCCompiler(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setCompilerFlags"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        System.setCFlags(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setDebugFlags"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = stringAppend("+d=", str);
        args = RTOpts.args({str_1});
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Integer res;
      equation 
        res = System.cd(str);
        (res == 0) = true;
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* no such directory */ 
      equation 
        failure(0 = System.directoryExists(str));
        res = Util.stringAppendList({"Error, directory ",str," does not exist,"});
      then
        (cache,Values.STRING(res),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getVersion"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = Settings.getVersionNr();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getTempDirectoryPath"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "system"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Integer res;
      equation 
        res = System.systemCall(str);
      then
        (cache,Values.INTEGER(res),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "readFile"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = System.readFile(str);
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getErrorString"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Error.printMessagesStr();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMessagesString"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* New error message implementation */ 
      equation 
        str = Error.printMessagesStr();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMessagesStringInternal"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Error.getMessagesStr();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "runScript"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local String msg;
      equation 
        scriptstr = System.readFile(str);
        (istmts,msg) = Parser.parsestringexp(scriptstr);
        equality(msg = "Ok");
        (res,newst) = Interactive.evaluate(istmts, st, true);
        res_1 = Util.stringAppendList({res,"\ntrue"});
      then
        (cache,Values.STRING(res_1),newst);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "runScript"),expLst = {Exp.SCONST(string = str)}),st,msg) then (cache,Values.BOOL(false),st); 

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "generateCode"),expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        cache = cevalGenerateFunction(cache,env, path) "	& Inst.instantiate_implicit(p\') => d &" ;
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "loadModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg) /* add path to symboltable for compiled functions
	  Interactive.SYMBOLTABLE(p,sp,ic,iv,(path,t)::cf),
	  but where to get t? */ 
      local Absyn.Program p_1;
      equation 
        mp = Settings.getModelicaPath();
        pnew = ClassLoader.loadClass(path, mp);
        p_1 = Interactive.updateProgram(pnew, p);
        str = Print.getString();
        newst = Interactive.SYMBOLTABLE(p_1,sp,{},iv,cf,lf);
      then
        (cache,Values.BOOL(true),newst);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadModel"),expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        pathstr = ModUtil.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_ERROR, {pathstr});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadModel"),expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) 
    then (cache,Values.BOOL(false),st);  /* loadModel failed */ 

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "loadFile"),
        expLst = {Exp.SCONST(string = name)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local Absyn.Program p1;
      equation 
        p1 = ClassLoader.loadFile(name) "System.regularFileExists(name) => 0 & Parser.parse(name) => p1 &" ;
        newp = Interactive.updateProgram(p1, p);
      then
        (cache,Values.BOOL(true),Interactive.SYMBOLTABLE(newp,sp,ic,iv,cf,lf));

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadFile"),expLst = {Exp.SCONST(string = name)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* (Values.BOOL(true),Interactive.SYMBOLTABLE(newp,sp,{},iv,cf)) it the rule above have failed then check if file exists without this omc crashes */ 
      equation 
        rest = System.regularFileExists(name);
        (rest > 0) = true;
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadFile"),expLst = {Exp.SCONST(string = name)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* not Parser.parse(name) => _ */  
    then (cache,Values.BOOL(false),st); 

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = filename),Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        classpath = Static.componentRefToPath(cr);
        class_ = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP())) ",true" ;
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = name),Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        classpath = Static.componentRefToPath(cr) "Error writing to file" ;
        class_ = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP())) ",true" ;
        Error.addMessage(Error.WRITING_FILE_ERROR, {name});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "save"),expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Absyn.Program p_1;
      equation 
        (p_1,filename) = Interactive.getContainedClassAndFile(className, p);
        str = Dump.unparseStr(p_1) ",true" ;
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "save"),expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) 
    then (cache,Values.BOOL(false),st); 

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveAll"),expLst = {Exp.SCONST(string = filename)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Dump.unparseStr(p) ",true" ;
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = name),Exp.CODE(Absyn.C_TYPENAME(classpath),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        cname = Absyn.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "help"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        cit = winCitation();
        pd = System.pathDelimiter();
        filename = Util.stringAppendList({omhome_1,pd,"bin",pd,"omc_helptext.txt"});
        print(filename);
        str = System.readFile(filename);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getUnit"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "unit", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getQuantity"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "quantity", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getDisplayUnit"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "displayUnit", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMin"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "min", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMax"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "max", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getStart"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "start", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getFixed"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "fixed", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getNominal"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "nominal", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getStateSelect"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "stateSelect", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "echo"),expLst = {bool_exp}),st,msg)
      equation 
        (cache,(v as Values.BOOL(bval)),SOME(st_1)) = ceval(cache,env, bool_exp, true, SOME(st), NONE, msg);
        setEcho(bval);
      then
        (cache,v,st);
  end matchcontinue;
end cevalInteractiveFunctions;

protected function setEcho 
  input Boolean echo;
algorithm
  _:=
  matchcontinue (echo)
    local
    case (true)
      equation 
        Settings.setEcho(1);
      then
        ();
    case (false)
      equation 
        Settings.setEcho(0);
      then
        ();
  end matchcontinue; 
end setEcho;


protected function generateMakefilename "function generateMakefilename"
  input String filenameprefix;
  output String makefilename;
algorithm 
  makefilename := Util.stringAppendList({filenameprefix,".makefile"});
end generateMakefilename;


public function getIncidenceMatrix "function getIncidenceMatrix
 author: adrpo
 translates a model and returns the incidence matrix"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  input Exp.Exp inExp;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output String outString;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable,outString):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,inExp)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,fileprefix) /* mo file directory */ 
      equation 
        print("getIncidenceMatrix:" +& Absyn.pathString(className) +& "\n");
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        p_1 = SCode.elaborate(p);
        (cache,dae_1,env) = Inst.instantiateClass(cache,p_1, className);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        DAE.printDAE(dae);
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);        
        dlow = DAELow.lower(dae, false);
        Debug.fprint("bltdump", "Lowered DAE:\n");
        Debug.fcall("bltdump", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        Debug.fprint("bltdump", "indexed DAE:\n");
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        /*
        cname_str = Absyn.pathString(className);
        filename = Util.stringAppendList({filenameprefix,"_imatrix.txt"});
        funcfilename = Util.stringAppendList({filenameprefix,"_functions.cpp"});
        makefilename = generateMakefilename(filenameprefix);
        libs = SimCodegen.generateFunctions(p_1, dae, indexed_dlow_1, className, funcfilename);
        SimCodegen.generateSimulationCode(dae, indexed_dlow_1, ass1, ass2, m, mT, comps, className, 
          filename, funcfilename,file_dir);
        SimCodegen.generateMakefile(makefilename, filenameprefix, libs, file_dir);
        s_call = Util.stringAppendList({"make -f ",cname_str, ".makefile\n"}) 
        */
      then
        (cache,Values.STRING("The model has been translated"),st,file_dir);
  end matchcontinue;
end getIncidenceMatrix;


public function translateModel "function translateModel
 author: x02lucpo
 translates a model into cpp code and writes also a makefile"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  input Exp.Exp inExp;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output DAELow.DAELow outDAELow;
  output list<String> outStringLst;
  output String outString;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable,outDAELow,outStringLst,outString):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,inExp)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,fileprefix) /* mo file directory */ 
      equation 
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        p_1 = SCode.elaborate(p);
        (cache,dae_1,env) = Inst.instantiateClass(cache,p_1, className);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        dlow = DAELow.lower(dae, true);
        Debug.fprint("bltdump", "Lowered DAE:\n");
        Debug.fcall("bltdump", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        (ass1,ass2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, 
          (DAELow.INDEX_REDUCTION(),DAELow.EXACT(),
          DAELow.REMOVE_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m, mT, ass1, ass2);
        indexed_dlow = DAELow.translateDae(dlow_1);
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        Debug.fprint("bltdump", "indexed DAE:\n");
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("bltdump", DAELow.dump, indexed_dlow_1);
        Debug.fcall("bltdump", DAELow.dumpMatching, ass1);
        cname_str = Absyn.pathString(className);
        filename = Util.stringAppendList({filenameprefix,".cpp"});
        funcfilename = Util.stringAppendList({filenameprefix,"_functions.cpp"});
        makefilename = generateMakefilename(filenameprefix);
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        libs = SimCodegen.generateFunctions(p_1, dae, indexed_dlow_1, className, funcfilename);
        SimCodegen.generateSimulationCode(dae, indexed_dlow_1, ass1, ass2, m, mT, comps, className, 
          filename, funcfilename,file_dir);
        SimCodegen.generateMakefile(makefilename, filenameprefix, libs, file_dir);
        /* 
        s_call = Util.stringAppendList({"make -f ",cname_str, ".makefile\n"}) 
        */
      then
        (cache,Values.STRING("The model has been translated"),st,indexed_dlow_1,libs,file_dir);
  end matchcontinue;
end translateModel;

public function checkModel "function: checkModel
 checks a model and returns number of variables and equations"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)  
      local Integer eqnSize,varSize,simpleEqnSize;
        String eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
        DAELow.EquationArray eqns;
        Integer elimLevel;
      equation 
        p_1 = SCode.elaborate(p);
        (cache,dae_1,env) = Inst.instantiateClass(cache,p_1, className);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(0); // No variable eliminiation
        (dlow as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(numberOfVars = varSize),orderedEqs = eqns)) 
        	= DAELow.lower(dae, false/* no dummy variable*/);
        RTOpts.setEliminationLevel(elimLevel); // reset elimination level.
        	eqnSize = DAELow.equationSize(eqns);
				simpleEqnSize = DAELow.countSimpleEquations(eqns);
				eqnSizeStr = intString(eqnSize);
				varSizeStr = intString(varSize);
				simpleEqnSizeStr = intString(simpleEqnSize);
				
				classNameStr = Absyn.pathString(className);
				retStr=Util.stringAppendList({"Check of ",classNameStr," successful.\n\n","model ",classNameStr," has ",eqnSizeStr," equation(s) and ",
				varSizeStr," variable(s).\n",simpleEqnSizeStr," of these are trivial equation(s).\n"});
      then
        (cache,Values.STRING(retStr),st);
    case (cache,_,_,st,_) local
      String errorMsg; Boolean strEmpty;
      equation
      errorMsg = Error.printMessagesStr();
      strEmpty = (System.strcmp("",errorMsg)==0);
      errorMsg = Util.if_(strEmpty,"Internal error, check of model failed with no error message.",errorMsg);
    then (cache,Values.STRING(errorMsg),st);  

  end matchcontinue;
end checkModel; 

public function translateGraphics "function: translates the graphical annotations from old to new version"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
      list<Interactive.LoadedFile> lf;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(p,sp,ic,iv,cf,lf)),msg)  
      local Integer eqnSize,varSize,simpleEqnSize;
        String eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr,s1;
        DAELow.EquationArray eqns;
        Absyn.Class cls, refactoredClass;
        Absyn.Within within_;
        Integer elimLevel;
        Absyn.Program p1;
      equation         
	  		cls = Interactive.getPathedClassInProgram(className, p);        
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = Interactive.buildWithin(className);
        p1 = Interactive.updateProgram(Absyn.PROGRAM({refactoredClass}, within_), p);
        s1 = Absyn.pathString(className);
				retStr=Util.stringAppendList({"Translation of ",s1," successful.\n"});
      then
        (cache,Values.STRING(retStr),Interactive.SYMBOLTABLE(p1,sp,ic,iv,cf,lf));
    case (cache,_,_,st,_) local
      String errorMsg; Boolean strEmpty;
      equation
      errorMsg = Error.printMessagesStr();
      strEmpty = (System.strcmp("",errorMsg)==0);
      errorMsg = Util.if_(strEmpty,"Internal error, translating graphics to new version",errorMsg);
    then (cache,Values.STRING(errorMsg),st);  

  end matchcontinue;
end translateGraphics; 


protected function extractFilePrefix "function extractFilePrefix
  author: x02lucpo 
  extracts the file prefix from Exp.Exp as string"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output Env.Cache outCache;
  output String outString;
algorithm 
  (outCache,outString):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      String prefix_str;
      Interactive.InteractiveSymbolTable st;
      list<Env.Frame> env;
      Exp.Exp filenameprefix;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      Env.Cache cache;
    case (cache,env,filenameprefix,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (cache,Values.STRING(prefix_str),SOME(st)) = ceval(cache,env, filenameprefix, true, SOME(st), NONE, msg);
      then
        (cache,prefix_str);
    case (_,_,_,_,_) then fail(); 
  end matchcontinue;
end extractFilePrefix;

protected function calculateSimulationSettings "function calculateSimulationSettings
 author: x02lucpo
 calculates the start,end,interval,stepsize, method and initFileName"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  input String inString;
  output Env.Cache outCache;
  output String outString1 "filename";
  output Real outReal2 "start time";
  output Real outReal3 "stop time";
  output Real outReal4 "step size";
  output String outString5 "method";
algorithm 
  (outCache,outString1,outReal2,outReal3,outReal4,outString5):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg,inString)
    local
      String prefix_str,method_str,init_filename,cname_str;
      Interactive.InteractiveSymbolTable st;
      Values.Value starttime_v,stoptime_v;
      Integer interval_i;
      Real starttime_r,stoptime_r,interval_r;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Exp.Exp starttime,stoptime,interval,method,filenameprefix;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      Env.Cache cache;
      Absyn.Path className;
    case (cache,env,Exp.CALL(expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_),starttime,stoptime,interval,method,filenameprefix,_}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,cname_str)
      equation 
        (cache,Values.STRING(prefix_str),SOME(st)) = ceval(cache,env, filenameprefix, true, SOME(st), NONE, msg);
        (cache,starttime_v,SOME(st)) = ceval(cache,env, starttime, true, SOME(st), NONE, msg);
        (cache,stoptime_v,SOME(st)) = ceval(cache,env, stoptime, true, SOME(st), NONE, msg);
        (cache,Values.INTEGER(interval_i),SOME(st)) = ceval(cache,env, interval, true, SOME(st), NONE, msg);
        (cache,Values.STRING(method_str),SOME(st)) = ceval(cache,env, method, true, SOME(st), NONE, msg);
        starttime_r = Values.valueReal(starttime_v);
        stoptime_r = Values.valueReal(stoptime_v);
        interval_r = intReal(interval_i);
        init_filename = Util.stringAppendList({prefix_str,"_init.txt"});
      then
        (cache,init_filename,starttime_r,stoptime_r,interval_r,method_str);
    case (_,_,_,_,_,_)
      equation 
        Print.printErrorBuf("#- Ceval.calculateSimulationSettings failed\n");
      then
        fail();
  end matchcontinue;
end calculateSimulationSettings;

public function buildModel "function buildModel
 author: x02lucpo
 translates and builds the model by running compiler script on the generated makefile"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output Env.Cache outCache;
  output String outString1 "className";
  output String outString2 "method";
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String outString4 "initFileName";
algorithm 
  (outCache,outString1,outString2,outInteractiveSymbolTable3,outString4):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      Values.Value ret_val;
      Interactive.InteractiveSymbolTable st,st_1;
      DAELow.DAELow indexed_dlow_1;
      list<String> libs;
      String file_dir,cname_str,init_filename,method_str,filenameprefix,makefilename,oldDir,tempDir;
      Absyn.Path classname;
      Real starttime_r,stoptime_r,interval_r;
      list<Env.Frame> env;
      Exp.Exp exp,starttime,stoptime,interval,method,fileprefix,storeInTemp;
      Exp.ComponentRef cr;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
      Env.Cache cache;
      Boolean cdToTemp;
    case (cache,env,(exp as Exp.CALL(path = Absyn.IDENT(name = _),expLst = {Exp.CODE(Absyn.C_TYPENAME(classname),_),starttime,stoptime,interval,method,fileprefix,storeInTemp})),(st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (cache,Values.BOOL(cdToTemp),SOME(st)) = ceval(cache,env, storeInTemp, true, SOME(st_1), NONE, msg);
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,ret_val,st,indexed_dlow_1,libs,file_dir) = translateModel(cache,env, classname, st_1, msg, fileprefix);
        cname_str = Absyn.pathString(classname);
        (cache,init_filename,starttime_r,stoptime_r,interval_r,method_str) = calculateSimulationSettings(cache,env, exp, st, msg, cname_str);
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        SimCodegen.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, 
          starttime_r, stoptime_r, interval_r,method_str);
        makefilename = generateMakefilename(filenameprefix);
        compileModel(filenameprefix, libs, file_dir);
        _ = System.cd(oldDir);
        // s_call = Util.stringAppendList({"make -f ",cname_str, ".makefile\n"});
      then
        (cache,filenameprefix,method_str,st,init_filename);
    case (_,_,_,_,_)
      then
        fail();
  end matchcontinue;
end buildModel;

protected function changeToTempDirectory "function changeToTempDirectory
changes to temp directory (set using the functions from Settings.mo) 
if the boolean flag given as input is true"
	input Boolean cdToTemp;
algorithm
  _ := matchcontinue(cdToTemp)
  local String tempDir;
    case(true) equation
   			tempDir = Settings.getTempDirectoryPath();
        0 = System.cd(tempDir);
        then ();
    case(_) then ();
  end matchcontinue;
end changeToTempDirectory;

public function getFileDir "function: getFileDir
  author: x02lucpo
  returns the dir where class file (.mo) was saved or 
  $OPENMODELICAHOME/work if the file was not saved yet"
  input Absyn.ComponentRef inComponentRef "class";
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String filename,pd,dir_1,omhome,omhome_1,cit;
      String pd_1;
      list<String> filename_1,dir;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation 
        p_class = Absyn.crefToPath(class_) "change to the saved files directory" ;
        cdef = Interactive.getPathedClassInProgram(p_class, p);
        filename = Absyn.classFilename(cdef);
        pd = System.pathDelimiter();
        (pd_1 :: _) = string_list_string_char(pd);
        filename_1 = Util.stringSplitAtChar(filename, pd_1);
        dir = Util.listStripLast(filename_1);
        dir_1 = Util.stringDelimitList(dir, pd);
      then
        dir_1;
    case (class_,p)
      equation 
        omhome = Settings.getInstallationDirectoryPath() "model not yet saved! change to $OPENMODELICAHOME/work" ;
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        cit = winCitation();
        dir_1 = Util.stringAppendList({cit,omhome_1,pd,"work",cit});
      then
        dir_1;
    case (_,_) then "";  /* this function should never fail */ 
  end matchcontinue;
end getFileDir;

protected function compileModel "function: compileModel
  author: PA, x02lucpo
  Compiles a model given a file-prefix, helper function to buildModel."
  input String inString1;
  input list<String> inStringLst2;
  input String inString3;
algorithm 
  _:= matchcontinue (inString1,inStringLst2,inString3)
    local
      String pd,omhome,omhome_1,cd_path,libsfilename,libs_str,s_call,fileprefix,file_dir,command,filename,str;
      list<String> libs;
      
      // If compileCommand not set, use $OPENMODELICAHOME\bin\Compile
    case (fileprefix,libs,file_dir) 
      equation 
        "" = Settings.getCompileCommand();
        pd = System.pathDelimiter();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        cd_path = System.pwd();
        libsfilename = stringAppend(fileprefix, ".libs");
        libs_str = Util.stringDelimitList(libs, " ");
        System.writeFile(libsfilename, libs_str);
        s_call = Util.stringAppendList({"set OPENMODELICAHOME=",omhome_1,"&& \"",
          omhome_1,pd,"bin",pd,"Compile","\""," ",fileprefix});
        //print(s_call);
        0 = System.systemCall(s_call)  ;
      then
        ();
        // If compileCommand is set.
    case (fileprefix,libs,file_dir)
      equation 
        command = Settings.getCompileCommand();
        false = Util.isEmptyString(command);
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        cd_path = System.pwd() "needed when the above rule does not work" ;
        libs_str = Util.stringDelimitList(libs, " ");
        libsfilename = stringAppend(fileprefix, ".libs");
        System.writeFile(libsfilename, libs_str);
        s_call = Util.stringAppendList({"set OPENMODELICAHOME=",omhome_1,"&& ",command," ",fileprefix});
        // print(s_call);
        0 = System.systemCall(s_call) ;
      then
        ();     
        
    case (fileprefix,libs,file_dir) /* compilation failed */ 
      equation 
        filename = Util.stringAppendList({fileprefix,".log"});
        0 = System.regularFileExists(filename);
        str = System.readFile(filename);
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
      then
        fail();
    case (fileprefix,libs,file_dir)
      local Integer retVal;
      equation 
        command = Settings.getCompileCommand();
        false = Util.isEmptyString(command);
        retVal = System.regularFileExists(command);
        true = retVal <> 0; 
        str=Util.stringAppendList({"command ",command," not found. Check $OPENMODELICAHOME"});
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
      then fail();
        
    case (fileprefix,libs,file_dir) /* compilation failed\\n */ 
      local Integer retVal;
      equation  
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        pd = System.pathDelimiter();
        /* adrpo - 2006-08-28 -> 
         * please leave Compile instead of Compile.bat 
         * here as it has to work on Linux too
         */
        s_call = Util.stringAppendList({"\"",omhome_1,pd,"bin",pd,"Compile","\""});
        retVal = System.regularFileExists(s_call);
        true = retVal <> 0; 
        str=Util.stringAppendList({"command ",s_call," not found. Check $OPENMODELICAHOME"});
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
      then
        fail();
    case (fileprefix,libs,file_dir)
      equation 
        Print.printErrorBuf("#- Error building simulation code. Ceval.compileModel failed.\n ");
      then
        fail();
  end matchcontinue;
end compileModel;

protected function winCitation "function: winCitation
  author: PA
  Returns a citation mark if platform is windows, otherwise empty string. 
  Used by simulate to make whitespaces work in filepaths for WIN32"
  output String outString;
algorithm 
  outString:=
  matchcontinue ()
    case ()
      equation 
        "WIN32" = System.platform();
      then
        "\"";
    case () then ""; 
  end matchcontinue;
end winCitation;

protected function getBuiltinAttribute "function: getBuiltinAttribute
  Retrieves a builtin attribute of a variable in a class by instantiating 
  the class and retrieving the attribute value from the flat variable."	
	input Env.Cache inCache;
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
  input String inString3;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable4;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inComponentRef1,inComponentRef2,inString3,inInteractiveSymbolTable4)
    local
      Absyn.Path classname_1;
      list<DAE.Element> dae,dae1;
      list<Env.Frame> env,env_1,env3,env4;
      Exp.ComponentRef cref_1,classname,cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Exp.Exp exp;
      String str,n,attribute;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<SCode.Class> sp,p_1;
      list<Interactive.InstantiatedClass> ic,ic_1;
      list<Interactive.InteractiveVariable> vars;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction r;
      ClassInf.State ci_state,ci_state_1;
      Connect.Sets csets_1;
      list<Types.Var> tys;
      Values.Value v;
      Env.Cache cache;
      list<Interactive.LoadedFile> lf;
    case (cache,classname,cref,"stateSelect",
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf)))
      equation 
        classname_1 = Static.componentRefToPath(classname) "Check cached instantiated class" ;
        Interactive.INSTCLASS(_,dae,env) = Interactive.getInstantiatedClass(ic, classname_1);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT("stateSelect",{}));
        (cache,attr,ty,Types.EQBOUND(exp,_,_)) = Lookup.lookupVar(cache,env, cref_1);
        str = Exp.printExpStr(exp);
      then
        (cache,Values.STRING(str),st);
    case (cache,classname,cref,"stateSelect",
      Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf,
        loadedFiles = lf))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        p_1 = SCode.elaborate(p);
        (cache,env) = Inst.makeEnvFromProgram(cache,p_1, Absyn.IDENT(""));
        (cache,(c as SCode.CLASS(n,_,encflag,r,_)),env_1) = Lookup.lookupClass(cache,env, classname_1, true);
        env3 = Env.openScope(env_1, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,dae1,env4,csets_1,ci_state_1,tys,_) = Inst.instClassIn(cache,env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT("stateSelect",{}));
        (cache,attr,ty,Types.EQBOUND(exp,_,_)) = Lookup.lookupVar(cache,env4, cref_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname_1,dae1,env4));
        str = Exp.printExpStr(exp);
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,sp,ic_1,vars,cf,lf));
    case (cache,classname,cref,attribute,
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf)))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        Interactive.INSTCLASS(_,dae,env) = Interactive.getInstantiatedClass(ic, classname_1);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT(attribute,{}));
        (cache,attr,ty,Types.VALBOUND(v)) = Lookup.lookupVar(cache,env, cref_1);
      then
        (cache,v,st);
    case (cache,classname,cref,attribute,
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf,
        loadedFiles = lf)))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        p_1 = SCode.elaborate(p);
        (cache,env) = Inst.makeEnvFromProgram(cache,p_1, Absyn.IDENT(""));
        (cache,(c as SCode.CLASS(n,_,encflag,r,_)),env_1) = Lookup.lookupClass(cache,env, classname_1, true);
        env3 = Env.openScope(env_1, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,dae1,env4,csets_1,ci_state_1,tys,_) = Inst.instClassIn(cache,env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT(attribute,{}));
        (cache,attr,ty,Types.VALBOUND(v)) = Lookup.lookupVar(cache,env4, cref_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname_1,dae1,env4));
      then
        (cache,v,Interactive.SYMBOLTABLE(p,sp,ic_1,vars,cf,lf));
  end matchcontinue;
end getBuiltinAttribute;

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
      Boolean impl;
      Msg msg;
      list<Inst.DimExp> dims;
      Values.Value v2;
      Exp.Type crtp;
      Exp.Exp exp,e;
      String cr_str,dim_str,size_str,expstr;
      list<Exp.Exp> es;
      Env.Cache cache;
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),dim,impl,st,msg)
      equation 
        (cache,attr,tp,bind) = Lookup.lookupVar(cache,env, cr) "If dimensions known, always ceval" ;
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
        (cache,attr,tp,bind) = Lookup.lookupVar(cache,env, cr) "If dimensions not known and impl=true, just silently fail" ;
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (cache,env,Exp.CREF(componentRef = cr,ty = tp),dim,(impl as false),st,MSG())
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,bind) = Lookup.lookupVar(cache,env, cr) "If dimensions not known and impl=false, error message" ;

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
        (cache,attr,tp,bind) = Lookup.lookupVar(cache,env, cr);
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,(impl as false),st,MSG())
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,Types.UNBOUND()) = Lookup.lookupVar(cache,env, cr) "For crefs without value binding" ;
        expstr = Exp.printExpStr(exp);
        Error.addMessage(Error.UNBOUND_VALUE, {expstr});
      then
        fail();
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,(impl as false),st,NO_MSG())
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,Types.UNBOUND()) = Lookup.lookupVar(cache,env, cr);
      then
        fail();
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,(impl as true),st,msg)
      local Exp.Exp dim;
      equation 
        (cache,attr,tp,Types.UNBOUND()) = Lookup.lookupVar(cache,env, cr) "For crefs without value binding. If impl=true just silently fail" ;
      then
        fail();
               
		/* For crefs with value binding
		e.g. size(x,1) when Real x[:]=fill(0,1); */
    case (cache,env,(exp as Exp.CREF(componentRef = cr,ty = crtp)),dim,impl,st,msg)
      local
        Values.Value v;
        Exp.Exp dim;
      equation 
        (cache,attr,tp,binding) = Lookup.lookupVar(cache,env, cr)  ;     
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
      list<Exp.ComponentRef> cr_lst,cr_lst2,cr_totlst,crs;
      Integer res;
      Exp.ComponentRef cr;
      Env.Cache cache;
      Absyn.Path path;
      Exp.ComponentRef prefix,currentPrefix;
      Absyn.Ident currentPrefixIdent;
    case (cache,(Env.FRAME(current6 = (crs,prefix)) :: _),cr)
      equation 
        cr_lst = Util.listSelect1(crs, cr, Exp.crefContainedIn);
        currentPrefixIdent= Exp.crefLastIdent(prefix);
        currentPrefix = Exp.CREF_IDENT(currentPrefixIdent,{});
 		    //	Select connect references that has cr as suffix and correct Prefix.
        cr_lst = Util.listSelect1R(cr_lst, currentPrefix, Exp.crefPrefixOf);
        
        // Select connect references that are identifiers (inside connectors)
        cr_lst2 = Util.listSelect(crs,Exp.crefIsIdent);
        cr_lst2 = Util.listSelect1(cr_lst2,cr,Exp.crefEqual);
        
        cr_totlst = listAppend(cr_lst,cr_lst2);
        res = listLength(cr_totlst);
        /*  
        print("cardinality(");print(Exp.printComponentRefStr(cr));print(")=");print(intString(res));
        print("\n");
        print("icrefs =");print(Util.stringDelimitList(Util.listMap(crs,Exp.printComponentRefStr),","));
        print("crefs =");print(Util.stringDelimitList(Util.listMap(cr_totlst,Exp.printComponentRefStr),","));
        print("\n");
       	print("prefix =");print(Exp.printComponentRefStr(prefix));print("\n");
       	*/
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
      Real rv,rv_1,rvt,rv_2;
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
        (cache,Values.INTEGER(ri),st);
    case (cache,env,{exp},impl,st,msg)
      equation 
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        ri_1 = ri + 1;
      then
        (cache,Values.INTEGER(ri_1),st);
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
        print("- Ceval.cevalBuiltinMax2 failed\n");
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
        Print.printBuf("#- Differentiation failed. Celab.cevalBuiltinDifferentiate failed.\n");
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
        Print.printBuf("#- Simplification failed. Ceval.cevalBuildinSimplify failed.\n");
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

protected function cevalGenerateFunction "function: cevalGenerateFunction
  Generates code for a given function name."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
algorithm 
  outCache :=
  matchcontinue (inCache,inEnv,inPath)
    local
      String pathstr,gencodestr,filename;
      list<Env.Frame> env;
      Absyn.Path path;
      Env.Cache cache;
    case (cache,env,path)
      equation 
         (cache,false) = Static.isExternalObjectFunction(cache,env,path); //ext objs functions not possible to ceval.
        Debug.fprintln("ceval", "/*- Ceval.cevalGenerateFunction starting*/");
        pathstr = ModUtil.pathString2(path, "_");
        (cache,gencodestr,_) = cevalGenerateFunctionStr(cache,path, env, {});
        filename = stringAppend(pathstr, ".c");
        Print.clearBuf();
        Print.printBuf("#include \"modelica.h\"\n#include <stdio.h>\n#include <stdlib.h>\n#include <errno.h>\n");
        Print.printBuf(gencodestr);
        Print.printBuf("\nint main(int argc, char** argv)\n");
        Print.printBuf("{\n\n  if (argc != 3)\n");
        Print.printBuf("{\n      fprintf(stderr,\"# Incorrect number of arguments\\n\");\n");
        Print.printBuf("return 1;\n    }\n");
        Print.printBuf("_");
        Print.printBuf(pathstr);
        Print.printBuf("_read_call_write(argv[1],argv[2]);\n  return 0;\n}\n");
        Print.writeBuf(filename);
        System.compileCFile(filename);
      then
        (cache);
    case (cache,_,_)
      equation 
        Debug.fprint("failtrace", "/*- Ceval.cevalGenerateFunction failed*/\n");
      then
        fail();
  end matchcontinue;
end cevalGenerateFunction;

protected function cevalGenerateFunctionStr "function: cevalGenerateFunctionStr
  Generates a function with the given path, and all functions that are called
  within that function. The string list contains names of functions already
  generated, which won\'t be generated again."
 	input Env.Cache inCache;
  input Absyn.Path inPath;
  input Env.Env inEnv;
  input list<Absyn.Path> inAbsynPathLst;
  output Env.Cache outCache;
  output String outString;
  output list<Absyn.Path> outAbsynPathLst;
algorithm 
  (outCache,outString,outAbsynPathLst):=
  matchcontinue (inCache,inPath,inEnv,inAbsynPathLst)
    local
      Absyn.Path gfmember,path;
      list<Env.Frame> env,env_1,env_2;
      list<Absyn.Path> gflist,calledfuncs,gflist_1;
      SCode.Class cls;
      list<DAE.Element> d;
      list<String> debugfuncs,calledfuncsstrs,libs,calledfuncsstrs_1;
      String debugfuncsstr,funcname,funccom,thisfuncstr,resstr;
      DAE.DAElist d_1;
      Env.Cache cache;
    case (cache,path,env,gflist) /* If getmember succeeds, path is in generated functions list, so do nothing */ 
      equation 
        gfmember = Util.listGetMemberOnTrue(path, gflist, ModUtil.pathEqual);
      then
        (cache,"",gflist);
    case (cache,path,env,gflist) /* If getmember fails, path is not in generated functions list, hence generate it */ 
      equation 
        failure(_ = Util.listGetMemberOnTrue(path, gflist, ModUtil.pathEqual));
        Debug.fprintln("ceval", "/*- Ceval.cevalGenerateFunctionStr starting*/");
        (cache,cls,env_1) = Lookup.lookupClass(cache,env, path, false);
        Debug.fprintln("ceval", "/*- ceval_generate_function_str instantiating*/");
        (cache,env_2,d) = Inst.implicitFunctionInstantiation(cache,env_1, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cls, {});
        Debug.fprint("ceval", "/*- Ceval.cevalGenerateFunctionStr getting functions: ");
        calledfuncs = SimCodegen.getCalledFunctionsInFunction(path, DAE.DAE(d));
        debugfuncs = Util.listMap(calledfuncs, Absyn.pathString);
        debugfuncsstr = Util.stringDelimitList(debugfuncs, ", ");
        Debug.fprint("ceval", debugfuncsstr);
        Debug.fprintln("ceval", "*/");
        (cache,calledfuncsstrs,gflist_1) = cevalGenerateFunctionStrList(cache,calledfuncs, env, gflist);
        Debug.fprint("ceval", "/*- Ceval.cevalGenerateFunctionStr prefixing dae */");
        d_1 = ModUtil.stringPrefixParams(DAE.DAE(d));
        Print.clearBuf();
        funcname = Absyn.pathString(path);
        funccom = Util.stringAppendList({"/*---FUNC: ",funcname," ---*/\n\n"});
        Print.printBuf(funccom);
        Debug.fprintln("ceval", "/*- Ceval.cevalGenerateFunctionStr generating functions */");
        libs = Codegen.generateFunctions(d_1);
        thisfuncstr = Print.getString();
        calledfuncsstrs_1 = Util.listAppendElt(thisfuncstr, calledfuncsstrs);
        resstr = Util.stringDelimitList(calledfuncsstrs_1, "\n\n");
      then
        (cache,resstr,(path :: gflist));
    case (_,_,env,_)
      equation 
        Debug.fprint("failtrace", "/*- Ceval.cevalGenerateFunctionStr failed*/\n");
      then
        fail();
  end matchcontinue;
end cevalGenerateFunctionStr;

protected function cevalGenerateFunctionStrList "function: cevalGenerateFunctionStrList
  Generates code for several functions."
	input Env.Cache inCache;
  input list<Absyn.Path> inAbsynPathLst1;
  input Env.Env inEnv2;
  input list<Absyn.Path> inAbsynPathLst3;
  output Env.Cache outCache;
  output list<String> outStringLst;
  output list<Absyn.Path> outAbsynPathLst;
algorithm 
  (outCache,outStringLst,outAbsynPathLst):=
  matchcontinue (inCache,inAbsynPathLst1,inEnv2,inAbsynPathLst3)
    local
      list<Env.Frame> env;
      list<Absyn.Path> gflist,gflist_1,gflist_2,rest;
      String firststr;
      list<String> reststr;
      Absyn.Path first;
      Env.Cache cache;
    case (cache,{},env,gflist) then (cache,{},gflist); 
    case (cache,(first :: rest),env,gflist)
      equation 
        (cache,firststr,gflist_1) = cevalGenerateFunctionStr(cache,first, env, gflist);
        (cache,reststr,gflist_2) = cevalGenerateFunctionStrList(cache,rest, env, gflist_1);
      then
        (cache,(firststr :: reststr),gflist_2);
  end matchcontinue;
end cevalGenerateFunctionStrList;

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
      Exp.Exp s1;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String RowString,matrixDimensionString;
      Env.Cache cache;
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg)
      equation 
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Exp.ASUB(s1,row), impl, st, NONE, msg);
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
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Exp.ASUB(s1,row), impl, st, NONE, msg);
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
        (cache,Values.INTEGER(rv2),_) = ceval(cache,env, Exp.ASUB(s1,row), impl, st, NONE, msg);
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
        (cache,Values.INTEGER(rv2),_) = ceval(cache,env, Exp.ASUB(s1,row), impl, st, NONE, msg);
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
        (cache,attr,tp,bind) = Lookup.lookupVar(cache,env, cr);
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
    case (v1,Exp.GREATER(ty = t),v2)
      equation 
        v = cevalRelation(v2, Exp.LESS(t), v1);
      then
        v;
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
    case (Values.INTEGER(integer = i1),Exp.NEQUAL(ty = Exp.INT()),Values.INTEGER(integer = i2)) /* Reals */ 
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
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "- Ceval.cevalRelation failed\n");
        print("- Ceval.cevalRelation failed\n");
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
    case (cache,env,c,impl,msg) /* Search in env for binding. */ 
      equation 
        (cache,attr,ty,binding) = Lookup.lookupVar(cache,env, c);
        (cache,v) = cevalCrefBinding(cache,env, c, binding, impl, msg);
      then
        (cache,v);
    case (cache,env,c,(impl as false),MSG())
      equation 
        failure((_,_,_,_) = Lookup.lookupVar(cache,env, c));
        scope_str = Env.printEnvPathStr(env);
        str = Exp.printComponentRefStr(c);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {str,scope_str});
      then
        fail();
    case (cache,env,c,(impl as false),NO_MSG())
      equation 
        failure((_,_,_,_) = Lookup.lookupVar(cache,env, c));
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
        (cache,_,tp,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);
    case (cache,env,_,Types.UNBOUND(),(impl as false),MSG())
      equation 
        Print.printBuf("- Ceval.cevalCrefBinding failed (UNBOUND)\n");
      then
        fail();
    case (cache,env,_,Types.UNBOUND(),(impl as true),MSG())
      equation 
        Debug.fprint("ceval", "#- Ceval.cevalCrefBinding: Ignoring unbound when implicit");
      then
        fail();
    case (cache,env,Exp.CREF_IDENT(ident = id,subscriptLst = subsc),Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,MSG()) /* REDUCTION bindings */ 
      equation 
        Exp.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        equality(rfn = "array");
        Debug.fprintln("ceval", "#- Ceval.cevalCrefBinding: Array evaluation");
      then
        fail();
    case (cache,env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,msg) /* REDUCTION bindings Exp.CREF_IDENT(id,subsc) */ 
      equation 
        Exp.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        failure(equality(rfn = "array"));
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache,env, exp, impl, NONE, NONE, msg);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);
    case (cache,env,cr,Types.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = Types.C_VAR()),impl,msg) /* arbitrary expressions, C_VAR, value exists. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, e_val, sizelst, impl, msg);
      then
        (cache,res);
    case (cache,env,cr,Types.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = Types.C_PARAM()),impl,msg) /* arbitrary expressions, C_PARAM, value exists. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,res)= cevalSubscriptValue(cache,env, subsc, e_val, sizelst, impl, msg);
      then
        (cache,res);
    case (cache,env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,msg) /* arbitrary expressions. When binding has optional value. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (cache,v,_) = ceval(cache,env, exp, impl, NONE, NONE, msg);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, sizelst, impl, msg);
      then
        (cache,res);
    case (cache,env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_PARAM()),impl,msg) /* arbitrary expressions. When binding has optional value. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (cache,_,tp,_) = Lookup.lookupVar(cache,env, cr_1) "Exp.CREF_IDENT(id,{})" ;
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
        s1 = Exp.printComponentRefStr(e1);
        s2 = Exp.printExpStr(exp);
        str = Util.stringAppendList({"- Ceval.cevalCrefBinding: ",s1," = ",s2," failed\n"});
        Debug.fprint("failtrace", str);
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
  values."
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

protected function cevalSubscript "function: cevalSubscript
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
    case (cache,env,Exp.WHOLEDIM(),_,_,_) then (cache,Exp.WHOLEDIM()); 
    case (cache,env,Exp.INDEX(exp = e1),dim,impl,msg)
      equation 
        (cache,v1,_) = ceval(cache,env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
      then
        (cache,Exp.INDEX(e1_1));
    case (cache,env,Exp.SLICE(exp = e1),dim,impl,msg)
      equation 
        (cache,v1,_) = ceval(cache,env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
      then
        (cache,Exp.SLICE(e1_1));
  end matchcontinue;
end cevalSubscript;

end Ceval;

