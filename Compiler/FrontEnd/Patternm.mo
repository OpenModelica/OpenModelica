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

package Patternm
" file:	       Patternm.mo
  package:     Patternm
  description: Patternmatching

  RCS: $Id$

  This module contains the patternmatch algorithm for the MetaModelica
  matchcontinue expression."

public import Absyn;
public import ClassInf;
public import Connect;
public import ConnectionGraph;
public import DAE;
public import Env;
public import SCode;
public import Dump;
public import InnerOuter;
public import Interactive;
public import Prefix;
public import Types;
public import UnitAbsyn;

protected import ComponentReference;
protected import DAEUtil;
protected import Expression;
protected import ExpressionDump;
protected import Error;
protected import Inst;
protected import InstSection;
protected import Lookup;
protected import MetaUtil;
protected import SCodeUtil;
protected import Static;
protected import Util;

protected function generatePositionalArgs "function: generatePositionalArgs
	author: KS
	This function is used in the following cases:
	v := matchcontinue (x)
  	  case REC(a=1,b=2)
   	 ...
	The named arguments a=1 and b=2 must be sorted and transformed into
	positional arguments (a,b is not necessarely the correct order).
"
  input list<Absyn.Ident> fieldNameList;
  input list<Absyn.NamedArg> namedArgList;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outList;
  output list<Absyn.NamedArg> outInvalidNames;
algorithm
  (outList,outInvalidNames) := matchcontinue (fieldNameList,namedArgList,accList)
    local
      list<Absyn.Exp> localAccList;
      list<Absyn.Ident> restFieldNames;
      Absyn.Ident firstFieldName;
      Absyn.Exp exp;
      list<Absyn.NamedArg> localNamedArgList;
    case ({},namedArgList,localAccList) then (listReverse(localAccList),namedArgList);
    case (firstFieldName :: restFieldNames,localNamedArgList,localAccList)
      equation
        (exp,localNamedArgList) = findFieldExpInList(firstFieldName,localNamedArgList);
        (localAccList,localNamedArgList) = generatePositionalArgs(restFieldNames,localNamedArgList,exp::localAccList);
      then (localAccList,localNamedArgList);
  end matchcontinue;
end generatePositionalArgs;

protected function findFieldExpInList "function: findFieldExpInList
	author: KS
	Helper function to generatePositionalArgs
"
  input Absyn.Ident firstFieldName;
  input list<Absyn.NamedArg> namedArgList;
  output Absyn.Exp outExp;
  output list<Absyn.NamedArg> outNamedArgList;
algorithm
  (outExp,outNamedArgList) := matchcontinue (firstFieldName,namedArgList)
    local
      Absyn.Exp e;
      Absyn.Ident localFieldName,aName;
      list<Absyn.NamedArg> rest;
      Absyn.NamedArg first;
    case (_,{}) then (Absyn.CREF(Absyn.WILD()),{});
    case (localFieldName,Absyn.NAMEDARG(aName,e) :: rest)
      equation
        true = stringEq(localFieldName,aName);
      then (e,rest);
    case (localFieldName,first::rest)
      equation
        (e,rest) = findFieldExpInList(localFieldName,rest);
      then (e,first::rest);
  end matchcontinue;
end findFieldExpInList;

protected function checkInvalidPatternNamedArgs
"Checks that there are no invalid named arguments in the pattern"
  input list<Absyn.NamedArg> args;
  input Util.Status status;
  input Absyn.Info info;
  output Util.Status outStatus;
algorithm
  outStatus := match (args,status,info)
    local
      list<String> argsNames;
      String str1;
    case ({},status,_) then status;
    case (args,status,info)
      equation
        (argsNames,_) = Absyn.getNamedFuncArgNamesAndValues(args);
        str1 = Util.stringDelimitList(argsNames, ",");
        Error.addSourceMessage(Error.META_INVALID_PATTERN_NAMED_FIELD, {str1}, info);
      then Util.FAILURE();
  end match;
end checkInvalidPatternNamedArgs;

public function elabPattern
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Exp lhs;
  input DAE.Type ty;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := elabPattern2(cache,env,lhs,ty,info);
end elabPattern;

protected function elabPattern2
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Exp lhs;
  input DAE.Type ty;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := match (cache,env,lhs,ty,info)
    local
      list<Absyn.Exp> exps;
      list<DAE.Type> tys;
      list<DAE.Pattern> patterns;
      Absyn.Exp exp,head,tail;
      String id,s,str;
      Integer i;
      Real r;
      Boolean b;
      DAE.Type ty1,ty2,tyHead,tyTail;
      Option<DAE.ExpType> et;
      DAE.Pattern patternHead,patternTail;
      Absyn.ComponentRef fcr;
      Absyn.FunctionArgs fargs;
      Absyn.Path utPath;

    case (cache,env,Absyn.INTEGER(i),ty,info)
      equation
        et = validPatternType(DAE.T_INTEGER_DEFAULT,ty,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,env,Absyn.REAL(r),ty,info)
      equation
        et = validPatternType(DAE.T_REAL_DEFAULT,ty,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.RCONST(r)));

    case (cache,env,Absyn.UNARY(Absyn.UMINUS(),Absyn.INTEGER(i)),ty,info)
      equation
        et = validPatternType(DAE.T_INTEGER_DEFAULT,ty,info);
        i = -i;
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,env,Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(r)),ty,info)
      equation
        et = validPatternType(DAE.T_REAL_DEFAULT,ty,info);
        r = realNeg(r);
      then (cache,DAE.PAT_CONSTANT(et,DAE.RCONST(r)));

    case (cache,env,Absyn.STRING(s),ty,info)
      equation
        et = validPatternType(DAE.T_STRING_DEFAULT,ty,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.SCONST(s)));

    case (cache,env,Absyn.BOOL(b),ty,info)
      equation
        et = validPatternType(DAE.T_BOOL_DEFAULT,ty,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.BCONST(b)));

    case (cache,env,Absyn.ARRAY({}),ty,info)
      equation
        et = validPatternType(DAE.T_LIST_DEFAULT,ty,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.LIST(DAE.ET_OTHER(),{})));

    case (cache,env,Absyn.ARRAY(exps),ty,info)
      equation
        lhs = Util.listFold(listReverse(exps), Absyn.makeCons, Absyn.ARRAY({}));
        (cache,pattern) = elabPattern(cache,env,lhs,ty,info);
      then (cache,pattern);

    case (cache,env,Absyn.CALL(Absyn.CREF_IDENT("NONE",{}),Absyn.FUNCTIONARGS({},{})),ty,info)
      equation
        _ = validPatternType(DAE.T_NONE_DEFAULT,ty,info);
      then (cache,DAE.PAT_CONSTANT(NONE(),DAE.META_OPTION(NONE())));

    case (cache,env,Absyn.CALL(Absyn.CREF_IDENT("SOME",{}),Absyn.FUNCTIONARGS({exp},{})),(DAE.T_METAOPTION(ty),_),info)
      equation
        (cache,pattern) = elabPattern(cache,env,exp,ty,info);
      then (cache,DAE.PAT_SOME(pattern));

    case (cache,env,Absyn.CONS(head,tail),tyTail as (DAE.T_LIST(tyHead),_),info)
      equation
        tyHead = Types.boxIfUnboxedType(tyHead);
        (cache,patternHead) = elabPattern(cache,env,head,tyHead,info);
        (cache,patternTail) = elabPattern(cache,env,tail,tyTail,info);
      then (cache,DAE.PAT_CONS(patternHead,patternTail));

    case (cache,env,Absyn.TUPLE(exps),(DAE.T_METATUPLE(tys),_),info)
      equation
        tys = Util.listMap(tys, Types.boxIfUnboxedType);
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,lhs);
      then (cache,DAE.PAT_META_TUPLE(patterns));

    case (cache,env,Absyn.TUPLE(exps),(DAE.T_TUPLE(tys),_),info)
      equation
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,lhs);
      then (cache,DAE.PAT_CALL_TUPLE(patterns));

    case (cache,env,lhs as Absyn.CALL(fcr,fargs),(DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)),SOME(utPath)),info)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,env,lhs as Absyn.CALL(fcr,fargs),(DAE.T_UNIONTYPE(_),SOME(utPath)),info)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,env,Absyn.AS(id,exp),ty2,info)
      equation
        (cache,DAE.TYPES_VAR(type_ = ty1),_,_) = Lookup.lookupIdent(cache,env,id);
        et = validPatternType(ty1,ty2,info);
        (cache,pattern) = elabPattern2(cache,env,exp,ty2,info);
        pattern = Util.if_(Types.isFunctionType(ty2), DAE.PAT_AS_FUNC_PTR(id,pattern), DAE.PAT_AS(id,et,pattern));
      then (cache,pattern);

    case (cache,env,Absyn.CREF(Absyn.CREF_IDENT(id,{})),ty2,info)
      equation
        (cache,DAE.TYPES_VAR(type_ = ty1),_,_) = Lookup.lookupIdent(cache,env,id);
        et = validPatternType(ty1,ty2,info);
        pattern = Util.if_(Types.isFunctionType(ty2), DAE.PAT_AS_FUNC_PTR(id,DAE.PAT_WILD()), DAE.PAT_AS(id,et,DAE.PAT_WILD()));
      then (cache,pattern);

    case (cache,env,Absyn.CREF(Absyn.WILD()),_,info) then (cache,DAE.PAT_WILD());

    case (cache,env,lhs,ty,info)
      equation
        str = Dump.printExpStr(lhs);
        Error.addSourceMessage(Error.META_INVALID_PATTERN, {str}, info);
      then fail();
  end match;
end elabPattern2;

protected function elabPatternTuple
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Exp> exps;
  input list<DAE.Type> tys;
  input Absyn.Info info;
  input Absyn.Exp lhs "for error messages";
  output Env.Cache outCache;
  output list<DAE.Pattern> patterns;
algorithm
  (outCache,patterns) := match (cache,env,exps,tys,info,lhs)
    local
      Absyn.Exp exp;
      String s;
      DAE.Pattern pattern;
      DAE.Type ty;
    case (cache,env,{},{},info,lhs) then (cache,{});
    case (cache,env,exp::exps,ty::tys,info,lhs)
      equation
        (cache,pattern) = elabPattern2(cache,env,exp,ty,info);
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,lhs);
      then (cache,pattern::patterns);
    case (cache,env,_,_,info,lhs)
      equation
        s = Dump.printExpStr(lhs);
        s = "pattern " +& s;
        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS, {s}, info);
      then fail();
  end match;
end elabPatternTuple;

protected function elabPatternCall
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Path callPath;
  input Absyn.FunctionArgs fargs;
  input Absyn.Path utPath;
  input Absyn.Info info;
  input Absyn.Exp lhs "for error messages";
  output Env.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := matchcontinue (cache,env,callPath,fargs,utPath,info,lhs)
    local
      Absyn.Exp exp;
      String s;
      DAE.Type ty,t;
      Absyn.Path utPath1,utPath2,fqPath;
      Integer index,numPosArgs;
      list<Absyn.NamedArg> namedArgList,invalidArgs;
      list<Absyn.Exp> funcArgsNamedFixed,funcArgs;
      list<String> fieldNameList,fieldNamesNamed;
      list<DAE.Type> fieldTypeList;
      list<DAE.Var> fieldVarList;
      list<DAE.Pattern> patterns;
      list<tuple<DAE.Pattern,String,DAE.ExpType>> namedPatterns;
    case (cache,env,callPath,Absyn.FUNCTIONARGS(funcArgs,namedArgList),utPath2,info,lhs)
      equation
        (cache,t as (DAE.T_METARECORD(utPath=utPath1,index=index,fields=fieldVarList),SOME(fqPath)),_) = Lookup.lookupType(cache, env, callPath, NONE());
        validUniontype(utPath1,utPath2,info,lhs);

        fieldTypeList = Util.listMap(fieldVarList, Types.getVarType);
        fieldNameList = Util.listMap(fieldVarList, Types.getVarName);
        
        numPosArgs = listLength(funcArgs);
        (_,fieldNamesNamed) = Util.listSplit(fieldNameList, numPosArgs);

        (funcArgsNamedFixed,invalidArgs) = generatePositionalArgs(fieldNamesNamed,namedArgList,{});
        funcArgs = listAppend(funcArgs,funcArgsNamedFixed);
        Util.SUCCESS() = checkInvalidPatternNamedArgs(invalidArgs,Util.SUCCESS(),info);
        (cache,patterns) = elabPatternTuple(cache,env,funcArgs,fieldTypeList,info,lhs);
      then (cache,DAE.PAT_CALL(fqPath,index,patterns));
    case (cache,env,callPath,Absyn.FUNCTIONARGS(funcArgs,namedArgList),utPath2,info,lhs)
      equation
        (cache,t as (DAE.T_FUNCTION(funcResultType = (DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_),complexVarLst=fieldVarList),_)),SOME(fqPath)),_) = Lookup.lookupType(cache, env, callPath, NONE());
        true = Absyn.pathEqual(fqPath,utPath2);

        fieldTypeList = Util.listMap(fieldVarList, Types.getVarType);
        fieldNameList = Util.listMap(fieldVarList, Types.getVarName);
        
        numPosArgs = listLength(funcArgs);
        (_,fieldNamesNamed) = Util.listSplit(fieldNameList, numPosArgs);

        (funcArgsNamedFixed,invalidArgs) = generatePositionalArgs(fieldNamesNamed,namedArgList,{});
        funcArgs = listAppend(funcArgs,funcArgsNamedFixed);
        Util.SUCCESS() = checkInvalidPatternNamedArgs(invalidArgs,Util.SUCCESS(),info);
        (cache,patterns) = elabPatternTuple(cache,env,funcArgs,fieldTypeList,info,lhs);
        namedPatterns = Util.listThread3Tuple(patterns, fieldNameList, Util.listMap(fieldTypeList,Types.elabType));
        namedPatterns = Util.listFilter(namedPatterns, filterEmptyPattern);
      then (cache,DAE.PAT_CALL_NAMED(fqPath,namedPatterns));
    case (cache,env,callPath,_,_,info,lhs)
      equation
        failure((_,_,_) = Lookup.lookupType(cache, env, callPath, NONE()));
        s = Absyn.pathString(callPath);
        Error.addSourceMessage(Error.META_DECONSTRUCTOR_NOT_RECORD, {s}, info);
      then fail();
  end matchcontinue;
end elabPatternCall;

protected function validPatternType
  input DAE.Type ty1;
  input DAE.Type ty2;
  input Absyn.Info info;
  output Option<DAE.ExpType> ty;
algorithm
  ty := matchcontinue (ty1,ty2,info)
    local
      DAE.ExpType et;
      String s1,s2,str;
      DAE.ComponentRef cr;
      DAE.Exp crefExp;
    
    case (ty1,(DAE.T_BOXED(ty2),_),_)
      equation
        cr = ComponentReference.makeCrefIdent("#DUMMY#",DAE.ET_OTHER(),{});
        crefExp = Expression.crefExp(cr);
        (_,ty1) = Types.matchType(crefExp,ty2,ty1,true);
        et = Types.elabType(ty1);
      then SOME(et);
    
    case (ty1,ty2,_)
      equation
        cr = ComponentReference.makeCrefIdent("#DUMMY#",DAE.ET_OTHER(),{});
        crefExp = Expression.crefExp(cr);
        (_,_) = Types.matchType(crefExp,ty2,ty1,true);
      then NONE();
    
    case (ty1,ty2,info)
      equation
        s1 = Types.unparseType(ty1);
        s2 = Types.unparseType(ty2);
        Error.addSourceMessage(Error.META_TYPE_MISMATCH_PATTERN, {s1,s2}, info);
      then fail();
  end matchcontinue;
end validPatternType;

protected function validUniontype
  input Absyn.Path path1;
  input Absyn.Path path2;
  input Absyn.Info info;
  input Absyn.Exp lhs;
algorithm
  _ := matchcontinue (path1,path2,info,lhs)
    local
      String s1,s2;
    case (path1,path2,_,_)
      equation
        true = Absyn.pathEqual(path1,path2);
      then ();
    else
      equation
        s1 = Absyn.pathString(path1);
        s2 = Absyn.pathString(path2);
        Error.addSourceMessage(Error.META_DECONSTRUCTOR_NOT_PART_OF_UNIONTYPE, {s1,s2}, info);
      then fail();
  end matchcontinue;
end validUniontype;

public function patternStr "Pattern to String unparsing"
  input DAE.Pattern pattern;
  output String str;
algorithm
  str := matchcontinue pattern
    local
      list<DAE.Pattern> pats;
      DAE.Exp exp;
      DAE.Pattern pat,head,tail;
      String id;
      DAE.ExpType et;
    case DAE.PAT_WILD() then "_";
    case DAE.PAT_AS(id,_,DAE.PAT_WILD()) then id;
    case DAE.PAT_SOME(pat)
      equation
        str = patternStr(pat);
      then "SOME(" +& str +& ")";
    case DAE.PAT_META_TUPLE(pats)
      equation
        str = Util.stringDelimitList(Util.listMap(pats,patternStr),",");
      then "Tuple(" +& str +& ")";

    case DAE.PAT_CONS(head,tail) then patternStr(head) +& "::" +& patternStr(tail);

    case DAE.PAT_CONSTANT(_,exp) then ExpressionDump.printExpStr(exp);
    // case DAE.PAT_CONSTANT(SOME(et),exp) then "(" +& ExpressionDump.typeString(et) +& ")" +& ExpressionDump.printExpStr(exp);
    case DAE.PAT_AS(id,_,pat) then id +& " as " +& patternStr(pat);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Patternm.patternStr not implemented correctly"});
      then "*PATTERN*";
  end matchcontinue;
end patternStr;

public function elabMatchExpression
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Exp matchExp;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numError;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<Interactive.InteractiveSymbolTable> outSt;
algorithm
  (outCache,outExp,outProperties,outSt) := matchcontinue (cache,env,matchExp,impl,inSt,performVectorization,inPrefix,info,numError)
    local
      Absyn.MatchType matchTy;
      Absyn.Exp inExp;
      list<Absyn.Exp> inExps;
      list<Absyn.ElementItem> decls;
      list<Absyn.Case> cases;
      list<DAE.Element> matchDecls;
      Option<Interactive.InteractiveSymbolTable> st;
      Prefix.Prefix pre;
      list<DAE.Exp> elabExps;
      list<DAE.MatchCase> elabCases;
      list<DAE.Type> tys;
      DAE.Properties prop;
      list<DAE.Properties> elabProps;
      DAE.Type resType;
      DAE.ExpType et;
      String str;
    case (cache,env,Absyn.MATCHEXP(matchTy=matchTy,inputExp=inExp,localDecls=decls,cases=cases),impl,st,performVectorization,pre,info,numError)
      equation
        (cache,SOME((env,DAE.DAE(matchDecls)))) = addLocalDecls(cache,env,decls,Env.matchScopeName,impl,info);
        inExps = MetaUtil.extractListFromTuple(inExp, 0);
        (cache,elabExps,elabProps,st) = Static.elabExpList(cache,env,inExps,impl,st,performVectorization,pre,info);
        tys = Util.listMap(elabProps, Types.getPropType);
        (cache,elabCases,resType,st) = elabMatchCases(cache,env,cases,tys,impl,st,performVectorization,pre,info);
        prop = DAE.PROP(resType,DAE.C_VAR());
        et = Types.elabType(resType);
      then (cache,DAE.MATCHEXPRESSION(matchTy,elabExps,matchDecls,elabCases,et),prop,st);
    else
      equation
        true = numError == Error.getNumErrorMessages();
        str = Dump.printExpStr(matchExp);
        Error.addSourceMessage(Error.META_MATCH_GENERAL_FAILURE, {str}, info);
      then fail();
  end matchcontinue;
end elabMatchExpression;

protected function elabMatchCases
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Case> cases;
  input list<DAE.Type> tys;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.MatchCase> elabCases;
  output DAE.Type resType;
  output Option<Interactive.InteractiveSymbolTable> outSt;
protected
  list<DAE.Exp> resExps;
  list<DAE.Type> resTypes;
algorithm
  (outCache,elabCases,resExps,resTypes,outSt) := elabMatchCases2(cache,env,cases,tys,impl,st,performVectorization,pre,info,{},{});
  (elabCases,resType) := fixCaseReturnTypes(elabCases,resExps,resTypes,info);
end elabMatchCases;

protected function elabMatchCases2
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Case> cases;
  input list<DAE.Type> tys;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  input list<DAE.Exp> accExps "Order does matter";
  input list<DAE.Type> accTypes "Order does not matter";
  output Env.Cache outCache;
  output list<DAE.MatchCase> elabCases;
  output list<DAE.Exp> resExps;
  output list<DAE.Type> resTypes;
  output Option<Interactive.InteractiveSymbolTable> outSt;
algorithm
  (outCache,elabCases,resExps,resTypes,outSt) := matchcontinue (cache,env,cases,tys,impl,st,performVectorization,pre,info,accExps,accTypes)
    local
      Absyn.Case case_;
      list<Absyn.Case> rest;
      DAE.MatchCase elabCase;
      list<DAE.MatchCase> elabCases;
      Option<DAE.Type> optType;
      Option<DAE.Exp> optExp;
    case (cache,env,{},tys,impl,st,performVectorization,pre,info,accExps,accTypes) then (cache,{},listReverse(accExps),listReverse(accTypes),st);
    case (cache,env,case_::rest,tys,impl,st,performVectorization,pre,info,accExps,accTypes)
      equation
        (cache,elabCase,optExp,optType,st) = elabMatchCase(cache,env,case_,tys,impl,st,performVectorization,pre,info);
        (cache,elabCases,accExps,accTypes,st) = elabMatchCases2(cache,env,rest,tys,impl,st,performVectorization,pre,info,Util.listConsOption(optExp,accExps),Util.listConsOption(optType,accTypes));
      then (cache,elabCase::elabCases,accExps,accTypes,st);
  end matchcontinue;
end elabMatchCases2;

protected function elabMatchCase
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Case acase;
  input list<DAE.Type> tys;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output DAE.MatchCase elabCase;
  output Option<DAE.Exp> resExp;
  output Option<DAE.Type> resType;
  output Option<Interactive.InteractiveSymbolTable> outSt;
algorithm
  (outCache,elabCase,resExp,resType,outSt) := matchcontinue (cache,env,acase,tys,impl,st,performVectorization,pre,info)
    local
      list<Absyn.Case> rest;
      Absyn.Exp result,pattern;
      list<Absyn.Exp> patterns;
      list<DAE.Pattern> elabPatterns;
      DAE.MatchCase case_;
      Option<DAE.Exp> elabResult;
      list<DAE.Element> caseDecls;
      list<Absyn.EquationItem> eq1;
      list<Absyn.AlgorithmItem> eqAlgs;
      list<SCode.Statement> algs;
      list<DAE.Statement> body;
      list<Absyn.ElementItem> decls;
      Absyn.Info patternInfo;
    case (cache,env,Absyn.CASE(pattern=pattern,patternInfo=patternInfo,localDecls=decls,equations=eq1,result=result),tys,impl,st,performVectorization,pre,info)
      equation
        (cache,SOME((env,DAE.DAE(caseDecls)))) = addLocalDecls(cache,env,decls,Env.caseScopeName,impl,info);
        patterns = MetaUtil.extractListFromTuple(pattern, 0);
        patterns = Util.if_(listLength(tys)==1, {pattern}, patterns);
        (cache,elabPatterns) = elabPatternTuple(cache, env, patterns, tys, patternInfo, pattern);
        (cache,eqAlgs) = Static.fromEquationsToAlgAssignments(eq1,{},cache,env,pre);
        algs = SCodeUtil.translateClassdefAlgorithmitems(eqAlgs);
        (cache,body) = InstSection.instStatements(cache, env, InnerOuter.emptyInstHierarchy, pre, algs, DAEUtil.addElementSourceFileInfo(DAE.emptyElementSource,patternInfo), SCode.NON_INITIAL(), true, Inst.neverUnroll);
        (cache,elabResult,resType,st) = elabResultExp(cache,env,result,impl,st,performVectorization,pre,patternInfo);
      then (cache,DAE.CASE(elabPatterns, caseDecls, body, elabResult),elabResult,resType,st);

      // ELSE is the same as CASE, but without pattern
    case (cache,env,Absyn.ELSE(localDecls=decls,equations=eq1,result=result),_,impl,st,performVectorization,pre,info)
      equation
        (cache,elabCase,elabResult,resType,st) = elabMatchCase(cache,env,Absyn.CASE(Absyn.TUPLE({}),info,decls,eq1,result,NONE()),{},impl,st,performVectorization,pre,info); 
      then (cache,elabCase,elabResult,resType,st);
        
  end matchcontinue;
end elabMatchCase;

protected function elabResultExp
  input Env.Cache cache;
  input Env.Env env;
  input Absyn.Exp exp;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<DAE.Exp> resExp;
  output Option<DAE.Type> resType;
  output Option<Interactive.InteractiveSymbolTable> outSt;
algorithm
  (outCache,resExp,resType,outSt) := match (cache,env,exp,impl,st,performVectorization,pre,info)
    local
      DAE.Exp elabExp;
      DAE.Properties prop;
      DAE.Type ty;
      list<Absyn.Exp> es;
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT("fail",{}), functionArgs = Absyn.FUNCTIONARGS({},{})),impl,st,performVectorization,pre,info)
      then (cache,NONE(),NONE(),st);
    case (cache,env,exp as Absyn.TUPLE(_),impl,st,performVectorization,pre,info)
      equation
        (cache,elabExp,prop,st) = Static.elabExp(cache,env,exp,impl,st,performVectorization,pre,info);
        ty = Types.getPropType(prop);
      then (cache,SOME(elabExp),SOME(ty),st);
    case (cache,env,exp,impl,st,performVectorization,pre,info)
      equation
        (cache,elabExp,prop,st) = Static.elabExp(cache,env,exp,impl,st,performVectorization,pre,info);
        ty = Types.getPropType(prop);
      then (cache,SOME(elabExp),SOME(ty),st);
  end match;
end elabResultExp;

protected function fixCaseReturnTypes
  input list<DAE.MatchCase> cases;
  input list<DAE.Exp> exps;
  input list<DAE.Type> tys;
  input Absyn.Info info;
  output list<DAE.MatchCase> outCases;
  output DAE.Type ty;
algorithm
  (outCases,ty) := matchcontinue (cases,exps,tys,info)
    local
      DAE.Type resType;
      String str;
    case (cases,{},{},info) then (cases,(DAE.T_NORETCALL(),NONE()));
    case (cases,exps,tys,info)
      equation
        ty = Util.listReduce(tys, Types.superType);
        ty = Types.superType(ty, ty);
        ty = Types.unboxedType(ty);
        ty = Types.makeRegularTupleFromMetaTupleOnTrue(Types.allTuple(tys),ty);
        exps = Types.matchTypes(exps, tys, ty, true);
        cases = fixCaseReturnTypes2(cases,exps,info);
      then (cases,ty);
    else
      equation
        tys = Util.listUnionOnTrue(tys, {}, Types.equivtypes);
        str = stringAppendList(Util.listMap1r(Util.listMap(tys, Types.unparseType), stringAppend, "\n  "));
        Error.addSourceMessage(Error.META_MATCHEXP_RESULT_TYPES, {str}, info);
      then fail();
  end matchcontinue;
end fixCaseReturnTypes;

public function fixCaseReturnTypes2
  input list<DAE.MatchCase> cases;
  input list<DAE.Exp> exps;
  input Absyn.Info info;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := matchcontinue (cases,exps,info)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> decls;
      list<DAE.Statement> body;
      DAE.Exp exp;
      DAE.MatchCase case_;
    case ({},{},_) then {};
    
    case (DAE.CASE(patterns,decls,body,SOME(_))::cases,exp::exps,info)
      equation
        cases = fixCaseReturnTypes2(cases,exps,info);
      then DAE.CASE(patterns,decls,body,SOME(exp))::cases;
    
    case ((case_ as DAE.CASE(result=NONE()))::cases,exps,info)
      equation
        cases = fixCaseReturnTypes2(cases,exps,info);
      then case_::cases;
    
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Patternm.fixCaseReturnTypes2 failed"}, info);
      then fail();
  end matchcontinue;
end fixCaseReturnTypes2;

public function traverseCases
  replaceable type A subtypeof Any;
  input list<DAE.MatchCase> cases;
  input FuncExpType func;
  input A a;
  output list<DAE.MatchCase> outCases;
  output A oa;
  partial function FuncExpType
    input tuple<DAE.Exp, A> inTpl;
    output tuple<DAE.Exp, A> outTpl;
  end FuncExpType;
algorithm
  (outCases,oa) := match (cases,func,a)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> decls;
      list<DAE.Statement> body;
      Option<DAE.Exp> result;
    case ({},_,a) then ({},a);
    case (DAE.CASE(patterns,decls,body,result)::cases,_,a)
      equation
        (body,(_,a)) = DAEUtil.traverseDAEEquationsStmts(body,Expression.traverseSubexpressionsHelper,(func,a));
        ((result,a)) = Expression.traverseExpOpt(result,func,a);
        (cases,a) = traverseCases(cases,func,a); 
      then (DAE.CASE(patterns,decls,body,result)::cases,a);
  end match;
end traverseCases;

protected function filterEmptyPattern
  input tuple<DAE.Pattern,String,DAE.ExpType> tpl;
algorithm
  _ := match tpl
    case ((DAE.PAT_WILD(),_,_)) then fail();
    else ();
  end match;
end filterEmptyPattern;

protected function addLocalDecls
"Adds local declarations to the environment and returns the DAE"
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.ElementItem> els;
  input String scopeName;
  input Boolean impl;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<Env.Env,DAE.DAElist>> tpl;
algorithm
  (outCache,tpl) := matchcontinue (cache,env,els,scopeName,impl,info)
    local
      list<Absyn.ElementItem> ld;
      list<SCode.Element> ld2,ld3,ld4;
      list<tuple<SCode.Element, DAE.Mod>> ld_mod;      
      DAE.DAElist dae,dae1;
      list<DAE.Element> dae1_2Elts;
      Env.Env env2;
      ClassInf.State dummyFunc;
      list<Absyn.AlgorithmItem> algs;
      String str;

    case (cache,env,{},scopeName,impl,info) then (cache,SOME((env,DAEUtil.emptyDae)));
    case (cache,env,ld,scopeName,impl,info)
      equation
        env2 = Env.openScope(env, false, SOME(scopeName),NONE());

        // Tranform declarations such as Real x,y; to Real x; Real y;
        ld2 = SCodeUtil.translateEitemlist(ld,false);

        // Filter out the components (just to be sure)
        true = Util.listFold(Util.listMap1(ld2, SCode.isComponentWithDirection, Absyn.BIDIR()), boolAnd, true);

        // Transform the element list into a list of element,NOMOD
        ld_mod = Inst.addNomod(ld2);

        dummyFunc = ClassInf.FUNCTION(Absyn.IDENT("dummieFunc"));
        (cache,env2,_) = Inst.addComponentsToEnv(cache, env2,
          InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(),
          Connect.emptySet, dummyFunc, ld_mod, {}, {}, {}, impl);
        (cache,env2,_,_,dae1,_,_,_,_) = Inst.instElementList(
          cache,env2, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), Connect.emptySet, dummyFunc, ld_mod, {},
          impl, Inst.INNER_CALL(), ConnectionGraph.EMPTY);
      then (cache,SOME((env2,dae1)));
      
    case (cache,env,ld,scopeName,impl,info)
      equation
        ld2 = SCodeUtil.translateEitemlist(ld,false);
        (ld2 as _::_) = Util.listFilterBoolean(ld2, SCode.isNotComponent);
        str = Util.stringDelimitList(Util.listMap(ld2, SCode.unparseElementStr),", ");
        Error.addSourceMessage(Error.META_INVALID_LOCAL_ELEMENT,{str},info);
      then (cache,NONE());
      
    case (cache,env,ld,scopeName,impl,info)
      equation
        env2 = Env.openScope(env, false, SOME(scopeName),NONE());

        // Tranform declarations such as Real x,y; to Real x; Real y;
        ld2 = SCodeUtil.translateEitemlist(ld,false);

        // Filter out the components (just to be sure)
        ld3 = Util.listSelect1(ld2, Absyn.INPUT(), SCode.isComponentWithDirection);
        ld4 = Util.listSelect1(ld2, Absyn.OUTPUT(), SCode.isComponentWithDirection);
        (ld2 as _::_) = listAppend(ld3,ld4); // I don't care that this is slow; it's just for error message generation
        str = Util.stringDelimitList(Util.listMap(ld2, SCode.unparseElementStr),", ");
        Error.addSourceMessage(Error.META_INVALID_LOCAL_ELEMENT,{str},info);
      then (cache,NONE());
      
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"Patternm.addLocalDecls failed"},info);
      then (cache,NONE());
  end matchcontinue;
end addLocalDecls;

public function resultExps
  input list<DAE.MatchCase> cases;
  output list<DAE.Exp> exps;
algorithm
  exps := match cases
    local
      DAE.Exp exp;
    case {} then {};
    case (DAE.CASE(result=SOME(exp))::cases)
      equation
        exps = resultExps(cases);
      then exp::exps;
    case (_::cases) then resultExps(cases);
  end match;
end resultExps;

end Patternm;
