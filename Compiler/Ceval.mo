package Ceval "
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

  
  file:	 Ceval.rml
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

public import OpenModelica.Compiler.Env;

public import OpenModelica.Compiler.Exp;

public import OpenModelica.Compiler.Interactive;

public import OpenModelica.Compiler.Values;

public import OpenModelica.Compiler.DAELow;

public import OpenModelica.Compiler.Absyn;

public 
uniontype Msg
  record MSG "Give error message" end MSG;

  record NO_MSG "Do not give error message" end NO_MSG;

end Msg;

protected import OpenModelica.Compiler.SimCodegen;

protected import OpenModelica.Compiler.Static;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.Types;

protected import OpenModelica.Compiler.ModUtil;

protected import OpenModelica.Compiler.System;

protected import OpenModelica.Compiler.SCode;

protected import OpenModelica.Compiler.Inst;

protected import OpenModelica.Compiler.Lookup;

protected import OpenModelica.Compiler.Dump;

protected import OpenModelica.Compiler.DAE;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.ClassInf;

protected import OpenModelica.Compiler.RTOpts;

protected import OpenModelica.Compiler.Parser;

protected import OpenModelica.Compiler.Prefix;

protected import OpenModelica.Compiler.Codegen;

protected import OpenModelica.Compiler.ClassLoader;

protected import OpenModelica.Compiler.Derive;

protected import OpenModelica.Compiler.Connect;

protected import OpenModelica.Compiler.Error;

protected import OpenModelica.Compiler.Settings;

protected function cevalBuiltin "adrpo -- not used
with \"ErrorExt.rml\"

  function: cevalBuiltin
 
  Helper for ceval. Parts for builtin calls are moved here, for readability.
  See ceval for documentation.
 
  inputs: (Env.Env, Exp.Exp, bool /* impl */,
			  Interactive.InteractiveSymbolTable option, 
			  int option,
			  Msg) 
  outputs: (Values.Value, Interactive.InteractiveSymbolTable option)
  
  NOTE:    It\'s ok if ceval_builtin fails. Just means the call wasn\'t a builtin function 
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Option<Integer> inIntegerOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inIntegerOption,inMsg)
    local
      partial function FuncTypeEnv_FrameLstExp_ExpLstBooleanInteractive_InteractiveSymbolTableOptionMsgToValues_ValueInteractive_InteractiveSymbolTableOption
        input list<Env.Frame> inEnvFrameLst;
        input list<Exp.Exp> inExpExpLst;
        input Boolean inBoolean;
        input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
        input Msg inMsg;
        output Values.Value outValue;
        output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
      end FuncTypeEnv_FrameLstExp_ExpLstBooleanInteractive_InteractiveSymbolTableOptionMsgToValues_ValueInteractive_InteractiveSymbolTableOption;
      Values.Value v,newval;
      Option<Interactive.InteractiveSymbolTable> st;
      list<Env.Frame> env;
      Exp.Exp exp,dim,e;
      Boolean impl,builtin;
      Msg msg;
      FuncTypeEnv_FrameLstExp_ExpLstBooleanInteractive_InteractiveSymbolTableOptionMsgToValues_ValueInteractive_InteractiveSymbolTableOption handler;
      String id;
      list<Exp.Exp> args,expl;
      list<Values.Value> vallst;
      Absyn.Path funcpath;
    case (env,Exp.SIZE(exp = exp,the = SOME(dim)),impl,st,_,msg)
      equation 
        (v,st) = cevalBuiltinSize(env, exp, dim, impl, st, msg) "Handle size separately" ;
      then
        (v,st);
    case (env,Exp.SIZE(exp = exp,the = NONE),impl,st,_,msg)
      equation 
        (v,st) = cevalBuiltinSizeMatrix(env, exp, impl, st, msg);
      then
        (v,st);
    case (env,Exp.CALL(path = Absyn.IDENT(name = id),expLst = args,builtin = builtin),impl,st,_,msg) /* buildin: as true */ 
      equation 
        handler = cevalBuiltinHandler(id);
        (v,st) = handler(env, args, impl, st, msg);
      then
        (v,st);
    case (env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = (builtin as true))),impl,(st as NONE),_,msg)
      equation 
        vallst = cevalList(env, expl, impl, st, msg);
        newval = cevalCallFunction(env, e, vallst, msg);
      then
        (newval,st);
  end matchcontinue;
end cevalBuiltin;

protected function cevalBuiltinHandler "function: cevalBuiltinHandler
 
  This function dispatches builtin functions and operators to a dedicated
  function that evaluates that particular function.
  It takes an identifier as input and returns a function that evaluates that
  function or operator.
 
  inputs: Absyn.Ident  /* operator/function name */
  outputs: ((Env.Env, 
		Exp.Exp list, 
		bool, 
		Interactive.InteractiveSymbolTable option,
		Msg) => (Values.Value, Interactive.InteractiveSymbolTable option))
 
  NOTE:   size handled specially. see ceval_builtin:
            removed: axiom	ceval_builtin_handler \"size\" => ceval_builtin_size
"
  input Absyn.Ident inIdent;
  output FuncTypeEnv_EnvExp_ExpLstBooleanInteractive_InteractiveSymbolTableOptionMsgToValues_ValueInteractive_InteractiveSymbolTableOption outFuncTypeEnvEnvExpExpLstBooleanInteractiveInteractiveSymbolTableOptionMsgToValuesValueInteractiveInteractiveSymbolTableOption;
  partial function FuncTypeEnv_EnvExp_ExpLstBooleanInteractive_InteractiveSymbolTableOptionMsgToValues_ValueInteractive_InteractiveSymbolTableOption
    input Env.Env inEnv;
    input list<Exp.Exp> inExpExpLst;
    input Boolean inBoolean;
    input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
    input Msg inMsg;
    output Values.Value outValue;
    output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
  end FuncTypeEnv_EnvExp_ExpLstBooleanInteractive_InteractiveSymbolTableOptionMsgToValues_ValueInteractive_InteractiveSymbolTableOption;
algorithm 
  outFuncTypeEnvEnvExpExpLstBooleanInteractiveInteractiveSymbolTableOptionMsgToValuesValueInteractiveInteractiveSymbolTableOption:=
  matchcontinue (inIdent)
    local String id;
    case "floor" then cevalBuiltinFloor; 
    case "ceil" then cevalBuiltinCeil; 
    case "abs" then cevalBuiltinAbs; 
    case "sqrt" then cevalBuiltinSqrt; 
    case "div" then cevalBuiltinDiv; 
    case "sin" then cevalBuiltinSin; 
    case "cos" then cevalBuiltinCos; 
    case "asin" then cevalBuiltinAsin; 
    case "acos" then cevalBuiltinAcos; 
    case "atan" then cevalBuiltinAtan; 
    case "tan" then cevalBuiltinTan; 
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
    case id
      equation 
        Debug.fprint("ceval", "No ceval_builtin_handler found for: ");
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
 
  The last argument is an optional dimension.
  
  inputs: (Env.Env, Exp.Exp, bool /* impl */,
			Interactive.InteractiveSymbolTable option, 
			int option,
			Msg) 
  outputs: (Values.Value, Interactive.InteractiveSymbolTable option)
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Option<Integer> inIntegerOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inIntegerOption,inMsg)
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
      Absyn.Code c;
      list<Values.Value> es_1,elts,vallst,vlst1,vlst2,reslst,aval,rhvals,lhvals,arr,arr_1,ivals,rvals,vallst_1,vals;
      list<Exp.Exp> es,expl;
      list<list<tuple<Exp.Exp, Boolean>>> expll;
      Values.Value v,newval,value,sval,elt1,elt2,v_1,lhs_1,rhs_1;
      Exp.Exp lh,rh,e,lhs,rhs,start,stop,step,e1,e2,iterexp;
      Absyn.Path funcpath,func;
      Absyn.Program p;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cflist;
      Exp.Operator relop;
    case (_,Exp.ICONST(integer = x),_,st,_,_) then (Values.INTEGER(x),st); 

    case (_,Exp.RCONST(real = x),_,st,_,_)
      local Real x;
      then
        (Values.REAL(x),st);

    case (_,Exp.SCONST(string = x),_,st,_,_)
      local String x;
      then
        (Values.STRING(x),st);

    case (_,Exp.BCONST(bool = x),_,st,_,_)
      local Boolean x;
      then
        (Values.BOOL(x),st);

    case (_,Exp.END(),_,st,SOME(dim),_) then (Values.INTEGER(dim),st); 

    case (_,Exp.END(),_,st,NONE,MSG())
      equation 
        Error.addMessage(Error.END_ILLEGAL_USE_ERROR, {});
      then
        fail();

    case (_,Exp.END(),_,st,NONE,NO_MSG()) then fail(); 

    case (env,Exp.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation 
        exp_1 = cevalAstExp(env, exp, impl, st, msg);
      then
        (Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (env,Exp.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,st,_,msg)
      equation 
        exp_1 = cevalAstExp(env, exp, impl, st, msg);
      then
        (Values.CODE(Absyn.C_EXPRESSION(exp_1)),st);

    case (env,Exp.CODE(code = Absyn.C_ELEMENT(element = elt)),impl,st,_,msg)
      equation 
        elt_1 = cevalAstElt(env, elt, impl, st, msg);
      then
        (Values.CODE(Absyn.C_ELEMENT(elt_1)),st);

    case (env,Exp.CODE(code = c),_,st,_,_) then (Values.CODE(c),st); 

    case (env,Exp.ARRAY(array = es),impl,st,_,msg)
      equation 
        es_1 = cevalList(env, es, impl, st, msg);
        l = listLength(es_1);
      then
        (Values.ARRAY(es_1),st);

    case (env,Exp.MATRIX(scalar = expll),impl,st,_,msg)
      equation 
        elts = cevalMatrixelt(env, expll, impl, msg);
      then
        (Values.ARRAY(elts),st);

    case (env,Exp.CREF(componentRef = c),(impl as false),SOME(st),_,msg)
      local
        Exp.ComponentRef c;
        Interactive.InteractiveSymbolTable st;
      equation 
        v = cevalCref(env, c, false, msg) "When in interactive mode, always evalutate crefs, i.e non-implicit
	    mode.." ;
      then
        (v,SOME(st));

    case (env,Exp.CREF(componentRef = c),impl,st,_,msg)
      local Exp.ComponentRef c;
      equation 
        v = cevalCref(env, c, impl, msg);
      then
        (v,st);

    case (env,exp,impl,st,dim,msg)
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (v,st_1) = cevalBuiltin(env, exp, impl, st, dim, msg);
      then
        (v,st_1);

    case (env,Exp.BINARY(exp = lh,operator = Exp.POW(type_ = Exp.INT()),binary = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.INTEGER(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.INTEGER(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        lhvr = intReal(lhv);
        rhvr = intReal(rhv);
        resr = realPow(lhvr, rhvr);
        res = realInt(resr);
      then
        (Values.INTEGER(res),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.POW(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg)
      local
        Real lhv;
        Option<Integer> dim;
      equation 
        (Values.REAL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.INTEGER(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        rhvr = intReal(rhv);
        resr = realPow(lhv, rhvr);
      then
        (Values.REAL(resr),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.POW(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg)
      local
        Real rhv;
        Option<Integer> dim;
      equation 
        (Values.INTEGER(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.REAL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        lhvr = intReal(lhv);
        resr = realPow(lhvr, rhv);
      then
        (Values.REAL(resr),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.POW(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg)
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation 
        (Values.REAL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.REAL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        resr = realPow(lhv, rhv);
      then
        (Values.REAL(resr),st_2);

    case (env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),impl,st,_,msg) /* Call functions FIXME: functions are always generated. Put back the check
	  and write another rule for the false case that generates the function */ 
      equation 
        vallst = cevalList(env, expl, impl, st, msg);
        newval = cevalCallFunction(env, e, vallst, msg);
      then
        (newval,st);

    case (env,(e as Exp.CALL(path = _)),(impl as false),NONE,_,NO_MSG()) then fail(); 

    case (env,(e as Exp.CALL(path = _)),(impl as true),SOME(st),_,msg)
      local Interactive.InteractiveSymbolTable st;
      equation 
        (value,st) = cevalInteractiveFunctions(env, e, st, msg);
      then
        (value,SOME(st));

    case (env,(e as Exp.CALL(path = func,expLst = expl)),(impl as true),(st as SOME(_)),_,msg)
      equation 
        vallst = cevalList(env, expl, impl, st, msg) "Call of record constructors, etc., i.e. functions that can be 
	 constant propagated." ;
        newval = cevalFunction(env, func, vallst, impl, msg);
      then
        (newval,st);

    case (env,(e as Exp.CALL(path = func,expLst = expl)),(impl as true),(st as SOME(Interactive.SYMBOLTABLE(p,_,_,_,cflist))),_,msg)
      equation 
        true = Static.isFunctionInCflist(cflist, func) "Call externally implemented functions." ;
        vallst = cevalList(env, expl, impl, st, msg);
        funcstr = ModUtil.pathString2(func, "_");
        infilename = stringAppend(funcstr, "_in.txt");
        outfilename = stringAppend(funcstr, "_out.txt");
        Values.writeToFileAsArgs(vallst, infilename);
        System.executeFunction(funcstr);
        newval = System.readValuesFromFile(outfilename);
      then
        (newval,st);

    case (env,Exp.BINARY(exp = lh,operator = Exp.ADD(type_ = Exp.STRING()),binary = rh),impl,st,_,msg) /* Strings */ 
      local String lhv,rhv;
      equation 
        (Values.STRING(lhv),_) = ceval(env, lh, impl, st, NONE, msg);
        (Values.STRING(rhv),_) = ceval(env, rh, impl, st, NONE, msg);
        str = stringAppend(lhv, rhv);
      then
        (Values.STRING(str),st);

    case (env,Exp.BINARY(exp = lh,operator = Exp.ADD(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg) /* Numerical */ 
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation 
        (Values.REAL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.REAL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        sum = lhv +. rhv;
      then
        (Values.REAL(sum),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.ADD_ARR(type_ = _),binary = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.ARRAY(vlst1),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.ARRAY(vlst2),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        reslst = Values.addElementwiseArrayelt(vlst1, vlst2);
      then
        (Values.ARRAY(reslst),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.SUB_ARR(type_ = _),binary = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.ARRAY(vlst1),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.ARRAY(vlst2),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        reslst = Values.subElementwiseArrayelt(vlst1, vlst2);
      then
        (Values.ARRAY(reslst),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL_SCALAR_ARRAY(a = _),binary = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (sval,st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.ARRAY(aval),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        reslst = Values.multScalarArrayelt(sval, aval);
      then
        (Values.ARRAY(reslst),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL_ARRAY_SCALAR(type_ = _),binary = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (sval,st_1) = ceval(env, rh, impl, st, dim, msg);
        (Values.ARRAY(aval),st_2) = ceval(env, lh, impl, st_1, dim, msg);
        reslst = Values.multScalarArrayelt(sval, aval);
      then
        (Values.ARRAY(reslst),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.DIV_ARRAY_SCALAR(type_ = _),binary = rh),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (sval,st_1) = ceval(env, rh, impl, st, dim, msg);
        (Values.ARRAY(aval),st_2) = ceval(env, lh, impl, st_1, dim, msg);
        reslst = Values.divArrayeltScalar(sval, aval);
      then
        (Values.ARRAY(reslst),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL_SCALAR_PRODUCT(type_ = _),binary = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation 
        (Values.ARRAY(rhvals),st_1) = ceval(env, rh, impl, st, dim, msg);
        (Values.ARRAY(lhvals),st_2) = ceval(env, lh, impl, st_1, dim, msg);
        res = Values.multScalarProduct(rhvals, lhvals);
      then
        (res,st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL_MATRIX_PRODUCT(type_ = _),binary = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation 
        (Values.ARRAY((lhvals as (elt1 :: _))),st_1) = ceval(env, lh, impl, st, dim, msg) "{{..}..{..}}  {...}" ;
        (Values.ARRAY((rhvals as (elt2 :: _))),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        true = Values.isArray(elt1);
        false = Values.isArray(elt2);
        res = Values.multScalarProduct(lhvals, rhvals);
      then
        (res,st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL_MATRIX_PRODUCT(type_ = _),binary = rh),impl,st,dim,msg)
      local
        Values.Value res;
        Option<Integer> dim;
      equation 
        (Values.ARRAY((rhvals as (elt1 :: _))),st_1) = ceval(env, rh, impl, st, dim, msg) "{...}  {{..}..{..}}" ;
        (Values.ARRAY((lhvals as (elt2 :: _))),st_2) = ceval(env, lh, impl, st_1, dim, msg);
        true = Values.isArray(elt1);
        false = Values.isArray(elt2);
        res = Values.multScalarProduct(lhvals, rhvals);
      then
        (res,st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL_MATRIX_PRODUCT(type_ = _),binary = rh),impl,st,dim,msg)
      local
        list<Values.Value> res;
        Option<Integer> dim;
      equation 
        (Values.ARRAY((rhvals as (elt1 :: _))),st_1) = ceval(env, rh, impl, st, dim, msg) "{{..}..{..}}  {{..}..{..}}" ;
        (Values.ARRAY((lhvals as (elt2 :: _))),st_2) = ceval(env, lh, impl, st_1, dim, msg);
        true = Values.isArray(elt1);
        true = Values.isArray(elt2);
        res = Values.multMatrix(lhvals, rhvals);
      then
        (Values.ARRAY(res),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.ADD(type_ = Exp.INT()),binary = rh),impl,st,dim,msg)
      local
        Integer sum;
        Option<Integer> dim;
      equation 
        (Values.INTEGER(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.INTEGER(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        sum = lhv + rhv;
      then
        (Values.INTEGER(sum),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.SUB(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg) /*  */ 
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation 
        (Values.REAL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.REAL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        sum = lhv -. rhv;
      then
        (Values.REAL(sum),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.SUB(type_ = Exp.INT()),binary = rh),impl,st,dim,msg)
      local
        Integer sum;
        Option<Integer> dim;
      equation 
        (Values.INTEGER(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.INTEGER(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        sum = lhv - rhv;
      then
        (Values.INTEGER(sum),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg) /*  */ 
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation 
        (Values.REAL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.REAL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        sum = lhv*.rhv;
      then
        (Values.REAL(sum),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.DIV(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg)
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation 
        (Values.REAL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.REAL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        div = lhv/.rhv;
      then
        (Values.REAL(div),st_2);

    case (env,Exp.BINARY(exp = lh,operator = Exp.DIV(type_ = Exp.REAL()),binary = rh),impl,st,dim,msg)
      local
        Real lhv,rhv;
        Option<Integer> dim;
      equation 
        (Values.REAL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.REAL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        failure(_ = realDiv(lhv, rhv));
        lh_str = Exp.printExpStr(lh);
        rh_str = Exp.printExpStr(rh);
        Error.addMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str});
      then
        fail();

    case (env,Exp.BINARY(exp = lh,operator = Exp.MUL(type_ = Exp.INT()),binary = rh),impl,st,dim,msg)
      local
        Integer sum;
        Option<Integer> dim;
      equation 
        (Values.INTEGER(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.INTEGER(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        sum = lhv*rhv;
      then
        (Values.INTEGER(sum),st_2);

    case (env,Exp.UNARY(operator = Exp.UMINUS_ARR(type_ = _),unary = exp),impl,st,dim,msg) /*  unary minus of array */ 
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (Values.ARRAY(arr),st_1) = ceval(env, exp, impl, st, dim, msg);
        arr_1 = Util.listMap(arr, Values.valueNeg);
      then
        (Values.ARRAY(arr_1),st_1);

    case (env,Exp.UNARY(operator = Exp.UMINUS(type_ = _),unary = exp),impl,st,dim,msg)
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (v,st_1) = ceval(env, exp, impl, st, dim, msg);
        v_1 = Values.valueNeg(v);
      then
        (v_1,st_1);

    case (env,Exp.UNARY(operator = Exp.UPLUS(type_ = _),unary = exp),impl,st,dim,msg)
      local
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        (v,st_1) = ceval(env, exp, impl, st, dim, msg);
      then
        (v,st_1);

    case (env,Exp.LBINARY(exp = lh,operator = Exp.AND(),logical = rh),impl,st,dim,msg) /* Logical */ 
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation 
        (Values.BOOL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.BOOL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        x = boolAnd(lhv, rhv);
      then
        (Values.BOOL(x),st_2);

    case (env,Exp.LBINARY(exp = lh,operator = Exp.OR(),logical = rh),impl,st,dim,msg)
      local
        Boolean lhv,rhv,x;
        Option<Integer> dim;
      equation 
        (Values.BOOL(lhv),st_1) = ceval(env, lh, impl, st, dim, msg);
        (Values.BOOL(rhv),st_2) = ceval(env, rh, impl, st_1, dim, msg);
        x = boolOr(lhv, rhv);
      then
        (Values.BOOL(x),st_2);

    case (env,Exp.LUNARY(operator = Exp.NOT(),logical = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.BOOL(b),st_1) = ceval(env, e, impl, st, dim, msg);
        b_1 = boolNot(b);
      then
        (Values.BOOL(b_1),st_1);

    case (env,Exp.RELATION(exp = lhs,operator = relop,relation_ = rhs),impl,st,dim,msg) /* Relations */ 
      local Option<Integer> dim;
      equation 
        (lhs_1,st_1) = ceval(env, lhs, impl, st, dim, msg);
        (rhs_1,st_2) = ceval(env, rhs, impl, st_1, dim, msg);
        v = cevalRelation(lhs_1, relop, rhs_1);
      then
        (v,st_2);

    case (env,Exp.RANGE(type_ = Exp.INT(),exp = start,expOption = NONE,range = stop),impl,st,dim,msg) /*  */ 
      local Option<Integer> dim;
      equation 
        (Values.INTEGER(start_1),st_1) = ceval(env, start, impl, st, dim, msg);
        (Values.INTEGER(stop_1),st_2) = ceval(env, stop, impl, st_1, dim, msg);
        arr = cevalRange(start_1, 1, stop_1);
      then
        (Values.ARRAY(arr),st_1);

    case (env,Exp.RANGE(type_ = Exp.INT(),exp = start,expOption = SOME(step),range = stop),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.INTEGER(start_1),st_1) = ceval(env, start, impl, st, dim, msg);
        (Values.INTEGER(step_1),st_2) = ceval(env, step, impl, st_1, dim, msg);
        (Values.INTEGER(stop_1),st_3) = ceval(env, stop, impl, st_2, dim, msg);
        arr = cevalRange(start_1, step_1, stop_1);
      then
        (Values.ARRAY(arr),st_3);

    case (env,Exp.RANGE(type_ = Exp.REAL(),exp = start,expOption = NONE,range = stop),impl,st,dim,msg)
      local
        Real start_1,stop_1,step;
        Option<Integer> dim;
      equation 
        (Values.REAL(start_1),st_1) = ceval(env, start, impl, st, dim, msg);
        (Values.REAL(stop_1),st_2) = ceval(env, stop, impl, st_1, dim, msg);
        diff = stop_1 -. start_1;
        step = intReal(1);
        arr = cevalRangeReal(start_1, step, stop_1) "bug in rml, 1.0 => 0.0 in cygwin" ;
      then
        (Values.ARRAY(arr),st_2);

    case (env,Exp.RANGE(type_ = Exp.REAL(),exp = start,expOption = SOME(step),range = stop),impl,st,dim,msg)
      local
        Real start_1,step_1,stop_1;
        Option<Integer> dim;
      equation 
        (Values.REAL(start_1),st_1) = ceval(env, start, impl, st, dim, msg);
        (Values.REAL(step_1),st_2) = ceval(env, step, impl, st_1, dim, msg);
        (Values.REAL(stop_1),st_3) = ceval(env, stop, impl, st_2, dim, msg);
        arr = cevalRangeReal(start_1, step_1, stop_1);
      then
        (Values.ARRAY(arr),st_3);

    case (env,Exp.CAST(type_ = Exp.REAL(),cast = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.INTEGER(i),st_1) = ceval(env, e, impl, st, dim, msg);
        r = intReal(i);
      then
        (Values.REAL(r),st_1);

    case (env,Exp.CAST(type_ = Exp.REAL(),cast = e),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.ARRAY(ivals),st_1) = ceval(env, e, impl, st, dim, msg);
        rvals = Values.typeConvert(Exp.INT(), Exp.REAL(), ivals);
      then
        (Values.ARRAY(rvals),st_1);

    case (env,Exp.CAST(type_ = Exp.REAL(),cast = (e as Exp.ARRAY(type_ = Exp.INT(),array = expl))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.ARRAY(vallst),st_1) = ceval(env, e, impl, st, dim, msg);
        vallst_1 = Values.typeConvert(Exp.INT(), Exp.REAL(), vallst);
      then
        (Values.ARRAY(vallst_1),st_1);

    case (env,Exp.CAST(type_ = Exp.REAL(),cast = (e as Exp.RANGE(type_ = Exp.INT()))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.ARRAY(vallst),st_1) = ceval(env, e, impl, st, dim, msg);
        vallst_1 = Values.typeConvert(Exp.INT(), Exp.REAL(), vallst);
      then
        (Values.ARRAY(vallst_1),st_1);

    case (env,Exp.CAST(type_ = Exp.REAL(),cast = (e as Exp.MATRIX(type_ = Exp.INT()))),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.ARRAY(vallst),st_1) = ceval(env, e, impl, st, dim, msg);
        vallst_1 = Values.typeConvert(Exp.INT(), Exp.REAL(), vallst);
      then
        (Values.ARRAY(vallst_1),st_1);

    case (env,Exp.IFEXP(exp1 = b,exp2 = e1,if_3 = e2),impl,st,dim,msg)
      local
        Exp.Exp b;
        Option<Integer> dim;
      equation 
        (Values.BOOL(true),st_1) = ceval(env, b, impl, st, dim, msg) "Ifexp, true branch" ;
        (v,st_2) = ceval(env, e1, impl, st_1, dim, msg);
      then
        (v,st_2);

    case (env,Exp.IFEXP(exp1 = b,exp2 = e1,if_3 = e2),impl,st,dim,msg)
      local
        Exp.Exp b;
        Option<Integer> dim;
      equation 
        (Values.BOOL(false),st_1) = ceval(env, b, impl, st, dim, msg) "Ifexp, false branch" ;
        (v,st_2) = ceval(env, e2, impl, st_1, dim, msg);
      then
        (v,st_2);

    case (env,Exp.ASUB(exp = e,array = indx),impl,st,dim,msg)
      local Option<Integer> dim;
      equation 
        (Values.ARRAY(vals),st_1) = ceval(env, e, impl, st, dim, msg) "asub" ;
        indx_1 = indx - 1;
        v = listNth(vals, indx_1);
      then
        (v,st_1);

    case (env,Exp.REDUCTION(path = p,expr = exp,ident = iter,range = iterexp),impl,st,dim,MSG()) /* (v,st) */ 
      local
        Absyn.Path p;
        Exp.Exp exp;
        Option<Integer> dim;
      equation 
        Print.printBuf("#-- ceval reduction\n");
      then
        fail();

    case (env,Exp.REDUCTION(path = p,expr = exp,ident = iter,range = iterexp),impl,st,dim,NO_MSG()) /* (v,st) */ 
      local
        Absyn.Path p;
        Exp.Exp exp;
        Option<Integer> dim;
      then
        fail();

    case (env,e,_,_,_,MSG()) /* ceval can apparently fa-il and that is ok, catched by other rules... */ 
      equation 
        Debug.fprint("failtrace", "- ceval failed: ");
        str = Exp.printExpStr(e);
        Debug.fprint("failtrace", str);
        Debug.fprint("failtrace", "\n") "& Debug.fprint(\"failtrace\", \" Env:\" )
	  & Debug.fcall(\"failtrace\",Env.print_env, env)" ;
      then
        fail();
  end matchcontinue;
end ceval;

protected function cevalCallFunction "function: cevalCallFunction
 
  This function evaluates CALL expressions, i.e. function calls.
  They are currently evaluated by generating code for the function and
  then write input to file and execute the generated code. Finally, the
  result is read back from file and returned.
  
  inputs:(Env.Env, 
			Exp.Exp, /* the call expression*/
			Values.Value list, /* input parameter values*/
			Msg) /* Should error messages be printed. */
  outputs: Values.Value /* resulting value */
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input list<Values.Value> inValuesValueLst;
  input Msg inMsg;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inEnv,inExp,inValuesValueLst,inMsg)
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
    case (env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,msg) /* External functions that are \"known\" should be evaluated without
	  compilation, e.g. all math functions */ 
      equation 
        newval = cevalKnownExternalFuncs(env, funcpath, vallst, msg);
      then
        newval;
    case (env,(e as Exp.CALL(path = funcpath,expLst = expl,builtin = builtin)),vallst,msg) /* Call functions in non-interactive mode. FIXME: functions are always generated. Put back the check
	 and write another rule for the false case that generates the function */ 
      equation 
        cevalGenerateFunction(env, funcpath) "Static.is_function_in_cflist(cflist,funcpath) => true &" ;
        funcstr = ModUtil.pathString2(funcpath, "_");
        infilename = stringAppend(funcstr, "_in.txt");
        outfilename = stringAppend(funcstr, "_out.txt");
        Values.writeToFileAsArgs(vallst, infilename);
        System.executeFunction(funcstr);
        newval = System.readValuesFromFile(outfilename);
      then
        newval;
    case (env,e,_,_)
      equation 
        Debug.fprint("failtrace", "- ceval_call_function failed: ");
        str = Exp.printExpStr(e);
        Debug.fprintln("failtrace", str);
      then
        fail();
  end matchcontinue;
end cevalCallFunction;

protected function cevalKnownExternalFuncs "function: cevalKnownExternalFuncs
 
  Evaluates external functions that are known, e.g. all math functions.
"
  input Env.Env env;
  input Absyn.Path funcpath;
  input list<Values.Value> vals;
  input Msg msg;
  output Values.Value res;
  SCode.Class cdef;
  list<Env.Frame> env_1;
  String fid;
  Option<Absyn.ExternalDecl> extdecl;
  Option<String> id,lan;
  Option<Absyn.ComponentRef> out;
  list<Absyn.Exp> args;
algorithm 
  (cdef,env_1) := Lookup.lookupClass(env, funcpath, false);
  SCode.CLASS(fid,_,_,SCode.R_EXT_FUNCTION(),SCode.PARTS(_,_,_,_,_,extdecl)) := cdef;
  SOME(Absyn.EXTERNALDECL(id,lan,out,args,_)) := extdecl;
  isKnownExternalFunc(fid, id);
  res := cevalKnownExternalFuncs2(fid, id, vals, msg);
end cevalKnownExternalFuncs;

public function isKnownExternalFunc "function isKnownExternalFunc
 
  Succeds if external function name is \"known\", i.e. no compilation
  required.
 
  NOTE:    adrpo changed the inputs to not include SCode and Absyn in the
             public impots
 
  inputs:  (SCode.Ident /* string */, Absyn.Ident option /* string option */) 
  outputs: ()
"
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
 
  Helper function to ceval_known_external_funcs, does the evaluation.
"
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
  
  For constant evaluation of functions returning a single value. For now only
  record constructors.
  
  inputs: (Env.Env, Absyn.Path, Values.Value list, 
			  bool /*impl*/, Msg ) 
  outputs: Values.Value =
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Values.Value> inValuesValueLst;
  input Boolean inBoolean;
  input Msg inMsg;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inEnv,inPath,inValuesValueLst,inBoolean,inMsg)
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
    case (env,funcname,vallst,impl,msg) /* For record constructors */ 
      equation 
        (_,_) = Lookup.lookupRecordConstructorClass(env, funcname);
        (c,env_1) = Lookup.lookupClass(env, funcname, false);
        compnames = SCode.componentNames(c);
        mod = Types.valuesToMods(vallst, compnames);
        (dae,_,_,_,_) = Inst.instClass(env_1, mod, Prefix.NOPRE(), Connect.emptySet, c, {}, impl, 
          Inst.TOP_CALL());
        value = DAE.daeToRecordValue(funcname, dae, impl);
      then
        value;
    case (env,funcname,vallst,(impl as true),msg)
      equation 
        Debug.fprint("failtrace", 
          "ceval_function: Don't know what to do. impl was always false before:");
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
           2 + 5  ( x + Eval(y) )  =>   2 + 5  ( x + 1 + x )
 
  inputs:  (Env.Env, Absyn.Exp, 
			  bool /* impl */, 
			  Interactive.InteractiveSymbolTable option,
			  Msg)
  outputs: Absyn.Exp 
"
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Absyn.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
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
    case (_,(e as Absyn.INTEGER(value = _)),_,_,_) then e; 
    case (_,(e as Absyn.REAL(value = _)),_,_,_) then e; 
    case (_,(e as Absyn.CREF(componentReg = _)),_,_,_) then e; 
    case (_,(e as Absyn.STRING(value = _)),_,_,_) then e; 
    case (_,(e as Absyn.BOOL(value = _)),_,_,_) then e; 
    case (env,Absyn.BINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        e1_1 = cevalAstExp(env, e1, impl, st, msg);
        e2_1 = cevalAstExp(env, e2, impl, st, msg);
      then
        Absyn.BINARY(e1_1,op,e2_1);
    case (env,Absyn.UNARY(op = op,exp = e),impl,st,msg)
      equation 
        e_1 = cevalAstExp(env, e, impl, st, msg);
      then
        Absyn.UNARY(op,e_1);
    case (env,Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        e1_1 = cevalAstExp(env, e1, impl, st, msg);
        e2_1 = cevalAstExp(env, e2, impl, st, msg);
      then
        Absyn.LBINARY(e1_1,op,e2_1);
    case (env,Absyn.LUNARY(op = op,exp = e),impl,st,msg)
      equation 
        e_1 = cevalAstExp(env, e, impl, st, msg);
      then
        Absyn.LUNARY(op,e_1);
    case (env,Absyn.RELATION(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        e1_1 = cevalAstExp(env, e1, impl, st, msg);
        e2_1 = cevalAstExp(env, e2, impl, st, msg);
      then
        Absyn.RELATION(e1_1,op,e2_1);
    case (env,Absyn.IFEXP(ifExp = cond,trueBranch = then_,elseBranch = else_,elseIfBranch = nest),impl,st,msg)
      equation 
        cond_1 = cevalAstExp(env, cond, impl, st, msg);
        then_1 = cevalAstExp(env, then_, impl, st, msg);
        else_1 = cevalAstExp(env, else_, impl, st, msg);
        nest_1 = cevalAstExpexpList(env, nest, impl, st, msg);
      then
        Absyn.IFEXP(cond_1,then_1,else_1,nest_1);
    case (env,Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "Eval",subscripts = {}),functionArgs = Absyn.FUNCTIONARGS(args = {e},argNames = {})),impl,st,msg)
      local Exp.Exp e_1;
      equation 
        (e_1,_,_) = Static.elabExp(env, e, impl, st);
        (Values.CODE(Absyn.C_EXPRESSION(exp)),_) = ceval(env, e_1, impl, st, NONE, msg);
      then
        exp;
    case (env,(e as Absyn.CALL(function_ = cr,functionArgs = fa)),_,_,msg) then e; 
    case (env,Absyn.ARRAY(arrayExp = expl),impl,st,msg)
      equation 
        expl_1 = cevalAstExpList(env, expl, impl, st, msg);
      then
        Absyn.ARRAY(expl_1);
    case (env,Absyn.MATRIX(matrix = expl),impl,st,msg)
      local list<list<Absyn.Exp>> expl_1,expl;
      equation 
        expl_1 = cevalAstExpListList(env, expl, impl, st, msg);
      then
        Absyn.MATRIX(expl_1);
    case (env,Absyn.RANGE(start = e1,step = SOME(e2),stop = e3),impl,st,msg)
      equation 
        e1_1 = cevalAstExp(env, e1, impl, st, msg);
        e2_1 = cevalAstExp(env, e2, impl, st, msg);
        e3_1 = cevalAstExp(env, e3, impl, st, msg);
      then
        Absyn.RANGE(e1_1,SOME(e2_1),e3_1);
    case (env,Absyn.RANGE(start = e1,step = NONE,stop = e3),impl,st,msg)
      equation 
        e1_1 = cevalAstExp(env, e1, impl, st, msg);
        e3_1 = cevalAstExp(env, e3, impl, st, msg);
      then
        Absyn.RANGE(e1_1,NONE,e3_1);
    case (env,Absyn.TUPLE(expressions = expl),impl,st,msg)
      equation 
        expl_1 = cevalAstExpList(env, expl, impl, st, msg);
      then
        Absyn.TUPLE(expl_1);
    case (env,Absyn.END(),_,_,msg) then Absyn.END(); 
    case (env,(e as Absyn.CODE(code = _)),_,_,msg) then e; 
  end matchcontinue;
end cevalAstExp;

protected function cevalAstExpList "function: cevalAstExpList
  
  List version of ceval_ast_exp
  
  inputs: (Env.Env, Absyn.Exp list, 
			 bool /* impl */ , Interactive.InteractiveSymbolTable option,
			 Msg) 
  outputs: (Absyn.Exp list)
"
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  outAbsynExpLst:=
  matchcontinue (inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      Absyn.Exp e_1,e;
      list<Absyn.Exp> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
    case (env,{},_,_,msg) then {}; 
    case (env,(e :: es),impl,st,msg)
      equation 
        e_1 = cevalAstExp(env, e, impl, st, msg);
        res = cevalAstExpList(env, es, impl, st, msg);
      then
        (e :: res);
  end matchcontinue;
end cevalAstExpList;

protected function cevalAstExpListList "function: cevalAstExpListList
  
  inputs: (Env.Env, Absyn.Exp list list, 
			 bool /* impl */, 
			 Interactive.InteractiveSymbolTable option,
			 Msg) 
  outputs: (Absyn.Exp list list)
"
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm 
  outAbsynExpLstLst:=
  matchcontinue (inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      list<Absyn.Exp> e_1,e;
      list<list<Absyn.Exp>> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
    case (env,{},_,_,msg) then {}; 
    case (env,(e :: es),impl,st,msg)
      equation 
        e_1 = cevalAstExpList(env, e, impl, st, msg);
        res = cevalAstExpListList(env, es, impl, st, msg);
      then
        (e :: res);
  end matchcontinue;
end cevalAstExpListList;

protected function cevalAstExpexpList "function: cevalAstExpexpList
 
  For IFEXP
"
  input Env.Env inEnv;
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm 
  outTplAbsynExpAbsynExpLst:=
  matchcontinue (inEnv,inTplAbsynExpAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Msg msg;
      Absyn.Exp e1_1,e2_1,e1,e2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res,xs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
    case (_,{},_,_,msg) then {}; 
    case (env,((e1,e2) :: xs),impl,st,msg)
      equation 
        e1_1 = cevalAstExp(env, e1, impl, st, msg);
        e2_1 = cevalAstExp(env, e2, impl, st, msg);
        res = cevalAstExpexpList(env, xs, impl, st, msg);
      then
        ((e1_1,e2_1) :: res);
  end matchcontinue;
end cevalAstExpexpList;

protected function cevalAstElt "function: cevalAstElt
 
  Evaluates an ast constructor for Element nodes, e.g. 
  Code(parameter Real x=1;)
 
  inputs:  (Env.Env, Absyn.Element, 
			 bool /* impl */, 
			 Interactive.InteractiveSymbolTable option,
			 Msg)
  outputs: (Absyn.Element)
"
  input Env.Env inEnv;
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inEnv,inElement,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      list<Env.Frame> env;
      Boolean f,isReadOnly,impl;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String id,file;
      Absyn.ElementAttributes attr;
      Absyn.Path tp;
      Absyn.Info info;
      Integer sline,scolumn,eline,ecolumn;
      Option<Absyn.ConstrainClass> c;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = io,name = id,specification = Absyn.COMPONENTS(attributes = attr,typeName = tp,components = citems),info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scolumn,lineNumberEnd = eline,columnNumberEnd = ecolumn)),constrainClass = c),impl,st,msg)
      equation 
        citems_1 = cevalAstCitems(env, citems, impl, st, msg);
      then
        Absyn.ELEMENT(f,r,io,id,Absyn.COMPONENTS(attr,tp,citems_1),info,c);
  end matchcontinue;
end cevalAstElt;

protected function cevalAstCitems "function: cevalAstCitems
 
  Helper function to ceval_ast_elt.
 
  inputs: (Env.Env, Absyn.ComponentItem list, 
			 bool /* impl */, 
			 Interactive.InteractiveSymbolTable option,
			 Msg)
  outputs: Absyn.ComponentItem list
"
  input Env.Env inEnv;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  outAbsynComponentItemLst:=
  matchcontinue (inEnv,inAbsynComponentItemLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
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
    case (_,{},_,_,msg) then {}; 
    case (env,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = modopt),condition = cond,comment = cmt) :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        res = cevalAstCitems(env, xs, impl, st, msg);
        modopt_1 = cevalAstModopt(env, modopt, impl, st, msg);
        ad_1 = cevalAstArraydim(env, ad, impl, st, msg);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad_1,modopt_1),cond,cmt) :: res);
    case (env,(x :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        res = cevalAstCitems(env, xs, impl, st, msg);
      then
        (x :: res);
  end matchcontinue;
end cevalAstCitems;

protected function cevalAstModopt "function: cevalAstModopt
 
  inputs:  (Env.Env, Absyn.Modification option,
			  bool /* impl */, Interactive.InteractiveSymbolTable option,
			  Msg)
  outputs: Absyn.Modification option
"
  input Env.Env inEnv;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm 
  outAbsynModificationOption:=
  matchcontinue (inEnv,inAbsynModificationOption,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Modification res,mod;
      list<Env.Frame> env;
      Boolean st;
      Option<Interactive.InteractiveSymbolTable> impl;
      Msg msg;
    case (env,SOME(mod),st,impl,msg)
      equation 
        res = cevalAstModification(env, mod, st, impl, msg);
      then
        SOME(res);
    case (env,NONE,_,_,msg) then NONE; 
  end matchcontinue;
end cevalAstModopt;

protected function cevalAstModification "function: cevalAstModification
 
  This function evaluates Eval(variable) inside an AST Modification  and replaces 
  the Eval operator with the value of the variable if it has a type \"Expression\"
 
  inputs:  (Env.Env, Absyn.Modification, 
		      bool /* impl */, 
			  Interactive.InteractiveSymbolTable option,
			  Msg)
  outputs: (Absyn.Modification)
"
  input Env.Env inEnv;
  input Absyn.Modification inModification;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Absyn.Modification outModification;
algorithm 
  outModification:=
  matchcontinue (inEnv,inModification,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Exp e_1,e;
      list<Absyn.ElementArg> eltargs_1,eltargs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = SOME(e)),impl,st,msg)
      equation 
        e_1 = cevalAstExp(env, e, impl, st, msg);
        eltargs_1 = cevalAstEltargs(env, eltargs, impl, st, msg);
      then
        Absyn.CLASSMOD(eltargs_1,SOME(e_1));
    case (env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = NONE),impl,st,msg)
      equation 
        eltargs_1 = cevalAstEltargs(env, eltargs, impl, st, msg);
      then
        Absyn.CLASSMOD(eltargs_1,NONE);
  end matchcontinue;
end cevalAstModification;

protected function cevalAstEltargs "function: cevalAstEltargs
 
  Helper function to ceval_ast_modification.
"
  input Env.Env inEnv;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inEnv,inAbsynElementArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
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
    case (env,{},_,_,msg) then {}; 
    case (env,(Absyn.MODIFICATION(finalItem = b,each_ = e,componentReg = cr,modification = SOME(mod),comment = stropt) :: args),impl,st,msg) /* TODO: look through redeclarations for Eval(var) as well */ 
      equation 
        mod_1 = cevalAstModification(env, mod, impl, st, msg);
        res = cevalAstEltargs(env, args, impl, st, msg);
      then
        (Absyn.MODIFICATION(b,e,cr,SOME(mod_1),stropt) :: res);
    case (env,(m :: args),impl,st,msg) /* TODO: look through redeclarations for Eval(var) as well */ 
      equation 
        res = cevalAstEltargs(env, args, impl, st, msg);
      then
        (m :: res);
  end matchcontinue;
end cevalAstEltargs;

protected function cevalAstArraydim "function: cevalAstArraydim
 
  Helper function to ceva_ast_citems
 
  inputs:  (Env.Env, Absyn.ArrayDim, 
			  bool /* impl */, 
			  Interactive.InteractiveSymbolTable option,
			  Msg)
  outputs: (Absyn.ArrayDim) 
"
  input Env.Env inEnv;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Absyn.ArrayDim outArrayDim;
algorithm 
  outArrayDim:=
  matchcontinue (inEnv,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      list<Absyn.Subscript> res,xs;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.Exp e_1,e;
    case (env,{},_,_,msg) then {}; 
    case (env,(Absyn.NOSUB() :: xs),impl,st,msg)
      equation 
        res = cevalAstArraydim(env, xs, impl, st, msg);
      then
        (Absyn.NOSUB() :: res);
    case (env,(Absyn.SUBSCRIPT(subScript = e) :: xs),impl,st,msg)
      equation 
        res = cevalAstArraydim(env, xs, impl, st, msg);
        e_1 = cevalAstExp(env, e, impl, st, msg);
      then
        (Absyn.SUBSCRIPT(e) :: res);
  end matchcontinue;
end cevalAstArraydim;

protected function cevalInteractiveFunctions "function cevalInteractiveFunctions
 
  This function evaluates the functions defined in the interactive 
  environment.
 
  inputs:  (Env.Env, 
			  Exp.Exp, /* exp to evaluate */
			  Interactive.InteractiveSymbolTable,
			  Msg)
  outputs: (Values.Value, Interactive.InteractiveSymbolTable)
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outValue,outInteractiveSymbolTable):=
  matchcontinue (inEnv,inExp,inInteractiveSymbolTable,inMsg)
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
      Exp.Exp filenameprefix,exp,starttime,stoptime,interval,method,size_expression,funcref,bool_exp;
      Absyn.ComponentRef cr_1;
      Integer size,length,rest;
      list<String> vars_1,vars_2,args;
      Real t1,t2,time;
      Interactive.InteractiveStmts istmts;
      Boolean bval;
    case (env,Exp.CALL(path = Absyn.IDENT(name = "lookupClass"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        p_1 = SCode.elaborate(p);
        env = Inst.makeEnvFromProgram(p_1, Absyn.IDENT(""));
        (c,env) = Lookup.lookupClass(env, path, true);
        SOME(p1) = Env.getEnvPath(env);
        s1 = ModUtil.pathString(p1);
        Print.printBuf("Found class ");
        Print.printBuf(s1);
        Print.printBuf("\n\n");
        str = Print.getString();
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "typeOf"),expLst = {Exp.CREF(componentRef = Exp.CREF_IDENT(ident = varid))}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        tp = Interactive.getTypeOfVariable(varid, iv);
        str = Types.unparseType(tp);
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "clear"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) then (Values.BOOL(true),Interactive.emptySymboltable); 

    case (env,Exp.CALL(path = Absyn.IDENT(name = "clearVariables"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = fp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        newst = Interactive.SYMBOLTABLE(p,fp,ic,{},cf);
      then
        (Values.BOOL(true),newst);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "clearCache"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = fp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        newst = Interactive.SYMBOLTABLE(p,fp,{},iv,cf);
      then
        (Values.BOOL(true),newst);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "list"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Dump.unparseStr(p) ",false" ;
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "list"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        class_ = Interactive.getPathedClassInProgram(path, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP())) ",false" ;
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "jacobian"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        p_1 = SCode.elaborate(p);
        (dae_1,env) = Inst.instantiateClass(p_1, path);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(path,dael,env));
        ((daelow as DAELow.DAELOW(vars,_,eqnarr,_,_,ae,_,_))) = DAELow.lower(dae, false) "no dummy state" ;
        m = DAELow.incidenceMatrix(daelow);
        mt = DAELow.transposeMatrix(m);
        jac = DAELow.calculateJacobian(vars, eqnarr, ae, m, mt);
        res = DAELow.dumpJacobianStr(jac);
      then
        (Values.STRING(res),Interactive.SYMBOLTABLE(p,sp,ic_1,iv,cf));

    case (env,Exp.CALL(path = Absyn.IDENT(name = "translateModel"),expLst = {Exp.CREF(componentRef = cr),filenameprefix}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (ret_val,st_1,_,_,_) = translateModel(env, cr, st, msg, filenameprefix);
      then
        (ret_val,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setCompileCommand"),expLst = {Exp.SCONST(string = cmd)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* (Values.STRING(\"The model have been translated\"),st\') */ 
      equation 
        Settings.setCompileCommand(cmd);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setPlotCommand"),expLst = {Exp.SCONST(string = cmd)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        Settings.setPlotCommand(cmd);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setTempDirectoryPath"),expLst = {Exp.SCONST(string = cmd)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        Settings.setTempDirectoryPath(cmd);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setInstallationDirectoryPath"),expLst = {Exp.SCONST(string = cmd)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        Settings.setInstallationDirectoryPath(cmd);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setModelicaPath"),expLst = {Exp.SCONST(string = cmd)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        Settings.setModelicaPath(cmd);
      then
        (Values.BOOL(true),st);

    case (env,(exp as Exp.CALL(path = Absyn.IDENT(name = "buildModel"),expLst = {Exp.CREF(componentRef = cr),starttime,stoptime,interval,method,filenameprefix})),(st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (executable,method_str,st,initfilename) = buildModel(env, exp, st_1, msg);
      then
        (Values.ARRAY({Values.STRING(executable),Values.STRING(initfilename)}),st);

    case (env,(exp as Exp.CALL(path = Absyn.IDENT(name = "buildModel"),expLst = {Exp.CREF(componentRef = cr),starttime,stoptime,interval,method,filenameprefix})),(st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* failing build_model */  then (Values.ARRAY({Values.STRING(""),Values.STRING("")}),st_1); 

    case (env,(exp as Exp.CALL(path = Absyn.IDENT(name = "simulate"),expLst = {Exp.CREF(componentRef = cr),starttime,stoptime,interval,method,filenameprefix})),(st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (executable,method_str,st,_) = buildModel(env, exp, st_1, msg) "FIXME: Should ceval be called with impl=true here? Build and simulate model" ;
        cit = winCitation();
        pd = System.pathDelimiter();
        executableSuffixedExe = stringAppend(executable, ".exe");
        sim_call = Util.stringAppendList(
          {cit,".",pd,executableSuffixedExe,cit," -m ",method_str,
          " >> output.log 2>&1"});
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
        (simValue,newst);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "simulate"),expLst = {Exp.CREF(componentRef = cr),starttime,stoptime,interval,method,filenameprefix}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        omhome = Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        res = Util.stringAppendList({"Simulation failed.\n"});
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),{Values.STRING(res)},
          {"resultFile"});
      then
        (simValue,st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "simulate"),expLst = {Exp.CREF(componentRef = cr),starttime,stoptime,interval,method,filenameprefix}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),
          {
          Values.STRING(
          "Simulation Failed. Environment variable OPENMODELICAHOME not set.")},{"resultFile"});
      then
        (simValue,st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "instantiateModel"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        cr_1 = Exp.unelabCref(cr);
        true = Interactive.existClass(cr_1, p);
        path = Static.componentRefToPath(cr);
        p_1 = SCode.elaborate(p);
        ((dae as DAE.DAE(dael)),env) = Inst.instantiateClass(p_1, path);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(path,dael,env));
        str = DAE.dumpStr(dae);
      then
        (Values.STRING(str),Interactive.SYMBOLTABLE(p,sp,ic_1,iv,cf));

    case (env,Exp.CALL(path = Absyn.IDENT(name = "instantiateModel"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* model does not exist */ 
      equation 
        cr_1 = Exp.unelabCref(cr);
        false = Interactive.existClass(cr_1, p);
      then
        (Values.STRING("Unknown model.\n"),Interactive.SYMBOLTABLE(p,sp,ic,iv,cf));

    case (env,Exp.CALL(path = Absyn.IDENT(name = "instantiateModel"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        p_1 = SCode.elaborate(p);
        str = Print.getErrorString() "we do not want error msg twice.." ;
        failure(((dae as DAE.DAE(dael)),env) = Inst.instantiateClass(p_1, path));
        Print.clearErrorBuf();
        Print.printErrorBuf(str);
        str = Print.getErrorString();
      then
        (Values.STRING(str),Interactive.SYMBOLTABLE(p,sp,ic,iv,cf));

    case (env,Exp.CALL(path = Absyn.IDENT(name = "readSimulationResult"),expLst = {Exp.SCONST(string = filename),Exp.ARRAY(array = vars),size_expression}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* function ceval : (Env.Env, Exp.Exp, bool (implicit) ,
		    Interactive.InteractiveSymbolTable option, 
		    int option, ( dimensions )
		    Msg)
	  => (Values.Value, Interactive.InteractiveSymbolTable option)
 */ 
      local list<Exp.Exp> vars;
      equation 
        ((size_value as Values.INTEGER(size)),SOME(st)) = ceval(env, size_expression, true, SOME(st), NONE, msg);
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.stringAppendList({pwd,pd,filename});
        value = System.readPtolemyplotDataset(filename_1, vars_1, size);
      then
        (value,st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "readSimulationResult"),expLst = {Exp.SCONST(string = filename),Exp.ARRAY(type_ = _),_}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then
        fail();

    case (env,Exp.CALL(path = Absyn.IDENT(name = "readSimulationResultSize"),expLst = {Exp.SCONST(string = filename)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.stringAppendList({pwd,pd,filename});
        value = System.readPtolemyplotDatasetSize(filename_1);
      then
        (value,st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "readSimulationResultSize"),expLst = {Exp.SCONST(string = filename)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_SIZE_ERROR, {});
      then
        fail();

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plot"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local
        Integer res;
        list<Exp.Exp> vars;
      equation 
        vars_1 = Util.listMap(vars, Exp.printExpStr) "plot" ;
        vars_2 = Util.listUnionElt("time", vars_1);
        (Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(env, 
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
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plot"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        (Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        failure(_ = System.readPtolemyplotDataset(filename, vars_2, 0));
      then
        (Values.STRING("Error reading the simulation result."),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plot"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        failure((_,_) = ceval(env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, NO_MSG()));
      then
        (Values.STRING("No simulation result to plot."),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plot"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local list<Exp.Exp> vars;
      then
        (Values.STRING("Unknown error while plotting"),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* plotparametric This rule represents the normal case when an array of at least two elements 
   is given as an argument */ 
      local
        Integer res;
        list<Exp.Exp> vars;
      equation 
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        length = listLength(vars_1);
        (length > 1) = true;
        (Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(env, 
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
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error with less than two elements (=variables) in the array.
           This means we cannot plot var2 as a function of var1 as var2 is missing" ;
        length = listLength(vars_1);
        (length < 2) = true;
      then
        (Values.STRING("Error: Less than two variables given to plotParametric."),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        (Values.RECORD(_,{Values.STRING(filename)},_),_) = ceval(env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, msg) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
        failure(_ = System.readPtolemyplotDataset(filename, vars_1, 0));
      then
        (Values.STRING("Error reading the simulation result."),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        failure((_,_) = ceval(env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",{}),Exp.OTHER()), true, SOME(st), NONE, NO_MSG())) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
      then
        (Values.STRING("No simulation result to plot."),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = {Exp.ARRAY(array = vars)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local list<Exp.Exp> vars;
      then
        (Values.STRING("Unknown error while plotting"),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "timing"),expLst = {exp}),st,msg) /* end plotparametric */ 
      equation 
        t1 = System.time();
        (value,SOME(st_1)) = ceval(env, exp, true, SOME(st), NONE, msg);
        t2 = System.time();
        time = t2 -. t1;
      then
        (Values.REAL(time),st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setCompiler"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        System.setCCompiler(str);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setCompilerFlags"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        System.setCFlags(str);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "setDebugFlags"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = stringAppend("+d=", str);
        args = RTOpts.args({str_1});
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Integer res;
      equation 
        res = System.cd(str);
        (res == 0) = true;
        str_1 = System.pwd();
      then
        (Values.STRING(str_1),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* no such directory */ 
      equation 
        failure(0 = System.directoryExists(str));
        res = Util.stringAppendList({"Error, directory ",str," does not exist,"});
      then
        (Values.STRING(res),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = System.pwd();
      then
        (Values.STRING(str_1),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "system"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Integer res;
      equation 
        res = System.systemCall(str);
      then
        (Values.INTEGER(res),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "readFile"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = System.readFile(str);
      then
        (Values.STRING(str_1),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getErrorString"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Error.printMessagesStr();
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getMessagesString"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* New error message implementation */ 
      equation 
        str = Error.printMessagesStr();
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getMessagesStringInternal"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Error.getMessagesStr();
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "runScript"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local String msg;
      equation 
        scriptstr = System.readFile(str);
        (istmts,msg) = Parser.parsestringexp(scriptstr);
        equality(msg = "Ok");
        (res,newst) = Interactive.evaluate(istmts, st, true);
        res_1 = Util.stringAppendList({res,"\ntrue"});
      then
        (Values.STRING(res_1),newst);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "runScript"),expLst = {Exp.SCONST(string = str)}),st,msg) then (Values.BOOL(false),st); 

    case (env,Exp.CALL(path = Absyn.IDENT(name = "generateCode"),expLst = {(funcref as Exp.CREF(componentRef = fcr))}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(fcr) "SCode.elaborate(p) => p\' &" ;
        cevalGenerateFunction(env, path) "	& Inst.instantiate_implicit(p\') => d &" ;
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "loadModel"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* add path to symboltable for compiled functions
	  Interactive.SYMBOLTABLE(p,sp,ic,iv,(path,t)::cf),
	  but where to get t? */ 
      local Absyn.Program p_1;
      equation 
        mp = Settings.getModelicaPath();
        path = Static.componentRefToPath(cr);
        pnew = ClassLoader.loadClass(path, mp);
        p_1 = Interactive.updateProgram(pnew, p);
        str = Print.getString();
        newst = Interactive.SYMBOLTABLE(p_1,sp,{},iv,cf);
      then
        (Values.BOOL(true),newst);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "loadModel"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        pathstr = ModUtil.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_ERROR, {pathstr});
      then
        (Values.BOOL(false),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "loadModel"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) then (Values.BOOL(false),st);  /* loadModel failed */ 

    case (env,Exp.CALL(path = Absyn.IDENT(name = "loadFile"),expLst = {Exp.SCONST(string = name)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Absyn.Program p1;
      equation 
        p1 = ClassLoader.loadFile(name) "System.regularFileExists(name) => 0 & Parser.parse(name) => p1 &" ;
        newp = Interactive.updateProgram(p1, p);
      then
        (Values.BOOL(true),Interactive.SYMBOLTABLE(newp,sp,ic,iv,cf));

    case (env,Exp.CALL(path = Absyn.IDENT(name = "loadFile"),expLst = {Exp.SCONST(string = name)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* (Values.BOOL(true),Interactive.SYMBOLTABLE(newp,sp,{},iv,cf)) it the rule above have failed then check if file exists without this omc crashes */ 
      equation 
        rest = System.regularFileExists(name);
        (rest > 0) = true;
      then
        (Values.BOOL(false),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "loadFile"),expLst = {Exp.SCONST(string = name)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* not Parser.parse(name) => _ */  then (Values.BOOL(false),st); 

    case (env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = filename),Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        classpath = Static.componentRefToPath(cr);
        class_ = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP())) ",true" ;
        System.writeFile(filename, str);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = name),Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        classpath = Static.componentRefToPath(cr) "Error writing to file" ;
        class_ = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP())) ",true" ;
        Error.addMessage(Error.WRITING_FILE_ERROR, {name});
      then
        (Values.BOOL(false),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "save"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Absyn.Program p_1;
      equation 
        classpath = Static.componentRefToPath(cr);
        (p_1,filename) = Interactive.getContainedClassAndFile(classpath, p);
        str = Dump.unparseStr(p_1) ",true" ;
        System.writeFile(filename, str);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "save"),expLst = {Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) then (Values.BOOL(false),st); 

    case (env,Exp.CALL(path = Absyn.IDENT(name = "saveAll"),expLst = {Exp.SCONST(string = filename)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Dump.unparseStr(p) ",true" ;
        System.writeFile(filename, str);
      then
        (Values.BOOL(true),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = name),Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        classpath = Static.componentRefToPath(cr) "Error writing to file" ;
        cname = Absyn.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        (Values.BOOL(false),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "help"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        cit = winCitation();
        pd = System.pathDelimiter();
        filename = Util.stringAppendList({omhome_1,pd,"bin",pd,"omc_helptext.txt"});
        print(filename);
        str = System.readFile(filename);
      then
        (Values.STRING(str),st);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getUnit"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "unit", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getQuantity"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "quantity", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getDisplayUnit"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "displayUnit", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getMin"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "min", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getMax"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "max", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getStart"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "start", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getFixed"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "fixed", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getNominal"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "nominal", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "getStateSelect"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (v,st_1) = getBuiltinAttribute(classname, cref, "stateSelect", st);
      then
        (v,st_1);

    case (env,Exp.CALL(path = Absyn.IDENT(name = "echo"),expLst = {bool_exp}),st,msg)
      equation 
        ((v as Values.BOOL(bval)),SOME(st_1)) = ceval(env, bool_exp, true, SOME(st), NONE, msg);
        setEcho(bval);
      then
        (v,st);
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

protected function generateMakefilename "function generateMakefilename
 
"
  input String filenameprefix;
  output String makefilename;
algorithm 
  makefilename := Util.stringAppendList({filenameprefix,".makefile"});
end generateMakefilename;

public function translateModel "function translateModel
 author: x02lucpo
 
 translates a model into cpp code and writes also a makefile 
 
  inputs:  (Env.Env, 
			  Exp.ComponentRef, /* component ref for model */
			  Interactive.InteractiveSymbolTable,
              Msg,
              Exp.Exp)
  outputs:  (Values.Value, 
              Interactive.InteractiveSymbolTable,
              DAELow.DAELow,
              string list /*libs */)
"
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  input Exp.Exp inExp;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output DAELow.DAELow outDAELow;
  output list<String> outStringLst;
  output String outString;
algorithm 
  (outValue,outInteractiveSymbolTable,outDAELow,outStringLst,outString):=
  matchcontinue (inEnv,inComponentRef,inInteractiveSymbolTable,inMsg,inExp)
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
    case (env,cr,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,fileprefix) /* mo file directory */ 
      equation 
        filenameprefix = extractFilePrefix(env, fileprefix, st, msg);
        classname = Static.componentRefToPath(cr);
        p_1 = SCode.elaborate(p);
        (dae_1,env) = Inst.instantiateClass(p_1, classname);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname,dael,env));
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
        cname_str = Absyn.pathString(classname);
        filename = Util.stringAppendList({filenameprefix,".cpp"});
        funcfilename = Util.stringAppendList({filenameprefix,"_functions.cpp"});
        makefilename = generateMakefilename(filenameprefix);
        a_cref = Exp.unelabCref(cr);
        file_dir = getFileDir(a_cref, p);
        libs = SimCodegen.generateFunctions(p_1, dae, indexed_dlow_1, classname, funcfilename);
        SimCodegen.generateSimulationCode(dae, indexed_dlow_1, ass1, ass2, m, mT, comps, classname, 
          filename, funcfilename);
        SimCodegen.generateMakefile(makefilename, filenameprefix, libs, file_dir) "	Util.string_append_list({\"make -f \",cname_str, \".makefile\\n\"}) => s_call &
" ;
      then
        (Values.STRING("The model have been translated"),st,indexed_dlow_1,libs,file_dir);
  end matchcontinue;
end translateModel;

protected function extractFilePrefix "function extractFilePrefix
  author: x02lucpo
 
  extracts the file_prefix from Exp.Exp as string
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEnv,inExp,inInteractiveSymbolTable,inMsg)
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
    case (env,filenameprefix,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (Values.STRING(prefix_str),SOME(st)) = ceval(env, filenameprefix, true, SOME(st), NONE, msg);
      then
        prefix_str;
    case (_,_,_,_) then fail(); 
  end matchcontinue;
end extractFilePrefix;

protected function calculateSimulationSettings "function calculateSimulationSettings
 author: x02lucpo
 
 calculates the start,end,interval,stepsize, method and init_file_name
 
  inputs:  (Env.Env,Exp.Exp,
			  Interactive.InteractiveSymbolTable,
              Msg,
              string)
  outputs:  (string/* filename */,
              real, /* start time*/
              real, /* stop time */
              real, /* step size */
              string /* method*/) 
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  input String inString;
  output String outString1;
  output Real outReal2;
  output Real outReal3;
  output Real outReal4;
  output String outString5;
algorithm 
  (outString1,outReal2,outReal3,outReal4,outString5):=
  matchcontinue (inEnv,inExp,inInteractiveSymbolTable,inMsg,inString)
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
    case (env,Exp.CALL(expLst = {Exp.CREF(componentRef = cr),starttime,stoptime,interval,method,filenameprefix}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,cname_str)
      equation 
        (Values.STRING(prefix_str),SOME(st)) = ceval(env, filenameprefix, true, SOME(st), NONE, msg);
        (starttime_v,SOME(st)) = ceval(env, starttime, true, SOME(st), NONE, msg);
        (stoptime_v,SOME(st)) = ceval(env, stoptime, true, SOME(st), NONE, msg);
        (Values.INTEGER(interval_i),SOME(st)) = ceval(env, interval, true, SOME(st), NONE, msg);
        (Values.STRING(method_str),SOME(st)) = ceval(env, method, true, SOME(st), NONE, msg);
        starttime_r = Values.valueReal(starttime_v);
        stoptime_r = Values.valueReal(stoptime_v);
        interval_r = intReal(interval_i);
        init_filename = Util.stringAppendList({prefix_str,"_init.txt"});
      then
        (init_filename,starttime_r,stoptime_r,interval_r,method_str);
    case (_,_,_,_,_)
      equation 
        Print.printErrorBuf("# calculate_simulation_settings failed\n");
      then
        fail();
  end matchcontinue;
end calculateSimulationSettings;

public function buildModel "function buildModel
author: x02lucpo

translates and builds the model through the compiler script

 inputs: (Env.Env,  
		    Exp.Exp, /* component ref for model */
		    Interactive.InteractiveSymbolTable,
            Msg)
 outputs: (string, /*classname*/
             string, /*method*/
             Interactive.InteractiveSymbolTable, 
             string) /*initfilename*/
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Msg inMsg;
  output String outString1;
  output String outString2;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String outString4;
algorithm 
  (outString1,outString2,outInteractiveSymbolTable3,outString4):=
  matchcontinue (inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      Values.Value ret_val;
      Interactive.InteractiveSymbolTable st,st_1;
      DAELow.DAELow indexed_dlow_1;
      list<String> libs;
      String file_dir,cname_str,init_filename,method_str,filenameprefix,makefilename;
      Absyn.Path classname;
      Real starttime_r,stoptime_r,interval_r;
      list<Env.Frame> env;
      Exp.Exp exp,starttime,stoptime,interval,method,fileprefix;
      Exp.ComponentRef cr;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Msg msg;
    case (env,(exp as Exp.CALL(path = Absyn.IDENT(name = _),expLst = {Exp.CREF(componentRef = cr),starttime,stoptime,interval,method,fileprefix})),(st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (ret_val,st,indexed_dlow_1,libs,file_dir) = translateModel(env, cr, st_1, msg, fileprefix);
        classname = Static.componentRefToPath(cr);
        cname_str = Absyn.pathString(classname);
        (init_filename,starttime_r,stoptime_r,interval_r,method_str) = calculateSimulationSettings(env, exp, st, msg, cname_str);
        filenameprefix = extractFilePrefix(env, fileprefix, st, msg);
        SimCodegen.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, 
          starttime_r, stoptime_r, interval_r);
        makefilename = generateMakefilename(filenameprefix);
        compileModel(filenameprefix, libs, file_dir) "	Util.string_append_list({\"make -f \",cname_str, \".makefile\\n\"}) => s_call &
" ;
      then
        (filenameprefix,method_str,st,init_filename);
    case (_,_,_,_)
      equation 
        print("-build_model failed\n");
      then
        fail();
  end matchcontinue;
end buildModel;

public function getFileDir "function: getFileDir
  author: x02lucpo
 
  returns the dir where class-file (.mo) is saved or 
  OPENMODELICAHOMe/work if not saved
 
  inputs: (Absyn.ComponentRef, /* class */
			    Absyn.Program) 
  outputs: string 
"
  input Absyn.ComponentRef inComponentRef;
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
        omhome = Settings.getInstallationDirectoryPath() "model no saved! change to OPENMODELICAHOME/work" ;
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
 
  Compiles a model given a file-prefix, helper function to build_model.
"
  input String inString1;
  input list<String> inStringLst2;
  input String inString3;
algorithm 
  _:=
  matchcontinue (inString1,inStringLst2,inString3)
    local
      String pd,omhome,omhome_1,cd_path,libsfilename,libs_str,s_call,fileprefix,file_dir,command,filename,str;
      list<String> libs;
    case (fileprefix,libs,file_dir) /* executable name external libs directory for mo-file */ 
      equation 
        "" = Settings.getCompileCommand();
        pd = System.pathDelimiter();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        cd_path = System.pwd();
        libsfilename = stringAppend(fileprefix, ".libs");
        libs_str = Util.stringDelimitList(libs, " ");
        System.writeFile(libsfilename, libs_str);
        s_call = Util.stringAppendList({"\"",omhome_1,pd,"bin",pd,"Compile","\""," ",fileprefix}) "\"\"\",cd_path,\"\"\",\" \", ,\" \",cit,file_dir,\" \",cit" ;
 //       print(s_call);
 //       print("<<<<<\n");
        0 = System.systemCall(s_call) "> output.log 2>&1 = redirect stderr to stdout and put it in output.log print s_call & print \"\\n\" &" ;
      then
        ();
    case (fileprefix,libs,file_dir)
      equation 
        command = Settings.getCompileCommand();
        false = Util.isEmptyString(command);
        cd_path = System.pwd() "needed when the above rule does not work" ;
        libs_str = Util.stringDelimitList(libs, " ");
        libsfilename = stringAppend(fileprefix, ".libs");
        System.writeFile(libsfilename, libs_str);
        s_call = Util.stringAppendList({command," ",fileprefix}) "cit,cd_path,cit,\" \", ,\" \",cit,file_dir,\" \",cit" ;
//        print(s_call);
//        print("<<<<<222\n");
        0 = System.systemCall(s_call) "> output.log 2>&1 = redirect stderr to stdout and put it in output.log print s_call & print \"\\n\" &" ;
      then
        ();
    case (fileprefix,libs,file_dir) /* compilation failed\\n */ 
      equation 
        filename = Util.stringAppendList({fileprefix,".log"});
        0 = System.regularFileExists(filename);
        str = System.readFile(filename);
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
      then
        fail();
    case (fileprefix,libs,file_dir)
      equation 
        Print.printErrorBuf("#Error building simulation code.\n ");
      then
        fail();
  end matchcontinue;
end compileModel;

protected function winCitation "function: winCitation
  author: PA
 
  Returns a cition mark if platform is windows, otherwise empty string. Used
  by simulate to make whitespaces work in filepaths for WIN32
"
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
  the class and retrieving the attribute value from the flat variable.
"
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
  input String inString3;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable4;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outValue,outInteractiveSymbolTable):=
  matchcontinue (inComponentRef1,inComponentRef2,inString3,inInteractiveSymbolTable4)
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
    case (classname,cref,"stateSelect",(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = vars,compiledFunctions = cf)))
      equation 
        classname_1 = Static.componentRefToPath(classname) "Check cached instantiated class" ;
        Interactive.INSTCLASS(_,dae,env) = Interactive.getInstantiatedClass(ic, classname_1);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT("stateSelect",{}));
        (attr,ty,Types.EQBOUND(exp,_,_)) = Lookup.lookupVar(env, cref_1);
        str = Exp.printExpStr(exp);
      then
        (Values.STRING(str),st);
    case (classname,cref,"stateSelect",Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = vars,compiledFunctions = cf))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        p_1 = SCode.elaborate(p);
        env = Inst.makeEnvFromProgram(p_1, Absyn.IDENT(""));
        ((c as SCode.CLASS(n,_,encflag,r,_)),env_1) = Lookup.lookupClass(env, classname_1, true);
        env3 = Env.openScope(env_1, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (dae1,env4,csets_1,ci_state_1,tys,_) = Inst.instClassIn(env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false, false);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT("stateSelect",{}));
        (attr,ty,Types.EQBOUND(exp,_,_)) = Lookup.lookupVar(env4, cref_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname_1,dae1,env4));
        str = Exp.printExpStr(exp);
      then
        (Values.STRING(str),Interactive.SYMBOLTABLE(p,sp,ic_1,vars,cf));
    case (classname,cref,attribute,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = vars,compiledFunctions = cf)))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        Interactive.INSTCLASS(_,dae,env) = Interactive.getInstantiatedClass(ic, classname_1);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT(attribute,{}));
        (attr,ty,Types.VALBOUND(v)) = Lookup.lookupVar(env, cref_1);
      then
        (v,st);
    case (classname,cref,attribute,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = vars,compiledFunctions = cf)))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        p_1 = SCode.elaborate(p);
        env = Inst.makeEnvFromProgram(p_1, Absyn.IDENT(""));
        ((c as SCode.CLASS(n,_,encflag,r,_)),env_1) = Lookup.lookupClass(env, classname_1, true);
        env3 = Env.openScope(env_1, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (dae1,env4,csets_1,ci_state_1,tys,_) = Inst.instClassIn(env3, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false, false);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT(attribute,{}));
        (attr,ty,Types.VALBOUND(v)) = Lookup.lookupVar(env4, cref_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname_1,dae1,env4));
      then
        (v,Interactive.SYMBOLTABLE(p,sp,ic_1,vars,cf));
  end matchcontinue;
end getBuiltinAttribute;

protected function cevalMatrixelt "function: cevalMatrixelt
 
  Evaluates the expression of a matrix constructor, e.g. {1,2;3,4}
 
  signature: (Env.Env,
			  (Exp.Expbool) list list, /* matrix constr. elts*/
			  bool, /*impl*/ 
			  Msg) 
	  => Values.Value list
"
  input Env.Env inEnv;
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input Boolean inBoolean;
  input Msg inMsg;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inEnv,inTplExpExpBooleanLstLst,inBoolean,inMsg)
    local
      Values.Value v;
      list<Values.Value> vl;
      list<Env.Frame> env;
      list<tuple<Exp.Exp, Boolean>> expl;
      list<list<tuple<Exp.Exp, Boolean>>> expll;
      Boolean impl;
      Msg msg;
    case (env,(expl :: expll),impl,msg)
      equation 
        v = cevalMatrixeltrow(env, expl, impl, msg);
        vl = cevalMatrixelt(env, expll, impl, msg);
      then
        (v :: vl);
    case (_,{},_,msg) then {}; 
  end matchcontinue;
end cevalMatrixelt;

protected function cevalMatrixeltrow "function: cevalMatrixeltrow
 
  Helper function to ceval_matrixelt
 
  signature: (Env.Env, (Exp.Expbool) list, bool, /*impl*/ 
			     Msg) => Values.Value
"
  input Env.Env inEnv;
  input list<tuple<Exp.Exp, Boolean>> inTplExpExpBooleanLst;
  input Boolean inBoolean;
  input Msg inMsg;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inEnv,inTplExpExpBooleanLst,inBoolean,inMsg)
    local
      Values.Value res;
      list<Values.Value> resl;
      list<Env.Frame> env;
      Exp.Exp e;
      list<tuple<Exp.Exp, Boolean>> rest;
      Boolean impl;
      Msg msg;
    case (env,((e,_) :: rest),impl,msg)
      equation 
        (res,_) = ceval(env, e, impl, NONE, NONE, msg);
        Values.ARRAY(resl) = cevalMatrixeltrow(env, rest, impl, msg);
      then
        Values.ARRAY((res :: resl));
    case (env,{},_,msg) then Values.ARRAY({}); 
  end matchcontinue;
end cevalMatrixeltrow;

protected function cevalBuiltinSize "function: cevalBuiltinSize
 
  Evaluates the size operator.
"
  input Env.Env inEnv1;
  input Exp.Exp inExp2;
  input Exp.Exp inExp3;
  input Boolean inBoolean4;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption5;
  input Msg inMsg6;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv1,inExp2,inExp3,inBoolean4,inInteractiveInteractiveSymbolTableOption5,inMsg6)
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
    case (env,Exp.CREF(componentRef = cr,component = tp),dim,impl,st,msg)
      equation 
        (attr,tp,bind) = Lookup.lookupVar(env, cr) "If dimensions known, always ceval" ;
        true = Types.dimensionsKnown(tp);
        sizelst = Types.getDimensionSizes(tp);
        (Values.INTEGER(dim),st_1) = ceval(env, dim, impl, st, NONE, msg);
        dim_1 = dim - 1;
        v = listNth(sizelst, dim_1);
      then
        (Values.INTEGER(v),st_1);
    case (env,Exp.CREF(componentRef = cr,component = tp),dim,(impl as false),st,msg)
      local
        Exp.Type tp;
        Exp.Exp dim;
      equation 
        dims = Inst.elabComponentArraydimFromEnv(env, cr) "If component not instantiated yet, recursive definition.
	 For example,
	 Real x{:}(min=fill(1.0,size(x,1))) = {1.0} 
	 
	  When size(x,1) should be determined, x must be instantiated, but
	  that is not done yet. Solution: Examine Element to find modifier 
	  which will determine dimension size.
	" ;
        (Values.INTEGER(dimv),st_1) = ceval(env, dim, impl, st, NONE, msg);
        v2 = cevalBuiltinSize3(dims, dimv);
      then
        (v2,st_1);
    case (env,Exp.CREF(componentRef = cr,component = tp),dim,(impl as true),st,msg)
      local Exp.Exp dim;
      equation 
        (attr,tp,bind) = Lookup.lookupVar(env, cr) "If dimensions not known and impl=true, just silently fail" ;
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (env,Exp.CREF(componentRef = cr,component = tp),dim,(impl as false),st,MSG())
      local Exp.Exp dim;
      equation 
        (attr,tp,bind) = Lookup.lookupVar(env, cr) "If dimensions not known and impl=false, error message" ;
        false = Types.dimensionsKnown(tp);
        cr_str = Exp.printComponentRefStr(cr);
        dim_str = Exp.printExpStr(dim);
        size_str = Util.stringAppendList({"size(",cr_str,", ",dim_str,")"});
        Error.addMessage(Error.DIMENSION_NOT_KNOWN, {size_str});
      then
        fail();
    case (env,Exp.CREF(componentRef = cr,component = tp),dim,(impl as false),st,NO_MSG())
      local Exp.Exp dim;
      equation 
        (attr,tp,bind) = Lookup.lookupVar(env, cr);
        false = Types.dimensionsKnown(tp);
      then
        fail();
    case (env,(exp as Exp.CREF(componentRef = cr,component = crtp)),dim,(impl as false),st,MSG())
      local Exp.Exp dim;
      equation 
        (attr,tp,Types.UNBOUND()) = Lookup.lookupVar(env, cr) "For crefs without value binding" ;
        expstr = Exp.printExpStr(exp);
        Error.addMessage(Error.UNBOUND_VALUE, {expstr});
      then
        fail();
    case (env,(exp as Exp.CREF(componentRef = cr,component = crtp)),dim,(impl as false),st,NO_MSG())
      local Exp.Exp dim;
      equation 
        (attr,tp,Types.UNBOUND()) = Lookup.lookupVar(env, cr);
      then
        fail();
    case (env,(exp as Exp.CREF(componentRef = cr,component = crtp)),dim,(impl as true),st,msg)
      local Exp.Exp dim;
      equation 
        (attr,tp,Types.UNBOUND()) = Lookup.lookupVar(env, cr) "For crefs without value binding. If impl=true just silently fail" ;
      then
        fail();
    case (env,(exp as Exp.CREF(componentRef = cr,component = crtp)),dim,impl,st,msg)
      local
        Values.Value v;
        Exp.Exp dim;
      equation 
        (attr,tp,binding) = Lookup.lookupVar(env, cr) "For crefs with value binding" ;
        (Values.INTEGER(dimv),st_1) = ceval(env, dim, impl, st, NONE, msg);
        v = cevalCrefBinding(env, cr, binding, impl, msg);
        v2 = cevalBuiltinSize2(v, dimv);
      then
        (v2,st_1);
    case (env,Exp.ARRAY(array = (e :: es)),dim,impl,st,msg)
      local
        Exp.Type tp;
        Exp.Exp dim;
      equation 
        tp = Exp.typeof(e) "Special case for array expressions with nonconstant values For now: only arrays of scalar elements: TODO generalize to arbitrary
	   dimensions" ;
        true = Exp.typeBuiltin(tp);
        (Values.INTEGER(1),st_1) = ceval(env, dim, impl, st, NONE, msg);
        len = listLength((e :: es));
      then
        (Values.INTEGER(len),st_1);
    case (env,exp,dim,impl,st,msg)
      local
        Values.Value v;
        Exp.Exp dim;
      equation 
        (v,st_1) = ceval(env, exp, impl, st, NONE, msg) "try to ceval expression, for constant expressions" ;
        (Values.INTEGER(dimv),st_1) = ceval(env, dim, impl, st, NONE, msg);
        v2 = cevalBuiltinSize2(v, dimv);
      then
        (v2,st_1);
    case (env,exp,dim,impl,st,MSG())
      local Exp.Exp dim;
      equation 
        Print.printErrorBuf("#-- ceval_builtin_size failed: ");
        expstr = Exp.printExpStr(exp);
        Print.printErrorBuf(expstr);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize;

protected function cevalBuiltinSize2 "function: ceval_bultin_size_2
  
  Helper function to ceval_builtin_size
"
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
        Debug.fprint("failtrace", "- ceval_builtin_size_2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize2;

protected function cevalBuiltinSize3 "function: cevalBuiltinSize3
  author: PA
  
  Helper function to ceval_builtin_size. Used when recursive definition
  (attribute modifiers using size) is used.
"
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
        print("ceval_builtin_size_3 failed DIMEXP in dimesion\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize3;

protected function cevalBuiltinAbs "function: cevalBuiltinAbs
  author: LP
  
  Evaluates the abs operator.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer iv;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realAbs(rv);
      then
        (Values.REAL(rv_1),st);
    case (env,{exp},impl,st,msg)
      equation 
        (Values.INTEGER(iv),_) = ceval(env, exp, impl, st, NONE, msg);
        iv = intAbs(iv);
      then
        (Values.INTEGER(iv),st);
  end matchcontinue;
end cevalBuiltinAbs;

protected function cevalBuiltinSign "function: cevalBuiltinSign
  author: PA
  
  Evaluates the sign operator.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      Boolean b1,b2,b3,impl;
      list<Env.Frame> env;
      Exp.Exp exp;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer iv,iv_1;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        b1 = (rv >. 0.0);
        b2 = (rv <. 0.0);
        b3 = (rv ==. 0.0);
        {(_,rv_1)} = Util.listSelect({(b1,1.0),(b2,-1.0),(b3,0.0)}, Util.tuple21);
      then
        (Values.REAL(rv_1),st);
    case (env,{exp},impl,st,msg)
      equation 
        (Values.INTEGER(iv),_) = ceval(env, exp, impl, st, NONE, msg);
        b1 = (iv > 0);
        b2 = (iv < 0);
        b3 = (iv == 0);
        {(_,iv_1)} = Util.listSelect({(b1,1),(b2,-1),(b3,0)}, Util.tuple21);
      then
        (Values.INTEGER(iv_1),st);
  end matchcontinue;
end cevalBuiltinSign;

protected function cevalBuiltinExp "function: cevalBuiltinExp
  author: PA
  
  Evaluates the exp function
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realExp(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinExp;

protected function cevalBuiltinNoevent "function: cevalBuiltinNoevent
  author: PA
  
  Evaluates the noEvent operator. During constant evaluation events are not
  considered, so evaluation will simply remove the operator and evaluate the
  operand.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (v,_) = ceval(env, exp, impl, st, NONE, msg);
      then
        (v,st);
  end matchcontinue;
end cevalBuiltinNoevent;

protected function cevalBuiltinCardinality "function: cevalBuiltinCardinality
  author: PA
  
  Evaluates the cardinality operator. The cardinality of a connector 
  instance is its number of (inside and outside) connections, i.e. 
  number of occurences in connect equations.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer cnt;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{Exp.CREF(componentRef = cr)},impl,st,msg)
      equation 
        cnt = cevalCardinality(env, cr);
      then
        (Values.INTEGER(cnt),st);
  end matchcontinue;
end cevalBuiltinCardinality;

protected function cevalCardinality "function: cevalCardinality 
  author: PA
  
  counts the number of connect occurences of the component ref in 
  equations in current scope.
"
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inEnv,inComponentRef)
    local
      list<Exp.ComponentRef> cr_lst,crs;
      Integer res;
      Exp.ComponentRef cr;
    case ((Env.FRAME(current6 = crs) :: _),cr)
      equation 
        cr_lst = Util.listSelect1(crs, cr, Exp.crefContainedIn);
        res = listLength(cr_lst);
      then
        res;
  end matchcontinue;
end cevalCardinality;

protected function cevalBuiltinCat "function: cevalBuiltinCat
  author: PA
  
  Evaluates the cat operator, for matrix concatenation.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
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
    case (env,(dim :: matrices),impl,st,msg)
      equation 
        (Values.INTEGER(dim_int),_) = ceval(env, dim, impl, st, NONE, msg);
        mat_lst = cevalList(env, matrices, impl, st, msg);
        v = cevalCat(mat_lst, dim_int);
      then
        (v,st);
  end matchcontinue;
end cevalBuiltinCat;

protected function cevalBuiltinIdentity "function: cevalBuiltinIdentity
  author: PA
  
  Evaluates the cat operator, for matrix concatenation.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Integer dim_int,dim_int_1;
      list<Exp.Exp> expl;
      list<Values.Value> retExp;
      list<Env.Frame> env;
      Exp.Exp dim;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{dim},impl,st,msg)
      equation 
        (Values.INTEGER(dim_int),_) = ceval(env, dim, impl, st, NONE, msg);
        dim_int_1 = dim_int + 1;
        expl = Util.listFill(Exp.ICONST(1), dim_int);
        retExp = cevalBuiltinDiagonal2(env, Exp.ARRAY(Exp.INT(),true,expl), impl, st, dim_int_1, 
          1, {}, msg);
      then
        (Values.ARRAY(retExp),st);
  end matchcontinue;
end cevalBuiltinIdentity;

protected function cevalBuiltinPromote "function: cevalBuiltinPromote
  author: PA
  
  Evaluates the internal promote operator, for promotion of arrays
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value arr_val,res;
      Integer dim_val;
      list<Env.Frame> env;
      Exp.Exp arr,dim;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{arr,dim},impl,st,msg)
      equation 
        (arr_val,_) = ceval(env, arr, impl, st, NONE, msg);
        (Values.INTEGER(dim_val),_) = ceval(env, dim, impl, st, NONE, msg);
        res = cevalBuiltinPromote2(arr_val, dim_val);
      then
        (res,st);
  end matchcontinue;
end cevalBuiltinPromote;

protected function cevalBuiltinPromote2 "function: cevalBuiltinPromote2
 
  Helper function to ceval_builtin_promote
"
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

protected function cevalCat "function: cevalCat
 
  evaluates the cat operator given a list of array values and a 
  concatenation dimension.
"
  input list<Values.Value> v_lst;
  input Integer dim;
  output Values.Value outValue;
  list<Values.Value> v_lst_1;
algorithm 
  v_lst_1 := catDimension(v_lst, dim);
  outValue := Values.ARRAY(v_lst_1);
end cevalCat;

protected function catDimension "function: catDimension
  
  Helper function to ceval_cat, concatenates a list arrays as
  Values, given a dimension as integer.
"
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
 
  Helper function to cat_dimension.
"
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
  
  evaluates the floor operator.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinFloor;

protected function cevalBuiltinCeil "function cevalBuiltinCeil
  author: LP
  
  evaluates the ceil operator.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1,rvt,rv_2;
      Integer ri,ri_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        rvt = intReal(ri);
        (rvt ==. rv) = true;
      then
        (Values.REAL(rv_1),st);
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        ri_1 = ri + 1;
        rv_2 = intReal(ri_1);
      then
        (Values.REAL(rv_2),st);
  end matchcontinue;
end cevalBuiltinCeil;

protected function cevalBuiltinSqrt "function: cevalBuiltinSqrt
  author: LP
  
  Evaluates the builtin sqrt operator.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        (rv <. 0.0) = true;
        Error.addMessage(Error.NEGATIVE_SQRT, {});
      then
        fail();
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realSqrt(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinSqrt;

protected function cevalBuiltinSin "function cevalBuiltinSin
  author: LP
 
  Evaluates the builtin sin function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realSin(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinSin;

protected function cevalBuiltinCos "function cevalBuiltinCos
  author: LP
 
  Evaluates the builtin cos function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = realCos(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinCos;

protected function cevalBuiltinTan "function cevalBuiltinTan
  author: LP
 
  Evaluates the builtin tan function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,sv,cv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg) /* tan is not implemented in RML for some strange reason. */ 
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        sv = realSin(rv);
        cv = realCos(rv);
        rv_1 = sv/.cv;
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinTan;

protected function cevalBuiltinAsin "function cevalBuiltinAsin
  author: PA
 
  Evaluates the builtin asin function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = System.asin(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinAsin;

protected function cevalBuiltinAcos "function cevalBuiltinAcos
  author: PA
 
  Evaluates the builtin acos function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = System.acos(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinAcos;

protected function cevalBuiltinAtan "function cevalBuiltinAtan
  author: PA
 
  Evaluates the builtin atan function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg) /* atan is not implemented in RML for some strange reason. */ 
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        rv_1 = System.atan(rv);
      then
        (Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinAtan;

protected function cevalBuiltinDiv "function cevalBuiltinDiv
  author: LP
 
  Evaluates the builtin div operator.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rv_1,rv_2;
      Integer ri,ri_1,ri1,ri2;
      list<Env.Frame> env;
      Exp.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str,lh_str,rh_str;
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.REAL(rv1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rv_1 = rv1/.rv2;
        ri = realInt(rv_1);
        rv_2 = intReal(ri);
      then
        (Values.REAL(rv_2),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.INTEGER(ri),_) = ceval(env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rv_1 = rv1/.rv2;
        ri_1 = realInt(rv_1);
        rv_2 = intReal(ri_1);
      then
        (Values.REAL(rv_2),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.REAL(rv1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.INTEGER(ri),_) = ceval(env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
        rv_1 = rv1/.rv2;
        ri_1 = realInt(rv_1);
        rv_2 = intReal(ri_1);
      then
        (Values.REAL(rv_2),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.INTEGER(ri1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, msg);
        ri_1 = ri1/ri2;
      then
        (Values.INTEGER(ri_1),st);
    case (env,{exp1,exp2},impl,st,MSG())
      equation 
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, MSG());
        (rv2 ==. 0.0) = true;
        exp1_str = Exp.printExpStr(exp1);
        exp2_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.DIVISION_BY_ZERO, {exp1_str,exp2_str});
      then
        fail();
    case (env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (env,{exp1,exp2},impl,st,MSG())
      equation 
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, MSG());
        (ri2 == 0) = true;
        lh_str = Exp.printExpStr(exp1);
        rh_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str});
      then
        fail();
    case (env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiv;

protected function cevalBuiltinMod "function cevalBuiltinMod
  author: LP
 
  Evaluates the builtin mod operator.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rva,rvb,rvc,rvd;
      list<Env.Frame> env;
      Exp.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer ri,ri1,ri2,ri_1;
      String lhs_str,rhs_str;
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.REAL(rv1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
      then
        (Values.REAL(rvd),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.INTEGER(ri),_) = ceval(env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
      then
        (Values.REAL(rvd),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.REAL(rv1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.INTEGER(ri),_) = ceval(env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
      then
        (Values.REAL(rvd),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.INTEGER(ri1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rv1 = intReal(ri1);
        rv2 = intReal(ri2);
        rva = rv1/.rv2;
        rvb = realFloor(rva);
        rvc = rvb*.rv2;
        rvd = rv1 -. rvc;
        ri_1 = realInt(rvd);
      then
        (Values.INTEGER(ri_1),st);
    case (env,{exp1,exp2},impl,st,MSG())
      equation 
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, MSG());
        (rv2 ==. 0.0) = true;
        lhs_str = Exp.printExpStr(exp1);
        rhs_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str});
      then
        fail();
    case (env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (env,{exp1,exp2},impl,st,MSG())
      equation 
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, MSG());
        (ri2 == 0) = true;
        lhs_str = Exp.printExpStr(exp1);
        rhs_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str});
      then
        fail();
    case (env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinMod;

protected function cevalBuiltinMax "function cevalBuiltinMax
  author: LP
 
  Evaluates the builtin max function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v,v_1;
      list<Env.Frame> env;
      Exp.Exp arr,s1,s2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer i1,i2,i;
      Real r1,r2,r;
    case (env,{arr},impl,st,msg)
      equation 
        (v,_) = ceval(env, arr, impl, st, NONE, msg);
        (v_1) = cevalBuiltinMax2(v);
      then
        (v_1,st);
    case (env,{s1,s2},impl,st,msg)
      equation 
        (Values.INTEGER(i1),_) = ceval(env, s1, impl, st, NONE, msg);
        (Values.INTEGER(i2),_) = ceval(env, s2, impl, st, NONE, msg);
        i = intMax(i1, i2);
      then
        (Values.INTEGER(i),st);
    case (env,{s1,s2},impl,st,msg)
      equation 
        (Values.REAL(r1),_) = ceval(env, s1, impl, st, NONE, msg);
        (Values.REAL(r2),_) = ceval(env, s2, impl, st, NONE, msg);
        r = realMax(r1, r2);
      then
        (Values.REAL(r),st);
  end matchcontinue;
end cevalBuiltinMax;

protected function cevalBuiltinMax2 "function: cevalBuiltinMax2
 
  Helper function to ceval_builtin_max.
"
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
        print("ceval_builtin_max2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinMax2;

protected function cevalBuiltinMin "function: cevalBuiltinMin
  author: PA
 
  Constant evaluation of builtin min function.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Values.Value v,v_1;
      list<Env.Frame> env;
      Exp.Exp arr,s1,s2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      Integer i1,i2,i;
      Real r1,r2,r;
    case (env,{arr},impl,st,msg)
      equation 
        (v,_) = ceval(env, arr, impl, st, NONE, msg);
        (v_1) = cevalBuiltinMin2(v);
      then
        (v_1,st);
    case (env,{s1,s2},impl,st,msg)
      equation 
        (Values.INTEGER(i1),_) = ceval(env, s1, impl, st, NONE, msg);
        (Values.INTEGER(i2),_) = ceval(env, s2, impl, st, NONE, msg);
        i = intMin(i1, i2);
      then
        (Values.INTEGER(i),st);
    case (env,{s1,s2},impl,st,msg)
      equation 
        (Values.REAL(r1),_) = ceval(env, s1, impl, st, NONE, msg);
        (Values.REAL(r2),_) = ceval(env, s2, impl, st, NONE, msg);
        r = realMin(r1, r2);
      then
        (Values.REAL(r),st);
  end matchcontinue;
end cevalBuiltinMin;

protected function cevalBuiltinMin2 "function: cevalBuiltinMin2
 
  Helper function to ceval_builtin_min.
"
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
  
  This function differentiates an equation: x^2 + x => 2x + 1
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Exp.Exp differentiated_exp,differentiated_exp_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp1,Exp.CREF(componentRef = cr)},impl,st,msg)
      equation 
        differentiated_exp = Derive.differentiateExp(exp1, cr);
        differentiated_exp_1 = Exp.simplify(differentiated_exp);
        ret_val = Exp.printExpStr(differentiated_exp_1) "this is wrong... this should be used instead but unelab_exp must be able to unelaborate a complete exp 
           now it doesn\'t so the expression is returned as string Exp.unelab_exp(differentiated_exp\') => absyn_exp" ;
      then
        (Values.STRING(ret_val),st);
    case (_,_,_,st,msg) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */ 
      equation 
        Print.printBuf("#Differentiation failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDifferentiate;

protected function cevalBuiltinSimplify "function cevalBuiltinSimplify
  author: LP
 
  this function simplifies an equation: x^2 + x => 2x + 1
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Exp.Exp exp1_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp1},impl,st,msg)
      equation 
        exp1_1 = Exp.simplify(exp1);
        ret_val = Exp.printExpStr(exp1_1) "this should be used instead but unelab_exp must be able to unelaborate a complete exp Exp.unelab_exp(simplifyd_exp\') => absyn_exp" ;
      then
        (Values.STRING(ret_val),st);
    case (_,_,_,st,MSG()) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */ 
      equation 
        Print.printBuf("#simplification failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSimplify;

protected function cevalBuiltinRem "function cevalBuiltinRem
  author: LP
 
  Evaluates the builtin rem operator
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv1,rv2,rva,rva_1,rvb,rvd;
      Integer rvai,ri,ri1,ri2,ri_1;
      list<Env.Frame> env;
      Exp.Exp exp1,exp2;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
      String exp1_str,exp2_str;
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.REAL(rv1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
      then
        (Values.REAL(rvd),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.INTEGER(ri),_) = ceval(env, exp1, impl, st, NONE, msg);
        rv1 = intReal(ri);
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
      then
        (Values.REAL(rvd),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.REAL(rv1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.INTEGER(ri),_) = ceval(env, exp2, impl, st, NONE, msg);
        rv2 = intReal(ri);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
      then
        (Values.REAL(rvd),st);
    case (env,{exp1,exp2},impl,st,msg)
      equation 
        (Values.INTEGER(ri1),_) = ceval(env, exp1, impl, st, NONE, msg);
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, msg);
        rv1 = intReal(ri1);
        rv2 = intReal(ri2);
        rva = rv1/.rv2;
        rvai = realInt(rva);
        rva_1 = intReal(rvai);
        rvb = rva_1*.rv2;
        rvd = rv1 -. rvb;
        ri_1 = realInt(rvd);
      then
        (Values.INTEGER(ri_1),st);
    case (env,{exp1,exp2},impl,st,MSG())
      equation 
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, MSG());
        (rv2 ==. 0.0) = true;
        exp1_str = Exp.printExpStr(exp1);
        exp2_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str});
      then
        fail();
    case (env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (Values.REAL(rv2),_) = ceval(env, exp2, impl, st, NONE, NO_MSG());
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (env,{exp1,exp2},impl,st,MSG())
      equation 
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, MSG());
        (ri2 == 0) = true;
        exp1_str = Exp.printExpStr(exp1);
        exp2_str = Exp.printExpStr(exp2);
        Error.addMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str});
      then
        fail();
    case (env,{exp1,exp2},impl,st,NO_MSG())
      equation 
        (Values.INTEGER(ri2),_) = ceval(env, exp2, impl, st, NONE, NO_MSG());
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinRem;

protected function cevalBuiltinInteger "function cevalBuiltinInteger
  author: LP
 
  Evaluates the builtin integer operator
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Real rv;
      Integer ri;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.REAL(rv),_) = ceval(env, exp, impl, st, NONE, msg);
        ri = realInt(rv);
      then
        (Values.INTEGER(ri),st);
  end matchcontinue;
end cevalBuiltinInteger;

protected function cevalGenerateFunction "function: cevalGenerateFunction
  
 
  Generates code for a given function name.
"
  input Env.Env inEnv;
  input Absyn.Path inPath;
algorithm 
  _:=
  matchcontinue (inEnv,inPath)
    local
      String pathstr,gencodestr,filename;
      list<Env.Frame> env;
      Absyn.Path path;
    case (env,path)
      equation 
        Debug.fprintln("ceval", "/*- ceval_generate_function starting*/");
        pathstr = ModUtil.pathString2(path, "_");
        (gencodestr,_) = cevalGenerateFunctionStr(path, env, {});
        filename = stringAppend(pathstr, ".c");
        Print.clearBuf();
        Print.printBuf(
          "#include \"modelica.h\"\n#include <stdio.h>\n#include <stdlib.h>\n#include <errno.h>\n") "
	 string_append(\"CEVALGENFUNC_\", pathstr) => defmacro &
	 Print.printBuf \"#ifndef \" & Print.printBuf defmacro & Print.printBuf \"\\n\" &
	 Print.printBuf \"#define \" & Print.printBuf defmacro & Print.printBuf \"\\n\" &
" ;
        Print.printBuf(gencodestr);
        Print.printBuf("\nint main(int argc, char** argv)\n");
        Print.printBuf("{\n\n  if (argc != 3)\n");
        Print.printBuf(
          "{\n      fprintf(stderr,\"# Incorrect number of arguments\\n\");\n");
        Print.printBuf("return 1;\n    }\n");
        Print.printBuf("_");
        Print.printBuf(pathstr);
        Print.printBuf("_read_call_write(argv[1],argv[2]);\n  return 0;\n}\n");
        Print.writeBuf(filename) "
	 Print.printBuf \"#endif /*\" & Print.printBuf defmacro & Print.printBuf \"*/\\n\" & 
" ;
        System.compileCFile(filename);
      then
        ();
    case (_,_)
      equation 
        Debug.fprint("failtrace", "/*- ceval_generate_function failed*/\n");
      then
        fail();
  end matchcontinue;
end cevalGenerateFunction;

protected function cevalGenerateFunctionStr "function: cevalGenerateFunctionStr
 
  Generates a function with the given path, and all functions that are called
   within that function. The string list contains names of functions already
  generated, which won\'t be generated again 
"
  input Absyn.Path inPath;
  input Env.Env inEnv;
  input list<Absyn.Path> inAbsynPathLst;
  output String outString;
  output list<Absyn.Path> outAbsynPathLst;
algorithm 
  (outString,outAbsynPathLst):=
  matchcontinue (inPath,inEnv,inAbsynPathLst)
    local
      Absyn.Path gfmember,path;
      list<Env.Frame> env,env_1,env_2;
      list<Absyn.Path> gflist,calledfuncs,gflist_1;
      SCode.Class cls;
      list<DAE.Element> d;
      list<String> debugfuncs,calledfuncsstrs,libs,calledfuncsstrs_1;
      String debugfuncsstr,funcname,funccom,thisfuncstr,resstr;
      DAE.DAElist d_1;
    case (path,env,gflist) /* If getmember succeeds, path is in generated functions list, so do nothing */ 
      equation 
        gfmember = Util.listGetmemberP(path, gflist, ModUtil.pathEqual);
      then
        ("",gflist);
    case (path,env,gflist) /* If getmember fails, path is not in generated functions list, hence
	  generate it */ 
      equation 
        failure(_ = Util.listGetmemberP(path, gflist, ModUtil.pathEqual));
        Debug.fprintln("ceval", "/*- ceval_generate_function_str starting*/");
        (cls,env_1) = Lookup.lookupClass(env, path, false);
        Debug.fprintln("ceval", "/*- ceval_generate_function_str instantiating*/");
        (env_2,d) = Inst.implicitFunctionInstantiation(env_1, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          cls, {}, false);
        Debug.fprint("ceval", 
          "/*- ceval_generate_function_str getting functions: ");
        calledfuncs = SimCodegen.getCalledFunctionsInFunction(path, DAE.DAE(d));
        debugfuncs = Util.listMap(calledfuncs, Absyn.pathString);
        debugfuncsstr = Util.stringDelimitList(debugfuncs, ", ");
        Debug.fprint("ceval", debugfuncsstr);
        Debug.fprintln("ceval", "*/");
        (calledfuncsstrs,gflist_1) = cevalGenerateFunctionStrList(calledfuncs, env, gflist);
        Debug.fprint("ceval", "/*- ceval_generate_function_str prefixing dae */");
        d_1 = ModUtil.stringPrefixParams(DAE.DAE(d));
        Print.clearBuf();
        funcname = Absyn.pathString(path);
        funccom = Util.stringAppendList({"/*---FUNC: ",funcname," ---*/\n\n"});
        Print.printBuf(funccom);
        Debug.fprintln("ceval", 
          "/* - ceval_generate_function_str generating functions */");
        libs = Codegen.generateFunctions(d_1);
        thisfuncstr = Print.getString();
        calledfuncsstrs_1 = Util.listAppendElt(thisfuncstr, calledfuncsstrs);
        resstr = Util.stringDelimitList(calledfuncsstrs_1, "\n\n");
      then
        (resstr,(path :: gflist));
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "/*- ceval_generate_function_str failed*/\n");
      then
        fail();
  end matchcontinue;
end cevalGenerateFunctionStr;

protected function cevalGenerateFunctionStrList "function: cevalGenerateFunctionStrList
 
  Generates code for several functions.
"
  input list<Absyn.Path> inAbsynPathLst1;
  input Env.Env inEnv2;
  input list<Absyn.Path> inAbsynPathLst3;
  output list<String> outStringLst;
  output list<Absyn.Path> outAbsynPathLst;
algorithm 
  (outStringLst,outAbsynPathLst):=
  matchcontinue (inAbsynPathLst1,inEnv2,inAbsynPathLst3)
    local
      list<Env.Frame> env;
      list<Absyn.Path> gflist,gflist_1,gflist_2,rest;
      String firststr;
      list<String> reststr;
      Absyn.Path first;
    case ({},env,gflist) then ({},gflist); 
    case ((first :: rest),env,gflist)
      equation 
        (firststr,gflist_1) = cevalGenerateFunctionStr(first, env, gflist);
        (reststr,gflist_2) = cevalGenerateFunctionStrList(rest, env, gflist_1);
      then
        ((firststr :: reststr),gflist_2);
  end matchcontinue;
end cevalGenerateFunctionStrList;

protected function cevalBuiltinDiagonal "function cevalBuiltinDiagonal
 
  This function generates a matrix{n,n} (A) of the vector {a,b,...,n}
  where the diagonal of A is the vector {a,b,...,n}
  ie A{1,1} == a, A{2,2} == b ...
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Values.Value> rv2,retExp;
      Integer dimension,correctDimension;
      String dimensionString;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.ARRAY(rv2),_) = ceval(env, exp, impl, st, NONE, msg);
        dimension = listLength(rv2);
        correctDimension = dimension + 1;
        retExp = cevalBuiltinDiagonal2(env, exp, impl, st, correctDimension, 1, {}, msg);
        dimensionString = intString(dimension);
        Debug.fcall("ceval", Print.printBuf, "== dimensionString ");
        Debug.fcall("ceval", Print.printBuf, dimensionString);
        Debug.fcall("ceval", Print.printBuf, "\n");
      then
        (Values.ARRAY(retExp),st);
    case (_,_,_,_,MSG())
      equation 
        Print.printErrorBuf("#Error, could not evaulate diagonal.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal;

protected function cevalBuiltinDiagonal2 "function: cevalBuiltinDiagonal2
  
   This is a help function that is calling itself recursively to 
   generate the a nxn matrix with some special diagonal elements. 
  see ceval_builtin_diagonal 
 
  signature : (Env.Env, 
				    Exp.Exp, 
				    bool, 
				    Interactive.InteractiveSymbolTable option, 
				    int, /* matrix dimension */
				    int,  /* row */
				    Values.Value list,
				    Msg) 
	  =>  Values.Value list 
"
  input Env.Env inEnv1;
  input Exp.Exp inExp2;
  input Boolean inBoolean3;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Values.Value> inValuesValueLst7;
  input Msg inMsg8;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inEnv1,inExp2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inInteger5,inInteger6,inValuesValueLst7,inMsg8)
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
    case (env,s1,impl,st,matrixDimension,row,{},msg)
      equation 
        (Values.REAL(rv2),_) = ceval(env, Exp.ASUB(s1,row), impl, st, NONE, msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceat(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        retExp = cevalBuiltinDiagonal2(env, s1, impl, st, matrixDimension, newRow, 
          {Values.ARRAY(listWithElement)}, msg);
      then
        retExp;
    case (env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation 
        (Values.REAL(rv2),_) = ceval(env, Exp.ASUB(s1,row), impl, st, NONE, msg);
        failure(equality(matrixDimension = row));
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceat(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        appendedList = listAppend(listIN, {Values.ARRAY(listWithElement)});
        retExp = cevalBuiltinDiagonal2(env, s1, impl, st, matrixDimension, newRow, appendedList, 
          msg);
      then
        retExp;
    case (env,s1,impl,st,matrixDimension,row,{},msg)
      local Integer rv2;
      equation 
        (Values.INTEGER(rv2),_) = ceval(env, Exp.ASUB(s1,row), impl, st, NONE, msg);
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceat(Values.INTEGER(rv2), correctPlace, zeroList);
        newRow = row + 1;
        retExp = cevalBuiltinDiagonal2(env, s1, impl, st, matrixDimension, newRow, 
          {Values.ARRAY(listWithElement)}, msg);
      then
        retExp;
    case (env,s1,impl,st,matrixDimension,row,listIN,msg)
      local Integer rv2;
      equation 
        (Values.INTEGER(rv2),_) = ceval(env, Exp.ASUB(s1,row), impl, st, NONE, msg);
        failure(equality(matrixDimension = row));
        correctDim = matrixDimension - 1;
        zeroList = Util.listFill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = Util.listReplaceat(Values.INTEGER(rv2), correctPlace, zeroList);
        newRow = row + 1;
        appendedList = listAppend(listIN, {Values.ARRAY(listWithElement)});
        retExp = cevalBuiltinDiagonal2(env, s1, impl, st, matrixDimension, newRow, appendedList, 
          msg);
      then
        retExp;
    case (env,s1,impl,st,matrixDimension,row,listIN,msg)
      equation 
        equality(matrixDimension = row);
      then
        listIN;
    case (_,_,_,_,matrixDimension,row,list_,MSG())
      equation 
        print(
          "#-- ceval_builtin_diagonal2: Couldn't elaborate ceval_builtin_diagonal2()\n");
        RowString = intString(row);
        matrixDimensionString = intString(matrixDimension);
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal2;

protected function cevalBuiltinTranspose "function cevalBuiltinTranspose
 
  This function transposes the two first dimension of an array A.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Values.Value> vlst,vlst2,vlst_1;
      Integer dim1;
      list<Env.Frame> env;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Msg msg;
    case (env,{exp},impl,st,msg)
      equation 
        (Values.ARRAY(vlst),_) = ceval(env, exp, impl, st, NONE, msg);
        (Values.ARRAY(valueLst = vlst2) :: _) = vlst;
        dim1 = listLength(vlst2);
        vlst_1 = cevalBuiltinTranspose2(vlst, 1, dim1);
      then
        (Values.ARRAY(vlst_1),st);
    case (_,_,_,_,MSG())
      equation 
        Print.printErrorBuf("#Error, could not evaulate transpose.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinTranspose;

protected function cevalBuiltinTranspose2 "function: cevalBuiltinTranspose2
  author: PA
 
  Helper function to ceval_builtin_transpose
 
  signature: (Values.Value list, 
				    int /* index */,
				    int) /* dim1 */
	  => Values.Value list 
"
  input list<Values.Value> inValuesValueLst1;
  input Integer inInteger2;
  input Integer inInteger3;
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
 
  Helper function for ceval_builtin_size, for size(A) where 
  A is a matrix.
"
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output Values.Value outValue;
  output Option<Interactive.InteractiveSymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm 
  (outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
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
    case (env,Exp.CREF(componentRef = cr,component = tp),impl,st,msg)
      equation 
        (attr,tp,bind) = Lookup.lookupVar(env, cr);
        sizelst = Types.getDimensionSizes(tp);
        v = Values.intlistToValue(sizelst);
      then
        (v,st);
    case (env,exp,impl,st,msg)
      equation 
        (v,st_1) = ceval(env, exp, impl, st, NONE, msg);
        tp = Types.typeOfValue(v);
        sizelst = Types.getDimensionSizes(tp);
        v = Values.intlistToValue(sizelst);
      then
        (v,st);
  end matchcontinue;
end cevalBuiltinSizeMatrix;

protected function cevalRelation "function: cevalRelation
 
  Performs the function check and gives a boolean result.
"
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
    case (v1,Exp.GREATER(type_ = t),v2)
      equation 
        v = cevalRelation(v2, Exp.LESS(t), v1);
      then
        v;
    case (Values.INTEGER(integer = i1),Exp.LESS(type_ = Exp.INT()),Values.INTEGER(integer = i2)) /* Integers */ 
      equation 
        b = (i1 < i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.LESSEQ(type_ = Exp.INT()),Values.INTEGER(integer = i2))
      equation 
        b = (i1 <= i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.GREATEREQ(type_ = Exp.INT()),Values.INTEGER(integer = i2))
      equation 
        b = (i1 >= i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.EQUAL(type_ = Exp.INT()),Values.INTEGER(integer = i2))
      equation 
        b = (i1 == i2);
      then
        Values.BOOL(b);
    case (Values.INTEGER(integer = i1),Exp.NEQUAL(type_ = Exp.INT()),Values.INTEGER(integer = i2)) /* Reals */ 
      equation 
        b = (i1 <> i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.LESS(type_ = Exp.REAL()),Values.REAL(real = i2)) /* Reals */ 
      local Real i1,i2;
      equation 
        b = (i1 <. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.LESSEQ(type_ = Exp.REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation 
        b = (i1 <=. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.GREATEREQ(type_ = Exp.REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation 
        b = (i1 >=. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.EQUAL(type_ = Exp.REAL()),Values.REAL(real = i2))
      local Real i1,i2;
      equation 
        b = (i1 ==. i2);
      then
        Values.BOOL(b);
    case (Values.REAL(real = i1),Exp.NEQUAL(type_ = Exp.REAL()),Values.REAL(real = i2)) /* Booleans */ 
      local Real i1,i2;
      equation 
        b = (i1 <>. i2);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = b1),Exp.NEQUAL(type_ = Exp.BOOL()),Values.BOOL(boolean = b2)) /* Booleans */ 
      equation 
        nb1 = boolNot(b1) "b1 != b2  == (b1 and not b2) or (not b1 and b2)" ;
        nb2 = boolNot(b2);
        ba = boolAnd(b1, nb2);
        bb = boolAnd(nb1, b2);
        b = boolOr(ba, bb);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = b1),Exp.EQUAL(type_ = Exp.BOOL()),Values.BOOL(boolean = b2))
      equation 
        nb1 = boolNot(b1) "b1 == b2  ==> b1 and b2 or (not b1 and not b2)" ;
        nb2 = boolNot(b2);
        ba = boolAnd(b1, b2);
        bb = boolAnd(nb1, nb2);
        b = boolOr(ba, bb);
      then
        Values.BOOL(b);
    case (Values.BOOL(boolean = false),Exp.LESS(type_ = Exp.BOOL()),Values.BOOL(boolean = true)) then Values.BOOL(true); 
    case (Values.BOOL(boolean = _),Exp.LESS(type_ = Exp.BOOL()),Values.BOOL(boolean = _)) then Values.BOOL(false); 
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "- ceval_relation failed\n");
        print("-ceval_relation failed\n");
      then
        fail();
  end matchcontinue;
end cevalRelation;

protected function cevalRange "function: cevalRange
 
  This re-lation evaluates a range expression.  It only handles integers.
"
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
 
  Helper function to ceval_range.
"
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
 
  This function evaluates a range expression.  It only handles reals
"
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
 
  Helper function to ceval_range_real.
"
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
 
  This function does a constant evaluation on a number of expressions.
"
  input Env.Env inEnv;
  input list<Exp.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Msg inMsg;
  output list<Values.Value> outValuesValueLst;
algorithm 
  outValuesValueLst:=
  matchcontinue (inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Msg msg;
      Values.Value v;
      Exp.Exp exp;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      list<Values.Value> vs;
      list<Exp.Exp> exps;
    case (env,{},_,_,msg) then {}; 
    case (env,{exp},impl,st,msg)
      equation 
        (v,_) = ceval(env, exp, impl, st, NONE, msg);
      then
        {v};
    case (env,(exp :: exps),impl,st,msg)
      equation 
        (v,_) = ceval(env, exp, impl, st, NONE, msg);
        vs = cevalList(env, exps, impl, st, msg);
      then
        (v :: vs);
  end matchcontinue;
end cevalList;

protected function cevalCref "function: cevalCref
 
  Evaluates ComponentRef, i.e. variables, by looking up variables in the
  environment.
 
  signature: (Env.Env, Exp.ComponentRef, bool, /*impl*/ Msg) 
	  => Values.Value
"
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input Boolean inBoolean;
  input Msg inMsg;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inEnv,inComponentRef,inBoolean,inMsg)
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
    case (env,c,impl,msg) /* Search in env for binding. */ 
      equation 
        (attr,ty,binding) = Lookup.lookupVar(env, c);
        v = cevalCrefBinding(env, c, binding, impl, msg);
      then
        v;
    case (env,c,(impl as false),MSG())
      equation 
        failure((_,_,_) = Lookup.lookupVar(env, c));
        scope_str = Env.printEnvPathStr(env);
        str = Exp.printComponentRefStr(c);
        Error.addMessage(Error.LOOKUP_VARIABLE_ERROR, {str,scope_str});
      then
        fail();
    case (env,c,(impl as false),NO_MSG())
      equation 
        failure((_,_,_) = Lookup.lookupVar(env, c));
      then
        fail();
    case (env,c,(impl as false),MSG()) /* No binding found. */ 
      equation 
        str = Exp.printComponentRefStr(c);
        scope_str = Env.printEnvPathStr(env);
        Error.addMessage(Error.NO_CONSTANT_BINDING, {str,scope_str});
      then
        fail();
  end matchcontinue;
end cevalCref;

protected function cevalCrefBinding "function: cevalCrefBinding
 
  Helper function to ceval_cref. Evaluates varaibles by evaluating 
  their bindings.
 
  signature: ceval_cref_binding : (Env.Env, Exp.ComponentRef,
			       Types.Binding, 
			       bool, /*impl*/
			       Msg) 
	  => Values.Value
"
  input Env.Env inEnv;
  input Exp.ComponentRef inComponentRef;
  input Types.Binding inBinding;
  input Boolean inBoolean;
  input Msg inMsg;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inEnv,inComponentRef,inBinding,inBoolean,inMsg)
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
    case (env,cr,Types.VALBOUND(valBound = v),impl,msg) /* Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (_,tp,_) = Lookup.lookupVar(env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        res = cevalSubscriptValue(env, subsc, v, sizelst, impl, msg);
      then
        res;
    case (env,_,Types.UNBOUND(),(impl as false),MSG())
      equation 
        Print.printBuf("- ceval_cref_binding failed (UNBOUND)\n");
      then
        fail();
    case (env,_,Types.UNBOUND(),(impl as true),MSG())
      equation 
        Debug.fprint("ceval", 
          "#- ceval_cref__binding: Ignoring unbound when implicit");
      then
        fail();
    case (env,Exp.CREF_IDENT(ident = id,subscriptLst = subsc),Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,MSG()) /* REDUCTION bindings */ 
      equation 
        Exp.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        equality(rfn = "array");
        Debug.fprintln("ceval", "#-- ceval_cref_binding Array evaluation");
      then
        fail();
    case (env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,msg) /* REDUCTION bindings Exp.CREF_IDENT(id,subsc) */ 
      equation 
        Exp.REDUCTION(path = Absyn.IDENT(name = rfn),expr = elexp,ident = iter,range = iterexp) = exp;
        failure(equality(rfn = "array"));
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (_,tp,_) = Lookup.lookupVar(env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (v,_) = ceval(env, exp, impl, NONE, NONE, msg);
        res = cevalSubscriptValue(env, subsc, v, sizelst, impl, msg);
      then
        res;
    case (env,cr,Types.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = Types.C_VAR()),impl,msg) /* arbitrary expressions, C_VAR, value exists. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (_,tp,_) = Lookup.lookupVar(env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        res = cevalSubscriptValue(env, subsc, e_val, sizelst, impl, msg);
      then
        res;
    case (env,cr,Types.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = Types.C_PARAM()),impl,msg) /* arbitrary expressions, C_PARAM, value exists. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (_,tp,_) = Lookup.lookupVar(env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        res = cevalSubscriptValue(env, subsc, e_val, sizelst, impl, msg);
      then
        res;
    case (env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_CONST()),impl,msg) /* arbitrary expressions. When binding has optional value. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (_,tp,_) = Lookup.lookupVar(env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (v,_) = ceval(env, exp, impl, NONE, NONE, msg);
        res = cevalSubscriptValue(env, subsc, v, sizelst, impl, msg);
      then
        res;
    case (env,cr,Types.EQBOUND(exp = exp,constant_ = Types.C_PARAM()),impl,msg) /* arbitrary expressions. When binding has optional value. Exp.CREF_IDENT(id,subsc) */ 
      equation 
        cr_1 = Exp.crefStripLastSubs(cr) "lookup without subscripts, so dimension sizes can be determined." ;
        subsc = Exp.crefLastSubs(cr);
        (_,tp,_) = Lookup.lookupVar(env, cr_1) "Exp.CREF_IDENT(id,{})" ;
        sizelst = Types.getDimensionSizes(tp);
        (v,_) = ceval(env, exp, impl, NONE, NONE, msg);
        res = cevalSubscriptValue(env, subsc, v, sizelst, impl, msg);
      then
        res;
    case (env,_,Types.EQBOUND(exp = exp,constant_ = Types.C_VAR()),impl,MSG())
      equation 
        Debug.fprint("ceval", 
          "#- ceval_cref__binding failed (nonconstant EQBOUND(");
        expstr = Exp.printExpStr(exp);
        Debug.fprint("ceval", expstr);
        Debug.fprintln("ceval", "))");
      then
        fail();
    case (_,e1,Types.EQBOUND(exp = exp),_,_)
      equation 
        s1 = Exp.printComponentRefStr(e1);
        s2 = Exp.printExpStr(exp);
        str = Util.stringAppendList({"-ceval_cref_binding : ",s1," = ",s2," failed\n"});
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end cevalCrefBinding;

protected function cevalSubscriptValue "function: cevalSubscriptValue
 
  Helper function to ceval_cref_binding, applies subscrupts to array values
  to extract array elements.
 
  signature: (Env.Env,
				 Exp.Subscript list, /* subscript to extract*/
				 Values.Value, 
				 int list, /* dimension sizes */
				 bool, /*impl*/
				 Msg) 
	  => Values.Value
"
  input Env.Env inEnv;
  input list<Exp.Subscript> inExpSubscriptLst;
  input Values.Value inValue;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean;
  input Msg inMsg;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inEnv,inExpSubscriptLst,inValue,inIntegerLst,inBoolean,inMsg)
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
    case (env,(Exp.INDEX(a = exp) :: subs),Values.ARRAY(valueLst = lst),(dim :: dims),impl,msg)
      equation 
        (Values.INTEGER(n),_) = ceval(env, exp, impl, NONE, SOME(dim), msg);
        n_1 = n - 1;
        subval = listNth(lst, n_1);
        res = cevalSubscriptValue(env, subs, subval, dims, impl, msg);
      then
        res;
    case (env,{},v,_,_,_) then v; 
    case (_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "-ceval_subscript_value failed\n");
      then
        fail();
  end matchcontinue;
end cevalSubscriptValue;

public function cevalSubscripts "function: cevalSubscripts
 
  This function relates a list of subscripts to their canonical
  forms, which is when all expressions are evaluated to constant
  values.
 
  signature: (Env.Env, Exp.Subscript list, int list, 
			     bool, /*impl*/
			     Msg)
	  => Exp.Subscript list
"
  input Env.Env inEnv;
  input list<Exp.Subscript> inExpSubscriptLst;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean;
  input Msg inMsg;
  output list<Exp.Subscript> outExpSubscriptLst;
algorithm 
  outExpSubscriptLst:=
  matchcontinue (inEnv,inExpSubscriptLst,inIntegerLst,inBoolean,inMsg)
    local
      Exp.Subscript sub_1,sub;
      list<Exp.Subscript> subs_1,subs;
      list<Env.Frame> env;
      Integer dim;
      list<Integer> dims;
      Boolean impl;
      Msg msg;
    case (_,{},_,_,_) then {}; 
    case (env,(sub :: subs),(dim :: dims),impl,msg)
      equation 
        sub_1 = cevalSubscript(env, sub, dim, impl, msg);
        subs_1 = cevalSubscripts(env, subs, dims, impl, msg);
      then
        (sub_1 :: subs_1);
  end matchcontinue;
end cevalSubscripts;

protected function cevalSubscript "function: cevalSubscript
 
  This function relates a subscript to its canonical forms, which is
  when all expressions are evaluated to constant values.
 
  signature: (Env.Env, Exp.Subscript, int, 
			    bool, /*impl*/ 
			    Msg) => Exp.Subscript
"
  input Env.Env inEnv;
  input Exp.Subscript inSubscript;
  input Integer inInteger;
  input Boolean inBoolean;
  input Msg inMsg;
  output Exp.Subscript outSubscript;
algorithm 
  outSubscript:=
  matchcontinue (inEnv,inSubscript,inInteger,inBoolean,inMsg)
    local
      list<Env.Frame> env;
      Values.Value v1;
      Exp.Exp e1_1,e1;
      Integer dim;
      Boolean impl;
      Msg msg;
    case (env,Exp.WHOLEDIM(),_,_,_) then Exp.WHOLEDIM(); 
    case (env,Exp.INDEX(a = e1),dim,impl,msg)
      equation 
        (v1,_) = ceval(env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
      then
        Exp.INDEX(e1_1);
    case (env,Exp.SLICE(a = e1),dim,impl,msg)
      equation 
        (v1,_) = ceval(env, e1, impl, NONE, SOME(dim), msg);
        e1_1 = Static.valueExp(v1);
      then
        Exp.SLICE(e1_1);
  end matchcontinue;
end cevalSubscript;
end Ceval;

