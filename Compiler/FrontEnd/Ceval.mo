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

encapsulated package Ceval
" file:        Ceval.mo
  package:     Ceval
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
    InteractiveSymbolTable is optional, and used in interactive mode, e.g. from OMShell

  Output:
    Value: The evaluated value
    InteractiveSymbolTable: Modified symbol table
    Subscript list : Evaluates subscripts and generates constant expressions."

public import Absyn;
public import DAE;
public import Env;
public import GlobalScript;
public import InstTypes;
public import Values;
public import Lookup;

// protected imports
protected import CevalScript;
protected import ComponentReference;
protected import Config;
protected import Debug;
protected import Derive;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import Inst;
protected import List;
protected import Mod;
protected import ModelicaExternalC;
protected import Prefix;
protected import Print;
protected import SCode;
protected import Static;
protected import System;
protected import Types;
protected import Util;
protected import ValuesUtil;
protected import ClassInf;

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
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter "Maximum recursion depth";
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outValue,outST) := cevalWork1(inCache,inEnv,inExp,inBoolean,inST,inMsg,numIter,numIter > 100);
end ceval;

protected function cevalWork1
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter "Maximum recursion depth";
  input Boolean iterReached;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outValue,outST) := match (inCache,inEnv,inExp,inBoolean,inST,inMsg,numIter,iterReached)
    local
      Absyn.Info info;
      String str1,str2;
    case (_,_,_,_,_,_,_,false)
      equation
        (outCache,outValue,outST) = cevalWork2(inCache,inEnv,inExp,inBoolean,inST,inMsg,numIter);
      then (outCache,outValue,outST);
    case (_,_,_,_,_,Absyn.MSG(info=info),_,true)
      equation
        str1 = ExpressionDump.printExpStr(inExp);
        str2 = Env.printEnvPathStr(inEnv);
        Error.addSourceMessage(Error.RECURSION_DEPTH_WARNING, {str1,str2}, info);
      then fail();
  end match;
end cevalWork1;

protected function cevalWork2 "
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
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;

  partial function ReductionOperator
    input Values.Value v1;
    input Values.Value v2;
    output Values.Value res;
  end ReductionOperator;
algorithm
  (outCache,outValue,outST):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inST,inMsg,numIter)
    local
      Integer start_1,stop_1,step_1,i,indx_1,indx,index;
      Option<GlobalScript.SymbolTable> stOpt;
      Real lhvReal,rhvReal,sum,r,realStart1,realStop1,realStep1;
      String str,lhvStr,rhvStr,s;
      Boolean impl,b,b_1,lhvBool,rhvBool,resBool, bstart, bstop;
      Absyn.Exp exp_1,exp;
      list<Env.Frame> env;
      Absyn.Msg msg;
      Absyn.Element elt_1,elt;
      Absyn.CodeNode c;
      list<Values.Value> es_1,elts,vallst,vlst1,vlst2,reslst,aval,rhvals,lhvals,arr,arr_1,ivals,rvals,vals;
      list<DAE.Exp> es,expl;
      list<list<DAE.Exp>> expll;
      Values.Value v,newval,value,sval,elt1,elt2,v_1,lhs_1,rhs_1,resVal,lhvVal,rhvVal;
      DAE.Exp lh,rh,e,lhs,rhs,start,stop,step,e1,e2,cond;
      Absyn.Path funcpath,name;
      DAE.Operator relop;
      Env.Cache cache;
      DAE.Exp expExp;
      list<Integer> dims;
      DAE.Dimensions arrayDims;
      DAE.ComponentRef cr;
      list<String> fieldNames, n, names;
      DAE.Type t;
      GlobalScript.SymbolTable st;
      DAE.Exp daeExp;
      Absyn.Path path;
      Option<Values.Value> ov;
      Option<DAE.Exp> foldExp;
      DAE.Type ty;
      list<DAE.Type> tys;
      DAE.ReductionIterators iterators;
      list<list<Values.Value>> valMatrix;
      Absyn.Info info;

    // uncomment for debugging 
    // case (cache,env,inExp,_,st,_,_) 
    //   equation print("Ceval.ceval: " +& ExpressionDump.printExpStr(inExp) +& " in env: " +& Env.printEnvPathStr(env) +& "\n");
    //   then fail();

    case (cache,_,DAE.ICONST(integer = i),_,stOpt,_,_) then (cache,Values.INTEGER(i),stOpt);

    case (cache,_,DAE.RCONST(real = r),_,stOpt,_,_) then (cache,Values.REAL(r),stOpt);

    case (cache,_,DAE.SCONST(string = s),_,stOpt,_,_) then (cache,Values.STRING(s),stOpt);

    case (cache,_,DAE.BCONST(bool = b),_,stOpt,_,_) then (cache,Values.BOOL(b),stOpt);

    case (cache,_,DAE.ENUM_LITERAL(name = name, index = i),_,stOpt,_,_)
      then (cache, Values.ENUM_LITERAL(name, i), stOpt);

    case (cache,env,DAE.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,stOpt,msg,_)
      equation
        (cache,exp_1) = cevalAstExp(cache,env, exp, impl, stOpt, msg, Absyn.dummyInfo);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),stOpt);
    
    case (cache,env,DAE.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,stOpt,msg,_)
      equation
        (cache,exp_1) = cevalAstExp(cache,env, exp, impl, stOpt, msg, Absyn.dummyInfo);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)),stOpt);
    
    case (cache,env,DAE.CODE(code = Absyn.C_ELEMENT(element = elt)),impl,stOpt,msg,_)
      equation
        (cache,elt_1) = cevalAstElt(cache,env, elt, impl, stOpt, msg);
      then
        (cache,Values.CODE(Absyn.C_ELEMENT(elt_1)),stOpt);
    
    case (cache,env,DAE.CODE(code = c),_,stOpt,_,_) then (cache,Values.CODE(c),stOpt);
    
    case (cache,env,DAE.ARRAY(array = es, ty = DAE.T_ARRAY(dims = arrayDims)),impl,stOpt,msg,_)
      equation
        dims = List.map(arrayDims, Expression.dimensionSize);
        (cache,es_1, stOpt) = cevalList(cache,env, es, impl, stOpt,msg,numIter);
      then
        (cache,Values.ARRAY(es_1,dims),stOpt);

    case (cache,env,DAE.ARRAY(array = es, ty = DAE.T_ARRAY(dims = arrayDims)),impl,stOpt,msg,_)
      equation
        failure(_ = List.map(arrayDims, Expression.dimensionSize));
        (cache,es_1,stOpt) = cevalList(cache,env, es, impl, stOpt,msg,numIter);
      then
        (cache,ValuesUtil.makeArray(es_1),stOpt);

    case (cache,env,DAE.MATRIX(matrix = expll, ty = DAE.T_ARRAY(dims = arrayDims)),impl,stOpt,msg,_)
      equation
        dims = List.map(arrayDims, Expression.dimensionSize);
        (cache,elts) = cevalMatrixElt(cache, env, expll, impl,msg,numIter+1);
      then
        (cache,Values.ARRAY(elts,dims),stOpt);

    // MetaModelica List. sjoelund 
    case (cache,env,DAE.LIST(valList = expl),impl,stOpt,msg,_)
      equation
        (cache,es_1,stOpt) = cevalList(cache,env, expl, impl, stOpt,msg,numIter);
      then
        (cache,Values.LIST(es_1),stOpt);

    case (cache,env,DAE.BOX(exp=e1),impl,stOpt,msg,_)
      equation
        (cache,v,stOpt) = ceval(cache,env,e1,impl,stOpt,msg,numIter+1);
      then
        (cache,v,stOpt);

    case (cache,env,DAE.UNBOX(exp=e1),impl,stOpt,msg,_)
      equation
        (cache,Values.META_BOX(v),stOpt) = ceval(cache,env,e1,impl,stOpt,msg,numIter+1);
      then
        (cache,v,stOpt);

    case (cache,env,DAE.CONS(car=e1,cdr=e2),impl,stOpt,msg,_)
      equation
        (cache,v,stOpt) = ceval(cache,env,e1,impl,stOpt,msg,numIter+1);
        (cache,Values.LIST(vallst),stOpt) = ceval(cache,env,e2,impl,stOpt,msg,numIter);
      then
        (cache,Values.LIST(v::vallst),stOpt);

    // MetaModelica Partial Function. sjoelund 
    case (cache,env,DAE.CREF(componentRef = cr, 
        ty = DAE.T_FUNCTION_REFERENCE_VAR(source = _)),impl,stOpt,Absyn.MSG(info = info),_)
      equation
        str = ComponentReference.crefStr(cr);
        Error.addSourceMessage(Error.META_CEVAL_FUNCTION_REFERENCE, {str}, info);
      then
        fail();

    case (cache,env,DAE.CREF(componentRef = cr, ty = DAE.T_FUNCTION_REFERENCE_FUNC(builtin = _)),
        impl, stOpt, Absyn.MSG(info = info),_)
      equation
        str = ComponentReference.crefStr(cr);
        Error.addSourceMessage(Error.META_CEVAL_FUNCTION_REFERENCE, {str}, info);
      then
        fail();

    // MetaModelica Uniontype Constructor. sjoelund 2009-05-18
    case (cache,env,DAE.METARECORDCALL(path=funcpath,args=expl,fieldNames=fieldNames,index=index),impl,stOpt,msg,_)
      equation
        (cache,vallst,stOpt) = cevalList(cache, env, expl, impl, stOpt,msg,numIter);
      then (cache,Values.RECORD(funcpath,vallst,fieldNames,index),stOpt);

    // MetaModelica Option type. sjoelund 2009-07-01 
    case (cache,env,DAE.META_OPTION(NONE()),impl,stOpt,msg,_)
      then (cache,Values.OPTION(NONE()),stOpt);
    case (cache,env,DAE.META_OPTION(SOME(expExp)),impl,stOpt,msg,_)
      equation
        (cache,value,stOpt) = ceval(cache,env,expExp,impl,stOpt,msg,numIter+1);
      then (cache,Values.OPTION(SOME(value)),stOpt);

    // MetaModelica Tuple. sjoelund 2009-07-02 
    case (cache,env,DAE.META_TUPLE(expl),impl,stOpt,msg,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,vallst,stOpt) = cevalList(cache, env, expl, impl, stOpt,msg,numIter);
      then (cache,Values.META_TUPLE(vallst),stOpt);

    case (cache,env,DAE.TUPLE(expl),impl,stOpt,msg,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,vallst,stOpt) = cevalList(cache, env, expl, impl, stOpt,msg,numIter);
      then (cache,Values.TUPLE(vallst),stOpt);

    case (cache,env,DAE.CREF(componentRef = cr),(impl as false),SOME(st),msg,_)
      equation
        (cache,v) = cevalCref(cache, env, cr, false, msg, numIter+1) "When in interactive mode, always evaluate crefs, i.e non-implicit mode.." ;
        //Debug.traceln("cevalCref cr: " +& ComponentReference.printComponentRefStr(c) +& " in s: " +& Env.printEnvPathStr(env) +& " v:" +& ValuesUtil.valString(v));
      then
        (cache,v,SOME(st));

    case (cache,env,DAE.CREF(componentRef = cr),impl,stOpt,msg,_)
      equation
        (cache,v) = cevalCref(cache,env, cr, impl,msg,numIter+1);
        //Debug.traceln("cevalCref cr: " +& ComponentReference.printComponentRefStr(c) +& " in s: " +& Env.printEnvPathStr(env) +& " v:" +& ValuesUtil.valString(v));
      then
        (cache,v,stOpt);
        
    // Evaluates for build in types. ADD, SUB, MUL, DIV for Reals and Integers.
    case (cache,env,expExp,impl,stOpt,msg,_)
      equation
        (cache,v,stOpt) = cevalBuiltin(cache,env, expExp, impl, stOpt,msg,numIter+1);
      then
        (cache,v,stOpt);

    // adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem 
    // lochel: do not evaluate impure function calls
    case (cache, env, (e as DAE.CALL(path=funcpath, expLst=expl, attr=DAE.CALL_ATTR(isImpure=false))), impl, stOpt, msg,_)
      equation
        // do not handle Connection.isRoot here!        
        false = stringEq("Connection.isRoot", Absyn.pathString(funcpath));
        // do not roll back errors generated by evaluating the arguments
        (cache, vallst, stOpt) = cevalList(cache, env, expl, impl, stOpt,msg,numIter);
        
        (cache, newval, stOpt)= CevalScript.cevalCallFunction(cache, env, e, vallst, impl, stOpt,msg,numIter+1);
      then
        (cache,newval,stOpt);

    // Try Interactive functions last
    case (cache,env,(e as DAE.CALL(path = _)),(impl as true),SOME(st),msg,_)
      equation
        (cache,value,st) = CevalScript.cevalInteractiveFunctions(cache, env, e, st,msg,numIter+1);
      then
        (cache,value,SOME(st));

    case (_,_,e as DAE.CALL(path = _),_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Ceval.ceval DAE.CALL failed: ");
        str = ExpressionDump.printExpStr(e);
        Debug.traceln(str);
      then
        fail();

    // Strings 
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.T_STRING(varLst = _)),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.STRING(lhvStr),_) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.STRING(rhvStr),_) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        str = stringAppend(lhvStr, rhvStr);
      then
        (cache,Values.STRING(str),stOpt);

    // Numerical
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.T_REAL(varLst = _)),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.REAL(lhvReal),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.REAL(rhvReal),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        sum = lhvReal +. rhvReal;
      then
        (cache,Values.REAL(sum),stOpt);

    // Array addition
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.addElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array subtraction
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_ARR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.subElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array multiplication
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.mulElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array division
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.divElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array power
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARR2(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(vlst2,_),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.powElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array multipled scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array add scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array subtract scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.subScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.powScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.powArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // scalar div array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_SCALAR_ARRAY(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,sval,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.divScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // array div scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARRAY_SCALAR(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,sval,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter+1);
        (cache,Values.ARRAY(aval,dims),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        reslst = ValuesUtil.divArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims),stOpt);

    // scalar multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_SCALAR_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(valueLst = rhvals),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        (cache,Values.ARRAY(valueLst = lhvals),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        resVal = ValuesUtil.multScalarProduct(rhvals, lhvals);
      then
        (cache,resVal,stOpt);

    // array multipled array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(valueLst = (lhvals as (elt1 :: _))),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter) "{{..}..{..}}  {...}" ;
        (cache,Values.ARRAY(valueLst = (rhvals as (elt2 :: _))),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        resVal = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,resVal,stOpt);

    // array multiplied array 
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(valueLst = (rhvals as (elt1 :: _))),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter) "{...}  {{..}..{..}}" ;
        (cache,Values.ARRAY(valueLst = (lhvals as (elt2 :: _))),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        resVal = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,resVal,stOpt);

    // array multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(ty = _),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY((rhvals as (elt1 :: _)),dims),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter+1) "{{..}..{..}}  {{..}..{..}}" ;
        (cache,Values.ARRAY((lhvals as (elt2 :: _)),_),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter+1);
        true = ValuesUtil.isArray(elt1);
        true = ValuesUtil.isArray(elt2);
        vallst = ValuesUtil.multMatrix(lhvals, rhvals);
      then
        (cache,ValuesUtil.makeArray(vallst),stOpt);

    //POW (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW(ty=_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.POWOP());
      then
        (cache,resVal,stOpt);

    //MUL (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL(ty=_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.MULOP());
      then
        (cache,resVal,stOpt);

    //DIV (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(ty=_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.DIVOP());
      then
        (cache,resVal,stOpt);

    //DIV (handle div by zero)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(ty =_), exp2 = rh),
        impl, stOpt, msg as Absyn.MSG(info = info),_)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        true = ValuesUtil.isZero(lhvVal);
        lhvStr = ExpressionDump.printExpStr(lh);
        rhvStr = ExpressionDump.printExpStr(rh);
        Error.addSourceMessage(Error.DIVISION_BY_ZERO, {lhvStr,rhvStr}, info);
      then
        fail();

    //ADD (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty=_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.ADDOP());
      then
        (cache,resVal,stOpt);

    //SUB (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB(ty=_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,lhvVal,stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,rhvVal,stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.SUBOP());
      then
        (cache,resVal,stOpt);

    //  unary minus of array 
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS_ARR(ty = _),exp = daeExp),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(arr,dims),stOpt) = ceval(cache,env, daeExp, impl, stOpt,msg,numIter+1);
        arr_1 = List.map(arr, ValuesUtil.valueNeg);
      then
        (cache,Values.ARRAY(arr_1,dims),stOpt);

    // unary minus of expression
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = daeExp),impl,stOpt,msg,_)
      equation
        (cache,v,stOpt) = ceval(cache,env, daeExp, impl, stOpt,msg,numIter+1);
        v_1 = ValuesUtil.valueNeg(v);
      then
        (cache,v_1,stOpt);

    // Logical operations false AND rhs
    // special case when leftside is false...
    // We allow errors on right hand side. and even if there is no errors, the performance
    // will be better.
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.AND(_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.BOOL(false),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
      then
        (cache,Values.BOOL(false),stOpt);

    // Logical lhs AND rhs
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.AND(_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.BOOL(lhvBool),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.BOOL(rhvBool),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        resBool = boolAnd(rhvBool, rhvBool);
      then
        (cache,Values.BOOL(resBool),stOpt);

    // true OR rhs 
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.BOOL(true),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
      then
        (cache,Values.BOOL(true),stOpt);

    // lhs OR rhs 
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,Values.BOOL(lhvBool),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        (cache,Values.BOOL(rhvBool),stOpt) = ceval(cache,env, rh, impl, stOpt,msg,numIter);
        resBool = boolOr(lhvBool, rhvBool);
      then
        (cache,Values.BOOL(resBool),stOpt);

    // Special case for a boolean expression like if( expression or ARRAY_IDEX_OUT_OF_BOUNDS_ERROR)
    // "expression" in this case we return the lh expression to be equall to
    // the previous c-code generation.
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,stOpt,msg,_)
      equation
        (cache,v as Values.BOOL(rhvBool),stOpt) = ceval(cache,env, lh, impl, stOpt,msg,numIter);
        failure((_,_,_) = ceval(cache,env, rh, impl, stOpt, msg, numIter));
      then
        (cache,v,stOpt);
    
    // NOT
    case (cache,env,DAE.LUNARY(operator = DAE.NOT(_),exp = e),impl,stOpt,msg,_)
      equation
        (cache,Values.BOOL(b),stOpt) = ceval(cache,env, e, impl, stOpt,msg,numIter+1);
        b_1 = boolNot(b);
      then
        (cache,Values.BOOL(b_1),stOpt);
    
    // relations <, >, <=, >=, <> 
    case (cache,env,DAE.RELATION(exp1 = lhs,operator = relop,exp2 = rhs),impl,stOpt,msg,_)
      equation
        (cache,lhs_1,stOpt) = ceval(cache,env, lhs, impl, stOpt,msg,numIter);
        (cache,rhs_1,stOpt) = ceval(cache,env, rhs, impl, stOpt,msg,numIter);
        v = cevalRelation(lhs_1, relop, rhs_1);
      then
        (cache,v,stOpt);
    
    case (cache, env, DAE.RANGE(ty = DAE.T_BOOL(varLst = _), start = start, step = NONE(),stop = stop), impl, stOpt, msg,_)
      equation
        (cache, Values.BOOL(bstart), stOpt) = ceval(cache, env, start, impl, stOpt,msg,numIter+1);
        (cache, Values.BOOL(bstop), stOpt) = ceval(cache, env, stop, impl, stOpt,msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRangeBool(bstart, bstop),
          ValuesUtil.makeBoolean);
      then
        (cache, ValuesUtil.makeArray(arr), stOpt);

    // range first:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.T_INTEGER(varLst = _),start = start,step = NONE(),stop = stop),impl,stOpt,msg,_)
      equation
        (cache,Values.INTEGER(start_1),stOpt) = ceval(cache,env, start, impl, stOpt,msg,numIter+1);
        (cache,Values.INTEGER(stop_1),stOpt) = ceval(cache,env, stop, impl, stOpt,msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRange(start_1, 1, stop_1), ValuesUtil.makeInteger);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);
    
    // range first:step:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.T_INTEGER(varLst = _),start = start,step = SOME(step),stop = stop),impl,stOpt,msg,_)
      equation
        (cache,Values.INTEGER(start_1),stOpt) = ceval(cache,env, start, impl, stOpt,msg,numIter+1);
        (cache,Values.INTEGER(step_1),stOpt) = ceval(cache,env, step, impl, stOpt,msg,numIter+1);
        (cache,Values.INTEGER(stop_1),stOpt) = ceval(cache,env, stop, impl, stOpt,msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRange(start_1, step_1, stop_1), ValuesUtil.makeInteger);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);
    
    // range first:last for enumerations.
    case (cache,env,DAE.RANGE(ty = t as DAE.T_ENUMERATION(path = _),start = start,step = NONE(),stop = stop),impl,stOpt,msg,_)
      equation
        (cache,Values.ENUM_LITERAL(index = start_1),stOpt) = ceval(cache,env, start, impl, stOpt,msg,numIter+1);
        (cache,Values.ENUM_LITERAL(index = stop_1),stOpt) = ceval(cache,env, stop, impl, stOpt,msg,numIter+1);
        arr = cevalRangeEnum(start_1, stop_1, t);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);

    // range first:last for reals
    case (cache,env,DAE.RANGE(ty = DAE.T_REAL(varLst = _),start = start,step = NONE(),stop = stop),impl,stOpt,msg,_)
      equation
        (cache,Values.REAL(realStart1),stOpt) = ceval(cache,env, start, impl, stOpt,msg,numIter+1);
        (cache,Values.REAL(realStop1),stOpt) = ceval(cache,env, stop, impl, stOpt,msg,numIter+1);
        // diff = realStop1 -. realStart1;
        realStep1 = intReal(1);
        arr = List.map(ExpressionSimplify.simplifyRangeReal(realStart1, realStep1, realStop1), ValuesUtil.makeReal);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);

    // range first:step:last for reals    
    case (cache,env,DAE.RANGE(ty = DAE.T_REAL(varLst = _),start = start,step = SOME(step),stop = stop),impl,stOpt,msg,_)
      equation
        (cache,Values.REAL(realStart1),stOpt) = ceval(cache,env, start, impl, stOpt,msg,numIter+1);
        (cache,Values.REAL(realStep1),stOpt) = ceval(cache,env, step, impl, stOpt,msg,numIter+1);
        (cache,Values.REAL(realStop1),stOpt) = ceval(cache,env, stop, impl, stOpt,msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRangeReal(realStart1, realStep1, realStop1), ValuesUtil.makeReal);
      then
        (cache,ValuesUtil.makeArray(arr),stOpt);

    // cast integer to real
    case (cache,env,DAE.CAST(ty = DAE.T_REAL(varLst = _),exp = e),impl,stOpt,msg,_)
      equation
        (cache,Values.INTEGER(i),stOpt) = ceval(cache,env, e, impl, stOpt,msg,numIter+1);
        r = intReal(i);
      then
        (cache,Values.REAL(r),stOpt);

    // cast real to integer
    case (cache,env,DAE.CAST(ty = DAE.T_INTEGER(varLst = _), exp = e),impl,stOpt,msg,_)
      equation
        (cache,Values.REAL(r),stOpt) = ceval(cache, env, e, impl, stOpt,msg,numIter+1);
        i = realInt(r);
      then
        (cache,Values.INTEGER(i),stOpt);
        
    // cast integer to enum
    case (cache,env,DAE.CAST(ty = DAE.T_ENUMERATION(path = path, names = n), exp = e), impl, stOpt, msg,_)
      equation
        (cache, Values.INTEGER(i), stOpt) = ceval(cache, env, e, impl, stOpt,msg,numIter+1);
        str = listNth(n, i - 1);
        path = Absyn.joinPaths(path, Absyn.IDENT(str));
      then
        (cache, Values.ENUM_LITERAL(path, i), stOpt);

    // cast integer array to real array
    case (cache,env,DAE.CAST(ty = DAE.T_ARRAY(ty = DAE.T_REAL(varLst = _)),exp = e),impl,stOpt,msg,_)
      equation
        (cache,v as Values.ARRAY(ivals,dims),stOpt) = ceval(cache,env, e, impl, stOpt,msg,numIter+1);
        rvals = ValuesUtil.typeConvert(DAE.T_INTEGER_DEFAULT, DAE.T_REAL_DEFAULT, ivals);
      then
        (cache,Values.ARRAY(rvals,dims),stOpt);

    // if expressions, select then branch if condition is true
    case (cache,env,DAE.IFEXP(expCond = cond,expThen = e1,expElse = e2),impl,stOpt,msg,_)
      equation
        (cache,Values.BOOL(true),stOpt) = ceval(cache, env, cond, impl, stOpt, msg, numIter+1) "Ifexp, true branch";
        (cache,v,stOpt) = ceval(cache,env, e1, impl, stOpt,msg,numIter);
      then
        (cache,v,stOpt);

    // if expressions, select else branch if condition is false
    case (cache,env,DAE.IFEXP(expCond = cond,expThen = e1,expElse = e2),impl,stOpt,msg,_)
      equation
        (cache,Values.BOOL(false),stOpt) = ceval(cache, env, cond, impl, stOpt,msg,numIter+1) "Ifexp, false branch" ;
        (cache,v,stOpt) = ceval(cache,env, e2, impl, stOpt,msg,numIter);
      then
        (cache,v,stOpt);

    // indexing for array[integer index] 
    case (cache,env,DAE.ASUB(exp = e,sub = ((e1 as DAE.ICONST(indx))::{})),impl,stOpt,msg,_)
      equation
        (cache,Values.ARRAY(vals,_),stOpt) = ceval(cache,env, e, impl, stOpt,msg,numIter+1) "asub" ;
        indx_1 = indx - 1;
        v = listNth(vals, indx_1);
      then
        (cache,v,stOpt);
    
    // indexing for array[subscripts]
    case (cache, env, DAE.ASUB(exp = e,sub = expl ), impl, stOpt, msg,_)
      equation
        (cache,Values.ARRAY(vals,dims),stOpt) = ceval(cache,env, e, impl, stOpt,msg,numIter+1);
        (cache,es_1,stOpt) = cevalList(cache,env, expl, impl, stOpt,msg,numIter);
        v = List.first(es_1);
        v = ValuesUtil.nthnthArrayelt(es_1,Values.ARRAY(vals,dims),v);
      then
        (cache,v,stOpt);

    // indexing for tuple[index]
    case (cache, env, DAE.TSUB(exp = e,ix = indx), impl, stOpt, msg,_)
      equation
        (cache,Values.TUPLE(vals),stOpt) = ceval(cache,env, e, impl, stOpt,msg,numIter+1);
        v = listGet(vals, indx);
      then
        (cache,v,stOpt);

    case (cache, env, DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = path, foldExp = foldExp, defaultValue = ov, exprType = ty), expr = daeExp, iterators = iterators), impl, stOpt, msg,_)
      equation
        env = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.forScopeName), NONE());
        (cache, valMatrix, names, dims, tys, stOpt) = cevalReductionIterators(cache, env, iterators, impl, stOpt,msg,numIter+1);
        // print("Before:\n");print(stringDelimitList(List.map1(List.mapList(valMatrix, ValuesUtil.valString), stringDelimitList, ","), "\n") +& "\n");
        valMatrix = Util.allCombinations(valMatrix,SOME(100000),Absyn.dummyInfo);
        // print("After:\n");print(stringDelimitList(List.map1(List.mapList(valMatrix, ValuesUtil.valString), stringDelimitList, ","), "\n") +& "\n");
        // print("Start cevalReduction: " +& Absyn.pathString(path) +& " " +& ValuesUtil.valString(startValue) +& " " +& ValuesUtil.valString(Values.TUPLE(vals)) +& " " +& ExpressionDump.printExpStr(daeExp) +& "\n");
        (cache, ov, stOpt) = cevalReduction(cache, env, path, ov, daeExp, ty, foldExp, names, listReverse(valMatrix), tys, impl, stOpt,msg,numIter+1);
        value = Util.getOptionOrDefault(ov, Values.META_FAIL());
        value = backpatchArrayReduction(path, value, dims);
      then (cache, value, stOpt);

    // ceval can fail and that is ok, caught by other rules... 
    case (cache,env,e,_,_,_,_) // Absyn.MSG())
      equation
        true = Flags.isSet(Flags.CEVAL);
        Debug.traceln("- Ceval.ceval failed: " +& ExpressionDump.printExpStr(e));
        Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
        // Debug.traceln("  Env:" +& Env.printEnvStr(env));
      then
        fail();
  end matchcontinue;
end cevalWork2;

public function cevalIfConstant
  "This function constant evaluates an expression if the expression is constant,
   or if the expression is a call of parameter constness whose return type
   contains unknown dimensions (in which case we need to determine the size of
   those dimensions)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input DAE.Properties inProp;
  input Boolean impl;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outCache, outExp, outProp) := 
  matchcontinue(inCache, inEnv, inExp, inProp, impl, inInfo)
    local 
        DAE.Exp e;
        Values.Value v;
        Env.Cache cache;
        DAE.Properties prop;
      DAE.Type tp;
        
    case (_, _, e as DAE.CALL(attr = DAE.CALL_ATTR(ty = DAE.T_ARRAY(dims = _))), 
        DAE.PROP(constFlag = DAE.C_PARAM()), _, _)
      equation
        (e, prop) = cevalWholedimRetCall(e, inCache, inEnv, inInfo, 0);
      then
        (inCache, e, prop);
    
    case (_, _, e, DAE.PROP(constFlag = DAE.C_PARAM(), type_ = tp), _, _) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.CEVAL_EQUATION);
      then
        (inCache, e, DAE.PROP(tp, DAE.C_VAR()));
    
    case (_, _, e, DAE.PROP(constFlag = DAE.C_CONST()), _, _)
      equation
        (cache, v, _) = ceval(inCache, inEnv, e, impl, NONE(), Absyn.NO_MSG(), 0);
        e = ValuesUtil.valueExp(v);
      then
        (cache, e, inProp);
    
    case (_, _, e, DAE.PROP_TUPLE(tupleConst = _), _, _)
      equation
        DAE.C_CONST() = Types.propAllConst(inProp);
        (cache, v, _) = ceval(inCache, inEnv, e, impl, NONE(), Absyn.NO_MSG(), 0);
        e = ValuesUtil.valueExp(v);
      then
        (cache, e, inProp);
    
    case (_, _, e, DAE.PROP_TUPLE(tupleConst = _), _, _) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.CEVAL_EQUATION);
        DAE.C_PARAM() = Types.propAllConst(inProp);
        print(" tuple non constant evaluation not implemented yet\n");
      then
        fail();
    
    case (_, _, _, _, _, _)
      equation
        // If we fail to evaluate, at least we should simplify the expression
        (e,_) = ExpressionSimplify.simplify1(inExp);
      then (inCache, e, inProp);
  
  end matchcontinue;
end cevalIfConstant;

protected function cevalWholedimRetCall
  "Helper function to cevalIfConstant. Determines the size of any unknown
   dimensions in a function calls return type."
  input DAE.Exp inExp;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  input Integer numIter;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outExp, outProp) := match(inExp, inCache, inEnv, inInfo, numIter)
    local
      DAE.Exp e;
      Absyn.Path p;
      list<DAE.Exp> el;
      Boolean t, b, isImpure;
      DAE.InlineType i;
      DAE.Dimensions dims;
      Values.Value v;
      DAE.Type cevalType, ty;
      DAE.TailCall tc;
           
     case (e as DAE.CALL(path = p, expLst = el, attr = DAE.CALL_ATTR(tuple_ = t, builtin = b, isImpure=isImpure,
           ty = DAE.T_ARRAY(dims = dims), inlineType = i, tailCall = tc)), _, _, _, _)
       equation
         true = Expression.arrayContainWholeDimension(dims);
         (_, v, _) = ceval(inCache, inEnv, e, true, NONE(), Absyn.MSG(inInfo), numIter+1);
         ty = Types.typeOfValue(v);
         cevalType = Types.simplifyType(ty);
       then
         (DAE.CALL(p, el, DAE.CALL_ATTR(cevalType, t, b, isImpure, i, tc)), DAE.PROP(ty, DAE.C_PARAM()));
  end match;
end cevalWholedimRetCall;

public function cevalRangeIfConstant
  "Constant evaluates the limits of a range if they are constant."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input DAE.Properties inProp;
  input Boolean impl;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache, outExp) := matchcontinue(inCache, inEnv, inExp, inProp, impl, inInfo)
    local
      DAE.Exp e1, e2;
      Option<DAE.Exp> e3;
      DAE.Type ty;
      Env.Cache cache;
      
    case (_, _, DAE.RANGE(ty = ty, start = e1, stop = e2, step = e3), _, _, _)
      equation
        (cache, e1, _) = cevalIfConstant(inCache, inEnv, e1, inProp, impl, inInfo);
        (cache, e2, _) = cevalIfConstant(cache, inEnv, e2, inProp, impl, inInfo);
      then
        (inCache, DAE.RANGE(ty, e1, e3, e2));
    else (inCache, inExp);
  end matchcontinue;
end cevalRangeIfConstant;

protected function cevalBuiltin
"Helper for ceval. Parts for builtin calls are moved here, for readability.
  See ceval for documentation.
  NOTE:    It\'s ok if cevalBuiltin fails. Just means the call was not a builtin function"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
  partial function HandlerFunc
    input Env.Cache inCache;
    input list<Env.Frame> inEnvFrameLst;
    input list<DAE.Exp> inExpExpLst;
    input Boolean inBoolean;
    input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
    input Absyn.Msg inMsg;
    input Integer numIter;
    output Env.Cache outCache;
    output Values.Value outValue;
    output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
  end HandlerFunc;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Values.Value v,newval;
      Option<GlobalScript.SymbolTable> st;
      list<Env.Frame> env;
      DAE.Exp exp,dim,e;
      Boolean impl;
      Absyn.Msg msg;
      HandlerFunc handler;
      String id;
      list<DAE.Exp> args,expl;
      list<Values.Value> vallst;
      Absyn.Path funcpath,path;
      Env.Cache cache;

    case (cache,env,DAE.SIZE(exp = exp,sz = SOME(dim)),impl,st,msg,_)
      equation
        (cache,v,st) = cevalBuiltinSize(cache,env, exp, dim, impl, st, msg, numIter+1) "Handle size separately" ;
      then
        (cache,v,st);
    case (cache,env,DAE.SIZE(exp = exp,sz = NONE()),impl,st,msg,_)
      equation
        (cache,v,st) = cevalBuiltinSizeMatrix(cache,env, exp, impl, st,msg,numIter+1);
      then
        (cache,v,st);
    case (cache,env,DAE.CALL(path = path,expLst = args,attr = DAE.CALL_ATTR(builtin = true)),impl,st,msg,_)
      equation
        id = Absyn.pathString(path);
        handler = cevalBuiltinHandler(id);
        (cache,v,st) = handler(cache, env, args, impl, st,msg,numIter+1);
      then
        (cache,v,st);
    case (cache,env,(e as DAE.CALL(path = funcpath,expLst = expl,attr = DAE.CALL_ATTR(builtin = true))),impl,(st as NONE()),msg,_)
      equation
        (cache,vallst,st) = cevalList(cache, env, expl, impl, st,msg,numIter);
        (cache,newval,st) = CevalScript.cevalCallFunction(cache, env, e, vallst, impl, st,msg,numIter+1);
      then
        (cache,newval,st);
  end matchcontinue;
end cevalBuiltin;

protected function cevalBuiltinHandler
"This function dispatches builtin functions and operators to a dedicated
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
    input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
    input Absyn.Msg inMsg;
    input Integer numIter;
    output Env.Cache outCache;
    output Values.Value outValue;
    output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
  end HandlerFunc;
algorithm
  handler := match (inIdent)
    local
      String id;
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
    case "integer" then cevalBuiltinInteger;
    case "boolean" then cevalBuiltinBoolean;
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
    case "Integer" then cevalBuiltinIntegerEnumeration;
    case "rooted" then cevalBuiltinRooted; //
    case "cross" then cevalBuiltinCross;
    case "fill" then cevalBuiltinFill;
    case "Modelica.Utilities.Strings.substring" then cevalBuiltinSubstring;
    case "print" then cevalBuiltinPrint;
    // MetaModelica type conversions
    case "intString" equation true = Config.acceptMetaModelicaGrammar(); then cevalIntString;
    case "realString" equation true = Config.acceptMetaModelicaGrammar(); then cevalRealString;
    case "stringCharInt" equation true = Config.acceptMetaModelicaGrammar(); then cevalStringCharInt;
    case "intStringChar" equation true = Config.acceptMetaModelicaGrammar(); then cevalIntStringChar;
    case "stringLength" equation true = Config.acceptMetaModelicaGrammar(); then cevalStringLength;
    case "stringInt" equation true = Config.acceptMetaModelicaGrammar(); then cevalStringInt;
    case "stringListStringChar" equation true = Config.acceptMetaModelicaGrammar(); then cevalStringListStringChar;
    case "listStringCharString" equation true = Config.acceptMetaModelicaGrammar(); then cevalListStringCharString;
    case "stringAppendList" equation true = Config.acceptMetaModelicaGrammar(); then cevalStringAppendList;
    case "stringDelimitList" equation true = Config.acceptMetaModelicaGrammar(); then cevalStringDelimitList;
    case "listLength" equation true = Config.acceptMetaModelicaGrammar(); then cevalListLength;
    case "listAppend" equation true = Config.acceptMetaModelicaGrammar(); then cevalListAppend;
    case "listReverse" equation true = Config.acceptMetaModelicaGrammar(); then cevalListReverse;
    case "listHead" equation true = Config.acceptMetaModelicaGrammar(); then cevalListFirst;
    case "listRest" equation true = Config.acceptMetaModelicaGrammar(); then cevalListRest;
    case "anyString" equation true = Config.acceptMetaModelicaGrammar(); then cevalAnyString;
    case "numBits" then cevalNumBits;
    case "integerMax" then cevalIntegerMax;
    case "getLoadedLibraries" then cevalGetLoadedLibraries;

    //case "semiLinear" then cevalBuiltinSemiLinear;
    //case "delay" then cevalBuiltinDelay;
    case id
      equation
        true = Flags.isSet(Flags.CEVAL);
        Debug.traceln("No cevalBuiltinHandler found for " +& id);
      then
        fail();
  end match;
end cevalBuiltinHandler;




public function cevalKnownExternalFuncs "Evaluates external functions that are known, e.g. all math functions."
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path funcpath;
  input list<Values.Value> vals;
  input Absyn.Msg msg;
  output Env.Cache outCache;
  output Values.Value res;
protected
  SCode.Element cdef;
  list<Env.Frame> env_1;
  String fid,id;
  Option<String> oid;
  Option<SCode.ExternalDecl> extdecl;
  Option<String> lan;
  Option<Absyn.ComponentRef> out;
  list<Absyn.Exp> args;
  SCode.FunctionRestriction funcRest;
algorithm
  (outCache,cdef,env_1) := Lookup.lookupClass(inCache,env, funcpath, false);
  SCode.CLASS(name=fid,restriction = SCode.R_FUNCTION(funcRest), classDef=SCode.PARTS(externalDecl=extdecl)) := cdef;
  SCode.FR_EXTERNAL_FUNCTION(_) := funcRest;
  SOME(SCode.EXTERNALDECL(oid,lan,out,args,_)) := extdecl;
  // oid=NONE() is more safe, but most of the functions are declared is a certain way =/
  id := Util.getOptionOrDefault(oid,fid);
  isKnownExternalFunc(id);
  res := cevalKnownExternalFuncs2(id, vals, msg);
end cevalKnownExternalFuncs;

public function isKnownExternalFunc "\"known\", i.e. no compilation required."
  input String id;
algorithm
  _:=  match (id)
    case ("acos") then ();
    case ("asin") then ();
    case ("atan") then ();
    case ("atan2") then ();
    case ("cos") then ();
    case ("cosh") then ();
    case ("exp") then ();
    case ("log") then ();
    case ("log10") then ();
    case ("sin") then ();
    case ("sinh") then ();
    case ("tan") then ();
    case ("tanh") then ();
    case ("print") then ();
    case ("ModelicaStreams_closeFile") then ();
    case ("ModelicaStrings_substring") then ();
    case ("ModelicaStrings_length") then ();
    case ("ModelicaInternal_print") then ();
    case ("ModelicaInternal_countLines") then ();
    case ("ModelicaInternal_readLine") then ();
    case ("ModelicaInternal_stat") then ();
    case ("ModelicaInternal_fullPathName") then ();
    case ("ModelicaStrings_scanReal") then ();
    case ("ModelicaStrings_skipWhiteSpace") then ();
    case ("ModelicaError") then ();
    case ("OpenModelica_regex") then ();
  end match;
end isKnownExternalFunc;

protected function cevalKnownExternalFuncs2 "Helper function to cevalKnownExternalFuncs, does the evaluation."
  input String id;
  input list<Values.Value> inValuesValueLst;
  input Absyn.Msg inMsg;
  output Values.Value outValue;
algorithm
  outValue := match (id,inValuesValueLst,inMsg)
    local 
      Real rv_1,rv,rv1,rv2,sv,cv,r;
      String str,fileName,re;
      Integer start, stop, i, lineNumber, n;
      Boolean b, extended, insensitive;
      list<String> strs;
      list<Values.Value> vals;
      Values.Value v;
      Absyn.Path p;
      
    case ("acos",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realAcos(rv);
      then
        Values.REAL(rv_1);
    case ("asin",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realAsin(rv);
      then
        Values.REAL(rv_1);
    case ("atan",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realAtan(rv);
      then
        Values.REAL(rv_1);
    case ("atan2",{Values.REAL(real = rv1),Values.REAL(real = rv2)},_)
      equation
        rv_1 = realAtan2(rv1, rv2);
      then
        Values.REAL(rv_1);
    case ("cos",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realCos(rv);
      then
        Values.REAL(rv_1);
    case ("cosh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realCosh(rv);
      then
        Values.REAL(rv_1);
    case ("exp",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realExp(rv);
      then
        Values.REAL(rv_1);
    case ("log",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realLn(rv);
      then
        Values.REAL(rv_1);
    case ("log10",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realLog10(rv);
      then
        Values.REAL(rv_1);
    case ("sin",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realSin(rv);
      then
        Values.REAL(rv_1);
    case ("sinh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realSinh(rv);
      then
        Values.REAL(rv_1);
    case ("tan",{Values.REAL(real = rv)},_)
      equation
        sv = realSin(rv);
        cv = realCos(rv);
        rv_1 = sv/. cv;
      then
        Values.REAL(rv_1);
    case ("tanh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = realTanh(rv);
      then
        Values.REAL(rv_1);
    
    case ("ModelicaStrings_substring",
          {
           Values.STRING(string = str),
           Values.INTEGER(integer = start),
           Values.INTEGER(integer = stop)
          },_)
      equation
        str = System.substring(str, start, stop);
      then
        Values.STRING(str);
    case ("ModelicaStrings_length",{Values.STRING(str)},_)
      equation
        i = stringLength(str);
      then Values.INTEGER(i);
    case ("print",{Values.STRING(str)},_)
      equation
        print(str);
      then Values.NORETCALL();
    case ("ModelicaStreams_closeFile",{Values.STRING(fileName)},_)
      equation
        ModelicaExternalC.Streams_close(fileName);
      then Values.NORETCALL();
    case ("ModelicaInternal_print",{Values.STRING(str),Values.STRING(fileName)},_)
      equation
        ModelicaExternalC.Streams_print(str,fileName);
      then Values.NORETCALL();
    case ("ModelicaInternal_countLines",{Values.STRING(fileName)},_)
      equation
        i = ModelicaExternalC.Streams_countLines(fileName);
      then Values.INTEGER(i);
    case ("ModelicaInternal_readLine",{Values.STRING(fileName),Values.INTEGER(lineNumber)},_)
      equation
        (str,b) = ModelicaExternalC.Streams_readLine(fileName,lineNumber);
      then Values.TUPLE({Values.STRING(str),Values.BOOL(b)});
    case ("ModelicaInternal_fullPathName",{Values.STRING(fileName)},_)
      equation
        fileName = ModelicaExternalC.File_fullPathName(fileName);
      then Values.STRING(fileName);
    case ("ModelicaInternal_stat",{Values.STRING(str)},_)
      equation
        i = ModelicaExternalC.File_stat(str);
        str = listGet({"NoFile", "RegularFile", "Directory", "SpecialFile"}, i);
        p = Absyn.stringListPath({"OpenModelica","Scripting","Internal","FileType",str});
        v = Values.ENUM_LITERAL(p,i);
      then v;
        
    case ("ModelicaStrings_scanReal",{Values.STRING(str),Values.INTEGER(i),Values.BOOL(b)},_)
      equation
        (i,r) = ModelicaExternalC.Strings_advanced_scanReal(str,i,b);
      then Values.TUPLE({Values.INTEGER(i),Values.REAL(r)});

    case ("ModelicaInternal_skipWhiteSpace",{Values.STRING(str),Values.INTEGER(i)},_)
      equation
        i = ModelicaExternalC.Strings_advanced_skipWhiteSpace(str,i);
      then Values.INTEGER(i);
    
    case ("OpenModelica_regex",{Values.STRING(str),Values.STRING(re),Values.INTEGER(i),Values.BOOL(extended),Values.BOOL(insensitive)},_)
      equation
        (n,strs) = System.regex(str,re,i,extended,insensitive);
        vals = List.map(strs,ValuesUtil.makeString);
        v = Values.ARRAY(vals,{i});
      then Values.TUPLE({Values.INTEGER(n),v});

  end match;
end cevalKnownExternalFuncs2;

protected function cevalMatrixElt "Evaluates the expression of a matrix constructor, e.g. {1,2;3,4}"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<DAE.Exp>> inTplExpExpBooleanLstLst "matrix constr. elts";
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
algorithm
  (outCache,outValuesValueLst) :=
  match (inCache,inEnv,inTplExpExpBooleanLstLst,inBoolean,inMsg,numIter)
    local
      Values.Value v;
      list<Values.Value> vl;
      list<Env.Frame> env;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> expll;
      Boolean impl;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,(expl :: expll),impl,msg,_)
      equation
        (cache,vl,_) = cevalList(cache,env,expl,impl,NONE(),msg,numIter);
        v = ValuesUtil.makeArray(vl);
        (cache,vl)= cevalMatrixElt(cache,env, expll, impl,msg,numIter);
      then
        (cache,v :: vl);
    case (cache,_,{},_,msg,_) then (cache,{});
  end match;
end cevalMatrixElt;

protected function cevalBuiltinSize "Evaluates the size operator."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input DAE.Exp inDimExp;
  input Boolean inBoolean4;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption5;
  input Absyn.Msg inMsg6;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv1,inExp2,inDimExp,inBoolean4,inInteractiveInteractiveSymbolTableOption5,inMsg6,numIter)
    local
      DAE.Attributes attr;
      DAE.Type tp;
      DAE.Binding bind,binding;
      list<Integer> sizelst,adims;
      Integer dim,dim_1,dimv,len,i;
      Option<GlobalScript.SymbolTable> st_1,st;
      list<Env.Frame> env;
      DAE.ComponentRef cr;
      Boolean impl,bl;
      Absyn.Msg msg;
      DAE.Dimensions dims;
      Values.Value v2,val;
      DAE.Type crtp,expTp;
      DAE.Exp exp,e,dimExp;
      String cr_str,dim_str,size_str,expstr;
      list<DAE.Exp> es;
      Env.Cache cache;
      list<list<DAE.Exp>> mat;
      Absyn.Info info;
      DAE.Dimension ddim;
    
    case (cache,_,DAE.MATRIX(matrix=mat),DAE.ICONST(1),_,st,_,_)
      equation
        i = listLength(mat);
      then
        (cache,Values.INTEGER(i),st);
    
    case (cache,_,DAE.MATRIX(matrix=mat),DAE.ICONST(2),_,st,_,_)
      equation
        i = listLength(List.first(mat));
      then
        (cache,Values.INTEGER(i),st);
    
    case (cache,env,DAE.MATRIX(matrix=mat),DAE.ICONST(dim),impl,st,msg,_)
      equation
        bl = (dim>2);
        true = bl;
        dim_1 = dim-2;
        e = List.first(List.first(mat));
        (cache,Values.INTEGER(i),st_1)=cevalBuiltinSize(cache,env,e,DAE.ICONST(dim_1),impl,st,msg,numIter+1);
      then
        (cache,Values.INTEGER(i),st);
    
    case (cache,env,DAE.CREF(componentRef = cr),dimExp,impl,st,msg,_)
      equation
        (cache,attr,tp,bind,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions known, always ceval" ;
        true = Types.dimensionsKnown(tp);
        (sizelst as (_ :: _)) = Types.getDimensionSizes(tp);
        (cache,Values.INTEGER(dim),st_1) = ceval(cache, env, dimExp, impl, st,msg,numIter+1);
        dim_1 = dim - 1;
        i = listNth(sizelst, dim_1);
      then
        (cache,Values.INTEGER(i),st_1);
    
    case (cache,env,DAE.CREF(componentRef = cr,ty = expTp),dimExp,(impl as false),st,msg,_)
      equation
        (cache,dims) = Inst.elabComponentArraydimFromEnv(cache,env,cr,Absyn.dummyInfo) 
        "If component not instantiated yet, recursive definition.
         For example,
           Real x[:](min=fill(1.0,size(x,1))) = {1.0}
         When size(x,1) should be determined, x must be instantiated, but
         that is not done yet. Solution: Examine Element to find modifier
         which will determine dimension size.";
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache, env, dimExp, impl, st,msg,numIter+1);
        ddim = listGet(dims, dimv);
        (cache, v2, st_1) = cevalDimension(cache, env, ddim, impl, st,msg,numIter+1);
      then
        (cache,v2,st_1);
    
    case (cache,env,DAE.CREF(componentRef = cr),dimExp,false,st,
        Absyn.MSG(info = info),_)
      equation
        (cache,attr,tp,bind,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr) "If dimensions not known and impl=false, error message";
        false = Types.dimensionsKnown(tp);
        cr_str = ComponentReference.printComponentRefStr(cr);
        dim_str = ExpressionDump.printExpStr(dimExp);
        size_str = stringAppendList({"size(",cr_str,", ",dim_str,")"});
        Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {size_str}, info);
      then
        fail();
    
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dimExp,
        (impl as false),st,Absyn.MSG(info = info),_)
      equation
        (cache,attr,tp,DAE.UNBOUND(),_,_,_,_,_) = Lookup.lookupVar(cache, env, cr) "For crefs without value binding" ;
        expstr = ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.UNBOUND_VALUE, {expstr}, info);
      then
        fail();
    
    // For crefs with value binding e.g. size(x,1) when Real x[:]=fill(0,1);
    case (cache,env,(exp as DAE.CREF(componentRef = cr,ty = crtp)),dimExp,impl,st,msg,_)
      equation 
        (cache,attr,tp,binding,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr)  ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env,dimExp,impl,st,msg,numIter+1);
        (cache,val) = cevalCrefBinding(cache,env, cr, binding, impl,msg,numIter+1);
        v2 = cevalBuiltinSize2(val, dimv);
      then
        (cache,v2,st_1);
    
    case (cache,env,DAE.ARRAY(array = (exp :: es)),dimExp,impl,st,msg,_)
      equation
        expTp = Expression.typeof(exp) "Special case for array expressions with nonconstant
                                        values For now: only arrays of scalar elements:
                                        TODO generalize to arbitrary dimensions";
        true = Expression.typeBuiltin(expTp);
        (cache,Values.INTEGER(1),st_1) = ceval(cache, env, dimExp, impl, st,msg,numIter+1);
        len = listLength((exp :: es));
      then
        (cache,Values.INTEGER(len),st_1);

    // adrpo 2009-06-08: it doen't need to be a builtin type as long as the dimension is an integer!
    case (cache,env,DAE.ARRAY(array = (exp :: es)),dimExp,impl,st,msg,_)
      equation
        expTp = Expression.typeof(exp) "Special case for array expressions with nonconstant values
                                        For now: only arrays of scalar elements:
                                        TODO generalize to arbitrary dimensions" ;
        false = Expression.typeBuiltin(expTp);
        (cache,Values.INTEGER(1),st_1) = ceval(cache,env, dimExp, impl, st,msg,numIter+1);
        len = listLength((exp :: es));
      then
        (cache,Values.INTEGER(len),st_1);

    // For expressions with value binding that can not determine type
    // e.g. size(x,2) when Real x[:,:]=fill(0.0,0,2); empty array with second dimension == 2, no way of 
    // knowing that from the value. Must investigate the expression itself.
    case (cache,env,exp,dimExp,impl,st,msg,_)
      equation
        (cache,Values.ARRAY({},adims),st_1) = ceval(cache,env,exp,impl,st,msg,numIter+1) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env,dimExp,impl,st,msg,numIter+1);
        i = listNth(adims,dimv-1);
      then
        (cache,Values.INTEGER(i),st_1);

    case (cache,env,exp,dimExp,impl,st,msg,_)
      equation
        (cache,val,st_1) = ceval(cache, env,exp,impl,st,msg,numIter+1) "try to ceval expression, for constant expressions" ;
        (cache,Values.INTEGER(dimv),st_1) = ceval(cache,env,dimExp,impl,st,msg,numIter+1);
        v2 = cevalBuiltinSize2(val, dimv);
      then
        (cache,v2,st_1);
    
    case (cache,env,exp,dimExp,impl,st,Absyn.MSG(info = _),_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Print.printErrorBuf("#-- Ceval.cevalBuiltinSize failed: ");
        expstr = ExpressionDump.printExpStr(exp);
        Print.printErrorBuf(expstr);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize;

protected function cevalBuiltinSize2 "Helper function to cevalBuiltinSize"
  input Values.Value inValue;
  input Integer inInteger;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue,inInteger)
    local
      Integer dim,ind_1,ind;
      list<Values.Value> lst;
      Values.Value l;
      Values.Value dimVal;
    
    case (Values.ARRAY(valueLst = lst),1)
      equation
        dim = listLength(lst);
      then
        Values.INTEGER(dim);
    
    case (Values.ARRAY(valueLst = (l :: lst)),ind)
      equation
        ind_1 = ind - 1;
        dimVal = cevalBuiltinSize2(l, ind_1);
      then
        dimVal;
    
    case (_,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "- Ceval.cevalBuiltinSize2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize2;

protected function cevalBuiltinSize3 "author: PA
  Helper function to cevalBuiltinSize.
  Used when recursive definition (attribute modifiers using size) is used."
  input DAE.Dimensions inInstDimExpLst;
  input Integer inInteger;
  output Values.Value outValue;
algorithm
  outValue:=
  match (inInstDimExpLst,inInteger)
    local
      Integer n_1,v,n;
      DAE.Dimensions dims;
    case (dims,n)
      equation
        n_1 = n - 1;
        DAE.DIM_INTEGER(v) = listNth(dims, n_1);
      then
        Values.INTEGER(v);
  end match;
end cevalBuiltinSize3;

protected function cevalBuiltinAbs "author: LP
  Evaluates the abs operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Integer iv;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        rv_1 = realAbs(rv);
      then
        (cache,Values.REAL(rv_1),st);
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(iv),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        iv = intAbs(iv);
      then
        (cache,Values.INTEGER(iv),st);
  end matchcontinue;
end cevalBuiltinAbs;

protected function cevalBuiltinSign "author: PA
  Evaluates the sign operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv;
      Boolean b1,b2,b3,impl;
      list<Env.Frame> env;
      DAE.Exp exp;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Integer iv,iv_1;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        b1 = (rv >. 0.0);
        b2 = (rv <. 0.0);
        b3 = (rv ==. 0.0);
        {(_,iv_1)} = List.select({(b1,1),(b2,-1),(b3,0)}, Util.tuple21);
      then
        (cache,Values.INTEGER(iv_1),st);
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(iv),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        b1 = (iv > 0);
        b2 = (iv < 0);
        b3 = (iv == 0);
        {(_,iv_1)} = List.select({(b1,1),(b2,-1),(b3,0)}, Util.tuple21);
      then
        (cache,Values.INTEGER(iv_1),st);
  end matchcontinue;
end cevalBuiltinSign;

protected function cevalBuiltinExp "author: PA
  Evaluates the exp function"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        rv_1 = realExp(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinExp;

protected function cevalBuiltinNoevent "author: PA
  Evaluates the noEvent operator. During constant evaluation events are not
  considered, so evaluation will simply remove the operator and evaluate the
  operand."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Values.Value v;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,v,_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
      then
        (cache,v,st);
  end match;
end cevalBuiltinNoevent;

protected function cevalBuiltinCardinality "author: PA
  Evaluates the cardinality operator. The cardinality of a connector
  instance is its number of (inside and outside) connections, i.e.
  number of occurences in connect equations."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
protected
  DAE.Exp exp;
algorithm
  outCache := inCache;
  outST := inST;
  {exp} := inExpExpLst;
  outValue := cevalCardinality(exp, inEnv);
end cevalBuiltinCardinality;

protected function cevalCardinality "author: PA
  counts the number of connect occurences of the
  component ref in equations in current scope."
  input DAE.Exp inExp;
  input Env.Env inEnv;
  output Values.Value outValue;
algorithm
  outValue := match(inExp, inEnv)
    local
      Env.Env env;
      Integer res, dim;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<Values.Value> vals;
      Env.CSetsType clst;

    case (DAE.CREF(componentRef = cr), env)
      equation
        env = Env.stripForLoopScope(env);
        Env.FRAME(connectionSet = clst)::_ = env;
        res = cevalCardinality2(cr, clst, env, 0);
      then
        Values.INTEGER(res);

    case (DAE.ARRAY(array = expl), _)
      equation
        vals = List.map1(expl, cevalCardinality, inEnv);
        dim = listLength(vals);
      then
        Values.ARRAY(vals, {dim});

  end match;
end cevalCardinality;

protected function cevalCardinality2 
  input DAE.ComponentRef inCref;
  input Env.CSetsType inCSets;
  input Env.Env inEnv;
  input Integer inStartValue;
  output Integer outValue;
algorithm
  outValue := match(inCref, inCSets, inEnv, inStartValue)
    local
      Env.Env env;
      list<DAE.ComponentRef> cr_lst,cr_lst2,cr_totlst,crs;
      Integer res;
      DAE.ComponentRef cr;
      DAE.ComponentRef prefix,currentPrefix;
      Absyn.Ident currentPrefixIdent;
      Env.CSetsType rest;

    case (cr, {}, env, _) then inStartValue;

    case (cr, (crs,prefix)::rest, env, _)
      equation
        // strip the subs from the cref!
        cr = ComponentReference.crefStripSubs(cr);
        
        cr_lst = List.select1(crs, ComponentReference.crefContainedIn, cr);
        currentPrefixIdent = ComponentReference.crefLastIdent(prefix);
        currentPrefix = ComponentReference.makeCrefIdent(currentPrefixIdent,DAE.T_UNKNOWN_DEFAULT,{});
         //  Select connect references that has cr as suffix and correct Prefix.
        cr_lst = List.select1r(cr_lst, ComponentReference.crefPrefixOf, currentPrefix);

        // Select connect references that are identifiers (inside connectors)
        cr_lst2 = List.select(crs,ComponentReference.crefIsIdent);
        cr_lst2 = List.select1(cr_lst2,ComponentReference.crefEqual,cr);

        // adrpo: do not do union! 
        // see bug: https://trac.openmodelica.org/OpenModelica/ticket/2062
        cr_totlst = List.unionOnTrue(listAppend(cr_lst,cr_lst2),{},ComponentReference.crefEqual);
        res = listLength(cr_totlst);
        /*print("inFrame :");print(Env.printEnvPathStr(env));print("\n");
        print("cardinality(");print(ComponentReference.printComponentRefStr(cr));print(")=");print(intString(res));
        print("\nicrefs =");print(stringDelimitList(List.map(crs,ComponentReference.printComponentRefStr),","));
        print("\ncrefs =");print(stringDelimitList(List.map(cr_totlst,ComponentReference.printComponentRefStr),","));
        print("\n");
         print("prefix =");print(ComponentReference.printComponentRefStr(prefix));print("\n");*/
       //  print("env:");print(Env.printEnvStr(env));
       res = cevalCardinality2(cr, rest, inEnv, res + inStartValue);
      then
       res;

  end match;
end cevalCardinality2;

protected function cevalBuiltinCat "author: PA
  Evaluates the cat operator, for matrix concatenation."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Integer dim_int;
      list<Values.Value> mat_lst;
      Values.Value v;
      list<Env.Frame> env;
      DAE.Exp dim;
      list<DAE.Exp> matrices;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    
    case (cache,env,(dim :: matrices),impl,st,msg,_)
      equation
        (cache,Values.INTEGER(dim_int),_) = ceval(cache,env,dim,impl,st,msg,numIter+1);
        (cache,mat_lst,st) = cevalList(cache,env, matrices, impl, st,msg,numIter);
        v = cevalCat(mat_lst, dim_int);
      then
        (cache,v,st);
  end match;
end cevalBuiltinCat;

protected function cevalBuiltinIdentity "author: PA
  Evaluates the identity operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Integer dim_int,dim_int_1;
      list<DAE.Exp> expl;
      list<Values.Value> retExp;
      list<Env.Frame> env;
      DAE.Exp dim;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
       Env.Cache cache;
    
    case (cache,env,{dim},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(dim_int),_) = ceval(cache,env,dim,impl,st,msg,numIter+1);
        dim_int_1 = dim_int + 1;
        expl = List.fill(DAE.ICONST(1), dim_int);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, DAE.ARRAY(DAE.T_INTEGER_DEFAULT,true,expl), impl, st, dim_int_1,
          1, {},msg,numIter+1);
      then
        (cache,ValuesUtil.makeArray(retExp),st);
  end match;
end cevalBuiltinIdentity;

protected function cevalBuiltinPromote "author: PA
  Evaluates the internal promote operator, for promotion of arrays"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Values.Value arr_val,res;
      Integer dim_val;
      list<Env.Frame> env;
      DAE.Exp arr,dim;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    
    case (cache,env,{arr,dim},impl,st,msg,_)
      equation
        (cache,arr_val,_) = ceval(cache,env, arr, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(dim_val),_) = ceval(cache,env, dim, impl, st,msg,numIter+1);
        res = cevalBuiltinPromote2(arr_val, dim_val);
      then
        (cache,res,st);
  end match;
end cevalBuiltinPromote;

protected function cevalBuiltinPromote2 "Helper function to cevalBuiltinPromote"
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
        (vs_1 as (Values.ARRAY(dimLst = il)::_)) = List.map1(vs, cevalBuiltinPromote2, n_1);
      then
        Values.ARRAY(vs_1,i::il);
    case (_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Ceval.cevalBuiltinPromote2 failed");
      then fail();
  end matchcontinue;
end cevalBuiltinPromote2;

protected function cevalBuiltinSubstring "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e).
  TODO: Also evaluate String(r, significantDigits=d), and String(r, format=s)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp str_exp, start_exp, stop_exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Integer start, stop;
    
    case (cache,env,{str_exp, start_exp, stop_exp},impl,st,msg,_)
      equation
        (cache,Values.STRING(str),_) = ceval(cache,env, str_exp, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(start),_) = ceval(cache,env, start_exp, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(stop),_) = ceval(cache,env, stop_exp, impl, st,msg,numIter+1);
        str = System.substring(str, start, stop);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalBuiltinSubstring;

protected function cevalBuiltinString "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e).
  TODO: Also evaluate String(r, significantDigits=d), and String(r, format=s)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp, len_exp, justified_exp, sig_dig;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str,format;
      Integer i,len,sig; Real r; Boolean b, left_just;
      Absyn.Path p;
    
    case (cache,env,{exp, len_exp, justified_exp},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(i),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        str = intString(i);
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, st,msg,numIter+1);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,{exp, len_exp, justified_exp, sig_dig},impl,st,msg,_)
      equation
        (cache,Values.REAL(r),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(len),_) = ceval(cache,env, len_exp, impl, st,msg,numIter+1);
        (cache,Values.BOOL(left_just),_) = ceval(cache,env, justified_exp, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(sig),_) = ceval(cache,env, sig_dig, impl, st,msg,numIter+1);
        format = "%"+&Util.if_(left_just,"-","") +& intString(len) +& "." +& intString(sig) +& "g";
        str = System.snprintff(format,len+20,r);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,{exp, len_exp, justified_exp},impl,st,msg,_)
      equation
        (cache,Values.BOOL(b),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        str = boolString(b);
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, st,msg,numIter+1);
      then
        (cache,Values.STRING(str),st);
    
    case (cache,env,{exp, len_exp, justified_exp},impl,st,msg,_)
      equation
        (cache,Values.ENUM_LITERAL(name = p),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        str = Absyn.pathLastIdent(p);
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, st,msg,numIter+1);
      then
        (cache,Values.STRING(str),st);
    
  end matchcontinue;
end cevalBuiltinString;

protected function cevalBuiltinStringFormat
  "This function formats a string by using the minimumLength and leftJustified
  arguments to the String function."  
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inString;
  input DAE.Exp lengthExp;
  input DAE.Exp justifiedExp;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output String outString;
algorithm
  (outCache, outString) := match(inCache, inEnv, inString, lengthExp,
      justifiedExp, inBoolean, inST, inMsg, numIter)
    local
      Env.Cache cache;
      Integer min_length;
      Boolean left_justified;
      String str;
    case (cache, _, _, _, _, _, _, _, _)
      equation
        (cache, Values.INTEGER(integer = min_length), _) = 
          ceval(cache, inEnv, lengthExp, inBoolean, inST,inMsg,numIter+1);
        (cache, Values.BOOL(boolean = left_justified), _) = 
          ceval(cache, inEnv, justifiedExp, inBoolean, inST,inMsg,numIter+1);
        str = ExpressionSimplify.cevalBuiltinStringFormat(inString, stringLength(inString), min_length, left_justified);
      then
        (cache, str);
  end match;
end cevalBuiltinStringFormat;

protected function cevalBuiltinPrint
  "Prints a String to stdout"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        print(str);
      then
        (cache,Values.NORETCALL(),st);
  end match;
end cevalBuiltinPrint;

protected function cevalIntString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(i),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        str = intString(i);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalIntString;

protected function cevalRealString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Real r;
      Values.Value v;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,v,st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        Values.REAL(r) = v;
        str = realString(r);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalRealString;

protected function cevalStringCharInt
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.STRING(str),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        i = stringCharInt(str);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalStringCharInt;

protected function cevalIntStringChar
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(i),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        str = intStringChar(i);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalIntStringChar;

protected function cevalStringInt
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        i = stringInt(str);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalStringInt;


protected function cevalStringLength
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        i = stringLength(str);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalStringLength;

protected function cevalStringListStringChar
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.STRING(str),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        chList = stringListStringChar(str);
        valList = List.map(chList, generateValueString);
      then
        (cache,Values.LIST(valList),st);
  end match;
end cevalStringListStringChar;

protected function generateValueString
  input String str;
  output Values.Value val;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  val := Values.STRING(str);
end generateValueString;

protected function cevalListStringCharString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp, impl,st,msg,numIter+1);
        // Note that the RML version of the function has a weird name, but is also not implemented yet!
        // The work-around is to check that each String has length 1 and append all the Strings together
        // WARNING: This can be very, very slow for long lists - it grows as O(n^2)
        // TODO: When implemented, use listStringCharString (OMC name) or stringCharListString (RML name) directly
        chList = List.map(valList, extractValueStringChar);
        str = stringAppendList(chList);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalListStringCharString;

protected function cevalStringAppendList
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        chList = List.map(valList, ValuesUtil.extractValueString);
        str = stringAppendList(chList);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalStringAppendList;

protected function cevalStringDelimitList
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.STRING(str),st) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        chList = List.map(valList, ValuesUtil.extractValueString);
        str = stringDelimitList(chList,str);
      then
        (cache,Values.STRING(str),st);
  end match;
end cevalStringDelimitList;

protected function cevalListLength
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Integer i;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.LIST(valList),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        i = listLength(valList);
      then
        (cache,Values.INTEGER(i),st);
  end match;
end cevalListLength;

protected function cevalListAppend
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      list<Values.Value> valList,valList1,valList2;
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.LIST(valList1),st) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.LIST(valList2),st) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        valList = listAppend(valList1, valList2);
      then
        (cache,Values.LIST(valList),st);
  end match;
end cevalListAppend;

protected function cevalListReverse
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      list<Values.Value> valList,valList1;
    case (cache,env,{exp1},impl,st,msg,_)
      equation
        (cache,Values.LIST(valList1),st) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        valList = listReverse(valList1);
      then
        (cache,Values.LIST(valList),st);
  end match;
end cevalListReverse;

protected function cevalListRest
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      list<Values.Value> valList1;
    case (cache,env,{exp1},impl,st,msg,_)
      equation
        (cache,Values.LIST(_::valList1),st) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
      then
        (cache,Values.LIST(valList1),st);
  end match;
end cevalListRest;

protected function cevalAnyString
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Values.Value v;
      String s;
    case (cache,env,{exp1},impl,st,msg,_)
      equation
        (cache,v,st) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        s = ValuesUtil.valString(v);
      then
        (cache,Values.STRING(s),st);
  end match;
end cevalAnyString;

protected function cevalNumBits
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outValue,outST) := match (inCache,inEnv,inExpExpLst,inBoolean,inST,inMsg,numIter)
    local
      Integer i;
    case (_,_,{},_,_,_,_)
      equation
         i = System.numBits();
      then
        (inCache,Values.INTEGER(i),inST);
  end match;
end cevalNumBits;

protected function cevalIntegerMax
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outValue,outST) := match (inCache,inEnv,inExpExpLst,inBoolean,inST,inMsg,numIter)
    local
      Integer i;
    case (_,_,{},_,_,_,_)
      equation
         i = System.intMaxLit();
      then
        (inCache,Values.INTEGER(i),inST);
  end match;
end cevalIntegerMax;

protected function cevalGetLoadedLibraries
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outValue,outST) := match (inCache,inEnv,inExpExpLst,inBoolean,inST,inMsg,numIter)
    local
      Env.Cache cache;
      Env.Env env;
      Env.Frame fr;
      list<SCode.Element> classes;
      list<Absyn.Class> absynclasses;
      Values.Value v;
    case (cache,env,{},_,SOME(GlobalScript.SYMBOLTABLE(ast=Absyn.PROGRAM(classes=absynclasses))),_,_)
      equation
        v = ValuesUtil.makeArray(List.fold(absynclasses,makeLoadLibrariesEntryAbsyn,{}));
      then (cache,v,inST);
    case (cache,env,{},_,_,_,_)
      equation
        fr::_ = listReverse(env);
        classes = Env.getClassesInFrame(fr);
        v = ValuesUtil.makeArray(List.fold(classes,makeLoadLibrariesEntry,{}));
      then (cache,v,inST);
  end match;
end cevalGetLoadedLibraries;

protected function makeLoadLibrariesEntry "Needed to be able to resolve modelica:// during runtime, etc.
Should not be part of CevalScript since ModelicaServices needs this feature and the frontend needs to take care of it."
  input SCode.Element cl;
  input list<Values.Value> acc;
  output list<Values.Value> out;
algorithm
  out := match (cl,acc)
    local
      String name,fileName,dir;
      Values.Value v;
      Boolean b;
    case (SCode.CLASS(info=Absyn.INFO(fileName="<interactive>")),_) then acc;
    case (SCode.CLASS(name=name,info=Absyn.INFO(fileName=fileName)),_)
      equation
        dir = System.dirname(fileName);
        fileName = System.basename(fileName);
        v = ValuesUtil.makeArray({Values.STRING(name),Values.STRING(dir)});
        b = stringEq(fileName,"ModelicaBuiltin.mo") or stringEq(fileName,"MetaModelicaBuiltin.mo") or stringEq(dir,".");
      then List.consOnTrue(not b,v,acc);
  end match;
end makeLoadLibrariesEntry;

protected function makeLoadLibrariesEntryAbsyn "Needed to be able to resolve modelica:// during runtime, etc.
Should not be part of CevalScript since ModelicaServices needs this feature and the frontend needs to take care of it."
  input Absyn.Class cl;
  input list<Values.Value> acc;
  output list<Values.Value> out;
algorithm
  out := match (cl,acc)
    local
      String name,fileName,dir;
      Values.Value v;
      Boolean b;
    case (Absyn.CLASS(info=Absyn.INFO(fileName="<interactive>")),_) then acc;
    case (Absyn.CLASS(name=name,info=Absyn.INFO(fileName=fileName)),_)
      equation
        dir = System.dirname(fileName);
        fileName = System.basename(fileName);
        v = ValuesUtil.makeArray({Values.STRING(name),Values.STRING(dir)});
        b = stringEq(fileName,"ModelicaBuiltin.mo") or stringEq(fileName,"MetaModelicaBuiltin.mo") or stringEq(dir,".");
      then List.consOnTrue(not b,v,acc);
  end match;
end makeLoadLibrariesEntryAbsyn;

protected function cevalListFirst
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp1;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Values.Value v;
    case (cache,env,{exp1},impl,st,msg,_)
      equation
        (cache,Values.LIST(v::_),st) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
      then
        (cache,ValuesUtil.boxIfUnboxedVal(v),st);
  end match;
end cevalListFirst;

protected function extractValueStringChar
  input Values.Value val;
  output String str;
algorithm
  str := match (val)
    case Values.STRING(str) equation 1 = stringLength(str); then str;
  end match;
end extractValueStringChar;

protected function cevalCat "evaluates the cat operator given a list of
  array values and a concatenation dimension."
  input list<Values.Value> v_lst;
  input Integer dim;
  output Values.Value outValue;
protected
  list<Values.Value> v_lst_1;
algorithm
  v_lst_1 := catDimension(v_lst, dim);
  outValue := ValuesUtil.makeArray(v_lst_1);
end cevalCat;

protected function catDimension "Helper function to cevalCat, concatenates a list
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
      Integer dim_1,dim,i1,i2;
      list<Integer> il;
    case (vlst,1) /* base case for first dimension */
      equation
        vlst_lst = List.map(vlst, ValuesUtil.arrayValues);
        v_lst_1 = List.flatten(vlst_lst);
      then
        v_lst_1;
    case (vlst,dim)
      equation
        v_lst_lst = List.map(vlst, ValuesUtil.arrayValues);
        dim_1 = dim - 1;
        v_lst_lst_1 = catDimension2(v_lst_lst, dim_1);
        v_lst_1 = List.map(v_lst_lst_1, ValuesUtil.makeArray);
        (Values.ARRAY(valueLst = vlst2, dimLst = i2::il) :: _) = v_lst_1;
        i1 = listLength(v_lst_1);
        v_lst_1 = cevalBuiltinTranspose2(v_lst_1, 1, i2::i1::il);
      then
        v_lst_1;
  end matchcontinue;
end catDimension;

protected function catDimension2 "author: PA
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
        l_lst = List.first(lst);
        1 = listLength(l_lst);
        first_lst = List.map(lst, List.first);
        first_lst_1 = catDimension(first_lst, dim);
        first_lst_2 = List.map(first_lst_1, List.create);
      then
        first_lst_2;
    case (lst,dim)
      equation
        first_lst = List.map(lst, List.first);
        rest = List.map(lst, List.rest);
        first_lst_1 = catDimension(first_lst, dim);
        rest_1 = catDimension2(rest, dim);
        res = List.threadMap(rest_1, first_lst_1, List.consr);
      then
        res;
  end matchcontinue;
end catDimension2;

protected function cevalBuiltinFloor "author: LP
  evaluates the floor operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realFloor(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinFloor;

protected function cevalBuiltinCeil "author: LP
  evaluates the ceil operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1,rvt,realRet;
      Integer ri,ri_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        rvt = intReal(ri);
        (rvt ==. rv) = true;
      then
        (cache,Values.REAL(rvt),st);
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realFloor(rv);
        ri = realInt(rv_1);
        ri_1 = ri + 1;
        realRet = intReal(ri_1);
      then
        (cache,Values.REAL(realRet),st);
  end matchcontinue;
end cevalBuiltinCeil;

protected function cevalBuiltinSqrt "author: LP
  Evaluates the builtin sqrt operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp},impl,st, msg as Absyn.MSG(info = info),_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        (rv <. 0.0) = true;
        Error.addSourceMessage(Error.NEGATIVE_SQRT, {}, info);
      then
        fail();
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realSqrt(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end matchcontinue;
end cevalBuiltinSqrt;

protected function cevalBuiltinSin "author: LP
  Evaluates the builtin sin function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realSin(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinSin;

protected function cevalBuiltinSinh "author: PA
  Evaluates the builtin sinh function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realSinh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinSinh;

protected function cevalBuiltinCos "author: LP
  Evaluates the builtin cos function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realCos(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinCos;

protected function cevalBuiltinCosh "author: PA
  Evaluates the builtin cosh function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realCosh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinCosh;

protected function cevalBuiltinLog "author: LP
  Evaluates the builtin Log function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realLn(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinLog;

protected function cevalBuiltinLog10
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realLog10(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinLog10;

protected function cevalBuiltinTan "author: LP
  Evaluates the builtin tan function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,sv,cv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_) /* tan is not implemented in MetaModelica Compiler (MMC) for some strange reason. */
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        sv = realSin(rv);
        cv = realCos(rv);
        rv_1 = sv /. cv;
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinTan;

protected function cevalBuiltinTanh "author: PA
  Evaluates the builtin tanh function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_) /* tanh is not implemented in MetaModelica Compiler (MMC) for some strange reason. */
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
         rv_1 = realTanh(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinTanh;

protected function cevalBuiltinAsin "author: PA
  Evaluates the builtin asin function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realAsin(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinAsin;

protected function cevalBuiltinAcos "author: PA
  Evaluates the builtin acos function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realAcos(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinAcos;

protected function cevalBuiltinAtan "author: PA
  Evaluates the builtin atan function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_) /* atan is not implemented in MetaModelica Compiler (MMC) for some strange reason. */
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        rv_1 = realAtan(rv);
      then
        (cache,Values.REAL(rv_1),st);
  end match;
end cevalBuiltinAtan;

protected function cevalBuiltinAtan2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv,rv_1,rv_2;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv_1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.REAL(rv_2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rv = realAtan2(rv_1,rv_2);
      then
        (cache,Values.REAL(rv),st);
  end match;
end cevalBuiltinAtan2;

protected function cevalBuiltinDiv "author: LP
  Evaluates the builtin div operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv1,rv2,rv_1,rv_2;
      Integer ri,ri_1,ri1,ri2;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      String exp1_str,exp2_str,lh_str,rh_str;
      Env.Cache cache; Boolean b;
      Absyn.Info info;

    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rv_1 = rv1/. rv2;
        b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rv_1 = rv1/. rv2;
         b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rv2 = intReal(ri);
        rv_1 = rv1/. rv2;
        b = rv_1 <. 0.0;
        rv_2 = Util.if_(b,realCeil(rv_1),realFloor(rv_1));
      then
        (cache,Values.REAL(rv_2),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        ri_1 = intDiv(ri1,ri2);
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,Absyn.MSG(info = info),_)
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, inMsg,numIter+1);
        (rv2 ==. 0.0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.DIVISION_BY_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,Absyn.NO_MSG(),_)
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, Absyn.NO_MSG(),numIter+1);
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,Absyn.MSG(info = info),_)
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, inMsg,numIter+1);
        (ri2 == 0) = true;
        lh_str = ExpressionDump.printExpStr(exp1);
        rh_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,Absyn.NO_MSG(),_)
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, Absyn.NO_MSG(),numIter+1);
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiv;

protected function cevalBuiltinMod "author: LP
  Evaluates the builtin mod operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv1,rv2,rva,rvb,rvc,rvd;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Integer ri,ri1,ri2,ri_1;
      String lhs_str,rhs_str;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rva = rv1/. rv2;
        rvb = realFloor(rva);
        rvc = rvb*. rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rva = rv1 /. rv2;
        rvb = realFloor(rva);
        rvc = rvb *. rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rv2 = intReal(ri);
        rva = rv1 /. rv2;
        rvb = realFloor(rva);
        rvc = rvb *. rv2;
        rvd = rv1 -. rvc;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rv1 = intReal(ri1);
        rv2 = intReal(ri2);
        rva = rv1 /. rv2;
        rvb = realFloor(rva);
        rvc = rvb *. rv2;
        rvd = rv1 -. rvc;
        ri_1 = realInt(rvd);
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,Absyn.MSG(info = info),_)
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, inMsg,numIter+1);
        (rv2 ==. 0.0) = true;
        lhs_str = ExpressionDump.printExpStr(exp1);
        rhs_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,Absyn.NO_MSG(),_)
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st, Absyn.NO_MSG(),numIter+1);
        (rv2 ==. 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,Absyn.MSG(info = info),_)
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, inMsg,numIter+1);
        (ri2 == 0) = true;
        lhs_str = ExpressionDump.printExpStr(exp1);
        rhs_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,Absyn.NO_MSG(),_)
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st, Absyn.NO_MSG(),numIter+1);
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinMod;

protected function cevalBuiltinMax "author: LP
  Evaluates the builtin max function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Values.Value v,v1,v2,v_1;
      list<Env.Frame> env;
      DAE.Exp arr,s1,s2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{arr},impl,st,msg,_)
      equation
        (cache,v,_) = ceval(cache,env, arr, impl, st,msg,numIter+1);
        (v_1) = cevalBuiltinMaxArr(v);
      then
        (cache,v_1,st);
    case (cache,env,{s1,s2},impl,st,msg,_)
      equation
        (cache,v1,_) = ceval(cache,env, s1, impl, st,msg,numIter+1);
        (cache,v2,_) = ceval(cache,env, s2, impl, st,msg,numIter+1);
        v = cevalBuiltinMax2(v1,v2);
      then
        (cache,v,st);
  end match;
end cevalBuiltinMax;

protected function cevalBuiltinMax2
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value outValue;
algorithm
  outValue := match (v1,v2)
    local
      Integer i1,i2,i;
      Real r1,r2,r;
      Boolean b1,b2,b;
    case (Values.INTEGER(i1),Values.INTEGER(i2))
      equation
        i = intMax(i1, i2);
      then Values.INTEGER(i);
    case (Values.REAL(r1),Values.REAL(r2))
      equation
        r = realMax(r1, r2);
      then Values.REAL(r);
    case (Values.BOOL(b1),Values.BOOL(b2))
      equation
        b = boolOr(b1, b2);
      then Values.BOOL(b);
  end match;
end cevalBuiltinMax2;

protected function cevalBuiltinMaxArr "Helper function to cevalBuiltinMax."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue)
    local
      Integer i1,i2,resI,i;
      Real r,r1,r2,resR;
      Values.Value v1,v,vl;
      list<Values.Value> vls;
    
    case (Values.INTEGER(integer = i)) then Values.INTEGER(i);
    
    case (Values.REAL(real = r)) then Values.REAL(r);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.INTEGER(i1)) = cevalBuiltinMaxArr(v1);
        (Values.INTEGER(i2)) = cevalBuiltinMaxArr(ValuesUtil.makeArray(vls));
        resI = intMax(i1, i2);
      then
        Values.INTEGER(resI);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.REAL(r1)) = cevalBuiltinMaxArr(v1);
        (Values.REAL(r2)) = cevalBuiltinMaxArr(ValuesUtil.makeArray(vls));
        resR = realMax(r1, r2);
      then
        Values.REAL(resR);
    
    case (Values.ARRAY(valueLst = {vl}))
      equation
        (v) = cevalBuiltinMaxArr(vl);
      then
        v;
    
    case (_)
      equation
        //print("- Ceval.cevalBuiltinMax2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinMaxArr;

protected function cevalBuiltinMin "author: PA
  Constant evaluation of builtin min function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Values.Value v,v1,v2,v_1;
      list<Env.Frame> env;
      DAE.Exp arr,s1,s2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{arr},impl,st,msg,_)
      equation
        (cache,v,_) = ceval(cache,env, arr, impl, st,msg,numIter+1);
        (v_1) = cevalBuiltinMinArr(v);
      then
        (cache,v_1,st);
    case (cache,env,{s1,s2},impl,st,msg,_)
      equation
        (cache,v1,_) = ceval(cache,env, s1, impl, st,msg,numIter+1);
        (cache,v2,_) = ceval(cache,env, s2, impl, st,msg,numIter+1);
        v = cevalBuiltinMin2(v1, v2, msg);
      then
        (cache,v,st);
  end match;
end cevalBuiltinMin;

protected function cevalBuiltinMin2
  input Values.Value v1;
  input Values.Value v2;
  input Absyn.Msg inMsg;
  output Values.Value outValue;
algorithm
  outValue := match (v1, v2, inMsg)
    local
      Integer i1,i2,i;
      Real r1,r2,r;
      Boolean b1,b2,b;
      String s1,s2,s;
      Absyn.Info info;

    case (Values.INTEGER(i1), Values.INTEGER(i2), _)
      equation
        i = intMin(i1, i2);
      then Values.INTEGER(i);
    case (Values.REAL(r1), Values.REAL(r2), _)
      equation
        r = realMin(r1, r2);
      then Values.REAL(r);
    case (Values.BOOL(b1), Values.BOOL(b2), _)
      equation
        b = boolAnd(b1, b2);
      then Values.BOOL(b);
    case (_, _, Absyn.MSG(info = info))
      equation
        s1 = ValuesUtil.valString(v1);
        s2 = ValuesUtil.valString(v2);
        s = stringAppendList({"cevalBuiltinMin2 failed: min(", s1, ", ", s2, ")"});
        Error.addSourceMessage(Error.INTERNAL_ERROR, {s}, info);
      then fail();
  end match;
end cevalBuiltinMin2;

protected function cevalBuiltinMinArr "Helper function to cevalBuiltinMin."
  input Values.Value inValue;
  output Values.Value outValue;
algorithm
  outValue := matchcontinue (inValue)
    local
      Integer i1,i2,resI,i;
      Values.Value v1,v,vl;
      list<Values.Value> vls;
      Real r,r1,r2,resR;
    
    case (Values.INTEGER(integer = i)) then Values.INTEGER(i);
    case (Values.REAL(real = r)) then Values.REAL(r);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.INTEGER(i1)) = cevalBuiltinMinArr(v1);
        (Values.INTEGER(i2)) = cevalBuiltinMinArr(ValuesUtil.makeArray(vls));
        resI = intMin(i1, i2);
      then
        Values.INTEGER(resI);
    
    case (Values.ARRAY(valueLst = (v1 :: (vls as (_ :: _)))))
      equation
        (Values.REAL(r1)) = cevalBuiltinMinArr(v1);
        (Values.REAL(r2)) = cevalBuiltinMinArr(ValuesUtil.makeArray(vls));
        resR = realMin(r1, r2);
      then
        Values.REAL(resR);
    
    case (Values.ARRAY(valueLst = {vl}))
      equation
        (v) = cevalBuiltinMinArr(vl);
      then
        v;
    
  end matchcontinue;
end cevalBuiltinMinArr;

protected function cevalBuiltinDifferentiate "author: LP
  This function differentiates an equation: x^2 + x => 2x + 1"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      DAE.Exp differentiated_exp,differentiated_exp_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      DAE.ComponentRef cr;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      DAE.FunctionTree ft;
    case (cache,env,{exp1,DAE.CREF(componentRef = cr)},impl,st,msg,_)
      equation
        ft = Env.getFunctionTree(cache);
        differentiated_exp = Derive.differentiateExpCont(exp1, cr,SOME(ft));
        (differentiated_exp_1,_) = ExpressionSimplify.simplify(differentiated_exp);
        /*
         this is wrong... this should be used instead but unelabExp must be able to unelaborate a complete exp
         now it doesn't so the expression is returned as string Expression.unelabExp(differentiated_exp') => absyn_exp
        */
        ret_val = ExpressionDump.printExpStr(differentiated_exp_1);
      then
        (cache,Values.STRING(ret_val),st);
    case (_,_,_,_,st,msg,_) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */
      equation
        print("#- Differentiation failed. Celab.cevalBuiltinDifferentiate failed.\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinDifferentiate;

protected function cevalBuiltinSimplify "author: LP
  this function simplifies an equation: x^2 + x => 2x + 1"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      DAE.Exp exp1_1,exp1;
      String ret_val;
      list<Env.Frame> env;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp1},impl,st,msg,_)
      equation
        (exp1_1,_) = ExpressionSimplify.simplify(exp1);
        ret_val = ExpressionDump.printExpStr(exp1_1) "this should be used instead but unelab_exp must be able to unelaborate a complete exp Expression.unelab_exp(simplifyd_exp\') => absyn_exp" ;
      then
        (cache,Values.STRING(ret_val),st);
    case (_,_,_,_,st,Absyn.MSG(info = info),_) /* =>  (Values.CODE(Absyn.C_EXPRESSION(absyn_exp)),st) */
      equation
        Error.addSourceMessage(Error.COMPILER_ERROR, 
          {"Simplification failed. Ceval.cevalBuiltinSimplify failed."}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinSimplify;

protected function cevalBuiltinRem "author: LP
  Evaluates the builtin rem operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv1,rv2,rvd,dr;
      Integer ri,ri1,ri2,ri_1,di;
      list<Env.Frame> env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      String exp1_str,exp2_str;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg,numIter+1);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg,numIter+1);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(ri),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        rv2 = intReal(ri);
        (cache,Values.REAL(dr),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg,numIter+1);
        rvd = rv1 -. rv2 *. dr;
      then
        (cache,Values.REAL(rvd),st);
    case (cache,env,{exp1,exp2},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(ri1),_) = ceval(cache,env, exp1, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st,msg,numIter+1);
        (cache,Values.INTEGER(di),_) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,st,msg,numIter+1);
        ri_1 = ri1 - ri2 * di;
      then
        (cache,Values.INTEGER(ri_1),st);
    case (cache,env,{exp1,exp2},impl,st,Absyn.MSG(info = info),_)
      equation
        (cache,Values.REAL(rv2),_) = ceval(cache,env,exp2,impl,st,inMsg,numIter+1);
        (rv2 ==. 0.0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,st,Absyn.MSG(info = info),_)
      equation
        (cache,Values.INTEGER(ri2),_) = ceval(cache,env, exp2, impl, st,inMsg,numIter+1);
        (ri2 == 0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinRem;

protected function cevalBuiltinInteger "author: LP
  Evaluates the builtin integer operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv;
      Integer ri;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        ri = realInt(rv);
      then
        (cache,Values.INTEGER(ri),st);
  end match;
end cevalBuiltinInteger;

protected function cevalBuiltinBoolean "function cevalBuiltinBoolean
 @author: adrpo
  Evaluates the builtin boolean operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Real rv;
      Integer iv;
      Boolean bv;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    
    // real -> bool
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.REAL(rv),_) = ceval(cache, env, exp, impl, st,msg,numIter+1);
        bv = Util.if_(realEq(rv, 0.0), false, true);
      then
        (cache,Values.BOOL(bv),st);
    
    // integer -> bool
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.INTEGER(iv),_) = ceval(cache, env, exp, impl, st,msg,numIter+1);
        bv = Util.if_(intEq(iv, 0), false, true);
      then
        (cache,Values.BOOL(bv),st);
    
    // bool -> bool
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.BOOL(bv),_) = ceval(cache, env, exp, impl, st,msg,numIter+1);
      then
        (cache,Values.BOOL(bv),st);
  end matchcontinue;
end cevalBuiltinBoolean;

protected function cevalBuiltinRooted
"author: adrpo
  Evaluates the builtin rooted operator from MultiBody"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,_,_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
      then
        (cache,Values.BOOL(true),st);
  end match;
end cevalBuiltinRooted;

protected function cevalBuiltinIntegerEnumeration "author: LP
  Evaluates the builtin Integer operator"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      Integer ri;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.ENUM_LITERAL(index = ri),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
      then
        (cache,Values.INTEGER(ri),st);
  end match;
end cevalBuiltinIntegerEnumeration;

protected function cevalBuiltinDiagonal "This function generates a matrix{n,n} (A) of the vector {a,b,...,n}
  where the diagonal of A is the vector {a,b,...,n}
  ie A{1,1} == a, A{2,2} == b ..."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Values.Value> rv2,retExp;
      Integer dimension,correctDimension;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Values.Value res;
      Absyn.Info info;

    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.ARRAY(rv2,{dimension}),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        correctDimension = dimension + 1;
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, exp, impl, st, correctDimension, 1, {},msg,numIter+1);
        res = Values.ARRAY(retExp,{dimension,dimension});
      then
        (cache,res,st);
    case (_,_,_,_,_,Absyn.MSG(info = info),_)
      equation
        Error.addSourceMessage(Error.COMPILER_ERROR,
          {"Could not evaluate diagonal. Ceval.cevalBuiltinDiagonal failed."}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal;

protected function cevalBuiltinDiagonal2 " This is a help function that is calling itself recursively to
   generate the a nxn matrix with some special diagonal elements.
   See cevalBuiltinDiagonal."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input Boolean inBoolean3;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Integer inInteger5 "matrix dimension";
  input Integer inInteger6 "row";
  input list<Values.Value> inValuesValueLst7;
  input Absyn.Msg inMsg8;
  input Integer numIter;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
algorithm
  (outCache,outValuesValueLst) :=
  matchcontinue (inCache,inEnv1,inExp2,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inInteger5,inInteger6,inValuesValueLst7,inMsg8,numIter)
    local
      Real rv2;
      Integer correctDim,correctPlace,newRow,matrixDimension,row,iv2;
      list<Values.Value> zeroList,listWithElement,retExp,appendedList,listIN,list_;
      list<Env.Frame> env;
      DAE.Exp s1,s2;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Values.Value v;
      Absyn.Info info;
      String str;
    
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg,_)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg,numIter+1);
        correctDim = matrixDimension - 1;
        zeroList = List.fill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = List.replaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, {v},msg,numIter);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg,_)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.REAL(rv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg,numIter+1);
        
        false = intEq(matrixDimension, row);
        
        correctDim = matrixDimension - 1;
        zeroList = List.fill(Values.REAL(0.0), correctDim);
        correctPlace = row - 1;
        listWithElement = List.replaceAt(Values.REAL(rv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        appendedList = listAppend(listIN, {v});
        (cache,retExp)= cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, appendedList,msg,numIter);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,{},msg,_)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.INTEGER(iv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg,numIter+1);
        correctDim = matrixDimension - 1;
        zeroList = List.fill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = List.replaceAt(Values.INTEGER(iv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, {v},msg,numIter);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg,_)
      equation
        s2 = DAE.ICONST(row);
        (cache,Values.INTEGER(iv2),_) = ceval(cache,env, Expression.makeASUB(s1,{s2}), impl, st,msg,numIter+1);
        
        false = intEq(matrixDimension, row);

        correctDim = matrixDimension - 1;
        zeroList = List.fill(Values.INTEGER(0), correctDim);
        correctPlace = row - 1;
        listWithElement = List.replaceAt(Values.INTEGER(iv2), correctPlace, zeroList);
        newRow = row + 1;
        v = ValuesUtil.makeArray(listWithElement);
        appendedList = listAppend(listIN, {v});
        (cache,retExp) = cevalBuiltinDiagonal2(cache,env, s1, impl, st, matrixDimension, newRow, appendedList, msg, numIter);
      then
        (cache,retExp);
    
    case (cache,env,s1,impl,st,matrixDimension,row,listIN,msg,_)
      equation
        true = intEq(matrixDimension, row);
      then
        (cache,listIN);
    
    case (_,_,_,_,_,matrixDimension,row,list_,Absyn.MSG(info = info),_)
      equation
        true = Flags.isSet(Flags.CEVAL);
        str = Error.infoStr(info);
        Debug.traceln(str +& " Ceval.cevalBuiltinDiagonal2 failed");
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
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Values.Value> xv,yv;
      Values.Value res;
      list<Env.Frame> env;
      DAE.Exp xe,ye;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      String str;
      Absyn.Info info;

    case (cache,env,{xe,ye},impl,st,msg,_)
      equation
        (cache,Values.ARRAY(xv,{3}),_) = ceval(cache,env,xe,impl,st,msg,numIter+1);
        (cache,Values.ARRAY(yv,{3}),_) = ceval(cache,env,ye,impl,st,msg,numIter+1);
        res = ValuesUtil.crossProduct(xv,yv);
      then
        (cache,res,st);
    case (_,_,_,_,_,Absyn.MSG(info = info),_)
      equation
        str = "cross" +& ExpressionDump.printExpStr(DAE.TUPLE(inExpExpLst));
        Error.addSourceMessage(Error.FAILED_TO_EVALUATE_EXPRESSION, {str}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinCross;

protected function cevalBuiltinTranspose "This function transposes the two first dimension of an array A."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Values.Value> vlst,vlst2,vlst_1;
      Integer i1,i2;
      list<Integer> il;
      list<Env.Frame> env;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Absyn.Info info;

    case (cache,env,{exp},impl,st,msg,_)
      equation
        (cache,Values.ARRAY(vlst,i1::_),_) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        (Values.ARRAY(valueLst = vlst2, dimLst = i2::il) :: _) = vlst;
        vlst_1 = cevalBuiltinTranspose2(vlst, 1, i2::i1::il);
      then
        (cache,Values.ARRAY(vlst_1,i2::i1::il),st);
    case (_,_,_,_,_,Absyn.MSG(info = info),_)
      equation
        Error.addSourceMessage(Error.COMPILER_ERROR, 
          {"Could not evaluate transpose. Celab.cevalBuildinTranspose failed."}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinTranspose;

protected function cevalBuiltinTranspose2 "author: PA
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
    case (vlst,indx,(dim1::_))
      equation
        (indx <= dim1) = true;
        transposed_row = List.map1(vlst, ValuesUtil.nthArrayelt, indx);
        indx_1 = indx + 1;
        rest = cevalBuiltinTranspose2(vlst, indx_1, inDims);
      then
        (Values.ARRAY(transposed_row,inDims) :: rest);
    case (_,_,_) then {};
  end matchcontinue;
end cevalBuiltinTranspose2;

protected function cevalBuiltinSizeMatrix "Helper function for cevalBuiltinSize, for size(A) where A is a matrix."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValue,outInteractiveInteractiveSymbolTableOption) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      DAE.Type tp;
      list<Integer> sizelst;
      Values.Value v;
      Env.Env env;
      DAE.ComponentRef cr;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      DAE.Exp exp;
      DAE.Dimensions dims;
    
    // size(cr)
    case (cache,env,DAE.CREF(componentRef = cr),impl,st,msg,_)
      equation
        (cache,_,tp,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        sizelst = Types.getDimensionSizes(tp);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v,st);
        
    // For matrix expressions: [1,2;3,4]
    case (cache, env, DAE.MATRIX(ty = DAE.T_ARRAY(dims = dims)), impl, st, msg, _)
      equation
        sizelst = List.map(dims, Expression.dimensionSize);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache, v, st);
    
    // For other matrix expressions e.g. on array form: {{1,2},{3,4}}
    case (cache,env,exp,impl,st,msg,_)
      equation
        (cache,Values.ARRAY(dimLst=sizelst),st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v,st);
  end matchcontinue;
end cevalBuiltinSizeMatrix;

protected function cevalBuiltinFill
  "This function constant evaluates calls to the fill function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpl;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache, outValue, outST) :=
  match (inCache, inEnv, inExpl, inImpl, inST, inMsg, numIter)
    local
      DAE.Exp fill_exp;
      list<DAE.Exp> dims;
      Values.Value fill_val;
      Env.Cache cache;
      Option<GlobalScript.SymbolTable> st;
    case (cache, _, fill_exp :: dims, _, st, _, _)
      equation
        (cache, fill_val, st) = ceval(cache, inEnv, fill_exp, inImpl, st, inMsg, numIter+1);
        (cache, fill_val, st) = cevalBuiltinFill2(cache, inEnv, fill_val, dims, inImpl, inST, inMsg, numIter);
      then
        (cache, fill_val, st);
  end match;
end cevalBuiltinFill;

protected function cevalBuiltinFill2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Values.Value inFillValue;
  input list<DAE.Exp> inDims;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache, outValue, outST) := 
  match (inCache, inEnv, inFillValue, inDims, inImpl, inST, inMsg, numIter)
    local
      DAE.Exp dim;
      list<DAE.Exp> rest_dims;
      Integer int_dim;
      list<Integer> array_dims;
      Values.Value fill_value;
      list<Values.Value> fill_vals;
      Env.Cache cache;
      Option<GlobalScript.SymbolTable> st;

    case (cache, _, _, {}, _, st, _, _) then (cache, inFillValue, st);

    case (cache, _, _, dim :: rest_dims, _, st, _, _)
      equation
        (cache, fill_value, st) = cevalBuiltinFill2(cache, inEnv, inFillValue,
          rest_dims, inImpl, inST, inMsg, numIter);
        (cache, Values.INTEGER(int_dim), st) = ceval(cache, inEnv, dim, inImpl, st, inMsg, numIter+1);
        fill_vals = List.fill(fill_value, int_dim);
        array_dims = ValuesUtil.valueDimensions(fill_value);
        array_dims = int_dim :: array_dims;
      then
        (cache, Values.ARRAY(fill_vals, array_dims), st);
  end match;
end cevalBuiltinFill2;

protected function cevalRelation
  "Performs the arithmetic relation check and gives a boolean result."
  input Values.Value inValue1;
  input DAE.Operator inOperator;
  input Values.Value inValue2;
  output Values.Value outValue;

protected
  Boolean result;
algorithm
  result := cevalRelation_dispatch(inValue1, inOperator, inValue2);
  outValue := Values.BOOL(result);
end cevalRelation;

protected function cevalRelation_dispatch
  "Dispatch function for cevalRelation. Call the right relation function
  depending on the operator."
  input Values.Value inValue1;
  input DAE.Operator inOperator;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inOperator, inValue2)
    local 
      Values.Value v1, v2;
      DAE.Operator op;
    
    case (v1, DAE.GREATER(ty = _), v2) then cevalRelationLess(v2, v1);
    case (v1, DAE.LESS(ty = _), v2) then cevalRelationLess(v1, v2);
    case (v1, DAE.LESSEQ(ty = _), v2) then cevalRelationLessEq(v1, v2);
    case (v1, DAE.GREATEREQ(ty = _), v2) then cevalRelationGreaterEq(v1, v2);
    case (v1, DAE.EQUAL(ty = _), v2) then cevalRelationEqual(v1, v2);
    case (v1, DAE.NEQUAL(ty = _), v2) then cevalRelationNotEqual(v1, v2);
    
    case (v1, op, v2)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Ceval.cevalRelation failed on: " +&
          ValuesUtil.printValStr(v1) +&
          ExpressionDump.binopSymbol(op) +&
          ValuesUtil.printValStr(v2));
      then
        fail();
  end matchcontinue;
end cevalRelation_dispatch;

protected function cevalRelationLess
  "Returns whether the first value is less than the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) < 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 < i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 <. r2);
    case (Values.BOOL(boolean = false), Values.BOOL(boolean = true))
      then true;
    case (Values.BOOL(boolean = _), Values.BOOL(boolean = _))
      then false;
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 < i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 < i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 < i2);
  end matchcontinue;
end cevalRelationLess;

protected function cevalRelationLessEq
  "Returns whether the first value is less than or equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) <= 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 <= i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 <=. r2);
    case (Values.BOOL(boolean = true), Values.BOOL(boolean = false))
      then false;
    case (Values.BOOL(boolean = _), Values.BOOL(boolean = _))
      then true;
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <= i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 <= i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <= i2);
  end matchcontinue;
end cevalRelationLessEq;

protected function cevalRelationGreaterEq
  "Returns whether the first value is greater than or equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := matchcontinue(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) >= 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 >= i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 >=. r2);
    case (Values.BOOL(boolean = false), Values.BOOL(boolean = true))
      then false;
    case (Values.BOOL(boolean = _), Values.BOOL(boolean = _))
      then true;
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 >= i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 >= i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 >= i2);
  end matchcontinue;
end cevalRelationGreaterEq;

protected function cevalRelationEqual
  "Returns whether the first value is equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
      Boolean b1, b2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) == 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 == i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 ==. r2);
    case (Values.BOOL(boolean = b1), Values.BOOL(boolean = b2)) 
      then boolEq(b1, b2);
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 == i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 == i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 == i2);
  end match;
end cevalRelationEqual;

protected function cevalRelationNotEqual
  "Returns whether the first value is not equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    local
      String s1, s2;
      Integer i1, i2;
      Real r1, r2;
      Boolean b1, b2;
    case (Values.STRING(string = s1), Values.STRING(string = s2))
      then (stringCompare(s1, s2) <> 0);
    case (Values.INTEGER(integer = i1), Values.INTEGER(integer = i2))
      then (i1 <> i2);
    case (Values.REAL(real = r1), Values.REAL(real = r2)) 
      then (r1 <>. r2);
    case (Values.BOOL(boolean = b1), Values.BOOL(boolean = b2)) 
      then not boolEq(b1, b2);
    case (Values.ENUM_LITERAL(index = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <> i2);
    case (Values.ENUM_LITERAL(index = i1), Values.INTEGER(integer = i2))
      then (i1 <> i2);
    case (Values.INTEGER(integer = i1), Values.ENUM_LITERAL(index = i2))
      then (i1 <> i2);
  end match;
end cevalRelationNotEqual;

public function cevalRangeEnum
  "Evaluates a range expression on the form enum.lit1 : enum.lit2"
  input Integer startIndex;
  input Integer stopIndex;
  input DAE.Type enumType;
  output list<Values.Value> enumValList;
algorithm
  enumValList := match(startIndex, stopIndex, enumType)
    local
      Absyn.Path enum_type;
      list<String> enum_names;
      list<Absyn.Path> enum_paths;
      list<Values.Value> enum_values;
    case (_, _, DAE.T_ENUMERATION(path = enum_type, names = enum_names))
      equation
        (startIndex <= stopIndex) = true;
        enum_names = List.sublist(enum_names, startIndex, (stopIndex - startIndex) + 1);
        enum_paths = List.map(enum_names, Absyn.makeIdentPathFromString);
        enum_paths = List.map1r(enum_paths, Absyn.joinPaths, enum_type);
        (enum_values, _) = List.mapFold(enum_paths, makeEnumValue, startIndex);
      then
        enum_values;
  end match;
end cevalRangeEnum;
  
protected function makeEnumValue
  input Absyn.Path name;
  input Integer index;
  output Values.Value enumValue;
  output Integer newIndex;
algorithm
  enumValue := Values.ENUM_LITERAL(name, index);
  newIndex := index + 1;
end makeEnumValue;

public function cevalList "This function does constant
  evaluation on a list of expressions."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output list<Values.Value> outValuesValueLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outValuesValueLst,outInteractiveInteractiveSymbolTableOption) :=
  match (inCache,inEnv,inExpExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,numIter)
    local
      list<Env.Frame> env;
      Absyn.Msg msg;
      Values.Value v;
      DAE.Exp exp;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      list<Values.Value> vs;
      list<DAE.Exp> exps;
      Env.Cache cache;
    case (cache,env,{},_,st,msg,_) then (cache,{},st);
    case (cache,env,(exp :: exps ),impl,st,msg,_)
      equation
        (cache,v,st) = ceval(cache,env, exp, impl, st,msg,numIter+1);
        (cache,vs,st) = cevalList(cache,env, exps, impl, st,msg,numIter);
      then
        (cache,v :: vs,st);
  end match;
end cevalList;

public function cevalCref "Evaluates ComponentRef, i.e. variables, by
  looking up variables in the environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,inMsg,numIter)
    local
      DAE.Binding binding;
      Values.Value v;
      Env.Env env, classEnv, componentEnv;
      DAE.ComponentRef c;
      Boolean impl;
      Absyn.Msg msg;
      String scope_str,str, name;
      Env.Cache cache;
      Option<DAE.Const> const_for_range;
      DAE.Type ty;
      DAE.Attributes attr;
      InstTypes.SplicedExpData splicedExpData;
      Absyn.Info info;

    // Try to lookup the variables binding and constant evaluate it.
    case (cache, env, c, impl, msg, _)
      equation
        (cache,attr,ty,binding,const_for_range,splicedExpData,classEnv,componentEnv,name) = Lookup.lookupVar(cache, env, c);
         // send the entire shebang to cevalCref2 so we don't have to do lookup var again!
        (cache, v) = cevalCref_dispatch(cache, env, c, attr, ty, binding, const_for_range, splicedExpData, classEnv, componentEnv, name, impl,msg,numIter);
      then
        (cache, v);

    // failure in lookup and we have the MSG go-ahead to print the error
    case (cache,env,c,(impl as false),Absyn.MSG(info = info),_)
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
        scope_str = Env.printEnvPathStr(env);
        str = ComponentReference.printComponentRefStr(c);
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR, {str,scope_str}, info);
      then
        fail();
    
    // failure in lookup but NO_MSG, silently fail and move along
    /*case (cache,env,c,(impl as false),Absyn.NO_MSG(),_)
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
      then
        fail();*/
  end matchcontinue;
end cevalCref;

public function cevalCref_dispatch
  "Helper function to cevalCref"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inCref;
  input DAE.Attributes inAttr;
  input DAE.Type inType;   
  input DAE.Binding inBinding;
  input Option<DAE.Const> constForRange;
  input InstTypes.SplicedExpData inSplicedExpData;
  input Env.Env inClassEnv;
  input Env.Env inComponentEnv;
  input String  inFQName;
  input Boolean inImpl;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) := match (inCache, inEnv, inCref, inAttr, inType, inBinding, constForRange, inSplicedExpData, inClassEnv, inComponentEnv, inFQName, inImpl, inMsg, numIter)
    local
      Env.Cache cache;
      Values.Value v;
      String str, scope_str, s1, s2, s3;
      Absyn.Info info;
      SCode.Variability variability;
    
    // A variable with no binding and SOME for range constness -> a for iterator
    case (_, _, _, _, _, DAE.UNBOUND(), SOME(_), _, _, _, _, _, _, _) then fail();
    
    // A variable without a binding -> error in a simulation model
    // and we can only check that at the DAE level!
    case (_, _, _, _, _, DAE.UNBOUND(), NONE(), _, _, _, _, false, Absyn.MSG(info = info), _)
      equation
        str = ComponentReference.printComponentRefStr(inCref);
        scope_str = Env.printEnvPathStr(inEnv);
        // Error.addSourceMessage(Error.NO_CONSTANT_BINDING, {str, scope_str}, info);
        Debug.fprintln(Flags.CEVAL, "- Ceval.cevalCref on: " +& str +& 
          " failed with no constant binding in scope: " +& scope_str);
        // build a default binding for it!
        s1 = Env.printEnvPathStr(inEnv);
        s2 = ComponentReference.printComponentRefStr(inCref);
        s3 = Types.printTypeStr(inType);
        v = Types.typeToValue(inType);
        v = Values.EMPTY(s1, s2, v, s3);
        // i would really like to have Absyn.Info to put in Values.EMPTY here!
        // to easier report errors later on and also to have DAE.ComponentRef and DAE.Type 
        // but unfortunately DAE depends on Values and they should probably be merged !
        // Actually, at a second thought we SHOULD NOT HAVE VALUES AT ALL, WE SHOULD HAVE
        // JUST ONE DAE.Exp.CONSTANT_EXPRESSION(exp, constantness, type)!
      then
        (inCache, v);    
        
    // A variable with a binding -> constant evaluate the binding
    case (_, _, _, DAE.ATTR(variability=variability), _, _, _, _, _, _, _, _, _, _)
      equation
        // We might try to ceval variables in reduction scope... but it can't be helped since we do things in a ***** way in Inst/Static
        true = SCode.isParameterOrConst(variability) or inImpl or Env.inForLoopScope(inEnv);
        false = crefEqualValue(inCref, inBinding);
        (cache, v) = cevalCrefBinding(inCache, inEnv, inCref, inBinding, inImpl, inMsg, numIter);
        // print("Eval cref: " +& ComponentReference.printComponentRefStr(inCref) +& "\n  in scope " +& Env.printEnvPathStr(inEnv) +& "\n");
        cache = Env.addEvaluatedCref(cache,variability,ComponentReference.crefStripLastSubs(inCref));
      then
        (cache, v);
  end match;
end cevalCref_dispatch;

public function cevalCrefBinding "Helper function to cevalCref.
  Evaluates variables by evaluating their bindings."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.Binding inBinding;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inComponentRef,inBinding,inBoolean,inMsg,numIter)
    local
      DAE.ComponentRef cr,e1;
      list<DAE.Subscript> subsc;
      Values.Value res,v,e_val;
      list<Env.Frame> env;
      Boolean impl;
      Absyn.Msg msg;
      String rfn,iter,expstr,s1,s2,str;
      DAE.Exp elexp,iterexp,exp;
      Env.Cache cache;
      list<DAE.Var> vl;
      Absyn.Path tpath;
      DAE.Type ty;
      Absyn.Ident id;
      Absyn.Info info;
      DAE.Binding binding;

    /*
    case (cache,env,cr,_,impl,msg)
      equation 
        print("Ceval: " +& 
          ComponentReference.printComponentRefStr(cr) +& " | " +&
          Env.printEnvPathStr(env) +& " | " +&
          DAEUtil.printBindingExpStr(inBinding) +&
          "\n"); 
      then
        fail();*/

    case (cache,env,cr,DAE.VALBOUND(valBound = v),impl,msg,_) 
      equation 
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl,msg,numIter+1);
      then
        (cache,res);

    // take the bindings form the cref type if is a record that has bindings for everything!
    case (cache,env,DAE.CREF_IDENT(id, ty, {}),DAE.UNBOUND(),_,Absyn.MSG(info),_)
      equation
        (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = tpath),
           varLst = vl)) = Types.arrayElementType(ty);
        true = Types.allHaveBindings(vl);
        binding = Inst.makeRecordBinding(cache, env, tpath, ty, vl, {}, info);
        (cache, res) = cevalCrefBinding(cache, env, inComponentRef, binding, inBoolean, inMsg, numIter+1);
      then 
        (cache, res);

    case (cache,env,_,DAE.UNBOUND(),(impl as false),Absyn.MSG(_),_) then fail();

    case (cache,env,_,DAE.UNBOUND(),(impl as true),Absyn.MSG(_),_)
      equation
        Debug.fprint(Flags.CEVAL, "#- Ceval.cevalCrefBinding: Ignoring unbound when implicit");
      then
        fail();

    // REDUCTION bindings  
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg,_)
      equation 
        DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = Absyn.IDENT(name = rfn)),expr = elexp, iterators = {DAE.REDUCTIONITER(id=iter,exp=iterexp)}) = exp;
        (cache,v,_) = ceval(cache, env, exp, impl,NONE(),msg,numIter+1);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl,msg,numIter+1);
      then
        (cache,res);
        
    // arbitrary expressions, C_VAR, value exists. 
    case (cache,env,cr,DAE.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = DAE.C_VAR()),impl,msg,_)
      equation 
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, e_val, impl,msg,numIter+1);
      then
        (cache,res);

    // arbitrary expressions, C_PARAM, value exists.  
    case (cache,env,cr,DAE.EQBOUND(exp = exp,evaluatedExp = SOME(e_val),constant_ = DAE.C_PARAM()),impl,msg,_)
      equation 
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res)= cevalSubscriptValue(cache,env, subsc, e_val, impl,msg,numIter+1);
      then
        (cache,res);

    // arbitrary expressions. When binding has optional value. 
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg,_)
      equation
        (cache,v,_) = ceval(cache, env, exp, impl, NONE(),msg,numIter+1);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, v, impl,msg,numIter+1);
      then
        (cache,res);

    // arbitrary expressions. When binding has optional value.  
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_PARAM()),impl,msg,_)
      equation 
        // TODO: Ugly hack to prevent infinite recursion. If we have a binding r = r that
        // can for instance come from a modifier, this can cause an infinite loop here if r has no value.
        false = isRecursiveBinding(cr,exp);
        
        (cache,v,_) = ceval(cache, env, exp, impl, NONE(),msg,numIter+1);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl,msg,numIter+1);
      then
        (cache,res);

    // if the binding has constant-ness DAE.C_VAR we cannot constant evaluate.
    case (cache,env,_,DAE.EQBOUND(exp = exp,constant_ = DAE.C_VAR()),impl,Absyn.MSG(_),_)
      equation
        true = Flags.isSet(Flags.CEVAL);
        Debug.trace("#- Ceval.cevalCrefBinding failed (nonconstant EQBOUND(");
        expstr = ExpressionDump.printExpStr(exp);
        Debug.trace(expstr);
        Debug.traceln("))");
      then
        fail();

    case (cache,env,e1,_,_,_,_)
      equation
        true = Flags.isSet(Flags.CEVAL);
        s1 = ComponentReference.printComponentRefStr(e1);
        s2 = Types.printBindingStr(inBinding);
        str = Env.printEnvPathStr(env);
        str = stringAppendList({"- Ceval.cevalCrefBinding: ", 
                s1, " = [", s2, "] in env:", str, " failed"});
        Debug.traceln(str);
        //print("ENV: " +& Env.printEnvStr(inEnv) +& "\n");
      then
        fail();
  end matchcontinue;
end cevalCrefBinding;

protected function isRecursiveBinding " help function to cevalCrefBinding"
input DAE.ComponentRef cr;
input DAE.Exp exp;
output Boolean res;
algorithm
  res := matchcontinue(cr,exp)
    case(_,_) equation
      res = Util.boolOrList(List.map1(Expression.extractCrefsFromExp(exp),ComponentReference.crefEqual,cr));
    then res;
    case(_,_) then false;
  end matchcontinue;
end isRecursiveBinding;
  

public function cevalSubscriptValue "Helper function to cevalCrefBinding. It applies
  subscripts to array values to extract array elements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
  input Values.Value inValue;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inExpSubscriptLst,inValue,inBoolean,inMsg,numIter)
    local
      Integer n,n_1;
      Values.Value subval,res,v;
      list<Env.Frame> env;
      DAE.Exp exp;
      list<DAE.Subscript> subs;
      list<Values.Value> lst,sliceLst,subvals;
      list<Integer> slice;
      Boolean impl;
      Absyn.Msg msg;
      Env.Cache cache;

    // we have a subscript which is an index, try to constant evaluate it
    case (cache,env,(DAE.INDEX(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg,_)
      equation
        (cache,Values.INTEGER(n),_) = ceval(cache, env, exp, impl, NONE(),msg,numIter+1);
        n_1 = n - 1;
        subval = listNth(lst, n_1);
        (cache,res) = cevalSubscriptValue(cache, env, subs, subval, impl,msg,numIter+1);
      then
        (cache,res);
    
    // ceval gives us a enumeration literal scalar
    case (cache,env,(DAE.INDEX(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg,_)
      equation
        (cache,Values.ENUM_LITERAL(index = n),_) = ceval(cache, env, exp, impl, NONE(),msg,numIter+1);
        n_1 = n - 1;
        subval = listNth(lst, n_1); // listNth indexes from 0!
        (cache,res) = cevalSubscriptValue(cache, env, subs, subval, impl,msg,numIter+1);
      then
        (cache,res);
    
    // slices
    case (cache,env,(DAE.SLICE(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg,_)
      equation
        (cache,subval as Values.ARRAY(valueLst = sliceLst),_) = ceval(cache, env, exp, impl,NONE(),msg,numIter+1);
        slice = List.map(sliceLst, ValuesUtil.valueIntegerMinusOne);
        subvals = List.map1r(slice, listNth, lst);
        (cache,lst) = cevalSubscriptValueList(cache,env, subs, subvals, impl,msg,numIter);
        res = ValuesUtil.makeArray(lst);
      then
        (cache,res);
    
    // we have a wholedim, so just pass the whole array on.
    case (cache, env, (DAE.WHOLEDIM() :: subs), subval as Values.ARRAY(valueLst = _), impl, msg,_)
      equation
        (cache, res) = cevalSubscriptValue(cache, env, subs, subval, impl,msg,numIter+1);
      then
        (cache, res);
       
    // we have no subscripts but we have a value, return it
    case (cache,env,{},v,_,_,_) then (cache,v);
    
    /*// failtrace
    case (cache, env, subs, inValue, dims, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Ceval.cevalSubscriptValue failed on:" +&
          "\n env: " +& Env.printEnvPathStr(env) +&
          "\n subs: " +& stringDelimitList(List.map(subs, ExpressionDump.printSubscriptStr), ", ") +&
          "\n value: " +& ValuesUtil.printValStr(inValue) +&
          "\n dim sizes: " +& stringDelimitList(List.map(dims, intString), ", ") 
        );
      then
        fail();*/
  end matchcontinue;
end cevalSubscriptValue;

protected function cevalSubscriptValueList "Applies subscripts to array values to extract array elements."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
  input list<Values.Value> inValue;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output list<Values.Value> outValue;
algorithm
  (outCache,outValue) :=
  match (inCache,inEnv,inExpSubscriptLst,inValue,inBoolean,inMsg,numIter)
    local
      Values.Value subval,res;
      list<Env.Frame> env;
      list<Values.Value> lst,subvals;
      Boolean impl;
      Absyn.Msg msg;
      list<DAE.Subscript> subs;
      Env.Cache cache;
    case (cache,env,subs,{},impl,msg,_) then (cache,{});
    case (cache,env,subs,subval::subvals,impl,msg,_)
      equation
        (cache,res) = cevalSubscriptValue(cache,env, subs, subval, impl,msg,numIter+1);
        (cache,lst) = cevalSubscriptValueList(cache,env, subs, subvals, impl,msg,numIter);
      then
        (cache,res::lst);
  end match;
end cevalSubscriptValueList;

public function cevalSubscripts "This function relates a list of subscripts to their canonical
  forms, which is when all expressions are evaluated to constant
  values. For instance
  the subscript list {1,p,q} (as in x[1,p,q]) where p and q have constant values 2,3 respectively will become
  {1,2,3} (resulting in x[1,2,3])."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  (outCache,outExpSubscriptLst) :=
  match (inCache,inEnv,inExpSubscriptLst,inIntegerLst,inBoolean,inMsg,numIter)
    local
      DAE.Subscript sub_1,sub;
      list<DAE.Subscript> subs_1,subs;
      list<Env.Frame> env;
      Integer dim;
      list<Integer> dims;
      Boolean impl;
      Absyn.Msg msg;
      Env.Cache cache;

    // empty case
    case (cache,_,{},_,_,_,_) then (cache,{});

    // we have subscripts
    case (cache,env,(sub :: subs),(dim :: dims),impl,msg,_)
      equation
        (cache,sub_1) = cevalSubscript(cache, env, sub, dim, impl,msg,numIter+1);
        (cache,subs_1) = cevalSubscripts(cache, env, subs, dims, impl,msg,numIter);
      then
        (cache,sub_1 :: subs_1);
  end match;
end cevalSubscripts;

public function cevalSubscript "This function relates a subscript to its canonical forms, which
  is when all expressions are evaluated to constant values."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Subscript inSubscript;
  input Integer inInteger;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output DAE.Subscript outSubscript;
algorithm
  (outCache,outSubscript) :=
  matchcontinue (inCache,inEnv,inSubscript,inInteger,inBoolean,inMsg,numIter)
    local
      list<Env.Frame> env;
      Values.Value v1;
      DAE.Exp e1_1,e1;
      Integer dim;
      Boolean impl;
      Absyn.Msg msg;
      Env.Cache cache;
      Integer indx;

    // the entire dimension, nothing to do
    case (cache,env,DAE.WHOLEDIM(),_,_,_,_) then (cache,DAE.WHOLEDIM());
      
    // An enumeration literal is already constant
    case (cache, _, DAE.INDEX(exp = DAE.ENUM_LITERAL(name = _)), _, _, _, _)
      then (cache, inSubscript);
      
    // an expression index that can be constant evaluated
    case (cache,env,DAE.INDEX(exp = e1),dim,impl,msg,_)
      equation
        (cache,v1 as Values.INTEGER(indx),_) = ceval(cache,env, e1, impl,NONE(),msg,numIter+1);
        e1_1 = ValuesUtil.valueExp(v1);
        // This is a runtime or backend failure; not front-end
        // true = (indx <= dim) and (indx > 0);
      then
        (cache,DAE.INDEX(e1_1));

    // indexing using enum! 
    case (cache,env,DAE.INDEX(exp = e1),dim,impl,msg,_)
      equation
        (cache,v1 as Values.ENUM_LITERAL(index = indx),_) = ceval(cache,env, e1, impl,NONE(),msg,numIter+1);
        e1_1 = ValuesUtil.valueExp(v1);
        // This is a runtime or backend failure; not front-end
        // true = (indx <= dim) and (indx > 0);
      then
        (cache,DAE.INDEX(e1_1));

    case (cache,env,DAE.INDEX(exp = e1),dim,impl,msg,_)
      equation
        (cache,v1 as Values.BOOL(_),_) = ceval(cache,env, e1, impl,NONE(),msg,numIter+1);
        e1_1 = ValuesUtil.valueExp(v1);
      then (cache,DAE.INDEX(e1_1));

    // an expression slice that can be constant evaluated
    case (cache,env,DAE.SLICE(exp = e1),dim,impl,msg,_)
      equation
        (cache,v1,_) = ceval(cache,env, e1, impl,NONE(),msg,numIter+1);
        e1_1 = ValuesUtil.valueExp(v1);
        true = dimensionSliceInRange(v1,dim);
      then
        (cache,DAE.SLICE(e1_1));
        
  end matchcontinue;
end cevalSubscript;

protected function crefEqualValue ""
  input DAE.ComponentRef c;
  input DAE.Binding v;
  output Boolean outBoolean;
algorithm 
  outBoolean := match (c,v)
    local 
      DAE.ComponentRef cr;
    
    case(_,(DAE.EQBOUND(DAE.CREF(cr,_),NONE(),_,_)))
      then ComponentReference.crefEqual(c,cr);
    
    else false;
    
  end match;
end crefEqualValue;

protected function dimensionSliceInRange "
Checks that the values of a dimension slice is all in the range 1 to dim size
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
    
    case(Values.ARRAY(valueLst = Values.INTEGER(indx)::vlst, dimLst = dim::dims),_) 
      equation
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
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path opPath;
  input Option<Values.Value> inCurValue;
  input DAE.Exp exp;
  input DAE.Type exprType;
  input Option<DAE.Exp> foldExp;
  input list<String> iteratorNames;
  input list<list<Values.Value>> inValueMatrix;
  input list<DAE.Type> iterTypes;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Absyn.Msg msg;
  input Integer numIter;
  output Env.Cache newCache;
  output Option<Values.Value> result;
  output Option<GlobalScript.SymbolTable> newSymbolTable;
algorithm
  (newCache, result, newSymbolTable) := matchcontinue (inCache, inEnv, opPath, inCurValue, exp, exprType, foldExp, iteratorNames, inValueMatrix, iterTypes, impl, inSt, msg, numIter)
    local
      list<Values.Value> vals;
      Env.Env new_env,env;
      Env.Cache cache;
      list<Integer> dims;
      Option<GlobalScript.SymbolTable> st;
      list<list<Values.Value>> valueMatrix;
      Option<Values.Value> curValue;
      
    case (cache, _, Absyn.IDENT("listReverse"), SOME(Values.LIST(vals)), _, _, _, _, {}, _, _, st, _, _)
      equation
        vals = listReverse(vals);
      then (cache, SOME(Values.LIST(vals)), st);
    case (cache, _, Absyn.IDENT("array"), SOME(Values.ARRAY(vals,dims)), _, _, _, _, {}, _, _, st, _, _)
      then (cache, SOME(Values.ARRAY(vals,dims)), st);

    case (cache, _, _, curValue, _, _, _, _, {}, _, _, st, _, _)
      then (cache, curValue, st);

    case (cache, env, _, curValue, _, _, _, _, vals :: valueMatrix, _, _, st, _, _)
      equation
        // Bind the iterator
        // print("iterator: " +& iteratorName +& " => " +& ValuesUtil.valString(value) +& "\n");
        new_env = extendFrameForIterators(env, iteratorNames, vals, iterTypes);
        // Calculate var1 of the folding function
        (cache, curValue, st) = cevalReductionEvalAndFold(cache, new_env, opPath, curValue, exp, exprType, foldExp, impl, st,msg,numIter+1);
        // Fold the rest of the reduction
        (cache, curValue, st) = cevalReduction(cache, env, opPath, curValue, exp, exprType, foldExp, iteratorNames, valueMatrix, iterTypes, impl, st,msg,numIter);
      then (cache, curValue, st);
  end matchcontinue;
end cevalReduction;

protected function cevalReductionEvalAndFold "Evaluate the reduction body and fold"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path opPath;
  input Option<Values.Value> inCurValue;
  input DAE.Exp exp;
  input DAE.Type exprType;
  input Option<DAE.Exp> foldExp;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Absyn.Msg msg;
  input Integer numIter;
  output Env.Cache newCache;
  output Option<Values.Value> result;
  output Option<GlobalScript.SymbolTable> newSymbolTable;
algorithm
  (newCache,result,newSymbolTable) := match (inCache,inEnv,opPath,inCurValue,exp,exprType,foldExp,impl,inSt,msg,numIter)
    local
      Values.Value value;
      Option<Values.Value> curValue;
      Env.Cache cache;
      Env.Env env;
      Option<GlobalScript.SymbolTable> st;
      
    case (cache,env,_,curValue,_,_,_,_,st,_,_)
      equation
        (cache, value, st) = ceval(cache, env, exp, impl, st,msg,numIter+1);
        // print("cevalReductionEval: " +& ExpressionDump.printExpStr(exp) +& " => " +& ValuesUtil.valString(value) +& "\n");
        (cache, result, st) = cevalReductionFold(cache, env, opPath, curValue, value, foldExp, exprType, impl, st,msg,numIter);
      then (cache, result, st);
  end match;
end cevalReductionEvalAndFold;

protected function cevalReductionFold "Fold the reduction body"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path opPath;
  input Option<Values.Value> inCurValue;
  input Values.Value inValue;
  input Option<DAE.Exp> foldExp;
  input DAE.Type exprType;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Absyn.Msg msg;
  input Integer numIter;
  output Env.Cache newCache;
  output Option<Values.Value> result;
  output Option<GlobalScript.SymbolTable> newSymbolTable;
algorithm
  (newCache,result,newSymbolTable) := 
  match (inCache,inEnv,opPath,inCurValue,inValue,foldExp,exprType,impl,inSt,msg,numIter)
    local
      DAE.Exp exp;
      Values.Value value;
      Env.Cache cache;
      Env.Env env;
      Option<GlobalScript.SymbolTable> st;
      
    case (cache,_,Absyn.IDENT("array"),SOME(value),_,_,_,_,st,_,_)
      equation
        value = valueArrayCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value),st);
    case (cache,_,Absyn.IDENT("list"),SOME(value),_,_,_,_,st,_,_)
      equation
        value = valueCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value),st);
    case (cache,_,Absyn.IDENT("listReverse"),SOME(value),_,_,_,_,st,_,_)
      equation
        value = valueCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value),st);
    case (cache,env,_,NONE(),_,_,_,_,st,_,_)
      then (cache,SOME(inValue),st);

    case (cache,env,_,SOME(value),_,SOME(exp),_,_,st,_,_)
      equation
        // print("cevalReductionFold " +& ExpressionDump.printExpStr(exp) +& ", " +& ValuesUtil.valString(inValue) +& ", " +& ValuesUtil.valString(value) +& "\n");
        /* TODO: Store the actual types somewhere... */
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpA", exprType, DAE.VALBOUND(inValue, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpB", exprType, DAE.VALBOUND(value, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        (cache, value, st) = ceval(cache, env, exp, impl, st,msg,numIter+1);
      then (cache, SOME(value), st);
  end match;
end cevalReductionFold;

protected function valueArrayCons
  "Returns the cons of two values. Used by cevalReduction for array reductions."
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value res;
algorithm
  res := match(v1, v2)
    local
      list<Values.Value> vals;
      Integer dim_size;
      list<Integer> rest_dims;

    case (_, Values.ARRAY(valueLst = vals, dimLst = dim_size :: rest_dims))
      equation
        dim_size = dim_size + 1;
      then 
        Values.ARRAY(v1 :: vals, dim_size :: rest_dims);

    else then Values.ARRAY({v1, v2}, {2});
  end match;
end valueArrayCons;

protected function valueCons
  "Returns the cons of two values. Used by cevalReduction for list reductions."
  input Values.Value inV1;
  input Values.Value inV2;
  output Values.Value res;
algorithm
  res := match(inV1, inV2)
    local
      list<Values.Value> vals;
      Values.Value v1;

    case (Values.META_BOX(v1), Values.LIST(vals)) then Values.LIST(v1::vals);
    case (v1, Values.LIST(vals)) then Values.LIST(v1::vals);
  end match;
end valueCons;

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
  op := match(reductionName)
    case "array" then valueArrayCons;
    case "list" then valueCons;
    case "listReverse" then valueCons;
  end match;
end lookupReductionOp;

protected function cevalReductionIterators
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.ReductionIterator> inIterators;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Absyn.Msg msg;
  input Integer numIter;
  output Env.Cache outCache;
  output list<list<Values.Value>> vals;
  output list<String> names;
  output list<Integer> dims;
  output list<DAE.Type> tys;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,vals,names,dims,tys,outSt) := match (inCache,inEnv,inIterators,impl,inSt,msg,numIter)
    local
      Values.Value val;
      list<Values.Value> iterVals;
      Integer dim;
      DAE.Type ty;
      String id;
      DAE.Exp exp;
      Option<DAE.Exp> guardExp;
      Env.Cache cache;
      Env.Env env;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.ReductionIterator> iterators;
      
    case (cache,env,{},_,st,_,_) then (cache,{},{},{},{},st);
    case (cache,env,DAE.REDUCTIONITER(id,exp,guardExp,ty)::iterators,_,st,_,_)
      equation
        (cache,val,st) = ceval(cache,env,exp,impl,st,msg,numIter+1);
        iterVals = ValuesUtil.arrayOrListVals(val,true);
        (cache,iterVals,st) = filterReductionIterator(cache,env,id,ty,iterVals,guardExp,impl,st,msg,numIter);
        dim = listLength(iterVals);
        (cache,vals,names,dims,tys,st) = cevalReductionIterators(cache,env,iterators,impl,st,msg,numIter);
      then (cache,iterVals::vals,id::names,dim::dims,ty::tys,st);
  end match;
end cevalReductionIterators;

protected function filterReductionIterator
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String id;
  input DAE.Type ty;
  input list<Values.Value> inVals;
  input Option<DAE.Exp> guardExp;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Absyn.Msg msg;
  input Integer numIter;
  output Env.Cache outCache;
  output list<Values.Value> outVals;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,outVals,outSt) := match (inCache,inEnv,id,ty,inVals,guardExp,impl,inSt,msg,numIter)
    local
      DAE.Exp exp;
      Values.Value val;
      Boolean b;
      Env.Env new_env,env;
      Env.Cache cache;
      list<Values.Value> vals;
      Option<GlobalScript.SymbolTable> st;
    
   case (cache,env,_,_,{},_,_,st,_,_) then (cache,{},st);
    case (cache,env,_,_,val::vals,SOME(exp),_,st,_,_)
      equation
        new_env = Env.extendFrameForIterator(env, id, ty, DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        (cache,Values.BOOL(b),st) = ceval(cache,new_env,exp,impl,st,msg,numIter+1);
        (cache,vals,st) = filterReductionIterator(cache,env,id,ty,vals,guardExp,impl,st,msg,numIter);
        vals = Util.if_(b, val::vals, vals);
      then (cache,vals,st);
    case (cache,env,_,_,vals,NONE(),_,st,_,_) then (cache,vals,st);
  end match;
end filterReductionIterator;

protected function extendFrameForIterators
  input Env.Env inEnv;
  input list<String> inNames;
  input list<Values.Value> inVals;
  input list<DAE.Type> inTys;
  output Env.Env outEnv;
algorithm
  outEnv := match (inEnv,inNames,inVals,inTys)
    local
      String name;
      Values.Value val;
      DAE.Type ty;
      Env.Env env;
      list<String> names;
      list<Values.Value> vals;
      list<DAE.Type> tys;

    case (env,{},{},{}) then env;
    case (env,name::names,val::vals,ty::tys)
      equation
        env = Env.extendFrameForIterator(env, name, ty, DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        env = extendFrameForIterators(env,names,vals,tys);
      then env;
  end match;
end extendFrameForIterators;

protected function backpatchArrayReduction
  input Absyn.Path path;
  input Values.Value inValue;
  input list<Integer> dims;
  output Values.Value outValue;
algorithm
  outValue := match (path,inValue,dims)
    local
      list<Values.Value> vals;
      Values.Value value;
    case (_,value,{_}) then value;
    case (Absyn.IDENT("array"),Values.ARRAY(valueLst=vals),_)
      equation
        value = backpatchArrayReduction3(vals,listReverse(dims));
        // print(ValuesUtil.valString(value));print("\n");
      then value;
    else inValue;
  end match;
end backpatchArrayReduction;

protected function backpatchArrayReduction3
  input list<Values.Value> inVals;
  input list<Integer> inDims;
  output Values.Value outValue;
algorithm
  outValue := match (inVals,inDims)
    local
      Integer dim;
      list<list<Values.Value>> valMatrix;
      Values.Value value;
      list<Values.Value> vals;
      list<Integer> dims;
      
    case (vals,{dim}) then ValuesUtil.makeArray(vals);
    case (vals,dim::dims)
      equation
        // Split into the smallest of the arrays
        // print("into sublists of length: " +& intString(dim) +& " from length=" +& intString(listLength(vals)) +& "\n");
        valMatrix = List.partition(vals,dim);
        // print("output has length=" +& intString(listLength(valMatrix)) +& "\n");
        vals = List.map(valMatrix,ValuesUtil.makeArray);
        value = backpatchArrayReduction3(vals,dims);
      then value;
  end match;
end backpatchArrayReduction3;

public function cevalSimple
  "A simple expression does not need cache, etc"
  input DAE.Exp exp;
  output Values.Value val;
algorithm
  (_,val,_) := ceval(Env.emptyCache(),{},exp,false,NONE(),Absyn.MSG(Absyn.dummyInfo),0);
end cevalSimple;

public function cevalAstExp
"Part of meta-programming using CODE.
  This function evaluates a piece of Expression AST, replacing Eval(variable)
  with the value of the variable, given that it is of type \"Expression\".

  Example: y = Code(1 + x)
           2 + 5  ( x + Eval(y) )  =>   2 + 5  ( x + 1 + x )"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Exp e,e1_1,e2_1,e1,e2,e_1,cond_1,then_1,else_1,cond,then_,else_,exp,e3_1,e3;
      list<Env.Frame> env;
      Absyn.Operator op;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      list<tuple<Absyn.Exp, Absyn.Exp>> nest_1,nest;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fa;
      list<Absyn.Exp> expl_1,expl;
      Env.Cache cache;
      DAE.Exp daeExp;
      list<list<Absyn.Exp>> lstExpl_1,lstExpl;

    case (cache,_,(e as Absyn.INTEGER(value = _)),_,_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.REAL(value = _)),_,_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.CREF(componentRef = _)),_,_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.STRING(value = _)),_,_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.BOOL(value = _)),_,_,_,_) then (cache,e);
    
    case (cache,env,Absyn.BINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
      then
        (cache,Absyn.BINARY(e1_1,op,e2_1));
    
    case (cache,env,Absyn.UNARY(op = op,exp = e),impl,st,msg,_)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
      then
        (cache,Absyn.UNARY(op,e_1));
    
    case (cache,env,Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
      then
        (cache,Absyn.LBINARY(e1_1,op,e2_1));
    
    case (cache,env,Absyn.LUNARY(op = op,exp = e),impl,st,msg,_)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
      then
        (cache,Absyn.LUNARY(op,e_1));
    
    case (cache,env,Absyn.RELATION(exp1 = e1,op = op,exp2 = e2),impl,st,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
      then
        (cache,Absyn.RELATION(e1_1,op,e2_1));
    
    case (cache,env,Absyn.IFEXP(ifExp = cond,trueBranch = then_,elseBranch = else_,elseIfBranch = nest),impl,st,msg,_)
      equation
        (cache,cond_1) = cevalAstExp(cache,env, cond, impl, st, msg, info);
        (cache,then_1) = cevalAstExp(cache,env, then_, impl, st, msg, info);
        (cache,else_1) = cevalAstExp(cache,env, else_, impl, st, msg, info);
        (cache,nest_1) = cevalAstExpexpList(cache,env, nest, impl, st, msg, info);
      then
        (cache,Absyn.IFEXP(cond_1,then_1,else_1,nest_1));
    
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "Eval",subscripts = {}),functionArgs = Absyn.FUNCTIONARGS(args = {e},argNames = {})),impl,st,msg,_)
      equation
        (cache,daeExp,_,_) = Static.elabExp(cache, env, e, impl, st, true, Prefix.NOPRE(), info);
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp)),_) = ceval(cache, env, daeExp, impl, st,msg,0);
      then
        (cache,exp);
    
    case (cache,env,(e as Absyn.CALL(function_ = cr,functionArgs = fa)),_,_,msg,_) then (cache,e);
    
    case (cache,env,Absyn.ARRAY(arrayExp = expl),impl,st,msg,_)
      equation
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg, info);
      then
        (cache,Absyn.ARRAY(expl_1));
    
    case (cache,env,Absyn.MATRIX(matrix = lstExpl),impl,st,msg,_)
      equation
        (cache,lstExpl_1) = cevalAstExpListList(cache, env, lstExpl, impl, st, msg, info);
      then
        (cache,Absyn.MATRIX(lstExpl_1));
    
    case (cache,env,Absyn.RANGE(start = e1,step = SOME(e2),stop = e3),impl,st,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg, info);
      then
        (cache,Absyn.RANGE(e1_1,SOME(e2_1),e3_1));
    
    case (cache,env,Absyn.RANGE(start = e1,step = NONE(),stop = e3),impl,st,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg, info);
      then
        (cache,Absyn.RANGE(e1_1,NONE(),e3_1));
    
    case (cache,env,Absyn.TUPLE(expressions = expl),impl,st,msg,_)
      equation
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg, info);
      then
        (cache,Absyn.TUPLE(expl_1));
    
    case (cache,env,Absyn.END(),_,_,msg,_) then (cache,Absyn.END());
    
    case (cache,env,(e as Absyn.CODE(code = _)),_,_,msg,_) then (cache,e);

  end matchcontinue;
end cevalAstExp;

public function cevalAstExpList
"List version of cevalAstExp"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm
  (outCache,outAbsynExpLst) :=
  match (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Absyn.Msg msg;
      Absyn.Exp e_1,e;
      list<Absyn.Exp> res,es;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Env.Cache cache;
    
    case (cache,env,{},_,_,msg,_) then (cache,{});
    
    case (cache,env,(e :: es),impl,st,msg,_)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
        (cache,res) = cevalAstExpList(cache,env, es, impl, st, msg, info);
      then
        (cache,e :: res);
  end match;
end cevalAstExpList;

protected function cevalAstExpListList "function: cevalAstExpListList"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm
  (outCache,outAbsynExpLstLst) :=
  match (inCache,inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Absyn.Msg msg;
      list<Absyn.Exp> e_1,e;
      list<list<Absyn.Exp>> res,es;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Env.Cache cache;
    
    case (cache,env,{},_,_,msg,_) then (cache,{});
    
    case (cache,env,(e :: es),impl,st,msg,_)
      equation
        (cache,e_1) = cevalAstExpList(cache,env, e, impl, st, msg, info);
        (cache,res) = cevalAstExpListList(cache,env, es, impl, st, msg, info);
      then
        (cache,e :: res);
  end match;
end cevalAstExpListList;

public function cevalAstElt
"Evaluates an ast constructor for Element nodes, e.g.
  Code(parameter Real x=1;)"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Element outElement;
algorithm
  (outCache,outElement) :=
  match (inCache,inEnv,inElement,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      list<Env.Frame> env;
      Boolean f,isReadOnly,impl;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String file;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.Info info;
      Integer sline,scolumn,eline,ecolumn;
      Option<Absyn.ConstrainClass> c;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = citems),info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scolumn,lineNumberEnd = eline,columnNumberEnd = ecolumn)),constrainClass = c),impl,st,msg)
      equation
        (cache,citems_1) = cevalAstCitems(cache,env, citems, impl, st, msg, info);
      then
        (cache,Absyn.ELEMENT(f,r,io,Absyn.COMPONENTS(attr,tp,citems_1),info,c));
  end match;
end cevalAstElt;

protected function cevalAstCitems
"Helper function to cevalAstElt."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  (outCache,outAbsynComponentItemLst) :=
  matchcontinue (inCache,inEnv,inAbsynComponentItemLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Msg msg;
      list<Absyn.ComponentItem> res,xs;
      Option<Absyn.Modification> modopt_1,modopt;
      list<Absyn.Subscript> ad_1,ad;
      list<Env.Frame> env;
      String id;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.ComponentItem x;
      Env.Cache cache;
    case (cache,_,{},_,_,msg,_) then (cache,{});
    case (cache,env,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = modopt),condition = cond,comment = cmt) :: xs),impl,st,msg,_) /* If one component fails, the rest should still succeed */
      equation
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg, info);
        (cache,modopt_1) = cevalAstModopt(cache,env, modopt, impl, st, msg, info);
        (cache,ad_1) = cevalAstArraydim(cache,env, ad, impl, st, msg, info);
      then
        (cache,Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad_1,modopt_1),cond,cmt) :: res);
    case (cache,env,(x :: xs),impl,st,msg,_) /* If one component fails, the rest should still succeed */
      equation
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg, info);
      then
        (cache,x :: res);
  end matchcontinue;
end cevalAstCitems;

protected function cevalAstModopt
"function: cevalAstModopt"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  (outCache,outAbsynModificationOption) :=
  match (inCache,inEnv,inAbsynModificationOption,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Modification res,mod;
      list<Env.Frame> env;
      Boolean st;
      Option<GlobalScript.SymbolTable> impl;
      Absyn.Msg msg;
      Env.Cache cache;
    case (cache,env,SOME(mod),st,impl,msg,_)
      equation
        (cache,res) = cevalAstModification(cache,env, mod, st, impl, msg, info);
      then
        (cache,SOME(res));
    case (cache,env,NONE(),_,_,msg,_) then (cache,NONE());
  end match;
end cevalAstModopt;

protected function cevalAstModification "This function evaluates Eval(variable) inside an AST Modification  and replaces
  the Eval operator with the value of the variable if it has a type \"Expression\""
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Modification inModification;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Absyn.Modification outModification;
algorithm
  (outCache,outModification) :=
  match (inCache,inEnv,inModification,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Exp e_1,e;
      list<Absyn.ElementArg> eltargs_1,eltargs;
      list<Env.Frame> env;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Msg msg;
      Env.Cache cache;
      Absyn.Info info2;
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,eqMod = Absyn.EQMOD(e,info2)),impl,st,msg,_)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg, info);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,Absyn.EQMOD(e_1,info2)));
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,eqMod = Absyn.NOMOD()),impl,st,msg,_)
      equation
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg, info);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,Absyn.NOMOD()));
  end match;
end cevalAstModification;

protected function cevalAstEltargs "Helper function to cevalAstModification."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  (outCache,outAbsynElementArgLst):=
  matchcontinue (inCache,inEnv,inAbsynElementArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Absyn.Msg msg;
      Absyn.Modification mod_1,mod;
      list<Absyn.ElementArg> res,args;
      Boolean b,impl;
      Absyn.Each e;
      Option<String> stropt;
      Option<GlobalScript.SymbolTable> st;
      Absyn.ElementArg m;
      Env.Cache cache;
      Absyn.Info mod_info;
      Absyn.Path p;

    case (cache,env,{},_,_,msg,_) then (cache,{});
    /* TODO: look through redeclarations for Eval(var) as well */
    case (cache,env,(Absyn.MODIFICATION(finalPrefix = b,eachPrefix = e,path = p,modification = SOME(mod),comment = stropt, info = mod_info) :: args),impl,st,msg,_)
      equation
        (cache,mod_1) = cevalAstModification(cache,env, mod, impl, st, msg, info);
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg, info);
      then
        (cache,Absyn.MODIFICATION(b,e,p,SOME(mod_1),stropt,mod_info) :: res);
    case (cache,env,(m :: args),impl,st,msg,_) /* TODO: look through redeclarations for Eval(var) as well */
      equation
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg, info);
      then
        (cache,m :: res);
  end matchcontinue;
end cevalAstEltargs;

protected function cevalAstArraydim "Helper function to cevaAstCitems"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Absyn.ArrayDim outArrayDim;
algorithm
  (outCache,outArrayDim) :=
  match (inCache,inEnv,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      list<Env.Frame> env;
      Absyn.Msg msg;
      list<Absyn.Subscript> res,xs;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Exp e_1,e;
      Env.Cache cache;
    case (cache,env,{},_,_,msg,_) then (cache,{});
    case (cache,env,(Absyn.NOSUB() :: xs),impl,st,msg,_)
      equation
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg, info);
      then
        (cache,Absyn.NOSUB() :: res);
    case (cache,env,(Absyn.SUBSCRIPT(subscript = e) :: xs),impl,st,msg,_)
      equation
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg, info);
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg, info);
      then
        (cache,Absyn.SUBSCRIPT(e) :: res);
  end match;
end cevalAstArraydim;

protected function cevalAstExpexpList
"For IFEXP"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Absyn.Msg inMsg;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm
  (outCache,outTplAbsynExpAbsynExpLst) :=
  match (inCache,inEnv,inTplAbsynExpAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg,info)
    local
      Absyn.Msg msg;
      Absyn.Exp e1_1,e2_1,e1,e2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res,xs;
      list<Env.Frame> env;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      Env.Cache cache;
    case (cache,_,{},_,_,msg,_) then (cache,{});
    case (cache,env,((e1,e2) :: xs),impl,st,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg, info);
        (cache,res) = cevalAstExpexpList(cache,env, xs, impl, st, msg, info);
      then
        (cache,(e1_1,e2_1) :: res);
  end match;
end cevalAstExpexpList;

public function cevalDimension
  "Constant evaluates a dimension, returning the size of the dimension as a value."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Dimension inDimension;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache, outValue, outST) :=
  match(inCache, inEnv, inDimension, inImpl, inST, inMsg, numIter)
    local
      Integer dim_int;
      DAE.Exp exp;
      Env.Cache cache;
      Values.Value res;
      Option<GlobalScript.SymbolTable> st;

    // Integer dimension, already constant.
    case (_, _, DAE.DIM_INTEGER(integer = dim_int), _, _, _, _)
      then (inCache, Values.INTEGER(dim_int), inST);

    // Enumeration dimension, already constant.
    case (_, _, DAE.DIM_ENUM(size = dim_int), _, _, _, _)
      then (inCache, Values.INTEGER(dim_int), inST);

    case (_, _, DAE.DIM_BOOLEAN(), _, _, _, _)
      then (inCache, Values.INTEGER(2), inST);

    // Dimension given by expression, evaluate the expression.
    case (_, _, DAE.DIM_EXP(exp = exp), _, _, _, _)
      equation
        (cache, res, st) = ceval(inCache, inEnv, exp, inImpl, inST, inMsg, numIter+1);
      then
        (cache, res, st);

  end match;
end cevalDimension;
        
end Ceval;

