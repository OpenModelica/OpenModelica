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

encapsulated package Static
" file:        Static.mo
  package:     Static
  description: Static analysis of expressions

  RCS: $Id$

  This module does static analysis on expressions.
  The analyzed expressions are built using the
  constructors in the Expression module from expressions defined in Absyn.
  Also, a set of properties of the expressions is calculated during analysis.
  Properties of expressions include type information and a boolean indicating if the
  expression is constant or not.
  If the expression is constant, the Ceval module is used to evaluate the expression
  value. A value of an expression is described using the Values module.

  The main function in this module is evalExp which takes an Absyn.Exp and transform it
  into an DAE.Exp, while performing type checking and automatic type conversions, etc.
  To determine types of builtin functions and operators, the module also contain an elaboration
  handler for functions and operators. This function is called elabBuiltinHandler.
  NOTE: These functions should only determine the type and properties of the builtin functions and
  operators and not evaluate them. Constant evaluation is performed by the Ceval module.
  The module also contain a function for deoverloading of operators, in the \'deoverload\' function.
  It transforms operators like + to its specific form, ADD, ADD_ARR, etc.

  Interactive function calls are also given their types by elabExp, which calls
  elabCallInteractive.

  Elaboration for functions involve checking the types of the arguments by filling slots of the
  argument list with first positional and then named arguments to find a matching function. The
  details of this mechanism can be found in the Modelica specification.
  The elaboration also contain function deoverloading which will be added to Modelica in the future."

public import Absyn;
public import DAE;
public import Env;
public import GlobalScript;
public import MetaUtil;
public import SCode;
public import SCodeUtil;
public import Values;
public import Prefix;
public import Util;

protected
uniontype Slot
  record SLOT
    DAE.FuncArg an "An argument to a function" ;
    Boolean slotFilled "True if the slot has been filled, i.e. argument has been given a value" ;
    Option<DAE.Exp> expExpOption;
    DAE.Dimensions typesArrayDimLst;
  end SLOT;
end Slot;

protected import Ceval;
protected import ClassInf;
protected import ComponentReference;
protected import Config;
protected import Debug;
protected import Dump;
protected import Error;
protected import ErrorExt;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import Global;
protected import Inline;
protected import Inst;
protected import InstTypes;
protected import InnerOuter;
protected import Interactive;
protected import List;
protected import Lookup;
protected import Mod;
protected import Patternm;
protected import Print;
protected import System;
protected import Types;
protected import ValuesUtil;
protected import DAEUtil;
protected import PrefixUtil;
protected import VarTransform;
protected import SCodeDump;
protected import StaticScript;

public function elabExpList "Expression elaboration of Absyn.Exp list, i.e. lists of expressions."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  elabExpList2(inCache,inEnv,inAbsynExpLst,DAE.T_UNKNOWN_DEFAULT,inImplicit,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix,info);
end elabExpList;

protected function elabExpList2 "Expression elaboration of Absyn.Exp list, i.e. lists of expressions."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input DAE.Type ty "The type of the last evaluated expression; used to speed up instantiation of enumerations :)";
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,ty,inImplicit,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix,info)
    local
      Boolean impl;
      Option<GlobalScript.SymbolTable> st,st_1,st_2;
      DAE.Exp exp;
      DAE.Properties p;
      list<DAE.Exp> exps;
      list<DAE.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
      Env.Cache cache;
      Boolean doVect;
      Prefix.Prefix pre;
      Absyn.ComponentRef cr;
      Absyn.Path path,path1,path2;
      String name;
      list<String> names;
      Integer ix;

    case (cache,_,{},_,impl,st,doVect,_,_) then (cache,{},{},st);

    // Hack to make enumeration arrays elaborate a _lot_ faster
    case (cache,env,(Absyn.CREF(cr as Absyn.CREF_FULLYQUALIFIED(componentRef=_)) :: rest),DAE.T_ENUMERATION(path=path2,names=names),impl,st,doVect,pre,_)
      equation
        path = Absyn.crefToPath(cr);
        (path1,Absyn.IDENT(name)) = Absyn.splitQualAndIdentPath(path);
        true = Absyn.pathEqual(path1,path2);
        ix = List.position(name,names)+1;
        exp = DAE.ENUM_LITERAL(path,ix);
        p = DAE.PROP(ty,DAE.C_CONST());
        (cache,exps,props,st_2) = elabExpList2(cache, env, rest, ty, impl, st, doVect, pre, info);
      then (cache,exp :: exps,p :: props, st_2);

    case (cache,env,(e :: rest),_,impl,st,doVect,pre,_)
      equation
        (cache,exp,p,st_1) = elabExp(cache, env, e, impl, st, doVect, pre, info);
        (cache,exps,props,st_2) = elabExpList2(cache, env, rest, Types.getPropType(p), impl, st_1, doVect, pre, info);
      then
        (cache,(exp :: exps),(p :: props),st_2);

  end matchcontinue;
end elabExpList2;

public function elabExpListList
"Expression elaboration of lists of lists of expressions.
  Used in for instance matrices, etc."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input DAE.Type ty "The type of the last evaluated expression; used to speed up instantiation of enumerations :)";
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<list<DAE.Exp>> outExpExpLstLst;
  output list<list<DAE.Properties>> outTypesPropertiesLstLst;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outExpExpLstLst,outTypesPropertiesLstLst,outST):=
  match (inCache,inEnv,inAbsynExpLstLst,ty,inBoolean,st,performVectorization,inPrefix,info)
    local
      Boolean impl;
      Option<GlobalScript.SymbolTable> st_1,st_2;
      list<DAE.Exp> exp;
      list<DAE.Properties> p;
      list<list<DAE.Exp>> exps;
      list<list<DAE.Properties>> props;
      list<Env.Frame> env;
      list<Absyn.Exp> e;
      list<list<Absyn.Exp>> rest;
      Env.Cache cache;
      Boolean doVect;
      Prefix.Prefix pre;
      DAE.Properties p1;

    case (cache,_,{},_,_,_,_,_,_) then (cache,{},{},st);
    case (cache,env,(e :: rest),_,impl,_,doVect,pre,_)
      equation
        (cache,exp,p as p1::_,st_1) = elabExpList2(cache,env,e,ty,impl,st,doVect,pre,info);
        (cache,exps,props,st_2) = elabExpListList(cache,env,rest,Types.getPropType(p1),impl,st_1,doVect,pre,info);
      then
        (cache,(exp :: exps),(p :: props),st_2);
  end match;
end elabExpListList;

protected function elabExpOptAndMatchType "
  elabExp, but for Option<Absyn.Exp>,DAE.Type => Option<DAE.Exp>"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.Exp> oExp;
  input DAE.Type defaultType;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache cache;
  output Option<DAE.Exp> outExp;
  output DAE.Properties prop;
  output Option<GlobalScript.SymbolTable> st;
algorithm
  (cache,outExp,prop,st) := match (inCache,inEnv,oExp,defaultType,inBoolean,inSt,performVectorization,inPrefix,info)
    local
      Absyn.Exp inExp;
      DAE.Exp exp;
    case (_,_,SOME(inExp),_,_,_,_,_,_)
      equation
        (cache,exp,prop,st) = elabExp(inCache,inEnv,inExp,inBoolean,inSt,performVectorization,inPrefix,info);
        (exp,prop) = Types.matchProp(exp,prop,DAE.PROP(defaultType,DAE.C_CONST()),true);
      then (cache,SOME(exp),prop,st);
    else (inCache,NONE(),DAE.PROP(defaultType,DAE.C_CONST()),inSt);
  end match;
end elabExpOptAndMatchType;

public function elabExp "
function: elabExp
  Static analysis of expressions means finding out the properties of
  the expression.  These properties are described by the
  DAE.Properties type, and include the type and the variability of the
  expression.  This function performs analysis, and returns an
  DAE.Exp and the properties."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> st;
algorithm
  (outCache,outExp,outProperties,st) := elabExp2(inCache,inEnv,inExp,inImplicit,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix,info,Error.getNumErrorMessages());
end elabExp;

public function elabExpInExpression "Like elabExp but casts PROP_TUPLE to a PROP"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> st;
algorithm
  (outCache,outExp,outProperties,st) := elabExp(inCache,inEnv,inExp,inImplicit,inST,performVectorization,inPrefix,info);
  (outExp,outProperties) := elabExpInExpression2(outExp,outProperties);
end elabExpInExpression;

protected function elabExpInExpression2
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp,outProperties) := match (inExp,inProperties)
    local
      DAE.Type ty;
      DAE.Const c;
    case (_,DAE.PROP_TUPLE(type_ = DAE.T_TUPLE(tupleType = ty :: _), tupleConst = DAE.TUPLE_CONST(tupleConstLst = DAE.SINGLE_CONST(const = c) :: _)))
      then (DAE.TSUB(inExp, 1, ty), DAE.PROP(ty,c));
    else (inExp,inProperties);
  end match;
end elabExpInExpression2;

public function checkAssignmentToInput
  input Absyn.Exp inExp;
  input DAE.Attributes inAttributes;
  input Env.Env inEnv;
  input Boolean inAllowTopLevelInputs;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExp, inAttributes, inEnv, inAllowTopLevelInputs, inInfo)
    case (_, _, _, _, _)
      equation
        true = inAllowTopLevelInputs or not Env.inFunctionScope(inEnv);
      then
        ();

    else
      equation
        checkAssignmentToInput2(inExp, inAttributes, inInfo);
      then
        ();

  end matchcontinue;
end checkAssignmentToInput;

protected function checkAssignmentToInput2
  input Absyn.Exp inExp;
  input DAE.Attributes inAttributes;
  input Absyn.Info inInfo;
algorithm
  _ := match(inExp, inAttributes, inInfo)
    local
      Absyn.ComponentRef cr;
      String cr_str;

    case (Absyn.CREF(cr), DAE.ATTR(direction = Absyn.INPUT()), _)
      equation
        cr_str = Dump.printComponentRefStr(cr);
        Error.addSourceMessage(Error.ASSIGN_READONLY_ERROR,
          {"input", cr_str}, inInfo);
      then
        fail();

    else ();

  end match;
end checkAssignmentToInput2;

public function checkAssignmentToInputs
  input list<Absyn.Exp> inExpCrefs;
  input list<DAE.Attributes> inAttributes;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
protected
  Boolean func_scope;
algorithm
  _ := matchcontinue(inExpCrefs, inAttributes, inEnv, inInfo)
    case (_, _, _, _)
      equation
        false = Env.inFunctionScope(inEnv);
      then
        ();

    else
      equation
        List.threadMap1_0(inExpCrefs, inAttributes, checkAssignmentToInput2, inInfo);
      then
        ();

  end matchcontinue;
end checkAssignmentToInputs;

public function elabExpCrefNoEvalList
"elaborates a list of expressions that are only component references."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inExpLst;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numErrorMessages;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpLst;
  output list<DAE.Properties> outPropertiesLst;
  output list<DAE.Attributes> outAttributesLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExpLst,outPropertiesLst,outAttributesLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpLst,inImplicit,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix,info,numErrorMessages)
    local
      Env.Cache cache;
      Env.Env env;
      Boolean impl,doVect;
      Option<GlobalScript.SymbolTable> st;
      list<Absyn.Exp> rest;
      Absyn.Exp aExp;
      Prefix.Prefix pre;
      Absyn.ComponentRef cr;
      list<DAE.Attributes> attrLst;
      list<DAE.Exp> expLst;
      DAE.Exp exp;
      DAE.Attributes attr;
      list<DAE.Properties> propLst;
      DAE.Properties prop;
      String msg;
      DAE.Type ty;

    case (cache,env,{},impl,st,doVect,pre,_,_) then (cache,{},{},{},st);

    case (cache,env,Absyn.CREF(componentRef = cr)::rest,impl,st,doVect,pre,_,_) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.CEVAL_EQUATION);
        (cache,SOME((exp,prop as DAE.PROP(ty,DAE.C_PARAM()),attr))) = elabCrefNoEval(cache,env, cr, impl, doVect, pre, info);
        (cache, expLst, propLst, attrLst, st) = elabExpCrefNoEvalList(cache, env, rest, impl, st, doVect, pre, info, numErrorMessages);
      then
        (cache,exp::expLst,DAE.PROP(ty,DAE.C_VAR())::propLst,attr::attrLst,st);

    case (cache,env,Absyn.CREF(componentRef = cr)::rest,impl,st,doVect,pre,_,_)
      equation
        (cache,SOME((exp,prop,attr))) = elabCrefNoEval(cache, env, cr, impl, doVect, pre, info);
        (cache, expLst, propLst, attrLst, st) = elabExpCrefNoEvalList(cache, env, rest, impl, st, doVect, pre, info, numErrorMessages);
      then
        (cache,exp::expLst,prop::propLst,attr::attrLst,st);

   case (cache,env,aExp::_,_,_,_,pre,_,_)
     equation
       true = numErrorMessages == Error.getNumErrorMessages();
       msg = Dump.printExpStr(aExp);
       Error.addSourceMessage(Error.GENERIC_ELAB_EXPRESSION,{msg},info);
     then
       fail();
  end matchcontinue;
end elabExpCrefNoEvalList;

protected function elabExp2 "
function: elabExp
  Static analysis of expressions means finding out the properties of
  the expression.  These properties are described by the
  DAE.Properties type, and include the type and the variability of the
  expression.  This function performs analysis, and returns an
  DAE.Exp and the properties."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numErrorMessages;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inImplicit,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix,info,numErrorMessages)
    local
      Boolean impl,a,b,havereal,doVect;
      Integer l,i,nmax;
      Real r;
      String expstr,str1,str2,s,msg;
      DAE.Dimension dim1,dim2;
      Option<GlobalScript.SymbolTable> st,st_1,st_2;
      DAE.Exp exp,e1_1,e2_1,exp_1,e_1,mexp,mexp_1,arrexp;
      DAE.Properties prop,prop1,prop2;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,fn;
      DAE.Type t,t1,t2,arrtp,t_1,t_2,tp,ty;
      DAE.Const c1,c2,c,const;
      Absyn.Exp e,e1,e2,e3;
      Absyn.Operator op;
      list<Absyn.Exp> args,es;
      list<Absyn.NamedArg> nargs;
      list<DAE.Exp> es_1;
      list<DAE.Properties> props,propList;
      list<DAE.Type> types,tps_2;
      list<DAE.TupleConst> consts;
      DAE.Type at,tp_1;
      list<list<DAE.Properties>> tps;
      list<list<DAE.Type>> tps_1;
      Env.Cache cache;
      Absyn.ForIterators iterators;
      Prefix.Prefix pre;
      list<list<Absyn.Exp>> ess;
      list<list<DAE.Exp>> dess;
      Absyn.CodeNode cn;
      list<DAE.Type> typeList;
      list<DAE.Const> constList;


    /* uncomment for debuging
    case (cache,_,inExp,impl,st,doVect,_,info)
      equation
        print("Static.elabExp: " +& Dump.dumpExpStr(inExp) +& "\n");
      then
        fail();
    */

    // The types below should contain the default values of the attributes of the builtin
    // types. But since they are default, we can leave them out for now, unit=\"\" is not
    // that interesting to find out.
    case (cache,_,Absyn.INTEGER(value = i),impl,st,doVect,_,_,_)
    then (cache,DAE.ICONST(i),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()),st);

    case (cache,_,Absyn.REAL(value = r),impl,st,doVect,_,_,_)
      then
        (cache,DAE.RCONST(r),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_CONST()),st);

    case (cache,_,Absyn.STRING(value = s),impl,st,doVect,_,_,_)
      equation
        s = System.unescapedString(s);
      then
        (cache,DAE.SCONST(s),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()),st);

    case (cache,_,Absyn.BOOL(value = b),impl,st,doVect,_,_,_)
      then
        (cache,DAE.BCONST(b),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),st);

    case (cache,_,Absyn.END(),impl,st,doVect,_,_,_)
      equation
        Error.addSourceMessage(Error.END_ILLEGAL_USE_ERROR, {}, info);
      then fail();

    case (cache,env,Absyn.CREF(componentRef = cr),impl,st,doVect,pre,_,_) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.CEVAL_EQUATION);
        (cache,SOME((exp,prop as DAE.PROP(ty,DAE.C_PARAM()),_))) = elabCref(cache,env, cr, impl, doVect, pre, info);
      then
        (cache,exp,DAE.PROP(ty,DAE.C_VAR()),st);

    case (cache,env,Absyn.CREF(componentRef = cr),impl,st,doVect,pre,_,_)
      equation
        (cache,SOME((exp,prop,_))) = elabCref(cache, env, cr, impl, doVect, pre, info);
      then
        (cache,exp,prop,st);

    case (cache,env,(e as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre,_,_) /* Binary and unary operations */
      equation
        (cache,e1_1,prop1,st_1) = elabExp(cache,env, e1, impl, st,doVect,pre,info);
        (cache,e2_1,prop2,st_2) = elabExp(cache,env, e2, impl, st_1,doVect,pre,info);
        (cache,exp_1,prop) = operatorDeoverloadBinary(cache,env,op,prop1,e1_1,prop2,e2_1,e,e1,e2,impl,st_2,pre,info);
      then
        (cache,exp_1,prop,st_2);

    case (cache,env,(e as Absyn.UNARY(op = Absyn.UPLUS(),exp = e1)),impl,st,doVect,pre,_,_)
      equation
        (cache,exp_1,DAE.PROP(t,c),st_1) = elabExp(cache,env,e1,impl,st,doVect,pre,info);
        true = Types.isIntegerOrRealOrSubTypeOfEither(Types.arrayElementType(t));
        prop = DAE.PROP(t,c);
      then
        (cache,exp_1,prop,st_1);

    case (cache,env,(e as Absyn.UNARY(op = op,exp = e1)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop1,st_1) = elabExp(cache,env,e1,impl,st,doVect,pre,info);
        (cache,exp_1,prop) = operatorDeoverloadUnary(cache,env,op,prop1,e_1,e,e1,impl,st_1,pre,info);
      then
        (cache,exp_1,prop,st_1);

    case (cache,env,(e as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre,_,_) "Logical binary expressions"
      equation
        (cache,e1_1,prop1,st_1) = elabExp(cache,env, e1, impl, st,doVect,pre,info);
        (cache,e2_1,prop2,st_2) = elabExp(cache,env, e2, impl, st_1,doVect,pre,info);
        (cache,exp_1,prop) = operatorDeoverloadBinary(cache,env,op,prop1,e1_1,prop2,e2_1,e,e1,e2,impl,st_2,pre,info);
      then
        (cache,exp_1,prop,st_2);

    case (cache,env,(e as Absyn.LUNARY(op = op,exp = e1)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop1,st_1) = elabExp(cache,env,e1,impl,st,doVect,pre,info);
        (cache,exp_1,prop) = operatorDeoverloadUnary(cache,env,op,prop1,e_1,e,e1,impl,st_1,pre,info);
      then
        (cache,exp_1,prop,st_1);


    case (cache,env,(e as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre,_,_)
      equation
        (cache,e1_1,prop1,st_1) = elabExp(cache,env, e1, impl, st,doVect,pre,info);
        (cache,e2_1,prop2,st_2) = elabExp(cache,env, e2, impl, st_1,doVect,pre,info);
        (cache,exp_1,prop) = operatorDeoverloadBinary(cache,env,op,prop1,e1_1,prop2,e2_1,e,e1,e2,impl,st_2,pre,info);
      then
        (cache,exp_1,prop,st_2);

    case (cache,env,e as Absyn.IFEXP(ifExp = _),impl,st,doVect,pre,_,_) /* Conditional expressions */
      equation
        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(e);
        (cache,e1_1,prop1,st_1) = elabExp(cache,env, e1, impl, st,doVect,pre,info) "if expressions";
        (cache,e_1,prop,st_2) = elabIfExp(cache,env,e1_1,prop1,e2,e3,impl,st_1,doVect,pre,info);
      then
        (cache,e_1,prop,st_2);

    // adrpo: deal with EnumToInteger(E) -> transform to Integer(E)
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect,pre,_,_)
      equation
        s = Absyn.pathLastIdent(Absyn.crefToPathIgnoreSubs(fn));
        true = stringEq(s, "EnumToInteger");        
        (cache,e_1,prop,st_1) = elabCall(cache, env, Absyn.CREF_IDENT("Integer", {}), args, nargs, impl, st,pre,info,Error.getNumErrorMessages());
        c = Types.propAllConst(prop);
        (e_1,_) = ExpressionSimplify.simplify1(e_1);
      then
        (cache,e_1,prop,st_1);

    // adrpo: deal with DynamicSelect(literalExp, dynamicExp) by returning literalExp only!
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("DynamicSelect",_),functionArgs = Absyn.FUNCTIONARGS(args = (e1 :: _),argNames = _)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = elabExp(cache,env, e1, impl, st, doVect, pre, info);
      then
        (cache,e_1,prop,st_1);

       /*--------------------------------*/
       /* Part of MetaModelica extension. KS */
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("SOME",_),functionArgs = Absyn.FUNCTIONARGS(args = (e1 :: _),argNames = _)),impl,st,doVect,pre,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,e_1,prop,st_1) = elabExp(cache,env, e1, impl, st,doVect,pre,info);
        t = Types.getPropType(prop);
        (e_1,t) = Types.matchType(e_1,t,DAE.T_METABOXED_DEFAULT,true);
        e_1 = DAE.META_OPTION(SOME(e_1));
        c = Types.propAllConst(prop);
        prop1 = DAE.PROP(DAE.T_METAOPTION(t, DAE.emptyTypeSource),c);
      then
        (cache,e_1,prop1,st);

    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("NONE",_),functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = _)),impl,st,doVect,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        e_1 = DAE.META_OPTION(NONE());
        prop1 = DAE.PROP(DAE.T_METAOPTION(DAE.T_UNKNOWN_DEFAULT, DAE.emptyTypeSource),DAE.C_CONST());
      then
        (cache,e_1,prop1,st);


    //Check if 'String' is overloaded. This can be moved down the chain to avoid checking for normal types.
    //However elab call prints error messags if it can not elaborate it even though the function might be overloaded.
    case (cache,env, e as Absyn.CALL(function_ = Absyn.CREF_IDENT("String",_),functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect,pre,_,_)
      equation
        (cache,exp_1,prop,st_1) = userDefOperatorDeoverloadString(cache,env,e,impl,st,doVect,pre,info);
      then
        (cache,exp_1,prop,st_1);

    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = elabCall(cache,env, fn, args, nargs, impl, st,pre,info,Error.getNumErrorMessages());
        c = Types.propAllConst(prop);
        (e_1,_) = ExpressionSimplify.simplify1(e_1);
      then
        (cache,e_1,prop,st_1);

    // stefan
    case (cache,env,e1 as Absyn.PARTEVALFUNCTION(function_ = _),impl,st,doVect,pre,_,_)
      equation
        (cache,e1_1,prop,st_1) = elabPartEvalFunction(cache,env,e1,st,impl,doVect,pre,info);
      then
        (cache,e1_1,prop,st_1);

    // get the properties for each expression in the tuple. Each expression has its own constflag.
    case (cache,env,Absyn.TUPLE(expressions = es),impl,st,doVect,pre,_,_)
      equation
        (cache,es_1,props) = elabTuple(cache,env,es,impl,doVect,pre,info) "Tuple function calls" ;
        (types,consts) = splitProps(props);
      then
        (cache,DAE.TUPLE(es_1),DAE.PROP_TUPLE(DAE.T_TUPLE(types,DAE.emptyTypeSource),DAE.TUPLE_CONST(consts)),st);

    // Array-related expressions Elab reduction expressions, including array() constructor
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FOR_ITER_FARG(exp = e, iterators=iterators)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = elabCallReduction(cache,env, fn, e, iterators, impl, st,doVect,pre,info);
        c = Types.propAllConst(prop);
      then
        (cache,e_1,prop,st_1);

    case (cache, env, Absyn.RANGE(start = _), impl, st, doVect, pre, _, _)
      equation
        (cache, e_1, prop, st_1) = elabRange(cache, env, inExp, impl, st, doVect, pre, info);
      then
        (cache, e_1, prop, st_1);

    // Part of the MetaModelica extension. This eliminates elab_array failed failtraces when using the empty list. sjoelund
    case (cache,env,Absyn.ARRAY({}),impl,st,doVect,pre,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,exp,prop,st) = elabExp(cache,env,Absyn.LIST({}),impl,st,doVect,pre,info);
      then (cache,exp,prop,st);

    // array expressions, e.g. {1,2,3}
    case (cache,env,Absyn.ARRAY(arrayExp = es),impl,st,doVect,pre,_,_)
      equation
        (cache,es_1,props,_) = elabExpList(cache, env, es, impl, st, doVect, pre, info);
        (es_1,DAE.PROP(t,const)) = elabArray(es_1,props,pre,info); // type-checking the array
        l = listLength(es_1);
        arrtp = DAE.T_ARRAY(t, {DAE.DIM_INTEGER(l)},DAE.emptyTypeSource);
        at = Types.simplifyType(arrtp);
        a = Types.isArray(t,{});
        a = boolNot(a); // scalar = !array
        arrexp =  DAE.ARRAY(at,a,es_1);
        (arrexp,arrtp) = MetaUtil.tryToConvertArrayToList(arrexp,arrtp) "converts types that cannot be arrays into lists";
        arrexp = elabMatrixToMatrixExp(arrexp);
      then
        (cache,arrexp,DAE.PROP(arrtp,const),st);

    case (cache,env,Absyn.MATRIX(matrix = ess),impl,st,doVect,pre,_,_)
      equation
        (cache,dess,tps,_) = elabExpListList(cache, env, ess, DAE.T_UNKNOWN_DEFAULT, impl, st,doVect,pre,info) "matrix expressions, e.g. {1,0;0,1} with elements of simple type." ;
        tps_1 = List.mapList(tps, Types.getPropType);
        tps_2 = List.flatten(tps_1);
        nmax = matrixConstrMaxDim(tps_2);
        havereal = Types.containReal(tps_2);
        (cache,mexp,DAE.PROP(t,c),dim1,dim2)
        = elabMatrixSemi(cache,env, dess, tps, impl, st, havereal, nmax,doVect,pre,info);
        mexp = Util.if_(havereal,DAE.CAST(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{dim1,dim2},DAE.emptyTypeSource),mexp),mexp);
        (mexp,_) = ExpressionSimplify.simplify1(mexp); // to propagate cast down to scalar elts
        mexp_1 = elabMatrixToMatrixExp(mexp);
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1) "All elts promoted to matrix, therefore unlifting" ;
      then
        (cache,mexp_1,DAE.PROP(DAE.T_ARRAY(DAE.T_ARRAY(t_2, {dim2}, DAE.emptyTypeSource), {dim1}, DAE.emptyTypeSource),c),st);

    case (cache,env,Absyn.CODE(code = cn),impl,st,doVect,_,_,_)
      equation
        tp = elabCodeType(env, cn) "Code expressions" ;
        tp_1 = Types.simplifyType(tp);
      then
        (cache,DAE.CODE(cn,tp_1),DAE.PROP(tp,DAE.C_CONST()),st);

       //-------------------------------------
       // Part of the MetaModelica extension. KS
   case (cache,env,Absyn.ARRAY(es),impl,st,doVect,pre,_,_)
     equation
       true = Config.acceptMetaModelicaGrammar();
       (cache,exp,prop,st) = elabExp(cache,env,Absyn.LIST(es),impl,st,doVect,pre,info);
     then (cache,exp,prop,st);

   case (cache,env,Absyn.CONS(e1,e2),impl,st,doVect,pre,_,_)
     equation
       {e1,e2} = MetaUtil.transformArrayNodesToListNodes({e1,e2},{});

       (cache,e1_1,prop1,st_1) = elabExp(cache,env, e1, impl, st,doVect,pre,info);
       (cache,e2_1,DAE.PROP(DAE.T_METALIST(listType = t2),c2),st_1) = elabExp(cache,env, e2, impl, st,doVect,pre,info);
       t1 = Types.getPropType(prop1);
       c1 = Types.propAllConst(prop1);
       t = Types.superType(Types.boxIfUnboxedType(t1),Types.boxIfUnboxedType(t2));

       (e1_1,_) = Types.matchType(e1_1, t1, t, true);
       (e2_1,_) = Types.matchType(e2_1, DAE.T_METALIST(t2, DAE.emptyTypeSource), DAE.T_METALIST(t, DAE.emptyTypeSource), true);

       exp = DAE.CONS(e1_1,e2_1);
       c = Types.constAnd(c1,c2);
       prop = DAE.PROP(DAE.T_METALIST(t, DAE.emptyTypeSource),c);
     then (cache,exp,prop,st);

   case (cache,env,e as Absyn.CONS(e1,e2),impl,st,doVect,pre,_,_)
     equation
       {e1,e2} = MetaUtil.transformArrayNodesToListNodes({e1,e2},{});
       (cache,e1_1,prop1,st_1) = elabExp(cache,env, e1, impl, st,doVect,pre,info);
       (cache,e2_1,DAE.PROP(t2 as DAE.T_METALIST(listType = _),c2),st_1) = elabExp(cache,env, e2, impl, st,doVect,pre,info);
       expstr = Dump.printExpStr(e);
       str1 = Types.unparseType(Types.getPropType(prop1));
       str2 = Types.unparseType(t2);
       Error.addSourceMessage(Error.META_CONS_TYPE_MATCH, {expstr,str1,str2}, info);
     then fail();

       // The Absyn.LIST() node is used for list expressions that are
       // transformed from Absyn.ARRAY()
  case (cache,env,Absyn.LIST({}),impl,st,doVect,_,_,_)
    equation
      t = DAE.T_METALIST_DEFAULT;
      prop = DAE.PROP(t,DAE.C_CONST());
    then (cache,DAE.LIST({}),prop,st);

  case (cache,env,Absyn.LIST(es),impl,st,doVect,pre,_,_)
    equation
      (cache,es_1,propList,st_2) = elabExpList(cache,env, es, impl, st,doVect,pre,info);
      typeList = List.map(propList, Types.getPropType);
      constList = Types.getConstList(propList);
      c = List.fold(constList, Types.constAnd, DAE.C_CONST());
      t = Types.boxIfUnboxedType(List.reduce(typeList, Types.superType));
      (es_1,_) = Types.matchTypes(es_1, typeList, t, true);
      prop = DAE.PROP(DAE.T_METALIST(t,DAE.emptyTypeSource),c);
    then (cache,DAE.LIST(es_1),prop,st_2);
   // ----------------------------------

   // Pattern matching has its own module that handles match expressions
   case (cache,env,e as Absyn.MATCHEXP(matchTy = _),impl,st,doVect,pre,_,_)
     equation
       (cache,exp,prop,st) = Patternm.elabMatchExpression(cache,env,e,impl,st,doVect,pre,info,numErrorMessages);
     then (cache,exp,prop,st);

   case (cache,env,e,_,_,_,pre,_,_)
     equation
       true = numErrorMessages == Error.getNumErrorMessages();
       msg = Dump.printExpStr(e);
       Error.addSourceMessage(Error.GENERIC_ELAB_EXPRESSION,{msg},info);
       /* FAILTRACE REMOVE
       true = Flags.isSet(Flags.FAILTRACE);
       Debug.fprint(Flags.FAILTRACE, "- Static.elabExp failed: ");
       Debug.traceln(Dump.printExpStr(e));
       Debug.traceln("  Scope: " +& Env.printEnvPathStr(env));
       Debug.traceln("  Prefix: " +& PrefixUtil.printPrefixStr(pre));

       //Debug.traceln("\n env : ");
       //Debug.traceln(Env.printEnvStr(env));
       //Debug.traceln("\n----------------------- FINISHED ENV ------------------------\n");
       */
     then
       fail();
  end matchcontinue;
end elabExp2;

protected function elabIfExp
"Elaborates an if-expression. If one of the branches can not be elaborated and
the condition is parameter or constant; it is evaluated and the correct branch is selected.
This is a dirty hack to make MSL CombiTable models work!
Note: Because of this, the function has to rollback or delete an ErrorExt checkpoint."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp condExp;
  input DAE.Properties condProp;
  input Absyn.Exp trueExp;
  input Absyn.Exp falseExp;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean vect;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties prop;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,outExp,prop,outSt) := matchcontinue (inCache,inEnv,condExp,condProp,trueExp,falseExp,impl,inSt,vect,pre,info)
    local
      DAE.Exp etrueExp,efalseExp;
      DAE.Properties trueProp,falseProp;
      Boolean b;
      Option<GlobalScript.SymbolTable> st;
      Env.Cache cache;
      Env.Env env;

    case (cache,env,_,_,_,_,_,st,_,_,_)
      equation
        ErrorExt.setCheckpoint("Static.elabExp:IFEXP");
        (cache,etrueExp,trueProp,st) = elabExp(cache,env,trueExp,impl,st,vect,pre,info);
        (cache,efalseExp,falseProp,st) = elabExp(cache,env,falseExp,impl,st,vect,pre,info);
        (cache,outExp,prop) = makeIfexp(cache,env,condExp,condProp,etrueExp,trueProp,efalseExp,falseProp,impl,st,pre,info);
        ErrorExt.delCheckpoint("Static.elabExp:IFEXP");
      then (cache,outExp,prop,st);
    case (cache,env,_,_,_,_,_,st,_,_,_)
      equation
        ErrorExt.setCheckpoint("Static.elabExp:IFEXP:HACK") "Extra rollback point so we get the regular error message only once if the hack fails";
        true = Types.isParameterOrConstant(Types.propAllConst(condProp));
        (cache,Values.BOOL(b),_) = Ceval.ceval(cache,env,condExp,impl,NONE(),Absyn.MSG(info),0);
        (cache,outExp,prop,st) = elabExp(cache,env,Util.if_(b,trueExp,falseExp),impl,st,vect,pre,info);
        ErrorExt.delCheckpoint("Static.elabExp:IFEXP:HACK");
        ErrorExt.rollBack("Static.elabExp:IFEXP");
      then (cache,outExp,prop,st);
    else
      equation
        ErrorExt.rollBack("Static.elabExp:IFEXP:HACK");
        ErrorExt.delCheckpoint("Static.elabExp:IFEXP");
      then fail();
  end matchcontinue;
end elabIfExp;

// Part of MetaModelica extension
public function elabListExp "Function that elaborates the MetaModelica list type,
for instance list<Integer>.
This is used by Inst.mo when handling a var := {...} statement"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inExpList;
  input DAE.Properties inProp;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption) :=
  matchcontinue (inCache,inEnv,inExpList,inProp,inBoolean,inInteractiveInteractiveSymbolTableOption,performVectorization,inPrefix,info)
    local
      Env.Cache cache;
      Env.Env env;
      Boolean impl,doVect;
      Option<GlobalScript.SymbolTable> st;
      DAE.Properties prop;
      DAE.Const c;
      Prefix.Prefix pre;
      list<Absyn.Exp> expList;
      list<DAE.Exp> expExpList;
      DAE.Type t;
      list<Boolean> boolList;
      list<DAE.Properties> propList;
      list<DAE.Type> typeList;
      DAE.Type t2;

    case (cache,env,{},prop,_,st,_,_,_) then (cache,DAE.LIST({}),prop,st);

    case (cache,env,expList,prop as DAE.PROP(DAE.T_METALIST(listType = t),c),impl,st,doVect,pre,_)
      equation
        (cache,expExpList,propList,st) = elabExpList(cache,env,expList,impl,st,doVect,pre,info);
        typeList = List.map(propList, Types.getPropType);
        (expExpList, t) = Types.listMatchSuperType(expExpList, typeList, true);
      then
        (cache,DAE.LIST(expExpList),DAE.PROP(DAE.T_METALIST(t,DAE.emptyTypeSource),c),st);

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- elabListExp failed, non-matching args in list constructor?");
      then
        fail();
  end matchcontinue;
end elabListExp;
/* ------------------------------- */

public function fromEquationsToAlgAssignments " Converts equations to algorithm assignments.
 Matchcontinue expressions may contain statements that you won't find
 in a normal equation section. For instance:

 case(...)
 local
 equation
     (var1,_,MYREC(...)) = func(...);
    fail();
 then 1;"
  input list<Absyn.EquationItem> eqsIn;
  input list<Absyn.AlgorithmItem> accList;
  input Env.Cache cache;
  input Env.Env env;
  input Prefix.Prefix inPrefix;
  output Env.Cache outCache;
  output list<Absyn.AlgorithmItem> algsOut;
algorithm
  (outCache,algsOut) :=
  match (eqsIn,accList,cache,env,inPrefix)
    local
      list<Absyn.AlgorithmItem> localAccList;
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix.Prefix pre;
      Option<Absyn.Comment> comment;
      Absyn.Info info;
      Absyn.Equation first;
      list<Absyn.EquationItem> rest;
      list<Absyn.AlgorithmItem> alg;
    case ({},localAccList,localCache,localEnv,_) then (localCache,listReverse(localAccList));
    case (Absyn.EQUATIONITEM(equation_ = first, comment = comment, info = info) :: rest,localAccList,localCache,localEnv,pre)
      equation
        (localCache,alg) = fromEquationToAlgAssignment(first,comment,info,localCache,localEnv,pre);
        (localCache,localAccList) = fromEquationsToAlgAssignments(rest,listAppend(alg,localAccList),localCache,localEnv,pre);
      then (localCache,localAccList);
  end match;
end fromEquationsToAlgAssignments;

protected function fromEquationBranchesToAlgBranches
"Converts equations to algorithm assignments."
  input list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> eqsIn;
  input list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> accList;
  input Env.Cache cache;
  input Env.Env env;
  input Prefix.Prefix inPrefix;
  output Env.Cache outCache;
  output list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> algsOut;
algorithm
  (outCache,algsOut) :=
  match (eqsIn,accList,cache,env,inPrefix)
    local
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> localAccList;
      list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> rest;
      Env.Cache localCache;
      Env.Env localEnv;
      Prefix.Prefix pre;
      Absyn.Exp e;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.EquationItem> eqs;
    case ({},localAccList,localCache,localEnv,_) then (localCache,listReverse(localAccList));
    case ((e,eqs)::rest,localAccList,localCache,localEnv,pre)
      equation
        (localCache,algs) = fromEquationsToAlgAssignments(eqs,{},localCache,localEnv,pre);
        (localCache,localAccList) = fromEquationBranchesToAlgBranches(rest,(e,algs)::localAccList,localCache,localEnv,pre);
      then (localCache,localAccList);
  end match;
end fromEquationBranchesToAlgBranches;

protected function fromEquationToAlgAssignment "function: fromEquationToAlgAssignment"
  input Absyn.Equation eq;
  input Option<Absyn.Comment> comment;
  input Absyn.Info info;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Prefix.Prefix inPrefix;
  output Env.Cache outCache;
  output list<Absyn.AlgorithmItem> algStatement;
algorithm
  (outCache,algStatement) := matchcontinue (eq,comment,info,inCache,inEnv,inPrefix)
    local
      Env.Cache localCache,cache;
      Env.Env env;
      Prefix.Prefix pre;
      String str,strLeft,strRight;
      Absyn.Exp left,right,e;
      Absyn.AlgorithmItem algItem,algItem1,algItem2;
      Absyn.Equation eq2;
      Option<Absyn.Comment> comment2;
      Absyn.Info info2;
      Absyn.AlgorithmItem res;
      Absyn.ComponentRef cref;
      Absyn.FunctionArgs fargs;
      list<Absyn.AlgorithmItem> algs, algTrueItems, algElseItems;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> algBranches;
      list<Absyn.EquationItem> eqTrueItems, eqElseItems;
      list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> eqBranches;

    case (Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_IDENT(strLeft,{})),Absyn.CREF(Absyn.CREF_IDENT(strRight,{}))),_,_,localCache,_,_)
      equation
        true = strLeft ==& strRight;
        // match x case x then ... produces equation x = x; we save a bit of time by removing it here :)
      then (localCache,{});

      // The syntax n>=0 = true; is also used
    case (Absyn.EQ_EQUALS(left,Absyn.BOOL(true)),_,_,localCache,_,_)
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info);
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.LUNARY(Absyn.NOT(),left),{algItem1},{},{}),comment,info);
      then (localCache,{algItem2});

    case (Absyn.EQ_EQUALS(left,Absyn.BOOL(false)),_,_,localCache,_,_)
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info);
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_IF(left,{algItem1},{},{}),comment,info);
      then (localCache,{algItem2});

    case (Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("fail",_),_),_,_,localCache,_,_)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),comment,info);
      then (localCache,{algItem});

    case (Absyn.EQ_NORETCALL(cref,fargs),_,_,localCache,_,_)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(cref,fargs),comment,info);
      then (localCache,{algItem});

    case (Absyn.EQ_EQUALS(left,right),_,_,localCache,_,_)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),comment,info);
      then (localCache,{algItem});

    case (Absyn.EQ_FAILURE(Absyn.EQUATIONITEM(eq2,comment2,info2)),_,_,cache,env,pre)
      equation
        (cache,algs) = fromEquationToAlgAssignment(eq2,comment2,info2,cache,env,pre);
        res = Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs),comment,info);
      then (cache,{res});

    case (Absyn.EQ_IF(ifExp = e, equationTrueItems = eqTrueItems, elseIfBranches = eqBranches, equationElseItems = eqElseItems),_,_,cache,env,pre)
      equation
        (cache,algTrueItems) = fromEquationsToAlgAssignments(eqTrueItems,{},cache,env,pre);
        (cache,algElseItems) = fromEquationsToAlgAssignments(eqElseItems,{},cache,env,pre);
        (cache,algBranches) = fromEquationBranchesToAlgBranches(eqBranches,{},cache,env,pre);
        res = Absyn.ALGORITHMITEM(Absyn.ALG_IF(e, algTrueItems, algBranches, algElseItems),comment,info);
      then (cache,{res});

    case (_,_,_,_,_,_)
      equation
        str = Dump.equationName(eq);
        Error.addSourceMessage(Error.META_MATCH_EQUATION_FORBIDDEN, {str}, info);
      then fail();
  end matchcontinue;
end fromEquationToAlgAssignment;

protected function elabMatrixGetDimensions "Helper function to elab_exp (MATRIX). Calculates the dimensions of the
  matrix by investigating the elaborated expression."
  input DAE.Exp inExp;
  output Integer outInteger1;
  output Integer outInteger2;
algorithm
  (outInteger1,outInteger2):=
  matchcontinue (inExp)
    local
      Integer dim1,dim2;
      list<DAE.Exp> lst2,lst;
    case (DAE.ARRAY(array = lst))
      equation
        dim1 = listLength(lst);
        (DAE.ARRAY(array = lst2) :: _) = lst;
        dim2 = listLength(lst2);
      then
        (dim1,dim2);
  end matchcontinue;
end elabMatrixGetDimensions;

protected function elabMatrixToMatrixExp
  "Convert an 2-dimensional array expression to a matrix expression."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      list<list<DAE.Exp>> mexpl;
      DAE.Type a;
      Integer d1;
      list<DAE.Exp> expl;

    // Convert a 2-dimensional array to a matrix.
    case (DAE.ARRAY(ty = a as DAE.T_ARRAY(dims = _ :: _ :: {}),
        array = expl))
      equation
        mexpl = elabMatrixToMatrixExp2(expl);
        d1 = listLength(mexpl);
        true = Expression.typeBuiltin(Expression.unliftArray(Expression.unliftArray(a)));
      then
        DAE.MATRIX(a,d1,mexpl);

    // if fails, skip conversion, use generic array expression as is.
    else inExp;
  end matchcontinue;
end elabMatrixToMatrixExp;

protected function elabMatrixToMatrixExp2
  "Helper function to elabMatrixToMatrixExp."
  input list<DAE.Exp> inArrays;
  output list<list<DAE.Exp>> outMatrix;
algorithm
  outMatrix := match (inArrays)
    local
      list<list<DAE.Exp>> es_1;
      DAE.Type a;
      list<DAE.Exp> expl,es;
    case ({}) then {};
    case ((DAE.ARRAY(ty = a,array = expl) :: es))
      equation
        es_1 = elabMatrixToMatrixExp2(es);
      then
        expl :: es_1;
  end match;
end elabMatrixToMatrixExp2;

protected function matrixConstrMaxDim "Helper function to elab_exp (MATRIX).
  Determines the maximum dimension of the array arguments to the matrix
  constructor as.
  max(2, ndims(A), ndims(B), ndims(C),..) for matrix constructor arguments
  A, B, C, ..."
  input list<DAE.Type> inTypesTypeLst;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inTypesTypeLst)
    local
      Integer tn,tn2,res;
      DAE.Type t;
      list<DAE.Type> ts;
    case ({}) then 2;
    case ((t :: ts))
      equation
        tn = Types.numberOfDimensions(t);
        tn2 = matrixConstrMaxDim(ts);
        res = intMax(tn, tn2);
      then
        res;
    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE, "-matrix_constr_max_dim failed\n");
      then
        fail();
  end matchcontinue;
end matrixConstrMaxDim;

protected function elabCallReduction
"This function elaborates reduction expressions that look like function
  calls. For example an array constructor."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef reductionFn;
  input Absyn.Exp reductionExp;
  input Absyn.ForIterators iterators;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outExp,outProperties,outST):=
  matchcontinue (inCache,inEnv,reductionFn,reductionExp,iterators,impl,
      inST,performVectorization,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.Type expty;
      DAE.Const iterconst,expconst,const;
      list<Env.Frame> env_foldExp,env_1,env;
      Option<GlobalScript.SymbolTable> st;
      DAE.Properties prop;
      Absyn.Path fn_1;
      Absyn.ComponentRef fn;
      Absyn.Exp exp;
      Boolean doVect,hasGuardExp;
      Env.Cache cache;
      Prefix.Prefix pre;
      Option<Absyn.Exp> afoldExp;
      Option<DAE.Exp> foldExp;
      Option<Values.Value> v;
      list<DAE.ReductionIterator> reductionIters;
      DAE.Dimensions dims;
      DAE.Properties props;
      Absyn.ForIterators iters;

    case (cache,env,fn,exp,iters,_,st,doVect,pre,_)
      equation
        env_1 = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(Env.forIterScopeName), NONE());
        iters = listReverse(iters);
        (cache,env_1,reductionIters,dims,iterconst,hasGuardExp,st) = elabCallReductionIterators(cache, env_1, iters, impl, st, doVect, pre, info);
        dims = listReverse(dims);
        // print("elabReductionExp: " +& Dump.printExpStr(exp) +& "\n");
        (cache,exp_1,DAE.PROP(expty, expconst),st) = elabExpInExpression(cache, env_1, exp, impl, st, doVect, pre, info);
        // print("exp_1 has type: " +& Types.unparseType(expty) +& "\n");
        const = Types.constAnd(expconst, iterconst);
        fn_1 = Absyn.crefToPath(fn);
        (cache,exp_1,expty,v,fn_1) = reductionType(cache, env, fn_1, exp_1, expty, Types.unboxedType(expty), dims, hasGuardExp, info);
        prop = DAE.PROP(expty, const);
        (env_foldExp,afoldExp) = makeReductionFoldExp(env_1,fn_1,expty);
        (cache,foldExp,_,st) = elabExpOptAndMatchType(cache, env_foldExp, afoldExp, expty, impl, st, doVect,pre,info);
        // print("make reduction: " +& Absyn.pathString(fn_1) +& " exp_1: " +& ExpressionDump.printExpStr(exp_1) +& "\n");
        exp_1 = DAE.REDUCTION(DAE.REDUCTIONINFO(fn_1,expty,v,foldExp),exp_1,reductionIters);
      then
        (cache,exp_1,prop,st);

    case (cache,env,fn,exp,_::_::_,_,st,doVect,pre,_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Reductions using multiple iterators is not yet implemented. Try rewriting the expression using nested reductions (e.g. array(i+j for i, j) => array(array(i+j for i) for j)."}, info);
      then fail();

    case (cache,env,fn,exp,_,_,st,doVect,pre,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "Static.elabCallReduction - failed!\n");
      then fail();
  end matchcontinue;
end elabCallReduction;

protected function elabCallReductionIterators
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ForIterators inIterators;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean doVect;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Env.Env envWithIterators;
  output list<DAE.ReductionIterator> outIterators;
  output DAE.Dimensions outDims;
  output DAE.Const const;
  output Boolean hasGuardExp;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,envWithIterators,outIterators,outDims,const,hasGuardExp,outST) :=
  match (inCache,inEnv,inIterators,impl,inSt,doVect,pre,info)
    local
      String iter;
      Option<Absyn.Exp> aguardExp;
      Absyn.Exp aiterExp;
      Option<DAE.Exp> guardExp;
      DAE.Exp iterExp;
      DAE.ReductionIterator diter;
      DAE.Dimension dim;
      list<DAE.ReductionIterator> diters;
      DAE.Dimensions dims;
      Env.Cache cache;
      Env.Env env;
      DAE.Const iterconst,guardconst;
      DAE.Type fulliterty,iterty;
      Option<GlobalScript.SymbolTable> st;
      Absyn.ForIterators iterators;

    case (cache,env,{},_,st,_,_,_) then (cache,env,{},{},DAE.C_CONST(),false,st);
    case (cache,env,Absyn.ITERATOR(iter,aguardExp,SOME(aiterExp))::iterators,_,st,_,_,_)
      equation
        (cache,iterExp,DAE.PROP(fulliterty,iterconst),st) = elabExp(cache, env, aiterExp, impl, st, doVect,pre,info);
        // We need to evaluate the iterator because the rest of the compiler is stupid
        (cache,iterExp,_) = Ceval.cevalIfConstant(cache,env,iterExp,DAE.PROP(fulliterty,DAE.C_CONST()),impl, info);
        (iterty,dim) = Types.unliftArrayOrList(fulliterty);

        // print("iterator type: " +& Types.unparseType(iterty) +& "\n");
        envWithIterators = Env.extendFrameForIterator(env, iter, iterty, DAE.UNBOUND(), SCode.CONST(), SOME(iterconst));
        // print("exp_1 has type: " +& Types.unparseType(expty) +& "\n");
        (cache,guardExp,DAE.PROP(_, guardconst),st) = elabExpOptAndMatchType(cache, envWithIterators, aguardExp, DAE.T_BOOL_DEFAULT, impl, st, doVect,pre,info);

        diter = DAE.REDUCTIONITER(iter,iterExp,guardExp,iterty);

        (cache,envWithIterators,diters,dims,const,hasGuardExp,st) = elabCallReductionIterators(cache,env,iterators,impl,st,doVect,pre,info);
        // Yes, we do this twice to hide the iterators from the different guard-expressions...
        envWithIterators = Env.extendFrameForIterator(envWithIterators, iter, iterty, DAE.UNBOUND(), SCode.CONST(), SOME(iterconst));
        const = Types.constAnd(guardconst, iterconst);
        hasGuardExp = hasGuardExp or Util.isSome(guardExp);
        dim = Util.if_(Util.isSome(guardExp), DAE.DIM_UNKNOWN(), dim);
      then (cache,envWithIterators,diter::diters,dim::dims,const,hasGuardExp,st);
  end match;
end elabCallReductionIterators;

protected function makeReductionFoldExp
  input Env.Env inEnv;
  input Absyn.Path path;
  input DAE.Type expty;
  output Env.Env outEnv;
  output Option<Absyn.Exp> afoldExp;
algorithm
  (outEnv,afoldExp) := match (inEnv,path,expty)
    local
      Absyn.Exp exp;
      Absyn.ComponentRef cr,cr1,cr2;
      Env.Env env;

    case (env,Absyn.IDENT("array"),_) then (env,NONE());
    case (env,Absyn.IDENT("list"),_) then (env,NONE());
    case (env,Absyn.IDENT("listReverse"),_) then (env,NONE());
    case (env,Absyn.IDENT("sum"),_)
      equation
        cr = Absyn.pathToCref(path);
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpA", expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpB", expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT("$reductionFoldTmpA",{});
        cr2 = Absyn.CREF_IDENT("$reductionFoldTmpB",{});
        exp = Absyn.BINARY(Absyn.CREF(cr1),Absyn.ADD(),Absyn.CREF(cr2));
      then (env,SOME(exp));
    case (env,Absyn.IDENT("product"),_)
      equation
        cr = Absyn.pathToCref(path);
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpA", expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpB", expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT("$reductionFoldTmpA",{});
        cr2 = Absyn.CREF_IDENT("$reductionFoldTmpB",{});
        exp = Absyn.BINARY(Absyn.CREF(cr1),Absyn.MUL(),Absyn.CREF(cr2));
      then (env,SOME(exp));
    else
      equation
        env = inEnv;
        cr = Absyn.pathToCref(path);
        // print("makeReductionFoldExp => " +& Absyn.pathString(path) +& Types.unparseType(expty) +& "\n");
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpA", expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = Env.extendFrameForIterator(env, "$reductionFoldTmpB", expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT("$reductionFoldTmpA",{});
        cr2 = Absyn.CREF_IDENT("$reductionFoldTmpB",{});
        exp = Absyn.CALL(cr,Absyn.FUNCTIONARGS({Absyn.CREF(cr1),Absyn.CREF(cr2)},{}));
      then (env,SOME(exp));
  end match;
end makeReductionFoldExp;

protected function reductionType
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path fn;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input DAE.Type unboxedType;
  input DAE.Dimensions dims;
  input Boolean hasGuardExp;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output Option<Values.Value> defaultValue;
  output Absyn.Path outPath;
algorithm
  (outCache,outExp,outType,defaultValue,outPath) :=
  match (inCache, inEnv, fn, inExp, inType, unboxedType, dims, hasGuardExp, info)
    local
      Boolean b;
      Integer i;
      Real r;
      list<DAE.Type> fnTypes;
      DAE.Type ty,typeA,typeB,resType;
      Absyn.Path path;
      Values.Value v;
      DAE.Exp exp;
      Env.Cache cache;
      Env.Env env;

    case (cache,env,Absyn.IDENT(name = "array"), exp, ty, _, _, b, _)
      equation
        ty = List.foldr(dims,Types.liftArray,ty);
      then (cache,exp,ty,SOME(Values.ARRAY({},{0})),fn);

    case (cache,env,Absyn.IDENT(name = "list"), exp, ty, _, _, _, _)
      equation
        (exp,ty) = Types.matchType(exp, ty, DAE.T_METABOXED_DEFAULT, true);
      then (cache,exp,DAE.T_METALIST(ty, DAE.emptyTypeSource),SOME(Values.LIST({})),fn);

    case (cache,env,Absyn.IDENT(name = "listReverse"), exp, ty, _, _, _, _)
      equation
        (exp,ty) = Types.matchType(exp, ty, DAE.T_METABOXED_DEFAULT, true);
      then (cache,exp,DAE.T_METALIST(ty, DAE.emptyTypeSource),SOME(Values.LIST({})),fn);

    case (cache,env,Absyn.IDENT("min"),exp, ty, DAE.T_REAL(varLst = _),_,_,_)
      equation
        r = System.realMaxLit();
        v = Values.REAL(r);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("min"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        i = System.intMaxLit();
        v = Values.INTEGER(i);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("min"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(true);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("min"),exp,ty,DAE.T_STRING(varLst = _),_,_,_)
      equation
        (exp,ty) = Types.matchType(exp, ty, DAE.T_STRING_DEFAULT, true);
      then (cache,exp,ty,NONE(),fn);

    case (cache,env,Absyn.IDENT("max"),exp,ty,DAE.T_REAL(varLst = _),_,_,_)
      equation
        r = realNeg(System.realMaxLit());
        v = Values.REAL(r);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("max"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        i = intNeg(System.intMaxLit());
        v = Values.INTEGER(i);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("max"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(false);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("max"),exp,ty,DAE.T_STRING(varLst = _),_,_,_)
      equation
        v = Values.STRING("");
        (exp,ty) = Types.matchType(exp, ty, DAE.T_STRING_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("sum"),exp,ty,DAE.T_REAL(varLst = _),_,_,_)
      equation
        v = Values.REAL(0.0);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("sum"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        v = Values.INTEGER(0);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("sum"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(false);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("sum"),exp,ty,DAE.T_STRING(varLst = _),_,_,_)
      equation
        v = Values.STRING("");
        (exp,ty) = Types.matchType(exp, ty, DAE.T_STRING_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("sum"),exp,ty,DAE.T_ARRAY(ty =_),_,_,_)
      then (cache,exp,ty,NONE(),fn);

    case (cache,env,Absyn.IDENT("product"),exp,ty,DAE.T_REAL(varLst = _),_,_,_)
      equation
        v = Values.REAL(1.0);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("product"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        v = Values.INTEGER(1);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("product"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(true);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,SOME(v),fn);

    case (cache,env,Absyn.IDENT("product"),exp,ty,DAE.T_STRING(varLst = _),_,_,_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"product reduction not defined for String"},info);
      then fail();

    case (cache,env,Absyn.IDENT("product"),exp,ty,DAE.T_ARRAY(ty = _),_,_,_)
      equation
      then (cache,exp,ty,NONE(),fn);

    case (cache,env,path,exp,ty,_,_,_,_)
      equation
        (cache,fnTypes) = Lookup.lookupFunctionsInEnv(cache, env, path, info);
        (typeA,typeB,resType,path) = checkReductionType1(env,path,fnTypes,info);
        (exp,ty) = checkReductionType2(exp,ty,typeA,typeB,resType,Types.equivtypes(typeA,typeB),Types.equivtypes(typeB,resType),info);
        (cache,Util.SUCCESS()) = instantiateDaeFunction(cache, env, path, false, NONE(), true);
        Error.assertionOrAddSourceMessage(Config.acceptMetaModelicaGrammar() or Flags.isSet(Flags.EXPERIMENTAL_REDUCTIONS), Error.COMPILER_NOTIFICATION, {"Custom reduction functions are an OpenModelica extension to the Modelica Specification. Do not use them if you need your model to compile using other tools or if you are concerned about using experimental features. Use +d=experimentalReductions to disable this message."}, info);
      then (cache,exp,ty,NONE(),path);
  end match;
end reductionType;

protected function checkReductionType1
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<DAE.Type> fnTypes;
  input Absyn.Info info;
  output DAE.Type typeA;
  output DAE.Type typeB;
  output DAE.Type resType;
  output Absyn.Path outPath;
algorithm
  (typeA,typeB,resType,outPath) := match (inEnv,inPath,fnTypes,info)
    local
      String str1,str2;
      Absyn.Path path;
      Env.Env env;

    case (env, path, {}, _)
      equation
        str1 = Absyn.pathString(path);
        str2 = Env.printEnvPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_ERROR, {str1,str2}, info);
      then fail();

    case (env, _, {DAE.T_FUNCTION(funcArg={(_,typeA,DAE.C_VAR(),_),(_,typeB,DAE.C_VAR(),_)},funcResultType = resType, source = {path})}, _)
      then (typeA,typeB,resType,path);

    case (env, path, _, _)
      equation
        str1 = stringDelimitList(List.map(fnTypes, Types.unparseType), ",");
        Error.addSourceMessage(Error.UNSUPPORTED_REDUCTION_TYPE, {str1}, info);
      then fail();
  end match;
end checkReductionType1;

protected function checkReductionType2
  input DAE.Exp inExp;
  input DAE.Type expType;
  input DAE.Type typeA;
  input DAE.Type typeB;
  input DAE.Type typeC;
  input Boolean equivAB;
  input Boolean equivBC;
  input Absyn.Info info;
  output DAE.Exp outExp;
  output DAE.Type outTy;
algorithm
  (outExp,outTy) := matchcontinue (inExp,expType,typeA,typeB,typeC,equivAB,equivBC,info)
    local
      String str1,str2;
      DAE.Exp exp;

    case (exp,_,_,_,_,true,true,_)
      equation
        // print("Casting " +& ExpressionDump.printExpStr(exp) +& " of " +& Types.unparseType(expType) +& " to " +& Types.unparseType(typeA) +& "\n");
        (exp,outTy) = Types.matchType(exp,expType,typeA,true);
      then (exp,outTy);
    case (_,_,_,_,_,_,false,_)
      equation
        str1 = Types.unparseType(typeB);
        str2 = Types.unparseType(typeC);
        Error.addSourceMessage(Error.REDUCTION_TYPE_ERROR,{"second argument", "result-type", "identical", str1, str2},info);
      then fail();
    case (_,_,_,_,_,false,true,_)
      equation
        str1 = Types.unparseType(typeA);
        str2 = Types.unparseType(typeB);
        Error.addSourceMessage(Error.REDUCTION_TYPE_ERROR,{"first", "second arguments", "identical", str1, str2},info);
      then fail();
    case (_,_,_,_,_,true,true,_)
      equation
        str1 = Types.unparseType(expType);
        str2 = Types.unparseType(typeA);
        Error.addSourceMessage(Error.REDUCTION_TYPE_ERROR,{"reduction expression", "first argument", "compatible", str1, str2},info);
      then fail();
  end matchcontinue;
end checkReductionType2;

protected function constToVariability "translates an DAE.Const to a SCode.Variability"
  input DAE.Const const;
  output SCode.Variability variability;
algorithm
  variability := match(const)
    case(DAE.C_VAR())  then SCode.VAR();
    case(DAE.C_PARAM()) then SCode.PARAM();
    case(DAE.C_CONST()) then SCode.CONST();
    case(DAE.C_UNKNOWN())
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Static.constToVariability failed on DAE.C_UNKNOWN()");
      then
        fail();
  end match;
end constToVariability;

protected function constructArrayType
  "Helper function for elabCallReduction. Combines the type of the expression in
    an array constructor with the type of the generated array by replacing the
    placeholder T_UNKNOWN in arrayType with expType. Example:
      r[i] for i in 1:5 =>
        arrayType = type(i in 1:5) = (T_ARRAY(DIM(5), T_UNKNOWN),NONE())
        expType = type(r[i]) = (T_REAL,NONE())
      => resType = (T_ARRAY(DIM(5), (T_REAL,NONE())),NONE())"
  input DAE.Type arrayType;
  input DAE.Type expType;
  output DAE.Type resType;
algorithm
  resType := match(arrayType, expType)
    local
      DAE.Type ty;
      DAE.Dimension dim;
      Option<Absyn.Path> path;
      DAE.TypeSource ts;

    case (DAE.T_UNKNOWN(_), _) then expType;

    case (DAE.T_ARRAY(dims = {dim}, ty = ty, source = ts), _)
      equation
        ty = constructArrayType(ty, expType);
      then
        DAE.T_ARRAY(ty, {dim}, ts);
  end match;
end constructArrayType;

protected function replaceOperatorWithFcall "Replaces a userdefined operator expression with a corresponding function
  call expression. Other expressions just passes through."
  input Absyn.Exp AbExp;
  input DAE.Exp inExp1;
  input DAE.Operator inOper;
  input Option<DAE.Exp> inExp2;
  input DAE.Const inConst;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (AbExp,inExp1,inOper,inExp2,inConst)
    local
      DAE.Exp e1,e2;
      Absyn.Path funcname;
      DAE.Const c;

    case (Absyn.BINARY(_,_,_), e1, DAE.USERDEFINED(fqName = funcname), SOME(e2), c)
      then DAE.CALL(funcname,{e1,e2},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.BINARY(_,_,_), e1, _, SOME(e2), _)
      then DAE.BINARY(e1, inOper, e2);

    case (Absyn.UNARY(_, _), e1, DAE.USERDEFINED(fqName = funcname), NONE(), c)
      then DAE.CALL(funcname,{e1},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.UNARY(_, _), e1, _, NONE(), _)
        then DAE.UNARY(inOper,e1);

    case (Absyn.LBINARY(_, _, _), e1, DAE.USERDEFINED(fqName = funcname), SOME(e2), c)
       then DAE.CALL(funcname,{e1,e2},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.LBINARY(_,_,_), e1, _, SOME(e2), _)
      then DAE.LBINARY(e1, inOper, e2);

    case (Absyn.LUNARY(_, _), e1, DAE.USERDEFINED(fqName = funcname), NONE(),c)
      then DAE.CALL(funcname,{e1},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.LUNARY(_, _), e1, _, NONE(), _)
        then DAE.LUNARY(inOper,e1);

    case (Absyn.RELATION(_, _, _), e1, DAE.USERDEFINED(fqName = funcname), SOME(e2),c)
      then DAE.CALL(funcname,{e1,e2},DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (Absyn.RELATION(_,_,_), e1, _, SOME(e2), _)
      then DAE.RELATION(e1, inOper, e2, -1, NONE());

  end matchcontinue;
end replaceOperatorWithFcall;

protected function elabCodeType "This function will construct the correct type for the given Code
  expression. The types are built-in classes of different types. E.g.
  the class TypeName is the type
  of Code expressions corresponding to a type name Code expression."
  input Env.Env inEnv;
  input Absyn.CodeNode inCode;
  output DAE.Type outType;
algorithm
  outType := match (inEnv,inCode)
    local list<Env.Frame> env;

    case (env,Absyn.C_TYPENAME(path = _))
      then DAE.T_CODE(DAE.C_TYPENAME(),DAE.emptyTypeSource);

    case (env,Absyn.C_VARIABLENAME(componentRef = _))
      then DAE.T_CODE(DAE.C_VARIABLENAME(),DAE.emptyTypeSource);

    case (env,Absyn.C_EQUATIONSECTION(boolean = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("EquationSection")),{},NONE(),DAE.emptyTypeSource);

    case (env,Absyn.C_ALGORITHMSECTION(boolean = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("AlgorithmSection")),{},NONE(),DAE.emptyTypeSource);

    case (env,Absyn.C_ELEMENT(element = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Element")),{},NONE(),DAE.emptyTypeSource);

    case (env,Absyn.C_EXPRESSION(exp = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Expression")),{},NONE(),DAE.emptyTypeSource);

    case (env,Absyn.C_MODIFICATION(modification = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Modification")),{},NONE(),DAE.emptyTypeSource);
  end match;
end elabCodeType;

public function elabGraphicsExp
"investigating Modelica 2.0 graphical annotations.
  These have an array of records representing graphical objects. These
  elements can have different types, therefore elab_graphic_exp will allow
  arrays with elements of varying types. "
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inPrefix,info)
    local
      Integer i,l,nmax;
      Real r;
      DAE.Dimension dim1,dim2;
      Boolean b,impl,a,havereal;
      String s,ps;
      DAE.Exp dexp,e1_1,e2_1,e_1,e3_1,start_1,stop_1,start_2,stop_2,step_1,step_2,mexp,mexp_1;
      DAE.Properties prop,prop1,prop2,prop3;
      list<Env.Frame> env;
      Absyn.ComponentRef cr,fn;
      DAE.Type t,start_t,stop_t,step_t,t_1,t_2;
      DAE.Const c1,c,c_start,c_stop,const,c_step;
      Absyn.Exp e,e1,e2,e3,start,stop,step,exp;
      Absyn.Operator op;
      list<Absyn.Exp> args,rest,es;
      list<Absyn.NamedArg> nargs;
      list<DAE.Exp> es_1;
      list<DAE.Properties> props;
      list<DAE.Type> types,tps_2;
      list<DAE.TupleConst> consts;
      DAE.Type rt,at;
      list<list<DAE.Properties>> tps;
      list<list<DAE.Type>> tps_1;
      Env.Cache cache;
      Prefix.Prefix pre;
      list<list<Absyn.Exp>> ess;
      list<list<DAE.Exp>> dess;

    case (cache,_,Absyn.INTEGER(value = i),impl,_,_) then (cache,DAE.ICONST(i),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()));  /* impl */

    case (cache,_,Absyn.REAL(value = r),impl,_,_)
      then
        (cache,DAE.RCONST(r),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.STRING(value = s),impl,_,_)
      equation
        s = System.unescapedString(s);
      then
        (cache,DAE.SCONST(s),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.BOOL(value = b),impl,_,_)
      then
        (cache,DAE.BCONST(b),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

    // adrpo: 2010-11-17 this is now fixed!
    // adrpo, if we have useHeatPort, return false.
    // this is a workaround for handling Modelica.Electrical.Analog.Basic.Resistor
    // case (cache,env,Absyn.CREF(componentRef = cr as Absyn.CREF_IDENT("useHeatPort", _)),impl,pre,info)
    //   equation
    //     dexp  = DAE.BCONST(false);
    //     prop = DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_CONST());
    //   then
    //     (cache,dexp,prop);
    case (cache,env,Absyn.CREF(componentRef = cr),impl,pre,_)
      equation
        (cache,SOME((dexp,prop,_))) = elabCref(cache,env, cr, impl,true /*perform vectorization*/,pre,info);
      then
        (cache,dexp,prop);

    // Binary and unary operations
    case (cache,env,(exp as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = operatorDeoverloadBinary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);
    case (cache,env,(e as Absyn.UNARY(op = Absyn.UPLUS(),exp = e1)),impl,pre,_)
      equation
        (cache,e_1,DAE.PROP(t,c)) = elabGraphicsExp(cache,env, e, impl,pre,info);
        true = Types.isRealOrSubTypeReal(Types.arrayElementType(t));
        prop = DAE.PROP(t,c);
      then
        (cache,e_1,prop);
    case (cache,env,(exp as Absyn.UNARY(op = op,exp = e)),impl,pre,_)
      equation
        (cache,e_1,prop1) = elabGraphicsExp(cache,env, e, impl,pre,info);
        (cache, dexp, prop) = operatorDeoverloadUnary(cache,env, op, prop1, e_1, exp, e, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Logical binary expressions
    case (cache,env,(exp as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = operatorDeoverloadBinary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Logical unary expressions
    case (cache,env,(exp as Absyn.LUNARY(op = op,exp = e)),impl,pre,_)
      equation
        (cache,e_1,prop1) = elabGraphicsExp(cache,env, e, impl,pre,info);
        (cache, dexp, prop) = operatorDeoverloadUnary(cache,env, op, prop1, e_1, exp, e, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Relation expressions
    case (cache,env,(exp as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = operatorDeoverloadBinary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Conditional expressions
    case (cache,env,e as Absyn.IFEXP(ifExp = _),impl,pre,_)
      equation
        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(e);
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache,e3_1,prop3) = elabGraphicsExp(cache,env, e3, impl,pre,info);
        (cache,e_1,prop) = makeIfexp(cache,env, e1_1, prop1, e2_1, prop2, e3_1, prop3, impl,NONE(),pre, info);
      then
        (cache,e_1,prop);

    // Function calls
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,pre,_)
      equation
        (cache,e_1,prop,_) = elabCall(cache,env, fn, args, nargs, true,NONE(),pre,info,Error.getNumErrorMessages());
      then
        (cache,e_1,prop);

    // PR. Get the properties for each expression in the tuple.
    // Each expression has its own constflag.
    // The output from functions does just have one const flag. Fix this!!
    case (cache,env,Absyn.TUPLE(expressions = (es as (e1 :: rest))),impl,pre,_)
      equation
        (cache,es_1,props) = elabTuple(cache,env,es,impl,false,pre,info);
        (types,consts) = splitProps(props);
      then
        (cache,DAE.TUPLE(es_1),DAE.PROP_TUPLE(DAE.T_TUPLE(types,DAE.emptyTypeSource),DAE.TUPLE_CONST(consts)));

    // array-related expressions
    case (cache,env,Absyn.RANGE(start = start,step = NONE(),stop = stop),impl,pre,_)
      equation
        (cache,start_1,DAE.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl,pre,info);
        (cache,stop_1,DAE.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl,pre,info);
        (start_2,NONE(),stop_2,rt) = deoverloadRange((start_1,start_t),NONE(), (stop_1,stop_t));
        const = Types.constAnd(c_start, c_stop);
        (cache, t) = elabRangeType(cache, env, start_1, NONE(), stop_1, start_t, rt, const, impl);
      then
        (cache,DAE.RANGE(rt,start_1,NONE(),stop_1),DAE.PROP(t,const));

    case (cache,env,Absyn.RANGE(start = start,step = SOME(step),stop = stop),impl,pre,_)
      equation
        (cache,start_1,DAE.PROP(start_t,c_start)) = elabGraphicsExp(cache,env, start, impl,pre,info) "Debug.fprintln(\"setr\", \"elab_graphics_exp_range2\") &" ;
        (cache,step_1,DAE.PROP(step_t,c_step)) = elabGraphicsExp(cache,env, step, impl,pre,info);
        (cache,stop_1,DAE.PROP(stop_t,c_stop)) = elabGraphicsExp(cache,env, stop, impl,pre,info);
        (start_2,SOME(step_2),stop_2,rt) = deoverloadRange((start_1,start_t), SOME((step_1,step_t)), (stop_1,stop_t));
        c1 = Types.constAnd(c_start, c_step);
        const = Types.constAnd(c1, c_stop);
        (cache, t) = elabRangeType(cache, env, start_1, SOME(step_1), stop_1, start_t, rt, const, impl);
      then
        (cache,DAE.RANGE(rt,start_2,SOME(step_2),stop_2),DAE.PROP(t,const));

    case (cache,env,Absyn.ARRAY(arrayExp = es),impl,pre,_)
      equation
        (cache,es_1,DAE.PROP(t,const)) = elabGraphicsArray(cache,env, es, impl,pre,info);
        l = listLength(es_1);
        at = Types.simplifyType(t);
        a = Types.isArray(t,{});
      then
        (cache,DAE.ARRAY(at,a,es_1),DAE.PROP(DAE.T_ARRAY(t, {DAE.DIM_INTEGER(l)},DAE.emptyTypeSource),const));

    case (cache,env,Absyn.MATRIX(matrix = ess),impl,pre,_)
      equation
        (cache,dess,tps,_) = elabExpListList(cache,env,ess,DAE.T_UNKNOWN_DEFAULT,impl,NONE(),true,pre,info);
        tps_1 = List.mapList(tps, Types.getPropType);
        tps_2 = List.flatten(tps_1);
        nmax = matrixConstrMaxDim(tps_2);
        havereal = Types.containReal(tps_2);
        (cache,mexp,DAE.PROP(t,c),dim1,dim2) = elabMatrixSemi(cache,env,dess,tps,impl,NONE(),havereal,nmax,true,pre,info);
        at = Types.simplifyType(t);
        mexp_1 = elabMatrixToMatrixExp(mexp);
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1);
      then
        (cache,mexp,DAE.PROP(DAE.T_ARRAY(DAE.T_ARRAY(t_2, {dim2}, DAE.emptyTypeSource), {dim1}, DAE.emptyTypeSource),c));

    case (cache,_,e,impl,pre,_)
      equation
        Print.printErrorBuf("- Inst.elabGraphicsExp failed: ");
        ps = PrefixUtil.printPrefixStr2(pre);
        s = Dump.printExpStr(e);
        Print.printErrorBuf(ps+&s);
        Print.printErrorBuf("\n");
      then
        fail();
  end matchcontinue;
end elabGraphicsExp;

protected function deoverloadRange "Does deoverloading of range expressions.
  They can be both Integer ranges and Real ranges.
  This function determines which one to use."
  input tuple<DAE.Exp, DAE.Type> inStart;
  input Option<tuple<DAE.Exp, DAE.Type>> inStep;
  input tuple<DAE.Exp, DAE.Type> inStop;
  output DAE.Exp outStart;
  output Option<DAE.Exp> outStep;
  output DAE.Exp outStop;
  output DAE.Type outRangeType;
algorithm
  (outStart, outStep, outStop, outRangeType) := matchcontinue (inStart, inStep, inStop)
    local
      DAE.Exp e1,e3,e2,e1_1,e3_1,e2_1;
      DAE.Type t1,t3,t2;
      DAE.Type et;
      list<String> ns,ne;

    case ((e1, DAE.T_BOOL(varLst = _)), NONE(), (e3, DAE.T_BOOL(varLst = _)))
      then (e1, NONE(), e3, DAE.T_BOOL_DEFAULT);

    case ((e1, DAE.T_INTEGER(varLst = _)), NONE(), (e3, DAE.T_INTEGER(varLst = _)))
      then (e1, NONE(), e3, DAE.T_INTEGER_DEFAULT);

    case ((e1,DAE.T_INTEGER(varLst = _)), SOME((e2,DAE.T_INTEGER(varLst = _))), (e3,DAE.T_INTEGER(varLst = _)))
      then (e1, SOME(e2), e3, DAE.T_INTEGER_DEFAULT);

    // enumeration has no step value
    case ((e1, t1 as DAE.T_ENUMERATION(names = ns)), NONE(), (e3, DAE.T_ENUMERATION(names = ne)))
      equation
        // check if enumtype start and end are equal
        true = List.isEqual(ns,ne,true);
        // convert vars
        et = Types.simplifyType(t1);
      then
        (e1,NONE(),e3,et);

    case ((e1, t1), NONE(), (e3, t3))
      equation
        ({e1_1, e3_1},_) = elabArglist({DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT},
          {(e1, t1), (e3, t3)});
      then
        (e1_1, NONE(), e3_1, DAE.T_REAL_DEFAULT);

    case ((e1, t1), SOME((e2, t2)),(e3, t3))
      equation
        ({e1_1, e2_1, e3_1},_) = elabArglist(
          {DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT},
          {(e1, t1), (e2, t2), (e3, t3)});
      then
        (e1_1, SOME(e2_1), e3_1, DAE.T_REAL_DEFAULT);

  end matchcontinue;
end deoverloadRange;

protected function elabRange
  "Elaborates a range expression on the form start:stop or start:step:stop."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inRangeExp;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProps;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache, outExp, outProps, outST) :=
  matchcontinue(inCache, inEnv, inRangeExp, inImpl, inST, inVect, inPrefix, info)
    local
      Absyn.Exp start, step, stop;
      Option<Absyn.Exp> opt_step;
      DAE.Exp start_exp, step_exp, stop_exp, range_exp;
      DAE.Type ty, start_t, step_t, stop_t;
      DAE.Const co, start_c, step_c, stop_c;
      Option<GlobalScript.SymbolTable> st;
      Env.Cache cache;
      DAE.Type ety;
      list<String> error_strs;
      String error_str;

    // Range without step value.
    case (_, _, Absyn.RANGE(start = start, step = NONE(), stop = stop), _, _, _, _, _)
      equation
        (cache, start_exp, DAE.PROP(start_t, start_c), st) =
          elabExp(inCache, inEnv, start, inImpl, inST, inVect, inPrefix, info);
        (cache, stop_exp, DAE.PROP(stop_t, stop_c), st) =
          elabExp(cache, inEnv, stop, inImpl, st, inVect, inPrefix, info);
        (start_exp, NONE(), stop_exp, ety) =
          deoverloadRange((start_exp, start_t), NONE(), (stop_exp, stop_t));
        co = Types.constAnd(start_c, stop_c);
        (cache, ty) = elabRangeType(cache, inEnv, start_exp, NONE(), stop_exp, start_t, ety, co, inImpl);
        range_exp = DAE.RANGE(ety, start_exp, NONE(), stop_exp);
      then
        (cache, range_exp, DAE.PROP(ty, co), st);

    // Range with step value.
    case (_, _, Absyn.RANGE(start = start, step = SOME(step), stop = stop), _, _, _, _, _)
      equation
        (cache, start_exp, DAE.PROP(start_t, start_c), st) =
          elabExp(inCache, inEnv, start, inImpl, inST, inVect, inPrefix, info);
        (cache, step_exp, DAE.PROP(step_t, step_c), st) =
          elabExp(cache, inEnv, step, inImpl, st, inVect, inPrefix, info);
        (cache, stop_exp, DAE.PROP(stop_t, stop_c), st) =
          elabExp(cache, inEnv, stop, inImpl, st, inVect, inPrefix, info);
        (start_exp, SOME(step_exp), stop_exp, ety) =
          deoverloadRange((start_exp, start_t), SOME((step_exp, step_t)), (stop_exp, stop_t));
        co = Types.constAnd(start_c, stop_c);
        (cache, ty) = elabRangeType(cache, inEnv, start_exp, SOME(step_exp), stop_exp, start_t, ety, co, inImpl);
        range_exp = DAE.RANGE(ety, start_exp, SOME(step_exp), stop_exp);
      then
        (cache, range_exp, DAE.PROP(ty, co), st);

    case (_, _, Absyn.RANGE(start = start, step = opt_step, stop = stop), _, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        error_strs = List.map(
        List.consr(List.consOption(opt_step, {stop}), start),
          Dump.dumpExpStr);
        error_str = stringDelimitList(error_strs, ":");
        Debug.trace("- " +& Error.infoStr(info));
        Debug.traceln(" Static.elabRangeType failed on " +& error_str);
      then
        fail();
  end matchcontinue;
end elabRange;

protected function elabRangeType
  "This function creates a type for a range expression given by a start, stop,
  and optional step expression. This function always succeeds, but may return an
  array-type of unknown size if the expressions can't be constant evaluated."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inStart;
  input Option<DAE.Exp> inStep;
  input DAE.Exp inStop;
  input DAE.Type inType;
  input DAE.Type inExpType;
  input DAE.Const co;
  input Boolean inImpl;
  output Env.Cache outCache;
  output DAE.Type outType;
algorithm
  (outCache, outType) := matchcontinue(inCache, inEnv, inStart, inStep, inStop, inType,
      inExpType, co, inImpl)
    local
      DAE.Exp step_exp;
      Values.Value start_val, step_val, stop_val;
      Integer dim;
      Env.Cache cache;

    case (_, _, _, _, _, _, _, DAE.C_VAR(), _)
      then (inCache, DAE.T_ARRAY(inType, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource));

    // No step value.
    case (_, _, _, NONE(), _, _, _, _, _)
      equation
        (cache, start_val, _) = Ceval.ceval(inCache, inEnv, inStart, inImpl, NONE(), Absyn.NO_MSG(), 0);
        (cache, stop_val, _) = Ceval.ceval(cache, inEnv, inStop, inImpl, NONE(), Absyn.NO_MSG(), 0);
        dim = elabRangeSize(start_val, NONE(), stop_val);
      then
        (cache, DAE.T_ARRAY(inType, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource));

    // Some step value.
    case (_, _, _, SOME(step_exp), _, _, _, _, _)
      equation
        (cache, start_val, _) = Ceval.ceval(inCache, inEnv, inStart, inImpl, NONE(), Absyn.NO_MSG(), 0);
        (cache, step_val, _) = Ceval.ceval(cache, inEnv, step_exp, inImpl, NONE(), Absyn.NO_MSG(), 0);
        (cache, stop_val, _) = Ceval.ceval(cache, inEnv, inStop, inImpl, NONE(), Absyn.NO_MSG(), 0);
        dim = elabRangeSize(start_val, SOME(step_val), stop_val);
      then
        (cache, DAE.T_ARRAY(inType, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource));

    // Ceval failed in previous cases, return an array of unknown size.
    else
      then (inCache, DAE.T_ARRAY(inType, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource));
  end matchcontinue;
end elabRangeType;

protected function elabRangeSize
  "Returns the size of a range, given a start, stop, and optional step value."
  input Values.Value inStartValue;
  input Option<Values.Value> inStepValue;
  input Values.Value inStopValue;
  output Integer outSize;
algorithm
  outSize := matchcontinue(inStartValue, inStepValue, inStopValue)
    local
      Integer int_start, int_step, int_stop, dim;
      Real real_start, real_step, real_stop;

    // start:stop where start > stop gives an empty vector.
    case (_, NONE(), _)
      equation
        // start > stop == not (start <= stop)
        false = ValuesUtil.safeLessEq(inStartValue, inStopValue);
      then
        0;

    case (Values.INTEGER(int_start), NONE(), Values.INTEGER(int_stop))
      equation
        dim = int_stop - int_start + 1;
      then
        dim;

    case (Values.INTEGER(int_start), SOME(Values.INTEGER(int_step)),
          Values.INTEGER(int_stop))
      equation
        dim = int_stop - int_start;
        dim = intDiv(dim, int_step) + 1;
      then
        dim;

    case (Values.REAL(real_start), NONE(), Values.REAL(real_stop))
      then Util.realRangeSize(real_start, 1.0, real_stop);

    case (Values.REAL(real_start), SOME(Values.REAL(real_step)),
          Values.REAL(real_stop))
      then Util.realRangeSize(real_start, real_step, real_stop);

    case (Values.ENUM_LITERAL(index = int_start), NONE(),
          Values.ENUM_LITERAL(index = int_stop))
      equation
        dim = int_stop - int_start + 1;
      then
        dim;

    case (Values.BOOL(true), NONE(), Values.BOOL(false)) then 0;
    case (Values.BOOL(false), NONE(), Values.BOOL(true)) then 2;
    case (Values.BOOL(_), NONE(), Values.BOOL(_)) then 1;
  end matchcontinue;
end elabRangeSize;

protected function elabTuple "This function does elaboration of tuples, i.e. function calls returning several values."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,performVectorization,inPrefix,info)
    local
      DAE.Exp e_1;
      DAE.Properties p;
      list<DAE.Exp> exps_1;
      list<DAE.Properties> props;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> exps;
      Boolean impl;
      Env.Cache cache;
      Boolean doVect;
      Prefix.Prefix pre;

    case (cache,env,(e :: exps),impl,doVect,pre,_)
      equation
        failure(Absyn.TUPLE(_) = e);
        (cache,e_1,p,_) = elabExp(cache,env, e, impl,NONE(),doVect,pre,info);
        (cache,exps_1,props) = elabTuple(cache,env, exps, impl,doVect,pre,info);
      then
        (cache,(e_1 :: exps_1),(p :: props));

    case (cache,env,{},impl,doVect,_,_) then (cache,{},{});

    case (cache,env,((e as Absyn.TUPLE(_)) :: exps),impl,doVect,pre,_)
      equation
        (cache,e_1,p,_) = elabExp(cache,env, e, impl,NONE(),doVect,pre,info);
        (e_1,p) = Types.matchProp(e_1,p,DAE.PROP(DAE.T_METABOXED_DEFAULT,DAE.C_CONST()),true);
        (cache,exps_1,props) = elabTuple(cache,env, exps, impl,doVect,pre,info);
      then (cache,(e_1 :: exps_1),(p :: props));
  end matchcontinue;
end elabTuple;

// stefan
protected function elabPartEvalFunction
"turns an Absyn.PARTEVALFUNCTION into an DAE.PARTEVALFUNCTION"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Option<GlobalScript.SymbolTable> inSymbolTableOption;
  input Boolean inImpl;
  input Boolean inVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outSymbolTableOption) := matchcontinue(inCache,inEnv,inExp,inSymbolTableOption,inImpl,inVect,inPrefix,info)
    local
      Env.Cache cache;
      Env.Env env;
      Absyn.ComponentRef cref;
      list<Absyn.Exp> posArgs;
      list<Absyn.NamedArg> namedArgs;
      Option<GlobalScript.SymbolTable> st;
      Boolean impl,doVect;
      Absyn.Path p;
      list<DAE.Exp> args;
      DAE.Type ty;
      DAE.Properties prop_1;
      DAE.Type tty,tty_1;
      Prefix.Prefix pre;
      list<Slot> slots;
      list<DAE.Const> consts;
      DAE.Const c;

    case(cache,env,Absyn.PARTEVALFUNCTION(cref,Absyn.FUNCTIONARGS(posArgs,namedArgs)),st,impl,doVect,pre,_)
      equation
        p = Absyn.crefToPath(cref);
        (cache,{tty}) = Lookup.lookupFunctionsInEnv(cache, env, p, info);
        tty = Types.unboxedFunctionType(tty);
        (cache,args,consts,_,tty,_,slots) = elabTypes(cache, env, posArgs, namedArgs, {tty}, true, impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), NONE(), pre, info);
        {p} = Types.getTypeSource(tty);
        tty_1 = stripExtraArgsFromType(slots,tty);
        tty_1 = Types.makeFunctionPolymorphicReference(tty_1);
        ty = Types.simplifyType(tty_1);
        c = List.fold(consts,Types.constAnd,DAE.C_CONST());
        prop_1 = DAE.PROP(tty_1,c);
        (cache,Util.SUCCESS()) = instantiateDaeFunction(cache, env, p, false, NONE(), true);
      then
        (cache,DAE.PARTEVALFUNCTION(p,args,ty),prop_1,st);

    case(_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Static.elabPartEvalFunction failed");
      then
        fail();
  end matchcontinue;
end elabPartEvalFunction;

protected function stripExtraArgsFromType
  input list<Slot> slots;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(slots,inType)
    local
      DAE.Type resType;
      list<DAE.FuncArg> args;
      DAE.TypeSource ts;
      DAE.FunctionAttributes functionAttributes;


    case(_,DAE.T_FUNCTION(args,resType,functionAttributes,ts))
      equation
        args = stripExtraArgsFromType2(slots,args);
      then
        DAE.T_FUNCTION(args,resType,functionAttributes,ts);

    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"- Static.stripExtraArgsFromType failed");
      then
        fail();
  end matchcontinue;
end stripExtraArgsFromType;

protected function stripExtraArgsFromType2
  input list<Slot> slots;
  input list<DAE.FuncArg> inType;
  output list<DAE.FuncArg> outType;
algorithm
  outType := match(slots,inType)
    local
      list<Slot> slotsRest;
      list<DAE.FuncArg> rest;
      DAE.FuncArg arg;
    case ({},{}) then {};
    case (SLOT(slotFilled = true)::slotsRest,_::rest) then stripExtraArgsFromType2(slotsRest,rest);
    case (SLOT(slotFilled = false)::slotsRest,arg::rest)
      equation
        rest = stripExtraArgsFromType2(slotsRest,rest);
      then arg::rest;
  end match;
end stripExtraArgsFromType2;

protected function elabArray
"This function elaborates on array expressions.

  All types of an array should be equivalent. However, mixed Integer and Real
  elements are allowed in an array and in that case the Integer elements
  are converted to Real elements."
  input list<DAE.Exp> inExpl;
  input list<DAE.Properties> inProps;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output list<DAE.Exp> outExpLst;
  output DAE.Properties outProperties;
algorithm
  (outExpLst,outProperties):=
  matchcontinue (inExpl, inProps, inPrefix, inInfo)
    local
      list<DAE.Exp> expl;
      DAE.Properties prop;
      DAE.Type t;
      DAE.Const c;
      list<DAE.Type> types;

    // Empty array constructors are not allowed in Modelica.
    case ({}, _, _, _)
      equation
        Error.addSourceMessage(Error.EMPTY_ARRAY, {}, inInfo);
      then
        fail();

    // impl array contains mixed Integer and Real types
    case (_ :: _, _, _, _)
      equation
        t = elabArrayHasMixedIntReals(inProps);
        c = elabArrayConst(inProps);
        types = List.map(inProps, Types.getPropType);
        expl = elabArrayReal2(inExpl, types, t);
      then
        (expl, DAE.PROP(t, c));

    case (_ :: _, _, _, _)
      equation
        (expl, prop) = elabArray2(inExpl, inProps, inPrefix, inInfo);
      then
        (expl, prop);
  end matchcontinue;
end elabArray;

protected function elabArrayHasMixedIntReals
"Helper function to elab_array, checks if expression list contains both
  Integer and Real types."
  input list<DAE.Properties> props;
  output DAE.Type ty;
algorithm
  elabArrayHasInt(props);
  ty := elabArrayFirstPropsReal(props);
end elabArrayHasMixedIntReals;

protected function elabArrayHasInt
"author :PA
  Helper function to elabArray."
  input list<DAE.Properties> inProps;
algorithm
  _ := matchcontinue (inProps)
    local
      DAE.Type tp;
      list<DAE.Properties> props;

    case (DAE.PROP(tp,_) :: props)
      equation
        DAE.T_INTEGER(varLst = _) = Types.arrayElementType(tp);
      then
        ();

    case (_::props)
      equation
        elabArrayHasInt(props);
      then
        ();
  end matchcontinue;
end elabArrayHasInt;

protected function elabArrayFirstPropsReal
"author: PA
  Pick the first type among the list of
  properties which has elementype Real."
  input list<DAE.Properties> inTypesPropertiesLst;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inTypesPropertiesLst)
    local
      DAE.Type tp;
      list<DAE.Properties> rest;

    case ((DAE.PROP(type_ = tp) :: _))
      equation
        DAE.T_REAL(varLst = _) = Types.arrayElementType(tp);
      then
        tp;

    case ((_ :: rest))
      equation
        tp = elabArrayFirstPropsReal(rest);
      then
        tp;
  end matchcontinue;
end elabArrayFirstPropsReal;

protected function elabArrayConst
"Constructs a const value from a list of properties, using constAnd."
  input list<DAE.Properties> inTypesPropertiesLst;
  output DAE.Const outConst;
algorithm
  outConst:=
  matchcontinue (inTypesPropertiesLst)
    local
      DAE.Type tp;
      DAE.Const c,c2,c1;
      list<DAE.Properties> rest;

    case ({DAE.PROP(type_ = tp,constFlag = c)}) then c;

    case ((DAE.PROP(constFlag = c1) :: rest))
      equation
        c2 = elabArrayConst(rest);
        c = Types.constAnd(c2, c1);
      then
        c;

    case (_) equation Debug.fprint(Flags.FAILTRACE, "-elabArrayConst failed\n"); then fail();
  end matchcontinue;
end elabArrayConst;

protected function elabArrayReal2
"author: PA
  Applies type_convert to all expressions in a list to the type given
  as argument."
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Type> inTypesTypeLst;
  input DAE.Type inType;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst :=
  matchcontinue (inExpExpLst,inTypesTypeLst,inType)
    local
      DAE.Type t,to_type;
      list<DAE.Exp> res,es;
      DAE.Exp e,e_1;
      list<DAE.Type> ts;
    case ({},{},_) then {};  /* expl to_type new_expl res_type */
    case ((e :: es),(t :: ts),to_type) /* No need for type conversion. */
      equation
        true = Types.equivtypes(t, to_type);
        res = elabArrayReal2(es, ts, to_type);
      then
        (e :: res);
    case ((e :: es),(t :: ts),to_type) /* type conversion */
      equation
        (e_1,_) = Types.matchType(e, t, to_type, true);
        res = elabArrayReal2(es, ts, to_type);
      then
        (e_1 :: res);
  end matchcontinue;
end elabArrayReal2;

protected function elabArray2
"Helper function to elabArray, checks that all elements are equivalent."
  input list<DAE.Exp> es;
  input list<DAE.Properties> inProps;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outExpExpLst,outProperties):=
  matchcontinue (es,inProps,pre,info)
    local
      DAE.Exp e_1;
      DAE.Properties prop;
      DAE.Type t1,t2;
      DAE.Const c1,c2,c;
      list<DAE.Exp> es_1;
      String e_str,str,elt_str,t1_str,t2_str,sp;
      list<String> strs;
      list<DAE.Properties> props;

    case ({}, {}, _, _)
      then ({}, DAE.PROP(DAE.T_REAL_DEFAULT, DAE.C_CONST()));

    case ({e_1},{prop},_,_) then ({e_1},prop);

    case (e_1::es_1,DAE.PROP(t1,c1)::props,_,_)
      equation
        (es_1,DAE.PROP(t2,c2)) = elabArray2(es_1,props,pre,info);
        true = Types.equivtypes(t1, t2);
        c = Types.constAnd(c1, c2);
      then
        ((e_1 :: es_1),DAE.PROP(t1,c));

    case (e_1::es_1,DAE.PROP(t1,c1)::props,_,_)
      equation
        (es_1,DAE.PROP(t2,c2)) = elabArray2(es_1,props,pre,info);
        (e_1,t2) = Types.matchType(e_1, t1, t2, false);
        c = Types.constAnd(c1, c2);
      then
        ((e_1 :: es_1),DAE.PROP(t2,c));

    case (e_1::es_1,DAE.PROP(t1,c1)::props,_,_)
      equation
        (es_1,DAE.PROP(t2,c2)) = elabArray2(es_1,props,pre,info);
        false = Types.equivtypes(t1, t2);
        sp = PrefixUtil.printPrefixStr3(pre);
        e_str = ExpressionDump.printExpStr(e_1);
        strs = List.map(es, ExpressionDump.printExpStr);
        str = stringDelimitList(strs, ",");
        elt_str = stringAppendList({"[",str,"]"});
        t1_str = Types.unparseType(t1);
        t2_str = Types.unparseType(t2);
        Types.typeErrorSanityCheck(t1_str, t2_str, info);
        Error.addSourceMessage(Error.TYPE_MISMATCH_ARRAY_EXP, {sp,e_str,t1_str,elt_str,t2_str}, info);
      then
        fail();
  end matchcontinue;
end elabArray2;

protected function elabGraphicsArray
"This function elaborates array expressions for graphics elaboration."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExpExpLst,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inPrefix,info)
    local
      DAE.Exp e_1;
      DAE.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl;
      DAE.Type t1,t2;
      DAE.Const c1,c2,c;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es;
      Env.Cache cache;
      Prefix.Prefix pre;
      String envStr,str,preStr,expStr;
    case (cache,env,{e},impl,pre,_) /* impl */
      equation
        (cache,e_1,prop) = elabGraphicsExp(cache,env,e,impl,pre,info);
      then
        (cache,{e_1},prop);
    case (cache,env,(e :: es),impl,pre,_)
      equation
        (cache,e_1,DAE.PROP(t1,c1)) = elabGraphicsExp(cache,env, e, impl,pre,info);
        (cache,es_1,DAE.PROP(t2,c2)) = elabGraphicsArray(cache,env, es, impl,pre,info);
        c = Types.constAnd(c1, c2);
      then
        (cache,(e_1 :: es_1),DAE.PROP(t1,c));
    case (cache,env,{},impl,pre,_)
      equation
        envStr = Env.printEnvPathStr(env);
        preStr = PrefixUtil.printPrefixStr(pre);
        str = "Static.elabGraphicsArray failed on an empty modification with prefix: " +& preStr +& " in scope: " +& envStr;
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();
    case (cache,env,e::_,impl,pre,_)
      equation
        envStr = Env.printEnvPathStr(env);
        preStr = PrefixUtil.printPrefixStr(pre);
        expStr = Dump.printExpStr(e);
        str = "Static.elabGraphicsArray failed on expresion: " +& expStr +& " with prefix: " +& preStr +& " in scope: " +& envStr;
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();
  end matchcontinue;
end elabGraphicsArray;

protected function elabMatrixComma "This function is a helper function for elabMatrixSemi.
  It elaborates one matrix row of a matrix."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input list<DAE.Exp> es;
  input list<DAE.Properties> inProps;
  input Boolean inBoolean3;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp1;
  output DAE.Properties outProperties2;
  output DAE.Dimension outInteger3;
  output DAE.Dimension outInteger4;
algorithm
  (outCache,outExp1,outProperties2,outInteger3,outInteger4):=
  matchcontinue (inCache,inEnv1,es,inProps,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inBoolean5,inInteger6,performVectorization,inPrefix,info)
    local
      DAE.Exp el_1,el_2;
      DAE.Properties prop,prop1,prop1_1,prop2;
      DAE.Type t1,t1_1;
      Integer nmax;
      DAE.Dimension t1_dim1_1,t1_dim2_1,dim1,dim2,dim2_1;
      Boolean impl,havereal,a,doVect;
      DAE.Type at;
      list<Env.Frame> env;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Exp> els_1,els;
      Env.Cache cache;
      Prefix.Prefix pre;
      list<DAE.Properties> props;

    case (cache,env,{el_1},{prop as DAE.PROP(t1,_)},impl,st,havereal,nmax,doVect,pre,_) /* implicit inst. have real nmax dim1 dim2 */
      equation
        (el_2,(prop as DAE.PROP(t1_1,_))) = promoteExp(el_1, prop, nmax);
        (_,t1_dim1_1 :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        at = Types.simplifyType(t1_1);
        at = Expression.liftArrayLeft(at, DAE.DIM_INTEGER(1));
      then
        (cache,DAE.ARRAY(at,false,{el_2}),prop,t1_dim1_1,t1_dim2_1);
    case (cache,env,(el_1 :: els),(prop1 as DAE.PROP(t1,_))::props,impl,st,havereal,nmax,doVect,pre,_)
      equation
        (el_2,(prop1_1 as DAE.PROP(t1_1,_))) = promoteExp(el_1, prop1, nmax);
         (_,t1_dim1_1 :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        (cache,el_1 as DAE.ARRAY(at,a,els_1),prop2,dim1,dim2) = elabMatrixComma(cache,env, els, props, impl, st, havereal, nmax,doVect,pre,info);
        dim2_1 = Expression.dimensionsAdd(t1_dim2_1,dim2)"comma between matrices => concatenation along second dimension" ;
        prop = Types.matchWithPromote(prop1_1, prop2, havereal);
        el_1 = Expression.arrayAppend(el_2, el_1);
        //dim = listLength((el :: els));
        //at = Expression.liftArrayLeft(at, DAE.DIM_INTEGER(dim));
      then
        (cache, el_1, prop, dim1, dim2_1);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- Static.elabMatrixComma failed\n");
      then
        fail();
  end matchcontinue;
end elabMatrixComma;

protected function elabMatrixCatTwoExp "author: PA
  This function takes an array expression of dimension >=3 and
  concatenates each array element along the second dimension.
  For instance
  elab_matrix_cat_two( {{1,2;5,6}, {3,4;7,8}}) => {1,2,3,4;5,6,7,8}"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
    local
      DAE.Exp res;
      list<DAE.Exp> expl;
    case (DAE.ARRAY(array = expl))
      equation
        res = elabMatrixCatTwo(expl);
      then
        res;
    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE, "-elab_matrix_cat_one failed\n");
      then
        fail();
  end matchcontinue;
end elabMatrixCatTwoExp;

protected function elabMatrixCatTwo "author: PA
  Concatenates a list of matrix(or higher dim) expressions along
  the second dimension."
  input list<DAE.Exp> inExpExpLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExpExpLst)
    local
      DAE.Exp e,res,e1,e2;
      list<DAE.Exp> rest,expl;
      DAE.Type tp;
    case ({e}) then e;
    case ({e1,e2})
      equation
        res = elabMatrixCatTwo2(e1, e2);
      then
        res;
    case ((e1 :: rest))
      equation
        e2 = elabMatrixCatTwo(rest);
        res = elabMatrixCatTwo2(e1, e2);
      then
        res;
    case (expl)
      equation
        tp = Expression.typeof(List.first(expl));
        res = Expression.makeBuiltinCall("cat", DAE.ICONST(2) :: expl, tp);
      then res;
  end matchcontinue;
end elabMatrixCatTwo;

protected function elabMatrixCatTwo2 "Helper function to elabMatrixCatTwo
  Concatenates two array expressions that are matrices (or higher dimension)
  along the first dimension (row)."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
algorithm
  outExp:=
  match (inExp1,inExp2)
    local
      list<DAE.Exp> expl,expl1,expl2;
      DAE.Exp e;
      DAE.Type a1,a2, ty;
      Boolean at1,at2;
    case (DAE.ARRAY(ty = a1,scalar = at1,array = expl1),DAE.ARRAY(ty = a2,scalar = at2,array = expl2))
      equation
        e :: expl = elabMatrixCatTwo3(expl1, expl2);
        ty = Expression.typeof(e);
        ty = Expression.liftArrayLeft(ty, DAE.DIM_INTEGER(1));
      then
        DAE.ARRAY(ty,at1,e :: expl);
  end match;
end elabMatrixCatTwo2;

protected function elabMatrixCatTwo3 "Helper function to elabMatrixCatTwo2"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  match (inExpExpLst1,inExpExpLst2)
    local
      list<DAE.Exp> expl,es_1,expl1,es1,expl2,es2;
      DAE.Type a1,a2, ty;
      Boolean at1,at2;
    case ({},{}) then {};
    case ((DAE.ARRAY(ty = a1,scalar = at1,array = expl1) :: es1),
          (DAE.ARRAY(ty = a2,scalar = at2,array = expl2) :: es2))
      equation
        expl = listAppend(expl1, expl2);
        es_1 = elabMatrixCatTwo3(es1, es2);
        ty = Expression.concatArrayType(a1, a2);
      then
        (DAE.ARRAY(ty,at1,expl) :: es_1);
  end match;
end elabMatrixCatTwo3;

protected function elabMatrixCatOne "author: PA
  Concatenates a list of matrix(or higher dim) expressions along
  the first dimension.
  i.e. elabMatrixCatOne( { {1,2;3,4}, {5,6;7,8} }) => {1,2;3,4;5,6;7,8}"
  input list<DAE.Exp> inExpLst;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExpLst)
    local
      DAE.Exp res;
      DAE.Type ty;

    case _
      equation
        res = List.reduce(inExpLst, elabMatrixCatOne2);
      then
        res;
    else
      equation
        ty = Expression.typeof(List.first(inExpLst));
        res = Expression.makeBuiltinCall("cat", DAE.ICONST(1) :: inExpLst, ty);
      then
        res;
  end matchcontinue;
end elabMatrixCatOne;

protected function elabMatrixCatOne2
  "Helper function to elabMatrixCatOne. Concatenates two arrays along the
  first dimension."
  input DAE.Exp inArray1;
  input DAE.Exp inArray2;
  output DAE.Exp outExp;
protected
  DAE.Type ety;
  Boolean at;
  DAE.Dimension dim, dim1, dim2;
  DAE.Dimensions dim_rest;
  list<DAE.Exp> expl, expl1, expl2;
  DAE.TypeSource ts;
algorithm
  DAE.ARRAY(DAE.T_ARRAY(ety, dim1 :: dim_rest, ts), at, expl1) := inArray1;
  DAE.ARRAY(ty = DAE.T_ARRAY(dims = dim2 :: _), array = expl2) := inArray2;
  expl := listAppend(expl1, expl2);
  dim := Expression.dimensionsAdd(dim1, dim2);
  outExp := DAE.ARRAY(DAE.T_ARRAY(ety, dim :: dim_rest, ts), at, expl);
end elabMatrixCatOne2;

protected function promoteExp
  "Wrapper function for Expression.promoteExp which also handles Properties."
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input Integer inDims;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp, outProperties) := matchcontinue(inExp, inProperties, inDims)
    local
      DAE.Type ty;
      DAE.Const c;
      DAE.Exp exp;

    case (_, DAE.PROP(ty, c), _)
      equation
        (exp, ty) = Expression.promoteExp(inExp, ty, inDims);
      then
        (exp, DAE.PROP(ty, c));

    else
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Static.promoteExp failed");
      then
        fail();

  end matchcontinue;
end promoteExp;

protected function elabMatrixSemi
"This function elaborates Matrix expressions, e.g. {1,0;2,1}
  A row is elaborated with elabMatrixComma."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input list<list<DAE.Exp>> expss;
  input list<list<DAE.Properties>> inPropss;
  input Boolean inBoolean3;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp1;
  output DAE.Properties outProperties2;
  output DAE.Dimension outInteger3;
  output DAE.Dimension outInteger4;
algorithm
  (outCache,outExp1,outProperties2,outInteger3,outInteger4) :=
  matchcontinue (inCache,inEnv1,expss,inPropss,inBoolean3,inInteractiveInteractiveSymbolTableOption4,inBoolean5,inInteger6,performVectorization,inPrefix,info)
    local
      DAE.Exp exp,el_1,el_2;
      DAE.Properties prop,prop1,prop2;
      DAE.Type t1,t2;
      Integer maxn,dim;
      DAE.Dimension dim1,dim2,dim1_1,dim2_1,dim1_2;
      Boolean impl,havereal;
      list<Env.Frame> env;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Exp> els;
      list<list<DAE.Exp>> elss;
      String el_str,t1_str,t2_str,dim1_str,dim2_str,el_str1,pre_str;
      Env.Cache cache;
      Boolean doVect;
      Prefix.Prefix pre;
      list<DAE.Properties> props;
      list<list<DAE.Properties>> propss;

    case (cache,env,{els},{props},impl,st,havereal,maxn,doVect,pre,_) /* implicit inst. contain real maxn */
      equation
        (cache,exp,prop,dim1,dim2) = elabMatrixComma(cache,env, els, props, impl, st, havereal, maxn,doVect,pre,info);
        exp = elabMatrixCatTwoExp(exp);
      then
        (cache,exp,prop,dim1,dim2);
    case (cache,env,els::elss,props::propss,impl,st,havereal,maxn,doVect,pre,_)
      equation
        dim = listLength((els :: elss));
        (cache,el_1,prop1,dim1,dim2) = elabMatrixComma(cache,env, els, props, impl, st, havereal, maxn,doVect,pre,info);
        el_2 = elabMatrixCatTwoExp(el_1);
        (cache,el_1,prop2,dim1_1,dim2_1) = elabMatrixSemi(cache,env, elss, propss, impl, st, havereal, maxn,doVect,pre,info);
        exp = elabMatrixCatOne({el_2,el_1});
        true = Expression.dimensionsEqual(dim2,dim2_1) "semicoloned values a;b must have same no of columns" ;
        dim1_2 = Expression.dimensionsAdd(dim1, dim1_1) "number of rows added." ;
        prop = Types.matchWithPromote(prop1, prop2, havereal);
      then
        (cache,exp,prop,dim1_2,dim2);

    case (cache,env,els::elss,props::propss,impl,st,havereal,maxn,doVect,pre,_) /* Error messages */
      equation
        (cache,_,DAE.PROP(t1,_),_,_) = elabMatrixComma(cache,env, els, props, impl, st, havereal, maxn,doVect,pre,info);
        (cache,_,DAE.PROP(t2,_),_,_) = elabMatrixSemi(cache,env, elss, propss, impl, st, havereal, maxn,doVect,pre,info);
        failure(equality(t1 = t2));
        pre_str = PrefixUtil.printPrefixStr3(inPrefix);
        el_str = ExpressionDump.printListStr(els, ExpressionDump.printExpStr, ", ");
        t1_str = Types.unparseType(t1);
        t2_str = Types.unparseType(t2);
        Types.typeErrorSanityCheck(t1_str, t2_str, info);
        Error.addSourceMessage(Error.TYPE_MISMATCH_MATRIX_EXP, {pre_str,el_str,t1_str,t2_str}, info);
      then
        fail();
    case (cache,env,(els :: elss),props::propss,impl,st,havereal,maxn,doVect,pre,_)
      equation
        (cache,_,DAE.PROP(t1,_),dim1,_) = elabMatrixComma(cache,env, els, props, impl, st, havereal, maxn,doVect,pre,info);
        (cache,_,prop2,_,dim2) = elabMatrixSemi(cache,env, elss, propss, impl, st, havereal, maxn,doVect,pre,info);
        false = Expression.dimensionsEqual(dim1,dim2);
        dim1_str = ExpressionDump.dimensionString(dim1);
        dim2_str = ExpressionDump.dimensionString(dim2);
        pre_str = PrefixUtil.printPrefixStr3(inPrefix);
        el_str = ExpressionDump.printListStr(els, ExpressionDump.printExpStr, ", ");
        el_str1 = stringAppendList({"[",el_str,"]"});
        Error.addSourceMessage(Error.MATRIX_EXP_ROW_SIZE, {pre_str,el_str1,dim1_str,dim2_str},info);
      then
        fail();
  end matchcontinue;
end elabMatrixSemi;

protected function verifyBuiltInHandlerType "
 Author BZ, 2009-02
  This function validates that arguments to function are of a correct type.
  Then call elabCallArgs to vectorize/type-match."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean impl;
  input extraFunc typeChecker;
  input String fnName;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  partial function extraFunc
    input DAE.Type inp1;
    output Boolean outp1;
  end extraFunc;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,impl,typeChecker,fnName,inPrefix,info)
    local
      DAE.Type ty,ty2;
      Absyn.Exp s1;
      DAE.Exp s1_1;
      DAE.Const c;
      DAE.Properties prop;
      Prefix.Prefix pre;
      Env.Cache cache;
      Env.Env env;

    case (cache,env,{s1},_,_,_,pre,_) /* impl */
      equation
        (cache,_,DAE.PROP(ty,c),_) = elabExp(cache, env, s1, impl,NONE(),true,pre,info);
        // verify type here to see that input arguments are okay.
        ty2 = Types.arrayElementType(ty);
        true = typeChecker(ty2);
        (cache,s1_1,(prop as DAE.PROP(ty,c))) = elabCallArgs(cache,env, Absyn.FULLYQUALIFIED(Absyn.IDENT(fnName)), {s1}, {}, impl,NONE(),pre,info);
      then
        (cache,s1_1,prop);
  end match;
end verifyBuiltInHandlerType;

protected function elabBuiltinCardinality
"author: PA
  This function elaborates the cardinality operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.Type tp1;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;

    case (cache, env, {exp}, _, impl, pre, _)
      equation
        (cache, exp_1, DAE.PROP(tp1, _), _) =
          elabExp(cache, env, exp, impl, NONE(), true, pre, info);
        tp1 = Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, Types.getDimensions(tp1));
        exp_1 = Expression.makeBuiltinCall("cardinality", {exp_1}, tp1);
      then
        (cache, exp_1, DAE.PROP(tp1, DAE.C_CONST()));
  end match;
end elabBuiltinCardinality;

protected function elabBuiltinSmooth
"This function elaborates the smooth operator.
  smooth(p,expr) - If p>=0 smooth(p, expr) returns expr and states that expr is p times
  continuously differentiable, i.e.: expr is continuous in all real variables appearing in
  the expression and all partial derivatives with respect to all appearing real variables
  exist and are continuous up to order p.
  The only allowed types for expr in smooth are: real expressions, arrays of
  allowed expressions, and records containing only components of allowed
  expressions."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp p_1,expr_1,exp;
      DAE.Const c1,c;
      Boolean impl,b1,b2;
      DAE.Type tp,tp1;
      list<Env.Frame> env;
      Absyn.Exp p,expr;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      DAE.Type etp;
      String s1,a1,a2,sp;
      Integer pInt;
      Prefix.Prefix pre;

    case (cache,env,{Absyn.INTEGER(pInt),expr},_,impl,pre,_) // if p is 0 just return the expression!
      equation
        true = pInt == 0;
        (cache,expr_1,DAE.PROP(tp,c),_) = elabExp(cache,env, expr, impl,NONE(), true,pre,info);
        b1 = Types.isReal(tp);
        b2 = Types.isRecordWithOnlyReals(tp);
        true = Util.boolOrList({b1,b2});
        etp = Types.simplifyType(tp);
        exp = expr_1;
      then
        (cache,exp,DAE.PROP(tp,c));

    case (cache,env,{p,expr},_,impl,pre,_)
      equation
        (cache,p_1,DAE.PROP(tp1,c1),_) = elabExp(cache,env, p, impl,NONE(),true,pre,info);
        true = Types.isParameterOrConstant(c1);
        true = Types.isInteger(tp1);
        (cache,expr_1,DAE.PROP(tp,c),_) = elabExp(cache,env, expr, impl,NONE(),true,pre,info);
        b1 = Types.isReal(tp);
        b2 = Types.isRecordWithOnlyReals(tp);
        true = Util.boolOrList({b1,b2});
        etp = Types.simplifyType(tp);
        exp = Expression.makeBuiltinCall("smooth", {p_1, expr_1}, etp);
      then
        (cache,exp,DAE.PROP(tp,c));

    case (cache,env,{p,expr},_,impl,pre,_)
      equation
        (cache,p_1,DAE.PROP(tp1,c1),_) = elabExp(cache,env, p, impl,NONE(),true,pre,info);
        false = Types.isParameterOrConstant(c1) and Types.isInteger(tp1);
        a1 = Dump.printExpStr(p);
        a2 = Dump.printExpStr(expr);
        sp = PrefixUtil.printPrefixStr3(pre);
        s1 = "smooth(" +& a1 +& ", " +& a2 +&"), first argument must be a constant or parameter expression of type Integer";
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,{s1,sp},info);
      then
        fail();

    case (cache,env,{p,expr},_,impl,pre,_)
      equation
        (cache,p_1,DAE.PROP(_,c1),_) = elabExp(cache,env, p, impl,NONE(),true,pre,info);
        true = Types.isParameterOrConstant(c1);
        (cache,expr_1,DAE.PROP(tp,c),_) = elabExp(cache,env, expr, impl,NONE(),true,pre,info);
        b1 = Types.isReal(tp);
        b2 = Types.isRecordWithOnlyReals(tp);
        false = Util.boolOrList({b1,b2});
        a1 = Dump.printExpStr(p);
        a2 = Dump.printExpStr(expr);
        sp = PrefixUtil.printPrefixStr3(pre);
        s1 = "smooth("+&a1+& ", "+&a2 +&"), second argument must be a Real, array of Reals or record only containg Reals";
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,{s1,sp},info);
      then
        fail();

    case (cache,env,expl,_,impl,pre,_)
      equation
        failure(2 = listLength(expl));
        a1 = Dump.printExpLstStr(expl);
        sp = PrefixUtil.printPrefixStr3(pre);
        s1 = "expected smooth(p,expr), got smooth("+&a1+&")";
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS,{s1,sp},info);
      then fail();
  end matchcontinue;
end elabBuiltinSmooth;

protected function elabBuiltinSize
"This function elaborates the size operator.
  Input is the list of arguments to size as Absyn.Exp
  expressions and the environment, Env.Env."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp dimp,arraycrefe,exp;
      DAE.Type arrtp;
      DAE.Properties prop;
      Boolean impl;
      list<Env.Frame> env;
      Absyn.Exp arraycr,dim;
      Env.Cache cache;
      Prefix.Prefix pre;
      DAE.Type ety;
      DAE.Dimensions dims;

    case (cache, env, {arraycr, dim}, _, impl, pre, _)
      equation
        (cache, dimp, _, _) =
          elabExp(cache, env, dim, impl, NONE(), true, pre, info);
        (cache, arraycrefe, prop, _) =
          elabExp(cache, env, arraycr, impl, NONE(), false, pre, info);
        ety = Expression.typeof(arraycrefe);
        dims = Expression.arrayDimension(ety);
        // sent in the props of the arraycrefe as if the array is constant then the size(x, 1) is constant!
        // see Modelica.Media.Incompressible.Examples.Glycol47 and Modelica.Media.Incompressible.TableBased (hasDensity)
        (SOME(exp), SOME(prop)) =
          elabBuiltinSizeIndex(arraycrefe, prop, ety, dimp, dims, env, info);
      then
        (cache, exp, prop);

    case (cache, env, {arraycr}, _, impl, pre, _)
      equation
        (cache, arraycrefe, DAE.PROP(arrtp, _), _) =
          elabExp(cache, env, arraycr, impl, NONE(), false, pre, info);
        ety = Expression.typeof(arraycrefe);
        dims = Expression.arrayDimension(ety);
        (exp, prop) = elabBuiltinSizeNoIndex(arraycrefe, ety, dims, arrtp, info);
      then
        (cache, exp, prop);

  end match;
end elabBuiltinSize;

protected function elabBuiltinSizeNoIndex
  "Helper function to elabBuiltinSize. Elaborates the size(A) operator."
  input DAE.Exp inArrayExp;
  input DAE.Type inArrayExpType;
  input DAE.Dimensions inDimensions;
  input DAE.Type inArrayType;
  input Absyn.Info inInfo;
  output DAE.Exp outSizeExp;
  output DAE.Properties outProperties;
algorithm
  (outSizeExp, outProperties) :=
  matchcontinue(inArrayExp, inArrayExpType, inDimensions, inArrayType, inInfo)
    local
      list<DAE.Exp> dim_expl;
      Integer dim_int;
      DAE.Exp exp;
      DAE.Properties prop;
      Boolean b;
      DAE.Const cnst;
      DAE.Type ty;
      String exp_str, size_str;

    // size of a scalar is not allowed.
    case (_, _, {}, _, _)
      equation
        // Make sure that we have a proper type here. We might get DAE.T_UNKNOWN if
        // the size expression is part of a modifier, in which case we can't
        // determine if it's a scalar or array.
        false = Types.isUnknownType(inArrayExpType);
        exp_str = ExpressionDump.printExpStr(inArrayExp);
        size_str = "size(" +& exp_str +& ")";
        Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {size_str}, inInfo);
      then
        fail();

    // size(A) for an array A with known dimensions.
    // Returns an array of all dimensions of A.
    case (_, _, _ :: _, _, _)
      equation
        dim_expl = List.map(inDimensions, Expression.dimensionSizeExp);
        dim_int = listLength(dim_expl);
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim_int)}, DAE.emptyTypeSource);
        exp = DAE.ARRAY(ty, true, dim_expl);
        prop = DAE.PROP(ty, DAE.C_CONST());
      then
        (exp, prop);

    // If we couldn't evaluate the size expression or find any problems with it,
    // just generate a call to size and let the runtime sort it out.
    case (_, _, _ :: _, _, _)
      equation
        b = Types.dimensionsKnown(inArrayType);
        cnst = Types.boolConstSize(b);
        exp = DAE.SIZE(inArrayExp,NONE());
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()} , DAE.emptyTypeSource);
        prop = DAE.PROP(ty, cnst);
      then
        (exp, prop);

  end matchcontinue;
end elabBuiltinSizeNoIndex;

protected function elabBuiltinSizeIndex
  "Helper function to elabBuiltinSize. Elaborates the size(A, x) operator."
  input DAE.Exp inArrayExp;
  input DAE.Properties inArrayProp;
  input DAE.Type inArrayType;
  input DAE.Exp inIndexExp;
  input DAE.Dimensions inDimensions;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  output Option<DAE.Exp> outSizeExp;
  output Option<DAE.Properties> outProperties;
algorithm
  (outSizeExp, outProperties) :=
  matchcontinue(inArrayExp, inArrayProp, inArrayType, inIndexExp, inDimensions, inEnv, inInfo)
    local
      Integer dim_int, dim_count;
      DAE.Exp exp;
      DAE.Dimension dim;
      DAE.Properties prop;
      DAE.Const cnst;
      String exp_str, index_str, size_str, dim_str;

    // size of a scalar is not allowed.
    case (_, _, _, _, {}, _, _)
      equation
        // Make sure that we have a proper type here. We might get T_UNKNOWN if
        // the size expression is part of a modifier, in which case we can't
        // determine if it's a scalar or array.
        false = Types.isUnknownType(inArrayType);
        exp_str = ExpressionDump.printExpStr(inArrayExp);
        index_str = ExpressionDump.printExpStr(inIndexExp);
        size_str = "size(" +& exp_str +& ", " +& index_str +& ")";
        Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE_FIRST_ARRAY, {size_str}, inInfo);
      then
        (NONE(), NONE());

    // size(A, x) for an array A with known dimensions and constant x.
    // Returns the size of the x:th dimension.
    case (_, _, _, _, _, _, _)
      equation
        dim_int = Expression.expInt(inIndexExp);
        dim_count = listLength(inDimensions);
        true = (dim_int > 0 and dim_int <= dim_count);
        dim = listNth(inDimensions, dim_int - 1);
        exp = Expression.dimensionSizeExp(dim);
        prop = DAE.PROP(DAE.T_INTEGER_DEFAULT, DAE.C_CONST());
      then
        (SOME(exp), SOME(prop));

    // The index is out of bounds.
    case (_, _, _, _, _, _, _)
      equation
        false = Types.isUnknownType(inArrayType);
        dim_int = Expression.expInt(inIndexExp);
        dim_count = listLength(inDimensions);
        true = (dim_int <= 0 or dim_int > dim_count);
        index_str = intString(dim_int);
        exp_str = ExpressionDump.printExpStr(inArrayExp);
        dim_str = intString(dim_count);
        Error.addSourceMessage(Error.INVALID_SIZE_INDEX,
          {index_str, exp_str, dim_str}, inInfo);
      then
        (NONE(), NONE());

    // If we couldn't evaluate the size expression or find any problems with it,
    // just generate a call to size and let the runtime sort it out.
    case (_, _, _, _, _, _, _)
      equation
        exp = DAE.SIZE(inArrayExp, SOME(inIndexExp));
        cnst = DAE.C_PARAM(); // Types.getPropConst(inArrayProp);
        cnst = Util.if_(Env.inFunctionScope(inEnv), DAE.C_VAR(), cnst);
        prop = DAE.PROP(DAE.T_INTEGER_DEFAULT, cnst);
      then
        (SOME(exp), SOME(prop));

  end matchcontinue;
end elabBuiltinSizeIndex;

protected function elabBuiltinNDims
"@author Stefan Vorkoetter <svorkoetter@maplesoft.com>
 ndims(A) : Returns the number of dimensions k of array expression A, with k >= 0.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp arraycrefe,exp;
      DAE.Type arrtp;
      Boolean impl;
      list<Env.Frame> env;
      Absyn.Exp arraycr;
      Env.Cache cache;
      list<Absyn.Exp> expl;
      Integer nd;
      Prefix.Prefix pre;
      String sp;

    case (cache,env,{arraycr},_,impl,pre,_)
      equation
        (cache,arraycrefe,DAE.PROP(arrtp,_),_) = elabExp(cache,env, arraycr, impl,NONE(),true,pre,info);
        nd = Types.numberOfDimensions(arrtp);
        exp = DAE.ICONST(nd);
      then
        (cache,exp,DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()));

    case (cache,env,expl,_,impl,pre,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        sp = PrefixUtil.printPrefixStr3(pre);
        Debug.fprint(Flags.FAILTRACE, "- Static.elabBuiltinNdims failed for: ndims(" +& Dump.printExpLstStr(expl) +& " in component: " +& sp);
      then
        fail();
  end matchcontinue;
end elabBuiltinNDims;

protected function elabBuiltinFill "This function elaborates the builtin operator fill.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp s_1,exp;
      DAE.Properties prop;
      list<DAE.Exp> dims_1;
      list<DAE.Properties> dimprops;
      DAE.Type sty;
      list<Values.Value> dimvals;
      list<Env.Frame> env;
      Absyn.Exp s;
      list<Absyn.Exp> dims;
      Boolean impl;
      String implstr,expstr,str,sp;
      list<String> expstrs;
      Env.Cache cache;
      DAE.Const c1;
      Prefix.Prefix pre;
      DAE.Type exp_type;

    // try to constant evaluate dimensions
    case (cache,env,(s :: dims),_,impl,pre,_)
      equation
        (cache,s_1,prop,_) = elabExp(cache, env, s, impl,NONE(), true, pre, info);
        (cache,dims_1,dimprops,_) = elabExpList(cache, env, dims, impl, NONE(), true, pre, info);
        (dims_1,_) = Types.matchTypes(dims_1, List.map(dimprops,Types.getPropType), DAE.T_INTEGER_DEFAULT, false);
        c1 = Types.propertiesListToConst(dimprops);
        failure(DAE.C_VAR() = c1);
        c1 = Types.constAnd(c1,Types.propAllConst(prop));
        sty = Types.getPropType(prop);
        (cache,dimvals,_) = Ceval.cevalList(cache, env, dims_1, impl, NONE(), Absyn.NO_MSG(),0);
        (cache,exp,prop) = elabBuiltinFill2(cache, env, s_1, sty, dimvals, c1, pre, dims, info);
      then
        (cache, exp, prop);

    // If the previous case failed we probably couldn't constant evaluate the
    // dimensions. Create a function call to fill instead, and let the compiler sort it out later.
    case (cache, env, (s :: dims), _, impl, pre, _)
      equation
        c1 = unevaluatedFunctionVariability(env);
        (cache, s_1, prop, _) = elabExp(cache, env, s, impl,NONE(), true, pre, info);
        (cache, dims_1, dimprops, _) = elabExpList(cache, env, dims, impl, NONE(), true, pre, info);
        (dims_1,_) = Types.matchTypes(dims_1, List.map(dimprops,Types.getPropType), DAE.T_INTEGER_DEFAULT, false);
        sty = Types.getPropType(prop);
        sty = makeFillArgListType(sty, dimprops);
        exp_type = Types.simplifyType(sty);
        prop = DAE.PROP(sty, c1);
        exp = Expression.makeBuiltinCall("fill", s_1 :: dims_1, exp_type);
     then
       (cache, exp, prop);

    // Non-constant dimensons are also allowed in the case of non-expanded arrays
    // TODO: check that the diemnsions are parametric?
    case (cache, env, (s :: dims), _, impl, pre, _)
      equation
        false = Config.splitArrays();
        (cache, s_1, DAE.PROP(sty, c1), _) = elabExp(cache, env, s, impl,NONE(), true, pre, info);
        (cache, dims_1, dimprops, _) = elabExpList(cache, env, dims, impl,NONE(), true, pre, info);
        sty = makeFillArgListType(sty, dimprops);
        exp_type = Types.simplifyType(sty);
        c1 = Types.constAnd(c1, DAE.C_PARAM());
        prop = DAE.PROP(sty, c1);
        exp = Expression.makeBuiltinCall("fill", s_1 :: dims_1, exp_type);
     then
       (cache, exp, prop);

    case (cache,env,dims,_,impl,pre,_)
      equation
        str = "Static.elabBuiltinFill failed in component" +& PrefixUtil.printPrefixStr3(inPrefix) +&
              " and scope: " +& Env.printEnvPathStr(env) +& 
              " for expression: fill(" +& Dump.printExpLstStr(dims) +& ")";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    case (cache,env,dims,_,impl,pre,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE,
          "- Static.elabBuiltinFill: Couldn't elaborate fill(): ");
        implstr = boolString(impl);
        expstrs = List.map(dims, Dump.printExpStr);
        expstr = stringDelimitList(expstrs, ", ");
        sp = PrefixUtil.printPrefixStr3(pre);
        str = stringAppendList({expstr," impl=",implstr,", in component: ",sp});
        Debug.fprintln(Flags.FAILTRACE, str);
      then
        fail();
  end matchcontinue;
end elabBuiltinFill;

public function elabBuiltinFill2
"
  function: elabBuiltinFill2
  Helper function to: elabBuiltinFill

  Public since it is used by ExpressionSimplify.simplifyBuiltinCalls.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input list<Values.Value> inValuesValueLst;
  input DAE.Const constVar;
  input Prefix.Prefix inPrefix;
  input list<Absyn.Exp> inDims;
  input Absyn.Info inInfo;  
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inExp,inType,inValuesValueLst,constVar,inPrefix,inDims,inInfo)
    local
      list<DAE.Exp> arraylist;
      DAE.Type at;
      Boolean a;
      list<Env.Frame> env;
      DAE.Exp s,exp;
      DAE.Type sty,ty,sty2;
      Integer v;
      DAE.Const con;
      list<Values.Value> rest;
      Env.Cache cache;
      DAE.Const c1;
      Prefix.Prefix pre;
      String str;

    // we might get here negative integers!
    case (cache,env,s,sty,{Values.INTEGER(integer = v)},c1,_,_,_)
      equation
        true = intLt(v, 0); // fill with 0 then!
        v = 0;
        arraylist = List.fill(s, v);
        sty2 = DAE.T_ARRAY(sty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2, {});
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    case (cache,env,s,sty,{Values.INTEGER(integer = v)},c1,_,_,_)
      equation
        arraylist = List.fill(s, v);
        sty2 = DAE.T_ARRAY(sty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2, {});
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    case (cache,env,s,sty,(Values.INTEGER(integer = v) :: rest),c1,pre,_,_)
      equation
        (cache,exp,DAE.PROP(ty,con)) = elabBuiltinFill2(cache,env, s, sty, rest,c1,pre,inDims,inInfo);
        arraylist = List.fill(exp, v);
        sty2 = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2, {});
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));
        
    case (cache,env,s,sty,_,c1,_,_,_)
      equation
        str = "Static.elabBuiltinFill2 failed in component" +& PrefixUtil.printPrefixStr3(inPrefix) +&
              " and scope: " +& Env.printEnvPathStr(env) +& 
              " for expression: fill(" +& Dump.printExpLstStr(inDims) +& ")";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, inInfo);
      then
        fail();
  end matchcontinue;
end elabBuiltinFill2;

protected function makeFillArgListType
  "Helper function to elabBuiltinFill. Takes the type of the fill expression and
    the properties of the dimensions, and constructs the result type of the fill
    function."
  input DAE.Type fillType;
  input list<DAE.Properties> dimProps;
  output DAE.Type resType;
algorithm
  resType := match(fillType, dimProps)
    local
      DAE.Properties prop;
      list<DAE.Properties> rest_props;
      DAE.Type t;

    case (_, {}) then fillType;

    case (_, prop :: rest_props)
      equation
        t = makeFillArgListType(fillType, rest_props);
        t = DAE.T_ARRAY(t, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource);
      then
        t;
  end match;
end makeFillArgListType;

protected function elabBuiltinSymmetric "This function elaborates the builtin operator symmetric"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Type tp;
      Boolean  impl;
      DAE.Dimension d1,d2;
      DAE.Type eltp,newtp;
      DAE.Properties prop;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp matexp;
      DAE.Exp exp_1,exp;
      Env.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,{matexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(DAE.T_ARRAY(dims = {d1}, ty = DAE.T_ARRAY(dims = {d2}, ty = eltp)), c),_)
          = elabExp(cache,env, matexp, impl,NONE(),true,pre,info);
        newtp = DAE.T_ARRAY(DAE.T_ARRAY(eltp, {d1}, DAE.emptyTypeSource), {d2}, DAE.emptyTypeSource);
        tp = Types.simplifyType(newtp);
        exp = Expression.makeBuiltinCall("symmetric", {exp_1}, tp);
        prop = DAE.PROP(newtp,c);
      then
        (cache,exp,prop);
  end match;
end elabBuiltinSymmetric;

protected function elabBuiltinTranspose "This function elaborates the builtin operator transpose
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Type tp;
      Boolean sc, impl;
      list<DAE.Exp> expl,exp_2;
      DAE.Dimension d1,d2;
      DAE.Type eltp,newtp;
      Integer dim1,dim2,dimMax;
      DAE.Properties prop;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp matexp;
      DAE.Exp exp_1,exp;
      Env.Cache cache;
      Prefix.Prefix pre;
      list<list<DAE.Exp>> mexpl,mexp_2;
      Integer i;

    // try symbolically transpose the ARRAY expression
    case (cache,env,{matexp},_,impl,pre,_)
      equation
        (cache,DAE.ARRAY(tp,sc,expl),DAE.PROP(DAE.T_ARRAY(ty = DAE.T_ARRAY(ty = eltp, dims = {d2}), dims = {d1}), c),_)
          = elabExpInExpression(cache,env, matexp, impl,NONE(),true,pre,info);
        dim1 = Expression.dimensionSize(d1);
        exp_2 = elabBuiltinTranspose2(expl, 1, dim1);
        newtp = DAE.T_ARRAY(DAE.T_ARRAY(eltp, {d1}, DAE.emptyTypeSource), {d2}, DAE.emptyTypeSource);
        prop = DAE.PROP(newtp,c);
        tp = transposeExpType(tp);
      then
        (cache,DAE.ARRAY(tp,sc,exp_2),prop);

    // try symbolically transpose the MATRIX expression
    case (cache,env,{matexp},_,impl,pre,_)
      equation
        (cache,DAE.MATRIX(tp,i,mexpl),DAE.PROP(DAE.T_ARRAY(dims = {d1}, ty = DAE.T_ARRAY(dims = {d2}, ty = eltp)),c),_)
          = elabExpInExpression(cache,env, matexp, impl,NONE(),true,pre,info);
        dim1 = Expression.dimensionSize(d1);
        dim2 = Expression.dimensionSize(d2);
        dimMax = intMax(dim1, dim2);
        mexp_2 = elabBuiltinTranspose3(mexpl, 1, dimMax);
        newtp = DAE.T_ARRAY(DAE.T_ARRAY(eltp, {d1}, DAE.emptyTypeSource), {d2}, DAE.emptyTypeSource);
        prop = DAE.PROP(newtp,c);
        tp = transposeExpType(tp);
      then
        (cache,DAE.MATRIX(tp,i,mexp_2),prop);

    // .. otherwise create transpose call
    case (cache,env,{matexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(DAE.T_ARRAY(dims = {d1}, ty = DAE.T_ARRAY(dims = {d2}, ty = eltp)), c),_)
          = elabExpInExpression(cache,env, matexp, impl,NONE(),true,pre,info);
        newtp = DAE.T_ARRAY(DAE.T_ARRAY(eltp, {d1}, DAE.emptyTypeSource), {d2}, DAE.emptyTypeSource);
        tp = Types.simplifyType(newtp);
        exp = Expression.makeBuiltinCall("transpose", {exp_1}, tp);
        prop = DAE.PROP(newtp,c);
      then
        (cache,exp,prop);
  end matchcontinue;
end elabBuiltinTranspose;

protected function transposeExpType
  "Helper function to elabBuiltinTranspose. Transposes an array type, i.e. swaps
  the first two dimensions."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    local
      DAE.Type ty;
      DAE.Dimension dim1, dim2;
      DAE.Dimensions dim_rest;
      DAE.TypeSource ts;

    case (DAE.T_ARRAY(ty = ty, dims = dim1 :: dim2 :: dim_rest, source = ts))
      then
        DAE.T_ARRAY(ty, dim2 :: dim1 :: dim_rest, ts);
  end match;
end transposeExpType;

protected function elabBuiltinTranspose2 "author: PA
  Helper function to elab_builtin_transpose.
  Tries to symbolically transpose a matrix expression in ARRAY form."
  input list<DAE.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExpExpLst1,inInteger2,inInteger3)
    local
      DAE.Exp e;
      list<DAE.Exp> es,rest,elst;
      DAE.Type tp;
      Integer indx_1,indx,dim1;

    case (elst,indx,dim1)
      equation
        (indx <= dim1) = true;
        indx_1 = indx - 1;
        (e :: es) = List.map1(elst, Expression.nthArrayExp, indx_1);
        tp = Expression.typeof(e);
        indx_1 = indx + 1;
        rest = elabBuiltinTranspose2(elst, indx_1, dim1);
      then
        (DAE.ARRAY(tp,false,(e :: es)) :: rest);

    case (_,_,_) then {};
  end matchcontinue;
end elabBuiltinTranspose2;

protected function elabBuiltinTranspose3 "author: PA
  Helper function to elab_builtin_transpose. Tries to symbolically transpose
  a MATRIX expression list"
  input list<list<DAE.Exp>> inTplExpExpBooleanLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<list<DAE.Exp>> outTplExpExpBooleanLstLst;
algorithm
  outTplExpExpBooleanLstLst:=
  matchcontinue (inTplExpExpBooleanLstLst1,inInteger2,inInteger3)
    local
      Integer indx_1,indx,dim1;
      DAE.Exp e;
      list<DAE.Exp> es;
      DAE.Exp e_1;
      DAE.Type tp;
      list<list<DAE.Exp>> rest,res,elst;
    case (elst,indx,dim1)
      equation
        (indx <= dim1) = true;
        (e :: es) = List.map1(elst, listGet, indx);
        e_1 = e;
        tp = Expression.typeof(e_1);
        indx_1 = indx + 1;
        rest = elabBuiltinTranspose3(elst, indx_1, dim1);
        res = listAppend({(e :: es)}, rest);
      then
        res;
    case (_,_,_) then {};
  end matchcontinue;
end elabBuiltinTranspose3;

protected function elabBuiltinSum "This function elaborates the builtin operator sum.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1,exp_2;
      DAE.Type t,tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp arrexp;
      Boolean impl,b;
      Env.Cache cache;
      Prefix.Prefix pre;
      String estr,tstr;
      DAE.Type etp;

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(t,c),_) = elabExp(cache,env,arrexp, impl,NONE(),true,pre,info);
        tp = Types.arrayElementType(t);
        etp = Types.simplifyType(tp);
        b = Types.isArray(t,{});
        b = b and Types.isSimpleType(tp);
        estr = Dump.printExpStr(arrexp);
        tstr = Types.unparseType(t);
        Error.assertionOrAddSourceMessage(b,Error.SUM_EXPECTED_ARRAY,{estr,tstr},info);
        exp_2 = Expression.makeBuiltinCall("sum", {exp_1}, etp);
      then
        (cache,exp_2,DAE.PROP(tp,c));
  end match;
end elabBuiltinSum;

protected function elabBuiltinProduct "This function elaborates the builtin operator product.
  The input is the arguments to fill as Absyn.Exp expressions and the environment Env.Env"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1,exp_2;
      DAE.Dimension dim;
      DAE.Type t,tp;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp arrexp;
      Boolean impl;
      DAE.Type ty,ty2;
      Env.Cache cache;
      Prefix.Prefix pre;
      String str_exp,str_pre;
      DAE.Type etp;

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(ty,c),_) = elabExp(cache,env, arrexp, impl,NONE(),true,pre,info);
        (exp_1,ty2) = Types.matchType(exp_1, ty, DAE.T_INTEGER_DEFAULT, true);
        str_exp = "product(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre}, info);
      then
         (cache,exp_1,DAE.PROP(DAE.T_INTEGER_DEFAULT,c));

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(ty,c),_) = elabExp(cache,env, arrexp, impl,NONE(),true,pre,info);
        (exp_1,ty2) = Types.matchType(exp_1, ty, DAE.T_REAL_DEFAULT, true);
        str_exp = "product(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre}, info);
      then
         (cache,exp_1,DAE.PROP(DAE.T_REAL_DEFAULT,c));

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(t as DAE.T_ARRAY(dims = {dim}, ty = tp),c),_) = elabExp(cache,env, arrexp, impl,NONE(),true,pre,info);
        tp = Types.arrayElementType(t);
        etp = Types.simplifyType(tp);
        exp_2 = Expression.makeBuiltinCall("product", {exp_1}, etp);
        exp_2 = elabBuiltinProduct2(exp_2);
      then
        (cache,exp_2,DAE.PROP(tp,c));
  end matchcontinue;
end elabBuiltinProduct;

protected function elabBuiltinProduct2 " replaces product({a1,a2,...an})
with a1*a2*...*an} and
product([a11,a12,...,a1n;...,am1,am2,..amn]) with a11*a12*...*amn
"
input DAE.Exp inExp;
output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mexpl;

    case (DAE.CALL(expLst={DAE.ARRAY(array = expl)}))
      then Expression.makeProductLst(expl);

    case (DAE.CALL(expLst={DAE.MATRIX(matrix = mexpl)}))
      equation
        expl = List.flatten(mexpl);
      then Expression.makeProductLst(expl);

    else inExp;
  end matchcontinue;
end elabBuiltinProduct2;

protected function elabBuiltinPre "This function elaborates the builtin operator pre.
  Input is the arguments to the pre operator and the environment, Env.Env."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1,exp_2, call;
      DAE.Const c;
      list<Env.Frame> env;
      Absyn.Exp exp;
      DAE.Dimension dim;
      Boolean impl,sc;
      String s,el_str,pre_str;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      Prefix.Prefix pre;
      DAE.Type t,t2,tp;
      DAE.Type etp,etp_org;
      list<DAE.Exp> expl_1;

    /* an matrix? */
    case (cache,env,{exp},_,impl,pre,_) /* impl */
      equation
        (cache,exp_1 as DAE.MATRIX(matrix=_),
         DAE.PROP(t as DAE.T_ARRAY(dims = {dim}, ty = tp),c),_) = elabExp(cache, env, exp, impl,NONE(), true,pre,info);

        true = Types.isArray(tp,{});

        t2 = Types.unliftArray(tp);
        etp = Types.simplifyType(t2);

        call = Expression.makeBuiltinCall("pre", {exp_1}, etp);
        exp_2 = elabBuiltinPreMatrix(call, t2);
      then
        (cache,exp_2,DAE.PROP(t,c));

    // an array?
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(t as DAE.T_ARRAY(dims = {dim}, ty = tp),c),_) = elabExp(cache, env, exp, impl,NONE(),true,pre,info);

        true = Types.isArray(t,{});

        t2 = Types.unliftArray(t);
        etp = Types.simplifyType(t2);

        call = Expression.makeBuiltinCall("pre", {exp_1}, etp);
        (expl_1,sc) = elabBuiltinPre2(call, t2);

        etp_org = Types.simplifyType(t);
        exp_2 = DAE.ARRAY(etp_org,  sc,  expl_1);
      then
        (cache,exp_2,DAE.PROP(t,c));

    // a scalar?
    case (cache,env,{exp},_,impl,pre,_) /* impl */
      equation
        (cache,exp_1,DAE.PROP(tp,c),_) = elabExp(cache,env, exp, impl,NONE(),true,pre,info);
        (tp,_) = Types.flattenArrayType(tp);
        true = Types.basicType(tp);
        etp = Types.simplifyType(tp);
        exp_2 = Expression.makeBuiltinCall("pre", {exp_1}, etp);
      then
        (cache,exp_2,DAE.PROP(tp,c));

    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(tp,c),_) = elabExp(cache,env, exp, impl,NONE(),true,pre,info);
        (tp,_) = Types.flattenArrayType(tp);
        false = Types.basicType(tp);
        s = ExpressionDump.printExpStr(exp_1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.OPERAND_BUILTIN_TYPE, {"pre",pre_str,s}, info);
      then
        fail();

    case (cache,env,expl,_,_,pre,_)
      equation
        el_str = ExpressionDump.printListStr(expl, Dump.printExpStr, ", ");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        s = stringAppendList({"pre(",el_str,")"});
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,pre_str}, info);
      then
        fail();
  end matchcontinue;
end elabBuiltinPre;

protected function elabBuiltinPre2 "Help function for elabBuiltinPre, when type is array, send it here.
"
input DAE.Exp inExp;
input DAE.Type t;
output list<DAE.Exp> outExp;
output Boolean sc;
algorithm
  (outExp,sc) := matchcontinue(inExp,t)
    local
      DAE.Type ty;
      Integer i;
      list<DAE.Exp> expl,e;
      DAE.Exp exp_1;
      list<list<DAE.Exp>> matrixExpl, matrixExplPre;

    case(DAE.CALL(expLst = {DAE.ARRAY(ty,sc,expl)}),_)
      equation
        (e) = makePreLst(expl, t);
      then (e,sc);
    case(DAE.CALL(expLst = {DAE.MATRIX(ty,i,matrixExpl)}),_)
      equation
        matrixExplPre = List.map1(matrixExpl, makePreLst, t);
      then ({DAE.MATRIX(ty,i,matrixExplPre)},false);
    case (exp_1,_)
      equation
      then
        (exp_1 :: {},false);

  end matchcontinue;
end elabBuiltinPre2;

protected function elabBuiltinInStream "This function elaborates the builtin operator inStream.
  Input is the arguments to the inStream operator and the environment, Env.Env."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) :=
  match (inCache, inEnv, inArgs, inNamedArgs, inImpl, inPrefix, inInfo)
    local
      DAE.Exp exp_1, e;
      DAE.Type tp;
      DAE.Const c;
      Env.Env env;
      Absyn.Exp exp;
      Env.Cache cache;
      Absyn.Info info;
      DAE.Properties prop;

    // use elab_call_args to also try vectorized calls
    case (cache, env, {exp}, _, _, _, info)
      equation
        (_, exp_1, DAE.PROP(tp, c),_) = elabExp(cache, env, exp, inImpl, NONE(), true, inPrefix, info);
        true = Types.dimensionsKnown(tp);
        // check the stream prefix
        _ = elabBuiltinStreamOperator(cache, env, "inStream", exp_1, tp, inInfo);
        (cache, e, prop) = elabCallArgs(cache, env, Absyn.IDENT("inStream"), {exp}, {}, inImpl, NONE(), inPrefix, info);
      then
        (cache, e, prop);

    case (cache, env, {exp as Absyn.CREF(componentRef = _)}, _, _, _, _)
      equation
        (cache, exp_1, DAE.PROP(tp, c), _) = elabExp(cache, env, exp, inImpl, NONE(), true, inPrefix, inInfo);
        exp_1 = elabBuiltinStreamOperator(cache, env, "inStream", exp_1, tp, inInfo);
      then
        (cache, exp_1, DAE.PROP(tp, c));
  end match;
end elabBuiltinInStream;

protected function elabBuiltinActualStream "This function elaborates the builtin operator actualStream.
  Input is the arguments to the actualStream operator and the environment, Env.Env."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) :=
  match(inCache, inEnv, inArgs, inNamedArgs, inImpl, inPrefix, inInfo)
    local
      Absyn.Exp exp;
      DAE.Exp exp_1, e;
      DAE.Type tp;
      DAE.Const c;
      Env.Env env;
      Env.Cache cache;
      Absyn.Info info;
      DAE.Properties prop;

    // use elab_call_args to also try vectorized calls
    case (cache, env, {exp}, _, _, _, info)
      equation
        (_, exp_1, DAE.PROP(tp, c),_) = elabExp(cache, env, exp, inImpl, NONE(), true, inPrefix, info);
        true = Types.dimensionsKnown(tp);
        // check the stream prefix
        _ = elabBuiltinStreamOperator(cache, env, "actualStream", exp_1, tp, inInfo);
        (cache, e, prop) = elabCallArgs(cache, env, Absyn.IDENT("actualStream"), {exp}, {}, inImpl, NONE(), inPrefix, info);
      then
        (cache, e, prop);

    case (cache, env, {exp as Absyn.CREF(componentRef = _)}, _, _, _, _)
      equation
        (cache, exp_1, DAE.PROP(tp, c), _) = elabExp(cache, env, exp, inImpl, NONE(), true, inPrefix, inInfo);
        exp_1 = elabBuiltinStreamOperator(cache, env, "actualStream", exp_1, tp, inInfo);
      then
        (cache, exp_1, DAE.PROP(tp, c));
  end match;
end elabBuiltinActualStream;

protected function elabBuiltinStreamOperator
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inOperator;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Absyn.Info inInfo;
  output DAE.Exp outExp;
algorithm
  outExp := match(inCache, inEnv, inOperator, inExp, inType, inInfo)
    local
      DAE.Type et;
      DAE.Exp exp;

    case (_, _, _, DAE.ARRAY(array = {}), _, _)
      then inExp;

    else
      equation
        exp :: _ = Expression.flattenArrayExpToList(inExp);
        validateBuiltinStreamOperator(inCache, inEnv, exp, inType, inOperator, inInfo);
        et = Types.simplifyType(inType);
        exp = Expression.makeBuiltinCall(inOperator, {exp}, et);
      then
        exp;

  end match;
end elabBuiltinStreamOperator;

protected function validateBuiltinStreamOperator
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inOperand;
  input DAE.Type inType;
  input String inOperator;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inCache, inEnv, inOperand, inType, inOperator, inInfo)
    local
      DAE.ComponentRef cr;
      String op_str;
    // Operand is a stream variable, ok!
    case (_, _, DAE.CREF(componentRef = cr), _, _, _)
      equation
        (_, DAE.ATTR(connectorType = SCode.STREAM()), _, _, _, _, _, _, _) =
          Lookup.lookupVar(inCache, inEnv, cr);
      then
        ();
    // Operand is not a stream variable, error!
    else
      equation
        op_str = ExpressionDump.printExpStr(inOperand);
        Error.addSourceMessage(Error.NON_STREAM_OPERAND_IN_STREAM_OPERATOR,
          {op_str, inOperator}, inInfo);
      then
        fail();
  end matchcontinue;
end validateBuiltinStreamOperator;

protected function makePreLst
"Takes a list of expressions and makes a list of pre - expressions"
  input list<DAE.Exp> inExpLst;
  input DAE.Type t;
  output list<DAE.Exp> outExp;
algorithm
  (outExp):=
  match (inExpLst,t)
    local
      DAE.Exp exp_1,exp_2;
      list<DAE.Exp> expl_1,expl_2;
      DAE.Type ttt;

    case((exp_1 :: expl_1),_)
      equation
        ttt = Types.simplifyType(t);
        exp_2 = Expression.makeBuiltinCall("pre", {exp_1}, ttt);
        (expl_2) = makePreLst(expl_1,t);
      then
        ((exp_2 :: expl_2));

      case ({},_) then {};
  end match;
end makePreLst;

protected function elabBuiltinPreMatrix
" Help function for elabBuiltinPreMatrix, when type is matrix, send it here."
  input DAE.Exp inExp;
  input DAE.Type t;
  output DAE.Exp outExp;
algorithm
  (outExp) := matchcontinue(inExp,t)
    local
      DAE.Type ty;
      Integer i;
      DAE.Exp exp_1;
      list<list<DAE.Exp>> matrixExpl, matrixExplPre;

    case(DAE.CALL(expLst={DAE.MATRIX(ty,i,matrixExpl)}),_)
      equation
        matrixExplPre = List.map1(matrixExpl, makePreLst, t);
      then DAE.MATRIX(ty,i,matrixExplPre);

    case (exp_1,_) then exp_1;
  end matchcontinue;
end elabBuiltinPreMatrix;

protected function elabBuiltinArray "
  This function elaborates the builtin operator \'array\'. For instance,
  array(1,4,6) which is the same as {1,4,6}.
  Input is the list of arguments to the operator, as Absyn.Exp list.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      list<DAE.Exp> exp_1,exp_2;
      list<DAE.Properties> typel;
      DAE.Type tp,newtp;
      DAE.Const c;
      Integer len;
      DAE.Type newtp_1;
      Boolean scalar,impl;
      DAE.Exp exp;
      list<Env.Frame> env;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,expl,_,impl,pre,_)
      equation
        (cache,exp_1,typel,_) = elabExpList(cache,env, expl, impl,NONE(),true,pre,info);
        (exp_2,DAE.PROP(tp,c)) = elabBuiltinArray2(exp_1, typel,pre,info);
        len = listLength(expl);
        newtp = DAE.T_ARRAY(tp, {DAE.DIM_INTEGER(len)}, DAE.emptyTypeSource);
        newtp_1 = Types.simplifyType(newtp);
        scalar = Types.isArray(tp, {});
        exp = DAE.ARRAY(newtp_1,scalar,exp_1);
      then
        (cache,exp,DAE.PROP(newtp,c));
  end match;
end elabBuiltinArray;

protected function elabBuiltinArray2 "function elabBuiltinArray2.
  Helper function to elabBuiltinArray.
  Asserts that all types are of same dimensionality and of same builtin types."
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outExpExpLst,outProperties):=
  matchcontinue (inExpExpLst,inTypesPropertiesLst,inPrefix,info)
    local
      list<DAE.Exp> expl,expl_1;
      list<DAE.Properties> tpl;
      list<DAE.Type> tpl_1;
      DAE.Properties tp;
      Prefix.Prefix pre;
      String sp;
    case (expl,tpl,pre,_)
      equation
        false = sameDimensions(tpl);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS, {"array",sp}, info);
      then
        fail();
    case (expl,tpl,_,_)
      equation
        tpl_1 = List.map(tpl, Types.getPropType) "If first elt is Integer but arguments contain Real, convert all to Real" ;
        true = Types.containReal(tpl_1);
        (expl_1,tp) = elabBuiltinArray3(expl, tpl,
          DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_VAR()));
      then
        (expl_1,tp);
    case (expl,(tpl as (tp :: _)),_,_)
      equation
        (expl_1,tp) = elabBuiltinArray3(expl, tpl, tp);
      then
        (expl_1,tp);
  end matchcontinue;
end elabBuiltinArray2;

protected function elabBuiltinArray3 "
  Helper function to elab_builtin_array.
"
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  input DAE.Properties inProperties;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outExpExpLst,outProperties):=
  match (inExpExpLst,inTypesPropertiesLst,inProperties)
    local
      DAE.Properties tp,t1;
      DAE.Exp e1_1,e1;
      list<DAE.Exp> expl_1,expl;
      list<DAE.Properties> tpl;
    case ({},{},tp) then ({},tp);
    case ((e1 :: expl),(t1 :: tpl),tp)
      equation
        (e1_1,_) = Types.matchProp(e1, t1, tp, true);
        (expl_1,_) = elabBuiltinArray3(expl, tpl, tp);
      then
        ((e1_1 :: expl_1),t1);
  end match;
end elabBuiltinArray3;

protected function elabBuiltinZeros "This function elaborates the builtin operator zeros(n)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp e;
      DAE.Properties p;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,args,_,impl,pre,_)
      equation
        (cache,e,p) = elabBuiltinFill(cache, env, (Absyn.INTEGER(0) :: args), {}, impl, pre, info);
      then
        (cache,e,p);
  end match;
end elabBuiltinZeros;

protected function sameDimensions
  "This function returns true if all properties, containing types, have the same
  dimensions, otherwise false."
  input list<DAE.Properties> inProps;
  output Boolean res;
protected
  list<DAE.Type> types;
  list<DAE.Dimensions> dims;
algorithm
  types := List.map(inProps, Types.getPropType);
  dims := List.map(types, Types.getDimensions);
  res := sameDimensions2(dims);
end sameDimensions;

protected function sameDimensionsExceptionDimX
  "This function returns true if all properties, containing types, have the same
  dimensions (except for dimension X), otherwise false."
  input list<DAE.Properties> inProps;
  input Integer dimException;
  output Boolean res;
protected
  list<DAE.Type> types;
  list<DAE.Dimensions> dims;
algorithm
  types := List.map(inProps, Types.getPropType);
  dims := List.map(types, Types.getDimensions);
  dims := List.map1(dims, listDelete, dimException - 1);
  res := sameDimensions2(dims);
end sameDimensionsExceptionDimX;

protected function sameDimensions2
  input list<DAE.Dimensions> inDimensions;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDimensions)
    local
      list<DAE.Dimensions> rest_dims;
      DAE.Dimensions dims;
    case _
      equation
        {} = List.flatten(inDimensions);
      then
        true;
    case _
      equation
        dims = List.map(inDimensions, List.first);
        rest_dims = List.map(inDimensions, List.rest);
        true = sameDimensions3(dims);
        true = sameDimensions2(rest_dims);
      then
        true;
    else then false;
  end matchcontinue;
end sameDimensions2;

protected function sameDimensions3
  "Helper function to sameDimensions2. Check that all dimensions in a list are equal."
  input DAE.Dimensions inDims;
  output Boolean outRes;
algorithm
  outRes := matchcontinue (inDims)
    local
      DAE.Dimension dim1, dim2;
      Boolean res,res2,res_1;
      DAE.Dimensions rest;
    case ({}) then true;
    case ({_}) then true;
    case ({dim1, dim2}) then Expression.dimensionsEqual(dim1, dim2);
    case ((dim1 :: (dim2 :: rest)))
      equation
        res = sameDimensions3((dim2 :: rest));
        res2 = Expression.dimensionsEqual(dim1, dim2);
        res_1 = boolAnd(res, res2);
      then
        res_1;
    case (_) then false;
  end matchcontinue;
end sameDimensions3;

protected function elabBuiltinOnes "This function elaborates on the builtin opeator ones(n)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp e;
      DAE.Properties p;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
    case (cache,env,args,_,impl,pre,_)
      equation
        (cache,e,p) = elabBuiltinFill(cache,env, (Absyn.INTEGER(1) :: args), {}, impl,pre,info);
      then
        (cache,e,p);
  end match;
end elabBuiltinOnes;

protected function elabBuiltinMax
  "This function elaborates on the builtin operator max(a, b)."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inFnArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
 (outCache, outExp, outProperties) :=
    elabBuiltinMinMaxCommon(inCache, inEnv, "max", inFnArgs, inImpl, inPrefix, info);
end elabBuiltinMax;

protected function elabBuiltinMin
  "This function elaborates the builtin operator min(a, b)"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inFnArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) :=
    elabBuiltinMinMaxCommon(inCache, inEnv, "min", inFnArgs, inImpl, inPrefix, info);
end elabBuiltinMin;

protected function elabBuiltinMinMaxCommon
  "Helper function to elabBuiltinMin and elabBuiltinMax, containing common
  functionality."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input String inFnName;
  input list<Absyn.Exp> inFnArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties):=
  matchcontinue (inCache, inEnv, inFnName, inFnArgs, inImpl, inPrefix, info)
    local
      DAE.Exp arrexp_1,s1_1,s2_1, call;
      DAE.Type tp;
      DAE.Type ty,ty1,ty2,elt_ty;
      DAE.Const c,c1,c2;
      list<Env.Frame> env;
      Absyn.Exp arrexp,s1,s2;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties p;

    // min|max(vector)
    case (cache, env, _, {arrexp}, impl, pre, _)
      equation
        (cache, arrexp_1, DAE.PROP(ty, c), _) =
          elabExp(cache, env, arrexp, impl,NONE(), true, pre, info);
        true = Types.isArray(ty,{});
        elt_ty = Types.arrayElementType(ty);
        tp = Types.simplifyType(elt_ty);
        false = Types.isString(tp);
        call = Expression.makeBuiltinCall(inFnName, {arrexp_1}, tp);
      then
        (cache, call, DAE.PROP(elt_ty,c));

    // min|max(function returning multiple values)
    // This may or may not be valid Modelica, but it's used in
    // Modelica.Math.Matrices.norm.
    case (cache, env, _, {arrexp}, impl, pre, _)
      equation
        (cache, arrexp_1 as DAE.CALL(path = _),
         p as DAE.PROP_TUPLE(type_ = _), _) =
          elabExp(cache, env, arrexp, impl,NONE(), true, pre, info);

        // Use the first of the returned values from the function.
        DAE.PROP(ty, c) :: _ = Types.propTuplePropList(p);
        true = Types.isArray(ty,{});
        tp = Types.simplifyType(ty);
        arrexp_1 = DAE.TSUB(arrexp_1, 1, tp);
        elt_ty = Types.arrayElementType(ty);
        tp = Types.simplifyType(elt_ty);
        false = Types.isString(tp);
        call = Expression.makeBuiltinCall(inFnName, {arrexp_1}, tp);
      then
        (cache, call, DAE.PROP(elt_ty,c));

    // min|max(x,y) where x & y are scalars.
    case (cache, env, _, {s1, s2}, impl, pre, _)
      equation
        (cache, s1_1, DAE.PROP(ty1, c1), _) =
          elabExp(cache, env, s1, impl,NONE(), true, pre, info);
        (cache, s2_1, DAE.PROP(ty2, c2), _) =
          elabExp(cache, env, s2, impl,NONE(), true, pre, info);

        ty = Types.scalarSuperType(ty1,ty2);
        (s1_1,_) = Types.matchType(s1_1, ty1, ty, true);
        (s2_1,_) = Types.matchType(s2_1, ty2, ty, true);
        c = Types.constAnd(c1, c2);
        tp = Types.simplifyType(ty);
        false = Types.isString(tp);
        call = Expression.makeBuiltinCall(inFnName, {s1_1, s2_1}, tp);
      then
        (cache, call, DAE.PROP(ty,c));

  end matchcontinue;
end elabBuiltinMinMaxCommon;

protected function elabBuiltinDelay "
Author BZ
TODO: implement,
fix types, so we can have integer as input
verify that the input is correct."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      Env.Env env;
      Env.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;
      Integer i;

    case (cache,env,_,_,impl,pre,_)
      equation
        i = listLength(args);
        ty1 = DAE.T_FUNCTION(
                {("expr",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
                 ("delayTime",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),NONE())},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN,
                DAE.emptyTypeSource);
        ty2 = DAE.T_FUNCTION(
                {("expr",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
                 ("delayTime",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
                 ("delayMax",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),NONE())},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN,
                DAE.emptyTypeSource);
        ty = Util.if_(i==2,ty1,ty2);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("delay"), args, nargs, impl, NONE(), pre, info);
        ((call,_)) = Expression.traverseExp(call,elabBuiltinDelay2,1);
      then (cache, call, prop);
  end match;
end elabBuiltinDelay;

protected function elabBuiltinDelay2
  "Duplicate the 2nd argument of delay for no good reason"
  input tuple<DAE.Exp,Integer> exp;
  output tuple<DAE.Exp,Integer> oexp;
algorithm
  oexp := match exp
    local
      Absyn.Path path;
      DAE.Exp e1,e2;
      DAE.CallAttributes attr;
    case ((DAE.CALL(path as Absyn.IDENT("delay"), {e1,e2}, attr),_)) then ((DAE.CALL(path, {e1,e2,e2}, attr),1)); // stupid, eh?
    else exp;
  end match;
end elabBuiltinDelay2;

protected function elabBuiltinBoolean
"This function elaborates on the builtin operator boolean, which extracts
  the boolean value of a Real, Integer or Boolean value."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp s1_1;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      DAE.Properties prop;
      Prefix.Prefix pre;
    case (cache,env,{s1},_,impl,pre,_)
      equation
        (cache,s1_1,prop) =
          verifyBuiltInHandlerType(
             cache,
             env,
             {s1},
             impl,
             Types.isIntegerOrRealOrBooleanOrSubTypeOfEither,
             "boolean",pre,info);
      then
        (cache,s1_1,prop);
  end match;
end elabBuiltinBoolean;

protected function elabBuiltinIntegerEnum
"This function elaborates on the builtin operator Integer for Enumerations, which extracts
  the Integer value of a Enumeration element."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp s1_1;
      list<Env.Frame> env;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      DAE.Properties prop;
      Prefix.Prefix pre;
    case (cache,env,{s1},_,impl,pre,_)
      equation
        (cache,s1_1,prop) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isEnumeration,"Integer",pre,info);
      then
        (cache,s1_1,prop);
  end matchcontinue;
end elabBuiltinIntegerEnum;

protected function elabBuiltinDiagonal "This function elaborates on the builtin operator diagonal, creating a
  matrix with a value of the diagonal. The other elements are zero."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Type tp;
      Boolean impl;
      list<DAE.Exp> expl;
      DAE.Dimension dim;
      DAE.Type arrType,ty;
      DAE.Const c;
      DAE.Exp res,s1_1;
      list<Env.Frame> env;
      Absyn.Exp v1,s1;
      Env.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,{v1},_,impl,pre,_)
      equation
        (cache, DAE.ARRAY(ty = tp, array = expl),
         DAE.PROP(DAE.T_ARRAY(dims = {dim}, ty = arrType, source = _/*{}*/),c),
         _) = elabExp(cache,env, v1, impl,NONE(),true,pre,info);
        true = Expression.dimensionKnown(dim);
        ty = DAE.T_ARRAY(DAE.T_ARRAY(arrType, {dim}, DAE.emptyTypeSource), {dim}, DAE.emptyTypeSource);
        tp = Types.simplifyType(ty);
        res = elabBuiltinDiagonal2(expl,tp);
      then
        (cache,res,DAE.PROP(ty,c));

    case (cache,env,{s1},_,impl,pre,_)
      equation
        (cache,s1_1,
          DAE.PROP(DAE.T_ARRAY(dims = {dim}, ty = arrType, source = _/*{}*/),c),
         _) = elabExp(cache,env, s1, impl,NONE(),true, pre,info);
        true = Expression.dimensionKnown(dim);
        ty = DAE.T_ARRAY(DAE.T_ARRAY(arrType, {dim}, DAE.emptyTypeSource), {dim}, DAE.emptyTypeSource);
        tp = Types.simplifyType(ty);
        res = Expression.makeBuiltinCall("diagonal", {s1_1}, tp);
      then
        (cache, res, DAE.PROP(ty,c));

    case (_,_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabBuiltinDiagonal: Couldn't elaborate diagonal()");
      then
        fail();
  end matchcontinue;
end elabBuiltinDiagonal;

protected function elabBuiltinDiagonal2 "author: PA
  Tries to symbolically simplify diagonal.
  For instance diagonal({a,b}) => {a,0;0,b}"
  input list<DAE.Exp> expl;
  input DAE.Type  inType;
  output DAE.Exp res;
protected
  Integer dim;
algorithm
  dim := listLength(expl);
  res := elabBuiltinDiagonal3(expl, 0, dim, inType);
end elabBuiltinDiagonal2;

protected function elabBuiltinDiagonal3
  input list<DAE.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input DAE.Type  inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExpExpLst1,inInteger2,inInteger3,inType)
    local
      DAE.Type tp,ty;
      list<DAE.Exp> expl,expl_1,es;
      DAE.Exp e;
      Integer indx,dim,indx_1,mdim;
      list<list<DAE.Exp>> rows;

    case ({e},indx,dim,ty)
      equation
        tp = Expression.typeof(e);
        expl = List.fill(Expression.makeConstZero(tp), dim);
        expl_1 = List.replaceAt(e, indx, expl);
      then
        DAE.MATRIX(ty,dim,{expl_1});

    case ((e :: es),indx,dim,ty)
      equation
        indx_1 = indx + 1;
        DAE.MATRIX(tp,mdim,rows) = elabBuiltinDiagonal3(es, indx_1, dim, ty);
        expl = List.fill(Expression.makeConstZero(tp), dim);
        expl_1 = List.replaceAt(e, indx, expl);
      then
        DAE.MATRIX(ty,mdim,(expl_1 :: rows));
  end matchcontinue;
end elabBuiltinDiagonal3;

protected function elabBuiltinDifferentiate "This function elaborates on the builtin operator differentiate, by deriving the Exp"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      list<Absyn.ComponentRef> cref_list1,cref_list2,cref_list;
      GlobalScript.SymbolTable symbol_table;
      list<Env.Frame> gen_env,env;
      DAE.Exp s1_1,s2_1,call;
      DAE.Properties st;
      Absyn.Exp s1,s2;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,{s1,s2},_,impl,pre,_)
      equation
        cref_list1 = Absyn.getCrefFromExp(s1,true,false);
        cref_list2 = Absyn.getCrefFromExp(s2,true,false);
        cref_list = listAppend(cref_list1, cref_list2);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, GlobalScript.emptySymboltable,
          DAE.T_REAL_DEFAULT);
        (gen_env,_) = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExp(cache,gen_env, s1, impl,NONE(),true,pre,info);
        (cache,s2_1,st,_) = elabExp(cache,gen_env, s2, impl,NONE(),true,pre,info);
        call = Expression.makeBuiltinCall("differentiate", {s1_1, s2_1}, DAE.T_REAL_DEFAULT);
      then
        (cache, call, st);

    // failure
    case (_,_,_,_,_,_,_)
      equation
        print("#-- elabBuiltinDifferentiate: Couldn't elaborate differentiate()\n");
      then
        fail();
  end matchcontinue;
end elabBuiltinDifferentiate;

protected function elabBuiltinSimplify "This function elaborates the simplify function.
  The call in mosh is: simplify(x+yx-x,\"Real\") if the variable should be
  Real or simplify(x+yx-x,\"Integer\") if the variable should be Integer
  This function is only for testing ExpressionSimplify.simplify"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      list<Absyn.ComponentRef> cref_list;
      GlobalScript.SymbolTable symbol_table;
      list<Env.Frame> gen_env,env;
      DAE.Exp s1_1;
      DAE.Properties st;
      Absyn.Exp s1;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
    case (cache,env,{s1,Absyn.STRING(value = "Real")},_,impl,pre,_) /* impl */
      equation
        cref_list = Absyn.getCrefFromExp(s1,true,false);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, GlobalScript.emptySymboltable,
          DAE.T_REAL_DEFAULT);
        (gen_env,_) = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExp(cache,gen_env, s1, impl,NONE(),true,pre,info);
        s1_1 = Expression.makeBuiltinCall("simplify", {s1_1}, DAE.T_REAL_DEFAULT);
      then
        (cache, s1_1, st);
    case (cache,env,{s1,Absyn.STRING(value = "Integer")},_,impl,pre,_)
      equation
        cref_list = Absyn.getCrefFromExp(s1,true,false);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, GlobalScript.emptySymboltable,
          DAE.T_INTEGER_DEFAULT);
        (gen_env,_) = Interactive.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExp(cache,gen_env, s1, impl,NONE(),true,pre,info);
        s1_1 = Expression.makeBuiltinCall("simplify", {s1_1}, DAE.T_INTEGER_DEFAULT);
      then
        (cache, s1_1, st);
    case (_,_,_,_,_,_,_)
      equation
        // print("#-- elab_builtin_simplify: Couldn't elaborate simplify()\n");
      then
        fail();
  end match;
end elabBuiltinSimplify;

protected function absynCrefListToInteractiveVarList "
  Creates Interactive variables from the list of component references. Each
  variable will get a value that is the AST code for the variable itself.
  This is used when calling differentiate, etc., to be able to evaluate
  a variable and still get the variable name.
"
  input list<Absyn.ComponentRef> inAbsynComponentRefLst;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input DAE.Type inType;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable:=
  matchcontinue (inAbsynComponentRefLst,inInteractiveSymbolTable,inType)
    local
      GlobalScript.SymbolTable symbol_table,symbol_table_1,symbol_table_2;
      Absyn.Path path;
      String path_str;
      Absyn.ComponentRef cr;
      list<Absyn.ComponentRef> rest;
      DAE.Type tp;
    case ({},symbol_table,_) then symbol_table;
    case ((cr :: rest),symbol_table,tp)
      equation
        path = Absyn.crefToPath(cr);
        path_str = Absyn.pathString(path);
        symbol_table_1 = Interactive.addVarToSymboltable(
          DAE.CREF_IDENT(path_str, tp, {}),
          Values.CODE(Absyn.C_VARIABLENAME(cr)), Env.emptyEnv, symbol_table);
        symbol_table_2 = absynCrefListToInteractiveVarList(rest, symbol_table_1, tp);
      then
        symbol_table_2;
    case (_,_,_)
      equation
        Debug.fprint(Flags.FAILTRACE,
          "-absyn_cref_list_to_interactive_var_list failed\n");
      then
        fail();
  end matchcontinue;
end absynCrefListToInteractiveVarList;

protected function elabBuiltinNoevent "
  The builtin operator noevent makes sure that events are not generated
  for the expression.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,exp_1,prop,_) = elabExp(cache,env, exp, impl,NONE(),true,pre,info);
        exp_1 = Expression.makeBuiltinCall("noEvent", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_1, prop);
  end match;
end elabBuiltinNoevent;

protected function elabBuiltinEdge "
  This function handles the built in edge operator. If the operand is
  constant edge is always false.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1,exp_2;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      DAE.Const c;
      Env.Cache cache;
      Prefix.Prefix pre;
      String ps;
    case (cache,env,{exp},_,impl,pre,_) /* Constness: C_VAR */
      equation
        (cache,exp_1,DAE.PROP(DAE.T_BOOL(varLst = _),DAE.C_VAR()),_) = elabExp(cache, env, exp, impl,NONE(),true,pre,info);
        exp_2 = Expression.makeBuiltinCall("edge", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_2, DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()));

    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(DAE.T_BOOL(varLst = _),c),_) = elabExp(cache, env, exp, impl,NONE(),true,pre,info);
        exp_2 = ValuesUtil.valueExp(Values.BOOL(false));
      then
        (cache,exp_2,DAE.PROP(DAE.T_BOOL_DEFAULT,c));
    case (_,env,_,_,_,pre,_)
      equation
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {"edge",ps}, info);
      then
        fail();
  end matchcontinue;
end elabBuiltinEdge;

protected function elabBuiltinDer
"This function handles the built in der operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp e,ee1;
      DAE.Properties prop;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      DAE.Const c;
      list<String> lst;
      String s,sp,es3;
      list<Absyn.Exp> expl;
      Env.Cache cache;
      Prefix.Prefix pre;
      DAE.Type ety,ty,elem_ty;
      DAE.Dimensions dims;
      DAE.Type expty;

    // Replace der of constant Real, Integer or array of Real/Integer by zero(s)
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (_,_,DAE.PROP(ety,c),_) = elabExp(cache, env, exp, impl,NONE(),false,pre,info);
        failure(equality(c=DAE.C_VAR()));
        dims = Types.getRealOrIntegerDimensions(ety);
        (e,ty) = Expression.makeZeroExpression(dims);
      then
        (cache,e,DAE.PROP(ty,DAE.C_CONST()));

    // use elab_call_args to also try vectorized calls
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (_,ee1,DAE.PROP(ety,c),_) = elabExp(cache, env, exp, impl,NONE(),true,pre,info);
        true = Types.dimensionsKnown(ety);
        ety = Types.arrayElementType(ety);
        true = Types.isRealOrSubTypeReal(ety);
        (cache,e,(prop as DAE.PROP(ty,_))) = elabCallArgs(cache,env, Absyn.IDENT("der"), {exp}, {}, impl,NONE(),pre,info);
      then
        (cache,e,prop);

    case (cache, env, {exp}, _, impl, pre,_)
      equation
        (cache, e, DAE.PROP(ety, c), _) = elabExp(cache, env, exp, impl,NONE(), false, pre, info);
        elem_ty = Types.arrayElementType(ety);
        true = Types.isRealOrSubTypeReal(elem_ty);
        expty = Types.simplifyType(ety);
        e = Expression.makeBuiltinCall("der", {e}, expty);
      then
        (cache, e, DAE.PROP(ety, c));

    case (cache,env,{exp},_,impl,pre,_)
      equation
        (_,_,DAE.PROP(ety,_),_) = elabExp(cache,env, exp, impl,NONE(),false,pre,info);
        false = Types.isRealOrSubTypeReal(ety);
        s = Dump.printExpStr(exp);
        sp = PrefixUtil.printPrefixStr3(pre);
        es3 = Types.unparseType(ety);
        Error.addSourceMessage(Error.DERIVATIVE_NON_REAL, {s,sp,es3}, info);
      then
        fail();
    case (cache,env,expl,_,_,pre,_)
      equation
        lst = List.map(expl, Dump.printExpStr);
        s = stringDelimitList(lst, ", ");
        sp = PrefixUtil.printPrefixStr3(pre);
        s = stringAppendList({"der(",s,")"});
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,sp}, info);
      then fail();
  end matchcontinue;
end elabBuiltinDer;

protected function elabBuiltinChange "author: PA

  This function handles the built in change operator.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp;
      DAE.ComponentRef cr_1;
      DAE.Const c;
      DAE.Type tp1;
      list<Env.Frame> env;
      Absyn.ComponentRef cr;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      String sp;
      DAE.Properties prop;
      Absyn.Exp aexp;

    case (cache,env,{aexp as Absyn.CREF(componentRef = cr)},{},impl,pre,_) /* simple type, constant variability */
      equation
        (cache,exp,prop,_) = elabExp(cache,env,aexp,impl,NONE(),true,pre,info);
        (cache,exp,prop) = elabBuiltinChange2(cache,env,cr,exp,prop,pre,info);
      then (cache, exp, prop);

    else
      equation
        sp = PrefixUtil.printPrefixStr3(inPrefix);
        Error.addSourceMessage(Error.ARGUMENT_MUST_BE_VARIABLE, {"First","change", sp}, info);
      then fail();
  end match;
end elabBuiltinChange;

protected function elabBuiltinChange2 "author: PA

  This function handles the built in change operator.
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef cr;
  input DAE.Exp inExp;
  input DAE.Properties prop;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,cr,inExp,prop,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.ComponentRef cr_1;
      DAE.Const c;
      DAE.Type tp1,tp2;
      list<Env.Frame> env;
      Absyn.Exp exp;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      String sp;
      DAE.Dimensions dims;

    case (cache,env,_,exp_1,DAE.PROP(tp1,c),pre,_)
      equation
        Types.simpleType(tp1);
        true = Types.isParameterOrConstant(c);
      then (cache, DAE.BCONST(false), DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

    case (cache,env,_,exp_1,DAE.PROP(tp1,c),pre,_)
      equation
        Types.simpleType(tp1);
        Types.discreteType(tp1);
        exp_1 = Expression.makeBuiltinCall("change", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_1, DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()));

    case (cache,env,_,exp_1,DAE.PROP(tp1,c),pre,_) /* workaround for discrete Reals; does not handle Reals that become discrete due to when-section */
      equation
        Types.simpleType(tp1);
        failure(Types.discreteType(tp1));
        cr_1 = Expression.getCrefFromCrefOrAsub(exp_1);
        (cache,DAE.ATTR(variability = SCode.DISCRETE()),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1);
        exp_1 = Expression.makeBuiltinCall("change", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_1, DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()));

    case (cache,env,_,exp_1,DAE.PROP(tp1,c),pre,_)
      equation
        cr_1 = Expression.getCrefFromCrefOrAsub(exp_1);
        Types.simpleType(tp1);
        (cache,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.ARGUMENT_MUST_BE_DISCRETE_VAR, {"First","change",sp}, info);
      then fail();

    case (cache,env,_,exp_1,DAE.PROP(tp1,c),pre,_)
      equation
        failure(Types.simpleType(tp1));
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.TYPE_MUST_BE_SIMPLE, {"operand to change", sp}, info);
      then fail();
  end matchcontinue;
end elabBuiltinChange2;

protected function elabBuiltinCat "author: PA
  This function handles the built in cat operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp,dim_exp;
      DAE.Const const1,const2,const;
      Integer dim_int;
      list<DAE.Exp> matrices_1;
      list<DAE.Properties> props;
      DAE.Type result_type,result_type_1,ty;
      list<Env.Frame> env;
      list<Absyn.Exp> matrices;
      list<DAE.Type> tys,tys2;
      Boolean impl;
      DAE.Properties tp;
      list<String> lst;
      String s,str;
      Env.Cache cache;
      DAE.Type etp;
      Prefix.Prefix pre;
      String sp;
      Absyn.Exp dim_aexp;
      DAE.Dimensions dims;
      DAE.Dimension dim;

    case (cache,env,(dim_aexp :: matrices),_,impl,pre,_) /* impl */
      equation
        // Evaluate the dimension expression and elaborate the rest of the arguments.
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),const1),_) = elabExp(cache,env, dim_aexp, impl,NONE(),true,pre,info);
        (cache,Values.INTEGER(dim_int),_) = Ceval.ceval(cache,env, dim_exp, false,NONE(), Absyn.MSG(info),0);
        (cache,matrices_1,props,_) = elabExpList(cache,env, matrices, impl,NONE(),true,pre,info);

        // Type check the arguments and check that all dimensions except the one
        // we will concatenate along is equal.
        tys = List.map(props,Types.getPropType);
        ty::tys2 = List.map1(tys,Types.makeNthDimUnknown,dim_int);
        result_type = List.fold1(tys2,Types.arraySuperType,info,ty);
        (matrices_1,tys) = Types.matchTypes(matrices_1,tys,result_type,false);

        // Calculate the size of the concatenated dimension, and insert it in
        // the result type.
        dims = List.map1(tys, Types.getDimensionNth, dim_int);
        dim = List.reduce(dims, Expression.dimensionsAdd);
        result_type_1 = Types.setDimensionNth(result_type, dim, dim_int);

        // Construct a call to cat.
        const2 = elabArrayConst(props);
        const = Types.constAnd(const1, const2);
        etp = Types.simplifyType(result_type_1);
        exp = Expression.makeBuiltinCall("cat", dim_exp :: matrices_1, etp);
      then
        (cache,exp,DAE.PROP(result_type_1,const));
    case (cache,env,(dim_aexp :: matrices),_,impl,pre,_)
      equation
        (cache,dim_exp,tp,_) = elabExp(cache,env, dim_aexp, impl,NONE(),true,pre,info);
        failure(DAE.PROP(DAE.T_INTEGER(varLst = _),const1) = tp);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.ARGUMENT_MUST_BE_INTEGER, {"First","cat",sp}, info);
      then
        fail();
    case (cache,env,(dim_aexp :: matrices),_,impl,pre,_)
      equation
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),const1),_) = elabExp(cache,env, dim_aexp, impl,NONE(),true,pre,info);
        (cache,Values.INTEGER(dim_int),_) = Ceval.ceval(cache,env, dim_exp, false,NONE(), Absyn.MSG(info),0);
        (cache,matrices_1,props,_) = elabExpList(cache,env, matrices, impl,NONE(),true,pre,info);
        false = sameDimensionsExceptionDimX(props,dim_int);
        lst = List.map((dim_aexp :: matrices), Dump.printExpStr);
        s = stringDelimitList(lst, ", ");
        sp = PrefixUtil.printPrefixStr3(pre);
        str = stringAppendList({"cat(",s,")"});
        Error.addSourceMessage(Error.DIFFERENT_DIM_SIZE_IN_ARGUMENTS, {str,sp}, info);
      then
        fail();
  end matchcontinue;
end elabBuiltinCat;

protected function elabBuiltinCat2 "Helper function to elab_builtin_cat. Updates the result type given
  the input type, number of matrices given to cat and dimension to concatenate
  along."
  input DAE.Type inType1;
  input Integer inInteger2;
  input Integer inInteger3;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType1,inInteger2,inInteger3)
    local
      Integer new_d,old_d,n_args,n_1,n;
      DAE.Type tp,tp_1;
      DAE.TypeSource ts;
      DAE.Dimension dim;

    case (DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(integer = old_d)}, ty = tp, source = ts),1,n_args)
      equation
        new_d = old_d*n_args;
      then
        DAE.T_ARRAY(tp,{DAE.DIM_INTEGER(new_d)},ts);

    case (DAE.T_ARRAY(dims = {DAE.DIM_UNKNOWN()}), 1, _)
      then
        inType1;

    case (DAE.T_ARRAY(dims = {DAE.DIM_EXP(exp=_)}, ty = tp, source = ts), 1, _)
      then
        DAE.T_ARRAY(tp,{DAE.DIM_UNKNOWN()},ts);

    case (DAE.T_ARRAY(dims = {dim}, ty = tp, source = ts),n,n_args)
      equation
        n_1 = n - 1;
        tp_1 = elabBuiltinCat2(tp, n_1, n_args);
      then
        DAE.T_ARRAY(tp_1,{dim},ts);
  end matchcontinue;
end elabBuiltinCat2;

protected function elabBuiltinIdentity "author: PA
  This function handles the built in identity operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp dim_exp, call;
      Integer size;
      DAE.Dimension dim_size;
      list<Env.Frame> env;
      Absyn.Exp dim;
      Boolean impl;
      Env.Cache cache;
      DAE.Type ty;
      DAE.Type ety;
      Prefix.Prefix pre;
      DAE.Const c;
      Absyn.Msg msg;

    case (cache,env,{dim},_,impl,pre,_)
      equation
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),c),_) = elabExp(cache,env, dim, impl,NONE(),true,pre,info);
        true = Types.isParameterOrConstant(c);
        msg = Util.if_(Flags.getConfigBool(Flags.CHECK_MODEL), Absyn.NO_MSG(), Absyn.MSG(info));
        (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, dim_exp, false,NONE(), msg,0);
        dim_size = DAE.DIM_INTEGER(size);
        ty = Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, {dim_size, dim_size});
        ety = Types.simplifyType(ty);
        dim_exp = DAE.ICONST(size);
        call = Expression.makeBuiltinCall("identity", {dim_exp}, ety);
      then
        (cache, call, DAE.PROP(ty,c));

    case (cache,env,{dim},_,impl,pre,_)
      equation
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),DAE.C_VAR()),_) = elabExp(cache,env, dim, impl,NONE(),true,pre,info);
        ty = Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN(), DAE.DIM_UNKNOWN()});
        ety = Types.simplifyType(ty);
        call = Expression.makeBuiltinCall("identity", {dim_exp}, ety);
      then
        (cache, call, DAE.PROP(ty,DAE.C_VAR()));

    case (cache,env,{dim},_,impl,pre,_)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (cache,dim_exp,DAE.PROP(type_ = DAE.T_INTEGER(varLst = _)),_) = elabExp(cache,env,dim,impl,NONE(),true,pre,info);
        ty = Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN(), DAE.DIM_UNKNOWN()});
        ety = Types.simplifyType(ty);
        call = Expression.makeBuiltinCall("identity", {dim_exp}, ety);
      then
        (cache, call, DAE.PROP(ty,DAE.C_VAR()));

  end matchcontinue;
end elabBuiltinIdentity;

protected function elabBuiltinIsRoot
"This function elaborates on the builtin operator Connections.isRoot."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      list<Env.Frame> env;
      Env.Cache cache;
      Boolean impl;
      Absyn.Exp exp0;
      DAE.Exp exp;
      Prefix.Prefix pre;
    case (cache,env,{exp0},{},impl,pre,_)
      equation
      (cache,exp,_,_) = elabExp(cache, env, exp0, false,NONE(), false,pre,info);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), {exp}, DAE.callAttrBuiltinBool),
        DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR()));
  end match;
end elabBuiltinIsRoot;

protected function elabBuiltinRooted
"author: adrpo
  This function handles the built-in rooted operator. (MultiBody).
  See more here: http://trac.modelica.org/Modelica/ticket/95"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      list<Env.Frame> env;
      Env.Cache cache;
      Boolean impl;
      Absyn.Exp exp0;
      DAE.Exp exp;
      Prefix.Prefix pre;

    //        this operator is not even specified in the specification!
    //        http://trac.modelica.org/Modelica/ticket/95
    case (cache,env,{exp0},{},impl,pre,_) /* impl */
      equation
        (cache, exp, _, _) = elabExp(cache, env, exp0, false,NONE(), false,pre,info);
      then
        (cache,
        DAE.CALL(Absyn.IDENT("rooted"), {exp}, DAE.callAttrBuiltinBool),
        DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR()));

  end match;
end elabBuiltinRooted;

protected function elabBuiltinScalar "author: PA

  This function handles the built in scalar operator.
  For example, scalar({1}) => 1 or scalar({a}) => a
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inArgs,inNamedArg,inImpl,inPrefix,inInfo)
    local
      DAE.Exp e;
      DAE.Type tp,scalar_tp;
      DAE.Const c;
      Env.Env env;
      Env.Cache cache;
      Absyn.Exp aexp;

    case (cache, env, {aexp}, _, _, _, _)
      equation
        (cache, e, DAE.PROP(tp, c), _) =
          elabExp(cache, env, aexp, inImpl, NONE(), true, inPrefix, inInfo);
        e = arrayScalar(e, 1, "scalar", inInfo);
        scalar_tp = Types.arrayElementType(tp);
      then
        (cache, e, DAE.PROP(scalar_tp, c));

  end match;
end elabBuiltinScalar;

public function elabBuiltinSkew2 "help function to ExpressionSimplify"
  input list<DAE.Exp> v1;
  output list<list<DAE.Exp>> res;
algorithm
  res := match v1
    local
      DAE.Exp x1,x2,x3,zero,a11,a12,a13,a21,a22,a23,a31,a32,a33;

     // skew(x)
    case {x1,x2,x3}
      equation
        zero = Expression.makeConstZero(Expression.typeof(x1));
        a11 = zero;
        a12 = Expression.negate(x3);
        a13 = x2;
        a21 = x3;
        a22 = zero;
        a23 = Expression.negate(x1);
        a31 = Expression.negate(x2);
        a32 = x1;
        a33 = zero;
      then {{a11,a12,a13},{a21,a22,a23},{a31,a32,a33}};
  end match;
end elabBuiltinSkew2;

public function elabBuiltinCross2 "help function to elabBuiltinCross. Public since it used by ExpressionSimplify.simplify1"
  input list<DAE.Exp> v1;
  input list<DAE.Exp> v2;
  output list<DAE.Exp> res;
algorithm
  res := match (v1,v2)
  local DAE.Exp x1,x2,x3,y1,y2,y3,r1,r2,r3;

     // {x[2]*y[3]-x[3]*y[2],x[3]*y[1]-x[1]*y[3],x[1]*y[2]-x[2]*y[1]}
    case({x1,x2,x3},{y1,y2,y3})
      equation
        r1 = Expression.makeDiff(Expression.makeProductLst({x2,y3}),Expression.makeProductLst({x3,y2}));
        r2 = Expression.makeDiff(Expression.makeProductLst({x3,y1}),Expression.makeProductLst({x1,y3}));
        r3 = Expression.makeDiff(Expression.makeProductLst({x1,y2}),Expression.makeProductLst({x2,y1}));
      then {r1,r2,r3};
  end match;
end elabBuiltinCross2;

protected function elabBuiltinString "
  author: PA
  This function handles the built-in String operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp;
      DAE.Type tp;
      DAE.Const c;
      list<DAE.Const> constlist;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl;
      list<DAE.Exp> args_1;
      Env.Cache cache;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      list<Slot> slots,newslots;
      Prefix.Prefix pre;

    // handle most of the stuff
    case (cache,env,args as e::_,nargs,impl,pre,_)
      equation
        (cache,exp,DAE.PROP(tp,c),_) = elabExp(cache,env, e, impl,NONE(),true,pre,info);
        // Create argument slots for String function.
        slots = {SLOT(("x",tp,DAE.C_VAR(),NONE()),false,NONE(),{}),
                 SLOT(("minimumLength",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE()),false,SOME(DAE.ICONST(0)),{}),
                 SLOT(("leftJustified",DAE.T_BOOL_DEFAULT,DAE.C_VAR(),NONE()),false,SOME(DAE.BCONST(true)),{})};
        // Only String(Real) has the significantDigits option.
        slots = Util.if_(Types.isRealOrSubTypeReal(tp),
          listAppend(slots, {SLOT(("significantDigits",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE()),false,SOME(DAE.ICONST(6)),{})}),
          slots);
        (cache,args_1,newslots,constlist,_) = elabInputArgs(cache,env, args, nargs, slots, true/*checkTypes*/ ,impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), {}, NONE(), pre, info);
        c = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        exp = Expression.makeBuiltinCall("String", args_1, DAE.T_STRING_DEFAULT);
      then
        (cache, exp, DAE.PROP(DAE.T_STRING_DEFAULT,c));

    // handle format
    case (cache,env,args as e::_,nargs,impl,pre,_)
      equation
        (cache,exp,DAE.PROP(tp,c),_) = elabExp(cache,env, e, impl,NONE(),true,pre,info);

        slots = {SLOT(("x",tp,DAE.C_VAR(),NONE()),false,NONE(),{})};

        slots = Util.if_(Types.isRealOrSubTypeReal(tp),
          listAppend(slots, {SLOT(("format",DAE.T_STRING_DEFAULT,DAE.C_VAR(),NONE()),false,SOME(DAE.SCONST("f")),{})}),
          slots);
        slots = Util.if_(Types.isIntegerOrSubTypeInteger(tp),
          listAppend(slots, {SLOT(("format",DAE.T_STRING_DEFAULT,DAE.C_VAR(),NONE()),false,SOME(DAE.SCONST("d")),{})}),
          slots);
        slots = Util.if_(Types.isString(tp),
          listAppend(slots, {SLOT(("format",DAE.T_STRING_DEFAULT,DAE.C_VAR(),NONE()),false,SOME(DAE.SCONST("s")),{})}),
          slots);
        (cache,args_1,newslots,constlist,_) = elabInputArgs(cache, env, args, nargs, slots, true /*checkTypes*/, impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), {}, NONE(), pre, info);
        c = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        exp = Expression.makeBuiltinCall("String", args_1, DAE.T_STRING_DEFAULT);
      then
        (cache, exp, DAE.PROP(DAE.T_STRING_DEFAULT,c));
  end matchcontinue;
end elabBuiltinString;

protected function elabBuiltinGetInstanceName
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      String str;
      Absyn.Path name,envName;
    case (Env.CACHE(modelName=name),_,{},{},_,Prefix.NOPRE(),_)
      equation
        envName = Env.getEnvName(inEnv);
        true = Absyn.pathEqual(envName,name);
        str = Absyn.pathLastIdent(name);
        outExp = DAE.SCONST(str);
        outProperties = DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST());
      then (inCache,outExp,outProperties);
    case (Env.CACHE(modelName=name),_,{},{},_,Prefix.NOPRE(),_)
      equation
        envName = Env.getEnvName(inEnv);
        false = Absyn.pathEqual(envName,name);
        str = Absyn.pathString(envName);
        outExp = DAE.SCONST(str);
        outProperties = DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST());
      then (inCache,outExp,outProperties);
    case (Env.CACHE(modelName=name),_,{},{},_,_,_)
      equation
        str = Absyn.pathLastIdent(name) +& "." +& PrefixUtil.printPrefixStr(inPrefix);
        outExp = DAE.SCONST(str);
        outProperties = DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST());
      then (inCache,outExp,outProperties);
  end matchcontinue;
end elabBuiltinGetInstanceName;

protected function elabBuiltinVector "author: PA
  This function handles the built in vector operator."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp;
      DAE.Type tp,tp_1,arr_tp;
      DAE.Const c;
      DAE.Type etp;
      list<Env.Frame> env;
      Absyn.Exp e;
      Boolean impl,scalar;
      list<DAE.Exp> expl,expl_1,expl_2;
      list<list<DAE.Exp>> explm;
      list<Integer> dims;
      Env.Cache cache;
      Prefix.Prefix pre;
      Integer dim,dimtmp;

    case (cache,env,{e},_,impl,pre,_) /* vector(scalar) = {scalar} */
      equation
        (cache,exp,DAE.PROP(tp,c),_) = elabExp(cache,env, e, impl,NONE(),true,pre,info);
        Types.simpleType(tp);
        arr_tp = Types.liftArray(tp, DAE.DIM_INTEGER(1));
        etp = Types.simplifyType(arr_tp);
      then
        (cache,DAE.ARRAY(etp,true,{exp}),DAE.PROP(arr_tp,c));

    case (cache,env,{e},_,impl,pre,_) /* vector(array of scalars) = array of scalars */
      equation
        (cache,DAE.ARRAY(etp,scalar,expl),DAE.PROP(tp,c),_) = elabExp(cache,env, e, impl,NONE(),true,pre,info);
        1 = Types.numberOfDimensions(tp);
      then
        (cache,DAE.ARRAY(etp,scalar,expl),DAE.PROP(tp,c));

    case (cache,env,{e},_,impl,pre,_) /* vector of multi dimensional array, at most one dim > 1 */
      equation
        (cache,DAE.ARRAY(_,_,expl),DAE.PROP(tp,c),_) = elabExp(cache,env, e, impl,NONE(),true,pre,info);
        tp_1 = Types.arrayElementType(tp);
        dims = Types.getDimensionSizes(tp);
        checkBuiltinVectorDims(e, env, dims, pre, info);
        expl_1 = flattenArray(expl);
        dim = listLength(expl_1);
        tp = DAE.T_ARRAY(tp_1, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
        etp = Types.simplifyType(tp);
      then
        (cache,DAE.ARRAY(etp,true,expl_1),DAE.PROP(tp,c));

    case (cache,env,{e},_,impl,pre,_) /* vector of multi dimensional matrix, at most one dim > 1 */
      equation
        (cache,DAE.MATRIX(matrix=explm),DAE.PROP(tp,c),_) = elabExp(cache,env, e, impl,NONE(),true,pre,info);
        tp_1 = Types.arrayElementType(tp);
        dims = Types.getDimensionSizes(tp);
        expl_2 = List.flatten(explm);
        expl_1 = elabBuiltinVector2(expl_2, dims);
        dimtmp = listLength(expl_1);
        tp_1 = Types.liftArray(tp_1, DAE.DIM_INTEGER(dimtmp));
        etp = Types.simplifyType(tp_1);
      then
        (cache,DAE.ARRAY(etp,true,expl_1),DAE.PROP(tp_1,c));

    case (cache, env, {e}, _, impl, pre,_)
      equation
        (cache, exp, DAE.PROP(tp, c), _) = elabExp(cache, env, e, impl,NONE(), true, pre,info);
        tp = Types.liftArray(Types.arrayElementType(tp), DAE.DIM_UNKNOWN());
        etp = Types.simplifyType(tp);
        exp = Expression.makeBuiltinCall("vector", {exp}, etp);
      then
        (cache, exp, DAE.PROP(tp, c));
  end matchcontinue;
end elabBuiltinVector;

protected function checkBuiltinVectorDims
  input Absyn.Exp expr;
  input Env.Env env;
  input list<Integer> dimensions;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(expr, env, dimensions,inPrefix, inInfo)
    local
      Integer dims_larger_than_one;
      Prefix.Prefix pre;
      String arg_str, scope_str, dim_str, pre_str;
    case (_, _, _,_, _)
      equation
        dims_larger_than_one = countDimsLargerThanOne(dimensions);
        (dims_larger_than_one > 1) = false;
      then ();
    case (_, _, _, pre, _)
      equation
        scope_str = Env.printEnvPathStr(env);
        arg_str = "vector(" +& Dump.printExpStr(expr) +& ")";
        dim_str = "[" +& stringDelimitList(List.map(dimensions, intString), ", ") +& "]";
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.BUILTIN_VECTOR_INVALID_DIMENSIONS,
          {scope_str, pre_str, dim_str, arg_str}, inInfo);
      then fail();
  end matchcontinue;
end checkBuiltinVectorDims;

protected function countDimsLargerThanOne
  input list<Integer> dimensions;
  output Integer dimsLargerThanOne;
algorithm
  dimsLargerThanOne := matchcontinue(dimensions)
    local
      Integer dim, dims_larger_than_one;
      list<Integer> rest_dims;
    case ({}) then 0;
    case ((dim :: rest_dims))
      equation
        (dim > 1) = true;
        dims_larger_than_one = 1 + countDimsLargerThanOne(rest_dims);
      then
        dims_larger_than_one;
    case ((dim :: rest_dims))
      equation
        dims_larger_than_one = countDimsLargerThanOne(rest_dims);
      then dims_larger_than_one;
  end matchcontinue;
end countDimsLargerThanOne;

protected function flattenArray
  input list<DAE.Exp> arr;
  output list<DAE.Exp> flattenedExpl;
algorithm
  flattenedExpl := matchcontinue(arr)
    local
      DAE.Exp e;
      list<DAE.Exp> expl, expl2, rest_expl;

    case ({}) then {};

    case ((DAE.ARRAY(array = expl) :: rest_expl))
      equation
        expl = flattenArray(expl);
        expl2 = flattenArray(rest_expl);
        expl = listAppend(expl, expl2);
      then expl;

    case ((DAE.MATRIX(matrix = {{e}}) :: rest_expl))
      equation
        expl = flattenArray(rest_expl);
      then
        (e :: expl);

    case ((e :: expl))
      equation
        expl = flattenArray(expl);
      then
        (e :: expl);
  end matchcontinue;
end flattenArray;

protected function dimensionListMaxOne "Helper function to elab_builtin_vector."
  input list<Integer> inIntegerLst;
  output Integer dimensions;
algorithm
  dimensions := matchcontinue (inIntegerLst)
    local
      Integer dim,x;
      list<Integer> dims;

    case ({}) then 0;

    case ((dim :: dims))
      equation
        (dim > 1) = true;
        Error.addMessage(Error.ERROR_FLATTENING, {"Vector may only be 1x2 or 2x1 dimensions"});
      then
        10;

    case((dim :: dims))
      equation
        x = dimensionListMaxOne(dims);
      then
        x;
  end matchcontinue;
end dimensionListMaxOne;

protected function elabBuiltinVector2 "Helper function to elabBuiltinVector, for matrix expressions."
  input list<DAE.Exp> inExpExpLst;
  input list<Integer> inIntegerLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExpExpLst,inIntegerLst)
    local
      list<DAE.Exp> expl_1,expl;
      Integer dim;
      list<Integer> dims;

    case (expl,(dim :: dims))
      equation
        (dim > 1) = true;
        (1 > dimensionListMaxOne(dims)) = true;
        then
        expl;

    case (expl,(dim :: dims))
      equation
        (1 > dimensionListMaxOne(dims) ) = false;
        expl_1 = elabBuiltinVector2(expl, dims);
      then
        expl_1;
  end matchcontinue;
end elabBuiltinVector2;

public function elabBuiltinMatrix
  "Elaborates the builtin matrix function."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) := match(inCache, inEnv, inArgs, inNamedArgs, inImpl, inPrefix, inInfo)
    local
      Absyn.Exp arg;
      Env.Cache cache;
      DAE.Exp exp;
      DAE.Properties props;
      DAE.Type ty;

    case (_, _, {arg}, _, _, _, _)
      equation
        (cache, exp, props, _) =
          elabExp(inCache, inEnv, arg, inImpl, NONE(), true, inPrefix, inInfo);
        ty = Types.getPropType(props);
        (exp, props) = elabBuiltinMatrix2(inCache, inEnv, exp, props, ty, inInfo);
      then
        (cache, exp, props);

    else
      equation
        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS, {"matrix"}, inInfo);
      then
        fail();

  end match;
end elabBuiltinMatrix;

protected function elabBuiltinMatrix2
  "Helper function to elabBuiltinMatrix, evaluates the matrix function given the
   elaborated argument."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inArg;
  input DAE.Properties inProperties;
  input DAE.Type inType;
  input Absyn.Info inInfo;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp, outProperties) :=
  matchcontinue(inCache, inEnv, inArg, inProperties, inType, inInfo)
    local
      DAE.Type ty;
      DAE.Exp exp;
      DAE.Properties props;
      list<DAE.Exp> expl;
      DAE.Type ety;
      DAE.Dimension dim1, dim2;
      Boolean scalar;
      DAE.TypeSource ts;

    // Scalar
    case (_, _, _, _, _, _)
      equation
        Types.simpleType(inType);
        (exp, props) = promoteExp(inArg, inProperties, 2);
      then
        (exp, props);

    // 1-dimensional array
    case (_, _, _, _, _, _)
      equation
        1 = Types.numberOfDimensions(inType);
        (exp, props) = promoteExp(inArg, inProperties, 2);
      then
        (exp, props);

    // Matrix
    case (_, _, DAE.MATRIX(ty = _), _, _, _)
      then (inArg, inProperties);

    // n-dimensional array
    case (_, _, DAE.ARRAY(ty = DAE.T_ARRAY(ety, dim1 :: dim2 :: _, ts), scalar = scalar, array = expl), _, _, _)
      equation
        expl = List.map1(expl, elabBuiltinMatrix3, inInfo);
        ty = Types.arrayElementType(inType);
        ty = Types.liftArrayListDims(ty, {dim1, dim2});
        props = Types.setTypeInProps(ty, inProperties);
      then
        (DAE.ARRAY(DAE.T_ARRAY(ety, {dim1, dim2}, ts), scalar, expl), props);

  end matchcontinue;
end elabBuiltinMatrix2;

protected function elabBuiltinMatrix3
  "Helper function to elabBuiltinMatrix2."
  input DAE.Exp inExp;
  input Absyn.Info inInfo;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inInfo)
    local
      DAE.Type ety, ety2;
      Boolean scalar;
      list<DAE.Exp> expl;
      DAE.Dimension dim;
      DAE.Dimensions dims;
      list<list<DAE.Exp>> matrix_expl;
      DAE.TypeSource ts;

    case (DAE.ARRAY(ty = DAE.T_ARRAY(ety, dim :: _, ts),scalar = scalar, array = expl), _)
      equation
        expl = List.map3(expl, arrayScalar, 3, "matrix", inInfo);
      then
        DAE.ARRAY(DAE.T_ARRAY(ety, {dim}, ts), scalar, expl);

    case (DAE.MATRIX(ty = DAE.T_ARRAY(ety, dim :: dims, ts), matrix = matrix_expl), _)
      equation
        ety2 = DAE.T_ARRAY(ety, dims, ts);
        expl = List.map2(matrix_expl, Expression.makeArray, ety2, true);
        expl = List.map3(expl, arrayScalar, 3, "matrix", inInfo);
      then
        DAE.ARRAY(DAE.T_ARRAY(ety, {dim}, ts), true, expl);

  end match;
end elabBuiltinMatrix3;

protected function arrayScalar
  "Returns the scalar value of an array, or prints an error message and fails if
  any dimension of the array isn't of size 1."
  input DAE.Exp inExp;
  input Integer inDim "The current dimension, used for error message.";
  input String inOperator "The current operator name, used for error message.";
  input Absyn.Info inInfo;
  output DAE.Exp outExp;
algorithm
  outExp := match(inExp, inDim, inOperator, inInfo)
    local
      DAE.Exp exp;
      DAE.Type ty;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mexpl;
      String dim_str, size_str;

    // An array with one element.
    case (DAE.ARRAY(array = {exp}), _, _, _)
      then arrayScalar(exp, inDim + 1, inOperator, inInfo);

    // Any other array.
    case (DAE.ARRAY(array = expl), _, _, _)
      equation
        dim_str = intString(inDim);
        size_str = intString(listLength(expl));
        Error.addSourceMessage(Error.INVALID_ARRAY_DIM_IN_CONVERSION_OP,
          {dim_str, inOperator, "1", size_str}, inInfo);
      then
        fail();

    // A matrix where the first dimension is 1.
    case (DAE.MATRIX(ty = ty, matrix = {expl}), _, _, _)
      then arrayScalar(DAE.ARRAY(ty, true, expl), inDim + 1, inOperator, inInfo);

    // Any other matrix.
    case (DAE.MATRIX(matrix = mexpl), _, _, _)
      equation
        dim_str = intString(inDim);
        size_str = intString(listLength(mexpl));
        Error.addSourceMessage(Error.INVALID_ARRAY_DIM_IN_CONVERSION_OP,
          {dim_str, inOperator, "1", size_str}, inInfo);
      then
        fail();

    // Anything else is assumed to be a scalar.
    else inExp;
  end match;
end arrayScalar;

public function elabBuiltinHandlerGeneric "
  This function dispatches the elaboration of special builtin operators by
  returning the appropriate function, see also elab_builtin_handler.
  These special builtin operators can not be represented in the
  environment since they must be generated on the fly, given a generated
  type.
"
  input String inIdent;
  output FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties;
  partial function FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties
    input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output Env.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
  end FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties;
algorithm
  outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties:=
  match (inIdent)
    case "cardinality" then elabBuiltinCardinality;
  end match;
end elabBuiltinHandlerGeneric;

public function elabBuiltinHandler "
  This function dispatches the elaboration of builtin operators by
  returning the appropriate function. When a new builtin operator is
  added, a new rule has to be added to this function.
"
  input String inIdent;
  output FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties;
  partial function FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties
    input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output Env.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
  end FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties;
algorithm
  outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties:=
  match (inIdent)
    case "delay" then elabBuiltinDelay;
    case "smooth" then elabBuiltinSmooth;
    case "size" then elabBuiltinSize;  /* impl */
    case "ndims" then elabBuiltinNDims;
    case "zeros" then elabBuiltinZeros;
    case "ones" then elabBuiltinOnes;
    case "fill" then elabBuiltinFill;
    case "max" then elabBuiltinMax;
    case "min" then elabBuiltinMin;
    case "transpose" then elabBuiltinTranspose;
    case "symmetric" then elabBuiltinSymmetric;
    case "array" then elabBuiltinArray;
    case "sum" then elabBuiltinSum;
    case "product" then elabBuiltinProduct;
    case "pre" then elabBuiltinPre;
    case "boolean" then elabBuiltinBoolean;
    case "diagonal" then elabBuiltinDiagonal;
    case "differentiate" then elabBuiltinDifferentiate;
    case "noEvent" then elabBuiltinNoevent;
    case "edge" then elabBuiltinEdge;
    case "der" then elabBuiltinDer;
    case "change" then elabBuiltinChange;
    case "cat" then elabBuiltinCat;
    case "identity" then elabBuiltinIdentity;
    case "vector" then elabBuiltinVector;
    case "matrix" then elabBuiltinMatrix;
    case "scalar" then elabBuiltinScalar;
    case "String" then elabBuiltinString;
    case "rooted" then elabBuiltinRooted;
    case "Integer" then elabBuiltinIntegerEnum;
    case "EnumToInteger" then elabBuiltinIntegerEnum;
    case "inStream" then elabBuiltinInStream;
    case "actualStream" then elabBuiltinActualStream;
    case "getInstanceName" then elabBuiltinGetInstanceName;
  end match;
end elabBuiltinHandler;

public function elabBuiltinHandlerInternal "
  This function dispatches the elaboration of builtin operators by
  returning the appropriate function. When a new builtin operator is
  added, a new rule has to be added to this function.
"
  input String inIdent;
  output FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties;
  partial function FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties
    input Env.Cache inCache;
    input Env.Env inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output Env.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
  end FuncTypeEnv_EnvAbsyn_ExpLstBooleanToExp_ExpTypes_Properties;
algorithm
  outFuncTypeEnvEnvAbsynExpLstBooleanToExpExpTypesProperties:=
  match (inIdent)
    case "simplify" then elabBuiltinSimplify;
  end match;
end elabBuiltinHandlerInternal;

protected function isBuiltinFunc "Returns true if the function name given as argument
  is a builtin function, which either has a elabBuiltinHandler function
  or can be found in the builtin environment."
  input Absyn.Path inPath "the path of the found function";
  input DAE.Type ty;
  output DAE.FunctionBuiltin isBuiltin;
  output Boolean b;
  output Absyn.Path outPath "make the path non-FQ";
algorithm
  (isBuiltin,b,outPath) := matchcontinue (inPath,ty)
    local
      String id;
      Absyn.Path path;

    case (path,DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isBuiltin=isBuiltin as DAE.FUNCTION_BUILTIN(_))))
      equation
        path = Absyn.makeNotFullyQualified(path);
      then (isBuiltin,true,path);

    case (path,DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isBuiltin=isBuiltin as DAE.FUNCTION_BUILTIN_PTR())))
      equation
        path = Absyn.makeNotFullyQualified(path);
      then (isBuiltin,false,path);

    case (Absyn.IDENT(name = id),_)
      equation
        _ = elabBuiltinHandler(id);
      then
        (DAE.FUNCTION_BUILTIN(SOME(id)),true,inPath);

    case (Absyn.QUALIFIED("OpenModelicaInternal",Absyn.IDENT(name = id)),_)
      equation
        _ = elabBuiltinHandlerInternal(id);
      then
        (DAE.FUNCTION_BUILTIN(SOME(id)),true,inPath);

    case (Absyn.FULLYQUALIFIED(path),_)
      equation
        (isBuiltin as DAE.FUNCTION_BUILTIN(_),_,path) = isBuiltinFunc(path,ty);
      then
        (isBuiltin,true,path);

    case (Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")),_)
      then (DAE.FUNCTION_BUILTIN(NONE()),true,inPath);

    case (path,_) then (DAE.FUNCTION_NOT_BUILTIN(),false,path);
  end matchcontinue;
end isBuiltinFunc;

protected function elabCallBuiltin "This function elaborates on builtin operators (such as \"pre\", \"der\" etc.),
  by calling the builtin handler to retrieve the correct function to call."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  partial function handlerFunc
    input Env.Cache inCache;
    input list<Env.Frame> inEnvFrameLst;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArgs;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output Env.Cache outCache;
    output DAE.Exp outExp;
    output DAE.Properties outProperties;
  end handlerFunc;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inNamedArgs,inBoolean,inPrefix,info)
    local
      handlerFunc handler;
      DAE.Exp exp;
      DAE.Properties prop;
      list<Env.Frame> env;
      String name;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      Absyn.ComponentRef cr;

    /* impl for normal builtin operators and functions */
    case (cache,env,Absyn.CREF_IDENT(name = name,subscripts = {}),args,nargs,impl,pre,_)
      equation
        handler = elabBuiltinHandler(name);
        (cache,exp,prop) = handler(cache,env, args, nargs, impl,pre,info);
      then
        (cache,exp,prop);
    case (cache,env,Absyn.CREF_QUAL(name = "OpenModelicaInternal", componentRef = Absyn.CREF_IDENT(name = name)),args,nargs,impl,pre,_)
      equation
        handler = elabBuiltinHandlerInternal(name);
        (cache,exp,prop) = handler(cache,env, args, nargs, impl,pre,info);
      then
        (cache,exp,prop);

    /* special handling for MultiBody 3.x rooted() operator */
    case (cache,env,Absyn.CREF_IDENT(name = "rooted"),args,nargs,impl,pre,_)
      equation
        (cache,exp,prop) = elabBuiltinRooted(cache,env, args, nargs, impl,pre,info);
      then
        (cache,exp,prop);
    /* special handling for Connections.isRoot() operator */
    case (cache,env,Absyn.CREF_QUAL(name = "Connections", componentRef = Absyn.CREF_IDENT(name = "isRoot")),args,nargs,impl,pre,_)
      equation
        (cache,exp,prop) = elabBuiltinIsRoot(cache,env, args, nargs, impl,pre,info);
      then
        (cache,exp,prop);
    /* for generic types, like e.g. cardinality */
    case (cache,env,Absyn.CREF_IDENT(name = name,subscripts = {}),args,nargs,impl,pre,_)
      equation
        handler = elabBuiltinHandlerGeneric(name);
        (cache,exp,prop) = handler(cache,env, args, nargs, impl,pre,info);
      then
        (cache,exp,prop);
    case (cache,env,Absyn.CREF_FULLYQUALIFIED(cr),args,nargs,impl,pre,_)
      equation
        (cache,exp,prop) = elabCallBuiltin(cache,env,cr,args,nargs,impl,pre,info);
      then
        (cache,exp,prop);
  end matchcontinue;
end elabCallBuiltin;

protected function elabCall "
function: elabCall
  This function elaborates on a function call.  It converts the name
  to a Absyn.Path, and used the Static.elabCallArgs to do the rest of the
  work."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numErrorMessages;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inPrefix,info,numErrorMessages)
    local
      DAE.Exp e;
      DAE.Properties prop;
      Option<GlobalScript.SymbolTable> st;
      list<Env.Frame> env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Absyn.Path fn_1;
      String fnstr,argstr,prestr,s,name,env_str;
      list<String> argstrs;
      Env.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,fn,args,nargs,impl,st,pre,_,_)
      equation
        (cache,e,prop) = elabCallBuiltin(cache,env, fn, args, nargs, impl,pre,info) "Built in functions (e.g. \"pre\", \"der\"), have only possitional arguments" ;
      then
        (cache,e,prop,st);

    case (cache,env,fn,args,nargs,impl,st,pre,_,_)
      equation
        true = hasBuiltInHandler(fn);
        true = numErrorMessages == Error.getNumErrorMessages();
        name = Absyn.printComponentRefStr(fn);
        s = stringDelimitList(List.map(args, Dump.printExpStr), ", ");
        s = stringAppendList({name,"(",s,")'.\n"});
        prestr = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,prestr}, info);
      then fail();

    case (_, _, Absyn.CREF_INVALID(componentRef = fn), _, _, _, _, _, _, _)
      equation
        fnstr = Absyn.printComponentRefStr(fn);
        env_str = Env.printEnvPathStr(inEnv);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_ERROR,
          {fnstr, env_str}, info);
      then
        fail();

    /* Interactive mode */
    case (cache,env,fn,args,nargs,(impl as true),st,pre,_,_)
      equation
        false = hasBuiltInHandler(fn);
        ErrorExt.setCheckpoint("elabCall_InteractiveFunction");
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre,info);
        fnstr = Dump.printComponentRefStr(fn);
        ErrorExt.delCheckpoint("elabCall_InteractiveFunction");
      then
        (cache,e,prop,st);

    /* Non-interactive mode */
    case (cache,env,fn,args,nargs,(impl as false),st,pre,_,_)
      equation
        false = hasBuiltInHandler(fn);
        fnstr = Dump.printComponentRefStr(fn);
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre,info);
      then
        (cache,e,prop,st);

    case (cache,env,fn,args,nargs,impl,st,pre,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabCall failed\n");
        Debug.trace(" function: ");
        fnstr = Dump.printComponentRefStr(fn);
        Debug.trace(fnstr);
        Debug.trace("   posargs: ");
        argstrs = List.map(args, Dump.printExpStr);
        argstr = stringDelimitList(argstrs, ", ");
        Debug.traceln(argstr);
        Debug.trace(" prefix: ");
        prestr = PrefixUtil.printPrefixStr(pre);
        Debug.traceln(prestr);
      then
        fail();
    case (cache,env,fn,args,nargs,impl,st as SOME(_),pre,_,_) /* impl LS: Check if a builtin function call, e.g. size() and calculate if so */
      equation
        (cache,e,prop,st) = StaticScript.elabCallInteractive(cache,env, fn, args, nargs, impl,st,pre,info) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
        ErrorExt.rollBack("elabCall_InteractiveFunction");
      then
        (cache,e,prop,st);
    case(_,_,_,_,_,_,_,_,_,_)
        equation
          true=ErrorExt.isTopCheckpoint("elabCall_InteractiveFunction");
          ErrorExt.delCheckpoint("elabCall_InteractiveFunction");    
        then fail();    
  end matchcontinue;
end elabCall;

public function hasBuiltInHandler "
Author: BZ, 2009-02
Determine if a function has a builtin handler or not.
"
  input Absyn.ComponentRef fn;
  output Boolean b;
algorithm
  b := matchcontinue(fn)
    local
      String name;
    case (Absyn.CREF_IDENT(name = name,subscripts = {}))
      equation
        _ = elabBuiltinHandler(name);
      then
        true;
    else false;
  end matchcontinue;
end hasBuiltInHandler;

public function elabVariablenames "This function elaborates variablenames to DAE.Expression. A variablename can
  be used in e.g. plot(model,{v1{3},v2.t}) It should only be used in interactive
  functions that uses variablenames as componentreferences.
"
  input list<Absyn.Exp> inAbsynExpLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  match (inAbsynExpLst)
    local
      list<DAE.Exp> xs_1;
      Absyn.ComponentRef cr;
      list<Absyn.Exp> xs;
    case {} then {};
    case ((Absyn.CREF(componentRef = cr) :: xs))
      equation

        xs_1 = elabVariablenames(xs);
      then
        (DAE.CODE(Absyn.C_VARIABLENAME(cr),DAE.T_UNKNOWN_DEFAULT) :: xs_1);
    case ((Absyn.CALL(Absyn.CREF_IDENT(name="der"), Absyn.FUNCTIONARGS({Absyn.CREF(componentRef = cr)}, {})) :: xs))
      equation
        xs_1 = elabVariablenames(xs);
      then
        DAE.CODE(Absyn.C_EXPRESSION(Absyn.CALL(Absyn.CREF_IDENT("der",{}),Absyn.FUNCTIONARGS({Absyn.CREF(cr)},{}))),DAE.T_UNKNOWN_DEFAULT)::xs_1;

/*
    case ((Absyn.STRING(value = str) :: xs))
      equation

        xs_1 = elabVariablenames(xs);
      then
        (DAE.SCONST(str) :: xs_1);
*/
  end match;
end elabVariablenames;

public function getOptionalNamedArgExpList
  input String name;
  input list<Absyn.NamedArg> nargs;
  output list<DAE.Exp> out;
algorithm
  out := matchcontinue (name, nargs)
    local
      list<Absyn.Exp> absynExpList;
      list<DAE.Exp> daeExpList;
      String argName;
      list<Absyn.NamedArg> rest;
    case (_, {})
      then {};
    case (_, (Absyn.NAMEDARG(argName = argName, argValue = Absyn.ARRAY(arrayExp = absynExpList)) :: _))
      equation
        true = stringEq(name, argName);
        daeExpList = absynExpListToDaeExpList(absynExpList);
      then daeExpList;
    case (_, _::rest)
      then getOptionalNamedArgExpList(name, rest);
  end matchcontinue;
end getOptionalNamedArgExpList;

protected function absynExpListToDaeExpList
  input list<Absyn.Exp> absynExpList;
  output list<DAE.Exp> out;
algorithm
  out := matchcontinue (absynExpList)
    local
      list<DAE.Exp> daeExpList;
      list<Absyn.Exp> absynRest;
      Absyn.ComponentRef absynCr;
      Absyn.Path absynPath;
      DAE.ComponentRef daeCr;
      DAE.Exp crefExp;

    case ({})
      then {};

    case (Absyn.CREF(componentRef = absynCr) :: absynRest)
      equation
        absynPath = Absyn.crefToPath(absynCr);
        daeCr = pathToComponentRef(absynPath);
        daeExpList = absynExpListToDaeExpList(absynRest);
        crefExp = Expression.crefExp(daeCr);
      then
        crefExp :: daeExpList;

    case (_ :: absynRest)
      then absynExpListToDaeExpList(absynRest);
  end matchcontinue;
end absynExpListToDaeExpList;

public function getOptionalNamedArg " This function is used to \"elaborate\" interactive functions optional parameters,
  e.g. simulate(A.b, startTime=1), startTime is an optional parameter
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Boolean inBoolean;
  input String inIdent;
  input DAE.Type inType;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input DAE.Exp inExp;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp):=
  matchcontinue (inCache,inEnv,inInteractiveInteractiveSymbolTableOption,inBoolean,inIdent,inType,inAbsynNamedArgLst,inExp,inPrefix,info)
    local
      DAE.Exp exp,exp_1,exp_2,dexp;
      DAE.Type t,tp;
      DAE.Const c1;
      list<Env.Frame> env;
      Option<GlobalScript.SymbolTable> st;
      Boolean impl;
      String id,id2;
      list<Absyn.NamedArg> xs;
      Env.Cache cache;
      Prefix.Prefix pre;
      Absyn.Exp aexp;
    case (cache,_,_,_,_,_,{},exp,_,_) then (cache,exp);  /* The expected type */
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = id2,argValue = aexp) :: xs),_,pre,_)
      equation
        true = stringEq(id, id2);
        (cache,exp_1,DAE.PROP(t,c1),_) = elabExp(cache,env,aexp,impl,st,true,pre,info);
        (exp_2,_) = Types.matchType(exp_1, t, tp, true);
      then
        (cache,exp_2);
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = id2) :: xs),dexp,pre,_)
      equation
        (cache,exp_1) = getOptionalNamedArg(cache,env, st, impl, id, tp, xs, dexp,pre,info);
      then
        (cache,exp_1);
  end matchcontinue;
end getOptionalNamedArg;

public function elabUntypedCref "This function elaborates a ComponentRef without adding type information.
   Environment is passed along, such that constant subscripts can be elabed using existing
  functions
"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  match (inCache,inEnv,inComponentRef,inBoolean,inPrefix,info)
    local
      list<DAE.Subscript> subs_1;
      list<Env.Frame> env;
      String id;
      list<Absyn.Subscript> subs;
      Boolean impl;
      DAE.ComponentRef cr_1;
      Absyn.ComponentRef cr;
      Env.Cache cache;
      Prefix.Prefix pre;
    case (cache,env,Absyn.CREF_IDENT(name = id,subscripts = subs),impl,pre,_) /* impl */
      equation
        (cache,subs_1,_) = elabSubscripts(cache,env, subs, impl,pre,info);
      then
        (cache,ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,subs_1));
    case (cache,env,Absyn.CREF_QUAL(name = id,subscripts = subs,componentRef = cr),impl,pre,_)
      equation
        (cache,subs_1,_) = elabSubscripts(cache,env, subs, impl,pre,info);
        (cache,cr_1) = elabUntypedCref(cache,env, cr, impl,pre,info);
      then
        (cache,ComponentReference.makeCrefQual(id,DAE.T_UNKNOWN_DEFAULT,subs_1,cr_1));
  end match;
end elabUntypedCref;

protected function pathToComponentRef "This function translates a typename to a variable name.
"
  input Absyn.Path inPath;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  match (inPath)
    local
      String id;
      DAE.ComponentRef cref;
      Absyn.Path path;
    case (Absyn.FULLYQUALIFIED(path)) then pathToComponentRef(path);
    case (Absyn.IDENT(name = id)) then ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{});
    case (Absyn.QUALIFIED(name = id,path = path))
      equation
        cref = pathToComponentRef(path);
      then
        ComponentReference.makeCrefQual(id,DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("")), {}, NONE(), DAE.emptyTypeSource),{},cref);
  end match;
end pathToComponentRef;

public function componentRefToPath "This function translates a variable name to a type name."
  input DAE.ComponentRef inComponentRef;
  output Absyn.Path outPath;
algorithm
  outPath := match (inComponentRef)
    local
      String s,id;
      Absyn.Path path;
      DAE.ComponentRef cref;
    case (DAE.CREF_IDENT(ident = s,subscriptLst = {})) then Absyn.IDENT(s);
    case (DAE.CREF_QUAL(ident = id,componentRef = cref))
      equation
        path = componentRefToPath(cref);
      then
        Absyn.QUALIFIED(id,path);
  end match;
end componentRefToPath;

public function needToRebuild
  input String newFile;
  input String oldFile;
  input Real   buildTime;
  output Boolean buildNeeded;
algorithm
  buildNeeded := matchcontinue(newFile, oldFile, buildTime)
    local String newf,oldf; Real bt,nfmt;
    case ("","",bt) then true; // rebuild all the time if the function has no file!
    case (newf,oldf,bt)
      equation
        true = stringEq(newf, oldf); // the files should be the same!
        // the new file nf should have an older modification time than the last build
        SOME(nfmt) = System.getFileModificationTime(newf);
        true = realGt(bt, nfmt); // the file was not modified since last build
      then false;
    case (_,_,_) then true;
  end matchcontinue;
end needToRebuild;

public function isFunctionInCflist
"This function returns true if a function, named by an Absyn.Path,
  is present in the list of precompiled functions that can be executed
  in the interactive mode. If it returns true, it also returns the
  functionHandle stored in the cflist."
  input list<GlobalScript.CompiledCFunction> inTplAbsynPathTypesTypeLst;
  input Absyn.Path inPath;
  output Boolean outBoolean;
  output Integer outFuncHandle;
  output Real outBuildTime;
  output String outFileName;
algorithm
  (outBoolean,outFuncHandle,outBuildTime,outFileName) := matchcontinue (inTplAbsynPathTypesTypeLst,inPath)
    local
      Absyn.Path path1,path2;
      DAE.Type ty;
      list<GlobalScript.CompiledCFunction> rest;
      Boolean res;
      Integer handle;
      Real buildTime;
      String fileName;

    case ({},_) then (false, -1, -1.0, "");

    case ((GlobalScript.CFunction(path1,ty,handle,buildTime,fileName) :: rest),path2)
      equation
        true = Absyn.pathEqual(path1, path2);
      then
        (true, handle, buildTime, fileName);

    case ((GlobalScript.CFunction(path1,ty,_,_,_) :: rest),path2)
      equation
        false = Absyn.pathEqual(path1, path2);
        (res,handle,buildTime,fileName) = isFunctionInCflist(rest, path2);
      then
        (res,handle,buildTime,fileName);
  end matchcontinue;
end isFunctionInCflist;

/*
public function getComponentsWithUnkownArraySizes
"This function returns true if a class
 has unknown array sizes for a component"
  input SCode.Element cl;
  output list<SCode.Element> compElts;
algorithm
  compElts := matchcontinue (cl)
    local
      list<SCode.Element> rest;
      SCode.Element comp;
    // handle the empty things
    case ({}) then ({},{},{});
    // collect components
    case (( comp as SCode.COMPONENT(component=_) ) :: rest) then comp::splitElts(rest);
    // ignore others
    case (_ :: rest) then splitElts(rest);
  end matchcontinue;
end getComponentsWithUnkownArraySizes;

protected function transformFunctionArgumentsIntoModifications
"@author: adrpo
 This function transforms the arguments
 given to a function into a modification."
  input Env.Cache cache;
  input Env.Env env;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input SCode.Element inClass;
  input list<Absyn.Exp> inPositionalArguments;
  input list<Absyn.NamedArg> inNamedArguments;
  output Option<Absyn.Modification> absynOptMod;
algorithm
  absynOptMod := matchcontinue (cache, env, impl, inSymTab, inClass, inPositionalArguments, inNamedArguments)
    local
      Option<Absyn.Modification> m;
      list<Absyn.NamedArg> na;

    case (_, _, _, _, _,{},{}) then NONE();
    case (cache,env,impl,inSymTab,_,{},inNamedArguments)
      equation
        m = transformToModification(cache,env,impl,inSymTab,inNamedArguments);
      then m;
    case (cache,env,impl,inSymTab,inClass,inPositionalArguments,inNamedArguments)
      equation
        // TODO! FIXME! transform positional to named!
        //na = listAppend(inNamedArguments, transformPositionalToNamed(inClass, inPositionalArguments);
        m = transformToModification(cache,env,impl,inSymTab,inNamedArguments);
      then m;
  end matchcontinue;
end transformFunctionArgumentsIntoModifications;

protected function transformFunctionArgumentsIntoModifications
"@author: adrpo
 This function transforms the arguments
 given to a function into a modification."
  input Env.Cache cache;
  input Env.Env env;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input SCode.Element inClass;
  input list<Absyn.Exp> inPositionalArguments;
  input list<Absyn.NamedArg> inNamedArguments;
  output Option<Absyn.Modification> absynOptMod;
algorithm
  absynOptMod := matchcontinue (cache, env, impl, inSymTab, inClass, inPositionalArguments, inNamedArguments)
    local
      Option<Absyn.Modification> m;
    case (_, _, _, _, _,{},{}) then NONE();
    case (cache,env,impl,inSymTab,_,{},inNamedArguments)
      equation
        m = transformToModification(cache,env,impl,inSymTab,inNamedArguments);
      then m;
  end matchcontinue;
end transformFunctionArgumentsIntoModifications;
*/

protected function createDummyFarg
  input String name;
  output DAE.FuncArg farg;
algorithm
  farg := (name, DAE.T_UNKNOWN_DEFAULT, DAE.C_VAR(), NONE());
end createDummyFarg;

protected function transformModificationsToNamedArguments
  input SCode.Element c;
  input String prefix;
  output list<Absyn.NamedArg> namedArguments;
algorithm
  namedArguments := matchcontinue(c, prefix)
    local
      SCode.Mod mod;
      list<Absyn.NamedArg> nArgs;

    // fech modifications from the class if there are any
    case (SCode.CLASS(classDef = SCode.DERIVED(modifications = mod)), _)
      equation
        // transform modifications into function arguments and prefix the UNQUALIFIED component
        // references with the function prefix, here world.
        Debug.fprintln(Flags.STATIC, "Found modifications: " +& SCodeDump.printModStr(mod));
        /* modification elaboration doesn't work as World is not a package!
           anyhow we can deal with this in a different way, see below
        // build the prefix
        prefix = Prefix.PREFIX(Prefix.PRE(componentName, {}, Prefix.NOCOMPPRE()),
                               Prefix.CLASSPRE(SCode.VAR()));
        // elaborate the modification
        (cache, daeMod) = Mod.elabMod(cache, classEnv, prefix, mod, impl);
        Debug.fprintln(Flags.STATIC, "Elaborated modifications: " +& Mod.printModStr(daeMod));
        */
        nArgs = SCodeUtil.translateSCodeModToNArgs(prefix, mod);
        Debug.fprintln(Flags.STATIC, "Translated mods to named arguments: " +&
           stringDelimitList(List.map(nArgs, Dump.printNamedArgStr), ", "));
     then
       nArgs;
   // if there isn't a derived class, return nothing
   case (_, _)
     then {};
  end matchcontinue;
end transformModificationsToNamedArguments;

protected function addComponentFunctionsToCurrentEnvironment
"author: adrpo
  This function will copy the SCode.Element N given as input and the
  derived dependency into the current scope with name componentName.N"
 input Env.Cache inCache;
 input Env.Env inEnv;
 input SCode.Element scodeClass;
 input Env.Env inClassEnv;
 input String componentName;
 output Env.Cache outCache;
 output Env.Env outEnv;
algorithm
  (outCache, outEnv) := matchcontinue(inCache, inEnv, scodeClass, inClassEnv, componentName)
    local
      Env.Cache cache;
      Env.Env env, classEnv;
      SCode.Element sc, extendedClass;
      String cn, extendsCn;
      SCode.Ident name "the name of the class" ;
      SCode.Partial partialPrefix "the partial prefix" ;
      SCode.Encapsulated encapsulatedPrefix "the encapsulated prefix" ;
      SCode.Restriction restriction "the restriction of the class" ;
      SCode.ClassDef classDef "the class specification" ;
      Absyn.TypeSpec typeSpec "typeSpec: type specification" ;
      Absyn.Path extendsPath, newExtendsPath;
      SCode.Mod modifications ;
      SCode.Attributes attributes ;
      SCode.Comment cmt,comment "the translated comment from the Absyn" ;
      Option<Absyn.ArrayDim> arrayDim;
      Absyn.Info info;
      SCode.Prefixes prefixes;

    // handle derived component functions i.e. gravityAcceleration = gravityAccelerationTypes
    case(cache, env,
         sc as SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef as
         SCode.DERIVED(typeSpec as Absyn.TPATH(extendsPath, arrayDim), modifications, attributes),comment,info),
         classEnv, cn)
      equation
        // enableTrace();
        // change the class name from gravityAcceleration to be world.gravityAcceleration
        name = componentName +& "__" +& name;
        // remove modifications as they are added via transformModificationsToNamedArguments
        // also change extendsPath to world.gravityAccelerationTypes
        extendsCn = componentName +& "__" +& Absyn.pathString(extendsPath);
        newExtendsPath = Absyn.IDENT(extendsCn);
        sc = SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction,
               SCode.DERIVED(Absyn.TPATH(newExtendsPath, arrayDim), SCode.NOMOD(), attributes), comment,info);
        // add the class function to the environment
        env = Env.extendFrameC(env, sc);
        // lookup the derived class
        (_, extendedClass, _) = Lookup.lookupClass(cache, classEnv, extendsPath, true);
        // construct the extended class gravityAccelerationType
        // with a different name: world.gravityAccelerationType
        SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info) = extendedClass;
        // change the class name from gravityAccelerationTypes to be world.gravityAccelerationTypes
        name = componentName +& "__" +& name;
        // construct the extended class world.gravityAccelerationType
        sc = SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info);
        // add the extended class function to the environment
        env = Env.extendFrameC(env, sc);
      then (cache, env);
    // handle component functions made of parts
    case(cache, env, sc as SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info),
         classEnv, cn)
      equation
        // enableTrace();
        // change the class name from gravityAcceleration to be world.gravityAcceleration
        name = componentName +& "__" +& name;
        // remove modifications as they are added via transformModificationsToNamedArguments
        // also change extendsPath to world.gravityAccelerationTypes
        sc = SCode.CLASS(name, prefixes, encapsulatedPrefix, partialPrefix, restriction, classDef, cmt, info);
        // add the class function to the environment
        env = Env.extendFrameC(env, sc);
      then (cache, env);
  end matchcontinue;
end addComponentFunctionsToCurrentEnvironment;

public function elabCallArgs "
function: elabCallArgs
  Given the name of a function and two lists of expression and
  NamedArg respectively to be used
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,SOME((outExp,outProperties))) :=
  elabCallArgs2(inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,Util.makeStatefulBoolean(false),inInteractiveInteractiveSymbolTableOption,inPrefix,info);
  (outCache,outProperties) := elabCallArgsEvaluateArrayLength(outCache,inEnv,outProperties,inPrefix,info);
end elabCallArgs;

protected function elabCallArgsEvaluateArrayLength "Evaluate array dimensions in the returned type. For a call f(n) we might get Integer[n] back, where n is a parameter expression.
We consider any such parameter structural since it decides the dimension of an array.
We fall back to not evaluating the parameter if we fail since the dimension may not be structural (used in another call or reduction, etc)."
  input Env.Cache inCache;
  input Env.Env env;
  input DAE.Properties inProperties;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Properties outProperties;
algorithm
  (outCache,outProperties) := matchcontinue (inCache,env,inProperties,inPrefix,info)
    local
      Env.Cache cache;
      DAE.Type ty;
      /* Unsure if we want to evaluate dimensions inside function scope */
    case (_,Env.FRAME(scopeType = SOME(Env.CLASS_SCOPE()))::_,_,_,_)
      equation
        ty = Types.getPropType(inProperties);
        ((ty,(cache,_))) = Types.traverseType((ty,(inCache,env)),elabCallArgsEvaluateArrayLength2);
      then (cache,Types.setPropType(inProperties,ty));
    else (inCache,inProperties);
  end matchcontinue;
end elabCallArgsEvaluateArrayLength;

protected function elabCallArgsEvaluateArrayLength2
  input tuple<DAE.Type,tuple<Env.Cache,Env.Env>> inTpl;
  output tuple<DAE.Type,tuple<Env.Cache,Env.Env>> outTpl;
algorithm
  (outTpl) := matchcontinue (inTpl)
    local
      tuple<Env.Cache,Env.Env> tpl;
      DAE.Dimensions dims;
      DAE.TypeSource source;
      DAE.Type ty;
    case ((DAE.T_ARRAY(ty,dims,source),tpl))
      equation
        (dims,tpl) = List.mapFold(dims,elabCallArgsEvaluateArrayLength3,tpl);
      then ((DAE.T_ARRAY(ty,dims,source),tpl));
    else inTpl;
  end matchcontinue;
end elabCallArgsEvaluateArrayLength2;

protected function elabCallArgsEvaluateArrayLength3
  input DAE.Dimension inDim;
  input tuple<Env.Cache,Env.Env> inTpl;
  output DAE.Dimension outDim;
  output tuple<Env.Cache,Env.Env> outTpl;
algorithm
  (outDim,outTpl) := matchcontinue (inDim,inTpl)
    local
      Integer i;
      DAE.Exp exp;
      Env.Cache cache;
      Env.Env env;
    case (DAE.DIM_EXP(exp),(cache,env))
      equation
        (cache,Values.INTEGER(i),_) = Ceval.ceval(cache,env,exp,false,NONE(),Absyn.NO_MSG(),0);
      then (DAE.DIM_INTEGER(i),(cache,env));
    else (inDim,inTpl);
  end matchcontinue;
end elabCallArgsEvaluateArrayLength3;

protected function createInputVariableReplacements
"@author: adrpo
  This function will add the binding expressions for inputs
  to the variable replacement structure. This is needed to
  be able to replace input variables in default values.
  Example: ... "
  input list<Slot> inSlotLst;
  input VarTransform.VariableReplacements inVarsRepl;
  output VarTransform.VariableReplacements outVarsRepl;
algorithm
  outVarsRepl := matchcontinue(inSlotLst, inVarsRepl)
    local
      VarTransform.VariableReplacements i,o;
      String id;
      DAE.Exp e;
      list<Slot> rest;

    // handle empty
    case ({}, i) then i;

    // only interested in filled slots that have a optional expression
    case (SLOT(an = (id, _, _, _), slotFilled = true, expExpOption = SOME(e))::rest, i)
      equation
        o = VarTransform.addReplacement(i, ComponentReference.makeCrefIdent(id, DAE.T_UNKNOWN_DEFAULT, {}), e);
        o = createInputVariableReplacements(rest, o);
      then
        o;

    // try the next.
    case (_::rest, i)
      equation
        o = createInputVariableReplacements(rest, i);
      then
        o;
  end matchcontinue;
end createInputVariableReplacements;

protected function elabCallArgs2 "
function: elabCallArgs
  Given the name of a function and two lists of expression and
  NamedArg respectively to be used
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Util.StatefulBoolean stopElab;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
algorithm
  (outCache,expProps) :=
  matchcontinue (inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,stopElab,inInteractiveInteractiveSymbolTableOption,inPrefix,info)
    local
      DAE.Type t,outtype,restype,functype,tp1;
      list<DAE.FuncArg> fargs;
      Env.Env env_1,env_2,env,classEnv,recordEnv;
      list<Slot> slots,newslots,newslots2;
      list<DAE.Exp> args_1,args_2;
      list<DAE.Const> constlist, constInputArgs, constDefaultArgs;
      DAE.Const const;
      DAE.TupleConst tyconst;
      DAE.Properties prop,prop_1;
      SCode.Element cl,scodeClass,recordCl;
      Absyn.Path fn,fn_1,fqPath,utPath,fnPrefix,componentType,correctFunctionPath,functionClassPath,path;
      list<Absyn.Exp> args,t4;
      Absyn.Exp argexp;
      list<Absyn.NamedArg> nargs, translatedNArgs;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Type> typelist;
      DAE.Dimensions vect_dims;
      DAE.Exp call_exp,callExp,daeexp;
      list<String> t_lst,names;
      String fn_str,types_str,scope,pre_str,componentName,fnIdent;
      String s,name,argStr,stringifiedInstanceFunctionName;
      Env.Cache cache;
      DAE.Type tp;
      Prefix.Prefix pre;
      SCode.Restriction re;
      Integer index;
      list<DAE.Var> vars;
      list<SCode.Element> comps;
      Absyn.InnerOuter innerOuter;
      list<Absyn.Path> operNames;
      Absyn.ComponentRef cref;
      DAE.ComponentRef daecref;
      DAE.Function func;
      DAE.ElementSource source;

    /* Record constructors that might have come from Graphical expressions with unknown array sizes */
    /*
     * adrpo: HACK! HACK! TODO! remove this case if records with unknown sizes can be instantiated
     * this could be also fixed by transforming the function call arguments into modifications and
     * send the modifications as an option in Lookup.lookup* functions!
     */
    case (cache,env,fn,args,nargs,impl,_,st,pre,_)
      equation
        (cache,cl as SCode.CLASS(restriction = SCode.R_PACKAGE()),_) =
           Lookup.lookupClass(cache, env, Absyn.IDENT("GraphicalAnnotationsProgram____"), false);
        (cache,cl as SCode.CLASS(name = name, restriction = SCode.R_RECORD()),env_1) = Lookup.lookupClass(cache, env, fn, false);
        (cache,cl,env_2) = Lookup.lookupRecordConstructorClass(cache, env_1 /* env */, fn);
        (comps,_::names) = SCode.getClassComponents(cl); // remove the fist one as it is the result!
        /*
        (cache,(t as (DAE.T_FUNCTION(fargs,(outtype as (DAE.T_COMPLEX(complexClassType as ClassInf.RECORD(name),_,_,_),_))),_)),env_1)
          = Lookup.lookupType(cache, env, fn, SOME(info));
        */
        fargs = List.map(names, createDummyFarg);
        slots = makeEmptySlots(fargs);
        (cache,args_1,newslots,constInputArgs,_) = elabInputArgs(cache, env, args, nargs, slots, false /*checkTypes*/ ,impl,NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),  {},st,pre,info);
        (cache,newslots2,constDefaultArgs,_) = fillGraphicsDefaultSlots(cache, newslots, cl, env_2, impl, {}, pre, info);
        constlist = listAppend(constInputArgs, constDefaultArgs);
        const = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        args_2 = expListFromSlots(newslots2);

        tp = complexTypeFromSlots(newslots2,ClassInf.UNKNOWN(Absyn.IDENT("")));
        //tyconst = elabConsts(outtype, const);
        //prop = getProperties(outtype, tyconst);
      then
        (cache,SOME((DAE.CALL(fn,args_2,DAE.CALL_ATTR(tp,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),DAE.PROP(DAE.T_UNKNOWN_DEFAULT,DAE.C_CONST()))));

    // adrpo: deal with function call via an instance: MultiBody world.gravityAcceleration
    case (cache, env, fn, args, nargs, impl, _, st,pre,_)
      equation
        fnPrefix = Absyn.stripLast(fn); // take the prefix: word
        fnIdent = Absyn.pathLastIdent(fn); // take the suffix: gravityAcceleration
        Absyn.IDENT(componentName) = fnPrefix; // see that is just a name TODO! this might be a path
        (_, _, SCode.COMPONENT(
          prefixes = SCode.PREFIXES(innerOuter=innerOuter),
          typeSpec = Absyn.TPATH(componentType, _)),_, _, _) =
          Lookup.lookupIdent(cache, env, componentName); // search for the component
        // join the type with the function name: Modelica.Mechanics.MultiBody.World.gravityAcceleration
        functionClassPath = Absyn.joinPaths(componentType, Absyn.IDENT(fnIdent));

        Debug.fprintln(Flags.STATIC, "Looking for function: " +& Absyn.pathString(fn));
        // lookup the function using the correct typeOf(world).functionName
        Debug.fprintln(Flags.STATIC, "Looking up class: " +& Absyn.pathString(functionClassPath));
        (_, scodeClass, classEnv) = Lookup.lookupClass(cache, env, functionClassPath, true);
        Util.setStatefulBoolean(stopElab,true);
        // see if class scodeClass is derived and then
        // take the applied modifications and transform
        // them into function arguments by prefixing them
        // with the component reference (here world)
        // Example:
        //   The derived function:
        //     function gravityAcceleration = gravityAccelerationTypes(
        //                  gravityType = gravityType,
        //                  g = g * Modelica.Math.Vectors.normalize(n),
        //                  mue = mue);
        //   The actual call (that we are handling here):
        //     g_0 = world.gravityAcceleration(frame_a.r_0 + Frames.resolve1(frame_a.R, r_CM));
        //   Will be rewriten to:
        //     g_0 = world.gravityAcceleration(frame_a.r_0 + Frames.resolve1(frame_a.R, r_CM),
        //                  gravityType = world.gravityType,
        //                  g = world.g*Modelica.Math.Vectors.normalize(world.n, 1E-013),
        //                  mue = world.mue));
        // if the class is derived translate modifications to named arguments
        translatedNArgs = transformModificationsToNamedArguments(scodeClass, componentName);
        (cache, env) = addComponentFunctionsToCurrentEnvironment(cache, env, scodeClass, classEnv, componentName);
        // transform Absyn.QUALIFIED("world", Absyn.IDENT("gravityAcceleration")) to
        // Absyn.IDENT("world.gravityAcceleration").
        stringifiedInstanceFunctionName = componentName +& "__" +& SCode.className(scodeClass);
        correctFunctionPath = Absyn.IDENT(stringifiedInstanceFunctionName);
        // use the extra arguments if any
        nargs = listAppend(nargs, translatedNArgs);
        // call the class normally
        (cache,call_exp,prop_1) = elabCallArgs(cache, env, correctFunctionPath, args, nargs, impl, st,pre,info);
      then
        (cache,SOME((call_exp,prop_1)));

    // Record constructors, user defined or implicit, try the hard stuff first
    case (cache,env,fn,args,nargs,impl,_,st,pre,_)
      equation
        // For unrolling errors if an overloaded 'constructor' matches later.
        ErrorExt.setCheckpoint("RecordConstructor");

        (_,recordCl,recordEnv) = Lookup.lookupClass(cache, env, fn, false);
        true = MetaUtil.classHasRestriction(recordCl, SCode.R_RECORD());


        (cache,func) = Inst.getRecordConstructorFunction(cache,env,fn);

        DAE.RECORD_CONSTRUCTOR(path,tp1,source) = func;
        DAE.T_FUNCTION(fargs, outtype, _, {path}) = tp1;


        slots = makeEmptySlots(fargs);
        (cache,args_1,newslots,constInputArgs,_) = elabInputArgs(cache,env, args, nargs, slots, true  ,impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),  {},st,pre,info);

        newslots2 = List.map1(newslots,fillDefaultSlot,info);
        vect_dims = slotsVectorizable(newslots2);

        constlist = constInputArgs;
        const = List.fold(constlist, Types.constAnd, DAE.C_CONST());

        tyconst = elabConsts(outtype, const);
        prop = getProperties(outtype, tyconst);

        args_2 = expListFromSlots(newslots2);
        callExp = DAE.CALL(path,args_2,DAE.CALL_ATTR(outtype,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

        (call_exp,prop_1) = vectorizeCall(callExp, vect_dims, newslots2, prop, info);
        expProps = SOME((call_exp,prop_1));

        Util.setStatefulBoolean(stopElab,true);
        ErrorExt.rollBack("RecordConstructor");

      then
        (cache,expProps);

        /* If the default constructor failed look for
        overloaded Record constructors (operators), user defined.
        mahge:TODO move this to a function and call it from above.
        avoids uneccesary lookup since we already have a record.*/
    case (cache,env,fn,args,nargs,impl,_,st,pre,_)
      equation

        false = Util.getStatefulBoolean(stopElab);

        (cache,recordCl,recordEnv) = Lookup.lookupClass(cache,env,fn, false);
        true = MetaUtil.classHasRestriction(recordCl, SCode.R_RECORD());

        fn_1 = Absyn.joinPaths(fn,Absyn.IDENT("'constructor'"));
        (cache,recordCl,recordEnv) = Lookup.lookupClass(cache,recordEnv,fn_1, false);
        true = SCode.isOperator(recordCl);

        operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(recordCl);
        (cache,typelist as _::_) = Lookup.lookupFunctionsListInEnv(cache, recordEnv, operNames, info, {});

        Util.setStatefulBoolean(stopElab,true);
        (cache,expProps) = elabCallArgs3(cache,env,typelist,fn_1,args,nargs,impl,st,pre,info);

        ErrorExt.rollBack("RecordConstructor");

      then
        (cache,expProps);

    /* ------ */
    case (cache,env,fn,args,nargs,impl,_,st,pre,_) /* Metamodelica extension, added by simbj */
      equation

        ErrorExt.delCheckpoint("RecordConstructor");

        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopElab);
        (cache,t as DAE.T_METARECORD(utPath=utPath,index=index,fields=vars,source={fqPath}),env_1) = Lookup.lookupType(cache, env, fn, NONE());
        Util.setStatefulBoolean(stopElab,true);
        (cache,expProps) = elabCallArgsMetarecord(cache,env,t,args,nargs,impl,stopElab,st,pre,info);
      then
        (cache,expProps);

      /* ..Other functions */
    case (cache,env,fn,args,nargs,impl,_,st,pre,_)
      equation

        ErrorExt.setCheckpoint("elabCallArgs2FunctionLookup");

        false = Util.getStatefulBoolean(stopElab);
        (cache,typelist as _::_) = Lookup.lookupFunctionsInEnv(cache, env, fn, info)
        "PR. A function can have several types. Taking an array with
         different dimensions as parameter for example. Because of this we
         cannot just lookup the function name and trust that it
         returns the correct function. It returns just one
         functiontype of several possibilites. The solution is to send
         in the function type of the user function and check both the
         function name and the function\'s type." ;
        Util.setStatefulBoolean(stopElab,true);
        (cache,expProps) = elabCallArgs3(cache,env,typelist,fn,args,nargs,impl,st,pre,info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");

      then
        (cache,expProps);

    case (cache,env,fn,args,nargs,impl,_,st,pre,_) /* no matching type found, with -one- candidate */
      equation
        (cache,typelist as {tp1}) = Lookup.lookupFunctionsInEnv(cache, env, fn, info);
        (cache,args_1,constlist,restype,functype,vect_dims,slots) =
          elabTypes(cache, env, args, nargs, typelist, false/* Do not check types*/, impl,NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), st,pre,info);
        argStr = ExpressionDump.printExpListStr(args_1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = Absyn.pathString(fn) +& "(" +& argStr +& ")\nof type\n  " +& Types.unparseType(functype);
        types_str = "\n  " +& Types.unparseType(tp1);
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,pre_str,types_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,args,nargs,impl,_,st,pre,_) /* class found; not function */
      equation
        (cache,SCode.CLASS(restriction = re),_) = Lookup.lookupClass(cache,env,fn,false);
        false = SCode.isFunctionRestriction(re);
        fn_str = Absyn.pathString(fn);
        s = SCodeDump.restrString(re);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_GOT_CLASS, {fn_str,s}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,args,nargs,impl,_,st,pre,_) /* no matching type found, with candidates */
      equation
        (cache,typelist as _::_::_) = Lookup.lookupFunctionsInEnv(cache,env, fn, info);
        t_lst = List.map(typelist, Types.unparseType);
        fn_str = Absyn.pathString(fn);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        types_str = stringDelimitList(t_lst, "\n -");
        //fn_str = fn_str +& " in component " +& pre_str;
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,pre_str,types_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    // In Optimica there is an odd syntax like for eg.,  x(finalTime) + y(finalTime); where both x and y are normal variables
    // not functions. So it is not really a call Exp but the compiler treats it as if it is up until this point.
    // This is a kind of trick to handle that.
    case (cache,env,fn,{argexp as Absyn.CREF(Absyn.CREF_IDENT(name,_))},_,impl,_,st,pre,_)
      equation
        true = Config.acceptOptimicaGrammar();
        cref = Absyn.pathToCref(fn);

        (cache,SOME((daeexp as DAE.CREF(daecref,tp),prop,_))) = elabCref(cache,env, cref, impl,true,pre,info);
        ErrorExt.rollBack("elabCallArgs2FunctionLookup");

        daeexp = DAE.CREF(DAE.OPTIMICA_ATTR_INST_CREF(daecref,name), tp);
        expProps = SOME((daeexp,prop));
      then
        (cache,expProps);

    case (cache,env,fn,args,nargs,impl,_,st,pre,_)
      equation
        t4 = args;
        failure((_,_,_) = Lookup.lookupType(cache,env, fn, NONE())) "msg" ;
        scope = Env.printEnvPathStr(env) +& " (looking for a function or record)";
        fn_str = Absyn.pathString(fn);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {fn_str,scope}, info); // No need to add prefix because only depends on scope?

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,args,nargs,impl,_,st,pre,_) /* no matching type found, no candidates. */
      equation
        (cache,{}) = Lookup.lookupFunctionsInEnv(cache,env,fn,info);
        fn_str = Absyn.pathString(fn);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = fn_str +& " in component " +& pre_str;
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE, {fn_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,args,nargs,impl,_,st,pre,_)
      equation
        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabCallArgs failed on: " +& Absyn.pathString(fn) +& " in env: " +& Env.printEnvPathStr(env));
      then
        fail();
  end matchcontinue;
end elabCallArgs2;

protected function elabCallArgs3
  "Elaborates the input given a set of viable function candidates, and vectorizes the arguments+performs type checking"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Type> typelist;
  input Absyn.Path fn;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
protected
  DAE.Exp callExp,call_exp;
  list<DAE.Exp> args_1,args_2;
  list<DAE.Const> constlist;
  DAE.Const const;
  DAE.Type restype,functype;
  DAE.FunctionBuiltin isBuiltin;
  DAE.FunctionParallelism funcParal;
  Boolean isPure,tuple_,builtin,isImpure;
  DAE.InlineType inlineType;
  Absyn.Path fn_1;
  DAE.Properties prop,prop_1;
  DAE.Type tp;
  DAE.TupleConst tyconst;
  DAE.Dimensions vect_dims;
  list<Slot> slots,slots2;
  DAE.FunctionTree functionTree;
  Util.Status status;
  Env.Cache cache;
  Env.Env env;
  Boolean didInline;
  Boolean b;
  IsExternalObject isExternalObject;
algorithm
  (cache,b) := isExternalObjectFunction(inCache,inEnv,fn);
  isExternalObject := Util.if_(b and not Env.inFunctionScope(inEnv), IS_EXTERNAL_OBJECT_MODEL_SCOPE(), NOT_EXTERNAL_OBJECT_MODEL_SCOPE());
  (cache,
   args_1,
   constlist,
   restype,
   functype as DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isOpenModelicaPure=isPure,
                                                                         isImpure=isImpure,
                                                                         inline=inlineType,
                                                                         functionParallelism=funcParal)),
   vect_dims,
   slots) := elabTypes(cache, inEnv, args, nargs, typelist, true/* Check types*/, impl,isExternalObject,st,pre,info)
   "The constness of a function depends on the inputs. If all inputs are constant the call itself is constant." ;

  (fn_1,functype) := deoverloadFuncname(fn, functype);
  tuple_ := isTuple(restype);
  (isBuiltin,builtin,fn_1) := isBuiltinFunc(fn_1,functype);
  inlineType := inlineBuiltin(isBuiltin,inlineType);

  //check the env to see if a call to a parallel or kernle function is a valid one.
  true := isValidWRTParallelScope(fn,builtin,funcParal,inEnv,info);

  const := List.fold(constlist, Types.constAnd, DAE.C_CONST());
  const := Util.if_((Flags.isSet(Flags.RML) and not builtin) or (not isPure), DAE.C_VAR(), const) "in RML no function needs to be ceval'ed; this speeds up compilation significantly when bootstrapping";
  (cache,const) := determineConstSpecialFunc(cache,inEnv,const,fn_1);
  tyconst := elabConsts(restype, const);
  prop := getProperties(restype, tyconst);
  tp := Types.simplifyType(restype);
  // adrpo: 2011-09-30 NOTE THAT THIS WILL NOT ADD DEFAULT ARGS
  //                   FROM extends (THE BASE CLASS)
  (cache,args_2,slots2) := addDefaultArgs(cache,inEnv,args_1,fn_1,slots,impl,pre,info);
  // DO NOT CHECK IF ALL SLOTS ARE FILLED!
  true := List.fold(slots2, slotAnd, true);
  callExp := DAE.CALL(fn_1,args_2,DAE.CALL_ATTR(tp,tuple_,builtin,isImpure,inlineType,DAE.NO_TAIL()));
  //ExpressionDump.dumpExpWithTitle("function elabCallArgs3: ", callExp);

  // create a replacement for input variables -> their binding
  //inputVarsRepl = createInputVariableReplacements(slots2, VarTransform.emptyReplacements());
  //print("Repls: " +& VarTransform.dumpReplacementsStr(inputVarsRepl) +& "\n");
  // replace references to inputs in the arguments
  //callExp = VarTransform.replaceExp(callExp, inputVarsRepl, NONE());

  //debugPrintString = Util.if_(Util.isEqual(DAE.NORM_INLINE,inline)," Inline: " +& Absyn.pathString(fn_1) +& "\n", "");print(debugPrintString);
  (call_exp,prop_1) := vectorizeCall(callExp, vect_dims, slots2, prop, info);
  /* Instantiate the function and add to dae function tree*/
  (cache,status) := instantiateDaeFunction(cache,inEnv,fn_1,builtin,NONE(),true);
  /* Instantiate any implicit record constructors needed and add them to the dae function tree */
  cache := instantiateImplicitRecordConstructors(cache, inEnv, args_1, st);
  functionTree := Env.getFunctionTree(cache);
  ((call_exp,(_,didInline))) := Inline.inlineCall((call_exp,((SOME(functionTree),{DAE.BUILTIN_EARLY_INLINE(),DAE.EARLY_INLINE()}),false)));
  (call_exp,_) := ExpressionSimplify.condsimplify(didInline,call_exp);
  didInline := didInline and (not Config.acceptMetaModelicaGrammar() /* Some weird errors when inlining. Becomes boxed even if it shouldn't... */);
  prop_1 := Debug.bcallret2(didInline, Types.setTypeInProps, restype, prop_1, prop_1);
  expProps := Util.if_(Util.isSuccess(status),SOME((call_exp,prop_1)),NONE());
  outCache := cache;
end elabCallArgs3;

protected function inlineBuiltin
  input DAE.FunctionBuiltin isBuiltin;
  input DAE.InlineType inlineType;
  output DAE.InlineType outInlineType;
algorithm
  outInlineType := match (isBuiltin,inlineType)
    case (DAE.FUNCTION_BUILTIN_PTR(),_)
      then DAE.BUILTIN_EARLY_INLINE();
    else inlineType;
  end match;
end inlineBuiltin;

protected function isValidWRTParallelScope
  input Absyn.Path inFn;
  input Boolean isBuiltin;
  input DAE.FunctionParallelism inFuncParallelism;
  input Env.Env inEnv;
  input Absyn.Info inInfo;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inFn,isBuiltin,inFuncParallelism,inEnv,inInfo)
  local
    String scopeName, errorString;
    list<Env.Frame> restFrames;


    // non-parallel builtin function call is OK everywhere.
    case(_,true,DAE.FP_NON_PARALLEL(), _, _)
      then true;

    // If we have a function call in an implicit scope type, then go
    // up recursively to find the actuall scope and then check.
    // But parfor scope is a parallel type so is handled differently.
    case(_,_,_, Env.FRAME(name = SOME(scopeName))::restFrames, _)
      equation
        true = listMember(scopeName, Env.implicitScopeNames);
        false = stringEq(scopeName, Env.parForScopeName);
      then isValidWRTParallelScope(inFn,isBuiltin,inFuncParallelism,restFrames,inInfo);

    // This two are common cases so keep them at the top.
    // normal(non parallel) function call in a normal scope (function and class scopes) is OK.
    case(_,_,DAE.FP_NON_PARALLEL(), Env.FRAME(scopeType = SOME(Env.CLASS_SCOPE()))::_, _)
      then true;
    case(_,_,DAE.FP_NON_PARALLEL(), Env.FRAME(scopeType = SOME(Env.FUNCTION_SCOPE()))::_, _)
      then true;

    // Normal function call in a prallel scope is error, if it is not a built-in function.
    case(_,_,DAE.FP_NON_PARALLEL(), Env.FRAME(name = SOME(scopeName), scopeType = SOME(Env.PARALLEL_SCOPE()))::_, _)
      equation

        errorString = "\n" +&
             "- Non-Parallel function '" +& Absyn.pathString(inFn) +&
             "' can not be called from a parallel scope." +& "\n" +&
             "- Here called from :" +& scopeName +& "\n" +&
             "- Please declare the function as parallel function.";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;


    // parallel function call in a parallel scope (kernel function, parallel function) is OK.
    // Except when it is calling itself, recurssion
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), Env.FRAME(name = SOME(scopeName), scopeType = SOME(Env.PARALLEL_SCOPE()))::_, _)
      equation
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        false = stringEqual(scopeName,Absyn.pathString(inFn));
      then true;

    // If the above case failed (parallel function recurssion) this will print the error message
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), Env.FRAME(name = SOME(scopeName), scopeType = SOME(Env.PARALLEL_SCOPE()))::_, _)
      equation
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        true = stringEqual(scopeName,Absyn.pathString(inFn));
        errorString = "\n" +&
             "- Parallel function '" +& Absyn.pathString(inFn) +&
             "' can not call itself. Recurrsion is not allowed for parallel functions currently." +& "\n" +&
             "- Parallel functions can only be called from: 'kernel' functions," +&
             " OTHER 'parallel' functions (no recurrsion) or from a body of a" +&
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    // parallel function call in a parfor scope is OK.
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), Env.FRAME(name = SOME(scopeName))::_, _)
      equation
        true = stringEqual(scopeName, Env.parForScopeName);
      then true;

    //parallel function call in non parallel scope types is error.
    case(_,_,DAE.FP_PARALLEL_FUNCTION(),Env.FRAME(name = SOME(scopeName))::_,_)
      equation
        errorString = "\n" +&
             "- Parallel function '" +& Absyn.pathString(inFn) +&
             "' can not be called from a non parallel scope '" +& scopeName +& "'.\n" +&
             "- Parallel functions can only be called from: 'kernel' functions," +&
             " other 'parallel' functions (no recurrsion) or from a body of a" +&
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    // Kernel functions should not call themselves.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), Env.FRAME(name = SOME(scopeName))::_, _)
      equation
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        true = stringEqual(scopeName,Absyn.pathString(inFn));
        errorString = "\n" +&
             "- Kernel function '" +& Absyn.pathString(inFn) +&
             "' can not call itself. " +& "\n" +&
             "- Recurrsion is not allowed for Kernel functions. ";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    //kernel function call in a parallel scope (kernel function, parallel function) is Error.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), Env.FRAME(name = SOME(scopeName), scopeType = SOME(Env.PARALLEL_SCOPE()))::_, _)
      equation
        errorString = "\n" +&
             "- Kernel function '" +& Absyn.pathString(inFn) +&
             "' can not be called from a parallel scope '" +& scopeName +& "'.\n" +&
             "- Kernel functions CAN NOT be called from: 'kernel' functions," +&
             " 'parallel' functions or from a body of a" +&
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    //kernel function call in a parfor loop is Error too (similar to above). just different error message.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), Env.FRAME(name = SOME(scopeName))::_, _)
      equation
        true = stringEqual(scopeName, Env.parForScopeName);
        errorString = "\n" +&
             "- Kernel function '" +& Absyn.pathString(inFn) +&
             "' can not be called from inside parallel for (parfor) loop body." +& "'.\n" +&
             "- Kernel functions CAN NOT be called from: 'kernel' functions," +&
             " 'parallel' functions or from a body of a" +&
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then false;

    // Kernel function call in a non-parallel scope is OK.
    // Except when it is calling itself, recurssion
    case(_,_,DAE.FP_KERNEL_FUNCTION(), Env.FRAME(name = SOME(scopeName))::_, _)
      equation
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        false = stringEqual(scopeName,Absyn.pathString(inFn));
      then true;

    case(_,_,_,_,_) then true;
        /*
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_NON_PARALLEL(), Env.FRAME(scopeType = Env.FUNCTION_SCOPE())) then();
    //Normal (non parallel) function call in a normal class scope is OK.
    case(DAE.FP_NON_PARALLEL(), Env.FRAME(scopeType = Env.CLASS_SCOPE())) then();
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_NON_PARALLEL(), Env.FRAME(scopeType = Env.FUNCTION_SCOPE())) then();
    //Normal (non parallel) function call in a normal class scope is OK.
    case(DAE.FP_KERNEL_FUNCTION(), Env.FRAME(scopeType = Env.CLASS_SCOPE())) then();
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_KERNEL_FUNCTION(), Env.FRAME(scopeType = Env.FUNCTION_SCOPE())) then();
    */

 end matchcontinue;
end isValidWRTParallelScope;

protected function elabCallArgsMetarecord
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Type inType;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Util.StatefulBoolean stopElab;
  input Option<GlobalScript.SymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
algorithm
  (outCache,expProps) :=
  matchcontinue (inCache,inEnv,inType,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,stopElab,inInteractiveInteractiveSymbolTableOption,inPrefix,info)
    local
      DAE.Type t;
      list<DAE.FuncArg> fargs;
      Env.Cache cache;
      Env.Env env;
      list<Slot> slots,newslots;
      list<DAE.Exp> args_1,args_2;
      list<DAE.Const> constlist;
      DAE.Const const;
      DAE.TupleConst tyconst;
      DAE.Properties prop;
      Absyn.Path fqPath,utPath;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Type> tys;
      DAE.Exp daeExp;
      String fn_str;
      String args_str,str;
      Prefix.Prefix pre;
      Integer index;
      list<String> fieldNames;
      list<DAE.Var> vars;
      Boolean knownSingleton;

    case (cache,env,t as DAE.T_METARECORD(fields=vars,source={fqPath}),args,nargs,impl,_,st,pre,_)
      equation
        tys = List.map(vars, Types.getVarType);
        DAE.TYPES_VAR(name = str) = List.selectFirst(vars, Types.varHasMetaRecordType);
        fn_str = Absyn.pathString(fqPath);
        Error.addSourceMessage(Error.METARECORD_CONTAINS_METARECORD_MEMBER,{fn_str,str},info);
      then (cache,NONE());

    case (cache,env,t as DAE.T_METARECORD(fields=vars,source={fqPath}),args,nargs,impl,_,st,pre,_)
      equation
        false = listLength(vars) == listLength(args) + listLength(nargs);
        fn_str = Types.unparseType(t);
        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS,{fn_str},info);
      then (cache,NONE());

    case (cache,env,t as DAE.T_METARECORD(index=index,utPath=utPath,fields=vars,knownSingleton=knownSingleton,source={fqPath}),args,nargs,impl,_,st,pre,_)
      equation
        fieldNames = List.map(vars, Types.getVarName);
        tys = List.map(vars, Types.getVarType);
        fargs = List.thread4Tuple(fieldNames, tys, List.fill(DAE.C_VAR(),listLength(tys)), List.fill(NONE(),listLength(tys)));
        slots = makeEmptySlots(fargs);
        (cache,args_1,newslots,constlist,_) = elabInputArgs(cache,env, args, nargs, slots, true ,impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), {}, st, pre, info);
        const = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        tyconst = elabConsts(t, const);
        t = DAE.T_METAUNIONTYPE({},knownSingleton,{utPath});
        prop = getProperties(t, tyconst);
        true = List.fold(newslots, slotAnd, true);
        args_2 = expListFromSlots(newslots);
      then
        (cache,SOME((DAE.METARECORDCALL(fqPath,args_2,fieldNames,index),prop)));

    // MetaRecord failure
    case (cache,env,DAE.T_METARECORD(utPath=utPath,index=index,fields=vars,source={fqPath}),args,nargs,impl,_,st,pre,_)
      equation
        (cache,daeExp,prop,_) = elabExp(cache,env,Absyn.TUPLE(args),false,st,false,pre,info);
        tys = List.map(vars, Types.getVarType);
        str = "Failed to match types:\n    actual:   " +& Types.unparseType(Types.getPropType(prop)) +& "\n    expected: " +& Types.unparseType(DAE.T_TUPLE(tys,DAE.emptyTypeSource));
        fn_str = Absyn.pathString(fqPath);
        Error.addSourceMessage(Error.META_RECORD_FOUND_FAILURE,{fn_str,str},info);
      then (cache,NONE());

    // MetaRecord failure (args).
    case (cache,env,t,args,nargs,impl,_,st,pre,_)
      equation
        {fqPath} = Types.getTypeSource(t);
        args_str = "Failed to elaborate arguments " +& Dump.printExpStr(Absyn.TUPLE(args));
        fn_str = Absyn.pathString(fqPath);
        Error.addSourceMessage(Error.META_RECORD_FOUND_FAILURE,{fn_str,args_str},info);
      then (cache,NONE());
  end matchcontinue;
end elabCallArgsMetarecord;

protected uniontype ForceFunctionInst
  record FORCE_FUNCTION_INST "Used when blocking function instantiation to instantiate the function anyway" end FORCE_FUNCTION_INST;
  record NORMAL_FUNCTION_INST "Used when blocking function instantiation to instantiate the function anyway" end NORMAL_FUNCTION_INST;
end ForceFunctionInst;

public function instantiateDaeFunction "help function to elabCallArgs. Instantiates the function as a dae and adds it to the
functiontree of a newly created dae"
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path name;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  output Env.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := instantiateDaeFunction2(inCache, env, name, builtin, clOpt, Error.getNumErrorMessages(), printErrorMsg, Util.isSome(getGlobalRoot(Global.instOnlyForcedFunctions)), NORMAL_FUNCTION_INST());
end instantiateDaeFunction;

public function instantiateDaeFunctionForceInst "help function to elabCallArgs. Instantiates the function as a dae and adds it to the
functiontree of a newly created dae"
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path name;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  output Env.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := instantiateDaeFunction2(inCache, env, name, builtin, clOpt, Error.getNumErrorMessages(), printErrorMsg, Util.isSome(getGlobalRoot(Global.instOnlyForcedFunctions)), FORCE_FUNCTION_INST());
end instantiateDaeFunctionForceInst;

protected function instantiateDaeFunction2 "help function to elabCallArgs. Instantiates the function as a dae and adds it to the
functiontree of a newly created dae"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inName;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Integer numError "if errors were added, do not add a generic error message";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  input Boolean instOnlyForcedFunctions;
  input ForceFunctionInst forceFunctionInst;
  output Env.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := matchcontinue(inCache,inEnv,inName,builtin,clOpt,numError,printErrorMsg,instOnlyForcedFunctions,forceFunctionInst)
    local
      Env.Cache cache;
      Env.Env env;
      SCode.Element cl;
      String pathStr,envStr;
      DAE.ComponentRef cref;
      Absyn.Path name;

    // Skip function instantiation if we set those flags
    case(cache,env,name,_,_,_,_,true,NORMAL_FUNCTION_INST())
      equation
        failure(Absyn.IDENT(_) = name); // Don't skip builtin functions or functions in the same package; they are useful to inline
        // print("Skipping: " +& Absyn.pathString(name) +& "\n");
      then (cache,Util.SUCCESS());

    // Builtin functions skipped
    case(cache,env,name,true,_,_,_,_,_) then (cache,Util.SUCCESS());

    // External object functions skipped
    case(cache,env,name,_,_,_,_,_,_)
      equation
        (_,true) = isExternalObjectFunction(cache,env,name);
      then (cache,Util.SUCCESS());

    // Recursive calls (by looking at envinronment) skipped
    case(cache,env,name,_,NONE(),_,_,_,_)
      equation
        false = Env.isTopScope(env);
        true = Absyn.pathSuffixOf(name,Env.getEnvName(env));
      then (cache,Util.SUCCESS());

    // Recursive calls (by looking in cache) skipped
    case(cache,env,name,_,_,_,_,_,_)
      equation
        (cache,cl,env) = Lookup.lookupClass(cache,env,name,false);
        (cache,name) = Inst.makeFullyQualified(cache,env,name);
        Env.checkCachedInstFuncGuard(cache,name);
      then (cache,Util.SUCCESS());

    // class must be looked up
    case(cache,env,name,_,NONE(),_,_,_,_)
      equation
        (cache,cl,env) = Lookup.lookupClass(cache,env,name,false);
        (cache,name) = Inst.makeFullyQualified(cache,env,name);
        cache = Env.addCachedInstFuncGuard(cache,name);
        (cache,env,_) = Inst.implicitFunctionInstantiation(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),cl,{});
      then (cache,Util.SUCCESS());

    // class already available
    case(cache,env,name,_,SOME(cl),_,_,_,_)
      equation
        (cache,name) = Inst.makeFullyQualified(cache,env,name);
        (cache,env,_) = Inst.implicitFunctionInstantiation(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),cl,{});
      then (cache,Util.SUCCESS());

    // call to function reference variable
    case (cache,env,name,_,NONE(),_,_,_,_)
      equation
        cref = pathToComponentRef(name);
        (cache,_,DAE.T_FUNCTION(funcArg = _),_,_,_,env,_,_) = Lookup.lookupVar(cache,env,cref);
      then (cache,Util.SUCCESS());

    case(cache,env,name,_,_,_,true,_,_)
      equation
        true = Error.getNumErrorMessages() == numError;
        envStr = Env.printEnvPathStr(env);
        pathStr = Absyn.pathString(name);
        Error.addMessage(Error.GENERIC_INST_FUNCTION, {pathStr, envStr});
      then fail();

    else (inCache,Util.FAILURE());
  end matchcontinue;
end instantiateDaeFunction2;

protected function instantiateImplicitRecordConstructors
  "Given a list of arguments to a function, this function checks if any of the
  arguments are component references to a record instance, and instantiates the
  record constructors for those components. These are implicit record
  constructors, because they are not explicitly called, but are needed when code
  is generated for record instances as function input arguments."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Exp> args;
  input Option<GlobalScript.SymbolTable> st;
  output Env.Cache outCache;
algorithm
  outCache := matchcontinue(inCache, inEnv, args, st)
    local
      list<DAE.Exp> rest_args;
      Absyn.Path record_name;
      Env.Cache cache;
    case (_, _, _, SOME(_)) then inCache;
    case (_, _, {}, _) then inCache;
    case (_, _, DAE.CREF(ty = DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path = record_name))) :: rest_args, _)
      equation
        (cache,Util.SUCCESS()) = instantiateDaeFunction(inCache, inEnv, record_name, false,NONE(), false);
        cache = instantiateImplicitRecordConstructors(cache, inEnv, rest_args, NONE());
      then cache;
    case (_, _, _ :: rest_args, _)
      equation
        cache = instantiateImplicitRecordConstructors(inCache, inEnv, rest_args, NONE());
      then cache;
  end matchcontinue;
end instantiateImplicitRecordConstructors;

protected function addDefaultArgs "adds default values (from slots) to argument list of function call.
This is needed because when generating C-code all arguments must be present in the function call.

If in future C++ code is generated instead, this is not required, since C++ allows default values for arguments.
Not true: Mutable default values still need to be constructed. C++ only helps
if we also enforce all input args immutable."
  input Env.Cache inCache;
  input Env.Env env;
  input list<DAE.Exp> inArgs;
  input Absyn.Path fn;
  input list<Slot> slots;
  input Boolean impl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Exp> outArgs;
  output list<Slot> outSlots;
algorithm
  (outCache,outArgs,outSlots) := match(inCache,env,inArgs,fn,slots,impl,inPrefix,info)
    local Env.Cache cache;
      list<DAE.Exp> args_2;
      list<Slot> slots2;
      Prefix.Prefix pre;

    // If we find a class
    case(cache,_,_,_,_,_,pre,_)
      equation
        // We need the class to fill default slots
        // (cache,cl,env_2) = Lookup.lookupClass(cache,env,fn,false);
        slots2 = List.map1(slots,fillDefaultSlot,info);
        // Update argument list to include default values.
        args_2 = expListFromSlots(slots2);
      then
        (cache,args_2,slots2);

      // If no class found. builtin, with no defaults. NOTE: if builtin class with defaults exist
      // both its type -and- its class must be added to Builtin.mo
    // case(cache,env,inArgs,fn,slots,impl,_,_) then (cache,inArgs,slots);

  end match;
end addDefaultArgs;

protected function determineConstSpecialFunc "For the special functions constructor and destructor,
in external object,
the constantness is always variable, even if arguments are constant, because they should be called during
runtime and not during compiletime."
  input Env.Cache inCache;
  input Env.Env env;
  input DAE.Const inConst;
  input Absyn.Path funcName;
  output Env.Cache outCache;
  output DAE.Const outConst;
algorithm
  (outCache,outConst) := matchcontinue(inCache,env,inConst,funcName)
  local Absyn.Path path;
    Env.Cache cache;
    // External Object found, constructor call is not constant.
    case (cache,_,_, path)
      equation
        (cache,true) = isExternalObjectFunction(cache,env,path);
      then (cache,DAE.C_VAR());
    case (cache,_,_,_) then (cache,inConst);
  end matchcontinue;
end determineConstSpecialFunc;

public function isExternalObjectFunction
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output Boolean res;
algorithm
  (outCache,res) := matchcontinue(inCache,inEnv,inPath)
    local
      Env.Cache cache;
      Env.Env env_1,env;
      Absyn.Path path;
      list<SCode.Element> els;

    case (cache,env,path) equation
      (cache,SCode.CLASS(classDef = SCode.PARTS(elementLst = els)),env_1)
          = Lookup.lookupClass(cache,env, path, false);
      true = Inst.isExternalObject(els);
      then (cache,true);
    case (cache,env,path) equation
      "constructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,env,path) equation
      "destructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,env,path)  then (cache,false);
  end matchcontinue;
end isExternalObjectFunction;

protected constant String vectorizeArg = "$vectorizeArg";

protected function vectorizeCall "author: PA
  Takes an expression and a list of array dimensions and the Slot list.
  It will vectorize the expression over the dimension given as array dim
  for the slots which have that dimension.
  For example foo:(Real,Real[:])=> Real
  foo(1:2,{1,2;3,4}) vectorizes with arraydim [2] to
  {foo(1,{1,2}),foo(2,{3,4})}"
  input DAE.Exp inExp;
  input DAE.Dimensions inTypesArrayDimLst;
  input list<Slot> inSlotLst;
  input DAE.Properties inProperties;
  input Absyn.Info info;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp,outProperties) := matchcontinue (inExp,inTypesArrayDimLst,inSlotLst,inProperties,info)
    local
      DAE.Exp e,vect_exp,vect_exp_1,dimexp;
      DAE.Type tp,tp0;
      DAE.Properties prop;
      DAE.Type exp_type,etp;
      DAE.Const c;
      Absyn.Path fn;
      list<DAE.Exp> expl,es;
      Boolean scalar;
      Integer int_dim;
      DAE.Dimension dim;
      DAE.Dimensions ad;
      list<Slot> slots;
      String str;
      DAE.CallAttributes attr;
      DAE.ReductionInfo rinfo;
      DAE.ReductionIterator riter;

    case (e,{},_,prop,_) then (e,prop);

    // If the dimension is not defined we can't vectorize the call. If we are running
    // checkModel this should succeed anyway, since we might be checking a function
    // that takes a vector of unknown size. So pretend that the dimension is 1.
    case (e, (DAE.DIM_UNKNOWN() :: ad), slots, prop, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (vect_exp_1, prop) = vectorizeCall(e, DAE.DIM_INTEGER(1) :: ad, slots, prop, info);
      then
        (vect_exp_1, prop);
      /* TODO: Remove me :D */
    case (e, (DAE.DIM_EXP(exp=_) :: ad), slots, prop, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (vect_exp_1, prop) = vectorizeCall(e, DAE.DIM_INTEGER(1) :: ad, slots, prop, info);
      then
        (vect_exp_1, prop);

    /* Scalar expression, i.e function call with unknown dimensions
    case (e as DAE.CALL(path = fn,expLst = {arg},tuple_ = tuple_,builtin = builtin,ty = etp,inlineType=inl),(dim as DAE.DIM_UNKNOWN()) :: ad,slots,DAE.PROP(tp,c))
      equation
        exp_type = Types.simplifyType(Types.liftArray(tp, dim)) "pass type of vectorized result expr";
        tickID = "i_" +& Util.tickStr();
        crefID = ComponentReference.makeCrefIdent(tickID, DAE.T_INTEGER_DEFAULT, {});
        vect_exp =
         DAE.REDUCTION(
           fn,
           DAE.ASUB(arg, {DAE.CREF(crefID, DAE.T_INTEGER_DEFAULT)}),
           tickID,
           DAE.RANGE(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource), DAE.ICONST(1), NONE(), DAE.END()));
        tp = Types.liftArray(tp, dim);
        (vect_exp_1,prop) = vectorizeCall(vect_exp, ad, slots, DAE.PROP(tp,c));
      then
        (vect_exp_1,prop);*/

    case (DAE.CALL(fn,es,attr),{DAE.DIM_UNKNOWN()},slots,prop as DAE.PROP(tp,c),_)
      equation
        (es,vect_exp) = vectorizeCallUnknownDimension(es,slots,{},NONE(),info);
        tp0 = Types.liftArrayRight(tp, DAE.DIM_INTEGER(0));
        tp = Types.liftArrayRight(tp, DAE.DIM_UNKNOWN());
        prop = DAE.PROP(tp,c);
        e = DAE.CALL(fn,es,attr);
        etp = Types.simplifyType(tp0);
        rinfo = DAE.REDUCTIONINFO(Absyn.IDENT("array"),tp,SOME(Values.ARRAY({},{0})),NONE());
        tp = Types.expTypetoTypesType(Expression.typeof(vect_exp));
        riter = DAE.REDUCTIONITER(vectorizeArg,vect_exp,NONE(),tp);
        e = DAE.REDUCTION(rinfo,e,{riter});
      then
        (e,prop);

    /* Scalar expression, non-constant but known dimensions */
    case (e as DAE.CALL(path = _),(DAE.DIM_EXP(exp=dimexp) :: ad),slots,DAE.PROP(tp,c),_)
      equation
        str = "Cannot vectorize call with dimension [" +& ExpressionDump.printExpStr(dimexp) +& "]";
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},info);
      then
        fail();

    /* Scalar expression, i.e function call */
    case (e as DAE.CALL(path = _),(dim :: ad),slots,DAE.PROP(tp,c),_)
      equation
        int_dim = Expression.dimensionSize(dim);
        exp_type = Types.simplifyType(Types.liftArray(tp, dim)) "pass type of vectorized result expr";
        vect_exp = vectorizeCallScalar(e, exp_type, int_dim, slots);
        tp = Types.liftArray(tp, dim);
        (vect_exp_1,prop) = vectorizeCall(vect_exp, ad, slots, DAE.PROP(tp,c),info);
      then
        (vect_exp_1,prop);

    /* array expression of function calls */
    case (DAE.ARRAY(scalar = scalar,array = expl),(dim :: ad),slots,DAE.PROP(tp,c),_)
      equation
        int_dim = Expression.dimensionSize(dim);
        exp_type = Types.simplifyType(Types.liftArray(tp, dim));
        vect_exp = vectorizeCallArray(inExp, int_dim, slots);
        tp = Types.liftArrayRight(tp, dim);
        (vect_exp_1,prop) = vectorizeCall(vect_exp, ad, slots, DAE.PROP(tp,c),info);
      then
        (vect_exp_1,prop);

    case (_,dim::_,_,_,_)
      equation
        str = ExpressionDump.dimensionString(dim);
        Debug.fprintln(Flags.FAILTRACE, "- Static.vectorizeCall failed: " +& str);
      then
        fail();
  end matchcontinue;
end vectorizeCall;

protected function vectorizeCallUnknownDimension
  "Returns the new call arguments and a reduction iterator argument"
  input list<DAE.Exp> inEs;
  input list<Slot> inSlots;
  input list<DAE.Exp> inAcc;
  input Option<DAE.Exp> found;
  input Absyn.Info info;
  output list<DAE.Exp> oes;
  output DAE.Exp ofound;
algorithm
  (oes,ofound) := match (inEs,inSlots,inAcc,found,info)
    local
      DAE.Exp e,e1,e2;
      String s1,s2;
      list<DAE.Exp> es;
      list<Slot> slots;
      list<DAE.Exp> acc;

    case ({},{},acc,SOME(e),_) then (listReverse(acc),e);
    case ({},{},_,NONE(),_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"Static.vectorizeCallUnknownDimension could not find any slot to vectorize"},info);
      then fail();
    case (e::es,SLOT(typesArrayDimLst={})::slots,acc,_,_)
      equation
        (oes,ofound) = vectorizeCallUnknownDimension(es,slots,e::acc,found,info);
      then (oes,ofound);
    case (e1::_,_,acc,SOME(e2),_)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        Error.addSourceMessage(Error.VECTORIZE_TWO_UNKNOWN,{s1,s2},info);
      then fail();
    case (e::es,_::slots,acc,_,_)
      equation
        (oes,ofound) = vectorizeCallUnknownDimension(es,slots,DAE.CREF(DAE.CREF_IDENT(vectorizeArg,DAE.T_REAL_DEFAULT,{}),DAE.T_REAL_DEFAULT)::acc,SOME(e),info);
      then (oes,ofound);
  end match;
end vectorizeCallUnknownDimension;

protected function vectorizeCallArray
"function : vectorizeCallArray
  author: PA
  Helper function to vectorize_call, vectoriezes ARRAY expression to
  an array of array expressions."
  input DAE.Exp inExp;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  match (inExp,inInteger,inSlotLst)
    local
      list<DAE.Exp> arr_expl,expl;
      Boolean scalar_1,scalar;
      DAE.Exp res_exp;
      DAE.Type tp;
      Integer cur_dim;
      list<Slot> slots;
    case (DAE.ARRAY(ty = tp,scalar = scalar,array = expl),cur_dim,slots) /* cur_dim */
      equation
        arr_expl = vectorizeCallArray2(expl, tp, cur_dim, slots);
        scalar_1 = Expression.typeBuiltin(tp);
        tp = Expression.liftArrayRight(tp, DAE.DIM_INTEGER(cur_dim));
        res_exp = DAE.ARRAY(tp,scalar_1,arr_expl);
      then
        res_exp;
  end match;
end vectorizeCallArray;

protected function vectorizeCallArray2
"author: PA
  Helper function to vectorizeCallArray"
  input list<DAE.Exp> inExpExpLst;
  input DAE.Type inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  match (inExpExpLst,inType,inInteger,inSlotLst)
    local
      DAE.Type tp,e_tp;
      Integer cur_dim;
      list<Slot> slots;
      DAE.Exp e_1,e;
      list<DAE.Exp> es_1,es;
    case ({},tp,cur_dim,slots) then {};
    case ((e :: es),e_tp,cur_dim,slots)
      equation
        e_1 = vectorizeCallArray3(e, e_tp, cur_dim, slots);
        es_1 = vectorizeCallArray2(es, e_tp, cur_dim, slots);
      then
        (e_1 :: es_1);
  end match;
end vectorizeCallArray2;

protected function vectorizeCallArray3 "author: PA
  Helper function to vectorizeCallArray2"
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  match (inExp,inType,inInteger,inSlotLst)
    local
      DAE.Exp e_1,e;
      DAE.Type e_tp;
      Integer cur_dim;
      list<Slot> slots;
    case ((e as DAE.CALL(path = _)),e_tp,cur_dim,slots) /* cur_dim */
      equation
        e_1 = vectorizeCallScalar(e, e_tp, cur_dim, slots);
      then
        e_1;
    case ((e as DAE.ARRAY(ty = _)),e_tp,cur_dim,slots)
      equation
        e_1 = vectorizeCallArray(e, cur_dim, slots);
      then
        e_1;
  end match;
end vectorizeCallArray3;

protected function vectorizeCallScalar
"author: PA
  Helper function to vectorizeCall, vectorizes CALL expressions to
  array expressions."
  input DAE.Exp inExp "e.g. abs(v)";
  input DAE.Type inType " e.g. Real[3], result of vectorized call";
  input Integer inInteger;
  input list<Slot> inSlotLst;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inType,inInteger,inSlotLst)
    local
      list<DAE.Exp> expl,args;
      Boolean scalar;
      DAE.Exp new_exp,callexp;
      DAE.Type e_type, arr_type;
      Integer dim;
      list<Slot> slots;

    case ((callexp as DAE.CALL(expLst = args)),e_type,dim,slots) /* cur_dim */
      equation
        expl = vectorizeCallScalar2(args, slots, 1, dim, callexp);
        e_type = Expression.unliftArray(e_type);
        scalar = Expression.typeBuiltin(e_type) " unlift vectorized dimension to find element type";
        arr_type = DAE.T_ARRAY(e_type, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
        new_exp = DAE.ARRAY(arr_type,scalar,expl);
      then
        new_exp;

    case (_,_,_,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "-Static.vectorizeCallScalar failed\n");
      then
        fail();
  end matchcontinue;
end vectorizeCallScalar;

protected function vectorizeCallScalar2
"author: PA
  Iterates through vectorized dimension an creates argument list according
  to vectorized dimension in corresponding slot."
  input list<DAE.Exp> inExpExpLst1;
  input list<Slot> inSlotLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  input DAE.Exp inExp5;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExpExpLst1,inSlotLst2,inInteger3,inInteger4,inExp5)
    local
      list<DAE.Exp> callargs,res,expl,args;
      Integer cur_dim_1,cur_dim,dim;
      list<Slot> slots;
      Absyn.Path fn;
      DAE.CallAttributes attr;
    // cur_dim - current indx in dim dim - dimension size
    case (expl,slots,cur_dim,dim,DAE.CALL(fn,args,attr))
      equation
        (cur_dim <= dim) = true;
        callargs = vectorizeCallScalar3(expl, slots, cur_dim);

        cur_dim_1 = cur_dim + 1;
        res = vectorizeCallScalar2(expl, slots, cur_dim_1, dim, inExp5);
      then
        (DAE.CALL(fn,callargs,attr) :: res);
    case (_,_,_,_,_) then {};
  end matchcontinue;
end vectorizeCallScalar2;

protected function vectorizeCallScalar3
"author: PA
  Helper function to vectorizeCallScalar2"
  input list<DAE.Exp> inExpExpLst;
  input list<Slot> inSlotLst;
  input Integer inInteger;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  match (inExpExpLst,inSlotLst,inInteger)
    local
      list<DAE.Exp> res,es;
      DAE.Exp e,asub_exp;
      list<Slot> ss;
      Integer dim_indx;

    // dim_indx
    case ({},{},_) then {};

    // scalar argument
    case ((e :: es),(SLOT(typesArrayDimLst = {}) :: ss),dim_indx)
      equation
        res = vectorizeCallScalar3(es, ss, dim_indx);
      then
        (e :: res);

    // foreach argument
    case ((e :: es),(SLOT(typesArrayDimLst = (_ :: _)) :: ss),dim_indx)
      equation
        res = vectorizeCallScalar3(es, ss, dim_indx);
        asub_exp = DAE.ICONST(dim_indx);
        (asub_exp,_) = ExpressionSimplify.simplify1(Expression.makeASUB(e,{asub_exp}));
      then
        (asub_exp :: res);
  end match;
end vectorizeCallScalar3;

protected function deoverloadFuncname
"This function is used to deoverload function calls. It investigates the
  type of the function to see if it has the optional functionname set. If
  so this is returned. Otherwise return input."
  input Absyn.Path inPath;
  input DAE.Type inType;
  output Absyn.Path outPath;
  output DAE.Type outType;
algorithm
  (outPath,outType) := match (inPath,inType)
    local
      Absyn.Path fn;
      String name;
      DAE.Type tty;
    case (_,tty as DAE.T_FUNCTION(functionAttributes = DAE.FUNCTION_ATTRIBUTES(isBuiltin=DAE.FUNCTION_BUILTIN(SOME(name)))))
      equation
        fn = Absyn.IDENT(name);
        tty = Types.setTypeSource(tty,Types.mkTypeSource(SOME(fn)));
      then (fn,tty);

    case (_,DAE.T_FUNCTION(funcArg = _, source = {fn})) then (fn,inType);

    else (inPath,inType);
  end match;
end deoverloadFuncname;

protected function isTuple
"Return true if Type is a Tuple type."
  input DAE.Type inType;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inType)
    case (DAE.T_TUPLE(tupleType = _)) then true;
    case (_) then false;
  end matchcontinue;
end isTuple;

protected function elabTypes "
function: elabTypes
   Elaborate input parameters to a function and
   select matching function type from a list of types."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<DAE.Type> inTypesTypeLst;
  input Boolean checkTypes "if True, checks types";
  input Boolean inBoolean;
  input IsExternalObject isExternalObject;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Const> outTypesConstLst2;
  output DAE.Type outType3;
  output DAE.Type outType4;
  output DAE.Dimensions outTypesArrayDimLst5;
  output list<Slot> outSlotLst6;
algorithm
  (outCache,outExpExpLst1,outTypesConstLst2,outType3,outType4,outTypesArrayDimLst5,outSlotLst6):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inTypesTypeLst,checkTypes,inBoolean,isExternalObject,st,inPrefix,info)
    local
      list<Slot> slots,newslots;
      list<DAE.Exp> args_1;
      list<DAE.Const> clist;
      DAE.Dimensions dims;
      list<Env.Frame> env;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      DAE.Type t,restype;
      list<DAE.FuncArg> params;
      list<DAE.Type> trest;
      Boolean impl;
      Env.Cache cache;
      InstTypes.PolymorphicBindings polymorphicBindings;
      Prefix.Prefix pre;
      DAE.FunctionAttributes functionAttributes;
      DAE.TypeSource ts;

    // We found a match.
    case (cache,env,args,nargs,(t as DAE.T_FUNCTION(funcArg=params, funcResultType=restype, functionAttributes=functionAttributes, source=ts))::trest,_,impl,_,_,pre,_)
      equation
        slots = makeEmptySlots(params);
        (cache,args_1,newslots,clist,polymorphicBindings) = elabInputArgs(cache, env, args, nargs, slots, checkTypes, impl, isExternalObject,{},st,pre,info);
        (params, restype) = applyArgTypesToFuncType(newslots, params, restype, env);
        dims = slotsVectorizable(newslots);
        polymorphicBindings = Types.solvePolymorphicBindings(polymorphicBindings,info,ts);
        restype = Types.fixPolymorphicRestype(restype, polymorphicBindings, info);
        t = DAE.T_FUNCTION(params,restype,functionAttributes,ts);
        t = createActualFunctype(t,newslots,checkTypes) "only created when not checking types for error msg";
      then
        (cache,args_1,clist,restype,t,dims,newslots);

    // We didn't find a match, try next function type
    case (cache,env,args,nargs,DAE.T_FUNCTION(funcArg=params, funcResultType=restype)::trest,_,impl,_,_,pre,_)
      equation
        (cache,args_1,clist,restype,t,dims,slots) = elabTypes(cache, env, args, nargs, trest, checkTypes, impl, isExternalObject, st, pre, info);
      then
        (cache,args_1,clist,restype,t,dims,slots);

    // failtrace
    case (cache,env,_,_,t::_,_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabTypes failed: " +& Types.unparseType(t));
      then
        fail();
  end matchcontinue;
end elabTypes;

protected function applyArgTypesToFuncType
  "This function is yet another hack trying to handle function parameters with
   unknown dimensions. It uses the input arguments to try and figure out the
   actual dimensions of the dimensions."
  input list<Slot> inSlots;
  input list<DAE.FuncArg> inParameters;
  input DAE.Type inResultType;
  input Env.Env inEnv;
  output list<DAE.FuncArg> outParameters;
  output DAE.Type outResultType;
algorithm
  (outParameters, outResultType) :=
  matchcontinue(inSlots, inParameters, inResultType, inEnv)
    local
      Env.Env env;
      Env.Cache cache;
      list<DAE.Var> vars;
      SCode.Element dummy_var;
      DAE.Type res_ty;
      list<DAE.FuncArg> params;
      list<String> used_args;
      list<DAE.Type> tys;
      list<DAE.Dimension> dims;
      list<Slot> used_slots;

    // some optimizations so we don't do all that below
    case ({}, {}, _, _) then ({}, inResultType);

    // get all the dims, bind the actual params to the formal params
    // build an new env frame with these bindings and evaluate dimensions
    case (_, _, _, _)
      equation
        // Extract all dimensions from the parameters.
        tys = List.map(inParameters, funcArgType);
        dims = getAllOutputDimensions(inResultType);
        dims = List.mapFlat_tail(tys, Types.getDimensions, dims);
        // Use the dimensions to figure out which parameters are referenced by
        // other parameters' dimensions. This is done to minimize the things we
        // need to constant evaluate, a.k.a. 'things that go wrong'.
        used_args = extractNamesFromDims(dims, {});
        used_slots = List.filter1OnTrue(inSlots, isSlotUsed, used_args);

        // Create DAE.Vars from the slots.
        cache = Env.emptyCache();
        vars = List.map2(used_slots, makeVarFromSlot, inEnv, cache);

        // Use a dummy SCode.Element, because we're only interested in the DAE.Vars.
        dummy_var = SCode.COMPONENT("dummy", SCode.defaultPrefixes,
          SCode.defaultVarAttr, Absyn.TPATH(Absyn.IDENT(""), NONE()),
          SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);
        
        // Create a new implicit scope with the needed parameters on top 
        // of the current env so we can find the bindings if needed.
        // We need an implicit scope so comp1.comp2 can be looked up without package constant restriction 
        env = Env.openScope(inEnv, SCode.NOT_ENCAPSULATED(), SOME(Env.forScopeName), NONE());
        
        // add variables to the environment
        env = makeDummyFuncEnv(env, vars, dummy_var);

        // Evaluate the dimensions in the types.
        params = List.map2(inParameters, evaluateFuncParamDim, env, cache);
        res_ty = evaluateFuncArgTypeDims(inResultType, env, cache);
      then
        (params, res_ty);

  end matchcontinue;
end applyArgTypesToFuncType;

protected function funcArgType
  "Returns the type of a FuncArg."
  input DAE.FuncArg inFuncArg;
  output DAE.Type outType;
algorithm
  (_, outType, _, _) := inFuncArg;
end funcArgType;

protected function getAllOutputDimensions
  "Return the dimensions of an output type."
  input DAE.Type inOutputType;
  output list<DAE.Dimension> outDimensions;
algorithm
  outDimensions := match(inOutputType)
    local
      list<DAE.Type> tys;

    // A tuple, get the dimensions of all the types.
    case DAE.T_TUPLE(tupleType = tys)
      then List.mapFlat(tys, Types.getDimensions);

    else Types.getDimensions(inOutputType);
  end match;
end getAllOutputDimensions;

protected function extractNamesFromDims
  "Extracts a list of unique names referenced by the given list of dimensions."
  input list<DAE.Dimension> inDimensions;
  input list<String> inAccumNames;
  output list<String> outNames;
algorithm
  outNames := match(inDimensions, inAccumNames)
    local
      DAE.Exp exp;
      list<DAE.Dimension> rest_dims;
      list<DAE.ComponentRef> crefs;
      list<String> names;

    case (DAE.DIM_EXP(exp = exp) :: rest_dims, _)
      equation
        crefs = Expression.extractCrefsFromExp(exp);
        names = List.fold(crefs, extractNamesFromDims2, inAccumNames);
      then
        extractNamesFromDims(rest_dims, names);

    case (_ :: rest_dims, _) then extractNamesFromDims(rest_dims, inAccumNames);
    case ({}, _) then inAccumNames;

  end match;
end extractNamesFromDims;

protected function extractNamesFromDims2
  input DAE.ComponentRef inCref;
  input list<String> inAccumNames;
  output list<String> outNames;
algorithm
  outNames := matchcontinue(inCref, inAccumNames)
    local
      String name;

    // Only interested in simple identifier, since that's all we can handle
    // anyway.
    case (DAE.CREF_IDENT(ident = name), _)
      equation
        // Make sure we haven't added this name yet.
        false = List.isMemberOnTrue(name, inAccumNames, stringEq);
      then
        name :: inAccumNames;

    else inAccumNames;

  end matchcontinue;
end extractNamesFromDims2;

protected function isSlotUsed
  "Checks if a slot is used, in the sense that it's referenced by a function
   parameter dimension."
  input Slot inSlot;
  input list<String> inUsedNames;
  output Boolean outIsUsed;
protected
  String slot_name;
algorithm
  SLOT(an = (slot_name, _, _, _)) := inSlot;
  outIsUsed := List.isMemberOnTrue(slot_name, inUsedNames, stringEq);
end isSlotUsed;

protected function makeVarFromSlot
  "Converts a Slot to a DAE.Var."
  input Slot inSlot;
  input Env.Env inEnv;
  input Env.Cache inCache;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue(inSlot, inEnv, inCache)
    local
      DAE.Ident name;
      DAE.Type ty;
      DAE.Exp exp;
      DAE.Binding binding;
      Values.Value val;

    // If the argument expression already has known dimensions, no need to
    // constant evaluate it.
    case (SLOT(an = (name, _, _, _), expExpOption = SOME(exp)), _, _)
      equation
        false = Expression.expHasCref(exp,ComponentReference.makeCrefIdent(name,DAE.T_UNKNOWN_DEFAULT,{}));
        ty = Expression.typeof(exp);
        true = Types.dimensionsKnown(ty);
        binding = DAE.EQBOUND(exp, NONE(), DAE.C_CONST(),
          DAE.BINDING_FROM_DEFAULT_VALUE());
      then
        DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, binding, NONE());

    // Otherwise, try to constant evaluate the expression.
    case (SLOT(an = (name, _, _, _), expExpOption = SOME(exp)), _, _)
      equation
        // Constant evaluate the bound expression.
        (_, val, _) = Ceval.ceval(inCache, inEnv, exp, false, NONE(), Absyn.NO_MSG(), 0);
        exp = ValuesUtil.valueExp(val);
        ty = Expression.typeof(exp);
        // Create a binding from the evaluated expression.
        binding = DAE.EQBOUND(exp, SOME(val), DAE.C_CONST(),
          DAE.BINDING_FROM_DEFAULT_VALUE());
      then
        DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, binding, NONE());

    case (SLOT(an = (name, ty, _, _)), _, _)
      then DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, DAE.UNBOUND(), NONE());

  end matchcontinue;
end makeVarFromSlot;

protected function makeDummyFuncEnv
  "Helper function to applyArgTypesToFuncType, creates a dummy function
   environment."
  input Env.Env inEnv;
  input list<DAE.Var> inVars;
  input SCode.Element inDummyVar;
  output Env.Env outEnv;
algorithm
  outEnv := match(inEnv, inVars, inDummyVar)
    local
      DAE.Var var;
      list<DAE.Var> rest_vars;
      Env.Env env;

    case (_, var :: rest_vars, _)
      equation
        env = Env.extendFrameV(inEnv, var, inDummyVar, DAE.NOMOD(),
          Env.VAR_TYPED(), Env.emptyEnv);
      then
        makeDummyFuncEnv(env, rest_vars, inDummyVar);

    case (_, {}, _) then inEnv;

  end match;
end makeDummyFuncEnv;

protected function evaluateFuncParamDim
  "Constant evaluates the dimensions of a FuncArg."
  input DAE.FuncArg inParam;
  input Env.Env inEnv;
  input Env.Cache inCache;
  output DAE.FuncArg outParam;
protected
  DAE.Ident ident;
  DAE.Type ty;
  DAE.Const c;
  Option<DAE.Exp> oexp;
algorithm
  (ident, ty, c, oexp) := inParam;
  ty := evaluateFuncArgTypeDims(ty, inEnv, inCache);
  outParam := (ident, ty, c, oexp);
end evaluateFuncParamDim;

protected function evaluateFuncArgTypeDims
  "Constant evaluates the dimensions of a type."
  input DAE.Type inType;
  input Env.Env inEnv;
  input Env.Cache inCache;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType, inEnv, inCache)
    local
      DAE.Type ty;
      DAE.TypeSource ts;
      Integer n;
      DAE.Dimension dim;
      list<DAE.Type> tys;
      Env.Env env;

    // Array type, evaluate the dimension.
    case (DAE.T_ARRAY(ty, {dim}, ts), _, _)
      equation
        (_, Values.INTEGER(n), _) = Ceval.cevalDimension(inCache, inEnv, dim, false, NONE(), Absyn.NO_MSG(), 0);
        ty = evaluateFuncArgTypeDims(ty, inEnv, inCache);
      then
        DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(n)}, ts);

    // Previous case failed, keep the dimension but evaluate the rest of the type.
    case (DAE.T_ARRAY(ty, {dim}, ts), _, _)
      equation
        ty = evaluateFuncArgTypeDims(ty, inEnv, inCache);
      then
        DAE.T_ARRAY(ty, {dim}, ts);

    case (DAE.T_TUPLE(tys, ts), _, _)
      equation
        tys = List.map2(tys, evaluateFuncArgTypeDims, inEnv, inCache);
      then
        DAE.T_TUPLE(tys, ts);

    else inType;

  end matchcontinue;
end evaluateFuncArgTypeDims;

protected function createActualFunctype
"Creates the actual function type of a CALL expression, used for error messages.
 This type is only created if checkTypes is false."
  input DAE.Type tp;
  input list<Slot> slots;
  input Boolean checkTypes;
  output DAE.Type outTp;
algorithm
  outTp := match(tp,slots,checkTypes)
    local
      DAE.TypeSource ts;
      list<DAE.FuncArg> slotParams,params;
      DAE.Type restype;
      DAE.FunctionAttributes functionAttributes;

    case (_,_,true) then tp;

    // When not checking types, create function type by looking at the filled slots
    case(DAE.T_FUNCTION(params,restype,functionAttributes,ts),_,false)
      equation
        slotParams = funcArgsFromSlots(slots);
      then
        DAE.T_FUNCTION(slotParams,restype,functionAttributes,ts);

  end match;
end createActualFunctype;

protected function slotsVectorizable
"author: PA
  This function checks all vectorized array dimensions in the slots and
  confirms that they all are of same dimension,or no dimension, i.e. not
  vectorized. The uniform vectorized array dimension is returned."
  input list<Slot> inSlotLst;
  output DAE.Dimensions outTypesArrayDimLst;
algorithm
  outTypesArrayDimLst:=
  matchcontinue (inSlotLst)
    local
      DAE.Dimensions ad;
      list<Slot> rest;
    case ({}) then {};
    case ((SLOT(typesArrayDimLst = (ad as (_ :: _))) :: rest))
      equation
        sameSlotsVectorizable(rest, ad);
      then
        ad;
    case ((SLOT(typesArrayDimLst = {}) :: rest))
      equation
        ad = slotsVectorizable(rest);
      then
        ad;
    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE, "-slots_vectorizable failed\n");
      then
        fail();
  end matchcontinue;
end slotsVectorizable;

protected function sameSlotsVectorizable
"author: PA
  This function succeds if all slots in the list either has the array
  dimension as given by the second argument or no array dimension at all.
  The array dimension must match both in dimension size and number of
  dimensions."
  input list<Slot> inSlotLst;
  input DAE.Dimensions inTypesArrayDimLst;
algorithm
  _:=
  match (inSlotLst,inTypesArrayDimLst)
    local
      DAE.Dimensions slot_ad,ad;
      list<Slot> rest;
    case ({},_) then ();
    case ((SLOT(typesArrayDimLst = (slot_ad as (_ :: _))) :: rest),ad) /* arraydim must match */
      equation
        sameArraydimLst(ad, slot_ad);
        sameSlotsVectorizable(rest, ad);
      then
        ();
    case ((SLOT(typesArrayDimLst = {}) :: rest),ad) /* empty arradim matches too */
      equation
        sameSlotsVectorizable(rest, ad);
      then
        ();
  end match;
end sameSlotsVectorizable;

protected function sameArraydimLst
"author: PA
  Helper function to sameSlotsVectorizable. "
  input DAE.Dimensions inTypesArrayDimLst1;
  input DAE.Dimensions inTypesArrayDimLst2;
algorithm
  _:=
  matchcontinue (inTypesArrayDimLst1,inTypesArrayDimLst2)
    local
      Integer i1,i2;
      DAE.Dimensions ads1,ads2;
      DAE.Exp e1,e2;
      DAE.Dimension ad1,ad2;
      String str1,str2,str;
    case ({},{}) then ();
    case ((DAE.DIM_INTEGER(integer = i1) :: ads1),(DAE.DIM_INTEGER(integer = i2) :: ads2))
      equation
        true = intEq(i1, i2);
        sameArraydimLst(ads1, ads2);
      then
        ();
    case (DAE.DIM_UNKNOWN() :: ads1,DAE.DIM_UNKNOWN() :: ads2)
      equation
        sameArraydimLst(ads1, ads2);
      then
        ();
    case (DAE.DIM_EXP(e1) :: ads1,DAE.DIM_EXP(e2) :: ads2)
      equation
        true = Expression.expEqual(e1,e2);
        sameArraydimLst(ads1, ads2);
      then
        ();
    case (ad1 :: ads1,ad2 :: ads2)
      equation
        str1 = ExpressionDump.dimensionString(ad1);
        str2 = ExpressionDump.dimensionString(ad2);
        str = "Could not vectorize function because dimensions "+&str1+&" and "+&str2+&"mismatch.";
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end sameArraydimLst;

protected function getProperties
"This function creates a Properties object from a DAE.Type and a
  DAE.TupleConst value."
  input DAE.Type inType;
  input DAE.TupleConst inTupleConst;
  output DAE.Properties outProperties;
algorithm
  outProperties := matchcontinue (inType,inTupleConst)
    local
      DAE.Type tt,t,ty;
      DAE.TupleConst const;
      DAE.Const b;
      String tystr,conststr;

    // At least two elements in the type list, this is a tuple. LS: Tuples are fixed before here
    case (tt as DAE.T_TUPLE(tupleType = _),const) then DAE.PROP_TUPLE(tt,const);

    // One type, this is a tuple with one element. The resulting properties is then identical to that of a single expression.
    case (t,DAE.TUPLE_CONST(tupleConstLst = (DAE.SINGLE_CONST(const = b) :: {}))) then DAE.PROP(t,b);
    case (t,DAE.TUPLE_CONST(tupleConstLst = (DAE.SINGLE_CONST(const = b) :: {}))) then DAE.PROP(t,b);
    case (t,DAE.SINGLE_CONST(const = b)) then DAE.PROP(t,b);

    // failure
    case (ty,const)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprint(Flags.FAILTRACE, "- get_properties failed: ");
        tystr = Types.unparseType(ty);
        conststr = Types.printTupleConstStr(const);
        Debug.fprint(Flags.FAILTRACE, tystr);
        Debug.fprint(Flags.FAILTRACE, ", ");
        Debug.fprintln(Flags.FAILTRACE, conststr);
      then
        fail();
  end matchcontinue;
end getProperties;

protected function buildTupleConst
"author: LS
  Build a TUPLE_CONST (DAE.TupleConst) for a PROP_TUPLE for a function call
  from a list of bools derived from arguments
  We should check functions actual arguments instead of their formal
  parameters as done below"
  input list<DAE.Const> blist;
  output DAE.TupleConst outTupleConst;
protected
  list<DAE.TupleConst> clist;
algorithm
  clist := buildTupleConstList(blist);
  outTupleConst := DAE.TUPLE_CONST(clist);
end buildTupleConst;

protected function buildTupleConstList
"Helper function to buildTupleConst"
  input list<DAE.Const> inTypesConstLst;
  output list<DAE.TupleConst> outTypesTupleConstLst;
algorithm
  outTypesTupleConstLst := matchcontinue (inTypesConstLst)
    local
      list<DAE.TupleConst> restlist;
      DAE.Const c;
      list<DAE.Const> crest;

    case {} then {};

    case (c :: crest)
      equation
        restlist = buildTupleConstList(crest);
      then
        (DAE.SINGLE_CONST(c) :: restlist);
  end matchcontinue;
end buildTupleConstList;

protected function elabConsts "author: PR
  This just splits the properties list into a type list and a const list.
  LS: Changed to take a Type, which is the functions return type.
  LS: Update: const is derived from the input arguments and sent here."
  input DAE.Type inType;
  input DAE.Const inConst;
  output DAE.TupleConst outTupleConst;
algorithm
  outTupleConst := matchcontinue (inType,inConst)
    local
      list<DAE.TupleConst> consts;
      list<DAE.Type> tys;
      DAE.Const c;
      DAE.Type ty;

    case (DAE.T_TUPLE(tupleType = tys),c)
      equation
        consts = checkConsts(tys, c);
      then
        DAE.TUPLE_CONST(consts);

    // LS: If not a tuple then one normal type, T_INTEGER etc, but we make a list of types
    // with one element and call the same check_consts, so that we always have DAE.TUPLE_CONST as result
    case (ty,c)
      equation
        consts = checkConsts({ty}, c);
      then
        DAE.TUPLE_CONST(consts);
  end matchcontinue;
end elabConsts;

protected function checkConsts
"LS: Changed to take a Type list, which is the functions return type. Only
   for functions returning a tuple
  LS: Update: const is derived from the input arguments and sent here "
  input list<DAE.Type> inTypesTypeLst;
  input DAE.Const inConst;
  output list<DAE.TupleConst> outTypesTupleConstLst;
algorithm
  outTypesTupleConstLst := match (inTypesTypeLst,inConst)
    local
      DAE.TupleConst c;
      list<DAE.TupleConst> rest_1;
      DAE.Type a;
      list<DAE.Type> rest;
      DAE.Const const;

    case ({},_) then {};

    case (a :: rest,const)
      equation
        c = checkConst(a, const);
        rest_1 = checkConsts(rest, const);
      then
        (c :: rest_1);
  end match;
end checkConsts;

protected function checkConst "author: PR
   At the moment this make all outputs non cons.
  All ouputs should be checked in the function body for constness.
  LS: but it says true?
  LS: Adapted to check one type instead of funcarg, since it just checks
  return type
  LS: Update: const is derived from the input arguments and sent here"
  input DAE.Type inType;
  input DAE.Const inConst;
  output DAE.TupleConst outTupleConst;
algorithm
  outTupleConst := matchcontinue (inType,inConst)
    local DAE.Const c;

    case (DAE.T_TUPLE(tupleType = _),c)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"No suport for tuples built by tuples"});
      then
        fail();

    case (_,c) then DAE.SINGLE_CONST(c);
  end matchcontinue;
end checkConst;

protected function splitProps "Splits the properties list into the separated types list and const list."
  input list<DAE.Properties> inTypesPropertiesLst;
  output list<DAE.Type> outTypesTypeLst;
  output list<DAE.TupleConst> outTypesTupleConstLst;
algorithm
  (outTypesTypeLst,outTypesTupleConstLst) := match (inTypesPropertiesLst)
    local
      list<DAE.Type> types;
      list<DAE.TupleConst> consts;
      DAE.Type t;
      DAE.Const c;
      list<DAE.Properties> props;
      DAE.TupleConst t_c;

    case ((DAE.PROP(type_ = t,constFlag = c) :: props))
      equation
        (types,consts) = splitProps(props) "list_append(ts,t::{}) => t1 & list_append(cs,DAE.SINGLE_CONST(c)::{}) => t2 & " ;
      then
        ((t :: types),(DAE.SINGLE_CONST(c) :: consts));

    case ((DAE.PROP_TUPLE(type_ = t,tupleConst = t_c) :: props))
      equation
        (types,consts) = splitProps(props) "list_append(ts,t::{}) => ts\' & list_append(cs, t_c::{}) => cs\' &" ;
      then
        ((t :: types),(t_c :: consts));

    case ({}) then ({},{});
  end match;
end splitProps;

protected function getTypes
"This function returns the types of a DAE.FuncArg list."
  input list<DAE.FuncArg> farg;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst := List.map(farg,Util.tuple42);
end getTypes;

protected function functionParams
"A function definition is just a clas definition where all publi
  components are declared as either inpu or outpu.  This
  function_ find all those components and_ separates them into two
  separate lists.
  LS: This can probably replaced by Types.getInputVars and Types.getOutputVars"
  input list<DAE.Var> inTypesVarLst;
  output list<DAE.FuncArg> outTypesFuncArgLst1;
  output list<DAE.FuncArg> outTypesFuncArgLst2;
algorithm
  (outTypesFuncArgLst1,outTypesFuncArgLst2) := match (inTypesVarLst)
    local
      list<DAE.FuncArg> in_,out;
      list<DAE.Var> vs;
      String n;
      DAE.Type t;
      DAE.Var v;
      SCode.Variability var;
      DAE.Const c;

    case {} then ({},{});

    case ((DAE.TYPES_VAR(attributes = DAE.ATTR(visibility = SCode.PROTECTED())) :: vs)) /* Ignore protected components */
      equation
        (in_,out) = functionParams(vs);
      then
        (in_,out);

    case ((DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(direction = Absyn.INPUT(), variability = var,
           visibility = SCode.PUBLIC()),ty = t,binding = DAE.UNBOUND()) :: vs))
      equation
        c = Types.variabilityToConst(var);
        (in_,out) = functionParams(vs);
      then
        (((n,t,c,NONE()) :: in_),out);

    case ((DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(direction = Absyn.OUTPUT(), variability = var,
           visibility = SCode.PUBLIC()),ty = t,binding = DAE.UNBOUND()) :: vs))
      equation
        c = Types.variabilityToConst(var);
        (in_,out) = functionParams(vs);
      then
        (in_,((n,t,c,NONE()) :: out));

    case (((v as DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(direction = Absyn.BIDIR()))) :: vs))
      equation
        Error.addMessage(Error.FUNCTION_COMPS_MUST_HAVE_DIRECTION, {n});
      then
        fail();

    case (vs)
      equation
        // enabled only by +d=failtrace
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.functionParams failed on: " +& stringDelimitList(List.map(vs, Types.printVarStr), "; "));
      then
        fail();
  end match;
end functionParams;

protected function elabInputArgs
"function_: elabInputArgs
  This function_ elaborates on a number of expressions and_ matches
  them to a number of `DAE.Var\' objects, applying type_ conversions
  on the expressions when necessary to match the type_ of the
  DAE.Var.
  PA: Positional arguments and named arguments are filled in the argument slots as:
  1. Positional arguments fill the first slots according to their position.
  2. Named arguments fill slots with the same name as the named argument.
  3. Unfilled slots are checks so that they have default values, otherwise error."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "if true, check types";
  input Boolean inBoolean;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outExpExpLst,outSlotLst,outTypesConstLst,outPolymorphicBindings):=
  match (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inSlotLst,checkTypes,inBoolean,isExternalObject,inPolymorphicBindings,st,inPrefix,info)
    local
      list<DAE.FuncArg> farg;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist1,clist2,clist;
      list<DAE.Exp> explst,newexp;
      list<Env.Frame> env;
      list<Absyn.Exp> exp;
      list<Absyn.NamedArg> narg;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;

    // impl const Fill slots with positional arguments
    case (cache,env,(exp as (_ :: _)),narg,slots,_,impl,_,polymorphicBindings,_,pre,_)
      equation
        farg = funcArgsFromSlots(slots);
        (cache,slots_1,clist1,polymorphicBindings) =
          elabPositionalInputArgs(cache, env, exp, farg, slots, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
        (cache,_,newslots,clist2,polymorphicBindings) =
          elabInputArgs(cache, env, {}, narg, slots_1, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info)
          "recursive call fills named arguments" ;
        clist = listAppend(clist1, clist2);
        explst = expListFromSlots(newslots);
      then
        (cache,explst,newslots,clist,polymorphicBindings);

    // Fill slots with named arguments
    case (cache,env,{},narg as _::_,slots,_,impl,_,polymorphicBindings,_,pre,_)
      equation
        farg = funcArgsFromSlots(slots);
        (cache,newslots,clist,polymorphicBindings) =
          elabNamedInputArgs(cache, env, narg, farg, slots, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
        newexp = expListFromSlots(newslots);
      then
        (cache,newexp,newslots,clist,polymorphicBindings);

    // Empty function call, e.g foo(), is always constant
    // arpo 2010-11-09: TODO! FIXME! this is not always true, RecordCall() can contain DEFAULT bindings that are par
    case (cache,env,{},{},slots,_,impl,_,polymorphicBindings,_,_,_)
      then (cache,{},slots,{DAE.C_CONST()},polymorphicBindings);

    // fail trace
    else
      /* FAILTRACE REMOVE equation Debug.fprint(Flags.FAILTRACE,"elabInputArgs failed\n"); */
      then fail();
  end match;
end elabInputArgs;

protected function makeEmptySlots
"Helper function to elabInputArgs.
  Creates the slots to be filled with arguments. Intially they are empty."
  input list<DAE.FuncArg> inTypesFuncArgLst;
  output list<Slot> outSlotLst;
algorithm
  outSlotLst:=
  match (inTypesFuncArgLst)
    local
      list<Slot> ss;
      DAE.FuncArg fa;
      list<DAE.FuncArg> fs;
    case ({}) then {};
    case (fa :: fs)
      equation
        ss = makeEmptySlots(fs);
      then
        (SLOT(fa,false,NONE(),{}) :: ss);
  end match;
end makeEmptySlots;

protected function funcArgsFromSlots
  "Converts a list of Slot to a list of FuncArg."
  input list<Slot> inSlots;
  output list<DAE.FuncArg> outFuncArgs;
algorithm
  outFuncArgs := List.map(inSlots, funcArgFromSlot);
end funcArgsFromSlots;

protected function funcArgFromSlot
  input Slot inSlot;
  output DAE.FuncArg outFuncArg;
algorithm
  SLOT(an = outFuncArg) := inSlot;
end funcArgFromSlot;

protected function complexTypeFromSlots
"Creates an DAE.T_COMPLEX type from a list of slots.
 Used to create type of record constructors "
  input list<Slot> inSlots;
  input ClassInf.State complexClassType;
  output DAE.Type tp;
algorithm
  tp := match(inSlots,complexClassType)
    local
      DAE.Type etp;
      DAE.Type ty;
      String id;
      list<DAE.Var> vLst;
      ClassInf.State ci;
      Absyn.Path path;
      DAE.TypeSource ts;
      DAE.EqualityConstraint ec;
      DAE.Var tv;
      list<Slot> slots;

    case({},_)
      equation
        path = ClassInf.getStateName(complexClassType);
      then
        DAE.T_COMPLEX(complexClassType, {}, NONE(), DAE.emptyTypeSource);

    case(SLOT(an = (id,ty,_,_))::slots,_)
      equation
        etp = Types.simplifyType(ty);
        DAE.T_COMPLEX(ci,vLst,ec,ts) = complexTypeFromSlots(slots,complexClassType);
        tv = Expression.makeVar(id,etp);
      then
        DAE.T_COMPLEX(ci, tv::vLst, ec, ts);

  end match;
end complexTypeFromSlots;

protected function expListFromSlots
"Convers slots to expressions "
  input list<Slot> inSlotLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  match (inSlotLst)
    local
      list<DAE.Exp> lst;
      DAE.Exp e;
      list<Slot> xs;
    case {} then {};
    case ((SLOT(expExpOption = SOME(e)) :: xs))
      equation
        lst = expListFromSlots(xs);
      then
        (e :: lst);
    case ((SLOT(expExpOption = NONE()) :: xs))
      equation
        lst = expListFromSlots(xs);
      then
        lst;
  end match;
end expListFromSlots;

protected function getExpInModifierFomEnvOrClass
"@author: adrpo
  we should get the modifier from the environemnt as it might have been changed by a extends modification!"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Ident inComponentName;
  input SCode.Element inClass;
  output Absyn.Exp outExp;
algorithm
  outExp := matchcontinue(inCache,inEnv,inComponentName,inClass)
    local
      Env.Cache cache;
      Env.Env env;
      SCode.Ident id;
      SCode.Element cls;
      Absyn.Exp exp;
      DAE.Mod extendsMod;
      SCode.Mod scodeMod;

    // no element in env
    case (cache, env, id, cls)
      equation
        //(_, _, NONE(), _, _ ) = Lookup.lookupIdentLocal(cache, env, id);
        //print("here1\n");
        SCode.COMPONENT(modifications = SCode.MOD(binding = SOME((exp,_)))) = SCode.getElementNamed(id, cls);
      then
        exp;

    // no modifier in env
    case (cache, env, id, cls)
      equation
        (_, _, _, DAE.NOMOD(), _, _ ) = Lookup.lookupIdentLocal(cache, env, id);
        print("here2");
        SCode.COMPONENT(modifications = SCode.MOD(binding = SOME((exp,_)))) = SCode.getElementNamed(id, cls);
      then
        exp;

    // some modifier in env, return that
    case (cache, env, id, cls)
      equation
        (_, _, _, extendsMod, _, _ ) = Lookup.lookupIdentLocal(cache, env, id);
        print("here3");
        scodeMod = Mod.unelabMod(extendsMod);
        SCode.MOD(binding = SOME((exp,_))) = scodeMod;
      then
        exp;

  end matchcontinue;
end getExpInModifierFomEnvOrClass;

protected function fillDefaultSlot
  "This function takes a slot list and a class definition of a function
  and fills  default values into slots which have not been filled."
  input Slot slot;
  input Absyn.Info info;
  output Slot outSlot;
algorithm
  outSlot := matchcontinue (slot,info)
    local
      Option<DAE.Exp> e;
      DAE.Dimensions ds;
      DAE.Exp exp_1;
      DAE.Type tp;
      DAE.Const c2;
      String id;

    case (SLOT(slotFilled = true,expExpOption = e as SOME(_)),_) then slot;

    case (SLOT(an = (id,tp,c2,e as SOME(exp_1)),slotFilled = false,expExpOption = NONE(),typesArrayDimLst = ds),_)
      then
        SLOT((id,tp,c2,e),true,SOME(exp_1),ds);

    case (SLOT(an = (id,_,_,_)),_)
      equation
        Error.addSourceMessage(Error.UNFILLED_SLOT, {id}, info);
      then fail();
  end matchcontinue;
end fillDefaultSlot;

protected function fillGraphicsDefaultSlots
  "This function takes a slot list and a class definition of a function
  and fills  default values into slots which have not been filled.

  Special case for graphics exps"
  input Env.Cache inCache;
  input list<Slot> inSlotLst;
  input SCode.Element inClass;
  input Env.Env inEnv;
  input Boolean inBoolean;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings) :=
  matchcontinue (inCache,inSlotLst,inClass,inEnv,inBoolean,inPolymorphicBindings,inPrefix,info)
    local
      list<Slot> res,xs;
      DAE.FuncArg fa;
      Option<DAE.Exp> e;
      DAE.Dimensions ds;
      SCode.Element class_;
      list<Env.Frame> env;
      Boolean impl;
      Absyn.Exp dexp;
      DAE.Exp exp,exp_1;
      DAE.Type t,tp;
      DAE.Const c1,c2;
      list<DAE.Const> constLst;
      String id;
      Env.Cache cache;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;

    case (cache,(SLOT(an = fa,slotFilled = true,expExpOption = e as SOME(_),typesArrayDimLst = ds) :: xs),class_,env,impl,polymorphicBindings,pre,_)
      equation
        (cache, res, constLst, polymorphicBindings) = fillGraphicsDefaultSlots(cache, xs, class_, env, impl, polymorphicBindings, pre, info);
      then
        (cache, SLOT(fa,true,e,ds) :: res, constLst, polymorphicBindings);

    case (cache,(SLOT(an = (id,tp,c2,e),slotFilled = false,expExpOption = NONE(),typesArrayDimLst = ds) :: xs),class_,env,impl,polymorphicBindings,pre,_)
      equation
        (cache,res,constLst,polymorphicBindings) = fillGraphicsDefaultSlots(cache, xs, class_, env, impl, polymorphicBindings, pre, info);

        SCode.COMPONENT(modifications = SCode.MOD(binding = SOME((dexp,_)))) = SCode.getElementNamed(id, class_);

        (cache,exp,DAE.PROP(t,c1),_) = elabExp(cache, env, dexp, impl, NONE(), true, pre, info);
        // print("Slot: " +& id +& " -> " +& Exp.printExpStr(exp) +& "\n");
        (exp_1,_,polymorphicBindings) = Types.matchTypePolymorphic(exp,t,tp,Env.getEnvPathNoImplicitScope(env),polymorphicBindings,false);
        true = Types.constEqualOrHigher(c1,c2);
      then
        (cache, SLOT((id,tp,c2,e),true,SOME(exp_1),ds) :: res, c1::constLst, polymorphicBindings);

    case (cache,(SLOT(an = fa,slotFilled = false,expExpOption = e,typesArrayDimLst = ds) :: xs),class_,env,impl,polymorphicBindings,pre,_)
      equation
        (cache, res, constLst, polymorphicBindings) = fillGraphicsDefaultSlots(cache, xs, class_, env, impl, polymorphicBindings, pre, info);
      then
        (cache,SLOT(fa,false,e,ds) :: res, constLst, polymorphicBindings);


    case (cache,{},_,_,_,_,_,_) then (cache,{},{},{});
  end matchcontinue;
end fillGraphicsDefaultSlots;

protected function printSlotsStr
"prints the slots to a string"
  input list<Slot> inSlotLst;
  output String outString;
algorithm
  outString:=
  match (inSlotLst)
    local
      Boolean filled;
      String farg_str,filledStr,str,s,s1,s2,res;
      list<String> str_lst;
      DAE.FuncArg farg;
      Option<DAE.Exp> exp;
      DAE.Dimensions ds;
      list<Slot> xs;
    case ((SLOT(an = farg,slotFilled = filled,expExpOption = exp,typesArrayDimLst = ds) :: xs))
      equation
        farg_str = Types.printFargStr(farg);
        filledStr = Util.if_(filled, "filled", "not filled");
        str = Dump.getOptionStr(exp, ExpressionDump.printExpStr);
        str_lst = List.map(ds, ExpressionDump.dimensionString);
        s = stringDelimitList(str_lst, ", ");
        s1 = stringAppendList({"SLOT(",farg_str,", ",filledStr,", ",str,", [",s,"])\n"});
        s2 = printSlotsStr(xs);
        res = stringAppend(s1, s2);
      then
        res;
    case ({}) then "";
  end match;
end printSlotsStr;

protected uniontype IsExternalObject
  record IS_EXTERNAL_OBJECT_MODEL_SCOPE end IS_EXTERNAL_OBJECT_MODEL_SCOPE;
  record NOT_EXTERNAL_OBJECT_MODEL_SCOPE end NOT_EXTERNAL_OBJECT_MODEL_SCOPE;
end IsExternalObject;

protected function evalExternalObjectInput
  "External Object requires us to construct before initialization for good results. So try to evaluate the inputs."
  input IsExternalObject isExternalObject;
  input DAE.Type ty;
  input DAE.Const const;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Exp inExp;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp) := matchcontinue (isExternalObject,ty,const,inCache,inEnv,inExp,info)
    local
      String str;
      Values.Value val;
    case (NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),_,_,_,_,_,_)
      then (inCache,inExp);
    case (_,_,_,_,_,_,_)
      equation
        true = Types.isParameterOrConstant(const);
        false = Expression.isConst(inExp);
        (outCache, val, _) = Ceval.ceval(inCache, inEnv, inExp, false, NONE(), Absyn.MSG(info), 0);
        outExp = ValuesUtil.valueExp(val);
      then (outCache,outExp);
    case (_,_,_,_,_,_,_)
      equation
        true = Types.isParameterOrConstant(const) or Types.isExternalObject(ty) or Expression.isConst(inExp);
      then (inCache,inExp);
    else
      equation
        false = Types.isParameterOrConstant(const);
        str = ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.EVAL_EXTERNAL_OBJECT_CONSTRUCTOR, {str}, info);
      then (inCache,inExp);
  end matchcontinue;
end evalExternalObjectInput;

protected function elabPositionalInputArgs
"This function elaborates the positional input arguments of a function.
  A list of slots is filled from the beginning with types of each
  positional argument."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "if true, check types";
  input Boolean inBoolean;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inTypesFuncArgLst,inSlotLst,checkTypes,inBoolean,isExternalObject,inPolymorphicBindings,st,inPrefix,info)
    local
      list<Slot> slots,slots_1,newslots;
      Boolean impl;
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1,c2;
      list<DAE.Const> clist;
      list<Env.Frame> env;
      Absyn.Exp e;
      list<Absyn.Exp> es;
      DAE.FuncArg farg;
      list<DAE.FuncArg> vs;
      DAE.Dimensions ds;
      Env.Cache cache;
      String id;
      DAE.Properties props;
      Prefix.Prefix pre;
      DAE.CodeType ct;
      InstTypes.PolymorphicBindings polymorphicBindings;

    // the empty case
    case (cache, _, {}, _, slots, _, impl, _, polymorphicBindings,_,pre,_)
      then (cache,slots,{},polymorphicBindings);

    case (cache, env, (e :: es), ((farg as (_,DAE.T_CODE(ct,_),_,_)) :: vs), slots, true, impl, _, polymorphicBindings,_,pre,_)
      equation
        e_1 = elabCodeExp(e,cache,env,ct,info);
        (cache,slots_1,clist,polymorphicBindings) =
        elabPositionalInputArgs(cache, env, es, vs, slots, checkTypes, impl, isExternalObject, polymorphicBindings, st, pre, info);
        newslots = fillSlot(farg, e_1, {}, slots_1,checkTypes,pre,info);
      then
        (cache,newslots,(DAE.C_VAR() :: clist),polymorphicBindings);

    // exact match
    case (cache, env, (e :: es), ((farg as (id,vt,c2,_)) :: vs), slots, true, impl, _, polymorphicBindings,_,pre,_)
      equation
        (cache,e_1,props,_) = elabExp(cache,env, e, impl,st, true,pre,info);
        t = Types.getPropType(props);
        ((vt, _)) = Types.traverseType((vt, -1), Types.makeExpDimensionsUnknown);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, vt, c1, cache, env, e_1, info);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,Env.getEnvPathNoImplicitScope(env),polymorphicBindings,false);
        // TODO: Check const
        (cache,slots_1,clist,polymorphicBindings) =
        elabPositionalInputArgs(cache, env, es, vs, slots, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
        newslots = fillSlot((id,vt,c1,NONE()), e_2, {}, slots_1,checkTypes,pre,info) "no vectorized dim" ;
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings);

    // check if vectorized argument
    case (cache, env, (e :: es), ((farg as (id,vt,c2,_)) :: vs), slots, true, impl, _, polymorphicBindings,_,pre,_)
      equation
        (cache,e_1,props,_) = elabExp(cache,env, e, impl,st,true,pre,info);
        t = Types.getPropType(props);
        ((vt, _)) = Types.traverseType((vt, -1), Types.makeExpDimensionsUnknown);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, vt, c1, cache, env, e_1, info);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt, Env.getEnvPathNoImplicitScope(env));
        // TODO: Check const...
        (cache,slots_1,clist,_) =
          elabPositionalInputArgs(cache, env, es, vs, slots, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
        newslots = fillSlot((id,vt,c1,NONE()), e_2, ds, slots_1, checkTypes,pre,info);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings);

    // not checking types
    case (cache, env, (e :: es), ((farg as (id,vt,_,_)) :: vs), slots, false, impl, _, polymorphicBindings,_,pre,_)
      equation
        (cache,e_1,props,_) = elabExp(cache,env, e, impl,st,true,pre,info);
        t = Types.getPropType(props);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        (cache,slots_1,clist,polymorphicBindings) =
          elabPositionalInputArgs(cache, env, es, vs, slots,checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
        /* fill slot with actual type for error message*/
        newslots = fillSlot((id,t,c1,NONE()), e_1, {}, slots_1, checkTypes,pre,info);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings);

    // check types and display error
    case (cache, env, (e :: es), ((farg as (_,vt,_,_)) :: vs), slots, true, impl, _, polymorphicBindings,_,pre,_)
      equation
        /* FAILTRACE REMOVE
        (cache,e_1,DAE.PROP(t,c1),_) = elabExp(cache,env,e,impl,NONE(),true,pre,info);
        failure((_,_,_) = Types.matchTypePolymorphic(e_1,t,vt,polymorphicBindings,false,fnPath));
        Debug.fprint(Flags.FAILTRACE, "elabPositionalInputArgs failed, expected type:");
        Debug.fprint(Flags.FAILTRACE, Types.unparseType(vt));
        Debug.fprint(Flags.FAILTRACE, " found type");
        Debug.fprint(Flags.FAILTRACE, Types.unparseType(t));
        Debug.fprint(Flags.FAILTRACE, "\n");
        */
      then
        fail();
    // failtrace
    case (cache, env, es, _, slots, _, impl, _, polymorphicBindings,_,pre,_)
      equation
        /* FAILTRACE REMOVE
        Debug.fprint(Flags.FAILTRACE, "elabPositionalInputArgs failed: expl:");
        Debug.fprint(Flags.FAILTRACE, stringDelimitList(List.map(es,Dump.printExpStr),", "));
        Debug.fprint(Flags.FAILTRACE, "\n");
        */
      then
        fail();
  end matchcontinue;
end elabPositionalInputArgs;

protected function elabNamedInputArgs
"This function takes an Env, a NamedArg list, a DAE.FuncArg list and a
  Slot list.
  It builds up a new slot list and a list of elaborated expressions.
  If a slot is filled twice the function fails. If a slot is not filled at
  all and the
  value is not a parameter or a constant the function also fails."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "if true, check types";
  input Boolean inBoolean;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings) :=
  matchcontinue (inCache,inEnv,inAbsynNamedArgLst,inTypesFuncArgLst,inSlotLst,checkTypes,inBoolean,isExternalObject,inPolymorphicBindings,st,inPrefix,info)
    local
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist;
      list<Env.Frame> env;
      String id, pre_str;
      Absyn.Exp e;
      list<Absyn.NamedArg> nas,narg;
      list<DAE.FuncArg> farg;
      Boolean impl;
      DAE.CodeType ct;
      Env.Cache cache;
      DAE.Dimensions ds;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;

    // the empty case
    case (cache,_,{},_,slots,_,impl,_,polymorphicBindings,_,_,_)
      then (cache,slots,{},polymorphicBindings);

    case (cache, env, (Absyn.NAMEDARG(argName = id,argValue = e) :: nas), farg, slots, true, impl, _, polymorphicBindings,_,pre,_)
      equation
        (vt as DAE.T_CODE(ty=ct)) = findNamedArgType(id, farg);
        e_1 = elabCodeExp(e,cache,env,ct,info);
        slots_1 = fillSlot((id,vt,DAE.C_VAR(),NONE()), e_1, {}, slots,checkTypes,pre,info);
        (cache,newslots,clist,polymorphicBindings) =
        elabNamedInputArgs(cache, env, nas, farg, slots_1, checkTypes, impl, isExternalObject, polymorphicBindings, st, pre, info);
      then
        (cache,newslots,(DAE.C_VAR() :: clist),polymorphicBindings);

    // check types exact match
    case (cache,env,(Absyn.NAMEDARG(argName = id,argValue = e) :: nas),farg,slots,true,impl,_,polymorphicBindings,_,pre,_)
      equation
        vt = findNamedArgType(id, farg);
        (cache,e_1,DAE.PROP(t,c1),_) = elabExp(cache, env, e, impl,st, true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,Env.getEnvPathNoImplicitScope(env),polymorphicBindings,false);
        slots_1 = fillSlot((id,vt,c1,NONE()), e_2, {}, slots,checkTypes,pre,info);
        (cache,newslots,clist,polymorphicBindings) =
          elabNamedInputArgs(cache, env, nas, farg, slots_1, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings);

    // check types vectorized argument
    case (cache,env,(Absyn.NAMEDARG(argName = id,argValue = e) :: nas),farg,slots,true,impl,_,polymorphicBindings,_,pre,_)
      equation
        (cache,e_1,DAE.PROP(t,c1),_) = elabExp(cache, env, e, impl,st, true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        vt = findNamedArgType(id, farg);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt, Env.getEnvPathNoImplicitScope(env));
        slots_1 = fillSlot((id,vt,c1,NONE()), e_2, ds, slots, checkTypes,pre,info);
        (cache,newslots,clist,polymorphicBindings) =
          elabNamedInputArgs(cache, env, nas, farg, slots_1, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings);

    // do not check types
    case (cache,env,(Absyn.NAMEDARG(argName = id,argValue = e) :: nas),farg,slots,false,impl,_,polymorphicBindings,_,pre,_)
      equation
        (cache,e_1,DAE.PROP(t,c1),_) = elabExp(cache,env, e, impl,st,true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        vt = findNamedArgType(id, farg);
        slots_1 = fillSlot((id,vt,c1,NONE()), e_1, {}, slots,checkTypes,pre,info);
        (cache,newslots,clist,polymorphicBindings) =
          elabNamedInputArgs(cache, env, nas, farg, slots_1, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info);
      then
        (cache,newslots,(c1 :: clist),polymorphicBindings);

    // failure
    case (cache,env,narg,farg,_,_,impl,_,_,_,pre,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Debug.fprintln(Flags.FAILTRACE, "Static.elabNamedInputArgs failed for first named argument in: (" +&
           stringDelimitList(List.map(narg, Dump.printNamedArgStr), ", ") +& "), in component: " +& pre_str);
      then
        fail();
  end matchcontinue;
end elabNamedInputArgs;

protected function findNamedArgType
"This function takes an Ident and a FuncArg list, and returns the FuncArg
  which has  that identifier.
  Used for instance when looking up named arguments from the function type."
  input String inIdent;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inIdent,inTypesFuncArgLst)
    local
      String id,id2;
      DAE.Type ty;
      list<DAE.FuncArg> ts;
    case (id,(id2,ty,_,_) :: ts)
      equation
        true = stringEq(id, id2);
      then
        ty;
    case (id,(id2,_,_,_) :: ts)
      equation
        false = stringEq(id, id2);
        ty = findNamedArgType(id, ts);
      then
        ty;
  end matchcontinue;
end findNamedArgType;

protected function fillSlot
"This function takses a `FuncArg\' and an DAE.Exp and a Slot list and fills
  the slot holding the FuncArg, by setting the boolean value of the slot
  and setting the expression. The function fails if the slot is allready set."
  input DAE.FuncArg inFuncArg;
  input DAE.Exp inExp;
  input DAE.Dimensions inTypesArrayDimLst;
  input list<Slot> inSlotLst;
  input Boolean checkTypes "type checking only if true";
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output list<Slot> outSlotLst;
algorithm
  outSlotLst := matchcontinue (inFuncArg,inExp,inTypesArrayDimLst,inSlotLst,checkTypes,inPrefix,info)
    local
      String fa1,fa2,fa;
      DAE.Exp exp;
      DAE.Dimensions ds;
      DAE.Type b;
      list<Slot> xs,newslots;
      DAE.FuncArg farg,farg1,farg2;
      Slot s1;
      Prefix.Prefix pre;
      String ps,str1,str2;
      DAE.Const c1,c2;
      Option<DAE.Exp> oe;

    case ((fa1,b,c1,_),exp,ds,(SLOT(an = (fa2,_,c2,oe),slotFilled = false) :: xs),_,pre,_)
      equation
        true = stringEq(fa1, fa2);
        true = Types.constEqualOrHigher(c1,c2);
      then
        (SLOT((fa2,b,c2,oe),true,SOME(exp),ds) :: xs);

    // fail if variability is wrong
    case (farg1 as (fa1,_,c1,_),exp,ds,(SLOT(an = farg2 as (fa2,b,c2,_),slotFilled = false) :: xs),_,pre,_)
      equation
        true = stringEq(fa1, fa2);
        false = Types.constEqualOrHigher(c1,c2);
        str1 = ExpressionDump.printExpStr(exp);
        str2 = DAEUtil.constStrFriendly(c2);
        Error.addSourceMessage(Error.FUNCTION_SLOT_VARIABILITY, {fa1,str1,str2}, info);
      then
        fail();

    // fail if slot already filled
    case ((fa1,_,_,_),exp,ds,(SLOT(an = (fa2,b,_,_),slotFilled = true) :: xs), _,pre,_)
      equation
        true = stringEq(fa1, fa2);
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.FUNCTION_SLOT_ALLREADY_FILLED, {fa2,ps}, info);
      then
        fail();

    // no equal, try next
    case ((farg as (fa1,_,_,_)),exp,ds,((s1 as SLOT(an = (fa2,_,_,_))) :: xs),_,pre,_)
      equation
        false = stringEq(fa1, fa2);
        newslots = fillSlot(farg, exp, ds, xs,checkTypes,pre,info);
      then
        (s1 :: newslots);

    // failure
    case ((fa,_,_,_),_,_,{},_,pre,_)
      equation
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.NO_SUCH_ARGUMENT, {fa,ps}, info);
      then
        fail();
  end matchcontinue;
end fillSlot;

public function elabCref "
function: elabCref
  Elaborate on a component reference.  Check the type of the
  component referred to, and check if the environment contains
  either a constant binding for that variable, or if it contains an
  equation binding with a constant expression."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplict "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties,DAE.Attributes>> res;
algorithm
  (outCache,res) := elabCref1(inCache,inEnv,inComponentRef,inImplict,performVectorization,inPrefix,true,info);
end elabCref;

public function elabCrefNoEval "
  Some functions expect a DAE.ComponentRef back and use this instead of elabCref :)"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplict "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties,DAE.Attributes>> res;
algorithm
  (outCache,res) := elabCref1(inCache,inEnv,inComponentRef,inImplict,performVectorization,inPrefix,false,info);
end elabCrefNoEval;

protected function elabCref1 "
function: elabCref
  Elaborate on a component reference.  Check the type of the
  component referred to, and check if the environment contains
  either a constant binding for that variable, or if it contains an
  equation binding with a constant expression."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplict "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input Boolean evalCref;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties,DAE.Attributes>> res;
algorithm
  (outCache,res) := matchcontinue (inCache,inEnv,inComponentRef,inImplict,performVectorization,inPrefix,evalCref,info)
    local
      DAE.ComponentRef c_1;
      DAE.Const const,const1,const2,constCref,constSubs;
      DAE.TypeSource tySource;
      DAE.Type t,origt;
      DAE.Type tt;
      DAE.Exp exp,exp1,exp2,crefExp,expASUB;
      list<Env.Frame> env;
      Absyn.ComponentRef c;
      Env.Cache cache;
      Boolean impl,doVect,isBuiltinFn,isBuiltinFnOrInlineBuiltin,hasZeroSizeDim;
      DAE.Type et;
      String s,scope;
      InstTypes.SplicedExpData splicedExpData;
      Absyn.Path path,fpath;
      list<String> enum_lit_strs;
      String typeStr,id;
      DAE.ComponentRef expCref;
      Option<DAE.Const> forIteratorConstOpt;
      Prefix.Prefix pre;
      Absyn.Exp e;
      SCode.Element cl;
      DAE.FunctionBuiltin isBuiltin;
      DAE.Attributes attr;
      DAE.Binding binding "equation modification";
      Env.Frame frame;

    // wildcard
    case (cache,env,c as Absyn.WILD(),impl,doVect,_,_,_)
      equation
        t = DAE.T_ANYTYPE_DEFAULT;
        et = Types.simplifyType(t);
        crefExp = Expression.makeCrefExp(DAE.WILD(),et);
      then
        (cache,SOME((crefExp,DAE.PROP(t, DAE.C_VAR()),DAE.dummyAttrVar)));

    // Boolean => {false, true}
    case (cache, env, Absyn.CREF_IDENT(name = "Boolean"), _, _, _, _, _)
      equation
        exp = Expression.makeScalarArray({DAE.BCONST(false), DAE.BCONST(true)}, DAE.T_BOOL_DEFAULT);
        t = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
      then
        (cache, SOME((exp, DAE.PROP(t, DAE.C_CONST()), DAE.dummyAttrConst)));

    // MetaModelica arrays are only used in function context as IDENT, and at most one subscript
    // No vectorization is performed
    case (cache,env,c as Absyn.CREF_IDENT(name=id, subscripts={Absyn.SUBSCRIPT(e)}),impl,doVect,pre,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,SOME((exp1,DAE.PROP(DAE.T_METAARRAY(ty = t), const1),attr))) = elabCref1(cache,env,Absyn.CREF_IDENT(id,{}),false,false,pre,evalCref,info);
        (cache,exp2,DAE.PROP(DAE.T_INTEGER(varLst = _), const2),_) = elabExp(cache,env,e,impl,NONE(),false,pre,info);
        const = Types.constAnd(const1,const2);
        expASUB = Expression.makeASUB(exp1,{exp2});
      then
        (cache,SOME((expASUB,DAE.PROP(t, const),attr)));

    // a normal cref
    case (cache,env,c,impl,doVect,pre,_,_)
      equation
        c = replaceEnd(c);
        (cache,c_1,constSubs,hasZeroSizeDim) = elabCrefSubs(cache, env, c, Prefix.NOPRE(), impl, false, info);
        (cache,attr,t,binding,forIteratorConstOpt,splicedExpData,_,_,_) = Lookup.lookupVar(cache, env, c_1);
        // variability = applySubscriptsVariability(DAEUtil.getAttrVariability(attr), constSubs);
        // attr = DAEUtil.setAttrVariability(attr, variability);
        // get the binding if is a constant
        (cache,exp,constCref,attr) = elabCref2(cache, env, c_1, attr, constSubs, forIteratorConstOpt, t, binding, doVect, splicedExpData, pre, evalCref, info);
        const = constCref; // Types.constAnd(constCref, constSubs);
        exp = makeASUBArrayAdressing(c,cache,env,impl,exp,splicedExpData,doVect,pre,info);
        t = fixEnumerationType(t);
        (exp,const) = evaluateEmptyVariable(hasZeroSizeDim and evalCref,exp,t,const);
      then
        (cache,SOME((exp,DAE.PROP(t, const),attr)));

    // a normal cref, fully-qualified and lookupVar failed in some weird way in the previous case
    case (cache,env,Absyn.CREF_FULLYQUALIFIED(c),impl,doVect,pre,_,_)
      equation
        c = replaceEnd(c);
        frame = Env.topFrame(env);
        env = {frame};
        (cache,c_1,constSubs,hasZeroSizeDim) = elabCrefSubs(cache, env, c, Prefix.NOPRE(), impl, false, info);
        (cache,attr,t,binding,forIteratorConstOpt,splicedExpData,_,_,_) = Lookup.lookupVar(cache, env, c_1);
        // variability = applySubscriptsVariability(DAEUtil.getAttrVariability(attr), constSubs);
        // attr = DAEUtil.setAttrVariability(attr, variability);
        // get the binding if is a constant
        (cache,exp,constCref,attr) = elabCref2(cache, env, c_1, attr, constSubs, forIteratorConstOpt, t, binding, doVect, splicedExpData, pre, evalCref, info);
        const = constCref; // Types.constAnd(constCref, constSubs);
        exp = makeASUBArrayAdressing(c,cache,env,impl,exp,splicedExpData,doVect,pre,info);
        t = fixEnumerationType(t);
        (exp,const) = evaluateEmptyVariable(hasZeroSizeDim and evalCref,exp,t,const);
      then
        (cache,SOME((exp,DAE.PROP(t, const),attr)));

    // An enumeration type => array of enumeration literals.
    case (cache, env, c, impl, doVect, pre, _, _)
      equation
        c = replaceEnd(c);
        path = Absyn.crefToPath(c);
        (cache, cl as SCode.CLASS(restriction = SCode.R_ENUMERATION()), env) =
          Lookup.lookupClass(cache, env, path, false);
        typeStr = Absyn.pathLastIdent(path);
        path = Env.joinEnvPath(env, Absyn.IDENT(typeStr));
        enum_lit_strs = SCode.componentNames(cl);
        (exp, t) = makeEnumerationArray(path, enum_lit_strs);
      then
        (cache,SOME((exp,DAE.PROP(t, DAE.C_CONST()),DAE.dummyAttrConst /* RO */)));

    // MetaModelica Partial Function
    case (cache,env,c,impl,doVect,pre,_,_)
      equation
        // true = Flags.isSet(Flags.FNPTR) or Config.acceptMetaModelicaGrammar();
        path = Absyn.crefToPath(c);
        // call the lookup function that removes errors when it fails!
        (cache, {t}) = lookupFunctionsInEnvNoError(cache, env, path, info);
        (isBuiltin,isBuiltinFn,path) = isBuiltinFunc(path,t);
        isBuiltinFnOrInlineBuiltin = not valueEq(DAE.FUNCTION_NOT_BUILTIN(),isBuiltin);
        tySource = Types.getTypeSource(t);
        // some builtin functions store {} there
        tySource = Util.if_(isBuiltinFn, Types.mkTypeSource(SOME(path)), tySource);
        tt = Types.setTypeSource(t, tySource);
        origt = tt;
        {fpath} = Types.getTypeSource(t);
        t = Types.makeFunctionPolymorphicReference(t);
        c = Absyn.pathToCref(fpath);
        expCref = ComponentReference.toExpCref(c);
        exp = Expression.makeCrefExp(expCref,DAE.T_FUNCTION_REFERENCE_FUNC(isBuiltinFnOrInlineBuiltin,origt,tySource));
        // This is not done by lookup - only elabCall. So we should do it here.
        (cache,Util.SUCCESS()) = instantiateDaeFunction(cache,env,path,isBuiltinFn,NONE(),true);
      then
        (cache,SOME((exp,DAE.PROP(t,DAE.C_CONST()),DAE.dummyAttrConst /* RO */)));

    // MetaModelica extension
    case (cache,env,Absyn.CREF_IDENT("NONE",{}),impl,doVect,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        Error.addSourceMessage(Error.META_NONE_CREF, {}, info);
      then
        (cache,NONE());

    case (cache,env,c,impl,doVect,pre,_,_)
      equation
        // enabled with +d=failtrace
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabCref failed: " +&
          Dump.printComponentRefStr(c) +& " in env: " +&
          Env.printEnvPathStr(env));
        // Debug.traceln("ENVIRONMENT:\n" +& Env.printEnvStr(env));
      then
        fail();

    /*
    // maybe we do have it but without a binding, so maybe we can actually type it!
    case (cache,env,c,impl,doVect,pre,info)
      equation
        failure((_,_,_) = elabCrefSubs(cache,env, c, Prefix.NOPRE(),impl,info));
        id = Absyn.crefFirstIdent(c);
        (cache,DAE.TYPES_VAR(name, attributes, visibility, ty, binding, constOfForIteratorRange),
               SOME((cl as SCode.COMPONENT(n, pref, SCode.ATTR(arrayDims = ad), Absyn.TPATH(tpath, _),m,comment,cond,info),cmod)),instStatus,_)
          = Lookup.lookupIdent(cache, env, id);
        print("Static: cref:" +& Absyn.printComponentRefStr(c) +& " component first ident:\n" +& SCodeDump.unparseElementStr(cl) +& "\n");
        (cache, cl, env) = Lookup.lookupClass(cache, env, tpath, false);
        print("Static: cref:" +& Absyn.printComponentRefStr(c) +& " class component first ident:\n" +& SCodeDump.unparseElementStr(cl) +& "\n");
      then
        (cache,NONE());*/

    case (cache,env,c,impl,doVect,pre,_,_)
      equation
        failure((_,_,_,_) = elabCrefSubs(cache,env, c, Prefix.NOPRE(),impl,false,info));
        s = Dump.printComponentRefStr(c);
        scope = Env.printEnvPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR, {s,scope}, info); // - no need to add prefix info since problem only depends on the scope?
      then
        (cache,NONE());
  end matchcontinue;
end elabCref1;

protected function lookupFunctionsInEnvNoError
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outCache, outTypesTypeLst) := matchcontinue(inCache, inEnv, inPath, inInfo)

    case (_, _, _, _)
      equation
        ErrorExt.setCheckpoint("Static.lookupFunctionsInEnvNoError");
        (outCache, outTypesTypeLst) = Lookup.lookupFunctionsInEnv(inCache, inEnv, inPath, inInfo);
        // rollback lookup errors!
        ErrorExt.rollBack("Static.lookupFunctionsInEnvNoError");
      then
        (outCache, outTypesTypeLst);

    case (_, _, _, _)
      equation
        // rollback lookup errors!
        ErrorExt.rollBack("Static.lookupFunctionsInEnvNoError");
      then
        fail();
  end matchcontinue;
end lookupFunctionsInEnvNoError;


protected function evaluateEmptyVariable
  "A variable with a 0-length dimension can be evaluated.
  This is good to do because otherwise the C-code contains references to non-existing variables"
  input Boolean hasZeroSizeDim;
  input DAE.Exp inExp;
  input DAE.Type ty;
  input DAE.Const c;
  output DAE.Exp oexp;
  output DAE.Const oc;
algorithm
  (oexp,oc) := matchcontinue (hasZeroSizeDim,inExp,ty,c)
    local
      Boolean sc,a;
      DAE.Type et;
      list<DAE.Subscript> ss;
      DAE.ComponentRef cr;
      list<DAE.Exp> sub;
      DAE.Exp exp;

    case (true,DAE.ASUB(sub=sub),_,_)
      equation
        // TODO: Use a DAE.ERROR() or something if this has subscripts?
        a = Types.isArray(ty,{});
        sc = boolNot(a);
        et = Types.simplifyType(ty);
        exp = DAE.ARRAY(et,sc,{});
        exp = Expression.makeASUB(exp,sub);
      then (exp,c);

    case (true,DAE.CREF(componentRef=cr),_,_)
      equation
        a = Types.isArray(ty,{});
        sc = boolNot(a);
        et = Types.simplifyType(ty);
        {} = ComponentReference.crefLastSubs(cr);
        exp = DAE.ARRAY(et,sc,{});
      then (exp,c);

    case (true,DAE.CREF(componentRef=cr),_,_)
      equation
        // TODO: Use a DAE.ERROR() or something if this has subscripts?
        a = Types.isArray(ty,{});
        sc = boolNot(a);
        et = Types.simplifyType(ty);
        (ss as _::_) = ComponentReference.crefLastSubs(cr);
        exp = DAE.ARRAY(et,sc,{});
        exp = Expression.makeASUB(exp,List.map(ss,Expression.getSubscriptExp));
      then (exp,c);

    case (_,exp,_,_) then (exp,c);
  end matchcontinue;
end evaluateEmptyVariable;

public function fixEnumerationType
"Removes the index from an enumeration type."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      Absyn.Path p;
      list<String> n;
      list<DAE.Var> v, al;
      DAE.TypeSource ts;

    case DAE.T_ENUMERATION(index = SOME(_), path = p, names = n, literalVarLst = v, attributeLst = al, source = ts)
      then
        DAE.T_ENUMERATION(NONE(), p, n, v, al, ts);

    case _ then inType;
  end matchcontinue;
end fixEnumerationType;

public function applySubscriptsVariability
  "Takes the variability of a variable and the constness of it's subscripts and
  determines if the varibility of the variable should be raised. I.e.:
    parameter with variable subscripts => variable
    constant with variable subscripts => variable
    constant with parameter subscripts => parameter"
  input SCode.Variability inVariability;
  input DAE.Const inSubsConst;
  output SCode.Variability outVariability;
algorithm
  outVariability := matchcontinue(inVariability, inSubsConst)
    case (SCode.PARAM(), DAE.C_VAR()) then SCode.VAR();
    case (SCode.CONST(), DAE.C_VAR()) then SCode.VAR();
    case (SCode.CONST(), DAE.C_PARAM()) then SCode.PARAM();
    case (_, _) then inVariability;
  end matchcontinue;
end applySubscriptsVariability;

public function makeEnumerationArray
  "Expands an enumeration type to an array of it's enumeration literals."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  output DAE.Exp enumArray;
  output DAE.Type enumArrayType;

protected
  list<Absyn.Path> enum_lit_names;
  list<DAE.Exp> enum_lit_expl;
  Integer sz;
  DAE.Type ety;
algorithm
  enum_lit_expl := Expression.makeEnumLiterals(enumTypeName, enumLiterals);
  sz := listLength(enumLiterals);
  ety := DAE.T_ARRAY(DAE.T_ENUMERATION(NONE(), enumTypeName, enumLiterals, {}, {}, DAE.emptyTypeSource),
                     {DAE.DIM_ENUM(enumTypeName, enumLiterals, sz)},
                     DAE.emptyTypeSource);
  enumArray := DAE.ARRAY(ety, true, enum_lit_expl);
  enumArrayType := ety;
end makeEnumerationArray;

protected function makeASUBArrayAdressing
"This function remakes CREF subscripts to ASUB's of ASUB's
  a[1,index,y[z]] (CREF_IDENT(a,{1,DAE.INDEX(CREF_IDENT('index',{})),DAE.INDEX(CREF_IDENT('y',{DAE.INDEX(CREF_IDENT('z))})) ))
  to
  ASUB( exp = CREF_IDENT(a,{}),
   sub = {1,CREF_IDENT('index',{}), ASUB( exp = CREF_IDENT('y',{}), sub = {CREF_IDENT('z',{})})})
  will create nestled asubs for subscripts conaining crefs with subs."
  input Absyn.ComponentRef inRef;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Boolean inBoolean "implicit instantiation";
  input DAE.Exp inExp;
  input InstTypes.SplicedExpData splicedExpData;
  input Boolean doVect "if doVect is false, no vectorization and thus no ASUB addressing is performed";
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inRef,inCache,inEnv,inBoolean,inExp,splicedExpData,doVect,inPrefix,info)
    local
      DAE.Exp exp1,crefExp;
      list<Absyn.Subscript> assl;
      list<DAE.Subscript> essl;
      String id2;
      DAE.Type ty,ty2,tty2;
      DAE.ComponentRef cr,cref_;
      list<Env.Frame> env;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;
      list<DAE.Exp> exps;

    // return inExp if no vectorization is to be done
    case(_, _, _, _, _, _, false, _, _) then inExp;

    case(Absyn.CREF_IDENT(subscripts = assl), cache, env, impl,
        DAE.CREF(componentRef = DAE.CREF_IDENT(ident = id2, subscriptLst = essl)),
        _, _, pre, _)
      equation
        (_, _, DAE.C_VAR()) = elabSubscripts(cache, env, assl, impl, pre, info);
        exps = List.map(essl, Expression.subscriptIndexExp);
        (ty, ty2) = getSplicedCrefTypes(inExp, splicedExpData);
        cref_ = ComponentReference.makeCrefIdent(id2, ty2, {});
        crefExp = Expression.makeCrefExp(cref_, ty);
        exp1 = Expression.makeASUB(crefExp, exps);
      then
        exp1;

    case(_, _, _, _, DAE.CREF(componentRef =
          DAE.CREF_IDENT(ident = id2, subscriptLst = essl), ty = ty),
        InstTypes.SPLICEDEXPDATA(splicedExp = SOME(DAE.CREF(componentRef = cr))),
        _, _, _)
      equation
        tty2 = ComponentReference.crefLastType(cr);
        cref_ = ComponentReference.makeCrefIdent(id2, tty2, essl);
        exp1 = Expression.makeCrefExp(cref_, ty);
      then
        exp1;

    // Qualified cref, might be a package constant.
    case(_, _, _, _, DAE.CREF(componentRef = cr, ty = ty), _, _, _, _)
      equation
        (essl as _ :: _) = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        exps = List.map(essl, Expression.subscriptIndexExp);
        crefExp = Expression.crefExp(cr);
        exp1 = Expression.makeASUB(crefExp, exps);
      then
        exp1;

    else then inExp;
  end matchcontinue;
end makeASUBArrayAdressing;

protected function getSplicedCrefTypes
  "This function was refactored from makeASUBArrayAdressing to avoid
  elabSubscripts being called twice. If you understand what this function does,
  please update this comment."
  input DAE.Exp inCref;
  input InstTypes.SplicedExpData inSplicedExpData;
  output DAE.Type outType1;
  output DAE.Type outType2;
algorithm
  (outType1, outType2) := match(inCref, inSplicedExpData)
    local
      DAE.Type ty1, ty2;
      DAE.ComponentRef cr;

    case (_, InstTypes.SPLICEDEXPDATA(splicedExp = SOME(DAE.CREF(componentRef = cr))))
      equation
        ty2 = ComponentReference.crefLastType(cr);
      then
        (ty2, ty2);

    case (DAE.CREF(componentRef = DAE.CREF_IDENT(identType = ty2), ty = ty1), _)
      then (ty1, ty2);

  end match;
end getSplicedCrefTypes;

/* This function will be usefull when we implement Qualified subs such as:
a.b[1,j] or a[1].b[1,j]. As of now, a[j].b[i] will not be possible since
we can't know where b is located in a. but if a is non_array or a fully
adressed array(without variables), this is doable and this funtion can be used.
protected function allowQualSubscript ""
  input list<DAE.Subscript> subs;
  input DAE.Type ty;
  output Boolean bool;
algorithm bool := matchcontinue( subs, ty )
  local
    list<Option<Integer>> ad;
    list<list<Integer>> ill;
    list<Integer> il;
    Integer x,y;
  case({},ty as DAE.T_ARRAY(ty=_))
  then false;
  case({},_)
  then true;
  case(subs, ty as DAE.T_ARRAY(dims=ad))
    equation
      x = listLength(subs);
      ill = List.map(ad,Util.genericOption);
      il = List.flatten(ill);
      y = listLength(il);
      true = intEq(x, y );
    then
      true;
  case(_,_) equation print(" not allowed qual_asub\n"); then false;
end matchcontinue;
end allowQualSubscript;
*/

protected function fillCrefSubscripts
"This is a helper function to elab_cref2.
  It investigates a DAE.Type in order to fill the subscript lists of a
  component reference. For instance, the name a.b with the type array of
  one dimension will become a.b[:]."
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue (inComponentRef,inType/*,slicedExp*/)
    local
      DAE.ComponentRef e,cref_1,cref;
      DAE.Type t;
      list<DAE.Subscript> subs_1,subs;
      String id;
      DAE.Type ty2;
    // no subscripts
    case ((e as DAE.CREF_IDENT(subscriptLst = {})),t) then e;

    // simple ident with non-empty subscripts
    case ((e as DAE.CREF_IDENT(ident = id, identType = ty2, subscriptLst = subs)),t)
      equation
        subs_1 = fillSubscripts(subs, t);
      then
        ComponentReference.makeCrefIdent(id,ty2,subs_1);
    // qualified ident with non-empty subscrips
    case (e as (DAE.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref,identType = ty2 )),t)
      equation
        // TODO!FIXME!
        // ComponentReference.makeCrefIdent(id, ty2, subs) = fillCrefSubscripts(ComponentReference.makeCrefIdent(id, ty2, subs),t);
        cref_1 = fillCrefSubscripts(cref, t);
      then
        ComponentReference.makeCrefQual(id,ty2,subs,cref_1);
  end matchcontinue;
end fillCrefSubscripts;

protected function fillSubscripts
"Helper function to fillCrefSubscripts."
  input list<DAE.Subscript> inExpSubscriptLst;
  input DAE.Type inType;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  outExpSubscriptLst := matchcontinue (inExpSubscriptLst,inType)
    local
      list<DAE.Subscript> subs_1,subs_2,subs;
      DAE.Type t;
      DAE.Subscript fs;
    // empty list
    case ({},DAE.T_ARRAY(ty = t))
      equation
        subs_1 = fillSubscripts({}, t);
        subs_2 = listAppend({DAE.WHOLEDIM()}, subs_1);
      then
        subs_2;
    // some subscripts present
    case ((fs :: subs),DAE.T_ARRAY(ty = t))
      equation
        subs_1 = fillSubscripts(subs, t);
      then
        (fs :: subs_1);
    // not an array type!
    case (subs,_) then subs;
  end matchcontinue;
end fillSubscripts;

protected function elabCref2
"This function check whether the component reference found in
  elabCref has a binding, and if that binding is constant.
  If the binding is a VALBOUND binding, the value is substituted.
  Constant values are e.g.:
    1+5, c1+c2, ps1+ps2, where c1 and c2 are Modelica constants,
                      ps1 and ps2 are structural parameters.

  Non Constant values are e.g.:
    p1+p2, x1x2, where p1,p2 are modelica parameters,
                 x1,x2 modelica variables."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.Attributes inAttributes;
  input DAE.Const constSubs;
  input Option<DAE.Const> forIteratorConstOpt;
  input DAE.Type inType;
  input DAE.Binding inBinding;
  input Boolean performVectorization "true => vectorized expressions";
  input InstTypes.SplicedExpData splicedExpData;
  input Prefix.Prefix inPrefix;
  input Boolean evalCref;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Const outConst;
  output DAE.Attributes outAttributes;
algorithm
  (outCache,outExp,outConst,outAttributes) :=
  matchcontinue (inCache,inEnv,inComponentRef,inAttributes,constSubs,forIteratorConstOpt,inType,inBinding,performVectorization,splicedExpData,inPrefix,evalCref,info)
    local
      DAE.Type  expTy;
      DAE.ComponentRef cr,cr_1,cref,cr2,subCr1,subCr2;
      DAE.Type t,tt,tp,idTp;
      DAE.Exp e,e_1,exp,index;
      Option<DAE.Exp> sexp;
      Values.Value v;
      list<Env.Frame> env;
      DAE.Const const;
      SCode.Variability var;
      DAE.Binding binding_1,bind;
      String s,str,scope,pre_str;
      DAE.Binding binding;
      Env.Cache cache;
      Boolean doVect,genWarning,scalar;
      DAE.Type expIdTy;
      Prefix.Prefix pre;
      Integer i;
      Absyn.Path p;
      DAE.Attributes attr, attr1, attr2;
      Absyn.InnerOuter io;
      list<DAE.Subscript> subsc;
      DAE.Subscript slice;
      list<DAE.Exp> arr;

    // If type not yet determined, component must be referencing itself.
    // The constantness is undecidable since binding is not available. return C_VAR
    case (cache,_,cr,attr,_,_,t as DAE.T_UNKNOWN(source = _),_,doVect,_,_,_,_)
      equation
        expTy = Types.simplifyType(t);
        // adrpo: 2010-11-09
        //  use the variability to generate the constantness
        //  instead of returning *variabile* variability DAE.C_VAR()
        const = Types.variabilityToConst(DAEUtil.getAttrVariability(attr));
      then
        (cache, DAE.CREF(cr,expTy), const, attr);

    // adrpo: report a warning if the binding came from a start value!
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,bind as DAE.EQBOUND(source = DAE.BINDING_FROM_START_VALUE()),doVect,_,_,_,_)
      equation
        true = Types.getFixedVarAttribute(tt);
        s = ComponentReference.printComponentRefStr(cr);
        pre_str = PrefixUtil.printPrefixStr2(inPrefix);
        s = pre_str +& s;
        str = DAEUtil.printBindingExpStr(inBinding);
        Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s,str}, info); // Don't add source info here... Many models give multiple errors that are not filtered out
        bind = DAEUtil.setBindingSource(bind, DAE.BINDING_FROM_DEFAULT_VALUE());
        (cache, e_1, const, attr) = elabCref2(cache,env,cr,attr,constSubs,forIteratorConstOpt,tt,bind,doVect,splicedExpData,inPrefix,evalCref,info);
      then
        (cache,e_1,const,attr);

    // a variable
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.VAR()),_,_,tt,_,doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = crefVectorize(doVect, Expression.makeCrefExp(cr_1,expTy), tt, sexp, expIdTy);
      then
        (cache,e,DAE.C_VAR(),attr);

    // a discrete variable
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.DISCRETE()),_,_,tt,_,doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
        expIdTy = Types.simplifyType(idTp);
        e = crefVectorize(doVect, Expression.makeCrefExp(cr_1,expTy), tt, NONE(), expIdTy);
      then
        (cache,e,DAE.C_VAR(),attr);

    // an enumeration literal -> simplify to a literal expression
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,DAE.T_ENUMERATION(index = SOME(i), path = p),_,_,_,_,true,_)
      equation
        p = Absyn.joinPaths(p, ComponentReference.crefLastPath(cr));
      then
        (cache, DAE.ENUM_LITERAL(p, i), DAE.C_CONST(), attr);

    // Don't evaluate constants if evalCref is false.
    case (cache, _, cr, attr as DAE.ATTR(variability = SCode.CONST()), _, _, tt, _, _, _, _, false, _)
      equation
        expTy = Types.simplifyType(tt);
      then
        (cache, Expression.makeCrefExp(cr,expTy), DAE.C_CONST(), attr);

    // a constant with variable subscript
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),DAE.C_VAR(),_,tt,binding,doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        cr2 = ComponentReference.crefStripLastSubs(cr);
        subsc = ComponentReference.crefLastSubs(cr);
        // print(ComponentReference.printComponentRefStr(cr) +& " is a constant with variable subscript and binding: " +& DAEUtil.printBindingExpStr(binding) +& "\n");
        (cache,v) = Ceval.cevalCref(cache,env,cr2,false,Absyn.MSG(info),0);
        // print("Got value: " +& ValuesUtil.valString(v) +& "\n");
        e = ValuesUtil.valueExp(v);
        e = Expression.makeASUB(e, List.map(subsc,Expression.getSubscriptExp));
        // print(ComponentReference.printComponentRefStr(cr) +& " is a constant with variable subscript and binding: " +& ExpressionDump.printB+& "\n");
      then
        (cache,e,DAE.C_VAR(),attr);

    /*/ a constant with parameter subscript
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),DAE.C_PARAM(),_,tt,binding,doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        cr2 = ComponentReference.crefStripLastSubs(cr);
        subsc = ComponentReference.crefLastSubs(cr);
        (cache,v) = Ceval.cevalCref(cache,env,cr2,false,Absyn.MSG(info),0);
        e = ValuesUtil.valueExp(v);
        e = Expression.makeASUB(e, List.map(subsc,Expression.getSubscriptExp));
      then
        (cache,e,DAE.C_PARAM(),attr);*/

    // a constant -> evaluate binding
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,binding,doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        true = Types.equivtypes(tt,idTp);
        (cache,v) = Ceval.cevalCrefBinding(cache,env,cr,binding,false,Absyn.MSG(info),0);
        e = ValuesUtil.valueExp(v);
        const = DAE.C_CONST(); //Types.constAnd(DAE.C_CONST(), constSubs);
      then
        (cache,e,const,attr);

    // a constant, couldn't evaluate binding, replace with it!
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,binding,doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        true = Types.equivtypes(tt,idTp);
        failure((_,_) = Ceval.cevalCrefBinding(cache,env,cr,binding,false,Absyn.MSG(info),0));
        // constant binding
        DAE.EQBOUND(exp = e, constant_ = DAE.C_CONST()) = binding;
        // adrpo: todo -> subscript the binding expression
        // subsc = ComponentReference.crefLastSubs(cr);
        // e = Expression.makeASUB(e, List.map(subsc,Expression.getSubscriptExp));
        const = DAE.C_CONST(); // const = Types.constAnd(DAE.C_CONST(), constSubs);
      then
        (cache,e,const,attr);

    // a constant, couldn't evaluate binding, replace with it!
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,binding,doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        true = Types.equivtypes(tt,idTp);
        failure((_,_) = Ceval.cevalCrefBinding(cache,env,cr,binding,false,Absyn.MSG(info),0));
        // constant binding
        DAE.VALBOUND(valBound = v) = binding;
        e = ValuesUtil.valueExp(v);
        // adrpo: todo -> subscript the binding expression
        // subsc = ComponentReference.crefLastSubs(cr);
        // e = Expression.makeASUB(e, List.map(subsc,Expression.getSubscriptExp));
        // const = Types.constAnd(DAE.C_CONST(), constSubs);
        const = DAE.C_CONST();
      then
        (cache,e,const,attr);

    // a constant with some for iterator constness -> don't constant evaluate
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,SOME(_),tt,_,doVect,_,_,_,_)
      equation
        expTy = Types.simplifyType(tt);
      then
        (cache,Expression.makeCrefExp(cr,expTy),DAE.C_CONST(),attr);

    // evaluate parameters only if "evalparam" or Config.getEvaluateParametersInAnnotations()is set
    // TODO! also ceval if annotation Evaluate=true.
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,DAE.VALBOUND(valBound = v),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        true = boolOr(Flags.isSet(Flags.EVAL_PARAM), Config.getEvaluateParametersInAnnotations());
        // make it a constant if evalparam is used
        attr = DAEUtil.setAttrVariability(attr, SCode.CONST());
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,NONE(),expIdTy);
        (cache,v,_) = Ceval.ceval(cache,env,e_1,false,NONE(),Absyn.MSG(info),0);
        e = ValuesUtil.valueExp(v);
      then
        (cache,e,DAE.C_PARAM(),attr);

    // a binding equation and evalparam
    case (cache,env,cr,attr as DAE.ATTR(variability = var),_,_,tt,DAE.EQBOUND(exp = exp,constant_ = const),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        true = SCode.isParameterOrConst(var);
        true = boolOr(Flags.isSet(Flags.EVAL_PARAM), Config.getEvaluateParametersInAnnotations());
        // make it a constant if evalparam is used
        attr = DAEUtil.setAttrVariability(attr, SCode.CONST());
        expTy = Types.simplifyType(tt) "Constants with equal bindings should be constant, i.e. true
                                    but const is passed on, allowing constants to have wrong bindings
                                    This must be caught later on.";
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,NONE(),expIdTy);
        (cache,v,_) = Ceval.ceval(cache,env,e_1,false,NONE(),Absyn.MSG(info),0);
        e = ValuesUtil.valueExp(v);
      then
        (cache,e,DAE.C_PARAM(),attr);

    // vectorization of parameters with valuebound
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,DAE.VALBOUND(valBound = v),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,NONE(),expIdTy);
      then
        (cache,e_1,DAE.C_PARAM(),attr);

    // a constant with a binding
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,DAE.EQBOUND(exp = exp,constant_ = DAE.C_CONST()),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt) "Constants with equal bindings should be constant, i.e. true
                                    but const is passed on, allowing constants to have wrong bindings
                                    This must be caught later on." ;
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = Expression.makeCrefExp(cr_1,expTy);
        e_1 = crefVectorize(doVect,e, tt,NONE(),expIdTy);
        (cache,v,_) = Ceval.ceval(cache,env,e_1,false,NONE(),Absyn.MSG(info),0);
        e_1 = ValuesUtil.valueExp(v);
      then
        (cache,e_1,DAE.C_CONST(),attr);

    // a constant array indexed by a for iterator -> transform into an array of values. HACK! HACK! UGLY! TODO! FIXME!
    // handles things like fcall(data[i]) in 1:X where data is a package constant of the form:
    // data={Common.SingleGasesData.N2,Common.SingleGasesData.H2,Common.SingleGasesData.CO,Common.SingleGasesData.O2,Common.SingleGasesData.H2O, Common.SingleGasesData.CO2}
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,DAE.EQBOUND(evaluatedExp = SOME(v),constant_ = DAE.C_CONST()),doVect,
          InstTypes.SPLICEDEXPDATA(SOME(DAE.CREF(componentRef = DAE.CREF_IDENT(subscriptLst = {DAE.INDEX(DAE.CREF(componentRef = subCr2)),slice as DAE.SLICE(_)}))),idTp),_,_,_)
      equation
        {DAE.INDEX(index as DAE.CREF(componentRef = subCr1))} = ComponentReference.crefLastSubs(cr);
        true = ComponentReference.crefEqual(subCr1, subCr2);
        DAE.SLICE(DAE.ARRAY(_, scalar, arr)) = slice;
        e_1 = ValuesUtil.valueExp(v);
        e_1 = DAE.ASUB(e_1, {index});
      then
        (cache,e_1,DAE.C_CONST(),attr);

    // vectorization of parameters with binding equations
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,DAE.EQBOUND(exp = exp ,constant_ = const),doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt) "parameters with equal binding becomes C_PARAM" ;
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,sexp,expIdTy);
      then
        (cache,e_1,DAE.C_PARAM(),attr);

    // variables with constant binding
    case (cache,env,cr,attr,_,_,tt,DAE.EQBOUND(exp = exp),doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt) "..the rest should be non constant, even if they have a constant binding." ;
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,NONE(),expIdTy);
        const = Types.variabilityToConst(DAEUtil.getAttrVariability(attr));
      then
        (cache,e_1,const,attr);

    // if value not constant, but references another parameter, which has a value perform value propagation.
    case (cache,env,cr,attr1,_,_,tp,DAE.EQBOUND(exp = DAE.CREF(componentRef = cref,ty = _),constant_ = DAE.C_VAR()),doVect,_,pre,_,_)
      equation
        (cache,attr2,t,binding_1,_,_,_,_,_) = Lookup.lookupVar(cache, env, cref);
        (cache,e,const,attr2) = elabCref2(cache,env,cref,attr2,DAE.C_VAR(),forIteratorConstOpt,t,binding_1,doVect,splicedExpData,pre,evalCref,info);
      then
        (cache,e,const,attr2);

    // report error
    case (cache,_,cr,_,_,_,_,DAE.EQBOUND(exp = exp,constant_ = DAE.C_VAR()),doVect,_,pre,_,_)
      equation
        s = ComponentReference.printComponentRefStr(cr);
        str = ExpressionDump.printExpStr(exp);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        s = pre_str +& s;
        Error.addSourceMessage(Error.CONSTANT_OR_PARAM_WITH_NONCONST_BINDING, {s,str}, info);
      then
        fail();

    // constants without value should not produce error if they are not in a simulation model!
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,NONE()/*not foriter*/,tt,DAE.UNBOUND(),doVect,_,pre,_,_)
      equation
        s = ComponentReference.printComponentRefStr(cr);
        scope = Env.printEnvPathStr(env);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        s = pre_str +& s;
        // Error.addSourceMessage(Error.NO_CONSTANT_BINDING, {s,scope}, info);
        Debug.fprintln(Flags.STATIC,"- Static.elabCref2 failed on: " +& pre_str +& s +& " with no constant binding in scope: " +& scope);
        expTy = Types.simplifyType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
        // tyStr = Types.printTypeStr(tt);
        // do not fail yet, just add an empty expression,
        // we check for empty exp and empty values in certain
        // places only, i.e. equations, array dimensions, final
        // DAE if is send to simulation! Modelica requires that
        // all things have a binding IN A SIMULATION MODEL!
        // e = DAE.EMPTY(scope, cr_1, expTy, tyStr);
        e = Expression.makeCrefExp(cr_1,expTy);
      then
        (cache,e,DAE.C_CONST(),attr);

    // parameters without value but with fixed=false is ok, these are given value during initialization. (as long as not for iterator)
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,NONE()/* not foriter*/,tt,DAE.UNBOUND(),
        doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
      equation
        false = Types.getFixedVarAttribute(tt);
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = crefVectorize(doVect, Expression.makeCrefExp(cr_1,expTy), tt, sexp,expIdTy);
      then
        (cache,e,DAE.C_PARAM(),attr);

    // outer parameters without value is ok.
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM(), innerOuter = io),_,_,tt,DAE.UNBOUND(),doVect,_,_,_,_)
      equation
        (_,true) = InnerOuter.innerOuterBooleans(io);
        expTy = Types.simplifyType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
      then
        (cache,Expression.makeCrefExp(cr_1,expTy),DAE.C_PARAM(),attr);

    // parameters without value with fixed=true or no fixed attribute set produce warning (as long as not for iterator)
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,DAE.UNBOUND(),doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),pre,_,_)
      equation
        /* Disable warning since this seems to be the wrong place to check it or the message is at least wrong
        genWarning = Types.isFixedWithNoBinding(tt, SCode.PARAM());
        s = ComponentReference.printComponentRefStr(cr);
        genWarning = not (boolNot(genWarning) or
                          Util.isSome(forIteratorConstOpt) or
                          Flags.getConfigBool(Flags.CHECK_MODEL));
        pre_str = PrefixUtil.printPrefixStr2(pre);
        // Don't generate warning if variable is for iterator, since it doesn't have a value (it's iterated over separately)
        s = pre_str +& s;
        Debug.bcall3(genWarning,Error.addSourceMessage,Error.UNBOUND_PARAMETER_WARNING,{s}, info);
        */
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect, Expression.makeCrefExp(cr_1,expTy), tt, sexp, expIdTy);
      then
        (cache,e_1,DAE.C_PARAM(),attr);

    // failure!
    case (cache,env,cr,attr,_,_,tp,bind,doVect,_,pre,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        Debug.fprint(Flags.FAILTRACE, "- Static.elabCref2 failed for: " +& pre_str +& ComponentReference.printComponentRefStr(cr) +& "\n env:" +& Env.printEnvStr(env));
      then
        fail();
  end matchcontinue;
end elabCref2;

public function crefVectorize
"This function takes a DAE.Exp and a DAE.Type and if the expression
  is a ComponentRef and the type is an array it returns an array of
  component references with subscripts for each index.
  For instance, parameter Real x[3];
  gives cref_vectorize('x', <arraytype>) => '{x[1],x[2],x[3]}
  This is needed since the DAE does not know what the variable 'x' is,
  it only knows the variables 'x[1]', 'x[2]' and 'x[3]'.
  NOTE: Currently only works for one and two dimensions."
  input Boolean performVectorization "if false, return input";
  input DAE.Exp inExp;
  input DAE.Type inType;
  input Option<DAE.Exp> splicedExp;
  input DAE.Type crefIdType "the type of the last cref ident, without considering subscripts. picked up from splicedExpData and used for crefs in vectorized exp";
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (performVectorization,inExp,inType,splicedExp,crefIdType)
    local
      Boolean b1,b2;
      DAE.Type exptp;
      DAE.Exp e;
      DAE.ComponentRef cr;
      DAE.Type t;
      DAE.Dimension d1, d2;
      Integer ds, ds2;

    // no vectorization
    case(false, e, _, _,_) then e;

    // types extending basictype
    case (_,e,DAE.T_SUBTYPE_BASIC(complexType = t),_,_)
      equation
        e = crefVectorize(true,e,t,NONE(),crefIdType);
      then e;

    // component reference and an array type with dimensions less than vectorization limit
    case (_, _, DAE.T_ARRAY(dims = {d1}, ty = DAE.T_ARRAY(dims = {d2})),
        SOME(DAE.CREF(componentRef = cr)), _)
      equation
        b1 = (Expression.dimensionSize(d1) < Config.vectorizationLimit());
        b2 = (Expression.dimensionSize(d2) < Config.vectorizationLimit());
        true = boolAnd(b1, b2) or Config.vectorizationLimit() == 0;
        e = elabCrefSlice(cr,crefIdType);
        e = elabMatrixToMatrixExp(e);
      then
        e;

    case (_, _, DAE.T_ARRAY(dims = {d1}, ty = t),
        SOME(DAE.CREF(componentRef = cr)), _)
      equation
        false = Types.isArray(t,{});
        true = (Expression.dimensionSize(d1) < Config.vectorizationLimit()) or Config.vectorizationLimit() == 0;
        e = elabCrefSlice(cr,crefIdType);
      then
        e;

    // matrix sizes > vectorization limit is not vectorized
    case (_, DAE.CREF(componentRef = cr, ty = exptp),
         DAE.T_ARRAY(dims = {d1}, ty = t as DAE.T_ARRAY(dims = {d2})),
         _, _)
      equation
        ds = Expression.dimensionSize(d1);
        ds2 = Expression.dimensionSize(d2);
        b1 = (ds < Config.vectorizationLimit());
        b2 = (ds2 < Config.vectorizationLimit());
        true = boolAnd(b1, b2) or Config.vectorizationLimit() == 0;
        e = createCrefArray2d(cr, 1, ds, ds2, exptp, t,crefIdType);
      then
        e;

    // vectorsizes > vectorization limit is not vectorized
    case (_,DAE.CREF(componentRef = cr,ty = exptp),
         DAE.T_ARRAY(dims = {d1},ty = t),
         _,_)
      equation
        false = Types.isArray(t,{});
        ds = Expression.dimensionSize(d1);
        true = ds < Config.vectorizationLimit() or Config.vectorizationLimit() == 0;
        e = createCrefArray(cr, 1, ds, exptp, t,crefIdType);
      then
        e;
    case (_,e,_,_,_) then e;
  end matchcontinue;
end crefVectorize;

protected function extractDimensionOfChild
"A function for extracting the type-dimension of the child to *me* to dimension *my* array-size.
  Also returns wheter the array is a scalar or not."
  input DAE.Exp inExp;
  output DAE.Dimensions outExp;
  output Boolean isScalar;
algorithm
  (outExp,isScalar) := matchcontinue(inExp)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2;
      DAE.Type ety,ety2;
      DAE.Dimensions tl;
      Integer x;
      Boolean sc;

    case(exp1 as DAE.ARRAY(ty = (ety as DAE.T_ARRAY(ty=ety2, dims=(tl))),scalar=sc,array=expl1))
    then (tl,sc);

    case(exp1 as DAE.ARRAY(ty = _,scalar=_,array=expl1 as ((exp2 as DAE.ARRAY(_,_,_)) :: expl2)))
      equation
        (tl,_) = extractDimensionOfChild(exp2);
        x = listLength(expl1);
      then
        (DAE.DIM_INTEGER(x)::tl, false );

    case(exp1 as DAE.ARRAY(ty = _,scalar=_,array=expl1))
      equation
        x = listLength(expl1);
      then ({DAE.DIM_INTEGER(x)},true);

    case(exp1 as DAE.CREF(_ , _))
    then
      ({},true);
  end matchcontinue;
end extractDimensionOfChild;

protected function elabCrefSlice
"Bjozac, 2007-05-29  Main function from now for vectorizing output.
  the subscriptlist should contain either 'done slices' or numbers representing
 dimension entries.
Example:
1) a is a real[2,3] with no subscripts, the input here should be
CREF_IDENT('a',{DAE.SLICE(DAE.ARRAY(_,_,{1,2})), DAE.SLICE(DAE.ARRAY(_,_,{1,2,3}))})>
   ==> {{a[1,1],a[1,2],a[1,3]},{a[2,1],a[2,2],a[2,3]}}
2) a is a real[3,3] with subscripts {1,2},{1,3}, the input should be
CREF_IDENT('a',{DAE.SLICE(DAE.ARRAY(_,_,{DAE.INDEX(1),DAE.INDEX(2)})),
                DAE.SLICE(DAE.ARRAY(_,_,{DAE.INDEX(1),DAE.INDEX(3)}))})
   ==> {{a[1,1],a[1,3]},{a[2,1],a[2,3]}}"
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  output DAE.Exp outCref;
algorithm
  outCref := match(inCref, inType)
    local
      list<DAE.Subscript> ssl;
      String id;
      DAE.ComponentRef child;
      DAE.Exp exp1,childExp;
      DAE.Type ety;

    case( DAE.CREF_IDENT(ident = id,subscriptLst = ssl),ety)
      equation
        exp1 = flattenSubscript(ssl,id,ety);
      then
        exp1;
    case( DAE.CREF_QUAL(ident = id, subscriptLst = ssl, componentRef = child),ety)
      equation
        childExp = elabCrefSlice(child,ety);
        exp1 = flattenSubscript(ssl,id,ety);
        exp1 = mergeQualWithRest(exp1,childExp,ety) ;
      then
        exp1;
  end match;
end elabCrefSlice;

protected function mergeQualWithRest
"Incase we have a qual with child references, this function merges them.
  The input should be an array, or just one CREF_QUAL, of arrays...of arrays
  of CREF_QUALS and the same goes for 'rest'. Also the flat type as input."
  input DAE.Exp qual;
  input DAE.Exp rest;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(qual,rest,inType)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      DAE.Type ety;
      DAE.Dimensions iLst;
      Boolean scalar;
    // a component reference
    case(exp1 as DAE.CREF(_,_),exp2,_)
      equation
        exp1 = mergeQualWithRest2(exp2,exp1);
      then exp1;
    // an array
    case(exp1 as DAE.ARRAY(_, _, expl1),exp2,ety)
      equation
        expl1 = List.map2(expl1,mergeQualWithRest,exp2,ety);

        exp2 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Expression.arrayEltType(ety);
        exp2 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
    then exp2;
  end match;
end mergeQualWithRest;

protected function mergeQualWithRest2
"Helper to mergeQualWithRest, handles the case
  when the child-qual is arrays of arrays."
  input DAE.Exp rest;
  input DAE.Exp qual;
  output DAE.Exp outExp;
algorithm
  outExp := match(rest,qual)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      list<DAE.Subscript> ssl;
      DAE.ComponentRef cref,cref_2;
      String id;
      DAE.Type ety,ty2;
      DAE.Dimensions iLst;
      Boolean scalar;
    // a component reference
    case(exp1 as DAE.CREF(cref, ety),exp2 as DAE.CREF(DAE.CREF_IDENT(id,ty2, ssl),_))
      equation
        cref_2 = ComponentReference.makeCrefQual(id,ty2, ssl,cref);
        exp1 = Expression.makeCrefExp(cref_2,ety);
      then exp1;
    // an array
    case(exp1 as DAE.ARRAY(_, _, expl1), exp2 as DAE.CREF(DAE.CREF_IDENT(id,_, ssl),ety))
      equation
        expl1 = List.map1(expl1,mergeQualWithRest2,exp2);
        exp1 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp1);
        ety = Expression.arrayEltType(ety);
        exp1 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
      then exp1;
  end match;
end mergeQualWithRest2;

protected function flattenSubscript
"to catch subscript free CREF's."
  input list<DAE.Subscript> inSubs;
  input String name;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inSubs,name, inType)
    local
      String id;
      list<DAE.Subscript> subs1;
      DAE.Exp exp1,exp2;
      DAE.Type ety;
      DAE.ComponentRef cref_;
    // empty list
    case({},id,ety)
      equation
        cref_ = ComponentReference.makeCrefIdent(id,ety,{});
        exp1 = Expression.makeCrefExp(cref_,ety);
      then
        exp1;
    // some subscripts present
    case(subs1,id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
      then
        exp2;
  end matchcontinue;
end flattenSubscript;

// BZ(2010-01-29): Changed to public to be able to vectorize crefs from other places
public function flattenSubscript2
"This function takes the created 'invalid' subscripts
  and the name of the CREF and returning the CREFS
  Example: flattenSubscript2({SLICE({1,2}},SLICE({1}),\"a\",tp) ==> {{a[1,1]},{a[2,1]}}.

  This is done in several function calls, this specific
  function extracts the numbers ( 1,2 and 1 ).
  "
  input list<DAE.Subscript> inSubs;
  input String name;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inSubs,name, inType)
    local
      String id;
      DAE.Subscript sub1;
      list<DAE.Subscript> subs1;
      list<DAE.Exp> expl1,expl2;
      DAE.Exp exp1,exp2,exp3;
      DAE.Type ety;
      DAE.Dimensions iLst;
      Boolean scalar;

    // empty subscript
    case({},_,_) then DAE.ARRAY(DAE.T_UNKNOWN_DEFAULT,false,{});

    // first subscript integer, ety
    case( ( (sub1 as DAE.INDEX(exp = exp1 as DAE.ICONST(_))) :: subs1),id,ety)
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        //print("1. flattened rest into "+&ExpressionDump.dumpExpStr(exp2,0)+&"\n");
        exp2 = applySubscript(exp1, exp2 ,id,Expression.unliftArray(ety));
        //print("1. applied this subscript into "+&ExpressionDump.dumpExpStr(exp2,0)+&"\n");
      then
        exp2;
    // special case for zero dimension...
    case( ((sub1 as DAE.SLICE( exp2 as DAE.ARRAY(_,_,(expl1 as DAE.ICONST(0)::{})) )):: subs1),id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        expl2 = List.map3(expl1,applySubscript,exp2,id,ety);
        exp3 = listNth(expl2,0);
        //exp3 = removeDoubleEmptyArrays(exp3);
      then
        exp3;
    // normal case;
    case( ((sub1 as DAE.SLICE( exp2 as DAE.ARRAY(_,_,expl1) )):: subs1),id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        expl2 = List.map3(expl1,applySubscript,exp2,id,ety);
        exp3 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl2);
        (iLst, scalar) = extractDimensionOfChild(exp3);
        ety = Expression.arrayEltType(ety);
        exp3 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl2);
        //exp3 = removeDoubleEmptyArrays(exp3);
      then
        exp3;
  end matchcontinue;
end flattenSubscript2;

protected function removeDoubleEmptyArrays
" A help function, to prevent the {{}} look of empty arrays."
  input DAE.Exp inArr;
  output DAE.Exp  outArr;
algorithm
  outArr := matchcontinue(inArr)
    local
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1,expl2,expl3;
      DAE.Type ty1,ty2;
      Boolean sc;
    case(exp1 as DAE.ARRAY(ty = _,scalar=_,array = expl1 as
      ((exp2 as DAE.ARRAY(ty=_,scalar=_,array={}))::{}) ))
      then
        exp2;
    case(exp1 as DAE.ARRAY(ty = ty1,scalar=sc,array = expl1 as
      ((exp2 as DAE.ARRAY(ty=ty2,scalar=_,array=expl2))::expl3) ))
      equation
        expl3 = List.map(expl1,removeDoubleEmptyArrays);
        exp1 = DAE.ARRAY(ty1, sc, (expl3));
      then
        exp1;
    case(exp1) then exp1;
    case(exp1)
      equation
        print("- Static.removeDoubleEmptyArrays failure for: " +& ExpressionDump.printExpStr(exp1) +& "\n");
      then
        fail();
  end matchcontinue;
end removeDoubleEmptyArrays;

protected function applySubscript
"here we apply the subscripts to the IDENTS of the CREF's.
  Special case for adressing INDEX[0], make an empty array.
  If we have an array of subscript, we call applySubscript2"
  input DAE.Exp inSub "dim n ";
  input DAE.Exp inSubs "dim >n";
  input String name;
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inSub, inSubs ,name, inType)
    local
      String id;
      DAE.Exp exp1,exp2;
      DAE.Type ety,crty;
      DAE.Dimensions arrDim;
      DAE.ComponentRef cref_;

    case(exp2,exp1 as DAE.ARRAY(DAE.T_ARRAY(ty =_, dims = arrDim) ,_,{}),id ,ety)
      equation
        true = Expression.arrayContainZeroDimension(arrDim);
      then exp1;

        /* add dimensions */
    case(exp1 as DAE.ICONST(integer=0),exp2 as DAE.ARRAY(DAE.T_ARRAY(ty =_, dims = arrDim) ,_,_),id ,ety)
      equation
        ety = Expression.arrayEltType(ety);
        exp1 = DAE.ARRAY(DAE.T_ARRAY(ety, DAE.DIM_INTEGER(0)::arrDim, DAE.emptyTypeSource),true,{});
      then exp1;

    case(exp1 as DAE.ICONST(integer=0),_,_ ,ety)
      equation
        ety = Expression.arrayEltType(ety);
        exp1 = DAE.ARRAY(DAE.T_ARRAY(ety,{DAE.DIM_INTEGER(0)}, DAE.emptyTypeSource),true,{});
      then exp1;

    case(exp1,DAE.ARRAY(_,_,{}),id ,ety)
      equation
        true = Expression.isValidSubscript(exp1);
        crty = Expression.unliftArray(ety) "only subscripting one dimension, unlifting once ";
        cref_ = ComponentReference.makeCrefIdent(id,ety,{DAE.INDEX(exp1)});
        exp1 = Expression.makeCrefExp(cref_,crty);
      then exp1;

    case(exp1, exp2, id ,ety)
      equation
        true = Expression.isValidSubscript(exp1);
        exp1 = applySubscript2(exp1, exp2,ety);
      then exp1;
  end matchcontinue;
end applySubscript;

protected function applySubscript2
"Handles multiple subscripts for the expression.
  If it is an array, we listmap applySubscript3"
  input DAE.Exp inSub "The subs to add";
  input DAE.Exp inSubs "The already created subs";
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSub, inSubs, inType )
    local
      String id;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      list<DAE.Subscript> subs;
      DAE.Type ety,ty2,crty;
      DAE.Dimensions iLst;
      Boolean scalar;
      DAE.ComponentRef cref_;

    case(exp1 as DAE.ICONST(integer=_),exp2 as DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_ ),ety )
      equation
        crty = Expression.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        cref_ = ComponentReference.makeCrefIdent(id,ty2,(DAE.INDEX(exp1)::subs));
        exp2 = Expression.makeCrefExp(cref_,crty);
      then exp2;

    case(exp1 as DAE.ICONST(integer=_), exp2 as DAE.ARRAY(_,_,expl1),ety )
      equation
        expl1 = List.map2(expl1,applySubscript3,exp1,ety);
        exp2 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Expression.arrayEltType(ety);
        exp2 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
      then exp2;
  end match;
end applySubscript2;

protected function applySubscript3
"Final applySubscript function, here we call ourself
  recursive until we have the CREFS we are looking for."
  input DAE.Exp inSubs "The already created subs";
  input DAE.Exp inSub "The subs to add";
  input DAE.Type inType;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSubs,inSub, inType )
    local
      String id;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> expl1;
      list<DAE.Subscript> subs;
      DAE.Type ety,ty2,crty;
      DAE.Dimensions iLst;
      Boolean scalar;
      DAE.ComponentRef cref_;

    case(exp2 as DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_), exp1 as DAE.ICONST(integer=_),ety )
      equation
        crty = Expression.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        cref_ = ComponentReference.makeCrefIdent(id,ty2,(DAE.INDEX(exp1)::subs));
        exp2 = Expression.makeCrefExp(cref_,crty);
      then exp2;

    case( exp2 as DAE.ARRAY(_,_,expl1), exp1 as DAE.ICONST(integer=_),ety)
      equation
        expl1 = List.map2(expl1,applySubscript3,exp1,ety);
        exp2 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Expression.unliftArray(ety);
        exp2 = DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
      then exp2;
  end match;
end applySubscript3;


protected function callVectorize
"author: PA

  Takes an expression that is a function call and an expresion list
  and maps the call to each expression in the list.
  For instance, call_vectorize(DAE.CALL(XX(\"der\",),...),{1,2,3}))
  => {DAE.CALL(XX(\"der\"),{1}), DAE.CALL(XX(\"der\"),{2}),DAE.CALL(XX(\"der\",{3}))}
  NOTE: the vectorized expression is inserted first in the argument list
 of the call, so if extra arguments should be passed these can be given as
 input to the call expression."
  input DAE.Exp inExp;
  input list<DAE.Exp> inExpExpLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExp,inExpExpLst)
    local
      DAE.Exp e,callexp;
      list<DAE.Exp> es_1,args,es;
      Absyn.Path fn;
      Boolean tuple_,builtin;
      DAE.InlineType inl;
      DAE.Type tp;
      DAE.CallAttributes attr;
    // empty list
    case (e,{}) then {};
    // vectorize call
    case ((callexp as DAE.CALL(fn,args,attr)),(e :: es))
      equation
        es_1 = callVectorize(callexp, es);
      then
        (DAE.CALL(fn,(e :: args),attr) :: es_1);
    case (_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- Static.callVectorize failed");
      then
        fail();
  end matchcontinue;
end callVectorize;

protected function createCrefArray
"helper function to crefVectorize, creates each individual cref,
  e.g. {x{1},x{2}, ...} from x."
  input DAE.ComponentRef inComponentRef1;
  input Integer inInteger2;
  input Integer inInteger3;
  input DAE.Type inType4;
  input DAE.Type inType5;
  input DAE.Type crefIdType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inComponentRef1,inInteger2,inInteger3,inType4,inType5,crefIdType)
    local
      DAE.ComponentRef cr,cr_1;
      Integer indx,ds,indx_1;
      DAE.Type et,elt_tp;
      DAE.Type t;
      list<DAE.Exp> expl;
      DAE.Exp e_1;
    // index iterator dimension size
    case (cr,indx,ds,et,t,_)
      equation
        (indx > ds) = true;
      then
        DAE.ARRAY(et,true,{});
    // index
    /*
    case (cr,indx,ds,et,t,crefIdType)
      equation
        (DAE.INDEX(e_1) :: ss) = ComponentReference.crefLastSubs(cr);
        cr_1 = ComponentReference.crefStripLastSubs(cr);
        cr_1 = ComponentReference.subscriptCref(cr_1,ss);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr_1, indx, ds, et, t,crefIdType);
        expl = List.map1(expl,Expression.prependSubscriptExp,DAE.INDEX(e_1));
      then
        DAE.ARRAY(et,true,expl);
    */
    // for crefs with wholedim
    case (cr,indx,ds,et,t,_)
      equation
        indx_1 = indx + 1;
        DAE.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t,crefIdType);
        cr_1 = ComponentReference.replaceWholeDimSubscript(cr,indx);
        elt_tp = Expression.unliftArray(et);
        e_1 = crefVectorize(true,Expression.makeCrefExp(cr_1,elt_tp), t,NONE(),crefIdType);
      then
        DAE.ARRAY(et,true,(e_1 :: expl));
    // no subscript
    case (cr,indx,ds,et,t,_)
      equation
        indx_1 = indx + 1;
        // {} = ComponentReference.crefLastSubs(cr);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t,crefIdType);
        e_1 = Expression.makeASUB(Expression.makeCrefExp(cr,et),{DAE.ICONST(indx)});
        (e_1,_) = ExpressionSimplify.simplify(e_1);
        e_1 = crefVectorize(true,e_1, t,NONE(),crefIdType);
      then
        DAE.ARRAY(et,true,(e_1 :: expl));
    // failure
    case (cr,indx,ds,et,t,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "createCrefArray failed on:" +& ComponentReference.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end createCrefArray;

protected function createCrefArray2d
"helper function to cref_vectorize, creates each
  individual cref, e.g. {x{1,1},x{2,1}, ...} from x."
  input DAE.ComponentRef inComponentRef1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  input DAE.Type inType5;
  input DAE.Type inType6;
  input DAE.Type crefIdType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inComponentRef1,inInteger2,inInteger3,inInteger4,inType5,inType6,crefIdType)
    local
      DAE.ComponentRef cr,cr_1;
      Integer indx,ds,ds2,indx_1;
      DAE.Type et,tp,elt_tp;
      DAE.Type t;
      list<list<DAE.Exp>> ms;
      list<DAE.Exp> expl;
    // index iterator dimension size 1 dimension size 2
    case (cr,indx,ds,ds2,et,t,_)
      equation
        (indx > ds) = true;
      then
        DAE.MATRIX(et,0,{});
    // increase the index dimension
    case (cr,indx,ds,ds2,et,t,_)
      equation
        indx_1 = indx + 1;
        DAE.MATRIX(matrix = ms) = createCrefArray2d(cr, indx_1, ds, ds2, et, t,crefIdType);
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(indx))});
        elt_tp = Expression.unliftArray(et);
        DAE.ARRAY(tp,true,expl) = crefVectorize(true,Expression.makeCrefExp(cr_1,elt_tp), t,NONE(),crefIdType);
      then
        DAE.MATRIX(et,ds,(expl :: ms));
    //
    case (cr,indx,ds,ds2,et,t,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Static.createCrefArray2d failed on: " +& ComponentReference.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end createCrefArray2d;

public function absynCrefToComponentReference "This function converts an absyn cref to a component reference"
  input Absyn.ComponentRef inComponentRef;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inComponentRef)
    local
      String i;
      Boolean b;
      Absyn.ComponentRef c;
      DAE.ComponentRef cref;

    case Absyn.CREF_IDENT(name = i,subscripts = {})
      equation
        cref = ComponentReference.makeCrefIdent(i, DAE.T_UNKNOWN_DEFAULT, {});
      then
        cref;

    case Absyn.CREF_QUAL(name = i,subscripts = {},componentRef = c)
      equation
        cref = absynCrefToComponentReference(c);
        cref = ComponentReference.makeCrefQual(i, DAE.T_UNKNOWN_DEFAULT, {}, cref);
      then
        cref;

    case Absyn.CREF_FULLYQUALIFIED(componentRef = c)
      equation
        cref = absynCrefToComponentReference(c);
      then
        cref;
  end match;
end absynCrefToComponentReference;

protected function elabCrefSubs
"This function elaborates on all subscripts in a component reference."
  input Env.Cache inCache;
  input Env.Env inCrefEnv "search for the cref in this environment";
  input Absyn.ComponentRef inComponentRef;
  input Prefix.Prefix inCrefPrefix "the accumulated cref, required for lookup";
  input Boolean inBoolean;
  input Boolean inHasZeroSizeDim;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
  output DAE.Const outConst "The constness of the subscripts. Note: This is not the same as
  the constness of a cref with subscripts! (just becase x[1,2] has a constant subscript list does
  not mean that the variable x[1,2] is constant)";
  output Boolean outHasZeroSizeDim;
algorithm
  (outCache,outComponentRef,outConst,outHasZeroSizeDim) := matchcontinue (inCache,inCrefEnv,inComponentRef,inCrefPrefix,inBoolean,inHasZeroSizeDim,info)
    local
      DAE.Type t;
      DAE.Dimensions sl;
      DAE.Const const,const1,const2;
      list<Env.Frame> crefEnv;
      String id;
      list<Absyn.Subscript> ss;
      Boolean impl, hasZeroSizeDim;
      DAE.ComponentRef cr;
      Absyn.ComponentRef absynCr;
      DAE.Type ty;
      list<DAE.Subscript> ss_1;
      Absyn.ComponentRef restCref,absynCref;
      Env.Cache cache;
      SCode.Variability vt;
      Prefix.Prefix crefPrefix;

    // IDENT
    case (cache,crefEnv,Absyn.CREF_IDENT(name = id,subscripts = ss),crefPrefix,impl,hasZeroSizeDim,_)
      equation
        // Debug.traceln("Try elabSucscriptsDims " +& id);
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        // print("elabCrefSubs type of: " +& id +& " is " +& Types.printTypeStr(t) +& "\n");
        // Debug.traceln("    elabSucscriptsDims " +& id +& " got var");
        ty = Types.simplifyType(t);
        hasZeroSizeDim = Types.isZeroLengthArray(ty);
        sl = Types.getDimensions(t);
        // Constant evaluate subscripts on form x[1,p,q] where p,q are constants or parameters
        (cache,ss_1,const) = elabSubscriptsDims(cache, crefEnv, ss, sl, impl, crefPrefix, info);
      then
        (cache,ComponentReference.makeCrefIdent(id,ty,ss_1),const,hasZeroSizeDim);

    // QUAL,with no subscripts => looking for var in the top env!
    case (cache,crefEnv,Absyn.CREF_QUAL(name = id,subscripts = {},componentRef = restCref),crefPrefix,impl,hasZeroSizeDim,_)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        //print("env:");print(Env.printEnvStr(env));print("\n");
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        ty = Types.simplifyType(t);
        crefPrefix = PrefixUtil.prefixAdd(id,{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, restCref, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache,ComponentReference.makeCrefQual(id,ty,{},cr),const,hasZeroSizeDim);

    // QUAL,with no subscripts second case => look for class
    case (cache,crefEnv,Absyn.CREF_QUAL(name = id,subscripts = {},componentRef = restCref),crefPrefix,impl,hasZeroSizeDim,_)
      equation
        crefPrefix = PrefixUtil.prefixAdd(id,{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, restCref, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache,ComponentReference.makeCrefQual(id,DAE.T_COMPLEX_DEFAULT,{},cr),const,hasZeroSizeDim);

    // QUAL,with constant subscripts
    case (cache,crefEnv,Absyn.CREF_QUAL(name = id,subscripts = ss as _::_,componentRef = restCref),crefPrefix,impl,hasZeroSizeDim,_)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,DAE.ATTR(variability = vt),t,_,_,_,_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        sl = Types.getDimensions(t);
        ty = Types.simplifyType(t);
        (cache,ss_1,const1) = elabSubscriptsDims(cache, crefEnv, ss, sl, impl, crefPrefix, info);
        crefPrefix = PrefixUtil.prefixAdd(id, ss_1, crefPrefix, vt, ClassInf.UNKNOWN(Absyn.IDENT("")));
        (cache,cr,const2,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, restCref, crefPrefix, impl, hasZeroSizeDim, info);
        const = Types.constAnd(const1, const2);
      then
        (cache,ComponentReference.makeCrefQual(id,ty,ss_1,cr),const,hasZeroSizeDim);

    case (cache, crefEnv, Absyn.CREF_FULLYQUALIFIED(componentRef = absynCr), crefPrefix, impl, hasZeroSizeDim, _)
      equation
        (cache, cr, const1, hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, absynCr, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache, cr, const1, hasZeroSizeDim);

    // failure
    case (cache,crefEnv,absynCref,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        // FAILTRACE REMOVE
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabCrefSubs failed on: " +&
        PrefixUtil.printPrefixStr(crefPrefix) +& "." +&
          Dump.printComponentRefStr(absynCref) +& " env: " +&
          Env.printEnvPathStr(crefEnv));
      then
        fail();
  end matchcontinue;
end elabCrefSubs;

public function elabSubscripts
"This function converts a list of Absyn.Subscript to a list of
  DAE.Subscript, and checks if all subscripts are constant.
  HJ: not checking for constant, returning if constant or not"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
  output DAE.Const outConst;
algorithm
  (outCache,outExpSubscriptLst,outConst) := match (inCache,inEnv,inAbsynSubscriptLst,inBoolean,inPrefix,info)
    local
      DAE.Subscript sub_1;
      DAE.Const const1,const2,const;
      list<DAE.Subscript> subs_1;
      list<Env.Frame> env;
      Absyn.Subscript sub;
      list<Absyn.Subscript> subs;
      Boolean impl;
      Env.Cache cache;
      Prefix.Prefix pre;

    // empty list
    case (cache,_,{},_,_,_) then (cache,{},DAE.C_CONST());
    // elab a subscript then recurse
    case (cache,env,(sub :: subs),impl,pre,_)
      equation
        (cache,sub_1,const1, _) = elabSubscript(cache,env, sub, impl,pre,info);
        (cache,subs_1,const2) = elabSubscripts(cache,env, subs, impl,pre,info);
        const = Types.constAnd(const1, const2);
      then
        (cache,(sub_1 :: subs_1),const);
  end match;
end elabSubscripts;

protected function elabSubscriptsDims
"Helper function to elabSubscripts"
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Subscript> subs;
  input DAE.Dimensions dims;
  input Boolean impl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Subscript> outSubs;
  output DAE.Const outConst;
algorithm
  (outCache,outSubs,outConst) := matchcontinue (cache,env,subs,dims,impl,inPrefix,info)
    local
      String s1,s2,sp;
      Prefix.Prefix pre;

    case (_,_,_,_,_,pre,_)
      equation
        ErrorExt.setCheckpoint("elabSubscriptsDims");
        (outCache, outSubs, outConst) = elabSubscriptsDims2(cache, env, subs, dims, impl, pre, info, DAE.C_CONST(), {});
        ErrorExt.rollBack("elabSubscriptsDims");
      then (outCache,outSubs,outConst);

    case (_,_,_,_,_,pre,_)
      equation
        // ErrorExt.delCheckpoint("elabSubscriptsDims");
        ErrorExt.rollBack("elabSubscriptsDims");
        s1 = Dump.printSubscriptsStr(subs);
        s2 = Types.printDimensionsStr(dims);
        sp = PrefixUtil.printPrefixStr3(pre);
        //print(" adding error for {{" +& s1 +& "}},,{{" +& s2 +& "}} ");
        Error.addSourceMessage(Error.ILLEGAL_SUBSCRIPT,{s1,s2,sp},info);
      then fail();
    end matchcontinue;
end elabSubscriptsDims;

protected function elabSubscriptsDims2
  "Helper function to elabSubscriptsDims."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Subscript> inSubscripts;
  input DAE.Dimensions inDimensions;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  input DAE.Const inConst;
  input list<DAE.Subscript> inElabSubscripts;
  output Env.Cache outCache;
  output list<DAE.Subscript> outSubscripts;
  output DAE.Const outConst;
algorithm
  (outCache, outSubscripts, outConst) :=
  match(inCache, inEnv, inSubscripts, inDimensions, inImpl, inPrefix,
      inInfo, inConst, inElabSubscripts)
    local
      Absyn.Subscript asub;
      list<Absyn.Subscript> rest_asub;
      DAE.Dimension dim;
      DAE.Dimensions rest_dims;
      DAE.Subscript dsub;
      list<DAE.Subscript> elabed_subs;
      DAE.Const const;
      Env.Cache cache;
      Option<DAE.Properties> prop;

    case (_, _, {}, _, _, _, _, _, _)
      then (inCache, listReverse(inElabSubscripts), inConst);

    case (_, _, asub :: rest_asub, dim :: rest_dims, _, _, _, _, _)
      equation
        (cache, dsub, const, prop) = elabSubscript(inCache, inEnv, asub, inImpl, inPrefix, inInfo);
        const = Types.constAnd(const, inConst);
        (cache, dsub) = elabSubscriptsDims3(cache, inEnv, dsub, dim, const, prop, inImpl, inInfo);
        elabed_subs = dsub :: inElabSubscripts;
        (cache, elabed_subs, const) = elabSubscriptsDims2(cache, inEnv, rest_asub, rest_dims, inImpl, inPrefix, inInfo, const, elabed_subs);
      then
        (cache, elabed_subs, const);

  end match;
end elabSubscriptsDims2;

protected function elabSubscriptsDims3
  "Helper function to elabSubscriptsDims2."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.Subscript inSubscript;
  input DAE.Dimension inDimension;
  input DAE.Const inConst;
  input Option<DAE.Properties> inProperties;
  input Boolean inImpl;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Subscript outSubscript;
algorithm
  (outCache, outSubscript) := matchcontinue(inCache, inEnv,
      inSubscript, inDimension, inConst, inProperties, inImpl, inInfo)
    local
      Env.Cache cache;
      DAE.Subscript sub;
      Integer int_dim;
      DAE.Properties prop;
      DAE.Type ty;
      DAE.Exp e;

    // If in for iterator loop scope the subscript should never be evaluated to
    // a value (since the parameter/const value of iterator variables are not
    // available until expansion, which happens later on)
    // Note that for loops are expanded 'on the fly' and should therefore not be
    // treated in this way.
    case (_, _, _, _, _, _, _, _)
      equation
        true = Env.inForOrParforIterLoopScope(inEnv);
        true = Expression.dimensionKnown(inDimension);
      then
        (inCache, inSubscript);

    // Keep non-fixed parameters.
    case (_, _, _, _, _, SOME(prop), _, _)
      equation
        true = Types.isParameter(inConst);
        ty = Types.getPropType(prop);
        false = Types.getFixedVarAttribute(ty);
      then
        (inCache, inSubscript);

    /*/ Keep parameters as they are:
    // adrpo 2012-12-02 this does not work as we need to evaluate final parameters!
    //                  and we have now way yet of knowing which ones those are
    case (_, _, _, _, _, _, _, _)
      equation
        true = Types.isParameter(inConst);
      then
        (inCache, inSubscript);*/

    // If the subscript contains a const then it should be evaluated to
    // the value.
    case (_, _, _, _, _, _, _, _)
      equation
        int_dim = Expression.dimensionSize(inDimension);
        true = Types.isParameterOrConstant(inConst);
        (cache, sub) = Ceval.cevalSubscript(inCache, inEnv, inSubscript, int_dim, inImpl, Absyn.MSG(inInfo), 0);
      then
        (cache, sub);

    case (_, _, _, DAE.DIM_EXP(exp=e), _, _, _, _)
      equation
        true = Types.isParameterOrConstant(inConst);
        (cache, Values.INTEGER(integer=int_dim), _) = Ceval.ceval(inCache,inEnv,e,true,NONE(),Absyn.MSG(inInfo),0);
        (cache, sub) = Ceval.cevalSubscript(inCache, inEnv, inSubscript, int_dim, inImpl, Absyn.MSG(inInfo), 0);
      then
        (cache, sub);

    // If the previous case failed and we're just checking the model, try again
    // but skip the constant evaluation.
    case (_, _, _, _, _, _, _, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        true = Types.isParameterOrConstant(inConst);
      then
        (inCache, inSubscript);

    // If not constant, keep as is.
    case (_, _, _, _, _, _, _, _)
      equation
        true = Expression.dimensionKnown(inDimension);
        false = Types.isParameterOrConstant(inConst);
      then
        (inCache, inSubscript);

    // For unknown dimensions, ':', keep as is.
    case (_, _, _, DAE.DIM_UNKNOWN(), _, _, _, _)
      then (inCache, inSubscript);
    case (_, _, _, DAE.DIM_EXP(_), _, _, _, _)
      then (inCache, inSubscript);

  end matchcontinue;
end elabSubscriptsDims3;

protected function elabSubscript "This function converts an Absyn.Subscript to an
  DAE.Subscript."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Subscript inSubscript;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Subscript outSubscript;
  output DAE.Const outConst;
  output Option<DAE.Properties> outProperties;
algorithm
  (outCache, outSubscript, outConst, outProperties) :=
  matchcontinue(inCache, inEnv, inSubscript, inBoolean, inPrefix, info)
    local
      Boolean impl;
      DAE.Exp sub_1;
      DAE.Type ty;
      DAE.Const const;
      DAE.Subscript sub_2;
      list<Env.Frame> env;
      Absyn.Exp sub;
      Env.Cache cache;
      DAE.Properties prop;
      Prefix.Prefix pre;

    // no subscript
    case (cache, _, Absyn.NOSUB(), impl, _, _)
      then (cache, DAE.WHOLEDIM(), DAE.C_CONST(), NONE());

    // some subscript, try to elaborate it
    case (cache, env, Absyn.SUBSCRIPT(subscript = sub), impl, pre, _)
      equation
        (cache, sub_1, prop as DAE.PROP(constFlag = const), _) =
          elabExp(cache, env, sub, impl, NONE(), true, pre, info);
        (cache, sub_1, prop as DAE.PROP(type_ = ty)) =
          Ceval.cevalIfConstant(cache, env, sub_1, prop, impl, info);
        sub_2 = elabSubscriptType(ty, sub, sub_1, pre, env);
      then
        (cache, sub_2, const, SOME(prop));

    // failtrace
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabSubscript failed on " +&
          Dump.printSubscriptStr(inSubscript) +& " in env: " +&
          Env.printEnvPathStr(inEnv));
      then
        fail();
  end matchcontinue;
end elabSubscript;

protected function elabSubscriptType "This function is used to find the correct constructor for
  DAE.Subscript to use for an indexing expression.  If an integer
  is given as index, DAE.INDEX() is used, and if an integer array
  is given, DAE.SLICE() is used."
  input DAE.Type inType1;
  input Absyn.Exp inExp2;
  input DAE.Exp inExp3;
  input Prefix.Prefix inPrefix;
  input Env.Env inEnv;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := matchcontinue (inType1,inExp2,inExp3,inPrefix,inEnv)
    local
      DAE.Exp sub;
      String e_str,t_str,p_str;
      DAE.Type t;
      Absyn.Exp e;
      Prefix.Prefix pre;

    case (DAE.T_INTEGER(varLst = _),_,sub,_,_) then DAE.INDEX(sub);
    case (DAE.T_ENUMERATION(path = _),_,sub,_,_) then DAE.INDEX(sub);
    case (DAE.T_BOOL(varLst = _),_,sub,_,_) then DAE.INDEX(sub);
    case (DAE.T_ARRAY(ty = DAE.T_INTEGER(varLst = _)),_,sub,_,_) then DAE.SLICE(sub);

    // Modelica.Electrical.Analog.Lines.M_OLine.segment in MSL 3.1 uses a real
    // expression to index an array, which is not legal Modelica. But since we
    // want to support the MSL we allow it for that particular model only.
    case (DAE.T_REAL(varLst = _),_,sub,_, _)
      equation
        true = Absyn.pathPrefixOf(
          Absyn.stringListPath({"Modelica", "Electrical", "Analog", "Lines", "M_OLine", "segment"}),
          Env.getEnvName(inEnv));
      then DAE.INDEX(DAE.CAST(DAE.T_INTEGER_DEFAULT, sub));

    case (t,e,_,pre,_)
      equation
        e_str = Dump.printExpStr(e);
        t_str = Types.unparseType(t);
        p_str = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.SUBSCRIPT_NOT_INT_OR_INT_ARRAY, {e_str,t_str,p_str});
      then
        fail();
  end matchcontinue;
end elabSubscriptType;

protected function subscriptCrefType
"If a component of an array type is subscripted, the type of the
  component reference is of lower dimensionality than the
  component.  This function shows the function between the component
  type and the component reference expression type.

  This function might actually not be needed.
"
  input DAE.Exp inExp;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inExp,inType)
    local
      DAE.Type t_1,t;
      DAE.ComponentRef c;
      DAE.Exp e;

    case (DAE.CREF(componentRef = c),t)
      equation
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;

    case (e,t) then t;
  end matchcontinue;
end subscriptCrefType;

protected function subscriptCrefType2
  input DAE.ComponentRef inComponentRef;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inComponentRef,inType)
    local
      DAE.Type t,t_1;
      list<DAE.Subscript> subs;
      DAE.ComponentRef c;

    case (DAE.CREF_IDENT(subscriptLst = {}),t) then t;
    case (DAE.CREF_IDENT(subscriptLst = subs),t)
      equation
        t_1 = subscriptType(t, subs);
      then
        t_1;
    case (DAE.CREF_QUAL(componentRef = c),t)
      equation
        t_1 = subscriptCrefType2(c, t);
      then
        t_1;
  end matchcontinue;
end subscriptCrefType2;

protected function subscriptType "Given an array dimensionality and a list of subscripts, this
  function reduces the dimensionality.
  This does not handle slices or check that subscripts are not out
  of bounds."
  input DAE.Type inType;
  input list<DAE.Subscript> inExpSubscriptLst;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inType,inExpSubscriptLst)
    local
      DAE.Type t,t_1;
      list<DAE.Subscript> subs;
      DAE.Dimension dim;
      DAE.TypeSource ts;

    case (t,{}) then t;

    case (DAE.T_ARRAY(dims = {DAE.DIM_INTEGER(integer = _)}, ty = t),(DAE.INDEX(exp = _) :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        t_1;

    case (DAE.T_ARRAY(dims = {dim}, ty = t, source = ts),(DAE.SLICE(exp = _) :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        DAE.T_ARRAY(t_1,{dim},ts);

    case (DAE.T_ARRAY(dims = {dim}, ty = t, source = ts),(DAE.WHOLEDIM() :: subs))
      equation
        t_1 = subscriptType(t, subs);
      then
        DAE.T_ARRAY(t_1,{dim},ts);

    case (t,_)
      equation
        Print.printBuf("- subscript_type failed (");
        Print.printBuf(Types.printTypeStr(t));
        Print.printBuf(" , [...])\n");
      then
        fail();
  end matchcontinue;
end subscriptType;

protected function makeIfexp "This function elaborates on the parts of an if expression."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input DAE.Properties inProperties3;
  input DAE.Exp inExp4;
  input DAE.Properties inProperties5;
  input DAE.Exp inExp6;
  input DAE.Properties inProperties7;
  input Boolean inBoolean8;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv1,inExp2,inProperties3,inExp4,inProperties5,inExp6,inProperties7,inBoolean8,inST,inPrefix,inInfo)
    local
      DAE.Const c,c1,c2,c3;
      DAE.Exp exp,e1,e2,e3,e2_1,e3_1;
      list<Env.Frame> env;
      DAE.Type t2,t3,t2_1,t3_1,t1,ty;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      String e_str,t_str,e1_str,t1_str,e2_str,t2_str,pre_str;
      Env.Cache cache;
      Prefix.Prefix pre;

    /*
    case (cache,env,e1,DAE.PROP(type_ = DAE.T_BOOL(varLst = _),constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,_, _)
      equation
        true = Types.semiEquivTypes(t2, t3);
        c = constIfexp(e1, c1, c2, c3);
        (cache,exp) = cevalIfexpIfConstant(cache,env, e1, e2, e3, c1, impl, st, inInfo);
      then
        (cache,exp,DAE.PROP(t2,c));
    */

    case (cache,env,e1,DAE.PROP(type_ = t1,constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,_, _)
      equation
        (e1,_) = Types.matchType(e1, t1, DAE.T_BOOL_DEFAULT, true);
        (t2_1,t3_1) = Types.ifExpMakeDimsUnknown(t2,t3);
        (e2_1,t2_1) = Types.matchType(e2, t2_1, t3_1, true);
        c = constIfexp(e1, c1, c2, c3) "then-part type converted to match else-part" ;
        (cache,exp,ty) = cevalIfexpIfConstant(cache,env, e1, e2_1, e3, c1, t2, t3, t2_1, impl, st, inInfo);
      then
        (cache,exp,DAE.PROP(ty,c));

    case (cache,env,e1,DAE.PROP(type_ = t1,constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,_, _)
      equation
        (e1,_) = Types.matchType(e1, t1, DAE.T_BOOL_DEFAULT, true);
        (t2_1,t3_1) = Types.ifExpMakeDimsUnknown(t2,t3);
        (e3_1,t3_1) = Types.matchType(e3, t3, t2, true);
        c = constIfexp(e1, c1, c2, c3) "else-part type converted to match then-part" ;
        (cache,exp,ty) = cevalIfexpIfConstant(cache,env, e1, e2, e3_1, c1, t2, t3, t3_1, impl, st, inInfo);
      then
        (cache,exp,DAE.PROP(t2,c));

    case (cache,env,e1,DAE.PROP(type_ = t1,constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,pre,_)
      equation
        failure((_,_) = Types.matchType(e1, t1, DAE.T_BOOL_DEFAULT, true));
        e_str = ExpressionDump.printExpStr(e1);
        t_str = Types.unparseType(t1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        t_str = t_str +& " (in component: "+&pre_str+&")";
        Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str,t_str}, inInfo);
      then
        fail();

    case (cache,env,e1,DAE.PROP(type_ = DAE.T_BOOL(varLst = _),constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,pre,_)
      equation
        false = Types.semiEquivTypes(t2, t3);
        e1_str = ExpressionDump.printExpStr(e2);
        t1_str = Types.unparseType(t2);
        e2_str = ExpressionDump.printExpStr(e3);
        t2_str = Types.unparseType(t3);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Types.typeErrorSanityCheck(t1_str, t2_str, inInfo);
        Error.addSourceMessage(Error.TYPE_MISMATCH_IF_EXP, {pre_str,e1_str,t1_str,e2_str,t2_str}, inInfo);
      then
        fail();

    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Print.printBuf("- Static.makeIfexp failed\n");
      then
        fail();
  end matchcontinue;
end makeIfexp;

protected function cevalIfexpIfConstant "author: PA
  Constant evaluates the condition of an expression if it is constants and
  elimitates the if expressions by selecting branch."
  input Env.Cache inCache;
  input Env.Env inEnv1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  input DAE.Exp inExp4;
  input DAE.Const inConst5;
  input DAE.Type trueType;
  input DAE.Type falseType;
  input DAE.Type defaultType;
  input Boolean inBoolean6;
  input Option<GlobalScript.SymbolTable> inST;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outCache,outExp,outType) :=
  matchcontinue (inCache,inEnv1,inExp2,inExp3,inExp4,inConst5,trueType,falseType,defaultType,inBoolean6,inST,inInfo)
    local
      list<Env.Frame> env;
      DAE.Exp e1,e2,e3,res;
      Boolean impl,cond;
      Option<GlobalScript.SymbolTable> st;
      Env.Cache cache;
      Absyn.Msg msg;
      DAE.Type ty;

    case (cache,env,e1,e2,e3,DAE.C_VAR(),_,_,_,impl,st,_) then (cache,DAE.IFEXP(e1,e2,e3),defaultType);
    case (cache,env,e1,e2,e3,DAE.C_PARAM(),_,_,_,impl,st,_)
      equation
        false = valueEq(Types.getDimensionSizes(trueType),Types.getDimensionSizes(falseType));
        // We have different dimensions in the branches, so we should consider the condition structural in order to handle more models
        (cache,Values.BOOL(cond),_) = Ceval.ceval(cache,env, e1, impl, st, Absyn.NO_MSG(),0);
        res = Util.if_(cond, e2, e3);
        ty = Util.if_(cond, trueType, falseType);
      then (cache,res,ty);
    case (cache,env,e1,e2,e3,DAE.C_PARAM(),_,_,_,impl,st,_) then (cache,DAE.IFEXP(e1,e2,e3),defaultType);
    case (cache,env,e1,e2,e3,DAE.C_CONST(),_,_,_,impl,st,_)
      equation
        msg = Util.if_(Env.inFunctionScope(env) or Env.inForOrParforIterLoopScope(env), Absyn.NO_MSG(), Absyn.MSG(inInfo));
        (cache,Values.BOOL(cond),_) = Ceval.ceval(cache,env, e1, impl, st,msg,0);
        res = Util.if_(cond, e2, e3);
        ty = Util.if_(cond, trueType, falseType);
      then
        (cache,res,ty);
    // Allow ceval of constant if expressions to fail. This is needed because of
    // the stupid Lookup which instantiates packages without modifiers.
    case (cache,env,e1,e2,e3,DAE.C_CONST(),_,_,_,impl,st,_)
      equation
        true = Env.inFunctionScope(env) or Env.inForOrParforIterLoopScope(env);
      then
        (cache, DAE.IFEXP(e1, e2, e3),defaultType);

  end matchcontinue;
end cevalIfexpIfConstant;

protected function constIfexp "Tests wether an *if* expression is constant.  This is done by
  first testing if the conditional is constant, and if so evaluating
  it to see which branch should be tested for constant-ness.
  This will miss some occations where the expression actually
  is constant, as in the expression *if x then 1.0 else 1.0*"
  input DAE.Exp inExp1;
  input DAE.Const inConst2;
  input DAE.Const inConst3;
  input DAE.Const inConst4;
  output DAE.Const outConst;
algorithm
  outConst := match (inExp1,inConst2,inConst3,inConst4)
    local DAE.Const const,c1,c2,c3;
    case (_,c1,c2,c3)
      equation
        const = List.fold({c1,c2,c3}, Types.constAnd, DAE.C_CONST());
      then
        const;
  end match;
end constIfexp;

protected function canonCref2 "This function relates a DAE.ComponentRef to its canonical form,
  which is when all subscripts are evaluated to constant values.
  If Such an evaluation is not possible, there is no canonical
  form and this function fails."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.ComponentRef inPrefixCref;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inPrefixCref,inBoolean)
    local
      list<DAE.Subscript> ss_1,ss;
      list<Env.Frame> env;
      String n;
      Boolean impl;
      Env.Cache cache;
      DAE.ComponentRef prefixCr,cr;
      list<Integer> sl;
      DAE.Type t;
      DAE.Type ty2;
    case (cache,env,DAE.CREF_IDENT(ident = n,identType = ty2, subscriptLst = ss),prefixCr,impl) /* impl */
      equation
        cr = ComponentReference.crefPrependIdent(prefixCr,n,{},ty2);
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr);
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache,env, ss, sl, impl, Absyn.NO_MSG(),0);
      then
        (cache,ComponentReference.makeCrefIdent(n,ty2,ss_1));
  end matchcontinue;
end canonCref2;

public function canonCref "Transform expression to canonical form
  by constant evaluating all subscripts."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean)
    local
      DAE.Type t;
      list<Integer> sl;
      list<DAE.Subscript> ss_1,ss;
      list<Env.Frame> env, componentEnv;
      String n;
      Boolean impl;
      DAE.ComponentRef c_1,c,cr;
      Env.Cache cache;
      DAE.Type ty2;

    // handle wild _
    case (cache,env,DAE.WILD(),impl)
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
        (cache,DAE.WILD());

    // an unqualified component reference
    case (cache,env,DAE.CREF_IDENT(ident = n,subscriptLst = ss),impl) /* impl */
      equation
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache, env, ComponentReference.makeCrefIdent(n,DAE.T_UNKNOWN_DEFAULT,{}));
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache, env, ss, sl, impl, Absyn.NO_MSG(),0);
        ty2 = Types.simplifyType(t);
      then
        (cache,ComponentReference.makeCrefIdent(n,ty2,ss_1));

    // a qualified component reference
    case (cache,env,DAE.CREF_QUAL(ident = n,subscriptLst = ss,componentRef = c),impl)
      equation
        (cache,_,t,_,_,_,_,componentEnv,_) = Lookup.lookupVar(cache, env, ComponentReference.makeCrefIdent(n,DAE.T_UNKNOWN_DEFAULT,{}));
        ty2 = Types.simplifyType(t);
        sl = Types.getDimensionSizes(t);
        (cache,ss_1) = Ceval.cevalSubscripts(cache, env, ss, sl, impl, Absyn.NO_MSG(),0);
       //(cache,c_1) = canonCref2(cache, env, c, ComponentReference.makeCrefIdent(n,ty2,ss), impl);
       (cache, c_1) = canonCref(cache, componentEnv, c, impl);
      then
        (cache,ComponentReference.makeCrefQual(n,ty2, ss_1,c_1));

    // failtrace
    case (cache,env,cr,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Static.canonCref failed, cr: ");
        Debug.traceln(ComponentReference.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end canonCref;

public function eqCref "- Equality functions
  function: eqCref

  This function checks if two component references can be considered
  equal and fails if not.  Two component references are equal if all
  corresponding identifiers are the same, and if the subscripts are
  equal, according to the function `eq_subscripts\'.
"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
algorithm
  _:=
  match (inComponentRef1,inComponentRef2)
    local
      String n1,n2;
      list<DAE.Subscript> s1,s2;
      DAE.ComponentRef c1,c2;
    case (DAE.CREF_IDENT(ident = n1,subscriptLst = s1),DAE.CREF_IDENT(ident = n2,subscriptLst = s2))
      equation
        true = stringEq(n1, n2);
        eqSubscripts(s1, s2);
      then
        ();
    case (DAE.CREF_QUAL(ident = n1,subscriptLst = s1,componentRef = c1),DAE.CREF_QUAL(ident = n2,subscriptLst = s2,componentRef = c2))
      equation
        true = stringEq(n1, n2);
        eqSubscripts(s1, s2);
        eqCref(c1, c2);
      then
        ();
  end match;
end eqCref;

protected function eqSubscripts "
  Two list of subscripts are equal if they are of equal length and
  all their elements are pairwise equal according to the function
  `eq_subscript\'.
"
  input list<DAE.Subscript> inExpSubscriptLst1;
  input list<DAE.Subscript> inExpSubscriptLst2;
algorithm
  _:=
  match (inExpSubscriptLst1,inExpSubscriptLst2)
    local
      DAE.Subscript s1,s2;
      list<DAE.Subscript> ss1,ss2;
    case ({},{}) then ();
    case ((s1 :: ss1),(s2 :: ss2))
      equation
        eqSubscript(s1, s2);
        eqSubscripts(ss1, ss2);
      then
        ();
  end match;
end eqSubscripts;

protected function eqSubscript "This function test whether two subscripts are equal.
  Two subscripts are equal if they have the same constructor, and
  if all corresponding expressions are either syntactically equal,
  or if they have the same constant value."
  input DAE.Subscript inSubscript1;
  input DAE.Subscript inSubscript2;
algorithm
  _ := match (inSubscript1,inSubscript2)
    local DAE.Exp s1,s2;
    case (DAE.WHOLEDIM(),DAE.WHOLEDIM()) then ();
    case (DAE.INDEX(exp = s1),DAE.INDEX(exp = s2))
      equation
        true = Expression.expEqual(s1, s2);
      then
        ();
  end match;
end eqSubscript;

/*
 * - Argument type casting and operator de-overloading
 *
 *  If a function is called with arguments that don\'t match the
 *  expected parameter types, implicit type conversions are performed
 *  in some cases.  Usually it is an integer argument that is promoted
 *  to a real.
 *
 *  Many operators in Modelica are overloaded, meaning that they can
 *  operate on several different types of arguments.  To describe what
 *  it means to add, say, an integer and a real number, the
 *  expressions have to be de-overloaded, with one operator for each
 *  distinct operation.
 */

protected function elabArglist
"Given a list of parameter types and an argument list, this
  function tries to match the two, promoting the type of
  arguments when necessary."
  input list<DAE.Type> inTypesTypeLst;
  input list<tuple<DAE.Exp, DAE.Type>> inTplExpExpTypesTypeLst;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  (outExpExpLst,outTypesTypeLst) := match (inTypesTypeLst,inTplExpExpTypesTypeLst)
    local
      DAE.Exp arg_1,arg;
      DAE.Type atype_1,pt,atype;
      list<DAE.Exp> args_1;
      list<DAE.Type> atypes_1,pts;
      list<tuple<DAE.Exp, DAE.Type>> args;

    // empty lists
    case ({},{}) then ({},{});

    // we have something
    case ((pt :: pts),((arg,atype) :: args))
      equation
        (arg_1,atype_1) = Types.matchType(arg, atype, pt, false);
        (args_1,atypes_1) = elabArglist(pts, args);
      then
        ((arg_1 :: args_1),(atype_1 :: atypes_1));
  end match;
end elabArglist;

protected function deoverload "Given several lists of parameter types and one argument list,
  this function tries to find one list of parameter types which
  is compatible with the argument list. It uses elabArglist to
  do the matching, which means that automatic type conversions
  will be made when necessary.  The new argument list, together
  with a new operator that corresponds to the parameter type list
  is returned.

  The basic principle is that the first operator that matches is chosen.
  ."
  input list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> inTplExpOperatorTypesTypeLstTypesTypeLst;
  input list<tuple<DAE.Exp, DAE.Type>> inTplExpExpTypesTypeLst;
  input Absyn.Exp aexp "for error-messages";
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output DAE.Operator outOperator;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Type outType;
algorithm
  (outOperator,outExpExpLst,outType) := matchcontinue (inTplExpOperatorTypesTypeLstTypesTypeLst,inTplExpExpTypesTypeLst,aexp,inPrefix,info)
    local
      list<DAE.Exp> exps,args_1;
      list<DAE.Type> types_1,params,tps;
      DAE.Type rtype_1,rtype;
      DAE.Operator op;
      list<tuple<DAE.Exp, DAE.Type>> args;
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> xs;
      Prefix.Prefix pre;
      DAE.Type ty;
      list<String> exps_str,tps_str;
      String estr, pre_str, s, tpsstr;

    case (((op,params,rtype) :: _),args,_,pre,_)
      equation
        //Debug.fprint(Flags.DOVL, stringDelimitList(List.map(params, Types.printTypeStr),"\n"));
        //Debug.fprint(Flags.DOVL, "\n===\n");
        (args_1,types_1) = elabArglist(params, args);
        rtype_1 = computeReturnType(op, types_1, rtype,pre,info);
        ty = Types.simplifyType(rtype_1);
        op = Expression.setOpType(op, ty);
      then
        (op,args_1,rtype_1);

    case ((_ :: xs),args,_,pre,_)
      equation
        (op,args_1,rtype) = deoverload(xs,args,aexp,pre,info);
      then
        (op,args_1,rtype);

    //Don't fail and dont print error messages. Operators can be overloaded
    //for records.
    //mahge: TODO move this to the proper place and print.
    case ({},args,_,pre,_)
      equation
        s = Dump.printExpStr(aexp);
        exps = List.map(args, Util.tuple21);
        tps = List.map(args, Util.tuple22);
        exps_str = List.map(exps, ExpressionDump.printExpStr);
        estr = stringDelimitList(exps_str, ", ");
        tps_str = List.map(tps, Types.unparseType);
        tpsstr = stringDelimitList(tps_str, ", ");
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {s,tpsstr,pre_str}, info);
      then
        fail();
  end matchcontinue;
end deoverload;

protected function computeReturnType "This function determines the return type of
  an operator and the types of the operands."
  input DAE.Operator inOperator;
  input list<DAE.Type> inTypesTypeLst;
  input DAE.Type inType;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inOperator,inTypesTypeLst,inType,inPrefix, inInfo)
    local
      DAE.Type typ1,typ2,rtype,etype,typ;
      String t1_str,t2_str,pre_str;
      DAE.Dimension n1,n2,m,n,m1,m2,p;
      Prefix.Prefix pre;

    case (DAE.ADD_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.ADD_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.ADD_ARR(ty = _),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector addition", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.SUB_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.SUB_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.SUB_ARR(ty = _),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector subtraction", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.MUL_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.MUL_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.MUL_ARR(ty = _),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector elementwise multiplication", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.DIV_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.DIV_ARR(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.DIV_ARR(ty = _),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"vector elementwise division", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    // Matrix[n,m]^i
    case (DAE.POW_ARR(ty = _),{typ1,typ2},_,_, _)
      equation
        2 = nDims(typ1);
        n = Types.getDimensionNth(typ1, 1);
        m = Types.getDimensionNth(typ1, 2);
        true = Expression.dimensionsKnownAndEqual(n, m);
      then
        typ1;

    case (DAE.POW_ARR2(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        typ1;

    case (DAE.POW_ARR2(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        typ1;

    case (DAE.POW_ARR2(ty = _),{typ1,typ2},_,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"elementwise vector^vector", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ1, typ2);
      then
        rtype;

    case (DAE.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype,_, _)
      equation
        true = Types.subtype(typ2, typ1);
      then
        rtype;

    case (DAE.MUL_SCALAR_PRODUCT(ty = _),{typ1,typ2},rtype,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"scalar product", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    // Vector[n]*Matrix[n,m] = Vector[m]
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_,_, _)
      equation
        1 = nDims(typ1);
        2 = nDims(typ2);

        n1 = Types.getDimensionNth(typ1, 1);
        n2 = Types.getDimensionNth(typ2, 1);
        m = Types.getDimensionNth(typ2, 2);

        true = isValidMatrixProductDims(n1, n2);
        etype = elementType(typ1);
        rtype = Types.liftArray(etype, m);
      then
        rtype;

    // Matrix[n,m]*Vector[m] = Vector[n]
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_,_, _)
      equation
        2 = nDims(typ1);
        1 = nDims(typ2);

        n = Types.getDimensionNth(typ1, 1);
        m1 = Types.getDimensionNth(typ1, 2);
        m2 = Types.getDimensionNth(typ2, 1);

        true = isValidMatrixProductDims(m1, m2);
        etype = elementType(typ2);
        rtype = Types.liftArray(etype, n);
      then
        rtype;

    // Matrix[n,m] * Matrix[m,p] = Matrix[n, p]
    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},_,_, _)
      equation
        2 = nDims(typ1);
        2 = nDims(typ2);

        n = Types.getDimensionNth(typ1, 1);
        m1 = Types.getDimensionNth(typ1, 2);
        m2 = Types.getDimensionNth(typ2, 1);
        p = Types.getDimensionNth(typ2, 2);

        true = isValidMatrixProductDims(m1, m2);
        etype = elementType(typ1);
        rtype = Types.liftArrayListDims(etype, {n, p});
      then
        rtype;

    case (DAE.MUL_MATRIX_PRODUCT(ty = _),{typ1,typ2},rtype,pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"matrix multiplication", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.MUL_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_, _) then typ1;  /* rtype */

    case (DAE.ADD_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_, _) then typ1;  /* rtype */

    case (DAE.SUB_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_, _) then typ2;  /* rtype */

    case (DAE.DIV_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_, _) then typ2;  /* rtype */

    case (DAE.DIV_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_, _) then typ1;  /* rtype */

    case (DAE.POW_ARRAY_SCALAR(ty = _),{typ1,typ2},rtype,_, _) then typ1;  /* rtype */

    case (DAE.POW_SCALAR_ARRAY(ty = _),{typ1,typ2},rtype,_, _) then typ2;  /* rtype */

    case (DAE.ADD(ty = _),_,typ,_, _) then typ;

    case (DAE.SUB(ty = _),_,typ,_, _) then typ;

    case (DAE.MUL(ty = _),_,typ,_, _) then typ;

    case (DAE.DIV(ty = _),_,typ,_, _) then typ;

    case (DAE.POW(ty = _),_,typ,_, _) then typ;

    case (DAE.UMINUS(ty = _),_,typ,_, _) then typ;

    case (DAE.UMINUS_ARR(ty = _),(typ1 :: _),_,_, _) then typ1;

    case (DAE.AND(ty = _), {typ1, typ2}, _, _, _)
      equation
        true = Types.equivtypes(typ1, typ2);
      then
        typ1;

    case (DAE.AND(ty = _), {typ1, typ2}, _, pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"and", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.OR(ty = _), {typ1, typ2}, _, _, _)
      equation
        true = Types.equivtypes(typ1, typ2);
      then
        typ1;

    case (DAE.OR(ty = _), {typ1, typ2}, _, pre, _)
      equation
        t1_str = Types.unparseType(typ1);
        t2_str = Types.unparseType(typ2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"or", pre_str, t1_str, t2_str}, inInfo);
      then
        fail();

    case (DAE.NOT(ty = _),{typ1},typ,_, _) then typ1;

    case (DAE.LESS(ty = _),_,typ,_, _) then typ;

    case (DAE.LESSEQ(ty = _),_,typ,_, _) then typ;

    case (DAE.GREATER(ty = _),_,typ,_, _) then typ;

    case (DAE.GREATEREQ(ty = _),_,typ,_, _) then typ;

    case (DAE.EQUAL(ty = _),_,typ,_, _) then typ;

    case (DAE.NEQUAL(ty = _),_,typ,_, _) then typ;

    case (DAE.USERDEFINED(fqName = _),_,typ,_, _) then typ;
  end matchcontinue;
end computeReturnType;

protected function isValidMatrixProductDims
  "Checks if two dimensions are equal, which is a prerequisite for matrix
  multiplication."
  input DAE.Dimension dim1;
  input DAE.Dimension dim2;
  output Boolean res;
algorithm
  res := matchcontinue(dim1, dim2)
    // The dimensions are both known and equal.
    case (_, _)
      equation
        true = Expression.dimensionsKnownAndEqual(dim1, dim2);
      then
        true;
    // If checkModel is used we might get unknown dimensions. So use
    // dimensionsEqual instead, which matches anything against DIM_UNKNOWN.
    case (_, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        true = Expression.dimensionsEqual(dim1, dim2);
      then
        true;
    case (_, _) then false;
  end matchcontinue;
end isValidMatrixProductDims;

public function nDims "Returns the number of dimensions of a Type."
  input DAE.Type inType;
  output Integer outInteger;
algorithm
  outInteger := match (inType)
    local
      Integer ns;
      DAE.Type t;
    case (DAE.T_INTEGER(varLst = _)) then 0;
    case (DAE.T_REAL(varLst = _)) then 0;
    case (DAE.T_STRING(varLst = _)) then 0;
    case (DAE.T_BOOL(varLst = _)) then 0;
    case (DAE.T_ARRAY(ty = t))
      equation
        ns = nDims(t);
      then
        ns + 1;
    case (DAE.T_SUBTYPE_BASIC(complexType = t))
      equation
        ns = nDims(t);
      then ns;
  end match;
end nDims;

protected function elementType "Returns the element type of a type, i.e. for arrays, return the
  element type, and for bulitin scalar types return the type itself."
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match (inType)
    local DAE.Type t,t_1;
    case ((t as DAE.T_INTEGER(varLst = _))) then t;
    case ((t as DAE.T_REAL(varLst = _))) then t;
    case ((t as DAE.T_STRING(varLst = _))) then t;
    case ((t as DAE.T_BOOL(varLst = _))) then t;
    case (DAE.T_ARRAY(ty = t))
      equation
        t_1 = elementType(t);
      then
        t_1;
    case (DAE.T_SUBTYPE_BASIC(complexType = t))
      equation
        t_1 = elementType(t);
      then t_1;
  end match;
end elementType;

/* We have these as constants instead of function calls as done previously
 * because it takes a long time to generate these types over and over again.
 * The types are a bit hard to read, but they are simply 1 through 9-dimensional
 * arrays of the basic types. */
protected constant list<DAE.Type> intarrtypes = {
  DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
protected constant list<DAE.Type> realarrtypes = {
  DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
protected constant list<DAE.Type> boolarrtypes = {
  DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
protected constant list<DAE.Type> stringarrtypes = {
  DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 1-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 2-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 3-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 4-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 5-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 6-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 7-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource), // 8-dim
  DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_ARRAY(DAE.T_STRING_DEFAULT,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource),{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource) // 9-dim
};
/* Simply a list of 9 of that basic type; used to match with the array types */
protected constant list<DAE.Type> inttypes = {
  DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT
};
protected constant list<DAE.Type> realtypes = {
  DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT
};
protected constant list<DAE.Type> stringtypes = {
  DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT
};



protected function typeIsRecord
  input DAE.Type inType1;
  output Boolean outBool;
algorithm
  outBool := match(inType1)
    case (DAE.T_COMPLEX(ClassInf.RECORD(_),_, _,_)) then true;
    case (DAE.T_ARRAY(DAE.T_COMPLEX(ClassInf.RECORD(_),_, _,_),_,_)) then true;
    else false;
  end match;

end typeIsRecord;

protected function getRecordPath
  input DAE.Type inType1;
  output Absyn.Path outPath;
algorithm
  outPath := match(inType1)
  local
    Absyn.Path path;
    case (DAE.T_COMPLEX(ClassInf.RECORD(_),_, _,{path})) then path;
    case (DAE.T_ARRAY(DAE.T_COMPLEX(ClassInf.RECORD(_),_, _,{path}),_,_)) then path;
    else fail();
  end match;

end getRecordPath;

protected function getCallPath
  input DAE.Exp inExp;
  output Absyn.Path outPath;
algorithm
  outPath := match(inExp)
  local
    Absyn.Path path;
    case (DAE.CALL(path,_,_)) then path;
    case (DAE.ARRAY(_, _, DAE.CALL(path,_,_)::_ )) then path;
    else fail();
  end match;

end getCallPath;

protected function isOpElemWise
  input Absyn.Operator inOper;
  output Boolean isElemWise;
algorithm
  isElemWise := match(inOper)
    case (Absyn.ADD_EW()) then true;
    case (Absyn.SUB_EW()) then true;
    case (Absyn.MUL_EW()) then true;
    case (Absyn.DIV_EW()) then true;
    case (Absyn.POW_EW()) then true;
    case (Absyn.UMINUS_EW()) then true;
  else false;
  end match;
end isOpElemWise;

public function isFuncWithArrayInput
  input DAE.Type inType;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(inType)
    local
      DAE.Type ty;
    case (DAE.T_FUNCTION((_, ty, _, _)::_, _, _, _))
    equation
        true = Types.arrayType(ty);
    then true;

    else false;
   end matchcontinue;
end isFuncWithArrayInput;

protected function OverloadingValidForSpec_3_2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Operator inOper;
  input Boolean isArray1;
  input Boolean isArray2;
  input list<DAE.Type> inTypeList;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inFuncArgs;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSyTabOpt;
  input Prefix.Prefix inPre;
  input Absyn.Info inInfo;
  input Boolean lastRound;    /*This is true if we have tried all possiblities and should print error.  ie all of => left, right implicit constr, right, left impl const*/
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;

algorithm
  (outCache,outExp,outProp) :=
  matchcontinue (inCache,inEnv,inOper,isArray1,isArray2,inTypeList,inPath,inFuncArgs,inImpl,inSyTabOpt,inPre,inInfo, lastRound)
      local
        list<DAE.Type> types,scalartypes, arraytypes;
        Env.Cache cache;
        DAE.Exp daeExp;
        DAE.Properties prop;
        String str1;
    /*
    case (_, _, _, {})
      equation
      Error.addSourceMessage(Error.INCOMPATIBLE_TYPES,
          {"Operator overload: No overloaded Operator found", "", "", ""}, inInfo);
      then fail();
      */

    // If both are scalars everything should be OK.
    case (_, _, _ ,false, false, types, _, _, _, _, _, _, _)
      equation
        (cache,SOME((daeExp,prop))) = elabCallArgs3(inCache,inEnv,types,inPath,inFuncArgs,{},inImpl,inSyTabOpt,inPre,inInfo);
      then (cache, daeExp, prop);

    // If the first one array and the second scalar with NON-ELEMWISE operation
    // we shouldn't expand. (remember here eventhough this
    // is normally invalid (e.g. {1,2} + 1),  the user might overload
    // the operator to match this kind of operation on his records..
    //)
    case (_, _, _ ,true, false, types, _, _, _, _, _, _, _)
      equation
        false = isOpElemWise(inOper);
        (arraytypes, scalartypes) = List.splitOnTrue(types,isFuncWithArrayInput);
        (cache,SOME((daeExp,prop))) = elabCallArgs3(inCache,inEnv,arraytypes,inPath,inFuncArgs,{},inImpl,inSyTabOpt,inPre,inInfo);
    then (cache, daeExp, prop);

    // the first one array the second a scalar with ELEMWISE operation
    // this should be expanded.
    case (_, _, _ ,true, false, types, _, _, _, _, _, _, _)
      equation
        true = isOpElemWise(inOper);
        (arraytypes, scalartypes) = List.splitOnTrue(types,isFuncWithArrayInput);
        (cache,SOME((daeExp,prop))) = elabCallArgs3(inCache,inEnv,scalartypes,inPath,inFuncArgs,{},inImpl,inSyTabOpt,inPre,inInfo);
    then (cache, daeExp, prop);

    // Both are arrays with NON-ELEMWISE operator
    // Try without expanding first. (see Complex.'*'.scalarProduct)
    case (_, _, _, true, true, types, _, _, _, _, _, _, _)
      equation
        false = isOpElemWise(inOper);
        (arraytypes, scalartypes) = List.splitOnTrue(types,isFuncWithArrayInput);
        (cache,SOME((daeExp,prop))) = elabCallArgs3(inCache,inEnv,arraytypes,inPath,inFuncArgs,{},inImpl,inSyTabOpt,inPre,inInfo);
    then (cache, daeExp, prop);

    // Both are arrays with NON-ELEMWISE operator
    // the above case (without Expanding) failed.)
    // Try expnding.
    // Spec 3.2 says this should be expanded for + and - by default.
    // The same way as {1,2} + {2,3} is expanded, i.e elementwise.
    // But this shouldn't be since, again, the user can overload for this
    // specific case. For now we print a warning and allow this
    // (allowed for all operators!!!)
    case (_, _, _, true, true, types, _, _, _, _, _, _, _)
      equation
        false = isOpElemWise(inOper);
        (arraytypes, scalartypes) = List.splitOnTrue(types,isFuncWithArrayInput);
        (cache,SOME((daeExp,prop))) = elabCallArgs3(inCache,inEnv,scalartypes,inPath,inFuncArgs,{},inImpl,inSyTabOpt,inPre,inInfo);

        str1 = "\n" +&
                  "- No exact match overloading found for operator '" +& Dump.opSymbol(inOper) +& "' " +&
                  "on record array of type: '" +& Absyn.pathString(Absyn.pathPrefix(inPath)) +& "'\n" +&
                   "- Automatically expanded using operator function: " +& Absyn.pathString(getCallPath(daeExp));
        Error.addSourceMessage(Error.OPERATOR_OVERLOADING_WARNING,
          {str1}, inInfo);
    then (cache, daeExp, prop);

    // Both are arrays with ELEMWISE operator
    // this should be expanded.
    case (_, _, _, true, true, types, _, _, _, _, _, _, _)
      equation
        true = isOpElemWise(inOper);
        (arraytypes, scalartypes) = List.splitOnTrue(types,isFuncWithArrayInput);
        (cache,SOME((daeExp,prop))) = elabCallArgs3(inCache,inEnv,scalartypes,inPath,inFuncArgs,{},inImpl,inSyTabOpt,inPre,inInfo);
    then (cache, daeExp, prop);

    // If this is the last round then print the error.
    case (_, _, _, _, _, _, _, _, _, _, _, _, true)
      equation
      str1 = "\n" +&
                 "- Failed to deoverload operator '" +& Dump.opSymbol(inOper) +& "' " +&
                 "  for record of type: '" +& Absyn.pathString(Absyn.pathPrefix(inPath));
      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_ERROR,
          {str1}, inInfo);
      then fail();

  end matchcontinue;
end OverloadingValidForSpec_3_2;


protected function userDefOperatorDeoverloadBinary
"used to resolve overloaded binary operators for operator records
It looks if there is an operator function defined for the specific
operation. If there is then it will call that function and returns the
resulting expression. "
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Operator inOper;
  input Absyn.Exp inExp1;
  input Absyn.Exp inExp2;
  input DAE.Type inType1;
  input DAE.Type inType2;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSyTabOpt;
  input Prefix.Prefix inPre;
  input Absyn.Info inInfo;
  input Boolean lastRound;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;

algorithm

  (outCache,outExp,outProp) :=
  matchcontinue (inCache, inEnv, inOper,inExp1,inExp2,inType1,inType2,inImpl,inSyTabOpt,inPre,inInfo,lastRound)
    local
      Boolean bool1,bool2;
      String str1;
      Absyn.Path path,path2;
      list<Absyn.Path> operNames;
      Env.Env recordEnv,operatorEnv,env;
      SCode.Element operatorCl;
      Env.Cache cache;
      list<DAE.Type> types;
      DAE.Properties prop;
      DAE.Type type1, type2;
      Absyn.Exp exp1,exp2;
      Absyn.Operator op;
      Absyn.ComponentRef comRef;
      DAE.Exp  daeExp;

   case (cache, env, op, exp1, exp2, type1, type2, _, _, _, _,_)
      equation

        // prepare the call path for the operator.
        // if *   => recordPath.'*'  , !!also if .*   => recordPath.'*'
        path = getRecordPath(type1);
        path = Absyn.makeFullyQualified(path);
        (cache,_,recordEnv) = Lookup.lookupClass(cache,env,path, false);

        str1 = "'" +& Dump.opSymbolCompact(op) +& "'";
        path = Absyn.joinPaths(path, Absyn.IDENT(str1));


        // check if the operator is defined. i.e overloaded
        (cache,operatorCl,operatorEnv) = Lookup.lookupClass(cache,recordEnv,path, false);
        true = SCode.isOperator(operatorCl);


        // get the list of functions in the operator. !! there can be multiple options
        operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(operatorCl);
        (cache,types) = Lookup.lookupFunctionsListInEnv(cache, operatorEnv, operNames, inInfo, {});

        // Apply operation according to the Specifications.See the function.
        bool1 = Types.arrayType(type1);
        bool2 = Types.arrayType(type2);
        (cache,daeExp,prop) = OverloadingValidForSpec_3_2(cache,env,op,bool1,bool2,types,path,{exp1,exp2},inImpl,inSyTabOpt,inPre,inInfo, false /*Never last round here. look down*/);

      then
        (cache,daeExp,prop);


    //Try constructing the right side(implicit) and then evaluate == L + r -> L.'+'(L,L(r))
    case (cache, env, op, exp1, exp2, type1, type2, _, _, _, _,_)
      equation

        path = getRecordPath(type1);
        path = Absyn.makeFullyQualified(path);
        (cache,_,recordEnv) = Lookup.lookupClass(cache,env,path, false);

        str1 = "'constructor'";
        path2 = Absyn.joinPaths(path, Absyn.IDENT(str1));

        (cache,operatorCl,operatorEnv) = Lookup.lookupClass(cache,recordEnv,path2, false);
        true = SCode.isOperator(operatorCl);

        operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(operatorCl);
        (cache,types) = Lookup.lookupFunctionsListInEnv(cache, operatorEnv, operNames, inInfo, {});

        (cache,SOME((daeExp, DAE.PROP(type2,_)))) = elabCallArgs3(cache,env,types,path2,{exp2},{},inImpl,inSyTabOpt,inPre,inInfo);

        path2 = getCallPath(daeExp);

        comRef = Absyn.pathToCref(path2);
        exp2 = Absyn.CALL(comRef, Absyn.FUNCTIONARGS({exp2}, {}));

        (cache, daeExp , prop) = userDefOperatorDeoverloadBinary(cache,env,op,exp1,exp2,type1,type2,inImpl,inSyTabOpt,inPre,inInfo, lastRound); /*Now it can be last round*/

      then
        (cache,daeExp,prop);

  end matchcontinue;

end userDefOperatorDeoverloadBinary;

protected function userDefOperatorDeoverloadString
"This functions checks if the builtin function string is overloaded for opertor records"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp1;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSyTabOpt;
  input Boolean inDoVect;
  input Prefix.Prefix inPre;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
  output Option<GlobalScript.SymbolTable> outSyTabOpt;

algorithm

  (outCache,outExp,outProp,outSyTabOpt) :=
  match (inCache, inEnv,inExp1,inImpl,inSyTabOpt,inDoVect,inPre,inInfo)
    local
      String str1;
      Absyn.Path path;
      Option<GlobalScript.SymbolTable> st_1;
      list<Absyn.Path> operNames;
      Env.Env recordEnv,operatorEnv,env;
      SCode.Element operatorCl;
      Env.Cache cache;
      list<DAE.Type> types;
      DAE.Properties prop;
      DAE.Type type1;
      Absyn.Exp exp1;
      DAE.Exp  daeExp;
      list<Absyn.Exp> restargs;
      list<Absyn.NamedArg> nargs;

    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("String",_),functionArgs = Absyn.FUNCTIONARGS(args = exp1::restargs,argNames = nargs)),_,_,_,_,_)
      equation
        (cache,_,DAE.PROP(type1,_),st_1) = elabExp(cache,env,exp1,inImpl,inSyTabOpt,inDoVect,inPre,inInfo);

        path = getRecordPath(type1);
        path = Absyn.makeFullyQualified(path);
        (cache,_,recordEnv) = Lookup.lookupClass(cache,env,path, false);

        str1 = "'String'";
        path = Absyn.joinPaths(path, Absyn.IDENT(str1));

        (cache,operatorCl,operatorEnv) = Lookup.lookupClass(cache,recordEnv,path, false);
        true = SCode.isOperator(operatorCl);

        operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(operatorCl);
        (cache,types as _::_) = Lookup.lookupFunctionsListInEnv(cache, operatorEnv, operNames, inInfo, {});

        (cache,SOME((daeExp,prop))) = elabCallArgs3(cache,env,types,path,exp1::restargs,nargs,inImpl,st_1,inPre,inInfo);
      then
        (cache,daeExp,prop,st_1);

   end match;

end userDefOperatorDeoverloadString;

protected function operatorDeoverloadBinary
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Operator inOperator1;
  input DAE.Properties inProp1;
  input DAE.Exp inExp1;
  input DAE.Properties inProp2;
  input DAE.Exp inExp2;
  input Absyn.Exp AbExp "needed for function replaceOperatorWithFcall (not  really sure what is done in there though.)";
  input Absyn.Exp AbExp1 "We need this when/if we elaborate user defined operator functions";
  input Absyn.Exp AbExp2 "We need this when/if we elaborate user defined operator functions";
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input Prefix.Prefix inPre "For error-messages only";
  input Absyn.Info inInfo "For error-messages only";
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outCache, outExp, outProp) :=
   matchcontinue(inCache,inEnv,inOperator1, inProp1, inExp1, inProp2, inExp2, AbExp, AbExp1, AbExp2, inImpl, inSymTab, inPre, inInfo)
       local
         Env.Cache cache;
         Env.Env env;
         list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> opList;
         DAE.Type type1,type2, otype;
         DAE.Exp exp1,exp2,exp;
         DAE.Const const1,const2, const;
         DAE.Operator oper;
         Absyn.Operator aboper;
         DAE.Properties prop, props1, props2;
         Absyn.Exp  absexp1, absexp2;
         Boolean lastRound;

     // handle tuple op non_tuple
     case (_, _, aboper, props1 as DAE.PROP_TUPLE(type_ = _), exp1, props2 as DAE.PROP(type_ = _), exp2, _, _, _, _, _, _, _)
       equation
         false = Config.acceptMetaModelicaGrammar();
         (prop as DAE.PROP(type1, const1)) = Types.propTupleFirstProp(props1);
         exp = DAE.TSUB(inExp1, 1, type1);
         (cache, exp, prop) = operatorDeoverloadBinary(inCache, inEnv, inOperator1, prop, exp, inProp2, inExp2, AbExp, AbExp1, AbExp2, inImpl, inSymTab, inPre, inInfo);
       then
         (inCache, exp, prop);

     // handle non_tuple op tuple
     case (_, _, aboper, props1 as DAE.PROP(type_ = _), exp1, props2 as DAE.PROP_TUPLE(type_ = _), exp2, _, _, _, _, _, _, _)
       equation
         false = Config.acceptMetaModelicaGrammar();
         (prop as DAE.PROP(type2, const2)) = Types.propTupleFirstProp(props2);
         exp = DAE.TSUB(inExp2, 1, type2);
         (cache, exp, prop) = operatorDeoverloadBinary(inCache, inEnv, inOperator1, inProp1, inExp1, prop, exp, AbExp, AbExp1, AbExp2, inImpl, inSymTab, inPre, inInfo);
       then
         (inCache, exp, prop);

     case (_, _, aboper, DAE.PROP(type1,const1), exp1, DAE.PROP(type2,const2), exp2, _, _, _, _, _, _, _)
       equation
         false = typeIsRecord(Types.arrayElementType(type1));
         false = typeIsRecord(Types.arrayElementType(type2));
         (opList, type1,exp1,type2,exp2) = operatorsBinary(aboper, type1, exp1, type2, exp2);
         (oper, {exp1,exp2}, otype) = deoverload(opList, {(exp1,type1), (exp2,type2)}, AbExp, inPre, inInfo);
         const = Types.constAnd(const1, const2);
         exp = replaceOperatorWithFcall(AbExp, exp1,oper,SOME(exp2), const);
         (exp,_) = ExpressionSimplify.simplify(exp);
         prop = DAE.PROP(otype,const);
         warnUnsafeRelations(inEnv,AbExp,const, type1,type2,exp1,exp2,oper,inPre);
       then
         (inCache,exp, prop);

      // The order of this two cases determines the priority given to operators
      // Now left has priority for all.
      // Different from spec a bit (They say it should be error if there are two possible matches)
      // Here it is evaluated by priority. Allows safe combination of code or libraries from two sources.
      // (e.g if they overload their operators for each others records.)

       // if we have a record on the left side check for overloaded operators
     case(cache, env, aboper, DAE.PROP(type1, const1), exp1, DAE.PROP(type2, const2), exp2, _, absexp1, absexp2, _, _, _, _)
       equation
         true = typeIsRecord(Types.arrayElementType(type1));

         // If the right side is not record then (lastRound is true) which means we should print errors on this round (last one:).
         lastRound = not typeIsRecord(Types.arrayElementType(type2));

         (cache, exp , prop) = userDefOperatorDeoverloadBinary(cache,env,aboper,absexp1,absexp2,type1,type2,inImpl,inSymTab,inPre,inInfo,lastRound /**/);
         (exp,_) = ExpressionSimplify.simplify(exp);
       then
         (cache, exp, prop);

      // if we have a record on the right side check for overloaded operators
     case(cache, env, aboper, DAE.PROP(type1, const1), exp1, DAE.PROP(type2, const2), exp2, _, absexp1, absexp2, _, _, _, _)
       equation
         true = typeIsRecord(Types.arrayElementType(type2));
         (cache, exp , prop) = userDefOperatorDeoverloadBinary(cache,env,aboper,absexp2,absexp1,type2,type1,inImpl,inSymTab,inPre,inInfo, true); /*we have tried left side*/
         (exp,_) = ExpressionSimplify.simplify(exp);
       then
         (cache, exp, prop);

  end matchcontinue;
end operatorDeoverloadBinary;

protected function operatorDeoverloadUnary
"used to resolve unary operations.

also used to resolve user overloaded unary operators for operator records
It looks if there is an operator function defined for the specific
operation. If there is then it will call that function and returns the
resulting expression. "
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Operator inOperator1;
  input DAE.Properties inProp1;
  input DAE.Exp inExp1;
  input Absyn.Exp AbExp "needed for function replaceOperatorWithFcall (not  really sure what is done in there though.)";
  input Absyn.Exp AbExp1 "We need this when/if we elaborate user defined operator functions";
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inSymTab;
  input Prefix.Prefix inPre "For error-messages only";
  input Absyn.Info inInfo "For error-messages only";
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProp;
algorithm
  (outCache, outExp, outProp) :=
   matchcontinue(inCache,inEnv,inOperator1, inProp1, inExp1, AbExp, AbExp1, inImpl, inSymTab, inPre, inInfo)
     local
       String str1;
       Env.Cache cache;
       list<Absyn.Path> operNames;
       Absyn.Path path;
       Env.Env operatorEnv,recordEnv;
       SCode.Element operatorCl;
       list<DAE.Type> types;
       Env.Env env;
       list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> opList;
       DAE.Type type1, otype;
       DAE.Exp exp1,exp;
       DAE.Const const;
       DAE.Operator oper;
       Absyn.Operator aboper;
       DAE.Properties prop;
       Absyn.Exp  absexp1;

     // handle op tuple
     case (_, _, aboper, DAE.PROP_TUPLE(type_ = _), exp1, _, _, _, _, _, _)
       equation
         false = Config.acceptMetaModelicaGrammar();
         (prop as DAE.PROP(type1, const)) = Types.propTupleFirstProp(inProp1);
         exp = DAE.TSUB(exp1, 1, type1);
         (cache, exp, prop) = operatorDeoverloadUnary(inCache, inEnv, inOperator1, prop, exp, AbExp, AbExp1, inImpl, inSymTab, inPre, inInfo);
       then
         (cache, exp, prop);

     case (_, _, aboper, DAE.PROP(type1,const), exp1, _, _, _, _, _, _)
       equation
         false = typeIsRecord(Types.arrayElementType(type1));
         opList = operatorsUnary(aboper);
         (oper, {exp1}, otype) = deoverload(opList, {(exp1,type1)}, AbExp, inPre, inInfo);
         exp = replaceOperatorWithFcall(AbExp, exp1,oper,NONE(), const);
         // (exp,_) = ExpressionSimplify.simplify(exp);
         prop = DAE.PROP(otype,const);
       then
         (inCache,exp, prop);

      // if we have a record check for overloaded operators
     case(cache, env, aboper, DAE.PROP(type1,const) , _, _, absexp1, _, _, _, _)
       equation

         path = getRecordPath(type1);
         path = Absyn.makeFullyQualified(path);
         (cache,_,recordEnv) = Lookup.lookupClass(cache,env,path, false);

         str1 = "'" +& Dump.opSymbolCompact(aboper) +& "'";
         path = Absyn.joinPaths(path, Absyn.IDENT(str1));

         (cache,operatorCl,operatorEnv) = Lookup.lookupClass(cache,recordEnv,path, false);
         true = SCode.isOperator(operatorCl);

         operNames = SCodeUtil.getListofQualOperatorFuncsfromOperator(operatorCl);
         (cache,types as _::_) = Lookup.lookupFunctionsListInEnv(cache, operatorEnv, operNames, inInfo, {});

         (cache,SOME((exp,prop))) = elabCallArgs3(cache,env,types,path,{absexp1},{},inImpl,inSymTab,inPre,inInfo);

       then
         (cache,exp,prop);

  end matchcontinue;
end operatorDeoverloadUnary;


protected function operatorsBinary "This function relates the operators in the abstract syntax to the
  de-overloaded operators in the SCode. It produces a list of available
  types for a specific operator, that the overload function chooses from.
  Therefore, in order for the builtin type conversion from Integer to
  Real to work, operators that work on both Integers and Reals must
  return the Integer type -before- the Real type in the list."
  input Absyn.Operator inOperator1;
  input DAE.Type inType3;
  input DAE.Exp inE1;
  input DAE.Type inType4;
  input DAE.Exp inE2;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> ops;
  output DAE.Type oty1;
  output DAE.Exp oe1;
  output DAE.Type oty2;
  output DAE.Exp oe2;
algorithm
  (ops,oty1,oe1,oty2,oe2) :=
  matchcontinue (inOperator1,inType3,inE1,inType4,inE2)
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> intarrs,realarrs,boolarrs,stringarrs,scalars,arrays,types,scalarprod,matrixprod,intscalararrs,realscalararrs,intarrsscalar,realarrsscalar,realarrscalar,arrscalar,stringarrsscalar;
      tuple<DAE.Operator, list<DAE.Type>, DAE.Type> enum_op;
      DAE.Type t1,t2,int_scalar,int_vector,int_matrix,real_scalar,real_vector,real_matrix;
      DAE.Operator int_mul,real_mul,int_mul_sp,real_mul_sp,int_mul_mp,real_mul_mp,real_div,real_pow;
      Absyn.Operator op;
      DAE.Exp e1,e2;

    // arithmetical operators
    case (Absyn.ADD(),t1,e1,t2,e2)
      equation
        intarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        stringarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                       stringarrtypes, stringarrtypes, stringarrtypes);
        scalars = {
          (DAE.ADD(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.ADD(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT),
          (DAE.ADD(DAE.T_STRING_DEFAULT),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_STRING_DEFAULT)};
        arrays = List.flatten({intarrs,realarrs,stringarrs});
        types = List.flatten({scalars,arrays});
      then
        (types,t1,e1,t2,e2);

    // arithmetical element wise operators
    case (Absyn.ADD_EW(),t1,e1,t2,e2)
      equation
        false = Types.isArray(t2,{}) and (not Types.isArray(t1,{}));
        intarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        stringarrs = operatorReturn(DAE.ADD_ARR(DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                       stringarrtypes, stringarrtypes, stringarrtypes);
        scalars = {
          (DAE.ADD(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.ADD(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT),
          (DAE.ADD(DAE.T_STRING_DEFAULT),
          {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_STRING_DEFAULT)};
        intarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                           realarrtypes, realtypes, realarrtypes);
        stringarrsscalar = operatorReturn(DAE.ADD_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                             stringarrtypes, stringtypes, stringarrtypes);
        types = List.flatten({scalars,intarrsscalar,realarrsscalar,stringarrsscalar,intarrs,realarrs,stringarrs});
      then
        (types,t1,e1,t2,e2);

    // arithmetical operators
    case (Absyn.SUB(),t1,e1,t2,e2)
      equation
        intarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.SUB(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.SUB(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        types = List.flatten({scalars,intarrs,realarrs});
      then
        (types,t1,e1,t2,e2);

    // arithmetical element wise operators
    case (Absyn.SUB_EW(),t1,e1,t2,e2)
      equation
        false = Types.isArray(t1,{}) and (not Types.isArray(t2,{}));
        intarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                    intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.SUB_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                     realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.SUB(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.SUB(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        intscalararrs = operatorReturn(DAE.SUB_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                          inttypes, intarrtypes, intarrtypes);
        realscalararrs = operatorReturn(DAE.SUB_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                           realtypes, realarrtypes, realarrtypes);
        types = List.flatten({scalars,intscalararrs,realscalararrs,intarrs,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.MUL(),t1,e1,t2,e2)
      equation
        false = Types.isArray(t2,{}) and (not Types.isArray(t1,{}));
        int_mul = DAE.MUL(DAE.T_INTEGER_DEFAULT);
        real_mul = DAE.MUL(DAE.T_REAL_DEFAULT);
        int_mul_sp = DAE.MUL_SCALAR_PRODUCT(DAE.T_INTEGER_DEFAULT);
        real_mul_sp = DAE.MUL_SCALAR_PRODUCT(DAE.T_REAL_DEFAULT);
        int_mul_mp = DAE.MUL_MATRIX_PRODUCT(DAE.T_INTEGER_DEFAULT);
        real_mul_mp = DAE.MUL_MATRIX_PRODUCT(DAE.T_REAL_DEFAULT);
        int_scalar = DAE.T_INTEGER_DEFAULT;
        int_vector = DAE.T_ARRAY(int_scalar,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        int_matrix = DAE.T_ARRAY(int_vector,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_scalar = DAE.T_REAL_DEFAULT;
        real_vector = DAE.T_ARRAY(real_scalar,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_matrix = DAE.T_ARRAY(real_vector,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        scalars = {(int_mul,{int_scalar,int_scalar},int_scalar),
          (real_mul,{real_scalar,real_scalar},real_scalar)};
        scalarprod = {(int_mul_sp,{int_vector,int_vector},int_scalar),
          (real_mul_sp,{real_vector,real_vector},real_scalar)};
        matrixprod = {(int_mul_mp,{int_vector,int_matrix},int_vector),
          (int_mul_mp,{int_matrix,int_vector},int_vector),(int_mul_mp,{int_matrix,int_matrix},int_matrix),
          (real_mul_mp,{real_vector,real_matrix},real_vector),(real_mul_mp,{real_matrix,real_vector},real_vector),
          (real_mul_mp,{real_matrix,real_matrix},real_matrix)};
        intarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
                           realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,intarrsscalar,realarrsscalar,scalarprod,matrixprod});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.MUL_EW(),t1,e1,t2,e2) /* Arithmetical operators */
      equation
        false = Types.isArray(t2,{}) and (not Types.isArray(t1,{}));
        intarrs = operatorReturn(DAE.MUL_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          intarrtypes, intarrtypes, intarrtypes);
        realarrs = operatorReturn(DAE.MUL_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.MUL(DAE.T_INTEGER_DEFAULT),
          {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_INTEGER_DEFAULT),
          (DAE.MUL(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        intarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          intarrtypes, inttypes, intarrtypes);
        realarrsscalar = operatorReturn(DAE.MUL_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,intarrsscalar,realarrsscalar,intarrs,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.DIV(),t1,e1,t2,e2)
      equation
        real_div = DAE.DIV(DAE.T_REAL_DEFAULT);
        real_scalar = DAE.T_REAL_DEFAULT;
        scalars = {(real_div,{real_scalar,real_scalar},real_scalar)};
        realarrscalar = operatorReturn(DAE.DIV_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,realarrscalar});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.DIV_EW(),t1,e1,t2,e2) /* Arithmetical operators */
      equation
        realarrs = operatorReturn(DAE.DIV_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.DIV(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        realscalararrs = operatorReturn(DAE.DIV_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realtypes, realarrtypes, realarrtypes);
        realarrsscalar = operatorReturn(DAE.DIV_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,realscalararrs,
          realarrsscalar,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.POW(),t1,e1,t2,e2)
      equation
        // Note: POW_ARR uses Integer exponents, while POW only uses Real exponents
        real_scalar = DAE.T_REAL_DEFAULT;
        int_scalar = DAE.T_INTEGER_DEFAULT;
        real_vector = DAE.T_ARRAY(real_scalar,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_matrix = DAE.T_ARRAY(real_vector,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
        real_pow = DAE.POW(DAE.T_REAL_DEFAULT);
        scalars = {(real_pow,{real_scalar,real_scalar},real_scalar)};
        arrscalar = {
          (DAE.POW_ARR(DAE.T_REAL_DEFAULT),{real_matrix,int_scalar},
          real_matrix)};
        types = List.flatten({scalars,arrscalar});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.POW_EW(),t1,e1,t2,e2)
      equation
        realarrs = operatorReturn(DAE.POW_ARR2(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes, realarrtypes);
        scalars = {
          (DAE.POW(DAE.T_REAL_DEFAULT),
          {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_REAL_DEFAULT)};
        realscalararrs = operatorReturn(DAE.POW_SCALAR_ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realtypes, realarrtypes, realarrtypes);
        realarrsscalar = operatorReturn(DAE.POW_ARRAY_SCALAR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realtypes, realarrtypes);
        types = List.flatten({scalars,realscalararrs,
          realarrsscalar,realarrs});
      then
        (types,t1,e1,t2,e2);

    case (Absyn.AND(), t1, e1, t2, e2)
      equation
        scalars = {(DAE.AND(DAE.T_BOOL_DEFAULT), {DAE.T_BOOL_DEFAULT, DAE.T_BOOL_DEFAULT}, DAE.T_BOOL_DEFAULT)};
        boolarrs = operatorReturn(DAE.AND(DAE.T_BOOL_DEFAULT), boolarrtypes, boolarrtypes, boolarrtypes);
        types = List.flatten({scalars, boolarrs});
      then (types,t1,e1,t2,e2);

    case (Absyn.OR(), t1, e1, t2, e2)
      equation
        scalars = {(DAE.OR(DAE.T_BOOL_DEFAULT), {DAE.T_BOOL_DEFAULT, DAE.T_BOOL_DEFAULT}, DAE.T_BOOL_DEFAULT)};
        boolarrs = operatorReturn(DAE.OR(DAE.T_BOOL_DEFAULT), boolarrtypes, boolarrtypes, boolarrtypes);
        types = List.flatten({scalars, boolarrs});
      then (types,t1,e1,t2,e2);

    // Relational operators
    case (Absyn.LESS(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.LESS(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.LESS(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.LESS(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESS(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESS(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.LESSEQ(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.LESSEQ(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.LESSEQ(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.LESSEQ(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESSEQ(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.LESSEQ(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.GREATER(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.GREATER(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.GREATER(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.GREATER(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATER(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATER(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.GREATEREQ(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.GREATEREQ(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        scalars = {
          (DAE.GREATEREQ(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT),
          enum_op,
          (DAE.GREATEREQ(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATEREQ(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT),
          (DAE.GREATEREQ(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)};
        types = List.flatten({scalars});
      then (types,t1,e1,t2,e2);

    case (Absyn.EQUAL(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.EQUAL(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        types = Util.if_(Types.isBoxedType(t1) and Types.isBoxedType(t2),
                                  {(DAE.EQUAL(DAE.T_METABOXED_DEFAULT),{t1,t2},DAE.T_BOOL_DEFAULT)},
                                  {});
        types =
          (DAE.EQUAL(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT)::
          enum_op::
          (DAE.EQUAL(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.EQUAL(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.EQUAL(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          types;
      then
        (types,t1,e1,t2,e2);

    case (Absyn.NEQUAL(),t1,e1,t2,e2)
      equation
        enum_op = makeEnumOperator(DAE.NEQUAL(DAE.T_ENUMERATION_DEFAULT), t1, t2);
        types = Util.if_(Types.isBoxedType(t1) and Types.isBoxedType(t2),
                                  {(DAE.NEQUAL(DAE.T_METABOXED_DEFAULT),{t1,t2},DAE.T_BOOL_DEFAULT)},
                                  {});
        types =
          (DAE.NEQUAL(DAE.T_INTEGER_DEFAULT),
            {DAE.T_INTEGER_DEFAULT,DAE.T_INTEGER_DEFAULT},DAE.T_BOOL_DEFAULT)::
          enum_op::
          (DAE.NEQUAL(DAE.T_REAL_DEFAULT),
            {DAE.T_REAL_DEFAULT,DAE.T_REAL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.NEQUAL(DAE.T_STRING_DEFAULT),
            {DAE.T_STRING_DEFAULT,DAE.T_STRING_DEFAULT},DAE.T_BOOL_DEFAULT)::
          (DAE.NEQUAL(DAE.T_BOOL_DEFAULT),
            {DAE.T_BOOL_DEFAULT,DAE.T_BOOL_DEFAULT},DAE.T_BOOL_DEFAULT)::
          types;
      then
        (types,t1,e1,t2,e2);

    // element-wise equivalent operators
    case (Absyn.ADD_EW(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t2,{}) and (not Types.isArray(t1,{}));
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.ADD_EW(),t2,e2,t1,e1);
      then (types,t1,e1,t2,e2);

    case (Absyn.SUB_EW(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t1,{}) and (not Types.isArray(t2,{}));
        e2 = Expression.negate(e2);
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.ADD_EW(),t1,e1,t2,e2);
      then (types,t1,e1,t2,e2);

    case (Absyn.MUL(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t2,{}) and (not Types.isArray(t1,{}));
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.MUL(),t2,e2,t1,e1);
      then (types,t1,e1,t2,e2);

    case (Absyn.MUL_EW(),t1,e1,t2,e2)
      equation
        true = Types.isArray(t2,{}) and (not Types.isArray(t1,{}));
        (types,t1,e1,t2,e2) = operatorsBinary(Absyn.MUL_EW(),t2,e2,t1,e1);
      then (types,t1,e1,t2,e2);

    case (op,t1,e1,t2,e2)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.operatorsBinary failed, op: " +& Dump.opSymbol(op));
      then
        fail();
  end matchcontinue;
end operatorsBinary;

protected function operatorsUnary "This function relates the operators in the abstract syntax to the
  de-overloaded operators in the SCode. It produces a list of available
  types for a specific operator, that the overload function chooses from.
  Therefore, in order for the builtin type conversion from Integer to
  Real to work, operators that work on both Integers and Reals must
  return the Integer type -before- the Real type in the list."
  input Absyn.Operator op;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> ops;
algorithm
  ops := match op
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> intarrs,realarrs,boolarrs,scalars,types;

    case Absyn.UMINUS()
      equation
        scalars = {
          (DAE.UMINUS(DAE.T_INTEGER_DEFAULT),{DAE.T_INTEGER_DEFAULT},
          DAE.T_INTEGER_DEFAULT),
          (DAE.UMINUS(DAE.T_REAL_DEFAULT),{DAE.T_REAL_DEFAULT},
          DAE.T_REAL_DEFAULT)} "The UMINUS operator, unary minus" ;
        intarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          intarrtypes, intarrtypes);
        realarrs = operatorReturnUnary(DAE.UMINUS_ARR(DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()}, DAE.emptyTypeSource)),
          realarrtypes, realarrtypes);
        types = List.flatten({scalars,intarrs,realarrs});
      then types;

    case Absyn.NOT()
      equation
        scalars = {(DAE.NOT(DAE.T_BOOL_DEFAULT), {DAE.T_BOOL_DEFAULT}, DAE.T_BOOL_DEFAULT)};
        boolarrs = operatorReturnUnary(DAE.NOT(DAE.T_BOOL_DEFAULT), boolarrtypes, boolarrtypes);
        types = List.flatten({scalars, boolarrs});
      then types;

    case _
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.operatorsUnary failed, op: " +& Dump.opSymbol(op));
      then fail();
  end match;
end operatorsUnary;

protected function makeEnumOperator
  "Used by operators to create an operator with enumeration type. It sets the
  correct expected type of the operator, so that for example integer=>enum type
  casts work correctly without matching things that it shouldn't match."
  input DAE.Operator inOp;
  input DAE.Type inType1;
  input DAE.Type inType2;
  output tuple<DAE.Operator, list<DAE.Type>, DAE.Type> outOp;
algorithm
  outOp := matchcontinue(inOp, inType1, inType2)
    local
      DAE.Type op_ty;
      DAE.Operator op;

    case (_, DAE.T_ENUMERATION(path = _), DAE.T_ENUMERATION(path = _))
      equation
        op_ty = Types.simplifyType(inType1);
        op = Expression.setOpType(inOp, op_ty);
      then ((op, {inType1, inType2}, DAE.T_BOOL_DEFAULT));

    case (_, DAE.T_ENUMERATION(path = _), _)
      equation
        op_ty = Types.simplifyType(inType1);
        op = Expression.setOpType(inOp, op_ty);
      then
        ((op, {inType1, inType1}, DAE.T_BOOL_DEFAULT));

    case (_, _, DAE.T_ENUMERATION(path = _))
      equation
        op_ty = Types.simplifyType(inType1);
        op = Expression.setOpType(inOp, op_ty);
      then
        ((op, {inType1, inType2}, DAE.T_BOOL_DEFAULT));

    case (_, _, _)
      then ((inOp, {DAE.T_ENUMERATION_DEFAULT, DAE.T_ENUMERATION_DEFAULT}, DAE.T_BOOL_DEFAULT));
  end matchcontinue;
end makeEnumOperator;

protected function buildOperatorTypes
"This function takes the types operator overloaded user functions and
  builds  the type list structure suitable for the deoverload function."
  input list<DAE.Type> inTypesTypeLst;
  input Absyn.Path inPath;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm
  outTplExpOperatorTypesTypeLstTypesTypeLst := matchcontinue (inTypesTypeLst,inPath)
    local
      list<DAE.Type> argtypes,tps;
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> rest;
      list<DAE.FuncArg> args;
      DAE.Type tp;
      Absyn.Path funcname;
    case ({},_) then {};
    case (DAE.T_FUNCTION(funcArg = args,funcResultType = tp) :: tps,funcname)
      equation
        argtypes = List.map(args, Util.tuple42);
        rest = buildOperatorTypes(tps, funcname);
      then
        ((DAE.USERDEFINED(funcname),argtypes,tp) :: rest);
  end matchcontinue;
end buildOperatorTypes;

protected function nDimArray "Returns a type based on the type given as input but as an array type with n dimensions."
  input Integer inInteger;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue (inInteger,inType)
    local
      DAE.Type t,t_1;
      Integer n_1,n;
    case (0,t) then t;  /* n orig type array type of n dimensions with element type = orig type */
    case (n,t)
      equation
        n_1 = n - 1;
        t_1 = nDimArray(n_1, t);
      then
        DAE.T_ARRAY(t_1,{DAE.DIM_UNKNOWN()},DAE.emptyTypeSource);
  end matchcontinue;
end nDimArray;

protected function nTypes "Creates n copies of the type type.
  This could instead be accomplished with Util.list_fill..."
  input Integer inInteger;
  input DAE.Type inType;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst := matchcontinue (inInteger,inType)
    local
      Integer n_1,n;
      list<DAE.Type> l;
      DAE.Type t;
    case (0,_) then {};
    case (n,t)
      equation
        n_1 = n - 1;
        l = nTypes(n_1, t);
      then
        (t :: l);
  end matchcontinue;
end nTypes;

protected function operatorReturn "This function collects the types and operator lists into a tuple list, suitable
  for the deoverloading function for binary operations."
  input DAE.Operator inOperator1;
  input list<DAE.Type> inTypesTypeLst2;
  input list<DAE.Type> inTypesTypeLst3;
  input list<DAE.Type> inTypesTypeLst4;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  match (inOperator1,inTypesTypeLst2,inTypesTypeLst3,inTypesTypeLst4)
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> rest;
      tuple<DAE.Operator, list<DAE.Type>, DAE.Type> t;
      DAE.Operator op;
      DAE.Type l,r,re;
      list<DAE.Type> lr,rr,rer;
    case (_,{},{},{}) then {};
    case (op,(l :: lr),(r :: rr),(re :: rer))
      equation
        rest = operatorReturn(op, lr, rr, rer);
        t = (op,{l,r},re) "list contains two types, i.e. BINARY operations" ;
      then
        (t :: rest);
  end match;
end operatorReturn;

protected function operatorReturnUnary "This function collects the types and operator lists into a tuple list,
  suitable for the deoverloading function to be used for unary
  expressions."
  input DAE.Operator inOperator1;
  input list<DAE.Type> inTypesTypeLst2;
  input list<DAE.Type> inTypesTypeLst3;
  output list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> outTplExpOperatorTypesTypeLstTypesTypeLst;
algorithm
  outTplExpOperatorTypesTypeLstTypesTypeLst:=
  match (inOperator1,inTypesTypeLst2,inTypesTypeLst3)
    local
      list<tuple<DAE.Operator, list<DAE.Type>, DAE.Type>> rest;
      tuple<DAE.Operator, list<DAE.Type>, DAE.Type> t;
      DAE.Operator op;
      DAE.Type l,re;
      list<DAE.Type> lr,rer;
    case (_,{},{}) then {};
    case (op,(l :: lr),(re :: rer))
      equation
        rest = operatorReturnUnary(op, lr, rer);
        t = (op,{l},re) "list only contains one type, i.e. for UNARY operations" ;
      then
        (t :: rest);
  end match;
end operatorReturnUnary;

protected function arrayTypeList "This function creates a list of types using the original type passed as input, but
  as array types up to n dimensions."
  input Integer inInteger;
  input DAE.Type inType;
  output list<DAE.Type> outTypesTypeLst;
algorithm
  outTypesTypeLst:=
  matchcontinue (inInteger,inType)
    local
      Integer n_1,n;
      DAE.Type f,t;
      list<DAE.Type> r;
    case (0,_) then {};  /* n orig type array types */
    case (n,t)
      equation
        n_1 = n - 1;
        f = nDimArray(n, t);
        r = arrayTypeList(n_1, t);
      then
        (f :: r);
  end matchcontinue;
end arrayTypeList;

protected function warnUnsafeRelations "
  Author: BZ, 2008-08
  Check if we have Real == Real or Real != Real, if so give a warning."
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input DAE.Const variability;
  input DAE.Type t1,t2;
  input DAE.Exp e1,e2;
  input DAE.Operator op;
  input Prefix.Prefix inPrefix;
algorithm
  _ := matchcontinue(inEnv,inExp,variability,t1,t2,e1,e2,op,inPrefix)
    local
      Boolean b1,b2;
      String stmtString,opString,pre_str;
      Prefix.Prefix pre;
    // == or != on Real is permitted in functions, so don't print an error if
    // we're in a function.
    case (_, _, _, _, _, _, _, _, _)
      equation
        true = Env.inFunctionScope(inEnv);
      then ();

    case(_, Absyn.RELATION(_, _, _), DAE.C_VAR(),_,_,_,_,_,pre)
      equation
        b1 = Types.isReal(t1);
        b2 = Types.isReal(t1);
        true = boolOr(b1,b2);
        verifyOp(op);
        opString = ExpressionDump.relopSymbol(op);
        stmtString = ExpressionDump.printExpStr(e1) +& opString +& ExpressionDump.printExpStr(e2);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addMessage(Error.WARNING_RELATION_ON_REAL, {pre_str,stmtString,opString});
      then
        ();
    case(_,_,_,_,_,_,_,_,_) then ();
  end matchcontinue;
end warnUnsafeRelations;

protected function verifyOp "
Helper function for warnUnsafeRelations
We only want to check DAE.EQUAL and Expression.NEQUAL since they are the only illegal real operations."
input DAE.Operator op;
algorithm _ := match(op)
  case(DAE.EQUAL(_)) then ();
  case(DAE.NEQUAL(_)) then ();
  end match;
end verifyOp;

protected function unevaluatedFunctionVariability
  "In a function we might have input arguments with unknown dimensions, and in
  that case we can't expand calls such as fill. A function call is therefore
  created with variable variability. This function checks that we're inside a
  function and returns DAE.C_VAR(), or fails if we're not inside a function.

  The exception is if checkModel is used, in which case we don't know what the
  variability would have been had all parameters received a binding. We can't
  set the variability to variable or parameter because then we might get
  bindings with higher variability than the component, and we can't set it to
  constant because that would cause the compiler to try and constant evaluate
  the call. So we set it to DAE.C_UNKNOWN() instead."
  input Env.Env inEnv;
  output DAE.Const outConst;
algorithm
  outConst := matchcontinue(inEnv)
    case _ equation true = Env.inFunctionScope(inEnv); then DAE.C_VAR();
    case _ equation true = Flags.getConfigBool(Flags.CHECK_MODEL); then DAE.C_UNKNOWN();
    // bug #2113, seems that there is nothing in the specs 
    // that requires that fill arguments are of parameter/constant 
    // variability, so allow it.
    else
      equation
        true = Config.splitArrays();
      then DAE.C_UNKNOWN();
  end matchcontinue;
end unevaluatedFunctionVariability;

protected function slotAnd
"Use with listFold to check if all slots have been filled"
  input Slot s;
  input Boolean b;
  output Boolean res;
algorithm
  SLOT(slotFilled = res) := s;
  res := b and res;
end slotAnd;

public function elabCodeExp
  input Absyn.Exp exp;
  input Env.Cache cache;
  input Env.Env env;
  input DAE.CodeType ct;
  input Absyn.Info info;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (exp,cache,env,ct,info)
    local
      String s1,s2;
      Absyn.ComponentRef cr;
      Absyn.Path path;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es;
      DAE.Type et;
      Integer i;
      DAE.Exp dexp;

    // Expression
    case (_,_,_,DAE.C_EXPRESSION(),_)
      then DAE.CODE(Absyn.C_EXPRESSION(exp),DAE.T_UNKNOWN_DEFAULT);

    // Type Name
    case (Absyn.CREF(componentRef=cr),_,_,DAE.C_TYPENAME(),_)
      equation
        path = Absyn.crefToPath(cr);
      then DAE.CODE(Absyn.C_TYPENAME(path),DAE.T_UNKNOWN_DEFAULT);

    // Variable Names
    case (Absyn.ARRAY(es),_,_,DAE.C_VARIABLENAMES(),_)
      equation
        es_1 = List.map4(es,elabCodeExp,cache,env,DAE.C_VARIABLENAME(),info);
        i = listLength(es);
        et = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(i)}, DAE.emptyTypeSource);
      then DAE.ARRAY(et,false,es_1);

    case (_,_,_,DAE.C_VARIABLENAMES(),_)
      equation
        et = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
        dexp = elabCodeExp(exp,cache,env,DAE.C_VARIABLENAME(),info);
      then DAE.ARRAY(et,false,{dexp});

    // Variable Name
    case (Absyn.CREF(componentRef=cr),_,_,DAE.C_VARIABLENAME(),_)
      then DAE.CODE(Absyn.C_VARIABLENAME(cr),DAE.T_UNKNOWN_DEFAULT);

    case (Absyn.CALL(Absyn.CREF_IDENT("der",{}),Absyn.FUNCTIONARGS(args={Absyn.CREF(componentRef=cr)},argNames={})),_,_,DAE.C_VARIABLENAME(),_)
      then DAE.CODE(Absyn.C_EXPRESSION(exp),DAE.T_UNKNOWN_DEFAULT);

    // failure
    case (_,_,_,_,_)
      equation
        failure(DAE.C_VARIABLENAMES() = ct);
        s1 = Dump.printExpStr(exp);
        s2 = Types.printCodeTypeStr(ct);
        Error.addSourceMessage(Error.ELAB_CODE_EXP_FAILED, {s1,s2}, info);
      then fail();
  end matchcontinue;
end elabCodeExp;

public function elabArrayDims
  "Elaborates a list of array dimensions."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Subscript> inDimensions;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Dimensions outDimensions;
algorithm
  (outCache, outDimensions) := elabArrayDims2(inCache, inEnv, inComponentRef,
    inDimensions, inImplicit, inST, inDoVect, inPrefix, inInfo, {});
end elabArrayDims;

protected function elabArrayDims2
  "Helper function to elabArrayDims. Needed because of tail recursion."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inCref;
  input list<Absyn.Subscript> inDimensions;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  input DAE.Dimensions inElaboratedDims;
  output Env.Cache outCache;
  output DAE.Dimensions outDimensions;
algorithm
  (outCache, outDimensions) := match(inCache, inEnv, inCref, inDimensions,
      inImplicit, inST, inDoVect, inPrefix, inInfo, inElaboratedDims)
    local
      Env.Cache cache;
      Absyn.Subscript dim;
      list<Absyn.Subscript> rest_dims;
      DAE.Dimension elab_dim;
      DAE.Dimensions elab_dims;

    case (_, _, _, {}, _, _, _, _, _, _)
      then (inCache, listReverse(inElaboratedDims));

    case (_, _, _, dim :: rest_dims, _, _, _, _, _, _)
      equation
        (cache, elab_dim) = elabArrayDim(inCache, inEnv, inCref, dim,
          inImplicit, inST, inDoVect, inPrefix, inInfo);
        elab_dims = elab_dim :: inElaboratedDims;
        (cache, elab_dims) = elabArrayDims2(cache, inEnv, inCref, rest_dims,
          inImplicit, inST, inDoVect, inPrefix, inInfo, elab_dims);
      then
        (cache, elab_dims);
  end match;
end elabArrayDims2;

protected function elabArrayDim
  "Elaborates a single array dimension."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inCref;
  input Absyn.Subscript inDimension;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output DAE.Dimension outDimension;
algorithm
  (outCache, outDimension) := matchcontinue(inCache, inEnv, inCref, inDimension,
      inImpl, inST, inDoVect, inPrefix, inInfo)
    local
      Absyn.ComponentRef cr;
      DAE.Dimension dim;
      Env.Cache cache;
      Env.Env cenv;
      SCode.Element cls;
      Absyn.Path type_path, enum_type_name;
      String name;
      list<String> enum_literals;
      Integer enum_size;
      list<SCode.Element> el;
      Absyn.Exp sub, cr_exp;
      DAE.Exp e, dim_exp;
      DAE.Properties prop;
      list<SCode.Enum> enum_lst;
      Absyn.Exp size_arg;

    // The : operator results in an unknown dimension.
    case (_, _, _, Absyn.NOSUB(), _, _, _, _, _)
      then (inCache, DAE.DIM_UNKNOWN());

    // Size expression that refers to the array itself, such as
    // Real x(:, size(x, 1)).
    case (_, _, _, Absyn.SUBSCRIPT(subscript = Absyn.CALL(function_ =
        Absyn.CREF_IDENT(name = "size"), functionArgs = Absyn.FUNCTIONARGS(args =
        {cr_exp as Absyn.CREF(componentRef = cr), size_arg}))), _, _, _, _, _)
      equation
        true = Absyn.crefEqual(inCref, cr);
        (cache, e, _, _) = elabExp(inCache, inEnv, cr_exp, inImpl, inST,
          inDoVect, inPrefix, inInfo);
        (cache, dim_exp, _, _) = elabExp(cache, inEnv, size_arg, inImpl, inST,
          inDoVect, inPrefix, inInfo);
        dim = DAE.DIM_EXP(DAE.SIZE(e, SOME(dim_exp)));
        //dim = DAE.DIM_UNKNOWN();
      then
        (inCache, dim);

    case (_, _, _, Absyn.SUBSCRIPT(subscript = Absyn.CREF(componentRef = Absyn.CREF_IDENT(name = "Boolean"))), _, _, _, _, _)
      then
        (inCache, DAE.DIM_BOOLEAN());

    // Array dimension from an enumeration.
    case (_, _, _, Absyn.SUBSCRIPT(subscript = Absyn.CREF(cr)), _, _, _, _, _)
      equation
        type_path = Absyn.crefToPath(cr);
        (_, cls as SCode.CLASS(name = name, restriction = SCode.R_ENUMERATION(),
            classDef = SCode.PARTS(elementLst = el)), cenv) =
          Lookup.lookupClass(inCache, inEnv, type_path, false);
        enum_type_name = Env.joinEnvPath(cenv, Absyn.IDENT(name));
        enum_literals = SCode.componentNames(cls);
        enum_size = listLength(enum_literals);
      then
        (inCache, DAE.DIM_ENUM(enum_type_name, enum_literals, enum_size));

    // Frenkel TUD try next enum.
    case (_, _, _, Absyn.SUBSCRIPT(subscript = Absyn.CREF(cr)), _, _, _, _, _)
      equation
        type_path = Absyn.crefToPath(cr);
        (_, SCode.CLASS(restriction = SCode.R_TYPE(), classDef =
            SCode.ENUMERATION(enumLst = enum_lst)), _) =
          Lookup.lookupClass(inCache, inEnv, type_path, false);
        enum_size = listLength(enum_lst);
      then
        (inCache, DAE.DIM_INTEGER(enum_size));

    // For all other cases we need to elaborate the subscript expression, so the
    // expression is elaborated and passed on to elabArrayDim2 to avoid doing
    // the elaboration several times.
    case (_, _, _, Absyn.SUBSCRIPT(subscript = sub), _, _, _, _, _)
      equation
        (cache, e, prop, _) = elabExp(inCache, inEnv, sub, inImpl, inST,
          inDoVect, inPrefix, inInfo);
        (cache, SOME(dim)) = elabArrayDim2(cache, inEnv, inCref, e, prop, inImpl, inST,
          inDoVect, inPrefix, inInfo);
      then
        (cache, dim);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabArrayDim failed on: " +&
          Absyn.printComponentRefStr(inCref) +&
          Dump.printArraydimStr({inDimension}));
      then
        fail();

  end matchcontinue;
end elabArrayDim;

protected function elabArrayDim2
  "Helper function to elabArrayDim. Continues the work from the last case in
  elabArrayDim to avoid unnecessary elaboration."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ComponentRef inCref;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output Option<DAE.Dimension> outDimension;
algorithm
  (outCache, outDimension) := matchcontinue(inCache, inEnv, inCref, inExp, inProperties,
      inImpl, inST, inDoVect, inPrefix, inInfo)
    local
      DAE.Const cnst;
      Env.Cache cache;
      DAE.Exp e;
      DAE.Type ty;
      String e_str, t_str, a_str;
      Integer i;

    // Constant dimension creates DIM_INTEGER.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(varLst = _), cnst), _, _, _, _, _)
      equation
        true = Types.isParameterOrConstant(cnst);
        (cache, Values.INTEGER(i), _) = Ceval.ceval(inCache, inEnv, inExp, inImpl, inST, Absyn.NO_MSG(), 0);
      then
        (cache, SOME(DAE.DIM_INTEGER(i)));

    // When arrays are non-expanded, non-constant parametric dimensions are allowed.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(varLst = _), DAE.C_PARAM()), _, _, _, _, _)
      equation
        false = Config.splitArrays();
      then
        (inCache, SOME(DAE.DIM_EXP(inExp)));

    // When not implicit instantiation, array dimension must be constant.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(varLst = _), DAE.C_VAR()), false, _, _, _, _)
      equation
        e_str = ExpressionDump.printExpStr(inExp);
        Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN, {e_str}, inInfo);
      then
        (inCache, NONE());

    // Non-constant dimension creates DIM_EXP.
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(varLst = _), _), true, _, _, _, _)
      equation
        (cache, e, _) =
          Ceval.cevalIfConstant(inCache, inEnv, inExp, inProperties, inImpl, inInfo);
      then
        (cache, SOME(DAE.DIM_EXP(e)));

    case (_, _, _, _, _, _, _, _, _, _)
      equation
        (cache, e as DAE.SIZE(_, _), _) =
          Ceval.cevalIfConstant(inCache, inEnv, inExp, inProperties, inImpl, inInfo);
      then
        (cache, SOME(DAE.DIM_EXP(e)));

    case (_, _, _, _, _, _, _, _, _, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
      then
        (inCache, SOME(DAE.DIM_UNKNOWN()));

    // an integer parameter with no binding
    case (_, _, _, _, DAE.PROP(DAE.T_INTEGER(varLst = _), cnst), _, _, _, _, _)
      equation
        true = Types.isParameterOrConstant(cnst);
        e_str = ExpressionDump.printExpStr(inExp);
        a_str = Dump.printComponentRefStr(inCref) +& "[" +& e_str +& "]";
        Error.addSourceMessage(Error.STRUCTURAL_PARAMETER_OR_CONSTANT_WITH_NO_BINDING, {e_str, a_str}, inInfo);
        //(_, _) = elabArrayDim2(inCache, inEnv, inCref, inExp, inProperties, inImpl, inST, inDoVect, inPrefix, inInfo);
      then
        (inCache, NONE());

    case (_, _, _, _, DAE.PROP(ty, _), _, _, _, _, _)
      equation
        e_str = ExpressionDump.printExpStr(inExp);
        t_str = Types.unparseType(ty);
        Types.typeErrorSanityCheck(t_str, "Integer", inInfo);
        Error.addSourceMessage(Error.ARRAY_DIMENSION_INTEGER,
          {e_str, t_str}, inInfo);
      then
        (inCache, NONE());

  end matchcontinue;
end elabArrayDim2;

protected function consStrippedCref
  input Absyn.Exp e;
  input list<Absyn.Exp> es;
  output list<Absyn.Exp> oes;
algorithm
  oes := match (e,es)
    local
      Absyn.ComponentRef cr;
    case (Absyn.CREF(cr),_)
      equation
        cr = Absyn.crefStripLastSubs(cr);
      then Absyn.CREF(cr)::es;
    else es;
  end match;
end consStrippedCref;

protected function replaceEndEnter
  "Single pass traversal that replaces end-expressions with the correct size-expression.
  It uses a couple of stacks and crap to handle all of this :)."
  input tuple<Absyn.Exp,tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>>> itpl;
  output tuple<Absyn.Exp,tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>>> otpl;
algorithm
  otpl := match itpl
    local
      Absyn.Exp exp;
      list<Absyn.Exp> crs;
      list<Integer> li;
      Integer i,ni;
      list<Boolean> bs;
      Boolean isCr,inc;
    case ((exp,(crs,i::li,bs as (inc::_))))
      equation
        isCr = Absyn.isCref(exp);
        bs = Util.if_(isCr,true::bs,false::bs);
        ni = Util.if_(isCr,0,i+1);
        li = Util.if_(inc,ni::li,i::li);
        li = Util.if_(isCr,0::li,li);
        crs = consStrippedCref(exp,crs);
      then ((exp,(crs,li,bs)));
  end match;
end replaceEndEnter;

protected function replaceEndExit
  "Single pass traversal that replaces end-expressions with the correct size-expression.
  It uses a couple of stacks and crap to handle all of this :)."
  input tuple<Absyn.Exp,tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>>> itpl;
  output tuple<Absyn.Exp,tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>>> otpl;
algorithm
  otpl := match itpl
    local
      Absyn.Exp cr,exp;
      list<Absyn.Exp> crs;
      Integer i;
      list<Integer> li;
      list<Boolean> bs;
    case ((Absyn.END(),(crs as (cr::_),li as (i::_),_::bs)))
      then ((Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({cr,Absyn.INTEGER(i)},{})),(crs,li,bs)));
    case ((cr as Absyn.CREF(_),(_::crs,_::li,_::bs)))
      then ((cr,(crs,li,bs)));
    case ((exp,(crs,li,_::bs))) then ((exp,(crs,li,bs)));
  end match;
end replaceEndExit;

protected function replaceEnd
  "Single pass traversal that replaces end-expressions with the correct size-expression.
  It uses a couple of stacks and crap to handle all of this :)."
  input Absyn.ComponentRef cr;
  output Absyn.ComponentRef ocr;
protected
  Absyn.ComponentRef stripcr;
algorithm
  // print("replaceEnd start " +& Dump.printExpStr(Absyn.CREF(cr)) +& "\n");
  stripcr := Absyn.crefStripLastSubs(cr);
  // print("stripCref        " +& Dump.printExpStr(Absyn.CREF(stripcr)) +& "\n");
  (ocr,_) := Absyn.traverseExpBidirCref(cr,(replaceEndEnter,replaceEndExit,({Absyn.CREF(stripcr)},{0},{true})));
  // print("replaceEnd  end  " +& Dump.printExpStr(Absyn.CREF(ocr)) +& "\n");
end replaceEnd;

end Static;
