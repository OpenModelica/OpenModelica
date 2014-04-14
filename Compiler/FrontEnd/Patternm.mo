/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package Patternm
" file:        Patternm.mo
  package:     Patternm
  description: Patternmatching

  RCS: $Id$

  This module contains the patternmatch algorithm for the MetaModelica
  matchcontinue expression."

public import Absyn;
public import AvlTreeString;
public import ClassInf;
public import ConnectionGraph;
public import DAE;
public import Env;
public import HashTableStringToPath;
public import SCode;
public import Dump;
public import InnerOuter;
public import GlobalScript;
public import Prefix;
public import Types;
public import UnitAbsyn;

protected import Algorithm;
protected import BaseHashTable;
protected import ComponentReference;
protected import Connect;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import Error;
protected import Flags;
protected import Inst;
protected import InstSection;
protected import InstTypes;
protected import InstUtil;
protected import List;
protected import Lookup;
protected import MetaUtil;
protected import SCodeUtil;
protected import Static;
protected import System;
protected import Util;
protected import SCodeDump;

protected function generatePositionalArgs "author: KS
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
    case ({},_,localAccList) then (listReverse(localAccList),namedArgList);
    case (firstFieldName :: restFieldNames,localNamedArgList,localAccList)
      equation
        (exp,localNamedArgList) = findFieldExpInList(firstFieldName,localNamedArgList);
        (localAccList,localNamedArgList) = generatePositionalArgs(restFieldNames,localNamedArgList,exp::localAccList);
      then (localAccList,localNamedArgList);
  end match;
end generatePositionalArgs;

protected function findFieldExpInList "author: KS
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
  input list<String> fieldNameList;
  input Util.Status status;
  input Absyn.Info info;
  output Util.Status outStatus;
algorithm
  outStatus := match (args,fieldNameList,status,info)
    local
      list<String> argsNames;
      String str1,str2;
    case ({},_,_,_) then status;
    case (_,_,_,_)
      equation
        (argsNames,_) = Absyn.getNamedFuncArgNamesAndValues(args);
        str1 = stringDelimitList(argsNames, ",");
        str2 = stringDelimitList(fieldNameList, ",");
        Error.addSourceMessage(Error.META_INVALID_PATTERN_NAMED_FIELD, {str1,str2}, info);
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
  (outCache,pattern) := elabPattern2(cache,env,lhs,ty,info,Error.getNumErrorMessages());
end elabPattern;

protected function elabPattern2
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Exp inLhs;
  input DAE.Type ty;
  input Absyn.Info info;
  input Integer numError;
  output Env.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := matchcontinue (inCache,env,inLhs,ty,info,numError)
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
      Option<DAE.Type> et;
      DAE.Pattern patternHead,patternTail;
      Absyn.ComponentRef fcr;
      Absyn.FunctionArgs fargs;
      Absyn.Path utPath;
      Env.Cache cache;
      Absyn.Exp lhs;
      DAE.Attributes attr;

    case (cache,_,Absyn.INTEGER(i),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_INTEGER_DEFAULT,inLhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,_,Absyn.REAL(r),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_REAL_DEFAULT,inLhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.RCONST(r)));

    case (cache,_,Absyn.UNARY(Absyn.UMINUS(),Absyn.INTEGER(i)),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_INTEGER_DEFAULT,inLhs,info);
        i = -i;
      then (cache,DAE.PAT_CONSTANT(et,DAE.ICONST(i)));

    case (cache,_,Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(r)),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_REAL_DEFAULT,inLhs,info);
        r = realNeg(r);
      then (cache,DAE.PAT_CONSTANT(et,DAE.RCONST(r)));

    case (cache,_,Absyn.STRING(s),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_STRING_DEFAULT,inLhs,info);
        s = System.unescapedString(s);
      then (cache,DAE.PAT_CONSTANT(et,DAE.SCONST(s)));

    case (cache,_,Absyn.BOOL(b),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_BOOL_DEFAULT,inLhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.BCONST(b)));

    case (cache,_,Absyn.ARRAY({}),_,_,_)
      equation
        et = validPatternType(ty,DAE.T_METALIST_DEFAULT,inLhs,info);
      then (cache,DAE.PAT_CONSTANT(et,DAE.LIST({})));

    case (cache,_,Absyn.ARRAY(exps as _::_),_,_,_)
      equation
        lhs = List.fold(listReverse(exps), Absyn.makeCons, Absyn.ARRAY({}));
        (cache,pattern) = elabPattern(cache,env,lhs,ty,info);
      then (cache,pattern);

    case (cache,_,Absyn.CALL(Absyn.CREF_IDENT("NONE",{}),Absyn.FUNCTIONARGS({},{})),_,_,_)
      equation
        _ = validPatternType(ty,DAE.T_NONE_DEFAULT,inLhs,info);
      then (cache,DAE.PAT_CONSTANT(NONE(),DAE.META_OPTION(NONE())));

    case (cache,_,Absyn.CALL(Absyn.CREF_IDENT("SOME",{}),Absyn.FUNCTIONARGS({exp},{})),DAE.T_METAOPTION(optionType = ty2),_,_)
      equation
        (cache,pattern) = elabPattern(cache,env,exp,ty2,info);
      then (cache,DAE.PAT_SOME(pattern));

    case (cache,_,Absyn.CONS(head,tail),tyTail as DAE.T_METALIST(listType = tyHead),_,_)
      equation
        tyHead = Types.boxIfUnboxedType(tyHead);
        (cache,patternHead) = elabPattern(cache,env,head,tyHead,info);
        (cache,patternTail) = elabPattern(cache,env,tail,tyTail,info);
      then (cache,DAE.PAT_CONS(patternHead,patternTail));

    case (cache,_,Absyn.TUPLE(exps),DAE.T_METATUPLE(types = tys),_,_)
      equation
        tys = List.map(tys, Types.boxIfUnboxedType);
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,inLhs);
      then (cache,DAE.PAT_META_TUPLE(patterns));

    case (cache,_,Absyn.TUPLE(exps),DAE.T_TUPLE(tupleType = tys),_,_)
      equation
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,inLhs);
      then (cache,DAE.PAT_CALL_TUPLE(patterns));

    case (cache,_,lhs as Absyn.CALL(fcr,fargs),DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), source = {utPath}),_,_)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,_,lhs as Absyn.CALL(fcr,fargs),DAE.T_METAUNIONTYPE(source = {utPath}),_,_)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,_,lhs as Absyn.CALL(fcr,fargs),DAE.T_METARECORD(utPath = utPath),_,_)
      equation
        (cache,pattern) = elabPatternCall(cache,env,Absyn.crefToPath(fcr),fargs,utPath,info,lhs);
      then (cache,pattern);

    case (cache,_,Absyn.AS(id,exp),ty2,_,_)
      equation
        (cache,DAE.TYPES_VAR(ty = ty1, attributes = attr),_,_,_,_) = Lookup.lookupIdent(cache,env,id);
        lhs = Absyn.CREF(Absyn.CREF_IDENT(id, {}));
        Static.checkAssignmentToInput(lhs, attr, env, false, info);
        et = validPatternType(ty2,ty1,inLhs,info);
        (cache,pattern) = elabPattern(cache,env,exp,ty2,info);
        pattern = Util.if_(Types.isFunctionType(ty2), DAE.PAT_AS_FUNC_PTR(id,pattern), DAE.PAT_AS(id,et,attr,pattern));
      then (cache,pattern);

    case (cache,_,Absyn.CREF(Absyn.CREF_IDENT(id,{})),ty2,_,_)
      equation
        (cache,DAE.TYPES_VAR(ty = ty1, attributes = attr),_,_,_,_) = Lookup.lookupIdent(cache,env,id);
        Static.checkAssignmentToInput(inLhs, attr, env, false, info);
        et = validPatternType(ty2,ty1,inLhs,info);
        pattern = Util.if_(Types.isFunctionType(ty2), DAE.PAT_AS_FUNC_PTR(id,DAE.PAT_WILD()), DAE.PAT_AS(id,et,attr,DAE.PAT_WILD()));
      then (cache,pattern);

    case (cache,_,Absyn.AS(id,exp),ty2,_,_)
      equation
        failure((_,_,_,_,_,_) = Lookup.lookupIdent(cache,env,id));
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,{id,""},info);
      then fail();

    case (cache,_,Absyn.CREF(Absyn.CREF_IDENT(id,{})),ty2,_,_)
      equation
        failure((_,_,_,_,_,_) = Lookup.lookupIdent(cache,env,id));
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,{id,""},info);
      then fail();

    case (cache,_,Absyn.CREF(Absyn.WILD()),_,_,_) then (cache,DAE.PAT_WILD());

    case (cache,_,lhs,_,_,_)
      equation
        true = numError == Error.getNumErrorMessages();
        str = Dump.printExpStr(lhs) +& " of type " +& Types.unparseType(ty);
        Error.addSourceMessage(Error.META_INVALID_PATTERN, {str}, info);
      then fail();

  end matchcontinue;
end elabPattern2;

protected function elabPatternTuple
  input Env.Cache inCache;
  input Env.Env env;
  input list<Absyn.Exp> inExps;
  input list<DAE.Type> inTys;
  input Absyn.Info info;
  input Absyn.Exp lhs "for error messages";
  output Env.Cache outCache;
  output list<DAE.Pattern> patterns;
algorithm
  (outCache,patterns) := match (inCache,env,inExps,inTys,info,lhs)
    local
      Absyn.Exp exp;
      String s;
      DAE.Pattern pattern;
      DAE.Type ty;
      Env.Cache cache;
      list<Absyn.Exp> exps;
      list<DAE.Type> tys;

    case (cache,_,{},{},_,_) then (cache,{});

    case (cache,_,exp::exps,ty::tys,_,_)
      equation
        (cache,pattern) = elabPattern(cache,env,exp,ty,info);
        (cache,patterns) = elabPatternTuple(cache,env,exps,tys,info,lhs);
      then (cache,pattern::patterns);

    case (cache,_,_,_,_,_)
      equation
        s = Dump.printExpStr(lhs);
        s = "pattern " +& s;
        Error.addSourceMessage(Error.WRONG_NO_OF_ARGS, {s}, info);
      then fail();
  end match;
end elabPatternTuple;

protected function elabPatternCall
  input Env.Cache inCache;
  input Env.Env env;
  input Absyn.Path callPath;
  input Absyn.FunctionArgs fargs;
  input Absyn.Path utPath;
  input Absyn.Info info;
  input Absyn.Exp lhs "for error messages";
  output Env.Cache outCache;
  output DAE.Pattern pattern;
algorithm
  (outCache,pattern) := matchcontinue (inCache,env,callPath,fargs,utPath,info,lhs)
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
      list<tuple<DAE.Pattern,String,DAE.Type>> namedPatterns;
      Boolean knownSingleton;
      Env.Cache cache;

    case (cache,_,_,Absyn.FUNCTIONARGS(funcArgs,namedArgList),utPath2,_,_)
      equation
        (cache,t as DAE.T_METARECORD(utPath=utPath1,index=index,fields=fieldVarList,knownSingleton = knownSingleton,source = {fqPath}),_) =
          Lookup.lookupType(cache, env, callPath, NONE());
        validUniontype(utPath1,utPath2,info,lhs);

        fieldTypeList = List.map(fieldVarList, Types.getVarType);
        fieldNameList = List.map(fieldVarList, Types.getVarName);

        (funcArgs,namedArgList) = checkForAllWildCall(funcArgs,namedArgList,listLength(fieldNameList));

        numPosArgs = listLength(funcArgs);
        (_,fieldNamesNamed) = List.split(fieldNameList, numPosArgs);
        checkMissingArgs(fqPath,numPosArgs,fieldNamesNamed,listLength(namedArgList),info);
        (funcArgsNamedFixed,invalidArgs) = generatePositionalArgs(fieldNamesNamed,namedArgList,{});
        funcArgs = listAppend(funcArgs,funcArgsNamedFixed);
        Util.SUCCESS() = checkInvalidPatternNamedArgs(invalidArgs,fieldNameList,Util.SUCCESS(),info);
        (cache,patterns) = elabPatternTuple(cache,env,funcArgs,fieldTypeList,info,lhs);
      then (cache,DAE.PAT_CALL(fqPath,index,patterns,fieldVarList,knownSingleton));

    case (cache,_,_,Absyn.FUNCTIONARGS(funcArgs,namedArgList),utPath2,_,_)
      equation
        (cache,t as DAE.T_FUNCTION(funcResultType = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_),varLst=fieldVarList), source = {fqPath}),_) =
          Lookup.lookupType(cache, env, callPath, NONE());
        true = Absyn.pathEqual(fqPath,utPath2);

        fieldTypeList = List.map(fieldVarList, Types.getVarType);
        fieldNameList = List.map(fieldVarList, Types.getVarName);

        (funcArgs,namedArgList) = checkForAllWildCall(funcArgs,namedArgList,listLength(fieldNameList));

        numPosArgs = listLength(funcArgs);
        (_,fieldNamesNamed) = List.split(fieldNameList, numPosArgs);
        checkMissingArgs(fqPath,numPosArgs,fieldNamesNamed,listLength(namedArgList),info);

        (funcArgsNamedFixed,invalidArgs) = generatePositionalArgs(fieldNamesNamed,namedArgList,{});
        funcArgs = listAppend(funcArgs,funcArgsNamedFixed);
        Util.SUCCESS() = checkInvalidPatternNamedArgs(invalidArgs,fieldNameList,Util.SUCCESS(),info);
        (cache,patterns) = elabPatternTuple(cache,env,funcArgs,fieldTypeList,info,lhs);
        namedPatterns = List.thread3Tuple(patterns, fieldNameList, List.map(fieldTypeList,Types.simplifyType));
        namedPatterns = List.filter(namedPatterns, filterEmptyPattern);
      then (cache,DAE.PAT_CALL_NAMED(fqPath,namedPatterns));

    case (cache,_,_,_,_,_,_)
      equation
        failure((_,_,_) = Lookup.lookupType(cache, env, callPath, NONE()));
        s = Absyn.pathString(callPath);
        Error.addSourceMessage(Error.META_CONSTRUCTOR_NOT_RECORD, {s}, info);
      then fail();
  end matchcontinue;
end elabPatternCall;

protected function checkMissingArgs
  input Absyn.Path path;
  input Integer numPosArgs;
  input list<String> missingFieldNames;
  input Integer numNamedArgs;
  input Absyn.Info info;
algorithm
  _ := match (path,numPosArgs,missingFieldNames,numNamedArgs,info)
    local
      String str;
      list<String> strs;
    case (_,_,{},0,_) then ();
/* Language extension to not have to bind everything...
    case (_,_,strs,0,_)
      equation
        str = stringDelimitList(strs,",");
        str = Absyn.pathString(path) +& " missing pattern for fields: " +& str;
        Error.addSourceMessage(Error.META_INVALID_PATTERN,{str},info);
      then fail();
*/
    /*
    case (path,_,_,_,info)
      equation
        str = Absyn.pathString(path) +& " mixing positional and named patterns";
        Error.addSourceMessage(Error.META_INVALID_PATTERN,{str},info);
      then fail();
    */
    else ();
  end match;
end checkMissingArgs;

protected function checkForAllWildCall "Converts a call REC(__) to REC(_,_,_,_)"
  input list<Absyn.Exp> args;
  input list<Absyn.NamedArg> named;
  input Integer numFields;
  output list<Absyn.Exp> outArgs;
  output list<Absyn.NamedArg> outNamed;
algorithm
  (outArgs,outNamed) := match (args,named,numFields)
    case ({Absyn.CREF(Absyn.ALLWILD())},{},_)
      then (List.fill(Absyn.CREF(Absyn.WILD()),numFields),{});
    else (args,named);
  end match;
end checkForAllWildCall;

protected function validPatternType
  input DAE.Type inTy1;
  input DAE.Type inTy2;
  input Absyn.Exp lhs;
  input Absyn.Info info;
  output Option<DAE.Type> ty;
algorithm
  ty := matchcontinue (inTy1,inTy2,lhs,info)
    local
      DAE.Type et;
      String s,s1,s2;
      DAE.ComponentRef cr;
      DAE.Exp crefExp;
      DAE.Type ty1, ty2;

    case (DAE.T_METABOXED(ty = ty1),ty2,_,_)
      equation
        cr = ComponentReference.makeCrefIdent("#DUMMY#",DAE.T_UNKNOWN_DEFAULT,{});
        crefExp = Expression.crefExp(cr);
        (_,ty1) = Types.matchType(crefExp,ty1,ty2,true);
        et = Types.simplifyType(ty1);
      then SOME(et);

    case (ty1,ty2,_,_)
      equation
        cr = ComponentReference.makeCrefIdent("#DUMMY#",DAE.T_UNKNOWN_DEFAULT,{});
        crefExp = Expression.crefExp(cr);
        (_,et) = Types.matchType(crefExp,ty1,ty2,true);
      then NONE();

    case (ty1,ty2,_,_)
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
    case (_,_,_,_)
      equation
        true = Absyn.pathEqual(path1,path2);
      then ();
    else
      equation
        s = Dump.printExpStr(lhs);
        s1 = Absyn.pathString(path1);
        s2 = Absyn.pathString(path2);
        Error.addSourceMessage(Error.META_CONSTRUCTOR_NOT_PART_OF_UNIONTYPE, {s,s1,s2}, info);
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
      list<tuple<DAE.Pattern,String,DAE.Type>> namedpats;
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
        str = stringDelimitList(List.map(pats,patternStr),",");
      then "(" +& str +& ")";

    case DAE.PAT_CALL_TUPLE(pats)
      equation
        str = stringDelimitList(List.map(pats,patternStr),",");
      then "(" +& str +& ")";

    case DAE.PAT_CALL(name=name, patterns=pats)
      equation
        id = Absyn.pathString(name);
        str = stringDelimitList(List.map(pats,patternStr),",");
      then stringAppendList({id,"(",str,")"});

    case DAE.PAT_CALL_NAMED(name=name, patterns=namedpats)
      equation
        id = Absyn.pathString(name);
        fields = List.map(namedpats, Util.tuple32);
        patsStr = List.map1r(List.mapMap(namedpats, Util.tuple31, patternStr), stringAppend, "=");
        str = stringDelimitList(List.threadMap(fields, patsStr, stringAppend), ",");
      then stringAppendList({id,"(",str,")"});

    case DAE.PAT_CONS(head,tail) then patternStr(head) +& "::" +& patternStr(tail);

    case DAE.PAT_CONSTANT(exp=exp) then ExpressionDump.printExpStr(exp);
    // case DAE.PAT_CONSTANT(SOME(et),exp) then "(" +& Types.unparseType(et) +& ")" +& ExpressionDump.printExpStr(exp);
    case DAE.PAT_AS(id=id,pat=pat) then id +& " as " +& patternStr(pat);
    case DAE.PAT_AS_FUNC_PTR(id, pat) then id +& " as " +& patternStr(pat);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Patternm.patternStr not implemented correctly"});
      then "*PATTERN*";
  end matchcontinue;
end patternStr;

public function elabMatchExpression
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp matchExp;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix inPrefix;
  input Absyn.Info info;
  input Integer numError;
  output Env.Cache outCache;
  output DAE.Exp outExp;
  output DAE.Properties outProperties;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,outExp,outProperties,outSt) := matchcontinue (inCache,inEnv,matchExp,impl,inSt,performVectorization,inPrefix,info,numError)
    local
      Absyn.MatchType matchTy;
      Absyn.Exp inExp;
      list<Absyn.Exp> inExps;
      list<Absyn.ElementItem> decls;
      list<Absyn.Case> cases;
      list<DAE.Element> matchDecls;
      Option<GlobalScript.SymbolTable> st;
      Prefix.Prefix pre;
      list<DAE.Exp> elabExps;
      list<DAE.MatchCase> elabCases;
      list<DAE.Type> tys;
      DAE.Properties prop;
      list<DAE.Properties> elabProps;
      DAE.Type resType;
      DAE.Type et;
      String str;
      DAE.Exp exp;
      HashTableStringToPath.HashTable ht;
      DAE.MatchType elabMatchTy;
      Env.Cache cache;
      Env.Env env;
      Integer hashSize;
      list<list<String>> inputAliases,inputAliasesAndCrefs;
      AvlTreeString.AvlTree declsTree;

    case (cache,env,Absyn.MATCHEXP(matchTy=matchTy,inputExp=inExp,localDecls=decls,cases=cases),_,st,_,pre,_,_)
      equation
        // First do inputs
        inExps = MetaUtil.extractListFromTuple(inExp, 0);
        (inExps,inputAliases,inputAliasesAndCrefs) = List.map_3(inExps,getInputAsBinding);
        (cache,elabExps,elabProps,st) = Static.elabExpList(cache,env,inExps,impl,st,performVectorization,pre,info);
        // Then add locals
        (cache,SOME((env,DAE.DAE(matchDecls),declsTree))) = addLocalDecls(cache,env,decls,Env.matchScopeName,impl,info);
        tys = List.map(elabProps, Types.getPropType);
        env = addAliasesToEnv(env, tys, inputAliases, info);
        (cache,elabCases,resType,st) = elabMatchCases(cache,env,cases,tys,inputAliasesAndCrefs,declsTree,impl,st,performVectorization,pre,info);
        prop = DAE.PROP(resType,DAE.C_VAR());
        et = Types.simplifyType(resType);
        (elabExps,inputAliases,elabCases) = filterUnusedPatterns(elabExps,inputAliases,elabCases) "filterUnusedPatterns() First time to speed up the other optimizations.";
        elabCases = caseDeadCodeEliminiation(matchTy, elabCases, {}, {}, false);
        // Do DCE before converting mc to m
        matchTy = optimizeContinueToMatch(matchTy,elabCases,info);
        elabCases = optimizeContinueJumps(matchTy, elabCases);
        // hashSize = Util.nextPowerOf2(listLength(matchDecls)) + 1; // faster, but unstable in RML
        hashSize = Util.nextPrime(listLength(matchDecls));
        ht = getUsedLocalCrefs(Flags.isSet(Flags.PATTERNM_SKIP_FILTER_UNUSED_AS_BINDINGS),DAE.MATCHEXPRESSION(DAE.MATCHCONTINUE(),elabExps,inputAliases,matchDecls,elabCases,et),hashSize);
        (matchDecls,ht) = filterUnusedDecls(matchDecls,ht,{},HashTableStringToPath.emptyHashTableSized(hashSize));
        (elabExps,inputAliases,elabCases) = filterUnusedPatterns(elabExps,inputAliases,elabCases) "filterUnusedPatterns() again to filter out the last parts.";
        elabMatchTy = optimizeMatchToSwitch(matchTy,elabCases,info);
        exp = DAE.MATCHEXPRESSION(elabMatchTy,elabExps,inputAliases,matchDecls,elabCases,et);
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
  match int case 1 ... case 17 ... case 2 => switch(int)...
  Works if all values are unique. Also works if there is one 'default' case at the end of the list (and there is only 1 pattern):
    case (1,_) ... case (_,_) ... works
    case (1,2) ... case (_,_) ... does not work
  .
  "
  input Absyn.MatchType matchTy;
  input list<DAE.MatchCase> cases;
  input Absyn.Info info;
  output DAE.MatchType outType;
algorithm
  outType := matchcontinue (matchTy,cases,info)
    local
      tuple<Integer,DAE.Type,Integer> tpl;
      list<list<DAE.Pattern>> patternMatrix;
      list<Option<list<DAE.Pattern>>> optPatternMatrix;
      Integer numNonEmptyColumns;
      String str;
      DAE.Type ty;
    case (Absyn.MATCHCONTINUE(),_,_) then DAE.MATCHCONTINUE();
    case (_,_,_)
      equation
        true = listLength(cases) > 2;
        patternMatrix = List.transposeList(List.map(cases,getCasePatterns));
        (optPatternMatrix,numNonEmptyColumns) = removeWildPatternColumnsFromMatrix(patternMatrix,{},0);
        tpl = findPatternToConvertToSwitch(optPatternMatrix,0,numNonEmptyColumns,info);
        (_,ty,_) = tpl;
        str = Types.unparseType(ty);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.MATCH_TO_SWITCH_OPTIMIZATION, {str}, info);
      then DAE.MATCH(SOME(tpl));
    else DAE.MATCH(NONE());
  end matchcontinue;
end optimizeMatchToSwitch;

protected function removeWildPatternColumnsFromMatrix
  input list<list<DAE.Pattern>> inPatternMatrix;
  input list<Option<list<DAE.Pattern>>> inAcc;
  input Integer inNumAcc;
  output list<Option<list<DAE.Pattern>>> optPatternMatrix;
  output Integer numNonEmptyColumns;
algorithm
  (optPatternMatrix,numNonEmptyColumns) := match (inPatternMatrix,inAcc,inNumAcc)
    local
      Boolean alwaysMatch;
      list<DAE.Pattern> pats;
      Option<list<DAE.Pattern>> optPats;
      list<list<DAE.Pattern>> patternMatrix;
      list<Option<list<DAE.Pattern>>> acc;
      Integer numAcc;

    case ({},acc,numAcc) then (listReverse(acc),numAcc);

    case (pats::patternMatrix,acc,numAcc)
      equation
        alwaysMatch = allPatternsAlwaysMatch(List.stripLast(pats));
        optPats = Util.if_(alwaysMatch,NONE(),SOME(pats));
        numAcc = Util.if_(alwaysMatch,numAcc,numAcc+1);
        (acc,numAcc) = removeWildPatternColumnsFromMatrix(patternMatrix,optPats::acc,numAcc);
      then (acc,numAcc);
  end match;
end removeWildPatternColumnsFromMatrix;

protected function findPatternToConvertToSwitch
  input list<Option<list<DAE.Pattern>>> inPatternMatrix;
  input Integer index;
  input Integer numPatternsInMatrix "If there is only 1 pattern, we can optimize the default case";
  input Absyn.Info info;
  output tuple<Integer,DAE.Type,Integer> tpl;
algorithm
  tpl := matchcontinue  (inPatternMatrix,index,numPatternsInMatrix,info)
    local
      list<DAE.Pattern> pats;
      DAE.Type ty;
      Integer extraarg;
      list<Option<list<DAE.Pattern>>> patternMatrix;

    case (SOME(pats)::patternMatrix,_,_,_)
      equation
        (ty,extraarg) = findPatternToConvertToSwitch2(pats, {}, DAE.T_UNKNOWN_DEFAULT, true, numPatternsInMatrix);
      then ((index,ty,extraarg));
    case (_::patternMatrix,_,_,_)
      then findPatternToConvertToSwitch(patternMatrix,index+1,numPatternsInMatrix,info);
  end matchcontinue;
end findPatternToConvertToSwitch;

protected function findPatternToConvertToSwitch2
  input list<DAE.Pattern> ipats;
  input list<Integer> ixs;
  input DAE.Type ity;
  input Boolean allSubPatternsMatch;
  input Integer numPatternsInMatrix;
  output DAE.Type outTy;
  output Integer extraarg;
algorithm
  (outTy,extraarg) := match (ipats,ixs,ity,allSubPatternsMatch,numPatternsInMatrix)
    local
      Integer ix;
      String str;
      list<DAE.Pattern> pats,subpats;
      DAE.Type ty;

    case (DAE.PAT_CONSTANT(exp=DAE.SCONST(str))::pats,_,_,_,_)
      equation
        ix = System.stringHashDjb2Mod(str,65536);
        false = listMember(ix,ixs);
        (ty,extraarg) = findPatternToConvertToSwitch2(pats,ix::ixs,DAE.T_STRING_DEFAULT,allSubPatternsMatch,numPatternsInMatrix);
      then (ty,extraarg);

    case (DAE.PAT_CALL(index=ix,patterns=subpats)::pats,_,_,_,_)
      equation
        false = listMember(ix,ixs);
        (ty,extraarg) = findPatternToConvertToSwitch2(pats,ix::ixs,DAE.T_METATYPE_DEFAULT,allSubPatternsMatch and allPatternsAlwaysMatch(subpats),numPatternsInMatrix);
      then (ty,extraarg);

    case (DAE.PAT_CONSTANT(exp=DAE.ICONST(ix))::pats,_,_,_,_)
      equation
        false = listMember(ix,ixs);
        (ty,extraarg) = findPatternToConvertToSwitch2(pats,ix::ixs,DAE.T_INTEGER_DEFAULT,allSubPatternsMatch,numPatternsInMatrix);
      then (ty,extraarg);

    case ({},_,DAE.T_STRING(varLst = _),_,_)
      equation
        true = listLength(ixs)>11; // hashing has a considerable overhead, only convert to switch if it is worth it
        ix = findMinMod(ixs,1);
      then (DAE.T_STRING_DEFAULT,ix);

    case ({_},_,DAE.T_STRING(varLst = _),_,1)
      equation
        true = listLength(ixs)>11; // hashing has a considerable overhead, only convert to switch if it is worth it
        ix = findMinMod(ixs,1);
      then (DAE.T_STRING_DEFAULT,ix);

    case ({},_,_,_,_) then (ity,0);

    // Sadly, we cannot switch a default uniontype as the previous case in not guaranteed
    // to succeed matching if it matches for subpatterns.
    case ({_},_,_,true,1) then (ity,0);
  end match;
end findPatternToConvertToSwitch2;

protected function findMinMod
  input list<Integer> inIxs;
  input Integer inMod;
  output Integer outMod;
algorithm
  outMod := matchcontinue (inIxs,inMod)
    local list<Integer> ixs; Integer mod;
    case (ixs,mod)
      equation
        ixs = List.map1(ixs, intMod, mod);
        ixs = List.sort(ixs, intLt);
        (_,{}) = Util.splitUniqueOnBool(ixs, intEq);
        // This mod was high enough that all values were distinct
      then mod;
    else
      equation
        true = inMod < 65536;
      then findMinMod(inIxs,inMod*2);
  end matchcontinue;
end findMinMod;

protected function filterUnusedPatterns
  "case (1,_,_) then ...; case (2,_,_) then ...; =>"
  input list<DAE.Exp> inputs "We can only remove inputs that are free from side-effects";
  input list<list<String>> inAliases;
  input list<DAE.MatchCase> inCases;
  output list<DAE.Exp> outInputs;
  output list<list<String>> outAliases;
  output list<DAE.MatchCase> outCases;
algorithm
  (outInputs,outAliases,outCases) := matchcontinue (inputs,inAliases,inCases)
    local
      list<list<DAE.Pattern>> patternMatrix;
      list<DAE.MatchCase> cases;

    case (_,_,cases)
      equation
        patternMatrix = List.transposeList(List.map(cases,getCasePatterns));
        (true,outInputs,outAliases,patternMatrix) = filterUnusedPatterns2(inputs,inAliases,patternMatrix,false,{},{},{});
        patternMatrix = List.transposeList(patternMatrix);
        cases = List.threadMap(cases,patternMatrix,setCasePatterns);
      then (outInputs,outAliases,cases);
    else (inputs,inAliases,inCases);
  end matchcontinue;
end filterUnusedPatterns;

protected function filterUnusedPatterns2
  "case (1,_,_) then ...; case (2,_,_) then ...; =>"
  input list<DAE.Exp> inInputs "We can only remove inputs that are free from side-effects";
  input list<list<String>> inAliases;
  input list<list<DAE.Pattern>> inPatternMatrix;
  input Boolean change "Only rebuild the cases if something changed";
  input list<DAE.Exp> inputsAcc;
  input list<list<String>> aliasesAcc;
  input list<list<DAE.Pattern>> patternMatrixAcc;
  output Boolean outChange;
  output list<DAE.Exp> outInputs;
  output list<list<String>> outAliases;
  output list<list<DAE.Pattern>> outPatternMatrix;
algorithm
  (outChange,outInputs,outAliases,outPatternMatrix) := matchcontinue (inInputs,inAliases,inPatternMatrix,change,inputsAcc,aliasesAcc,patternMatrixAcc)
    local
      DAE.Exp e;
      list<DAE.Pattern> pats;
      list<DAE.Exp> inputs;
      list<list<DAE.Pattern>> patternMatrix;
      list<String> alias;
      list<list<String>> aliases;

    case ({},{},{},true,_,_,_)
      then (true,listReverse(inputsAcc),listReverse(aliasesAcc),listReverse(patternMatrixAcc));
    case (e::inputs,_::aliases,pats::patternMatrix,_,_,_,_)
      equation
        ((_,true)) = Expression.traverseExp(e,Expression.hasNoSideEffects,true);
        true = allPatternsWild(pats);
        (outChange,outInputs,outAliases,outPatternMatrix) = filterUnusedPatterns2(inputs,aliases,patternMatrix,true,inputsAcc,aliasesAcc,patternMatrixAcc);
      then (outChange,outInputs,outAliases,outPatternMatrix);
    case (e::inputs,alias::aliases,pats::patternMatrix,_,_,_,_)
      equation
        (outChange,outInputs,outAliases,outPatternMatrix) = filterUnusedPatterns2(inputs,aliases,patternMatrix,change,e::inputsAcc,alias::aliasesAcc,pats::patternMatrixAcc);
      then (outChange,outInputs,outAliases,outPatternMatrix);
    else (false,{},{},{});
  end matchcontinue;
end filterUnusedPatterns2;

protected function getUsedLocalCrefs
  input Boolean skipFilterUnusedAsBindings "if true, traverse the whole expression; else only the bodies and results";
  input DAE.Exp exp;
  input Integer hashSize;
  output HashTableStringToPath.HashTable ht;
algorithm
  ht := match (skipFilterUnusedAsBindings,exp,hashSize)
    local
      list<DAE.MatchCase> cases;
    case (true,_,_)
      equation
        ((_,ht)) = Expression.traverseExp(exp, addLocalCref, HashTableStringToPath.emptyHashTableSized(hashSize));
      then ht;
    case (false,DAE.MATCHEXPRESSION(cases=cases),_)
      equation
        (_,ht) = traverseCases(cases, addLocalCref, HashTableStringToPath.emptyHashTableSized(hashSize));
      then ht;
  end match;
end getUsedLocalCrefs;

protected function filterUnusedAsBindings
  input list<DAE.MatchCase> inCases;
  input HashTableStringToPath.HashTable ht;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := match (inCases,ht)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> localDecls;
      list<DAE.Statement> body;
      Option<DAE.Exp> guardPattern, result;
      Integer jump;
      Absyn.Info resultInfo, info;
      list<DAE.MatchCase> cases;

    case ({},_) then {};
    case (DAE.CASE(patterns, guardPattern, localDecls, body, result, resultInfo, jump, info)::cases,_)
      equation
        (patterns,_) = traversePatternList(patterns, removePatternAsBinding, (ht,info));
        cases = filterUnusedAsBindings(cases,ht);
      then DAE.CASE(patterns, guardPattern, localDecls, body, result, resultInfo, jump, info)::cases;
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
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_AS_BINDING, {id}, info);
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
      DAE.ComponentRef cr;
    case ((exp as DAE.CREF(componentRef=cr),ht))
      equation
        ht = addLocalCrefHelper(cr,ht);
      then ((exp,ht));
    case ((exp as DAE.CALL(path=Absyn.IDENT(name), attr=DAE.CALL_ATTR(builtin=false)),ht))
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

protected function addLocalCrefHelper
  input DAE.ComponentRef cr;
  input HashTableStringToPath.HashTable iht;
  output HashTableStringToPath.HashTable ht;
algorithm
  ht := match (cr,iht)
    local
      String name;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr2;
    case (DAE.CREF_IDENT(ident=name,subscriptLst=subs),ht)
      equation
        ht = addLocalCrefSubs(subs,ht);
        ht = BaseHashTable.add((name,Absyn.IDENT("")), ht);
      then ht;
    case (DAE.CREF_QUAL(ident=name,subscriptLst=subs,componentRef=cr2),ht)
      equation
        ht = addLocalCrefSubs(subs,ht);
        ht = BaseHashTable.add((name,Absyn.IDENT("")), ht);
      then addLocalCrefHelper(cr2,ht);
    else iht;
  end match;
end addLocalCrefHelper;

protected function addLocalCrefSubs
  "Cref subscripts may also contain crefs"
  input list<DAE.Subscript> isubs;
  input HashTableStringToPath.HashTable iht;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (isubs,iht)
    local
      DAE.Exp exp;
      list<DAE.Subscript> subs;
      HashTableStringToPath.HashTable ht;

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
    else iht;
  end match;
end addLocalCrefSubs;

protected function checkDefUse
"Use with traverseExp to collect all CREF's that could be references to local
variables."
  input tuple<DAE.Exp,tuple<AvlTreeString.AvlTree,AvlTreeString.AvlTree,Absyn.Info>> inTpl;
  output tuple<DAE.Exp,tuple<AvlTreeString.AvlTree,AvlTreeString.AvlTree,Absyn.Info>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      DAE.Exp exp;
      AvlTreeString.AvlTree localsTree,useTree;
      String name;
      DAE.Pattern pat;
      DAE.ComponentRef cr;
      Absyn.Info info;
      DAE.Type ty;
      tuple<AvlTreeString.AvlTree,AvlTreeString.AvlTree,Absyn.Info> extra;
    case ((exp as DAE.CREF(componentRef=cr,ty=ty),extra as (localsTree,useTree,info)))
      equation
        name = ComponentReference.crefFirstIdent(cr);
        // TODO: Can skip matchcontinue and failure if there was an AvlTree.exists(key)
        _ = AvlTreeString.avlTreeGet(localsTree,name);
        failure(_ = AvlTreeString.avlTreeGet(useTree,name));
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_ASSIGNMENT,{name},info);
      then ((DAE.CREF(DAE.WILD(),ty),extra));
    case ((DAE.PATTERN(pattern=pat),extra))
      equation
        ((pat,extra)) = traversePattern((pat,extra), checkDefUsePattern);
      then ((DAE.PATTERN(pat),extra));
    else inTpl;
  end matchcontinue;
end checkDefUse;

protected function checkDefUsePattern
"Replace unused assignments with wildcards"
  input tuple<DAE.Pattern,tuple<AvlTreeString.AvlTree,AvlTreeString.AvlTree,Absyn.Info>> inTpl;
  output tuple<DAE.Pattern,tuple<AvlTreeString.AvlTree,AvlTreeString.AvlTree,Absyn.Info>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      AvlTreeString.AvlTree localsTree,useTree;
      String name;
      DAE.Pattern pat;
      Absyn.Info info;
      DAE.Type ty;
      tuple<AvlTreeString.AvlTree,AvlTreeString.AvlTree,Absyn.Info> extra;
    case ((DAE.PAT_AS(id=name,pat=pat),extra as (localsTree,useTree,info)))
      equation
        // TODO: Can skip matchcontinue and failure if there was an AvlTree.exists(key)
        _ = AvlTreeString.avlTreeGet(localsTree,name);
        failure(_ = AvlTreeString.avlTreeGet(useTree,name));
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_AS_BINDING,{name},info);
      then ((pat,extra));
    case ((DAE.PAT_AS_FUNC_PTR(id=name,pat=pat),extra as (localsTree,useTree,info)))
      equation
        // TODO: Can skip matchcontinue and failure if there was an AvlTree.exists(key)
        _ = AvlTreeString.avlTreeGet(localsTree,name);
        failure(_ = AvlTreeString.avlTreeGet(useTree,name));
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_AS_BINDING,{name},info);
      then ((pat,extra));
    else simplifyPattern(inTpl);
  end matchcontinue;
end checkDefUsePattern;

protected function useLocalCref
"Use with traverseExp to collect all CREF's that could be references to local
variables."
  input tuple<DAE.Exp,AvlTreeString.AvlTree> inTpl;
  output tuple<DAE.Exp,AvlTreeString.AvlTree> outTpl;
algorithm
  outTpl := match inTpl
    local
      DAE.Exp exp;
      AvlTreeString.AvlTree tree;
      String name;
      list<DAE.MatchCase> cases;
      DAE.Pattern pat;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr;
    case ((exp as DAE.CREF(componentRef=cr),tree))
      equation
        tree = useLocalCrefHelper(cr,tree);
      then ((exp,tree));
    case ((exp as DAE.CALL(path=Absyn.IDENT(name), attr=DAE.CALL_ATTR(builtin=false)),tree))
      equation
        tree = AvlTreeString.avlTreeAdd(tree, name, 1);
      then ((exp,tree));
    case ((exp as DAE.PATTERN(pattern=pat),tree))
      equation
        ((_,tree)) = traversePattern((pat,tree), usePatternAsBindings);
      then ((exp,tree));
    case ((exp as DAE.MATCHEXPRESSION(cases=cases),tree))
      equation
        tree = useCasesLocalCref(cases,tree);
      then ((exp,tree));
    else inTpl;
  end match;
end useLocalCref;

protected function useLocalCrefHelper
  input DAE.ComponentRef cr;
  input AvlTreeString.AvlTree inTree;
  output AvlTreeString.AvlTree tree;
algorithm
  tree := match (cr,inTree)
    local
      String name;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cr2;
    case (DAE.CREF_IDENT(ident=name,subscriptLst=subs), _)
      equation
        tree = useLocalCrefSubs(subs,inTree);
      then AvlTreeString.avlTreeAdd(tree, name, 1);
    case (DAE.CREF_QUAL(ident=name,subscriptLst=subs,componentRef=cr2),_)
      equation
        tree = useLocalCrefSubs(subs,inTree);
        tree = AvlTreeString.avlTreeAdd(tree, name, 1);
      then useLocalCrefHelper(cr2,tree);
    else inTree;
  end match;
end useLocalCrefHelper;

protected function useLocalCrefSubs
  "Cref subscripts may also contain crefs"
  input list<DAE.Subscript> isubs;
  input AvlTreeString.AvlTree inTree;
  output AvlTreeString.AvlTree tree;
algorithm
  tree := match (isubs,inTree)
    local
      DAE.Exp exp;
      list<DAE.Subscript> subs;

    case ({},_) then inTree;
    case (DAE.SLICE(exp)::subs,_)
      equation
        ((_,tree)) = Expression.traverseExp(exp, useLocalCref, inTree);
        tree = useLocalCrefSubs(subs,tree);
      then tree;
    case (DAE.INDEX(exp)::subs,_)
      equation
        ((_,tree)) = Expression.traverseExp(exp, useLocalCref, inTree);
        tree = useLocalCrefSubs(subs,tree);
      then tree;
    else inTree;
  end match;
end useLocalCrefSubs;

protected function usePatternAsBindings
  "Traverse patterns and as-bindings as variable references in the hashtable"
  input tuple<DAE.Pattern,AvlTreeString.AvlTree> inTpl;
  output tuple<DAE.Pattern,AvlTreeString.AvlTree> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      AvlTreeString.AvlTree tree;
      DAE.Pattern pat;
      String id;
    case ((pat as DAE.PAT_AS(id=id),tree))
      equation
        tree = AvlTreeString.avlTreeAdd(tree, id, 1);
      then ((pat,tree));
    case ((pat as DAE.PAT_AS_FUNC_PTR(id=id),tree))
      equation
        tree = AvlTreeString.avlTreeAdd(tree, id, 1);
      then ((pat,tree));
    else inTpl;
  end matchcontinue;
end usePatternAsBindings;

protected function useCasesLocalCref
  input list<DAE.MatchCase> icases;
  input AvlTreeString.AvlTree inTree;
  output AvlTreeString.AvlTree tree;
algorithm
  tree := match (icases,inTree)
    local
      list<DAE.Pattern> pats;
      list<DAE.MatchCase> cases;

    case ({},_) then inTree;
    case (DAE.CASE(patterns=pats)::cases,_)
      equation
        (_,tree) = traversePatternList(pats, usePatternAsBindings, inTree);
        tree = useCasesLocalCref(cases,tree);
      then tree;
  end match;
end useCasesLocalCref;

protected function addCasesLocalCref
  input list<DAE.MatchCase> icases;
  input HashTableStringToPath.HashTable iht;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (icases,iht)
    local
      list<DAE.Pattern> pats;
      list<DAE.MatchCase> cases;
      HashTableStringToPath.HashTable ht;

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
      DAE.Pattern pat,pat2;
      list<tuple<DAE.Pattern, String, DAE.Type>> namedPatterns;
      list<DAE.Pattern> patterns;
    case ((DAE.PAT_CALL_NAMED(name, namedPatterns),a))
      equation
        namedPatterns = List.filter(namedPatterns, filterEmptyPattern);
        pat = Util.if_(List.isEmpty(namedPatterns), DAE.PAT_WILD(), DAE.PAT_CALL_NAMED(name, namedPatterns));
      then ((pat,a));
    case ((pat as DAE.PAT_CALL_TUPLE(patterns),a))
      equation
        pat2 = Util.if_(allPatternsWild(patterns), DAE.PAT_WILD(), pat);
      then ((pat2,a));
    case ((pat as DAE.PAT_META_TUPLE(patterns),a))
      equation
        pat2 = Util.if_(allPatternsWild(patterns), DAE.PAT_WILD(), pat);
      then ((pat2,a));
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
  input list<DAE.Pattern> ipats;
  input Func func;
  input TypeA ia;
  output list<DAE.Pattern> outPats;
  output TypeA oa;
  partial function Func
    input tuple<DAE.Pattern,TypeA> inTpl;
    output tuple<DAE.Pattern,TypeA> outTpl;
  end Func;
  replaceable type TypeA subtypeof Any;
algorithm
  (outPats,oa) := match (ipats,func,ia)
    local
      DAE.Pattern pat;
      list<DAE.Pattern> pats;
      TypeA a;

    case ({},_,a) then ({},a);
    case (pat::pats,_,a)
      equation
        ((pat,a)) = traversePattern((pat,a),func);
        (pats,a) = traversePatternList(pats,func,a);
      then (pat::pats,a);
  end match;
end traversePatternList;

public function traversePattern
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
      list<DAE.Type> types;
      String id,str;
      Option<DAE.Type> ty;
      Absyn.Path name;
      Integer index;
      list<tuple<DAE.Pattern,String,DAE.Type>> namedpats;
      Boolean knownSingleton;
      list<DAE.Var> fieldVars;
      DAE.Attributes attr;
    case ((DAE.PAT_AS(id,ty,attr,pat2),a),_)
      equation
        ((pat2,a)) = traversePattern((pat2,a),func);
        pat = DAE.PAT_AS(id,ty,attr,pat2);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_AS_FUNC_PTR(id,pat2),a),_)
      equation
        ((pat2,a)) = traversePattern((pat2,a),func);
        pat = DAE.PAT_AS_FUNC_PTR(id,pat2);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CALL(name,index,pats,fieldVars,knownSingleton),a),_)
      equation
        (pats,a) = traversePatternList(pats, func, a);
        pat = DAE.PAT_CALL(name,index,pats,fieldVars,knownSingleton);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CALL_NAMED(name,namedpats),a),_)
      equation
        pats = List.map(namedpats,Util.tuple31);
        fields = List.map(namedpats,Util.tuple32);
        types = List.map(namedpats,Util.tuple33);
        (pats,a) = traversePatternList(pats, func, a);
        namedpats = List.thread3Tuple(pats, fields, types);
        pat = DAE.PAT_CALL_NAMED(name,namedpats);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CALL_TUPLE(pats),a),_)
      equation
        (pats,a) = traversePatternList(pats, func, a);
        pat = DAE.PAT_CALL_TUPLE(pats);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_META_TUPLE(pats),a),_)
      equation
        (pats,a) = traversePatternList(pats, func, a);
        pat = DAE.PAT_META_TUPLE(pats);
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_CONS(pat1,pat2),a),_)
      equation
        ((pat1,a)) = traversePattern((pat1,a),func);
        ((pat2,a)) = traversePattern((pat2,a),func);
        pat = DAE.PAT_CONS(pat1,pat2);
        outTpl = func((pat,a));
      then outTpl;
    case ((pat as DAE.PAT_CONSTANT(ty=_),a),_)
      equation
        outTpl = func((pat,a));
      then outTpl;
    case ((DAE.PAT_SOME(pat1),a),_)
      equation
        ((pat1,a)) = traversePattern((pat1,a),func);
        pat = DAE.PAT_SOME(pat1);
        outTpl = func((pat,a));
      then outTpl;
    case ((pat as DAE.PAT_WILD(),a),_)
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
  input list<DAE.Element> iacc;
  input HashTableStringToPath.HashTable iunusedHt;
  output list<DAE.Element> outDecls;
  output HashTableStringToPath.HashTable outUnusedHt;
algorithm
  (outDecls,outUnusedHt) := matchcontinue (matchDecls,ht,iacc,iunusedHt)
    local
      DAE.Element el;
      list<DAE.Element> rest;
      Absyn.Info info;
      String name;
      list<DAE.Element> acc;
      HashTableStringToPath.HashTable unusedHt;

    case ({},_,acc,unusedHt) then (listReverse(acc),unusedHt);
    case (DAE.VAR(componentRef=DAE.CREF_IDENT(ident=name), source=DAE.SOURCE(info=info))::rest,_,acc,unusedHt)
      equation
        failure(_ = BaseHashTable.get(name, ht));
        unusedHt = BaseHashTable.add((name,Absyn.IDENT("")),unusedHt);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_UNUSED_DECL, {name}, info);
        (acc,unusedHt) = filterUnusedDecls(rest,ht,acc,unusedHt);
      then (acc,unusedHt);
    case (el::rest,_,acc,unusedHt)
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
  input list<DAE.MatchCase> iacc;
  input Boolean iter "If we remove some code, it may cascade. We should we loop more.";
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := matchcontinue (matchType,cases,prevPatterns,iacc,iter)
    local
      list<DAE.MatchCase> rest;
      list<DAE.Pattern> pats;
      DAE.MatchCase case_;
      Absyn.Info info;
      list<DAE.MatchCase> acc;

    case (_,{},_,acc,false) then listReverse(acc);
    case (_,{},_,acc,true) then caseDeadCodeEliminiation(matchType,listReverse(acc),{},{},false);
    case (_,DAE.CASE(body={},result=NONE(),info=info)::{},_,acc,_)
      equation
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Last pattern is empty"}, info);
      then caseDeadCodeEliminiation(matchType,listReverse(acc),{},{},false);
        /* Tricky to get right; I'll try again later as it probably only gives marginal results anyway
    case (Absyn.MATCH(),DAE.CASE(patterns=pats,info=info)::rest,prevPatterns as _::_,acc,iter)
      equation
        oinfo = findOverlappingPattern(pats,acc);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Unreachable pattern"}, info);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Shadowing case"}, oinfo);
      then caseDeadCodeEliminiation(matchType,rest,pats::prevPatterns,acc,true);
      */
    case (Absyn.MATCHCONTINUE(),DAE.CASE(patterns=pats,body={},result=NONE(),info=info)::rest,_,acc,_)
      equation
        true = Flags.isSet(Flags.PATTERNM_DCE);
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.META_DEAD_CODE, {"Empty matchcontinue case"}, info);
        acc = caseDeadCodeEliminiation(matchType,rest,pats::prevPatterns,acc,true);
      then acc;
    case (_,(case_ as DAE.CASE(patterns=pats))::rest,_,acc,_) then caseDeadCodeEliminiation(matchType,rest,pats::prevPatterns,case_::acc,iter);
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
    case (Absyn.MATCH(),_) then cases;
    else optimizeContinueJumps2(cases);
  end match;
end optimizeContinueJumps;

protected function optimizeContinueJumps2
  input list<DAE.MatchCase> icases;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := match icases
    local
      DAE.MatchCase case_;
      list<DAE.MatchCase> cases;

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
  input list<DAE.MatchCase> icases;
  input Integer jump;
  output DAE.MatchCase outCase;
algorithm
  outCase := matchcontinue (case_,icases,jump)
    local
      DAE.MatchCase case1;
      list<DAE.Pattern> ps1,ps2;
      list<DAE.MatchCase> cases;

    case (case1,{},_) then updateMatchCaseJump(case1,jump);
    case (case1 as DAE.CASE(patterns=ps1),DAE.CASE(patterns=ps2)::cases,_)
      equation
        true = patternListsDoNotOverlap(ps1,ps2);
      then optimizeContinueJump(case1,cases,jump+1);
    case (case1,_,_) then updateMatchCaseJump(case1,jump);
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
      Option<DAE.Exp> result,guardPattern;
      Absyn.Info resultInfo, info;
    case (_,0) then case_;
    case (DAE.CASE(patterns, guardPattern, localDecls, body, result, resultInfo, _, info), _)
      then DAE.CASE(patterns, guardPattern, localDecls, body, result, resultInfo, jump, info);
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
  input list<DAE.MatchCase> icases;
  input list<list<DAE.Pattern>> prevPatterns "All cases check its patterns against all previous patterns. If they overlap, we can't optimize away the continue";
  input Absyn.Info info;
  output Absyn.MatchType outMatchType;
algorithm
  outMatchType := matchcontinue (icases,prevPatterns,info)
    local
      list<DAE.Pattern> patterns;
      list<DAE.MatchCase> cases;

    case ({},_,_)
      equation
        Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.PATTERNM_ALL_INFO), Error.MATCHCONTINUE_TO_MATCH_OPTIMIZATION, {}, info);
      then Absyn.MATCH();
    case (DAE.CASE(patterns=patterns)::cases,_,_)
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
  input list<list<DAE.Pattern>> ipss1;
  input list<DAE.Pattern> ps2;
algorithm
  _ := match (ipss1,ps2)
    local
      list<DAE.Pattern> ps1;
      list<list<DAE.Pattern>> pss1;

    case ({},_) then ();
    case (ps1::pss1,_)
      equation
        true = patternListsDoNotOverlap(ps1,ps2);
        assertAllPatternListsDoNotOverlap(pss1,ps2);
      then ();
  end match;
end assertAllPatternListsDoNotOverlap;

protected function patternListsDoNotOverlap
  "Verifies that pats1 does not shadow pats2"
  input list<DAE.Pattern> ips1;
  input list<DAE.Pattern> ips2;
  output Boolean b;
algorithm
  b := match (ips1,ips2)
    local
      Boolean res;
      DAE.Pattern p1,p2;
      list<DAE.Pattern> ps1,ps2;

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
  input DAE.Pattern ip1;
  input DAE.Pattern ip2;
  output Boolean b;
algorithm
  b := match (ip1,ip2)
    local
      DAE.Pattern head1,tail1,head2,tail2,p1,p2;
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

    case (DAE.PAT_CALL(name1,ix1,{},_,_),DAE.PAT_CALL(name2,ix2,{},_,_))
      equation
        res = ix1 == ix2;
        res = Debug.bcallret2(res, Absyn.pathEqual, name1, name2, res);
      then not res;

    case (DAE.PAT_CALL(name1,ix1,ps1,_,_),DAE.PAT_CALL(name2,ix2,ps2,_,_))
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
  input list<list<String>> inputAliases;
  input AvlTreeString.AvlTree matchExpLocalTree;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> st;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info info;
  output Env.Cache outCache;
  output list<DAE.MatchCase> elabCases;
  output DAE.Type resType;
  output Option<GlobalScript.SymbolTable> outSt;
protected
  list<DAE.Exp> resExps;
  list<DAE.Type> resTypes,tysFixed;
algorithm
  tysFixed := List.map(tys, Types.getUniontypeIfMetarecordReplaceAllSubtypes);
  (outCache,elabCases,resExps,resTypes,outSt) := elabMatchCases2(cache,env,cases,tysFixed,inputAliases,matchExpLocalTree,impl,st,performVectorization,pre,{},{},{});
  (elabCases,resType) := fixCaseReturnTypes(elabCases,resExps,resTypes,info);
end elabMatchCases;

protected function elabMatchCases2
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Case> cases;
  input list<DAE.Type> tys;
  input list<list<String>> inputAliases;
  input AvlTreeString.AvlTree matchExpLocalTree;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input list<DAE.MatchCase> inAccCases "Order does matter";
  input list<DAE.Exp> inAccExps "Order does matter";
  input list<DAE.Type> inAccTypes "Order does not matter";
  output Env.Cache outCache;
  output list<DAE.MatchCase> elabCases;
  output list<DAE.Exp> resExps;
  output list<DAE.Type> resTypes;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,elabCases,resExps,resTypes,outSt) :=
  match (inCache,inEnv,cases,tys,inputAliases,matchExpLocalTree,impl,inSt,performVectorization,pre,inAccCases,inAccExps,inAccTypes)
    local
      Absyn.Case case_;
      list<Absyn.Case> rest;
      DAE.MatchCase elabCase;
      Option<DAE.Type> optType;
      Option<DAE.Exp> optExp;
      Env.Cache cache;
      Env.Env env;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Exp> accExps;
      list<DAE.Type> accTypes;

    case (cache,env,{},_,_,_,_,st,_,_,_,accExps,accTypes) then (cache,listReverse(inAccCases),listReverse(accExps),listReverse(accTypes),st);
    case (cache,env,case_::rest,_,_,_,_,st,_,_,_,accExps,accTypes)
      equation
        (cache,elabCase,optExp,optType,st) = elabMatchCase(cache,env,case_,tys,inputAliases,matchExpLocalTree,impl,st,performVectorization,pre);
        (cache,elabCases,accExps,accTypes,st) = elabMatchCases2(cache,env,rest,tys,inputAliases,matchExpLocalTree,impl,st,performVectorization,pre,elabCase::inAccCases,List.consOption(optExp,accExps),List.consOption(optType,accTypes));
      then (cache,elabCases,accExps,accTypes,st);
  end match;
end elabMatchCases2;

protected function elabMatchCase
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Case acase;
  input list<DAE.Type> tys;
  input list<list<String>> inputAliases;
  input AvlTreeString.AvlTree matchExpLocalTree;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  output Env.Cache outCache;
  output DAE.MatchCase elabCase;
  output Option<DAE.Exp> resExp;
  output Option<DAE.Type> resType;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,elabCase,resExp,resType,outSt) :=
  match (inCache,inEnv,acase,tys,inputAliases,matchExpLocalTree,impl,inSt,performVectorization,pre)
    local
      Absyn.Exp result,pattern;
      list<Absyn.Exp> patterns;
      list<DAE.Pattern> elabPatterns;
      Option<Absyn.Exp> patternGuard;
      Option<DAE.Exp> elabResult,dPatternGuard;
      list<DAE.Element> caseDecls;
      list<Absyn.EquationItem> eq1;
      list<Absyn.AlgorithmItem> eqAlgs;
      list<SCode.Statement> algs;
      list<DAE.Statement> body;
      list<Absyn.ElementItem> decls;
      Absyn.Info patternInfo,resultInfo,info;
      Integer len;
      Env.Cache cache;
      Env.Env env;
      Option<GlobalScript.SymbolTable> st;
      AvlTreeString.AvlTree caseLocalTree,localsTree,useTree;

    case (cache,env,Absyn.CASE(pattern=pattern,patternGuard=patternGuard,patternInfo=patternInfo,localDecls=decls,equations=eq1,result=result,resultInfo=resultInfo,info=info),_,_,_,_,st,_,_)
      equation
        (cache,SOME((env,DAE.DAE(caseDecls),caseLocalTree))) = addLocalDecls(cache,env,decls,Env.caseScopeName,impl,info);
        patterns = MetaUtil.extractListFromTuple(pattern, 0);
        patterns = Util.if_(listLength(tys)==1, {pattern}, patterns);
        (cache,elabPatterns) = elabPatternTuple(cache, env, patterns, tys, patternInfo, pattern);
        (_,env) = traversePatternList(List.threadMap(elabPatterns,inputAliases,addPatternAliases),addEnvKnownAsBindings,env);
        (cache,eqAlgs) = Static.fromEquationsToAlgAssignments(eq1,{},cache,env,pre);
        algs = SCodeUtil.translateClassdefAlgorithmitems(eqAlgs);
        (cache,body) = InstSection.instStatements(cache, env, InnerOuter.emptyInstHierarchy, pre, ClassInf.FUNCTION(Absyn.IDENT("match"), false), algs, DAEUtil.addElementSourceFileInfo(DAE.emptyElementSource,patternInfo), SCode.NON_INITIAL(), true, InstTypes.neverUnroll, {});
        (cache,body,elabResult,resultInfo,resType,st) = elabResultExp(cache,env,body,result,impl,st,performVectorization,pre,resultInfo);
        (cache,dPatternGuard,st) = elabPatternGuard(cache,env,patternGuard,impl,st,performVectorization,pre,patternInfo);
        localsTree = AvlTreeString.joinAvlTrees(matchExpLocalTree, caseLocalTree);
        // Start building the def-use chain bottom-up
        useTree = AvlTreeString.avlTreeNew();
        ((_,useTree)) = Expression.traverseExp(DAE.META_OPTION(elabResult), useLocalCref, useTree);
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,useTree);
        ((_,useTree)) = Expression.traverseExp(DAE.META_OPTION(dPatternGuard), useLocalCref, useTree);
        (elabPatterns,_) = traversePatternList(elabPatterns, checkDefUsePattern, (localsTree,useTree,patternInfo));
        // Do the same thing again, for fun and glory
        useTree = AvlTreeString.avlTreeNew();
        ((_,useTree)) = Expression.traverseExp(DAE.META_OPTION(elabResult), useLocalCref, useTree);
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,useTree);
        ((_,useTree)) = Expression.traverseExp(DAE.META_OPTION(dPatternGuard), useLocalCref, useTree);
        (elabPatterns,_) = traversePatternList(elabPatterns, checkDefUsePattern, (localsTree,useTree,patternInfo));
        elabCase = DAE.CASE(elabPatterns, dPatternGuard, caseDecls, body, elabResult, resultInfo, 0, info);
      then (cache,elabCase,elabResult,resType,st);

      // ELSE is the same as CASE, but without pattern
    case (cache,env,Absyn.ELSE(localDecls=decls,equations=eq1,result=result,resultInfo=resultInfo,info=info),_,_,_,_,st,_,_)
      equation
        // Needs to be same length as any other pattern for the simplification algorithms, etc to work properly
        len = listLength(tys);
        patterns = List.fill(Absyn.CREF(Absyn.WILD()),listLength(tys));
        pattern = Util.if_(len == 1, Absyn.CREF(Absyn.WILD()), Absyn.TUPLE(patterns));
        (cache,elabCase,elabResult,resType,st) = elabMatchCase(cache, env, Absyn.CASE(pattern,NONE(),info,decls,eq1,result,resultInfo,NONE(),info), tys, inputAliases, matchExpLocalTree, impl, st, performVectorization, pre);
      then (cache,elabCase,elabResult,resType,st);

  end match;
end elabMatchCase;

protected function elabResultExp
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<DAE.Statement> inBody "Is input in case we want to optimize for tail-recursion";
  input Absyn.Exp exp;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output list<DAE.Statement> outBody;
  output Option<DAE.Exp> resExp;
  output Absyn.Info resultInfo;
  output Option<DAE.Type> resType;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,outBody,resExp,resultInfo,resType,outSt) :=
  matchcontinue (inCache,inEnv,inBody,exp,impl,inSt,performVectorization,pre,inInfo)
    local
      DAE.Exp elabExp;
      DAE.Properties prop;
      DAE.Type ty;
      Env.Cache cache;
      Env.Env env;
      Option<GlobalScript.SymbolTable> st;
      list<DAE.Statement> body;
      Absyn.Info info;

    case (cache,env,body,Absyn.CALL(function_ = Absyn.CREF_IDENT("fail",{}), functionArgs = Absyn.FUNCTIONARGS({},{})),_,st,_,_,info)
      then (cache,body,NONE(),info,NONE(),st);

    case (cache,env,body,_,_,st,_,_,info)
      equation
        (cache,elabExp,prop,st) = Static.elabExp(cache,env,exp,impl,st,performVectorization,pre,info);
        (body,elabExp,info) = elabResultExp2(not Flags.isSet(Flags.PATTERNM_MOVE_LAST_EXP),body,elabExp,info);
        ty = Types.getPropType(prop);
      then (cache,body,SOME(elabExp),info,SOME(ty),st);
  end matchcontinue;
end elabResultExp;

protected function elabPatternGuard
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.Exp> patternGuard;
  input Boolean impl;
  input Option<GlobalScript.SymbolTable> inSt;
  input Boolean performVectorization;
  input Prefix.Prefix pre;
  input Absyn.Info inInfo;
  output Env.Cache outCache;
  output Option<DAE.Exp> outPatternGuard;
  output Option<GlobalScript.SymbolTable> outSt;
algorithm
  (outCache,outPatternGuard,outSt) :=
  matchcontinue (inCache,inEnv,patternGuard,impl,inSt,performVectorization,pre,inInfo)
    local
      Absyn.Exp exp;
      DAE.Exp elabExp;
      DAE.Properties prop;
      Env.Cache cache;
      Env.Env env;
      Option<GlobalScript.SymbolTable> st;
      Absyn.Info info;
      String str;

    case (cache,env,NONE(),_,st,_,_,info)
      then (cache,NONE(),st);

    case (cache,env,SOME(exp),_,st,_,_,info)
      equation
        (cache,elabExp,prop,st) = Static.elabExp(cache,env,exp,impl,st,performVectorization,pre,info);
        (elabExp,_) = Types.matchType(elabExp,Types.getPropType(prop),DAE.T_BOOL_DEFAULT,true);
      then (cache,SOME(elabExp),st);

    case (cache,env,SOME(exp),_,st,_,_,info)
      equation
        (cache,elabExp,prop,st) = Static.elabExp(cache,env,exp,impl,st,performVectorization,pre,info);
        str = Types.unparseType(Types.getPropType(prop));
        Error.addSourceMessage(Error.GUARD_EXPRESSION_TYPE_MISMATCH, {str}, info);
      then fail();

  end matchcontinue;
end elabPatternGuard;

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
  input Absyn.Info info;
  output list<DAE.Statement> outBody;
  output DAE.Exp outExp;
  output Absyn.Info outInfo;
algorithm
  (outBody,outExp,outInfo) := matchcontinue (skipPhase,body,elabExp,info)
    local
      DAE.Exp elabCr1,elabCr2;
      list<DAE.Exp> elabCrs1,elabCrs2;
      list<DAE.Statement> b;
      DAE.Exp e;
      Absyn.Info i;

    case (true,b,e,i) then (b,e,i);
    case (_,b,elabCr2 as DAE.CREF(ty=_),_)
      equation
        (DAE.STMT_ASSIGN(exp1=elabCr1,exp=e,source=DAE.SOURCE(info=i)),b) = List.splitLast(b);
        true = Expression.expEqual(elabCr1,elabCr2);
        (b,e,i) = elabResultExp2(false,b,e,i);
      then (b,e,i);
    case (_,b,DAE.TUPLE(elabCrs2),_)
      equation
        (DAE.STMT_TUPLE_ASSIGN(expExpLst=elabCrs1,exp=e,source=DAE.SOURCE(info=i)),b) = List.splitLast(b);
        List.threadMapAllValue(elabCrs1, elabCrs2, Expression.expEqual, true);
        (b,e,i) = elabResultExp2(false,b,e,i);
      then (b,e,i);
    else (body,elabExp,info);
  end matchcontinue;
end elabResultExp2;

protected function fixCaseReturnTypes
  input list<DAE.MatchCase> icases;
  input list<DAE.Exp> iexps;
  input list<DAE.Type> itys;
  input Absyn.Info info;
  output list<DAE.MatchCase> outCases;
  output DAE.Type ty;
algorithm
  (outCases,ty) := matchcontinue (icases,iexps,itys,info)
    local
      String str;
      list<DAE.MatchCase> cases;
      list<DAE.Exp> exps;
      list<DAE.Type> tys,tysboxed;

    case (cases,{},{},_) then (cases,DAE.T_NORETCALL_DEFAULT);

    case (cases,exps,tys,_)
      equation
        ty = List.reduce(List.map(tys, Types.boxIfUnboxedType), Types.superType);
        ty = Types.superType(ty, ty);
        ty = Types.unboxedType(ty);
        ty = Types.makeRegularTupleFromMetaTupleOnTrue(Types.allTuple(tys),ty);
        ty = Types.getUniontypeIfMetarecordReplaceAllSubtypes(ty);
        (exps,_) = Types.matchTypes(exps, tys, ty, true);
        cases = fixCaseReturnTypes2(cases,exps,info);
      then (cases,ty);

    // 2 different cases, one boxed and one unboxed to handle everything
    case (cases,exps,tys,_)
      equation
        ty = List.reduce(tys, Types.superType);
        ty = Types.superType(ty, ty);
        ty = Types.unboxedType(ty);
        ty = Types.makeRegularTupleFromMetaTupleOnTrue(Types.allTuple(tys),ty);
        ty = Types.getUniontypeIfMetarecordReplaceAllSubtypes(ty);
        (exps,_) = Types.matchTypes(exps, tys, ty, true);
        cases = fixCaseReturnTypes2(cases,exps,info);
      then (cases,ty);

    else
      equation
        tys = List.unionOnTrue(itys, {}, Types.equivtypes);
        str = stringAppendList(List.map1r(List.map(tys, Types.unparseType), stringAppend, "\n  "));
        Error.addSourceMessage(Error.META_MATCHEXP_RESULT_TYPES, {str}, info);
      then fail();

  end matchcontinue;
end fixCaseReturnTypes;

public function fixCaseReturnTypes2
  input list<DAE.MatchCase> inCases;
  input list<DAE.Exp> inExps;
  input Absyn.Info inInfo;
  output list<DAE.MatchCase> outCases;
algorithm
  outCases := matchcontinue (inCases,inExps,inInfo)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> decls;
      list<DAE.Statement> body;
      Option<DAE.Exp> patternGuard;
      DAE.Exp exp;
      DAE.MatchCase case_;
      Integer jump;
      Absyn.Info resultInfo,info2;
      list<DAE.MatchCase> cases;
      list<DAE.Exp> exps;
      Absyn.Info info;

    case ({},{},_) then {};

    case (DAE.CASE(patterns,patternGuard,decls,body,SOME(_),resultInfo,jump,info2)::cases,exp::exps,info)
      equation
        cases = fixCaseReturnTypes2(cases,exps,info);
      then DAE.CASE(patterns,patternGuard,decls,body,SOME(exp),resultInfo,jump,info2)::cases;

    case ((case_ as DAE.CASE(result=NONE()))::cases,exps,info)
      equation
        cases = fixCaseReturnTypes2(cases,exps,info);
      then case_::cases;

    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Patternm.fixCaseReturnTypes2 failed"}, inInfo);
      then fail();
  end matchcontinue;
end fixCaseReturnTypes2;

public function traverseCases
  replaceable type A subtypeof Any;
  input list<DAE.MatchCase> inCases;
  input FuncExpType func;
  input A inA;
  output list<DAE.MatchCase> outCases;
  output A oa;
  partial function FuncExpType
    input tuple<DAE.Exp, A> inTpl;
    output tuple<DAE.Exp, A> outTpl;
  end FuncExpType;
algorithm
  (outCases,oa) := match (inCases,func,inA)
    local
      list<DAE.Pattern> patterns;
      list<DAE.Element> decls;
      list<DAE.Statement> body,body1;
      Option<DAE.Exp> result,result1,patternGuard,patternGuard1;
      Integer jump;
      Absyn.Info resultInfo,info;
      list<DAE.MatchCase> cases,cases1;
      A a;

    case ({},_,a) then ({},a);
    case (DAE.CASE(patterns,patternGuard,decls,body,result,resultInfo,jump,info)::cases,_,a)
      equation
        (body1,(_,a)) = DAEUtil.traverseDAEEquationsStmts(body,Expression.traverseSubexpressionsHelper,(func,a));
        ((patternGuard1,a)) = Expression.traverseExpOpt(patternGuard,func,a);
        ((result1,a)) = Expression.traverseExpOpt(result,func,a);
        (cases1,a) = traverseCases(cases,func,a);
        cases = Util.if_(referenceEq(cases,cases1) and referenceEq(patternGuard,patternGuard1) and referenceEq(result,result1) and referenceEq(body,body1), inCases, DAE.CASE(patterns,patternGuard1,decls,body1,result1,resultInfo,jump,info)::cases1);
      then (cases,a);
  end match;
end traverseCases;

protected function filterEmptyPattern
  input tuple<DAE.Pattern,String,DAE.Type> tpl;
algorithm
  _ := match tpl
    case ((DAE.PAT_WILD(),_,_)) then fail();
    else ();
  end match;
end filterEmptyPattern;

protected function addLocalDecls
"Adds local declarations to the environment and returns the DAE"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ElementItem> els;
  input String scopeName;
  input Boolean impl;
  input Absyn.Info info;
  output Env.Cache outCache;
  output Option<tuple<Env.Env,DAE.DAElist,AvlTreeString.AvlTree>> res;
algorithm
  (outCache,res) := matchcontinue (inCache,inEnv,els,scopeName,impl,info)
    local
      list<Absyn.ElementItem> ld;
      list<SCode.Element> ld2,ld3,ld4;
      list<tuple<SCode.Element, DAE.Mod>> ld_mod;
      DAE.DAElist dae1;
      Env.Env env2;
      ClassInf.State dummyFunc;
      String str;
      Env.Cache cache;
      Env.Env env;
      Boolean b;
      AvlTreeString.AvlTree declsTree;
      list<String> names;

    case (cache,env,{},_,_,_)
      equation
        declsTree = AvlTreeString.avlTreeNew();
      then (cache,SOME((env,DAE.emptyDae,declsTree)));
    case (cache,env,ld,_,_,_)
      equation
        env2 = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(scopeName),NONE());

        // Tranform declarations such as Real x,y; to Real x; Real y;
        ld2 = SCodeUtil.translateEitemlist(ld, SCode.PROTECTED());

        // Filter out the components (just to be sure)
        true = List.fold(List.map1(ld2, SCode.isComponentWithDirection, Absyn.BIDIR()), boolAnd, true);
        ((cache,b)) = List.fold1(ld2, checkLocalShadowing, env, (cache,false));
        ld2 = Util.if_(b,{},ld2);

        // Transform the element list into a list of element,NOMOD
        ld_mod = InstUtil.addNomod(ld2);

        dummyFunc = ClassInf.FUNCTION(Absyn.IDENT("dummieFunc"), false);
        (cache,env2,_) = InstUtil.addComponentsToEnv(cache, env2,
          InnerOuter.emptyInstHierarchy, DAE.NOMOD(), Prefix.NOPRE(),
          dummyFunc, ld_mod, {}, {}, {}, impl);
        (cache,env2,_,_,dae1,_,_,_,_) = Inst.instElementList(
          cache,env2, InnerOuter.emptyInstHierarchy, UnitAbsyn.noStore,
          DAE.NOMOD(), Prefix.NOPRE(), dummyFunc, ld_mod, {},
          impl, InstTypes.INNER_CALL(), ConnectionGraph.EMPTY, Connect.emptySet, true);

        names = List.map(ld2, SCode.elementName);
        declsTree = List.fold1(names, AvlTreeString.avlTreeAddFold, 0, AvlTreeString.avlTreeNew());

        res = Util.if_(b,NONE(),SOME((env2,dae1,declsTree)));
      then (cache,res);

    case (cache,env,ld,_,_,_)
      equation
        ld2 = SCodeUtil.translateEitemlist(ld, SCode.PROTECTED());
        (ld2 as _::_) = List.filterOnTrue(ld2, SCode.isNotComponent);
        str = stringDelimitList(List.map1(ld2, SCodeDump.unparseElementStr, SCodeDump.defaultOptions),", ");
        Error.addSourceMessage(Error.META_INVALID_LOCAL_ELEMENT,{str},info);
      then (cache,NONE());

    case (cache,env,ld,_,_,_)
      equation
        env2 = Env.openScope(env, SCode.NOT_ENCAPSULATED(), SOME(scopeName),NONE());

        // Tranform declarations such as Real x,y; to Real x; Real y;
        ld2 = SCodeUtil.translateEitemlist(ld, SCode.PROTECTED());

        // Filter out the components (just to be sure)
        ld3 = List.select1(ld2, SCode.isComponentWithDirection, Absyn.INPUT());
        ld4 = List.select1(ld2, SCode.isComponentWithDirection, Absyn.OUTPUT());
        (ld2 as _::_) = listAppend(ld3,ld4); // I don't care that this is slow; it's just for error message generation
        str = stringDelimitList(List.map1(ld2, SCodeDump.unparseElementStr, SCodeDump.defaultOptions),", ");
        Error.addSourceMessage(Error.META_INVALID_LOCAL_ELEMENT,{str},info);
      then (cache,NONE());

    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"Patternm.addLocalDecls failed"},info);
      then (inCache,NONE());
  end matchcontinue;
end addLocalDecls;

protected function checkLocalShadowing
  input SCode.Element elt;
  input Env.Env env;
  input tuple<Env.Cache,Boolean> inTpl;
  output tuple<Env.Cache,Boolean> outTpl;
algorithm
  outTpl := matchcontinue (elt,env,inTpl)
    local
      String name;
      Env.Cache cache;
      Boolean b;
      Absyn.Info info;
    case (SCode.COMPONENT(name=name),_,(cache,_))
      equation
        failure((_,_,_,_,_,_,_,_,_) = Lookup.lookupVarLocal(cache,env,DAE.CREF_IDENT(name,DAE.T_UNKNOWN_DEFAULT,{})));
      then inTpl;
    case (SCode.COMPONENT(name=name),_,(cache,b))
      equation
        (cache,DAE.ATTR(variability=SCode.CONST()),_,_,_,_,_,_,_) = Lookup.lookupVarLocal(cache,env,DAE.CREF_IDENT(name,DAE.T_UNKNOWN_DEFAULT,{}));
        // Allow shadowing constants. Should be safe since they become values pretty much straight away.
      then ((cache,b));
    case (SCode.COMPONENT(name=name,info=info),_,(cache,b))
      equation
        Error.addSourceMessage(Error.MATCH_SHADOWING,{name},info);
      then ((cache,true));
  end matchcontinue;
end checkLocalShadowing;

public function resultExps
  input list<DAE.MatchCase> inCases;
  output list<DAE.Exp> exps;
algorithm
  exps := match inCases
    local
      DAE.Exp exp; list<DAE.MatchCase> cases;
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
  input list<DAE.Pattern> ipats;
  output Boolean b;
algorithm
  b := match ipats
    local list<DAE.Pattern> pats;
    case {} then true;
    case DAE.PAT_WILD()::pats then allPatternsWild(pats);
    else false;
  end match;
end allPatternsWild;

protected function allPatternsAlwaysMatch
  "Returns true if all patterns in the list are wildcards or as-bindings"
  input list<DAE.Pattern> ipats;
  output Boolean b;
algorithm
  b := match ipats
    local DAE.Pattern pat; list<DAE.Pattern> pats;
    case {} then true;
    case DAE.PAT_WILD()::pats then allPatternsAlwaysMatch(pats);
    case DAE.PAT_AS(pat=pat)::pats then allPatternsAlwaysMatch(pat::pats);
    case DAE.PAT_AS_FUNC_PTR(pat=pat)::pats then allPatternsAlwaysMatch(pat::pats);
    else false;
  end match;
end allPatternsAlwaysMatch;

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
      Option<DAE.Exp> patternGuard,result;
      Integer jump;
      Absyn.Info resultInfo,info;
    case (DAE.CASE(_,patternGuard,localDecls,body,result,resultInfo,jump,info),_)
      then DAE.CASE(pats,patternGuard,localDecls,body,result,resultInfo,jump,info);
  end match;
end setCasePatterns;

public function getValueCtor
  "Get the constructor index of a uniontype record based on its index in the uniontype"
  input Integer ix;
  output Integer ctor;
algorithm
  ctor := ix+3;
end getValueCtor;

public function sortPatternsByComplexity
  input list<DAE.Pattern> inPatterns;
  output list<tuple<DAE.Pattern,Integer>> outPatterns;
algorithm
  outPatterns := List.toListWithPositions(inPatterns,0,{});
  outPatterns := List.sort(outPatterns, sortPatternsByComplexityWork);
end sortPatternsByComplexity;

protected function sortPatternsByComplexityWork
  input tuple<DAE.Pattern,Integer> tpl1;
  input tuple<DAE.Pattern,Integer> tpl2;
  output Boolean greater;
protected
  DAE.Pattern pat1,pat2;
  Integer i1,i2,c1,c2;
algorithm
  (pat1,i1) := tpl1;
  (pat2,i2) := tpl2;
  ((_,c1)) := traversePattern((pat1,0),patternComplexity);
  ((_,c2)) := traversePattern((pat2,0),patternComplexity);
  // If both complexities are equal, keep the original ordering
  // If c1 is 0, and c2 is not 0 we move the left pattern to the end.
  // Else we move the cheaper pattern to the beginning
  greater := Util.if_(c1 == c2, i1 > i2, Util.if_(c2 == 0, false, Util.if_(c1 == 0, true, c1 > c2)));
end sortPatternsByComplexityWork;

protected function patternComplexity
  input tuple<DAE.Pattern,Integer> inTpl;
  output tuple<DAE.Pattern,Integer> outTpl;
algorithm
  outTpl := match inTpl
    local
      DAE.Pattern p;
      DAE.Exp exp;
      Integer i;
    case ((p as DAE.PAT_CONSTANT(exp=exp),i))
      equation
        ((_,i)) = Expression.traverseExp(exp,constantComplexity,i);
      then ((p,i));
    case ((p as DAE.PAT_CONS(head=_),i))
      then ((p,i+5));
    case ((p as DAE.PAT_CALL(knownSingleton=false),i))
      then ((p,i+5));
    case ((p as DAE.PAT_SOME(pat=_),i))
      then ((p,i+5));
    else inTpl;
  end match;
end patternComplexity;

protected function constantComplexity
  input tuple<DAE.Exp,Integer> inTpl;
  output tuple<DAE.Exp,Integer> outTpl;
algorithm
  outTpl := match inTpl
     local
       DAE.Exp e;
       String str;
       Integer i;
     case ((e as DAE.SCONST(str),i)) then ((e,i+5+stringLength(str)));
     case ((e as DAE.ICONST(_),i)) then ((e,i+1));
     case ((e as DAE.BCONST(_),i)) then ((e,i+1));
     case ((e as DAE.RCONST(_),i)) then ((e,i+2));
     case ((e,i)) then ((e,i+5)); // lists and such; add a little something in addition to its members....
  end match;
end constantComplexity;

protected function addEnvKnownAsBindings
  input tuple<DAE.Pattern,Env.Env> inTpl;
  output tuple<DAE.Pattern,Env.Env> outTpl;
algorithm
  outTpl := match inTpl
    local
      Absyn.Path name,path;
      String id,scope;
      DAE.Type ty;
      Env.Env env;
      DAE.Pattern pat;
      list<DAE.Var> fields;
      Integer index;
      Boolean knownSingleton;
    case ((DAE.PAT_AS(pat=pat),_))
      then addEnvKnownAsBindings2(inTpl,findFirstNonAsPattern(pat));
    else inTpl;
  end match;
end addEnvKnownAsBindings;

protected function addEnvKnownAsBindings2
  input tuple<DAE.Pattern,Env.Env> inTpl;
  input DAE.Pattern firstPattern;
  output tuple<DAE.Pattern,Env.Env> outTpl;
algorithm
  outTpl := match (inTpl,firstPattern)
    local
      Absyn.Path name,path;
      String id,scope;
      DAE.Type ty;
      Env.Env env;
      DAE.Pattern pat;
      list<DAE.Var> fields;
      Integer index;
      Boolean knownSingleton;
      DAE.Attributes attr;
    case ((pat as DAE.PAT_AS(id=id,attr=attr),env),DAE.PAT_CALL(index=index,fields=fields,knownSingleton=knownSingleton,name=name))
      equation
         path = Absyn.stripLast(name);
         ty = DAE.T_METARECORD(path,index,fields,knownSingleton,{name});
         env = Env.extendFrameV(env, DAE.TYPES_VAR(id,attr,ty,DAE.UNBOUND(),NONE()), SCode.COMPONENT(id,SCode.defaultPrefixes,SCode.defaultVarAttr,Absyn.TPATH(name,NONE()),SCode.NOMOD(),SCode.noComment,NONE(),Absyn.dummyInfo), DAE.NOMOD(), Env.VAR_DAE(), Env.emptyEnv);
      then ((pat,env));
    else inTpl;
  end match;
end addEnvKnownAsBindings2;

protected function findFirstNonAsPattern
  input DAE.Pattern inPattern;
  output DAE.Pattern outPattern;
algorithm
  outPattern := match inPattern
    case DAE.PAT_AS(pat=outPattern) then findFirstNonAsPattern(outPattern);
    else inPattern;
  end match;
end findFirstNonAsPattern;

protected function getInputAsBinding
  input Absyn.Exp inExp;
  output Absyn.Exp exp;
  output list<String> aliases;
  output list<String> aliasesAndCrefs;
algorithm
  (exp,aliases,aliasesAndCrefs) := match inExp
    local
      String id;
    case Absyn.CREF(componentRef=Absyn.CREF_IDENT(id,{})) then (inExp,{},{id});
    case Absyn.AS(id,exp)
      equation
        (exp,aliases,aliasesAndCrefs) = getInputAsBinding(exp);
      then (exp,id::aliases,id::aliasesAndCrefs);
    else (inExp,{},{});
  end match;
annotation(Documentation(info="<html>
<p>Checks an input expression to the match-expression for alias candidates.</p>
<p>If the input is a cref, it is a candidate for a metarecord to bind with dot-notation.</p>
<p>If the input is an as-binding (cref as exp), cref is used as an alias, and we keep recursing to find aliases.
The as-binding is then removed, using only the exp-part as the actual input to the match-expression</p>
<p>Note: An as-binding is again overridden by an as-binding in the case pattern.</p>
</html>"));
end getInputAsBinding;

protected function addPatternAliases
  input DAE.Pattern inPattern;
  input list<String> inAliases;
  output DAE.Pattern pat;
algorithm
  pat := match (inPattern,inAliases)
    local
      String alias;
      list<String> aliases;
    case (_,alias::aliases) then addPatternAliases(DAE.PAT_AS(alias,NONE(),DAE.dummyAttrInput,inPattern), aliases);
    else inPattern;
  end match;
end addPatternAliases;

protected function addAliasesToEnv
  input Env.Env inEnv;
  input list<DAE.Type> inTypes;
  input list<list<String>> inAliases;
  input Absyn.Info info;
  output Env.Env outEnv;
algorithm
  outEnv := match (inEnv,inTypes,inAliases,info)
    local
      list<DAE.Type> tys;
      list<list<String>> aliases;
      list<String> rest;
      String id;
      Env.Env env;
      DAE.Type ty;
      DAE.Attributes attr;
    case (_,{},{},_) then inEnv;
    case (_,_::tys,{}::aliases,_) then addAliasesToEnv(inEnv,tys,aliases,info);
    case (env,ty::_,(id::rest)::aliases,_)
      equation
        attr = DAE.dummyAttrInput;
        env = Env.extendFrameV(env, DAE.TYPES_VAR(id,attr,ty,DAE.UNBOUND(),NONE()), SCode.COMPONENT(id,SCode.defaultPrefixes,SCode.defaultVarAttr,Absyn.TPATH(Absyn.IDENT("$dummy"),NONE()),SCode.NOMOD(),SCode.noComment,NONE(),info), DAE.NOMOD(), Env.VAR_DAE(), Env.emptyEnv);
      then addAliasesToEnv(env,inTypes,rest::aliases,info);
  end match;
end addAliasesToEnv;

protected function statementListFindDeadStoreRemoveEmptyStatements
  input list<DAE.Statement> inBody;
  input AvlTreeString.AvlTree localsTree;
  input AvlTreeString.AvlTree inUseTree;
  output list<DAE.Statement> body;
  output AvlTreeString.AvlTree useTree;
algorithm
  (body,useTree) := List.map1Fold(listReverse(inBody),statementFindDeadStore,localsTree,inUseTree);
  body := List.select(body,isNotDummyStatement);
  body := listReverse(body);
end statementListFindDeadStoreRemoveEmptyStatements;

protected function statementFindDeadStore
  input DAE.Statement inStatement;
  input AvlTreeString.AvlTree localsTree;
  input AvlTreeString.AvlTree inUseTree;
  output DAE.Statement outStatement;
  output AvlTreeString.AvlTree useTree;
algorithm
  (outStatement,useTree) := match (inStatement,localsTree,inUseTree)
    local
      AvlTreeString.AvlTree elseTree;
      list<DAE.Statement> body;
      DAE.ComponentRef cr;
      DAE.Exp exp,lhs,cond,msg,level;
      list<DAE.Exp> exps;
      DAE.Else else_;
      DAE.Type ty;
      Absyn.Info info;
      Boolean b;
      String id;
      Integer index;
      DAE.ElementSource source;
    case (DAE.STMT_ASSIGN(type_=ty,exp1=lhs,exp=exp,source=source as DAE.SOURCE(info=info)),_,_)
      equation
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, inUseTree);
        ((lhs,_)) = Expression.traverseExp(lhs, checkDefUse, (localsTree,useTree,info));
        outStatement = Algorithm.makeAssignmentNoTypeCheck(ty,lhs,exp,source);
      then (outStatement,useTree);

    case (DAE.STMT_TUPLE_ASSIGN(type_=ty,expExpLst=exps,exp=exp,source=source as DAE.SOURCE(info=info)),_,_)
      equation
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, inUseTree);
        ((DAE.TUPLE(exps),_)) = Expression.traverseExp(DAE.TUPLE(exps), checkDefUse, (localsTree,useTree,info));
        outStatement = Algorithm.makeTupleAssignmentNoTypeCheck(ty,exps,exp,source);
      then (outStatement,useTree);

    case (DAE.STMT_ASSIGN_ARR(type_=ty,componentRef=cr,exp=exp,source=source as DAE.SOURCE(info=info)),_,_)
      equation
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, inUseTree);
        ((DAE.CREF(componentRef=cr),_)) = Expression.traverseExp(DAE.CREF(cr,DAE.T_REAL_DEFAULT), checkDefUse, (localsTree,useTree,info));
        outStatement = Algorithm.makeArrayAssignmentNoTypeCheck(ty,cr,exp,source);
      then (outStatement,useTree);

    case (DAE.STMT_IF(exp=exp,statementLst=body,else_=else_,source=source),_,_)
      equation
        (else_,elseTree) = elseFindDeadStore(else_, localsTree, inUseTree);
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, useTree);
        useTree = AvlTreeString.joinAvlTrees(useTree,elseTree);
      then (DAE.STMT_IF(exp,body,else_,source),useTree);

    case (DAE.STMT_FOR(ty,b,id,index,exp,body,source),_,_)
      equation
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, useTree);
        // TODO: We should remove ident from the use-tree in case of shadowing... But our avlTree cannot delete
        useTree = AvlTreeString.joinAvlTrees(useTree,inUseTree);
      then (DAE.STMT_FOR(ty,b,id,index,exp,body,source),useTree);

    case (DAE.STMT_WHILE(exp=exp,statementLst=body,source=source),_,_)
      equation
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, useTree);
        // The loop might not be entered just like if. The following should not remove all previous uses:
        // while false loop
        //   return;
        // end while;
        useTree = AvlTreeString.joinAvlTrees(useTree,inUseTree);
      then (DAE.STMT_WHILE(exp,body,source),useTree);

    // No PARFOR in MetaModelica
    case (DAE.STMT_PARFOR(source=_),_,_) then fail();

    case (DAE.STMT_ASSERT(cond=cond,msg=msg,level=level),_,_)
      equation
        ((_,useTree)) = Expression.traverseExp(cond, useLocalCref, inUseTree);
        ((_,useTree)) = Expression.traverseExp(msg, useLocalCref, useTree);
        ((_,useTree)) = Expression.traverseExp(level, useLocalCref, useTree);
      then (inStatement,useTree);

    // Reset the tree; we do not execute anything after this
    case (DAE.STMT_TERMINATE(msg=exp),_,_)
      equation
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, AvlTreeString.avlTreeNew());
      then (inStatement,useTree);

    // No when or reinit in functions
    case (DAE.STMT_WHEN(source=_),_,_) then fail();
    case (DAE.STMT_REINIT(source=_),_,_) then fail();

    // There is no use after this one, so we can reset the tree
    case (DAE.STMT_NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("fail"))),_,_) then (inStatement,AvlTreeString.avlTreeNew());
    case (DAE.STMT_RETURN(source=_),_,_) then (inStatement,AvlTreeString.avlTreeNew());

    case (DAE.STMT_NORETCALL(exp=exp),_,_)
      equation
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, inUseTree);
      then (inStatement,useTree);

    case (DAE.STMT_BREAK(source=_),_,_) then (inStatement,inUseTree);
    case (DAE.STMT_ARRAY_INIT(source=_),_,_) then (inStatement,inUseTree);
    case (DAE.STMT_FAILURE(body=body,source=source),_,_)
      equation
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
      then (DAE.STMT_FAILURE(body,source),useTree);
  end match;
end statementFindDeadStore;

protected function elseFindDeadStore
  input DAE.Else inElse;
  input AvlTreeString.AvlTree localsTree;
  input AvlTreeString.AvlTree inUseTree;
  output DAE.Else outElse;
  output AvlTreeString.AvlTree useTree;
algorithm
  (outElse,useTree) := match (inElse,localsTree,inUseTree)
    local
      DAE.Exp exp;
      list<DAE.Statement> body;
      DAE.Else else_;
      AvlTreeString.AvlTree elseTree;
    case (DAE.NOELSE(),_,_) then (inElse,inUseTree);
    case (DAE.ELSEIF(exp,body,else_),_,_)
      equation
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
        ((_,useTree)) = Expression.traverseExp(exp, useLocalCref, useTree);
        (else_,elseTree) = elseFindDeadStore(else_, localsTree, inUseTree);
        useTree = AvlTreeString.joinAvlTrees(useTree,elseTree);
        else_ = DAE.ELSEIF(exp,body,else_);
      then (else_,useTree);
    case (DAE.ELSE(body),_,_)
      equation
        (body,useTree) = statementListFindDeadStoreRemoveEmptyStatements(body,localsTree,inUseTree);
        else_ = DAE.ELSE(body);
      then (else_,useTree);
  end match;
end elseFindDeadStore;

protected function isNotDummyStatement
  input DAE.Statement statement;
  output Boolean b;
algorithm
  b := Algorithm.isNotDummyStatement(statement);
  Error.assertionOrAddSourceMessage(b or not Flags.isSet(Flags.PATTERNM_ALL_INFO),Error.META_DEAD_CODE,{"Statement optimised away"},DAEUtil.getElementSourceFileInfo(Algorithm.getStatementSource(statement)));
end isNotDummyStatement;

end Patternm;
