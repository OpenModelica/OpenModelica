/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Ceval
" file:        Ceval.mo
  package:     Ceval
  description: Constant propagation of expressions


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
public import FCore;
public import FGraph;
public import FNode;
public import InstTypes;
public import Values;
public import Lookup;

// protected imports
protected
import AvlTreeStringString;
protected import BackendInterface;
protected import ComponentReference;
protected import Config;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import InstBinding;
protected import InstUtil;
protected import List;
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
protected import Global;
protected import MetaModelica.Dangerous.listReverseInPlace;

public function ceval "
  This function is used when the value of a constant expression is
  needed.  It takes an environment and an expression and calculates
  its value.
  The third argument indicates whether the evaluation is performed in the
  interactive environment (implicit instantiation), in which case function
  calls are evaluated.
  The last argument is an optional dimension."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg = Absyn.NO_MSG();
  input Integer numIter = 0 "Maximum recursion depth";
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := cevalWork1(inCache,inEnv,inExp,inBoolean,inMsg,numIter,numIter > Global.recursionDepthLimit);
end ceval;

protected function cevalWork1
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter "Maximum recursion depth";
  input Boolean iterReached;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := match (inCache,inEnv,inExp,inBoolean,inMsg,numIter,iterReached)
    local
      SourceInfo info;
      String str1,str2,str3;
    case (_,_,_,_,_,_,false)
      equation
        (outCache,outValue) = cevalWork2(inCache,inEnv,inExp,inBoolean,inMsg,numIter);
      then (outCache,outValue);
    case (_,_,_,_,Absyn.MSG(info=info),_,true)
      equation
        str1 = intString(Global.recursionDepthLimit);
        str2 = ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.RECURSION_DEPTH_WARNING, {str1,str2,FGraph.printGraphPathStr(inEnv)}, info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;

  partial function ReductionOperator
    input Values.Value v1;
    input Values.Value v2;
    output Values.Value res;
  end ReductionOperator;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inMsg,numIter)
    local
      Integer start_1,stop_1,step_1,i,indx_1,indx,index;
      Real lhvReal,rhvReal,sum,r,realStart1,realStop1,realStep1;
      String str,lhvStr,rhvStr,s,foldName,resultName;
      Boolean impl,b,b_1,lhvBool,rhvBool,resBool, bstart, bstop;
      Absyn.Exp exp_1,exp;
      FCore.Graph env;
      Absyn.Msg msg;
      Absyn.Element elt_1,elt;
      Absyn.CodeNode c;
      list<Values.Value> es_1,elts,vallst,vlst1,vlst2,reslst,aval,rhvals,lhvals,arr,arr_1,ivals,rvals,vals;
      list<DAE.Exp> es,expl;
      list<list<DAE.Exp>> expll;
      Values.Value v,newval,value,sval,elt1,elt2,v_1,lhs_1,rhs_1,resVal,lhvVal,rhvVal;
      DAE.Exp lh,rh,e,lhs,rhs,start,stop,step,e1,e2,cond;
      Absyn.Path funcpath, name, recName;
      DAE.Operator relop;
      FCore.Cache cache;
      DAE.Exp expExp;
      list<Integer> dims;
      DAE.Dimensions arrayDims;
      DAE.ComponentRef cr;
      list<String> fieldNames, n, names;
      DAE.Type t;
      DAE.Exp daeExp;
      Absyn.Path path;
      Option<Values.Value> ov;
      Option<DAE.Exp> foldExp;
      DAE.Type ty;
      list<DAE.Type> tys;
      DAE.ReductionIterators iterators;
      list<list<Values.Value>> valMatrix;
      SourceInfo info;
      list<Values.Value> orderd;
      list<String> comp;
      DAE.ClockKind ck;
      Absyn.ReductionIterType iterType;

    // uncomment for debugging
    // case (cache,env,inExp,_,_,_)
    //   equation print("Ceval.ceval: " + ExpressionDump.printExpStr(inExp) + " in env: " + FGraph.printGraphPathStr(env) + "\n");
    //   then fail();

    case (cache,_,DAE.ICONST(integer = i),_,_,_) then (cache,Values.INTEGER(i));

    case (cache,_,DAE.RCONST(real = r),_,_,_) then (cache,Values.REAL(r));

    case (cache,_,DAE.SCONST(string = s),_,_,_) then (cache,Values.STRING(s));

    case (cache,_,DAE.BCONST(bool = b),_,_,_) then (cache,Values.BOOL(b));

    case (cache,_,DAE.ENUM_LITERAL(name = name, index = i),_,_,_)
      then (cache, Values.ENUM_LITERAL(name, i));

    case (cache,env,DAE.CODE(code = Absyn.C_EXPRESSION(exp = exp)),impl,msg,_)
      equation
        (cache, exp_1) = cevalAstExp(cache, env, exp, impl, msg, Absyn.dummyInfo);
      then
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp_1)));

    case (cache,env,DAE.CODE(code = Absyn.C_ELEMENT(element = elt)),impl,msg,_)
      equation
        (cache,elt_1) = cevalAstElt(cache,env, elt, impl, msg);
      then
        (cache,Values.CODE(Absyn.C_ELEMENT(elt_1)));

    case (cache,_,DAE.CODE(code = c),_,_,_) then (cache,Values.CODE(c));

    case (cache,env,DAE.ARRAY(array = es, ty = DAE.T_ARRAY(dims = arrayDims)),impl,msg,_)
      equation
        (cache, es_1) = cevalList(cache, env, es, impl, msg, numIter);
        v =
        matchcontinue()
          case ()
            equation
              dims = List.map(arrayDims, Expression.dimensionSize);
              v = Values.ARRAY(es_1,dims);
            then v;
          else
            equation
              v = ValuesUtil.makeArray(es_1);
            then
              v;
        end matchcontinue;
      then
        (cache,v);

    case (cache,env,DAE.MATRIX(matrix = expll, ty = DAE.T_ARRAY(dims = arrayDims)),impl,msg,_)
      equation
        dims = List.map(arrayDims, Expression.dimensionSize);
        (cache,elts) = cevalMatrixElt(cache, env, expll, impl,msg,numIter+1);
      then
        (cache,Values.ARRAY(elts,dims));

    // MetaModelica
    case (cache,env,DAE.LIST(valList = expl),impl,msg,_)
      equation
        (cache,es_1) = cevalList(cache,env, expl, impl, msg,numIter);
      then
        (cache,Values.LIST(es_1));

    case (cache,env,DAE.BOX(exp=e1),impl,msg,_)
      equation
        (cache,v) = ceval(cache,env,e1,impl,msg,numIter+1);
      then
        (cache,v);

    case (cache,env,DAE.UNBOX(exp=e1),impl,msg,_)
      equation
        (cache,Values.META_BOX(v)) = ceval(cache,env,e1,impl,msg,numIter+1);
      then
        (cache,v);

    case (cache,env,DAE.CONS(car=e1,cdr=e2),impl,msg,_)
      equation
        (cache,v) = ceval(cache,env,e1,impl,msg,numIter+1);
        (cache,Values.LIST(vallst)) = ceval(cache,env,e2,impl,msg,numIter);
      then
        (cache,Values.LIST(v::vallst));

    // MetaModelica Partial Function
    case (_,_,DAE.CREF(componentRef = cr,
        ty = DAE.T_FUNCTION_REFERENCE_VAR()),_,Absyn.MSG(info = info),_)
      equation
        str = ComponentReference.crefStr(cr);
        Error.addSourceMessage(Error.META_CEVAL_FUNCTION_REFERENCE, {str}, info);
      then
        fail();

    case (_,_,DAE.CREF(componentRef = cr, ty = DAE.T_FUNCTION_REFERENCE_FUNC()),
        _, Absyn.MSG(info = info),_)
      equation
        str = ComponentReference.crefStr(cr);
        Error.addSourceMessage(Error.META_CEVAL_FUNCTION_REFERENCE, {str}, info);
      then
        fail();

    // MetaModelica Uniontype Constructor
    case (cache,env,DAE.METARECORDCALL(path=funcpath,args=expl,fieldNames=fieldNames,index=index),impl,msg,_)
      equation
        (cache,vallst) = cevalList(cache, env, expl, impl, msg,numIter);
      then (cache,Values.RECORD(funcpath,vallst,fieldNames,index));

    // MetaModelica Option type. sjoelund 2009-07-01
    case (cache,_,DAE.META_OPTION(NONE()),_,_,_)
      then (cache,Values.OPTION(NONE()));
    case (cache,env,DAE.META_OPTION(SOME(expExp)),impl,msg,_)
      equation
        (cache,value) = ceval(cache,env,expExp,impl,msg,numIter+1);
      then (cache,Values.OPTION(SOME(value)));

    // MetaModelica Tuple. sjoelund 2009-07-02
    case (cache,env,DAE.META_TUPLE(expl),impl,msg,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,vallst) = cevalList(cache, env, expl, impl, msg,numIter);
      then (cache,Values.META_TUPLE(vallst));

    case (cache,env,DAE.TUPLE(expl),impl,msg,_)
      equation
        // true = Config.acceptMetaModelicaGrammar();
        (cache,vallst) = cevalList(cache, env, expl, impl, msg,numIter);
      then (cache,Values.TUPLE(vallst));

    case (cache,env,DAE.CREF(componentRef = cr),(false),msg,_)
      equation
        (cache,v) = cevalCref(cache, env, cr, false, msg, numIter+1) "When in interactive mode, always evaluate crefs, i.e non-implicit mode.." ;
        //Debug.traceln("cevalCref cr: " + ComponentReference.printComponentRefStr(c) + " in s: " + FGraph.printGraphPathStr(env) + " v:" + ValuesUtil.valString(v));
      then
        (cache,v);

    case (cache,env,DAE.CREF(componentRef = cr),impl,msg,_)
      equation
        (cache,v) = cevalCref(cache,env, cr, impl,msg,numIter+1);
        //Debug.traceln("cevalCref cr: " + ComponentReference.printComponentRefStr(c) + " in s: " + FGraph.printGraphPathStr(env) + " v:" + ValuesUtil.valString(v));
      then
        (cache,v);

    // Evaluates for build in types. ADD, SUB, MUL, DIV for Reals and Integers.
    case (cache,env,expExp,impl,msg,_)
      equation
        (cache,v) = cevalBuiltin(cache,env, expExp, impl, msg,numIter+1);
      then
        (cache,v);

    // ceval smooth(0, expr) -> expr
    case (cache, env, (DAE.CALL(path=funcpath, expLst={DAE.ICONST(0), expExp}, attr=DAE.CALL_ATTR(isImpure=false))), impl, msg,_)
      equation
        Absyn.IDENT("smooth") = Absyn.makeNotFullyQualified(funcpath);
        (cache,value) = ceval(cache,env,expExp,impl,msg,numIter+1);
      then
        (cache,value);

    // adrpo: TODO! this needs more work as if we don't have a symtab we run into unloading of dlls problem
    // lochel: do not evaluate impure function calls
    case (cache, env, (e as DAE.CALL(path=funcpath, expLst=expl, attr=DAE.CALL_ATTR(isImpure=false))), impl, msg,_)
      equation
        // do not handle Connection.isRoot here!
        false = Absyn.pathEqual(Absyn.QUALIFIED("Connection",Absyn.IDENT("isRoot")), funcpath);
        // do not roll back errors generated by evaluating the arguments
        (cache, vallst) = cevalList(cache, env, expl, impl, msg,numIter);
        (cache, newval)= BackendInterface.cevalCallFunction(cache, env, e, vallst, impl, msg,numIter+1);
      then
        (cache,newval);

    // Cast of records  (Check done by static, so ok to just evaluate the expression and return)
    case(cache,env,DAE.CAST(ty = ty,exp = e),impl,msg,_)
      equation
        true = Types.isRecord(ty);
        (cache,value) = ceval(cache, env, e, impl, msg, numIter+1);
      then (cache,value);

    // Try Interactive functions last
    case (cache,env,(e as DAE.CALL()),(true),msg,_)
      equation
        (cache,value) = BackendInterface.cevalInteractiveFunctions(cache, env, e, msg,numIter+1);
      then
        (cache,value);

    case (_,_,e as DAE.CALL(),_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Ceval.ceval DAE.CALL failed: ");
        str = ExpressionDump.printExpStr(e);
        Debug.traceln(str);
      then
        fail();

    case (cache, env, DAE.RECORD(path=funcpath, exps=expl, comp = fieldNames), impl, msg,_)
      equation
        (cache, vallst) = cevalList(cache, env, expl, impl, msg,numIter);
      then
        (cache,Values.RECORD(funcpath,vallst,fieldNames,-1));

    // Strings
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.T_STRING()),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.STRING(lhvStr)) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.STRING(rhvStr)) = ceval(cache,env, rh, impl, msg,numIter);
        str = stringAppend(lhvStr, rhvStr);
      then
        (cache,Values.STRING(str));

    // Numerical
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(ty = DAE.T_REAL()),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.REAL(lhvReal)) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.REAL(rhvReal)) = ceval(cache,env, rh, impl, msg,numIter);
        sum = lhvReal + rhvReal;
      then
        (cache,Values.REAL(sum));

    // Array addition
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARR(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(vlst2,_)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.addElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array subtraction
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_ARR(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(vlst2,_)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.subElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array multiplication
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARR(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(vlst2,_)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.mulElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array division
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARR(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(vlst2,_)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.divElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array power
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARR2(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(vlst1,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(vlst2,_)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.powElementwiseArrayelt(vlst1, vlst2);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array multipled scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_ARRAY_SCALAR(),exp2 = rh),impl,msg,_)
      equation
        (cache,sval) = ceval(cache,env, rh, impl, msg,numIter);
        (cache,Values.ARRAY(aval,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        reslst = ValuesUtil.multScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array add scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD_ARRAY_SCALAR(),exp2 = rh),impl,msg,_)
      equation
        (cache,sval) = ceval(cache,env, rh, impl, msg,numIter);
        (cache,Values.ARRAY(aval,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        reslst = ValuesUtil.addScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array subtract scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB_SCALAR_ARRAY(),exp2 = rh),impl,msg,_)
      equation
        (cache,sval) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(aval,dims)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.subScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_SCALAR_ARRAY(),exp2 = rh),impl,msg,_)
      equation
        (cache,sval) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(aval,dims)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.powScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims));

    // Array power scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW_ARRAY_SCALAR(),exp2 = rh),impl,msg,_)
      equation
        (cache,sval) = ceval(cache,env, rh, impl, msg,numIter);
        (cache,Values.ARRAY(aval,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        reslst = ValuesUtil.powArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims));

    // scalar div array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_SCALAR_ARRAY(),exp2 = rh),impl,msg,_)
      equation
        (cache,sval) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,Values.ARRAY(aval,dims)) = ceval(cache,env, rh, impl, msg,numIter);
        reslst = ValuesUtil.divScalarArrayelt(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims));

    // array div scalar
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV_ARRAY_SCALAR(),exp2 = rh),impl,msg,_)
      equation
        (cache,sval) = ceval(cache,env, rh, impl, msg,numIter+1);
        (cache,Values.ARRAY(aval,dims)) = ceval(cache,env, lh, impl, msg,numIter);
        reslst = ValuesUtil.divArrayeltScalar(sval, aval);
      then
        (cache,Values.ARRAY(reslst,dims));

    // scalar multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_SCALAR_PRODUCT(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(valueLst = rhvals)) = ceval(cache,env, rh, impl, msg,numIter);
        (cache,Values.ARRAY(valueLst = lhvals)) = ceval(cache,env, lh, impl, msg,numIter);
        resVal = ValuesUtil.multScalarProduct(rhvals, lhvals);
      then
        (cache,resVal);

    // array multipled array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(valueLst = (lhvals as (elt1 :: _)))) = ceval(cache,env, lh, impl, msg,numIter) "{{..}..{..}}  {...}" ;
        (cache,Values.ARRAY(valueLst = (rhvals as (elt2 :: _)))) = ceval(cache,env, rh, impl, msg,numIter);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        resVal = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,resVal);

    // array multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY(valueLst = (rhvals as (elt1 :: _)))) = ceval(cache,env, rh, impl, msg,numIter) "{...}  {{..}..{..}}" ;
        (cache,Values.ARRAY(valueLst = (lhvals as (elt2 :: _)))) = ceval(cache,env, lh, impl, msg,numIter);
        true = ValuesUtil.isArray(elt1);
        false = ValuesUtil.isArray(elt2);
        resVal = ValuesUtil.multScalarProduct(lhvals, rhvals);
      then
        (cache,resVal);

    // array multiplied array
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL_MATRIX_PRODUCT(),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.ARRAY((rhvals as (elt1 :: _)),_)) = ceval(cache,env, rh, impl, msg,numIter+1) "{{..}..{..}}  {{..}..{..}}" ;
        (cache,Values.ARRAY((lhvals as (elt2 :: _)),_)) = ceval(cache,env, lh, impl, msg,numIter+1);
        true = ValuesUtil.isArray(elt1);
        true = ValuesUtil.isArray(elt2);
        vallst = ValuesUtil.multMatrix(lhvals, rhvals);
      then
        (cache,ValuesUtil.makeArray(vallst));

    //POW (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.POW(),exp2 = rh),impl,msg,_)
      equation
        (cache,lhvVal) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,rhvVal) = ceval(cache,env, rh, impl, msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.POWOP());
      then
        (cache,resVal);

    //MUL (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.MUL(),exp2 = rh),impl,msg,_)
      equation
        (cache,lhvVal) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,rhvVal) = ceval(cache,env, rh, impl, msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.MULOP());
      then
        (cache,resVal);

    //DIV (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(),exp2 = rh),impl,msg,_)
      equation
        (cache,lhvVal) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,rhvVal) = ceval(cache,env, rh, impl, msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.DIVOP());
      then
        (cache,resVal);

    //DIV (handle div by zero)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.DIV(), exp2 = rh),
        impl, msg as Absyn.MSG(info = info),_)
      equation
        (_,lhvVal) = ceval(cache,env, rh, impl, msg,numIter);
        true = ValuesUtil.isZero(lhvVal);
        lhvStr = ExpressionDump.printExpStr(lh);
        rhvStr = ExpressionDump.printExpStr(rh);
        Error.addSourceMessage(Error.DIVISION_BY_ZERO, {lhvStr,rhvStr}, info);
      then
        fail();

    //ADD (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.ADD(),exp2 = rh),impl,msg,_)
      equation
        (cache,lhvVal) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,rhvVal) = ceval(cache,env, rh, impl, msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.ADDOP());
      then
        (cache,resVal);

    //SUB (integer or real)
    case (cache,env,DAE.BINARY(exp1 = lh,operator = DAE.SUB(),exp2 = rh),impl,msg,_)
      equation
        (cache,lhvVal) = ceval(cache,env, lh, impl, msg,numIter);
        (cache,rhvVal) = ceval(cache,env, rh, impl, msg,numIter);
        resVal = ValuesUtil.safeIntRealOp(lhvVal, rhvVal, Values.SUBOP());
      then
        (cache,resVal);

    //  unary minus of array
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS_ARR(),exp = daeExp),impl,msg,_)
      equation
        (cache,Values.ARRAY(arr,dims)) = ceval(cache,env, daeExp, impl, msg,numIter+1);
        arr_1 = List.map(arr, ValuesUtil.valueNeg);
      then
        (cache,Values.ARRAY(arr_1,dims));

    // unary minus of expression
    case (cache,env,DAE.UNARY(operator = DAE.UMINUS(),exp = daeExp),impl,msg,_)
      equation
        (cache,v) = ceval(cache,env, daeExp, impl, msg,numIter+1);
        v_1 = ValuesUtil.valueNeg(v);
      then
        (cache,v_1);

    // Logical lhs AND rhs (handle lhs = false)
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.AND(_),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.BOOL(lhvBool)) = ceval(cache,env, lh, impl, msg,numIter);
        if not lhvBool then
          v = Values.BOOL(false);
        else
          (cache,Values.BOOL(rhvBool)) = ceval(cache,env, rh, impl, msg,numIter);
          resBool = boolAnd(lhvBool, rhvBool);
          v = Values.BOOL(resBool);
        end if;
      then
        (cache,v);

    // lhs OR rhs (handle lhs = true)
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,msg,_)
      equation
        (cache,Values.BOOL(lhvBool)) = ceval(cache, env, lh, impl, msg, numIter);
        if lhvBool then
          v = Values.BOOL(true);
        else
          (cache,Values.BOOL(rhvBool)) = ceval(cache, env, rh, impl,  msg, numIter);
          resBool = boolOr(lhvBool, rhvBool);
          v = Values.BOOL(resBool);
        end if;
      then
        (cache,v);

    // Special case for a boolean expression like if( expression or ARRAY_IDEX_OUT_OF_BOUNDS_ERROR)
    // "expression" in this case we return the lh expression to be equall to
    // the previous c-code generation.
    case (cache,env,DAE.LBINARY(exp1 = lh,operator = DAE.OR(_),exp2 = rh),impl,msg,_)
      equation
        (cache,v as Values.BOOL(_)) = ceval(cache,env, lh, impl,msg,numIter);
        failure(ceval(cache,env, rh, impl, msg, numIter));
      then
        (cache,v);

    // NOT
    case (cache,env,DAE.LUNARY(operator = DAE.NOT(_),exp = e),impl,msg,_)
      equation
        (cache,Values.BOOL(b)) = ceval(cache,env, e, impl, msg,numIter+1);
        b_1 = boolNot(b);
      then
        (cache,Values.BOOL(b_1));

    // relations <, >, <=, >=, <>
    case (cache,env,DAE.RELATION(exp1 = lhs,operator = relop,exp2 = rhs),impl,msg,_)
      equation
        (cache,lhs_1) = ceval(cache,env, lhs, impl,msg,numIter);
        (cache,rhs_1) = ceval(cache,env, rhs, impl,msg,numIter);
        v = cevalRelation(lhs_1, relop, rhs_1);
      then
        (cache,v);

    case (cache, env, DAE.RANGE(ty = DAE.T_BOOL(), start = start, step = NONE(),stop = stop), impl,  msg,_)
      equation
        (cache, Values.BOOL(bstart)) = ceval(cache, env, start, impl, msg,numIter+1);
        (cache, Values.BOOL(bstop)) = ceval(cache, env, stop, impl, msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRangeBool(bstart, bstop),
          ValuesUtil.makeBoolean);
      then
        (cache, ValuesUtil.makeArray(arr));

    // range first:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.T_INTEGER(),start = start,step = NONE(),stop = stop),impl,msg,_)
      equation
        (cache,Values.INTEGER(start_1)) = ceval(cache,env, start, impl, msg,numIter+1);
        (cache,Values.INTEGER(stop_1)) = ceval(cache,env, stop, impl, msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRange(start_1, 1, stop_1), ValuesUtil.makeInteger);
      then
        (cache,ValuesUtil.makeArray(arr));

    // range first:step:last for integers
    case (cache,env,DAE.RANGE(ty = DAE.T_INTEGER(),start = start,step = SOME(step),stop = stop),impl,msg,_)
      equation
        (cache,Values.INTEGER(start_1)) = ceval(cache,env, start, impl, msg,numIter+1);
        (cache,Values.INTEGER(step_1)) = ceval(cache,env, step, impl, msg,numIter+1);
        (cache,Values.INTEGER(stop_1)) = ceval(cache,env, stop, impl, msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRange(start_1, step_1, stop_1), ValuesUtil.makeInteger);
      then
        (cache,ValuesUtil.makeArray(arr));

    // range first:last for enumerations.
    case (cache,env,DAE.RANGE(ty = t as DAE.T_ENUMERATION(),start = start,step = NONE(),stop = stop),impl,msg,_)
      equation
        (cache,Values.ENUM_LITERAL(index = start_1)) = ceval(cache,env, start, impl, msg,numIter+1);
        (cache,Values.ENUM_LITERAL(index = stop_1)) = ceval(cache,env, stop, impl, msg,numIter+1);
        arr = cevalRangeEnum(start_1, stop_1, t);
      then
        (cache,ValuesUtil.makeArray(arr));

    // range first:last for reals
    case (cache,env,DAE.RANGE(ty = DAE.T_REAL(),start = start,step = NONE(),stop = stop),impl,msg,_)
      equation
        (cache,Values.REAL(realStart1)) = ceval(cache,env, start, impl, msg,numIter+1);
        (cache,Values.REAL(realStop1)) = ceval(cache,env, stop, impl, msg,numIter+1);
        // diff = realStop1 - realStart1;
        realStep1 = intReal(1);
        arr = List.map(ExpressionSimplify.simplifyRangeReal(realStart1, realStep1, realStop1), ValuesUtil.makeReal);
      then
        (cache,ValuesUtil.makeArray(arr));

    // range first:step:last for reals
    case (cache,env,DAE.RANGE(ty = DAE.T_REAL(),start = start,step = SOME(step),stop = stop),impl,msg,_)
      equation
        (cache,Values.REAL(realStart1)) = ceval(cache,env, start, impl, msg,numIter+1);
        (cache,Values.REAL(realStep1)) = ceval(cache,env, step, impl, msg,numIter+1);
        (cache,Values.REAL(realStop1)) = ceval(cache,env, stop, impl, msg,numIter+1);
        arr = List.map(ExpressionSimplify.simplifyRangeReal(realStart1, realStep1, realStop1), ValuesUtil.makeReal);
      then
        (cache,ValuesUtil.makeArray(arr));

    // cast integer to real
    case (cache,env,DAE.CAST(ty = DAE.T_REAL(),exp = e),impl,msg,_)
      equation
        (cache,Values.INTEGER(i)) = ceval(cache,env, e, impl, msg,numIter+1);
        r = intReal(i);
      then
        (cache,Values.REAL(r));

    // cast real to integer
    case (cache,env,DAE.CAST(ty = DAE.T_INTEGER(), exp = e),impl,msg,_)
      equation
        (cache,Values.REAL(r)) = ceval(cache, env, e, impl,msg,numIter+1);
        i = realInt(r);
      then
        (cache,Values.INTEGER(i));

    // cast integer to enum
    case (cache,env,DAE.CAST(ty = DAE.T_ENUMERATION(path = path, names = n), exp = e), impl, msg,_)
      equation
        (cache, Values.INTEGER(i)) = ceval(cache, env, e, impl, msg,numIter+1);
        str = listGet(n, i);
        path = Absyn.joinPaths(path, Absyn.IDENT(str));
      then
        (cache, Values.ENUM_LITERAL(path, i));

    // cast integer array to real array
    case (cache,env,DAE.CAST(ty = DAE.T_ARRAY(ty = DAE.T_REAL()),exp = e),impl,msg,_)
      equation
        (cache,Values.ARRAY(ivals,dims)) = ceval(cache,env, e, impl, msg,numIter+1);
        rvals = ValuesUtil.typeConvert(DAE.T_INTEGER_DEFAULT, DAE.T_REAL_DEFAULT, ivals);
      then
        (cache,Values.ARRAY(rvals,dims));

    // if expressions, select then/else branch if condition is true/false
    case (cache,env,DAE.IFEXP(expCond = cond,expThen = e1,expElse = e2),impl,msg,_)
      equation
        (cache,v) = ceval(cache, env, cond, impl, msg, numIter+1);
         // ifexp true then then branch, else else branch"
        Values.BOOL(resBool) = v;
        (cache, v) = ceval(cache, env, if resBool then e1 else e2, impl, msg,numIter);
      then
        (cache,v);

    // indexing for array[integer index]
    case (cache,env,DAE.ASUB(exp = e,sub = ((DAE.ICONST(indx))::{})),impl,msg,_)
      equation
        (cache,Values.ARRAY(vals,_)) = ceval(cache,env, e, impl, msg,numIter+1) "asub" ;
        v = listGet(vals, indx);
      then
        (cache,v);

    // indexing for array[subscripts]
    case (cache, env, DAE.ASUB(exp = e,sub = expl ), impl, msg,_)
      equation
        (cache,Values.ARRAY(vals,dims)) = ceval(cache,env, e, impl, msg,numIter+1);
        (cache,es_1) = cevalList(cache,env, expl, impl, msg,numIter);
        v = listHead(es_1);
        v = ValuesUtil.nthnthArrayelt(es_1,Values.ARRAY(vals,dims),v);
      then
        (cache,v);

    // indexing for tuple[index]
    case (cache, env, DAE.TSUB(exp = e,ix = indx), impl, msg,_)
      equation
        (cache,Values.TUPLE(vals)) = ceval(cache,env, e, impl, msg,numIter+1);
        v = listGet(vals, indx);
      then
        (cache,v);

    case (cache, env, DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(iterType = iterType, path = path, foldName=foldName, resultName=resultName, foldExp = foldExp, defaultValue = ov, exprType = ty), expr = daeExp, iterators = iterators), impl, msg,_)
      equation
        env = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), FCore.forScopeName, NONE());
        (cache, valMatrix, names, dims, tys) = cevalReductionIterators(cache, env, iterators, impl, msg,numIter+1);
        // print("Before:\n");print(stringDelimitList(List.map1(List.mapList(valMatrix, ValuesUtil.valString), stringDelimitList, ","), "\n") + "\n");
        valMatrix = makeReductionAllCombinations(valMatrix,iterType);
        // print("After:\n");print(stringDelimitList(List.map1(List.mapList(valMatrix, ValuesUtil.valString), stringDelimitList, ","), "\n") + "\n");
        // print("Start cevalReduction: " + Absyn.pathString(path) + " " + ExpressionDump.printExpStr(daeExp) + "\n");
        (cache, ov) = cevalReduction(cache, env, path, ov, daeExp, ty, foldName, resultName, foldExp, names, listReverse(valMatrix), tys, impl, msg,numIter+1);
        value = Util.getOptionOrDefault(ov, Values.META_FAIL());
        value = backpatchArrayReduction(path, iterType, value, dims);
      then (cache, value);

    case (_, _, DAE.EMPTY(), _, _, _)
      algorithm
        s := ComponentReference.printComponentRefStr(inExp.name);
        v := Types.typeToValue(inExp.ty);
      then
        (inCache, Values.EMPTY(inExp.scope, s, v, inExp.tyStr));

    case (_,_,_,_,_,_) guard Config.getGraphicsExpMode()
      algorithm
        ty := Expression.typeof(inExp);
        v := Types.typeToValue(ty);
      then (inCache, Values.EMPTY("#graphicsExp#", ExpressionDump.printExpStr(inExp), v, Types.unparseType(ty)));

    // ceval can fail and that is ok, caught by other rules...
    case (_,env,e,_,_,_) // Absyn.MSG())
      equation
        true = Flags.isSet(Flags.CEVAL);
        Debug.traceln("- Ceval.ceval failed: " + ExpressionDump.printExpStr(e));
        Debug.traceln("  Scope: " + FGraph.printGraphPathStr(env));
        // Debug.traceln("  Env:" + FGraph.printGraphStr(env));
      then
        fail();
  end matchcontinue;
end cevalWork2;

public function cevalIfConstant
  "This function constant evaluates an expression if the expression is constant,
   or if the expression is a call of parameter constness whose return type
   contains unknown dimensions (in which case we need to determine the size of
   those dimensions)."
  input output FCore.Cache cache;
  input FCore.Graph inEnv;
  input output DAE.Exp exp;
  input output DAE.Properties prop;
  input Boolean impl;
  input SourceInfo inInfo;
algorithm
  if Expression.isEvaluatedConst(exp) then
    // Don't mess up the dimensions, etc by using the Values module
    return;
  end if;
  (cache, exp, prop) := matchcontinue prop
    local
      Values.Value v;
      DAE.Type tp;

    case DAE.PROP(constFlag = DAE.C_PARAM(), type_ = tp)
      // BoschRexroth specifics
      guard not Flags.getConfigBool(Flags.CEVAL_EQUATION)
      then (cache, exp, DAE.PROP(tp, DAE.C_VAR()));

    case DAE.PROP(constFlag = DAE.C_CONST(), type_ = tp)
      algorithm
        (cache, v) := ceval(cache, inEnv, exp, impl, Absyn.NO_MSG(), 0);
        exp := ValuesUtil.valueExp(v);
        exp := ValuesUtil.fixZeroSizeArray(exp, tp);
      then (cache, exp, prop);

    case DAE.PROP_TUPLE()
      algorithm
        DAE.C_CONST() := Types.propAllConst(prop);
        (cache, v) := ceval(cache, inEnv, exp, false, Absyn.NO_MSG(), 0);
        exp := ValuesUtil.valueExp(v);
      then (cache, exp, prop);

    case DAE.PROP_TUPLE()
      // BoschRexroth specifics
      guard not Flags.getConfigBool(Flags.CEVAL_EQUATION)
      algorithm
        DAE.C_PARAM() := Types.propAllConst(prop);
        print(" tuple non constant evaluation not implemented yet\n");
      then fail();

    case _
      // Structural parameters and the like... we can ceval them if we want to
      guard Expression.isConst(exp) and not Config.acceptMetaModelicaGrammar()
      algorithm
        (_, v) := ceval(cache, inEnv, exp, impl, Absyn.NO_MSG(), 0);
        exp := ValuesUtil.valueExp(v);
        exp := ValuesUtil.fixZeroSizeArray(exp, Types.getPropType(prop));
      then (cache, exp, prop);

    else
      algorithm
        // If we fail to evaluate, at least we should simplify the expression
        (exp,_) := ExpressionSimplify.simplify1(exp);
      then (cache, exp, prop);

  end matchcontinue;
end cevalIfConstant;

protected function cevalWholedimRetCall
  "Helper function to cevalIfConstant. Determines the size of any unknown
   dimensions in a function calls return type."
  input DAE.Exp inExp;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input SourceInfo inInfo;
  input Integer numIter;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outExp, outProp) := match(inExp, inCache, inEnv, inInfo, numIter)
    local
      DAE.Exp e;
      Absyn.Path p;
      list<DAE.Exp> el;
      Boolean t, b, isImpure, isFunctionPointerCall;
      DAE.InlineType i;
      DAE.Dimensions dims;
      Values.Value v;
      DAE.Type cevalType, ty;
      DAE.TailCall tc;
      DAE.CallAttributes attr;

     case (e as DAE.CALL(path = p, expLst = el, attr = attr as DAE.CALL_ATTR(ty = DAE.T_ARRAY(dims = dims))), _, _, _, _)
       equation
         true = Expression.arrayContainWholeDimension(dims);
         (_, v) = ceval(inCache, inEnv, e, true, Absyn.MSG(inInfo), numIter+1);
         ty = Types.typeOfValue(v);
         cevalType = Types.simplifyType(ty);
         attr.ty = cevalType;
       then
         (DAE.CALL(p, el, attr), DAE.PROP(ty, DAE.C_PARAM()));
  end match;
end cevalWholedimRetCall;

public function cevalRangeIfConstant
  "Constant evaluates the limits of a range if they are constant."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input DAE.Properties inProp;
  input Boolean impl;
  input SourceInfo inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache, outExp) := matchcontinue(inCache, inEnv, inExp, inProp, impl, inInfo)
    local
      DAE.Exp e1, e2;
      Option<DAE.Exp> e3;
      DAE.Type ty;
      FCore.Cache cache;

    case (_, _, DAE.RANGE(ty = ty, start = e1, stop = e2, step = e3), _, _, _)
      equation
        (cache, e1, _) = cevalIfConstant(inCache, inEnv, e1, inProp, impl, inInfo);
        (_, e2, _) = cevalIfConstant(cache, inEnv, e2, inProp, impl, inInfo);
      then
        (inCache, DAE.RANGE(ty, e1, e3, e2));
    else (inCache, inExp);
  end matchcontinue;
end cevalRangeIfConstant;

protected function cevalBuiltin
"Helper for ceval. Parts for builtin calls are moved here, for readability.
  See ceval for documentation.
  NOTE:    It\'s ok if cevalBuiltin fails. Just means the call was not a builtin function"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
  partial function HandlerFunc
    input FCore.Cache inCache;
    input FCore.Graph inEnvFrameLst;
    input list<DAE.Exp> inExpExpLst;
    input Boolean inBoolean;
    input Absyn.Msg inMsg;
    input Integer numIter;
    output FCore.Cache outCache;
    output Values.Value outValue;
  end HandlerFunc;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inMsg,numIter)
    local
      Values.Value v,newval;
      FCore.Graph env;
      DAE.Exp exp,dim,e;
      Boolean impl;
      Absyn.Msg msg;
      HandlerFunc handler;
      String id;
      list<DAE.Exp> args,expl;
      list<Values.Value> vallst;
      Absyn.Path funcpath,path;
      FCore.Cache cache;

    case (cache,env,DAE.SIZE(exp = exp,sz = SOME(dim)),impl,msg,_)
      equation
        (cache,v) = cevalBuiltinSize(cache,env, exp, dim, impl, msg, numIter+1) "Handle size separately" ;
      then
        (cache,v);
    case (cache,env,DAE.SIZE(exp = exp,sz = NONE()),impl,msg,_)
      equation
        (cache,v) = cevalBuiltinSizeMatrix(cache,env, exp, impl, msg,numIter+1);
      then
        (cache,v);
    case (cache,env,DAE.CALL(path = path,expLst = args,attr = DAE.CALL_ATTR(builtin = true)),impl,msg,_)
      equation
        id = Absyn.pathString(path);
        handler = cevalBuiltinHandler(id);
        (cache,v) = handler(cache, env, args, impl, msg,numIter+1);
      then (cache,v);
    case (cache,env,(e as DAE.CALL(expLst = expl,attr = DAE.CALL_ATTR(builtin = true))),impl,msg,_)
      equation
        (cache,vallst) = cevalList(cache, env, expl, impl, msg, numIter);
        (cache,newval) = BackendInterface.cevalCallFunction(cache, env, e, vallst, impl, msg,numIter+1);
      then (cache,newval);
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
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input list<DAE.Exp> inExpExpLst;
    input Boolean inBoolean;
    input Absyn.Msg inMsg;
    input Integer numIter;
    output FCore.Cache outCache;
    output Values.Value outValue;
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
    case "sum" then cevalBuiltinSum;
    case "diagonal" then cevalBuiltinDiagonal;
    case "sign" then cevalBuiltinSign;
    case "exp" then cevalBuiltinExp;
    case "noEvent" then cevalBuiltinNoevent;
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
    case "fail" then cevalBuiltinFail;
    // BTH
    /*
    case "Clock"
      equation
        true = Config.synchronousFeaturesAllowed();
      then cevalBuiltinClock; */
    // MetaModelica type conversions
    case "intString" guard Config.acceptMetaModelicaGrammar() then cevalIntString;
    case "realString" guard Config.acceptMetaModelicaGrammar() then cevalRealString;
    case "stringCharInt" guard Config.acceptMetaModelicaGrammar() then cevalStringCharInt;
    case "intStringChar" guard Config.acceptMetaModelicaGrammar() then cevalIntStringChar;
    case "stringLength" guard Config.acceptMetaModelicaGrammar() then cevalStringLength;
    case "stringInt" guard Config.acceptMetaModelicaGrammar() then cevalStringInt;
    case "stringListStringChar" guard Config.acceptMetaModelicaGrammar() then cevalStringListStringChar;
    case "listStringCharString" guard Config.acceptMetaModelicaGrammar() then cevalListStringCharString;
    case "stringAppendList" guard Config.acceptMetaModelicaGrammar() then cevalStringAppendList;
    case "stringDelimitList" guard Config.acceptMetaModelicaGrammar() then cevalStringDelimitList;
    case "listLength" guard Config.acceptMetaModelicaGrammar() then cevalListLength;
    case "listAppend" guard Config.acceptMetaModelicaGrammar() then cevalListAppend;
    case "listReverse" guard Config.acceptMetaModelicaGrammar() then cevalListReverse;
    case "listHead" guard Config.acceptMetaModelicaGrammar() then cevalListFirst;
    case "listRest" guard Config.acceptMetaModelicaGrammar() then cevalListRest;
    case "listMember" guard Config.acceptMetaModelicaGrammar() then cevalListMember;
    case "anyString" guard Config.acceptMetaModelicaGrammar() then cevalAnyString;
    case "listArrayLiteral" guard Config.acceptMetaModelicaGrammar() then cevalListArrayLiteral;
    case "intBitAnd" guard Config.acceptMetaModelicaGrammar() then cevalIntBitAnd;
    case "intBitOr" guard Config.acceptMetaModelicaGrammar() then cevalIntBitOr;
    case "intBitXor" guard Config.acceptMetaModelicaGrammar() then cevalIntBitXor;
    case "intBitLShift" guard Config.acceptMetaModelicaGrammar() then cevalIntBitLShift;
    case "intBitRShift" guard Config.acceptMetaModelicaGrammar() then cevalIntBitRShift;
    case "numBits" then cevalNumBits;
    case "integerMax" then cevalIntegerMax;

    //case "semiLinear" then cevalBuiltinSemiLinear;
    //case "delay" then cevalBuiltinDelay;
    case id
      equation
        true = Flags.isSet(Flags.CEVAL);
        Debug.traceln("No cevalBuiltinHandler found for " + id);
      then
        fail();
  end match;
end cevalBuiltinHandler;




public function cevalKnownExternalFuncs "Evaluates external functions that are known, e.g. all math functions."
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Absyn.Path funcpath;
  input list<Values.Value> vals;
  input Absyn.Msg msg;
  output FCore.Cache outCache;
  output Values.Value res;
protected
  SCode.Element cdef;
  FCore.Graph env_1;
  String fid,id;
  Option<String> oid;
  Option<SCode.ExternalDecl> extdecl;
  Option<String> lan;
  Option<Absyn.ComponentRef> out;
  list<Absyn.Exp> args;
  SCode.FunctionRestriction funcRest;
algorithm
  (outCache,cdef,env_1) := Lookup.lookupClass(inCache,env, funcpath);
  SCode.CLASS(name=fid,restriction = SCode.R_FUNCTION(funcRest), classDef=SCode.PARTS(externalDecl=extdecl)) := cdef;
  SCode.FR_EXTERNAL_FUNCTION(_) := funcRest;
  SOME(SCode.EXTERNALDECL(oid,_,_,_,_)) := extdecl;
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
    case ("ModelicaStrings_compare") then ();
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
      Real rv_1,rv,rv1,rv2,r;
      String str,fileName,re,str1,str2;
      Integer start, stop, i, lineNumber, n;
      Boolean b, extended, insensitive;
      list<String> strs;
      list<Values.Value> vals;
      Values.Value v;
      Absyn.Path p;

    case ("acos",{Values.REAL(real = rv)},_)
      equation
        true = rv >= -1.0 and rv <= 1.0;
        rv_1 = acos(rv);
      then
        Values.REAL(rv_1);
    case ("asin",{Values.REAL(real = rv)},_)
      equation
        true = rv >= -1.0 and rv <= 1.0;
        rv_1 = asin(rv);
      then
        Values.REAL(rv_1);
    case ("atan",{Values.REAL(real = rv)},_)
      equation
        rv_1 = atan(rv);
      then
        Values.REAL(rv_1);
    case ("atan2",{Values.REAL(real = rv1),Values.REAL(real = rv2)},_)
      equation
        rv_1 = atan2(rv1, rv2);
      then
        Values.REAL(rv_1);
    case ("cos",{Values.REAL(real = rv)},_)
      equation
        rv_1 = cos(rv);
      then
        Values.REAL(rv_1);
    case ("cosh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = cosh(rv);
      then
        Values.REAL(rv_1);
    case ("exp",{Values.REAL(real = rv)},_)
      equation
        rv_1 = exp(rv);
      then
        Values.REAL(rv_1);
    case ("log",{Values.REAL(real = rv)},_)
      equation
        true = rv > 0;
        rv_1 = log(rv);
      then
        Values.REAL(rv_1);
    case ("log10",{Values.REAL(real = rv)},_)
      equation
        true = rv > 0;
        rv_1 = log10(rv);
      then
        Values.REAL(rv_1);
    case ("sin",{Values.REAL(real = rv)},_)
      equation
        rv_1 = sin(rv);
      then
        Values.REAL(rv_1);
    case ("sinh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = sinh(rv);
      then
        Values.REAL(rv_1);
    case ("tan",{Values.REAL(real = rv)},_)
      equation
        rv_1 = tan(rv);
      then
        Values.REAL(rv_1);
    case ("tanh",{Values.REAL(real = rv)},_)
      equation
        rv_1 = tanh(rv);
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

    case ("ModelicaStrings_compare",{Values.STRING(str1),Values.STRING(str2),Values.BOOL(b)},_)
      equation
        i = ModelicaExternalC.Strings_compare(str1,str2,b);
        p = listGet({EnumCompareLess,EnumCompareEqual,EnumCompareGreater},i);
      then Values.ENUM_LITERAL(p,i);

    case ("ModelicaStrings_scanReal",{Values.STRING(str),Values.INTEGER(i),Values.BOOL(b)},_)
      equation
        (i,r) = ModelicaExternalC.Strings_advanced_scanReal(str,i,b);
      then Values.TUPLE({Values.INTEGER(i),Values.REAL(r)});

    case ("ModelicaStrings_skipWhiteSpace",{Values.STRING(str),Values.INTEGER(i)},_)
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

protected constant Absyn.Path EnumCompareLess = Absyn.QUALIFIED("Modelica",Absyn.QUALIFIED("Utilities",Absyn.QUALIFIED("Types",Absyn.QUALIFIED("Compare",Absyn.IDENT("Less")))));
protected constant Absyn.Path EnumCompareEqual = Absyn.QUALIFIED("Modelica",Absyn.QUALIFIED("Utilities",Absyn.QUALIFIED("Types",Absyn.QUALIFIED("Compare",Absyn.IDENT("Equal")))));
protected constant Absyn.Path EnumCompareGreater = Absyn.QUALIFIED("Modelica",Absyn.QUALIFIED("Utilities",Absyn.QUALIFIED("Types",Absyn.QUALIFIED("Compare",Absyn.IDENT("Greater")))));

protected function cevalMatrixElt "Evaluates the expression of a matrix constructor, e.g. {1,2;3,4}"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<list<DAE.Exp>> inMatrix "matrix constr. elts";
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache = inCache;
  output list<Values.Value> outValues = {};
protected
  Values.Value v;
  list<Values.Value> vl;
algorithm
  for expl in inMatrix loop
    (outCache,vl) := cevalList(outCache,inEnv,expl,inBoolean,inMsg,numIter);
    v := ValuesUtil.makeArray(vl);
    outValues := v::outValues;
  end for;
  outValues := listReverseInPlace(outValues);
end cevalMatrixElt;

protected function cevalBuiltinSize "Evaluates the size operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv1;
  input DAE.Exp inExp2;
  input DAE.Exp inDimExp;
  input Boolean inBoolean4;
  input Absyn.Msg inMsg6;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv1,inExp2,inDimExp,inBoolean4,inMsg6,numIter)
    local
      DAE.Attributes attr;
      DAE.Type tp;
      DAE.Binding bind,binding;
      list<Integer> sizelst,adims;
      Integer dim,dim_1,dimv,len,i;
      FCore.Graph env;
      DAE.ComponentRef cr;
      Boolean impl,bl;
      Absyn.Msg msg;
      DAE.Dimensions dims;
      Values.Value v2,val;
      DAE.Type crtp,expTp;
      DAE.Exp exp,e,dimExp;
      String cr_str,dim_str,size_str,expstr;
      list<DAE.Exp> es;
      FCore.Cache cache;
      list<list<DAE.Exp>> mat;
      SourceInfo info;
      DAE.Dimension ddim;

    case (cache,_,DAE.MATRIX(matrix=mat),DAE.ICONST(1),_,_,_)
      equation
        i = listLength(mat);
      then
        (cache,Values.INTEGER(i));

    case (cache,_,DAE.MATRIX(matrix=mat),DAE.ICONST(2),_,_,_)
      equation
        i = listLength(listHead(mat));
      then
        (cache,Values.INTEGER(i));

    case (cache,env,DAE.MATRIX(matrix=mat),DAE.ICONST(dim),impl,msg,_)
      equation
        bl = (dim>2);
        true = bl;
        dim_1 = dim-2;
        e = listHead(listHead(mat));
        (cache,Values.INTEGER(i)) = cevalBuiltinSize(cache,env,e,DAE.ICONST(dim_1),impl,msg,numIter+1);
      then
        (cache,Values.INTEGER(i));

    case (cache,env,DAE.CREF(componentRef = cr),dimExp,impl,msg,_)
      equation
        (cache,_,tp,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr) "If dimensions known, always ceval" ;
        true = Types.dimensionsKnown(tp);
        (sizelst as (_ :: _)) = Types.getDimensionSizes(tp);
        (cache,Values.INTEGER(dim)) = ceval(cache, env, dimExp, impl, msg,numIter+1);
        i = listGet(sizelst, dim);
      then
        (cache,Values.INTEGER(i));

    case (cache,env,DAE.CREF(componentRef = cr),dimExp,(impl as false),msg,_)
      equation
        (cache,dims) = InstUtil.elabComponentArraydimFromEnv(cache,env,cr,Absyn.dummyInfo)
        "If component not instantiated yet, recursive definition.
         For example,
           Real x[:](min=fill(1.0,size(x,1))) = {1.0}
         When size(x,1) should be determined, x must be instantiated, but
         that is not done yet. Solution: Examine Element to find modifier
         which will determine dimension size.";
        (cache,Values.INTEGER(dimv)) = ceval(cache, env, dimExp, impl, msg,numIter+1);
        ddim = listGet(dims, dimv);
        (cache, v2) = cevalDimension(cache, env, ddim, impl, msg,numIter+1);
      then
        (cache,v2);

    case (cache,env,DAE.CREF(componentRef = cr),dimExp,false,Absyn.MSG(info = info),_)
      equation
        (_,_,tp,binding,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr) "If dimensions not known and impl=false, error message";
        if not Types.dimensionsKnown(tp)
        then
          cr_str = ComponentReference.printComponentRefStr(cr);
          dim_str = ExpressionDump.printExpStr(dimExp);
          size_str = stringAppendList({"size(",cr_str,", ",dim_str,")"});
          Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {size_str}, info);
        else
          _ = match(binding)
               case DAE.UNBOUND()
                 equation
                   expstr = ExpressionDump.printExpStr(inExp2);
                   Error.addSourceMessage(Error.UNBOUND_VALUE, {expstr}, info);
                 then
                   fail();
              end match;
        end if;
      then
        fail();

    // For crefs with value binding e.g. size(x,1) when Real x[:]=fill(0,1);
    case (cache,env,(DAE.CREF(componentRef = cr)),dimExp,impl,msg,_)
      equation
        (cache,_,_,binding,_,_,_,_,_) = Lookup.lookupVar(cache, env, cr)  ;
        (cache,Values.INTEGER(dimv)) = ceval(cache,env,dimExp,impl,msg,numIter+1);
        (cache,val) = cevalCrefBinding(cache,env, cr, binding, impl,msg,numIter+1);
        v2 = cevalBuiltinSize2(val, dimv);
      then
        (cache,v2);

    case (cache,env,DAE.ARRAY(array = (exp :: es)),dimExp,impl,msg,_)
      equation
        _ = Expression.typeof(exp) "Special case for array expressions with nonconstant
                                        values For now: only arrays of scalar elements:
                                        TODO generalize to arbitrary dimensions";
        (cache,Values.INTEGER(1)) = ceval(cache, env, dimExp, impl, msg, numIter+1);
        len = listLength(exp :: es);
      then
        (cache,Values.INTEGER(len));

    // For expressions with value binding that can not determine type
    // e.g. size(x,2) when Real x[:,:]=fill(0.0,0,2); empty array with second dimension == 2, no way of
    // knowing that from the value. Must investigate the expression itself.
    case (cache,env,exp,dimExp,impl,msg,_)
      equation
        (cache,val) = ceval(cache,env,exp,impl,msg,numIter+1);
        (cache,Values.INTEGER(dimv)) = ceval(cache,env,dimExp,impl,msg,numIter+1);
        v2 = match(val)
               case Values.ARRAY({},adims) then Values.INTEGER(listGet(adims,dimv));
               else cevalBuiltinSize2(val, dimv);
             end match;
      then
        (cache,v2);

    case (_,_,exp,_,_,Absyn.MSG(),_)
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

    case (Values.ARRAY(valueLst = (l :: _)),ind)
      equation
        ind_1 = ind - 1;
        dimVal = cevalBuiltinSize2(l, ind_1);
      then
        dimVal;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Ceval.cevalBuiltinSize2 failed\n");
      then
        fail();
  end matchcontinue;
end cevalBuiltinSize2;

protected function cevalBuiltinSize3 "author: PA
  Helper function to cevalBuiltinSize.
  Used when recursive definition (attribute modifiers using size) is used."
  input DAE.Dimensions inDims;
  input Integer inIndex;
  output Values.Value outValue;
protected
  Integer v;
algorithm
  DAE.DIM_INTEGER(v) := listGet(inDims, inIndex);
  outValue := Values.INTEGER(v);
end cevalBuiltinSize3;

protected function cevalBuiltinAbs "author: LP
  Evaluates the abs operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      Integer iv;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env,exp,impl,msg,numIter+1);
        rv_1 = realAbs(rv);
      then
        (cache,Values.REAL(rv_1));
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.INTEGER(iv)) = ceval(cache,env,exp,impl,msg,numIter+1);
        iv = intAbs(iv);
      then
        (cache,Values.INTEGER(iv));
  end matchcontinue;
end cevalBuiltinAbs;

protected function cevalBuiltinSign "author: PA
  Evaluates the sign operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv;
      Boolean b1,b2,b3,impl;
      FCore.Graph env;
      DAE.Exp exp;
      Absyn.Msg msg;
      Integer iv,iv_1;
      FCore.Cache cache;
      Values.Value v;

    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,v) = ceval(cache,env,exp,impl,msg,numIter+1);
        (b1, b2, b3) = match(v)
          case (Values.REAL(rv)) then ((rv > 0.0), (rv < 0.0), (rv == 0.0));
          case (Values.INTEGER(iv)) then ((iv > 0), (iv < 0), (iv == 0));
        end match;
        {(_,iv_1)} = List.select({(b1,1),(b2,-1),(b3,0)}, Util.tuple21);
      then
        (cache,Values.INTEGER(iv_1));

  end match;
end cevalBuiltinSign;

protected function cevalBuiltinExp "author: PA
  Evaluates the exp function"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env,exp,impl,msg,numIter+1);
        rv_1 = .exp(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinExp;

protected function cevalBuiltinNoevent "author: PA
  Evaluates the noEvent operator. During constant evaluation events are not
  considered, so evaluation will simply remove the operator and evaluate the
  operand."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Values.Value v;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,v) = ceval(cache,env,exp,impl,msg,numIter+1);
      then
        (cache,v);
  end match;
end cevalBuiltinNoevent;

protected function cevalBuiltinCat "author: PA
  Evaluates the cat operator, for matrix concatenation."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Integer dim_int;
      list<Values.Value> mat_lst;
      Values.Value v;
      FCore.Graph env;
      DAE.Exp dim;
      list<DAE.Exp> matrices;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;

    case (cache,env,(dim :: matrices),impl,msg,_)
      equation
        (cache,Values.INTEGER(dim_int)) = ceval(cache,env,dim,impl,msg,numIter+1);
        (cache,mat_lst) = cevalList(cache,env, matrices, impl, msg,numIter);
        v = cevalCat(mat_lst, dim_int);
      then
        (cache,v);

  end match;
end cevalBuiltinCat;

protected function cevalBuiltinIdentity "author: PA
  Evaluates the identity operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Integer dimension;
      list<DAE.Exp> expl;
      list<Values.Value> retExp;
      FCore.Graph env;
      DAE.Exp dim;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Values.Value res;

    case (cache,env,{dim},impl,msg,_)
      algorithm
        (cache,Values.INTEGER(dimension)) := ceval(cache,env,dim,impl,msg,numIter+1);
        res := Values.ARRAY(list(Values.ARRAY(list(if i==j then Values.INTEGER(1) else Values.INTEGER(0) for i in 1:dimension),{dimension}) for j in 1:dimension), {dimension,dimension});
      then
        (cache,res);

  end match;
end cevalBuiltinIdentity;

protected function cevalBuiltinPromote "author: PA
  Evaluates the internal promote operator, for promotion of arrays"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Values.Value arr_val,res;
      Integer dim_val;
      FCore.Graph env;
      DAE.Exp arr,dim;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      list<Integer> dims;

    case (cache,env,{arr,dim},impl,msg,_)
      equation
        (cache,arr_val as Values.ARRAY(dimLst=dims)) = ceval(cache,env, arr, impl, msg,numIter+1);
        (cache,Values.INTEGER(dim_val)) = ceval(cache,env, dim, impl, msg,numIter+1);
        res = cevalBuiltinPromote2(arr_val, dim_val - listLength(dims));
      then
        (cache,res);
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
      then Values.ARRAY(vs_1,i::il);
    case (v,n)
      equation
        failure(Values.ARRAY() = v);
        n_1 = n - 1;
        (v as Values.ARRAY(dimLst = il)) = cevalBuiltinPromote2(v, n_1);
      then Values.ARRAY({v},1::il);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Ceval.cevalBuiltinPromote2 failed\n");
      then fail();
  end matchcontinue;
end cevalBuiltinPromote2;

protected function cevalBuiltinSubstring "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e).
  TODO: Also evaluate String(r, significantDigits=d), and String(r, format=s)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp str_exp, start_exp, stop_exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      Integer start, stop;

    case (cache,env,{str_exp, start_exp, stop_exp},impl,msg,_)
      equation
        (cache,Values.STRING(str)) = ceval(cache,env, str_exp, impl, msg,numIter+1);
        (cache,Values.INTEGER(start)) = ceval(cache,env, start_exp, impl, msg,numIter+1);
        (cache,Values.INTEGER(stop)) = ceval(cache,env, stop_exp, impl, msg,numIter+1);
        str = System.substring(str, start, stop);
      then
        (cache,Values.STRING(str));
  end match;
end cevalBuiltinSubstring;

protected function cevalBuiltinString "
  author: PA
  Evaluates the String operator String(r), String(i), String(b), String(e).
  TODO: Also evaluate String(r, significantDigits=d), and String(r, format=s)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp, len_exp, justified_exp, sig_dig;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str,format;
      Integer i,len,sig; Real r; Boolean b, left_just;
      Absyn.Path p;
      Values.Value v;

    case (cache,env,{exp, len_exp, justified_exp},impl,msg,_)
      equation
        (cache,v) = ceval(cache, env, exp, impl, msg, numIter+1);
        str = match(v)
          case (Values.INTEGER(i)) then intString(i);
          case (Values.BOOL(b)) then boolString(b);
          case (Values.ENUM_LITERAL(name = p)) then Absyn.pathLastIdent(p);
        end match;
        (cache, str) = cevalBuiltinStringFormat(cache, env, str, len_exp, justified_exp, impl, msg, numIter+1);
      then
        (cache,Values.STRING(str));

    case (cache,env,{exp, sig_dig, len_exp, justified_exp},impl,msg,_)
      equation
        (cache,Values.REAL(r)) = ceval(cache,env, exp, impl, msg,numIter+1);
        (cache,Values.INTEGER(len)) = ceval(cache,env, len_exp, impl, msg,numIter+1);
        (cache,Values.BOOL(left_just)) = ceval(cache,env, justified_exp, impl, msg,numIter+1);
        (cache,Values.INTEGER(sig)) = ceval(cache,env, sig_dig, impl, msg,numIter+1);
        format = "%" + (if left_just then "-" else "") + intString(len) + "." + intString(sig) + "g";
        str = System.snprintff(format,len+20,r);
      then
        (cache,Values.STRING(str));

  end match;
end cevalBuiltinString;

protected function cevalBuiltinStringFormat
  "This function formats a string by using the minimumLength and leftJustified
  arguments to the String function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inString;
  input DAE.Exp lengthExp;
  input DAE.Exp justifiedExp;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output String outString;
algorithm
  (outCache, outString) := match(inCache, inEnv, inString, lengthExp,
      justifiedExp, inBoolean, inMsg, numIter)
    local
      FCore.Cache cache;
      Integer min_length;
      Boolean left_justified;
      String str;
    case (cache, _, _, _, _, _, _, _)
      equation
        (cache, Values.INTEGER(integer = min_length)) =
          ceval(cache, inEnv, lengthExp, inBoolean, inMsg,numIter+1);
        (cache, Values.BOOL(boolean = left_justified)) =
          ceval(cache, inEnv, justifiedExp, inBoolean, inMsg,numIter+1);
        str = ExpressionSimplify.cevalBuiltinStringFormat(inString, stringLength(inString), min_length, left_justified);
      then
        (cache, str);
  end match;
end cevalBuiltinStringFormat;

protected function cevalBuiltinPrint
  "Prints a String to stdout"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.STRING(str)) = ceval(cache,env, exp, impl, msg,numIter+1);
        print(str);
      then
        (cache,Values.NORETCALL());
  end match;
end cevalBuiltinPrint;

protected function cevalIntString
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.INTEGER(i)) = ceval(cache,env, exp, impl, msg,numIter+1);
        str = intString(i);
      then
        (cache,Values.STRING(str));
  end match;
end cevalIntString;

protected function cevalRealString
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      Real r;
      Values.Value v;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,v) = ceval(cache,env, exp, impl, msg,numIter+1);
        Values.REAL(r) = v;
        str = realString(r);
      then
        (cache,Values.STRING(str));
  end match;
end cevalRealString;

protected function cevalStringCharInt
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.STRING(str)) = ceval(cache,env, exp, impl, msg,numIter+1);
        i = stringCharInt(str);
      then
        (cache,Values.INTEGER(i));
  end match;
end cevalStringCharInt;

protected function cevalIntStringChar
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.INTEGER(i)) = ceval(cache,env, exp, impl, msg,numIter+1);
        str = intStringChar(i);
      then
        (cache,Values.STRING(str));
  end match;
end cevalIntStringChar;

protected function cevalStringInt
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.STRING(str)) = ceval(cache,env, exp, impl, msg,numIter+1);
        i = stringInt(str);
      then
        (cache,Values.INTEGER(i));
  end match;
end cevalStringInt;


protected function cevalStringLength
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      Integer i;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.STRING(str)) = ceval(cache,env, exp, impl, msg,numIter+1);
        i = stringLength(str);
      then
        (cache,Values.INTEGER(i));
  end match;
end cevalStringLength;

protected function cevalStringListStringChar
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.STRING(str)) = ceval(cache,env, exp, impl, msg,numIter+1);
        chList = stringListStringChar(str);
        valList = List.map(chList, generateValueString);
      then
        (cache,Values.LIST(valList));
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.LIST(valList)) = ceval(cache,env, exp, impl,msg,numIter+1);
        // Note that the RML version of the function has a weird name, but is also not implemented yet!
        // The work-around is to check that each String has length 1 and append all the Strings together
        // WARNING: This can be very, very slow for long lists - it grows as O(n^2)
        // TODO: When implemented, use listStringCharString (OMC name) or stringCharListString (RML name) directly
        chList = List.map(valList, extractValueStringChar);
        str = stringAppendList(chList);
      then
        (cache,Values.STRING(str));
  end match;
end cevalListStringCharString;

protected function cevalStringAppendList
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.LIST(valList)) = ceval(cache,env, exp, impl, msg,numIter+1);
        chList = List.map(valList, ValuesUtil.extractValueString);
        str = stringAppendList(chList);
      then
        (cache,Values.STRING(str));
  end match;
end cevalStringAppendList;

protected function cevalStringDelimitList
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      list<String> chList;
      list<Values.Value> valList;
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.LIST(valList)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.STRING(str)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        chList = List.map(valList, ValuesUtil.extractValueString);
        str = stringDelimitList(chList,str);
      then
        (cache,Values.STRING(str));
  end match;
end cevalStringDelimitList;

protected function cevalListLength
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Integer i;
      list<Values.Value> valList;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.LIST(valList)) = ceval(cache,env, exp, impl, msg,numIter+1);
        i = listLength(valList);
      then
        (cache,Values.INTEGER(i));
  end match;
end cevalListLength;

protected function cevalListAppend
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      list<Values.Value> valList,valList1,valList2;
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.LIST(valList1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.LIST(valList2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        valList = listAppend(valList1, valList2);
      then
        (cache,Values.LIST(valList));
  end match;
end cevalListAppend;

protected function cevalListReverse
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp1;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      list<Values.Value> valList,valList1;
    case (cache,env,{exp1},impl,msg,_)
      equation
        (cache,Values.LIST(valList1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        valList = listReverse(valList1);
      then
        (cache,Values.LIST(valList));
  end match;
end cevalListReverse;

protected function cevalListRest
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp1;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      list<Values.Value> valList1;
    case (cache,env,{exp1},impl,msg,_)
      equation
        (cache,Values.LIST(_::valList1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
      then
        (cache,Values.LIST(valList1));
  end match;
end cevalListRest;

protected function cevalListMember
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      list<Values.Value> vals;
      Values.Value val;
      Boolean b;
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,val) = ceval(cache,env,exp1,impl,msg,numIter+1);
        (cache,Values.LIST(vals)) = ceval(cache,env,exp2,impl,msg,numIter+1);
        b = listMember(val,vals);
      then
        (cache,Values.BOOL(b));
  end match;
end cevalListMember;

protected function cevalListArrayLiteral
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      list<Values.Value> vals;
      Values.Value val;
      Boolean b;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.LIST(vals)) = ceval(cache,env,exp,impl,msg,numIter+1);
      then
        (cache,Values.META_ARRAY(vals));
  end match;
end cevalListArrayLiteral;

protected function cevalAnyString
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp1;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Values.Value v;
      String s;
    case (cache,env,{exp1},impl,msg,_)
      equation
        (cache,v) = ceval(cache,env, exp1, impl, msg,numIter+1);
        s = ValuesUtil.valString(v);
      then
        (cache,Values.STRING(s));
  end match;
end cevalAnyString;

protected function cevalNumBits
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Integer i;
    case (_,_,{},_,_,_)
      equation
         i = System.numBits();
      then
        (inCache,Values.INTEGER(i));
  end match;
end cevalNumBits;

protected function cevalIntegerMax
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Integer i;
    case (_,_,{},_,_,_)
      equation
         i = System.intMaxLit();
      then
        (inCache,Values.INTEGER(i));
  end match;
end cevalIntegerMax;

function cevalIntBitAnd
  input output FCore.Cache cache;
  input FCore.Graph env;
  input list<DAE.Exp> args;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
        output Values.Value result;
protected
  DAE.Exp e1, e2;
  Integer i1, i2;
algorithm
  e1 :: e2 :: _ := args;
  (cache, Values.INTEGER(i1)) := ceval(cache, env, e1, impl, msg, numIter + 1);
  (cache, Values.INTEGER(i2)) := ceval(cache, env, e2, impl, msg, numIter + 1);
  result := Values.INTEGER(intBitAnd(i1, i2));
end cevalIntBitAnd;

function cevalIntBitOr
  input output FCore.Cache cache;
  input FCore.Graph env;
  input list<DAE.Exp> args;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
        output Values.Value result;
protected
  DAE.Exp e1, e2;
  Integer i1, i2;
algorithm
  e1 :: e2 :: _ := args;
  (cache, Values.INTEGER(i1)) := ceval(cache, env, e1, impl, msg, numIter + 1);
  (cache, Values.INTEGER(i2)) := ceval(cache, env, e2, impl, msg, numIter + 1);
  result := Values.INTEGER(intBitOr(i1, i2));
end cevalIntBitOr;

function cevalIntBitXor
  input output FCore.Cache cache;
  input FCore.Graph env;
  input list<DAE.Exp> args;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
        output Values.Value result;
protected
  DAE.Exp e1, e2;
  Integer i1, i2;
algorithm
  e1 :: e2 :: _ := args;
  (cache, Values.INTEGER(i1)) := ceval(cache, env, e1, impl, msg, numIter + 1);
  (cache, Values.INTEGER(i2)) := ceval(cache, env, e2, impl, msg, numIter + 1);
  result := Values.INTEGER(intBitXor(i1, i2));
end cevalIntBitXor;

function cevalIntBitLShift
  input output FCore.Cache cache;
  input FCore.Graph env;
  input list<DAE.Exp> args;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
        output Values.Value result;
protected
  DAE.Exp e1, e2;
  Integer i, s;
algorithm
  e1 :: e2 :: _ := args;
  (cache, Values.INTEGER(i)) := ceval(cache, env, e1, impl, msg, numIter + 1);
  (cache, Values.INTEGER(s)) := ceval(cache, env, e2, impl, msg, numIter + 1);
  result := Values.INTEGER(intBitLShift(i, s));
end cevalIntBitLShift;

function cevalIntBitRShift
  input output FCore.Cache cache;
  input FCore.Graph env;
  input list<DAE.Exp> args;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
        output Values.Value result;
protected
  DAE.Exp e1, e2;
  Integer i, s;
algorithm
  e1 :: e2 :: _ := args;
  (cache, Values.INTEGER(i)) := ceval(cache, env, e1, impl, msg, numIter + 1);
  (cache, Values.INTEGER(s)) := ceval(cache, env, e2, impl, msg, numIter + 1);
  result := Values.INTEGER(intBitRShift(i, s));
end cevalIntBitRShift;

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
    case (SCode.CLASS(info=SOURCEINFO(fileName="<interactive>")),_) then acc;
    case (SCode.CLASS(name=name,info=SOURCEINFO(fileName=fileName)),_)
      equation
        dir = System.dirname(fileName);
        fileName = System.basename(fileName);
        v = ValuesUtil.makeArray({Values.STRING(name),Values.STRING(dir)});
        b = stringEq(fileName,"ModelicaBuiltin.mo") or stringEq(fileName,"MetaModelicaBuiltin.mo") or stringEq(dir,".");
      then List.consOnTrue(not b,v,acc);
  end match;
end makeLoadLibrariesEntry;

protected function cevalListFirst
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp1;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Values.Value v;
    case (cache,env,{exp1},impl,msg,_)
      equation
        (cache,Values.LIST(v::_)) = ceval(cache,env, exp1, impl, msg,numIter+1);
      then
        (cache,ValuesUtil.boxIfUnboxedVal(v));
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
        (Values.ARRAY(dimLst = i2::il) :: _) = v_lst_1;
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
        l_lst = listHead(lst);
        1 = listLength(l_lst);
        first_lst = List.map(lst, listHead);
        first_lst_1 = catDimension(first_lst, dim);
        first_lst_2 = List.map(first_lst_1, List.create);
      then
        first_lst_2;
    case (lst,dim)
      equation
        first_lst = List.map(lst, listHead);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        rv_1 = floor(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinFloor;

protected function cevalBuiltinCeil "author: LP
  evaluates the ceil operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match(inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1,rvt,realRet;
      Integer ri,ri_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Values.Value v;

    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache, env, exp, impl, msg, numIter+1);

        rv_1 = floor(rv);
        ri = realInt(rv_1);
        rvt = intReal(ri);
        ri_1 = ri + 1;
        realRet = intReal(ri_1);

        v = if (rvt == rv) then Values.REAL(rvt) else Values.REAL(realRet);
      then
        (cache,v);

  end match;
end cevalBuiltinCeil;

protected function cevalBuiltinSqrt "author: LP
  Evaluates the builtin sqrt operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match(inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      SourceInfo info;

    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        if (rv < 0.0)
        then
          Absyn.MSG(info = info) = msg;
          Error.addSourceMessage(Error.NEGATIVE_SQRT, {}, info);
          fail();
        else
          rv_1 = sqrt(rv);
        end if;
      then
        (cache,Values.REAL(rv_1));

  end match;
end cevalBuiltinSqrt;

protected function cevalBuiltinSin "author: LP
  Evaluates the builtin sin function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl, msg, numIter+1);
        rv_1 = sin(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinSin;

protected function cevalBuiltinSinh "author: PA
  Evaluates the builtin sinh function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        rv_1 = sinh(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinSinh;

protected function cevalBuiltinCos "author: LP
  Evaluates the builtin cos function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        rv_1 = cos(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinCos;

protected function cevalBuiltinCosh "author: PA
  Evaluates the builtin cosh function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        rv_1 = cosh(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinCosh;

protected function cevalBuiltinLog "author: LP
  Evaluates the builtin Log function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl, msg,numIter+1);
        true = rv > 0; // TODO: Print error-message?
        rv_1 = log(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinLog;

protected function cevalBuiltinLog10
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        true = rv > 0; // TODO: Print error-message?
        rv_1 = log10(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinLog10;

protected function cevalBuiltinTan "author: LP
  Evaluates the builtin tan function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      FCore.Cache cache;
    case (cache,env,{exp})
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl, msg,numIter+1);
        rv_1 = tan(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinTan;

protected function cevalBuiltinTanh "author: PA
  Evaluates the builtin tanh function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
         rv_1 = tanh(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinTanh;

protected function cevalBuiltinAsin "author: PA
  Evaluates the builtin asin function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        true = rv >= -1.0 and rv <= 1.0;
        rv_1 = asin(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinAsin;

protected function cevalBuiltinAcos "author: PA
  Evaluates the builtin acos function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        true = rv >= -1.0 and rv <= 1.0;
        rv_1 = acos(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinAcos;

protected function cevalBuiltinAtan "author: PA
  Evaluates the builtin atan function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_) /* atan is not implemented in MetaModelica Compiler (MMC) for some strange reason. */
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env, exp, impl,msg,numIter+1);
        rv_1 = atan(rv);
      then
        (cache,Values.REAL(rv_1));
  end match;
end cevalBuiltinAtan;

protected function cevalBuiltinAtan2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv,rv_1,rv_2;
      FCore.Graph env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.REAL(rv_1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.REAL(rv_2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        rv = atan2(rv_1,rv_2);
      then
        (cache,Values.REAL(rv));
  end match;
end cevalBuiltinAtan2;

protected function cevalBuiltinDiv "author: LP
  Evaluates the builtin div operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv1,rv2,rv_1,rv_2;
      Integer ri,ri_1,ri1,ri2;
      FCore.Graph env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Absyn.Msg msg;
      String exp1_str,exp2_str,lh_str,rh_str;
      FCore.Cache cache; Boolean b;
      SourceInfo info;

    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.REAL(rv1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.REAL(rv2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        rv_1 = rv1 / rv2;
        b = rv_1 < 0.0;
        rv_2 = if b then ceil(rv_1) else floor(rv_1);
      then
        (cache,Values.REAL(rv_2));
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.INTEGER(ri)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        Error.addInternalError("cevalBuiltinDiv got Integer and Real (type error)\n", sourceInfo());
        rv_1 = rv1 / rv2;
         b = rv_1 < 0.0;
        rv_2 = if b then ceil(rv_1) else floor(rv_1);
      then
        (cache,Values.REAL(rv_2));
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.REAL(rv1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.INTEGER(ri)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        Error.addInternalError("cevalBuiltinDiv got Real and Integer (type error)\n", sourceInfo());
        rv2 = intReal(ri);
        rv_1 = rv1 / rv2;
        b = rv_1 < 0.0;
        rv_2 = if b then ceil(rv_1) else floor(rv_1);
      then
        (cache,Values.REAL(rv_2));
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.INTEGER(ri1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.INTEGER(ri2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        ri_1 = intDiv(ri1,ri2);
      then
        (cache,Values.INTEGER(ri_1));
    case (cache,env,{exp1,exp2},impl,Absyn.MSG(info = info),_)
      equation
        (_,Values.REAL(rv2)) = ceval(cache,env, exp2, impl, inMsg,numIter+1);
        (rv2 == 0.0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.DIVISION_BY_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
    case (cache,env,{_,exp2},impl,Absyn.NO_MSG(),_)
      equation
        (_,Values.REAL(rv2)) = ceval(cache,env, exp2, impl, Absyn.NO_MSG(),numIter+1);
        (rv2 == 0.0) = true;
      then
        fail();
    case (cache,env,{exp1,exp2},impl,Absyn.MSG(info = info),_)
      equation
        (_,Values.INTEGER(ri2)) = ceval(cache,env, exp2, impl,  inMsg,numIter+1);
        (ri2 == 0) = true;
        lh_str = ExpressionDump.printExpStr(exp1);
        rh_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.DIVISION_BY_ZERO, {lh_str,rh_str}, info);
      then
        fail();
    case (cache,env,{_,exp2},impl,Absyn.NO_MSG(),_)
      equation
        (_,Values.INTEGER(ri2)) = ceval(cache,env, exp2, impl, Absyn.NO_MSG(),numIter+1);
        (ri2 == 0) = true;
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiv;

protected function cevalBuiltinMod "author: LP
  Evaluates the builtin mod operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
  output FCore.Cache cache = inCache;
  output Values.Value outValue;
protected
  Values.Value v1, v2;
  DAE.Exp exp1,exp2;
algorithm
  {exp1,exp2} := inExpExpLst;
  (cache,v1) := ceval(cache,inEnv, exp1, impl, msg,numIter+1);
  (cache,v2) := ceval(cache,inEnv, exp2, impl, msg,numIter+1);
  outValue := match (v1,v2,msg)
    local
      Real rv1,rv2;
      Integer ri,ri1,ri2;
      String lhs_str,rhs_str;
      SourceInfo info;

    case (Values.REAL(rv1),Values.REAL(rv2),_)
      then (Values.REAL(mod(rv1,rv2)));
    case (Values.INTEGER(ri),Values.REAL(rv2),_)
      then (Values.REAL(mod(ri,rv2)));
    case (Values.REAL(rv1),Values.INTEGER(ri),_)
      then (Values.REAL(mod(rv1,ri)));
    case (Values.INTEGER(ri1),Values.INTEGER(ri2),_)
      then (Values.INTEGER(mod(ri1,ri2)));
    case (_,Values.REAL(rv2),Absyn.MSG(info = info))
      guard rv2 == 0.0
      equation
        lhs_str = ExpressionDump.printExpStr(exp1);
        rhs_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str}, info);
      then fail();
    case (_,Values.INTEGER(0),Absyn.MSG(info = info))
      equation
        lhs_str = ExpressionDump.printExpStr(exp1);
        rhs_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.MODULO_BY_ZERO, {lhs_str,rhs_str}, info);
      then
        fail();
  end match;
end cevalBuiltinMod;

protected function cevalBuiltinSum "Evaluates the builtin sum function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Values.Value v;
      list<Values.Value> vals;
      FCore.Graph env;
      DAE.Exp arr;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{arr},impl,msg,_)
      algorithm
        (cache, Values.ARRAY(valueLst = vals)) := ceval(cache,env, arr, impl, msg, numIter+1);
        if Types.isInteger(Expression.typeof(arr)) then
          if listEmpty(vals) then
            v := Values.INTEGER(0);
          else
            (v as Values.INTEGER()) := ValuesUtil.sumArrayelt(vals);
          end if;
        else
          if listEmpty(vals) then
            v := Values.REAL(0.0);
          else
            (v as Values.REAL()) := ValuesUtil.sumArrayelt(vals);
          end if;
        end if;
      then (cache,v);
  end match;
end cevalBuiltinSum;

protected function cevalBuiltinMax "author: LP
  Evaluates the builtin max function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Values.Value v,v1,v2,v_1;
      FCore.Graph env;
      DAE.Exp arr,s1,s2;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{arr},impl,msg,_)
      equation
        (cache,v) = ceval(cache,env, arr, impl, msg,numIter+1);
        (v_1) = cevalBuiltinMaxArr(v);
      then
        (cache,v_1);
    case (cache,env,{s1,s2},impl,msg,_)
      equation
        (cache,v1) = ceval(cache,env, s1, impl, msg,numIter+1);
        (cache,v2) = ceval(cache,env, s2, impl, msg,numIter+1);
        v = cevalBuiltinMax2(v1,v2);
      then
        (cache,v);
  end match;
end cevalBuiltinMax;

protected function cevalBuiltinMax2
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value outValue;
algorithm
  outValue := match (v1,v2)
    local
      Integer i1, i2;
      Real r1, r2;
      Boolean b1, b2;
      String s1, s2;

    case (Values.INTEGER(i1), Values.INTEGER(i2)) then Values.INTEGER(max(i1, i2));
    case (Values.REAL(r1), Values.REAL(r2)) then Values.REAL(max(r1, r2));
    case (Values.BOOL(b1), Values.BOOL(b2)) then Values.BOOL(b1 or b2);
    case (Values.ENUM_LITERAL(), Values.ENUM_LITERAL())
      then if v1.index > v2.index then v1 else v2;
    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        s1 := ValuesUtil.valString(v1);
        s2 := ValuesUtil.valString(v2);
        Debug.traceln("- Ceval.cevalBuiltinMin2 failed: min(" + s1 + ", " + s2 + ")");
      then
        fail();
  end match;
end cevalBuiltinMax2;

protected function cevalBuiltinMaxArr "Helper function to cevalBuiltinMax."
  input Values.Value inValue;
  output Values.Value outValue;
protected
  list<Values.Value> vals;
algorithm
  Values.ARRAY(valueLst = vals) := inValue;
  outValue := cevalBuiltinMax2(v for v in vals);
end cevalBuiltinMaxArr;

protected function cevalBuiltinMin "author: PA
  Constant evaluation of builtin min function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Values.Value v,v1,v2,v_1;
      FCore.Graph env;
      DAE.Exp arr,s1,s2;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{arr},impl,msg,_)
      equation
        (cache,v) = ceval(cache,env, arr, impl, msg,numIter+1);
        (v_1) = cevalBuiltinMinArr(v);
      then
        (cache,v_1);
    case (cache,env,{s1,s2},impl,msg,_)
      equation
        (cache,v1) = ceval(cache,env, s1, impl, msg,numIter+1);
        (cache,v2) = ceval(cache,env, s2, impl, msg,numIter+1);
        v = cevalBuiltinMin2(v1, v2);
      then
        (cache,v);
  end match;
end cevalBuiltinMin;

protected function cevalBuiltinMin2
  input Values.Value v1;
  input Values.Value v2;
  output Values.Value outValue;
algorithm
  outValue := match (v1, v2)
    local
      Integer i1, i2;
      Real r1, r2;
      Boolean b1, b2;
      String s1, s2;
      SourceInfo info;

    case (Values.INTEGER(i1), Values.INTEGER(i2)) then Values.INTEGER(min(i1, i2));
    case (Values.REAL(r1), Values.REAL(r2)) then Values.REAL(min(r1, r2));
    case (Values.BOOL(b1), Values.BOOL(b2)) then Values.BOOL(b1 and b2);
    case (Values.ENUM_LITERAL(), Values.ENUM_LITERAL())
      then if v1.index < v2.index then v1 else v2;
    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        s1 := ValuesUtil.valString(v1);
        s2 := ValuesUtil.valString(v2);
        Debug.traceln("- Ceval.cevalBuiltinMin2 failed: min(" + s1 + ", " + s2 + ")");
      then
        fail();

  end match;
end cevalBuiltinMin2;

protected function cevalBuiltinMinArr "Helper function to cevalBuiltinMin."
  input Values.Value inValue;
  output Values.Value outValue;
protected
  list<Values.Value> vals;
algorithm
  Values.ARRAY(valueLst = vals) := inValue;
  outValue := cevalBuiltinMin2(v for v in vals);
end cevalBuiltinMinArr;

protected function cevalBuiltinRem "author: LP
  Evaluates the builtin rem operator"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv1,rv2,rvd,dr;
      Integer ri,ri1,ri2,ri_1,di;
      FCore.Graph env;
      DAE.Exp exp1,exp2;
      Boolean impl;
      Absyn.Msg msg;
      String exp1_str,exp2_str;
      FCore.Cache cache;
      SourceInfo info;

    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.REAL(rv1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.REAL(rv2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        (cache,Values.REAL(dr)) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,msg,numIter+1);
        rvd = rv1 - rv2 * dr;
      then
        (cache,Values.REAL(rvd));
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.INTEGER(ri)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        rv1 = intReal(ri);
        (cache,Values.REAL(rv2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        (cache,Values.REAL(dr)) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,msg,numIter+1);
        rvd = rv1 - rv2 * dr;
      then
        (cache,Values.REAL(rvd));
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.REAL(rv1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.INTEGER(ri)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        rv2 = intReal(ri);
        (cache,Values.REAL(dr)) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,msg,numIter+1);
        rvd = rv1 - rv2 * dr;
      then
        (cache,Values.REAL(rvd));
    case (cache,env,{exp1,exp2},impl,msg,_)
      equation
        (cache,Values.INTEGER(ri1)) = ceval(cache,env, exp1, impl, msg,numIter+1);
        (cache,Values.INTEGER(ri2)) = ceval(cache,env, exp2, impl, msg,numIter+1);
        (cache,Values.INTEGER(di)) = cevalBuiltinDiv(cache,env,{exp1,exp2},impl,msg,numIter+1);
        ri_1 = ri1 - ri2 * di;
      then
        (cache,Values.INTEGER(ri_1));
    case (cache,env,{exp1,exp2},impl,Absyn.MSG(info = info),_)
      equation
        (_,Values.REAL(rv2)) = ceval(cache,env,exp2,impl,inMsg,numIter+1);
        (rv2 == 0.0) = true;
        exp1_str = ExpressionDump.printExpStr(exp1);
        exp2_str = ExpressionDump.printExpStr(exp2);
        Error.addSourceMessage(Error.REM_ARG_ZERO, {exp1_str,exp2_str}, info);
      then
        fail();
    case (cache,env,{exp1,exp2},impl,Absyn.MSG(info = info),_)
      equation
        (_,Values.INTEGER(ri2)) = ceval(cache,env, exp2, impl, inMsg,numIter+1);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv;
      Integer ri;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.REAL(rv)) = ceval(cache,env,exp,impl,msg,numIter+1);
        ri = realInt(rv);
      then
        (cache,Values.INTEGER(ri));
  end match;
end cevalBuiltinInteger;

protected function cevalBuiltinBoolean " @author: adrpo
  Evaluates the builtin boolean operator"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Real rv;
      Integer iv;
      Boolean bv;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Boolean b;
      Values.Value v;

    // real/integer/bool -> bool
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,v) = ceval(cache, env, exp, impl,  msg, numIter+1);
        b = match v
              case Values.REAL(rv) then not realEq(rv, 0.0);
              case Values.INTEGER(iv) then not intEq(iv, 0);
              case Values.BOOL(bv) then bv;
            end match;
      then
        (cache,Values.BOOL(b));

  end match;
end cevalBuiltinBoolean;

protected function cevalBuiltinRooted
"author: adrpo
  Evaluates the builtin rooted operator from MultiBody"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,_) = ceval(cache,env,exp,impl,msg,numIter+1);
      then
        (cache,Values.BOOL(true));
  end match;
end cevalBuiltinRooted;

protected function cevalBuiltinIntegerEnumeration "author: LP
  Evaluates the builtin Integer operator"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  match (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      Integer ri;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,{exp},impl,msg,_)
      equation
        (cache,Values.ENUM_LITERAL(index = ri)) = ceval(cache,env,exp,impl,msg,numIter+1);
      then
        (cache,Values.INTEGER(ri));
  end match;
end cevalBuiltinIntegerEnumeration;

protected function cevalBuiltinDiagonal "This function generates a matrix{n,n} (A) of the vector {a,b,...,n}
  where the diagonal of A is the vector {a,b,...,n}
  ie A{1,1} == a, A{2,2} == b ..."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      list<Values.Value> vals,retExp;
      Integer dimension,correctDimension;
      FCore.Graph env;
      DAE.Exp exp;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Values.Value res;
      SourceInfo info;
      Values.Value zero;
      DAE.Type ty;

    case (cache,env,{exp},impl,msg,_)
      algorithm
        DAE.T_ARRAY(ty=ty) := Expression.typeof(exp);
        (cache,Values.ARRAY(vals,{dimension})) := ceval(cache,env,exp,impl,msg,numIter+1);
        zero := ValuesUtil.makeZero(ty);
        res := Values.ARRAY(list(Values.ARRAY(list(if i==j then listGet(vals,i) else zero for i in 1:dimension),{dimension}) for j in 1:dimension), {dimension,dimension});
      then
        (cache,res);
    case (_,_,_,_,Absyn.MSG(info = info),_)
      equation
        Error.addSourceMessage(Error.COMPILER_ERROR,
          {"Could not evaluate diagonal. Ceval.cevalBuiltinDiagonal failed."}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinDiagonal;

protected function cevalBuiltinCross "
  x,y => {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue):=
  matchcontinue (inCache,inEnv,inExpExpLst,inBoolean,inMsg,numIter)
    local
      list<Values.Value> xv,yv;
      Values.Value res;
      FCore.Graph env;
      DAE.Exp xe,ye;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      String str;
      SourceInfo info;

    case (cache,env,{xe,ye},impl,msg,_)
      equation
        (cache,Values.ARRAY(xv,{3})) = ceval(cache,env,xe,impl,msg,numIter+1);
        (cache,Values.ARRAY(yv,{3})) = ceval(cache,env,ye,impl,msg,numIter+1);
        res = ValuesUtil.crossProduct(xv,yv);
      then
        (cache,res);
    case (_,_,_,_,Absyn.MSG(info = info),_)
      equation
        str = "cross" + ExpressionDump.printExpStr(DAE.TUPLE(inExpExpLst));
        Error.addSourceMessage(Error.FAILED_TO_EVALUATE_EXPRESSION, {str}, info);
      then
        fail();
  end matchcontinue;
end cevalBuiltinCross;

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
    else {};
  end matchcontinue;
end cevalBuiltinTranspose2;

protected function cevalBuiltinSizeMatrix "Helper function for cevalBuiltinSize, for size(A) where A is a matrix."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inMsg,numIter)
    local
      DAE.Type tp;
      list<Integer> sizelst;
      Values.Value v;
      FCore.Graph env;
      DAE.ComponentRef cr;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      DAE.Exp exp;
      DAE.Dimensions dims;

    // size(cr)
    case (cache,env,DAE.CREF(componentRef = cr),_,_,_)
      equation
        (cache,_,tp,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        sizelst = Types.getDimensionSizes(tp);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v);

    // For matrix expressions: [1,2;3,4]
    case (cache, _, DAE.MATRIX(ty = DAE.T_ARRAY(dims = dims)), _, _, _)
      equation
        sizelst = List.map(dims, Expression.dimensionSize);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache, v);

    // For other matrix expressions e.g. on array form: {{1,2},{3,4}}
    case (cache,env,exp,impl,msg,_)
      equation
        (cache,Values.ARRAY(dimLst=sizelst)) = ceval(cache,env, exp, impl, msg,numIter+1);
        v = ValuesUtil.intlistToValue(sizelst);
      then
        (cache,v);
  end matchcontinue;
end cevalBuiltinSizeMatrix;

protected function cevalBuiltinFail
  "This function constant evaluates calls to the fail() function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpl;
  input Boolean inImpl;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  outCache := inCache;
  outValue := Values.META_FAIL();
end cevalBuiltinFail;

protected function cevalBuiltinFill
  "This function constant evaluates calls to the fill function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpl;
  input Boolean inImpl;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) :=
  match (inCache, inEnv, inExpl, inImpl, inMsg, numIter)
    local
      DAE.Exp fill_exp;
      list<DAE.Exp> dims;
      Values.Value fill_val;
      FCore.Cache cache;
    case (cache, _, fill_exp :: dims, _, _, _)
      equation
        (cache, fill_val) = ceval(cache, inEnv, fill_exp, inImpl, inMsg, numIter+1);
        (cache, fill_val) = cevalBuiltinFill2(cache, inEnv, fill_val, dims, inImpl, inMsg, numIter);
      then
        (cache, fill_val);
  end match;
end cevalBuiltinFill;

protected function cevalBuiltinFill2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Values.Value inFillValue;
  input list<DAE.Exp> inDims;
  input Boolean inImpl;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) :=
  match (inCache, inEnv, inFillValue, inDims, inImpl, inMsg, numIter)
    local
      DAE.Exp dim;
      list<DAE.Exp> rest_dims;
      Integer int_dim;
      list<Integer> array_dims;
      Values.Value fill_value;
      list<Values.Value> fill_vals;
      FCore.Cache cache;

    case (cache, _, _, {}, _, _, _) then (cache, inFillValue);

    case (cache, _, _, dim :: rest_dims, _, _, _)
      equation
        (cache, fill_value) = cevalBuiltinFill2(cache, inEnv, inFillValue,
          rest_dims, inImpl, inMsg, numIter);
        (cache, Values.INTEGER(int_dim)) = ceval(cache, inEnv, dim, inImpl, inMsg, numIter+1);
        fill_vals = List.fill(fill_value, int_dim);
        array_dims = ValuesUtil.valueDimensions(fill_value);
        array_dims = int_dim :: array_dims;
      then
        (cache, Values.ARRAY(fill_vals, array_dims));
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
  result := matchcontinue inOperator
    case DAE.GREATER()   then cevalRelationLess(inValue2, inValue1);
    case DAE.LESS()      then cevalRelationLess(inValue1, inValue2);
    case DAE.LESSEQ()    then cevalRelationLessEq(inValue1, inValue2);
    case DAE.GREATEREQ() then cevalRelationGreaterEq(inValue1, inValue2);
    case DAE.EQUAL()     then cevalRelationEqual(inValue1, inValue2);
    case DAE.NEQUAL()    then cevalRelationNotEqual(inValue1, inValue2);

    else
      algorithm
        true := Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Ceval.cevalRelation failed on: " +
          ValuesUtil.printValStr(inValue1) +
          ExpressionDump.relopSymbol(inOperator) +
          ValuesUtil.printValStr(inValue2));
      then
        fail();
  end matchcontinue;

  outValue := Values.BOOL(result);
end cevalRelation;

protected function cevalRelationLess
  "Returns whether the first value is less than the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    case (Values.STRING(),       Values.STRING())       then (stringCompare(inValue1.string, inValue2.string) < 0);
    case (Values.BOOL(),         Values.BOOL())         then (inValue1.boolean < inValue2.boolean);
    case (Values.INTEGER(),      Values.INTEGER())      then (inValue1.integer < inValue2.integer);
    case (Values.REAL(),         Values.REAL())         then (inValue1.real < inValue2.real);
    case (Values.INTEGER(),      Values.REAL())         then (intReal(inValue1.integer) < inValue2.real);
    case (Values.REAL(),         Values.INTEGER())      then (inValue1.real < intReal(inValue2.integer));
    case (Values.ENUM_LITERAL(), Values.ENUM_LITERAL()) then (inValue1.index < inValue2.index);
    case (Values.ENUM_LITERAL(), Values.INTEGER())      then (inValue1.index < inValue2.integer);
    case (Values.INTEGER(),      Values.ENUM_LITERAL()) then (inValue1.integer < inValue2.index);
  end match;
end cevalRelationLess;

protected function cevalRelationLessEq
  "Returns whether the first value is less than or equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    case (Values.STRING(),       Values.STRING())       then (stringCompare(inValue1.string, inValue2.string) <= 0);
    case (Values.BOOL(),         Values.BOOL())         then (inValue1.boolean <= inValue2.boolean);
    case (Values.INTEGER(),      Values.INTEGER())      then (inValue1.integer <= inValue2.integer);
    case (Values.REAL(),         Values.REAL())         then (inValue1.real <= inValue2.real);
    case (Values.INTEGER(),      Values.REAL())         then (intReal(inValue1.integer) <= inValue2.real);
    case (Values.REAL(),         Values.INTEGER())      then (inValue1.real <= intReal(inValue2.integer));
    case (Values.ENUM_LITERAL(), Values.ENUM_LITERAL()) then (inValue1.index <= inValue2.index);
    case (Values.ENUM_LITERAL(), Values.INTEGER())      then (inValue1.index <= inValue2.integer);
    case (Values.INTEGER(),      Values.ENUM_LITERAL()) then (inValue1.integer <= inValue2.index);
  end match;
end cevalRelationLessEq;

protected function cevalRelationGreaterEq
  "Returns whether the first value is greater than or equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    case (Values.STRING(),       Values.STRING())       then (stringCompare(inValue1.string, inValue2.string) >= 0);
    case (Values.BOOL(),         Values.BOOL())         then (inValue1.boolean >= inValue2.boolean);
    case (Values.INTEGER(),      Values.INTEGER())      then (inValue1.integer >= inValue2.integer);
    case (Values.REAL(),         Values.REAL())         then (inValue1.real >= inValue2.real);
    case (Values.INTEGER(),      Values.REAL())         then (intReal(inValue1.integer) >= inValue2.real);
    case (Values.REAL(),         Values.INTEGER())      then (inValue1.real >= intReal(inValue2.integer));
    case (Values.ENUM_LITERAL(), Values.ENUM_LITERAL()) then (inValue1.index >= inValue2.index);
    case (Values.ENUM_LITERAL(), Values.INTEGER())      then (inValue1.index >= inValue2.integer);
    case (Values.INTEGER(),      Values.ENUM_LITERAL()) then (inValue1.integer >= inValue2.index);
  end match;
end cevalRelationGreaterEq;

protected function cevalRelationEqual
  "Returns whether the first value is equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    case (Values.STRING(),       Values.STRING())       then (stringCompare(inValue1.string, inValue2.string) == 0);
    case (Values.BOOL(),         Values.BOOL())         then (inValue1.boolean == inValue2.boolean);
    case (Values.INTEGER(),      Values.INTEGER())      then (inValue1.integer == inValue2.integer);
    case (Values.REAL(),         Values.REAL())         then (inValue1.real == inValue2.real);
    case (Values.INTEGER(),      Values.REAL())         then (intReal(inValue1.integer) == inValue2.real);
    case (Values.REAL(),         Values.INTEGER())      then (inValue1.real == intReal(inValue2.integer));
    case (Values.ENUM_LITERAL(), Values.ENUM_LITERAL()) then (inValue1.index == inValue2.index);
    case (Values.ENUM_LITERAL(), Values.INTEGER())      then (inValue1.index == inValue2.integer);
    case (Values.INTEGER(),      Values.ENUM_LITERAL()) then (inValue1.integer == inValue2.index);
  end match;
end cevalRelationEqual;

protected function cevalRelationNotEqual
  "Returns whether the first value is not equal to the second value."
  input Values.Value inValue1;
  input Values.Value inValue2;
  output Boolean result;
algorithm
  result := match(inValue1, inValue2)
    case (Values.STRING(),       Values.STRING())       then (stringCompare(inValue1.string, inValue2.string) <> 0);
    case (Values.BOOL(),         Values.BOOL())         then (inValue1.boolean <> inValue2.boolean);
    case (Values.INTEGER(),      Values.INTEGER())      then (inValue1.integer <> inValue2.integer);
    case (Values.REAL(),         Values.REAL())         then (inValue1.real <> inValue2.real);
    case (Values.INTEGER(),      Values.REAL())         then (intReal(inValue1.integer) <> inValue2.real);
    case (Values.REAL(),         Values.INTEGER())      then (inValue1.real <> intReal(inValue2.integer));
    case (Values.ENUM_LITERAL(), Values.ENUM_LITERAL()) then (inValue1.index <> inValue2.index);
    case (Values.ENUM_LITERAL(), Values.INTEGER())      then (inValue1.index <> inValue2.integer);
    case (Values.INTEGER(),      Values.ENUM_LITERAL()) then (inValue1.integer <> inValue2.index);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> inExpExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache = inCache;
  output list<Values.Value> outValuesValueLst = {};
protected
  list<DAE.Exp> expLstNew = inExpExpLst;
  Values.Value v;
algorithm
  for exp in expLstNew loop
    (outCache, v) := ceval(outCache, inEnv, exp, inBoolean, inMsg, numIter+1);
    outValuesValueLst := v :: outValuesValueLst;
  end for;
  outValuesValueLst := listReverseInPlace(outValuesValueLst);
end cevalList;

public function cevalCref "Evaluates ComponentRef, i.e. variables, by
  looking up variables in the environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean,inMsg,numIter)
    local
      DAE.Binding binding;
      Values.Value v;
      FCore.Graph env, classEnv, componentEnv;
      DAE.ComponentRef c;
      Boolean impl;
      Absyn.Msg msg;
      String scope_str,str, name;
      FCore.Cache cache;
      Option<DAE.Const> const_for_range;
      DAE.Type ty;
      DAE.Attributes attr;
      InstTypes.SplicedExpData splicedExpData;
      SourceInfo info;

    // Try to lookup the variables binding and constant evaluate it.
    case (cache, env, c, impl, msg, _)
      equation
        (cache,attr,ty,binding,const_for_range,splicedExpData,classEnv,componentEnv,name) = Lookup.lookupVar(cache, env, c);
         // send the entire shebang to cevalCref2 so we don't have to do lookup var again!
        (cache, v) = cevalCref_dispatch(cache, env, c, attr, ty, binding, const_for_range, splicedExpData, classEnv, componentEnv, name, impl,msg,numIter);
      then
        (cache, v);

    // failure in lookup and we have the MSG go-ahead to print the error
    case (cache,env,c,(false),Absyn.MSG(info = info),_)
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, c));
        scope_str = FGraph.printGraphPathStr(env);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inCref;
  input DAE.Attributes inAttr;
  input DAE.Type inType;
  input DAE.Binding inBinding;
  input Option<DAE.Const> constForRange;
  input InstTypes.SplicedExpData inSplicedExpData;
  input FCore.Graph inClassEnv;
  input FCore.Graph inComponentEnv;
  input String  inFQName;
  input Boolean inImpl;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) := match (inCache, inEnv, inCref, inAttr, inType, inBinding, constForRange, inSplicedExpData, inClassEnv, inComponentEnv, inFQName, inImpl, inMsg, numIter)
    local
      FCore.Cache cache;
      Values.Value v;
      String str, scope_str, s1, s2, s3;
      SourceInfo info;
      SCode.Variability variability;

    // A variable with no binding and SOME for range constness -> a for iterator
    case (_, _, _, _, _, DAE.UNBOUND(), SOME(_), _, _, _, _, _, _, _) then fail();

    // A variable without a binding -> error in a simulation model
    // and we can only check that at the DAE level!
    case (_, _, _, _, _, DAE.UNBOUND(), NONE(), _, _, _, _, false, Absyn.MSG(), _)
      equation
        str = ComponentReference.printComponentRefStr(inCref);
        scope_str = FGraph.printGraphPathStr(inEnv);
        // Error.addSourceMessage(Error.NO_CONSTANT_BINDING, {str, scope_str}, info);
        if Flags.isSet(Flags.CEVAL) then
          Debug.traceln("- Ceval.cevalCref on: " + str + " failed with no constant binding in scope: " + scope_str);
        end if;
        // build a default binding for it!
        s1 = FGraph.printGraphPathStr(inEnv);
        s2 = ComponentReference.printComponentRefStr(inCref);
        s3 = Types.printTypeStr(inType);
        v = Types.typeToValue(inType);
        v = Values.EMPTY(s1, s2, v, s3);
        // i would really like to have SourceInfo to put in Values.EMPTY here!
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
        true = SCode.isParameterOrConst(variability) or inImpl or FGraph.inForLoopScope(inEnv);
        false = crefEqualValue(inCref, inBinding);
        (cache, v) = cevalCrefBinding(inCache, inEnv, inCref, inBinding, inImpl, inMsg, numIter);
        // print("Eval cref: " + ComponentReference.printComponentRefStr(inCref) + "\n  in scope " + FGraph.printGraphPathStr(inEnv) + "\n");
        cache = FCore.addEvaluatedCref(cache,variability,ComponentReference.crefStripLastSubs(inCref));
      then
        (cache, v);
  end match;
end cevalCref_dispatch;

public function cevalCrefBinding "Helper function to cevalCref.
  Evaluates variables by evaluating their bindings."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.Binding inBinding;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := matchcontinue (inCache,inEnv,inComponentRef,inBinding,inBoolean,inMsg,numIter)
    local
      DAE.ComponentRef cr,e1;
      list<DAE.Subscript> subsc;
      Values.Value res,v,e_val;
      FCore.Graph env;
      Boolean impl;
      Absyn.Msg msg;
      String rfn,iter,expstr,s1,s2,str;
      DAE.Exp elexp,iterexp,exp;
      FCore.Cache cache;
      list<DAE.Var> vl;
      Absyn.Path tpath;
      DAE.Type ty;
      Absyn.Ident id;
      SourceInfo info;
      DAE.Binding binding;

    /*
    case (cache,env,cr,_,impl,msg)
      equation
        print("Ceval: " +
          ComponentReference.printComponentRefStr(cr) + " | " +
          FGraph.printGraphPathStr(env) + " | " +
          DAEUtil.printBindingExpStr(inBinding) +
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
    case (cache,env,DAE.CREF_IDENT(_, ty, {}),DAE.UNBOUND(),_,Absyn.MSG(info),_)
      equation
        (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = tpath),
           varLst = vl)) = Types.arrayElementType(ty);
        true = Types.allHaveBindings(vl);
        binding = InstBinding.makeRecordBinding(cache, env, tpath, ty, vl, {}, info);
        (cache, res) = cevalCrefBinding(cache, env, inComponentRef, binding, inBoolean, inMsg, numIter+1);
      then
        (cache, res);

    case (_,_,_,DAE.UNBOUND(),(false),Absyn.MSG(_),_) then fail();

    case (_,_,_,DAE.UNBOUND(),(true),Absyn.MSG(_),_)
      equation
        true = Flags.isSet(Flags.CEVAL);
        Debug.trace("#- Ceval.cevalCrefBinding: Ignoring unbound when implicit\n");
      then
        fail();

    // REDUCTION bindings
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg,_)
      equation
        DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = Absyn.IDENT()), iterators = {DAE.REDUCTIONITER()}) = exp;
        (cache,v) = ceval(cache, env, exp, impl,msg,numIter+1);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl,msg,numIter+1);
      then
        (cache,res);

    // arbitrary expressions, value exists.
    case (cache,env,cr,DAE.EQBOUND(evaluatedExp = SOME(e_val)),impl,msg,_)
      equation
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache,env, subsc, e_val, impl,msg,numIter+1);
      then
        (cache,res);

    // arbitrary expressions. When binding has optional value.
    case (cache,env,cr,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),impl,msg,_)
      equation
        (cache,v) = ceval(cache, env, exp, impl, msg, numIter+1);
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

        (cache,v) = ceval(cache, env, exp, impl, msg, numIter+1);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,res) = cevalSubscriptValue(cache, env, subsc, v, impl,msg,numIter+1);
      then
        (cache,res);

    // if the binding has constant-ness DAE.C_VAR we cannot constant evaluate.
    case (_,_,_,DAE.EQBOUND(exp = exp,constant_ = DAE.C_VAR()),_,Absyn.MSG(_),_)
      equation
        true = Flags.isSet(Flags.CEVAL);
        Debug.trace("#- Ceval.cevalCrefBinding failed (nonconstant EQBOUND(");
        expstr = ExpressionDump.printExpStr(exp);
        Debug.trace(expstr);
        Debug.traceln("))");
      then
        fail();

    case (_,env,e1,_,_,_,_)
      equation
        true = Flags.isSet(Flags.CEVAL);
        s1 = ComponentReference.printComponentRefStr(e1);
        s2 = Types.printBindingStr(inBinding);
        str = FGraph.printGraphPathStr(env);
        str = stringAppendList({"- Ceval.cevalCrefBinding: ",
                s1, " = [", s2, "] in env:", str, " failed"});
        Debug.traceln(str);
        //print("ENV: " + FGraph.printGraphStr(inEnv) + "\n");
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
      res = List.map1BoolOr(Expression.extractCrefsFromExp(exp),ComponentReference.crefEqual,cr);
    then res;
    else false;
  end matchcontinue;
end isRecursiveBinding;


public function cevalSubscriptValue "Helper function to cevalCrefBinding. It applies
  subscripts to array values to extract array elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
  input Values.Value inValue;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache,outValue) := match (inCache,inEnv,inExpSubscriptLst,inValue,inBoolean,inMsg,numIter)
    local
      Integer n;
      Values.Value subval,res,v;
      FCore.Graph env;
      DAE.Exp exp;
      list<DAE.Subscript> subs;
      list<Values.Value> lst,sliceLst,subvals;
      list<Integer> slice;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;

    // we have a subscript which is an index or an enumeration literal scalar, try to constant evaluate it
    case (cache,env,(DAE.INDEX(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg,_)
      equation
        (cache,v) = ceval(cache, env, exp, impl, msg,numIter+1);
        n = match (v)
             case Values.INTEGER(n) then n;
             case Values.ENUM_LITERAL(index = n) then n;
            end match;
        subval = listGet(lst, n);
        (cache,res) = cevalSubscriptValue(cache, env, subs, subval, impl,msg,numIter+1);
      then
        (cache,res);

    // slices
    case (cache,env,(DAE.SLICE(exp = exp) :: subs),Values.ARRAY(valueLst = lst),impl,msg,_)
      equation
        (cache,Values.ARRAY(valueLst = sliceLst)) = ceval(cache, env, exp, impl,msg,numIter+1);
        slice = List.map(sliceLst, ValuesUtil.valueInteger);
        subvals = List.map1r(slice, listGet, lst);
        (cache,lst) = cevalSubscriptValueList(cache,env, subs, subvals, impl,msg,numIter);
        res = ValuesUtil.makeArray(lst);
      then
        (cache,res);

    // we have a wholedim, apply the rest of the subscripts to each element of the array.
    case (cache, env, (DAE.WHOLEDIM() :: subs), subval as Values.ARRAY(), impl, msg,_)
      algorithm
        if listEmpty(subs) then
          // If the wholedim is the last subscript we can just return the value as it is.
          res := subval;
        else
          (cache,lst) := cevalSubscriptValueList(cache, env, subs, subval.valueLst, impl, msg, numIter+1);
          res := ValuesUtil.makeArray(lst);
        end if;
      then
        (cache, res);

    // we have no subscripts but we have a value, return it
    case (cache,_,{},v,_,_,_) then (cache,v);

    /*// failtrace
    case (cache, env, subs, inValue, dims, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Ceval.cevalSubscriptValue failed on:" +
          "\n env: " + FGraph.printGraphPathStr(env) +
          "\n subs: " + stringDelimitList(List.map(subs, ExpressionDump.printSubscriptStr), ", ") +
          "\n value: " + ValuesUtil.printValStr(inValue) +
          "\n dim sizes: " + stringDelimitList(List.map(dims, intString), ", ")
        );
      then
        fail();*/
  end match;
end cevalSubscriptValue;

protected function cevalSubscriptValueList "Applies subscripts to array values to extract array elements."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Subscript> inExpSubscriptLst "subscripts to extract";
  input list<Values.Value> inValue;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output list<Values.Value> outValue;
algorithm
  (outCache,outValue) :=
  match (inCache,inEnv,inExpSubscriptLst,inValue,inBoolean,inMsg,numIter)
    local
      Values.Value subval,res;
      FCore.Graph env;
      list<Values.Value> lst,subvals;
      Boolean impl;
      Absyn.Msg msg;
      list<DAE.Subscript> subs;
      FCore.Cache cache;
    case (cache,_,_,{},_,_,_) then (cache,{});
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
  {1,2,3} (resulting in x[1,2,3]).
  adrpo: do not fail if you cannot evaluate one, just move to the next one!"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<Integer> inIntegerLst;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  (outCache,outExpSubscriptLst) :=
  matchcontinue (inCache,inEnv,inExpSubscriptLst,inIntegerLst,inBoolean,inMsg,numIter)
    local
      DAE.Subscript sub_1,sub;
      list<DAE.Subscript> subs_1,subs;
      FCore.Graph env;
      Integer dim;
      list<Integer> dims;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;

    // empty case
    case (cache,_,{},_,_,_,_) then (cache,{});

    // we have subscripts and we can evaluate the first
    case (cache,env,(sub :: subs),(dim :: dims),impl,msg,_)
      equation
        (cache,sub_1) = cevalSubscript(cache, env, sub, dim, impl,msg,numIter+1);
        (cache,subs_1) = cevalSubscripts(cache, env, subs, dims, impl,msg,numIter);
      then
        (cache,sub_1 :: subs_1);

    // we have subscripts and we CANNOT evaluate the first, move to next
    case (cache,env,(sub :: subs),(dim :: dims),impl,msg,_)
      equation
        failure((_,_) = cevalSubscript(cache, env, sub, dim, impl,msg,numIter+1));
        (cache,subs_1) = cevalSubscripts(cache, env, subs, dims, impl,msg,numIter);
      then
        (cache,sub :: subs_1);
  end matchcontinue;
end cevalSubscripts;

public function cevalSubscript "This function relates a subscript to its canonical forms, which
  is when all expressions are evaluated to constant values."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Subscript inSubscript;
  input Integer inInteger;
  input Boolean inBoolean "impl";
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output DAE.Subscript outSubscript;
algorithm
  (outCache,outSubscript) :=
  matchcontinue (inCache,inEnv,inSubscript,inInteger,inBoolean,inMsg,numIter)
    local
      FCore.Graph env;
      Values.Value v1;
      DAE.Exp e1_1,e1;
      Integer dim;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      Integer indx;

    // the entire dimension, nothing to do
    case (cache,_,DAE.WHOLEDIM(),_,_,_,_) then (cache,DAE.WHOLEDIM());

    // An enumeration literal is already constant
    case (cache, _, DAE.INDEX(exp = DAE.ENUM_LITERAL()), _, _, _, _)
      then (cache, inSubscript);

    // an expression index that can be constant evaluated, indexing using enum or bool
    case (cache,env,DAE.INDEX(exp = e1),_,impl,msg,_)
      equation
        (cache,v1) = ceval(cache, env, e1, impl, msg, numIter+1);
        e1_1 = match (v1)
                 case Values.INTEGER(_) then ValuesUtil.valueExp(v1);
                 case Values.ENUM_LITERAL() then ValuesUtil.valueExp(v1);
                 case Values.BOOL(_) then ValuesUtil.valueExp(v1);
               end match;
      then
        (cache,DAE.INDEX(e1_1));

    // an expression slice that can be constant evaluated
    case (cache,env,DAE.SLICE(exp = e1),_,impl,msg,_)
      equation
        (cache,v1) = ceval(cache,env, e1, impl,msg,numIter+1);
        e1_1 = ValuesUtil.valueExp(v1);
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

    else false;

  end matchcontinue;
end dimensionSliceInRange;

protected function cevalReduction
  "Help function to ceval. Evaluates reductions calls, such as
    'sum(i for i in 1:5)'"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path opPath;
  input Option<Values.Value> inCurValue;
  input DAE.Exp exp;
  input DAE.Type exprType;
  input String foldName;
  input String resultName;
  input Option<DAE.Exp> foldExp;
  input list<String> iteratorNames;
  input list<list<Values.Value>> inValueMatrix;
  input list<DAE.Type> iterTypes;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
  output FCore.Cache newCache;
  output Option<Values.Value> result;
algorithm
  (newCache, result) := match (inCache, inEnv, opPath, inCurValue, exp, exprType, foldName, resultName, foldExp, iteratorNames, inValueMatrix, iterTypes, impl, msg, numIter)
    local
      list<Values.Value> vals;
      FCore.Graph new_env,env;
      FCore.Cache cache;
      list<Integer> dims;
      list<list<Values.Value>> valueMatrix;
      Option<Values.Value> curValue;

    case (cache, _, Absyn.IDENT("list"), SOME(Values.LIST(vals)), _, _, _, _, _, _, {}, _, _, _, _)
      equation
        vals = listReverse(vals);
      then (cache, SOME(Values.LIST(vals)));
    case (cache, _, Absyn.IDENT("listReverse"), SOME(Values.LIST(_)), _, _, _, _, _, _, {}, _, _, _, _)
      then (cache, inCurValue);
    case (cache, _, Absyn.IDENT("array"), SOME(Values.ARRAY(vals,dims)), _, _, _, _, _, _, {}, _, _, _, _)
      equation
        vals = listReverse(vals);
      then (cache, SOME(Values.ARRAY(vals,dims)));

    case (cache, _, _, curValue, _, _, _, _, _, _, {}, _, _, _, _)
      then (cache, curValue);

    case (cache, env, _, curValue, _, _, _, _, _, _, vals :: valueMatrix, _, _, _, _)
      equation
        // Bind the iterator
        // print("iterators: " + stringDelimitList(list(ValuesUtil.valString(v) for v in vals), ",") + "\n");
        new_env = extendFrameForIterators(env, iteratorNames, vals, iterTypes);
        // Calculate var1 of the folding function
        (cache, curValue) = cevalReductionEvalAndFold(cache, new_env, opPath, curValue, exp, exprType, foldName, resultName, foldExp, impl, msg,numIter+1);
        // Fold the rest of the reduction
        (cache, curValue) = cevalReduction(cache, env, opPath, curValue, exp, exprType, foldName, resultName, foldExp, iteratorNames, valueMatrix, iterTypes, impl, msg,numIter);
      then (cache, curValue);
  end match;
end cevalReduction;

protected function cevalReductionEvalAndFold "Evaluate the reduction body and fold"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path opPath;
  input Option<Values.Value> inCurValue;
  input DAE.Exp exp;
  input DAE.Type exprType;
  input String foldName;
  input String resultName;
  input Option<DAE.Exp> foldExp;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
  output FCore.Cache newCache;
  output Option<Values.Value> result;
algorithm
  (newCache,result) := match (inCache,inEnv,opPath,inCurValue,exp,exprType,foldName,resultName,foldExp,impl,msg,numIter)
    local
      Values.Value value;
      Option<Values.Value> curValue;
      FCore.Cache cache;
      FCore.Graph env;

    case (cache,env,_,curValue,_,_,_,_,_,_,_,_)
      equation
        (cache, value) = ceval(cache, env, exp, impl, msg,numIter+1);
        // print("cevalReductionEval: " + ExpressionDump.printExpStr(exp) + " => " + ValuesUtil.valString(value) + "\n");
        (cache, result) = cevalReductionFold(cache, env, opPath, curValue, value, foldName, resultName, foldExp, exprType, impl, msg,numIter);
        // print("cevalReductionEval => " + Util.applyOptionOrDefault(result, ValuesUtil.valString, "") + "\n");
      then (cache, result);
  end match;
end cevalReductionEvalAndFold;

protected function cevalReductionFold "Fold the reduction body"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path opPath;
  input Option<Values.Value> inCurValue;
  input Values.Value inValue;
  input String foldName;
  input String resultName;
  input Option<DAE.Exp> foldExp;
  input DAE.Type exprType;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
  output FCore.Cache newCache;
  output Option<Values.Value> result;
algorithm
  (newCache,result) := match (inCache,opPath,inCurValue,foldExp)
    local
      DAE.Exp exp;
      Values.Value value;
      FCore.Cache cache;
      FCore.Graph env;

    case (cache,Absyn.IDENT("array"),SOME(value),_)
      equation
        value = valueArrayCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value));
    case (cache,Absyn.IDENT("list"),SOME(value),_)
      equation
        value = valueCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value));
    case (cache,Absyn.IDENT("listReverse"),SOME(value),_)
      equation
        value = valueCons(ValuesUtil.unboxIfBoxedVal(inValue),value);
      then (cache,SOME(value));
    case (cache,_,NONE(),_)
      then (cache,SOME(inValue));

    case (cache,_,SOME(value),SOME(exp))
      equation
        // print("cevalReductionFold " + ExpressionDump.printExpStr(exp) + ", " + ValuesUtil.valString(inValue) + ", " + ValuesUtil.valString(value) + "\n");
        /* TODO: Store the actual types somewhere... */
        env = FGraph.addForIterator(inEnv, foldName, exprType, DAE.VALBOUND(inValue, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        env = FGraph.addForIterator(env, resultName, exprType, DAE.VALBOUND(value, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        (cache, value) = ceval(cache, env, exp, impl, msg,numIter+1);
      then (cache, SOME(value));
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

    else Values.ARRAY({v1, v2}, {2});
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

protected function cevalReductionIterators
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.ReductionIterator> inIterators;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
  output FCore.Cache outCache;
  output list<list<Values.Value>> vals;
  output list<String> names;
  output list<Integer> dims;
  output list<DAE.Type> tys;
algorithm
  (outCache,vals,names,dims,tys) := match (inCache,inEnv,inIterators,impl,msg,numIter)
    local
      Values.Value val;
      list<Values.Value> iterVals;
      Integer dim;
      DAE.Type ty;
      String id;
      DAE.Exp exp;
      Option<DAE.Exp> guardExp;
      FCore.Cache cache;
      FCore.Graph env;
      list<DAE.ReductionIterator> iterators;

    case (cache,_,{},_,_,_) then (cache,{},{},{},{});
    case (cache,env,DAE.REDUCTIONITER(id,exp,guardExp,ty)::iterators,_,_,_)
      equation
        (cache,val) = ceval(cache,env,exp,impl,msg,numIter+1);
        iterVals = ValuesUtil.arrayOrListVals(val,true);
        (cache,iterVals) = filterReductionIterator(cache,env,id,ty,iterVals,guardExp,impl,msg,numIter);
        dim = listLength(iterVals);
        (cache,vals,names,dims,tys) = cevalReductionIterators(cache,env,iterators,impl,msg,numIter);
      then (cache,iterVals::vals,id::names,dim::dims,ty::tys);
  end match;
end cevalReductionIterators;

protected function filterReductionIterator
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String id;
  input DAE.Type ty;
  input list<Values.Value> inVals;
  input Option<DAE.Exp> guardExp;
  input Boolean impl;
  input Absyn.Msg msg;
  input Integer numIter;
  output FCore.Cache outCache;
  output list<Values.Value> outVals;
algorithm
  (outCache,outVals) := match (inCache,inEnv,id,ty,inVals,guardExp,impl,msg,numIter)
    local
      DAE.Exp exp;
      Values.Value val;
      Boolean b;
      FCore.Graph new_env,env;
      FCore.Cache cache;
      list<Values.Value> vals;

   case (cache,_,_,_,{},_,_,_,_) then (cache,{});
    case (cache,env,_,_,val::vals,SOME(exp),_,_,_)
      equation
        new_env = FGraph.addForIterator(env, id, ty, DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        (cache,Values.BOOL(b)) = ceval(cache,new_env,exp,impl,msg,numIter+1);
        (cache,vals) = filterReductionIterator(cache,env,id,ty,vals,guardExp,impl,msg,numIter);
        vals = if b then val::vals else vals;
      then (cache,vals);
    case (cache,_,_,_,vals,NONE(),_,_,_) then (cache,vals);
  end match;
end filterReductionIterator;

protected function extendFrameForIterators
  input FCore.Graph inEnv;
  input list<String> inNames;
  input list<Values.Value> inVals;
  input list<DAE.Type> inTys;
  output FCore.Graph outEnv;
algorithm
  outEnv := match (inEnv,inNames,inVals,inTys)
    local
      String name;
      Values.Value val;
      DAE.Type ty;
      FCore.Graph env;
      list<String> names;
      list<Values.Value> vals;
      list<DAE.Type> tys;

    case (env,{},{},{}) then env;
    case (env,name::names,val::vals,ty::tys)
      equation
        env = FGraph.addForIterator(env, name, ty, DAE.VALBOUND(val, DAE.BINDING_FROM_DEFAULT_VALUE()), SCode.VAR(), SOME(DAE.C_CONST()));
        env = extendFrameForIterators(env,names,vals,tys);
      then env;
  end match;
end extendFrameForIterators;

protected function backpatchArrayReduction
  input Absyn.Path path;
  input Absyn.ReductionIterType iterType;
  input Values.Value inValue;
  input list<Integer> dims;
  output Values.Value outValue;
algorithm
  outValue := match (path,iterType,inValue,dims)
    local
      list<Values.Value> vals;
      Values.Value value;
    case (_,_,value,{_}) then value;
    case (Absyn.IDENT("array"),Absyn.COMBINE(),Values.ARRAY(valueLst=vals),_)
      equation
        value = backpatchArrayReduction3(vals,listReverse(dims),ValuesUtil.makeArray);
        // print(ValuesUtil.valString(value));print("\n");
      then value;
    case (Absyn.IDENT("list"),Absyn.COMBINE(),Values.LIST(vals),_)
      equation
        value = backpatchArrayReduction3(vals,listReverse(dims),ValuesUtil.makeList);
        // print(ValuesUtil.valString(value));print("\n");
      then value;
    case (Absyn.IDENT("listReverse"),Absyn.COMBINE(),Values.LIST(vals),_)
      equation
        value = backpatchArrayReduction3(vals,listReverse(dims),ValuesUtil.makeList);
        // print(ValuesUtil.valString(value));print("\n");
      then value;
    else inValue;
  end match;
end backpatchArrayReduction;

protected function backpatchArrayReduction3
  input list<Values.Value> inVals;
  input list<Integer> inDims;
  input Func makeSequence;
  output Values.Value outValue;
  partial function Func
    input list<Values.Value> inVals;
    output Values.Value outVal;
  end Func;
algorithm
  outValue := match (inVals,inDims,makeSequence)
    local
      Integer dim;
      list<list<Values.Value>> valMatrix;
      Values.Value value;
      list<Values.Value> vals;
      list<Integer> dims;

    case (vals,{_},_)
      equation
        value = makeSequence(vals);
      then value;
    case (vals,dim::dims,_)
      equation
        // Split into the smallest of the arrays
        // print("into sublists of length: " + intString(dim) + " from length=" + intString(listLength(vals)) + "\n");
        valMatrix = List.partition(vals,dim);
        // print("output has length=" + intString(listLength(valMatrix)) + "\n");
        vals = List.map(valMatrix,makeSequence);
        value = backpatchArrayReduction3(vals,dims,makeSequence);
      then value;
  end match;
end backpatchArrayReduction3;

public function cevalSimple
  "A simple expression does not need cache, etc"
  input DAE.Exp exp;
  output Values.Value val;
algorithm
  (_,val) := ceval(FCore.emptyCache(),FGraph.empty(),exp,false,Absyn.MSG(Absyn.dummyInfo),0);
end cevalSimple;

public function cevalSimpleWithFunctionTreeReturnExp
  "A simple expression does not need cache, etc"
  input DAE.Exp exp;
  input DAE.FunctionTree functions;
  output DAE.Exp oexp;
protected
  Values.Value val;
  FCore.Cache cache;
  FCore.StructuralParameters structuralParameters;
  Mutable<DAE.FunctionTree> functionTree;
algorithm
  structuralParameters := (AvlSetCR.EMPTY(),{});
  functionTree := Mutable.create(functions);
  cache := FCore.CACHE(NONE(), functionTree, structuralParameters, Absyn.IDENT(""));
  (_,val) := ceval(cache, FGraph.empty(), exp, false, Absyn.NO_MSG(),0);
  oexp := ValuesUtil.valueExp(val);
end cevalSimpleWithFunctionTreeReturnExp;

public function cevalAstExp
"Part of meta-programming using CODE.
  This function evaluates a piece of Expression AST, replacing Eval(variable)
  with the value of the variable, given that it is of type \"Expression\".

  Example: y = Code(1 + x)
           2 + 5  ( x + Eval(y) )  =>   2 + 5  ( x + 1 + x )"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Absyn.Exp outExp;
algorithm
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inMsg,info)
    local
      Absyn.Exp e,e1_1,e2_1,e1,e2,e_1,cond_1,then_1,else_1,cond,then_,else_,exp,e3_1,e3;
      FCore.Graph env;
      Absyn.Operator op;
      Boolean impl;
      Absyn.Msg msg;
      list<tuple<Absyn.Exp, Absyn.Exp>> nest_1,nest;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fa;
      list<Absyn.Exp> expl_1,expl;
      FCore.Cache cache;
      DAE.Exp daeExp;
      list<list<Absyn.Exp>> lstExpl_1,lstExpl;

    case (cache,_,(e as Absyn.INTEGER()),_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.REAL()),_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.CREF()),_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.STRING()),_,_,_) then (cache,e);
    case (cache,_,(e as Absyn.BOOL()),_,_,_) then (cache,e);

    case (cache,env,Absyn.BINARY(exp1 = e1,op = op,exp2 = e2),impl,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, msg, info);
      then
        (cache,Absyn.BINARY(e1_1,op,e2_1));

    case (cache,env,Absyn.UNARY(op = op,exp = e),impl,msg,_)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, msg, info);
      then
        (cache,Absyn.UNARY(op,e_1));

    case (cache,env,Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2),impl,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, msg, info);
      then
        (cache,Absyn.LBINARY(e1_1,op,e2_1));

    case (cache,env,Absyn.LUNARY(op = op,exp = e),impl,msg,_)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, msg, info);
      then
        (cache,Absyn.LUNARY(op,e_1));

    case (cache,env,Absyn.RELATION(exp1 = e1,op = op,exp2 = e2),impl,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, msg, info);
      then
        (cache,Absyn.RELATION(e1_1,op,e2_1));

    case (cache,env,Absyn.IFEXP(ifExp = cond,trueBranch = then_,elseBranch = else_,elseIfBranch = nest),impl,msg,_)
      equation
        (cache,cond_1) = cevalAstExp(cache,env, cond, impl, msg, info);
        (cache,then_1) = cevalAstExp(cache,env, then_, impl, msg, info);
        (cache,else_1) = cevalAstExp(cache,env, else_, impl, msg, info);
        (cache,nest_1) = cevalAstExpexpList(cache,env, nest, impl, msg, info);
      then
        (cache,Absyn.IFEXP(cond_1,then_1,else_1,nest_1));

    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "Eval",subscripts = {}),functionArgs = Absyn.FUNCTIONARGS(args = {e},argNames = {})),impl,msg,_)
      equation
        (cache,daeExp,_) = Static.elabExp(cache, env, e, impl, true, Prefix.NOPRE(), info);
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp))) = ceval(cache, env, daeExp, impl,msg,0);
      then
        (cache,exp);

    case (cache,_,(e as Absyn.CALL()),_,_,_) then (cache,e);

    case (cache,env,Absyn.ARRAY(arrayExp = expl),impl,msg,_)
      equation
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, msg, info);
      then
        (cache,Absyn.ARRAY(expl_1));

    case (cache,env,Absyn.MATRIX(matrix = lstExpl),impl,msg,_)
      equation
        (cache,lstExpl_1) = cevalAstExpListList(cache, env, lstExpl, impl, msg, info);
      then
        (cache,Absyn.MATRIX(lstExpl_1));

    case (cache,env,Absyn.RANGE(start = e1,step = SOME(e2),stop = e3),impl,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, msg, info);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, msg, info);
      then
        (cache,Absyn.RANGE(e1_1,SOME(e2_1),e3_1));

    case (cache,env,Absyn.RANGE(start = e1,step = NONE(),stop = e3),impl,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, msg, info);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, msg, info);
      then
        (cache,Absyn.RANGE(e1_1,NONE(),e3_1));

    case (cache,env,Absyn.TUPLE(expressions = expl),impl,msg,_)
      equation
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, msg, info);
      then
        (cache,Absyn.TUPLE(expl_1));

    case (cache,_,Absyn.END(),_,_,_) then (cache,Absyn.END());

    case (cache,_,(e as Absyn.CODE()),_,_,_) then (cache,e);

  end matchcontinue;
end cevalAstExp;

public function cevalAstExpList
"List version of cevalAstExp"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm
  (outCache,outAbsynExpLst) :=
  match (inCache,inEnv,inAbsynExpLst,inBoolean,inMsg,info)
    local
      FCore.Graph env;
      Absyn.Msg msg;
      Absyn.Exp e_1,e;
      list<Absyn.Exp> res,es;
      Boolean impl;
      FCore.Cache cache;

    case (cache,_,{},_,_,_) then (cache,{});

    case (cache,env,(e :: es),impl,msg,_)
      equation
        (cache,_) = cevalAstExp(cache,env, e, impl, msg, info);
        (cache,res) = cevalAstExpList(cache,env, es, impl, msg, info);
      then
        (cache,e :: res);
  end match;
end cevalAstExpList;

protected function cevalAstExpListList "function: cevalAstExpListList"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm
  (outCache,outAbsynExpLstLst) :=
  match (inCache,inEnv,inAbsynExpLstLst,inBoolean,inMsg,info)
    local
      FCore.Graph env;
      Absyn.Msg msg;
      list<Absyn.Exp> e_1,e;
      list<list<Absyn.Exp>> res,es;
      Boolean impl;
      FCore.Cache cache;

    case (cache,_,{},_,_,_) then (cache,{});

    case (cache,env,(e :: es),impl,msg,_)
      equation
        (cache,_) = cevalAstExpList(cache,env, e, impl, msg, info);
        (cache,res) = cevalAstExpListList(cache,env, es, impl, msg, info);
      then
        (cache,e :: res);
  end match;
end cevalAstExpListList;

public function cevalAstElt
"Evaluates an ast constructor for Element nodes, e.g.
  Code(parameter Real x=1;)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  output FCore.Cache outCache;
  output Absyn.Element outElement;
algorithm
  (outCache,outElement) :=
  match (inCache,inEnv,inElement,inBoolean,inMsg)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      FCore.Graph env;
      Boolean f,isReadOnly,impl;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String file;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      SourceInfo info;
      Integer sline,scolumn,eline,ecolumn;
      Option<Absyn.ConstrainClass> c;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = citems),info = (info as SOURCEINFO()),constrainClass = c),impl,msg)
      equation
        (cache,citems_1) = cevalAstCitems(cache,env, citems, impl, msg, info);
      then
        (cache,Absyn.ELEMENT(f,r,io,Absyn.COMPONENTS(attr,tp,citems_1),info,c));
  end match;
end cevalAstElt;

protected function cevalAstCitems
"Helper function to cevalAstElt."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm
  (outCache,outAbsynComponentItemLst) :=
  matchcontinue (inCache,inEnv,inAbsynComponentItemLst,inBoolean,inMsg,info)
    local
      Absyn.Msg msg;
      list<Absyn.ComponentItem> res,xs;
      Option<Absyn.Modification> modopt_1,modopt;
      list<Absyn.Subscript> ad_1,ad;
      FCore.Graph env;
      String id;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      Boolean impl;
      Absyn.ComponentItem x;
      FCore.Cache cache;
    case (cache,_,{},_,_,_) then (cache,{});
    case (cache,env,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = modopt),condition = cond,comment = cmt) :: xs),impl,msg,_) /* If one component fails, the rest should still succeed */
      equation
        (cache,res) = cevalAstCitems(cache,env, xs, impl, msg, info);
        (cache,modopt_1) = cevalAstModopt(cache,env, modopt, impl, msg, info);
        (cache,ad_1) = cevalAstArraydim(cache,env, ad, impl, msg, info);
      then
        (cache,Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad_1,modopt_1),cond,cmt) :: res);
    case (cache,env,(x :: xs),impl,msg,_) /* If one component fails, the rest should still succeed */
      equation
        (cache,res) = cevalAstCitems(cache,env, xs, impl, msg, info);
      then
        (cache,x :: res);
  end matchcontinue;
end cevalAstCitems;

protected function cevalAstModopt
"function: cevalAstModopt"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm
  (outCache,outAbsynModificationOption) :=
  match (inCache,inEnv,inAbsynModificationOption,inBoolean,inMsg,info)
    local
      Absyn.Modification res,mod;
      FCore.Graph env;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
    case (cache,env,SOME(mod),impl,msg,_)
      equation
        (cache,res) = cevalAstModification(cache,env, mod, impl, msg, info);
      then
        (cache,SOME(res));
    case (cache,_,NONE(),_,_,_) then (cache,NONE());
  end match;
end cevalAstModopt;

protected function cevalAstModification "This function evaluates Eval(variable) inside an AST Modification  and replaces
  the Eval operator with the value of the variable if it has a type \"Expression\""
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Modification inModification;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Absyn.Modification outModification;
algorithm
  (outCache,outModification) :=
  match (inCache,inEnv,inModification,inBoolean,inMsg,info)
    local
      Absyn.Exp e_1,e;
      list<Absyn.ElementArg> eltargs_1,eltargs;
      FCore.Graph env;
      Boolean impl;
      Absyn.Msg msg;
      FCore.Cache cache;
      SourceInfo info2;
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,eqMod = Absyn.EQMOD(e,info2)),impl,msg,_)
      equation
        (cache,e_1) = cevalAstExp(cache,env, e, impl, msg, info);
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, msg, info);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,Absyn.EQMOD(e_1,info2)));
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,eqMod = Absyn.NOMOD()),impl,msg,_)
      equation
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, msg, info);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,Absyn.NOMOD()));
  end match;
end cevalAstModification;

protected function cevalAstEltargs "Helper function to cevalAstModification."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm
  (outCache,outAbsynElementArgLst):=
  matchcontinue (inCache,inEnv,inAbsynElementArgLst,inBoolean,inMsg,info)
    local
      FCore.Graph env;
      Absyn.Msg msg;
      Absyn.Modification mod_1,mod;
      list<Absyn.ElementArg> res,args;
      Boolean b,impl;
      Absyn.Each e;
      Option<String> stropt;
      Absyn.ElementArg m;
      FCore.Cache cache;
      SourceInfo mod_info;
      Absyn.Path p;

    case (cache,_,{},_,_,_) then (cache,{});
    /* TODO: look through redeclarations for Eval(var) as well */
    case (cache,env,(Absyn.MODIFICATION(finalPrefix = b,eachPrefix = e,path = p,modification = SOME(mod),comment = stropt, info = mod_info) :: args),impl,msg,_)
      equation
        (cache,mod_1) = cevalAstModification(cache,env, mod, impl, msg, info);
        (cache,res) = cevalAstEltargs(cache,env, args, impl, msg, info);
      then
        (cache,Absyn.MODIFICATION(b,e,p,SOME(mod_1),stropt,mod_info) :: res);
    case (cache,env,(m :: args),impl,msg,_) /* TODO: look through redeclarations for Eval(var) as well */
      equation
        (cache,res) = cevalAstEltargs(cache,env, args, impl, msg, info);
      then
        (cache,m :: res);
  end matchcontinue;
end cevalAstEltargs;

protected function cevalAstArraydim "Helper function to cevaAstCitems"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output Absyn.ArrayDim outArrayDim;
algorithm
  (outCache,outArrayDim) :=
  match (inCache,inEnv,inArrayDim,inBoolean,inMsg,info)
    local
      FCore.Graph env;
      Absyn.Msg msg;
      list<Absyn.Subscript> res,xs;
      Boolean impl;
      Absyn.Exp e_1,e;
      FCore.Cache cache;
    case (cache,_,{},_,_,_) then (cache,{});
    case (cache,env,(Absyn.NOSUB() :: xs),impl,msg,_)
      equation
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, msg, info);
      then
        (cache,Absyn.NOSUB() :: res);
    case (cache,env,(Absyn.SUBSCRIPT(subscript = e) :: xs),impl,msg,_)
      equation
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, msg, info);
        (cache,_) = cevalAstExp(cache,env, e, impl, msg, info);
      then
        (cache,Absyn.SUBSCRIPT(e) :: res);
  end match;
end cevalAstArraydim;

protected function cevalAstExpexpList
"For IFEXP"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<tuple<Absyn.Exp, Absyn.Exp>> inExpTpls;
  input Boolean inBoolean;
  input Absyn.Msg inMsg;
  input SourceInfo info;
  output FCore.Cache outCache;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outExpTpls;
algorithm
  (outCache, outExpTpls) :=
  match (inCache, inEnv, inExpTpls, inBoolean, inMsg, info)
    local
      Absyn.Msg msg;
      Absyn.Exp e1_1,e2_1,e1,e2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res,xs;
      FCore.Graph env;
      Boolean impl;
      FCore.Cache cache;
    case (cache,_,{},_,_,_) then (cache,{});
    case (cache,env,((e1,e2) :: xs),impl,msg,_)
      equation
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, msg, info);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, msg, info);
        (cache,res) = cevalAstExpexpList(cache,env, xs, impl, msg, info);
      then
        (cache,(e1_1,e2_1) :: res);
  end match;
end cevalAstExpexpList;

public function cevalDimension
  "Constant evaluates a dimension, returning the size of the dimension as a value."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Dimension inDimension;
  input Boolean inImpl;
  input Absyn.Msg inMsg;
  input Integer numIter;
  output FCore.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) :=
  match(inCache, inEnv, inDimension, inImpl, inMsg, numIter)
    local
      Integer dim_int;
      DAE.Exp exp;
      FCore.Cache cache;
      Values.Value res;

    // Integer dimension, already constant.
    case (_, _, DAE.DIM_INTEGER(integer = dim_int), _, _, _)
      then (inCache, Values.INTEGER(dim_int));

    // Enumeration dimension, already constant.
    case (_, _, DAE.DIM_ENUM(size = dim_int), _, _, _)
      then (inCache, Values.INTEGER(dim_int));

    case (_, _, DAE.DIM_BOOLEAN(), _, _, _)
      then (inCache, Values.INTEGER(2));

    // Dimension given by expression, evaluate the expression.
    case (_, _, DAE.DIM_EXP(exp = exp), _, _, _)
      equation
        (cache, res) = ceval(inCache, inEnv, exp, inImpl, inMsg, numIter+1);
      then
        (cache, res);

  end match;
end cevalDimension;

protected function makeReductionAllCombinations
  input list<list<Values.Value>> inValMatrix;
  input Absyn.ReductionIterType rtype;
  output list<list<Values.Value>> valMatrix;
algorithm
  valMatrix := match (inValMatrix,rtype)
    case (_,Absyn.COMBINE()) then listReverse(Util.allCombinations(inValMatrix,SOME(100000),Absyn.dummyInfo));
    case (_,Absyn.THREAD()) then listReverse(List.transposeList(inValMatrix));
  end match;
end makeReductionAllCombinations;

annotation(__OpenModelica_Interface="frontend");
end Ceval;
