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
public import FCore;
public import FGraph;
public import FNode;
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
    DAE.FuncArg defaultArg "The slots default argument.";
    Boolean slotFilled "True if the slot has been filled, otherwise false.";
    Option<DAE.Exp> arg "The argument for the slot given by the function call.";
    DAE.Dimensions dims "The dimensions of the slot.";
    Integer idx "The index of the slot, 1 = first slot etc.";
  end SLOT;
end Slot;

protected import BackendInterface;
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
protected import GlobalScriptUtil;
protected import Inline;
protected import Inst;
protected import InstFunction;
protected import InstTypes;
protected import InnerOuter;
protected import List;
protected import Lookup;
protected import OperatorOverloading;
protected import Patternm;
protected import Print;
protected import System;
protected import Types;
protected import ValuesUtil;
protected import DAEUtil;
protected import PrefixUtil;
protected import VarTransform;
protected import SCodeDump;
protected import RewriteRules;

public function elabExpList "Expression elaboration of Absyn.Exp list, i.e. lists of expressions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  elabExpList2(inCache,inEnv,inAbsynExpLst,DAE.T_UNKNOWN_DEFAULT,inImplicit,inST,performVectorization,inPrefix,info);
end elabExpList;

protected function elabExpList2 "Expression elaboration of Absyn.Exp list, i.e. lists of expressions."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input DAE.Type ty "The type of the last evaluated expression; used to speed up instantiation of enumerations :)";
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output list<DAE.Properties> outTypesPropertiesLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExpExpLst,outTypesPropertiesLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,ty,inImplicit,inST,performVectorization,inPrefix,info)
    local
      Boolean impl;
      Option<GlobalScript.SymbolTable> st,st_1,st_2;
      DAE.Exp exp;
      DAE.Properties p;
      list<DAE.Exp> exps;
      list<DAE.Properties> props;
      FCore.Graph env;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
      FCore.Cache cache;
      Boolean doVect;
      Prefix.Prefix pre;
      Absyn.ComponentRef cr;
      Absyn.Path path,path1,path2;
      String name;
      list<String> names;
      Integer ix;

    case (cache,_,{},_,_,st,_,_,_) then (cache,{},{},st);

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
        (cache,exp,p,st_1) = elabExpInExpression(cache, env, e, impl, st, doVect, pre, info);
        (cache,exps,props,st_2) = elabExpList2(cache, env, rest, Types.getPropType(p), impl, st_1, doVect, pre, info);
      then
        (cache,(exp :: exps),(p :: props),st_2);

  end matchcontinue;
end elabExpList2;

public function elabExpListList
"Expression elaboration of lists of lists of expressions.
  Used in for instance matrices, etc."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input DAE.Type ty "The type of the last evaluated expression; used to speed up instantiation of enumerations :)";
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      list<Absyn.Exp> e;
      list<list<Absyn.Exp>> rest;
      FCore.Cache cache;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<Absyn.Exp> oExp;
  input DAE.Type defaultType;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache cache;
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
        (cache,exp,prop,st) = elabExpInExpression(inCache,inEnv,inExp,inBoolean,inSt,performVectorization,inPrefix,info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> st;
algorithm
  (outCache,outExp,outProperties,st) := matchcontinue(inCache,inEnv,inExp,inImplicit,inST,performVectorization,inPrefix,info)
    local
      Absyn.Exp expRewritten;

    // we have some rewrite rules
    case (_, _, _, _, _, _, _, _)
      equation
        false = RewriteRules.noRewriteRulesFrontEnd();
        (expRewritten, _) = RewriteRules.rewriteFrontEnd(inExp);
        (outCache,outExp,outProperties,st) = elabExp_dispatch(inCache,inEnv,expRewritten,inImplicit,inST,performVectorization,inPrefix,info);
      then
        (outCache,outExp,outProperties,st);

    // we have no rewrite rules
    case (_, _, _, _, _, _, _, _)
      equation
        true = RewriteRules.noRewriteRulesFrontEnd();
        (outCache,outExp,outProperties,st) = elabExp_dispatch(inCache,inEnv,inExp,inImplicit,inST,performVectorization,inPrefix,info);
      then
        (outCache,outExp,outProperties,st);
  end matchcontinue;
end elabExp;

public function elabExp_dispatch "
function: elabExp
  Static analysis of expressions means finding out the properties of
  the expression.  These properties are described by the
  DAE.Properties type, and include the type and the variability of the
  expression.  This function performs analysis, and returns an
  DAE.Exp and the properties."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> st;
algorithm
  (outCache,outExp,outProperties,st) := elabExp2(inCache,inEnv,inExp,inImplicit,inST,performVectorization,inPrefix,info,Error.getNumErrorMessages());
end elabExp_dispatch;

public function elabExpInExpression "Like elabExp but casts PROP_TUPLE to a PROP"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
  input FCore.Graph inEnv;
  input Boolean inAllowTopLevelInputs;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExp, inAttributes, inEnv, inAllowTopLevelInputs, inInfo)

    case (_, _, _, _, _)
      equation
        true = Config.acceptParModelicaGrammar();
      then
        ();

    case (_, _, _, _, _)
      equation
        true = inAllowTopLevelInputs or not FGraph.inFunctionScope(inEnv);
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
  input FCore.Graph inEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExpCrefs, inAttributes, inEnv, inInfo)
    case (_, _, _, _)
      equation
        false = FGraph.inFunctionScope(inEnv);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpLst;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output list<DAE.Exp> outExpLst;
  output list<DAE.Properties> outPropertiesLst;
  output list<DAE.Attributes> outAttributesLst;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExpLst,outPropertiesLst,outAttributesLst,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExpLst,inImplicit,inST,performVectorization,inPrefix,info,numErrorMessages)
    local
      FCore.Cache cache;
      FCore.Graph env;
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

    case (cache,_,{},_,st,_,_,_,_) then (cache,{},{},{},st);

    case (cache,env,Absyn.CREF(componentRef = cr)::rest,impl,st,doVect,pre,_,_) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.CEVAL_EQUATION);
        (cache,SOME((exp,DAE.PROP(ty,DAE.C_PARAM()),attr))) = elabCrefNoEval(cache,env, cr, impl, doVect, pre, info);
        (cache, expLst, propLst, attrLst, st) = elabExpCrefNoEvalList(cache, env, rest, impl, st, doVect, pre, info, numErrorMessages);
      then
        (cache,exp::expLst,DAE.PROP(ty,DAE.C_VAR())::propLst,attr::attrLst,st);

    case (cache,env,Absyn.CREF(componentRef = cr)::rest,impl,st,doVect,pre,_,_)
      equation
        (cache,SOME((exp,prop,attr))) = elabCrefNoEval(cache, env, cr, impl, doVect, pre, info);
        (cache, expLst, propLst, attrLst, st) = elabExpCrefNoEvalList(cache, env, rest, impl, st, doVect, pre, info, numErrorMessages);
      then
        (cache,exp::expLst,prop::propLst,attr::attrLst,st);

   case (_,_,aExp::_,_,_,_,_,_,_)
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption):=
  matchcontinue (inCache,inEnv,inExp,inImplicit,inST,performVectorization,inPrefix,info,numErrorMessages)
    local
      Boolean impl,a,b,havereal,doVect;
      Integer l,i,nmax;
      Real r;
      DAE.ClockKind ck;
      String expstr,str1,str2,s,msg,replaceWith;
      DAE.Dimension dim1,dim2;
      Option<GlobalScript.SymbolTable> st,st_1,st_2;
      DAE.Exp exp,e1_1,e2_1,exp_1,e_1,mexp,mexp_1,arrexp;
      DAE.Properties prop,prop1,prop2;
      FCore.Graph env;
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
      FCore.Cache cache;
      Absyn.ForIterators iterators;
      Prefix.Prefix pre;
      list<list<Absyn.Exp>> ess;
      list<list<DAE.Exp>> dess;
      Absyn.CodeNode cn;
      list<DAE.Type> typeList;
      list<DAE.Const> constList;
      Absyn.ReductionIterType iterType;

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
    case (cache,_,Absyn.INTEGER(value = i),_,st,_,_,_,_)
      then (cache,DAE.ICONST(i),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()),st);

    case (cache,_,Absyn.REAL(value = s),_,st,_,_,_,_)
      equation
        r = System.stringReal(s);
      then (cache,DAE.RCONST(r),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_CONST()),st);

    case (cache,_,Absyn.STRING(value = s),_,st,_,_,_,_)
      equation
        s = System.unescapedString(s);
      then
        (cache,DAE.SCONST(s),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()),st);

    case (cache,_,Absyn.BOOL(value = b),_,st,_,_,_,_)
      then
        (cache,DAE.BCONST(b),DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()),st);

    case (_,_,Absyn.END(),_,_,_,_,_,_)
      equation
        Error.addSourceMessage(Error.END_ILLEGAL_USE_ERROR, {}, info);
      then fail();

    case (cache,env,Absyn.CREF(componentRef = cr),impl,st,doVect,pre,_,_) // BoschRexroth specifics
      equation
        false = Flags.getConfigBool(Flags.CEVAL_EQUATION);
        (cache,SOME((exp,DAE.PROP(ty,DAE.C_PARAM()),_))) = elabCref(cache,env, cr, impl, doVect, pre, info);
      then
        (cache,exp,DAE.PROP(ty,DAE.C_VAR()),st);

    case (cache,env,Absyn.CREF(componentRef = cr),impl,st,doVect,pre,_,_)
      equation
        (cache,SOME((exp,prop,_))) = elabCref(cache, env, cr, impl, doVect, pre, info);
      then
        (cache,exp,prop,st);

    case (cache,env,(e as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre,_,_) /* Binary and unary operations */
      equation
        (cache,e1_1,prop1,st_1) = elabExpInExpression(cache,env, e1, impl, st,doVect,pre,info);
        (cache,e2_1,prop2,st_2) = elabExpInExpression(cache,env, e2, impl, st_1,doVect,pre,info);
        (cache,exp_1,prop) = OperatorOverloading.binary(cache,env,op,prop1,e1_1,prop2,e2_1,e,e1,e2,impl,st_2,pre,info);
      then
        (cache,exp_1,prop,st_2);

    case (cache,env,(Absyn.UNARY(op = Absyn.UPLUS(),exp = e1)),impl,st,doVect,pre,_,_)
      equation
        (cache,exp_1,DAE.PROP(t,c),st_1) = elabExpInExpression(cache,env,e1,impl,st,doVect,pre,info);
        true = Types.isIntegerOrRealOrSubTypeOfEither(Types.arrayElementType(t));
        prop = DAE.PROP(t,c);
      then
        (cache,exp_1,prop,st_1);

    case (cache,env,(e as Absyn.UNARY(op = op,exp = e1)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop1,st_1) = elabExpInExpression(cache,env,e1,impl,st,doVect,pre,info);
        (cache,exp_1,prop) = OperatorOverloading.unary(cache,env,op,prop1,e_1,e,e1,impl,st_1,pre,info);
      then
        (cache,exp_1,prop,st_1);

    case (cache,env,(e as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre,_,_) "Logical binary expressions"
      equation
        (cache,e1_1,prop1,st_1) = elabExpInExpression(cache,env, e1, impl, st,doVect,pre,info);
        (cache,e2_1,prop2,st_2) = elabExpInExpression(cache,env, e2, impl, st_1,doVect,pre,info);
        (cache,exp_1,prop) = OperatorOverloading.binary(cache,env,op,prop1,e1_1,prop2,e2_1,e,e1,e2,impl,st_2,pre,info);
      then
        (cache,exp_1,prop,st_2);

    case (cache,env,(e as Absyn.LUNARY(op = op,exp = e1)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop1,st_1) = elabExpInExpression(cache,env,e1,impl,st,doVect,pre,info);
        (cache,exp_1,prop) = OperatorOverloading.unary(cache,env,op,prop1,e_1,e,e1,impl,st_1,pre,info);
      then
        (cache,exp_1,prop,st_1);


    case (cache,env,(e as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,st,doVect,pre,_,_)
      equation
        (cache,e1_1,prop1,st_1) = elabExpInExpression(cache,env, e1, impl, st,doVect,pre,info);
        (cache,e2_1,prop2,st_2) = elabExpInExpression(cache,env, e2, impl, st_1,doVect,pre,info);
        (cache,exp_1,prop) = OperatorOverloading.binary(cache,env,op,prop1,e1_1,prop2,e2_1,e,e1,e2,impl,st_2,pre,info);
      then
        (cache,exp_1,prop,st_2);

    case (cache,env,e as Absyn.IFEXP(ifExp = _),impl,st,doVect,pre,_,_) /* Conditional expressions */
      equation
        Absyn.IFEXP(ifExp = e1,trueBranch = e2,elseBranch = e3) = Absyn.canonIfExp(e);
        (cache,e1_1,prop1,st_1) = elabExpInExpression(cache,env, e1, impl, st,doVect,pre,info) "if expressions";
        (cache,e_1,prop,st_2) = elabIfExp(cache,env,e1_1,prop1,e2,e3,impl,st_1,doVect,pre,info);
      then
        (cache,e_1,prop,st_2);

    // adrpo: deal with EnumToInteger(E) -> transform to Integer(E)
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,_,pre,_,_)
      equation
        s = Absyn.crefLastIdent(fn);
        true = stringEq(s, "EnumToInteger");
        (cache,e_1,prop,st_1) = elabCall(cache, env, Absyn.CREF_IDENT("Integer", {}), args, nargs, impl, st,pre,info,Error.getNumErrorMessages());
        _ = Types.propAllConst(prop);
        (e_1,_) = ExpressionSimplify.simplify1(e_1);
      then
        (cache,e_1,prop,st_1);

    // adrpo: deal with DynamicSelect(literalExp, dynamicExp) by returning literalExp only!
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("DynamicSelect",_),functionArgs = Absyn.FUNCTIONARGS(args = (e1 :: _),argNames = _)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = elabExpInExpression(cache,env, e1, impl, st, doVect, pre, info);
      then
        (cache,e_1,prop,st_1);

       /*--------------------------------*/
       /* Part of MetaModelica extension. KS */
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("SOME",_),functionArgs = Absyn.FUNCTIONARGS(args = (e1 :: _),argNames = _)),impl,st,doVect,pre,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,e_1,prop,_) = elabExpInExpression(cache,env, e1, impl, st,doVect,pre,info);
        t = Types.getPropType(prop);
        (e_1,t) = Types.matchType(e_1,t,DAE.T_METABOXED_DEFAULT,true);
        e_1 = DAE.META_OPTION(SOME(e_1));
        c = Types.propAllConst(prop);
        prop1 = DAE.PROP(DAE.T_METAOPTION(t, DAE.emptyTypeSource),c);
      then
        (cache,e_1,prop1,st);

    case (cache,_,Absyn.CALL(function_ = Absyn.CREF_IDENT("NONE",_),functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = _)),_,st,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        e_1 = DAE.META_OPTION(NONE());
        prop1 = DAE.PROP(DAE.T_METAOPTION(DAE.T_UNKNOWN_DEFAULT, DAE.emptyTypeSource),DAE.C_CONST());
      then
        (cache,e_1,prop1,st);

    //Check if 'String' is overloaded. This can be moved down the chain to avoid checking for normal types.
    //However elab call prints error messags if it can not elaborate it even though the function might be overloaded.
    case (cache,env, e as Absyn.CALL(function_ = Absyn.CREF_IDENT("String",_),functionArgs = Absyn.FUNCTIONARGS(argNames = _)),impl,st,doVect,pre,_,_)
      equation
        (cache,exp_1,prop,st_1) = OperatorOverloading.string(cache,env,e,impl,st,doVect,pre,info);
      then
        (cache,exp_1,prop,st_1);

    // homotopy replacement (usually used for debugging only)
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("homotopy", _),functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,doVect,pre,_,_)
      equation
        replaceWith = Flags.getConfigString(Flags.REPLACE_HOMOTOPY);
        // replace homotopy if Flags.REPLACE_HOMOTOPY is "actual" or "simplified"
        false = stringEq(replaceWith, "none");
        true = boolOr(stringEq(replaceWith, "actual"), stringEq(replaceWith, "simplified"));
        // TODO, handle empy args and nargs for homotopy!
        {e1, e2} = getHomotopyArguments(args, nargs);
        e = Util.if_(stringEq(replaceWith, "actual"), e1, e2);
        (cache,e_1,prop,st_1) = elabExpInExpression(cache, env, e, impl, st, doVect, pre, info);
      then
        (cache,e_1,prop,st_1);

    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),impl,st,_,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = elabCall(cache, env, fn, args, nargs, impl, st, pre, info, Error.getNumErrorMessages());
        _ = Types.propAllConst(prop);
        (e_1,_) = ExpressionSimplify.simplify1(e_1);
      then
        (cache,e_1,prop,st_1);

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
        (e_1,prop) = fixTupleMetaModelica(Config.acceptMetaModelicaGrammar(),es_1,types,consts);
      then
        (cache,e_1,prop,st);

    // Array-related expressions Elab reduction expressions, including array() constructor
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FOR_ITER_FARG(exp = e, iterType=iterType, iterators=iterators)),impl,st,doVect,pre,_,_)
      equation
        (cache,e_1,prop,st_1) = elabCallReduction(cache,env, fn, e, iterType, iterators, impl, st,doVect,pre,info);
        _ = Types.propAllConst(prop);
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
        (cache,exp,prop,st) = elabExpInExpression(cache,env,Absyn.LIST({}),impl,st,doVect,pre,info);
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
        nmax = matrixConstrMaxDim(tps_2, 2);
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

    case (cache,env,Absyn.CODE(code = cn),_,st,_,_,_,_)
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
       (cache,exp,prop,st) = elabExpInExpression(cache,env,Absyn.LIST(es),impl,st,doVect,pre,info);
     then (cache,exp,prop,st);

   case (cache,env,Absyn.CONS(e1,e2),impl,st,doVect,pre,_,_)
     equation
       {e1,e2} = MetaUtil.transformArrayNodesToListNodes({e1,e2},{});

       (cache,e1_1,prop1,_) = elabExpInExpression(cache,env, e1, impl, st,doVect,pre,info);
       (cache,e2_1,DAE.PROP(DAE.T_METALIST(listType = t2),c2),_) = elabExpInExpression(cache,env, e2, impl, st,doVect,pre,info);
       t1 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(Types.getPropType(prop1));
       t2 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t2);
       c1 = Types.propAllConst(prop1);
       t = Types.getUniontypeIfMetarecordReplaceAllSubtypes(Types.superType(Types.boxIfUnboxedType(t1),Types.boxIfUnboxedType(t2)));

       (e1_1,_) = Types.matchType(e1_1, t1, t, true);
       (e2_1,_) = Types.matchType(e2_1, DAE.T_METALIST(t, DAE.emptyTypeSource), DAE.T_METALIST(t2, DAE.emptyTypeSource), true);

       exp = DAE.CONS(e1_1,e2_1);
       c = Types.constAnd(c1,c2);
       prop = DAE.PROP(DAE.T_METALIST(t, DAE.emptyTypeSource),c);
     then (cache,exp,prop,st);

   case (cache,env,e as Absyn.CONS(e1,e2),impl,st,doVect,pre,_,_)
     equation
       {e1,e2} = MetaUtil.transformArrayNodesToListNodes({e1,e2},{});
       (cache,_,prop1,_) = elabExpInExpression(cache,env, e1, impl, st,doVect,pre,info);
       (cache,_,DAE.PROP(t2 as DAE.T_METALIST(listType = _),_),_) = elabExpInExpression(cache,env, e2, impl, st,doVect,pre,info);
       expstr = Dump.printExpStr(e);
       str1 = Types.unparseType(Types.getPropType(prop1));
       str2 = Types.unparseType(t2);
       Error.addSourceMessage(Error.META_CONS_TYPE_MATCH, {expstr,str1,str2}, info);
     then fail();

       // The Absyn.LIST() node is used for list expressions that are
       // transformed from Absyn.ARRAY()
   case (cache,_,Absyn.LIST({}),_,st,_,_,_,_)
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

   case (_,_,e,_,_,_,_,_,_)
     equation
       true = numErrorMessages == Error.getNumErrorMessages();
       msg = Dump.printExpStr(e);
       Error.addSourceMessage(Error.GENERIC_ELAB_EXPRESSION,{msg},info);
       /* FAILTRACE REMOVE
       true = Flags.isSet(Flags.FAILTRACE);
       Debug.fprint(Flags.FAILTRACE, "- Static.elabExp failed: ");
       Debug.traceln(Dump.printExpStr(e));
       Debug.traceln("  Scope: " +& FGraph.printGraphPathStr(env));
       Debug.traceln("  Prefix: " +& PrefixUtil.printPrefixStr(pre));

       //Debug.traceln("\n env : ");
       //Debug.traceln(FGraph.printGraphStr(env));
       //Debug.traceln("\n----------------------- FINISHED ENV ------------------------\n");
       */
     then
       fail();
  end matchcontinue;
end elabExp2;

public function getHomotopyArguments
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  output list<Absyn.Exp> outPositionalArgs;
algorithm
  outPositionalArgs := matchcontinue(args, nargs)
    local
      Absyn.Exp e1, e2;

    // only positional
    case ({e1, e2}, _) then {e1, e2};
    // only named
    case ({}, {Absyn.NAMEDARG("actual", e1), Absyn.NAMEDARG("simplified", e2)}) then {e1, e2};
    case ({}, {Absyn.NAMEDARG("simplified", e2), Absyn.NAMEDARG("actual", e1)}) then {e1, e2};
    // combination
    case ({e1}, {Absyn.NAMEDARG("simplified", e2)}) then {e1, e2};
    case (_, _)
      equation
        Error.addCompilerError("+replaceHomotopy: homotopy called with wrong arguments: " +&
          Dump.printFunctionArgsStr(Absyn.FUNCTIONARGS(args, nargs)));
      then
        fail();
  end matchcontinue;
end getHomotopyArguments;

protected function elabIfExp
"Elaborates an if-expression. If one of the branches can not be elaborated and
the condition is parameter or constant; it is evaluated and the correct branch is selected.
This is a dirty hack to make MSL CombiTable models work!
Note: Because of this, the function has to rollback or delete an ErrorExt checkpoint."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp condExp;
  input DAE.Properties condProp;
  input Absyn.Exp trueExp;
  input Absyn.Exp falseExp;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean vect;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Cache cache;
      FCore.Graph env;

    case (cache,env,_,_,_,_,_,st,_,_,_)
      equation
        ErrorExt.setCheckpoint("Static.elabExp:IFEXP");
        (cache,etrueExp,trueProp,st) = elabExpInExpression(cache,env,trueExp,impl,st,vect,pre,info);
        (cache,efalseExp,falseProp,st) = elabExpInExpression(cache,env,falseExp,impl,st,vect,pre,info);
        (cache,outExp,prop) = makeIfexp(cache,env,condExp,condProp,etrueExp,trueProp,efalseExp,falseProp,impl,st,pre,info);
        ErrorExt.delCheckpoint("Static.elabExp:IFEXP");
      then (cache,outExp,prop,st);
    case (cache,env,_,_,_,_,_,st,_,_,_)
      equation
        ErrorExt.setCheckpoint("Static.elabExp:IFEXP:HACK") "Extra rollback point so we get the regular error message only once if the hack fails";
        true = Types.isParameterOrConstant(Types.propAllConst(condProp));
        (cache,Values.BOOL(b),_) = Ceval.ceval(cache,env,condExp,impl,NONE(),Absyn.MSG(info),0);
        (cache,outExp,prop,st) = elabExpInExpression(cache,env,Util.if_(b,trueExp,falseExp),impl,st,vect,pre,info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inExpList;
  input DAE.Properties inProp;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outInteractiveInteractiveSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outInteractiveInteractiveSymbolTableOption) :=
  matchcontinue (inCache,inEnv,inExpList,inProp,inBoolean,inST,performVectorization,inPrefix,info)
    local
      FCore.Cache cache;
      FCore.Graph env;
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

    case (cache,_,{},prop,_,st,_,_,_) then (cache,DAE.LIST({}),prop,st);

    case (cache,env,expList,DAE.PROP(DAE.T_METALIST(listType = t),c),impl,st,doVect,pre,_)
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
  input Absyn.ClassPart cp;
  output list<Absyn.AlgorithmItem> algsOut;
algorithm
  algsOut := match cp
    local
      list<Absyn.AlgorithmItem> localAccList;
      FCore.Cache localCache;
      FCore.Graph localEnv;
      Prefix.Prefix pre;
      Option<Absyn.Comment> comment;
      Absyn.Info info;
      Absyn.Equation first;
      list<Absyn.EquationItem> rest;
      list<Absyn.AlgorithmItem> alg;
      String str;
    case Absyn.ALGORITHMS(alg) then alg;
    case Absyn.EQUATIONS(rest)
      then fromEquationsToAlgAssignmentsWork(rest,{});
    else
      equation
        str = Dump.unparseClassPart(cp);
        Error.addInternalError("Static.fromEquationsToAlgAssignments: Unknown classPart in match expression:\n" +& str);
      then fail();
  end match;
end fromEquationsToAlgAssignments;

protected function fromEquationsToAlgAssignmentsWork " Converts equations to algorithm assignments.
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
  output list<Absyn.AlgorithmItem> algsOut;
algorithm
  algsOut := match (eqsIn,accList)
    local
      list<Absyn.AlgorithmItem> localAccList;
      FCore.Cache localCache;
      FCore.Graph localEnv;
      Prefix.Prefix pre;
      Option<Absyn.Comment> comment;
      Absyn.Info info;
      Absyn.Equation first;
      list<Absyn.EquationItem> rest;
      list<Absyn.AlgorithmItem> alg;
    case ({},localAccList) then listReverse(localAccList);
    case (Absyn.EQUATIONITEM(equation_ = first, comment = comment, info = info) :: rest,localAccList)
      equation
        alg = fromEquationToAlgAssignment(first,comment,info);
        localAccList = fromEquationsToAlgAssignmentsWork(rest,listAppend(alg,localAccList));
      then localAccList;
    case (Absyn.EQUATIONITEMCOMMENT(comment=_) :: rest,localAccList)
      equation
        localAccList = fromEquationsToAlgAssignmentsWork(rest,localAccList);
      then localAccList;
  end match;
end fromEquationsToAlgAssignmentsWork;

protected function fromEquationBranchesToAlgBranches
"Converts equations to algorithm assignments."
  input list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> eqsIn;
  input list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> accList;
  output list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> algsOut;
algorithm
  algsOut := match (eqsIn,accList)
    local
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> localAccList;
      list<tuple<Absyn.Exp,list<Absyn.EquationItem>>> rest;
      FCore.Cache localCache;
      FCore.Graph localEnv;
      Prefix.Prefix pre;
      Absyn.Exp e;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.EquationItem> eqs;
    case ({},localAccList) then listReverse(localAccList);
    case ((e,eqs)::rest,localAccList)
      equation
        algs = fromEquationsToAlgAssignmentsWork(eqs,{});
        (localAccList) = fromEquationBranchesToAlgBranches(rest,(e,algs)::localAccList);
      then localAccList;
  end match;
end fromEquationBranchesToAlgBranches;

protected function fromEquationToAlgAssignment "function: fromEquationToAlgAssignment"
  input Absyn.Equation eq;
  input Option<Absyn.Comment> comment;
  input Absyn.Info info;
  output list<Absyn.AlgorithmItem> algStatement;
algorithm
  algStatement := matchcontinue (eq,comment,info)
    local
      FCore.Cache localCache,cache;
      FCore.Graph env;
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

    case (Absyn.EQ_EQUALS(Absyn.CREF(Absyn.CREF_IDENT(strLeft,{})),Absyn.CREF(Absyn.CREF_IDENT(strRight,{}))),_,_)
      equation
        true = strLeft ==& strRight;
        // match x case x then ... produces equation x = x; we save a bit of time by removing it here :)
      then {};

      // The syntax n>=0 = true; is also used
    case (Absyn.EQ_EQUALS(left,Absyn.BOOL(true)),_,_)
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("fail",{}),Absyn.FUNCTIONARGS({},{})),comment,info);
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.LUNARY(Absyn.NOT(),left),{algItem1},{},{}),comment,info);
      then {algItem2};

    case (Absyn.EQ_EQUALS(left,Absyn.BOOL(false)),_,_)
      equation
        failure(Absyn.CREF(_) = left); // If lhs is a CREF, it should be an assignment
        algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("fail",{}),Absyn.FUNCTIONARGS({},{})),comment,info);
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_IF(left,{algItem1},{},{}),comment,info);
      then {algItem2};

    case (Absyn.EQ_NORETCALL(Absyn.CREF_IDENT("fail",_),_),_,_)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(Absyn.CREF_IDENT("fail",{}),Absyn.FUNCTIONARGS({},{})),comment,info);
      then {algItem};

    case (Absyn.EQ_NORETCALL(cref,fargs),_,_)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_NORETCALL(cref,fargs),comment,info);
      then {algItem};

    case (Absyn.EQ_EQUALS(left,right),_,_)
      equation
        algItem = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),comment,info);
      then {algItem};

    case (Absyn.EQ_FAILURE(Absyn.EQUATIONITEM(eq2,comment2,info2)),_,_)
      equation
        algs = fromEquationToAlgAssignment(eq2,comment2,info2);
        res = Absyn.ALGORITHMITEM(Absyn.ALG_FAILURE(algs),comment,info);
      then {res};

    case (Absyn.EQ_IF(ifExp = e, equationTrueItems = eqTrueItems, elseIfBranches = eqBranches, equationElseItems = eqElseItems),_,_)
      equation
        algTrueItems = fromEquationsToAlgAssignmentsWork(eqTrueItems,{});
        algElseItems = fromEquationsToAlgAssignmentsWork(eqElseItems,{});
        algBranches = fromEquationBranchesToAlgBranches(eqBranches,{});
        res = Absyn.ALGORITHMITEM(Absyn.ALG_IF(e, algTrueItems, algBranches, algElseItems),comment,info);
      then {res};

    else
      equation
        str = Dump.equationName(eq);
        Error.addSourceMessage(Error.META_MATCH_EQUATION_FORBIDDEN, {str}, info);
      then fail();
  end matchcontinue;
end fromEquationToAlgAssignment;

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
    case (DAE.ARRAY(ty = a as DAE.T_ARRAY(dims = _ :: _ :: {}), array = expl))
      equation
        mexpl = List.map(expl, Expression.arrayContent);
        d1 = listLength(mexpl);
        true = Expression.typeBuiltin(Expression.unliftArray(Expression.unliftArray(a)));
      then
        DAE.MATRIX(a,d1,mexpl);

    // if fails, skip conversion, use generic array expression as is.
    else inExp;
  end matchcontinue;
end elabMatrixToMatrixExp;

protected function matrixConstrMaxDim
  "Helper function to elabExp (MATRIX).
  Determines the maximum dimension of the array arguments to the matrix
  constructor as.
  max(2, ndims(A), ndims(B), ndims(C),..) for matrix constructor arguments
  A, B, C, ..."
  input list<DAE.Type> inTypes;
  input Integer inAccumMax;
  output Integer outMaxDim;
algorithm
  outMaxDim := match(inTypes, inAccumMax)
    local
      DAE.Type ty;
      list<DAE.Type> rest_tys;
      Integer dims;

    case ({}, _) then inAccumMax;

    case (ty :: rest_tys, _)
      equation
        dims = Types.numberOfDimensions(ty);
        dims = intMax(dims, inAccumMax);
      then
        matrixConstrMaxDim(rest_tys, dims);

  end match;
end matrixConstrMaxDim;

protected function elabCallReduction
"This function elaborates reduction expressions that look like function
  calls. For example an array constructor."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef reductionFn;
  input Absyn.Exp reductionExp;
  input Absyn.ReductionIterType iterType;
  input Absyn.ForIterators iterators;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outExp,outProperties,outST):=
  matchcontinue (inCache,inEnv,reductionFn,reductionExp,iterType,iterators,impl,
      inST,performVectorization,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.Type expty,resultTy;
      DAE.Const iterconst,expconst,const;
      FCore.Graph env_foldExp,env_1,env;
      Option<GlobalScript.SymbolTable> st;
      DAE.Properties prop;
      Absyn.Path fn_1;
      Absyn.ComponentRef fn;
      Absyn.Exp exp;
      Boolean doVect,hasGuardExp;
      FCore.Cache cache;
      Prefix.Prefix pre;
      Option<Absyn.Exp> afoldExp;
      Option<DAE.Exp> foldExp;
      Option<Values.Value> v;
      list<DAE.ReductionIterator> reductionIters;
      DAE.Dimensions dims;
      DAE.Properties props;
      Absyn.ForIterators iters;
      String foldId,resultId;

    case (cache,env,fn,exp,_,iters,_,st,doVect,pre,_)
      equation
        env_1 = FGraph.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(FCore.forIterScopeName), NONE());
        iters = listReverse(iters);
        (cache,env_1,reductionIters,dims,iterconst,hasGuardExp,st) = elabCallReductionIterators(cache, env_1, iters, impl, st, doVect, pre, info);
        dims = listReverse(dims);
        dims = fixDimsItertype(iterType,dims);
        // print("elabReductionExp: " +& Dump.printExpStr(exp) +& "\n");
        (cache,exp_1,DAE.PROP(expty, expconst),st) = elabExpInExpression(cache, env_1, exp, impl, st, doVect, pre, info);
        // print("exp_1 has type: " +& Types.unparseType(expty) +& "\n");
        const = Types.constAnd(expconst, iterconst);
        fn_1 = Absyn.crefToPath(fn);
        (cache,exp_1,expty,resultTy,v,fn_1) = reductionType(cache, env, fn_1, exp_1, expty, Types.unboxedType(expty), dims, hasGuardExp, info);
        prop = DAE.PROP(expty, const);
        foldId = Util.getTempVariableIndex();
        resultId = Util.getTempVariableIndex();
        (env_foldExp,afoldExp) = makeReductionFoldExp(env_1,fn_1,expty,resultTy,foldId,resultId);
        (cache,foldExp,_,st) = elabExpOptAndMatchType(cache, env_foldExp, afoldExp, resultTy, impl, st, doVect,pre,info);
        // print("make reduction: " +& Absyn.pathString(fn_1) +& " exp_1: " +& ExpressionDump.printExpStr(exp_1) +& " ty: " +& Types.unparseType(expty) +& "\n");
        exp_1 = DAE.REDUCTION(DAE.REDUCTIONINFO(fn_1,iterType,expty,v,foldId,resultId,foldExp),exp_1,reductionIters);
      then
        (cache,exp_1,prop,st);

    case (_,_,_,_,_,_::_::_,_,_,_,_,_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Reductions using multiple iterators is not yet implemented. Try rewriting the expression using nested reductions (e.g. array(i+j for i, j) => array(array(i+j for i) for j)."}, info);
      then fail();

    else
      equation
        Debug.fprint(Flags.FAILTRACE, "Static.elabCallReduction - failed!\n");
      then fail();
  end matchcontinue;
end elabCallReduction;

protected function fixDimsItertype
  input Absyn.ReductionIterType iterType;
  input list<DAE.Dimension> dims;
  output list<DAE.Dimension> outDims;
algorithm
  outDims := match (iterType,dims)
    local
      DAE.Dimension dim;
    case (Absyn.COMBINE(),_) then dims;
    case (_,dim::_) // TODO: Get the best dimension (if several, choose the one that is integer constant; we do run-time checks to assert they are all equal)
      then {dim};
  end match;
end fixDimsItertype;

protected function elabCallReductionIterators
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ForIterators inIterators;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean doVect;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output FCore.Graph envWithIterators;
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
      FCore.Cache cache;
      FCore.Graph env;
      DAE.Const iterconst,guardconst;
      DAE.Type fulliterty,iterty;
      Option<GlobalScript.SymbolTable> st;
      Absyn.ForIterators iterators;

    case (cache,env,{},_,st,_,_,_) then (cache,env,{},{},DAE.C_CONST(),false,st);
    case (cache,env,Absyn.ITERATOR(iter,aguardExp,SOME(aiterExp))::iterators,_,st,_,_,_)
      equation
        (cache,iterExp,DAE.PROP(fulliterty,iterconst),st) = elabExpInExpression(cache, env, aiterExp, impl, st, doVect,pre,info);
        // We need to evaluate the iterator because the rest of the compiler is stupid
        (cache,iterExp,_) = Ceval.cevalIfConstant(cache,env,iterExp,DAE.PROP(fulliterty,DAE.C_CONST()),impl, info);
        (iterty,dim) = Types.unliftArrayOrList(fulliterty);

        // print("iterator type: " +& Types.unparseType(iterty) +& "\n");
        envWithIterators = FGraph.addForIterator(env, iter, iterty, DAE.UNBOUND(), SCode.CONST(), SOME(iterconst));
        // print("exp_1 has type: " +& Types.unparseType(expty) +& "\n");
        (cache,guardExp,DAE.PROP(_, guardconst),st) = elabExpOptAndMatchType(cache, envWithIterators, aguardExp, DAE.T_BOOL_DEFAULT, impl, st, doVect,pre,info);

        diter = DAE.REDUCTIONITER(iter,iterExp,guardExp,iterty);

        (cache,envWithIterators,diters,dims,const,hasGuardExp,st) = elabCallReductionIterators(cache,env,iterators,impl,st,doVect,pre,info);
        // Yes, we do this twice to hide the iterators from the different guard-expressions...
        envWithIterators = FGraph.addForIterator(envWithIterators, iter, iterty, DAE.UNBOUND(), SCode.CONST(), SOME(iterconst));
        const = Types.constAnd(guardconst, iterconst);
        hasGuardExp = hasGuardExp or Util.isSome(guardExp);
        dim = Util.if_(Util.isSome(guardExp), DAE.DIM_UNKNOWN(), dim);
      then (cache,envWithIterators,diter::diters,dim::dims,const,hasGuardExp,st);
  end match;
end elabCallReductionIterators;

protected function makeReductionFoldExp
  input FCore.Graph inEnv;
  input Absyn.Path path;
  input DAE.Type expty;
  input DAE.Type resultTy;
  input String foldId;
  input String resultId;
  output FCore.Graph outEnv;  output Option<Absyn.Exp> afoldExp;
algorithm
  (outEnv,afoldExp) := match (inEnv,path,expty,resultTy,foldId,resultId)
    local
      Absyn.Exp exp;
      Absyn.ComponentRef cr,cr1,cr2;
      FCore.Graph env;

    case (env,Absyn.IDENT("array"),_,_,_,_) then (env,NONE());
    case (env,Absyn.IDENT("list"),_,_,_,_) then (env,NONE());
    case (env,Absyn.IDENT("listReverse"),_,_,_,_) then (env,NONE());
    case (env,Absyn.IDENT("sum"),_,_,_,_)
      equation
        _ = Absyn.pathToCref(path);
        env = FGraph.addForIterator(env, foldId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = FGraph.addForIterator(env, resultId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT(foldId,{});
        cr2 = Absyn.CREF_IDENT(resultId,{});
        exp = Absyn.BINARY(Absyn.CREF(cr2),Absyn.ADD(),Absyn.CREF(cr1));
      then (env,SOME(exp));
    case (env,Absyn.IDENT("product"),_,_,_,_)
      equation
        _ = Absyn.pathToCref(path);
        env = FGraph.addForIterator(env, foldId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = FGraph.addForIterator(env, resultId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT(foldId,{});
        cr2 = Absyn.CREF_IDENT(resultId,{});
        exp = Absyn.BINARY(Absyn.CREF(cr2),Absyn.MUL(),Absyn.CREF(cr1));
      then (env,SOME(exp));
    else
      equation
        env = inEnv;
        cr = Absyn.pathToCref(path);
        // print("makeReductionFoldExp => " +& Absyn.pathString(path) +& Types.unparseType(expty) +& "\n");
        env = FGraph.addForIterator(env, foldId, expty, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        env = FGraph.addForIterator(env, resultId, resultTy, DAE.UNBOUND(), SCode.VAR(), SOME(DAE.C_VAR()));
        cr1 = Absyn.CREF_IDENT(foldId,{});
        cr2 = Absyn.CREF_IDENT(resultId,{});
        exp = Absyn.CALL(cr,Absyn.FUNCTIONARGS({Absyn.CREF(cr1),Absyn.CREF(cr2)},{}));
      then (env,SOME(exp));
  end match;
end makeReductionFoldExp;

protected function reductionType
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path fn;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input DAE.Type unboxedType;
  input DAE.Dimensions dims;
  input Boolean hasGuardExp;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output DAE.Type resultType;
  output Option<Values.Value> defaultValue;
  output Absyn.Path outPath;
algorithm
  (outCache,outExp,outType,resultType,defaultValue,outPath) :=
  match (inCache, inEnv, fn, inExp, inType, unboxedType, dims, hasGuardExp, info)
    local
      Boolean b;
      Integer i;
      Real r;
      list<DAE.Type> fnTypes;
      DAE.Type ty,ty2,typeA,typeB,resType;
      Absyn.Path path;
      Values.Value v;
      DAE.Exp exp;
      FCore.Cache cache;
      FCore.Graph env;
      InstTypes.PolymorphicBindings bindings;
      Option<Values.Value> defaultBinding;

    case (cache,_,Absyn.IDENT(name = "array"), exp, ty, _, _, _, _)
      equation
        ty = List.foldr(dims,Types.liftArray,ty);
      then (cache,exp,ty,ty,SOME(Values.ARRAY({},{0})),fn);

    case (cache,_,Absyn.IDENT(name = "list"), exp, ty, _, _, _, _)
      equation
        (exp,ty) = Types.matchType(exp, ty, DAE.T_METABOXED_DEFAULT, true);
        ty = List.foldr(dims,Types.liftList,ty);
      then (cache,exp,ty,ty,SOME(Values.LIST({})),fn);

    case (cache,_,Absyn.IDENT(name = "listReverse"), exp, ty, _, _, _, _)
      equation
        (exp,ty) = Types.matchType(exp, ty, DAE.T_METABOXED_DEFAULT, true);
        ty = List.foldr(dims,Types.liftList,ty);
      then (cache,exp,ty,ty,SOME(Values.LIST({})),fn);

    case (cache,_,Absyn.IDENT("min"),exp, ty, DAE.T_REAL(varLst = _),_,_,_)
      equation
        r = System.realMaxLit();
        v = Values.REAL(r);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("min"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        i = System.intMaxLit();
        v = Values.INTEGER(i);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("min"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(true);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("min"),exp,ty,DAE.T_STRING(varLst = _),_,_,_)
      equation
        (exp,ty) = Types.matchType(exp, ty, DAE.T_STRING_DEFAULT, true);
      then (cache,exp,ty,ty,NONE(),fn);

    case (cache,_,Absyn.IDENT("max"),exp,ty,DAE.T_REAL(varLst = _),_,_,_)
      equation
        r = realNeg(System.realMaxLit());
        v = Values.REAL(r);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("max"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        i = intNeg(System.intMaxLit());
        v = Values.INTEGER(i);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("max"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(false);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("max"),exp,ty,DAE.T_STRING(varLst = _),_,_,_)
      equation
        v = Values.STRING("");
        (exp,ty) = Types.matchType(exp, ty, DAE.T_STRING_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("sum"),exp,ty,DAE.T_REAL(varLst = _),_,_,_)
      equation
        v = Values.REAL(0.0);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("sum"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        v = Values.INTEGER(0);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("sum"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(false);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("sum"),exp,ty,DAE.T_STRING(varLst = _),_,_,_)
      equation
        v = Values.STRING("");
        (exp,ty) = Types.matchType(exp, ty, DAE.T_STRING_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("sum"),exp,ty,DAE.T_ARRAY(ty =_),_,_,_)
      then (cache,exp,ty,ty,NONE(),fn);

    case (cache,_,Absyn.IDENT("product"),exp,ty,DAE.T_REAL(varLst = _),_,_,_)
      equation
        v = Values.REAL(1.0);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_REAL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("product"),exp,ty,DAE.T_INTEGER(varLst = _),_,_,_)
      equation
        v = Values.INTEGER(1);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_INTEGER_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (cache,_,Absyn.IDENT("product"),exp,ty,DAE.T_BOOL(varLst = _),_,_,_)
      equation
        v = Values.BOOL(true);
        (exp,ty) = Types.matchType(exp, ty, DAE.T_BOOL_DEFAULT, true);
      then (cache,exp,ty,ty,SOME(v),fn);

    case (_,_,Absyn.IDENT("product"),_,_,DAE.T_STRING(varLst = _),_,_,_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"product reduction not defined for String"},info);
      then fail();

    case (cache,_,Absyn.IDENT("product"),exp,ty,DAE.T_ARRAY(ty = _),_,_,_)
      equation
      then (cache,exp,ty,ty,NONE(),fn);

    case (cache,env,path,exp,ty,_,_,_,_)
      equation
        (cache,fnTypes) = Lookup.lookupFunctionsInEnv(cache, env, path, info);
        (typeA,typeB,resType,defaultBinding,path) = checkReductionType1(env,path,fnTypes,info);
        ty2 = Util.if_(Util.isSome(defaultBinding),typeB,ty);
        (exp,typeA,bindings) = Types.matchTypePolymorphicWithError(exp,ty,typeA,SOME(path),{},info);
        (_,typeB,bindings) = Types.matchTypePolymorphicWithError(DAE.CREF(DAE.CREF_IDENT("$result",DAE.T_ANYTYPE_DEFAULT,{}),DAE.T_ANYTYPE_DEFAULT),ty2,typeB,SOME(path),bindings,info);
        bindings = Types.solvePolymorphicBindings(bindings, info, {path});
        typeA = Types.fixPolymorphicRestype(typeA, bindings, info);
        typeB = Types.fixPolymorphicRestype(typeB, bindings, info);
        resType = Types.fixPolymorphicRestype(resType, bindings, info);
        (exp,ty) = checkReductionType2(exp,ty,typeA,typeB,resType,Types.equivtypes(typeA,typeB) or Util.isSome(defaultBinding),Types.equivtypes(typeB,resType),info);
        (cache,Util.SUCCESS()) = instantiateDaeFunction(cache, env, path, false, NONE(), true);
        Error.assertionOrAddSourceMessage(Config.acceptMetaModelicaGrammar() or Flags.isSet(Flags.EXPERIMENTAL_REDUCTIONS), Error.COMPILER_NOTIFICATION, {"Custom reduction functions are an OpenModelica extension to the Modelica Specification. Do not use them if you need your model to compile using other tools or if you are concerned about using experimental features. Use +d=experimentalReductions to disable this message."}, info);
      then (cache,exp,ty,typeB,defaultBinding,path);
  end match;
end reductionType;

protected function checkReductionType1
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<DAE.Type> fnTypes;
  input Absyn.Info info;
  output DAE.Type typeA;
  output DAE.Type typeB;
  output DAE.Type resType;
  output Option<Values.Value> startValue;
  output Absyn.Path outPath;
algorithm
  (typeA,typeB,resType,startValue,outPath) := match (inEnv,inPath,fnTypes,info)
    local
      String str1,str2;
      Absyn.Path path;
      FCore.Graph env;
      DAE.Exp e;
      Values.Value v;

    case (env, path, {}, _)
      equation
        str1 = Absyn.pathString(path);
        str2 = FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_ERROR, {str1,str2}, info);
      then fail();

    case (_, _, {DAE.T_FUNCTION(funcArg={DAE.FUNCARG(ty=typeA,const=DAE.C_VAR()),DAE.FUNCARG(ty=typeB,const=DAE.C_VAR(),defaultBinding=SOME(e))},funcResultType = resType, source = {path})}, _)
      equation
        v = Ceval.cevalSimple(e);
      then (typeA,typeB,resType,SOME(v),path);

    case (_, _, {DAE.T_FUNCTION(funcArg={DAE.FUNCARG(ty=typeA,const=DAE.C_VAR()),DAE.FUNCARG(ty=typeB,const=DAE.C_VAR(),defaultBinding=NONE())},funcResultType = resType, source = {path})}, _)
      then (typeA,typeB,resType,NONE(),path);

    else
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
        // (exp,outTy) = Types.matchType(exp,expType,typeA,true);
      then (exp,typeA);
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

protected function elabCodeType "This function will construct the correct type for the given Code
  expression. The types are built-in classes of different types. E.g.
  the class TypeName is the type
  of Code expressions corresponding to a type name Code expression."
  input FCore.Graph inEnv;
  input Absyn.CodeNode inCode;
  output DAE.Type outType;
algorithm
  outType := match (inEnv,inCode)
    local FCore.Graph env;

    case (_,Absyn.C_TYPENAME(path = _))
      then DAE.T_CODE(DAE.C_TYPENAME(),DAE.emptyTypeSource);

    case (_,Absyn.C_VARIABLENAME(componentRef = _))
      then DAE.T_CODE(DAE.C_VARIABLENAME(),DAE.emptyTypeSource);

    case (_,Absyn.C_EQUATIONSECTION(boolean = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("EquationSection")),{},NONE(),DAE.emptyTypeSource);

    case (_,Absyn.C_ALGORITHMSECTION(boolean = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("AlgorithmSection")),{},NONE(),DAE.emptyTypeSource);

    case (_,Absyn.C_ELEMENT(element = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Element")),{},NONE(),DAE.emptyTypeSource);

    case (_,Absyn.C_EXPRESSION(exp = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Expression")),{},NONE(),DAE.emptyTypeSource);

    case (_,Absyn.C_MODIFICATION(modification = _))
      then DAE.T_COMPLEX(ClassInf.UNKNOWN(Absyn.IDENT("Modification")),{},NONE(),DAE.emptyTypeSource);
  end match;
end elabCodeType;

public function elabGraphicsExp
"investigating Modelica 2.0 graphical annotations.
  These have an array of records representing graphical objects. These
  elements can have different types, therefore elab_graphic_exp will allow
  arrays with elements of varying types. "
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
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
      FCore.Cache cache;
      Prefix.Prefix pre;
      list<list<Absyn.Exp>> ess;
      list<list<DAE.Exp>> dess;

    case (cache,_,Absyn.INTEGER(value = i),_,_,_) then (cache,DAE.ICONST(i),DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()));  /* impl */

    case (cache,_,Absyn.REAL(value = s),_,_,_)
      equation
        r = System.stringReal(s);
      then
        (cache,DAE.RCONST(r),DAE.PROP(DAE.T_REAL_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.STRING(value = s),_,_,_)
      equation
        s = System.unescapedString(s);
      then
        (cache,DAE.SCONST(s),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()));

    case (cache,_,Absyn.BOOL(value = b),_,_,_)
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
        (cache, dexp, prop) = OperatorOverloading.binary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);
    case (cache,env,(e as Absyn.UNARY(op = Absyn.UPLUS(),exp = _)),impl,pre,_)
      equation
        (cache,e_1,DAE.PROP(t,c)) = elabGraphicsExp(cache,env, e, impl,pre,info);
        true = Types.isRealOrSubTypeReal(Types.arrayElementType(t));
        prop = DAE.PROP(t,c);
      then
        (cache,e_1,prop);
    case (cache,env,(exp as Absyn.UNARY(op = op,exp = e)),impl,pre,_)
      equation
        (cache,e_1,prop1) = elabGraphicsExp(cache,env, e, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.unary(cache,env, op, prop1, e_1, exp, e, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Logical binary expressions
    case (cache,env,(exp as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.binary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Logical unary expressions
    case (cache,env,(exp as Absyn.LUNARY(op = op,exp = e)),impl,pre,_)
      equation
        (cache,e_1,prop1) = elabGraphicsExp(cache,env, e, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.unary(cache,env, op, prop1, e_1, exp, e, impl, NONE(), pre, info);
      then
        (cache, dexp, prop);

    // Relation expressions
    case (cache,env,(exp as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)),impl,pre,_)
      equation
        (cache,e1_1,prop1) = elabGraphicsExp(cache,env, e1, impl,pre,info);
        (cache,e2_1,prop2) = elabGraphicsExp(cache,env, e2, impl,pre,info);
        (cache, dexp, prop) = OperatorOverloading.binary(cache, env, op, prop1, e1_1, prop2, e2_1, exp, e1, e2, impl, NONE(), pre, info);
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
    case (cache,env,Absyn.CALL(function_ = fn,functionArgs = Absyn.FUNCTIONARGS(args = args,argNames = nargs)),_,pre,_)
      equation
        (cache,e_1,prop,_) = elabCall(cache,env, fn, args, nargs, true,NONE(),pre,info,Error.getNumErrorMessages());
      then
        (cache,e_1,prop);

    // PR. Get the properties for each expression in the tuple.
    // Each expression has its own constflag.
    // The output from functions does just have one const flag. Fix this!!
    case (cache,env,Absyn.TUPLE(expressions = (es as (_ :: _))),impl,pre,_)
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
        (_,NONE(),_,rt) = deoverloadRange((start_1,start_t),NONE(), (stop_1,stop_t));
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
        nmax = matrixConstrMaxDim(tps_2, 2);
        havereal = Types.containReal(tps_2);
        (cache,mexp,DAE.PROP(t,c),dim1,dim2) = elabMatrixSemi(cache,env,dess,tps,impl,NONE(),havereal,nmax,true,pre,info);
        _ = Types.simplifyType(t);
        _ = elabMatrixToMatrixExp(mexp);
        t_1 = Types.unliftArray(t);
        t_2 = Types.unliftArray(t_1);
      then
        (cache,mexp,DAE.PROP(DAE.T_ARRAY(DAE.T_ARRAY(t_2, {dim2}, DAE.emptyTypeSource), {dim1}, DAE.emptyTypeSource),c));

    case (_,_,e,_,pre,_)
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
        ({e1_1, e3_1},_) = OperatorOverloading.elabArglist({DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT},
          {(e1, t1), (e3, t3)});
      then
        (e1_1, NONE(), e3_1, DAE.T_REAL_DEFAULT);

    case ((e1, t1), SOME((e2, t2)),(e3, t3))
      equation
        ({e1_1, e2_1, e3_1},_) = OperatorOverloading.elabArglist(
          {DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT, DAE.T_REAL_DEFAULT},
          {(e1, t1), (e2, t2), (e3, t3)});
      then
        (e1_1, SOME(e2_1), e3_1, DAE.T_REAL_DEFAULT);

  end matchcontinue;
end deoverloadRange;

protected function elabRange
  "Elaborates a range expression on the form start:stop or start:step:stop."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inRangeExp;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Cache cache;
      DAE.Type ety;
      list<String> error_strs;
      String error_str;

    // Range without step value.
    case (_, _, Absyn.RANGE(start = start, step = NONE(), stop = stop), _, _, _, _, _)
      equation
        (cache, start_exp, DAE.PROP(start_t, start_c), st) =
          elabExpInExpression(inCache, inEnv, start, inImpl, inST, inVect, inPrefix, info);
        (cache, stop_exp, DAE.PROP(stop_t, stop_c), st) =
          elabExpInExpression(cache, inEnv, stop, inImpl, st, inVect, inPrefix, info);
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
          elabExpInExpression(inCache, inEnv, start, inImpl, inST, inVect, inPrefix, info);
        (cache, step_exp, DAE.PROP(step_t, _), st) =
          elabExpInExpression(cache, inEnv, step, inImpl, st, inVect, inPrefix, info);
        (cache, stop_exp, DAE.PROP(stop_t, stop_c), st) =
          elabExpInExpression(cache, inEnv, stop, inImpl, st, inVect, inPrefix, info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inStart;
  input Option<DAE.Exp> inStep;
  input DAE.Exp inStop;
  input DAE.Type inType;
  input DAE.Type inExpType;
  input DAE.Const co;
  input Boolean inImpl;
  output FCore.Cache outCache;
  output DAE.Type outType;
algorithm
  (outCache, outType) := matchcontinue(inCache, inEnv, inStart, inStep, inStop, inType,
      inExpType, co, inImpl)
    local
      DAE.Exp step_exp;
      Values.Value start_val, step_val, stop_val;
      Integer dim;
      FCore.Cache cache;

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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp e;
      list<Absyn.Exp> exps;
      Boolean impl;
      FCore.Cache cache;
      Boolean doVect;
      Prefix.Prefix pre;

    case (cache,env,(e :: exps),impl,doVect,pre,_)
      equation
        failure(Absyn.TUPLE(_) = e);
        (cache,e_1,p,_) = elabExp(cache,env, e, impl,NONE(),doVect,pre,info);
        (cache,exps_1,props) = elabTuple(cache,env, exps, impl,doVect,pre,info);
      then
        (cache,(e_1 :: exps_1),(p :: props));

    case (cache,_,{},_,_,_,_) then (cache,{},{});

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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input Option<GlobalScript.SymbolTable> inSymbolTableOption;
  input Boolean inImpl;
  input Boolean inVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outSymbolTableOption;
algorithm
  (outCache,outExp,outProperties,outSymbolTableOption) := match (inCache,inEnv,inExp,inSymbolTableOption,inImpl,inVect,inPrefix,info)
    local
      FCore.Cache cache;
      FCore.Graph env;
      Absyn.ComponentRef cref;
      list<Absyn.Exp> posArgs;
      list<Absyn.NamedArg> namedArgs;
      Option<GlobalScript.SymbolTable> st;
      Boolean impl,doVect;
      Absyn.Path p,p2;
      list<DAE.Exp> args;
      DAE.Type ty;
      DAE.Properties prop_1;
      DAE.Type tty,tty_1;
      Prefix.Prefix pre;
      list<Slot> slots;
      list<DAE.Const> consts;
      DAE.Const c;
      DAE.Exp exp;
      Boolean isFunctionPointer;

    case (cache,env,Absyn.PARTEVALFUNCTION(cref,Absyn.FUNCTIONARGS({},{})),st,impl,_,pre,_)
      equation
        (cache,exp,prop_1,st) = elabExpInExpression(cache, env, Absyn.CREF(cref), impl, st, inVect, pre, info);
      then (cache,exp,prop_1,st);

    case(cache,env,Absyn.PARTEVALFUNCTION(cref,Absyn.FUNCTIONARGS(posArgs,namedArgs)),st,impl,_,pre,_)
      equation
        p = Absyn.crefToPath(cref);
        (cache,{tty}) = Lookup.lookupFunctionsInEnv(cache, env, p, info);
        tty = Types.makeFunctionPolymorphicReference(tty);
        (cache,args,consts,_,tty as DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isFunctionPointer=isFunctionPointer)),_,slots) = elabTypes(cache, env, posArgs, namedArgs, {tty}, true, true, impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), NONE(), pre, info);
        // {p} = Types.getTypeSource(tty);
        (cache, p2) = Inst.makeFullyQualified(cache, env, Util.if_(isFunctionPointer,Absyn.FULLYQUALIFIED(Absyn.IDENT("sin")),p));
        p = Util.if_(isFunctionPointer,p,p2); // RML hacks because it doesn't have if statements
        tty_1 = stripExtraArgsFromType(slots,tty);
        tty_1 = Types.makeFunctionPolymorphicReference(tty_1);
        ty = Types.simplifyType(tty_1);
        c = List.fold(consts,Types.constAnd,DAE.C_CONST());
        prop_1 = DAE.PROP(tty_1,c);
        (cache,Util.SUCCESS()) = instantiateDaeFunction(cache, env, p2, false, NONE(), true);
        tty = Types.simplifyType(tty);
      then
        (cache,DAE.PARTEVALFUNCTION(p,args,ty,tty),prop_1,st);

  end match;
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
        args = stripExtraArgsFromType2(slots, args, {});
      then
        DAE.T_FUNCTION(args,resType,functionAttributes,ts);

    else
      equation
        Debug.fprintln(Flags.FAILTRACE,"- Static.stripExtraArgsFromType failed");
      then
        fail();
  end matchcontinue;
end stripExtraArgsFromType;

protected function stripExtraArgsFromType2
  input list<Slot> inSlots;
  input list<DAE.FuncArg> inType;
  input list<DAE.FuncArg> inAccumType;
  output list<DAE.FuncArg> outType;
algorithm
  outType := match(inSlots, inType, inAccumType)
    local
      list<Slot> slotsRest;
      list<DAE.FuncArg> rest;
      DAE.FuncArg arg;

    case (SLOT(slotFilled = true) :: slotsRest, _ :: rest, _)
      then stripExtraArgsFromType2(slotsRest, rest, inAccumType);

    case (SLOT(slotFilled = false) :: slotsRest, arg :: rest, _)
      then stripExtraArgsFromType2(slotsRest, rest, arg :: inAccumType);

    case ({}, {}, _) then listReverse(inAccumType);
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

    // Array contains mixed Integer and Real types
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

    case (DAE.PROP(tp,_) :: _)
      equation
        true = Types.isInteger(tp);
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
        true = Types.isReal(tp);
      then tp;

    case ((_ :: rest))
      equation
        tp = elabArrayFirstPropsReal(rest);
      then tp;

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

    case ({DAE.PROP(type_ = _,constFlag = c)}) then c;

    case ((DAE.PROP(constFlag = c1) :: rest))
      equation
        c2 = elabArrayConst(rest);
        c = Types.constAnd(c2, c1);
      then
        c;

    else equation Debug.fprint(Flags.FAILTRACE, "-elabArrayConst failed\n"); then fail();
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
      Boolean knownSingleton;
      Absyn.Path p;

    case ({}, {}, _, _)
      then ({}, DAE.PROP(DAE.T_REAL_DEFAULT, DAE.C_CONST()));

    case ({e_1},{prop},_,_) then ({e_1},prop);

    case (e_1::es_1,DAE.PROP(t1,c1)::props,_,_)
      equation
        (es_1,DAE.PROP(t2,c2)) = elabArray2(es_1,props,pre,info);
        t1 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t1);
        t2 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t2);
        true = Types.equivtypes(t1, t2);
        c = Types.constAnd(c1, c2);
      then
        ((e_1 :: es_1),DAE.PROP(t1,c));

    case (e_1::es_1,DAE.PROP(t1,c1)::props,_,_)
      equation
        (es_1,DAE.PROP(t2,c2)) = elabArray2(es_1,props,pre,info);
        t1 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t1);
        t2 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t2);
        (e_1,t2) = Types.matchType(e_1, t1, t2, false);
        c = Types.constAnd(c1, c2);
      then
        ((e_1 :: es_1),DAE.PROP(t2,c));

    case (e_1::es_1,DAE.PROP(t1,_)::props,_,_)
      equation
        (es_1,DAE.PROP(t2,_)) = elabArray2(es_1,props,pre,info);
        t1 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t1);
        false = Types.equivtypes(t1, t2);
        sp = PrefixUtil.printPrefixStr3(pre);
        e_str = ExpressionDump.printExpStr(e_1);
        strs = List.map(es, ExpressionDump.printExpStr);
        str = stringDelimitList(strs, ",");
        elt_str = stringAppendList({"[",str,"]"});
        t1_str = Types.unparseTypeNoAttr(t1);
        t2_str = Types.unparseTypeNoAttr(t2);
        Types.typeErrorSanityCheck(t1_str, t2_str, info);
        Error.addSourceMessage(Error.TYPE_MISMATCH_ARRAY_EXP, {sp,e_str,t1_str,elt_str,t2_str}, info);
      then
        fail();
  end matchcontinue;
end elabArray2;

protected function elabGraphicsArray
"This function elaborates array expressions for graphics elaboration."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output list<DAE.Exp> outExpExpLst;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExpExpLst,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inPrefix,info)
    local
      DAE.Exp e_1;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.Exp e;
      Boolean impl;
      DAE.Type t1,t2;
      DAE.Const c1,c2,c;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es;
      FCore.Cache cache;
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
        (cache,es_1,DAE.PROP(_,c2)) = elabGraphicsArray(cache,env, es, impl,pre,info);
        c = Types.constAnd(c1, c2);
      then
        (cache,(e_1 :: es_1),DAE.PROP(t1,c));
    case (_,env,{},_,pre,_)
      equation
        envStr = FGraph.printGraphPathStr(env);
        preStr = PrefixUtil.printPrefixStr(pre);
        str = "Static.elabGraphicsArray failed on an empty modification with prefix: " +& preStr +& " in scope: " +& envStr;
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();
    case (_,env,e::_,_,pre,_)
      equation
        envStr = FGraph.printGraphPathStr(env);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv1;
  input list<DAE.Exp> es;
  input list<DAE.Properties> inProps;
  input Boolean inBoolean3;
  input Option<GlobalScript.SymbolTable> inST4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp1;
  output DAE.Properties outProperties2;
  output DAE.Dimension outInteger3;
  output DAE.Dimension outInteger4;
algorithm
  (outCache,outExp1,outProperties2,outInteger3,outInteger4):=
  matchcontinue (inCache,inEnv1,es,inProps,inBoolean3,inST4,inBoolean5,inInteger6,performVectorization,inPrefix,info)
    local
      DAE.Exp el_1,el_2;
      DAE.Properties prop,prop1,prop1_1,prop2;
      DAE.Type t1,t1_1;
      Integer nmax;
      DAE.Dimension t1_dim1_1,t1_dim2_1,dim1,dim2,dim2_1;
      Boolean impl,havereal,a,doVect;
      DAE.Type at;
      FCore.Graph env;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Exp> els_1,els;
      FCore.Cache cache;
      Prefix.Prefix pre;
      list<DAE.Properties> props;

    case (cache,_,{el_1},{prop as DAE.PROP(_,_)},_,_,_,nmax,_,_,_) /* implicit inst. have real nmax dim1 dim2 */
      equation
        (el_2,(prop1 as DAE.PROP(t1_1,_))) = promoteExp(el_1, prop, nmax);
        (_,t1_dim1_1 :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        at = Types.simplifyType(t1_1);
        at = Expression.liftArrayLeft(at, DAE.DIM_INTEGER(1));
      then
        (cache,DAE.ARRAY(at,false,{el_2}),prop1,t1_dim1_1,t1_dim2_1);
    case (cache,env,(el_1 :: els),(prop1 as DAE.PROP(_,_))::props,impl,st,havereal,nmax,doVect,pre,_)
      equation
        (el_2,(prop1_1 as DAE.PROP(t1_1,_))) = promoteExp(el_1, prop1, nmax);
         (_,_ :: (t1_dim2_1 :: _)) = Types.flattenArrayTypeOpt(t1_1);
        (cache,el_1 as DAE.ARRAY(_,_,_),prop2,dim1,dim2) = elabMatrixComma(cache,env, els, props, impl, st, havereal, nmax,doVect,pre,info);
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
        expl = ExpressionSimplify.simplifyList(expl, {});
        expl = List.map(expl, Expression.matrixToArray);
        res = elabMatrixCatTwo(expl);
      then
        res;
    else
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
        res = Expression.makePureBuiltinCall("cat", DAE.ICONST(2) :: expl, tp);
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
    case (DAE.ARRAY(ty = _,scalar = at1,array = expl1),DAE.ARRAY(ty = _,scalar = _,array = expl2))
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
          (DAE.ARRAY(ty = a2,scalar = _,array = expl2) :: es2))
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
        res = Expression.makePureBuiltinCall("cat", DAE.ICONST(1) :: inExpLst, ty);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv1;
  input list<list<DAE.Exp>> expss;
  input list<list<DAE.Properties>> inPropss;
  input Boolean inBoolean3;
  input Option<GlobalScript.SymbolTable> inST4;
  input Boolean inBoolean5;
  input Integer inInteger6;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp1;
  output DAE.Properties outProperties2;
  output DAE.Dimension outInteger3;
  output DAE.Dimension outInteger4;
algorithm
  (outCache,outExp1,outProperties2,outInteger3,outInteger4) :=
  matchcontinue (inCache,inEnv1,expss,inPropss,inBoolean3,inST4,inBoolean5,inInteger6,performVectorization,inPrefix,info)
    local
      DAE.Exp exp,el_1,el_2;
      DAE.Properties prop,prop1,prop2;
      DAE.Type t1,t2;
      Integer maxn,dim;
      DAE.Dimension dim1,dim2,dim1_1,dim2_1,dim1_2;
      Boolean impl,havereal;
      FCore.Graph env;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Exp> els;
      list<list<DAE.Exp>> elss;
      String el_str,t1_str,t2_str,dim1_str,dim2_str,el_str1,pre_str;
      FCore.Cache cache;
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
        _ = listLength((els :: elss));
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
        t1_str = Types.unparseTypeNoAttr(t1);
        t2_str = Types.unparseTypeNoAttr(t2);
        Types.typeErrorSanityCheck(t1_str, t2_str, info);
        Error.addSourceMessage(Error.TYPE_MISMATCH_MATRIX_EXP, {pre_str,el_str,t1_str,t2_str}, info);
      then
        fail();
    case (cache,env,(els :: elss),props::propss,impl,st,havereal,maxn,doVect,pre,_)
      equation
        (cache,_,DAE.PROP(_,_),dim1,_) = elabMatrixComma(cache,env, els, props, impl, st, havereal, maxn,doVect,pre,info);
        (cache,_,_,_,dim2) = elabMatrixSemi(cache,env, elss, propss, impl, st, havereal, maxn,doVect,pre,info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean impl;
  input extraFunc typeChecker;
  input String fnName;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Cache cache;
      FCore.Graph env;

    case (cache,env,{s1},_,_,_,pre,_) /* impl */
      equation
        (cache,_,DAE.PROP(ty,_),_) = elabExpInExpression(cache, env, s1, impl,NONE(),true,pre,info);
        // verify type here to see that input arguments are okay.
        ty2 = Types.arrayElementType(ty);
        true = typeChecker(ty2);
        (cache,s1_1,(prop as DAE.PROP(_,_))) = elabCallArgs(cache,env, Absyn.FULLYQUALIFIED(Absyn.IDENT(fnName)), {s1}, {}, impl,NONE(),pre,info);
      then
        (cache,s1_1,prop);
  end match;
end verifyBuiltInHandlerType;

protected function elabBuiltinCardinality
"author: PA
  This function elaborates the cardinality operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.Type tp1;
      FCore.Graph env;
      Absyn.Exp exp;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;

    case (cache, env, {exp}, _, impl, pre, _)
      equation
        (cache, exp_1, DAE.PROP(tp1, _), _) =
          elabExpInExpression(cache, env, exp, impl, NONE(), true, pre, info);
        tp1 = Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, Types.getDimensions(tp1));
        exp_1 = Expression.makePureBuiltinCall("cardinality", {exp_1}, tp1);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp p_1,expr_1,exp;
      DAE.Const c1,c;
      Boolean impl,b1,b2;
      DAE.Type tp,tp1;
      FCore.Graph env;
      Absyn.Exp p,expr;
      list<Absyn.Exp> expl;
      FCore.Cache cache;
      DAE.Type etp;
      String s1,a1,a2,sp;
      Integer pInt;
      Prefix.Prefix pre;

    case (cache,env,{p,expr},_,impl,pre,_)
      equation
        (cache,p_1,DAE.PROP(tp1,c1),_) = elabExpInExpression(cache,env, p, impl,NONE(),true,pre,info);
        true = Types.isParameterOrConstant(c1);
        true = Types.isInteger(tp1);
        (cache,expr_1,DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, expr, impl,NONE(),true,pre,info);
        b1 = Types.isReal(tp);
        b2 = Types.isRecordWithOnlyReals(tp);
        true = Util.boolOrList({b1,b2});
        etp = Types.simplifyType(tp);
        exp = Expression.makePureBuiltinCall("smooth", {p_1, expr_1}, etp);
      then
        (cache,exp,DAE.PROP(tp,c));

    case (cache,env,{p,expr},_,impl,pre,_)
      equation
        (cache,_,DAE.PROP(tp1,c1),_) = elabExpInExpression(cache,env, p, impl,NONE(),true,pre,info);
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
        (cache,_,DAE.PROP(_,c1),_) = elabExpInExpression(cache,env, p, impl,NONE(),true,pre,info);
        true = Types.isParameterOrConstant(c1);
        (cache,_,DAE.PROP(tp,_),_) = elabExpInExpression(cache,env, expr, impl,NONE(),true,pre,info);
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

    case (_,_,expl,_,_,pre,_)
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
  expressions and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp dimp,arraycrefe,exp;
      DAE.Type arrtp;
      DAE.Properties prop;
      Boolean impl;
      FCore.Graph env;
      Absyn.Exp arraycr,dim;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Type ety;
      DAE.Dimensions dims;

    case (cache, env, {arraycr, dim}, _, impl, pre, _)
      equation
        (cache, dimp, _, _) =
          elabExpInExpression(cache, env, dim, impl, NONE(), true, pre, info);
        (cache, arraycrefe, prop, _) =
          elabExpInExpression(cache, env, arraycr, impl, NONE(), false, pre, info);
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
          elabExpInExpression(cache, env, arraycr, impl, NONE(), false, pre, info);
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
  input FCore.Graph inEnv;
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
        exp = Expression.dimensionSizeConstantExp(dim);
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
        cnst = Util.if_(FGraph.inFunctionScope(inEnv), DAE.C_VAR(), cnst);
        prop = DAE.PROP(DAE.T_INTEGER_DEFAULT, cnst);
      then
        (SOME(exp), SOME(prop));

  end matchcontinue;
end elabBuiltinSizeIndex;

protected function elabBuiltinNDims
"@author Stefan Vorkoetter <svorkoetter@maplesoft.com>
 ndims(A) : Returns the number of dimensions k of array expression A, with k >= 0.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp arraycrefe,exp;
      DAE.Type arrtp;
      Boolean impl;
      FCore.Graph env;
      Absyn.Exp arraycr;
      FCore.Cache cache;
      list<Absyn.Exp> expl;
      Integer nd;
      Prefix.Prefix pre;
      String sp;

    case (cache,env,{arraycr},_,impl,pre,_)
      equation
        (cache,_,DAE.PROP(arrtp,_),_) = elabExpInExpression(cache,env, arraycr, impl,NONE(),true,pre,info);
        nd = Types.numberOfDimensions(arrtp);
        exp = DAE.ICONST(nd);
      then
        (cache,exp,DAE.PROP(DAE.T_INTEGER_DEFAULT,DAE.C_CONST()));

    case (_,_,expl,_,_,pre,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        sp = PrefixUtil.printPrefixStr3(pre);
        Debug.fprint(Flags.FAILTRACE, "- Static.elabBuiltinNdims failed for: ndims(" +& Dump.printExpLstStr(expl) +& " in component: " +& sp);
      then
        fail();
  end matchcontinue;
end elabBuiltinNDims;

protected function elabBuiltinFill "This function elaborates the builtin operator fill.
  The input is the arguments to fill as Absyn.Exp expressions and the environment FCore.Graph"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp s;
      list<Absyn.Exp> dims;
      Boolean impl;
      String implstr,expstr,str,sp;
      list<String> expstrs;
      FCore.Cache cache;
      DAE.Const c1;
      Prefix.Prefix pre;
      DAE.Type exp_type;

    // try to constant evaluate dimensions
    case (cache,env,(s :: dims),_,impl,pre,_)
      equation
        (cache,s_1,prop,_) = elabExpInExpression(cache, env, s, impl,NONE(), true, pre, info);
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
        (cache, s_1, prop, _) = elabExpInExpression(cache, env, s, impl,NONE(), true, pre, info);
        (cache, dims_1, dimprops, _) = elabExpList(cache, env, dims, impl, NONE(), true, pre, info);
        (dims_1,_) = Types.matchTypes(dims_1, List.map(dimprops,Types.getPropType), DAE.T_INTEGER_DEFAULT, false);
        sty = Types.getPropType(prop);
        sty = Types.liftArrayListExp(sty, dims_1);
        exp_type = Types.simplifyType(sty);
        prop = DAE.PROP(sty, c1);
        exp = Expression.makePureBuiltinCall("fill", s_1 :: dims_1, exp_type);
     then
       (cache, exp, prop);

    // Non-constant dimensons are also allowed in the case of non-expanded arrays
    // TODO: check that the diemnsions are parametric?
    case (cache, env, (s :: dims), _, impl, pre, _)
      equation
        false = Config.splitArrays();
        (cache, s_1, DAE.PROP(sty, c1), _) = elabExpInExpression(cache, env, s, impl,NONE(), true, pre, info);
        (cache, dims_1, dimprops, _) = elabExpList(cache, env, dims, impl,NONE(), true, pre, info);
        sty = Types.liftArrayListExp(sty, dims_1);
        exp_type = Types.simplifyType(sty);
        c1 = Types.constAnd(c1, DAE.C_PARAM());
        prop = DAE.PROP(sty, c1);
        exp = Expression.makePureBuiltinCall("fill", s_1 :: dims_1, exp_type);
     then
       (cache, exp, prop);

    case (_,env,dims,_,_,_,_)
      equation
        str = "Static.elabBuiltinFill failed in component" +& PrefixUtil.printPrefixStr3(inPrefix) +&
              " and scope: " +& FGraph.printGraphPathStr(env) +&
              " for expression: fill(" +& Dump.printExpLstStr(dims) +& ")";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();

    case (_,_,dims,_,impl,pre,_)
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input DAE.Type inType;
  input list<Values.Value> inValuesValueLst;
  input DAE.Const constVar;
  input Prefix.Prefix inPrefix;
  input list<Absyn.Exp> inDims;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inExp,inType,inValuesValueLst,constVar,inPrefix,inDims,inInfo)
    local
      list<DAE.Exp> arraylist;
      DAE.Type at;
      Boolean a;
      FCore.Graph env;
      DAE.Exp s,exp;
      DAE.Type sty,ty,sty2;
      Integer v;
      DAE.Const con;
      list<Values.Value> rest;
      FCore.Cache cache;
      DAE.Const c1;
      Prefix.Prefix pre;
      String str;

    // we might get here negative integers!
    case (cache,_,s,sty,{Values.INTEGER(integer = v)},c1,_,_,_)
      equation
        true = intLt(v, 0); // fill with 0 then!
        v = 0;
        arraylist = List.fill(s, v);
        sty2 = DAE.T_ARRAY(sty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2, {});
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    case (cache,_,s,sty,{Values.INTEGER(integer = v)},c1,_,_,_)
      equation
        arraylist = List.fill(s, v);
        sty2 = DAE.T_ARRAY(sty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2, {});
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    case (cache,env,s,sty,(Values.INTEGER(integer = v) :: rest),c1,pre,_,_)
      equation
        (cache,exp,DAE.PROP(ty,_)) = elabBuiltinFill2(cache,env, s, sty, rest,c1,pre,inDims,inInfo);
        arraylist = List.fill(exp, v);
        sty2 = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(v)}, DAE.emptyTypeSource);
        at = Types.simplifyType(sty2);
        a = Types.isArray(sty2, {});
      then
        (cache,DAE.ARRAY(at,a,arraylist),DAE.PROP(sty2,c1));

    case (_,env,_,_,_,_,_,_,_)
      equation
        str = "Static.elabBuiltinFill2 failed in component" +& PrefixUtil.printPrefixStr3(inPrefix) +&
              " and scope: " +& FGraph.printGraphPathStr(env) +&
              " for expression: fill(" +& Dump.printExpLstStr(inDims) +& ")";
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, inInfo);
      then
        fail();
  end matchcontinue;
end elabBuiltinFill2;

protected function elabBuiltinSymmetric "This function elaborates the builtin operator symmetric"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp matexp;
      DAE.Exp exp_1,exp;
      FCore.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,{matexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(DAE.T_ARRAY(dims = {d1}, ty = DAE.T_ARRAY(dims = {d2}, ty = eltp)), c),_)
          = elabExpInExpression(cache,env, matexp, impl,NONE(),true,pre,info);
        newtp = DAE.T_ARRAY(DAE.T_ARRAY(eltp, {d1}, DAE.emptyTypeSource), {d2}, DAE.emptyTypeSource);
        tp = Types.simplifyType(newtp);
        exp = Expression.makePureBuiltinCall("symmetric", {exp_1}, tp);
        prop = DAE.PROP(newtp,c);
      then
        (cache,exp,prop);
  end match;
end elabBuiltinSymmetric;

protected function elabBuiltinClassDirectory
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      String str,fileName;

    case (_,_,_,_,_,_,Absyn.INFO(fileName=fileName))
      equation
        str = stringAppend(System.dirname(fileName),"/");
        Error.addSourceMessage(Error.NON_STANDARD_OPERATOR_CLASS_DIRECTORY, {}, info);
      then
        (inCache,DAE.SCONST(str),DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST()));
  end match;
end elabBuiltinClassDirectory;

protected function elabBuiltinTranspose
  "Elaborates the builtin operator transpose."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inPosArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
protected
  FCore.Cache cache;
  Absyn.Exp aexp;
  DAE.Exp exp;
  DAE.Type ty, el_ty;
  DAE.Const c;
  DAE.Dimension d1, d2;
  DAE.TypeSource src1, src2;
algorithm
  {aexp} := inPosArgs;
  (outCache, exp, DAE.PROP(ty, c), _) :=
    elabExpInExpression(inCache, inEnv, aexp, inImpl, NONE(), true, inPrefix, inInfo);
  // Transpose the type.
  DAE.T_ARRAY(DAE.T_ARRAY(el_ty, {d1}, src1), {d2}, src2) := ty;
  ty := DAE.T_ARRAY(DAE.T_ARRAY(el_ty, {d2}, src1), {d1}, src2);
  outProperties := DAE.PROP(ty, c);
  // Simplify the type and make a call to transpose.
  ty := Types.simplifyType(ty);
  outExp := Expression.makePureBuiltinCall("transpose", {exp}, ty);
end elabBuiltinTranspose;

protected function elabBuiltinSum "This function elaborates the builtin operator sum.
  The input is the arguments to fill as Absyn.Exp expressions and the environment FCore.Graph"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1,exp_2;
      DAE.Type t,tp;
      DAE.Const c;
      FCore.Graph env;
      Absyn.Exp arrexp;
      Boolean impl,b;
      FCore.Cache cache;
      Prefix.Prefix pre;
      String estr,tstr;
      DAE.Type etp;

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(t,c),_) = elabExpInExpression(cache,env,arrexp, impl,NONE(),true,pre,info);
        tp = Types.arrayElementType(t);
        etp = Types.simplifyType(tp);
        b = Types.isArray(t,{});
        b = b and Types.isSimpleType(tp);
        estr = Dump.printExpStr(arrexp);
        tstr = Types.unparseType(t);
        Error.assertionOrAddSourceMessage(b,Error.SUM_EXPECTED_ARRAY,{estr,tstr},info);
        exp_2 = Expression.makePureBuiltinCall("sum", {exp_1}, etp);
      then
        (cache,exp_2,DAE.PROP(tp,c));
  end match;
end elabBuiltinSum;

protected function elabBuiltinProduct "This function elaborates the builtin operator product.
  The input is the arguments to fill as Absyn.Exp expressions and the environment FCore.Graph"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp arrexp;
      Boolean impl;
      DAE.Type ty,ty2;
      FCore.Cache cache;
      Prefix.Prefix pre;
      String str_exp,str_pre;
      DAE.Type etp;

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(ty,c),_) = elabExpInExpression(cache,env, arrexp, impl,NONE(),true,pre,info);
        (exp_1,_) = Types.matchType(exp_1, ty, DAE.T_INTEGER_DEFAULT, true);
        str_exp = "product(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre}, info);
      then
         (cache,exp_1,DAE.PROP(DAE.T_INTEGER_DEFAULT,c));

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(ty,c),_) = elabExpInExpression(cache,env, arrexp, impl,NONE(),true,pre,info);
        (exp_1,_) = Types.matchType(exp_1, ty, DAE.T_REAL_DEFAULT, true);
        str_exp = "product(" +& Dump.printExpStr(arrexp) +& ")";
        str_pre = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.BUILTIN_FUNCTION_PRODUCT_HAS_SCALAR_PARAMETER, {str_exp, str_pre}, info);
      then
         (cache,exp_1,DAE.PROP(DAE.T_REAL_DEFAULT,c));

    case (cache,env,{arrexp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(t as DAE.T_ARRAY(dims = {_}, ty = tp),c),_) = elabExpInExpression(cache,env, arrexp, impl,NONE(),true,pre,info);
        tp = Types.arrayElementType(t);
        etp = Types.simplifyType(tp);
        exp_2 = Expression.makePureBuiltinCall("product", {exp_1}, etp);
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
      DAE.Exp array_exp;
      list<DAE.Exp> expl;

    case DAE.CALL(expLst = {array_exp})
      then Expression.makeProductLst(Expression.arrayElements(array_exp));

    else inExp;
  end matchcontinue;
end elabBuiltinProduct2;

protected function elabBuiltinPre "This function elaborates the builtin operator pre.
  Input is the arguments to the pre operator and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1,exp_2, call;
      DAE.Const c;
      FCore.Graph env;
      Absyn.Exp exp;
      DAE.Dimension dim;
      Boolean impl,sc;
      String s,el_str,pre_str;
      list<Absyn.Exp> expl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Type t,t2,tp;
      DAE.Type etp,etp_org;
      list<DAE.Exp> expl_1;

    /* a matrix? */
    case (cache,env,{exp},_,impl,pre,_) /* impl */
      equation
        (cache,exp_1 as DAE.MATRIX(matrix=_),
         DAE.PROP(t as DAE.T_ARRAY(dims = {_}, ty = tp),c),_) = elabExpInExpression(cache, env, exp, impl,NONE(), true,pre,info);

        true = Types.isArray(tp,{});

        t2 = Types.unliftArray(tp);
        etp = Types.simplifyType(t2);

        call = Expression.makePureBuiltinCall("pre", {exp_1}, etp);
        exp_2 = elabBuiltinPreMatrix(call, t2);
      then
        (cache,exp_2,DAE.PROP(t,c));

    // an array?
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(t as DAE.T_ARRAY(dims = {_}, ty = _),c),_) = elabExpInExpression(cache, env, exp, impl,NONE(),true,pre,info);

        true = Types.isArray(t,{});

        t2 = Types.unliftArray(t);
        etp = Types.simplifyType(t2);

        call = Expression.makePureBuiltinCall("pre", {exp_1}, etp);
        (expl_1,sc) = elabBuiltinPre2(call, t2);

        etp_org = Types.simplifyType(t);
        exp_2 = DAE.ARRAY(etp_org,  sc,  expl_1);
      then
        (cache,exp_2,DAE.PROP(t,c));

    // a scalar?
    case (cache,env,{exp},_,impl,pre,_) /* impl */
      equation
        (cache,exp_1,DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, exp, impl,NONE(),true,pre,info);
        (tp,_) = Types.flattenArrayType(tp);
        true = Types.basicType(tp);
        etp = Types.simplifyType(tp);
        exp_2 = Expression.makePureBuiltinCall("pre", {exp_1}, etp);
      then
        (cache,exp_2,DAE.PROP(tp,c));

    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,exp_1,DAE.PROP(tp,_),_) = elabExpInExpression(cache,env, exp, impl,NONE(),true,pre,info);
        (tp,_) = Types.flattenArrayType(tp);
        false = Types.basicType(tp);
        s = ExpressionDump.printExpStr(exp_1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.OPERAND_BUILTIN_TYPE, {"pre",pre_str,s}, info);
      then
        fail();

    case (_,_,expl,_,_,pre,_)
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

    case(DAE.CALL(expLst = {DAE.ARRAY(_,sc,expl)}),_)
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
  Input is the arguments to the inStream operator and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) :=
  match (inCache, inEnv, inArgs, inNamedArgs, inImpl, inPrefix, inInfo)
    local
      DAE.Exp exp_1, e;
      DAE.Type tp;
      DAE.Const c;
      FCore.Graph env;
      Absyn.Exp exp;
      FCore.Cache cache;
      Absyn.Info info;
      DAE.Properties prop;

    // use elab_call_args to also try vectorized calls
    case (cache, env, {exp}, _, _, _, info)
      equation
        (_, exp_1, DAE.PROP(tp, _),_) = elabExpInExpression(cache, env, exp, inImpl, NONE(), true, inPrefix, info);
        true = Types.dimensionsKnown(tp);
        // check the stream prefix
        _ = elabBuiltinStreamOperator(cache, env, "inStream", exp_1, tp, inInfo);
        (cache, e, prop) = elabCallArgs(cache, env, Absyn.IDENT("inStream"), {exp}, {}, inImpl, NONE(), inPrefix, info);
      then
        (cache, e, prop);

    case (cache, env, {exp as Absyn.CREF(componentRef = _)}, _, _, _, _)
      equation
        (cache, exp_1, DAE.PROP(tp, c), _) = elabExpInExpression(cache, env, exp, inImpl, NONE(), true, inPrefix, inInfo);
        exp_1 = elabBuiltinStreamOperator(cache, env, "inStream", exp_1, tp, inInfo);
      then
        (cache, exp_1, DAE.PROP(tp, c));
  end match;
end elabBuiltinInStream;

protected function elabBuiltinActualStream "This function elaborates the builtin operator actualStream.
  Input is the arguments to the actualStream operator and the environment, FCore.Graph."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      FCore.Cache cache;
      Absyn.Info info;
      DAE.Properties prop;

    // use elab_call_args to also try vectorized calls
    case (cache, env, {exp}, _, _, _, info)
      equation
        (_, exp_1, DAE.PROP(tp, _),_) = elabExpInExpression(cache, env, exp, inImpl, NONE(), true, inPrefix, info);
        true = Types.dimensionsKnown(tp);
        // check the stream prefix
        _ = elabBuiltinStreamOperator(cache, env, "actualStream", exp_1, tp, inInfo);
        (cache, e, prop) = elabCallArgs(cache, env, Absyn.IDENT("actualStream"), {exp}, {}, inImpl, NONE(), inPrefix, info);
      then
        (cache, e, prop);

    case (cache, env, {exp as Absyn.CREF(componentRef = _)}, _, _, _, _)
      equation
        (cache, exp_1, DAE.PROP(tp, c), _) = elabExpInExpression(cache, env, exp, inImpl, NONE(), true, inPrefix, inInfo);
        exp_1 = elabBuiltinStreamOperator(cache, env, "actualStream", exp_1, tp, inInfo);
      then
        (cache, exp_1, DAE.PROP(tp, c));
  end match;
end elabBuiltinActualStream;

protected function elabBuiltinStreamOperator
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
        exp = Expression.makePureBuiltinCall(inOperator, {exp}, et);
      then
        exp;

  end match;
end elabBuiltinStreamOperator;

protected function validateBuiltinStreamOperator
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
        exp_2 = Expression.makePureBuiltinCall("pre", {exp_1}, ttt);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      list<Absyn.Exp> expl;
      FCore.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,expl,_,impl,pre,_)
      equation
        (cache,exp_1,typel,_) = elabExpList(cache,env, expl, impl,NONE(),true,pre,info);
        (_,DAE.PROP(tp,c)) = elabBuiltinArray2(exp_1, typel,pre,info);
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
    case (_,tpl,pre,_)
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp e;
      DAE.Properties p;
      FCore.Graph env;
      list<Absyn.Exp> args;
      Boolean impl;
      FCore.Cache cache;
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
  dims := List.map1(dims, List.delete, dimException);
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
    else false;
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
    else false;
  end matchcontinue;
end sameDimensions3;

protected function elabBuiltinOnes "This function elaborates on the builtin opeator ones(n)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp e;
      DAE.Properties p;
      FCore.Graph env;
      list<Absyn.Exp> args;
      Boolean impl;
      FCore.Cache cache;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inFnArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
 (outCache, outExp, outProperties) :=
    elabBuiltinMinMaxCommon(inCache, inEnv, "max", inFnArgs, inImpl, inPrefix, info);
end elabBuiltinMax;

protected function elabBuiltinMin
  "This function elaborates the builtin operator min(a, b)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inFnArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) :=
    elabBuiltinMinMaxCommon(inCache, inEnv, "min", inFnArgs, inImpl, inPrefix, info);
end elabBuiltinMin;

protected function elabBuiltinMinMaxCommon
  "Helper function to elabBuiltinMin and elabBuiltinMax, containing common
  functionality."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFnName;
  input list<Absyn.Exp> inFnArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp arrexp,s1,s2;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties p;

    // min|max(vector)
    case (cache, env, _, {arrexp}, impl, pre, _)
      equation
        (cache, arrexp_1, DAE.PROP(ty, c), _) =
          elabExpInExpression(cache, env, arrexp, impl,NONE(), true, pre, info);
        true = Types.isArray(ty,{});
        arrexp_1 = Expression.matrixToArray(arrexp_1);
        elt_ty = Types.arrayElementType(ty);
        tp = Types.simplifyType(elt_ty);
        false = Types.isString(tp);
        call = Expression.makePureBuiltinCall(inFnName, {arrexp_1}, tp);
      then
        (cache, call, DAE.PROP(elt_ty,c));

    // min|max(x,y) where x & y are scalars.
    case (cache, env, _, {s1, s2}, impl, pre, _)
      equation
        (cache, s1_1, DAE.PROP(ty1, c1), _) =
          elabExpInExpression(cache, env, s1, impl,NONE(), true, pre, info);
        (cache, s2_1, DAE.PROP(ty2, c2), _) =
          elabExpInExpression(cache, env, s2, impl,NONE(), true, pre, info);

        ty = Types.scalarSuperType(ty1,ty2);
        (s1_1,_) = Types.matchType(s1_1, ty1, ty, true);
        (s2_1,_) = Types.matchType(s2_1, ty2, ty, true);
        c = Types.constAnd(c1, c2);
        tp = Types.simplifyType(ty);
        false = Types.isString(tp);
        call = Expression.makePureBuiltinCall(inFnName, {s1_1, s2_1}, tp);
      then
        (cache, call, DAE.PROP(ty,c));

  end matchcontinue;
end elabBuiltinMinMaxCommon;

protected function elabBuiltinDelay "
Author BZ
TODO: implement,
fix types, so we can have integer as input
verify that the input is correct."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;
      Integer i;

    case (cache,env,_,_,impl,pre,_)
      equation
        i = listLength(args);
        ty1 = DAE.T_FUNCTION(
                {DAE.FUNCARG("expr",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("delayTime",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN,
                DAE.emptyTypeSource);
        ty2 = DAE.T_FUNCTION(
                {DAE.FUNCARG("expr",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("delayTime",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("delayMax",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN,
                DAE.emptyTypeSource);
        ty = Util.if_(i==2,ty1,ty2);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("delay"), args, nargs, impl, NONE(), pre, info);
        call = Expression.traverseExpDummy(call,elabBuiltinDelay2);
      then (cache, call, prop);
  end match;
end elabBuiltinDelay;

protected function elabBuiltinDelay2
  input DAE.Exp exp;
  output DAE.Exp oexp;
algorithm
  oexp := match exp
    local
      Absyn.Path path;
      DAE.Exp e1,e2;
      DAE.CallAttributes attr;
    case DAE.CALL(path as Absyn.IDENT("delay"), {e1,e2}, attr) then DAE.CALL(path, {e1,e2,e2}, attr);
    else exp;
  end match;
end elabBuiltinDelay2;

protected function elabBuiltinClock "
Author: BTH
This function elaborates the builtin Clock constructor Clock(..)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,interval,intervalCounter,resolution,condition,startInterval,c,solverMethod;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop;
      Absyn.Exp ainterval, aintervalCounter, aresolution, acondition, astartInterval, ac, asolverMethod;
      Real rInterval, rStartInterval;
      Integer iIntervalCounter, iResolution;
      DAE.Const variability;

    // Inferred clock "Clock()"
    case (cache,env,{},{},impl,pre,_)
      equation
        ty =  DAE.T_FUNCTION(
                {},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        call = Expression.makeImpureBuiltinCall("Clock", {}, ty);
      then (cache, call, DAE.PROP(DAE.T_CLOCK_DEFAULT, DAE.C_CONST()));

    // clock with Integer interval "Clock(intervalCounter)", intervalCounter variability is C_VAR()
    case (cache,env,{aintervalCounter},{},impl,pre,_)
      equation
        (cache, intervalCounter, prop1, _) = elabExpInExpression(cache,env,aintervalCounter,impl,NONE(),true,pre,info);
        aresolution = Absyn.INTEGER(1);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (intervalCounter,_) = Types.matchType(intervalCounter,ty1,DAE.T_INTEGER_DEFAULT,true);

        variability = Types.getPropConst(prop1);
        true = valueEq(variability,DAE.C_VAR());

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("intervalCounter",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that Clock(intervalCounter) was Clock(intervalCounter,1) (resolution default value)
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               listReverse(aresolution :: args), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // clock with Integer interval "Clock(intervalCounter)"
    case (cache,env,{aintervalCounter},{},impl,pre,_)
      equation
        (cache, intervalCounter, prop1, _) = elabExpInExpression(cache,env,aintervalCounter,impl,NONE(),true,pre,info);
        aresolution = Absyn.INTEGER(1);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (intervalCounter,_) = Types.matchType(intervalCounter,ty1,DAE.T_INTEGER_DEFAULT,true);

        variability = Types.getPropConst(prop1);
        false = valueEq(variability,DAE.C_VAR());
        // check if argument is non-negativ
        iIntervalCounter = Expression.expInt(intervalCounter);
        true = iIntervalCounter >= 0;


        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("intervalCounter",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that Clock(intervalCounter) was Clock(intervalCounter,1) (resolution default value)
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               listReverse(aresolution :: args), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // clock with Integer interval "Clock(intervalCounter, resolution)", , intervalCounter variability is C_VAR()
    case (cache,env,{aintervalCounter, aresolution},{},impl,pre,_)
      equation
        (cache, intervalCounter, prop1, _) = elabExpInExpression(cache,env,aintervalCounter,impl,NONE(),true,pre,info);
        (cache, resolution, prop2, _) = elabExpInExpression(cache,env,aresolution,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        (intervalCounter,_) = Types.matchType(intervalCounter,ty1,DAE.T_INTEGER_DEFAULT,true);
        (resolution,_) = Types.matchType(resolution,ty2,DAE.T_INTEGER_DEFAULT,true);

        variability = Types.getPropConst(prop1);
        true = valueEq(variability,DAE.C_VAR());

        iResolution = Expression.expInt(resolution);
        true = iResolution >= 1;

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("intervalCounter",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // clock with Integer interval "Clock(intervalCounter, resolution)"
    case (cache,env,{aintervalCounter, aresolution},{},impl,pre,_)
      equation
        (cache, intervalCounter, prop1, _) = elabExpInExpression(cache,env,aintervalCounter,impl,NONE(),true,pre,info);
        (cache, resolution, prop2, _) = elabExpInExpression(cache,env,aresolution,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        (intervalCounter,_) = Types.matchType(intervalCounter,ty1,DAE.T_INTEGER_DEFAULT,true);
        (resolution,_) = Types.matchType(resolution,ty2,DAE.T_INTEGER_DEFAULT,true);

        variability = Types.getPropConst(prop1);
        false = valueEq(variability,DAE.C_VAR());

          // check if argument is non-negativ
          iIntervalCounter = Expression.expInt(intervalCounter);
          true = iIntervalCounter >= 0;

        iResolution = Expression.expInt(resolution);
        true = iResolution >= 1;

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("intervalCounter",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);


    // clock with Real interval "Clock(interval)", intervalCounter variability is C_VAR()
    case (cache,env,{ainterval},{},impl,pre,_)
      equation
        (cache, interval, prop1, _) = elabExpInExpression(cache,env,ainterval,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (interval,_) = Types.matchType(interval,ty1,DAE.T_REAL_DEFAULT,true);

        variability = Types.getPropConst(prop1);
        true = valueEq(variability,DAE.C_VAR());

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("interval",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // clock with Real interval "Clock(interval)"
    case (cache,env,{ainterval},{},impl,pre,_)
      equation
        (cache, interval, prop1, _) = elabExpInExpression(cache,env,ainterval,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (interval,_) = Types.matchType(interval,ty1,DAE.T_REAL_DEFAULT,true);

        variability = Types.getPropConst(prop1);
        false = valueEq(variability,DAE.C_VAR());
          // check if argument is non-negativ
          rInterval = Expression.expReal(interval);
          true = rInterval >=. 0.0;

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("interval",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // Boolean Clock (clock triggered by zero-crossing events) "Clock(condition)"
    case (cache,env,{acondition},{},impl,pre,_)
      equation
        (cache, condition, prop1, _) = elabExpInExpression(cache,env,acondition,impl,NONE(),true,pre,info);
        astartInterval = Absyn.REAL("0.0");
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        (condition,_) = Types.matchType(condition,ty1,DAE.T_BOOL_DEFAULT,true);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("condition",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("startInterval",DAE.T_REAL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               listReverse(astartInterval :: args), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // Boolean Clock (clock triggered by zero-crossing events) "Clock(condition, startInterval)"
    case (cache,env,{acondition, astartInterval},{},impl,pre,_)
      equation
        (cache, condition, prop1, _) = elabExpInExpression(cache,env,acondition,impl,NONE(),true,pre,info);
        (cache, startInterval, prop2, _) = elabExpInExpression(cache,env,astartInterval,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        (condition,_) = Types.matchType(condition,ty1,DAE.T_BOOL_DEFAULT,true);
        (startInterval,_) = Types.matchType(startInterval,ty2,DAE.T_REAL_DEFAULT,true);
        rStartInterval = Expression.expReal(startInterval);
        true = rStartInterval >=. 0.0;

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("condition",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("startInterval",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // Solver Clock "Clock(c, solverMethod)"
    case (cache,env,{ac, asolverMethod},{},impl,pre,_)
      equation
        (cache, c, prop1, _) = elabExpInExpression(cache,env,ac,impl,NONE(),true,pre,info);
        (cache, solverMethod, prop2, _) = elabExpInExpression(cache,env,asolverMethod,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        (c,_) = Types.matchType(c,ty1,DAE.T_CLOCK_DEFAULT,true);
        (solverMethod,_) = Types.matchType(solverMethod,ty2,DAE.T_STRING_DEFAULT,true);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("c",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("solverMethod",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_CLOCK_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("Clock"),
               args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

  end matchcontinue;
end elabBuiltinClock;

protected function elabBuiltinPrevious "
Author: BTH
This function elaborates the builtin operator previous(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("previous"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinPrevious;

protected function elabBuiltinHold "
Author: BTH
This function elaborates the builtin operator hold(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("hold"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinHold;

protected function elabBuiltinSample "
Author: BTH
This function elaborates the builtin operator sample(..) variants."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,c,start,interval;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop;
      DAE.Const variability;
      Absyn.Exp au,ac,astart,ainterval;

    // The time event triggering sample(start, interval)
    case (cache,env,{astart,ainterval},{},impl,pre,_)
      equation
        (cache, start, prop1, _) = elabExpInExpression(cache,env,astart,impl,NONE(),true,pre,info);
        (cache, interval, prop2, _) = elabExpInExpression(cache,env,ainterval,impl,NONE(),true,pre,info);
        ty1 = Types.getPropType(prop1);
        ty2 = Types.getPropType(prop2);
        (start,_) = Types.matchType(start,ty1,DAE.T_REAL_DEFAULT,true);
        (interval,_) = Types.matchType(interval,ty2,DAE.T_REAL_DEFAULT,true);
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("start",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("interval",DAE.T_REAL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 DAE.T_BOOL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("sample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    // The sample from the Synchronous Language Elements chapter (Modelica 3.3)
    case (cache,env,{au,ac}, {},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, c, prop2, _) = elabExpInExpression(cache,env,ac,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty2 = Types.arrayElementType(Types.getPropType(prop2));
        variability = Types.getPropConst(prop1);
        (c,_) = Types.matchType(c,ty2,DAE.T_CLOCK_DEFAULT,true);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,variability,DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("c",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),SOME(DAE.CLKCONST(DAE.INFERRED_CLOCK())))},
                ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("sample"),
          args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au}, {},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        variability = Types.getPropConst(prop1);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,variability,DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("c",DAE.T_CLOCK_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),SOME(DAE.CLKCONST(DAE.INFERRED_CLOCK())))},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);

        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("sample"),
          args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);


  end matchcontinue;
end elabBuiltinSample;


protected function elabBuiltinSubSample "
Author: BTH
This function elaborates the builtin operator subSample(u,factor)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,factor;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop;
      Absyn.Exp au,afactor;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        afactor = Absyn.INTEGER(0);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that subSample(x) was subSample(x,0) since "0" is the default value if no argument given
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("subSample"),
               listReverse(afactor :: args), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,afactor},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, factor, prop2, _) = elabExpInExpression(cache,env,afactor,impl,NONE(),true,pre,info);
        (factor,_) = Types.matchType(factor,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(factor) >= 0;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("subSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinSubSample;

protected function elabBuiltinSuperSample "
Author: BTH
This function elaborates the builtin operator superSample(u,factor)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,factor;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop;
      Absyn.Exp au,afactor;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        afactor = Absyn.INTEGER(0);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that superSample(x) was superSample(x,0) since "0" is the default value if no argument given
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("superSample"),
               listReverse(afactor :: args), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,afactor},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, factor, prop2, _) = elabExpInExpression(cache,env,afactor,impl,NONE(),true,pre,info);
        (factor,_) = Types.matchType(factor,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(factor) >= 0;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("factor",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("superSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinSuperSample;

protected function elabBuiltinShiftSample "
Author: BTH
This function elaborates the builtin operator shiftSample(u,shiftCounter,resolution)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,shiftCounter,resolution;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop3,prop;
      Absyn.Exp au,ashiftCounter,aresolution;

    case (cache,env,{au,ashiftCounter},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, shiftCounter, prop2, _) = elabExpInExpression(cache,env,ashiftCounter,impl,NONE(),true,pre,info);
        (shiftCounter,_) = Types.matchType(shiftCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(shiftCounter) >= 0;
        aresolution = Absyn.INTEGER(1);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("shiftCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that shiftSample(u,shiftCounter) was shiftSample(u,shiftCounter,1) (resolution=1 is default value)
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("shiftSample"),
                listAppend(args,{aresolution}), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,ashiftCounter,aresolution},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, shiftCounter, prop2, _) = elabExpInExpression(cache,env,ashiftCounter,impl,NONE(),true,pre,info);
        (shiftCounter,_) = Types.matchType(shiftCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(shiftCounter) >= 0;
        (cache, resolution, prop3, _) = elabExpInExpression(cache,env,aresolution,impl,NONE(),true,pre,info);
        (resolution,_) = Types.matchType(resolution,Types.getPropType(prop3),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(resolution) >= 1;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("shiftCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("shiftSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

  end match;
end elabBuiltinShiftSample;

protected function elabBuiltinBackSample "
Author: BTH
This function elaborates the builtin operator backSample(u,backCounter,resolution)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,u,backCounter,resolution;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop2,prop3,prop;
      Absyn.Exp au,abackCounter,aresolution;

    case (cache,env,{au,abackCounter},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, backCounter, prop2, _) = elabExpInExpression(cache,env,abackCounter,impl,NONE(),true,pre,info);
        (backCounter,_) = Types.matchType(backCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(backCounter) >= 0;
        aresolution = Absyn.INTEGER(1);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("backCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        // Pretend that backSample(u,backCounter) was backSample(u,backCounter,1) (resolution=1 is default value)
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("backSample"),
                listAppend(args, {aresolution}), nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au,abackCounter,aresolution},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        (cache, backCounter, prop2, _) = elabExpInExpression(cache,env,abackCounter,impl,NONE(),true,pre,info);
        (backCounter,_) = Types.matchType(backCounter,Types.getPropType(prop2),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(backCounter) >= 0;
        (cache, resolution, prop3, _) = elabExpInExpression(cache,env,aresolution,impl,NONE(),true,pre,info);
        (resolution,_) = Types.matchType(resolution,Types.getPropType(prop3),DAE.T_INTEGER_DEFAULT,true);
        true = Expression.expInt(resolution) >= 1;
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("backCounter",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("resolution",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("backSample"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

  end match;
end elabBuiltinBackSample;

protected function elabBuiltinNoClock "
Author: BTH
This function elaborates the builtin operator noClock(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 ty1,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("noClock"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinNoClock;

protected function elabBuiltinInterval "
Author: BTH
This function elaborates the builtin operator interval(u)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call, u;
      DAE.Type ty1,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1, prop;
      Absyn.Exp au;

    case (cache,env,{},{},impl,pre,_)
      equation
        ty =  DAE.T_FUNCTION(
                {},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("interval"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);

    case (cache,env,{au},{},impl,pre,_)
      equation
        (cache, u, prop1, _) = elabExpInExpression(cache,env,au,impl,NONE(),true,pre,info);
        ty1 = Types.arrayElementType(Types.getPropType(prop1));
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("u",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("interval"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinInterval;

protected function isBlockTypeWorkaround "
Author: BTH
Helper function to elabBuiltinTransition.
This function checks whether a type is complex.
It is used as a workaround to check for block instances in elabBuiltinTransition, elabBultinActiveState and elabBuiltinInitalState.
This is not perfect since there are also other instances that are 'complex' types which are not block instances.
But allowing more might not be so bad anyway, since the MLS 3.3 restriction to block seems more restrictive than necessary,
e.g., one can be more lenient and allow models as states, too..."
  input DAE.Type ity;
  output Boolean b;
algorithm
  b := matchcontinue(ity)
    local DAE.Type ty;
    case (DAE.T_SUBTYPE_BASIC(complexType = ty)) then isBlockTypeWorkaround(ty);
    case (DAE.T_COMPLEX(varLst = _)) then true;
    else false;
  end matchcontinue;
end isBlockTypeWorkaround;

protected function elabBuiltinTransition "
Author: BTH
This function elaborates the builtin operator
transition(from, to, condition, immediate=true, reset=true, synchronize=false, priority=1)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty1,ty2,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;
      Integer n, nFrom;
      String strMsg0,strPre,s1,s2;
      list<String> slist;

    case (cache,env,_,_,impl,pre,_)
      equation
        slist = List.map(nargs,Dump.printNamedArgStr);
        s1 = Dump.printExpLstStr(args);
        s2 = stringDelimitList(s1 :: slist, ", ");
        strMsg0 = "transition(" +& s2 +& ")";
        strPre = PrefixUtil.printPrefixStr3(pre);
        n = listLength(args);

        // Check if "from" and "to" arguments are of complex type and return their type
        ty1 = elabBuiltinTransition2(cache, env, args, nargs, impl, pre, info, "from", n, strMsg0, strPre);
        ty2 = elabBuiltinTransition2(cache, env, args, nargs, impl, pre, info, "to", n, strMsg0, strPre);

        // Alternatively, ty1 and ty2 could be replaced by DAE.T_CODE(DAE.C_VARIABLENAME,{}), not sure if that would be a better solution
        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("from",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("to",ty2,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("condition",DAE.T_BOOL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),
                 DAE.FUNCARG("immediate",DAE.T_BOOL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.BCONST(true))),
                 DAE.FUNCARG("reset",DAE.T_BOOL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.BCONST(true))),
                 DAE.FUNCARG("synchronize",DAE.T_BOOL_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.BCONST(false))),
                 DAE.FUNCARG("priority",DAE.T_INTEGER_DEFAULT,DAE.C_PARAM(),DAE.NON_PARALLEL(),SOME(DAE.ICONST(1)))},
                 DAE.T_NORETCALL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("transition"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinTransition;

protected function elabBuiltinTransition2 "
Author: BTH
Helper function to elabBuiltinTransition.
Check if the \"from\" argument or the \"to\" argument is of complex type."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Absyn.Ident argName;
  input Integer n;
  input String strMsg0;
  input String strPre;
  output DAE.Type ty;
protected
  Absyn.Exp arg1;
  DAE.Properties prop1;
  Integer nPos;
  String s1,s2,strPos,strMsg1;
  Boolean b1;
algorithm
  strPos := Util.if_(argName ==& "from", "first", "second");
  nPos := Util.if_(argName ==& "from", 1, 2);
  b1 := List.isMemberOnTrue(argName, nargs, elabBuiltinTransition3);

  s1 := strMsg0 +& ", named argument \"" +& argName +& "\" already has a value.";
  Error.assertionOrAddSourceMessage(not (b1 and n >= nPos),Error.WRONG_TYPE_OR_NO_OF_ARGS,
    {s1, strPre}, info);

  s2 := strMsg0 +& ", missing value for " +& strPos +& " argument \"" +& argName +& "\".";
  Error.assertionOrAddSourceMessage(b1 or n >= nPos, Error.WRONG_TYPE_OR_NO_OF_ARGS,
      {s2, strPre}, info);

  arg1 := elabBuiltinTransition5(argName, b1, args, nargs);
  (_, _, prop1, _) := elabExpInExpression(inCache,inEnv,arg1,inBoolean,NONE(),true,inPrefix,info);
  ty := Types.getPropType(prop1);
  strMsg1 := strMsg0 +& ", " +& strPos +& "argument needs to be a block instance.";
  Error.assertionOrAddSourceMessage(isBlockTypeWorkaround(ty),Error.WRONG_TYPE_OR_NO_OF_ARGS,
  {strMsg1, strPre}, info);

end elabBuiltinTransition2;


protected function elabBuiltinTransition3 "
Author: BTH
Helper function to elabBuiltinTransition.
Checks if namedArg.argName == name"
  input Absyn.Ident name;
  input Absyn.NamedArg namedArg;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match (name, namedArg)
    local
      Absyn.Ident argName;
      Absyn.Exp argValue;

    case (_, Absyn.NAMEDARG(argName=argName))
      then stringEq(name, argName);

    else false;
  end match;
end elabBuiltinTransition3;

protected function elabBuiltinTransition4 "
Author: BTH
Helper function to elabBuiltinTransition.
Extract element argValue."
  input Absyn.NamedArg inElement;
  output Absyn.Exp argValue;
algorithm
  argValue := match (inElement)
    local
      Absyn.Exp argValue1;
    case (Absyn.NAMEDARG(argValue = argValue1))
      then argValue1;
  end match;
end elabBuiltinTransition4;

protected function elabBuiltinTransition5 "
Author: BTH
Helper function to elabBuiltinTransition."
  input String argName;
  input Boolean getAsNamedArg;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  output Absyn.Exp argValue;
algorithm
  argValue := match (argName, getAsNamedArg, args, nargs)
  local
      Absyn.NamedArg namedArg;
    case ("from", true, _, _)
      equation
        namedArg = List.getMemberOnTrue("from", nargs, elabBuiltinTransition3);
      then elabBuiltinTransition4(namedArg);
    case ("from", false, _, _)
      then listGet(args, 1);
    case ("to", true, _, _)
      equation
        namedArg = List.getMemberOnTrue("to", nargs, elabBuiltinTransition3);
      then elabBuiltinTransition4(namedArg);
    case ("to", false, _, _)
      then listGet(args, 2);
  end match;
end elabBuiltinTransition5;

protected function elabBuiltinInitialState "
Author: BTH
This function elaborates the builtin operator
initialState(state)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,state;
      DAE.Type ty1,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop;
      Absyn.Exp astate;
      String strMsg, strPre;

    case (cache,env,{astate},{},impl,pre,_)
      equation
        (cache, state, prop1, _) = elabExpInExpression(cache,env,astate,impl,NONE(),true,pre,info);
        ty1 = Types.getPropType(prop1);
        strMsg = "initialState(" +& Dump.printExpLstStr(args) +& "), Argument needs to be a block instance.";
        strPre = PrefixUtil.printPrefixStr3(pre);
        Error.assertionOrAddSourceMessage(isBlockTypeWorkaround(ty1),Error.WRONG_TYPE_OR_NO_OF_ARGS,
          {strMsg, strPre}, info);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("state",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 DAE.T_NORETCALL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("initialState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinInitialState;

protected function elabBuiltinActiveState "
Author: BTH
This function elaborates the builtin operator
activeState(state)."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call,state;
      DAE.Type ty1,ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop1,prop;
      Absyn.Exp astate;
      String strMsg, strPre;

    case (cache,env,{astate},{},impl,pre,_)
      equation
        (cache, state, prop1, _) = elabExpInExpression(cache,env,astate,impl,NONE(),true,pre,info);
        ty1 = Types.getPropType(prop1);
        strMsg = "activeState(" +& Dump.printExpLstStr(args) +& "), Argument needs to be a block instance.";
        strPre = PrefixUtil.printPrefixStr3(pre);
        Error.assertionOrAddSourceMessage(isBlockTypeWorkaround(ty1), Error.WRONG_TYPE_OR_NO_OF_ARGS,
          {strMsg, strPre}, info);

        ty =  DAE.T_FUNCTION(
                {DAE.FUNCARG("state",ty1,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE())},
                 DAE.T_BOOL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("activeState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinActiveState;

protected function elabBuiltinTicksInState "
Author: BTH
This function elaborates the builtin operator
ticksInState()."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;

    case (cache,env,{},{},impl,pre,_)
      equation
        ty =  DAE.T_FUNCTION(
                {},
                 DAE.T_INTEGER_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("ticksInState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinTicksInState;

protected function elabBuiltinTimeInState "
Author: BTH
This function elaborates the builtin operator
timeInState()."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,args,nargs,inBoolean,inPrefix,info)
    local
      DAE.Exp call;
      DAE.Type ty;
      Boolean impl;
      FCore.Graph env;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Properties prop;

    case (cache,env,{},{},impl,pre,_)
      equation
        ty =  DAE.T_FUNCTION(
                {},
                 DAE.T_REAL_DEFAULT,
                DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE,
                DAE.emptyTypeSource);
        (cache,SOME((call,prop))) = elabCallArgs3(cache, env, {ty}, Absyn.IDENT("timeInState"), args, nargs, impl, NONE(), pre, info);
      then (cache, call, prop);
  end match;
end elabBuiltinTimeInState;

protected function elabBuiltinBoolean
"This function elaborates on the builtin operator boolean, which extracts
  the boolean value of a Real, Integer or Boolean value."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp s1_1;
      FCore.Graph env;
      Absyn.Exp s1;
      Boolean impl;
      FCore.Cache cache;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp s1_1;
      FCore.Graph env;
      Absyn.Exp s1;
      Boolean impl;
      FCore.Cache cache;
      DAE.Properties prop;
      Prefix.Prefix pre;
    case (cache,env,{s1},_,impl,pre,_)
      equation
        (cache,s1_1,prop) = verifyBuiltInHandlerType(cache,env,{s1},impl,Types.isEnumeration,"Integer",pre,info);
      then
        (cache,s1_1,prop);
  end match;
end elabBuiltinIntegerEnum;

protected function elabBuiltinDiagonal "This function elaborates on the builtin operator diagonal, creating a
  matrix with a value of the diagonal. The other elements are zero."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp v1,s1;
      FCore.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,{v1},_,impl,pre,_)
      equation
        (cache, DAE.ARRAY(ty = tp, array = expl),
         DAE.PROP(DAE.T_ARRAY(dims = {dim}, ty = arrType, source = _/*{}*/),c),
         _) = elabExpInExpression(cache,env, v1, impl,NONE(),true,pre,info);
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
         _) = elabExpInExpression(cache,env, s1, impl,NONE(),true, pre,info);
        true = Expression.dimensionKnown(dim);
        ty = DAE.T_ARRAY(DAE.T_ARRAY(arrType, {dim}, DAE.emptyTypeSource), {dim}, DAE.emptyTypeSource);
        tp = Types.simplifyType(ty);
        res = Expression.makePureBuiltinCall("diagonal", {s1_1}, tp);
      then
        (cache, res, DAE.PROP(ty,c));

    else
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

protected function elabBuiltinSimplify "This function elaborates the simplify function.
  The call in mosh is: simplify(x+yx-x,\"Real\") if the variable should be
  Real or simplify(x+yx-x,\"Integer\") if the variable should be Integer
  This function is only for testing ExpressionSimplify.simplify"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      list<Absyn.ComponentRef> cref_list;
      GlobalScript.SymbolTable symbol_table;
      FCore.Graph gen_env,env;
      DAE.Exp s1_1;
      DAE.Properties st;
      Absyn.Exp s1;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
    case (cache,_,{s1,Absyn.STRING(value = "Real")},_,impl,pre,_) /* impl */
      equation
        cref_list = Absyn.getCrefFromExp(s1,true,false);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, GlobalScript.emptySymboltable,
          DAE.T_REAL_DEFAULT);
        (gen_env,_) = GlobalScriptUtil.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExpInExpression(cache,gen_env, s1, impl,NONE(),true,pre,info);
        s1_1 = Expression.makePureBuiltinCall("simplify", {s1_1}, DAE.T_REAL_DEFAULT);
      then
        (cache, s1_1, st);
    case (cache,_,{s1,Absyn.STRING(value = "Integer")},_,impl,pre,_)
      equation
        cref_list = Absyn.getCrefFromExp(s1,true,false);
        symbol_table = absynCrefListToInteractiveVarList(cref_list, GlobalScript.emptySymboltable,
          DAE.T_INTEGER_DEFAULT);
        (gen_env,_) = GlobalScriptUtil.buildEnvFromSymboltable(symbol_table);
        (cache,s1_1,st,_) = elabExpInExpression(cache,gen_env, s1, impl,NONE(),true,pre,info);
        s1_1 = Expression.makePureBuiltinCall("simplify", {s1_1}, DAE.T_INTEGER_DEFAULT);
      then
        (cache, s1_1, st);
    else
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
        symbol_table_1 = GlobalScriptUtil.addVarToSymboltable(
          DAE.CREF_IDENT(path_str, tp, {}),
          Values.CODE(Absyn.C_VARIABLENAME(cr)), FGraph.empty(), symbol_table);
        symbol_table_2 = absynCrefListToInteractiveVarList(rest, symbol_table_1, tp);
      then
        symbol_table_2;
    else
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.Exp exp;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,exp_1,prop,_) = elabExpInExpression(cache,env, exp, impl,NONE(),true,pre,info);
        exp_1 = Expression.makePureBuiltinCall("noEvent", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_1, prop);
  end match;
end elabBuiltinNoevent;

protected function elabBuiltinEdge "
  This function handles the built in edge operator. If the operand is
  constant edge is always false.
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp_1,exp_2;
      FCore.Graph env;
      Absyn.Exp exp;
      Boolean impl;
      DAE.Const c;
      FCore.Cache cache;
      Prefix.Prefix pre;
      String ps;
    case (cache,env,{exp},_,impl,pre,_) /* Constness: C_VAR */
      equation
        (cache,exp_1,DAE.PROP(DAE.T_BOOL(varLst = _),DAE.C_VAR()),_) = elabExpInExpression(cache, env, exp, impl,NONE(),true,pre,info);
        exp_2 = Expression.makePureBuiltinCall("edge", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_2, DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()));

    case (cache,env,{exp},_,impl,pre,_)
      equation
        (cache,_,DAE.PROP(DAE.T_BOOL(varLst = _),c),_) = elabExpInExpression(cache, env, exp, impl,NONE(),true,pre,info);
        exp_2 = ValuesUtil.valueExp(Values.BOOL(false));
      then
        (cache,exp_2,DAE.PROP(DAE.T_BOOL_DEFAULT,c));
    case (_,_,_,_,_,pre,_)
      equation
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {"edge",ps}, info);
      then
        fail();
  end matchcontinue;
end elabBuiltinEdge;

protected function elabBuiltinDer
"This function handles the built in der operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp e,ee1;
      DAE.Properties prop;
      FCore.Graph env;
      Absyn.Exp exp;
      Boolean impl;
      DAE.Const c;
      list<String> lst;
      String s,sp,es3;
      list<Absyn.Exp> expl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      DAE.Type ety,ty,elem_ty;
      DAE.Dimensions dims;
      DAE.Type expty;

    // Replace der of constant Real, Integer or array of Real/Integer by zero(s)
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (_,_,DAE.PROP(ety,c),_) = elabExpInExpression(cache, env, exp, impl,NONE(),false,pre,info);
        failure(equality(c=DAE.C_VAR()));
        dims = Types.getRealOrIntegerDimensions(ety);
        (e,ty) = Expression.makeZeroExpression(dims);
      then
        (cache,e,DAE.PROP(ty,DAE.C_CONST()));

    // use elab_call_args to also try vectorized calls
    case (cache,env,{exp},_,impl,pre,_)
      equation
        (_,_,DAE.PROP(ety,_),_) = elabExpInExpression(cache, env, exp, impl,NONE(),true,pre,info);
        true = Types.dimensionsKnown(ety);
        ety = Types.arrayElementType(ety);
        true = Types.isRealOrSubTypeReal(ety);
        (cache,e,(prop as DAE.PROP(_,_))) = elabCallArgs(cache, env, Absyn.IDENT("der"), {exp}, {}, impl, NONE(), pre, info);
      then
        (cache,e,prop);

    case (cache, env, {exp}, _, impl, pre,_)
      equation
        (cache, e, DAE.PROP(ety, c), _) = elabExpInExpression(cache, env, exp, impl,NONE(), false, pre, info);
        elem_ty = Types.arrayElementType(ety);
        true = Types.isRealOrSubTypeReal(elem_ty);
        expty = Types.simplifyType(ety);
        e = Expression.makePureBuiltinCall("der", {e}, expty);
      then
        (cache, e, DAE.PROP(ety, c));

    case (cache,env,{exp},_,impl,pre,_)
      equation
        (_,_,DAE.PROP(ety,_),_) = elabExpInExpression(cache,env, exp, impl,NONE(),false,pre,info);
        false = Types.isRealOrSubTypeReal(ety);
        s = Dump.printExpStr(exp);
        sp = PrefixUtil.printPrefixStr3(pre);
        es3 = Types.unparseType(ety);
        Error.addSourceMessage(Error.DERIVATIVE_NON_REAL, {s,sp,es3}, info);
      then
        fail();
    case (_,_,expl,_,_,pre,_)
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp;
      DAE.ComponentRef cr_1;
      DAE.Const c;
      DAE.Type tp1;
      FCore.Graph env;
      Absyn.ComponentRef cr;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      String sp;
      DAE.Properties prop;
      Absyn.Exp aexp;

    case (cache,env,{aexp as Absyn.CREF(componentRef = cr)},{},impl,pre,_) /* simple type, constant variability */
      equation
        (cache,exp,prop,_) = elabExpInExpression(cache,env,aexp,impl,NONE(),true,pre,info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef cr;
  input DAE.Exp inExp;
  input DAE.Properties prop;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,cr,inExp,prop,inPrefix,info)
    local
      DAE.Exp exp_1;
      DAE.ComponentRef cr_1;
      DAE.Const c;
      DAE.Type tp1,tp2;
      FCore.Graph env;
      Absyn.Exp exp;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      String sp;
      DAE.Dimensions dims;

    case (cache,_,_,_,DAE.PROP(tp1,c),_,_)
      equation
        Types.simpleType(tp1);
        true = Types.isParameterOrConstant(c);
      then (cache, DAE.BCONST(false), DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_CONST()));

    case (cache,_,_,exp_1,DAE.PROP(tp1,_),_,_)
      equation
        Types.simpleType(tp1);
        Types.discreteType(tp1);
        exp_1 = Expression.makePureBuiltinCall("change", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_1, DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()));

    case (cache,env,_,exp_1,DAE.PROP(tp1,_),_,_) /* workaround for discrete Reals; does not handle Reals that become discrete due to when-section */
      equation
        Types.simpleType(tp1);
        failure(Types.discreteType(tp1));
        cr_1 = Expression.getCrefFromCrefOrAsub(exp_1);
        (cache,DAE.ATTR(variability = SCode.DISCRETE()),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1);
        exp_1 = Expression.makePureBuiltinCall("change", {exp_1}, DAE.T_BOOL_DEFAULT);
      then
        (cache, exp_1, DAE.PROP(DAE.T_BOOL_DEFAULT,DAE.C_VAR()));

    case (cache,env,_,exp_1,DAE.PROP(tp1,_),pre,_)
      equation
        cr_1 = Expression.getCrefFromCrefOrAsub(exp_1);
        Types.simpleType(tp1);
        (cache,_,_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env, cr_1);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.ARGUMENT_MUST_BE_DISCRETE_VAR, {"First","change",sp}, info);
      then fail();

    case (_,_,_,_,DAE.PROP(tp1,_),pre,_)
      equation
        failure(Types.simpleType(tp1));
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.TYPE_MUST_BE_SIMPLE, {"operand to change", sp}, info);
      then fail();
  end matchcontinue;
end elabBuiltinChange2;

protected function elabBuiltinCat "author: PA
  This function handles the built in cat operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      list<Absyn.Exp> matrices;
      list<DAE.Type> tys,tys2;
      Boolean impl;
      DAE.Properties tp;
      list<String> lst;
      String s,str;
      FCore.Cache cache;
      DAE.Type etp;
      Prefix.Prefix pre;
      String sp;
      Absyn.Exp dim_aexp;
      DAE.Dimensions dims;
      DAE.Dimension dim;

    case (cache,env,(dim_aexp :: matrices),_,impl,pre,_) /* impl */
      equation
        // Evaluate the dimension expression and elaborate the rest of the arguments.
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),const1),_) = elabExpInExpression(cache,env, dim_aexp, impl,NONE(),true,pre,info);
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
        exp = Expression.makePureBuiltinCall("cat", dim_exp :: matrices_1, etp);
      then
        (cache,exp,DAE.PROP(result_type_1,const));
    case (cache,env,(dim_aexp :: _),_,impl,pre,_)
      equation
        (cache,_,tp,_) = elabExpInExpression(cache,env, dim_aexp, impl,NONE(),true,pre,info);
        failure(DAE.PROP(DAE.T_INTEGER(varLst = _),_) = tp);
        sp = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.ARGUMENT_MUST_BE_INTEGER, {"First","cat",sp}, info);
      then
        fail();
    case (cache,env,(dim_aexp :: matrices),_,impl,pre,_)
      equation
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),_),_) = elabExpInExpression(cache,env, dim_aexp, impl,NONE(),true,pre,info);
        (cache,Values.INTEGER(dim_int),_) = Ceval.ceval(cache,env, dim_exp, false,NONE(), Absyn.MSG(info),0);
        (cache,_,props,_) = elabExpList(cache,env, matrices, impl,NONE(),true,pre,info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp dim_exp, call;
      Integer size;
      DAE.Dimension dim_size;
      FCore.Graph env;
      Absyn.Exp dim;
      Boolean impl;
      FCore.Cache cache;
      DAE.Type ty;
      DAE.Type ety;
      Prefix.Prefix pre;
      DAE.Const c;
      Absyn.Msg msg;

    case (cache,env,{dim},_,impl,pre,_)
      equation
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),c),_) = elabExpInExpression(cache,env, dim, impl,NONE(),true,pre,info);
        true = Types.isParameterOrConstant(c);
        msg = Util.if_(Flags.getConfigBool(Flags.CHECK_MODEL), Absyn.NO_MSG(), Absyn.MSG(info));
        (cache,Values.INTEGER(size),_) = Ceval.ceval(cache,env, dim_exp, false,NONE(), msg,0);
        dim_size = DAE.DIM_INTEGER(size);
        ty = Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, {dim_size, dim_size});
        ety = Types.simplifyType(ty);
        dim_exp = DAE.ICONST(size);
        call = Expression.makePureBuiltinCall("identity", {dim_exp}, ety);
      then
        (cache, call, DAE.PROP(ty,c));

    case (cache,env,{dim},_,impl,pre,_)
      equation
        (cache,dim_exp,DAE.PROP(DAE.T_INTEGER(varLst = _),c),_) = elabExpInExpression(cache,env,dim,impl,NONE(),true,pre,info);
        ty = Types.liftArrayListDims(DAE.T_INTEGER_DEFAULT, {DAE.DIM_UNKNOWN(), DAE.DIM_UNKNOWN()});
        ety = Types.simplifyType(ty);
        call = Expression.makePureBuiltinCall("identity", {dim_exp}, ety);
      then
        (cache, call, DAE.PROP(ty,c));

  end matchcontinue;
end elabBuiltinIdentity;

protected function zeroSizeOverconstrainedOperator
  input DAE.Exp inExp;
  input DAE.Exp inFExp;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExp, inFExp, inInfo)
    local String s;

    case (DAE.ARRAY(array = {}), _, _)
      equation
        s = ExpressionDump.printExpStr(inFExp);
        Error.addSourceMessage(Error.OVERCONSTRAINED_OPERATOR_SIZE_ZERO_RETURN_FALSE, {s}, inInfo);
      then
        ();

    else ();

  end matchcontinue;
end zeroSizeOverconstrainedOperator;

protected function elabBuiltinIsRoot
"This function elaborates on the builtin operator Connections.isRoot."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      FCore.Graph env;
      FCore.Cache cache;
      Boolean impl;
      Absyn.Exp exp0;
      DAE.Exp exp, fexp;
      Prefix.Prefix pre;

    case (cache,env,{exp0},{},_,pre,_)
      equation
        (cache,exp,_,_) = elabExpInExpression(cache, env, exp0, false, NONE(), false, pre, info);
        fexp = DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), {exp}, DAE.callAttrBuiltinBool);
        zeroSizeOverconstrainedOperator(exp, fexp, info);
      then
        (cache, fexp, DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR()));
  end match;
end elabBuiltinIsRoot;

protected function elabBuiltinRooted
"author: adrpo
  This function handles the built-in rooted operator. (MultiBody).
  See more here: http://trac.modelica.org/Modelica/ticket/95"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      FCore.Graph env;
      FCore.Cache cache;
      Boolean impl;
      Absyn.Exp exp0;
      DAE.Exp exp, fexp;
      Prefix.Prefix pre;

    // this operator is not even specified in the specification! see: http://trac.modelica.org/Modelica/ticket/95
    case (cache,env,{exp0},{},_,pre,_)
      equation
        (cache, exp, _, _) = elabExpInExpression(cache, env, exp0, false,NONE(), false,pre,info);
        fexp = DAE.CALL(Absyn.IDENT("rooted"), {exp}, DAE.callAttrBuiltinBool);
        zeroSizeOverconstrainedOperator(exp, fexp, info);
      then
        (cache, fexp, DAE.PROP(DAE.T_BOOL_DEFAULT, DAE.C_VAR()));
  end match;
end elabBuiltinRooted;

protected function elabBuiltinUniqueRootIndices
"This function elaborates on the builtin operator Connections.uniqueRootIndices.
 TODO: assert size(second arg) <= size(first arg)
 See Modelica_StateGraph2:
  https://github.com/modelica/Modelica_StateGraph2
  and
  https://trac.modelica.org/Modelica/ticket/984
  and
  http://www.ep.liu.se/ecp/043/041/ecp09430108.pdf
 for a specification of this operator"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      FCore.Graph env;
      FCore.Cache cache;
      Boolean impl;
      Absyn.Exp aexp1, aexp2, aexp3;
      DAE.Exp exp1, exp2, exp3;
      Prefix.Prefix pre;
      DAE.Dimensions dims;
      DAE.Properties props;
      list<DAE.Exp> lst;
      Integer dim;
      DAE.Type ty;

    case (cache,env,{aexp1,aexp2},{},_,pre,_)
      equation
        (cache,exp1 as DAE.ARRAY(array = lst),_,_) = elabExpInExpression(cache, env, aexp1, false, NONE(), false, pre, info);
        dim = listLength(lst);
        (cache,exp2,_,_) = elabExpInExpression(cache, env, aexp2, false, NONE(), false, pre, info);
        exp3 = DAE.SCONST("");
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")), {exp1, exp2, exp3},
                 DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),
        DAE.PROP(ty, DAE.C_VAR()));

    case (cache,env,{aexp1,aexp2,aexp3},{},_,pre,_)
      equation
        (cache,exp1 as DAE.ARRAY(array = lst),_,_) = elabExpInExpression(cache, env, aexp1, false, NONE(), false, pre, info);
        dim = listLength(lst);
        (cache,exp2,_,_) = elabExpInExpression(cache, env, aexp2, false, NONE(), false, pre, info);
        (cache,exp3,_,_) = elabExpInExpression(cache, env, aexp2, false, NONE(), false, pre, info);
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")), {exp1, exp2, exp3},
                 DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),
        DAE.PROP(ty, DAE.C_VAR()));

    case (cache,env,{aexp1,aexp2},{Absyn.NAMEDARG("message", aexp3)},_,pre,_)
      equation
        (cache,exp1 as DAE.ARRAY(array = lst),_,_) = elabExpInExpression(cache, env, aexp1, false, NONE(), false, pre, info);
        dim = listLength(lst);
        (cache,exp2,_,_) = elabExpInExpression(cache, env, aexp2, false,NONE(), false,pre,info);
        (cache,exp3,_,_) = elabExpInExpression(cache, env, aexp2, false,NONE(), false,pre,info);
        ty = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(dim)}, DAE.emptyTypeSource);
      then
        (cache,
        DAE.CALL(Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")), {exp1, exp2, exp3},
                 DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),
        DAE.PROP(ty, DAE.C_VAR()));

  end match;
end elabBuiltinUniqueRootIndices;

protected function elabBuiltinScalar "author: PA

  This function handles the built in scalar operator.
  For example, scalar({1}) => 1 or scalar({a}) => a
"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  match (inCache,inEnv,inArgs,inNamedArg,inImpl,inPrefix,inInfo)
    local
      DAE.Exp e;
      DAE.Type tp,scalar_tp;
      DAE.Const c;
      FCore.Graph env;
      FCore.Cache cache;
      Absyn.Exp aexp;
      DAE.Dimensions dims;

    case (cache, env, {aexp}, _, _, _, _)
      equation
        (cache, e, DAE.PROP(tp, c), _) =
          elabExpInExpression(cache, env, aexp, inImpl, NONE(), true, inPrefix, inInfo);
        (scalar_tp,dims) = Types.flattenArrayTypeOpt(tp);
        List.map2_0(dims,checkTypeScalar,tp,inInfo);
        e = Util.if_(List.isEmpty(dims), e, Expression.makePureBuiltinCall("scalar", {e}, scalar_tp));
        (e,_) = ExpressionSimplify.simplify1(e);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp e;
      Boolean impl;
      list<DAE.Exp> args_1;
      FCore.Cache cache;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      list<Slot> slots,newslots;
      Prefix.Prefix pre;

    // handle most of the stuff
    case (cache,env,args as e::_,nargs,impl,pre,_)
      equation
        (cache,exp,DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, e, impl,NONE(),true,pre,info);
        // Create argument slots for String function.
        slots = {SLOT(DAE.FUNCARG("x",tp,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,NONE(),{},1),
                 SLOT(DAE.FUNCARG("minimumLength",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,SOME(DAE.ICONST(0)),{},2),
                 SLOT(DAE.FUNCARG("leftJustified",DAE.T_BOOL_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,SOME(DAE.BCONST(true)),{},3)};
        // Only String(Real) has the significantDigits option.
        slots = Util.if_(Types.isRealOrSubTypeReal(tp),
          listAppend(slots, {SLOT(DAE.FUNCARG("significantDigits",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,SOME(DAE.ICONST(6)),{},4)}),
          slots);
        (cache,args_1,_,constlist,_) = elabInputArgs(cache,env, args, nargs, slots, false, true/*checkTypes*/ ,impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), {}, NONE(), pre, info, DAE.T_UNKNOWN_DEFAULT, Absyn.IDENT("String"));
        c = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        exp = Expression.makePureBuiltinCall("String", args_1, DAE.T_STRING_DEFAULT);
      then
        (cache, exp, DAE.PROP(DAE.T_STRING_DEFAULT,c));

    // handle format
    case (cache,env,args as e::_,nargs,impl,pre,_)
      equation
        (cache,exp,DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, e, impl,NONE(),true,pre,info);

        slots = {SLOT(DAE.FUNCARG("x",tp,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,NONE(),{},1)};

        slots = Util.if_(Types.isRealOrSubTypeReal(tp),
          listAppend(slots, {SLOT(DAE.FUNCARG("format",DAE.T_STRING_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,SOME(DAE.SCONST("f")),{},2)}),
          slots);
        slots = Util.if_(Types.isIntegerOrSubTypeInteger(tp),
          listAppend(slots, {SLOT(DAE.FUNCARG("format",DAE.T_STRING_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,SOME(DAE.SCONST("d")),{},2)}),
          slots);
        slots = Util.if_(Types.isString(tp),
          listAppend(slots, {SLOT(DAE.FUNCARG("format",DAE.T_STRING_DEFAULT,DAE.C_VAR(),DAE.NON_PARALLEL(),NONE()),false,SOME(DAE.SCONST("s")),{},2)}),
          slots);
        (cache,args_1,_,constlist,_) = elabInputArgs(cache, env, args, nargs, slots, false, true /*checkTypes*/, impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), {}, NONE(), pre, info, DAE.T_UNKNOWN_DEFAULT, Absyn.IDENT("String"));
        c = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        exp = Expression.makePureBuiltinCall("String", args_1, DAE.T_STRING_DEFAULT);
      then
        (cache, exp, DAE.PROP(DAE.T_STRING_DEFAULT,c));
  end matchcontinue;
end elabBuiltinString;

protected function elabBuiltinGetInstanceName
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      String str;
      Absyn.Path name,envName;
    case (FCore.CACHE(modelName=name),_,{},{},_,Prefix.NOPRE(),_)
      equation
        envName = FGraph.getGraphName(inEnv);
        true = Absyn.pathEqual(envName,name);
        str = Absyn.pathLastIdent(name);
        outExp = DAE.SCONST(str);
        outProperties = DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST());
      then (inCache,outExp,outProperties);
    case (FCore.CACHE(modelName=name),_,{},{},_,Prefix.NOPRE(),_)
      equation
        envName = FGraph.getGraphName(inEnv);
        false = Absyn.pathEqual(envName,name);
        str = Absyn.pathString(envName);
        outExp = DAE.SCONST(str);
        outProperties = DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST());
      then (inCache,outExp,outProperties);
    case (FCore.CACHE(modelName=name),_,{},{},_,_,_)
      equation
        str = Absyn.pathLastIdent(name) +& "." +& PrefixUtil.printPrefixStr(inPrefix);
        outExp = DAE.SCONST(str);
        outProperties = DAE.PROP(DAE.T_STRING_DEFAULT,DAE.C_CONST());
      then (inCache,outExp,outProperties);
  end matchcontinue;
end elabBuiltinGetInstanceName;

protected function elabBuiltinVector "author: PA
  This function handles the built in vector operator."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArg;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties) := matchcontinue (inCache,inEnv,inAbsynExpLst,inNamedArg,inBoolean,inPrefix,info)
    local
      DAE.Exp exp;
      DAE.Type tp,tp_1,arr_tp;
      DAE.Const c;
      DAE.Type etp;
      FCore.Graph env;
      Absyn.Exp e;
      Boolean impl,scalar;
      list<DAE.Exp> expl,expl_1,expl_2;
      list<list<DAE.Exp>> explm;
      list<Integer> dims;
      FCore.Cache cache;
      Prefix.Prefix pre;
      Integer dim,dimtmp;

    case (cache,env,{e},_,impl,pre,_) /* vector(scalar) = {scalar} */
      equation
        (cache,exp,DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, e, impl,NONE(),true,pre,info);
        Types.simpleType(tp);
        arr_tp = Types.liftArray(tp, DAE.DIM_INTEGER(1));
        etp = Types.simplifyType(arr_tp);
      then
        (cache,DAE.ARRAY(etp,true,{exp}),DAE.PROP(arr_tp,c));

    case (cache,env,{e},_,impl,pre,_) /* vector(array of scalars) = array of scalars */
      equation
        (cache,DAE.ARRAY(etp,scalar,expl),DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, e, impl,NONE(),true,pre,info);
        1 = Types.numberOfDimensions(tp);
      then
        (cache,DAE.ARRAY(etp,scalar,expl),DAE.PROP(tp,c));

    case (cache,env,{e},_,impl,pre,_) /* vector of multi dimensional array, at most one dim > 1 */
      equation
        (cache,DAE.ARRAY(_,_,expl),DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, e, impl,NONE(),true,pre,info);
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
        (cache,DAE.MATRIX(matrix=explm),DAE.PROP(tp,c),_) = elabExpInExpression(cache,env, e, impl,NONE(),true,pre,info);
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
        (cache, exp, DAE.PROP(tp, c), _) = elabExpInExpression(cache, env, e, impl,NONE(), true, pre,info);
        tp = Types.liftArray(Types.arrayElementType(tp), DAE.DIM_UNKNOWN());
        etp = Types.simplifyType(tp);
        exp = Expression.makePureBuiltinCall("vector", {exp}, etp);
      then
        (cache, exp, DAE.PROP(tp, c));
  end matchcontinue;
end elabBuiltinVector;

protected function checkBuiltinVectorDims
  input Absyn.Exp expr;
  input FCore.Graph env;
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
        scope_str = FGraph.printGraphPathStr(env);
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
    case ((_ :: rest_dims))
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

    case ((dim :: _))
      equation
        (dim > 1) = true;
        Error.addMessage(Error.ERROR_FLATTENING, {"Vector may only be 1x2 or 2x1 dimensions"});
      then
        10;

    case((_ :: dims))
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

    case (expl,(_ :: dims))
      equation
        (1 > dimensionListMaxOne(dims) ) = false;
        expl_1 = elabBuiltinVector2(expl, dims);
      then
        expl_1;
  end matchcontinue;
end elabBuiltinVector2;

public function elabBuiltinMatrix
  "Elaborates the builtin matrix function."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inArgs;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache, outExp, outProperties) := match(inCache, inEnv, inArgs, inNamedArgs, inImpl, inPrefix, inInfo)
    local
      Absyn.Exp arg;
      FCore.Cache cache;
      DAE.Exp exp;
      DAE.Properties props;
      DAE.Type ty;

    case (_, _, {arg}, _, _, _, _)
      equation
        (cache, exp, props, _) =
          elabExpInExpression(inCache, inEnv, arg, inImpl, NONE(), true, inPrefix, inInfo);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
        props = Types.setPropType(inProperties, ty);
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

protected function checkTypeScalar
  "Returns the scalar value of an array, or prints an error message and fails if
  any dimension of the array isn't of size 1."
  input DAE.Dimension inDim;
  input DAE.Type ty;
  input Absyn.Info inInfo;
algorithm
  _ := match(inDim, ty, inInfo)
    local
      String ty_str;
    // An array with one element.
    case (DAE.DIM_INTEGER(1),_,_) then ();
    case (DAE.DIM_EXP(_),_,_) then ();
    case (DAE.DIM_UNKNOWN(),_,_) then ();
    // Any other dimension
    else
      equation
        ty_str = Types.unparseType(ty);
        Error.addSourceMessage(Error.INVALID_ARRAY_DIM_IN_SCALAR_OP, {ty_str}, inInfo);
      then fail();
  end match;
end checkTypeScalar;

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
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output FCore.Cache outCache;
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
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output FCore.Cache outCache;
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
    case "interval" then elabBuiltinInterval;
    case "boolean" then elabBuiltinBoolean;
    case "diagonal" then elabBuiltinDiagonal;
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
    case "classDirectory" then elabBuiltinClassDirectory;
    case "sample" then elabBuiltinSample;
    case "Clock"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinClock;
    case "previous"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinPrevious;
    case "hold"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinHold;
    case "subSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinSubSample;
    case "superSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinSuperSample;
    case "shiftSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinShiftSample;
    case "backSample"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinBackSample;
    case "noClock"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinNoClock;
    case "transition"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinTransition;
    case "initialState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinInitialState;
    case "activeState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinActiveState;
    case "ticksInState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinTicksInState;
    case "timeInState"
      equation
        true = intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);
      then elabBuiltinTimeInState;
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
    input FCore.Cache inCache;
    input FCore.Graph inEnv;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArg;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output FCore.Cache outCache;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inNamedArgs;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  partial function handlerFunc
    input FCore.Cache inCache;
    input FCore.Graph inEnvFrameLst;
    input list<Absyn.Exp> inAbsynExpLst;
    input list<Absyn.NamedArg> inNamedArgs;
    input Boolean inBoolean;
    input Prefix.Prefix inPrefix;
    input Absyn.Info info;
    output FCore.Cache outCache;
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
      FCore.Graph env;
      String name;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      FCore.Cache cache;
      Prefix.Prefix pre;
      Absyn.ComponentRef cr;

    // impl for normal builtin operators and functions
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

    // special handling for MultiBody 3.x rooted() operator
    case (cache,env,Absyn.CREF_IDENT(name = "rooted"),args,nargs,impl,pre,_)
      equation
        (cache,exp,prop) = elabBuiltinRooted(cache,env, args, nargs, impl,pre,info);
      then
        (cache,exp,prop);

    // special handling for Connections.isRoot() operator
    case (cache,env,Absyn.CREF_QUAL(name = "Connections", componentRef = Absyn.CREF_IDENT(name = "isRoot")),args,nargs,impl,pre,_)
      equation
        (cache,exp,prop) = elabBuiltinIsRoot(cache, env, args, nargs, impl, pre, info);
      then
        (cache,exp,prop);

    // special handling for Connections.uniqueRootIndices(roots, nodes, message) operator
    case (cache,env,Absyn.CREF_QUAL(name = "Connections", componentRef = Absyn.CREF_IDENT(name = "uniqueRootIndices")),args,nargs,impl,pre,_)
      equation
        (cache,exp,prop) = elabBuiltinUniqueRootIndices(cache, env, args, nargs, impl, pre, info);
        Error.addSourceMessage(Error.NON_STANDARD_OPERATOR, {"Connections.uniqueRootIndices"}, info);
      then
        (cache,exp,prop);

    // for generic types, like e.g. cardinality
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numErrorMessages;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outST;
algorithm
  (outCache,outExp,outProperties,outST):=
  matchcontinue (inCache,inEnv,inComponentRef,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,inST,inPrefix,info,numErrorMessages)
    local
      DAE.Exp e;
      DAE.Properties prop;
      Option<GlobalScript.SymbolTable> st;
      FCore.Graph env;
      Absyn.ComponentRef fn;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      Boolean impl;
      Absyn.Path fn_1;
      String fnstr,argstr,prestr,s,name,env_str;
      list<String> argstrs;
      FCore.Cache cache;
      Prefix.Prefix pre;

    case (cache,env,fn,args,nargs,impl,st,pre,_,_)
      equation
        (cache,e,prop) = elabCallBuiltin(cache,env, fn, args, nargs, impl,pre,info) "Built in functions (e.g. \"pre\", \"der\"), have only possitional arguments" ;
      then
        (cache,e,prop,st);

    case (_,_,fn,args,_,_,_,pre,_,_)
      equation
        true = hasBuiltInHandler(fn);
        true = numErrorMessages == Error.getNumErrorMessages();
        name = Absyn.printComponentRefStr(fn);
        s = stringDelimitList(List.map(args, Dump.printExpStr), ", ");
        s = stringAppendList({name,"(",s,").\n"});
        prestr = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.WRONG_TYPE_OR_NO_OF_ARGS, {s,prestr}, info);
      then fail();

    /* Interactive mode */
    case (cache,env,fn,args,nargs,(impl as true),st,pre,_,_)
      equation
        false = hasBuiltInHandler(fn);
        ErrorExt.setCheckpoint("elabCall_InteractiveFunction");
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre,info);
        ErrorExt.delCheckpoint("elabCall_InteractiveFunction");
      then
        (cache,e,prop,st);

    /* Non-interactive mode */
    case (cache,env,fn,args,nargs,(impl as false),st,pre,_,_)
      equation
        false = hasBuiltInHandler(fn);
        fn_1 = Absyn.crefToPath(fn);
        (cache,e,prop) = elabCallArgs(cache,env, fn_1, args, nargs, impl, st,pre,info);
      then
        (cache,e,prop,st);

    case (_,_,fn,args,_,_,_,pre,_,_)
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
        (cache,e,prop,st) = BackendInterface.elabCallInteractive(cache,env, fn, args, nargs, impl,st,pre,info) "Elaborate interactive function calls, such as simulate(), plot() etc." ;
        ErrorExt.rollBack("elabCall_InteractiveFunction");
      then
        (cache,e,prop,st);
    else
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
        daeCr = ComponentReference.pathToCref(absynPath);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inBoolean;
  input String inIdent;
  input DAE.Type inType;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input DAE.Exp inExp;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
algorithm
  (outCache,outExp):=
  matchcontinue (inCache,inEnv,inST,inBoolean,inIdent,inType,inAbsynNamedArgLst,inExp,inPrefix,info)
    local
      DAE.Exp exp,exp_1,exp_2,dexp;
      DAE.Type t,tp;
      DAE.Const c1;
      FCore.Graph env;
      Option<GlobalScript.SymbolTable> st;
      Boolean impl;
      String id,id2;
      list<Absyn.NamedArg> xs;
      FCore.Cache cache;
      Prefix.Prefix pre;
      Absyn.Exp aexp;
    case (cache,_,_,_,_,_,{},exp,_,_) then (cache,exp);  /* The expected type */
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = id2,argValue = aexp) :: _),_,pre,_)
      equation
        true = stringEq(id, id2);
        (cache,exp_1,DAE.PROP(t,_),_) = elabExpInExpression(cache,env,aexp,impl,st,true,pre,info);
        (exp_2,_) = Types.matchType(exp_1, t, tp, true);
      then
        (cache,exp_2);
    case (cache,env,st,impl,id,tp,(Absyn.NAMEDARG(argName = _) :: xs),dexp,pre,_)
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  match (inCache,inEnv,inComponentRef,inBoolean,inPrefix,info)
    local
      list<DAE.Subscript> subs_1;
      FCore.Graph env;
      String id;
      list<Absyn.Subscript> subs;
      Boolean impl;
      DAE.ComponentRef cr_1;
      Absyn.ComponentRef cr;
      FCore.Cache cache;
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

public function needToRebuild
  input String newFile;
  input String oldFile;
  input Real   buildTime;
  output Boolean buildNeeded;
algorithm
  buildNeeded := matchcontinue(newFile, oldFile, buildTime)
    local String newf,oldf; Real bt,nfmt;
    case ("","",_) then true; // rebuild all the time if the function has no file!
    case (newf,oldf,bt)
      equation
        true = stringEq(newf, oldf); // the files should be the same!
        // the new file nf should have an older modification time than the last build
        SOME(nfmt) = System.getFileModificationTime(newf);
        true = realGt(bt, nfmt); // the file was not modified since last build
      then false;
    else true;
  end matchcontinue;
end needToRebuild;

public function isFunctionInCflist
"This function returns true if a function, named by an Absyn.Path,
  is present in the list of precompiled functions that can be executed
  in the interactive mode. If it returns true, it also returns the
  functionHandle stored in the cflist."
  input list<GlobalScript.CompiledCFunction> inFunctions;
  input Absyn.Path inPath;
  output Boolean outBoolean;
  output Integer outFuncHandle;
  output Real outBuildTime;
  output String outFileName;
algorithm
  (outBoolean,outFuncHandle,outBuildTime,outFileName) :=
  matchcontinue (inFunctions,inPath)
    local
      Absyn.Path path1,path2;
      DAE.Type ty;
      list<GlobalScript.CompiledCFunction> rest;
      Boolean res;
      Integer handle;
      Real buildTime;
      String fileName;

    case ({},_) then (false, -1, -1.0, "");

    case ((GlobalScript.CFunction(path1,_,handle,buildTime,fileName) :: _),path2)
      equation
        true = Absyn.pathEqual(path1, path2);
      then
        (true, handle, buildTime, fileName);

    case ((GlobalScript.CFunction(path1,_,_,_,_) :: rest),path2)
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
*/

protected function createDummyFarg
  input String name;
  output DAE.FuncArg farg;
algorithm
  farg := DAE.FUNCARG(name, DAE.T_UNKNOWN_DEFAULT, DAE.C_VAR(), DAE.NON_PARALLEL(), NONE());
end createDummyFarg;

protected function propagateDerivedInlineAnnotation
  "Inserts an inline annotation from the given class into the given comment, if
   the comment doesn't already have such an annotation."
  input SCode.Element inExtendedClass;
  input SCode.Comment inComment;
  output SCode.Comment outComment;
algorithm
  outComment := matchcontinue(inExtendedClass, inComment)
    local
      SCode.Comment cmt;
      SCode.Annotation ann;

    case (SCode.CLASS(cmt = cmt), _)
      equation
        NONE() = SCode.getInlineTypeAnnotationFromCmt(inComment);
        SOME(ann) = SCode.getInlineTypeAnnotationFromCmt(cmt);
        cmt = SCode.appendAnnotationToComment(ann, cmt);
      then
        cmt;

    else inComment;
  end matchcontinue;
end propagateDerivedInlineAnnotation;

public function elabCallArgs "
function: elabCallArgs
  Given the name of a function and two lists of expression and
  NamedArg respectively to be used
  as actual arguments in a function call to that function, this
  function finds the function definition and matches the actual
  arguments to the formal parameters."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,SOME((outExp,outProperties))) :=
  elabCallArgs2(inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,Util.makeStatefulBoolean(false),inST,inPrefix,info,Error.getNumErrorMessages());
  (outCache,outProperties) := elabCallArgsEvaluateArrayLength(outCache,inEnv,outProperties,inPrefix,info);
end elabCallArgs;

protected function elabCallArgsEvaluateArrayLength "Evaluate array dimensions in the returned type. For a call f(n) we might get Integer[n] back, where n is a parameter expression.
We consider any such parameter structural since it decides the dimension of an array.
We fall back to not evaluating the parameter if we fail since the dimension may not be structural (used in another call or reduction, etc)."
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.Properties inProperties;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.Properties outProperties;
algorithm
  (outCache,outProperties) := matchcontinue (inCache,env,inProperties,inPrefix,info)
    local
      FCore.Cache cache;
      DAE.Type ty;
      /* Unsure if we want to evaluate dimensions inside function scope */
    case (_,_,_,_,_)
      equation
        // last scope ref in env is a class scope
        true = FGraph.checkScopeType(List.create(FGraph.lastScopeRef(env)), SOME(FCore.CLASS_SCOPE()));
        ty = Types.getPropType(inProperties);
        ((ty,(cache,_))) = Types.traverseType((ty,(inCache,env)),elabCallArgsEvaluateArrayLength2);
      then (cache,Types.setPropType(inProperties,ty));
    else (inCache,inProperties);
  end matchcontinue;
end elabCallArgsEvaluateArrayLength;

protected function elabCallArgsEvaluateArrayLength2
  input tuple<DAE.Type,tuple<FCore.Cache,FCore.Graph>> inTpl;
  output tuple<DAE.Type,tuple<FCore.Cache,FCore.Graph>> outTpl;
algorithm
  (outTpl) := matchcontinue (inTpl)
    local
      tuple<FCore.Cache,FCore.Graph> tpl;
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
  input tuple<FCore.Cache,FCore.Graph> inTpl;
  output DAE.Dimension outDim;
  output tuple<FCore.Cache,FCore.Graph> outTpl;
algorithm
  (outDim,outTpl) := matchcontinue (inDim,inTpl)
    local
      Integer i;
      DAE.Exp exp;
      FCore.Cache cache;
      FCore.Graph env;
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
    case (SLOT(defaultArg = DAE.FUNCARG(name=id), slotFilled = true, arg = SOME(e))::rest, i)
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Util.StatefulBoolean stopElab;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numErrors;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
algorithm
  (outCache,expProps) :=
  matchcontinue (inCache,inEnv,inPath,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,stopElab,inST,inPrefix,info,numErrors)
    local
      DAE.Type t,outtype,restype,functype,tp1;
      list<DAE.FuncArg> fargs;
      FCore.Graph env_1,env_2,env,classEnv,recordEnv;
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
      FCore.Cache cache;
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
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
      equation
        (cache,cl as SCode.CLASS(restriction = SCode.R_PACKAGE()),_) =
           Lookup.lookupClass(cache, env, Absyn.IDENT("GraphicalAnnotationsProgram____"), false);
        (cache,cl as SCode.CLASS( restriction = SCode.R_RECORD(_)),env_1) = Lookup.lookupClass(cache, env, fn, false);
        (cache,cl,env_2) = Lookup.lookupRecordConstructorClass(cache, env_1 /* env */, fn);
        (_,_::names) = SCode.getClassComponents(cl); // remove the fist one as it is the result!
        /*
        (cache,(t as (DAE.T_FUNCTION(fargs,(outtype as (DAE.T_COMPLEX(complexClassType as ClassInf.RECORD(name),_,_,_),_))),_)),env_1)
          = Lookup.lookupType(cache, env, fn, SOME(info));
        */
        fargs = List.map(names, createDummyFarg);
        slots = makeEmptySlots(fargs);
        (cache,_,newslots,constInputArgs,_) = elabInputArgs(cache, env, args, nargs, slots, true, false /*checkTypes*/ ,impl,NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),  {},st,pre,info,DAE.T_UNKNOWN_DEFAULT,fn);
        (cache,newslots2,constDefaultArgs,_) = fillGraphicsDefaultSlots(cache, newslots, cl, env_2, impl, {}, pre, info);
        constlist = listAppend(constInputArgs, constDefaultArgs);
        _ = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        args_2 = slotListArgs(newslots2);

        tp = complexTypeFromSlots(newslots2,ClassInf.UNKNOWN(Absyn.IDENT("")));
        //tyconst = elabConsts(outtype, const);
        //prop = getProperties(outtype, tyconst);
      then
        (cache,SOME((DAE.CALL(fn,args_2,DAE.CALL_ATTR(tp,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL())),DAE.PROP(DAE.T_UNKNOWN_DEFAULT,DAE.C_CONST()))));

    /*/ adrpo: deal with function call via an instance: MultiBody world.gravityAcceleration
    case (cache, env, fn, args, nargs, impl, _, st,pre,_,_)
      equation
        fnPrefix = Absyn.stripLast(fn); // take the prefix: word
        fnIdent = Absyn.pathLastIdent(fn); // take the suffix: gravityAcceleration
        Absyn.IDENT(componentName) = fnPrefix; // see that is just a name TODO! this might be a path
        (_, _, SCode.COMPONENT(
          prefixes = SCode.PREFIXES(innerOuter=_),
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
        (cache,SOME((call_exp,prop_1)));*/

    // Record constructors, user defined or implicit, try the hard stuff first
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
      equation
        // For unrolling errors if an overloaded 'constructor' matches later.
        ErrorExt.setCheckpoint("RecordConstructor");

        (cache,func) = InstFunction.getRecordConstructorFunction(cache,env,fn);

        DAE.RECORD_CONSTRUCTOR(path,tp1,_,_) = func;
        DAE.T_FUNCTION(fargs, outtype, _, {path}) = tp1;


        slots = makeEmptySlots(fargs);
        (cache,_,newslots,constInputArgs,_) = elabInputArgs(cache,env, args, nargs, slots,true,true,impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(),  {},st,pre,info,tp1,path);

        (args_2, newslots2) = addDefaultArgs(newslots, info);
        vect_dims = slotsVectorizable(newslots2, info);

        constlist = constInputArgs;
        const = List.fold(constlist, Types.constAnd, DAE.C_CONST());

        tyconst = elabConsts(outtype, const);
        prop = getProperties(outtype, tyconst);

        callExp = DAE.CALL(path,args_2,DAE.CALL_ATTR(outtype,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

        (call_exp,prop_1) = vectorizeCall(callExp, vect_dims, newslots2, prop, info);
        expProps = SOME((call_exp,prop_1));

        Util.setStatefulBoolean(stopElab,true);
        ErrorExt.rollBack("RecordConstructor");

      then
        (cache,expProps);

        /* If the default constructor failed and we have an operator record
        look for overloaded Record constructors (operators), user defined.
        mahge:TODO move this to a function and call it from above.
        avoids uneccesary lookup since we already have a record.*/
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
      equation

        false = Util.getStatefulBoolean(stopElab);

        (cache,recordCl,recordEnv) = Lookup.lookupClass(cache,env,fn, false);
        true = SCode.isOperatorRecord(recordCl);

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
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_) /* Metamodelica extension, added by simbj */
      equation

        ErrorExt.delCheckpoint("RecordConstructor");

        true = Config.acceptMetaModelicaGrammar();
        false = Util.getStatefulBoolean(stopElab);
        (cache,t as DAE.T_METARECORD(fields=_,source={_}),_) = Lookup.lookupType(cache, env, fn, NONE());
        Util.setStatefulBoolean(stopElab,true);
        (cache,expProps) = elabCallArgsMetarecord(cache,env,t,args,nargs,impl,stopElab,st,pre,info);
      then
        (cache,expProps);

      /* ..Other functions */
    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_)
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

    case (cache,env,fn,args,nargs,impl,_,st,pre,_,_) /* no matching type found, with -one- candidate */
      equation
        (cache,typelist as {tp1}) = Lookup.lookupFunctionsInEnv(cache, env, fn, info);
        (cache,args_1,_,_,functype,_,_) =
          elabTypes(cache, env, args, nargs, typelist, true, false/* Do not check types*/, impl,NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), st,pre,info);
        argStr = ExpressionDump.printExpListStr(args_1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = Absyn.pathString(fn) +& "(" +& argStr +& ")\nof type\n  " +& Types.unparseType(functype);
        types_str = "\n  " +& Types.unparseType(tp1);
        Error.assertionOrAddSourceMessage(Error.getNumErrorMessages()<>numErrors,Error.NO_MATCHING_FUNCTION_FOUND, {fn_str,pre_str,types_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,_,_,_,_,_,_,_,_) /* class found; not function */
      equation
        (cache,SCode.CLASS(restriction = re),_) = Lookup.lookupClass(cache,env,fn,false);
        false = SCode.isFunctionRestriction(re);
        fn_str = Absyn.pathString(fn);
        s = SCodeDump.restrString(re);
        Error.addSourceMessage(Error.LOOKUP_FUNCTION_GOT_CLASS, {fn_str,s}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,_,_,_,_,_,pre,_,_) /* no matching type found, with candidates */
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
    case (cache,env,fn,{Absyn.CREF(Absyn.CREF_IDENT(name,_))},_,impl,_,_,pre,_,_)
      equation
        true = Config.acceptOptimicaGrammar();
        cref = Absyn.pathToCref(fn);

        (cache,SOME((daeexp as DAE.CREF(daecref,tp),prop,_))) = elabCref(cache,env, cref, impl,true,pre,info);
        ErrorExt.rollBack("elabCallArgs2FunctionLookup");

        daeexp = DAE.CREF(DAE.OPTIMICA_ATTR_INST_CREF(daecref,name), tp);
        expProps = SOME((daeexp,prop));
      then
        (cache,expProps);

    case (cache,env,fn,_,_,_,_,_,_,_,_)
      equation
        failure((_,_,_) = Lookup.lookupType(cache,env, fn, NONE())) "msg" ;
        scope = FGraph.printGraphPathStr(env) +& " (looking for a function or record)";
        fn_str = Absyn.pathString(fn);
        Error.addSourceMessage(Error.LOOKUP_ERROR, {fn_str,scope}, info); // No need to add prefix because only depends on scope?

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (cache,env,fn,_,_,_,_,_,pre,_,_) /* no matching type found, no candidates. */
      equation
        (cache,{}) = Lookup.lookupFunctionsInEnv(cache,env,fn,info);
        fn_str = Absyn.pathString(fn);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        fn_str = fn_str +& " in component " +& pre_str;
        Error.addSourceMessage(Error.NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE, {fn_str}, info);

        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
      then
        (cache,NONE());

    case (_,env,fn,_,_,_,_,_,_,_,_)
      equation
        ErrorExt.delCheckpoint("elabCallArgs2FunctionLookup");
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabCallArgs failed on: " +& Absyn.pathString(fn) +& " in env: " +& FGraph.printGraphPathStr(env));
      then
        fail();
  end matchcontinue;
end elabCallArgs2;

public function elabCallArgs3
  "Elaborates the input given a set of viable function candidates, and vectorizes the arguments+performs type checking"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Type> typelist;
  input Absyn.Path fn;
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> nargs;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
  FCore.Cache cache;
  Boolean didInline;
  Boolean b,onlyOneFunction,isFunctionPointer;
  IsExternalObject isExternalObject;
algorithm
  onlyOneFunction := listLength(typelist) == 1;
  (cache,b) := isExternalObjectFunction(inCache,inEnv,fn);
  isExternalObject := Util.if_(b and not FGraph.inFunctionScope(inEnv), IS_EXTERNAL_OBJECT_MODEL_SCOPE(), NOT_EXTERNAL_OBJECT_MODEL_SCOPE());
  (cache,
   args_1,
   constlist,
   restype,
   functype as DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isOpenModelicaPure=isPure,
                                                                         isImpure=isImpure,
                                                                         inline=inlineType,
                                                                         isFunctionPointer=isFunctionPointer,
                                                                         functionParallelism=funcParal)),
   vect_dims,
   slots) := elabTypes(cache, inEnv, args, nargs, typelist, onlyOneFunction, true/* Check types*/, impl,isExternalObject,st,pre,info)
   "The constness of a function depends on the inputs. If all inputs are constant the call itself is constant." ;
  (fn_1,functype) := deoverloadFuncname(fn, functype, inEnv);
  tuple_ := Types.isTuple(restype);
  (isBuiltin,builtin,fn_1) := isBuiltinFunc(fn_1,functype);
  inlineType := inlineBuiltin(isBuiltin,inlineType);

  //check the env to see if a call to a parallel or kernel function is a valid one.
  true := isValidWRTParallelScope(fn,builtin,funcParal,inEnv,info);

  const := List.fold(constlist, Types.constAnd, DAE.C_CONST());
  const := Util.if_((Flags.isSet(Flags.RML) and not builtin) or (not isPure), DAE.C_VAR(), const) "in RML no function needs to be ceval'ed; this speeds up compilation significantly when bootstrapping";
  (cache,const) := determineConstSpecialFunc(cache,inEnv,const,fn_1);
  tyconst := elabConsts(restype, const);
  prop := getProperties(restype, tyconst);
  tp := Types.simplifyType(restype);
  // adrpo: 2011-09-30 NOTE THAT THIS WILL NOT ADD DEFAULT ARGS
  //                   FROM extends (THE BASE CLASS)
  (args_2, slots2) := addDefaultArgs(slots, info);
  // DO NOT CHECK IF ALL SLOTS ARE FILLED!
  true := List.fold(slots2, slotAnd, true);
  callExp := DAE.CALL(fn_1,args_2,DAE.CALL_ATTR(tp,tuple_,builtin,isImpure,isFunctionPointer,inlineType,DAE.NO_TAIL()));
  //ExpressionDump.dumpExpWithTitle("function elabCallArgs3: ", callExp);

  // create a replacement for input variables -> their binding
  //inputVarsRepl = createInputVariableReplacements(slots2, VarTransform.emptyReplacements());
  //print("Repls: " +& VarTransform.dumpReplacementsStr(inputVarsRepl) +& "\n");
  // replace references to inputs in the arguments
  //callExp = VarTransform.replaceExp(callExp, inputVarsRepl, NONE());

  //debugPrintString = Util.if_(Util.isEqual(DAE.NORM_INLINE,inline)," Inline: " +& Absyn.pathString(fn_1) +& "\n", "");print(debugPrintString);
  (call_exp,prop_1) := vectorizeCall(callExp, vect_dims, slots2, prop, info);
  // print("3 Prefix: " +& PrefixUtil.printPrefixStr(pre) +& " path: " +& Absyn.pathString(fn_1) +& "\n");
  // Instantiate the function and add to dae function tree
  (cache,status) := instantiateDaeFunction(cache,inEnv,
    Util.if_(Lookup.isFunctionCallViaComponent(cache, inEnv, fn), fn, fn_1), // don't use the fully qualified name for calling component functions
    builtin,NONE(),true);
  // Instantiate any implicit record constructors needed and add them to the dae function tree
  cache := instantiateImplicitRecordConstructors(cache, inEnv, args_1, st);
  functionTree := FCore.getFunctionTree(cache);
  (call_exp,_,didInline,_) := Inline.inlineExp(call_exp,(SOME(functionTree),{DAE.BUILTIN_EARLY_INLINE(),DAE.EARLY_INLINE()}),DAE.emptyElementSource);
  (call_exp,_) := ExpressionSimplify.condsimplify(didInline,call_exp);
  didInline := didInline and (not Config.acceptMetaModelicaGrammar() /* Some weird errors when inlining. Becomes boxed even if it shouldn't... */);
  prop_1 := Debug.bcallret2(didInline, Types.setPropType, prop_1, restype, prop_1);
  (cache, call_exp, prop_1) := Ceval.cevalIfConstant(cache, inEnv, call_exp, prop_1, impl, info);
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
  input FCore.Graph inEnv;
  input Absyn.Info inInfo;
  output Boolean isValid;
algorithm
  isValid := isValidWRTParallelScope_dispatch(inFn, isBuiltin, inFuncParallelism, FGraph.currentScope(inEnv), inInfo);
end isValidWRTParallelScope;

protected function isValidWRTParallelScope_dispatch
  input Absyn.Path inFn;
  input Boolean isBuiltin;
  input DAE.FunctionParallelism inFuncParallelism;
  input FCore.Scope inScope;
  input Absyn.Info inInfo;
  output Boolean isValid;
algorithm
  isValid := matchcontinue(inFn,isBuiltin,inFuncParallelism,inScope,inInfo)
  local
    String scopeName, errorString;
    FCore.Scope restScope;
    FCore.Ref ref;


    // non-parallel builtin function call is OK everywhere.
    case(_,true,DAE.FP_NON_PARALLEL(), _, _)
      then true;

    // If we have a function call in an implicit scope type, then go
    // up recursively to find the actuall scope and then check.
    // But parfor scope is a parallel type so is handled differently.
    case(_,_,_, ref::restScope, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = listMember(scopeName, FCore.implicitScopeNames);
        false = stringEq(scopeName, FCore.parForScopeName);
      then isValidWRTParallelScope_dispatch(inFn,isBuiltin,inFuncParallelism,restScope,inInfo);

    // This two are common cases so keep them at the top.
    // normal(non parallel) function call in a normal scope (function and class scopes) is OK.
    case(_,_,DAE.FP_NON_PARALLEL(), ref::_, _)
      equation
        true = FGraph.checkScopeType({ref}, SOME(FCore.CLASS_SCOPE()));
      then
        true;

    case(_,_,DAE.FP_NON_PARALLEL(), ref::_, _)
      equation
        true = FGraph.checkScopeType({ref}, SOME(FCore.FUNCTION_SCOPE()));
      then
        true;

    // Normal function call in a prallel scope is error, if it is not a built-in function.
    case(_,_,DAE.FP_NON_PARALLEL(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));

        errorString = "\n" +&
             "- Non-Parallel function '" +& Absyn.pathString(inFn) +&
             "' can not be called from a parallel scope." +& "\n" +&
             "- Here called from :" +& scopeName +& "\n" +&
             "- Please declare the function as parallel function.";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then
        false;


    // parallel function call in a parallel scope (kernel function, parallel function) is OK.
    // Except when it is calling itself, recurssion
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        false = stringEqual(scopeName,Absyn.pathString(inFn));
      then
        true;

    // If the above case failed (parallel function recurssion) this will print the error message
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));

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
      then
        false;

    // parallel function call in a parfor scope is OK.
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = stringEqual(scopeName, FCore.parForScopeName);
      then
        true;

    //parallel function call in non parallel scope types is error.
    case(_,_,DAE.FP_PARALLEL_FUNCTION(), ref::_,_)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);

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
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);

        // make sure the function is not calling itself
        // recurrsion is not allowed.
        true = stringEqual(scopeName,Absyn.pathString(inFn));
        errorString = "\n" +&
             "- Kernel function '" +& Absyn.pathString(inFn) +&
             "' can not call itself. " +& "\n" +&
             "- Recurrsion is not allowed for Kernel functions. ";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then
        false;

    //kernel function call in a parallel scope (kernel function, parallel function) is Error.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        true = FGraph.checkScopeType({ref}, SOME(FCore.PARALLEL_SCOPE()));

        errorString = "\n" +&
             "- Kernel function '" +& Absyn.pathString(inFn) +&
             "' can not be called from a parallel scope '" +& scopeName +& "'.\n" +&
             "- Kernel functions CAN NOT be called from: 'kernel' functions," +&
             " 'parallel' functions or from a body of a" +&
             " 'parfor' loop";
        Error.addSourceMessage(Error.PARMODELICA_ERROR,
          {errorString}, inInfo);
      then
        false;

    //kernel function call in a parfor loop is Error too (similar to above). just different error message.
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);

        true = stringEqual(scopeName, FCore.parForScopeName);
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
    case(_,_,DAE.FP_KERNEL_FUNCTION(), ref::_, _)
      equation
        false = FNode.isRefTop(ref);
        scopeName = FNode.refName(ref);
        // make sure the function is not calling itself
        // recurrsion is not allowed.
        false = stringEqual(scopeName,Absyn.pathString(inFn));
      then
        true;

    else true;

        /*
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_NON_PARALLEL(), FCore.N(scopeType = FCore.FUNCTION_SCOPE())) then();
    //Normal (non parallel) function call in a normal class scope is OK.
    case(DAE.FP_NON_PARALLEL(), FCore.N(scopeType = FCore.CLASS_SCOPE())) then();
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_NON_PARALLEL(), FCore.N(scopeType = FCore.FUNCTION_SCOPE())) then();
    //Normal (non parallel) function call in a normal class scope is OK.
    case(DAE.FP_KERNEL_FUNCTION(), FCore.N(scopeType = FCore.CLASS_SCOPE())) then();
    //Normal (non parallel) function call in a normal function scope is OK.
    case(DAE.FP_KERNEL_FUNCTION(), FCore.N(scopeType = FCore.FUNCTION_SCOPE())) then();
    */

 end matchcontinue;
end isValidWRTParallelScope_dispatch;

protected function elabCallArgsMetarecord
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Type inType;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Boolean inBoolean;
  input Util.StatefulBoolean stopElab;
  input Option<GlobalScript.SymbolTable> inST;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties>> expProps;
algorithm
  (outCache,expProps) :=
  matchcontinue (inCache,inEnv,inType,inAbsynExpLst,inAbsynNamedArgLst,inBoolean,stopElab,inST,inPrefix,info)
    local
      DAE.Type t;
      list<DAE.FuncArg> fargs;
      FCore.Cache cache;
      FCore.Graph env;
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

    case (cache,_,DAE.T_METARECORD(fields=vars,source={fqPath}),_,_,_,_,_,_,_)
      equation
        _ = List.map(vars, Types.getVarType);
        DAE.TYPES_VAR(name = str) = List.selectFirst(vars, Types.varHasMetaRecordType);
        fn_str = Absyn.pathString(fqPath);
        Error.addSourceMessage(Error.METARECORD_CONTAINS_METARECORD_MEMBER,{fn_str,str},info);
      then (cache,NONE());

    case (cache,_,t as DAE.T_METARECORD(fields=vars,source={_}),args,nargs,_,_,_,_,_)
      equation
        false = listLength(vars) == listLength(args) + listLength(nargs);
        fn_str = Types.unparseType(t);
        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS,{fn_str},info);
      then (cache,NONE());

    case (cache,env,t as DAE.T_METARECORD(index=index,utPath=utPath,fields=vars,source={fqPath}),args,nargs,impl,_,st,pre,_)
      equation
        fieldNames = List.map(vars, Types.getVarName);
        tys = List.map(vars, Types.getVarType);
        fargs = List.threadMap(fieldNames, tys, Types.makeDefaultFuncArg);
        slots = makeEmptySlots(fargs);
        (cache,_,newslots,constlist,_) = elabInputArgs(cache,env, args, nargs, slots, true, true , impl, NOT_EXTERNAL_OBJECT_MODEL_SCOPE(), {}, st, pre, info, t, utPath);
        const = List.fold(constlist, Types.constAnd, DAE.C_CONST());
        tyconst = elabConsts(t, const);
//      t = DAE.T_METAUNIONTYPE({},knownSingleton,{utPath});
        prop = getProperties(t, tyconst);
        true = List.fold(newslots, slotAnd, true);
        args_2 = slotListArgs(newslots);
      then
        (cache,SOME((DAE.METARECORDCALL(fqPath,args_2,fieldNames,index),prop)));

    // MetaRecord failure
    case (cache,env,DAE.T_METARECORD(fields=vars,source={fqPath}),args,_,_,_,st,pre,_)
      equation
        (cache,_,prop,_) = elabExpInExpression(cache,env,Absyn.TUPLE(args),false,st,false,pre,info);
        tys = List.map(vars, Types.getVarType);
        str = "Failed to match types:\n    actual:   " +& Types.unparseType(Types.getPropType(prop)) +& "\n    expected: " +& Types.unparseType(DAE.T_TUPLE(tys,DAE.emptyTypeSource));
        fn_str = Absyn.pathString(fqPath);
        Error.addSourceMessage(Error.META_RECORD_FOUND_FAILURE,{fn_str,str},info);
      then (cache,NONE());

    // MetaRecord failure (args).
    case (cache,_,t,args,_,_,_,_,_,_)
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
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Absyn.Path name;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  output FCore.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := instantiateDaeFunction2(inCache, env, name, builtin, clOpt, Error.getNumErrorMessages(), printErrorMsg, Util.isSome(getGlobalRoot(Global.instOnlyForcedFunctions)), NORMAL_FUNCTION_INST());
end instantiateDaeFunction;

public function instantiateDaeFunctionFromTypes "help function to elabCallArgs. Instantiates the function as a dae and adds it to the
functiontree of a newly created dae"
  input FCore.Cache inCache;
  input FCore.Graph env;
  input list<DAE.Type> tys;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  input Util.Status acc;
  output FCore.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := match (inCache, env, tys, builtin, clOpt, printErrorMsg, acc)
    local
      Absyn.Path name;
      list<DAE.Type> rest;
      Util.Status status1,status2;
    case (_, _, DAE.T_FUNCTION(source={name})::rest, _, _, _, Util.SUCCESS())
      equation
        (outCache,status) = instantiateDaeFunction(inCache, env, name, builtin, clOpt, printErrorMsg);
        (outCache,status) = instantiateDaeFunctionFromTypes(inCache, env, rest, builtin, clOpt, printErrorMsg, status);
      then (outCache, status);
    else (inCache, acc);
  end match;
end instantiateDaeFunctionFromTypes;

public function instantiateDaeFunctionForceInst "help function to elabCallArgs. Instantiates the function as a dae and adds it to the
functiontree of a newly created dae"
  input FCore.Cache inCache;
  input FCore.Graph env;
  input Absyn.Path name;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  output FCore.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := instantiateDaeFunction2(inCache, env, name, builtin, clOpt, Error.getNumErrorMessages(), printErrorMsg, Util.isSome(getGlobalRoot(Global.instOnlyForcedFunctions)), FORCE_FUNCTION_INST());
end instantiateDaeFunctionForceInst;

protected function instantiateDaeFunction2 "help function to elabCallArgs. Instantiates the function as a dae and adds it to the
functiontree of a newly created dae"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inName;
  input Boolean builtin "builtin functions create empty dae";
  input Option<SCode.Element> clOpt "if not present, looked up by name in environment";
  input Integer numError "if errors were added, do not add a generic error message";
  input Boolean printErrorMsg "if true, prints an error message if the function could not be instantiated";
  input Boolean instOnlyForcedFunctions;
  input ForceFunctionInst forceFunctionInst;
  output FCore.Cache outCache;
  output Util.Status status;
algorithm
  (outCache,status) := matchcontinue(inCache,inEnv,inName,builtin,clOpt,numError,printErrorMsg,instOnlyForcedFunctions,forceFunctionInst)
    local
      FCore.Cache cache;
      FCore.Graph env;
      SCode.Element cl;
      String pathStr,envStr;
      DAE.ComponentRef cref;
      Absyn.Path name;

    // Skip function instantiation if we set those flags
    case(cache,_,name,_,_,_,_,true,NORMAL_FUNCTION_INST())
      equation
        failure(Absyn.IDENT(_) = name); // Don't skip builtin functions or functions in the same package; they are useful to inline
        // print("Skipping: " +& Absyn.pathString(name) +& "\n");
      then (cache,Util.SUCCESS());

    // Builtin functions skipped
    case(cache,_,_,true,_,_,_,_,_) then (cache,Util.SUCCESS());

    // External object functions skipped
    case(cache,env,name,_,_,_,_,_,NORMAL_FUNCTION_INST())
      equation
        (_,true) = isExternalObjectFunction(cache,env,name);
      then (cache,Util.SUCCESS());

    // Recursive calls (by looking at environment) skipped
    case(cache,env,name,_,NONE(),_,_,_,_)
      equation
        false = FGraph.isTopScope(env);
        true = Absyn.pathSuffixOf(name,FGraph.getGraphName(env));
      then (cache,Util.SUCCESS());

    // Recursive calls (by looking in cache) skipped
    case(cache,env,name,_,_,_,_,_,_)
      equation
        (cache, env, cl, name) = lookupAndFullyQualify(cache,env,name);
        FCore.checkCachedInstFuncGuard(cache,name);
      then (cache,Util.SUCCESS());

    // class must be looked up
    case(cache,env,name,_,NONE(),_,_,_,_)
      equation
        (cache, env, cl, name) = lookupAndFullyQualify(cache,env,name);
        cache = FCore.addCachedInstFuncGuard(cache,name);
        (cache,env,_) = InstFunction.implicitFunctionInstantiation(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),cl,{});
      then (cache,Util.SUCCESS());

    // class already available
    case(cache,env,name,_,SOME(cl),_,_,_,_)
      equation
        (cache,name) = Inst.makeFullyQualified(cache,env,name);
        (cache,env,_) = InstFunction.implicitFunctionInstantiation(cache,env,InnerOuter.emptyInstHierarchy,DAE.NOMOD(),Prefix.NOPRE(),cl,{});
      then (cache,Util.SUCCESS());

    // call to function reference variable
    case (cache,env,name,_,NONE(),_,_,_,_)
      equation
        cref = ComponentReference.pathToCref(name);
        (cache,_,DAE.T_FUNCTION(funcArg = _),_,_,_,env,_,_) = Lookup.lookupVar(cache,env,cref);
      then (cache,Util.SUCCESS());

    case(_,env,name,_,_,_,true,_,_)
      equation
        true = Error.getNumErrorMessages() == numError;
        envStr = FGraph.printGraphPathStr(env);
        pathStr = Absyn.pathString(name);
        Error.addMessage(Error.GENERIC_INST_FUNCTION, {pathStr, envStr});
      then fail();

    else (inCache,Util.FAILURE());
  end matchcontinue;
end instantiateDaeFunction2;

protected function lookupAndFullyQualify
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inFunctionName;
  output FCore.Cache outCache;
  output FCore.Graph outEnv;
  output SCode.Element outClass;
  output Absyn.Path outFunctionName;
algorithm
  (outCache, outEnv, outClass, outFunctionName) := matchcontinue(inCache, inEnv, inFunctionName)
    local
      FCore.Cache cache;
      FCore.Graph env;
      Absyn.Path name;
      SCode.Element cl;

    // do NOT qualify function calls via component instance!
    case (_, _, _)
      equation
        true = Lookup.isFunctionCallViaComponent(inCache, inEnv, inFunctionName);
        (cache,cl,env) = Lookup.lookupClass(inCache, inEnv, inFunctionName, false);
        name = FGraph.joinScopePath(env, Absyn.makeIdentPathFromString(SCode.elementName(cl)));
      then
        (inCache, env, cl, name);

    // qualify everything else
    case (_, _, _)
      equation
        (cache,cl,env) = Lookup.lookupClass(inCache, inEnv, inFunctionName, false);
        name = Absyn.makeFullyQualified(FGraph.joinScopePath(env, Absyn.makeIdentPathFromString(SCode.elementName(cl))));
      then
        (cache, env, cl, name);

  end matchcontinue;
end lookupAndFullyQualify;

protected function instantiateImplicitRecordConstructors
  "Given a list of arguments to a function, this function checks if any of the
  arguments are component references to a record instance, and instantiates the
  record constructors for those components. These are implicit record
  constructors, because they are not explicitly called, but are needed when code
  is generated for record instances as function input arguments."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<DAE.Exp> args;
  input Option<GlobalScript.SymbolTable> st;
  output FCore.Cache outCache;
algorithm
  outCache := matchcontinue(inCache, inEnv, args, st)
    local
      list<DAE.Exp> rest_args;
      Absyn.Path record_name;
      FCore.Cache cache;
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

protected function addDefaultArgs
  "Adds default values to a list of function slots."
  input list<Slot> inSlots;
  input Absyn.Info inInfo;
  output list<DAE.Exp> outArgs;
  output list<Slot> outSlots;
protected
  list<tuple<Slot, Integer>> slots;
  array<tuple<Slot, Integer>> slot_arr;
algorithm
  slots := List.map1(inSlots, Util.makeTuple, 0);
  slot_arr := listArray(slots);
  (outArgs, outSlots) := List.map2_2(inSlots, fillDefaultSlot, slot_arr, inInfo);
end addDefaultArgs;

protected function fillDefaultSlot
  "Fills a function slot with it's default value if it hasn't already been filled."
  input Slot inSlot;
  input array<tuple<Slot, Integer>> inSlotArray;
  input Absyn.Info inInfo;
  output DAE.Exp outArg;
  output Slot outSlot;
algorithm
  (outArg, outSlot) := match(inSlot, inSlotArray, inInfo)
    local
      DAE.Dimensions dims;
      DAE.Exp arg;
      String id;
      Integer idx;
      tuple<Slot, Integer> aslot;
      Slot slot;

    // Slot already filled by function argument.
    case (SLOT(slotFilled = true, arg = SOME(arg)), _, _) then (arg, inSlot);

    // Slot not filled by function argument, but has default value.
    case (SLOT(slotFilled = false, defaultArg = DAE.FUNCARG(defaultBinding=SOME(_)), idx = idx), _, _)
      equation
        aslot = arrayGet(inSlotArray, idx);
        (arg, slot) = fillDefaultSlot2(aslot, inSlotArray, inInfo);
      then
        (arg, slot);

    // Slot not filled, and has no default value => error.
    case (SLOT(defaultArg = DAE.FUNCARG(name=id)), _, _)
      equation
        Error.addSourceMessage(Error.UNFILLED_SLOT, {id}, inInfo);
      then
        fail();

  end match;
end fillDefaultSlot;

protected function fillDefaultSlot2
  input tuple<Slot, Integer> inSlot;
  input array<tuple<Slot, Integer>> inSlotArray;
  input Absyn.Info inInfo;
  output DAE.Exp outArg;
  output Slot outSlot;
algorithm
  (outArg, outSlot) := match(inSlot, inSlotArray, inInfo)
    local
      Slot slot;
      DAE.Exp exp;
      String id;
      DAE.FuncArg da;
      DAE.Dimensions dims;
      Integer idx;
      list<tuple<Slot, Integer>> slots;
      list<String> cyclic_slots;

    // An already evaluated slot, return its binding.
    case ((slot as SLOT(arg = SOME(exp)), 2), _, _) then (exp, slot);

    // A slot in the process of being evaluated => cyclic bindings.
    case ((SLOT(defaultArg = DAE.FUNCARG(name=id)), 1), _, _)
      equation
        Error.addSourceMessage(Error.CYCLIC_DEFAULT_VALUE,
          {id}, inInfo);
      then
        fail();

    // A slot with an unevaluated binding, evaluate the binding and return it.
    case ((slot as SLOT(defaultArg = da as DAE.FUNCARG(defaultBinding=SOME(exp)), dims = dims, idx = idx), 0), _, _)
      equation
        _ = arrayUpdate(inSlotArray, idx, (slot, 1));
        exp = evaluateSlotExp(exp, inSlotArray, inInfo);
        slot = SLOT(da, true, SOME(exp), dims, idx);
        _ = arrayUpdate(inSlotArray, idx, (slot, 2));
      then
        (exp, slot);

  end match;
end fillDefaultSlot2;

protected function evaluateSlotExp
  "Evaluates a slot's binding by recursively replacing references to other slots
   with their bindings."
  input DAE.Exp inExp;
  input array<tuple<Slot, Integer>> inSlotArray;
  input Absyn.Info inInfo;
  output DAE.Exp outExp;
algorithm
  (outExp, _) := Expression.traverseExp(inExp, evaluateSlotExp_traverser, (inSlotArray, inInfo));
end evaluateSlotExp;

protected function evaluateSlotExp_traverser
  input DAE.Exp inExp;
  input tuple<array<tuple<Slot, Integer>>, Absyn.Info> inTuple;
  output DAE.Exp outExp;
  output tuple<array<tuple<Slot, Integer>>, Absyn.Info> outTuple;
algorithm
  (outExp,outTuple) := match (inExp,inTuple)
    local
      String id;
      array<tuple<Slot, Integer>> slots;
      Option<Slot> slot;
      DAE.Exp exp, orig_exp;
      Absyn.Info info;

    // Only simple identifiers can be slot names.
    case (orig_exp as DAE.CREF(componentRef = DAE.CREF_IDENT(ident = id)), (slots, info))
      equation
        slot = lookupSlotInArray(id, slots);
        exp = getOptSlotDefaultExp(slot, slots, info, orig_exp);
      then (exp, (slots, info));

    else (inExp,inTuple);
  end match;
end evaluateSlotExp_traverser;

protected function lookupSlotInArray
  "Looks up the given name in an array of slots, and returns either SOME(slot)
   if a slot with that name was found, or NONE() if a slot couldn't be found."
  input String inSlotName;
  input array<tuple<Slot, Integer>> inSlots;
  output Option<Slot> outSlot;
algorithm
  outSlot := matchcontinue(inSlotName, inSlots)
    local
      Slot slot;

    case (_, _)
      equation
        ((slot, _), _) = Util.arrayGetMemberOnTrue(inSlotName, inSlots, isSlotNamed);
      then
        SOME(slot);

    else NONE();
  end matchcontinue;
end lookupSlotInArray;

protected function isSlotNamed
  input String inName;
  input tuple<Slot, Integer> inSlot;
  output Boolean outIsNamed;
protected
  String id;
algorithm
  (SLOT(defaultArg = DAE.FUNCARG(name=id)), _) := inSlot;
  outIsNamed := stringEq(id, inName);
end isSlotNamed;

protected function getOptSlotDefaultExp
  "Takes an optional slot and tries to evaluate the slot's binding if it's SOME,
   otherwise returns the original expression if it's NONE."
  input Option<Slot> inSlot;
  input array<tuple<Slot, Integer>> inSlots;
  input Absyn.Info inInfo;
  input DAE.Exp inOrigExp;
  output DAE.Exp outExp;
algorithm
  outExp := match(inSlot, inSlots, inInfo, inOrigExp)
    local
      Slot slot;
      DAE.Exp exp;

    // Got a slot, evaluate its binding and return it.
    case (SOME(slot), _, _, _)
      equation
        (exp, _) = fillDefaultSlot(slot, inSlots, inInfo);
      then
        exp;

    // No slot, return the original expression.
    case (NONE(), _, _, _) then inOrigExp;
  end match;
end getOptSlotDefaultExp;

protected function determineConstSpecialFunc "For the special functions constructor and destructor,
in external object,
the constantness is always variable, even if arguments are constant, because they should be called during
runtime and not during compiletime."
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.Const inConst;
  input Absyn.Path funcName;
  output FCore.Cache outCache;
  output DAE.Const outConst;
algorithm
  (outCache,outConst) := matchcontinue(inCache,env,inConst,funcName)
  local Absyn.Path path;
    FCore.Cache cache;
    // External Object found, constructor call is not constant.
    case (cache,_,_, path)
      equation
        (cache,true) = isExternalObjectFunction(cache,env,path);
      then (cache,DAE.C_VAR());
    case (cache,_,_,_) then (cache,inConst);
  end matchcontinue;
end determineConstSpecialFunc;

public function isExternalObjectFunction
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  output FCore.Cache outCache;
  output Boolean res;
algorithm
  (outCache,res) := matchcontinue(inCache,inEnv,inPath)
    local
      FCore.Cache cache;
      FCore.Graph env_1,env;
      Absyn.Path path;
      list<SCode.Element> els;

    case (cache,env,path) equation
      (cache,SCode.CLASS(classDef = SCode.PARTS(elementLst = els)),_)
          = Lookup.lookupClass(cache, env, path, false);
      true = SCode.isExternalObject(els);
      then (cache,true);
    case (cache,_,path) equation
      "constructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,_,path) equation
      "destructor" = Absyn.pathLastIdent(path); then (cache,true);
    case (cache,_,_)  then (cache,false);
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
  input DAE.Dimensions inDims;
  input list<Slot> inSlotLst;
  input DAE.Properties inProperties;
  input Absyn.Info info;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outExp,outProperties) := matchcontinue (inExp,inDims,inSlotLst,inProperties,info)
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
      String foldName,resultName;
      list<DAE.ReductionIterator> riters;
      Absyn.ReductionIterType iterType;

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
    case (DAE.ARRAY(array = _),(dim :: ad),slots,DAE.PROP(tp,c),_)
      equation
        int_dim = Expression.dimensionSize(dim);
        _ = Types.simplifyType(Types.liftArray(tp, dim));
        vect_exp = vectorizeCallArray(inExp, int_dim, slots);
        tp = Types.liftArrayRight(tp, dim);
        (vect_exp_1,prop) = vectorizeCall(vect_exp, ad, slots, DAE.PROP(tp,c),info);
      then
        (vect_exp_1,prop);

    /* Multiple dimensions are possible to change to a reduction, like:
     * f(arr1,arr2) => array(f(x,y) thread for x in arr1, y in arr2)
     * f(mat1,mat2) => array(array(f(x,y) thread for x in arr1, y in arr2) thread for arr1 in mat1, arr2 in mat2
     */
    case (DAE.CALL(fn,es,attr),dim::ad,slots,prop as DAE.PROP(tp,c),_)
      equation
        (es,riters) = vectorizeCallUnknownDimension(es,slots,{},{},info);
        tp = Types.liftArrayRight(tp, dim);
        prop = DAE.PROP(tp,c);
        e = DAE.CALL(fn,es,attr);
        (e,prop) = vectorizeCall(e,ad,slots,prop,info); // Recurse...
        foldName = Util.getTempVariableIndex();
        resultName = Util.getTempVariableIndex();
        iterType = Util.if_(listLength(riters)>1,Absyn.THREAD(),Absyn.COMBINE());
        rinfo = DAE.REDUCTIONINFO(Absyn.IDENT("array"),iterType,tp,SOME(Values.ARRAY({},{0})),foldName,resultName,NONE());
        e = DAE.REDUCTION(rinfo,e,riters);
      then (e,prop);

    /* Scalar expression, non-constant but known dimensions */
    case (DAE.CALL(path = _),(DAE.DIM_EXP(exp=dimexp) :: _),_,DAE.PROP(_,_),_)
      equation
        str = "Cannot vectorize call with dimensions [" +& ExpressionDump.dimensionsString(inDims) +& "]";
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},info);
      then
        fail();

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
  input list<DAE.ReductionIterator> found;
  input Absyn.Info info;
  output list<DAE.Exp> oes;
  output list<DAE.ReductionIterator> ofound;
algorithm
  (oes,ofound) := match (inEs,inSlots,inAcc,found,info)
    local
      DAE.Exp e,e1,e2;
      String s1,s2;
      list<DAE.Exp> es;
      list<Slot> slots;
      list<DAE.Exp> acc;
      String name;
      DAE.Type ty,tp;
      DAE.ReductionIterator riter;
    case ({},{},_,{},_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"Static.vectorizeCallUnknownDimension could not find any slot to vectorize"},info);
      then fail();
    case ({},{},acc,_,_) then (listReverse(acc),listReverse(found));
    case (e::es,SLOT(dims={})::slots,acc,_,_)
      equation
        (oes,ofound) = vectorizeCallUnknownDimension(es,slots,e::acc,found,info);
      then (oes,ofound);
    case (e::es,SLOT(defaultArg=DAE.FUNCARG(ty=ty))::slots,acc,_,_)
      equation
        name = Util.getTempVariableIndex();
        tp = Types.expTypetoTypesType(Expression.typeof(e)); // Maybe raise the type from the SLOT instead?
        riter = DAE.REDUCTIONITER(name,e,NONE(),tp);
        (oes,ofound) = vectorizeCallUnknownDimension(es,slots,DAE.CREF(DAE.CREF_IDENT(name,ty,{}),ty)::acc,riter::found,info);
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
    case (DAE.ARRAY(ty = tp,array = expl),cur_dim,slots) /* cur_dim */
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
    case ({},_,_,_) then {};
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
    case ((e as DAE.ARRAY(ty = _)),_,cur_dim,slots)
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

    else
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
    case (expl,slots,cur_dim,dim,DAE.CALL(fn,_,attr))
      equation
        (cur_dim <= dim) = true;
        callargs = vectorizeCallScalar3(expl, slots, cur_dim);

        cur_dim_1 = cur_dim + 1;
        res = vectorizeCallScalar2(expl, slots, cur_dim_1, dim, inExp5);
      then
        (DAE.CALL(fn,callargs,attr) :: res);
    else {};
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
    case ((e :: es),(SLOT(dims = {}) :: ss),dim_indx)
      equation
        res = vectorizeCallScalar3(es, ss, dim_indx);
      then
        (e :: res);

    // foreach argument
    case ((e :: es),(SLOT(dims = (_ :: _)) :: ss),dim_indx)
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
  input FCore.Graph inEnv;
  output Absyn.Path outPath;
  output DAE.Type outType;
algorithm
  (outPath,outType) := matchcontinue (inPath,inType,inEnv)
    local
      Absyn.Path fn;
      String name;
      DAE.Type tty;

    case (_,DAE.T_FUNCTION(functionAttributes = DAE.FUNCTION_ATTRIBUTES(isBuiltin=DAE.FUNCTION_BUILTIN(SOME(name)))), _)
      equation
        fn = Absyn.IDENT(name);
        tty = Types.setTypeSource(inType,Types.mkTypeSource(SOME(fn)));
      then (fn,tty);

    case (_,DAE.T_FUNCTION(funcArg = _, source = {fn}), _)
      then (fn,inType);

    else (inPath,inType);
  end matchcontinue;
end deoverloadFuncname;

protected function elabTypes "
function: elabTypes
   Elaborate input parameters to a function and
   select matching function type from a list of types."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<DAE.Type> inTypesTypeLst;
  input Boolean onlyOneFunction "if true, we can report errors as soon as possible";
  input Boolean checkTypes "if True, checks types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Const> outTypesConstLst2;
  output DAE.Type outType3;
  output DAE.Type outType4;
  output DAE.Dimensions outTypesArrayDimLst5;
  output list<Slot> outSlotLst6;
algorithm
  (outCache,outExpExpLst1,outTypesConstLst2,outType3,outType4,outTypesArrayDimLst5,outSlotLst6):=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inTypesTypeLst,onlyOneFunction,checkTypes,impl,isExternalObject,st,inPrefix,info)
    local
      list<Slot> slots,newslots;
      list<DAE.Exp> args_1;
      list<DAE.Const> clist;
      DAE.Dimensions dims;
      FCore.Graph env;
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> nargs;
      DAE.Type funcType,t,restype;
      list<DAE.FuncArg> params;
      list<DAE.Type> trest;
      FCore.Cache cache;
      InstTypes.PolymorphicBindings polymorphicBindings;
      Prefix.Prefix pre;
      DAE.FunctionAttributes functionAttributes;
      DAE.TypeSource ts;

    // We found a match.
    case (cache,env,args,nargs,(funcType as DAE.T_FUNCTION(funcArg=params, funcResultType=restype, functionAttributes=functionAttributes, source=ts))::_,_,_,_,_,_,pre,_)
      equation
        slots = makeEmptySlots(params);
        (cache,args_1,newslots,clist,polymorphicBindings) = elabInputArgs(cache, env, args, nargs, slots, onlyOneFunction, checkTypes, impl, isExternalObject,{},st,pre,info,funcType,Util.makeValueOrDefault(List.first,ts,Absyn.IDENT("builtinFunction")));
        // Check the sanity of function parameters whose types are dependent on other parameters.
        // e.g. input Integer i; input Integer a[i];  // type of 'a' depends on te value 'i'
        (params, restype) = applyArgTypesToFuncType(newslots, params, restype, env, checkTypes, info);
        dims = slotsVectorizable(newslots, info);
        polymorphicBindings = Types.solvePolymorphicBindings(polymorphicBindings,info,ts);
        restype = Types.fixPolymorphicRestype(restype, polymorphicBindings, info);
        t = DAE.T_FUNCTION(params,restype,functionAttributes,ts);
        t = createActualFunctype(t,newslots,checkTypes) "only created when not checking types for error msg";
      then
        (cache,args_1,clist,restype,t,dims,newslots);

    // We didn't find a match, try next function type
    case (cache,env,args,nargs,t::trest,_,_,_,_,_,pre,_)
      equation
        (cache,args_1,clist,restype,t,dims,slots) = elabTypes(cache, env, args, nargs, trest, onlyOneFunction, checkTypes, impl, isExternalObject, st, pre, info);
      then
        (cache,args_1,clist,restype,t,dims,slots);

    // failtrace
    case (_,_,_,_,t::_,_,_,_,_,_,_,_)
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
  input FCore.Graph inEnv;
  input Boolean checkTypes; // If not checking types no need to do any of this. In and out.
  input Absyn.Info inInfo;
  output list<DAE.FuncArg> outParameters;
  output DAE.Type outResultType;
algorithm
  (outParameters, outResultType) :=
  matchcontinue(inSlots, inParameters, inResultType, inEnv, checkTypes, inInfo)
    local
      FCore.Graph env;
      FCore.Cache cache;
      list<DAE.Var> vars;
      SCode.Element dummy_var;
      DAE.Type res_ty;
      list<DAE.FuncArg> params;
      list<String> used_args;
      list<DAE.Type> tys;
      list<DAE.Dimension> dims;
      list<Slot> used_slots;

    // If not checking types there is nothing to be done here.
    // Even if dims don't match we need the function as candidate for error messages.
    case (_, _, _, _, false, _) then (inParameters, inResultType);

    // some optimizations so we don't do all that below
    case ({}, {}, _, _, _, _) then ({}, inResultType);

    // get all the dims, bind the actual params to the formal params
    // build a new env frame with these bindings and evaluate dimensions
    else
      equation
        // Extract all dimensions from the parameters.
        tys = List.map(inParameters, Types.funcArgType);
        dims = getAllOutputDimensions(inResultType);
        dims = listAppend(List.mapFlat(tys, Types.getDimensions), dims);
        // Use the dimensions to figure out which parameters are referenced by
        // other parameters' dimensions. This is done to minimize the things we
        // need to constant evaluate, a.k.a. 'things that go wrong'.
        used_args = extractNamesFromDims(dims, {});
        used_slots = List.filter1OnTrue(inSlots, isSlotUsed, used_args);

        // Create DAE.Vars from the slots.
        cache = FCore.noCache();

        vars = List.map2(used_slots, makeVarFromSlot, inEnv, cache);

        // Use a dummy SCode.Element, because we're only interested in the DAE.Vars.
        dummy_var = SCode.COMPONENT("dummy", SCode.defaultPrefixes,
          SCode.defaultVarAttr, Absyn.TPATH(Absyn.IDENT(""), NONE()),
          SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

        // Create a new implicit scope with the needed parameters on top
        // of the current env so we can find the bindings if needed.
        // We need an implicit scope so comp1.comp2 can be looked up without package constant restriction
        env = FGraph.openScope(inEnv, SCode.NOT_ENCAPSULATED(), SOME(FCore.forScopeName), NONE());

        // add variables to the environment
        env = makeDummyFuncEnv(env, vars, dummy_var);
        // Evaluate the dimensions in the types.
        params = List.threadMap3(inSlots,inParameters, evaluateFuncParamDimAndMatchTypes, env, cache, inInfo);

        res_ty = evaluateFuncArgTypeDims(inResultType, env, cache);
      then
        (params, res_ty);

  end matchcontinue;
end applyArgTypesToFuncType;

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
  SLOT(defaultArg = DAE.FUNCARG(name=slot_name)) := inSlot;
  outIsUsed := List.isMemberOnTrue(slot_name, inUsedNames, stringEq);
end isSlotUsed;

protected function makeVarFromSlot
  "Converts a Slot to a DAE.Var."
  input Slot inSlot;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  output DAE.Var outVar;
algorithm
  outVar := matchcontinue (inSlot, inEnv, inCache)
    local
      DAE.Ident name;
      DAE.Type ty;
      DAE.Exp exp;
      DAE.Binding binding;
      Values.Value val;
      DAE.FuncArg defaultArg;
      Boolean slotFilled;
      DAE.Dimensions dims;
      Integer idx;
      DAE.Var var;

    // If the argument expression already has known dimensions, no need to
    // constant evaluate it.
    case (SLOT(defaultArg = DAE.FUNCARG(name=name), arg = SOME(exp)), _, _)
      equation
        false = Expression.expHasCref(exp,ComponentReference.makeCrefIdent(name,DAE.T_UNKNOWN_DEFAULT,{}));
        ty = Expression.typeof(exp);
        true = Types.dimensionsKnown(ty);
        binding = DAE.EQBOUND(exp, NONE(), DAE.C_CONST(), DAE.BINDING_FROM_DEFAULT_VALUE());
      then (DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, binding, NONE()));

    // Otherwise, try to constant evaluate the expression.
    case (SLOT(defaultArg = DAE.FUNCARG(name=name), arg = SOME(exp)), _, _)
      equation
        // Constant evaluate the bound expression.
        (_, val, _) = Ceval.ceval(inCache, inEnv, exp, false, NONE(), Absyn.NO_MSG(), 0);
        exp = ValuesUtil.valueExp(val);
        ty = Expression.typeof(exp);
        // Create a binding from the evaluated expression.
        binding = DAE.EQBOUND(exp, SOME(val), DAE.C_CONST(), DAE.BINDING_FROM_DEFAULT_VALUE());
      then DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, binding, NONE());

    case (SLOT(defaultArg = DAE.FUNCARG(name=name, ty=ty)), _, _)
      then (DAE.TYPES_VAR(name, DAE.dummyAttrParam, ty, DAE.UNBOUND(), NONE()));

  end matchcontinue;
end makeVarFromSlot;

protected function evaluateStructuralSlots2
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Slot> inSlots;
  input list<String> usedSlots;
  input list<Slot> acc;
  output FCore.Cache cache;
  output list<Slot> slots;
algorithm
  (cache,slots) := matchcontinue (inCache,inEnv,inSlots,usedSlots,acc)
    local
      String name;
      Boolean slotFilled;
      DAE.Exp exp;
      Slot slot;
      list<Slot> rest;
      DAE.FuncArg defaultArg;
      list<DAE.Dimension> dims;
      Integer idx;
      Values.Value val;
      DAE.Type ty;
      DAE.Binding binding;
    case (_,_,{},_,_) then (inCache,listReverse(acc));

    case (_,_,slot::rest,_,_)
      equation
        false = isSlotUsed(slot, usedSlots);
        (cache,slots) = evaluateStructuralSlots2(inCache,inEnv,rest,usedSlots,slot::acc);
      then (cache,slots);

      // If we are suggested the argument is structural, evaluate it
    case (_,_,SLOT(defaultArg as DAE.FUNCARG(name=name), slotFilled, SOME(exp), dims, idx)::rest, _, _)
      equation
        // Constant evaluate the bound expression.
        (cache, val, _) = Ceval.ceval(inCache, inEnv, exp, false, NONE(), Absyn.NO_MSG(), 0);
        exp = ValuesUtil.valueExp(val);
        ty = Expression.typeof(exp);
        // Create a binding from the evaluated expression.
        binding = DAE.EQBOUND(exp, SOME(val), DAE.C_CONST(), DAE.BINDING_FROM_DEFAULT_VALUE());
        slot = SLOT(defaultArg,true,SOME(exp),dims,idx);
        (cache,slots) = evaluateStructuralSlots2(cache,inEnv,rest,usedSlots,slot::acc);
      then (cache,slots);
    case (_,_,slot::rest,_,_)
      equation
        (cache,slots) = evaluateStructuralSlots2(inCache,inEnv,rest,usedSlots,slot::acc);
      then (cache,slots);
  end matchcontinue;
end evaluateStructuralSlots2;

protected function evaluateStructuralSlots
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Slot> inSlots;
  input DAE.Type funcType;
  output FCore.Cache cache;
  output list<Slot> slots;
algorithm
  (cache,slots) := match (inCache,inEnv,inSlots,funcType)
    local
      list<DAE.Type> tys;
      list<DAE.Dimension> dims;
      list<String> used_args;
      list<DAE.FuncArg> funcArg;
      DAE.Type funcResultType;
    case (_,_,_,DAE.T_FUNCTION(funcArg=funcArg,funcResultType=funcResultType))
      equation
        tys = List.map(funcArg, Types.funcArgType);
        dims = getAllOutputDimensions(funcResultType);
        dims = listAppend(List.mapFlat(tys, Types.getDimensions), dims);
        // Use the dimensions to figure out which parameters are referenced by
        // other parameters' dimensions. This is done to minimize the things we
        // need to constant evaluate, a.k.a. 'things that go wrong'.
        used_args = extractNamesFromDims(dims, {});
        (cache,slots) = evaluateStructuralSlots2(inCache,inEnv,inSlots,used_args,{});
      then (cache,slots);
    else (inCache,inSlots); // T_METARECORD, T_NOTYPE etc for builtins
  end match;
end evaluateStructuralSlots;

protected function makeDummyFuncEnv
  "Helper function to applyArgTypesToFuncType, creates a dummy function
   environment."
  input FCore.Graph inEnv;
  input list<DAE.Var> inVars;
  input SCode.Element inDummyVar;
  output FCore.Graph outEnv;
algorithm
  outEnv := match(inEnv, inVars, inDummyVar)
    local
      DAE.Var var;
      list<DAE.Var> rest_vars;
      FCore.Graph env;
      SCode.Element dummyVar;

    case (_, var :: rest_vars, _)
      equation
        dummyVar = SCode.setComponentName(inDummyVar, DAEUtil.typeVarIdent(var));
        env = FGraph.mkComponentNode(inEnv, var, dummyVar, DAE.NOMOD(),
          FCore.VAR_TYPED(), FGraph.empty());
      then
        makeDummyFuncEnv(env, rest_vars, inDummyVar);

    case (_, {}, _) then inEnv;

  end match;
end makeDummyFuncEnv;


protected function evaluateFuncParamDimAndMatchTypes
  "Constant evaluates the dimensions of a FuncArg and then makes
  sure the type matches with the expected type in the slot."
  input Slot inSlot;
  input DAE.FuncArg inParam;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  input Absyn.Info inInfo;
  output DAE.FuncArg outParam;
algorithm
  outParam := matchcontinue(inSlot, inParam, inEnv, inCache, inInfo)
  local
    DAE.Ident ident;
    DAE.Type pty, sty;
    DAE.Const c;
    DAE.VarParallelism p;
    Option<DAE.Exp> oexp;
    DAE.Dimensions dims1, dims2;
    String t_str1,t_str2;
    DAE.Dimensions vdims;
    Boolean b;


    // If we have a code exp argument we can't check dims...
    // There are all kinds of scripting function that complicate things.
    case(_, DAE.FUNCARG(ty=DAE.T_CODE(_,_)), _, _, _)
      then
        inParam;

    // If we have an array constant-evaluate the dimensions and make sure
    // They add up
    case(SLOT(arg = SOME(DAE.ARRAY(ty = sty)), dims = vdims), _, _, _, _)
      equation
        DAE.FUNCARG(ty=pty) = inParam;
        // evaluate the dimesions
        pty = evaluateFuncArgTypeDims(pty, inEnv, inCache);
        // append the vectorization dim if argument is vectorized.
        dims1 = Types.getDimensions(pty);
        dims1 = listAppend(vdims,dims1);

        dims2 = Types.getDimensions(sty);
        true = Expression.dimsEqual(dims1, dims2);

        outParam = Types.setFuncArgType(inParam, pty);
      then
        outParam;

    case(SLOT(arg = SOME(DAE.MATRIX(ty = sty)), dims = vdims), _, _, _, _)
      equation
        DAE.FUNCARG(ty=pty) = inParam;
        // evaluate the dimesions
        pty = evaluateFuncArgTypeDims(pty, inEnv, inCache);
        // append the vectorization dim if argument is vectorized.
        dims1 = Types.getDimensions(pty);
        dims1 = listAppend(dims1,vdims);
        dims2 = Types.getDimensions(sty);
        true = Expression.dimsEqual(dims1, dims2);

        outParam = Types.setFuncArgType(inParam, pty);
      then
        outParam;

    else
      equation
        failure(SLOT(arg = SOME(DAE.ARRAY(ty = _))) = inSlot);
        failure(SLOT(arg = SOME(DAE.MATRIX(ty = _))) = inSlot);
        DAE.FUNCARG(ty=pty) = inParam;
        pty = evaluateFuncArgTypeDims(pty, inEnv, inCache);
        outParam = Types.setFuncArgType(inParam, pty);
      then
        outParam;

  end matchcontinue;
end evaluateFuncParamDimAndMatchTypes;

protected function evaluateFuncArgTypeDims
  "Constant evaluates the dimensions of a type."
  input DAE.Type inType;
  input FCore.Graph inEnv;
  input FCore.Cache inCache;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType, inEnv, inCache)
    local
      DAE.Type ty;
      DAE.TypeSource ts;
      Integer n;
      DAE.Dimension dim;
      list<DAE.Type> tys;
      FCore.Graph env;

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
    case(DAE.T_FUNCTION(_,restype,functionAttributes,ts),_,false)
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
  input Absyn.Info info;
  output DAE.Dimensions outTypesArrayDimLst;
algorithm
  outTypesArrayDimLst:=
  matchcontinue (inSlotLst,info)
    local
      DAE.Dimensions ad;
      list<Slot> rest;
      DAE.Exp exp;
      String name;
    case ({},_) then {};
    case ((SLOT(defaultArg = DAE.FUNCARG(name=name), arg = SOME(exp), dims = (ad as (_ :: _))) :: rest),_)
      equation
        sameSlotsVectorizable(rest, ad, name, exp, info);
      then
        ad;
    case ((SLOT(dims = {}) :: rest),_)
      equation
        ad = slotsVectorizable(rest, info);
      then
        ad;
    else
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
  input String name;
  input DAE.Exp exp;
  input Absyn.Info info;
algorithm
  _:=
  match (inSlotLst,inTypesArrayDimLst, name, exp, info)
    local
      DAE.Dimensions slot_ad,ad;
      list<Slot> rest;
      DAE.Exp exp2;
      String name2;
    case ({},_,_,_,_) then ();
    case ((SLOT(defaultArg = DAE.FUNCARG(name=name2), arg = SOME(exp2), dims = (slot_ad as (_ :: _))) :: rest),ad,_,_,_) /* arraydim must match */
      equation
        sameArraydimLst(ad, name, exp, slot_ad, name2, exp2, info);
        sameSlotsVectorizable(rest, ad, name, exp, info);
      then
        ();
    case ((SLOT(dims = {}) :: rest),ad,_,_,_) /* empty arradim matches too */
      equation
        sameSlotsVectorizable(rest, ad, name, exp, info);
      then
        ();
  end match;
end sameSlotsVectorizable;

protected function sameArraydimLst
"author: PA
  Helper function to sameSlotsVectorizable. "
  input DAE.Dimensions inTypesArrayDimLst1;
  input String name1;
  input DAE.Exp exp1;
  input DAE.Dimensions inTypesArrayDimLst2;
  input String name2;
  input DAE.Exp exp2;
  input Absyn.Info info;
algorithm
  _:=
  matchcontinue (inTypesArrayDimLst1,name1,exp1,inTypesArrayDimLst2,name2,exp2,info)
    local
      Integer i1,i2;
      DAE.Dimensions ads1,ads2;
      DAE.Exp e1,e2;
      DAE.Dimension ad1,ad2;
      String str1,str2,str3,str4,str;
    case ({},_,_,{},_,_,_) then ();
    case ((DAE.DIM_INTEGER(integer = i1) :: ads1),_,_,(DAE.DIM_INTEGER(integer = i2) :: ads2),_,_,_)
      equation
        true = intEq(i1, i2);
        sameArraydimLst(ads1, name1, exp1, ads2, name2, exp2, info);
      then
        ();
    case (DAE.DIM_UNKNOWN() :: ads1,_,_,DAE.DIM_UNKNOWN() :: ads2,_,_,_)
      equation
        sameArraydimLst(ads1, name1, exp1, ads2, name2, exp2, info);
      then
        ();
    case (DAE.DIM_EXP(e1) :: ads1,_, _, DAE.DIM_EXP(e2) :: ads2, _, _, _)
      equation
        true = Expression.expEqual(e1,e2);
        sameArraydimLst(ads1, name1, exp1, ads2, name2, exp2, info);
      then
        ();
    case (ad1 :: _, _, _, ad2 :: _, _, _, _)
      equation
        str1 = ExpressionDump.printExpStr(exp1);
        str2 = ExpressionDump.printExpStr(exp2);
        str3 = ExpressionDump.dimensionString(ad1);
        str4 = ExpressionDump.dimensionString(ad2);
        Error.addSourceMessage(Error.VECTORIZE_CALL_DIM_MISMATCH, {name1,str1,name2,str2,str3,str4}, info);
      then fail();
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
  outTypesTupleConstLst := match (inTypesConstLst)
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
  end match;
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

    case (DAE.T_TUPLE(tupleType = _),_)
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
  outTypesTypeLst := List.map(farg,Types.funcArgType);
end getTypes;

/*
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

    case ((DAE.TYPES_VAR(attributes = DAE.ATTR(visibility = SCode.PROTECTED())) :: vs)) // Ignore protected components
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
*/

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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input DAE.Type funcType "Used to determine which arguments are structural. We will evaluate them later to figure if they are used in dimensions. So we evaluate them here to get a more optimised DAE";
  input Absyn.Path path;
  output FCore.Cache outCache;
  output list<DAE.Exp> outExps;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outExps,outSlotLst,outTypesConstLst,outPolymorphicBindings):=
  match (inCache,inEnv,inAbsynExpLst,inAbsynNamedArgLst,inSlotLst,onlyOneFunction,checkTypes,impl,isExternalObject,inPolymorphicBindings,st,inPrefix,info,funcType,path)
    local
      list<DAE.FuncArg> farg;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist1,clist2,clist;
      list<DAE.Exp> explst,newexp;
      FCore.Graph env;
      list<Absyn.Exp> exp;
      list<Absyn.NamedArg> narg;
      FCore.Cache cache;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;

    // impl const Fill slots with positional arguments
    case (cache,env,(exp as (_ :: _)),narg,slots,_,_,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        farg = funcArgsFromSlots(slots);
        (cache,slots_1,clist1,polymorphicBindings) =
          elabPositionalInputArgs(cache, env, exp, farg, 1, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info,path);
        (cache,explst,newslots,clist2,polymorphicBindings) =
          elabInputArgs(cache, env, {}, narg, slots_1, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info,funcType,path)
          "recursive call fills named arguments" ;
        clist = listAppend(clist1, clist2);
      then
        (cache,explst,newslots,clist,polymorphicBindings);

    // Fill slots with named arguments
    case (cache,env,{},narg as _::_,slots,_,_,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        farg = funcArgsFromSlots(slots);
        (cache,newslots,clist,polymorphicBindings) =
          elabNamedInputArgs(cache, env, narg, farg, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings,st,pre,info,path);
        (cache,newslots) = evaluateStructuralSlots(cache,env,newslots,funcType);
        newexp = slotListArgs(newslots);
      then
        (cache,newexp,newslots,clist,polymorphicBindings);

    // Empty function call, e.g foo(), is always constant
    // arpo 2010-11-09: TODO! FIXME! this is not always true, RecordCall() can contain DEFAULT bindings that are par
    case (cache,env,{},{},slots,_,_,_,_,polymorphicBindings,_,_,_,_,_)
      equation
        (cache,slots) = evaluateStructuralSlots(cache,env,slots,funcType);
        newexp = slotListArgs(slots);
      then (cache,newexp,slots,{DAE.C_CONST()},polymorphicBindings);

    // fail trace
    else
      /* FAILTRACE REMOVE equation Debug.fprint(Flags.FAILTRACE,"elabInputArgs failed\n"); */
      then fail();
  end match;
end elabInputArgs;

protected function makeEmptySlots
  "Creates a list of empty slots given a list of function parameters."
  input list<DAE.FuncArg> inArgs;
  output list<Slot> outSlots;
algorithm
  (outSlots, _) := List.mapFold(inArgs, makeEmptySlot, 1);
end makeEmptySlots;

protected function makeEmptySlot
  input DAE.FuncArg inArg;
  input Integer inIndex;
  output Slot outSlot;
  output Integer outIndex;
algorithm
  outSlot := SLOT(inArg, false, NONE(), {}, inIndex);
  outIndex := inIndex + 1;
end makeEmptySlot;

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
  SLOT(defaultArg = outFuncArg) := inSlot;
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
        _ = ClassInf.getStateName(complexClassType);
      then
        DAE.T_COMPLEX(complexClassType, {}, NONE(), DAE.emptyTypeSource);

    case(SLOT(defaultArg = DAE.FUNCARG(name=id,ty=ty))::slots,_)
      equation
        etp = Types.simplifyType(ty);
        DAE.T_COMPLEX(ci,vLst,ec,ts) = complexTypeFromSlots(slots,complexClassType);
        tv = Expression.makeVar(id,etp);
      then
        DAE.T_COMPLEX(ci, tv::vLst, ec, ts);

  end match;
end complexTypeFromSlots;

protected function slotListArgs
  "Gets the argument expressions from a list of slots."
  input list<Slot> inSlots;
  output list<DAE.Exp> outArgs;
algorithm
  outArgs := List.filterMap(inSlots, slotArg);
end slotListArgs;

protected function slotArg
  "Gets the argument from a slot."
  input Slot inSlot;
  output DAE.Exp outArg;
algorithm
  SLOT(arg = SOME(outArg)) := inSlot;
end slotArg;

protected function fillGraphicsDefaultSlots
  "This function takes a slot list and a class definition of a function
  and fills  default values into slots which have not been filled.

  Special case for graphics exps"
  input FCore.Cache inCache;
  input list<Slot> inSlotLst;
  input SCode.Element inClass;
  input FCore.Graph inEnv;
  input Boolean inBoolean;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Boolean impl;
      Absyn.Exp dexp;
      DAE.Exp exp,exp_1;
      DAE.Type t,tp;
      DAE.Const c1,c2;
      DAE.VarParallelism pr;
      list<DAE.Const> constLst;
      String id;
      FCore.Cache cache;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;
      Integer idx;

    case (cache,(SLOT(fa, true, e as SOME(_), ds, idx) :: xs),class_,env,impl,polymorphicBindings,pre,_)
      equation
        (cache, res, constLst, polymorphicBindings) = fillGraphicsDefaultSlots(cache, xs, class_, env, impl, polymorphicBindings, pre, info);
      then
        (cache, SLOT(fa,true,e,ds,idx) :: res, constLst, polymorphicBindings);

    case (cache,(SLOT(DAE.FUNCARG(id,tp,c2,pr,e), false, NONE(), ds, idx) :: xs),class_,env,impl,polymorphicBindings,pre,_)
      equation
        (cache,res,constLst,polymorphicBindings) = fillGraphicsDefaultSlots(cache, xs, class_, env, impl, polymorphicBindings, pre, info);

        SCode.COMPONENT(modifications = SCode.MOD(binding = SOME((dexp,_)))) = SCode.getElementNamed(id, class_);

        (cache,exp,DAE.PROP(t,c1),_) = elabExpInExpression(cache, env, dexp, impl, NONE(), true, pre, info);
        // print("Slot: " +& id +& " -> " +& Exp.printExpStr(exp) +& "\n");
        (exp_1,_,polymorphicBindings) = Types.matchTypePolymorphic(exp,t,tp,FGraph.getGraphPathNoImplicitScope(env),polymorphicBindings,false);
        true = Types.constEqualOrHigher(c1,c2);
      then
        (cache, SLOT(DAE.FUNCARG(id,tp,c2,pr,e),true,SOME(exp_1),ds,idx) :: res, c1::constLst, polymorphicBindings);

    case (cache,(SLOT(fa, false, e, ds, idx) :: xs),class_,env,impl,polymorphicBindings,pre,_)
      equation
        (cache, res, constLst, polymorphicBindings) = fillGraphicsDefaultSlots(cache, xs, class_, env, impl, polymorphicBindings, pre, info);
      then
        (cache,SLOT(fa,false,e,ds,idx) :: res, constLst, polymorphicBindings);


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
    case ((SLOT(defaultArg = farg,slotFilled = filled,arg = exp,dims = ds) :: xs))
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Exp inExp;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input Integer position;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean inBoolean;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Absyn.Path path;
  output FCore.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings):=
  match (inCache,inEnv,inAbsynExpLst,inTypesFuncArgLst,position,inSlotLst,onlyOneFunction,checkTypes,inBoolean,isExternalObject,inPolymorphicBindings,st,inPrefix,info,path)
    local
      list<Slot> slots,slots_1,newslots;
      Boolean impl;
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1,c2;
      DAE.VarParallelism pr;
      list<DAE.Const> clist;
      FCore.Graph env;
      Absyn.Exp e;
      list<Absyn.Exp> es;
      DAE.FuncArg farg;
      list<DAE.FuncArg> vs;
      DAE.Dimensions ds;
      FCore.Cache cache;
      String id;
      DAE.Properties props;
      Prefix.Prefix pre;
      DAE.CodeType ct;
      InstTypes.PolymorphicBindings polymorphicBindings;

    // the empty case
    case (cache, _, {}, _, _, slots, _, _, _, _, polymorphicBindings,_,_,_,_)
      then (cache,slots,{},polymorphicBindings);

    case (cache, env, e :: es, farg :: vs, _, slots, _, _, impl, _, polymorphicBindings,_,pre,_,_)
      equation
        (cache,slots,c1,polymorphicBindings) =
        elabPositionalInputArg(cache, env, e, farg, position, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings, st, pre, info,path,Error.getNumErrorMessages());
        (cache,slots,clist,polymorphicBindings) =
        elabPositionalInputArgs(cache, env, es, vs, position+1, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings, st, pre, info,path);
      then
        (cache,slots,c1::clist,polymorphicBindings);

  end match;
end elabPositionalInputArgs;

protected function elabPositionalInputArg
"This function elaborates the positional input arguments of a function.
  A list of slots is filled from the beginning with types of each
  positional argument."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Exp inExp;
  input DAE.FuncArg farg;
  input Integer position;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Absyn.Path path;
  input Integer numErrors;
  output FCore.Cache outCache;
  output list<Slot> outSlotLst;
  output DAE.Const outConst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outConst,outPolymorphicBindings):=
  matchcontinue (inCache,inEnv,inExp,farg,position,inSlotLst,onlyOneFunction,checkTypes,impl,isExternalObject,inPolymorphicBindings,st,inPrefix,info,path,numErrors)
    local
      list<Slot> slots,slots_1,newslots;
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1,c2;
      DAE.VarParallelism pr;
      DAE.Properties prop;
      list<DAE.Const> clist;
      FCore.Graph env;
      Absyn.Exp e;
      list<Absyn.Exp> es;
      list<DAE.FuncArg> vs;
      DAE.Dimensions ds;
      FCore.Cache cache;
      String id;
      DAE.Properties props;
      Prefix.Prefix pre;
      DAE.CodeType ct;
      InstTypes.PolymorphicBindings polymorphicBindings;
      String s1,s2,s3,s4,s5;

    case (cache, env, e, DAE.FUNCARG(name=id,ty = vt as DAE.T_CODE(ct,_),par=pr), _, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        e_1 = elabCodeExp(e,cache,env,ct,st,info);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,DAE.C_VAR(),pr,NONE()), e_1, {}, slots,checkTypes,pre,info);
      then
        (cache,slots_1,DAE.C_VAR(),polymorphicBindings);

    // exact match
    case (cache, env, e, DAE.FUNCARG(name=id,ty=vt,par=pr), _, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (cache,e_1,props,_) = elabExpInExpression(cache,env, e, impl,st, true,pre,info);
        t = Types.getPropType(props);
        ((vt, _)) = Types.traverseType((vt, -1), Types.makeExpDimensionsUnknown);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, vt, c1, cache, env, e_1, info);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,FGraph.getGraphPathNoImplicitScope(env),polymorphicBindings,false);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, {}, slots,checkTypes,pre,info) "no vectorized dim" ;
      then
        (cache,slots_1,c1,polymorphicBindings);

    // check if vectorized argument
    case (cache, env, e, DAE.FUNCARG(name=id,ty=vt,par=pr), _, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (cache,e_1,props,_) = elabExpInExpression(cache,env, e, impl,st,true,pre,info);
        t = Types.getPropType(props);
        ((vt, _)) = Types.traverseType((vt, -1), Types.makeExpDimensionsUnknown);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, vt, c1, cache, env, e_1, info);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt, FGraph.getGraphPathNoImplicitScope(env));
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, ds, slots, checkTypes,pre,info);
      then
        (cache,slots_1,c1,polymorphicBindings);

    // not checking types
    case (cache, env, e, DAE.FUNCARG(name=id,par=pr), _, slots, _, false, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (cache,e_1,props,_) = elabExpInExpression(cache,env, e, impl,st,true,pre,info);
        t = Types.getPropType(props);
        c1 = Types.propAllConst(props);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        /* fill slot with actual type for error message*/
        slots_1 = fillSlot(DAE.FUNCARG(id,t,c1,pr,NONE()), e_1, {}, slots, checkTypes,pre,info);
      then
        (cache,slots_1,c1,polymorphicBindings);

    // check types and display error
    case (cache,env,e,DAE.FUNCARG(name=id,ty=vt),_,_, true /* 1 function */,true /* checkTypes */,_,_,_,_,pre,_,_,_)
      equation
        true = Error.getNumErrorMessages() == numErrors;
        (cache,e_1,prop,_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        s1 = intString(position);
        s2 = Absyn.pathStringNoQual(path);
        s3 = ExpressionDump.printExpStr(e_1);
        s4 = Types.unparseTypeNoAttr(Types.getPropType(prop));
        s5 = Types.unparseTypeNoAttr(vt);
        Error.addSourceMessage(Error.ARG_TYPE_MISMATCH, {s1,s2,id,s3,s4,s5}, info);
      then fail();

  end matchcontinue;
end elabPositionalInputArg;

protected function elabNamedInputArgs
"This function takes an Env, a NamedArg list, a DAE.FuncArg list and a
  Slot list.
  It builds up a new slot list and a list of elaborated expressions.
  If a slot is filled twice the function fails. If a slot is not filled at
  all and the
  value is not a parameter or a constant the function also fails."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Absyn.Path path;
  output FCore.Cache outCache;
  output list<Slot> outSlotLst;
  output list<DAE.Const> outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings) :=
  match (inCache,inEnv,inAbsynNamedArgLst,inTypesFuncArgLst,inSlotLst,onlyOneFunction,checkTypes,impl,isExternalObject,inPolymorphicBindings,st,inPrefix,info,path)
    local
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1;
      DAE.VarParallelism pr;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist;
      FCore.Graph env;
      String id, pre_str;
      Absyn.Exp e;
      Absyn.NamedArg na;
      list<Absyn.NamedArg> nas,narg;
      list<DAE.FuncArg> farg;
      DAE.CodeType ct;
      FCore.Cache cache;
      DAE.Dimensions ds;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;

    // the empty case
    case (cache,_,{},_,slots,_,_,_,_,_,_,_,_,_)
      then (cache,slots,{},inPolymorphicBindings);

    case (cache, env, na :: nas, farg, slots, _, _, _, _, polymorphicBindings, _, _, _, _)
      equation
        (cache,slots,c1,polymorphicBindings) =
        elabNamedInputArg(cache, env, na, farg, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings, st, inPrefix, info, path, Error.getNumErrorMessages());
        (cache,slots,clist,polymorphicBindings) =
        elabNamedInputArgs(cache, env, nas, farg, slots, onlyOneFunction, checkTypes, impl, isExternalObject, polymorphicBindings, st, inPrefix, info, path);
      then
        (cache,slots,c1::clist,polymorphicBindings);

  end match;
end elabNamedInputArgs;

protected function elabNamedInputArg
"This function takes an Env, a NamedArg list, a DAE.FuncArg list and a
  Slot list.
  It builds up a new slot list and a list of elaborated expressions.
  If a slot is filled twice the function fails. If a slot is not filled at
  all and the
  value is not a parameter or a constant the function also fails."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.NamedArg inNamedArg;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  input list<Slot> inSlotLst;
  input Boolean onlyOneFunction;
  input Boolean checkTypes "if true, check types";
  input Boolean impl;
  input IsExternalObject isExternalObject;
  input InstTypes.PolymorphicBindings inPolymorphicBindings;
  input Option<GlobalScript.SymbolTable> st;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Absyn.Path path;
  input Integer numErrors;
  output FCore.Cache outCache;
  output list<Slot> outSlotLst;
  output DAE.Const outTypesConstLst;
  output InstTypes.PolymorphicBindings outPolymorphicBindings;
algorithm
  (outCache,outSlotLst,outTypesConstLst,outPolymorphicBindings) :=
  matchcontinue (inCache,inEnv,inNamedArg,inTypesFuncArgLst,inSlotLst,onlyOneFunction,checkTypes,impl,isExternalObject,inPolymorphicBindings,st,inPrefix,info,path,numErrors)
    local
      DAE.Exp e_1,e_2;
      DAE.Type t,vt;
      DAE.Const c1;
      DAE.VarParallelism pr;
      list<Slot> slots_1,newslots,slots;
      list<DAE.Const> clist;
      FCore.Graph env;
      String id, pre_str, str;
      Absyn.Exp e;
      list<Absyn.NamedArg> nas,narg;
      list<DAE.FuncArg> farg;
      DAE.CodeType ct;
      FCore.Cache cache;
      DAE.Dimensions ds;
      Prefix.Prefix pre;
      InstTypes.PolymorphicBindings polymorphicBindings;
      DAE.Properties prop;
      String s1,s2,s3,s4;

    case (cache, env, Absyn.NAMEDARG(argName = id,argValue = e), farg, slots, _, true, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        (vt as DAE.T_CODE(ty=ct)) = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        e_1 = elabCodeExp(e,cache,env,ct,st,info);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,DAE.C_VAR(),pr,NONE()), e_1, {}, slots,checkTypes,pre,info);
      then (cache,slots_1,DAE.C_VAR(),polymorphicBindings);

    // check types exact match
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,slots,_,true,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        vt = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        (cache,e_1,DAE.PROP(t,c1),_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        (e_2,_,polymorphicBindings) = Types.matchTypePolymorphic(e_1,t,vt,FGraph.getGraphPathNoImplicitScope(env),polymorphicBindings,false);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, {}, slots,checkTypes,pre,info);
      then (cache,slots_1,c1,polymorphicBindings);

    // check types vectorized argument
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,slots,_,true,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        vt = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        (cache,e_1,DAE.PROP(t,c1),_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        (e_2,_,ds,polymorphicBindings) = Types.vectorizableType(e_1, t, vt, FGraph.getGraphPathNoImplicitScope(env));
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_2, ds, slots, checkTypes,pre,info);
      then (cache,slots_1,c1,polymorphicBindings);

    // do not check types
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,slots,_,false,_,_,polymorphicBindings,_,pre,_,_,_)
      equation
        vt = findNamedArgType(id, farg);
        pr = findNamedArgParallelism(id,farg);
        (cache,e_1,DAE.PROP(t,c1),_) = elabExpInExpression(cache,env, e, impl,st,true,pre,info);
        (cache,e_1) = evalExternalObjectInput(isExternalObject, t, c1, cache, env, e_1, info);
        slots_1 = fillSlot(DAE.FUNCARG(id,vt,c1,pr,NONE()), e_1, {}, slots,checkTypes,pre,info);
      then (cache,slots_1,c1,polymorphicBindings);

    case (cache, env, Absyn.NAMEDARG(argName = id), farg, slots, true /* only 1 function */, _, _, _, polymorphicBindings,_,pre,_,_,_)
      equation
        failure(_ = findNamedArgType(id, farg));
        s1 = Absyn.pathStringNoQual(path);
        Error.addSourceMessage(Error.NO_SUCH_ARGUMENT, {s1,id}, info);
      then fail();

    // failure
    case (cache,env,Absyn.NAMEDARG(argName = id,argValue = e),farg,_,true /* 1 function */,true /* checkTypes */,_,_,_,_,pre,_,_,_)
      equation
        true = Error.getNumErrorMessages() == numErrors;
        vt = findNamedArgType(id, farg);
        (cache,e_1,prop,_) = elabExpInExpression(cache, env, e, impl,st, true,pre,info);
        s1 = Absyn.pathStringNoQual(path);
        s2 = ExpressionDump.printExpStr(e_1);
        s3 = Types.unparseTypeNoAttr(Types.getPropType(prop));
        s4 = Types.unparseTypeNoAttr(vt);
        Error.addSourceMessage(Error.NAMED_ARG_TYPE_MISMATCH, {s1,id,s2,s3,s4}, info);
      then fail();
  end matchcontinue;
end elabNamedInputArg;

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
    case (id,DAE.FUNCARG(name=id2,ty=ty) :: _)
      equation
        true = stringEq(id, id2);
      then
        ty;
    case (id,DAE.FUNCARG(name=id2) :: ts)
      equation
        false = stringEq(id, id2);
        ty = findNamedArgType(id, ts);
      then
        ty;
  end matchcontinue;
end findNamedArgType;

protected function findNamedArgParallelism
"This function takes an Ident and a FuncArg list, and returns the
  parallelism of the FuncArg which has  that identifier."
  input String inIdent;
  input list<DAE.FuncArg> inTypesFuncArgLst;
  output DAE.VarParallelism outParallelism;
algorithm
  outParallelism :=
  matchcontinue (inIdent,inTypesFuncArgLst)
    local
      String id,id2;
      DAE.VarParallelism pr;
      list<DAE.FuncArg> ts;
    case (id,DAE.FUNCARG(name=id2,par=pr) :: _)
      equation
        true = stringEq(id, id2);
      then
        pr;
    case (id,DAE.FUNCARG(name=id2) :: ts)
      equation
        false = stringEq(id, id2);
        pr = findNamedArgParallelism(id, ts);
      then
        pr;
  end matchcontinue;
end findNamedArgParallelism;

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
      DAE.VarParallelism prl;
      Option<DAE.Exp> oe;
      Integer idx;

    case (DAE.FUNCARG(name=fa1,ty=b,const=c1),exp,ds,(SLOT(defaultArg = DAE.FUNCARG(name=fa2,const=c2,par=prl,defaultBinding=oe),slotFilled = false,idx = idx) :: xs),_,_,_)
      equation
        true = stringEq(fa1, fa2);
        true = Types.constEqualOrHigher(c1,c2);
      then
        (SLOT(DAE.FUNCARG(fa2,b,c2,prl,oe),true,SOME(exp),ds,idx) :: xs);

    // fail if variability is wrong
    case (DAE.FUNCARG(name=fa1,const=c1),exp,_,(SLOT(defaultArg = DAE.FUNCARG(name=fa2,const=c2),slotFilled = false) :: _),_,_,_)
      equation
        true = stringEq(fa1, fa2);
        false = Types.constEqualOrHigher(c1,c2);
        str1 = ExpressionDump.printExpStr(exp);
        str2 = DAEUtil.constStrFriendly(c2);
        Error.addSourceMessage(Error.FUNCTION_SLOT_VARIABILITY, {fa1,str1,str2}, info);
      then
        fail();

    // fail if slot already filled
    case (DAE.FUNCARG(name=fa1),_,_,(SLOT(defaultArg = DAE.FUNCARG(name=fa2),slotFilled = true) :: _), _,pre,_)
      equation
        true = stringEq(fa1, fa2);
        ps = PrefixUtil.printPrefixStr3(pre);
        Error.addSourceMessage(Error.FUNCTION_SLOT_ALLREADY_FILLED, {fa2,ps}, info);
      then
        fail();

    // no equal, try next
    case ((farg as DAE.FUNCARG(name=fa1)),exp,ds,((s1 as SLOT(defaultArg = DAE.FUNCARG(name=fa2))) :: xs),_,pre,_)
      equation
        false = stringEq(fa1, fa2);
        newslots = fillSlot(farg, exp, ds, xs,checkTypes,pre,info);
      then
        (s1 :: newslots);

    // failure
    case (DAE.FUNCARG(name=fa),_,_,{},_,_,_)
      equation
        Error.addSourceMessage(Error.NO_SUCH_ARGUMENT, {"",fa}, info);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplict "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output Option<tuple<DAE.Exp,DAE.Properties,DAE.Attributes>> res;
algorithm
  (outCache,res) := elabCref1(inCache,inEnv,inComponentRef,inImplict,performVectorization,inPrefix,true,info);
end elabCref;

public function elabCrefNoEval "
  Some functions expect a DAE.ComponentRef back and use this instead of elabCref :)"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplict "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input Boolean inImplict "implicit instantiation";
  input Boolean performVectorization "true => generates vectorized expressions, {v[1],v[2],...}";
  input Prefix.Prefix inPrefix;
  input Boolean evalCref;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.ComponentRef c;
      FCore.Cache cache;
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

    // wildcard
    case (cache,_,Absyn.WILD(),_,_,_,_,_)
      equation
        t = DAE.T_ANYTYPE_DEFAULT;
        et = Types.simplifyType(t);
        crefExp = Expression.makeCrefExp(DAE.WILD(),et);
      then
        (cache,SOME((crefExp,DAE.PROP(t, DAE.C_VAR()),DAE.dummyAttrVar)));

    // Boolean => {false, true}
    case (cache, _, Absyn.CREF_IDENT(name = "Boolean"), _, _, _, _, _)
      equation
        exp = Expression.makeScalarArray({DAE.BCONST(false), DAE.BCONST(true)}, DAE.T_BOOL_DEFAULT);
        t = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
      then
        (cache, SOME((exp, DAE.PROP(t, DAE.C_CONST()), DAE.dummyAttrConst)));

    // MetaModelica arrays are only used in function context as IDENT, and at most one subscript
    // No vectorization is performed
    case (cache,env,Absyn.CREF_IDENT(name=id, subscripts={Absyn.SUBSCRIPT(e)}),impl,_,pre,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        (cache,SOME((exp1,DAE.PROP(DAE.T_METAARRAY(ty = t), const1),attr))) = elabCref1(cache,env,Absyn.CREF_IDENT(id,{}),false,false,pre,evalCref,info);
        (cache,exp2,DAE.PROP(DAE.T_INTEGER(varLst = _), const2),_) = elabExpInExpression(cache,env,e,impl,NONE(),false,pre,info);
        const = Types.constAnd(const1,const2);
        expASUB = Expression.makeASUB(exp1,{exp2});
      then
        (cache,SOME((expASUB,DAE.PROP(t, const),attr)));

    // a normal cref, fully-qualified and lookupVar failed in some weird way in the previous case
    case (cache,env,Absyn.CREF_FULLYQUALIFIED(c),impl,doVect,pre,_,_)
      equation
        c = replaceEnd(c);
        env = FGraph.topScope(env);
        (cache,c_1,constSubs,hasZeroSizeDim) = elabCrefSubs(cache, env, inEnv, c, pre, Prefix.NOPRE(), impl, false, info);
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

    // a normal cref
    case (cache,env,c,impl,doVect,pre,_,_)
      equation
        c = replaceEnd(c);
        (cache,c_1,constSubs,hasZeroSizeDim) = elabCrefSubs(cache, env, env, c, pre, Prefix.NOPRE(), impl, false, info);
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
    case (cache, env, c, _, _, _, _, _)
      equation
        c = replaceEnd(c);
        path = Absyn.crefToPath(c);
        (cache, cl as SCode.CLASS(restriction = SCode.R_ENUMERATION()), env) =
          Lookup.lookupClass(cache, env, path, false);
        typeStr = Absyn.pathLastIdent(path);
        path = FGraph.joinScopePath(env, Absyn.IDENT(typeStr));
        enum_lit_strs = SCode.componentNames(cl);
        (exp, t) = makeEnumerationArray(path, enum_lit_strs);
      then
        (cache,SOME((exp,DAE.PROP(t, DAE.C_CONST()),DAE.dummyAttrConst /* RO */)));

    // MetaModelica Partial Function
    case (cache,env,c,_,_,_,_,_)
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
        (cache,SOME((exp,DAE.PROP(t,DAE.C_VAR()),DAE.dummyAttrConst /* RO */)));

    // MetaModelica extension
    case (cache,_,Absyn.CREF_IDENT("NONE",{}),_,_,_,_,_)
      equation
        true = Config.acceptMetaModelicaGrammar();
        Error.addSourceMessage(Error.META_NONE_CREF, {}, info);
      then
        (cache,NONE());

    case (_,env,c,_,_,_,_,_)
      equation
        // enabled with +d=failtrace
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Static.elabCref failed: " +&
          Dump.printComponentRefStr(c) +& " in env: " +&
          FGraph.printGraphPathStr(env));
        // Debug.traceln("ENVIRONMENT:\n" +& FGraph.printGraphStr(env));
      then
        fail();

    /*
    // maybe we do have it but without a binding, so maybe we can actually type it!
    case (cache,env,c,impl,doVect,pre,info)
      equation
        failure((_,_,_) = elabCrefSubs(cache,env, c, pre, Prefix.NOPRE(),impl,info));
        id = Absyn.crefFirstIdent(c);
        (cache,DAE.TYPES_VAR(name, attributes, visibility, ty, binding, constOfForIteratorRange),
               SOME((cl as SCode.COMPONENT(n, pref, SCode.ATTR(arrayDims = ad), Absyn.TPATH(tpath, _),m,comment,cond,info),cmod)),instStatus,_)
          = Lookup.lookupIdent(cache, env, id);
        print("Static: cref:" +& Absyn.printComponentRefStr(c) +& " component first ident:\n" +& SCodeDump.unparseElementStr(cl) +& "\n");
        (cache, cl, env) = Lookup.lookupClass(cache, env, tpath, false);
        print("Static: cref:" +& Absyn.printComponentRefStr(c) +& " class component first ident:\n" +& SCodeDump.unparseElementStr(cl) +& "\n");
      then
        (cache,NONE());*/

    case (cache,env,c,impl,_,pre,_,_)
      equation
        failure((_,_,_,_) = elabCrefSubs(cache,env, env,c, pre, Prefix.NOPRE(),impl,false,info));
        s = Dump.printComponentRefStr(c);
        scope = FGraph.printGraphPathStr(env);
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR, {s,scope}, info); // - no need to add prefix info since problem only depends on the scope?
      then
        (cache,NONE());
  end matchcontinue;
end elabCref1;

protected function lookupFunctionsInEnvNoError
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
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

    else
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
    else inVariability;
  end matchcontinue;
end applySubscriptsVariability;

public function makeEnumerationArray
  "Expands an enumeration type to an array of it's enumeration literals."
  input Absyn.Path enumTypeName;
  input list<String> enumLiterals;
  output DAE.Exp enumArray;
  output DAE.Type enumArrayType;

protected
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
      FCore.Graph env;
      Boolean impl;
      FCore.Cache cache;
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
    case(_, _, _, _, DAE.CREF(componentRef = cr), _, _, _, _)
      equation
        (essl as _ :: _) = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        exps = List.map(essl, Expression.subscriptIndexExp);
        crefExp = Expression.crefExp(cr);
        exp1 = Expression.makeASUB(crefExp, exps);
      then
        exp1;

    else inExp;
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
  else equation print(" not allowed qual_asub\n"); then false;
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
    case ((e as DAE.CREF_IDENT(subscriptLst = {})),_) then e;

    // simple ident with non-empty subscripts
    case ((DAE.CREF_IDENT(ident = id, identType = ty2, subscriptLst = subs)),t)
      equation
        subs_1 = fillSubscripts(subs, t);
      then
        ComponentReference.makeCrefIdent(id,ty2,subs_1);
    // qualified ident with non-empty subscrips
    case ((DAE.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref,identType = ty2 )),t)
      equation
        subs = fillSubscripts(subs, ty2);
        t = stripPrefixType(t, ty2);
        cref_1 = fillCrefSubscripts(cref, t);
      then
        ComponentReference.makeCrefQual(id,ty2,subs,cref_1);
  end matchcontinue;
end fillCrefSubscripts;

protected function stripPrefixType
  input DAE.Type inType;
  input DAE.Type inPrefixType;
  output DAE.Type outType;
algorithm
  outType := match(inType, inPrefixType)
    local
      DAE.Type t, pt;

    case (DAE.T_ARRAY(ty = t), DAE.T_ARRAY(ty = pt)) then stripPrefixType(t, pt);
    else inType;
  end match;
end stripPrefixType;

protected function fillSubscripts
"Helper function to fillCrefSubscripts."
  input list<DAE.Subscript> inExpSubscriptLst;
  input DAE.Type inType;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  outExpSubscriptLst := matchcontinue (inExpSubscriptLst,inType)
    local
      list<DAE.Subscript> subs;
      DAE.Dimensions dims;

    // an array
    case (_, DAE.T_ARRAY(ty = _))
      equation
        subs = List.fill(DAE.WHOLEDIM(), listLength(Types.getDimensions(inType)));
        subs = List.stripN(subs, listLength(inExpSubscriptLst));
        subs = listAppend(inExpSubscriptLst, subs);
      then
        subs;

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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
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
  output FCore.Cache outCache;
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
      FCore.Graph env;
      DAE.Const const;
      SCode.Variability var;
      DAE.Binding binding_1,bind;
      String s,str,scope,pre_str;
      DAE.Binding binding;
      FCore.Cache cache;
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
    case (cache,_,cr,attr,_,_,t as DAE.T_UNKNOWN(source = _),_,_,_,_,_,_)
      equation
        expTy = Types.simplifyType(t);
        // adrpo: 2010-11-09
        //  use the variability to generate the constantness
        //  instead of returning *variabile* variability DAE.C_VAR()
        const = Types.variabilityToConst(DAEUtil.getAttrVariability(attr));
      then
        (cache, DAE.CREF(cr,expTy), const, attr);

    // adrpo: report a warning if the binding came from a start value!
    // lochel: I moved the waring to the back end for now
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,bind as DAE.EQBOUND(source = DAE.BINDING_FROM_START_VALUE()),doVect,_,_,_,_)
      equation
        true = Types.getFixedVarAttributeParameterOrConstant(tt);
        // s = ComponentReference.printComponentRefStr(cr);
        // pre_str = PrefixUtil.printPrefixStr2(inPrefix);
        // s = pre_str +& s;
        // str = DAEUtil.printBindingExpStr(inBinding);
        // Error.addSourceMessage(Error.UNBOUND_PARAMETER_WITH_START_VALUE_WARNING, {s,str}, info); // Don't add source info here... Many models give multiple errors that are not filtered out
        binding_1 = DAEUtil.setBindingSource(bind, DAE.BINDING_FROM_DEFAULT_VALUE());
        (cache, e_1, const, attr) = elabCref2(cache,env,cr,attr,constSubs,forIteratorConstOpt,tt,binding_1,doVect,splicedExpData,inPrefix,evalCref,info);
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
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.DISCRETE()),_,_,tt,_,doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = crefVectorize(doVect, Expression.makeCrefExp(cr_1,expTy), tt, sexp, expIdTy);
      then
        (cache,e,DAE.C_VAR(),attr);

    // an enumeration literal -> simplify to a literal expression
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,DAE.T_ENUMERATION(index = SOME(i), path = p),_,_,_,_,true,_)
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
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),DAE.C_VAR(),_,_,_,_,InstTypes.SPLICEDEXPDATA(_,_),_,_,_)
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
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,binding,_,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        true = Types.equivtypes(tt,idTp);
        (cache,v) = Ceval.cevalCrefBinding(cache,env,cr,binding,false,Absyn.MSG(info),0);
        e = ValuesUtil.valueExp(v);
        const = DAE.C_CONST(); //Types.constAnd(DAE.C_CONST(), constSubs);
      then
        (cache,e,const,attr);

    // a constant, couldn't evaluate binding, replace with it!
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,binding,_,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
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
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,binding,_,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
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
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,SOME(_),tt,_,_,_,_,_,_)
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
    case (cache,env,cr,attr as DAE.ATTR(variability = var),_,_,tt,DAE.EQBOUND(constant_ = _),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
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
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,DAE.VALBOUND(valBound = _),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,NONE(),expIdTy);
      then
        (cache,e_1,DAE.C_PARAM(),attr);

    // a constant with a binding
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,tt,DAE.EQBOUND(constant_ = DAE.C_CONST()),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
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
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,_,_,DAE.EQBOUND(evaluatedExp = SOME(v),constant_ = DAE.C_CONST()),_,
          InstTypes.SPLICEDEXPDATA(SOME(DAE.CREF(componentRef = DAE.CREF_IDENT(subscriptLst = {DAE.INDEX(DAE.CREF(componentRef = subCr2)),slice as DAE.SLICE(_)}))),_),_,_,_)
      equation
        {DAE.INDEX(index as DAE.CREF(componentRef = subCr1))} = ComponentReference.crefLastSubs(cr);
        true = ComponentReference.crefEqual(subCr1, subCr2);
        DAE.SLICE(DAE.ARRAY(_, _, _)) = slice;
        e_1 = ValuesUtil.valueExp(v);
        e_1 = DAE.ASUB(e_1, {index});
      then
        (cache,e_1,DAE.C_CONST(),attr);

    // vectorization of parameters with binding equations
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,DAE.EQBOUND(constant_ = _),doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt) "parameters with equal binding becomes C_PARAM" ;
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,sexp,expIdTy);
      then
        (cache,e_1,DAE.C_PARAM(),attr);

    // variables with constant binding
    case (cache,_,cr,attr,_,_,tt,DAE.EQBOUND(exp=_),doVect,InstTypes.SPLICEDEXPDATA(_,idTp),_,_,_)
      equation
        expTy = Types.simplifyType(tt) "..the rest should be non constant, even if they have a constant binding." ;
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e_1 = crefVectorize(doVect,Expression.makeCrefExp(cr_1,expTy), tt,NONE(),expIdTy);
        const = Types.variabilityToConst(DAEUtil.getAttrVariability(attr));
      then
        (cache,e_1,const,attr);

    // if value not constant, but references another parameter, which has a value perform value propagation.
    case (cache,env,_,_,_,_,_,DAE.EQBOUND(exp = DAE.CREF(componentRef = cref,ty = _),constant_ = DAE.C_VAR()),doVect,_,pre,_,_)
      equation
        (cache,attr2,t,binding_1,_,_,_,_,_) = Lookup.lookupVar(cache, env, cref);
        (cache,e,const,attr2) = elabCref2(cache,env,cref,attr2,DAE.C_VAR(),forIteratorConstOpt,t,binding_1,doVect,splicedExpData,pre,evalCref,info);
      then
        (cache,e,const,attr2);

    // report error
    case (_,_,cr,_,_,_,_,DAE.EQBOUND(exp = exp,constant_ = DAE.C_VAR()),_,_,pre,_,_)
      equation
        s = ComponentReference.printComponentRefStr(cr);
        str = ExpressionDump.printExpStr(exp);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        s = pre_str +& s;
        Error.addSourceMessage(Error.CONSTANT_OR_PARAM_WITH_NONCONST_BINDING, {s,str}, info);
      then
        fail();

    // constants without value should not produce error if they are not in a simulation model!
    case (cache,env,cr,attr as DAE.ATTR(variability = SCode.CONST()),_,NONE()/*not foriter*/,tt,DAE.UNBOUND(),_,_,pre,_,_)
      equation
        s = ComponentReference.printComponentRefStr(cr);
        scope = FGraph.printGraphPathStr(env);
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
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,NONE()/* not foriter*/,tt,DAE.UNBOUND(),
        doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
      equation
        false = Types.getFixedVarAttributeParameterOrConstant(tt);
        expTy = Types.simplifyType(tt);
        expIdTy = Types.simplifyType(idTp);
        cr_1 = fillCrefSubscripts(cr, tt);
        e = crefVectorize(doVect, Expression.makeCrefExp(cr_1,expTy), tt, sexp,expIdTy);
      then
        (cache,e,DAE.C_PARAM(),attr);

    // outer parameters without value is ok.
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.PARAM(), innerOuter = io),_,_,tt,DAE.UNBOUND(),_,_,_,_,_)
      equation
        (_,true) = InnerOuter.innerOuterBooleans(io);
        expTy = Types.simplifyType(tt);
        cr_1 = fillCrefSubscripts(cr, tt);
      then
        (cache,Expression.makeCrefExp(cr_1,expTy),DAE.C_PARAM(),attr);

    // parameters without value with fixed=true or no fixed attribute set produce warning (as long as not for iterator)
    case (cache,_,cr,attr as DAE.ATTR(variability = SCode.PARAM()),_,_,tt,DAE.UNBOUND(),doVect,InstTypes.SPLICEDEXPDATA(sexp,idTp),_,_,_)
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
    case (_,env,cr,_,_,_,_,_,_,_,pre,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        pre_str = PrefixUtil.printPrefixStr2(pre);
        Debug.fprint(Flags.FAILTRACE, "- Static.elabCref2 failed for: " +& pre_str +& ComponentReference.printComponentRefStr(cr) +& "\n env:" +& FGraph.printGraphStr(env));
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

    case(DAE.ARRAY(ty = (DAE.T_ARRAY(ty=_, dims=(tl))),scalar=sc,array=_))
    then (tl,sc);

    case(DAE.ARRAY(ty = _,scalar=_,array=expl1 as ((exp2 as DAE.ARRAY(_,_,_)) :: _)))
      equation
        (tl,_) = extractDimensionOfChild(exp2);
        x = listLength(expl1);
      then
        (DAE.DIM_INTEGER(x)::tl, false );

    case(DAE.ARRAY(ty = _,scalar=_,array=expl1))
      equation
        x = listLength(expl1);
      then ({DAE.DIM_INTEGER(x)},true);

    case(DAE.CREF(_ , _))
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
      then mergeQualWithRest2(exp2,exp1);
    // an array
    case(DAE.ARRAY(_, _, expl1),exp2,ety)
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
    case(DAE.CREF(cref, ety),DAE.CREF(DAE.CREF_IDENT(id,ty2, ssl),_))
      equation
        cref_2 = ComponentReference.makeCrefQual(id,ty2, ssl,cref);
      then Expression.makeCrefExp(cref_2,ety);
    // an array
    case(exp1 as DAE.ARRAY(_, _, expl1), exp2 as DAE.CREF(DAE.CREF_IDENT(_,_, _),ety))
      equation
        expl1 = List.map1(expl1,mergeQualWithRest2,exp2);
        exp1 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp1);
        ety = Expression.arrayEltType(ety);
      then DAE.ARRAY(DAE.T_ARRAY(ety, iLst, DAE.emptyTypeSource), scalar, expl1);
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
    case( ( (DAE.INDEX(exp = exp1 as DAE.ICONST(_))) :: subs1),id,ety)
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        //print("1. flattened rest into "+&ExpressionDump.dumpExpStr(exp2,0)+&"\n");
        exp2 = applySubscript(exp1, exp2 ,id,Expression.unliftArray(ety));
        //print("1. applied this subscript into "+&ExpressionDump.dumpExpStr(exp2,0)+&"\n");
      then
        exp2;
    // special case for zero dimension...
    case( ((DAE.SLICE( DAE.ARRAY(_,_,(expl1 as DAE.ICONST(0)::{})) )):: subs1),id,ety) // {1,2,3}
      equation
        exp2 = flattenSubscript2(subs1,id,ety);
        expl2 = List.map3(expl1,applySubscript,exp2,id,ety);
        exp3 = listNth(expl2,0);
        //exp3 = removeDoubleEmptyArrays(exp3);
      then
        exp3;
    // normal case;
    case( ((DAE.SLICE( DAE.ARRAY(_,_,expl1) )):: subs1),id,ety) // {1,2,3}
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
    case(DAE.ARRAY(ty = _,scalar=_,array =       ((exp2 as DAE.ARRAY(ty=_,scalar=_,array={}))::{}) ))
      then
        exp2;
    case(DAE.ARRAY(ty = ty1,scalar=sc,array = expl1 as
      ((DAE.ARRAY(ty=_,scalar=_,array=_))::expl3) ))
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

    case(_,exp1 as DAE.ARRAY(DAE.T_ARRAY(ty =_, dims = arrDim) ,_,{}),_ ,_)
      equation
        true = Expression.arrayContainZeroDimension(arrDim);
      then exp1;

        /* add dimensions */
    case(DAE.ICONST(integer=0),DAE.ARRAY(DAE.T_ARRAY(ty =_, dims = arrDim) ,_,_),_ ,ety)
      equation
        ety = Expression.arrayEltType(ety);
      then DAE.ARRAY(DAE.T_ARRAY(ety, DAE.DIM_INTEGER(0)::arrDim, DAE.emptyTypeSource),true,{});

    case(DAE.ICONST(integer=0),_,_ ,ety)
      equation
        ety = Expression.arrayEltType(ety);
      then DAE.ARRAY(DAE.T_ARRAY(ety,{DAE.DIM_INTEGER(0)}, DAE.emptyTypeSource),true,{});

    case(exp1,DAE.ARRAY(_,_,{}),id ,ety)
      equation
        true = Expression.isValidSubscript(exp1);
        crty = Expression.unliftArray(ety) "only subscripting one dimension, unlifting once ";
        cref_ = ComponentReference.makeCrefIdent(id,ety,{DAE.INDEX(exp1)});
      then Expression.makeCrefExp(cref_,crty);

    case(exp1, exp2, _ ,ety)
      equation
        true = Expression.isValidSubscript(exp1);
      then applySubscript2(exp1, exp2,ety);
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

    case(exp1, DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_ ),_ )
      equation
        crty = Expression.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        cref_ = ComponentReference.makeCrefIdent(id,ty2,(DAE.INDEX(exp1)::subs));
        exp2 = Expression.makeCrefExp(cref_,crty);
      then exp2;

    case(exp1, DAE.ARRAY(_,_,expl1),ety )
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

    case(DAE.CREF(DAE.CREF_IDENT(id,ty2,subs),_), exp1, _ )
      equation
        crty = Expression.unliftArrayTypeWithSubs(DAE.INDEX(exp1)::subs,ty2);
        cref_ = ComponentReference.makeCrefIdent(id,ty2,(DAE.INDEX(exp1)::subs));
        exp2 = Expression.makeCrefExp(cref_,crty);
      then exp2;

    case(DAE.ARRAY(_,_,expl1), exp1, ety)
      equation
        expl1 = List.map2(expl1,applySubscript3,exp1,ety);
        exp2 = DAE.ARRAY(DAE.T_INTEGER_DEFAULT,false,expl1);
        (iLst, scalar) = extractDimensionOfChild(exp2);
        ety = Expression.arrayEltType(ety);
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
    case (_,{}) then {};
    // vectorize call
    case ((callexp as DAE.CALL(fn,args,attr)),(e :: es))
      equation
        es_1 = callVectorize(callexp, es);
      then
        (DAE.CALL(fn,(e :: args),attr) :: es_1);
    else
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
    case (_,indx,ds,et,_,_)
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
        cr_1 = ComponentReference.replaceWholeDimSubscript(cr,indx);
        DAE.ARRAY(_,_,expl) = createCrefArray(cr, indx_1, ds, et, t,crefIdType);
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
    case (cr,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "createCrefArray failed on:" +& ComponentReference.printComponentRefStr(cr));
      then
        fail();
  end matchcontinue;
end createCrefArray;

protected function createCrefArray2d
"helper function to cref_vectorize, creates each
  individual cref, e.g. {x{1,1},x{2,1}, ...} from x."
  input DAE.ComponentRef inCref;
  input Integer inIndex;
  input Integer inDim1;
  input Integer inDim2;
  input DAE.Type inType5;
  input DAE.Type inType6;
  input DAE.Type crefIdType;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inCref, inIndex, inDim1, inDim2, inType5,inType6,crefIdType)
    local
      DAE.ComponentRef cr,cr_1;
      Integer indx,ds,ds2,indx_1;
      DAE.Type et,tp,elt_tp;
      DAE.Type t;
      list<list<DAE.Exp>> ms;
      list<DAE.Exp> expl;
    // index iterator dimension size 1 dimension size 2
    case (_,indx,ds,_,et,_,_)
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
        DAE.ARRAY(_,true,expl) = crefVectorize(true,Expression.makeCrefExp(cr_1,elt_tp), t,NONE(),crefIdType);
      then
        DAE.MATRIX(et,ds,(expl :: ms));
    //
    case (cr,_,_,_,_,_,_)
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
  input FCore.Cache inCache;
  input FCore.Graph inCrefEnv "search for the cref in this environment";
  input FCore.Graph inSubsEnv;
  input Absyn.ComponentRef inComponentRef;
  input Prefix.Prefix inTopPrefix "the top prefix, i.e. the one send down by elabCref1, needed to prefix expressions in subscript types!";
  input Prefix.Prefix inCrefPrefix "the accumulated cref, required for lookup";
  input Boolean inBoolean;
  input Boolean inHasZeroSizeDim;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
  output DAE.Const outConst "The constness of the subscripts. Note: This is not the same as
  the constness of a cref with subscripts! (just becase x[1,2] has a constant subscript list does
  not mean that the variable x[1,2] is constant)";
  output Boolean outHasZeroSizeDim;
algorithm
  (outCache,outComponentRef,outConst,outHasZeroSizeDim) := matchcontinue (inCache,inCrefEnv,inSubsEnv,inComponentRef,inTopPrefix,inCrefPrefix,inBoolean,inHasZeroSizeDim,info)
    local
      DAE.Type t;
      DAE.Dimensions sl;
      DAE.Const const,const1,const2;
      FCore.Graph crefEnv, crefSubs;
      String id;
      list<Absyn.Subscript> ss;
      Boolean impl, hasZeroSizeDim;
      DAE.ComponentRef cr;
      Absyn.ComponentRef absynCr;
      DAE.Type ty, id_ty;
      list<DAE.Subscript> ss_1;
      Absyn.ComponentRef restCref,absynCref;
      FCore.Cache cache;
      SCode.Variability vt;
      Prefix.Prefix crefPrefix;
      Prefix.Prefix topPrefix;

    // IDENT
    case (cache,crefEnv,crefSubs,Absyn.CREF_IDENT(name = id,subscripts = ss),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        // Debug.traceln("Try elabSucscriptsDims " +& id);
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,
                                           ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,_,t,_,_,InstTypes.SPLICEDEXPDATA(identType = id_ty),_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        // false = Types.isUnknownType(t);
        // print("elabCrefSubs type of: " +& id +& " is " +& Types.printTypeStr(t) +& "\n");
        // Debug.traceln("    elabSucscriptsDims " +& id +& " got var");
        ty = Types.simplifyType(t);
        id_ty = Types.simplifyType(id_ty);
        hasZeroSizeDim = Types.isZeroLengthArray(id_ty);
        sl = Types.getDimensions(id_ty);
        // Constant evaluate subscripts on form x[1,p,q] where p,q are constants or parameters
        (cache,ss_1,const) = elabSubscriptsDims(cache, crefSubs, ss, sl, impl,
            topPrefix, inComponentRef, info);
      then
        (cache,ComponentReference.makeCrefIdent(id,ty,ss_1),const,hasZeroSizeDim);

    // QUAL,with no subscripts => looking for var in the top env!
    case (cache,crefEnv,crefSubs,Absyn.CREF_QUAL(name = id,subscripts = {},componentRef = restCref),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,
                                           ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        //print("env:");print(FGraph.printGraphStr(env));print("\n");
        (cache,_,t,_,_,_,_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        ty = Types.simplifyType(t);
        sl = Types.getDimensions(ty);
        crefPrefix = PrefixUtil.prefixAdd(id,sl,{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, restCref, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache,ComponentReference.makeCrefQual(id,ty,{},cr),const,hasZeroSizeDim);

    // QUAL,with no subscripts second case => look for class
    case (cache,crefEnv,crefSubs,Absyn.CREF_QUAL(name = id,subscripts = {},componentRef = restCref),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        crefPrefix = PrefixUtil.prefixAdd(id,{},{},crefPrefix,SCode.VAR(),ClassInf.UNKNOWN(Absyn.IDENT(""))); // variability doesn't matter
        (cache,cr,const,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, restCref, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache,ComponentReference.makeCrefQual(id,DAE.T_COMPLEX_DEFAULT,{},cr),const,hasZeroSizeDim);

    // QUAL,with constant subscripts
    case (cache,crefEnv,crefSubs,Absyn.CREF_QUAL(name = id,subscripts = ss as _::_,componentRef = restCref),topPrefix,crefPrefix,impl,hasZeroSizeDim,_)
      equation
        (cache,cr) = PrefixUtil.prefixCref(cache,crefEnv,InnerOuter.emptyInstHierarchy,crefPrefix,
                                           ComponentReference.makeCrefIdent(id,DAE.T_UNKNOWN_DEFAULT,{}));
        (cache,DAE.ATTR(variability = vt),t,_,_,InstTypes.SPLICEDEXPDATA(identType = id_ty),_,_,_) = Lookup.lookupVar(cache, crefEnv, cr);
        ty = Types.simplifyType(t);
        id_ty = Types.simplifyType(id_ty);
        sl = Types.getDimensions(id_ty);
        (cache,ss_1,const1) = elabSubscriptsDims(cache, crefSubs, ss, sl, impl,
            topPrefix, inComponentRef, info);
        crefPrefix = PrefixUtil.prefixAdd(id, sl, ss_1, crefPrefix, vt, ClassInf.UNKNOWN(Absyn.IDENT("")));
        (cache,cr,const2,hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, restCref, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
        const = Types.constAnd(const1, const2);
      then
        (cache,ComponentReference.makeCrefQual(id,ty,ss_1,cr),const,hasZeroSizeDim);

    case (cache, crefEnv, crefSubs, Absyn.CREF_FULLYQUALIFIED(componentRef = absynCr), topPrefix, crefPrefix, impl, hasZeroSizeDim, _)
      equation
        crefEnv = FGraph.topScope(crefEnv);
        (cache, cr, const1, hasZeroSizeDim) = elabCrefSubs(cache, crefEnv, crefSubs, absynCr, topPrefix, crefPrefix, impl, hasZeroSizeDim, info);
      then
        (cache, cr, const1, hasZeroSizeDim);

    // failure
    case (_,crefEnv,_,absynCref,topPrefix,crefPrefix,_,_,_)
      equation
        // FAILTRACE REMOVE
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabCrefSubs failed on: " +&
        "[top:" +& PrefixUtil.printPrefixStr(topPrefix) +& "]." +&
        PrefixUtil.printPrefixStr(crefPrefix) +& "." +&
          Dump.printComponentRefStr(absynCref) +& " env: " +&
          FGraph.printGraphPathStr(crefEnv));
      then
        fail();
  end matchcontinue;
end elabCrefSubs;

public function elabSubscripts
"This function converts a list of Absyn.Subscript to a list of
  DAE.Subscript, and checks if all subscripts are constant.
  HJ: not checking for constant, returning if constant or not"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output list<DAE.Subscript> outExpSubscriptLst;
  output DAE.Const outConst;
algorithm
  (outCache,outExpSubscriptLst,outConst) := match (inCache,inEnv,inAbsynSubscriptLst,inBoolean,inPrefix,info)
    local
      DAE.Subscript sub_1;
      DAE.Const const1,const2,const;
      list<DAE.Subscript> subs_1;
      FCore.Graph env;
      Absyn.Subscript sub;
      list<Absyn.Subscript> subs;
      Boolean impl;
      FCore.Cache cache;
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
  "Elaborates a list of subscripts and checks that they are valid for the given dimensions."
  input FCore.Cache cache;
  input FCore.Graph env;
  input list<Absyn.Subscript> subs;
  input DAE.Dimensions dims;
  input Boolean impl;
  input Prefix.Prefix inPrefix;
  input Absyn.ComponentRef inCref;
  input Absyn.Info info;
  output FCore.Cache outCache;
  output list<DAE.Subscript> outSubs;
  output DAE.Const outConst;
algorithm
  (outCache, outSubs, outConst) := elabSubscriptsDims2(cache, env, subs, dims,
    impl, inPrefix, inCref, info, DAE.C_CONST(), {});
end elabSubscriptsDims;

protected function elabSubscriptsDims2
  "Helper function to elabSubscriptsDims."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input list<Absyn.Subscript> inSubscripts;
  input DAE.Dimensions inDimensions;
  input Boolean inImpl;
  input Prefix.Prefix inPrefix;
  input Absyn.ComponentRef inCref;
  input Absyn.Info inInfo;
  input DAE.Const inConst;
  input list<DAE.Subscript> inElabSubscripts;
  output FCore.Cache outCache;
  output list<DAE.Subscript> outSubscripts;
  output DAE.Const outConst;
algorithm
  (outCache, outSubscripts, outConst) :=
  match(inCache, inEnv, inSubscripts, inDimensions, inImpl, inPrefix,
      inCref, inInfo, inConst, inElabSubscripts)
    local
      Absyn.Subscript asub;
      list<Absyn.Subscript> rest_asub;
      DAE.Dimension dim;
      DAE.Dimensions rest_dims;
      DAE.Subscript dsub;
      list<DAE.Subscript> elabed_subs;
      DAE.Const const;
      FCore.Cache cache;
      Option<DAE.Properties> prop;
      Integer subl, diml, esubl;
      String subl_str, diml_str, cref_str;

    case (_, _, asub :: rest_asub, dim :: rest_dims, _, _, _, _, _, _)
      equation
        (cache, dsub, const, prop) = elabSubscript(inCache, inEnv, asub, inImpl, inPrefix, inInfo);
        const = Types.constAnd(const, inConst);
        (cache, dsub) = elabSubscriptsDims3(cache, inEnv, dsub, dim, const, prop, inImpl, inCref, inInfo);
        elabed_subs = dsub :: inElabSubscripts;
        (cache, elabed_subs, const) = elabSubscriptsDims2(cache, inEnv, rest_asub, rest_dims, inImpl, inPrefix, inCref, inInfo, const, elabed_subs);
      then
        (cache, elabed_subs, const);

    case (_, _, {}, {}, _, _, _, _, _, _)
      then (inCache, listReverse(inElabSubscripts), inConst);

    case (_, _, {}, _, _, _, _, _, _, {})
      then (inCache, {}, inConst);

    // Check for wrong number of subscripts. The number of subscripts must be
    // either the same as the number of dimensions, or no subscripts at all.
    else
      equation
        subl = listLength(inSubscripts);
        diml = listLength(inDimensions);
        true = subl <> diml;
        // Add the number of already elaborated subscripts to get the correct count.
        esubl = listLength(inElabSubscripts);
        subl_str = intString(subl + esubl);
        diml_str = intString(diml + esubl);
        cref_str = Dump.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.WRONG_NUMBER_OF_SUBSCRIPTS,
          {cref_str, subl_str, diml_str}, inInfo);
      then
        fail();

  end match;
end elabSubscriptsDims2;

protected function elabSubscriptsDims3
  "Helper function to elabSubscriptsDims2."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.Subscript inSubscript;
  input DAE.Dimension inDimension;
  input DAE.Const inConst;
  input Option<DAE.Properties> inProperties;
  input Boolean inImpl;
  input Absyn.ComponentRef inCref;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Subscript outSubscript;
algorithm
  (outCache, outSubscript) := matchcontinue(inCache, inEnv,
      inSubscript, inDimension, inConst, inProperties, inImpl, inCref, inInfo)
    local
      FCore.Cache cache;
      DAE.Subscript sub;
      Integer int_dim;
      DAE.Properties prop;
      DAE.Type ty;
      DAE.Exp e;
      String sub_str, dim_str, cref_str;

    // If in for iterator loop scope the subscript should never be evaluated to
    // a value (since the parameter/const value of iterator variables are not
    // available until expansion, which happens later on)
    // Note that for loops are expanded 'on the fly' and should therefore not be
    // treated in this way.
    case (_, _, _, _, _, _, _, _, _)
      equation
        true = FGraph.inForOrParforIterLoopScope(inEnv);
        true = Expression.dimensionKnown(inDimension);
      then
        (inCache, inSubscript);

    // Keep non-fixed parameters.
    case (_, _, _, _, _, SOME(prop), _, _, _)
      equation
        true = Types.isParameter(inConst);
        ty = Types.getPropType(prop);
        false = Types.getFixedVarAttributeParameterOrConstant(ty);
      then
        (inCache, inSubscript);

    /*/ Keep parameters as they are:
    // adrpo 2012-12-02 this does not work as we need to evaluate final parameters!
    //                  and we have now way yet of knowing which ones those are
    case (_, _, _, _, _, _, _, _, _)
      equation
        true = Types.isParameter(inConst);
      then
        (inCache, inSubscript);*/

    // If the subscript contains a const then it should be evaluated to
    // the value.
    case (_, _, _, _, _, _, _, _, _)
      equation
        int_dim = Expression.dimensionSize(inDimension);
        true = Types.isParameterOrConstant(inConst);
        (cache, sub) = Ceval.cevalSubscript(inCache, inEnv, inSubscript, int_dim, inImpl, Absyn.MSG(inInfo), 0);
      then
        (cache, sub);

    case (_, _, _, DAE.DIM_EXP(exp=e), _, _, _, _, _)
      equation
        true = Types.isParameterOrConstant(inConst);
        (_, Values.INTEGER(integer=int_dim), _) = Ceval.ceval(inCache,inEnv,e,true,NONE(),Absyn.MSG(inInfo),0);
        (cache, sub) = Ceval.cevalSubscript(inCache, inEnv, inSubscript, int_dim, inImpl, Absyn.MSG(inInfo), 0);
      then
        (cache, sub);

    // If the previous case failed and we're just checking the model, try again
    // but skip the constant evaluation.
    case (_, _, _, _, _, _, _, _, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        true = Types.isParameterOrConstant(inConst);
      then
        (inCache, inSubscript);

    // If not constant, keep as is.
    case (_, _, _, _, _, _, _, _, _)
      equation
        true = Expression.dimensionKnown(inDimension);
        false = Types.isParameterOrConstant(inConst);
      then
        (inCache, inSubscript);

    // For unknown dimensions, ':', keep as is.
    case (_, _, _, DAE.DIM_UNKNOWN(), _, _, _, _, _)
      then (inCache, inSubscript);
    case (_, _, _, DAE.DIM_EXP(_), _, _, _, _, _)
      then (inCache, inSubscript);

    case (_, _, _, _, _, _, _, _, _)
      equation
        sub_str = ExpressionDump.printSubscriptStr(inSubscript);
        dim_str = ExpressionDump.dimensionString(inDimension);
        cref_str = Dump.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.ILLEGAL_SUBSCRIPT, {sub_str, dim_str, cref_str}, inInfo);
      then
        fail();

  end matchcontinue;
end elabSubscriptsDims3;

protected function elabSubscript "This function converts an Absyn.Subscript to an
  DAE.Subscript."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Subscript inSubscript;
  input Boolean inBoolean;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  output FCore.Cache outCache;
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
      FCore.Graph env;
      Absyn.Exp sub;
      FCore.Cache cache;
      DAE.Properties prop;
      Prefix.Prefix pre;

    // no subscript
    case (cache, _, Absyn.NOSUB(), _, _, _)
      then (cache, DAE.WHOLEDIM(), DAE.C_CONST(), NONE());

    // some subscript, try to elaborate it
    case (cache, env, Absyn.SUBSCRIPT(subscript = sub), impl, pre, _)
      equation
        (cache, sub_1, prop as DAE.PROP(constFlag = const), _) =
          elabExpInExpression(cache, env, sub, impl, NONE(), true, pre, info);
        (cache, sub_1, prop as DAE.PROP(type_ = ty)) =
          Ceval.cevalIfConstant(cache, env, sub_1, prop, impl, info);
        sub_2 = elabSubscriptType(ty, sub, sub_1, info);
      then
        (cache, sub_2, const, SOME(prop));

    // failtrace
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.fprintln(Flags.FAILTRACE, "- Static.elabSubscript failed on " +&
          Dump.printSubscriptStr(inSubscript) +& " in env: " +&
          FGraph.printGraphPathStr(inEnv));
      then
        fail();
  end matchcontinue;
end elabSubscript;

protected function elabSubscriptType
  "This function is used to find the correct constructor for DAE.Subscript to
   use for an indexing expression.  If a scalar is given as index, DAE.INDEX()
   is used, and if an array is given, DAE.SLICE() is used."
  input DAE.Type inType;
  input Absyn.Exp inAbsynExp;
  input DAE.Exp inDaeExp;
  input Absyn.Info inInfo;
  output DAE.Subscript outSubscript;
algorithm
  outSubscript := match(inType, inAbsynExp, inDaeExp, inInfo)
    local
      DAE.Exp sub;
      String e_str,t_str,p_str;

    case (DAE.T_INTEGER(varLst = _), _, _, _) then DAE.INDEX(inDaeExp);
    case (DAE.T_ENUMERATION(path = _), _, _, _) then DAE.INDEX(inDaeExp);
    case (DAE.T_BOOL(varLst = _), _, _, _) then DAE.INDEX(inDaeExp);
    case (DAE.T_ARRAY(ty = DAE.T_INTEGER(varLst = _)), _, _, _) then DAE.SLICE(inDaeExp);
    case (DAE.T_ARRAY(ty = DAE.T_ENUMERATION(path = _)), _, _, _) then DAE.SLICE(inDaeExp);
    case (DAE.T_ARRAY(ty = DAE.T_BOOL(varLst = _)), _, _, _) then DAE.SLICE(inDaeExp);

    else
      equation
        e_str = Dump.printExpStr(inAbsynExp);
        t_str = Types.unparseType(inType);
        Error.addSourceMessage(Error.WRONG_DIMENSION_TYPE, {e_str, t_str}, inInfo);
      then
        fail();
  end match;
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

    case (_,t) then t;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv1;
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
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
algorithm
  (outCache,outExp,outProperties):=
  matchcontinue (inCache,inEnv1,inExp2,inProperties3,inExp4,inProperties5,inExp6,inProperties7,inBoolean8,inST,inPrefix,inInfo)
    local
      DAE.Const c,c1,c2,c3;
      DAE.Exp exp,e1,e2,e3,e2_1,e3_1;
      FCore.Graph env;
      DAE.Type t2,t3,t2_1,t3_1,t1,ty;
      Boolean impl;
      Option<GlobalScript.SymbolTable> st;
      String e_str,t_str,e1_str,t1_str,e2_str,t2_str,pre_str;
      FCore.Cache cache;
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
        t2_1 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t2_1);
        t3_1 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t3_1);
        (e2_1,t2_1) = Types.matchType(e2, t2_1, t3_1, true);
        c = constIfexp(e1, c1, c2, c3) "then-part type converted to match else-part" ;
        (cache,exp,ty) = cevalIfexpIfConstant(cache,env, e1, e2_1, e3, c1, t2, t3, t2_1, impl, st, inInfo);
      then
        (cache,exp,DAE.PROP(ty,c));

    case (cache,env,e1,DAE.PROP(type_ = t1,constFlag = c1),e2,DAE.PROP(type_ = t2,constFlag = c2),e3,DAE.PROP(type_ = t3,constFlag = c3),impl,st,_, _)
      equation
        (e1,_) = Types.matchType(e1, t1, DAE.T_BOOL_DEFAULT, true);
        (_,t3_1) = Types.ifExpMakeDimsUnknown(t2,t3);
        t2 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t2);
        t3 = Types.getUniontypeIfMetarecordReplaceAllSubtypes(t3);
        (e3_1,t3_1) = Types.matchType(e3, t3, t2, true);
        c = constIfexp(e1, c1, c2, c3) "else-part type converted to match then-part" ;
        (cache,exp,_) = cevalIfexpIfConstant(cache,env, e1, e2, e3_1, c1, t2, t3, t3_1, impl, st, inInfo);
      then
        (cache,exp,DAE.PROP(t2,c));

    case (_,_,e1,DAE.PROP(type_ = t1,constFlag = _),_,DAE.PROP(type_ = _,constFlag = _),_,DAE.PROP(type_ = _,constFlag = _),_,_,pre,_)
      equation
        failure((_,_) = Types.matchType(e1, t1, DAE.T_BOOL_DEFAULT, true));
        e_str = ExpressionDump.printExpStr(e1);
        t_str = Types.unparseTypeNoAttr(t1);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        t_str = t_str +& " (in component: "+&pre_str+&")";
        Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str,t_str}, inInfo);
      then
        fail();

    case (_,_,_,DAE.PROP(type_ = DAE.T_BOOL(varLst = _),constFlag = _),e2,DAE.PROP(type_ = t2,constFlag = _),e3,DAE.PROP(type_ = t3,constFlag = _),_,_,pre,_)
      equation
        false = Types.semiEquivTypes(t2, t3);
        e1_str = ExpressionDump.printExpStr(e2);
        t1_str = Types.unparseTypeNoAttr(t2);
        e2_str = ExpressionDump.printExpStr(e3);
        t2_str = Types.unparseTypeNoAttr(t3);
        pre_str = PrefixUtil.printPrefixStr3(pre);
        Types.typeErrorSanityCheck(t1_str, t2_str, inInfo);
        Error.addSourceMessage(Error.TYPE_MISMATCH_IF_EXP, {pre_str,e1_str,t1_str,e2_str,t2_str}, inInfo);
      then
        fail();

    else
      equation
        Print.printBuf("- Static.makeIfexp failed\n");
      then
        fail();
  end matchcontinue;
end makeIfexp;

protected function cevalIfexpIfConstant "author: PA
  Constant evaluates the condition of an expression if it is constants and
  elimitates the if expressions by selecting branch."
  input FCore.Cache inCache;
  input FCore.Graph inEnv1;
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
  output FCore.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outCache,outExp,outType) :=
  matchcontinue (inCache,inEnv1,inExp2,inExp3,inExp4,inConst5,trueType,falseType,defaultType,inBoolean6,inST,inInfo)
    local
      FCore.Graph env;
      DAE.Exp e1,e2,e3,res;
      Boolean impl,cond;
      Option<GlobalScript.SymbolTable> st;
      FCore.Cache cache;
      Absyn.Msg msg;
      DAE.Type ty;

    case (cache,_,e1,e2,e3,DAE.C_VAR(),_,_,_,_,_,_) then (cache,DAE.IFEXP(e1,e2,e3),defaultType);
    case (cache,env,e1,e2,e3,DAE.C_PARAM(),_,_,_,impl,st,_)
      equation
        false = valueEq(Types.getDimensionSizes(trueType),Types.getDimensionSizes(falseType));
        // We have different dimensions in the branches, so we should consider the condition structural in order to handle more models
        (cache,Values.BOOL(cond),_) = Ceval.ceval(cache,env, e1, impl, st, Absyn.NO_MSG(),0);
        res = Util.if_(cond, e2, e3);
        ty = Util.if_(cond, trueType, falseType);
      then (cache,res,ty);
    case (cache,_,e1,e2,e3,DAE.C_PARAM(),_,_,_,_,_,_) then (cache,DAE.IFEXP(e1,e2,e3),defaultType);
    case (cache,env,e1,e2,e3,DAE.C_CONST(),_,_,_,impl,st,_)
      equation
        msg = Util.if_(FGraph.inFunctionScope(env) or FGraph.inForOrParforIterLoopScope(env), Absyn.NO_MSG(), Absyn.MSG(inInfo));
        (cache,Values.BOOL(cond),_) = Ceval.ceval(cache,env, e1, impl, st,msg,0);
        res = Util.if_(cond, e2, e3);
        ty = Util.if_(cond, trueType, falseType);
      then
        (cache,res,ty);
    // Allow ceval of constant if expressions to fail. This is needed because of
    // the stupid Lookup which instantiates packages without modifiers.
    case (cache,env,e1,e2,e3,DAE.C_CONST(),_,_,_,_,_,_)
      equation
        true = FGraph.inFunctionScope(env) or FGraph.inForOrParforIterLoopScope(env);
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input DAE.ComponentRef inPrefixCref;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  match (inCache,inEnv,inComponentRef,inPrefixCref,inBoolean)
    local
      list<DAE.Subscript> ss_1,ss;
      FCore.Graph env;
      String n;
      Boolean impl;
      FCore.Cache cache;
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
  end match;
end canonCref2;

public function canonCref "Transform expression to canonical form
  by constant evaluating all subscripts."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.ComponentRef inComponentRef;
  input Boolean inBoolean;
  output FCore.Cache outCache;
  output DAE.ComponentRef outComponentRef;
algorithm
  (outCache,outComponentRef) :=
  matchcontinue (inCache,inEnv,inComponentRef,inBoolean)
    local
      DAE.Type t;
      list<Integer> sl;
      list<DAE.Subscript> ss_1,ss;
      FCore.Graph env, componentEnv;
      String n;
      Boolean impl;
      DAE.ComponentRef c_1,c,cr;
      FCore.Cache cache;
      DAE.Type ty2;

    // handle wild _
    case (cache,_,DAE.WILD(),_)
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
    case (_,_,cr,_)
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
    case ((t as DAE.T_CLOCK(varLst = _))) then t;
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
  input FCore.Graph inEnv;
  output DAE.Const outConst;
algorithm
  outConst := matchcontinue(inEnv)
    case _ equation true = FGraph.inFunctionScope(inEnv); then DAE.C_VAR();
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
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.CodeType ct;
  input Option<GlobalScript.SymbolTable> st;
  input Absyn.Info info;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (exp,cache,env,ct,st,info)
    local
      String s1,s2;
      Absyn.ComponentRef cr;
      Absyn.Path path;
      list<DAE.Exp> es_1;
      list<Absyn.Exp> es;
      DAE.Type et;
      Integer i;
      DAE.Exp dexp;
      DAE.Properties prop;
      DAE.Type ty;
      DAE.CodeType ct2;

    // First; try to elaborate the exp (maybe there is a binding in the environment that says v is a VariableName, etc...
    case (_,_,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("elabCodeExp");
        (_,dexp,prop,_) = elabExpInExpression(cache,env,exp,false,st,false,Prefix.NOPRE(),info);
        DAE.T_CODE(ty=ct2) = Types.getPropType(prop);
        true = valueEq(ct,ct2);
        ErrorExt.delCheckpoint("elabCodeExp");
        // print(ExpressionDump.printExpStr(dexp) + " " + Types.unparseType(ty) + "\n");
      then dexp;

    case (_,_,_,_,_,_)
      equation
        ErrorExt.rollBack("elabCodeExp");
      then fail();

    // Expression
    case (_,_,_,DAE.C_EXPRESSION(),_,_)
      then DAE.CODE(Absyn.C_EXPRESSION(exp),DAE.T_UNKNOWN_DEFAULT);

    // Type Name
    case (Absyn.CREF(componentRef=cr),_,_,DAE.C_TYPENAME(),_,_)
      equation
        path = Absyn.crefToPath(cr);
      then DAE.CODE(Absyn.C_TYPENAME(path),DAE.T_UNKNOWN_DEFAULT);

    // Variable Names
    case (Absyn.ARRAY(es),_,_,DAE.C_VARIABLENAMES(),_,_)
      equation
        es_1 = List.map5(es,elabCodeExp,cache,env,DAE.C_VARIABLENAME(),st,info);
        i = listLength(es);
        et = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(i)}, DAE.emptyTypeSource);
      then DAE.ARRAY(et,false,es_1);

    case (_,_,_,DAE.C_VARIABLENAMES(),_,_)
      equation
        et = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
        dexp = elabCodeExp(exp,cache,env,DAE.C_VARIABLENAME(),st,info);
      then DAE.ARRAY(et,false,{dexp});

    // Variable Name
    case (Absyn.CREF(componentRef=cr),_,_,DAE.C_VARIABLENAME(),_,_)
      then DAE.CODE(Absyn.C_VARIABLENAME(cr),DAE.T_UNKNOWN_DEFAULT);

    case (Absyn.CALL(Absyn.CREF_IDENT("der",{}),Absyn.FUNCTIONARGS(args={Absyn.CREF(componentRef=_)},argNames={})),_,_,DAE.C_VARIABLENAME(),_,_)
      then DAE.CODE(Absyn.C_EXPRESSION(exp),DAE.T_UNKNOWN_DEFAULT);

    // failure
    else
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.Subscript> inDimensions;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensions;
algorithm
  (outCache, outDimensions) := elabArrayDims2(inCache, inEnv, inComponentRef,
    inDimensions, inImplicit, inST, inDoVect, inPrefix, inInfo, {});
end elabArrayDims;

protected function elabArrayDims2
  "Helper function to elabArrayDims. Needed because of tail recursion."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input list<Absyn.Subscript> inDimensions;
  input Boolean inImplicit;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  input DAE.Dimensions inElaboratedDims;
  output FCore.Cache outCache;
  output DAE.Dimensions outDimensions;
algorithm
  (outCache, outDimensions) := match(inCache, inEnv, inCref, inDimensions,
      inImplicit, inST, inDoVect, inPrefix, inInfo, inElaboratedDims)
    local
      FCore.Cache cache;
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input Absyn.Subscript inDimension;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output DAE.Dimension outDimension;
algorithm
  (outCache, outDimension) := matchcontinue(inCache, inEnv, inCref, inDimension,
      inImpl, inST, inDoVect, inPrefix, inInfo)
    local
      Absyn.ComponentRef cr;
      DAE.Dimension dim;
      FCore.Cache cache;
      FCore.Graph cenv;
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
        (cache, e, _, _) = elabExpInExpression(inCache, inEnv, cr_exp, inImpl, inST,
          inDoVect, inPrefix, inInfo);
        (cache, dim_exp, _, _) = elabExpInExpression(cache, inEnv, size_arg, inImpl, inST,
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
            classDef = SCode.PARTS(elementLst = _)), cenv) =
          Lookup.lookupClass(inCache, inEnv, type_path, false);
        enum_type_name = FGraph.joinScopePath(cenv, Absyn.IDENT(name));
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
        (cache, e, prop, _) = elabExpInExpression(inCache, inEnv, sub, inImpl, inST,
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
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.ComponentRef inCref;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input Boolean inImpl;
  input Option<GlobalScript.SymbolTable> inST;
  input Boolean inDoVect;
  input Prefix.Prefix inPrefix;
  input Absyn.Info inInfo;
  output FCore.Cache outCache;
  output Option<DAE.Dimension> outDimension;
algorithm
  (outCache, outDimension) := matchcontinue(inCache, inEnv, inCref, inExp, inProperties,
      inImpl, inST, inDoVect, inPrefix, inInfo)
    local
      DAE.Const cnst;
      FCore.Cache cache;
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
  input Absyn.Exp inExp;
  input tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>> inTuple;
  output Absyn.Exp outExp;
  output tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>> outTuple;
algorithm
  (outExp,outTuple) := match (inExp,inTuple)
    local
      Absyn.Exp exp;
      list<Absyn.Exp> crs;
      list<Integer> li;
      Integer i,ni;
      list<Boolean> bs;
      Boolean isCr,inc;
    case (_,(crs,i::li,bs as (inc::_)))
      equation
        isCr = Absyn.isCref(inExp);
        bs = Util.if_(isCr,true::bs,false::bs);
        ni = Util.if_(isCr,0,i+1);
        li = Util.if_(inc,ni::li,i::li);
        li = Util.if_(isCr,0::li,li);
        crs = consStrippedCref(inExp,crs);
      then (inExp,(crs,li,bs));
  end match;
end replaceEndEnter;

protected function replaceEndExit
  "Single pass traversal that replaces end-expressions with the correct size-expression.
  It uses a couple of stacks and crap to handle all of this :)."
  input Absyn.Exp inExp;
  input tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>> inTuple;
  output Absyn.Exp outExp;
  output tuple<list<Absyn.Exp>,list<Integer>,list<Boolean>> outTuple;
algorithm
  (outExp,outTuple) := match (inExp,inTuple)
    local
      Absyn.Exp cr,exp;
      list<Absyn.Exp> crs;
      Integer i;
      list<Integer> li;
      list<Boolean> bs;
    case (Absyn.END(),(crs as (cr::_),li as (i::_),_::bs))
      then (Absyn.CALL(Absyn.CREF_IDENT("size",{}),Absyn.FUNCTIONARGS({cr,Absyn.INTEGER(i)},{})),(crs,li,bs));
    case (cr as Absyn.CREF(_),(_::crs,_::li,_::bs))
      then (cr,(crs,li,bs));
    case (exp,(crs,li,_::bs)) then (exp,(crs,li,bs));
  end match;
end replaceEndExit;

protected function replaceEnd
  "Single pass traversal that replaces end-expressions with the correct size-expression.
  It uses a couple of stacks and crap to handle all of this :)."
  input Absyn.ComponentRef cr;
  output Absyn.ComponentRef ocr;
algorithm
  ocr := Absyn.mapCrefParts(cr, replaceEnd2);
end replaceEnd;

protected function replaceEnd2
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
  (ocr,_) := Absyn.traverseExpBidirCref(cr,replaceEndEnter,replaceEndExit,({Absyn.CREF(stripcr)},{0},{true}));
  // print("replaceEnd  end  " +& Dump.printExpStr(Absyn.CREF(ocr)) +& "\n");
end replaceEnd2;

protected function fixTupleMetaModelica
  input Boolean isMetaModelica;
  input list<DAE.Exp> exps;
  input list<DAE.Type> types;
  input list<DAE.TupleConst> consts;
  output DAE.Exp exp;
  output DAE.Properties prop;
algorithm
  (exp,prop) := match (isMetaModelica,exps,types,consts)
    local
      DAE.Const c;
      list<DAE.Type> tys2;
      list<DAE.Exp> exps2;
    case (false,_,_,_)
      then (DAE.TUPLE(exps),DAE.PROP_TUPLE(DAE.T_TUPLE(types,DAE.emptyTypeSource),DAE.TUPLE_CONST(consts)));
    else
      equation
        c = Types.tupleConstListToConst(consts);
        tys2 = List.map(types, Types.boxIfUnboxedType);
        (exps2,tys2) = Types.matchTypeTuple(exps, types, tys2, false);
      then (DAE.META_TUPLE(exps2),DAE.PROP(DAE.T_METATUPLE(tys2,DAE.emptyTypeSource),c));
  end match;
end fixTupleMetaModelica;

annotation(__OpenModelica_Interface="frontend");
end Static;
