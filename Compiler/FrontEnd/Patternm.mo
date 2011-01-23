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

encapsulated package Patternm
" file:         Patternm.mo
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
public import HashTableStringToPath;
public import SCode;
public import Dump;
public import InnerOuter;
public import Interactive;
public import Prefix;
public import Types;
public import UnitAbsyn;

protected import BaseHashTable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import Error;
protected import Inst;
protected import InstSection;
protected import Lookup;
protected import MetaUtil;
protected import RTOpts;
protected import SCodeUtil;
protected import Static;
protected import System;
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
  (outList,outInvalidNames) := match (fieldNameList,namedArgList,accList)
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
  end match;
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
        et = validPatternType(DAE.T_INTEGER_DEFAULT,ty,lhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,env,Absyn.REAL(r),ty,info)
      equation
        et = validPatternType(DAE.T_REAL_DEFAULT,ty,lhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.RCONST(r)));

    case (cache,env,Absyn.UNARY(Absyn.UMINUS(),Absyn.INTEGER(i)),ty,info)
      equation
        et = validPatternType(DAE.T_INTEGER_DEFAULT,ty,lhs,info);
        i = -i;
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,env,Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(r)),ty,info)
      equation
        et = validPatternType(DAE.T_REAL_DEFAULT,ty,lhs,info);
        r = realNeg(r);
      then (cache,DAE.PAT_CONSTANT(et,DAE.RCONST(r)));

    case (cache,env,Absyn.STRING(s),ty,info)
      equation
        et = validPatternType(DAE.T_STRING_DEFAULT,ty,lhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.SCONST(s)));

    case (cache,env,Absyn.BOOL(b),ty,info)
      equation
        et = validPatternType(DAE.T_BOOL_DEFAULT,ty,lhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.BCONST(b)));

    case (cache,env,Absyn.ARRAY({}),ty,info)
      equation
        et = validPatternType(DAE.T_LIST_DEFAULT,ty,lhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.LIST({})));

    case (cache,env,Absyn.ARRAY(exps),ty,info)
      equation
        lhs = Util.listFold(listReverse(exps), Absyn.makeCons, Absyn.ARRAY({}));
        (cache,pattern) = elabPattern(cache,env,lhs,ty,info);
      then (cache,pattern);

    case (cache,env,Absyn.CALL(Absyn.CREF_IDENT("NONE",{}),Absyn.FUNCTIONARGS({},{})),ty,info)
      equation
        _ = validPatternType(DAE.T_NONE_DEFAULT,ty,lhs,info);
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
        et = validPatternType(ty1,ty2,lhs,info);
        (cache,pattern) = elabPattern2(cache,env,exp,ty2,info);
        pattern = Util.if_(Types.isFunctionType(ty2), DAE.PAT_AS_FUNC_PTR(id,pattern), DAE.PAT_AS(id,et,pattern));
      then (cache,pattern);

    case (cache,env,Absyn.CREF(Absyn.CREF_IDENT(id,{})),ty2,info)
      equation
        (cache,DAE.TYPES_VAR(type_ = ty1),_,_) = Lookup.lookupIdent(cache,env,id);
        et = validPatternType(ty1,ty2,lhs,info);
        pattern = Util.if_(Types.isFunctionType(ty2), DAE.PAT_AS_FUNC_PTR(id,DAE.PAT_WILD()), DAE.PAT_AS(id,et,DAE.PAT_WILD()));
      then (cache,pattern);

    case (cache,env,Absyn.CREF(Absyn.WILD()),_,info) then (cache,DAE.PAT_WILD());

    case (cache,env,lhs,ty,info)
      equation
        str = Dump.printExpStr(lhs) +& " of type " +& Types.unparseType(ty);
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
      String s;
      DAE.Type t;
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
  input Absyn.Exp lhs;
  input Absyn.Info info;
  output Option<DAE.ExpType> ty;
algorithm
  ty := matchcontinue (ty1,ty2,lhs,info)
    local
      DAE.ExpType et;
      String s,s1,s2;
      DAE.ComponentRef cr;
      DAE.Exp crefExp;
    
    case (ty1,(DAE.T_BOXED(ty2),_),_,_)
      equation
        cr = ComponentReference.makeCrefIdent("#DUMMY#",DAE.ET_OTHER(),{});
        crefExp = Expression.crefExp(cr);
        (_,ty1) = Types.matchType(crefExp,ty2,ty1,true);
        et = Types.elabType(ty1);
      then SOME(et);
    
    case (ty1,ty2,_,_)
      equation
        cr = ComponentReference.makeCrefIdent("#DUMMY#",DAE.ET_OTHER(),{});
        crefExp = Expression.crefExp(cr);
        (_,_) = Types.matchType(crefExp,ty2,ty1,true);
      then NONE();
    
    case (ty1,ty2,lhs,info)
      equation
        s = Dump.printExpStr(lhs);
        s1 = Types.unparseType(ty1);
        s2 = Types.unparseType(ty2);
        Error.addSourceMessage(Error.META_TYPE_MISMATCH_PATTERN, {s,s1,s2}, info);
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
      String s,s1,s2;
    case (path1,path2,_,_)
      equation
        true = Absyn.pathEqual(path1,path2);
      then ();
    else
      equation
        s = Dump.printExpStr(lhs);
        s1 = Absyn.pathString(path1);
        s2 = Absyn.pathString(path2);
        Error.addSourceMessage(Error.META_DECONSTRUCTOR_NOT_PART_OF_UNIONTYPE, {s,s1,s2}, info);
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
      list<String> fields,patsStr;
      DAE.Exp exp;
      DAE.Pattern pat,head,tail;
      String id;
      list<tuple<DAE.Pattern,String,DAE.ExpType>> namedpats;
      Absyn.Path name;
    case DAE.PAT_WILD() then "_";
    case DAE.PAT_AS(id=id,pat=DAE.PAT_WILD()) then id;
    case DAE.PAT_AS_FUNC_PTR(id,DAE.PAT_WILD()) then id;
    case DAE.PAT_SOME(pat)
      equation
        str = patternStr(pat);
      then "SOME(" +& str +& ")";
    case DAE.PAT_META_TUPLE(pats)
      equation
        str = Util.stringDelimitList(Util.listMap(pats,patternStr),",");
      then "(" +& str +& ")";
        
    case DAE.PAT_CALL_TUPLE(pats)
      equation
        str = Util.stringDelimitList(Util.listMap(pats,patternStr),",");
      then "(" +& str +& ")";
    
    case DAE.PAT_CALL(name=name, patterns=pats)
      equation
        id = Absyn.pathString(name);
        str = Util.stringDelimitList(Util.listMap(pats,patternStr),",");
      then stringAppendList({id,"(",str,")"});

    case DAE.PAT_CALL_NAMED(name=name, patterns=namedpats)
      equation
        id = Absyn.pathString(name);
        fields = Util.listMap(namedpats, Util.tuple32);
        patsStr = Util.listMap1r(Util.listMapMap(namedpats, Util.tuple31, patternStr), stringAppend, "=");
        str = Util.stringDelimitList(Util.listThreadMap(fields, patsStr, stringAppend), ",");
      then stringAppendList({id,"(",str,")"});

    case DAE.PAT_CONS(head,tail) then patternStr(head) +& "::" +& patternStr(tail);

    case DAE.PAT_CONSTANT(exp=exp) then ExpressionDump.printExpStr(exp);
    // case DAE.PAT_CONSTANT(SOME(et),exp) then "(" +& ExpressionDump.typeString(et) +& ")" +& ExpressionDump.printExpStr(exp);
    case DAE.PAT_AS(id=id,pat=pat) then id +& " as " +& patternStr(pat);
    case DAE.PAT_AS_FUNC_PTR(id, pat) then id +& " as " +& patternStr(pat);
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
      DAE.Exp exp;
      HashTableStringToPath.HashTable ht;
      DAE.MatchType elabMatchTy;
    case (cache,env,Absyn.MATCHEXP(matchTy=matchTy,inputExp=inExp,localDecls=decls,cases=cases),impl,st,performVectorization,pre,info,numError)
      equation
        (cache,SOME((env,DAE.DAE(matchDecls)))) = addLocalDecls(cache,env,decls,Env.matchScopeName,impl,info);
        inExps = MetaUtil.extractListFromTuple(inExp, 0);
        (cache,elabExps,elabProps,st) = Static.elabExpList(cache,env,inExps,impl,st,performVectorization,pre,info);
        tys = Util.listMap(elabProps, Types.getPropType);
        (cache,elabCases,resType,st) = elabMatchCases(cache,env,cases,tys,impl,st,performVectorization,pre,info);
        prop = DAE.PROP(resType,DAE.C_VAR());
        et = Types.elabType(resType);
        (elabExps,elabCases) = filterUnusedPatterns(elabExps,elabCases) "filterUnusedPatterns() First time to speed up the other optimizations.";
        elabCases = caseDeadCodeEliminiation(matchTy, elabCases, {}, {}, false);
        // Do DCE before converting mc to m
        matchTy = optimizeContinueToMatch(matchTy,elabCases,info);
        elabCases = optimizeContinueJumps(matchTy, elabCases);
        ht = getUsedLocalCrefs(RTOpts.debugFlag("patternmSkipFilterUnusedAsBindings"),DAE.MATCHEXPRESSION(DAE.MATCHCONTINUE(),elabExps,matchDecls,elabCases,et));
        (matchDecls,ht) = filterUnusedDecls(matchDecls,ht,{},HashTableStringToPath.emptyHashTable());
        elabCases = filterUnusedAsBindings(elabCases,ht);
        (elabExps,elabCases) = filterUnusedPatterns(elabExps,elabCases) "filterUnusedPatterns() Then again to filter out the last parts.";
        elabMatchTy = optimizeMatchToSwitch(matchTy,elabCases,info);
        exp = DAE.MATCHEXPRESSION(elabMatchTy,elabExps,matchDecls,elabCases,et);
      then (cache,exp,prop,st);
    else
      equation
        true = numError == Error.getNumErrorMessages();
        str = Dump.printExpStr(matchExp);
        Error.addSourceMessage(Error.META_MATCH_GENERAL_FAILURE, {str}, info);
      then fail();
  end matchcontinue;
end elabMatchExpression;

protected function optimizeMatchToSwitch
  "match str case 'str1' ... case 'str2' case 'str3' => switch hash(str)...
  match ut case UT1 ... case UT2 ... case UT3 => switch valueConstructor(ut)...
  Works if all values are unique. Also works if there is one 'default' case at the end of the list.
  
  NOT YET WORKING CODE! Code generation does not know about this.
  We need DAE.MATCH/CONTINUE/SWITCH instead of Absyn.MATCH/CONTINUE
  "
  input Absyn.MatchType matchTy;
  input list<DAE.MatchCase> cases;
  input Absyn.Info info;
  output DAE.MatchType outType;
algorithm
  outType := matchcontinue (matchTy,cases,info)
    local
      tuple<Integer,DAE.ExpType,Integer> tpl;
      list<list<DAE.Pattern>> patternMatrix;
      String str;
      DAE.ExpType ty;
    case (Absyn.MATCHCONTINUE(),_,_) then DAE.MATCHCONTINUE();
    case (_,cases,_)
      equation
        true = listLength(cases) > 2;
        patternMatrix = Util.transposeList(Util.listMap(cases,getCasePatterns));
        tpl = findPatternToConvertToSwitch(patternMatrix,0,info);
        (_,ty,_) = tpl;
        str = ExpressionDump.typeString(ty);
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"),Error.MATCH_TO_SWITCH_OPTIMIZATION, {str}, info);
      then DAE.MATCH(SOME(tpl));
    else DAE.MATCH(NONE());
  end matchcontinue;
end optimizeMatchToSwitch;

protected function findPatternToConvertToSwitch
  input list<list<DAE.Pattern>> patternMatrix;
  input Integer index;
  input Absyn.Info info;
  output tuple<Integer,DAE.ExpType,Integer> tpl;
algorithm
  tpl := matchcontinue  (patternMatrix,index,info)
    local
      list<DAE.Pattern> pats;
      String str;
      DAE.ExpType ty;
      Integer extraarg;
    case (pats::patternMatrix,index,info)
      equation
        (ty,extraarg) = findPatternToConvertToSwitch2(pats, {}, DAE.ET_OTHER());
      then ((index,ty,extraarg));
    case (_::patternMatrix,index,info)
      then findPatternToConvertToSwitch(patternMatrix,index+1,info);
  end matchcontinue;
end findPatternToConvertToSwitch;

protected function findPatternToConvertToSwitch2
  input list<DAE.Pattern> pats;
  input list<Integer> ixs;
  input DAE.ExpType ty;
  output DAE.ExpType outTy;
  output Integer extraarg;
algorithm
  (outTy,extraarg) := match (pats,ixs,ty)
    local
      Integer ix;
      String str;
      // Always jump to the last pattern as a default case? Seems reasonable, but requires knowledge about the other patterns...
    case ({},ixs,DAE.ET_STRING())
      equation
        // Should probably start at realCeil(log2(listLength(ixs))), but we don't have log2 in RML :)
        true = listLength(ixs)>7; // hashing has a considerable overhead, only convert to switch if it is worth it
        ix = findMinMod(ixs,1);
      then (DAE.ET_STRING(),ix);
    case ({},_,_) then (ty,0);
    case (DAE.PAT_CONSTANT(exp=DAE.SCONST(str))::pats,ixs,_)
      equation
        ix = System.stringHashDjb2Mod(str,65536);
        false = listMember(ix,ixs);
        (ty,extraarg) = findPatternToConvertToSwitch2(pats,ix::ixs,DAE.ET_STRING());
      then (ty,extraarg);
    case (DAE.PAT_CALL(index=ix)::pats,ixs,_)
      equation
        false = listMember(ix,ixs);
        (ty,extraarg) = findPatternToConvertToSwitch2(pats,ix::ixs,DAE.ET_METATYPE());
      then (ty,extraarg);
    case (DAE.PAT_CONSTANT(exp=DAE.ICONST(ix))::pats,ixs,_)
      equation
        false = listMember(ix,ixs);
        (ty,extraarg) = findPatternToConvertToSwitch2(pats,ix::ixs,DAE.ET_INT());
      then (ty,extraarg);
  end match;
end findPatternToConvertToSwitch2;

protected function findMinMod
  input list<Integer> ixs;
  input Integer mod;
  output Integer outMod;
algorithm
  outMod := matchcontinue (ixs,mod)
    case (ixs,mod)
      equation
        ixs = Util.listMap1(ixs, intMod, mod);
        ixs = Util.sort(ixs, intLt);
        (_,{}) = Util.splitUniqueOnBool(ixs, intEq);
        // This mod was high enough that all values were distinct
      then mod;
    else
      equation
        true = mod < 65536;
      then findMinMod(ixs,mod*2);
  end matchcontinue;
end findMinMod;

protected function filterUnusedPatterns
  "case (1,_,_) then ...; case (2,_,_) then ...; =>"
  input list<DAE.Exp> inputs "We can only remove inputs that are free from side-effects";
  input list<DAE.MatchCase> cases;
  output list<DAE.Exp> outInputs;
  output list<DAE.MatchCase> outCases;
algorithm
  (outInputs,outCases) := matchcontinue (inputs,cases)
    local
      list<list<DAE.Pattern>> patternMatrix;
    case (inputs,cases)
      equation
        patternMatrix = Util.transposeList(Util.listMap(cases,getCasePatterns));
        (true,outInputs,patternMatrix) = filterUnusedPatterns2(inputs,patternMatrix,false,{},{});
        patternMatrix = Util.transposeList(patternMatrix);
        cases = Util.listThreadMap(cases,patternMatrix,setCasePatterns);
      then (outInputs,cases);
    else (inputs,cases);
  end matchcontinue;
end filterUnusedPatterns;

protected function filterUnusedPatterns2
  "case (1,_,_) then ...; case (2,_,_) then ...; =>"
  input list<DAE.Exp> inputs "We can only remove inputs that are free from side-effects";
  input list<list<DAE.Pattern>> patternMatrix;
  input Boolean change "Only rebuild the cases if something changed";
  input list<DAE.Exp> inputsAcc;
  input list<list<DAE.Pattern>> patternMatrixAcc;
  output Boolean outChange;
  output list<DAE.Exp> outInputs;
  output list<list<DAE.Pattern>> outPatternMatrix;
algorithm
  (outChange,outInputs,outPatternMatrix) := matchcontinue (inputs,patternMatrix,change,inputsAcc,patternMatrixAcc)
    local
      DAE.Exp e;
      list<DAE.Pattern> pats;
    case ({},{},true,inputsAcc,patternMatrixAcc)
      then (true,listReverse(inputsAcc),listReverse(patternMatrixAcc));
    case (e::inputs,pats::patternMatrix,_,inputsAcc,patternMatrixAcc)
      equation
        ((_,true)) = Expression.traverseExp(e,Expression.hasNoSideEffects,true);
        true = allPatternsWild(pats);
        (outChange,outInputs,outPatternMatrix) = filterUnusedPatterns2(inputs,patternMatrix,true,inputsAcc,patternMatrixAcc);
      then (outChange,outInputs,outPatternMatrix);
    case (e::inputs,pats::patternMatrix,change,inputsAcc,patternMatrixAcc)
      equation
        (outChange,outInputs,outPatternMatrix) = filterUnusedPatterns2(inputs,patternMatrix,change,e::inputsAcc,pats::patternMatrixAcc);
      then (outChange,outInputs,outPatternMatrix);
    else (false,{},{});
  end matchcontinue;
end filterUnusedPatterns2;

protected function getUsedLocalCrefs
  input Boolean skipFilterUnusedAsBindings "if true, traverse the whole expression; else only the bodies and results";
  input DAE.Exp exp;
  output HashTableStringToPath.HashTable ht;
algorithm
  ht := match (skipFilterUnusedAsBindings,exp)
    local
      list<DAE.MatchCase> cases;
    case (true,exp)
      equation
        ((_,ht)) = Expression.traverseExp(exp, addLocalCref, HashTableStringToPath.emptyHashTable());
      then ht;
    case (false,DAE.MATCHEXPRESSION(cases=cases))
      equation
        (_,ht) = traverseCases(cases, addLocalCref, HashTableStringToPath.emptyHashTable());
      then ht;
  end match;
end getUsedLocalCrefs;

protected function filterUnusedAsBindings
  input list<DAE.MatchCase> cases;
  input HashTableStringToPath.HashTable ht;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := match (cases,ht)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> localDecls;
      list<DAE.Statement> body;
      Option<DAE.Exp> result;
      Integer jump;
      Absyn.Info info;
    case ({},_) then {};
    case (DAE.CASE(patterns, localDecls, body, result, jump, info)::cases,ht)
      equation
        (patterns,_) = traversePatternList(patterns, removePatternAsBinding, (ht,info));
        cases = filterUnusedAsBindings(cases,ht);
      then DAE.CASE(patterns, localDecls, body, result, jump, info)::cases;
  end match;
end filterUnusedAsBindings;

protected function removePatternAsBinding
  input tuple<DAE.Pattern,tuple<HashTableStringToPath.HashTable,Absyn.Info>> inTpl;
  output tuple<DAE.Pattern,tuple<HashTableStringToPath.HashTable,Absyn.Info>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      HashTableStringToPath.HashTable ht;
      DAE.Pattern pat;
      String id;
      Absyn.Info info;
      tuple<HashTableStringToPath.HashTable,Absyn.Info> tpl;
    case ((DAE.PAT_AS(id=id,pat=pat),tpl as (ht,info)))
      equation
        _ = BaseHashTable.get(id, ht);
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"),Error.META_UNUSED_AS_BINDING, {id}, info);
      then ((pat,tpl));
    case ((DAE.PAT_AS_FUNC_PTR(id=id,pat=pat),tpl as (ht,info)))
      equation
        _ = BaseHashTable.get(id, ht);
      then ((pat,tpl));
    else simplifyPattern(inTpl);
  end matchcontinue;
end removePatternAsBinding;

protected function addLocalCref
"Use with traverseExp to collect all CREF's that could be references to local
variables."
  input tuple<DAE.Exp,HashTableStringToPath.HashTable> inTpl;
  output tuple<DAE.Exp,HashTableStringToPath.HashTable> outTpl;
algorithm
  outTpl := match inTpl
    local
      DAE.Exp exp;
      HashTableStringToPath.HashTable ht;
      String name;
      list<DAE.MatchCase> cases;
      DAE.Pattern pat;
      list<DAE.Subscript> subs;
    case ((exp as DAE.CREF(componentRef=DAE.CREF_IDENT(ident=name,subscriptLst=subs)),ht))
      equation
        ht = addLocalCrefSubs(subs,ht);
        ht = BaseHashTable.add((name,Absyn.IDENT("")), ht);
      then ((exp,ht));
    case ((exp as DAE.CALL(path=Absyn.IDENT(name), builtin=false),ht))
      equation
        ht = BaseHashTable.add((name,Absyn.IDENT("")), ht);
      then ((exp,ht));
    case ((exp as DAE.PATTERN(pattern=pat),ht))
      equation
        ((_,ht)) = traversePattern((pat,ht), addPatternAsBindings);
      then ((exp,ht));
    case ((exp as DAE.MATCHEXPRESSION(cases=cases),ht))
      equation
        ht = addCasesLocalCref(cases,ht);
      then ((exp,ht));
    else inTpl;
  end match;
end addLocalCref;

protected function addLocalCrefSubs
  "Cref subscripts may also contain crefs"
  input list<DAE.Subscript> subs;
  input HashTableStringToPath.HashTable ht;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (subs,ht)
    local
      DAE.Exp exp;
    case ({},ht) then ht;
    case (DAE.SLICE(exp)::subs,ht)
      equation
        ((_,ht)) = Expression.traverseExp(exp, addLocalCref, ht);
        ht = addLocalCrefSubs(subs,ht);
      then ht;
    case (DAE.INDEX(exp)::subs,ht)
      equation
        ((_,ht)) = Expression.traverseExp(exp, addLocalCref, ht);
        ht = addLocalCrefSubs(subs,ht);
      then ht;
    else ht;
  end match;
end addLocalCrefSubs;

protected function addCasesLocalCref
  input list<DAE.MatchCase> cases;
  input HashTableStringToPath.HashTable ht;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (cases,ht)
    local
      list<DAE.Pattern> pats;
    case ({},ht) then ht;
    case (DAE.CASE(patterns=pats)::cases,ht)
      equation
        (_,ht) = traversePatternList(pats, addPatternAsBindings, ht);
        ht = addCasesLocalCref(cases,ht);
      then ht;
  end match;
end addCasesLocalCref;

protected function simplifyPattern
  "Simplifies a pattern, for example (_,_,_)=>_. For use with traversePattern"
  input tuple<DAE.Pattern,A> itpl;
  output tuple<DAE.Pattern,A> otpl;
  replaceable type A subtypeof Any;
algorithm
  otpl := match itpl
    local
      Absyn.Path name;
      A a;
      DAE.Pattern pat;
      list<tuple<DAE.Pattern, String, DAE.ExpType>> namedPatterns;
      list<DAE.Pattern> patterns;
    case ((DAE.PAT_CALL_NAMED(name, namedPatterns),a))
      equation
        namedPatterns = Util.listFilter(namedPatterns, filterEmptyPattern);
        pat = Util.if_(Util.isListEmpty(namedPatterns), DAE.PAT_WILD(), DAE.PAT_CALL_NAMED(name, namedPatterns));
      then ((pat,a));
    case ((pat as DAE.PAT_CALL_TUPLE(patterns),a))
      equation
        pat = Util.if_(allPatternsWild(patterns), DAE.PAT_WILD(), pat);
      then ((pat,a));
    case ((pat as DAE.PAT_META_TUPLE(patterns),a))
      equation
        pat = Util.if_(allPatternsWild(patterns), DAE.PAT_WILD(), pat);
      then ((pat,a));
    else itpl;
  end match;
end simplifyPattern;

protected function addPatternAsBindings
  "Traverse patterns and as-bindings as variable references in the hashtable"
  input tuple<DAE.Pattern,HashTableStringToPath.HashTable> inTpl;
  output tuple<DAE.Pattern,HashTableStringToPath.HashTable> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      HashTableStringToPath.HashTable ht;
      DAE.Pattern pat;
      String id;
    case ((pat as DAE.PAT_AS(id=id),ht))
      equation
        ht = BaseHashTable.add((id,Absyn.IDENT("")), ht);
      then ((pat,ht));
    case ((pat as DAE.PAT_AS_FUNC_PTR(id=id),ht))
      equation
        ht = BaseHashTable.add((id,Absyn.IDENT("")), ht);
      then ((pat,ht));
    else inTpl;
  end matchcontinue;
end addPatternAsBindings;

protected function traversePatternList
  input list<DAE.Pattern> pats;
  input Func func;
  input TypeA a;
  output list<DAE.Pattern> outPats;
  output TypeA oa;
  partial function Func
    input tuple<DAE.Pattern,TypeA> inTpl;
    output tuple<DAE.Pattern,TypeA> outTpl;
  end Func;
  replaceable type TypeA subtypeof Any;
algorithm
  (outPats,oa) := match (pats,func,a)
    local
      DAE.Pattern pat;
    case ({},func,a) then ({},a);
    case (pat::pats,func,a)
      equation
        ((pat,a)) = traversePattern((pat,a),func);
        (pats,a) = traversePatternList(pats,func,a);
      then (pat::pats,a);
  end match;
end traversePatternList;

protected function traversePattern
  input tuple<DAE.Pattern,TypeA> inTpl;
  input Func func;
  output tuple<DAE.Pattern,TypeA> outTpl;
  partial function Func
    input tuple<DAE.Pattern,TypeA> inTpl;
    output tuple<DAE.Pattern,TypeA> outTpl;
  end Func;
  replaceable type TypeA subtypeof Any;
algorithm
  outTpl := match (inTpl,func)
    local
      TypeA a;
      DAE.Pattern pat,pat1,pat2;
      list<DAE.Pattern> pats;
      list<String> fields;
      list<DAE.ExpType> types;
      String id,str;
      Option<DAE.ExpType> ty;
      Absyn.Path name;
      Integer index;
      list<tuple<DAE.Pattern,String,DAE.ExpType>> namedpats;
    case ((DAE.PAT_AS(id,ty,pat2),a),func)
      equation
        ((pat2,a)) = traversePattern((pat2,a),func);
        pat = DAE.PAT_AS(id,ty,pat2);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_AS_FUNC_PTR(id,pat2),a),func)
      equation
        ((pat2,a)) = traversePattern((pat2,a),func);
        pat = DAE.PAT_AS_FUNC_PTR(id,pat2);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CALL(name,index,pats),a),func)
      equation
        (pats,a) = traversePatternList(pats, func, a);
        pat = DAE.PAT_CALL(name,index,pats);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CALL_NAMED(name,namedpats),a),func)
      equation
        pats = Util.listMap(namedpats,Util.tuple31);
        fields = Util.listMap(namedpats,Util.tuple32);
        types = Util.listMap(namedpats,Util.tuple33);
        namedpats = Util.listThread3Tuple(pats, fields, types);
        pat = DAE.PAT_CALL_NAMED(name,namedpats);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CALL_TUPLE(pats),a),func)
      equation
        (pats,a) = traversePatternList(pats, func, a);
        pat = DAE.PAT_CALL_TUPLE(pats);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_META_TUPLE(pats),a),func)
      equation
        (pats,a) = traversePatternList(pats, func, a);
        pat = DAE.PAT_META_TUPLE(pats);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CONS(pat1,pat2),a),func)
      equation
        ((pat1,a)) = traversePattern((pat1,a),func);
        ((pat2,a)) = traversePattern((pat2,a),func);
        pat = DAE.PAT_CONS(pat1,pat2);
        outTpl = func((pat,a));
      then outTpl;
    case ((pat as DAE.PAT_CONSTANT(ty=_),a),func)
      equation
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_SOME(pat1),a),func)
      equation
        ((pat1,a)) = traversePattern((pat1,a),func);
        pat = DAE.PAT_SOME(pat1);
        outTpl = func((pat,a));
      then outTpl;
    case ((pat as DAE.PAT_WILD(),a),func)
      equation
        outTpl = func((pat,a));
      then outTpl;
    case ((pat,_),_)
      equation
        str = "Patternm.traversePattern failed: " +& patternStr(pat);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end traversePattern;

protected function filterUnusedDecls
"Filters out unused local declarations"
  input list<DAE.Element> matchDecls;
  input HashTableStringToPath.HashTable ht;
  input list<DAE.Element> acc;
  input HashTableStringToPath.HashTable unusedHt;
  output list<DAE.Element> outDecls;
  output HashTableStringToPath.HashTable outUnusedHt;
algorithm
  (outDecls,outUnusedHt) := matchcontinue (matchDecls,ht,acc,unusedHt)
    local
      DAE.Element el;
      list<DAE.Element> rest;
      Absyn.Info info;
      String name;
    case ({},ht,acc,unusedHt) then (listReverse(acc),unusedHt);
    case (DAE.VAR(componentRef=DAE.CREF_IDENT(ident=name), source=DAE.SOURCE(info=info))::rest,ht,acc,unusedHt)
      equation
        failure(_ = BaseHashTable.get(name, ht));
        unusedHt = BaseHashTable.add((name,Absyn.IDENT("")),unusedHt);
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"),Error.META_UNUSED_DECL, {name}, info);
        (acc,unusedHt) = filterUnusedDecls(rest,ht,acc,unusedHt);
      then (acc,unusedHt);
    case (el::rest,ht,acc,unusedHt)
      equation
        (acc,unusedHt) = filterUnusedDecls(rest,ht,el::acc,unusedHt);
      then (acc,unusedHt);
  end matchcontinue;
end filterUnusedDecls;

protected function caseDeadCodeEliminiation
  "matchcontinue: Removes empty, failing cases
  match: Removes empty cases that can't be matched by subsequent cases
  match: Removes cases that can't be reached because a previous case has a dominating pattern
  "
  input Absyn.MatchType matchType;
  input list<DAE.MatchCase> cases;
  input list<list<DAE.Pattern>> prevPatterns;
  input list<DAE.MatchCase> acc;
  input Boolean iter "If we remove some code, it may cascade. We should we loop more.";
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := matchcontinue (matchType,cases,prevPatterns,acc,iter)
    local
      list<DAE.MatchCase> rest;
      list<DAE.Pattern> pats;
      DAE.MatchCase case_;
      Absyn.Info info;
    case (_,{},_,acc,false) then listReverse(acc);
    case (_,{},_,acc,true) then caseDeadCodeEliminiation(matchType,listReverse(acc),{},{},false);
    case (_,DAE.CASE(body={},result=NONE(),info=info)::{},prevPatterns,acc,iter)
      equation
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"), Error.META_DEAD_CODE, {"Last pattern is empty"}, info);
      then caseDeadCodeEliminiation(matchType,listReverse(acc),{},{},false);
        /* Tricky to get right; I'll try again later as it probably only gives marginal results anyway
    case (Absyn.MATCH(),DAE.CASE(patterns=pats,info=info)::rest,prevPatterns as _::_,acc,iter)
      equation
        oinfo = findOverlappingPattern(pats,acc);
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"), Error.META_DEAD_CODE, {"Unreachable pattern"}, info);
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"), Error.META_DEAD_CODE, {"Shadowing case"}, oinfo);
      then caseDeadCodeEliminiation(matchType,rest,pats::prevPatterns,acc,true);
      */
    case (Absyn.MATCHCONTINUE(),DAE.CASE(patterns=pats,body={},result=NONE(),info=info)::rest,prevPatterns,acc,_)
      equation
        false = RTOpts.debugFlag("patternmSkipMCDCE");
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"), Error.META_DEAD_CODE, {"Empty matchcontinue case"}, info);
        acc = caseDeadCodeEliminiation(matchType,rest,pats::prevPatterns,acc,true);
      then acc;
    case (_,(case_ as DAE.CASE(patterns=pats))::rest,prevPatterns,acc,iter) then caseDeadCodeEliminiation(matchType,rest,pats::prevPatterns,case_::acc,iter);
  end matchcontinue;
end caseDeadCodeEliminiation;

/*
protected function findOverlappingPattern
  input list<DAE.Pattern> patterns;
  input list<DAE.MatchCase> prevCases;
  output Absyn.Info info;
algorithm
  info := matchcontinue (patterns,prevCases)
    local
      list<DAE.Pattern> ps1,ps2;
    case (ps1,DAE.CASE(patterns=ps2,info=info)::_)
      equation
        true = patternListsDoOverlap(ps1,ps2); ???
      then info;
    case (ps1,_::prevCases) then findOverlappingPattern(ps1,prevCases); 
  end matchcontinue;
end findOverlappingPattern;
*/

protected function optimizeContinueJumps
  "If a case in a matchcontinue expression is followed by a (list of) cases that
  do not have overlapping patterns with the first one, an optimization can be made.
  If we match against the first pattern, we can jump a few positions in the loop!

  For example:
    matchcontinue i,j
      case (1,_) then (); // (1) => skip (2),(3) if this pattern matches
      case (2,_) then (); // (2) => skip (3),(4) if this pattern matches
      case (3,_) then (); // (3) => skip (4),(5) if this pattern matches
      case (1,_) then (); // (4) => skip (5),(6) if this pattern matches
      case (2,_) then (); // (5) => skip (6) if this pattern matches
      case (3,_) then (); // (6)
      case (_,2) then (); // (7) => skip (8),(9) if this pattern matches
      case (1,1) then (); // (8) => skip (9) if this pattern matches
      case (2,1) then (); // (9) => skip (10) if this pattern matches 
      case (1,_) then (); // (10)
    end matchcontinue;
  "
  input Absyn.MatchType matchType;
  input list<DAE.MatchCase> cases;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := match (matchType,cases)
    case (Absyn.MATCH(),cases) then cases;
    else optimizeContinueJumps2(cases);
  end match;
end optimizeContinueJumps;

protected function optimizeContinueJumps2
  input list<DAE.MatchCase> cases;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := match cases
    local
      DAE.MatchCase case_;
    case {} then {};
    case case_::cases
      equation
        case_ = optimizeContinueJump(case_,cases,0);
        cases = optimizeContinueJumps2(cases);
      then case_::cases;
  end match;
end optimizeContinueJumps2;

protected function optimizeContinueJump
  input DAE.MatchCase case_;
  input list<DAE.MatchCase> cases;
  input Integer jump;
  output DAE.MatchCase outCase;
algorithm
  outCase := matchcontinue (case_,cases,jump)
    local
      DAE.MatchCase case1;
      list<DAE.Pattern> ps1,ps2;
    case (case1,{},jump) then updateMatchCaseJump(case1,jump);
    case (case1 as DAE.CASE(patterns=ps1),DAE.CASE(patterns=ps2)::cases,jump)
      equation
        true = patternListsDoNotOverlap(ps1,ps2);
      then optimizeContinueJump(case1,cases,jump+1);
    case (case1,_,jump) then updateMatchCaseJump(case1,jump);
  end matchcontinue;
end optimizeContinueJump;

protected function updateMatchCaseJump
  "Updates the jump field of a DAE.MatchCase"
  input DAE.MatchCase case_;
  input Integer jump;
  output DAE.MatchCase outCase;
algorithm
  outCase := match (case_,jump)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> localDecls;
      list<DAE.Statement> body;
      Option<DAE.Exp> result;
      Absyn.Info info;
    case (case_,0) then case_;
    case (DAE.CASE(patterns, localDecls, body, result, _, info), jump)
      then DAE.CASE(patterns, localDecls, body, result, jump, info);
  end match;
end updateMatchCaseJump;

protected function optimizeContinueToMatch
  "If a matchcontinue expression has only one case, it is optimized to match instead.
  The same goes if for every case there is no overlapping pattern with a previous case.
  For example, the following example can be safely translated into a match-expression:
    matchcontinue i
      case 1 then ();
      case 2 then ();
      case 3 then ();
    end matchcontinue;
  "
  input Absyn.MatchType matchType;
  input list<DAE.MatchCase> cases;
  input Absyn.Info info;
  output Absyn.MatchType outMatchType;
algorithm
  outMatchType := match (matchType,cases,info)
    case (Absyn.MATCH(),_,_) then Absyn.MATCH();
    else optimizeContinueToMatch2(cases,{},info);
  end match;
end optimizeContinueToMatch;

protected function optimizeContinueToMatch2
  "If a matchcontinue expression has only one case, it is optimized to match instead.
  The same goes if for every case there is no overlapping pattern with a previous case.
  For example, the following example can be safely translated into a match-expression:
    matchcontinue i
      case 1 then ();
      case 2 then ();
      case 3 then ();
    end matchcontinue;
  "
  input list<DAE.MatchCase> cases;
  input list<list<DAE.Pattern>> prevPatterns "All cases check its patterns against all previous patterns. If they overlap, we can't optimize away the continue";
  input Absyn.Info info;
  output Absyn.MatchType outMatchType;
algorithm
  outMatchType := matchcontinue (cases,prevPatterns,info)
    local
      list<DAE.Pattern> patterns;
    case ({},_,info)
      equation
        Error.assertionOrAddSourceMessage(not RTOpts.debugFlag("patternmAllInfo"), Error.MATCHCONTINUE_TO_MATCH_OPTIMIZATION, {}, info);
      then Absyn.MATCH();
    case (DAE.CASE(patterns=patterns)::cases,prevPatterns,info)
      equation
        assertAllPatternListsDoNotOverlap(prevPatterns,patterns);
      then optimizeContinueToMatch2(cases,patterns::prevPatterns,info);
    else Absyn.MATCHCONTINUE();
  end matchcontinue;
end optimizeContinueToMatch2;

protected function assertAllPatternListsDoNotOverlap
  "If a matchcontinue expression has only one case, it is optimized to match instead.
  The same goes if for every case there is no overlapping pattern with a previous case.
  For example, the following example can be safely translated into a match-expression:
    matchcontinue i
      case 1 then ();
      case 2 then ();
      case 3 then ();
    end matchcontinue;
  "
  input list<list<DAE.Pattern>> pss1;
  input list<DAE.Pattern> ps2;
algorithm
  _ := match (pss1,ps2)
    local
      list<DAE.Pattern> ps1;
    case ({},_) then ();
    case (ps1::pss1,ps2)
      equation
        true = patternListsDoNotOverlap(ps1,ps2);
        assertAllPatternListsDoNotOverlap(pss1,ps2);
      then ();
  end match;
end assertAllPatternListsDoNotOverlap;

protected function patternListsDoNotOverlap
  "Verifies that pats1 does not shadow pats2"
  input list<DAE.Pattern> ps1;
  input list<DAE.Pattern> ps2;
  output Boolean b;
algorithm
  b := match (ps1,ps2)
    local
      Boolean res;
      DAE.Pattern p1,p2;
    case ({},{}) then false;
    case (p1::ps1,p2::ps2)
      equation
        res = patternsDoNotOverlap(p1,p2);
        res = Debug.bcallret2(not res,patternListsDoNotOverlap,ps1,ps2,res);
      then res;
  end match;
end patternListsDoNotOverlap;

protected function patternsDoNotOverlap
  "Verifies that p1 do not shadow p2"
  input DAE.Pattern p1;
  input DAE.Pattern p2;
  output Boolean b;
algorithm
  b := match (p1,p2)
    local
      DAE.Pattern head1,tail1,head2,tail2;
      list<DAE.Pattern> ps1,ps2;
      Boolean res;
      Absyn.Path name1,name2;
      Integer ix1,ix2;
      DAE.Exp e1,e2;
    case (DAE.PAT_WILD(),_) then false;
    case (_,DAE.PAT_WILD()) then false;
    case (DAE.PAT_AS_FUNC_PTR(id=_),_) then false;
    case (DAE.PAT_AS(pat=p1),p2)
      then patternsDoNotOverlap(p1,p2);
    case (p1,DAE.PAT_AS(pat=p2))
      then patternsDoNotOverlap(p1,p2);
    
    case (DAE.PAT_CONS(head1, tail1),DAE.PAT_CONS(head2, tail2))
      then patternsDoNotOverlap(head1,head2) or patternsDoNotOverlap(tail1,tail2);
    case (DAE.PAT_SOME(p1),DAE.PAT_SOME(p2))
      then patternsDoNotOverlap(p1,p2);
    case (DAE.PAT_META_TUPLE(ps1),DAE.PAT_META_TUPLE(ps2))
      then patternListsDoNotOverlap(ps1,ps2);
    case (DAE.PAT_CALL_TUPLE(ps1),DAE.PAT_CALL_TUPLE(ps2))
      then patternListsDoNotOverlap(ps1,ps2);
    
    case (DAE.PAT_CALL(name1,ix1,{}),DAE.PAT_CALL(name2,ix2,{}))
      equation
        res = ix1 == ix2;
        res = Debug.bcallret2(res, Absyn.pathEqual, name1, name2, res);
      then not res;

    case (DAE.PAT_CALL(name1,ix1,ps1),DAE.PAT_CALL(name2,ix2,ps2))
      equation
        res = ix1 == ix2;
        res = Debug.bcallret2(res, Absyn.pathEqual, name1, name2, res);
        res = Debug.bcallret2(res, patternListsDoNotOverlap, ps1, ps2, not res);
      then res;

    // TODO: PAT_CALLED_NAMED?

    // Constant patterns...
    case (DAE.PAT_CONSTANT(exp=e1),DAE.PAT_CONSTANT(exp=e2))
      then not Expression.expEqual(e1, e2);
    case (DAE.PAT_CONSTANT(exp=_),_) then true;
    case (_,DAE.PAT_CONSTANT(exp=_)) then true;
    
    else false;
  end match;
end patternsDoNotOverlap;

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
  (outCache,elabCases,resExps,resTypes,outSt) := elabMatchCases2(cache,env,cases,tys,impl,st,performVectorization,pre,{},{});
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
  input list<DAE.Exp> accExps "Order does matter";
  input list<DAE.Type> accTypes "Order does not matter";
  output Env.Cache outCache;
  output list<DAE.MatchCase> elabCases;
  output list<DAE.Exp> resExps;
  output list<DAE.Type> resTypes;
  output Option<Interactive.InteractiveSymbolTable> outSt;
algorithm
  (outCache,elabCases,resExps,resTypes,outSt) := match (cache,env,cases,tys,impl,st,performVectorization,pre,accExps,accTypes)
    local
      Absyn.Case case_;
      list<Absyn.Case> rest;
      DAE.MatchCase elabCase;
      list<DAE.MatchCase> elabCases;
      Option<DAE.Type> optType;
      Option<DAE.Exp> optExp;
    case (cache,env,{},tys,impl,st,performVectorization,pre,accExps,accTypes) then (cache,{},listReverse(accExps),listReverse(accTypes),st);
    case (cache,env,case_::rest,tys,impl,st,performVectorization,pre,accExps,accTypes)
      equation
        (cache,elabCase,optExp,optType,st) = elabMatchCase(cache,env,case_,tys,impl,st,performVectorization,pre);
        (cache,elabCases,accExps,accTypes,st) = elabMatchCases2(cache,env,rest,tys,impl,st,performVectorization,pre,Util.listConsOption(optExp,accExps),Util.listConsOption(optType,accTypes));
      then (cache,elabCase::elabCases,accExps,accTypes,st);
  end match;
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
  output Env.Cache outCache;
  output DAE.MatchCase elabCase;
  output Option<DAE.Exp> resExp;
  output Option<DAE.Type> resType;
  output Option<Interactive.InteractiveSymbolTable> outSt;
algorithm
  (outCache,elabCase,resExp,resType,outSt) := match (cache,env,acase,tys,impl,st,performVectorization,pre)
    local
      Absyn.Exp result,pattern;
      list<Absyn.Exp> patterns;
      list<DAE.Pattern> elabPatterns;
      Option<DAE.Exp> elabResult;
      list<DAE.Element> caseDecls;
      list<Absyn.EquationItem> eq1;
      list<Absyn.AlgorithmItem> eqAlgs;
      list<SCode.Statement> algs;
      list<DAE.Statement> body;
      list<Absyn.ElementItem> decls;
      Absyn.Info patternInfo,info;
      Integer len;
    case (cache,env,Absyn.CASE(pattern=pattern,patternInfo=patternInfo,localDecls=decls,equations=eq1,result=result,info=info),tys,impl,st,performVectorization,pre)
      equation
        (cache,SOME((env,DAE.DAE(caseDecls)))) = addLocalDecls(cache,env,decls,Env.caseScopeName,impl,info);
        patterns = MetaUtil.extractListFromTuple(pattern, 0);
        patterns = Util.if_(listLength(tys)==1, {pattern}, patterns);
        (cache,elabPatterns) = elabPatternTuple(cache, env, patterns, tys, patternInfo, pattern);
        (cache,eqAlgs) = Static.fromEquationsToAlgAssignments(eq1,{},cache,env,pre);
        algs = SCodeUtil.translateClassdefAlgorithmitems(eqAlgs);
        (cache,body) = InstSection.instStatements(cache, env, InnerOuter.emptyInstHierarchy, pre, algs, DAEUtil.addElementSourceFileInfo(DAE.emptyElementSource,patternInfo), SCode.NON_INITIAL(), true, Inst.neverUnroll);
        (cache,body,elabResult,resType,st) = elabResultExp(cache,env,body,result,impl,st,performVectorization,pre,patternInfo);
      then (cache,DAE.CASE(elabPatterns, caseDecls, body, elabResult, 0, info),elabResult,resType,st);

      // ELSE is the same as CASE, but without pattern
    case (cache,env,Absyn.ELSE(localDecls=decls,equations=eq1,result=result,info=info),tys,impl,st,performVectorization,pre)
      equation
        // Needs to be same length as any other pattern for the simplification algorithms, etc to work properly
        len = listLength(tys);
        patterns = Util.listFill(Absyn.CREF(Absyn.WILD()),listLength(tys));
        pattern = Util.if_(len == 1, Absyn.CREF(Absyn.WILD()), Absyn.TUPLE(patterns));
        (cache,elabCase,elabResult,resType,st) = elabMatchCase(cache,env,Absyn.CASE(pattern,info,decls,eq1,result,NONE(),info),tys,impl,st,performVectorization,pre); 
      then (cache,elabCase,elabResult,resType,st);
        
  end match;
end elabMatchCase;

protected function elabResultExp
  input Env.Cache cache;
  input Env.Env env;
  input list<DAE.Statement> body "Is input in case we want to optimize for tail-recursion";
  input Absyn.Exp exp;
  input Boolean impl;
  input Option<Interactive.InteractiveSymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.Statement> outBody;
  output Option<DAE.Exp> resExp;
  output Option<DAE.Type> resType;
  output Option<Interactive.InteractiveSymbolTable> outSt;
algorithm
  (outCache,outBody,resExp,resType,outSt) := matchcontinue (cache,env,body,exp,impl,st,performVectorization,pre,info)
    local
      DAE.Exp elabExp;
      DAE.Properties prop;
      DAE.Type ty;
    case (cache,env,body,Absyn.CALL(function_ = Absyn.CREF_IDENT("fail",{}), functionArgs = Absyn.FUNCTIONARGS({},{})),impl,st,performVectorization,pre,info)
      then (cache,body,NONE(),NONE(),st);

    case (cache,env,body,exp,impl,st,performVectorization,pre,info)
      equation
        (cache,elabExp,prop,st) = Static.elabExp(cache,env,exp,impl,st,performVectorization,pre,info);
        (body,elabExp) = elabResultExp2(RTOpts.debugFlag("patternmSkipMoveLastExp"),body,elabExp); 
        ty = Types.getPropType(prop);
      then (cache,body,SOME(elabExp),SOME(ty),st);
  end matchcontinue;
end elabResultExp;

protected function elabResultExp2
  "(cr1,...,crn) = exp; then (cr1,...,crn); => then exp;
    cr = exp; then cr; => then exp;
    
    Is recursive, and will remove all such assignments, i.e.:
     doStuff(); a = 1; b = a; c = b; then c;
   Becomes:
     doStuff(); then c;
  
  This phase needs to be performed if we want to be able to discover places to
  optimize for tail recursion.
  "
  input Boolean skipPhase;
  input list<DAE.Statement> body;
  input DAE.Exp elabExp;
  output list<DAE.Statement> outBody;
  output DAE.Exp outExp;
algorithm
  (outBody,outExp) := matchcontinue (skipPhase,body,elabExp)
    local
      DAE.Exp elabCr1,elabCr2;
      list<DAE.Exp> elabCrs1,elabCrs2;
    case (true,body,elabExp) then (body,elabExp);
    case (_,body,elabCr2 as DAE.CREF(ty=_))
      equation
        (DAE.STMT_ASSIGN(exp1=elabCr1,exp=elabExp),body) = Util.listSplitLast(body);
        true = Expression.expEqual(elabCr1,elabCr2);
        (body,elabExp) = elabResultExp2(false,body,elabExp);
      then (body,elabExp);
    case (_,body,DAE.TUPLE(elabCrs2))
      equation
        (DAE.STMT_TUPLE_ASSIGN(expExpLst=elabCrs1,exp=elabExp),body) = Util.listSplitLast(body);
        Util.listThreadMapAllValue(elabCrs1, elabCrs2, Expression.expEqual, true);
        (body,elabExp) = elabResultExp2(false,body,elabExp);
      then (body,elabExp);
    else (body,elabExp);
  end matchcontinue;
end elabResultExp2;

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
      Integer jump;
      Absyn.Info info2;
    case ({},{},_) then {};
    
    case (DAE.CASE(patterns,decls,body,SOME(_),jump,info2)::cases,exp::exps,info)
      equation
        cases = fixCaseReturnTypes2(cases,exps,info);
      then DAE.CASE(patterns,decls,body,SOME(exp),jump,info2)::cases;
    
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
      Integer jump;
      Absyn.Info info;
    case ({},_,a) then ({},a);
    case (DAE.CASE(patterns,decls,body,result,jump,info)::cases,_,a)
      equation
        (body,(_,a)) = DAEUtil.traverseDAEEquationsStmts(body,Expression.traverseSubexpressionsHelper,(func,a));
        ((result,a)) = Expression.traverseExpOpt(result,func,a);
        (cases,a) = traverseCases(cases,func,a); 
      then (DAE.CASE(patterns,decls,body,result,jump,info)::cases,a);
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
      DAE.DAElist dae1;
      Env.Env env2;
      ClassInf.State dummyFunc;
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

protected function allPatternsWild
  "Returns true if all patterns in the list are wildcards"
  input list<DAE.Pattern> pats;
  output Boolean b;
algorithm
  b := match pats
    case {} then true;
    case DAE.PAT_WILD()::pats then allPatternsWild(pats);
    else false;
  end match;
end allPatternsWild;

protected function getCasePatterns
"Accessor function for DAE.Case"
  input DAE.MatchCase case_;
  output list<DAE.Pattern> pats;
algorithm
  DAE.CASE(patterns=pats) := case_;
end getCasePatterns;
  
protected function setCasePatterns
"Sets the patterns field in a DAE.Case"
  input DAE.MatchCase case1;
  input list<DAE.Pattern> pats;
  output DAE.MatchCase case2;
algorithm
  case2 := match (case1,pats)
    local
      list<DAE.Element> localDecls;
      list<DAE.Statement> body;
      Option<DAE.Exp> result;
      Integer jump;
      Absyn.Info info;
    case (DAE.CASE(_,localDecls,body,result,jump,info),pats)
      then DAE.CASE(pats,localDecls,body,result,jump,info);
  end match;
end setCasePatterns;

public function getValueCtor
  "Get the constructor index of a uniontype record based on its index in the uniontype"
  input Integer ix;
  output Integer ctor;
algorithm
  ctor := ix+3;
end getValueCtor;
  
end Patternm;
